
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a7013103          	ld	sp,-1424(sp) # 80008a70 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	1ec78793          	addi	a5,a5,492 # 80006250 <timervec>
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
    80000130:	510080e7          	jalr	1296(ra) # 8000263c <either_copyin>
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
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	b70080e7          	jalr	-1168(ra) # 80001d34 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	1ee080e7          	jalr	494(ra) # 800023c2 <sleep>
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
    80000214:	3d6080e7          	jalr	982(ra) # 800025e6 <either_copyout>
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
    800002f6:	3a0080e7          	jalr	928(ra) # 80002692 <procdump>
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
    8000044a:	592080e7          	jalr	1426(ra) # 800029d8 <wakeup>
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
    8000047c:	36078793          	addi	a5,a5,864 # 800217d8 <devsw>
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
    80000570:	dcc50513          	addi	a0,a0,-564 # 80008338 <digits+0x2f8>
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
    800008a4:	138080e7          	jalr	312(ra) # 800029d8 <wakeup>
    
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
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	a96080e7          	jalr	-1386(ra) # 800023c2 <sleep>
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
    80000b82:	194080e7          	jalr	404(ra) # 80001d12 <mycpu>
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
    80000bb4:	162080e7          	jalr	354(ra) # 80001d12 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	156080e7          	jalr	342(ra) # 80001d12 <mycpu>
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
    80000bd8:	13e080e7          	jalr	318(ra) # 80001d12 <mycpu>
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
    80000c18:	0fe080e7          	jalr	254(ra) # 80001d12 <mycpu>
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
    80000c44:	0d2080e7          	jalr	210(ra) # 80001d12 <mycpu>
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
    80000e9a:	e6c080e7          	jalr	-404(ra) # 80001d02 <cpuid>
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
    80000eb6:	e50080e7          	jalr	-432(ra) # 80001d02 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	dea080e7          	jalr	-534(ra) # 80002cbe <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	3b4080e7          	jalr	948(ra) # 80006290 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	2b0080e7          	jalr	688(ra) # 80002194 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	43c50513          	addi	a0,a0,1084 # 80008338 <digits+0x2f8>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	41c50513          	addi	a0,a0,1052 # 80008338 <digits+0x2f8>
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
    80000f48:	cba080e7          	jalr	-838(ra) # 80001bfe <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	d4a080e7          	jalr	-694(ra) # 80002c96 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	d6a080e7          	jalr	-662(ra) # 80002cbe <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	31e080e7          	jalr	798(ra) # 8000627a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	32c080e7          	jalr	812(ra) # 80006290 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	510080e7          	jalr	1296(ra) # 8000347c <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	ba0080e7          	jalr	-1120(ra) # 80003b14 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	b4a080e7          	jalr	-1206(ra) # 80004ac6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	42e080e7          	jalr	1070(ra) # 800063b2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	0ec080e7          	jalr	236(ra) # 80002078 <userinit>
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
    80001240:	00001097          	auipc	ra,0x1
    80001244:	928080e7          	jalr	-1752(ra) # 80001b68 <proc_mapstacks>
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

000000008000183e <print_list>:
struct _list unused_list = {-1, -1};   // contains all UNUSED process entries.
struct _list sleeping_list = {-1, -1}; // contains all SLEEPING processes.
struct _list zombie_list = {-1, -1};   // contains all ZOMBIE processes.

void
print_list(struct _list lst){
    8000183e:	715d                	addi	sp,sp,-80
    80001840:	e486                	sd	ra,72(sp)
    80001842:	e0a2                	sd	s0,64(sp)
    80001844:	fc26                	sd	s1,56(sp)
    80001846:	f84a                	sd	s2,48(sp)
    80001848:	f44e                	sd	s3,40(sp)
    8000184a:	f052                	sd	s4,32(sp)
    8000184c:	ec56                	sd	s5,24(sp)
    8000184e:	0880                	addi	s0,sp,80
    80001850:	faa43c23          	sd	a0,-72(s0)
  int curr = lst.head;
    80001854:	0005049b          	sext.w	s1,a0
  printf("\n[ ");
    80001858:	00007517          	auipc	a0,0x7
    8000185c:	98050513          	addi	a0,a0,-1664 # 800081d8 <digits+0x198>
    80001860:	fffff097          	auipc	ra,0xfffff
    80001864:	d28080e7          	jalr	-728(ra) # 80000588 <printf>
  while(curr != -1){
    80001868:	57fd                	li	a5,-1
    8000186a:	02f48a63          	beq	s1,a5,8000189e <print_list+0x60>
    printf(" %d,", curr);
    8000186e:	00007a97          	auipc	s5,0x7
    80001872:	972a8a93          	addi	s5,s5,-1678 # 800081e0 <digits+0x1a0>
    curr = proc[curr].next_index;
    80001876:	00010a17          	auipc	s4,0x10
    8000187a:	f1aa0a13          	addi	s4,s4,-230 # 80011790 <proc>
    8000187e:	17800993          	li	s3,376
  while(curr != -1){
    80001882:	597d                	li	s2,-1
    printf(" %d,", curr);
    80001884:	85a6                	mv	a1,s1
    80001886:	8556                	mv	a0,s5
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	d00080e7          	jalr	-768(ra) # 80000588 <printf>
    curr = proc[curr].next_index;
    80001890:	033484b3          	mul	s1,s1,s3
    80001894:	94d2                	add	s1,s1,s4
    80001896:	1744a483          	lw	s1,372(s1)
  while(curr != -1){
    8000189a:	ff2495e3          	bne	s1,s2,80001884 <print_list+0x46>
  }
  printf(" ]\n");
    8000189e:	00007517          	auipc	a0,0x7
    800018a2:	94a50513          	addi	a0,a0,-1718 # 800081e8 <digits+0x1a8>
    800018a6:	fffff097          	auipc	ra,0xfffff
    800018aa:	ce2080e7          	jalr	-798(ra) # 80000588 <printf>
}
    800018ae:	60a6                	ld	ra,72(sp)
    800018b0:	6406                	ld	s0,64(sp)
    800018b2:	74e2                	ld	s1,56(sp)
    800018b4:	7942                	ld	s2,48(sp)
    800018b6:	79a2                	ld	s3,40(sp)
    800018b8:	7a02                	ld	s4,32(sp)
    800018ba:	6ae2                	ld	s5,24(sp)
    800018bc:	6161                	addi	sp,sp,80
    800018be:	8082                	ret

00000000800018c0 <initialize_runnable_lists>:
    lst->head = p-> index;
  lst->head = -1;
  lst->tail = -1;
}*/

void initialize_runnable_lists(void){
    800018c0:	1141                	addi	sp,sp,-16
    800018c2:	e422                	sd	s0,8(sp)
    800018c4:	0800                	addi	s0,sp,16
  struct cpu *c;
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    800018c6:	00010797          	auipc	a5,0x10
    800018ca:	9da78793          	addi	a5,a5,-1574 # 800112a0 <cpus>
    c->runnable_list = (struct _list){-1, -1};
    800018ce:	577d                	li	a4,-1
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    800018d0:	00010697          	auipc	a3,0x10
    800018d4:	e9068693          	addi	a3,a3,-368 # 80011760 <pid_lock>
    c->runnable_list = (struct _list){-1, -1};
    800018d8:	08e7a023          	sw	a4,128(a5)
    800018dc:	08e7a223          	sw	a4,132(a5)
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    800018e0:	09878793          	addi	a5,a5,152
    800018e4:	fed79ae3          	bne	a5,a3,800018d8 <initialize_runnable_lists+0x18>
  }
}
    800018e8:	6422                	ld	s0,8(sp)
    800018ea:	0141                	addi	sp,sp,16
    800018ec:	8082                	ret

00000000800018ee <initialize_proc>:

void
initialize_proc(struct proc *p){
    800018ee:	1141                	addi	sp,sp,-16
    800018f0:	e422                	sd	s0,8(sp)
    800018f2:	0800                	addi	s0,sp,16
  proc->next_index = -1;
    800018f4:	00010797          	auipc	a5,0x10
    800018f8:	e9c78793          	addi	a5,a5,-356 # 80011790 <proc>
    800018fc:	577d                	li	a4,-1
    800018fe:	16e7aa23          	sw	a4,372(a5)
  proc->prev_index = -1;
    80001902:	16e7a823          	sw	a4,368(a5)
}
    80001906:	6422                	ld	s0,8(sp)
    80001908:	0141                	addi	sp,sp,16
    8000190a:	8082                	ret

000000008000190c <isEmpty>:

int
isEmpty(struct _list *lst){
    8000190c:	1141                	addi	sp,sp,-16
    8000190e:	e422                	sd	s0,8(sp)
    80001910:	0800                	addi	s0,sp,16
  return lst->head == -1;
    80001912:	4108                	lw	a0,0(a0)
    80001914:	0505                	addi	a0,a0,1
}
    80001916:	00153513          	seqz	a0,a0
    8000191a:	6422                	ld	s0,8(sp)
    8000191c:	0141                	addi	sp,sp,16
    8000191e:	8082                	ret

0000000080001920 <insert_proc_to_list>:

void 
insert_proc_to_list(struct _list *lst, struct proc *p){
    80001920:	7179                	addi	sp,sp,-48
    80001922:	f406                	sd	ra,40(sp)
    80001924:	f022                	sd	s0,32(sp)
    80001926:	ec26                	sd	s1,24(sp)
    80001928:	e84a                	sd	s2,16(sp)
    8000192a:	e44e                	sd	s3,8(sp)
    8000192c:	e052                	sd	s4,0(sp)
    8000192e:	1800                	addi	s0,sp,48
    80001930:	84aa                	mv	s1,a0
    80001932:	89ae                	mv	s3,a1
  printf("before insert: \n");
    80001934:	00007517          	auipc	a0,0x7
    80001938:	8bc50513          	addi	a0,a0,-1860 # 800081f0 <digits+0x1b0>
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	c4c080e7          	jalr	-948(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001944:	0004e503          	lwu	a0,0(s1)
    80001948:	0044e783          	lwu	a5,4(s1)
    8000194c:	1782                	slli	a5,a5,0x20
    8000194e:	8d5d                	or	a0,a0,a5
    80001950:	00000097          	auipc	ra,0x0
    80001954:	eee080e7          	jalr	-274(ra) # 8000183e <print_list>

  if(cas(&lst->tail, -1, p->index) == 0){ // if lst is empty
    80001958:	00448a13          	addi	s4,s1,4
    8000195c:	16c9a603          	lw	a2,364(s3) # 116c <_entry-0x7fffee94>
    80001960:	55fd                	li	a1,-1
    80001962:	8552                	mv	a0,s4
    80001964:	00005097          	auipc	ra,0x5
    80001968:	f32080e7          	jalr	-206(ra) # 80006896 <cas>
    8000196c:	2501                	sext.w	a0,a0
    8000196e:	e509                	bnez	a0,80001978 <insert_proc_to_list+0x58>
    lst->head = p->index; // the only option is to insert another process and change tail, changing head is safe now
    80001970:	16c9a783          	lw	a5,364(s3)
    80001974:	c09c                	sw	a5,0(s1)
    80001976:	a825                	j	800019ae <insert_proc_to_list+0x8e>
  }
  else {
    int curr_tail;
    struct proc *p_tail;
    do {
      p_tail = &proc[lst->tail];
    80001978:	0044a903          	lw	s2,4(s1)
      curr_tail = lst->tail;
    } while(cas(&lst->tail, curr_tail, p->index)); // try to update tail
    8000197c:	16c9a603          	lw	a2,364(s3)
    80001980:	85ca                	mv	a1,s2
    80001982:	8552                	mv	a0,s4
    80001984:	00005097          	auipc	ra,0x5
    80001988:	f12080e7          	jalr	-238(ra) # 80006896 <cas>
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	f56d                	bnez	a0,80001978 <insert_proc_to_list+0x58>
    p_tail->next_index = p->index; // update next proc of the curr tail
    80001990:	16c9a683          	lw	a3,364(s3)
    80001994:	17800793          	li	a5,376
    80001998:	02f90733          	mul	a4,s2,a5
    8000199c:	00010797          	auipc	a5,0x10
    800019a0:	df478793          	addi	a5,a5,-524 # 80011790 <proc>
    800019a4:	97ba                	add	a5,a5,a4
    800019a6:	16d7aa23          	sw	a3,372(a5)
    p->prev_index = curr_tail; // update the prev proc of the new proc
    800019aa:	1729a823          	sw	s2,368(s3)
  }
  printf("after insert: \n");
    800019ae:	00007517          	auipc	a0,0x7
    800019b2:	85a50513          	addi	a0,a0,-1958 # 80008208 <digits+0x1c8>
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	bd2080e7          	jalr	-1070(ra) # 80000588 <printf>
  print_list(*lst); // delete
    800019be:	0004e503          	lwu	a0,0(s1)
    800019c2:	0044e783          	lwu	a5,4(s1)
    800019c6:	1782                	slli	a5,a5,0x20
    800019c8:	8d5d                	or	a0,a0,a5
    800019ca:	00000097          	auipc	ra,0x0
    800019ce:	e74080e7          	jalr	-396(ra) # 8000183e <print_list>
}
    800019d2:	70a2                	ld	ra,40(sp)
    800019d4:	7402                	ld	s0,32(sp)
    800019d6:	64e2                	ld	s1,24(sp)
    800019d8:	6942                	ld	s2,16(sp)
    800019da:	69a2                	ld	s3,8(sp)
    800019dc:	6a02                	ld	s4,0(sp)
    800019de:	6145                	addi	sp,sp,48
    800019e0:	8082                	ret

00000000800019e2 <remove_proc_to_list>:

void 
remove_proc_to_list(struct _list *lst, struct proc *p){
    800019e2:	1101                	addi	sp,sp,-32
    800019e4:	ec06                	sd	ra,24(sp)
    800019e6:	e822                	sd	s0,16(sp)
    800019e8:	e426                	sd	s1,8(sp)
    800019ea:	e04a                	sd	s2,0(sp)
    800019ec:	1000                	addi	s0,sp,32
    800019ee:	892a                	mv	s2,a0
    800019f0:	84ae                	mv	s1,a1
  printf("before remove: \n");
    800019f2:	00007517          	auipc	a0,0x7
    800019f6:	82650513          	addi	a0,a0,-2010 # 80008218 <digits+0x1d8>
    800019fa:	fffff097          	auipc	ra,0xfffff
    800019fe:	b8e080e7          	jalr	-1138(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001a02:	00096503          	lwu	a0,0(s2) # 1000 <_entry-0x7ffff000>
    80001a06:	00496783          	lwu	a5,4(s2)
    80001a0a:	1782                	slli	a5,a5,0x20
    80001a0c:	8d5d                	or	a0,a0,a5
    80001a0e:	00000097          	auipc	ra,0x0
    80001a12:	e30080e7          	jalr	-464(ra) # 8000183e <print_list>
  if(cas(&lst->tail, p->index, p->prev_index) == 0 && p->prev_index != -1){ // case: p is the list's tail
    80001a16:	1704a603          	lw	a2,368(s1)
    80001a1a:	16c4a583          	lw	a1,364(s1)
    80001a1e:	00490513          	addi	a0,s2,4
    80001a22:	00005097          	auipc	ra,0x5
    80001a26:	e74080e7          	jalr	-396(ra) # 80006896 <cas>
    80001a2a:	2501                	sext.w	a0,a0
    80001a2c:	e511                	bnez	a0,80001a38 <remove_proc_to_list+0x56>
    80001a2e:	1704a703          	lw	a4,368(s1)
    80001a32:	57fd                	li	a5,-1
    80001a34:	02f71863          	bne	a4,a5,80001a64 <remove_proc_to_list+0x82>
    struct proc *p_new_tail = &proc[lst->tail];
    int curr_tail_next = p_new_tail->next_index;
    cas(&p_new_tail->next_index, curr_tail_next, -1);
  }
  if(cas(&lst->head, p->index, p->next_index) == 0 && p->next_index != -1){ // case: p is the list's head
    80001a38:	1744a603          	lw	a2,372(s1)
    80001a3c:	16c4a583          	lw	a1,364(s1)
    80001a40:	854a                	mv	a0,s2
    80001a42:	00005097          	auipc	ra,0x5
    80001a46:	e54080e7          	jalr	-428(ra) # 80006896 <cas>
    80001a4a:	2501                	sext.w	a0,a0
    80001a4c:	e92d                	bnez	a0,80001abe <remove_proc_to_list+0xdc>
    80001a4e:	1744a703          	lw	a4,372(s1)
    80001a52:	57fd                	li	a5,-1
    80001a54:	02f71f63          	bne	a4,a5,80001a92 <remove_proc_to_list+0xb0>
    struct proc *p_new_head = &proc[lst->head];
    int curr_head_prev = p_new_head->prev_index;
    cas(&p_new_head->prev_index, curr_head_prev, -1);
  }
  if(p->prev_index != -1){ // case: p is in the middle
    80001a58:	1704a783          	lw	a5,368(s1)
    80001a5c:	577d                	li	a4,-1
    80001a5e:	0ce78463          	beq	a5,a4,80001b26 <remove_proc_to_list+0x144>
    80001a62:	a09d                	j	80001ac8 <remove_proc_to_list+0xe6>
    struct proc *p_new_tail = &proc[lst->tail];
    80001a64:	00492783          	lw	a5,4(s2)
    int curr_tail_next = p_new_tail->next_index;
    80001a68:	00010517          	auipc	a0,0x10
    80001a6c:	d2850513          	addi	a0,a0,-728 # 80011790 <proc>
    80001a70:	17800713          	li	a4,376
    80001a74:	02e787b3          	mul	a5,a5,a4
    80001a78:	00f50733          	add	a4,a0,a5
    cas(&p_new_tail->next_index, curr_tail_next, -1);
    80001a7c:	17478793          	addi	a5,a5,372
    80001a80:	567d                	li	a2,-1
    80001a82:	17472583          	lw	a1,372(a4)
    80001a86:	953e                	add	a0,a0,a5
    80001a88:	00005097          	auipc	ra,0x5
    80001a8c:	e0e080e7          	jalr	-498(ra) # 80006896 <cas>
    80001a90:	b765                	j	80001a38 <remove_proc_to_list+0x56>
    struct proc *p_new_head = &proc[lst->head];
    80001a92:	00092783          	lw	a5,0(s2)
    int curr_head_prev = p_new_head->prev_index;
    80001a96:	00010517          	auipc	a0,0x10
    80001a9a:	cfa50513          	addi	a0,a0,-774 # 80011790 <proc>
    80001a9e:	17800713          	li	a4,376
    80001aa2:	02e787b3          	mul	a5,a5,a4
    80001aa6:	00f50733          	add	a4,a0,a5
    cas(&p_new_head->prev_index, curr_head_prev, -1);
    80001aaa:	17078793          	addi	a5,a5,368
    80001aae:	567d                	li	a2,-1
    80001ab0:	17072583          	lw	a1,368(a4)
    80001ab4:	953e                	add	a0,a0,a5
    80001ab6:	00005097          	auipc	ra,0x5
    80001aba:	de0080e7          	jalr	-544(ra) # 80006896 <cas>
  if(p->prev_index != -1){ // case: p is in the middle
    80001abe:	1704a783          	lw	a5,368(s1)
    80001ac2:	577d                	li	a4,-1
    80001ac4:	02e78763          	beq	a5,a4,80001af2 <remove_proc_to_list+0x110>
    int prev_next_index = proc[p->prev_index].next_index;
    80001ac8:	00010517          	auipc	a0,0x10
    80001acc:	cc850513          	addi	a0,a0,-824 # 80011790 <proc>
    80001ad0:	17800713          	li	a4,376
    80001ad4:	02e787b3          	mul	a5,a5,a4
    80001ad8:	00f50733          	add	a4,a0,a5
    cas(&proc[p->prev_index].next_index, prev_next_index, p->next_index);
    80001adc:	17478793          	addi	a5,a5,372
    80001ae0:	1744a603          	lw	a2,372(s1)
    80001ae4:	17472583          	lw	a1,372(a4)
    80001ae8:	953e                	add	a0,a0,a5
    80001aea:	00005097          	auipc	ra,0x5
    80001aee:	dac080e7          	jalr	-596(ra) # 80006896 <cas>
  }
  if(p->next_index != -1){
    80001af2:	1744a783          	lw	a5,372(s1)
    80001af6:	577d                	li	a4,-1
    80001af8:	02e78763          	beq	a5,a4,80001b26 <remove_proc_to_list+0x144>
    int next_prev_index = proc[p->next_index].prev_index;
    80001afc:	00010517          	auipc	a0,0x10
    80001b00:	c9450513          	addi	a0,a0,-876 # 80011790 <proc>
    80001b04:	17800713          	li	a4,376
    80001b08:	02e787b3          	mul	a5,a5,a4
    80001b0c:	00f50733          	add	a4,a0,a5
    cas(&proc[p->next_index].prev_index, next_prev_index, p->prev_index);
    80001b10:	17078793          	addi	a5,a5,368
    80001b14:	1704a603          	lw	a2,368(s1)
    80001b18:	17072583          	lw	a1,368(a4)
    80001b1c:	953e                	add	a0,a0,a5
    80001b1e:	00005097          	auipc	ra,0x5
    80001b22:	d78080e7          	jalr	-648(ra) # 80006896 <cas>
  proc->next_index = -1;
    80001b26:	00010797          	auipc	a5,0x10
    80001b2a:	c6a78793          	addi	a5,a5,-918 # 80011790 <proc>
    80001b2e:	577d                	li	a4,-1
    80001b30:	16e7aa23          	sw	a4,372(a5)
  proc->prev_index = -1;
    80001b34:	16e7a823          	sw	a4,368(a5)
  }
  initialize_proc(p);

  printf("after remove: \n");
    80001b38:	00006517          	auipc	a0,0x6
    80001b3c:	6f850513          	addi	a0,a0,1784 # 80008230 <digits+0x1f0>
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	a48080e7          	jalr	-1464(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001b48:	00096503          	lwu	a0,0(s2)
    80001b4c:	00496783          	lwu	a5,4(s2)
    80001b50:	1782                	slli	a5,a5,0x20
    80001b52:	8d5d                	or	a0,a0,a5
    80001b54:	00000097          	auipc	ra,0x0
    80001b58:	cea080e7          	jalr	-790(ra) # 8000183e <print_list>
}
    80001b5c:	60e2                	ld	ra,24(sp)
    80001b5e:	6442                	ld	s0,16(sp)
    80001b60:	64a2                	ld	s1,8(sp)
    80001b62:	6902                	ld	s2,0(sp)
    80001b64:	6105                	addi	sp,sp,32
    80001b66:	8082                	ret

0000000080001b68 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001b68:	7139                	addi	sp,sp,-64
    80001b6a:	fc06                	sd	ra,56(sp)
    80001b6c:	f822                	sd	s0,48(sp)
    80001b6e:	f426                	sd	s1,40(sp)
    80001b70:	f04a                	sd	s2,32(sp)
    80001b72:	ec4e                	sd	s3,24(sp)
    80001b74:	e852                	sd	s4,16(sp)
    80001b76:	e456                	sd	s5,8(sp)
    80001b78:	e05a                	sd	s6,0(sp)
    80001b7a:	0080                	addi	s0,sp,64
    80001b7c:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b7e:	00010497          	auipc	s1,0x10
    80001b82:	c1248493          	addi	s1,s1,-1006 # 80011790 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001b86:	8b26                	mv	s6,s1
    80001b88:	00006a97          	auipc	s5,0x6
    80001b8c:	478a8a93          	addi	s5,s5,1144 # 80008000 <etext>
    80001b90:	04000937          	lui	s2,0x4000
    80001b94:	197d                	addi	s2,s2,-1
    80001b96:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b98:	00016a17          	auipc	s4,0x16
    80001b9c:	9f8a0a13          	addi	s4,s4,-1544 # 80017590 <tickslock>
    char *pa = kalloc();
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	f54080e7          	jalr	-172(ra) # 80000af4 <kalloc>
    80001ba8:	862a                	mv	a2,a0
    if(pa == 0)
    80001baa:	c131                	beqz	a0,80001bee <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001bac:	416485b3          	sub	a1,s1,s6
    80001bb0:	858d                	srai	a1,a1,0x3
    80001bb2:	000ab783          	ld	a5,0(s5)
    80001bb6:	02f585b3          	mul	a1,a1,a5
    80001bba:	2585                	addiw	a1,a1,1
    80001bbc:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001bc0:	4719                	li	a4,6
    80001bc2:	6685                	lui	a3,0x1
    80001bc4:	40b905b3          	sub	a1,s2,a1
    80001bc8:	854e                	mv	a0,s3
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	586080e7          	jalr	1414(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd2:	17848493          	addi	s1,s1,376
    80001bd6:	fd4495e3          	bne	s1,s4,80001ba0 <proc_mapstacks+0x38>
  }
}
    80001bda:	70e2                	ld	ra,56(sp)
    80001bdc:	7442                	ld	s0,48(sp)
    80001bde:	74a2                	ld	s1,40(sp)
    80001be0:	7902                	ld	s2,32(sp)
    80001be2:	69e2                	ld	s3,24(sp)
    80001be4:	6a42                	ld	s4,16(sp)
    80001be6:	6aa2                	ld	s5,8(sp)
    80001be8:	6b02                	ld	s6,0(sp)
    80001bea:	6121                	addi	sp,sp,64
    80001bec:	8082                	ret
      panic("kalloc");
    80001bee:	00006517          	auipc	a0,0x6
    80001bf2:	65250513          	addi	a0,a0,1618 # 80008240 <digits+0x200>
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	948080e7          	jalr	-1720(ra) # 8000053e <panic>

0000000080001bfe <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001bfe:	711d                	addi	sp,sp,-96
    80001c00:	ec86                	sd	ra,88(sp)
    80001c02:	e8a2                	sd	s0,80(sp)
    80001c04:	e4a6                	sd	s1,72(sp)
    80001c06:	e0ca                	sd	s2,64(sp)
    80001c08:	fc4e                	sd	s3,56(sp)
    80001c0a:	f852                	sd	s4,48(sp)
    80001c0c:	f456                	sd	s5,40(sp)
    80001c0e:	f05a                	sd	s6,32(sp)
    80001c10:	ec5e                	sd	s7,24(sp)
    80001c12:	e862                	sd	s8,16(sp)
    80001c14:	e466                	sd	s9,8(sp)
    80001c16:	e06a                	sd	s10,0(sp)
    80001c18:	1080                	addi	s0,sp,96
  struct proc *p;

  initialize_runnable_lists();
    80001c1a:	00000097          	auipc	ra,0x0
    80001c1e:	ca6080e7          	jalr	-858(ra) # 800018c0 <initialize_runnable_lists>

  initlock(&pid_lock, "nextpid");
    80001c22:	00006597          	auipc	a1,0x6
    80001c26:	62658593          	addi	a1,a1,1574 # 80008248 <digits+0x208>
    80001c2a:	00010517          	auipc	a0,0x10
    80001c2e:	b3650513          	addi	a0,a0,-1226 # 80011760 <pid_lock>
    80001c32:	fffff097          	auipc	ra,0xfffff
    80001c36:	f22080e7          	jalr	-222(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001c3a:	00006597          	auipc	a1,0x6
    80001c3e:	61658593          	addi	a1,a1,1558 # 80008250 <digits+0x210>
    80001c42:	00010517          	auipc	a0,0x10
    80001c46:	b3650513          	addi	a0,a0,-1226 # 80011778 <wait_lock>
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	f0a080e7          	jalr	-246(ra) # 80000b54 <initlock>

  int i = 0;
    80001c52:	4981                	li	s3,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c54:	00010497          	auipc	s1,0x10
    80001c58:	b3c48493          	addi	s1,s1,-1220 # 80011790 <proc>
      initlock(&p->lock, "proc");
    80001c5c:	00006d17          	auipc	s10,0x6
    80001c60:	604d0d13          	addi	s10,s10,1540 # 80008260 <digits+0x220>
      p->kstack = KSTACK((int) (p - proc));
    80001c64:	8926                	mv	s2,s1
    80001c66:	00006c97          	auipc	s9,0x6
    80001c6a:	39ac8c93          	addi	s9,s9,922 # 80008000 <etext>
    80001c6e:	04000ab7          	lui	s5,0x4000
    80001c72:	1afd                	addi	s5,s5,-1
    80001c74:	0ab2                	slli	s5,s5,0xc
  proc->next_index = -1;
    80001c76:	5a7d                	li	s4,-1
      p->index = i;
      initialize_proc(p);
      printf("insert procinit unused %d\n", p->index); //delete
    80001c78:	00006c17          	auipc	s8,0x6
    80001c7c:	5f0c0c13          	addi	s8,s8,1520 # 80008268 <digits+0x228>
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001c80:	00007b97          	auipc	s7,0x7
    80001c84:	d98b8b93          	addi	s7,s7,-616 # 80008a18 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c88:	00016b17          	auipc	s6,0x16
    80001c8c:	908b0b13          	addi	s6,s6,-1784 # 80017590 <tickslock>
      initlock(&p->lock, "proc");
    80001c90:	85ea                	mv	a1,s10
    80001c92:	8526                	mv	a0,s1
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	ec0080e7          	jalr	-320(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001c9c:	412487b3          	sub	a5,s1,s2
    80001ca0:	878d                	srai	a5,a5,0x3
    80001ca2:	000cb703          	ld	a4,0(s9)
    80001ca6:	02e787b3          	mul	a5,a5,a4
    80001caa:	2785                	addiw	a5,a5,1
    80001cac:	00d7979b          	slliw	a5,a5,0xd
    80001cb0:	40fa87b3          	sub	a5,s5,a5
    80001cb4:	e0bc                	sd	a5,64(s1)
      p->index = i;
    80001cb6:	1734a623          	sw	s3,364(s1)
  proc->next_index = -1;
    80001cba:	17492a23          	sw	s4,372(s2) # 4000174 <_entry-0x7bfffe8c>
  proc->prev_index = -1;
    80001cbe:	17492823          	sw	s4,368(s2)
      printf("insert procinit unused %d\n", p->index); //delete
    80001cc2:	16c4a583          	lw	a1,364(s1)
    80001cc6:	8562                	mv	a0,s8
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	8c0080e7          	jalr	-1856(ra) # 80000588 <printf>
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001cd0:	85a6                	mv	a1,s1
    80001cd2:	855e                	mv	a0,s7
    80001cd4:	00000097          	auipc	ra,0x0
    80001cd8:	c4c080e7          	jalr	-948(ra) # 80001920 <insert_proc_to_list>
      i++;
    80001cdc:	2985                	addiw	s3,s3,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cde:	17848493          	addi	s1,s1,376
    80001ce2:	fb6497e3          	bne	s1,s6,80001c90 <procinit+0x92>
  }
}
    80001ce6:	60e6                	ld	ra,88(sp)
    80001ce8:	6446                	ld	s0,80(sp)
    80001cea:	64a6                	ld	s1,72(sp)
    80001cec:	6906                	ld	s2,64(sp)
    80001cee:	79e2                	ld	s3,56(sp)
    80001cf0:	7a42                	ld	s4,48(sp)
    80001cf2:	7aa2                	ld	s5,40(sp)
    80001cf4:	7b02                	ld	s6,32(sp)
    80001cf6:	6be2                	ld	s7,24(sp)
    80001cf8:	6c42                	ld	s8,16(sp)
    80001cfa:	6ca2                	ld	s9,8(sp)
    80001cfc:	6d02                	ld	s10,0(sp)
    80001cfe:	6125                	addi	sp,sp,96
    80001d00:	8082                	ret

0000000080001d02 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001d02:	1141                	addi	sp,sp,-16
    80001d04:	e422                	sd	s0,8(sp)
    80001d06:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d08:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001d0a:	2501                	sext.w	a0,a0
    80001d0c:	6422                	ld	s0,8(sp)
    80001d0e:	0141                	addi	sp,sp,16
    80001d10:	8082                	ret

0000000080001d12 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001d12:	1141                	addi	sp,sp,-16
    80001d14:	e422                	sd	s0,8(sp)
    80001d16:	0800                	addi	s0,sp,16
    80001d18:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001d1a:	2781                	sext.w	a5,a5
    80001d1c:	09800513          	li	a0,152
    80001d20:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001d24:	0000f517          	auipc	a0,0xf
    80001d28:	57c50513          	addi	a0,a0,1404 # 800112a0 <cpus>
    80001d2c:	953e                	add	a0,a0,a5
    80001d2e:	6422                	ld	s0,8(sp)
    80001d30:	0141                	addi	sp,sp,16
    80001d32:	8082                	ret

0000000080001d34 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001d34:	1101                	addi	sp,sp,-32
    80001d36:	ec06                	sd	ra,24(sp)
    80001d38:	e822                	sd	s0,16(sp)
    80001d3a:	e426                	sd	s1,8(sp)
    80001d3c:	1000                	addi	s0,sp,32
  push_off();
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	e5a080e7          	jalr	-422(ra) # 80000b98 <push_off>
    80001d46:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001d48:	2781                	sext.w	a5,a5
    80001d4a:	09800713          	li	a4,152
    80001d4e:	02e787b3          	mul	a5,a5,a4
    80001d52:	0000f717          	auipc	a4,0xf
    80001d56:	54e70713          	addi	a4,a4,1358 # 800112a0 <cpus>
    80001d5a:	97ba                	add	a5,a5,a4
    80001d5c:	6384                	ld	s1,0(a5)
  pop_off();
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	eda080e7          	jalr	-294(ra) # 80000c38 <pop_off>
  return p;
}
    80001d66:	8526                	mv	a0,s1
    80001d68:	60e2                	ld	ra,24(sp)
    80001d6a:	6442                	ld	s0,16(sp)
    80001d6c:	64a2                	ld	s1,8(sp)
    80001d6e:	6105                	addi	sp,sp,32
    80001d70:	8082                	ret

0000000080001d72 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001d72:	1141                	addi	sp,sp,-16
    80001d74:	e406                	sd	ra,8(sp)
    80001d76:	e022                	sd	s0,0(sp)
    80001d78:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	fba080e7          	jalr	-70(ra) # 80001d34 <myproc>
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	f16080e7          	jalr	-234(ra) # 80000c98 <release>

  if (first) {
    80001d8a:	00007797          	auipc	a5,0x7
    80001d8e:	c767a783          	lw	a5,-906(a5) # 80008a00 <first.1759>
    80001d92:	eb89                	bnez	a5,80001da4 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001d94:	00001097          	auipc	ra,0x1
    80001d98:	f42080e7          	jalr	-190(ra) # 80002cd6 <usertrapret>
}
    80001d9c:	60a2                	ld	ra,8(sp)
    80001d9e:	6402                	ld	s0,0(sp)
    80001da0:	0141                	addi	sp,sp,16
    80001da2:	8082                	ret
    first = 0;
    80001da4:	00007797          	auipc	a5,0x7
    80001da8:	c407ae23          	sw	zero,-932(a5) # 80008a00 <first.1759>
    fsinit(ROOTDEV);
    80001dac:	4505                	li	a0,1
    80001dae:	00002097          	auipc	ra,0x2
    80001db2:	ce6080e7          	jalr	-794(ra) # 80003a94 <fsinit>
    80001db6:	bff9                	j	80001d94 <forkret+0x22>

0000000080001db8 <allocpid>:
allocpid() {
    80001db8:	1101                	addi	sp,sp,-32
    80001dba:	ec06                	sd	ra,24(sp)
    80001dbc:	e822                	sd	s0,16(sp)
    80001dbe:	e426                	sd	s1,8(sp)
    80001dc0:	e04a                	sd	s2,0(sp)
    80001dc2:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001dc4:	00007917          	auipc	s2,0x7
    80001dc8:	c5c90913          	addi	s2,s2,-932 # 80008a20 <nextpid>
    80001dcc:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, nextpid + 1));
    80001dd0:	0014861b          	addiw	a2,s1,1
    80001dd4:	85a6                	mv	a1,s1
    80001dd6:	854a                	mv	a0,s2
    80001dd8:	00005097          	auipc	ra,0x5
    80001ddc:	abe080e7          	jalr	-1346(ra) # 80006896 <cas>
    80001de0:	2501                	sext.w	a0,a0
    80001de2:	f56d                	bnez	a0,80001dcc <allocpid+0x14>
}
    80001de4:	8526                	mv	a0,s1
    80001de6:	60e2                	ld	ra,24(sp)
    80001de8:	6442                	ld	s0,16(sp)
    80001dea:	64a2                	ld	s1,8(sp)
    80001dec:	6902                	ld	s2,0(sp)
    80001dee:	6105                	addi	sp,sp,32
    80001df0:	8082                	ret

0000000080001df2 <proc_pagetable>:
{
    80001df2:	1101                	addi	sp,sp,-32
    80001df4:	ec06                	sd	ra,24(sp)
    80001df6:	e822                	sd	s0,16(sp)
    80001df8:	e426                	sd	s1,8(sp)
    80001dfa:	e04a                	sd	s2,0(sp)
    80001dfc:	1000                	addi	s0,sp,32
    80001dfe:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	53a080e7          	jalr	1338(ra) # 8000133a <uvmcreate>
    80001e08:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001e0a:	c121                	beqz	a0,80001e4a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e0c:	4729                	li	a4,10
    80001e0e:	00005697          	auipc	a3,0x5
    80001e12:	1f268693          	addi	a3,a3,498 # 80007000 <_trampoline>
    80001e16:	6605                	lui	a2,0x1
    80001e18:	040005b7          	lui	a1,0x4000
    80001e1c:	15fd                	addi	a1,a1,-1
    80001e1e:	05b2                	slli	a1,a1,0xc
    80001e20:	fffff097          	auipc	ra,0xfffff
    80001e24:	290080e7          	jalr	656(ra) # 800010b0 <mappages>
    80001e28:	02054863          	bltz	a0,80001e58 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e2c:	4719                	li	a4,6
    80001e2e:	05893683          	ld	a3,88(s2)
    80001e32:	6605                	lui	a2,0x1
    80001e34:	020005b7          	lui	a1,0x2000
    80001e38:	15fd                	addi	a1,a1,-1
    80001e3a:	05b6                	slli	a1,a1,0xd
    80001e3c:	8526                	mv	a0,s1
    80001e3e:	fffff097          	auipc	ra,0xfffff
    80001e42:	272080e7          	jalr	626(ra) # 800010b0 <mappages>
    80001e46:	02054163          	bltz	a0,80001e68 <proc_pagetable+0x76>
}
    80001e4a:	8526                	mv	a0,s1
    80001e4c:	60e2                	ld	ra,24(sp)
    80001e4e:	6442                	ld	s0,16(sp)
    80001e50:	64a2                	ld	s1,8(sp)
    80001e52:	6902                	ld	s2,0(sp)
    80001e54:	6105                	addi	sp,sp,32
    80001e56:	8082                	ret
    uvmfree(pagetable, 0);
    80001e58:	4581                	li	a1,0
    80001e5a:	8526                	mv	a0,s1
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	6da080e7          	jalr	1754(ra) # 80001536 <uvmfree>
    return 0;
    80001e64:	4481                	li	s1,0
    80001e66:	b7d5                	j	80001e4a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e68:	4681                	li	a3,0
    80001e6a:	4605                	li	a2,1
    80001e6c:	040005b7          	lui	a1,0x4000
    80001e70:	15fd                	addi	a1,a1,-1
    80001e72:	05b2                	slli	a1,a1,0xc
    80001e74:	8526                	mv	a0,s1
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	400080e7          	jalr	1024(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e7e:	4581                	li	a1,0
    80001e80:	8526                	mv	a0,s1
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	6b4080e7          	jalr	1716(ra) # 80001536 <uvmfree>
    return 0;
    80001e8a:	4481                	li	s1,0
    80001e8c:	bf7d                	j	80001e4a <proc_pagetable+0x58>

0000000080001e8e <proc_freepagetable>:
{
    80001e8e:	1101                	addi	sp,sp,-32
    80001e90:	ec06                	sd	ra,24(sp)
    80001e92:	e822                	sd	s0,16(sp)
    80001e94:	e426                	sd	s1,8(sp)
    80001e96:	e04a                	sd	s2,0(sp)
    80001e98:	1000                	addi	s0,sp,32
    80001e9a:	84aa                	mv	s1,a0
    80001e9c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e9e:	4681                	li	a3,0
    80001ea0:	4605                	li	a2,1
    80001ea2:	040005b7          	lui	a1,0x4000
    80001ea6:	15fd                	addi	a1,a1,-1
    80001ea8:	05b2                	slli	a1,a1,0xc
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	3cc080e7          	jalr	972(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001eb2:	4681                	li	a3,0
    80001eb4:	4605                	li	a2,1
    80001eb6:	020005b7          	lui	a1,0x2000
    80001eba:	15fd                	addi	a1,a1,-1
    80001ebc:	05b6                	slli	a1,a1,0xd
    80001ebe:	8526                	mv	a0,s1
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	3b6080e7          	jalr	950(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ec8:	85ca                	mv	a1,s2
    80001eca:	8526                	mv	a0,s1
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	66a080e7          	jalr	1642(ra) # 80001536 <uvmfree>
}
    80001ed4:	60e2                	ld	ra,24(sp)
    80001ed6:	6442                	ld	s0,16(sp)
    80001ed8:	64a2                	ld	s1,8(sp)
    80001eda:	6902                	ld	s2,0(sp)
    80001edc:	6105                	addi	sp,sp,32
    80001ede:	8082                	ret

0000000080001ee0 <freeproc>:
{
    80001ee0:	1101                	addi	sp,sp,-32
    80001ee2:	ec06                	sd	ra,24(sp)
    80001ee4:	e822                	sd	s0,16(sp)
    80001ee6:	e426                	sd	s1,8(sp)
    80001ee8:	1000                	addi	s0,sp,32
    80001eea:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001eec:	6d28                	ld	a0,88(a0)
    80001eee:	c509                	beqz	a0,80001ef8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	b08080e7          	jalr	-1272(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001ef8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001efc:	68a8                	ld	a0,80(s1)
    80001efe:	c511                	beqz	a0,80001f0a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001f00:	64ac                	ld	a1,72(s1)
    80001f02:	00000097          	auipc	ra,0x0
    80001f06:	f8c080e7          	jalr	-116(ra) # 80001e8e <proc_freepagetable>
  p->pagetable = 0;
    80001f0a:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001f0e:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001f12:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001f16:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001f1a:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001f1e:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001f22:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001f26:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001f2a:	0004ac23          	sw	zero,24(s1)
  printf("remove free proc zombie %d\n", p->index); //delete
    80001f2e:	16c4a583          	lw	a1,364(s1)
    80001f32:	00006517          	auipc	a0,0x6
    80001f36:	35650513          	addi	a0,a0,854 # 80008288 <digits+0x248>
    80001f3a:	ffffe097          	auipc	ra,0xffffe
    80001f3e:	64e080e7          	jalr	1614(ra) # 80000588 <printf>
  remove_proc_to_list(&zombie_list, p); // remove the freed process from the ZOMBIE list
    80001f42:	85a6                	mv	a1,s1
    80001f44:	00007517          	auipc	a0,0x7
    80001f48:	ac450513          	addi	a0,a0,-1340 # 80008a08 <zombie_list>
    80001f4c:	00000097          	auipc	ra,0x0
    80001f50:	a96080e7          	jalr	-1386(ra) # 800019e2 <remove_proc_to_list>
  printf("insert free proc unused %d\n", p->index); //delete
    80001f54:	16c4a583          	lw	a1,364(s1)
    80001f58:	00006517          	auipc	a0,0x6
    80001f5c:	35050513          	addi	a0,a0,848 # 800082a8 <digits+0x268>
    80001f60:	ffffe097          	auipc	ra,0xffffe
    80001f64:	628080e7          	jalr	1576(ra) # 80000588 <printf>
  insert_proc_to_list(&unused_list, p); // admit its entry to the UNUSED entry list.
    80001f68:	85a6                	mv	a1,s1
    80001f6a:	00007517          	auipc	a0,0x7
    80001f6e:	aae50513          	addi	a0,a0,-1362 # 80008a18 <unused_list>
    80001f72:	00000097          	auipc	ra,0x0
    80001f76:	9ae080e7          	jalr	-1618(ra) # 80001920 <insert_proc_to_list>
}
    80001f7a:	60e2                	ld	ra,24(sp)
    80001f7c:	6442                	ld	s0,16(sp)
    80001f7e:	64a2                	ld	s1,8(sp)
    80001f80:	6105                	addi	sp,sp,32
    80001f82:	8082                	ret

0000000080001f84 <allocproc>:
{
    80001f84:	1101                	addi	sp,sp,-32
    80001f86:	ec06                	sd	ra,24(sp)
    80001f88:	e822                	sd	s0,16(sp)
    80001f8a:	e426                	sd	s1,8(sp)
    80001f8c:	e04a                	sd	s2,0(sp)
    80001f8e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f90:	00010497          	auipc	s1,0x10
    80001f94:	80048493          	addi	s1,s1,-2048 # 80011790 <proc>
    80001f98:	00015917          	auipc	s2,0x15
    80001f9c:	5f890913          	addi	s2,s2,1528 # 80017590 <tickslock>
    acquire(&p->lock);
    80001fa0:	8526                	mv	a0,s1
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	c42080e7          	jalr	-958(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001faa:	4c9c                	lw	a5,24(s1)
    80001fac:	cf81                	beqz	a5,80001fc4 <allocproc+0x40>
      release(&p->lock);
    80001fae:	8526                	mv	a0,s1
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	ce8080e7          	jalr	-792(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fb8:	17848493          	addi	s1,s1,376
    80001fbc:	ff2492e3          	bne	s1,s2,80001fa0 <allocproc+0x1c>
  return 0;
    80001fc0:	4481                	li	s1,0
    80001fc2:	a8a5                	j	8000203a <allocproc+0xb6>
      printf("remove allocproc unused %d\n", p->index); //delete
    80001fc4:	16c4a583          	lw	a1,364(s1)
    80001fc8:	00006517          	auipc	a0,0x6
    80001fcc:	30050513          	addi	a0,a0,768 # 800082c8 <digits+0x288>
    80001fd0:	ffffe097          	auipc	ra,0xffffe
    80001fd4:	5b8080e7          	jalr	1464(ra) # 80000588 <printf>
      remove_proc_to_list(&unused_list, p); // choose the new process entry to initialize from the UNUSED entry list.
    80001fd8:	85a6                	mv	a1,s1
    80001fda:	00007517          	auipc	a0,0x7
    80001fde:	a3e50513          	addi	a0,a0,-1474 # 80008a18 <unused_list>
    80001fe2:	00000097          	auipc	ra,0x0
    80001fe6:	a00080e7          	jalr	-1536(ra) # 800019e2 <remove_proc_to_list>
  p->pid = allocpid();
    80001fea:	00000097          	auipc	ra,0x0
    80001fee:	dce080e7          	jalr	-562(ra) # 80001db8 <allocpid>
    80001ff2:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ff4:	4785                	li	a5,1
    80001ff6:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ff8:	fffff097          	auipc	ra,0xfffff
    80001ffc:	afc080e7          	jalr	-1284(ra) # 80000af4 <kalloc>
    80002000:	892a                	mv	s2,a0
    80002002:	eca8                	sd	a0,88(s1)
    80002004:	c131                	beqz	a0,80002048 <allocproc+0xc4>
  p->pagetable = proc_pagetable(p);
    80002006:	8526                	mv	a0,s1
    80002008:	00000097          	auipc	ra,0x0
    8000200c:	dea080e7          	jalr	-534(ra) # 80001df2 <proc_pagetable>
    80002010:	892a                	mv	s2,a0
    80002012:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80002014:	c531                	beqz	a0,80002060 <allocproc+0xdc>
  memset(&p->context, 0, sizeof(p->context));
    80002016:	07000613          	li	a2,112
    8000201a:	4581                	li	a1,0
    8000201c:	06048513          	addi	a0,s1,96
    80002020:	fffff097          	auipc	ra,0xfffff
    80002024:	cc0080e7          	jalr	-832(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80002028:	00000797          	auipc	a5,0x0
    8000202c:	d4a78793          	addi	a5,a5,-694 # 80001d72 <forkret>
    80002030:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002032:	60bc                	ld	a5,64(s1)
    80002034:	6705                	lui	a4,0x1
    80002036:	97ba                	add	a5,a5,a4
    80002038:	f4bc                	sd	a5,104(s1)
}
    8000203a:	8526                	mv	a0,s1
    8000203c:	60e2                	ld	ra,24(sp)
    8000203e:	6442                	ld	s0,16(sp)
    80002040:	64a2                	ld	s1,8(sp)
    80002042:	6902                	ld	s2,0(sp)
    80002044:	6105                	addi	sp,sp,32
    80002046:	8082                	ret
    freeproc(p);
    80002048:	8526                	mv	a0,s1
    8000204a:	00000097          	auipc	ra,0x0
    8000204e:	e96080e7          	jalr	-362(ra) # 80001ee0 <freeproc>
    release(&p->lock);
    80002052:	8526                	mv	a0,s1
    80002054:	fffff097          	auipc	ra,0xfffff
    80002058:	c44080e7          	jalr	-956(ra) # 80000c98 <release>
    return 0;
    8000205c:	84ca                	mv	s1,s2
    8000205e:	bff1                	j	8000203a <allocproc+0xb6>
    freeproc(p);
    80002060:	8526                	mv	a0,s1
    80002062:	00000097          	auipc	ra,0x0
    80002066:	e7e080e7          	jalr	-386(ra) # 80001ee0 <freeproc>
    release(&p->lock);
    8000206a:	8526                	mv	a0,s1
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	c2c080e7          	jalr	-980(ra) # 80000c98 <release>
    return 0;
    80002074:	84ca                	mv	s1,s2
    80002076:	b7d1                	j	8000203a <allocproc+0xb6>

0000000080002078 <userinit>:
{
    80002078:	1101                	addi	sp,sp,-32
    8000207a:	ec06                	sd	ra,24(sp)
    8000207c:	e822                	sd	s0,16(sp)
    8000207e:	e426                	sd	s1,8(sp)
    80002080:	1000                	addi	s0,sp,32
  p = allocproc();
    80002082:	00000097          	auipc	ra,0x0
    80002086:	f02080e7          	jalr	-254(ra) # 80001f84 <allocproc>
    8000208a:	84aa                	mv	s1,a0
  initproc = p;
    8000208c:	00007797          	auipc	a5,0x7
    80002090:	f8a7be23          	sd	a0,-100(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002094:	03400613          	li	a2,52
    80002098:	00007597          	auipc	a1,0x7
    8000209c:	99858593          	addi	a1,a1,-1640 # 80008a30 <initcode>
    800020a0:	6928                	ld	a0,80(a0)
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	2c6080e7          	jalr	710(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    800020aa:	6785                	lui	a5,0x1
    800020ac:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    800020ae:	6cb8                	ld	a4,88(s1)
    800020b0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800020b4:	6cb8                	ld	a4,88(s1)
    800020b6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800020b8:	4641                	li	a2,16
    800020ba:	00006597          	auipc	a1,0x6
    800020be:	22e58593          	addi	a1,a1,558 # 800082e8 <digits+0x2a8>
    800020c2:	15848513          	addi	a0,s1,344
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	d6c080e7          	jalr	-660(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800020ce:	00006517          	auipc	a0,0x6
    800020d2:	22a50513          	addi	a0,a0,554 # 800082f8 <digits+0x2b8>
    800020d6:	00002097          	auipc	ra,0x2
    800020da:	3ec080e7          	jalr	1004(ra) # 800044c2 <namei>
    800020de:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800020e2:	478d                	li	a5,3
    800020e4:	cc9c                	sw	a5,24(s1)
  printf("insert userinit runnable %d\n", p->index); //delete
    800020e6:	16c4a583          	lw	a1,364(s1)
    800020ea:	00006517          	auipc	a0,0x6
    800020ee:	21650513          	addi	a0,a0,534 # 80008300 <digits+0x2c0>
    800020f2:	ffffe097          	auipc	ra,0xffffe
    800020f6:	496080e7          	jalr	1174(ra) # 80000588 <printf>
  insert_proc_to_list(&(cpus[0].runnable_list), p); // admit the init process (the first process in the OS) to the first CPU’s list.
    800020fa:	85a6                	mv	a1,s1
    800020fc:	0000f517          	auipc	a0,0xf
    80002100:	22450513          	addi	a0,a0,548 # 80011320 <cpus+0x80>
    80002104:	00000097          	auipc	ra,0x0
    80002108:	81c080e7          	jalr	-2020(ra) # 80001920 <insert_proc_to_list>
  release(&p->lock);
    8000210c:	8526                	mv	a0,s1
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	b8a080e7          	jalr	-1142(ra) # 80000c98 <release>
}
    80002116:	60e2                	ld	ra,24(sp)
    80002118:	6442                	ld	s0,16(sp)
    8000211a:	64a2                	ld	s1,8(sp)
    8000211c:	6105                	addi	sp,sp,32
    8000211e:	8082                	ret

0000000080002120 <growproc>:
{
    80002120:	1101                	addi	sp,sp,-32
    80002122:	ec06                	sd	ra,24(sp)
    80002124:	e822                	sd	s0,16(sp)
    80002126:	e426                	sd	s1,8(sp)
    80002128:	e04a                	sd	s2,0(sp)
    8000212a:	1000                	addi	s0,sp,32
    8000212c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000212e:	00000097          	auipc	ra,0x0
    80002132:	c06080e7          	jalr	-1018(ra) # 80001d34 <myproc>
    80002136:	892a                	mv	s2,a0
  sz = p->sz;
    80002138:	652c                	ld	a1,72(a0)
    8000213a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000213e:	00904f63          	bgtz	s1,8000215c <growproc+0x3c>
  } else if(n < 0){
    80002142:	0204cc63          	bltz	s1,8000217a <growproc+0x5a>
  p->sz = sz;
    80002146:	1602                	slli	a2,a2,0x20
    80002148:	9201                	srli	a2,a2,0x20
    8000214a:	04c93423          	sd	a2,72(s2)
  return 0;
    8000214e:	4501                	li	a0,0
}
    80002150:	60e2                	ld	ra,24(sp)
    80002152:	6442                	ld	s0,16(sp)
    80002154:	64a2                	ld	s1,8(sp)
    80002156:	6902                	ld	s2,0(sp)
    80002158:	6105                	addi	sp,sp,32
    8000215a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000215c:	9e25                	addw	a2,a2,s1
    8000215e:	1602                	slli	a2,a2,0x20
    80002160:	9201                	srli	a2,a2,0x20
    80002162:	1582                	slli	a1,a1,0x20
    80002164:	9181                	srli	a1,a1,0x20
    80002166:	6928                	ld	a0,80(a0)
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	2ba080e7          	jalr	698(ra) # 80001422 <uvmalloc>
    80002170:	0005061b          	sext.w	a2,a0
    80002174:	fa69                	bnez	a2,80002146 <growproc+0x26>
      return -1;
    80002176:	557d                	li	a0,-1
    80002178:	bfe1                	j	80002150 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000217a:	9e25                	addw	a2,a2,s1
    8000217c:	1602                	slli	a2,a2,0x20
    8000217e:	9201                	srli	a2,a2,0x20
    80002180:	1582                	slli	a1,a1,0x20
    80002182:	9181                	srli	a1,a1,0x20
    80002184:	6928                	ld	a0,80(a0)
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	254080e7          	jalr	596(ra) # 800013da <uvmdealloc>
    8000218e:	0005061b          	sext.w	a2,a0
    80002192:	bf55                	j	80002146 <growproc+0x26>

0000000080002194 <scheduler>:
{
    80002194:	7159                	addi	sp,sp,-112
    80002196:	f486                	sd	ra,104(sp)
    80002198:	f0a2                	sd	s0,96(sp)
    8000219a:	eca6                	sd	s1,88(sp)
    8000219c:	e8ca                	sd	s2,80(sp)
    8000219e:	e4ce                	sd	s3,72(sp)
    800021a0:	e0d2                	sd	s4,64(sp)
    800021a2:	fc56                	sd	s5,56(sp)
    800021a4:	f85a                	sd	s6,48(sp)
    800021a6:	f45e                	sd	s7,40(sp)
    800021a8:	f062                	sd	s8,32(sp)
    800021aa:	ec66                	sd	s9,24(sp)
    800021ac:	e86a                	sd	s10,16(sp)
    800021ae:	e46e                	sd	s11,8(sp)
    800021b0:	1880                	addi	s0,sp,112
    800021b2:	8712                	mv	a4,tp
  int id = r_tp();
    800021b4:	2701                	sext.w	a4,a4
  c->proc = 0;
    800021b6:	0000fc97          	auipc	s9,0xf
    800021ba:	0eac8c93          	addi	s9,s9,234 # 800112a0 <cpus>
    800021be:	09800793          	li	a5,152
    800021c2:	02f707b3          	mul	a5,a4,a5
    800021c6:	00fc86b3          	add	a3,s9,a5
    800021ca:	0006b023          	sd	zero,0(a3)
    if(!isEmpty(&(c->runnable_list))) { // check whether there is a ready process in the cpu
    800021ce:	08078d13          	addi	s10,a5,128 # 1080 <_entry-0x7fffef80>
    800021d2:	9d66                	add	s10,s10,s9
        swtch(&c->context, &p->context);
    800021d4:	07a1                	addi	a5,a5,8
    800021d6:	9cbe                	add	s9,s9,a5
  return lst->head == -1;
    800021d8:	8ab6                	mv	s5,a3
    if(!isEmpty(&(c->runnable_list))) { // check whether there is a ready process in the cpu
    800021da:	597d                	li	s2,-1
    800021dc:	17800b93          	li	s7,376
      p =  &proc[c->runnable_list.head]; //  pick the first process from the correct CPU’s list.
    800021e0:	0000fb17          	auipc	s6,0xf
    800021e4:	5b0b0b13          	addi	s6,s6,1456 # 80011790 <proc>
      if(p->state == RUNNABLE) {  
    800021e8:	4c0d                	li	s8,3
        p->state = RUNNING;
    800021ea:	4d91                	li	s11,4
    800021ec:	a031                	j	800021f8 <scheduler+0x64>
      release(&p->lock);
    800021ee:	854e                	mv	a0,s3
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	aa8080e7          	jalr	-1368(ra) # 80000c98 <release>
  return lst->head == -1;
    800021f8:	080aa483          	lw	s1,128(s5) # 4000080 <_entry-0x7bffff80>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021fc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002200:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002204:	10079073          	csrw	sstatus,a5
    if(!isEmpty(&(c->runnable_list))) { // check whether there is a ready process in the cpu
    80002208:	ff248ae3          	beq	s1,s2,800021fc <scheduler+0x68>
      p =  &proc[c->runnable_list.head]; //  pick the first process from the correct CPU’s list.
    8000220c:	03748a33          	mul	s4,s1,s7
    80002210:	016a09b3          	add	s3,s4,s6
      acquire(&p->lock);
    80002214:	854e                	mv	a0,s3
    80002216:	fffff097          	auipc	ra,0xfffff
    8000221a:	9ce080e7          	jalr	-1586(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {  
    8000221e:	0189a783          	lw	a5,24(s3)
    80002222:	fd8796e3          	bne	a5,s8,800021ee <scheduler+0x5a>
        p->state = RUNNING;
    80002226:	01b9ac23          	sw	s11,24(s3)
        c->proc = p;
    8000222a:	013ab023          	sd	s3,0(s5)
        p->last_cpu = c->cpu_id;
    8000222e:	088aa783          	lw	a5,136(s5)
    80002232:	16f9a423          	sw	a5,360(s3)
        printf("remove sched runnable %d\n", p->index); //delete
    80002236:	16c9a583          	lw	a1,364(s3)
    8000223a:	00006517          	auipc	a0,0x6
    8000223e:	0e650513          	addi	a0,a0,230 # 80008320 <digits+0x2e0>
    80002242:	ffffe097          	auipc	ra,0xffffe
    80002246:	346080e7          	jalr	838(ra) # 80000588 <printf>
        remove_proc_to_list(&(c->runnable_list), p);
    8000224a:	85ce                	mv	a1,s3
    8000224c:	856a                	mv	a0,s10
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	794080e7          	jalr	1940(ra) # 800019e2 <remove_proc_to_list>
        swtch(&c->context, &p->context);
    80002256:	060a0593          	addi	a1,s4,96
    8000225a:	95da                	add	a1,a1,s6
    8000225c:	8566                	mv	a0,s9
    8000225e:	00001097          	auipc	ra,0x1
    80002262:	9ce080e7          	jalr	-1586(ra) # 80002c2c <swtch>
        c->proc = 0;
    80002266:	000ab023          	sd	zero,0(s5)
    8000226a:	b751                	j	800021ee <scheduler+0x5a>

000000008000226c <sched>:
{
    8000226c:	7179                	addi	sp,sp,-48
    8000226e:	f406                	sd	ra,40(sp)
    80002270:	f022                	sd	s0,32(sp)
    80002272:	ec26                	sd	s1,24(sp)
    80002274:	e84a                	sd	s2,16(sp)
    80002276:	e44e                	sd	s3,8(sp)
    80002278:	e052                	sd	s4,0(sp)
    8000227a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000227c:	00000097          	auipc	ra,0x0
    80002280:	ab8080e7          	jalr	-1352(ra) # 80001d34 <myproc>
    80002284:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	8e4080e7          	jalr	-1820(ra) # 80000b6a <holding>
    8000228e:	c141                	beqz	a0,8000230e <sched+0xa2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002290:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002292:	2781                	sext.w	a5,a5
    80002294:	09800713          	li	a4,152
    80002298:	02e787b3          	mul	a5,a5,a4
    8000229c:	0000f717          	auipc	a4,0xf
    800022a0:	00470713          	addi	a4,a4,4 # 800112a0 <cpus>
    800022a4:	97ba                	add	a5,a5,a4
    800022a6:	5fb8                	lw	a4,120(a5)
    800022a8:	4785                	li	a5,1
    800022aa:	06f71a63          	bne	a4,a5,8000231e <sched+0xb2>
  if(p->state == RUNNING)
    800022ae:	4c98                	lw	a4,24(s1)
    800022b0:	4791                	li	a5,4
    800022b2:	06f70e63          	beq	a4,a5,8000232e <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022b6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022ba:	8b89                	andi	a5,a5,2
  if(intr_get())
    800022bc:	e3c9                	bnez	a5,8000233e <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022be:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022c0:	0000f917          	auipc	s2,0xf
    800022c4:	fe090913          	addi	s2,s2,-32 # 800112a0 <cpus>
    800022c8:	2781                	sext.w	a5,a5
    800022ca:	09800993          	li	s3,152
    800022ce:	033787b3          	mul	a5,a5,s3
    800022d2:	97ca                	add	a5,a5,s2
    800022d4:	07c7aa03          	lw	s4,124(a5)
    800022d8:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    800022da:	2581                	sext.w	a1,a1
    800022dc:	033585b3          	mul	a1,a1,s3
    800022e0:	05a1                	addi	a1,a1,8
    800022e2:	95ca                	add	a1,a1,s2
    800022e4:	06048513          	addi	a0,s1,96
    800022e8:	00001097          	auipc	ra,0x1
    800022ec:	944080e7          	jalr	-1724(ra) # 80002c2c <swtch>
    800022f0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022f2:	2781                	sext.w	a5,a5
    800022f4:	033787b3          	mul	a5,a5,s3
    800022f8:	993e                	add	s2,s2,a5
    800022fa:	07492e23          	sw	s4,124(s2)
}
    800022fe:	70a2                	ld	ra,40(sp)
    80002300:	7402                	ld	s0,32(sp)
    80002302:	64e2                	ld	s1,24(sp)
    80002304:	6942                	ld	s2,16(sp)
    80002306:	69a2                	ld	s3,8(sp)
    80002308:	6a02                	ld	s4,0(sp)
    8000230a:	6145                	addi	sp,sp,48
    8000230c:	8082                	ret
    panic("sched p->lock");
    8000230e:	00006517          	auipc	a0,0x6
    80002312:	03250513          	addi	a0,a0,50 # 80008340 <digits+0x300>
    80002316:	ffffe097          	auipc	ra,0xffffe
    8000231a:	228080e7          	jalr	552(ra) # 8000053e <panic>
    panic("sched locks");
    8000231e:	00006517          	auipc	a0,0x6
    80002322:	03250513          	addi	a0,a0,50 # 80008350 <digits+0x310>
    80002326:	ffffe097          	auipc	ra,0xffffe
    8000232a:	218080e7          	jalr	536(ra) # 8000053e <panic>
    panic("sched running");
    8000232e:	00006517          	auipc	a0,0x6
    80002332:	03250513          	addi	a0,a0,50 # 80008360 <digits+0x320>
    80002336:	ffffe097          	auipc	ra,0xffffe
    8000233a:	208080e7          	jalr	520(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000233e:	00006517          	auipc	a0,0x6
    80002342:	03250513          	addi	a0,a0,50 # 80008370 <digits+0x330>
    80002346:	ffffe097          	auipc	ra,0xffffe
    8000234a:	1f8080e7          	jalr	504(ra) # 8000053e <panic>

000000008000234e <yield>:
{
    8000234e:	1101                	addi	sp,sp,-32
    80002350:	ec06                	sd	ra,24(sp)
    80002352:	e822                	sd	s0,16(sp)
    80002354:	e426                	sd	s1,8(sp)
    80002356:	e04a                	sd	s2,0(sp)
    80002358:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000235a:	00000097          	auipc	ra,0x0
    8000235e:	9da080e7          	jalr	-1574(ra) # 80001d34 <myproc>
    80002362:	84aa                	mv	s1,a0
    80002364:	8912                	mv	s2,tp
  acquire(&p->lock);
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	87e080e7          	jalr	-1922(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000236e:	478d                	li	a5,3
    80002370:	cc9c                	sw	a5,24(s1)
  printf("insert yield runnable %d\n", p->index); //delete
    80002372:	16c4a583          	lw	a1,364(s1)
    80002376:	00006517          	auipc	a0,0x6
    8000237a:	01250513          	addi	a0,a0,18 # 80008388 <digits+0x348>
    8000237e:	ffffe097          	auipc	ra,0xffffe
    80002382:	20a080e7          	jalr	522(ra) # 80000588 <printf>
  insert_proc_to_list(&(c->runnable_list), p); // TODO: check
    80002386:	2901                	sext.w	s2,s2
    80002388:	09800513          	li	a0,152
    8000238c:	02a90933          	mul	s2,s2,a0
    80002390:	85a6                	mv	a1,s1
    80002392:	0000f517          	auipc	a0,0xf
    80002396:	f8e50513          	addi	a0,a0,-114 # 80011320 <cpus+0x80>
    8000239a:	954a                	add	a0,a0,s2
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	584080e7          	jalr	1412(ra) # 80001920 <insert_proc_to_list>
  sched();
    800023a4:	00000097          	auipc	ra,0x0
    800023a8:	ec8080e7          	jalr	-312(ra) # 8000226c <sched>
  release(&p->lock);
    800023ac:	8526                	mv	a0,s1
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	8ea080e7          	jalr	-1814(ra) # 80000c98 <release>
}
    800023b6:	60e2                	ld	ra,24(sp)
    800023b8:	6442                	ld	s0,16(sp)
    800023ba:	64a2                	ld	s1,8(sp)
    800023bc:	6902                	ld	s2,0(sp)
    800023be:	6105                	addi	sp,sp,32
    800023c0:	8082                	ret

00000000800023c2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800023c2:	7179                	addi	sp,sp,-48
    800023c4:	f406                	sd	ra,40(sp)
    800023c6:	f022                	sd	s0,32(sp)
    800023c8:	ec26                	sd	s1,24(sp)
    800023ca:	e84a                	sd	s2,16(sp)
    800023cc:	e44e                	sd	s3,8(sp)
    800023ce:	1800                	addi	s0,sp,48
    800023d0:	89aa                	mv	s3,a0
    800023d2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800023d4:	00000097          	auipc	ra,0x0
    800023d8:	960080e7          	jalr	-1696(ra) # 80001d34 <myproc>
    800023dc:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	806080e7          	jalr	-2042(ra) # 80000be4 <acquire>
  release(lk);
    800023e6:	854a                	mv	a0,s2
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	8b0080e7          	jalr	-1872(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800023f0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800023f4:	4789                	li	a5,2
    800023f6:	cc9c                	sw	a5,24(s1)
  printf("insert sleep sleep %d\n", p->index); //delete
    800023f8:	16c4a583          	lw	a1,364(s1)
    800023fc:	00006517          	auipc	a0,0x6
    80002400:	fac50513          	addi	a0,a0,-84 # 800083a8 <digits+0x368>
    80002404:	ffffe097          	auipc	ra,0xffffe
    80002408:	184080e7          	jalr	388(ra) # 80000588 <printf>
  insert_proc_to_list(&sleeping_list, p);
    8000240c:	85a6                	mv	a1,s1
    8000240e:	00006517          	auipc	a0,0x6
    80002412:	60250513          	addi	a0,a0,1538 # 80008a10 <sleeping_list>
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	50a080e7          	jalr	1290(ra) # 80001920 <insert_proc_to_list>

  sched();
    8000241e:	00000097          	auipc	ra,0x0
    80002422:	e4e080e7          	jalr	-434(ra) # 8000226c <sched>

  // Tidy up.
  p->chan = 0;
    80002426:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000242a:	8526                	mv	a0,s1
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	86c080e7          	jalr	-1940(ra) # 80000c98 <release>
  acquire(lk);
    80002434:	854a                	mv	a0,s2
    80002436:	ffffe097          	auipc	ra,0xffffe
    8000243a:	7ae080e7          	jalr	1966(ra) # 80000be4 <acquire>
}
    8000243e:	70a2                	ld	ra,40(sp)
    80002440:	7402                	ld	s0,32(sp)
    80002442:	64e2                	ld	s1,24(sp)
    80002444:	6942                	ld	s2,16(sp)
    80002446:	69a2                	ld	s3,8(sp)
    80002448:	6145                	addi	sp,sp,48
    8000244a:	8082                	ret

000000008000244c <wait>:
{
    8000244c:	715d                	addi	sp,sp,-80
    8000244e:	e486                	sd	ra,72(sp)
    80002450:	e0a2                	sd	s0,64(sp)
    80002452:	fc26                	sd	s1,56(sp)
    80002454:	f84a                	sd	s2,48(sp)
    80002456:	f44e                	sd	s3,40(sp)
    80002458:	f052                	sd	s4,32(sp)
    8000245a:	ec56                	sd	s5,24(sp)
    8000245c:	e85a                	sd	s6,16(sp)
    8000245e:	e45e                	sd	s7,8(sp)
    80002460:	e062                	sd	s8,0(sp)
    80002462:	0880                	addi	s0,sp,80
    80002464:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002466:	00000097          	auipc	ra,0x0
    8000246a:	8ce080e7          	jalr	-1842(ra) # 80001d34 <myproc>
    8000246e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002470:	0000f517          	auipc	a0,0xf
    80002474:	30850513          	addi	a0,a0,776 # 80011778 <wait_lock>
    80002478:	ffffe097          	auipc	ra,0xffffe
    8000247c:	76c080e7          	jalr	1900(ra) # 80000be4 <acquire>
    havekids = 0;
    80002480:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002482:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002484:	00015997          	auipc	s3,0x15
    80002488:	10c98993          	addi	s3,s3,268 # 80017590 <tickslock>
        havekids = 1;
    8000248c:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000248e:	0000fc17          	auipc	s8,0xf
    80002492:	2eac0c13          	addi	s8,s8,746 # 80011778 <wait_lock>
    havekids = 0;
    80002496:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002498:	0000f497          	auipc	s1,0xf
    8000249c:	2f848493          	addi	s1,s1,760 # 80011790 <proc>
    800024a0:	a0bd                	j	8000250e <wait+0xc2>
          pid = np->pid;
    800024a2:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024a6:	000b0e63          	beqz	s6,800024c2 <wait+0x76>
    800024aa:	4691                	li	a3,4
    800024ac:	02c48613          	addi	a2,s1,44
    800024b0:	85da                	mv	a1,s6
    800024b2:	05093503          	ld	a0,80(s2)
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	1bc080e7          	jalr	444(ra) # 80001672 <copyout>
    800024be:	02054563          	bltz	a0,800024e8 <wait+0x9c>
          freeproc(np);
    800024c2:	8526                	mv	a0,s1
    800024c4:	00000097          	auipc	ra,0x0
    800024c8:	a1c080e7          	jalr	-1508(ra) # 80001ee0 <freeproc>
          release(&np->lock);
    800024cc:	8526                	mv	a0,s1
    800024ce:	ffffe097          	auipc	ra,0xffffe
    800024d2:	7ca080e7          	jalr	1994(ra) # 80000c98 <release>
          release(&wait_lock);
    800024d6:	0000f517          	auipc	a0,0xf
    800024da:	2a250513          	addi	a0,a0,674 # 80011778 <wait_lock>
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	7ba080e7          	jalr	1978(ra) # 80000c98 <release>
          return pid;
    800024e6:	a09d                	j	8000254c <wait+0x100>
            release(&np->lock);
    800024e8:	8526                	mv	a0,s1
    800024ea:	ffffe097          	auipc	ra,0xffffe
    800024ee:	7ae080e7          	jalr	1966(ra) # 80000c98 <release>
            release(&wait_lock);
    800024f2:	0000f517          	auipc	a0,0xf
    800024f6:	28650513          	addi	a0,a0,646 # 80011778 <wait_lock>
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	79e080e7          	jalr	1950(ra) # 80000c98 <release>
            return -1;
    80002502:	59fd                	li	s3,-1
    80002504:	a0a1                	j	8000254c <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002506:	17848493          	addi	s1,s1,376
    8000250a:	03348463          	beq	s1,s3,80002532 <wait+0xe6>
      if(np->parent == p){
    8000250e:	7c9c                	ld	a5,56(s1)
    80002510:	ff279be3          	bne	a5,s2,80002506 <wait+0xba>
        acquire(&np->lock);
    80002514:	8526                	mv	a0,s1
    80002516:	ffffe097          	auipc	ra,0xffffe
    8000251a:	6ce080e7          	jalr	1742(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000251e:	4c9c                	lw	a5,24(s1)
    80002520:	f94781e3          	beq	a5,s4,800024a2 <wait+0x56>
        release(&np->lock);
    80002524:	8526                	mv	a0,s1
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	772080e7          	jalr	1906(ra) # 80000c98 <release>
        havekids = 1;
    8000252e:	8756                	mv	a4,s5
    80002530:	bfd9                	j	80002506 <wait+0xba>
    if(!havekids || p->killed){
    80002532:	c701                	beqz	a4,8000253a <wait+0xee>
    80002534:	02892783          	lw	a5,40(s2)
    80002538:	c79d                	beqz	a5,80002566 <wait+0x11a>
      release(&wait_lock);
    8000253a:	0000f517          	auipc	a0,0xf
    8000253e:	23e50513          	addi	a0,a0,574 # 80011778 <wait_lock>
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	756080e7          	jalr	1878(ra) # 80000c98 <release>
      return -1;
    8000254a:	59fd                	li	s3,-1
}
    8000254c:	854e                	mv	a0,s3
    8000254e:	60a6                	ld	ra,72(sp)
    80002550:	6406                	ld	s0,64(sp)
    80002552:	74e2                	ld	s1,56(sp)
    80002554:	7942                	ld	s2,48(sp)
    80002556:	79a2                	ld	s3,40(sp)
    80002558:	7a02                	ld	s4,32(sp)
    8000255a:	6ae2                	ld	s5,24(sp)
    8000255c:	6b42                	ld	s6,16(sp)
    8000255e:	6ba2                	ld	s7,8(sp)
    80002560:	6c02                	ld	s8,0(sp)
    80002562:	6161                	addi	sp,sp,80
    80002564:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002566:	85e2                	mv	a1,s8
    80002568:	854a                	mv	a0,s2
    8000256a:	00000097          	auipc	ra,0x0
    8000256e:	e58080e7          	jalr	-424(ra) # 800023c2 <sleep>
    havekids = 0;
    80002572:	b715                	j	80002496 <wait+0x4a>

0000000080002574 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002574:	7179                	addi	sp,sp,-48
    80002576:	f406                	sd	ra,40(sp)
    80002578:	f022                	sd	s0,32(sp)
    8000257a:	ec26                	sd	s1,24(sp)
    8000257c:	e84a                	sd	s2,16(sp)
    8000257e:	e44e                	sd	s3,8(sp)
    80002580:	1800                	addi	s0,sp,48
    80002582:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002584:	0000f497          	auipc	s1,0xf
    80002588:	20c48493          	addi	s1,s1,524 # 80011790 <proc>
    8000258c:	00015997          	auipc	s3,0x15
    80002590:	00498993          	addi	s3,s3,4 # 80017590 <tickslock>
    acquire(&p->lock);
    80002594:	8526                	mv	a0,s1
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	64e080e7          	jalr	1614(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000259e:	589c                	lw	a5,48(s1)
    800025a0:	01278d63          	beq	a5,s2,800025ba <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025a4:	8526                	mv	a0,s1
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	6f2080e7          	jalr	1778(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025ae:	17848493          	addi	s1,s1,376
    800025b2:	ff3491e3          	bne	s1,s3,80002594 <kill+0x20>
  }
  return -1;
    800025b6:	557d                	li	a0,-1
    800025b8:	a829                	j	800025d2 <kill+0x5e>
      p->killed = 1;
    800025ba:	4785                	li	a5,1
    800025bc:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025be:	4c98                	lw	a4,24(s1)
    800025c0:	4789                	li	a5,2
    800025c2:	00f70f63          	beq	a4,a5,800025e0 <kill+0x6c>
      release(&p->lock);
    800025c6:	8526                	mv	a0,s1
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	6d0080e7          	jalr	1744(ra) # 80000c98 <release>
      return 0;
    800025d0:	4501                	li	a0,0
}
    800025d2:	70a2                	ld	ra,40(sp)
    800025d4:	7402                	ld	s0,32(sp)
    800025d6:	64e2                	ld	s1,24(sp)
    800025d8:	6942                	ld	s2,16(sp)
    800025da:	69a2                	ld	s3,8(sp)
    800025dc:	6145                	addi	sp,sp,48
    800025de:	8082                	ret
        p->state = RUNNABLE;
    800025e0:	478d                	li	a5,3
    800025e2:	cc9c                	sw	a5,24(s1)
    800025e4:	b7cd                	j	800025c6 <kill+0x52>

00000000800025e6 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025e6:	7179                	addi	sp,sp,-48
    800025e8:	f406                	sd	ra,40(sp)
    800025ea:	f022                	sd	s0,32(sp)
    800025ec:	ec26                	sd	s1,24(sp)
    800025ee:	e84a                	sd	s2,16(sp)
    800025f0:	e44e                	sd	s3,8(sp)
    800025f2:	e052                	sd	s4,0(sp)
    800025f4:	1800                	addi	s0,sp,48
    800025f6:	84aa                	mv	s1,a0
    800025f8:	892e                	mv	s2,a1
    800025fa:	89b2                	mv	s3,a2
    800025fc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025fe:	fffff097          	auipc	ra,0xfffff
    80002602:	736080e7          	jalr	1846(ra) # 80001d34 <myproc>
  if(user_dst){
    80002606:	c08d                	beqz	s1,80002628 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002608:	86d2                	mv	a3,s4
    8000260a:	864e                	mv	a2,s3
    8000260c:	85ca                	mv	a1,s2
    8000260e:	6928                	ld	a0,80(a0)
    80002610:	fffff097          	auipc	ra,0xfffff
    80002614:	062080e7          	jalr	98(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002618:	70a2                	ld	ra,40(sp)
    8000261a:	7402                	ld	s0,32(sp)
    8000261c:	64e2                	ld	s1,24(sp)
    8000261e:	6942                	ld	s2,16(sp)
    80002620:	69a2                	ld	s3,8(sp)
    80002622:	6a02                	ld	s4,0(sp)
    80002624:	6145                	addi	sp,sp,48
    80002626:	8082                	ret
    memmove((char *)dst, src, len);
    80002628:	000a061b          	sext.w	a2,s4
    8000262c:	85ce                	mv	a1,s3
    8000262e:	854a                	mv	a0,s2
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	710080e7          	jalr	1808(ra) # 80000d40 <memmove>
    return 0;
    80002638:	8526                	mv	a0,s1
    8000263a:	bff9                	j	80002618 <either_copyout+0x32>

000000008000263c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000263c:	7179                	addi	sp,sp,-48
    8000263e:	f406                	sd	ra,40(sp)
    80002640:	f022                	sd	s0,32(sp)
    80002642:	ec26                	sd	s1,24(sp)
    80002644:	e84a                	sd	s2,16(sp)
    80002646:	e44e                	sd	s3,8(sp)
    80002648:	e052                	sd	s4,0(sp)
    8000264a:	1800                	addi	s0,sp,48
    8000264c:	892a                	mv	s2,a0
    8000264e:	84ae                	mv	s1,a1
    80002650:	89b2                	mv	s3,a2
    80002652:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002654:	fffff097          	auipc	ra,0xfffff
    80002658:	6e0080e7          	jalr	1760(ra) # 80001d34 <myproc>
  if(user_src){
    8000265c:	c08d                	beqz	s1,8000267e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000265e:	86d2                	mv	a3,s4
    80002660:	864e                	mv	a2,s3
    80002662:	85ca                	mv	a1,s2
    80002664:	6928                	ld	a0,80(a0)
    80002666:	fffff097          	auipc	ra,0xfffff
    8000266a:	098080e7          	jalr	152(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000266e:	70a2                	ld	ra,40(sp)
    80002670:	7402                	ld	s0,32(sp)
    80002672:	64e2                	ld	s1,24(sp)
    80002674:	6942                	ld	s2,16(sp)
    80002676:	69a2                	ld	s3,8(sp)
    80002678:	6a02                	ld	s4,0(sp)
    8000267a:	6145                	addi	sp,sp,48
    8000267c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000267e:	000a061b          	sext.w	a2,s4
    80002682:	85ce                	mv	a1,s3
    80002684:	854a                	mv	a0,s2
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	6ba080e7          	jalr	1722(ra) # 80000d40 <memmove>
    return 0;
    8000268e:	8526                	mv	a0,s1
    80002690:	bff9                	j	8000266e <either_copyin+0x32>

0000000080002692 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    80002692:	715d                	addi	sp,sp,-80
    80002694:	e486                	sd	ra,72(sp)
    80002696:	e0a2                	sd	s0,64(sp)
    80002698:	fc26                	sd	s1,56(sp)
    8000269a:	f84a                	sd	s2,48(sp)
    8000269c:	f44e                	sd	s3,40(sp)
    8000269e:	f052                	sd	s4,32(sp)
    800026a0:	ec56                	sd	s5,24(sp)
    800026a2:	e85a                	sd	s6,16(sp)
    800026a4:	e45e                	sd	s7,8(sp)
    800026a6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026a8:	00006517          	auipc	a0,0x6
    800026ac:	c9050513          	addi	a0,a0,-880 # 80008338 <digits+0x2f8>
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	ed8080e7          	jalr	-296(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026b8:	0000f497          	auipc	s1,0xf
    800026bc:	23048493          	addi	s1,s1,560 # 800118e8 <proc+0x158>
    800026c0:	00015917          	auipc	s2,0x15
    800026c4:	02890913          	addi	s2,s2,40 # 800176e8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026c8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    800026ca:	00006997          	auipc	s3,0x6
    800026ce:	cf698993          	addi	s3,s3,-778 # 800083c0 <digits+0x380>
    printf("%d %s %s", p->pid, state, p->name);
    800026d2:	00006a97          	auipc	s5,0x6
    800026d6:	cf6a8a93          	addi	s5,s5,-778 # 800083c8 <digits+0x388>
    printf("\n");
    800026da:	00006a17          	auipc	s4,0x6
    800026de:	c5ea0a13          	addi	s4,s4,-930 # 80008338 <digits+0x2f8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026e2:	00006b97          	auipc	s7,0x6
    800026e6:	daeb8b93          	addi	s7,s7,-594 # 80008490 <states.1797>
    800026ea:	a00d                	j	8000270c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026ec:	ed86a583          	lw	a1,-296(a3)
    800026f0:	8556                	mv	a0,s5
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	e96080e7          	jalr	-362(ra) # 80000588 <printf>
    printf("\n");
    800026fa:	8552                	mv	a0,s4
    800026fc:	ffffe097          	auipc	ra,0xffffe
    80002700:	e8c080e7          	jalr	-372(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002704:	17848493          	addi	s1,s1,376
    80002708:	03248163          	beq	s1,s2,8000272a <procdump+0x98>
    if(p->state == UNUSED)
    8000270c:	86a6                	mv	a3,s1
    8000270e:	ec04a783          	lw	a5,-320(s1)
    80002712:	dbed                	beqz	a5,80002704 <procdump+0x72>
      state = "???"; 
    80002714:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002716:	fcfb6be3          	bltu	s6,a5,800026ec <procdump+0x5a>
    8000271a:	1782                	slli	a5,a5,0x20
    8000271c:	9381                	srli	a5,a5,0x20
    8000271e:	078e                	slli	a5,a5,0x3
    80002720:	97de                	add	a5,a5,s7
    80002722:	6390                	ld	a2,0(a5)
    80002724:	f661                	bnez	a2,800026ec <procdump+0x5a>
      state = "???"; 
    80002726:	864e                	mv	a2,s3
    80002728:	b7d1                	j	800026ec <procdump+0x5a>
  }
}
    8000272a:	60a6                	ld	ra,72(sp)
    8000272c:	6406                	ld	s0,64(sp)
    8000272e:	74e2                	ld	s1,56(sp)
    80002730:	7942                	ld	s2,48(sp)
    80002732:	79a2                	ld	s3,40(sp)
    80002734:	7a02                	ld	s4,32(sp)
    80002736:	6ae2                	ld	s5,24(sp)
    80002738:	6b42                	ld	s6,16(sp)
    8000273a:	6ba2                	ld	s7,8(sp)
    8000273c:	6161                	addi	sp,sp,80
    8000273e:	8082                	ret

0000000080002740 <set_cpu>:

// assign current process to a different CPU. 
int
set_cpu(int cpu_num){
    80002740:	1101                	addi	sp,sp,-32
    80002742:	ec06                	sd	ra,24(sp)
    80002744:	e822                	sd	s0,16(sp)
    80002746:	e426                	sd	s1,8(sp)
    80002748:	e04a                	sd	s2,0(sp)
    8000274a:	1000                	addi	s0,sp,32
    8000274c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000274e:	fffff097          	auipc	ra,0xfffff
    80002752:	5e6080e7          	jalr	1510(ra) # 80001d34 <myproc>
  if(cpu_num >= 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL){
    80002756:	0004871b          	sext.w	a4,s1
    8000275a:	479d                	li	a5,7
    8000275c:	02e7e963          	bltu	a5,a4,8000278e <set_cpu+0x4e>
    80002760:	892a                	mv	s2,a0
    acquire(&p->lock);
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	482080e7          	jalr	1154(ra) # 80000be4 <acquire>
    p->last_cpu = cpu_num;
    8000276a:	16992423          	sw	s1,360(s2)
    release(&p->lock);
    8000276e:	854a                	mv	a0,s2
    80002770:	ffffe097          	auipc	ra,0xffffe
    80002774:	528080e7          	jalr	1320(ra) # 80000c98 <release>

    yield();
    80002778:	00000097          	auipc	ra,0x0
    8000277c:	bd6080e7          	jalr	-1066(ra) # 8000234e <yield>

    return cpu_num;
    80002780:	8526                	mv	a0,s1
  }
  return -1;
}
    80002782:	60e2                	ld	ra,24(sp)
    80002784:	6442                	ld	s0,16(sp)
    80002786:	64a2                	ld	s1,8(sp)
    80002788:	6902                	ld	s2,0(sp)
    8000278a:	6105                	addi	sp,sp,32
    8000278c:	8082                	ret
  return -1;
    8000278e:	557d                	li	a0,-1
    80002790:	bfcd                	j	80002782 <set_cpu+0x42>

0000000080002792 <get_cpu>:

// return the current CPU id.
int
get_cpu(void){
    80002792:	1141                	addi	sp,sp,-16
    80002794:	e406                	sd	ra,8(sp)
    80002796:	e022                	sd	s0,0(sp)
    80002798:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000279a:	fffff097          	auipc	ra,0xfffff
    8000279e:	59a080e7          	jalr	1434(ra) # 80001d34 <myproc>
  return p->last_cpu;
}
    800027a2:	16852503          	lw	a0,360(a0)
    800027a6:	60a2                	ld	ra,8(sp)
    800027a8:	6402                	ld	s0,0(sp)
    800027aa:	0141                	addi	sp,sp,16
    800027ac:	8082                	ret

00000000800027ae <min_cpu>:

int
min_cpu(void){
    800027ae:	1141                	addi	sp,sp,-16
    800027b0:	e422                	sd	s0,8(sp)
    800027b2:	0800                	addi	s0,sp,16
  struct cpu *c, *min_cpu;
// should add an if to insure numberOfCpus>0
  min_cpu = cpus;
    800027b4:	0000f617          	auipc	a2,0xf
    800027b8:	aec60613          	addi	a2,a2,-1300 # 800112a0 <cpus>
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL ; c++){
    800027bc:	0000f797          	auipc	a5,0xf
    800027c0:	b7c78793          	addi	a5,a5,-1156 # 80011338 <cpus+0x98>
    800027c4:	0000f597          	auipc	a1,0xf
    800027c8:	f9c58593          	addi	a1,a1,-100 # 80011760 <pid_lock>
    800027cc:	a029                	j	800027d6 <min_cpu+0x28>
    800027ce:	09878793          	addi	a5,a5,152
    800027d2:	00b78863          	beq	a5,a1,800027e2 <min_cpu+0x34>
    if (c->cpu_process_count < min_cpu->cpu_process_count)
    800027d6:	6bd4                	ld	a3,144(a5)
    800027d8:	6a58                	ld	a4,144(a2)
    800027da:	fee6fae3          	bgeu	a3,a4,800027ce <min_cpu+0x20>
    800027de:	863e                	mv	a2,a5
    800027e0:	b7fd                	j	800027ce <min_cpu+0x20>
        min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    800027e2:	08862503          	lw	a0,136(a2)
    800027e6:	6422                	ld	s0,8(sp)
    800027e8:	0141                	addi	sp,sp,16
    800027ea:	8082                	ret

00000000800027ec <cpu_process_count>:

int
cpu_process_count(int cpu_num){
    800027ec:	1141                	addi	sp,sp,-16
    800027ee:	e422                	sd	s0,8(sp)
    800027f0:	0800                	addi	s0,sp,16
  if (cpu_num > 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL) 
    800027f2:	fff5071b          	addiw	a4,a0,-1
    800027f6:	4799                	li	a5,6
    800027f8:	02e7e063          	bltu	a5,a4,80002818 <cpu_process_count+0x2c>
    return cpus[cpu_num].cpu_process_count;
    800027fc:	09800793          	li	a5,152
    80002800:	02f50533          	mul	a0,a0,a5
    80002804:	0000f797          	auipc	a5,0xf
    80002808:	a9c78793          	addi	a5,a5,-1380 # 800112a0 <cpus>
    8000280c:	953e                	add	a0,a0,a5
    8000280e:	09052503          	lw	a0,144(a0)
  return -1;
}
    80002812:	6422                	ld	s0,8(sp)
    80002814:	0141                	addi	sp,sp,16
    80002816:	8082                	ret
  return -1;
    80002818:	557d                	li	a0,-1
    8000281a:	bfe5                	j	80002812 <cpu_process_count+0x26>

000000008000281c <increment_cpu_process_count>:

void 
increment_cpu_process_count(struct cpu *c){
    8000281c:	1101                	addi	sp,sp,-32
    8000281e:	ec06                	sd	ra,24(sp)
    80002820:	e822                	sd	s0,16(sp)
    80002822:	e426                	sd	s1,8(sp)
    80002824:	e04a                	sd	s2,0(sp)
    80002826:	1000                	addi	s0,sp,32
    80002828:	84aa                	mv	s1,a0
  uint64 curr_count;
  do{
    curr_count = c->cpu_process_count;
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    8000282a:	09050913          	addi	s2,a0,144
    curr_count = c->cpu_process_count;
    8000282e:	68cc                	ld	a1,144(s1)
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    80002830:	0015861b          	addiw	a2,a1,1
    80002834:	2581                	sext.w	a1,a1
    80002836:	854a                	mv	a0,s2
    80002838:	00004097          	auipc	ra,0x4
    8000283c:	05e080e7          	jalr	94(ra) # 80006896 <cas>
    80002840:	2501                	sext.w	a0,a0
    80002842:	f575                	bnez	a0,8000282e <increment_cpu_process_count+0x12>
}
    80002844:	60e2                	ld	ra,24(sp)
    80002846:	6442                	ld	s0,16(sp)
    80002848:	64a2                	ld	s1,8(sp)
    8000284a:	6902                	ld	s2,0(sp)
    8000284c:	6105                	addi	sp,sp,32
    8000284e:	8082                	ret

0000000080002850 <fork>:
{
    80002850:	7139                	addi	sp,sp,-64
    80002852:	fc06                	sd	ra,56(sp)
    80002854:	f822                	sd	s0,48(sp)
    80002856:	f426                	sd	s1,40(sp)
    80002858:	f04a                	sd	s2,32(sp)
    8000285a:	ec4e                	sd	s3,24(sp)
    8000285c:	e852                	sd	s4,16(sp)
    8000285e:	e456                	sd	s5,8(sp)
    80002860:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002862:	fffff097          	auipc	ra,0xfffff
    80002866:	4d2080e7          	jalr	1234(ra) # 80001d34 <myproc>
    8000286a:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    8000286c:	fffff097          	auipc	ra,0xfffff
    80002870:	718080e7          	jalr	1816(ra) # 80001f84 <allocproc>
    80002874:	16050063          	beqz	a0,800029d4 <fork+0x184>
    80002878:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000287a:	0489b603          	ld	a2,72(s3)
    8000287e:	692c                	ld	a1,80(a0)
    80002880:	0509b503          	ld	a0,80(s3)
    80002884:	fffff097          	auipc	ra,0xfffff
    80002888:	cea080e7          	jalr	-790(ra) # 8000156e <uvmcopy>
    8000288c:	04054663          	bltz	a0,800028d8 <fork+0x88>
  np->sz = p->sz;
    80002890:	0489b783          	ld	a5,72(s3)
    80002894:	04f93423          	sd	a5,72(s2)
  *(np->trapframe) = *(p->trapframe);
    80002898:	0589b683          	ld	a3,88(s3)
    8000289c:	87b6                	mv	a5,a3
    8000289e:	05893703          	ld	a4,88(s2)
    800028a2:	12068693          	addi	a3,a3,288
    800028a6:	0007b803          	ld	a6,0(a5)
    800028aa:	6788                	ld	a0,8(a5)
    800028ac:	6b8c                	ld	a1,16(a5)
    800028ae:	6f90                	ld	a2,24(a5)
    800028b0:	01073023          	sd	a6,0(a4)
    800028b4:	e708                	sd	a0,8(a4)
    800028b6:	eb0c                	sd	a1,16(a4)
    800028b8:	ef10                	sd	a2,24(a4)
    800028ba:	02078793          	addi	a5,a5,32
    800028be:	02070713          	addi	a4,a4,32
    800028c2:	fed792e3          	bne	a5,a3,800028a6 <fork+0x56>
  np->trapframe->a0 = 0;
    800028c6:	05893783          	ld	a5,88(s2)
    800028ca:	0607b823          	sd	zero,112(a5)
    800028ce:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    800028d2:	15000a13          	li	s4,336
    800028d6:	a03d                	j	80002904 <fork+0xb4>
    freeproc(np);
    800028d8:	854a                	mv	a0,s2
    800028da:	fffff097          	auipc	ra,0xfffff
    800028de:	606080e7          	jalr	1542(ra) # 80001ee0 <freeproc>
    release(&np->lock);
    800028e2:	854a                	mv	a0,s2
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	3b4080e7          	jalr	948(ra) # 80000c98 <release>
    return -1;
    800028ec:	5afd                	li	s5,-1
    800028ee:	a8c9                	j	800029c0 <fork+0x170>
      np->ofile[i] = filedup(p->ofile[i]);
    800028f0:	00002097          	auipc	ra,0x2
    800028f4:	268080e7          	jalr	616(ra) # 80004b58 <filedup>
    800028f8:	009907b3          	add	a5,s2,s1
    800028fc:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800028fe:	04a1                	addi	s1,s1,8
    80002900:	01448763          	beq	s1,s4,8000290e <fork+0xbe>
    if(p->ofile[i])
    80002904:	009987b3          	add	a5,s3,s1
    80002908:	6388                	ld	a0,0(a5)
    8000290a:	f17d                	bnez	a0,800028f0 <fork+0xa0>
    8000290c:	bfcd                	j	800028fe <fork+0xae>
  np->cwd = idup(p->cwd);
    8000290e:	1509b503          	ld	a0,336(s3)
    80002912:	00001097          	auipc	ra,0x1
    80002916:	3bc080e7          	jalr	956(ra) # 80003cce <idup>
    8000291a:	14a93823          	sd	a0,336(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000291e:	4641                	li	a2,16
    80002920:	15898593          	addi	a1,s3,344
    80002924:	15890513          	addi	a0,s2,344
    80002928:	ffffe097          	auipc	ra,0xffffe
    8000292c:	50a080e7          	jalr	1290(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002930:	03092a83          	lw	s5,48(s2)
  release(&np->lock);
    80002934:	854a                	mv	a0,s2
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	362080e7          	jalr	866(ra) # 80000c98 <release>
  acquire(&wait_lock);
    8000293e:	0000fa17          	auipc	s4,0xf
    80002942:	962a0a13          	addi	s4,s4,-1694 # 800112a0 <cpus>
    80002946:	0000f497          	auipc	s1,0xf
    8000294a:	e3248493          	addi	s1,s1,-462 # 80011778 <wait_lock>
    8000294e:	8526                	mv	a0,s1
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	294080e7          	jalr	660(ra) # 80000be4 <acquire>
  np->parent = p;
    80002958:	03393c23          	sd	s3,56(s2)
  release(&wait_lock);
    8000295c:	8526                	mv	a0,s1
    8000295e:	ffffe097          	auipc	ra,0xffffe
    80002962:	33a080e7          	jalr	826(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002966:	854a                	mv	a0,s2
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	27c080e7          	jalr	636(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002970:	478d                	li	a5,3
    80002972:	00f92c23          	sw	a5,24(s2)
  np->last_cpu = p->last_cpu; // case BLNCFLG=OFF -> cpu = parent's cpu 
    80002976:	1689a483          	lw	s1,360(s3)
    8000297a:	16992423          	sw	s1,360(s2)
  struct cpu *c = &cpus[np->last_cpu];
    8000297e:	09800513          	li	a0,152
    80002982:	02a484b3          	mul	s1,s1,a0
  increment_cpu_process_count(c);
    80002986:	009a0533          	add	a0,s4,s1
    8000298a:	00000097          	auipc	ra,0x0
    8000298e:	e92080e7          	jalr	-366(ra) # 8000281c <increment_cpu_process_count>
  printf("insert fork runnable %d\n", np->index); //delete
    80002992:	16c92583          	lw	a1,364(s2)
    80002996:	00006517          	auipc	a0,0x6
    8000299a:	a4250513          	addi	a0,a0,-1470 # 800083d8 <digits+0x398>
    8000299e:	ffffe097          	auipc	ra,0xffffe
    800029a2:	bea080e7          	jalr	-1046(ra) # 80000588 <printf>
  insert_proc_to_list(&(c->runnable_list), np); // admit the new process to the father’s current CPU’s ready list
    800029a6:	08048513          	addi	a0,s1,128
    800029aa:	85ca                	mv	a1,s2
    800029ac:	9552                	add	a0,a0,s4
    800029ae:	fffff097          	auipc	ra,0xfffff
    800029b2:	f72080e7          	jalr	-142(ra) # 80001920 <insert_proc_to_list>
  release(&np->lock);
    800029b6:	854a                	mv	a0,s2
    800029b8:	ffffe097          	auipc	ra,0xffffe
    800029bc:	2e0080e7          	jalr	736(ra) # 80000c98 <release>
}
    800029c0:	8556                	mv	a0,s5
    800029c2:	70e2                	ld	ra,56(sp)
    800029c4:	7442                	ld	s0,48(sp)
    800029c6:	74a2                	ld	s1,40(sp)
    800029c8:	7902                	ld	s2,32(sp)
    800029ca:	69e2                	ld	s3,24(sp)
    800029cc:	6a42                	ld	s4,16(sp)
    800029ce:	6aa2                	ld	s5,8(sp)
    800029d0:	6121                	addi	sp,sp,64
    800029d2:	8082                	ret
    return -1;
    800029d4:	5afd                	li	s5,-1
    800029d6:	b7ed                	j	800029c0 <fork+0x170>

00000000800029d8 <wakeup>:
{
    800029d8:	7159                	addi	sp,sp,-112
    800029da:	f486                	sd	ra,104(sp)
    800029dc:	f0a2                	sd	s0,96(sp)
    800029de:	eca6                	sd	s1,88(sp)
    800029e0:	e8ca                	sd	s2,80(sp)
    800029e2:	e4ce                	sd	s3,72(sp)
    800029e4:	e0d2                	sd	s4,64(sp)
    800029e6:	fc56                	sd	s5,56(sp)
    800029e8:	f85a                	sd	s6,48(sp)
    800029ea:	f45e                	sd	s7,40(sp)
    800029ec:	f062                	sd	s8,32(sp)
    800029ee:	ec66                	sd	s9,24(sp)
    800029f0:	e86a                	sd	s10,16(sp)
    800029f2:	e46e                	sd	s11,8(sp)
    800029f4:	1880                	addi	s0,sp,112
    800029f6:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800029f8:	0000f497          	auipc	s1,0xf
    800029fc:	d9848493          	addi	s1,s1,-616 # 80011790 <proc>
      if(p->state == SLEEPING && p->chan == chan) {
    80002a00:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002a02:	4d0d                	li	s10,3
        printf("remove wakeup sleep %d\n", p->index); //delete
    80002a04:	00006c97          	auipc	s9,0x6
    80002a08:	9f4c8c93          	addi	s9,s9,-1548 # 800083f8 <digits+0x3b8>
        remove_proc_to_list(&sleeping_list, p);
    80002a0c:	00006c17          	auipc	s8,0x6
    80002a10:	004c0c13          	addi	s8,s8,4 # 80008a10 <sleeping_list>
    80002a14:	09800b93          	li	s7,152
        c = &cpus[p->last_cpu];
    80002a18:	0000fa97          	auipc	s5,0xf
    80002a1c:	888a8a93          	addi	s5,s5,-1912 # 800112a0 <cpus>
        printf("insert wakeup runnable %d\n", p->index); //delete
    80002a20:	00006b17          	auipc	s6,0x6
    80002a24:	9f0b0b13          	addi	s6,s6,-1552 # 80008410 <digits+0x3d0>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002a28:	00015917          	auipc	s2,0x15
    80002a2c:	b6890913          	addi	s2,s2,-1176 # 80017590 <tickslock>
    80002a30:	a811                	j	80002a44 <wakeup+0x6c>
      release(&p->lock);
    80002a32:	8526                	mv	a0,s1
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	264080e7          	jalr	612(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002a3c:	17848493          	addi	s1,s1,376
    80002a40:	07248c63          	beq	s1,s2,80002ab8 <wakeup+0xe0>
    if(p != myproc()){
    80002a44:	fffff097          	auipc	ra,0xfffff
    80002a48:	2f0080e7          	jalr	752(ra) # 80001d34 <myproc>
    80002a4c:	fea488e3          	beq	s1,a0,80002a3c <wakeup+0x64>
      acquire(&p->lock);
    80002a50:	8526                	mv	a0,s1
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	192080e7          	jalr	402(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002a5a:	4c9c                	lw	a5,24(s1)
    80002a5c:	fd379be3          	bne	a5,s3,80002a32 <wakeup+0x5a>
    80002a60:	709c                	ld	a5,32(s1)
    80002a62:	fd4798e3          	bne	a5,s4,80002a32 <wakeup+0x5a>
        p->state = RUNNABLE;
    80002a66:	01a4ac23          	sw	s10,24(s1)
        printf("remove wakeup sleep %d\n", p->index); //delete
    80002a6a:	16c4a583          	lw	a1,364(s1)
    80002a6e:	8566                	mv	a0,s9
    80002a70:	ffffe097          	auipc	ra,0xffffe
    80002a74:	b18080e7          	jalr	-1256(ra) # 80000588 <printf>
        remove_proc_to_list(&sleeping_list, p);
    80002a78:	85a6                	mv	a1,s1
    80002a7a:	8562                	mv	a0,s8
    80002a7c:	fffff097          	auipc	ra,0xfffff
    80002a80:	f66080e7          	jalr	-154(ra) # 800019e2 <remove_proc_to_list>
        c = &cpus[p->last_cpu];
    80002a84:	1684ad83          	lw	s11,360(s1)
    80002a88:	037d8db3          	mul	s11,s11,s7
        increment_cpu_process_count(c);
    80002a8c:	01ba8533          	add	a0,s5,s11
    80002a90:	00000097          	auipc	ra,0x0
    80002a94:	d8c080e7          	jalr	-628(ra) # 8000281c <increment_cpu_process_count>
        printf("insert wakeup runnable %d\n", p->index); //delete
    80002a98:	16c4a583          	lw	a1,364(s1)
    80002a9c:	855a                	mv	a0,s6
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	aea080e7          	jalr	-1302(ra) # 80000588 <printf>
        insert_proc_to_list(&(c->runnable_list), p);
    80002aa6:	080d8513          	addi	a0,s11,128
    80002aaa:	85a6                	mv	a1,s1
    80002aac:	9556                	add	a0,a0,s5
    80002aae:	fffff097          	auipc	ra,0xfffff
    80002ab2:	e72080e7          	jalr	-398(ra) # 80001920 <insert_proc_to_list>
    80002ab6:	bfb5                	j	80002a32 <wakeup+0x5a>
}
    80002ab8:	70a6                	ld	ra,104(sp)
    80002aba:	7406                	ld	s0,96(sp)
    80002abc:	64e6                	ld	s1,88(sp)
    80002abe:	6946                	ld	s2,80(sp)
    80002ac0:	69a6                	ld	s3,72(sp)
    80002ac2:	6a06                	ld	s4,64(sp)
    80002ac4:	7ae2                	ld	s5,56(sp)
    80002ac6:	7b42                	ld	s6,48(sp)
    80002ac8:	7ba2                	ld	s7,40(sp)
    80002aca:	7c02                	ld	s8,32(sp)
    80002acc:	6ce2                	ld	s9,24(sp)
    80002ace:	6d42                	ld	s10,16(sp)
    80002ad0:	6da2                	ld	s11,8(sp)
    80002ad2:	6165                	addi	sp,sp,112
    80002ad4:	8082                	ret

0000000080002ad6 <reparent>:
{
    80002ad6:	7179                	addi	sp,sp,-48
    80002ad8:	f406                	sd	ra,40(sp)
    80002ada:	f022                	sd	s0,32(sp)
    80002adc:	ec26                	sd	s1,24(sp)
    80002ade:	e84a                	sd	s2,16(sp)
    80002ae0:	e44e                	sd	s3,8(sp)
    80002ae2:	e052                	sd	s4,0(sp)
    80002ae4:	1800                	addi	s0,sp,48
    80002ae6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002ae8:	0000f497          	auipc	s1,0xf
    80002aec:	ca848493          	addi	s1,s1,-856 # 80011790 <proc>
      pp->parent = initproc;
    80002af0:	00006a17          	auipc	s4,0x6
    80002af4:	538a0a13          	addi	s4,s4,1336 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002af8:	00015997          	auipc	s3,0x15
    80002afc:	a9898993          	addi	s3,s3,-1384 # 80017590 <tickslock>
    80002b00:	a029                	j	80002b0a <reparent+0x34>
    80002b02:	17848493          	addi	s1,s1,376
    80002b06:	01348d63          	beq	s1,s3,80002b20 <reparent+0x4a>
    if(pp->parent == p){
    80002b0a:	7c9c                	ld	a5,56(s1)
    80002b0c:	ff279be3          	bne	a5,s2,80002b02 <reparent+0x2c>
      pp->parent = initproc;
    80002b10:	000a3503          	ld	a0,0(s4)
    80002b14:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002b16:	00000097          	auipc	ra,0x0
    80002b1a:	ec2080e7          	jalr	-318(ra) # 800029d8 <wakeup>
    80002b1e:	b7d5                	j	80002b02 <reparent+0x2c>
}
    80002b20:	70a2                	ld	ra,40(sp)
    80002b22:	7402                	ld	s0,32(sp)
    80002b24:	64e2                	ld	s1,24(sp)
    80002b26:	6942                	ld	s2,16(sp)
    80002b28:	69a2                	ld	s3,8(sp)
    80002b2a:	6a02                	ld	s4,0(sp)
    80002b2c:	6145                	addi	sp,sp,48
    80002b2e:	8082                	ret

0000000080002b30 <exit>:
{
    80002b30:	7179                	addi	sp,sp,-48
    80002b32:	f406                	sd	ra,40(sp)
    80002b34:	f022                	sd	s0,32(sp)
    80002b36:	ec26                	sd	s1,24(sp)
    80002b38:	e84a                	sd	s2,16(sp)
    80002b3a:	e44e                	sd	s3,8(sp)
    80002b3c:	e052                	sd	s4,0(sp)
    80002b3e:	1800                	addi	s0,sp,48
    80002b40:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002b42:	fffff097          	auipc	ra,0xfffff
    80002b46:	1f2080e7          	jalr	498(ra) # 80001d34 <myproc>
    80002b4a:	89aa                	mv	s3,a0
  if(p == initproc)
    80002b4c:	00006797          	auipc	a5,0x6
    80002b50:	4dc7b783          	ld	a5,1244(a5) # 80009028 <initproc>
    80002b54:	0d050493          	addi	s1,a0,208
    80002b58:	15050913          	addi	s2,a0,336
    80002b5c:	02a79363          	bne	a5,a0,80002b82 <exit+0x52>
    panic("init exiting");
    80002b60:	00006517          	auipc	a0,0x6
    80002b64:	8d050513          	addi	a0,a0,-1840 # 80008430 <digits+0x3f0>
    80002b68:	ffffe097          	auipc	ra,0xffffe
    80002b6c:	9d6080e7          	jalr	-1578(ra) # 8000053e <panic>
      fileclose(f);
    80002b70:	00002097          	auipc	ra,0x2
    80002b74:	03a080e7          	jalr	58(ra) # 80004baa <fileclose>
      p->ofile[fd] = 0;
    80002b78:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002b7c:	04a1                	addi	s1,s1,8
    80002b7e:	01248563          	beq	s1,s2,80002b88 <exit+0x58>
    if(p->ofile[fd]){
    80002b82:	6088                	ld	a0,0(s1)
    80002b84:	f575                	bnez	a0,80002b70 <exit+0x40>
    80002b86:	bfdd                	j	80002b7c <exit+0x4c>
  begin_op();
    80002b88:	00002097          	auipc	ra,0x2
    80002b8c:	b56080e7          	jalr	-1194(ra) # 800046de <begin_op>
  iput(p->cwd);
    80002b90:	1509b503          	ld	a0,336(s3)
    80002b94:	00001097          	auipc	ra,0x1
    80002b98:	332080e7          	jalr	818(ra) # 80003ec6 <iput>
  end_op();
    80002b9c:	00002097          	auipc	ra,0x2
    80002ba0:	bc2080e7          	jalr	-1086(ra) # 8000475e <end_op>
  p->cwd = 0;
    80002ba4:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002ba8:	0000f497          	auipc	s1,0xf
    80002bac:	bd048493          	addi	s1,s1,-1072 # 80011778 <wait_lock>
    80002bb0:	8526                	mv	a0,s1
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	032080e7          	jalr	50(ra) # 80000be4 <acquire>
  reparent(p);
    80002bba:	854e                	mv	a0,s3
    80002bbc:	00000097          	auipc	ra,0x0
    80002bc0:	f1a080e7          	jalr	-230(ra) # 80002ad6 <reparent>
  wakeup(p->parent);
    80002bc4:	0389b503          	ld	a0,56(s3)
    80002bc8:	00000097          	auipc	ra,0x0
    80002bcc:	e10080e7          	jalr	-496(ra) # 800029d8 <wakeup>
  acquire(&p->lock);
    80002bd0:	854e                	mv	a0,s3
    80002bd2:	ffffe097          	auipc	ra,0xffffe
    80002bd6:	012080e7          	jalr	18(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002bda:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002bde:	4795                	li	a5,5
    80002be0:	00f9ac23          	sw	a5,24(s3)
  printf("insert exit zombie %d\n", p->index); //delete
    80002be4:	16c9a583          	lw	a1,364(s3)
    80002be8:	00006517          	auipc	a0,0x6
    80002bec:	85850513          	addi	a0,a0,-1960 # 80008440 <digits+0x400>
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	998080e7          	jalr	-1640(ra) # 80000588 <printf>
  insert_proc_to_list(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    80002bf8:	85ce                	mv	a1,s3
    80002bfa:	00006517          	auipc	a0,0x6
    80002bfe:	e0e50513          	addi	a0,a0,-498 # 80008a08 <zombie_list>
    80002c02:	fffff097          	auipc	ra,0xfffff
    80002c06:	d1e080e7          	jalr	-738(ra) # 80001920 <insert_proc_to_list>
  release(&wait_lock);
    80002c0a:	8526                	mv	a0,s1
    80002c0c:	ffffe097          	auipc	ra,0xffffe
    80002c10:	08c080e7          	jalr	140(ra) # 80000c98 <release>
  sched();
    80002c14:	fffff097          	auipc	ra,0xfffff
    80002c18:	658080e7          	jalr	1624(ra) # 8000226c <sched>
  panic("zombie exit");
    80002c1c:	00006517          	auipc	a0,0x6
    80002c20:	83c50513          	addi	a0,a0,-1988 # 80008458 <digits+0x418>
    80002c24:	ffffe097          	auipc	ra,0xffffe
    80002c28:	91a080e7          	jalr	-1766(ra) # 8000053e <panic>

0000000080002c2c <swtch>:
    80002c2c:	00153023          	sd	ra,0(a0)
    80002c30:	00253423          	sd	sp,8(a0)
    80002c34:	e900                	sd	s0,16(a0)
    80002c36:	ed04                	sd	s1,24(a0)
    80002c38:	03253023          	sd	s2,32(a0)
    80002c3c:	03353423          	sd	s3,40(a0)
    80002c40:	03453823          	sd	s4,48(a0)
    80002c44:	03553c23          	sd	s5,56(a0)
    80002c48:	05653023          	sd	s6,64(a0)
    80002c4c:	05753423          	sd	s7,72(a0)
    80002c50:	05853823          	sd	s8,80(a0)
    80002c54:	05953c23          	sd	s9,88(a0)
    80002c58:	07a53023          	sd	s10,96(a0)
    80002c5c:	07b53423          	sd	s11,104(a0)
    80002c60:	0005b083          	ld	ra,0(a1)
    80002c64:	0085b103          	ld	sp,8(a1)
    80002c68:	6980                	ld	s0,16(a1)
    80002c6a:	6d84                	ld	s1,24(a1)
    80002c6c:	0205b903          	ld	s2,32(a1)
    80002c70:	0285b983          	ld	s3,40(a1)
    80002c74:	0305ba03          	ld	s4,48(a1)
    80002c78:	0385ba83          	ld	s5,56(a1)
    80002c7c:	0405bb03          	ld	s6,64(a1)
    80002c80:	0485bb83          	ld	s7,72(a1)
    80002c84:	0505bc03          	ld	s8,80(a1)
    80002c88:	0585bc83          	ld	s9,88(a1)
    80002c8c:	0605bd03          	ld	s10,96(a1)
    80002c90:	0685bd83          	ld	s11,104(a1)
    80002c94:	8082                	ret

0000000080002c96 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c96:	1141                	addi	sp,sp,-16
    80002c98:	e406                	sd	ra,8(sp)
    80002c9a:	e022                	sd	s0,0(sp)
    80002c9c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c9e:	00006597          	auipc	a1,0x6
    80002ca2:	82258593          	addi	a1,a1,-2014 # 800084c0 <states.1797+0x30>
    80002ca6:	00015517          	auipc	a0,0x15
    80002caa:	8ea50513          	addi	a0,a0,-1814 # 80017590 <tickslock>
    80002cae:	ffffe097          	auipc	ra,0xffffe
    80002cb2:	ea6080e7          	jalr	-346(ra) # 80000b54 <initlock>
}
    80002cb6:	60a2                	ld	ra,8(sp)
    80002cb8:	6402                	ld	s0,0(sp)
    80002cba:	0141                	addi	sp,sp,16
    80002cbc:	8082                	ret

0000000080002cbe <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002cbe:	1141                	addi	sp,sp,-16
    80002cc0:	e422                	sd	s0,8(sp)
    80002cc2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cc4:	00003797          	auipc	a5,0x3
    80002cc8:	4fc78793          	addi	a5,a5,1276 # 800061c0 <kernelvec>
    80002ccc:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002cd0:	6422                	ld	s0,8(sp)
    80002cd2:	0141                	addi	sp,sp,16
    80002cd4:	8082                	ret

0000000080002cd6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002cd6:	1141                	addi	sp,sp,-16
    80002cd8:	e406                	sd	ra,8(sp)
    80002cda:	e022                	sd	s0,0(sp)
    80002cdc:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	056080e7          	jalr	86(ra) # 80001d34 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ce6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002cea:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cec:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002cf0:	00004617          	auipc	a2,0x4
    80002cf4:	31060613          	addi	a2,a2,784 # 80007000 <_trampoline>
    80002cf8:	00004697          	auipc	a3,0x4
    80002cfc:	30868693          	addi	a3,a3,776 # 80007000 <_trampoline>
    80002d00:	8e91                	sub	a3,a3,a2
    80002d02:	040007b7          	lui	a5,0x4000
    80002d06:	17fd                	addi	a5,a5,-1
    80002d08:	07b2                	slli	a5,a5,0xc
    80002d0a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d0c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d10:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d12:	180026f3          	csrr	a3,satp
    80002d16:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d18:	6d38                	ld	a4,88(a0)
    80002d1a:	6134                	ld	a3,64(a0)
    80002d1c:	6585                	lui	a1,0x1
    80002d1e:	96ae                	add	a3,a3,a1
    80002d20:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d22:	6d38                	ld	a4,88(a0)
    80002d24:	00000697          	auipc	a3,0x0
    80002d28:	13868693          	addi	a3,a3,312 # 80002e5c <usertrap>
    80002d2c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d2e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d30:	8692                	mv	a3,tp
    80002d32:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d34:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d38:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d3c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d40:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d44:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d46:	6f18                	ld	a4,24(a4)
    80002d48:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d4c:	692c                	ld	a1,80(a0)
    80002d4e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002d50:	00004717          	auipc	a4,0x4
    80002d54:	34070713          	addi	a4,a4,832 # 80007090 <userret>
    80002d58:	8f11                	sub	a4,a4,a2
    80002d5a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002d5c:	577d                	li	a4,-1
    80002d5e:	177e                	slli	a4,a4,0x3f
    80002d60:	8dd9                	or	a1,a1,a4
    80002d62:	02000537          	lui	a0,0x2000
    80002d66:	157d                	addi	a0,a0,-1
    80002d68:	0536                	slli	a0,a0,0xd
    80002d6a:	9782                	jalr	a5
}
    80002d6c:	60a2                	ld	ra,8(sp)
    80002d6e:	6402                	ld	s0,0(sp)
    80002d70:	0141                	addi	sp,sp,16
    80002d72:	8082                	ret

0000000080002d74 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d74:	1101                	addi	sp,sp,-32
    80002d76:	ec06                	sd	ra,24(sp)
    80002d78:	e822                	sd	s0,16(sp)
    80002d7a:	e426                	sd	s1,8(sp)
    80002d7c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d7e:	00015497          	auipc	s1,0x15
    80002d82:	81248493          	addi	s1,s1,-2030 # 80017590 <tickslock>
    80002d86:	8526                	mv	a0,s1
    80002d88:	ffffe097          	auipc	ra,0xffffe
    80002d8c:	e5c080e7          	jalr	-420(ra) # 80000be4 <acquire>
  ticks++;
    80002d90:	00006517          	auipc	a0,0x6
    80002d94:	2a050513          	addi	a0,a0,672 # 80009030 <ticks>
    80002d98:	411c                	lw	a5,0(a0)
    80002d9a:	2785                	addiw	a5,a5,1
    80002d9c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d9e:	00000097          	auipc	ra,0x0
    80002da2:	c3a080e7          	jalr	-966(ra) # 800029d8 <wakeup>
  release(&tickslock);
    80002da6:	8526                	mv	a0,s1
    80002da8:	ffffe097          	auipc	ra,0xffffe
    80002dac:	ef0080e7          	jalr	-272(ra) # 80000c98 <release>
}
    80002db0:	60e2                	ld	ra,24(sp)
    80002db2:	6442                	ld	s0,16(sp)
    80002db4:	64a2                	ld	s1,8(sp)
    80002db6:	6105                	addi	sp,sp,32
    80002db8:	8082                	ret

0000000080002dba <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002dba:	1101                	addi	sp,sp,-32
    80002dbc:	ec06                	sd	ra,24(sp)
    80002dbe:	e822                	sd	s0,16(sp)
    80002dc0:	e426                	sd	s1,8(sp)
    80002dc2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dc4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002dc8:	00074d63          	bltz	a4,80002de2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002dcc:	57fd                	li	a5,-1
    80002dce:	17fe                	slli	a5,a5,0x3f
    80002dd0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002dd2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002dd4:	06f70363          	beq	a4,a5,80002e3a <devintr+0x80>
  }
}
    80002dd8:	60e2                	ld	ra,24(sp)
    80002dda:	6442                	ld	s0,16(sp)
    80002ddc:	64a2                	ld	s1,8(sp)
    80002dde:	6105                	addi	sp,sp,32
    80002de0:	8082                	ret
     (scause & 0xff) == 9){
    80002de2:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002de6:	46a5                	li	a3,9
    80002de8:	fed792e3          	bne	a5,a3,80002dcc <devintr+0x12>
    int irq = plic_claim();
    80002dec:	00003097          	auipc	ra,0x3
    80002df0:	4dc080e7          	jalr	1244(ra) # 800062c8 <plic_claim>
    80002df4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002df6:	47a9                	li	a5,10
    80002df8:	02f50763          	beq	a0,a5,80002e26 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002dfc:	4785                	li	a5,1
    80002dfe:	02f50963          	beq	a0,a5,80002e30 <devintr+0x76>
    return 1;
    80002e02:	4505                	li	a0,1
    } else if(irq){
    80002e04:	d8f1                	beqz	s1,80002dd8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e06:	85a6                	mv	a1,s1
    80002e08:	00005517          	auipc	a0,0x5
    80002e0c:	6c050513          	addi	a0,a0,1728 # 800084c8 <states.1797+0x38>
    80002e10:	ffffd097          	auipc	ra,0xffffd
    80002e14:	778080e7          	jalr	1912(ra) # 80000588 <printf>
      plic_complete(irq);
    80002e18:	8526                	mv	a0,s1
    80002e1a:	00003097          	auipc	ra,0x3
    80002e1e:	4d2080e7          	jalr	1234(ra) # 800062ec <plic_complete>
    return 1;
    80002e22:	4505                	li	a0,1
    80002e24:	bf55                	j	80002dd8 <devintr+0x1e>
      uartintr();
    80002e26:	ffffe097          	auipc	ra,0xffffe
    80002e2a:	b82080e7          	jalr	-1150(ra) # 800009a8 <uartintr>
    80002e2e:	b7ed                	j	80002e18 <devintr+0x5e>
      virtio_disk_intr();
    80002e30:	00004097          	auipc	ra,0x4
    80002e34:	99c080e7          	jalr	-1636(ra) # 800067cc <virtio_disk_intr>
    80002e38:	b7c5                	j	80002e18 <devintr+0x5e>
    if(cpuid() == 0){
    80002e3a:	fffff097          	auipc	ra,0xfffff
    80002e3e:	ec8080e7          	jalr	-312(ra) # 80001d02 <cpuid>
    80002e42:	c901                	beqz	a0,80002e52 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e44:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e48:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e4a:	14479073          	csrw	sip,a5
    return 2;
    80002e4e:	4509                	li	a0,2
    80002e50:	b761                	j	80002dd8 <devintr+0x1e>
      clockintr();
    80002e52:	00000097          	auipc	ra,0x0
    80002e56:	f22080e7          	jalr	-222(ra) # 80002d74 <clockintr>
    80002e5a:	b7ed                	j	80002e44 <devintr+0x8a>

0000000080002e5c <usertrap>:
{
    80002e5c:	1101                	addi	sp,sp,-32
    80002e5e:	ec06                	sd	ra,24(sp)
    80002e60:	e822                	sd	s0,16(sp)
    80002e62:	e426                	sd	s1,8(sp)
    80002e64:	e04a                	sd	s2,0(sp)
    80002e66:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e68:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e6c:	1007f793          	andi	a5,a5,256
    80002e70:	e3ad                	bnez	a5,80002ed2 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e72:	00003797          	auipc	a5,0x3
    80002e76:	34e78793          	addi	a5,a5,846 # 800061c0 <kernelvec>
    80002e7a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e7e:	fffff097          	auipc	ra,0xfffff
    80002e82:	eb6080e7          	jalr	-330(ra) # 80001d34 <myproc>
    80002e86:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e88:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e8a:	14102773          	csrr	a4,sepc
    80002e8e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e90:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e94:	47a1                	li	a5,8
    80002e96:	04f71c63          	bne	a4,a5,80002eee <usertrap+0x92>
    if(p->killed)
    80002e9a:	551c                	lw	a5,40(a0)
    80002e9c:	e3b9                	bnez	a5,80002ee2 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002e9e:	6cb8                	ld	a4,88(s1)
    80002ea0:	6f1c                	ld	a5,24(a4)
    80002ea2:	0791                	addi	a5,a5,4
    80002ea4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ea6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002eaa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002eae:	10079073          	csrw	sstatus,a5
    syscall();
    80002eb2:	00000097          	auipc	ra,0x0
    80002eb6:	2e0080e7          	jalr	736(ra) # 80003192 <syscall>
  if(p->killed)
    80002eba:	549c                	lw	a5,40(s1)
    80002ebc:	ebc1                	bnez	a5,80002f4c <usertrap+0xf0>
  usertrapret();
    80002ebe:	00000097          	auipc	ra,0x0
    80002ec2:	e18080e7          	jalr	-488(ra) # 80002cd6 <usertrapret>
}
    80002ec6:	60e2                	ld	ra,24(sp)
    80002ec8:	6442                	ld	s0,16(sp)
    80002eca:	64a2                	ld	s1,8(sp)
    80002ecc:	6902                	ld	s2,0(sp)
    80002ece:	6105                	addi	sp,sp,32
    80002ed0:	8082                	ret
    panic("usertrap: not from user mode");
    80002ed2:	00005517          	auipc	a0,0x5
    80002ed6:	61650513          	addi	a0,a0,1558 # 800084e8 <states.1797+0x58>
    80002eda:	ffffd097          	auipc	ra,0xffffd
    80002ede:	664080e7          	jalr	1636(ra) # 8000053e <panic>
      exit(-1);
    80002ee2:	557d                	li	a0,-1
    80002ee4:	00000097          	auipc	ra,0x0
    80002ee8:	c4c080e7          	jalr	-948(ra) # 80002b30 <exit>
    80002eec:	bf4d                	j	80002e9e <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002eee:	00000097          	auipc	ra,0x0
    80002ef2:	ecc080e7          	jalr	-308(ra) # 80002dba <devintr>
    80002ef6:	892a                	mv	s2,a0
    80002ef8:	c501                	beqz	a0,80002f00 <usertrap+0xa4>
  if(p->killed)
    80002efa:	549c                	lw	a5,40(s1)
    80002efc:	c3a1                	beqz	a5,80002f3c <usertrap+0xe0>
    80002efe:	a815                	j	80002f32 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f00:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f04:	5890                	lw	a2,48(s1)
    80002f06:	00005517          	auipc	a0,0x5
    80002f0a:	60250513          	addi	a0,a0,1538 # 80008508 <states.1797+0x78>
    80002f0e:	ffffd097          	auipc	ra,0xffffd
    80002f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f16:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f1a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f1e:	00005517          	auipc	a0,0x5
    80002f22:	61a50513          	addi	a0,a0,1562 # 80008538 <states.1797+0xa8>
    80002f26:	ffffd097          	auipc	ra,0xffffd
    80002f2a:	662080e7          	jalr	1634(ra) # 80000588 <printf>
    p->killed = 1;
    80002f2e:	4785                	li	a5,1
    80002f30:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002f32:	557d                	li	a0,-1
    80002f34:	00000097          	auipc	ra,0x0
    80002f38:	bfc080e7          	jalr	-1028(ra) # 80002b30 <exit>
  if(which_dev == 2)
    80002f3c:	4789                	li	a5,2
    80002f3e:	f8f910e3          	bne	s2,a5,80002ebe <usertrap+0x62>
    yield();
    80002f42:	fffff097          	auipc	ra,0xfffff
    80002f46:	40c080e7          	jalr	1036(ra) # 8000234e <yield>
    80002f4a:	bf95                	j	80002ebe <usertrap+0x62>
  int which_dev = 0;
    80002f4c:	4901                	li	s2,0
    80002f4e:	b7d5                	j	80002f32 <usertrap+0xd6>

0000000080002f50 <kerneltrap>:
{
    80002f50:	7179                	addi	sp,sp,-48
    80002f52:	f406                	sd	ra,40(sp)
    80002f54:	f022                	sd	s0,32(sp)
    80002f56:	ec26                	sd	s1,24(sp)
    80002f58:	e84a                	sd	s2,16(sp)
    80002f5a:	e44e                	sd	s3,8(sp)
    80002f5c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f5e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f62:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f66:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f6a:	1004f793          	andi	a5,s1,256
    80002f6e:	cb85                	beqz	a5,80002f9e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f70:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f74:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f76:	ef85                	bnez	a5,80002fae <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f78:	00000097          	auipc	ra,0x0
    80002f7c:	e42080e7          	jalr	-446(ra) # 80002dba <devintr>
    80002f80:	cd1d                	beqz	a0,80002fbe <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f82:	4789                	li	a5,2
    80002f84:	06f50a63          	beq	a0,a5,80002ff8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f88:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f8c:	10049073          	csrw	sstatus,s1
}
    80002f90:	70a2                	ld	ra,40(sp)
    80002f92:	7402                	ld	s0,32(sp)
    80002f94:	64e2                	ld	s1,24(sp)
    80002f96:	6942                	ld	s2,16(sp)
    80002f98:	69a2                	ld	s3,8(sp)
    80002f9a:	6145                	addi	sp,sp,48
    80002f9c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f9e:	00005517          	auipc	a0,0x5
    80002fa2:	5ba50513          	addi	a0,a0,1466 # 80008558 <states.1797+0xc8>
    80002fa6:	ffffd097          	auipc	ra,0xffffd
    80002faa:	598080e7          	jalr	1432(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002fae:	00005517          	auipc	a0,0x5
    80002fb2:	5d250513          	addi	a0,a0,1490 # 80008580 <states.1797+0xf0>
    80002fb6:	ffffd097          	auipc	ra,0xffffd
    80002fba:	588080e7          	jalr	1416(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002fbe:	85ce                	mv	a1,s3
    80002fc0:	00005517          	auipc	a0,0x5
    80002fc4:	5e050513          	addi	a0,a0,1504 # 800085a0 <states.1797+0x110>
    80002fc8:	ffffd097          	auipc	ra,0xffffd
    80002fcc:	5c0080e7          	jalr	1472(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fd0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fd4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fd8:	00005517          	auipc	a0,0x5
    80002fdc:	5d850513          	addi	a0,a0,1496 # 800085b0 <states.1797+0x120>
    80002fe0:	ffffd097          	auipc	ra,0xffffd
    80002fe4:	5a8080e7          	jalr	1448(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002fe8:	00005517          	auipc	a0,0x5
    80002fec:	5e050513          	addi	a0,a0,1504 # 800085c8 <states.1797+0x138>
    80002ff0:	ffffd097          	auipc	ra,0xffffd
    80002ff4:	54e080e7          	jalr	1358(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ff8:	fffff097          	auipc	ra,0xfffff
    80002ffc:	d3c080e7          	jalr	-708(ra) # 80001d34 <myproc>
    80003000:	d541                	beqz	a0,80002f88 <kerneltrap+0x38>
    80003002:	fffff097          	auipc	ra,0xfffff
    80003006:	d32080e7          	jalr	-718(ra) # 80001d34 <myproc>
    8000300a:	4d18                	lw	a4,24(a0)
    8000300c:	4791                	li	a5,4
    8000300e:	f6f71de3          	bne	a4,a5,80002f88 <kerneltrap+0x38>
    yield();
    80003012:	fffff097          	auipc	ra,0xfffff
    80003016:	33c080e7          	jalr	828(ra) # 8000234e <yield>
    8000301a:	b7bd                	j	80002f88 <kerneltrap+0x38>

000000008000301c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000301c:	1101                	addi	sp,sp,-32
    8000301e:	ec06                	sd	ra,24(sp)
    80003020:	e822                	sd	s0,16(sp)
    80003022:	e426                	sd	s1,8(sp)
    80003024:	1000                	addi	s0,sp,32
    80003026:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003028:	fffff097          	auipc	ra,0xfffff
    8000302c:	d0c080e7          	jalr	-756(ra) # 80001d34 <myproc>
  switch (n) {
    80003030:	4795                	li	a5,5
    80003032:	0497e163          	bltu	a5,s1,80003074 <argraw+0x58>
    80003036:	048a                	slli	s1,s1,0x2
    80003038:	00005717          	auipc	a4,0x5
    8000303c:	5c870713          	addi	a4,a4,1480 # 80008600 <states.1797+0x170>
    80003040:	94ba                	add	s1,s1,a4
    80003042:	409c                	lw	a5,0(s1)
    80003044:	97ba                	add	a5,a5,a4
    80003046:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003048:	6d3c                	ld	a5,88(a0)
    8000304a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000304c:	60e2                	ld	ra,24(sp)
    8000304e:	6442                	ld	s0,16(sp)
    80003050:	64a2                	ld	s1,8(sp)
    80003052:	6105                	addi	sp,sp,32
    80003054:	8082                	ret
    return p->trapframe->a1;
    80003056:	6d3c                	ld	a5,88(a0)
    80003058:	7fa8                	ld	a0,120(a5)
    8000305a:	bfcd                	j	8000304c <argraw+0x30>
    return p->trapframe->a2;
    8000305c:	6d3c                	ld	a5,88(a0)
    8000305e:	63c8                	ld	a0,128(a5)
    80003060:	b7f5                	j	8000304c <argraw+0x30>
    return p->trapframe->a3;
    80003062:	6d3c                	ld	a5,88(a0)
    80003064:	67c8                	ld	a0,136(a5)
    80003066:	b7dd                	j	8000304c <argraw+0x30>
    return p->trapframe->a4;
    80003068:	6d3c                	ld	a5,88(a0)
    8000306a:	6bc8                	ld	a0,144(a5)
    8000306c:	b7c5                	j	8000304c <argraw+0x30>
    return p->trapframe->a5;
    8000306e:	6d3c                	ld	a5,88(a0)
    80003070:	6fc8                	ld	a0,152(a5)
    80003072:	bfe9                	j	8000304c <argraw+0x30>
  panic("argraw");
    80003074:	00005517          	auipc	a0,0x5
    80003078:	56450513          	addi	a0,a0,1380 # 800085d8 <states.1797+0x148>
    8000307c:	ffffd097          	auipc	ra,0xffffd
    80003080:	4c2080e7          	jalr	1218(ra) # 8000053e <panic>

0000000080003084 <fetchaddr>:
{
    80003084:	1101                	addi	sp,sp,-32
    80003086:	ec06                	sd	ra,24(sp)
    80003088:	e822                	sd	s0,16(sp)
    8000308a:	e426                	sd	s1,8(sp)
    8000308c:	e04a                	sd	s2,0(sp)
    8000308e:	1000                	addi	s0,sp,32
    80003090:	84aa                	mv	s1,a0
    80003092:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003094:	fffff097          	auipc	ra,0xfffff
    80003098:	ca0080e7          	jalr	-864(ra) # 80001d34 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000309c:	653c                	ld	a5,72(a0)
    8000309e:	02f4f863          	bgeu	s1,a5,800030ce <fetchaddr+0x4a>
    800030a2:	00848713          	addi	a4,s1,8
    800030a6:	02e7e663          	bltu	a5,a4,800030d2 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800030aa:	46a1                	li	a3,8
    800030ac:	8626                	mv	a2,s1
    800030ae:	85ca                	mv	a1,s2
    800030b0:	6928                	ld	a0,80(a0)
    800030b2:	ffffe097          	auipc	ra,0xffffe
    800030b6:	64c080e7          	jalr	1612(ra) # 800016fe <copyin>
    800030ba:	00a03533          	snez	a0,a0
    800030be:	40a00533          	neg	a0,a0
}
    800030c2:	60e2                	ld	ra,24(sp)
    800030c4:	6442                	ld	s0,16(sp)
    800030c6:	64a2                	ld	s1,8(sp)
    800030c8:	6902                	ld	s2,0(sp)
    800030ca:	6105                	addi	sp,sp,32
    800030cc:	8082                	ret
    return -1;
    800030ce:	557d                	li	a0,-1
    800030d0:	bfcd                	j	800030c2 <fetchaddr+0x3e>
    800030d2:	557d                	li	a0,-1
    800030d4:	b7fd                	j	800030c2 <fetchaddr+0x3e>

00000000800030d6 <fetchstr>:
{
    800030d6:	7179                	addi	sp,sp,-48
    800030d8:	f406                	sd	ra,40(sp)
    800030da:	f022                	sd	s0,32(sp)
    800030dc:	ec26                	sd	s1,24(sp)
    800030de:	e84a                	sd	s2,16(sp)
    800030e0:	e44e                	sd	s3,8(sp)
    800030e2:	1800                	addi	s0,sp,48
    800030e4:	892a                	mv	s2,a0
    800030e6:	84ae                	mv	s1,a1
    800030e8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800030ea:	fffff097          	auipc	ra,0xfffff
    800030ee:	c4a080e7          	jalr	-950(ra) # 80001d34 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800030f2:	86ce                	mv	a3,s3
    800030f4:	864a                	mv	a2,s2
    800030f6:	85a6                	mv	a1,s1
    800030f8:	6928                	ld	a0,80(a0)
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	690080e7          	jalr	1680(ra) # 8000178a <copyinstr>
  if(err < 0)
    80003102:	00054763          	bltz	a0,80003110 <fetchstr+0x3a>
  return strlen(buf);
    80003106:	8526                	mv	a0,s1
    80003108:	ffffe097          	auipc	ra,0xffffe
    8000310c:	d5c080e7          	jalr	-676(ra) # 80000e64 <strlen>
}
    80003110:	70a2                	ld	ra,40(sp)
    80003112:	7402                	ld	s0,32(sp)
    80003114:	64e2                	ld	s1,24(sp)
    80003116:	6942                	ld	s2,16(sp)
    80003118:	69a2                	ld	s3,8(sp)
    8000311a:	6145                	addi	sp,sp,48
    8000311c:	8082                	ret

000000008000311e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000311e:	1101                	addi	sp,sp,-32
    80003120:	ec06                	sd	ra,24(sp)
    80003122:	e822                	sd	s0,16(sp)
    80003124:	e426                	sd	s1,8(sp)
    80003126:	1000                	addi	s0,sp,32
    80003128:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000312a:	00000097          	auipc	ra,0x0
    8000312e:	ef2080e7          	jalr	-270(ra) # 8000301c <argraw>
    80003132:	c088                	sw	a0,0(s1)
  return 0;
}
    80003134:	4501                	li	a0,0
    80003136:	60e2                	ld	ra,24(sp)
    80003138:	6442                	ld	s0,16(sp)
    8000313a:	64a2                	ld	s1,8(sp)
    8000313c:	6105                	addi	sp,sp,32
    8000313e:	8082                	ret

0000000080003140 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003140:	1101                	addi	sp,sp,-32
    80003142:	ec06                	sd	ra,24(sp)
    80003144:	e822                	sd	s0,16(sp)
    80003146:	e426                	sd	s1,8(sp)
    80003148:	1000                	addi	s0,sp,32
    8000314a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000314c:	00000097          	auipc	ra,0x0
    80003150:	ed0080e7          	jalr	-304(ra) # 8000301c <argraw>
    80003154:	e088                	sd	a0,0(s1)
  return 0;
}
    80003156:	4501                	li	a0,0
    80003158:	60e2                	ld	ra,24(sp)
    8000315a:	6442                	ld	s0,16(sp)
    8000315c:	64a2                	ld	s1,8(sp)
    8000315e:	6105                	addi	sp,sp,32
    80003160:	8082                	ret

0000000080003162 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003162:	1101                	addi	sp,sp,-32
    80003164:	ec06                	sd	ra,24(sp)
    80003166:	e822                	sd	s0,16(sp)
    80003168:	e426                	sd	s1,8(sp)
    8000316a:	e04a                	sd	s2,0(sp)
    8000316c:	1000                	addi	s0,sp,32
    8000316e:	84ae                	mv	s1,a1
    80003170:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003172:	00000097          	auipc	ra,0x0
    80003176:	eaa080e7          	jalr	-342(ra) # 8000301c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000317a:	864a                	mv	a2,s2
    8000317c:	85a6                	mv	a1,s1
    8000317e:	00000097          	auipc	ra,0x0
    80003182:	f58080e7          	jalr	-168(ra) # 800030d6 <fetchstr>
}
    80003186:	60e2                	ld	ra,24(sp)
    80003188:	6442                	ld	s0,16(sp)
    8000318a:	64a2                	ld	s1,8(sp)
    8000318c:	6902                	ld	s2,0(sp)
    8000318e:	6105                	addi	sp,sp,32
    80003190:	8082                	ret

0000000080003192 <syscall>:
[SYS_cpu_process_count]   sys_cpu_process_count,
};

void
syscall(void)
{
    80003192:	1101                	addi	sp,sp,-32
    80003194:	ec06                	sd	ra,24(sp)
    80003196:	e822                	sd	s0,16(sp)
    80003198:	e426                	sd	s1,8(sp)
    8000319a:	e04a                	sd	s2,0(sp)
    8000319c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000319e:	fffff097          	auipc	ra,0xfffff
    800031a2:	b96080e7          	jalr	-1130(ra) # 80001d34 <myproc>
    800031a6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800031a8:	05853903          	ld	s2,88(a0)
    800031ac:	0a893783          	ld	a5,168(s2)
    800031b0:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800031b4:	37fd                	addiw	a5,a5,-1
    800031b6:	475d                	li	a4,23
    800031b8:	00f76f63          	bltu	a4,a5,800031d6 <syscall+0x44>
    800031bc:	00369713          	slli	a4,a3,0x3
    800031c0:	00005797          	auipc	a5,0x5
    800031c4:	45878793          	addi	a5,a5,1112 # 80008618 <syscalls>
    800031c8:	97ba                	add	a5,a5,a4
    800031ca:	639c                	ld	a5,0(a5)
    800031cc:	c789                	beqz	a5,800031d6 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800031ce:	9782                	jalr	a5
    800031d0:	06a93823          	sd	a0,112(s2)
    800031d4:	a839                	j	800031f2 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800031d6:	15848613          	addi	a2,s1,344
    800031da:	588c                	lw	a1,48(s1)
    800031dc:	00005517          	auipc	a0,0x5
    800031e0:	40450513          	addi	a0,a0,1028 # 800085e0 <states.1797+0x150>
    800031e4:	ffffd097          	auipc	ra,0xffffd
    800031e8:	3a4080e7          	jalr	932(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800031ec:	6cbc                	ld	a5,88(s1)
    800031ee:	577d                	li	a4,-1
    800031f0:	fbb8                	sd	a4,112(a5)
  }
}
    800031f2:	60e2                	ld	ra,24(sp)
    800031f4:	6442                	ld	s0,16(sp)
    800031f6:	64a2                	ld	s1,8(sp)
    800031f8:	6902                	ld	s2,0(sp)
    800031fa:	6105                	addi	sp,sp,32
    800031fc:	8082                	ret

00000000800031fe <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800031fe:	1101                	addi	sp,sp,-32
    80003200:	ec06                	sd	ra,24(sp)
    80003202:	e822                	sd	s0,16(sp)
    80003204:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003206:	fec40593          	addi	a1,s0,-20
    8000320a:	4501                	li	a0,0
    8000320c:	00000097          	auipc	ra,0x0
    80003210:	f12080e7          	jalr	-238(ra) # 8000311e <argint>
    return -1;
    80003214:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003216:	00054963          	bltz	a0,80003228 <sys_exit+0x2a>
  exit(n);
    8000321a:	fec42503          	lw	a0,-20(s0)
    8000321e:	00000097          	auipc	ra,0x0
    80003222:	912080e7          	jalr	-1774(ra) # 80002b30 <exit>
  return 0;  // not reached
    80003226:	4781                	li	a5,0
}
    80003228:	853e                	mv	a0,a5
    8000322a:	60e2                	ld	ra,24(sp)
    8000322c:	6442                	ld	s0,16(sp)
    8000322e:	6105                	addi	sp,sp,32
    80003230:	8082                	ret

0000000080003232 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003232:	1141                	addi	sp,sp,-16
    80003234:	e406                	sd	ra,8(sp)
    80003236:	e022                	sd	s0,0(sp)
    80003238:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000323a:	fffff097          	auipc	ra,0xfffff
    8000323e:	afa080e7          	jalr	-1286(ra) # 80001d34 <myproc>
}
    80003242:	5908                	lw	a0,48(a0)
    80003244:	60a2                	ld	ra,8(sp)
    80003246:	6402                	ld	s0,0(sp)
    80003248:	0141                	addi	sp,sp,16
    8000324a:	8082                	ret

000000008000324c <sys_fork>:

uint64
sys_fork(void)
{
    8000324c:	1141                	addi	sp,sp,-16
    8000324e:	e406                	sd	ra,8(sp)
    80003250:	e022                	sd	s0,0(sp)
    80003252:	0800                	addi	s0,sp,16
  return fork();
    80003254:	fffff097          	auipc	ra,0xfffff
    80003258:	5fc080e7          	jalr	1532(ra) # 80002850 <fork>
}
    8000325c:	60a2                	ld	ra,8(sp)
    8000325e:	6402                	ld	s0,0(sp)
    80003260:	0141                	addi	sp,sp,16
    80003262:	8082                	ret

0000000080003264 <sys_wait>:

uint64
sys_wait(void)
{
    80003264:	1101                	addi	sp,sp,-32
    80003266:	ec06                	sd	ra,24(sp)
    80003268:	e822                	sd	s0,16(sp)
    8000326a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000326c:	fe840593          	addi	a1,s0,-24
    80003270:	4501                	li	a0,0
    80003272:	00000097          	auipc	ra,0x0
    80003276:	ece080e7          	jalr	-306(ra) # 80003140 <argaddr>
    8000327a:	87aa                	mv	a5,a0
    return -1;
    8000327c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000327e:	0007c863          	bltz	a5,8000328e <sys_wait+0x2a>
  return wait(p);
    80003282:	fe843503          	ld	a0,-24(s0)
    80003286:	fffff097          	auipc	ra,0xfffff
    8000328a:	1c6080e7          	jalr	454(ra) # 8000244c <wait>
}
    8000328e:	60e2                	ld	ra,24(sp)
    80003290:	6442                	ld	s0,16(sp)
    80003292:	6105                	addi	sp,sp,32
    80003294:	8082                	ret

0000000080003296 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003296:	7179                	addi	sp,sp,-48
    80003298:	f406                	sd	ra,40(sp)
    8000329a:	f022                	sd	s0,32(sp)
    8000329c:	ec26                	sd	s1,24(sp)
    8000329e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800032a0:	fdc40593          	addi	a1,s0,-36
    800032a4:	4501                	li	a0,0
    800032a6:	00000097          	auipc	ra,0x0
    800032aa:	e78080e7          	jalr	-392(ra) # 8000311e <argint>
    800032ae:	87aa                	mv	a5,a0
    return -1;
    800032b0:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800032b2:	0207c063          	bltz	a5,800032d2 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800032b6:	fffff097          	auipc	ra,0xfffff
    800032ba:	a7e080e7          	jalr	-1410(ra) # 80001d34 <myproc>
    800032be:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800032c0:	fdc42503          	lw	a0,-36(s0)
    800032c4:	fffff097          	auipc	ra,0xfffff
    800032c8:	e5c080e7          	jalr	-420(ra) # 80002120 <growproc>
    800032cc:	00054863          	bltz	a0,800032dc <sys_sbrk+0x46>
    return -1;
  return addr;
    800032d0:	8526                	mv	a0,s1
}
    800032d2:	70a2                	ld	ra,40(sp)
    800032d4:	7402                	ld	s0,32(sp)
    800032d6:	64e2                	ld	s1,24(sp)
    800032d8:	6145                	addi	sp,sp,48
    800032da:	8082                	ret
    return -1;
    800032dc:	557d                	li	a0,-1
    800032de:	bfd5                	j	800032d2 <sys_sbrk+0x3c>

00000000800032e0 <sys_sleep>:

uint64
sys_sleep(void)
{
    800032e0:	7139                	addi	sp,sp,-64
    800032e2:	fc06                	sd	ra,56(sp)
    800032e4:	f822                	sd	s0,48(sp)
    800032e6:	f426                	sd	s1,40(sp)
    800032e8:	f04a                	sd	s2,32(sp)
    800032ea:	ec4e                	sd	s3,24(sp)
    800032ec:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800032ee:	fcc40593          	addi	a1,s0,-52
    800032f2:	4501                	li	a0,0
    800032f4:	00000097          	auipc	ra,0x0
    800032f8:	e2a080e7          	jalr	-470(ra) # 8000311e <argint>
    return -1;
    800032fc:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800032fe:	06054563          	bltz	a0,80003368 <sys_sleep+0x88>
  acquire(&tickslock);
    80003302:	00014517          	auipc	a0,0x14
    80003306:	28e50513          	addi	a0,a0,654 # 80017590 <tickslock>
    8000330a:	ffffe097          	auipc	ra,0xffffe
    8000330e:	8da080e7          	jalr	-1830(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003312:	00006917          	auipc	s2,0x6
    80003316:	d1e92903          	lw	s2,-738(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000331a:	fcc42783          	lw	a5,-52(s0)
    8000331e:	cf85                	beqz	a5,80003356 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003320:	00014997          	auipc	s3,0x14
    80003324:	27098993          	addi	s3,s3,624 # 80017590 <tickslock>
    80003328:	00006497          	auipc	s1,0x6
    8000332c:	d0848493          	addi	s1,s1,-760 # 80009030 <ticks>
    if(myproc()->killed){
    80003330:	fffff097          	auipc	ra,0xfffff
    80003334:	a04080e7          	jalr	-1532(ra) # 80001d34 <myproc>
    80003338:	551c                	lw	a5,40(a0)
    8000333a:	ef9d                	bnez	a5,80003378 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000333c:	85ce                	mv	a1,s3
    8000333e:	8526                	mv	a0,s1
    80003340:	fffff097          	auipc	ra,0xfffff
    80003344:	082080e7          	jalr	130(ra) # 800023c2 <sleep>
  while(ticks - ticks0 < n){
    80003348:	409c                	lw	a5,0(s1)
    8000334a:	412787bb          	subw	a5,a5,s2
    8000334e:	fcc42703          	lw	a4,-52(s0)
    80003352:	fce7efe3          	bltu	a5,a4,80003330 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003356:	00014517          	auipc	a0,0x14
    8000335a:	23a50513          	addi	a0,a0,570 # 80017590 <tickslock>
    8000335e:	ffffe097          	auipc	ra,0xffffe
    80003362:	93a080e7          	jalr	-1734(ra) # 80000c98 <release>
  return 0;
    80003366:	4781                	li	a5,0
}
    80003368:	853e                	mv	a0,a5
    8000336a:	70e2                	ld	ra,56(sp)
    8000336c:	7442                	ld	s0,48(sp)
    8000336e:	74a2                	ld	s1,40(sp)
    80003370:	7902                	ld	s2,32(sp)
    80003372:	69e2                	ld	s3,24(sp)
    80003374:	6121                	addi	sp,sp,64
    80003376:	8082                	ret
      release(&tickslock);
    80003378:	00014517          	auipc	a0,0x14
    8000337c:	21850513          	addi	a0,a0,536 # 80017590 <tickslock>
    80003380:	ffffe097          	auipc	ra,0xffffe
    80003384:	918080e7          	jalr	-1768(ra) # 80000c98 <release>
      return -1;
    80003388:	57fd                	li	a5,-1
    8000338a:	bff9                	j	80003368 <sys_sleep+0x88>

000000008000338c <sys_kill>:

uint64
sys_kill(void)
{
    8000338c:	1101                	addi	sp,sp,-32
    8000338e:	ec06                	sd	ra,24(sp)
    80003390:	e822                	sd	s0,16(sp)
    80003392:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003394:	fec40593          	addi	a1,s0,-20
    80003398:	4501                	li	a0,0
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	d84080e7          	jalr	-636(ra) # 8000311e <argint>
    800033a2:	87aa                	mv	a5,a0
    return -1;
    800033a4:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800033a6:	0007c863          	bltz	a5,800033b6 <sys_kill+0x2a>
  return kill(pid);
    800033aa:	fec42503          	lw	a0,-20(s0)
    800033ae:	fffff097          	auipc	ra,0xfffff
    800033b2:	1c6080e7          	jalr	454(ra) # 80002574 <kill>
}
    800033b6:	60e2                	ld	ra,24(sp)
    800033b8:	6442                	ld	s0,16(sp)
    800033ba:	6105                	addi	sp,sp,32
    800033bc:	8082                	ret

00000000800033be <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033be:	1101                	addi	sp,sp,-32
    800033c0:	ec06                	sd	ra,24(sp)
    800033c2:	e822                	sd	s0,16(sp)
    800033c4:	e426                	sd	s1,8(sp)
    800033c6:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800033c8:	00014517          	auipc	a0,0x14
    800033cc:	1c850513          	addi	a0,a0,456 # 80017590 <tickslock>
    800033d0:	ffffe097          	auipc	ra,0xffffe
    800033d4:	814080e7          	jalr	-2028(ra) # 80000be4 <acquire>
  xticks = ticks;
    800033d8:	00006497          	auipc	s1,0x6
    800033dc:	c584a483          	lw	s1,-936(s1) # 80009030 <ticks>
  release(&tickslock);
    800033e0:	00014517          	auipc	a0,0x14
    800033e4:	1b050513          	addi	a0,a0,432 # 80017590 <tickslock>
    800033e8:	ffffe097          	auipc	ra,0xffffe
    800033ec:	8b0080e7          	jalr	-1872(ra) # 80000c98 <release>
  return xticks;
}
    800033f0:	02049513          	slli	a0,s1,0x20
    800033f4:	9101                	srli	a0,a0,0x20
    800033f6:	60e2                	ld	ra,24(sp)
    800033f8:	6442                	ld	s0,16(sp)
    800033fa:	64a2                	ld	s1,8(sp)
    800033fc:	6105                	addi	sp,sp,32
    800033fe:	8082                	ret

0000000080003400 <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    80003400:	1101                	addi	sp,sp,-32
    80003402:	ec06                	sd	ra,24(sp)
    80003404:	e822                	sd	s0,16(sp)
    80003406:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    80003408:	fec40593          	addi	a1,s0,-20
    8000340c:	4501                	li	a0,0
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	d10080e7          	jalr	-752(ra) # 8000311e <argint>
    80003416:	87aa                	mv	a5,a0
    return -1;
    80003418:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    8000341a:	0007c863          	bltz	a5,8000342a <sys_set_cpu+0x2a>
  return set_cpu(cpu_id);
    8000341e:	fec42503          	lw	a0,-20(s0)
    80003422:	fffff097          	auipc	ra,0xfffff
    80003426:	31e080e7          	jalr	798(ra) # 80002740 <set_cpu>
}
    8000342a:	60e2                	ld	ra,24(sp)
    8000342c:	6442                	ld	s0,16(sp)
    8000342e:	6105                	addi	sp,sp,32
    80003430:	8082                	ret

0000000080003432 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    80003432:	1141                	addi	sp,sp,-16
    80003434:	e406                	sd	ra,8(sp)
    80003436:	e022                	sd	s0,0(sp)
    80003438:	0800                	addi	s0,sp,16
  return get_cpu();
    8000343a:	fffff097          	auipc	ra,0xfffff
    8000343e:	358080e7          	jalr	856(ra) # 80002792 <get_cpu>
}
    80003442:	60a2                	ld	ra,8(sp)
    80003444:	6402                	ld	s0,0(sp)
    80003446:	0141                	addi	sp,sp,16
    80003448:	8082                	ret

000000008000344a <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void)
{
    8000344a:	1101                	addi	sp,sp,-32
    8000344c:	ec06                	sd	ra,24(sp)
    8000344e:	e822                	sd	s0,16(sp)
    80003450:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    80003452:	fec40593          	addi	a1,s0,-20
    80003456:	4501                	li	a0,0
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	cc6080e7          	jalr	-826(ra) # 8000311e <argint>
    80003460:	87aa                	mv	a5,a0
    return -1;
    80003462:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    80003464:	0007c863          	bltz	a5,80003474 <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpu_id);
    80003468:	fec42503          	lw	a0,-20(s0)
    8000346c:	fffff097          	auipc	ra,0xfffff
    80003470:	380080e7          	jalr	896(ra) # 800027ec <cpu_process_count>
}
    80003474:	60e2                	ld	ra,24(sp)
    80003476:	6442                	ld	s0,16(sp)
    80003478:	6105                	addi	sp,sp,32
    8000347a:	8082                	ret

000000008000347c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000347c:	7179                	addi	sp,sp,-48
    8000347e:	f406                	sd	ra,40(sp)
    80003480:	f022                	sd	s0,32(sp)
    80003482:	ec26                	sd	s1,24(sp)
    80003484:	e84a                	sd	s2,16(sp)
    80003486:	e44e                	sd	s3,8(sp)
    80003488:	e052                	sd	s4,0(sp)
    8000348a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000348c:	00005597          	auipc	a1,0x5
    80003490:	25458593          	addi	a1,a1,596 # 800086e0 <syscalls+0xc8>
    80003494:	00014517          	auipc	a0,0x14
    80003498:	11450513          	addi	a0,a0,276 # 800175a8 <bcache>
    8000349c:	ffffd097          	auipc	ra,0xffffd
    800034a0:	6b8080e7          	jalr	1720(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034a4:	0001c797          	auipc	a5,0x1c
    800034a8:	10478793          	addi	a5,a5,260 # 8001f5a8 <bcache+0x8000>
    800034ac:	0001c717          	auipc	a4,0x1c
    800034b0:	36470713          	addi	a4,a4,868 # 8001f810 <bcache+0x8268>
    800034b4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034b8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034bc:	00014497          	auipc	s1,0x14
    800034c0:	10448493          	addi	s1,s1,260 # 800175c0 <bcache+0x18>
    b->next = bcache.head.next;
    800034c4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034c6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034c8:	00005a17          	auipc	s4,0x5
    800034cc:	220a0a13          	addi	s4,s4,544 # 800086e8 <syscalls+0xd0>
    b->next = bcache.head.next;
    800034d0:	2b893783          	ld	a5,696(s2)
    800034d4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034d6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034da:	85d2                	mv	a1,s4
    800034dc:	01048513          	addi	a0,s1,16
    800034e0:	00001097          	auipc	ra,0x1
    800034e4:	4bc080e7          	jalr	1212(ra) # 8000499c <initsleeplock>
    bcache.head.next->prev = b;
    800034e8:	2b893783          	ld	a5,696(s2)
    800034ec:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034ee:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034f2:	45848493          	addi	s1,s1,1112
    800034f6:	fd349de3          	bne	s1,s3,800034d0 <binit+0x54>
  }
}
    800034fa:	70a2                	ld	ra,40(sp)
    800034fc:	7402                	ld	s0,32(sp)
    800034fe:	64e2                	ld	s1,24(sp)
    80003500:	6942                	ld	s2,16(sp)
    80003502:	69a2                	ld	s3,8(sp)
    80003504:	6a02                	ld	s4,0(sp)
    80003506:	6145                	addi	sp,sp,48
    80003508:	8082                	ret

000000008000350a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000350a:	7179                	addi	sp,sp,-48
    8000350c:	f406                	sd	ra,40(sp)
    8000350e:	f022                	sd	s0,32(sp)
    80003510:	ec26                	sd	s1,24(sp)
    80003512:	e84a                	sd	s2,16(sp)
    80003514:	e44e                	sd	s3,8(sp)
    80003516:	1800                	addi	s0,sp,48
    80003518:	89aa                	mv	s3,a0
    8000351a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000351c:	00014517          	auipc	a0,0x14
    80003520:	08c50513          	addi	a0,a0,140 # 800175a8 <bcache>
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	6c0080e7          	jalr	1728(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000352c:	0001c497          	auipc	s1,0x1c
    80003530:	3344b483          	ld	s1,820(s1) # 8001f860 <bcache+0x82b8>
    80003534:	0001c797          	auipc	a5,0x1c
    80003538:	2dc78793          	addi	a5,a5,732 # 8001f810 <bcache+0x8268>
    8000353c:	02f48f63          	beq	s1,a5,8000357a <bread+0x70>
    80003540:	873e                	mv	a4,a5
    80003542:	a021                	j	8000354a <bread+0x40>
    80003544:	68a4                	ld	s1,80(s1)
    80003546:	02e48a63          	beq	s1,a4,8000357a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000354a:	449c                	lw	a5,8(s1)
    8000354c:	ff379ce3          	bne	a5,s3,80003544 <bread+0x3a>
    80003550:	44dc                	lw	a5,12(s1)
    80003552:	ff2799e3          	bne	a5,s2,80003544 <bread+0x3a>
      b->refcnt++;
    80003556:	40bc                	lw	a5,64(s1)
    80003558:	2785                	addiw	a5,a5,1
    8000355a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000355c:	00014517          	auipc	a0,0x14
    80003560:	04c50513          	addi	a0,a0,76 # 800175a8 <bcache>
    80003564:	ffffd097          	auipc	ra,0xffffd
    80003568:	734080e7          	jalr	1844(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000356c:	01048513          	addi	a0,s1,16
    80003570:	00001097          	auipc	ra,0x1
    80003574:	466080e7          	jalr	1126(ra) # 800049d6 <acquiresleep>
      return b;
    80003578:	a8b9                	j	800035d6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000357a:	0001c497          	auipc	s1,0x1c
    8000357e:	2de4b483          	ld	s1,734(s1) # 8001f858 <bcache+0x82b0>
    80003582:	0001c797          	auipc	a5,0x1c
    80003586:	28e78793          	addi	a5,a5,654 # 8001f810 <bcache+0x8268>
    8000358a:	00f48863          	beq	s1,a5,8000359a <bread+0x90>
    8000358e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003590:	40bc                	lw	a5,64(s1)
    80003592:	cf81                	beqz	a5,800035aa <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003594:	64a4                	ld	s1,72(s1)
    80003596:	fee49de3          	bne	s1,a4,80003590 <bread+0x86>
  panic("bget: no buffers");
    8000359a:	00005517          	auipc	a0,0x5
    8000359e:	15650513          	addi	a0,a0,342 # 800086f0 <syscalls+0xd8>
    800035a2:	ffffd097          	auipc	ra,0xffffd
    800035a6:	f9c080e7          	jalr	-100(ra) # 8000053e <panic>
      b->dev = dev;
    800035aa:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800035ae:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800035b2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035b6:	4785                	li	a5,1
    800035b8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035ba:	00014517          	auipc	a0,0x14
    800035be:	fee50513          	addi	a0,a0,-18 # 800175a8 <bcache>
    800035c2:	ffffd097          	auipc	ra,0xffffd
    800035c6:	6d6080e7          	jalr	1750(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800035ca:	01048513          	addi	a0,s1,16
    800035ce:	00001097          	auipc	ra,0x1
    800035d2:	408080e7          	jalr	1032(ra) # 800049d6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035d6:	409c                	lw	a5,0(s1)
    800035d8:	cb89                	beqz	a5,800035ea <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035da:	8526                	mv	a0,s1
    800035dc:	70a2                	ld	ra,40(sp)
    800035de:	7402                	ld	s0,32(sp)
    800035e0:	64e2                	ld	s1,24(sp)
    800035e2:	6942                	ld	s2,16(sp)
    800035e4:	69a2                	ld	s3,8(sp)
    800035e6:	6145                	addi	sp,sp,48
    800035e8:	8082                	ret
    virtio_disk_rw(b, 0);
    800035ea:	4581                	li	a1,0
    800035ec:	8526                	mv	a0,s1
    800035ee:	00003097          	auipc	ra,0x3
    800035f2:	f08080e7          	jalr	-248(ra) # 800064f6 <virtio_disk_rw>
    b->valid = 1;
    800035f6:	4785                	li	a5,1
    800035f8:	c09c                	sw	a5,0(s1)
  return b;
    800035fa:	b7c5                	j	800035da <bread+0xd0>

00000000800035fc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035fc:	1101                	addi	sp,sp,-32
    800035fe:	ec06                	sd	ra,24(sp)
    80003600:	e822                	sd	s0,16(sp)
    80003602:	e426                	sd	s1,8(sp)
    80003604:	1000                	addi	s0,sp,32
    80003606:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003608:	0541                	addi	a0,a0,16
    8000360a:	00001097          	auipc	ra,0x1
    8000360e:	466080e7          	jalr	1126(ra) # 80004a70 <holdingsleep>
    80003612:	cd01                	beqz	a0,8000362a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003614:	4585                	li	a1,1
    80003616:	8526                	mv	a0,s1
    80003618:	00003097          	auipc	ra,0x3
    8000361c:	ede080e7          	jalr	-290(ra) # 800064f6 <virtio_disk_rw>
}
    80003620:	60e2                	ld	ra,24(sp)
    80003622:	6442                	ld	s0,16(sp)
    80003624:	64a2                	ld	s1,8(sp)
    80003626:	6105                	addi	sp,sp,32
    80003628:	8082                	ret
    panic("bwrite");
    8000362a:	00005517          	auipc	a0,0x5
    8000362e:	0de50513          	addi	a0,a0,222 # 80008708 <syscalls+0xf0>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	f0c080e7          	jalr	-244(ra) # 8000053e <panic>

000000008000363a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000363a:	1101                	addi	sp,sp,-32
    8000363c:	ec06                	sd	ra,24(sp)
    8000363e:	e822                	sd	s0,16(sp)
    80003640:	e426                	sd	s1,8(sp)
    80003642:	e04a                	sd	s2,0(sp)
    80003644:	1000                	addi	s0,sp,32
    80003646:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003648:	01050913          	addi	s2,a0,16
    8000364c:	854a                	mv	a0,s2
    8000364e:	00001097          	auipc	ra,0x1
    80003652:	422080e7          	jalr	1058(ra) # 80004a70 <holdingsleep>
    80003656:	c92d                	beqz	a0,800036c8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003658:	854a                	mv	a0,s2
    8000365a:	00001097          	auipc	ra,0x1
    8000365e:	3d2080e7          	jalr	978(ra) # 80004a2c <releasesleep>

  acquire(&bcache.lock);
    80003662:	00014517          	auipc	a0,0x14
    80003666:	f4650513          	addi	a0,a0,-186 # 800175a8 <bcache>
    8000366a:	ffffd097          	auipc	ra,0xffffd
    8000366e:	57a080e7          	jalr	1402(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003672:	40bc                	lw	a5,64(s1)
    80003674:	37fd                	addiw	a5,a5,-1
    80003676:	0007871b          	sext.w	a4,a5
    8000367a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000367c:	eb05                	bnez	a4,800036ac <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000367e:	68bc                	ld	a5,80(s1)
    80003680:	64b8                	ld	a4,72(s1)
    80003682:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003684:	64bc                	ld	a5,72(s1)
    80003686:	68b8                	ld	a4,80(s1)
    80003688:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000368a:	0001c797          	auipc	a5,0x1c
    8000368e:	f1e78793          	addi	a5,a5,-226 # 8001f5a8 <bcache+0x8000>
    80003692:	2b87b703          	ld	a4,696(a5)
    80003696:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003698:	0001c717          	auipc	a4,0x1c
    8000369c:	17870713          	addi	a4,a4,376 # 8001f810 <bcache+0x8268>
    800036a0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036a2:	2b87b703          	ld	a4,696(a5)
    800036a6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036a8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036ac:	00014517          	auipc	a0,0x14
    800036b0:	efc50513          	addi	a0,a0,-260 # 800175a8 <bcache>
    800036b4:	ffffd097          	auipc	ra,0xffffd
    800036b8:	5e4080e7          	jalr	1508(ra) # 80000c98 <release>
}
    800036bc:	60e2                	ld	ra,24(sp)
    800036be:	6442                	ld	s0,16(sp)
    800036c0:	64a2                	ld	s1,8(sp)
    800036c2:	6902                	ld	s2,0(sp)
    800036c4:	6105                	addi	sp,sp,32
    800036c6:	8082                	ret
    panic("brelse");
    800036c8:	00005517          	auipc	a0,0x5
    800036cc:	04850513          	addi	a0,a0,72 # 80008710 <syscalls+0xf8>
    800036d0:	ffffd097          	auipc	ra,0xffffd
    800036d4:	e6e080e7          	jalr	-402(ra) # 8000053e <panic>

00000000800036d8 <bpin>:

void
bpin(struct buf *b) {
    800036d8:	1101                	addi	sp,sp,-32
    800036da:	ec06                	sd	ra,24(sp)
    800036dc:	e822                	sd	s0,16(sp)
    800036de:	e426                	sd	s1,8(sp)
    800036e0:	1000                	addi	s0,sp,32
    800036e2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036e4:	00014517          	auipc	a0,0x14
    800036e8:	ec450513          	addi	a0,a0,-316 # 800175a8 <bcache>
    800036ec:	ffffd097          	auipc	ra,0xffffd
    800036f0:	4f8080e7          	jalr	1272(ra) # 80000be4 <acquire>
  b->refcnt++;
    800036f4:	40bc                	lw	a5,64(s1)
    800036f6:	2785                	addiw	a5,a5,1
    800036f8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036fa:	00014517          	auipc	a0,0x14
    800036fe:	eae50513          	addi	a0,a0,-338 # 800175a8 <bcache>
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	596080e7          	jalr	1430(ra) # 80000c98 <release>
}
    8000370a:	60e2                	ld	ra,24(sp)
    8000370c:	6442                	ld	s0,16(sp)
    8000370e:	64a2                	ld	s1,8(sp)
    80003710:	6105                	addi	sp,sp,32
    80003712:	8082                	ret

0000000080003714 <bunpin>:

void
bunpin(struct buf *b) {
    80003714:	1101                	addi	sp,sp,-32
    80003716:	ec06                	sd	ra,24(sp)
    80003718:	e822                	sd	s0,16(sp)
    8000371a:	e426                	sd	s1,8(sp)
    8000371c:	1000                	addi	s0,sp,32
    8000371e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003720:	00014517          	auipc	a0,0x14
    80003724:	e8850513          	addi	a0,a0,-376 # 800175a8 <bcache>
    80003728:	ffffd097          	auipc	ra,0xffffd
    8000372c:	4bc080e7          	jalr	1212(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003730:	40bc                	lw	a5,64(s1)
    80003732:	37fd                	addiw	a5,a5,-1
    80003734:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003736:	00014517          	auipc	a0,0x14
    8000373a:	e7250513          	addi	a0,a0,-398 # 800175a8 <bcache>
    8000373e:	ffffd097          	auipc	ra,0xffffd
    80003742:	55a080e7          	jalr	1370(ra) # 80000c98 <release>
}
    80003746:	60e2                	ld	ra,24(sp)
    80003748:	6442                	ld	s0,16(sp)
    8000374a:	64a2                	ld	s1,8(sp)
    8000374c:	6105                	addi	sp,sp,32
    8000374e:	8082                	ret

0000000080003750 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003750:	1101                	addi	sp,sp,-32
    80003752:	ec06                	sd	ra,24(sp)
    80003754:	e822                	sd	s0,16(sp)
    80003756:	e426                	sd	s1,8(sp)
    80003758:	e04a                	sd	s2,0(sp)
    8000375a:	1000                	addi	s0,sp,32
    8000375c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000375e:	00d5d59b          	srliw	a1,a1,0xd
    80003762:	0001c797          	auipc	a5,0x1c
    80003766:	5227a783          	lw	a5,1314(a5) # 8001fc84 <sb+0x1c>
    8000376a:	9dbd                	addw	a1,a1,a5
    8000376c:	00000097          	auipc	ra,0x0
    80003770:	d9e080e7          	jalr	-610(ra) # 8000350a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003774:	0074f713          	andi	a4,s1,7
    80003778:	4785                	li	a5,1
    8000377a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000377e:	14ce                	slli	s1,s1,0x33
    80003780:	90d9                	srli	s1,s1,0x36
    80003782:	00950733          	add	a4,a0,s1
    80003786:	05874703          	lbu	a4,88(a4)
    8000378a:	00e7f6b3          	and	a3,a5,a4
    8000378e:	c69d                	beqz	a3,800037bc <bfree+0x6c>
    80003790:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003792:	94aa                	add	s1,s1,a0
    80003794:	fff7c793          	not	a5,a5
    80003798:	8ff9                	and	a5,a5,a4
    8000379a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000379e:	00001097          	auipc	ra,0x1
    800037a2:	118080e7          	jalr	280(ra) # 800048b6 <log_write>
  brelse(bp);
    800037a6:	854a                	mv	a0,s2
    800037a8:	00000097          	auipc	ra,0x0
    800037ac:	e92080e7          	jalr	-366(ra) # 8000363a <brelse>
}
    800037b0:	60e2                	ld	ra,24(sp)
    800037b2:	6442                	ld	s0,16(sp)
    800037b4:	64a2                	ld	s1,8(sp)
    800037b6:	6902                	ld	s2,0(sp)
    800037b8:	6105                	addi	sp,sp,32
    800037ba:	8082                	ret
    panic("freeing free block");
    800037bc:	00005517          	auipc	a0,0x5
    800037c0:	f5c50513          	addi	a0,a0,-164 # 80008718 <syscalls+0x100>
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	d7a080e7          	jalr	-646(ra) # 8000053e <panic>

00000000800037cc <balloc>:
{
    800037cc:	711d                	addi	sp,sp,-96
    800037ce:	ec86                	sd	ra,88(sp)
    800037d0:	e8a2                	sd	s0,80(sp)
    800037d2:	e4a6                	sd	s1,72(sp)
    800037d4:	e0ca                	sd	s2,64(sp)
    800037d6:	fc4e                	sd	s3,56(sp)
    800037d8:	f852                	sd	s4,48(sp)
    800037da:	f456                	sd	s5,40(sp)
    800037dc:	f05a                	sd	s6,32(sp)
    800037de:	ec5e                	sd	s7,24(sp)
    800037e0:	e862                	sd	s8,16(sp)
    800037e2:	e466                	sd	s9,8(sp)
    800037e4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037e6:	0001c797          	auipc	a5,0x1c
    800037ea:	4867a783          	lw	a5,1158(a5) # 8001fc6c <sb+0x4>
    800037ee:	cbd1                	beqz	a5,80003882 <balloc+0xb6>
    800037f0:	8baa                	mv	s7,a0
    800037f2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037f4:	0001cb17          	auipc	s6,0x1c
    800037f8:	474b0b13          	addi	s6,s6,1140 # 8001fc68 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037fc:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037fe:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003800:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003802:	6c89                	lui	s9,0x2
    80003804:	a831                	j	80003820 <balloc+0x54>
    brelse(bp);
    80003806:	854a                	mv	a0,s2
    80003808:	00000097          	auipc	ra,0x0
    8000380c:	e32080e7          	jalr	-462(ra) # 8000363a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003810:	015c87bb          	addw	a5,s9,s5
    80003814:	00078a9b          	sext.w	s5,a5
    80003818:	004b2703          	lw	a4,4(s6)
    8000381c:	06eaf363          	bgeu	s5,a4,80003882 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003820:	41fad79b          	sraiw	a5,s5,0x1f
    80003824:	0137d79b          	srliw	a5,a5,0x13
    80003828:	015787bb          	addw	a5,a5,s5
    8000382c:	40d7d79b          	sraiw	a5,a5,0xd
    80003830:	01cb2583          	lw	a1,28(s6)
    80003834:	9dbd                	addw	a1,a1,a5
    80003836:	855e                	mv	a0,s7
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	cd2080e7          	jalr	-814(ra) # 8000350a <bread>
    80003840:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003842:	004b2503          	lw	a0,4(s6)
    80003846:	000a849b          	sext.w	s1,s5
    8000384a:	8662                	mv	a2,s8
    8000384c:	faa4fde3          	bgeu	s1,a0,80003806 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003850:	41f6579b          	sraiw	a5,a2,0x1f
    80003854:	01d7d69b          	srliw	a3,a5,0x1d
    80003858:	00c6873b          	addw	a4,a3,a2
    8000385c:	00777793          	andi	a5,a4,7
    80003860:	9f95                	subw	a5,a5,a3
    80003862:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003866:	4037571b          	sraiw	a4,a4,0x3
    8000386a:	00e906b3          	add	a3,s2,a4
    8000386e:	0586c683          	lbu	a3,88(a3)
    80003872:	00d7f5b3          	and	a1,a5,a3
    80003876:	cd91                	beqz	a1,80003892 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003878:	2605                	addiw	a2,a2,1
    8000387a:	2485                	addiw	s1,s1,1
    8000387c:	fd4618e3          	bne	a2,s4,8000384c <balloc+0x80>
    80003880:	b759                	j	80003806 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003882:	00005517          	auipc	a0,0x5
    80003886:	eae50513          	addi	a0,a0,-338 # 80008730 <syscalls+0x118>
    8000388a:	ffffd097          	auipc	ra,0xffffd
    8000388e:	cb4080e7          	jalr	-844(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003892:	974a                	add	a4,a4,s2
    80003894:	8fd5                	or	a5,a5,a3
    80003896:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000389a:	854a                	mv	a0,s2
    8000389c:	00001097          	auipc	ra,0x1
    800038a0:	01a080e7          	jalr	26(ra) # 800048b6 <log_write>
        brelse(bp);
    800038a4:	854a                	mv	a0,s2
    800038a6:	00000097          	auipc	ra,0x0
    800038aa:	d94080e7          	jalr	-620(ra) # 8000363a <brelse>
  bp = bread(dev, bno);
    800038ae:	85a6                	mv	a1,s1
    800038b0:	855e                	mv	a0,s7
    800038b2:	00000097          	auipc	ra,0x0
    800038b6:	c58080e7          	jalr	-936(ra) # 8000350a <bread>
    800038ba:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038bc:	40000613          	li	a2,1024
    800038c0:	4581                	li	a1,0
    800038c2:	05850513          	addi	a0,a0,88
    800038c6:	ffffd097          	auipc	ra,0xffffd
    800038ca:	41a080e7          	jalr	1050(ra) # 80000ce0 <memset>
  log_write(bp);
    800038ce:	854a                	mv	a0,s2
    800038d0:	00001097          	auipc	ra,0x1
    800038d4:	fe6080e7          	jalr	-26(ra) # 800048b6 <log_write>
  brelse(bp);
    800038d8:	854a                	mv	a0,s2
    800038da:	00000097          	auipc	ra,0x0
    800038de:	d60080e7          	jalr	-672(ra) # 8000363a <brelse>
}
    800038e2:	8526                	mv	a0,s1
    800038e4:	60e6                	ld	ra,88(sp)
    800038e6:	6446                	ld	s0,80(sp)
    800038e8:	64a6                	ld	s1,72(sp)
    800038ea:	6906                	ld	s2,64(sp)
    800038ec:	79e2                	ld	s3,56(sp)
    800038ee:	7a42                	ld	s4,48(sp)
    800038f0:	7aa2                	ld	s5,40(sp)
    800038f2:	7b02                	ld	s6,32(sp)
    800038f4:	6be2                	ld	s7,24(sp)
    800038f6:	6c42                	ld	s8,16(sp)
    800038f8:	6ca2                	ld	s9,8(sp)
    800038fa:	6125                	addi	sp,sp,96
    800038fc:	8082                	ret

00000000800038fe <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800038fe:	7179                	addi	sp,sp,-48
    80003900:	f406                	sd	ra,40(sp)
    80003902:	f022                	sd	s0,32(sp)
    80003904:	ec26                	sd	s1,24(sp)
    80003906:	e84a                	sd	s2,16(sp)
    80003908:	e44e                	sd	s3,8(sp)
    8000390a:	e052                	sd	s4,0(sp)
    8000390c:	1800                	addi	s0,sp,48
    8000390e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003910:	47ad                	li	a5,11
    80003912:	04b7fe63          	bgeu	a5,a1,8000396e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003916:	ff45849b          	addiw	s1,a1,-12
    8000391a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000391e:	0ff00793          	li	a5,255
    80003922:	0ae7e363          	bltu	a5,a4,800039c8 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003926:	08052583          	lw	a1,128(a0)
    8000392a:	c5ad                	beqz	a1,80003994 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000392c:	00092503          	lw	a0,0(s2)
    80003930:	00000097          	auipc	ra,0x0
    80003934:	bda080e7          	jalr	-1062(ra) # 8000350a <bread>
    80003938:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000393a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000393e:	02049593          	slli	a1,s1,0x20
    80003942:	9181                	srli	a1,a1,0x20
    80003944:	058a                	slli	a1,a1,0x2
    80003946:	00b784b3          	add	s1,a5,a1
    8000394a:	0004a983          	lw	s3,0(s1)
    8000394e:	04098d63          	beqz	s3,800039a8 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003952:	8552                	mv	a0,s4
    80003954:	00000097          	auipc	ra,0x0
    80003958:	ce6080e7          	jalr	-794(ra) # 8000363a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000395c:	854e                	mv	a0,s3
    8000395e:	70a2                	ld	ra,40(sp)
    80003960:	7402                	ld	s0,32(sp)
    80003962:	64e2                	ld	s1,24(sp)
    80003964:	6942                	ld	s2,16(sp)
    80003966:	69a2                	ld	s3,8(sp)
    80003968:	6a02                	ld	s4,0(sp)
    8000396a:	6145                	addi	sp,sp,48
    8000396c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000396e:	02059493          	slli	s1,a1,0x20
    80003972:	9081                	srli	s1,s1,0x20
    80003974:	048a                	slli	s1,s1,0x2
    80003976:	94aa                	add	s1,s1,a0
    80003978:	0504a983          	lw	s3,80(s1)
    8000397c:	fe0990e3          	bnez	s3,8000395c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003980:	4108                	lw	a0,0(a0)
    80003982:	00000097          	auipc	ra,0x0
    80003986:	e4a080e7          	jalr	-438(ra) # 800037cc <balloc>
    8000398a:	0005099b          	sext.w	s3,a0
    8000398e:	0534a823          	sw	s3,80(s1)
    80003992:	b7e9                	j	8000395c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003994:	4108                	lw	a0,0(a0)
    80003996:	00000097          	auipc	ra,0x0
    8000399a:	e36080e7          	jalr	-458(ra) # 800037cc <balloc>
    8000399e:	0005059b          	sext.w	a1,a0
    800039a2:	08b92023          	sw	a1,128(s2)
    800039a6:	b759                	j	8000392c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800039a8:	00092503          	lw	a0,0(s2)
    800039ac:	00000097          	auipc	ra,0x0
    800039b0:	e20080e7          	jalr	-480(ra) # 800037cc <balloc>
    800039b4:	0005099b          	sext.w	s3,a0
    800039b8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800039bc:	8552                	mv	a0,s4
    800039be:	00001097          	auipc	ra,0x1
    800039c2:	ef8080e7          	jalr	-264(ra) # 800048b6 <log_write>
    800039c6:	b771                	j	80003952 <bmap+0x54>
  panic("bmap: out of range");
    800039c8:	00005517          	auipc	a0,0x5
    800039cc:	d8050513          	addi	a0,a0,-640 # 80008748 <syscalls+0x130>
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	b6e080e7          	jalr	-1170(ra) # 8000053e <panic>

00000000800039d8 <iget>:
{
    800039d8:	7179                	addi	sp,sp,-48
    800039da:	f406                	sd	ra,40(sp)
    800039dc:	f022                	sd	s0,32(sp)
    800039de:	ec26                	sd	s1,24(sp)
    800039e0:	e84a                	sd	s2,16(sp)
    800039e2:	e44e                	sd	s3,8(sp)
    800039e4:	e052                	sd	s4,0(sp)
    800039e6:	1800                	addi	s0,sp,48
    800039e8:	89aa                	mv	s3,a0
    800039ea:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039ec:	0001c517          	auipc	a0,0x1c
    800039f0:	29c50513          	addi	a0,a0,668 # 8001fc88 <itable>
    800039f4:	ffffd097          	auipc	ra,0xffffd
    800039f8:	1f0080e7          	jalr	496(ra) # 80000be4 <acquire>
  empty = 0;
    800039fc:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039fe:	0001c497          	auipc	s1,0x1c
    80003a02:	2a248493          	addi	s1,s1,674 # 8001fca0 <itable+0x18>
    80003a06:	0001e697          	auipc	a3,0x1e
    80003a0a:	d2a68693          	addi	a3,a3,-726 # 80021730 <log>
    80003a0e:	a039                	j	80003a1c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a10:	02090b63          	beqz	s2,80003a46 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a14:	08848493          	addi	s1,s1,136
    80003a18:	02d48a63          	beq	s1,a3,80003a4c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a1c:	449c                	lw	a5,8(s1)
    80003a1e:	fef059e3          	blez	a5,80003a10 <iget+0x38>
    80003a22:	4098                	lw	a4,0(s1)
    80003a24:	ff3716e3          	bne	a4,s3,80003a10 <iget+0x38>
    80003a28:	40d8                	lw	a4,4(s1)
    80003a2a:	ff4713e3          	bne	a4,s4,80003a10 <iget+0x38>
      ip->ref++;
    80003a2e:	2785                	addiw	a5,a5,1
    80003a30:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a32:	0001c517          	auipc	a0,0x1c
    80003a36:	25650513          	addi	a0,a0,598 # 8001fc88 <itable>
    80003a3a:	ffffd097          	auipc	ra,0xffffd
    80003a3e:	25e080e7          	jalr	606(ra) # 80000c98 <release>
      return ip;
    80003a42:	8926                	mv	s2,s1
    80003a44:	a03d                	j	80003a72 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a46:	f7f9                	bnez	a5,80003a14 <iget+0x3c>
    80003a48:	8926                	mv	s2,s1
    80003a4a:	b7e9                	j	80003a14 <iget+0x3c>
  if(empty == 0)
    80003a4c:	02090c63          	beqz	s2,80003a84 <iget+0xac>
  ip->dev = dev;
    80003a50:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a54:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a58:	4785                	li	a5,1
    80003a5a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a5e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a62:	0001c517          	auipc	a0,0x1c
    80003a66:	22650513          	addi	a0,a0,550 # 8001fc88 <itable>
    80003a6a:	ffffd097          	auipc	ra,0xffffd
    80003a6e:	22e080e7          	jalr	558(ra) # 80000c98 <release>
}
    80003a72:	854a                	mv	a0,s2
    80003a74:	70a2                	ld	ra,40(sp)
    80003a76:	7402                	ld	s0,32(sp)
    80003a78:	64e2                	ld	s1,24(sp)
    80003a7a:	6942                	ld	s2,16(sp)
    80003a7c:	69a2                	ld	s3,8(sp)
    80003a7e:	6a02                	ld	s4,0(sp)
    80003a80:	6145                	addi	sp,sp,48
    80003a82:	8082                	ret
    panic("iget: no inodes");
    80003a84:	00005517          	auipc	a0,0x5
    80003a88:	cdc50513          	addi	a0,a0,-804 # 80008760 <syscalls+0x148>
    80003a8c:	ffffd097          	auipc	ra,0xffffd
    80003a90:	ab2080e7          	jalr	-1358(ra) # 8000053e <panic>

0000000080003a94 <fsinit>:
fsinit(int dev) {
    80003a94:	7179                	addi	sp,sp,-48
    80003a96:	f406                	sd	ra,40(sp)
    80003a98:	f022                	sd	s0,32(sp)
    80003a9a:	ec26                	sd	s1,24(sp)
    80003a9c:	e84a                	sd	s2,16(sp)
    80003a9e:	e44e                	sd	s3,8(sp)
    80003aa0:	1800                	addi	s0,sp,48
    80003aa2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003aa4:	4585                	li	a1,1
    80003aa6:	00000097          	auipc	ra,0x0
    80003aaa:	a64080e7          	jalr	-1436(ra) # 8000350a <bread>
    80003aae:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ab0:	0001c997          	auipc	s3,0x1c
    80003ab4:	1b898993          	addi	s3,s3,440 # 8001fc68 <sb>
    80003ab8:	02000613          	li	a2,32
    80003abc:	05850593          	addi	a1,a0,88
    80003ac0:	854e                	mv	a0,s3
    80003ac2:	ffffd097          	auipc	ra,0xffffd
    80003ac6:	27e080e7          	jalr	638(ra) # 80000d40 <memmove>
  brelse(bp);
    80003aca:	8526                	mv	a0,s1
    80003acc:	00000097          	auipc	ra,0x0
    80003ad0:	b6e080e7          	jalr	-1170(ra) # 8000363a <brelse>
  if(sb.magic != FSMAGIC)
    80003ad4:	0009a703          	lw	a4,0(s3)
    80003ad8:	102037b7          	lui	a5,0x10203
    80003adc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ae0:	02f71263          	bne	a4,a5,80003b04 <fsinit+0x70>
  initlog(dev, &sb);
    80003ae4:	0001c597          	auipc	a1,0x1c
    80003ae8:	18458593          	addi	a1,a1,388 # 8001fc68 <sb>
    80003aec:	854a                	mv	a0,s2
    80003aee:	00001097          	auipc	ra,0x1
    80003af2:	b4c080e7          	jalr	-1204(ra) # 8000463a <initlog>
}
    80003af6:	70a2                	ld	ra,40(sp)
    80003af8:	7402                	ld	s0,32(sp)
    80003afa:	64e2                	ld	s1,24(sp)
    80003afc:	6942                	ld	s2,16(sp)
    80003afe:	69a2                	ld	s3,8(sp)
    80003b00:	6145                	addi	sp,sp,48
    80003b02:	8082                	ret
    panic("invalid file system");
    80003b04:	00005517          	auipc	a0,0x5
    80003b08:	c6c50513          	addi	a0,a0,-916 # 80008770 <syscalls+0x158>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	a32080e7          	jalr	-1486(ra) # 8000053e <panic>

0000000080003b14 <iinit>:
{
    80003b14:	7179                	addi	sp,sp,-48
    80003b16:	f406                	sd	ra,40(sp)
    80003b18:	f022                	sd	s0,32(sp)
    80003b1a:	ec26                	sd	s1,24(sp)
    80003b1c:	e84a                	sd	s2,16(sp)
    80003b1e:	e44e                	sd	s3,8(sp)
    80003b20:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b22:	00005597          	auipc	a1,0x5
    80003b26:	c6658593          	addi	a1,a1,-922 # 80008788 <syscalls+0x170>
    80003b2a:	0001c517          	auipc	a0,0x1c
    80003b2e:	15e50513          	addi	a0,a0,350 # 8001fc88 <itable>
    80003b32:	ffffd097          	auipc	ra,0xffffd
    80003b36:	022080e7          	jalr	34(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b3a:	0001c497          	auipc	s1,0x1c
    80003b3e:	17648493          	addi	s1,s1,374 # 8001fcb0 <itable+0x28>
    80003b42:	0001e997          	auipc	s3,0x1e
    80003b46:	bfe98993          	addi	s3,s3,-1026 # 80021740 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b4a:	00005917          	auipc	s2,0x5
    80003b4e:	c4690913          	addi	s2,s2,-954 # 80008790 <syscalls+0x178>
    80003b52:	85ca                	mv	a1,s2
    80003b54:	8526                	mv	a0,s1
    80003b56:	00001097          	auipc	ra,0x1
    80003b5a:	e46080e7          	jalr	-442(ra) # 8000499c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b5e:	08848493          	addi	s1,s1,136
    80003b62:	ff3498e3          	bne	s1,s3,80003b52 <iinit+0x3e>
}
    80003b66:	70a2                	ld	ra,40(sp)
    80003b68:	7402                	ld	s0,32(sp)
    80003b6a:	64e2                	ld	s1,24(sp)
    80003b6c:	6942                	ld	s2,16(sp)
    80003b6e:	69a2                	ld	s3,8(sp)
    80003b70:	6145                	addi	sp,sp,48
    80003b72:	8082                	ret

0000000080003b74 <ialloc>:
{
    80003b74:	715d                	addi	sp,sp,-80
    80003b76:	e486                	sd	ra,72(sp)
    80003b78:	e0a2                	sd	s0,64(sp)
    80003b7a:	fc26                	sd	s1,56(sp)
    80003b7c:	f84a                	sd	s2,48(sp)
    80003b7e:	f44e                	sd	s3,40(sp)
    80003b80:	f052                	sd	s4,32(sp)
    80003b82:	ec56                	sd	s5,24(sp)
    80003b84:	e85a                	sd	s6,16(sp)
    80003b86:	e45e                	sd	s7,8(sp)
    80003b88:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b8a:	0001c717          	auipc	a4,0x1c
    80003b8e:	0ea72703          	lw	a4,234(a4) # 8001fc74 <sb+0xc>
    80003b92:	4785                	li	a5,1
    80003b94:	04e7fa63          	bgeu	a5,a4,80003be8 <ialloc+0x74>
    80003b98:	8aaa                	mv	s5,a0
    80003b9a:	8bae                	mv	s7,a1
    80003b9c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b9e:	0001ca17          	auipc	s4,0x1c
    80003ba2:	0caa0a13          	addi	s4,s4,202 # 8001fc68 <sb>
    80003ba6:	00048b1b          	sext.w	s6,s1
    80003baa:	0044d593          	srli	a1,s1,0x4
    80003bae:	018a2783          	lw	a5,24(s4)
    80003bb2:	9dbd                	addw	a1,a1,a5
    80003bb4:	8556                	mv	a0,s5
    80003bb6:	00000097          	auipc	ra,0x0
    80003bba:	954080e7          	jalr	-1708(ra) # 8000350a <bread>
    80003bbe:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003bc0:	05850993          	addi	s3,a0,88
    80003bc4:	00f4f793          	andi	a5,s1,15
    80003bc8:	079a                	slli	a5,a5,0x6
    80003bca:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003bcc:	00099783          	lh	a5,0(s3)
    80003bd0:	c785                	beqz	a5,80003bf8 <ialloc+0x84>
    brelse(bp);
    80003bd2:	00000097          	auipc	ra,0x0
    80003bd6:	a68080e7          	jalr	-1432(ra) # 8000363a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bda:	0485                	addi	s1,s1,1
    80003bdc:	00ca2703          	lw	a4,12(s4)
    80003be0:	0004879b          	sext.w	a5,s1
    80003be4:	fce7e1e3          	bltu	a5,a4,80003ba6 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003be8:	00005517          	auipc	a0,0x5
    80003bec:	bb050513          	addi	a0,a0,-1104 # 80008798 <syscalls+0x180>
    80003bf0:	ffffd097          	auipc	ra,0xffffd
    80003bf4:	94e080e7          	jalr	-1714(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003bf8:	04000613          	li	a2,64
    80003bfc:	4581                	li	a1,0
    80003bfe:	854e                	mv	a0,s3
    80003c00:	ffffd097          	auipc	ra,0xffffd
    80003c04:	0e0080e7          	jalr	224(ra) # 80000ce0 <memset>
      dip->type = type;
    80003c08:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c0c:	854a                	mv	a0,s2
    80003c0e:	00001097          	auipc	ra,0x1
    80003c12:	ca8080e7          	jalr	-856(ra) # 800048b6 <log_write>
      brelse(bp);
    80003c16:	854a                	mv	a0,s2
    80003c18:	00000097          	auipc	ra,0x0
    80003c1c:	a22080e7          	jalr	-1502(ra) # 8000363a <brelse>
      return iget(dev, inum);
    80003c20:	85da                	mv	a1,s6
    80003c22:	8556                	mv	a0,s5
    80003c24:	00000097          	auipc	ra,0x0
    80003c28:	db4080e7          	jalr	-588(ra) # 800039d8 <iget>
}
    80003c2c:	60a6                	ld	ra,72(sp)
    80003c2e:	6406                	ld	s0,64(sp)
    80003c30:	74e2                	ld	s1,56(sp)
    80003c32:	7942                	ld	s2,48(sp)
    80003c34:	79a2                	ld	s3,40(sp)
    80003c36:	7a02                	ld	s4,32(sp)
    80003c38:	6ae2                	ld	s5,24(sp)
    80003c3a:	6b42                	ld	s6,16(sp)
    80003c3c:	6ba2                	ld	s7,8(sp)
    80003c3e:	6161                	addi	sp,sp,80
    80003c40:	8082                	ret

0000000080003c42 <iupdate>:
{
    80003c42:	1101                	addi	sp,sp,-32
    80003c44:	ec06                	sd	ra,24(sp)
    80003c46:	e822                	sd	s0,16(sp)
    80003c48:	e426                	sd	s1,8(sp)
    80003c4a:	e04a                	sd	s2,0(sp)
    80003c4c:	1000                	addi	s0,sp,32
    80003c4e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c50:	415c                	lw	a5,4(a0)
    80003c52:	0047d79b          	srliw	a5,a5,0x4
    80003c56:	0001c597          	auipc	a1,0x1c
    80003c5a:	02a5a583          	lw	a1,42(a1) # 8001fc80 <sb+0x18>
    80003c5e:	9dbd                	addw	a1,a1,a5
    80003c60:	4108                	lw	a0,0(a0)
    80003c62:	00000097          	auipc	ra,0x0
    80003c66:	8a8080e7          	jalr	-1880(ra) # 8000350a <bread>
    80003c6a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c6c:	05850793          	addi	a5,a0,88
    80003c70:	40c8                	lw	a0,4(s1)
    80003c72:	893d                	andi	a0,a0,15
    80003c74:	051a                	slli	a0,a0,0x6
    80003c76:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c78:	04449703          	lh	a4,68(s1)
    80003c7c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c80:	04649703          	lh	a4,70(s1)
    80003c84:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c88:	04849703          	lh	a4,72(s1)
    80003c8c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c90:	04a49703          	lh	a4,74(s1)
    80003c94:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c98:	44f8                	lw	a4,76(s1)
    80003c9a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c9c:	03400613          	li	a2,52
    80003ca0:	05048593          	addi	a1,s1,80
    80003ca4:	0531                	addi	a0,a0,12
    80003ca6:	ffffd097          	auipc	ra,0xffffd
    80003caa:	09a080e7          	jalr	154(ra) # 80000d40 <memmove>
  log_write(bp);
    80003cae:	854a                	mv	a0,s2
    80003cb0:	00001097          	auipc	ra,0x1
    80003cb4:	c06080e7          	jalr	-1018(ra) # 800048b6 <log_write>
  brelse(bp);
    80003cb8:	854a                	mv	a0,s2
    80003cba:	00000097          	auipc	ra,0x0
    80003cbe:	980080e7          	jalr	-1664(ra) # 8000363a <brelse>
}
    80003cc2:	60e2                	ld	ra,24(sp)
    80003cc4:	6442                	ld	s0,16(sp)
    80003cc6:	64a2                	ld	s1,8(sp)
    80003cc8:	6902                	ld	s2,0(sp)
    80003cca:	6105                	addi	sp,sp,32
    80003ccc:	8082                	ret

0000000080003cce <idup>:
{
    80003cce:	1101                	addi	sp,sp,-32
    80003cd0:	ec06                	sd	ra,24(sp)
    80003cd2:	e822                	sd	s0,16(sp)
    80003cd4:	e426                	sd	s1,8(sp)
    80003cd6:	1000                	addi	s0,sp,32
    80003cd8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cda:	0001c517          	auipc	a0,0x1c
    80003cde:	fae50513          	addi	a0,a0,-82 # 8001fc88 <itable>
    80003ce2:	ffffd097          	auipc	ra,0xffffd
    80003ce6:	f02080e7          	jalr	-254(ra) # 80000be4 <acquire>
  ip->ref++;
    80003cea:	449c                	lw	a5,8(s1)
    80003cec:	2785                	addiw	a5,a5,1
    80003cee:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cf0:	0001c517          	auipc	a0,0x1c
    80003cf4:	f9850513          	addi	a0,a0,-104 # 8001fc88 <itable>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	fa0080e7          	jalr	-96(ra) # 80000c98 <release>
}
    80003d00:	8526                	mv	a0,s1
    80003d02:	60e2                	ld	ra,24(sp)
    80003d04:	6442                	ld	s0,16(sp)
    80003d06:	64a2                	ld	s1,8(sp)
    80003d08:	6105                	addi	sp,sp,32
    80003d0a:	8082                	ret

0000000080003d0c <ilock>:
{
    80003d0c:	1101                	addi	sp,sp,-32
    80003d0e:	ec06                	sd	ra,24(sp)
    80003d10:	e822                	sd	s0,16(sp)
    80003d12:	e426                	sd	s1,8(sp)
    80003d14:	e04a                	sd	s2,0(sp)
    80003d16:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d18:	c115                	beqz	a0,80003d3c <ilock+0x30>
    80003d1a:	84aa                	mv	s1,a0
    80003d1c:	451c                	lw	a5,8(a0)
    80003d1e:	00f05f63          	blez	a5,80003d3c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d22:	0541                	addi	a0,a0,16
    80003d24:	00001097          	auipc	ra,0x1
    80003d28:	cb2080e7          	jalr	-846(ra) # 800049d6 <acquiresleep>
  if(ip->valid == 0){
    80003d2c:	40bc                	lw	a5,64(s1)
    80003d2e:	cf99                	beqz	a5,80003d4c <ilock+0x40>
}
    80003d30:	60e2                	ld	ra,24(sp)
    80003d32:	6442                	ld	s0,16(sp)
    80003d34:	64a2                	ld	s1,8(sp)
    80003d36:	6902                	ld	s2,0(sp)
    80003d38:	6105                	addi	sp,sp,32
    80003d3a:	8082                	ret
    panic("ilock");
    80003d3c:	00005517          	auipc	a0,0x5
    80003d40:	a7450513          	addi	a0,a0,-1420 # 800087b0 <syscalls+0x198>
    80003d44:	ffffc097          	auipc	ra,0xffffc
    80003d48:	7fa080e7          	jalr	2042(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d4c:	40dc                	lw	a5,4(s1)
    80003d4e:	0047d79b          	srliw	a5,a5,0x4
    80003d52:	0001c597          	auipc	a1,0x1c
    80003d56:	f2e5a583          	lw	a1,-210(a1) # 8001fc80 <sb+0x18>
    80003d5a:	9dbd                	addw	a1,a1,a5
    80003d5c:	4088                	lw	a0,0(s1)
    80003d5e:	fffff097          	auipc	ra,0xfffff
    80003d62:	7ac080e7          	jalr	1964(ra) # 8000350a <bread>
    80003d66:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d68:	05850593          	addi	a1,a0,88
    80003d6c:	40dc                	lw	a5,4(s1)
    80003d6e:	8bbd                	andi	a5,a5,15
    80003d70:	079a                	slli	a5,a5,0x6
    80003d72:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d74:	00059783          	lh	a5,0(a1)
    80003d78:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d7c:	00259783          	lh	a5,2(a1)
    80003d80:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d84:	00459783          	lh	a5,4(a1)
    80003d88:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d8c:	00659783          	lh	a5,6(a1)
    80003d90:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d94:	459c                	lw	a5,8(a1)
    80003d96:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d98:	03400613          	li	a2,52
    80003d9c:	05b1                	addi	a1,a1,12
    80003d9e:	05048513          	addi	a0,s1,80
    80003da2:	ffffd097          	auipc	ra,0xffffd
    80003da6:	f9e080e7          	jalr	-98(ra) # 80000d40 <memmove>
    brelse(bp);
    80003daa:	854a                	mv	a0,s2
    80003dac:	00000097          	auipc	ra,0x0
    80003db0:	88e080e7          	jalr	-1906(ra) # 8000363a <brelse>
    ip->valid = 1;
    80003db4:	4785                	li	a5,1
    80003db6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003db8:	04449783          	lh	a5,68(s1)
    80003dbc:	fbb5                	bnez	a5,80003d30 <ilock+0x24>
      panic("ilock: no type");
    80003dbe:	00005517          	auipc	a0,0x5
    80003dc2:	9fa50513          	addi	a0,a0,-1542 # 800087b8 <syscalls+0x1a0>
    80003dc6:	ffffc097          	auipc	ra,0xffffc
    80003dca:	778080e7          	jalr	1912(ra) # 8000053e <panic>

0000000080003dce <iunlock>:
{
    80003dce:	1101                	addi	sp,sp,-32
    80003dd0:	ec06                	sd	ra,24(sp)
    80003dd2:	e822                	sd	s0,16(sp)
    80003dd4:	e426                	sd	s1,8(sp)
    80003dd6:	e04a                	sd	s2,0(sp)
    80003dd8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003dda:	c905                	beqz	a0,80003e0a <iunlock+0x3c>
    80003ddc:	84aa                	mv	s1,a0
    80003dde:	01050913          	addi	s2,a0,16
    80003de2:	854a                	mv	a0,s2
    80003de4:	00001097          	auipc	ra,0x1
    80003de8:	c8c080e7          	jalr	-884(ra) # 80004a70 <holdingsleep>
    80003dec:	cd19                	beqz	a0,80003e0a <iunlock+0x3c>
    80003dee:	449c                	lw	a5,8(s1)
    80003df0:	00f05d63          	blez	a5,80003e0a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003df4:	854a                	mv	a0,s2
    80003df6:	00001097          	auipc	ra,0x1
    80003dfa:	c36080e7          	jalr	-970(ra) # 80004a2c <releasesleep>
}
    80003dfe:	60e2                	ld	ra,24(sp)
    80003e00:	6442                	ld	s0,16(sp)
    80003e02:	64a2                	ld	s1,8(sp)
    80003e04:	6902                	ld	s2,0(sp)
    80003e06:	6105                	addi	sp,sp,32
    80003e08:	8082                	ret
    panic("iunlock");
    80003e0a:	00005517          	auipc	a0,0x5
    80003e0e:	9be50513          	addi	a0,a0,-1602 # 800087c8 <syscalls+0x1b0>
    80003e12:	ffffc097          	auipc	ra,0xffffc
    80003e16:	72c080e7          	jalr	1836(ra) # 8000053e <panic>

0000000080003e1a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e1a:	7179                	addi	sp,sp,-48
    80003e1c:	f406                	sd	ra,40(sp)
    80003e1e:	f022                	sd	s0,32(sp)
    80003e20:	ec26                	sd	s1,24(sp)
    80003e22:	e84a                	sd	s2,16(sp)
    80003e24:	e44e                	sd	s3,8(sp)
    80003e26:	e052                	sd	s4,0(sp)
    80003e28:	1800                	addi	s0,sp,48
    80003e2a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e2c:	05050493          	addi	s1,a0,80
    80003e30:	08050913          	addi	s2,a0,128
    80003e34:	a021                	j	80003e3c <itrunc+0x22>
    80003e36:	0491                	addi	s1,s1,4
    80003e38:	01248d63          	beq	s1,s2,80003e52 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e3c:	408c                	lw	a1,0(s1)
    80003e3e:	dde5                	beqz	a1,80003e36 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e40:	0009a503          	lw	a0,0(s3)
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	90c080e7          	jalr	-1780(ra) # 80003750 <bfree>
      ip->addrs[i] = 0;
    80003e4c:	0004a023          	sw	zero,0(s1)
    80003e50:	b7dd                	j	80003e36 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e52:	0809a583          	lw	a1,128(s3)
    80003e56:	e185                	bnez	a1,80003e76 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e58:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e5c:	854e                	mv	a0,s3
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	de4080e7          	jalr	-540(ra) # 80003c42 <iupdate>
}
    80003e66:	70a2                	ld	ra,40(sp)
    80003e68:	7402                	ld	s0,32(sp)
    80003e6a:	64e2                	ld	s1,24(sp)
    80003e6c:	6942                	ld	s2,16(sp)
    80003e6e:	69a2                	ld	s3,8(sp)
    80003e70:	6a02                	ld	s4,0(sp)
    80003e72:	6145                	addi	sp,sp,48
    80003e74:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e76:	0009a503          	lw	a0,0(s3)
    80003e7a:	fffff097          	auipc	ra,0xfffff
    80003e7e:	690080e7          	jalr	1680(ra) # 8000350a <bread>
    80003e82:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e84:	05850493          	addi	s1,a0,88
    80003e88:	45850913          	addi	s2,a0,1112
    80003e8c:	a811                	j	80003ea0 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003e8e:	0009a503          	lw	a0,0(s3)
    80003e92:	00000097          	auipc	ra,0x0
    80003e96:	8be080e7          	jalr	-1858(ra) # 80003750 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003e9a:	0491                	addi	s1,s1,4
    80003e9c:	01248563          	beq	s1,s2,80003ea6 <itrunc+0x8c>
      if(a[j])
    80003ea0:	408c                	lw	a1,0(s1)
    80003ea2:	dde5                	beqz	a1,80003e9a <itrunc+0x80>
    80003ea4:	b7ed                	j	80003e8e <itrunc+0x74>
    brelse(bp);
    80003ea6:	8552                	mv	a0,s4
    80003ea8:	fffff097          	auipc	ra,0xfffff
    80003eac:	792080e7          	jalr	1938(ra) # 8000363a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003eb0:	0809a583          	lw	a1,128(s3)
    80003eb4:	0009a503          	lw	a0,0(s3)
    80003eb8:	00000097          	auipc	ra,0x0
    80003ebc:	898080e7          	jalr	-1896(ra) # 80003750 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ec0:	0809a023          	sw	zero,128(s3)
    80003ec4:	bf51                	j	80003e58 <itrunc+0x3e>

0000000080003ec6 <iput>:
{
    80003ec6:	1101                	addi	sp,sp,-32
    80003ec8:	ec06                	sd	ra,24(sp)
    80003eca:	e822                	sd	s0,16(sp)
    80003ecc:	e426                	sd	s1,8(sp)
    80003ece:	e04a                	sd	s2,0(sp)
    80003ed0:	1000                	addi	s0,sp,32
    80003ed2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ed4:	0001c517          	auipc	a0,0x1c
    80003ed8:	db450513          	addi	a0,a0,-588 # 8001fc88 <itable>
    80003edc:	ffffd097          	auipc	ra,0xffffd
    80003ee0:	d08080e7          	jalr	-760(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ee4:	4498                	lw	a4,8(s1)
    80003ee6:	4785                	li	a5,1
    80003ee8:	02f70363          	beq	a4,a5,80003f0e <iput+0x48>
  ip->ref--;
    80003eec:	449c                	lw	a5,8(s1)
    80003eee:	37fd                	addiw	a5,a5,-1
    80003ef0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ef2:	0001c517          	auipc	a0,0x1c
    80003ef6:	d9650513          	addi	a0,a0,-618 # 8001fc88 <itable>
    80003efa:	ffffd097          	auipc	ra,0xffffd
    80003efe:	d9e080e7          	jalr	-610(ra) # 80000c98 <release>
}
    80003f02:	60e2                	ld	ra,24(sp)
    80003f04:	6442                	ld	s0,16(sp)
    80003f06:	64a2                	ld	s1,8(sp)
    80003f08:	6902                	ld	s2,0(sp)
    80003f0a:	6105                	addi	sp,sp,32
    80003f0c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f0e:	40bc                	lw	a5,64(s1)
    80003f10:	dff1                	beqz	a5,80003eec <iput+0x26>
    80003f12:	04a49783          	lh	a5,74(s1)
    80003f16:	fbf9                	bnez	a5,80003eec <iput+0x26>
    acquiresleep(&ip->lock);
    80003f18:	01048913          	addi	s2,s1,16
    80003f1c:	854a                	mv	a0,s2
    80003f1e:	00001097          	auipc	ra,0x1
    80003f22:	ab8080e7          	jalr	-1352(ra) # 800049d6 <acquiresleep>
    release(&itable.lock);
    80003f26:	0001c517          	auipc	a0,0x1c
    80003f2a:	d6250513          	addi	a0,a0,-670 # 8001fc88 <itable>
    80003f2e:	ffffd097          	auipc	ra,0xffffd
    80003f32:	d6a080e7          	jalr	-662(ra) # 80000c98 <release>
    itrunc(ip);
    80003f36:	8526                	mv	a0,s1
    80003f38:	00000097          	auipc	ra,0x0
    80003f3c:	ee2080e7          	jalr	-286(ra) # 80003e1a <itrunc>
    ip->type = 0;
    80003f40:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f44:	8526                	mv	a0,s1
    80003f46:	00000097          	auipc	ra,0x0
    80003f4a:	cfc080e7          	jalr	-772(ra) # 80003c42 <iupdate>
    ip->valid = 0;
    80003f4e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f52:	854a                	mv	a0,s2
    80003f54:	00001097          	auipc	ra,0x1
    80003f58:	ad8080e7          	jalr	-1320(ra) # 80004a2c <releasesleep>
    acquire(&itable.lock);
    80003f5c:	0001c517          	auipc	a0,0x1c
    80003f60:	d2c50513          	addi	a0,a0,-724 # 8001fc88 <itable>
    80003f64:	ffffd097          	auipc	ra,0xffffd
    80003f68:	c80080e7          	jalr	-896(ra) # 80000be4 <acquire>
    80003f6c:	b741                	j	80003eec <iput+0x26>

0000000080003f6e <iunlockput>:
{
    80003f6e:	1101                	addi	sp,sp,-32
    80003f70:	ec06                	sd	ra,24(sp)
    80003f72:	e822                	sd	s0,16(sp)
    80003f74:	e426                	sd	s1,8(sp)
    80003f76:	1000                	addi	s0,sp,32
    80003f78:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	e54080e7          	jalr	-428(ra) # 80003dce <iunlock>
  iput(ip);
    80003f82:	8526                	mv	a0,s1
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	f42080e7          	jalr	-190(ra) # 80003ec6 <iput>
}
    80003f8c:	60e2                	ld	ra,24(sp)
    80003f8e:	6442                	ld	s0,16(sp)
    80003f90:	64a2                	ld	s1,8(sp)
    80003f92:	6105                	addi	sp,sp,32
    80003f94:	8082                	ret

0000000080003f96 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f96:	1141                	addi	sp,sp,-16
    80003f98:	e422                	sd	s0,8(sp)
    80003f9a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f9c:	411c                	lw	a5,0(a0)
    80003f9e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003fa0:	415c                	lw	a5,4(a0)
    80003fa2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fa4:	04451783          	lh	a5,68(a0)
    80003fa8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003fac:	04a51783          	lh	a5,74(a0)
    80003fb0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fb4:	04c56783          	lwu	a5,76(a0)
    80003fb8:	e99c                	sd	a5,16(a1)
}
    80003fba:	6422                	ld	s0,8(sp)
    80003fbc:	0141                	addi	sp,sp,16
    80003fbe:	8082                	ret

0000000080003fc0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fc0:	457c                	lw	a5,76(a0)
    80003fc2:	0ed7e963          	bltu	a5,a3,800040b4 <readi+0xf4>
{
    80003fc6:	7159                	addi	sp,sp,-112
    80003fc8:	f486                	sd	ra,104(sp)
    80003fca:	f0a2                	sd	s0,96(sp)
    80003fcc:	eca6                	sd	s1,88(sp)
    80003fce:	e8ca                	sd	s2,80(sp)
    80003fd0:	e4ce                	sd	s3,72(sp)
    80003fd2:	e0d2                	sd	s4,64(sp)
    80003fd4:	fc56                	sd	s5,56(sp)
    80003fd6:	f85a                	sd	s6,48(sp)
    80003fd8:	f45e                	sd	s7,40(sp)
    80003fda:	f062                	sd	s8,32(sp)
    80003fdc:	ec66                	sd	s9,24(sp)
    80003fde:	e86a                	sd	s10,16(sp)
    80003fe0:	e46e                	sd	s11,8(sp)
    80003fe2:	1880                	addi	s0,sp,112
    80003fe4:	8baa                	mv	s7,a0
    80003fe6:	8c2e                	mv	s8,a1
    80003fe8:	8ab2                	mv	s5,a2
    80003fea:	84b6                	mv	s1,a3
    80003fec:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003fee:	9f35                	addw	a4,a4,a3
    return 0;
    80003ff0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ff2:	0ad76063          	bltu	a4,a3,80004092 <readi+0xd2>
  if(off + n > ip->size)
    80003ff6:	00e7f463          	bgeu	a5,a4,80003ffe <readi+0x3e>
    n = ip->size - off;
    80003ffa:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ffe:	0a0b0963          	beqz	s6,800040b0 <readi+0xf0>
    80004002:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004004:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004008:	5cfd                	li	s9,-1
    8000400a:	a82d                	j	80004044 <readi+0x84>
    8000400c:	020a1d93          	slli	s11,s4,0x20
    80004010:	020ddd93          	srli	s11,s11,0x20
    80004014:	05890613          	addi	a2,s2,88
    80004018:	86ee                	mv	a3,s11
    8000401a:	963a                	add	a2,a2,a4
    8000401c:	85d6                	mv	a1,s5
    8000401e:	8562                	mv	a0,s8
    80004020:	ffffe097          	auipc	ra,0xffffe
    80004024:	5c6080e7          	jalr	1478(ra) # 800025e6 <either_copyout>
    80004028:	05950d63          	beq	a0,s9,80004082 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000402c:	854a                	mv	a0,s2
    8000402e:	fffff097          	auipc	ra,0xfffff
    80004032:	60c080e7          	jalr	1548(ra) # 8000363a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004036:	013a09bb          	addw	s3,s4,s3
    8000403a:	009a04bb          	addw	s1,s4,s1
    8000403e:	9aee                	add	s5,s5,s11
    80004040:	0569f763          	bgeu	s3,s6,8000408e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004044:	000ba903          	lw	s2,0(s7)
    80004048:	00a4d59b          	srliw	a1,s1,0xa
    8000404c:	855e                	mv	a0,s7
    8000404e:	00000097          	auipc	ra,0x0
    80004052:	8b0080e7          	jalr	-1872(ra) # 800038fe <bmap>
    80004056:	0005059b          	sext.w	a1,a0
    8000405a:	854a                	mv	a0,s2
    8000405c:	fffff097          	auipc	ra,0xfffff
    80004060:	4ae080e7          	jalr	1198(ra) # 8000350a <bread>
    80004064:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004066:	3ff4f713          	andi	a4,s1,1023
    8000406a:	40ed07bb          	subw	a5,s10,a4
    8000406e:	413b06bb          	subw	a3,s6,s3
    80004072:	8a3e                	mv	s4,a5
    80004074:	2781                	sext.w	a5,a5
    80004076:	0006861b          	sext.w	a2,a3
    8000407a:	f8f679e3          	bgeu	a2,a5,8000400c <readi+0x4c>
    8000407e:	8a36                	mv	s4,a3
    80004080:	b771                	j	8000400c <readi+0x4c>
      brelse(bp);
    80004082:	854a                	mv	a0,s2
    80004084:	fffff097          	auipc	ra,0xfffff
    80004088:	5b6080e7          	jalr	1462(ra) # 8000363a <brelse>
      tot = -1;
    8000408c:	59fd                	li	s3,-1
  }
  return tot;
    8000408e:	0009851b          	sext.w	a0,s3
}
    80004092:	70a6                	ld	ra,104(sp)
    80004094:	7406                	ld	s0,96(sp)
    80004096:	64e6                	ld	s1,88(sp)
    80004098:	6946                	ld	s2,80(sp)
    8000409a:	69a6                	ld	s3,72(sp)
    8000409c:	6a06                	ld	s4,64(sp)
    8000409e:	7ae2                	ld	s5,56(sp)
    800040a0:	7b42                	ld	s6,48(sp)
    800040a2:	7ba2                	ld	s7,40(sp)
    800040a4:	7c02                	ld	s8,32(sp)
    800040a6:	6ce2                	ld	s9,24(sp)
    800040a8:	6d42                	ld	s10,16(sp)
    800040aa:	6da2                	ld	s11,8(sp)
    800040ac:	6165                	addi	sp,sp,112
    800040ae:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040b0:	89da                	mv	s3,s6
    800040b2:	bff1                	j	8000408e <readi+0xce>
    return 0;
    800040b4:	4501                	li	a0,0
}
    800040b6:	8082                	ret

00000000800040b8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040b8:	457c                	lw	a5,76(a0)
    800040ba:	10d7e863          	bltu	a5,a3,800041ca <writei+0x112>
{
    800040be:	7159                	addi	sp,sp,-112
    800040c0:	f486                	sd	ra,104(sp)
    800040c2:	f0a2                	sd	s0,96(sp)
    800040c4:	eca6                	sd	s1,88(sp)
    800040c6:	e8ca                	sd	s2,80(sp)
    800040c8:	e4ce                	sd	s3,72(sp)
    800040ca:	e0d2                	sd	s4,64(sp)
    800040cc:	fc56                	sd	s5,56(sp)
    800040ce:	f85a                	sd	s6,48(sp)
    800040d0:	f45e                	sd	s7,40(sp)
    800040d2:	f062                	sd	s8,32(sp)
    800040d4:	ec66                	sd	s9,24(sp)
    800040d6:	e86a                	sd	s10,16(sp)
    800040d8:	e46e                	sd	s11,8(sp)
    800040da:	1880                	addi	s0,sp,112
    800040dc:	8b2a                	mv	s6,a0
    800040de:	8c2e                	mv	s8,a1
    800040e0:	8ab2                	mv	s5,a2
    800040e2:	8936                	mv	s2,a3
    800040e4:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800040e6:	00e687bb          	addw	a5,a3,a4
    800040ea:	0ed7e263          	bltu	a5,a3,800041ce <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040ee:	00043737          	lui	a4,0x43
    800040f2:	0ef76063          	bltu	a4,a5,800041d2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040f6:	0c0b8863          	beqz	s7,800041c6 <writei+0x10e>
    800040fa:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040fc:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004100:	5cfd                	li	s9,-1
    80004102:	a091                	j	80004146 <writei+0x8e>
    80004104:	02099d93          	slli	s11,s3,0x20
    80004108:	020ddd93          	srli	s11,s11,0x20
    8000410c:	05848513          	addi	a0,s1,88
    80004110:	86ee                	mv	a3,s11
    80004112:	8656                	mv	a2,s5
    80004114:	85e2                	mv	a1,s8
    80004116:	953a                	add	a0,a0,a4
    80004118:	ffffe097          	auipc	ra,0xffffe
    8000411c:	524080e7          	jalr	1316(ra) # 8000263c <either_copyin>
    80004120:	07950263          	beq	a0,s9,80004184 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004124:	8526                	mv	a0,s1
    80004126:	00000097          	auipc	ra,0x0
    8000412a:	790080e7          	jalr	1936(ra) # 800048b6 <log_write>
    brelse(bp);
    8000412e:	8526                	mv	a0,s1
    80004130:	fffff097          	auipc	ra,0xfffff
    80004134:	50a080e7          	jalr	1290(ra) # 8000363a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004138:	01498a3b          	addw	s4,s3,s4
    8000413c:	0129893b          	addw	s2,s3,s2
    80004140:	9aee                	add	s5,s5,s11
    80004142:	057a7663          	bgeu	s4,s7,8000418e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004146:	000b2483          	lw	s1,0(s6)
    8000414a:	00a9559b          	srliw	a1,s2,0xa
    8000414e:	855a                	mv	a0,s6
    80004150:	fffff097          	auipc	ra,0xfffff
    80004154:	7ae080e7          	jalr	1966(ra) # 800038fe <bmap>
    80004158:	0005059b          	sext.w	a1,a0
    8000415c:	8526                	mv	a0,s1
    8000415e:	fffff097          	auipc	ra,0xfffff
    80004162:	3ac080e7          	jalr	940(ra) # 8000350a <bread>
    80004166:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004168:	3ff97713          	andi	a4,s2,1023
    8000416c:	40ed07bb          	subw	a5,s10,a4
    80004170:	414b86bb          	subw	a3,s7,s4
    80004174:	89be                	mv	s3,a5
    80004176:	2781                	sext.w	a5,a5
    80004178:	0006861b          	sext.w	a2,a3
    8000417c:	f8f674e3          	bgeu	a2,a5,80004104 <writei+0x4c>
    80004180:	89b6                	mv	s3,a3
    80004182:	b749                	j	80004104 <writei+0x4c>
      brelse(bp);
    80004184:	8526                	mv	a0,s1
    80004186:	fffff097          	auipc	ra,0xfffff
    8000418a:	4b4080e7          	jalr	1204(ra) # 8000363a <brelse>
  }

  if(off > ip->size)
    8000418e:	04cb2783          	lw	a5,76(s6)
    80004192:	0127f463          	bgeu	a5,s2,8000419a <writei+0xe2>
    ip->size = off;
    80004196:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000419a:	855a                	mv	a0,s6
    8000419c:	00000097          	auipc	ra,0x0
    800041a0:	aa6080e7          	jalr	-1370(ra) # 80003c42 <iupdate>

  return tot;
    800041a4:	000a051b          	sext.w	a0,s4
}
    800041a8:	70a6                	ld	ra,104(sp)
    800041aa:	7406                	ld	s0,96(sp)
    800041ac:	64e6                	ld	s1,88(sp)
    800041ae:	6946                	ld	s2,80(sp)
    800041b0:	69a6                	ld	s3,72(sp)
    800041b2:	6a06                	ld	s4,64(sp)
    800041b4:	7ae2                	ld	s5,56(sp)
    800041b6:	7b42                	ld	s6,48(sp)
    800041b8:	7ba2                	ld	s7,40(sp)
    800041ba:	7c02                	ld	s8,32(sp)
    800041bc:	6ce2                	ld	s9,24(sp)
    800041be:	6d42                	ld	s10,16(sp)
    800041c0:	6da2                	ld	s11,8(sp)
    800041c2:	6165                	addi	sp,sp,112
    800041c4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041c6:	8a5e                	mv	s4,s7
    800041c8:	bfc9                	j	8000419a <writei+0xe2>
    return -1;
    800041ca:	557d                	li	a0,-1
}
    800041cc:	8082                	ret
    return -1;
    800041ce:	557d                	li	a0,-1
    800041d0:	bfe1                	j	800041a8 <writei+0xf0>
    return -1;
    800041d2:	557d                	li	a0,-1
    800041d4:	bfd1                	j	800041a8 <writei+0xf0>

00000000800041d6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041d6:	1141                	addi	sp,sp,-16
    800041d8:	e406                	sd	ra,8(sp)
    800041da:	e022                	sd	s0,0(sp)
    800041dc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041de:	4639                	li	a2,14
    800041e0:	ffffd097          	auipc	ra,0xffffd
    800041e4:	bd8080e7          	jalr	-1064(ra) # 80000db8 <strncmp>
}
    800041e8:	60a2                	ld	ra,8(sp)
    800041ea:	6402                	ld	s0,0(sp)
    800041ec:	0141                	addi	sp,sp,16
    800041ee:	8082                	ret

00000000800041f0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041f0:	7139                	addi	sp,sp,-64
    800041f2:	fc06                	sd	ra,56(sp)
    800041f4:	f822                	sd	s0,48(sp)
    800041f6:	f426                	sd	s1,40(sp)
    800041f8:	f04a                	sd	s2,32(sp)
    800041fa:	ec4e                	sd	s3,24(sp)
    800041fc:	e852                	sd	s4,16(sp)
    800041fe:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004200:	04451703          	lh	a4,68(a0)
    80004204:	4785                	li	a5,1
    80004206:	00f71a63          	bne	a4,a5,8000421a <dirlookup+0x2a>
    8000420a:	892a                	mv	s2,a0
    8000420c:	89ae                	mv	s3,a1
    8000420e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004210:	457c                	lw	a5,76(a0)
    80004212:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004214:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004216:	e79d                	bnez	a5,80004244 <dirlookup+0x54>
    80004218:	a8a5                	j	80004290 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000421a:	00004517          	auipc	a0,0x4
    8000421e:	5b650513          	addi	a0,a0,1462 # 800087d0 <syscalls+0x1b8>
    80004222:	ffffc097          	auipc	ra,0xffffc
    80004226:	31c080e7          	jalr	796(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000422a:	00004517          	auipc	a0,0x4
    8000422e:	5be50513          	addi	a0,a0,1470 # 800087e8 <syscalls+0x1d0>
    80004232:	ffffc097          	auipc	ra,0xffffc
    80004236:	30c080e7          	jalr	780(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000423a:	24c1                	addiw	s1,s1,16
    8000423c:	04c92783          	lw	a5,76(s2)
    80004240:	04f4f763          	bgeu	s1,a5,8000428e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004244:	4741                	li	a4,16
    80004246:	86a6                	mv	a3,s1
    80004248:	fc040613          	addi	a2,s0,-64
    8000424c:	4581                	li	a1,0
    8000424e:	854a                	mv	a0,s2
    80004250:	00000097          	auipc	ra,0x0
    80004254:	d70080e7          	jalr	-656(ra) # 80003fc0 <readi>
    80004258:	47c1                	li	a5,16
    8000425a:	fcf518e3          	bne	a0,a5,8000422a <dirlookup+0x3a>
    if(de.inum == 0)
    8000425e:	fc045783          	lhu	a5,-64(s0)
    80004262:	dfe1                	beqz	a5,8000423a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004264:	fc240593          	addi	a1,s0,-62
    80004268:	854e                	mv	a0,s3
    8000426a:	00000097          	auipc	ra,0x0
    8000426e:	f6c080e7          	jalr	-148(ra) # 800041d6 <namecmp>
    80004272:	f561                	bnez	a0,8000423a <dirlookup+0x4a>
      if(poff)
    80004274:	000a0463          	beqz	s4,8000427c <dirlookup+0x8c>
        *poff = off;
    80004278:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000427c:	fc045583          	lhu	a1,-64(s0)
    80004280:	00092503          	lw	a0,0(s2)
    80004284:	fffff097          	auipc	ra,0xfffff
    80004288:	754080e7          	jalr	1876(ra) # 800039d8 <iget>
    8000428c:	a011                	j	80004290 <dirlookup+0xa0>
  return 0;
    8000428e:	4501                	li	a0,0
}
    80004290:	70e2                	ld	ra,56(sp)
    80004292:	7442                	ld	s0,48(sp)
    80004294:	74a2                	ld	s1,40(sp)
    80004296:	7902                	ld	s2,32(sp)
    80004298:	69e2                	ld	s3,24(sp)
    8000429a:	6a42                	ld	s4,16(sp)
    8000429c:	6121                	addi	sp,sp,64
    8000429e:	8082                	ret

00000000800042a0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042a0:	711d                	addi	sp,sp,-96
    800042a2:	ec86                	sd	ra,88(sp)
    800042a4:	e8a2                	sd	s0,80(sp)
    800042a6:	e4a6                	sd	s1,72(sp)
    800042a8:	e0ca                	sd	s2,64(sp)
    800042aa:	fc4e                	sd	s3,56(sp)
    800042ac:	f852                	sd	s4,48(sp)
    800042ae:	f456                	sd	s5,40(sp)
    800042b0:	f05a                	sd	s6,32(sp)
    800042b2:	ec5e                	sd	s7,24(sp)
    800042b4:	e862                	sd	s8,16(sp)
    800042b6:	e466                	sd	s9,8(sp)
    800042b8:	1080                	addi	s0,sp,96
    800042ba:	84aa                	mv	s1,a0
    800042bc:	8b2e                	mv	s6,a1
    800042be:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042c0:	00054703          	lbu	a4,0(a0)
    800042c4:	02f00793          	li	a5,47
    800042c8:	02f70363          	beq	a4,a5,800042ee <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042cc:	ffffe097          	auipc	ra,0xffffe
    800042d0:	a68080e7          	jalr	-1432(ra) # 80001d34 <myproc>
    800042d4:	15053503          	ld	a0,336(a0)
    800042d8:	00000097          	auipc	ra,0x0
    800042dc:	9f6080e7          	jalr	-1546(ra) # 80003cce <idup>
    800042e0:	89aa                	mv	s3,a0
  while(*path == '/')
    800042e2:	02f00913          	li	s2,47
  len = path - s;
    800042e6:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800042e8:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042ea:	4c05                	li	s8,1
    800042ec:	a865                	j	800043a4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800042ee:	4585                	li	a1,1
    800042f0:	4505                	li	a0,1
    800042f2:	fffff097          	auipc	ra,0xfffff
    800042f6:	6e6080e7          	jalr	1766(ra) # 800039d8 <iget>
    800042fa:	89aa                	mv	s3,a0
    800042fc:	b7dd                	j	800042e2 <namex+0x42>
      iunlockput(ip);
    800042fe:	854e                	mv	a0,s3
    80004300:	00000097          	auipc	ra,0x0
    80004304:	c6e080e7          	jalr	-914(ra) # 80003f6e <iunlockput>
      return 0;
    80004308:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000430a:	854e                	mv	a0,s3
    8000430c:	60e6                	ld	ra,88(sp)
    8000430e:	6446                	ld	s0,80(sp)
    80004310:	64a6                	ld	s1,72(sp)
    80004312:	6906                	ld	s2,64(sp)
    80004314:	79e2                	ld	s3,56(sp)
    80004316:	7a42                	ld	s4,48(sp)
    80004318:	7aa2                	ld	s5,40(sp)
    8000431a:	7b02                	ld	s6,32(sp)
    8000431c:	6be2                	ld	s7,24(sp)
    8000431e:	6c42                	ld	s8,16(sp)
    80004320:	6ca2                	ld	s9,8(sp)
    80004322:	6125                	addi	sp,sp,96
    80004324:	8082                	ret
      iunlock(ip);
    80004326:	854e                	mv	a0,s3
    80004328:	00000097          	auipc	ra,0x0
    8000432c:	aa6080e7          	jalr	-1370(ra) # 80003dce <iunlock>
      return ip;
    80004330:	bfe9                	j	8000430a <namex+0x6a>
      iunlockput(ip);
    80004332:	854e                	mv	a0,s3
    80004334:	00000097          	auipc	ra,0x0
    80004338:	c3a080e7          	jalr	-966(ra) # 80003f6e <iunlockput>
      return 0;
    8000433c:	89d2                	mv	s3,s4
    8000433e:	b7f1                	j	8000430a <namex+0x6a>
  len = path - s;
    80004340:	40b48633          	sub	a2,s1,a1
    80004344:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004348:	094cd463          	bge	s9,s4,800043d0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000434c:	4639                	li	a2,14
    8000434e:	8556                	mv	a0,s5
    80004350:	ffffd097          	auipc	ra,0xffffd
    80004354:	9f0080e7          	jalr	-1552(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004358:	0004c783          	lbu	a5,0(s1)
    8000435c:	01279763          	bne	a5,s2,8000436a <namex+0xca>
    path++;
    80004360:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004362:	0004c783          	lbu	a5,0(s1)
    80004366:	ff278de3          	beq	a5,s2,80004360 <namex+0xc0>
    ilock(ip);
    8000436a:	854e                	mv	a0,s3
    8000436c:	00000097          	auipc	ra,0x0
    80004370:	9a0080e7          	jalr	-1632(ra) # 80003d0c <ilock>
    if(ip->type != T_DIR){
    80004374:	04499783          	lh	a5,68(s3)
    80004378:	f98793e3          	bne	a5,s8,800042fe <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000437c:	000b0563          	beqz	s6,80004386 <namex+0xe6>
    80004380:	0004c783          	lbu	a5,0(s1)
    80004384:	d3cd                	beqz	a5,80004326 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004386:	865e                	mv	a2,s7
    80004388:	85d6                	mv	a1,s5
    8000438a:	854e                	mv	a0,s3
    8000438c:	00000097          	auipc	ra,0x0
    80004390:	e64080e7          	jalr	-412(ra) # 800041f0 <dirlookup>
    80004394:	8a2a                	mv	s4,a0
    80004396:	dd51                	beqz	a0,80004332 <namex+0x92>
    iunlockput(ip);
    80004398:	854e                	mv	a0,s3
    8000439a:	00000097          	auipc	ra,0x0
    8000439e:	bd4080e7          	jalr	-1068(ra) # 80003f6e <iunlockput>
    ip = next;
    800043a2:	89d2                	mv	s3,s4
  while(*path == '/')
    800043a4:	0004c783          	lbu	a5,0(s1)
    800043a8:	05279763          	bne	a5,s2,800043f6 <namex+0x156>
    path++;
    800043ac:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043ae:	0004c783          	lbu	a5,0(s1)
    800043b2:	ff278de3          	beq	a5,s2,800043ac <namex+0x10c>
  if(*path == 0)
    800043b6:	c79d                	beqz	a5,800043e4 <namex+0x144>
    path++;
    800043b8:	85a6                	mv	a1,s1
  len = path - s;
    800043ba:	8a5e                	mv	s4,s7
    800043bc:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800043be:	01278963          	beq	a5,s2,800043d0 <namex+0x130>
    800043c2:	dfbd                	beqz	a5,80004340 <namex+0xa0>
    path++;
    800043c4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800043c6:	0004c783          	lbu	a5,0(s1)
    800043ca:	ff279ce3          	bne	a5,s2,800043c2 <namex+0x122>
    800043ce:	bf8d                	j	80004340 <namex+0xa0>
    memmove(name, s, len);
    800043d0:	2601                	sext.w	a2,a2
    800043d2:	8556                	mv	a0,s5
    800043d4:	ffffd097          	auipc	ra,0xffffd
    800043d8:	96c080e7          	jalr	-1684(ra) # 80000d40 <memmove>
    name[len] = 0;
    800043dc:	9a56                	add	s4,s4,s5
    800043de:	000a0023          	sb	zero,0(s4)
    800043e2:	bf9d                	j	80004358 <namex+0xb8>
  if(nameiparent){
    800043e4:	f20b03e3          	beqz	s6,8000430a <namex+0x6a>
    iput(ip);
    800043e8:	854e                	mv	a0,s3
    800043ea:	00000097          	auipc	ra,0x0
    800043ee:	adc080e7          	jalr	-1316(ra) # 80003ec6 <iput>
    return 0;
    800043f2:	4981                	li	s3,0
    800043f4:	bf19                	j	8000430a <namex+0x6a>
  if(*path == 0)
    800043f6:	d7fd                	beqz	a5,800043e4 <namex+0x144>
  while(*path != '/' && *path != 0)
    800043f8:	0004c783          	lbu	a5,0(s1)
    800043fc:	85a6                	mv	a1,s1
    800043fe:	b7d1                	j	800043c2 <namex+0x122>

0000000080004400 <dirlink>:
{
    80004400:	7139                	addi	sp,sp,-64
    80004402:	fc06                	sd	ra,56(sp)
    80004404:	f822                	sd	s0,48(sp)
    80004406:	f426                	sd	s1,40(sp)
    80004408:	f04a                	sd	s2,32(sp)
    8000440a:	ec4e                	sd	s3,24(sp)
    8000440c:	e852                	sd	s4,16(sp)
    8000440e:	0080                	addi	s0,sp,64
    80004410:	892a                	mv	s2,a0
    80004412:	8a2e                	mv	s4,a1
    80004414:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004416:	4601                	li	a2,0
    80004418:	00000097          	auipc	ra,0x0
    8000441c:	dd8080e7          	jalr	-552(ra) # 800041f0 <dirlookup>
    80004420:	e93d                	bnez	a0,80004496 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004422:	04c92483          	lw	s1,76(s2)
    80004426:	c49d                	beqz	s1,80004454 <dirlink+0x54>
    80004428:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000442a:	4741                	li	a4,16
    8000442c:	86a6                	mv	a3,s1
    8000442e:	fc040613          	addi	a2,s0,-64
    80004432:	4581                	li	a1,0
    80004434:	854a                	mv	a0,s2
    80004436:	00000097          	auipc	ra,0x0
    8000443a:	b8a080e7          	jalr	-1142(ra) # 80003fc0 <readi>
    8000443e:	47c1                	li	a5,16
    80004440:	06f51163          	bne	a0,a5,800044a2 <dirlink+0xa2>
    if(de.inum == 0)
    80004444:	fc045783          	lhu	a5,-64(s0)
    80004448:	c791                	beqz	a5,80004454 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000444a:	24c1                	addiw	s1,s1,16
    8000444c:	04c92783          	lw	a5,76(s2)
    80004450:	fcf4ede3          	bltu	s1,a5,8000442a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004454:	4639                	li	a2,14
    80004456:	85d2                	mv	a1,s4
    80004458:	fc240513          	addi	a0,s0,-62
    8000445c:	ffffd097          	auipc	ra,0xffffd
    80004460:	998080e7          	jalr	-1640(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004464:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004468:	4741                	li	a4,16
    8000446a:	86a6                	mv	a3,s1
    8000446c:	fc040613          	addi	a2,s0,-64
    80004470:	4581                	li	a1,0
    80004472:	854a                	mv	a0,s2
    80004474:	00000097          	auipc	ra,0x0
    80004478:	c44080e7          	jalr	-956(ra) # 800040b8 <writei>
    8000447c:	872a                	mv	a4,a0
    8000447e:	47c1                	li	a5,16
  return 0;
    80004480:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004482:	02f71863          	bne	a4,a5,800044b2 <dirlink+0xb2>
}
    80004486:	70e2                	ld	ra,56(sp)
    80004488:	7442                	ld	s0,48(sp)
    8000448a:	74a2                	ld	s1,40(sp)
    8000448c:	7902                	ld	s2,32(sp)
    8000448e:	69e2                	ld	s3,24(sp)
    80004490:	6a42                	ld	s4,16(sp)
    80004492:	6121                	addi	sp,sp,64
    80004494:	8082                	ret
    iput(ip);
    80004496:	00000097          	auipc	ra,0x0
    8000449a:	a30080e7          	jalr	-1488(ra) # 80003ec6 <iput>
    return -1;
    8000449e:	557d                	li	a0,-1
    800044a0:	b7dd                	j	80004486 <dirlink+0x86>
      panic("dirlink read");
    800044a2:	00004517          	auipc	a0,0x4
    800044a6:	35650513          	addi	a0,a0,854 # 800087f8 <syscalls+0x1e0>
    800044aa:	ffffc097          	auipc	ra,0xffffc
    800044ae:	094080e7          	jalr	148(ra) # 8000053e <panic>
    panic("dirlink");
    800044b2:	00004517          	auipc	a0,0x4
    800044b6:	45650513          	addi	a0,a0,1110 # 80008908 <syscalls+0x2f0>
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	084080e7          	jalr	132(ra) # 8000053e <panic>

00000000800044c2 <namei>:

struct inode*
namei(char *path)
{
    800044c2:	1101                	addi	sp,sp,-32
    800044c4:	ec06                	sd	ra,24(sp)
    800044c6:	e822                	sd	s0,16(sp)
    800044c8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044ca:	fe040613          	addi	a2,s0,-32
    800044ce:	4581                	li	a1,0
    800044d0:	00000097          	auipc	ra,0x0
    800044d4:	dd0080e7          	jalr	-560(ra) # 800042a0 <namex>
}
    800044d8:	60e2                	ld	ra,24(sp)
    800044da:	6442                	ld	s0,16(sp)
    800044dc:	6105                	addi	sp,sp,32
    800044de:	8082                	ret

00000000800044e0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044e0:	1141                	addi	sp,sp,-16
    800044e2:	e406                	sd	ra,8(sp)
    800044e4:	e022                	sd	s0,0(sp)
    800044e6:	0800                	addi	s0,sp,16
    800044e8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044ea:	4585                	li	a1,1
    800044ec:	00000097          	auipc	ra,0x0
    800044f0:	db4080e7          	jalr	-588(ra) # 800042a0 <namex>
}
    800044f4:	60a2                	ld	ra,8(sp)
    800044f6:	6402                	ld	s0,0(sp)
    800044f8:	0141                	addi	sp,sp,16
    800044fa:	8082                	ret

00000000800044fc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044fc:	1101                	addi	sp,sp,-32
    800044fe:	ec06                	sd	ra,24(sp)
    80004500:	e822                	sd	s0,16(sp)
    80004502:	e426                	sd	s1,8(sp)
    80004504:	e04a                	sd	s2,0(sp)
    80004506:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004508:	0001d917          	auipc	s2,0x1d
    8000450c:	22890913          	addi	s2,s2,552 # 80021730 <log>
    80004510:	01892583          	lw	a1,24(s2)
    80004514:	02892503          	lw	a0,40(s2)
    80004518:	fffff097          	auipc	ra,0xfffff
    8000451c:	ff2080e7          	jalr	-14(ra) # 8000350a <bread>
    80004520:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004522:	02c92683          	lw	a3,44(s2)
    80004526:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004528:	02d05763          	blez	a3,80004556 <write_head+0x5a>
    8000452c:	0001d797          	auipc	a5,0x1d
    80004530:	23478793          	addi	a5,a5,564 # 80021760 <log+0x30>
    80004534:	05c50713          	addi	a4,a0,92
    80004538:	36fd                	addiw	a3,a3,-1
    8000453a:	1682                	slli	a3,a3,0x20
    8000453c:	9281                	srli	a3,a3,0x20
    8000453e:	068a                	slli	a3,a3,0x2
    80004540:	0001d617          	auipc	a2,0x1d
    80004544:	22460613          	addi	a2,a2,548 # 80021764 <log+0x34>
    80004548:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000454a:	4390                	lw	a2,0(a5)
    8000454c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000454e:	0791                	addi	a5,a5,4
    80004550:	0711                	addi	a4,a4,4
    80004552:	fed79ce3          	bne	a5,a3,8000454a <write_head+0x4e>
  }
  bwrite(buf);
    80004556:	8526                	mv	a0,s1
    80004558:	fffff097          	auipc	ra,0xfffff
    8000455c:	0a4080e7          	jalr	164(ra) # 800035fc <bwrite>
  brelse(buf);
    80004560:	8526                	mv	a0,s1
    80004562:	fffff097          	auipc	ra,0xfffff
    80004566:	0d8080e7          	jalr	216(ra) # 8000363a <brelse>
}
    8000456a:	60e2                	ld	ra,24(sp)
    8000456c:	6442                	ld	s0,16(sp)
    8000456e:	64a2                	ld	s1,8(sp)
    80004570:	6902                	ld	s2,0(sp)
    80004572:	6105                	addi	sp,sp,32
    80004574:	8082                	ret

0000000080004576 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004576:	0001d797          	auipc	a5,0x1d
    8000457a:	1e67a783          	lw	a5,486(a5) # 8002175c <log+0x2c>
    8000457e:	0af05d63          	blez	a5,80004638 <install_trans+0xc2>
{
    80004582:	7139                	addi	sp,sp,-64
    80004584:	fc06                	sd	ra,56(sp)
    80004586:	f822                	sd	s0,48(sp)
    80004588:	f426                	sd	s1,40(sp)
    8000458a:	f04a                	sd	s2,32(sp)
    8000458c:	ec4e                	sd	s3,24(sp)
    8000458e:	e852                	sd	s4,16(sp)
    80004590:	e456                	sd	s5,8(sp)
    80004592:	e05a                	sd	s6,0(sp)
    80004594:	0080                	addi	s0,sp,64
    80004596:	8b2a                	mv	s6,a0
    80004598:	0001da97          	auipc	s5,0x1d
    8000459c:	1c8a8a93          	addi	s5,s5,456 # 80021760 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045a0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045a2:	0001d997          	auipc	s3,0x1d
    800045a6:	18e98993          	addi	s3,s3,398 # 80021730 <log>
    800045aa:	a035                	j	800045d6 <install_trans+0x60>
      bunpin(dbuf);
    800045ac:	8526                	mv	a0,s1
    800045ae:	fffff097          	auipc	ra,0xfffff
    800045b2:	166080e7          	jalr	358(ra) # 80003714 <bunpin>
    brelse(lbuf);
    800045b6:	854a                	mv	a0,s2
    800045b8:	fffff097          	auipc	ra,0xfffff
    800045bc:	082080e7          	jalr	130(ra) # 8000363a <brelse>
    brelse(dbuf);
    800045c0:	8526                	mv	a0,s1
    800045c2:	fffff097          	auipc	ra,0xfffff
    800045c6:	078080e7          	jalr	120(ra) # 8000363a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ca:	2a05                	addiw	s4,s4,1
    800045cc:	0a91                	addi	s5,s5,4
    800045ce:	02c9a783          	lw	a5,44(s3)
    800045d2:	04fa5963          	bge	s4,a5,80004624 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045d6:	0189a583          	lw	a1,24(s3)
    800045da:	014585bb          	addw	a1,a1,s4
    800045de:	2585                	addiw	a1,a1,1
    800045e0:	0289a503          	lw	a0,40(s3)
    800045e4:	fffff097          	auipc	ra,0xfffff
    800045e8:	f26080e7          	jalr	-218(ra) # 8000350a <bread>
    800045ec:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045ee:	000aa583          	lw	a1,0(s5)
    800045f2:	0289a503          	lw	a0,40(s3)
    800045f6:	fffff097          	auipc	ra,0xfffff
    800045fa:	f14080e7          	jalr	-236(ra) # 8000350a <bread>
    800045fe:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004600:	40000613          	li	a2,1024
    80004604:	05890593          	addi	a1,s2,88
    80004608:	05850513          	addi	a0,a0,88
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	734080e7          	jalr	1844(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004614:	8526                	mv	a0,s1
    80004616:	fffff097          	auipc	ra,0xfffff
    8000461a:	fe6080e7          	jalr	-26(ra) # 800035fc <bwrite>
    if(recovering == 0)
    8000461e:	f80b1ce3          	bnez	s6,800045b6 <install_trans+0x40>
    80004622:	b769                	j	800045ac <install_trans+0x36>
}
    80004624:	70e2                	ld	ra,56(sp)
    80004626:	7442                	ld	s0,48(sp)
    80004628:	74a2                	ld	s1,40(sp)
    8000462a:	7902                	ld	s2,32(sp)
    8000462c:	69e2                	ld	s3,24(sp)
    8000462e:	6a42                	ld	s4,16(sp)
    80004630:	6aa2                	ld	s5,8(sp)
    80004632:	6b02                	ld	s6,0(sp)
    80004634:	6121                	addi	sp,sp,64
    80004636:	8082                	ret
    80004638:	8082                	ret

000000008000463a <initlog>:
{
    8000463a:	7179                	addi	sp,sp,-48
    8000463c:	f406                	sd	ra,40(sp)
    8000463e:	f022                	sd	s0,32(sp)
    80004640:	ec26                	sd	s1,24(sp)
    80004642:	e84a                	sd	s2,16(sp)
    80004644:	e44e                	sd	s3,8(sp)
    80004646:	1800                	addi	s0,sp,48
    80004648:	892a                	mv	s2,a0
    8000464a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000464c:	0001d497          	auipc	s1,0x1d
    80004650:	0e448493          	addi	s1,s1,228 # 80021730 <log>
    80004654:	00004597          	auipc	a1,0x4
    80004658:	1b458593          	addi	a1,a1,436 # 80008808 <syscalls+0x1f0>
    8000465c:	8526                	mv	a0,s1
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	4f6080e7          	jalr	1270(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004666:	0149a583          	lw	a1,20(s3)
    8000466a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000466c:	0109a783          	lw	a5,16(s3)
    80004670:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004672:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004676:	854a                	mv	a0,s2
    80004678:	fffff097          	auipc	ra,0xfffff
    8000467c:	e92080e7          	jalr	-366(ra) # 8000350a <bread>
  log.lh.n = lh->n;
    80004680:	4d3c                	lw	a5,88(a0)
    80004682:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004684:	02f05563          	blez	a5,800046ae <initlog+0x74>
    80004688:	05c50713          	addi	a4,a0,92
    8000468c:	0001d697          	auipc	a3,0x1d
    80004690:	0d468693          	addi	a3,a3,212 # 80021760 <log+0x30>
    80004694:	37fd                	addiw	a5,a5,-1
    80004696:	1782                	slli	a5,a5,0x20
    80004698:	9381                	srli	a5,a5,0x20
    8000469a:	078a                	slli	a5,a5,0x2
    8000469c:	06050613          	addi	a2,a0,96
    800046a0:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800046a2:	4310                	lw	a2,0(a4)
    800046a4:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800046a6:	0711                	addi	a4,a4,4
    800046a8:	0691                	addi	a3,a3,4
    800046aa:	fef71ce3          	bne	a4,a5,800046a2 <initlog+0x68>
  brelse(buf);
    800046ae:	fffff097          	auipc	ra,0xfffff
    800046b2:	f8c080e7          	jalr	-116(ra) # 8000363a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046b6:	4505                	li	a0,1
    800046b8:	00000097          	auipc	ra,0x0
    800046bc:	ebe080e7          	jalr	-322(ra) # 80004576 <install_trans>
  log.lh.n = 0;
    800046c0:	0001d797          	auipc	a5,0x1d
    800046c4:	0807ae23          	sw	zero,156(a5) # 8002175c <log+0x2c>
  write_head(); // clear the log
    800046c8:	00000097          	auipc	ra,0x0
    800046cc:	e34080e7          	jalr	-460(ra) # 800044fc <write_head>
}
    800046d0:	70a2                	ld	ra,40(sp)
    800046d2:	7402                	ld	s0,32(sp)
    800046d4:	64e2                	ld	s1,24(sp)
    800046d6:	6942                	ld	s2,16(sp)
    800046d8:	69a2                	ld	s3,8(sp)
    800046da:	6145                	addi	sp,sp,48
    800046dc:	8082                	ret

00000000800046de <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046de:	1101                	addi	sp,sp,-32
    800046e0:	ec06                	sd	ra,24(sp)
    800046e2:	e822                	sd	s0,16(sp)
    800046e4:	e426                	sd	s1,8(sp)
    800046e6:	e04a                	sd	s2,0(sp)
    800046e8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046ea:	0001d517          	auipc	a0,0x1d
    800046ee:	04650513          	addi	a0,a0,70 # 80021730 <log>
    800046f2:	ffffc097          	auipc	ra,0xffffc
    800046f6:	4f2080e7          	jalr	1266(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800046fa:	0001d497          	auipc	s1,0x1d
    800046fe:	03648493          	addi	s1,s1,54 # 80021730 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004702:	4979                	li	s2,30
    80004704:	a039                	j	80004712 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004706:	85a6                	mv	a1,s1
    80004708:	8526                	mv	a0,s1
    8000470a:	ffffe097          	auipc	ra,0xffffe
    8000470e:	cb8080e7          	jalr	-840(ra) # 800023c2 <sleep>
    if(log.committing){
    80004712:	50dc                	lw	a5,36(s1)
    80004714:	fbed                	bnez	a5,80004706 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004716:	509c                	lw	a5,32(s1)
    80004718:	0017871b          	addiw	a4,a5,1
    8000471c:	0007069b          	sext.w	a3,a4
    80004720:	0027179b          	slliw	a5,a4,0x2
    80004724:	9fb9                	addw	a5,a5,a4
    80004726:	0017979b          	slliw	a5,a5,0x1
    8000472a:	54d8                	lw	a4,44(s1)
    8000472c:	9fb9                	addw	a5,a5,a4
    8000472e:	00f95963          	bge	s2,a5,80004740 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004732:	85a6                	mv	a1,s1
    80004734:	8526                	mv	a0,s1
    80004736:	ffffe097          	auipc	ra,0xffffe
    8000473a:	c8c080e7          	jalr	-884(ra) # 800023c2 <sleep>
    8000473e:	bfd1                	j	80004712 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004740:	0001d517          	auipc	a0,0x1d
    80004744:	ff050513          	addi	a0,a0,-16 # 80021730 <log>
    80004748:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	54e080e7          	jalr	1358(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004752:	60e2                	ld	ra,24(sp)
    80004754:	6442                	ld	s0,16(sp)
    80004756:	64a2                	ld	s1,8(sp)
    80004758:	6902                	ld	s2,0(sp)
    8000475a:	6105                	addi	sp,sp,32
    8000475c:	8082                	ret

000000008000475e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000475e:	7139                	addi	sp,sp,-64
    80004760:	fc06                	sd	ra,56(sp)
    80004762:	f822                	sd	s0,48(sp)
    80004764:	f426                	sd	s1,40(sp)
    80004766:	f04a                	sd	s2,32(sp)
    80004768:	ec4e                	sd	s3,24(sp)
    8000476a:	e852                	sd	s4,16(sp)
    8000476c:	e456                	sd	s5,8(sp)
    8000476e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004770:	0001d497          	auipc	s1,0x1d
    80004774:	fc048493          	addi	s1,s1,-64 # 80021730 <log>
    80004778:	8526                	mv	a0,s1
    8000477a:	ffffc097          	auipc	ra,0xffffc
    8000477e:	46a080e7          	jalr	1130(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004782:	509c                	lw	a5,32(s1)
    80004784:	37fd                	addiw	a5,a5,-1
    80004786:	0007891b          	sext.w	s2,a5
    8000478a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000478c:	50dc                	lw	a5,36(s1)
    8000478e:	efb9                	bnez	a5,800047ec <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004790:	06091663          	bnez	s2,800047fc <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004794:	0001d497          	auipc	s1,0x1d
    80004798:	f9c48493          	addi	s1,s1,-100 # 80021730 <log>
    8000479c:	4785                	li	a5,1
    8000479e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047a0:	8526                	mv	a0,s1
    800047a2:	ffffc097          	auipc	ra,0xffffc
    800047a6:	4f6080e7          	jalr	1270(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047aa:	54dc                	lw	a5,44(s1)
    800047ac:	06f04763          	bgtz	a5,8000481a <end_op+0xbc>
    acquire(&log.lock);
    800047b0:	0001d497          	auipc	s1,0x1d
    800047b4:	f8048493          	addi	s1,s1,-128 # 80021730 <log>
    800047b8:	8526                	mv	a0,s1
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	42a080e7          	jalr	1066(ra) # 80000be4 <acquire>
    log.committing = 0;
    800047c2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047c6:	8526                	mv	a0,s1
    800047c8:	ffffe097          	auipc	ra,0xffffe
    800047cc:	210080e7          	jalr	528(ra) # 800029d8 <wakeup>
    release(&log.lock);
    800047d0:	8526                	mv	a0,s1
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	4c6080e7          	jalr	1222(ra) # 80000c98 <release>
}
    800047da:	70e2                	ld	ra,56(sp)
    800047dc:	7442                	ld	s0,48(sp)
    800047de:	74a2                	ld	s1,40(sp)
    800047e0:	7902                	ld	s2,32(sp)
    800047e2:	69e2                	ld	s3,24(sp)
    800047e4:	6a42                	ld	s4,16(sp)
    800047e6:	6aa2                	ld	s5,8(sp)
    800047e8:	6121                	addi	sp,sp,64
    800047ea:	8082                	ret
    panic("log.committing");
    800047ec:	00004517          	auipc	a0,0x4
    800047f0:	02450513          	addi	a0,a0,36 # 80008810 <syscalls+0x1f8>
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	d4a080e7          	jalr	-694(ra) # 8000053e <panic>
    wakeup(&log);
    800047fc:	0001d497          	auipc	s1,0x1d
    80004800:	f3448493          	addi	s1,s1,-204 # 80021730 <log>
    80004804:	8526                	mv	a0,s1
    80004806:	ffffe097          	auipc	ra,0xffffe
    8000480a:	1d2080e7          	jalr	466(ra) # 800029d8 <wakeup>
  release(&log.lock);
    8000480e:	8526                	mv	a0,s1
    80004810:	ffffc097          	auipc	ra,0xffffc
    80004814:	488080e7          	jalr	1160(ra) # 80000c98 <release>
  if(do_commit){
    80004818:	b7c9                	j	800047da <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000481a:	0001da97          	auipc	s5,0x1d
    8000481e:	f46a8a93          	addi	s5,s5,-186 # 80021760 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004822:	0001da17          	auipc	s4,0x1d
    80004826:	f0ea0a13          	addi	s4,s4,-242 # 80021730 <log>
    8000482a:	018a2583          	lw	a1,24(s4)
    8000482e:	012585bb          	addw	a1,a1,s2
    80004832:	2585                	addiw	a1,a1,1
    80004834:	028a2503          	lw	a0,40(s4)
    80004838:	fffff097          	auipc	ra,0xfffff
    8000483c:	cd2080e7          	jalr	-814(ra) # 8000350a <bread>
    80004840:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004842:	000aa583          	lw	a1,0(s5)
    80004846:	028a2503          	lw	a0,40(s4)
    8000484a:	fffff097          	auipc	ra,0xfffff
    8000484e:	cc0080e7          	jalr	-832(ra) # 8000350a <bread>
    80004852:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004854:	40000613          	li	a2,1024
    80004858:	05850593          	addi	a1,a0,88
    8000485c:	05848513          	addi	a0,s1,88
    80004860:	ffffc097          	auipc	ra,0xffffc
    80004864:	4e0080e7          	jalr	1248(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004868:	8526                	mv	a0,s1
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	d92080e7          	jalr	-622(ra) # 800035fc <bwrite>
    brelse(from);
    80004872:	854e                	mv	a0,s3
    80004874:	fffff097          	auipc	ra,0xfffff
    80004878:	dc6080e7          	jalr	-570(ra) # 8000363a <brelse>
    brelse(to);
    8000487c:	8526                	mv	a0,s1
    8000487e:	fffff097          	auipc	ra,0xfffff
    80004882:	dbc080e7          	jalr	-580(ra) # 8000363a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004886:	2905                	addiw	s2,s2,1
    80004888:	0a91                	addi	s5,s5,4
    8000488a:	02ca2783          	lw	a5,44(s4)
    8000488e:	f8f94ee3          	blt	s2,a5,8000482a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004892:	00000097          	auipc	ra,0x0
    80004896:	c6a080e7          	jalr	-918(ra) # 800044fc <write_head>
    install_trans(0); // Now install writes to home locations
    8000489a:	4501                	li	a0,0
    8000489c:	00000097          	auipc	ra,0x0
    800048a0:	cda080e7          	jalr	-806(ra) # 80004576 <install_trans>
    log.lh.n = 0;
    800048a4:	0001d797          	auipc	a5,0x1d
    800048a8:	ea07ac23          	sw	zero,-328(a5) # 8002175c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048ac:	00000097          	auipc	ra,0x0
    800048b0:	c50080e7          	jalr	-944(ra) # 800044fc <write_head>
    800048b4:	bdf5                	j	800047b0 <end_op+0x52>

00000000800048b6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048b6:	1101                	addi	sp,sp,-32
    800048b8:	ec06                	sd	ra,24(sp)
    800048ba:	e822                	sd	s0,16(sp)
    800048bc:	e426                	sd	s1,8(sp)
    800048be:	e04a                	sd	s2,0(sp)
    800048c0:	1000                	addi	s0,sp,32
    800048c2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048c4:	0001d917          	auipc	s2,0x1d
    800048c8:	e6c90913          	addi	s2,s2,-404 # 80021730 <log>
    800048cc:	854a                	mv	a0,s2
    800048ce:	ffffc097          	auipc	ra,0xffffc
    800048d2:	316080e7          	jalr	790(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048d6:	02c92603          	lw	a2,44(s2)
    800048da:	47f5                	li	a5,29
    800048dc:	06c7c563          	blt	a5,a2,80004946 <log_write+0x90>
    800048e0:	0001d797          	auipc	a5,0x1d
    800048e4:	e6c7a783          	lw	a5,-404(a5) # 8002174c <log+0x1c>
    800048e8:	37fd                	addiw	a5,a5,-1
    800048ea:	04f65e63          	bge	a2,a5,80004946 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048ee:	0001d797          	auipc	a5,0x1d
    800048f2:	e627a783          	lw	a5,-414(a5) # 80021750 <log+0x20>
    800048f6:	06f05063          	blez	a5,80004956 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048fa:	4781                	li	a5,0
    800048fc:	06c05563          	blez	a2,80004966 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004900:	44cc                	lw	a1,12(s1)
    80004902:	0001d717          	auipc	a4,0x1d
    80004906:	e5e70713          	addi	a4,a4,-418 # 80021760 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000490a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000490c:	4314                	lw	a3,0(a4)
    8000490e:	04b68c63          	beq	a3,a1,80004966 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004912:	2785                	addiw	a5,a5,1
    80004914:	0711                	addi	a4,a4,4
    80004916:	fef61be3          	bne	a2,a5,8000490c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000491a:	0621                	addi	a2,a2,8
    8000491c:	060a                	slli	a2,a2,0x2
    8000491e:	0001d797          	auipc	a5,0x1d
    80004922:	e1278793          	addi	a5,a5,-494 # 80021730 <log>
    80004926:	963e                	add	a2,a2,a5
    80004928:	44dc                	lw	a5,12(s1)
    8000492a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000492c:	8526                	mv	a0,s1
    8000492e:	fffff097          	auipc	ra,0xfffff
    80004932:	daa080e7          	jalr	-598(ra) # 800036d8 <bpin>
    log.lh.n++;
    80004936:	0001d717          	auipc	a4,0x1d
    8000493a:	dfa70713          	addi	a4,a4,-518 # 80021730 <log>
    8000493e:	575c                	lw	a5,44(a4)
    80004940:	2785                	addiw	a5,a5,1
    80004942:	d75c                	sw	a5,44(a4)
    80004944:	a835                	j	80004980 <log_write+0xca>
    panic("too big a transaction");
    80004946:	00004517          	auipc	a0,0x4
    8000494a:	eda50513          	addi	a0,a0,-294 # 80008820 <syscalls+0x208>
    8000494e:	ffffc097          	auipc	ra,0xffffc
    80004952:	bf0080e7          	jalr	-1040(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004956:	00004517          	auipc	a0,0x4
    8000495a:	ee250513          	addi	a0,a0,-286 # 80008838 <syscalls+0x220>
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	be0080e7          	jalr	-1056(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004966:	00878713          	addi	a4,a5,8
    8000496a:	00271693          	slli	a3,a4,0x2
    8000496e:	0001d717          	auipc	a4,0x1d
    80004972:	dc270713          	addi	a4,a4,-574 # 80021730 <log>
    80004976:	9736                	add	a4,a4,a3
    80004978:	44d4                	lw	a3,12(s1)
    8000497a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000497c:	faf608e3          	beq	a2,a5,8000492c <log_write+0x76>
  }
  release(&log.lock);
    80004980:	0001d517          	auipc	a0,0x1d
    80004984:	db050513          	addi	a0,a0,-592 # 80021730 <log>
    80004988:	ffffc097          	auipc	ra,0xffffc
    8000498c:	310080e7          	jalr	784(ra) # 80000c98 <release>
}
    80004990:	60e2                	ld	ra,24(sp)
    80004992:	6442                	ld	s0,16(sp)
    80004994:	64a2                	ld	s1,8(sp)
    80004996:	6902                	ld	s2,0(sp)
    80004998:	6105                	addi	sp,sp,32
    8000499a:	8082                	ret

000000008000499c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000499c:	1101                	addi	sp,sp,-32
    8000499e:	ec06                	sd	ra,24(sp)
    800049a0:	e822                	sd	s0,16(sp)
    800049a2:	e426                	sd	s1,8(sp)
    800049a4:	e04a                	sd	s2,0(sp)
    800049a6:	1000                	addi	s0,sp,32
    800049a8:	84aa                	mv	s1,a0
    800049aa:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049ac:	00004597          	auipc	a1,0x4
    800049b0:	eac58593          	addi	a1,a1,-340 # 80008858 <syscalls+0x240>
    800049b4:	0521                	addi	a0,a0,8
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	19e080e7          	jalr	414(ra) # 80000b54 <initlock>
  lk->name = name;
    800049be:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049c2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049c6:	0204a423          	sw	zero,40(s1)
}
    800049ca:	60e2                	ld	ra,24(sp)
    800049cc:	6442                	ld	s0,16(sp)
    800049ce:	64a2                	ld	s1,8(sp)
    800049d0:	6902                	ld	s2,0(sp)
    800049d2:	6105                	addi	sp,sp,32
    800049d4:	8082                	ret

00000000800049d6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049d6:	1101                	addi	sp,sp,-32
    800049d8:	ec06                	sd	ra,24(sp)
    800049da:	e822                	sd	s0,16(sp)
    800049dc:	e426                	sd	s1,8(sp)
    800049de:	e04a                	sd	s2,0(sp)
    800049e0:	1000                	addi	s0,sp,32
    800049e2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049e4:	00850913          	addi	s2,a0,8
    800049e8:	854a                	mv	a0,s2
    800049ea:	ffffc097          	auipc	ra,0xffffc
    800049ee:	1fa080e7          	jalr	506(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800049f2:	409c                	lw	a5,0(s1)
    800049f4:	cb89                	beqz	a5,80004a06 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049f6:	85ca                	mv	a1,s2
    800049f8:	8526                	mv	a0,s1
    800049fa:	ffffe097          	auipc	ra,0xffffe
    800049fe:	9c8080e7          	jalr	-1592(ra) # 800023c2 <sleep>
  while (lk->locked) {
    80004a02:	409c                	lw	a5,0(s1)
    80004a04:	fbed                	bnez	a5,800049f6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a06:	4785                	li	a5,1
    80004a08:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a0a:	ffffd097          	auipc	ra,0xffffd
    80004a0e:	32a080e7          	jalr	810(ra) # 80001d34 <myproc>
    80004a12:	591c                	lw	a5,48(a0)
    80004a14:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a16:	854a                	mv	a0,s2
    80004a18:	ffffc097          	auipc	ra,0xffffc
    80004a1c:	280080e7          	jalr	640(ra) # 80000c98 <release>
}
    80004a20:	60e2                	ld	ra,24(sp)
    80004a22:	6442                	ld	s0,16(sp)
    80004a24:	64a2                	ld	s1,8(sp)
    80004a26:	6902                	ld	s2,0(sp)
    80004a28:	6105                	addi	sp,sp,32
    80004a2a:	8082                	ret

0000000080004a2c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a2c:	1101                	addi	sp,sp,-32
    80004a2e:	ec06                	sd	ra,24(sp)
    80004a30:	e822                	sd	s0,16(sp)
    80004a32:	e426                	sd	s1,8(sp)
    80004a34:	e04a                	sd	s2,0(sp)
    80004a36:	1000                	addi	s0,sp,32
    80004a38:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a3a:	00850913          	addi	s2,a0,8
    80004a3e:	854a                	mv	a0,s2
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	1a4080e7          	jalr	420(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004a48:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a4c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a50:	8526                	mv	a0,s1
    80004a52:	ffffe097          	auipc	ra,0xffffe
    80004a56:	f86080e7          	jalr	-122(ra) # 800029d8 <wakeup>
  release(&lk->lk);
    80004a5a:	854a                	mv	a0,s2
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	23c080e7          	jalr	572(ra) # 80000c98 <release>
}
    80004a64:	60e2                	ld	ra,24(sp)
    80004a66:	6442                	ld	s0,16(sp)
    80004a68:	64a2                	ld	s1,8(sp)
    80004a6a:	6902                	ld	s2,0(sp)
    80004a6c:	6105                	addi	sp,sp,32
    80004a6e:	8082                	ret

0000000080004a70 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a70:	7179                	addi	sp,sp,-48
    80004a72:	f406                	sd	ra,40(sp)
    80004a74:	f022                	sd	s0,32(sp)
    80004a76:	ec26                	sd	s1,24(sp)
    80004a78:	e84a                	sd	s2,16(sp)
    80004a7a:	e44e                	sd	s3,8(sp)
    80004a7c:	1800                	addi	s0,sp,48
    80004a7e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a80:	00850913          	addi	s2,a0,8
    80004a84:	854a                	mv	a0,s2
    80004a86:	ffffc097          	auipc	ra,0xffffc
    80004a8a:	15e080e7          	jalr	350(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a8e:	409c                	lw	a5,0(s1)
    80004a90:	ef99                	bnez	a5,80004aae <holdingsleep+0x3e>
    80004a92:	4481                	li	s1,0
  release(&lk->lk);
    80004a94:	854a                	mv	a0,s2
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	202080e7          	jalr	514(ra) # 80000c98 <release>
  return r;
}
    80004a9e:	8526                	mv	a0,s1
    80004aa0:	70a2                	ld	ra,40(sp)
    80004aa2:	7402                	ld	s0,32(sp)
    80004aa4:	64e2                	ld	s1,24(sp)
    80004aa6:	6942                	ld	s2,16(sp)
    80004aa8:	69a2                	ld	s3,8(sp)
    80004aaa:	6145                	addi	sp,sp,48
    80004aac:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004aae:	0284a983          	lw	s3,40(s1)
    80004ab2:	ffffd097          	auipc	ra,0xffffd
    80004ab6:	282080e7          	jalr	642(ra) # 80001d34 <myproc>
    80004aba:	5904                	lw	s1,48(a0)
    80004abc:	413484b3          	sub	s1,s1,s3
    80004ac0:	0014b493          	seqz	s1,s1
    80004ac4:	bfc1                	j	80004a94 <holdingsleep+0x24>

0000000080004ac6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ac6:	1141                	addi	sp,sp,-16
    80004ac8:	e406                	sd	ra,8(sp)
    80004aca:	e022                	sd	s0,0(sp)
    80004acc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ace:	00004597          	auipc	a1,0x4
    80004ad2:	d9a58593          	addi	a1,a1,-614 # 80008868 <syscalls+0x250>
    80004ad6:	0001d517          	auipc	a0,0x1d
    80004ada:	da250513          	addi	a0,a0,-606 # 80021878 <ftable>
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	076080e7          	jalr	118(ra) # 80000b54 <initlock>
}
    80004ae6:	60a2                	ld	ra,8(sp)
    80004ae8:	6402                	ld	s0,0(sp)
    80004aea:	0141                	addi	sp,sp,16
    80004aec:	8082                	ret

0000000080004aee <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004aee:	1101                	addi	sp,sp,-32
    80004af0:	ec06                	sd	ra,24(sp)
    80004af2:	e822                	sd	s0,16(sp)
    80004af4:	e426                	sd	s1,8(sp)
    80004af6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004af8:	0001d517          	auipc	a0,0x1d
    80004afc:	d8050513          	addi	a0,a0,-640 # 80021878 <ftable>
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	0e4080e7          	jalr	228(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b08:	0001d497          	auipc	s1,0x1d
    80004b0c:	d8848493          	addi	s1,s1,-632 # 80021890 <ftable+0x18>
    80004b10:	0001e717          	auipc	a4,0x1e
    80004b14:	d2070713          	addi	a4,a4,-736 # 80022830 <ftable+0xfb8>
    if(f->ref == 0){
    80004b18:	40dc                	lw	a5,4(s1)
    80004b1a:	cf99                	beqz	a5,80004b38 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b1c:	02848493          	addi	s1,s1,40
    80004b20:	fee49ce3          	bne	s1,a4,80004b18 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b24:	0001d517          	auipc	a0,0x1d
    80004b28:	d5450513          	addi	a0,a0,-684 # 80021878 <ftable>
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	16c080e7          	jalr	364(ra) # 80000c98 <release>
  return 0;
    80004b34:	4481                	li	s1,0
    80004b36:	a819                	j	80004b4c <filealloc+0x5e>
      f->ref = 1;
    80004b38:	4785                	li	a5,1
    80004b3a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b3c:	0001d517          	auipc	a0,0x1d
    80004b40:	d3c50513          	addi	a0,a0,-708 # 80021878 <ftable>
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	154080e7          	jalr	340(ra) # 80000c98 <release>
}
    80004b4c:	8526                	mv	a0,s1
    80004b4e:	60e2                	ld	ra,24(sp)
    80004b50:	6442                	ld	s0,16(sp)
    80004b52:	64a2                	ld	s1,8(sp)
    80004b54:	6105                	addi	sp,sp,32
    80004b56:	8082                	ret

0000000080004b58 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b58:	1101                	addi	sp,sp,-32
    80004b5a:	ec06                	sd	ra,24(sp)
    80004b5c:	e822                	sd	s0,16(sp)
    80004b5e:	e426                	sd	s1,8(sp)
    80004b60:	1000                	addi	s0,sp,32
    80004b62:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b64:	0001d517          	auipc	a0,0x1d
    80004b68:	d1450513          	addi	a0,a0,-748 # 80021878 <ftable>
    80004b6c:	ffffc097          	auipc	ra,0xffffc
    80004b70:	078080e7          	jalr	120(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b74:	40dc                	lw	a5,4(s1)
    80004b76:	02f05263          	blez	a5,80004b9a <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b7a:	2785                	addiw	a5,a5,1
    80004b7c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b7e:	0001d517          	auipc	a0,0x1d
    80004b82:	cfa50513          	addi	a0,a0,-774 # 80021878 <ftable>
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	112080e7          	jalr	274(ra) # 80000c98 <release>
  return f;
}
    80004b8e:	8526                	mv	a0,s1
    80004b90:	60e2                	ld	ra,24(sp)
    80004b92:	6442                	ld	s0,16(sp)
    80004b94:	64a2                	ld	s1,8(sp)
    80004b96:	6105                	addi	sp,sp,32
    80004b98:	8082                	ret
    panic("filedup");
    80004b9a:	00004517          	auipc	a0,0x4
    80004b9e:	cd650513          	addi	a0,a0,-810 # 80008870 <syscalls+0x258>
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	99c080e7          	jalr	-1636(ra) # 8000053e <panic>

0000000080004baa <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004baa:	7139                	addi	sp,sp,-64
    80004bac:	fc06                	sd	ra,56(sp)
    80004bae:	f822                	sd	s0,48(sp)
    80004bb0:	f426                	sd	s1,40(sp)
    80004bb2:	f04a                	sd	s2,32(sp)
    80004bb4:	ec4e                	sd	s3,24(sp)
    80004bb6:	e852                	sd	s4,16(sp)
    80004bb8:	e456                	sd	s5,8(sp)
    80004bba:	0080                	addi	s0,sp,64
    80004bbc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bbe:	0001d517          	auipc	a0,0x1d
    80004bc2:	cba50513          	addi	a0,a0,-838 # 80021878 <ftable>
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	01e080e7          	jalr	30(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004bce:	40dc                	lw	a5,4(s1)
    80004bd0:	06f05163          	blez	a5,80004c32 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004bd4:	37fd                	addiw	a5,a5,-1
    80004bd6:	0007871b          	sext.w	a4,a5
    80004bda:	c0dc                	sw	a5,4(s1)
    80004bdc:	06e04363          	bgtz	a4,80004c42 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004be0:	0004a903          	lw	s2,0(s1)
    80004be4:	0094ca83          	lbu	s5,9(s1)
    80004be8:	0104ba03          	ld	s4,16(s1)
    80004bec:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bf0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004bf4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004bf8:	0001d517          	auipc	a0,0x1d
    80004bfc:	c8050513          	addi	a0,a0,-896 # 80021878 <ftable>
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	098080e7          	jalr	152(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004c08:	4785                	li	a5,1
    80004c0a:	04f90d63          	beq	s2,a5,80004c64 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c0e:	3979                	addiw	s2,s2,-2
    80004c10:	4785                	li	a5,1
    80004c12:	0527e063          	bltu	a5,s2,80004c52 <fileclose+0xa8>
    begin_op();
    80004c16:	00000097          	auipc	ra,0x0
    80004c1a:	ac8080e7          	jalr	-1336(ra) # 800046de <begin_op>
    iput(ff.ip);
    80004c1e:	854e                	mv	a0,s3
    80004c20:	fffff097          	auipc	ra,0xfffff
    80004c24:	2a6080e7          	jalr	678(ra) # 80003ec6 <iput>
    end_op();
    80004c28:	00000097          	auipc	ra,0x0
    80004c2c:	b36080e7          	jalr	-1226(ra) # 8000475e <end_op>
    80004c30:	a00d                	j	80004c52 <fileclose+0xa8>
    panic("fileclose");
    80004c32:	00004517          	auipc	a0,0x4
    80004c36:	c4650513          	addi	a0,a0,-954 # 80008878 <syscalls+0x260>
    80004c3a:	ffffc097          	auipc	ra,0xffffc
    80004c3e:	904080e7          	jalr	-1788(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004c42:	0001d517          	auipc	a0,0x1d
    80004c46:	c3650513          	addi	a0,a0,-970 # 80021878 <ftable>
    80004c4a:	ffffc097          	auipc	ra,0xffffc
    80004c4e:	04e080e7          	jalr	78(ra) # 80000c98 <release>
  }
}
    80004c52:	70e2                	ld	ra,56(sp)
    80004c54:	7442                	ld	s0,48(sp)
    80004c56:	74a2                	ld	s1,40(sp)
    80004c58:	7902                	ld	s2,32(sp)
    80004c5a:	69e2                	ld	s3,24(sp)
    80004c5c:	6a42                	ld	s4,16(sp)
    80004c5e:	6aa2                	ld	s5,8(sp)
    80004c60:	6121                	addi	sp,sp,64
    80004c62:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c64:	85d6                	mv	a1,s5
    80004c66:	8552                	mv	a0,s4
    80004c68:	00000097          	auipc	ra,0x0
    80004c6c:	34c080e7          	jalr	844(ra) # 80004fb4 <pipeclose>
    80004c70:	b7cd                	j	80004c52 <fileclose+0xa8>

0000000080004c72 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c72:	715d                	addi	sp,sp,-80
    80004c74:	e486                	sd	ra,72(sp)
    80004c76:	e0a2                	sd	s0,64(sp)
    80004c78:	fc26                	sd	s1,56(sp)
    80004c7a:	f84a                	sd	s2,48(sp)
    80004c7c:	f44e                	sd	s3,40(sp)
    80004c7e:	0880                	addi	s0,sp,80
    80004c80:	84aa                	mv	s1,a0
    80004c82:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c84:	ffffd097          	auipc	ra,0xffffd
    80004c88:	0b0080e7          	jalr	176(ra) # 80001d34 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c8c:	409c                	lw	a5,0(s1)
    80004c8e:	37f9                	addiw	a5,a5,-2
    80004c90:	4705                	li	a4,1
    80004c92:	04f76763          	bltu	a4,a5,80004ce0 <filestat+0x6e>
    80004c96:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c98:	6c88                	ld	a0,24(s1)
    80004c9a:	fffff097          	auipc	ra,0xfffff
    80004c9e:	072080e7          	jalr	114(ra) # 80003d0c <ilock>
    stati(f->ip, &st);
    80004ca2:	fb840593          	addi	a1,s0,-72
    80004ca6:	6c88                	ld	a0,24(s1)
    80004ca8:	fffff097          	auipc	ra,0xfffff
    80004cac:	2ee080e7          	jalr	750(ra) # 80003f96 <stati>
    iunlock(f->ip);
    80004cb0:	6c88                	ld	a0,24(s1)
    80004cb2:	fffff097          	auipc	ra,0xfffff
    80004cb6:	11c080e7          	jalr	284(ra) # 80003dce <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cba:	46e1                	li	a3,24
    80004cbc:	fb840613          	addi	a2,s0,-72
    80004cc0:	85ce                	mv	a1,s3
    80004cc2:	05093503          	ld	a0,80(s2)
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	9ac080e7          	jalr	-1620(ra) # 80001672 <copyout>
    80004cce:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004cd2:	60a6                	ld	ra,72(sp)
    80004cd4:	6406                	ld	s0,64(sp)
    80004cd6:	74e2                	ld	s1,56(sp)
    80004cd8:	7942                	ld	s2,48(sp)
    80004cda:	79a2                	ld	s3,40(sp)
    80004cdc:	6161                	addi	sp,sp,80
    80004cde:	8082                	ret
  return -1;
    80004ce0:	557d                	li	a0,-1
    80004ce2:	bfc5                	j	80004cd2 <filestat+0x60>

0000000080004ce4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ce4:	7179                	addi	sp,sp,-48
    80004ce6:	f406                	sd	ra,40(sp)
    80004ce8:	f022                	sd	s0,32(sp)
    80004cea:	ec26                	sd	s1,24(sp)
    80004cec:	e84a                	sd	s2,16(sp)
    80004cee:	e44e                	sd	s3,8(sp)
    80004cf0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004cf2:	00854783          	lbu	a5,8(a0)
    80004cf6:	c3d5                	beqz	a5,80004d9a <fileread+0xb6>
    80004cf8:	84aa                	mv	s1,a0
    80004cfa:	89ae                	mv	s3,a1
    80004cfc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cfe:	411c                	lw	a5,0(a0)
    80004d00:	4705                	li	a4,1
    80004d02:	04e78963          	beq	a5,a4,80004d54 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d06:	470d                	li	a4,3
    80004d08:	04e78d63          	beq	a5,a4,80004d62 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d0c:	4709                	li	a4,2
    80004d0e:	06e79e63          	bne	a5,a4,80004d8a <fileread+0xa6>
    ilock(f->ip);
    80004d12:	6d08                	ld	a0,24(a0)
    80004d14:	fffff097          	auipc	ra,0xfffff
    80004d18:	ff8080e7          	jalr	-8(ra) # 80003d0c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d1c:	874a                	mv	a4,s2
    80004d1e:	5094                	lw	a3,32(s1)
    80004d20:	864e                	mv	a2,s3
    80004d22:	4585                	li	a1,1
    80004d24:	6c88                	ld	a0,24(s1)
    80004d26:	fffff097          	auipc	ra,0xfffff
    80004d2a:	29a080e7          	jalr	666(ra) # 80003fc0 <readi>
    80004d2e:	892a                	mv	s2,a0
    80004d30:	00a05563          	blez	a0,80004d3a <fileread+0x56>
      f->off += r;
    80004d34:	509c                	lw	a5,32(s1)
    80004d36:	9fa9                	addw	a5,a5,a0
    80004d38:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d3a:	6c88                	ld	a0,24(s1)
    80004d3c:	fffff097          	auipc	ra,0xfffff
    80004d40:	092080e7          	jalr	146(ra) # 80003dce <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d44:	854a                	mv	a0,s2
    80004d46:	70a2                	ld	ra,40(sp)
    80004d48:	7402                	ld	s0,32(sp)
    80004d4a:	64e2                	ld	s1,24(sp)
    80004d4c:	6942                	ld	s2,16(sp)
    80004d4e:	69a2                	ld	s3,8(sp)
    80004d50:	6145                	addi	sp,sp,48
    80004d52:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d54:	6908                	ld	a0,16(a0)
    80004d56:	00000097          	auipc	ra,0x0
    80004d5a:	3c8080e7          	jalr	968(ra) # 8000511e <piperead>
    80004d5e:	892a                	mv	s2,a0
    80004d60:	b7d5                	j	80004d44 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d62:	02451783          	lh	a5,36(a0)
    80004d66:	03079693          	slli	a3,a5,0x30
    80004d6a:	92c1                	srli	a3,a3,0x30
    80004d6c:	4725                	li	a4,9
    80004d6e:	02d76863          	bltu	a4,a3,80004d9e <fileread+0xba>
    80004d72:	0792                	slli	a5,a5,0x4
    80004d74:	0001d717          	auipc	a4,0x1d
    80004d78:	a6470713          	addi	a4,a4,-1436 # 800217d8 <devsw>
    80004d7c:	97ba                	add	a5,a5,a4
    80004d7e:	639c                	ld	a5,0(a5)
    80004d80:	c38d                	beqz	a5,80004da2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d82:	4505                	li	a0,1
    80004d84:	9782                	jalr	a5
    80004d86:	892a                	mv	s2,a0
    80004d88:	bf75                	j	80004d44 <fileread+0x60>
    panic("fileread");
    80004d8a:	00004517          	auipc	a0,0x4
    80004d8e:	afe50513          	addi	a0,a0,-1282 # 80008888 <syscalls+0x270>
    80004d92:	ffffb097          	auipc	ra,0xffffb
    80004d96:	7ac080e7          	jalr	1964(ra) # 8000053e <panic>
    return -1;
    80004d9a:	597d                	li	s2,-1
    80004d9c:	b765                	j	80004d44 <fileread+0x60>
      return -1;
    80004d9e:	597d                	li	s2,-1
    80004da0:	b755                	j	80004d44 <fileread+0x60>
    80004da2:	597d                	li	s2,-1
    80004da4:	b745                	j	80004d44 <fileread+0x60>

0000000080004da6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004da6:	715d                	addi	sp,sp,-80
    80004da8:	e486                	sd	ra,72(sp)
    80004daa:	e0a2                	sd	s0,64(sp)
    80004dac:	fc26                	sd	s1,56(sp)
    80004dae:	f84a                	sd	s2,48(sp)
    80004db0:	f44e                	sd	s3,40(sp)
    80004db2:	f052                	sd	s4,32(sp)
    80004db4:	ec56                	sd	s5,24(sp)
    80004db6:	e85a                	sd	s6,16(sp)
    80004db8:	e45e                	sd	s7,8(sp)
    80004dba:	e062                	sd	s8,0(sp)
    80004dbc:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004dbe:	00954783          	lbu	a5,9(a0)
    80004dc2:	10078663          	beqz	a5,80004ece <filewrite+0x128>
    80004dc6:	892a                	mv	s2,a0
    80004dc8:	8aae                	mv	s5,a1
    80004dca:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dcc:	411c                	lw	a5,0(a0)
    80004dce:	4705                	li	a4,1
    80004dd0:	02e78263          	beq	a5,a4,80004df4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dd4:	470d                	li	a4,3
    80004dd6:	02e78663          	beq	a5,a4,80004e02 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dda:	4709                	li	a4,2
    80004ddc:	0ee79163          	bne	a5,a4,80004ebe <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004de0:	0ac05d63          	blez	a2,80004e9a <filewrite+0xf4>
    int i = 0;
    80004de4:	4981                	li	s3,0
    80004de6:	6b05                	lui	s6,0x1
    80004de8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004dec:	6b85                	lui	s7,0x1
    80004dee:	c00b8b9b          	addiw	s7,s7,-1024
    80004df2:	a861                	j	80004e8a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004df4:	6908                	ld	a0,16(a0)
    80004df6:	00000097          	auipc	ra,0x0
    80004dfa:	22e080e7          	jalr	558(ra) # 80005024 <pipewrite>
    80004dfe:	8a2a                	mv	s4,a0
    80004e00:	a045                	j	80004ea0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e02:	02451783          	lh	a5,36(a0)
    80004e06:	03079693          	slli	a3,a5,0x30
    80004e0a:	92c1                	srli	a3,a3,0x30
    80004e0c:	4725                	li	a4,9
    80004e0e:	0cd76263          	bltu	a4,a3,80004ed2 <filewrite+0x12c>
    80004e12:	0792                	slli	a5,a5,0x4
    80004e14:	0001d717          	auipc	a4,0x1d
    80004e18:	9c470713          	addi	a4,a4,-1596 # 800217d8 <devsw>
    80004e1c:	97ba                	add	a5,a5,a4
    80004e1e:	679c                	ld	a5,8(a5)
    80004e20:	cbdd                	beqz	a5,80004ed6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e22:	4505                	li	a0,1
    80004e24:	9782                	jalr	a5
    80004e26:	8a2a                	mv	s4,a0
    80004e28:	a8a5                	j	80004ea0 <filewrite+0xfa>
    80004e2a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e2e:	00000097          	auipc	ra,0x0
    80004e32:	8b0080e7          	jalr	-1872(ra) # 800046de <begin_op>
      ilock(f->ip);
    80004e36:	01893503          	ld	a0,24(s2)
    80004e3a:	fffff097          	auipc	ra,0xfffff
    80004e3e:	ed2080e7          	jalr	-302(ra) # 80003d0c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e42:	8762                	mv	a4,s8
    80004e44:	02092683          	lw	a3,32(s2)
    80004e48:	01598633          	add	a2,s3,s5
    80004e4c:	4585                	li	a1,1
    80004e4e:	01893503          	ld	a0,24(s2)
    80004e52:	fffff097          	auipc	ra,0xfffff
    80004e56:	266080e7          	jalr	614(ra) # 800040b8 <writei>
    80004e5a:	84aa                	mv	s1,a0
    80004e5c:	00a05763          	blez	a0,80004e6a <filewrite+0xc4>
        f->off += r;
    80004e60:	02092783          	lw	a5,32(s2)
    80004e64:	9fa9                	addw	a5,a5,a0
    80004e66:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e6a:	01893503          	ld	a0,24(s2)
    80004e6e:	fffff097          	auipc	ra,0xfffff
    80004e72:	f60080e7          	jalr	-160(ra) # 80003dce <iunlock>
      end_op();
    80004e76:	00000097          	auipc	ra,0x0
    80004e7a:	8e8080e7          	jalr	-1816(ra) # 8000475e <end_op>

      if(r != n1){
    80004e7e:	009c1f63          	bne	s8,s1,80004e9c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e82:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e86:	0149db63          	bge	s3,s4,80004e9c <filewrite+0xf6>
      int n1 = n - i;
    80004e8a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e8e:	84be                	mv	s1,a5
    80004e90:	2781                	sext.w	a5,a5
    80004e92:	f8fb5ce3          	bge	s6,a5,80004e2a <filewrite+0x84>
    80004e96:	84de                	mv	s1,s7
    80004e98:	bf49                	j	80004e2a <filewrite+0x84>
    int i = 0;
    80004e9a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e9c:	013a1f63          	bne	s4,s3,80004eba <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ea0:	8552                	mv	a0,s4
    80004ea2:	60a6                	ld	ra,72(sp)
    80004ea4:	6406                	ld	s0,64(sp)
    80004ea6:	74e2                	ld	s1,56(sp)
    80004ea8:	7942                	ld	s2,48(sp)
    80004eaa:	79a2                	ld	s3,40(sp)
    80004eac:	7a02                	ld	s4,32(sp)
    80004eae:	6ae2                	ld	s5,24(sp)
    80004eb0:	6b42                	ld	s6,16(sp)
    80004eb2:	6ba2                	ld	s7,8(sp)
    80004eb4:	6c02                	ld	s8,0(sp)
    80004eb6:	6161                	addi	sp,sp,80
    80004eb8:	8082                	ret
    ret = (i == n ? n : -1);
    80004eba:	5a7d                	li	s4,-1
    80004ebc:	b7d5                	j	80004ea0 <filewrite+0xfa>
    panic("filewrite");
    80004ebe:	00004517          	auipc	a0,0x4
    80004ec2:	9da50513          	addi	a0,a0,-1574 # 80008898 <syscalls+0x280>
    80004ec6:	ffffb097          	auipc	ra,0xffffb
    80004eca:	678080e7          	jalr	1656(ra) # 8000053e <panic>
    return -1;
    80004ece:	5a7d                	li	s4,-1
    80004ed0:	bfc1                	j	80004ea0 <filewrite+0xfa>
      return -1;
    80004ed2:	5a7d                	li	s4,-1
    80004ed4:	b7f1                	j	80004ea0 <filewrite+0xfa>
    80004ed6:	5a7d                	li	s4,-1
    80004ed8:	b7e1                	j	80004ea0 <filewrite+0xfa>

0000000080004eda <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004eda:	7179                	addi	sp,sp,-48
    80004edc:	f406                	sd	ra,40(sp)
    80004ede:	f022                	sd	s0,32(sp)
    80004ee0:	ec26                	sd	s1,24(sp)
    80004ee2:	e84a                	sd	s2,16(sp)
    80004ee4:	e44e                	sd	s3,8(sp)
    80004ee6:	e052                	sd	s4,0(sp)
    80004ee8:	1800                	addi	s0,sp,48
    80004eea:	84aa                	mv	s1,a0
    80004eec:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004eee:	0005b023          	sd	zero,0(a1)
    80004ef2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ef6:	00000097          	auipc	ra,0x0
    80004efa:	bf8080e7          	jalr	-1032(ra) # 80004aee <filealloc>
    80004efe:	e088                	sd	a0,0(s1)
    80004f00:	c551                	beqz	a0,80004f8c <pipealloc+0xb2>
    80004f02:	00000097          	auipc	ra,0x0
    80004f06:	bec080e7          	jalr	-1044(ra) # 80004aee <filealloc>
    80004f0a:	00aa3023          	sd	a0,0(s4)
    80004f0e:	c92d                	beqz	a0,80004f80 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f10:	ffffc097          	auipc	ra,0xffffc
    80004f14:	be4080e7          	jalr	-1052(ra) # 80000af4 <kalloc>
    80004f18:	892a                	mv	s2,a0
    80004f1a:	c125                	beqz	a0,80004f7a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f1c:	4985                	li	s3,1
    80004f1e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f22:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f26:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f2a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f2e:	00004597          	auipc	a1,0x4
    80004f32:	97a58593          	addi	a1,a1,-1670 # 800088a8 <syscalls+0x290>
    80004f36:	ffffc097          	auipc	ra,0xffffc
    80004f3a:	c1e080e7          	jalr	-994(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004f3e:	609c                	ld	a5,0(s1)
    80004f40:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f44:	609c                	ld	a5,0(s1)
    80004f46:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f4a:	609c                	ld	a5,0(s1)
    80004f4c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f50:	609c                	ld	a5,0(s1)
    80004f52:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f56:	000a3783          	ld	a5,0(s4)
    80004f5a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f5e:	000a3783          	ld	a5,0(s4)
    80004f62:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f66:	000a3783          	ld	a5,0(s4)
    80004f6a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f6e:	000a3783          	ld	a5,0(s4)
    80004f72:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f76:	4501                	li	a0,0
    80004f78:	a025                	j	80004fa0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f7a:	6088                	ld	a0,0(s1)
    80004f7c:	e501                	bnez	a0,80004f84 <pipealloc+0xaa>
    80004f7e:	a039                	j	80004f8c <pipealloc+0xb2>
    80004f80:	6088                	ld	a0,0(s1)
    80004f82:	c51d                	beqz	a0,80004fb0 <pipealloc+0xd6>
    fileclose(*f0);
    80004f84:	00000097          	auipc	ra,0x0
    80004f88:	c26080e7          	jalr	-986(ra) # 80004baa <fileclose>
  if(*f1)
    80004f8c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f90:	557d                	li	a0,-1
  if(*f1)
    80004f92:	c799                	beqz	a5,80004fa0 <pipealloc+0xc6>
    fileclose(*f1);
    80004f94:	853e                	mv	a0,a5
    80004f96:	00000097          	auipc	ra,0x0
    80004f9a:	c14080e7          	jalr	-1004(ra) # 80004baa <fileclose>
  return -1;
    80004f9e:	557d                	li	a0,-1
}
    80004fa0:	70a2                	ld	ra,40(sp)
    80004fa2:	7402                	ld	s0,32(sp)
    80004fa4:	64e2                	ld	s1,24(sp)
    80004fa6:	6942                	ld	s2,16(sp)
    80004fa8:	69a2                	ld	s3,8(sp)
    80004faa:	6a02                	ld	s4,0(sp)
    80004fac:	6145                	addi	sp,sp,48
    80004fae:	8082                	ret
  return -1;
    80004fb0:	557d                	li	a0,-1
    80004fb2:	b7fd                	j	80004fa0 <pipealloc+0xc6>

0000000080004fb4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fb4:	1101                	addi	sp,sp,-32
    80004fb6:	ec06                	sd	ra,24(sp)
    80004fb8:	e822                	sd	s0,16(sp)
    80004fba:	e426                	sd	s1,8(sp)
    80004fbc:	e04a                	sd	s2,0(sp)
    80004fbe:	1000                	addi	s0,sp,32
    80004fc0:	84aa                	mv	s1,a0
    80004fc2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004fc4:	ffffc097          	auipc	ra,0xffffc
    80004fc8:	c20080e7          	jalr	-992(ra) # 80000be4 <acquire>
  if(writable){
    80004fcc:	02090d63          	beqz	s2,80005006 <pipeclose+0x52>
    pi->writeopen = 0;
    80004fd0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004fd4:	21848513          	addi	a0,s1,536
    80004fd8:	ffffe097          	auipc	ra,0xffffe
    80004fdc:	a00080e7          	jalr	-1536(ra) # 800029d8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004fe0:	2204b783          	ld	a5,544(s1)
    80004fe4:	eb95                	bnez	a5,80005018 <pipeclose+0x64>
    release(&pi->lock);
    80004fe6:	8526                	mv	a0,s1
    80004fe8:	ffffc097          	auipc	ra,0xffffc
    80004fec:	cb0080e7          	jalr	-848(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004ff0:	8526                	mv	a0,s1
    80004ff2:	ffffc097          	auipc	ra,0xffffc
    80004ff6:	a06080e7          	jalr	-1530(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004ffa:	60e2                	ld	ra,24(sp)
    80004ffc:	6442                	ld	s0,16(sp)
    80004ffe:	64a2                	ld	s1,8(sp)
    80005000:	6902                	ld	s2,0(sp)
    80005002:	6105                	addi	sp,sp,32
    80005004:	8082                	ret
    pi->readopen = 0;
    80005006:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000500a:	21c48513          	addi	a0,s1,540
    8000500e:	ffffe097          	auipc	ra,0xffffe
    80005012:	9ca080e7          	jalr	-1590(ra) # 800029d8 <wakeup>
    80005016:	b7e9                	j	80004fe0 <pipeclose+0x2c>
    release(&pi->lock);
    80005018:	8526                	mv	a0,s1
    8000501a:	ffffc097          	auipc	ra,0xffffc
    8000501e:	c7e080e7          	jalr	-898(ra) # 80000c98 <release>
}
    80005022:	bfe1                	j	80004ffa <pipeclose+0x46>

0000000080005024 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005024:	7159                	addi	sp,sp,-112
    80005026:	f486                	sd	ra,104(sp)
    80005028:	f0a2                	sd	s0,96(sp)
    8000502a:	eca6                	sd	s1,88(sp)
    8000502c:	e8ca                	sd	s2,80(sp)
    8000502e:	e4ce                	sd	s3,72(sp)
    80005030:	e0d2                	sd	s4,64(sp)
    80005032:	fc56                	sd	s5,56(sp)
    80005034:	f85a                	sd	s6,48(sp)
    80005036:	f45e                	sd	s7,40(sp)
    80005038:	f062                	sd	s8,32(sp)
    8000503a:	ec66                	sd	s9,24(sp)
    8000503c:	1880                	addi	s0,sp,112
    8000503e:	84aa                	mv	s1,a0
    80005040:	8aae                	mv	s5,a1
    80005042:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005044:	ffffd097          	auipc	ra,0xffffd
    80005048:	cf0080e7          	jalr	-784(ra) # 80001d34 <myproc>
    8000504c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000504e:	8526                	mv	a0,s1
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	b94080e7          	jalr	-1132(ra) # 80000be4 <acquire>
  while(i < n){
    80005058:	0d405163          	blez	s4,8000511a <pipewrite+0xf6>
    8000505c:	8ba6                	mv	s7,s1
  int i = 0;
    8000505e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005060:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005062:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005066:	21c48c13          	addi	s8,s1,540
    8000506a:	a08d                	j	800050cc <pipewrite+0xa8>
      release(&pi->lock);
    8000506c:	8526                	mv	a0,s1
    8000506e:	ffffc097          	auipc	ra,0xffffc
    80005072:	c2a080e7          	jalr	-982(ra) # 80000c98 <release>
      return -1;
    80005076:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005078:	854a                	mv	a0,s2
    8000507a:	70a6                	ld	ra,104(sp)
    8000507c:	7406                	ld	s0,96(sp)
    8000507e:	64e6                	ld	s1,88(sp)
    80005080:	6946                	ld	s2,80(sp)
    80005082:	69a6                	ld	s3,72(sp)
    80005084:	6a06                	ld	s4,64(sp)
    80005086:	7ae2                	ld	s5,56(sp)
    80005088:	7b42                	ld	s6,48(sp)
    8000508a:	7ba2                	ld	s7,40(sp)
    8000508c:	7c02                	ld	s8,32(sp)
    8000508e:	6ce2                	ld	s9,24(sp)
    80005090:	6165                	addi	sp,sp,112
    80005092:	8082                	ret
      wakeup(&pi->nread);
    80005094:	8566                	mv	a0,s9
    80005096:	ffffe097          	auipc	ra,0xffffe
    8000509a:	942080e7          	jalr	-1726(ra) # 800029d8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000509e:	85de                	mv	a1,s7
    800050a0:	8562                	mv	a0,s8
    800050a2:	ffffd097          	auipc	ra,0xffffd
    800050a6:	320080e7          	jalr	800(ra) # 800023c2 <sleep>
    800050aa:	a839                	j	800050c8 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050ac:	21c4a783          	lw	a5,540(s1)
    800050b0:	0017871b          	addiw	a4,a5,1
    800050b4:	20e4ae23          	sw	a4,540(s1)
    800050b8:	1ff7f793          	andi	a5,a5,511
    800050bc:	97a6                	add	a5,a5,s1
    800050be:	f9f44703          	lbu	a4,-97(s0)
    800050c2:	00e78c23          	sb	a4,24(a5)
      i++;
    800050c6:	2905                	addiw	s2,s2,1
  while(i < n){
    800050c8:	03495d63          	bge	s2,s4,80005102 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800050cc:	2204a783          	lw	a5,544(s1)
    800050d0:	dfd1                	beqz	a5,8000506c <pipewrite+0x48>
    800050d2:	0289a783          	lw	a5,40(s3)
    800050d6:	fbd9                	bnez	a5,8000506c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050d8:	2184a783          	lw	a5,536(s1)
    800050dc:	21c4a703          	lw	a4,540(s1)
    800050e0:	2007879b          	addiw	a5,a5,512
    800050e4:	faf708e3          	beq	a4,a5,80005094 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050e8:	4685                	li	a3,1
    800050ea:	01590633          	add	a2,s2,s5
    800050ee:	f9f40593          	addi	a1,s0,-97
    800050f2:	0509b503          	ld	a0,80(s3)
    800050f6:	ffffc097          	auipc	ra,0xffffc
    800050fa:	608080e7          	jalr	1544(ra) # 800016fe <copyin>
    800050fe:	fb6517e3          	bne	a0,s6,800050ac <pipewrite+0x88>
  wakeup(&pi->nread);
    80005102:	21848513          	addi	a0,s1,536
    80005106:	ffffe097          	auipc	ra,0xffffe
    8000510a:	8d2080e7          	jalr	-1838(ra) # 800029d8 <wakeup>
  release(&pi->lock);
    8000510e:	8526                	mv	a0,s1
    80005110:	ffffc097          	auipc	ra,0xffffc
    80005114:	b88080e7          	jalr	-1144(ra) # 80000c98 <release>
  return i;
    80005118:	b785                	j	80005078 <pipewrite+0x54>
  int i = 0;
    8000511a:	4901                	li	s2,0
    8000511c:	b7dd                	j	80005102 <pipewrite+0xde>

000000008000511e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000511e:	715d                	addi	sp,sp,-80
    80005120:	e486                	sd	ra,72(sp)
    80005122:	e0a2                	sd	s0,64(sp)
    80005124:	fc26                	sd	s1,56(sp)
    80005126:	f84a                	sd	s2,48(sp)
    80005128:	f44e                	sd	s3,40(sp)
    8000512a:	f052                	sd	s4,32(sp)
    8000512c:	ec56                	sd	s5,24(sp)
    8000512e:	e85a                	sd	s6,16(sp)
    80005130:	0880                	addi	s0,sp,80
    80005132:	84aa                	mv	s1,a0
    80005134:	892e                	mv	s2,a1
    80005136:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005138:	ffffd097          	auipc	ra,0xffffd
    8000513c:	bfc080e7          	jalr	-1028(ra) # 80001d34 <myproc>
    80005140:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005142:	8b26                	mv	s6,s1
    80005144:	8526                	mv	a0,s1
    80005146:	ffffc097          	auipc	ra,0xffffc
    8000514a:	a9e080e7          	jalr	-1378(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000514e:	2184a703          	lw	a4,536(s1)
    80005152:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005156:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000515a:	02f71463          	bne	a4,a5,80005182 <piperead+0x64>
    8000515e:	2244a783          	lw	a5,548(s1)
    80005162:	c385                	beqz	a5,80005182 <piperead+0x64>
    if(pr->killed){
    80005164:	028a2783          	lw	a5,40(s4)
    80005168:	ebc1                	bnez	a5,800051f8 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000516a:	85da                	mv	a1,s6
    8000516c:	854e                	mv	a0,s3
    8000516e:	ffffd097          	auipc	ra,0xffffd
    80005172:	254080e7          	jalr	596(ra) # 800023c2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005176:	2184a703          	lw	a4,536(s1)
    8000517a:	21c4a783          	lw	a5,540(s1)
    8000517e:	fef700e3          	beq	a4,a5,8000515e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005182:	09505263          	blez	s5,80005206 <piperead+0xe8>
    80005186:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005188:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000518a:	2184a783          	lw	a5,536(s1)
    8000518e:	21c4a703          	lw	a4,540(s1)
    80005192:	02f70d63          	beq	a4,a5,800051cc <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005196:	0017871b          	addiw	a4,a5,1
    8000519a:	20e4ac23          	sw	a4,536(s1)
    8000519e:	1ff7f793          	andi	a5,a5,511
    800051a2:	97a6                	add	a5,a5,s1
    800051a4:	0187c783          	lbu	a5,24(a5)
    800051a8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051ac:	4685                	li	a3,1
    800051ae:	fbf40613          	addi	a2,s0,-65
    800051b2:	85ca                	mv	a1,s2
    800051b4:	050a3503          	ld	a0,80(s4)
    800051b8:	ffffc097          	auipc	ra,0xffffc
    800051bc:	4ba080e7          	jalr	1210(ra) # 80001672 <copyout>
    800051c0:	01650663          	beq	a0,s6,800051cc <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051c4:	2985                	addiw	s3,s3,1
    800051c6:	0905                	addi	s2,s2,1
    800051c8:	fd3a91e3          	bne	s5,s3,8000518a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051cc:	21c48513          	addi	a0,s1,540
    800051d0:	ffffe097          	auipc	ra,0xffffe
    800051d4:	808080e7          	jalr	-2040(ra) # 800029d8 <wakeup>
  release(&pi->lock);
    800051d8:	8526                	mv	a0,s1
    800051da:	ffffc097          	auipc	ra,0xffffc
    800051de:	abe080e7          	jalr	-1346(ra) # 80000c98 <release>
  return i;
}
    800051e2:	854e                	mv	a0,s3
    800051e4:	60a6                	ld	ra,72(sp)
    800051e6:	6406                	ld	s0,64(sp)
    800051e8:	74e2                	ld	s1,56(sp)
    800051ea:	7942                	ld	s2,48(sp)
    800051ec:	79a2                	ld	s3,40(sp)
    800051ee:	7a02                	ld	s4,32(sp)
    800051f0:	6ae2                	ld	s5,24(sp)
    800051f2:	6b42                	ld	s6,16(sp)
    800051f4:	6161                	addi	sp,sp,80
    800051f6:	8082                	ret
      release(&pi->lock);
    800051f8:	8526                	mv	a0,s1
    800051fa:	ffffc097          	auipc	ra,0xffffc
    800051fe:	a9e080e7          	jalr	-1378(ra) # 80000c98 <release>
      return -1;
    80005202:	59fd                	li	s3,-1
    80005204:	bff9                	j	800051e2 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005206:	4981                	li	s3,0
    80005208:	b7d1                	j	800051cc <piperead+0xae>

000000008000520a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000520a:	df010113          	addi	sp,sp,-528
    8000520e:	20113423          	sd	ra,520(sp)
    80005212:	20813023          	sd	s0,512(sp)
    80005216:	ffa6                	sd	s1,504(sp)
    80005218:	fbca                	sd	s2,496(sp)
    8000521a:	f7ce                	sd	s3,488(sp)
    8000521c:	f3d2                	sd	s4,480(sp)
    8000521e:	efd6                	sd	s5,472(sp)
    80005220:	ebda                	sd	s6,464(sp)
    80005222:	e7de                	sd	s7,456(sp)
    80005224:	e3e2                	sd	s8,448(sp)
    80005226:	ff66                	sd	s9,440(sp)
    80005228:	fb6a                	sd	s10,432(sp)
    8000522a:	f76e                	sd	s11,424(sp)
    8000522c:	0c00                	addi	s0,sp,528
    8000522e:	84aa                	mv	s1,a0
    80005230:	dea43c23          	sd	a0,-520(s0)
    80005234:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005238:	ffffd097          	auipc	ra,0xffffd
    8000523c:	afc080e7          	jalr	-1284(ra) # 80001d34 <myproc>
    80005240:	892a                	mv	s2,a0

  begin_op();
    80005242:	fffff097          	auipc	ra,0xfffff
    80005246:	49c080e7          	jalr	1180(ra) # 800046de <begin_op>

  if((ip = namei(path)) == 0){
    8000524a:	8526                	mv	a0,s1
    8000524c:	fffff097          	auipc	ra,0xfffff
    80005250:	276080e7          	jalr	630(ra) # 800044c2 <namei>
    80005254:	c92d                	beqz	a0,800052c6 <exec+0xbc>
    80005256:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005258:	fffff097          	auipc	ra,0xfffff
    8000525c:	ab4080e7          	jalr	-1356(ra) # 80003d0c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005260:	04000713          	li	a4,64
    80005264:	4681                	li	a3,0
    80005266:	e5040613          	addi	a2,s0,-432
    8000526a:	4581                	li	a1,0
    8000526c:	8526                	mv	a0,s1
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	d52080e7          	jalr	-686(ra) # 80003fc0 <readi>
    80005276:	04000793          	li	a5,64
    8000527a:	00f51a63          	bne	a0,a5,8000528e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000527e:	e5042703          	lw	a4,-432(s0)
    80005282:	464c47b7          	lui	a5,0x464c4
    80005286:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000528a:	04f70463          	beq	a4,a5,800052d2 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000528e:	8526                	mv	a0,s1
    80005290:	fffff097          	auipc	ra,0xfffff
    80005294:	cde080e7          	jalr	-802(ra) # 80003f6e <iunlockput>
    end_op();
    80005298:	fffff097          	auipc	ra,0xfffff
    8000529c:	4c6080e7          	jalr	1222(ra) # 8000475e <end_op>
  }
  return -1;
    800052a0:	557d                	li	a0,-1
}
    800052a2:	20813083          	ld	ra,520(sp)
    800052a6:	20013403          	ld	s0,512(sp)
    800052aa:	74fe                	ld	s1,504(sp)
    800052ac:	795e                	ld	s2,496(sp)
    800052ae:	79be                	ld	s3,488(sp)
    800052b0:	7a1e                	ld	s4,480(sp)
    800052b2:	6afe                	ld	s5,472(sp)
    800052b4:	6b5e                	ld	s6,464(sp)
    800052b6:	6bbe                	ld	s7,456(sp)
    800052b8:	6c1e                	ld	s8,448(sp)
    800052ba:	7cfa                	ld	s9,440(sp)
    800052bc:	7d5a                	ld	s10,432(sp)
    800052be:	7dba                	ld	s11,424(sp)
    800052c0:	21010113          	addi	sp,sp,528
    800052c4:	8082                	ret
    end_op();
    800052c6:	fffff097          	auipc	ra,0xfffff
    800052ca:	498080e7          	jalr	1176(ra) # 8000475e <end_op>
    return -1;
    800052ce:	557d                	li	a0,-1
    800052d0:	bfc9                	j	800052a2 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800052d2:	854a                	mv	a0,s2
    800052d4:	ffffd097          	auipc	ra,0xffffd
    800052d8:	b1e080e7          	jalr	-1250(ra) # 80001df2 <proc_pagetable>
    800052dc:	8baa                	mv	s7,a0
    800052de:	d945                	beqz	a0,8000528e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052e0:	e7042983          	lw	s3,-400(s0)
    800052e4:	e8845783          	lhu	a5,-376(s0)
    800052e8:	c7ad                	beqz	a5,80005352 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052ea:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052ec:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800052ee:	6c85                	lui	s9,0x1
    800052f0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800052f4:	def43823          	sd	a5,-528(s0)
    800052f8:	a42d                	j	80005522 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800052fa:	00003517          	auipc	a0,0x3
    800052fe:	5b650513          	addi	a0,a0,1462 # 800088b0 <syscalls+0x298>
    80005302:	ffffb097          	auipc	ra,0xffffb
    80005306:	23c080e7          	jalr	572(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000530a:	8756                	mv	a4,s5
    8000530c:	012d86bb          	addw	a3,s11,s2
    80005310:	4581                	li	a1,0
    80005312:	8526                	mv	a0,s1
    80005314:	fffff097          	auipc	ra,0xfffff
    80005318:	cac080e7          	jalr	-852(ra) # 80003fc0 <readi>
    8000531c:	2501                	sext.w	a0,a0
    8000531e:	1aaa9963          	bne	s5,a0,800054d0 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005322:	6785                	lui	a5,0x1
    80005324:	0127893b          	addw	s2,a5,s2
    80005328:	77fd                	lui	a5,0xfffff
    8000532a:	01478a3b          	addw	s4,a5,s4
    8000532e:	1f897163          	bgeu	s2,s8,80005510 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005332:	02091593          	slli	a1,s2,0x20
    80005336:	9181                	srli	a1,a1,0x20
    80005338:	95ea                	add	a1,a1,s10
    8000533a:	855e                	mv	a0,s7
    8000533c:	ffffc097          	auipc	ra,0xffffc
    80005340:	d32080e7          	jalr	-718(ra) # 8000106e <walkaddr>
    80005344:	862a                	mv	a2,a0
    if(pa == 0)
    80005346:	d955                	beqz	a0,800052fa <exec+0xf0>
      n = PGSIZE;
    80005348:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000534a:	fd9a70e3          	bgeu	s4,s9,8000530a <exec+0x100>
      n = sz - i;
    8000534e:	8ad2                	mv	s5,s4
    80005350:	bf6d                	j	8000530a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005352:	4901                	li	s2,0
  iunlockput(ip);
    80005354:	8526                	mv	a0,s1
    80005356:	fffff097          	auipc	ra,0xfffff
    8000535a:	c18080e7          	jalr	-1000(ra) # 80003f6e <iunlockput>
  end_op();
    8000535e:	fffff097          	auipc	ra,0xfffff
    80005362:	400080e7          	jalr	1024(ra) # 8000475e <end_op>
  p = myproc();
    80005366:	ffffd097          	auipc	ra,0xffffd
    8000536a:	9ce080e7          	jalr	-1586(ra) # 80001d34 <myproc>
    8000536e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005370:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005374:	6785                	lui	a5,0x1
    80005376:	17fd                	addi	a5,a5,-1
    80005378:	993e                	add	s2,s2,a5
    8000537a:	757d                	lui	a0,0xfffff
    8000537c:	00a977b3          	and	a5,s2,a0
    80005380:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005384:	6609                	lui	a2,0x2
    80005386:	963e                	add	a2,a2,a5
    80005388:	85be                	mv	a1,a5
    8000538a:	855e                	mv	a0,s7
    8000538c:	ffffc097          	auipc	ra,0xffffc
    80005390:	096080e7          	jalr	150(ra) # 80001422 <uvmalloc>
    80005394:	8b2a                	mv	s6,a0
  ip = 0;
    80005396:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005398:	12050c63          	beqz	a0,800054d0 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000539c:	75f9                	lui	a1,0xffffe
    8000539e:	95aa                	add	a1,a1,a0
    800053a0:	855e                	mv	a0,s7
    800053a2:	ffffc097          	auipc	ra,0xffffc
    800053a6:	29e080e7          	jalr	670(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800053aa:	7c7d                	lui	s8,0xfffff
    800053ac:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800053ae:	e0043783          	ld	a5,-512(s0)
    800053b2:	6388                	ld	a0,0(a5)
    800053b4:	c535                	beqz	a0,80005420 <exec+0x216>
    800053b6:	e9040993          	addi	s3,s0,-368
    800053ba:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800053be:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800053c0:	ffffc097          	auipc	ra,0xffffc
    800053c4:	aa4080e7          	jalr	-1372(ra) # 80000e64 <strlen>
    800053c8:	2505                	addiw	a0,a0,1
    800053ca:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053ce:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800053d2:	13896363          	bltu	s2,s8,800054f8 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800053d6:	e0043d83          	ld	s11,-512(s0)
    800053da:	000dba03          	ld	s4,0(s11)
    800053de:	8552                	mv	a0,s4
    800053e0:	ffffc097          	auipc	ra,0xffffc
    800053e4:	a84080e7          	jalr	-1404(ra) # 80000e64 <strlen>
    800053e8:	0015069b          	addiw	a3,a0,1
    800053ec:	8652                	mv	a2,s4
    800053ee:	85ca                	mv	a1,s2
    800053f0:	855e                	mv	a0,s7
    800053f2:	ffffc097          	auipc	ra,0xffffc
    800053f6:	280080e7          	jalr	640(ra) # 80001672 <copyout>
    800053fa:	10054363          	bltz	a0,80005500 <exec+0x2f6>
    ustack[argc] = sp;
    800053fe:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005402:	0485                	addi	s1,s1,1
    80005404:	008d8793          	addi	a5,s11,8
    80005408:	e0f43023          	sd	a5,-512(s0)
    8000540c:	008db503          	ld	a0,8(s11)
    80005410:	c911                	beqz	a0,80005424 <exec+0x21a>
    if(argc >= MAXARG)
    80005412:	09a1                	addi	s3,s3,8
    80005414:	fb3c96e3          	bne	s9,s3,800053c0 <exec+0x1b6>
  sz = sz1;
    80005418:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000541c:	4481                	li	s1,0
    8000541e:	a84d                	j	800054d0 <exec+0x2c6>
  sp = sz;
    80005420:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005422:	4481                	li	s1,0
  ustack[argc] = 0;
    80005424:	00349793          	slli	a5,s1,0x3
    80005428:	f9040713          	addi	a4,s0,-112
    8000542c:	97ba                	add	a5,a5,a4
    8000542e:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005432:	00148693          	addi	a3,s1,1
    80005436:	068e                	slli	a3,a3,0x3
    80005438:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000543c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005440:	01897663          	bgeu	s2,s8,8000544c <exec+0x242>
  sz = sz1;
    80005444:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005448:	4481                	li	s1,0
    8000544a:	a059                	j	800054d0 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000544c:	e9040613          	addi	a2,s0,-368
    80005450:	85ca                	mv	a1,s2
    80005452:	855e                	mv	a0,s7
    80005454:	ffffc097          	auipc	ra,0xffffc
    80005458:	21e080e7          	jalr	542(ra) # 80001672 <copyout>
    8000545c:	0a054663          	bltz	a0,80005508 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005460:	058ab783          	ld	a5,88(s5)
    80005464:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005468:	df843783          	ld	a5,-520(s0)
    8000546c:	0007c703          	lbu	a4,0(a5)
    80005470:	cf11                	beqz	a4,8000548c <exec+0x282>
    80005472:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005474:	02f00693          	li	a3,47
    80005478:	a039                	j	80005486 <exec+0x27c>
      last = s+1;
    8000547a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000547e:	0785                	addi	a5,a5,1
    80005480:	fff7c703          	lbu	a4,-1(a5)
    80005484:	c701                	beqz	a4,8000548c <exec+0x282>
    if(*s == '/')
    80005486:	fed71ce3          	bne	a4,a3,8000547e <exec+0x274>
    8000548a:	bfc5                	j	8000547a <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000548c:	4641                	li	a2,16
    8000548e:	df843583          	ld	a1,-520(s0)
    80005492:	158a8513          	addi	a0,s5,344
    80005496:	ffffc097          	auipc	ra,0xffffc
    8000549a:	99c080e7          	jalr	-1636(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000549e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800054a2:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800054a6:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054aa:	058ab783          	ld	a5,88(s5)
    800054ae:	e6843703          	ld	a4,-408(s0)
    800054b2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054b4:	058ab783          	ld	a5,88(s5)
    800054b8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054bc:	85ea                	mv	a1,s10
    800054be:	ffffd097          	auipc	ra,0xffffd
    800054c2:	9d0080e7          	jalr	-1584(ra) # 80001e8e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054c6:	0004851b          	sext.w	a0,s1
    800054ca:	bbe1                	j	800052a2 <exec+0x98>
    800054cc:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800054d0:	e0843583          	ld	a1,-504(s0)
    800054d4:	855e                	mv	a0,s7
    800054d6:	ffffd097          	auipc	ra,0xffffd
    800054da:	9b8080e7          	jalr	-1608(ra) # 80001e8e <proc_freepagetable>
  if(ip){
    800054de:	da0498e3          	bnez	s1,8000528e <exec+0x84>
  return -1;
    800054e2:	557d                	li	a0,-1
    800054e4:	bb7d                	j	800052a2 <exec+0x98>
    800054e6:	e1243423          	sd	s2,-504(s0)
    800054ea:	b7dd                	j	800054d0 <exec+0x2c6>
    800054ec:	e1243423          	sd	s2,-504(s0)
    800054f0:	b7c5                	j	800054d0 <exec+0x2c6>
    800054f2:	e1243423          	sd	s2,-504(s0)
    800054f6:	bfe9                	j	800054d0 <exec+0x2c6>
  sz = sz1;
    800054f8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054fc:	4481                	li	s1,0
    800054fe:	bfc9                	j	800054d0 <exec+0x2c6>
  sz = sz1;
    80005500:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005504:	4481                	li	s1,0
    80005506:	b7e9                	j	800054d0 <exec+0x2c6>
  sz = sz1;
    80005508:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000550c:	4481                	li	s1,0
    8000550e:	b7c9                	j	800054d0 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005510:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005514:	2b05                	addiw	s6,s6,1
    80005516:	0389899b          	addiw	s3,s3,56
    8000551a:	e8845783          	lhu	a5,-376(s0)
    8000551e:	e2fb5be3          	bge	s6,a5,80005354 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005522:	2981                	sext.w	s3,s3
    80005524:	03800713          	li	a4,56
    80005528:	86ce                	mv	a3,s3
    8000552a:	e1840613          	addi	a2,s0,-488
    8000552e:	4581                	li	a1,0
    80005530:	8526                	mv	a0,s1
    80005532:	fffff097          	auipc	ra,0xfffff
    80005536:	a8e080e7          	jalr	-1394(ra) # 80003fc0 <readi>
    8000553a:	03800793          	li	a5,56
    8000553e:	f8f517e3          	bne	a0,a5,800054cc <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005542:	e1842783          	lw	a5,-488(s0)
    80005546:	4705                	li	a4,1
    80005548:	fce796e3          	bne	a5,a4,80005514 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000554c:	e4043603          	ld	a2,-448(s0)
    80005550:	e3843783          	ld	a5,-456(s0)
    80005554:	f8f669e3          	bltu	a2,a5,800054e6 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005558:	e2843783          	ld	a5,-472(s0)
    8000555c:	963e                	add	a2,a2,a5
    8000555e:	f8f667e3          	bltu	a2,a5,800054ec <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005562:	85ca                	mv	a1,s2
    80005564:	855e                	mv	a0,s7
    80005566:	ffffc097          	auipc	ra,0xffffc
    8000556a:	ebc080e7          	jalr	-324(ra) # 80001422 <uvmalloc>
    8000556e:	e0a43423          	sd	a0,-504(s0)
    80005572:	d141                	beqz	a0,800054f2 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005574:	e2843d03          	ld	s10,-472(s0)
    80005578:	df043783          	ld	a5,-528(s0)
    8000557c:	00fd77b3          	and	a5,s10,a5
    80005580:	fba1                	bnez	a5,800054d0 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005582:	e2042d83          	lw	s11,-480(s0)
    80005586:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000558a:	f80c03e3          	beqz	s8,80005510 <exec+0x306>
    8000558e:	8a62                	mv	s4,s8
    80005590:	4901                	li	s2,0
    80005592:	b345                	j	80005332 <exec+0x128>

0000000080005594 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005594:	7179                	addi	sp,sp,-48
    80005596:	f406                	sd	ra,40(sp)
    80005598:	f022                	sd	s0,32(sp)
    8000559a:	ec26                	sd	s1,24(sp)
    8000559c:	e84a                	sd	s2,16(sp)
    8000559e:	1800                	addi	s0,sp,48
    800055a0:	892e                	mv	s2,a1
    800055a2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800055a4:	fdc40593          	addi	a1,s0,-36
    800055a8:	ffffe097          	auipc	ra,0xffffe
    800055ac:	b76080e7          	jalr	-1162(ra) # 8000311e <argint>
    800055b0:	04054063          	bltz	a0,800055f0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055b4:	fdc42703          	lw	a4,-36(s0)
    800055b8:	47bd                	li	a5,15
    800055ba:	02e7ed63          	bltu	a5,a4,800055f4 <argfd+0x60>
    800055be:	ffffc097          	auipc	ra,0xffffc
    800055c2:	776080e7          	jalr	1910(ra) # 80001d34 <myproc>
    800055c6:	fdc42703          	lw	a4,-36(s0)
    800055ca:	01a70793          	addi	a5,a4,26
    800055ce:	078e                	slli	a5,a5,0x3
    800055d0:	953e                	add	a0,a0,a5
    800055d2:	611c                	ld	a5,0(a0)
    800055d4:	c395                	beqz	a5,800055f8 <argfd+0x64>
    return -1;
  if(pfd)
    800055d6:	00090463          	beqz	s2,800055de <argfd+0x4a>
    *pfd = fd;
    800055da:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800055de:	4501                	li	a0,0
  if(pf)
    800055e0:	c091                	beqz	s1,800055e4 <argfd+0x50>
    *pf = f;
    800055e2:	e09c                	sd	a5,0(s1)
}
    800055e4:	70a2                	ld	ra,40(sp)
    800055e6:	7402                	ld	s0,32(sp)
    800055e8:	64e2                	ld	s1,24(sp)
    800055ea:	6942                	ld	s2,16(sp)
    800055ec:	6145                	addi	sp,sp,48
    800055ee:	8082                	ret
    return -1;
    800055f0:	557d                	li	a0,-1
    800055f2:	bfcd                	j	800055e4 <argfd+0x50>
    return -1;
    800055f4:	557d                	li	a0,-1
    800055f6:	b7fd                	j	800055e4 <argfd+0x50>
    800055f8:	557d                	li	a0,-1
    800055fa:	b7ed                	j	800055e4 <argfd+0x50>

00000000800055fc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800055fc:	1101                	addi	sp,sp,-32
    800055fe:	ec06                	sd	ra,24(sp)
    80005600:	e822                	sd	s0,16(sp)
    80005602:	e426                	sd	s1,8(sp)
    80005604:	1000                	addi	s0,sp,32
    80005606:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005608:	ffffc097          	auipc	ra,0xffffc
    8000560c:	72c080e7          	jalr	1836(ra) # 80001d34 <myproc>
    80005610:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005612:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005616:	4501                	li	a0,0
    80005618:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000561a:	6398                	ld	a4,0(a5)
    8000561c:	cb19                	beqz	a4,80005632 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000561e:	2505                	addiw	a0,a0,1
    80005620:	07a1                	addi	a5,a5,8
    80005622:	fed51ce3          	bne	a0,a3,8000561a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005626:	557d                	li	a0,-1
}
    80005628:	60e2                	ld	ra,24(sp)
    8000562a:	6442                	ld	s0,16(sp)
    8000562c:	64a2                	ld	s1,8(sp)
    8000562e:	6105                	addi	sp,sp,32
    80005630:	8082                	ret
      p->ofile[fd] = f;
    80005632:	01a50793          	addi	a5,a0,26
    80005636:	078e                	slli	a5,a5,0x3
    80005638:	963e                	add	a2,a2,a5
    8000563a:	e204                	sd	s1,0(a2)
      return fd;
    8000563c:	b7f5                	j	80005628 <fdalloc+0x2c>

000000008000563e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000563e:	715d                	addi	sp,sp,-80
    80005640:	e486                	sd	ra,72(sp)
    80005642:	e0a2                	sd	s0,64(sp)
    80005644:	fc26                	sd	s1,56(sp)
    80005646:	f84a                	sd	s2,48(sp)
    80005648:	f44e                	sd	s3,40(sp)
    8000564a:	f052                	sd	s4,32(sp)
    8000564c:	ec56                	sd	s5,24(sp)
    8000564e:	0880                	addi	s0,sp,80
    80005650:	89ae                	mv	s3,a1
    80005652:	8ab2                	mv	s5,a2
    80005654:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005656:	fb040593          	addi	a1,s0,-80
    8000565a:	fffff097          	auipc	ra,0xfffff
    8000565e:	e86080e7          	jalr	-378(ra) # 800044e0 <nameiparent>
    80005662:	892a                	mv	s2,a0
    80005664:	12050f63          	beqz	a0,800057a2 <create+0x164>
    return 0;

  ilock(dp);
    80005668:	ffffe097          	auipc	ra,0xffffe
    8000566c:	6a4080e7          	jalr	1700(ra) # 80003d0c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005670:	4601                	li	a2,0
    80005672:	fb040593          	addi	a1,s0,-80
    80005676:	854a                	mv	a0,s2
    80005678:	fffff097          	auipc	ra,0xfffff
    8000567c:	b78080e7          	jalr	-1160(ra) # 800041f0 <dirlookup>
    80005680:	84aa                	mv	s1,a0
    80005682:	c921                	beqz	a0,800056d2 <create+0x94>
    iunlockput(dp);
    80005684:	854a                	mv	a0,s2
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	8e8080e7          	jalr	-1816(ra) # 80003f6e <iunlockput>
    ilock(ip);
    8000568e:	8526                	mv	a0,s1
    80005690:	ffffe097          	auipc	ra,0xffffe
    80005694:	67c080e7          	jalr	1660(ra) # 80003d0c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005698:	2981                	sext.w	s3,s3
    8000569a:	4789                	li	a5,2
    8000569c:	02f99463          	bne	s3,a5,800056c4 <create+0x86>
    800056a0:	0444d783          	lhu	a5,68(s1)
    800056a4:	37f9                	addiw	a5,a5,-2
    800056a6:	17c2                	slli	a5,a5,0x30
    800056a8:	93c1                	srli	a5,a5,0x30
    800056aa:	4705                	li	a4,1
    800056ac:	00f76c63          	bltu	a4,a5,800056c4 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800056b0:	8526                	mv	a0,s1
    800056b2:	60a6                	ld	ra,72(sp)
    800056b4:	6406                	ld	s0,64(sp)
    800056b6:	74e2                	ld	s1,56(sp)
    800056b8:	7942                	ld	s2,48(sp)
    800056ba:	79a2                	ld	s3,40(sp)
    800056bc:	7a02                	ld	s4,32(sp)
    800056be:	6ae2                	ld	s5,24(sp)
    800056c0:	6161                	addi	sp,sp,80
    800056c2:	8082                	ret
    iunlockput(ip);
    800056c4:	8526                	mv	a0,s1
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	8a8080e7          	jalr	-1880(ra) # 80003f6e <iunlockput>
    return 0;
    800056ce:	4481                	li	s1,0
    800056d0:	b7c5                	j	800056b0 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800056d2:	85ce                	mv	a1,s3
    800056d4:	00092503          	lw	a0,0(s2)
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	49c080e7          	jalr	1180(ra) # 80003b74 <ialloc>
    800056e0:	84aa                	mv	s1,a0
    800056e2:	c529                	beqz	a0,8000572c <create+0xee>
  ilock(ip);
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	628080e7          	jalr	1576(ra) # 80003d0c <ilock>
  ip->major = major;
    800056ec:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800056f0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800056f4:	4785                	li	a5,1
    800056f6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056fa:	8526                	mv	a0,s1
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	546080e7          	jalr	1350(ra) # 80003c42 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005704:	2981                	sext.w	s3,s3
    80005706:	4785                	li	a5,1
    80005708:	02f98a63          	beq	s3,a5,8000573c <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000570c:	40d0                	lw	a2,4(s1)
    8000570e:	fb040593          	addi	a1,s0,-80
    80005712:	854a                	mv	a0,s2
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	cec080e7          	jalr	-788(ra) # 80004400 <dirlink>
    8000571c:	06054b63          	bltz	a0,80005792 <create+0x154>
  iunlockput(dp);
    80005720:	854a                	mv	a0,s2
    80005722:	fffff097          	auipc	ra,0xfffff
    80005726:	84c080e7          	jalr	-1972(ra) # 80003f6e <iunlockput>
  return ip;
    8000572a:	b759                	j	800056b0 <create+0x72>
    panic("create: ialloc");
    8000572c:	00003517          	auipc	a0,0x3
    80005730:	1a450513          	addi	a0,a0,420 # 800088d0 <syscalls+0x2b8>
    80005734:	ffffb097          	auipc	ra,0xffffb
    80005738:	e0a080e7          	jalr	-502(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000573c:	04a95783          	lhu	a5,74(s2)
    80005740:	2785                	addiw	a5,a5,1
    80005742:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005746:	854a                	mv	a0,s2
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	4fa080e7          	jalr	1274(ra) # 80003c42 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005750:	40d0                	lw	a2,4(s1)
    80005752:	00003597          	auipc	a1,0x3
    80005756:	18e58593          	addi	a1,a1,398 # 800088e0 <syscalls+0x2c8>
    8000575a:	8526                	mv	a0,s1
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	ca4080e7          	jalr	-860(ra) # 80004400 <dirlink>
    80005764:	00054f63          	bltz	a0,80005782 <create+0x144>
    80005768:	00492603          	lw	a2,4(s2)
    8000576c:	00003597          	auipc	a1,0x3
    80005770:	17c58593          	addi	a1,a1,380 # 800088e8 <syscalls+0x2d0>
    80005774:	8526                	mv	a0,s1
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	c8a080e7          	jalr	-886(ra) # 80004400 <dirlink>
    8000577e:	f80557e3          	bgez	a0,8000570c <create+0xce>
      panic("create dots");
    80005782:	00003517          	auipc	a0,0x3
    80005786:	16e50513          	addi	a0,a0,366 # 800088f0 <syscalls+0x2d8>
    8000578a:	ffffb097          	auipc	ra,0xffffb
    8000578e:	db4080e7          	jalr	-588(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005792:	00003517          	auipc	a0,0x3
    80005796:	16e50513          	addi	a0,a0,366 # 80008900 <syscalls+0x2e8>
    8000579a:	ffffb097          	auipc	ra,0xffffb
    8000579e:	da4080e7          	jalr	-604(ra) # 8000053e <panic>
    return 0;
    800057a2:	84aa                	mv	s1,a0
    800057a4:	b731                	j	800056b0 <create+0x72>

00000000800057a6 <sys_dup>:
{
    800057a6:	7179                	addi	sp,sp,-48
    800057a8:	f406                	sd	ra,40(sp)
    800057aa:	f022                	sd	s0,32(sp)
    800057ac:	ec26                	sd	s1,24(sp)
    800057ae:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057b0:	fd840613          	addi	a2,s0,-40
    800057b4:	4581                	li	a1,0
    800057b6:	4501                	li	a0,0
    800057b8:	00000097          	auipc	ra,0x0
    800057bc:	ddc080e7          	jalr	-548(ra) # 80005594 <argfd>
    return -1;
    800057c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800057c2:	02054363          	bltz	a0,800057e8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800057c6:	fd843503          	ld	a0,-40(s0)
    800057ca:	00000097          	auipc	ra,0x0
    800057ce:	e32080e7          	jalr	-462(ra) # 800055fc <fdalloc>
    800057d2:	84aa                	mv	s1,a0
    return -1;
    800057d4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800057d6:	00054963          	bltz	a0,800057e8 <sys_dup+0x42>
  filedup(f);
    800057da:	fd843503          	ld	a0,-40(s0)
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	37a080e7          	jalr	890(ra) # 80004b58 <filedup>
  return fd;
    800057e6:	87a6                	mv	a5,s1
}
    800057e8:	853e                	mv	a0,a5
    800057ea:	70a2                	ld	ra,40(sp)
    800057ec:	7402                	ld	s0,32(sp)
    800057ee:	64e2                	ld	s1,24(sp)
    800057f0:	6145                	addi	sp,sp,48
    800057f2:	8082                	ret

00000000800057f4 <sys_read>:
{
    800057f4:	7179                	addi	sp,sp,-48
    800057f6:	f406                	sd	ra,40(sp)
    800057f8:	f022                	sd	s0,32(sp)
    800057fa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057fc:	fe840613          	addi	a2,s0,-24
    80005800:	4581                	li	a1,0
    80005802:	4501                	li	a0,0
    80005804:	00000097          	auipc	ra,0x0
    80005808:	d90080e7          	jalr	-624(ra) # 80005594 <argfd>
    return -1;
    8000580c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000580e:	04054163          	bltz	a0,80005850 <sys_read+0x5c>
    80005812:	fe440593          	addi	a1,s0,-28
    80005816:	4509                	li	a0,2
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	906080e7          	jalr	-1786(ra) # 8000311e <argint>
    return -1;
    80005820:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005822:	02054763          	bltz	a0,80005850 <sys_read+0x5c>
    80005826:	fd840593          	addi	a1,s0,-40
    8000582a:	4505                	li	a0,1
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	914080e7          	jalr	-1772(ra) # 80003140 <argaddr>
    return -1;
    80005834:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005836:	00054d63          	bltz	a0,80005850 <sys_read+0x5c>
  return fileread(f, p, n);
    8000583a:	fe442603          	lw	a2,-28(s0)
    8000583e:	fd843583          	ld	a1,-40(s0)
    80005842:	fe843503          	ld	a0,-24(s0)
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	49e080e7          	jalr	1182(ra) # 80004ce4 <fileread>
    8000584e:	87aa                	mv	a5,a0
}
    80005850:	853e                	mv	a0,a5
    80005852:	70a2                	ld	ra,40(sp)
    80005854:	7402                	ld	s0,32(sp)
    80005856:	6145                	addi	sp,sp,48
    80005858:	8082                	ret

000000008000585a <sys_write>:
{
    8000585a:	7179                	addi	sp,sp,-48
    8000585c:	f406                	sd	ra,40(sp)
    8000585e:	f022                	sd	s0,32(sp)
    80005860:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005862:	fe840613          	addi	a2,s0,-24
    80005866:	4581                	li	a1,0
    80005868:	4501                	li	a0,0
    8000586a:	00000097          	auipc	ra,0x0
    8000586e:	d2a080e7          	jalr	-726(ra) # 80005594 <argfd>
    return -1;
    80005872:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005874:	04054163          	bltz	a0,800058b6 <sys_write+0x5c>
    80005878:	fe440593          	addi	a1,s0,-28
    8000587c:	4509                	li	a0,2
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	8a0080e7          	jalr	-1888(ra) # 8000311e <argint>
    return -1;
    80005886:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005888:	02054763          	bltz	a0,800058b6 <sys_write+0x5c>
    8000588c:	fd840593          	addi	a1,s0,-40
    80005890:	4505                	li	a0,1
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	8ae080e7          	jalr	-1874(ra) # 80003140 <argaddr>
    return -1;
    8000589a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000589c:	00054d63          	bltz	a0,800058b6 <sys_write+0x5c>
  return filewrite(f, p, n);
    800058a0:	fe442603          	lw	a2,-28(s0)
    800058a4:	fd843583          	ld	a1,-40(s0)
    800058a8:	fe843503          	ld	a0,-24(s0)
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	4fa080e7          	jalr	1274(ra) # 80004da6 <filewrite>
    800058b4:	87aa                	mv	a5,a0
}
    800058b6:	853e                	mv	a0,a5
    800058b8:	70a2                	ld	ra,40(sp)
    800058ba:	7402                	ld	s0,32(sp)
    800058bc:	6145                	addi	sp,sp,48
    800058be:	8082                	ret

00000000800058c0 <sys_close>:
{
    800058c0:	1101                	addi	sp,sp,-32
    800058c2:	ec06                	sd	ra,24(sp)
    800058c4:	e822                	sd	s0,16(sp)
    800058c6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800058c8:	fe040613          	addi	a2,s0,-32
    800058cc:	fec40593          	addi	a1,s0,-20
    800058d0:	4501                	li	a0,0
    800058d2:	00000097          	auipc	ra,0x0
    800058d6:	cc2080e7          	jalr	-830(ra) # 80005594 <argfd>
    return -1;
    800058da:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800058dc:	02054463          	bltz	a0,80005904 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800058e0:	ffffc097          	auipc	ra,0xffffc
    800058e4:	454080e7          	jalr	1108(ra) # 80001d34 <myproc>
    800058e8:	fec42783          	lw	a5,-20(s0)
    800058ec:	07e9                	addi	a5,a5,26
    800058ee:	078e                	slli	a5,a5,0x3
    800058f0:	97aa                	add	a5,a5,a0
    800058f2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800058f6:	fe043503          	ld	a0,-32(s0)
    800058fa:	fffff097          	auipc	ra,0xfffff
    800058fe:	2b0080e7          	jalr	688(ra) # 80004baa <fileclose>
  return 0;
    80005902:	4781                	li	a5,0
}
    80005904:	853e                	mv	a0,a5
    80005906:	60e2                	ld	ra,24(sp)
    80005908:	6442                	ld	s0,16(sp)
    8000590a:	6105                	addi	sp,sp,32
    8000590c:	8082                	ret

000000008000590e <sys_fstat>:
{
    8000590e:	1101                	addi	sp,sp,-32
    80005910:	ec06                	sd	ra,24(sp)
    80005912:	e822                	sd	s0,16(sp)
    80005914:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005916:	fe840613          	addi	a2,s0,-24
    8000591a:	4581                	li	a1,0
    8000591c:	4501                	li	a0,0
    8000591e:	00000097          	auipc	ra,0x0
    80005922:	c76080e7          	jalr	-906(ra) # 80005594 <argfd>
    return -1;
    80005926:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005928:	02054563          	bltz	a0,80005952 <sys_fstat+0x44>
    8000592c:	fe040593          	addi	a1,s0,-32
    80005930:	4505                	li	a0,1
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	80e080e7          	jalr	-2034(ra) # 80003140 <argaddr>
    return -1;
    8000593a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000593c:	00054b63          	bltz	a0,80005952 <sys_fstat+0x44>
  return filestat(f, st);
    80005940:	fe043583          	ld	a1,-32(s0)
    80005944:	fe843503          	ld	a0,-24(s0)
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	32a080e7          	jalr	810(ra) # 80004c72 <filestat>
    80005950:	87aa                	mv	a5,a0
}
    80005952:	853e                	mv	a0,a5
    80005954:	60e2                	ld	ra,24(sp)
    80005956:	6442                	ld	s0,16(sp)
    80005958:	6105                	addi	sp,sp,32
    8000595a:	8082                	ret

000000008000595c <sys_link>:
{
    8000595c:	7169                	addi	sp,sp,-304
    8000595e:	f606                	sd	ra,296(sp)
    80005960:	f222                	sd	s0,288(sp)
    80005962:	ee26                	sd	s1,280(sp)
    80005964:	ea4a                	sd	s2,272(sp)
    80005966:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005968:	08000613          	li	a2,128
    8000596c:	ed040593          	addi	a1,s0,-304
    80005970:	4501                	li	a0,0
    80005972:	ffffd097          	auipc	ra,0xffffd
    80005976:	7f0080e7          	jalr	2032(ra) # 80003162 <argstr>
    return -1;
    8000597a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000597c:	10054e63          	bltz	a0,80005a98 <sys_link+0x13c>
    80005980:	08000613          	li	a2,128
    80005984:	f5040593          	addi	a1,s0,-176
    80005988:	4505                	li	a0,1
    8000598a:	ffffd097          	auipc	ra,0xffffd
    8000598e:	7d8080e7          	jalr	2008(ra) # 80003162 <argstr>
    return -1;
    80005992:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005994:	10054263          	bltz	a0,80005a98 <sys_link+0x13c>
  begin_op();
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	d46080e7          	jalr	-698(ra) # 800046de <begin_op>
  if((ip = namei(old)) == 0){
    800059a0:	ed040513          	addi	a0,s0,-304
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	b1e080e7          	jalr	-1250(ra) # 800044c2 <namei>
    800059ac:	84aa                	mv	s1,a0
    800059ae:	c551                	beqz	a0,80005a3a <sys_link+0xde>
  ilock(ip);
    800059b0:	ffffe097          	auipc	ra,0xffffe
    800059b4:	35c080e7          	jalr	860(ra) # 80003d0c <ilock>
  if(ip->type == T_DIR){
    800059b8:	04449703          	lh	a4,68(s1)
    800059bc:	4785                	li	a5,1
    800059be:	08f70463          	beq	a4,a5,80005a46 <sys_link+0xea>
  ip->nlink++;
    800059c2:	04a4d783          	lhu	a5,74(s1)
    800059c6:	2785                	addiw	a5,a5,1
    800059c8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059cc:	8526                	mv	a0,s1
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	274080e7          	jalr	628(ra) # 80003c42 <iupdate>
  iunlock(ip);
    800059d6:	8526                	mv	a0,s1
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	3f6080e7          	jalr	1014(ra) # 80003dce <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800059e0:	fd040593          	addi	a1,s0,-48
    800059e4:	f5040513          	addi	a0,s0,-176
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	af8080e7          	jalr	-1288(ra) # 800044e0 <nameiparent>
    800059f0:	892a                	mv	s2,a0
    800059f2:	c935                	beqz	a0,80005a66 <sys_link+0x10a>
  ilock(dp);
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	318080e7          	jalr	792(ra) # 80003d0c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800059fc:	00092703          	lw	a4,0(s2)
    80005a00:	409c                	lw	a5,0(s1)
    80005a02:	04f71d63          	bne	a4,a5,80005a5c <sys_link+0x100>
    80005a06:	40d0                	lw	a2,4(s1)
    80005a08:	fd040593          	addi	a1,s0,-48
    80005a0c:	854a                	mv	a0,s2
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	9f2080e7          	jalr	-1550(ra) # 80004400 <dirlink>
    80005a16:	04054363          	bltz	a0,80005a5c <sys_link+0x100>
  iunlockput(dp);
    80005a1a:	854a                	mv	a0,s2
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	552080e7          	jalr	1362(ra) # 80003f6e <iunlockput>
  iput(ip);
    80005a24:	8526                	mv	a0,s1
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	4a0080e7          	jalr	1184(ra) # 80003ec6 <iput>
  end_op();
    80005a2e:	fffff097          	auipc	ra,0xfffff
    80005a32:	d30080e7          	jalr	-720(ra) # 8000475e <end_op>
  return 0;
    80005a36:	4781                	li	a5,0
    80005a38:	a085                	j	80005a98 <sys_link+0x13c>
    end_op();
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	d24080e7          	jalr	-732(ra) # 8000475e <end_op>
    return -1;
    80005a42:	57fd                	li	a5,-1
    80005a44:	a891                	j	80005a98 <sys_link+0x13c>
    iunlockput(ip);
    80005a46:	8526                	mv	a0,s1
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	526080e7          	jalr	1318(ra) # 80003f6e <iunlockput>
    end_op();
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	d0e080e7          	jalr	-754(ra) # 8000475e <end_op>
    return -1;
    80005a58:	57fd                	li	a5,-1
    80005a5a:	a83d                	j	80005a98 <sys_link+0x13c>
    iunlockput(dp);
    80005a5c:	854a                	mv	a0,s2
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	510080e7          	jalr	1296(ra) # 80003f6e <iunlockput>
  ilock(ip);
    80005a66:	8526                	mv	a0,s1
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	2a4080e7          	jalr	676(ra) # 80003d0c <ilock>
  ip->nlink--;
    80005a70:	04a4d783          	lhu	a5,74(s1)
    80005a74:	37fd                	addiw	a5,a5,-1
    80005a76:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a7a:	8526                	mv	a0,s1
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	1c6080e7          	jalr	454(ra) # 80003c42 <iupdate>
  iunlockput(ip);
    80005a84:	8526                	mv	a0,s1
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	4e8080e7          	jalr	1256(ra) # 80003f6e <iunlockput>
  end_op();
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	cd0080e7          	jalr	-816(ra) # 8000475e <end_op>
  return -1;
    80005a96:	57fd                	li	a5,-1
}
    80005a98:	853e                	mv	a0,a5
    80005a9a:	70b2                	ld	ra,296(sp)
    80005a9c:	7412                	ld	s0,288(sp)
    80005a9e:	64f2                	ld	s1,280(sp)
    80005aa0:	6952                	ld	s2,272(sp)
    80005aa2:	6155                	addi	sp,sp,304
    80005aa4:	8082                	ret

0000000080005aa6 <sys_unlink>:
{
    80005aa6:	7151                	addi	sp,sp,-240
    80005aa8:	f586                	sd	ra,232(sp)
    80005aaa:	f1a2                	sd	s0,224(sp)
    80005aac:	eda6                	sd	s1,216(sp)
    80005aae:	e9ca                	sd	s2,208(sp)
    80005ab0:	e5ce                	sd	s3,200(sp)
    80005ab2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005ab4:	08000613          	li	a2,128
    80005ab8:	f3040593          	addi	a1,s0,-208
    80005abc:	4501                	li	a0,0
    80005abe:	ffffd097          	auipc	ra,0xffffd
    80005ac2:	6a4080e7          	jalr	1700(ra) # 80003162 <argstr>
    80005ac6:	18054163          	bltz	a0,80005c48 <sys_unlink+0x1a2>
  begin_op();
    80005aca:	fffff097          	auipc	ra,0xfffff
    80005ace:	c14080e7          	jalr	-1004(ra) # 800046de <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005ad2:	fb040593          	addi	a1,s0,-80
    80005ad6:	f3040513          	addi	a0,s0,-208
    80005ada:	fffff097          	auipc	ra,0xfffff
    80005ade:	a06080e7          	jalr	-1530(ra) # 800044e0 <nameiparent>
    80005ae2:	84aa                	mv	s1,a0
    80005ae4:	c979                	beqz	a0,80005bba <sys_unlink+0x114>
  ilock(dp);
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	226080e7          	jalr	550(ra) # 80003d0c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005aee:	00003597          	auipc	a1,0x3
    80005af2:	df258593          	addi	a1,a1,-526 # 800088e0 <syscalls+0x2c8>
    80005af6:	fb040513          	addi	a0,s0,-80
    80005afa:	ffffe097          	auipc	ra,0xffffe
    80005afe:	6dc080e7          	jalr	1756(ra) # 800041d6 <namecmp>
    80005b02:	14050a63          	beqz	a0,80005c56 <sys_unlink+0x1b0>
    80005b06:	00003597          	auipc	a1,0x3
    80005b0a:	de258593          	addi	a1,a1,-542 # 800088e8 <syscalls+0x2d0>
    80005b0e:	fb040513          	addi	a0,s0,-80
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	6c4080e7          	jalr	1732(ra) # 800041d6 <namecmp>
    80005b1a:	12050e63          	beqz	a0,80005c56 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b1e:	f2c40613          	addi	a2,s0,-212
    80005b22:	fb040593          	addi	a1,s0,-80
    80005b26:	8526                	mv	a0,s1
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	6c8080e7          	jalr	1736(ra) # 800041f0 <dirlookup>
    80005b30:	892a                	mv	s2,a0
    80005b32:	12050263          	beqz	a0,80005c56 <sys_unlink+0x1b0>
  ilock(ip);
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	1d6080e7          	jalr	470(ra) # 80003d0c <ilock>
  if(ip->nlink < 1)
    80005b3e:	04a91783          	lh	a5,74(s2)
    80005b42:	08f05263          	blez	a5,80005bc6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b46:	04491703          	lh	a4,68(s2)
    80005b4a:	4785                	li	a5,1
    80005b4c:	08f70563          	beq	a4,a5,80005bd6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b50:	4641                	li	a2,16
    80005b52:	4581                	li	a1,0
    80005b54:	fc040513          	addi	a0,s0,-64
    80005b58:	ffffb097          	auipc	ra,0xffffb
    80005b5c:	188080e7          	jalr	392(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b60:	4741                	li	a4,16
    80005b62:	f2c42683          	lw	a3,-212(s0)
    80005b66:	fc040613          	addi	a2,s0,-64
    80005b6a:	4581                	li	a1,0
    80005b6c:	8526                	mv	a0,s1
    80005b6e:	ffffe097          	auipc	ra,0xffffe
    80005b72:	54a080e7          	jalr	1354(ra) # 800040b8 <writei>
    80005b76:	47c1                	li	a5,16
    80005b78:	0af51563          	bne	a0,a5,80005c22 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b7c:	04491703          	lh	a4,68(s2)
    80005b80:	4785                	li	a5,1
    80005b82:	0af70863          	beq	a4,a5,80005c32 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b86:	8526                	mv	a0,s1
    80005b88:	ffffe097          	auipc	ra,0xffffe
    80005b8c:	3e6080e7          	jalr	998(ra) # 80003f6e <iunlockput>
  ip->nlink--;
    80005b90:	04a95783          	lhu	a5,74(s2)
    80005b94:	37fd                	addiw	a5,a5,-1
    80005b96:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b9a:	854a                	mv	a0,s2
    80005b9c:	ffffe097          	auipc	ra,0xffffe
    80005ba0:	0a6080e7          	jalr	166(ra) # 80003c42 <iupdate>
  iunlockput(ip);
    80005ba4:	854a                	mv	a0,s2
    80005ba6:	ffffe097          	auipc	ra,0xffffe
    80005baa:	3c8080e7          	jalr	968(ra) # 80003f6e <iunlockput>
  end_op();
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	bb0080e7          	jalr	-1104(ra) # 8000475e <end_op>
  return 0;
    80005bb6:	4501                	li	a0,0
    80005bb8:	a84d                	j	80005c6a <sys_unlink+0x1c4>
    end_op();
    80005bba:	fffff097          	auipc	ra,0xfffff
    80005bbe:	ba4080e7          	jalr	-1116(ra) # 8000475e <end_op>
    return -1;
    80005bc2:	557d                	li	a0,-1
    80005bc4:	a05d                	j	80005c6a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005bc6:	00003517          	auipc	a0,0x3
    80005bca:	d4a50513          	addi	a0,a0,-694 # 80008910 <syscalls+0x2f8>
    80005bce:	ffffb097          	auipc	ra,0xffffb
    80005bd2:	970080e7          	jalr	-1680(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bd6:	04c92703          	lw	a4,76(s2)
    80005bda:	02000793          	li	a5,32
    80005bde:	f6e7f9e3          	bgeu	a5,a4,80005b50 <sys_unlink+0xaa>
    80005be2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005be6:	4741                	li	a4,16
    80005be8:	86ce                	mv	a3,s3
    80005bea:	f1840613          	addi	a2,s0,-232
    80005bee:	4581                	li	a1,0
    80005bf0:	854a                	mv	a0,s2
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	3ce080e7          	jalr	974(ra) # 80003fc0 <readi>
    80005bfa:	47c1                	li	a5,16
    80005bfc:	00f51b63          	bne	a0,a5,80005c12 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c00:	f1845783          	lhu	a5,-232(s0)
    80005c04:	e7a1                	bnez	a5,80005c4c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c06:	29c1                	addiw	s3,s3,16
    80005c08:	04c92783          	lw	a5,76(s2)
    80005c0c:	fcf9ede3          	bltu	s3,a5,80005be6 <sys_unlink+0x140>
    80005c10:	b781                	j	80005b50 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c12:	00003517          	auipc	a0,0x3
    80005c16:	d1650513          	addi	a0,a0,-746 # 80008928 <syscalls+0x310>
    80005c1a:	ffffb097          	auipc	ra,0xffffb
    80005c1e:	924080e7          	jalr	-1756(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005c22:	00003517          	auipc	a0,0x3
    80005c26:	d1e50513          	addi	a0,a0,-738 # 80008940 <syscalls+0x328>
    80005c2a:	ffffb097          	auipc	ra,0xffffb
    80005c2e:	914080e7          	jalr	-1772(ra) # 8000053e <panic>
    dp->nlink--;
    80005c32:	04a4d783          	lhu	a5,74(s1)
    80005c36:	37fd                	addiw	a5,a5,-1
    80005c38:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c3c:	8526                	mv	a0,s1
    80005c3e:	ffffe097          	auipc	ra,0xffffe
    80005c42:	004080e7          	jalr	4(ra) # 80003c42 <iupdate>
    80005c46:	b781                	j	80005b86 <sys_unlink+0xe0>
    return -1;
    80005c48:	557d                	li	a0,-1
    80005c4a:	a005                	j	80005c6a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c4c:	854a                	mv	a0,s2
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	320080e7          	jalr	800(ra) # 80003f6e <iunlockput>
  iunlockput(dp);
    80005c56:	8526                	mv	a0,s1
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	316080e7          	jalr	790(ra) # 80003f6e <iunlockput>
  end_op();
    80005c60:	fffff097          	auipc	ra,0xfffff
    80005c64:	afe080e7          	jalr	-1282(ra) # 8000475e <end_op>
  return -1;
    80005c68:	557d                	li	a0,-1
}
    80005c6a:	70ae                	ld	ra,232(sp)
    80005c6c:	740e                	ld	s0,224(sp)
    80005c6e:	64ee                	ld	s1,216(sp)
    80005c70:	694e                	ld	s2,208(sp)
    80005c72:	69ae                	ld	s3,200(sp)
    80005c74:	616d                	addi	sp,sp,240
    80005c76:	8082                	ret

0000000080005c78 <sys_open>:

uint64
sys_open(void)
{
    80005c78:	7131                	addi	sp,sp,-192
    80005c7a:	fd06                	sd	ra,184(sp)
    80005c7c:	f922                	sd	s0,176(sp)
    80005c7e:	f526                	sd	s1,168(sp)
    80005c80:	f14a                	sd	s2,160(sp)
    80005c82:	ed4e                	sd	s3,152(sp)
    80005c84:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c86:	08000613          	li	a2,128
    80005c8a:	f5040593          	addi	a1,s0,-176
    80005c8e:	4501                	li	a0,0
    80005c90:	ffffd097          	auipc	ra,0xffffd
    80005c94:	4d2080e7          	jalr	1234(ra) # 80003162 <argstr>
    return -1;
    80005c98:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c9a:	0c054163          	bltz	a0,80005d5c <sys_open+0xe4>
    80005c9e:	f4c40593          	addi	a1,s0,-180
    80005ca2:	4505                	li	a0,1
    80005ca4:	ffffd097          	auipc	ra,0xffffd
    80005ca8:	47a080e7          	jalr	1146(ra) # 8000311e <argint>
    80005cac:	0a054863          	bltz	a0,80005d5c <sys_open+0xe4>

  begin_op();
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	a2e080e7          	jalr	-1490(ra) # 800046de <begin_op>

  if(omode & O_CREATE){
    80005cb8:	f4c42783          	lw	a5,-180(s0)
    80005cbc:	2007f793          	andi	a5,a5,512
    80005cc0:	cbdd                	beqz	a5,80005d76 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005cc2:	4681                	li	a3,0
    80005cc4:	4601                	li	a2,0
    80005cc6:	4589                	li	a1,2
    80005cc8:	f5040513          	addi	a0,s0,-176
    80005ccc:	00000097          	auipc	ra,0x0
    80005cd0:	972080e7          	jalr	-1678(ra) # 8000563e <create>
    80005cd4:	892a                	mv	s2,a0
    if(ip == 0){
    80005cd6:	c959                	beqz	a0,80005d6c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005cd8:	04491703          	lh	a4,68(s2)
    80005cdc:	478d                	li	a5,3
    80005cde:	00f71763          	bne	a4,a5,80005cec <sys_open+0x74>
    80005ce2:	04695703          	lhu	a4,70(s2)
    80005ce6:	47a5                	li	a5,9
    80005ce8:	0ce7ec63          	bltu	a5,a4,80005dc0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005cec:	fffff097          	auipc	ra,0xfffff
    80005cf0:	e02080e7          	jalr	-510(ra) # 80004aee <filealloc>
    80005cf4:	89aa                	mv	s3,a0
    80005cf6:	10050263          	beqz	a0,80005dfa <sys_open+0x182>
    80005cfa:	00000097          	auipc	ra,0x0
    80005cfe:	902080e7          	jalr	-1790(ra) # 800055fc <fdalloc>
    80005d02:	84aa                	mv	s1,a0
    80005d04:	0e054663          	bltz	a0,80005df0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d08:	04491703          	lh	a4,68(s2)
    80005d0c:	478d                	li	a5,3
    80005d0e:	0cf70463          	beq	a4,a5,80005dd6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d12:	4789                	li	a5,2
    80005d14:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d18:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d1c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d20:	f4c42783          	lw	a5,-180(s0)
    80005d24:	0017c713          	xori	a4,a5,1
    80005d28:	8b05                	andi	a4,a4,1
    80005d2a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d2e:	0037f713          	andi	a4,a5,3
    80005d32:	00e03733          	snez	a4,a4
    80005d36:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d3a:	4007f793          	andi	a5,a5,1024
    80005d3e:	c791                	beqz	a5,80005d4a <sys_open+0xd2>
    80005d40:	04491703          	lh	a4,68(s2)
    80005d44:	4789                	li	a5,2
    80005d46:	08f70f63          	beq	a4,a5,80005de4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d4a:	854a                	mv	a0,s2
    80005d4c:	ffffe097          	auipc	ra,0xffffe
    80005d50:	082080e7          	jalr	130(ra) # 80003dce <iunlock>
  end_op();
    80005d54:	fffff097          	auipc	ra,0xfffff
    80005d58:	a0a080e7          	jalr	-1526(ra) # 8000475e <end_op>

  return fd;
}
    80005d5c:	8526                	mv	a0,s1
    80005d5e:	70ea                	ld	ra,184(sp)
    80005d60:	744a                	ld	s0,176(sp)
    80005d62:	74aa                	ld	s1,168(sp)
    80005d64:	790a                	ld	s2,160(sp)
    80005d66:	69ea                	ld	s3,152(sp)
    80005d68:	6129                	addi	sp,sp,192
    80005d6a:	8082                	ret
      end_op();
    80005d6c:	fffff097          	auipc	ra,0xfffff
    80005d70:	9f2080e7          	jalr	-1550(ra) # 8000475e <end_op>
      return -1;
    80005d74:	b7e5                	j	80005d5c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d76:	f5040513          	addi	a0,s0,-176
    80005d7a:	ffffe097          	auipc	ra,0xffffe
    80005d7e:	748080e7          	jalr	1864(ra) # 800044c2 <namei>
    80005d82:	892a                	mv	s2,a0
    80005d84:	c905                	beqz	a0,80005db4 <sys_open+0x13c>
    ilock(ip);
    80005d86:	ffffe097          	auipc	ra,0xffffe
    80005d8a:	f86080e7          	jalr	-122(ra) # 80003d0c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d8e:	04491703          	lh	a4,68(s2)
    80005d92:	4785                	li	a5,1
    80005d94:	f4f712e3          	bne	a4,a5,80005cd8 <sys_open+0x60>
    80005d98:	f4c42783          	lw	a5,-180(s0)
    80005d9c:	dba1                	beqz	a5,80005cec <sys_open+0x74>
      iunlockput(ip);
    80005d9e:	854a                	mv	a0,s2
    80005da0:	ffffe097          	auipc	ra,0xffffe
    80005da4:	1ce080e7          	jalr	462(ra) # 80003f6e <iunlockput>
      end_op();
    80005da8:	fffff097          	auipc	ra,0xfffff
    80005dac:	9b6080e7          	jalr	-1610(ra) # 8000475e <end_op>
      return -1;
    80005db0:	54fd                	li	s1,-1
    80005db2:	b76d                	j	80005d5c <sys_open+0xe4>
      end_op();
    80005db4:	fffff097          	auipc	ra,0xfffff
    80005db8:	9aa080e7          	jalr	-1622(ra) # 8000475e <end_op>
      return -1;
    80005dbc:	54fd                	li	s1,-1
    80005dbe:	bf79                	j	80005d5c <sys_open+0xe4>
    iunlockput(ip);
    80005dc0:	854a                	mv	a0,s2
    80005dc2:	ffffe097          	auipc	ra,0xffffe
    80005dc6:	1ac080e7          	jalr	428(ra) # 80003f6e <iunlockput>
    end_op();
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	994080e7          	jalr	-1644(ra) # 8000475e <end_op>
    return -1;
    80005dd2:	54fd                	li	s1,-1
    80005dd4:	b761                	j	80005d5c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005dd6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005dda:	04691783          	lh	a5,70(s2)
    80005dde:	02f99223          	sh	a5,36(s3)
    80005de2:	bf2d                	j	80005d1c <sys_open+0xa4>
    itrunc(ip);
    80005de4:	854a                	mv	a0,s2
    80005de6:	ffffe097          	auipc	ra,0xffffe
    80005dea:	034080e7          	jalr	52(ra) # 80003e1a <itrunc>
    80005dee:	bfb1                	j	80005d4a <sys_open+0xd2>
      fileclose(f);
    80005df0:	854e                	mv	a0,s3
    80005df2:	fffff097          	auipc	ra,0xfffff
    80005df6:	db8080e7          	jalr	-584(ra) # 80004baa <fileclose>
    iunlockput(ip);
    80005dfa:	854a                	mv	a0,s2
    80005dfc:	ffffe097          	auipc	ra,0xffffe
    80005e00:	172080e7          	jalr	370(ra) # 80003f6e <iunlockput>
    end_op();
    80005e04:	fffff097          	auipc	ra,0xfffff
    80005e08:	95a080e7          	jalr	-1702(ra) # 8000475e <end_op>
    return -1;
    80005e0c:	54fd                	li	s1,-1
    80005e0e:	b7b9                	j	80005d5c <sys_open+0xe4>

0000000080005e10 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e10:	7175                	addi	sp,sp,-144
    80005e12:	e506                	sd	ra,136(sp)
    80005e14:	e122                	sd	s0,128(sp)
    80005e16:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e18:	fffff097          	auipc	ra,0xfffff
    80005e1c:	8c6080e7          	jalr	-1850(ra) # 800046de <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e20:	08000613          	li	a2,128
    80005e24:	f7040593          	addi	a1,s0,-144
    80005e28:	4501                	li	a0,0
    80005e2a:	ffffd097          	auipc	ra,0xffffd
    80005e2e:	338080e7          	jalr	824(ra) # 80003162 <argstr>
    80005e32:	02054963          	bltz	a0,80005e64 <sys_mkdir+0x54>
    80005e36:	4681                	li	a3,0
    80005e38:	4601                	li	a2,0
    80005e3a:	4585                	li	a1,1
    80005e3c:	f7040513          	addi	a0,s0,-144
    80005e40:	fffff097          	auipc	ra,0xfffff
    80005e44:	7fe080e7          	jalr	2046(ra) # 8000563e <create>
    80005e48:	cd11                	beqz	a0,80005e64 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e4a:	ffffe097          	auipc	ra,0xffffe
    80005e4e:	124080e7          	jalr	292(ra) # 80003f6e <iunlockput>
  end_op();
    80005e52:	fffff097          	auipc	ra,0xfffff
    80005e56:	90c080e7          	jalr	-1780(ra) # 8000475e <end_op>
  return 0;
    80005e5a:	4501                	li	a0,0
}
    80005e5c:	60aa                	ld	ra,136(sp)
    80005e5e:	640a                	ld	s0,128(sp)
    80005e60:	6149                	addi	sp,sp,144
    80005e62:	8082                	ret
    end_op();
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	8fa080e7          	jalr	-1798(ra) # 8000475e <end_op>
    return -1;
    80005e6c:	557d                	li	a0,-1
    80005e6e:	b7fd                	j	80005e5c <sys_mkdir+0x4c>

0000000080005e70 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e70:	7135                	addi	sp,sp,-160
    80005e72:	ed06                	sd	ra,152(sp)
    80005e74:	e922                	sd	s0,144(sp)
    80005e76:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e78:	fffff097          	auipc	ra,0xfffff
    80005e7c:	866080e7          	jalr	-1946(ra) # 800046de <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e80:	08000613          	li	a2,128
    80005e84:	f7040593          	addi	a1,s0,-144
    80005e88:	4501                	li	a0,0
    80005e8a:	ffffd097          	auipc	ra,0xffffd
    80005e8e:	2d8080e7          	jalr	728(ra) # 80003162 <argstr>
    80005e92:	04054a63          	bltz	a0,80005ee6 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e96:	f6c40593          	addi	a1,s0,-148
    80005e9a:	4505                	li	a0,1
    80005e9c:	ffffd097          	auipc	ra,0xffffd
    80005ea0:	282080e7          	jalr	642(ra) # 8000311e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ea4:	04054163          	bltz	a0,80005ee6 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ea8:	f6840593          	addi	a1,s0,-152
    80005eac:	4509                	li	a0,2
    80005eae:	ffffd097          	auipc	ra,0xffffd
    80005eb2:	270080e7          	jalr	624(ra) # 8000311e <argint>
     argint(1, &major) < 0 ||
    80005eb6:	02054863          	bltz	a0,80005ee6 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005eba:	f6841683          	lh	a3,-152(s0)
    80005ebe:	f6c41603          	lh	a2,-148(s0)
    80005ec2:	458d                	li	a1,3
    80005ec4:	f7040513          	addi	a0,s0,-144
    80005ec8:	fffff097          	auipc	ra,0xfffff
    80005ecc:	776080e7          	jalr	1910(ra) # 8000563e <create>
     argint(2, &minor) < 0 ||
    80005ed0:	c919                	beqz	a0,80005ee6 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ed2:	ffffe097          	auipc	ra,0xffffe
    80005ed6:	09c080e7          	jalr	156(ra) # 80003f6e <iunlockput>
  end_op();
    80005eda:	fffff097          	auipc	ra,0xfffff
    80005ede:	884080e7          	jalr	-1916(ra) # 8000475e <end_op>
  return 0;
    80005ee2:	4501                	li	a0,0
    80005ee4:	a031                	j	80005ef0 <sys_mknod+0x80>
    end_op();
    80005ee6:	fffff097          	auipc	ra,0xfffff
    80005eea:	878080e7          	jalr	-1928(ra) # 8000475e <end_op>
    return -1;
    80005eee:	557d                	li	a0,-1
}
    80005ef0:	60ea                	ld	ra,152(sp)
    80005ef2:	644a                	ld	s0,144(sp)
    80005ef4:	610d                	addi	sp,sp,160
    80005ef6:	8082                	ret

0000000080005ef8 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ef8:	7135                	addi	sp,sp,-160
    80005efa:	ed06                	sd	ra,152(sp)
    80005efc:	e922                	sd	s0,144(sp)
    80005efe:	e526                	sd	s1,136(sp)
    80005f00:	e14a                	sd	s2,128(sp)
    80005f02:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f04:	ffffc097          	auipc	ra,0xffffc
    80005f08:	e30080e7          	jalr	-464(ra) # 80001d34 <myproc>
    80005f0c:	892a                	mv	s2,a0
  
  begin_op();
    80005f0e:	ffffe097          	auipc	ra,0xffffe
    80005f12:	7d0080e7          	jalr	2000(ra) # 800046de <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f16:	08000613          	li	a2,128
    80005f1a:	f6040593          	addi	a1,s0,-160
    80005f1e:	4501                	li	a0,0
    80005f20:	ffffd097          	auipc	ra,0xffffd
    80005f24:	242080e7          	jalr	578(ra) # 80003162 <argstr>
    80005f28:	04054b63          	bltz	a0,80005f7e <sys_chdir+0x86>
    80005f2c:	f6040513          	addi	a0,s0,-160
    80005f30:	ffffe097          	auipc	ra,0xffffe
    80005f34:	592080e7          	jalr	1426(ra) # 800044c2 <namei>
    80005f38:	84aa                	mv	s1,a0
    80005f3a:	c131                	beqz	a0,80005f7e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f3c:	ffffe097          	auipc	ra,0xffffe
    80005f40:	dd0080e7          	jalr	-560(ra) # 80003d0c <ilock>
  if(ip->type != T_DIR){
    80005f44:	04449703          	lh	a4,68(s1)
    80005f48:	4785                	li	a5,1
    80005f4a:	04f71063          	bne	a4,a5,80005f8a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f4e:	8526                	mv	a0,s1
    80005f50:	ffffe097          	auipc	ra,0xffffe
    80005f54:	e7e080e7          	jalr	-386(ra) # 80003dce <iunlock>
  iput(p->cwd);
    80005f58:	15093503          	ld	a0,336(s2)
    80005f5c:	ffffe097          	auipc	ra,0xffffe
    80005f60:	f6a080e7          	jalr	-150(ra) # 80003ec6 <iput>
  end_op();
    80005f64:	ffffe097          	auipc	ra,0xffffe
    80005f68:	7fa080e7          	jalr	2042(ra) # 8000475e <end_op>
  p->cwd = ip;
    80005f6c:	14993823          	sd	s1,336(s2)
  return 0;
    80005f70:	4501                	li	a0,0
}
    80005f72:	60ea                	ld	ra,152(sp)
    80005f74:	644a                	ld	s0,144(sp)
    80005f76:	64aa                	ld	s1,136(sp)
    80005f78:	690a                	ld	s2,128(sp)
    80005f7a:	610d                	addi	sp,sp,160
    80005f7c:	8082                	ret
    end_op();
    80005f7e:	ffffe097          	auipc	ra,0xffffe
    80005f82:	7e0080e7          	jalr	2016(ra) # 8000475e <end_op>
    return -1;
    80005f86:	557d                	li	a0,-1
    80005f88:	b7ed                	j	80005f72 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f8a:	8526                	mv	a0,s1
    80005f8c:	ffffe097          	auipc	ra,0xffffe
    80005f90:	fe2080e7          	jalr	-30(ra) # 80003f6e <iunlockput>
    end_op();
    80005f94:	ffffe097          	auipc	ra,0xffffe
    80005f98:	7ca080e7          	jalr	1994(ra) # 8000475e <end_op>
    return -1;
    80005f9c:	557d                	li	a0,-1
    80005f9e:	bfd1                	j	80005f72 <sys_chdir+0x7a>

0000000080005fa0 <sys_exec>:

uint64
sys_exec(void)
{
    80005fa0:	7145                	addi	sp,sp,-464
    80005fa2:	e786                	sd	ra,456(sp)
    80005fa4:	e3a2                	sd	s0,448(sp)
    80005fa6:	ff26                	sd	s1,440(sp)
    80005fa8:	fb4a                	sd	s2,432(sp)
    80005faa:	f74e                	sd	s3,424(sp)
    80005fac:	f352                	sd	s4,416(sp)
    80005fae:	ef56                	sd	s5,408(sp)
    80005fb0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fb2:	08000613          	li	a2,128
    80005fb6:	f4040593          	addi	a1,s0,-192
    80005fba:	4501                	li	a0,0
    80005fbc:	ffffd097          	auipc	ra,0xffffd
    80005fc0:	1a6080e7          	jalr	422(ra) # 80003162 <argstr>
    return -1;
    80005fc4:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fc6:	0c054a63          	bltz	a0,8000609a <sys_exec+0xfa>
    80005fca:	e3840593          	addi	a1,s0,-456
    80005fce:	4505                	li	a0,1
    80005fd0:	ffffd097          	auipc	ra,0xffffd
    80005fd4:	170080e7          	jalr	368(ra) # 80003140 <argaddr>
    80005fd8:	0c054163          	bltz	a0,8000609a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005fdc:	10000613          	li	a2,256
    80005fe0:	4581                	li	a1,0
    80005fe2:	e4040513          	addi	a0,s0,-448
    80005fe6:	ffffb097          	auipc	ra,0xffffb
    80005fea:	cfa080e7          	jalr	-774(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005fee:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ff2:	89a6                	mv	s3,s1
    80005ff4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ff6:	02000a13          	li	s4,32
    80005ffa:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ffe:	00391513          	slli	a0,s2,0x3
    80006002:	e3040593          	addi	a1,s0,-464
    80006006:	e3843783          	ld	a5,-456(s0)
    8000600a:	953e                	add	a0,a0,a5
    8000600c:	ffffd097          	auipc	ra,0xffffd
    80006010:	078080e7          	jalr	120(ra) # 80003084 <fetchaddr>
    80006014:	02054a63          	bltz	a0,80006048 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006018:	e3043783          	ld	a5,-464(s0)
    8000601c:	c3b9                	beqz	a5,80006062 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000601e:	ffffb097          	auipc	ra,0xffffb
    80006022:	ad6080e7          	jalr	-1322(ra) # 80000af4 <kalloc>
    80006026:	85aa                	mv	a1,a0
    80006028:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000602c:	cd11                	beqz	a0,80006048 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000602e:	6605                	lui	a2,0x1
    80006030:	e3043503          	ld	a0,-464(s0)
    80006034:	ffffd097          	auipc	ra,0xffffd
    80006038:	0a2080e7          	jalr	162(ra) # 800030d6 <fetchstr>
    8000603c:	00054663          	bltz	a0,80006048 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006040:	0905                	addi	s2,s2,1
    80006042:	09a1                	addi	s3,s3,8
    80006044:	fb491be3          	bne	s2,s4,80005ffa <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006048:	10048913          	addi	s2,s1,256
    8000604c:	6088                	ld	a0,0(s1)
    8000604e:	c529                	beqz	a0,80006098 <sys_exec+0xf8>
    kfree(argv[i]);
    80006050:	ffffb097          	auipc	ra,0xffffb
    80006054:	9a8080e7          	jalr	-1624(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006058:	04a1                	addi	s1,s1,8
    8000605a:	ff2499e3          	bne	s1,s2,8000604c <sys_exec+0xac>
  return -1;
    8000605e:	597d                	li	s2,-1
    80006060:	a82d                	j	8000609a <sys_exec+0xfa>
      argv[i] = 0;
    80006062:	0a8e                	slli	s5,s5,0x3
    80006064:	fc040793          	addi	a5,s0,-64
    80006068:	9abe                	add	s5,s5,a5
    8000606a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000606e:	e4040593          	addi	a1,s0,-448
    80006072:	f4040513          	addi	a0,s0,-192
    80006076:	fffff097          	auipc	ra,0xfffff
    8000607a:	194080e7          	jalr	404(ra) # 8000520a <exec>
    8000607e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006080:	10048993          	addi	s3,s1,256
    80006084:	6088                	ld	a0,0(s1)
    80006086:	c911                	beqz	a0,8000609a <sys_exec+0xfa>
    kfree(argv[i]);
    80006088:	ffffb097          	auipc	ra,0xffffb
    8000608c:	970080e7          	jalr	-1680(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006090:	04a1                	addi	s1,s1,8
    80006092:	ff3499e3          	bne	s1,s3,80006084 <sys_exec+0xe4>
    80006096:	a011                	j	8000609a <sys_exec+0xfa>
  return -1;
    80006098:	597d                	li	s2,-1
}
    8000609a:	854a                	mv	a0,s2
    8000609c:	60be                	ld	ra,456(sp)
    8000609e:	641e                	ld	s0,448(sp)
    800060a0:	74fa                	ld	s1,440(sp)
    800060a2:	795a                	ld	s2,432(sp)
    800060a4:	79ba                	ld	s3,424(sp)
    800060a6:	7a1a                	ld	s4,416(sp)
    800060a8:	6afa                	ld	s5,408(sp)
    800060aa:	6179                	addi	sp,sp,464
    800060ac:	8082                	ret

00000000800060ae <sys_pipe>:

uint64
sys_pipe(void)
{
    800060ae:	7139                	addi	sp,sp,-64
    800060b0:	fc06                	sd	ra,56(sp)
    800060b2:	f822                	sd	s0,48(sp)
    800060b4:	f426                	sd	s1,40(sp)
    800060b6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060b8:	ffffc097          	auipc	ra,0xffffc
    800060bc:	c7c080e7          	jalr	-900(ra) # 80001d34 <myproc>
    800060c0:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800060c2:	fd840593          	addi	a1,s0,-40
    800060c6:	4501                	li	a0,0
    800060c8:	ffffd097          	auipc	ra,0xffffd
    800060cc:	078080e7          	jalr	120(ra) # 80003140 <argaddr>
    return -1;
    800060d0:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800060d2:	0e054063          	bltz	a0,800061b2 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800060d6:	fc840593          	addi	a1,s0,-56
    800060da:	fd040513          	addi	a0,s0,-48
    800060de:	fffff097          	auipc	ra,0xfffff
    800060e2:	dfc080e7          	jalr	-516(ra) # 80004eda <pipealloc>
    return -1;
    800060e6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800060e8:	0c054563          	bltz	a0,800061b2 <sys_pipe+0x104>
  fd0 = -1;
    800060ec:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800060f0:	fd043503          	ld	a0,-48(s0)
    800060f4:	fffff097          	auipc	ra,0xfffff
    800060f8:	508080e7          	jalr	1288(ra) # 800055fc <fdalloc>
    800060fc:	fca42223          	sw	a0,-60(s0)
    80006100:	08054c63          	bltz	a0,80006198 <sys_pipe+0xea>
    80006104:	fc843503          	ld	a0,-56(s0)
    80006108:	fffff097          	auipc	ra,0xfffff
    8000610c:	4f4080e7          	jalr	1268(ra) # 800055fc <fdalloc>
    80006110:	fca42023          	sw	a0,-64(s0)
    80006114:	06054863          	bltz	a0,80006184 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006118:	4691                	li	a3,4
    8000611a:	fc440613          	addi	a2,s0,-60
    8000611e:	fd843583          	ld	a1,-40(s0)
    80006122:	68a8                	ld	a0,80(s1)
    80006124:	ffffb097          	auipc	ra,0xffffb
    80006128:	54e080e7          	jalr	1358(ra) # 80001672 <copyout>
    8000612c:	02054063          	bltz	a0,8000614c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006130:	4691                	li	a3,4
    80006132:	fc040613          	addi	a2,s0,-64
    80006136:	fd843583          	ld	a1,-40(s0)
    8000613a:	0591                	addi	a1,a1,4
    8000613c:	68a8                	ld	a0,80(s1)
    8000613e:	ffffb097          	auipc	ra,0xffffb
    80006142:	534080e7          	jalr	1332(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006146:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006148:	06055563          	bgez	a0,800061b2 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000614c:	fc442783          	lw	a5,-60(s0)
    80006150:	07e9                	addi	a5,a5,26
    80006152:	078e                	slli	a5,a5,0x3
    80006154:	97a6                	add	a5,a5,s1
    80006156:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000615a:	fc042503          	lw	a0,-64(s0)
    8000615e:	0569                	addi	a0,a0,26
    80006160:	050e                	slli	a0,a0,0x3
    80006162:	9526                	add	a0,a0,s1
    80006164:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006168:	fd043503          	ld	a0,-48(s0)
    8000616c:	fffff097          	auipc	ra,0xfffff
    80006170:	a3e080e7          	jalr	-1474(ra) # 80004baa <fileclose>
    fileclose(wf);
    80006174:	fc843503          	ld	a0,-56(s0)
    80006178:	fffff097          	auipc	ra,0xfffff
    8000617c:	a32080e7          	jalr	-1486(ra) # 80004baa <fileclose>
    return -1;
    80006180:	57fd                	li	a5,-1
    80006182:	a805                	j	800061b2 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006184:	fc442783          	lw	a5,-60(s0)
    80006188:	0007c863          	bltz	a5,80006198 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000618c:	01a78513          	addi	a0,a5,26
    80006190:	050e                	slli	a0,a0,0x3
    80006192:	9526                	add	a0,a0,s1
    80006194:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006198:	fd043503          	ld	a0,-48(s0)
    8000619c:	fffff097          	auipc	ra,0xfffff
    800061a0:	a0e080e7          	jalr	-1522(ra) # 80004baa <fileclose>
    fileclose(wf);
    800061a4:	fc843503          	ld	a0,-56(s0)
    800061a8:	fffff097          	auipc	ra,0xfffff
    800061ac:	a02080e7          	jalr	-1534(ra) # 80004baa <fileclose>
    return -1;
    800061b0:	57fd                	li	a5,-1
}
    800061b2:	853e                	mv	a0,a5
    800061b4:	70e2                	ld	ra,56(sp)
    800061b6:	7442                	ld	s0,48(sp)
    800061b8:	74a2                	ld	s1,40(sp)
    800061ba:	6121                	addi	sp,sp,64
    800061bc:	8082                	ret
	...

00000000800061c0 <kernelvec>:
    800061c0:	7111                	addi	sp,sp,-256
    800061c2:	e006                	sd	ra,0(sp)
    800061c4:	e40a                	sd	sp,8(sp)
    800061c6:	e80e                	sd	gp,16(sp)
    800061c8:	ec12                	sd	tp,24(sp)
    800061ca:	f016                	sd	t0,32(sp)
    800061cc:	f41a                	sd	t1,40(sp)
    800061ce:	f81e                	sd	t2,48(sp)
    800061d0:	fc22                	sd	s0,56(sp)
    800061d2:	e0a6                	sd	s1,64(sp)
    800061d4:	e4aa                	sd	a0,72(sp)
    800061d6:	e8ae                	sd	a1,80(sp)
    800061d8:	ecb2                	sd	a2,88(sp)
    800061da:	f0b6                	sd	a3,96(sp)
    800061dc:	f4ba                	sd	a4,104(sp)
    800061de:	f8be                	sd	a5,112(sp)
    800061e0:	fcc2                	sd	a6,120(sp)
    800061e2:	e146                	sd	a7,128(sp)
    800061e4:	e54a                	sd	s2,136(sp)
    800061e6:	e94e                	sd	s3,144(sp)
    800061e8:	ed52                	sd	s4,152(sp)
    800061ea:	f156                	sd	s5,160(sp)
    800061ec:	f55a                	sd	s6,168(sp)
    800061ee:	f95e                	sd	s7,176(sp)
    800061f0:	fd62                	sd	s8,184(sp)
    800061f2:	e1e6                	sd	s9,192(sp)
    800061f4:	e5ea                	sd	s10,200(sp)
    800061f6:	e9ee                	sd	s11,208(sp)
    800061f8:	edf2                	sd	t3,216(sp)
    800061fa:	f1f6                	sd	t4,224(sp)
    800061fc:	f5fa                	sd	t5,232(sp)
    800061fe:	f9fe                	sd	t6,240(sp)
    80006200:	d51fc0ef          	jal	ra,80002f50 <kerneltrap>
    80006204:	6082                	ld	ra,0(sp)
    80006206:	6122                	ld	sp,8(sp)
    80006208:	61c2                	ld	gp,16(sp)
    8000620a:	7282                	ld	t0,32(sp)
    8000620c:	7322                	ld	t1,40(sp)
    8000620e:	73c2                	ld	t2,48(sp)
    80006210:	7462                	ld	s0,56(sp)
    80006212:	6486                	ld	s1,64(sp)
    80006214:	6526                	ld	a0,72(sp)
    80006216:	65c6                	ld	a1,80(sp)
    80006218:	6666                	ld	a2,88(sp)
    8000621a:	7686                	ld	a3,96(sp)
    8000621c:	7726                	ld	a4,104(sp)
    8000621e:	77c6                	ld	a5,112(sp)
    80006220:	7866                	ld	a6,120(sp)
    80006222:	688a                	ld	a7,128(sp)
    80006224:	692a                	ld	s2,136(sp)
    80006226:	69ca                	ld	s3,144(sp)
    80006228:	6a6a                	ld	s4,152(sp)
    8000622a:	7a8a                	ld	s5,160(sp)
    8000622c:	7b2a                	ld	s6,168(sp)
    8000622e:	7bca                	ld	s7,176(sp)
    80006230:	7c6a                	ld	s8,184(sp)
    80006232:	6c8e                	ld	s9,192(sp)
    80006234:	6d2e                	ld	s10,200(sp)
    80006236:	6dce                	ld	s11,208(sp)
    80006238:	6e6e                	ld	t3,216(sp)
    8000623a:	7e8e                	ld	t4,224(sp)
    8000623c:	7f2e                	ld	t5,232(sp)
    8000623e:	7fce                	ld	t6,240(sp)
    80006240:	6111                	addi	sp,sp,256
    80006242:	10200073          	sret
    80006246:	00000013          	nop
    8000624a:	00000013          	nop
    8000624e:	0001                	nop

0000000080006250 <timervec>:
    80006250:	34051573          	csrrw	a0,mscratch,a0
    80006254:	e10c                	sd	a1,0(a0)
    80006256:	e510                	sd	a2,8(a0)
    80006258:	e914                	sd	a3,16(a0)
    8000625a:	6d0c                	ld	a1,24(a0)
    8000625c:	7110                	ld	a2,32(a0)
    8000625e:	6194                	ld	a3,0(a1)
    80006260:	96b2                	add	a3,a3,a2
    80006262:	e194                	sd	a3,0(a1)
    80006264:	4589                	li	a1,2
    80006266:	14459073          	csrw	sip,a1
    8000626a:	6914                	ld	a3,16(a0)
    8000626c:	6510                	ld	a2,8(a0)
    8000626e:	610c                	ld	a1,0(a0)
    80006270:	34051573          	csrrw	a0,mscratch,a0
    80006274:	30200073          	mret
	...

000000008000627a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000627a:	1141                	addi	sp,sp,-16
    8000627c:	e422                	sd	s0,8(sp)
    8000627e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006280:	0c0007b7          	lui	a5,0xc000
    80006284:	4705                	li	a4,1
    80006286:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006288:	c3d8                	sw	a4,4(a5)
}
    8000628a:	6422                	ld	s0,8(sp)
    8000628c:	0141                	addi	sp,sp,16
    8000628e:	8082                	ret

0000000080006290 <plicinithart>:

void
plicinithart(void)
{
    80006290:	1141                	addi	sp,sp,-16
    80006292:	e406                	sd	ra,8(sp)
    80006294:	e022                	sd	s0,0(sp)
    80006296:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006298:	ffffc097          	auipc	ra,0xffffc
    8000629c:	a6a080e7          	jalr	-1430(ra) # 80001d02 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062a0:	0085171b          	slliw	a4,a0,0x8
    800062a4:	0c0027b7          	lui	a5,0xc002
    800062a8:	97ba                	add	a5,a5,a4
    800062aa:	40200713          	li	a4,1026
    800062ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062b2:	00d5151b          	slliw	a0,a0,0xd
    800062b6:	0c2017b7          	lui	a5,0xc201
    800062ba:	953e                	add	a0,a0,a5
    800062bc:	00052023          	sw	zero,0(a0)
}
    800062c0:	60a2                	ld	ra,8(sp)
    800062c2:	6402                	ld	s0,0(sp)
    800062c4:	0141                	addi	sp,sp,16
    800062c6:	8082                	ret

00000000800062c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062c8:	1141                	addi	sp,sp,-16
    800062ca:	e406                	sd	ra,8(sp)
    800062cc:	e022                	sd	s0,0(sp)
    800062ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062d0:	ffffc097          	auipc	ra,0xffffc
    800062d4:	a32080e7          	jalr	-1486(ra) # 80001d02 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800062d8:	00d5179b          	slliw	a5,a0,0xd
    800062dc:	0c201537          	lui	a0,0xc201
    800062e0:	953e                	add	a0,a0,a5
  return irq;
}
    800062e2:	4148                	lw	a0,4(a0)
    800062e4:	60a2                	ld	ra,8(sp)
    800062e6:	6402                	ld	s0,0(sp)
    800062e8:	0141                	addi	sp,sp,16
    800062ea:	8082                	ret

00000000800062ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800062ec:	1101                	addi	sp,sp,-32
    800062ee:	ec06                	sd	ra,24(sp)
    800062f0:	e822                	sd	s0,16(sp)
    800062f2:	e426                	sd	s1,8(sp)
    800062f4:	1000                	addi	s0,sp,32
    800062f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800062f8:	ffffc097          	auipc	ra,0xffffc
    800062fc:	a0a080e7          	jalr	-1526(ra) # 80001d02 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006300:	00d5151b          	slliw	a0,a0,0xd
    80006304:	0c2017b7          	lui	a5,0xc201
    80006308:	97aa                	add	a5,a5,a0
    8000630a:	c3c4                	sw	s1,4(a5)
}
    8000630c:	60e2                	ld	ra,24(sp)
    8000630e:	6442                	ld	s0,16(sp)
    80006310:	64a2                	ld	s1,8(sp)
    80006312:	6105                	addi	sp,sp,32
    80006314:	8082                	ret

0000000080006316 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006316:	1141                	addi	sp,sp,-16
    80006318:	e406                	sd	ra,8(sp)
    8000631a:	e022                	sd	s0,0(sp)
    8000631c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000631e:	479d                	li	a5,7
    80006320:	06a7c963          	blt	a5,a0,80006392 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006324:	0001d797          	auipc	a5,0x1d
    80006328:	cdc78793          	addi	a5,a5,-804 # 80023000 <disk>
    8000632c:	00a78733          	add	a4,a5,a0
    80006330:	6789                	lui	a5,0x2
    80006332:	97ba                	add	a5,a5,a4
    80006334:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006338:	e7ad                	bnez	a5,800063a2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000633a:	00451793          	slli	a5,a0,0x4
    8000633e:	0001f717          	auipc	a4,0x1f
    80006342:	cc270713          	addi	a4,a4,-830 # 80025000 <disk+0x2000>
    80006346:	6314                	ld	a3,0(a4)
    80006348:	96be                	add	a3,a3,a5
    8000634a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000634e:	6314                	ld	a3,0(a4)
    80006350:	96be                	add	a3,a3,a5
    80006352:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006356:	6314                	ld	a3,0(a4)
    80006358:	96be                	add	a3,a3,a5
    8000635a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000635e:	6318                	ld	a4,0(a4)
    80006360:	97ba                	add	a5,a5,a4
    80006362:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006366:	0001d797          	auipc	a5,0x1d
    8000636a:	c9a78793          	addi	a5,a5,-870 # 80023000 <disk>
    8000636e:	97aa                	add	a5,a5,a0
    80006370:	6509                	lui	a0,0x2
    80006372:	953e                	add	a0,a0,a5
    80006374:	4785                	li	a5,1
    80006376:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000637a:	0001f517          	auipc	a0,0x1f
    8000637e:	c9e50513          	addi	a0,a0,-866 # 80025018 <disk+0x2018>
    80006382:	ffffc097          	auipc	ra,0xffffc
    80006386:	656080e7          	jalr	1622(ra) # 800029d8 <wakeup>
}
    8000638a:	60a2                	ld	ra,8(sp)
    8000638c:	6402                	ld	s0,0(sp)
    8000638e:	0141                	addi	sp,sp,16
    80006390:	8082                	ret
    panic("free_desc 1");
    80006392:	00002517          	auipc	a0,0x2
    80006396:	5be50513          	addi	a0,a0,1470 # 80008950 <syscalls+0x338>
    8000639a:	ffffa097          	auipc	ra,0xffffa
    8000639e:	1a4080e7          	jalr	420(ra) # 8000053e <panic>
    panic("free_desc 2");
    800063a2:	00002517          	auipc	a0,0x2
    800063a6:	5be50513          	addi	a0,a0,1470 # 80008960 <syscalls+0x348>
    800063aa:	ffffa097          	auipc	ra,0xffffa
    800063ae:	194080e7          	jalr	404(ra) # 8000053e <panic>

00000000800063b2 <virtio_disk_init>:
{
    800063b2:	1101                	addi	sp,sp,-32
    800063b4:	ec06                	sd	ra,24(sp)
    800063b6:	e822                	sd	s0,16(sp)
    800063b8:	e426                	sd	s1,8(sp)
    800063ba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063bc:	00002597          	auipc	a1,0x2
    800063c0:	5b458593          	addi	a1,a1,1460 # 80008970 <syscalls+0x358>
    800063c4:	0001f517          	auipc	a0,0x1f
    800063c8:	d6450513          	addi	a0,a0,-668 # 80025128 <disk+0x2128>
    800063cc:	ffffa097          	auipc	ra,0xffffa
    800063d0:	788080e7          	jalr	1928(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063d4:	100017b7          	lui	a5,0x10001
    800063d8:	4398                	lw	a4,0(a5)
    800063da:	2701                	sext.w	a4,a4
    800063dc:	747277b7          	lui	a5,0x74727
    800063e0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800063e4:	0ef71163          	bne	a4,a5,800064c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800063e8:	100017b7          	lui	a5,0x10001
    800063ec:	43dc                	lw	a5,4(a5)
    800063ee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063f0:	4705                	li	a4,1
    800063f2:	0ce79a63          	bne	a5,a4,800064c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063f6:	100017b7          	lui	a5,0x10001
    800063fa:	479c                	lw	a5,8(a5)
    800063fc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800063fe:	4709                	li	a4,2
    80006400:	0ce79363          	bne	a5,a4,800064c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006404:	100017b7          	lui	a5,0x10001
    80006408:	47d8                	lw	a4,12(a5)
    8000640a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000640c:	554d47b7          	lui	a5,0x554d4
    80006410:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006414:	0af71963          	bne	a4,a5,800064c6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006418:	100017b7          	lui	a5,0x10001
    8000641c:	4705                	li	a4,1
    8000641e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006420:	470d                	li	a4,3
    80006422:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006424:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006426:	c7ffe737          	lui	a4,0xc7ffe
    8000642a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000642e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006430:	2701                	sext.w	a4,a4
    80006432:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006434:	472d                	li	a4,11
    80006436:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006438:	473d                	li	a4,15
    8000643a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000643c:	6705                	lui	a4,0x1
    8000643e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006440:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006444:	5bdc                	lw	a5,52(a5)
    80006446:	2781                	sext.w	a5,a5
  if(max == 0)
    80006448:	c7d9                	beqz	a5,800064d6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000644a:	471d                	li	a4,7
    8000644c:	08f77d63          	bgeu	a4,a5,800064e6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006450:	100014b7          	lui	s1,0x10001
    80006454:	47a1                	li	a5,8
    80006456:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006458:	6609                	lui	a2,0x2
    8000645a:	4581                	li	a1,0
    8000645c:	0001d517          	auipc	a0,0x1d
    80006460:	ba450513          	addi	a0,a0,-1116 # 80023000 <disk>
    80006464:	ffffb097          	auipc	ra,0xffffb
    80006468:	87c080e7          	jalr	-1924(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000646c:	0001d717          	auipc	a4,0x1d
    80006470:	b9470713          	addi	a4,a4,-1132 # 80023000 <disk>
    80006474:	00c75793          	srli	a5,a4,0xc
    80006478:	2781                	sext.w	a5,a5
    8000647a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000647c:	0001f797          	auipc	a5,0x1f
    80006480:	b8478793          	addi	a5,a5,-1148 # 80025000 <disk+0x2000>
    80006484:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006486:	0001d717          	auipc	a4,0x1d
    8000648a:	bfa70713          	addi	a4,a4,-1030 # 80023080 <disk+0x80>
    8000648e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006490:	0001e717          	auipc	a4,0x1e
    80006494:	b7070713          	addi	a4,a4,-1168 # 80024000 <disk+0x1000>
    80006498:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000649a:	4705                	li	a4,1
    8000649c:	00e78c23          	sb	a4,24(a5)
    800064a0:	00e78ca3          	sb	a4,25(a5)
    800064a4:	00e78d23          	sb	a4,26(a5)
    800064a8:	00e78da3          	sb	a4,27(a5)
    800064ac:	00e78e23          	sb	a4,28(a5)
    800064b0:	00e78ea3          	sb	a4,29(a5)
    800064b4:	00e78f23          	sb	a4,30(a5)
    800064b8:	00e78fa3          	sb	a4,31(a5)
}
    800064bc:	60e2                	ld	ra,24(sp)
    800064be:	6442                	ld	s0,16(sp)
    800064c0:	64a2                	ld	s1,8(sp)
    800064c2:	6105                	addi	sp,sp,32
    800064c4:	8082                	ret
    panic("could not find virtio disk");
    800064c6:	00002517          	auipc	a0,0x2
    800064ca:	4ba50513          	addi	a0,a0,1210 # 80008980 <syscalls+0x368>
    800064ce:	ffffa097          	auipc	ra,0xffffa
    800064d2:	070080e7          	jalr	112(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800064d6:	00002517          	auipc	a0,0x2
    800064da:	4ca50513          	addi	a0,a0,1226 # 800089a0 <syscalls+0x388>
    800064de:	ffffa097          	auipc	ra,0xffffa
    800064e2:	060080e7          	jalr	96(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800064e6:	00002517          	auipc	a0,0x2
    800064ea:	4da50513          	addi	a0,a0,1242 # 800089c0 <syscalls+0x3a8>
    800064ee:	ffffa097          	auipc	ra,0xffffa
    800064f2:	050080e7          	jalr	80(ra) # 8000053e <panic>

00000000800064f6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800064f6:	7159                	addi	sp,sp,-112
    800064f8:	f486                	sd	ra,104(sp)
    800064fa:	f0a2                	sd	s0,96(sp)
    800064fc:	eca6                	sd	s1,88(sp)
    800064fe:	e8ca                	sd	s2,80(sp)
    80006500:	e4ce                	sd	s3,72(sp)
    80006502:	e0d2                	sd	s4,64(sp)
    80006504:	fc56                	sd	s5,56(sp)
    80006506:	f85a                	sd	s6,48(sp)
    80006508:	f45e                	sd	s7,40(sp)
    8000650a:	f062                	sd	s8,32(sp)
    8000650c:	ec66                	sd	s9,24(sp)
    8000650e:	e86a                	sd	s10,16(sp)
    80006510:	1880                	addi	s0,sp,112
    80006512:	892a                	mv	s2,a0
    80006514:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006516:	00c52c83          	lw	s9,12(a0)
    8000651a:	001c9c9b          	slliw	s9,s9,0x1
    8000651e:	1c82                	slli	s9,s9,0x20
    80006520:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006524:	0001f517          	auipc	a0,0x1f
    80006528:	c0450513          	addi	a0,a0,-1020 # 80025128 <disk+0x2128>
    8000652c:	ffffa097          	auipc	ra,0xffffa
    80006530:	6b8080e7          	jalr	1720(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006534:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006536:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006538:	0001db97          	auipc	s7,0x1d
    8000653c:	ac8b8b93          	addi	s7,s7,-1336 # 80023000 <disk>
    80006540:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006542:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006544:	8a4e                	mv	s4,s3
    80006546:	a051                	j	800065ca <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006548:	00fb86b3          	add	a3,s7,a5
    8000654c:	96da                	add	a3,a3,s6
    8000654e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006552:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006554:	0207c563          	bltz	a5,8000657e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006558:	2485                	addiw	s1,s1,1
    8000655a:	0711                	addi	a4,a4,4
    8000655c:	25548063          	beq	s1,s5,8000679c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006560:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006562:	0001f697          	auipc	a3,0x1f
    80006566:	ab668693          	addi	a3,a3,-1354 # 80025018 <disk+0x2018>
    8000656a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000656c:	0006c583          	lbu	a1,0(a3)
    80006570:	fde1                	bnez	a1,80006548 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006572:	2785                	addiw	a5,a5,1
    80006574:	0685                	addi	a3,a3,1
    80006576:	ff879be3          	bne	a5,s8,8000656c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000657a:	57fd                	li	a5,-1
    8000657c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000657e:	02905a63          	blez	s1,800065b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006582:	f9042503          	lw	a0,-112(s0)
    80006586:	00000097          	auipc	ra,0x0
    8000658a:	d90080e7          	jalr	-624(ra) # 80006316 <free_desc>
      for(int j = 0; j < i; j++)
    8000658e:	4785                	li	a5,1
    80006590:	0297d163          	bge	a5,s1,800065b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006594:	f9442503          	lw	a0,-108(s0)
    80006598:	00000097          	auipc	ra,0x0
    8000659c:	d7e080e7          	jalr	-642(ra) # 80006316 <free_desc>
      for(int j = 0; j < i; j++)
    800065a0:	4789                	li	a5,2
    800065a2:	0097d863          	bge	a5,s1,800065b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065a6:	f9842503          	lw	a0,-104(s0)
    800065aa:	00000097          	auipc	ra,0x0
    800065ae:	d6c080e7          	jalr	-660(ra) # 80006316 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065b2:	0001f597          	auipc	a1,0x1f
    800065b6:	b7658593          	addi	a1,a1,-1162 # 80025128 <disk+0x2128>
    800065ba:	0001f517          	auipc	a0,0x1f
    800065be:	a5e50513          	addi	a0,a0,-1442 # 80025018 <disk+0x2018>
    800065c2:	ffffc097          	auipc	ra,0xffffc
    800065c6:	e00080e7          	jalr	-512(ra) # 800023c2 <sleep>
  for(int i = 0; i < 3; i++){
    800065ca:	f9040713          	addi	a4,s0,-112
    800065ce:	84ce                	mv	s1,s3
    800065d0:	bf41                	j	80006560 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800065d2:	20058713          	addi	a4,a1,512
    800065d6:	00471693          	slli	a3,a4,0x4
    800065da:	0001d717          	auipc	a4,0x1d
    800065de:	a2670713          	addi	a4,a4,-1498 # 80023000 <disk>
    800065e2:	9736                	add	a4,a4,a3
    800065e4:	4685                	li	a3,1
    800065e6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800065ea:	20058713          	addi	a4,a1,512
    800065ee:	00471693          	slli	a3,a4,0x4
    800065f2:	0001d717          	auipc	a4,0x1d
    800065f6:	a0e70713          	addi	a4,a4,-1522 # 80023000 <disk>
    800065fa:	9736                	add	a4,a4,a3
    800065fc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006600:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006604:	7679                	lui	a2,0xffffe
    80006606:	963e                	add	a2,a2,a5
    80006608:	0001f697          	auipc	a3,0x1f
    8000660c:	9f868693          	addi	a3,a3,-1544 # 80025000 <disk+0x2000>
    80006610:	6298                	ld	a4,0(a3)
    80006612:	9732                	add	a4,a4,a2
    80006614:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006616:	6298                	ld	a4,0(a3)
    80006618:	9732                	add	a4,a4,a2
    8000661a:	4541                	li	a0,16
    8000661c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000661e:	6298                	ld	a4,0(a3)
    80006620:	9732                	add	a4,a4,a2
    80006622:	4505                	li	a0,1
    80006624:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006628:	f9442703          	lw	a4,-108(s0)
    8000662c:	6288                	ld	a0,0(a3)
    8000662e:	962a                	add	a2,a2,a0
    80006630:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006634:	0712                	slli	a4,a4,0x4
    80006636:	6290                	ld	a2,0(a3)
    80006638:	963a                	add	a2,a2,a4
    8000663a:	05890513          	addi	a0,s2,88
    8000663e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006640:	6294                	ld	a3,0(a3)
    80006642:	96ba                	add	a3,a3,a4
    80006644:	40000613          	li	a2,1024
    80006648:	c690                	sw	a2,8(a3)
  if(write)
    8000664a:	140d0063          	beqz	s10,8000678a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000664e:	0001f697          	auipc	a3,0x1f
    80006652:	9b26b683          	ld	a3,-1614(a3) # 80025000 <disk+0x2000>
    80006656:	96ba                	add	a3,a3,a4
    80006658:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000665c:	0001d817          	auipc	a6,0x1d
    80006660:	9a480813          	addi	a6,a6,-1628 # 80023000 <disk>
    80006664:	0001f517          	auipc	a0,0x1f
    80006668:	99c50513          	addi	a0,a0,-1636 # 80025000 <disk+0x2000>
    8000666c:	6114                	ld	a3,0(a0)
    8000666e:	96ba                	add	a3,a3,a4
    80006670:	00c6d603          	lhu	a2,12(a3)
    80006674:	00166613          	ori	a2,a2,1
    80006678:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000667c:	f9842683          	lw	a3,-104(s0)
    80006680:	6110                	ld	a2,0(a0)
    80006682:	9732                	add	a4,a4,a2
    80006684:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006688:	20058613          	addi	a2,a1,512
    8000668c:	0612                	slli	a2,a2,0x4
    8000668e:	9642                	add	a2,a2,a6
    80006690:	577d                	li	a4,-1
    80006692:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006696:	00469713          	slli	a4,a3,0x4
    8000669a:	6114                	ld	a3,0(a0)
    8000669c:	96ba                	add	a3,a3,a4
    8000669e:	03078793          	addi	a5,a5,48
    800066a2:	97c2                	add	a5,a5,a6
    800066a4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800066a6:	611c                	ld	a5,0(a0)
    800066a8:	97ba                	add	a5,a5,a4
    800066aa:	4685                	li	a3,1
    800066ac:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066ae:	611c                	ld	a5,0(a0)
    800066b0:	97ba                	add	a5,a5,a4
    800066b2:	4809                	li	a6,2
    800066b4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800066b8:	611c                	ld	a5,0(a0)
    800066ba:	973e                	add	a4,a4,a5
    800066bc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800066c0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800066c4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800066c8:	6518                	ld	a4,8(a0)
    800066ca:	00275783          	lhu	a5,2(a4)
    800066ce:	8b9d                	andi	a5,a5,7
    800066d0:	0786                	slli	a5,a5,0x1
    800066d2:	97ba                	add	a5,a5,a4
    800066d4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800066d8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800066dc:	6518                	ld	a4,8(a0)
    800066de:	00275783          	lhu	a5,2(a4)
    800066e2:	2785                	addiw	a5,a5,1
    800066e4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800066e8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800066ec:	100017b7          	lui	a5,0x10001
    800066f0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800066f4:	00492703          	lw	a4,4(s2)
    800066f8:	4785                	li	a5,1
    800066fa:	02f71163          	bne	a4,a5,8000671c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800066fe:	0001f997          	auipc	s3,0x1f
    80006702:	a2a98993          	addi	s3,s3,-1494 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006706:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006708:	85ce                	mv	a1,s3
    8000670a:	854a                	mv	a0,s2
    8000670c:	ffffc097          	auipc	ra,0xffffc
    80006710:	cb6080e7          	jalr	-842(ra) # 800023c2 <sleep>
  while(b->disk == 1) {
    80006714:	00492783          	lw	a5,4(s2)
    80006718:	fe9788e3          	beq	a5,s1,80006708 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000671c:	f9042903          	lw	s2,-112(s0)
    80006720:	20090793          	addi	a5,s2,512
    80006724:	00479713          	slli	a4,a5,0x4
    80006728:	0001d797          	auipc	a5,0x1d
    8000672c:	8d878793          	addi	a5,a5,-1832 # 80023000 <disk>
    80006730:	97ba                	add	a5,a5,a4
    80006732:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006736:	0001f997          	auipc	s3,0x1f
    8000673a:	8ca98993          	addi	s3,s3,-1846 # 80025000 <disk+0x2000>
    8000673e:	00491713          	slli	a4,s2,0x4
    80006742:	0009b783          	ld	a5,0(s3)
    80006746:	97ba                	add	a5,a5,a4
    80006748:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000674c:	854a                	mv	a0,s2
    8000674e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006752:	00000097          	auipc	ra,0x0
    80006756:	bc4080e7          	jalr	-1084(ra) # 80006316 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000675a:	8885                	andi	s1,s1,1
    8000675c:	f0ed                	bnez	s1,8000673e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000675e:	0001f517          	auipc	a0,0x1f
    80006762:	9ca50513          	addi	a0,a0,-1590 # 80025128 <disk+0x2128>
    80006766:	ffffa097          	auipc	ra,0xffffa
    8000676a:	532080e7          	jalr	1330(ra) # 80000c98 <release>
}
    8000676e:	70a6                	ld	ra,104(sp)
    80006770:	7406                	ld	s0,96(sp)
    80006772:	64e6                	ld	s1,88(sp)
    80006774:	6946                	ld	s2,80(sp)
    80006776:	69a6                	ld	s3,72(sp)
    80006778:	6a06                	ld	s4,64(sp)
    8000677a:	7ae2                	ld	s5,56(sp)
    8000677c:	7b42                	ld	s6,48(sp)
    8000677e:	7ba2                	ld	s7,40(sp)
    80006780:	7c02                	ld	s8,32(sp)
    80006782:	6ce2                	ld	s9,24(sp)
    80006784:	6d42                	ld	s10,16(sp)
    80006786:	6165                	addi	sp,sp,112
    80006788:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000678a:	0001f697          	auipc	a3,0x1f
    8000678e:	8766b683          	ld	a3,-1930(a3) # 80025000 <disk+0x2000>
    80006792:	96ba                	add	a3,a3,a4
    80006794:	4609                	li	a2,2
    80006796:	00c69623          	sh	a2,12(a3)
    8000679a:	b5c9                	j	8000665c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000679c:	f9042583          	lw	a1,-112(s0)
    800067a0:	20058793          	addi	a5,a1,512
    800067a4:	0792                	slli	a5,a5,0x4
    800067a6:	0001d517          	auipc	a0,0x1d
    800067aa:	90250513          	addi	a0,a0,-1790 # 800230a8 <disk+0xa8>
    800067ae:	953e                	add	a0,a0,a5
  if(write)
    800067b0:	e20d11e3          	bnez	s10,800065d2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800067b4:	20058713          	addi	a4,a1,512
    800067b8:	00471693          	slli	a3,a4,0x4
    800067bc:	0001d717          	auipc	a4,0x1d
    800067c0:	84470713          	addi	a4,a4,-1980 # 80023000 <disk>
    800067c4:	9736                	add	a4,a4,a3
    800067c6:	0a072423          	sw	zero,168(a4)
    800067ca:	b505                	j	800065ea <virtio_disk_rw+0xf4>

00000000800067cc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067cc:	1101                	addi	sp,sp,-32
    800067ce:	ec06                	sd	ra,24(sp)
    800067d0:	e822                	sd	s0,16(sp)
    800067d2:	e426                	sd	s1,8(sp)
    800067d4:	e04a                	sd	s2,0(sp)
    800067d6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067d8:	0001f517          	auipc	a0,0x1f
    800067dc:	95050513          	addi	a0,a0,-1712 # 80025128 <disk+0x2128>
    800067e0:	ffffa097          	auipc	ra,0xffffa
    800067e4:	404080e7          	jalr	1028(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800067e8:	10001737          	lui	a4,0x10001
    800067ec:	533c                	lw	a5,96(a4)
    800067ee:	8b8d                	andi	a5,a5,3
    800067f0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800067f2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800067f6:	0001f797          	auipc	a5,0x1f
    800067fa:	80a78793          	addi	a5,a5,-2038 # 80025000 <disk+0x2000>
    800067fe:	6b94                	ld	a3,16(a5)
    80006800:	0207d703          	lhu	a4,32(a5)
    80006804:	0026d783          	lhu	a5,2(a3)
    80006808:	06f70163          	beq	a4,a5,8000686a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000680c:	0001c917          	auipc	s2,0x1c
    80006810:	7f490913          	addi	s2,s2,2036 # 80023000 <disk>
    80006814:	0001e497          	auipc	s1,0x1e
    80006818:	7ec48493          	addi	s1,s1,2028 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000681c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006820:	6898                	ld	a4,16(s1)
    80006822:	0204d783          	lhu	a5,32(s1)
    80006826:	8b9d                	andi	a5,a5,7
    80006828:	078e                	slli	a5,a5,0x3
    8000682a:	97ba                	add	a5,a5,a4
    8000682c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000682e:	20078713          	addi	a4,a5,512
    80006832:	0712                	slli	a4,a4,0x4
    80006834:	974a                	add	a4,a4,s2
    80006836:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000683a:	e731                	bnez	a4,80006886 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000683c:	20078793          	addi	a5,a5,512
    80006840:	0792                	slli	a5,a5,0x4
    80006842:	97ca                	add	a5,a5,s2
    80006844:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006846:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000684a:	ffffc097          	auipc	ra,0xffffc
    8000684e:	18e080e7          	jalr	398(ra) # 800029d8 <wakeup>

    disk.used_idx += 1;
    80006852:	0204d783          	lhu	a5,32(s1)
    80006856:	2785                	addiw	a5,a5,1
    80006858:	17c2                	slli	a5,a5,0x30
    8000685a:	93c1                	srli	a5,a5,0x30
    8000685c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006860:	6898                	ld	a4,16(s1)
    80006862:	00275703          	lhu	a4,2(a4)
    80006866:	faf71be3          	bne	a4,a5,8000681c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000686a:	0001f517          	auipc	a0,0x1f
    8000686e:	8be50513          	addi	a0,a0,-1858 # 80025128 <disk+0x2128>
    80006872:	ffffa097          	auipc	ra,0xffffa
    80006876:	426080e7          	jalr	1062(ra) # 80000c98 <release>
}
    8000687a:	60e2                	ld	ra,24(sp)
    8000687c:	6442                	ld	s0,16(sp)
    8000687e:	64a2                	ld	s1,8(sp)
    80006880:	6902                	ld	s2,0(sp)
    80006882:	6105                	addi	sp,sp,32
    80006884:	8082                	ret
      panic("virtio_disk_intr status");
    80006886:	00002517          	auipc	a0,0x2
    8000688a:	15a50513          	addi	a0,a0,346 # 800089e0 <syscalls+0x3c8>
    8000688e:	ffffa097          	auipc	ra,0xffffa
    80006892:	cb0080e7          	jalr	-848(ra) # 8000053e <panic>

0000000080006896 <cas>:
    80006896:	100522af          	lr.w	t0,(a0)
    8000689a:	00b29563          	bne	t0,a1,800068a4 <fail>
    8000689e:	18c5252f          	sc.w	a0,a2,(a0)
    800068a2:	8082                	ret

00000000800068a4 <fail>:
    800068a4:	4505                	li	a0,1
    800068a6:	8082                	ret
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
