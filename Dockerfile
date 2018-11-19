FROM jruby:9.2.0.0
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs openjdk-8-jdk
RUN mkdir /app
WORKDIR /app
ADD Gemfile .
ADD Gemfile.lock .
RUN bundle install --without development:test --path vendor/bundle --deployment
ADD . .
RUN ./lib/upvs/compile
