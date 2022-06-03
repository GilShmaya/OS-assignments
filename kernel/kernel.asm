
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
    80000068:	bac78793          	addi	a5,a5,-1108 # 80005c10 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffb87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	edc78793          	addi	a5,a5,-292 # 80000f8a <main>
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
    80000130:	436080e7          	jalr	1078(ra) # 80002562 <either_copyin>
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
    80000198:	b4c080e7          	jalr	-1204(ra) # 80000ce0 <acquire>
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
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	8e8080e7          	jalr	-1816(ra) # 80001aac <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	f94080e7          	jalr	-108(ra) # 80002168 <sleep>
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
    80000214:	2fc080e7          	jalr	764(ra) # 8000250c <either_copyout>
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
    80000230:	b68080e7          	jalr	-1176(ra) # 80000d94 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	b52080e7          	jalr	-1198(ra) # 80000d94 <release>
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
    800002d8:	a0c080e7          	jalr	-1524(ra) # 80000ce0 <acquire>

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
    800002f6:	2c6080e7          	jalr	710(ra) # 800025b8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	a92080e7          	jalr	-1390(ra) # 80000d94 <release>
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
    8000044a:	eae080e7          	jalr	-338(ra) # 800022f4 <wakeup>
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
    8000046c:	7e8080e7          	jalr	2024(ra) # 80000c50 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00041797          	auipc	a5,0x41
    8000047c:	ea078793          	addi	a5,a5,-352 # 80041318 <devsw>
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
    80000604:	6e0080e7          	jalr	1760(ra) # 80000ce0 <acquire>
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
    80000768:	630080e7          	jalr	1584(ra) # 80000d94 <release>
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
    8000078e:	4c6080e7          	jalr	1222(ra) # 80000c50 <initlock>
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
    800007e4:	470080e7          	jalr	1136(ra) # 80000c50 <initlock>
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
    80000800:	498080e7          	jalr	1176(ra) # 80000c94 <push_off>

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
    80000832:	506080e7          	jalr	1286(ra) # 80000d34 <pop_off>
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
    800008a4:	a54080e7          	jalr	-1452(ra) # 800022f4 <wakeup>
    
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
    800008e8:	3fc080e7          	jalr	1020(ra) # 80000ce0 <acquire>
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
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	83c080e7          	jalr	-1988(ra) # 80002168 <sleep>
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
    8000096c:	42c080e7          	jalr	1068(ra) # 80000d94 <release>
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
    800009d8:	30c080e7          	jalr	780(ra) # 80000ce0 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	3ae080e7          	jalr	942(ra) # 80000d94 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <get_reference_index>:

  return (void*)r;
}

uint64
get_reference_index(uint64 pa){
    800009f8:	1141                	addi	sp,sp,-16
    800009fa:	e422                	sd	s0,8(sp)
    800009fc:	0800                	addi	s0,sp,16
  return (pa - KERNBASE) / PGSIZE;
    800009fe:	800007b7          	lui	a5,0x80000
    80000a02:	953e                	add	a0,a0,a5
}
    80000a04:	8131                	srli	a0,a0,0xc
    80000a06:	6422                	ld	s0,8(sp)
    80000a08:	0141                	addi	sp,sp,16
    80000a0a:	8082                	ret

0000000080000a0c <decrease_reference>:

int
decrease_reference(uint64 pa)
{
    80000a0c:	7179                	addi	sp,sp,-48
    80000a0e:	f406                	sd	ra,40(sp)
    80000a10:	f022                	sd	s0,32(sp)
    80000a12:	ec26                	sd	s1,24(sp)
    80000a14:	e84a                	sd	s2,16(sp)
    80000a16:	e44e                	sd	s3,8(sp)
    80000a18:	1800                	addi	s0,sp,48
  return (pa - KERNBASE) / PGSIZE;
    80000a1a:	80000937          	lui	s2,0x80000
    80000a1e:	992a                	add	s2,s2,a0
    80000a20:	00c95913          	srli	s2,s2,0xc
  int reference;
  do {
    reference = references[get_reference_index((uint64)pa)];
  } while(cas(&references[get_reference_index((uint64)pa)], reference, reference - 1));
    80000a24:	00291993          	slli	s3,s2,0x2
    80000a28:	00011797          	auipc	a5,0x11
    80000a2c:	87878793          	addi	a5,a5,-1928 # 800112a0 <references>
    80000a30:	99be                	add	s3,s3,a5
    reference = references[get_reference_index((uint64)pa)];
    80000a32:	894e                	mv	s2,s3
    80000a34:	00092583          	lw	a1,0(s2) # ffffffff80000000 <end+0xfffffffefffba000>
  } while(cas(&references[get_reference_index((uint64)pa)], reference, reference - 1));
    80000a38:	fff5849b          	addiw	s1,a1,-1
    80000a3c:	8626                	mv	a2,s1
    80000a3e:	854e                	mv	a0,s3
    80000a40:	00006097          	auipc	ra,0x6
    80000a44:	816080e7          	jalr	-2026(ra) # 80006256 <cas>
    80000a48:	2501                	sext.w	a0,a0
    80000a4a:	f56d                	bnez	a0,80000a34 <decrease_reference+0x28>
  return reference - 1;
}
    80000a4c:	8526                	mv	a0,s1
    80000a4e:	70a2                	ld	ra,40(sp)
    80000a50:	7402                	ld	s0,32(sp)
    80000a52:	64e2                	ld	s1,24(sp)
    80000a54:	6942                	ld	s2,16(sp)
    80000a56:	69a2                	ld	s3,8(sp)
    80000a58:	6145                	addi	sp,sp,48
    80000a5a:	8082                	ret

0000000080000a5c <kfree>:
{
    80000a5c:	1101                	addi	sp,sp,-32
    80000a5e:	ec06                	sd	ra,24(sp)
    80000a60:	e822                	sd	s0,16(sp)
    80000a62:	e426                	sd	s1,8(sp)
    80000a64:	e04a                	sd	s2,0(sp)
    80000a66:	1000                	addi	s0,sp,32
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a68:	03451793          	slli	a5,a0,0x34
    80000a6c:	eb85                	bnez	a5,80000a9c <kfree+0x40>
    80000a6e:	84aa                	mv	s1,a0
    80000a70:	00045797          	auipc	a5,0x45
    80000a74:	59078793          	addi	a5,a5,1424 # 80046000 <end>
    80000a78:	02f56263          	bltu	a0,a5,80000a9c <kfree+0x40>
    80000a7c:	47c5                	li	a5,17
    80000a7e:	07ee                	slli	a5,a5,0x1b
    80000a80:	00f57e63          	bgeu	a0,a5,80000a9c <kfree+0x40>
  if(decrease_reference((uint64)pa) > 0) // check if there are still references to the page after removing one. Continue if there are.
    80000a84:	00000097          	auipc	ra,0x0
    80000a88:	f88080e7          	jalr	-120(ra) # 80000a0c <decrease_reference>
    80000a8c:	02a05063          	blez	a0,80000aac <kfree+0x50>
}
    80000a90:	60e2                	ld	ra,24(sp)
    80000a92:	6442                	ld	s0,16(sp)
    80000a94:	64a2                	ld	s1,8(sp)
    80000a96:	6902                	ld	s2,0(sp)
    80000a98:	6105                	addi	sp,sp,32
    80000a9a:	8082                	ret
    panic("kfree");
    80000a9c:	00007517          	auipc	a0,0x7
    80000aa0:	5c450513          	addi	a0,a0,1476 # 80008060 <digits+0x20>
    80000aa4:	00000097          	auipc	ra,0x0
    80000aa8:	a9a080e7          	jalr	-1382(ra) # 8000053e <panic>
  return (pa - KERNBASE) / PGSIZE;
    80000aac:	800007b7          	lui	a5,0x80000
    80000ab0:	97a6                	add	a5,a5,s1
    80000ab2:	83b1                	srli	a5,a5,0xc
  references[get_reference_index((uint64)pa)] = 0; // initialize references of the page address
    80000ab4:	078a                	slli	a5,a5,0x2
    80000ab6:	00010717          	auipc	a4,0x10
    80000aba:	7ea70713          	addi	a4,a4,2026 # 800112a0 <references>
    80000abe:	97ba                	add	a5,a5,a4
    80000ac0:	0007a023          	sw	zero,0(a5) # ffffffff80000000 <end+0xfffffffefffba000>
  memset(pa, 1, PGSIZE);
    80000ac4:	6605                	lui	a2,0x1
    80000ac6:	4585                	li	a1,1
    80000ac8:	8526                	mv	a0,s1
    80000aca:	00000097          	auipc	ra,0x0
    80000ace:	312080e7          	jalr	786(ra) # 80000ddc <memset>
  acquire(&kmem.lock);
    80000ad2:	00010917          	auipc	s2,0x10
    80000ad6:	7ae90913          	addi	s2,s2,1966 # 80011280 <kmem>
    80000ada:	854a                	mv	a0,s2
    80000adc:	00000097          	auipc	ra,0x0
    80000ae0:	204080e7          	jalr	516(ra) # 80000ce0 <acquire>
  r->next = kmem.freelist;
    80000ae4:	01893783          	ld	a5,24(s2)
    80000ae8:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000aea:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000aee:	854a                	mv	a0,s2
    80000af0:	00000097          	auipc	ra,0x0
    80000af4:	2a4080e7          	jalr	676(ra) # 80000d94 <release>
    80000af8:	bf61                	j	80000a90 <kfree+0x34>

0000000080000afa <freerange>:
{
    80000afa:	7179                	addi	sp,sp,-48
    80000afc:	f406                	sd	ra,40(sp)
    80000afe:	f022                	sd	s0,32(sp)
    80000b00:	ec26                	sd	s1,24(sp)
    80000b02:	e84a                	sd	s2,16(sp)
    80000b04:	e44e                	sd	s3,8(sp)
    80000b06:	e052                	sd	s4,0(sp)
    80000b08:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b0a:	6785                	lui	a5,0x1
    80000b0c:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b10:	94aa                	add	s1,s1,a0
    80000b12:	757d                	lui	a0,0xfffff
    80000b14:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b16:	94be                	add	s1,s1,a5
    80000b18:	0095ee63          	bltu	a1,s1,80000b34 <freerange+0x3a>
    80000b1c:	892e                	mv	s2,a1
    kfree(p);
    80000b1e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b20:	6985                	lui	s3,0x1
    kfree(p);
    80000b22:	01448533          	add	a0,s1,s4
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	f36080e7          	jalr	-202(ra) # 80000a5c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b2e:	94ce                	add	s1,s1,s3
    80000b30:	fe9979e3          	bgeu	s2,s1,80000b22 <freerange+0x28>
}
    80000b34:	70a2                	ld	ra,40(sp)
    80000b36:	7402                	ld	s0,32(sp)
    80000b38:	64e2                	ld	s1,24(sp)
    80000b3a:	6942                	ld	s2,16(sp)
    80000b3c:	69a2                	ld	s3,8(sp)
    80000b3e:	6a02                	ld	s4,0(sp)
    80000b40:	6145                	addi	sp,sp,48
    80000b42:	8082                	ret

0000000080000b44 <kinit>:
{
    80000b44:	1141                	addi	sp,sp,-16
    80000b46:	e406                	sd	ra,8(sp)
    80000b48:	e022                	sd	s0,0(sp)
    80000b4a:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b4c:	00007597          	auipc	a1,0x7
    80000b50:	51c58593          	addi	a1,a1,1308 # 80008068 <digits+0x28>
    80000b54:	00010517          	auipc	a0,0x10
    80000b58:	72c50513          	addi	a0,a0,1836 # 80011280 <kmem>
    80000b5c:	00000097          	auipc	ra,0x0
    80000b60:	0f4080e7          	jalr	244(ra) # 80000c50 <initlock>
  memset(references, 0, sizeof(int)*NUM_PYS_PAGES);
    80000b64:	00020637          	lui	a2,0x20
    80000b68:	4581                	li	a1,0
    80000b6a:	00010517          	auipc	a0,0x10
    80000b6e:	73650513          	addi	a0,a0,1846 # 800112a0 <references>
    80000b72:	00000097          	auipc	ra,0x0
    80000b76:	26a080e7          	jalr	618(ra) # 80000ddc <memset>
  freerange(end, (void*)PHYSTOP);
    80000b7a:	45c5                	li	a1,17
    80000b7c:	05ee                	slli	a1,a1,0x1b
    80000b7e:	00045517          	auipc	a0,0x45
    80000b82:	48250513          	addi	a0,a0,1154 # 80046000 <end>
    80000b86:	00000097          	auipc	ra,0x0
    80000b8a:	f74080e7          	jalr	-140(ra) # 80000afa <freerange>
}
    80000b8e:	60a2                	ld	ra,8(sp)
    80000b90:	6402                	ld	s0,0(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <increase_reference>:

int
increase_reference(uint64 pa)
{
    80000b96:	7179                	addi	sp,sp,-48
    80000b98:	f406                	sd	ra,40(sp)
    80000b9a:	f022                	sd	s0,32(sp)
    80000b9c:	ec26                	sd	s1,24(sp)
    80000b9e:	e84a                	sd	s2,16(sp)
    80000ba0:	e44e                	sd	s3,8(sp)
    80000ba2:	1800                	addi	s0,sp,48
  return (pa - KERNBASE) / PGSIZE;
    80000ba4:	80000937          	lui	s2,0x80000
    80000ba8:	992a                	add	s2,s2,a0
    80000baa:	00c95913          	srli	s2,s2,0xc
  int reference;
  do {
    reference = references[get_reference_index((uint64)pa)];
  } while(cas(&references[get_reference_index((uint64)pa)], reference, reference + 1));
    80000bae:	00291993          	slli	s3,s2,0x2
    80000bb2:	00010797          	auipc	a5,0x10
    80000bb6:	6ee78793          	addi	a5,a5,1774 # 800112a0 <references>
    80000bba:	99be                	add	s3,s3,a5
    reference = references[get_reference_index((uint64)pa)];
    80000bbc:	894e                	mv	s2,s3
    80000bbe:	00092583          	lw	a1,0(s2) # ffffffff80000000 <end+0xfffffffefffba000>
  } while(cas(&references[get_reference_index((uint64)pa)], reference, reference + 1));
    80000bc2:	0015849b          	addiw	s1,a1,1
    80000bc6:	8626                	mv	a2,s1
    80000bc8:	854e                	mv	a0,s3
    80000bca:	00005097          	auipc	ra,0x5
    80000bce:	68c080e7          	jalr	1676(ra) # 80006256 <cas>
    80000bd2:	2501                	sext.w	a0,a0
    80000bd4:	f56d                	bnez	a0,80000bbe <increase_reference+0x28>
  return reference + 1;
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	70a2                	ld	ra,40(sp)
    80000bda:	7402                	ld	s0,32(sp)
    80000bdc:	64e2                	ld	s1,24(sp)
    80000bde:	6942                	ld	s2,16(sp)
    80000be0:	69a2                	ld	s3,8(sp)
    80000be2:	6145                	addi	sp,sp,48
    80000be4:	8082                	ret

0000000080000be6 <kalloc>:
{
    80000be6:	1101                	addi	sp,sp,-32
    80000be8:	ec06                	sd	ra,24(sp)
    80000bea:	e822                	sd	s0,16(sp)
    80000bec:	e426                	sd	s1,8(sp)
    80000bee:	1000                	addi	s0,sp,32
  acquire(&kmem.lock);
    80000bf0:	00010497          	auipc	s1,0x10
    80000bf4:	69048493          	addi	s1,s1,1680 # 80011280 <kmem>
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	0e6080e7          	jalr	230(ra) # 80000ce0 <acquire>
  r = kmem.freelist;
    80000c02:	6c84                	ld	s1,24(s1)
  if(r)
    80000c04:	cc8d                	beqz	s1,80000c3e <kalloc+0x58>
    kmem.freelist = r->next;
    80000c06:	609c                	ld	a5,0(s1)
    80000c08:	00010517          	auipc	a0,0x10
    80000c0c:	67850513          	addi	a0,a0,1656 # 80011280 <kmem>
    80000c10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000c12:	00000097          	auipc	ra,0x0
    80000c16:	182080e7          	jalr	386(ra) # 80000d94 <release>
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000c1a:	6605                	lui	a2,0x1
    80000c1c:	4595                	li	a1,5
    80000c1e:	8526                	mv	a0,s1
    80000c20:	00000097          	auipc	ra,0x0
    80000c24:	1bc080e7          	jalr	444(ra) # 80000ddc <memset>
    increase_reference((uint64)r); // references[index of r] = 1
    80000c28:	8526                	mv	a0,s1
    80000c2a:	00000097          	auipc	ra,0x0
    80000c2e:	f6c080e7          	jalr	-148(ra) # 80000b96 <increase_reference>
}
    80000c32:	8526                	mv	a0,s1
    80000c34:	60e2                	ld	ra,24(sp)
    80000c36:	6442                	ld	s0,16(sp)
    80000c38:	64a2                	ld	s1,8(sp)
    80000c3a:	6105                	addi	sp,sp,32
    80000c3c:	8082                	ret
  release(&kmem.lock);
    80000c3e:	00010517          	auipc	a0,0x10
    80000c42:	64250513          	addi	a0,a0,1602 # 80011280 <kmem>
    80000c46:	00000097          	auipc	ra,0x0
    80000c4a:	14e080e7          	jalr	334(ra) # 80000d94 <release>
  if(r)
    80000c4e:	b7d5                	j	80000c32 <kalloc+0x4c>

0000000080000c50 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c50:	1141                	addi	sp,sp,-16
    80000c52:	e422                	sd	s0,8(sp)
    80000c54:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c56:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c58:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c5c:	00053823          	sd	zero,16(a0)
}
    80000c60:	6422                	ld	s0,8(sp)
    80000c62:	0141                	addi	sp,sp,16
    80000c64:	8082                	ret

0000000080000c66 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c66:	411c                	lw	a5,0(a0)
    80000c68:	e399                	bnez	a5,80000c6e <holding+0x8>
    80000c6a:	4501                	li	a0,0
  return r;
}
    80000c6c:	8082                	ret
{
    80000c6e:	1101                	addi	sp,sp,-32
    80000c70:	ec06                	sd	ra,24(sp)
    80000c72:	e822                	sd	s0,16(sp)
    80000c74:	e426                	sd	s1,8(sp)
    80000c76:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c78:	6904                	ld	s1,16(a0)
    80000c7a:	00001097          	auipc	ra,0x1
    80000c7e:	e16080e7          	jalr	-490(ra) # 80001a90 <mycpu>
    80000c82:	40a48533          	sub	a0,s1,a0
    80000c86:	00153513          	seqz	a0,a0
}
    80000c8a:	60e2                	ld	ra,24(sp)
    80000c8c:	6442                	ld	s0,16(sp)
    80000c8e:	64a2                	ld	s1,8(sp)
    80000c90:	6105                	addi	sp,sp,32
    80000c92:	8082                	ret

0000000080000c94 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c94:	1101                	addi	sp,sp,-32
    80000c96:	ec06                	sd	ra,24(sp)
    80000c98:	e822                	sd	s0,16(sp)
    80000c9a:	e426                	sd	s1,8(sp)
    80000c9c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c9e:	100024f3          	csrr	s1,sstatus
    80000ca2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000ca6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ca8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cac:	00001097          	auipc	ra,0x1
    80000cb0:	de4080e7          	jalr	-540(ra) # 80001a90 <mycpu>
    80000cb4:	5d3c                	lw	a5,120(a0)
    80000cb6:	cf89                	beqz	a5,80000cd0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cb8:	00001097          	auipc	ra,0x1
    80000cbc:	dd8080e7          	jalr	-552(ra) # 80001a90 <mycpu>
    80000cc0:	5d3c                	lw	a5,120(a0)
    80000cc2:	2785                	addiw	a5,a5,1
    80000cc4:	dd3c                	sw	a5,120(a0)
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    mycpu()->intena = old;
    80000cd0:	00001097          	auipc	ra,0x1
    80000cd4:	dc0080e7          	jalr	-576(ra) # 80001a90 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cd8:	8085                	srli	s1,s1,0x1
    80000cda:	8885                	andi	s1,s1,1
    80000cdc:	dd64                	sw	s1,124(a0)
    80000cde:	bfe9                	j	80000cb8 <push_off+0x24>

0000000080000ce0 <acquire>:
{
    80000ce0:	1101                	addi	sp,sp,-32
    80000ce2:	ec06                	sd	ra,24(sp)
    80000ce4:	e822                	sd	s0,16(sp)
    80000ce6:	e426                	sd	s1,8(sp)
    80000ce8:	1000                	addi	s0,sp,32
    80000cea:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cec:	00000097          	auipc	ra,0x0
    80000cf0:	fa8080e7          	jalr	-88(ra) # 80000c94 <push_off>
  if(holding(lk))
    80000cf4:	8526                	mv	a0,s1
    80000cf6:	00000097          	auipc	ra,0x0
    80000cfa:	f70080e7          	jalr	-144(ra) # 80000c66 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cfe:	4705                	li	a4,1
  if(holding(lk))
    80000d00:	e115                	bnez	a0,80000d24 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d02:	87ba                	mv	a5,a4
    80000d04:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d08:	2781                	sext.w	a5,a5
    80000d0a:	ffe5                	bnez	a5,80000d02 <acquire+0x22>
  __sync_synchronize();
    80000d0c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d10:	00001097          	auipc	ra,0x1
    80000d14:	d80080e7          	jalr	-640(ra) # 80001a90 <mycpu>
    80000d18:	e888                	sd	a0,16(s1)
}
    80000d1a:	60e2                	ld	ra,24(sp)
    80000d1c:	6442                	ld	s0,16(sp)
    80000d1e:	64a2                	ld	s1,8(sp)
    80000d20:	6105                	addi	sp,sp,32
    80000d22:	8082                	ret
    panic("acquire");
    80000d24:	00007517          	auipc	a0,0x7
    80000d28:	34c50513          	addi	a0,a0,844 # 80008070 <digits+0x30>
    80000d2c:	00000097          	auipc	ra,0x0
    80000d30:	812080e7          	jalr	-2030(ra) # 8000053e <panic>

0000000080000d34 <pop_off>:

void
pop_off(void)
{
    80000d34:	1141                	addi	sp,sp,-16
    80000d36:	e406                	sd	ra,8(sp)
    80000d38:	e022                	sd	s0,0(sp)
    80000d3a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d3c:	00001097          	auipc	ra,0x1
    80000d40:	d54080e7          	jalr	-684(ra) # 80001a90 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d44:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d48:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d4a:	e78d                	bnez	a5,80000d74 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d4c:	5d3c                	lw	a5,120(a0)
    80000d4e:	02f05b63          	blez	a5,80000d84 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d52:	37fd                	addiw	a5,a5,-1
    80000d54:	0007871b          	sext.w	a4,a5
    80000d58:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d5a:	eb09                	bnez	a4,80000d6c <pop_off+0x38>
    80000d5c:	5d7c                	lw	a5,124(a0)
    80000d5e:	c799                	beqz	a5,80000d6c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d60:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d64:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d68:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d6c:	60a2                	ld	ra,8(sp)
    80000d6e:	6402                	ld	s0,0(sp)
    80000d70:	0141                	addi	sp,sp,16
    80000d72:	8082                	ret
    panic("pop_off - interruptible");
    80000d74:	00007517          	auipc	a0,0x7
    80000d78:	30450513          	addi	a0,a0,772 # 80008078 <digits+0x38>
    80000d7c:	fffff097          	auipc	ra,0xfffff
    80000d80:	7c2080e7          	jalr	1986(ra) # 8000053e <panic>
    panic("pop_off");
    80000d84:	00007517          	auipc	a0,0x7
    80000d88:	30c50513          	addi	a0,a0,780 # 80008090 <digits+0x50>
    80000d8c:	fffff097          	auipc	ra,0xfffff
    80000d90:	7b2080e7          	jalr	1970(ra) # 8000053e <panic>

0000000080000d94 <release>:
{
    80000d94:	1101                	addi	sp,sp,-32
    80000d96:	ec06                	sd	ra,24(sp)
    80000d98:	e822                	sd	s0,16(sp)
    80000d9a:	e426                	sd	s1,8(sp)
    80000d9c:	1000                	addi	s0,sp,32
    80000d9e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000da0:	00000097          	auipc	ra,0x0
    80000da4:	ec6080e7          	jalr	-314(ra) # 80000c66 <holding>
    80000da8:	c115                	beqz	a0,80000dcc <release+0x38>
  lk->cpu = 0;
    80000daa:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000dae:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000db2:	0f50000f          	fence	iorw,ow
    80000db6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000dba:	00000097          	auipc	ra,0x0
    80000dbe:	f7a080e7          	jalr	-134(ra) # 80000d34 <pop_off>
}
    80000dc2:	60e2                	ld	ra,24(sp)
    80000dc4:	6442                	ld	s0,16(sp)
    80000dc6:	64a2                	ld	s1,8(sp)
    80000dc8:	6105                	addi	sp,sp,32
    80000dca:	8082                	ret
    panic("release");
    80000dcc:	00007517          	auipc	a0,0x7
    80000dd0:	2cc50513          	addi	a0,a0,716 # 80008098 <digits+0x58>
    80000dd4:	fffff097          	auipc	ra,0xfffff
    80000dd8:	76a080e7          	jalr	1898(ra) # 8000053e <panic>

0000000080000ddc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ddc:	1141                	addi	sp,sp,-16
    80000dde:	e422                	sd	s0,8(sp)
    80000de0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000de2:	ce09                	beqz	a2,80000dfc <memset+0x20>
    80000de4:	87aa                	mv	a5,a0
    80000de6:	fff6071b          	addiw	a4,a2,-1
    80000dea:	1702                	slli	a4,a4,0x20
    80000dec:	9301                	srli	a4,a4,0x20
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000df2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000df6:	0785                	addi	a5,a5,1
    80000df8:	fee79de3          	bne	a5,a4,80000df2 <memset+0x16>
  }
  return dst;
}
    80000dfc:	6422                	ld	s0,8(sp)
    80000dfe:	0141                	addi	sp,sp,16
    80000e00:	8082                	ret

0000000080000e02 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e02:	1141                	addi	sp,sp,-16
    80000e04:	e422                	sd	s0,8(sp)
    80000e06:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e08:	ca05                	beqz	a2,80000e38 <memcmp+0x36>
    80000e0a:	fff6069b          	addiw	a3,a2,-1
    80000e0e:	1682                	slli	a3,a3,0x20
    80000e10:	9281                	srli	a3,a3,0x20
    80000e12:	0685                	addi	a3,a3,1
    80000e14:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e16:	00054783          	lbu	a5,0(a0)
    80000e1a:	0005c703          	lbu	a4,0(a1)
    80000e1e:	00e79863          	bne	a5,a4,80000e2e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e22:	0505                	addi	a0,a0,1
    80000e24:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e26:	fed518e3          	bne	a0,a3,80000e16 <memcmp+0x14>
  }

  return 0;
    80000e2a:	4501                	li	a0,0
    80000e2c:	a019                	j	80000e32 <memcmp+0x30>
      return *s1 - *s2;
    80000e2e:	40e7853b          	subw	a0,a5,a4
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret
  return 0;
    80000e38:	4501                	li	a0,0
    80000e3a:	bfe5                	j	80000e32 <memcmp+0x30>

0000000080000e3c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e3c:	1141                	addi	sp,sp,-16
    80000e3e:	e422                	sd	s0,8(sp)
    80000e40:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e42:	ca0d                	beqz	a2,80000e74 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e44:	00a5f963          	bgeu	a1,a0,80000e56 <memmove+0x1a>
    80000e48:	02061693          	slli	a3,a2,0x20
    80000e4c:	9281                	srli	a3,a3,0x20
    80000e4e:	00d58733          	add	a4,a1,a3
    80000e52:	02e56463          	bltu	a0,a4,80000e7a <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e56:	fff6079b          	addiw	a5,a2,-1
    80000e5a:	1782                	slli	a5,a5,0x20
    80000e5c:	9381                	srli	a5,a5,0x20
    80000e5e:	0785                	addi	a5,a5,1
    80000e60:	97ae                	add	a5,a5,a1
    80000e62:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e64:	0585                	addi	a1,a1,1
    80000e66:	0705                	addi	a4,a4,1
    80000e68:	fff5c683          	lbu	a3,-1(a1)
    80000e6c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e70:	fef59ae3          	bne	a1,a5,80000e64 <memmove+0x28>

  return dst;
}
    80000e74:	6422                	ld	s0,8(sp)
    80000e76:	0141                	addi	sp,sp,16
    80000e78:	8082                	ret
    d += n;
    80000e7a:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e7c:	fff6079b          	addiw	a5,a2,-1
    80000e80:	1782                	slli	a5,a5,0x20
    80000e82:	9381                	srli	a5,a5,0x20
    80000e84:	fff7c793          	not	a5,a5
    80000e88:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e8a:	177d                	addi	a4,a4,-1
    80000e8c:	16fd                	addi	a3,a3,-1
    80000e8e:	00074603          	lbu	a2,0(a4)
    80000e92:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e96:	fef71ae3          	bne	a4,a5,80000e8a <memmove+0x4e>
    80000e9a:	bfe9                	j	80000e74 <memmove+0x38>

0000000080000e9c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e9c:	1141                	addi	sp,sp,-16
    80000e9e:	e406                	sd	ra,8(sp)
    80000ea0:	e022                	sd	s0,0(sp)
    80000ea2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000ea4:	00000097          	auipc	ra,0x0
    80000ea8:	f98080e7          	jalr	-104(ra) # 80000e3c <memmove>
}
    80000eac:	60a2                	ld	ra,8(sp)
    80000eae:	6402                	ld	s0,0(sp)
    80000eb0:	0141                	addi	sp,sp,16
    80000eb2:	8082                	ret

0000000080000eb4 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000eb4:	1141                	addi	sp,sp,-16
    80000eb6:	e422                	sd	s0,8(sp)
    80000eb8:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000eba:	ce11                	beqz	a2,80000ed6 <strncmp+0x22>
    80000ebc:	00054783          	lbu	a5,0(a0)
    80000ec0:	cf89                	beqz	a5,80000eda <strncmp+0x26>
    80000ec2:	0005c703          	lbu	a4,0(a1)
    80000ec6:	00f71a63          	bne	a4,a5,80000eda <strncmp+0x26>
    n--, p++, q++;
    80000eca:	367d                	addiw	a2,a2,-1
    80000ecc:	0505                	addi	a0,a0,1
    80000ece:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000ed0:	f675                	bnez	a2,80000ebc <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ed2:	4501                	li	a0,0
    80000ed4:	a809                	j	80000ee6 <strncmp+0x32>
    80000ed6:	4501                	li	a0,0
    80000ed8:	a039                	j	80000ee6 <strncmp+0x32>
  if(n == 0)
    80000eda:	ca09                	beqz	a2,80000eec <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000edc:	00054503          	lbu	a0,0(a0)
    80000ee0:	0005c783          	lbu	a5,0(a1)
    80000ee4:	9d1d                	subw	a0,a0,a5
}
    80000ee6:	6422                	ld	s0,8(sp)
    80000ee8:	0141                	addi	sp,sp,16
    80000eea:	8082                	ret
    return 0;
    80000eec:	4501                	li	a0,0
    80000eee:	bfe5                	j	80000ee6 <strncmp+0x32>

0000000080000ef0 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000ef0:	1141                	addi	sp,sp,-16
    80000ef2:	e422                	sd	s0,8(sp)
    80000ef4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000ef6:	872a                	mv	a4,a0
    80000ef8:	8832                	mv	a6,a2
    80000efa:	367d                	addiw	a2,a2,-1
    80000efc:	01005963          	blez	a6,80000f0e <strncpy+0x1e>
    80000f00:	0705                	addi	a4,a4,1
    80000f02:	0005c783          	lbu	a5,0(a1)
    80000f06:	fef70fa3          	sb	a5,-1(a4)
    80000f0a:	0585                	addi	a1,a1,1
    80000f0c:	f7f5                	bnez	a5,80000ef8 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f0e:	00c05d63          	blez	a2,80000f28 <strncpy+0x38>
    80000f12:	86ba                	mv	a3,a4
    *s++ = 0;
    80000f14:	0685                	addi	a3,a3,1
    80000f16:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f1a:	fff6c793          	not	a5,a3
    80000f1e:	9fb9                	addw	a5,a5,a4
    80000f20:	010787bb          	addw	a5,a5,a6
    80000f24:	fef048e3          	bgtz	a5,80000f14 <strncpy+0x24>
  return os;
}
    80000f28:	6422                	ld	s0,8(sp)
    80000f2a:	0141                	addi	sp,sp,16
    80000f2c:	8082                	ret

0000000080000f2e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f2e:	1141                	addi	sp,sp,-16
    80000f30:	e422                	sd	s0,8(sp)
    80000f32:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f34:	02c05363          	blez	a2,80000f5a <safestrcpy+0x2c>
    80000f38:	fff6069b          	addiw	a3,a2,-1
    80000f3c:	1682                	slli	a3,a3,0x20
    80000f3e:	9281                	srli	a3,a3,0x20
    80000f40:	96ae                	add	a3,a3,a1
    80000f42:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f44:	00d58963          	beq	a1,a3,80000f56 <safestrcpy+0x28>
    80000f48:	0585                	addi	a1,a1,1
    80000f4a:	0785                	addi	a5,a5,1
    80000f4c:	fff5c703          	lbu	a4,-1(a1)
    80000f50:	fee78fa3          	sb	a4,-1(a5)
    80000f54:	fb65                	bnez	a4,80000f44 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f56:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f5a:	6422                	ld	s0,8(sp)
    80000f5c:	0141                	addi	sp,sp,16
    80000f5e:	8082                	ret

0000000080000f60 <strlen>:

int
strlen(const char *s)
{
    80000f60:	1141                	addi	sp,sp,-16
    80000f62:	e422                	sd	s0,8(sp)
    80000f64:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f66:	00054783          	lbu	a5,0(a0)
    80000f6a:	cf91                	beqz	a5,80000f86 <strlen+0x26>
    80000f6c:	0505                	addi	a0,a0,1
    80000f6e:	87aa                	mv	a5,a0
    80000f70:	4685                	li	a3,1
    80000f72:	9e89                	subw	a3,a3,a0
    80000f74:	00f6853b          	addw	a0,a3,a5
    80000f78:	0785                	addi	a5,a5,1
    80000f7a:	fff7c703          	lbu	a4,-1(a5)
    80000f7e:	fb7d                	bnez	a4,80000f74 <strlen+0x14>
    ;
  return n;
}
    80000f80:	6422                	ld	s0,8(sp)
    80000f82:	0141                	addi	sp,sp,16
    80000f84:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f86:	4501                	li	a0,0
    80000f88:	bfe5                	j	80000f80 <strlen+0x20>

0000000080000f8a <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f8a:	1141                	addi	sp,sp,-16
    80000f8c:	e406                	sd	ra,8(sp)
    80000f8e:	e022                	sd	s0,0(sp)
    80000f90:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	aee080e7          	jalr	-1298(ra) # 80001a80 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	07e70713          	addi	a4,a4,126 # 80009018 <started>
  if(cpuid() == 0){
    80000fa2:	c139                	beqz	a0,80000fe8 <main+0x5e>
    while(started == 0)
    80000fa4:	431c                	lw	a5,0(a4)
    80000fa6:	2781                	sext.w	a5,a5
    80000fa8:	dff5                	beqz	a5,80000fa4 <main+0x1a>
      ;
    __sync_synchronize();
    80000faa:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fae:	00001097          	auipc	ra,0x1
    80000fb2:	ad2080e7          	jalr	-1326(ra) # 80001a80 <cpuid>
    80000fb6:	85aa                	mv	a1,a0
    80000fb8:	00007517          	auipc	a0,0x7
    80000fbc:	10050513          	addi	a0,a0,256 # 800080b8 <digits+0x78>
    80000fc0:	fffff097          	auipc	ra,0xfffff
    80000fc4:	5c8080e7          	jalr	1480(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000fc8:	00000097          	auipc	ra,0x0
    80000fcc:	0d8080e7          	jalr	216(ra) # 800010a0 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000fd0:	00001097          	auipc	ra,0x1
    80000fd4:	728080e7          	jalr	1832(ra) # 800026f8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000fd8:	00005097          	auipc	ra,0x5
    80000fdc:	c78080e7          	jalr	-904(ra) # 80005c50 <plicinithart>
  }

  scheduler();        
    80000fe0:	00001097          	auipc	ra,0x1
    80000fe4:	fd6080e7          	jalr	-42(ra) # 80001fb6 <scheduler>
    consoleinit();
    80000fe8:	fffff097          	auipc	ra,0xfffff
    80000fec:	468080e7          	jalr	1128(ra) # 80000450 <consoleinit>
    printfinit();
    80000ff0:	fffff097          	auipc	ra,0xfffff
    80000ff4:	77e080e7          	jalr	1918(ra) # 8000076e <printfinit>
    printf("\n");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d050513          	addi	a0,a0,208 # 800080c8 <digits+0x88>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	588080e7          	jalr	1416(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80001008:	00007517          	auipc	a0,0x7
    8000100c:	09850513          	addi	a0,a0,152 # 800080a0 <digits+0x60>
    80001010:	fffff097          	auipc	ra,0xfffff
    80001014:	578080e7          	jalr	1400(ra) # 80000588 <printf>
    printf("\n");
    80001018:	00007517          	auipc	a0,0x7
    8000101c:	0b050513          	addi	a0,a0,176 # 800080c8 <digits+0x88>
    80001020:	fffff097          	auipc	ra,0xfffff
    80001024:	568080e7          	jalr	1384(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80001028:	00000097          	auipc	ra,0x0
    8000102c:	b1c080e7          	jalr	-1252(ra) # 80000b44 <kinit>
    kvminit();       // create kernel page table
    80001030:	00000097          	auipc	ra,0x0
    80001034:	322080e7          	jalr	802(ra) # 80001352 <kvminit>
    kvminithart();   // turn on paging
    80001038:	00000097          	auipc	ra,0x0
    8000103c:	068080e7          	jalr	104(ra) # 800010a0 <kvminithart>
    procinit();      // process table
    80001040:	00001097          	auipc	ra,0x1
    80001044:	990080e7          	jalr	-1648(ra) # 800019d0 <procinit>
    trapinit();      // trap vectors
    80001048:	00001097          	auipc	ra,0x1
    8000104c:	688080e7          	jalr	1672(ra) # 800026d0 <trapinit>
    trapinithart();  // install kernel trap vector
    80001050:	00001097          	auipc	ra,0x1
    80001054:	6a8080e7          	jalr	1704(ra) # 800026f8 <trapinithart>
    plicinit();      // set up interrupt controller
    80001058:	00005097          	auipc	ra,0x5
    8000105c:	be2080e7          	jalr	-1054(ra) # 80005c3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001060:	00005097          	auipc	ra,0x5
    80001064:	bf0080e7          	jalr	-1040(ra) # 80005c50 <plicinithart>
    binit();         // buffer cache
    80001068:	00002097          	auipc	ra,0x2
    8000106c:	dd2080e7          	jalr	-558(ra) # 80002e3a <binit>
    iinit();         // inode table
    80001070:	00002097          	auipc	ra,0x2
    80001074:	462080e7          	jalr	1122(ra) # 800034d2 <iinit>
    fileinit();      // file table
    80001078:	00003097          	auipc	ra,0x3
    8000107c:	40c080e7          	jalr	1036(ra) # 80004484 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001080:	00005097          	auipc	ra,0x5
    80001084:	cf2080e7          	jalr	-782(ra) # 80005d72 <virtio_disk_init>
    userinit();      // first user process
    80001088:	00001097          	auipc	ra,0x1
    8000108c:	cfc080e7          	jalr	-772(ra) # 80001d84 <userinit>
    __sync_synchronize();
    80001090:	0ff0000f          	fence
    started = 1;
    80001094:	4785                	li	a5,1
    80001096:	00008717          	auipc	a4,0x8
    8000109a:	f8f72123          	sw	a5,-126(a4) # 80009018 <started>
    8000109e:	b789                	j	80000fe0 <main+0x56>

00000000800010a0 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010a0:	1141                	addi	sp,sp,-16
    800010a2:	e422                	sd	s0,8(sp)
    800010a4:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800010a6:	00008797          	auipc	a5,0x8
    800010aa:	f7a7b783          	ld	a5,-134(a5) # 80009020 <kernel_pagetable>
    800010ae:	83b1                	srli	a5,a5,0xc
    800010b0:	577d                	li	a4,-1
    800010b2:	177e                	slli	a4,a4,0x3f
    800010b4:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010b6:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010ba:	12000073          	sfence.vma
  sfence_vma();
}
    800010be:	6422                	ld	s0,8(sp)
    800010c0:	0141                	addi	sp,sp,16
    800010c2:	8082                	ret

00000000800010c4 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010c4:	7139                	addi	sp,sp,-64
    800010c6:	fc06                	sd	ra,56(sp)
    800010c8:	f822                	sd	s0,48(sp)
    800010ca:	f426                	sd	s1,40(sp)
    800010cc:	f04a                	sd	s2,32(sp)
    800010ce:	ec4e                	sd	s3,24(sp)
    800010d0:	e852                	sd	s4,16(sp)
    800010d2:	e456                	sd	s5,8(sp)
    800010d4:	e05a                	sd	s6,0(sp)
    800010d6:	0080                	addi	s0,sp,64
    800010d8:	84aa                	mv	s1,a0
    800010da:	89ae                	mv	s3,a1
    800010dc:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800010de:	57fd                	li	a5,-1
    800010e0:	83e9                	srli	a5,a5,0x1a
    800010e2:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800010e4:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010e6:	04b7f263          	bgeu	a5,a1,8000112a <walk+0x66>
    panic("walk");
    800010ea:	00007517          	auipc	a0,0x7
    800010ee:	fe650513          	addi	a0,a0,-26 # 800080d0 <digits+0x90>
    800010f2:	fffff097          	auipc	ra,0xfffff
    800010f6:	44c080e7          	jalr	1100(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010fa:	060a8663          	beqz	s5,80001166 <walk+0xa2>
    800010fe:	00000097          	auipc	ra,0x0
    80001102:	ae8080e7          	jalr	-1304(ra) # 80000be6 <kalloc>
    80001106:	84aa                	mv	s1,a0
    80001108:	c529                	beqz	a0,80001152 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000110a:	6605                	lui	a2,0x1
    8000110c:	4581                	li	a1,0
    8000110e:	00000097          	auipc	ra,0x0
    80001112:	cce080e7          	jalr	-818(ra) # 80000ddc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001116:	00c4d793          	srli	a5,s1,0xc
    8000111a:	07aa                	slli	a5,a5,0xa
    8000111c:	0017e793          	ori	a5,a5,1
    80001120:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001124:	3a5d                	addiw	s4,s4,-9
    80001126:	036a0063          	beq	s4,s6,80001146 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000112a:	0149d933          	srl	s2,s3,s4
    8000112e:	1ff97913          	andi	s2,s2,511
    80001132:	090e                	slli	s2,s2,0x3
    80001134:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001136:	00093483          	ld	s1,0(s2)
    8000113a:	0014f793          	andi	a5,s1,1
    8000113e:	dfd5                	beqz	a5,800010fa <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001140:	80a9                	srli	s1,s1,0xa
    80001142:	04b2                	slli	s1,s1,0xc
    80001144:	b7c5                	j	80001124 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001146:	00c9d513          	srli	a0,s3,0xc
    8000114a:	1ff57513          	andi	a0,a0,511
    8000114e:	050e                	slli	a0,a0,0x3
    80001150:	9526                	add	a0,a0,s1
}
    80001152:	70e2                	ld	ra,56(sp)
    80001154:	7442                	ld	s0,48(sp)
    80001156:	74a2                	ld	s1,40(sp)
    80001158:	7902                	ld	s2,32(sp)
    8000115a:	69e2                	ld	s3,24(sp)
    8000115c:	6a42                	ld	s4,16(sp)
    8000115e:	6aa2                	ld	s5,8(sp)
    80001160:	6b02                	ld	s6,0(sp)
    80001162:	6121                	addi	sp,sp,64
    80001164:	8082                	ret
        return 0;
    80001166:	4501                	li	a0,0
    80001168:	b7ed                	j	80001152 <walk+0x8e>

000000008000116a <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000116a:	57fd                	li	a5,-1
    8000116c:	83e9                	srli	a5,a5,0x1a
    8000116e:	00b7f463          	bgeu	a5,a1,80001176 <walkaddr+0xc>
    return 0;
    80001172:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001174:	8082                	ret
{
    80001176:	1141                	addi	sp,sp,-16
    80001178:	e406                	sd	ra,8(sp)
    8000117a:	e022                	sd	s0,0(sp)
    8000117c:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000117e:	4601                	li	a2,0
    80001180:	00000097          	auipc	ra,0x0
    80001184:	f44080e7          	jalr	-188(ra) # 800010c4 <walk>
  if(pte == 0)
    80001188:	c105                	beqz	a0,800011a8 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000118a:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000118c:	0117f693          	andi	a3,a5,17
    80001190:	4745                	li	a4,17
    return 0;
    80001192:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001194:	00e68663          	beq	a3,a4,800011a0 <walkaddr+0x36>
}
    80001198:	60a2                	ld	ra,8(sp)
    8000119a:	6402                	ld	s0,0(sp)
    8000119c:	0141                	addi	sp,sp,16
    8000119e:	8082                	ret
  pa = PTE2PA(*pte);
    800011a0:	00a7d513          	srli	a0,a5,0xa
    800011a4:	0532                	slli	a0,a0,0xc
  return pa;
    800011a6:	bfcd                	j	80001198 <walkaddr+0x2e>
    return 0;
    800011a8:	4501                	li	a0,0
    800011aa:	b7fd                	j	80001198 <walkaddr+0x2e>

00000000800011ac <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011ac:	715d                	addi	sp,sp,-80
    800011ae:	e486                	sd	ra,72(sp)
    800011b0:	e0a2                	sd	s0,64(sp)
    800011b2:	fc26                	sd	s1,56(sp)
    800011b4:	f84a                	sd	s2,48(sp)
    800011b6:	f44e                	sd	s3,40(sp)
    800011b8:	f052                	sd	s4,32(sp)
    800011ba:	ec56                	sd	s5,24(sp)
    800011bc:	e85a                	sd	s6,16(sp)
    800011be:	e45e                	sd	s7,8(sp)
    800011c0:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800011c2:	c205                	beqz	a2,800011e2 <mappages+0x36>
    800011c4:	8aaa                	mv	s5,a0
    800011c6:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011c8:	77fd                	lui	a5,0xfffff
    800011ca:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800011ce:	15fd                	addi	a1,a1,-1
    800011d0:	00c589b3          	add	s3,a1,a2
    800011d4:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800011d8:	8952                	mv	s2,s4
    800011da:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011de:	6b85                	lui	s7,0x1
    800011e0:	a015                	j	80001204 <mappages+0x58>
    panic("mappages: size");
    800011e2:	00007517          	auipc	a0,0x7
    800011e6:	ef650513          	addi	a0,a0,-266 # 800080d8 <digits+0x98>
    800011ea:	fffff097          	auipc	ra,0xfffff
    800011ee:	354080e7          	jalr	852(ra) # 8000053e <panic>
      panic("mappages: remap");
    800011f2:	00007517          	auipc	a0,0x7
    800011f6:	ef650513          	addi	a0,a0,-266 # 800080e8 <digits+0xa8>
    800011fa:	fffff097          	auipc	ra,0xfffff
    800011fe:	344080e7          	jalr	836(ra) # 8000053e <panic>
    a += PGSIZE;
    80001202:	995e                	add	s2,s2,s7
  for(;;){
    80001204:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001208:	4605                	li	a2,1
    8000120a:	85ca                	mv	a1,s2
    8000120c:	8556                	mv	a0,s5
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	eb6080e7          	jalr	-330(ra) # 800010c4 <walk>
    80001216:	cd19                	beqz	a0,80001234 <mappages+0x88>
    if(*pte & PTE_V)
    80001218:	611c                	ld	a5,0(a0)
    8000121a:	8b85                	andi	a5,a5,1
    8000121c:	fbf9                	bnez	a5,800011f2 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000121e:	80b1                	srli	s1,s1,0xc
    80001220:	04aa                	slli	s1,s1,0xa
    80001222:	0164e4b3          	or	s1,s1,s6
    80001226:	0014e493          	ori	s1,s1,1
    8000122a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000122c:	fd391be3          	bne	s2,s3,80001202 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001230:	4501                	li	a0,0
    80001232:	a011                	j	80001236 <mappages+0x8a>
      return -1;
    80001234:	557d                	li	a0,-1
}
    80001236:	60a6                	ld	ra,72(sp)
    80001238:	6406                	ld	s0,64(sp)
    8000123a:	74e2                	ld	s1,56(sp)
    8000123c:	7942                	ld	s2,48(sp)
    8000123e:	79a2                	ld	s3,40(sp)
    80001240:	7a02                	ld	s4,32(sp)
    80001242:	6ae2                	ld	s5,24(sp)
    80001244:	6b42                	ld	s6,16(sp)
    80001246:	6ba2                	ld	s7,8(sp)
    80001248:	6161                	addi	sp,sp,80
    8000124a:	8082                	ret

000000008000124c <kvmmap>:
{
    8000124c:	1141                	addi	sp,sp,-16
    8000124e:	e406                	sd	ra,8(sp)
    80001250:	e022                	sd	s0,0(sp)
    80001252:	0800                	addi	s0,sp,16
    80001254:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001256:	86b2                	mv	a3,a2
    80001258:	863e                	mv	a2,a5
    8000125a:	00000097          	auipc	ra,0x0
    8000125e:	f52080e7          	jalr	-174(ra) # 800011ac <mappages>
    80001262:	e509                	bnez	a0,8000126c <kvmmap+0x20>
}
    80001264:	60a2                	ld	ra,8(sp)
    80001266:	6402                	ld	s0,0(sp)
    80001268:	0141                	addi	sp,sp,16
    8000126a:	8082                	ret
    panic("kvmmap");
    8000126c:	00007517          	auipc	a0,0x7
    80001270:	e8c50513          	addi	a0,a0,-372 # 800080f8 <digits+0xb8>
    80001274:	fffff097          	auipc	ra,0xfffff
    80001278:	2ca080e7          	jalr	714(ra) # 8000053e <panic>

000000008000127c <kvmmake>:
{
    8000127c:	1101                	addi	sp,sp,-32
    8000127e:	ec06                	sd	ra,24(sp)
    80001280:	e822                	sd	s0,16(sp)
    80001282:	e426                	sd	s1,8(sp)
    80001284:	e04a                	sd	s2,0(sp)
    80001286:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001288:	00000097          	auipc	ra,0x0
    8000128c:	95e080e7          	jalr	-1698(ra) # 80000be6 <kalloc>
    80001290:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001292:	6605                	lui	a2,0x1
    80001294:	4581                	li	a1,0
    80001296:	00000097          	auipc	ra,0x0
    8000129a:	b46080e7          	jalr	-1210(ra) # 80000ddc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000129e:	4719                	li	a4,6
    800012a0:	6685                	lui	a3,0x1
    800012a2:	10000637          	lui	a2,0x10000
    800012a6:	100005b7          	lui	a1,0x10000
    800012aa:	8526                	mv	a0,s1
    800012ac:	00000097          	auipc	ra,0x0
    800012b0:	fa0080e7          	jalr	-96(ra) # 8000124c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012b4:	4719                	li	a4,6
    800012b6:	6685                	lui	a3,0x1
    800012b8:	10001637          	lui	a2,0x10001
    800012bc:	100015b7          	lui	a1,0x10001
    800012c0:	8526                	mv	a0,s1
    800012c2:	00000097          	auipc	ra,0x0
    800012c6:	f8a080e7          	jalr	-118(ra) # 8000124c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012ca:	4719                	li	a4,6
    800012cc:	004006b7          	lui	a3,0x400
    800012d0:	0c000637          	lui	a2,0xc000
    800012d4:	0c0005b7          	lui	a1,0xc000
    800012d8:	8526                	mv	a0,s1
    800012da:	00000097          	auipc	ra,0x0
    800012de:	f72080e7          	jalr	-142(ra) # 8000124c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012e2:	00007917          	auipc	s2,0x7
    800012e6:	d1e90913          	addi	s2,s2,-738 # 80008000 <etext>
    800012ea:	4729                	li	a4,10
    800012ec:	80007697          	auipc	a3,0x80007
    800012f0:	d1468693          	addi	a3,a3,-748 # 8000 <_entry-0x7fff8000>
    800012f4:	4605                	li	a2,1
    800012f6:	067e                	slli	a2,a2,0x1f
    800012f8:	85b2                	mv	a1,a2
    800012fa:	8526                	mv	a0,s1
    800012fc:	00000097          	auipc	ra,0x0
    80001300:	f50080e7          	jalr	-176(ra) # 8000124c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001304:	4719                	li	a4,6
    80001306:	46c5                	li	a3,17
    80001308:	06ee                	slli	a3,a3,0x1b
    8000130a:	412686b3          	sub	a3,a3,s2
    8000130e:	864a                	mv	a2,s2
    80001310:	85ca                	mv	a1,s2
    80001312:	8526                	mv	a0,s1
    80001314:	00000097          	auipc	ra,0x0
    80001318:	f38080e7          	jalr	-200(ra) # 8000124c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000131c:	4729                	li	a4,10
    8000131e:	6685                	lui	a3,0x1
    80001320:	00006617          	auipc	a2,0x6
    80001324:	ce060613          	addi	a2,a2,-800 # 80007000 <_trampoline>
    80001328:	040005b7          	lui	a1,0x4000
    8000132c:	15fd                	addi	a1,a1,-1
    8000132e:	05b2                	slli	a1,a1,0xc
    80001330:	8526                	mv	a0,s1
    80001332:	00000097          	auipc	ra,0x0
    80001336:	f1a080e7          	jalr	-230(ra) # 8000124c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000133a:	8526                	mv	a0,s1
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	5fe080e7          	jalr	1534(ra) # 8000193a <proc_mapstacks>
}
    80001344:	8526                	mv	a0,s1
    80001346:	60e2                	ld	ra,24(sp)
    80001348:	6442                	ld	s0,16(sp)
    8000134a:	64a2                	ld	s1,8(sp)
    8000134c:	6902                	ld	s2,0(sp)
    8000134e:	6105                	addi	sp,sp,32
    80001350:	8082                	ret

0000000080001352 <kvminit>:
{
    80001352:	1141                	addi	sp,sp,-16
    80001354:	e406                	sd	ra,8(sp)
    80001356:	e022                	sd	s0,0(sp)
    80001358:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000135a:	00000097          	auipc	ra,0x0
    8000135e:	f22080e7          	jalr	-222(ra) # 8000127c <kvmmake>
    80001362:	00008797          	auipc	a5,0x8
    80001366:	caa7bf23          	sd	a0,-834(a5) # 80009020 <kernel_pagetable>
}
    8000136a:	60a2                	ld	ra,8(sp)
    8000136c:	6402                	ld	s0,0(sp)
    8000136e:	0141                	addi	sp,sp,16
    80001370:	8082                	ret

0000000080001372 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001372:	715d                	addi	sp,sp,-80
    80001374:	e486                	sd	ra,72(sp)
    80001376:	e0a2                	sd	s0,64(sp)
    80001378:	fc26                	sd	s1,56(sp)
    8000137a:	f84a                	sd	s2,48(sp)
    8000137c:	f44e                	sd	s3,40(sp)
    8000137e:	f052                	sd	s4,32(sp)
    80001380:	ec56                	sd	s5,24(sp)
    80001382:	e85a                	sd	s6,16(sp)
    80001384:	e45e                	sd	s7,8(sp)
    80001386:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001388:	03459793          	slli	a5,a1,0x34
    8000138c:	e795                	bnez	a5,800013b8 <uvmunmap+0x46>
    8000138e:	8a2a                	mv	s4,a0
    80001390:	892e                	mv	s2,a1
    80001392:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001394:	0632                	slli	a2,a2,0xc
    80001396:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000139a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000139c:	6b05                	lui	s6,0x1
    8000139e:	0735e863          	bltu	a1,s3,8000140e <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013a2:	60a6                	ld	ra,72(sp)
    800013a4:	6406                	ld	s0,64(sp)
    800013a6:	74e2                	ld	s1,56(sp)
    800013a8:	7942                	ld	s2,48(sp)
    800013aa:	79a2                	ld	s3,40(sp)
    800013ac:	7a02                	ld	s4,32(sp)
    800013ae:	6ae2                	ld	s5,24(sp)
    800013b0:	6b42                	ld	s6,16(sp)
    800013b2:	6ba2                	ld	s7,8(sp)
    800013b4:	6161                	addi	sp,sp,80
    800013b6:	8082                	ret
    panic("uvmunmap: not aligned");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	d4850513          	addi	a0,a0,-696 # 80008100 <digits+0xc0>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800013c8:	00007517          	auipc	a0,0x7
    800013cc:	d5050513          	addi	a0,a0,-688 # 80008118 <digits+0xd8>
    800013d0:	fffff097          	auipc	ra,0xfffff
    800013d4:	16e080e7          	jalr	366(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800013d8:	00007517          	auipc	a0,0x7
    800013dc:	d5050513          	addi	a0,a0,-688 # 80008128 <digits+0xe8>
    800013e0:	fffff097          	auipc	ra,0xfffff
    800013e4:	15e080e7          	jalr	350(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800013e8:	00007517          	auipc	a0,0x7
    800013ec:	d5850513          	addi	a0,a0,-680 # 80008140 <digits+0x100>
    800013f0:	fffff097          	auipc	ra,0xfffff
    800013f4:	14e080e7          	jalr	334(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800013f8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013fa:	0532                	slli	a0,a0,0xc
    800013fc:	fffff097          	auipc	ra,0xfffff
    80001400:	660080e7          	jalr	1632(ra) # 80000a5c <kfree>
    *pte = 0;
    80001404:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001408:	995a                	add	s2,s2,s6
    8000140a:	f9397ce3          	bgeu	s2,s3,800013a2 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000140e:	4601                	li	a2,0
    80001410:	85ca                	mv	a1,s2
    80001412:	8552                	mv	a0,s4
    80001414:	00000097          	auipc	ra,0x0
    80001418:	cb0080e7          	jalr	-848(ra) # 800010c4 <walk>
    8000141c:	84aa                	mv	s1,a0
    8000141e:	d54d                	beqz	a0,800013c8 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001420:	6108                	ld	a0,0(a0)
    80001422:	00157793          	andi	a5,a0,1
    80001426:	dbcd                	beqz	a5,800013d8 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001428:	3ff57793          	andi	a5,a0,1023
    8000142c:	fb778ee3          	beq	a5,s7,800013e8 <uvmunmap+0x76>
    if(do_free){
    80001430:	fc0a8ae3          	beqz	s5,80001404 <uvmunmap+0x92>
    80001434:	b7d1                	j	800013f8 <uvmunmap+0x86>

0000000080001436 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001436:	1101                	addi	sp,sp,-32
    80001438:	ec06                	sd	ra,24(sp)
    8000143a:	e822                	sd	s0,16(sp)
    8000143c:	e426                	sd	s1,8(sp)
    8000143e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001440:	fffff097          	auipc	ra,0xfffff
    80001444:	7a6080e7          	jalr	1958(ra) # 80000be6 <kalloc>
    80001448:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000144a:	c519                	beqz	a0,80001458 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000144c:	6605                	lui	a2,0x1
    8000144e:	4581                	li	a1,0
    80001450:	00000097          	auipc	ra,0x0
    80001454:	98c080e7          	jalr	-1652(ra) # 80000ddc <memset>
  return pagetable;
}
    80001458:	8526                	mv	a0,s1
    8000145a:	60e2                	ld	ra,24(sp)
    8000145c:	6442                	ld	s0,16(sp)
    8000145e:	64a2                	ld	s1,8(sp)
    80001460:	6105                	addi	sp,sp,32
    80001462:	8082                	ret

0000000080001464 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001464:	7179                	addi	sp,sp,-48
    80001466:	f406                	sd	ra,40(sp)
    80001468:	f022                	sd	s0,32(sp)
    8000146a:	ec26                	sd	s1,24(sp)
    8000146c:	e84a                	sd	s2,16(sp)
    8000146e:	e44e                	sd	s3,8(sp)
    80001470:	e052                	sd	s4,0(sp)
    80001472:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001474:	6785                	lui	a5,0x1
    80001476:	04f67863          	bgeu	a2,a5,800014c6 <uvminit+0x62>
    8000147a:	8a2a                	mv	s4,a0
    8000147c:	89ae                	mv	s3,a1
    8000147e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001480:	fffff097          	auipc	ra,0xfffff
    80001484:	766080e7          	jalr	1894(ra) # 80000be6 <kalloc>
    80001488:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000148a:	6605                	lui	a2,0x1
    8000148c:	4581                	li	a1,0
    8000148e:	00000097          	auipc	ra,0x0
    80001492:	94e080e7          	jalr	-1714(ra) # 80000ddc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001496:	4779                	li	a4,30
    80001498:	86ca                	mv	a3,s2
    8000149a:	6605                	lui	a2,0x1
    8000149c:	4581                	li	a1,0
    8000149e:	8552                	mv	a0,s4
    800014a0:	00000097          	auipc	ra,0x0
    800014a4:	d0c080e7          	jalr	-756(ra) # 800011ac <mappages>
  memmove(mem, src, sz);
    800014a8:	8626                	mv	a2,s1
    800014aa:	85ce                	mv	a1,s3
    800014ac:	854a                	mv	a0,s2
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	98e080e7          	jalr	-1650(ra) # 80000e3c <memmove>
}
    800014b6:	70a2                	ld	ra,40(sp)
    800014b8:	7402                	ld	s0,32(sp)
    800014ba:	64e2                	ld	s1,24(sp)
    800014bc:	6942                	ld	s2,16(sp)
    800014be:	69a2                	ld	s3,8(sp)
    800014c0:	6a02                	ld	s4,0(sp)
    800014c2:	6145                	addi	sp,sp,48
    800014c4:	8082                	ret
    panic("inituvm: more than a page");
    800014c6:	00007517          	auipc	a0,0x7
    800014ca:	c9250513          	addi	a0,a0,-878 # 80008158 <digits+0x118>
    800014ce:	fffff097          	auipc	ra,0xfffff
    800014d2:	070080e7          	jalr	112(ra) # 8000053e <panic>

00000000800014d6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014d6:	1101                	addi	sp,sp,-32
    800014d8:	ec06                	sd	ra,24(sp)
    800014da:	e822                	sd	s0,16(sp)
    800014dc:	e426                	sd	s1,8(sp)
    800014de:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014e0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014e2:	00b67d63          	bgeu	a2,a1,800014fc <uvmdealloc+0x26>
    800014e6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014e8:	6785                	lui	a5,0x1
    800014ea:	17fd                	addi	a5,a5,-1
    800014ec:	00f60733          	add	a4,a2,a5
    800014f0:	767d                	lui	a2,0xfffff
    800014f2:	8f71                	and	a4,a4,a2
    800014f4:	97ae                	add	a5,a5,a1
    800014f6:	8ff1                	and	a5,a5,a2
    800014f8:	00f76863          	bltu	a4,a5,80001508 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014fc:	8526                	mv	a0,s1
    800014fe:	60e2                	ld	ra,24(sp)
    80001500:	6442                	ld	s0,16(sp)
    80001502:	64a2                	ld	s1,8(sp)
    80001504:	6105                	addi	sp,sp,32
    80001506:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001508:	8f99                	sub	a5,a5,a4
    8000150a:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000150c:	4685                	li	a3,1
    8000150e:	0007861b          	sext.w	a2,a5
    80001512:	85ba                	mv	a1,a4
    80001514:	00000097          	auipc	ra,0x0
    80001518:	e5e080e7          	jalr	-418(ra) # 80001372 <uvmunmap>
    8000151c:	b7c5                	j	800014fc <uvmdealloc+0x26>

000000008000151e <uvmalloc>:
  if(newsz < oldsz)
    8000151e:	0ab66163          	bltu	a2,a1,800015c0 <uvmalloc+0xa2>
{
    80001522:	7139                	addi	sp,sp,-64
    80001524:	fc06                	sd	ra,56(sp)
    80001526:	f822                	sd	s0,48(sp)
    80001528:	f426                	sd	s1,40(sp)
    8000152a:	f04a                	sd	s2,32(sp)
    8000152c:	ec4e                	sd	s3,24(sp)
    8000152e:	e852                	sd	s4,16(sp)
    80001530:	e456                	sd	s5,8(sp)
    80001532:	0080                	addi	s0,sp,64
    80001534:	8aaa                	mv	s5,a0
    80001536:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001538:	6985                	lui	s3,0x1
    8000153a:	19fd                	addi	s3,s3,-1
    8000153c:	95ce                	add	a1,a1,s3
    8000153e:	79fd                	lui	s3,0xfffff
    80001540:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001544:	08c9f063          	bgeu	s3,a2,800015c4 <uvmalloc+0xa6>
    80001548:	894e                	mv	s2,s3
    mem = kalloc();
    8000154a:	fffff097          	auipc	ra,0xfffff
    8000154e:	69c080e7          	jalr	1692(ra) # 80000be6 <kalloc>
    80001552:	84aa                	mv	s1,a0
    if(mem == 0){
    80001554:	c51d                	beqz	a0,80001582 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001556:	6605                	lui	a2,0x1
    80001558:	4581                	li	a1,0
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	882080e7          	jalr	-1918(ra) # 80000ddc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001562:	4779                	li	a4,30
    80001564:	86a6                	mv	a3,s1
    80001566:	6605                	lui	a2,0x1
    80001568:	85ca                	mv	a1,s2
    8000156a:	8556                	mv	a0,s5
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	c40080e7          	jalr	-960(ra) # 800011ac <mappages>
    80001574:	e905                	bnez	a0,800015a4 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001576:	6785                	lui	a5,0x1
    80001578:	993e                	add	s2,s2,a5
    8000157a:	fd4968e3          	bltu	s2,s4,8000154a <uvmalloc+0x2c>
  return newsz;
    8000157e:	8552                	mv	a0,s4
    80001580:	a809                	j	80001592 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001582:	864e                	mv	a2,s3
    80001584:	85ca                	mv	a1,s2
    80001586:	8556                	mv	a0,s5
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	f4e080e7          	jalr	-178(ra) # 800014d6 <uvmdealloc>
      return 0;
    80001590:	4501                	li	a0,0
}
    80001592:	70e2                	ld	ra,56(sp)
    80001594:	7442                	ld	s0,48(sp)
    80001596:	74a2                	ld	s1,40(sp)
    80001598:	7902                	ld	s2,32(sp)
    8000159a:	69e2                	ld	s3,24(sp)
    8000159c:	6a42                	ld	s4,16(sp)
    8000159e:	6aa2                	ld	s5,8(sp)
    800015a0:	6121                	addi	sp,sp,64
    800015a2:	8082                	ret
      kfree(mem);
    800015a4:	8526                	mv	a0,s1
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	4b6080e7          	jalr	1206(ra) # 80000a5c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015ae:	864e                	mv	a2,s3
    800015b0:	85ca                	mv	a1,s2
    800015b2:	8556                	mv	a0,s5
    800015b4:	00000097          	auipc	ra,0x0
    800015b8:	f22080e7          	jalr	-222(ra) # 800014d6 <uvmdealloc>
      return 0;
    800015bc:	4501                	li	a0,0
    800015be:	bfd1                	j	80001592 <uvmalloc+0x74>
    return oldsz;
    800015c0:	852e                	mv	a0,a1
}
    800015c2:	8082                	ret
  return newsz;
    800015c4:	8532                	mv	a0,a2
    800015c6:	b7f1                	j	80001592 <uvmalloc+0x74>

00000000800015c8 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015c8:	7179                	addi	sp,sp,-48
    800015ca:	f406                	sd	ra,40(sp)
    800015cc:	f022                	sd	s0,32(sp)
    800015ce:	ec26                	sd	s1,24(sp)
    800015d0:	e84a                	sd	s2,16(sp)
    800015d2:	e44e                	sd	s3,8(sp)
    800015d4:	e052                	sd	s4,0(sp)
    800015d6:	1800                	addi	s0,sp,48
    800015d8:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015da:	84aa                	mv	s1,a0
    800015dc:	6905                	lui	s2,0x1
    800015de:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015e0:	4985                	li	s3,1
    800015e2:	a821                	j	800015fa <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015e4:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015e6:	0532                	slli	a0,a0,0xc
    800015e8:	00000097          	auipc	ra,0x0
    800015ec:	fe0080e7          	jalr	-32(ra) # 800015c8 <freewalk>
      pagetable[i] = 0;
    800015f0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015f4:	04a1                	addi	s1,s1,8
    800015f6:	03248163          	beq	s1,s2,80001618 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015fa:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015fc:	00f57793          	andi	a5,a0,15
    80001600:	ff3782e3          	beq	a5,s3,800015e4 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001604:	8905                	andi	a0,a0,1
    80001606:	d57d                	beqz	a0,800015f4 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001608:	00007517          	auipc	a0,0x7
    8000160c:	b7050513          	addi	a0,a0,-1168 # 80008178 <digits+0x138>
    80001610:	fffff097          	auipc	ra,0xfffff
    80001614:	f2e080e7          	jalr	-210(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001618:	8552                	mv	a0,s4
    8000161a:	fffff097          	auipc	ra,0xfffff
    8000161e:	442080e7          	jalr	1090(ra) # 80000a5c <kfree>
}
    80001622:	70a2                	ld	ra,40(sp)
    80001624:	7402                	ld	s0,32(sp)
    80001626:	64e2                	ld	s1,24(sp)
    80001628:	6942                	ld	s2,16(sp)
    8000162a:	69a2                	ld	s3,8(sp)
    8000162c:	6a02                	ld	s4,0(sp)
    8000162e:	6145                	addi	sp,sp,48
    80001630:	8082                	ret

0000000080001632 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001632:	1101                	addi	sp,sp,-32
    80001634:	ec06                	sd	ra,24(sp)
    80001636:	e822                	sd	s0,16(sp)
    80001638:	e426                	sd	s1,8(sp)
    8000163a:	1000                	addi	s0,sp,32
    8000163c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000163e:	e999                	bnez	a1,80001654 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001640:	8526                	mv	a0,s1
    80001642:	00000097          	auipc	ra,0x0
    80001646:	f86080e7          	jalr	-122(ra) # 800015c8 <freewalk>
}
    8000164a:	60e2                	ld	ra,24(sp)
    8000164c:	6442                	ld	s0,16(sp)
    8000164e:	64a2                	ld	s1,8(sp)
    80001650:	6105                	addi	sp,sp,32
    80001652:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001654:	6605                	lui	a2,0x1
    80001656:	167d                	addi	a2,a2,-1
    80001658:	962e                	add	a2,a2,a1
    8000165a:	4685                	li	a3,1
    8000165c:	8231                	srli	a2,a2,0xc
    8000165e:	4581                	li	a1,0
    80001660:	00000097          	auipc	ra,0x0
    80001664:	d12080e7          	jalr	-750(ra) # 80001372 <uvmunmap>
    80001668:	bfe1                	j	80001640 <uvmfree+0xe>

000000008000166a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000166a:	c679                	beqz	a2,80001738 <uvmcopy+0xce>
{
    8000166c:	715d                	addi	sp,sp,-80
    8000166e:	e486                	sd	ra,72(sp)
    80001670:	e0a2                	sd	s0,64(sp)
    80001672:	fc26                	sd	s1,56(sp)
    80001674:	f84a                	sd	s2,48(sp)
    80001676:	f44e                	sd	s3,40(sp)
    80001678:	f052                	sd	s4,32(sp)
    8000167a:	ec56                	sd	s5,24(sp)
    8000167c:	e85a                	sd	s6,16(sp)
    8000167e:	e45e                	sd	s7,8(sp)
    80001680:	0880                	addi	s0,sp,80
    80001682:	8b2a                	mv	s6,a0
    80001684:	8aae                	mv	s5,a1
    80001686:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001688:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000168a:	4601                	li	a2,0
    8000168c:	85ce                	mv	a1,s3
    8000168e:	855a                	mv	a0,s6
    80001690:	00000097          	auipc	ra,0x0
    80001694:	a34080e7          	jalr	-1484(ra) # 800010c4 <walk>
    80001698:	c531                	beqz	a0,800016e4 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000169a:	6118                	ld	a4,0(a0)
    8000169c:	00177793          	andi	a5,a4,1
    800016a0:	cbb1                	beqz	a5,800016f4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800016a2:	00a75593          	srli	a1,a4,0xa
    800016a6:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800016aa:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	538080e7          	jalr	1336(ra) # 80000be6 <kalloc>
    800016b6:	892a                	mv	s2,a0
    800016b8:	c939                	beqz	a0,8000170e <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800016ba:	6605                	lui	a2,0x1
    800016bc:	85de                	mv	a1,s7
    800016be:	fffff097          	auipc	ra,0xfffff
    800016c2:	77e080e7          	jalr	1918(ra) # 80000e3c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016c6:	8726                	mv	a4,s1
    800016c8:	86ca                	mv	a3,s2
    800016ca:	6605                	lui	a2,0x1
    800016cc:	85ce                	mv	a1,s3
    800016ce:	8556                	mv	a0,s5
    800016d0:	00000097          	auipc	ra,0x0
    800016d4:	adc080e7          	jalr	-1316(ra) # 800011ac <mappages>
    800016d8:	e515                	bnez	a0,80001704 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016da:	6785                	lui	a5,0x1
    800016dc:	99be                	add	s3,s3,a5
    800016de:	fb49e6e3          	bltu	s3,s4,8000168a <uvmcopy+0x20>
    800016e2:	a081                	j	80001722 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016e4:	00007517          	auipc	a0,0x7
    800016e8:	aa450513          	addi	a0,a0,-1372 # 80008188 <digits+0x148>
    800016ec:	fffff097          	auipc	ra,0xfffff
    800016f0:	e52080e7          	jalr	-430(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800016f4:	00007517          	auipc	a0,0x7
    800016f8:	ab450513          	addi	a0,a0,-1356 # 800081a8 <digits+0x168>
    800016fc:	fffff097          	auipc	ra,0xfffff
    80001700:	e42080e7          	jalr	-446(ra) # 8000053e <panic>
      kfree(mem);
    80001704:	854a                	mv	a0,s2
    80001706:	fffff097          	auipc	ra,0xfffff
    8000170a:	356080e7          	jalr	854(ra) # 80000a5c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000170e:	4685                	li	a3,1
    80001710:	00c9d613          	srli	a2,s3,0xc
    80001714:	4581                	li	a1,0
    80001716:	8556                	mv	a0,s5
    80001718:	00000097          	auipc	ra,0x0
    8000171c:	c5a080e7          	jalr	-934(ra) # 80001372 <uvmunmap>
  return -1;
    80001720:	557d                	li	a0,-1
}
    80001722:	60a6                	ld	ra,72(sp)
    80001724:	6406                	ld	s0,64(sp)
    80001726:	74e2                	ld	s1,56(sp)
    80001728:	7942                	ld	s2,48(sp)
    8000172a:	79a2                	ld	s3,40(sp)
    8000172c:	7a02                	ld	s4,32(sp)
    8000172e:	6ae2                	ld	s5,24(sp)
    80001730:	6b42                	ld	s6,16(sp)
    80001732:	6ba2                	ld	s7,8(sp)
    80001734:	6161                	addi	sp,sp,80
    80001736:	8082                	ret
  return 0;
    80001738:	4501                	li	a0,0
}
    8000173a:	8082                	ret

000000008000173c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000173c:	1141                	addi	sp,sp,-16
    8000173e:	e406                	sd	ra,8(sp)
    80001740:	e022                	sd	s0,0(sp)
    80001742:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001744:	4601                	li	a2,0
    80001746:	00000097          	auipc	ra,0x0
    8000174a:	97e080e7          	jalr	-1666(ra) # 800010c4 <walk>
  if(pte == 0)
    8000174e:	c901                	beqz	a0,8000175e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001750:	611c                	ld	a5,0(a0)
    80001752:	9bbd                	andi	a5,a5,-17
    80001754:	e11c                	sd	a5,0(a0)
}
    80001756:	60a2                	ld	ra,8(sp)
    80001758:	6402                	ld	s0,0(sp)
    8000175a:	0141                	addi	sp,sp,16
    8000175c:	8082                	ret
    panic("uvmclear");
    8000175e:	00007517          	auipc	a0,0x7
    80001762:	a6a50513          	addi	a0,a0,-1430 # 800081c8 <digits+0x188>
    80001766:	fffff097          	auipc	ra,0xfffff
    8000176a:	dd8080e7          	jalr	-552(ra) # 8000053e <panic>

000000008000176e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000176e:	c6bd                	beqz	a3,800017dc <copyout+0x6e>
{
    80001770:	715d                	addi	sp,sp,-80
    80001772:	e486                	sd	ra,72(sp)
    80001774:	e0a2                	sd	s0,64(sp)
    80001776:	fc26                	sd	s1,56(sp)
    80001778:	f84a                	sd	s2,48(sp)
    8000177a:	f44e                	sd	s3,40(sp)
    8000177c:	f052                	sd	s4,32(sp)
    8000177e:	ec56                	sd	s5,24(sp)
    80001780:	e85a                	sd	s6,16(sp)
    80001782:	e45e                	sd	s7,8(sp)
    80001784:	e062                	sd	s8,0(sp)
    80001786:	0880                	addi	s0,sp,80
    80001788:	8b2a                	mv	s6,a0
    8000178a:	8c2e                	mv	s8,a1
    8000178c:	8a32                	mv	s4,a2
    8000178e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001790:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001792:	6a85                	lui	s5,0x1
    80001794:	a015                	j	800017b8 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001796:	9562                	add	a0,a0,s8
    80001798:	0004861b          	sext.w	a2,s1
    8000179c:	85d2                	mv	a1,s4
    8000179e:	41250533          	sub	a0,a0,s2
    800017a2:	fffff097          	auipc	ra,0xfffff
    800017a6:	69a080e7          	jalr	1690(ra) # 80000e3c <memmove>

    len -= n;
    800017aa:	409989b3          	sub	s3,s3,s1
    src += n;
    800017ae:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017b0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017b4:	02098263          	beqz	s3,800017d8 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017b8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017bc:	85ca                	mv	a1,s2
    800017be:	855a                	mv	a0,s6
    800017c0:	00000097          	auipc	ra,0x0
    800017c4:	9aa080e7          	jalr	-1622(ra) # 8000116a <walkaddr>
    if(pa0 == 0)
    800017c8:	cd01                	beqz	a0,800017e0 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017ca:	418904b3          	sub	s1,s2,s8
    800017ce:	94d6                	add	s1,s1,s5
    if(n > len)
    800017d0:	fc99f3e3          	bgeu	s3,s1,80001796 <copyout+0x28>
    800017d4:	84ce                	mv	s1,s3
    800017d6:	b7c1                	j	80001796 <copyout+0x28>
  }
  return 0;
    800017d8:	4501                	li	a0,0
    800017da:	a021                	j	800017e2 <copyout+0x74>
    800017dc:	4501                	li	a0,0
}
    800017de:	8082                	ret
      return -1;
    800017e0:	557d                	li	a0,-1
}
    800017e2:	60a6                	ld	ra,72(sp)
    800017e4:	6406                	ld	s0,64(sp)
    800017e6:	74e2                	ld	s1,56(sp)
    800017e8:	7942                	ld	s2,48(sp)
    800017ea:	79a2                	ld	s3,40(sp)
    800017ec:	7a02                	ld	s4,32(sp)
    800017ee:	6ae2                	ld	s5,24(sp)
    800017f0:	6b42                	ld	s6,16(sp)
    800017f2:	6ba2                	ld	s7,8(sp)
    800017f4:	6c02                	ld	s8,0(sp)
    800017f6:	6161                	addi	sp,sp,80
    800017f8:	8082                	ret

00000000800017fa <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017fa:	c6bd                	beqz	a3,80001868 <copyin+0x6e>
{
    800017fc:	715d                	addi	sp,sp,-80
    800017fe:	e486                	sd	ra,72(sp)
    80001800:	e0a2                	sd	s0,64(sp)
    80001802:	fc26                	sd	s1,56(sp)
    80001804:	f84a                	sd	s2,48(sp)
    80001806:	f44e                	sd	s3,40(sp)
    80001808:	f052                	sd	s4,32(sp)
    8000180a:	ec56                	sd	s5,24(sp)
    8000180c:	e85a                	sd	s6,16(sp)
    8000180e:	e45e                	sd	s7,8(sp)
    80001810:	e062                	sd	s8,0(sp)
    80001812:	0880                	addi	s0,sp,80
    80001814:	8b2a                	mv	s6,a0
    80001816:	8a2e                	mv	s4,a1
    80001818:	8c32                	mv	s8,a2
    8000181a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000181c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000181e:	6a85                	lui	s5,0x1
    80001820:	a015                	j	80001844 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001822:	9562                	add	a0,a0,s8
    80001824:	0004861b          	sext.w	a2,s1
    80001828:	412505b3          	sub	a1,a0,s2
    8000182c:	8552                	mv	a0,s4
    8000182e:	fffff097          	auipc	ra,0xfffff
    80001832:	60e080e7          	jalr	1550(ra) # 80000e3c <memmove>

    len -= n;
    80001836:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000183a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000183c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001840:	02098263          	beqz	s3,80001864 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001844:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001848:	85ca                	mv	a1,s2
    8000184a:	855a                	mv	a0,s6
    8000184c:	00000097          	auipc	ra,0x0
    80001850:	91e080e7          	jalr	-1762(ra) # 8000116a <walkaddr>
    if(pa0 == 0)
    80001854:	cd01                	beqz	a0,8000186c <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001856:	418904b3          	sub	s1,s2,s8
    8000185a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000185c:	fc99f3e3          	bgeu	s3,s1,80001822 <copyin+0x28>
    80001860:	84ce                	mv	s1,s3
    80001862:	b7c1                	j	80001822 <copyin+0x28>
  }
  return 0;
    80001864:	4501                	li	a0,0
    80001866:	a021                	j	8000186e <copyin+0x74>
    80001868:	4501                	li	a0,0
}
    8000186a:	8082                	ret
      return -1;
    8000186c:	557d                	li	a0,-1
}
    8000186e:	60a6                	ld	ra,72(sp)
    80001870:	6406                	ld	s0,64(sp)
    80001872:	74e2                	ld	s1,56(sp)
    80001874:	7942                	ld	s2,48(sp)
    80001876:	79a2                	ld	s3,40(sp)
    80001878:	7a02                	ld	s4,32(sp)
    8000187a:	6ae2                	ld	s5,24(sp)
    8000187c:	6b42                	ld	s6,16(sp)
    8000187e:	6ba2                	ld	s7,8(sp)
    80001880:	6c02                	ld	s8,0(sp)
    80001882:	6161                	addi	sp,sp,80
    80001884:	8082                	ret

0000000080001886 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001886:	c6c5                	beqz	a3,8000192e <copyinstr+0xa8>
{
    80001888:	715d                	addi	sp,sp,-80
    8000188a:	e486                	sd	ra,72(sp)
    8000188c:	e0a2                	sd	s0,64(sp)
    8000188e:	fc26                	sd	s1,56(sp)
    80001890:	f84a                	sd	s2,48(sp)
    80001892:	f44e                	sd	s3,40(sp)
    80001894:	f052                	sd	s4,32(sp)
    80001896:	ec56                	sd	s5,24(sp)
    80001898:	e85a                	sd	s6,16(sp)
    8000189a:	e45e                	sd	s7,8(sp)
    8000189c:	0880                	addi	s0,sp,80
    8000189e:	8a2a                	mv	s4,a0
    800018a0:	8b2e                	mv	s6,a1
    800018a2:	8bb2                	mv	s7,a2
    800018a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018a8:	6985                	lui	s3,0x1
    800018aa:	a035                	j	800018d6 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018b2:	0017b793          	seqz	a5,a5
    800018b6:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018ba:	60a6                	ld	ra,72(sp)
    800018bc:	6406                	ld	s0,64(sp)
    800018be:	74e2                	ld	s1,56(sp)
    800018c0:	7942                	ld	s2,48(sp)
    800018c2:	79a2                	ld	s3,40(sp)
    800018c4:	7a02                	ld	s4,32(sp)
    800018c6:	6ae2                	ld	s5,24(sp)
    800018c8:	6b42                	ld	s6,16(sp)
    800018ca:	6ba2                	ld	s7,8(sp)
    800018cc:	6161                	addi	sp,sp,80
    800018ce:	8082                	ret
    srcva = va0 + PGSIZE;
    800018d0:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018d4:	c8a9                	beqz	s1,80001926 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018d6:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018da:	85ca                	mv	a1,s2
    800018dc:	8552                	mv	a0,s4
    800018de:	00000097          	auipc	ra,0x0
    800018e2:	88c080e7          	jalr	-1908(ra) # 8000116a <walkaddr>
    if(pa0 == 0)
    800018e6:	c131                	beqz	a0,8000192a <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018e8:	41790833          	sub	a6,s2,s7
    800018ec:	984e                	add	a6,a6,s3
    if(n > max)
    800018ee:	0104f363          	bgeu	s1,a6,800018f4 <copyinstr+0x6e>
    800018f2:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018f4:	955e                	add	a0,a0,s7
    800018f6:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018fa:	fc080be3          	beqz	a6,800018d0 <copyinstr+0x4a>
    800018fe:	985a                	add	a6,a6,s6
    80001900:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001902:	41650633          	sub	a2,a0,s6
    80001906:	14fd                	addi	s1,s1,-1
    80001908:	9b26                	add	s6,s6,s1
    8000190a:	00f60733          	add	a4,a2,a5
    8000190e:	00074703          	lbu	a4,0(a4)
    80001912:	df49                	beqz	a4,800018ac <copyinstr+0x26>
        *dst = *p;
    80001914:	00e78023          	sb	a4,0(a5)
      --max;
    80001918:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000191c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000191e:	ff0796e3          	bne	a5,a6,8000190a <copyinstr+0x84>
      dst++;
    80001922:	8b42                	mv	s6,a6
    80001924:	b775                	j	800018d0 <copyinstr+0x4a>
    80001926:	4781                	li	a5,0
    80001928:	b769                	j	800018b2 <copyinstr+0x2c>
      return -1;
    8000192a:	557d                	li	a0,-1
    8000192c:	b779                	j	800018ba <copyinstr+0x34>
  int got_null = 0;
    8000192e:	4781                	li	a5,0
  if(got_null){
    80001930:	0017b793          	seqz	a5,a5
    80001934:	40f00533          	neg	a0,a5
}
    80001938:	8082                	ret

000000008000193a <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000193a:	7139                	addi	sp,sp,-64
    8000193c:	fc06                	sd	ra,56(sp)
    8000193e:	f822                	sd	s0,48(sp)
    80001940:	f426                	sd	s1,40(sp)
    80001942:	f04a                	sd	s2,32(sp)
    80001944:	ec4e                	sd	s3,24(sp)
    80001946:	e852                	sd	s4,16(sp)
    80001948:	e456                	sd	s5,8(sp)
    8000194a:	e05a                	sd	s6,0(sp)
    8000194c:	0080                	addi	s0,sp,64
    8000194e:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001950:	00030497          	auipc	s1,0x30
    80001954:	d8048493          	addi	s1,s1,-640 # 800316d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001958:	8b26                	mv	s6,s1
    8000195a:	00006a97          	auipc	s5,0x6
    8000195e:	6a6a8a93          	addi	s5,s5,1702 # 80008000 <etext>
    80001962:	04000937          	lui	s2,0x4000
    80001966:	197d                	addi	s2,s2,-1
    80001968:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196a:	00035a17          	auipc	s4,0x35
    8000196e:	766a0a13          	addi	s4,s4,1894 # 800370d0 <tickslock>
    char *pa = kalloc();
    80001972:	fffff097          	auipc	ra,0xfffff
    80001976:	274080e7          	jalr	628(ra) # 80000be6 <kalloc>
    8000197a:	862a                	mv	a2,a0
    if(pa == 0)
    8000197c:	c131                	beqz	a0,800019c0 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000197e:	416485b3          	sub	a1,s1,s6
    80001982:	858d                	srai	a1,a1,0x3
    80001984:	000ab783          	ld	a5,0(s5)
    80001988:	02f585b3          	mul	a1,a1,a5
    8000198c:	2585                	addiw	a1,a1,1
    8000198e:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001992:	4719                	li	a4,6
    80001994:	6685                	lui	a3,0x1
    80001996:	40b905b3          	sub	a1,s2,a1
    8000199a:	854e                	mv	a0,s3
    8000199c:	00000097          	auipc	ra,0x0
    800019a0:	8b0080e7          	jalr	-1872(ra) # 8000124c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a4:	16848493          	addi	s1,s1,360
    800019a8:	fd4495e3          	bne	s1,s4,80001972 <proc_mapstacks+0x38>
  }
}
    800019ac:	70e2                	ld	ra,56(sp)
    800019ae:	7442                	ld	s0,48(sp)
    800019b0:	74a2                	ld	s1,40(sp)
    800019b2:	7902                	ld	s2,32(sp)
    800019b4:	69e2                	ld	s3,24(sp)
    800019b6:	6a42                	ld	s4,16(sp)
    800019b8:	6aa2                	ld	s5,8(sp)
    800019ba:	6b02                	ld	s6,0(sp)
    800019bc:	6121                	addi	sp,sp,64
    800019be:	8082                	ret
      panic("kalloc");
    800019c0:	00007517          	auipc	a0,0x7
    800019c4:	81850513          	addi	a0,a0,-2024 # 800081d8 <digits+0x198>
    800019c8:	fffff097          	auipc	ra,0xfffff
    800019cc:	b76080e7          	jalr	-1162(ra) # 8000053e <panic>

00000000800019d0 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800019d0:	7139                	addi	sp,sp,-64
    800019d2:	fc06                	sd	ra,56(sp)
    800019d4:	f822                	sd	s0,48(sp)
    800019d6:	f426                	sd	s1,40(sp)
    800019d8:	f04a                	sd	s2,32(sp)
    800019da:	ec4e                	sd	s3,24(sp)
    800019dc:	e852                	sd	s4,16(sp)
    800019de:	e456                	sd	s5,8(sp)
    800019e0:	e05a                	sd	s6,0(sp)
    800019e2:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800019e4:	00006597          	auipc	a1,0x6
    800019e8:	7fc58593          	addi	a1,a1,2044 # 800081e0 <digits+0x1a0>
    800019ec:	00030517          	auipc	a0,0x30
    800019f0:	8b450513          	addi	a0,a0,-1868 # 800312a0 <pid_lock>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	25c080e7          	jalr	604(ra) # 80000c50 <initlock>
  initlock(&wait_lock, "wait_lock");
    800019fc:	00006597          	auipc	a1,0x6
    80001a00:	7ec58593          	addi	a1,a1,2028 # 800081e8 <digits+0x1a8>
    80001a04:	00030517          	auipc	a0,0x30
    80001a08:	8b450513          	addi	a0,a0,-1868 # 800312b8 <wait_lock>
    80001a0c:	fffff097          	auipc	ra,0xfffff
    80001a10:	244080e7          	jalr	580(ra) # 80000c50 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a14:	00030497          	auipc	s1,0x30
    80001a18:	cbc48493          	addi	s1,s1,-836 # 800316d0 <proc>
      initlock(&p->lock, "proc");
    80001a1c:	00006b17          	auipc	s6,0x6
    80001a20:	7dcb0b13          	addi	s6,s6,2012 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001a24:	8aa6                	mv	s5,s1
    80001a26:	00006a17          	auipc	s4,0x6
    80001a2a:	5daa0a13          	addi	s4,s4,1498 # 80008000 <etext>
    80001a2e:	04000937          	lui	s2,0x4000
    80001a32:	197d                	addi	s2,s2,-1
    80001a34:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a36:	00035997          	auipc	s3,0x35
    80001a3a:	69a98993          	addi	s3,s3,1690 # 800370d0 <tickslock>
      initlock(&p->lock, "proc");
    80001a3e:	85da                	mv	a1,s6
    80001a40:	8526                	mv	a0,s1
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	20e080e7          	jalr	526(ra) # 80000c50 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a4a:	415487b3          	sub	a5,s1,s5
    80001a4e:	878d                	srai	a5,a5,0x3
    80001a50:	000a3703          	ld	a4,0(s4)
    80001a54:	02e787b3          	mul	a5,a5,a4
    80001a58:	2785                	addiw	a5,a5,1
    80001a5a:	00d7979b          	slliw	a5,a5,0xd
    80001a5e:	40f907b3          	sub	a5,s2,a5
    80001a62:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a64:	16848493          	addi	s1,s1,360
    80001a68:	fd349be3          	bne	s1,s3,80001a3e <procinit+0x6e>
  }
}
    80001a6c:	70e2                	ld	ra,56(sp)
    80001a6e:	7442                	ld	s0,48(sp)
    80001a70:	74a2                	ld	s1,40(sp)
    80001a72:	7902                	ld	s2,32(sp)
    80001a74:	69e2                	ld	s3,24(sp)
    80001a76:	6a42                	ld	s4,16(sp)
    80001a78:	6aa2                	ld	s5,8(sp)
    80001a7a:	6b02                	ld	s6,0(sp)
    80001a7c:	6121                	addi	sp,sp,64
    80001a7e:	8082                	ret

0000000080001a80 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a80:	1141                	addi	sp,sp,-16
    80001a82:	e422                	sd	s0,8(sp)
    80001a84:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a86:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a88:	2501                	sext.w	a0,a0
    80001a8a:	6422                	ld	s0,8(sp)
    80001a8c:	0141                	addi	sp,sp,16
    80001a8e:	8082                	ret

0000000080001a90 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a90:	1141                	addi	sp,sp,-16
    80001a92:	e422                	sd	s0,8(sp)
    80001a94:	0800                	addi	s0,sp,16
    80001a96:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a98:	2781                	sext.w	a5,a5
    80001a9a:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a9c:	00030517          	auipc	a0,0x30
    80001aa0:	83450513          	addi	a0,a0,-1996 # 800312d0 <cpus>
    80001aa4:	953e                	add	a0,a0,a5
    80001aa6:	6422                	ld	s0,8(sp)
    80001aa8:	0141                	addi	sp,sp,16
    80001aaa:	8082                	ret

0000000080001aac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001aac:	1101                	addi	sp,sp,-32
    80001aae:	ec06                	sd	ra,24(sp)
    80001ab0:	e822                	sd	s0,16(sp)
    80001ab2:	e426                	sd	s1,8(sp)
    80001ab4:	1000                	addi	s0,sp,32
  push_off();
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	1de080e7          	jalr	478(ra) # 80000c94 <push_off>
    80001abe:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ac0:	2781                	sext.w	a5,a5
    80001ac2:	079e                	slli	a5,a5,0x7
    80001ac4:	0002f717          	auipc	a4,0x2f
    80001ac8:	7dc70713          	addi	a4,a4,2012 # 800312a0 <pid_lock>
    80001acc:	97ba                	add	a5,a5,a4
    80001ace:	7b84                	ld	s1,48(a5)
  pop_off();
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	264080e7          	jalr	612(ra) # 80000d34 <pop_off>
  return p;
}
    80001ad8:	8526                	mv	a0,s1
    80001ada:	60e2                	ld	ra,24(sp)
    80001adc:	6442                	ld	s0,16(sp)
    80001ade:	64a2                	ld	s1,8(sp)
    80001ae0:	6105                	addi	sp,sp,32
    80001ae2:	8082                	ret

0000000080001ae4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001ae4:	1141                	addi	sp,sp,-16
    80001ae6:	e406                	sd	ra,8(sp)
    80001ae8:	e022                	sd	s0,0(sp)
    80001aea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001aec:	00000097          	auipc	ra,0x0
    80001af0:	fc0080e7          	jalr	-64(ra) # 80001aac <myproc>
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	2a0080e7          	jalr	672(ra) # 80000d94 <release>

  if (first) {
    80001afc:	00007797          	auipc	a5,0x7
    80001b00:	d147a783          	lw	a5,-748(a5) # 80008810 <first.1681>
    80001b04:	eb89                	bnez	a5,80001b16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b06:	00001097          	auipc	ra,0x1
    80001b0a:	c0a080e7          	jalr	-1014(ra) # 80002710 <usertrapret>
}
    80001b0e:	60a2                	ld	ra,8(sp)
    80001b10:	6402                	ld	s0,0(sp)
    80001b12:	0141                	addi	sp,sp,16
    80001b14:	8082                	ret
    first = 0;
    80001b16:	00007797          	auipc	a5,0x7
    80001b1a:	ce07ad23          	sw	zero,-774(a5) # 80008810 <first.1681>
    fsinit(ROOTDEV);
    80001b1e:	4505                	li	a0,1
    80001b20:	00002097          	auipc	ra,0x2
    80001b24:	932080e7          	jalr	-1742(ra) # 80003452 <fsinit>
    80001b28:	bff9                	j	80001b06 <forkret+0x22>

0000000080001b2a <allocpid>:
allocpid() {
    80001b2a:	1101                	addi	sp,sp,-32
    80001b2c:	ec06                	sd	ra,24(sp)
    80001b2e:	e822                	sd	s0,16(sp)
    80001b30:	e426                	sd	s1,8(sp)
    80001b32:	e04a                	sd	s2,0(sp)
    80001b34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b36:	0002f917          	auipc	s2,0x2f
    80001b3a:	76a90913          	addi	s2,s2,1898 # 800312a0 <pid_lock>
    80001b3e:	854a                	mv	a0,s2
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	1a0080e7          	jalr	416(ra) # 80000ce0 <acquire>
  pid = nextpid;
    80001b48:	00007797          	auipc	a5,0x7
    80001b4c:	ccc78793          	addi	a5,a5,-820 # 80008814 <nextpid>
    80001b50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b52:	0014871b          	addiw	a4,s1,1
    80001b56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b58:	854a                	mv	a0,s2
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	23a080e7          	jalr	570(ra) # 80000d94 <release>
}
    80001b62:	8526                	mv	a0,s1
    80001b64:	60e2                	ld	ra,24(sp)
    80001b66:	6442                	ld	s0,16(sp)
    80001b68:	64a2                	ld	s1,8(sp)
    80001b6a:	6902                	ld	s2,0(sp)
    80001b6c:	6105                	addi	sp,sp,32
    80001b6e:	8082                	ret

0000000080001b70 <proc_pagetable>:
{
    80001b70:	1101                	addi	sp,sp,-32
    80001b72:	ec06                	sd	ra,24(sp)
    80001b74:	e822                	sd	s0,16(sp)
    80001b76:	e426                	sd	s1,8(sp)
    80001b78:	e04a                	sd	s2,0(sp)
    80001b7a:	1000                	addi	s0,sp,32
    80001b7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b7e:	00000097          	auipc	ra,0x0
    80001b82:	8b8080e7          	jalr	-1864(ra) # 80001436 <uvmcreate>
    80001b86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b88:	c121                	beqz	a0,80001bc8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b8a:	4729                	li	a4,10
    80001b8c:	00005697          	auipc	a3,0x5
    80001b90:	47468693          	addi	a3,a3,1140 # 80007000 <_trampoline>
    80001b94:	6605                	lui	a2,0x1
    80001b96:	040005b7          	lui	a1,0x4000
    80001b9a:	15fd                	addi	a1,a1,-1
    80001b9c:	05b2                	slli	a1,a1,0xc
    80001b9e:	fffff097          	auipc	ra,0xfffff
    80001ba2:	60e080e7          	jalr	1550(ra) # 800011ac <mappages>
    80001ba6:	02054863          	bltz	a0,80001bd6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001baa:	4719                	li	a4,6
    80001bac:	05893683          	ld	a3,88(s2)
    80001bb0:	6605                	lui	a2,0x1
    80001bb2:	020005b7          	lui	a1,0x2000
    80001bb6:	15fd                	addi	a1,a1,-1
    80001bb8:	05b6                	slli	a1,a1,0xd
    80001bba:	8526                	mv	a0,s1
    80001bbc:	fffff097          	auipc	ra,0xfffff
    80001bc0:	5f0080e7          	jalr	1520(ra) # 800011ac <mappages>
    80001bc4:	02054163          	bltz	a0,80001be6 <proc_pagetable+0x76>
}
    80001bc8:	8526                	mv	a0,s1
    80001bca:	60e2                	ld	ra,24(sp)
    80001bcc:	6442                	ld	s0,16(sp)
    80001bce:	64a2                	ld	s1,8(sp)
    80001bd0:	6902                	ld	s2,0(sp)
    80001bd2:	6105                	addi	sp,sp,32
    80001bd4:	8082                	ret
    uvmfree(pagetable, 0);
    80001bd6:	4581                	li	a1,0
    80001bd8:	8526                	mv	a0,s1
    80001bda:	00000097          	auipc	ra,0x0
    80001bde:	a58080e7          	jalr	-1448(ra) # 80001632 <uvmfree>
    return 0;
    80001be2:	4481                	li	s1,0
    80001be4:	b7d5                	j	80001bc8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001be6:	4681                	li	a3,0
    80001be8:	4605                	li	a2,1
    80001bea:	040005b7          	lui	a1,0x4000
    80001bee:	15fd                	addi	a1,a1,-1
    80001bf0:	05b2                	slli	a1,a1,0xc
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	77e080e7          	jalr	1918(ra) # 80001372 <uvmunmap>
    uvmfree(pagetable, 0);
    80001bfc:	4581                	li	a1,0
    80001bfe:	8526                	mv	a0,s1
    80001c00:	00000097          	auipc	ra,0x0
    80001c04:	a32080e7          	jalr	-1486(ra) # 80001632 <uvmfree>
    return 0;
    80001c08:	4481                	li	s1,0
    80001c0a:	bf7d                	j	80001bc8 <proc_pagetable+0x58>

0000000080001c0c <proc_freepagetable>:
{
    80001c0c:	1101                	addi	sp,sp,-32
    80001c0e:	ec06                	sd	ra,24(sp)
    80001c10:	e822                	sd	s0,16(sp)
    80001c12:	e426                	sd	s1,8(sp)
    80001c14:	e04a                	sd	s2,0(sp)
    80001c16:	1000                	addi	s0,sp,32
    80001c18:	84aa                	mv	s1,a0
    80001c1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c1c:	4681                	li	a3,0
    80001c1e:	4605                	li	a2,1
    80001c20:	040005b7          	lui	a1,0x4000
    80001c24:	15fd                	addi	a1,a1,-1
    80001c26:	05b2                	slli	a1,a1,0xc
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	74a080e7          	jalr	1866(ra) # 80001372 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c30:	4681                	li	a3,0
    80001c32:	4605                	li	a2,1
    80001c34:	020005b7          	lui	a1,0x2000
    80001c38:	15fd                	addi	a1,a1,-1
    80001c3a:	05b6                	slli	a1,a1,0xd
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	734080e7          	jalr	1844(ra) # 80001372 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c46:	85ca                	mv	a1,s2
    80001c48:	8526                	mv	a0,s1
    80001c4a:	00000097          	auipc	ra,0x0
    80001c4e:	9e8080e7          	jalr	-1560(ra) # 80001632 <uvmfree>
}
    80001c52:	60e2                	ld	ra,24(sp)
    80001c54:	6442                	ld	s0,16(sp)
    80001c56:	64a2                	ld	s1,8(sp)
    80001c58:	6902                	ld	s2,0(sp)
    80001c5a:	6105                	addi	sp,sp,32
    80001c5c:	8082                	ret

0000000080001c5e <freeproc>:
{
    80001c5e:	1101                	addi	sp,sp,-32
    80001c60:	ec06                	sd	ra,24(sp)
    80001c62:	e822                	sd	s0,16(sp)
    80001c64:	e426                	sd	s1,8(sp)
    80001c66:	1000                	addi	s0,sp,32
    80001c68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c6a:	6d28                	ld	a0,88(a0)
    80001c6c:	c509                	beqz	a0,80001c76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	dee080e7          	jalr	-530(ra) # 80000a5c <kfree>
  p->trapframe = 0;
    80001c76:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c7a:	68a8                	ld	a0,80(s1)
    80001c7c:	c511                	beqz	a0,80001c88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c7e:	64ac                	ld	a1,72(s1)
    80001c80:	00000097          	auipc	ra,0x0
    80001c84:	f8c080e7          	jalr	-116(ra) # 80001c0c <proc_freepagetable>
  p->pagetable = 0;
    80001c88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ca0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ca4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ca8:	0004ac23          	sw	zero,24(s1)
}
    80001cac:	60e2                	ld	ra,24(sp)
    80001cae:	6442                	ld	s0,16(sp)
    80001cb0:	64a2                	ld	s1,8(sp)
    80001cb2:	6105                	addi	sp,sp,32
    80001cb4:	8082                	ret

0000000080001cb6 <allocproc>:
{
    80001cb6:	1101                	addi	sp,sp,-32
    80001cb8:	ec06                	sd	ra,24(sp)
    80001cba:	e822                	sd	s0,16(sp)
    80001cbc:	e426                	sd	s1,8(sp)
    80001cbe:	e04a                	sd	s2,0(sp)
    80001cc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cc2:	00030497          	auipc	s1,0x30
    80001cc6:	a0e48493          	addi	s1,s1,-1522 # 800316d0 <proc>
    80001cca:	00035917          	auipc	s2,0x35
    80001cce:	40690913          	addi	s2,s2,1030 # 800370d0 <tickslock>
    acquire(&p->lock);
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	00c080e7          	jalr	12(ra) # 80000ce0 <acquire>
    if(p->state == UNUSED) {
    80001cdc:	4c9c                	lw	a5,24(s1)
    80001cde:	cf81                	beqz	a5,80001cf6 <allocproc+0x40>
      release(&p->lock);
    80001ce0:	8526                	mv	a0,s1
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	0b2080e7          	jalr	178(ra) # 80000d94 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cea:	16848493          	addi	s1,s1,360
    80001cee:	ff2492e3          	bne	s1,s2,80001cd2 <allocproc+0x1c>
  return 0;
    80001cf2:	4481                	li	s1,0
    80001cf4:	a889                	j	80001d46 <allocproc+0x90>
  p->pid = allocpid();
    80001cf6:	00000097          	auipc	ra,0x0
    80001cfa:	e34080e7          	jalr	-460(ra) # 80001b2a <allocpid>
    80001cfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d00:	4785                	li	a5,1
    80001d02:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	ee2080e7          	jalr	-286(ra) # 80000be6 <kalloc>
    80001d0c:	892a                	mv	s2,a0
    80001d0e:	eca8                	sd	a0,88(s1)
    80001d10:	c131                	beqz	a0,80001d54 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d12:	8526                	mv	a0,s1
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	e5c080e7          	jalr	-420(ra) # 80001b70 <proc_pagetable>
    80001d1c:	892a                	mv	s2,a0
    80001d1e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d20:	c531                	beqz	a0,80001d6c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d22:	07000613          	li	a2,112
    80001d26:	4581                	li	a1,0
    80001d28:	06048513          	addi	a0,s1,96
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	0b0080e7          	jalr	176(ra) # 80000ddc <memset>
  p->context.ra = (uint64)forkret;
    80001d34:	00000797          	auipc	a5,0x0
    80001d38:	db078793          	addi	a5,a5,-592 # 80001ae4 <forkret>
    80001d3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d3e:	60bc                	ld	a5,64(s1)
    80001d40:	6705                	lui	a4,0x1
    80001d42:	97ba                	add	a5,a5,a4
    80001d44:	f4bc                	sd	a5,104(s1)
}
    80001d46:	8526                	mv	a0,s1
    80001d48:	60e2                	ld	ra,24(sp)
    80001d4a:	6442                	ld	s0,16(sp)
    80001d4c:	64a2                	ld	s1,8(sp)
    80001d4e:	6902                	ld	s2,0(sp)
    80001d50:	6105                	addi	sp,sp,32
    80001d52:	8082                	ret
    freeproc(p);
    80001d54:	8526                	mv	a0,s1
    80001d56:	00000097          	auipc	ra,0x0
    80001d5a:	f08080e7          	jalr	-248(ra) # 80001c5e <freeproc>
    release(&p->lock);
    80001d5e:	8526                	mv	a0,s1
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	034080e7          	jalr	52(ra) # 80000d94 <release>
    return 0;
    80001d68:	84ca                	mv	s1,s2
    80001d6a:	bff1                	j	80001d46 <allocproc+0x90>
    freeproc(p);
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	00000097          	auipc	ra,0x0
    80001d72:	ef0080e7          	jalr	-272(ra) # 80001c5e <freeproc>
    release(&p->lock);
    80001d76:	8526                	mv	a0,s1
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	01c080e7          	jalr	28(ra) # 80000d94 <release>
    return 0;
    80001d80:	84ca                	mv	s1,s2
    80001d82:	b7d1                	j	80001d46 <allocproc+0x90>

0000000080001d84 <userinit>:
{
    80001d84:	1101                	addi	sp,sp,-32
    80001d86:	ec06                	sd	ra,24(sp)
    80001d88:	e822                	sd	s0,16(sp)
    80001d8a:	e426                	sd	s1,8(sp)
    80001d8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d8e:	00000097          	auipc	ra,0x0
    80001d92:	f28080e7          	jalr	-216(ra) # 80001cb6 <allocproc>
    80001d96:	84aa                	mv	s1,a0
  initproc = p;
    80001d98:	00007797          	auipc	a5,0x7
    80001d9c:	28a7b823          	sd	a0,656(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001da0:	03400613          	li	a2,52
    80001da4:	00007597          	auipc	a1,0x7
    80001da8:	a7c58593          	addi	a1,a1,-1412 # 80008820 <initcode>
    80001dac:	6928                	ld	a0,80(a0)
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	6b6080e7          	jalr	1718(ra) # 80001464 <uvminit>
  p->sz = PGSIZE;
    80001db6:	6785                	lui	a5,0x1
    80001db8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dba:	6cb8                	ld	a4,88(s1)
    80001dbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dc0:	6cb8                	ld	a4,88(s1)
    80001dc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dc4:	4641                	li	a2,16
    80001dc6:	00006597          	auipc	a1,0x6
    80001dca:	43a58593          	addi	a1,a1,1082 # 80008200 <digits+0x1c0>
    80001dce:	15848513          	addi	a0,s1,344
    80001dd2:	fffff097          	auipc	ra,0xfffff
    80001dd6:	15c080e7          	jalr	348(ra) # 80000f2e <safestrcpy>
  p->cwd = namei("/");
    80001dda:	00006517          	auipc	a0,0x6
    80001dde:	43650513          	addi	a0,a0,1078 # 80008210 <digits+0x1d0>
    80001de2:	00002097          	auipc	ra,0x2
    80001de6:	09e080e7          	jalr	158(ra) # 80003e80 <namei>
    80001dea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001dee:	478d                	li	a5,3
    80001df0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001df2:	8526                	mv	a0,s1
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	fa0080e7          	jalr	-96(ra) # 80000d94 <release>
}
    80001dfc:	60e2                	ld	ra,24(sp)
    80001dfe:	6442                	ld	s0,16(sp)
    80001e00:	64a2                	ld	s1,8(sp)
    80001e02:	6105                	addi	sp,sp,32
    80001e04:	8082                	ret

0000000080001e06 <growproc>:
{
    80001e06:	1101                	addi	sp,sp,-32
    80001e08:	ec06                	sd	ra,24(sp)
    80001e0a:	e822                	sd	s0,16(sp)
    80001e0c:	e426                	sd	s1,8(sp)
    80001e0e:	e04a                	sd	s2,0(sp)
    80001e10:	1000                	addi	s0,sp,32
    80001e12:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e14:	00000097          	auipc	ra,0x0
    80001e18:	c98080e7          	jalr	-872(ra) # 80001aac <myproc>
    80001e1c:	892a                	mv	s2,a0
  sz = p->sz;
    80001e1e:	652c                	ld	a1,72(a0)
    80001e20:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e24:	00904f63          	bgtz	s1,80001e42 <growproc+0x3c>
  } else if(n < 0){
    80001e28:	0204cc63          	bltz	s1,80001e60 <growproc+0x5a>
  p->sz = sz;
    80001e2c:	1602                	slli	a2,a2,0x20
    80001e2e:	9201                	srli	a2,a2,0x20
    80001e30:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e34:	4501                	li	a0,0
}
    80001e36:	60e2                	ld	ra,24(sp)
    80001e38:	6442                	ld	s0,16(sp)
    80001e3a:	64a2                	ld	s1,8(sp)
    80001e3c:	6902                	ld	s2,0(sp)
    80001e3e:	6105                	addi	sp,sp,32
    80001e40:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e42:	9e25                	addw	a2,a2,s1
    80001e44:	1602                	slli	a2,a2,0x20
    80001e46:	9201                	srli	a2,a2,0x20
    80001e48:	1582                	slli	a1,a1,0x20
    80001e4a:	9181                	srli	a1,a1,0x20
    80001e4c:	6928                	ld	a0,80(a0)
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	6d0080e7          	jalr	1744(ra) # 8000151e <uvmalloc>
    80001e56:	0005061b          	sext.w	a2,a0
    80001e5a:	fa69                	bnez	a2,80001e2c <growproc+0x26>
      return -1;
    80001e5c:	557d                	li	a0,-1
    80001e5e:	bfe1                	j	80001e36 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e60:	9e25                	addw	a2,a2,s1
    80001e62:	1602                	slli	a2,a2,0x20
    80001e64:	9201                	srli	a2,a2,0x20
    80001e66:	1582                	slli	a1,a1,0x20
    80001e68:	9181                	srli	a1,a1,0x20
    80001e6a:	6928                	ld	a0,80(a0)
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	66a080e7          	jalr	1642(ra) # 800014d6 <uvmdealloc>
    80001e74:	0005061b          	sext.w	a2,a0
    80001e78:	bf55                	j	80001e2c <growproc+0x26>

0000000080001e7a <fork>:
{
    80001e7a:	7179                	addi	sp,sp,-48
    80001e7c:	f406                	sd	ra,40(sp)
    80001e7e:	f022                	sd	s0,32(sp)
    80001e80:	ec26                	sd	s1,24(sp)
    80001e82:	e84a                	sd	s2,16(sp)
    80001e84:	e44e                	sd	s3,8(sp)
    80001e86:	e052                	sd	s4,0(sp)
    80001e88:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e8a:	00000097          	auipc	ra,0x0
    80001e8e:	c22080e7          	jalr	-990(ra) # 80001aac <myproc>
    80001e92:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e94:	00000097          	auipc	ra,0x0
    80001e98:	e22080e7          	jalr	-478(ra) # 80001cb6 <allocproc>
    80001e9c:	10050b63          	beqz	a0,80001fb2 <fork+0x138>
    80001ea0:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001ea2:	04893603          	ld	a2,72(s2)
    80001ea6:	692c                	ld	a1,80(a0)
    80001ea8:	05093503          	ld	a0,80(s2)
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	7be080e7          	jalr	1982(ra) # 8000166a <uvmcopy>
    80001eb4:	04054663          	bltz	a0,80001f00 <fork+0x86>
  np->sz = p->sz;
    80001eb8:	04893783          	ld	a5,72(s2)
    80001ebc:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ec0:	05893683          	ld	a3,88(s2)
    80001ec4:	87b6                	mv	a5,a3
    80001ec6:	0589b703          	ld	a4,88(s3)
    80001eca:	12068693          	addi	a3,a3,288
    80001ece:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ed2:	6788                	ld	a0,8(a5)
    80001ed4:	6b8c                	ld	a1,16(a5)
    80001ed6:	6f90                	ld	a2,24(a5)
    80001ed8:	01073023          	sd	a6,0(a4)
    80001edc:	e708                	sd	a0,8(a4)
    80001ede:	eb0c                	sd	a1,16(a4)
    80001ee0:	ef10                	sd	a2,24(a4)
    80001ee2:	02078793          	addi	a5,a5,32
    80001ee6:	02070713          	addi	a4,a4,32
    80001eea:	fed792e3          	bne	a5,a3,80001ece <fork+0x54>
  np->trapframe->a0 = 0;
    80001eee:	0589b783          	ld	a5,88(s3)
    80001ef2:	0607b823          	sd	zero,112(a5)
    80001ef6:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001efa:	15000a13          	li	s4,336
    80001efe:	a03d                	j	80001f2c <fork+0xb2>
    freeproc(np);
    80001f00:	854e                	mv	a0,s3
    80001f02:	00000097          	auipc	ra,0x0
    80001f06:	d5c080e7          	jalr	-676(ra) # 80001c5e <freeproc>
    release(&np->lock);
    80001f0a:	854e                	mv	a0,s3
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	e88080e7          	jalr	-376(ra) # 80000d94 <release>
    return -1;
    80001f14:	5a7d                	li	s4,-1
    80001f16:	a069                	j	80001fa0 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f18:	00002097          	auipc	ra,0x2
    80001f1c:	5fe080e7          	jalr	1534(ra) # 80004516 <filedup>
    80001f20:	009987b3          	add	a5,s3,s1
    80001f24:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f26:	04a1                	addi	s1,s1,8
    80001f28:	01448763          	beq	s1,s4,80001f36 <fork+0xbc>
    if(p->ofile[i])
    80001f2c:	009907b3          	add	a5,s2,s1
    80001f30:	6388                	ld	a0,0(a5)
    80001f32:	f17d                	bnez	a0,80001f18 <fork+0x9e>
    80001f34:	bfcd                	j	80001f26 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001f36:	15093503          	ld	a0,336(s2)
    80001f3a:	00001097          	auipc	ra,0x1
    80001f3e:	752080e7          	jalr	1874(ra) # 8000368c <idup>
    80001f42:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f46:	4641                	li	a2,16
    80001f48:	15890593          	addi	a1,s2,344
    80001f4c:	15898513          	addi	a0,s3,344
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	fde080e7          	jalr	-34(ra) # 80000f2e <safestrcpy>
  pid = np->pid;
    80001f58:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f5c:	854e                	mv	a0,s3
    80001f5e:	fffff097          	auipc	ra,0xfffff
    80001f62:	e36080e7          	jalr	-458(ra) # 80000d94 <release>
  acquire(&wait_lock);
    80001f66:	0002f497          	auipc	s1,0x2f
    80001f6a:	35248493          	addi	s1,s1,850 # 800312b8 <wait_lock>
    80001f6e:	8526                	mv	a0,s1
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	d70080e7          	jalr	-656(ra) # 80000ce0 <acquire>
  np->parent = p;
    80001f78:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001f7c:	8526                	mv	a0,s1
    80001f7e:	fffff097          	auipc	ra,0xfffff
    80001f82:	e16080e7          	jalr	-490(ra) # 80000d94 <release>
  acquire(&np->lock);
    80001f86:	854e                	mv	a0,s3
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	d58080e7          	jalr	-680(ra) # 80000ce0 <acquire>
  np->state = RUNNABLE;
    80001f90:	478d                	li	a5,3
    80001f92:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f96:	854e                	mv	a0,s3
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	dfc080e7          	jalr	-516(ra) # 80000d94 <release>
}
    80001fa0:	8552                	mv	a0,s4
    80001fa2:	70a2                	ld	ra,40(sp)
    80001fa4:	7402                	ld	s0,32(sp)
    80001fa6:	64e2                	ld	s1,24(sp)
    80001fa8:	6942                	ld	s2,16(sp)
    80001faa:	69a2                	ld	s3,8(sp)
    80001fac:	6a02                	ld	s4,0(sp)
    80001fae:	6145                	addi	sp,sp,48
    80001fb0:	8082                	ret
    return -1;
    80001fb2:	5a7d                	li	s4,-1
    80001fb4:	b7f5                	j	80001fa0 <fork+0x126>

0000000080001fb6 <scheduler>:
{
    80001fb6:	7139                	addi	sp,sp,-64
    80001fb8:	fc06                	sd	ra,56(sp)
    80001fba:	f822                	sd	s0,48(sp)
    80001fbc:	f426                	sd	s1,40(sp)
    80001fbe:	f04a                	sd	s2,32(sp)
    80001fc0:	ec4e                	sd	s3,24(sp)
    80001fc2:	e852                	sd	s4,16(sp)
    80001fc4:	e456                	sd	s5,8(sp)
    80001fc6:	e05a                	sd	s6,0(sp)
    80001fc8:	0080                	addi	s0,sp,64
    80001fca:	8792                	mv	a5,tp
  int id = r_tp();
    80001fcc:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fce:	00779a93          	slli	s5,a5,0x7
    80001fd2:	0002f717          	auipc	a4,0x2f
    80001fd6:	2ce70713          	addi	a4,a4,718 # 800312a0 <pid_lock>
    80001fda:	9756                	add	a4,a4,s5
    80001fdc:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001fe0:	0002f717          	auipc	a4,0x2f
    80001fe4:	2f870713          	addi	a4,a4,760 # 800312d8 <cpus+0x8>
    80001fe8:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001fea:	498d                	li	s3,3
        p->state = RUNNING;
    80001fec:	4b11                	li	s6,4
        c->proc = p;
    80001fee:	079e                	slli	a5,a5,0x7
    80001ff0:	0002fa17          	auipc	s4,0x2f
    80001ff4:	2b0a0a13          	addi	s4,s4,688 # 800312a0 <pid_lock>
    80001ff8:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ffa:	00035917          	auipc	s2,0x35
    80001ffe:	0d690913          	addi	s2,s2,214 # 800370d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002002:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002006:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000200a:	10079073          	csrw	sstatus,a5
    8000200e:	0002f497          	auipc	s1,0x2f
    80002012:	6c248493          	addi	s1,s1,1730 # 800316d0 <proc>
    80002016:	a03d                	j	80002044 <scheduler+0x8e>
        p->state = RUNNING;
    80002018:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    8000201c:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002020:	06048593          	addi	a1,s1,96
    80002024:	8556                	mv	a0,s5
    80002026:	00000097          	auipc	ra,0x0
    8000202a:	640080e7          	jalr	1600(ra) # 80002666 <swtch>
        c->proc = 0;
    8000202e:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80002032:	8526                	mv	a0,s1
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	d60080e7          	jalr	-672(ra) # 80000d94 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000203c:	16848493          	addi	s1,s1,360
    80002040:	fd2481e3          	beq	s1,s2,80002002 <scheduler+0x4c>
      acquire(&p->lock);
    80002044:	8526                	mv	a0,s1
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	c9a080e7          	jalr	-870(ra) # 80000ce0 <acquire>
      if(p->state == RUNNABLE) {
    8000204e:	4c9c                	lw	a5,24(s1)
    80002050:	ff3791e3          	bne	a5,s3,80002032 <scheduler+0x7c>
    80002054:	b7d1                	j	80002018 <scheduler+0x62>

0000000080002056 <sched>:
{
    80002056:	7179                	addi	sp,sp,-48
    80002058:	f406                	sd	ra,40(sp)
    8000205a:	f022                	sd	s0,32(sp)
    8000205c:	ec26                	sd	s1,24(sp)
    8000205e:	e84a                	sd	s2,16(sp)
    80002060:	e44e                	sd	s3,8(sp)
    80002062:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002064:	00000097          	auipc	ra,0x0
    80002068:	a48080e7          	jalr	-1464(ra) # 80001aac <myproc>
    8000206c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	bf8080e7          	jalr	-1032(ra) # 80000c66 <holding>
    80002076:	c93d                	beqz	a0,800020ec <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002078:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000207a:	2781                	sext.w	a5,a5
    8000207c:	079e                	slli	a5,a5,0x7
    8000207e:	0002f717          	auipc	a4,0x2f
    80002082:	22270713          	addi	a4,a4,546 # 800312a0 <pid_lock>
    80002086:	97ba                	add	a5,a5,a4
    80002088:	0a87a703          	lw	a4,168(a5)
    8000208c:	4785                	li	a5,1
    8000208e:	06f71763          	bne	a4,a5,800020fc <sched+0xa6>
  if(p->state == RUNNING)
    80002092:	4c98                	lw	a4,24(s1)
    80002094:	4791                	li	a5,4
    80002096:	06f70b63          	beq	a4,a5,8000210c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000209a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000209e:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020a0:	efb5                	bnez	a5,8000211c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020a2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020a4:	0002f917          	auipc	s2,0x2f
    800020a8:	1fc90913          	addi	s2,s2,508 # 800312a0 <pid_lock>
    800020ac:	2781                	sext.w	a5,a5
    800020ae:	079e                	slli	a5,a5,0x7
    800020b0:	97ca                	add	a5,a5,s2
    800020b2:	0ac7a983          	lw	s3,172(a5)
    800020b6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020b8:	2781                	sext.w	a5,a5
    800020ba:	079e                	slli	a5,a5,0x7
    800020bc:	0002f597          	auipc	a1,0x2f
    800020c0:	21c58593          	addi	a1,a1,540 # 800312d8 <cpus+0x8>
    800020c4:	95be                	add	a1,a1,a5
    800020c6:	06048513          	addi	a0,s1,96
    800020ca:	00000097          	auipc	ra,0x0
    800020ce:	59c080e7          	jalr	1436(ra) # 80002666 <swtch>
    800020d2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020d4:	2781                	sext.w	a5,a5
    800020d6:	079e                	slli	a5,a5,0x7
    800020d8:	97ca                	add	a5,a5,s2
    800020da:	0b37a623          	sw	s3,172(a5)
}
    800020de:	70a2                	ld	ra,40(sp)
    800020e0:	7402                	ld	s0,32(sp)
    800020e2:	64e2                	ld	s1,24(sp)
    800020e4:	6942                	ld	s2,16(sp)
    800020e6:	69a2                	ld	s3,8(sp)
    800020e8:	6145                	addi	sp,sp,48
    800020ea:	8082                	ret
    panic("sched p->lock");
    800020ec:	00006517          	auipc	a0,0x6
    800020f0:	12c50513          	addi	a0,a0,300 # 80008218 <digits+0x1d8>
    800020f4:	ffffe097          	auipc	ra,0xffffe
    800020f8:	44a080e7          	jalr	1098(ra) # 8000053e <panic>
    panic("sched locks");
    800020fc:	00006517          	auipc	a0,0x6
    80002100:	12c50513          	addi	a0,a0,300 # 80008228 <digits+0x1e8>
    80002104:	ffffe097          	auipc	ra,0xffffe
    80002108:	43a080e7          	jalr	1082(ra) # 8000053e <panic>
    panic("sched running");
    8000210c:	00006517          	auipc	a0,0x6
    80002110:	12c50513          	addi	a0,a0,300 # 80008238 <digits+0x1f8>
    80002114:	ffffe097          	auipc	ra,0xffffe
    80002118:	42a080e7          	jalr	1066(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000211c:	00006517          	auipc	a0,0x6
    80002120:	12c50513          	addi	a0,a0,300 # 80008248 <digits+0x208>
    80002124:	ffffe097          	auipc	ra,0xffffe
    80002128:	41a080e7          	jalr	1050(ra) # 8000053e <panic>

000000008000212c <yield>:
{
    8000212c:	1101                	addi	sp,sp,-32
    8000212e:	ec06                	sd	ra,24(sp)
    80002130:	e822                	sd	s0,16(sp)
    80002132:	e426                	sd	s1,8(sp)
    80002134:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002136:	00000097          	auipc	ra,0x0
    8000213a:	976080e7          	jalr	-1674(ra) # 80001aac <myproc>
    8000213e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	ba0080e7          	jalr	-1120(ra) # 80000ce0 <acquire>
  p->state = RUNNABLE;
    80002148:	478d                	li	a5,3
    8000214a:	cc9c                	sw	a5,24(s1)
  sched();
    8000214c:	00000097          	auipc	ra,0x0
    80002150:	f0a080e7          	jalr	-246(ra) # 80002056 <sched>
  release(&p->lock);
    80002154:	8526                	mv	a0,s1
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	c3e080e7          	jalr	-962(ra) # 80000d94 <release>
}
    8000215e:	60e2                	ld	ra,24(sp)
    80002160:	6442                	ld	s0,16(sp)
    80002162:	64a2                	ld	s1,8(sp)
    80002164:	6105                	addi	sp,sp,32
    80002166:	8082                	ret

0000000080002168 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002168:	7179                	addi	sp,sp,-48
    8000216a:	f406                	sd	ra,40(sp)
    8000216c:	f022                	sd	s0,32(sp)
    8000216e:	ec26                	sd	s1,24(sp)
    80002170:	e84a                	sd	s2,16(sp)
    80002172:	e44e                	sd	s3,8(sp)
    80002174:	1800                	addi	s0,sp,48
    80002176:	89aa                	mv	s3,a0
    80002178:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000217a:	00000097          	auipc	ra,0x0
    8000217e:	932080e7          	jalr	-1742(ra) # 80001aac <myproc>
    80002182:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	b5c080e7          	jalr	-1188(ra) # 80000ce0 <acquire>
  release(lk);
    8000218c:	854a                	mv	a0,s2
    8000218e:	fffff097          	auipc	ra,0xfffff
    80002192:	c06080e7          	jalr	-1018(ra) # 80000d94 <release>

  // Go to sleep.
  p->chan = chan;
    80002196:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000219a:	4789                	li	a5,2
    8000219c:	cc9c                	sw	a5,24(s1)

  sched();
    8000219e:	00000097          	auipc	ra,0x0
    800021a2:	eb8080e7          	jalr	-328(ra) # 80002056 <sched>

  // Tidy up.
  p->chan = 0;
    800021a6:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021aa:	8526                	mv	a0,s1
    800021ac:	fffff097          	auipc	ra,0xfffff
    800021b0:	be8080e7          	jalr	-1048(ra) # 80000d94 <release>
  acquire(lk);
    800021b4:	854a                	mv	a0,s2
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	b2a080e7          	jalr	-1238(ra) # 80000ce0 <acquire>
}
    800021be:	70a2                	ld	ra,40(sp)
    800021c0:	7402                	ld	s0,32(sp)
    800021c2:	64e2                	ld	s1,24(sp)
    800021c4:	6942                	ld	s2,16(sp)
    800021c6:	69a2                	ld	s3,8(sp)
    800021c8:	6145                	addi	sp,sp,48
    800021ca:	8082                	ret

00000000800021cc <wait>:
{
    800021cc:	715d                	addi	sp,sp,-80
    800021ce:	e486                	sd	ra,72(sp)
    800021d0:	e0a2                	sd	s0,64(sp)
    800021d2:	fc26                	sd	s1,56(sp)
    800021d4:	f84a                	sd	s2,48(sp)
    800021d6:	f44e                	sd	s3,40(sp)
    800021d8:	f052                	sd	s4,32(sp)
    800021da:	ec56                	sd	s5,24(sp)
    800021dc:	e85a                	sd	s6,16(sp)
    800021de:	e45e                	sd	s7,8(sp)
    800021e0:	e062                	sd	s8,0(sp)
    800021e2:	0880                	addi	s0,sp,80
    800021e4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800021e6:	00000097          	auipc	ra,0x0
    800021ea:	8c6080e7          	jalr	-1850(ra) # 80001aac <myproc>
    800021ee:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021f0:	0002f517          	auipc	a0,0x2f
    800021f4:	0c850513          	addi	a0,a0,200 # 800312b8 <wait_lock>
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	ae8080e7          	jalr	-1304(ra) # 80000ce0 <acquire>
    havekids = 0;
    80002200:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002202:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002204:	00035997          	auipc	s3,0x35
    80002208:	ecc98993          	addi	s3,s3,-308 # 800370d0 <tickslock>
        havekids = 1;
    8000220c:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000220e:	0002fc17          	auipc	s8,0x2f
    80002212:	0aac0c13          	addi	s8,s8,170 # 800312b8 <wait_lock>
    havekids = 0;
    80002216:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002218:	0002f497          	auipc	s1,0x2f
    8000221c:	4b848493          	addi	s1,s1,1208 # 800316d0 <proc>
    80002220:	a0bd                	j	8000228e <wait+0xc2>
          pid = np->pid;
    80002222:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002226:	000b0e63          	beqz	s6,80002242 <wait+0x76>
    8000222a:	4691                	li	a3,4
    8000222c:	02c48613          	addi	a2,s1,44
    80002230:	85da                	mv	a1,s6
    80002232:	05093503          	ld	a0,80(s2)
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	538080e7          	jalr	1336(ra) # 8000176e <copyout>
    8000223e:	02054563          	bltz	a0,80002268 <wait+0x9c>
          freeproc(np);
    80002242:	8526                	mv	a0,s1
    80002244:	00000097          	auipc	ra,0x0
    80002248:	a1a080e7          	jalr	-1510(ra) # 80001c5e <freeproc>
          release(&np->lock);
    8000224c:	8526                	mv	a0,s1
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	b46080e7          	jalr	-1210(ra) # 80000d94 <release>
          release(&wait_lock);
    80002256:	0002f517          	auipc	a0,0x2f
    8000225a:	06250513          	addi	a0,a0,98 # 800312b8 <wait_lock>
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	b36080e7          	jalr	-1226(ra) # 80000d94 <release>
          return pid;
    80002266:	a09d                	j	800022cc <wait+0x100>
            release(&np->lock);
    80002268:	8526                	mv	a0,s1
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	b2a080e7          	jalr	-1238(ra) # 80000d94 <release>
            release(&wait_lock);
    80002272:	0002f517          	auipc	a0,0x2f
    80002276:	04650513          	addi	a0,a0,70 # 800312b8 <wait_lock>
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	b1a080e7          	jalr	-1254(ra) # 80000d94 <release>
            return -1;
    80002282:	59fd                	li	s3,-1
    80002284:	a0a1                	j	800022cc <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002286:	16848493          	addi	s1,s1,360
    8000228a:	03348463          	beq	s1,s3,800022b2 <wait+0xe6>
      if(np->parent == p){
    8000228e:	7c9c                	ld	a5,56(s1)
    80002290:	ff279be3          	bne	a5,s2,80002286 <wait+0xba>
        acquire(&np->lock);
    80002294:	8526                	mv	a0,s1
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	a4a080e7          	jalr	-1462(ra) # 80000ce0 <acquire>
        if(np->state == ZOMBIE){
    8000229e:	4c9c                	lw	a5,24(s1)
    800022a0:	f94781e3          	beq	a5,s4,80002222 <wait+0x56>
        release(&np->lock);
    800022a4:	8526                	mv	a0,s1
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	aee080e7          	jalr	-1298(ra) # 80000d94 <release>
        havekids = 1;
    800022ae:	8756                	mv	a4,s5
    800022b0:	bfd9                	j	80002286 <wait+0xba>
    if(!havekids || p->killed){
    800022b2:	c701                	beqz	a4,800022ba <wait+0xee>
    800022b4:	02892783          	lw	a5,40(s2)
    800022b8:	c79d                	beqz	a5,800022e6 <wait+0x11a>
      release(&wait_lock);
    800022ba:	0002f517          	auipc	a0,0x2f
    800022be:	ffe50513          	addi	a0,a0,-2 # 800312b8 <wait_lock>
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	ad2080e7          	jalr	-1326(ra) # 80000d94 <release>
      return -1;
    800022ca:	59fd                	li	s3,-1
}
    800022cc:	854e                	mv	a0,s3
    800022ce:	60a6                	ld	ra,72(sp)
    800022d0:	6406                	ld	s0,64(sp)
    800022d2:	74e2                	ld	s1,56(sp)
    800022d4:	7942                	ld	s2,48(sp)
    800022d6:	79a2                	ld	s3,40(sp)
    800022d8:	7a02                	ld	s4,32(sp)
    800022da:	6ae2                	ld	s5,24(sp)
    800022dc:	6b42                	ld	s6,16(sp)
    800022de:	6ba2                	ld	s7,8(sp)
    800022e0:	6c02                	ld	s8,0(sp)
    800022e2:	6161                	addi	sp,sp,80
    800022e4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022e6:	85e2                	mv	a1,s8
    800022e8:	854a                	mv	a0,s2
    800022ea:	00000097          	auipc	ra,0x0
    800022ee:	e7e080e7          	jalr	-386(ra) # 80002168 <sleep>
    havekids = 0;
    800022f2:	b715                	j	80002216 <wait+0x4a>

00000000800022f4 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800022f4:	7139                	addi	sp,sp,-64
    800022f6:	fc06                	sd	ra,56(sp)
    800022f8:	f822                	sd	s0,48(sp)
    800022fa:	f426                	sd	s1,40(sp)
    800022fc:	f04a                	sd	s2,32(sp)
    800022fe:	ec4e                	sd	s3,24(sp)
    80002300:	e852                	sd	s4,16(sp)
    80002302:	e456                	sd	s5,8(sp)
    80002304:	0080                	addi	s0,sp,64
    80002306:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002308:	0002f497          	auipc	s1,0x2f
    8000230c:	3c848493          	addi	s1,s1,968 # 800316d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002310:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002312:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002314:	00035917          	auipc	s2,0x35
    80002318:	dbc90913          	addi	s2,s2,-580 # 800370d0 <tickslock>
    8000231c:	a821                	j	80002334 <wakeup+0x40>
        p->state = RUNNABLE;
    8000231e:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002322:	8526                	mv	a0,s1
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	a70080e7          	jalr	-1424(ra) # 80000d94 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000232c:	16848493          	addi	s1,s1,360
    80002330:	03248463          	beq	s1,s2,80002358 <wakeup+0x64>
    if(p != myproc()){
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	778080e7          	jalr	1912(ra) # 80001aac <myproc>
    8000233c:	fea488e3          	beq	s1,a0,8000232c <wakeup+0x38>
      acquire(&p->lock);
    80002340:	8526                	mv	a0,s1
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	99e080e7          	jalr	-1634(ra) # 80000ce0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000234a:	4c9c                	lw	a5,24(s1)
    8000234c:	fd379be3          	bne	a5,s3,80002322 <wakeup+0x2e>
    80002350:	709c                	ld	a5,32(s1)
    80002352:	fd4798e3          	bne	a5,s4,80002322 <wakeup+0x2e>
    80002356:	b7e1                	j	8000231e <wakeup+0x2a>
    }
  }
}
    80002358:	70e2                	ld	ra,56(sp)
    8000235a:	7442                	ld	s0,48(sp)
    8000235c:	74a2                	ld	s1,40(sp)
    8000235e:	7902                	ld	s2,32(sp)
    80002360:	69e2                	ld	s3,24(sp)
    80002362:	6a42                	ld	s4,16(sp)
    80002364:	6aa2                	ld	s5,8(sp)
    80002366:	6121                	addi	sp,sp,64
    80002368:	8082                	ret

000000008000236a <reparent>:
{
    8000236a:	7179                	addi	sp,sp,-48
    8000236c:	f406                	sd	ra,40(sp)
    8000236e:	f022                	sd	s0,32(sp)
    80002370:	ec26                	sd	s1,24(sp)
    80002372:	e84a                	sd	s2,16(sp)
    80002374:	e44e                	sd	s3,8(sp)
    80002376:	e052                	sd	s4,0(sp)
    80002378:	1800                	addi	s0,sp,48
    8000237a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000237c:	0002f497          	auipc	s1,0x2f
    80002380:	35448493          	addi	s1,s1,852 # 800316d0 <proc>
      pp->parent = initproc;
    80002384:	00007a17          	auipc	s4,0x7
    80002388:	ca4a0a13          	addi	s4,s4,-860 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000238c:	00035997          	auipc	s3,0x35
    80002390:	d4498993          	addi	s3,s3,-700 # 800370d0 <tickslock>
    80002394:	a029                	j	8000239e <reparent+0x34>
    80002396:	16848493          	addi	s1,s1,360
    8000239a:	01348d63          	beq	s1,s3,800023b4 <reparent+0x4a>
    if(pp->parent == p){
    8000239e:	7c9c                	ld	a5,56(s1)
    800023a0:	ff279be3          	bne	a5,s2,80002396 <reparent+0x2c>
      pp->parent = initproc;
    800023a4:	000a3503          	ld	a0,0(s4)
    800023a8:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800023aa:	00000097          	auipc	ra,0x0
    800023ae:	f4a080e7          	jalr	-182(ra) # 800022f4 <wakeup>
    800023b2:	b7d5                	j	80002396 <reparent+0x2c>
}
    800023b4:	70a2                	ld	ra,40(sp)
    800023b6:	7402                	ld	s0,32(sp)
    800023b8:	64e2                	ld	s1,24(sp)
    800023ba:	6942                	ld	s2,16(sp)
    800023bc:	69a2                	ld	s3,8(sp)
    800023be:	6a02                	ld	s4,0(sp)
    800023c0:	6145                	addi	sp,sp,48
    800023c2:	8082                	ret

00000000800023c4 <exit>:
{
    800023c4:	7179                	addi	sp,sp,-48
    800023c6:	f406                	sd	ra,40(sp)
    800023c8:	f022                	sd	s0,32(sp)
    800023ca:	ec26                	sd	s1,24(sp)
    800023cc:	e84a                	sd	s2,16(sp)
    800023ce:	e44e                	sd	s3,8(sp)
    800023d0:	e052                	sd	s4,0(sp)
    800023d2:	1800                	addi	s0,sp,48
    800023d4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	6d6080e7          	jalr	1750(ra) # 80001aac <myproc>
    800023de:	89aa                	mv	s3,a0
  if(p == initproc)
    800023e0:	00007797          	auipc	a5,0x7
    800023e4:	c487b783          	ld	a5,-952(a5) # 80009028 <initproc>
    800023e8:	0d050493          	addi	s1,a0,208
    800023ec:	15050913          	addi	s2,a0,336
    800023f0:	02a79363          	bne	a5,a0,80002416 <exit+0x52>
    panic("init exiting");
    800023f4:	00006517          	auipc	a0,0x6
    800023f8:	e6c50513          	addi	a0,a0,-404 # 80008260 <digits+0x220>
    800023fc:	ffffe097          	auipc	ra,0xffffe
    80002400:	142080e7          	jalr	322(ra) # 8000053e <panic>
      fileclose(f);
    80002404:	00002097          	auipc	ra,0x2
    80002408:	164080e7          	jalr	356(ra) # 80004568 <fileclose>
      p->ofile[fd] = 0;
    8000240c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002410:	04a1                	addi	s1,s1,8
    80002412:	01248563          	beq	s1,s2,8000241c <exit+0x58>
    if(p->ofile[fd]){
    80002416:	6088                	ld	a0,0(s1)
    80002418:	f575                	bnez	a0,80002404 <exit+0x40>
    8000241a:	bfdd                	j	80002410 <exit+0x4c>
  begin_op();
    8000241c:	00002097          	auipc	ra,0x2
    80002420:	c80080e7          	jalr	-896(ra) # 8000409c <begin_op>
  iput(p->cwd);
    80002424:	1509b503          	ld	a0,336(s3)
    80002428:	00001097          	auipc	ra,0x1
    8000242c:	45c080e7          	jalr	1116(ra) # 80003884 <iput>
  end_op();
    80002430:	00002097          	auipc	ra,0x2
    80002434:	cec080e7          	jalr	-788(ra) # 8000411c <end_op>
  p->cwd = 0;
    80002438:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000243c:	0002f497          	auipc	s1,0x2f
    80002440:	e7c48493          	addi	s1,s1,-388 # 800312b8 <wait_lock>
    80002444:	8526                	mv	a0,s1
    80002446:	fffff097          	auipc	ra,0xfffff
    8000244a:	89a080e7          	jalr	-1894(ra) # 80000ce0 <acquire>
  reparent(p);
    8000244e:	854e                	mv	a0,s3
    80002450:	00000097          	auipc	ra,0x0
    80002454:	f1a080e7          	jalr	-230(ra) # 8000236a <reparent>
  wakeup(p->parent);
    80002458:	0389b503          	ld	a0,56(s3)
    8000245c:	00000097          	auipc	ra,0x0
    80002460:	e98080e7          	jalr	-360(ra) # 800022f4 <wakeup>
  acquire(&p->lock);
    80002464:	854e                	mv	a0,s3
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	87a080e7          	jalr	-1926(ra) # 80000ce0 <acquire>
  p->xstate = status;
    8000246e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002472:	4795                	li	a5,5
    80002474:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002478:	8526                	mv	a0,s1
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	91a080e7          	jalr	-1766(ra) # 80000d94 <release>
  sched();
    80002482:	00000097          	auipc	ra,0x0
    80002486:	bd4080e7          	jalr	-1068(ra) # 80002056 <sched>
  panic("zombie exit");
    8000248a:	00006517          	auipc	a0,0x6
    8000248e:	de650513          	addi	a0,a0,-538 # 80008270 <digits+0x230>
    80002492:	ffffe097          	auipc	ra,0xffffe
    80002496:	0ac080e7          	jalr	172(ra) # 8000053e <panic>

000000008000249a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000249a:	7179                	addi	sp,sp,-48
    8000249c:	f406                	sd	ra,40(sp)
    8000249e:	f022                	sd	s0,32(sp)
    800024a0:	ec26                	sd	s1,24(sp)
    800024a2:	e84a                	sd	s2,16(sp)
    800024a4:	e44e                	sd	s3,8(sp)
    800024a6:	1800                	addi	s0,sp,48
    800024a8:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024aa:	0002f497          	auipc	s1,0x2f
    800024ae:	22648493          	addi	s1,s1,550 # 800316d0 <proc>
    800024b2:	00035997          	auipc	s3,0x35
    800024b6:	c1e98993          	addi	s3,s3,-994 # 800370d0 <tickslock>
    acquire(&p->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	824080e7          	jalr	-2012(ra) # 80000ce0 <acquire>
    if(p->pid == pid){
    800024c4:	589c                	lw	a5,48(s1)
    800024c6:	01278d63          	beq	a5,s2,800024e0 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024ca:	8526                	mv	a0,s1
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	8c8080e7          	jalr	-1848(ra) # 80000d94 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024d4:	16848493          	addi	s1,s1,360
    800024d8:	ff3491e3          	bne	s1,s3,800024ba <kill+0x20>
  }
  return -1;
    800024dc:	557d                	li	a0,-1
    800024de:	a829                	j	800024f8 <kill+0x5e>
      p->killed = 1;
    800024e0:	4785                	li	a5,1
    800024e2:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800024e4:	4c98                	lw	a4,24(s1)
    800024e6:	4789                	li	a5,2
    800024e8:	00f70f63          	beq	a4,a5,80002506 <kill+0x6c>
      release(&p->lock);
    800024ec:	8526                	mv	a0,s1
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	8a6080e7          	jalr	-1882(ra) # 80000d94 <release>
      return 0;
    800024f6:	4501                	li	a0,0
}
    800024f8:	70a2                	ld	ra,40(sp)
    800024fa:	7402                	ld	s0,32(sp)
    800024fc:	64e2                	ld	s1,24(sp)
    800024fe:	6942                	ld	s2,16(sp)
    80002500:	69a2                	ld	s3,8(sp)
    80002502:	6145                	addi	sp,sp,48
    80002504:	8082                	ret
        p->state = RUNNABLE;
    80002506:	478d                	li	a5,3
    80002508:	cc9c                	sw	a5,24(s1)
    8000250a:	b7cd                	j	800024ec <kill+0x52>

000000008000250c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000250c:	7179                	addi	sp,sp,-48
    8000250e:	f406                	sd	ra,40(sp)
    80002510:	f022                	sd	s0,32(sp)
    80002512:	ec26                	sd	s1,24(sp)
    80002514:	e84a                	sd	s2,16(sp)
    80002516:	e44e                	sd	s3,8(sp)
    80002518:	e052                	sd	s4,0(sp)
    8000251a:	1800                	addi	s0,sp,48
    8000251c:	84aa                	mv	s1,a0
    8000251e:	892e                	mv	s2,a1
    80002520:	89b2                	mv	s3,a2
    80002522:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002524:	fffff097          	auipc	ra,0xfffff
    80002528:	588080e7          	jalr	1416(ra) # 80001aac <myproc>
  if(user_dst){
    8000252c:	c08d                	beqz	s1,8000254e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000252e:	86d2                	mv	a3,s4
    80002530:	864e                	mv	a2,s3
    80002532:	85ca                	mv	a1,s2
    80002534:	6928                	ld	a0,80(a0)
    80002536:	fffff097          	auipc	ra,0xfffff
    8000253a:	238080e7          	jalr	568(ra) # 8000176e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000253e:	70a2                	ld	ra,40(sp)
    80002540:	7402                	ld	s0,32(sp)
    80002542:	64e2                	ld	s1,24(sp)
    80002544:	6942                	ld	s2,16(sp)
    80002546:	69a2                	ld	s3,8(sp)
    80002548:	6a02                	ld	s4,0(sp)
    8000254a:	6145                	addi	sp,sp,48
    8000254c:	8082                	ret
    memmove((char *)dst, src, len);
    8000254e:	000a061b          	sext.w	a2,s4
    80002552:	85ce                	mv	a1,s3
    80002554:	854a                	mv	a0,s2
    80002556:	fffff097          	auipc	ra,0xfffff
    8000255a:	8e6080e7          	jalr	-1818(ra) # 80000e3c <memmove>
    return 0;
    8000255e:	8526                	mv	a0,s1
    80002560:	bff9                	j	8000253e <either_copyout+0x32>

0000000080002562 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002562:	7179                	addi	sp,sp,-48
    80002564:	f406                	sd	ra,40(sp)
    80002566:	f022                	sd	s0,32(sp)
    80002568:	ec26                	sd	s1,24(sp)
    8000256a:	e84a                	sd	s2,16(sp)
    8000256c:	e44e                	sd	s3,8(sp)
    8000256e:	e052                	sd	s4,0(sp)
    80002570:	1800                	addi	s0,sp,48
    80002572:	892a                	mv	s2,a0
    80002574:	84ae                	mv	s1,a1
    80002576:	89b2                	mv	s3,a2
    80002578:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000257a:	fffff097          	auipc	ra,0xfffff
    8000257e:	532080e7          	jalr	1330(ra) # 80001aac <myproc>
  if(user_src){
    80002582:	c08d                	beqz	s1,800025a4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002584:	86d2                	mv	a3,s4
    80002586:	864e                	mv	a2,s3
    80002588:	85ca                	mv	a1,s2
    8000258a:	6928                	ld	a0,80(a0)
    8000258c:	fffff097          	auipc	ra,0xfffff
    80002590:	26e080e7          	jalr	622(ra) # 800017fa <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002594:	70a2                	ld	ra,40(sp)
    80002596:	7402                	ld	s0,32(sp)
    80002598:	64e2                	ld	s1,24(sp)
    8000259a:	6942                	ld	s2,16(sp)
    8000259c:	69a2                	ld	s3,8(sp)
    8000259e:	6a02                	ld	s4,0(sp)
    800025a0:	6145                	addi	sp,sp,48
    800025a2:	8082                	ret
    memmove(dst, (char*)src, len);
    800025a4:	000a061b          	sext.w	a2,s4
    800025a8:	85ce                	mv	a1,s3
    800025aa:	854a                	mv	a0,s2
    800025ac:	fffff097          	auipc	ra,0xfffff
    800025b0:	890080e7          	jalr	-1904(ra) # 80000e3c <memmove>
    return 0;
    800025b4:	8526                	mv	a0,s1
    800025b6:	bff9                	j	80002594 <either_copyin+0x32>

00000000800025b8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025b8:	715d                	addi	sp,sp,-80
    800025ba:	e486                	sd	ra,72(sp)
    800025bc:	e0a2                	sd	s0,64(sp)
    800025be:	fc26                	sd	s1,56(sp)
    800025c0:	f84a                	sd	s2,48(sp)
    800025c2:	f44e                	sd	s3,40(sp)
    800025c4:	f052                	sd	s4,32(sp)
    800025c6:	ec56                	sd	s5,24(sp)
    800025c8:	e85a                	sd	s6,16(sp)
    800025ca:	e45e                	sd	s7,8(sp)
    800025cc:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025ce:	00006517          	auipc	a0,0x6
    800025d2:	afa50513          	addi	a0,a0,-1286 # 800080c8 <digits+0x88>
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	fb2080e7          	jalr	-78(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025de:	0002f497          	auipc	s1,0x2f
    800025e2:	24a48493          	addi	s1,s1,586 # 80031828 <proc+0x158>
    800025e6:	00035917          	auipc	s2,0x35
    800025ea:	c4290913          	addi	s2,s2,-958 # 80037228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ee:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025f0:	00006997          	auipc	s3,0x6
    800025f4:	c9098993          	addi	s3,s3,-880 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025f8:	00006a97          	auipc	s5,0x6
    800025fc:	c90a8a93          	addi	s5,s5,-880 # 80008288 <digits+0x248>
    printf("\n");
    80002600:	00006a17          	auipc	s4,0x6
    80002604:	ac8a0a13          	addi	s4,s4,-1336 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002608:	00006b97          	auipc	s7,0x6
    8000260c:	cb8b8b93          	addi	s7,s7,-840 # 800082c0 <states.1718>
    80002610:	a00d                	j	80002632 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002612:	ed86a583          	lw	a1,-296(a3)
    80002616:	8556                	mv	a0,s5
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	f70080e7          	jalr	-144(ra) # 80000588 <printf>
    printf("\n");
    80002620:	8552                	mv	a0,s4
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	f66080e7          	jalr	-154(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000262a:	16848493          	addi	s1,s1,360
    8000262e:	03248163          	beq	s1,s2,80002650 <procdump+0x98>
    if(p->state == UNUSED)
    80002632:	86a6                	mv	a3,s1
    80002634:	ec04a783          	lw	a5,-320(s1)
    80002638:	dbed                	beqz	a5,8000262a <procdump+0x72>
      state = "???";
    8000263a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000263c:	fcfb6be3          	bltu	s6,a5,80002612 <procdump+0x5a>
    80002640:	1782                	slli	a5,a5,0x20
    80002642:	9381                	srli	a5,a5,0x20
    80002644:	078e                	slli	a5,a5,0x3
    80002646:	97de                	add	a5,a5,s7
    80002648:	6390                	ld	a2,0(a5)
    8000264a:	f661                	bnez	a2,80002612 <procdump+0x5a>
      state = "???";
    8000264c:	864e                	mv	a2,s3
    8000264e:	b7d1                	j	80002612 <procdump+0x5a>
  }
}
    80002650:	60a6                	ld	ra,72(sp)
    80002652:	6406                	ld	s0,64(sp)
    80002654:	74e2                	ld	s1,56(sp)
    80002656:	7942                	ld	s2,48(sp)
    80002658:	79a2                	ld	s3,40(sp)
    8000265a:	7a02                	ld	s4,32(sp)
    8000265c:	6ae2                	ld	s5,24(sp)
    8000265e:	6b42                	ld	s6,16(sp)
    80002660:	6ba2                	ld	s7,8(sp)
    80002662:	6161                	addi	sp,sp,80
    80002664:	8082                	ret

0000000080002666 <swtch>:
    80002666:	00153023          	sd	ra,0(a0)
    8000266a:	00253423          	sd	sp,8(a0)
    8000266e:	e900                	sd	s0,16(a0)
    80002670:	ed04                	sd	s1,24(a0)
    80002672:	03253023          	sd	s2,32(a0)
    80002676:	03353423          	sd	s3,40(a0)
    8000267a:	03453823          	sd	s4,48(a0)
    8000267e:	03553c23          	sd	s5,56(a0)
    80002682:	05653023          	sd	s6,64(a0)
    80002686:	05753423          	sd	s7,72(a0)
    8000268a:	05853823          	sd	s8,80(a0)
    8000268e:	05953c23          	sd	s9,88(a0)
    80002692:	07a53023          	sd	s10,96(a0)
    80002696:	07b53423          	sd	s11,104(a0)
    8000269a:	0005b083          	ld	ra,0(a1)
    8000269e:	0085b103          	ld	sp,8(a1)
    800026a2:	6980                	ld	s0,16(a1)
    800026a4:	6d84                	ld	s1,24(a1)
    800026a6:	0205b903          	ld	s2,32(a1)
    800026aa:	0285b983          	ld	s3,40(a1)
    800026ae:	0305ba03          	ld	s4,48(a1)
    800026b2:	0385ba83          	ld	s5,56(a1)
    800026b6:	0405bb03          	ld	s6,64(a1)
    800026ba:	0485bb83          	ld	s7,72(a1)
    800026be:	0505bc03          	ld	s8,80(a1)
    800026c2:	0585bc83          	ld	s9,88(a1)
    800026c6:	0605bd03          	ld	s10,96(a1)
    800026ca:	0685bd83          	ld	s11,104(a1)
    800026ce:	8082                	ret

00000000800026d0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026d0:	1141                	addi	sp,sp,-16
    800026d2:	e406                	sd	ra,8(sp)
    800026d4:	e022                	sd	s0,0(sp)
    800026d6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026d8:	00006597          	auipc	a1,0x6
    800026dc:	c1858593          	addi	a1,a1,-1000 # 800082f0 <states.1718+0x30>
    800026e0:	00035517          	auipc	a0,0x35
    800026e4:	9f050513          	addi	a0,a0,-1552 # 800370d0 <tickslock>
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	568080e7          	jalr	1384(ra) # 80000c50 <initlock>
}
    800026f0:	60a2                	ld	ra,8(sp)
    800026f2:	6402                	ld	s0,0(sp)
    800026f4:	0141                	addi	sp,sp,16
    800026f6:	8082                	ret

00000000800026f8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026f8:	1141                	addi	sp,sp,-16
    800026fa:	e422                	sd	s0,8(sp)
    800026fc:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026fe:	00003797          	auipc	a5,0x3
    80002702:	48278793          	addi	a5,a5,1154 # 80005b80 <kernelvec>
    80002706:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000270a:	6422                	ld	s0,8(sp)
    8000270c:	0141                	addi	sp,sp,16
    8000270e:	8082                	ret

0000000080002710 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002710:	1141                	addi	sp,sp,-16
    80002712:	e406                	sd	ra,8(sp)
    80002714:	e022                	sd	s0,0(sp)
    80002716:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002718:	fffff097          	auipc	ra,0xfffff
    8000271c:	394080e7          	jalr	916(ra) # 80001aac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002720:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002724:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002726:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000272a:	00005617          	auipc	a2,0x5
    8000272e:	8d660613          	addi	a2,a2,-1834 # 80007000 <_trampoline>
    80002732:	00005697          	auipc	a3,0x5
    80002736:	8ce68693          	addi	a3,a3,-1842 # 80007000 <_trampoline>
    8000273a:	8e91                	sub	a3,a3,a2
    8000273c:	040007b7          	lui	a5,0x4000
    80002740:	17fd                	addi	a5,a5,-1
    80002742:	07b2                	slli	a5,a5,0xc
    80002744:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002746:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000274a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000274c:	180026f3          	csrr	a3,satp
    80002750:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002752:	6d38                	ld	a4,88(a0)
    80002754:	6134                	ld	a3,64(a0)
    80002756:	6585                	lui	a1,0x1
    80002758:	96ae                	add	a3,a3,a1
    8000275a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000275c:	6d38                	ld	a4,88(a0)
    8000275e:	00000697          	auipc	a3,0x0
    80002762:	13868693          	addi	a3,a3,312 # 80002896 <usertrap>
    80002766:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002768:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000276a:	8692                	mv	a3,tp
    8000276c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000276e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002772:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002776:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000277a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000277e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002780:	6f18                	ld	a4,24(a4)
    80002782:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002786:	692c                	ld	a1,80(a0)
    80002788:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000278a:	00005717          	auipc	a4,0x5
    8000278e:	90670713          	addi	a4,a4,-1786 # 80007090 <userret>
    80002792:	8f11                	sub	a4,a4,a2
    80002794:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002796:	577d                	li	a4,-1
    80002798:	177e                	slli	a4,a4,0x3f
    8000279a:	8dd9                	or	a1,a1,a4
    8000279c:	02000537          	lui	a0,0x2000
    800027a0:	157d                	addi	a0,a0,-1
    800027a2:	0536                	slli	a0,a0,0xd
    800027a4:	9782                	jalr	a5
}
    800027a6:	60a2                	ld	ra,8(sp)
    800027a8:	6402                	ld	s0,0(sp)
    800027aa:	0141                	addi	sp,sp,16
    800027ac:	8082                	ret

00000000800027ae <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027ae:	1101                	addi	sp,sp,-32
    800027b0:	ec06                	sd	ra,24(sp)
    800027b2:	e822                	sd	s0,16(sp)
    800027b4:	e426                	sd	s1,8(sp)
    800027b6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027b8:	00035497          	auipc	s1,0x35
    800027bc:	91848493          	addi	s1,s1,-1768 # 800370d0 <tickslock>
    800027c0:	8526                	mv	a0,s1
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	51e080e7          	jalr	1310(ra) # 80000ce0 <acquire>
  ticks++;
    800027ca:	00007517          	auipc	a0,0x7
    800027ce:	86650513          	addi	a0,a0,-1946 # 80009030 <ticks>
    800027d2:	411c                	lw	a5,0(a0)
    800027d4:	2785                	addiw	a5,a5,1
    800027d6:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027d8:	00000097          	auipc	ra,0x0
    800027dc:	b1c080e7          	jalr	-1252(ra) # 800022f4 <wakeup>
  release(&tickslock);
    800027e0:	8526                	mv	a0,s1
    800027e2:	ffffe097          	auipc	ra,0xffffe
    800027e6:	5b2080e7          	jalr	1458(ra) # 80000d94 <release>
}
    800027ea:	60e2                	ld	ra,24(sp)
    800027ec:	6442                	ld	s0,16(sp)
    800027ee:	64a2                	ld	s1,8(sp)
    800027f0:	6105                	addi	sp,sp,32
    800027f2:	8082                	ret

00000000800027f4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027f4:	1101                	addi	sp,sp,-32
    800027f6:	ec06                	sd	ra,24(sp)
    800027f8:	e822                	sd	s0,16(sp)
    800027fa:	e426                	sd	s1,8(sp)
    800027fc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027fe:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002802:	00074d63          	bltz	a4,8000281c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002806:	57fd                	li	a5,-1
    80002808:	17fe                	slli	a5,a5,0x3f
    8000280a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000280c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000280e:	06f70363          	beq	a4,a5,80002874 <devintr+0x80>
  }
}
    80002812:	60e2                	ld	ra,24(sp)
    80002814:	6442                	ld	s0,16(sp)
    80002816:	64a2                	ld	s1,8(sp)
    80002818:	6105                	addi	sp,sp,32
    8000281a:	8082                	ret
     (scause & 0xff) == 9){
    8000281c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002820:	46a5                	li	a3,9
    80002822:	fed792e3          	bne	a5,a3,80002806 <devintr+0x12>
    int irq = plic_claim();
    80002826:	00003097          	auipc	ra,0x3
    8000282a:	462080e7          	jalr	1122(ra) # 80005c88 <plic_claim>
    8000282e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002830:	47a9                	li	a5,10
    80002832:	02f50763          	beq	a0,a5,80002860 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002836:	4785                	li	a5,1
    80002838:	02f50963          	beq	a0,a5,8000286a <devintr+0x76>
    return 1;
    8000283c:	4505                	li	a0,1
    } else if(irq){
    8000283e:	d8f1                	beqz	s1,80002812 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002840:	85a6                	mv	a1,s1
    80002842:	00006517          	auipc	a0,0x6
    80002846:	ab650513          	addi	a0,a0,-1354 # 800082f8 <states.1718+0x38>
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	d3e080e7          	jalr	-706(ra) # 80000588 <printf>
      plic_complete(irq);
    80002852:	8526                	mv	a0,s1
    80002854:	00003097          	auipc	ra,0x3
    80002858:	458080e7          	jalr	1112(ra) # 80005cac <plic_complete>
    return 1;
    8000285c:	4505                	li	a0,1
    8000285e:	bf55                	j	80002812 <devintr+0x1e>
      uartintr();
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	148080e7          	jalr	328(ra) # 800009a8 <uartintr>
    80002868:	b7ed                	j	80002852 <devintr+0x5e>
      virtio_disk_intr();
    8000286a:	00004097          	auipc	ra,0x4
    8000286e:	922080e7          	jalr	-1758(ra) # 8000618c <virtio_disk_intr>
    80002872:	b7c5                	j	80002852 <devintr+0x5e>
    if(cpuid() == 0){
    80002874:	fffff097          	auipc	ra,0xfffff
    80002878:	20c080e7          	jalr	524(ra) # 80001a80 <cpuid>
    8000287c:	c901                	beqz	a0,8000288c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000287e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002882:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002884:	14479073          	csrw	sip,a5
    return 2;
    80002888:	4509                	li	a0,2
    8000288a:	b761                	j	80002812 <devintr+0x1e>
      clockintr();
    8000288c:	00000097          	auipc	ra,0x0
    80002890:	f22080e7          	jalr	-222(ra) # 800027ae <clockintr>
    80002894:	b7ed                	j	8000287e <devintr+0x8a>

0000000080002896 <usertrap>:
{
    80002896:	1101                	addi	sp,sp,-32
    80002898:	ec06                	sd	ra,24(sp)
    8000289a:	e822                	sd	s0,16(sp)
    8000289c:	e426                	sd	s1,8(sp)
    8000289e:	e04a                	sd	s2,0(sp)
    800028a0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028a6:	1007f793          	andi	a5,a5,256
    800028aa:	e3ad                	bnez	a5,8000290c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028ac:	00003797          	auipc	a5,0x3
    800028b0:	2d478793          	addi	a5,a5,724 # 80005b80 <kernelvec>
    800028b4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028b8:	fffff097          	auipc	ra,0xfffff
    800028bc:	1f4080e7          	jalr	500(ra) # 80001aac <myproc>
    800028c0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028c2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028c4:	14102773          	csrr	a4,sepc
    800028c8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ca:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028ce:	47a1                	li	a5,8
    800028d0:	04f71c63          	bne	a4,a5,80002928 <usertrap+0x92>
    if(p->killed)
    800028d4:	551c                	lw	a5,40(a0)
    800028d6:	e3b9                	bnez	a5,8000291c <usertrap+0x86>
    p->trapframe->epc += 4;
    800028d8:	6cb8                	ld	a4,88(s1)
    800028da:	6f1c                	ld	a5,24(a4)
    800028dc:	0791                	addi	a5,a5,4
    800028de:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028e4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028e8:	10079073          	csrw	sstatus,a5
    syscall();
    800028ec:	00000097          	auipc	ra,0x0
    800028f0:	2e0080e7          	jalr	736(ra) # 80002bcc <syscall>
  if(p->killed)
    800028f4:	549c                	lw	a5,40(s1)
    800028f6:	ebc1                	bnez	a5,80002986 <usertrap+0xf0>
  usertrapret();
    800028f8:	00000097          	auipc	ra,0x0
    800028fc:	e18080e7          	jalr	-488(ra) # 80002710 <usertrapret>
}
    80002900:	60e2                	ld	ra,24(sp)
    80002902:	6442                	ld	s0,16(sp)
    80002904:	64a2                	ld	s1,8(sp)
    80002906:	6902                	ld	s2,0(sp)
    80002908:	6105                	addi	sp,sp,32
    8000290a:	8082                	ret
    panic("usertrap: not from user mode");
    8000290c:	00006517          	auipc	a0,0x6
    80002910:	a0c50513          	addi	a0,a0,-1524 # 80008318 <states.1718+0x58>
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	c2a080e7          	jalr	-982(ra) # 8000053e <panic>
      exit(-1);
    8000291c:	557d                	li	a0,-1
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	aa6080e7          	jalr	-1370(ra) # 800023c4 <exit>
    80002926:	bf4d                	j	800028d8 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002928:	00000097          	auipc	ra,0x0
    8000292c:	ecc080e7          	jalr	-308(ra) # 800027f4 <devintr>
    80002930:	892a                	mv	s2,a0
    80002932:	c501                	beqz	a0,8000293a <usertrap+0xa4>
  if(p->killed)
    80002934:	549c                	lw	a5,40(s1)
    80002936:	c3a1                	beqz	a5,80002976 <usertrap+0xe0>
    80002938:	a815                	j	8000296c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000293a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000293e:	5890                	lw	a2,48(s1)
    80002940:	00006517          	auipc	a0,0x6
    80002944:	9f850513          	addi	a0,a0,-1544 # 80008338 <states.1718+0x78>
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	c40080e7          	jalr	-960(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002950:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002954:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002958:	00006517          	auipc	a0,0x6
    8000295c:	a1050513          	addi	a0,a0,-1520 # 80008368 <states.1718+0xa8>
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	c28080e7          	jalr	-984(ra) # 80000588 <printf>
    p->killed = 1;
    80002968:	4785                	li	a5,1
    8000296a:	d49c                	sw	a5,40(s1)
    exit(-1);
    8000296c:	557d                	li	a0,-1
    8000296e:	00000097          	auipc	ra,0x0
    80002972:	a56080e7          	jalr	-1450(ra) # 800023c4 <exit>
  if(which_dev == 2)
    80002976:	4789                	li	a5,2
    80002978:	f8f910e3          	bne	s2,a5,800028f8 <usertrap+0x62>
    yield();
    8000297c:	fffff097          	auipc	ra,0xfffff
    80002980:	7b0080e7          	jalr	1968(ra) # 8000212c <yield>
    80002984:	bf95                	j	800028f8 <usertrap+0x62>
  int which_dev = 0;
    80002986:	4901                	li	s2,0
    80002988:	b7d5                	j	8000296c <usertrap+0xd6>

000000008000298a <kerneltrap>:
{
    8000298a:	7179                	addi	sp,sp,-48
    8000298c:	f406                	sd	ra,40(sp)
    8000298e:	f022                	sd	s0,32(sp)
    80002990:	ec26                	sd	s1,24(sp)
    80002992:	e84a                	sd	s2,16(sp)
    80002994:	e44e                	sd	s3,8(sp)
    80002996:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002998:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000299c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029a0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029a4:	1004f793          	andi	a5,s1,256
    800029a8:	cb85                	beqz	a5,800029d8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029aa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029ae:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029b0:	ef85                	bnez	a5,800029e8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029b2:	00000097          	auipc	ra,0x0
    800029b6:	e42080e7          	jalr	-446(ra) # 800027f4 <devintr>
    800029ba:	cd1d                	beqz	a0,800029f8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029bc:	4789                	li	a5,2
    800029be:	06f50a63          	beq	a0,a5,80002a32 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029c2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029c6:	10049073          	csrw	sstatus,s1
}
    800029ca:	70a2                	ld	ra,40(sp)
    800029cc:	7402                	ld	s0,32(sp)
    800029ce:	64e2                	ld	s1,24(sp)
    800029d0:	6942                	ld	s2,16(sp)
    800029d2:	69a2                	ld	s3,8(sp)
    800029d4:	6145                	addi	sp,sp,48
    800029d6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029d8:	00006517          	auipc	a0,0x6
    800029dc:	9b050513          	addi	a0,a0,-1616 # 80008388 <states.1718+0xc8>
    800029e0:	ffffe097          	auipc	ra,0xffffe
    800029e4:	b5e080e7          	jalr	-1186(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800029e8:	00006517          	auipc	a0,0x6
    800029ec:	9c850513          	addi	a0,a0,-1592 # 800083b0 <states.1718+0xf0>
    800029f0:	ffffe097          	auipc	ra,0xffffe
    800029f4:	b4e080e7          	jalr	-1202(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800029f8:	85ce                	mv	a1,s3
    800029fa:	00006517          	auipc	a0,0x6
    800029fe:	9d650513          	addi	a0,a0,-1578 # 800083d0 <states.1718+0x110>
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	b86080e7          	jalr	-1146(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a0a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a0e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a12:	00006517          	auipc	a0,0x6
    80002a16:	9ce50513          	addi	a0,a0,-1586 # 800083e0 <states.1718+0x120>
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	b6e080e7          	jalr	-1170(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a22:	00006517          	auipc	a0,0x6
    80002a26:	9d650513          	addi	a0,a0,-1578 # 800083f8 <states.1718+0x138>
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	b14080e7          	jalr	-1260(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	07a080e7          	jalr	122(ra) # 80001aac <myproc>
    80002a3a:	d541                	beqz	a0,800029c2 <kerneltrap+0x38>
    80002a3c:	fffff097          	auipc	ra,0xfffff
    80002a40:	070080e7          	jalr	112(ra) # 80001aac <myproc>
    80002a44:	4d18                	lw	a4,24(a0)
    80002a46:	4791                	li	a5,4
    80002a48:	f6f71de3          	bne	a4,a5,800029c2 <kerneltrap+0x38>
    yield();
    80002a4c:	fffff097          	auipc	ra,0xfffff
    80002a50:	6e0080e7          	jalr	1760(ra) # 8000212c <yield>
    80002a54:	b7bd                	j	800029c2 <kerneltrap+0x38>

0000000080002a56 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a56:	1101                	addi	sp,sp,-32
    80002a58:	ec06                	sd	ra,24(sp)
    80002a5a:	e822                	sd	s0,16(sp)
    80002a5c:	e426                	sd	s1,8(sp)
    80002a5e:	1000                	addi	s0,sp,32
    80002a60:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a62:	fffff097          	auipc	ra,0xfffff
    80002a66:	04a080e7          	jalr	74(ra) # 80001aac <myproc>
  switch (n) {
    80002a6a:	4795                	li	a5,5
    80002a6c:	0497e163          	bltu	a5,s1,80002aae <argraw+0x58>
    80002a70:	048a                	slli	s1,s1,0x2
    80002a72:	00006717          	auipc	a4,0x6
    80002a76:	9be70713          	addi	a4,a4,-1602 # 80008430 <states.1718+0x170>
    80002a7a:	94ba                	add	s1,s1,a4
    80002a7c:	409c                	lw	a5,0(s1)
    80002a7e:	97ba                	add	a5,a5,a4
    80002a80:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a82:	6d3c                	ld	a5,88(a0)
    80002a84:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a86:	60e2                	ld	ra,24(sp)
    80002a88:	6442                	ld	s0,16(sp)
    80002a8a:	64a2                	ld	s1,8(sp)
    80002a8c:	6105                	addi	sp,sp,32
    80002a8e:	8082                	ret
    return p->trapframe->a1;
    80002a90:	6d3c                	ld	a5,88(a0)
    80002a92:	7fa8                	ld	a0,120(a5)
    80002a94:	bfcd                	j	80002a86 <argraw+0x30>
    return p->trapframe->a2;
    80002a96:	6d3c                	ld	a5,88(a0)
    80002a98:	63c8                	ld	a0,128(a5)
    80002a9a:	b7f5                	j	80002a86 <argraw+0x30>
    return p->trapframe->a3;
    80002a9c:	6d3c                	ld	a5,88(a0)
    80002a9e:	67c8                	ld	a0,136(a5)
    80002aa0:	b7dd                	j	80002a86 <argraw+0x30>
    return p->trapframe->a4;
    80002aa2:	6d3c                	ld	a5,88(a0)
    80002aa4:	6bc8                	ld	a0,144(a5)
    80002aa6:	b7c5                	j	80002a86 <argraw+0x30>
    return p->trapframe->a5;
    80002aa8:	6d3c                	ld	a5,88(a0)
    80002aaa:	6fc8                	ld	a0,152(a5)
    80002aac:	bfe9                	j	80002a86 <argraw+0x30>
  panic("argraw");
    80002aae:	00006517          	auipc	a0,0x6
    80002ab2:	95a50513          	addi	a0,a0,-1702 # 80008408 <states.1718+0x148>
    80002ab6:	ffffe097          	auipc	ra,0xffffe
    80002aba:	a88080e7          	jalr	-1400(ra) # 8000053e <panic>

0000000080002abe <fetchaddr>:
{
    80002abe:	1101                	addi	sp,sp,-32
    80002ac0:	ec06                	sd	ra,24(sp)
    80002ac2:	e822                	sd	s0,16(sp)
    80002ac4:	e426                	sd	s1,8(sp)
    80002ac6:	e04a                	sd	s2,0(sp)
    80002ac8:	1000                	addi	s0,sp,32
    80002aca:	84aa                	mv	s1,a0
    80002acc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	fde080e7          	jalr	-34(ra) # 80001aac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ad6:	653c                	ld	a5,72(a0)
    80002ad8:	02f4f863          	bgeu	s1,a5,80002b08 <fetchaddr+0x4a>
    80002adc:	00848713          	addi	a4,s1,8
    80002ae0:	02e7e663          	bltu	a5,a4,80002b0c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ae4:	46a1                	li	a3,8
    80002ae6:	8626                	mv	a2,s1
    80002ae8:	85ca                	mv	a1,s2
    80002aea:	6928                	ld	a0,80(a0)
    80002aec:	fffff097          	auipc	ra,0xfffff
    80002af0:	d0e080e7          	jalr	-754(ra) # 800017fa <copyin>
    80002af4:	00a03533          	snez	a0,a0
    80002af8:	40a00533          	neg	a0,a0
}
    80002afc:	60e2                	ld	ra,24(sp)
    80002afe:	6442                	ld	s0,16(sp)
    80002b00:	64a2                	ld	s1,8(sp)
    80002b02:	6902                	ld	s2,0(sp)
    80002b04:	6105                	addi	sp,sp,32
    80002b06:	8082                	ret
    return -1;
    80002b08:	557d                	li	a0,-1
    80002b0a:	bfcd                	j	80002afc <fetchaddr+0x3e>
    80002b0c:	557d                	li	a0,-1
    80002b0e:	b7fd                	j	80002afc <fetchaddr+0x3e>

0000000080002b10 <fetchstr>:
{
    80002b10:	7179                	addi	sp,sp,-48
    80002b12:	f406                	sd	ra,40(sp)
    80002b14:	f022                	sd	s0,32(sp)
    80002b16:	ec26                	sd	s1,24(sp)
    80002b18:	e84a                	sd	s2,16(sp)
    80002b1a:	e44e                	sd	s3,8(sp)
    80002b1c:	1800                	addi	s0,sp,48
    80002b1e:	892a                	mv	s2,a0
    80002b20:	84ae                	mv	s1,a1
    80002b22:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b24:	fffff097          	auipc	ra,0xfffff
    80002b28:	f88080e7          	jalr	-120(ra) # 80001aac <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b2c:	86ce                	mv	a3,s3
    80002b2e:	864a                	mv	a2,s2
    80002b30:	85a6                	mv	a1,s1
    80002b32:	6928                	ld	a0,80(a0)
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	d52080e7          	jalr	-686(ra) # 80001886 <copyinstr>
  if(err < 0)
    80002b3c:	00054763          	bltz	a0,80002b4a <fetchstr+0x3a>
  return strlen(buf);
    80002b40:	8526                	mv	a0,s1
    80002b42:	ffffe097          	auipc	ra,0xffffe
    80002b46:	41e080e7          	jalr	1054(ra) # 80000f60 <strlen>
}
    80002b4a:	70a2                	ld	ra,40(sp)
    80002b4c:	7402                	ld	s0,32(sp)
    80002b4e:	64e2                	ld	s1,24(sp)
    80002b50:	6942                	ld	s2,16(sp)
    80002b52:	69a2                	ld	s3,8(sp)
    80002b54:	6145                	addi	sp,sp,48
    80002b56:	8082                	ret

0000000080002b58 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b58:	1101                	addi	sp,sp,-32
    80002b5a:	ec06                	sd	ra,24(sp)
    80002b5c:	e822                	sd	s0,16(sp)
    80002b5e:	e426                	sd	s1,8(sp)
    80002b60:	1000                	addi	s0,sp,32
    80002b62:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b64:	00000097          	auipc	ra,0x0
    80002b68:	ef2080e7          	jalr	-270(ra) # 80002a56 <argraw>
    80002b6c:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b6e:	4501                	li	a0,0
    80002b70:	60e2                	ld	ra,24(sp)
    80002b72:	6442                	ld	s0,16(sp)
    80002b74:	64a2                	ld	s1,8(sp)
    80002b76:	6105                	addi	sp,sp,32
    80002b78:	8082                	ret

0000000080002b7a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b7a:	1101                	addi	sp,sp,-32
    80002b7c:	ec06                	sd	ra,24(sp)
    80002b7e:	e822                	sd	s0,16(sp)
    80002b80:	e426                	sd	s1,8(sp)
    80002b82:	1000                	addi	s0,sp,32
    80002b84:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b86:	00000097          	auipc	ra,0x0
    80002b8a:	ed0080e7          	jalr	-304(ra) # 80002a56 <argraw>
    80002b8e:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b90:	4501                	li	a0,0
    80002b92:	60e2                	ld	ra,24(sp)
    80002b94:	6442                	ld	s0,16(sp)
    80002b96:	64a2                	ld	s1,8(sp)
    80002b98:	6105                	addi	sp,sp,32
    80002b9a:	8082                	ret

0000000080002b9c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b9c:	1101                	addi	sp,sp,-32
    80002b9e:	ec06                	sd	ra,24(sp)
    80002ba0:	e822                	sd	s0,16(sp)
    80002ba2:	e426                	sd	s1,8(sp)
    80002ba4:	e04a                	sd	s2,0(sp)
    80002ba6:	1000                	addi	s0,sp,32
    80002ba8:	84ae                	mv	s1,a1
    80002baa:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bac:	00000097          	auipc	ra,0x0
    80002bb0:	eaa080e7          	jalr	-342(ra) # 80002a56 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bb4:	864a                	mv	a2,s2
    80002bb6:	85a6                	mv	a1,s1
    80002bb8:	00000097          	auipc	ra,0x0
    80002bbc:	f58080e7          	jalr	-168(ra) # 80002b10 <fetchstr>
}
    80002bc0:	60e2                	ld	ra,24(sp)
    80002bc2:	6442                	ld	s0,16(sp)
    80002bc4:	64a2                	ld	s1,8(sp)
    80002bc6:	6902                	ld	s2,0(sp)
    80002bc8:	6105                	addi	sp,sp,32
    80002bca:	8082                	ret

0000000080002bcc <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002bcc:	1101                	addi	sp,sp,-32
    80002bce:	ec06                	sd	ra,24(sp)
    80002bd0:	e822                	sd	s0,16(sp)
    80002bd2:	e426                	sd	s1,8(sp)
    80002bd4:	e04a                	sd	s2,0(sp)
    80002bd6:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bd8:	fffff097          	auipc	ra,0xfffff
    80002bdc:	ed4080e7          	jalr	-300(ra) # 80001aac <myproc>
    80002be0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002be2:	05853903          	ld	s2,88(a0)
    80002be6:	0a893783          	ld	a5,168(s2)
    80002bea:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bee:	37fd                	addiw	a5,a5,-1
    80002bf0:	4751                	li	a4,20
    80002bf2:	00f76f63          	bltu	a4,a5,80002c10 <syscall+0x44>
    80002bf6:	00369713          	slli	a4,a3,0x3
    80002bfa:	00006797          	auipc	a5,0x6
    80002bfe:	84e78793          	addi	a5,a5,-1970 # 80008448 <syscalls>
    80002c02:	97ba                	add	a5,a5,a4
    80002c04:	639c                	ld	a5,0(a5)
    80002c06:	c789                	beqz	a5,80002c10 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c08:	9782                	jalr	a5
    80002c0a:	06a93823          	sd	a0,112(s2)
    80002c0e:	a839                	j	80002c2c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c10:	15848613          	addi	a2,s1,344
    80002c14:	588c                	lw	a1,48(s1)
    80002c16:	00005517          	auipc	a0,0x5
    80002c1a:	7fa50513          	addi	a0,a0,2042 # 80008410 <states.1718+0x150>
    80002c1e:	ffffe097          	auipc	ra,0xffffe
    80002c22:	96a080e7          	jalr	-1686(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c26:	6cbc                	ld	a5,88(s1)
    80002c28:	577d                	li	a4,-1
    80002c2a:	fbb8                	sd	a4,112(a5)
  }
}
    80002c2c:	60e2                	ld	ra,24(sp)
    80002c2e:	6442                	ld	s0,16(sp)
    80002c30:	64a2                	ld	s1,8(sp)
    80002c32:	6902                	ld	s2,0(sp)
    80002c34:	6105                	addi	sp,sp,32
    80002c36:	8082                	ret

0000000080002c38 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c38:	1101                	addi	sp,sp,-32
    80002c3a:	ec06                	sd	ra,24(sp)
    80002c3c:	e822                	sd	s0,16(sp)
    80002c3e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c40:	fec40593          	addi	a1,s0,-20
    80002c44:	4501                	li	a0,0
    80002c46:	00000097          	auipc	ra,0x0
    80002c4a:	f12080e7          	jalr	-238(ra) # 80002b58 <argint>
    return -1;
    80002c4e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c50:	00054963          	bltz	a0,80002c62 <sys_exit+0x2a>
  exit(n);
    80002c54:	fec42503          	lw	a0,-20(s0)
    80002c58:	fffff097          	auipc	ra,0xfffff
    80002c5c:	76c080e7          	jalr	1900(ra) # 800023c4 <exit>
  return 0;  // not reached
    80002c60:	4781                	li	a5,0
}
    80002c62:	853e                	mv	a0,a5
    80002c64:	60e2                	ld	ra,24(sp)
    80002c66:	6442                	ld	s0,16(sp)
    80002c68:	6105                	addi	sp,sp,32
    80002c6a:	8082                	ret

0000000080002c6c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c6c:	1141                	addi	sp,sp,-16
    80002c6e:	e406                	sd	ra,8(sp)
    80002c70:	e022                	sd	s0,0(sp)
    80002c72:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	e38080e7          	jalr	-456(ra) # 80001aac <myproc>
}
    80002c7c:	5908                	lw	a0,48(a0)
    80002c7e:	60a2                	ld	ra,8(sp)
    80002c80:	6402                	ld	s0,0(sp)
    80002c82:	0141                	addi	sp,sp,16
    80002c84:	8082                	ret

0000000080002c86 <sys_fork>:

uint64
sys_fork(void)
{
    80002c86:	1141                	addi	sp,sp,-16
    80002c88:	e406                	sd	ra,8(sp)
    80002c8a:	e022                	sd	s0,0(sp)
    80002c8c:	0800                	addi	s0,sp,16
  return fork();
    80002c8e:	fffff097          	auipc	ra,0xfffff
    80002c92:	1ec080e7          	jalr	492(ra) # 80001e7a <fork>
}
    80002c96:	60a2                	ld	ra,8(sp)
    80002c98:	6402                	ld	s0,0(sp)
    80002c9a:	0141                	addi	sp,sp,16
    80002c9c:	8082                	ret

0000000080002c9e <sys_wait>:

uint64
sys_wait(void)
{
    80002c9e:	1101                	addi	sp,sp,-32
    80002ca0:	ec06                	sd	ra,24(sp)
    80002ca2:	e822                	sd	s0,16(sp)
    80002ca4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ca6:	fe840593          	addi	a1,s0,-24
    80002caa:	4501                	li	a0,0
    80002cac:	00000097          	auipc	ra,0x0
    80002cb0:	ece080e7          	jalr	-306(ra) # 80002b7a <argaddr>
    80002cb4:	87aa                	mv	a5,a0
    return -1;
    80002cb6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cb8:	0007c863          	bltz	a5,80002cc8 <sys_wait+0x2a>
  return wait(p);
    80002cbc:	fe843503          	ld	a0,-24(s0)
    80002cc0:	fffff097          	auipc	ra,0xfffff
    80002cc4:	50c080e7          	jalr	1292(ra) # 800021cc <wait>
}
    80002cc8:	60e2                	ld	ra,24(sp)
    80002cca:	6442                	ld	s0,16(sp)
    80002ccc:	6105                	addi	sp,sp,32
    80002cce:	8082                	ret

0000000080002cd0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cd0:	7179                	addi	sp,sp,-48
    80002cd2:	f406                	sd	ra,40(sp)
    80002cd4:	f022                	sd	s0,32(sp)
    80002cd6:	ec26                	sd	s1,24(sp)
    80002cd8:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cda:	fdc40593          	addi	a1,s0,-36
    80002cde:	4501                	li	a0,0
    80002ce0:	00000097          	auipc	ra,0x0
    80002ce4:	e78080e7          	jalr	-392(ra) # 80002b58 <argint>
    80002ce8:	87aa                	mv	a5,a0
    return -1;
    80002cea:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002cec:	0207c063          	bltz	a5,80002d0c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	dbc080e7          	jalr	-580(ra) # 80001aac <myproc>
    80002cf8:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002cfa:	fdc42503          	lw	a0,-36(s0)
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	108080e7          	jalr	264(ra) # 80001e06 <growproc>
    80002d06:	00054863          	bltz	a0,80002d16 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d0a:	8526                	mv	a0,s1
}
    80002d0c:	70a2                	ld	ra,40(sp)
    80002d0e:	7402                	ld	s0,32(sp)
    80002d10:	64e2                	ld	s1,24(sp)
    80002d12:	6145                	addi	sp,sp,48
    80002d14:	8082                	ret
    return -1;
    80002d16:	557d                	li	a0,-1
    80002d18:	bfd5                	j	80002d0c <sys_sbrk+0x3c>

0000000080002d1a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d1a:	7139                	addi	sp,sp,-64
    80002d1c:	fc06                	sd	ra,56(sp)
    80002d1e:	f822                	sd	s0,48(sp)
    80002d20:	f426                	sd	s1,40(sp)
    80002d22:	f04a                	sd	s2,32(sp)
    80002d24:	ec4e                	sd	s3,24(sp)
    80002d26:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d28:	fcc40593          	addi	a1,s0,-52
    80002d2c:	4501                	li	a0,0
    80002d2e:	00000097          	auipc	ra,0x0
    80002d32:	e2a080e7          	jalr	-470(ra) # 80002b58 <argint>
    return -1;
    80002d36:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d38:	06054563          	bltz	a0,80002da2 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d3c:	00034517          	auipc	a0,0x34
    80002d40:	39450513          	addi	a0,a0,916 # 800370d0 <tickslock>
    80002d44:	ffffe097          	auipc	ra,0xffffe
    80002d48:	f9c080e7          	jalr	-100(ra) # 80000ce0 <acquire>
  ticks0 = ticks;
    80002d4c:	00006917          	auipc	s2,0x6
    80002d50:	2e492903          	lw	s2,740(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002d54:	fcc42783          	lw	a5,-52(s0)
    80002d58:	cf85                	beqz	a5,80002d90 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d5a:	00034997          	auipc	s3,0x34
    80002d5e:	37698993          	addi	s3,s3,886 # 800370d0 <tickslock>
    80002d62:	00006497          	auipc	s1,0x6
    80002d66:	2ce48493          	addi	s1,s1,718 # 80009030 <ticks>
    if(myproc()->killed){
    80002d6a:	fffff097          	auipc	ra,0xfffff
    80002d6e:	d42080e7          	jalr	-702(ra) # 80001aac <myproc>
    80002d72:	551c                	lw	a5,40(a0)
    80002d74:	ef9d                	bnez	a5,80002db2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d76:	85ce                	mv	a1,s3
    80002d78:	8526                	mv	a0,s1
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	3ee080e7          	jalr	1006(ra) # 80002168 <sleep>
  while(ticks - ticks0 < n){
    80002d82:	409c                	lw	a5,0(s1)
    80002d84:	412787bb          	subw	a5,a5,s2
    80002d88:	fcc42703          	lw	a4,-52(s0)
    80002d8c:	fce7efe3          	bltu	a5,a4,80002d6a <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d90:	00034517          	auipc	a0,0x34
    80002d94:	34050513          	addi	a0,a0,832 # 800370d0 <tickslock>
    80002d98:	ffffe097          	auipc	ra,0xffffe
    80002d9c:	ffc080e7          	jalr	-4(ra) # 80000d94 <release>
  return 0;
    80002da0:	4781                	li	a5,0
}
    80002da2:	853e                	mv	a0,a5
    80002da4:	70e2                	ld	ra,56(sp)
    80002da6:	7442                	ld	s0,48(sp)
    80002da8:	74a2                	ld	s1,40(sp)
    80002daa:	7902                	ld	s2,32(sp)
    80002dac:	69e2                	ld	s3,24(sp)
    80002dae:	6121                	addi	sp,sp,64
    80002db0:	8082                	ret
      release(&tickslock);
    80002db2:	00034517          	auipc	a0,0x34
    80002db6:	31e50513          	addi	a0,a0,798 # 800370d0 <tickslock>
    80002dba:	ffffe097          	auipc	ra,0xffffe
    80002dbe:	fda080e7          	jalr	-38(ra) # 80000d94 <release>
      return -1;
    80002dc2:	57fd                	li	a5,-1
    80002dc4:	bff9                	j	80002da2 <sys_sleep+0x88>

0000000080002dc6 <sys_kill>:

uint64
sys_kill(void)
{
    80002dc6:	1101                	addi	sp,sp,-32
    80002dc8:	ec06                	sd	ra,24(sp)
    80002dca:	e822                	sd	s0,16(sp)
    80002dcc:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002dce:	fec40593          	addi	a1,s0,-20
    80002dd2:	4501                	li	a0,0
    80002dd4:	00000097          	auipc	ra,0x0
    80002dd8:	d84080e7          	jalr	-636(ra) # 80002b58 <argint>
    80002ddc:	87aa                	mv	a5,a0
    return -1;
    80002dde:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002de0:	0007c863          	bltz	a5,80002df0 <sys_kill+0x2a>
  return kill(pid);
    80002de4:	fec42503          	lw	a0,-20(s0)
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	6b2080e7          	jalr	1714(ra) # 8000249a <kill>
}
    80002df0:	60e2                	ld	ra,24(sp)
    80002df2:	6442                	ld	s0,16(sp)
    80002df4:	6105                	addi	sp,sp,32
    80002df6:	8082                	ret

0000000080002df8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002df8:	1101                	addi	sp,sp,-32
    80002dfa:	ec06                	sd	ra,24(sp)
    80002dfc:	e822                	sd	s0,16(sp)
    80002dfe:	e426                	sd	s1,8(sp)
    80002e00:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e02:	00034517          	auipc	a0,0x34
    80002e06:	2ce50513          	addi	a0,a0,718 # 800370d0 <tickslock>
    80002e0a:	ffffe097          	auipc	ra,0xffffe
    80002e0e:	ed6080e7          	jalr	-298(ra) # 80000ce0 <acquire>
  xticks = ticks;
    80002e12:	00006497          	auipc	s1,0x6
    80002e16:	21e4a483          	lw	s1,542(s1) # 80009030 <ticks>
  release(&tickslock);
    80002e1a:	00034517          	auipc	a0,0x34
    80002e1e:	2b650513          	addi	a0,a0,694 # 800370d0 <tickslock>
    80002e22:	ffffe097          	auipc	ra,0xffffe
    80002e26:	f72080e7          	jalr	-142(ra) # 80000d94 <release>
  return xticks;
}
    80002e2a:	02049513          	slli	a0,s1,0x20
    80002e2e:	9101                	srli	a0,a0,0x20
    80002e30:	60e2                	ld	ra,24(sp)
    80002e32:	6442                	ld	s0,16(sp)
    80002e34:	64a2                	ld	s1,8(sp)
    80002e36:	6105                	addi	sp,sp,32
    80002e38:	8082                	ret

0000000080002e3a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e3a:	7179                	addi	sp,sp,-48
    80002e3c:	f406                	sd	ra,40(sp)
    80002e3e:	f022                	sd	s0,32(sp)
    80002e40:	ec26                	sd	s1,24(sp)
    80002e42:	e84a                	sd	s2,16(sp)
    80002e44:	e44e                	sd	s3,8(sp)
    80002e46:	e052                	sd	s4,0(sp)
    80002e48:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e4a:	00005597          	auipc	a1,0x5
    80002e4e:	6ae58593          	addi	a1,a1,1710 # 800084f8 <syscalls+0xb0>
    80002e52:	00034517          	auipc	a0,0x34
    80002e56:	29650513          	addi	a0,a0,662 # 800370e8 <bcache>
    80002e5a:	ffffe097          	auipc	ra,0xffffe
    80002e5e:	df6080e7          	jalr	-522(ra) # 80000c50 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e62:	0003c797          	auipc	a5,0x3c
    80002e66:	28678793          	addi	a5,a5,646 # 8003f0e8 <bcache+0x8000>
    80002e6a:	0003c717          	auipc	a4,0x3c
    80002e6e:	4e670713          	addi	a4,a4,1254 # 8003f350 <bcache+0x8268>
    80002e72:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e76:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e7a:	00034497          	auipc	s1,0x34
    80002e7e:	28648493          	addi	s1,s1,646 # 80037100 <bcache+0x18>
    b->next = bcache.head.next;
    80002e82:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e84:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e86:	00005a17          	auipc	s4,0x5
    80002e8a:	67aa0a13          	addi	s4,s4,1658 # 80008500 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002e8e:	2b893783          	ld	a5,696(s2)
    80002e92:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e94:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e98:	85d2                	mv	a1,s4
    80002e9a:	01048513          	addi	a0,s1,16
    80002e9e:	00001097          	auipc	ra,0x1
    80002ea2:	4bc080e7          	jalr	1212(ra) # 8000435a <initsleeplock>
    bcache.head.next->prev = b;
    80002ea6:	2b893783          	ld	a5,696(s2)
    80002eaa:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002eac:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eb0:	45848493          	addi	s1,s1,1112
    80002eb4:	fd349de3          	bne	s1,s3,80002e8e <binit+0x54>
  }
}
    80002eb8:	70a2                	ld	ra,40(sp)
    80002eba:	7402                	ld	s0,32(sp)
    80002ebc:	64e2                	ld	s1,24(sp)
    80002ebe:	6942                	ld	s2,16(sp)
    80002ec0:	69a2                	ld	s3,8(sp)
    80002ec2:	6a02                	ld	s4,0(sp)
    80002ec4:	6145                	addi	sp,sp,48
    80002ec6:	8082                	ret

0000000080002ec8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002ec8:	7179                	addi	sp,sp,-48
    80002eca:	f406                	sd	ra,40(sp)
    80002ecc:	f022                	sd	s0,32(sp)
    80002ece:	ec26                	sd	s1,24(sp)
    80002ed0:	e84a                	sd	s2,16(sp)
    80002ed2:	e44e                	sd	s3,8(sp)
    80002ed4:	1800                	addi	s0,sp,48
    80002ed6:	89aa                	mv	s3,a0
    80002ed8:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002eda:	00034517          	auipc	a0,0x34
    80002ede:	20e50513          	addi	a0,a0,526 # 800370e8 <bcache>
    80002ee2:	ffffe097          	auipc	ra,0xffffe
    80002ee6:	dfe080e7          	jalr	-514(ra) # 80000ce0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002eea:	0003c497          	auipc	s1,0x3c
    80002eee:	4b64b483          	ld	s1,1206(s1) # 8003f3a0 <bcache+0x82b8>
    80002ef2:	0003c797          	auipc	a5,0x3c
    80002ef6:	45e78793          	addi	a5,a5,1118 # 8003f350 <bcache+0x8268>
    80002efa:	02f48f63          	beq	s1,a5,80002f38 <bread+0x70>
    80002efe:	873e                	mv	a4,a5
    80002f00:	a021                	j	80002f08 <bread+0x40>
    80002f02:	68a4                	ld	s1,80(s1)
    80002f04:	02e48a63          	beq	s1,a4,80002f38 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f08:	449c                	lw	a5,8(s1)
    80002f0a:	ff379ce3          	bne	a5,s3,80002f02 <bread+0x3a>
    80002f0e:	44dc                	lw	a5,12(s1)
    80002f10:	ff2799e3          	bne	a5,s2,80002f02 <bread+0x3a>
      b->refcnt++;
    80002f14:	40bc                	lw	a5,64(s1)
    80002f16:	2785                	addiw	a5,a5,1
    80002f18:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f1a:	00034517          	auipc	a0,0x34
    80002f1e:	1ce50513          	addi	a0,a0,462 # 800370e8 <bcache>
    80002f22:	ffffe097          	auipc	ra,0xffffe
    80002f26:	e72080e7          	jalr	-398(ra) # 80000d94 <release>
      acquiresleep(&b->lock);
    80002f2a:	01048513          	addi	a0,s1,16
    80002f2e:	00001097          	auipc	ra,0x1
    80002f32:	466080e7          	jalr	1126(ra) # 80004394 <acquiresleep>
      return b;
    80002f36:	a8b9                	j	80002f94 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f38:	0003c497          	auipc	s1,0x3c
    80002f3c:	4604b483          	ld	s1,1120(s1) # 8003f398 <bcache+0x82b0>
    80002f40:	0003c797          	auipc	a5,0x3c
    80002f44:	41078793          	addi	a5,a5,1040 # 8003f350 <bcache+0x8268>
    80002f48:	00f48863          	beq	s1,a5,80002f58 <bread+0x90>
    80002f4c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f4e:	40bc                	lw	a5,64(s1)
    80002f50:	cf81                	beqz	a5,80002f68 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f52:	64a4                	ld	s1,72(s1)
    80002f54:	fee49de3          	bne	s1,a4,80002f4e <bread+0x86>
  panic("bget: no buffers");
    80002f58:	00005517          	auipc	a0,0x5
    80002f5c:	5b050513          	addi	a0,a0,1456 # 80008508 <syscalls+0xc0>
    80002f60:	ffffd097          	auipc	ra,0xffffd
    80002f64:	5de080e7          	jalr	1502(ra) # 8000053e <panic>
      b->dev = dev;
    80002f68:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002f6c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002f70:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f74:	4785                	li	a5,1
    80002f76:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f78:	00034517          	auipc	a0,0x34
    80002f7c:	17050513          	addi	a0,a0,368 # 800370e8 <bcache>
    80002f80:	ffffe097          	auipc	ra,0xffffe
    80002f84:	e14080e7          	jalr	-492(ra) # 80000d94 <release>
      acquiresleep(&b->lock);
    80002f88:	01048513          	addi	a0,s1,16
    80002f8c:	00001097          	auipc	ra,0x1
    80002f90:	408080e7          	jalr	1032(ra) # 80004394 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f94:	409c                	lw	a5,0(s1)
    80002f96:	cb89                	beqz	a5,80002fa8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f98:	8526                	mv	a0,s1
    80002f9a:	70a2                	ld	ra,40(sp)
    80002f9c:	7402                	ld	s0,32(sp)
    80002f9e:	64e2                	ld	s1,24(sp)
    80002fa0:	6942                	ld	s2,16(sp)
    80002fa2:	69a2                	ld	s3,8(sp)
    80002fa4:	6145                	addi	sp,sp,48
    80002fa6:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fa8:	4581                	li	a1,0
    80002faa:	8526                	mv	a0,s1
    80002fac:	00003097          	auipc	ra,0x3
    80002fb0:	f0a080e7          	jalr	-246(ra) # 80005eb6 <virtio_disk_rw>
    b->valid = 1;
    80002fb4:	4785                	li	a5,1
    80002fb6:	c09c                	sw	a5,0(s1)
  return b;
    80002fb8:	b7c5                	j	80002f98 <bread+0xd0>

0000000080002fba <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fba:	1101                	addi	sp,sp,-32
    80002fbc:	ec06                	sd	ra,24(sp)
    80002fbe:	e822                	sd	s0,16(sp)
    80002fc0:	e426                	sd	s1,8(sp)
    80002fc2:	1000                	addi	s0,sp,32
    80002fc4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fc6:	0541                	addi	a0,a0,16
    80002fc8:	00001097          	auipc	ra,0x1
    80002fcc:	466080e7          	jalr	1126(ra) # 8000442e <holdingsleep>
    80002fd0:	cd01                	beqz	a0,80002fe8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002fd2:	4585                	li	a1,1
    80002fd4:	8526                	mv	a0,s1
    80002fd6:	00003097          	auipc	ra,0x3
    80002fda:	ee0080e7          	jalr	-288(ra) # 80005eb6 <virtio_disk_rw>
}
    80002fde:	60e2                	ld	ra,24(sp)
    80002fe0:	6442                	ld	s0,16(sp)
    80002fe2:	64a2                	ld	s1,8(sp)
    80002fe4:	6105                	addi	sp,sp,32
    80002fe6:	8082                	ret
    panic("bwrite");
    80002fe8:	00005517          	auipc	a0,0x5
    80002fec:	53850513          	addi	a0,a0,1336 # 80008520 <syscalls+0xd8>
    80002ff0:	ffffd097          	auipc	ra,0xffffd
    80002ff4:	54e080e7          	jalr	1358(ra) # 8000053e <panic>

0000000080002ff8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002ff8:	1101                	addi	sp,sp,-32
    80002ffa:	ec06                	sd	ra,24(sp)
    80002ffc:	e822                	sd	s0,16(sp)
    80002ffe:	e426                	sd	s1,8(sp)
    80003000:	e04a                	sd	s2,0(sp)
    80003002:	1000                	addi	s0,sp,32
    80003004:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003006:	01050913          	addi	s2,a0,16
    8000300a:	854a                	mv	a0,s2
    8000300c:	00001097          	auipc	ra,0x1
    80003010:	422080e7          	jalr	1058(ra) # 8000442e <holdingsleep>
    80003014:	c92d                	beqz	a0,80003086 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003016:	854a                	mv	a0,s2
    80003018:	00001097          	auipc	ra,0x1
    8000301c:	3d2080e7          	jalr	978(ra) # 800043ea <releasesleep>

  acquire(&bcache.lock);
    80003020:	00034517          	auipc	a0,0x34
    80003024:	0c850513          	addi	a0,a0,200 # 800370e8 <bcache>
    80003028:	ffffe097          	auipc	ra,0xffffe
    8000302c:	cb8080e7          	jalr	-840(ra) # 80000ce0 <acquire>
  b->refcnt--;
    80003030:	40bc                	lw	a5,64(s1)
    80003032:	37fd                	addiw	a5,a5,-1
    80003034:	0007871b          	sext.w	a4,a5
    80003038:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000303a:	eb05                	bnez	a4,8000306a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000303c:	68bc                	ld	a5,80(s1)
    8000303e:	64b8                	ld	a4,72(s1)
    80003040:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003042:	64bc                	ld	a5,72(s1)
    80003044:	68b8                	ld	a4,80(s1)
    80003046:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003048:	0003c797          	auipc	a5,0x3c
    8000304c:	0a078793          	addi	a5,a5,160 # 8003f0e8 <bcache+0x8000>
    80003050:	2b87b703          	ld	a4,696(a5)
    80003054:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003056:	0003c717          	auipc	a4,0x3c
    8000305a:	2fa70713          	addi	a4,a4,762 # 8003f350 <bcache+0x8268>
    8000305e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003060:	2b87b703          	ld	a4,696(a5)
    80003064:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003066:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000306a:	00034517          	auipc	a0,0x34
    8000306e:	07e50513          	addi	a0,a0,126 # 800370e8 <bcache>
    80003072:	ffffe097          	auipc	ra,0xffffe
    80003076:	d22080e7          	jalr	-734(ra) # 80000d94 <release>
}
    8000307a:	60e2                	ld	ra,24(sp)
    8000307c:	6442                	ld	s0,16(sp)
    8000307e:	64a2                	ld	s1,8(sp)
    80003080:	6902                	ld	s2,0(sp)
    80003082:	6105                	addi	sp,sp,32
    80003084:	8082                	ret
    panic("brelse");
    80003086:	00005517          	auipc	a0,0x5
    8000308a:	4a250513          	addi	a0,a0,1186 # 80008528 <syscalls+0xe0>
    8000308e:	ffffd097          	auipc	ra,0xffffd
    80003092:	4b0080e7          	jalr	1200(ra) # 8000053e <panic>

0000000080003096 <bpin>:

void
bpin(struct buf *b) {
    80003096:	1101                	addi	sp,sp,-32
    80003098:	ec06                	sd	ra,24(sp)
    8000309a:	e822                	sd	s0,16(sp)
    8000309c:	e426                	sd	s1,8(sp)
    8000309e:	1000                	addi	s0,sp,32
    800030a0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030a2:	00034517          	auipc	a0,0x34
    800030a6:	04650513          	addi	a0,a0,70 # 800370e8 <bcache>
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	c36080e7          	jalr	-970(ra) # 80000ce0 <acquire>
  b->refcnt++;
    800030b2:	40bc                	lw	a5,64(s1)
    800030b4:	2785                	addiw	a5,a5,1
    800030b6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030b8:	00034517          	auipc	a0,0x34
    800030bc:	03050513          	addi	a0,a0,48 # 800370e8 <bcache>
    800030c0:	ffffe097          	auipc	ra,0xffffe
    800030c4:	cd4080e7          	jalr	-812(ra) # 80000d94 <release>
}
    800030c8:	60e2                	ld	ra,24(sp)
    800030ca:	6442                	ld	s0,16(sp)
    800030cc:	64a2                	ld	s1,8(sp)
    800030ce:	6105                	addi	sp,sp,32
    800030d0:	8082                	ret

00000000800030d2 <bunpin>:

void
bunpin(struct buf *b) {
    800030d2:	1101                	addi	sp,sp,-32
    800030d4:	ec06                	sd	ra,24(sp)
    800030d6:	e822                	sd	s0,16(sp)
    800030d8:	e426                	sd	s1,8(sp)
    800030da:	1000                	addi	s0,sp,32
    800030dc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030de:	00034517          	auipc	a0,0x34
    800030e2:	00a50513          	addi	a0,a0,10 # 800370e8 <bcache>
    800030e6:	ffffe097          	auipc	ra,0xffffe
    800030ea:	bfa080e7          	jalr	-1030(ra) # 80000ce0 <acquire>
  b->refcnt--;
    800030ee:	40bc                	lw	a5,64(s1)
    800030f0:	37fd                	addiw	a5,a5,-1
    800030f2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030f4:	00034517          	auipc	a0,0x34
    800030f8:	ff450513          	addi	a0,a0,-12 # 800370e8 <bcache>
    800030fc:	ffffe097          	auipc	ra,0xffffe
    80003100:	c98080e7          	jalr	-872(ra) # 80000d94 <release>
}
    80003104:	60e2                	ld	ra,24(sp)
    80003106:	6442                	ld	s0,16(sp)
    80003108:	64a2                	ld	s1,8(sp)
    8000310a:	6105                	addi	sp,sp,32
    8000310c:	8082                	ret

000000008000310e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000310e:	1101                	addi	sp,sp,-32
    80003110:	ec06                	sd	ra,24(sp)
    80003112:	e822                	sd	s0,16(sp)
    80003114:	e426                	sd	s1,8(sp)
    80003116:	e04a                	sd	s2,0(sp)
    80003118:	1000                	addi	s0,sp,32
    8000311a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000311c:	00d5d59b          	srliw	a1,a1,0xd
    80003120:	0003c797          	auipc	a5,0x3c
    80003124:	6a47a783          	lw	a5,1700(a5) # 8003f7c4 <sb+0x1c>
    80003128:	9dbd                	addw	a1,a1,a5
    8000312a:	00000097          	auipc	ra,0x0
    8000312e:	d9e080e7          	jalr	-610(ra) # 80002ec8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003132:	0074f713          	andi	a4,s1,7
    80003136:	4785                	li	a5,1
    80003138:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000313c:	14ce                	slli	s1,s1,0x33
    8000313e:	90d9                	srli	s1,s1,0x36
    80003140:	00950733          	add	a4,a0,s1
    80003144:	05874703          	lbu	a4,88(a4)
    80003148:	00e7f6b3          	and	a3,a5,a4
    8000314c:	c69d                	beqz	a3,8000317a <bfree+0x6c>
    8000314e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003150:	94aa                	add	s1,s1,a0
    80003152:	fff7c793          	not	a5,a5
    80003156:	8ff9                	and	a5,a5,a4
    80003158:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000315c:	00001097          	auipc	ra,0x1
    80003160:	118080e7          	jalr	280(ra) # 80004274 <log_write>
  brelse(bp);
    80003164:	854a                	mv	a0,s2
    80003166:	00000097          	auipc	ra,0x0
    8000316a:	e92080e7          	jalr	-366(ra) # 80002ff8 <brelse>
}
    8000316e:	60e2                	ld	ra,24(sp)
    80003170:	6442                	ld	s0,16(sp)
    80003172:	64a2                	ld	s1,8(sp)
    80003174:	6902                	ld	s2,0(sp)
    80003176:	6105                	addi	sp,sp,32
    80003178:	8082                	ret
    panic("freeing free block");
    8000317a:	00005517          	auipc	a0,0x5
    8000317e:	3b650513          	addi	a0,a0,950 # 80008530 <syscalls+0xe8>
    80003182:	ffffd097          	auipc	ra,0xffffd
    80003186:	3bc080e7          	jalr	956(ra) # 8000053e <panic>

000000008000318a <balloc>:
{
    8000318a:	711d                	addi	sp,sp,-96
    8000318c:	ec86                	sd	ra,88(sp)
    8000318e:	e8a2                	sd	s0,80(sp)
    80003190:	e4a6                	sd	s1,72(sp)
    80003192:	e0ca                	sd	s2,64(sp)
    80003194:	fc4e                	sd	s3,56(sp)
    80003196:	f852                	sd	s4,48(sp)
    80003198:	f456                	sd	s5,40(sp)
    8000319a:	f05a                	sd	s6,32(sp)
    8000319c:	ec5e                	sd	s7,24(sp)
    8000319e:	e862                	sd	s8,16(sp)
    800031a0:	e466                	sd	s9,8(sp)
    800031a2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031a4:	0003c797          	auipc	a5,0x3c
    800031a8:	6087a783          	lw	a5,1544(a5) # 8003f7ac <sb+0x4>
    800031ac:	cbd1                	beqz	a5,80003240 <balloc+0xb6>
    800031ae:	8baa                	mv	s7,a0
    800031b0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031b2:	0003cb17          	auipc	s6,0x3c
    800031b6:	5f6b0b13          	addi	s6,s6,1526 # 8003f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031ba:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031bc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031be:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031c0:	6c89                	lui	s9,0x2
    800031c2:	a831                	j	800031de <balloc+0x54>
    brelse(bp);
    800031c4:	854a                	mv	a0,s2
    800031c6:	00000097          	auipc	ra,0x0
    800031ca:	e32080e7          	jalr	-462(ra) # 80002ff8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031ce:	015c87bb          	addw	a5,s9,s5
    800031d2:	00078a9b          	sext.w	s5,a5
    800031d6:	004b2703          	lw	a4,4(s6)
    800031da:	06eaf363          	bgeu	s5,a4,80003240 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800031de:	41fad79b          	sraiw	a5,s5,0x1f
    800031e2:	0137d79b          	srliw	a5,a5,0x13
    800031e6:	015787bb          	addw	a5,a5,s5
    800031ea:	40d7d79b          	sraiw	a5,a5,0xd
    800031ee:	01cb2583          	lw	a1,28(s6)
    800031f2:	9dbd                	addw	a1,a1,a5
    800031f4:	855e                	mv	a0,s7
    800031f6:	00000097          	auipc	ra,0x0
    800031fa:	cd2080e7          	jalr	-814(ra) # 80002ec8 <bread>
    800031fe:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003200:	004b2503          	lw	a0,4(s6)
    80003204:	000a849b          	sext.w	s1,s5
    80003208:	8662                	mv	a2,s8
    8000320a:	faa4fde3          	bgeu	s1,a0,800031c4 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000320e:	41f6579b          	sraiw	a5,a2,0x1f
    80003212:	01d7d69b          	srliw	a3,a5,0x1d
    80003216:	00c6873b          	addw	a4,a3,a2
    8000321a:	00777793          	andi	a5,a4,7
    8000321e:	9f95                	subw	a5,a5,a3
    80003220:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003224:	4037571b          	sraiw	a4,a4,0x3
    80003228:	00e906b3          	add	a3,s2,a4
    8000322c:	0586c683          	lbu	a3,88(a3)
    80003230:	00d7f5b3          	and	a1,a5,a3
    80003234:	cd91                	beqz	a1,80003250 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003236:	2605                	addiw	a2,a2,1
    80003238:	2485                	addiw	s1,s1,1
    8000323a:	fd4618e3          	bne	a2,s4,8000320a <balloc+0x80>
    8000323e:	b759                	j	800031c4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003240:	00005517          	auipc	a0,0x5
    80003244:	30850513          	addi	a0,a0,776 # 80008548 <syscalls+0x100>
    80003248:	ffffd097          	auipc	ra,0xffffd
    8000324c:	2f6080e7          	jalr	758(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003250:	974a                	add	a4,a4,s2
    80003252:	8fd5                	or	a5,a5,a3
    80003254:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003258:	854a                	mv	a0,s2
    8000325a:	00001097          	auipc	ra,0x1
    8000325e:	01a080e7          	jalr	26(ra) # 80004274 <log_write>
        brelse(bp);
    80003262:	854a                	mv	a0,s2
    80003264:	00000097          	auipc	ra,0x0
    80003268:	d94080e7          	jalr	-620(ra) # 80002ff8 <brelse>
  bp = bread(dev, bno);
    8000326c:	85a6                	mv	a1,s1
    8000326e:	855e                	mv	a0,s7
    80003270:	00000097          	auipc	ra,0x0
    80003274:	c58080e7          	jalr	-936(ra) # 80002ec8 <bread>
    80003278:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000327a:	40000613          	li	a2,1024
    8000327e:	4581                	li	a1,0
    80003280:	05850513          	addi	a0,a0,88
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	b58080e7          	jalr	-1192(ra) # 80000ddc <memset>
  log_write(bp);
    8000328c:	854a                	mv	a0,s2
    8000328e:	00001097          	auipc	ra,0x1
    80003292:	fe6080e7          	jalr	-26(ra) # 80004274 <log_write>
  brelse(bp);
    80003296:	854a                	mv	a0,s2
    80003298:	00000097          	auipc	ra,0x0
    8000329c:	d60080e7          	jalr	-672(ra) # 80002ff8 <brelse>
}
    800032a0:	8526                	mv	a0,s1
    800032a2:	60e6                	ld	ra,88(sp)
    800032a4:	6446                	ld	s0,80(sp)
    800032a6:	64a6                	ld	s1,72(sp)
    800032a8:	6906                	ld	s2,64(sp)
    800032aa:	79e2                	ld	s3,56(sp)
    800032ac:	7a42                	ld	s4,48(sp)
    800032ae:	7aa2                	ld	s5,40(sp)
    800032b0:	7b02                	ld	s6,32(sp)
    800032b2:	6be2                	ld	s7,24(sp)
    800032b4:	6c42                	ld	s8,16(sp)
    800032b6:	6ca2                	ld	s9,8(sp)
    800032b8:	6125                	addi	sp,sp,96
    800032ba:	8082                	ret

00000000800032bc <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032bc:	7179                	addi	sp,sp,-48
    800032be:	f406                	sd	ra,40(sp)
    800032c0:	f022                	sd	s0,32(sp)
    800032c2:	ec26                	sd	s1,24(sp)
    800032c4:	e84a                	sd	s2,16(sp)
    800032c6:	e44e                	sd	s3,8(sp)
    800032c8:	e052                	sd	s4,0(sp)
    800032ca:	1800                	addi	s0,sp,48
    800032cc:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032ce:	47ad                	li	a5,11
    800032d0:	04b7fe63          	bgeu	a5,a1,8000332c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800032d4:	ff45849b          	addiw	s1,a1,-12
    800032d8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032dc:	0ff00793          	li	a5,255
    800032e0:	0ae7e363          	bltu	a5,a4,80003386 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800032e4:	08052583          	lw	a1,128(a0)
    800032e8:	c5ad                	beqz	a1,80003352 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800032ea:	00092503          	lw	a0,0(s2)
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	bda080e7          	jalr	-1062(ra) # 80002ec8 <bread>
    800032f6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032f8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032fc:	02049593          	slli	a1,s1,0x20
    80003300:	9181                	srli	a1,a1,0x20
    80003302:	058a                	slli	a1,a1,0x2
    80003304:	00b784b3          	add	s1,a5,a1
    80003308:	0004a983          	lw	s3,0(s1)
    8000330c:	04098d63          	beqz	s3,80003366 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003310:	8552                	mv	a0,s4
    80003312:	00000097          	auipc	ra,0x0
    80003316:	ce6080e7          	jalr	-794(ra) # 80002ff8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000331a:	854e                	mv	a0,s3
    8000331c:	70a2                	ld	ra,40(sp)
    8000331e:	7402                	ld	s0,32(sp)
    80003320:	64e2                	ld	s1,24(sp)
    80003322:	6942                	ld	s2,16(sp)
    80003324:	69a2                	ld	s3,8(sp)
    80003326:	6a02                	ld	s4,0(sp)
    80003328:	6145                	addi	sp,sp,48
    8000332a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000332c:	02059493          	slli	s1,a1,0x20
    80003330:	9081                	srli	s1,s1,0x20
    80003332:	048a                	slli	s1,s1,0x2
    80003334:	94aa                	add	s1,s1,a0
    80003336:	0504a983          	lw	s3,80(s1)
    8000333a:	fe0990e3          	bnez	s3,8000331a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000333e:	4108                	lw	a0,0(a0)
    80003340:	00000097          	auipc	ra,0x0
    80003344:	e4a080e7          	jalr	-438(ra) # 8000318a <balloc>
    80003348:	0005099b          	sext.w	s3,a0
    8000334c:	0534a823          	sw	s3,80(s1)
    80003350:	b7e9                	j	8000331a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003352:	4108                	lw	a0,0(a0)
    80003354:	00000097          	auipc	ra,0x0
    80003358:	e36080e7          	jalr	-458(ra) # 8000318a <balloc>
    8000335c:	0005059b          	sext.w	a1,a0
    80003360:	08b92023          	sw	a1,128(s2)
    80003364:	b759                	j	800032ea <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003366:	00092503          	lw	a0,0(s2)
    8000336a:	00000097          	auipc	ra,0x0
    8000336e:	e20080e7          	jalr	-480(ra) # 8000318a <balloc>
    80003372:	0005099b          	sext.w	s3,a0
    80003376:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000337a:	8552                	mv	a0,s4
    8000337c:	00001097          	auipc	ra,0x1
    80003380:	ef8080e7          	jalr	-264(ra) # 80004274 <log_write>
    80003384:	b771                	j	80003310 <bmap+0x54>
  panic("bmap: out of range");
    80003386:	00005517          	auipc	a0,0x5
    8000338a:	1da50513          	addi	a0,a0,474 # 80008560 <syscalls+0x118>
    8000338e:	ffffd097          	auipc	ra,0xffffd
    80003392:	1b0080e7          	jalr	432(ra) # 8000053e <panic>

0000000080003396 <iget>:
{
    80003396:	7179                	addi	sp,sp,-48
    80003398:	f406                	sd	ra,40(sp)
    8000339a:	f022                	sd	s0,32(sp)
    8000339c:	ec26                	sd	s1,24(sp)
    8000339e:	e84a                	sd	s2,16(sp)
    800033a0:	e44e                	sd	s3,8(sp)
    800033a2:	e052                	sd	s4,0(sp)
    800033a4:	1800                	addi	s0,sp,48
    800033a6:	89aa                	mv	s3,a0
    800033a8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800033aa:	0003c517          	auipc	a0,0x3c
    800033ae:	41e50513          	addi	a0,a0,1054 # 8003f7c8 <itable>
    800033b2:	ffffe097          	auipc	ra,0xffffe
    800033b6:	92e080e7          	jalr	-1746(ra) # 80000ce0 <acquire>
  empty = 0;
    800033ba:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033bc:	0003c497          	auipc	s1,0x3c
    800033c0:	42448493          	addi	s1,s1,1060 # 8003f7e0 <itable+0x18>
    800033c4:	0003e697          	auipc	a3,0x3e
    800033c8:	eac68693          	addi	a3,a3,-340 # 80041270 <log>
    800033cc:	a039                	j	800033da <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033ce:	02090b63          	beqz	s2,80003404 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033d2:	08848493          	addi	s1,s1,136
    800033d6:	02d48a63          	beq	s1,a3,8000340a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033da:	449c                	lw	a5,8(s1)
    800033dc:	fef059e3          	blez	a5,800033ce <iget+0x38>
    800033e0:	4098                	lw	a4,0(s1)
    800033e2:	ff3716e3          	bne	a4,s3,800033ce <iget+0x38>
    800033e6:	40d8                	lw	a4,4(s1)
    800033e8:	ff4713e3          	bne	a4,s4,800033ce <iget+0x38>
      ip->ref++;
    800033ec:	2785                	addiw	a5,a5,1
    800033ee:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800033f0:	0003c517          	auipc	a0,0x3c
    800033f4:	3d850513          	addi	a0,a0,984 # 8003f7c8 <itable>
    800033f8:	ffffe097          	auipc	ra,0xffffe
    800033fc:	99c080e7          	jalr	-1636(ra) # 80000d94 <release>
      return ip;
    80003400:	8926                	mv	s2,s1
    80003402:	a03d                	j	80003430 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003404:	f7f9                	bnez	a5,800033d2 <iget+0x3c>
    80003406:	8926                	mv	s2,s1
    80003408:	b7e9                	j	800033d2 <iget+0x3c>
  if(empty == 0)
    8000340a:	02090c63          	beqz	s2,80003442 <iget+0xac>
  ip->dev = dev;
    8000340e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003412:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003416:	4785                	li	a5,1
    80003418:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000341c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003420:	0003c517          	auipc	a0,0x3c
    80003424:	3a850513          	addi	a0,a0,936 # 8003f7c8 <itable>
    80003428:	ffffe097          	auipc	ra,0xffffe
    8000342c:	96c080e7          	jalr	-1684(ra) # 80000d94 <release>
}
    80003430:	854a                	mv	a0,s2
    80003432:	70a2                	ld	ra,40(sp)
    80003434:	7402                	ld	s0,32(sp)
    80003436:	64e2                	ld	s1,24(sp)
    80003438:	6942                	ld	s2,16(sp)
    8000343a:	69a2                	ld	s3,8(sp)
    8000343c:	6a02                	ld	s4,0(sp)
    8000343e:	6145                	addi	sp,sp,48
    80003440:	8082                	ret
    panic("iget: no inodes");
    80003442:	00005517          	auipc	a0,0x5
    80003446:	13650513          	addi	a0,a0,310 # 80008578 <syscalls+0x130>
    8000344a:	ffffd097          	auipc	ra,0xffffd
    8000344e:	0f4080e7          	jalr	244(ra) # 8000053e <panic>

0000000080003452 <fsinit>:
fsinit(int dev) {
    80003452:	7179                	addi	sp,sp,-48
    80003454:	f406                	sd	ra,40(sp)
    80003456:	f022                	sd	s0,32(sp)
    80003458:	ec26                	sd	s1,24(sp)
    8000345a:	e84a                	sd	s2,16(sp)
    8000345c:	e44e                	sd	s3,8(sp)
    8000345e:	1800                	addi	s0,sp,48
    80003460:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003462:	4585                	li	a1,1
    80003464:	00000097          	auipc	ra,0x0
    80003468:	a64080e7          	jalr	-1436(ra) # 80002ec8 <bread>
    8000346c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000346e:	0003c997          	auipc	s3,0x3c
    80003472:	33a98993          	addi	s3,s3,826 # 8003f7a8 <sb>
    80003476:	02000613          	li	a2,32
    8000347a:	05850593          	addi	a1,a0,88
    8000347e:	854e                	mv	a0,s3
    80003480:	ffffe097          	auipc	ra,0xffffe
    80003484:	9bc080e7          	jalr	-1604(ra) # 80000e3c <memmove>
  brelse(bp);
    80003488:	8526                	mv	a0,s1
    8000348a:	00000097          	auipc	ra,0x0
    8000348e:	b6e080e7          	jalr	-1170(ra) # 80002ff8 <brelse>
  if(sb.magic != FSMAGIC)
    80003492:	0009a703          	lw	a4,0(s3)
    80003496:	102037b7          	lui	a5,0x10203
    8000349a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000349e:	02f71263          	bne	a4,a5,800034c2 <fsinit+0x70>
  initlog(dev, &sb);
    800034a2:	0003c597          	auipc	a1,0x3c
    800034a6:	30658593          	addi	a1,a1,774 # 8003f7a8 <sb>
    800034aa:	854a                	mv	a0,s2
    800034ac:	00001097          	auipc	ra,0x1
    800034b0:	b4c080e7          	jalr	-1204(ra) # 80003ff8 <initlog>
}
    800034b4:	70a2                	ld	ra,40(sp)
    800034b6:	7402                	ld	s0,32(sp)
    800034b8:	64e2                	ld	s1,24(sp)
    800034ba:	6942                	ld	s2,16(sp)
    800034bc:	69a2                	ld	s3,8(sp)
    800034be:	6145                	addi	sp,sp,48
    800034c0:	8082                	ret
    panic("invalid file system");
    800034c2:	00005517          	auipc	a0,0x5
    800034c6:	0c650513          	addi	a0,a0,198 # 80008588 <syscalls+0x140>
    800034ca:	ffffd097          	auipc	ra,0xffffd
    800034ce:	074080e7          	jalr	116(ra) # 8000053e <panic>

00000000800034d2 <iinit>:
{
    800034d2:	7179                	addi	sp,sp,-48
    800034d4:	f406                	sd	ra,40(sp)
    800034d6:	f022                	sd	s0,32(sp)
    800034d8:	ec26                	sd	s1,24(sp)
    800034da:	e84a                	sd	s2,16(sp)
    800034dc:	e44e                	sd	s3,8(sp)
    800034de:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800034e0:	00005597          	auipc	a1,0x5
    800034e4:	0c058593          	addi	a1,a1,192 # 800085a0 <syscalls+0x158>
    800034e8:	0003c517          	auipc	a0,0x3c
    800034ec:	2e050513          	addi	a0,a0,736 # 8003f7c8 <itable>
    800034f0:	ffffd097          	auipc	ra,0xffffd
    800034f4:	760080e7          	jalr	1888(ra) # 80000c50 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034f8:	0003c497          	auipc	s1,0x3c
    800034fc:	2f848493          	addi	s1,s1,760 # 8003f7f0 <itable+0x28>
    80003500:	0003e997          	auipc	s3,0x3e
    80003504:	d8098993          	addi	s3,s3,-640 # 80041280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003508:	00005917          	auipc	s2,0x5
    8000350c:	0a090913          	addi	s2,s2,160 # 800085a8 <syscalls+0x160>
    80003510:	85ca                	mv	a1,s2
    80003512:	8526                	mv	a0,s1
    80003514:	00001097          	auipc	ra,0x1
    80003518:	e46080e7          	jalr	-442(ra) # 8000435a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000351c:	08848493          	addi	s1,s1,136
    80003520:	ff3498e3          	bne	s1,s3,80003510 <iinit+0x3e>
}
    80003524:	70a2                	ld	ra,40(sp)
    80003526:	7402                	ld	s0,32(sp)
    80003528:	64e2                	ld	s1,24(sp)
    8000352a:	6942                	ld	s2,16(sp)
    8000352c:	69a2                	ld	s3,8(sp)
    8000352e:	6145                	addi	sp,sp,48
    80003530:	8082                	ret

0000000080003532 <ialloc>:
{
    80003532:	715d                	addi	sp,sp,-80
    80003534:	e486                	sd	ra,72(sp)
    80003536:	e0a2                	sd	s0,64(sp)
    80003538:	fc26                	sd	s1,56(sp)
    8000353a:	f84a                	sd	s2,48(sp)
    8000353c:	f44e                	sd	s3,40(sp)
    8000353e:	f052                	sd	s4,32(sp)
    80003540:	ec56                	sd	s5,24(sp)
    80003542:	e85a                	sd	s6,16(sp)
    80003544:	e45e                	sd	s7,8(sp)
    80003546:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003548:	0003c717          	auipc	a4,0x3c
    8000354c:	26c72703          	lw	a4,620(a4) # 8003f7b4 <sb+0xc>
    80003550:	4785                	li	a5,1
    80003552:	04e7fa63          	bgeu	a5,a4,800035a6 <ialloc+0x74>
    80003556:	8aaa                	mv	s5,a0
    80003558:	8bae                	mv	s7,a1
    8000355a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000355c:	0003ca17          	auipc	s4,0x3c
    80003560:	24ca0a13          	addi	s4,s4,588 # 8003f7a8 <sb>
    80003564:	00048b1b          	sext.w	s6,s1
    80003568:	0044d593          	srli	a1,s1,0x4
    8000356c:	018a2783          	lw	a5,24(s4)
    80003570:	9dbd                	addw	a1,a1,a5
    80003572:	8556                	mv	a0,s5
    80003574:	00000097          	auipc	ra,0x0
    80003578:	954080e7          	jalr	-1708(ra) # 80002ec8 <bread>
    8000357c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000357e:	05850993          	addi	s3,a0,88
    80003582:	00f4f793          	andi	a5,s1,15
    80003586:	079a                	slli	a5,a5,0x6
    80003588:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000358a:	00099783          	lh	a5,0(s3)
    8000358e:	c785                	beqz	a5,800035b6 <ialloc+0x84>
    brelse(bp);
    80003590:	00000097          	auipc	ra,0x0
    80003594:	a68080e7          	jalr	-1432(ra) # 80002ff8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003598:	0485                	addi	s1,s1,1
    8000359a:	00ca2703          	lw	a4,12(s4)
    8000359e:	0004879b          	sext.w	a5,s1
    800035a2:	fce7e1e3          	bltu	a5,a4,80003564 <ialloc+0x32>
  panic("ialloc: no inodes");
    800035a6:	00005517          	auipc	a0,0x5
    800035aa:	00a50513          	addi	a0,a0,10 # 800085b0 <syscalls+0x168>
    800035ae:	ffffd097          	auipc	ra,0xffffd
    800035b2:	f90080e7          	jalr	-112(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800035b6:	04000613          	li	a2,64
    800035ba:	4581                	li	a1,0
    800035bc:	854e                	mv	a0,s3
    800035be:	ffffe097          	auipc	ra,0xffffe
    800035c2:	81e080e7          	jalr	-2018(ra) # 80000ddc <memset>
      dip->type = type;
    800035c6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035ca:	854a                	mv	a0,s2
    800035cc:	00001097          	auipc	ra,0x1
    800035d0:	ca8080e7          	jalr	-856(ra) # 80004274 <log_write>
      brelse(bp);
    800035d4:	854a                	mv	a0,s2
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	a22080e7          	jalr	-1502(ra) # 80002ff8 <brelse>
      return iget(dev, inum);
    800035de:	85da                	mv	a1,s6
    800035e0:	8556                	mv	a0,s5
    800035e2:	00000097          	auipc	ra,0x0
    800035e6:	db4080e7          	jalr	-588(ra) # 80003396 <iget>
}
    800035ea:	60a6                	ld	ra,72(sp)
    800035ec:	6406                	ld	s0,64(sp)
    800035ee:	74e2                	ld	s1,56(sp)
    800035f0:	7942                	ld	s2,48(sp)
    800035f2:	79a2                	ld	s3,40(sp)
    800035f4:	7a02                	ld	s4,32(sp)
    800035f6:	6ae2                	ld	s5,24(sp)
    800035f8:	6b42                	ld	s6,16(sp)
    800035fa:	6ba2                	ld	s7,8(sp)
    800035fc:	6161                	addi	sp,sp,80
    800035fe:	8082                	ret

0000000080003600 <iupdate>:
{
    80003600:	1101                	addi	sp,sp,-32
    80003602:	ec06                	sd	ra,24(sp)
    80003604:	e822                	sd	s0,16(sp)
    80003606:	e426                	sd	s1,8(sp)
    80003608:	e04a                	sd	s2,0(sp)
    8000360a:	1000                	addi	s0,sp,32
    8000360c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000360e:	415c                	lw	a5,4(a0)
    80003610:	0047d79b          	srliw	a5,a5,0x4
    80003614:	0003c597          	auipc	a1,0x3c
    80003618:	1ac5a583          	lw	a1,428(a1) # 8003f7c0 <sb+0x18>
    8000361c:	9dbd                	addw	a1,a1,a5
    8000361e:	4108                	lw	a0,0(a0)
    80003620:	00000097          	auipc	ra,0x0
    80003624:	8a8080e7          	jalr	-1880(ra) # 80002ec8 <bread>
    80003628:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000362a:	05850793          	addi	a5,a0,88
    8000362e:	40c8                	lw	a0,4(s1)
    80003630:	893d                	andi	a0,a0,15
    80003632:	051a                	slli	a0,a0,0x6
    80003634:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003636:	04449703          	lh	a4,68(s1)
    8000363a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000363e:	04649703          	lh	a4,70(s1)
    80003642:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003646:	04849703          	lh	a4,72(s1)
    8000364a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000364e:	04a49703          	lh	a4,74(s1)
    80003652:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003656:	44f8                	lw	a4,76(s1)
    80003658:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000365a:	03400613          	li	a2,52
    8000365e:	05048593          	addi	a1,s1,80
    80003662:	0531                	addi	a0,a0,12
    80003664:	ffffd097          	auipc	ra,0xffffd
    80003668:	7d8080e7          	jalr	2008(ra) # 80000e3c <memmove>
  log_write(bp);
    8000366c:	854a                	mv	a0,s2
    8000366e:	00001097          	auipc	ra,0x1
    80003672:	c06080e7          	jalr	-1018(ra) # 80004274 <log_write>
  brelse(bp);
    80003676:	854a                	mv	a0,s2
    80003678:	00000097          	auipc	ra,0x0
    8000367c:	980080e7          	jalr	-1664(ra) # 80002ff8 <brelse>
}
    80003680:	60e2                	ld	ra,24(sp)
    80003682:	6442                	ld	s0,16(sp)
    80003684:	64a2                	ld	s1,8(sp)
    80003686:	6902                	ld	s2,0(sp)
    80003688:	6105                	addi	sp,sp,32
    8000368a:	8082                	ret

000000008000368c <idup>:
{
    8000368c:	1101                	addi	sp,sp,-32
    8000368e:	ec06                	sd	ra,24(sp)
    80003690:	e822                	sd	s0,16(sp)
    80003692:	e426                	sd	s1,8(sp)
    80003694:	1000                	addi	s0,sp,32
    80003696:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003698:	0003c517          	auipc	a0,0x3c
    8000369c:	13050513          	addi	a0,a0,304 # 8003f7c8 <itable>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	640080e7          	jalr	1600(ra) # 80000ce0 <acquire>
  ip->ref++;
    800036a8:	449c                	lw	a5,8(s1)
    800036aa:	2785                	addiw	a5,a5,1
    800036ac:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800036ae:	0003c517          	auipc	a0,0x3c
    800036b2:	11a50513          	addi	a0,a0,282 # 8003f7c8 <itable>
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	6de080e7          	jalr	1758(ra) # 80000d94 <release>
}
    800036be:	8526                	mv	a0,s1
    800036c0:	60e2                	ld	ra,24(sp)
    800036c2:	6442                	ld	s0,16(sp)
    800036c4:	64a2                	ld	s1,8(sp)
    800036c6:	6105                	addi	sp,sp,32
    800036c8:	8082                	ret

00000000800036ca <ilock>:
{
    800036ca:	1101                	addi	sp,sp,-32
    800036cc:	ec06                	sd	ra,24(sp)
    800036ce:	e822                	sd	s0,16(sp)
    800036d0:	e426                	sd	s1,8(sp)
    800036d2:	e04a                	sd	s2,0(sp)
    800036d4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036d6:	c115                	beqz	a0,800036fa <ilock+0x30>
    800036d8:	84aa                	mv	s1,a0
    800036da:	451c                	lw	a5,8(a0)
    800036dc:	00f05f63          	blez	a5,800036fa <ilock+0x30>
  acquiresleep(&ip->lock);
    800036e0:	0541                	addi	a0,a0,16
    800036e2:	00001097          	auipc	ra,0x1
    800036e6:	cb2080e7          	jalr	-846(ra) # 80004394 <acquiresleep>
  if(ip->valid == 0){
    800036ea:	40bc                	lw	a5,64(s1)
    800036ec:	cf99                	beqz	a5,8000370a <ilock+0x40>
}
    800036ee:	60e2                	ld	ra,24(sp)
    800036f0:	6442                	ld	s0,16(sp)
    800036f2:	64a2                	ld	s1,8(sp)
    800036f4:	6902                	ld	s2,0(sp)
    800036f6:	6105                	addi	sp,sp,32
    800036f8:	8082                	ret
    panic("ilock");
    800036fa:	00005517          	auipc	a0,0x5
    800036fe:	ece50513          	addi	a0,a0,-306 # 800085c8 <syscalls+0x180>
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	e3c080e7          	jalr	-452(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000370a:	40dc                	lw	a5,4(s1)
    8000370c:	0047d79b          	srliw	a5,a5,0x4
    80003710:	0003c597          	auipc	a1,0x3c
    80003714:	0b05a583          	lw	a1,176(a1) # 8003f7c0 <sb+0x18>
    80003718:	9dbd                	addw	a1,a1,a5
    8000371a:	4088                	lw	a0,0(s1)
    8000371c:	fffff097          	auipc	ra,0xfffff
    80003720:	7ac080e7          	jalr	1964(ra) # 80002ec8 <bread>
    80003724:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003726:	05850593          	addi	a1,a0,88
    8000372a:	40dc                	lw	a5,4(s1)
    8000372c:	8bbd                	andi	a5,a5,15
    8000372e:	079a                	slli	a5,a5,0x6
    80003730:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003732:	00059783          	lh	a5,0(a1)
    80003736:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000373a:	00259783          	lh	a5,2(a1)
    8000373e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003742:	00459783          	lh	a5,4(a1)
    80003746:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000374a:	00659783          	lh	a5,6(a1)
    8000374e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003752:	459c                	lw	a5,8(a1)
    80003754:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003756:	03400613          	li	a2,52
    8000375a:	05b1                	addi	a1,a1,12
    8000375c:	05048513          	addi	a0,s1,80
    80003760:	ffffd097          	auipc	ra,0xffffd
    80003764:	6dc080e7          	jalr	1756(ra) # 80000e3c <memmove>
    brelse(bp);
    80003768:	854a                	mv	a0,s2
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	88e080e7          	jalr	-1906(ra) # 80002ff8 <brelse>
    ip->valid = 1;
    80003772:	4785                	li	a5,1
    80003774:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003776:	04449783          	lh	a5,68(s1)
    8000377a:	fbb5                	bnez	a5,800036ee <ilock+0x24>
      panic("ilock: no type");
    8000377c:	00005517          	auipc	a0,0x5
    80003780:	e5450513          	addi	a0,a0,-428 # 800085d0 <syscalls+0x188>
    80003784:	ffffd097          	auipc	ra,0xffffd
    80003788:	dba080e7          	jalr	-582(ra) # 8000053e <panic>

000000008000378c <iunlock>:
{
    8000378c:	1101                	addi	sp,sp,-32
    8000378e:	ec06                	sd	ra,24(sp)
    80003790:	e822                	sd	s0,16(sp)
    80003792:	e426                	sd	s1,8(sp)
    80003794:	e04a                	sd	s2,0(sp)
    80003796:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003798:	c905                	beqz	a0,800037c8 <iunlock+0x3c>
    8000379a:	84aa                	mv	s1,a0
    8000379c:	01050913          	addi	s2,a0,16
    800037a0:	854a                	mv	a0,s2
    800037a2:	00001097          	auipc	ra,0x1
    800037a6:	c8c080e7          	jalr	-884(ra) # 8000442e <holdingsleep>
    800037aa:	cd19                	beqz	a0,800037c8 <iunlock+0x3c>
    800037ac:	449c                	lw	a5,8(s1)
    800037ae:	00f05d63          	blez	a5,800037c8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037b2:	854a                	mv	a0,s2
    800037b4:	00001097          	auipc	ra,0x1
    800037b8:	c36080e7          	jalr	-970(ra) # 800043ea <releasesleep>
}
    800037bc:	60e2                	ld	ra,24(sp)
    800037be:	6442                	ld	s0,16(sp)
    800037c0:	64a2                	ld	s1,8(sp)
    800037c2:	6902                	ld	s2,0(sp)
    800037c4:	6105                	addi	sp,sp,32
    800037c6:	8082                	ret
    panic("iunlock");
    800037c8:	00005517          	auipc	a0,0x5
    800037cc:	e1850513          	addi	a0,a0,-488 # 800085e0 <syscalls+0x198>
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	d6e080e7          	jalr	-658(ra) # 8000053e <panic>

00000000800037d8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037d8:	7179                	addi	sp,sp,-48
    800037da:	f406                	sd	ra,40(sp)
    800037dc:	f022                	sd	s0,32(sp)
    800037de:	ec26                	sd	s1,24(sp)
    800037e0:	e84a                	sd	s2,16(sp)
    800037e2:	e44e                	sd	s3,8(sp)
    800037e4:	e052                	sd	s4,0(sp)
    800037e6:	1800                	addi	s0,sp,48
    800037e8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037ea:	05050493          	addi	s1,a0,80
    800037ee:	08050913          	addi	s2,a0,128
    800037f2:	a021                	j	800037fa <itrunc+0x22>
    800037f4:	0491                	addi	s1,s1,4
    800037f6:	01248d63          	beq	s1,s2,80003810 <itrunc+0x38>
    if(ip->addrs[i]){
    800037fa:	408c                	lw	a1,0(s1)
    800037fc:	dde5                	beqz	a1,800037f4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037fe:	0009a503          	lw	a0,0(s3)
    80003802:	00000097          	auipc	ra,0x0
    80003806:	90c080e7          	jalr	-1780(ra) # 8000310e <bfree>
      ip->addrs[i] = 0;
    8000380a:	0004a023          	sw	zero,0(s1)
    8000380e:	b7dd                	j	800037f4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003810:	0809a583          	lw	a1,128(s3)
    80003814:	e185                	bnez	a1,80003834 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003816:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000381a:	854e                	mv	a0,s3
    8000381c:	00000097          	auipc	ra,0x0
    80003820:	de4080e7          	jalr	-540(ra) # 80003600 <iupdate>
}
    80003824:	70a2                	ld	ra,40(sp)
    80003826:	7402                	ld	s0,32(sp)
    80003828:	64e2                	ld	s1,24(sp)
    8000382a:	6942                	ld	s2,16(sp)
    8000382c:	69a2                	ld	s3,8(sp)
    8000382e:	6a02                	ld	s4,0(sp)
    80003830:	6145                	addi	sp,sp,48
    80003832:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003834:	0009a503          	lw	a0,0(s3)
    80003838:	fffff097          	auipc	ra,0xfffff
    8000383c:	690080e7          	jalr	1680(ra) # 80002ec8 <bread>
    80003840:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003842:	05850493          	addi	s1,a0,88
    80003846:	45850913          	addi	s2,a0,1112
    8000384a:	a811                	j	8000385e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000384c:	0009a503          	lw	a0,0(s3)
    80003850:	00000097          	auipc	ra,0x0
    80003854:	8be080e7          	jalr	-1858(ra) # 8000310e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003858:	0491                	addi	s1,s1,4
    8000385a:	01248563          	beq	s1,s2,80003864 <itrunc+0x8c>
      if(a[j])
    8000385e:	408c                	lw	a1,0(s1)
    80003860:	dde5                	beqz	a1,80003858 <itrunc+0x80>
    80003862:	b7ed                	j	8000384c <itrunc+0x74>
    brelse(bp);
    80003864:	8552                	mv	a0,s4
    80003866:	fffff097          	auipc	ra,0xfffff
    8000386a:	792080e7          	jalr	1938(ra) # 80002ff8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000386e:	0809a583          	lw	a1,128(s3)
    80003872:	0009a503          	lw	a0,0(s3)
    80003876:	00000097          	auipc	ra,0x0
    8000387a:	898080e7          	jalr	-1896(ra) # 8000310e <bfree>
    ip->addrs[NDIRECT] = 0;
    8000387e:	0809a023          	sw	zero,128(s3)
    80003882:	bf51                	j	80003816 <itrunc+0x3e>

0000000080003884 <iput>:
{
    80003884:	1101                	addi	sp,sp,-32
    80003886:	ec06                	sd	ra,24(sp)
    80003888:	e822                	sd	s0,16(sp)
    8000388a:	e426                	sd	s1,8(sp)
    8000388c:	e04a                	sd	s2,0(sp)
    8000388e:	1000                	addi	s0,sp,32
    80003890:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003892:	0003c517          	auipc	a0,0x3c
    80003896:	f3650513          	addi	a0,a0,-202 # 8003f7c8 <itable>
    8000389a:	ffffd097          	auipc	ra,0xffffd
    8000389e:	446080e7          	jalr	1094(ra) # 80000ce0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038a2:	4498                	lw	a4,8(s1)
    800038a4:	4785                	li	a5,1
    800038a6:	02f70363          	beq	a4,a5,800038cc <iput+0x48>
  ip->ref--;
    800038aa:	449c                	lw	a5,8(s1)
    800038ac:	37fd                	addiw	a5,a5,-1
    800038ae:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038b0:	0003c517          	auipc	a0,0x3c
    800038b4:	f1850513          	addi	a0,a0,-232 # 8003f7c8 <itable>
    800038b8:	ffffd097          	auipc	ra,0xffffd
    800038bc:	4dc080e7          	jalr	1244(ra) # 80000d94 <release>
}
    800038c0:	60e2                	ld	ra,24(sp)
    800038c2:	6442                	ld	s0,16(sp)
    800038c4:	64a2                	ld	s1,8(sp)
    800038c6:	6902                	ld	s2,0(sp)
    800038c8:	6105                	addi	sp,sp,32
    800038ca:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038cc:	40bc                	lw	a5,64(s1)
    800038ce:	dff1                	beqz	a5,800038aa <iput+0x26>
    800038d0:	04a49783          	lh	a5,74(s1)
    800038d4:	fbf9                	bnez	a5,800038aa <iput+0x26>
    acquiresleep(&ip->lock);
    800038d6:	01048913          	addi	s2,s1,16
    800038da:	854a                	mv	a0,s2
    800038dc:	00001097          	auipc	ra,0x1
    800038e0:	ab8080e7          	jalr	-1352(ra) # 80004394 <acquiresleep>
    release(&itable.lock);
    800038e4:	0003c517          	auipc	a0,0x3c
    800038e8:	ee450513          	addi	a0,a0,-284 # 8003f7c8 <itable>
    800038ec:	ffffd097          	auipc	ra,0xffffd
    800038f0:	4a8080e7          	jalr	1192(ra) # 80000d94 <release>
    itrunc(ip);
    800038f4:	8526                	mv	a0,s1
    800038f6:	00000097          	auipc	ra,0x0
    800038fa:	ee2080e7          	jalr	-286(ra) # 800037d8 <itrunc>
    ip->type = 0;
    800038fe:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003902:	8526                	mv	a0,s1
    80003904:	00000097          	auipc	ra,0x0
    80003908:	cfc080e7          	jalr	-772(ra) # 80003600 <iupdate>
    ip->valid = 0;
    8000390c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003910:	854a                	mv	a0,s2
    80003912:	00001097          	auipc	ra,0x1
    80003916:	ad8080e7          	jalr	-1320(ra) # 800043ea <releasesleep>
    acquire(&itable.lock);
    8000391a:	0003c517          	auipc	a0,0x3c
    8000391e:	eae50513          	addi	a0,a0,-338 # 8003f7c8 <itable>
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	3be080e7          	jalr	958(ra) # 80000ce0 <acquire>
    8000392a:	b741                	j	800038aa <iput+0x26>

000000008000392c <iunlockput>:
{
    8000392c:	1101                	addi	sp,sp,-32
    8000392e:	ec06                	sd	ra,24(sp)
    80003930:	e822                	sd	s0,16(sp)
    80003932:	e426                	sd	s1,8(sp)
    80003934:	1000                	addi	s0,sp,32
    80003936:	84aa                	mv	s1,a0
  iunlock(ip);
    80003938:	00000097          	auipc	ra,0x0
    8000393c:	e54080e7          	jalr	-428(ra) # 8000378c <iunlock>
  iput(ip);
    80003940:	8526                	mv	a0,s1
    80003942:	00000097          	auipc	ra,0x0
    80003946:	f42080e7          	jalr	-190(ra) # 80003884 <iput>
}
    8000394a:	60e2                	ld	ra,24(sp)
    8000394c:	6442                	ld	s0,16(sp)
    8000394e:	64a2                	ld	s1,8(sp)
    80003950:	6105                	addi	sp,sp,32
    80003952:	8082                	ret

0000000080003954 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003954:	1141                	addi	sp,sp,-16
    80003956:	e422                	sd	s0,8(sp)
    80003958:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000395a:	411c                	lw	a5,0(a0)
    8000395c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000395e:	415c                	lw	a5,4(a0)
    80003960:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003962:	04451783          	lh	a5,68(a0)
    80003966:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000396a:	04a51783          	lh	a5,74(a0)
    8000396e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003972:	04c56783          	lwu	a5,76(a0)
    80003976:	e99c                	sd	a5,16(a1)
}
    80003978:	6422                	ld	s0,8(sp)
    8000397a:	0141                	addi	sp,sp,16
    8000397c:	8082                	ret

000000008000397e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000397e:	457c                	lw	a5,76(a0)
    80003980:	0ed7e963          	bltu	a5,a3,80003a72 <readi+0xf4>
{
    80003984:	7159                	addi	sp,sp,-112
    80003986:	f486                	sd	ra,104(sp)
    80003988:	f0a2                	sd	s0,96(sp)
    8000398a:	eca6                	sd	s1,88(sp)
    8000398c:	e8ca                	sd	s2,80(sp)
    8000398e:	e4ce                	sd	s3,72(sp)
    80003990:	e0d2                	sd	s4,64(sp)
    80003992:	fc56                	sd	s5,56(sp)
    80003994:	f85a                	sd	s6,48(sp)
    80003996:	f45e                	sd	s7,40(sp)
    80003998:	f062                	sd	s8,32(sp)
    8000399a:	ec66                	sd	s9,24(sp)
    8000399c:	e86a                	sd	s10,16(sp)
    8000399e:	e46e                	sd	s11,8(sp)
    800039a0:	1880                	addi	s0,sp,112
    800039a2:	8baa                	mv	s7,a0
    800039a4:	8c2e                	mv	s8,a1
    800039a6:	8ab2                	mv	s5,a2
    800039a8:	84b6                	mv	s1,a3
    800039aa:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039ac:	9f35                	addw	a4,a4,a3
    return 0;
    800039ae:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039b0:	0ad76063          	bltu	a4,a3,80003a50 <readi+0xd2>
  if(off + n > ip->size)
    800039b4:	00e7f463          	bgeu	a5,a4,800039bc <readi+0x3e>
    n = ip->size - off;
    800039b8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039bc:	0a0b0963          	beqz	s6,80003a6e <readi+0xf0>
    800039c0:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039c2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039c6:	5cfd                	li	s9,-1
    800039c8:	a82d                	j	80003a02 <readi+0x84>
    800039ca:	020a1d93          	slli	s11,s4,0x20
    800039ce:	020ddd93          	srli	s11,s11,0x20
    800039d2:	05890613          	addi	a2,s2,88
    800039d6:	86ee                	mv	a3,s11
    800039d8:	963a                	add	a2,a2,a4
    800039da:	85d6                	mv	a1,s5
    800039dc:	8562                	mv	a0,s8
    800039de:	fffff097          	auipc	ra,0xfffff
    800039e2:	b2e080e7          	jalr	-1234(ra) # 8000250c <either_copyout>
    800039e6:	05950d63          	beq	a0,s9,80003a40 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800039ea:	854a                	mv	a0,s2
    800039ec:	fffff097          	auipc	ra,0xfffff
    800039f0:	60c080e7          	jalr	1548(ra) # 80002ff8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039f4:	013a09bb          	addw	s3,s4,s3
    800039f8:	009a04bb          	addw	s1,s4,s1
    800039fc:	9aee                	add	s5,s5,s11
    800039fe:	0569f763          	bgeu	s3,s6,80003a4c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a02:	000ba903          	lw	s2,0(s7)
    80003a06:	00a4d59b          	srliw	a1,s1,0xa
    80003a0a:	855e                	mv	a0,s7
    80003a0c:	00000097          	auipc	ra,0x0
    80003a10:	8b0080e7          	jalr	-1872(ra) # 800032bc <bmap>
    80003a14:	0005059b          	sext.w	a1,a0
    80003a18:	854a                	mv	a0,s2
    80003a1a:	fffff097          	auipc	ra,0xfffff
    80003a1e:	4ae080e7          	jalr	1198(ra) # 80002ec8 <bread>
    80003a22:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a24:	3ff4f713          	andi	a4,s1,1023
    80003a28:	40ed07bb          	subw	a5,s10,a4
    80003a2c:	413b06bb          	subw	a3,s6,s3
    80003a30:	8a3e                	mv	s4,a5
    80003a32:	2781                	sext.w	a5,a5
    80003a34:	0006861b          	sext.w	a2,a3
    80003a38:	f8f679e3          	bgeu	a2,a5,800039ca <readi+0x4c>
    80003a3c:	8a36                	mv	s4,a3
    80003a3e:	b771                	j	800039ca <readi+0x4c>
      brelse(bp);
    80003a40:	854a                	mv	a0,s2
    80003a42:	fffff097          	auipc	ra,0xfffff
    80003a46:	5b6080e7          	jalr	1462(ra) # 80002ff8 <brelse>
      tot = -1;
    80003a4a:	59fd                	li	s3,-1
  }
  return tot;
    80003a4c:	0009851b          	sext.w	a0,s3
}
    80003a50:	70a6                	ld	ra,104(sp)
    80003a52:	7406                	ld	s0,96(sp)
    80003a54:	64e6                	ld	s1,88(sp)
    80003a56:	6946                	ld	s2,80(sp)
    80003a58:	69a6                	ld	s3,72(sp)
    80003a5a:	6a06                	ld	s4,64(sp)
    80003a5c:	7ae2                	ld	s5,56(sp)
    80003a5e:	7b42                	ld	s6,48(sp)
    80003a60:	7ba2                	ld	s7,40(sp)
    80003a62:	7c02                	ld	s8,32(sp)
    80003a64:	6ce2                	ld	s9,24(sp)
    80003a66:	6d42                	ld	s10,16(sp)
    80003a68:	6da2                	ld	s11,8(sp)
    80003a6a:	6165                	addi	sp,sp,112
    80003a6c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a6e:	89da                	mv	s3,s6
    80003a70:	bff1                	j	80003a4c <readi+0xce>
    return 0;
    80003a72:	4501                	li	a0,0
}
    80003a74:	8082                	ret

0000000080003a76 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a76:	457c                	lw	a5,76(a0)
    80003a78:	10d7e863          	bltu	a5,a3,80003b88 <writei+0x112>
{
    80003a7c:	7159                	addi	sp,sp,-112
    80003a7e:	f486                	sd	ra,104(sp)
    80003a80:	f0a2                	sd	s0,96(sp)
    80003a82:	eca6                	sd	s1,88(sp)
    80003a84:	e8ca                	sd	s2,80(sp)
    80003a86:	e4ce                	sd	s3,72(sp)
    80003a88:	e0d2                	sd	s4,64(sp)
    80003a8a:	fc56                	sd	s5,56(sp)
    80003a8c:	f85a                	sd	s6,48(sp)
    80003a8e:	f45e                	sd	s7,40(sp)
    80003a90:	f062                	sd	s8,32(sp)
    80003a92:	ec66                	sd	s9,24(sp)
    80003a94:	e86a                	sd	s10,16(sp)
    80003a96:	e46e                	sd	s11,8(sp)
    80003a98:	1880                	addi	s0,sp,112
    80003a9a:	8b2a                	mv	s6,a0
    80003a9c:	8c2e                	mv	s8,a1
    80003a9e:	8ab2                	mv	s5,a2
    80003aa0:	8936                	mv	s2,a3
    80003aa2:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003aa4:	00e687bb          	addw	a5,a3,a4
    80003aa8:	0ed7e263          	bltu	a5,a3,80003b8c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003aac:	00043737          	lui	a4,0x43
    80003ab0:	0ef76063          	bltu	a4,a5,80003b90 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ab4:	0c0b8863          	beqz	s7,80003b84 <writei+0x10e>
    80003ab8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aba:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003abe:	5cfd                	li	s9,-1
    80003ac0:	a091                	j	80003b04 <writei+0x8e>
    80003ac2:	02099d93          	slli	s11,s3,0x20
    80003ac6:	020ddd93          	srli	s11,s11,0x20
    80003aca:	05848513          	addi	a0,s1,88
    80003ace:	86ee                	mv	a3,s11
    80003ad0:	8656                	mv	a2,s5
    80003ad2:	85e2                	mv	a1,s8
    80003ad4:	953a                	add	a0,a0,a4
    80003ad6:	fffff097          	auipc	ra,0xfffff
    80003ada:	a8c080e7          	jalr	-1396(ra) # 80002562 <either_copyin>
    80003ade:	07950263          	beq	a0,s9,80003b42 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ae2:	8526                	mv	a0,s1
    80003ae4:	00000097          	auipc	ra,0x0
    80003ae8:	790080e7          	jalr	1936(ra) # 80004274 <log_write>
    brelse(bp);
    80003aec:	8526                	mv	a0,s1
    80003aee:	fffff097          	auipc	ra,0xfffff
    80003af2:	50a080e7          	jalr	1290(ra) # 80002ff8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003af6:	01498a3b          	addw	s4,s3,s4
    80003afa:	0129893b          	addw	s2,s3,s2
    80003afe:	9aee                	add	s5,s5,s11
    80003b00:	057a7663          	bgeu	s4,s7,80003b4c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b04:	000b2483          	lw	s1,0(s6)
    80003b08:	00a9559b          	srliw	a1,s2,0xa
    80003b0c:	855a                	mv	a0,s6
    80003b0e:	fffff097          	auipc	ra,0xfffff
    80003b12:	7ae080e7          	jalr	1966(ra) # 800032bc <bmap>
    80003b16:	0005059b          	sext.w	a1,a0
    80003b1a:	8526                	mv	a0,s1
    80003b1c:	fffff097          	auipc	ra,0xfffff
    80003b20:	3ac080e7          	jalr	940(ra) # 80002ec8 <bread>
    80003b24:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b26:	3ff97713          	andi	a4,s2,1023
    80003b2a:	40ed07bb          	subw	a5,s10,a4
    80003b2e:	414b86bb          	subw	a3,s7,s4
    80003b32:	89be                	mv	s3,a5
    80003b34:	2781                	sext.w	a5,a5
    80003b36:	0006861b          	sext.w	a2,a3
    80003b3a:	f8f674e3          	bgeu	a2,a5,80003ac2 <writei+0x4c>
    80003b3e:	89b6                	mv	s3,a3
    80003b40:	b749                	j	80003ac2 <writei+0x4c>
      brelse(bp);
    80003b42:	8526                	mv	a0,s1
    80003b44:	fffff097          	auipc	ra,0xfffff
    80003b48:	4b4080e7          	jalr	1204(ra) # 80002ff8 <brelse>
  }

  if(off > ip->size)
    80003b4c:	04cb2783          	lw	a5,76(s6)
    80003b50:	0127f463          	bgeu	a5,s2,80003b58 <writei+0xe2>
    ip->size = off;
    80003b54:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b58:	855a                	mv	a0,s6
    80003b5a:	00000097          	auipc	ra,0x0
    80003b5e:	aa6080e7          	jalr	-1370(ra) # 80003600 <iupdate>

  return tot;
    80003b62:	000a051b          	sext.w	a0,s4
}
    80003b66:	70a6                	ld	ra,104(sp)
    80003b68:	7406                	ld	s0,96(sp)
    80003b6a:	64e6                	ld	s1,88(sp)
    80003b6c:	6946                	ld	s2,80(sp)
    80003b6e:	69a6                	ld	s3,72(sp)
    80003b70:	6a06                	ld	s4,64(sp)
    80003b72:	7ae2                	ld	s5,56(sp)
    80003b74:	7b42                	ld	s6,48(sp)
    80003b76:	7ba2                	ld	s7,40(sp)
    80003b78:	7c02                	ld	s8,32(sp)
    80003b7a:	6ce2                	ld	s9,24(sp)
    80003b7c:	6d42                	ld	s10,16(sp)
    80003b7e:	6da2                	ld	s11,8(sp)
    80003b80:	6165                	addi	sp,sp,112
    80003b82:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b84:	8a5e                	mv	s4,s7
    80003b86:	bfc9                	j	80003b58 <writei+0xe2>
    return -1;
    80003b88:	557d                	li	a0,-1
}
    80003b8a:	8082                	ret
    return -1;
    80003b8c:	557d                	li	a0,-1
    80003b8e:	bfe1                	j	80003b66 <writei+0xf0>
    return -1;
    80003b90:	557d                	li	a0,-1
    80003b92:	bfd1                	j	80003b66 <writei+0xf0>

0000000080003b94 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b94:	1141                	addi	sp,sp,-16
    80003b96:	e406                	sd	ra,8(sp)
    80003b98:	e022                	sd	s0,0(sp)
    80003b9a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b9c:	4639                	li	a2,14
    80003b9e:	ffffd097          	auipc	ra,0xffffd
    80003ba2:	316080e7          	jalr	790(ra) # 80000eb4 <strncmp>
}
    80003ba6:	60a2                	ld	ra,8(sp)
    80003ba8:	6402                	ld	s0,0(sp)
    80003baa:	0141                	addi	sp,sp,16
    80003bac:	8082                	ret

0000000080003bae <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003bae:	7139                	addi	sp,sp,-64
    80003bb0:	fc06                	sd	ra,56(sp)
    80003bb2:	f822                	sd	s0,48(sp)
    80003bb4:	f426                	sd	s1,40(sp)
    80003bb6:	f04a                	sd	s2,32(sp)
    80003bb8:	ec4e                	sd	s3,24(sp)
    80003bba:	e852                	sd	s4,16(sp)
    80003bbc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bbe:	04451703          	lh	a4,68(a0)
    80003bc2:	4785                	li	a5,1
    80003bc4:	00f71a63          	bne	a4,a5,80003bd8 <dirlookup+0x2a>
    80003bc8:	892a                	mv	s2,a0
    80003bca:	89ae                	mv	s3,a1
    80003bcc:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bce:	457c                	lw	a5,76(a0)
    80003bd0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bd2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bd4:	e79d                	bnez	a5,80003c02 <dirlookup+0x54>
    80003bd6:	a8a5                	j	80003c4e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003bd8:	00005517          	auipc	a0,0x5
    80003bdc:	a1050513          	addi	a0,a0,-1520 # 800085e8 <syscalls+0x1a0>
    80003be0:	ffffd097          	auipc	ra,0xffffd
    80003be4:	95e080e7          	jalr	-1698(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003be8:	00005517          	auipc	a0,0x5
    80003bec:	a1850513          	addi	a0,a0,-1512 # 80008600 <syscalls+0x1b8>
    80003bf0:	ffffd097          	auipc	ra,0xffffd
    80003bf4:	94e080e7          	jalr	-1714(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bf8:	24c1                	addiw	s1,s1,16
    80003bfa:	04c92783          	lw	a5,76(s2)
    80003bfe:	04f4f763          	bgeu	s1,a5,80003c4c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c02:	4741                	li	a4,16
    80003c04:	86a6                	mv	a3,s1
    80003c06:	fc040613          	addi	a2,s0,-64
    80003c0a:	4581                	li	a1,0
    80003c0c:	854a                	mv	a0,s2
    80003c0e:	00000097          	auipc	ra,0x0
    80003c12:	d70080e7          	jalr	-656(ra) # 8000397e <readi>
    80003c16:	47c1                	li	a5,16
    80003c18:	fcf518e3          	bne	a0,a5,80003be8 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c1c:	fc045783          	lhu	a5,-64(s0)
    80003c20:	dfe1                	beqz	a5,80003bf8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c22:	fc240593          	addi	a1,s0,-62
    80003c26:	854e                	mv	a0,s3
    80003c28:	00000097          	auipc	ra,0x0
    80003c2c:	f6c080e7          	jalr	-148(ra) # 80003b94 <namecmp>
    80003c30:	f561                	bnez	a0,80003bf8 <dirlookup+0x4a>
      if(poff)
    80003c32:	000a0463          	beqz	s4,80003c3a <dirlookup+0x8c>
        *poff = off;
    80003c36:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c3a:	fc045583          	lhu	a1,-64(s0)
    80003c3e:	00092503          	lw	a0,0(s2)
    80003c42:	fffff097          	auipc	ra,0xfffff
    80003c46:	754080e7          	jalr	1876(ra) # 80003396 <iget>
    80003c4a:	a011                	j	80003c4e <dirlookup+0xa0>
  return 0;
    80003c4c:	4501                	li	a0,0
}
    80003c4e:	70e2                	ld	ra,56(sp)
    80003c50:	7442                	ld	s0,48(sp)
    80003c52:	74a2                	ld	s1,40(sp)
    80003c54:	7902                	ld	s2,32(sp)
    80003c56:	69e2                	ld	s3,24(sp)
    80003c58:	6a42                	ld	s4,16(sp)
    80003c5a:	6121                	addi	sp,sp,64
    80003c5c:	8082                	ret

0000000080003c5e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c5e:	711d                	addi	sp,sp,-96
    80003c60:	ec86                	sd	ra,88(sp)
    80003c62:	e8a2                	sd	s0,80(sp)
    80003c64:	e4a6                	sd	s1,72(sp)
    80003c66:	e0ca                	sd	s2,64(sp)
    80003c68:	fc4e                	sd	s3,56(sp)
    80003c6a:	f852                	sd	s4,48(sp)
    80003c6c:	f456                	sd	s5,40(sp)
    80003c6e:	f05a                	sd	s6,32(sp)
    80003c70:	ec5e                	sd	s7,24(sp)
    80003c72:	e862                	sd	s8,16(sp)
    80003c74:	e466                	sd	s9,8(sp)
    80003c76:	1080                	addi	s0,sp,96
    80003c78:	84aa                	mv	s1,a0
    80003c7a:	8b2e                	mv	s6,a1
    80003c7c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c7e:	00054703          	lbu	a4,0(a0)
    80003c82:	02f00793          	li	a5,47
    80003c86:	02f70363          	beq	a4,a5,80003cac <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c8a:	ffffe097          	auipc	ra,0xffffe
    80003c8e:	e22080e7          	jalr	-478(ra) # 80001aac <myproc>
    80003c92:	15053503          	ld	a0,336(a0)
    80003c96:	00000097          	auipc	ra,0x0
    80003c9a:	9f6080e7          	jalr	-1546(ra) # 8000368c <idup>
    80003c9e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ca0:	02f00913          	li	s2,47
  len = path - s;
    80003ca4:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003ca6:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ca8:	4c05                	li	s8,1
    80003caa:	a865                	j	80003d62 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003cac:	4585                	li	a1,1
    80003cae:	4505                	li	a0,1
    80003cb0:	fffff097          	auipc	ra,0xfffff
    80003cb4:	6e6080e7          	jalr	1766(ra) # 80003396 <iget>
    80003cb8:	89aa                	mv	s3,a0
    80003cba:	b7dd                	j	80003ca0 <namex+0x42>
      iunlockput(ip);
    80003cbc:	854e                	mv	a0,s3
    80003cbe:	00000097          	auipc	ra,0x0
    80003cc2:	c6e080e7          	jalr	-914(ra) # 8000392c <iunlockput>
      return 0;
    80003cc6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003cc8:	854e                	mv	a0,s3
    80003cca:	60e6                	ld	ra,88(sp)
    80003ccc:	6446                	ld	s0,80(sp)
    80003cce:	64a6                	ld	s1,72(sp)
    80003cd0:	6906                	ld	s2,64(sp)
    80003cd2:	79e2                	ld	s3,56(sp)
    80003cd4:	7a42                	ld	s4,48(sp)
    80003cd6:	7aa2                	ld	s5,40(sp)
    80003cd8:	7b02                	ld	s6,32(sp)
    80003cda:	6be2                	ld	s7,24(sp)
    80003cdc:	6c42                	ld	s8,16(sp)
    80003cde:	6ca2                	ld	s9,8(sp)
    80003ce0:	6125                	addi	sp,sp,96
    80003ce2:	8082                	ret
      iunlock(ip);
    80003ce4:	854e                	mv	a0,s3
    80003ce6:	00000097          	auipc	ra,0x0
    80003cea:	aa6080e7          	jalr	-1370(ra) # 8000378c <iunlock>
      return ip;
    80003cee:	bfe9                	j	80003cc8 <namex+0x6a>
      iunlockput(ip);
    80003cf0:	854e                	mv	a0,s3
    80003cf2:	00000097          	auipc	ra,0x0
    80003cf6:	c3a080e7          	jalr	-966(ra) # 8000392c <iunlockput>
      return 0;
    80003cfa:	89d2                	mv	s3,s4
    80003cfc:	b7f1                	j	80003cc8 <namex+0x6a>
  len = path - s;
    80003cfe:	40b48633          	sub	a2,s1,a1
    80003d02:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d06:	094cd463          	bge	s9,s4,80003d8e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d0a:	4639                	li	a2,14
    80003d0c:	8556                	mv	a0,s5
    80003d0e:	ffffd097          	auipc	ra,0xffffd
    80003d12:	12e080e7          	jalr	302(ra) # 80000e3c <memmove>
  while(*path == '/')
    80003d16:	0004c783          	lbu	a5,0(s1)
    80003d1a:	01279763          	bne	a5,s2,80003d28 <namex+0xca>
    path++;
    80003d1e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d20:	0004c783          	lbu	a5,0(s1)
    80003d24:	ff278de3          	beq	a5,s2,80003d1e <namex+0xc0>
    ilock(ip);
    80003d28:	854e                	mv	a0,s3
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	9a0080e7          	jalr	-1632(ra) # 800036ca <ilock>
    if(ip->type != T_DIR){
    80003d32:	04499783          	lh	a5,68(s3)
    80003d36:	f98793e3          	bne	a5,s8,80003cbc <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d3a:	000b0563          	beqz	s6,80003d44 <namex+0xe6>
    80003d3e:	0004c783          	lbu	a5,0(s1)
    80003d42:	d3cd                	beqz	a5,80003ce4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d44:	865e                	mv	a2,s7
    80003d46:	85d6                	mv	a1,s5
    80003d48:	854e                	mv	a0,s3
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	e64080e7          	jalr	-412(ra) # 80003bae <dirlookup>
    80003d52:	8a2a                	mv	s4,a0
    80003d54:	dd51                	beqz	a0,80003cf0 <namex+0x92>
    iunlockput(ip);
    80003d56:	854e                	mv	a0,s3
    80003d58:	00000097          	auipc	ra,0x0
    80003d5c:	bd4080e7          	jalr	-1068(ra) # 8000392c <iunlockput>
    ip = next;
    80003d60:	89d2                	mv	s3,s4
  while(*path == '/')
    80003d62:	0004c783          	lbu	a5,0(s1)
    80003d66:	05279763          	bne	a5,s2,80003db4 <namex+0x156>
    path++;
    80003d6a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d6c:	0004c783          	lbu	a5,0(s1)
    80003d70:	ff278de3          	beq	a5,s2,80003d6a <namex+0x10c>
  if(*path == 0)
    80003d74:	c79d                	beqz	a5,80003da2 <namex+0x144>
    path++;
    80003d76:	85a6                	mv	a1,s1
  len = path - s;
    80003d78:	8a5e                	mv	s4,s7
    80003d7a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d7c:	01278963          	beq	a5,s2,80003d8e <namex+0x130>
    80003d80:	dfbd                	beqz	a5,80003cfe <namex+0xa0>
    path++;
    80003d82:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d84:	0004c783          	lbu	a5,0(s1)
    80003d88:	ff279ce3          	bne	a5,s2,80003d80 <namex+0x122>
    80003d8c:	bf8d                	j	80003cfe <namex+0xa0>
    memmove(name, s, len);
    80003d8e:	2601                	sext.w	a2,a2
    80003d90:	8556                	mv	a0,s5
    80003d92:	ffffd097          	auipc	ra,0xffffd
    80003d96:	0aa080e7          	jalr	170(ra) # 80000e3c <memmove>
    name[len] = 0;
    80003d9a:	9a56                	add	s4,s4,s5
    80003d9c:	000a0023          	sb	zero,0(s4)
    80003da0:	bf9d                	j	80003d16 <namex+0xb8>
  if(nameiparent){
    80003da2:	f20b03e3          	beqz	s6,80003cc8 <namex+0x6a>
    iput(ip);
    80003da6:	854e                	mv	a0,s3
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	adc080e7          	jalr	-1316(ra) # 80003884 <iput>
    return 0;
    80003db0:	4981                	li	s3,0
    80003db2:	bf19                	j	80003cc8 <namex+0x6a>
  if(*path == 0)
    80003db4:	d7fd                	beqz	a5,80003da2 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003db6:	0004c783          	lbu	a5,0(s1)
    80003dba:	85a6                	mv	a1,s1
    80003dbc:	b7d1                	j	80003d80 <namex+0x122>

0000000080003dbe <dirlink>:
{
    80003dbe:	7139                	addi	sp,sp,-64
    80003dc0:	fc06                	sd	ra,56(sp)
    80003dc2:	f822                	sd	s0,48(sp)
    80003dc4:	f426                	sd	s1,40(sp)
    80003dc6:	f04a                	sd	s2,32(sp)
    80003dc8:	ec4e                	sd	s3,24(sp)
    80003dca:	e852                	sd	s4,16(sp)
    80003dcc:	0080                	addi	s0,sp,64
    80003dce:	892a                	mv	s2,a0
    80003dd0:	8a2e                	mv	s4,a1
    80003dd2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003dd4:	4601                	li	a2,0
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	dd8080e7          	jalr	-552(ra) # 80003bae <dirlookup>
    80003dde:	e93d                	bnez	a0,80003e54 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de0:	04c92483          	lw	s1,76(s2)
    80003de4:	c49d                	beqz	s1,80003e12 <dirlink+0x54>
    80003de6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003de8:	4741                	li	a4,16
    80003dea:	86a6                	mv	a3,s1
    80003dec:	fc040613          	addi	a2,s0,-64
    80003df0:	4581                	li	a1,0
    80003df2:	854a                	mv	a0,s2
    80003df4:	00000097          	auipc	ra,0x0
    80003df8:	b8a080e7          	jalr	-1142(ra) # 8000397e <readi>
    80003dfc:	47c1                	li	a5,16
    80003dfe:	06f51163          	bne	a0,a5,80003e60 <dirlink+0xa2>
    if(de.inum == 0)
    80003e02:	fc045783          	lhu	a5,-64(s0)
    80003e06:	c791                	beqz	a5,80003e12 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e08:	24c1                	addiw	s1,s1,16
    80003e0a:	04c92783          	lw	a5,76(s2)
    80003e0e:	fcf4ede3          	bltu	s1,a5,80003de8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e12:	4639                	li	a2,14
    80003e14:	85d2                	mv	a1,s4
    80003e16:	fc240513          	addi	a0,s0,-62
    80003e1a:	ffffd097          	auipc	ra,0xffffd
    80003e1e:	0d6080e7          	jalr	214(ra) # 80000ef0 <strncpy>
  de.inum = inum;
    80003e22:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e26:	4741                	li	a4,16
    80003e28:	86a6                	mv	a3,s1
    80003e2a:	fc040613          	addi	a2,s0,-64
    80003e2e:	4581                	li	a1,0
    80003e30:	854a                	mv	a0,s2
    80003e32:	00000097          	auipc	ra,0x0
    80003e36:	c44080e7          	jalr	-956(ra) # 80003a76 <writei>
    80003e3a:	872a                	mv	a4,a0
    80003e3c:	47c1                	li	a5,16
  return 0;
    80003e3e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e40:	02f71863          	bne	a4,a5,80003e70 <dirlink+0xb2>
}
    80003e44:	70e2                	ld	ra,56(sp)
    80003e46:	7442                	ld	s0,48(sp)
    80003e48:	74a2                	ld	s1,40(sp)
    80003e4a:	7902                	ld	s2,32(sp)
    80003e4c:	69e2                	ld	s3,24(sp)
    80003e4e:	6a42                	ld	s4,16(sp)
    80003e50:	6121                	addi	sp,sp,64
    80003e52:	8082                	ret
    iput(ip);
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	a30080e7          	jalr	-1488(ra) # 80003884 <iput>
    return -1;
    80003e5c:	557d                	li	a0,-1
    80003e5e:	b7dd                	j	80003e44 <dirlink+0x86>
      panic("dirlink read");
    80003e60:	00004517          	auipc	a0,0x4
    80003e64:	7b050513          	addi	a0,a0,1968 # 80008610 <syscalls+0x1c8>
    80003e68:	ffffc097          	auipc	ra,0xffffc
    80003e6c:	6d6080e7          	jalr	1750(ra) # 8000053e <panic>
    panic("dirlink");
    80003e70:	00005517          	auipc	a0,0x5
    80003e74:	8b050513          	addi	a0,a0,-1872 # 80008720 <syscalls+0x2d8>
    80003e78:	ffffc097          	auipc	ra,0xffffc
    80003e7c:	6c6080e7          	jalr	1734(ra) # 8000053e <panic>

0000000080003e80 <namei>:

struct inode*
namei(char *path)
{
    80003e80:	1101                	addi	sp,sp,-32
    80003e82:	ec06                	sd	ra,24(sp)
    80003e84:	e822                	sd	s0,16(sp)
    80003e86:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e88:	fe040613          	addi	a2,s0,-32
    80003e8c:	4581                	li	a1,0
    80003e8e:	00000097          	auipc	ra,0x0
    80003e92:	dd0080e7          	jalr	-560(ra) # 80003c5e <namex>
}
    80003e96:	60e2                	ld	ra,24(sp)
    80003e98:	6442                	ld	s0,16(sp)
    80003e9a:	6105                	addi	sp,sp,32
    80003e9c:	8082                	ret

0000000080003e9e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e9e:	1141                	addi	sp,sp,-16
    80003ea0:	e406                	sd	ra,8(sp)
    80003ea2:	e022                	sd	s0,0(sp)
    80003ea4:	0800                	addi	s0,sp,16
    80003ea6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ea8:	4585                	li	a1,1
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	db4080e7          	jalr	-588(ra) # 80003c5e <namex>
}
    80003eb2:	60a2                	ld	ra,8(sp)
    80003eb4:	6402                	ld	s0,0(sp)
    80003eb6:	0141                	addi	sp,sp,16
    80003eb8:	8082                	ret

0000000080003eba <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003eba:	1101                	addi	sp,sp,-32
    80003ebc:	ec06                	sd	ra,24(sp)
    80003ebe:	e822                	sd	s0,16(sp)
    80003ec0:	e426                	sd	s1,8(sp)
    80003ec2:	e04a                	sd	s2,0(sp)
    80003ec4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ec6:	0003d917          	auipc	s2,0x3d
    80003eca:	3aa90913          	addi	s2,s2,938 # 80041270 <log>
    80003ece:	01892583          	lw	a1,24(s2)
    80003ed2:	02892503          	lw	a0,40(s2)
    80003ed6:	fffff097          	auipc	ra,0xfffff
    80003eda:	ff2080e7          	jalr	-14(ra) # 80002ec8 <bread>
    80003ede:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003ee0:	02c92683          	lw	a3,44(s2)
    80003ee4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003ee6:	02d05763          	blez	a3,80003f14 <write_head+0x5a>
    80003eea:	0003d797          	auipc	a5,0x3d
    80003eee:	3b678793          	addi	a5,a5,950 # 800412a0 <log+0x30>
    80003ef2:	05c50713          	addi	a4,a0,92
    80003ef6:	36fd                	addiw	a3,a3,-1
    80003ef8:	1682                	slli	a3,a3,0x20
    80003efa:	9281                	srli	a3,a3,0x20
    80003efc:	068a                	slli	a3,a3,0x2
    80003efe:	0003d617          	auipc	a2,0x3d
    80003f02:	3a660613          	addi	a2,a2,934 # 800412a4 <log+0x34>
    80003f06:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f08:	4390                	lw	a2,0(a5)
    80003f0a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f0c:	0791                	addi	a5,a5,4
    80003f0e:	0711                	addi	a4,a4,4
    80003f10:	fed79ce3          	bne	a5,a3,80003f08 <write_head+0x4e>
  }
  bwrite(buf);
    80003f14:	8526                	mv	a0,s1
    80003f16:	fffff097          	auipc	ra,0xfffff
    80003f1a:	0a4080e7          	jalr	164(ra) # 80002fba <bwrite>
  brelse(buf);
    80003f1e:	8526                	mv	a0,s1
    80003f20:	fffff097          	auipc	ra,0xfffff
    80003f24:	0d8080e7          	jalr	216(ra) # 80002ff8 <brelse>
}
    80003f28:	60e2                	ld	ra,24(sp)
    80003f2a:	6442                	ld	s0,16(sp)
    80003f2c:	64a2                	ld	s1,8(sp)
    80003f2e:	6902                	ld	s2,0(sp)
    80003f30:	6105                	addi	sp,sp,32
    80003f32:	8082                	ret

0000000080003f34 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f34:	0003d797          	auipc	a5,0x3d
    80003f38:	3687a783          	lw	a5,872(a5) # 8004129c <log+0x2c>
    80003f3c:	0af05d63          	blez	a5,80003ff6 <install_trans+0xc2>
{
    80003f40:	7139                	addi	sp,sp,-64
    80003f42:	fc06                	sd	ra,56(sp)
    80003f44:	f822                	sd	s0,48(sp)
    80003f46:	f426                	sd	s1,40(sp)
    80003f48:	f04a                	sd	s2,32(sp)
    80003f4a:	ec4e                	sd	s3,24(sp)
    80003f4c:	e852                	sd	s4,16(sp)
    80003f4e:	e456                	sd	s5,8(sp)
    80003f50:	e05a                	sd	s6,0(sp)
    80003f52:	0080                	addi	s0,sp,64
    80003f54:	8b2a                	mv	s6,a0
    80003f56:	0003da97          	auipc	s5,0x3d
    80003f5a:	34aa8a93          	addi	s5,s5,842 # 800412a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f5e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f60:	0003d997          	auipc	s3,0x3d
    80003f64:	31098993          	addi	s3,s3,784 # 80041270 <log>
    80003f68:	a035                	j	80003f94 <install_trans+0x60>
      bunpin(dbuf);
    80003f6a:	8526                	mv	a0,s1
    80003f6c:	fffff097          	auipc	ra,0xfffff
    80003f70:	166080e7          	jalr	358(ra) # 800030d2 <bunpin>
    brelse(lbuf);
    80003f74:	854a                	mv	a0,s2
    80003f76:	fffff097          	auipc	ra,0xfffff
    80003f7a:	082080e7          	jalr	130(ra) # 80002ff8 <brelse>
    brelse(dbuf);
    80003f7e:	8526                	mv	a0,s1
    80003f80:	fffff097          	auipc	ra,0xfffff
    80003f84:	078080e7          	jalr	120(ra) # 80002ff8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f88:	2a05                	addiw	s4,s4,1
    80003f8a:	0a91                	addi	s5,s5,4
    80003f8c:	02c9a783          	lw	a5,44(s3)
    80003f90:	04fa5963          	bge	s4,a5,80003fe2 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f94:	0189a583          	lw	a1,24(s3)
    80003f98:	014585bb          	addw	a1,a1,s4
    80003f9c:	2585                	addiw	a1,a1,1
    80003f9e:	0289a503          	lw	a0,40(s3)
    80003fa2:	fffff097          	auipc	ra,0xfffff
    80003fa6:	f26080e7          	jalr	-218(ra) # 80002ec8 <bread>
    80003faa:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fac:	000aa583          	lw	a1,0(s5)
    80003fb0:	0289a503          	lw	a0,40(s3)
    80003fb4:	fffff097          	auipc	ra,0xfffff
    80003fb8:	f14080e7          	jalr	-236(ra) # 80002ec8 <bread>
    80003fbc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fbe:	40000613          	li	a2,1024
    80003fc2:	05890593          	addi	a1,s2,88
    80003fc6:	05850513          	addi	a0,a0,88
    80003fca:	ffffd097          	auipc	ra,0xffffd
    80003fce:	e72080e7          	jalr	-398(ra) # 80000e3c <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fd2:	8526                	mv	a0,s1
    80003fd4:	fffff097          	auipc	ra,0xfffff
    80003fd8:	fe6080e7          	jalr	-26(ra) # 80002fba <bwrite>
    if(recovering == 0)
    80003fdc:	f80b1ce3          	bnez	s6,80003f74 <install_trans+0x40>
    80003fe0:	b769                	j	80003f6a <install_trans+0x36>
}
    80003fe2:	70e2                	ld	ra,56(sp)
    80003fe4:	7442                	ld	s0,48(sp)
    80003fe6:	74a2                	ld	s1,40(sp)
    80003fe8:	7902                	ld	s2,32(sp)
    80003fea:	69e2                	ld	s3,24(sp)
    80003fec:	6a42                	ld	s4,16(sp)
    80003fee:	6aa2                	ld	s5,8(sp)
    80003ff0:	6b02                	ld	s6,0(sp)
    80003ff2:	6121                	addi	sp,sp,64
    80003ff4:	8082                	ret
    80003ff6:	8082                	ret

0000000080003ff8 <initlog>:
{
    80003ff8:	7179                	addi	sp,sp,-48
    80003ffa:	f406                	sd	ra,40(sp)
    80003ffc:	f022                	sd	s0,32(sp)
    80003ffe:	ec26                	sd	s1,24(sp)
    80004000:	e84a                	sd	s2,16(sp)
    80004002:	e44e                	sd	s3,8(sp)
    80004004:	1800                	addi	s0,sp,48
    80004006:	892a                	mv	s2,a0
    80004008:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000400a:	0003d497          	auipc	s1,0x3d
    8000400e:	26648493          	addi	s1,s1,614 # 80041270 <log>
    80004012:	00004597          	auipc	a1,0x4
    80004016:	60e58593          	addi	a1,a1,1550 # 80008620 <syscalls+0x1d8>
    8000401a:	8526                	mv	a0,s1
    8000401c:	ffffd097          	auipc	ra,0xffffd
    80004020:	c34080e7          	jalr	-972(ra) # 80000c50 <initlock>
  log.start = sb->logstart;
    80004024:	0149a583          	lw	a1,20(s3)
    80004028:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000402a:	0109a783          	lw	a5,16(s3)
    8000402e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004030:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004034:	854a                	mv	a0,s2
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	e92080e7          	jalr	-366(ra) # 80002ec8 <bread>
  log.lh.n = lh->n;
    8000403e:	4d3c                	lw	a5,88(a0)
    80004040:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004042:	02f05563          	blez	a5,8000406c <initlog+0x74>
    80004046:	05c50713          	addi	a4,a0,92
    8000404a:	0003d697          	auipc	a3,0x3d
    8000404e:	25668693          	addi	a3,a3,598 # 800412a0 <log+0x30>
    80004052:	37fd                	addiw	a5,a5,-1
    80004054:	1782                	slli	a5,a5,0x20
    80004056:	9381                	srli	a5,a5,0x20
    80004058:	078a                	slli	a5,a5,0x2
    8000405a:	06050613          	addi	a2,a0,96
    8000405e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004060:	4310                	lw	a2,0(a4)
    80004062:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004064:	0711                	addi	a4,a4,4
    80004066:	0691                	addi	a3,a3,4
    80004068:	fef71ce3          	bne	a4,a5,80004060 <initlog+0x68>
  brelse(buf);
    8000406c:	fffff097          	auipc	ra,0xfffff
    80004070:	f8c080e7          	jalr	-116(ra) # 80002ff8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004074:	4505                	li	a0,1
    80004076:	00000097          	auipc	ra,0x0
    8000407a:	ebe080e7          	jalr	-322(ra) # 80003f34 <install_trans>
  log.lh.n = 0;
    8000407e:	0003d797          	auipc	a5,0x3d
    80004082:	2007af23          	sw	zero,542(a5) # 8004129c <log+0x2c>
  write_head(); // clear the log
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	e34080e7          	jalr	-460(ra) # 80003eba <write_head>
}
    8000408e:	70a2                	ld	ra,40(sp)
    80004090:	7402                	ld	s0,32(sp)
    80004092:	64e2                	ld	s1,24(sp)
    80004094:	6942                	ld	s2,16(sp)
    80004096:	69a2                	ld	s3,8(sp)
    80004098:	6145                	addi	sp,sp,48
    8000409a:	8082                	ret

000000008000409c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000409c:	1101                	addi	sp,sp,-32
    8000409e:	ec06                	sd	ra,24(sp)
    800040a0:	e822                	sd	s0,16(sp)
    800040a2:	e426                	sd	s1,8(sp)
    800040a4:	e04a                	sd	s2,0(sp)
    800040a6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040a8:	0003d517          	auipc	a0,0x3d
    800040ac:	1c850513          	addi	a0,a0,456 # 80041270 <log>
    800040b0:	ffffd097          	auipc	ra,0xffffd
    800040b4:	c30080e7          	jalr	-976(ra) # 80000ce0 <acquire>
  while(1){
    if(log.committing){
    800040b8:	0003d497          	auipc	s1,0x3d
    800040bc:	1b848493          	addi	s1,s1,440 # 80041270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040c0:	4979                	li	s2,30
    800040c2:	a039                	j	800040d0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040c4:	85a6                	mv	a1,s1
    800040c6:	8526                	mv	a0,s1
    800040c8:	ffffe097          	auipc	ra,0xffffe
    800040cc:	0a0080e7          	jalr	160(ra) # 80002168 <sleep>
    if(log.committing){
    800040d0:	50dc                	lw	a5,36(s1)
    800040d2:	fbed                	bnez	a5,800040c4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040d4:	509c                	lw	a5,32(s1)
    800040d6:	0017871b          	addiw	a4,a5,1
    800040da:	0007069b          	sext.w	a3,a4
    800040de:	0027179b          	slliw	a5,a4,0x2
    800040e2:	9fb9                	addw	a5,a5,a4
    800040e4:	0017979b          	slliw	a5,a5,0x1
    800040e8:	54d8                	lw	a4,44(s1)
    800040ea:	9fb9                	addw	a5,a5,a4
    800040ec:	00f95963          	bge	s2,a5,800040fe <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040f0:	85a6                	mv	a1,s1
    800040f2:	8526                	mv	a0,s1
    800040f4:	ffffe097          	auipc	ra,0xffffe
    800040f8:	074080e7          	jalr	116(ra) # 80002168 <sleep>
    800040fc:	bfd1                	j	800040d0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040fe:	0003d517          	auipc	a0,0x3d
    80004102:	17250513          	addi	a0,a0,370 # 80041270 <log>
    80004106:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004108:	ffffd097          	auipc	ra,0xffffd
    8000410c:	c8c080e7          	jalr	-884(ra) # 80000d94 <release>
      break;
    }
  }
}
    80004110:	60e2                	ld	ra,24(sp)
    80004112:	6442                	ld	s0,16(sp)
    80004114:	64a2                	ld	s1,8(sp)
    80004116:	6902                	ld	s2,0(sp)
    80004118:	6105                	addi	sp,sp,32
    8000411a:	8082                	ret

000000008000411c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000411c:	7139                	addi	sp,sp,-64
    8000411e:	fc06                	sd	ra,56(sp)
    80004120:	f822                	sd	s0,48(sp)
    80004122:	f426                	sd	s1,40(sp)
    80004124:	f04a                	sd	s2,32(sp)
    80004126:	ec4e                	sd	s3,24(sp)
    80004128:	e852                	sd	s4,16(sp)
    8000412a:	e456                	sd	s5,8(sp)
    8000412c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000412e:	0003d497          	auipc	s1,0x3d
    80004132:	14248493          	addi	s1,s1,322 # 80041270 <log>
    80004136:	8526                	mv	a0,s1
    80004138:	ffffd097          	auipc	ra,0xffffd
    8000413c:	ba8080e7          	jalr	-1112(ra) # 80000ce0 <acquire>
  log.outstanding -= 1;
    80004140:	509c                	lw	a5,32(s1)
    80004142:	37fd                	addiw	a5,a5,-1
    80004144:	0007891b          	sext.w	s2,a5
    80004148:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000414a:	50dc                	lw	a5,36(s1)
    8000414c:	efb9                	bnez	a5,800041aa <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000414e:	06091663          	bnez	s2,800041ba <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004152:	0003d497          	auipc	s1,0x3d
    80004156:	11e48493          	addi	s1,s1,286 # 80041270 <log>
    8000415a:	4785                	li	a5,1
    8000415c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000415e:	8526                	mv	a0,s1
    80004160:	ffffd097          	auipc	ra,0xffffd
    80004164:	c34080e7          	jalr	-972(ra) # 80000d94 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004168:	54dc                	lw	a5,44(s1)
    8000416a:	06f04763          	bgtz	a5,800041d8 <end_op+0xbc>
    acquire(&log.lock);
    8000416e:	0003d497          	auipc	s1,0x3d
    80004172:	10248493          	addi	s1,s1,258 # 80041270 <log>
    80004176:	8526                	mv	a0,s1
    80004178:	ffffd097          	auipc	ra,0xffffd
    8000417c:	b68080e7          	jalr	-1176(ra) # 80000ce0 <acquire>
    log.committing = 0;
    80004180:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004184:	8526                	mv	a0,s1
    80004186:	ffffe097          	auipc	ra,0xffffe
    8000418a:	16e080e7          	jalr	366(ra) # 800022f4 <wakeup>
    release(&log.lock);
    8000418e:	8526                	mv	a0,s1
    80004190:	ffffd097          	auipc	ra,0xffffd
    80004194:	c04080e7          	jalr	-1020(ra) # 80000d94 <release>
}
    80004198:	70e2                	ld	ra,56(sp)
    8000419a:	7442                	ld	s0,48(sp)
    8000419c:	74a2                	ld	s1,40(sp)
    8000419e:	7902                	ld	s2,32(sp)
    800041a0:	69e2                	ld	s3,24(sp)
    800041a2:	6a42                	ld	s4,16(sp)
    800041a4:	6aa2                	ld	s5,8(sp)
    800041a6:	6121                	addi	sp,sp,64
    800041a8:	8082                	ret
    panic("log.committing");
    800041aa:	00004517          	auipc	a0,0x4
    800041ae:	47e50513          	addi	a0,a0,1150 # 80008628 <syscalls+0x1e0>
    800041b2:	ffffc097          	auipc	ra,0xffffc
    800041b6:	38c080e7          	jalr	908(ra) # 8000053e <panic>
    wakeup(&log);
    800041ba:	0003d497          	auipc	s1,0x3d
    800041be:	0b648493          	addi	s1,s1,182 # 80041270 <log>
    800041c2:	8526                	mv	a0,s1
    800041c4:	ffffe097          	auipc	ra,0xffffe
    800041c8:	130080e7          	jalr	304(ra) # 800022f4 <wakeup>
  release(&log.lock);
    800041cc:	8526                	mv	a0,s1
    800041ce:	ffffd097          	auipc	ra,0xffffd
    800041d2:	bc6080e7          	jalr	-1082(ra) # 80000d94 <release>
  if(do_commit){
    800041d6:	b7c9                	j	80004198 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041d8:	0003da97          	auipc	s5,0x3d
    800041dc:	0c8a8a93          	addi	s5,s5,200 # 800412a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041e0:	0003da17          	auipc	s4,0x3d
    800041e4:	090a0a13          	addi	s4,s4,144 # 80041270 <log>
    800041e8:	018a2583          	lw	a1,24(s4)
    800041ec:	012585bb          	addw	a1,a1,s2
    800041f0:	2585                	addiw	a1,a1,1
    800041f2:	028a2503          	lw	a0,40(s4)
    800041f6:	fffff097          	auipc	ra,0xfffff
    800041fa:	cd2080e7          	jalr	-814(ra) # 80002ec8 <bread>
    800041fe:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004200:	000aa583          	lw	a1,0(s5)
    80004204:	028a2503          	lw	a0,40(s4)
    80004208:	fffff097          	auipc	ra,0xfffff
    8000420c:	cc0080e7          	jalr	-832(ra) # 80002ec8 <bread>
    80004210:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004212:	40000613          	li	a2,1024
    80004216:	05850593          	addi	a1,a0,88
    8000421a:	05848513          	addi	a0,s1,88
    8000421e:	ffffd097          	auipc	ra,0xffffd
    80004222:	c1e080e7          	jalr	-994(ra) # 80000e3c <memmove>
    bwrite(to);  // write the log
    80004226:	8526                	mv	a0,s1
    80004228:	fffff097          	auipc	ra,0xfffff
    8000422c:	d92080e7          	jalr	-622(ra) # 80002fba <bwrite>
    brelse(from);
    80004230:	854e                	mv	a0,s3
    80004232:	fffff097          	auipc	ra,0xfffff
    80004236:	dc6080e7          	jalr	-570(ra) # 80002ff8 <brelse>
    brelse(to);
    8000423a:	8526                	mv	a0,s1
    8000423c:	fffff097          	auipc	ra,0xfffff
    80004240:	dbc080e7          	jalr	-580(ra) # 80002ff8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004244:	2905                	addiw	s2,s2,1
    80004246:	0a91                	addi	s5,s5,4
    80004248:	02ca2783          	lw	a5,44(s4)
    8000424c:	f8f94ee3          	blt	s2,a5,800041e8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004250:	00000097          	auipc	ra,0x0
    80004254:	c6a080e7          	jalr	-918(ra) # 80003eba <write_head>
    install_trans(0); // Now install writes to home locations
    80004258:	4501                	li	a0,0
    8000425a:	00000097          	auipc	ra,0x0
    8000425e:	cda080e7          	jalr	-806(ra) # 80003f34 <install_trans>
    log.lh.n = 0;
    80004262:	0003d797          	auipc	a5,0x3d
    80004266:	0207ad23          	sw	zero,58(a5) # 8004129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000426a:	00000097          	auipc	ra,0x0
    8000426e:	c50080e7          	jalr	-944(ra) # 80003eba <write_head>
    80004272:	bdf5                	j	8000416e <end_op+0x52>

0000000080004274 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004274:	1101                	addi	sp,sp,-32
    80004276:	ec06                	sd	ra,24(sp)
    80004278:	e822                	sd	s0,16(sp)
    8000427a:	e426                	sd	s1,8(sp)
    8000427c:	e04a                	sd	s2,0(sp)
    8000427e:	1000                	addi	s0,sp,32
    80004280:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004282:	0003d917          	auipc	s2,0x3d
    80004286:	fee90913          	addi	s2,s2,-18 # 80041270 <log>
    8000428a:	854a                	mv	a0,s2
    8000428c:	ffffd097          	auipc	ra,0xffffd
    80004290:	a54080e7          	jalr	-1452(ra) # 80000ce0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004294:	02c92603          	lw	a2,44(s2)
    80004298:	47f5                	li	a5,29
    8000429a:	06c7c563          	blt	a5,a2,80004304 <log_write+0x90>
    8000429e:	0003d797          	auipc	a5,0x3d
    800042a2:	fee7a783          	lw	a5,-18(a5) # 8004128c <log+0x1c>
    800042a6:	37fd                	addiw	a5,a5,-1
    800042a8:	04f65e63          	bge	a2,a5,80004304 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042ac:	0003d797          	auipc	a5,0x3d
    800042b0:	fe47a783          	lw	a5,-28(a5) # 80041290 <log+0x20>
    800042b4:	06f05063          	blez	a5,80004314 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042b8:	4781                	li	a5,0
    800042ba:	06c05563          	blez	a2,80004324 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042be:	44cc                	lw	a1,12(s1)
    800042c0:	0003d717          	auipc	a4,0x3d
    800042c4:	fe070713          	addi	a4,a4,-32 # 800412a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042c8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042ca:	4314                	lw	a3,0(a4)
    800042cc:	04b68c63          	beq	a3,a1,80004324 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042d0:	2785                	addiw	a5,a5,1
    800042d2:	0711                	addi	a4,a4,4
    800042d4:	fef61be3          	bne	a2,a5,800042ca <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042d8:	0621                	addi	a2,a2,8
    800042da:	060a                	slli	a2,a2,0x2
    800042dc:	0003d797          	auipc	a5,0x3d
    800042e0:	f9478793          	addi	a5,a5,-108 # 80041270 <log>
    800042e4:	963e                	add	a2,a2,a5
    800042e6:	44dc                	lw	a5,12(s1)
    800042e8:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042ea:	8526                	mv	a0,s1
    800042ec:	fffff097          	auipc	ra,0xfffff
    800042f0:	daa080e7          	jalr	-598(ra) # 80003096 <bpin>
    log.lh.n++;
    800042f4:	0003d717          	auipc	a4,0x3d
    800042f8:	f7c70713          	addi	a4,a4,-132 # 80041270 <log>
    800042fc:	575c                	lw	a5,44(a4)
    800042fe:	2785                	addiw	a5,a5,1
    80004300:	d75c                	sw	a5,44(a4)
    80004302:	a835                	j	8000433e <log_write+0xca>
    panic("too big a transaction");
    80004304:	00004517          	auipc	a0,0x4
    80004308:	33450513          	addi	a0,a0,820 # 80008638 <syscalls+0x1f0>
    8000430c:	ffffc097          	auipc	ra,0xffffc
    80004310:	232080e7          	jalr	562(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004314:	00004517          	auipc	a0,0x4
    80004318:	33c50513          	addi	a0,a0,828 # 80008650 <syscalls+0x208>
    8000431c:	ffffc097          	auipc	ra,0xffffc
    80004320:	222080e7          	jalr	546(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004324:	00878713          	addi	a4,a5,8
    80004328:	00271693          	slli	a3,a4,0x2
    8000432c:	0003d717          	auipc	a4,0x3d
    80004330:	f4470713          	addi	a4,a4,-188 # 80041270 <log>
    80004334:	9736                	add	a4,a4,a3
    80004336:	44d4                	lw	a3,12(s1)
    80004338:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000433a:	faf608e3          	beq	a2,a5,800042ea <log_write+0x76>
  }
  release(&log.lock);
    8000433e:	0003d517          	auipc	a0,0x3d
    80004342:	f3250513          	addi	a0,a0,-206 # 80041270 <log>
    80004346:	ffffd097          	auipc	ra,0xffffd
    8000434a:	a4e080e7          	jalr	-1458(ra) # 80000d94 <release>
}
    8000434e:	60e2                	ld	ra,24(sp)
    80004350:	6442                	ld	s0,16(sp)
    80004352:	64a2                	ld	s1,8(sp)
    80004354:	6902                	ld	s2,0(sp)
    80004356:	6105                	addi	sp,sp,32
    80004358:	8082                	ret

000000008000435a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000435a:	1101                	addi	sp,sp,-32
    8000435c:	ec06                	sd	ra,24(sp)
    8000435e:	e822                	sd	s0,16(sp)
    80004360:	e426                	sd	s1,8(sp)
    80004362:	e04a                	sd	s2,0(sp)
    80004364:	1000                	addi	s0,sp,32
    80004366:	84aa                	mv	s1,a0
    80004368:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000436a:	00004597          	auipc	a1,0x4
    8000436e:	30658593          	addi	a1,a1,774 # 80008670 <syscalls+0x228>
    80004372:	0521                	addi	a0,a0,8
    80004374:	ffffd097          	auipc	ra,0xffffd
    80004378:	8dc080e7          	jalr	-1828(ra) # 80000c50 <initlock>
  lk->name = name;
    8000437c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004380:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004384:	0204a423          	sw	zero,40(s1)
}
    80004388:	60e2                	ld	ra,24(sp)
    8000438a:	6442                	ld	s0,16(sp)
    8000438c:	64a2                	ld	s1,8(sp)
    8000438e:	6902                	ld	s2,0(sp)
    80004390:	6105                	addi	sp,sp,32
    80004392:	8082                	ret

0000000080004394 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004394:	1101                	addi	sp,sp,-32
    80004396:	ec06                	sd	ra,24(sp)
    80004398:	e822                	sd	s0,16(sp)
    8000439a:	e426                	sd	s1,8(sp)
    8000439c:	e04a                	sd	s2,0(sp)
    8000439e:	1000                	addi	s0,sp,32
    800043a0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043a2:	00850913          	addi	s2,a0,8
    800043a6:	854a                	mv	a0,s2
    800043a8:	ffffd097          	auipc	ra,0xffffd
    800043ac:	938080e7          	jalr	-1736(ra) # 80000ce0 <acquire>
  while (lk->locked) {
    800043b0:	409c                	lw	a5,0(s1)
    800043b2:	cb89                	beqz	a5,800043c4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043b4:	85ca                	mv	a1,s2
    800043b6:	8526                	mv	a0,s1
    800043b8:	ffffe097          	auipc	ra,0xffffe
    800043bc:	db0080e7          	jalr	-592(ra) # 80002168 <sleep>
  while (lk->locked) {
    800043c0:	409c                	lw	a5,0(s1)
    800043c2:	fbed                	bnez	a5,800043b4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043c4:	4785                	li	a5,1
    800043c6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043c8:	ffffd097          	auipc	ra,0xffffd
    800043cc:	6e4080e7          	jalr	1764(ra) # 80001aac <myproc>
    800043d0:	591c                	lw	a5,48(a0)
    800043d2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043d4:	854a                	mv	a0,s2
    800043d6:	ffffd097          	auipc	ra,0xffffd
    800043da:	9be080e7          	jalr	-1602(ra) # 80000d94 <release>
}
    800043de:	60e2                	ld	ra,24(sp)
    800043e0:	6442                	ld	s0,16(sp)
    800043e2:	64a2                	ld	s1,8(sp)
    800043e4:	6902                	ld	s2,0(sp)
    800043e6:	6105                	addi	sp,sp,32
    800043e8:	8082                	ret

00000000800043ea <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043ea:	1101                	addi	sp,sp,-32
    800043ec:	ec06                	sd	ra,24(sp)
    800043ee:	e822                	sd	s0,16(sp)
    800043f0:	e426                	sd	s1,8(sp)
    800043f2:	e04a                	sd	s2,0(sp)
    800043f4:	1000                	addi	s0,sp,32
    800043f6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043f8:	00850913          	addi	s2,a0,8
    800043fc:	854a                	mv	a0,s2
    800043fe:	ffffd097          	auipc	ra,0xffffd
    80004402:	8e2080e7          	jalr	-1822(ra) # 80000ce0 <acquire>
  lk->locked = 0;
    80004406:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000440a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000440e:	8526                	mv	a0,s1
    80004410:	ffffe097          	auipc	ra,0xffffe
    80004414:	ee4080e7          	jalr	-284(ra) # 800022f4 <wakeup>
  release(&lk->lk);
    80004418:	854a                	mv	a0,s2
    8000441a:	ffffd097          	auipc	ra,0xffffd
    8000441e:	97a080e7          	jalr	-1670(ra) # 80000d94 <release>
}
    80004422:	60e2                	ld	ra,24(sp)
    80004424:	6442                	ld	s0,16(sp)
    80004426:	64a2                	ld	s1,8(sp)
    80004428:	6902                	ld	s2,0(sp)
    8000442a:	6105                	addi	sp,sp,32
    8000442c:	8082                	ret

000000008000442e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000442e:	7179                	addi	sp,sp,-48
    80004430:	f406                	sd	ra,40(sp)
    80004432:	f022                	sd	s0,32(sp)
    80004434:	ec26                	sd	s1,24(sp)
    80004436:	e84a                	sd	s2,16(sp)
    80004438:	e44e                	sd	s3,8(sp)
    8000443a:	1800                	addi	s0,sp,48
    8000443c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000443e:	00850913          	addi	s2,a0,8
    80004442:	854a                	mv	a0,s2
    80004444:	ffffd097          	auipc	ra,0xffffd
    80004448:	89c080e7          	jalr	-1892(ra) # 80000ce0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000444c:	409c                	lw	a5,0(s1)
    8000444e:	ef99                	bnez	a5,8000446c <holdingsleep+0x3e>
    80004450:	4481                	li	s1,0
  release(&lk->lk);
    80004452:	854a                	mv	a0,s2
    80004454:	ffffd097          	auipc	ra,0xffffd
    80004458:	940080e7          	jalr	-1728(ra) # 80000d94 <release>
  return r;
}
    8000445c:	8526                	mv	a0,s1
    8000445e:	70a2                	ld	ra,40(sp)
    80004460:	7402                	ld	s0,32(sp)
    80004462:	64e2                	ld	s1,24(sp)
    80004464:	6942                	ld	s2,16(sp)
    80004466:	69a2                	ld	s3,8(sp)
    80004468:	6145                	addi	sp,sp,48
    8000446a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000446c:	0284a983          	lw	s3,40(s1)
    80004470:	ffffd097          	auipc	ra,0xffffd
    80004474:	63c080e7          	jalr	1596(ra) # 80001aac <myproc>
    80004478:	5904                	lw	s1,48(a0)
    8000447a:	413484b3          	sub	s1,s1,s3
    8000447e:	0014b493          	seqz	s1,s1
    80004482:	bfc1                	j	80004452 <holdingsleep+0x24>

0000000080004484 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004484:	1141                	addi	sp,sp,-16
    80004486:	e406                	sd	ra,8(sp)
    80004488:	e022                	sd	s0,0(sp)
    8000448a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000448c:	00004597          	auipc	a1,0x4
    80004490:	1f458593          	addi	a1,a1,500 # 80008680 <syscalls+0x238>
    80004494:	0003d517          	auipc	a0,0x3d
    80004498:	f2450513          	addi	a0,a0,-220 # 800413b8 <ftable>
    8000449c:	ffffc097          	auipc	ra,0xffffc
    800044a0:	7b4080e7          	jalr	1972(ra) # 80000c50 <initlock>
}
    800044a4:	60a2                	ld	ra,8(sp)
    800044a6:	6402                	ld	s0,0(sp)
    800044a8:	0141                	addi	sp,sp,16
    800044aa:	8082                	ret

00000000800044ac <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044ac:	1101                	addi	sp,sp,-32
    800044ae:	ec06                	sd	ra,24(sp)
    800044b0:	e822                	sd	s0,16(sp)
    800044b2:	e426                	sd	s1,8(sp)
    800044b4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044b6:	0003d517          	auipc	a0,0x3d
    800044ba:	f0250513          	addi	a0,a0,-254 # 800413b8 <ftable>
    800044be:	ffffd097          	auipc	ra,0xffffd
    800044c2:	822080e7          	jalr	-2014(ra) # 80000ce0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044c6:	0003d497          	auipc	s1,0x3d
    800044ca:	f0a48493          	addi	s1,s1,-246 # 800413d0 <ftable+0x18>
    800044ce:	0003e717          	auipc	a4,0x3e
    800044d2:	ea270713          	addi	a4,a4,-350 # 80042370 <ftable+0xfb8>
    if(f->ref == 0){
    800044d6:	40dc                	lw	a5,4(s1)
    800044d8:	cf99                	beqz	a5,800044f6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044da:	02848493          	addi	s1,s1,40
    800044de:	fee49ce3          	bne	s1,a4,800044d6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044e2:	0003d517          	auipc	a0,0x3d
    800044e6:	ed650513          	addi	a0,a0,-298 # 800413b8 <ftable>
    800044ea:	ffffd097          	auipc	ra,0xffffd
    800044ee:	8aa080e7          	jalr	-1878(ra) # 80000d94 <release>
  return 0;
    800044f2:	4481                	li	s1,0
    800044f4:	a819                	j	8000450a <filealloc+0x5e>
      f->ref = 1;
    800044f6:	4785                	li	a5,1
    800044f8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044fa:	0003d517          	auipc	a0,0x3d
    800044fe:	ebe50513          	addi	a0,a0,-322 # 800413b8 <ftable>
    80004502:	ffffd097          	auipc	ra,0xffffd
    80004506:	892080e7          	jalr	-1902(ra) # 80000d94 <release>
}
    8000450a:	8526                	mv	a0,s1
    8000450c:	60e2                	ld	ra,24(sp)
    8000450e:	6442                	ld	s0,16(sp)
    80004510:	64a2                	ld	s1,8(sp)
    80004512:	6105                	addi	sp,sp,32
    80004514:	8082                	ret

0000000080004516 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004516:	1101                	addi	sp,sp,-32
    80004518:	ec06                	sd	ra,24(sp)
    8000451a:	e822                	sd	s0,16(sp)
    8000451c:	e426                	sd	s1,8(sp)
    8000451e:	1000                	addi	s0,sp,32
    80004520:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004522:	0003d517          	auipc	a0,0x3d
    80004526:	e9650513          	addi	a0,a0,-362 # 800413b8 <ftable>
    8000452a:	ffffc097          	auipc	ra,0xffffc
    8000452e:	7b6080e7          	jalr	1974(ra) # 80000ce0 <acquire>
  if(f->ref < 1)
    80004532:	40dc                	lw	a5,4(s1)
    80004534:	02f05263          	blez	a5,80004558 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004538:	2785                	addiw	a5,a5,1
    8000453a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000453c:	0003d517          	auipc	a0,0x3d
    80004540:	e7c50513          	addi	a0,a0,-388 # 800413b8 <ftable>
    80004544:	ffffd097          	auipc	ra,0xffffd
    80004548:	850080e7          	jalr	-1968(ra) # 80000d94 <release>
  return f;
}
    8000454c:	8526                	mv	a0,s1
    8000454e:	60e2                	ld	ra,24(sp)
    80004550:	6442                	ld	s0,16(sp)
    80004552:	64a2                	ld	s1,8(sp)
    80004554:	6105                	addi	sp,sp,32
    80004556:	8082                	ret
    panic("filedup");
    80004558:	00004517          	auipc	a0,0x4
    8000455c:	13050513          	addi	a0,a0,304 # 80008688 <syscalls+0x240>
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	fde080e7          	jalr	-34(ra) # 8000053e <panic>

0000000080004568 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004568:	7139                	addi	sp,sp,-64
    8000456a:	fc06                	sd	ra,56(sp)
    8000456c:	f822                	sd	s0,48(sp)
    8000456e:	f426                	sd	s1,40(sp)
    80004570:	f04a                	sd	s2,32(sp)
    80004572:	ec4e                	sd	s3,24(sp)
    80004574:	e852                	sd	s4,16(sp)
    80004576:	e456                	sd	s5,8(sp)
    80004578:	0080                	addi	s0,sp,64
    8000457a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000457c:	0003d517          	auipc	a0,0x3d
    80004580:	e3c50513          	addi	a0,a0,-452 # 800413b8 <ftable>
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	75c080e7          	jalr	1884(ra) # 80000ce0 <acquire>
  if(f->ref < 1)
    8000458c:	40dc                	lw	a5,4(s1)
    8000458e:	06f05163          	blez	a5,800045f0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004592:	37fd                	addiw	a5,a5,-1
    80004594:	0007871b          	sext.w	a4,a5
    80004598:	c0dc                	sw	a5,4(s1)
    8000459a:	06e04363          	bgtz	a4,80004600 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000459e:	0004a903          	lw	s2,0(s1)
    800045a2:	0094ca83          	lbu	s5,9(s1)
    800045a6:	0104ba03          	ld	s4,16(s1)
    800045aa:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045ae:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045b2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045b6:	0003d517          	auipc	a0,0x3d
    800045ba:	e0250513          	addi	a0,a0,-510 # 800413b8 <ftable>
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	7d6080e7          	jalr	2006(ra) # 80000d94 <release>

  if(ff.type == FD_PIPE){
    800045c6:	4785                	li	a5,1
    800045c8:	04f90d63          	beq	s2,a5,80004622 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045cc:	3979                	addiw	s2,s2,-2
    800045ce:	4785                	li	a5,1
    800045d0:	0527e063          	bltu	a5,s2,80004610 <fileclose+0xa8>
    begin_op();
    800045d4:	00000097          	auipc	ra,0x0
    800045d8:	ac8080e7          	jalr	-1336(ra) # 8000409c <begin_op>
    iput(ff.ip);
    800045dc:	854e                	mv	a0,s3
    800045de:	fffff097          	auipc	ra,0xfffff
    800045e2:	2a6080e7          	jalr	678(ra) # 80003884 <iput>
    end_op();
    800045e6:	00000097          	auipc	ra,0x0
    800045ea:	b36080e7          	jalr	-1226(ra) # 8000411c <end_op>
    800045ee:	a00d                	j	80004610 <fileclose+0xa8>
    panic("fileclose");
    800045f0:	00004517          	auipc	a0,0x4
    800045f4:	0a050513          	addi	a0,a0,160 # 80008690 <syscalls+0x248>
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004600:	0003d517          	auipc	a0,0x3d
    80004604:	db850513          	addi	a0,a0,-584 # 800413b8 <ftable>
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	78c080e7          	jalr	1932(ra) # 80000d94 <release>
  }
}
    80004610:	70e2                	ld	ra,56(sp)
    80004612:	7442                	ld	s0,48(sp)
    80004614:	74a2                	ld	s1,40(sp)
    80004616:	7902                	ld	s2,32(sp)
    80004618:	69e2                	ld	s3,24(sp)
    8000461a:	6a42                	ld	s4,16(sp)
    8000461c:	6aa2                	ld	s5,8(sp)
    8000461e:	6121                	addi	sp,sp,64
    80004620:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004622:	85d6                	mv	a1,s5
    80004624:	8552                	mv	a0,s4
    80004626:	00000097          	auipc	ra,0x0
    8000462a:	34c080e7          	jalr	844(ra) # 80004972 <pipeclose>
    8000462e:	b7cd                	j	80004610 <fileclose+0xa8>

0000000080004630 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004630:	715d                	addi	sp,sp,-80
    80004632:	e486                	sd	ra,72(sp)
    80004634:	e0a2                	sd	s0,64(sp)
    80004636:	fc26                	sd	s1,56(sp)
    80004638:	f84a                	sd	s2,48(sp)
    8000463a:	f44e                	sd	s3,40(sp)
    8000463c:	0880                	addi	s0,sp,80
    8000463e:	84aa                	mv	s1,a0
    80004640:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004642:	ffffd097          	auipc	ra,0xffffd
    80004646:	46a080e7          	jalr	1130(ra) # 80001aac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000464a:	409c                	lw	a5,0(s1)
    8000464c:	37f9                	addiw	a5,a5,-2
    8000464e:	4705                	li	a4,1
    80004650:	04f76763          	bltu	a4,a5,8000469e <filestat+0x6e>
    80004654:	892a                	mv	s2,a0
    ilock(f->ip);
    80004656:	6c88                	ld	a0,24(s1)
    80004658:	fffff097          	auipc	ra,0xfffff
    8000465c:	072080e7          	jalr	114(ra) # 800036ca <ilock>
    stati(f->ip, &st);
    80004660:	fb840593          	addi	a1,s0,-72
    80004664:	6c88                	ld	a0,24(s1)
    80004666:	fffff097          	auipc	ra,0xfffff
    8000466a:	2ee080e7          	jalr	750(ra) # 80003954 <stati>
    iunlock(f->ip);
    8000466e:	6c88                	ld	a0,24(s1)
    80004670:	fffff097          	auipc	ra,0xfffff
    80004674:	11c080e7          	jalr	284(ra) # 8000378c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004678:	46e1                	li	a3,24
    8000467a:	fb840613          	addi	a2,s0,-72
    8000467e:	85ce                	mv	a1,s3
    80004680:	05093503          	ld	a0,80(s2)
    80004684:	ffffd097          	auipc	ra,0xffffd
    80004688:	0ea080e7          	jalr	234(ra) # 8000176e <copyout>
    8000468c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004690:	60a6                	ld	ra,72(sp)
    80004692:	6406                	ld	s0,64(sp)
    80004694:	74e2                	ld	s1,56(sp)
    80004696:	7942                	ld	s2,48(sp)
    80004698:	79a2                	ld	s3,40(sp)
    8000469a:	6161                	addi	sp,sp,80
    8000469c:	8082                	ret
  return -1;
    8000469e:	557d                	li	a0,-1
    800046a0:	bfc5                	j	80004690 <filestat+0x60>

00000000800046a2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046a2:	7179                	addi	sp,sp,-48
    800046a4:	f406                	sd	ra,40(sp)
    800046a6:	f022                	sd	s0,32(sp)
    800046a8:	ec26                	sd	s1,24(sp)
    800046aa:	e84a                	sd	s2,16(sp)
    800046ac:	e44e                	sd	s3,8(sp)
    800046ae:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046b0:	00854783          	lbu	a5,8(a0)
    800046b4:	c3d5                	beqz	a5,80004758 <fileread+0xb6>
    800046b6:	84aa                	mv	s1,a0
    800046b8:	89ae                	mv	s3,a1
    800046ba:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046bc:	411c                	lw	a5,0(a0)
    800046be:	4705                	li	a4,1
    800046c0:	04e78963          	beq	a5,a4,80004712 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046c4:	470d                	li	a4,3
    800046c6:	04e78d63          	beq	a5,a4,80004720 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046ca:	4709                	li	a4,2
    800046cc:	06e79e63          	bne	a5,a4,80004748 <fileread+0xa6>
    ilock(f->ip);
    800046d0:	6d08                	ld	a0,24(a0)
    800046d2:	fffff097          	auipc	ra,0xfffff
    800046d6:	ff8080e7          	jalr	-8(ra) # 800036ca <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046da:	874a                	mv	a4,s2
    800046dc:	5094                	lw	a3,32(s1)
    800046de:	864e                	mv	a2,s3
    800046e0:	4585                	li	a1,1
    800046e2:	6c88                	ld	a0,24(s1)
    800046e4:	fffff097          	auipc	ra,0xfffff
    800046e8:	29a080e7          	jalr	666(ra) # 8000397e <readi>
    800046ec:	892a                	mv	s2,a0
    800046ee:	00a05563          	blez	a0,800046f8 <fileread+0x56>
      f->off += r;
    800046f2:	509c                	lw	a5,32(s1)
    800046f4:	9fa9                	addw	a5,a5,a0
    800046f6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046f8:	6c88                	ld	a0,24(s1)
    800046fa:	fffff097          	auipc	ra,0xfffff
    800046fe:	092080e7          	jalr	146(ra) # 8000378c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004702:	854a                	mv	a0,s2
    80004704:	70a2                	ld	ra,40(sp)
    80004706:	7402                	ld	s0,32(sp)
    80004708:	64e2                	ld	s1,24(sp)
    8000470a:	6942                	ld	s2,16(sp)
    8000470c:	69a2                	ld	s3,8(sp)
    8000470e:	6145                	addi	sp,sp,48
    80004710:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004712:	6908                	ld	a0,16(a0)
    80004714:	00000097          	auipc	ra,0x0
    80004718:	3c8080e7          	jalr	968(ra) # 80004adc <piperead>
    8000471c:	892a                	mv	s2,a0
    8000471e:	b7d5                	j	80004702 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004720:	02451783          	lh	a5,36(a0)
    80004724:	03079693          	slli	a3,a5,0x30
    80004728:	92c1                	srli	a3,a3,0x30
    8000472a:	4725                	li	a4,9
    8000472c:	02d76863          	bltu	a4,a3,8000475c <fileread+0xba>
    80004730:	0792                	slli	a5,a5,0x4
    80004732:	0003d717          	auipc	a4,0x3d
    80004736:	be670713          	addi	a4,a4,-1050 # 80041318 <devsw>
    8000473a:	97ba                	add	a5,a5,a4
    8000473c:	639c                	ld	a5,0(a5)
    8000473e:	c38d                	beqz	a5,80004760 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004740:	4505                	li	a0,1
    80004742:	9782                	jalr	a5
    80004744:	892a                	mv	s2,a0
    80004746:	bf75                	j	80004702 <fileread+0x60>
    panic("fileread");
    80004748:	00004517          	auipc	a0,0x4
    8000474c:	f5850513          	addi	a0,a0,-168 # 800086a0 <syscalls+0x258>
    80004750:	ffffc097          	auipc	ra,0xffffc
    80004754:	dee080e7          	jalr	-530(ra) # 8000053e <panic>
    return -1;
    80004758:	597d                	li	s2,-1
    8000475a:	b765                	j	80004702 <fileread+0x60>
      return -1;
    8000475c:	597d                	li	s2,-1
    8000475e:	b755                	j	80004702 <fileread+0x60>
    80004760:	597d                	li	s2,-1
    80004762:	b745                	j	80004702 <fileread+0x60>

0000000080004764 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004764:	715d                	addi	sp,sp,-80
    80004766:	e486                	sd	ra,72(sp)
    80004768:	e0a2                	sd	s0,64(sp)
    8000476a:	fc26                	sd	s1,56(sp)
    8000476c:	f84a                	sd	s2,48(sp)
    8000476e:	f44e                	sd	s3,40(sp)
    80004770:	f052                	sd	s4,32(sp)
    80004772:	ec56                	sd	s5,24(sp)
    80004774:	e85a                	sd	s6,16(sp)
    80004776:	e45e                	sd	s7,8(sp)
    80004778:	e062                	sd	s8,0(sp)
    8000477a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000477c:	00954783          	lbu	a5,9(a0)
    80004780:	10078663          	beqz	a5,8000488c <filewrite+0x128>
    80004784:	892a                	mv	s2,a0
    80004786:	8aae                	mv	s5,a1
    80004788:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000478a:	411c                	lw	a5,0(a0)
    8000478c:	4705                	li	a4,1
    8000478e:	02e78263          	beq	a5,a4,800047b2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004792:	470d                	li	a4,3
    80004794:	02e78663          	beq	a5,a4,800047c0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004798:	4709                	li	a4,2
    8000479a:	0ee79163          	bne	a5,a4,8000487c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000479e:	0ac05d63          	blez	a2,80004858 <filewrite+0xf4>
    int i = 0;
    800047a2:	4981                	li	s3,0
    800047a4:	6b05                	lui	s6,0x1
    800047a6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047aa:	6b85                	lui	s7,0x1
    800047ac:	c00b8b9b          	addiw	s7,s7,-1024
    800047b0:	a861                	j	80004848 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800047b2:	6908                	ld	a0,16(a0)
    800047b4:	00000097          	auipc	ra,0x0
    800047b8:	22e080e7          	jalr	558(ra) # 800049e2 <pipewrite>
    800047bc:	8a2a                	mv	s4,a0
    800047be:	a045                	j	8000485e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047c0:	02451783          	lh	a5,36(a0)
    800047c4:	03079693          	slli	a3,a5,0x30
    800047c8:	92c1                	srli	a3,a3,0x30
    800047ca:	4725                	li	a4,9
    800047cc:	0cd76263          	bltu	a4,a3,80004890 <filewrite+0x12c>
    800047d0:	0792                	slli	a5,a5,0x4
    800047d2:	0003d717          	auipc	a4,0x3d
    800047d6:	b4670713          	addi	a4,a4,-1210 # 80041318 <devsw>
    800047da:	97ba                	add	a5,a5,a4
    800047dc:	679c                	ld	a5,8(a5)
    800047de:	cbdd                	beqz	a5,80004894 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800047e0:	4505                	li	a0,1
    800047e2:	9782                	jalr	a5
    800047e4:	8a2a                	mv	s4,a0
    800047e6:	a8a5                	j	8000485e <filewrite+0xfa>
    800047e8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047ec:	00000097          	auipc	ra,0x0
    800047f0:	8b0080e7          	jalr	-1872(ra) # 8000409c <begin_op>
      ilock(f->ip);
    800047f4:	01893503          	ld	a0,24(s2)
    800047f8:	fffff097          	auipc	ra,0xfffff
    800047fc:	ed2080e7          	jalr	-302(ra) # 800036ca <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004800:	8762                	mv	a4,s8
    80004802:	02092683          	lw	a3,32(s2)
    80004806:	01598633          	add	a2,s3,s5
    8000480a:	4585                	li	a1,1
    8000480c:	01893503          	ld	a0,24(s2)
    80004810:	fffff097          	auipc	ra,0xfffff
    80004814:	266080e7          	jalr	614(ra) # 80003a76 <writei>
    80004818:	84aa                	mv	s1,a0
    8000481a:	00a05763          	blez	a0,80004828 <filewrite+0xc4>
        f->off += r;
    8000481e:	02092783          	lw	a5,32(s2)
    80004822:	9fa9                	addw	a5,a5,a0
    80004824:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004828:	01893503          	ld	a0,24(s2)
    8000482c:	fffff097          	auipc	ra,0xfffff
    80004830:	f60080e7          	jalr	-160(ra) # 8000378c <iunlock>
      end_op();
    80004834:	00000097          	auipc	ra,0x0
    80004838:	8e8080e7          	jalr	-1816(ra) # 8000411c <end_op>

      if(r != n1){
    8000483c:	009c1f63          	bne	s8,s1,8000485a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004840:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004844:	0149db63          	bge	s3,s4,8000485a <filewrite+0xf6>
      int n1 = n - i;
    80004848:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000484c:	84be                	mv	s1,a5
    8000484e:	2781                	sext.w	a5,a5
    80004850:	f8fb5ce3          	bge	s6,a5,800047e8 <filewrite+0x84>
    80004854:	84de                	mv	s1,s7
    80004856:	bf49                	j	800047e8 <filewrite+0x84>
    int i = 0;
    80004858:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000485a:	013a1f63          	bne	s4,s3,80004878 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000485e:	8552                	mv	a0,s4
    80004860:	60a6                	ld	ra,72(sp)
    80004862:	6406                	ld	s0,64(sp)
    80004864:	74e2                	ld	s1,56(sp)
    80004866:	7942                	ld	s2,48(sp)
    80004868:	79a2                	ld	s3,40(sp)
    8000486a:	7a02                	ld	s4,32(sp)
    8000486c:	6ae2                	ld	s5,24(sp)
    8000486e:	6b42                	ld	s6,16(sp)
    80004870:	6ba2                	ld	s7,8(sp)
    80004872:	6c02                	ld	s8,0(sp)
    80004874:	6161                	addi	sp,sp,80
    80004876:	8082                	ret
    ret = (i == n ? n : -1);
    80004878:	5a7d                	li	s4,-1
    8000487a:	b7d5                	j	8000485e <filewrite+0xfa>
    panic("filewrite");
    8000487c:	00004517          	auipc	a0,0x4
    80004880:	e3450513          	addi	a0,a0,-460 # 800086b0 <syscalls+0x268>
    80004884:	ffffc097          	auipc	ra,0xffffc
    80004888:	cba080e7          	jalr	-838(ra) # 8000053e <panic>
    return -1;
    8000488c:	5a7d                	li	s4,-1
    8000488e:	bfc1                	j	8000485e <filewrite+0xfa>
      return -1;
    80004890:	5a7d                	li	s4,-1
    80004892:	b7f1                	j	8000485e <filewrite+0xfa>
    80004894:	5a7d                	li	s4,-1
    80004896:	b7e1                	j	8000485e <filewrite+0xfa>

0000000080004898 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004898:	7179                	addi	sp,sp,-48
    8000489a:	f406                	sd	ra,40(sp)
    8000489c:	f022                	sd	s0,32(sp)
    8000489e:	ec26                	sd	s1,24(sp)
    800048a0:	e84a                	sd	s2,16(sp)
    800048a2:	e44e                	sd	s3,8(sp)
    800048a4:	e052                	sd	s4,0(sp)
    800048a6:	1800                	addi	s0,sp,48
    800048a8:	84aa                	mv	s1,a0
    800048aa:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048ac:	0005b023          	sd	zero,0(a1)
    800048b0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048b4:	00000097          	auipc	ra,0x0
    800048b8:	bf8080e7          	jalr	-1032(ra) # 800044ac <filealloc>
    800048bc:	e088                	sd	a0,0(s1)
    800048be:	c551                	beqz	a0,8000494a <pipealloc+0xb2>
    800048c0:	00000097          	auipc	ra,0x0
    800048c4:	bec080e7          	jalr	-1044(ra) # 800044ac <filealloc>
    800048c8:	00aa3023          	sd	a0,0(s4)
    800048cc:	c92d                	beqz	a0,8000493e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048ce:	ffffc097          	auipc	ra,0xffffc
    800048d2:	318080e7          	jalr	792(ra) # 80000be6 <kalloc>
    800048d6:	892a                	mv	s2,a0
    800048d8:	c125                	beqz	a0,80004938 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048da:	4985                	li	s3,1
    800048dc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048e0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048e4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048e8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048ec:	00004597          	auipc	a1,0x4
    800048f0:	dd458593          	addi	a1,a1,-556 # 800086c0 <syscalls+0x278>
    800048f4:	ffffc097          	auipc	ra,0xffffc
    800048f8:	35c080e7          	jalr	860(ra) # 80000c50 <initlock>
  (*f0)->type = FD_PIPE;
    800048fc:	609c                	ld	a5,0(s1)
    800048fe:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004902:	609c                	ld	a5,0(s1)
    80004904:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004908:	609c                	ld	a5,0(s1)
    8000490a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000490e:	609c                	ld	a5,0(s1)
    80004910:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004914:	000a3783          	ld	a5,0(s4)
    80004918:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000491c:	000a3783          	ld	a5,0(s4)
    80004920:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004924:	000a3783          	ld	a5,0(s4)
    80004928:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000492c:	000a3783          	ld	a5,0(s4)
    80004930:	0127b823          	sd	s2,16(a5)
  return 0;
    80004934:	4501                	li	a0,0
    80004936:	a025                	j	8000495e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004938:	6088                	ld	a0,0(s1)
    8000493a:	e501                	bnez	a0,80004942 <pipealloc+0xaa>
    8000493c:	a039                	j	8000494a <pipealloc+0xb2>
    8000493e:	6088                	ld	a0,0(s1)
    80004940:	c51d                	beqz	a0,8000496e <pipealloc+0xd6>
    fileclose(*f0);
    80004942:	00000097          	auipc	ra,0x0
    80004946:	c26080e7          	jalr	-986(ra) # 80004568 <fileclose>
  if(*f1)
    8000494a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000494e:	557d                	li	a0,-1
  if(*f1)
    80004950:	c799                	beqz	a5,8000495e <pipealloc+0xc6>
    fileclose(*f1);
    80004952:	853e                	mv	a0,a5
    80004954:	00000097          	auipc	ra,0x0
    80004958:	c14080e7          	jalr	-1004(ra) # 80004568 <fileclose>
  return -1;
    8000495c:	557d                	li	a0,-1
}
    8000495e:	70a2                	ld	ra,40(sp)
    80004960:	7402                	ld	s0,32(sp)
    80004962:	64e2                	ld	s1,24(sp)
    80004964:	6942                	ld	s2,16(sp)
    80004966:	69a2                	ld	s3,8(sp)
    80004968:	6a02                	ld	s4,0(sp)
    8000496a:	6145                	addi	sp,sp,48
    8000496c:	8082                	ret
  return -1;
    8000496e:	557d                	li	a0,-1
    80004970:	b7fd                	j	8000495e <pipealloc+0xc6>

0000000080004972 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004972:	1101                	addi	sp,sp,-32
    80004974:	ec06                	sd	ra,24(sp)
    80004976:	e822                	sd	s0,16(sp)
    80004978:	e426                	sd	s1,8(sp)
    8000497a:	e04a                	sd	s2,0(sp)
    8000497c:	1000                	addi	s0,sp,32
    8000497e:	84aa                	mv	s1,a0
    80004980:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004982:	ffffc097          	auipc	ra,0xffffc
    80004986:	35e080e7          	jalr	862(ra) # 80000ce0 <acquire>
  if(writable){
    8000498a:	02090d63          	beqz	s2,800049c4 <pipeclose+0x52>
    pi->writeopen = 0;
    8000498e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004992:	21848513          	addi	a0,s1,536
    80004996:	ffffe097          	auipc	ra,0xffffe
    8000499a:	95e080e7          	jalr	-1698(ra) # 800022f4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000499e:	2204b783          	ld	a5,544(s1)
    800049a2:	eb95                	bnez	a5,800049d6 <pipeclose+0x64>
    release(&pi->lock);
    800049a4:	8526                	mv	a0,s1
    800049a6:	ffffc097          	auipc	ra,0xffffc
    800049aa:	3ee080e7          	jalr	1006(ra) # 80000d94 <release>
    kfree((char*)pi);
    800049ae:	8526                	mv	a0,s1
    800049b0:	ffffc097          	auipc	ra,0xffffc
    800049b4:	0ac080e7          	jalr	172(ra) # 80000a5c <kfree>
  } else
    release(&pi->lock);
}
    800049b8:	60e2                	ld	ra,24(sp)
    800049ba:	6442                	ld	s0,16(sp)
    800049bc:	64a2                	ld	s1,8(sp)
    800049be:	6902                	ld	s2,0(sp)
    800049c0:	6105                	addi	sp,sp,32
    800049c2:	8082                	ret
    pi->readopen = 0;
    800049c4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049c8:	21c48513          	addi	a0,s1,540
    800049cc:	ffffe097          	auipc	ra,0xffffe
    800049d0:	928080e7          	jalr	-1752(ra) # 800022f4 <wakeup>
    800049d4:	b7e9                	j	8000499e <pipeclose+0x2c>
    release(&pi->lock);
    800049d6:	8526                	mv	a0,s1
    800049d8:	ffffc097          	auipc	ra,0xffffc
    800049dc:	3bc080e7          	jalr	956(ra) # 80000d94 <release>
}
    800049e0:	bfe1                	j	800049b8 <pipeclose+0x46>

00000000800049e2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049e2:	7159                	addi	sp,sp,-112
    800049e4:	f486                	sd	ra,104(sp)
    800049e6:	f0a2                	sd	s0,96(sp)
    800049e8:	eca6                	sd	s1,88(sp)
    800049ea:	e8ca                	sd	s2,80(sp)
    800049ec:	e4ce                	sd	s3,72(sp)
    800049ee:	e0d2                	sd	s4,64(sp)
    800049f0:	fc56                	sd	s5,56(sp)
    800049f2:	f85a                	sd	s6,48(sp)
    800049f4:	f45e                	sd	s7,40(sp)
    800049f6:	f062                	sd	s8,32(sp)
    800049f8:	ec66                	sd	s9,24(sp)
    800049fa:	1880                	addi	s0,sp,112
    800049fc:	84aa                	mv	s1,a0
    800049fe:	8aae                	mv	s5,a1
    80004a00:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a02:	ffffd097          	auipc	ra,0xffffd
    80004a06:	0aa080e7          	jalr	170(ra) # 80001aac <myproc>
    80004a0a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a0c:	8526                	mv	a0,s1
    80004a0e:	ffffc097          	auipc	ra,0xffffc
    80004a12:	2d2080e7          	jalr	722(ra) # 80000ce0 <acquire>
  while(i < n){
    80004a16:	0d405163          	blez	s4,80004ad8 <pipewrite+0xf6>
    80004a1a:	8ba6                	mv	s7,s1
  int i = 0;
    80004a1c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a1e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a20:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a24:	21c48c13          	addi	s8,s1,540
    80004a28:	a08d                	j	80004a8a <pipewrite+0xa8>
      release(&pi->lock);
    80004a2a:	8526                	mv	a0,s1
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	368080e7          	jalr	872(ra) # 80000d94 <release>
      return -1;
    80004a34:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a36:	854a                	mv	a0,s2
    80004a38:	70a6                	ld	ra,104(sp)
    80004a3a:	7406                	ld	s0,96(sp)
    80004a3c:	64e6                	ld	s1,88(sp)
    80004a3e:	6946                	ld	s2,80(sp)
    80004a40:	69a6                	ld	s3,72(sp)
    80004a42:	6a06                	ld	s4,64(sp)
    80004a44:	7ae2                	ld	s5,56(sp)
    80004a46:	7b42                	ld	s6,48(sp)
    80004a48:	7ba2                	ld	s7,40(sp)
    80004a4a:	7c02                	ld	s8,32(sp)
    80004a4c:	6ce2                	ld	s9,24(sp)
    80004a4e:	6165                	addi	sp,sp,112
    80004a50:	8082                	ret
      wakeup(&pi->nread);
    80004a52:	8566                	mv	a0,s9
    80004a54:	ffffe097          	auipc	ra,0xffffe
    80004a58:	8a0080e7          	jalr	-1888(ra) # 800022f4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a5c:	85de                	mv	a1,s7
    80004a5e:	8562                	mv	a0,s8
    80004a60:	ffffd097          	auipc	ra,0xffffd
    80004a64:	708080e7          	jalr	1800(ra) # 80002168 <sleep>
    80004a68:	a839                	j	80004a86 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a6a:	21c4a783          	lw	a5,540(s1)
    80004a6e:	0017871b          	addiw	a4,a5,1
    80004a72:	20e4ae23          	sw	a4,540(s1)
    80004a76:	1ff7f793          	andi	a5,a5,511
    80004a7a:	97a6                	add	a5,a5,s1
    80004a7c:	f9f44703          	lbu	a4,-97(s0)
    80004a80:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a84:	2905                	addiw	s2,s2,1
  while(i < n){
    80004a86:	03495d63          	bge	s2,s4,80004ac0 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004a8a:	2204a783          	lw	a5,544(s1)
    80004a8e:	dfd1                	beqz	a5,80004a2a <pipewrite+0x48>
    80004a90:	0289a783          	lw	a5,40(s3)
    80004a94:	fbd9                	bnez	a5,80004a2a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a96:	2184a783          	lw	a5,536(s1)
    80004a9a:	21c4a703          	lw	a4,540(s1)
    80004a9e:	2007879b          	addiw	a5,a5,512
    80004aa2:	faf708e3          	beq	a4,a5,80004a52 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aa6:	4685                	li	a3,1
    80004aa8:	01590633          	add	a2,s2,s5
    80004aac:	f9f40593          	addi	a1,s0,-97
    80004ab0:	0509b503          	ld	a0,80(s3)
    80004ab4:	ffffd097          	auipc	ra,0xffffd
    80004ab8:	d46080e7          	jalr	-698(ra) # 800017fa <copyin>
    80004abc:	fb6517e3          	bne	a0,s6,80004a6a <pipewrite+0x88>
  wakeup(&pi->nread);
    80004ac0:	21848513          	addi	a0,s1,536
    80004ac4:	ffffe097          	auipc	ra,0xffffe
    80004ac8:	830080e7          	jalr	-2000(ra) # 800022f4 <wakeup>
  release(&pi->lock);
    80004acc:	8526                	mv	a0,s1
    80004ace:	ffffc097          	auipc	ra,0xffffc
    80004ad2:	2c6080e7          	jalr	710(ra) # 80000d94 <release>
  return i;
    80004ad6:	b785                	j	80004a36 <pipewrite+0x54>
  int i = 0;
    80004ad8:	4901                	li	s2,0
    80004ada:	b7dd                	j	80004ac0 <pipewrite+0xde>

0000000080004adc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004adc:	715d                	addi	sp,sp,-80
    80004ade:	e486                	sd	ra,72(sp)
    80004ae0:	e0a2                	sd	s0,64(sp)
    80004ae2:	fc26                	sd	s1,56(sp)
    80004ae4:	f84a                	sd	s2,48(sp)
    80004ae6:	f44e                	sd	s3,40(sp)
    80004ae8:	f052                	sd	s4,32(sp)
    80004aea:	ec56                	sd	s5,24(sp)
    80004aec:	e85a                	sd	s6,16(sp)
    80004aee:	0880                	addi	s0,sp,80
    80004af0:	84aa                	mv	s1,a0
    80004af2:	892e                	mv	s2,a1
    80004af4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004af6:	ffffd097          	auipc	ra,0xffffd
    80004afa:	fb6080e7          	jalr	-74(ra) # 80001aac <myproc>
    80004afe:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b00:	8b26                	mv	s6,s1
    80004b02:	8526                	mv	a0,s1
    80004b04:	ffffc097          	auipc	ra,0xffffc
    80004b08:	1dc080e7          	jalr	476(ra) # 80000ce0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b0c:	2184a703          	lw	a4,536(s1)
    80004b10:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b14:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b18:	02f71463          	bne	a4,a5,80004b40 <piperead+0x64>
    80004b1c:	2244a783          	lw	a5,548(s1)
    80004b20:	c385                	beqz	a5,80004b40 <piperead+0x64>
    if(pr->killed){
    80004b22:	028a2783          	lw	a5,40(s4)
    80004b26:	ebc1                	bnez	a5,80004bb6 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b28:	85da                	mv	a1,s6
    80004b2a:	854e                	mv	a0,s3
    80004b2c:	ffffd097          	auipc	ra,0xffffd
    80004b30:	63c080e7          	jalr	1596(ra) # 80002168 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b34:	2184a703          	lw	a4,536(s1)
    80004b38:	21c4a783          	lw	a5,540(s1)
    80004b3c:	fef700e3          	beq	a4,a5,80004b1c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b40:	09505263          	blez	s5,80004bc4 <piperead+0xe8>
    80004b44:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b46:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004b48:	2184a783          	lw	a5,536(s1)
    80004b4c:	21c4a703          	lw	a4,540(s1)
    80004b50:	02f70d63          	beq	a4,a5,80004b8a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b54:	0017871b          	addiw	a4,a5,1
    80004b58:	20e4ac23          	sw	a4,536(s1)
    80004b5c:	1ff7f793          	andi	a5,a5,511
    80004b60:	97a6                	add	a5,a5,s1
    80004b62:	0187c783          	lbu	a5,24(a5)
    80004b66:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b6a:	4685                	li	a3,1
    80004b6c:	fbf40613          	addi	a2,s0,-65
    80004b70:	85ca                	mv	a1,s2
    80004b72:	050a3503          	ld	a0,80(s4)
    80004b76:	ffffd097          	auipc	ra,0xffffd
    80004b7a:	bf8080e7          	jalr	-1032(ra) # 8000176e <copyout>
    80004b7e:	01650663          	beq	a0,s6,80004b8a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b82:	2985                	addiw	s3,s3,1
    80004b84:	0905                	addi	s2,s2,1
    80004b86:	fd3a91e3          	bne	s5,s3,80004b48 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b8a:	21c48513          	addi	a0,s1,540
    80004b8e:	ffffd097          	auipc	ra,0xffffd
    80004b92:	766080e7          	jalr	1894(ra) # 800022f4 <wakeup>
  release(&pi->lock);
    80004b96:	8526                	mv	a0,s1
    80004b98:	ffffc097          	auipc	ra,0xffffc
    80004b9c:	1fc080e7          	jalr	508(ra) # 80000d94 <release>
  return i;
}
    80004ba0:	854e                	mv	a0,s3
    80004ba2:	60a6                	ld	ra,72(sp)
    80004ba4:	6406                	ld	s0,64(sp)
    80004ba6:	74e2                	ld	s1,56(sp)
    80004ba8:	7942                	ld	s2,48(sp)
    80004baa:	79a2                	ld	s3,40(sp)
    80004bac:	7a02                	ld	s4,32(sp)
    80004bae:	6ae2                	ld	s5,24(sp)
    80004bb0:	6b42                	ld	s6,16(sp)
    80004bb2:	6161                	addi	sp,sp,80
    80004bb4:	8082                	ret
      release(&pi->lock);
    80004bb6:	8526                	mv	a0,s1
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	1dc080e7          	jalr	476(ra) # 80000d94 <release>
      return -1;
    80004bc0:	59fd                	li	s3,-1
    80004bc2:	bff9                	j	80004ba0 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bc4:	4981                	li	s3,0
    80004bc6:	b7d1                	j	80004b8a <piperead+0xae>

0000000080004bc8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004bc8:	df010113          	addi	sp,sp,-528
    80004bcc:	20113423          	sd	ra,520(sp)
    80004bd0:	20813023          	sd	s0,512(sp)
    80004bd4:	ffa6                	sd	s1,504(sp)
    80004bd6:	fbca                	sd	s2,496(sp)
    80004bd8:	f7ce                	sd	s3,488(sp)
    80004bda:	f3d2                	sd	s4,480(sp)
    80004bdc:	efd6                	sd	s5,472(sp)
    80004bde:	ebda                	sd	s6,464(sp)
    80004be0:	e7de                	sd	s7,456(sp)
    80004be2:	e3e2                	sd	s8,448(sp)
    80004be4:	ff66                	sd	s9,440(sp)
    80004be6:	fb6a                	sd	s10,432(sp)
    80004be8:	f76e                	sd	s11,424(sp)
    80004bea:	0c00                	addi	s0,sp,528
    80004bec:	84aa                	mv	s1,a0
    80004bee:	dea43c23          	sd	a0,-520(s0)
    80004bf2:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004bf6:	ffffd097          	auipc	ra,0xffffd
    80004bfa:	eb6080e7          	jalr	-330(ra) # 80001aac <myproc>
    80004bfe:	892a                	mv	s2,a0

  begin_op();
    80004c00:	fffff097          	auipc	ra,0xfffff
    80004c04:	49c080e7          	jalr	1180(ra) # 8000409c <begin_op>

  if((ip = namei(path)) == 0){
    80004c08:	8526                	mv	a0,s1
    80004c0a:	fffff097          	auipc	ra,0xfffff
    80004c0e:	276080e7          	jalr	630(ra) # 80003e80 <namei>
    80004c12:	c92d                	beqz	a0,80004c84 <exec+0xbc>
    80004c14:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c16:	fffff097          	auipc	ra,0xfffff
    80004c1a:	ab4080e7          	jalr	-1356(ra) # 800036ca <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c1e:	04000713          	li	a4,64
    80004c22:	4681                	li	a3,0
    80004c24:	e5040613          	addi	a2,s0,-432
    80004c28:	4581                	li	a1,0
    80004c2a:	8526                	mv	a0,s1
    80004c2c:	fffff097          	auipc	ra,0xfffff
    80004c30:	d52080e7          	jalr	-686(ra) # 8000397e <readi>
    80004c34:	04000793          	li	a5,64
    80004c38:	00f51a63          	bne	a0,a5,80004c4c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c3c:	e5042703          	lw	a4,-432(s0)
    80004c40:	464c47b7          	lui	a5,0x464c4
    80004c44:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c48:	04f70463          	beq	a4,a5,80004c90 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c4c:	8526                	mv	a0,s1
    80004c4e:	fffff097          	auipc	ra,0xfffff
    80004c52:	cde080e7          	jalr	-802(ra) # 8000392c <iunlockput>
    end_op();
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	4c6080e7          	jalr	1222(ra) # 8000411c <end_op>
  }
  return -1;
    80004c5e:	557d                	li	a0,-1
}
    80004c60:	20813083          	ld	ra,520(sp)
    80004c64:	20013403          	ld	s0,512(sp)
    80004c68:	74fe                	ld	s1,504(sp)
    80004c6a:	795e                	ld	s2,496(sp)
    80004c6c:	79be                	ld	s3,488(sp)
    80004c6e:	7a1e                	ld	s4,480(sp)
    80004c70:	6afe                	ld	s5,472(sp)
    80004c72:	6b5e                	ld	s6,464(sp)
    80004c74:	6bbe                	ld	s7,456(sp)
    80004c76:	6c1e                	ld	s8,448(sp)
    80004c78:	7cfa                	ld	s9,440(sp)
    80004c7a:	7d5a                	ld	s10,432(sp)
    80004c7c:	7dba                	ld	s11,424(sp)
    80004c7e:	21010113          	addi	sp,sp,528
    80004c82:	8082                	ret
    end_op();
    80004c84:	fffff097          	auipc	ra,0xfffff
    80004c88:	498080e7          	jalr	1176(ra) # 8000411c <end_op>
    return -1;
    80004c8c:	557d                	li	a0,-1
    80004c8e:	bfc9                	j	80004c60 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c90:	854a                	mv	a0,s2
    80004c92:	ffffd097          	auipc	ra,0xffffd
    80004c96:	ede080e7          	jalr	-290(ra) # 80001b70 <proc_pagetable>
    80004c9a:	8baa                	mv	s7,a0
    80004c9c:	d945                	beqz	a0,80004c4c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c9e:	e7042983          	lw	s3,-400(s0)
    80004ca2:	e8845783          	lhu	a5,-376(s0)
    80004ca6:	c7ad                	beqz	a5,80004d10 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ca8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004caa:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004cac:	6c85                	lui	s9,0x1
    80004cae:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004cb2:	def43823          	sd	a5,-528(s0)
    80004cb6:	a42d                	j	80004ee0 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cb8:	00004517          	auipc	a0,0x4
    80004cbc:	a1050513          	addi	a0,a0,-1520 # 800086c8 <syscalls+0x280>
    80004cc0:	ffffc097          	auipc	ra,0xffffc
    80004cc4:	87e080e7          	jalr	-1922(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cc8:	8756                	mv	a4,s5
    80004cca:	012d86bb          	addw	a3,s11,s2
    80004cce:	4581                	li	a1,0
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	fffff097          	auipc	ra,0xfffff
    80004cd6:	cac080e7          	jalr	-852(ra) # 8000397e <readi>
    80004cda:	2501                	sext.w	a0,a0
    80004cdc:	1aaa9963          	bne	s5,a0,80004e8e <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004ce0:	6785                	lui	a5,0x1
    80004ce2:	0127893b          	addw	s2,a5,s2
    80004ce6:	77fd                	lui	a5,0xfffff
    80004ce8:	01478a3b          	addw	s4,a5,s4
    80004cec:	1f897163          	bgeu	s2,s8,80004ece <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004cf0:	02091593          	slli	a1,s2,0x20
    80004cf4:	9181                	srli	a1,a1,0x20
    80004cf6:	95ea                	add	a1,a1,s10
    80004cf8:	855e                	mv	a0,s7
    80004cfa:	ffffc097          	auipc	ra,0xffffc
    80004cfe:	470080e7          	jalr	1136(ra) # 8000116a <walkaddr>
    80004d02:	862a                	mv	a2,a0
    if(pa == 0)
    80004d04:	d955                	beqz	a0,80004cb8 <exec+0xf0>
      n = PGSIZE;
    80004d06:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d08:	fd9a70e3          	bgeu	s4,s9,80004cc8 <exec+0x100>
      n = sz - i;
    80004d0c:	8ad2                	mv	s5,s4
    80004d0e:	bf6d                	j	80004cc8 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d10:	4901                	li	s2,0
  iunlockput(ip);
    80004d12:	8526                	mv	a0,s1
    80004d14:	fffff097          	auipc	ra,0xfffff
    80004d18:	c18080e7          	jalr	-1000(ra) # 8000392c <iunlockput>
  end_op();
    80004d1c:	fffff097          	auipc	ra,0xfffff
    80004d20:	400080e7          	jalr	1024(ra) # 8000411c <end_op>
  p = myproc();
    80004d24:	ffffd097          	auipc	ra,0xffffd
    80004d28:	d88080e7          	jalr	-632(ra) # 80001aac <myproc>
    80004d2c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d2e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d32:	6785                	lui	a5,0x1
    80004d34:	17fd                	addi	a5,a5,-1
    80004d36:	993e                	add	s2,s2,a5
    80004d38:	757d                	lui	a0,0xfffff
    80004d3a:	00a977b3          	and	a5,s2,a0
    80004d3e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d42:	6609                	lui	a2,0x2
    80004d44:	963e                	add	a2,a2,a5
    80004d46:	85be                	mv	a1,a5
    80004d48:	855e                	mv	a0,s7
    80004d4a:	ffffc097          	auipc	ra,0xffffc
    80004d4e:	7d4080e7          	jalr	2004(ra) # 8000151e <uvmalloc>
    80004d52:	8b2a                	mv	s6,a0
  ip = 0;
    80004d54:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d56:	12050c63          	beqz	a0,80004e8e <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d5a:	75f9                	lui	a1,0xffffe
    80004d5c:	95aa                	add	a1,a1,a0
    80004d5e:	855e                	mv	a0,s7
    80004d60:	ffffd097          	auipc	ra,0xffffd
    80004d64:	9dc080e7          	jalr	-1572(ra) # 8000173c <uvmclear>
  stackbase = sp - PGSIZE;
    80004d68:	7c7d                	lui	s8,0xfffff
    80004d6a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d6c:	e0043783          	ld	a5,-512(s0)
    80004d70:	6388                	ld	a0,0(a5)
    80004d72:	c535                	beqz	a0,80004dde <exec+0x216>
    80004d74:	e9040993          	addi	s3,s0,-368
    80004d78:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004d7c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004d7e:	ffffc097          	auipc	ra,0xffffc
    80004d82:	1e2080e7          	jalr	482(ra) # 80000f60 <strlen>
    80004d86:	2505                	addiw	a0,a0,1
    80004d88:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d8c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004d90:	13896363          	bltu	s2,s8,80004eb6 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d94:	e0043d83          	ld	s11,-512(s0)
    80004d98:	000dba03          	ld	s4,0(s11)
    80004d9c:	8552                	mv	a0,s4
    80004d9e:	ffffc097          	auipc	ra,0xffffc
    80004da2:	1c2080e7          	jalr	450(ra) # 80000f60 <strlen>
    80004da6:	0015069b          	addiw	a3,a0,1
    80004daa:	8652                	mv	a2,s4
    80004dac:	85ca                	mv	a1,s2
    80004dae:	855e                	mv	a0,s7
    80004db0:	ffffd097          	auipc	ra,0xffffd
    80004db4:	9be080e7          	jalr	-1602(ra) # 8000176e <copyout>
    80004db8:	10054363          	bltz	a0,80004ebe <exec+0x2f6>
    ustack[argc] = sp;
    80004dbc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004dc0:	0485                	addi	s1,s1,1
    80004dc2:	008d8793          	addi	a5,s11,8
    80004dc6:	e0f43023          	sd	a5,-512(s0)
    80004dca:	008db503          	ld	a0,8(s11)
    80004dce:	c911                	beqz	a0,80004de2 <exec+0x21a>
    if(argc >= MAXARG)
    80004dd0:	09a1                	addi	s3,s3,8
    80004dd2:	fb3c96e3          	bne	s9,s3,80004d7e <exec+0x1b6>
  sz = sz1;
    80004dd6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004dda:	4481                	li	s1,0
    80004ddc:	a84d                	j	80004e8e <exec+0x2c6>
  sp = sz;
    80004dde:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004de0:	4481                	li	s1,0
  ustack[argc] = 0;
    80004de2:	00349793          	slli	a5,s1,0x3
    80004de6:	f9040713          	addi	a4,s0,-112
    80004dea:	97ba                	add	a5,a5,a4
    80004dec:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004df0:	00148693          	addi	a3,s1,1
    80004df4:	068e                	slli	a3,a3,0x3
    80004df6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004dfa:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004dfe:	01897663          	bgeu	s2,s8,80004e0a <exec+0x242>
  sz = sz1;
    80004e02:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e06:	4481                	li	s1,0
    80004e08:	a059                	j	80004e8e <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e0a:	e9040613          	addi	a2,s0,-368
    80004e0e:	85ca                	mv	a1,s2
    80004e10:	855e                	mv	a0,s7
    80004e12:	ffffd097          	auipc	ra,0xffffd
    80004e16:	95c080e7          	jalr	-1700(ra) # 8000176e <copyout>
    80004e1a:	0a054663          	bltz	a0,80004ec6 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004e1e:	058ab783          	ld	a5,88(s5)
    80004e22:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e26:	df843783          	ld	a5,-520(s0)
    80004e2a:	0007c703          	lbu	a4,0(a5)
    80004e2e:	cf11                	beqz	a4,80004e4a <exec+0x282>
    80004e30:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e32:	02f00693          	li	a3,47
    80004e36:	a039                	j	80004e44 <exec+0x27c>
      last = s+1;
    80004e38:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004e3c:	0785                	addi	a5,a5,1
    80004e3e:	fff7c703          	lbu	a4,-1(a5)
    80004e42:	c701                	beqz	a4,80004e4a <exec+0x282>
    if(*s == '/')
    80004e44:	fed71ce3          	bne	a4,a3,80004e3c <exec+0x274>
    80004e48:	bfc5                	j	80004e38 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e4a:	4641                	li	a2,16
    80004e4c:	df843583          	ld	a1,-520(s0)
    80004e50:	158a8513          	addi	a0,s5,344
    80004e54:	ffffc097          	auipc	ra,0xffffc
    80004e58:	0da080e7          	jalr	218(ra) # 80000f2e <safestrcpy>
  oldpagetable = p->pagetable;
    80004e5c:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004e60:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004e64:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e68:	058ab783          	ld	a5,88(s5)
    80004e6c:	e6843703          	ld	a4,-408(s0)
    80004e70:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e72:	058ab783          	ld	a5,88(s5)
    80004e76:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e7a:	85ea                	mv	a1,s10
    80004e7c:	ffffd097          	auipc	ra,0xffffd
    80004e80:	d90080e7          	jalr	-624(ra) # 80001c0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e84:	0004851b          	sext.w	a0,s1
    80004e88:	bbe1                	j	80004c60 <exec+0x98>
    80004e8a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004e8e:	e0843583          	ld	a1,-504(s0)
    80004e92:	855e                	mv	a0,s7
    80004e94:	ffffd097          	auipc	ra,0xffffd
    80004e98:	d78080e7          	jalr	-648(ra) # 80001c0c <proc_freepagetable>
  if(ip){
    80004e9c:	da0498e3          	bnez	s1,80004c4c <exec+0x84>
  return -1;
    80004ea0:	557d                	li	a0,-1
    80004ea2:	bb7d                	j	80004c60 <exec+0x98>
    80004ea4:	e1243423          	sd	s2,-504(s0)
    80004ea8:	b7dd                	j	80004e8e <exec+0x2c6>
    80004eaa:	e1243423          	sd	s2,-504(s0)
    80004eae:	b7c5                	j	80004e8e <exec+0x2c6>
    80004eb0:	e1243423          	sd	s2,-504(s0)
    80004eb4:	bfe9                	j	80004e8e <exec+0x2c6>
  sz = sz1;
    80004eb6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eba:	4481                	li	s1,0
    80004ebc:	bfc9                	j	80004e8e <exec+0x2c6>
  sz = sz1;
    80004ebe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ec2:	4481                	li	s1,0
    80004ec4:	b7e9                	j	80004e8e <exec+0x2c6>
  sz = sz1;
    80004ec6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eca:	4481                	li	s1,0
    80004ecc:	b7c9                	j	80004e8e <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ece:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ed2:	2b05                	addiw	s6,s6,1
    80004ed4:	0389899b          	addiw	s3,s3,56
    80004ed8:	e8845783          	lhu	a5,-376(s0)
    80004edc:	e2fb5be3          	bge	s6,a5,80004d12 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ee0:	2981                	sext.w	s3,s3
    80004ee2:	03800713          	li	a4,56
    80004ee6:	86ce                	mv	a3,s3
    80004ee8:	e1840613          	addi	a2,s0,-488
    80004eec:	4581                	li	a1,0
    80004eee:	8526                	mv	a0,s1
    80004ef0:	fffff097          	auipc	ra,0xfffff
    80004ef4:	a8e080e7          	jalr	-1394(ra) # 8000397e <readi>
    80004ef8:	03800793          	li	a5,56
    80004efc:	f8f517e3          	bne	a0,a5,80004e8a <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004f00:	e1842783          	lw	a5,-488(s0)
    80004f04:	4705                	li	a4,1
    80004f06:	fce796e3          	bne	a5,a4,80004ed2 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004f0a:	e4043603          	ld	a2,-448(s0)
    80004f0e:	e3843783          	ld	a5,-456(s0)
    80004f12:	f8f669e3          	bltu	a2,a5,80004ea4 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f16:	e2843783          	ld	a5,-472(s0)
    80004f1a:	963e                	add	a2,a2,a5
    80004f1c:	f8f667e3          	bltu	a2,a5,80004eaa <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f20:	85ca                	mv	a1,s2
    80004f22:	855e                	mv	a0,s7
    80004f24:	ffffc097          	auipc	ra,0xffffc
    80004f28:	5fa080e7          	jalr	1530(ra) # 8000151e <uvmalloc>
    80004f2c:	e0a43423          	sd	a0,-504(s0)
    80004f30:	d141                	beqz	a0,80004eb0 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004f32:	e2843d03          	ld	s10,-472(s0)
    80004f36:	df043783          	ld	a5,-528(s0)
    80004f3a:	00fd77b3          	and	a5,s10,a5
    80004f3e:	fba1                	bnez	a5,80004e8e <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f40:	e2042d83          	lw	s11,-480(s0)
    80004f44:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f48:	f80c03e3          	beqz	s8,80004ece <exec+0x306>
    80004f4c:	8a62                	mv	s4,s8
    80004f4e:	4901                	li	s2,0
    80004f50:	b345                	j	80004cf0 <exec+0x128>

0000000080004f52 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f52:	7179                	addi	sp,sp,-48
    80004f54:	f406                	sd	ra,40(sp)
    80004f56:	f022                	sd	s0,32(sp)
    80004f58:	ec26                	sd	s1,24(sp)
    80004f5a:	e84a                	sd	s2,16(sp)
    80004f5c:	1800                	addi	s0,sp,48
    80004f5e:	892e                	mv	s2,a1
    80004f60:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f62:	fdc40593          	addi	a1,s0,-36
    80004f66:	ffffe097          	auipc	ra,0xffffe
    80004f6a:	bf2080e7          	jalr	-1038(ra) # 80002b58 <argint>
    80004f6e:	04054063          	bltz	a0,80004fae <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f72:	fdc42703          	lw	a4,-36(s0)
    80004f76:	47bd                	li	a5,15
    80004f78:	02e7ed63          	bltu	a5,a4,80004fb2 <argfd+0x60>
    80004f7c:	ffffd097          	auipc	ra,0xffffd
    80004f80:	b30080e7          	jalr	-1232(ra) # 80001aac <myproc>
    80004f84:	fdc42703          	lw	a4,-36(s0)
    80004f88:	01a70793          	addi	a5,a4,26
    80004f8c:	078e                	slli	a5,a5,0x3
    80004f8e:	953e                	add	a0,a0,a5
    80004f90:	611c                	ld	a5,0(a0)
    80004f92:	c395                	beqz	a5,80004fb6 <argfd+0x64>
    return -1;
  if(pfd)
    80004f94:	00090463          	beqz	s2,80004f9c <argfd+0x4a>
    *pfd = fd;
    80004f98:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004f9c:	4501                	li	a0,0
  if(pf)
    80004f9e:	c091                	beqz	s1,80004fa2 <argfd+0x50>
    *pf = f;
    80004fa0:	e09c                	sd	a5,0(s1)
}
    80004fa2:	70a2                	ld	ra,40(sp)
    80004fa4:	7402                	ld	s0,32(sp)
    80004fa6:	64e2                	ld	s1,24(sp)
    80004fa8:	6942                	ld	s2,16(sp)
    80004faa:	6145                	addi	sp,sp,48
    80004fac:	8082                	ret
    return -1;
    80004fae:	557d                	li	a0,-1
    80004fb0:	bfcd                	j	80004fa2 <argfd+0x50>
    return -1;
    80004fb2:	557d                	li	a0,-1
    80004fb4:	b7fd                	j	80004fa2 <argfd+0x50>
    80004fb6:	557d                	li	a0,-1
    80004fb8:	b7ed                	j	80004fa2 <argfd+0x50>

0000000080004fba <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fba:	1101                	addi	sp,sp,-32
    80004fbc:	ec06                	sd	ra,24(sp)
    80004fbe:	e822                	sd	s0,16(sp)
    80004fc0:	e426                	sd	s1,8(sp)
    80004fc2:	1000                	addi	s0,sp,32
    80004fc4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fc6:	ffffd097          	auipc	ra,0xffffd
    80004fca:	ae6080e7          	jalr	-1306(ra) # 80001aac <myproc>
    80004fce:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004fd0:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffb90d0>
    80004fd4:	4501                	li	a0,0
    80004fd6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004fd8:	6398                	ld	a4,0(a5)
    80004fda:	cb19                	beqz	a4,80004ff0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004fdc:	2505                	addiw	a0,a0,1
    80004fde:	07a1                	addi	a5,a5,8
    80004fe0:	fed51ce3          	bne	a0,a3,80004fd8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004fe4:	557d                	li	a0,-1
}
    80004fe6:	60e2                	ld	ra,24(sp)
    80004fe8:	6442                	ld	s0,16(sp)
    80004fea:	64a2                	ld	s1,8(sp)
    80004fec:	6105                	addi	sp,sp,32
    80004fee:	8082                	ret
      p->ofile[fd] = f;
    80004ff0:	01a50793          	addi	a5,a0,26
    80004ff4:	078e                	slli	a5,a5,0x3
    80004ff6:	963e                	add	a2,a2,a5
    80004ff8:	e204                	sd	s1,0(a2)
      return fd;
    80004ffa:	b7f5                	j	80004fe6 <fdalloc+0x2c>

0000000080004ffc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004ffc:	715d                	addi	sp,sp,-80
    80004ffe:	e486                	sd	ra,72(sp)
    80005000:	e0a2                	sd	s0,64(sp)
    80005002:	fc26                	sd	s1,56(sp)
    80005004:	f84a                	sd	s2,48(sp)
    80005006:	f44e                	sd	s3,40(sp)
    80005008:	f052                	sd	s4,32(sp)
    8000500a:	ec56                	sd	s5,24(sp)
    8000500c:	0880                	addi	s0,sp,80
    8000500e:	89ae                	mv	s3,a1
    80005010:	8ab2                	mv	s5,a2
    80005012:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005014:	fb040593          	addi	a1,s0,-80
    80005018:	fffff097          	auipc	ra,0xfffff
    8000501c:	e86080e7          	jalr	-378(ra) # 80003e9e <nameiparent>
    80005020:	892a                	mv	s2,a0
    80005022:	12050f63          	beqz	a0,80005160 <create+0x164>
    return 0;

  ilock(dp);
    80005026:	ffffe097          	auipc	ra,0xffffe
    8000502a:	6a4080e7          	jalr	1700(ra) # 800036ca <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000502e:	4601                	li	a2,0
    80005030:	fb040593          	addi	a1,s0,-80
    80005034:	854a                	mv	a0,s2
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	b78080e7          	jalr	-1160(ra) # 80003bae <dirlookup>
    8000503e:	84aa                	mv	s1,a0
    80005040:	c921                	beqz	a0,80005090 <create+0x94>
    iunlockput(dp);
    80005042:	854a                	mv	a0,s2
    80005044:	fffff097          	auipc	ra,0xfffff
    80005048:	8e8080e7          	jalr	-1816(ra) # 8000392c <iunlockput>
    ilock(ip);
    8000504c:	8526                	mv	a0,s1
    8000504e:	ffffe097          	auipc	ra,0xffffe
    80005052:	67c080e7          	jalr	1660(ra) # 800036ca <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005056:	2981                	sext.w	s3,s3
    80005058:	4789                	li	a5,2
    8000505a:	02f99463          	bne	s3,a5,80005082 <create+0x86>
    8000505e:	0444d783          	lhu	a5,68(s1)
    80005062:	37f9                	addiw	a5,a5,-2
    80005064:	17c2                	slli	a5,a5,0x30
    80005066:	93c1                	srli	a5,a5,0x30
    80005068:	4705                	li	a4,1
    8000506a:	00f76c63          	bltu	a4,a5,80005082 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000506e:	8526                	mv	a0,s1
    80005070:	60a6                	ld	ra,72(sp)
    80005072:	6406                	ld	s0,64(sp)
    80005074:	74e2                	ld	s1,56(sp)
    80005076:	7942                	ld	s2,48(sp)
    80005078:	79a2                	ld	s3,40(sp)
    8000507a:	7a02                	ld	s4,32(sp)
    8000507c:	6ae2                	ld	s5,24(sp)
    8000507e:	6161                	addi	sp,sp,80
    80005080:	8082                	ret
    iunlockput(ip);
    80005082:	8526                	mv	a0,s1
    80005084:	fffff097          	auipc	ra,0xfffff
    80005088:	8a8080e7          	jalr	-1880(ra) # 8000392c <iunlockput>
    return 0;
    8000508c:	4481                	li	s1,0
    8000508e:	b7c5                	j	8000506e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005090:	85ce                	mv	a1,s3
    80005092:	00092503          	lw	a0,0(s2)
    80005096:	ffffe097          	auipc	ra,0xffffe
    8000509a:	49c080e7          	jalr	1180(ra) # 80003532 <ialloc>
    8000509e:	84aa                	mv	s1,a0
    800050a0:	c529                	beqz	a0,800050ea <create+0xee>
  ilock(ip);
    800050a2:	ffffe097          	auipc	ra,0xffffe
    800050a6:	628080e7          	jalr	1576(ra) # 800036ca <ilock>
  ip->major = major;
    800050aa:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050ae:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800050b2:	4785                	li	a5,1
    800050b4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800050b8:	8526                	mv	a0,s1
    800050ba:	ffffe097          	auipc	ra,0xffffe
    800050be:	546080e7          	jalr	1350(ra) # 80003600 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050c2:	2981                	sext.w	s3,s3
    800050c4:	4785                	li	a5,1
    800050c6:	02f98a63          	beq	s3,a5,800050fa <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800050ca:	40d0                	lw	a2,4(s1)
    800050cc:	fb040593          	addi	a1,s0,-80
    800050d0:	854a                	mv	a0,s2
    800050d2:	fffff097          	auipc	ra,0xfffff
    800050d6:	cec080e7          	jalr	-788(ra) # 80003dbe <dirlink>
    800050da:	06054b63          	bltz	a0,80005150 <create+0x154>
  iunlockput(dp);
    800050de:	854a                	mv	a0,s2
    800050e0:	fffff097          	auipc	ra,0xfffff
    800050e4:	84c080e7          	jalr	-1972(ra) # 8000392c <iunlockput>
  return ip;
    800050e8:	b759                	j	8000506e <create+0x72>
    panic("create: ialloc");
    800050ea:	00003517          	auipc	a0,0x3
    800050ee:	5fe50513          	addi	a0,a0,1534 # 800086e8 <syscalls+0x2a0>
    800050f2:	ffffb097          	auipc	ra,0xffffb
    800050f6:	44c080e7          	jalr	1100(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800050fa:	04a95783          	lhu	a5,74(s2)
    800050fe:	2785                	addiw	a5,a5,1
    80005100:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005104:	854a                	mv	a0,s2
    80005106:	ffffe097          	auipc	ra,0xffffe
    8000510a:	4fa080e7          	jalr	1274(ra) # 80003600 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000510e:	40d0                	lw	a2,4(s1)
    80005110:	00003597          	auipc	a1,0x3
    80005114:	5e858593          	addi	a1,a1,1512 # 800086f8 <syscalls+0x2b0>
    80005118:	8526                	mv	a0,s1
    8000511a:	fffff097          	auipc	ra,0xfffff
    8000511e:	ca4080e7          	jalr	-860(ra) # 80003dbe <dirlink>
    80005122:	00054f63          	bltz	a0,80005140 <create+0x144>
    80005126:	00492603          	lw	a2,4(s2)
    8000512a:	00003597          	auipc	a1,0x3
    8000512e:	5d658593          	addi	a1,a1,1494 # 80008700 <syscalls+0x2b8>
    80005132:	8526                	mv	a0,s1
    80005134:	fffff097          	auipc	ra,0xfffff
    80005138:	c8a080e7          	jalr	-886(ra) # 80003dbe <dirlink>
    8000513c:	f80557e3          	bgez	a0,800050ca <create+0xce>
      panic("create dots");
    80005140:	00003517          	auipc	a0,0x3
    80005144:	5c850513          	addi	a0,a0,1480 # 80008708 <syscalls+0x2c0>
    80005148:	ffffb097          	auipc	ra,0xffffb
    8000514c:	3f6080e7          	jalr	1014(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005150:	00003517          	auipc	a0,0x3
    80005154:	5c850513          	addi	a0,a0,1480 # 80008718 <syscalls+0x2d0>
    80005158:	ffffb097          	auipc	ra,0xffffb
    8000515c:	3e6080e7          	jalr	998(ra) # 8000053e <panic>
    return 0;
    80005160:	84aa                	mv	s1,a0
    80005162:	b731                	j	8000506e <create+0x72>

0000000080005164 <sys_dup>:
{
    80005164:	7179                	addi	sp,sp,-48
    80005166:	f406                	sd	ra,40(sp)
    80005168:	f022                	sd	s0,32(sp)
    8000516a:	ec26                	sd	s1,24(sp)
    8000516c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000516e:	fd840613          	addi	a2,s0,-40
    80005172:	4581                	li	a1,0
    80005174:	4501                	li	a0,0
    80005176:	00000097          	auipc	ra,0x0
    8000517a:	ddc080e7          	jalr	-548(ra) # 80004f52 <argfd>
    return -1;
    8000517e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005180:	02054363          	bltz	a0,800051a6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005184:	fd843503          	ld	a0,-40(s0)
    80005188:	00000097          	auipc	ra,0x0
    8000518c:	e32080e7          	jalr	-462(ra) # 80004fba <fdalloc>
    80005190:	84aa                	mv	s1,a0
    return -1;
    80005192:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005194:	00054963          	bltz	a0,800051a6 <sys_dup+0x42>
  filedup(f);
    80005198:	fd843503          	ld	a0,-40(s0)
    8000519c:	fffff097          	auipc	ra,0xfffff
    800051a0:	37a080e7          	jalr	890(ra) # 80004516 <filedup>
  return fd;
    800051a4:	87a6                	mv	a5,s1
}
    800051a6:	853e                	mv	a0,a5
    800051a8:	70a2                	ld	ra,40(sp)
    800051aa:	7402                	ld	s0,32(sp)
    800051ac:	64e2                	ld	s1,24(sp)
    800051ae:	6145                	addi	sp,sp,48
    800051b0:	8082                	ret

00000000800051b2 <sys_read>:
{
    800051b2:	7179                	addi	sp,sp,-48
    800051b4:	f406                	sd	ra,40(sp)
    800051b6:	f022                	sd	s0,32(sp)
    800051b8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051ba:	fe840613          	addi	a2,s0,-24
    800051be:	4581                	li	a1,0
    800051c0:	4501                	li	a0,0
    800051c2:	00000097          	auipc	ra,0x0
    800051c6:	d90080e7          	jalr	-624(ra) # 80004f52 <argfd>
    return -1;
    800051ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051cc:	04054163          	bltz	a0,8000520e <sys_read+0x5c>
    800051d0:	fe440593          	addi	a1,s0,-28
    800051d4:	4509                	li	a0,2
    800051d6:	ffffe097          	auipc	ra,0xffffe
    800051da:	982080e7          	jalr	-1662(ra) # 80002b58 <argint>
    return -1;
    800051de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051e0:	02054763          	bltz	a0,8000520e <sys_read+0x5c>
    800051e4:	fd840593          	addi	a1,s0,-40
    800051e8:	4505                	li	a0,1
    800051ea:	ffffe097          	auipc	ra,0xffffe
    800051ee:	990080e7          	jalr	-1648(ra) # 80002b7a <argaddr>
    return -1;
    800051f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051f4:	00054d63          	bltz	a0,8000520e <sys_read+0x5c>
  return fileread(f, p, n);
    800051f8:	fe442603          	lw	a2,-28(s0)
    800051fc:	fd843583          	ld	a1,-40(s0)
    80005200:	fe843503          	ld	a0,-24(s0)
    80005204:	fffff097          	auipc	ra,0xfffff
    80005208:	49e080e7          	jalr	1182(ra) # 800046a2 <fileread>
    8000520c:	87aa                	mv	a5,a0
}
    8000520e:	853e                	mv	a0,a5
    80005210:	70a2                	ld	ra,40(sp)
    80005212:	7402                	ld	s0,32(sp)
    80005214:	6145                	addi	sp,sp,48
    80005216:	8082                	ret

0000000080005218 <sys_write>:
{
    80005218:	7179                	addi	sp,sp,-48
    8000521a:	f406                	sd	ra,40(sp)
    8000521c:	f022                	sd	s0,32(sp)
    8000521e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005220:	fe840613          	addi	a2,s0,-24
    80005224:	4581                	li	a1,0
    80005226:	4501                	li	a0,0
    80005228:	00000097          	auipc	ra,0x0
    8000522c:	d2a080e7          	jalr	-726(ra) # 80004f52 <argfd>
    return -1;
    80005230:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005232:	04054163          	bltz	a0,80005274 <sys_write+0x5c>
    80005236:	fe440593          	addi	a1,s0,-28
    8000523a:	4509                	li	a0,2
    8000523c:	ffffe097          	auipc	ra,0xffffe
    80005240:	91c080e7          	jalr	-1764(ra) # 80002b58 <argint>
    return -1;
    80005244:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005246:	02054763          	bltz	a0,80005274 <sys_write+0x5c>
    8000524a:	fd840593          	addi	a1,s0,-40
    8000524e:	4505                	li	a0,1
    80005250:	ffffe097          	auipc	ra,0xffffe
    80005254:	92a080e7          	jalr	-1750(ra) # 80002b7a <argaddr>
    return -1;
    80005258:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000525a:	00054d63          	bltz	a0,80005274 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000525e:	fe442603          	lw	a2,-28(s0)
    80005262:	fd843583          	ld	a1,-40(s0)
    80005266:	fe843503          	ld	a0,-24(s0)
    8000526a:	fffff097          	auipc	ra,0xfffff
    8000526e:	4fa080e7          	jalr	1274(ra) # 80004764 <filewrite>
    80005272:	87aa                	mv	a5,a0
}
    80005274:	853e                	mv	a0,a5
    80005276:	70a2                	ld	ra,40(sp)
    80005278:	7402                	ld	s0,32(sp)
    8000527a:	6145                	addi	sp,sp,48
    8000527c:	8082                	ret

000000008000527e <sys_close>:
{
    8000527e:	1101                	addi	sp,sp,-32
    80005280:	ec06                	sd	ra,24(sp)
    80005282:	e822                	sd	s0,16(sp)
    80005284:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005286:	fe040613          	addi	a2,s0,-32
    8000528a:	fec40593          	addi	a1,s0,-20
    8000528e:	4501                	li	a0,0
    80005290:	00000097          	auipc	ra,0x0
    80005294:	cc2080e7          	jalr	-830(ra) # 80004f52 <argfd>
    return -1;
    80005298:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000529a:	02054463          	bltz	a0,800052c2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000529e:	ffffd097          	auipc	ra,0xffffd
    800052a2:	80e080e7          	jalr	-2034(ra) # 80001aac <myproc>
    800052a6:	fec42783          	lw	a5,-20(s0)
    800052aa:	07e9                	addi	a5,a5,26
    800052ac:	078e                	slli	a5,a5,0x3
    800052ae:	97aa                	add	a5,a5,a0
    800052b0:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052b4:	fe043503          	ld	a0,-32(s0)
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	2b0080e7          	jalr	688(ra) # 80004568 <fileclose>
  return 0;
    800052c0:	4781                	li	a5,0
}
    800052c2:	853e                	mv	a0,a5
    800052c4:	60e2                	ld	ra,24(sp)
    800052c6:	6442                	ld	s0,16(sp)
    800052c8:	6105                	addi	sp,sp,32
    800052ca:	8082                	ret

00000000800052cc <sys_fstat>:
{
    800052cc:	1101                	addi	sp,sp,-32
    800052ce:	ec06                	sd	ra,24(sp)
    800052d0:	e822                	sd	s0,16(sp)
    800052d2:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052d4:	fe840613          	addi	a2,s0,-24
    800052d8:	4581                	li	a1,0
    800052da:	4501                	li	a0,0
    800052dc:	00000097          	auipc	ra,0x0
    800052e0:	c76080e7          	jalr	-906(ra) # 80004f52 <argfd>
    return -1;
    800052e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052e6:	02054563          	bltz	a0,80005310 <sys_fstat+0x44>
    800052ea:	fe040593          	addi	a1,s0,-32
    800052ee:	4505                	li	a0,1
    800052f0:	ffffe097          	auipc	ra,0xffffe
    800052f4:	88a080e7          	jalr	-1910(ra) # 80002b7a <argaddr>
    return -1;
    800052f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052fa:	00054b63          	bltz	a0,80005310 <sys_fstat+0x44>
  return filestat(f, st);
    800052fe:	fe043583          	ld	a1,-32(s0)
    80005302:	fe843503          	ld	a0,-24(s0)
    80005306:	fffff097          	auipc	ra,0xfffff
    8000530a:	32a080e7          	jalr	810(ra) # 80004630 <filestat>
    8000530e:	87aa                	mv	a5,a0
}
    80005310:	853e                	mv	a0,a5
    80005312:	60e2                	ld	ra,24(sp)
    80005314:	6442                	ld	s0,16(sp)
    80005316:	6105                	addi	sp,sp,32
    80005318:	8082                	ret

000000008000531a <sys_link>:
{
    8000531a:	7169                	addi	sp,sp,-304
    8000531c:	f606                	sd	ra,296(sp)
    8000531e:	f222                	sd	s0,288(sp)
    80005320:	ee26                	sd	s1,280(sp)
    80005322:	ea4a                	sd	s2,272(sp)
    80005324:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005326:	08000613          	li	a2,128
    8000532a:	ed040593          	addi	a1,s0,-304
    8000532e:	4501                	li	a0,0
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	86c080e7          	jalr	-1940(ra) # 80002b9c <argstr>
    return -1;
    80005338:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000533a:	10054e63          	bltz	a0,80005456 <sys_link+0x13c>
    8000533e:	08000613          	li	a2,128
    80005342:	f5040593          	addi	a1,s0,-176
    80005346:	4505                	li	a0,1
    80005348:	ffffe097          	auipc	ra,0xffffe
    8000534c:	854080e7          	jalr	-1964(ra) # 80002b9c <argstr>
    return -1;
    80005350:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005352:	10054263          	bltz	a0,80005456 <sys_link+0x13c>
  begin_op();
    80005356:	fffff097          	auipc	ra,0xfffff
    8000535a:	d46080e7          	jalr	-698(ra) # 8000409c <begin_op>
  if((ip = namei(old)) == 0){
    8000535e:	ed040513          	addi	a0,s0,-304
    80005362:	fffff097          	auipc	ra,0xfffff
    80005366:	b1e080e7          	jalr	-1250(ra) # 80003e80 <namei>
    8000536a:	84aa                	mv	s1,a0
    8000536c:	c551                	beqz	a0,800053f8 <sys_link+0xde>
  ilock(ip);
    8000536e:	ffffe097          	auipc	ra,0xffffe
    80005372:	35c080e7          	jalr	860(ra) # 800036ca <ilock>
  if(ip->type == T_DIR){
    80005376:	04449703          	lh	a4,68(s1)
    8000537a:	4785                	li	a5,1
    8000537c:	08f70463          	beq	a4,a5,80005404 <sys_link+0xea>
  ip->nlink++;
    80005380:	04a4d783          	lhu	a5,74(s1)
    80005384:	2785                	addiw	a5,a5,1
    80005386:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000538a:	8526                	mv	a0,s1
    8000538c:	ffffe097          	auipc	ra,0xffffe
    80005390:	274080e7          	jalr	628(ra) # 80003600 <iupdate>
  iunlock(ip);
    80005394:	8526                	mv	a0,s1
    80005396:	ffffe097          	auipc	ra,0xffffe
    8000539a:	3f6080e7          	jalr	1014(ra) # 8000378c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000539e:	fd040593          	addi	a1,s0,-48
    800053a2:	f5040513          	addi	a0,s0,-176
    800053a6:	fffff097          	auipc	ra,0xfffff
    800053aa:	af8080e7          	jalr	-1288(ra) # 80003e9e <nameiparent>
    800053ae:	892a                	mv	s2,a0
    800053b0:	c935                	beqz	a0,80005424 <sys_link+0x10a>
  ilock(dp);
    800053b2:	ffffe097          	auipc	ra,0xffffe
    800053b6:	318080e7          	jalr	792(ra) # 800036ca <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053ba:	00092703          	lw	a4,0(s2)
    800053be:	409c                	lw	a5,0(s1)
    800053c0:	04f71d63          	bne	a4,a5,8000541a <sys_link+0x100>
    800053c4:	40d0                	lw	a2,4(s1)
    800053c6:	fd040593          	addi	a1,s0,-48
    800053ca:	854a                	mv	a0,s2
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	9f2080e7          	jalr	-1550(ra) # 80003dbe <dirlink>
    800053d4:	04054363          	bltz	a0,8000541a <sys_link+0x100>
  iunlockput(dp);
    800053d8:	854a                	mv	a0,s2
    800053da:	ffffe097          	auipc	ra,0xffffe
    800053de:	552080e7          	jalr	1362(ra) # 8000392c <iunlockput>
  iput(ip);
    800053e2:	8526                	mv	a0,s1
    800053e4:	ffffe097          	auipc	ra,0xffffe
    800053e8:	4a0080e7          	jalr	1184(ra) # 80003884 <iput>
  end_op();
    800053ec:	fffff097          	auipc	ra,0xfffff
    800053f0:	d30080e7          	jalr	-720(ra) # 8000411c <end_op>
  return 0;
    800053f4:	4781                	li	a5,0
    800053f6:	a085                	j	80005456 <sys_link+0x13c>
    end_op();
    800053f8:	fffff097          	auipc	ra,0xfffff
    800053fc:	d24080e7          	jalr	-732(ra) # 8000411c <end_op>
    return -1;
    80005400:	57fd                	li	a5,-1
    80005402:	a891                	j	80005456 <sys_link+0x13c>
    iunlockput(ip);
    80005404:	8526                	mv	a0,s1
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	526080e7          	jalr	1318(ra) # 8000392c <iunlockput>
    end_op();
    8000540e:	fffff097          	auipc	ra,0xfffff
    80005412:	d0e080e7          	jalr	-754(ra) # 8000411c <end_op>
    return -1;
    80005416:	57fd                	li	a5,-1
    80005418:	a83d                	j	80005456 <sys_link+0x13c>
    iunlockput(dp);
    8000541a:	854a                	mv	a0,s2
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	510080e7          	jalr	1296(ra) # 8000392c <iunlockput>
  ilock(ip);
    80005424:	8526                	mv	a0,s1
    80005426:	ffffe097          	auipc	ra,0xffffe
    8000542a:	2a4080e7          	jalr	676(ra) # 800036ca <ilock>
  ip->nlink--;
    8000542e:	04a4d783          	lhu	a5,74(s1)
    80005432:	37fd                	addiw	a5,a5,-1
    80005434:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005438:	8526                	mv	a0,s1
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	1c6080e7          	jalr	454(ra) # 80003600 <iupdate>
  iunlockput(ip);
    80005442:	8526                	mv	a0,s1
    80005444:	ffffe097          	auipc	ra,0xffffe
    80005448:	4e8080e7          	jalr	1256(ra) # 8000392c <iunlockput>
  end_op();
    8000544c:	fffff097          	auipc	ra,0xfffff
    80005450:	cd0080e7          	jalr	-816(ra) # 8000411c <end_op>
  return -1;
    80005454:	57fd                	li	a5,-1
}
    80005456:	853e                	mv	a0,a5
    80005458:	70b2                	ld	ra,296(sp)
    8000545a:	7412                	ld	s0,288(sp)
    8000545c:	64f2                	ld	s1,280(sp)
    8000545e:	6952                	ld	s2,272(sp)
    80005460:	6155                	addi	sp,sp,304
    80005462:	8082                	ret

0000000080005464 <sys_unlink>:
{
    80005464:	7151                	addi	sp,sp,-240
    80005466:	f586                	sd	ra,232(sp)
    80005468:	f1a2                	sd	s0,224(sp)
    8000546a:	eda6                	sd	s1,216(sp)
    8000546c:	e9ca                	sd	s2,208(sp)
    8000546e:	e5ce                	sd	s3,200(sp)
    80005470:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005472:	08000613          	li	a2,128
    80005476:	f3040593          	addi	a1,s0,-208
    8000547a:	4501                	li	a0,0
    8000547c:	ffffd097          	auipc	ra,0xffffd
    80005480:	720080e7          	jalr	1824(ra) # 80002b9c <argstr>
    80005484:	18054163          	bltz	a0,80005606 <sys_unlink+0x1a2>
  begin_op();
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	c14080e7          	jalr	-1004(ra) # 8000409c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005490:	fb040593          	addi	a1,s0,-80
    80005494:	f3040513          	addi	a0,s0,-208
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	a06080e7          	jalr	-1530(ra) # 80003e9e <nameiparent>
    800054a0:	84aa                	mv	s1,a0
    800054a2:	c979                	beqz	a0,80005578 <sys_unlink+0x114>
  ilock(dp);
    800054a4:	ffffe097          	auipc	ra,0xffffe
    800054a8:	226080e7          	jalr	550(ra) # 800036ca <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054ac:	00003597          	auipc	a1,0x3
    800054b0:	24c58593          	addi	a1,a1,588 # 800086f8 <syscalls+0x2b0>
    800054b4:	fb040513          	addi	a0,s0,-80
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	6dc080e7          	jalr	1756(ra) # 80003b94 <namecmp>
    800054c0:	14050a63          	beqz	a0,80005614 <sys_unlink+0x1b0>
    800054c4:	00003597          	auipc	a1,0x3
    800054c8:	23c58593          	addi	a1,a1,572 # 80008700 <syscalls+0x2b8>
    800054cc:	fb040513          	addi	a0,s0,-80
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	6c4080e7          	jalr	1732(ra) # 80003b94 <namecmp>
    800054d8:	12050e63          	beqz	a0,80005614 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054dc:	f2c40613          	addi	a2,s0,-212
    800054e0:	fb040593          	addi	a1,s0,-80
    800054e4:	8526                	mv	a0,s1
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	6c8080e7          	jalr	1736(ra) # 80003bae <dirlookup>
    800054ee:	892a                	mv	s2,a0
    800054f0:	12050263          	beqz	a0,80005614 <sys_unlink+0x1b0>
  ilock(ip);
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	1d6080e7          	jalr	470(ra) # 800036ca <ilock>
  if(ip->nlink < 1)
    800054fc:	04a91783          	lh	a5,74(s2)
    80005500:	08f05263          	blez	a5,80005584 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005504:	04491703          	lh	a4,68(s2)
    80005508:	4785                	li	a5,1
    8000550a:	08f70563          	beq	a4,a5,80005594 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000550e:	4641                	li	a2,16
    80005510:	4581                	li	a1,0
    80005512:	fc040513          	addi	a0,s0,-64
    80005516:	ffffc097          	auipc	ra,0xffffc
    8000551a:	8c6080e7          	jalr	-1850(ra) # 80000ddc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000551e:	4741                	li	a4,16
    80005520:	f2c42683          	lw	a3,-212(s0)
    80005524:	fc040613          	addi	a2,s0,-64
    80005528:	4581                	li	a1,0
    8000552a:	8526                	mv	a0,s1
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	54a080e7          	jalr	1354(ra) # 80003a76 <writei>
    80005534:	47c1                	li	a5,16
    80005536:	0af51563          	bne	a0,a5,800055e0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000553a:	04491703          	lh	a4,68(s2)
    8000553e:	4785                	li	a5,1
    80005540:	0af70863          	beq	a4,a5,800055f0 <sys_unlink+0x18c>
  iunlockput(dp);
    80005544:	8526                	mv	a0,s1
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	3e6080e7          	jalr	998(ra) # 8000392c <iunlockput>
  ip->nlink--;
    8000554e:	04a95783          	lhu	a5,74(s2)
    80005552:	37fd                	addiw	a5,a5,-1
    80005554:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005558:	854a                	mv	a0,s2
    8000555a:	ffffe097          	auipc	ra,0xffffe
    8000555e:	0a6080e7          	jalr	166(ra) # 80003600 <iupdate>
  iunlockput(ip);
    80005562:	854a                	mv	a0,s2
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	3c8080e7          	jalr	968(ra) # 8000392c <iunlockput>
  end_op();
    8000556c:	fffff097          	auipc	ra,0xfffff
    80005570:	bb0080e7          	jalr	-1104(ra) # 8000411c <end_op>
  return 0;
    80005574:	4501                	li	a0,0
    80005576:	a84d                	j	80005628 <sys_unlink+0x1c4>
    end_op();
    80005578:	fffff097          	auipc	ra,0xfffff
    8000557c:	ba4080e7          	jalr	-1116(ra) # 8000411c <end_op>
    return -1;
    80005580:	557d                	li	a0,-1
    80005582:	a05d                	j	80005628 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005584:	00003517          	auipc	a0,0x3
    80005588:	1a450513          	addi	a0,a0,420 # 80008728 <syscalls+0x2e0>
    8000558c:	ffffb097          	auipc	ra,0xffffb
    80005590:	fb2080e7          	jalr	-78(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005594:	04c92703          	lw	a4,76(s2)
    80005598:	02000793          	li	a5,32
    8000559c:	f6e7f9e3          	bgeu	a5,a4,8000550e <sys_unlink+0xaa>
    800055a0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055a4:	4741                	li	a4,16
    800055a6:	86ce                	mv	a3,s3
    800055a8:	f1840613          	addi	a2,s0,-232
    800055ac:	4581                	li	a1,0
    800055ae:	854a                	mv	a0,s2
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	3ce080e7          	jalr	974(ra) # 8000397e <readi>
    800055b8:	47c1                	li	a5,16
    800055ba:	00f51b63          	bne	a0,a5,800055d0 <sys_unlink+0x16c>
    if(de.inum != 0)
    800055be:	f1845783          	lhu	a5,-232(s0)
    800055c2:	e7a1                	bnez	a5,8000560a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055c4:	29c1                	addiw	s3,s3,16
    800055c6:	04c92783          	lw	a5,76(s2)
    800055ca:	fcf9ede3          	bltu	s3,a5,800055a4 <sys_unlink+0x140>
    800055ce:	b781                	j	8000550e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055d0:	00003517          	auipc	a0,0x3
    800055d4:	17050513          	addi	a0,a0,368 # 80008740 <syscalls+0x2f8>
    800055d8:	ffffb097          	auipc	ra,0xffffb
    800055dc:	f66080e7          	jalr	-154(ra) # 8000053e <panic>
    panic("unlink: writei");
    800055e0:	00003517          	auipc	a0,0x3
    800055e4:	17850513          	addi	a0,a0,376 # 80008758 <syscalls+0x310>
    800055e8:	ffffb097          	auipc	ra,0xffffb
    800055ec:	f56080e7          	jalr	-170(ra) # 8000053e <panic>
    dp->nlink--;
    800055f0:	04a4d783          	lhu	a5,74(s1)
    800055f4:	37fd                	addiw	a5,a5,-1
    800055f6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055fa:	8526                	mv	a0,s1
    800055fc:	ffffe097          	auipc	ra,0xffffe
    80005600:	004080e7          	jalr	4(ra) # 80003600 <iupdate>
    80005604:	b781                	j	80005544 <sys_unlink+0xe0>
    return -1;
    80005606:	557d                	li	a0,-1
    80005608:	a005                	j	80005628 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000560a:	854a                	mv	a0,s2
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	320080e7          	jalr	800(ra) # 8000392c <iunlockput>
  iunlockput(dp);
    80005614:	8526                	mv	a0,s1
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	316080e7          	jalr	790(ra) # 8000392c <iunlockput>
  end_op();
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	afe080e7          	jalr	-1282(ra) # 8000411c <end_op>
  return -1;
    80005626:	557d                	li	a0,-1
}
    80005628:	70ae                	ld	ra,232(sp)
    8000562a:	740e                	ld	s0,224(sp)
    8000562c:	64ee                	ld	s1,216(sp)
    8000562e:	694e                	ld	s2,208(sp)
    80005630:	69ae                	ld	s3,200(sp)
    80005632:	616d                	addi	sp,sp,240
    80005634:	8082                	ret

0000000080005636 <sys_open>:

uint64
sys_open(void)
{
    80005636:	7131                	addi	sp,sp,-192
    80005638:	fd06                	sd	ra,184(sp)
    8000563a:	f922                	sd	s0,176(sp)
    8000563c:	f526                	sd	s1,168(sp)
    8000563e:	f14a                	sd	s2,160(sp)
    80005640:	ed4e                	sd	s3,152(sp)
    80005642:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005644:	08000613          	li	a2,128
    80005648:	f5040593          	addi	a1,s0,-176
    8000564c:	4501                	li	a0,0
    8000564e:	ffffd097          	auipc	ra,0xffffd
    80005652:	54e080e7          	jalr	1358(ra) # 80002b9c <argstr>
    return -1;
    80005656:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005658:	0c054163          	bltz	a0,8000571a <sys_open+0xe4>
    8000565c:	f4c40593          	addi	a1,s0,-180
    80005660:	4505                	li	a0,1
    80005662:	ffffd097          	auipc	ra,0xffffd
    80005666:	4f6080e7          	jalr	1270(ra) # 80002b58 <argint>
    8000566a:	0a054863          	bltz	a0,8000571a <sys_open+0xe4>

  begin_op();
    8000566e:	fffff097          	auipc	ra,0xfffff
    80005672:	a2e080e7          	jalr	-1490(ra) # 8000409c <begin_op>

  if(omode & O_CREATE){
    80005676:	f4c42783          	lw	a5,-180(s0)
    8000567a:	2007f793          	andi	a5,a5,512
    8000567e:	cbdd                	beqz	a5,80005734 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005680:	4681                	li	a3,0
    80005682:	4601                	li	a2,0
    80005684:	4589                	li	a1,2
    80005686:	f5040513          	addi	a0,s0,-176
    8000568a:	00000097          	auipc	ra,0x0
    8000568e:	972080e7          	jalr	-1678(ra) # 80004ffc <create>
    80005692:	892a                	mv	s2,a0
    if(ip == 0){
    80005694:	c959                	beqz	a0,8000572a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005696:	04491703          	lh	a4,68(s2)
    8000569a:	478d                	li	a5,3
    8000569c:	00f71763          	bne	a4,a5,800056aa <sys_open+0x74>
    800056a0:	04695703          	lhu	a4,70(s2)
    800056a4:	47a5                	li	a5,9
    800056a6:	0ce7ec63          	bltu	a5,a4,8000577e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	e02080e7          	jalr	-510(ra) # 800044ac <filealloc>
    800056b2:	89aa                	mv	s3,a0
    800056b4:	10050263          	beqz	a0,800057b8 <sys_open+0x182>
    800056b8:	00000097          	auipc	ra,0x0
    800056bc:	902080e7          	jalr	-1790(ra) # 80004fba <fdalloc>
    800056c0:	84aa                	mv	s1,a0
    800056c2:	0e054663          	bltz	a0,800057ae <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056c6:	04491703          	lh	a4,68(s2)
    800056ca:	478d                	li	a5,3
    800056cc:	0cf70463          	beq	a4,a5,80005794 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800056d0:	4789                	li	a5,2
    800056d2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056d6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056da:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056de:	f4c42783          	lw	a5,-180(s0)
    800056e2:	0017c713          	xori	a4,a5,1
    800056e6:	8b05                	andi	a4,a4,1
    800056e8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800056ec:	0037f713          	andi	a4,a5,3
    800056f0:	00e03733          	snez	a4,a4
    800056f4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800056f8:	4007f793          	andi	a5,a5,1024
    800056fc:	c791                	beqz	a5,80005708 <sys_open+0xd2>
    800056fe:	04491703          	lh	a4,68(s2)
    80005702:	4789                	li	a5,2
    80005704:	08f70f63          	beq	a4,a5,800057a2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005708:	854a                	mv	a0,s2
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	082080e7          	jalr	130(ra) # 8000378c <iunlock>
  end_op();
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	a0a080e7          	jalr	-1526(ra) # 8000411c <end_op>

  return fd;
}
    8000571a:	8526                	mv	a0,s1
    8000571c:	70ea                	ld	ra,184(sp)
    8000571e:	744a                	ld	s0,176(sp)
    80005720:	74aa                	ld	s1,168(sp)
    80005722:	790a                	ld	s2,160(sp)
    80005724:	69ea                	ld	s3,152(sp)
    80005726:	6129                	addi	sp,sp,192
    80005728:	8082                	ret
      end_op();
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	9f2080e7          	jalr	-1550(ra) # 8000411c <end_op>
      return -1;
    80005732:	b7e5                	j	8000571a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005734:	f5040513          	addi	a0,s0,-176
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	748080e7          	jalr	1864(ra) # 80003e80 <namei>
    80005740:	892a                	mv	s2,a0
    80005742:	c905                	beqz	a0,80005772 <sys_open+0x13c>
    ilock(ip);
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	f86080e7          	jalr	-122(ra) # 800036ca <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000574c:	04491703          	lh	a4,68(s2)
    80005750:	4785                	li	a5,1
    80005752:	f4f712e3          	bne	a4,a5,80005696 <sys_open+0x60>
    80005756:	f4c42783          	lw	a5,-180(s0)
    8000575a:	dba1                	beqz	a5,800056aa <sys_open+0x74>
      iunlockput(ip);
    8000575c:	854a                	mv	a0,s2
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	1ce080e7          	jalr	462(ra) # 8000392c <iunlockput>
      end_op();
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	9b6080e7          	jalr	-1610(ra) # 8000411c <end_op>
      return -1;
    8000576e:	54fd                	li	s1,-1
    80005770:	b76d                	j	8000571a <sys_open+0xe4>
      end_op();
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	9aa080e7          	jalr	-1622(ra) # 8000411c <end_op>
      return -1;
    8000577a:	54fd                	li	s1,-1
    8000577c:	bf79                	j	8000571a <sys_open+0xe4>
    iunlockput(ip);
    8000577e:	854a                	mv	a0,s2
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	1ac080e7          	jalr	428(ra) # 8000392c <iunlockput>
    end_op();
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	994080e7          	jalr	-1644(ra) # 8000411c <end_op>
    return -1;
    80005790:	54fd                	li	s1,-1
    80005792:	b761                	j	8000571a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005794:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005798:	04691783          	lh	a5,70(s2)
    8000579c:	02f99223          	sh	a5,36(s3)
    800057a0:	bf2d                	j	800056da <sys_open+0xa4>
    itrunc(ip);
    800057a2:	854a                	mv	a0,s2
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	034080e7          	jalr	52(ra) # 800037d8 <itrunc>
    800057ac:	bfb1                	j	80005708 <sys_open+0xd2>
      fileclose(f);
    800057ae:	854e                	mv	a0,s3
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	db8080e7          	jalr	-584(ra) # 80004568 <fileclose>
    iunlockput(ip);
    800057b8:	854a                	mv	a0,s2
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	172080e7          	jalr	370(ra) # 8000392c <iunlockput>
    end_op();
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	95a080e7          	jalr	-1702(ra) # 8000411c <end_op>
    return -1;
    800057ca:	54fd                	li	s1,-1
    800057cc:	b7b9                	j	8000571a <sys_open+0xe4>

00000000800057ce <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057ce:	7175                	addi	sp,sp,-144
    800057d0:	e506                	sd	ra,136(sp)
    800057d2:	e122                	sd	s0,128(sp)
    800057d4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	8c6080e7          	jalr	-1850(ra) # 8000409c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057de:	08000613          	li	a2,128
    800057e2:	f7040593          	addi	a1,s0,-144
    800057e6:	4501                	li	a0,0
    800057e8:	ffffd097          	auipc	ra,0xffffd
    800057ec:	3b4080e7          	jalr	948(ra) # 80002b9c <argstr>
    800057f0:	02054963          	bltz	a0,80005822 <sys_mkdir+0x54>
    800057f4:	4681                	li	a3,0
    800057f6:	4601                	li	a2,0
    800057f8:	4585                	li	a1,1
    800057fa:	f7040513          	addi	a0,s0,-144
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	7fe080e7          	jalr	2046(ra) # 80004ffc <create>
    80005806:	cd11                	beqz	a0,80005822 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005808:	ffffe097          	auipc	ra,0xffffe
    8000580c:	124080e7          	jalr	292(ra) # 8000392c <iunlockput>
  end_op();
    80005810:	fffff097          	auipc	ra,0xfffff
    80005814:	90c080e7          	jalr	-1780(ra) # 8000411c <end_op>
  return 0;
    80005818:	4501                	li	a0,0
}
    8000581a:	60aa                	ld	ra,136(sp)
    8000581c:	640a                	ld	s0,128(sp)
    8000581e:	6149                	addi	sp,sp,144
    80005820:	8082                	ret
    end_op();
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	8fa080e7          	jalr	-1798(ra) # 8000411c <end_op>
    return -1;
    8000582a:	557d                	li	a0,-1
    8000582c:	b7fd                	j	8000581a <sys_mkdir+0x4c>

000000008000582e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000582e:	7135                	addi	sp,sp,-160
    80005830:	ed06                	sd	ra,152(sp)
    80005832:	e922                	sd	s0,144(sp)
    80005834:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	866080e7          	jalr	-1946(ra) # 8000409c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000583e:	08000613          	li	a2,128
    80005842:	f7040593          	addi	a1,s0,-144
    80005846:	4501                	li	a0,0
    80005848:	ffffd097          	auipc	ra,0xffffd
    8000584c:	354080e7          	jalr	852(ra) # 80002b9c <argstr>
    80005850:	04054a63          	bltz	a0,800058a4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005854:	f6c40593          	addi	a1,s0,-148
    80005858:	4505                	li	a0,1
    8000585a:	ffffd097          	auipc	ra,0xffffd
    8000585e:	2fe080e7          	jalr	766(ra) # 80002b58 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005862:	04054163          	bltz	a0,800058a4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005866:	f6840593          	addi	a1,s0,-152
    8000586a:	4509                	li	a0,2
    8000586c:	ffffd097          	auipc	ra,0xffffd
    80005870:	2ec080e7          	jalr	748(ra) # 80002b58 <argint>
     argint(1, &major) < 0 ||
    80005874:	02054863          	bltz	a0,800058a4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005878:	f6841683          	lh	a3,-152(s0)
    8000587c:	f6c41603          	lh	a2,-148(s0)
    80005880:	458d                	li	a1,3
    80005882:	f7040513          	addi	a0,s0,-144
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	776080e7          	jalr	1910(ra) # 80004ffc <create>
     argint(2, &minor) < 0 ||
    8000588e:	c919                	beqz	a0,800058a4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	09c080e7          	jalr	156(ra) # 8000392c <iunlockput>
  end_op();
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	884080e7          	jalr	-1916(ra) # 8000411c <end_op>
  return 0;
    800058a0:	4501                	li	a0,0
    800058a2:	a031                	j	800058ae <sys_mknod+0x80>
    end_op();
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	878080e7          	jalr	-1928(ra) # 8000411c <end_op>
    return -1;
    800058ac:	557d                	li	a0,-1
}
    800058ae:	60ea                	ld	ra,152(sp)
    800058b0:	644a                	ld	s0,144(sp)
    800058b2:	610d                	addi	sp,sp,160
    800058b4:	8082                	ret

00000000800058b6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800058b6:	7135                	addi	sp,sp,-160
    800058b8:	ed06                	sd	ra,152(sp)
    800058ba:	e922                	sd	s0,144(sp)
    800058bc:	e526                	sd	s1,136(sp)
    800058be:	e14a                	sd	s2,128(sp)
    800058c0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058c2:	ffffc097          	auipc	ra,0xffffc
    800058c6:	1ea080e7          	jalr	490(ra) # 80001aac <myproc>
    800058ca:	892a                	mv	s2,a0
  
  begin_op();
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	7d0080e7          	jalr	2000(ra) # 8000409c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058d4:	08000613          	li	a2,128
    800058d8:	f6040593          	addi	a1,s0,-160
    800058dc:	4501                	li	a0,0
    800058de:	ffffd097          	auipc	ra,0xffffd
    800058e2:	2be080e7          	jalr	702(ra) # 80002b9c <argstr>
    800058e6:	04054b63          	bltz	a0,8000593c <sys_chdir+0x86>
    800058ea:	f6040513          	addi	a0,s0,-160
    800058ee:	ffffe097          	auipc	ra,0xffffe
    800058f2:	592080e7          	jalr	1426(ra) # 80003e80 <namei>
    800058f6:	84aa                	mv	s1,a0
    800058f8:	c131                	beqz	a0,8000593c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	dd0080e7          	jalr	-560(ra) # 800036ca <ilock>
  if(ip->type != T_DIR){
    80005902:	04449703          	lh	a4,68(s1)
    80005906:	4785                	li	a5,1
    80005908:	04f71063          	bne	a4,a5,80005948 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000590c:	8526                	mv	a0,s1
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	e7e080e7          	jalr	-386(ra) # 8000378c <iunlock>
  iput(p->cwd);
    80005916:	15093503          	ld	a0,336(s2)
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	f6a080e7          	jalr	-150(ra) # 80003884 <iput>
  end_op();
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	7fa080e7          	jalr	2042(ra) # 8000411c <end_op>
  p->cwd = ip;
    8000592a:	14993823          	sd	s1,336(s2)
  return 0;
    8000592e:	4501                	li	a0,0
}
    80005930:	60ea                	ld	ra,152(sp)
    80005932:	644a                	ld	s0,144(sp)
    80005934:	64aa                	ld	s1,136(sp)
    80005936:	690a                	ld	s2,128(sp)
    80005938:	610d                	addi	sp,sp,160
    8000593a:	8082                	ret
    end_op();
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	7e0080e7          	jalr	2016(ra) # 8000411c <end_op>
    return -1;
    80005944:	557d                	li	a0,-1
    80005946:	b7ed                	j	80005930 <sys_chdir+0x7a>
    iunlockput(ip);
    80005948:	8526                	mv	a0,s1
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	fe2080e7          	jalr	-30(ra) # 8000392c <iunlockput>
    end_op();
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	7ca080e7          	jalr	1994(ra) # 8000411c <end_op>
    return -1;
    8000595a:	557d                	li	a0,-1
    8000595c:	bfd1                	j	80005930 <sys_chdir+0x7a>

000000008000595e <sys_exec>:

uint64
sys_exec(void)
{
    8000595e:	7145                	addi	sp,sp,-464
    80005960:	e786                	sd	ra,456(sp)
    80005962:	e3a2                	sd	s0,448(sp)
    80005964:	ff26                	sd	s1,440(sp)
    80005966:	fb4a                	sd	s2,432(sp)
    80005968:	f74e                	sd	s3,424(sp)
    8000596a:	f352                	sd	s4,416(sp)
    8000596c:	ef56                	sd	s5,408(sp)
    8000596e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005970:	08000613          	li	a2,128
    80005974:	f4040593          	addi	a1,s0,-192
    80005978:	4501                	li	a0,0
    8000597a:	ffffd097          	auipc	ra,0xffffd
    8000597e:	222080e7          	jalr	546(ra) # 80002b9c <argstr>
    return -1;
    80005982:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005984:	0c054a63          	bltz	a0,80005a58 <sys_exec+0xfa>
    80005988:	e3840593          	addi	a1,s0,-456
    8000598c:	4505                	li	a0,1
    8000598e:	ffffd097          	auipc	ra,0xffffd
    80005992:	1ec080e7          	jalr	492(ra) # 80002b7a <argaddr>
    80005996:	0c054163          	bltz	a0,80005a58 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000599a:	10000613          	li	a2,256
    8000599e:	4581                	li	a1,0
    800059a0:	e4040513          	addi	a0,s0,-448
    800059a4:	ffffb097          	auipc	ra,0xffffb
    800059a8:	438080e7          	jalr	1080(ra) # 80000ddc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059ac:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059b0:	89a6                	mv	s3,s1
    800059b2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059b4:	02000a13          	li	s4,32
    800059b8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059bc:	00391513          	slli	a0,s2,0x3
    800059c0:	e3040593          	addi	a1,s0,-464
    800059c4:	e3843783          	ld	a5,-456(s0)
    800059c8:	953e                	add	a0,a0,a5
    800059ca:	ffffd097          	auipc	ra,0xffffd
    800059ce:	0f4080e7          	jalr	244(ra) # 80002abe <fetchaddr>
    800059d2:	02054a63          	bltz	a0,80005a06 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800059d6:	e3043783          	ld	a5,-464(s0)
    800059da:	c3b9                	beqz	a5,80005a20 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059dc:	ffffb097          	auipc	ra,0xffffb
    800059e0:	20a080e7          	jalr	522(ra) # 80000be6 <kalloc>
    800059e4:	85aa                	mv	a1,a0
    800059e6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800059ea:	cd11                	beqz	a0,80005a06 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059ec:	6605                	lui	a2,0x1
    800059ee:	e3043503          	ld	a0,-464(s0)
    800059f2:	ffffd097          	auipc	ra,0xffffd
    800059f6:	11e080e7          	jalr	286(ra) # 80002b10 <fetchstr>
    800059fa:	00054663          	bltz	a0,80005a06 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800059fe:	0905                	addi	s2,s2,1
    80005a00:	09a1                	addi	s3,s3,8
    80005a02:	fb491be3          	bne	s2,s4,800059b8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a06:	10048913          	addi	s2,s1,256
    80005a0a:	6088                	ld	a0,0(s1)
    80005a0c:	c529                	beqz	a0,80005a56 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a0e:	ffffb097          	auipc	ra,0xffffb
    80005a12:	04e080e7          	jalr	78(ra) # 80000a5c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a16:	04a1                	addi	s1,s1,8
    80005a18:	ff2499e3          	bne	s1,s2,80005a0a <sys_exec+0xac>
  return -1;
    80005a1c:	597d                	li	s2,-1
    80005a1e:	a82d                	j	80005a58 <sys_exec+0xfa>
      argv[i] = 0;
    80005a20:	0a8e                	slli	s5,s5,0x3
    80005a22:	fc040793          	addi	a5,s0,-64
    80005a26:	9abe                	add	s5,s5,a5
    80005a28:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a2c:	e4040593          	addi	a1,s0,-448
    80005a30:	f4040513          	addi	a0,s0,-192
    80005a34:	fffff097          	auipc	ra,0xfffff
    80005a38:	194080e7          	jalr	404(ra) # 80004bc8 <exec>
    80005a3c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a3e:	10048993          	addi	s3,s1,256
    80005a42:	6088                	ld	a0,0(s1)
    80005a44:	c911                	beqz	a0,80005a58 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a46:	ffffb097          	auipc	ra,0xffffb
    80005a4a:	016080e7          	jalr	22(ra) # 80000a5c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a4e:	04a1                	addi	s1,s1,8
    80005a50:	ff3499e3          	bne	s1,s3,80005a42 <sys_exec+0xe4>
    80005a54:	a011                	j	80005a58 <sys_exec+0xfa>
  return -1;
    80005a56:	597d                	li	s2,-1
}
    80005a58:	854a                	mv	a0,s2
    80005a5a:	60be                	ld	ra,456(sp)
    80005a5c:	641e                	ld	s0,448(sp)
    80005a5e:	74fa                	ld	s1,440(sp)
    80005a60:	795a                	ld	s2,432(sp)
    80005a62:	79ba                	ld	s3,424(sp)
    80005a64:	7a1a                	ld	s4,416(sp)
    80005a66:	6afa                	ld	s5,408(sp)
    80005a68:	6179                	addi	sp,sp,464
    80005a6a:	8082                	ret

0000000080005a6c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a6c:	7139                	addi	sp,sp,-64
    80005a6e:	fc06                	sd	ra,56(sp)
    80005a70:	f822                	sd	s0,48(sp)
    80005a72:	f426                	sd	s1,40(sp)
    80005a74:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a76:	ffffc097          	auipc	ra,0xffffc
    80005a7a:	036080e7          	jalr	54(ra) # 80001aac <myproc>
    80005a7e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005a80:	fd840593          	addi	a1,s0,-40
    80005a84:	4501                	li	a0,0
    80005a86:	ffffd097          	auipc	ra,0xffffd
    80005a8a:	0f4080e7          	jalr	244(ra) # 80002b7a <argaddr>
    return -1;
    80005a8e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005a90:	0e054063          	bltz	a0,80005b70 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005a94:	fc840593          	addi	a1,s0,-56
    80005a98:	fd040513          	addi	a0,s0,-48
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	dfc080e7          	jalr	-516(ra) # 80004898 <pipealloc>
    return -1;
    80005aa4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005aa6:	0c054563          	bltz	a0,80005b70 <sys_pipe+0x104>
  fd0 = -1;
    80005aaa:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005aae:	fd043503          	ld	a0,-48(s0)
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	508080e7          	jalr	1288(ra) # 80004fba <fdalloc>
    80005aba:	fca42223          	sw	a0,-60(s0)
    80005abe:	08054c63          	bltz	a0,80005b56 <sys_pipe+0xea>
    80005ac2:	fc843503          	ld	a0,-56(s0)
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	4f4080e7          	jalr	1268(ra) # 80004fba <fdalloc>
    80005ace:	fca42023          	sw	a0,-64(s0)
    80005ad2:	06054863          	bltz	a0,80005b42 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ad6:	4691                	li	a3,4
    80005ad8:	fc440613          	addi	a2,s0,-60
    80005adc:	fd843583          	ld	a1,-40(s0)
    80005ae0:	68a8                	ld	a0,80(s1)
    80005ae2:	ffffc097          	auipc	ra,0xffffc
    80005ae6:	c8c080e7          	jalr	-884(ra) # 8000176e <copyout>
    80005aea:	02054063          	bltz	a0,80005b0a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005aee:	4691                	li	a3,4
    80005af0:	fc040613          	addi	a2,s0,-64
    80005af4:	fd843583          	ld	a1,-40(s0)
    80005af8:	0591                	addi	a1,a1,4
    80005afa:	68a8                	ld	a0,80(s1)
    80005afc:	ffffc097          	auipc	ra,0xffffc
    80005b00:	c72080e7          	jalr	-910(ra) # 8000176e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b04:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b06:	06055563          	bgez	a0,80005b70 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b0a:	fc442783          	lw	a5,-60(s0)
    80005b0e:	07e9                	addi	a5,a5,26
    80005b10:	078e                	slli	a5,a5,0x3
    80005b12:	97a6                	add	a5,a5,s1
    80005b14:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b18:	fc042503          	lw	a0,-64(s0)
    80005b1c:	0569                	addi	a0,a0,26
    80005b1e:	050e                	slli	a0,a0,0x3
    80005b20:	9526                	add	a0,a0,s1
    80005b22:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b26:	fd043503          	ld	a0,-48(s0)
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	a3e080e7          	jalr	-1474(ra) # 80004568 <fileclose>
    fileclose(wf);
    80005b32:	fc843503          	ld	a0,-56(s0)
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	a32080e7          	jalr	-1486(ra) # 80004568 <fileclose>
    return -1;
    80005b3e:	57fd                	li	a5,-1
    80005b40:	a805                	j	80005b70 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b42:	fc442783          	lw	a5,-60(s0)
    80005b46:	0007c863          	bltz	a5,80005b56 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b4a:	01a78513          	addi	a0,a5,26
    80005b4e:	050e                	slli	a0,a0,0x3
    80005b50:	9526                	add	a0,a0,s1
    80005b52:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b56:	fd043503          	ld	a0,-48(s0)
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	a0e080e7          	jalr	-1522(ra) # 80004568 <fileclose>
    fileclose(wf);
    80005b62:	fc843503          	ld	a0,-56(s0)
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	a02080e7          	jalr	-1534(ra) # 80004568 <fileclose>
    return -1;
    80005b6e:	57fd                	li	a5,-1
}
    80005b70:	853e                	mv	a0,a5
    80005b72:	70e2                	ld	ra,56(sp)
    80005b74:	7442                	ld	s0,48(sp)
    80005b76:	74a2                	ld	s1,40(sp)
    80005b78:	6121                	addi	sp,sp,64
    80005b7a:	8082                	ret
    80005b7c:	0000                	unimp
	...

0000000080005b80 <kernelvec>:
    80005b80:	7111                	addi	sp,sp,-256
    80005b82:	e006                	sd	ra,0(sp)
    80005b84:	e40a                	sd	sp,8(sp)
    80005b86:	e80e                	sd	gp,16(sp)
    80005b88:	ec12                	sd	tp,24(sp)
    80005b8a:	f016                	sd	t0,32(sp)
    80005b8c:	f41a                	sd	t1,40(sp)
    80005b8e:	f81e                	sd	t2,48(sp)
    80005b90:	fc22                	sd	s0,56(sp)
    80005b92:	e0a6                	sd	s1,64(sp)
    80005b94:	e4aa                	sd	a0,72(sp)
    80005b96:	e8ae                	sd	a1,80(sp)
    80005b98:	ecb2                	sd	a2,88(sp)
    80005b9a:	f0b6                	sd	a3,96(sp)
    80005b9c:	f4ba                	sd	a4,104(sp)
    80005b9e:	f8be                	sd	a5,112(sp)
    80005ba0:	fcc2                	sd	a6,120(sp)
    80005ba2:	e146                	sd	a7,128(sp)
    80005ba4:	e54a                	sd	s2,136(sp)
    80005ba6:	e94e                	sd	s3,144(sp)
    80005ba8:	ed52                	sd	s4,152(sp)
    80005baa:	f156                	sd	s5,160(sp)
    80005bac:	f55a                	sd	s6,168(sp)
    80005bae:	f95e                	sd	s7,176(sp)
    80005bb0:	fd62                	sd	s8,184(sp)
    80005bb2:	e1e6                	sd	s9,192(sp)
    80005bb4:	e5ea                	sd	s10,200(sp)
    80005bb6:	e9ee                	sd	s11,208(sp)
    80005bb8:	edf2                	sd	t3,216(sp)
    80005bba:	f1f6                	sd	t4,224(sp)
    80005bbc:	f5fa                	sd	t5,232(sp)
    80005bbe:	f9fe                	sd	t6,240(sp)
    80005bc0:	dcbfc0ef          	jal	ra,8000298a <kerneltrap>
    80005bc4:	6082                	ld	ra,0(sp)
    80005bc6:	6122                	ld	sp,8(sp)
    80005bc8:	61c2                	ld	gp,16(sp)
    80005bca:	7282                	ld	t0,32(sp)
    80005bcc:	7322                	ld	t1,40(sp)
    80005bce:	73c2                	ld	t2,48(sp)
    80005bd0:	7462                	ld	s0,56(sp)
    80005bd2:	6486                	ld	s1,64(sp)
    80005bd4:	6526                	ld	a0,72(sp)
    80005bd6:	65c6                	ld	a1,80(sp)
    80005bd8:	6666                	ld	a2,88(sp)
    80005bda:	7686                	ld	a3,96(sp)
    80005bdc:	7726                	ld	a4,104(sp)
    80005bde:	77c6                	ld	a5,112(sp)
    80005be0:	7866                	ld	a6,120(sp)
    80005be2:	688a                	ld	a7,128(sp)
    80005be4:	692a                	ld	s2,136(sp)
    80005be6:	69ca                	ld	s3,144(sp)
    80005be8:	6a6a                	ld	s4,152(sp)
    80005bea:	7a8a                	ld	s5,160(sp)
    80005bec:	7b2a                	ld	s6,168(sp)
    80005bee:	7bca                	ld	s7,176(sp)
    80005bf0:	7c6a                	ld	s8,184(sp)
    80005bf2:	6c8e                	ld	s9,192(sp)
    80005bf4:	6d2e                	ld	s10,200(sp)
    80005bf6:	6dce                	ld	s11,208(sp)
    80005bf8:	6e6e                	ld	t3,216(sp)
    80005bfa:	7e8e                	ld	t4,224(sp)
    80005bfc:	7f2e                	ld	t5,232(sp)
    80005bfe:	7fce                	ld	t6,240(sp)
    80005c00:	6111                	addi	sp,sp,256
    80005c02:	10200073          	sret
    80005c06:	00000013          	nop
    80005c0a:	00000013          	nop
    80005c0e:	0001                	nop

0000000080005c10 <timervec>:
    80005c10:	34051573          	csrrw	a0,mscratch,a0
    80005c14:	e10c                	sd	a1,0(a0)
    80005c16:	e510                	sd	a2,8(a0)
    80005c18:	e914                	sd	a3,16(a0)
    80005c1a:	6d0c                	ld	a1,24(a0)
    80005c1c:	7110                	ld	a2,32(a0)
    80005c1e:	6194                	ld	a3,0(a1)
    80005c20:	96b2                	add	a3,a3,a2
    80005c22:	e194                	sd	a3,0(a1)
    80005c24:	4589                	li	a1,2
    80005c26:	14459073          	csrw	sip,a1
    80005c2a:	6914                	ld	a3,16(a0)
    80005c2c:	6510                	ld	a2,8(a0)
    80005c2e:	610c                	ld	a1,0(a0)
    80005c30:	34051573          	csrrw	a0,mscratch,a0
    80005c34:	30200073          	mret
	...

0000000080005c3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c3a:	1141                	addi	sp,sp,-16
    80005c3c:	e422                	sd	s0,8(sp)
    80005c3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c40:	0c0007b7          	lui	a5,0xc000
    80005c44:	4705                	li	a4,1
    80005c46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c48:	c3d8                	sw	a4,4(a5)
}
    80005c4a:	6422                	ld	s0,8(sp)
    80005c4c:	0141                	addi	sp,sp,16
    80005c4e:	8082                	ret

0000000080005c50 <plicinithart>:

void
plicinithart(void)
{
    80005c50:	1141                	addi	sp,sp,-16
    80005c52:	e406                	sd	ra,8(sp)
    80005c54:	e022                	sd	s0,0(sp)
    80005c56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c58:	ffffc097          	auipc	ra,0xffffc
    80005c5c:	e28080e7          	jalr	-472(ra) # 80001a80 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c60:	0085171b          	slliw	a4,a0,0x8
    80005c64:	0c0027b7          	lui	a5,0xc002
    80005c68:	97ba                	add	a5,a5,a4
    80005c6a:	40200713          	li	a4,1026
    80005c6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c72:	00d5151b          	slliw	a0,a0,0xd
    80005c76:	0c2017b7          	lui	a5,0xc201
    80005c7a:	953e                	add	a0,a0,a5
    80005c7c:	00052023          	sw	zero,0(a0)
}
    80005c80:	60a2                	ld	ra,8(sp)
    80005c82:	6402                	ld	s0,0(sp)
    80005c84:	0141                	addi	sp,sp,16
    80005c86:	8082                	ret

0000000080005c88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c88:	1141                	addi	sp,sp,-16
    80005c8a:	e406                	sd	ra,8(sp)
    80005c8c:	e022                	sd	s0,0(sp)
    80005c8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c90:	ffffc097          	auipc	ra,0xffffc
    80005c94:	df0080e7          	jalr	-528(ra) # 80001a80 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c98:	00d5179b          	slliw	a5,a0,0xd
    80005c9c:	0c201537          	lui	a0,0xc201
    80005ca0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ca2:	4148                	lw	a0,4(a0)
    80005ca4:	60a2                	ld	ra,8(sp)
    80005ca6:	6402                	ld	s0,0(sp)
    80005ca8:	0141                	addi	sp,sp,16
    80005caa:	8082                	ret

0000000080005cac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cac:	1101                	addi	sp,sp,-32
    80005cae:	ec06                	sd	ra,24(sp)
    80005cb0:	e822                	sd	s0,16(sp)
    80005cb2:	e426                	sd	s1,8(sp)
    80005cb4:	1000                	addi	s0,sp,32
    80005cb6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005cb8:	ffffc097          	auipc	ra,0xffffc
    80005cbc:	dc8080e7          	jalr	-568(ra) # 80001a80 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005cc0:	00d5151b          	slliw	a0,a0,0xd
    80005cc4:	0c2017b7          	lui	a5,0xc201
    80005cc8:	97aa                	add	a5,a5,a0
    80005cca:	c3c4                	sw	s1,4(a5)
}
    80005ccc:	60e2                	ld	ra,24(sp)
    80005cce:	6442                	ld	s0,16(sp)
    80005cd0:	64a2                	ld	s1,8(sp)
    80005cd2:	6105                	addi	sp,sp,32
    80005cd4:	8082                	ret

0000000080005cd6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005cd6:	1141                	addi	sp,sp,-16
    80005cd8:	e406                	sd	ra,8(sp)
    80005cda:	e022                	sd	s0,0(sp)
    80005cdc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cde:	479d                	li	a5,7
    80005ce0:	06a7c963          	blt	a5,a0,80005d52 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005ce4:	0003d797          	auipc	a5,0x3d
    80005ce8:	31c78793          	addi	a5,a5,796 # 80043000 <disk>
    80005cec:	00a78733          	add	a4,a5,a0
    80005cf0:	6789                	lui	a5,0x2
    80005cf2:	97ba                	add	a5,a5,a4
    80005cf4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005cf8:	e7ad                	bnez	a5,80005d62 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005cfa:	00451793          	slli	a5,a0,0x4
    80005cfe:	0003f717          	auipc	a4,0x3f
    80005d02:	30270713          	addi	a4,a4,770 # 80045000 <disk+0x2000>
    80005d06:	6314                	ld	a3,0(a4)
    80005d08:	96be                	add	a3,a3,a5
    80005d0a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d0e:	6314                	ld	a3,0(a4)
    80005d10:	96be                	add	a3,a3,a5
    80005d12:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d16:	6314                	ld	a3,0(a4)
    80005d18:	96be                	add	a3,a3,a5
    80005d1a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d1e:	6318                	ld	a4,0(a4)
    80005d20:	97ba                	add	a5,a5,a4
    80005d22:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d26:	0003d797          	auipc	a5,0x3d
    80005d2a:	2da78793          	addi	a5,a5,730 # 80043000 <disk>
    80005d2e:	97aa                	add	a5,a5,a0
    80005d30:	6509                	lui	a0,0x2
    80005d32:	953e                	add	a0,a0,a5
    80005d34:	4785                	li	a5,1
    80005d36:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d3a:	0003f517          	auipc	a0,0x3f
    80005d3e:	2de50513          	addi	a0,a0,734 # 80045018 <disk+0x2018>
    80005d42:	ffffc097          	auipc	ra,0xffffc
    80005d46:	5b2080e7          	jalr	1458(ra) # 800022f4 <wakeup>
}
    80005d4a:	60a2                	ld	ra,8(sp)
    80005d4c:	6402                	ld	s0,0(sp)
    80005d4e:	0141                	addi	sp,sp,16
    80005d50:	8082                	ret
    panic("free_desc 1");
    80005d52:	00003517          	auipc	a0,0x3
    80005d56:	a1650513          	addi	a0,a0,-1514 # 80008768 <syscalls+0x320>
    80005d5a:	ffffa097          	auipc	ra,0xffffa
    80005d5e:	7e4080e7          	jalr	2020(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005d62:	00003517          	auipc	a0,0x3
    80005d66:	a1650513          	addi	a0,a0,-1514 # 80008778 <syscalls+0x330>
    80005d6a:	ffffa097          	auipc	ra,0xffffa
    80005d6e:	7d4080e7          	jalr	2004(ra) # 8000053e <panic>

0000000080005d72 <virtio_disk_init>:
{
    80005d72:	1101                	addi	sp,sp,-32
    80005d74:	ec06                	sd	ra,24(sp)
    80005d76:	e822                	sd	s0,16(sp)
    80005d78:	e426                	sd	s1,8(sp)
    80005d7a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d7c:	00003597          	auipc	a1,0x3
    80005d80:	a0c58593          	addi	a1,a1,-1524 # 80008788 <syscalls+0x340>
    80005d84:	0003f517          	auipc	a0,0x3f
    80005d88:	3a450513          	addi	a0,a0,932 # 80045128 <disk+0x2128>
    80005d8c:	ffffb097          	auipc	ra,0xffffb
    80005d90:	ec4080e7          	jalr	-316(ra) # 80000c50 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d94:	100017b7          	lui	a5,0x10001
    80005d98:	4398                	lw	a4,0(a5)
    80005d9a:	2701                	sext.w	a4,a4
    80005d9c:	747277b7          	lui	a5,0x74727
    80005da0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005da4:	0ef71163          	bne	a4,a5,80005e86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005da8:	100017b7          	lui	a5,0x10001
    80005dac:	43dc                	lw	a5,4(a5)
    80005dae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005db0:	4705                	li	a4,1
    80005db2:	0ce79a63          	bne	a5,a4,80005e86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005db6:	100017b7          	lui	a5,0x10001
    80005dba:	479c                	lw	a5,8(a5)
    80005dbc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dbe:	4709                	li	a4,2
    80005dc0:	0ce79363          	bne	a5,a4,80005e86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005dc4:	100017b7          	lui	a5,0x10001
    80005dc8:	47d8                	lw	a4,12(a5)
    80005dca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dcc:	554d47b7          	lui	a5,0x554d4
    80005dd0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005dd4:	0af71963          	bne	a4,a5,80005e86 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dd8:	100017b7          	lui	a5,0x10001
    80005ddc:	4705                	li	a4,1
    80005dde:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005de0:	470d                	li	a4,3
    80005de2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005de4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005de6:	c7ffe737          	lui	a4,0xc7ffe
    80005dea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fb875f>
    80005dee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005df0:	2701                	sext.w	a4,a4
    80005df2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005df4:	472d                	li	a4,11
    80005df6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005df8:	473d                	li	a4,15
    80005dfa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005dfc:	6705                	lui	a4,0x1
    80005dfe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e00:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e04:	5bdc                	lw	a5,52(a5)
    80005e06:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e08:	c7d9                	beqz	a5,80005e96 <virtio_disk_init+0x124>
  if(max < NUM)
    80005e0a:	471d                	li	a4,7
    80005e0c:	08f77d63          	bgeu	a4,a5,80005ea6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e10:	100014b7          	lui	s1,0x10001
    80005e14:	47a1                	li	a5,8
    80005e16:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e18:	6609                	lui	a2,0x2
    80005e1a:	4581                	li	a1,0
    80005e1c:	0003d517          	auipc	a0,0x3d
    80005e20:	1e450513          	addi	a0,a0,484 # 80043000 <disk>
    80005e24:	ffffb097          	auipc	ra,0xffffb
    80005e28:	fb8080e7          	jalr	-72(ra) # 80000ddc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e2c:	0003d717          	auipc	a4,0x3d
    80005e30:	1d470713          	addi	a4,a4,468 # 80043000 <disk>
    80005e34:	00c75793          	srli	a5,a4,0xc
    80005e38:	2781                	sext.w	a5,a5
    80005e3a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005e3c:	0003f797          	auipc	a5,0x3f
    80005e40:	1c478793          	addi	a5,a5,452 # 80045000 <disk+0x2000>
    80005e44:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005e46:	0003d717          	auipc	a4,0x3d
    80005e4a:	23a70713          	addi	a4,a4,570 # 80043080 <disk+0x80>
    80005e4e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005e50:	0003e717          	auipc	a4,0x3e
    80005e54:	1b070713          	addi	a4,a4,432 # 80044000 <disk+0x1000>
    80005e58:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e5a:	4705                	li	a4,1
    80005e5c:	00e78c23          	sb	a4,24(a5)
    80005e60:	00e78ca3          	sb	a4,25(a5)
    80005e64:	00e78d23          	sb	a4,26(a5)
    80005e68:	00e78da3          	sb	a4,27(a5)
    80005e6c:	00e78e23          	sb	a4,28(a5)
    80005e70:	00e78ea3          	sb	a4,29(a5)
    80005e74:	00e78f23          	sb	a4,30(a5)
    80005e78:	00e78fa3          	sb	a4,31(a5)
}
    80005e7c:	60e2                	ld	ra,24(sp)
    80005e7e:	6442                	ld	s0,16(sp)
    80005e80:	64a2                	ld	s1,8(sp)
    80005e82:	6105                	addi	sp,sp,32
    80005e84:	8082                	ret
    panic("could not find virtio disk");
    80005e86:	00003517          	auipc	a0,0x3
    80005e8a:	91250513          	addi	a0,a0,-1774 # 80008798 <syscalls+0x350>
    80005e8e:	ffffa097          	auipc	ra,0xffffa
    80005e92:	6b0080e7          	jalr	1712(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005e96:	00003517          	auipc	a0,0x3
    80005e9a:	92250513          	addi	a0,a0,-1758 # 800087b8 <syscalls+0x370>
    80005e9e:	ffffa097          	auipc	ra,0xffffa
    80005ea2:	6a0080e7          	jalr	1696(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005ea6:	00003517          	auipc	a0,0x3
    80005eaa:	93250513          	addi	a0,a0,-1742 # 800087d8 <syscalls+0x390>
    80005eae:	ffffa097          	auipc	ra,0xffffa
    80005eb2:	690080e7          	jalr	1680(ra) # 8000053e <panic>

0000000080005eb6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005eb6:	7159                	addi	sp,sp,-112
    80005eb8:	f486                	sd	ra,104(sp)
    80005eba:	f0a2                	sd	s0,96(sp)
    80005ebc:	eca6                	sd	s1,88(sp)
    80005ebe:	e8ca                	sd	s2,80(sp)
    80005ec0:	e4ce                	sd	s3,72(sp)
    80005ec2:	e0d2                	sd	s4,64(sp)
    80005ec4:	fc56                	sd	s5,56(sp)
    80005ec6:	f85a                	sd	s6,48(sp)
    80005ec8:	f45e                	sd	s7,40(sp)
    80005eca:	f062                	sd	s8,32(sp)
    80005ecc:	ec66                	sd	s9,24(sp)
    80005ece:	e86a                	sd	s10,16(sp)
    80005ed0:	1880                	addi	s0,sp,112
    80005ed2:	892a                	mv	s2,a0
    80005ed4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005ed6:	00c52c83          	lw	s9,12(a0)
    80005eda:	001c9c9b          	slliw	s9,s9,0x1
    80005ede:	1c82                	slli	s9,s9,0x20
    80005ee0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005ee4:	0003f517          	auipc	a0,0x3f
    80005ee8:	24450513          	addi	a0,a0,580 # 80045128 <disk+0x2128>
    80005eec:	ffffb097          	auipc	ra,0xffffb
    80005ef0:	df4080e7          	jalr	-524(ra) # 80000ce0 <acquire>
  for(int i = 0; i < 3; i++){
    80005ef4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005ef6:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005ef8:	0003db97          	auipc	s7,0x3d
    80005efc:	108b8b93          	addi	s7,s7,264 # 80043000 <disk>
    80005f00:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f02:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f04:	8a4e                	mv	s4,s3
    80005f06:	a051                	j	80005f8a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f08:	00fb86b3          	add	a3,s7,a5
    80005f0c:	96da                	add	a3,a3,s6
    80005f0e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005f12:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005f14:	0207c563          	bltz	a5,80005f3e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f18:	2485                	addiw	s1,s1,1
    80005f1a:	0711                	addi	a4,a4,4
    80005f1c:	25548063          	beq	s1,s5,8000615c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005f20:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005f22:	0003f697          	auipc	a3,0x3f
    80005f26:	0f668693          	addi	a3,a3,246 # 80045018 <disk+0x2018>
    80005f2a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005f2c:	0006c583          	lbu	a1,0(a3)
    80005f30:	fde1                	bnez	a1,80005f08 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f32:	2785                	addiw	a5,a5,1
    80005f34:	0685                	addi	a3,a3,1
    80005f36:	ff879be3          	bne	a5,s8,80005f2c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f3a:	57fd                	li	a5,-1
    80005f3c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005f3e:	02905a63          	blez	s1,80005f72 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f42:	f9042503          	lw	a0,-112(s0)
    80005f46:	00000097          	auipc	ra,0x0
    80005f4a:	d90080e7          	jalr	-624(ra) # 80005cd6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f4e:	4785                	li	a5,1
    80005f50:	0297d163          	bge	a5,s1,80005f72 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f54:	f9442503          	lw	a0,-108(s0)
    80005f58:	00000097          	auipc	ra,0x0
    80005f5c:	d7e080e7          	jalr	-642(ra) # 80005cd6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f60:	4789                	li	a5,2
    80005f62:	0097d863          	bge	a5,s1,80005f72 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f66:	f9842503          	lw	a0,-104(s0)
    80005f6a:	00000097          	auipc	ra,0x0
    80005f6e:	d6c080e7          	jalr	-660(ra) # 80005cd6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f72:	0003f597          	auipc	a1,0x3f
    80005f76:	1b658593          	addi	a1,a1,438 # 80045128 <disk+0x2128>
    80005f7a:	0003f517          	auipc	a0,0x3f
    80005f7e:	09e50513          	addi	a0,a0,158 # 80045018 <disk+0x2018>
    80005f82:	ffffc097          	auipc	ra,0xffffc
    80005f86:	1e6080e7          	jalr	486(ra) # 80002168 <sleep>
  for(int i = 0; i < 3; i++){
    80005f8a:	f9040713          	addi	a4,s0,-112
    80005f8e:	84ce                	mv	s1,s3
    80005f90:	bf41                	j	80005f20 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005f92:	20058713          	addi	a4,a1,512
    80005f96:	00471693          	slli	a3,a4,0x4
    80005f9a:	0003d717          	auipc	a4,0x3d
    80005f9e:	06670713          	addi	a4,a4,102 # 80043000 <disk>
    80005fa2:	9736                	add	a4,a4,a3
    80005fa4:	4685                	li	a3,1
    80005fa6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005faa:	20058713          	addi	a4,a1,512
    80005fae:	00471693          	slli	a3,a4,0x4
    80005fb2:	0003d717          	auipc	a4,0x3d
    80005fb6:	04e70713          	addi	a4,a4,78 # 80043000 <disk>
    80005fba:	9736                	add	a4,a4,a3
    80005fbc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80005fc0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005fc4:	7679                	lui	a2,0xffffe
    80005fc6:	963e                	add	a2,a2,a5
    80005fc8:	0003f697          	auipc	a3,0x3f
    80005fcc:	03868693          	addi	a3,a3,56 # 80045000 <disk+0x2000>
    80005fd0:	6298                	ld	a4,0(a3)
    80005fd2:	9732                	add	a4,a4,a2
    80005fd4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005fd6:	6298                	ld	a4,0(a3)
    80005fd8:	9732                	add	a4,a4,a2
    80005fda:	4541                	li	a0,16
    80005fdc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005fde:	6298                	ld	a4,0(a3)
    80005fe0:	9732                	add	a4,a4,a2
    80005fe2:	4505                	li	a0,1
    80005fe4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80005fe8:	f9442703          	lw	a4,-108(s0)
    80005fec:	6288                	ld	a0,0(a3)
    80005fee:	962a                	add	a2,a2,a0
    80005ff0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffb800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005ff4:	0712                	slli	a4,a4,0x4
    80005ff6:	6290                	ld	a2,0(a3)
    80005ff8:	963a                	add	a2,a2,a4
    80005ffa:	05890513          	addi	a0,s2,88
    80005ffe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006000:	6294                	ld	a3,0(a3)
    80006002:	96ba                	add	a3,a3,a4
    80006004:	40000613          	li	a2,1024
    80006008:	c690                	sw	a2,8(a3)
  if(write)
    8000600a:	140d0063          	beqz	s10,8000614a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000600e:	0003f697          	auipc	a3,0x3f
    80006012:	ff26b683          	ld	a3,-14(a3) # 80045000 <disk+0x2000>
    80006016:	96ba                	add	a3,a3,a4
    80006018:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000601c:	0003d817          	auipc	a6,0x3d
    80006020:	fe480813          	addi	a6,a6,-28 # 80043000 <disk>
    80006024:	0003f517          	auipc	a0,0x3f
    80006028:	fdc50513          	addi	a0,a0,-36 # 80045000 <disk+0x2000>
    8000602c:	6114                	ld	a3,0(a0)
    8000602e:	96ba                	add	a3,a3,a4
    80006030:	00c6d603          	lhu	a2,12(a3)
    80006034:	00166613          	ori	a2,a2,1
    80006038:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000603c:	f9842683          	lw	a3,-104(s0)
    80006040:	6110                	ld	a2,0(a0)
    80006042:	9732                	add	a4,a4,a2
    80006044:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006048:	20058613          	addi	a2,a1,512
    8000604c:	0612                	slli	a2,a2,0x4
    8000604e:	9642                	add	a2,a2,a6
    80006050:	577d                	li	a4,-1
    80006052:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006056:	00469713          	slli	a4,a3,0x4
    8000605a:	6114                	ld	a3,0(a0)
    8000605c:	96ba                	add	a3,a3,a4
    8000605e:	03078793          	addi	a5,a5,48
    80006062:	97c2                	add	a5,a5,a6
    80006064:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006066:	611c                	ld	a5,0(a0)
    80006068:	97ba                	add	a5,a5,a4
    8000606a:	4685                	li	a3,1
    8000606c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000606e:	611c                	ld	a5,0(a0)
    80006070:	97ba                	add	a5,a5,a4
    80006072:	4809                	li	a6,2
    80006074:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006078:	611c                	ld	a5,0(a0)
    8000607a:	973e                	add	a4,a4,a5
    8000607c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006080:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006084:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006088:	6518                	ld	a4,8(a0)
    8000608a:	00275783          	lhu	a5,2(a4)
    8000608e:	8b9d                	andi	a5,a5,7
    80006090:	0786                	slli	a5,a5,0x1
    80006092:	97ba                	add	a5,a5,a4
    80006094:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006098:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000609c:	6518                	ld	a4,8(a0)
    8000609e:	00275783          	lhu	a5,2(a4)
    800060a2:	2785                	addiw	a5,a5,1
    800060a4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800060a8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060ac:	100017b7          	lui	a5,0x10001
    800060b0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800060b4:	00492703          	lw	a4,4(s2)
    800060b8:	4785                	li	a5,1
    800060ba:	02f71163          	bne	a4,a5,800060dc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800060be:	0003f997          	auipc	s3,0x3f
    800060c2:	06a98993          	addi	s3,s3,106 # 80045128 <disk+0x2128>
  while(b->disk == 1) {
    800060c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800060c8:	85ce                	mv	a1,s3
    800060ca:	854a                	mv	a0,s2
    800060cc:	ffffc097          	auipc	ra,0xffffc
    800060d0:	09c080e7          	jalr	156(ra) # 80002168 <sleep>
  while(b->disk == 1) {
    800060d4:	00492783          	lw	a5,4(s2)
    800060d8:	fe9788e3          	beq	a5,s1,800060c8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800060dc:	f9042903          	lw	s2,-112(s0)
    800060e0:	20090793          	addi	a5,s2,512
    800060e4:	00479713          	slli	a4,a5,0x4
    800060e8:	0003d797          	auipc	a5,0x3d
    800060ec:	f1878793          	addi	a5,a5,-232 # 80043000 <disk>
    800060f0:	97ba                	add	a5,a5,a4
    800060f2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800060f6:	0003f997          	auipc	s3,0x3f
    800060fa:	f0a98993          	addi	s3,s3,-246 # 80045000 <disk+0x2000>
    800060fe:	00491713          	slli	a4,s2,0x4
    80006102:	0009b783          	ld	a5,0(s3)
    80006106:	97ba                	add	a5,a5,a4
    80006108:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000610c:	854a                	mv	a0,s2
    8000610e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006112:	00000097          	auipc	ra,0x0
    80006116:	bc4080e7          	jalr	-1084(ra) # 80005cd6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000611a:	8885                	andi	s1,s1,1
    8000611c:	f0ed                	bnez	s1,800060fe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000611e:	0003f517          	auipc	a0,0x3f
    80006122:	00a50513          	addi	a0,a0,10 # 80045128 <disk+0x2128>
    80006126:	ffffb097          	auipc	ra,0xffffb
    8000612a:	c6e080e7          	jalr	-914(ra) # 80000d94 <release>
}
    8000612e:	70a6                	ld	ra,104(sp)
    80006130:	7406                	ld	s0,96(sp)
    80006132:	64e6                	ld	s1,88(sp)
    80006134:	6946                	ld	s2,80(sp)
    80006136:	69a6                	ld	s3,72(sp)
    80006138:	6a06                	ld	s4,64(sp)
    8000613a:	7ae2                	ld	s5,56(sp)
    8000613c:	7b42                	ld	s6,48(sp)
    8000613e:	7ba2                	ld	s7,40(sp)
    80006140:	7c02                	ld	s8,32(sp)
    80006142:	6ce2                	ld	s9,24(sp)
    80006144:	6d42                	ld	s10,16(sp)
    80006146:	6165                	addi	sp,sp,112
    80006148:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000614a:	0003f697          	auipc	a3,0x3f
    8000614e:	eb66b683          	ld	a3,-330(a3) # 80045000 <disk+0x2000>
    80006152:	96ba                	add	a3,a3,a4
    80006154:	4609                	li	a2,2
    80006156:	00c69623          	sh	a2,12(a3)
    8000615a:	b5c9                	j	8000601c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000615c:	f9042583          	lw	a1,-112(s0)
    80006160:	20058793          	addi	a5,a1,512
    80006164:	0792                	slli	a5,a5,0x4
    80006166:	0003d517          	auipc	a0,0x3d
    8000616a:	f4250513          	addi	a0,a0,-190 # 800430a8 <disk+0xa8>
    8000616e:	953e                	add	a0,a0,a5
  if(write)
    80006170:	e20d11e3          	bnez	s10,80005f92 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006174:	20058713          	addi	a4,a1,512
    80006178:	00471693          	slli	a3,a4,0x4
    8000617c:	0003d717          	auipc	a4,0x3d
    80006180:	e8470713          	addi	a4,a4,-380 # 80043000 <disk>
    80006184:	9736                	add	a4,a4,a3
    80006186:	0a072423          	sw	zero,168(a4)
    8000618a:	b505                	j	80005faa <virtio_disk_rw+0xf4>

000000008000618c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000618c:	1101                	addi	sp,sp,-32
    8000618e:	ec06                	sd	ra,24(sp)
    80006190:	e822                	sd	s0,16(sp)
    80006192:	e426                	sd	s1,8(sp)
    80006194:	e04a                	sd	s2,0(sp)
    80006196:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006198:	0003f517          	auipc	a0,0x3f
    8000619c:	f9050513          	addi	a0,a0,-112 # 80045128 <disk+0x2128>
    800061a0:	ffffb097          	auipc	ra,0xffffb
    800061a4:	b40080e7          	jalr	-1216(ra) # 80000ce0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061a8:	10001737          	lui	a4,0x10001
    800061ac:	533c                	lw	a5,96(a4)
    800061ae:	8b8d                	andi	a5,a5,3
    800061b0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061b2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061b6:	0003f797          	auipc	a5,0x3f
    800061ba:	e4a78793          	addi	a5,a5,-438 # 80045000 <disk+0x2000>
    800061be:	6b94                	ld	a3,16(a5)
    800061c0:	0207d703          	lhu	a4,32(a5)
    800061c4:	0026d783          	lhu	a5,2(a3)
    800061c8:	06f70163          	beq	a4,a5,8000622a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061cc:	0003d917          	auipc	s2,0x3d
    800061d0:	e3490913          	addi	s2,s2,-460 # 80043000 <disk>
    800061d4:	0003f497          	auipc	s1,0x3f
    800061d8:	e2c48493          	addi	s1,s1,-468 # 80045000 <disk+0x2000>
    __sync_synchronize();
    800061dc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061e0:	6898                	ld	a4,16(s1)
    800061e2:	0204d783          	lhu	a5,32(s1)
    800061e6:	8b9d                	andi	a5,a5,7
    800061e8:	078e                	slli	a5,a5,0x3
    800061ea:	97ba                	add	a5,a5,a4
    800061ec:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800061ee:	20078713          	addi	a4,a5,512
    800061f2:	0712                	slli	a4,a4,0x4
    800061f4:	974a                	add	a4,a4,s2
    800061f6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800061fa:	e731                	bnez	a4,80006246 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800061fc:	20078793          	addi	a5,a5,512
    80006200:	0792                	slli	a5,a5,0x4
    80006202:	97ca                	add	a5,a5,s2
    80006204:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006206:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000620a:	ffffc097          	auipc	ra,0xffffc
    8000620e:	0ea080e7          	jalr	234(ra) # 800022f4 <wakeup>

    disk.used_idx += 1;
    80006212:	0204d783          	lhu	a5,32(s1)
    80006216:	2785                	addiw	a5,a5,1
    80006218:	17c2                	slli	a5,a5,0x30
    8000621a:	93c1                	srli	a5,a5,0x30
    8000621c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006220:	6898                	ld	a4,16(s1)
    80006222:	00275703          	lhu	a4,2(a4)
    80006226:	faf71be3          	bne	a4,a5,800061dc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000622a:	0003f517          	auipc	a0,0x3f
    8000622e:	efe50513          	addi	a0,a0,-258 # 80045128 <disk+0x2128>
    80006232:	ffffb097          	auipc	ra,0xffffb
    80006236:	b62080e7          	jalr	-1182(ra) # 80000d94 <release>
}
    8000623a:	60e2                	ld	ra,24(sp)
    8000623c:	6442                	ld	s0,16(sp)
    8000623e:	64a2                	ld	s1,8(sp)
    80006240:	6902                	ld	s2,0(sp)
    80006242:	6105                	addi	sp,sp,32
    80006244:	8082                	ret
      panic("virtio_disk_intr status");
    80006246:	00002517          	auipc	a0,0x2
    8000624a:	5b250513          	addi	a0,a0,1458 # 800087f8 <syscalls+0x3b0>
    8000624e:	ffffa097          	auipc	ra,0xffffa
    80006252:	2f0080e7          	jalr	752(ra) # 8000053e <panic>

0000000080006256 <cas>:
    80006256:	100522af          	lr.w	t0,(a0)
    8000625a:	00b29563          	bne	t0,a1,80006264 <fail>
    8000625e:	18c5252f          	sc.w	a0,a2,(a0)
    80006262:	8082                	ret

0000000080006264 <fail>:
    80006264:	4505                	li	a0,1
    80006266:	8082                	ret
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
