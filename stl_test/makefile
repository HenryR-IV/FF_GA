program: template #clean

CC=g++

FLAGS=-Wall -lGL -lGLU -lglut -lGLEW

template: 
	$(CC) stl_raster.cpp -o stl_raster $(FLAGS)
	$(CC) stl_convert.cpp -o stl_convert

clean:
	rm *.o
