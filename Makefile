.PHONY: all clean

all: stock-price

stock-price:
	raco exe -o stock-price main.rkt

clean:
	rm stock-price
