# Azure DocumentDB output plugin for Embulk

embulk-output-documentdb is an embulk output plugin that dumps records to Azure DocumentDB. Embulk is a open-source bulk data loader that helps data transfer between various databases, storages, file formats, and cloud services. See [Embulk documentation](http://www.embulk.org/docs/) for details.

## Overview

* **Plugin type**: output
* **Load all or nothing**: no
* **Resume supported**: no
* **Cleanup supported**: yes

## Installation

    $ gem install embulk-output-documentdb

## Configuration

### DocumentDB

To use Microsoft Azure DocumentDB, you must create a DocumentDB database account using either the Azure portal, Azure Resource Manager templates, or Azure command-line interface (CLI). In addition, you must have a database and a collection to which embulk-output-documentdb writes event-stream out. Here are instructions:

 * Create a DocumentDB database account using [the Azure portal](https://azure.microsoft.com/en-us/documentation/articles/documentdb-create-account/), or [Azure Resource Manager templates and Azure CLI](https://azure.microsoft.com/en-us/documentation/articles/documentdb-automation-resource-manager-cli/)
 * [How to create a database for DocumentDB](https://azure.microsoft.com/en-us/documentation/articles/documentdb-create-database/)
 * [Create a DocumentDB collection](https://azure.microsoft.com/en-us/documentation/articles/documentdb-create-collection/)
 * [Partitioning and scaling in Azure DocumentDB](https://azure.microsoft.com/en-us/documentation/articles/documentdb-partition-data/)

### Embulk Configuration (config.yml)

```yaml
out:
  type: documentdb
  docdb_endpoint: https://yoichikademo0.documents.azure.com:443/
  docdb_account_key: EMwUa3EzsAtJ1qYfzxo9nQ3KudofsXNm3xLh1SLffKkUHMFl80OZRZIVu4lxdKRKxkgVAj0c2mv9BZSyMN7tdg==
  docdb_database: myembulkdb
  docdb_collection: myembulkcoll
  auto_create_database: true
  auto_create_collection: true
  partitioned_collection: false
  key_column: id
```

 * **docdb\_endpoint (required)** - Azure DocumentDB Account endpoint URI
 * **docdb\_account\_key (required)** - Azure DocumentDB Account key (master key). You must NOT set a read-only key
 * **docdb\_database (required)** - DocumentDB database nameb
 * **docdb\_collection (required)** - DocumentDB collection name
 * **auto\_create\_database (optional)** - Default:true. By default, DocumentDB database named **docdb\_database** will be automatically created if it does not exist
 * **auto\_create\_collection (optional)** - Default:true. By default, DocumentDB collection named **docdb\_collection** will be automatically created if it does not exist
 * **partitioned\_collection (optional)** - Default:false. Set true if you want to create and/or store records to partitioned collection. Set false for single-partition collection
 * **partition\_key (optional)** - Default:nil. Partition key must be specified for paritioned collection (partitioned\_collection set to be true)
 * **offer\_throughput (optional)** - Default:10100. Throughput for the collection expressed in units of 100 request units per second. This is only effective when you newly create a partitioned collection (ie. Both auto\_create\_collection and partitioned\_collection are set to be true )
 * **key\_column (required)** - Column name to be inserted to DocumentDB as primary key. If it's not named "id", the column name is converted into "id" (string).

## Configuration examples

Here are two types of the plugin configurations example - single-parition collection and partitioned collection.

### (1) Single-Partition Collection Case

```yaml
out:
  type: documentdb
  docdb_endpoint: https://yoichikademo0.documents.azure.com:443/
  docdb_account_key: EMwUa3EzsAtJ1qYfzxo9nQ3KudofsXNm3xLh1SLffKkUHMFl80OZRZIVu4lxdKRKxkgVAj0c2mv9BZSyMN7tdg==
  docdb_database: myembulkdb
  docdb_collection: myembulkcoll
  auto_create_database: true
  auto_create_collection: true
  partitioned_collection: false
  key_column: id
```

### (2) Partitioned Collection Case

```yaml
  type: documentdb
  docdb_endpoint: https://yoichikademo0.documents.azure.com:443/
  docdb_account_key: EMwUa3EzsAtJ1qYfzxo9nQ3KudofsXNm3xLh1SLffKkUHMFl80OZRZIVu4lxdKRKxkgVAj0c2mv9BZSyMN7tdg==
  docdb_database: myembulkdb
  docdb_collection: myembulkcoll
  auto_create_database: true
  auto_create_collection: true
  partitioned_collection: true
  partition_key: account
  offer_throughput: 10100
  key_column: id
```

## Build, Install, and Run

```
$ rake

$ embulk gem install pkg/embulk-output-documentdb-0.1.0.gem

$ embulk preview config.yml

$ embulk run config.yml

```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yokawasa/embulk-output-documentdb.

## Copyright

<table>
  <tr>
    <td>Copyright</td><td>Copyright (c) 2016- Yoichi Kawasaki</td>
  </tr>
  <tr>
    <td>License</td><td>MIT</td>
  </tr>
</table>
