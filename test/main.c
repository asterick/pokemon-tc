_sfrbyte target _at(0x20FF);
unsigned char x = 2;

int blerg(unsigned char k) {
  target = k;
}

int main(void) {
  target = 0xDD;
  for(;;x++) _halt();
}
