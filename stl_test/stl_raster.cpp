#include <GL/freeglut.h>
#include <iostream>
#include <fstream>
#include <cstdint>

using namespace std;

string filename;

bool wireframe = 0;

void processFile()
{
	ifstream infile(filename.c_str()); 
	if(!infile)
		cout << "Error Opening File" << endl;
	uint32_t x, y;

	int numVertices;

	infile >> hex >> numVertices; 
	for(int i = 0; i < numVertices; i++)
	{
		infile >> hex >> x;
		infile >> hex >> y;
		x = x>>16; // only consider whole number portion
		y = y>>16;
		glVertex2i(x,y);
	}
	infile.close();
}

void display_func()
{
	glClearColor(0.0, 0.0, 0.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT);

	glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);

	if(wireframe)
		glBegin(GL_TRIANGLES);
	else
		glBegin(GL_POINTS);

	processFile();

	glEnd();

	glFlush();
}

void timer_func(int tag)
{
	glutTimerFunc(33, timer_func, 0);
	glutPostRedisplay();
}

// if space is pressed toggle between wireframe and points
void keyboard_func(unsigned char k, int x, int y)
{
	if(k == ' ')
		wireframe = !wireframe;
}

#define canvas_Width 600
#define canvas_Height 600
char canvas_Name[] = "Simple Rasterizer";

int main(int argc, char** argv)
{
	if(argc < 2) 
	{
		cout << "Error: Please Provide Filename" << endl;
		return 1;
	}

	filename = string(argv[1]);

	glutInit(&argc, argv);

	glutInitContextVersion(4, 3);
	glutInitContextProfile(GLUT_COMPATIBILITY_PROFILE);

	glutInitDisplayMode(GLUT_SINGLE | GLUT_RGB);
	glutInitWindowSize(600, 600);
	glutInitWindowPosition(25, 25);

	glutCreateWindow(canvas_Name);

	//glewExperimental = GL_TRUE;
	//glewInit();

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluOrtho2D(0.0, 600.0, 0.0, 600.0);

	glutDisplayFunc(display_func);

	glutTimerFunc(33, timer_func, 0);

	glutKeyboardFunc(keyboard_func);

	glutMainLoop();
	return 0;
}


