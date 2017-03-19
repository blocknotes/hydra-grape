# hydra-grape

## Dev Notes

### run

- Execute with watch for changes:

`rerun -b -- rackup -p 3000`

or

`rerun -b -- thin start`

### curl tests

```sh
# User login:
curl -H 'Content-Type: application/json' -X POST 'http://localhost:3000/api/v1/auth/sign_in' --data '{"email":"aaa@bbb.ccc","encrypted_password":"81dc9bdb52d04dc20036dbd8313ed055"}'
# User logout:
curl -H 'Content-Type: application/json' -X DELETE 'http://localhost:3000/api/v1/auth/sign_out' --data '{"token":"123tok"}'
# User register:
curl -H 'Content-Type: application/json' -X POST 'http://localhost:3000/api/v1/auth/sign_up' --data '{"email":"aaa@bbb.ccc","password":"1234"}'
# Token check:
curl -H 'Content-Type: application/json' 'http://localhost:3000/api/v1/auth/check?token=9Mn606QhB3n5mWZTK1lTVA=='
# Token refresh:
curl -H 'Content-Type: application/json' -X POST 'http://localhost:3000/api/v1/auth/touch' --data '{"token":"9Mn606QhB3n5mWZTK1lTVA=="}'

# List projects:
curl 'http://localhost:3000/api/v1/projects'
# Create project:
curl -X POST 'http://localhost:3000/api/v1/projects' -H 'Content-Type: application/json' --data '{"name":"MyProject","code":"prj","url":"https://www.google.com"}'
# Read project:
curl 'http://localhost:3000/api/v1/projects/58b1dc2bf571550470276cc2'
# Update project:
curl -X PUT 'http://localhost:3000/api/v1/projects/58b1dc2bf571550470276cc2' -H 'Content-Type: application/json' --data '{"name":"Just a Test Project"}'
# Delete project:
curl -X DELETE 'http://localhost:3000/api/v1/projects/58b1dc2bf571550470276cc2'

# List collections:
curl 'http://localhost:3000/api/v1/collections/58b1dc2bf571550470276cc2'
# Create collection:
curl -X POST 'http://localhost:3000/api/v1/collections/58b1dc2bf571550470276cc2' -H 'Content-Type: application/json' --data '{"name":"articles","singular":"article","columns":{"title":"String","description":"String","position":"Float","published":"Boolean","dt":"DateTime"},"actions":{"list":["title","published"]}}'
curl -X POST 'http://localhost:3000/api/v1/collections/58b1dc2bf571550470276cc2' -H 'Content-Type: application/json' --data '{"name":"authors","singular":"author","columns":{"first_name":"String","last_name":"String","age":"Integer"}}'
# Read collection:
curl 'http://localhost:3000/api/v1/collections/58b1dc2bf571550470276cc2/58b1dc55f5715504fca07272'
# Update collection:
curl -X PUT 'http://localhost:3000/api/v1/collections/58b1dc2bf571550470276cc2/58b1dc55f5715504fca07272' -H 'Content-Type: application/json' --data '{"name":"posts","singular":"post"}'
# Delete collection:
curl -X DELETE 'http://localhost:3000/api/v1/collections/58b1dc2bf571550470276cc2/58a9c5c1f571556e1caf9e09'

# List items:
curl 'http://localhost:3000/api/v1/items/prj_articles'
curl -H 'Auth-Token:5ot6AjIdkt0lAbfnZkvUsQ==' 'http://localhost:3000/api/v1/items/prj_articles'
# Create item:
curl -X POST 'http://localhost:3000/api/v1/items/prj_articles' -H 'Content-Type: application/json' --data '{"data":{"title":"A test article","description":"Just a desc"}}'
curl -X POST 'http://localhost:3000/api/v1/items/prj_articles' -H 'Content-Type: application/json' --data '{"data":{"title":"Another one","position":"10.0","published":true}}'
# Read item:
curl 'http://localhost:3000/api/v1/items/prj_articles/58b1dc65f5715504fca07273'
# Update item:
curl -X PUT 'http://localhost:3000/api/v1/items/prj_articles/58b1dc65f5715504fca07273' -H 'Content-Type: application/json' --data '{"data":{"title":"Another article","position":"1.5"}}'
# Delete item:
curl -X DELETE 'http://localhost:3000/api/v1/items/prj_articles/58a9a4eef571552cf3200438'
```

```sh
# Embed tests:
curl -X POST 'http://localhost:3000/api/v1/collections/58b1dc2bf571550470276cc2' -H 'Content-Type: application/json' --data '{"name":"pages","singular":"page","columns":{"title":"String","prj_blocks":"embeds_many"}}'
curl -X POST 'http://localhost:3000/api/v1/collections/58b1dc2bf571550470276cc2' -H 'Content-Type: application/json' --data '{"name":"blocks","singular":"block","columns":{"name":"String","prj_pages":"embedded_in"}}'
# Create item:
curl -X POST 'http://localhost:3000/api/v1/items/prj/pages' -H 'Content-Type: application/json' --data '{"data":{"title":"A pag 2","prj_blocks":[{"name":"BL1"}]}}'
```

### More tests

```sh
mongo hydra
# List collections:
show collections
# Query:
db.projects.find()
db.prj_articles.find()

db.createCollection("books")
db.books.createIndex( { "name": 1 }, { "unique": 1 } )
# same as: db.books.ensureIndex( { name: 1 }, { unique: true } )
db.books.insert( { name: "Book 1" } )  # OK
db.books.insert( { name: "Book 1" } )  # fails

# db.books.ensureIndex({ "chapters.title": 1 }, { unique: true, sparse: true })  # !
db.books.ensureIndex({ "chapters.title": 1 }, { unique: true, sparse: true })  # !

# db.books.createIndex( { "chapters.title": 1 }, { "unique": 1 } )
# db.books.insert( { name: "Book 1", chapters: [ { title: "Name 1", more: "aaa" }, { title: "Name 1", more: "bbb" } ] } )


db.books.drop()

use books
db.books.ensureIndex({ title: 1 }, { unique: true })
db.books.ensureIndex({ "title": 1, "chapters.title": 1 }, { unique: true, sparse: true, drop_dups: true })
db.books.insert({ title: "Book1", chapters: [ { title: "Ch1" }, { title: "Ch1" } ] })
db.books.insert({ title: "Book1", chapters: [ { title: "Ch1" } ] })

b = db.books.findOne( { title: "Book1" } )
b.chapters.push( { "title": "Ch1" } )
db.books.save( b )
db.books.findOne( { title: "Book1" } )
```
