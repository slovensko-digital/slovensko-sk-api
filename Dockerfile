FROM jruby:10.1.2.0-jdk21

# Install packages needed to build gems with native extensions
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Bundle and cache Ruby gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set deployment true && \
    bundle config set without development:test && \
    bundle install

# Package and cache UPVS library
COPY lib/upvs lib/upvs
RUN gem install ruby-maven && \
    rmvn -f lib/upvs package

# Cache everything
COPY . .

# Run application by default
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
