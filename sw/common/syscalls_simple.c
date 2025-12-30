int main(int argc, char** argv);

extern volatile unsigned long long tohost;

void exit(int code)
{
  tohost = (code << 1) | 1;
  asm volatile("ecall\n");
  while (1);
}


void _init_rve(int cid, int nc)
{
  int ret = main(0, 0);
  exit(ret);

  while(1);
}


void _init_simple_crt(int cid, int nc)
{

  int ret = main(0, 0);
  exit(ret);

  while(1);
}


