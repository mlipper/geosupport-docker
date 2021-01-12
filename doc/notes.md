# Docker Notes

Notes about using Docker that I cannot seem to remember.

## Docker Environment Files

Source: https://docs.docker.com/compose/environment-variables/

When you set the same environment variable in multiple files, here’s the priority used by Compose to choose which value to use:

>
>  1. Compose file
>  2. Shell environment variables
>  3. Environment file
>  4. Dockerfile
>  5. Variable is not defined
>

**NOTE:** Docker does NOT support variable substitution or other shell-like string functions in .env files. E.g., use of single or double quotes will be part of variable values if used.

See also: https://docs.docker.com/engine/reference/run/#env-environment-variables


## Multi-stage Builds

Notes about Docker Engine's multistage build functionality.

### Declare ARG defaults that are visible to all build stages

Source: https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact

To make an ARG's default value visible across a Dockerfile containing multiple FROM statements:

>
>  1. It must be defaulted before the Dockerfile's first FROM statement
>  2. Before it is referenced within a build stage, it must be declared _without_ a default value.
>

For example:
```Dockerfile
ARG FOO=bar
FROM debian:buster AS build
ARG FOO
RUN echo "Hello from the build stage" > "/${FOO}.txt"
...
FROM debian:buster-slim
ARG FOO
COPY --from=build "/${FOO}.txt" /message.txt
...
```