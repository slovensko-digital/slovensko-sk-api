FROM jruby:9.2.4.0
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs openjdk-8-jdk
RUN mkdir /app
WORKDIR /app
COPY Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install --without development:test --path vendor/bundle --deployment
COPY . .
RUN ./lib/upvs/compile
