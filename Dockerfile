FROM ruby:3.0.0

ARG UID
RUN adduser rails --uid $UID --disabled-password --gecos ""

ENV APP /usr/src/app
RUN mkdir $APP
WORKDIR $APP

COPY Gemfile* $APP/
RUN bundle install -j3

COPY . $APP/

CMD ["rails", "server", "-p", "8080", "-b", "0.0.0.0"]
