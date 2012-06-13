

all: db test update generate


test:
	ruby localmoviedb_test.rb
	
	
db:
	local_mdb.rb --add-dynamic-media testdir/ 
	
update:
	local_mdb.rb --update --scan --update-poster 
	
generate:
	local_mdb.rb -g
	
clean:
	rm -v -r db
	rm -v imdb*html
	