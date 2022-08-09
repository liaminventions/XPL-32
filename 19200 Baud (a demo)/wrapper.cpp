// goofy ahh wrapper
//
// version negitive 0.1
//                   (lol)

#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <fstream> 

using namespace std;

fstream fileStream; 

int main(int argc, char *argv[]) {
  FILE *fin;
  int c;
  size_t bytes_read = 0;
  uint8_t buffer = 0x00;

  if (argc != 2) {
    cout << "No Filename Provided." << endl;
    exit(EXIT_FAILURE);
  }

  fin = fopen(argv[1], "rb");
  if (!fin) {
    fprintf(stderr, "Cannot open %s\n", argv[1]);
    exit(EXIT_FAILURE);
  }

  fileStream.open("output.bin", ios::out); 

  if(!fileStream.is_open()) {
    cout << "not export :(((" << endl;
    return 0;
  }

  while (EOF != (c = fgetc(fin))) {
    for(int i=0;i<=8;i++) {   
      if(c == 0x31) {
        buffer = buffer << 1;
        buffer++;
      } else if (c == 0x30) {
        buffer = buffer << 1;
      } else if (c == 0x0d) {
        //ignore
      } else if (c == 0x0a) {
        //ignore
      } else {
        cout << "bad char" << endl;
        return 0;
      }
    }    
    fileStream << buffer;
    bytes_read++;
  }

  fclose(fin);

  fileStream.close(); 

  cout << "done" << endl;
  
  return EXIT_SUCCESS;
}