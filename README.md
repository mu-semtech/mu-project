# mu-project

Bootstrap a mu.semte.ch microservices environment in three easy steps.


## Tutorial (getting started)
Repetition is boring. Web applications oftentimes require the same functionality: to create, read, update and delete resources. Even if they operate in different domains. Or, in terms of a REST API, endpoints to GET, POST, PATCH and DELETE resources. Since productivity is one of the driving forces behind the mu.semte.ch architecture, the platform provides a microservice – [mu-cl-resources](https://github.com/mu-semtech/mu-cl-resources) – that generates a [JSONAPI](http://jsonapi.org/) compliant API for your resources based on a simple configuration describing the domain. In this tutorial we will explain how to setup such a configuration.

### Adding mu-cl-resources to your project
Like all microservices in the mu.semte.ch stack, mu-cl-resources is published as a Docker image. It just needs two configuration files in `./config/resources/`:

- `domain.lisp`: describing the resources and relationships between them in your domain
- `repository.lisp`: defining prefixes for the vocabularies used in your domain

To provide the configuration files, you can mount the files in the /config folder of the Docker image:
```yaml
services:
  # ...
  resource:
    image: semtech/mu-cl-resources:1.20.0
    links:
      - db:database
    volumes:
      - ./config:/config
  # ...
```
Alternatively you can build your own Docker image by extending the mu-cl-resources image and copying the configuration files in /config. See the [mu-cl-resources repo](https://github.com/mu-semtech/mu-cl-resources#mounting-the-config-files).

The former option may be easier during development, while the latter is better suited in a production environment. With this last variant you can publish and release your service with its own version, independent of the mu-cl-resources version.

When adding mu-cl-resources to our application, we also have to update the dispatcher configuration such that incoming requests get dispatched to our new service. We will update the dispatcher configuration at the end of this tutorial once we know on which endpoints our resources will be available.

### Describing your domain
Next step is to describe your domain in the configuration files. The configuration is written in Common Lisp. Don’t be intimidated, just follow the examples, make abstraction of all the parentheses and your’re good to go 🙂 As an example, we will describe the domain of the [ember-data-table demo](http://ember-data-table.semte.ch/) which [consists of books and their authors](https://github.com/erikap/books-service/tree/ember-data-table-example).

#### repository.lisp
The `repository.lisp` file describes the prefixes for the vocabularies used in our domain model.

To start, each configuration file starts with:

```lisp
(in-package :mu-cl-resources)
```

Next, the prefixes are listed one per line as follows:

```lisp
(in-package :mu-cl-resources)

(add-prefix "dcterms" "http://purl.org/dc/terms/")
(add-prefix "schema" "http://schema.org/")
```

#### domain.lisp
The domain.lisp file describes your resources and the relationships between them. In this post we will describe the model of a book. Later on we will add an author model and specify the relationship between books and authors.

Also start the `domain.lisp` file with the following line:
```lisp
(in-package :mu-cl-resources)
```

Next, add the basis of the book model:
```lisp
(in-package :mu-cl-resources)

(define-resource book ()
  :class (s-prefix "schema:Book")
  :resource-base (s-url "http://mu.semte.ch/services/github/madnificent/book-service/books/")
:on-path "books")
```

Although you may not have written a letter of Common Lisp before, you will probably be able to understand the lines of code above.

- We define a book resource
- Each book will get schema:Book as RDF class
- Each book instance will be identified with a URI starting with “http://mu.semte.ch/services/github/madnificent/book-service/books/”  – mu-cl-resources just appends a generated UUID to it
- The resources will be published on the /books API endpoint

Finally, define the properties of a book:
```lisp
(in-package :mu-cl-resources)

(define-resource book ()
  :class (s-prefix "schema:Book")
  :properties `((:title :string ,(s-prefix "schema:headline"))
                (:isbn :string ,(s-prefix "schema:isbn"))
                (:publication-date :date ,(s-prefix "schema:datePublished"))
                (:genre :string ,(s-prefix "schema:genre"))
                (:language :string ,(s-prefix "schema:inLanguage")) 
                (:number-of-pages :integer ,(s-prefix "schema:numberOfPages")))
  :resource-base (s-url "http://mu.semte.ch/services/github/madnificent/book-service/books/")
:on-path "books")
```

Each property is described according to the format:

```lisp
(:dasherized-property-name :type, (s-prefix "my-prefix:my-predicate"))
```

and will result in a triple:
```
<http://mu.semte.ch/services/github/madnificent/book-service/books/ead2e61a-ab1e-4261-9b6d-9c142ae94765> my-prefix:my-predicate "some-value"
```

### Configuring the dispatcher

Our book resources will be available on the /books paths. The mu-cl-resources service provides GET, POST, PATCH and DELETE operations on this path for free Assuming the books service is known as ‘resource’ in our dispatcher, we will add the following dispatch rule to our dispatcher configuration to forward the incoming requests to the books service:

```lisp
match "/books/*path" do
 Proxy.forward conn, path, "http://resource/books/"
end
```

Good job! The books can now be produced and consumed by the frontend through your JSONAPI compliant API. Now we will add relationships to the model.


### The author model
Each book is written by (at least one) an author. An author isn’t a regular property of a book like - for example - the book’s title. It's a resource on its own. An author has its own properties like a name, a birth date etc. And it is related to a book. Before we can define the relationship between books and authors, we first need to specify the model of an author.

The definition of the model is very similar to that of the book. Add the following lines to your `domain.lisp`:

```lisp
(define-resource author ()
  :class (s-prefix "schema:Author")
  :properties `((:name :string ,(s-prefix "schema:name")))
  :resource-base (s-url "http://mu.semte.ch/services/github/madnificent/book-service/authors/")
:on-path "authors")
```

Expose the author endpoints in the `dispatcher.ex` configuration:
```
match "/authors/*path" do
  Proxy.forward conn, path, "http://resource/authors/"
end
```

### Defining relationships
Now that the author model is added, we can define the relationship between a book and an author. Let’s suppose a one-to-many relationship. A book has one author and an author may have written multiple books.

First, extend the book’s model:
```lisp
(define-resource book ()
  :class (s-prefix "schema:Book")
  :properties `((:title :string ,(s-prefix "schema:headline"))
                (:isbn :string ,(s-prefix "schema:isbn"))
                (:publication-date :date ,(s-prefix "schema:datePublished"))
                (:genre :string ,(s-prefix "schema:genre"))
                (:language :string ,(s-prefix "schema:inLanguage")) 
                (:number-of-pages :integer ,(s-prefix "schema:numberOfPages")))
  :has-one `((author :via ,(s-prefix "schema:author") 
              :as "author"))
  :resource-base (s-url "http://mu.semte.ch/services/github/madnificent/book-service/books/")
:on-path "books")
```

Adding an author to a book will now result in the following triple in the store:
```
<http://mu.semte.ch/services/github/madnificent/book-service/books/182232da-e07d-438f-8608-f6356624a666> 
    schema:author <http://mu.semte.ch/services/github/madnificent/book-service/authors/e6c446ad-36ee-43b3-a8a0-2349ecfdcb5d> .
```

The :as “author” portion of the definition specifies the path on which the relationship will be exposed in the JSON representation of a book.

```json
{
  "attributes": {
    "title": "Rock & Roll with Ember"
  },
  "id": "620f7a1c-9d31-4b8a-a627-2eb6904fe1f3",
  "type": "books",
  "relationships": {
     "author": {
       "links": {
         "self": "/books/620f7a1c-9d31-4b8a-a627-2eb6904fe1f3/links/author",
         "related": "/books/620f7a1c-9d31-4b8a-a627-2eb6904fe1f3/author"
       }
     }
  }
}
```

Next, add the inverse relationship to the author’s model:

```lisp
(define-resource author ()
  :class (s-prefix "schema:Author")
  :properties `((:name :string ,(s-prefix "schema:name")))
  :has-many `((book :via (s-prefix "schema:author")
               :inverse t
               :as "books"))
  :resource-base (s-url "http://mu.semte.ch/services/github/madnificent/book-service/authors/")
:on-path "authors")
```

The ‘:inverse t’ indicates that the relationship from author to books is the inverse relation. As you can see the the relationship’s path “books” is in plural since it’s a has-many relation in this case.

If you want to define a many-to-many relationships between books and authors, just change the :has-one to :has-many and pluralize the “author” path to “authors” in the book’s model. Don’t forget to restart your microservice if you’ve updated the model.

Now simply restart your microservice by running `docker-compose restart`, and you're done!

### Conclusion
That's it! Now you can [fetch](http://jsonapi.org/format/#fetching-relationships) and [update](http://jsonapi.org/format/#crud-updating-relationships) the relationships as specified by [jsonapi.org](http://jsonapi.org/).  The generated API also supports the [include query parameter](http://jsonapi.org/format/#fetching-includes) to include related resources in the response when fetching one or more resource. That’s a lot you get for just a few lines of code, isn’t it?

*This tutorial has been adapted from @erikap's mu.semte.ch articles. You can view them [here](https://mu.semte.ch/2017/07/27/generating-a-jsonapi-compliant-api-for-your-resources/) and [here](https://mu.semte.ch/2017/08/17/generating-a-jsonapi-compliant-api-for-your-resources-part-2/).*

## How-To

### Quickstart an mu-project

Setting up your environment is done in three easy steps:
1. First configure the running microservices and their names in `docker-compose.yml`
2. Then, configure how requests are dispatched in `config/dispatcher.ex`
3. Lastly, simply start the docker-compose.

### Hooking things up with docker-compose

Alter the `docker-compose.yml` file so it contains all microservices you need.  The example content should be clear, but you can find more information in the [Docker Compose documentation](https://docs.docker.com/compose/).  Don't remove the `identifier` and `db` container, they are respectively the entry-point and the database of your application.  Don't forget to link the necessary microservices to the dispatcher and the database to the microservices.

### Configure the dispatcher

Next, alter the file `config/dispatcher/dispatcher.ex` based on the example that is there by default.  Dispatch requests to the necessary microservices based on the names you used for the microservice.

### Boot up the system

Boot your microservices-enabled system using docker-compose.

    cd /path/to/mu-project
    docker-compose up

You can shut down using `docker-compose stop` and remove everything using `docker-compose rm`.
