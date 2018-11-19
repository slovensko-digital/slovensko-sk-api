FROM jruby:9.2.4.0-jdk-alpine
RUN apk update && apk add build-base nodejs postgresql-dev curl
RUN mkdir /app
WORKDIR /app
COPY Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install --without development:test --path vendor/bundle --deployment
COPY . .
RUN ./lib/upvs/compile
