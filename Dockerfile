FROM jruby:9.2.5.0-jdk-alpine

WORKDIR /app

COPY lib lib
COPY Gemfile Gemfile.lock ./
COPY . .

RUN apk add --no-cache --update build-base postgresql-dev nodejs curl \
    && ./lib/upvs/compile \
    && gem install bundler \
    && gem update --system \
    && bundle install --without development:test --path vendor/bundle --deployment

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
