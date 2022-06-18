
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	86013103          	ld	sp,-1952(sp) # 80008860 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	b7c78793          	addi	a5,a5,-1156 # 80005be0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	33a080e7          	jalr	826(ra) # 80002466 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	e98080e7          	jalr	-360(ra) # 8000206c <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	200080e7          	jalr	512(ra) # 80002410 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	1ca080e7          	jalr	458(ra) # 800024bc <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	db2080e7          	jalr	-590(ra) # 800021f8 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	d1078793          	addi	a5,a5,-752 # 80021188 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	958080e7          	jalr	-1704(ra) # 800021f8 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	740080e7          	jalr	1856(ra) # 8000206c <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00001097          	auipc	ra,0x1
    80000ed8:	728080e7          	jalr	1832(ra) # 800025fc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	d44080e7          	jalr	-700(ra) # 80005c20 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	fd6080e7          	jalr	-42(ra) # 80001eba <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	688080e7          	jalr	1672(ra) # 800025d4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	6a8080e7          	jalr	1704(ra) # 800025fc <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	cae080e7          	jalr	-850(ra) # 80005c0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	cbc080e7          	jalr	-836(ra) # 80005c20 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	dd2080e7          	jalr	-558(ra) # 80002d3e <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	528080e7          	jalr	1320(ra) # 8000349c <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	4d4080e7          	jalr	1236(ra) # 80004450 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	dbe080e7          	jalr	-578(ra) # 80005d42 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	cfc080e7          	jalr	-772(ra) # 80001c88 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	862a0a13          	addi	s4,s4,-1950 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	16848493          	addi	s1,s1,360
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00015997          	auipc	s3,0x15
    8000193e:	79698993          	addi	s3,s3,1942 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	878d                	srai	a5,a5,0x3
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	16848493          	addi	s1,s1,360
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first) {
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e107a783          	lw	a5,-496(a5) # 80008810 <first.1672>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	c0a080e7          	jalr	-1014(ra) # 80002614 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	de07ab23          	sw	zero,-522(a5) # 80008810 <first.1672>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	9f8080e7          	jalr	-1544(ra) # 8000341c <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
allocpid() {
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00010917          	auipc	s2,0x10
    80001a3e:	86690913          	addi	s2,s2,-1946 # 800112a0 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	dc878793          	addi	a5,a5,-568 # 80008814 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	05893683          	ld	a3,88(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6e:	6d28                	ld	a0,88(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7e:	68a8                	ld	a0,80(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	64ac                	ld	a1,72(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b90:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b9c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ac23          	sw	zero,24(s1)
}
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <allocproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc6:	00010497          	auipc	s1,0x10
    80001bca:	b0a48493          	addi	s1,s1,-1270 # 800116d0 <proc>
    80001bce:	00015917          	auipc	s2,0x15
    80001bd2:	50290913          	addi	s2,s2,1282 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001be0:	4c9c                	lw	a5,24(s1)
    80001be2:	cf81                	beqz	a5,80001bfa <allocproc+0x40>
      release(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bee:	16848493          	addi	s1,s1,360
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a889                	j	80001c4a <allocproc+0x90>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	eec080e7          	jalr	-276(ra) # 80000af4 <kalloc>
    80001c10:	892a                	mv	s2,a0
    80001c12:	eca8                	sd	a0,88(s1)
    80001c14:	c131                	beqz	a0,80001c58 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c16:	8526                	mv	a0,s1
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e5c080e7          	jalr	-420(ra) # 80001a74 <proc_pagetable>
    80001c20:	892a                	mv	s2,a0
    80001c22:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c24:	c531                	beqz	a0,80001c70 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c26:	07000613          	li	a2,112
    80001c2a:	4581                	li	a1,0
    80001c2c:	06048513          	addi	a0,s1,96
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	0b0080e7          	jalr	176(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c38:	00000797          	auipc	a5,0x0
    80001c3c:	db078793          	addi	a5,a5,-592 # 800019e8 <forkret>
    80001c40:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c42:	60bc                	ld	a5,64(s1)
    80001c44:	6705                	lui	a4,0x1
    80001c46:	97ba                	add	a5,a5,a4
    80001c48:	f4bc                	sd	a5,104(s1)
}
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	60e2                	ld	ra,24(sp)
    80001c4e:	6442                	ld	s0,16(sp)
    80001c50:	64a2                	ld	s1,8(sp)
    80001c52:	6902                	ld	s2,0(sp)
    80001c54:	6105                	addi	sp,sp,32
    80001c56:	8082                	ret
    freeproc(p);
    80001c58:	8526                	mv	a0,s1
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	f08080e7          	jalr	-248(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c62:	8526                	mv	a0,s1
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	034080e7          	jalr	52(ra) # 80000c98 <release>
    return 0;
    80001c6c:	84ca                	mv	s1,s2
    80001c6e:	bff1                	j	80001c4a <allocproc+0x90>
    freeproc(p);
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	ef0080e7          	jalr	-272(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	01c080e7          	jalr	28(ra) # 80000c98 <release>
    return 0;
    80001c84:	84ca                	mv	s1,s2
    80001c86:	b7d1                	j	80001c4a <allocproc+0x90>

0000000080001c88 <userinit>:
{
    80001c88:	1101                	addi	sp,sp,-32
    80001c8a:	ec06                	sd	ra,24(sp)
    80001c8c:	e822                	sd	s0,16(sp)
    80001c8e:	e426                	sd	s1,8(sp)
    80001c90:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	f28080e7          	jalr	-216(ra) # 80001bba <allocproc>
    80001c9a:	84aa                	mv	s1,a0
  initproc = p;
    80001c9c:	00007797          	auipc	a5,0x7
    80001ca0:	38a7b623          	sd	a0,908(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ca4:	03400613          	li	a2,52
    80001ca8:	00007597          	auipc	a1,0x7
    80001cac:	b7858593          	addi	a1,a1,-1160 # 80008820 <initcode>
    80001cb0:	6928                	ld	a0,80(a0)
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	6b6080e7          	jalr	1718(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cba:	6785                	lui	a5,0x1
    80001cbc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cbe:	6cb8                	ld	a4,88(s1)
    80001cc0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc4:	6cb8                	ld	a4,88(s1)
    80001cc6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc8:	4641                	li	a2,16
    80001cca:	00006597          	auipc	a1,0x6
    80001cce:	53658593          	addi	a1,a1,1334 # 80008200 <digits+0x1c0>
    80001cd2:	15848513          	addi	a0,s1,344
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	15c080e7          	jalr	348(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cde:	00006517          	auipc	a0,0x6
    80001ce2:	53250513          	addi	a0,a0,1330 # 80008210 <digits+0x1d0>
    80001ce6:	00002097          	auipc	ra,0x2
    80001cea:	166080e7          	jalr	358(ra) # 80003e4c <namei>
    80001cee:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cf2:	478d                	li	a5,3
    80001cf4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	fa0080e7          	jalr	-96(ra) # 80000c98 <release>
}
    80001d00:	60e2                	ld	ra,24(sp)
    80001d02:	6442                	ld	s0,16(sp)
    80001d04:	64a2                	ld	s1,8(sp)
    80001d06:	6105                	addi	sp,sp,32
    80001d08:	8082                	ret

0000000080001d0a <growproc>:
{
    80001d0a:	1101                	addi	sp,sp,-32
    80001d0c:	ec06                	sd	ra,24(sp)
    80001d0e:	e822                	sd	s0,16(sp)
    80001d10:	e426                	sd	s1,8(sp)
    80001d12:	e04a                	sd	s2,0(sp)
    80001d14:	1000                	addi	s0,sp,32
    80001d16:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d18:	00000097          	auipc	ra,0x0
    80001d1c:	c98080e7          	jalr	-872(ra) # 800019b0 <myproc>
    80001d20:	892a                	mv	s2,a0
  sz = p->sz;
    80001d22:	652c                	ld	a1,72(a0)
    80001d24:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d28:	00904f63          	bgtz	s1,80001d46 <growproc+0x3c>
  } else if(n < 0){
    80001d2c:	0204cc63          	bltz	s1,80001d64 <growproc+0x5a>
  p->sz = sz;
    80001d30:	1602                	slli	a2,a2,0x20
    80001d32:	9201                	srli	a2,a2,0x20
    80001d34:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d38:	4501                	li	a0,0
}
    80001d3a:	60e2                	ld	ra,24(sp)
    80001d3c:	6442                	ld	s0,16(sp)
    80001d3e:	64a2                	ld	s1,8(sp)
    80001d40:	6902                	ld	s2,0(sp)
    80001d42:	6105                	addi	sp,sp,32
    80001d44:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d46:	9e25                	addw	a2,a2,s1
    80001d48:	1602                	slli	a2,a2,0x20
    80001d4a:	9201                	srli	a2,a2,0x20
    80001d4c:	1582                	slli	a1,a1,0x20
    80001d4e:	9181                	srli	a1,a1,0x20
    80001d50:	6928                	ld	a0,80(a0)
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	6d0080e7          	jalr	1744(ra) # 80001422 <uvmalloc>
    80001d5a:	0005061b          	sext.w	a2,a0
    80001d5e:	fa69                	bnez	a2,80001d30 <growproc+0x26>
      return -1;
    80001d60:	557d                	li	a0,-1
    80001d62:	bfe1                	j	80001d3a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d64:	9e25                	addw	a2,a2,s1
    80001d66:	1602                	slli	a2,a2,0x20
    80001d68:	9201                	srli	a2,a2,0x20
    80001d6a:	1582                	slli	a1,a1,0x20
    80001d6c:	9181                	srli	a1,a1,0x20
    80001d6e:	6928                	ld	a0,80(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	66a080e7          	jalr	1642(ra) # 800013da <uvmdealloc>
    80001d78:	0005061b          	sext.w	a2,a0
    80001d7c:	bf55                	j	80001d30 <growproc+0x26>

0000000080001d7e <fork>:
{
    80001d7e:	7179                	addi	sp,sp,-48
    80001d80:	f406                	sd	ra,40(sp)
    80001d82:	f022                	sd	s0,32(sp)
    80001d84:	ec26                	sd	s1,24(sp)
    80001d86:	e84a                	sd	s2,16(sp)
    80001d88:	e44e                	sd	s3,8(sp)
    80001d8a:	e052                	sd	s4,0(sp)
    80001d8c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d8e:	00000097          	auipc	ra,0x0
    80001d92:	c22080e7          	jalr	-990(ra) # 800019b0 <myproc>
    80001d96:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d98:	00000097          	auipc	ra,0x0
    80001d9c:	e22080e7          	jalr	-478(ra) # 80001bba <allocproc>
    80001da0:	10050b63          	beqz	a0,80001eb6 <fork+0x138>
    80001da4:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da6:	04893603          	ld	a2,72(s2)
    80001daa:	692c                	ld	a1,80(a0)
    80001dac:	05093503          	ld	a0,80(s2)
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	7be080e7          	jalr	1982(ra) # 8000156e <uvmcopy>
    80001db8:	04054663          	bltz	a0,80001e04 <fork+0x86>
  np->sz = p->sz;
    80001dbc:	04893783          	ld	a5,72(s2)
    80001dc0:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dc4:	05893683          	ld	a3,88(s2)
    80001dc8:	87b6                	mv	a5,a3
    80001dca:	0589b703          	ld	a4,88(s3)
    80001dce:	12068693          	addi	a3,a3,288
    80001dd2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd6:	6788                	ld	a0,8(a5)
    80001dd8:	6b8c                	ld	a1,16(a5)
    80001dda:	6f90                	ld	a2,24(a5)
    80001ddc:	01073023          	sd	a6,0(a4)
    80001de0:	e708                	sd	a0,8(a4)
    80001de2:	eb0c                	sd	a1,16(a4)
    80001de4:	ef10                	sd	a2,24(a4)
    80001de6:	02078793          	addi	a5,a5,32
    80001dea:	02070713          	addi	a4,a4,32
    80001dee:	fed792e3          	bne	a5,a3,80001dd2 <fork+0x54>
  np->trapframe->a0 = 0;
    80001df2:	0589b783          	ld	a5,88(s3)
    80001df6:	0607b823          	sd	zero,112(a5)
    80001dfa:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001dfe:	15000a13          	li	s4,336
    80001e02:	a03d                	j	80001e30 <fork+0xb2>
    freeproc(np);
    80001e04:	854e                	mv	a0,s3
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	d5c080e7          	jalr	-676(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e0e:	854e                	mv	a0,s3
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	e88080e7          	jalr	-376(ra) # 80000c98 <release>
    return -1;
    80001e18:	5a7d                	li	s4,-1
    80001e1a:	a069                	j	80001ea4 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e1c:	00002097          	auipc	ra,0x2
    80001e20:	6c6080e7          	jalr	1734(ra) # 800044e2 <filedup>
    80001e24:	009987b3          	add	a5,s3,s1
    80001e28:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e2a:	04a1                	addi	s1,s1,8
    80001e2c:	01448763          	beq	s1,s4,80001e3a <fork+0xbc>
    if(p->ofile[i])
    80001e30:	009907b3          	add	a5,s2,s1
    80001e34:	6388                	ld	a0,0(a5)
    80001e36:	f17d                	bnez	a0,80001e1c <fork+0x9e>
    80001e38:	bfcd                	j	80001e2a <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e3a:	15093503          	ld	a0,336(s2)
    80001e3e:	00002097          	auipc	ra,0x2
    80001e42:	818080e7          	jalr	-2024(ra) # 80003656 <idup>
    80001e46:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e4a:	4641                	li	a2,16
    80001e4c:	15890593          	addi	a1,s2,344
    80001e50:	15898513          	addi	a0,s3,344
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	fde080e7          	jalr	-34(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e5c:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e60:	854e                	mv	a0,s3
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	e36080e7          	jalr	-458(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e6a:	0000f497          	auipc	s1,0xf
    80001e6e:	44e48493          	addi	s1,s1,1102 # 800112b8 <wait_lock>
    80001e72:	8526                	mv	a0,s1
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	d70080e7          	jalr	-656(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e7c:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e80:	8526                	mv	a0,s1
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e16080e7          	jalr	-490(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001e8a:	854e                	mv	a0,s3
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	d58080e7          	jalr	-680(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001e94:	478d                	li	a5,3
    80001e96:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e9a:	854e                	mv	a0,s3
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	dfc080e7          	jalr	-516(ra) # 80000c98 <release>
}
    80001ea4:	8552                	mv	a0,s4
    80001ea6:	70a2                	ld	ra,40(sp)
    80001ea8:	7402                	ld	s0,32(sp)
    80001eaa:	64e2                	ld	s1,24(sp)
    80001eac:	6942                	ld	s2,16(sp)
    80001eae:	69a2                	ld	s3,8(sp)
    80001eb0:	6a02                	ld	s4,0(sp)
    80001eb2:	6145                	addi	sp,sp,48
    80001eb4:	8082                	ret
    return -1;
    80001eb6:	5a7d                	li	s4,-1
    80001eb8:	b7f5                	j	80001ea4 <fork+0x126>

0000000080001eba <scheduler>:
{
    80001eba:	7139                	addi	sp,sp,-64
    80001ebc:	fc06                	sd	ra,56(sp)
    80001ebe:	f822                	sd	s0,48(sp)
    80001ec0:	f426                	sd	s1,40(sp)
    80001ec2:	f04a                	sd	s2,32(sp)
    80001ec4:	ec4e                	sd	s3,24(sp)
    80001ec6:	e852                	sd	s4,16(sp)
    80001ec8:	e456                	sd	s5,8(sp)
    80001eca:	e05a                	sd	s6,0(sp)
    80001ecc:	0080                	addi	s0,sp,64
    80001ece:	8792                	mv	a5,tp
  int id = r_tp();
    80001ed0:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ed2:	00779a93          	slli	s5,a5,0x7
    80001ed6:	0000f717          	auipc	a4,0xf
    80001eda:	3ca70713          	addi	a4,a4,970 # 800112a0 <pid_lock>
    80001ede:	9756                	add	a4,a4,s5
    80001ee0:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ee4:	0000f717          	auipc	a4,0xf
    80001ee8:	3f470713          	addi	a4,a4,1012 # 800112d8 <cpus+0x8>
    80001eec:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001eee:	498d                	li	s3,3
        p->state = RUNNING;
    80001ef0:	4b11                	li	s6,4
        c->proc = p;
    80001ef2:	079e                	slli	a5,a5,0x7
    80001ef4:	0000fa17          	auipc	s4,0xf
    80001ef8:	3aca0a13          	addi	s4,s4,940 # 800112a0 <pid_lock>
    80001efc:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001efe:	00015917          	auipc	s2,0x15
    80001f02:	1d290913          	addi	s2,s2,466 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f06:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f0a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f0e:	10079073          	csrw	sstatus,a5
    80001f12:	0000f497          	auipc	s1,0xf
    80001f16:	7be48493          	addi	s1,s1,1982 # 800116d0 <proc>
    80001f1a:	a03d                	j	80001f48 <scheduler+0x8e>
        p->state = RUNNING;
    80001f1c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f20:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f24:	06048593          	addi	a1,s1,96
    80001f28:	8556                	mv	a0,s5
    80001f2a:	00000097          	auipc	ra,0x0
    80001f2e:	640080e7          	jalr	1600(ra) # 8000256a <swtch>
        c->proc = 0;
    80001f32:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f36:	8526                	mv	a0,s1
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	d60080e7          	jalr	-672(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f40:	16848493          	addi	s1,s1,360
    80001f44:	fd2481e3          	beq	s1,s2,80001f06 <scheduler+0x4c>
      acquire(&p->lock);
    80001f48:	8526                	mv	a0,s1
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	c9a080e7          	jalr	-870(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001f52:	4c9c                	lw	a5,24(s1)
    80001f54:	ff3791e3          	bne	a5,s3,80001f36 <scheduler+0x7c>
    80001f58:	b7d1                	j	80001f1c <scheduler+0x62>

0000000080001f5a <sched>:
{
    80001f5a:	7179                	addi	sp,sp,-48
    80001f5c:	f406                	sd	ra,40(sp)
    80001f5e:	f022                	sd	s0,32(sp)
    80001f60:	ec26                	sd	s1,24(sp)
    80001f62:	e84a                	sd	s2,16(sp)
    80001f64:	e44e                	sd	s3,8(sp)
    80001f66:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f68:	00000097          	auipc	ra,0x0
    80001f6c:	a48080e7          	jalr	-1464(ra) # 800019b0 <myproc>
    80001f70:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	bf8080e7          	jalr	-1032(ra) # 80000b6a <holding>
    80001f7a:	c93d                	beqz	a0,80001ff0 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f7c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f7e:	2781                	sext.w	a5,a5
    80001f80:	079e                	slli	a5,a5,0x7
    80001f82:	0000f717          	auipc	a4,0xf
    80001f86:	31e70713          	addi	a4,a4,798 # 800112a0 <pid_lock>
    80001f8a:	97ba                	add	a5,a5,a4
    80001f8c:	0a87a703          	lw	a4,168(a5)
    80001f90:	4785                	li	a5,1
    80001f92:	06f71763          	bne	a4,a5,80002000 <sched+0xa6>
  if(p->state == RUNNING)
    80001f96:	4c98                	lw	a4,24(s1)
    80001f98:	4791                	li	a5,4
    80001f9a:	06f70b63          	beq	a4,a5,80002010 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f9e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fa2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fa4:	efb5                	bnez	a5,80002020 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fa6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fa8:	0000f917          	auipc	s2,0xf
    80001fac:	2f890913          	addi	s2,s2,760 # 800112a0 <pid_lock>
    80001fb0:	2781                	sext.w	a5,a5
    80001fb2:	079e                	slli	a5,a5,0x7
    80001fb4:	97ca                	add	a5,a5,s2
    80001fb6:	0ac7a983          	lw	s3,172(a5)
    80001fba:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fbc:	2781                	sext.w	a5,a5
    80001fbe:	079e                	slli	a5,a5,0x7
    80001fc0:	0000f597          	auipc	a1,0xf
    80001fc4:	31858593          	addi	a1,a1,792 # 800112d8 <cpus+0x8>
    80001fc8:	95be                	add	a1,a1,a5
    80001fca:	06048513          	addi	a0,s1,96
    80001fce:	00000097          	auipc	ra,0x0
    80001fd2:	59c080e7          	jalr	1436(ra) # 8000256a <swtch>
    80001fd6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fd8:	2781                	sext.w	a5,a5
    80001fda:	079e                	slli	a5,a5,0x7
    80001fdc:	97ca                	add	a5,a5,s2
    80001fde:	0b37a623          	sw	s3,172(a5)
}
    80001fe2:	70a2                	ld	ra,40(sp)
    80001fe4:	7402                	ld	s0,32(sp)
    80001fe6:	64e2                	ld	s1,24(sp)
    80001fe8:	6942                	ld	s2,16(sp)
    80001fea:	69a2                	ld	s3,8(sp)
    80001fec:	6145                	addi	sp,sp,48
    80001fee:	8082                	ret
    panic("sched p->lock");
    80001ff0:	00006517          	auipc	a0,0x6
    80001ff4:	22850513          	addi	a0,a0,552 # 80008218 <digits+0x1d8>
    80001ff8:	ffffe097          	auipc	ra,0xffffe
    80001ffc:	546080e7          	jalr	1350(ra) # 8000053e <panic>
    panic("sched locks");
    80002000:	00006517          	auipc	a0,0x6
    80002004:	22850513          	addi	a0,a0,552 # 80008228 <digits+0x1e8>
    80002008:	ffffe097          	auipc	ra,0xffffe
    8000200c:	536080e7          	jalr	1334(ra) # 8000053e <panic>
    panic("sched running");
    80002010:	00006517          	auipc	a0,0x6
    80002014:	22850513          	addi	a0,a0,552 # 80008238 <digits+0x1f8>
    80002018:	ffffe097          	auipc	ra,0xffffe
    8000201c:	526080e7          	jalr	1318(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002020:	00006517          	auipc	a0,0x6
    80002024:	22850513          	addi	a0,a0,552 # 80008248 <digits+0x208>
    80002028:	ffffe097          	auipc	ra,0xffffe
    8000202c:	516080e7          	jalr	1302(ra) # 8000053e <panic>

0000000080002030 <yield>:
{
    80002030:	1101                	addi	sp,sp,-32
    80002032:	ec06                	sd	ra,24(sp)
    80002034:	e822                	sd	s0,16(sp)
    80002036:	e426                	sd	s1,8(sp)
    80002038:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000203a:	00000097          	auipc	ra,0x0
    8000203e:	976080e7          	jalr	-1674(ra) # 800019b0 <myproc>
    80002042:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	ba0080e7          	jalr	-1120(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000204c:	478d                	li	a5,3
    8000204e:	cc9c                	sw	a5,24(s1)
  sched();
    80002050:	00000097          	auipc	ra,0x0
    80002054:	f0a080e7          	jalr	-246(ra) # 80001f5a <sched>
  release(&p->lock);
    80002058:	8526                	mv	a0,s1
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	c3e080e7          	jalr	-962(ra) # 80000c98 <release>
}
    80002062:	60e2                	ld	ra,24(sp)
    80002064:	6442                	ld	s0,16(sp)
    80002066:	64a2                	ld	s1,8(sp)
    80002068:	6105                	addi	sp,sp,32
    8000206a:	8082                	ret

000000008000206c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000206c:	7179                	addi	sp,sp,-48
    8000206e:	f406                	sd	ra,40(sp)
    80002070:	f022                	sd	s0,32(sp)
    80002072:	ec26                	sd	s1,24(sp)
    80002074:	e84a                	sd	s2,16(sp)
    80002076:	e44e                	sd	s3,8(sp)
    80002078:	1800                	addi	s0,sp,48
    8000207a:	89aa                	mv	s3,a0
    8000207c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000207e:	00000097          	auipc	ra,0x0
    80002082:	932080e7          	jalr	-1742(ra) # 800019b0 <myproc>
    80002086:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	b5c080e7          	jalr	-1188(ra) # 80000be4 <acquire>
  release(lk);
    80002090:	854a                	mv	a0,s2
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	c06080e7          	jalr	-1018(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000209a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000209e:	4789                	li	a5,2
    800020a0:	cc9c                	sw	a5,24(s1)

  sched();
    800020a2:	00000097          	auipc	ra,0x0
    800020a6:	eb8080e7          	jalr	-328(ra) # 80001f5a <sched>

  // Tidy up.
  p->chan = 0;
    800020aa:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020ae:	8526                	mv	a0,s1
    800020b0:	fffff097          	auipc	ra,0xfffff
    800020b4:	be8080e7          	jalr	-1048(ra) # 80000c98 <release>
  acquire(lk);
    800020b8:	854a                	mv	a0,s2
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	b2a080e7          	jalr	-1238(ra) # 80000be4 <acquire>
}
    800020c2:	70a2                	ld	ra,40(sp)
    800020c4:	7402                	ld	s0,32(sp)
    800020c6:	64e2                	ld	s1,24(sp)
    800020c8:	6942                	ld	s2,16(sp)
    800020ca:	69a2                	ld	s3,8(sp)
    800020cc:	6145                	addi	sp,sp,48
    800020ce:	8082                	ret

00000000800020d0 <wait>:
{
    800020d0:	715d                	addi	sp,sp,-80
    800020d2:	e486                	sd	ra,72(sp)
    800020d4:	e0a2                	sd	s0,64(sp)
    800020d6:	fc26                	sd	s1,56(sp)
    800020d8:	f84a                	sd	s2,48(sp)
    800020da:	f44e                	sd	s3,40(sp)
    800020dc:	f052                	sd	s4,32(sp)
    800020de:	ec56                	sd	s5,24(sp)
    800020e0:	e85a                	sd	s6,16(sp)
    800020e2:	e45e                	sd	s7,8(sp)
    800020e4:	e062                	sd	s8,0(sp)
    800020e6:	0880                	addi	s0,sp,80
    800020e8:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020ea:	00000097          	auipc	ra,0x0
    800020ee:	8c6080e7          	jalr	-1850(ra) # 800019b0 <myproc>
    800020f2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020f4:	0000f517          	auipc	a0,0xf
    800020f8:	1c450513          	addi	a0,a0,452 # 800112b8 <wait_lock>
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	ae8080e7          	jalr	-1304(ra) # 80000be4 <acquire>
    havekids = 0;
    80002104:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002106:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002108:	00015997          	auipc	s3,0x15
    8000210c:	fc898993          	addi	s3,s3,-56 # 800170d0 <tickslock>
        havekids = 1;
    80002110:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002112:	0000fc17          	auipc	s8,0xf
    80002116:	1a6c0c13          	addi	s8,s8,422 # 800112b8 <wait_lock>
    havekids = 0;
    8000211a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000211c:	0000f497          	auipc	s1,0xf
    80002120:	5b448493          	addi	s1,s1,1460 # 800116d0 <proc>
    80002124:	a0bd                	j	80002192 <wait+0xc2>
          pid = np->pid;
    80002126:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000212a:	000b0e63          	beqz	s6,80002146 <wait+0x76>
    8000212e:	4691                	li	a3,4
    80002130:	02c48613          	addi	a2,s1,44
    80002134:	85da                	mv	a1,s6
    80002136:	05093503          	ld	a0,80(s2)
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	538080e7          	jalr	1336(ra) # 80001672 <copyout>
    80002142:	02054563          	bltz	a0,8000216c <wait+0x9c>
          freeproc(np);
    80002146:	8526                	mv	a0,s1
    80002148:	00000097          	auipc	ra,0x0
    8000214c:	a1a080e7          	jalr	-1510(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002150:	8526                	mv	a0,s1
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	b46080e7          	jalr	-1210(ra) # 80000c98 <release>
          release(&wait_lock);
    8000215a:	0000f517          	auipc	a0,0xf
    8000215e:	15e50513          	addi	a0,a0,350 # 800112b8 <wait_lock>
    80002162:	fffff097          	auipc	ra,0xfffff
    80002166:	b36080e7          	jalr	-1226(ra) # 80000c98 <release>
          return pid;
    8000216a:	a09d                	j	800021d0 <wait+0x100>
            release(&np->lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	b2a080e7          	jalr	-1238(ra) # 80000c98 <release>
            release(&wait_lock);
    80002176:	0000f517          	auipc	a0,0xf
    8000217a:	14250513          	addi	a0,a0,322 # 800112b8 <wait_lock>
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	b1a080e7          	jalr	-1254(ra) # 80000c98 <release>
            return -1;
    80002186:	59fd                	li	s3,-1
    80002188:	a0a1                	j	800021d0 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000218a:	16848493          	addi	s1,s1,360
    8000218e:	03348463          	beq	s1,s3,800021b6 <wait+0xe6>
      if(np->parent == p){
    80002192:	7c9c                	ld	a5,56(s1)
    80002194:	ff279be3          	bne	a5,s2,8000218a <wait+0xba>
        acquire(&np->lock);
    80002198:	8526                	mv	a0,s1
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	a4a080e7          	jalr	-1462(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800021a2:	4c9c                	lw	a5,24(s1)
    800021a4:	f94781e3          	beq	a5,s4,80002126 <wait+0x56>
        release(&np->lock);
    800021a8:	8526                	mv	a0,s1
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	aee080e7          	jalr	-1298(ra) # 80000c98 <release>
        havekids = 1;
    800021b2:	8756                	mv	a4,s5
    800021b4:	bfd9                	j	8000218a <wait+0xba>
    if(!havekids || p->killed){
    800021b6:	c701                	beqz	a4,800021be <wait+0xee>
    800021b8:	02892783          	lw	a5,40(s2)
    800021bc:	c79d                	beqz	a5,800021ea <wait+0x11a>
      release(&wait_lock);
    800021be:	0000f517          	auipc	a0,0xf
    800021c2:	0fa50513          	addi	a0,a0,250 # 800112b8 <wait_lock>
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	ad2080e7          	jalr	-1326(ra) # 80000c98 <release>
      return -1;
    800021ce:	59fd                	li	s3,-1
}
    800021d0:	854e                	mv	a0,s3
    800021d2:	60a6                	ld	ra,72(sp)
    800021d4:	6406                	ld	s0,64(sp)
    800021d6:	74e2                	ld	s1,56(sp)
    800021d8:	7942                	ld	s2,48(sp)
    800021da:	79a2                	ld	s3,40(sp)
    800021dc:	7a02                	ld	s4,32(sp)
    800021de:	6ae2                	ld	s5,24(sp)
    800021e0:	6b42                	ld	s6,16(sp)
    800021e2:	6ba2                	ld	s7,8(sp)
    800021e4:	6c02                	ld	s8,0(sp)
    800021e6:	6161                	addi	sp,sp,80
    800021e8:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021ea:	85e2                	mv	a1,s8
    800021ec:	854a                	mv	a0,s2
    800021ee:	00000097          	auipc	ra,0x0
    800021f2:	e7e080e7          	jalr	-386(ra) # 8000206c <sleep>
    havekids = 0;
    800021f6:	b715                	j	8000211a <wait+0x4a>

00000000800021f8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021f8:	7139                	addi	sp,sp,-64
    800021fa:	fc06                	sd	ra,56(sp)
    800021fc:	f822                	sd	s0,48(sp)
    800021fe:	f426                	sd	s1,40(sp)
    80002200:	f04a                	sd	s2,32(sp)
    80002202:	ec4e                	sd	s3,24(sp)
    80002204:	e852                	sd	s4,16(sp)
    80002206:	e456                	sd	s5,8(sp)
    80002208:	0080                	addi	s0,sp,64
    8000220a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000220c:	0000f497          	auipc	s1,0xf
    80002210:	4c448493          	addi	s1,s1,1220 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002214:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002216:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002218:	00015917          	auipc	s2,0x15
    8000221c:	eb890913          	addi	s2,s2,-328 # 800170d0 <tickslock>
    80002220:	a821                	j	80002238 <wakeup+0x40>
        p->state = RUNNABLE;
    80002222:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002226:	8526                	mv	a0,s1
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	a70080e7          	jalr	-1424(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002230:	16848493          	addi	s1,s1,360
    80002234:	03248463          	beq	s1,s2,8000225c <wakeup+0x64>
    if(p != myproc()){
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	778080e7          	jalr	1912(ra) # 800019b0 <myproc>
    80002240:	fea488e3          	beq	s1,a0,80002230 <wakeup+0x38>
      acquire(&p->lock);
    80002244:	8526                	mv	a0,s1
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	99e080e7          	jalr	-1634(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000224e:	4c9c                	lw	a5,24(s1)
    80002250:	fd379be3          	bne	a5,s3,80002226 <wakeup+0x2e>
    80002254:	709c                	ld	a5,32(s1)
    80002256:	fd4798e3          	bne	a5,s4,80002226 <wakeup+0x2e>
    8000225a:	b7e1                	j	80002222 <wakeup+0x2a>
    }
  }
}
    8000225c:	70e2                	ld	ra,56(sp)
    8000225e:	7442                	ld	s0,48(sp)
    80002260:	74a2                	ld	s1,40(sp)
    80002262:	7902                	ld	s2,32(sp)
    80002264:	69e2                	ld	s3,24(sp)
    80002266:	6a42                	ld	s4,16(sp)
    80002268:	6aa2                	ld	s5,8(sp)
    8000226a:	6121                	addi	sp,sp,64
    8000226c:	8082                	ret

000000008000226e <reparent>:
{
    8000226e:	7179                	addi	sp,sp,-48
    80002270:	f406                	sd	ra,40(sp)
    80002272:	f022                	sd	s0,32(sp)
    80002274:	ec26                	sd	s1,24(sp)
    80002276:	e84a                	sd	s2,16(sp)
    80002278:	e44e                	sd	s3,8(sp)
    8000227a:	e052                	sd	s4,0(sp)
    8000227c:	1800                	addi	s0,sp,48
    8000227e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002280:	0000f497          	auipc	s1,0xf
    80002284:	45048493          	addi	s1,s1,1104 # 800116d0 <proc>
      pp->parent = initproc;
    80002288:	00007a17          	auipc	s4,0x7
    8000228c:	da0a0a13          	addi	s4,s4,-608 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002290:	00015997          	auipc	s3,0x15
    80002294:	e4098993          	addi	s3,s3,-448 # 800170d0 <tickslock>
    80002298:	a029                	j	800022a2 <reparent+0x34>
    8000229a:	16848493          	addi	s1,s1,360
    8000229e:	01348d63          	beq	s1,s3,800022b8 <reparent+0x4a>
    if(pp->parent == p){
    800022a2:	7c9c                	ld	a5,56(s1)
    800022a4:	ff279be3          	bne	a5,s2,8000229a <reparent+0x2c>
      pp->parent = initproc;
    800022a8:	000a3503          	ld	a0,0(s4)
    800022ac:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022ae:	00000097          	auipc	ra,0x0
    800022b2:	f4a080e7          	jalr	-182(ra) # 800021f8 <wakeup>
    800022b6:	b7d5                	j	8000229a <reparent+0x2c>
}
    800022b8:	70a2                	ld	ra,40(sp)
    800022ba:	7402                	ld	s0,32(sp)
    800022bc:	64e2                	ld	s1,24(sp)
    800022be:	6942                	ld	s2,16(sp)
    800022c0:	69a2                	ld	s3,8(sp)
    800022c2:	6a02                	ld	s4,0(sp)
    800022c4:	6145                	addi	sp,sp,48
    800022c6:	8082                	ret

00000000800022c8 <exit>:
{
    800022c8:	7179                	addi	sp,sp,-48
    800022ca:	f406                	sd	ra,40(sp)
    800022cc:	f022                	sd	s0,32(sp)
    800022ce:	ec26                	sd	s1,24(sp)
    800022d0:	e84a                	sd	s2,16(sp)
    800022d2:	e44e                	sd	s3,8(sp)
    800022d4:	e052                	sd	s4,0(sp)
    800022d6:	1800                	addi	s0,sp,48
    800022d8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	6d6080e7          	jalr	1750(ra) # 800019b0 <myproc>
    800022e2:	89aa                	mv	s3,a0
  if(p == initproc)
    800022e4:	00007797          	auipc	a5,0x7
    800022e8:	d447b783          	ld	a5,-700(a5) # 80009028 <initproc>
    800022ec:	0d050493          	addi	s1,a0,208
    800022f0:	15050913          	addi	s2,a0,336
    800022f4:	02a79363          	bne	a5,a0,8000231a <exit+0x52>
    panic("init exiting");
    800022f8:	00006517          	auipc	a0,0x6
    800022fc:	f6850513          	addi	a0,a0,-152 # 80008260 <digits+0x220>
    80002300:	ffffe097          	auipc	ra,0xffffe
    80002304:	23e080e7          	jalr	574(ra) # 8000053e <panic>
      fileclose(f);
    80002308:	00002097          	auipc	ra,0x2
    8000230c:	22c080e7          	jalr	556(ra) # 80004534 <fileclose>
      p->ofile[fd] = 0;
    80002310:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002314:	04a1                	addi	s1,s1,8
    80002316:	01248563          	beq	s1,s2,80002320 <exit+0x58>
    if(p->ofile[fd]){
    8000231a:	6088                	ld	a0,0(s1)
    8000231c:	f575                	bnez	a0,80002308 <exit+0x40>
    8000231e:	bfdd                	j	80002314 <exit+0x4c>
  begin_op();
    80002320:	00002097          	auipc	ra,0x2
    80002324:	d48080e7          	jalr	-696(ra) # 80004068 <begin_op>
  iput(p->cwd);
    80002328:	1509b503          	ld	a0,336(s3)
    8000232c:	00001097          	auipc	ra,0x1
    80002330:	522080e7          	jalr	1314(ra) # 8000384e <iput>
  end_op();
    80002334:	00002097          	auipc	ra,0x2
    80002338:	db4080e7          	jalr	-588(ra) # 800040e8 <end_op>
  p->cwd = 0;
    8000233c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002340:	0000f497          	auipc	s1,0xf
    80002344:	f7848493          	addi	s1,s1,-136 # 800112b8 <wait_lock>
    80002348:	8526                	mv	a0,s1
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	89a080e7          	jalr	-1894(ra) # 80000be4 <acquire>
  reparent(p);
    80002352:	854e                	mv	a0,s3
    80002354:	00000097          	auipc	ra,0x0
    80002358:	f1a080e7          	jalr	-230(ra) # 8000226e <reparent>
  wakeup(p->parent);
    8000235c:	0389b503          	ld	a0,56(s3)
    80002360:	00000097          	auipc	ra,0x0
    80002364:	e98080e7          	jalr	-360(ra) # 800021f8 <wakeup>
  acquire(&p->lock);
    80002368:	854e                	mv	a0,s3
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	87a080e7          	jalr	-1926(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002372:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002376:	4795                	li	a5,5
    80002378:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000237c:	8526                	mv	a0,s1
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	91a080e7          	jalr	-1766(ra) # 80000c98 <release>
  sched();
    80002386:	00000097          	auipc	ra,0x0
    8000238a:	bd4080e7          	jalr	-1068(ra) # 80001f5a <sched>
  panic("zombie exit");
    8000238e:	00006517          	auipc	a0,0x6
    80002392:	ee250513          	addi	a0,a0,-286 # 80008270 <digits+0x230>
    80002396:	ffffe097          	auipc	ra,0xffffe
    8000239a:	1a8080e7          	jalr	424(ra) # 8000053e <panic>

000000008000239e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000239e:	7179                	addi	sp,sp,-48
    800023a0:	f406                	sd	ra,40(sp)
    800023a2:	f022                	sd	s0,32(sp)
    800023a4:	ec26                	sd	s1,24(sp)
    800023a6:	e84a                	sd	s2,16(sp)
    800023a8:	e44e                	sd	s3,8(sp)
    800023aa:	1800                	addi	s0,sp,48
    800023ac:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023ae:	0000f497          	auipc	s1,0xf
    800023b2:	32248493          	addi	s1,s1,802 # 800116d0 <proc>
    800023b6:	00015997          	auipc	s3,0x15
    800023ba:	d1a98993          	addi	s3,s3,-742 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023be:	8526                	mv	a0,s1
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	824080e7          	jalr	-2012(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800023c8:	589c                	lw	a5,48(s1)
    800023ca:	01278d63          	beq	a5,s2,800023e4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	8c8080e7          	jalr	-1848(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023d8:	16848493          	addi	s1,s1,360
    800023dc:	ff3491e3          	bne	s1,s3,800023be <kill+0x20>
  }
  return -1;
    800023e0:	557d                	li	a0,-1
    800023e2:	a829                	j	800023fc <kill+0x5e>
      p->killed = 1;
    800023e4:	4785                	li	a5,1
    800023e6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023e8:	4c98                	lw	a4,24(s1)
    800023ea:	4789                	li	a5,2
    800023ec:	00f70f63          	beq	a4,a5,8000240a <kill+0x6c>
      release(&p->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	8a6080e7          	jalr	-1882(ra) # 80000c98 <release>
      return 0;
    800023fa:	4501                	li	a0,0
}
    800023fc:	70a2                	ld	ra,40(sp)
    800023fe:	7402                	ld	s0,32(sp)
    80002400:	64e2                	ld	s1,24(sp)
    80002402:	6942                	ld	s2,16(sp)
    80002404:	69a2                	ld	s3,8(sp)
    80002406:	6145                	addi	sp,sp,48
    80002408:	8082                	ret
        p->state = RUNNABLE;
    8000240a:	478d                	li	a5,3
    8000240c:	cc9c                	sw	a5,24(s1)
    8000240e:	b7cd                	j	800023f0 <kill+0x52>

0000000080002410 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002410:	7179                	addi	sp,sp,-48
    80002412:	f406                	sd	ra,40(sp)
    80002414:	f022                	sd	s0,32(sp)
    80002416:	ec26                	sd	s1,24(sp)
    80002418:	e84a                	sd	s2,16(sp)
    8000241a:	e44e                	sd	s3,8(sp)
    8000241c:	e052                	sd	s4,0(sp)
    8000241e:	1800                	addi	s0,sp,48
    80002420:	84aa                	mv	s1,a0
    80002422:	892e                	mv	s2,a1
    80002424:	89b2                	mv	s3,a2
    80002426:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	588080e7          	jalr	1416(ra) # 800019b0 <myproc>
  if(user_dst){
    80002430:	c08d                	beqz	s1,80002452 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002432:	86d2                	mv	a3,s4
    80002434:	864e                	mv	a2,s3
    80002436:	85ca                	mv	a1,s2
    80002438:	6928                	ld	a0,80(a0)
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	238080e7          	jalr	568(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002442:	70a2                	ld	ra,40(sp)
    80002444:	7402                	ld	s0,32(sp)
    80002446:	64e2                	ld	s1,24(sp)
    80002448:	6942                	ld	s2,16(sp)
    8000244a:	69a2                	ld	s3,8(sp)
    8000244c:	6a02                	ld	s4,0(sp)
    8000244e:	6145                	addi	sp,sp,48
    80002450:	8082                	ret
    memmove((char *)dst, src, len);
    80002452:	000a061b          	sext.w	a2,s4
    80002456:	85ce                	mv	a1,s3
    80002458:	854a                	mv	a0,s2
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	8e6080e7          	jalr	-1818(ra) # 80000d40 <memmove>
    return 0;
    80002462:	8526                	mv	a0,s1
    80002464:	bff9                	j	80002442 <either_copyout+0x32>

0000000080002466 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002466:	7179                	addi	sp,sp,-48
    80002468:	f406                	sd	ra,40(sp)
    8000246a:	f022                	sd	s0,32(sp)
    8000246c:	ec26                	sd	s1,24(sp)
    8000246e:	e84a                	sd	s2,16(sp)
    80002470:	e44e                	sd	s3,8(sp)
    80002472:	e052                	sd	s4,0(sp)
    80002474:	1800                	addi	s0,sp,48
    80002476:	892a                	mv	s2,a0
    80002478:	84ae                	mv	s1,a1
    8000247a:	89b2                	mv	s3,a2
    8000247c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	532080e7          	jalr	1330(ra) # 800019b0 <myproc>
  if(user_src){
    80002486:	c08d                	beqz	s1,800024a8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002488:	86d2                	mv	a3,s4
    8000248a:	864e                	mv	a2,s3
    8000248c:	85ca                	mv	a1,s2
    8000248e:	6928                	ld	a0,80(a0)
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	26e080e7          	jalr	622(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002498:	70a2                	ld	ra,40(sp)
    8000249a:	7402                	ld	s0,32(sp)
    8000249c:	64e2                	ld	s1,24(sp)
    8000249e:	6942                	ld	s2,16(sp)
    800024a0:	69a2                	ld	s3,8(sp)
    800024a2:	6a02                	ld	s4,0(sp)
    800024a4:	6145                	addi	sp,sp,48
    800024a6:	8082                	ret
    memmove(dst, (char*)src, len);
    800024a8:	000a061b          	sext.w	a2,s4
    800024ac:	85ce                	mv	a1,s3
    800024ae:	854a                	mv	a0,s2
    800024b0:	fffff097          	auipc	ra,0xfffff
    800024b4:	890080e7          	jalr	-1904(ra) # 80000d40 <memmove>
    return 0;
    800024b8:	8526                	mv	a0,s1
    800024ba:	bff9                	j	80002498 <either_copyin+0x32>

00000000800024bc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024bc:	715d                	addi	sp,sp,-80
    800024be:	e486                	sd	ra,72(sp)
    800024c0:	e0a2                	sd	s0,64(sp)
    800024c2:	fc26                	sd	s1,56(sp)
    800024c4:	f84a                	sd	s2,48(sp)
    800024c6:	f44e                	sd	s3,40(sp)
    800024c8:	f052                	sd	s4,32(sp)
    800024ca:	ec56                	sd	s5,24(sp)
    800024cc:	e85a                	sd	s6,16(sp)
    800024ce:	e45e                	sd	s7,8(sp)
    800024d0:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024d2:	00006517          	auipc	a0,0x6
    800024d6:	bf650513          	addi	a0,a0,-1034 # 800080c8 <digits+0x88>
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	0ae080e7          	jalr	174(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024e2:	0000f497          	auipc	s1,0xf
    800024e6:	34648493          	addi	s1,s1,838 # 80011828 <proc+0x158>
    800024ea:	00015917          	auipc	s2,0x15
    800024ee:	d3e90913          	addi	s2,s2,-706 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024f2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024f4:	00006997          	auipc	s3,0x6
    800024f8:	d8c98993          	addi	s3,s3,-628 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800024fc:	00006a97          	auipc	s5,0x6
    80002500:	d8ca8a93          	addi	s5,s5,-628 # 80008288 <digits+0x248>
    printf("\n");
    80002504:	00006a17          	auipc	s4,0x6
    80002508:	bc4a0a13          	addi	s4,s4,-1084 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000250c:	00006b97          	auipc	s7,0x6
    80002510:	db4b8b93          	addi	s7,s7,-588 # 800082c0 <states.1709>
    80002514:	a00d                	j	80002536 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002516:	ed86a583          	lw	a1,-296(a3)
    8000251a:	8556                	mv	a0,s5
    8000251c:	ffffe097          	auipc	ra,0xffffe
    80002520:	06c080e7          	jalr	108(ra) # 80000588 <printf>
    printf("\n");
    80002524:	8552                	mv	a0,s4
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	062080e7          	jalr	98(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000252e:	16848493          	addi	s1,s1,360
    80002532:	03248163          	beq	s1,s2,80002554 <procdump+0x98>
    if(p->state == UNUSED)
    80002536:	86a6                	mv	a3,s1
    80002538:	ec04a783          	lw	a5,-320(s1)
    8000253c:	dbed                	beqz	a5,8000252e <procdump+0x72>
      state = "???";
    8000253e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002540:	fcfb6be3          	bltu	s6,a5,80002516 <procdump+0x5a>
    80002544:	1782                	slli	a5,a5,0x20
    80002546:	9381                	srli	a5,a5,0x20
    80002548:	078e                	slli	a5,a5,0x3
    8000254a:	97de                	add	a5,a5,s7
    8000254c:	6390                	ld	a2,0(a5)
    8000254e:	f661                	bnez	a2,80002516 <procdump+0x5a>
      state = "???";
    80002550:	864e                	mv	a2,s3
    80002552:	b7d1                	j	80002516 <procdump+0x5a>
  }
}
    80002554:	60a6                	ld	ra,72(sp)
    80002556:	6406                	ld	s0,64(sp)
    80002558:	74e2                	ld	s1,56(sp)
    8000255a:	7942                	ld	s2,48(sp)
    8000255c:	79a2                	ld	s3,40(sp)
    8000255e:	7a02                	ld	s4,32(sp)
    80002560:	6ae2                	ld	s5,24(sp)
    80002562:	6b42                	ld	s6,16(sp)
    80002564:	6ba2                	ld	s7,8(sp)
    80002566:	6161                	addi	sp,sp,80
    80002568:	8082                	ret

000000008000256a <swtch>:
    8000256a:	00153023          	sd	ra,0(a0)
    8000256e:	00253423          	sd	sp,8(a0)
    80002572:	e900                	sd	s0,16(a0)
    80002574:	ed04                	sd	s1,24(a0)
    80002576:	03253023          	sd	s2,32(a0)
    8000257a:	03353423          	sd	s3,40(a0)
    8000257e:	03453823          	sd	s4,48(a0)
    80002582:	03553c23          	sd	s5,56(a0)
    80002586:	05653023          	sd	s6,64(a0)
    8000258a:	05753423          	sd	s7,72(a0)
    8000258e:	05853823          	sd	s8,80(a0)
    80002592:	05953c23          	sd	s9,88(a0)
    80002596:	07a53023          	sd	s10,96(a0)
    8000259a:	07b53423          	sd	s11,104(a0)
    8000259e:	0005b083          	ld	ra,0(a1)
    800025a2:	0085b103          	ld	sp,8(a1)
    800025a6:	6980                	ld	s0,16(a1)
    800025a8:	6d84                	ld	s1,24(a1)
    800025aa:	0205b903          	ld	s2,32(a1)
    800025ae:	0285b983          	ld	s3,40(a1)
    800025b2:	0305ba03          	ld	s4,48(a1)
    800025b6:	0385ba83          	ld	s5,56(a1)
    800025ba:	0405bb03          	ld	s6,64(a1)
    800025be:	0485bb83          	ld	s7,72(a1)
    800025c2:	0505bc03          	ld	s8,80(a1)
    800025c6:	0585bc83          	ld	s9,88(a1)
    800025ca:	0605bd03          	ld	s10,96(a1)
    800025ce:	0685bd83          	ld	s11,104(a1)
    800025d2:	8082                	ret

00000000800025d4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025d4:	1141                	addi	sp,sp,-16
    800025d6:	e406                	sd	ra,8(sp)
    800025d8:	e022                	sd	s0,0(sp)
    800025da:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025dc:	00006597          	auipc	a1,0x6
    800025e0:	d1458593          	addi	a1,a1,-748 # 800082f0 <states.1709+0x30>
    800025e4:	00015517          	auipc	a0,0x15
    800025e8:	aec50513          	addi	a0,a0,-1300 # 800170d0 <tickslock>
    800025ec:	ffffe097          	auipc	ra,0xffffe
    800025f0:	568080e7          	jalr	1384(ra) # 80000b54 <initlock>
}
    800025f4:	60a2                	ld	ra,8(sp)
    800025f6:	6402                	ld	s0,0(sp)
    800025f8:	0141                	addi	sp,sp,16
    800025fa:	8082                	ret

00000000800025fc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800025fc:	1141                	addi	sp,sp,-16
    800025fe:	e422                	sd	s0,8(sp)
    80002600:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002602:	00003797          	auipc	a5,0x3
    80002606:	54e78793          	addi	a5,a5,1358 # 80005b50 <kernelvec>
    8000260a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000260e:	6422                	ld	s0,8(sp)
    80002610:	0141                	addi	sp,sp,16
    80002612:	8082                	ret

0000000080002614 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002614:	1141                	addi	sp,sp,-16
    80002616:	e406                	sd	ra,8(sp)
    80002618:	e022                	sd	s0,0(sp)
    8000261a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000261c:	fffff097          	auipc	ra,0xfffff
    80002620:	394080e7          	jalr	916(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002624:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002628:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000262a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000262e:	00005617          	auipc	a2,0x5
    80002632:	9d260613          	addi	a2,a2,-1582 # 80007000 <_trampoline>
    80002636:	00005697          	auipc	a3,0x5
    8000263a:	9ca68693          	addi	a3,a3,-1590 # 80007000 <_trampoline>
    8000263e:	8e91                	sub	a3,a3,a2
    80002640:	040007b7          	lui	a5,0x4000
    80002644:	17fd                	addi	a5,a5,-1
    80002646:	07b2                	slli	a5,a5,0xc
    80002648:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000264a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000264e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002650:	180026f3          	csrr	a3,satp
    80002654:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002656:	6d38                	ld	a4,88(a0)
    80002658:	6134                	ld	a3,64(a0)
    8000265a:	6585                	lui	a1,0x1
    8000265c:	96ae                	add	a3,a3,a1
    8000265e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002660:	6d38                	ld	a4,88(a0)
    80002662:	00000697          	auipc	a3,0x0
    80002666:	13868693          	addi	a3,a3,312 # 8000279a <usertrap>
    8000266a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000266c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000266e:	8692                	mv	a3,tp
    80002670:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002672:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002676:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000267a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000267e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002682:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002684:	6f18                	ld	a4,24(a4)
    80002686:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000268a:	692c                	ld	a1,80(a0)
    8000268c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000268e:	00005717          	auipc	a4,0x5
    80002692:	a0270713          	addi	a4,a4,-1534 # 80007090 <userret>
    80002696:	8f11                	sub	a4,a4,a2
    80002698:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000269a:	577d                	li	a4,-1
    8000269c:	177e                	slli	a4,a4,0x3f
    8000269e:	8dd9                	or	a1,a1,a4
    800026a0:	02000537          	lui	a0,0x2000
    800026a4:	157d                	addi	a0,a0,-1
    800026a6:	0536                	slli	a0,a0,0xd
    800026a8:	9782                	jalr	a5
}
    800026aa:	60a2                	ld	ra,8(sp)
    800026ac:	6402                	ld	s0,0(sp)
    800026ae:	0141                	addi	sp,sp,16
    800026b0:	8082                	ret

00000000800026b2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026b2:	1101                	addi	sp,sp,-32
    800026b4:	ec06                	sd	ra,24(sp)
    800026b6:	e822                	sd	s0,16(sp)
    800026b8:	e426                	sd	s1,8(sp)
    800026ba:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026bc:	00015497          	auipc	s1,0x15
    800026c0:	a1448493          	addi	s1,s1,-1516 # 800170d0 <tickslock>
    800026c4:	8526                	mv	a0,s1
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	51e080e7          	jalr	1310(ra) # 80000be4 <acquire>
  ticks++;
    800026ce:	00007517          	auipc	a0,0x7
    800026d2:	96250513          	addi	a0,a0,-1694 # 80009030 <ticks>
    800026d6:	411c                	lw	a5,0(a0)
    800026d8:	2785                	addiw	a5,a5,1
    800026da:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800026dc:	00000097          	auipc	ra,0x0
    800026e0:	b1c080e7          	jalr	-1252(ra) # 800021f8 <wakeup>
  release(&tickslock);
    800026e4:	8526                	mv	a0,s1
    800026e6:	ffffe097          	auipc	ra,0xffffe
    800026ea:	5b2080e7          	jalr	1458(ra) # 80000c98 <release>
}
    800026ee:	60e2                	ld	ra,24(sp)
    800026f0:	6442                	ld	s0,16(sp)
    800026f2:	64a2                	ld	s1,8(sp)
    800026f4:	6105                	addi	sp,sp,32
    800026f6:	8082                	ret

00000000800026f8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800026f8:	1101                	addi	sp,sp,-32
    800026fa:	ec06                	sd	ra,24(sp)
    800026fc:	e822                	sd	s0,16(sp)
    800026fe:	e426                	sd	s1,8(sp)
    80002700:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002702:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002706:	00074d63          	bltz	a4,80002720 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000270a:	57fd                	li	a5,-1
    8000270c:	17fe                	slli	a5,a5,0x3f
    8000270e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002710:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002712:	06f70363          	beq	a4,a5,80002778 <devintr+0x80>
  }
}
    80002716:	60e2                	ld	ra,24(sp)
    80002718:	6442                	ld	s0,16(sp)
    8000271a:	64a2                	ld	s1,8(sp)
    8000271c:	6105                	addi	sp,sp,32
    8000271e:	8082                	ret
     (scause & 0xff) == 9){
    80002720:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002724:	46a5                	li	a3,9
    80002726:	fed792e3          	bne	a5,a3,8000270a <devintr+0x12>
    int irq = plic_claim();
    8000272a:	00003097          	auipc	ra,0x3
    8000272e:	52e080e7          	jalr	1326(ra) # 80005c58 <plic_claim>
    80002732:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002734:	47a9                	li	a5,10
    80002736:	02f50763          	beq	a0,a5,80002764 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000273a:	4785                	li	a5,1
    8000273c:	02f50963          	beq	a0,a5,8000276e <devintr+0x76>
    return 1;
    80002740:	4505                	li	a0,1
    } else if(irq){
    80002742:	d8f1                	beqz	s1,80002716 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002744:	85a6                	mv	a1,s1
    80002746:	00006517          	auipc	a0,0x6
    8000274a:	bb250513          	addi	a0,a0,-1102 # 800082f8 <states.1709+0x38>
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	e3a080e7          	jalr	-454(ra) # 80000588 <printf>
      plic_complete(irq);
    80002756:	8526                	mv	a0,s1
    80002758:	00003097          	auipc	ra,0x3
    8000275c:	524080e7          	jalr	1316(ra) # 80005c7c <plic_complete>
    return 1;
    80002760:	4505                	li	a0,1
    80002762:	bf55                	j	80002716 <devintr+0x1e>
      uartintr();
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	244080e7          	jalr	580(ra) # 800009a8 <uartintr>
    8000276c:	b7ed                	j	80002756 <devintr+0x5e>
      virtio_disk_intr();
    8000276e:	00004097          	auipc	ra,0x4
    80002772:	9ee080e7          	jalr	-1554(ra) # 8000615c <virtio_disk_intr>
    80002776:	b7c5                	j	80002756 <devintr+0x5e>
    if(cpuid() == 0){
    80002778:	fffff097          	auipc	ra,0xfffff
    8000277c:	20c080e7          	jalr	524(ra) # 80001984 <cpuid>
    80002780:	c901                	beqz	a0,80002790 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002782:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002786:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002788:	14479073          	csrw	sip,a5
    return 2;
    8000278c:	4509                	li	a0,2
    8000278e:	b761                	j	80002716 <devintr+0x1e>
      clockintr();
    80002790:	00000097          	auipc	ra,0x0
    80002794:	f22080e7          	jalr	-222(ra) # 800026b2 <clockintr>
    80002798:	b7ed                	j	80002782 <devintr+0x8a>

000000008000279a <usertrap>:
{
    8000279a:	1101                	addi	sp,sp,-32
    8000279c:	ec06                	sd	ra,24(sp)
    8000279e:	e822                	sd	s0,16(sp)
    800027a0:	e426                	sd	s1,8(sp)
    800027a2:	e04a                	sd	s2,0(sp)
    800027a4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027a6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027aa:	1007f793          	andi	a5,a5,256
    800027ae:	e3ad                	bnez	a5,80002810 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027b0:	00003797          	auipc	a5,0x3
    800027b4:	3a078793          	addi	a5,a5,928 # 80005b50 <kernelvec>
    800027b8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027bc:	fffff097          	auipc	ra,0xfffff
    800027c0:	1f4080e7          	jalr	500(ra) # 800019b0 <myproc>
    800027c4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027c6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027c8:	14102773          	csrr	a4,sepc
    800027cc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027ce:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027d2:	47a1                	li	a5,8
    800027d4:	04f71c63          	bne	a4,a5,8000282c <usertrap+0x92>
    if(p->killed)
    800027d8:	551c                	lw	a5,40(a0)
    800027da:	e3b9                	bnez	a5,80002820 <usertrap+0x86>
    p->trapframe->epc += 4;
    800027dc:	6cb8                	ld	a4,88(s1)
    800027de:	6f1c                	ld	a5,24(a4)
    800027e0:	0791                	addi	a5,a5,4
    800027e2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027e8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027ec:	10079073          	csrw	sstatus,a5
    syscall();
    800027f0:	00000097          	auipc	ra,0x0
    800027f4:	2e0080e7          	jalr	736(ra) # 80002ad0 <syscall>
  if(p->killed)
    800027f8:	549c                	lw	a5,40(s1)
    800027fa:	ebc1                	bnez	a5,8000288a <usertrap+0xf0>
  usertrapret();
    800027fc:	00000097          	auipc	ra,0x0
    80002800:	e18080e7          	jalr	-488(ra) # 80002614 <usertrapret>
}
    80002804:	60e2                	ld	ra,24(sp)
    80002806:	6442                	ld	s0,16(sp)
    80002808:	64a2                	ld	s1,8(sp)
    8000280a:	6902                	ld	s2,0(sp)
    8000280c:	6105                	addi	sp,sp,32
    8000280e:	8082                	ret
    panic("usertrap: not from user mode");
    80002810:	00006517          	auipc	a0,0x6
    80002814:	b0850513          	addi	a0,a0,-1272 # 80008318 <states.1709+0x58>
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	d26080e7          	jalr	-730(ra) # 8000053e <panic>
      exit(-1);
    80002820:	557d                	li	a0,-1
    80002822:	00000097          	auipc	ra,0x0
    80002826:	aa6080e7          	jalr	-1370(ra) # 800022c8 <exit>
    8000282a:	bf4d                	j	800027dc <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000282c:	00000097          	auipc	ra,0x0
    80002830:	ecc080e7          	jalr	-308(ra) # 800026f8 <devintr>
    80002834:	892a                	mv	s2,a0
    80002836:	c501                	beqz	a0,8000283e <usertrap+0xa4>
  if(p->killed)
    80002838:	549c                	lw	a5,40(s1)
    8000283a:	c3a1                	beqz	a5,8000287a <usertrap+0xe0>
    8000283c:	a815                	j	80002870 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000283e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002842:	5890                	lw	a2,48(s1)
    80002844:	00006517          	auipc	a0,0x6
    80002848:	af450513          	addi	a0,a0,-1292 # 80008338 <states.1709+0x78>
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	d3c080e7          	jalr	-708(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002854:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002858:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000285c:	00006517          	auipc	a0,0x6
    80002860:	b0c50513          	addi	a0,a0,-1268 # 80008368 <states.1709+0xa8>
    80002864:	ffffe097          	auipc	ra,0xffffe
    80002868:	d24080e7          	jalr	-732(ra) # 80000588 <printf>
    p->killed = 1;
    8000286c:	4785                	li	a5,1
    8000286e:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002870:	557d                	li	a0,-1
    80002872:	00000097          	auipc	ra,0x0
    80002876:	a56080e7          	jalr	-1450(ra) # 800022c8 <exit>
  if(which_dev == 2)
    8000287a:	4789                	li	a5,2
    8000287c:	f8f910e3          	bne	s2,a5,800027fc <usertrap+0x62>
    yield();
    80002880:	fffff097          	auipc	ra,0xfffff
    80002884:	7b0080e7          	jalr	1968(ra) # 80002030 <yield>
    80002888:	bf95                	j	800027fc <usertrap+0x62>
  int which_dev = 0;
    8000288a:	4901                	li	s2,0
    8000288c:	b7d5                	j	80002870 <usertrap+0xd6>

000000008000288e <kerneltrap>:
{
    8000288e:	7179                	addi	sp,sp,-48
    80002890:	f406                	sd	ra,40(sp)
    80002892:	f022                	sd	s0,32(sp)
    80002894:	ec26                	sd	s1,24(sp)
    80002896:	e84a                	sd	s2,16(sp)
    80002898:	e44e                	sd	s3,8(sp)
    8000289a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000289c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028a4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028a8:	1004f793          	andi	a5,s1,256
    800028ac:	cb85                	beqz	a5,800028dc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ae:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028b2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028b4:	ef85                	bnez	a5,800028ec <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028b6:	00000097          	auipc	ra,0x0
    800028ba:	e42080e7          	jalr	-446(ra) # 800026f8 <devintr>
    800028be:	cd1d                	beqz	a0,800028fc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028c0:	4789                	li	a5,2
    800028c2:	06f50a63          	beq	a0,a5,80002936 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028c6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ca:	10049073          	csrw	sstatus,s1
}
    800028ce:	70a2                	ld	ra,40(sp)
    800028d0:	7402                	ld	s0,32(sp)
    800028d2:	64e2                	ld	s1,24(sp)
    800028d4:	6942                	ld	s2,16(sp)
    800028d6:	69a2                	ld	s3,8(sp)
    800028d8:	6145                	addi	sp,sp,48
    800028da:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028dc:	00006517          	auipc	a0,0x6
    800028e0:	aac50513          	addi	a0,a0,-1364 # 80008388 <states.1709+0xc8>
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	c5a080e7          	jalr	-934(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800028ec:	00006517          	auipc	a0,0x6
    800028f0:	ac450513          	addi	a0,a0,-1340 # 800083b0 <states.1709+0xf0>
    800028f4:	ffffe097          	auipc	ra,0xffffe
    800028f8:	c4a080e7          	jalr	-950(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800028fc:	85ce                	mv	a1,s3
    800028fe:	00006517          	auipc	a0,0x6
    80002902:	ad250513          	addi	a0,a0,-1326 # 800083d0 <states.1709+0x110>
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	c82080e7          	jalr	-894(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000290e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002912:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002916:	00006517          	auipc	a0,0x6
    8000291a:	aca50513          	addi	a0,a0,-1334 # 800083e0 <states.1709+0x120>
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	c6a080e7          	jalr	-918(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002926:	00006517          	auipc	a0,0x6
    8000292a:	ad250513          	addi	a0,a0,-1326 # 800083f8 <states.1709+0x138>
    8000292e:	ffffe097          	auipc	ra,0xffffe
    80002932:	c10080e7          	jalr	-1008(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002936:	fffff097          	auipc	ra,0xfffff
    8000293a:	07a080e7          	jalr	122(ra) # 800019b0 <myproc>
    8000293e:	d541                	beqz	a0,800028c6 <kerneltrap+0x38>
    80002940:	fffff097          	auipc	ra,0xfffff
    80002944:	070080e7          	jalr	112(ra) # 800019b0 <myproc>
    80002948:	4d18                	lw	a4,24(a0)
    8000294a:	4791                	li	a5,4
    8000294c:	f6f71de3          	bne	a4,a5,800028c6 <kerneltrap+0x38>
    yield();
    80002950:	fffff097          	auipc	ra,0xfffff
    80002954:	6e0080e7          	jalr	1760(ra) # 80002030 <yield>
    80002958:	b7bd                	j	800028c6 <kerneltrap+0x38>

000000008000295a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000295a:	1101                	addi	sp,sp,-32
    8000295c:	ec06                	sd	ra,24(sp)
    8000295e:	e822                	sd	s0,16(sp)
    80002960:	e426                	sd	s1,8(sp)
    80002962:	1000                	addi	s0,sp,32
    80002964:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002966:	fffff097          	auipc	ra,0xfffff
    8000296a:	04a080e7          	jalr	74(ra) # 800019b0 <myproc>
  switch (n) {
    8000296e:	4795                	li	a5,5
    80002970:	0497e163          	bltu	a5,s1,800029b2 <argraw+0x58>
    80002974:	048a                	slli	s1,s1,0x2
    80002976:	00006717          	auipc	a4,0x6
    8000297a:	aba70713          	addi	a4,a4,-1350 # 80008430 <states.1709+0x170>
    8000297e:	94ba                	add	s1,s1,a4
    80002980:	409c                	lw	a5,0(s1)
    80002982:	97ba                	add	a5,a5,a4
    80002984:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002986:	6d3c                	ld	a5,88(a0)
    80002988:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000298a:	60e2                	ld	ra,24(sp)
    8000298c:	6442                	ld	s0,16(sp)
    8000298e:	64a2                	ld	s1,8(sp)
    80002990:	6105                	addi	sp,sp,32
    80002992:	8082                	ret
    return p->trapframe->a1;
    80002994:	6d3c                	ld	a5,88(a0)
    80002996:	7fa8                	ld	a0,120(a5)
    80002998:	bfcd                	j	8000298a <argraw+0x30>
    return p->trapframe->a2;
    8000299a:	6d3c                	ld	a5,88(a0)
    8000299c:	63c8                	ld	a0,128(a5)
    8000299e:	b7f5                	j	8000298a <argraw+0x30>
    return p->trapframe->a3;
    800029a0:	6d3c                	ld	a5,88(a0)
    800029a2:	67c8                	ld	a0,136(a5)
    800029a4:	b7dd                	j	8000298a <argraw+0x30>
    return p->trapframe->a4;
    800029a6:	6d3c                	ld	a5,88(a0)
    800029a8:	6bc8                	ld	a0,144(a5)
    800029aa:	b7c5                	j	8000298a <argraw+0x30>
    return p->trapframe->a5;
    800029ac:	6d3c                	ld	a5,88(a0)
    800029ae:	6fc8                	ld	a0,152(a5)
    800029b0:	bfe9                	j	8000298a <argraw+0x30>
  panic("argraw");
    800029b2:	00006517          	auipc	a0,0x6
    800029b6:	a5650513          	addi	a0,a0,-1450 # 80008408 <states.1709+0x148>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	b84080e7          	jalr	-1148(ra) # 8000053e <panic>

00000000800029c2 <fetchaddr>:
{
    800029c2:	1101                	addi	sp,sp,-32
    800029c4:	ec06                	sd	ra,24(sp)
    800029c6:	e822                	sd	s0,16(sp)
    800029c8:	e426                	sd	s1,8(sp)
    800029ca:	e04a                	sd	s2,0(sp)
    800029cc:	1000                	addi	s0,sp,32
    800029ce:	84aa                	mv	s1,a0
    800029d0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029d2:	fffff097          	auipc	ra,0xfffff
    800029d6:	fde080e7          	jalr	-34(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800029da:	653c                	ld	a5,72(a0)
    800029dc:	02f4f863          	bgeu	s1,a5,80002a0c <fetchaddr+0x4a>
    800029e0:	00848713          	addi	a4,s1,8
    800029e4:	02e7e663          	bltu	a5,a4,80002a10 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800029e8:	46a1                	li	a3,8
    800029ea:	8626                	mv	a2,s1
    800029ec:	85ca                	mv	a1,s2
    800029ee:	6928                	ld	a0,80(a0)
    800029f0:	fffff097          	auipc	ra,0xfffff
    800029f4:	d0e080e7          	jalr	-754(ra) # 800016fe <copyin>
    800029f8:	00a03533          	snez	a0,a0
    800029fc:	40a00533          	neg	a0,a0
}
    80002a00:	60e2                	ld	ra,24(sp)
    80002a02:	6442                	ld	s0,16(sp)
    80002a04:	64a2                	ld	s1,8(sp)
    80002a06:	6902                	ld	s2,0(sp)
    80002a08:	6105                	addi	sp,sp,32
    80002a0a:	8082                	ret
    return -1;
    80002a0c:	557d                	li	a0,-1
    80002a0e:	bfcd                	j	80002a00 <fetchaddr+0x3e>
    80002a10:	557d                	li	a0,-1
    80002a12:	b7fd                	j	80002a00 <fetchaddr+0x3e>

0000000080002a14 <fetchstr>:
{
    80002a14:	7179                	addi	sp,sp,-48
    80002a16:	f406                	sd	ra,40(sp)
    80002a18:	f022                	sd	s0,32(sp)
    80002a1a:	ec26                	sd	s1,24(sp)
    80002a1c:	e84a                	sd	s2,16(sp)
    80002a1e:	e44e                	sd	s3,8(sp)
    80002a20:	1800                	addi	s0,sp,48
    80002a22:	892a                	mv	s2,a0
    80002a24:	84ae                	mv	s1,a1
    80002a26:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a28:	fffff097          	auipc	ra,0xfffff
    80002a2c:	f88080e7          	jalr	-120(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a30:	86ce                	mv	a3,s3
    80002a32:	864a                	mv	a2,s2
    80002a34:	85a6                	mv	a1,s1
    80002a36:	6928                	ld	a0,80(a0)
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	d52080e7          	jalr	-686(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002a40:	00054763          	bltz	a0,80002a4e <fetchstr+0x3a>
  return strlen(buf);
    80002a44:	8526                	mv	a0,s1
    80002a46:	ffffe097          	auipc	ra,0xffffe
    80002a4a:	41e080e7          	jalr	1054(ra) # 80000e64 <strlen>
}
    80002a4e:	70a2                	ld	ra,40(sp)
    80002a50:	7402                	ld	s0,32(sp)
    80002a52:	64e2                	ld	s1,24(sp)
    80002a54:	6942                	ld	s2,16(sp)
    80002a56:	69a2                	ld	s3,8(sp)
    80002a58:	6145                	addi	sp,sp,48
    80002a5a:	8082                	ret

0000000080002a5c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a5c:	1101                	addi	sp,sp,-32
    80002a5e:	ec06                	sd	ra,24(sp)
    80002a60:	e822                	sd	s0,16(sp)
    80002a62:	e426                	sd	s1,8(sp)
    80002a64:	1000                	addi	s0,sp,32
    80002a66:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	ef2080e7          	jalr	-270(ra) # 8000295a <argraw>
    80002a70:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a72:	4501                	li	a0,0
    80002a74:	60e2                	ld	ra,24(sp)
    80002a76:	6442                	ld	s0,16(sp)
    80002a78:	64a2                	ld	s1,8(sp)
    80002a7a:	6105                	addi	sp,sp,32
    80002a7c:	8082                	ret

0000000080002a7e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002a7e:	1101                	addi	sp,sp,-32
    80002a80:	ec06                	sd	ra,24(sp)
    80002a82:	e822                	sd	s0,16(sp)
    80002a84:	e426                	sd	s1,8(sp)
    80002a86:	1000                	addi	s0,sp,32
    80002a88:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a8a:	00000097          	auipc	ra,0x0
    80002a8e:	ed0080e7          	jalr	-304(ra) # 8000295a <argraw>
    80002a92:	e088                	sd	a0,0(s1)
  return 0;
}
    80002a94:	4501                	li	a0,0
    80002a96:	60e2                	ld	ra,24(sp)
    80002a98:	6442                	ld	s0,16(sp)
    80002a9a:	64a2                	ld	s1,8(sp)
    80002a9c:	6105                	addi	sp,sp,32
    80002a9e:	8082                	ret

0000000080002aa0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002aa0:	1101                	addi	sp,sp,-32
    80002aa2:	ec06                	sd	ra,24(sp)
    80002aa4:	e822                	sd	s0,16(sp)
    80002aa6:	e426                	sd	s1,8(sp)
    80002aa8:	e04a                	sd	s2,0(sp)
    80002aaa:	1000                	addi	s0,sp,32
    80002aac:	84ae                	mv	s1,a1
    80002aae:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ab0:	00000097          	auipc	ra,0x0
    80002ab4:	eaa080e7          	jalr	-342(ra) # 8000295a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ab8:	864a                	mv	a2,s2
    80002aba:	85a6                	mv	a1,s1
    80002abc:	00000097          	auipc	ra,0x0
    80002ac0:	f58080e7          	jalr	-168(ra) # 80002a14 <fetchstr>
}
    80002ac4:	60e2                	ld	ra,24(sp)
    80002ac6:	6442                	ld	s0,16(sp)
    80002ac8:	64a2                	ld	s1,8(sp)
    80002aca:	6902                	ld	s2,0(sp)
    80002acc:	6105                	addi	sp,sp,32
    80002ace:	8082                	ret

0000000080002ad0 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002ad0:	1101                	addi	sp,sp,-32
    80002ad2:	ec06                	sd	ra,24(sp)
    80002ad4:	e822                	sd	s0,16(sp)
    80002ad6:	e426                	sd	s1,8(sp)
    80002ad8:	e04a                	sd	s2,0(sp)
    80002ada:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002adc:	fffff097          	auipc	ra,0xfffff
    80002ae0:	ed4080e7          	jalr	-300(ra) # 800019b0 <myproc>
    80002ae4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ae6:	05853903          	ld	s2,88(a0)
    80002aea:	0a893783          	ld	a5,168(s2)
    80002aee:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002af2:	37fd                	addiw	a5,a5,-1
    80002af4:	4751                	li	a4,20
    80002af6:	00f76f63          	bltu	a4,a5,80002b14 <syscall+0x44>
    80002afa:	00369713          	slli	a4,a3,0x3
    80002afe:	00006797          	auipc	a5,0x6
    80002b02:	94a78793          	addi	a5,a5,-1718 # 80008448 <syscalls>
    80002b06:	97ba                	add	a5,a5,a4
    80002b08:	639c                	ld	a5,0(a5)
    80002b0a:	c789                	beqz	a5,80002b14 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b0c:	9782                	jalr	a5
    80002b0e:	06a93823          	sd	a0,112(s2)
    80002b12:	a839                	j	80002b30 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b14:	15848613          	addi	a2,s1,344
    80002b18:	588c                	lw	a1,48(s1)
    80002b1a:	00006517          	auipc	a0,0x6
    80002b1e:	8f650513          	addi	a0,a0,-1802 # 80008410 <states.1709+0x150>
    80002b22:	ffffe097          	auipc	ra,0xffffe
    80002b26:	a66080e7          	jalr	-1434(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b2a:	6cbc                	ld	a5,88(s1)
    80002b2c:	577d                	li	a4,-1
    80002b2e:	fbb8                	sd	a4,112(a5)
  }
}
    80002b30:	60e2                	ld	ra,24(sp)
    80002b32:	6442                	ld	s0,16(sp)
    80002b34:	64a2                	ld	s1,8(sp)
    80002b36:	6902                	ld	s2,0(sp)
    80002b38:	6105                	addi	sp,sp,32
    80002b3a:	8082                	ret

0000000080002b3c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b3c:	1101                	addi	sp,sp,-32
    80002b3e:	ec06                	sd	ra,24(sp)
    80002b40:	e822                	sd	s0,16(sp)
    80002b42:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b44:	fec40593          	addi	a1,s0,-20
    80002b48:	4501                	li	a0,0
    80002b4a:	00000097          	auipc	ra,0x0
    80002b4e:	f12080e7          	jalr	-238(ra) # 80002a5c <argint>
    return -1;
    80002b52:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b54:	00054963          	bltz	a0,80002b66 <sys_exit+0x2a>
  exit(n);
    80002b58:	fec42503          	lw	a0,-20(s0)
    80002b5c:	fffff097          	auipc	ra,0xfffff
    80002b60:	76c080e7          	jalr	1900(ra) # 800022c8 <exit>
  return 0;  // not reached
    80002b64:	4781                	li	a5,0
}
    80002b66:	853e                	mv	a0,a5
    80002b68:	60e2                	ld	ra,24(sp)
    80002b6a:	6442                	ld	s0,16(sp)
    80002b6c:	6105                	addi	sp,sp,32
    80002b6e:	8082                	ret

0000000080002b70 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b70:	1141                	addi	sp,sp,-16
    80002b72:	e406                	sd	ra,8(sp)
    80002b74:	e022                	sd	s0,0(sp)
    80002b76:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b78:	fffff097          	auipc	ra,0xfffff
    80002b7c:	e38080e7          	jalr	-456(ra) # 800019b0 <myproc>
}
    80002b80:	5908                	lw	a0,48(a0)
    80002b82:	60a2                	ld	ra,8(sp)
    80002b84:	6402                	ld	s0,0(sp)
    80002b86:	0141                	addi	sp,sp,16
    80002b88:	8082                	ret

0000000080002b8a <sys_fork>:

uint64
sys_fork(void)
{
    80002b8a:	1141                	addi	sp,sp,-16
    80002b8c:	e406                	sd	ra,8(sp)
    80002b8e:	e022                	sd	s0,0(sp)
    80002b90:	0800                	addi	s0,sp,16
  return fork();
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	1ec080e7          	jalr	492(ra) # 80001d7e <fork>
}
    80002b9a:	60a2                	ld	ra,8(sp)
    80002b9c:	6402                	ld	s0,0(sp)
    80002b9e:	0141                	addi	sp,sp,16
    80002ba0:	8082                	ret

0000000080002ba2 <sys_wait>:

uint64
sys_wait(void)
{
    80002ba2:	1101                	addi	sp,sp,-32
    80002ba4:	ec06                	sd	ra,24(sp)
    80002ba6:	e822                	sd	s0,16(sp)
    80002ba8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002baa:	fe840593          	addi	a1,s0,-24
    80002bae:	4501                	li	a0,0
    80002bb0:	00000097          	auipc	ra,0x0
    80002bb4:	ece080e7          	jalr	-306(ra) # 80002a7e <argaddr>
    80002bb8:	87aa                	mv	a5,a0
    return -1;
    80002bba:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002bbc:	0007c863          	bltz	a5,80002bcc <sys_wait+0x2a>
  return wait(p);
    80002bc0:	fe843503          	ld	a0,-24(s0)
    80002bc4:	fffff097          	auipc	ra,0xfffff
    80002bc8:	50c080e7          	jalr	1292(ra) # 800020d0 <wait>
}
    80002bcc:	60e2                	ld	ra,24(sp)
    80002bce:	6442                	ld	s0,16(sp)
    80002bd0:	6105                	addi	sp,sp,32
    80002bd2:	8082                	ret

0000000080002bd4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002bd4:	7179                	addi	sp,sp,-48
    80002bd6:	f406                	sd	ra,40(sp)
    80002bd8:	f022                	sd	s0,32(sp)
    80002bda:	ec26                	sd	s1,24(sp)
    80002bdc:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002bde:	fdc40593          	addi	a1,s0,-36
    80002be2:	4501                	li	a0,0
    80002be4:	00000097          	auipc	ra,0x0
    80002be8:	e78080e7          	jalr	-392(ra) # 80002a5c <argint>
    80002bec:	87aa                	mv	a5,a0
    return -1;
    80002bee:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002bf0:	0207c063          	bltz	a5,80002c10 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002bf4:	fffff097          	auipc	ra,0xfffff
    80002bf8:	dbc080e7          	jalr	-580(ra) # 800019b0 <myproc>
    80002bfc:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002bfe:	fdc42503          	lw	a0,-36(s0)
    80002c02:	fffff097          	auipc	ra,0xfffff
    80002c06:	108080e7          	jalr	264(ra) # 80001d0a <growproc>
    80002c0a:	00054863          	bltz	a0,80002c1a <sys_sbrk+0x46>
    return -1;
  return addr;
    80002c0e:	8526                	mv	a0,s1
}
    80002c10:	70a2                	ld	ra,40(sp)
    80002c12:	7402                	ld	s0,32(sp)
    80002c14:	64e2                	ld	s1,24(sp)
    80002c16:	6145                	addi	sp,sp,48
    80002c18:	8082                	ret
    return -1;
    80002c1a:	557d                	li	a0,-1
    80002c1c:	bfd5                	j	80002c10 <sys_sbrk+0x3c>

0000000080002c1e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c1e:	7139                	addi	sp,sp,-64
    80002c20:	fc06                	sd	ra,56(sp)
    80002c22:	f822                	sd	s0,48(sp)
    80002c24:	f426                	sd	s1,40(sp)
    80002c26:	f04a                	sd	s2,32(sp)
    80002c28:	ec4e                	sd	s3,24(sp)
    80002c2a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c2c:	fcc40593          	addi	a1,s0,-52
    80002c30:	4501                	li	a0,0
    80002c32:	00000097          	auipc	ra,0x0
    80002c36:	e2a080e7          	jalr	-470(ra) # 80002a5c <argint>
    return -1;
    80002c3a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c3c:	06054563          	bltz	a0,80002ca6 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c40:	00014517          	auipc	a0,0x14
    80002c44:	49050513          	addi	a0,a0,1168 # 800170d0 <tickslock>
    80002c48:	ffffe097          	auipc	ra,0xffffe
    80002c4c:	f9c080e7          	jalr	-100(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002c50:	00006917          	auipc	s2,0x6
    80002c54:	3e092903          	lw	s2,992(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002c58:	fcc42783          	lw	a5,-52(s0)
    80002c5c:	cf85                	beqz	a5,80002c94 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c5e:	00014997          	auipc	s3,0x14
    80002c62:	47298993          	addi	s3,s3,1138 # 800170d0 <tickslock>
    80002c66:	00006497          	auipc	s1,0x6
    80002c6a:	3ca48493          	addi	s1,s1,970 # 80009030 <ticks>
    if(myproc()->killed){
    80002c6e:	fffff097          	auipc	ra,0xfffff
    80002c72:	d42080e7          	jalr	-702(ra) # 800019b0 <myproc>
    80002c76:	551c                	lw	a5,40(a0)
    80002c78:	ef9d                	bnez	a5,80002cb6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002c7a:	85ce                	mv	a1,s3
    80002c7c:	8526                	mv	a0,s1
    80002c7e:	fffff097          	auipc	ra,0xfffff
    80002c82:	3ee080e7          	jalr	1006(ra) # 8000206c <sleep>
  while(ticks - ticks0 < n){
    80002c86:	409c                	lw	a5,0(s1)
    80002c88:	412787bb          	subw	a5,a5,s2
    80002c8c:	fcc42703          	lw	a4,-52(s0)
    80002c90:	fce7efe3          	bltu	a5,a4,80002c6e <sys_sleep+0x50>
  }
  release(&tickslock);
    80002c94:	00014517          	auipc	a0,0x14
    80002c98:	43c50513          	addi	a0,a0,1084 # 800170d0 <tickslock>
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	ffc080e7          	jalr	-4(ra) # 80000c98 <release>
  return 0;
    80002ca4:	4781                	li	a5,0
}
    80002ca6:	853e                	mv	a0,a5
    80002ca8:	70e2                	ld	ra,56(sp)
    80002caa:	7442                	ld	s0,48(sp)
    80002cac:	74a2                	ld	s1,40(sp)
    80002cae:	7902                	ld	s2,32(sp)
    80002cb0:	69e2                	ld	s3,24(sp)
    80002cb2:	6121                	addi	sp,sp,64
    80002cb4:	8082                	ret
      release(&tickslock);
    80002cb6:	00014517          	auipc	a0,0x14
    80002cba:	41a50513          	addi	a0,a0,1050 # 800170d0 <tickslock>
    80002cbe:	ffffe097          	auipc	ra,0xffffe
    80002cc2:	fda080e7          	jalr	-38(ra) # 80000c98 <release>
      return -1;
    80002cc6:	57fd                	li	a5,-1
    80002cc8:	bff9                	j	80002ca6 <sys_sleep+0x88>

0000000080002cca <sys_kill>:

uint64
sys_kill(void)
{
    80002cca:	1101                	addi	sp,sp,-32
    80002ccc:	ec06                	sd	ra,24(sp)
    80002cce:	e822                	sd	s0,16(sp)
    80002cd0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002cd2:	fec40593          	addi	a1,s0,-20
    80002cd6:	4501                	li	a0,0
    80002cd8:	00000097          	auipc	ra,0x0
    80002cdc:	d84080e7          	jalr	-636(ra) # 80002a5c <argint>
    80002ce0:	87aa                	mv	a5,a0
    return -1;
    80002ce2:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ce4:	0007c863          	bltz	a5,80002cf4 <sys_kill+0x2a>
  return kill(pid);
    80002ce8:	fec42503          	lw	a0,-20(s0)
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	6b2080e7          	jalr	1714(ra) # 8000239e <kill>
}
    80002cf4:	60e2                	ld	ra,24(sp)
    80002cf6:	6442                	ld	s0,16(sp)
    80002cf8:	6105                	addi	sp,sp,32
    80002cfa:	8082                	ret

0000000080002cfc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002cfc:	1101                	addi	sp,sp,-32
    80002cfe:	ec06                	sd	ra,24(sp)
    80002d00:	e822                	sd	s0,16(sp)
    80002d02:	e426                	sd	s1,8(sp)
    80002d04:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d06:	00014517          	auipc	a0,0x14
    80002d0a:	3ca50513          	addi	a0,a0,970 # 800170d0 <tickslock>
    80002d0e:	ffffe097          	auipc	ra,0xffffe
    80002d12:	ed6080e7          	jalr	-298(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002d16:	00006497          	auipc	s1,0x6
    80002d1a:	31a4a483          	lw	s1,794(s1) # 80009030 <ticks>
  release(&tickslock);
    80002d1e:	00014517          	auipc	a0,0x14
    80002d22:	3b250513          	addi	a0,a0,946 # 800170d0 <tickslock>
    80002d26:	ffffe097          	auipc	ra,0xffffe
    80002d2a:	f72080e7          	jalr	-142(ra) # 80000c98 <release>
  return xticks;
}
    80002d2e:	02049513          	slli	a0,s1,0x20
    80002d32:	9101                	srli	a0,a0,0x20
    80002d34:	60e2                	ld	ra,24(sp)
    80002d36:	6442                	ld	s0,16(sp)
    80002d38:	64a2                	ld	s1,8(sp)
    80002d3a:	6105                	addi	sp,sp,32
    80002d3c:	8082                	ret

0000000080002d3e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d3e:	7179                	addi	sp,sp,-48
    80002d40:	f406                	sd	ra,40(sp)
    80002d42:	f022                	sd	s0,32(sp)
    80002d44:	ec26                	sd	s1,24(sp)
    80002d46:	e84a                	sd	s2,16(sp)
    80002d48:	e44e                	sd	s3,8(sp)
    80002d4a:	e052                	sd	s4,0(sp)
    80002d4c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d4e:	00005597          	auipc	a1,0x5
    80002d52:	7aa58593          	addi	a1,a1,1962 # 800084f8 <syscalls+0xb0>
    80002d56:	00014517          	auipc	a0,0x14
    80002d5a:	39250513          	addi	a0,a0,914 # 800170e8 <bcache>
    80002d5e:	ffffe097          	auipc	ra,0xffffe
    80002d62:	df6080e7          	jalr	-522(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002d66:	0001c797          	auipc	a5,0x1c
    80002d6a:	38278793          	addi	a5,a5,898 # 8001f0e8 <bcache+0x8000>
    80002d6e:	0001c717          	auipc	a4,0x1c
    80002d72:	5e270713          	addi	a4,a4,1506 # 8001f350 <bcache+0x8268>
    80002d76:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002d7a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002d7e:	00014497          	auipc	s1,0x14
    80002d82:	38248493          	addi	s1,s1,898 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002d86:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002d88:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002d8a:	00005a17          	auipc	s4,0x5
    80002d8e:	776a0a13          	addi	s4,s4,1910 # 80008500 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002d92:	2b893783          	ld	a5,696(s2)
    80002d96:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002d98:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002d9c:	85d2                	mv	a1,s4
    80002d9e:	01048513          	addi	a0,s1,16
    80002da2:	00001097          	auipc	ra,0x1
    80002da6:	584080e7          	jalr	1412(ra) # 80004326 <initsleeplock>
    bcache.head.next->prev = b;
    80002daa:	2b893783          	ld	a5,696(s2)
    80002dae:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002db0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002db4:	45848493          	addi	s1,s1,1112
    80002db8:	fd349de3          	bne	s1,s3,80002d92 <binit+0x54>
  }
}
    80002dbc:	70a2                	ld	ra,40(sp)
    80002dbe:	7402                	ld	s0,32(sp)
    80002dc0:	64e2                	ld	s1,24(sp)
    80002dc2:	6942                	ld	s2,16(sp)
    80002dc4:	69a2                	ld	s3,8(sp)
    80002dc6:	6a02                	ld	s4,0(sp)
    80002dc8:	6145                	addi	sp,sp,48
    80002dca:	8082                	ret

0000000080002dcc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002dcc:	7179                	addi	sp,sp,-48
    80002dce:	f406                	sd	ra,40(sp)
    80002dd0:	f022                	sd	s0,32(sp)
    80002dd2:	ec26                	sd	s1,24(sp)
    80002dd4:	e84a                	sd	s2,16(sp)
    80002dd6:	e44e                	sd	s3,8(sp)
    80002dd8:	1800                	addi	s0,sp,48
    80002dda:	89aa                	mv	s3,a0
    80002ddc:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002dde:	00014517          	auipc	a0,0x14
    80002de2:	30a50513          	addi	a0,a0,778 # 800170e8 <bcache>
    80002de6:	ffffe097          	auipc	ra,0xffffe
    80002dea:	dfe080e7          	jalr	-514(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002dee:	0001c497          	auipc	s1,0x1c
    80002df2:	5b24b483          	ld	s1,1458(s1) # 8001f3a0 <bcache+0x82b8>
    80002df6:	0001c797          	auipc	a5,0x1c
    80002dfa:	55a78793          	addi	a5,a5,1370 # 8001f350 <bcache+0x8268>
    80002dfe:	02f48f63          	beq	s1,a5,80002e3c <bread+0x70>
    80002e02:	873e                	mv	a4,a5
    80002e04:	a021                	j	80002e0c <bread+0x40>
    80002e06:	68a4                	ld	s1,80(s1)
    80002e08:	02e48a63          	beq	s1,a4,80002e3c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e0c:	449c                	lw	a5,8(s1)
    80002e0e:	ff379ce3          	bne	a5,s3,80002e06 <bread+0x3a>
    80002e12:	44dc                	lw	a5,12(s1)
    80002e14:	ff2799e3          	bne	a5,s2,80002e06 <bread+0x3a>
      b->refcnt++;
    80002e18:	40bc                	lw	a5,64(s1)
    80002e1a:	2785                	addiw	a5,a5,1
    80002e1c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e1e:	00014517          	auipc	a0,0x14
    80002e22:	2ca50513          	addi	a0,a0,714 # 800170e8 <bcache>
    80002e26:	ffffe097          	auipc	ra,0xffffe
    80002e2a:	e72080e7          	jalr	-398(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002e2e:	01048513          	addi	a0,s1,16
    80002e32:	00001097          	auipc	ra,0x1
    80002e36:	52e080e7          	jalr	1326(ra) # 80004360 <acquiresleep>
      return b;
    80002e3a:	a8b9                	j	80002e98 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e3c:	0001c497          	auipc	s1,0x1c
    80002e40:	55c4b483          	ld	s1,1372(s1) # 8001f398 <bcache+0x82b0>
    80002e44:	0001c797          	auipc	a5,0x1c
    80002e48:	50c78793          	addi	a5,a5,1292 # 8001f350 <bcache+0x8268>
    80002e4c:	00f48863          	beq	s1,a5,80002e5c <bread+0x90>
    80002e50:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e52:	40bc                	lw	a5,64(s1)
    80002e54:	cf81                	beqz	a5,80002e6c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e56:	64a4                	ld	s1,72(s1)
    80002e58:	fee49de3          	bne	s1,a4,80002e52 <bread+0x86>
  panic("bget: no buffers");
    80002e5c:	00005517          	auipc	a0,0x5
    80002e60:	6ac50513          	addi	a0,a0,1708 # 80008508 <syscalls+0xc0>
    80002e64:	ffffd097          	auipc	ra,0xffffd
    80002e68:	6da080e7          	jalr	1754(ra) # 8000053e <panic>
      b->dev = dev;
    80002e6c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002e70:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002e74:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002e78:	4785                	li	a5,1
    80002e7a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e7c:	00014517          	auipc	a0,0x14
    80002e80:	26c50513          	addi	a0,a0,620 # 800170e8 <bcache>
    80002e84:	ffffe097          	auipc	ra,0xffffe
    80002e88:	e14080e7          	jalr	-492(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002e8c:	01048513          	addi	a0,s1,16
    80002e90:	00001097          	auipc	ra,0x1
    80002e94:	4d0080e7          	jalr	1232(ra) # 80004360 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002e98:	409c                	lw	a5,0(s1)
    80002e9a:	cb89                	beqz	a5,80002eac <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002e9c:	8526                	mv	a0,s1
    80002e9e:	70a2                	ld	ra,40(sp)
    80002ea0:	7402                	ld	s0,32(sp)
    80002ea2:	64e2                	ld	s1,24(sp)
    80002ea4:	6942                	ld	s2,16(sp)
    80002ea6:	69a2                	ld	s3,8(sp)
    80002ea8:	6145                	addi	sp,sp,48
    80002eaa:	8082                	ret
    virtio_disk_rw(b, 0);
    80002eac:	4581                	li	a1,0
    80002eae:	8526                	mv	a0,s1
    80002eb0:	00003097          	auipc	ra,0x3
    80002eb4:	fd6080e7          	jalr	-42(ra) # 80005e86 <virtio_disk_rw>
    b->valid = 1;
    80002eb8:	4785                	li	a5,1
    80002eba:	c09c                	sw	a5,0(s1)
  return b;
    80002ebc:	b7c5                	j	80002e9c <bread+0xd0>

0000000080002ebe <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ebe:	1101                	addi	sp,sp,-32
    80002ec0:	ec06                	sd	ra,24(sp)
    80002ec2:	e822                	sd	s0,16(sp)
    80002ec4:	e426                	sd	s1,8(sp)
    80002ec6:	1000                	addi	s0,sp,32
    80002ec8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002eca:	0541                	addi	a0,a0,16
    80002ecc:	00001097          	auipc	ra,0x1
    80002ed0:	52e080e7          	jalr	1326(ra) # 800043fa <holdingsleep>
    80002ed4:	cd01                	beqz	a0,80002eec <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002ed6:	4585                	li	a1,1
    80002ed8:	8526                	mv	a0,s1
    80002eda:	00003097          	auipc	ra,0x3
    80002ede:	fac080e7          	jalr	-84(ra) # 80005e86 <virtio_disk_rw>
}
    80002ee2:	60e2                	ld	ra,24(sp)
    80002ee4:	6442                	ld	s0,16(sp)
    80002ee6:	64a2                	ld	s1,8(sp)
    80002ee8:	6105                	addi	sp,sp,32
    80002eea:	8082                	ret
    panic("bwrite");
    80002eec:	00005517          	auipc	a0,0x5
    80002ef0:	63450513          	addi	a0,a0,1588 # 80008520 <syscalls+0xd8>
    80002ef4:	ffffd097          	auipc	ra,0xffffd
    80002ef8:	64a080e7          	jalr	1610(ra) # 8000053e <panic>

0000000080002efc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002efc:	1101                	addi	sp,sp,-32
    80002efe:	ec06                	sd	ra,24(sp)
    80002f00:	e822                	sd	s0,16(sp)
    80002f02:	e426                	sd	s1,8(sp)
    80002f04:	e04a                	sd	s2,0(sp)
    80002f06:	1000                	addi	s0,sp,32
    80002f08:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f0a:	01050913          	addi	s2,a0,16
    80002f0e:	854a                	mv	a0,s2
    80002f10:	00001097          	auipc	ra,0x1
    80002f14:	4ea080e7          	jalr	1258(ra) # 800043fa <holdingsleep>
    80002f18:	c92d                	beqz	a0,80002f8a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f1a:	854a                	mv	a0,s2
    80002f1c:	00001097          	auipc	ra,0x1
    80002f20:	49a080e7          	jalr	1178(ra) # 800043b6 <releasesleep>

  acquire(&bcache.lock);
    80002f24:	00014517          	auipc	a0,0x14
    80002f28:	1c450513          	addi	a0,a0,452 # 800170e8 <bcache>
    80002f2c:	ffffe097          	auipc	ra,0xffffe
    80002f30:	cb8080e7          	jalr	-840(ra) # 80000be4 <acquire>
  b->refcnt--;
    80002f34:	40bc                	lw	a5,64(s1)
    80002f36:	37fd                	addiw	a5,a5,-1
    80002f38:	0007871b          	sext.w	a4,a5
    80002f3c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f3e:	eb05                	bnez	a4,80002f6e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f40:	68bc                	ld	a5,80(s1)
    80002f42:	64b8                	ld	a4,72(s1)
    80002f44:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f46:	64bc                	ld	a5,72(s1)
    80002f48:	68b8                	ld	a4,80(s1)
    80002f4a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f4c:	0001c797          	auipc	a5,0x1c
    80002f50:	19c78793          	addi	a5,a5,412 # 8001f0e8 <bcache+0x8000>
    80002f54:	2b87b703          	ld	a4,696(a5)
    80002f58:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f5a:	0001c717          	auipc	a4,0x1c
    80002f5e:	3f670713          	addi	a4,a4,1014 # 8001f350 <bcache+0x8268>
    80002f62:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f64:	2b87b703          	ld	a4,696(a5)
    80002f68:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002f6a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002f6e:	00014517          	auipc	a0,0x14
    80002f72:	17a50513          	addi	a0,a0,378 # 800170e8 <bcache>
    80002f76:	ffffe097          	auipc	ra,0xffffe
    80002f7a:	d22080e7          	jalr	-734(ra) # 80000c98 <release>
}
    80002f7e:	60e2                	ld	ra,24(sp)
    80002f80:	6442                	ld	s0,16(sp)
    80002f82:	64a2                	ld	s1,8(sp)
    80002f84:	6902                	ld	s2,0(sp)
    80002f86:	6105                	addi	sp,sp,32
    80002f88:	8082                	ret
    panic("brelse");
    80002f8a:	00005517          	auipc	a0,0x5
    80002f8e:	59e50513          	addi	a0,a0,1438 # 80008528 <syscalls+0xe0>
    80002f92:	ffffd097          	auipc	ra,0xffffd
    80002f96:	5ac080e7          	jalr	1452(ra) # 8000053e <panic>

0000000080002f9a <bpin>:

void
bpin(struct buf *b) {
    80002f9a:	1101                	addi	sp,sp,-32
    80002f9c:	ec06                	sd	ra,24(sp)
    80002f9e:	e822                	sd	s0,16(sp)
    80002fa0:	e426                	sd	s1,8(sp)
    80002fa2:	1000                	addi	s0,sp,32
    80002fa4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fa6:	00014517          	auipc	a0,0x14
    80002faa:	14250513          	addi	a0,a0,322 # 800170e8 <bcache>
    80002fae:	ffffe097          	auipc	ra,0xffffe
    80002fb2:	c36080e7          	jalr	-970(ra) # 80000be4 <acquire>
  b->refcnt++;
    80002fb6:	40bc                	lw	a5,64(s1)
    80002fb8:	2785                	addiw	a5,a5,1
    80002fba:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002fbc:	00014517          	auipc	a0,0x14
    80002fc0:	12c50513          	addi	a0,a0,300 # 800170e8 <bcache>
    80002fc4:	ffffe097          	auipc	ra,0xffffe
    80002fc8:	cd4080e7          	jalr	-812(ra) # 80000c98 <release>
}
    80002fcc:	60e2                	ld	ra,24(sp)
    80002fce:	6442                	ld	s0,16(sp)
    80002fd0:	64a2                	ld	s1,8(sp)
    80002fd2:	6105                	addi	sp,sp,32
    80002fd4:	8082                	ret

0000000080002fd6 <bunpin>:

void
bunpin(struct buf *b) {
    80002fd6:	1101                	addi	sp,sp,-32
    80002fd8:	ec06                	sd	ra,24(sp)
    80002fda:	e822                	sd	s0,16(sp)
    80002fdc:	e426                	sd	s1,8(sp)
    80002fde:	1000                	addi	s0,sp,32
    80002fe0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fe2:	00014517          	auipc	a0,0x14
    80002fe6:	10650513          	addi	a0,a0,262 # 800170e8 <bcache>
    80002fea:	ffffe097          	auipc	ra,0xffffe
    80002fee:	bfa080e7          	jalr	-1030(ra) # 80000be4 <acquire>
  b->refcnt--;
    80002ff2:	40bc                	lw	a5,64(s1)
    80002ff4:	37fd                	addiw	a5,a5,-1
    80002ff6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002ff8:	00014517          	auipc	a0,0x14
    80002ffc:	0f050513          	addi	a0,a0,240 # 800170e8 <bcache>
    80003000:	ffffe097          	auipc	ra,0xffffe
    80003004:	c98080e7          	jalr	-872(ra) # 80000c98 <release>
}
    80003008:	60e2                	ld	ra,24(sp)
    8000300a:	6442                	ld	s0,16(sp)
    8000300c:	64a2                	ld	s1,8(sp)
    8000300e:	6105                	addi	sp,sp,32
    80003010:	8082                	ret

0000000080003012 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003012:	1101                	addi	sp,sp,-32
    80003014:	ec06                	sd	ra,24(sp)
    80003016:	e822                	sd	s0,16(sp)
    80003018:	e426                	sd	s1,8(sp)
    8000301a:	e04a                	sd	s2,0(sp)
    8000301c:	1000                	addi	s0,sp,32
    8000301e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003020:	00d5d59b          	srliw	a1,a1,0xd
    80003024:	0001c797          	auipc	a5,0x1c
    80003028:	7a07a783          	lw	a5,1952(a5) # 8001f7c4 <sb+0x1c>
    8000302c:	9dbd                	addw	a1,a1,a5
    8000302e:	00000097          	auipc	ra,0x0
    80003032:	d9e080e7          	jalr	-610(ra) # 80002dcc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003036:	0074f713          	andi	a4,s1,7
    8000303a:	4785                	li	a5,1
    8000303c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003040:	14ce                	slli	s1,s1,0x33
    80003042:	90d9                	srli	s1,s1,0x36
    80003044:	00950733          	add	a4,a0,s1
    80003048:	05874703          	lbu	a4,88(a4)
    8000304c:	00e7f6b3          	and	a3,a5,a4
    80003050:	c69d                	beqz	a3,8000307e <bfree+0x6c>
    80003052:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003054:	94aa                	add	s1,s1,a0
    80003056:	fff7c793          	not	a5,a5
    8000305a:	8ff9                	and	a5,a5,a4
    8000305c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003060:	00001097          	auipc	ra,0x1
    80003064:	1e0080e7          	jalr	480(ra) # 80004240 <log_write>
  brelse(bp);
    80003068:	854a                	mv	a0,s2
    8000306a:	00000097          	auipc	ra,0x0
    8000306e:	e92080e7          	jalr	-366(ra) # 80002efc <brelse>
}
    80003072:	60e2                	ld	ra,24(sp)
    80003074:	6442                	ld	s0,16(sp)
    80003076:	64a2                	ld	s1,8(sp)
    80003078:	6902                	ld	s2,0(sp)
    8000307a:	6105                	addi	sp,sp,32
    8000307c:	8082                	ret
    panic("freeing free block");
    8000307e:	00005517          	auipc	a0,0x5
    80003082:	4b250513          	addi	a0,a0,1202 # 80008530 <syscalls+0xe8>
    80003086:	ffffd097          	auipc	ra,0xffffd
    8000308a:	4b8080e7          	jalr	1208(ra) # 8000053e <panic>

000000008000308e <balloc>:
{
    8000308e:	711d                	addi	sp,sp,-96
    80003090:	ec86                	sd	ra,88(sp)
    80003092:	e8a2                	sd	s0,80(sp)
    80003094:	e4a6                	sd	s1,72(sp)
    80003096:	e0ca                	sd	s2,64(sp)
    80003098:	fc4e                	sd	s3,56(sp)
    8000309a:	f852                	sd	s4,48(sp)
    8000309c:	f456                	sd	s5,40(sp)
    8000309e:	f05a                	sd	s6,32(sp)
    800030a0:	ec5e                	sd	s7,24(sp)
    800030a2:	e862                	sd	s8,16(sp)
    800030a4:	e466                	sd	s9,8(sp)
    800030a6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030a8:	0001c797          	auipc	a5,0x1c
    800030ac:	7047a783          	lw	a5,1796(a5) # 8001f7ac <sb+0x4>
    800030b0:	cbd1                	beqz	a5,80003144 <balloc+0xb6>
    800030b2:	8baa                	mv	s7,a0
    800030b4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030b6:	0001cb17          	auipc	s6,0x1c
    800030ba:	6f2b0b13          	addi	s6,s6,1778 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030be:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800030c0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030c2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800030c4:	6c89                	lui	s9,0x2
    800030c6:	a831                	j	800030e2 <balloc+0x54>
    brelse(bp);
    800030c8:	854a                	mv	a0,s2
    800030ca:	00000097          	auipc	ra,0x0
    800030ce:	e32080e7          	jalr	-462(ra) # 80002efc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800030d2:	015c87bb          	addw	a5,s9,s5
    800030d6:	00078a9b          	sext.w	s5,a5
    800030da:	004b2703          	lw	a4,4(s6)
    800030de:	06eaf363          	bgeu	s5,a4,80003144 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800030e2:	41fad79b          	sraiw	a5,s5,0x1f
    800030e6:	0137d79b          	srliw	a5,a5,0x13
    800030ea:	015787bb          	addw	a5,a5,s5
    800030ee:	40d7d79b          	sraiw	a5,a5,0xd
    800030f2:	01cb2583          	lw	a1,28(s6)
    800030f6:	9dbd                	addw	a1,a1,a5
    800030f8:	855e                	mv	a0,s7
    800030fa:	00000097          	auipc	ra,0x0
    800030fe:	cd2080e7          	jalr	-814(ra) # 80002dcc <bread>
    80003102:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003104:	004b2503          	lw	a0,4(s6)
    80003108:	000a849b          	sext.w	s1,s5
    8000310c:	8662                	mv	a2,s8
    8000310e:	faa4fde3          	bgeu	s1,a0,800030c8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003112:	41f6579b          	sraiw	a5,a2,0x1f
    80003116:	01d7d69b          	srliw	a3,a5,0x1d
    8000311a:	00c6873b          	addw	a4,a3,a2
    8000311e:	00777793          	andi	a5,a4,7
    80003122:	9f95                	subw	a5,a5,a3
    80003124:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003128:	4037571b          	sraiw	a4,a4,0x3
    8000312c:	00e906b3          	add	a3,s2,a4
    80003130:	0586c683          	lbu	a3,88(a3)
    80003134:	00d7f5b3          	and	a1,a5,a3
    80003138:	cd91                	beqz	a1,80003154 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000313a:	2605                	addiw	a2,a2,1
    8000313c:	2485                	addiw	s1,s1,1
    8000313e:	fd4618e3          	bne	a2,s4,8000310e <balloc+0x80>
    80003142:	b759                	j	800030c8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003144:	00005517          	auipc	a0,0x5
    80003148:	40450513          	addi	a0,a0,1028 # 80008548 <syscalls+0x100>
    8000314c:	ffffd097          	auipc	ra,0xffffd
    80003150:	3f2080e7          	jalr	1010(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003154:	974a                	add	a4,a4,s2
    80003156:	8fd5                	or	a5,a5,a3
    80003158:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000315c:	854a                	mv	a0,s2
    8000315e:	00001097          	auipc	ra,0x1
    80003162:	0e2080e7          	jalr	226(ra) # 80004240 <log_write>
        brelse(bp);
    80003166:	854a                	mv	a0,s2
    80003168:	00000097          	auipc	ra,0x0
    8000316c:	d94080e7          	jalr	-620(ra) # 80002efc <brelse>
  bp = bread(dev, bno);
    80003170:	85a6                	mv	a1,s1
    80003172:	855e                	mv	a0,s7
    80003174:	00000097          	auipc	ra,0x0
    80003178:	c58080e7          	jalr	-936(ra) # 80002dcc <bread>
    8000317c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000317e:	40000613          	li	a2,1024
    80003182:	4581                	li	a1,0
    80003184:	05850513          	addi	a0,a0,88
    80003188:	ffffe097          	auipc	ra,0xffffe
    8000318c:	b58080e7          	jalr	-1192(ra) # 80000ce0 <memset>
  log_write(bp);
    80003190:	854a                	mv	a0,s2
    80003192:	00001097          	auipc	ra,0x1
    80003196:	0ae080e7          	jalr	174(ra) # 80004240 <log_write>
  brelse(bp);
    8000319a:	854a                	mv	a0,s2
    8000319c:	00000097          	auipc	ra,0x0
    800031a0:	d60080e7          	jalr	-672(ra) # 80002efc <brelse>
}
    800031a4:	8526                	mv	a0,s1
    800031a6:	60e6                	ld	ra,88(sp)
    800031a8:	6446                	ld	s0,80(sp)
    800031aa:	64a6                	ld	s1,72(sp)
    800031ac:	6906                	ld	s2,64(sp)
    800031ae:	79e2                	ld	s3,56(sp)
    800031b0:	7a42                	ld	s4,48(sp)
    800031b2:	7aa2                	ld	s5,40(sp)
    800031b4:	7b02                	ld	s6,32(sp)
    800031b6:	6be2                	ld	s7,24(sp)
    800031b8:	6c42                	ld	s8,16(sp)
    800031ba:	6ca2                	ld	s9,8(sp)
    800031bc:	6125                	addi	sp,sp,96
    800031be:	8082                	ret

00000000800031c0 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// bn = block number
static uint
bmap(struct inode *ip, uint bn)
{
    800031c0:	7139                	addi	sp,sp,-64
    800031c2:	fc06                	sd	ra,56(sp)
    800031c4:	f822                	sd	s0,48(sp)
    800031c6:	f426                	sd	s1,40(sp)
    800031c8:	f04a                	sd	s2,32(sp)
    800031ca:	ec4e                	sd	s3,24(sp)
    800031cc:	e852                	sd	s4,16(sp)
    800031ce:	e456                	sd	s5,8(sp)
    800031d0:	0080                	addi	s0,sp,64
    800031d2:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800031d4:	47a9                	li	a5,10
    800031d6:	08b7fd63          	bgeu	a5,a1,80003270 <bmap+0xb0>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800031da:	ff55849b          	addiw	s1,a1,-11
    800031de:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800031e2:	0ff00793          	li	a5,255
    800031e6:	0ae7f863          	bgeu	a5,a4,80003296 <bmap+0xd6>
      log_write(bp);
    }
    brelse(bp);
    return addr;
  }
  bn -= NINDIRECT;
    800031ea:	ef55849b          	addiw	s1,a1,-267
    800031ee:	0004871b          	sext.w	a4,s1

  if(bn < NDOUBLINDIRECT){
    800031f2:	67c1                	lui	a5,0x10
    800031f4:	14f77e63          	bgeu	a4,a5,80003350 <bmap+0x190>
    // checks if the double indirect block is allocated (and load it) and allocates if not
    if((addr = ip->addrs[NDIRECT + 1]) == 0)
    800031f8:	08052583          	lw	a1,128(a0)
    800031fc:	10058063          	beqz	a1,800032fc <bmap+0x13c>
      ip->addrs[NDIRECT + 1] = addr = balloc(ip->dev);

    //bread returns a locked buf with the contents of the indicated block- of addr
    bp = bread(ip->dev, addr);
    80003200:	0009a503          	lw	a0,0(s3)
    80003204:	00000097          	auipc	ra,0x0
    80003208:	bc8080e7          	jalr	-1080(ra) # 80002dcc <bread>
    8000320c:	892a                	mv	s2,a0
    a = (uint*)bp->data;
    8000320e:	05850a13          	addi	s4,a0,88

    // checks if the level2 indirect block is allocated (and load it) and allocates if not
    uint bn_level1_double_index = bn / NINDIRECT;
    if ((addr = a[bn_level1_double_index]) == 0){
    80003212:	0084d79b          	srliw	a5,s1,0x8
    80003216:	078a                	slli	a5,a5,0x2
    80003218:	9a3e                	add	s4,s4,a5
    8000321a:	000a2a83          	lw	s5,0(s4) # 2000 <_entry-0x7fffe000>
    8000321e:	0e0a8963          	beqz	s5,80003310 <bmap+0x150>
      a[bn_level1_double_index] = addr = balloc(ip->dev);
      // level1 indirect block modified so write back
      log_write(bp);
    }
    brelse(bp);
    80003222:	854a                	mv	a0,s2
    80003224:	00000097          	auipc	ra,0x0
    80003228:	cd8080e7          	jalr	-808(ra) # 80002efc <brelse>

    bp = bread(ip->dev, addr);
    8000322c:	85d6                	mv	a1,s5
    8000322e:	0009a503          	lw	a0,0(s3)
    80003232:	00000097          	auipc	ra,0x0
    80003236:	b9a080e7          	jalr	-1126(ra) # 80002dcc <bread>
    8000323a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000323c:	05850793          	addi	a5,a0,88

    // checks if the data block is allocated (and load it) and allocates if not
    uint bn_level2_pos = bn % NINDIRECT;
    if((addr = a[bn_level2_pos]) == 0){
    80003240:	0ff4f593          	andi	a1,s1,255
    80003244:	058a                	slli	a1,a1,0x2
    80003246:	00b784b3          	add	s1,a5,a1
    8000324a:	0004a903          	lw	s2,0(s1)
    8000324e:	0e090163          	beqz	s2,80003330 <bmap+0x170>
      a[bn_level2_pos] = addr = balloc(ip->dev);
      // level2 block modified so write back
      log_write(bp);
    }
    brelse(bp);
    80003252:	8552                	mv	a0,s4
    80003254:	00000097          	auipc	ra,0x0
    80003258:	ca8080e7          	jalr	-856(ra) # 80002efc <brelse>
    return addr;

  }

  panic("bmap: out of range");
}
    8000325c:	854a                	mv	a0,s2
    8000325e:	70e2                	ld	ra,56(sp)
    80003260:	7442                	ld	s0,48(sp)
    80003262:	74a2                	ld	s1,40(sp)
    80003264:	7902                	ld	s2,32(sp)
    80003266:	69e2                	ld	s3,24(sp)
    80003268:	6a42                	ld	s4,16(sp)
    8000326a:	6aa2                	ld	s5,8(sp)
    8000326c:	6121                	addi	sp,sp,64
    8000326e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003270:	02059493          	slli	s1,a1,0x20
    80003274:	9081                	srli	s1,s1,0x20
    80003276:	048a                	slli	s1,s1,0x2
    80003278:	94aa                	add	s1,s1,a0
    8000327a:	0504a903          	lw	s2,80(s1)
    8000327e:	fc091fe3          	bnez	s2,8000325c <bmap+0x9c>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003282:	4108                	lw	a0,0(a0)
    80003284:	00000097          	auipc	ra,0x0
    80003288:	e0a080e7          	jalr	-502(ra) # 8000308e <balloc>
    8000328c:	0005091b          	sext.w	s2,a0
    80003290:	0524a823          	sw	s2,80(s1)
    80003294:	b7e1                	j	8000325c <bmap+0x9c>
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003296:	5d6c                	lw	a1,124(a0)
    80003298:	c985                	beqz	a1,800032c8 <bmap+0x108>
    bp = bread(ip->dev, addr);
    8000329a:	0009a503          	lw	a0,0(s3)
    8000329e:	00000097          	auipc	ra,0x0
    800032a2:	b2e080e7          	jalr	-1234(ra) # 80002dcc <bread>
    800032a6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032a8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032ac:	1482                	slli	s1,s1,0x20
    800032ae:	9081                	srli	s1,s1,0x20
    800032b0:	048a                	slli	s1,s1,0x2
    800032b2:	94be                	add	s1,s1,a5
    800032b4:	0004a903          	lw	s2,0(s1)
    800032b8:	02090263          	beqz	s2,800032dc <bmap+0x11c>
    brelse(bp);
    800032bc:	8552                	mv	a0,s4
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	c3e080e7          	jalr	-962(ra) # 80002efc <brelse>
    return addr;
    800032c6:	bf59                	j	8000325c <bmap+0x9c>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800032c8:	4108                	lw	a0,0(a0)
    800032ca:	00000097          	auipc	ra,0x0
    800032ce:	dc4080e7          	jalr	-572(ra) # 8000308e <balloc>
    800032d2:	0005059b          	sext.w	a1,a0
    800032d6:	06b9ae23          	sw	a1,124(s3)
    800032da:	b7c1                	j	8000329a <bmap+0xda>
      a[bn] = addr = balloc(ip->dev);
    800032dc:	0009a503          	lw	a0,0(s3)
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	dae080e7          	jalr	-594(ra) # 8000308e <balloc>
    800032e8:	0005091b          	sext.w	s2,a0
    800032ec:	0124a023          	sw	s2,0(s1)
      log_write(bp);
    800032f0:	8552                	mv	a0,s4
    800032f2:	00001097          	auipc	ra,0x1
    800032f6:	f4e080e7          	jalr	-178(ra) # 80004240 <log_write>
    800032fa:	b7c9                	j	800032bc <bmap+0xfc>
      ip->addrs[NDIRECT + 1] = addr = balloc(ip->dev);
    800032fc:	4108                	lw	a0,0(a0)
    800032fe:	00000097          	auipc	ra,0x0
    80003302:	d90080e7          	jalr	-624(ra) # 8000308e <balloc>
    80003306:	0005059b          	sext.w	a1,a0
    8000330a:	08b9a023          	sw	a1,128(s3)
    8000330e:	bdcd                	j	80003200 <bmap+0x40>
      a[bn_level1_double_index] = addr = balloc(ip->dev);
    80003310:	0009a503          	lw	a0,0(s3)
    80003314:	00000097          	auipc	ra,0x0
    80003318:	d7a080e7          	jalr	-646(ra) # 8000308e <balloc>
    8000331c:	00050a9b          	sext.w	s5,a0
    80003320:	015a2023          	sw	s5,0(s4)
      log_write(bp);
    80003324:	854a                	mv	a0,s2
    80003326:	00001097          	auipc	ra,0x1
    8000332a:	f1a080e7          	jalr	-230(ra) # 80004240 <log_write>
    8000332e:	bdd5                	j	80003222 <bmap+0x62>
      a[bn_level2_pos] = addr = balloc(ip->dev);
    80003330:	0009a503          	lw	a0,0(s3)
    80003334:	00000097          	auipc	ra,0x0
    80003338:	d5a080e7          	jalr	-678(ra) # 8000308e <balloc>
    8000333c:	0005091b          	sext.w	s2,a0
    80003340:	0124a023          	sw	s2,0(s1)
      log_write(bp);
    80003344:	8552                	mv	a0,s4
    80003346:	00001097          	auipc	ra,0x1
    8000334a:	efa080e7          	jalr	-262(ra) # 80004240 <log_write>
    8000334e:	b711                	j	80003252 <bmap+0x92>
  panic("bmap: out of range");
    80003350:	00005517          	auipc	a0,0x5
    80003354:	21050513          	addi	a0,a0,528 # 80008560 <syscalls+0x118>
    80003358:	ffffd097          	auipc	ra,0xffffd
    8000335c:	1e6080e7          	jalr	486(ra) # 8000053e <panic>

0000000080003360 <iget>:
{
    80003360:	7179                	addi	sp,sp,-48
    80003362:	f406                	sd	ra,40(sp)
    80003364:	f022                	sd	s0,32(sp)
    80003366:	ec26                	sd	s1,24(sp)
    80003368:	e84a                	sd	s2,16(sp)
    8000336a:	e44e                	sd	s3,8(sp)
    8000336c:	e052                	sd	s4,0(sp)
    8000336e:	1800                	addi	s0,sp,48
    80003370:	89aa                	mv	s3,a0
    80003372:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003374:	0001c517          	auipc	a0,0x1c
    80003378:	45450513          	addi	a0,a0,1108 # 8001f7c8 <itable>
    8000337c:	ffffe097          	auipc	ra,0xffffe
    80003380:	868080e7          	jalr	-1944(ra) # 80000be4 <acquire>
  empty = 0;
    80003384:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003386:	0001c497          	auipc	s1,0x1c
    8000338a:	45a48493          	addi	s1,s1,1114 # 8001f7e0 <itable+0x18>
    8000338e:	0001e697          	auipc	a3,0x1e
    80003392:	d5268693          	addi	a3,a3,-686 # 800210e0 <log>
    80003396:	a039                	j	800033a4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003398:	02090b63          	beqz	s2,800033ce <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000339c:	08048493          	addi	s1,s1,128
    800033a0:	02d48a63          	beq	s1,a3,800033d4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033a4:	449c                	lw	a5,8(s1)
    800033a6:	fef059e3          	blez	a5,80003398 <iget+0x38>
    800033aa:	4098                	lw	a4,0(s1)
    800033ac:	ff3716e3          	bne	a4,s3,80003398 <iget+0x38>
    800033b0:	40d8                	lw	a4,4(s1)
    800033b2:	ff4713e3          	bne	a4,s4,80003398 <iget+0x38>
      ip->ref++;
    800033b6:	2785                	addiw	a5,a5,1
    800033b8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800033ba:	0001c517          	auipc	a0,0x1c
    800033be:	40e50513          	addi	a0,a0,1038 # 8001f7c8 <itable>
    800033c2:	ffffe097          	auipc	ra,0xffffe
    800033c6:	8d6080e7          	jalr	-1834(ra) # 80000c98 <release>
      return ip;
    800033ca:	8926                	mv	s2,s1
    800033cc:	a03d                	j	800033fa <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033ce:	f7f9                	bnez	a5,8000339c <iget+0x3c>
    800033d0:	8926                	mv	s2,s1
    800033d2:	b7e9                	j	8000339c <iget+0x3c>
  if(empty == 0)
    800033d4:	02090c63          	beqz	s2,8000340c <iget+0xac>
  ip->dev = dev;
    800033d8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033dc:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033e0:	4785                	li	a5,1
    800033e2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033e6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800033ea:	0001c517          	auipc	a0,0x1c
    800033ee:	3de50513          	addi	a0,a0,990 # 8001f7c8 <itable>
    800033f2:	ffffe097          	auipc	ra,0xffffe
    800033f6:	8a6080e7          	jalr	-1882(ra) # 80000c98 <release>
}
    800033fa:	854a                	mv	a0,s2
    800033fc:	70a2                	ld	ra,40(sp)
    800033fe:	7402                	ld	s0,32(sp)
    80003400:	64e2                	ld	s1,24(sp)
    80003402:	6942                	ld	s2,16(sp)
    80003404:	69a2                	ld	s3,8(sp)
    80003406:	6a02                	ld	s4,0(sp)
    80003408:	6145                	addi	sp,sp,48
    8000340a:	8082                	ret
    panic("iget: no inodes");
    8000340c:	00005517          	auipc	a0,0x5
    80003410:	16c50513          	addi	a0,a0,364 # 80008578 <syscalls+0x130>
    80003414:	ffffd097          	auipc	ra,0xffffd
    80003418:	12a080e7          	jalr	298(ra) # 8000053e <panic>

000000008000341c <fsinit>:
fsinit(int dev) {
    8000341c:	7179                	addi	sp,sp,-48
    8000341e:	f406                	sd	ra,40(sp)
    80003420:	f022                	sd	s0,32(sp)
    80003422:	ec26                	sd	s1,24(sp)
    80003424:	e84a                	sd	s2,16(sp)
    80003426:	e44e                	sd	s3,8(sp)
    80003428:	1800                	addi	s0,sp,48
    8000342a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000342c:	4585                	li	a1,1
    8000342e:	00000097          	auipc	ra,0x0
    80003432:	99e080e7          	jalr	-1634(ra) # 80002dcc <bread>
    80003436:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003438:	0001c997          	auipc	s3,0x1c
    8000343c:	37098993          	addi	s3,s3,880 # 8001f7a8 <sb>
    80003440:	02000613          	li	a2,32
    80003444:	05850593          	addi	a1,a0,88
    80003448:	854e                	mv	a0,s3
    8000344a:	ffffe097          	auipc	ra,0xffffe
    8000344e:	8f6080e7          	jalr	-1802(ra) # 80000d40 <memmove>
  brelse(bp);
    80003452:	8526                	mv	a0,s1
    80003454:	00000097          	auipc	ra,0x0
    80003458:	aa8080e7          	jalr	-1368(ra) # 80002efc <brelse>
  if(sb.magic != FSMAGIC)
    8000345c:	0009a703          	lw	a4,0(s3)
    80003460:	102037b7          	lui	a5,0x10203
    80003464:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003468:	02f71263          	bne	a4,a5,8000348c <fsinit+0x70>
  initlog(dev, &sb);
    8000346c:	0001c597          	auipc	a1,0x1c
    80003470:	33c58593          	addi	a1,a1,828 # 8001f7a8 <sb>
    80003474:	854a                	mv	a0,s2
    80003476:	00001097          	auipc	ra,0x1
    8000347a:	b4e080e7          	jalr	-1202(ra) # 80003fc4 <initlog>
}
    8000347e:	70a2                	ld	ra,40(sp)
    80003480:	7402                	ld	s0,32(sp)
    80003482:	64e2                	ld	s1,24(sp)
    80003484:	6942                	ld	s2,16(sp)
    80003486:	69a2                	ld	s3,8(sp)
    80003488:	6145                	addi	sp,sp,48
    8000348a:	8082                	ret
    panic("invalid file system");
    8000348c:	00005517          	auipc	a0,0x5
    80003490:	0fc50513          	addi	a0,a0,252 # 80008588 <syscalls+0x140>
    80003494:	ffffd097          	auipc	ra,0xffffd
    80003498:	0aa080e7          	jalr	170(ra) # 8000053e <panic>

000000008000349c <iinit>:
{
    8000349c:	7179                	addi	sp,sp,-48
    8000349e:	f406                	sd	ra,40(sp)
    800034a0:	f022                	sd	s0,32(sp)
    800034a2:	ec26                	sd	s1,24(sp)
    800034a4:	e84a                	sd	s2,16(sp)
    800034a6:	e44e                	sd	s3,8(sp)
    800034a8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800034aa:	00005597          	auipc	a1,0x5
    800034ae:	0f658593          	addi	a1,a1,246 # 800085a0 <syscalls+0x158>
    800034b2:	0001c517          	auipc	a0,0x1c
    800034b6:	31650513          	addi	a0,a0,790 # 8001f7c8 <itable>
    800034ba:	ffffd097          	auipc	ra,0xffffd
    800034be:	69a080e7          	jalr	1690(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034c2:	0001c497          	auipc	s1,0x1c
    800034c6:	32e48493          	addi	s1,s1,814 # 8001f7f0 <itable+0x28>
    800034ca:	0001e997          	auipc	s3,0x1e
    800034ce:	c2698993          	addi	s3,s3,-986 # 800210f0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800034d2:	00005917          	auipc	s2,0x5
    800034d6:	0d690913          	addi	s2,s2,214 # 800085a8 <syscalls+0x160>
    800034da:	85ca                	mv	a1,s2
    800034dc:	8526                	mv	a0,s1
    800034de:	00001097          	auipc	ra,0x1
    800034e2:	e48080e7          	jalr	-440(ra) # 80004326 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034e6:	08048493          	addi	s1,s1,128
    800034ea:	ff3498e3          	bne	s1,s3,800034da <iinit+0x3e>
}
    800034ee:	70a2                	ld	ra,40(sp)
    800034f0:	7402                	ld	s0,32(sp)
    800034f2:	64e2                	ld	s1,24(sp)
    800034f4:	6942                	ld	s2,16(sp)
    800034f6:	69a2                	ld	s3,8(sp)
    800034f8:	6145                	addi	sp,sp,48
    800034fa:	8082                	ret

00000000800034fc <ialloc>:
{
    800034fc:	715d                	addi	sp,sp,-80
    800034fe:	e486                	sd	ra,72(sp)
    80003500:	e0a2                	sd	s0,64(sp)
    80003502:	fc26                	sd	s1,56(sp)
    80003504:	f84a                	sd	s2,48(sp)
    80003506:	f44e                	sd	s3,40(sp)
    80003508:	f052                	sd	s4,32(sp)
    8000350a:	ec56                	sd	s5,24(sp)
    8000350c:	e85a                	sd	s6,16(sp)
    8000350e:	e45e                	sd	s7,8(sp)
    80003510:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003512:	0001c717          	auipc	a4,0x1c
    80003516:	2a272703          	lw	a4,674(a4) # 8001f7b4 <sb+0xc>
    8000351a:	4785                	li	a5,1
    8000351c:	04e7fa63          	bgeu	a5,a4,80003570 <ialloc+0x74>
    80003520:	8aaa                	mv	s5,a0
    80003522:	8bae                	mv	s7,a1
    80003524:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003526:	0001ca17          	auipc	s4,0x1c
    8000352a:	282a0a13          	addi	s4,s4,642 # 8001f7a8 <sb>
    8000352e:	00048b1b          	sext.w	s6,s1
    80003532:	0044d593          	srli	a1,s1,0x4
    80003536:	018a2783          	lw	a5,24(s4)
    8000353a:	9dbd                	addw	a1,a1,a5
    8000353c:	8556                	mv	a0,s5
    8000353e:	00000097          	auipc	ra,0x0
    80003542:	88e080e7          	jalr	-1906(ra) # 80002dcc <bread>
    80003546:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003548:	05850993          	addi	s3,a0,88
    8000354c:	00f4f793          	andi	a5,s1,15
    80003550:	079a                	slli	a5,a5,0x6
    80003552:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003554:	00099783          	lh	a5,0(s3)
    80003558:	c785                	beqz	a5,80003580 <ialloc+0x84>
    brelse(bp);
    8000355a:	00000097          	auipc	ra,0x0
    8000355e:	9a2080e7          	jalr	-1630(ra) # 80002efc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003562:	0485                	addi	s1,s1,1
    80003564:	00ca2703          	lw	a4,12(s4)
    80003568:	0004879b          	sext.w	a5,s1
    8000356c:	fce7e1e3          	bltu	a5,a4,8000352e <ialloc+0x32>
  panic("ialloc: no inodes");
    80003570:	00005517          	auipc	a0,0x5
    80003574:	04050513          	addi	a0,a0,64 # 800085b0 <syscalls+0x168>
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	fc6080e7          	jalr	-58(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003580:	04000613          	li	a2,64
    80003584:	4581                	li	a1,0
    80003586:	854e                	mv	a0,s3
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	758080e7          	jalr	1880(ra) # 80000ce0 <memset>
      dip->type = type;
    80003590:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003594:	854a                	mv	a0,s2
    80003596:	00001097          	auipc	ra,0x1
    8000359a:	caa080e7          	jalr	-854(ra) # 80004240 <log_write>
      brelse(bp);
    8000359e:	854a                	mv	a0,s2
    800035a0:	00000097          	auipc	ra,0x0
    800035a4:	95c080e7          	jalr	-1700(ra) # 80002efc <brelse>
      return iget(dev, inum);
    800035a8:	85da                	mv	a1,s6
    800035aa:	8556                	mv	a0,s5
    800035ac:	00000097          	auipc	ra,0x0
    800035b0:	db4080e7          	jalr	-588(ra) # 80003360 <iget>
}
    800035b4:	60a6                	ld	ra,72(sp)
    800035b6:	6406                	ld	s0,64(sp)
    800035b8:	74e2                	ld	s1,56(sp)
    800035ba:	7942                	ld	s2,48(sp)
    800035bc:	79a2                	ld	s3,40(sp)
    800035be:	7a02                	ld	s4,32(sp)
    800035c0:	6ae2                	ld	s5,24(sp)
    800035c2:	6b42                	ld	s6,16(sp)
    800035c4:	6ba2                	ld	s7,8(sp)
    800035c6:	6161                	addi	sp,sp,80
    800035c8:	8082                	ret

00000000800035ca <iupdate>:
{
    800035ca:	1101                	addi	sp,sp,-32
    800035cc:	ec06                	sd	ra,24(sp)
    800035ce:	e822                	sd	s0,16(sp)
    800035d0:	e426                	sd	s1,8(sp)
    800035d2:	e04a                	sd	s2,0(sp)
    800035d4:	1000                	addi	s0,sp,32
    800035d6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035d8:	415c                	lw	a5,4(a0)
    800035da:	0047d79b          	srliw	a5,a5,0x4
    800035de:	0001c597          	auipc	a1,0x1c
    800035e2:	1e25a583          	lw	a1,482(a1) # 8001f7c0 <sb+0x18>
    800035e6:	9dbd                	addw	a1,a1,a5
    800035e8:	4108                	lw	a0,0(a0)
    800035ea:	fffff097          	auipc	ra,0xfffff
    800035ee:	7e2080e7          	jalr	2018(ra) # 80002dcc <bread>
    800035f2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035f4:	05850793          	addi	a5,a0,88
    800035f8:	40c8                	lw	a0,4(s1)
    800035fa:	893d                	andi	a0,a0,15
    800035fc:	051a                	slli	a0,a0,0x6
    800035fe:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003600:	04449703          	lh	a4,68(s1)
    80003604:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003608:	04649703          	lh	a4,70(s1)
    8000360c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003610:	04849703          	lh	a4,72(s1)
    80003614:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003618:	04a49703          	lh	a4,74(s1)
    8000361c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003620:	44f8                	lw	a4,76(s1)
    80003622:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003624:	03000613          	li	a2,48
    80003628:	05048593          	addi	a1,s1,80
    8000362c:	0531                	addi	a0,a0,12
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	712080e7          	jalr	1810(ra) # 80000d40 <memmove>
  log_write(bp);
    80003636:	854a                	mv	a0,s2
    80003638:	00001097          	auipc	ra,0x1
    8000363c:	c08080e7          	jalr	-1016(ra) # 80004240 <log_write>
  brelse(bp);
    80003640:	854a                	mv	a0,s2
    80003642:	00000097          	auipc	ra,0x0
    80003646:	8ba080e7          	jalr	-1862(ra) # 80002efc <brelse>
}
    8000364a:	60e2                	ld	ra,24(sp)
    8000364c:	6442                	ld	s0,16(sp)
    8000364e:	64a2                	ld	s1,8(sp)
    80003650:	6902                	ld	s2,0(sp)
    80003652:	6105                	addi	sp,sp,32
    80003654:	8082                	ret

0000000080003656 <idup>:
{
    80003656:	1101                	addi	sp,sp,-32
    80003658:	ec06                	sd	ra,24(sp)
    8000365a:	e822                	sd	s0,16(sp)
    8000365c:	e426                	sd	s1,8(sp)
    8000365e:	1000                	addi	s0,sp,32
    80003660:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003662:	0001c517          	auipc	a0,0x1c
    80003666:	16650513          	addi	a0,a0,358 # 8001f7c8 <itable>
    8000366a:	ffffd097          	auipc	ra,0xffffd
    8000366e:	57a080e7          	jalr	1402(ra) # 80000be4 <acquire>
  ip->ref++;
    80003672:	449c                	lw	a5,8(s1)
    80003674:	2785                	addiw	a5,a5,1
    80003676:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003678:	0001c517          	auipc	a0,0x1c
    8000367c:	15050513          	addi	a0,a0,336 # 8001f7c8 <itable>
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	618080e7          	jalr	1560(ra) # 80000c98 <release>
}
    80003688:	8526                	mv	a0,s1
    8000368a:	60e2                	ld	ra,24(sp)
    8000368c:	6442                	ld	s0,16(sp)
    8000368e:	64a2                	ld	s1,8(sp)
    80003690:	6105                	addi	sp,sp,32
    80003692:	8082                	ret

0000000080003694 <ilock>:
{
    80003694:	1101                	addi	sp,sp,-32
    80003696:	ec06                	sd	ra,24(sp)
    80003698:	e822                	sd	s0,16(sp)
    8000369a:	e426                	sd	s1,8(sp)
    8000369c:	e04a                	sd	s2,0(sp)
    8000369e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036a0:	c115                	beqz	a0,800036c4 <ilock+0x30>
    800036a2:	84aa                	mv	s1,a0
    800036a4:	451c                	lw	a5,8(a0)
    800036a6:	00f05f63          	blez	a5,800036c4 <ilock+0x30>
  acquiresleep(&ip->lock);
    800036aa:	0541                	addi	a0,a0,16
    800036ac:	00001097          	auipc	ra,0x1
    800036b0:	cb4080e7          	jalr	-844(ra) # 80004360 <acquiresleep>
  if(ip->valid == 0){
    800036b4:	40bc                	lw	a5,64(s1)
    800036b6:	cf99                	beqz	a5,800036d4 <ilock+0x40>
}
    800036b8:	60e2                	ld	ra,24(sp)
    800036ba:	6442                	ld	s0,16(sp)
    800036bc:	64a2                	ld	s1,8(sp)
    800036be:	6902                	ld	s2,0(sp)
    800036c0:	6105                	addi	sp,sp,32
    800036c2:	8082                	ret
    panic("ilock");
    800036c4:	00005517          	auipc	a0,0x5
    800036c8:	f0450513          	addi	a0,a0,-252 # 800085c8 <syscalls+0x180>
    800036cc:	ffffd097          	auipc	ra,0xffffd
    800036d0:	e72080e7          	jalr	-398(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036d4:	40dc                	lw	a5,4(s1)
    800036d6:	0047d79b          	srliw	a5,a5,0x4
    800036da:	0001c597          	auipc	a1,0x1c
    800036de:	0e65a583          	lw	a1,230(a1) # 8001f7c0 <sb+0x18>
    800036e2:	9dbd                	addw	a1,a1,a5
    800036e4:	4088                	lw	a0,0(s1)
    800036e6:	fffff097          	auipc	ra,0xfffff
    800036ea:	6e6080e7          	jalr	1766(ra) # 80002dcc <bread>
    800036ee:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036f0:	05850593          	addi	a1,a0,88
    800036f4:	40dc                	lw	a5,4(s1)
    800036f6:	8bbd                	andi	a5,a5,15
    800036f8:	079a                	slli	a5,a5,0x6
    800036fa:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036fc:	00059783          	lh	a5,0(a1)
    80003700:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003704:	00259783          	lh	a5,2(a1)
    80003708:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000370c:	00459783          	lh	a5,4(a1)
    80003710:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003714:	00659783          	lh	a5,6(a1)
    80003718:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000371c:	459c                	lw	a5,8(a1)
    8000371e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003720:	03000613          	li	a2,48
    80003724:	05b1                	addi	a1,a1,12
    80003726:	05048513          	addi	a0,s1,80
    8000372a:	ffffd097          	auipc	ra,0xffffd
    8000372e:	616080e7          	jalr	1558(ra) # 80000d40 <memmove>
    brelse(bp);
    80003732:	854a                	mv	a0,s2
    80003734:	fffff097          	auipc	ra,0xfffff
    80003738:	7c8080e7          	jalr	1992(ra) # 80002efc <brelse>
    ip->valid = 1;
    8000373c:	4785                	li	a5,1
    8000373e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003740:	04449783          	lh	a5,68(s1)
    80003744:	fbb5                	bnez	a5,800036b8 <ilock+0x24>
      panic("ilock: no type");
    80003746:	00005517          	auipc	a0,0x5
    8000374a:	e8a50513          	addi	a0,a0,-374 # 800085d0 <syscalls+0x188>
    8000374e:	ffffd097          	auipc	ra,0xffffd
    80003752:	df0080e7          	jalr	-528(ra) # 8000053e <panic>

0000000080003756 <iunlock>:
{
    80003756:	1101                	addi	sp,sp,-32
    80003758:	ec06                	sd	ra,24(sp)
    8000375a:	e822                	sd	s0,16(sp)
    8000375c:	e426                	sd	s1,8(sp)
    8000375e:	e04a                	sd	s2,0(sp)
    80003760:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003762:	c905                	beqz	a0,80003792 <iunlock+0x3c>
    80003764:	84aa                	mv	s1,a0
    80003766:	01050913          	addi	s2,a0,16
    8000376a:	854a                	mv	a0,s2
    8000376c:	00001097          	auipc	ra,0x1
    80003770:	c8e080e7          	jalr	-882(ra) # 800043fa <holdingsleep>
    80003774:	cd19                	beqz	a0,80003792 <iunlock+0x3c>
    80003776:	449c                	lw	a5,8(s1)
    80003778:	00f05d63          	blez	a5,80003792 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000377c:	854a                	mv	a0,s2
    8000377e:	00001097          	auipc	ra,0x1
    80003782:	c38080e7          	jalr	-968(ra) # 800043b6 <releasesleep>
}
    80003786:	60e2                	ld	ra,24(sp)
    80003788:	6442                	ld	s0,16(sp)
    8000378a:	64a2                	ld	s1,8(sp)
    8000378c:	6902                	ld	s2,0(sp)
    8000378e:	6105                	addi	sp,sp,32
    80003790:	8082                	ret
    panic("iunlock");
    80003792:	00005517          	auipc	a0,0x5
    80003796:	e4e50513          	addi	a0,a0,-434 # 800085e0 <syscalls+0x198>
    8000379a:	ffffd097          	auipc	ra,0xffffd
    8000379e:	da4080e7          	jalr	-604(ra) # 8000053e <panic>

00000000800037a2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037a2:	7179                	addi	sp,sp,-48
    800037a4:	f406                	sd	ra,40(sp)
    800037a6:	f022                	sd	s0,32(sp)
    800037a8:	ec26                	sd	s1,24(sp)
    800037aa:	e84a                	sd	s2,16(sp)
    800037ac:	e44e                	sd	s3,8(sp)
    800037ae:	e052                	sd	s4,0(sp)
    800037b0:	1800                	addi	s0,sp,48
    800037b2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037b4:	05050493          	addi	s1,a0,80
    800037b8:	07c50913          	addi	s2,a0,124
    800037bc:	a821                	j	800037d4 <itrunc+0x32>
    if(ip->addrs[i]){
      bfree(ip->dev, ip->addrs[i]);
    800037be:	0009a503          	lw	a0,0(s3)
    800037c2:	00000097          	auipc	ra,0x0
    800037c6:	850080e7          	jalr	-1968(ra) # 80003012 <bfree>
      ip->addrs[i] = 0;
    800037ca:	0004a023          	sw	zero,0(s1)
  for(i = 0; i < NDIRECT; i++){
    800037ce:	0491                	addi	s1,s1,4
    800037d0:	01248563          	beq	s1,s2,800037da <itrunc+0x38>
    if(ip->addrs[i]){
    800037d4:	408c                	lw	a1,0(s1)
    800037d6:	dde5                	beqz	a1,800037ce <itrunc+0x2c>
    800037d8:	b7dd                	j	800037be <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037da:	07c9a583          	lw	a1,124(s3)
    800037de:	e185                	bnez	a1,800037fe <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037e0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800037e4:	854e                	mv	a0,s3
    800037e6:	00000097          	auipc	ra,0x0
    800037ea:	de4080e7          	jalr	-540(ra) # 800035ca <iupdate>
}
    800037ee:	70a2                	ld	ra,40(sp)
    800037f0:	7402                	ld	s0,32(sp)
    800037f2:	64e2                	ld	s1,24(sp)
    800037f4:	6942                	ld	s2,16(sp)
    800037f6:	69a2                	ld	s3,8(sp)
    800037f8:	6a02                	ld	s4,0(sp)
    800037fa:	6145                	addi	sp,sp,48
    800037fc:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037fe:	0009a503          	lw	a0,0(s3)
    80003802:	fffff097          	auipc	ra,0xfffff
    80003806:	5ca080e7          	jalr	1482(ra) # 80002dcc <bread>
    8000380a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000380c:	05850493          	addi	s1,a0,88
    80003810:	45850913          	addi	s2,a0,1112
    80003814:	a811                	j	80003828 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003816:	0009a503          	lw	a0,0(s3)
    8000381a:	fffff097          	auipc	ra,0xfffff
    8000381e:	7f8080e7          	jalr	2040(ra) # 80003012 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003822:	0491                	addi	s1,s1,4
    80003824:	01248563          	beq	s1,s2,8000382e <itrunc+0x8c>
      if(a[j])
    80003828:	408c                	lw	a1,0(s1)
    8000382a:	dde5                	beqz	a1,80003822 <itrunc+0x80>
    8000382c:	b7ed                	j	80003816 <itrunc+0x74>
    brelse(bp);
    8000382e:	8552                	mv	a0,s4
    80003830:	fffff097          	auipc	ra,0xfffff
    80003834:	6cc080e7          	jalr	1740(ra) # 80002efc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003838:	07c9a583          	lw	a1,124(s3)
    8000383c:	0009a503          	lw	a0,0(s3)
    80003840:	fffff097          	auipc	ra,0xfffff
    80003844:	7d2080e7          	jalr	2002(ra) # 80003012 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003848:	0609ae23          	sw	zero,124(s3)
    8000384c:	bf51                	j	800037e0 <itrunc+0x3e>

000000008000384e <iput>:
{
    8000384e:	1101                	addi	sp,sp,-32
    80003850:	ec06                	sd	ra,24(sp)
    80003852:	e822                	sd	s0,16(sp)
    80003854:	e426                	sd	s1,8(sp)
    80003856:	e04a                	sd	s2,0(sp)
    80003858:	1000                	addi	s0,sp,32
    8000385a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000385c:	0001c517          	auipc	a0,0x1c
    80003860:	f6c50513          	addi	a0,a0,-148 # 8001f7c8 <itable>
    80003864:	ffffd097          	auipc	ra,0xffffd
    80003868:	380080e7          	jalr	896(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000386c:	4498                	lw	a4,8(s1)
    8000386e:	4785                	li	a5,1
    80003870:	02f70363          	beq	a4,a5,80003896 <iput+0x48>
  ip->ref--;
    80003874:	449c                	lw	a5,8(s1)
    80003876:	37fd                	addiw	a5,a5,-1
    80003878:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000387a:	0001c517          	auipc	a0,0x1c
    8000387e:	f4e50513          	addi	a0,a0,-178 # 8001f7c8 <itable>
    80003882:	ffffd097          	auipc	ra,0xffffd
    80003886:	416080e7          	jalr	1046(ra) # 80000c98 <release>
}
    8000388a:	60e2                	ld	ra,24(sp)
    8000388c:	6442                	ld	s0,16(sp)
    8000388e:	64a2                	ld	s1,8(sp)
    80003890:	6902                	ld	s2,0(sp)
    80003892:	6105                	addi	sp,sp,32
    80003894:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003896:	40bc                	lw	a5,64(s1)
    80003898:	dff1                	beqz	a5,80003874 <iput+0x26>
    8000389a:	04a49783          	lh	a5,74(s1)
    8000389e:	fbf9                	bnez	a5,80003874 <iput+0x26>
    acquiresleep(&ip->lock);
    800038a0:	01048913          	addi	s2,s1,16
    800038a4:	854a                	mv	a0,s2
    800038a6:	00001097          	auipc	ra,0x1
    800038aa:	aba080e7          	jalr	-1350(ra) # 80004360 <acquiresleep>
    release(&itable.lock);
    800038ae:	0001c517          	auipc	a0,0x1c
    800038b2:	f1a50513          	addi	a0,a0,-230 # 8001f7c8 <itable>
    800038b6:	ffffd097          	auipc	ra,0xffffd
    800038ba:	3e2080e7          	jalr	994(ra) # 80000c98 <release>
    itrunc(ip);
    800038be:	8526                	mv	a0,s1
    800038c0:	00000097          	auipc	ra,0x0
    800038c4:	ee2080e7          	jalr	-286(ra) # 800037a2 <itrunc>
    ip->type = 0;
    800038c8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038cc:	8526                	mv	a0,s1
    800038ce:	00000097          	auipc	ra,0x0
    800038d2:	cfc080e7          	jalr	-772(ra) # 800035ca <iupdate>
    ip->valid = 0;
    800038d6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038da:	854a                	mv	a0,s2
    800038dc:	00001097          	auipc	ra,0x1
    800038e0:	ada080e7          	jalr	-1318(ra) # 800043b6 <releasesleep>
    acquire(&itable.lock);
    800038e4:	0001c517          	auipc	a0,0x1c
    800038e8:	ee450513          	addi	a0,a0,-284 # 8001f7c8 <itable>
    800038ec:	ffffd097          	auipc	ra,0xffffd
    800038f0:	2f8080e7          	jalr	760(ra) # 80000be4 <acquire>
    800038f4:	b741                	j	80003874 <iput+0x26>

00000000800038f6 <iunlockput>:
{
    800038f6:	1101                	addi	sp,sp,-32
    800038f8:	ec06                	sd	ra,24(sp)
    800038fa:	e822                	sd	s0,16(sp)
    800038fc:	e426                	sd	s1,8(sp)
    800038fe:	1000                	addi	s0,sp,32
    80003900:	84aa                	mv	s1,a0
  iunlock(ip);
    80003902:	00000097          	auipc	ra,0x0
    80003906:	e54080e7          	jalr	-428(ra) # 80003756 <iunlock>
  iput(ip);
    8000390a:	8526                	mv	a0,s1
    8000390c:	00000097          	auipc	ra,0x0
    80003910:	f42080e7          	jalr	-190(ra) # 8000384e <iput>
}
    80003914:	60e2                	ld	ra,24(sp)
    80003916:	6442                	ld	s0,16(sp)
    80003918:	64a2                	ld	s1,8(sp)
    8000391a:	6105                	addi	sp,sp,32
    8000391c:	8082                	ret

000000008000391e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000391e:	1141                	addi	sp,sp,-16
    80003920:	e422                	sd	s0,8(sp)
    80003922:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003924:	411c                	lw	a5,0(a0)
    80003926:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003928:	415c                	lw	a5,4(a0)
    8000392a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000392c:	04451783          	lh	a5,68(a0)
    80003930:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003934:	04a51783          	lh	a5,74(a0)
    80003938:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000393c:	04c56783          	lwu	a5,76(a0)
    80003940:	e99c                	sd	a5,16(a1)
}
    80003942:	6422                	ld	s0,8(sp)
    80003944:	0141                	addi	sp,sp,16
    80003946:	8082                	ret

0000000080003948 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003948:	457c                	lw	a5,76(a0)
    8000394a:	0ed7e963          	bltu	a5,a3,80003a3c <readi+0xf4>
{
    8000394e:	7159                	addi	sp,sp,-112
    80003950:	f486                	sd	ra,104(sp)
    80003952:	f0a2                	sd	s0,96(sp)
    80003954:	eca6                	sd	s1,88(sp)
    80003956:	e8ca                	sd	s2,80(sp)
    80003958:	e4ce                	sd	s3,72(sp)
    8000395a:	e0d2                	sd	s4,64(sp)
    8000395c:	fc56                	sd	s5,56(sp)
    8000395e:	f85a                	sd	s6,48(sp)
    80003960:	f45e                	sd	s7,40(sp)
    80003962:	f062                	sd	s8,32(sp)
    80003964:	ec66                	sd	s9,24(sp)
    80003966:	e86a                	sd	s10,16(sp)
    80003968:	e46e                	sd	s11,8(sp)
    8000396a:	1880                	addi	s0,sp,112
    8000396c:	8baa                	mv	s7,a0
    8000396e:	8c2e                	mv	s8,a1
    80003970:	8ab2                	mv	s5,a2
    80003972:	84b6                	mv	s1,a3
    80003974:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003976:	9f35                	addw	a4,a4,a3
    return 0;
    80003978:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000397a:	0ad76063          	bltu	a4,a3,80003a1a <readi+0xd2>
  if(off + n > ip->size)
    8000397e:	00e7f463          	bgeu	a5,a4,80003986 <readi+0x3e>
    n = ip->size - off;
    80003982:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003986:	0a0b0963          	beqz	s6,80003a38 <readi+0xf0>
    8000398a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000398c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003990:	5cfd                	li	s9,-1
    80003992:	a82d                	j	800039cc <readi+0x84>
    80003994:	020a1d93          	slli	s11,s4,0x20
    80003998:	020ddd93          	srli	s11,s11,0x20
    8000399c:	05890613          	addi	a2,s2,88
    800039a0:	86ee                	mv	a3,s11
    800039a2:	963a                	add	a2,a2,a4
    800039a4:	85d6                	mv	a1,s5
    800039a6:	8562                	mv	a0,s8
    800039a8:	fffff097          	auipc	ra,0xfffff
    800039ac:	a68080e7          	jalr	-1432(ra) # 80002410 <either_copyout>
    800039b0:	05950d63          	beq	a0,s9,80003a0a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800039b4:	854a                	mv	a0,s2
    800039b6:	fffff097          	auipc	ra,0xfffff
    800039ba:	546080e7          	jalr	1350(ra) # 80002efc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039be:	013a09bb          	addw	s3,s4,s3
    800039c2:	009a04bb          	addw	s1,s4,s1
    800039c6:	9aee                	add	s5,s5,s11
    800039c8:	0569f763          	bgeu	s3,s6,80003a16 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800039cc:	000ba903          	lw	s2,0(s7)
    800039d0:	00a4d59b          	srliw	a1,s1,0xa
    800039d4:	855e                	mv	a0,s7
    800039d6:	fffff097          	auipc	ra,0xfffff
    800039da:	7ea080e7          	jalr	2026(ra) # 800031c0 <bmap>
    800039de:	0005059b          	sext.w	a1,a0
    800039e2:	854a                	mv	a0,s2
    800039e4:	fffff097          	auipc	ra,0xfffff
    800039e8:	3e8080e7          	jalr	1000(ra) # 80002dcc <bread>
    800039ec:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039ee:	3ff4f713          	andi	a4,s1,1023
    800039f2:	40ed07bb          	subw	a5,s10,a4
    800039f6:	413b06bb          	subw	a3,s6,s3
    800039fa:	8a3e                	mv	s4,a5
    800039fc:	2781                	sext.w	a5,a5
    800039fe:	0006861b          	sext.w	a2,a3
    80003a02:	f8f679e3          	bgeu	a2,a5,80003994 <readi+0x4c>
    80003a06:	8a36                	mv	s4,a3
    80003a08:	b771                	j	80003994 <readi+0x4c>
      brelse(bp);
    80003a0a:	854a                	mv	a0,s2
    80003a0c:	fffff097          	auipc	ra,0xfffff
    80003a10:	4f0080e7          	jalr	1264(ra) # 80002efc <brelse>
      tot = -1;
    80003a14:	59fd                	li	s3,-1
  }
  return tot;
    80003a16:	0009851b          	sext.w	a0,s3
}
    80003a1a:	70a6                	ld	ra,104(sp)
    80003a1c:	7406                	ld	s0,96(sp)
    80003a1e:	64e6                	ld	s1,88(sp)
    80003a20:	6946                	ld	s2,80(sp)
    80003a22:	69a6                	ld	s3,72(sp)
    80003a24:	6a06                	ld	s4,64(sp)
    80003a26:	7ae2                	ld	s5,56(sp)
    80003a28:	7b42                	ld	s6,48(sp)
    80003a2a:	7ba2                	ld	s7,40(sp)
    80003a2c:	7c02                	ld	s8,32(sp)
    80003a2e:	6ce2                	ld	s9,24(sp)
    80003a30:	6d42                	ld	s10,16(sp)
    80003a32:	6da2                	ld	s11,8(sp)
    80003a34:	6165                	addi	sp,sp,112
    80003a36:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a38:	89da                	mv	s3,s6
    80003a3a:	bff1                	j	80003a16 <readi+0xce>
    return 0;
    80003a3c:	4501                	li	a0,0
}
    80003a3e:	8082                	ret

0000000080003a40 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a40:	457c                	lw	a5,76(a0)
    80003a42:	10d7e963          	bltu	a5,a3,80003b54 <writei+0x114>
{
    80003a46:	7159                	addi	sp,sp,-112
    80003a48:	f486                	sd	ra,104(sp)
    80003a4a:	f0a2                	sd	s0,96(sp)
    80003a4c:	eca6                	sd	s1,88(sp)
    80003a4e:	e8ca                	sd	s2,80(sp)
    80003a50:	e4ce                	sd	s3,72(sp)
    80003a52:	e0d2                	sd	s4,64(sp)
    80003a54:	fc56                	sd	s5,56(sp)
    80003a56:	f85a                	sd	s6,48(sp)
    80003a58:	f45e                	sd	s7,40(sp)
    80003a5a:	f062                	sd	s8,32(sp)
    80003a5c:	ec66                	sd	s9,24(sp)
    80003a5e:	e86a                	sd	s10,16(sp)
    80003a60:	e46e                	sd	s11,8(sp)
    80003a62:	1880                	addi	s0,sp,112
    80003a64:	8b2a                	mv	s6,a0
    80003a66:	8c2e                	mv	s8,a1
    80003a68:	8ab2                	mv	s5,a2
    80003a6a:	8936                	mv	s2,a3
    80003a6c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003a6e:	9f35                	addw	a4,a4,a3
    80003a70:	0ed76463          	bltu	a4,a3,80003b58 <writei+0x118>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a74:	040437b7          	lui	a5,0x4043
    80003a78:	c0078793          	addi	a5,a5,-1024 # 4042c00 <_entry-0x7bfbd400>
    80003a7c:	0ee7e063          	bltu	a5,a4,80003b5c <writei+0x11c>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a80:	0c0b8863          	beqz	s7,80003b50 <writei+0x110>
    80003a84:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a86:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a8a:	5cfd                	li	s9,-1
    80003a8c:	a091                	j	80003ad0 <writei+0x90>
    80003a8e:	02099d93          	slli	s11,s3,0x20
    80003a92:	020ddd93          	srli	s11,s11,0x20
    80003a96:	05848513          	addi	a0,s1,88
    80003a9a:	86ee                	mv	a3,s11
    80003a9c:	8656                	mv	a2,s5
    80003a9e:	85e2                	mv	a1,s8
    80003aa0:	953a                	add	a0,a0,a4
    80003aa2:	fffff097          	auipc	ra,0xfffff
    80003aa6:	9c4080e7          	jalr	-1596(ra) # 80002466 <either_copyin>
    80003aaa:	07950263          	beq	a0,s9,80003b0e <writei+0xce>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003aae:	8526                	mv	a0,s1
    80003ab0:	00000097          	auipc	ra,0x0
    80003ab4:	790080e7          	jalr	1936(ra) # 80004240 <log_write>
    brelse(bp);
    80003ab8:	8526                	mv	a0,s1
    80003aba:	fffff097          	auipc	ra,0xfffff
    80003abe:	442080e7          	jalr	1090(ra) # 80002efc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ac2:	01498a3b          	addw	s4,s3,s4
    80003ac6:	0129893b          	addw	s2,s3,s2
    80003aca:	9aee                	add	s5,s5,s11
    80003acc:	057a7663          	bgeu	s4,s7,80003b18 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ad0:	000b2483          	lw	s1,0(s6)
    80003ad4:	00a9559b          	srliw	a1,s2,0xa
    80003ad8:	855a                	mv	a0,s6
    80003ada:	fffff097          	auipc	ra,0xfffff
    80003ade:	6e6080e7          	jalr	1766(ra) # 800031c0 <bmap>
    80003ae2:	0005059b          	sext.w	a1,a0
    80003ae6:	8526                	mv	a0,s1
    80003ae8:	fffff097          	auipc	ra,0xfffff
    80003aec:	2e4080e7          	jalr	740(ra) # 80002dcc <bread>
    80003af0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003af2:	3ff97713          	andi	a4,s2,1023
    80003af6:	40ed07bb          	subw	a5,s10,a4
    80003afa:	414b86bb          	subw	a3,s7,s4
    80003afe:	89be                	mv	s3,a5
    80003b00:	2781                	sext.w	a5,a5
    80003b02:	0006861b          	sext.w	a2,a3
    80003b06:	f8f674e3          	bgeu	a2,a5,80003a8e <writei+0x4e>
    80003b0a:	89b6                	mv	s3,a3
    80003b0c:	b749                	j	80003a8e <writei+0x4e>
      brelse(bp);
    80003b0e:	8526                	mv	a0,s1
    80003b10:	fffff097          	auipc	ra,0xfffff
    80003b14:	3ec080e7          	jalr	1004(ra) # 80002efc <brelse>
  }

  if(off > ip->size)
    80003b18:	04cb2783          	lw	a5,76(s6)
    80003b1c:	0127f463          	bgeu	a5,s2,80003b24 <writei+0xe4>
    ip->size = off;
    80003b20:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b24:	855a                	mv	a0,s6
    80003b26:	00000097          	auipc	ra,0x0
    80003b2a:	aa4080e7          	jalr	-1372(ra) # 800035ca <iupdate>

  return tot;
    80003b2e:	000a051b          	sext.w	a0,s4
}
    80003b32:	70a6                	ld	ra,104(sp)
    80003b34:	7406                	ld	s0,96(sp)
    80003b36:	64e6                	ld	s1,88(sp)
    80003b38:	6946                	ld	s2,80(sp)
    80003b3a:	69a6                	ld	s3,72(sp)
    80003b3c:	6a06                	ld	s4,64(sp)
    80003b3e:	7ae2                	ld	s5,56(sp)
    80003b40:	7b42                	ld	s6,48(sp)
    80003b42:	7ba2                	ld	s7,40(sp)
    80003b44:	7c02                	ld	s8,32(sp)
    80003b46:	6ce2                	ld	s9,24(sp)
    80003b48:	6d42                	ld	s10,16(sp)
    80003b4a:	6da2                	ld	s11,8(sp)
    80003b4c:	6165                	addi	sp,sp,112
    80003b4e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b50:	8a5e                	mv	s4,s7
    80003b52:	bfc9                	j	80003b24 <writei+0xe4>
    return -1;
    80003b54:	557d                	li	a0,-1
}
    80003b56:	8082                	ret
    return -1;
    80003b58:	557d                	li	a0,-1
    80003b5a:	bfe1                	j	80003b32 <writei+0xf2>
    return -1;
    80003b5c:	557d                	li	a0,-1
    80003b5e:	bfd1                	j	80003b32 <writei+0xf2>

0000000080003b60 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b60:	1141                	addi	sp,sp,-16
    80003b62:	e406                	sd	ra,8(sp)
    80003b64:	e022                	sd	s0,0(sp)
    80003b66:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b68:	4639                	li	a2,14
    80003b6a:	ffffd097          	auipc	ra,0xffffd
    80003b6e:	24e080e7          	jalr	590(ra) # 80000db8 <strncmp>
}
    80003b72:	60a2                	ld	ra,8(sp)
    80003b74:	6402                	ld	s0,0(sp)
    80003b76:	0141                	addi	sp,sp,16
    80003b78:	8082                	ret

0000000080003b7a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b7a:	7139                	addi	sp,sp,-64
    80003b7c:	fc06                	sd	ra,56(sp)
    80003b7e:	f822                	sd	s0,48(sp)
    80003b80:	f426                	sd	s1,40(sp)
    80003b82:	f04a                	sd	s2,32(sp)
    80003b84:	ec4e                	sd	s3,24(sp)
    80003b86:	e852                	sd	s4,16(sp)
    80003b88:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b8a:	04451703          	lh	a4,68(a0)
    80003b8e:	4785                	li	a5,1
    80003b90:	00f71a63          	bne	a4,a5,80003ba4 <dirlookup+0x2a>
    80003b94:	892a                	mv	s2,a0
    80003b96:	89ae                	mv	s3,a1
    80003b98:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b9a:	457c                	lw	a5,76(a0)
    80003b9c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b9e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ba0:	e79d                	bnez	a5,80003bce <dirlookup+0x54>
    80003ba2:	a8a5                	j	80003c1a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ba4:	00005517          	auipc	a0,0x5
    80003ba8:	a4450513          	addi	a0,a0,-1468 # 800085e8 <syscalls+0x1a0>
    80003bac:	ffffd097          	auipc	ra,0xffffd
    80003bb0:	992080e7          	jalr	-1646(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003bb4:	00005517          	auipc	a0,0x5
    80003bb8:	a4c50513          	addi	a0,a0,-1460 # 80008600 <syscalls+0x1b8>
    80003bbc:	ffffd097          	auipc	ra,0xffffd
    80003bc0:	982080e7          	jalr	-1662(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bc4:	24c1                	addiw	s1,s1,16
    80003bc6:	04c92783          	lw	a5,76(s2)
    80003bca:	04f4f763          	bgeu	s1,a5,80003c18 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003bce:	4741                	li	a4,16
    80003bd0:	86a6                	mv	a3,s1
    80003bd2:	fc040613          	addi	a2,s0,-64
    80003bd6:	4581                	li	a1,0
    80003bd8:	854a                	mv	a0,s2
    80003bda:	00000097          	auipc	ra,0x0
    80003bde:	d6e080e7          	jalr	-658(ra) # 80003948 <readi>
    80003be2:	47c1                	li	a5,16
    80003be4:	fcf518e3          	bne	a0,a5,80003bb4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003be8:	fc045783          	lhu	a5,-64(s0)
    80003bec:	dfe1                	beqz	a5,80003bc4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003bee:	fc240593          	addi	a1,s0,-62
    80003bf2:	854e                	mv	a0,s3
    80003bf4:	00000097          	auipc	ra,0x0
    80003bf8:	f6c080e7          	jalr	-148(ra) # 80003b60 <namecmp>
    80003bfc:	f561                	bnez	a0,80003bc4 <dirlookup+0x4a>
      if(poff)
    80003bfe:	000a0463          	beqz	s4,80003c06 <dirlookup+0x8c>
        *poff = off;
    80003c02:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c06:	fc045583          	lhu	a1,-64(s0)
    80003c0a:	00092503          	lw	a0,0(s2)
    80003c0e:	fffff097          	auipc	ra,0xfffff
    80003c12:	752080e7          	jalr	1874(ra) # 80003360 <iget>
    80003c16:	a011                	j	80003c1a <dirlookup+0xa0>
  return 0;
    80003c18:	4501                	li	a0,0
}
    80003c1a:	70e2                	ld	ra,56(sp)
    80003c1c:	7442                	ld	s0,48(sp)
    80003c1e:	74a2                	ld	s1,40(sp)
    80003c20:	7902                	ld	s2,32(sp)
    80003c22:	69e2                	ld	s3,24(sp)
    80003c24:	6a42                	ld	s4,16(sp)
    80003c26:	6121                	addi	sp,sp,64
    80003c28:	8082                	ret

0000000080003c2a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c2a:	711d                	addi	sp,sp,-96
    80003c2c:	ec86                	sd	ra,88(sp)
    80003c2e:	e8a2                	sd	s0,80(sp)
    80003c30:	e4a6                	sd	s1,72(sp)
    80003c32:	e0ca                	sd	s2,64(sp)
    80003c34:	fc4e                	sd	s3,56(sp)
    80003c36:	f852                	sd	s4,48(sp)
    80003c38:	f456                	sd	s5,40(sp)
    80003c3a:	f05a                	sd	s6,32(sp)
    80003c3c:	ec5e                	sd	s7,24(sp)
    80003c3e:	e862                	sd	s8,16(sp)
    80003c40:	e466                	sd	s9,8(sp)
    80003c42:	1080                	addi	s0,sp,96
    80003c44:	84aa                	mv	s1,a0
    80003c46:	8b2e                	mv	s6,a1
    80003c48:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c4a:	00054703          	lbu	a4,0(a0)
    80003c4e:	02f00793          	li	a5,47
    80003c52:	02f70363          	beq	a4,a5,80003c78 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c56:	ffffe097          	auipc	ra,0xffffe
    80003c5a:	d5a080e7          	jalr	-678(ra) # 800019b0 <myproc>
    80003c5e:	15053503          	ld	a0,336(a0)
    80003c62:	00000097          	auipc	ra,0x0
    80003c66:	9f4080e7          	jalr	-1548(ra) # 80003656 <idup>
    80003c6a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c6c:	02f00913          	li	s2,47
  len = path - s;
    80003c70:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003c72:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c74:	4c05                	li	s8,1
    80003c76:	a865                	j	80003d2e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c78:	4585                	li	a1,1
    80003c7a:	4505                	li	a0,1
    80003c7c:	fffff097          	auipc	ra,0xfffff
    80003c80:	6e4080e7          	jalr	1764(ra) # 80003360 <iget>
    80003c84:	89aa                	mv	s3,a0
    80003c86:	b7dd                	j	80003c6c <namex+0x42>
      iunlockput(ip);
    80003c88:	854e                	mv	a0,s3
    80003c8a:	00000097          	auipc	ra,0x0
    80003c8e:	c6c080e7          	jalr	-916(ra) # 800038f6 <iunlockput>
      return 0;
    80003c92:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c94:	854e                	mv	a0,s3
    80003c96:	60e6                	ld	ra,88(sp)
    80003c98:	6446                	ld	s0,80(sp)
    80003c9a:	64a6                	ld	s1,72(sp)
    80003c9c:	6906                	ld	s2,64(sp)
    80003c9e:	79e2                	ld	s3,56(sp)
    80003ca0:	7a42                	ld	s4,48(sp)
    80003ca2:	7aa2                	ld	s5,40(sp)
    80003ca4:	7b02                	ld	s6,32(sp)
    80003ca6:	6be2                	ld	s7,24(sp)
    80003ca8:	6c42                	ld	s8,16(sp)
    80003caa:	6ca2                	ld	s9,8(sp)
    80003cac:	6125                	addi	sp,sp,96
    80003cae:	8082                	ret
      iunlock(ip);
    80003cb0:	854e                	mv	a0,s3
    80003cb2:	00000097          	auipc	ra,0x0
    80003cb6:	aa4080e7          	jalr	-1372(ra) # 80003756 <iunlock>
      return ip;
    80003cba:	bfe9                	j	80003c94 <namex+0x6a>
      iunlockput(ip);
    80003cbc:	854e                	mv	a0,s3
    80003cbe:	00000097          	auipc	ra,0x0
    80003cc2:	c38080e7          	jalr	-968(ra) # 800038f6 <iunlockput>
      return 0;
    80003cc6:	89d2                	mv	s3,s4
    80003cc8:	b7f1                	j	80003c94 <namex+0x6a>
  len = path - s;
    80003cca:	40b48633          	sub	a2,s1,a1
    80003cce:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003cd2:	094cd463          	bge	s9,s4,80003d5a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003cd6:	4639                	li	a2,14
    80003cd8:	8556                	mv	a0,s5
    80003cda:	ffffd097          	auipc	ra,0xffffd
    80003cde:	066080e7          	jalr	102(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003ce2:	0004c783          	lbu	a5,0(s1)
    80003ce6:	01279763          	bne	a5,s2,80003cf4 <namex+0xca>
    path++;
    80003cea:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cec:	0004c783          	lbu	a5,0(s1)
    80003cf0:	ff278de3          	beq	a5,s2,80003cea <namex+0xc0>
    ilock(ip);
    80003cf4:	854e                	mv	a0,s3
    80003cf6:	00000097          	auipc	ra,0x0
    80003cfa:	99e080e7          	jalr	-1634(ra) # 80003694 <ilock>
    if(ip->type != T_DIR){
    80003cfe:	04499783          	lh	a5,68(s3)
    80003d02:	f98793e3          	bne	a5,s8,80003c88 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d06:	000b0563          	beqz	s6,80003d10 <namex+0xe6>
    80003d0a:	0004c783          	lbu	a5,0(s1)
    80003d0e:	d3cd                	beqz	a5,80003cb0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d10:	865e                	mv	a2,s7
    80003d12:	85d6                	mv	a1,s5
    80003d14:	854e                	mv	a0,s3
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	e64080e7          	jalr	-412(ra) # 80003b7a <dirlookup>
    80003d1e:	8a2a                	mv	s4,a0
    80003d20:	dd51                	beqz	a0,80003cbc <namex+0x92>
    iunlockput(ip);
    80003d22:	854e                	mv	a0,s3
    80003d24:	00000097          	auipc	ra,0x0
    80003d28:	bd2080e7          	jalr	-1070(ra) # 800038f6 <iunlockput>
    ip = next;
    80003d2c:	89d2                	mv	s3,s4
  while(*path == '/')
    80003d2e:	0004c783          	lbu	a5,0(s1)
    80003d32:	05279763          	bne	a5,s2,80003d80 <namex+0x156>
    path++;
    80003d36:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d38:	0004c783          	lbu	a5,0(s1)
    80003d3c:	ff278de3          	beq	a5,s2,80003d36 <namex+0x10c>
  if(*path == 0)
    80003d40:	c79d                	beqz	a5,80003d6e <namex+0x144>
    path++;
    80003d42:	85a6                	mv	a1,s1
  len = path - s;
    80003d44:	8a5e                	mv	s4,s7
    80003d46:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d48:	01278963          	beq	a5,s2,80003d5a <namex+0x130>
    80003d4c:	dfbd                	beqz	a5,80003cca <namex+0xa0>
    path++;
    80003d4e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d50:	0004c783          	lbu	a5,0(s1)
    80003d54:	ff279ce3          	bne	a5,s2,80003d4c <namex+0x122>
    80003d58:	bf8d                	j	80003cca <namex+0xa0>
    memmove(name, s, len);
    80003d5a:	2601                	sext.w	a2,a2
    80003d5c:	8556                	mv	a0,s5
    80003d5e:	ffffd097          	auipc	ra,0xffffd
    80003d62:	fe2080e7          	jalr	-30(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003d66:	9a56                	add	s4,s4,s5
    80003d68:	000a0023          	sb	zero,0(s4)
    80003d6c:	bf9d                	j	80003ce2 <namex+0xb8>
  if(nameiparent){
    80003d6e:	f20b03e3          	beqz	s6,80003c94 <namex+0x6a>
    iput(ip);
    80003d72:	854e                	mv	a0,s3
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	ada080e7          	jalr	-1318(ra) # 8000384e <iput>
    return 0;
    80003d7c:	4981                	li	s3,0
    80003d7e:	bf19                	j	80003c94 <namex+0x6a>
  if(*path == 0)
    80003d80:	d7fd                	beqz	a5,80003d6e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d82:	0004c783          	lbu	a5,0(s1)
    80003d86:	85a6                	mv	a1,s1
    80003d88:	b7d1                	j	80003d4c <namex+0x122>

0000000080003d8a <dirlink>:
{
    80003d8a:	7139                	addi	sp,sp,-64
    80003d8c:	fc06                	sd	ra,56(sp)
    80003d8e:	f822                	sd	s0,48(sp)
    80003d90:	f426                	sd	s1,40(sp)
    80003d92:	f04a                	sd	s2,32(sp)
    80003d94:	ec4e                	sd	s3,24(sp)
    80003d96:	e852                	sd	s4,16(sp)
    80003d98:	0080                	addi	s0,sp,64
    80003d9a:	892a                	mv	s2,a0
    80003d9c:	8a2e                	mv	s4,a1
    80003d9e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003da0:	4601                	li	a2,0
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	dd8080e7          	jalr	-552(ra) # 80003b7a <dirlookup>
    80003daa:	e93d                	bnez	a0,80003e20 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dac:	04c92483          	lw	s1,76(s2)
    80003db0:	c49d                	beqz	s1,80003dde <dirlink+0x54>
    80003db2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003db4:	4741                	li	a4,16
    80003db6:	86a6                	mv	a3,s1
    80003db8:	fc040613          	addi	a2,s0,-64
    80003dbc:	4581                	li	a1,0
    80003dbe:	854a                	mv	a0,s2
    80003dc0:	00000097          	auipc	ra,0x0
    80003dc4:	b88080e7          	jalr	-1144(ra) # 80003948 <readi>
    80003dc8:	47c1                	li	a5,16
    80003dca:	06f51163          	bne	a0,a5,80003e2c <dirlink+0xa2>
    if(de.inum == 0)
    80003dce:	fc045783          	lhu	a5,-64(s0)
    80003dd2:	c791                	beqz	a5,80003dde <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd4:	24c1                	addiw	s1,s1,16
    80003dd6:	04c92783          	lw	a5,76(s2)
    80003dda:	fcf4ede3          	bltu	s1,a5,80003db4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003dde:	4639                	li	a2,14
    80003de0:	85d2                	mv	a1,s4
    80003de2:	fc240513          	addi	a0,s0,-62
    80003de6:	ffffd097          	auipc	ra,0xffffd
    80003dea:	00e080e7          	jalr	14(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003dee:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003df2:	4741                	li	a4,16
    80003df4:	86a6                	mv	a3,s1
    80003df6:	fc040613          	addi	a2,s0,-64
    80003dfa:	4581                	li	a1,0
    80003dfc:	854a                	mv	a0,s2
    80003dfe:	00000097          	auipc	ra,0x0
    80003e02:	c42080e7          	jalr	-958(ra) # 80003a40 <writei>
    80003e06:	872a                	mv	a4,a0
    80003e08:	47c1                	li	a5,16
  return 0;
    80003e0a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e0c:	02f71863          	bne	a4,a5,80003e3c <dirlink+0xb2>
}
    80003e10:	70e2                	ld	ra,56(sp)
    80003e12:	7442                	ld	s0,48(sp)
    80003e14:	74a2                	ld	s1,40(sp)
    80003e16:	7902                	ld	s2,32(sp)
    80003e18:	69e2                	ld	s3,24(sp)
    80003e1a:	6a42                	ld	s4,16(sp)
    80003e1c:	6121                	addi	sp,sp,64
    80003e1e:	8082                	ret
    iput(ip);
    80003e20:	00000097          	auipc	ra,0x0
    80003e24:	a2e080e7          	jalr	-1490(ra) # 8000384e <iput>
    return -1;
    80003e28:	557d                	li	a0,-1
    80003e2a:	b7dd                	j	80003e10 <dirlink+0x86>
      panic("dirlink read");
    80003e2c:	00004517          	auipc	a0,0x4
    80003e30:	7e450513          	addi	a0,a0,2020 # 80008610 <syscalls+0x1c8>
    80003e34:	ffffc097          	auipc	ra,0xffffc
    80003e38:	70a080e7          	jalr	1802(ra) # 8000053e <panic>
    panic("dirlink");
    80003e3c:	00005517          	auipc	a0,0x5
    80003e40:	8e450513          	addi	a0,a0,-1820 # 80008720 <syscalls+0x2d8>
    80003e44:	ffffc097          	auipc	ra,0xffffc
    80003e48:	6fa080e7          	jalr	1786(ra) # 8000053e <panic>

0000000080003e4c <namei>:

struct inode*
namei(char *path)
{
    80003e4c:	1101                	addi	sp,sp,-32
    80003e4e:	ec06                	sd	ra,24(sp)
    80003e50:	e822                	sd	s0,16(sp)
    80003e52:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e54:	fe040613          	addi	a2,s0,-32
    80003e58:	4581                	li	a1,0
    80003e5a:	00000097          	auipc	ra,0x0
    80003e5e:	dd0080e7          	jalr	-560(ra) # 80003c2a <namex>
}
    80003e62:	60e2                	ld	ra,24(sp)
    80003e64:	6442                	ld	s0,16(sp)
    80003e66:	6105                	addi	sp,sp,32
    80003e68:	8082                	ret

0000000080003e6a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e6a:	1141                	addi	sp,sp,-16
    80003e6c:	e406                	sd	ra,8(sp)
    80003e6e:	e022                	sd	s0,0(sp)
    80003e70:	0800                	addi	s0,sp,16
    80003e72:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e74:	4585                	li	a1,1
    80003e76:	00000097          	auipc	ra,0x0
    80003e7a:	db4080e7          	jalr	-588(ra) # 80003c2a <namex>
    80003e7e:	60a2                	ld	ra,8(sp)
    80003e80:	6402                	ld	s0,0(sp)
    80003e82:	0141                	addi	sp,sp,16
    80003e84:	8082                	ret

0000000080003e86 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e86:	1101                	addi	sp,sp,-32
    80003e88:	ec06                	sd	ra,24(sp)
    80003e8a:	e822                	sd	s0,16(sp)
    80003e8c:	e426                	sd	s1,8(sp)
    80003e8e:	e04a                	sd	s2,0(sp)
    80003e90:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e92:	0001d917          	auipc	s2,0x1d
    80003e96:	24e90913          	addi	s2,s2,590 # 800210e0 <log>
    80003e9a:	01892583          	lw	a1,24(s2)
    80003e9e:	02892503          	lw	a0,40(s2)
    80003ea2:	fffff097          	auipc	ra,0xfffff
    80003ea6:	f2a080e7          	jalr	-214(ra) # 80002dcc <bread>
    80003eaa:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003eac:	02c92683          	lw	a3,44(s2)
    80003eb0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003eb2:	02d05763          	blez	a3,80003ee0 <write_head+0x5a>
    80003eb6:	0001d797          	auipc	a5,0x1d
    80003eba:	25a78793          	addi	a5,a5,602 # 80021110 <log+0x30>
    80003ebe:	05c50713          	addi	a4,a0,92
    80003ec2:	36fd                	addiw	a3,a3,-1
    80003ec4:	1682                	slli	a3,a3,0x20
    80003ec6:	9281                	srli	a3,a3,0x20
    80003ec8:	068a                	slli	a3,a3,0x2
    80003eca:	0001d617          	auipc	a2,0x1d
    80003ece:	24a60613          	addi	a2,a2,586 # 80021114 <log+0x34>
    80003ed2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ed4:	4390                	lw	a2,0(a5)
    80003ed6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003ed8:	0791                	addi	a5,a5,4
    80003eda:	0711                	addi	a4,a4,4
    80003edc:	fed79ce3          	bne	a5,a3,80003ed4 <write_head+0x4e>
  }
  bwrite(buf);
    80003ee0:	8526                	mv	a0,s1
    80003ee2:	fffff097          	auipc	ra,0xfffff
    80003ee6:	fdc080e7          	jalr	-36(ra) # 80002ebe <bwrite>
  brelse(buf);
    80003eea:	8526                	mv	a0,s1
    80003eec:	fffff097          	auipc	ra,0xfffff
    80003ef0:	010080e7          	jalr	16(ra) # 80002efc <brelse>
}
    80003ef4:	60e2                	ld	ra,24(sp)
    80003ef6:	6442                	ld	s0,16(sp)
    80003ef8:	64a2                	ld	s1,8(sp)
    80003efa:	6902                	ld	s2,0(sp)
    80003efc:	6105                	addi	sp,sp,32
    80003efe:	8082                	ret

0000000080003f00 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f00:	0001d797          	auipc	a5,0x1d
    80003f04:	20c7a783          	lw	a5,524(a5) # 8002110c <log+0x2c>
    80003f08:	0af05d63          	blez	a5,80003fc2 <install_trans+0xc2>
{
    80003f0c:	7139                	addi	sp,sp,-64
    80003f0e:	fc06                	sd	ra,56(sp)
    80003f10:	f822                	sd	s0,48(sp)
    80003f12:	f426                	sd	s1,40(sp)
    80003f14:	f04a                	sd	s2,32(sp)
    80003f16:	ec4e                	sd	s3,24(sp)
    80003f18:	e852                	sd	s4,16(sp)
    80003f1a:	e456                	sd	s5,8(sp)
    80003f1c:	e05a                	sd	s6,0(sp)
    80003f1e:	0080                	addi	s0,sp,64
    80003f20:	8b2a                	mv	s6,a0
    80003f22:	0001da97          	auipc	s5,0x1d
    80003f26:	1eea8a93          	addi	s5,s5,494 # 80021110 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f2a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f2c:	0001d997          	auipc	s3,0x1d
    80003f30:	1b498993          	addi	s3,s3,436 # 800210e0 <log>
    80003f34:	a035                	j	80003f60 <install_trans+0x60>
      bunpin(dbuf);
    80003f36:	8526                	mv	a0,s1
    80003f38:	fffff097          	auipc	ra,0xfffff
    80003f3c:	09e080e7          	jalr	158(ra) # 80002fd6 <bunpin>
    brelse(lbuf);
    80003f40:	854a                	mv	a0,s2
    80003f42:	fffff097          	auipc	ra,0xfffff
    80003f46:	fba080e7          	jalr	-70(ra) # 80002efc <brelse>
    brelse(dbuf);
    80003f4a:	8526                	mv	a0,s1
    80003f4c:	fffff097          	auipc	ra,0xfffff
    80003f50:	fb0080e7          	jalr	-80(ra) # 80002efc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f54:	2a05                	addiw	s4,s4,1
    80003f56:	0a91                	addi	s5,s5,4
    80003f58:	02c9a783          	lw	a5,44(s3)
    80003f5c:	04fa5963          	bge	s4,a5,80003fae <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f60:	0189a583          	lw	a1,24(s3)
    80003f64:	014585bb          	addw	a1,a1,s4
    80003f68:	2585                	addiw	a1,a1,1
    80003f6a:	0289a503          	lw	a0,40(s3)
    80003f6e:	fffff097          	auipc	ra,0xfffff
    80003f72:	e5e080e7          	jalr	-418(ra) # 80002dcc <bread>
    80003f76:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f78:	000aa583          	lw	a1,0(s5)
    80003f7c:	0289a503          	lw	a0,40(s3)
    80003f80:	fffff097          	auipc	ra,0xfffff
    80003f84:	e4c080e7          	jalr	-436(ra) # 80002dcc <bread>
    80003f88:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f8a:	40000613          	li	a2,1024
    80003f8e:	05890593          	addi	a1,s2,88
    80003f92:	05850513          	addi	a0,a0,88
    80003f96:	ffffd097          	auipc	ra,0xffffd
    80003f9a:	daa080e7          	jalr	-598(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f9e:	8526                	mv	a0,s1
    80003fa0:	fffff097          	auipc	ra,0xfffff
    80003fa4:	f1e080e7          	jalr	-226(ra) # 80002ebe <bwrite>
    if(recovering == 0)
    80003fa8:	f80b1ce3          	bnez	s6,80003f40 <install_trans+0x40>
    80003fac:	b769                	j	80003f36 <install_trans+0x36>
}
    80003fae:	70e2                	ld	ra,56(sp)
    80003fb0:	7442                	ld	s0,48(sp)
    80003fb2:	74a2                	ld	s1,40(sp)
    80003fb4:	7902                	ld	s2,32(sp)
    80003fb6:	69e2                	ld	s3,24(sp)
    80003fb8:	6a42                	ld	s4,16(sp)
    80003fba:	6aa2                	ld	s5,8(sp)
    80003fbc:	6b02                	ld	s6,0(sp)
    80003fbe:	6121                	addi	sp,sp,64
    80003fc0:	8082                	ret
    80003fc2:	8082                	ret

0000000080003fc4 <initlog>:
{
    80003fc4:	7179                	addi	sp,sp,-48
    80003fc6:	f406                	sd	ra,40(sp)
    80003fc8:	f022                	sd	s0,32(sp)
    80003fca:	ec26                	sd	s1,24(sp)
    80003fcc:	e84a                	sd	s2,16(sp)
    80003fce:	e44e                	sd	s3,8(sp)
    80003fd0:	1800                	addi	s0,sp,48
    80003fd2:	892a                	mv	s2,a0
    80003fd4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003fd6:	0001d497          	auipc	s1,0x1d
    80003fda:	10a48493          	addi	s1,s1,266 # 800210e0 <log>
    80003fde:	00004597          	auipc	a1,0x4
    80003fe2:	64258593          	addi	a1,a1,1602 # 80008620 <syscalls+0x1d8>
    80003fe6:	8526                	mv	a0,s1
    80003fe8:	ffffd097          	auipc	ra,0xffffd
    80003fec:	b6c080e7          	jalr	-1172(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80003ff0:	0149a583          	lw	a1,20(s3)
    80003ff4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003ff6:	0109a783          	lw	a5,16(s3)
    80003ffa:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003ffc:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004000:	854a                	mv	a0,s2
    80004002:	fffff097          	auipc	ra,0xfffff
    80004006:	dca080e7          	jalr	-566(ra) # 80002dcc <bread>
  log.lh.n = lh->n;
    8000400a:	4d3c                	lw	a5,88(a0)
    8000400c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000400e:	02f05563          	blez	a5,80004038 <initlog+0x74>
    80004012:	05c50713          	addi	a4,a0,92
    80004016:	0001d697          	auipc	a3,0x1d
    8000401a:	0fa68693          	addi	a3,a3,250 # 80021110 <log+0x30>
    8000401e:	37fd                	addiw	a5,a5,-1
    80004020:	1782                	slli	a5,a5,0x20
    80004022:	9381                	srli	a5,a5,0x20
    80004024:	078a                	slli	a5,a5,0x2
    80004026:	06050613          	addi	a2,a0,96
    8000402a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000402c:	4310                	lw	a2,0(a4)
    8000402e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004030:	0711                	addi	a4,a4,4
    80004032:	0691                	addi	a3,a3,4
    80004034:	fef71ce3          	bne	a4,a5,8000402c <initlog+0x68>
  brelse(buf);
    80004038:	fffff097          	auipc	ra,0xfffff
    8000403c:	ec4080e7          	jalr	-316(ra) # 80002efc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004040:	4505                	li	a0,1
    80004042:	00000097          	auipc	ra,0x0
    80004046:	ebe080e7          	jalr	-322(ra) # 80003f00 <install_trans>
  log.lh.n = 0;
    8000404a:	0001d797          	auipc	a5,0x1d
    8000404e:	0c07a123          	sw	zero,194(a5) # 8002110c <log+0x2c>
  write_head(); // clear the log
    80004052:	00000097          	auipc	ra,0x0
    80004056:	e34080e7          	jalr	-460(ra) # 80003e86 <write_head>
}
    8000405a:	70a2                	ld	ra,40(sp)
    8000405c:	7402                	ld	s0,32(sp)
    8000405e:	64e2                	ld	s1,24(sp)
    80004060:	6942                	ld	s2,16(sp)
    80004062:	69a2                	ld	s3,8(sp)
    80004064:	6145                	addi	sp,sp,48
    80004066:	8082                	ret

0000000080004068 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004068:	1101                	addi	sp,sp,-32
    8000406a:	ec06                	sd	ra,24(sp)
    8000406c:	e822                	sd	s0,16(sp)
    8000406e:	e426                	sd	s1,8(sp)
    80004070:	e04a                	sd	s2,0(sp)
    80004072:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004074:	0001d517          	auipc	a0,0x1d
    80004078:	06c50513          	addi	a0,a0,108 # 800210e0 <log>
    8000407c:	ffffd097          	auipc	ra,0xffffd
    80004080:	b68080e7          	jalr	-1176(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004084:	0001d497          	auipc	s1,0x1d
    80004088:	05c48493          	addi	s1,s1,92 # 800210e0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000408c:	4979                	li	s2,30
    8000408e:	a039                	j	8000409c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004090:	85a6                	mv	a1,s1
    80004092:	8526                	mv	a0,s1
    80004094:	ffffe097          	auipc	ra,0xffffe
    80004098:	fd8080e7          	jalr	-40(ra) # 8000206c <sleep>
    if(log.committing){
    8000409c:	50dc                	lw	a5,36(s1)
    8000409e:	fbed                	bnez	a5,80004090 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040a0:	509c                	lw	a5,32(s1)
    800040a2:	0017871b          	addiw	a4,a5,1
    800040a6:	0007069b          	sext.w	a3,a4
    800040aa:	0027179b          	slliw	a5,a4,0x2
    800040ae:	9fb9                	addw	a5,a5,a4
    800040b0:	0017979b          	slliw	a5,a5,0x1
    800040b4:	54d8                	lw	a4,44(s1)
    800040b6:	9fb9                	addw	a5,a5,a4
    800040b8:	00f95963          	bge	s2,a5,800040ca <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040bc:	85a6                	mv	a1,s1
    800040be:	8526                	mv	a0,s1
    800040c0:	ffffe097          	auipc	ra,0xffffe
    800040c4:	fac080e7          	jalr	-84(ra) # 8000206c <sleep>
    800040c8:	bfd1                	j	8000409c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040ca:	0001d517          	auipc	a0,0x1d
    800040ce:	01650513          	addi	a0,a0,22 # 800210e0 <log>
    800040d2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800040d4:	ffffd097          	auipc	ra,0xffffd
    800040d8:	bc4080e7          	jalr	-1084(ra) # 80000c98 <release>
      break;
    }
  }
}
    800040dc:	60e2                	ld	ra,24(sp)
    800040de:	6442                	ld	s0,16(sp)
    800040e0:	64a2                	ld	s1,8(sp)
    800040e2:	6902                	ld	s2,0(sp)
    800040e4:	6105                	addi	sp,sp,32
    800040e6:	8082                	ret

00000000800040e8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040e8:	7139                	addi	sp,sp,-64
    800040ea:	fc06                	sd	ra,56(sp)
    800040ec:	f822                	sd	s0,48(sp)
    800040ee:	f426                	sd	s1,40(sp)
    800040f0:	f04a                	sd	s2,32(sp)
    800040f2:	ec4e                	sd	s3,24(sp)
    800040f4:	e852                	sd	s4,16(sp)
    800040f6:	e456                	sd	s5,8(sp)
    800040f8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040fa:	0001d497          	auipc	s1,0x1d
    800040fe:	fe648493          	addi	s1,s1,-26 # 800210e0 <log>
    80004102:	8526                	mv	a0,s1
    80004104:	ffffd097          	auipc	ra,0xffffd
    80004108:	ae0080e7          	jalr	-1312(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000410c:	509c                	lw	a5,32(s1)
    8000410e:	37fd                	addiw	a5,a5,-1
    80004110:	0007891b          	sext.w	s2,a5
    80004114:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004116:	50dc                	lw	a5,36(s1)
    80004118:	efb9                	bnez	a5,80004176 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000411a:	06091663          	bnez	s2,80004186 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000411e:	0001d497          	auipc	s1,0x1d
    80004122:	fc248493          	addi	s1,s1,-62 # 800210e0 <log>
    80004126:	4785                	li	a5,1
    80004128:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000412a:	8526                	mv	a0,s1
    8000412c:	ffffd097          	auipc	ra,0xffffd
    80004130:	b6c080e7          	jalr	-1172(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004134:	54dc                	lw	a5,44(s1)
    80004136:	06f04763          	bgtz	a5,800041a4 <end_op+0xbc>
    acquire(&log.lock);
    8000413a:	0001d497          	auipc	s1,0x1d
    8000413e:	fa648493          	addi	s1,s1,-90 # 800210e0 <log>
    80004142:	8526                	mv	a0,s1
    80004144:	ffffd097          	auipc	ra,0xffffd
    80004148:	aa0080e7          	jalr	-1376(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000414c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004150:	8526                	mv	a0,s1
    80004152:	ffffe097          	auipc	ra,0xffffe
    80004156:	0a6080e7          	jalr	166(ra) # 800021f8 <wakeup>
    release(&log.lock);
    8000415a:	8526                	mv	a0,s1
    8000415c:	ffffd097          	auipc	ra,0xffffd
    80004160:	b3c080e7          	jalr	-1220(ra) # 80000c98 <release>
}
    80004164:	70e2                	ld	ra,56(sp)
    80004166:	7442                	ld	s0,48(sp)
    80004168:	74a2                	ld	s1,40(sp)
    8000416a:	7902                	ld	s2,32(sp)
    8000416c:	69e2                	ld	s3,24(sp)
    8000416e:	6a42                	ld	s4,16(sp)
    80004170:	6aa2                	ld	s5,8(sp)
    80004172:	6121                	addi	sp,sp,64
    80004174:	8082                	ret
    panic("log.committing");
    80004176:	00004517          	auipc	a0,0x4
    8000417a:	4b250513          	addi	a0,a0,1202 # 80008628 <syscalls+0x1e0>
    8000417e:	ffffc097          	auipc	ra,0xffffc
    80004182:	3c0080e7          	jalr	960(ra) # 8000053e <panic>
    wakeup(&log);
    80004186:	0001d497          	auipc	s1,0x1d
    8000418a:	f5a48493          	addi	s1,s1,-166 # 800210e0 <log>
    8000418e:	8526                	mv	a0,s1
    80004190:	ffffe097          	auipc	ra,0xffffe
    80004194:	068080e7          	jalr	104(ra) # 800021f8 <wakeup>
  release(&log.lock);
    80004198:	8526                	mv	a0,s1
    8000419a:	ffffd097          	auipc	ra,0xffffd
    8000419e:	afe080e7          	jalr	-1282(ra) # 80000c98 <release>
  if(do_commit){
    800041a2:	b7c9                	j	80004164 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041a4:	0001da97          	auipc	s5,0x1d
    800041a8:	f6ca8a93          	addi	s5,s5,-148 # 80021110 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041ac:	0001da17          	auipc	s4,0x1d
    800041b0:	f34a0a13          	addi	s4,s4,-204 # 800210e0 <log>
    800041b4:	018a2583          	lw	a1,24(s4)
    800041b8:	012585bb          	addw	a1,a1,s2
    800041bc:	2585                	addiw	a1,a1,1
    800041be:	028a2503          	lw	a0,40(s4)
    800041c2:	fffff097          	auipc	ra,0xfffff
    800041c6:	c0a080e7          	jalr	-1014(ra) # 80002dcc <bread>
    800041ca:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041cc:	000aa583          	lw	a1,0(s5)
    800041d0:	028a2503          	lw	a0,40(s4)
    800041d4:	fffff097          	auipc	ra,0xfffff
    800041d8:	bf8080e7          	jalr	-1032(ra) # 80002dcc <bread>
    800041dc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041de:	40000613          	li	a2,1024
    800041e2:	05850593          	addi	a1,a0,88
    800041e6:	05848513          	addi	a0,s1,88
    800041ea:	ffffd097          	auipc	ra,0xffffd
    800041ee:	b56080e7          	jalr	-1194(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800041f2:	8526                	mv	a0,s1
    800041f4:	fffff097          	auipc	ra,0xfffff
    800041f8:	cca080e7          	jalr	-822(ra) # 80002ebe <bwrite>
    brelse(from);
    800041fc:	854e                	mv	a0,s3
    800041fe:	fffff097          	auipc	ra,0xfffff
    80004202:	cfe080e7          	jalr	-770(ra) # 80002efc <brelse>
    brelse(to);
    80004206:	8526                	mv	a0,s1
    80004208:	fffff097          	auipc	ra,0xfffff
    8000420c:	cf4080e7          	jalr	-780(ra) # 80002efc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004210:	2905                	addiw	s2,s2,1
    80004212:	0a91                	addi	s5,s5,4
    80004214:	02ca2783          	lw	a5,44(s4)
    80004218:	f8f94ee3          	blt	s2,a5,800041b4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000421c:	00000097          	auipc	ra,0x0
    80004220:	c6a080e7          	jalr	-918(ra) # 80003e86 <write_head>
    install_trans(0); // Now install writes to home locations
    80004224:	4501                	li	a0,0
    80004226:	00000097          	auipc	ra,0x0
    8000422a:	cda080e7          	jalr	-806(ra) # 80003f00 <install_trans>
    log.lh.n = 0;
    8000422e:	0001d797          	auipc	a5,0x1d
    80004232:	ec07af23          	sw	zero,-290(a5) # 8002110c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004236:	00000097          	auipc	ra,0x0
    8000423a:	c50080e7          	jalr	-944(ra) # 80003e86 <write_head>
    8000423e:	bdf5                	j	8000413a <end_op+0x52>

0000000080004240 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004240:	1101                	addi	sp,sp,-32
    80004242:	ec06                	sd	ra,24(sp)
    80004244:	e822                	sd	s0,16(sp)
    80004246:	e426                	sd	s1,8(sp)
    80004248:	e04a                	sd	s2,0(sp)
    8000424a:	1000                	addi	s0,sp,32
    8000424c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000424e:	0001d917          	auipc	s2,0x1d
    80004252:	e9290913          	addi	s2,s2,-366 # 800210e0 <log>
    80004256:	854a                	mv	a0,s2
    80004258:	ffffd097          	auipc	ra,0xffffd
    8000425c:	98c080e7          	jalr	-1652(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004260:	02c92603          	lw	a2,44(s2)
    80004264:	47f5                	li	a5,29
    80004266:	06c7c563          	blt	a5,a2,800042d0 <log_write+0x90>
    8000426a:	0001d797          	auipc	a5,0x1d
    8000426e:	e927a783          	lw	a5,-366(a5) # 800210fc <log+0x1c>
    80004272:	37fd                	addiw	a5,a5,-1
    80004274:	04f65e63          	bge	a2,a5,800042d0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004278:	0001d797          	auipc	a5,0x1d
    8000427c:	e887a783          	lw	a5,-376(a5) # 80021100 <log+0x20>
    80004280:	06f05063          	blez	a5,800042e0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004284:	4781                	li	a5,0
    80004286:	06c05563          	blez	a2,800042f0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000428a:	44cc                	lw	a1,12(s1)
    8000428c:	0001d717          	auipc	a4,0x1d
    80004290:	e8470713          	addi	a4,a4,-380 # 80021110 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004294:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004296:	4314                	lw	a3,0(a4)
    80004298:	04b68c63          	beq	a3,a1,800042f0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000429c:	2785                	addiw	a5,a5,1
    8000429e:	0711                	addi	a4,a4,4
    800042a0:	fef61be3          	bne	a2,a5,80004296 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042a4:	0621                	addi	a2,a2,8
    800042a6:	060a                	slli	a2,a2,0x2
    800042a8:	0001d797          	auipc	a5,0x1d
    800042ac:	e3878793          	addi	a5,a5,-456 # 800210e0 <log>
    800042b0:	963e                	add	a2,a2,a5
    800042b2:	44dc                	lw	a5,12(s1)
    800042b4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042b6:	8526                	mv	a0,s1
    800042b8:	fffff097          	auipc	ra,0xfffff
    800042bc:	ce2080e7          	jalr	-798(ra) # 80002f9a <bpin>
    log.lh.n++;
    800042c0:	0001d717          	auipc	a4,0x1d
    800042c4:	e2070713          	addi	a4,a4,-480 # 800210e0 <log>
    800042c8:	575c                	lw	a5,44(a4)
    800042ca:	2785                	addiw	a5,a5,1
    800042cc:	d75c                	sw	a5,44(a4)
    800042ce:	a835                	j	8000430a <log_write+0xca>
    panic("too big a transaction");
    800042d0:	00004517          	auipc	a0,0x4
    800042d4:	36850513          	addi	a0,a0,872 # 80008638 <syscalls+0x1f0>
    800042d8:	ffffc097          	auipc	ra,0xffffc
    800042dc:	266080e7          	jalr	614(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800042e0:	00004517          	auipc	a0,0x4
    800042e4:	37050513          	addi	a0,a0,880 # 80008650 <syscalls+0x208>
    800042e8:	ffffc097          	auipc	ra,0xffffc
    800042ec:	256080e7          	jalr	598(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800042f0:	00878713          	addi	a4,a5,8
    800042f4:	00271693          	slli	a3,a4,0x2
    800042f8:	0001d717          	auipc	a4,0x1d
    800042fc:	de870713          	addi	a4,a4,-536 # 800210e0 <log>
    80004300:	9736                	add	a4,a4,a3
    80004302:	44d4                	lw	a3,12(s1)
    80004304:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004306:	faf608e3          	beq	a2,a5,800042b6 <log_write+0x76>
  }
  release(&log.lock);
    8000430a:	0001d517          	auipc	a0,0x1d
    8000430e:	dd650513          	addi	a0,a0,-554 # 800210e0 <log>
    80004312:	ffffd097          	auipc	ra,0xffffd
    80004316:	986080e7          	jalr	-1658(ra) # 80000c98 <release>
}
    8000431a:	60e2                	ld	ra,24(sp)
    8000431c:	6442                	ld	s0,16(sp)
    8000431e:	64a2                	ld	s1,8(sp)
    80004320:	6902                	ld	s2,0(sp)
    80004322:	6105                	addi	sp,sp,32
    80004324:	8082                	ret

0000000080004326 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004326:	1101                	addi	sp,sp,-32
    80004328:	ec06                	sd	ra,24(sp)
    8000432a:	e822                	sd	s0,16(sp)
    8000432c:	e426                	sd	s1,8(sp)
    8000432e:	e04a                	sd	s2,0(sp)
    80004330:	1000                	addi	s0,sp,32
    80004332:	84aa                	mv	s1,a0
    80004334:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004336:	00004597          	auipc	a1,0x4
    8000433a:	33a58593          	addi	a1,a1,826 # 80008670 <syscalls+0x228>
    8000433e:	0521                	addi	a0,a0,8
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	814080e7          	jalr	-2028(ra) # 80000b54 <initlock>
  lk->name = name;
    80004348:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000434c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004350:	0204a423          	sw	zero,40(s1)
}
    80004354:	60e2                	ld	ra,24(sp)
    80004356:	6442                	ld	s0,16(sp)
    80004358:	64a2                	ld	s1,8(sp)
    8000435a:	6902                	ld	s2,0(sp)
    8000435c:	6105                	addi	sp,sp,32
    8000435e:	8082                	ret

0000000080004360 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004360:	1101                	addi	sp,sp,-32
    80004362:	ec06                	sd	ra,24(sp)
    80004364:	e822                	sd	s0,16(sp)
    80004366:	e426                	sd	s1,8(sp)
    80004368:	e04a                	sd	s2,0(sp)
    8000436a:	1000                	addi	s0,sp,32
    8000436c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000436e:	00850913          	addi	s2,a0,8
    80004372:	854a                	mv	a0,s2
    80004374:	ffffd097          	auipc	ra,0xffffd
    80004378:	870080e7          	jalr	-1936(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000437c:	409c                	lw	a5,0(s1)
    8000437e:	cb89                	beqz	a5,80004390 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004380:	85ca                	mv	a1,s2
    80004382:	8526                	mv	a0,s1
    80004384:	ffffe097          	auipc	ra,0xffffe
    80004388:	ce8080e7          	jalr	-792(ra) # 8000206c <sleep>
  while (lk->locked) {
    8000438c:	409c                	lw	a5,0(s1)
    8000438e:	fbed                	bnez	a5,80004380 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004390:	4785                	li	a5,1
    80004392:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004394:	ffffd097          	auipc	ra,0xffffd
    80004398:	61c080e7          	jalr	1564(ra) # 800019b0 <myproc>
    8000439c:	591c                	lw	a5,48(a0)
    8000439e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043a0:	854a                	mv	a0,s2
    800043a2:	ffffd097          	auipc	ra,0xffffd
    800043a6:	8f6080e7          	jalr	-1802(ra) # 80000c98 <release>
}
    800043aa:	60e2                	ld	ra,24(sp)
    800043ac:	6442                	ld	s0,16(sp)
    800043ae:	64a2                	ld	s1,8(sp)
    800043b0:	6902                	ld	s2,0(sp)
    800043b2:	6105                	addi	sp,sp,32
    800043b4:	8082                	ret

00000000800043b6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043b6:	1101                	addi	sp,sp,-32
    800043b8:	ec06                	sd	ra,24(sp)
    800043ba:	e822                	sd	s0,16(sp)
    800043bc:	e426                	sd	s1,8(sp)
    800043be:	e04a                	sd	s2,0(sp)
    800043c0:	1000                	addi	s0,sp,32
    800043c2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043c4:	00850913          	addi	s2,a0,8
    800043c8:	854a                	mv	a0,s2
    800043ca:	ffffd097          	auipc	ra,0xffffd
    800043ce:	81a080e7          	jalr	-2022(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800043d2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043d6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043da:	8526                	mv	a0,s1
    800043dc:	ffffe097          	auipc	ra,0xffffe
    800043e0:	e1c080e7          	jalr	-484(ra) # 800021f8 <wakeup>
  release(&lk->lk);
    800043e4:	854a                	mv	a0,s2
    800043e6:	ffffd097          	auipc	ra,0xffffd
    800043ea:	8b2080e7          	jalr	-1870(ra) # 80000c98 <release>
}
    800043ee:	60e2                	ld	ra,24(sp)
    800043f0:	6442                	ld	s0,16(sp)
    800043f2:	64a2                	ld	s1,8(sp)
    800043f4:	6902                	ld	s2,0(sp)
    800043f6:	6105                	addi	sp,sp,32
    800043f8:	8082                	ret

00000000800043fa <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043fa:	7179                	addi	sp,sp,-48
    800043fc:	f406                	sd	ra,40(sp)
    800043fe:	f022                	sd	s0,32(sp)
    80004400:	ec26                	sd	s1,24(sp)
    80004402:	e84a                	sd	s2,16(sp)
    80004404:	e44e                	sd	s3,8(sp)
    80004406:	1800                	addi	s0,sp,48
    80004408:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000440a:	00850913          	addi	s2,a0,8
    8000440e:	854a                	mv	a0,s2
    80004410:	ffffc097          	auipc	ra,0xffffc
    80004414:	7d4080e7          	jalr	2004(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004418:	409c                	lw	a5,0(s1)
    8000441a:	ef99                	bnez	a5,80004438 <holdingsleep+0x3e>
    8000441c:	4481                	li	s1,0
  release(&lk->lk);
    8000441e:	854a                	mv	a0,s2
    80004420:	ffffd097          	auipc	ra,0xffffd
    80004424:	878080e7          	jalr	-1928(ra) # 80000c98 <release>
  return r;
}
    80004428:	8526                	mv	a0,s1
    8000442a:	70a2                	ld	ra,40(sp)
    8000442c:	7402                	ld	s0,32(sp)
    8000442e:	64e2                	ld	s1,24(sp)
    80004430:	6942                	ld	s2,16(sp)
    80004432:	69a2                	ld	s3,8(sp)
    80004434:	6145                	addi	sp,sp,48
    80004436:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004438:	0284a983          	lw	s3,40(s1)
    8000443c:	ffffd097          	auipc	ra,0xffffd
    80004440:	574080e7          	jalr	1396(ra) # 800019b0 <myproc>
    80004444:	5904                	lw	s1,48(a0)
    80004446:	413484b3          	sub	s1,s1,s3
    8000444a:	0014b493          	seqz	s1,s1
    8000444e:	bfc1                	j	8000441e <holdingsleep+0x24>

0000000080004450 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004450:	1141                	addi	sp,sp,-16
    80004452:	e406                	sd	ra,8(sp)
    80004454:	e022                	sd	s0,0(sp)
    80004456:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004458:	00004597          	auipc	a1,0x4
    8000445c:	22858593          	addi	a1,a1,552 # 80008680 <syscalls+0x238>
    80004460:	0001d517          	auipc	a0,0x1d
    80004464:	dc850513          	addi	a0,a0,-568 # 80021228 <ftable>
    80004468:	ffffc097          	auipc	ra,0xffffc
    8000446c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>
}
    80004470:	60a2                	ld	ra,8(sp)
    80004472:	6402                	ld	s0,0(sp)
    80004474:	0141                	addi	sp,sp,16
    80004476:	8082                	ret

0000000080004478 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004478:	1101                	addi	sp,sp,-32
    8000447a:	ec06                	sd	ra,24(sp)
    8000447c:	e822                	sd	s0,16(sp)
    8000447e:	e426                	sd	s1,8(sp)
    80004480:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004482:	0001d517          	auipc	a0,0x1d
    80004486:	da650513          	addi	a0,a0,-602 # 80021228 <ftable>
    8000448a:	ffffc097          	auipc	ra,0xffffc
    8000448e:	75a080e7          	jalr	1882(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004492:	0001d497          	auipc	s1,0x1d
    80004496:	dae48493          	addi	s1,s1,-594 # 80021240 <ftable+0x18>
    8000449a:	0001e717          	auipc	a4,0x1e
    8000449e:	d4670713          	addi	a4,a4,-698 # 800221e0 <ftable+0xfb8>
    if(f->ref == 0){
    800044a2:	40dc                	lw	a5,4(s1)
    800044a4:	cf99                	beqz	a5,800044c2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044a6:	02848493          	addi	s1,s1,40
    800044aa:	fee49ce3          	bne	s1,a4,800044a2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044ae:	0001d517          	auipc	a0,0x1d
    800044b2:	d7a50513          	addi	a0,a0,-646 # 80021228 <ftable>
    800044b6:	ffffc097          	auipc	ra,0xffffc
    800044ba:	7e2080e7          	jalr	2018(ra) # 80000c98 <release>
  return 0;
    800044be:	4481                	li	s1,0
    800044c0:	a819                	j	800044d6 <filealloc+0x5e>
      f->ref = 1;
    800044c2:	4785                	li	a5,1
    800044c4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044c6:	0001d517          	auipc	a0,0x1d
    800044ca:	d6250513          	addi	a0,a0,-670 # 80021228 <ftable>
    800044ce:	ffffc097          	auipc	ra,0xffffc
    800044d2:	7ca080e7          	jalr	1994(ra) # 80000c98 <release>
}
    800044d6:	8526                	mv	a0,s1
    800044d8:	60e2                	ld	ra,24(sp)
    800044da:	6442                	ld	s0,16(sp)
    800044dc:	64a2                	ld	s1,8(sp)
    800044de:	6105                	addi	sp,sp,32
    800044e0:	8082                	ret

00000000800044e2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044e2:	1101                	addi	sp,sp,-32
    800044e4:	ec06                	sd	ra,24(sp)
    800044e6:	e822                	sd	s0,16(sp)
    800044e8:	e426                	sd	s1,8(sp)
    800044ea:	1000                	addi	s0,sp,32
    800044ec:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044ee:	0001d517          	auipc	a0,0x1d
    800044f2:	d3a50513          	addi	a0,a0,-710 # 80021228 <ftable>
    800044f6:	ffffc097          	auipc	ra,0xffffc
    800044fa:	6ee080e7          	jalr	1774(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800044fe:	40dc                	lw	a5,4(s1)
    80004500:	02f05263          	blez	a5,80004524 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004504:	2785                	addiw	a5,a5,1
    80004506:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004508:	0001d517          	auipc	a0,0x1d
    8000450c:	d2050513          	addi	a0,a0,-736 # 80021228 <ftable>
    80004510:	ffffc097          	auipc	ra,0xffffc
    80004514:	788080e7          	jalr	1928(ra) # 80000c98 <release>
  return f;
}
    80004518:	8526                	mv	a0,s1
    8000451a:	60e2                	ld	ra,24(sp)
    8000451c:	6442                	ld	s0,16(sp)
    8000451e:	64a2                	ld	s1,8(sp)
    80004520:	6105                	addi	sp,sp,32
    80004522:	8082                	ret
    panic("filedup");
    80004524:	00004517          	auipc	a0,0x4
    80004528:	16450513          	addi	a0,a0,356 # 80008688 <syscalls+0x240>
    8000452c:	ffffc097          	auipc	ra,0xffffc
    80004530:	012080e7          	jalr	18(ra) # 8000053e <panic>

0000000080004534 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004534:	7139                	addi	sp,sp,-64
    80004536:	fc06                	sd	ra,56(sp)
    80004538:	f822                	sd	s0,48(sp)
    8000453a:	f426                	sd	s1,40(sp)
    8000453c:	f04a                	sd	s2,32(sp)
    8000453e:	ec4e                	sd	s3,24(sp)
    80004540:	e852                	sd	s4,16(sp)
    80004542:	e456                	sd	s5,8(sp)
    80004544:	0080                	addi	s0,sp,64
    80004546:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004548:	0001d517          	auipc	a0,0x1d
    8000454c:	ce050513          	addi	a0,a0,-800 # 80021228 <ftable>
    80004550:	ffffc097          	auipc	ra,0xffffc
    80004554:	694080e7          	jalr	1684(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004558:	40dc                	lw	a5,4(s1)
    8000455a:	06f05163          	blez	a5,800045bc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000455e:	37fd                	addiw	a5,a5,-1
    80004560:	0007871b          	sext.w	a4,a5
    80004564:	c0dc                	sw	a5,4(s1)
    80004566:	06e04363          	bgtz	a4,800045cc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000456a:	0004a903          	lw	s2,0(s1)
    8000456e:	0094ca83          	lbu	s5,9(s1)
    80004572:	0104ba03          	ld	s4,16(s1)
    80004576:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000457a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000457e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004582:	0001d517          	auipc	a0,0x1d
    80004586:	ca650513          	addi	a0,a0,-858 # 80021228 <ftable>
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	70e080e7          	jalr	1806(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004592:	4785                	li	a5,1
    80004594:	04f90d63          	beq	s2,a5,800045ee <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004598:	3979                	addiw	s2,s2,-2
    8000459a:	4785                	li	a5,1
    8000459c:	0527e063          	bltu	a5,s2,800045dc <fileclose+0xa8>
    begin_op();
    800045a0:	00000097          	auipc	ra,0x0
    800045a4:	ac8080e7          	jalr	-1336(ra) # 80004068 <begin_op>
    iput(ff.ip);
    800045a8:	854e                	mv	a0,s3
    800045aa:	fffff097          	auipc	ra,0xfffff
    800045ae:	2a4080e7          	jalr	676(ra) # 8000384e <iput>
    end_op();
    800045b2:	00000097          	auipc	ra,0x0
    800045b6:	b36080e7          	jalr	-1226(ra) # 800040e8 <end_op>
    800045ba:	a00d                	j	800045dc <fileclose+0xa8>
    panic("fileclose");
    800045bc:	00004517          	auipc	a0,0x4
    800045c0:	0d450513          	addi	a0,a0,212 # 80008690 <syscalls+0x248>
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	f7a080e7          	jalr	-134(ra) # 8000053e <panic>
    release(&ftable.lock);
    800045cc:	0001d517          	auipc	a0,0x1d
    800045d0:	c5c50513          	addi	a0,a0,-932 # 80021228 <ftable>
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	6c4080e7          	jalr	1732(ra) # 80000c98 <release>
  }
}
    800045dc:	70e2                	ld	ra,56(sp)
    800045de:	7442                	ld	s0,48(sp)
    800045e0:	74a2                	ld	s1,40(sp)
    800045e2:	7902                	ld	s2,32(sp)
    800045e4:	69e2                	ld	s3,24(sp)
    800045e6:	6a42                	ld	s4,16(sp)
    800045e8:	6aa2                	ld	s5,8(sp)
    800045ea:	6121                	addi	sp,sp,64
    800045ec:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045ee:	85d6                	mv	a1,s5
    800045f0:	8552                	mv	a0,s4
    800045f2:	00000097          	auipc	ra,0x0
    800045f6:	34c080e7          	jalr	844(ra) # 8000493e <pipeclose>
    800045fa:	b7cd                	j	800045dc <fileclose+0xa8>

00000000800045fc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045fc:	715d                	addi	sp,sp,-80
    800045fe:	e486                	sd	ra,72(sp)
    80004600:	e0a2                	sd	s0,64(sp)
    80004602:	fc26                	sd	s1,56(sp)
    80004604:	f84a                	sd	s2,48(sp)
    80004606:	f44e                	sd	s3,40(sp)
    80004608:	0880                	addi	s0,sp,80
    8000460a:	84aa                	mv	s1,a0
    8000460c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000460e:	ffffd097          	auipc	ra,0xffffd
    80004612:	3a2080e7          	jalr	930(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004616:	409c                	lw	a5,0(s1)
    80004618:	37f9                	addiw	a5,a5,-2
    8000461a:	4705                	li	a4,1
    8000461c:	04f76763          	bltu	a4,a5,8000466a <filestat+0x6e>
    80004620:	892a                	mv	s2,a0
    ilock(f->ip);
    80004622:	6c88                	ld	a0,24(s1)
    80004624:	fffff097          	auipc	ra,0xfffff
    80004628:	070080e7          	jalr	112(ra) # 80003694 <ilock>
    stati(f->ip, &st);
    8000462c:	fb840593          	addi	a1,s0,-72
    80004630:	6c88                	ld	a0,24(s1)
    80004632:	fffff097          	auipc	ra,0xfffff
    80004636:	2ec080e7          	jalr	748(ra) # 8000391e <stati>
    iunlock(f->ip);
    8000463a:	6c88                	ld	a0,24(s1)
    8000463c:	fffff097          	auipc	ra,0xfffff
    80004640:	11a080e7          	jalr	282(ra) # 80003756 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004644:	46e1                	li	a3,24
    80004646:	fb840613          	addi	a2,s0,-72
    8000464a:	85ce                	mv	a1,s3
    8000464c:	05093503          	ld	a0,80(s2)
    80004650:	ffffd097          	auipc	ra,0xffffd
    80004654:	022080e7          	jalr	34(ra) # 80001672 <copyout>
    80004658:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000465c:	60a6                	ld	ra,72(sp)
    8000465e:	6406                	ld	s0,64(sp)
    80004660:	74e2                	ld	s1,56(sp)
    80004662:	7942                	ld	s2,48(sp)
    80004664:	79a2                	ld	s3,40(sp)
    80004666:	6161                	addi	sp,sp,80
    80004668:	8082                	ret
  return -1;
    8000466a:	557d                	li	a0,-1
    8000466c:	bfc5                	j	8000465c <filestat+0x60>

000000008000466e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000466e:	7179                	addi	sp,sp,-48
    80004670:	f406                	sd	ra,40(sp)
    80004672:	f022                	sd	s0,32(sp)
    80004674:	ec26                	sd	s1,24(sp)
    80004676:	e84a                	sd	s2,16(sp)
    80004678:	e44e                	sd	s3,8(sp)
    8000467a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000467c:	00854783          	lbu	a5,8(a0)
    80004680:	c3d5                	beqz	a5,80004724 <fileread+0xb6>
    80004682:	84aa                	mv	s1,a0
    80004684:	89ae                	mv	s3,a1
    80004686:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004688:	411c                	lw	a5,0(a0)
    8000468a:	4705                	li	a4,1
    8000468c:	04e78963          	beq	a5,a4,800046de <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004690:	470d                	li	a4,3
    80004692:	04e78d63          	beq	a5,a4,800046ec <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004696:	4709                	li	a4,2
    80004698:	06e79e63          	bne	a5,a4,80004714 <fileread+0xa6>
    ilock(f->ip);
    8000469c:	6d08                	ld	a0,24(a0)
    8000469e:	fffff097          	auipc	ra,0xfffff
    800046a2:	ff6080e7          	jalr	-10(ra) # 80003694 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046a6:	874a                	mv	a4,s2
    800046a8:	5094                	lw	a3,32(s1)
    800046aa:	864e                	mv	a2,s3
    800046ac:	4585                	li	a1,1
    800046ae:	6c88                	ld	a0,24(s1)
    800046b0:	fffff097          	auipc	ra,0xfffff
    800046b4:	298080e7          	jalr	664(ra) # 80003948 <readi>
    800046b8:	892a                	mv	s2,a0
    800046ba:	00a05563          	blez	a0,800046c4 <fileread+0x56>
      f->off += r;
    800046be:	509c                	lw	a5,32(s1)
    800046c0:	9fa9                	addw	a5,a5,a0
    800046c2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046c4:	6c88                	ld	a0,24(s1)
    800046c6:	fffff097          	auipc	ra,0xfffff
    800046ca:	090080e7          	jalr	144(ra) # 80003756 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800046ce:	854a                	mv	a0,s2
    800046d0:	70a2                	ld	ra,40(sp)
    800046d2:	7402                	ld	s0,32(sp)
    800046d4:	64e2                	ld	s1,24(sp)
    800046d6:	6942                	ld	s2,16(sp)
    800046d8:	69a2                	ld	s3,8(sp)
    800046da:	6145                	addi	sp,sp,48
    800046dc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046de:	6908                	ld	a0,16(a0)
    800046e0:	00000097          	auipc	ra,0x0
    800046e4:	3c8080e7          	jalr	968(ra) # 80004aa8 <piperead>
    800046e8:	892a                	mv	s2,a0
    800046ea:	b7d5                	j	800046ce <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046ec:	02451783          	lh	a5,36(a0)
    800046f0:	03079693          	slli	a3,a5,0x30
    800046f4:	92c1                	srli	a3,a3,0x30
    800046f6:	4725                	li	a4,9
    800046f8:	02d76863          	bltu	a4,a3,80004728 <fileread+0xba>
    800046fc:	0792                	slli	a5,a5,0x4
    800046fe:	0001d717          	auipc	a4,0x1d
    80004702:	a8a70713          	addi	a4,a4,-1398 # 80021188 <devsw>
    80004706:	97ba                	add	a5,a5,a4
    80004708:	639c                	ld	a5,0(a5)
    8000470a:	c38d                	beqz	a5,8000472c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000470c:	4505                	li	a0,1
    8000470e:	9782                	jalr	a5
    80004710:	892a                	mv	s2,a0
    80004712:	bf75                	j	800046ce <fileread+0x60>
    panic("fileread");
    80004714:	00004517          	auipc	a0,0x4
    80004718:	f8c50513          	addi	a0,a0,-116 # 800086a0 <syscalls+0x258>
    8000471c:	ffffc097          	auipc	ra,0xffffc
    80004720:	e22080e7          	jalr	-478(ra) # 8000053e <panic>
    return -1;
    80004724:	597d                	li	s2,-1
    80004726:	b765                	j	800046ce <fileread+0x60>
      return -1;
    80004728:	597d                	li	s2,-1
    8000472a:	b755                	j	800046ce <fileread+0x60>
    8000472c:	597d                	li	s2,-1
    8000472e:	b745                	j	800046ce <fileread+0x60>

0000000080004730 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004730:	715d                	addi	sp,sp,-80
    80004732:	e486                	sd	ra,72(sp)
    80004734:	e0a2                	sd	s0,64(sp)
    80004736:	fc26                	sd	s1,56(sp)
    80004738:	f84a                	sd	s2,48(sp)
    8000473a:	f44e                	sd	s3,40(sp)
    8000473c:	f052                	sd	s4,32(sp)
    8000473e:	ec56                	sd	s5,24(sp)
    80004740:	e85a                	sd	s6,16(sp)
    80004742:	e45e                	sd	s7,8(sp)
    80004744:	e062                	sd	s8,0(sp)
    80004746:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004748:	00954783          	lbu	a5,9(a0)
    8000474c:	10078663          	beqz	a5,80004858 <filewrite+0x128>
    80004750:	892a                	mv	s2,a0
    80004752:	8aae                	mv	s5,a1
    80004754:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004756:	411c                	lw	a5,0(a0)
    80004758:	4705                	li	a4,1
    8000475a:	02e78263          	beq	a5,a4,8000477e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000475e:	470d                	li	a4,3
    80004760:	02e78663          	beq	a5,a4,8000478c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004764:	4709                	li	a4,2
    80004766:	0ee79163          	bne	a5,a4,80004848 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000476a:	0ac05d63          	blez	a2,80004824 <filewrite+0xf4>
    int i = 0;
    8000476e:	4981                	li	s3,0
    80004770:	6b05                	lui	s6,0x1
    80004772:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004776:	6b85                	lui	s7,0x1
    80004778:	c00b8b9b          	addiw	s7,s7,-1024
    8000477c:	a861                	j	80004814 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000477e:	6908                	ld	a0,16(a0)
    80004780:	00000097          	auipc	ra,0x0
    80004784:	22e080e7          	jalr	558(ra) # 800049ae <pipewrite>
    80004788:	8a2a                	mv	s4,a0
    8000478a:	a045                	j	8000482a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000478c:	02451783          	lh	a5,36(a0)
    80004790:	03079693          	slli	a3,a5,0x30
    80004794:	92c1                	srli	a3,a3,0x30
    80004796:	4725                	li	a4,9
    80004798:	0cd76263          	bltu	a4,a3,8000485c <filewrite+0x12c>
    8000479c:	0792                	slli	a5,a5,0x4
    8000479e:	0001d717          	auipc	a4,0x1d
    800047a2:	9ea70713          	addi	a4,a4,-1558 # 80021188 <devsw>
    800047a6:	97ba                	add	a5,a5,a4
    800047a8:	679c                	ld	a5,8(a5)
    800047aa:	cbdd                	beqz	a5,80004860 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800047ac:	4505                	li	a0,1
    800047ae:	9782                	jalr	a5
    800047b0:	8a2a                	mv	s4,a0
    800047b2:	a8a5                	j	8000482a <filewrite+0xfa>
    800047b4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047b8:	00000097          	auipc	ra,0x0
    800047bc:	8b0080e7          	jalr	-1872(ra) # 80004068 <begin_op>
      ilock(f->ip);
    800047c0:	01893503          	ld	a0,24(s2)
    800047c4:	fffff097          	auipc	ra,0xfffff
    800047c8:	ed0080e7          	jalr	-304(ra) # 80003694 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047cc:	8762                	mv	a4,s8
    800047ce:	02092683          	lw	a3,32(s2)
    800047d2:	01598633          	add	a2,s3,s5
    800047d6:	4585                	li	a1,1
    800047d8:	01893503          	ld	a0,24(s2)
    800047dc:	fffff097          	auipc	ra,0xfffff
    800047e0:	264080e7          	jalr	612(ra) # 80003a40 <writei>
    800047e4:	84aa                	mv	s1,a0
    800047e6:	00a05763          	blez	a0,800047f4 <filewrite+0xc4>
        f->off += r;
    800047ea:	02092783          	lw	a5,32(s2)
    800047ee:	9fa9                	addw	a5,a5,a0
    800047f0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047f4:	01893503          	ld	a0,24(s2)
    800047f8:	fffff097          	auipc	ra,0xfffff
    800047fc:	f5e080e7          	jalr	-162(ra) # 80003756 <iunlock>
      end_op();
    80004800:	00000097          	auipc	ra,0x0
    80004804:	8e8080e7          	jalr	-1816(ra) # 800040e8 <end_op>

      if(r != n1){
    80004808:	009c1f63          	bne	s8,s1,80004826 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000480c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004810:	0149db63          	bge	s3,s4,80004826 <filewrite+0xf6>
      int n1 = n - i;
    80004814:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004818:	84be                	mv	s1,a5
    8000481a:	2781                	sext.w	a5,a5
    8000481c:	f8fb5ce3          	bge	s6,a5,800047b4 <filewrite+0x84>
    80004820:	84de                	mv	s1,s7
    80004822:	bf49                	j	800047b4 <filewrite+0x84>
    int i = 0;
    80004824:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004826:	013a1f63          	bne	s4,s3,80004844 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000482a:	8552                	mv	a0,s4
    8000482c:	60a6                	ld	ra,72(sp)
    8000482e:	6406                	ld	s0,64(sp)
    80004830:	74e2                	ld	s1,56(sp)
    80004832:	7942                	ld	s2,48(sp)
    80004834:	79a2                	ld	s3,40(sp)
    80004836:	7a02                	ld	s4,32(sp)
    80004838:	6ae2                	ld	s5,24(sp)
    8000483a:	6b42                	ld	s6,16(sp)
    8000483c:	6ba2                	ld	s7,8(sp)
    8000483e:	6c02                	ld	s8,0(sp)
    80004840:	6161                	addi	sp,sp,80
    80004842:	8082                	ret
    ret = (i == n ? n : -1);
    80004844:	5a7d                	li	s4,-1
    80004846:	b7d5                	j	8000482a <filewrite+0xfa>
    panic("filewrite");
    80004848:	00004517          	auipc	a0,0x4
    8000484c:	e6850513          	addi	a0,a0,-408 # 800086b0 <syscalls+0x268>
    80004850:	ffffc097          	auipc	ra,0xffffc
    80004854:	cee080e7          	jalr	-786(ra) # 8000053e <panic>
    return -1;
    80004858:	5a7d                	li	s4,-1
    8000485a:	bfc1                	j	8000482a <filewrite+0xfa>
      return -1;
    8000485c:	5a7d                	li	s4,-1
    8000485e:	b7f1                	j	8000482a <filewrite+0xfa>
    80004860:	5a7d                	li	s4,-1
    80004862:	b7e1                	j	8000482a <filewrite+0xfa>

0000000080004864 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004864:	7179                	addi	sp,sp,-48
    80004866:	f406                	sd	ra,40(sp)
    80004868:	f022                	sd	s0,32(sp)
    8000486a:	ec26                	sd	s1,24(sp)
    8000486c:	e84a                	sd	s2,16(sp)
    8000486e:	e44e                	sd	s3,8(sp)
    80004870:	e052                	sd	s4,0(sp)
    80004872:	1800                	addi	s0,sp,48
    80004874:	84aa                	mv	s1,a0
    80004876:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004878:	0005b023          	sd	zero,0(a1)
    8000487c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004880:	00000097          	auipc	ra,0x0
    80004884:	bf8080e7          	jalr	-1032(ra) # 80004478 <filealloc>
    80004888:	e088                	sd	a0,0(s1)
    8000488a:	c551                	beqz	a0,80004916 <pipealloc+0xb2>
    8000488c:	00000097          	auipc	ra,0x0
    80004890:	bec080e7          	jalr	-1044(ra) # 80004478 <filealloc>
    80004894:	00aa3023          	sd	a0,0(s4)
    80004898:	c92d                	beqz	a0,8000490a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000489a:	ffffc097          	auipc	ra,0xffffc
    8000489e:	25a080e7          	jalr	602(ra) # 80000af4 <kalloc>
    800048a2:	892a                	mv	s2,a0
    800048a4:	c125                	beqz	a0,80004904 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048a6:	4985                	li	s3,1
    800048a8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048ac:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048b0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048b4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048b8:	00004597          	auipc	a1,0x4
    800048bc:	e0858593          	addi	a1,a1,-504 # 800086c0 <syscalls+0x278>
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	294080e7          	jalr	660(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800048c8:	609c                	ld	a5,0(s1)
    800048ca:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800048ce:	609c                	ld	a5,0(s1)
    800048d0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800048d4:	609c                	ld	a5,0(s1)
    800048d6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800048da:	609c                	ld	a5,0(s1)
    800048dc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800048e0:	000a3783          	ld	a5,0(s4)
    800048e4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048e8:	000a3783          	ld	a5,0(s4)
    800048ec:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800048f0:	000a3783          	ld	a5,0(s4)
    800048f4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800048f8:	000a3783          	ld	a5,0(s4)
    800048fc:	0127b823          	sd	s2,16(a5)
  return 0;
    80004900:	4501                	li	a0,0
    80004902:	a025                	j	8000492a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004904:	6088                	ld	a0,0(s1)
    80004906:	e501                	bnez	a0,8000490e <pipealloc+0xaa>
    80004908:	a039                	j	80004916 <pipealloc+0xb2>
    8000490a:	6088                	ld	a0,0(s1)
    8000490c:	c51d                	beqz	a0,8000493a <pipealloc+0xd6>
    fileclose(*f0);
    8000490e:	00000097          	auipc	ra,0x0
    80004912:	c26080e7          	jalr	-986(ra) # 80004534 <fileclose>
  if(*f1)
    80004916:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000491a:	557d                	li	a0,-1
  if(*f1)
    8000491c:	c799                	beqz	a5,8000492a <pipealloc+0xc6>
    fileclose(*f1);
    8000491e:	853e                	mv	a0,a5
    80004920:	00000097          	auipc	ra,0x0
    80004924:	c14080e7          	jalr	-1004(ra) # 80004534 <fileclose>
  return -1;
    80004928:	557d                	li	a0,-1
}
    8000492a:	70a2                	ld	ra,40(sp)
    8000492c:	7402                	ld	s0,32(sp)
    8000492e:	64e2                	ld	s1,24(sp)
    80004930:	6942                	ld	s2,16(sp)
    80004932:	69a2                	ld	s3,8(sp)
    80004934:	6a02                	ld	s4,0(sp)
    80004936:	6145                	addi	sp,sp,48
    80004938:	8082                	ret
  return -1;
    8000493a:	557d                	li	a0,-1
    8000493c:	b7fd                	j	8000492a <pipealloc+0xc6>

000000008000493e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000493e:	1101                	addi	sp,sp,-32
    80004940:	ec06                	sd	ra,24(sp)
    80004942:	e822                	sd	s0,16(sp)
    80004944:	e426                	sd	s1,8(sp)
    80004946:	e04a                	sd	s2,0(sp)
    80004948:	1000                	addi	s0,sp,32
    8000494a:	84aa                	mv	s1,a0
    8000494c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000494e:	ffffc097          	auipc	ra,0xffffc
    80004952:	296080e7          	jalr	662(ra) # 80000be4 <acquire>
  if(writable){
    80004956:	02090d63          	beqz	s2,80004990 <pipeclose+0x52>
    pi->writeopen = 0;
    8000495a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000495e:	21848513          	addi	a0,s1,536
    80004962:	ffffe097          	auipc	ra,0xffffe
    80004966:	896080e7          	jalr	-1898(ra) # 800021f8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000496a:	2204b783          	ld	a5,544(s1)
    8000496e:	eb95                	bnez	a5,800049a2 <pipeclose+0x64>
    release(&pi->lock);
    80004970:	8526                	mv	a0,s1
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	326080e7          	jalr	806(ra) # 80000c98 <release>
    kfree((char*)pi);
    8000497a:	8526                	mv	a0,s1
    8000497c:	ffffc097          	auipc	ra,0xffffc
    80004980:	07c080e7          	jalr	124(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004984:	60e2                	ld	ra,24(sp)
    80004986:	6442                	ld	s0,16(sp)
    80004988:	64a2                	ld	s1,8(sp)
    8000498a:	6902                	ld	s2,0(sp)
    8000498c:	6105                	addi	sp,sp,32
    8000498e:	8082                	ret
    pi->readopen = 0;
    80004990:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004994:	21c48513          	addi	a0,s1,540
    80004998:	ffffe097          	auipc	ra,0xffffe
    8000499c:	860080e7          	jalr	-1952(ra) # 800021f8 <wakeup>
    800049a0:	b7e9                	j	8000496a <pipeclose+0x2c>
    release(&pi->lock);
    800049a2:	8526                	mv	a0,s1
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	2f4080e7          	jalr	756(ra) # 80000c98 <release>
}
    800049ac:	bfe1                	j	80004984 <pipeclose+0x46>

00000000800049ae <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049ae:	7159                	addi	sp,sp,-112
    800049b0:	f486                	sd	ra,104(sp)
    800049b2:	f0a2                	sd	s0,96(sp)
    800049b4:	eca6                	sd	s1,88(sp)
    800049b6:	e8ca                	sd	s2,80(sp)
    800049b8:	e4ce                	sd	s3,72(sp)
    800049ba:	e0d2                	sd	s4,64(sp)
    800049bc:	fc56                	sd	s5,56(sp)
    800049be:	f85a                	sd	s6,48(sp)
    800049c0:	f45e                	sd	s7,40(sp)
    800049c2:	f062                	sd	s8,32(sp)
    800049c4:	ec66                	sd	s9,24(sp)
    800049c6:	1880                	addi	s0,sp,112
    800049c8:	84aa                	mv	s1,a0
    800049ca:	8aae                	mv	s5,a1
    800049cc:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800049ce:	ffffd097          	auipc	ra,0xffffd
    800049d2:	fe2080e7          	jalr	-30(ra) # 800019b0 <myproc>
    800049d6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800049d8:	8526                	mv	a0,s1
    800049da:	ffffc097          	auipc	ra,0xffffc
    800049de:	20a080e7          	jalr	522(ra) # 80000be4 <acquire>
  while(i < n){
    800049e2:	0d405163          	blez	s4,80004aa4 <pipewrite+0xf6>
    800049e6:	8ba6                	mv	s7,s1
  int i = 0;
    800049e8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049ea:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049ec:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049f0:	21c48c13          	addi	s8,s1,540
    800049f4:	a08d                	j	80004a56 <pipewrite+0xa8>
      release(&pi->lock);
    800049f6:	8526                	mv	a0,s1
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>
      return -1;
    80004a00:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a02:	854a                	mv	a0,s2
    80004a04:	70a6                	ld	ra,104(sp)
    80004a06:	7406                	ld	s0,96(sp)
    80004a08:	64e6                	ld	s1,88(sp)
    80004a0a:	6946                	ld	s2,80(sp)
    80004a0c:	69a6                	ld	s3,72(sp)
    80004a0e:	6a06                	ld	s4,64(sp)
    80004a10:	7ae2                	ld	s5,56(sp)
    80004a12:	7b42                	ld	s6,48(sp)
    80004a14:	7ba2                	ld	s7,40(sp)
    80004a16:	7c02                	ld	s8,32(sp)
    80004a18:	6ce2                	ld	s9,24(sp)
    80004a1a:	6165                	addi	sp,sp,112
    80004a1c:	8082                	ret
      wakeup(&pi->nread);
    80004a1e:	8566                	mv	a0,s9
    80004a20:	ffffd097          	auipc	ra,0xffffd
    80004a24:	7d8080e7          	jalr	2008(ra) # 800021f8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a28:	85de                	mv	a1,s7
    80004a2a:	8562                	mv	a0,s8
    80004a2c:	ffffd097          	auipc	ra,0xffffd
    80004a30:	640080e7          	jalr	1600(ra) # 8000206c <sleep>
    80004a34:	a839                	j	80004a52 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a36:	21c4a783          	lw	a5,540(s1)
    80004a3a:	0017871b          	addiw	a4,a5,1
    80004a3e:	20e4ae23          	sw	a4,540(s1)
    80004a42:	1ff7f793          	andi	a5,a5,511
    80004a46:	97a6                	add	a5,a5,s1
    80004a48:	f9f44703          	lbu	a4,-97(s0)
    80004a4c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a50:	2905                	addiw	s2,s2,1
  while(i < n){
    80004a52:	03495d63          	bge	s2,s4,80004a8c <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004a56:	2204a783          	lw	a5,544(s1)
    80004a5a:	dfd1                	beqz	a5,800049f6 <pipewrite+0x48>
    80004a5c:	0289a783          	lw	a5,40(s3)
    80004a60:	fbd9                	bnez	a5,800049f6 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a62:	2184a783          	lw	a5,536(s1)
    80004a66:	21c4a703          	lw	a4,540(s1)
    80004a6a:	2007879b          	addiw	a5,a5,512
    80004a6e:	faf708e3          	beq	a4,a5,80004a1e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a72:	4685                	li	a3,1
    80004a74:	01590633          	add	a2,s2,s5
    80004a78:	f9f40593          	addi	a1,s0,-97
    80004a7c:	0509b503          	ld	a0,80(s3)
    80004a80:	ffffd097          	auipc	ra,0xffffd
    80004a84:	c7e080e7          	jalr	-898(ra) # 800016fe <copyin>
    80004a88:	fb6517e3          	bne	a0,s6,80004a36 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004a8c:	21848513          	addi	a0,s1,536
    80004a90:	ffffd097          	auipc	ra,0xffffd
    80004a94:	768080e7          	jalr	1896(ra) # 800021f8 <wakeup>
  release(&pi->lock);
    80004a98:	8526                	mv	a0,s1
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	1fe080e7          	jalr	510(ra) # 80000c98 <release>
  return i;
    80004aa2:	b785                	j	80004a02 <pipewrite+0x54>
  int i = 0;
    80004aa4:	4901                	li	s2,0
    80004aa6:	b7dd                	j	80004a8c <pipewrite+0xde>

0000000080004aa8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004aa8:	715d                	addi	sp,sp,-80
    80004aaa:	e486                	sd	ra,72(sp)
    80004aac:	e0a2                	sd	s0,64(sp)
    80004aae:	fc26                	sd	s1,56(sp)
    80004ab0:	f84a                	sd	s2,48(sp)
    80004ab2:	f44e                	sd	s3,40(sp)
    80004ab4:	f052                	sd	s4,32(sp)
    80004ab6:	ec56                	sd	s5,24(sp)
    80004ab8:	e85a                	sd	s6,16(sp)
    80004aba:	0880                	addi	s0,sp,80
    80004abc:	84aa                	mv	s1,a0
    80004abe:	892e                	mv	s2,a1
    80004ac0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ac2:	ffffd097          	auipc	ra,0xffffd
    80004ac6:	eee080e7          	jalr	-274(ra) # 800019b0 <myproc>
    80004aca:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004acc:	8b26                	mv	s6,s1
    80004ace:	8526                	mv	a0,s1
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	114080e7          	jalr	276(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ad8:	2184a703          	lw	a4,536(s1)
    80004adc:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ae0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ae4:	02f71463          	bne	a4,a5,80004b0c <piperead+0x64>
    80004ae8:	2244a783          	lw	a5,548(s1)
    80004aec:	c385                	beqz	a5,80004b0c <piperead+0x64>
    if(pr->killed){
    80004aee:	028a2783          	lw	a5,40(s4)
    80004af2:	ebc1                	bnez	a5,80004b82 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004af4:	85da                	mv	a1,s6
    80004af6:	854e                	mv	a0,s3
    80004af8:	ffffd097          	auipc	ra,0xffffd
    80004afc:	574080e7          	jalr	1396(ra) # 8000206c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b00:	2184a703          	lw	a4,536(s1)
    80004b04:	21c4a783          	lw	a5,540(s1)
    80004b08:	fef700e3          	beq	a4,a5,80004ae8 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b0c:	09505263          	blez	s5,80004b90 <piperead+0xe8>
    80004b10:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b12:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004b14:	2184a783          	lw	a5,536(s1)
    80004b18:	21c4a703          	lw	a4,540(s1)
    80004b1c:	02f70d63          	beq	a4,a5,80004b56 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b20:	0017871b          	addiw	a4,a5,1
    80004b24:	20e4ac23          	sw	a4,536(s1)
    80004b28:	1ff7f793          	andi	a5,a5,511
    80004b2c:	97a6                	add	a5,a5,s1
    80004b2e:	0187c783          	lbu	a5,24(a5)
    80004b32:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b36:	4685                	li	a3,1
    80004b38:	fbf40613          	addi	a2,s0,-65
    80004b3c:	85ca                	mv	a1,s2
    80004b3e:	050a3503          	ld	a0,80(s4)
    80004b42:	ffffd097          	auipc	ra,0xffffd
    80004b46:	b30080e7          	jalr	-1232(ra) # 80001672 <copyout>
    80004b4a:	01650663          	beq	a0,s6,80004b56 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b4e:	2985                	addiw	s3,s3,1
    80004b50:	0905                	addi	s2,s2,1
    80004b52:	fd3a91e3          	bne	s5,s3,80004b14 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b56:	21c48513          	addi	a0,s1,540
    80004b5a:	ffffd097          	auipc	ra,0xffffd
    80004b5e:	69e080e7          	jalr	1694(ra) # 800021f8 <wakeup>
  release(&pi->lock);
    80004b62:	8526                	mv	a0,s1
    80004b64:	ffffc097          	auipc	ra,0xffffc
    80004b68:	134080e7          	jalr	308(ra) # 80000c98 <release>
  return i;
}
    80004b6c:	854e                	mv	a0,s3
    80004b6e:	60a6                	ld	ra,72(sp)
    80004b70:	6406                	ld	s0,64(sp)
    80004b72:	74e2                	ld	s1,56(sp)
    80004b74:	7942                	ld	s2,48(sp)
    80004b76:	79a2                	ld	s3,40(sp)
    80004b78:	7a02                	ld	s4,32(sp)
    80004b7a:	6ae2                	ld	s5,24(sp)
    80004b7c:	6b42                	ld	s6,16(sp)
    80004b7e:	6161                	addi	sp,sp,80
    80004b80:	8082                	ret
      release(&pi->lock);
    80004b82:	8526                	mv	a0,s1
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	114080e7          	jalr	276(ra) # 80000c98 <release>
      return -1;
    80004b8c:	59fd                	li	s3,-1
    80004b8e:	bff9                	j	80004b6c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b90:	4981                	li	s3,0
    80004b92:	b7d1                	j	80004b56 <piperead+0xae>

0000000080004b94 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004b94:	df010113          	addi	sp,sp,-528
    80004b98:	20113423          	sd	ra,520(sp)
    80004b9c:	20813023          	sd	s0,512(sp)
    80004ba0:	ffa6                	sd	s1,504(sp)
    80004ba2:	fbca                	sd	s2,496(sp)
    80004ba4:	f7ce                	sd	s3,488(sp)
    80004ba6:	f3d2                	sd	s4,480(sp)
    80004ba8:	efd6                	sd	s5,472(sp)
    80004baa:	ebda                	sd	s6,464(sp)
    80004bac:	e7de                	sd	s7,456(sp)
    80004bae:	e3e2                	sd	s8,448(sp)
    80004bb0:	ff66                	sd	s9,440(sp)
    80004bb2:	fb6a                	sd	s10,432(sp)
    80004bb4:	f76e                	sd	s11,424(sp)
    80004bb6:	0c00                	addi	s0,sp,528
    80004bb8:	84aa                	mv	s1,a0
    80004bba:	dea43c23          	sd	a0,-520(s0)
    80004bbe:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004bc2:	ffffd097          	auipc	ra,0xffffd
    80004bc6:	dee080e7          	jalr	-530(ra) # 800019b0 <myproc>
    80004bca:	892a                	mv	s2,a0

  begin_op();
    80004bcc:	fffff097          	auipc	ra,0xfffff
    80004bd0:	49c080e7          	jalr	1180(ra) # 80004068 <begin_op>

  if((ip = namei(path)) == 0){
    80004bd4:	8526                	mv	a0,s1
    80004bd6:	fffff097          	auipc	ra,0xfffff
    80004bda:	276080e7          	jalr	630(ra) # 80003e4c <namei>
    80004bde:	c92d                	beqz	a0,80004c50 <exec+0xbc>
    80004be0:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004be2:	fffff097          	auipc	ra,0xfffff
    80004be6:	ab2080e7          	jalr	-1358(ra) # 80003694 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004bea:	04000713          	li	a4,64
    80004bee:	4681                	li	a3,0
    80004bf0:	e5040613          	addi	a2,s0,-432
    80004bf4:	4581                	li	a1,0
    80004bf6:	8526                	mv	a0,s1
    80004bf8:	fffff097          	auipc	ra,0xfffff
    80004bfc:	d50080e7          	jalr	-688(ra) # 80003948 <readi>
    80004c00:	04000793          	li	a5,64
    80004c04:	00f51a63          	bne	a0,a5,80004c18 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c08:	e5042703          	lw	a4,-432(s0)
    80004c0c:	464c47b7          	lui	a5,0x464c4
    80004c10:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c14:	04f70463          	beq	a4,a5,80004c5c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c18:	8526                	mv	a0,s1
    80004c1a:	fffff097          	auipc	ra,0xfffff
    80004c1e:	cdc080e7          	jalr	-804(ra) # 800038f6 <iunlockput>
    end_op();
    80004c22:	fffff097          	auipc	ra,0xfffff
    80004c26:	4c6080e7          	jalr	1222(ra) # 800040e8 <end_op>
  }
  return -1;
    80004c2a:	557d                	li	a0,-1
}
    80004c2c:	20813083          	ld	ra,520(sp)
    80004c30:	20013403          	ld	s0,512(sp)
    80004c34:	74fe                	ld	s1,504(sp)
    80004c36:	795e                	ld	s2,496(sp)
    80004c38:	79be                	ld	s3,488(sp)
    80004c3a:	7a1e                	ld	s4,480(sp)
    80004c3c:	6afe                	ld	s5,472(sp)
    80004c3e:	6b5e                	ld	s6,464(sp)
    80004c40:	6bbe                	ld	s7,456(sp)
    80004c42:	6c1e                	ld	s8,448(sp)
    80004c44:	7cfa                	ld	s9,440(sp)
    80004c46:	7d5a                	ld	s10,432(sp)
    80004c48:	7dba                	ld	s11,424(sp)
    80004c4a:	21010113          	addi	sp,sp,528
    80004c4e:	8082                	ret
    end_op();
    80004c50:	fffff097          	auipc	ra,0xfffff
    80004c54:	498080e7          	jalr	1176(ra) # 800040e8 <end_op>
    return -1;
    80004c58:	557d                	li	a0,-1
    80004c5a:	bfc9                	j	80004c2c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c5c:	854a                	mv	a0,s2
    80004c5e:	ffffd097          	auipc	ra,0xffffd
    80004c62:	e16080e7          	jalr	-490(ra) # 80001a74 <proc_pagetable>
    80004c66:	8baa                	mv	s7,a0
    80004c68:	d945                	beqz	a0,80004c18 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c6a:	e7042983          	lw	s3,-400(s0)
    80004c6e:	e8845783          	lhu	a5,-376(s0)
    80004c72:	c7ad                	beqz	a5,80004cdc <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c74:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c76:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004c78:	6c85                	lui	s9,0x1
    80004c7a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004c7e:	def43823          	sd	a5,-528(s0)
    80004c82:	a42d                	j	80004eac <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004c84:	00004517          	auipc	a0,0x4
    80004c88:	a4450513          	addi	a0,a0,-1468 # 800086c8 <syscalls+0x280>
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	8b2080e7          	jalr	-1870(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c94:	8756                	mv	a4,s5
    80004c96:	012d86bb          	addw	a3,s11,s2
    80004c9a:	4581                	li	a1,0
    80004c9c:	8526                	mv	a0,s1
    80004c9e:	fffff097          	auipc	ra,0xfffff
    80004ca2:	caa080e7          	jalr	-854(ra) # 80003948 <readi>
    80004ca6:	2501                	sext.w	a0,a0
    80004ca8:	1aaa9963          	bne	s5,a0,80004e5a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004cac:	6785                	lui	a5,0x1
    80004cae:	0127893b          	addw	s2,a5,s2
    80004cb2:	77fd                	lui	a5,0xfffff
    80004cb4:	01478a3b          	addw	s4,a5,s4
    80004cb8:	1f897163          	bgeu	s2,s8,80004e9a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004cbc:	02091593          	slli	a1,s2,0x20
    80004cc0:	9181                	srli	a1,a1,0x20
    80004cc2:	95ea                	add	a1,a1,s10
    80004cc4:	855e                	mv	a0,s7
    80004cc6:	ffffc097          	auipc	ra,0xffffc
    80004cca:	3a8080e7          	jalr	936(ra) # 8000106e <walkaddr>
    80004cce:	862a                	mv	a2,a0
    if(pa == 0)
    80004cd0:	d955                	beqz	a0,80004c84 <exec+0xf0>
      n = PGSIZE;
    80004cd2:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004cd4:	fd9a70e3          	bgeu	s4,s9,80004c94 <exec+0x100>
      n = sz - i;
    80004cd8:	8ad2                	mv	s5,s4
    80004cda:	bf6d                	j	80004c94 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cdc:	4901                	li	s2,0
  iunlockput(ip);
    80004cde:	8526                	mv	a0,s1
    80004ce0:	fffff097          	auipc	ra,0xfffff
    80004ce4:	c16080e7          	jalr	-1002(ra) # 800038f6 <iunlockput>
  end_op();
    80004ce8:	fffff097          	auipc	ra,0xfffff
    80004cec:	400080e7          	jalr	1024(ra) # 800040e8 <end_op>
  p = myproc();
    80004cf0:	ffffd097          	auipc	ra,0xffffd
    80004cf4:	cc0080e7          	jalr	-832(ra) # 800019b0 <myproc>
    80004cf8:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004cfa:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004cfe:	6785                	lui	a5,0x1
    80004d00:	17fd                	addi	a5,a5,-1
    80004d02:	993e                	add	s2,s2,a5
    80004d04:	757d                	lui	a0,0xfffff
    80004d06:	00a977b3          	and	a5,s2,a0
    80004d0a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d0e:	6609                	lui	a2,0x2
    80004d10:	963e                	add	a2,a2,a5
    80004d12:	85be                	mv	a1,a5
    80004d14:	855e                	mv	a0,s7
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	70c080e7          	jalr	1804(ra) # 80001422 <uvmalloc>
    80004d1e:	8b2a                	mv	s6,a0
  ip = 0;
    80004d20:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d22:	12050c63          	beqz	a0,80004e5a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d26:	75f9                	lui	a1,0xffffe
    80004d28:	95aa                	add	a1,a1,a0
    80004d2a:	855e                	mv	a0,s7
    80004d2c:	ffffd097          	auipc	ra,0xffffd
    80004d30:	914080e7          	jalr	-1772(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d34:	7c7d                	lui	s8,0xfffff
    80004d36:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d38:	e0043783          	ld	a5,-512(s0)
    80004d3c:	6388                	ld	a0,0(a5)
    80004d3e:	c535                	beqz	a0,80004daa <exec+0x216>
    80004d40:	e9040993          	addi	s3,s0,-368
    80004d44:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004d48:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004d4a:	ffffc097          	auipc	ra,0xffffc
    80004d4e:	11a080e7          	jalr	282(ra) # 80000e64 <strlen>
    80004d52:	2505                	addiw	a0,a0,1
    80004d54:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d58:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004d5c:	13896363          	bltu	s2,s8,80004e82 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d60:	e0043d83          	ld	s11,-512(s0)
    80004d64:	000dba03          	ld	s4,0(s11)
    80004d68:	8552                	mv	a0,s4
    80004d6a:	ffffc097          	auipc	ra,0xffffc
    80004d6e:	0fa080e7          	jalr	250(ra) # 80000e64 <strlen>
    80004d72:	0015069b          	addiw	a3,a0,1
    80004d76:	8652                	mv	a2,s4
    80004d78:	85ca                	mv	a1,s2
    80004d7a:	855e                	mv	a0,s7
    80004d7c:	ffffd097          	auipc	ra,0xffffd
    80004d80:	8f6080e7          	jalr	-1802(ra) # 80001672 <copyout>
    80004d84:	10054363          	bltz	a0,80004e8a <exec+0x2f6>
    ustack[argc] = sp;
    80004d88:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d8c:	0485                	addi	s1,s1,1
    80004d8e:	008d8793          	addi	a5,s11,8
    80004d92:	e0f43023          	sd	a5,-512(s0)
    80004d96:	008db503          	ld	a0,8(s11)
    80004d9a:	c911                	beqz	a0,80004dae <exec+0x21a>
    if(argc >= MAXARG)
    80004d9c:	09a1                	addi	s3,s3,8
    80004d9e:	fb3c96e3          	bne	s9,s3,80004d4a <exec+0x1b6>
  sz = sz1;
    80004da2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004da6:	4481                	li	s1,0
    80004da8:	a84d                	j	80004e5a <exec+0x2c6>
  sp = sz;
    80004daa:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004dac:	4481                	li	s1,0
  ustack[argc] = 0;
    80004dae:	00349793          	slli	a5,s1,0x3
    80004db2:	f9040713          	addi	a4,s0,-112
    80004db6:	97ba                	add	a5,a5,a4
    80004db8:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004dbc:	00148693          	addi	a3,s1,1
    80004dc0:	068e                	slli	a3,a3,0x3
    80004dc2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004dc6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004dca:	01897663          	bgeu	s2,s8,80004dd6 <exec+0x242>
  sz = sz1;
    80004dce:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004dd2:	4481                	li	s1,0
    80004dd4:	a059                	j	80004e5a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004dd6:	e9040613          	addi	a2,s0,-368
    80004dda:	85ca                	mv	a1,s2
    80004ddc:	855e                	mv	a0,s7
    80004dde:	ffffd097          	auipc	ra,0xffffd
    80004de2:	894080e7          	jalr	-1900(ra) # 80001672 <copyout>
    80004de6:	0a054663          	bltz	a0,80004e92 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004dea:	058ab783          	ld	a5,88(s5)
    80004dee:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004df2:	df843783          	ld	a5,-520(s0)
    80004df6:	0007c703          	lbu	a4,0(a5)
    80004dfa:	cf11                	beqz	a4,80004e16 <exec+0x282>
    80004dfc:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004dfe:	02f00693          	li	a3,47
    80004e02:	a039                	j	80004e10 <exec+0x27c>
      last = s+1;
    80004e04:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004e08:	0785                	addi	a5,a5,1
    80004e0a:	fff7c703          	lbu	a4,-1(a5)
    80004e0e:	c701                	beqz	a4,80004e16 <exec+0x282>
    if(*s == '/')
    80004e10:	fed71ce3          	bne	a4,a3,80004e08 <exec+0x274>
    80004e14:	bfc5                	j	80004e04 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e16:	4641                	li	a2,16
    80004e18:	df843583          	ld	a1,-520(s0)
    80004e1c:	158a8513          	addi	a0,s5,344
    80004e20:	ffffc097          	auipc	ra,0xffffc
    80004e24:	012080e7          	jalr	18(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e28:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004e2c:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004e30:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e34:	058ab783          	ld	a5,88(s5)
    80004e38:	e6843703          	ld	a4,-408(s0)
    80004e3c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e3e:	058ab783          	ld	a5,88(s5)
    80004e42:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e46:	85ea                	mv	a1,s10
    80004e48:	ffffd097          	auipc	ra,0xffffd
    80004e4c:	cc8080e7          	jalr	-824(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e50:	0004851b          	sext.w	a0,s1
    80004e54:	bbe1                	j	80004c2c <exec+0x98>
    80004e56:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004e5a:	e0843583          	ld	a1,-504(s0)
    80004e5e:	855e                	mv	a0,s7
    80004e60:	ffffd097          	auipc	ra,0xffffd
    80004e64:	cb0080e7          	jalr	-848(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80004e68:	da0498e3          	bnez	s1,80004c18 <exec+0x84>
  return -1;
    80004e6c:	557d                	li	a0,-1
    80004e6e:	bb7d                	j	80004c2c <exec+0x98>
    80004e70:	e1243423          	sd	s2,-504(s0)
    80004e74:	b7dd                	j	80004e5a <exec+0x2c6>
    80004e76:	e1243423          	sd	s2,-504(s0)
    80004e7a:	b7c5                	j	80004e5a <exec+0x2c6>
    80004e7c:	e1243423          	sd	s2,-504(s0)
    80004e80:	bfe9                	j	80004e5a <exec+0x2c6>
  sz = sz1;
    80004e82:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e86:	4481                	li	s1,0
    80004e88:	bfc9                	j	80004e5a <exec+0x2c6>
  sz = sz1;
    80004e8a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e8e:	4481                	li	s1,0
    80004e90:	b7e9                	j	80004e5a <exec+0x2c6>
  sz = sz1;
    80004e92:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e96:	4481                	li	s1,0
    80004e98:	b7c9                	j	80004e5a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e9a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e9e:	2b05                	addiw	s6,s6,1
    80004ea0:	0389899b          	addiw	s3,s3,56
    80004ea4:	e8845783          	lhu	a5,-376(s0)
    80004ea8:	e2fb5be3          	bge	s6,a5,80004cde <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004eac:	2981                	sext.w	s3,s3
    80004eae:	03800713          	li	a4,56
    80004eb2:	86ce                	mv	a3,s3
    80004eb4:	e1840613          	addi	a2,s0,-488
    80004eb8:	4581                	li	a1,0
    80004eba:	8526                	mv	a0,s1
    80004ebc:	fffff097          	auipc	ra,0xfffff
    80004ec0:	a8c080e7          	jalr	-1396(ra) # 80003948 <readi>
    80004ec4:	03800793          	li	a5,56
    80004ec8:	f8f517e3          	bne	a0,a5,80004e56 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004ecc:	e1842783          	lw	a5,-488(s0)
    80004ed0:	4705                	li	a4,1
    80004ed2:	fce796e3          	bne	a5,a4,80004e9e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004ed6:	e4043603          	ld	a2,-448(s0)
    80004eda:	e3843783          	ld	a5,-456(s0)
    80004ede:	f8f669e3          	bltu	a2,a5,80004e70 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004ee2:	e2843783          	ld	a5,-472(s0)
    80004ee6:	963e                	add	a2,a2,a5
    80004ee8:	f8f667e3          	bltu	a2,a5,80004e76 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004eec:	85ca                	mv	a1,s2
    80004eee:	855e                	mv	a0,s7
    80004ef0:	ffffc097          	auipc	ra,0xffffc
    80004ef4:	532080e7          	jalr	1330(ra) # 80001422 <uvmalloc>
    80004ef8:	e0a43423          	sd	a0,-504(s0)
    80004efc:	d141                	beqz	a0,80004e7c <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004efe:	e2843d03          	ld	s10,-472(s0)
    80004f02:	df043783          	ld	a5,-528(s0)
    80004f06:	00fd77b3          	and	a5,s10,a5
    80004f0a:	fba1                	bnez	a5,80004e5a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f0c:	e2042d83          	lw	s11,-480(s0)
    80004f10:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f14:	f80c03e3          	beqz	s8,80004e9a <exec+0x306>
    80004f18:	8a62                	mv	s4,s8
    80004f1a:	4901                	li	s2,0
    80004f1c:	b345                	j	80004cbc <exec+0x128>

0000000080004f1e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f1e:	7179                	addi	sp,sp,-48
    80004f20:	f406                	sd	ra,40(sp)
    80004f22:	f022                	sd	s0,32(sp)
    80004f24:	ec26                	sd	s1,24(sp)
    80004f26:	e84a                	sd	s2,16(sp)
    80004f28:	1800                	addi	s0,sp,48
    80004f2a:	892e                	mv	s2,a1
    80004f2c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f2e:	fdc40593          	addi	a1,s0,-36
    80004f32:	ffffe097          	auipc	ra,0xffffe
    80004f36:	b2a080e7          	jalr	-1238(ra) # 80002a5c <argint>
    80004f3a:	04054063          	bltz	a0,80004f7a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f3e:	fdc42703          	lw	a4,-36(s0)
    80004f42:	47bd                	li	a5,15
    80004f44:	02e7ed63          	bltu	a5,a4,80004f7e <argfd+0x60>
    80004f48:	ffffd097          	auipc	ra,0xffffd
    80004f4c:	a68080e7          	jalr	-1432(ra) # 800019b0 <myproc>
    80004f50:	fdc42703          	lw	a4,-36(s0)
    80004f54:	01a70793          	addi	a5,a4,26
    80004f58:	078e                	slli	a5,a5,0x3
    80004f5a:	953e                	add	a0,a0,a5
    80004f5c:	611c                	ld	a5,0(a0)
    80004f5e:	c395                	beqz	a5,80004f82 <argfd+0x64>
    return -1;
  if(pfd)
    80004f60:	00090463          	beqz	s2,80004f68 <argfd+0x4a>
    *pfd = fd;
    80004f64:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004f68:	4501                	li	a0,0
  if(pf)
    80004f6a:	c091                	beqz	s1,80004f6e <argfd+0x50>
    *pf = f;
    80004f6c:	e09c                	sd	a5,0(s1)
}
    80004f6e:	70a2                	ld	ra,40(sp)
    80004f70:	7402                	ld	s0,32(sp)
    80004f72:	64e2                	ld	s1,24(sp)
    80004f74:	6942                	ld	s2,16(sp)
    80004f76:	6145                	addi	sp,sp,48
    80004f78:	8082                	ret
    return -1;
    80004f7a:	557d                	li	a0,-1
    80004f7c:	bfcd                	j	80004f6e <argfd+0x50>
    return -1;
    80004f7e:	557d                	li	a0,-1
    80004f80:	b7fd                	j	80004f6e <argfd+0x50>
    80004f82:	557d                	li	a0,-1
    80004f84:	b7ed                	j	80004f6e <argfd+0x50>

0000000080004f86 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f86:	1101                	addi	sp,sp,-32
    80004f88:	ec06                	sd	ra,24(sp)
    80004f8a:	e822                	sd	s0,16(sp)
    80004f8c:	e426                	sd	s1,8(sp)
    80004f8e:	1000                	addi	s0,sp,32
    80004f90:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f92:	ffffd097          	auipc	ra,0xffffd
    80004f96:	a1e080e7          	jalr	-1506(ra) # 800019b0 <myproc>
    80004f9a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f9c:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80004fa0:	4501                	li	a0,0
    80004fa2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004fa4:	6398                	ld	a4,0(a5)
    80004fa6:	cb19                	beqz	a4,80004fbc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004fa8:	2505                	addiw	a0,a0,1
    80004faa:	07a1                	addi	a5,a5,8
    80004fac:	fed51ce3          	bne	a0,a3,80004fa4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004fb0:	557d                	li	a0,-1
}
    80004fb2:	60e2                	ld	ra,24(sp)
    80004fb4:	6442                	ld	s0,16(sp)
    80004fb6:	64a2                	ld	s1,8(sp)
    80004fb8:	6105                	addi	sp,sp,32
    80004fba:	8082                	ret
      p->ofile[fd] = f;
    80004fbc:	01a50793          	addi	a5,a0,26
    80004fc0:	078e                	slli	a5,a5,0x3
    80004fc2:	963e                	add	a2,a2,a5
    80004fc4:	e204                	sd	s1,0(a2)
      return fd;
    80004fc6:	b7f5                	j	80004fb2 <fdalloc+0x2c>

0000000080004fc8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004fc8:	715d                	addi	sp,sp,-80
    80004fca:	e486                	sd	ra,72(sp)
    80004fcc:	e0a2                	sd	s0,64(sp)
    80004fce:	fc26                	sd	s1,56(sp)
    80004fd0:	f84a                	sd	s2,48(sp)
    80004fd2:	f44e                	sd	s3,40(sp)
    80004fd4:	f052                	sd	s4,32(sp)
    80004fd6:	ec56                	sd	s5,24(sp)
    80004fd8:	0880                	addi	s0,sp,80
    80004fda:	89ae                	mv	s3,a1
    80004fdc:	8ab2                	mv	s5,a2
    80004fde:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004fe0:	fb040593          	addi	a1,s0,-80
    80004fe4:	fffff097          	auipc	ra,0xfffff
    80004fe8:	e86080e7          	jalr	-378(ra) # 80003e6a <nameiparent>
    80004fec:	892a                	mv	s2,a0
    80004fee:	12050f63          	beqz	a0,8000512c <create+0x164>
    return 0;

  ilock(dp);
    80004ff2:	ffffe097          	auipc	ra,0xffffe
    80004ff6:	6a2080e7          	jalr	1698(ra) # 80003694 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004ffa:	4601                	li	a2,0
    80004ffc:	fb040593          	addi	a1,s0,-80
    80005000:	854a                	mv	a0,s2
    80005002:	fffff097          	auipc	ra,0xfffff
    80005006:	b78080e7          	jalr	-1160(ra) # 80003b7a <dirlookup>
    8000500a:	84aa                	mv	s1,a0
    8000500c:	c921                	beqz	a0,8000505c <create+0x94>
    iunlockput(dp);
    8000500e:	854a                	mv	a0,s2
    80005010:	fffff097          	auipc	ra,0xfffff
    80005014:	8e6080e7          	jalr	-1818(ra) # 800038f6 <iunlockput>
    ilock(ip);
    80005018:	8526                	mv	a0,s1
    8000501a:	ffffe097          	auipc	ra,0xffffe
    8000501e:	67a080e7          	jalr	1658(ra) # 80003694 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005022:	2981                	sext.w	s3,s3
    80005024:	4789                	li	a5,2
    80005026:	02f99463          	bne	s3,a5,8000504e <create+0x86>
    8000502a:	0444d783          	lhu	a5,68(s1)
    8000502e:	37f9                	addiw	a5,a5,-2
    80005030:	17c2                	slli	a5,a5,0x30
    80005032:	93c1                	srli	a5,a5,0x30
    80005034:	4705                	li	a4,1
    80005036:	00f76c63          	bltu	a4,a5,8000504e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000503a:	8526                	mv	a0,s1
    8000503c:	60a6                	ld	ra,72(sp)
    8000503e:	6406                	ld	s0,64(sp)
    80005040:	74e2                	ld	s1,56(sp)
    80005042:	7942                	ld	s2,48(sp)
    80005044:	79a2                	ld	s3,40(sp)
    80005046:	7a02                	ld	s4,32(sp)
    80005048:	6ae2                	ld	s5,24(sp)
    8000504a:	6161                	addi	sp,sp,80
    8000504c:	8082                	ret
    iunlockput(ip);
    8000504e:	8526                	mv	a0,s1
    80005050:	fffff097          	auipc	ra,0xfffff
    80005054:	8a6080e7          	jalr	-1882(ra) # 800038f6 <iunlockput>
    return 0;
    80005058:	4481                	li	s1,0
    8000505a:	b7c5                	j	8000503a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000505c:	85ce                	mv	a1,s3
    8000505e:	00092503          	lw	a0,0(s2)
    80005062:	ffffe097          	auipc	ra,0xffffe
    80005066:	49a080e7          	jalr	1178(ra) # 800034fc <ialloc>
    8000506a:	84aa                	mv	s1,a0
    8000506c:	c529                	beqz	a0,800050b6 <create+0xee>
  ilock(ip);
    8000506e:	ffffe097          	auipc	ra,0xffffe
    80005072:	626080e7          	jalr	1574(ra) # 80003694 <ilock>
  ip->major = major;
    80005076:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000507a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000507e:	4785                	li	a5,1
    80005080:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005084:	8526                	mv	a0,s1
    80005086:	ffffe097          	auipc	ra,0xffffe
    8000508a:	544080e7          	jalr	1348(ra) # 800035ca <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000508e:	2981                	sext.w	s3,s3
    80005090:	4785                	li	a5,1
    80005092:	02f98a63          	beq	s3,a5,800050c6 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005096:	40d0                	lw	a2,4(s1)
    80005098:	fb040593          	addi	a1,s0,-80
    8000509c:	854a                	mv	a0,s2
    8000509e:	fffff097          	auipc	ra,0xfffff
    800050a2:	cec080e7          	jalr	-788(ra) # 80003d8a <dirlink>
    800050a6:	06054b63          	bltz	a0,8000511c <create+0x154>
  iunlockput(dp);
    800050aa:	854a                	mv	a0,s2
    800050ac:	fffff097          	auipc	ra,0xfffff
    800050b0:	84a080e7          	jalr	-1974(ra) # 800038f6 <iunlockput>
  return ip;
    800050b4:	b759                	j	8000503a <create+0x72>
    panic("create: ialloc");
    800050b6:	00003517          	auipc	a0,0x3
    800050ba:	63250513          	addi	a0,a0,1586 # 800086e8 <syscalls+0x2a0>
    800050be:	ffffb097          	auipc	ra,0xffffb
    800050c2:	480080e7          	jalr	1152(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800050c6:	04a95783          	lhu	a5,74(s2)
    800050ca:	2785                	addiw	a5,a5,1
    800050cc:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800050d0:	854a                	mv	a0,s2
    800050d2:	ffffe097          	auipc	ra,0xffffe
    800050d6:	4f8080e7          	jalr	1272(ra) # 800035ca <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800050da:	40d0                	lw	a2,4(s1)
    800050dc:	00003597          	auipc	a1,0x3
    800050e0:	61c58593          	addi	a1,a1,1564 # 800086f8 <syscalls+0x2b0>
    800050e4:	8526                	mv	a0,s1
    800050e6:	fffff097          	auipc	ra,0xfffff
    800050ea:	ca4080e7          	jalr	-860(ra) # 80003d8a <dirlink>
    800050ee:	00054f63          	bltz	a0,8000510c <create+0x144>
    800050f2:	00492603          	lw	a2,4(s2)
    800050f6:	00003597          	auipc	a1,0x3
    800050fa:	60a58593          	addi	a1,a1,1546 # 80008700 <syscalls+0x2b8>
    800050fe:	8526                	mv	a0,s1
    80005100:	fffff097          	auipc	ra,0xfffff
    80005104:	c8a080e7          	jalr	-886(ra) # 80003d8a <dirlink>
    80005108:	f80557e3          	bgez	a0,80005096 <create+0xce>
      panic("create dots");
    8000510c:	00003517          	auipc	a0,0x3
    80005110:	5fc50513          	addi	a0,a0,1532 # 80008708 <syscalls+0x2c0>
    80005114:	ffffb097          	auipc	ra,0xffffb
    80005118:	42a080e7          	jalr	1066(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000511c:	00003517          	auipc	a0,0x3
    80005120:	5fc50513          	addi	a0,a0,1532 # 80008718 <syscalls+0x2d0>
    80005124:	ffffb097          	auipc	ra,0xffffb
    80005128:	41a080e7          	jalr	1050(ra) # 8000053e <panic>
    return 0;
    8000512c:	84aa                	mv	s1,a0
    8000512e:	b731                	j	8000503a <create+0x72>

0000000080005130 <sys_dup>:
{
    80005130:	7179                	addi	sp,sp,-48
    80005132:	f406                	sd	ra,40(sp)
    80005134:	f022                	sd	s0,32(sp)
    80005136:	ec26                	sd	s1,24(sp)
    80005138:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000513a:	fd840613          	addi	a2,s0,-40
    8000513e:	4581                	li	a1,0
    80005140:	4501                	li	a0,0
    80005142:	00000097          	auipc	ra,0x0
    80005146:	ddc080e7          	jalr	-548(ra) # 80004f1e <argfd>
    return -1;
    8000514a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000514c:	02054363          	bltz	a0,80005172 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005150:	fd843503          	ld	a0,-40(s0)
    80005154:	00000097          	auipc	ra,0x0
    80005158:	e32080e7          	jalr	-462(ra) # 80004f86 <fdalloc>
    8000515c:	84aa                	mv	s1,a0
    return -1;
    8000515e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005160:	00054963          	bltz	a0,80005172 <sys_dup+0x42>
  filedup(f);
    80005164:	fd843503          	ld	a0,-40(s0)
    80005168:	fffff097          	auipc	ra,0xfffff
    8000516c:	37a080e7          	jalr	890(ra) # 800044e2 <filedup>
  return fd;
    80005170:	87a6                	mv	a5,s1
}
    80005172:	853e                	mv	a0,a5
    80005174:	70a2                	ld	ra,40(sp)
    80005176:	7402                	ld	s0,32(sp)
    80005178:	64e2                	ld	s1,24(sp)
    8000517a:	6145                	addi	sp,sp,48
    8000517c:	8082                	ret

000000008000517e <sys_read>:
{
    8000517e:	7179                	addi	sp,sp,-48
    80005180:	f406                	sd	ra,40(sp)
    80005182:	f022                	sd	s0,32(sp)
    80005184:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005186:	fe840613          	addi	a2,s0,-24
    8000518a:	4581                	li	a1,0
    8000518c:	4501                	li	a0,0
    8000518e:	00000097          	auipc	ra,0x0
    80005192:	d90080e7          	jalr	-624(ra) # 80004f1e <argfd>
    return -1;
    80005196:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005198:	04054163          	bltz	a0,800051da <sys_read+0x5c>
    8000519c:	fe440593          	addi	a1,s0,-28
    800051a0:	4509                	li	a0,2
    800051a2:	ffffe097          	auipc	ra,0xffffe
    800051a6:	8ba080e7          	jalr	-1862(ra) # 80002a5c <argint>
    return -1;
    800051aa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051ac:	02054763          	bltz	a0,800051da <sys_read+0x5c>
    800051b0:	fd840593          	addi	a1,s0,-40
    800051b4:	4505                	li	a0,1
    800051b6:	ffffe097          	auipc	ra,0xffffe
    800051ba:	8c8080e7          	jalr	-1848(ra) # 80002a7e <argaddr>
    return -1;
    800051be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051c0:	00054d63          	bltz	a0,800051da <sys_read+0x5c>
  return fileread(f, p, n);
    800051c4:	fe442603          	lw	a2,-28(s0)
    800051c8:	fd843583          	ld	a1,-40(s0)
    800051cc:	fe843503          	ld	a0,-24(s0)
    800051d0:	fffff097          	auipc	ra,0xfffff
    800051d4:	49e080e7          	jalr	1182(ra) # 8000466e <fileread>
    800051d8:	87aa                	mv	a5,a0
}
    800051da:	853e                	mv	a0,a5
    800051dc:	70a2                	ld	ra,40(sp)
    800051de:	7402                	ld	s0,32(sp)
    800051e0:	6145                	addi	sp,sp,48
    800051e2:	8082                	ret

00000000800051e4 <sys_write>:
{
    800051e4:	7179                	addi	sp,sp,-48
    800051e6:	f406                	sd	ra,40(sp)
    800051e8:	f022                	sd	s0,32(sp)
    800051ea:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051ec:	fe840613          	addi	a2,s0,-24
    800051f0:	4581                	li	a1,0
    800051f2:	4501                	li	a0,0
    800051f4:	00000097          	auipc	ra,0x0
    800051f8:	d2a080e7          	jalr	-726(ra) # 80004f1e <argfd>
    return -1;
    800051fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051fe:	04054163          	bltz	a0,80005240 <sys_write+0x5c>
    80005202:	fe440593          	addi	a1,s0,-28
    80005206:	4509                	li	a0,2
    80005208:	ffffe097          	auipc	ra,0xffffe
    8000520c:	854080e7          	jalr	-1964(ra) # 80002a5c <argint>
    return -1;
    80005210:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005212:	02054763          	bltz	a0,80005240 <sys_write+0x5c>
    80005216:	fd840593          	addi	a1,s0,-40
    8000521a:	4505                	li	a0,1
    8000521c:	ffffe097          	auipc	ra,0xffffe
    80005220:	862080e7          	jalr	-1950(ra) # 80002a7e <argaddr>
    return -1;
    80005224:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005226:	00054d63          	bltz	a0,80005240 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000522a:	fe442603          	lw	a2,-28(s0)
    8000522e:	fd843583          	ld	a1,-40(s0)
    80005232:	fe843503          	ld	a0,-24(s0)
    80005236:	fffff097          	auipc	ra,0xfffff
    8000523a:	4fa080e7          	jalr	1274(ra) # 80004730 <filewrite>
    8000523e:	87aa                	mv	a5,a0
}
    80005240:	853e                	mv	a0,a5
    80005242:	70a2                	ld	ra,40(sp)
    80005244:	7402                	ld	s0,32(sp)
    80005246:	6145                	addi	sp,sp,48
    80005248:	8082                	ret

000000008000524a <sys_close>:
{
    8000524a:	1101                	addi	sp,sp,-32
    8000524c:	ec06                	sd	ra,24(sp)
    8000524e:	e822                	sd	s0,16(sp)
    80005250:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005252:	fe040613          	addi	a2,s0,-32
    80005256:	fec40593          	addi	a1,s0,-20
    8000525a:	4501                	li	a0,0
    8000525c:	00000097          	auipc	ra,0x0
    80005260:	cc2080e7          	jalr	-830(ra) # 80004f1e <argfd>
    return -1;
    80005264:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005266:	02054463          	bltz	a0,8000528e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000526a:	ffffc097          	auipc	ra,0xffffc
    8000526e:	746080e7          	jalr	1862(ra) # 800019b0 <myproc>
    80005272:	fec42783          	lw	a5,-20(s0)
    80005276:	07e9                	addi	a5,a5,26
    80005278:	078e                	slli	a5,a5,0x3
    8000527a:	97aa                	add	a5,a5,a0
    8000527c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005280:	fe043503          	ld	a0,-32(s0)
    80005284:	fffff097          	auipc	ra,0xfffff
    80005288:	2b0080e7          	jalr	688(ra) # 80004534 <fileclose>
  return 0;
    8000528c:	4781                	li	a5,0
}
    8000528e:	853e                	mv	a0,a5
    80005290:	60e2                	ld	ra,24(sp)
    80005292:	6442                	ld	s0,16(sp)
    80005294:	6105                	addi	sp,sp,32
    80005296:	8082                	ret

0000000080005298 <sys_fstat>:
{
    80005298:	1101                	addi	sp,sp,-32
    8000529a:	ec06                	sd	ra,24(sp)
    8000529c:	e822                	sd	s0,16(sp)
    8000529e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052a0:	fe840613          	addi	a2,s0,-24
    800052a4:	4581                	li	a1,0
    800052a6:	4501                	li	a0,0
    800052a8:	00000097          	auipc	ra,0x0
    800052ac:	c76080e7          	jalr	-906(ra) # 80004f1e <argfd>
    return -1;
    800052b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052b2:	02054563          	bltz	a0,800052dc <sys_fstat+0x44>
    800052b6:	fe040593          	addi	a1,s0,-32
    800052ba:	4505                	li	a0,1
    800052bc:	ffffd097          	auipc	ra,0xffffd
    800052c0:	7c2080e7          	jalr	1986(ra) # 80002a7e <argaddr>
    return -1;
    800052c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052c6:	00054b63          	bltz	a0,800052dc <sys_fstat+0x44>
  return filestat(f, st);
    800052ca:	fe043583          	ld	a1,-32(s0)
    800052ce:	fe843503          	ld	a0,-24(s0)
    800052d2:	fffff097          	auipc	ra,0xfffff
    800052d6:	32a080e7          	jalr	810(ra) # 800045fc <filestat>
    800052da:	87aa                	mv	a5,a0
}
    800052dc:	853e                	mv	a0,a5
    800052de:	60e2                	ld	ra,24(sp)
    800052e0:	6442                	ld	s0,16(sp)
    800052e2:	6105                	addi	sp,sp,32
    800052e4:	8082                	ret

00000000800052e6 <sys_link>:
{
    800052e6:	7169                	addi	sp,sp,-304
    800052e8:	f606                	sd	ra,296(sp)
    800052ea:	f222                	sd	s0,288(sp)
    800052ec:	ee26                	sd	s1,280(sp)
    800052ee:	ea4a                	sd	s2,272(sp)
    800052f0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052f2:	08000613          	li	a2,128
    800052f6:	ed040593          	addi	a1,s0,-304
    800052fa:	4501                	li	a0,0
    800052fc:	ffffd097          	auipc	ra,0xffffd
    80005300:	7a4080e7          	jalr	1956(ra) # 80002aa0 <argstr>
    return -1;
    80005304:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005306:	10054e63          	bltz	a0,80005422 <sys_link+0x13c>
    8000530a:	08000613          	li	a2,128
    8000530e:	f5040593          	addi	a1,s0,-176
    80005312:	4505                	li	a0,1
    80005314:	ffffd097          	auipc	ra,0xffffd
    80005318:	78c080e7          	jalr	1932(ra) # 80002aa0 <argstr>
    return -1;
    8000531c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000531e:	10054263          	bltz	a0,80005422 <sys_link+0x13c>
  begin_op();
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	d46080e7          	jalr	-698(ra) # 80004068 <begin_op>
  if((ip = namei(old)) == 0){
    8000532a:	ed040513          	addi	a0,s0,-304
    8000532e:	fffff097          	auipc	ra,0xfffff
    80005332:	b1e080e7          	jalr	-1250(ra) # 80003e4c <namei>
    80005336:	84aa                	mv	s1,a0
    80005338:	c551                	beqz	a0,800053c4 <sys_link+0xde>
  ilock(ip);
    8000533a:	ffffe097          	auipc	ra,0xffffe
    8000533e:	35a080e7          	jalr	858(ra) # 80003694 <ilock>
  if(ip->type == T_DIR){
    80005342:	04449703          	lh	a4,68(s1)
    80005346:	4785                	li	a5,1
    80005348:	08f70463          	beq	a4,a5,800053d0 <sys_link+0xea>
  ip->nlink++;
    8000534c:	04a4d783          	lhu	a5,74(s1)
    80005350:	2785                	addiw	a5,a5,1
    80005352:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005356:	8526                	mv	a0,s1
    80005358:	ffffe097          	auipc	ra,0xffffe
    8000535c:	272080e7          	jalr	626(ra) # 800035ca <iupdate>
  iunlock(ip);
    80005360:	8526                	mv	a0,s1
    80005362:	ffffe097          	auipc	ra,0xffffe
    80005366:	3f4080e7          	jalr	1012(ra) # 80003756 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000536a:	fd040593          	addi	a1,s0,-48
    8000536e:	f5040513          	addi	a0,s0,-176
    80005372:	fffff097          	auipc	ra,0xfffff
    80005376:	af8080e7          	jalr	-1288(ra) # 80003e6a <nameiparent>
    8000537a:	892a                	mv	s2,a0
    8000537c:	c935                	beqz	a0,800053f0 <sys_link+0x10a>
  ilock(dp);
    8000537e:	ffffe097          	auipc	ra,0xffffe
    80005382:	316080e7          	jalr	790(ra) # 80003694 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005386:	00092703          	lw	a4,0(s2)
    8000538a:	409c                	lw	a5,0(s1)
    8000538c:	04f71d63          	bne	a4,a5,800053e6 <sys_link+0x100>
    80005390:	40d0                	lw	a2,4(s1)
    80005392:	fd040593          	addi	a1,s0,-48
    80005396:	854a                	mv	a0,s2
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	9f2080e7          	jalr	-1550(ra) # 80003d8a <dirlink>
    800053a0:	04054363          	bltz	a0,800053e6 <sys_link+0x100>
  iunlockput(dp);
    800053a4:	854a                	mv	a0,s2
    800053a6:	ffffe097          	auipc	ra,0xffffe
    800053aa:	550080e7          	jalr	1360(ra) # 800038f6 <iunlockput>
  iput(ip);
    800053ae:	8526                	mv	a0,s1
    800053b0:	ffffe097          	auipc	ra,0xffffe
    800053b4:	49e080e7          	jalr	1182(ra) # 8000384e <iput>
  end_op();
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	d30080e7          	jalr	-720(ra) # 800040e8 <end_op>
  return 0;
    800053c0:	4781                	li	a5,0
    800053c2:	a085                	j	80005422 <sys_link+0x13c>
    end_op();
    800053c4:	fffff097          	auipc	ra,0xfffff
    800053c8:	d24080e7          	jalr	-732(ra) # 800040e8 <end_op>
    return -1;
    800053cc:	57fd                	li	a5,-1
    800053ce:	a891                	j	80005422 <sys_link+0x13c>
    iunlockput(ip);
    800053d0:	8526                	mv	a0,s1
    800053d2:	ffffe097          	auipc	ra,0xffffe
    800053d6:	524080e7          	jalr	1316(ra) # 800038f6 <iunlockput>
    end_op();
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	d0e080e7          	jalr	-754(ra) # 800040e8 <end_op>
    return -1;
    800053e2:	57fd                	li	a5,-1
    800053e4:	a83d                	j	80005422 <sys_link+0x13c>
    iunlockput(dp);
    800053e6:	854a                	mv	a0,s2
    800053e8:	ffffe097          	auipc	ra,0xffffe
    800053ec:	50e080e7          	jalr	1294(ra) # 800038f6 <iunlockput>
  ilock(ip);
    800053f0:	8526                	mv	a0,s1
    800053f2:	ffffe097          	auipc	ra,0xffffe
    800053f6:	2a2080e7          	jalr	674(ra) # 80003694 <ilock>
  ip->nlink--;
    800053fa:	04a4d783          	lhu	a5,74(s1)
    800053fe:	37fd                	addiw	a5,a5,-1
    80005400:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005404:	8526                	mv	a0,s1
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	1c4080e7          	jalr	452(ra) # 800035ca <iupdate>
  iunlockput(ip);
    8000540e:	8526                	mv	a0,s1
    80005410:	ffffe097          	auipc	ra,0xffffe
    80005414:	4e6080e7          	jalr	1254(ra) # 800038f6 <iunlockput>
  end_op();
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	cd0080e7          	jalr	-816(ra) # 800040e8 <end_op>
  return -1;
    80005420:	57fd                	li	a5,-1
}
    80005422:	853e                	mv	a0,a5
    80005424:	70b2                	ld	ra,296(sp)
    80005426:	7412                	ld	s0,288(sp)
    80005428:	64f2                	ld	s1,280(sp)
    8000542a:	6952                	ld	s2,272(sp)
    8000542c:	6155                	addi	sp,sp,304
    8000542e:	8082                	ret

0000000080005430 <sys_unlink>:
{
    80005430:	7151                	addi	sp,sp,-240
    80005432:	f586                	sd	ra,232(sp)
    80005434:	f1a2                	sd	s0,224(sp)
    80005436:	eda6                	sd	s1,216(sp)
    80005438:	e9ca                	sd	s2,208(sp)
    8000543a:	e5ce                	sd	s3,200(sp)
    8000543c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000543e:	08000613          	li	a2,128
    80005442:	f3040593          	addi	a1,s0,-208
    80005446:	4501                	li	a0,0
    80005448:	ffffd097          	auipc	ra,0xffffd
    8000544c:	658080e7          	jalr	1624(ra) # 80002aa0 <argstr>
    80005450:	18054163          	bltz	a0,800055d2 <sys_unlink+0x1a2>
  begin_op();
    80005454:	fffff097          	auipc	ra,0xfffff
    80005458:	c14080e7          	jalr	-1004(ra) # 80004068 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000545c:	fb040593          	addi	a1,s0,-80
    80005460:	f3040513          	addi	a0,s0,-208
    80005464:	fffff097          	auipc	ra,0xfffff
    80005468:	a06080e7          	jalr	-1530(ra) # 80003e6a <nameiparent>
    8000546c:	84aa                	mv	s1,a0
    8000546e:	c979                	beqz	a0,80005544 <sys_unlink+0x114>
  ilock(dp);
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	224080e7          	jalr	548(ra) # 80003694 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005478:	00003597          	auipc	a1,0x3
    8000547c:	28058593          	addi	a1,a1,640 # 800086f8 <syscalls+0x2b0>
    80005480:	fb040513          	addi	a0,s0,-80
    80005484:	ffffe097          	auipc	ra,0xffffe
    80005488:	6dc080e7          	jalr	1756(ra) # 80003b60 <namecmp>
    8000548c:	14050a63          	beqz	a0,800055e0 <sys_unlink+0x1b0>
    80005490:	00003597          	auipc	a1,0x3
    80005494:	27058593          	addi	a1,a1,624 # 80008700 <syscalls+0x2b8>
    80005498:	fb040513          	addi	a0,s0,-80
    8000549c:	ffffe097          	auipc	ra,0xffffe
    800054a0:	6c4080e7          	jalr	1732(ra) # 80003b60 <namecmp>
    800054a4:	12050e63          	beqz	a0,800055e0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054a8:	f2c40613          	addi	a2,s0,-212
    800054ac:	fb040593          	addi	a1,s0,-80
    800054b0:	8526                	mv	a0,s1
    800054b2:	ffffe097          	auipc	ra,0xffffe
    800054b6:	6c8080e7          	jalr	1736(ra) # 80003b7a <dirlookup>
    800054ba:	892a                	mv	s2,a0
    800054bc:	12050263          	beqz	a0,800055e0 <sys_unlink+0x1b0>
  ilock(ip);
    800054c0:	ffffe097          	auipc	ra,0xffffe
    800054c4:	1d4080e7          	jalr	468(ra) # 80003694 <ilock>
  if(ip->nlink < 1)
    800054c8:	04a91783          	lh	a5,74(s2)
    800054cc:	08f05263          	blez	a5,80005550 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800054d0:	04491703          	lh	a4,68(s2)
    800054d4:	4785                	li	a5,1
    800054d6:	08f70563          	beq	a4,a5,80005560 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800054da:	4641                	li	a2,16
    800054dc:	4581                	li	a1,0
    800054de:	fc040513          	addi	a0,s0,-64
    800054e2:	ffffb097          	auipc	ra,0xffffb
    800054e6:	7fe080e7          	jalr	2046(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054ea:	4741                	li	a4,16
    800054ec:	f2c42683          	lw	a3,-212(s0)
    800054f0:	fc040613          	addi	a2,s0,-64
    800054f4:	4581                	li	a1,0
    800054f6:	8526                	mv	a0,s1
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	548080e7          	jalr	1352(ra) # 80003a40 <writei>
    80005500:	47c1                	li	a5,16
    80005502:	0af51563          	bne	a0,a5,800055ac <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005506:	04491703          	lh	a4,68(s2)
    8000550a:	4785                	li	a5,1
    8000550c:	0af70863          	beq	a4,a5,800055bc <sys_unlink+0x18c>
  iunlockput(dp);
    80005510:	8526                	mv	a0,s1
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	3e4080e7          	jalr	996(ra) # 800038f6 <iunlockput>
  ip->nlink--;
    8000551a:	04a95783          	lhu	a5,74(s2)
    8000551e:	37fd                	addiw	a5,a5,-1
    80005520:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005524:	854a                	mv	a0,s2
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	0a4080e7          	jalr	164(ra) # 800035ca <iupdate>
  iunlockput(ip);
    8000552e:	854a                	mv	a0,s2
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	3c6080e7          	jalr	966(ra) # 800038f6 <iunlockput>
  end_op();
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	bb0080e7          	jalr	-1104(ra) # 800040e8 <end_op>
  return 0;
    80005540:	4501                	li	a0,0
    80005542:	a84d                	j	800055f4 <sys_unlink+0x1c4>
    end_op();
    80005544:	fffff097          	auipc	ra,0xfffff
    80005548:	ba4080e7          	jalr	-1116(ra) # 800040e8 <end_op>
    return -1;
    8000554c:	557d                	li	a0,-1
    8000554e:	a05d                	j	800055f4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005550:	00003517          	auipc	a0,0x3
    80005554:	1d850513          	addi	a0,a0,472 # 80008728 <syscalls+0x2e0>
    80005558:	ffffb097          	auipc	ra,0xffffb
    8000555c:	fe6080e7          	jalr	-26(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005560:	04c92703          	lw	a4,76(s2)
    80005564:	02000793          	li	a5,32
    80005568:	f6e7f9e3          	bgeu	a5,a4,800054da <sys_unlink+0xaa>
    8000556c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005570:	4741                	li	a4,16
    80005572:	86ce                	mv	a3,s3
    80005574:	f1840613          	addi	a2,s0,-232
    80005578:	4581                	li	a1,0
    8000557a:	854a                	mv	a0,s2
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	3cc080e7          	jalr	972(ra) # 80003948 <readi>
    80005584:	47c1                	li	a5,16
    80005586:	00f51b63          	bne	a0,a5,8000559c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000558a:	f1845783          	lhu	a5,-232(s0)
    8000558e:	e7a1                	bnez	a5,800055d6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005590:	29c1                	addiw	s3,s3,16
    80005592:	04c92783          	lw	a5,76(s2)
    80005596:	fcf9ede3          	bltu	s3,a5,80005570 <sys_unlink+0x140>
    8000559a:	b781                	j	800054da <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000559c:	00003517          	auipc	a0,0x3
    800055a0:	1a450513          	addi	a0,a0,420 # 80008740 <syscalls+0x2f8>
    800055a4:	ffffb097          	auipc	ra,0xffffb
    800055a8:	f9a080e7          	jalr	-102(ra) # 8000053e <panic>
    panic("unlink: writei");
    800055ac:	00003517          	auipc	a0,0x3
    800055b0:	1ac50513          	addi	a0,a0,428 # 80008758 <syscalls+0x310>
    800055b4:	ffffb097          	auipc	ra,0xffffb
    800055b8:	f8a080e7          	jalr	-118(ra) # 8000053e <panic>
    dp->nlink--;
    800055bc:	04a4d783          	lhu	a5,74(s1)
    800055c0:	37fd                	addiw	a5,a5,-1
    800055c2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055c6:	8526                	mv	a0,s1
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	002080e7          	jalr	2(ra) # 800035ca <iupdate>
    800055d0:	b781                	j	80005510 <sys_unlink+0xe0>
    return -1;
    800055d2:	557d                	li	a0,-1
    800055d4:	a005                	j	800055f4 <sys_unlink+0x1c4>
    iunlockput(ip);
    800055d6:	854a                	mv	a0,s2
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	31e080e7          	jalr	798(ra) # 800038f6 <iunlockput>
  iunlockput(dp);
    800055e0:	8526                	mv	a0,s1
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	314080e7          	jalr	788(ra) # 800038f6 <iunlockput>
  end_op();
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	afe080e7          	jalr	-1282(ra) # 800040e8 <end_op>
  return -1;
    800055f2:	557d                	li	a0,-1
}
    800055f4:	70ae                	ld	ra,232(sp)
    800055f6:	740e                	ld	s0,224(sp)
    800055f8:	64ee                	ld	s1,216(sp)
    800055fa:	694e                	ld	s2,208(sp)
    800055fc:	69ae                	ld	s3,200(sp)
    800055fe:	616d                	addi	sp,sp,240
    80005600:	8082                	ret

0000000080005602 <sys_open>:

uint64
sys_open(void)
{
    80005602:	7131                	addi	sp,sp,-192
    80005604:	fd06                	sd	ra,184(sp)
    80005606:	f922                	sd	s0,176(sp)
    80005608:	f526                	sd	s1,168(sp)
    8000560a:	f14a                	sd	s2,160(sp)
    8000560c:	ed4e                	sd	s3,152(sp)
    8000560e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005610:	08000613          	li	a2,128
    80005614:	f5040593          	addi	a1,s0,-176
    80005618:	4501                	li	a0,0
    8000561a:	ffffd097          	auipc	ra,0xffffd
    8000561e:	486080e7          	jalr	1158(ra) # 80002aa0 <argstr>
    return -1;
    80005622:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005624:	0c054163          	bltz	a0,800056e6 <sys_open+0xe4>
    80005628:	f4c40593          	addi	a1,s0,-180
    8000562c:	4505                	li	a0,1
    8000562e:	ffffd097          	auipc	ra,0xffffd
    80005632:	42e080e7          	jalr	1070(ra) # 80002a5c <argint>
    80005636:	0a054863          	bltz	a0,800056e6 <sys_open+0xe4>

  begin_op();
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	a2e080e7          	jalr	-1490(ra) # 80004068 <begin_op>

  if(omode & O_CREATE){
    80005642:	f4c42783          	lw	a5,-180(s0)
    80005646:	2007f793          	andi	a5,a5,512
    8000564a:	cbdd                	beqz	a5,80005700 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000564c:	4681                	li	a3,0
    8000564e:	4601                	li	a2,0
    80005650:	4589                	li	a1,2
    80005652:	f5040513          	addi	a0,s0,-176
    80005656:	00000097          	auipc	ra,0x0
    8000565a:	972080e7          	jalr	-1678(ra) # 80004fc8 <create>
    8000565e:	892a                	mv	s2,a0
    if(ip == 0){
    80005660:	c959                	beqz	a0,800056f6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005662:	04491703          	lh	a4,68(s2)
    80005666:	478d                	li	a5,3
    80005668:	00f71763          	bne	a4,a5,80005676 <sys_open+0x74>
    8000566c:	04695703          	lhu	a4,70(s2)
    80005670:	47a5                	li	a5,9
    80005672:	0ce7ec63          	bltu	a5,a4,8000574a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	e02080e7          	jalr	-510(ra) # 80004478 <filealloc>
    8000567e:	89aa                	mv	s3,a0
    80005680:	10050263          	beqz	a0,80005784 <sys_open+0x182>
    80005684:	00000097          	auipc	ra,0x0
    80005688:	902080e7          	jalr	-1790(ra) # 80004f86 <fdalloc>
    8000568c:	84aa                	mv	s1,a0
    8000568e:	0e054663          	bltz	a0,8000577a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005692:	04491703          	lh	a4,68(s2)
    80005696:	478d                	li	a5,3
    80005698:	0cf70463          	beq	a4,a5,80005760 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000569c:	4789                	li	a5,2
    8000569e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056a2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056a6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056aa:	f4c42783          	lw	a5,-180(s0)
    800056ae:	0017c713          	xori	a4,a5,1
    800056b2:	8b05                	andi	a4,a4,1
    800056b4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800056b8:	0037f713          	andi	a4,a5,3
    800056bc:	00e03733          	snez	a4,a4
    800056c0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800056c4:	4007f793          	andi	a5,a5,1024
    800056c8:	c791                	beqz	a5,800056d4 <sys_open+0xd2>
    800056ca:	04491703          	lh	a4,68(s2)
    800056ce:	4789                	li	a5,2
    800056d0:	08f70f63          	beq	a4,a5,8000576e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800056d4:	854a                	mv	a0,s2
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	080080e7          	jalr	128(ra) # 80003756 <iunlock>
  end_op();
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	a0a080e7          	jalr	-1526(ra) # 800040e8 <end_op>

  return fd;
}
    800056e6:	8526                	mv	a0,s1
    800056e8:	70ea                	ld	ra,184(sp)
    800056ea:	744a                	ld	s0,176(sp)
    800056ec:	74aa                	ld	s1,168(sp)
    800056ee:	790a                	ld	s2,160(sp)
    800056f0:	69ea                	ld	s3,152(sp)
    800056f2:	6129                	addi	sp,sp,192
    800056f4:	8082                	ret
      end_op();
    800056f6:	fffff097          	auipc	ra,0xfffff
    800056fa:	9f2080e7          	jalr	-1550(ra) # 800040e8 <end_op>
      return -1;
    800056fe:	b7e5                	j	800056e6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005700:	f5040513          	addi	a0,s0,-176
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	748080e7          	jalr	1864(ra) # 80003e4c <namei>
    8000570c:	892a                	mv	s2,a0
    8000570e:	c905                	beqz	a0,8000573e <sys_open+0x13c>
    ilock(ip);
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	f84080e7          	jalr	-124(ra) # 80003694 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005718:	04491703          	lh	a4,68(s2)
    8000571c:	4785                	li	a5,1
    8000571e:	f4f712e3          	bne	a4,a5,80005662 <sys_open+0x60>
    80005722:	f4c42783          	lw	a5,-180(s0)
    80005726:	dba1                	beqz	a5,80005676 <sys_open+0x74>
      iunlockput(ip);
    80005728:	854a                	mv	a0,s2
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	1cc080e7          	jalr	460(ra) # 800038f6 <iunlockput>
      end_op();
    80005732:	fffff097          	auipc	ra,0xfffff
    80005736:	9b6080e7          	jalr	-1610(ra) # 800040e8 <end_op>
      return -1;
    8000573a:	54fd                	li	s1,-1
    8000573c:	b76d                	j	800056e6 <sys_open+0xe4>
      end_op();
    8000573e:	fffff097          	auipc	ra,0xfffff
    80005742:	9aa080e7          	jalr	-1622(ra) # 800040e8 <end_op>
      return -1;
    80005746:	54fd                	li	s1,-1
    80005748:	bf79                	j	800056e6 <sys_open+0xe4>
    iunlockput(ip);
    8000574a:	854a                	mv	a0,s2
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	1aa080e7          	jalr	426(ra) # 800038f6 <iunlockput>
    end_op();
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	994080e7          	jalr	-1644(ra) # 800040e8 <end_op>
    return -1;
    8000575c:	54fd                	li	s1,-1
    8000575e:	b761                	j	800056e6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005760:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005764:	04691783          	lh	a5,70(s2)
    80005768:	02f99223          	sh	a5,36(s3)
    8000576c:	bf2d                	j	800056a6 <sys_open+0xa4>
    itrunc(ip);
    8000576e:	854a                	mv	a0,s2
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	032080e7          	jalr	50(ra) # 800037a2 <itrunc>
    80005778:	bfb1                	j	800056d4 <sys_open+0xd2>
      fileclose(f);
    8000577a:	854e                	mv	a0,s3
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	db8080e7          	jalr	-584(ra) # 80004534 <fileclose>
    iunlockput(ip);
    80005784:	854a                	mv	a0,s2
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	170080e7          	jalr	368(ra) # 800038f6 <iunlockput>
    end_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	95a080e7          	jalr	-1702(ra) # 800040e8 <end_op>
    return -1;
    80005796:	54fd                	li	s1,-1
    80005798:	b7b9                	j	800056e6 <sys_open+0xe4>

000000008000579a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000579a:	7175                	addi	sp,sp,-144
    8000579c:	e506                	sd	ra,136(sp)
    8000579e:	e122                	sd	s0,128(sp)
    800057a0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	8c6080e7          	jalr	-1850(ra) # 80004068 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057aa:	08000613          	li	a2,128
    800057ae:	f7040593          	addi	a1,s0,-144
    800057b2:	4501                	li	a0,0
    800057b4:	ffffd097          	auipc	ra,0xffffd
    800057b8:	2ec080e7          	jalr	748(ra) # 80002aa0 <argstr>
    800057bc:	02054963          	bltz	a0,800057ee <sys_mkdir+0x54>
    800057c0:	4681                	li	a3,0
    800057c2:	4601                	li	a2,0
    800057c4:	4585                	li	a1,1
    800057c6:	f7040513          	addi	a0,s0,-144
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	7fe080e7          	jalr	2046(ra) # 80004fc8 <create>
    800057d2:	cd11                	beqz	a0,800057ee <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	122080e7          	jalr	290(ra) # 800038f6 <iunlockput>
  end_op();
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	90c080e7          	jalr	-1780(ra) # 800040e8 <end_op>
  return 0;
    800057e4:	4501                	li	a0,0
}
    800057e6:	60aa                	ld	ra,136(sp)
    800057e8:	640a                	ld	s0,128(sp)
    800057ea:	6149                	addi	sp,sp,144
    800057ec:	8082                	ret
    end_op();
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	8fa080e7          	jalr	-1798(ra) # 800040e8 <end_op>
    return -1;
    800057f6:	557d                	li	a0,-1
    800057f8:	b7fd                	j	800057e6 <sys_mkdir+0x4c>

00000000800057fa <sys_mknod>:

uint64
sys_mknod(void)
{
    800057fa:	7135                	addi	sp,sp,-160
    800057fc:	ed06                	sd	ra,152(sp)
    800057fe:	e922                	sd	s0,144(sp)
    80005800:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	866080e7          	jalr	-1946(ra) # 80004068 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000580a:	08000613          	li	a2,128
    8000580e:	f7040593          	addi	a1,s0,-144
    80005812:	4501                	li	a0,0
    80005814:	ffffd097          	auipc	ra,0xffffd
    80005818:	28c080e7          	jalr	652(ra) # 80002aa0 <argstr>
    8000581c:	04054a63          	bltz	a0,80005870 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005820:	f6c40593          	addi	a1,s0,-148
    80005824:	4505                	li	a0,1
    80005826:	ffffd097          	auipc	ra,0xffffd
    8000582a:	236080e7          	jalr	566(ra) # 80002a5c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000582e:	04054163          	bltz	a0,80005870 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005832:	f6840593          	addi	a1,s0,-152
    80005836:	4509                	li	a0,2
    80005838:	ffffd097          	auipc	ra,0xffffd
    8000583c:	224080e7          	jalr	548(ra) # 80002a5c <argint>
     argint(1, &major) < 0 ||
    80005840:	02054863          	bltz	a0,80005870 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005844:	f6841683          	lh	a3,-152(s0)
    80005848:	f6c41603          	lh	a2,-148(s0)
    8000584c:	458d                	li	a1,3
    8000584e:	f7040513          	addi	a0,s0,-144
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	776080e7          	jalr	1910(ra) # 80004fc8 <create>
     argint(2, &minor) < 0 ||
    8000585a:	c919                	beqz	a0,80005870 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000585c:	ffffe097          	auipc	ra,0xffffe
    80005860:	09a080e7          	jalr	154(ra) # 800038f6 <iunlockput>
  end_op();
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	884080e7          	jalr	-1916(ra) # 800040e8 <end_op>
  return 0;
    8000586c:	4501                	li	a0,0
    8000586e:	a031                	j	8000587a <sys_mknod+0x80>
    end_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	878080e7          	jalr	-1928(ra) # 800040e8 <end_op>
    return -1;
    80005878:	557d                	li	a0,-1
}
    8000587a:	60ea                	ld	ra,152(sp)
    8000587c:	644a                	ld	s0,144(sp)
    8000587e:	610d                	addi	sp,sp,160
    80005880:	8082                	ret

0000000080005882 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005882:	7135                	addi	sp,sp,-160
    80005884:	ed06                	sd	ra,152(sp)
    80005886:	e922                	sd	s0,144(sp)
    80005888:	e526                	sd	s1,136(sp)
    8000588a:	e14a                	sd	s2,128(sp)
    8000588c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000588e:	ffffc097          	auipc	ra,0xffffc
    80005892:	122080e7          	jalr	290(ra) # 800019b0 <myproc>
    80005896:	892a                	mv	s2,a0
  
  begin_op();
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	7d0080e7          	jalr	2000(ra) # 80004068 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058a0:	08000613          	li	a2,128
    800058a4:	f6040593          	addi	a1,s0,-160
    800058a8:	4501                	li	a0,0
    800058aa:	ffffd097          	auipc	ra,0xffffd
    800058ae:	1f6080e7          	jalr	502(ra) # 80002aa0 <argstr>
    800058b2:	04054b63          	bltz	a0,80005908 <sys_chdir+0x86>
    800058b6:	f6040513          	addi	a0,s0,-160
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	592080e7          	jalr	1426(ra) # 80003e4c <namei>
    800058c2:	84aa                	mv	s1,a0
    800058c4:	c131                	beqz	a0,80005908 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	dce080e7          	jalr	-562(ra) # 80003694 <ilock>
  if(ip->type != T_DIR){
    800058ce:	04449703          	lh	a4,68(s1)
    800058d2:	4785                	li	a5,1
    800058d4:	04f71063          	bne	a4,a5,80005914 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800058d8:	8526                	mv	a0,s1
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	e7c080e7          	jalr	-388(ra) # 80003756 <iunlock>
  iput(p->cwd);
    800058e2:	15093503          	ld	a0,336(s2)
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	f68080e7          	jalr	-152(ra) # 8000384e <iput>
  end_op();
    800058ee:	ffffe097          	auipc	ra,0xffffe
    800058f2:	7fa080e7          	jalr	2042(ra) # 800040e8 <end_op>
  p->cwd = ip;
    800058f6:	14993823          	sd	s1,336(s2)
  return 0;
    800058fa:	4501                	li	a0,0
}
    800058fc:	60ea                	ld	ra,152(sp)
    800058fe:	644a                	ld	s0,144(sp)
    80005900:	64aa                	ld	s1,136(sp)
    80005902:	690a                	ld	s2,128(sp)
    80005904:	610d                	addi	sp,sp,160
    80005906:	8082                	ret
    end_op();
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	7e0080e7          	jalr	2016(ra) # 800040e8 <end_op>
    return -1;
    80005910:	557d                	li	a0,-1
    80005912:	b7ed                	j	800058fc <sys_chdir+0x7a>
    iunlockput(ip);
    80005914:	8526                	mv	a0,s1
    80005916:	ffffe097          	auipc	ra,0xffffe
    8000591a:	fe0080e7          	jalr	-32(ra) # 800038f6 <iunlockput>
    end_op();
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	7ca080e7          	jalr	1994(ra) # 800040e8 <end_op>
    return -1;
    80005926:	557d                	li	a0,-1
    80005928:	bfd1                	j	800058fc <sys_chdir+0x7a>

000000008000592a <sys_exec>:

uint64
sys_exec(void)
{
    8000592a:	7145                	addi	sp,sp,-464
    8000592c:	e786                	sd	ra,456(sp)
    8000592e:	e3a2                	sd	s0,448(sp)
    80005930:	ff26                	sd	s1,440(sp)
    80005932:	fb4a                	sd	s2,432(sp)
    80005934:	f74e                	sd	s3,424(sp)
    80005936:	f352                	sd	s4,416(sp)
    80005938:	ef56                	sd	s5,408(sp)
    8000593a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000593c:	08000613          	li	a2,128
    80005940:	f4040593          	addi	a1,s0,-192
    80005944:	4501                	li	a0,0
    80005946:	ffffd097          	auipc	ra,0xffffd
    8000594a:	15a080e7          	jalr	346(ra) # 80002aa0 <argstr>
    return -1;
    8000594e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005950:	0c054a63          	bltz	a0,80005a24 <sys_exec+0xfa>
    80005954:	e3840593          	addi	a1,s0,-456
    80005958:	4505                	li	a0,1
    8000595a:	ffffd097          	auipc	ra,0xffffd
    8000595e:	124080e7          	jalr	292(ra) # 80002a7e <argaddr>
    80005962:	0c054163          	bltz	a0,80005a24 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005966:	10000613          	li	a2,256
    8000596a:	4581                	li	a1,0
    8000596c:	e4040513          	addi	a0,s0,-448
    80005970:	ffffb097          	auipc	ra,0xffffb
    80005974:	370080e7          	jalr	880(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005978:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000597c:	89a6                	mv	s3,s1
    8000597e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005980:	02000a13          	li	s4,32
    80005984:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005988:	00391513          	slli	a0,s2,0x3
    8000598c:	e3040593          	addi	a1,s0,-464
    80005990:	e3843783          	ld	a5,-456(s0)
    80005994:	953e                	add	a0,a0,a5
    80005996:	ffffd097          	auipc	ra,0xffffd
    8000599a:	02c080e7          	jalr	44(ra) # 800029c2 <fetchaddr>
    8000599e:	02054a63          	bltz	a0,800059d2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800059a2:	e3043783          	ld	a5,-464(s0)
    800059a6:	c3b9                	beqz	a5,800059ec <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059a8:	ffffb097          	auipc	ra,0xffffb
    800059ac:	14c080e7          	jalr	332(ra) # 80000af4 <kalloc>
    800059b0:	85aa                	mv	a1,a0
    800059b2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800059b6:	cd11                	beqz	a0,800059d2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059b8:	6605                	lui	a2,0x1
    800059ba:	e3043503          	ld	a0,-464(s0)
    800059be:	ffffd097          	auipc	ra,0xffffd
    800059c2:	056080e7          	jalr	86(ra) # 80002a14 <fetchstr>
    800059c6:	00054663          	bltz	a0,800059d2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800059ca:	0905                	addi	s2,s2,1
    800059cc:	09a1                	addi	s3,s3,8
    800059ce:	fb491be3          	bne	s2,s4,80005984 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059d2:	10048913          	addi	s2,s1,256
    800059d6:	6088                	ld	a0,0(s1)
    800059d8:	c529                	beqz	a0,80005a22 <sys_exec+0xf8>
    kfree(argv[i]);
    800059da:	ffffb097          	auipc	ra,0xffffb
    800059de:	01e080e7          	jalr	30(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059e2:	04a1                	addi	s1,s1,8
    800059e4:	ff2499e3          	bne	s1,s2,800059d6 <sys_exec+0xac>
  return -1;
    800059e8:	597d                	li	s2,-1
    800059ea:	a82d                	j	80005a24 <sys_exec+0xfa>
      argv[i] = 0;
    800059ec:	0a8e                	slli	s5,s5,0x3
    800059ee:	fc040793          	addi	a5,s0,-64
    800059f2:	9abe                	add	s5,s5,a5
    800059f4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800059f8:	e4040593          	addi	a1,s0,-448
    800059fc:	f4040513          	addi	a0,s0,-192
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	194080e7          	jalr	404(ra) # 80004b94 <exec>
    80005a08:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a0a:	10048993          	addi	s3,s1,256
    80005a0e:	6088                	ld	a0,0(s1)
    80005a10:	c911                	beqz	a0,80005a24 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a12:	ffffb097          	auipc	ra,0xffffb
    80005a16:	fe6080e7          	jalr	-26(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a1a:	04a1                	addi	s1,s1,8
    80005a1c:	ff3499e3          	bne	s1,s3,80005a0e <sys_exec+0xe4>
    80005a20:	a011                	j	80005a24 <sys_exec+0xfa>
  return -1;
    80005a22:	597d                	li	s2,-1
}
    80005a24:	854a                	mv	a0,s2
    80005a26:	60be                	ld	ra,456(sp)
    80005a28:	641e                	ld	s0,448(sp)
    80005a2a:	74fa                	ld	s1,440(sp)
    80005a2c:	795a                	ld	s2,432(sp)
    80005a2e:	79ba                	ld	s3,424(sp)
    80005a30:	7a1a                	ld	s4,416(sp)
    80005a32:	6afa                	ld	s5,408(sp)
    80005a34:	6179                	addi	sp,sp,464
    80005a36:	8082                	ret

0000000080005a38 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a38:	7139                	addi	sp,sp,-64
    80005a3a:	fc06                	sd	ra,56(sp)
    80005a3c:	f822                	sd	s0,48(sp)
    80005a3e:	f426                	sd	s1,40(sp)
    80005a40:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a42:	ffffc097          	auipc	ra,0xffffc
    80005a46:	f6e080e7          	jalr	-146(ra) # 800019b0 <myproc>
    80005a4a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005a4c:	fd840593          	addi	a1,s0,-40
    80005a50:	4501                	li	a0,0
    80005a52:	ffffd097          	auipc	ra,0xffffd
    80005a56:	02c080e7          	jalr	44(ra) # 80002a7e <argaddr>
    return -1;
    80005a5a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005a5c:	0e054063          	bltz	a0,80005b3c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005a60:	fc840593          	addi	a1,s0,-56
    80005a64:	fd040513          	addi	a0,s0,-48
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	dfc080e7          	jalr	-516(ra) # 80004864 <pipealloc>
    return -1;
    80005a70:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005a72:	0c054563          	bltz	a0,80005b3c <sys_pipe+0x104>
  fd0 = -1;
    80005a76:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a7a:	fd043503          	ld	a0,-48(s0)
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	508080e7          	jalr	1288(ra) # 80004f86 <fdalloc>
    80005a86:	fca42223          	sw	a0,-60(s0)
    80005a8a:	08054c63          	bltz	a0,80005b22 <sys_pipe+0xea>
    80005a8e:	fc843503          	ld	a0,-56(s0)
    80005a92:	fffff097          	auipc	ra,0xfffff
    80005a96:	4f4080e7          	jalr	1268(ra) # 80004f86 <fdalloc>
    80005a9a:	fca42023          	sw	a0,-64(s0)
    80005a9e:	06054863          	bltz	a0,80005b0e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005aa2:	4691                	li	a3,4
    80005aa4:	fc440613          	addi	a2,s0,-60
    80005aa8:	fd843583          	ld	a1,-40(s0)
    80005aac:	68a8                	ld	a0,80(s1)
    80005aae:	ffffc097          	auipc	ra,0xffffc
    80005ab2:	bc4080e7          	jalr	-1084(ra) # 80001672 <copyout>
    80005ab6:	02054063          	bltz	a0,80005ad6 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005aba:	4691                	li	a3,4
    80005abc:	fc040613          	addi	a2,s0,-64
    80005ac0:	fd843583          	ld	a1,-40(s0)
    80005ac4:	0591                	addi	a1,a1,4
    80005ac6:	68a8                	ld	a0,80(s1)
    80005ac8:	ffffc097          	auipc	ra,0xffffc
    80005acc:	baa080e7          	jalr	-1110(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ad0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ad2:	06055563          	bgez	a0,80005b3c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005ad6:	fc442783          	lw	a5,-60(s0)
    80005ada:	07e9                	addi	a5,a5,26
    80005adc:	078e                	slli	a5,a5,0x3
    80005ade:	97a6                	add	a5,a5,s1
    80005ae0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ae4:	fc042503          	lw	a0,-64(s0)
    80005ae8:	0569                	addi	a0,a0,26
    80005aea:	050e                	slli	a0,a0,0x3
    80005aec:	9526                	add	a0,a0,s1
    80005aee:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005af2:	fd043503          	ld	a0,-48(s0)
    80005af6:	fffff097          	auipc	ra,0xfffff
    80005afa:	a3e080e7          	jalr	-1474(ra) # 80004534 <fileclose>
    fileclose(wf);
    80005afe:	fc843503          	ld	a0,-56(s0)
    80005b02:	fffff097          	auipc	ra,0xfffff
    80005b06:	a32080e7          	jalr	-1486(ra) # 80004534 <fileclose>
    return -1;
    80005b0a:	57fd                	li	a5,-1
    80005b0c:	a805                	j	80005b3c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b0e:	fc442783          	lw	a5,-60(s0)
    80005b12:	0007c863          	bltz	a5,80005b22 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b16:	01a78513          	addi	a0,a5,26
    80005b1a:	050e                	slli	a0,a0,0x3
    80005b1c:	9526                	add	a0,a0,s1
    80005b1e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b22:	fd043503          	ld	a0,-48(s0)
    80005b26:	fffff097          	auipc	ra,0xfffff
    80005b2a:	a0e080e7          	jalr	-1522(ra) # 80004534 <fileclose>
    fileclose(wf);
    80005b2e:	fc843503          	ld	a0,-56(s0)
    80005b32:	fffff097          	auipc	ra,0xfffff
    80005b36:	a02080e7          	jalr	-1534(ra) # 80004534 <fileclose>
    return -1;
    80005b3a:	57fd                	li	a5,-1
}
    80005b3c:	853e                	mv	a0,a5
    80005b3e:	70e2                	ld	ra,56(sp)
    80005b40:	7442                	ld	s0,48(sp)
    80005b42:	74a2                	ld	s1,40(sp)
    80005b44:	6121                	addi	sp,sp,64
    80005b46:	8082                	ret
	...

0000000080005b50 <kernelvec>:
    80005b50:	7111                	addi	sp,sp,-256
    80005b52:	e006                	sd	ra,0(sp)
    80005b54:	e40a                	sd	sp,8(sp)
    80005b56:	e80e                	sd	gp,16(sp)
    80005b58:	ec12                	sd	tp,24(sp)
    80005b5a:	f016                	sd	t0,32(sp)
    80005b5c:	f41a                	sd	t1,40(sp)
    80005b5e:	f81e                	sd	t2,48(sp)
    80005b60:	fc22                	sd	s0,56(sp)
    80005b62:	e0a6                	sd	s1,64(sp)
    80005b64:	e4aa                	sd	a0,72(sp)
    80005b66:	e8ae                	sd	a1,80(sp)
    80005b68:	ecb2                	sd	a2,88(sp)
    80005b6a:	f0b6                	sd	a3,96(sp)
    80005b6c:	f4ba                	sd	a4,104(sp)
    80005b6e:	f8be                	sd	a5,112(sp)
    80005b70:	fcc2                	sd	a6,120(sp)
    80005b72:	e146                	sd	a7,128(sp)
    80005b74:	e54a                	sd	s2,136(sp)
    80005b76:	e94e                	sd	s3,144(sp)
    80005b78:	ed52                	sd	s4,152(sp)
    80005b7a:	f156                	sd	s5,160(sp)
    80005b7c:	f55a                	sd	s6,168(sp)
    80005b7e:	f95e                	sd	s7,176(sp)
    80005b80:	fd62                	sd	s8,184(sp)
    80005b82:	e1e6                	sd	s9,192(sp)
    80005b84:	e5ea                	sd	s10,200(sp)
    80005b86:	e9ee                	sd	s11,208(sp)
    80005b88:	edf2                	sd	t3,216(sp)
    80005b8a:	f1f6                	sd	t4,224(sp)
    80005b8c:	f5fa                	sd	t5,232(sp)
    80005b8e:	f9fe                	sd	t6,240(sp)
    80005b90:	cfffc0ef          	jal	ra,8000288e <kerneltrap>
    80005b94:	6082                	ld	ra,0(sp)
    80005b96:	6122                	ld	sp,8(sp)
    80005b98:	61c2                	ld	gp,16(sp)
    80005b9a:	7282                	ld	t0,32(sp)
    80005b9c:	7322                	ld	t1,40(sp)
    80005b9e:	73c2                	ld	t2,48(sp)
    80005ba0:	7462                	ld	s0,56(sp)
    80005ba2:	6486                	ld	s1,64(sp)
    80005ba4:	6526                	ld	a0,72(sp)
    80005ba6:	65c6                	ld	a1,80(sp)
    80005ba8:	6666                	ld	a2,88(sp)
    80005baa:	7686                	ld	a3,96(sp)
    80005bac:	7726                	ld	a4,104(sp)
    80005bae:	77c6                	ld	a5,112(sp)
    80005bb0:	7866                	ld	a6,120(sp)
    80005bb2:	688a                	ld	a7,128(sp)
    80005bb4:	692a                	ld	s2,136(sp)
    80005bb6:	69ca                	ld	s3,144(sp)
    80005bb8:	6a6a                	ld	s4,152(sp)
    80005bba:	7a8a                	ld	s5,160(sp)
    80005bbc:	7b2a                	ld	s6,168(sp)
    80005bbe:	7bca                	ld	s7,176(sp)
    80005bc0:	7c6a                	ld	s8,184(sp)
    80005bc2:	6c8e                	ld	s9,192(sp)
    80005bc4:	6d2e                	ld	s10,200(sp)
    80005bc6:	6dce                	ld	s11,208(sp)
    80005bc8:	6e6e                	ld	t3,216(sp)
    80005bca:	7e8e                	ld	t4,224(sp)
    80005bcc:	7f2e                	ld	t5,232(sp)
    80005bce:	7fce                	ld	t6,240(sp)
    80005bd0:	6111                	addi	sp,sp,256
    80005bd2:	10200073          	sret
    80005bd6:	00000013          	nop
    80005bda:	00000013          	nop
    80005bde:	0001                	nop

0000000080005be0 <timervec>:
    80005be0:	34051573          	csrrw	a0,mscratch,a0
    80005be4:	e10c                	sd	a1,0(a0)
    80005be6:	e510                	sd	a2,8(a0)
    80005be8:	e914                	sd	a3,16(a0)
    80005bea:	6d0c                	ld	a1,24(a0)
    80005bec:	7110                	ld	a2,32(a0)
    80005bee:	6194                	ld	a3,0(a1)
    80005bf0:	96b2                	add	a3,a3,a2
    80005bf2:	e194                	sd	a3,0(a1)
    80005bf4:	4589                	li	a1,2
    80005bf6:	14459073          	csrw	sip,a1
    80005bfa:	6914                	ld	a3,16(a0)
    80005bfc:	6510                	ld	a2,8(a0)
    80005bfe:	610c                	ld	a1,0(a0)
    80005c00:	34051573          	csrrw	a0,mscratch,a0
    80005c04:	30200073          	mret
	...

0000000080005c0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c0a:	1141                	addi	sp,sp,-16
    80005c0c:	e422                	sd	s0,8(sp)
    80005c0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c10:	0c0007b7          	lui	a5,0xc000
    80005c14:	4705                	li	a4,1
    80005c16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c18:	c3d8                	sw	a4,4(a5)
}
    80005c1a:	6422                	ld	s0,8(sp)
    80005c1c:	0141                	addi	sp,sp,16
    80005c1e:	8082                	ret

0000000080005c20 <plicinithart>:

void
plicinithart(void)
{
    80005c20:	1141                	addi	sp,sp,-16
    80005c22:	e406                	sd	ra,8(sp)
    80005c24:	e022                	sd	s0,0(sp)
    80005c26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c28:	ffffc097          	auipc	ra,0xffffc
    80005c2c:	d5c080e7          	jalr	-676(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c30:	0085171b          	slliw	a4,a0,0x8
    80005c34:	0c0027b7          	lui	a5,0xc002
    80005c38:	97ba                	add	a5,a5,a4
    80005c3a:	40200713          	li	a4,1026
    80005c3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c42:	00d5151b          	slliw	a0,a0,0xd
    80005c46:	0c2017b7          	lui	a5,0xc201
    80005c4a:	953e                	add	a0,a0,a5
    80005c4c:	00052023          	sw	zero,0(a0)
}
    80005c50:	60a2                	ld	ra,8(sp)
    80005c52:	6402                	ld	s0,0(sp)
    80005c54:	0141                	addi	sp,sp,16
    80005c56:	8082                	ret

0000000080005c58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c58:	1141                	addi	sp,sp,-16
    80005c5a:	e406                	sd	ra,8(sp)
    80005c5c:	e022                	sd	s0,0(sp)
    80005c5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c60:	ffffc097          	auipc	ra,0xffffc
    80005c64:	d24080e7          	jalr	-732(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c68:	00d5179b          	slliw	a5,a0,0xd
    80005c6c:	0c201537          	lui	a0,0xc201
    80005c70:	953e                	add	a0,a0,a5
  return irq;
}
    80005c72:	4148                	lw	a0,4(a0)
    80005c74:	60a2                	ld	ra,8(sp)
    80005c76:	6402                	ld	s0,0(sp)
    80005c78:	0141                	addi	sp,sp,16
    80005c7a:	8082                	ret

0000000080005c7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c7c:	1101                	addi	sp,sp,-32
    80005c7e:	ec06                	sd	ra,24(sp)
    80005c80:	e822                	sd	s0,16(sp)
    80005c82:	e426                	sd	s1,8(sp)
    80005c84:	1000                	addi	s0,sp,32
    80005c86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c88:	ffffc097          	auipc	ra,0xffffc
    80005c8c:	cfc080e7          	jalr	-772(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c90:	00d5151b          	slliw	a0,a0,0xd
    80005c94:	0c2017b7          	lui	a5,0xc201
    80005c98:	97aa                	add	a5,a5,a0
    80005c9a:	c3c4                	sw	s1,4(a5)
}
    80005c9c:	60e2                	ld	ra,24(sp)
    80005c9e:	6442                	ld	s0,16(sp)
    80005ca0:	64a2                	ld	s1,8(sp)
    80005ca2:	6105                	addi	sp,sp,32
    80005ca4:	8082                	ret

0000000080005ca6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ca6:	1141                	addi	sp,sp,-16
    80005ca8:	e406                	sd	ra,8(sp)
    80005caa:	e022                	sd	s0,0(sp)
    80005cac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cae:	479d                	li	a5,7
    80005cb0:	06a7c963          	blt	a5,a0,80005d22 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005cb4:	0001d797          	auipc	a5,0x1d
    80005cb8:	34c78793          	addi	a5,a5,844 # 80023000 <disk>
    80005cbc:	00a78733          	add	a4,a5,a0
    80005cc0:	6789                	lui	a5,0x2
    80005cc2:	97ba                	add	a5,a5,a4
    80005cc4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005cc8:	e7ad                	bnez	a5,80005d32 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005cca:	00451793          	slli	a5,a0,0x4
    80005cce:	0001f717          	auipc	a4,0x1f
    80005cd2:	33270713          	addi	a4,a4,818 # 80025000 <disk+0x2000>
    80005cd6:	6314                	ld	a3,0(a4)
    80005cd8:	96be                	add	a3,a3,a5
    80005cda:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005cde:	6314                	ld	a3,0(a4)
    80005ce0:	96be                	add	a3,a3,a5
    80005ce2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005ce6:	6314                	ld	a3,0(a4)
    80005ce8:	96be                	add	a3,a3,a5
    80005cea:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005cee:	6318                	ld	a4,0(a4)
    80005cf0:	97ba                	add	a5,a5,a4
    80005cf2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005cf6:	0001d797          	auipc	a5,0x1d
    80005cfa:	30a78793          	addi	a5,a5,778 # 80023000 <disk>
    80005cfe:	97aa                	add	a5,a5,a0
    80005d00:	6509                	lui	a0,0x2
    80005d02:	953e                	add	a0,a0,a5
    80005d04:	4785                	li	a5,1
    80005d06:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d0a:	0001f517          	auipc	a0,0x1f
    80005d0e:	30e50513          	addi	a0,a0,782 # 80025018 <disk+0x2018>
    80005d12:	ffffc097          	auipc	ra,0xffffc
    80005d16:	4e6080e7          	jalr	1254(ra) # 800021f8 <wakeup>
}
    80005d1a:	60a2                	ld	ra,8(sp)
    80005d1c:	6402                	ld	s0,0(sp)
    80005d1e:	0141                	addi	sp,sp,16
    80005d20:	8082                	ret
    panic("free_desc 1");
    80005d22:	00003517          	auipc	a0,0x3
    80005d26:	a4650513          	addi	a0,a0,-1466 # 80008768 <syscalls+0x320>
    80005d2a:	ffffb097          	auipc	ra,0xffffb
    80005d2e:	814080e7          	jalr	-2028(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005d32:	00003517          	auipc	a0,0x3
    80005d36:	a4650513          	addi	a0,a0,-1466 # 80008778 <syscalls+0x330>
    80005d3a:	ffffb097          	auipc	ra,0xffffb
    80005d3e:	804080e7          	jalr	-2044(ra) # 8000053e <panic>

0000000080005d42 <virtio_disk_init>:
{
    80005d42:	1101                	addi	sp,sp,-32
    80005d44:	ec06                	sd	ra,24(sp)
    80005d46:	e822                	sd	s0,16(sp)
    80005d48:	e426                	sd	s1,8(sp)
    80005d4a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d4c:	00003597          	auipc	a1,0x3
    80005d50:	a3c58593          	addi	a1,a1,-1476 # 80008788 <syscalls+0x340>
    80005d54:	0001f517          	auipc	a0,0x1f
    80005d58:	3d450513          	addi	a0,a0,980 # 80025128 <disk+0x2128>
    80005d5c:	ffffb097          	auipc	ra,0xffffb
    80005d60:	df8080e7          	jalr	-520(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d64:	100017b7          	lui	a5,0x10001
    80005d68:	4398                	lw	a4,0(a5)
    80005d6a:	2701                	sext.w	a4,a4
    80005d6c:	747277b7          	lui	a5,0x74727
    80005d70:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d74:	0ef71163          	bne	a4,a5,80005e56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d78:	100017b7          	lui	a5,0x10001
    80005d7c:	43dc                	lw	a5,4(a5)
    80005d7e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d80:	4705                	li	a4,1
    80005d82:	0ce79a63          	bne	a5,a4,80005e56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d86:	100017b7          	lui	a5,0x10001
    80005d8a:	479c                	lw	a5,8(a5)
    80005d8c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d8e:	4709                	li	a4,2
    80005d90:	0ce79363          	bne	a5,a4,80005e56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d94:	100017b7          	lui	a5,0x10001
    80005d98:	47d8                	lw	a4,12(a5)
    80005d9a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d9c:	554d47b7          	lui	a5,0x554d4
    80005da0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005da4:	0af71963          	bne	a4,a5,80005e56 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005da8:	100017b7          	lui	a5,0x10001
    80005dac:	4705                	li	a4,1
    80005dae:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005db0:	470d                	li	a4,3
    80005db2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005db4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005db6:	c7ffe737          	lui	a4,0xc7ffe
    80005dba:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005dbe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005dc0:	2701                	sext.w	a4,a4
    80005dc2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dc4:	472d                	li	a4,11
    80005dc6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dc8:	473d                	li	a4,15
    80005dca:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005dcc:	6705                	lui	a4,0x1
    80005dce:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005dd0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005dd4:	5bdc                	lw	a5,52(a5)
    80005dd6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005dd8:	c7d9                	beqz	a5,80005e66 <virtio_disk_init+0x124>
  if(max < NUM)
    80005dda:	471d                	li	a4,7
    80005ddc:	08f77d63          	bgeu	a4,a5,80005e76 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005de0:	100014b7          	lui	s1,0x10001
    80005de4:	47a1                	li	a5,8
    80005de6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005de8:	6609                	lui	a2,0x2
    80005dea:	4581                	li	a1,0
    80005dec:	0001d517          	auipc	a0,0x1d
    80005df0:	21450513          	addi	a0,a0,532 # 80023000 <disk>
    80005df4:	ffffb097          	auipc	ra,0xffffb
    80005df8:	eec080e7          	jalr	-276(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005dfc:	0001d717          	auipc	a4,0x1d
    80005e00:	20470713          	addi	a4,a4,516 # 80023000 <disk>
    80005e04:	00c75793          	srli	a5,a4,0xc
    80005e08:	2781                	sext.w	a5,a5
    80005e0a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005e0c:	0001f797          	auipc	a5,0x1f
    80005e10:	1f478793          	addi	a5,a5,500 # 80025000 <disk+0x2000>
    80005e14:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005e16:	0001d717          	auipc	a4,0x1d
    80005e1a:	26a70713          	addi	a4,a4,618 # 80023080 <disk+0x80>
    80005e1e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005e20:	0001e717          	auipc	a4,0x1e
    80005e24:	1e070713          	addi	a4,a4,480 # 80024000 <disk+0x1000>
    80005e28:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e2a:	4705                	li	a4,1
    80005e2c:	00e78c23          	sb	a4,24(a5)
    80005e30:	00e78ca3          	sb	a4,25(a5)
    80005e34:	00e78d23          	sb	a4,26(a5)
    80005e38:	00e78da3          	sb	a4,27(a5)
    80005e3c:	00e78e23          	sb	a4,28(a5)
    80005e40:	00e78ea3          	sb	a4,29(a5)
    80005e44:	00e78f23          	sb	a4,30(a5)
    80005e48:	00e78fa3          	sb	a4,31(a5)
}
    80005e4c:	60e2                	ld	ra,24(sp)
    80005e4e:	6442                	ld	s0,16(sp)
    80005e50:	64a2                	ld	s1,8(sp)
    80005e52:	6105                	addi	sp,sp,32
    80005e54:	8082                	ret
    panic("could not find virtio disk");
    80005e56:	00003517          	auipc	a0,0x3
    80005e5a:	94250513          	addi	a0,a0,-1726 # 80008798 <syscalls+0x350>
    80005e5e:	ffffa097          	auipc	ra,0xffffa
    80005e62:	6e0080e7          	jalr	1760(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005e66:	00003517          	auipc	a0,0x3
    80005e6a:	95250513          	addi	a0,a0,-1710 # 800087b8 <syscalls+0x370>
    80005e6e:	ffffa097          	auipc	ra,0xffffa
    80005e72:	6d0080e7          	jalr	1744(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005e76:	00003517          	auipc	a0,0x3
    80005e7a:	96250513          	addi	a0,a0,-1694 # 800087d8 <syscalls+0x390>
    80005e7e:	ffffa097          	auipc	ra,0xffffa
    80005e82:	6c0080e7          	jalr	1728(ra) # 8000053e <panic>

0000000080005e86 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e86:	7159                	addi	sp,sp,-112
    80005e88:	f486                	sd	ra,104(sp)
    80005e8a:	f0a2                	sd	s0,96(sp)
    80005e8c:	eca6                	sd	s1,88(sp)
    80005e8e:	e8ca                	sd	s2,80(sp)
    80005e90:	e4ce                	sd	s3,72(sp)
    80005e92:	e0d2                	sd	s4,64(sp)
    80005e94:	fc56                	sd	s5,56(sp)
    80005e96:	f85a                	sd	s6,48(sp)
    80005e98:	f45e                	sd	s7,40(sp)
    80005e9a:	f062                	sd	s8,32(sp)
    80005e9c:	ec66                	sd	s9,24(sp)
    80005e9e:	e86a                	sd	s10,16(sp)
    80005ea0:	1880                	addi	s0,sp,112
    80005ea2:	892a                	mv	s2,a0
    80005ea4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005ea6:	00c52c83          	lw	s9,12(a0)
    80005eaa:	001c9c9b          	slliw	s9,s9,0x1
    80005eae:	1c82                	slli	s9,s9,0x20
    80005eb0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005eb4:	0001f517          	auipc	a0,0x1f
    80005eb8:	27450513          	addi	a0,a0,628 # 80025128 <disk+0x2128>
    80005ebc:	ffffb097          	auipc	ra,0xffffb
    80005ec0:	d28080e7          	jalr	-728(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005ec4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005ec6:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005ec8:	0001db97          	auipc	s7,0x1d
    80005ecc:	138b8b93          	addi	s7,s7,312 # 80023000 <disk>
    80005ed0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005ed2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005ed4:	8a4e                	mv	s4,s3
    80005ed6:	a051                	j	80005f5a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005ed8:	00fb86b3          	add	a3,s7,a5
    80005edc:	96da                	add	a3,a3,s6
    80005ede:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005ee2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005ee4:	0207c563          	bltz	a5,80005f0e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005ee8:	2485                	addiw	s1,s1,1
    80005eea:	0711                	addi	a4,a4,4
    80005eec:	25548063          	beq	s1,s5,8000612c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005ef0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005ef2:	0001f697          	auipc	a3,0x1f
    80005ef6:	12668693          	addi	a3,a3,294 # 80025018 <disk+0x2018>
    80005efa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005efc:	0006c583          	lbu	a1,0(a3)
    80005f00:	fde1                	bnez	a1,80005ed8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f02:	2785                	addiw	a5,a5,1
    80005f04:	0685                	addi	a3,a3,1
    80005f06:	ff879be3          	bne	a5,s8,80005efc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f0a:	57fd                	li	a5,-1
    80005f0c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005f0e:	02905a63          	blez	s1,80005f42 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f12:	f9042503          	lw	a0,-112(s0)
    80005f16:	00000097          	auipc	ra,0x0
    80005f1a:	d90080e7          	jalr	-624(ra) # 80005ca6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f1e:	4785                	li	a5,1
    80005f20:	0297d163          	bge	a5,s1,80005f42 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f24:	f9442503          	lw	a0,-108(s0)
    80005f28:	00000097          	auipc	ra,0x0
    80005f2c:	d7e080e7          	jalr	-642(ra) # 80005ca6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f30:	4789                	li	a5,2
    80005f32:	0097d863          	bge	a5,s1,80005f42 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f36:	f9842503          	lw	a0,-104(s0)
    80005f3a:	00000097          	auipc	ra,0x0
    80005f3e:	d6c080e7          	jalr	-660(ra) # 80005ca6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f42:	0001f597          	auipc	a1,0x1f
    80005f46:	1e658593          	addi	a1,a1,486 # 80025128 <disk+0x2128>
    80005f4a:	0001f517          	auipc	a0,0x1f
    80005f4e:	0ce50513          	addi	a0,a0,206 # 80025018 <disk+0x2018>
    80005f52:	ffffc097          	auipc	ra,0xffffc
    80005f56:	11a080e7          	jalr	282(ra) # 8000206c <sleep>
  for(int i = 0; i < 3; i++){
    80005f5a:	f9040713          	addi	a4,s0,-112
    80005f5e:	84ce                	mv	s1,s3
    80005f60:	bf41                	j	80005ef0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005f62:	20058713          	addi	a4,a1,512
    80005f66:	00471693          	slli	a3,a4,0x4
    80005f6a:	0001d717          	auipc	a4,0x1d
    80005f6e:	09670713          	addi	a4,a4,150 # 80023000 <disk>
    80005f72:	9736                	add	a4,a4,a3
    80005f74:	4685                	li	a3,1
    80005f76:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005f7a:	20058713          	addi	a4,a1,512
    80005f7e:	00471693          	slli	a3,a4,0x4
    80005f82:	0001d717          	auipc	a4,0x1d
    80005f86:	07e70713          	addi	a4,a4,126 # 80023000 <disk>
    80005f8a:	9736                	add	a4,a4,a3
    80005f8c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80005f90:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005f94:	7679                	lui	a2,0xffffe
    80005f96:	963e                	add	a2,a2,a5
    80005f98:	0001f697          	auipc	a3,0x1f
    80005f9c:	06868693          	addi	a3,a3,104 # 80025000 <disk+0x2000>
    80005fa0:	6298                	ld	a4,0(a3)
    80005fa2:	9732                	add	a4,a4,a2
    80005fa4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005fa6:	6298                	ld	a4,0(a3)
    80005fa8:	9732                	add	a4,a4,a2
    80005faa:	4541                	li	a0,16
    80005fac:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005fae:	6298                	ld	a4,0(a3)
    80005fb0:	9732                	add	a4,a4,a2
    80005fb2:	4505                	li	a0,1
    80005fb4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80005fb8:	f9442703          	lw	a4,-108(s0)
    80005fbc:	6288                	ld	a0,0(a3)
    80005fbe:	962a                	add	a2,a2,a0
    80005fc0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005fc4:	0712                	slli	a4,a4,0x4
    80005fc6:	6290                	ld	a2,0(a3)
    80005fc8:	963a                	add	a2,a2,a4
    80005fca:	05890513          	addi	a0,s2,88
    80005fce:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005fd0:	6294                	ld	a3,0(a3)
    80005fd2:	96ba                	add	a3,a3,a4
    80005fd4:	40000613          	li	a2,1024
    80005fd8:	c690                	sw	a2,8(a3)
  if(write)
    80005fda:	140d0063          	beqz	s10,8000611a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005fde:	0001f697          	auipc	a3,0x1f
    80005fe2:	0226b683          	ld	a3,34(a3) # 80025000 <disk+0x2000>
    80005fe6:	96ba                	add	a3,a3,a4
    80005fe8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fec:	0001d817          	auipc	a6,0x1d
    80005ff0:	01480813          	addi	a6,a6,20 # 80023000 <disk>
    80005ff4:	0001f517          	auipc	a0,0x1f
    80005ff8:	00c50513          	addi	a0,a0,12 # 80025000 <disk+0x2000>
    80005ffc:	6114                	ld	a3,0(a0)
    80005ffe:	96ba                	add	a3,a3,a4
    80006000:	00c6d603          	lhu	a2,12(a3)
    80006004:	00166613          	ori	a2,a2,1
    80006008:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000600c:	f9842683          	lw	a3,-104(s0)
    80006010:	6110                	ld	a2,0(a0)
    80006012:	9732                	add	a4,a4,a2
    80006014:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006018:	20058613          	addi	a2,a1,512
    8000601c:	0612                	slli	a2,a2,0x4
    8000601e:	9642                	add	a2,a2,a6
    80006020:	577d                	li	a4,-1
    80006022:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006026:	00469713          	slli	a4,a3,0x4
    8000602a:	6114                	ld	a3,0(a0)
    8000602c:	96ba                	add	a3,a3,a4
    8000602e:	03078793          	addi	a5,a5,48
    80006032:	97c2                	add	a5,a5,a6
    80006034:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006036:	611c                	ld	a5,0(a0)
    80006038:	97ba                	add	a5,a5,a4
    8000603a:	4685                	li	a3,1
    8000603c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000603e:	611c                	ld	a5,0(a0)
    80006040:	97ba                	add	a5,a5,a4
    80006042:	4809                	li	a6,2
    80006044:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006048:	611c                	ld	a5,0(a0)
    8000604a:	973e                	add	a4,a4,a5
    8000604c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006050:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006054:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006058:	6518                	ld	a4,8(a0)
    8000605a:	00275783          	lhu	a5,2(a4)
    8000605e:	8b9d                	andi	a5,a5,7
    80006060:	0786                	slli	a5,a5,0x1
    80006062:	97ba                	add	a5,a5,a4
    80006064:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006068:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000606c:	6518                	ld	a4,8(a0)
    8000606e:	00275783          	lhu	a5,2(a4)
    80006072:	2785                	addiw	a5,a5,1
    80006074:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006078:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000607c:	100017b7          	lui	a5,0x10001
    80006080:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006084:	00492703          	lw	a4,4(s2)
    80006088:	4785                	li	a5,1
    8000608a:	02f71163          	bne	a4,a5,800060ac <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000608e:	0001f997          	auipc	s3,0x1f
    80006092:	09a98993          	addi	s3,s3,154 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006096:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006098:	85ce                	mv	a1,s3
    8000609a:	854a                	mv	a0,s2
    8000609c:	ffffc097          	auipc	ra,0xffffc
    800060a0:	fd0080e7          	jalr	-48(ra) # 8000206c <sleep>
  while(b->disk == 1) {
    800060a4:	00492783          	lw	a5,4(s2)
    800060a8:	fe9788e3          	beq	a5,s1,80006098 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800060ac:	f9042903          	lw	s2,-112(s0)
    800060b0:	20090793          	addi	a5,s2,512
    800060b4:	00479713          	slli	a4,a5,0x4
    800060b8:	0001d797          	auipc	a5,0x1d
    800060bc:	f4878793          	addi	a5,a5,-184 # 80023000 <disk>
    800060c0:	97ba                	add	a5,a5,a4
    800060c2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800060c6:	0001f997          	auipc	s3,0x1f
    800060ca:	f3a98993          	addi	s3,s3,-198 # 80025000 <disk+0x2000>
    800060ce:	00491713          	slli	a4,s2,0x4
    800060d2:	0009b783          	ld	a5,0(s3)
    800060d6:	97ba                	add	a5,a5,a4
    800060d8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800060dc:	854a                	mv	a0,s2
    800060de:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800060e2:	00000097          	auipc	ra,0x0
    800060e6:	bc4080e7          	jalr	-1084(ra) # 80005ca6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800060ea:	8885                	andi	s1,s1,1
    800060ec:	f0ed                	bnez	s1,800060ce <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060ee:	0001f517          	auipc	a0,0x1f
    800060f2:	03a50513          	addi	a0,a0,58 # 80025128 <disk+0x2128>
    800060f6:	ffffb097          	auipc	ra,0xffffb
    800060fa:	ba2080e7          	jalr	-1118(ra) # 80000c98 <release>
}
    800060fe:	70a6                	ld	ra,104(sp)
    80006100:	7406                	ld	s0,96(sp)
    80006102:	64e6                	ld	s1,88(sp)
    80006104:	6946                	ld	s2,80(sp)
    80006106:	69a6                	ld	s3,72(sp)
    80006108:	6a06                	ld	s4,64(sp)
    8000610a:	7ae2                	ld	s5,56(sp)
    8000610c:	7b42                	ld	s6,48(sp)
    8000610e:	7ba2                	ld	s7,40(sp)
    80006110:	7c02                	ld	s8,32(sp)
    80006112:	6ce2                	ld	s9,24(sp)
    80006114:	6d42                	ld	s10,16(sp)
    80006116:	6165                	addi	sp,sp,112
    80006118:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000611a:	0001f697          	auipc	a3,0x1f
    8000611e:	ee66b683          	ld	a3,-282(a3) # 80025000 <disk+0x2000>
    80006122:	96ba                	add	a3,a3,a4
    80006124:	4609                	li	a2,2
    80006126:	00c69623          	sh	a2,12(a3)
    8000612a:	b5c9                	j	80005fec <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000612c:	f9042583          	lw	a1,-112(s0)
    80006130:	20058793          	addi	a5,a1,512
    80006134:	0792                	slli	a5,a5,0x4
    80006136:	0001d517          	auipc	a0,0x1d
    8000613a:	f7250513          	addi	a0,a0,-142 # 800230a8 <disk+0xa8>
    8000613e:	953e                	add	a0,a0,a5
  if(write)
    80006140:	e20d11e3          	bnez	s10,80005f62 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006144:	20058713          	addi	a4,a1,512
    80006148:	00471693          	slli	a3,a4,0x4
    8000614c:	0001d717          	auipc	a4,0x1d
    80006150:	eb470713          	addi	a4,a4,-332 # 80023000 <disk>
    80006154:	9736                	add	a4,a4,a3
    80006156:	0a072423          	sw	zero,168(a4)
    8000615a:	b505                	j	80005f7a <virtio_disk_rw+0xf4>

000000008000615c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000615c:	1101                	addi	sp,sp,-32
    8000615e:	ec06                	sd	ra,24(sp)
    80006160:	e822                	sd	s0,16(sp)
    80006162:	e426                	sd	s1,8(sp)
    80006164:	e04a                	sd	s2,0(sp)
    80006166:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006168:	0001f517          	auipc	a0,0x1f
    8000616c:	fc050513          	addi	a0,a0,-64 # 80025128 <disk+0x2128>
    80006170:	ffffb097          	auipc	ra,0xffffb
    80006174:	a74080e7          	jalr	-1420(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006178:	10001737          	lui	a4,0x10001
    8000617c:	533c                	lw	a5,96(a4)
    8000617e:	8b8d                	andi	a5,a5,3
    80006180:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006182:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006186:	0001f797          	auipc	a5,0x1f
    8000618a:	e7a78793          	addi	a5,a5,-390 # 80025000 <disk+0x2000>
    8000618e:	6b94                	ld	a3,16(a5)
    80006190:	0207d703          	lhu	a4,32(a5)
    80006194:	0026d783          	lhu	a5,2(a3)
    80006198:	06f70163          	beq	a4,a5,800061fa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000619c:	0001d917          	auipc	s2,0x1d
    800061a0:	e6490913          	addi	s2,s2,-412 # 80023000 <disk>
    800061a4:	0001f497          	auipc	s1,0x1f
    800061a8:	e5c48493          	addi	s1,s1,-420 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800061ac:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061b0:	6898                	ld	a4,16(s1)
    800061b2:	0204d783          	lhu	a5,32(s1)
    800061b6:	8b9d                	andi	a5,a5,7
    800061b8:	078e                	slli	a5,a5,0x3
    800061ba:	97ba                	add	a5,a5,a4
    800061bc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800061be:	20078713          	addi	a4,a5,512
    800061c2:	0712                	slli	a4,a4,0x4
    800061c4:	974a                	add	a4,a4,s2
    800061c6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800061ca:	e731                	bnez	a4,80006216 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800061cc:	20078793          	addi	a5,a5,512
    800061d0:	0792                	slli	a5,a5,0x4
    800061d2:	97ca                	add	a5,a5,s2
    800061d4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800061d6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800061da:	ffffc097          	auipc	ra,0xffffc
    800061de:	01e080e7          	jalr	30(ra) # 800021f8 <wakeup>

    disk.used_idx += 1;
    800061e2:	0204d783          	lhu	a5,32(s1)
    800061e6:	2785                	addiw	a5,a5,1
    800061e8:	17c2                	slli	a5,a5,0x30
    800061ea:	93c1                	srli	a5,a5,0x30
    800061ec:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800061f0:	6898                	ld	a4,16(s1)
    800061f2:	00275703          	lhu	a4,2(a4)
    800061f6:	faf71be3          	bne	a4,a5,800061ac <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800061fa:	0001f517          	auipc	a0,0x1f
    800061fe:	f2e50513          	addi	a0,a0,-210 # 80025128 <disk+0x2128>
    80006202:	ffffb097          	auipc	ra,0xffffb
    80006206:	a96080e7          	jalr	-1386(ra) # 80000c98 <release>
}
    8000620a:	60e2                	ld	ra,24(sp)
    8000620c:	6442                	ld	s0,16(sp)
    8000620e:	64a2                	ld	s1,8(sp)
    80006210:	6902                	ld	s2,0(sp)
    80006212:	6105                	addi	sp,sp,32
    80006214:	8082                	ret
      panic("virtio_disk_intr status");
    80006216:	00002517          	auipc	a0,0x2
    8000621a:	5e250513          	addi	a0,a0,1506 # 800087f8 <syscalls+0x3b0>
    8000621e:	ffffa097          	auipc	ra,0xffffa
    80006222:	320080e7          	jalr	800(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
