FROM jruby:9.2.0.0-jdk-alpine
RUN apk update && apk add build-base nodejs postgresql-dev curl
RUN mkdir /app
WORKDIR /app
COPY lib lib
RUN ./lib/upvs/compile
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN bundle install --without development:test --path vendor/bundle --deployment
COPY . .
