# mu-project

Bootstrap a mu.semte.ch microservices environment in three easy steps.


## How-To

### Quickstart an mu-project

Setting up your environment is done in three easy steps:
1. First configure the running microservices and their names in `docker-compose.yml`
2. Then, configure how requests are dispatched in `config/dispatcher.ex`
3. Lastly, simply start the docker-compose.

> [!WARNING]
> Many of the containers used have issues with high limits on open file descriptors, so you might need [to work around this](https://github.com/mu-semtech/project/blob/master/docs/how-tos/troubleshooting---slow-starting-containers.md)

#### Hooking things up with docker-compose

Alter the `docker-compose.yml` file so it contains all microservices you need.  The example content should be clear, but you can find more information in the [Docker Compose documentation](https://docs.docker.com/compose/).  Don't remove the `identifier` and `database` container, they are respectively the entry-point and the database of your application.  Don't forget to link the necessary microservices to the dispatcher and the database to the microservices.

#### Configure the dispatcher

Next, alter the file `config/dispatcher/dispatcher.ex` based on the example that is there by default.  Dispatch requests to the necessary microservices based on the names you used for the microservice.

#### Boot up the system

Boot your microservices-enabled system using docker-compose.

    cd /path/to/mu-project
    docker-compose up

You can shut down using `docker-compose stop` and remove everything using `docker-compose rm`.

## Tutorials

To help you find your feet with your first semantic works projects, we've collected [a few tutorials](TUTORIALS.md).

