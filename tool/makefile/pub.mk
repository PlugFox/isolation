.PHONY: get

get:
	@dart pub get

pana:
	@dart pub global activate pana
	@dart pub global run pana

deploy:
	@dart pub publish