FROM jruby:9.2.5.0-jdk-alpine
RUN apk add --no-cache --update build-base postgresql-dev nodejs curl
RUN mkdir /app
WORKDIR /app
COPY lib lib
RUN ./lib/upvs/compile
RUN gem install bundler
RUN gem update --system
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development:test --path vendor/bundle --deployment
COPY . .
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
