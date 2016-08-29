module Embulk
  module Output

    require 'time'
    require 'securerandom'
    require_relative 'documentdb/client'
    require_relative 'documentdb/partitioned_coll_client'
    require_relative 'documentdb/header'
    require_relative 'documentdb/resource'

    class Documentdb < OutputPlugin
      Plugin.register_output("documentdb", self)

      def self.transaction(config, schema, count, &control)
        # configuration code:
        task = {
          'docdb_endpoint'         => config.param('docdb_endpoint',        :string),
          'docdb_account_key'      => config.param('docdb_account_key',     :string),
          'docdb_database'         => config.param('docdb_database',        :string),
          'docdb_collection'       => config.param('docdb_collection',      :string),
          'auto_create_database'   => config.param('auto_create_database',  :bool,  :default => true),
          'auto_create_collection' => config.param('auto_create_collection',:bool,  :default => true),
          'partitioned_collection' => config.param('partitioned_collection',:bool,  :default => false),
          'partition_key'          => config.param('partition_key',         :string, :default => nil),
          'offer_throughput'       => config.param('offer_throughput',      :integer, :default => AzureDocumentDB::PARTITIONED_COLL_MIN_THROUGHPUT),
          'key_column'             => config.param('key_column',            :string),
        }
        Embulk.logger.info "transaction start"
        # param validation
        raise ConfigError, 'no docdb_endpoint' if task['docdb_endpoint'].empty?
        raise ConfigError, 'no docdb_account_key' if task['docdb_account_key'].empty?
        raise ConfigError, 'no docdb_database' if task['docdb_database'].empty?
        raise ConfigError, 'no docdb_collection' if task['docdb_collection'].empty?
        raise ConfigError, 'no key_column' if task['key_column'].empty?

        if task['partitioned_collection']
          raise ConfigError, 'partition_key must be set in partitioned collection mode' if @partition_key.empty?
          if (task['auto_create_collection'] && task['offer_throughput'] < AzureDocumentDB::PARTITIONED_COLL_MIN_THROUGHPUT)
            raise ConfigError, sprintf("offer_throughput must be more than and equals to %s",
                                AzureDocumentDB::PARTITIONED_COLL_MIN_THROUGHPUT)
          end
        end

        # resumable output:
        # resume(task, schema, count, &control)

        # non-resumable output:
        task_reports = yield(task)
        Embulk.logger.info "Documentdb output finished. Task reports = #{task_reports.to_json}"

        next_config_diff = {}
        return next_config_diff
      end

      #def self.resume(task, schema, count, &control)
      #  task_reports = yield(task)
      #
      #  next_config_diff = {}
      #  return next_config_diff
      #end


      # init is called in initialize(task, schema, index)     
      def init
        Embulk.logger.info "Documentdb output init"
        @start_time = Time.now
        # initialization code:
        @recordnum = 0
        @successnum = 0

        begin
          @client = nil
          if task['partitioned_collection']
            @client = AzureDocumentDB::PartitionedCollectionClient.new(task['docdb_account_key'],task['docdb_endpoint'])
          else
            @client = AzureDocumentDB::Client.new(task['docdb_account_key'],task['docdb_endpoint'])
          end

          # initial operations for database
          res = @client.find_databases_by_name(task['docdb_database'])
          if( res[:body]["_count"].to_i == 0 )
            raise "No database (#{docdb_database})! Enable auto_create_database or create it by yourself" if !task['auto_create_database']
            # create new database as it doesn't exists
            @client.create_database(task['docdb_database'])
          end
          
          # initial operations for collection
          database_resource = @client.get_database_resource(task['docdb_database'])
          res = @client.find_collections_by_name(database_resource, task['docdb_collection'])
          if( res[:body]["_count"].to_i == 0 )
            raise "No collection (#{docdb_collection})! Enable auto_create_collection or create it by yourself" if !task['auto_create_collection']
            # create new collection as it doesn't exists
            if task['partitioned_collection']
              partition_key_paths = ["/#{task['partition_key']}"] 
              @client.create_collection(database_resource,
                               task['docdb_collection'], partition_key_paths, task['offer_throughput'])
            else
              @client.create_collection(database_resource, task['docdb_collection'])               
            end
          end
          @coll_resource = @client.get_collection_resource(database_resource, task['docdb_collection'])
      
        rescue Exception =>ex
          Embulk.logger.error { "Error: init: '#{ex}'" }
          exit!
        end
      end

      
      def close
      end
      
      # called for each page in each task
      def add(page)
        # output code:
        page.each do |record|
          hash = Hash[schema.names.zip(record)]
          @recordnum += 1
          if !hash.key?(@task['key_column']) 
            Embulk.logger.warn { "Skip Invalid Record: no key_column, data=>" + hash.to_json }
            next 
          end
          unique_doc_id = "#{hash[@task['key_column']]}"
          if @task['key_column'] != 'id'
            hash.delete(@task['key_column'])
          end
          # force primary key to be both named "id" and "string" type
          hash['id'] = unique_doc_id 

          begin 
            if @task['partitioned_collection']
              @client.create_document(@coll_resource, unique_doc_id, hash, @task['partition_key']) 
            else
              @client.create_document(@coll_resource, unique_doc_id, hash) 
            end
            @successnum += 1
          rescue RestClient::ExceptionWithResponse => rcex
            exdict = JSON.parse(rcex.response)
            if exdict['code'] == 'Conflict'
              Embulk.logger.error { "Duplicate Error: doc id (#{unique_doc_id}) already exists, data=>" + hash.to_json }
            else
              Embulk.logger.error { "RestClient Error: '#{rcex.response}', data=>" + hash.to_json }
            end
          rescue => ex
            Embulk.logger.error { "UnknownError: '#{ex}', doc id=>#{unique_doc_id}, data=>" + hash.to_json }
          end
        end
      end

      def finish
        Embulk.logger.info "Documentdb output finish"
        @finish_time = Time.now
      end

      def abort
      end

      def commit
        Embulk.logger.info "Documentdb output commit"
        elapsed_time = @finish_time - @start_time
        task_report = {
          "total_records" => @recordnum,
          "success" => @successnum,
          "skip_or_error" => (@recordnum - @successnum),
          "elapsed_time" => elapsed_time,
        }
        return task_report
      end
    end

  end
end
