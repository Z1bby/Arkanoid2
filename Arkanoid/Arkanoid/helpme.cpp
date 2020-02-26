#define _CRT_SECURE_NO_WARNINGS
#pragma comment(lib, "winmm.lib")
#include <stdio.h>
#include <windows.h>
#include <mmsystem.h>
extern "C" void funkcja(); // dlaczego Source.asm nie widzi funkcja(void*,const char*) bez wpisania tej linijki?

float ffloat() {
	float a = 3.14;
	a++;
	return a;
}

void funkcja() {
	ffloat();
}