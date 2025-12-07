FROM ruby:3.1.3

# Dipendenze di sistema per Rails + Postgres + asset base
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    postgresql-client \
    curl \
    gnupg2 \
    nodejs \
    yarn \
    imagemagick \
    file \
    libssl-dev \
    libcurl3-dev \
    cmake \
    pkg-config \
  && rm -rf /var/lib/apt/lists/*

# Rails app vive qui (come nel Dockerfile generato da Rails)
WORKDIR /rails

# Gemfile prima (cache layer)
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Poi tutto il resto del codice dell'app
COPY . .

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Comando default: avvia il server Rails in ascolto su tutte le interfacce
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]