# hydra-grape

A multi-project API system.

Features:

- create REST API using specific endpoints (called collections)
- create group of API (called projects)
- simple auth using tokens
- built using Grape, a Mongo DB is required

## Examples

- Endpoint to create a new project:

```sh
curl -X POST 'http://localhost:3000/api/v1/projects' -H 'Content-Type: application/json' --data '{"name":"MyProject","code":"prj","url":"https://www.google.com"}'
```

- Endpoint to create a collection (using a project id):

```sh
curl -X POST 'http://localhost:3000/api/v1/collections/58b1dc2bf571550470276cc2' -H 'Content-Type: application/json' --data '{"name":"authors","singular":"author","columns":{"first_name":"String","last_name":"String","age":"Integer"}}'
```

- Endpoint to create a new item (using a project code and a collection name):

```sh
curl -X POST 'http://localhost:3000/api/v1/items/prj_authors' -H 'Content-Type: application/json' --data '{"data":{"first_name":"John","last_name":"Doe","age":"25"}}'
```

- Endpoint to list entries:

```sh
curl 'http://localhost:3000/api/v1/items/prj_authors'
```

## Setup

- Prepare database:

```sh
rake db:mongoid:drop
rake db:mongoid:create_indexes
```

## Dev / More examples

- See specific document: [here](README_DEV.md)
