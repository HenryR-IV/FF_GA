#include <iostream>
#include <fstream>
#include <cstdint>

using namespace std;

uint32_t to_fixed(float);
void readFile(char *);

int main(int argc, char **argv)
{ 
	if(argc < 2) 
	{
		cout << "Error: Please Provide Filename" << endl;
		return 1;
	}
	readFile(argv[1]);

	return 0;
}

uint32_t to_fixed(float num)
{
	// get exponent and subtract offset
	uint32_t exp = ((*(uint32_t*)&num & 0x7F800000)>>23) - 127;

	// put mantissa in correct position for fixed point
	// using 64 bit to ensure no bits are lost
	uint64_t mantissa = ((*(uint32_t*)&num & 0x007FFFFF) | 0x00800000);
	mantissa = mantissa << 9;

	// adjust mantissa to correct position
	if(exp > 0)
	{
		mantissa = mantissa << uint64_t(exp);
	}
	else if(exp < 0)
	{
		mantissa = mantissa >> uint64_t(0-exp);
	}

	uint32_t result = (mantissa & 0x0000FFFFFFFF0000)>>16; 

	if(num < 0.0)
		result = 0-result; 

	// middle 32 bits for result
	return result;
}

struct vertex
{
	float x, y, z;
};

// reads data from stl file
// averages the x, y, z  coordinates and translates by -avg on each axis to approx. center about origin
void readFile(char *filename)
{
	ifstream infile(filename);
	float avgX = 0.0;
	float avgY = 0.0;
	float avgZ = 0.0;

	// 80 byte header can be ignored
	infile.ignore(80);

	// header followed by 32 bit int indicating number of triangles
	// read in this way because the file format is little-endian and this pc is big-endian
	// so the bytes must be flipped which is what the bit shift and OR thing is
	uint8_t bytes[4];
	infile.read((char*)bytes, 4);
	int numtriangles = bytes[3]<<24 | bytes[2]<<16 | bytes[1]<<8 | bytes[0];
	cout << "Triangles: " << numtriangles << endl;

	int numVert = numtriangles * 3;

	numVert = numVert + numVert%4; // append extra values since processor can do 4 at a time for simplicity
	//array to hold all vertices read from stl file
	vertex *t = new vertex[numVert];

	for(int i = 0; i < numVert%4; i++)
	{
		t[numVert-i-1].x = 0.0;
		t[numVert-i-1].y = 0.0;
		t[numVert-i-1].z = 0.0;
	}

	cout << "Loading File ...";
	//calculate average point for center-ish of model
	float v1x, v1y, v1z;
	float v2x, v2y, v2z;
	float v3x, v3y, v3z;
	uint32_t temp;
	int j = 0;
	for(uint32_t i = 0; i < numtriangles; i++)
	{
		infile.ignore(12); // ignore normal vector

		//read in vertices, byte reversing still required
		//vertex 1
		infile.read((char*)bytes, 4);
		temp = bytes[3]<<24 | bytes[2]<<16 | bytes[1]<<8 | bytes[0];
		v1x = *((float*)&temp);
		infile.read((char*)bytes, 4);
		temp = bytes[3]<<24 | bytes[2]<<16 | bytes[1]<<8 | bytes[0];
		v1y = *((float*)&temp);
		infile.read((char*)bytes, 4);
		temp = bytes[3]<<24 | bytes[2]<<16 | bytes[1]<<8 | bytes[0];
		v1z = *((float*)&temp);
		//vertex 2
		infile.read((char*)bytes, 4);
		temp = bytes[3]<<24 | bytes[2]<<16 | bytes[1]<<8 | bytes[0];
		v2x = *((float*)&temp);
		infile.read((char*)bytes, 4);
		temp = bytes[3]<<24 | bytes[2]<<16 | bytes[1]<<8 | bytes[0];
		v2y = *((float*)&temp);
		infile.read((char*)bytes, 4);
		temp = bytes[3]<<24 | bytes[2]<<16 | bytes[1]<<8 | bytes[0];
		v2z = *((float*)&temp);
		//vertex 3
		infile.read((char*)bytes, 4);
		temp = bytes[3]<<24 | bytes[2]<<16 | bytes[1]<<8 | bytes[0];
		v3x = *((float*)&temp);
		infile.read((char*)bytes, 4);
		temp = bytes[3]<<24 | bytes[2]<<16 | bytes[1]<<8 | bytes[0];
		v3y = *((float*)&temp);
		infile.read((char*)bytes, 4);
		temp = bytes[3]<<24 | bytes[2]<<16 | bytes[1]<<8 | bytes[0];
		v3z = *((float*)&temp);

		//load into array
		t[j].x = v1x;
		t[j].y = v1y;
		t[j].z = v1z;

		t[j+1].x = v2x;
		t[j+1].y = v2y;
		t[j+1].z = v2z;

		t[j+2].x = v3x;
		t[j+2].y = v3y;
		t[j+2].z = v3z;

		//running sum for averages
		avgX += v1x + v2x + v3x;
		avgY += v1y + v2y + v3y;
		avgZ += v1z + v2z + v3z;

		//ignores extra bytes of data at end of each triangle
		infile.ignore(2);

		// increment by 3 vertices
		j += 3;
	}
	infile.close();
	cout << "Done" << endl;

	//finish computing averages by dividing by of vertices (3 per triangle)
	avgX /= numtriangles*3.0;
	avgY /= numtriangles*3.0;
	avgZ /= numtriangles*3.0;

	char outfilename[] = "test.txt";
	ofstream outfile(outfilename);

	outfile << hex << numVert << endl;
	
	cout << "Adjusting and Outputing to " << outfilename << "..." << endl; 
	//adjust for averages to ~center about origin
	for(uint32_t i = 0; i < numVert; i+=4 )
	{
		t[i].x -= avgX;
		t[i].y -= avgY;
		t[i].z -= avgZ;

		t[i+1].x -= avgX;
		t[i+1].y -= avgY;
		t[i+1].z -= avgZ;

		t[i+2].x -= avgX;
		t[i+2].y -= avgY;
		t[i+2].z -= avgZ;

		t[i+3].x -= avgX;
		t[i+3].y -= avgY;
		t[i+3].z -= avgZ;

		// write to output file
		outfile << hex << to_fixed(t[i].x) << endl;
		outfile << hex << to_fixed(t[i+1].x) << endl;
		outfile << hex << to_fixed(t[i+2].x) << endl;
		outfile << hex << to_fixed(t[i+3].x) << endl;

		outfile << hex << to_fixed(t[i].y) << endl;
		outfile << hex << to_fixed(t[i+1].y) << endl;
		outfile << hex << to_fixed(t[i+2].y) << endl;
		outfile << hex << to_fixed(t[i+3].y) << endl;

		outfile << hex << to_fixed(t[i].z) << endl;
		outfile << hex << to_fixed(t[i+1].z) << endl;
		outfile << hex << to_fixed(t[i+2].z) << endl;
		outfile << hex << to_fixed(t[i+3].z) << endl;

		outfile << hex << 0x00010000 << endl;
		outfile << hex << 0x00010000 << endl;
		outfile << hex << 0x00010000 << endl;
		outfile << hex << 0x00010000 << endl;
	}
	outfile.close();
	cout << "Done" << endl;
}
