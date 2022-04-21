
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	e3c78793          	addi	a5,a5,-452 # 80005ea0 <timervec>
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
    80000130:	5d4080e7          	jalr	1492(ra) # 80002700 <either_copyin>
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
    800001c8:	800080e7          	jalr	-2048(ra) # 800019c4 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	132080e7          	jalr	306(ra) # 80002306 <sleep>
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
    80000214:	49a080e7          	jalr	1178(ra) # 800026aa <either_copyout>
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
    800002f6:	464080e7          	jalr	1124(ra) # 80002756 <procdump>
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
    8000044a:	04c080e7          	jalr	76(ra) # 80002492 <wakeup>
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
    8000047c:	0a078793          	addi	a5,a5,160 # 80021518 <devsw>
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
    800008a4:	bf2080e7          	jalr	-1038(ra) # 80002492 <wakeup>
    
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
    80000930:	9da080e7          	jalr	-1574(ra) # 80002306 <sleep>
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
    80000b82:	e2a080e7          	jalr	-470(ra) # 800019a8 <mycpu>
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
    80000bb4:	df8080e7          	jalr	-520(ra) # 800019a8 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dec080e7          	jalr	-532(ra) # 800019a8 <mycpu>
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
    80000bd8:	dd4080e7          	jalr	-556(ra) # 800019a8 <mycpu>
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
    80000c18:	d94080e7          	jalr	-620(ra) # 800019a8 <mycpu>
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
    80000c44:	d68080e7          	jalr	-664(ra) # 800019a8 <mycpu>
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
    80000e9a:	b02080e7          	jalr	-1278(ra) # 80001998 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c539                	beqz	a0,80000ef4 <main+0x66>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ae6080e7          	jalr	-1306(ra) # 80001998 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0e0080e7          	jalr	224(ra) # 80000fac <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	a62080e7          	jalr	-1438(ra) # 80002936 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	004080e7          	jalr	4(ra) # 80005ee0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	22c080e7          	jalr	556(ra) # 80002110 <scheduler>
}
    80000eec:	60a2                	ld	ra,8(sp)
    80000eee:	6402                	ld	s0,0(sp)
    80000ef0:	0141                	addi	sp,sp,16
    80000ef2:	8082                	ret
    consoleinit();
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	55c080e7          	jalr	1372(ra) # 80000450 <consoleinit>
    printfinit();
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	872080e7          	jalr	-1934(ra) # 8000076e <printfinit>
    printf("\n");
    80000f04:	00007517          	auipc	a0,0x7
    80000f08:	1c450513          	addi	a0,a0,452 # 800080c8 <digits+0x88>
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	67c080e7          	jalr	1660(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f14:	00007517          	auipc	a0,0x7
    80000f18:	18c50513          	addi	a0,a0,396 # 800080a0 <digits+0x60>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
    printf("\n");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	1a450513          	addi	a0,a0,420 # 800080c8 <digits+0x88>
    80000f2c:	fffff097          	auipc	ra,0xfffff
    80000f30:	65c080e7          	jalr	1628(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	b84080e7          	jalr	-1148(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	322080e7          	jalr	802(ra) # 8000125e <kvminit>
    kvminithart();   // turn on paging
    80000f44:	00000097          	auipc	ra,0x0
    80000f48:	068080e7          	jalr	104(ra) # 80000fac <kvminithart>
    procinit();      // process table
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	99c080e7          	jalr	-1636(ra) # 800018e8 <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	9ba080e7          	jalr	-1606(ra) # 8000290e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	9da080e7          	jalr	-1574(ra) # 80002936 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	f66080e7          	jalr	-154(ra) # 80005eca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	f74080e7          	jalr	-140(ra) # 80005ee0 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	150080e7          	jalr	336(ra) # 800030c4 <binit>
    iinit();         // inode table
    80000f7c:	00002097          	auipc	ra,0x2
    80000f80:	7e0080e7          	jalr	2016(ra) # 8000375c <iinit>
    fileinit();      // file table
    80000f84:	00003097          	auipc	ra,0x3
    80000f88:	78a080e7          	jalr	1930(ra) # 8000470e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	076080e7          	jalr	118(ra) # 80006002 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	d10080e7          	jalr	-752(ra) # 80001ca4 <userinit>
    __sync_synchronize();
    80000f9c:	0ff0000f          	fence
    started = 1;
    80000fa0:	4785                	li	a5,1
    80000fa2:	00008717          	auipc	a4,0x8
    80000fa6:	06f72b23          	sw	a5,118(a4) # 80009018 <started>
    80000faa:	bf2d                	j	80000ee4 <main+0x56>

0000000080000fac <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fac:	1141                	addi	sp,sp,-16
    80000fae:	e422                	sd	s0,8(sp)
    80000fb0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb2:	00008797          	auipc	a5,0x8
    80000fb6:	06e7b783          	ld	a5,110(a5) # 80009020 <kernel_pagetable>
    80000fba:	83b1                	srli	a5,a5,0xc
    80000fbc:	577d                	li	a4,-1
    80000fbe:	177e                	slli	a4,a4,0x3f
    80000fc0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc6:	12000073          	sfence.vma
  sfence_vma();
}
    80000fca:	6422                	ld	s0,8(sp)
    80000fcc:	0141                	addi	sp,sp,16
    80000fce:	8082                	ret

0000000080000fd0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd0:	7139                	addi	sp,sp,-64
    80000fd2:	fc06                	sd	ra,56(sp)
    80000fd4:	f822                	sd	s0,48(sp)
    80000fd6:	f426                	sd	s1,40(sp)
    80000fd8:	f04a                	sd	s2,32(sp)
    80000fda:	ec4e                	sd	s3,24(sp)
    80000fdc:	e852                	sd	s4,16(sp)
    80000fde:	e456                	sd	s5,8(sp)
    80000fe0:	e05a                	sd	s6,0(sp)
    80000fe2:	0080                	addi	s0,sp,64
    80000fe4:	84aa                	mv	s1,a0
    80000fe6:	89ae                	mv	s3,a1
    80000fe8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fea:	57fd                	li	a5,-1
    80000fec:	83e9                	srli	a5,a5,0x1a
    80000fee:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff2:	04b7f263          	bgeu	a5,a1,80001036 <walk+0x66>
    panic("walk");
    80000ff6:	00007517          	auipc	a0,0x7
    80000ffa:	0da50513          	addi	a0,a0,218 # 800080d0 <digits+0x90>
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	540080e7          	jalr	1344(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001006:	060a8663          	beqz	s5,80001072 <walk+0xa2>
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	aea080e7          	jalr	-1302(ra) # 80000af4 <kalloc>
    80001012:	84aa                	mv	s1,a0
    80001014:	c529                	beqz	a0,8000105e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001016:	6605                	lui	a2,0x1
    80001018:	4581                	li	a1,0
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	cc6080e7          	jalr	-826(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001022:	00c4d793          	srli	a5,s1,0xc
    80001026:	07aa                	slli	a5,a5,0xa
    80001028:	0017e793          	ori	a5,a5,1
    8000102c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001030:	3a5d                	addiw	s4,s4,-9
    80001032:	036a0063          	beq	s4,s6,80001052 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001036:	0149d933          	srl	s2,s3,s4
    8000103a:	1ff97913          	andi	s2,s2,511
    8000103e:	090e                	slli	s2,s2,0x3
    80001040:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001042:	00093483          	ld	s1,0(s2)
    80001046:	0014f793          	andi	a5,s1,1
    8000104a:	dfd5                	beqz	a5,80001006 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104c:	80a9                	srli	s1,s1,0xa
    8000104e:	04b2                	slli	s1,s1,0xc
    80001050:	b7c5                	j	80001030 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001052:	00c9d513          	srli	a0,s3,0xc
    80001056:	1ff57513          	andi	a0,a0,511
    8000105a:	050e                	slli	a0,a0,0x3
    8000105c:	9526                	add	a0,a0,s1
}
    8000105e:	70e2                	ld	ra,56(sp)
    80001060:	7442                	ld	s0,48(sp)
    80001062:	74a2                	ld	s1,40(sp)
    80001064:	7902                	ld	s2,32(sp)
    80001066:	69e2                	ld	s3,24(sp)
    80001068:	6a42                	ld	s4,16(sp)
    8000106a:	6aa2                	ld	s5,8(sp)
    8000106c:	6b02                	ld	s6,0(sp)
    8000106e:	6121                	addi	sp,sp,64
    80001070:	8082                	ret
        return 0;
    80001072:	4501                	li	a0,0
    80001074:	b7ed                	j	8000105e <walk+0x8e>

0000000080001076 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001076:	57fd                	li	a5,-1
    80001078:	83e9                	srli	a5,a5,0x1a
    8000107a:	00b7f463          	bgeu	a5,a1,80001082 <walkaddr+0xc>
    return 0;
    8000107e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001080:	8082                	ret
{
    80001082:	1141                	addi	sp,sp,-16
    80001084:	e406                	sd	ra,8(sp)
    80001086:	e022                	sd	s0,0(sp)
    80001088:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108a:	4601                	li	a2,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	f44080e7          	jalr	-188(ra) # 80000fd0 <walk>
  if(pte == 0)
    80001094:	c105                	beqz	a0,800010b4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001096:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001098:	0117f693          	andi	a3,a5,17
    8000109c:	4745                	li	a4,17
    return 0;
    8000109e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a0:	00e68663          	beq	a3,a4,800010ac <walkaddr+0x36>
}
    800010a4:	60a2                	ld	ra,8(sp)
    800010a6:	6402                	ld	s0,0(sp)
    800010a8:	0141                	addi	sp,sp,16
    800010aa:	8082                	ret
  pa = PTE2PA(*pte);
    800010ac:	00a7d513          	srli	a0,a5,0xa
    800010b0:	0532                	slli	a0,a0,0xc
  return pa;
    800010b2:	bfcd                	j	800010a4 <walkaddr+0x2e>
    return 0;
    800010b4:	4501                	li	a0,0
    800010b6:	b7fd                	j	800010a4 <walkaddr+0x2e>

00000000800010b8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b8:	715d                	addi	sp,sp,-80
    800010ba:	e486                	sd	ra,72(sp)
    800010bc:	e0a2                	sd	s0,64(sp)
    800010be:	fc26                	sd	s1,56(sp)
    800010c0:	f84a                	sd	s2,48(sp)
    800010c2:	f44e                	sd	s3,40(sp)
    800010c4:	f052                	sd	s4,32(sp)
    800010c6:	ec56                	sd	s5,24(sp)
    800010c8:	e85a                	sd	s6,16(sp)
    800010ca:	e45e                	sd	s7,8(sp)
    800010cc:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ce:	c205                	beqz	a2,800010ee <mappages+0x36>
    800010d0:	8aaa                	mv	s5,a0
    800010d2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d4:	77fd                	lui	a5,0xfffff
    800010d6:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010da:	15fd                	addi	a1,a1,-1
    800010dc:	00c589b3          	add	s3,a1,a2
    800010e0:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e4:	8952                	mv	s2,s4
    800010e6:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ea:	6b85                	lui	s7,0x1
    800010ec:	a015                	j	80001110 <mappages+0x58>
    panic("mappages: size");
    800010ee:	00007517          	auipc	a0,0x7
    800010f2:	fea50513          	addi	a0,a0,-22 # 800080d8 <digits+0x98>
    800010f6:	fffff097          	auipc	ra,0xfffff
    800010fa:	448080e7          	jalr	1096(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010fe:	00007517          	auipc	a0,0x7
    80001102:	fea50513          	addi	a0,a0,-22 # 800080e8 <digits+0xa8>
    80001106:	fffff097          	auipc	ra,0xfffff
    8000110a:	438080e7          	jalr	1080(ra) # 8000053e <panic>
    a += PGSIZE;
    8000110e:	995e                	add	s2,s2,s7
  for(;;){
    80001110:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001114:	4605                	li	a2,1
    80001116:	85ca                	mv	a1,s2
    80001118:	8556                	mv	a0,s5
    8000111a:	00000097          	auipc	ra,0x0
    8000111e:	eb6080e7          	jalr	-330(ra) # 80000fd0 <walk>
    80001122:	cd19                	beqz	a0,80001140 <mappages+0x88>
    if(*pte & PTE_V)
    80001124:	611c                	ld	a5,0(a0)
    80001126:	8b85                	andi	a5,a5,1
    80001128:	fbf9                	bnez	a5,800010fe <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112a:	80b1                	srli	s1,s1,0xc
    8000112c:	04aa                	slli	s1,s1,0xa
    8000112e:	0164e4b3          	or	s1,s1,s6
    80001132:	0014e493          	ori	s1,s1,1
    80001136:	e104                	sd	s1,0(a0)
    if(a == last)
    80001138:	fd391be3          	bne	s2,s3,8000110e <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113c:	4501                	li	a0,0
    8000113e:	a011                	j	80001142 <mappages+0x8a>
      return -1;
    80001140:	557d                	li	a0,-1
}
    80001142:	60a6                	ld	ra,72(sp)
    80001144:	6406                	ld	s0,64(sp)
    80001146:	74e2                	ld	s1,56(sp)
    80001148:	7942                	ld	s2,48(sp)
    8000114a:	79a2                	ld	s3,40(sp)
    8000114c:	7a02                	ld	s4,32(sp)
    8000114e:	6ae2                	ld	s5,24(sp)
    80001150:	6b42                	ld	s6,16(sp)
    80001152:	6ba2                	ld	s7,8(sp)
    80001154:	6161                	addi	sp,sp,80
    80001156:	8082                	ret

0000000080001158 <kvmmap>:
{
    80001158:	1141                	addi	sp,sp,-16
    8000115a:	e406                	sd	ra,8(sp)
    8000115c:	e022                	sd	s0,0(sp)
    8000115e:	0800                	addi	s0,sp,16
    80001160:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001162:	86b2                	mv	a3,a2
    80001164:	863e                	mv	a2,a5
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	f52080e7          	jalr	-174(ra) # 800010b8 <mappages>
    8000116e:	e509                	bnez	a0,80001178 <kvmmap+0x20>
}
    80001170:	60a2                	ld	ra,8(sp)
    80001172:	6402                	ld	s0,0(sp)
    80001174:	0141                	addi	sp,sp,16
    80001176:	8082                	ret
    panic("kvmmap");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f8050513          	addi	a0,a0,-128 # 800080f8 <digits+0xb8>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3be080e7          	jalr	958(ra) # 8000053e <panic>

0000000080001188 <kvmmake>:
{
    80001188:	1101                	addi	sp,sp,-32
    8000118a:	ec06                	sd	ra,24(sp)
    8000118c:	e822                	sd	s0,16(sp)
    8000118e:	e426                	sd	s1,8(sp)
    80001190:	e04a                	sd	s2,0(sp)
    80001192:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001194:	00000097          	auipc	ra,0x0
    80001198:	960080e7          	jalr	-1696(ra) # 80000af4 <kalloc>
    8000119c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000119e:	6605                	lui	a2,0x1
    800011a0:	4581                	li	a1,0
    800011a2:	00000097          	auipc	ra,0x0
    800011a6:	b3e080e7          	jalr	-1218(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011aa:	4719                	li	a4,6
    800011ac:	6685                	lui	a3,0x1
    800011ae:	10000637          	lui	a2,0x10000
    800011b2:	100005b7          	lui	a1,0x10000
    800011b6:	8526                	mv	a0,s1
    800011b8:	00000097          	auipc	ra,0x0
    800011bc:	fa0080e7          	jalr	-96(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c0:	4719                	li	a4,6
    800011c2:	6685                	lui	a3,0x1
    800011c4:	10001637          	lui	a2,0x10001
    800011c8:	100015b7          	lui	a1,0x10001
    800011cc:	8526                	mv	a0,s1
    800011ce:	00000097          	auipc	ra,0x0
    800011d2:	f8a080e7          	jalr	-118(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d6:	4719                	li	a4,6
    800011d8:	004006b7          	lui	a3,0x400
    800011dc:	0c000637          	lui	a2,0xc000
    800011e0:	0c0005b7          	lui	a1,0xc000
    800011e4:	8526                	mv	a0,s1
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	f72080e7          	jalr	-142(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ee:	00007917          	auipc	s2,0x7
    800011f2:	e1290913          	addi	s2,s2,-494 # 80008000 <etext>
    800011f6:	4729                	li	a4,10
    800011f8:	80007697          	auipc	a3,0x80007
    800011fc:	e0868693          	addi	a3,a3,-504 # 8000 <_entry-0x7fff8000>
    80001200:	4605                	li	a2,1
    80001202:	067e                	slli	a2,a2,0x1f
    80001204:	85b2                	mv	a1,a2
    80001206:	8526                	mv	a0,s1
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	f50080e7          	jalr	-176(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001210:	4719                	li	a4,6
    80001212:	46c5                	li	a3,17
    80001214:	06ee                	slli	a3,a3,0x1b
    80001216:	412686b3          	sub	a3,a3,s2
    8000121a:	864a                	mv	a2,s2
    8000121c:	85ca                	mv	a1,s2
    8000121e:	8526                	mv	a0,s1
    80001220:	00000097          	auipc	ra,0x0
    80001224:	f38080e7          	jalr	-200(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001228:	4729                	li	a4,10
    8000122a:	6685                	lui	a3,0x1
    8000122c:	00006617          	auipc	a2,0x6
    80001230:	dd460613          	addi	a2,a2,-556 # 80007000 <_trampoline>
    80001234:	040005b7          	lui	a1,0x4000
    80001238:	15fd                	addi	a1,a1,-1
    8000123a:	05b2                	slli	a1,a1,0xc
    8000123c:	8526                	mv	a0,s1
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f1a080e7          	jalr	-230(ra) # 80001158 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	60a080e7          	jalr	1546(ra) # 80001852 <proc_mapstacks>
}
    80001250:	8526                	mv	a0,s1
    80001252:	60e2                	ld	ra,24(sp)
    80001254:	6442                	ld	s0,16(sp)
    80001256:	64a2                	ld	s1,8(sp)
    80001258:	6902                	ld	s2,0(sp)
    8000125a:	6105                	addi	sp,sp,32
    8000125c:	8082                	ret

000000008000125e <kvminit>:
{
    8000125e:	1141                	addi	sp,sp,-16
    80001260:	e406                	sd	ra,8(sp)
    80001262:	e022                	sd	s0,0(sp)
    80001264:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f22080e7          	jalr	-222(ra) # 80001188 <kvmmake>
    8000126e:	00008797          	auipc	a5,0x8
    80001272:	daa7b923          	sd	a0,-590(a5) # 80009020 <kernel_pagetable>
}
    80001276:	60a2                	ld	ra,8(sp)
    80001278:	6402                	ld	s0,0(sp)
    8000127a:	0141                	addi	sp,sp,16
    8000127c:	8082                	ret

000000008000127e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000127e:	715d                	addi	sp,sp,-80
    80001280:	e486                	sd	ra,72(sp)
    80001282:	e0a2                	sd	s0,64(sp)
    80001284:	fc26                	sd	s1,56(sp)
    80001286:	f84a                	sd	s2,48(sp)
    80001288:	f44e                	sd	s3,40(sp)
    8000128a:	f052                	sd	s4,32(sp)
    8000128c:	ec56                	sd	s5,24(sp)
    8000128e:	e85a                	sd	s6,16(sp)
    80001290:	e45e                	sd	s7,8(sp)
    80001292:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001294:	03459793          	slli	a5,a1,0x34
    80001298:	e795                	bnez	a5,800012c4 <uvmunmap+0x46>
    8000129a:	8a2a                	mv	s4,a0
    8000129c:	892e                	mv	s2,a1
    8000129e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	0632                	slli	a2,a2,0xc
    800012a2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a8:	6b05                	lui	s6,0x1
    800012aa:	0735e863          	bltu	a1,s3,8000131a <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012ae:	60a6                	ld	ra,72(sp)
    800012b0:	6406                	ld	s0,64(sp)
    800012b2:	74e2                	ld	s1,56(sp)
    800012b4:	7942                	ld	s2,48(sp)
    800012b6:	79a2                	ld	s3,40(sp)
    800012b8:	7a02                	ld	s4,32(sp)
    800012ba:	6ae2                	ld	s5,24(sp)
    800012bc:	6b42                	ld	s6,16(sp)
    800012be:	6ba2                	ld	s7,8(sp)
    800012c0:	6161                	addi	sp,sp,80
    800012c2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e3c50513          	addi	a0,a0,-452 # 80008100 <digits+0xc0>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	272080e7          	jalr	626(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012d4:	00007517          	auipc	a0,0x7
    800012d8:	e4450513          	addi	a0,a0,-444 # 80008118 <digits+0xd8>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012e4:	00007517          	auipc	a0,0x7
    800012e8:	e4450513          	addi	a0,a0,-444 # 80008128 <digits+0xe8>
    800012ec:	fffff097          	auipc	ra,0xfffff
    800012f0:	252080e7          	jalr	594(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012f4:	00007517          	auipc	a0,0x7
    800012f8:	e4c50513          	addi	a0,a0,-436 # 80008140 <digits+0x100>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	242080e7          	jalr	578(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001304:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001306:	0532                	slli	a0,a0,0xc
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	6f0080e7          	jalr	1776(ra) # 800009f8 <kfree>
    *pte = 0;
    80001310:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001314:	995a                	add	s2,s2,s6
    80001316:	f9397ce3          	bgeu	s2,s3,800012ae <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131a:	4601                	li	a2,0
    8000131c:	85ca                	mv	a1,s2
    8000131e:	8552                	mv	a0,s4
    80001320:	00000097          	auipc	ra,0x0
    80001324:	cb0080e7          	jalr	-848(ra) # 80000fd0 <walk>
    80001328:	84aa                	mv	s1,a0
    8000132a:	d54d                	beqz	a0,800012d4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132c:	6108                	ld	a0,0(a0)
    8000132e:	00157793          	andi	a5,a0,1
    80001332:	dbcd                	beqz	a5,800012e4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001334:	3ff57793          	andi	a5,a0,1023
    80001338:	fb778ee3          	beq	a5,s7,800012f4 <uvmunmap+0x76>
    if(do_free){
    8000133c:	fc0a8ae3          	beqz	s5,80001310 <uvmunmap+0x92>
    80001340:	b7d1                	j	80001304 <uvmunmap+0x86>

0000000080001342 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001342:	1101                	addi	sp,sp,-32
    80001344:	ec06                	sd	ra,24(sp)
    80001346:	e822                	sd	s0,16(sp)
    80001348:	e426                	sd	s1,8(sp)
    8000134a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	7a8080e7          	jalr	1960(ra) # 80000af4 <kalloc>
    80001354:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001356:	c519                	beqz	a0,80001364 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001358:	6605                	lui	a2,0x1
    8000135a:	4581                	li	a1,0
    8000135c:	00000097          	auipc	ra,0x0
    80001360:	984080e7          	jalr	-1660(ra) # 80000ce0 <memset>
  return pagetable;
}
    80001364:	8526                	mv	a0,s1
    80001366:	60e2                	ld	ra,24(sp)
    80001368:	6442                	ld	s0,16(sp)
    8000136a:	64a2                	ld	s1,8(sp)
    8000136c:	6105                	addi	sp,sp,32
    8000136e:	8082                	ret

0000000080001370 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001370:	7179                	addi	sp,sp,-48
    80001372:	f406                	sd	ra,40(sp)
    80001374:	f022                	sd	s0,32(sp)
    80001376:	ec26                	sd	s1,24(sp)
    80001378:	e84a                	sd	s2,16(sp)
    8000137a:	e44e                	sd	s3,8(sp)
    8000137c:	e052                	sd	s4,0(sp)
    8000137e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001380:	6785                	lui	a5,0x1
    80001382:	04f67863          	bgeu	a2,a5,800013d2 <uvminit+0x62>
    80001386:	8a2a                	mv	s4,a0
    80001388:	89ae                	mv	s3,a1
    8000138a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000138c:	fffff097          	auipc	ra,0xfffff
    80001390:	768080e7          	jalr	1896(ra) # 80000af4 <kalloc>
    80001394:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001396:	6605                	lui	a2,0x1
    80001398:	4581                	li	a1,0
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	946080e7          	jalr	-1722(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a2:	4779                	li	a4,30
    800013a4:	86ca                	mv	a3,s2
    800013a6:	6605                	lui	a2,0x1
    800013a8:	4581                	li	a1,0
    800013aa:	8552                	mv	a0,s4
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	d0c080e7          	jalr	-756(ra) # 800010b8 <mappages>
  memmove(mem, src, sz);
    800013b4:	8626                	mv	a2,s1
    800013b6:	85ce                	mv	a1,s3
    800013b8:	854a                	mv	a0,s2
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	986080e7          	jalr	-1658(ra) # 80000d40 <memmove>
}
    800013c2:	70a2                	ld	ra,40(sp)
    800013c4:	7402                	ld	s0,32(sp)
    800013c6:	64e2                	ld	s1,24(sp)
    800013c8:	6942                	ld	s2,16(sp)
    800013ca:	69a2                	ld	s3,8(sp)
    800013cc:	6a02                	ld	s4,0(sp)
    800013ce:	6145                	addi	sp,sp,48
    800013d0:	8082                	ret
    panic("inituvm: more than a page");
    800013d2:	00007517          	auipc	a0,0x7
    800013d6:	d8650513          	addi	a0,a0,-634 # 80008158 <digits+0x118>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	164080e7          	jalr	356(ra) # 8000053e <panic>

00000000800013e2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e2:	1101                	addi	sp,sp,-32
    800013e4:	ec06                	sd	ra,24(sp)
    800013e6:	e822                	sd	s0,16(sp)
    800013e8:	e426                	sd	s1,8(sp)
    800013ea:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ec:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ee:	00b67d63          	bgeu	a2,a1,80001408 <uvmdealloc+0x26>
    800013f2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f4:	6785                	lui	a5,0x1
    800013f6:	17fd                	addi	a5,a5,-1
    800013f8:	00f60733          	add	a4,a2,a5
    800013fc:	767d                	lui	a2,0xfffff
    800013fe:	8f71                	and	a4,a4,a2
    80001400:	97ae                	add	a5,a5,a1
    80001402:	8ff1                	and	a5,a5,a2
    80001404:	00f76863          	bltu	a4,a5,80001414 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001408:	8526                	mv	a0,s1
    8000140a:	60e2                	ld	ra,24(sp)
    8000140c:	6442                	ld	s0,16(sp)
    8000140e:	64a2                	ld	s1,8(sp)
    80001410:	6105                	addi	sp,sp,32
    80001412:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001414:	8f99                	sub	a5,a5,a4
    80001416:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001418:	4685                	li	a3,1
    8000141a:	0007861b          	sext.w	a2,a5
    8000141e:	85ba                	mv	a1,a4
    80001420:	00000097          	auipc	ra,0x0
    80001424:	e5e080e7          	jalr	-418(ra) # 8000127e <uvmunmap>
    80001428:	b7c5                	j	80001408 <uvmdealloc+0x26>

000000008000142a <uvmalloc>:
  if(newsz < oldsz)
    8000142a:	0ab66163          	bltu	a2,a1,800014cc <uvmalloc+0xa2>
{
    8000142e:	7139                	addi	sp,sp,-64
    80001430:	fc06                	sd	ra,56(sp)
    80001432:	f822                	sd	s0,48(sp)
    80001434:	f426                	sd	s1,40(sp)
    80001436:	f04a                	sd	s2,32(sp)
    80001438:	ec4e                	sd	s3,24(sp)
    8000143a:	e852                	sd	s4,16(sp)
    8000143c:	e456                	sd	s5,8(sp)
    8000143e:	0080                	addi	s0,sp,64
    80001440:	8aaa                	mv	s5,a0
    80001442:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001444:	6985                	lui	s3,0x1
    80001446:	19fd                	addi	s3,s3,-1
    80001448:	95ce                	add	a1,a1,s3
    8000144a:	79fd                	lui	s3,0xfffff
    8000144c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001450:	08c9f063          	bgeu	s3,a2,800014d0 <uvmalloc+0xa6>
    80001454:	894e                	mv	s2,s3
    mem = kalloc();
    80001456:	fffff097          	auipc	ra,0xfffff
    8000145a:	69e080e7          	jalr	1694(ra) # 80000af4 <kalloc>
    8000145e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001460:	c51d                	beqz	a0,8000148e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	87a080e7          	jalr	-1926(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000146e:	4779                	li	a4,30
    80001470:	86a6                	mv	a3,s1
    80001472:	6605                	lui	a2,0x1
    80001474:	85ca                	mv	a1,s2
    80001476:	8556                	mv	a0,s5
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	c40080e7          	jalr	-960(ra) # 800010b8 <mappages>
    80001480:	e905                	bnez	a0,800014b0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001482:	6785                	lui	a5,0x1
    80001484:	993e                	add	s2,s2,a5
    80001486:	fd4968e3          	bltu	s2,s4,80001456 <uvmalloc+0x2c>
  return newsz;
    8000148a:	8552                	mv	a0,s4
    8000148c:	a809                	j	8000149e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000148e:	864e                	mv	a2,s3
    80001490:	85ca                	mv	a1,s2
    80001492:	8556                	mv	a0,s5
    80001494:	00000097          	auipc	ra,0x0
    80001498:	f4e080e7          	jalr	-178(ra) # 800013e2 <uvmdealloc>
      return 0;
    8000149c:	4501                	li	a0,0
}
    8000149e:	70e2                	ld	ra,56(sp)
    800014a0:	7442                	ld	s0,48(sp)
    800014a2:	74a2                	ld	s1,40(sp)
    800014a4:	7902                	ld	s2,32(sp)
    800014a6:	69e2                	ld	s3,24(sp)
    800014a8:	6a42                	ld	s4,16(sp)
    800014aa:	6aa2                	ld	s5,8(sp)
    800014ac:	6121                	addi	sp,sp,64
    800014ae:	8082                	ret
      kfree(mem);
    800014b0:	8526                	mv	a0,s1
    800014b2:	fffff097          	auipc	ra,0xfffff
    800014b6:	546080e7          	jalr	1350(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ba:	864e                	mv	a2,s3
    800014bc:	85ca                	mv	a1,s2
    800014be:	8556                	mv	a0,s5
    800014c0:	00000097          	auipc	ra,0x0
    800014c4:	f22080e7          	jalr	-222(ra) # 800013e2 <uvmdealloc>
      return 0;
    800014c8:	4501                	li	a0,0
    800014ca:	bfd1                	j	8000149e <uvmalloc+0x74>
    return oldsz;
    800014cc:	852e                	mv	a0,a1
}
    800014ce:	8082                	ret
  return newsz;
    800014d0:	8532                	mv	a0,a2
    800014d2:	b7f1                	j	8000149e <uvmalloc+0x74>

00000000800014d4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014d4:	7179                	addi	sp,sp,-48
    800014d6:	f406                	sd	ra,40(sp)
    800014d8:	f022                	sd	s0,32(sp)
    800014da:	ec26                	sd	s1,24(sp)
    800014dc:	e84a                	sd	s2,16(sp)
    800014de:	e44e                	sd	s3,8(sp)
    800014e0:	e052                	sd	s4,0(sp)
    800014e2:	1800                	addi	s0,sp,48
    800014e4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014e6:	84aa                	mv	s1,a0
    800014e8:	6905                	lui	s2,0x1
    800014ea:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014ec:	4985                	li	s3,1
    800014ee:	a821                	j	80001506 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f0:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014f2:	0532                	slli	a0,a0,0xc
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	fe0080e7          	jalr	-32(ra) # 800014d4 <freewalk>
      pagetable[i] = 0;
    800014fc:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001500:	04a1                	addi	s1,s1,8
    80001502:	03248163          	beq	s1,s2,80001524 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001506:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001508:	00f57793          	andi	a5,a0,15
    8000150c:	ff3782e3          	beq	a5,s3,800014f0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001510:	8905                	andi	a0,a0,1
    80001512:	d57d                	beqz	a0,80001500 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001514:	00007517          	auipc	a0,0x7
    80001518:	c6450513          	addi	a0,a0,-924 # 80008178 <digits+0x138>
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	022080e7          	jalr	34(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001524:	8552                	mv	a0,s4
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	4d2080e7          	jalr	1234(ra) # 800009f8 <kfree>
}
    8000152e:	70a2                	ld	ra,40(sp)
    80001530:	7402                	ld	s0,32(sp)
    80001532:	64e2                	ld	s1,24(sp)
    80001534:	6942                	ld	s2,16(sp)
    80001536:	69a2                	ld	s3,8(sp)
    80001538:	6a02                	ld	s4,0(sp)
    8000153a:	6145                	addi	sp,sp,48
    8000153c:	8082                	ret

000000008000153e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000153e:	1101                	addi	sp,sp,-32
    80001540:	ec06                	sd	ra,24(sp)
    80001542:	e822                	sd	s0,16(sp)
    80001544:	e426                	sd	s1,8(sp)
    80001546:	1000                	addi	s0,sp,32
    80001548:	84aa                	mv	s1,a0
  if(sz > 0)
    8000154a:	e999                	bnez	a1,80001560 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000154c:	8526                	mv	a0,s1
    8000154e:	00000097          	auipc	ra,0x0
    80001552:	f86080e7          	jalr	-122(ra) # 800014d4 <freewalk>
}
    80001556:	60e2                	ld	ra,24(sp)
    80001558:	6442                	ld	s0,16(sp)
    8000155a:	64a2                	ld	s1,8(sp)
    8000155c:	6105                	addi	sp,sp,32
    8000155e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001560:	6605                	lui	a2,0x1
    80001562:	167d                	addi	a2,a2,-1
    80001564:	962e                	add	a2,a2,a1
    80001566:	4685                	li	a3,1
    80001568:	8231                	srli	a2,a2,0xc
    8000156a:	4581                	li	a1,0
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	d12080e7          	jalr	-750(ra) # 8000127e <uvmunmap>
    80001574:	bfe1                	j	8000154c <uvmfree+0xe>

0000000080001576 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001576:	c679                	beqz	a2,80001644 <uvmcopy+0xce>
{
    80001578:	715d                	addi	sp,sp,-80
    8000157a:	e486                	sd	ra,72(sp)
    8000157c:	e0a2                	sd	s0,64(sp)
    8000157e:	fc26                	sd	s1,56(sp)
    80001580:	f84a                	sd	s2,48(sp)
    80001582:	f44e                	sd	s3,40(sp)
    80001584:	f052                	sd	s4,32(sp)
    80001586:	ec56                	sd	s5,24(sp)
    80001588:	e85a                	sd	s6,16(sp)
    8000158a:	e45e                	sd	s7,8(sp)
    8000158c:	0880                	addi	s0,sp,80
    8000158e:	8b2a                	mv	s6,a0
    80001590:	8aae                	mv	s5,a1
    80001592:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001594:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001596:	4601                	li	a2,0
    80001598:	85ce                	mv	a1,s3
    8000159a:	855a                	mv	a0,s6
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	a34080e7          	jalr	-1484(ra) # 80000fd0 <walk>
    800015a4:	c531                	beqz	a0,800015f0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015a6:	6118                	ld	a4,0(a0)
    800015a8:	00177793          	andi	a5,a4,1
    800015ac:	cbb1                	beqz	a5,80001600 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ae:	00a75593          	srli	a1,a4,0xa
    800015b2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015b6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	53a080e7          	jalr	1338(ra) # 80000af4 <kalloc>
    800015c2:	892a                	mv	s2,a0
    800015c4:	c939                	beqz	a0,8000161a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015c6:	6605                	lui	a2,0x1
    800015c8:	85de                	mv	a1,s7
    800015ca:	fffff097          	auipc	ra,0xfffff
    800015ce:	776080e7          	jalr	1910(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015d2:	8726                	mv	a4,s1
    800015d4:	86ca                	mv	a3,s2
    800015d6:	6605                	lui	a2,0x1
    800015d8:	85ce                	mv	a1,s3
    800015da:	8556                	mv	a0,s5
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	adc080e7          	jalr	-1316(ra) # 800010b8 <mappages>
    800015e4:	e515                	bnez	a0,80001610 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015e6:	6785                	lui	a5,0x1
    800015e8:	99be                	add	s3,s3,a5
    800015ea:	fb49e6e3          	bltu	s3,s4,80001596 <uvmcopy+0x20>
    800015ee:	a081                	j	8000162e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015f0:	00007517          	auipc	a0,0x7
    800015f4:	b9850513          	addi	a0,a0,-1128 # 80008188 <digits+0x148>
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001600:	00007517          	auipc	a0,0x7
    80001604:	ba850513          	addi	a0,a0,-1112 # 800081a8 <digits+0x168>
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	f36080e7          	jalr	-202(ra) # 8000053e <panic>
      kfree(mem);
    80001610:	854a                	mv	a0,s2
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	3e6080e7          	jalr	998(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000161a:	4685                	li	a3,1
    8000161c:	00c9d613          	srli	a2,s3,0xc
    80001620:	4581                	li	a1,0
    80001622:	8556                	mv	a0,s5
    80001624:	00000097          	auipc	ra,0x0
    80001628:	c5a080e7          	jalr	-934(ra) # 8000127e <uvmunmap>
  return -1;
    8000162c:	557d                	li	a0,-1
}
    8000162e:	60a6                	ld	ra,72(sp)
    80001630:	6406                	ld	s0,64(sp)
    80001632:	74e2                	ld	s1,56(sp)
    80001634:	7942                	ld	s2,48(sp)
    80001636:	79a2                	ld	s3,40(sp)
    80001638:	7a02                	ld	s4,32(sp)
    8000163a:	6ae2                	ld	s5,24(sp)
    8000163c:	6b42                	ld	s6,16(sp)
    8000163e:	6ba2                	ld	s7,8(sp)
    80001640:	6161                	addi	sp,sp,80
    80001642:	8082                	ret
  return 0;
    80001644:	4501                	li	a0,0
}
    80001646:	8082                	ret

0000000080001648 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001648:	1141                	addi	sp,sp,-16
    8000164a:	e406                	sd	ra,8(sp)
    8000164c:	e022                	sd	s0,0(sp)
    8000164e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001650:	4601                	li	a2,0
    80001652:	00000097          	auipc	ra,0x0
    80001656:	97e080e7          	jalr	-1666(ra) # 80000fd0 <walk>
  if(pte == 0)
    8000165a:	c901                	beqz	a0,8000166a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000165c:	611c                	ld	a5,0(a0)
    8000165e:	9bbd                	andi	a5,a5,-17
    80001660:	e11c                	sd	a5,0(a0)
}
    80001662:	60a2                	ld	ra,8(sp)
    80001664:	6402                	ld	s0,0(sp)
    80001666:	0141                	addi	sp,sp,16
    80001668:	8082                	ret
    panic("uvmclear");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b5e50513          	addi	a0,a0,-1186 # 800081c8 <digits+0x188>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ecc080e7          	jalr	-308(ra) # 8000053e <panic>

000000008000167a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000167a:	c6bd                	beqz	a3,800016e8 <copyout+0x6e>
{
    8000167c:	715d                	addi	sp,sp,-80
    8000167e:	e486                	sd	ra,72(sp)
    80001680:	e0a2                	sd	s0,64(sp)
    80001682:	fc26                	sd	s1,56(sp)
    80001684:	f84a                	sd	s2,48(sp)
    80001686:	f44e                	sd	s3,40(sp)
    80001688:	f052                	sd	s4,32(sp)
    8000168a:	ec56                	sd	s5,24(sp)
    8000168c:	e85a                	sd	s6,16(sp)
    8000168e:	e45e                	sd	s7,8(sp)
    80001690:	e062                	sd	s8,0(sp)
    80001692:	0880                	addi	s0,sp,80
    80001694:	8b2a                	mv	s6,a0
    80001696:	8c2e                	mv	s8,a1
    80001698:	8a32                	mv	s4,a2
    8000169a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000169c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000169e:	6a85                	lui	s5,0x1
    800016a0:	a015                	j	800016c4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016a2:	9562                	add	a0,a0,s8
    800016a4:	0004861b          	sext.w	a2,s1
    800016a8:	85d2                	mv	a1,s4
    800016aa:	41250533          	sub	a0,a0,s2
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	692080e7          	jalr	1682(ra) # 80000d40 <memmove>

    len -= n;
    800016b6:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ba:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016bc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016c0:	02098263          	beqz	s3,800016e4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016c4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c8:	85ca                	mv	a1,s2
    800016ca:	855a                	mv	a0,s6
    800016cc:	00000097          	auipc	ra,0x0
    800016d0:	9aa080e7          	jalr	-1622(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800016d4:	cd01                	beqz	a0,800016ec <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016d6:	418904b3          	sub	s1,s2,s8
    800016da:	94d6                	add	s1,s1,s5
    if(n > len)
    800016dc:	fc99f3e3          	bgeu	s3,s1,800016a2 <copyout+0x28>
    800016e0:	84ce                	mv	s1,s3
    800016e2:	b7c1                	j	800016a2 <copyout+0x28>
  }
  return 0;
    800016e4:	4501                	li	a0,0
    800016e6:	a021                	j	800016ee <copyout+0x74>
    800016e8:	4501                	li	a0,0
}
    800016ea:	8082                	ret
      return -1;
    800016ec:	557d                	li	a0,-1
}
    800016ee:	60a6                	ld	ra,72(sp)
    800016f0:	6406                	ld	s0,64(sp)
    800016f2:	74e2                	ld	s1,56(sp)
    800016f4:	7942                	ld	s2,48(sp)
    800016f6:	79a2                	ld	s3,40(sp)
    800016f8:	7a02                	ld	s4,32(sp)
    800016fa:	6ae2                	ld	s5,24(sp)
    800016fc:	6b42                	ld	s6,16(sp)
    800016fe:	6ba2                	ld	s7,8(sp)
    80001700:	6c02                	ld	s8,0(sp)
    80001702:	6161                	addi	sp,sp,80
    80001704:	8082                	ret

0000000080001706 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001706:	c6bd                	beqz	a3,80001774 <copyin+0x6e>
{
    80001708:	715d                	addi	sp,sp,-80
    8000170a:	e486                	sd	ra,72(sp)
    8000170c:	e0a2                	sd	s0,64(sp)
    8000170e:	fc26                	sd	s1,56(sp)
    80001710:	f84a                	sd	s2,48(sp)
    80001712:	f44e                	sd	s3,40(sp)
    80001714:	f052                	sd	s4,32(sp)
    80001716:	ec56                	sd	s5,24(sp)
    80001718:	e85a                	sd	s6,16(sp)
    8000171a:	e45e                	sd	s7,8(sp)
    8000171c:	e062                	sd	s8,0(sp)
    8000171e:	0880                	addi	s0,sp,80
    80001720:	8b2a                	mv	s6,a0
    80001722:	8a2e                	mv	s4,a1
    80001724:	8c32                	mv	s8,a2
    80001726:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001728:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000172a:	6a85                	lui	s5,0x1
    8000172c:	a015                	j	80001750 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000172e:	9562                	add	a0,a0,s8
    80001730:	0004861b          	sext.w	a2,s1
    80001734:	412505b3          	sub	a1,a0,s2
    80001738:	8552                	mv	a0,s4
    8000173a:	fffff097          	auipc	ra,0xfffff
    8000173e:	606080e7          	jalr	1542(ra) # 80000d40 <memmove>

    len -= n;
    80001742:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001746:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001748:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000174c:	02098263          	beqz	s3,80001770 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001750:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001754:	85ca                	mv	a1,s2
    80001756:	855a                	mv	a0,s6
    80001758:	00000097          	auipc	ra,0x0
    8000175c:	91e080e7          	jalr	-1762(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001760:	cd01                	beqz	a0,80001778 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001762:	418904b3          	sub	s1,s2,s8
    80001766:	94d6                	add	s1,s1,s5
    if(n > len)
    80001768:	fc99f3e3          	bgeu	s3,s1,8000172e <copyin+0x28>
    8000176c:	84ce                	mv	s1,s3
    8000176e:	b7c1                	j	8000172e <copyin+0x28>
  }
  return 0;
    80001770:	4501                	li	a0,0
    80001772:	a021                	j	8000177a <copyin+0x74>
    80001774:	4501                	li	a0,0
}
    80001776:	8082                	ret
      return -1;
    80001778:	557d                	li	a0,-1
}
    8000177a:	60a6                	ld	ra,72(sp)
    8000177c:	6406                	ld	s0,64(sp)
    8000177e:	74e2                	ld	s1,56(sp)
    80001780:	7942                	ld	s2,48(sp)
    80001782:	79a2                	ld	s3,40(sp)
    80001784:	7a02                	ld	s4,32(sp)
    80001786:	6ae2                	ld	s5,24(sp)
    80001788:	6b42                	ld	s6,16(sp)
    8000178a:	6ba2                	ld	s7,8(sp)
    8000178c:	6c02                	ld	s8,0(sp)
    8000178e:	6161                	addi	sp,sp,80
    80001790:	8082                	ret

0000000080001792 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001792:	c6c5                	beqz	a3,8000183a <copyinstr+0xa8>
{
    80001794:	715d                	addi	sp,sp,-80
    80001796:	e486                	sd	ra,72(sp)
    80001798:	e0a2                	sd	s0,64(sp)
    8000179a:	fc26                	sd	s1,56(sp)
    8000179c:	f84a                	sd	s2,48(sp)
    8000179e:	f44e                	sd	s3,40(sp)
    800017a0:	f052                	sd	s4,32(sp)
    800017a2:	ec56                	sd	s5,24(sp)
    800017a4:	e85a                	sd	s6,16(sp)
    800017a6:	e45e                	sd	s7,8(sp)
    800017a8:	0880                	addi	s0,sp,80
    800017aa:	8a2a                	mv	s4,a0
    800017ac:	8b2e                	mv	s6,a1
    800017ae:	8bb2                	mv	s7,a2
    800017b0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017b2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017b4:	6985                	lui	s3,0x1
    800017b6:	a035                	j	800017e2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017bc:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017be:	0017b793          	seqz	a5,a5
    800017c2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017c6:	60a6                	ld	ra,72(sp)
    800017c8:	6406                	ld	s0,64(sp)
    800017ca:	74e2                	ld	s1,56(sp)
    800017cc:	7942                	ld	s2,48(sp)
    800017ce:	79a2                	ld	s3,40(sp)
    800017d0:	7a02                	ld	s4,32(sp)
    800017d2:	6ae2                	ld	s5,24(sp)
    800017d4:	6b42                	ld	s6,16(sp)
    800017d6:	6ba2                	ld	s7,8(sp)
    800017d8:	6161                	addi	sp,sp,80
    800017da:	8082                	ret
    srcva = va0 + PGSIZE;
    800017dc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017e0:	c8a9                	beqz	s1,80001832 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017e2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017e6:	85ca                	mv	a1,s2
    800017e8:	8552                	mv	a0,s4
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	88c080e7          	jalr	-1908(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800017f2:	c131                	beqz	a0,80001836 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017f4:	41790833          	sub	a6,s2,s7
    800017f8:	984e                	add	a6,a6,s3
    if(n > max)
    800017fa:	0104f363          	bgeu	s1,a6,80001800 <copyinstr+0x6e>
    800017fe:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001800:	955e                	add	a0,a0,s7
    80001802:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001806:	fc080be3          	beqz	a6,800017dc <copyinstr+0x4a>
    8000180a:	985a                	add	a6,a6,s6
    8000180c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000180e:	41650633          	sub	a2,a0,s6
    80001812:	14fd                	addi	s1,s1,-1
    80001814:	9b26                	add	s6,s6,s1
    80001816:	00f60733          	add	a4,a2,a5
    8000181a:	00074703          	lbu	a4,0(a4)
    8000181e:	df49                	beqz	a4,800017b8 <copyinstr+0x26>
        *dst = *p;
    80001820:	00e78023          	sb	a4,0(a5)
      --max;
    80001824:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001828:	0785                	addi	a5,a5,1
    while(n > 0){
    8000182a:	ff0796e3          	bne	a5,a6,80001816 <copyinstr+0x84>
      dst++;
    8000182e:	8b42                	mv	s6,a6
    80001830:	b775                	j	800017dc <copyinstr+0x4a>
    80001832:	4781                	li	a5,0
    80001834:	b769                	j	800017be <copyinstr+0x2c>
      return -1;
    80001836:	557d                	li	a0,-1
    80001838:	b779                	j	800017c6 <copyinstr+0x34>
  int got_null = 0;
    8000183a:	4781                	li	a5,0
  if(got_null){
    8000183c:	0017b793          	seqz	a5,a5
    80001840:	40f00533          	neg	a0,a5
}
    80001844:	8082                	ret

0000000080001846 <update_last_runnable_time>:
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

void 
update_last_runnable_time(struct proc *p){
    80001846:	1141                	addi	sp,sp,-16
    80001848:	e422                	sd	s0,8(sp)
    8000184a:	0800                	addi	s0,sp,16
  #ifdef FCFS
    p->last_runnable_time = ticks;
  #endif
}  
    8000184c:	6422                	ld	s0,8(sp)
    8000184e:	0141                	addi	sp,sp,16
    80001850:	8082                	ret

0000000080001852 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001852:	7139                	addi	sp,sp,-64
    80001854:	fc06                	sd	ra,56(sp)
    80001856:	f822                	sd	s0,48(sp)
    80001858:	f426                	sd	s1,40(sp)
    8000185a:	f04a                	sd	s2,32(sp)
    8000185c:	ec4e                	sd	s3,24(sp)
    8000185e:	e852                	sd	s4,16(sp)
    80001860:	e456                	sd	s5,8(sp)
    80001862:	e05a                	sd	s6,0(sp)
    80001864:	0080                	addi	s0,sp,64
    80001866:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001868:	00010497          	auipc	s1,0x10
    8000186c:	e6848493          	addi	s1,s1,-408 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001870:	8b26                	mv	s6,s1
    80001872:	00006a97          	auipc	s5,0x6
    80001876:	78ea8a93          	addi	s5,s5,1934 # 80008000 <etext>
    8000187a:	04000937          	lui	s2,0x4000
    8000187e:	197d                	addi	s2,s2,-1
    80001880:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001882:	00016a17          	auipc	s4,0x16
    80001886:	a4ea0a13          	addi	s4,s4,-1458 # 800172d0 <tickslock>
    char *pa = kalloc();
    8000188a:	fffff097          	auipc	ra,0xfffff
    8000188e:	26a080e7          	jalr	618(ra) # 80000af4 <kalloc>
    80001892:	862a                	mv	a2,a0
    if(pa == 0)
    80001894:	c131                	beqz	a0,800018d8 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001896:	416485b3          	sub	a1,s1,s6
    8000189a:	8591                	srai	a1,a1,0x4
    8000189c:	000ab783          	ld	a5,0(s5)
    800018a0:	02f585b3          	mul	a1,a1,a5
    800018a4:	2585                	addiw	a1,a1,1
    800018a6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018aa:	4719                	li	a4,6
    800018ac:	6685                	lui	a3,0x1
    800018ae:	40b905b3          	sub	a1,s2,a1
    800018b2:	854e                	mv	a0,s3
    800018b4:	00000097          	auipc	ra,0x0
    800018b8:	8a4080e7          	jalr	-1884(ra) # 80001158 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018bc:	17048493          	addi	s1,s1,368
    800018c0:	fd4495e3          	bne	s1,s4,8000188a <proc_mapstacks+0x38>
  }
}
    800018c4:	70e2                	ld	ra,56(sp)
    800018c6:	7442                	ld	s0,48(sp)
    800018c8:	74a2                	ld	s1,40(sp)
    800018ca:	7902                	ld	s2,32(sp)
    800018cc:	69e2                	ld	s3,24(sp)
    800018ce:	6a42                	ld	s4,16(sp)
    800018d0:	6aa2                	ld	s5,8(sp)
    800018d2:	6b02                	ld	s6,0(sp)
    800018d4:	6121                	addi	sp,sp,64
    800018d6:	8082                	ret
      panic("kalloc");
    800018d8:	00007517          	auipc	a0,0x7
    800018dc:	90050513          	addi	a0,a0,-1792 # 800081d8 <digits+0x198>
    800018e0:	fffff097          	auipc	ra,0xfffff
    800018e4:	c5e080e7          	jalr	-930(ra) # 8000053e <panic>

00000000800018e8 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018e8:	7139                	addi	sp,sp,-64
    800018ea:	fc06                	sd	ra,56(sp)
    800018ec:	f822                	sd	s0,48(sp)
    800018ee:	f426                	sd	s1,40(sp)
    800018f0:	f04a                	sd	s2,32(sp)
    800018f2:	ec4e                	sd	s3,24(sp)
    800018f4:	e852                	sd	s4,16(sp)
    800018f6:	e456                	sd	s5,8(sp)
    800018f8:	e05a                	sd	s6,0(sp)
    800018fa:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018fc:	00007597          	auipc	a1,0x7
    80001900:	8e458593          	addi	a1,a1,-1820 # 800081e0 <digits+0x1a0>
    80001904:	00010517          	auipc	a0,0x10
    80001908:	99c50513          	addi	a0,a0,-1636 # 800112a0 <pid_lock>
    8000190c:	fffff097          	auipc	ra,0xfffff
    80001910:	248080e7          	jalr	584(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001914:	00007597          	auipc	a1,0x7
    80001918:	8d458593          	addi	a1,a1,-1836 # 800081e8 <digits+0x1a8>
    8000191c:	00010517          	auipc	a0,0x10
    80001920:	99c50513          	addi	a0,a0,-1636 # 800112b8 <wait_lock>
    80001924:	fffff097          	auipc	ra,0xfffff
    80001928:	230080e7          	jalr	560(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192c:	00010497          	auipc	s1,0x10
    80001930:	da448493          	addi	s1,s1,-604 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001934:	00007b17          	auipc	s6,0x7
    80001938:	8c4b0b13          	addi	s6,s6,-1852 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    8000193c:	8aa6                	mv	s5,s1
    8000193e:	00006a17          	auipc	s4,0x6
    80001942:	6c2a0a13          	addi	s4,s4,1730 # 80008000 <etext>
    80001946:	04000937          	lui	s2,0x4000
    8000194a:	197d                	addi	s2,s2,-1
    8000194c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	00016997          	auipc	s3,0x16
    80001952:	98298993          	addi	s3,s3,-1662 # 800172d0 <tickslock>
      initlock(&p->lock, "proc");
    80001956:	85da                	mv	a1,s6
    80001958:	8526                	mv	a0,s1
    8000195a:	fffff097          	auipc	ra,0xfffff
    8000195e:	1fa080e7          	jalr	506(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001962:	415487b3          	sub	a5,s1,s5
    80001966:	8791                	srai	a5,a5,0x4
    80001968:	000a3703          	ld	a4,0(s4)
    8000196c:	02e787b3          	mul	a5,a5,a4
    80001970:	2785                	addiw	a5,a5,1
    80001972:	00d7979b          	slliw	a5,a5,0xd
    80001976:	40f907b3          	sub	a5,s2,a5
    8000197a:	e4bc                	sd	a5,72(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197c:	17048493          	addi	s1,s1,368
    80001980:	fd349be3          	bne	s1,s3,80001956 <procinit+0x6e>
  }
}
    80001984:	70e2                	ld	ra,56(sp)
    80001986:	7442                	ld	s0,48(sp)
    80001988:	74a2                	ld	s1,40(sp)
    8000198a:	7902                	ld	s2,32(sp)
    8000198c:	69e2                	ld	s3,24(sp)
    8000198e:	6a42                	ld	s4,16(sp)
    80001990:	6aa2                	ld	s5,8(sp)
    80001992:	6b02                	ld	s6,0(sp)
    80001994:	6121                	addi	sp,sp,64
    80001996:	8082                	ret

0000000080001998 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001998:	1141                	addi	sp,sp,-16
    8000199a:	e422                	sd	s0,8(sp)
    8000199c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000199e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a0:	2501                	sext.w	a0,a0
    800019a2:	6422                	ld	s0,8(sp)
    800019a4:	0141                	addi	sp,sp,16
    800019a6:	8082                	ret

00000000800019a8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019a8:	1141                	addi	sp,sp,-16
    800019aa:	e422                	sd	s0,8(sp)
    800019ac:	0800                	addi	s0,sp,16
    800019ae:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b0:	2781                	sext.w	a5,a5
    800019b2:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b4:	00010517          	auipc	a0,0x10
    800019b8:	91c50513          	addi	a0,a0,-1764 # 800112d0 <cpus>
    800019bc:	953e                	add	a0,a0,a5
    800019be:	6422                	ld	s0,8(sp)
    800019c0:	0141                	addi	sp,sp,16
    800019c2:	8082                	ret

00000000800019c4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019c4:	1101                	addi	sp,sp,-32
    800019c6:	ec06                	sd	ra,24(sp)
    800019c8:	e822                	sd	s0,16(sp)
    800019ca:	e426                	sd	s1,8(sp)
    800019cc:	1000                	addi	s0,sp,32
  push_off();
    800019ce:	fffff097          	auipc	ra,0xfffff
    800019d2:	1ca080e7          	jalr	458(ra) # 80000b98 <push_off>
    800019d6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019d8:	2781                	sext.w	a5,a5
    800019da:	079e                	slli	a5,a5,0x7
    800019dc:	00010717          	auipc	a4,0x10
    800019e0:	8c470713          	addi	a4,a4,-1852 # 800112a0 <pid_lock>
    800019e4:	97ba                	add	a5,a5,a4
    800019e6:	7b84                	ld	s1,48(a5)
  pop_off();
    800019e8:	fffff097          	auipc	ra,0xfffff
    800019ec:	250080e7          	jalr	592(ra) # 80000c38 <pop_off>
  return p;
}
    800019f0:	8526                	mv	a0,s1
    800019f2:	60e2                	ld	ra,24(sp)
    800019f4:	6442                	ld	s0,16(sp)
    800019f6:	64a2                	ld	s1,8(sp)
    800019f8:	6105                	addi	sp,sp,32
    800019fa:	8082                	ret

00000000800019fc <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019fc:	1141                	addi	sp,sp,-16
    800019fe:	e406                	sd	ra,8(sp)
    80001a00:	e022                	sd	s0,0(sp)
    80001a02:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a04:	00000097          	auipc	ra,0x0
    80001a08:	fc0080e7          	jalr	-64(ra) # 800019c4 <myproc>
    80001a0c:	fffff097          	auipc	ra,0xfffff
    80001a10:	28c080e7          	jalr	652(ra) # 80000c98 <release>

  if (first) {
    80001a14:	00007797          	auipc	a5,0x7
    80001a18:	e4c7a783          	lw	a5,-436(a5) # 80008860 <first.1729>
    80001a1c:	eb89                	bnez	a5,80001a2e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a1e:	00001097          	auipc	ra,0x1
    80001a22:	f30080e7          	jalr	-208(ra) # 8000294e <usertrapret>
}
    80001a26:	60a2                	ld	ra,8(sp)
    80001a28:	6402                	ld	s0,0(sp)
    80001a2a:	0141                	addi	sp,sp,16
    80001a2c:	8082                	ret
    first = 0;
    80001a2e:	00007797          	auipc	a5,0x7
    80001a32:	e207a923          	sw	zero,-462(a5) # 80008860 <first.1729>
    fsinit(ROOTDEV);
    80001a36:	4505                	li	a0,1
    80001a38:	00002097          	auipc	ra,0x2
    80001a3c:	ca4080e7          	jalr	-860(ra) # 800036dc <fsinit>
    80001a40:	bff9                	j	80001a1e <forkret+0x22>

0000000080001a42 <allocpid>:
allocpid() {
    80001a42:	1101                	addi	sp,sp,-32
    80001a44:	ec06                	sd	ra,24(sp)
    80001a46:	e822                	sd	s0,16(sp)
    80001a48:	e426                	sd	s1,8(sp)
    80001a4a:	e04a                	sd	s2,0(sp)
    80001a4c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a4e:	00010917          	auipc	s2,0x10
    80001a52:	85290913          	addi	s2,s2,-1966 # 800112a0 <pid_lock>
    80001a56:	854a                	mv	a0,s2
    80001a58:	fffff097          	auipc	ra,0xfffff
    80001a5c:	18c080e7          	jalr	396(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a60:	00007797          	auipc	a5,0x7
    80001a64:	e0478793          	addi	a5,a5,-508 # 80008864 <nextpid>
    80001a68:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6a:	0014871b          	addiw	a4,s1,1
    80001a6e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a70:	854a                	mv	a0,s2
    80001a72:	fffff097          	auipc	ra,0xfffff
    80001a76:	226080e7          	jalr	550(ra) # 80000c98 <release>
}
    80001a7a:	8526                	mv	a0,s1
    80001a7c:	60e2                	ld	ra,24(sp)
    80001a7e:	6442                	ld	s0,16(sp)
    80001a80:	64a2                	ld	s1,8(sp)
    80001a82:	6902                	ld	s2,0(sp)
    80001a84:	6105                	addi	sp,sp,32
    80001a86:	8082                	ret

0000000080001a88 <proc_pagetable>:
{
    80001a88:	1101                	addi	sp,sp,-32
    80001a8a:	ec06                	sd	ra,24(sp)
    80001a8c:	e822                	sd	s0,16(sp)
    80001a8e:	e426                	sd	s1,8(sp)
    80001a90:	e04a                	sd	s2,0(sp)
    80001a92:	1000                	addi	s0,sp,32
    80001a94:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a96:	00000097          	auipc	ra,0x0
    80001a9a:	8ac080e7          	jalr	-1876(ra) # 80001342 <uvmcreate>
    80001a9e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aa0:	c121                	beqz	a0,80001ae0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa2:	4729                	li	a4,10
    80001aa4:	00005697          	auipc	a3,0x5
    80001aa8:	55c68693          	addi	a3,a3,1372 # 80007000 <_trampoline>
    80001aac:	6605                	lui	a2,0x1
    80001aae:	040005b7          	lui	a1,0x4000
    80001ab2:	15fd                	addi	a1,a1,-1
    80001ab4:	05b2                	slli	a1,a1,0xc
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	602080e7          	jalr	1538(ra) # 800010b8 <mappages>
    80001abe:	02054863          	bltz	a0,80001aee <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac2:	4719                	li	a4,6
    80001ac4:	06093683          	ld	a3,96(s2)
    80001ac8:	6605                	lui	a2,0x1
    80001aca:	020005b7          	lui	a1,0x2000
    80001ace:	15fd                	addi	a1,a1,-1
    80001ad0:	05b6                	slli	a1,a1,0xd
    80001ad2:	8526                	mv	a0,s1
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	5e4080e7          	jalr	1508(ra) # 800010b8 <mappages>
    80001adc:	02054163          	bltz	a0,80001afe <proc_pagetable+0x76>
}
    80001ae0:	8526                	mv	a0,s1
    80001ae2:	60e2                	ld	ra,24(sp)
    80001ae4:	6442                	ld	s0,16(sp)
    80001ae6:	64a2                	ld	s1,8(sp)
    80001ae8:	6902                	ld	s2,0(sp)
    80001aea:	6105                	addi	sp,sp,32
    80001aec:	8082                	ret
    uvmfree(pagetable, 0);
    80001aee:	4581                	li	a1,0
    80001af0:	8526                	mv	a0,s1
    80001af2:	00000097          	auipc	ra,0x0
    80001af6:	a4c080e7          	jalr	-1460(ra) # 8000153e <uvmfree>
    return 0;
    80001afa:	4481                	li	s1,0
    80001afc:	b7d5                	j	80001ae0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001afe:	4681                	li	a3,0
    80001b00:	4605                	li	a2,1
    80001b02:	040005b7          	lui	a1,0x4000
    80001b06:	15fd                	addi	a1,a1,-1
    80001b08:	05b2                	slli	a1,a1,0xc
    80001b0a:	8526                	mv	a0,s1
    80001b0c:	fffff097          	auipc	ra,0xfffff
    80001b10:	772080e7          	jalr	1906(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001b14:	4581                	li	a1,0
    80001b16:	8526                	mv	a0,s1
    80001b18:	00000097          	auipc	ra,0x0
    80001b1c:	a26080e7          	jalr	-1498(ra) # 8000153e <uvmfree>
    return 0;
    80001b20:	4481                	li	s1,0
    80001b22:	bf7d                	j	80001ae0 <proc_pagetable+0x58>

0000000080001b24 <proc_freepagetable>:
{
    80001b24:	1101                	addi	sp,sp,-32
    80001b26:	ec06                	sd	ra,24(sp)
    80001b28:	e822                	sd	s0,16(sp)
    80001b2a:	e426                	sd	s1,8(sp)
    80001b2c:	e04a                	sd	s2,0(sp)
    80001b2e:	1000                	addi	s0,sp,32
    80001b30:	84aa                	mv	s1,a0
    80001b32:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	040005b7          	lui	a1,0x4000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b2                	slli	a1,a1,0xc
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	73e080e7          	jalr	1854(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b48:	4681                	li	a3,0
    80001b4a:	4605                	li	a2,1
    80001b4c:	020005b7          	lui	a1,0x2000
    80001b50:	15fd                	addi	a1,a1,-1
    80001b52:	05b6                	slli	a1,a1,0xd
    80001b54:	8526                	mv	a0,s1
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	728080e7          	jalr	1832(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b5e:	85ca                	mv	a1,s2
    80001b60:	8526                	mv	a0,s1
    80001b62:	00000097          	auipc	ra,0x0
    80001b66:	9dc080e7          	jalr	-1572(ra) # 8000153e <uvmfree>
}
    80001b6a:	60e2                	ld	ra,24(sp)
    80001b6c:	6442                	ld	s0,16(sp)
    80001b6e:	64a2                	ld	s1,8(sp)
    80001b70:	6902                	ld	s2,0(sp)
    80001b72:	6105                	addi	sp,sp,32
    80001b74:	8082                	ret

0000000080001b76 <freeproc>:
{
    80001b76:	1101                	addi	sp,sp,-32
    80001b78:	ec06                	sd	ra,24(sp)
    80001b7a:	e822                	sd	s0,16(sp)
    80001b7c:	e426                	sd	s1,8(sp)
    80001b7e:	1000                	addi	s0,sp,32
    80001b80:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b82:	7128                	ld	a0,96(a0)
    80001b84:	c509                	beqz	a0,80001b8e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b86:	fffff097          	auipc	ra,0xfffff
    80001b8a:	e72080e7          	jalr	-398(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b8e:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001b92:	6ca8                	ld	a0,88(s1)
    80001b94:	c511                	beqz	a0,80001ba0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b96:	68ac                	ld	a1,80(s1)
    80001b98:	00000097          	auipc	ra,0x0
    80001b9c:	f8c080e7          	jalr	-116(ra) # 80001b24 <proc_freepagetable>
  p->pagetable = 0;
    80001ba0:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001ba4:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001ba8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bac:	0404b023          	sd	zero,64(s1)
  p->name[0] = 0;
    80001bb0:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001bb4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bb8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bbc:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc0:	0004ac23          	sw	zero,24(s1)
}
    80001bc4:	60e2                	ld	ra,24(sp)
    80001bc6:	6442                	ld	s0,16(sp)
    80001bc8:	64a2                	ld	s1,8(sp)
    80001bca:	6105                	addi	sp,sp,32
    80001bcc:	8082                	ret

0000000080001bce <allocproc>:
{
    80001bce:	1101                	addi	sp,sp,-32
    80001bd0:	ec06                	sd	ra,24(sp)
    80001bd2:	e822                	sd	s0,16(sp)
    80001bd4:	e426                	sd	s1,8(sp)
    80001bd6:	e04a                	sd	s2,0(sp)
    80001bd8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bda:	00010497          	auipc	s1,0x10
    80001bde:	af648493          	addi	s1,s1,-1290 # 800116d0 <proc>
    80001be2:	00015917          	auipc	s2,0x15
    80001be6:	6ee90913          	addi	s2,s2,1774 # 800172d0 <tickslock>
    acquire(&p->lock);
    80001bea:	8526                	mv	a0,s1
    80001bec:	fffff097          	auipc	ra,0xfffff
    80001bf0:	ff8080e7          	jalr	-8(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001bf4:	4c9c                	lw	a5,24(s1)
    80001bf6:	cf81                	beqz	a5,80001c0e <allocproc+0x40>
      release(&p->lock);
    80001bf8:	8526                	mv	a0,s1
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	09e080e7          	jalr	158(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c02:	17048493          	addi	s1,s1,368
    80001c06:	ff2492e3          	bne	s1,s2,80001bea <allocproc+0x1c>
  return 0;
    80001c0a:	4481                	li	s1,0
    80001c0c:	a8a9                	j	80001c66 <allocproc+0x98>
  p->pid = allocpid();
    80001c0e:	00000097          	auipc	ra,0x0
    80001c12:	e34080e7          	jalr	-460(ra) # 80001a42 <allocpid>
    80001c16:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c18:	4785                	li	a5,1
    80001c1a:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001c1c:	0204aa23          	sw	zero,52(s1)
  p->last_ticks = 0;
    80001c20:	0204ac23          	sw	zero,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	ed0080e7          	jalr	-304(ra) # 80000af4 <kalloc>
    80001c2c:	892a                	mv	s2,a0
    80001c2e:	f0a8                	sd	a0,96(s1)
    80001c30:	c131                	beqz	a0,80001c74 <allocproc+0xa6>
  p->pagetable = proc_pagetable(p);
    80001c32:	8526                	mv	a0,s1
    80001c34:	00000097          	auipc	ra,0x0
    80001c38:	e54080e7          	jalr	-428(ra) # 80001a88 <proc_pagetable>
    80001c3c:	892a                	mv	s2,a0
    80001c3e:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001c40:	c531                	beqz	a0,80001c8c <allocproc+0xbe>
  memset(&p->context, 0, sizeof(p->context));
    80001c42:	07000613          	li	a2,112
    80001c46:	4581                	li	a1,0
    80001c48:	06848513          	addi	a0,s1,104
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	094080e7          	jalr	148(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c54:	00000797          	auipc	a5,0x0
    80001c58:	da878793          	addi	a5,a5,-600 # 800019fc <forkret>
    80001c5c:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c5e:	64bc                	ld	a5,72(s1)
    80001c60:	6705                	lui	a4,0x1
    80001c62:	97ba                	add	a5,a5,a4
    80001c64:	f8bc                	sd	a5,112(s1)
}
    80001c66:	8526                	mv	a0,s1
    80001c68:	60e2                	ld	ra,24(sp)
    80001c6a:	6442                	ld	s0,16(sp)
    80001c6c:	64a2                	ld	s1,8(sp)
    80001c6e:	6902                	ld	s2,0(sp)
    80001c70:	6105                	addi	sp,sp,32
    80001c72:	8082                	ret
    freeproc(p);
    80001c74:	8526                	mv	a0,s1
    80001c76:	00000097          	auipc	ra,0x0
    80001c7a:	f00080e7          	jalr	-256(ra) # 80001b76 <freeproc>
    release(&p->lock);
    80001c7e:	8526                	mv	a0,s1
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	018080e7          	jalr	24(ra) # 80000c98 <release>
    return 0;
    80001c88:	84ca                	mv	s1,s2
    80001c8a:	bff1                	j	80001c66 <allocproc+0x98>
    freeproc(p);
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	ee8080e7          	jalr	-280(ra) # 80001b76 <freeproc>
    release(&p->lock);
    80001c96:	8526                	mv	a0,s1
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	000080e7          	jalr	ra # 80000c98 <release>
    return 0;
    80001ca0:	84ca                	mv	s1,s2
    80001ca2:	b7d1                	j	80001c66 <allocproc+0x98>

0000000080001ca4 <userinit>:
{
    80001ca4:	1101                	addi	sp,sp,-32
    80001ca6:	ec06                	sd	ra,24(sp)
    80001ca8:	e822                	sd	s0,16(sp)
    80001caa:	e426                	sd	s1,8(sp)
    80001cac:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cae:	00000097          	auipc	ra,0x0
    80001cb2:	f20080e7          	jalr	-224(ra) # 80001bce <allocproc>
    80001cb6:	84aa                	mv	s1,a0
  initproc = p;
    80001cb8:	00007797          	auipc	a5,0x7
    80001cbc:	36a7bc23          	sd	a0,888(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cc0:	03400613          	li	a2,52
    80001cc4:	00007597          	auipc	a1,0x7
    80001cc8:	bac58593          	addi	a1,a1,-1108 # 80008870 <initcode>
    80001ccc:	6d28                	ld	a0,88(a0)
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	6a2080e7          	jalr	1698(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001cd6:	6785                	lui	a5,0x1
    80001cd8:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cda:	70b8                	ld	a4,96(s1)
    80001cdc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ce0:	70b8                	ld	a4,96(s1)
    80001ce2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ce4:	4641                	li	a2,16
    80001ce6:	00006597          	auipc	a1,0x6
    80001cea:	51a58593          	addi	a1,a1,1306 # 80008200 <digits+0x1c0>
    80001cee:	16048513          	addi	a0,s1,352
    80001cf2:	fffff097          	auipc	ra,0xfffff
    80001cf6:	140080e7          	jalr	320(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cfa:	00006517          	auipc	a0,0x6
    80001cfe:	51650513          	addi	a0,a0,1302 # 80008210 <digits+0x1d0>
    80001d02:	00002097          	auipc	ra,0x2
    80001d06:	408080e7          	jalr	1032(ra) # 8000410a <namei>
    80001d0a:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001d0e:	478d                	li	a5,3
    80001d10:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d12:	8526                	mv	a0,s1
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	f84080e7          	jalr	-124(ra) # 80000c98 <release>
}
    80001d1c:	60e2                	ld	ra,24(sp)
    80001d1e:	6442                	ld	s0,16(sp)
    80001d20:	64a2                	ld	s1,8(sp)
    80001d22:	6105                	addi	sp,sp,32
    80001d24:	8082                	ret

0000000080001d26 <growproc>:
{
    80001d26:	1101                	addi	sp,sp,-32
    80001d28:	ec06                	sd	ra,24(sp)
    80001d2a:	e822                	sd	s0,16(sp)
    80001d2c:	e426                	sd	s1,8(sp)
    80001d2e:	e04a                	sd	s2,0(sp)
    80001d30:	1000                	addi	s0,sp,32
    80001d32:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d34:	00000097          	auipc	ra,0x0
    80001d38:	c90080e7          	jalr	-880(ra) # 800019c4 <myproc>
    80001d3c:	892a                	mv	s2,a0
  sz = p->sz;
    80001d3e:	692c                	ld	a1,80(a0)
    80001d40:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d44:	00904f63          	bgtz	s1,80001d62 <growproc+0x3c>
  } else if(n < 0){
    80001d48:	0204cc63          	bltz	s1,80001d80 <growproc+0x5a>
  p->sz = sz;
    80001d4c:	1602                	slli	a2,a2,0x20
    80001d4e:	9201                	srli	a2,a2,0x20
    80001d50:	04c93823          	sd	a2,80(s2)
  return 0;
    80001d54:	4501                	li	a0,0
}
    80001d56:	60e2                	ld	ra,24(sp)
    80001d58:	6442                	ld	s0,16(sp)
    80001d5a:	64a2                	ld	s1,8(sp)
    80001d5c:	6902                	ld	s2,0(sp)
    80001d5e:	6105                	addi	sp,sp,32
    80001d60:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d62:	9e25                	addw	a2,a2,s1
    80001d64:	1602                	slli	a2,a2,0x20
    80001d66:	9201                	srli	a2,a2,0x20
    80001d68:	1582                	slli	a1,a1,0x20
    80001d6a:	9181                	srli	a1,a1,0x20
    80001d6c:	6d28                	ld	a0,88(a0)
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	6bc080e7          	jalr	1724(ra) # 8000142a <uvmalloc>
    80001d76:	0005061b          	sext.w	a2,a0
    80001d7a:	fa69                	bnez	a2,80001d4c <growproc+0x26>
      return -1;
    80001d7c:	557d                	li	a0,-1
    80001d7e:	bfe1                	j	80001d56 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d80:	9e25                	addw	a2,a2,s1
    80001d82:	1602                	slli	a2,a2,0x20
    80001d84:	9201                	srli	a2,a2,0x20
    80001d86:	1582                	slli	a1,a1,0x20
    80001d88:	9181                	srli	a1,a1,0x20
    80001d8a:	6d28                	ld	a0,88(a0)
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	656080e7          	jalr	1622(ra) # 800013e2 <uvmdealloc>
    80001d94:	0005061b          	sext.w	a2,a0
    80001d98:	bf55                	j	80001d4c <growproc+0x26>

0000000080001d9a <fork>:
{
    80001d9a:	7179                	addi	sp,sp,-48
    80001d9c:	f406                	sd	ra,40(sp)
    80001d9e:	f022                	sd	s0,32(sp)
    80001da0:	ec26                	sd	s1,24(sp)
    80001da2:	e84a                	sd	s2,16(sp)
    80001da4:	e44e                	sd	s3,8(sp)
    80001da6:	e052                	sd	s4,0(sp)
    80001da8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001daa:	00000097          	auipc	ra,0x0
    80001dae:	c1a080e7          	jalr	-998(ra) # 800019c4 <myproc>
    80001db2:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001db4:	00000097          	auipc	ra,0x0
    80001db8:	e1a080e7          	jalr	-486(ra) # 80001bce <allocproc>
    80001dbc:	10050b63          	beqz	a0,80001ed2 <fork+0x138>
    80001dc0:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dc2:	05093603          	ld	a2,80(s2)
    80001dc6:	6d2c                	ld	a1,88(a0)
    80001dc8:	05893503          	ld	a0,88(s2)
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	7aa080e7          	jalr	1962(ra) # 80001576 <uvmcopy>
    80001dd4:	04054663          	bltz	a0,80001e20 <fork+0x86>
  np->sz = p->sz;
    80001dd8:	05093783          	ld	a5,80(s2)
    80001ddc:	04f9b823          	sd	a5,80(s3)
  *(np->trapframe) = *(p->trapframe);
    80001de0:	06093683          	ld	a3,96(s2)
    80001de4:	87b6                	mv	a5,a3
    80001de6:	0609b703          	ld	a4,96(s3)
    80001dea:	12068693          	addi	a3,a3,288
    80001dee:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001df2:	6788                	ld	a0,8(a5)
    80001df4:	6b8c                	ld	a1,16(a5)
    80001df6:	6f90                	ld	a2,24(a5)
    80001df8:	01073023          	sd	a6,0(a4)
    80001dfc:	e708                	sd	a0,8(a4)
    80001dfe:	eb0c                	sd	a1,16(a4)
    80001e00:	ef10                	sd	a2,24(a4)
    80001e02:	02078793          	addi	a5,a5,32
    80001e06:	02070713          	addi	a4,a4,32
    80001e0a:	fed792e3          	bne	a5,a3,80001dee <fork+0x54>
  np->trapframe->a0 = 0;
    80001e0e:	0609b783          	ld	a5,96(s3)
    80001e12:	0607b823          	sd	zero,112(a5)
    80001e16:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    80001e1a:	15800a13          	li	s4,344
    80001e1e:	a03d                	j	80001e4c <fork+0xb2>
    freeproc(np);
    80001e20:	854e                	mv	a0,s3
    80001e22:	00000097          	auipc	ra,0x0
    80001e26:	d54080e7          	jalr	-684(ra) # 80001b76 <freeproc>
    release(&np->lock);
    80001e2a:	854e                	mv	a0,s3
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	e6c080e7          	jalr	-404(ra) # 80000c98 <release>
    return -1;
    80001e34:	5a7d                	li	s4,-1
    80001e36:	a069                	j	80001ec0 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e38:	00003097          	auipc	ra,0x3
    80001e3c:	968080e7          	jalr	-1688(ra) # 800047a0 <filedup>
    80001e40:	009987b3          	add	a5,s3,s1
    80001e44:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e46:	04a1                	addi	s1,s1,8
    80001e48:	01448763          	beq	s1,s4,80001e56 <fork+0xbc>
    if(p->ofile[i])
    80001e4c:	009907b3          	add	a5,s2,s1
    80001e50:	6388                	ld	a0,0(a5)
    80001e52:	f17d                	bnez	a0,80001e38 <fork+0x9e>
    80001e54:	bfcd                	j	80001e46 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e56:	15893503          	ld	a0,344(s2)
    80001e5a:	00002097          	auipc	ra,0x2
    80001e5e:	abc080e7          	jalr	-1348(ra) # 80003916 <idup>
    80001e62:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e66:	4641                	li	a2,16
    80001e68:	16090593          	addi	a1,s2,352
    80001e6c:	16098513          	addi	a0,s3,352
    80001e70:	fffff097          	auipc	ra,0xfffff
    80001e74:	fc2080e7          	jalr	-62(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e78:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e7c:	854e                	mv	a0,s3
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	e1a080e7          	jalr	-486(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e86:	0000f497          	auipc	s1,0xf
    80001e8a:	43248493          	addi	s1,s1,1074 # 800112b8 <wait_lock>
    80001e8e:	8526                	mv	a0,s1
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	d54080e7          	jalr	-684(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e98:	0529b023          	sd	s2,64(s3)
  release(&wait_lock);
    80001e9c:	8526                	mv	a0,s1
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	dfa080e7          	jalr	-518(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ea6:	854e                	mv	a0,s3
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	d3c080e7          	jalr	-708(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001eb0:	478d                	li	a5,3
    80001eb2:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eb6:	854e                	mv	a0,s3
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	de0080e7          	jalr	-544(ra) # 80000c98 <release>
}
    80001ec0:	8552                	mv	a0,s4
    80001ec2:	70a2                	ld	ra,40(sp)
    80001ec4:	7402                	ld	s0,32(sp)
    80001ec6:	64e2                	ld	s1,24(sp)
    80001ec8:	6942                	ld	s2,16(sp)
    80001eca:	69a2                	ld	s3,8(sp)
    80001ecc:	6a02                	ld	s4,0(sp)
    80001ece:	6145                	addi	sp,sp,48
    80001ed0:	8082                	ret
    return -1;
    80001ed2:	5a7d                	li	s4,-1
    80001ed4:	b7f5                	j	80001ec0 <fork+0x126>

0000000080001ed6 <scheduler_default>:
{
    80001ed6:	715d                	addi	sp,sp,-80
    80001ed8:	e486                	sd	ra,72(sp)
    80001eda:	e0a2                	sd	s0,64(sp)
    80001edc:	fc26                	sd	s1,56(sp)
    80001ede:	f84a                	sd	s2,48(sp)
    80001ee0:	f44e                	sd	s3,40(sp)
    80001ee2:	f052                	sd	s4,32(sp)
    80001ee4:	ec56                	sd	s5,24(sp)
    80001ee6:	e85a                	sd	s6,16(sp)
    80001ee8:	e45e                	sd	s7,8(sp)
    80001eea:	e062                	sd	s8,0(sp)
    80001eec:	0880                	addi	s0,sp,80
    80001eee:	8792                	mv	a5,tp
  int id = r_tp();
    80001ef0:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ef2:	00779c13          	slli	s8,a5,0x7
    80001ef6:	0000f717          	auipc	a4,0xf
    80001efa:	3aa70713          	addi	a4,a4,938 # 800112a0 <pid_lock>
    80001efe:	9762                	add	a4,a4,s8
    80001f00:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001f04:	0000f717          	auipc	a4,0xf
    80001f08:	3d470713          	addi	a4,a4,980 # 800112d8 <cpus+0x8>
    80001f0c:	9c3a                	add	s8,s8,a4
      if(ticks >= pause_ticks){ // check if pause signal was called
    80001f0e:	00007a17          	auipc	s4,0x7
    80001f12:	12aa0a13          	addi	s4,s4,298 # 80009038 <ticks>
    80001f16:	00007997          	auipc	s3,0x7
    80001f1a:	11298993          	addi	s3,s3,274 # 80009028 <pause_ticks>
        if(p->state == RUNNABLE) {
    80001f1e:	4a8d                	li	s5,3
          c->proc = p;
    80001f20:	079e                	slli	a5,a5,0x7
    80001f22:	0000fb17          	auipc	s6,0xf
    80001f26:	37eb0b13          	addi	s6,s6,894 # 800112a0 <pid_lock>
    80001f2a:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f2c:	00015917          	auipc	s2,0x15
    80001f30:	3a490913          	addi	s2,s2,932 # 800172d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f34:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f38:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f3c:	10079073          	csrw	sstatus,a5
    80001f40:	0000f497          	auipc	s1,0xf
    80001f44:	79048493          	addi	s1,s1,1936 # 800116d0 <proc>
          p->state = RUNNING;
    80001f48:	4b91                	li	s7,4
    80001f4a:	a03d                	j	80001f78 <scheduler_default+0xa2>
    80001f4c:	0174ac23          	sw	s7,24(s1)
          c->proc = p;
    80001f50:	029b3823          	sd	s1,48(s6)
          swtch(&c->context, &p->context);
    80001f54:	06848593          	addi	a1,s1,104
    80001f58:	8562                	mv	a0,s8
    80001f5a:	00001097          	auipc	ra,0x1
    80001f5e:	94a080e7          	jalr	-1718(ra) # 800028a4 <swtch>
          c->proc = 0;
    80001f62:	020b3823          	sd	zero,48(s6)
        release(&p->lock);
    80001f66:	8526                	mv	a0,s1
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	d30080e7          	jalr	-720(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f70:	17048493          	addi	s1,s1,368
    80001f74:	fd2480e3          	beq	s1,s2,80001f34 <scheduler_default+0x5e>
      if(ticks >= pause_ticks){ // check if pause signal was called
    80001f78:	000a2703          	lw	a4,0(s4)
    80001f7c:	0009a783          	lw	a5,0(s3)
    80001f80:	fef768e3          	bltu	a4,a5,80001f70 <scheduler_default+0x9a>
        acquire(&p->lock);
    80001f84:	8526                	mv	a0,s1
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	c5e080e7          	jalr	-930(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {
    80001f8e:	4c9c                	lw	a5,24(s1)
    80001f90:	fd579be3          	bne	a5,s5,80001f66 <scheduler_default+0x90>
    80001f94:	bf65                	j	80001f4c <scheduler_default+0x76>

0000000080001f96 <swap_process_ptr>:
{
    80001f96:	1141                	addi	sp,sp,-16
    80001f98:	e422                	sd	s0,8(sp)
    80001f9a:	0800                	addi	s0,sp,16
  struct proc *temp = *p1;
    80001f9c:	611c                	ld	a5,0(a0)
  *p1 = *p2;
    80001f9e:	6198                	ld	a4,0(a1)
    80001fa0:	e118                	sd	a4,0(a0)
  *p2 = temp; 
    80001fa2:	e19c                	sd	a5,0(a1)
}     
    80001fa4:	6422                	ld	s0,8(sp)
    80001fa6:	0141                	addi	sp,sp,16
    80001fa8:	8082                	ret

0000000080001faa <make_acquired_process_running>:
make_acquired_process_running(struct cpu *c, struct proc *p){
    80001faa:	1101                	addi	sp,sp,-32
    80001fac:	ec06                	sd	ra,24(sp)
    80001fae:	e822                	sd	s0,16(sp)
    80001fb0:	e426                	sd	s1,8(sp)
    80001fb2:	e04a                	sd	s2,0(sp)
    80001fb4:	1000                	addi	s0,sp,32
    80001fb6:	892a                	mv	s2,a0
    80001fb8:	84ae                	mv	s1,a1
  p->state = RUNNING;
    80001fba:	4791                	li	a5,4
    80001fbc:	cd9c                	sw	a5,24(a1)
  c->proc = p;
    80001fbe:	e10c                	sd	a1,0(a0)
  swtch(&c->context, &p->context);
    80001fc0:	06858593          	addi	a1,a1,104
    80001fc4:	0521                	addi	a0,a0,8
    80001fc6:	00001097          	auipc	ra,0x1
    80001fca:	8de080e7          	jalr	-1826(ra) # 800028a4 <swtch>
  c->proc = 0;
    80001fce:	00093023          	sd	zero,0(s2)
  release(&p->lock);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	cc4080e7          	jalr	-828(ra) # 80000c98 <release>
}
    80001fdc:	60e2                	ld	ra,24(sp)
    80001fde:	6442                	ld	s0,16(sp)
    80001fe0:	64a2                	ld	s1,8(sp)
    80001fe2:	6902                	ld	s2,0(sp)
    80001fe4:	6105                	addi	sp,sp,32
    80001fe6:	8082                	ret

0000000080001fe8 <scheduler_sjf>:
void scheduler_sjf(void){
    80001fe8:	7159                	addi	sp,sp,-112
    80001fea:	f486                	sd	ra,104(sp)
    80001fec:	f0a2                	sd	s0,96(sp)
    80001fee:	eca6                	sd	s1,88(sp)
    80001ff0:	e8ca                	sd	s2,80(sp)
    80001ff2:	e4ce                	sd	s3,72(sp)
    80001ff4:	e0d2                	sd	s4,64(sp)
    80001ff6:	fc56                	sd	s5,56(sp)
    80001ff8:	f85a                	sd	s6,48(sp)
    80001ffa:	f45e                	sd	s7,40(sp)
    80001ffc:	f062                	sd	s8,32(sp)
    80001ffe:	ec66                	sd	s9,24(sp)
    80002000:	e86a                	sd	s10,16(sp)
    80002002:	e46e                	sd	s11,8(sp)
    80002004:	1880                	addi	s0,sp,112
  asm volatile("mv %0, tp" : "=r" (x) );
    80002006:	8792                	mv	a5,tp
  int id = r_tp();
    80002008:	2781                	sext.w	a5,a5
  struct cpu *c = &cpus[id];
    8000200a:	079e                	slli	a5,a5,0x7
    8000200c:	0000fd17          	auipc	s10,0xf
    80002010:	2c4d0d13          	addi	s10,s10,708 # 800112d0 <cpus>
    80002014:	9d3e                	add	s10,s10,a5
  c->proc = 0;
    80002016:	0000f717          	auipc	a4,0xf
    8000201a:	28a70713          	addi	a4,a4,650 # 800112a0 <pid_lock>
    8000201e:	97ba                	add	a5,a5,a4
    80002020:	0207b823          	sd	zero,48(a5)
    printf("before loop");
    80002024:	00006d97          	auipc	s11,0x6
    80002028:	1f4d8d93          	addi	s11,s11,500 # 80008218 <digits+0x1d8>
      printf("in loop");
    8000202c:	00006b97          	auipc	s7,0x6
    80002030:	1fcb8b93          	addi	s7,s7,508 # 80008228 <digits+0x1e8>
      if(ticks >= pause_ticks){ // check if pause signal was called
    80002034:	00007a17          	auipc	s4,0x7
    80002038:	004a0a13          	addi	s4,s4,4 # 80009038 <ticks>
    8000203c:	00007b17          	auipc	s6,0x7
    80002040:	fecb0b13          	addi	s6,s6,-20 # 80009028 <pause_ticks>
        if(curr->state == RUNNABLE) {
    80002044:	4c0d                	li	s8,3
    for(curr = proc; curr < &proc[NPROC]; p++) {
    80002046:	00015a97          	auipc	s5,0x15
    8000204a:	28aa8a93          	addi	s5,s5,650 # 800172d0 <tickslock>
    8000204e:	a879                	j	800020ec <scheduler_sjf+0x104>
          curr->mean_ticks = ((SECONDS_TO_TICKS - RATE) * curr->mean_ticks + curr->last_ticks * (RATE)) / SECONDS_TO_TICKS;
    80002050:	0349a703          	lw	a4,52(s3)
    80002054:	0027179b          	slliw	a5,a4,0x2
    80002058:	9fb9                	addw	a5,a5,a4
    8000205a:	0017979b          	slliw	a5,a5,0x1
    8000205e:	0397d7bb          	divuw	a5,a5,s9
    80002062:	0007871b          	sext.w	a4,a5
    80002066:	02f9aa23          	sw	a5,52(s3)
          if(p == NULL){
    8000206a:	894e                	mv	s2,s3
    8000206c:	c881                	beqz	s1,8000207c <scheduler_sjf+0x94>
          } else if(p->mean_ticks > curr->mean_ticks) {
    8000206e:	58dc                	lw	a5,52(s1)
    80002070:	02f77f63          	bgeu	a4,a5,800020ae <scheduler_sjf+0xc6>
    80002074:	87a6                	mv	a5,s1
    80002076:	84ce                	mv	s1,s3
    80002078:	89be                	mv	s3,a5
    8000207a:	a815                	j	800020ae <scheduler_sjf+0xc6>
    for(curr = proc; curr < &proc[NPROC]; p++) {
    8000207c:	17090493          	addi	s1,s2,368
    80002080:	0559f063          	bgeu	s3,s5,800020c0 <scheduler_sjf+0xd8>
      printf("in loop");
    80002084:	855e                	mv	a0,s7
    80002086:	ffffe097          	auipc	ra,0xffffe
    8000208a:	502080e7          	jalr	1282(ra) # 80000588 <printf>
      if(ticks >= pause_ticks){ // check if pause signal was called
    8000208e:	000a2703          	lw	a4,0(s4)
    80002092:	000b2783          	lw	a5,0(s6)
    80002096:	8926                	mv	s2,s1
    80002098:	fef762e3          	bltu	a4,a5,8000207c <scheduler_sjf+0x94>
        acquire(&curr->lock);
    8000209c:	854e                	mv	a0,s3
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	b46080e7          	jalr	-1210(ra) # 80000be4 <acquire>
        if(curr->state == RUNNABLE) {
    800020a6:	0189a783          	lw	a5,24(s3)
    800020aa:	fb8783e3          	beq	a5,s8,80002050 <scheduler_sjf+0x68>
        if(p != curr)
    800020ae:	8926                	mv	s2,s1
    800020b0:	fd3486e3          	beq	s1,s3,8000207c <scheduler_sjf+0x94>
          release(&curr->lock);
    800020b4:	854e                	mv	a0,s3
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	be2080e7          	jalr	-1054(ra) # 80000c98 <release>
    800020be:	bf7d                	j	8000207c <scheduler_sjf+0x94>
    printf("after loop");
    800020c0:	00006517          	auipc	a0,0x6
    800020c4:	17050513          	addi	a0,a0,368 # 80008230 <digits+0x1f0>
    800020c8:	ffffe097          	auipc	ra,0xffffe
    800020cc:	4c0080e7          	jalr	1216(ra) # 80000588 <printf>
      uint start = ticks;
    800020d0:	000a2983          	lw	s3,0(s4)
      make_acquired_process_running(c, p);
    800020d4:	85a6                	mv	a1,s1
    800020d6:	856a                	mv	a0,s10
    800020d8:	00000097          	auipc	ra,0x0
    800020dc:	ed2080e7          	jalr	-302(ra) # 80001faa <make_acquired_process_running>
      p->last_ticks = ticks - start;
    800020e0:	000a2783          	lw	a5,0(s4)
    800020e4:	413787bb          	subw	a5,a5,s3
    800020e8:	1af92423          	sw	a5,424(s2)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020ec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020f0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020f4:	10079073          	csrw	sstatus,a5
    printf("before loop");
    800020f8:	856e                	mv	a0,s11
    800020fa:	ffffe097          	auipc	ra,0xffffe
    800020fe:	48e080e7          	jalr	1166(ra) # 80000588 <printf>
    for(curr = proc; curr < &proc[NPROC]; p++) {
    80002102:	0000f997          	auipc	s3,0xf
    80002106:	5ce98993          	addi	s3,s3,1486 # 800116d0 <proc>
    p = NULL;
    8000210a:	4481                	li	s1,0
          curr->mean_ticks = ((SECONDS_TO_TICKS - RATE) * curr->mean_ticks + curr->last_ticks * (RATE)) / SECONDS_TO_TICKS;
    8000210c:	4ca9                	li	s9,10
    8000210e:	bf9d                	j	80002084 <scheduler_sjf+0x9c>

0000000080002110 <scheduler>:
{
    80002110:	1141                	addi	sp,sp,-16
    80002112:	e406                	sd	ra,8(sp)
    80002114:	e022                	sd	s0,0(sp)
    80002116:	0800                	addi	s0,sp,16
    printf("SJF scheduler mode\n");
    80002118:	00006517          	auipc	a0,0x6
    8000211c:	12850513          	addi	a0,a0,296 # 80008240 <digits+0x200>
    80002120:	ffffe097          	auipc	ra,0xffffe
    80002124:	468080e7          	jalr	1128(ra) # 80000588 <printf>
    scheduler_sjf();
    80002128:	00000097          	auipc	ra,0x0
    8000212c:	ec0080e7          	jalr	-320(ra) # 80001fe8 <scheduler_sjf>

0000000080002130 <scheduler_fcfs>:
scheduler_fcfs(void) {
    80002130:	715d                	addi	sp,sp,-80
    80002132:	e486                	sd	ra,72(sp)
    80002134:	e0a2                	sd	s0,64(sp)
    80002136:	fc26                	sd	s1,56(sp)
    80002138:	f84a                	sd	s2,48(sp)
    8000213a:	f44e                	sd	s3,40(sp)
    8000213c:	f052                	sd	s4,32(sp)
    8000213e:	ec56                	sd	s5,24(sp)
    80002140:	e85a                	sd	s6,16(sp)
    80002142:	e45e                	sd	s7,8(sp)
    80002144:	e062                	sd	s8,0(sp)
    80002146:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80002148:	8792                	mv	a5,tp
  int id = r_tp();
    8000214a:	2781                	sext.w	a5,a5
  struct cpu *c = &cpus[id];
    8000214c:	079e                	slli	a5,a5,0x7
    8000214e:	0000fb97          	auipc	s7,0xf
    80002152:	182b8b93          	addi	s7,s7,386 # 800112d0 <cpus>
    80002156:	9bbe                	add	s7,s7,a5
  c->proc = 0;
    80002158:	0000f717          	auipc	a4,0xf
    8000215c:	14870713          	addi	a4,a4,328 # 800112a0 <pid_lock>
    80002160:	97ba                	add	a5,a5,a4
    80002162:	0207b823          	sd	zero,48(a5)
    for(curr = proc; curr < &proc[NPROC]; p++) {
    80002166:	0000fc17          	auipc	s8,0xf
    8000216a:	56ac0c13          	addi	s8,s8,1386 # 800116d0 <proc>
      if(ticks >= pause_ticks){ // check if pause signal was called
    8000216e:	00007a97          	auipc	s5,0x7
    80002172:	ecaa8a93          	addi	s5,s5,-310 # 80009038 <ticks>
    80002176:	00007a17          	auipc	s4,0x7
    8000217a:	eb2a0a13          	addi	s4,s4,-334 # 80009028 <pause_ticks>
        if(curr->state == RUNNABLE) {
    8000217e:	4b0d                	li	s6,3
    for(curr = proc; curr < &proc[NPROC]; p++) {
    80002180:	00015997          	auipc	s3,0x15
    80002184:	15098993          	addi	s3,s3,336 # 800172d0 <tickslock>
    80002188:	a8a9                	j	800021e2 <scheduler_fcfs+0xb2>
          if(p == NULL){
    8000218a:	c891                	beqz	s1,8000219e <scheduler_fcfs+0x6e>
          } else if(p->last_runnable_time > curr->last_runnable_time) {
    8000218c:	5cd8                	lw	a4,60(s1)
    8000218e:	03c92783          	lw	a5,60(s2)
    80002192:	02e7fa63          	bgeu	a5,a4,800021c6 <scheduler_fcfs+0x96>
    80002196:	87a6                	mv	a5,s1
    80002198:	84ca                	mv	s1,s2
    8000219a:	893e                	mv	s2,a5
    8000219c:	a02d                	j	800021c6 <scheduler_fcfs+0x96>
    8000219e:	84ca                	mv	s1,s2
    for(curr = proc; curr < &proc[NPROC]; p++) {
    800021a0:	17048493          	addi	s1,s1,368
    800021a4:	03397963          	bgeu	s2,s3,800021d6 <scheduler_fcfs+0xa6>
      if(ticks >= pause_ticks){ // check if pause signal was called
    800021a8:	000aa703          	lw	a4,0(s5)
    800021ac:	000a2783          	lw	a5,0(s4)
    800021b0:	fef768e3          	bltu	a4,a5,800021a0 <scheduler_fcfs+0x70>
        acquire(&curr->lock);
    800021b4:	854a                	mv	a0,s2
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	a2e080e7          	jalr	-1490(ra) # 80000be4 <acquire>
        if(curr->state == RUNNABLE) {
    800021be:	01892783          	lw	a5,24(s2)
    800021c2:	fd6784e3          	beq	a5,s6,8000218a <scheduler_fcfs+0x5a>
        if(p != curr)
    800021c6:	fd248de3          	beq	s1,s2,800021a0 <scheduler_fcfs+0x70>
          release(&curr->lock);
    800021ca:	854a                	mv	a0,s2
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	acc080e7          	jalr	-1332(ra) # 80000c98 <release>
    800021d4:	b7f1                	j	800021a0 <scheduler_fcfs+0x70>
      make_acquired_process_running(c, p);
    800021d6:	85a6                	mv	a1,s1
    800021d8:	855e                	mv	a0,s7
    800021da:	00000097          	auipc	ra,0x0
    800021de:	dd0080e7          	jalr	-560(ra) # 80001faa <make_acquired_process_running>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021e2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021e6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021ea:	10079073          	csrw	sstatus,a5
    for(curr = proc; curr < &proc[NPROC]; p++) {
    800021ee:	8962                	mv	s2,s8
    p = NULL;
    800021f0:	4481                	li	s1,0
    800021f2:	bf5d                	j	800021a8 <scheduler_fcfs+0x78>

00000000800021f4 <sched>:
{
    800021f4:	7179                	addi	sp,sp,-48
    800021f6:	f406                	sd	ra,40(sp)
    800021f8:	f022                	sd	s0,32(sp)
    800021fa:	ec26                	sd	s1,24(sp)
    800021fc:	e84a                	sd	s2,16(sp)
    800021fe:	e44e                	sd	s3,8(sp)
    80002200:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	7c2080e7          	jalr	1986(ra) # 800019c4 <myproc>
    8000220a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	95e080e7          	jalr	-1698(ra) # 80000b6a <holding>
    80002214:	c93d                	beqz	a0,8000228a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002216:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002218:	2781                	sext.w	a5,a5
    8000221a:	079e                	slli	a5,a5,0x7
    8000221c:	0000f717          	auipc	a4,0xf
    80002220:	08470713          	addi	a4,a4,132 # 800112a0 <pid_lock>
    80002224:	97ba                	add	a5,a5,a4
    80002226:	0a87a703          	lw	a4,168(a5)
    8000222a:	4785                	li	a5,1
    8000222c:	06f71763          	bne	a4,a5,8000229a <sched+0xa6>
  if(p->state == RUNNING)
    80002230:	4c98                	lw	a4,24(s1)
    80002232:	4791                	li	a5,4
    80002234:	06f70b63          	beq	a4,a5,800022aa <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002238:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000223c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000223e:	efb5                	bnez	a5,800022ba <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002240:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002242:	0000f917          	auipc	s2,0xf
    80002246:	05e90913          	addi	s2,s2,94 # 800112a0 <pid_lock>
    8000224a:	2781                	sext.w	a5,a5
    8000224c:	079e                	slli	a5,a5,0x7
    8000224e:	97ca                	add	a5,a5,s2
    80002250:	0ac7a983          	lw	s3,172(a5)
    80002254:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002256:	2781                	sext.w	a5,a5
    80002258:	079e                	slli	a5,a5,0x7
    8000225a:	0000f597          	auipc	a1,0xf
    8000225e:	07e58593          	addi	a1,a1,126 # 800112d8 <cpus+0x8>
    80002262:	95be                	add	a1,a1,a5
    80002264:	06848513          	addi	a0,s1,104
    80002268:	00000097          	auipc	ra,0x0
    8000226c:	63c080e7          	jalr	1596(ra) # 800028a4 <swtch>
    80002270:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002272:	2781                	sext.w	a5,a5
    80002274:	079e                	slli	a5,a5,0x7
    80002276:	97ca                	add	a5,a5,s2
    80002278:	0b37a623          	sw	s3,172(a5)
}
    8000227c:	70a2                	ld	ra,40(sp)
    8000227e:	7402                	ld	s0,32(sp)
    80002280:	64e2                	ld	s1,24(sp)
    80002282:	6942                	ld	s2,16(sp)
    80002284:	69a2                	ld	s3,8(sp)
    80002286:	6145                	addi	sp,sp,48
    80002288:	8082                	ret
    panic("sched p->lock");
    8000228a:	00006517          	auipc	a0,0x6
    8000228e:	fce50513          	addi	a0,a0,-50 # 80008258 <digits+0x218>
    80002292:	ffffe097          	auipc	ra,0xffffe
    80002296:	2ac080e7          	jalr	684(ra) # 8000053e <panic>
    panic("sched locks");
    8000229a:	00006517          	auipc	a0,0x6
    8000229e:	fce50513          	addi	a0,a0,-50 # 80008268 <digits+0x228>
    800022a2:	ffffe097          	auipc	ra,0xffffe
    800022a6:	29c080e7          	jalr	668(ra) # 8000053e <panic>
    panic("sched running");
    800022aa:	00006517          	auipc	a0,0x6
    800022ae:	fce50513          	addi	a0,a0,-50 # 80008278 <digits+0x238>
    800022b2:	ffffe097          	auipc	ra,0xffffe
    800022b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
    panic("sched interruptible");
    800022ba:	00006517          	auipc	a0,0x6
    800022be:	fce50513          	addi	a0,a0,-50 # 80008288 <digits+0x248>
    800022c2:	ffffe097          	auipc	ra,0xffffe
    800022c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>

00000000800022ca <yield>:
{
    800022ca:	1101                	addi	sp,sp,-32
    800022cc:	ec06                	sd	ra,24(sp)
    800022ce:	e822                	sd	s0,16(sp)
    800022d0:	e426                	sd	s1,8(sp)
    800022d2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	6f0080e7          	jalr	1776(ra) # 800019c4 <myproc>
    800022dc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	906080e7          	jalr	-1786(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800022e6:	478d                	li	a5,3
    800022e8:	cc9c                	sw	a5,24(s1)
  sched();
    800022ea:	00000097          	auipc	ra,0x0
    800022ee:	f0a080e7          	jalr	-246(ra) # 800021f4 <sched>
  release(&p->lock);
    800022f2:	8526                	mv	a0,s1
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	9a4080e7          	jalr	-1628(ra) # 80000c98 <release>
}
    800022fc:	60e2                	ld	ra,24(sp)
    800022fe:	6442                	ld	s0,16(sp)
    80002300:	64a2                	ld	s1,8(sp)
    80002302:	6105                	addi	sp,sp,32
    80002304:	8082                	ret

0000000080002306 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002306:	7179                	addi	sp,sp,-48
    80002308:	f406                	sd	ra,40(sp)
    8000230a:	f022                	sd	s0,32(sp)
    8000230c:	ec26                	sd	s1,24(sp)
    8000230e:	e84a                	sd	s2,16(sp)
    80002310:	e44e                	sd	s3,8(sp)
    80002312:	1800                	addi	s0,sp,48
    80002314:	89aa                	mv	s3,a0
    80002316:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	6ac080e7          	jalr	1708(ra) # 800019c4 <myproc>
    80002320:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	8c2080e7          	jalr	-1854(ra) # 80000be4 <acquire>
  release(lk);
    8000232a:	854a                	mv	a0,s2
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	96c080e7          	jalr	-1684(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002334:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002338:	4789                	li	a5,2
    8000233a:	cc9c                	sw	a5,24(s1)

  sched();
    8000233c:	00000097          	auipc	ra,0x0
    80002340:	eb8080e7          	jalr	-328(ra) # 800021f4 <sched>

  // Tidy up.
  p->chan = 0;
    80002344:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002348:	8526                	mv	a0,s1
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	94e080e7          	jalr	-1714(ra) # 80000c98 <release>
  acquire(lk);
    80002352:	854a                	mv	a0,s2
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	890080e7          	jalr	-1904(ra) # 80000be4 <acquire>
}
    8000235c:	70a2                	ld	ra,40(sp)
    8000235e:	7402                	ld	s0,32(sp)
    80002360:	64e2                	ld	s1,24(sp)
    80002362:	6942                	ld	s2,16(sp)
    80002364:	69a2                	ld	s3,8(sp)
    80002366:	6145                	addi	sp,sp,48
    80002368:	8082                	ret

000000008000236a <wait>:
{
    8000236a:	715d                	addi	sp,sp,-80
    8000236c:	e486                	sd	ra,72(sp)
    8000236e:	e0a2                	sd	s0,64(sp)
    80002370:	fc26                	sd	s1,56(sp)
    80002372:	f84a                	sd	s2,48(sp)
    80002374:	f44e                	sd	s3,40(sp)
    80002376:	f052                	sd	s4,32(sp)
    80002378:	ec56                	sd	s5,24(sp)
    8000237a:	e85a                	sd	s6,16(sp)
    8000237c:	e45e                	sd	s7,8(sp)
    8000237e:	e062                	sd	s8,0(sp)
    80002380:	0880                	addi	s0,sp,80
    80002382:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	640080e7          	jalr	1600(ra) # 800019c4 <myproc>
    8000238c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000238e:	0000f517          	auipc	a0,0xf
    80002392:	f2a50513          	addi	a0,a0,-214 # 800112b8 <wait_lock>
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	84e080e7          	jalr	-1970(ra) # 80000be4 <acquire>
    havekids = 0;
    8000239e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800023a0:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800023a2:	00015997          	auipc	s3,0x15
    800023a6:	f2e98993          	addi	s3,s3,-210 # 800172d0 <tickslock>
        havekids = 1;
    800023aa:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023ac:	0000fc17          	auipc	s8,0xf
    800023b0:	f0cc0c13          	addi	s8,s8,-244 # 800112b8 <wait_lock>
    havekids = 0;
    800023b4:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023b6:	0000f497          	auipc	s1,0xf
    800023ba:	31a48493          	addi	s1,s1,794 # 800116d0 <proc>
    800023be:	a0bd                	j	8000242c <wait+0xc2>
          pid = np->pid;
    800023c0:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023c4:	000b0e63          	beqz	s6,800023e0 <wait+0x76>
    800023c8:	4691                	li	a3,4
    800023ca:	02c48613          	addi	a2,s1,44
    800023ce:	85da                	mv	a1,s6
    800023d0:	05893503          	ld	a0,88(s2)
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	2a6080e7          	jalr	678(ra) # 8000167a <copyout>
    800023dc:	02054563          	bltz	a0,80002406 <wait+0x9c>
          freeproc(np);
    800023e0:	8526                	mv	a0,s1
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	794080e7          	jalr	1940(ra) # 80001b76 <freeproc>
          release(&np->lock);
    800023ea:	8526                	mv	a0,s1
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	8ac080e7          	jalr	-1876(ra) # 80000c98 <release>
          release(&wait_lock);
    800023f4:	0000f517          	auipc	a0,0xf
    800023f8:	ec450513          	addi	a0,a0,-316 # 800112b8 <wait_lock>
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	89c080e7          	jalr	-1892(ra) # 80000c98 <release>
          return pid;
    80002404:	a09d                	j	8000246a <wait+0x100>
            release(&np->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	890080e7          	jalr	-1904(ra) # 80000c98 <release>
            release(&wait_lock);
    80002410:	0000f517          	auipc	a0,0xf
    80002414:	ea850513          	addi	a0,a0,-344 # 800112b8 <wait_lock>
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	880080e7          	jalr	-1920(ra) # 80000c98 <release>
            return -1;
    80002420:	59fd                	li	s3,-1
    80002422:	a0a1                	j	8000246a <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002424:	17048493          	addi	s1,s1,368
    80002428:	03348463          	beq	s1,s3,80002450 <wait+0xe6>
      if(np->parent == p){
    8000242c:	60bc                	ld	a5,64(s1)
    8000242e:	ff279be3          	bne	a5,s2,80002424 <wait+0xba>
        acquire(&np->lock);
    80002432:	8526                	mv	a0,s1
    80002434:	ffffe097          	auipc	ra,0xffffe
    80002438:	7b0080e7          	jalr	1968(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000243c:	4c9c                	lw	a5,24(s1)
    8000243e:	f94781e3          	beq	a5,s4,800023c0 <wait+0x56>
        release(&np->lock);
    80002442:	8526                	mv	a0,s1
    80002444:	fffff097          	auipc	ra,0xfffff
    80002448:	854080e7          	jalr	-1964(ra) # 80000c98 <release>
        havekids = 1;
    8000244c:	8756                	mv	a4,s5
    8000244e:	bfd9                	j	80002424 <wait+0xba>
    if(!havekids || p->killed){
    80002450:	c701                	beqz	a4,80002458 <wait+0xee>
    80002452:	02892783          	lw	a5,40(s2)
    80002456:	c79d                	beqz	a5,80002484 <wait+0x11a>
      release(&wait_lock);
    80002458:	0000f517          	auipc	a0,0xf
    8000245c:	e6050513          	addi	a0,a0,-416 # 800112b8 <wait_lock>
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	838080e7          	jalr	-1992(ra) # 80000c98 <release>
      return -1;
    80002468:	59fd                	li	s3,-1
}
    8000246a:	854e                	mv	a0,s3
    8000246c:	60a6                	ld	ra,72(sp)
    8000246e:	6406                	ld	s0,64(sp)
    80002470:	74e2                	ld	s1,56(sp)
    80002472:	7942                	ld	s2,48(sp)
    80002474:	79a2                	ld	s3,40(sp)
    80002476:	7a02                	ld	s4,32(sp)
    80002478:	6ae2                	ld	s5,24(sp)
    8000247a:	6b42                	ld	s6,16(sp)
    8000247c:	6ba2                	ld	s7,8(sp)
    8000247e:	6c02                	ld	s8,0(sp)
    80002480:	6161                	addi	sp,sp,80
    80002482:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002484:	85e2                	mv	a1,s8
    80002486:	854a                	mv	a0,s2
    80002488:	00000097          	auipc	ra,0x0
    8000248c:	e7e080e7          	jalr	-386(ra) # 80002306 <sleep>
    havekids = 0;
    80002490:	b715                	j	800023b4 <wait+0x4a>

0000000080002492 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002492:	7139                	addi	sp,sp,-64
    80002494:	fc06                	sd	ra,56(sp)
    80002496:	f822                	sd	s0,48(sp)
    80002498:	f426                	sd	s1,40(sp)
    8000249a:	f04a                	sd	s2,32(sp)
    8000249c:	ec4e                	sd	s3,24(sp)
    8000249e:	e852                	sd	s4,16(sp)
    800024a0:	e456                	sd	s5,8(sp)
    800024a2:	0080                	addi	s0,sp,64
    800024a4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800024a6:	0000f497          	auipc	s1,0xf
    800024aa:	22a48493          	addi	s1,s1,554 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800024ae:	4989                	li	s3,2
        p->state = RUNNABLE;
    800024b0:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800024b2:	00015917          	auipc	s2,0x15
    800024b6:	e1e90913          	addi	s2,s2,-482 # 800172d0 <tickslock>
    800024ba:	a821                	j	800024d2 <wakeup+0x40>
        p->state = RUNNABLE;
    800024bc:	0154ac23          	sw	s5,24(s1)
        update_last_runnable_time(p);
      }
      release(&p->lock);
    800024c0:	8526                	mv	a0,s1
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	7d6080e7          	jalr	2006(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024ca:	17048493          	addi	s1,s1,368
    800024ce:	03248463          	beq	s1,s2,800024f6 <wakeup+0x64>
    if(p != myproc()){
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	4f2080e7          	jalr	1266(ra) # 800019c4 <myproc>
    800024da:	fea488e3          	beq	s1,a0,800024ca <wakeup+0x38>
      acquire(&p->lock);
    800024de:	8526                	mv	a0,s1
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	704080e7          	jalr	1796(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800024e8:	4c9c                	lw	a5,24(s1)
    800024ea:	fd379be3          	bne	a5,s3,800024c0 <wakeup+0x2e>
    800024ee:	709c                	ld	a5,32(s1)
    800024f0:	fd4798e3          	bne	a5,s4,800024c0 <wakeup+0x2e>
    800024f4:	b7e1                	j	800024bc <wakeup+0x2a>
    }
  }
}
    800024f6:	70e2                	ld	ra,56(sp)
    800024f8:	7442                	ld	s0,48(sp)
    800024fa:	74a2                	ld	s1,40(sp)
    800024fc:	7902                	ld	s2,32(sp)
    800024fe:	69e2                	ld	s3,24(sp)
    80002500:	6a42                	ld	s4,16(sp)
    80002502:	6aa2                	ld	s5,8(sp)
    80002504:	6121                	addi	sp,sp,64
    80002506:	8082                	ret

0000000080002508 <reparent>:
{
    80002508:	7179                	addi	sp,sp,-48
    8000250a:	f406                	sd	ra,40(sp)
    8000250c:	f022                	sd	s0,32(sp)
    8000250e:	ec26                	sd	s1,24(sp)
    80002510:	e84a                	sd	s2,16(sp)
    80002512:	e44e                	sd	s3,8(sp)
    80002514:	e052                	sd	s4,0(sp)
    80002516:	1800                	addi	s0,sp,48
    80002518:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000251a:	0000f497          	auipc	s1,0xf
    8000251e:	1b648493          	addi	s1,s1,438 # 800116d0 <proc>
      pp->parent = initproc;
    80002522:	00007a17          	auipc	s4,0x7
    80002526:	b0ea0a13          	addi	s4,s4,-1266 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000252a:	00015997          	auipc	s3,0x15
    8000252e:	da698993          	addi	s3,s3,-602 # 800172d0 <tickslock>
    80002532:	a029                	j	8000253c <reparent+0x34>
    80002534:	17048493          	addi	s1,s1,368
    80002538:	01348d63          	beq	s1,s3,80002552 <reparent+0x4a>
    if(pp->parent == p){
    8000253c:	60bc                	ld	a5,64(s1)
    8000253e:	ff279be3          	bne	a5,s2,80002534 <reparent+0x2c>
      pp->parent = initproc;
    80002542:	000a3503          	ld	a0,0(s4)
    80002546:	e0a8                	sd	a0,64(s1)
      wakeup(initproc);
    80002548:	00000097          	auipc	ra,0x0
    8000254c:	f4a080e7          	jalr	-182(ra) # 80002492 <wakeup>
    80002550:	b7d5                	j	80002534 <reparent+0x2c>
}
    80002552:	70a2                	ld	ra,40(sp)
    80002554:	7402                	ld	s0,32(sp)
    80002556:	64e2                	ld	s1,24(sp)
    80002558:	6942                	ld	s2,16(sp)
    8000255a:	69a2                	ld	s3,8(sp)
    8000255c:	6a02                	ld	s4,0(sp)
    8000255e:	6145                	addi	sp,sp,48
    80002560:	8082                	ret

0000000080002562 <exit>:
{
    80002562:	7179                	addi	sp,sp,-48
    80002564:	f406                	sd	ra,40(sp)
    80002566:	f022                	sd	s0,32(sp)
    80002568:	ec26                	sd	s1,24(sp)
    8000256a:	e84a                	sd	s2,16(sp)
    8000256c:	e44e                	sd	s3,8(sp)
    8000256e:	e052                	sd	s4,0(sp)
    80002570:	1800                	addi	s0,sp,48
    80002572:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	450080e7          	jalr	1104(ra) # 800019c4 <myproc>
    8000257c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000257e:	00007797          	auipc	a5,0x7
    80002582:	ab27b783          	ld	a5,-1358(a5) # 80009030 <initproc>
    80002586:	0d850493          	addi	s1,a0,216
    8000258a:	15850913          	addi	s2,a0,344
    8000258e:	02a79363          	bne	a5,a0,800025b4 <exit+0x52>
    panic("init exiting");
    80002592:	00006517          	auipc	a0,0x6
    80002596:	d0e50513          	addi	a0,a0,-754 # 800082a0 <digits+0x260>
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	fa4080e7          	jalr	-92(ra) # 8000053e <panic>
      fileclose(f);
    800025a2:	00002097          	auipc	ra,0x2
    800025a6:	250080e7          	jalr	592(ra) # 800047f2 <fileclose>
      p->ofile[fd] = 0;
    800025aa:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800025ae:	04a1                	addi	s1,s1,8
    800025b0:	01248563          	beq	s1,s2,800025ba <exit+0x58>
    if(p->ofile[fd]){
    800025b4:	6088                	ld	a0,0(s1)
    800025b6:	f575                	bnez	a0,800025a2 <exit+0x40>
    800025b8:	bfdd                	j	800025ae <exit+0x4c>
  begin_op();
    800025ba:	00002097          	auipc	ra,0x2
    800025be:	d6c080e7          	jalr	-660(ra) # 80004326 <begin_op>
  iput(p->cwd);
    800025c2:	1589b503          	ld	a0,344(s3)
    800025c6:	00001097          	auipc	ra,0x1
    800025ca:	548080e7          	jalr	1352(ra) # 80003b0e <iput>
  end_op();
    800025ce:	00002097          	auipc	ra,0x2
    800025d2:	dd8080e7          	jalr	-552(ra) # 800043a6 <end_op>
  p->cwd = 0;
    800025d6:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    800025da:	0000f497          	auipc	s1,0xf
    800025de:	cde48493          	addi	s1,s1,-802 # 800112b8 <wait_lock>
    800025e2:	8526                	mv	a0,s1
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	600080e7          	jalr	1536(ra) # 80000be4 <acquire>
  reparent(p);
    800025ec:	854e                	mv	a0,s3
    800025ee:	00000097          	auipc	ra,0x0
    800025f2:	f1a080e7          	jalr	-230(ra) # 80002508 <reparent>
  wakeup(p->parent);
    800025f6:	0409b503          	ld	a0,64(s3)
    800025fa:	00000097          	auipc	ra,0x0
    800025fe:	e98080e7          	jalr	-360(ra) # 80002492 <wakeup>
  acquire(&p->lock);
    80002602:	854e                	mv	a0,s3
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	5e0080e7          	jalr	1504(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000260c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002610:	4795                	li	a5,5
    80002612:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002616:	8526                	mv	a0,s1
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	680080e7          	jalr	1664(ra) # 80000c98 <release>
  sched();
    80002620:	00000097          	auipc	ra,0x0
    80002624:	bd4080e7          	jalr	-1068(ra) # 800021f4 <sched>
  panic("zombie exit");
    80002628:	00006517          	auipc	a0,0x6
    8000262c:	c8850513          	addi	a0,a0,-888 # 800082b0 <digits+0x270>
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	f0e080e7          	jalr	-242(ra) # 8000053e <panic>

0000000080002638 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002638:	7179                	addi	sp,sp,-48
    8000263a:	f406                	sd	ra,40(sp)
    8000263c:	f022                	sd	s0,32(sp)
    8000263e:	ec26                	sd	s1,24(sp)
    80002640:	e84a                	sd	s2,16(sp)
    80002642:	e44e                	sd	s3,8(sp)
    80002644:	1800                	addi	s0,sp,48
    80002646:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002648:	0000f497          	auipc	s1,0xf
    8000264c:	08848493          	addi	s1,s1,136 # 800116d0 <proc>
    80002650:	00015997          	auipc	s3,0x15
    80002654:	c8098993          	addi	s3,s3,-896 # 800172d0 <tickslock>
    acquire(&p->lock);
    80002658:	8526                	mv	a0,s1
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	58a080e7          	jalr	1418(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002662:	589c                	lw	a5,48(s1)
    80002664:	01278d63          	beq	a5,s2,8000267e <kill+0x46>
        update_last_runnable_time(p);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002668:	8526                	mv	a0,s1
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	62e080e7          	jalr	1582(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002672:	17048493          	addi	s1,s1,368
    80002676:	ff3491e3          	bne	s1,s3,80002658 <kill+0x20>
  }
  return -1;
    8000267a:	557d                	li	a0,-1
    8000267c:	a829                	j	80002696 <kill+0x5e>
      p->killed = 1;
    8000267e:	4785                	li	a5,1
    80002680:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002682:	4c98                	lw	a4,24(s1)
    80002684:	4789                	li	a5,2
    80002686:	00f70f63          	beq	a4,a5,800026a4 <kill+0x6c>
      release(&p->lock);
    8000268a:	8526                	mv	a0,s1
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	60c080e7          	jalr	1548(ra) # 80000c98 <release>
      return 0;
    80002694:	4501                	li	a0,0
}
    80002696:	70a2                	ld	ra,40(sp)
    80002698:	7402                	ld	s0,32(sp)
    8000269a:	64e2                	ld	s1,24(sp)
    8000269c:	6942                	ld	s2,16(sp)
    8000269e:	69a2                	ld	s3,8(sp)
    800026a0:	6145                	addi	sp,sp,48
    800026a2:	8082                	ret
        p->state = RUNNABLE;
    800026a4:	478d                	li	a5,3
    800026a6:	cc9c                	sw	a5,24(s1)
        update_last_runnable_time(p);
    800026a8:	b7cd                	j	8000268a <kill+0x52>

00000000800026aa <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026aa:	7179                	addi	sp,sp,-48
    800026ac:	f406                	sd	ra,40(sp)
    800026ae:	f022                	sd	s0,32(sp)
    800026b0:	ec26                	sd	s1,24(sp)
    800026b2:	e84a                	sd	s2,16(sp)
    800026b4:	e44e                	sd	s3,8(sp)
    800026b6:	e052                	sd	s4,0(sp)
    800026b8:	1800                	addi	s0,sp,48
    800026ba:	84aa                	mv	s1,a0
    800026bc:	892e                	mv	s2,a1
    800026be:	89b2                	mv	s3,a2
    800026c0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026c2:	fffff097          	auipc	ra,0xfffff
    800026c6:	302080e7          	jalr	770(ra) # 800019c4 <myproc>
  if(user_dst){
    800026ca:	c08d                	beqz	s1,800026ec <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026cc:	86d2                	mv	a3,s4
    800026ce:	864e                	mv	a2,s3
    800026d0:	85ca                	mv	a1,s2
    800026d2:	6d28                	ld	a0,88(a0)
    800026d4:	fffff097          	auipc	ra,0xfffff
    800026d8:	fa6080e7          	jalr	-90(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026dc:	70a2                	ld	ra,40(sp)
    800026de:	7402                	ld	s0,32(sp)
    800026e0:	64e2                	ld	s1,24(sp)
    800026e2:	6942                	ld	s2,16(sp)
    800026e4:	69a2                	ld	s3,8(sp)
    800026e6:	6a02                	ld	s4,0(sp)
    800026e8:	6145                	addi	sp,sp,48
    800026ea:	8082                	ret
    memmove((char *)dst, src, len);
    800026ec:	000a061b          	sext.w	a2,s4
    800026f0:	85ce                	mv	a1,s3
    800026f2:	854a                	mv	a0,s2
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	64c080e7          	jalr	1612(ra) # 80000d40 <memmove>
    return 0;
    800026fc:	8526                	mv	a0,s1
    800026fe:	bff9                	j	800026dc <either_copyout+0x32>

0000000080002700 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002700:	7179                	addi	sp,sp,-48
    80002702:	f406                	sd	ra,40(sp)
    80002704:	f022                	sd	s0,32(sp)
    80002706:	ec26                	sd	s1,24(sp)
    80002708:	e84a                	sd	s2,16(sp)
    8000270a:	e44e                	sd	s3,8(sp)
    8000270c:	e052                	sd	s4,0(sp)
    8000270e:	1800                	addi	s0,sp,48
    80002710:	892a                	mv	s2,a0
    80002712:	84ae                	mv	s1,a1
    80002714:	89b2                	mv	s3,a2
    80002716:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002718:	fffff097          	auipc	ra,0xfffff
    8000271c:	2ac080e7          	jalr	684(ra) # 800019c4 <myproc>
  if(user_src){
    80002720:	c08d                	beqz	s1,80002742 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002722:	86d2                	mv	a3,s4
    80002724:	864e                	mv	a2,s3
    80002726:	85ca                	mv	a1,s2
    80002728:	6d28                	ld	a0,88(a0)
    8000272a:	fffff097          	auipc	ra,0xfffff
    8000272e:	fdc080e7          	jalr	-36(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002732:	70a2                	ld	ra,40(sp)
    80002734:	7402                	ld	s0,32(sp)
    80002736:	64e2                	ld	s1,24(sp)
    80002738:	6942                	ld	s2,16(sp)
    8000273a:	69a2                	ld	s3,8(sp)
    8000273c:	6a02                	ld	s4,0(sp)
    8000273e:	6145                	addi	sp,sp,48
    80002740:	8082                	ret
    memmove(dst, (char*)src, len);
    80002742:	000a061b          	sext.w	a2,s4
    80002746:	85ce                	mv	a1,s3
    80002748:	854a                	mv	a0,s2
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	5f6080e7          	jalr	1526(ra) # 80000d40 <memmove>
    return 0;
    80002752:	8526                	mv	a0,s1
    80002754:	bff9                	j	80002732 <either_copyin+0x32>

0000000080002756 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002756:	715d                	addi	sp,sp,-80
    80002758:	e486                	sd	ra,72(sp)
    8000275a:	e0a2                	sd	s0,64(sp)
    8000275c:	fc26                	sd	s1,56(sp)
    8000275e:	f84a                	sd	s2,48(sp)
    80002760:	f44e                	sd	s3,40(sp)
    80002762:	f052                	sd	s4,32(sp)
    80002764:	ec56                	sd	s5,24(sp)
    80002766:	e85a                	sd	s6,16(sp)
    80002768:	e45e                	sd	s7,8(sp)
    8000276a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000276c:	00006517          	auipc	a0,0x6
    80002770:	95c50513          	addi	a0,a0,-1700 # 800080c8 <digits+0x88>
    80002774:	ffffe097          	auipc	ra,0xffffe
    80002778:	e14080e7          	jalr	-492(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000277c:	0000f497          	auipc	s1,0xf
    80002780:	0b448493          	addi	s1,s1,180 # 80011830 <proc+0x160>
    80002784:	00015917          	auipc	s2,0x15
    80002788:	cac90913          	addi	s2,s2,-852 # 80017430 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000278c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000278e:	00006997          	auipc	s3,0x6
    80002792:	b3298993          	addi	s3,s3,-1230 # 800082c0 <digits+0x280>
    printf("%d %s %s", p->pid, state, p->name);
    80002796:	00006a97          	auipc	s5,0x6
    8000279a:	b32a8a93          	addi	s5,s5,-1230 # 800082c8 <digits+0x288>
    printf("\n");
    8000279e:	00006a17          	auipc	s4,0x6
    800027a2:	92aa0a13          	addi	s4,s4,-1750 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027a6:	00006b97          	auipc	s7,0x6
    800027aa:	b5ab8b93          	addi	s7,s7,-1190 # 80008300 <states.1766>
    800027ae:	a00d                	j	800027d0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027b0:	ed06a583          	lw	a1,-304(a3)
    800027b4:	8556                	mv	a0,s5
    800027b6:	ffffe097          	auipc	ra,0xffffe
    800027ba:	dd2080e7          	jalr	-558(ra) # 80000588 <printf>
    printf("\n");
    800027be:	8552                	mv	a0,s4
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	dc8080e7          	jalr	-568(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027c8:	17048493          	addi	s1,s1,368
    800027cc:	03248163          	beq	s1,s2,800027ee <procdump+0x98>
    if(p->state == UNUSED)
    800027d0:	86a6                	mv	a3,s1
    800027d2:	eb84a783          	lw	a5,-328(s1)
    800027d6:	dbed                	beqz	a5,800027c8 <procdump+0x72>
      state = "???";
    800027d8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027da:	fcfb6be3          	bltu	s6,a5,800027b0 <procdump+0x5a>
    800027de:	1782                	slli	a5,a5,0x20
    800027e0:	9381                	srli	a5,a5,0x20
    800027e2:	078e                	slli	a5,a5,0x3
    800027e4:	97de                	add	a5,a5,s7
    800027e6:	6390                	ld	a2,0(a5)
    800027e8:	f661                	bnez	a2,800027b0 <procdump+0x5a>
      state = "???";
    800027ea:	864e                	mv	a2,s3
    800027ec:	b7d1                	j	800027b0 <procdump+0x5a>
  }
}
    800027ee:	60a6                	ld	ra,72(sp)
    800027f0:	6406                	ld	s0,64(sp)
    800027f2:	74e2                	ld	s1,56(sp)
    800027f4:	7942                	ld	s2,48(sp)
    800027f6:	79a2                	ld	s3,40(sp)
    800027f8:	7a02                	ld	s4,32(sp)
    800027fa:	6ae2                	ld	s5,24(sp)
    800027fc:	6b42                	ld	s6,16(sp)
    800027fe:	6ba2                	ld	s7,8(sp)
    80002800:	6161                	addi	sp,sp,80
    80002802:	8082                	ret

0000000080002804 <pause_system>:

// pause all user processes for the number of seconds specified by thesecond's integer parameter.
int pause_system(int seconds){
    80002804:	1141                	addi	sp,sp,-16
    80002806:	e406                	sd	ra,8(sp)
    80002808:	e022                	sd	s0,0(sp)
    8000280a:	0800                	addi	s0,sp,16
  pause_ticks = ticks + seconds * SECONDS_TO_TICKS;
    8000280c:	0025179b          	slliw	a5,a0,0x2
    80002810:	9fa9                	addw	a5,a5,a0
    80002812:	0017979b          	slliw	a5,a5,0x1
    80002816:	00007517          	auipc	a0,0x7
    8000281a:	82252503          	lw	a0,-2014(a0) # 80009038 <ticks>
    8000281e:	9fa9                	addw	a5,a5,a0
    80002820:	00007717          	auipc	a4,0x7
    80002824:	80f72423          	sw	a5,-2040(a4) # 80009028 <pause_ticks>
  yield();
    80002828:	00000097          	auipc	ra,0x0
    8000282c:	aa2080e7          	jalr	-1374(ra) # 800022ca <yield>

  return 0;
}
    80002830:	4501                	li	a0,0
    80002832:	60a2                	ld	ra,8(sp)
    80002834:	6402                	ld	s0,0(sp)
    80002836:	0141                	addi	sp,sp,16
    80002838:	8082                	ret

000000008000283a <kill_system>:

// terminate all user processes
int 
kill_system(void) {
    8000283a:	7179                	addi	sp,sp,-48
    8000283c:	f406                	sd	ra,40(sp)
    8000283e:	f022                	sd	s0,32(sp)
    80002840:	ec26                	sd	s1,24(sp)
    80002842:	e84a                	sd	s2,16(sp)
    80002844:	e44e                	sd	s3,8(sp)
    80002846:	e052                	sd	s4,0(sp)
    80002848:	1800                	addi	s0,sp,48
  struct proc *p;
  int pid;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000284a:	0000f497          	auipc	s1,0xf
    8000284e:	e8648493          	addi	s1,s1,-378 # 800116d0 <proc>
      acquire(&p->lock);
      pid = p->pid;
      release(&p->lock);
      if(pid != INIT_PROC_ID && pid != SHELL_PROC_ID)
    80002852:	4a05                	li	s4,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80002854:	00015997          	auipc	s3,0x15
    80002858:	a7c98993          	addi	s3,s3,-1412 # 800172d0 <tickslock>
    8000285c:	a029                	j	80002866 <kill_system+0x2c>
    8000285e:	17048493          	addi	s1,s1,368
    80002862:	03348863          	beq	s1,s3,80002892 <kill_system+0x58>
      acquire(&p->lock);
    80002866:	8526                	mv	a0,s1
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	37c080e7          	jalr	892(ra) # 80000be4 <acquire>
      pid = p->pid;
    80002870:	0304a903          	lw	s2,48(s1)
      release(&p->lock);
    80002874:	8526                	mv	a0,s1
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	422080e7          	jalr	1058(ra) # 80000c98 <release>
      if(pid != INIT_PROC_ID && pid != SHELL_PROC_ID)
    8000287e:	fff9079b          	addiw	a5,s2,-1
    80002882:	fcfa7ee3          	bgeu	s4,a5,8000285e <kill_system+0x24>
        kill(pid);
    80002886:	854a                	mv	a0,s2
    80002888:	00000097          	auipc	ra,0x0
    8000288c:	db0080e7          	jalr	-592(ra) # 80002638 <kill>
    80002890:	b7f9                	j	8000285e <kill_system+0x24>
  }
  return 0;
}
    80002892:	4501                	li	a0,0
    80002894:	70a2                	ld	ra,40(sp)
    80002896:	7402                	ld	s0,32(sp)
    80002898:	64e2                	ld	s1,24(sp)
    8000289a:	6942                	ld	s2,16(sp)
    8000289c:	69a2                	ld	s3,8(sp)
    8000289e:	6a02                	ld	s4,0(sp)
    800028a0:	6145                	addi	sp,sp,48
    800028a2:	8082                	ret

00000000800028a4 <swtch>:
    800028a4:	00153023          	sd	ra,0(a0)
    800028a8:	00253423          	sd	sp,8(a0)
    800028ac:	e900                	sd	s0,16(a0)
    800028ae:	ed04                	sd	s1,24(a0)
    800028b0:	03253023          	sd	s2,32(a0)
    800028b4:	03353423          	sd	s3,40(a0)
    800028b8:	03453823          	sd	s4,48(a0)
    800028bc:	03553c23          	sd	s5,56(a0)
    800028c0:	05653023          	sd	s6,64(a0)
    800028c4:	05753423          	sd	s7,72(a0)
    800028c8:	05853823          	sd	s8,80(a0)
    800028cc:	05953c23          	sd	s9,88(a0)
    800028d0:	07a53023          	sd	s10,96(a0)
    800028d4:	07b53423          	sd	s11,104(a0)
    800028d8:	0005b083          	ld	ra,0(a1)
    800028dc:	0085b103          	ld	sp,8(a1)
    800028e0:	6980                	ld	s0,16(a1)
    800028e2:	6d84                	ld	s1,24(a1)
    800028e4:	0205b903          	ld	s2,32(a1)
    800028e8:	0285b983          	ld	s3,40(a1)
    800028ec:	0305ba03          	ld	s4,48(a1)
    800028f0:	0385ba83          	ld	s5,56(a1)
    800028f4:	0405bb03          	ld	s6,64(a1)
    800028f8:	0485bb83          	ld	s7,72(a1)
    800028fc:	0505bc03          	ld	s8,80(a1)
    80002900:	0585bc83          	ld	s9,88(a1)
    80002904:	0605bd03          	ld	s10,96(a1)
    80002908:	0685bd83          	ld	s11,104(a1)
    8000290c:	8082                	ret

000000008000290e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000290e:	1141                	addi	sp,sp,-16
    80002910:	e406                	sd	ra,8(sp)
    80002912:	e022                	sd	s0,0(sp)
    80002914:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002916:	00006597          	auipc	a1,0x6
    8000291a:	a1a58593          	addi	a1,a1,-1510 # 80008330 <states.1766+0x30>
    8000291e:	00015517          	auipc	a0,0x15
    80002922:	9b250513          	addi	a0,a0,-1614 # 800172d0 <tickslock>
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	22e080e7          	jalr	558(ra) # 80000b54 <initlock>
}
    8000292e:	60a2                	ld	ra,8(sp)
    80002930:	6402                	ld	s0,0(sp)
    80002932:	0141                	addi	sp,sp,16
    80002934:	8082                	ret

0000000080002936 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002936:	1141                	addi	sp,sp,-16
    80002938:	e422                	sd	s0,8(sp)
    8000293a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000293c:	00003797          	auipc	a5,0x3
    80002940:	4d478793          	addi	a5,a5,1236 # 80005e10 <kernelvec>
    80002944:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002948:	6422                	ld	s0,8(sp)
    8000294a:	0141                	addi	sp,sp,16
    8000294c:	8082                	ret

000000008000294e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000294e:	1141                	addi	sp,sp,-16
    80002950:	e406                	sd	ra,8(sp)
    80002952:	e022                	sd	s0,0(sp)
    80002954:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002956:	fffff097          	auipc	ra,0xfffff
    8000295a:	06e080e7          	jalr	110(ra) # 800019c4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000295e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002962:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002964:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002968:	00004617          	auipc	a2,0x4
    8000296c:	69860613          	addi	a2,a2,1688 # 80007000 <_trampoline>
    80002970:	00004697          	auipc	a3,0x4
    80002974:	69068693          	addi	a3,a3,1680 # 80007000 <_trampoline>
    80002978:	8e91                	sub	a3,a3,a2
    8000297a:	040007b7          	lui	a5,0x4000
    8000297e:	17fd                	addi	a5,a5,-1
    80002980:	07b2                	slli	a5,a5,0xc
    80002982:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002984:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002988:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000298a:	180026f3          	csrr	a3,satp
    8000298e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002990:	7138                	ld	a4,96(a0)
    80002992:	6534                	ld	a3,72(a0)
    80002994:	6585                	lui	a1,0x1
    80002996:	96ae                	add	a3,a3,a1
    80002998:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000299a:	7138                	ld	a4,96(a0)
    8000299c:	00000697          	auipc	a3,0x0
    800029a0:	13868693          	addi	a3,a3,312 # 80002ad4 <usertrap>
    800029a4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029a6:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029a8:	8692                	mv	a3,tp
    800029aa:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ac:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029b0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029b4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029bc:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029be:	6f18                	ld	a4,24(a4)
    800029c0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029c4:	6d2c                	ld	a1,88(a0)
    800029c6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029c8:	00004717          	auipc	a4,0x4
    800029cc:	6c870713          	addi	a4,a4,1736 # 80007090 <userret>
    800029d0:	8f11                	sub	a4,a4,a2
    800029d2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029d4:	577d                	li	a4,-1
    800029d6:	177e                	slli	a4,a4,0x3f
    800029d8:	8dd9                	or	a1,a1,a4
    800029da:	02000537          	lui	a0,0x2000
    800029de:	157d                	addi	a0,a0,-1
    800029e0:	0536                	slli	a0,a0,0xd
    800029e2:	9782                	jalr	a5
}
    800029e4:	60a2                	ld	ra,8(sp)
    800029e6:	6402                	ld	s0,0(sp)
    800029e8:	0141                	addi	sp,sp,16
    800029ea:	8082                	ret

00000000800029ec <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029ec:	1101                	addi	sp,sp,-32
    800029ee:	ec06                	sd	ra,24(sp)
    800029f0:	e822                	sd	s0,16(sp)
    800029f2:	e426                	sd	s1,8(sp)
    800029f4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029f6:	00015497          	auipc	s1,0x15
    800029fa:	8da48493          	addi	s1,s1,-1830 # 800172d0 <tickslock>
    800029fe:	8526                	mv	a0,s1
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	1e4080e7          	jalr	484(ra) # 80000be4 <acquire>
  ticks++;
    80002a08:	00006517          	auipc	a0,0x6
    80002a0c:	63050513          	addi	a0,a0,1584 # 80009038 <ticks>
    80002a10:	411c                	lw	a5,0(a0)
    80002a12:	2785                	addiw	a5,a5,1
    80002a14:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a16:	00000097          	auipc	ra,0x0
    80002a1a:	a7c080e7          	jalr	-1412(ra) # 80002492 <wakeup>
  release(&tickslock);
    80002a1e:	8526                	mv	a0,s1
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	278080e7          	jalr	632(ra) # 80000c98 <release>
}
    80002a28:	60e2                	ld	ra,24(sp)
    80002a2a:	6442                	ld	s0,16(sp)
    80002a2c:	64a2                	ld	s1,8(sp)
    80002a2e:	6105                	addi	sp,sp,32
    80002a30:	8082                	ret

0000000080002a32 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a32:	1101                	addi	sp,sp,-32
    80002a34:	ec06                	sd	ra,24(sp)
    80002a36:	e822                	sd	s0,16(sp)
    80002a38:	e426                	sd	s1,8(sp)
    80002a3a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a3c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a40:	00074d63          	bltz	a4,80002a5a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a44:	57fd                	li	a5,-1
    80002a46:	17fe                	slli	a5,a5,0x3f
    80002a48:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a4a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a4c:	06f70363          	beq	a4,a5,80002ab2 <devintr+0x80>
  }
}
    80002a50:	60e2                	ld	ra,24(sp)
    80002a52:	6442                	ld	s0,16(sp)
    80002a54:	64a2                	ld	s1,8(sp)
    80002a56:	6105                	addi	sp,sp,32
    80002a58:	8082                	ret
     (scause & 0xff) == 9){
    80002a5a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a5e:	46a5                	li	a3,9
    80002a60:	fed792e3          	bne	a5,a3,80002a44 <devintr+0x12>
    int irq = plic_claim();
    80002a64:	00003097          	auipc	ra,0x3
    80002a68:	4b4080e7          	jalr	1204(ra) # 80005f18 <plic_claim>
    80002a6c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a6e:	47a9                	li	a5,10
    80002a70:	02f50763          	beq	a0,a5,80002a9e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a74:	4785                	li	a5,1
    80002a76:	02f50963          	beq	a0,a5,80002aa8 <devintr+0x76>
    return 1;
    80002a7a:	4505                	li	a0,1
    } else if(irq){
    80002a7c:	d8f1                	beqz	s1,80002a50 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a7e:	85a6                	mv	a1,s1
    80002a80:	00006517          	auipc	a0,0x6
    80002a84:	8b850513          	addi	a0,a0,-1864 # 80008338 <states.1766+0x38>
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	b00080e7          	jalr	-1280(ra) # 80000588 <printf>
      plic_complete(irq);
    80002a90:	8526                	mv	a0,s1
    80002a92:	00003097          	auipc	ra,0x3
    80002a96:	4aa080e7          	jalr	1194(ra) # 80005f3c <plic_complete>
    return 1;
    80002a9a:	4505                	li	a0,1
    80002a9c:	bf55                	j	80002a50 <devintr+0x1e>
      uartintr();
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	f0a080e7          	jalr	-246(ra) # 800009a8 <uartintr>
    80002aa6:	b7ed                	j	80002a90 <devintr+0x5e>
      virtio_disk_intr();
    80002aa8:	00004097          	auipc	ra,0x4
    80002aac:	974080e7          	jalr	-1676(ra) # 8000641c <virtio_disk_intr>
    80002ab0:	b7c5                	j	80002a90 <devintr+0x5e>
    if(cpuid() == 0){
    80002ab2:	fffff097          	auipc	ra,0xfffff
    80002ab6:	ee6080e7          	jalr	-282(ra) # 80001998 <cpuid>
    80002aba:	c901                	beqz	a0,80002aca <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002abc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ac0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ac2:	14479073          	csrw	sip,a5
    return 2;
    80002ac6:	4509                	li	a0,2
    80002ac8:	b761                	j	80002a50 <devintr+0x1e>
      clockintr();
    80002aca:	00000097          	auipc	ra,0x0
    80002ace:	f22080e7          	jalr	-222(ra) # 800029ec <clockintr>
    80002ad2:	b7ed                	j	80002abc <devintr+0x8a>

0000000080002ad4 <usertrap>:
{
    80002ad4:	1101                	addi	sp,sp,-32
    80002ad6:	ec06                	sd	ra,24(sp)
    80002ad8:	e822                	sd	s0,16(sp)
    80002ada:	e426                	sd	s1,8(sp)
    80002adc:	e04a                	sd	s2,0(sp)
    80002ade:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ae0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ae4:	1007f793          	andi	a5,a5,256
    80002ae8:	e3ad                	bnez	a5,80002b4a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aea:	00003797          	auipc	a5,0x3
    80002aee:	32678793          	addi	a5,a5,806 # 80005e10 <kernelvec>
    80002af2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002af6:	fffff097          	auipc	ra,0xfffff
    80002afa:	ece080e7          	jalr	-306(ra) # 800019c4 <myproc>
    80002afe:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b00:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b02:	14102773          	csrr	a4,sepc
    80002b06:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b08:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b0c:	47a1                	li	a5,8
    80002b0e:	04f71c63          	bne	a4,a5,80002b66 <usertrap+0x92>
    if(p->killed)
    80002b12:	551c                	lw	a5,40(a0)
    80002b14:	e3b9                	bnez	a5,80002b5a <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b16:	70b8                	ld	a4,96(s1)
    80002b18:	6f1c                	ld	a5,24(a4)
    80002b1a:	0791                	addi	a5,a5,4
    80002b1c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b1e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b22:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b26:	10079073          	csrw	sstatus,a5
    syscall();
    80002b2a:	00000097          	auipc	ra,0x0
    80002b2e:	2e0080e7          	jalr	736(ra) # 80002e0a <syscall>
  if(p->killed)
    80002b32:	549c                	lw	a5,40(s1)
    80002b34:	ebc1                	bnez	a5,80002bc4 <usertrap+0xf0>
  usertrapret();
    80002b36:	00000097          	auipc	ra,0x0
    80002b3a:	e18080e7          	jalr	-488(ra) # 8000294e <usertrapret>
}
    80002b3e:	60e2                	ld	ra,24(sp)
    80002b40:	6442                	ld	s0,16(sp)
    80002b42:	64a2                	ld	s1,8(sp)
    80002b44:	6902                	ld	s2,0(sp)
    80002b46:	6105                	addi	sp,sp,32
    80002b48:	8082                	ret
    panic("usertrap: not from user mode");
    80002b4a:	00006517          	auipc	a0,0x6
    80002b4e:	80e50513          	addi	a0,a0,-2034 # 80008358 <states.1766+0x58>
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	9ec080e7          	jalr	-1556(ra) # 8000053e <panic>
      exit(-1);
    80002b5a:	557d                	li	a0,-1
    80002b5c:	00000097          	auipc	ra,0x0
    80002b60:	a06080e7          	jalr	-1530(ra) # 80002562 <exit>
    80002b64:	bf4d                	j	80002b16 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b66:	00000097          	auipc	ra,0x0
    80002b6a:	ecc080e7          	jalr	-308(ra) # 80002a32 <devintr>
    80002b6e:	892a                	mv	s2,a0
    80002b70:	c501                	beqz	a0,80002b78 <usertrap+0xa4>
  if(p->killed)
    80002b72:	549c                	lw	a5,40(s1)
    80002b74:	c3a1                	beqz	a5,80002bb4 <usertrap+0xe0>
    80002b76:	a815                	j	80002baa <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b78:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b7c:	5890                	lw	a2,48(s1)
    80002b7e:	00005517          	auipc	a0,0x5
    80002b82:	7fa50513          	addi	a0,a0,2042 # 80008378 <states.1766+0x78>
    80002b86:	ffffe097          	auipc	ra,0xffffe
    80002b8a:	a02080e7          	jalr	-1534(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b8e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b92:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b96:	00006517          	auipc	a0,0x6
    80002b9a:	81250513          	addi	a0,a0,-2030 # 800083a8 <states.1766+0xa8>
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	9ea080e7          	jalr	-1558(ra) # 80000588 <printf>
    p->killed = 1;
    80002ba6:	4785                	li	a5,1
    80002ba8:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002baa:	557d                	li	a0,-1
    80002bac:	00000097          	auipc	ra,0x0
    80002bb0:	9b6080e7          	jalr	-1610(ra) # 80002562 <exit>
  if(which_dev == 2)
    80002bb4:	4789                	li	a5,2
    80002bb6:	f8f910e3          	bne	s2,a5,80002b36 <usertrap+0x62>
    yield();
    80002bba:	fffff097          	auipc	ra,0xfffff
    80002bbe:	710080e7          	jalr	1808(ra) # 800022ca <yield>
    80002bc2:	bf95                	j	80002b36 <usertrap+0x62>
  int which_dev = 0;
    80002bc4:	4901                	li	s2,0
    80002bc6:	b7d5                	j	80002baa <usertrap+0xd6>

0000000080002bc8 <kerneltrap>:
{
    80002bc8:	7179                	addi	sp,sp,-48
    80002bca:	f406                	sd	ra,40(sp)
    80002bcc:	f022                	sd	s0,32(sp)
    80002bce:	ec26                	sd	s1,24(sp)
    80002bd0:	e84a                	sd	s2,16(sp)
    80002bd2:	e44e                	sd	s3,8(sp)
    80002bd4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bda:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bde:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002be2:	1004f793          	andi	a5,s1,256
    80002be6:	cb85                	beqz	a5,80002c16 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002be8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bec:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002bee:	ef85                	bnez	a5,80002c26 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002bf0:	00000097          	auipc	ra,0x0
    80002bf4:	e42080e7          	jalr	-446(ra) # 80002a32 <devintr>
    80002bf8:	cd1d                	beqz	a0,80002c36 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bfa:	4789                	li	a5,2
    80002bfc:	06f50a63          	beq	a0,a5,80002c70 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c00:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c04:	10049073          	csrw	sstatus,s1
}
    80002c08:	70a2                	ld	ra,40(sp)
    80002c0a:	7402                	ld	s0,32(sp)
    80002c0c:	64e2                	ld	s1,24(sp)
    80002c0e:	6942                	ld	s2,16(sp)
    80002c10:	69a2                	ld	s3,8(sp)
    80002c12:	6145                	addi	sp,sp,48
    80002c14:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c16:	00005517          	auipc	a0,0x5
    80002c1a:	7b250513          	addi	a0,a0,1970 # 800083c8 <states.1766+0xc8>
    80002c1e:	ffffe097          	auipc	ra,0xffffe
    80002c22:	920080e7          	jalr	-1760(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002c26:	00005517          	auipc	a0,0x5
    80002c2a:	7ca50513          	addi	a0,a0,1994 # 800083f0 <states.1766+0xf0>
    80002c2e:	ffffe097          	auipc	ra,0xffffe
    80002c32:	910080e7          	jalr	-1776(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002c36:	85ce                	mv	a1,s3
    80002c38:	00005517          	auipc	a0,0x5
    80002c3c:	7d850513          	addi	a0,a0,2008 # 80008410 <states.1766+0x110>
    80002c40:	ffffe097          	auipc	ra,0xffffe
    80002c44:	948080e7          	jalr	-1720(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c48:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c4c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c50:	00005517          	auipc	a0,0x5
    80002c54:	7d050513          	addi	a0,a0,2000 # 80008420 <states.1766+0x120>
    80002c58:	ffffe097          	auipc	ra,0xffffe
    80002c5c:	930080e7          	jalr	-1744(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002c60:	00005517          	auipc	a0,0x5
    80002c64:	7d850513          	addi	a0,a0,2008 # 80008438 <states.1766+0x138>
    80002c68:	ffffe097          	auipc	ra,0xffffe
    80002c6c:	8d6080e7          	jalr	-1834(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	d54080e7          	jalr	-684(ra) # 800019c4 <myproc>
    80002c78:	d541                	beqz	a0,80002c00 <kerneltrap+0x38>
    80002c7a:	fffff097          	auipc	ra,0xfffff
    80002c7e:	d4a080e7          	jalr	-694(ra) # 800019c4 <myproc>
    80002c82:	4d18                	lw	a4,24(a0)
    80002c84:	4791                	li	a5,4
    80002c86:	f6f71de3          	bne	a4,a5,80002c00 <kerneltrap+0x38>
    yield();
    80002c8a:	fffff097          	auipc	ra,0xfffff
    80002c8e:	640080e7          	jalr	1600(ra) # 800022ca <yield>
    80002c92:	b7bd                	j	80002c00 <kerneltrap+0x38>

0000000080002c94 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c94:	1101                	addi	sp,sp,-32
    80002c96:	ec06                	sd	ra,24(sp)
    80002c98:	e822                	sd	s0,16(sp)
    80002c9a:	e426                	sd	s1,8(sp)
    80002c9c:	1000                	addi	s0,sp,32
    80002c9e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ca0:	fffff097          	auipc	ra,0xfffff
    80002ca4:	d24080e7          	jalr	-732(ra) # 800019c4 <myproc>
  switch (n) {
    80002ca8:	4795                	li	a5,5
    80002caa:	0497e163          	bltu	a5,s1,80002cec <argraw+0x58>
    80002cae:	048a                	slli	s1,s1,0x2
    80002cb0:	00005717          	auipc	a4,0x5
    80002cb4:	7c070713          	addi	a4,a4,1984 # 80008470 <states.1766+0x170>
    80002cb8:	94ba                	add	s1,s1,a4
    80002cba:	409c                	lw	a5,0(s1)
    80002cbc:	97ba                	add	a5,a5,a4
    80002cbe:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cc0:	713c                	ld	a5,96(a0)
    80002cc2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cc4:	60e2                	ld	ra,24(sp)
    80002cc6:	6442                	ld	s0,16(sp)
    80002cc8:	64a2                	ld	s1,8(sp)
    80002cca:	6105                	addi	sp,sp,32
    80002ccc:	8082                	ret
    return p->trapframe->a1;
    80002cce:	713c                	ld	a5,96(a0)
    80002cd0:	7fa8                	ld	a0,120(a5)
    80002cd2:	bfcd                	j	80002cc4 <argraw+0x30>
    return p->trapframe->a2;
    80002cd4:	713c                	ld	a5,96(a0)
    80002cd6:	63c8                	ld	a0,128(a5)
    80002cd8:	b7f5                	j	80002cc4 <argraw+0x30>
    return p->trapframe->a3;
    80002cda:	713c                	ld	a5,96(a0)
    80002cdc:	67c8                	ld	a0,136(a5)
    80002cde:	b7dd                	j	80002cc4 <argraw+0x30>
    return p->trapframe->a4;
    80002ce0:	713c                	ld	a5,96(a0)
    80002ce2:	6bc8                	ld	a0,144(a5)
    80002ce4:	b7c5                	j	80002cc4 <argraw+0x30>
    return p->trapframe->a5;
    80002ce6:	713c                	ld	a5,96(a0)
    80002ce8:	6fc8                	ld	a0,152(a5)
    80002cea:	bfe9                	j	80002cc4 <argraw+0x30>
  panic("argraw");
    80002cec:	00005517          	auipc	a0,0x5
    80002cf0:	75c50513          	addi	a0,a0,1884 # 80008448 <states.1766+0x148>
    80002cf4:	ffffe097          	auipc	ra,0xffffe
    80002cf8:	84a080e7          	jalr	-1974(ra) # 8000053e <panic>

0000000080002cfc <fetchaddr>:
{
    80002cfc:	1101                	addi	sp,sp,-32
    80002cfe:	ec06                	sd	ra,24(sp)
    80002d00:	e822                	sd	s0,16(sp)
    80002d02:	e426                	sd	s1,8(sp)
    80002d04:	e04a                	sd	s2,0(sp)
    80002d06:	1000                	addi	s0,sp,32
    80002d08:	84aa                	mv	s1,a0
    80002d0a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d0c:	fffff097          	auipc	ra,0xfffff
    80002d10:	cb8080e7          	jalr	-840(ra) # 800019c4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d14:	693c                	ld	a5,80(a0)
    80002d16:	02f4f863          	bgeu	s1,a5,80002d46 <fetchaddr+0x4a>
    80002d1a:	00848713          	addi	a4,s1,8
    80002d1e:	02e7e663          	bltu	a5,a4,80002d4a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d22:	46a1                	li	a3,8
    80002d24:	8626                	mv	a2,s1
    80002d26:	85ca                	mv	a1,s2
    80002d28:	6d28                	ld	a0,88(a0)
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	9dc080e7          	jalr	-1572(ra) # 80001706 <copyin>
    80002d32:	00a03533          	snez	a0,a0
    80002d36:	40a00533          	neg	a0,a0
}
    80002d3a:	60e2                	ld	ra,24(sp)
    80002d3c:	6442                	ld	s0,16(sp)
    80002d3e:	64a2                	ld	s1,8(sp)
    80002d40:	6902                	ld	s2,0(sp)
    80002d42:	6105                	addi	sp,sp,32
    80002d44:	8082                	ret
    return -1;
    80002d46:	557d                	li	a0,-1
    80002d48:	bfcd                	j	80002d3a <fetchaddr+0x3e>
    80002d4a:	557d                	li	a0,-1
    80002d4c:	b7fd                	j	80002d3a <fetchaddr+0x3e>

0000000080002d4e <fetchstr>:
{
    80002d4e:	7179                	addi	sp,sp,-48
    80002d50:	f406                	sd	ra,40(sp)
    80002d52:	f022                	sd	s0,32(sp)
    80002d54:	ec26                	sd	s1,24(sp)
    80002d56:	e84a                	sd	s2,16(sp)
    80002d58:	e44e                	sd	s3,8(sp)
    80002d5a:	1800                	addi	s0,sp,48
    80002d5c:	892a                	mv	s2,a0
    80002d5e:	84ae                	mv	s1,a1
    80002d60:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d62:	fffff097          	auipc	ra,0xfffff
    80002d66:	c62080e7          	jalr	-926(ra) # 800019c4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d6a:	86ce                	mv	a3,s3
    80002d6c:	864a                	mv	a2,s2
    80002d6e:	85a6                	mv	a1,s1
    80002d70:	6d28                	ld	a0,88(a0)
    80002d72:	fffff097          	auipc	ra,0xfffff
    80002d76:	a20080e7          	jalr	-1504(ra) # 80001792 <copyinstr>
  if(err < 0)
    80002d7a:	00054763          	bltz	a0,80002d88 <fetchstr+0x3a>
  return strlen(buf);
    80002d7e:	8526                	mv	a0,s1
    80002d80:	ffffe097          	auipc	ra,0xffffe
    80002d84:	0e4080e7          	jalr	228(ra) # 80000e64 <strlen>
}
    80002d88:	70a2                	ld	ra,40(sp)
    80002d8a:	7402                	ld	s0,32(sp)
    80002d8c:	64e2                	ld	s1,24(sp)
    80002d8e:	6942                	ld	s2,16(sp)
    80002d90:	69a2                	ld	s3,8(sp)
    80002d92:	6145                	addi	sp,sp,48
    80002d94:	8082                	ret

0000000080002d96 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d96:	1101                	addi	sp,sp,-32
    80002d98:	ec06                	sd	ra,24(sp)
    80002d9a:	e822                	sd	s0,16(sp)
    80002d9c:	e426                	sd	s1,8(sp)
    80002d9e:	1000                	addi	s0,sp,32
    80002da0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002da2:	00000097          	auipc	ra,0x0
    80002da6:	ef2080e7          	jalr	-270(ra) # 80002c94 <argraw>
    80002daa:	c088                	sw	a0,0(s1)
  return 0;
}
    80002dac:	4501                	li	a0,0
    80002dae:	60e2                	ld	ra,24(sp)
    80002db0:	6442                	ld	s0,16(sp)
    80002db2:	64a2                	ld	s1,8(sp)
    80002db4:	6105                	addi	sp,sp,32
    80002db6:	8082                	ret

0000000080002db8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002db8:	1101                	addi	sp,sp,-32
    80002dba:	ec06                	sd	ra,24(sp)
    80002dbc:	e822                	sd	s0,16(sp)
    80002dbe:	e426                	sd	s1,8(sp)
    80002dc0:	1000                	addi	s0,sp,32
    80002dc2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dc4:	00000097          	auipc	ra,0x0
    80002dc8:	ed0080e7          	jalr	-304(ra) # 80002c94 <argraw>
    80002dcc:	e088                	sd	a0,0(s1)
  return 0;
}
    80002dce:	4501                	li	a0,0
    80002dd0:	60e2                	ld	ra,24(sp)
    80002dd2:	6442                	ld	s0,16(sp)
    80002dd4:	64a2                	ld	s1,8(sp)
    80002dd6:	6105                	addi	sp,sp,32
    80002dd8:	8082                	ret

0000000080002dda <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002dda:	1101                	addi	sp,sp,-32
    80002ddc:	ec06                	sd	ra,24(sp)
    80002dde:	e822                	sd	s0,16(sp)
    80002de0:	e426                	sd	s1,8(sp)
    80002de2:	e04a                	sd	s2,0(sp)
    80002de4:	1000                	addi	s0,sp,32
    80002de6:	84ae                	mv	s1,a1
    80002de8:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002dea:	00000097          	auipc	ra,0x0
    80002dee:	eaa080e7          	jalr	-342(ra) # 80002c94 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002df2:	864a                	mv	a2,s2
    80002df4:	85a6                	mv	a1,s1
    80002df6:	00000097          	auipc	ra,0x0
    80002dfa:	f58080e7          	jalr	-168(ra) # 80002d4e <fetchstr>
}
    80002dfe:	60e2                	ld	ra,24(sp)
    80002e00:	6442                	ld	s0,16(sp)
    80002e02:	64a2                	ld	s1,8(sp)
    80002e04:	6902                	ld	s2,0(sp)
    80002e06:	6105                	addi	sp,sp,32
    80002e08:	8082                	ret

0000000080002e0a <syscall>:
[SYS_kill_system] sys_kill_system,
};

void
syscall(void)
{
    80002e0a:	1101                	addi	sp,sp,-32
    80002e0c:	ec06                	sd	ra,24(sp)
    80002e0e:	e822                	sd	s0,16(sp)
    80002e10:	e426                	sd	s1,8(sp)
    80002e12:	e04a                	sd	s2,0(sp)
    80002e14:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e16:	fffff097          	auipc	ra,0xfffff
    80002e1a:	bae080e7          	jalr	-1106(ra) # 800019c4 <myproc>
    80002e1e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e20:	06053903          	ld	s2,96(a0)
    80002e24:	0a893783          	ld	a5,168(s2)
    80002e28:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e2c:	37fd                	addiw	a5,a5,-1
    80002e2e:	4759                	li	a4,22
    80002e30:	00f76f63          	bltu	a4,a5,80002e4e <syscall+0x44>
    80002e34:	00369713          	slli	a4,a3,0x3
    80002e38:	00005797          	auipc	a5,0x5
    80002e3c:	65078793          	addi	a5,a5,1616 # 80008488 <syscalls>
    80002e40:	97ba                	add	a5,a5,a4
    80002e42:	639c                	ld	a5,0(a5)
    80002e44:	c789                	beqz	a5,80002e4e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e46:	9782                	jalr	a5
    80002e48:	06a93823          	sd	a0,112(s2)
    80002e4c:	a839                	j	80002e6a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e4e:	16048613          	addi	a2,s1,352
    80002e52:	588c                	lw	a1,48(s1)
    80002e54:	00005517          	auipc	a0,0x5
    80002e58:	5fc50513          	addi	a0,a0,1532 # 80008450 <states.1766+0x150>
    80002e5c:	ffffd097          	auipc	ra,0xffffd
    80002e60:	72c080e7          	jalr	1836(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e64:	70bc                	ld	a5,96(s1)
    80002e66:	577d                	li	a4,-1
    80002e68:	fbb8                	sd	a4,112(a5)
  }
}
    80002e6a:	60e2                	ld	ra,24(sp)
    80002e6c:	6442                	ld	s0,16(sp)
    80002e6e:	64a2                	ld	s1,8(sp)
    80002e70:	6902                	ld	s2,0(sp)
    80002e72:	6105                	addi	sp,sp,32
    80002e74:	8082                	ret

0000000080002e76 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e76:	1101                	addi	sp,sp,-32
    80002e78:	ec06                	sd	ra,24(sp)
    80002e7a:	e822                	sd	s0,16(sp)
    80002e7c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e7e:	fec40593          	addi	a1,s0,-20
    80002e82:	4501                	li	a0,0
    80002e84:	00000097          	auipc	ra,0x0
    80002e88:	f12080e7          	jalr	-238(ra) # 80002d96 <argint>
    return -1;
    80002e8c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e8e:	00054963          	bltz	a0,80002ea0 <sys_exit+0x2a>
  exit(n);
    80002e92:	fec42503          	lw	a0,-20(s0)
    80002e96:	fffff097          	auipc	ra,0xfffff
    80002e9a:	6cc080e7          	jalr	1740(ra) # 80002562 <exit>
  return 0;  // not reached
    80002e9e:	4781                	li	a5,0
}
    80002ea0:	853e                	mv	a0,a5
    80002ea2:	60e2                	ld	ra,24(sp)
    80002ea4:	6442                	ld	s0,16(sp)
    80002ea6:	6105                	addi	sp,sp,32
    80002ea8:	8082                	ret

0000000080002eaa <sys_getpid>:

uint64
sys_getpid(void)
{
    80002eaa:	1141                	addi	sp,sp,-16
    80002eac:	e406                	sd	ra,8(sp)
    80002eae:	e022                	sd	s0,0(sp)
    80002eb0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002eb2:	fffff097          	auipc	ra,0xfffff
    80002eb6:	b12080e7          	jalr	-1262(ra) # 800019c4 <myproc>
}
    80002eba:	5908                	lw	a0,48(a0)
    80002ebc:	60a2                	ld	ra,8(sp)
    80002ebe:	6402                	ld	s0,0(sp)
    80002ec0:	0141                	addi	sp,sp,16
    80002ec2:	8082                	ret

0000000080002ec4 <sys_fork>:

uint64
sys_fork(void)
{
    80002ec4:	1141                	addi	sp,sp,-16
    80002ec6:	e406                	sd	ra,8(sp)
    80002ec8:	e022                	sd	s0,0(sp)
    80002eca:	0800                	addi	s0,sp,16
  return fork();
    80002ecc:	fffff097          	auipc	ra,0xfffff
    80002ed0:	ece080e7          	jalr	-306(ra) # 80001d9a <fork>
}
    80002ed4:	60a2                	ld	ra,8(sp)
    80002ed6:	6402                	ld	s0,0(sp)
    80002ed8:	0141                	addi	sp,sp,16
    80002eda:	8082                	ret

0000000080002edc <sys_wait>:

uint64
sys_wait(void)
{
    80002edc:	1101                	addi	sp,sp,-32
    80002ede:	ec06                	sd	ra,24(sp)
    80002ee0:	e822                	sd	s0,16(sp)
    80002ee2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ee4:	fe840593          	addi	a1,s0,-24
    80002ee8:	4501                	li	a0,0
    80002eea:	00000097          	auipc	ra,0x0
    80002eee:	ece080e7          	jalr	-306(ra) # 80002db8 <argaddr>
    80002ef2:	87aa                	mv	a5,a0
    return -1;
    80002ef4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ef6:	0007c863          	bltz	a5,80002f06 <sys_wait+0x2a>
  return wait(p);
    80002efa:	fe843503          	ld	a0,-24(s0)
    80002efe:	fffff097          	auipc	ra,0xfffff
    80002f02:	46c080e7          	jalr	1132(ra) # 8000236a <wait>
}
    80002f06:	60e2                	ld	ra,24(sp)
    80002f08:	6442                	ld	s0,16(sp)
    80002f0a:	6105                	addi	sp,sp,32
    80002f0c:	8082                	ret

0000000080002f0e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f0e:	7179                	addi	sp,sp,-48
    80002f10:	f406                	sd	ra,40(sp)
    80002f12:	f022                	sd	s0,32(sp)
    80002f14:	ec26                	sd	s1,24(sp)
    80002f16:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f18:	fdc40593          	addi	a1,s0,-36
    80002f1c:	4501                	li	a0,0
    80002f1e:	00000097          	auipc	ra,0x0
    80002f22:	e78080e7          	jalr	-392(ra) # 80002d96 <argint>
    80002f26:	87aa                	mv	a5,a0
    return -1;
    80002f28:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f2a:	0207c063          	bltz	a5,80002f4a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	a96080e7          	jalr	-1386(ra) # 800019c4 <myproc>
    80002f36:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002f38:	fdc42503          	lw	a0,-36(s0)
    80002f3c:	fffff097          	auipc	ra,0xfffff
    80002f40:	dea080e7          	jalr	-534(ra) # 80001d26 <growproc>
    80002f44:	00054863          	bltz	a0,80002f54 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f48:	8526                	mv	a0,s1
}
    80002f4a:	70a2                	ld	ra,40(sp)
    80002f4c:	7402                	ld	s0,32(sp)
    80002f4e:	64e2                	ld	s1,24(sp)
    80002f50:	6145                	addi	sp,sp,48
    80002f52:	8082                	ret
    return -1;
    80002f54:	557d                	li	a0,-1
    80002f56:	bfd5                	j	80002f4a <sys_sbrk+0x3c>

0000000080002f58 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f58:	7139                	addi	sp,sp,-64
    80002f5a:	fc06                	sd	ra,56(sp)
    80002f5c:	f822                	sd	s0,48(sp)
    80002f5e:	f426                	sd	s1,40(sp)
    80002f60:	f04a                	sd	s2,32(sp)
    80002f62:	ec4e                	sd	s3,24(sp)
    80002f64:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f66:	fcc40593          	addi	a1,s0,-52
    80002f6a:	4501                	li	a0,0
    80002f6c:	00000097          	auipc	ra,0x0
    80002f70:	e2a080e7          	jalr	-470(ra) # 80002d96 <argint>
    return -1;
    80002f74:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f76:	06054563          	bltz	a0,80002fe0 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f7a:	00014517          	auipc	a0,0x14
    80002f7e:	35650513          	addi	a0,a0,854 # 800172d0 <tickslock>
    80002f82:	ffffe097          	auipc	ra,0xffffe
    80002f86:	c62080e7          	jalr	-926(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002f8a:	00006917          	auipc	s2,0x6
    80002f8e:	0ae92903          	lw	s2,174(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80002f92:	fcc42783          	lw	a5,-52(s0)
    80002f96:	cf85                	beqz	a5,80002fce <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f98:	00014997          	auipc	s3,0x14
    80002f9c:	33898993          	addi	s3,s3,824 # 800172d0 <tickslock>
    80002fa0:	00006497          	auipc	s1,0x6
    80002fa4:	09848493          	addi	s1,s1,152 # 80009038 <ticks>
    if(myproc()->killed){
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	a1c080e7          	jalr	-1508(ra) # 800019c4 <myproc>
    80002fb0:	551c                	lw	a5,40(a0)
    80002fb2:	ef9d                	bnez	a5,80002ff0 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002fb4:	85ce                	mv	a1,s3
    80002fb6:	8526                	mv	a0,s1
    80002fb8:	fffff097          	auipc	ra,0xfffff
    80002fbc:	34e080e7          	jalr	846(ra) # 80002306 <sleep>
  while(ticks - ticks0 < n){
    80002fc0:	409c                	lw	a5,0(s1)
    80002fc2:	412787bb          	subw	a5,a5,s2
    80002fc6:	fcc42703          	lw	a4,-52(s0)
    80002fca:	fce7efe3          	bltu	a5,a4,80002fa8 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002fce:	00014517          	auipc	a0,0x14
    80002fd2:	30250513          	addi	a0,a0,770 # 800172d0 <tickslock>
    80002fd6:	ffffe097          	auipc	ra,0xffffe
    80002fda:	cc2080e7          	jalr	-830(ra) # 80000c98 <release>
  return 0;
    80002fde:	4781                	li	a5,0
}
    80002fe0:	853e                	mv	a0,a5
    80002fe2:	70e2                	ld	ra,56(sp)
    80002fe4:	7442                	ld	s0,48(sp)
    80002fe6:	74a2                	ld	s1,40(sp)
    80002fe8:	7902                	ld	s2,32(sp)
    80002fea:	69e2                	ld	s3,24(sp)
    80002fec:	6121                	addi	sp,sp,64
    80002fee:	8082                	ret
      release(&tickslock);
    80002ff0:	00014517          	auipc	a0,0x14
    80002ff4:	2e050513          	addi	a0,a0,736 # 800172d0 <tickslock>
    80002ff8:	ffffe097          	auipc	ra,0xffffe
    80002ffc:	ca0080e7          	jalr	-864(ra) # 80000c98 <release>
      return -1;
    80003000:	57fd                	li	a5,-1
    80003002:	bff9                	j	80002fe0 <sys_sleep+0x88>

0000000080003004 <sys_kill>:

uint64
sys_kill(void)
{
    80003004:	1101                	addi	sp,sp,-32
    80003006:	ec06                	sd	ra,24(sp)
    80003008:	e822                	sd	s0,16(sp)
    8000300a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000300c:	fec40593          	addi	a1,s0,-20
    80003010:	4501                	li	a0,0
    80003012:	00000097          	auipc	ra,0x0
    80003016:	d84080e7          	jalr	-636(ra) # 80002d96 <argint>
    8000301a:	87aa                	mv	a5,a0
    return -1;
    8000301c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000301e:	0007c863          	bltz	a5,8000302e <sys_kill+0x2a>
  return kill(pid);
    80003022:	fec42503          	lw	a0,-20(s0)
    80003026:	fffff097          	auipc	ra,0xfffff
    8000302a:	612080e7          	jalr	1554(ra) # 80002638 <kill>
}
    8000302e:	60e2                	ld	ra,24(sp)
    80003030:	6442                	ld	s0,16(sp)
    80003032:	6105                	addi	sp,sp,32
    80003034:	8082                	ret

0000000080003036 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003036:	1101                	addi	sp,sp,-32
    80003038:	ec06                	sd	ra,24(sp)
    8000303a:	e822                	sd	s0,16(sp)
    8000303c:	e426                	sd	s1,8(sp)
    8000303e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003040:	00014517          	auipc	a0,0x14
    80003044:	29050513          	addi	a0,a0,656 # 800172d0 <tickslock>
    80003048:	ffffe097          	auipc	ra,0xffffe
    8000304c:	b9c080e7          	jalr	-1124(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003050:	00006497          	auipc	s1,0x6
    80003054:	fe84a483          	lw	s1,-24(s1) # 80009038 <ticks>
  release(&tickslock);
    80003058:	00014517          	auipc	a0,0x14
    8000305c:	27850513          	addi	a0,a0,632 # 800172d0 <tickslock>
    80003060:	ffffe097          	auipc	ra,0xffffe
    80003064:	c38080e7          	jalr	-968(ra) # 80000c98 <release>
  return xticks;
}
    80003068:	02049513          	slli	a0,s1,0x20
    8000306c:	9101                	srli	a0,a0,0x20
    8000306e:	60e2                	ld	ra,24(sp)
    80003070:	6442                	ld	s0,16(sp)
    80003072:	64a2                	ld	s1,8(sp)
    80003074:	6105                	addi	sp,sp,32
    80003076:	8082                	ret

0000000080003078 <sys_pause_system>:

uint64
sys_pause_system(void)
{
    80003078:	1101                	addi	sp,sp,-32
    8000307a:	ec06                	sd	ra,24(sp)
    8000307c:	e822                	sd	s0,16(sp)
    8000307e:	1000                	addi	s0,sp,32
  int seconds;
  if(argint(0, &seconds) >= 0)
    80003080:	fec40593          	addi	a1,s0,-20
    80003084:	4501                	li	a0,0
    80003086:	00000097          	auipc	ra,0x0
    8000308a:	d10080e7          	jalr	-752(ra) # 80002d96 <argint>
    8000308e:	87aa                	mv	a5,a0
  {
    return pause_system(seconds);
  }
  return -1;
    80003090:	557d                	li	a0,-1
  if(argint(0, &seconds) >= 0)
    80003092:	0007d663          	bgez	a5,8000309e <sys_pause_system+0x26>
}
    80003096:	60e2                	ld	ra,24(sp)
    80003098:	6442                	ld	s0,16(sp)
    8000309a:	6105                	addi	sp,sp,32
    8000309c:	8082                	ret
    return pause_system(seconds);
    8000309e:	fec42503          	lw	a0,-20(s0)
    800030a2:	fffff097          	auipc	ra,0xfffff
    800030a6:	762080e7          	jalr	1890(ra) # 80002804 <pause_system>
    800030aa:	b7f5                	j	80003096 <sys_pause_system+0x1e>

00000000800030ac <sys_kill_system>:

uint64
sys_kill_system(void)
{
    800030ac:	1141                	addi	sp,sp,-16
    800030ae:	e406                	sd	ra,8(sp)
    800030b0:	e022                	sd	s0,0(sp)
    800030b2:	0800                	addi	s0,sp,16
  return kill_system();
    800030b4:	fffff097          	auipc	ra,0xfffff
    800030b8:	786080e7          	jalr	1926(ra) # 8000283a <kill_system>
    800030bc:	60a2                	ld	ra,8(sp)
    800030be:	6402                	ld	s0,0(sp)
    800030c0:	0141                	addi	sp,sp,16
    800030c2:	8082                	ret

00000000800030c4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030c4:	7179                	addi	sp,sp,-48
    800030c6:	f406                	sd	ra,40(sp)
    800030c8:	f022                	sd	s0,32(sp)
    800030ca:	ec26                	sd	s1,24(sp)
    800030cc:	e84a                	sd	s2,16(sp)
    800030ce:	e44e                	sd	s3,8(sp)
    800030d0:	e052                	sd	s4,0(sp)
    800030d2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030d4:	00005597          	auipc	a1,0x5
    800030d8:	47458593          	addi	a1,a1,1140 # 80008548 <syscalls+0xc0>
    800030dc:	00014517          	auipc	a0,0x14
    800030e0:	20c50513          	addi	a0,a0,524 # 800172e8 <bcache>
    800030e4:	ffffe097          	auipc	ra,0xffffe
    800030e8:	a70080e7          	jalr	-1424(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030ec:	0001c797          	auipc	a5,0x1c
    800030f0:	1fc78793          	addi	a5,a5,508 # 8001f2e8 <bcache+0x8000>
    800030f4:	0001c717          	auipc	a4,0x1c
    800030f8:	45c70713          	addi	a4,a4,1116 # 8001f550 <bcache+0x8268>
    800030fc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003100:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003104:	00014497          	auipc	s1,0x14
    80003108:	1fc48493          	addi	s1,s1,508 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    8000310c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000310e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003110:	00005a17          	auipc	s4,0x5
    80003114:	440a0a13          	addi	s4,s4,1088 # 80008550 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003118:	2b893783          	ld	a5,696(s2)
    8000311c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000311e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003122:	85d2                	mv	a1,s4
    80003124:	01048513          	addi	a0,s1,16
    80003128:	00001097          	auipc	ra,0x1
    8000312c:	4bc080e7          	jalr	1212(ra) # 800045e4 <initsleeplock>
    bcache.head.next->prev = b;
    80003130:	2b893783          	ld	a5,696(s2)
    80003134:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003136:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000313a:	45848493          	addi	s1,s1,1112
    8000313e:	fd349de3          	bne	s1,s3,80003118 <binit+0x54>
  }
}
    80003142:	70a2                	ld	ra,40(sp)
    80003144:	7402                	ld	s0,32(sp)
    80003146:	64e2                	ld	s1,24(sp)
    80003148:	6942                	ld	s2,16(sp)
    8000314a:	69a2                	ld	s3,8(sp)
    8000314c:	6a02                	ld	s4,0(sp)
    8000314e:	6145                	addi	sp,sp,48
    80003150:	8082                	ret

0000000080003152 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003152:	7179                	addi	sp,sp,-48
    80003154:	f406                	sd	ra,40(sp)
    80003156:	f022                	sd	s0,32(sp)
    80003158:	ec26                	sd	s1,24(sp)
    8000315a:	e84a                	sd	s2,16(sp)
    8000315c:	e44e                	sd	s3,8(sp)
    8000315e:	1800                	addi	s0,sp,48
    80003160:	89aa                	mv	s3,a0
    80003162:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003164:	00014517          	auipc	a0,0x14
    80003168:	18450513          	addi	a0,a0,388 # 800172e8 <bcache>
    8000316c:	ffffe097          	auipc	ra,0xffffe
    80003170:	a78080e7          	jalr	-1416(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003174:	0001c497          	auipc	s1,0x1c
    80003178:	42c4b483          	ld	s1,1068(s1) # 8001f5a0 <bcache+0x82b8>
    8000317c:	0001c797          	auipc	a5,0x1c
    80003180:	3d478793          	addi	a5,a5,980 # 8001f550 <bcache+0x8268>
    80003184:	02f48f63          	beq	s1,a5,800031c2 <bread+0x70>
    80003188:	873e                	mv	a4,a5
    8000318a:	a021                	j	80003192 <bread+0x40>
    8000318c:	68a4                	ld	s1,80(s1)
    8000318e:	02e48a63          	beq	s1,a4,800031c2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003192:	449c                	lw	a5,8(s1)
    80003194:	ff379ce3          	bne	a5,s3,8000318c <bread+0x3a>
    80003198:	44dc                	lw	a5,12(s1)
    8000319a:	ff2799e3          	bne	a5,s2,8000318c <bread+0x3a>
      b->refcnt++;
    8000319e:	40bc                	lw	a5,64(s1)
    800031a0:	2785                	addiw	a5,a5,1
    800031a2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031a4:	00014517          	auipc	a0,0x14
    800031a8:	14450513          	addi	a0,a0,324 # 800172e8 <bcache>
    800031ac:	ffffe097          	auipc	ra,0xffffe
    800031b0:	aec080e7          	jalr	-1300(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800031b4:	01048513          	addi	a0,s1,16
    800031b8:	00001097          	auipc	ra,0x1
    800031bc:	466080e7          	jalr	1126(ra) # 8000461e <acquiresleep>
      return b;
    800031c0:	a8b9                	j	8000321e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031c2:	0001c497          	auipc	s1,0x1c
    800031c6:	3d64b483          	ld	s1,982(s1) # 8001f598 <bcache+0x82b0>
    800031ca:	0001c797          	auipc	a5,0x1c
    800031ce:	38678793          	addi	a5,a5,902 # 8001f550 <bcache+0x8268>
    800031d2:	00f48863          	beq	s1,a5,800031e2 <bread+0x90>
    800031d6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031d8:	40bc                	lw	a5,64(s1)
    800031da:	cf81                	beqz	a5,800031f2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031dc:	64a4                	ld	s1,72(s1)
    800031de:	fee49de3          	bne	s1,a4,800031d8 <bread+0x86>
  panic("bget: no buffers");
    800031e2:	00005517          	auipc	a0,0x5
    800031e6:	37650513          	addi	a0,a0,886 # 80008558 <syscalls+0xd0>
    800031ea:	ffffd097          	auipc	ra,0xffffd
    800031ee:	354080e7          	jalr	852(ra) # 8000053e <panic>
      b->dev = dev;
    800031f2:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800031f6:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800031fa:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031fe:	4785                	li	a5,1
    80003200:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003202:	00014517          	auipc	a0,0x14
    80003206:	0e650513          	addi	a0,a0,230 # 800172e8 <bcache>
    8000320a:	ffffe097          	auipc	ra,0xffffe
    8000320e:	a8e080e7          	jalr	-1394(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003212:	01048513          	addi	a0,s1,16
    80003216:	00001097          	auipc	ra,0x1
    8000321a:	408080e7          	jalr	1032(ra) # 8000461e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000321e:	409c                	lw	a5,0(s1)
    80003220:	cb89                	beqz	a5,80003232 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003222:	8526                	mv	a0,s1
    80003224:	70a2                	ld	ra,40(sp)
    80003226:	7402                	ld	s0,32(sp)
    80003228:	64e2                	ld	s1,24(sp)
    8000322a:	6942                	ld	s2,16(sp)
    8000322c:	69a2                	ld	s3,8(sp)
    8000322e:	6145                	addi	sp,sp,48
    80003230:	8082                	ret
    virtio_disk_rw(b, 0);
    80003232:	4581                	li	a1,0
    80003234:	8526                	mv	a0,s1
    80003236:	00003097          	auipc	ra,0x3
    8000323a:	f10080e7          	jalr	-240(ra) # 80006146 <virtio_disk_rw>
    b->valid = 1;
    8000323e:	4785                	li	a5,1
    80003240:	c09c                	sw	a5,0(s1)
  return b;
    80003242:	b7c5                	j	80003222 <bread+0xd0>

0000000080003244 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003244:	1101                	addi	sp,sp,-32
    80003246:	ec06                	sd	ra,24(sp)
    80003248:	e822                	sd	s0,16(sp)
    8000324a:	e426                	sd	s1,8(sp)
    8000324c:	1000                	addi	s0,sp,32
    8000324e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003250:	0541                	addi	a0,a0,16
    80003252:	00001097          	auipc	ra,0x1
    80003256:	466080e7          	jalr	1126(ra) # 800046b8 <holdingsleep>
    8000325a:	cd01                	beqz	a0,80003272 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000325c:	4585                	li	a1,1
    8000325e:	8526                	mv	a0,s1
    80003260:	00003097          	auipc	ra,0x3
    80003264:	ee6080e7          	jalr	-282(ra) # 80006146 <virtio_disk_rw>
}
    80003268:	60e2                	ld	ra,24(sp)
    8000326a:	6442                	ld	s0,16(sp)
    8000326c:	64a2                	ld	s1,8(sp)
    8000326e:	6105                	addi	sp,sp,32
    80003270:	8082                	ret
    panic("bwrite");
    80003272:	00005517          	auipc	a0,0x5
    80003276:	2fe50513          	addi	a0,a0,766 # 80008570 <syscalls+0xe8>
    8000327a:	ffffd097          	auipc	ra,0xffffd
    8000327e:	2c4080e7          	jalr	708(ra) # 8000053e <panic>

0000000080003282 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003282:	1101                	addi	sp,sp,-32
    80003284:	ec06                	sd	ra,24(sp)
    80003286:	e822                	sd	s0,16(sp)
    80003288:	e426                	sd	s1,8(sp)
    8000328a:	e04a                	sd	s2,0(sp)
    8000328c:	1000                	addi	s0,sp,32
    8000328e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003290:	01050913          	addi	s2,a0,16
    80003294:	854a                	mv	a0,s2
    80003296:	00001097          	auipc	ra,0x1
    8000329a:	422080e7          	jalr	1058(ra) # 800046b8 <holdingsleep>
    8000329e:	c92d                	beqz	a0,80003310 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032a0:	854a                	mv	a0,s2
    800032a2:	00001097          	auipc	ra,0x1
    800032a6:	3d2080e7          	jalr	978(ra) # 80004674 <releasesleep>

  acquire(&bcache.lock);
    800032aa:	00014517          	auipc	a0,0x14
    800032ae:	03e50513          	addi	a0,a0,62 # 800172e8 <bcache>
    800032b2:	ffffe097          	auipc	ra,0xffffe
    800032b6:	932080e7          	jalr	-1742(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032ba:	40bc                	lw	a5,64(s1)
    800032bc:	37fd                	addiw	a5,a5,-1
    800032be:	0007871b          	sext.w	a4,a5
    800032c2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032c4:	eb05                	bnez	a4,800032f4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032c6:	68bc                	ld	a5,80(s1)
    800032c8:	64b8                	ld	a4,72(s1)
    800032ca:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032cc:	64bc                	ld	a5,72(s1)
    800032ce:	68b8                	ld	a4,80(s1)
    800032d0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032d2:	0001c797          	auipc	a5,0x1c
    800032d6:	01678793          	addi	a5,a5,22 # 8001f2e8 <bcache+0x8000>
    800032da:	2b87b703          	ld	a4,696(a5)
    800032de:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032e0:	0001c717          	auipc	a4,0x1c
    800032e4:	27070713          	addi	a4,a4,624 # 8001f550 <bcache+0x8268>
    800032e8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032ea:	2b87b703          	ld	a4,696(a5)
    800032ee:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032f0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032f4:	00014517          	auipc	a0,0x14
    800032f8:	ff450513          	addi	a0,a0,-12 # 800172e8 <bcache>
    800032fc:	ffffe097          	auipc	ra,0xffffe
    80003300:	99c080e7          	jalr	-1636(ra) # 80000c98 <release>
}
    80003304:	60e2                	ld	ra,24(sp)
    80003306:	6442                	ld	s0,16(sp)
    80003308:	64a2                	ld	s1,8(sp)
    8000330a:	6902                	ld	s2,0(sp)
    8000330c:	6105                	addi	sp,sp,32
    8000330e:	8082                	ret
    panic("brelse");
    80003310:	00005517          	auipc	a0,0x5
    80003314:	26850513          	addi	a0,a0,616 # 80008578 <syscalls+0xf0>
    80003318:	ffffd097          	auipc	ra,0xffffd
    8000331c:	226080e7          	jalr	550(ra) # 8000053e <panic>

0000000080003320 <bpin>:

void
bpin(struct buf *b) {
    80003320:	1101                	addi	sp,sp,-32
    80003322:	ec06                	sd	ra,24(sp)
    80003324:	e822                	sd	s0,16(sp)
    80003326:	e426                	sd	s1,8(sp)
    80003328:	1000                	addi	s0,sp,32
    8000332a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000332c:	00014517          	auipc	a0,0x14
    80003330:	fbc50513          	addi	a0,a0,-68 # 800172e8 <bcache>
    80003334:	ffffe097          	auipc	ra,0xffffe
    80003338:	8b0080e7          	jalr	-1872(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000333c:	40bc                	lw	a5,64(s1)
    8000333e:	2785                	addiw	a5,a5,1
    80003340:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003342:	00014517          	auipc	a0,0x14
    80003346:	fa650513          	addi	a0,a0,-90 # 800172e8 <bcache>
    8000334a:	ffffe097          	auipc	ra,0xffffe
    8000334e:	94e080e7          	jalr	-1714(ra) # 80000c98 <release>
}
    80003352:	60e2                	ld	ra,24(sp)
    80003354:	6442                	ld	s0,16(sp)
    80003356:	64a2                	ld	s1,8(sp)
    80003358:	6105                	addi	sp,sp,32
    8000335a:	8082                	ret

000000008000335c <bunpin>:

void
bunpin(struct buf *b) {
    8000335c:	1101                	addi	sp,sp,-32
    8000335e:	ec06                	sd	ra,24(sp)
    80003360:	e822                	sd	s0,16(sp)
    80003362:	e426                	sd	s1,8(sp)
    80003364:	1000                	addi	s0,sp,32
    80003366:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003368:	00014517          	auipc	a0,0x14
    8000336c:	f8050513          	addi	a0,a0,-128 # 800172e8 <bcache>
    80003370:	ffffe097          	auipc	ra,0xffffe
    80003374:	874080e7          	jalr	-1932(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003378:	40bc                	lw	a5,64(s1)
    8000337a:	37fd                	addiw	a5,a5,-1
    8000337c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000337e:	00014517          	auipc	a0,0x14
    80003382:	f6a50513          	addi	a0,a0,-150 # 800172e8 <bcache>
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	912080e7          	jalr	-1774(ra) # 80000c98 <release>
}
    8000338e:	60e2                	ld	ra,24(sp)
    80003390:	6442                	ld	s0,16(sp)
    80003392:	64a2                	ld	s1,8(sp)
    80003394:	6105                	addi	sp,sp,32
    80003396:	8082                	ret

0000000080003398 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003398:	1101                	addi	sp,sp,-32
    8000339a:	ec06                	sd	ra,24(sp)
    8000339c:	e822                	sd	s0,16(sp)
    8000339e:	e426                	sd	s1,8(sp)
    800033a0:	e04a                	sd	s2,0(sp)
    800033a2:	1000                	addi	s0,sp,32
    800033a4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033a6:	00d5d59b          	srliw	a1,a1,0xd
    800033aa:	0001c797          	auipc	a5,0x1c
    800033ae:	61a7a783          	lw	a5,1562(a5) # 8001f9c4 <sb+0x1c>
    800033b2:	9dbd                	addw	a1,a1,a5
    800033b4:	00000097          	auipc	ra,0x0
    800033b8:	d9e080e7          	jalr	-610(ra) # 80003152 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033bc:	0074f713          	andi	a4,s1,7
    800033c0:	4785                	li	a5,1
    800033c2:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033c6:	14ce                	slli	s1,s1,0x33
    800033c8:	90d9                	srli	s1,s1,0x36
    800033ca:	00950733          	add	a4,a0,s1
    800033ce:	05874703          	lbu	a4,88(a4)
    800033d2:	00e7f6b3          	and	a3,a5,a4
    800033d6:	c69d                	beqz	a3,80003404 <bfree+0x6c>
    800033d8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033da:	94aa                	add	s1,s1,a0
    800033dc:	fff7c793          	not	a5,a5
    800033e0:	8ff9                	and	a5,a5,a4
    800033e2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033e6:	00001097          	auipc	ra,0x1
    800033ea:	118080e7          	jalr	280(ra) # 800044fe <log_write>
  brelse(bp);
    800033ee:	854a                	mv	a0,s2
    800033f0:	00000097          	auipc	ra,0x0
    800033f4:	e92080e7          	jalr	-366(ra) # 80003282 <brelse>
}
    800033f8:	60e2                	ld	ra,24(sp)
    800033fa:	6442                	ld	s0,16(sp)
    800033fc:	64a2                	ld	s1,8(sp)
    800033fe:	6902                	ld	s2,0(sp)
    80003400:	6105                	addi	sp,sp,32
    80003402:	8082                	ret
    panic("freeing free block");
    80003404:	00005517          	auipc	a0,0x5
    80003408:	17c50513          	addi	a0,a0,380 # 80008580 <syscalls+0xf8>
    8000340c:	ffffd097          	auipc	ra,0xffffd
    80003410:	132080e7          	jalr	306(ra) # 8000053e <panic>

0000000080003414 <balloc>:
{
    80003414:	711d                	addi	sp,sp,-96
    80003416:	ec86                	sd	ra,88(sp)
    80003418:	e8a2                	sd	s0,80(sp)
    8000341a:	e4a6                	sd	s1,72(sp)
    8000341c:	e0ca                	sd	s2,64(sp)
    8000341e:	fc4e                	sd	s3,56(sp)
    80003420:	f852                	sd	s4,48(sp)
    80003422:	f456                	sd	s5,40(sp)
    80003424:	f05a                	sd	s6,32(sp)
    80003426:	ec5e                	sd	s7,24(sp)
    80003428:	e862                	sd	s8,16(sp)
    8000342a:	e466                	sd	s9,8(sp)
    8000342c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000342e:	0001c797          	auipc	a5,0x1c
    80003432:	57e7a783          	lw	a5,1406(a5) # 8001f9ac <sb+0x4>
    80003436:	cbd1                	beqz	a5,800034ca <balloc+0xb6>
    80003438:	8baa                	mv	s7,a0
    8000343a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000343c:	0001cb17          	auipc	s6,0x1c
    80003440:	56cb0b13          	addi	s6,s6,1388 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003444:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003446:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003448:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000344a:	6c89                	lui	s9,0x2
    8000344c:	a831                	j	80003468 <balloc+0x54>
    brelse(bp);
    8000344e:	854a                	mv	a0,s2
    80003450:	00000097          	auipc	ra,0x0
    80003454:	e32080e7          	jalr	-462(ra) # 80003282 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003458:	015c87bb          	addw	a5,s9,s5
    8000345c:	00078a9b          	sext.w	s5,a5
    80003460:	004b2703          	lw	a4,4(s6)
    80003464:	06eaf363          	bgeu	s5,a4,800034ca <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003468:	41fad79b          	sraiw	a5,s5,0x1f
    8000346c:	0137d79b          	srliw	a5,a5,0x13
    80003470:	015787bb          	addw	a5,a5,s5
    80003474:	40d7d79b          	sraiw	a5,a5,0xd
    80003478:	01cb2583          	lw	a1,28(s6)
    8000347c:	9dbd                	addw	a1,a1,a5
    8000347e:	855e                	mv	a0,s7
    80003480:	00000097          	auipc	ra,0x0
    80003484:	cd2080e7          	jalr	-814(ra) # 80003152 <bread>
    80003488:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000348a:	004b2503          	lw	a0,4(s6)
    8000348e:	000a849b          	sext.w	s1,s5
    80003492:	8662                	mv	a2,s8
    80003494:	faa4fde3          	bgeu	s1,a0,8000344e <balloc+0x3a>
      m = 1 << (bi % 8);
    80003498:	41f6579b          	sraiw	a5,a2,0x1f
    8000349c:	01d7d69b          	srliw	a3,a5,0x1d
    800034a0:	00c6873b          	addw	a4,a3,a2
    800034a4:	00777793          	andi	a5,a4,7
    800034a8:	9f95                	subw	a5,a5,a3
    800034aa:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034ae:	4037571b          	sraiw	a4,a4,0x3
    800034b2:	00e906b3          	add	a3,s2,a4
    800034b6:	0586c683          	lbu	a3,88(a3)
    800034ba:	00d7f5b3          	and	a1,a5,a3
    800034be:	cd91                	beqz	a1,800034da <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034c0:	2605                	addiw	a2,a2,1
    800034c2:	2485                	addiw	s1,s1,1
    800034c4:	fd4618e3          	bne	a2,s4,80003494 <balloc+0x80>
    800034c8:	b759                	j	8000344e <balloc+0x3a>
  panic("balloc: out of blocks");
    800034ca:	00005517          	auipc	a0,0x5
    800034ce:	0ce50513          	addi	a0,a0,206 # 80008598 <syscalls+0x110>
    800034d2:	ffffd097          	auipc	ra,0xffffd
    800034d6:	06c080e7          	jalr	108(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034da:	974a                	add	a4,a4,s2
    800034dc:	8fd5                	or	a5,a5,a3
    800034de:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034e2:	854a                	mv	a0,s2
    800034e4:	00001097          	auipc	ra,0x1
    800034e8:	01a080e7          	jalr	26(ra) # 800044fe <log_write>
        brelse(bp);
    800034ec:	854a                	mv	a0,s2
    800034ee:	00000097          	auipc	ra,0x0
    800034f2:	d94080e7          	jalr	-620(ra) # 80003282 <brelse>
  bp = bread(dev, bno);
    800034f6:	85a6                	mv	a1,s1
    800034f8:	855e                	mv	a0,s7
    800034fa:	00000097          	auipc	ra,0x0
    800034fe:	c58080e7          	jalr	-936(ra) # 80003152 <bread>
    80003502:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003504:	40000613          	li	a2,1024
    80003508:	4581                	li	a1,0
    8000350a:	05850513          	addi	a0,a0,88
    8000350e:	ffffd097          	auipc	ra,0xffffd
    80003512:	7d2080e7          	jalr	2002(ra) # 80000ce0 <memset>
  log_write(bp);
    80003516:	854a                	mv	a0,s2
    80003518:	00001097          	auipc	ra,0x1
    8000351c:	fe6080e7          	jalr	-26(ra) # 800044fe <log_write>
  brelse(bp);
    80003520:	854a                	mv	a0,s2
    80003522:	00000097          	auipc	ra,0x0
    80003526:	d60080e7          	jalr	-672(ra) # 80003282 <brelse>
}
    8000352a:	8526                	mv	a0,s1
    8000352c:	60e6                	ld	ra,88(sp)
    8000352e:	6446                	ld	s0,80(sp)
    80003530:	64a6                	ld	s1,72(sp)
    80003532:	6906                	ld	s2,64(sp)
    80003534:	79e2                	ld	s3,56(sp)
    80003536:	7a42                	ld	s4,48(sp)
    80003538:	7aa2                	ld	s5,40(sp)
    8000353a:	7b02                	ld	s6,32(sp)
    8000353c:	6be2                	ld	s7,24(sp)
    8000353e:	6c42                	ld	s8,16(sp)
    80003540:	6ca2                	ld	s9,8(sp)
    80003542:	6125                	addi	sp,sp,96
    80003544:	8082                	ret

0000000080003546 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003546:	7179                	addi	sp,sp,-48
    80003548:	f406                	sd	ra,40(sp)
    8000354a:	f022                	sd	s0,32(sp)
    8000354c:	ec26                	sd	s1,24(sp)
    8000354e:	e84a                	sd	s2,16(sp)
    80003550:	e44e                	sd	s3,8(sp)
    80003552:	e052                	sd	s4,0(sp)
    80003554:	1800                	addi	s0,sp,48
    80003556:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003558:	47ad                	li	a5,11
    8000355a:	04b7fe63          	bgeu	a5,a1,800035b6 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000355e:	ff45849b          	addiw	s1,a1,-12
    80003562:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003566:	0ff00793          	li	a5,255
    8000356a:	0ae7e363          	bltu	a5,a4,80003610 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000356e:	08052583          	lw	a1,128(a0)
    80003572:	c5ad                	beqz	a1,800035dc <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003574:	00092503          	lw	a0,0(s2)
    80003578:	00000097          	auipc	ra,0x0
    8000357c:	bda080e7          	jalr	-1062(ra) # 80003152 <bread>
    80003580:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003582:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003586:	02049593          	slli	a1,s1,0x20
    8000358a:	9181                	srli	a1,a1,0x20
    8000358c:	058a                	slli	a1,a1,0x2
    8000358e:	00b784b3          	add	s1,a5,a1
    80003592:	0004a983          	lw	s3,0(s1)
    80003596:	04098d63          	beqz	s3,800035f0 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000359a:	8552                	mv	a0,s4
    8000359c:	00000097          	auipc	ra,0x0
    800035a0:	ce6080e7          	jalr	-794(ra) # 80003282 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035a4:	854e                	mv	a0,s3
    800035a6:	70a2                	ld	ra,40(sp)
    800035a8:	7402                	ld	s0,32(sp)
    800035aa:	64e2                	ld	s1,24(sp)
    800035ac:	6942                	ld	s2,16(sp)
    800035ae:	69a2                	ld	s3,8(sp)
    800035b0:	6a02                	ld	s4,0(sp)
    800035b2:	6145                	addi	sp,sp,48
    800035b4:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035b6:	02059493          	slli	s1,a1,0x20
    800035ba:	9081                	srli	s1,s1,0x20
    800035bc:	048a                	slli	s1,s1,0x2
    800035be:	94aa                	add	s1,s1,a0
    800035c0:	0504a983          	lw	s3,80(s1)
    800035c4:	fe0990e3          	bnez	s3,800035a4 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035c8:	4108                	lw	a0,0(a0)
    800035ca:	00000097          	auipc	ra,0x0
    800035ce:	e4a080e7          	jalr	-438(ra) # 80003414 <balloc>
    800035d2:	0005099b          	sext.w	s3,a0
    800035d6:	0534a823          	sw	s3,80(s1)
    800035da:	b7e9                	j	800035a4 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035dc:	4108                	lw	a0,0(a0)
    800035de:	00000097          	auipc	ra,0x0
    800035e2:	e36080e7          	jalr	-458(ra) # 80003414 <balloc>
    800035e6:	0005059b          	sext.w	a1,a0
    800035ea:	08b92023          	sw	a1,128(s2)
    800035ee:	b759                	j	80003574 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800035f0:	00092503          	lw	a0,0(s2)
    800035f4:	00000097          	auipc	ra,0x0
    800035f8:	e20080e7          	jalr	-480(ra) # 80003414 <balloc>
    800035fc:	0005099b          	sext.w	s3,a0
    80003600:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003604:	8552                	mv	a0,s4
    80003606:	00001097          	auipc	ra,0x1
    8000360a:	ef8080e7          	jalr	-264(ra) # 800044fe <log_write>
    8000360e:	b771                	j	8000359a <bmap+0x54>
  panic("bmap: out of range");
    80003610:	00005517          	auipc	a0,0x5
    80003614:	fa050513          	addi	a0,a0,-96 # 800085b0 <syscalls+0x128>
    80003618:	ffffd097          	auipc	ra,0xffffd
    8000361c:	f26080e7          	jalr	-218(ra) # 8000053e <panic>

0000000080003620 <iget>:
{
    80003620:	7179                	addi	sp,sp,-48
    80003622:	f406                	sd	ra,40(sp)
    80003624:	f022                	sd	s0,32(sp)
    80003626:	ec26                	sd	s1,24(sp)
    80003628:	e84a                	sd	s2,16(sp)
    8000362a:	e44e                	sd	s3,8(sp)
    8000362c:	e052                	sd	s4,0(sp)
    8000362e:	1800                	addi	s0,sp,48
    80003630:	89aa                	mv	s3,a0
    80003632:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003634:	0001c517          	auipc	a0,0x1c
    80003638:	39450513          	addi	a0,a0,916 # 8001f9c8 <itable>
    8000363c:	ffffd097          	auipc	ra,0xffffd
    80003640:	5a8080e7          	jalr	1448(ra) # 80000be4 <acquire>
  empty = 0;
    80003644:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003646:	0001c497          	auipc	s1,0x1c
    8000364a:	39a48493          	addi	s1,s1,922 # 8001f9e0 <itable+0x18>
    8000364e:	0001e697          	auipc	a3,0x1e
    80003652:	e2268693          	addi	a3,a3,-478 # 80021470 <log>
    80003656:	a039                	j	80003664 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003658:	02090b63          	beqz	s2,8000368e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000365c:	08848493          	addi	s1,s1,136
    80003660:	02d48a63          	beq	s1,a3,80003694 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003664:	449c                	lw	a5,8(s1)
    80003666:	fef059e3          	blez	a5,80003658 <iget+0x38>
    8000366a:	4098                	lw	a4,0(s1)
    8000366c:	ff3716e3          	bne	a4,s3,80003658 <iget+0x38>
    80003670:	40d8                	lw	a4,4(s1)
    80003672:	ff4713e3          	bne	a4,s4,80003658 <iget+0x38>
      ip->ref++;
    80003676:	2785                	addiw	a5,a5,1
    80003678:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000367a:	0001c517          	auipc	a0,0x1c
    8000367e:	34e50513          	addi	a0,a0,846 # 8001f9c8 <itable>
    80003682:	ffffd097          	auipc	ra,0xffffd
    80003686:	616080e7          	jalr	1558(ra) # 80000c98 <release>
      return ip;
    8000368a:	8926                	mv	s2,s1
    8000368c:	a03d                	j	800036ba <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000368e:	f7f9                	bnez	a5,8000365c <iget+0x3c>
    80003690:	8926                	mv	s2,s1
    80003692:	b7e9                	j	8000365c <iget+0x3c>
  if(empty == 0)
    80003694:	02090c63          	beqz	s2,800036cc <iget+0xac>
  ip->dev = dev;
    80003698:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000369c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036a0:	4785                	li	a5,1
    800036a2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036a6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800036aa:	0001c517          	auipc	a0,0x1c
    800036ae:	31e50513          	addi	a0,a0,798 # 8001f9c8 <itable>
    800036b2:	ffffd097          	auipc	ra,0xffffd
    800036b6:	5e6080e7          	jalr	1510(ra) # 80000c98 <release>
}
    800036ba:	854a                	mv	a0,s2
    800036bc:	70a2                	ld	ra,40(sp)
    800036be:	7402                	ld	s0,32(sp)
    800036c0:	64e2                	ld	s1,24(sp)
    800036c2:	6942                	ld	s2,16(sp)
    800036c4:	69a2                	ld	s3,8(sp)
    800036c6:	6a02                	ld	s4,0(sp)
    800036c8:	6145                	addi	sp,sp,48
    800036ca:	8082                	ret
    panic("iget: no inodes");
    800036cc:	00005517          	auipc	a0,0x5
    800036d0:	efc50513          	addi	a0,a0,-260 # 800085c8 <syscalls+0x140>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	e6a080e7          	jalr	-406(ra) # 8000053e <panic>

00000000800036dc <fsinit>:
fsinit(int dev) {
    800036dc:	7179                	addi	sp,sp,-48
    800036de:	f406                	sd	ra,40(sp)
    800036e0:	f022                	sd	s0,32(sp)
    800036e2:	ec26                	sd	s1,24(sp)
    800036e4:	e84a                	sd	s2,16(sp)
    800036e6:	e44e                	sd	s3,8(sp)
    800036e8:	1800                	addi	s0,sp,48
    800036ea:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036ec:	4585                	li	a1,1
    800036ee:	00000097          	auipc	ra,0x0
    800036f2:	a64080e7          	jalr	-1436(ra) # 80003152 <bread>
    800036f6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036f8:	0001c997          	auipc	s3,0x1c
    800036fc:	2b098993          	addi	s3,s3,688 # 8001f9a8 <sb>
    80003700:	02000613          	li	a2,32
    80003704:	05850593          	addi	a1,a0,88
    80003708:	854e                	mv	a0,s3
    8000370a:	ffffd097          	auipc	ra,0xffffd
    8000370e:	636080e7          	jalr	1590(ra) # 80000d40 <memmove>
  brelse(bp);
    80003712:	8526                	mv	a0,s1
    80003714:	00000097          	auipc	ra,0x0
    80003718:	b6e080e7          	jalr	-1170(ra) # 80003282 <brelse>
  if(sb.magic != FSMAGIC)
    8000371c:	0009a703          	lw	a4,0(s3)
    80003720:	102037b7          	lui	a5,0x10203
    80003724:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003728:	02f71263          	bne	a4,a5,8000374c <fsinit+0x70>
  initlog(dev, &sb);
    8000372c:	0001c597          	auipc	a1,0x1c
    80003730:	27c58593          	addi	a1,a1,636 # 8001f9a8 <sb>
    80003734:	854a                	mv	a0,s2
    80003736:	00001097          	auipc	ra,0x1
    8000373a:	b4c080e7          	jalr	-1204(ra) # 80004282 <initlog>
}
    8000373e:	70a2                	ld	ra,40(sp)
    80003740:	7402                	ld	s0,32(sp)
    80003742:	64e2                	ld	s1,24(sp)
    80003744:	6942                	ld	s2,16(sp)
    80003746:	69a2                	ld	s3,8(sp)
    80003748:	6145                	addi	sp,sp,48
    8000374a:	8082                	ret
    panic("invalid file system");
    8000374c:	00005517          	auipc	a0,0x5
    80003750:	e8c50513          	addi	a0,a0,-372 # 800085d8 <syscalls+0x150>
    80003754:	ffffd097          	auipc	ra,0xffffd
    80003758:	dea080e7          	jalr	-534(ra) # 8000053e <panic>

000000008000375c <iinit>:
{
    8000375c:	7179                	addi	sp,sp,-48
    8000375e:	f406                	sd	ra,40(sp)
    80003760:	f022                	sd	s0,32(sp)
    80003762:	ec26                	sd	s1,24(sp)
    80003764:	e84a                	sd	s2,16(sp)
    80003766:	e44e                	sd	s3,8(sp)
    80003768:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000376a:	00005597          	auipc	a1,0x5
    8000376e:	e8658593          	addi	a1,a1,-378 # 800085f0 <syscalls+0x168>
    80003772:	0001c517          	auipc	a0,0x1c
    80003776:	25650513          	addi	a0,a0,598 # 8001f9c8 <itable>
    8000377a:	ffffd097          	auipc	ra,0xffffd
    8000377e:	3da080e7          	jalr	986(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003782:	0001c497          	auipc	s1,0x1c
    80003786:	26e48493          	addi	s1,s1,622 # 8001f9f0 <itable+0x28>
    8000378a:	0001e997          	auipc	s3,0x1e
    8000378e:	cf698993          	addi	s3,s3,-778 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003792:	00005917          	auipc	s2,0x5
    80003796:	e6690913          	addi	s2,s2,-410 # 800085f8 <syscalls+0x170>
    8000379a:	85ca                	mv	a1,s2
    8000379c:	8526                	mv	a0,s1
    8000379e:	00001097          	auipc	ra,0x1
    800037a2:	e46080e7          	jalr	-442(ra) # 800045e4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037a6:	08848493          	addi	s1,s1,136
    800037aa:	ff3498e3          	bne	s1,s3,8000379a <iinit+0x3e>
}
    800037ae:	70a2                	ld	ra,40(sp)
    800037b0:	7402                	ld	s0,32(sp)
    800037b2:	64e2                	ld	s1,24(sp)
    800037b4:	6942                	ld	s2,16(sp)
    800037b6:	69a2                	ld	s3,8(sp)
    800037b8:	6145                	addi	sp,sp,48
    800037ba:	8082                	ret

00000000800037bc <ialloc>:
{
    800037bc:	715d                	addi	sp,sp,-80
    800037be:	e486                	sd	ra,72(sp)
    800037c0:	e0a2                	sd	s0,64(sp)
    800037c2:	fc26                	sd	s1,56(sp)
    800037c4:	f84a                	sd	s2,48(sp)
    800037c6:	f44e                	sd	s3,40(sp)
    800037c8:	f052                	sd	s4,32(sp)
    800037ca:	ec56                	sd	s5,24(sp)
    800037cc:	e85a                	sd	s6,16(sp)
    800037ce:	e45e                	sd	s7,8(sp)
    800037d0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037d2:	0001c717          	auipc	a4,0x1c
    800037d6:	1e272703          	lw	a4,482(a4) # 8001f9b4 <sb+0xc>
    800037da:	4785                	li	a5,1
    800037dc:	04e7fa63          	bgeu	a5,a4,80003830 <ialloc+0x74>
    800037e0:	8aaa                	mv	s5,a0
    800037e2:	8bae                	mv	s7,a1
    800037e4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037e6:	0001ca17          	auipc	s4,0x1c
    800037ea:	1c2a0a13          	addi	s4,s4,450 # 8001f9a8 <sb>
    800037ee:	00048b1b          	sext.w	s6,s1
    800037f2:	0044d593          	srli	a1,s1,0x4
    800037f6:	018a2783          	lw	a5,24(s4)
    800037fa:	9dbd                	addw	a1,a1,a5
    800037fc:	8556                	mv	a0,s5
    800037fe:	00000097          	auipc	ra,0x0
    80003802:	954080e7          	jalr	-1708(ra) # 80003152 <bread>
    80003806:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003808:	05850993          	addi	s3,a0,88
    8000380c:	00f4f793          	andi	a5,s1,15
    80003810:	079a                	slli	a5,a5,0x6
    80003812:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003814:	00099783          	lh	a5,0(s3)
    80003818:	c785                	beqz	a5,80003840 <ialloc+0x84>
    brelse(bp);
    8000381a:	00000097          	auipc	ra,0x0
    8000381e:	a68080e7          	jalr	-1432(ra) # 80003282 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003822:	0485                	addi	s1,s1,1
    80003824:	00ca2703          	lw	a4,12(s4)
    80003828:	0004879b          	sext.w	a5,s1
    8000382c:	fce7e1e3          	bltu	a5,a4,800037ee <ialloc+0x32>
  panic("ialloc: no inodes");
    80003830:	00005517          	auipc	a0,0x5
    80003834:	dd050513          	addi	a0,a0,-560 # 80008600 <syscalls+0x178>
    80003838:	ffffd097          	auipc	ra,0xffffd
    8000383c:	d06080e7          	jalr	-762(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003840:	04000613          	li	a2,64
    80003844:	4581                	li	a1,0
    80003846:	854e                	mv	a0,s3
    80003848:	ffffd097          	auipc	ra,0xffffd
    8000384c:	498080e7          	jalr	1176(ra) # 80000ce0 <memset>
      dip->type = type;
    80003850:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003854:	854a                	mv	a0,s2
    80003856:	00001097          	auipc	ra,0x1
    8000385a:	ca8080e7          	jalr	-856(ra) # 800044fe <log_write>
      brelse(bp);
    8000385e:	854a                	mv	a0,s2
    80003860:	00000097          	auipc	ra,0x0
    80003864:	a22080e7          	jalr	-1502(ra) # 80003282 <brelse>
      return iget(dev, inum);
    80003868:	85da                	mv	a1,s6
    8000386a:	8556                	mv	a0,s5
    8000386c:	00000097          	auipc	ra,0x0
    80003870:	db4080e7          	jalr	-588(ra) # 80003620 <iget>
}
    80003874:	60a6                	ld	ra,72(sp)
    80003876:	6406                	ld	s0,64(sp)
    80003878:	74e2                	ld	s1,56(sp)
    8000387a:	7942                	ld	s2,48(sp)
    8000387c:	79a2                	ld	s3,40(sp)
    8000387e:	7a02                	ld	s4,32(sp)
    80003880:	6ae2                	ld	s5,24(sp)
    80003882:	6b42                	ld	s6,16(sp)
    80003884:	6ba2                	ld	s7,8(sp)
    80003886:	6161                	addi	sp,sp,80
    80003888:	8082                	ret

000000008000388a <iupdate>:
{
    8000388a:	1101                	addi	sp,sp,-32
    8000388c:	ec06                	sd	ra,24(sp)
    8000388e:	e822                	sd	s0,16(sp)
    80003890:	e426                	sd	s1,8(sp)
    80003892:	e04a                	sd	s2,0(sp)
    80003894:	1000                	addi	s0,sp,32
    80003896:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003898:	415c                	lw	a5,4(a0)
    8000389a:	0047d79b          	srliw	a5,a5,0x4
    8000389e:	0001c597          	auipc	a1,0x1c
    800038a2:	1225a583          	lw	a1,290(a1) # 8001f9c0 <sb+0x18>
    800038a6:	9dbd                	addw	a1,a1,a5
    800038a8:	4108                	lw	a0,0(a0)
    800038aa:	00000097          	auipc	ra,0x0
    800038ae:	8a8080e7          	jalr	-1880(ra) # 80003152 <bread>
    800038b2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038b4:	05850793          	addi	a5,a0,88
    800038b8:	40c8                	lw	a0,4(s1)
    800038ba:	893d                	andi	a0,a0,15
    800038bc:	051a                	slli	a0,a0,0x6
    800038be:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038c0:	04449703          	lh	a4,68(s1)
    800038c4:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038c8:	04649703          	lh	a4,70(s1)
    800038cc:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038d0:	04849703          	lh	a4,72(s1)
    800038d4:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038d8:	04a49703          	lh	a4,74(s1)
    800038dc:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038e0:	44f8                	lw	a4,76(s1)
    800038e2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038e4:	03400613          	li	a2,52
    800038e8:	05048593          	addi	a1,s1,80
    800038ec:	0531                	addi	a0,a0,12
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	452080e7          	jalr	1106(ra) # 80000d40 <memmove>
  log_write(bp);
    800038f6:	854a                	mv	a0,s2
    800038f8:	00001097          	auipc	ra,0x1
    800038fc:	c06080e7          	jalr	-1018(ra) # 800044fe <log_write>
  brelse(bp);
    80003900:	854a                	mv	a0,s2
    80003902:	00000097          	auipc	ra,0x0
    80003906:	980080e7          	jalr	-1664(ra) # 80003282 <brelse>
}
    8000390a:	60e2                	ld	ra,24(sp)
    8000390c:	6442                	ld	s0,16(sp)
    8000390e:	64a2                	ld	s1,8(sp)
    80003910:	6902                	ld	s2,0(sp)
    80003912:	6105                	addi	sp,sp,32
    80003914:	8082                	ret

0000000080003916 <idup>:
{
    80003916:	1101                	addi	sp,sp,-32
    80003918:	ec06                	sd	ra,24(sp)
    8000391a:	e822                	sd	s0,16(sp)
    8000391c:	e426                	sd	s1,8(sp)
    8000391e:	1000                	addi	s0,sp,32
    80003920:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003922:	0001c517          	auipc	a0,0x1c
    80003926:	0a650513          	addi	a0,a0,166 # 8001f9c8 <itable>
    8000392a:	ffffd097          	auipc	ra,0xffffd
    8000392e:	2ba080e7          	jalr	698(ra) # 80000be4 <acquire>
  ip->ref++;
    80003932:	449c                	lw	a5,8(s1)
    80003934:	2785                	addiw	a5,a5,1
    80003936:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003938:	0001c517          	auipc	a0,0x1c
    8000393c:	09050513          	addi	a0,a0,144 # 8001f9c8 <itable>
    80003940:	ffffd097          	auipc	ra,0xffffd
    80003944:	358080e7          	jalr	856(ra) # 80000c98 <release>
}
    80003948:	8526                	mv	a0,s1
    8000394a:	60e2                	ld	ra,24(sp)
    8000394c:	6442                	ld	s0,16(sp)
    8000394e:	64a2                	ld	s1,8(sp)
    80003950:	6105                	addi	sp,sp,32
    80003952:	8082                	ret

0000000080003954 <ilock>:
{
    80003954:	1101                	addi	sp,sp,-32
    80003956:	ec06                	sd	ra,24(sp)
    80003958:	e822                	sd	s0,16(sp)
    8000395a:	e426                	sd	s1,8(sp)
    8000395c:	e04a                	sd	s2,0(sp)
    8000395e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003960:	c115                	beqz	a0,80003984 <ilock+0x30>
    80003962:	84aa                	mv	s1,a0
    80003964:	451c                	lw	a5,8(a0)
    80003966:	00f05f63          	blez	a5,80003984 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000396a:	0541                	addi	a0,a0,16
    8000396c:	00001097          	auipc	ra,0x1
    80003970:	cb2080e7          	jalr	-846(ra) # 8000461e <acquiresleep>
  if(ip->valid == 0){
    80003974:	40bc                	lw	a5,64(s1)
    80003976:	cf99                	beqz	a5,80003994 <ilock+0x40>
}
    80003978:	60e2                	ld	ra,24(sp)
    8000397a:	6442                	ld	s0,16(sp)
    8000397c:	64a2                	ld	s1,8(sp)
    8000397e:	6902                	ld	s2,0(sp)
    80003980:	6105                	addi	sp,sp,32
    80003982:	8082                	ret
    panic("ilock");
    80003984:	00005517          	auipc	a0,0x5
    80003988:	c9450513          	addi	a0,a0,-876 # 80008618 <syscalls+0x190>
    8000398c:	ffffd097          	auipc	ra,0xffffd
    80003990:	bb2080e7          	jalr	-1102(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003994:	40dc                	lw	a5,4(s1)
    80003996:	0047d79b          	srliw	a5,a5,0x4
    8000399a:	0001c597          	auipc	a1,0x1c
    8000399e:	0265a583          	lw	a1,38(a1) # 8001f9c0 <sb+0x18>
    800039a2:	9dbd                	addw	a1,a1,a5
    800039a4:	4088                	lw	a0,0(s1)
    800039a6:	fffff097          	auipc	ra,0xfffff
    800039aa:	7ac080e7          	jalr	1964(ra) # 80003152 <bread>
    800039ae:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039b0:	05850593          	addi	a1,a0,88
    800039b4:	40dc                	lw	a5,4(s1)
    800039b6:	8bbd                	andi	a5,a5,15
    800039b8:	079a                	slli	a5,a5,0x6
    800039ba:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039bc:	00059783          	lh	a5,0(a1)
    800039c0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039c4:	00259783          	lh	a5,2(a1)
    800039c8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039cc:	00459783          	lh	a5,4(a1)
    800039d0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039d4:	00659783          	lh	a5,6(a1)
    800039d8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039dc:	459c                	lw	a5,8(a1)
    800039de:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039e0:	03400613          	li	a2,52
    800039e4:	05b1                	addi	a1,a1,12
    800039e6:	05048513          	addi	a0,s1,80
    800039ea:	ffffd097          	auipc	ra,0xffffd
    800039ee:	356080e7          	jalr	854(ra) # 80000d40 <memmove>
    brelse(bp);
    800039f2:	854a                	mv	a0,s2
    800039f4:	00000097          	auipc	ra,0x0
    800039f8:	88e080e7          	jalr	-1906(ra) # 80003282 <brelse>
    ip->valid = 1;
    800039fc:	4785                	li	a5,1
    800039fe:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a00:	04449783          	lh	a5,68(s1)
    80003a04:	fbb5                	bnez	a5,80003978 <ilock+0x24>
      panic("ilock: no type");
    80003a06:	00005517          	auipc	a0,0x5
    80003a0a:	c1a50513          	addi	a0,a0,-998 # 80008620 <syscalls+0x198>
    80003a0e:	ffffd097          	auipc	ra,0xffffd
    80003a12:	b30080e7          	jalr	-1232(ra) # 8000053e <panic>

0000000080003a16 <iunlock>:
{
    80003a16:	1101                	addi	sp,sp,-32
    80003a18:	ec06                	sd	ra,24(sp)
    80003a1a:	e822                	sd	s0,16(sp)
    80003a1c:	e426                	sd	s1,8(sp)
    80003a1e:	e04a                	sd	s2,0(sp)
    80003a20:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a22:	c905                	beqz	a0,80003a52 <iunlock+0x3c>
    80003a24:	84aa                	mv	s1,a0
    80003a26:	01050913          	addi	s2,a0,16
    80003a2a:	854a                	mv	a0,s2
    80003a2c:	00001097          	auipc	ra,0x1
    80003a30:	c8c080e7          	jalr	-884(ra) # 800046b8 <holdingsleep>
    80003a34:	cd19                	beqz	a0,80003a52 <iunlock+0x3c>
    80003a36:	449c                	lw	a5,8(s1)
    80003a38:	00f05d63          	blez	a5,80003a52 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a3c:	854a                	mv	a0,s2
    80003a3e:	00001097          	auipc	ra,0x1
    80003a42:	c36080e7          	jalr	-970(ra) # 80004674 <releasesleep>
}
    80003a46:	60e2                	ld	ra,24(sp)
    80003a48:	6442                	ld	s0,16(sp)
    80003a4a:	64a2                	ld	s1,8(sp)
    80003a4c:	6902                	ld	s2,0(sp)
    80003a4e:	6105                	addi	sp,sp,32
    80003a50:	8082                	ret
    panic("iunlock");
    80003a52:	00005517          	auipc	a0,0x5
    80003a56:	bde50513          	addi	a0,a0,-1058 # 80008630 <syscalls+0x1a8>
    80003a5a:	ffffd097          	auipc	ra,0xffffd
    80003a5e:	ae4080e7          	jalr	-1308(ra) # 8000053e <panic>

0000000080003a62 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a62:	7179                	addi	sp,sp,-48
    80003a64:	f406                	sd	ra,40(sp)
    80003a66:	f022                	sd	s0,32(sp)
    80003a68:	ec26                	sd	s1,24(sp)
    80003a6a:	e84a                	sd	s2,16(sp)
    80003a6c:	e44e                	sd	s3,8(sp)
    80003a6e:	e052                	sd	s4,0(sp)
    80003a70:	1800                	addi	s0,sp,48
    80003a72:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a74:	05050493          	addi	s1,a0,80
    80003a78:	08050913          	addi	s2,a0,128
    80003a7c:	a021                	j	80003a84 <itrunc+0x22>
    80003a7e:	0491                	addi	s1,s1,4
    80003a80:	01248d63          	beq	s1,s2,80003a9a <itrunc+0x38>
    if(ip->addrs[i]){
    80003a84:	408c                	lw	a1,0(s1)
    80003a86:	dde5                	beqz	a1,80003a7e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a88:	0009a503          	lw	a0,0(s3)
    80003a8c:	00000097          	auipc	ra,0x0
    80003a90:	90c080e7          	jalr	-1780(ra) # 80003398 <bfree>
      ip->addrs[i] = 0;
    80003a94:	0004a023          	sw	zero,0(s1)
    80003a98:	b7dd                	j	80003a7e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a9a:	0809a583          	lw	a1,128(s3)
    80003a9e:	e185                	bnez	a1,80003abe <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003aa0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003aa4:	854e                	mv	a0,s3
    80003aa6:	00000097          	auipc	ra,0x0
    80003aaa:	de4080e7          	jalr	-540(ra) # 8000388a <iupdate>
}
    80003aae:	70a2                	ld	ra,40(sp)
    80003ab0:	7402                	ld	s0,32(sp)
    80003ab2:	64e2                	ld	s1,24(sp)
    80003ab4:	6942                	ld	s2,16(sp)
    80003ab6:	69a2                	ld	s3,8(sp)
    80003ab8:	6a02                	ld	s4,0(sp)
    80003aba:	6145                	addi	sp,sp,48
    80003abc:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003abe:	0009a503          	lw	a0,0(s3)
    80003ac2:	fffff097          	auipc	ra,0xfffff
    80003ac6:	690080e7          	jalr	1680(ra) # 80003152 <bread>
    80003aca:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003acc:	05850493          	addi	s1,a0,88
    80003ad0:	45850913          	addi	s2,a0,1112
    80003ad4:	a811                	j	80003ae8 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003ad6:	0009a503          	lw	a0,0(s3)
    80003ada:	00000097          	auipc	ra,0x0
    80003ade:	8be080e7          	jalr	-1858(ra) # 80003398 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003ae2:	0491                	addi	s1,s1,4
    80003ae4:	01248563          	beq	s1,s2,80003aee <itrunc+0x8c>
      if(a[j])
    80003ae8:	408c                	lw	a1,0(s1)
    80003aea:	dde5                	beqz	a1,80003ae2 <itrunc+0x80>
    80003aec:	b7ed                	j	80003ad6 <itrunc+0x74>
    brelse(bp);
    80003aee:	8552                	mv	a0,s4
    80003af0:	fffff097          	auipc	ra,0xfffff
    80003af4:	792080e7          	jalr	1938(ra) # 80003282 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003af8:	0809a583          	lw	a1,128(s3)
    80003afc:	0009a503          	lw	a0,0(s3)
    80003b00:	00000097          	auipc	ra,0x0
    80003b04:	898080e7          	jalr	-1896(ra) # 80003398 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b08:	0809a023          	sw	zero,128(s3)
    80003b0c:	bf51                	j	80003aa0 <itrunc+0x3e>

0000000080003b0e <iput>:
{
    80003b0e:	1101                	addi	sp,sp,-32
    80003b10:	ec06                	sd	ra,24(sp)
    80003b12:	e822                	sd	s0,16(sp)
    80003b14:	e426                	sd	s1,8(sp)
    80003b16:	e04a                	sd	s2,0(sp)
    80003b18:	1000                	addi	s0,sp,32
    80003b1a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b1c:	0001c517          	auipc	a0,0x1c
    80003b20:	eac50513          	addi	a0,a0,-340 # 8001f9c8 <itable>
    80003b24:	ffffd097          	auipc	ra,0xffffd
    80003b28:	0c0080e7          	jalr	192(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b2c:	4498                	lw	a4,8(s1)
    80003b2e:	4785                	li	a5,1
    80003b30:	02f70363          	beq	a4,a5,80003b56 <iput+0x48>
  ip->ref--;
    80003b34:	449c                	lw	a5,8(s1)
    80003b36:	37fd                	addiw	a5,a5,-1
    80003b38:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b3a:	0001c517          	auipc	a0,0x1c
    80003b3e:	e8e50513          	addi	a0,a0,-370 # 8001f9c8 <itable>
    80003b42:	ffffd097          	auipc	ra,0xffffd
    80003b46:	156080e7          	jalr	342(ra) # 80000c98 <release>
}
    80003b4a:	60e2                	ld	ra,24(sp)
    80003b4c:	6442                	ld	s0,16(sp)
    80003b4e:	64a2                	ld	s1,8(sp)
    80003b50:	6902                	ld	s2,0(sp)
    80003b52:	6105                	addi	sp,sp,32
    80003b54:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b56:	40bc                	lw	a5,64(s1)
    80003b58:	dff1                	beqz	a5,80003b34 <iput+0x26>
    80003b5a:	04a49783          	lh	a5,74(s1)
    80003b5e:	fbf9                	bnez	a5,80003b34 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b60:	01048913          	addi	s2,s1,16
    80003b64:	854a                	mv	a0,s2
    80003b66:	00001097          	auipc	ra,0x1
    80003b6a:	ab8080e7          	jalr	-1352(ra) # 8000461e <acquiresleep>
    release(&itable.lock);
    80003b6e:	0001c517          	auipc	a0,0x1c
    80003b72:	e5a50513          	addi	a0,a0,-422 # 8001f9c8 <itable>
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	122080e7          	jalr	290(ra) # 80000c98 <release>
    itrunc(ip);
    80003b7e:	8526                	mv	a0,s1
    80003b80:	00000097          	auipc	ra,0x0
    80003b84:	ee2080e7          	jalr	-286(ra) # 80003a62 <itrunc>
    ip->type = 0;
    80003b88:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b8c:	8526                	mv	a0,s1
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	cfc080e7          	jalr	-772(ra) # 8000388a <iupdate>
    ip->valid = 0;
    80003b96:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b9a:	854a                	mv	a0,s2
    80003b9c:	00001097          	auipc	ra,0x1
    80003ba0:	ad8080e7          	jalr	-1320(ra) # 80004674 <releasesleep>
    acquire(&itable.lock);
    80003ba4:	0001c517          	auipc	a0,0x1c
    80003ba8:	e2450513          	addi	a0,a0,-476 # 8001f9c8 <itable>
    80003bac:	ffffd097          	auipc	ra,0xffffd
    80003bb0:	038080e7          	jalr	56(ra) # 80000be4 <acquire>
    80003bb4:	b741                	j	80003b34 <iput+0x26>

0000000080003bb6 <iunlockput>:
{
    80003bb6:	1101                	addi	sp,sp,-32
    80003bb8:	ec06                	sd	ra,24(sp)
    80003bba:	e822                	sd	s0,16(sp)
    80003bbc:	e426                	sd	s1,8(sp)
    80003bbe:	1000                	addi	s0,sp,32
    80003bc0:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bc2:	00000097          	auipc	ra,0x0
    80003bc6:	e54080e7          	jalr	-428(ra) # 80003a16 <iunlock>
  iput(ip);
    80003bca:	8526                	mv	a0,s1
    80003bcc:	00000097          	auipc	ra,0x0
    80003bd0:	f42080e7          	jalr	-190(ra) # 80003b0e <iput>
}
    80003bd4:	60e2                	ld	ra,24(sp)
    80003bd6:	6442                	ld	s0,16(sp)
    80003bd8:	64a2                	ld	s1,8(sp)
    80003bda:	6105                	addi	sp,sp,32
    80003bdc:	8082                	ret

0000000080003bde <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bde:	1141                	addi	sp,sp,-16
    80003be0:	e422                	sd	s0,8(sp)
    80003be2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003be4:	411c                	lw	a5,0(a0)
    80003be6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003be8:	415c                	lw	a5,4(a0)
    80003bea:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bec:	04451783          	lh	a5,68(a0)
    80003bf0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bf4:	04a51783          	lh	a5,74(a0)
    80003bf8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003bfc:	04c56783          	lwu	a5,76(a0)
    80003c00:	e99c                	sd	a5,16(a1)
}
    80003c02:	6422                	ld	s0,8(sp)
    80003c04:	0141                	addi	sp,sp,16
    80003c06:	8082                	ret

0000000080003c08 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c08:	457c                	lw	a5,76(a0)
    80003c0a:	0ed7e963          	bltu	a5,a3,80003cfc <readi+0xf4>
{
    80003c0e:	7159                	addi	sp,sp,-112
    80003c10:	f486                	sd	ra,104(sp)
    80003c12:	f0a2                	sd	s0,96(sp)
    80003c14:	eca6                	sd	s1,88(sp)
    80003c16:	e8ca                	sd	s2,80(sp)
    80003c18:	e4ce                	sd	s3,72(sp)
    80003c1a:	e0d2                	sd	s4,64(sp)
    80003c1c:	fc56                	sd	s5,56(sp)
    80003c1e:	f85a                	sd	s6,48(sp)
    80003c20:	f45e                	sd	s7,40(sp)
    80003c22:	f062                	sd	s8,32(sp)
    80003c24:	ec66                	sd	s9,24(sp)
    80003c26:	e86a                	sd	s10,16(sp)
    80003c28:	e46e                	sd	s11,8(sp)
    80003c2a:	1880                	addi	s0,sp,112
    80003c2c:	8baa                	mv	s7,a0
    80003c2e:	8c2e                	mv	s8,a1
    80003c30:	8ab2                	mv	s5,a2
    80003c32:	84b6                	mv	s1,a3
    80003c34:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c36:	9f35                	addw	a4,a4,a3
    return 0;
    80003c38:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c3a:	0ad76063          	bltu	a4,a3,80003cda <readi+0xd2>
  if(off + n > ip->size)
    80003c3e:	00e7f463          	bgeu	a5,a4,80003c46 <readi+0x3e>
    n = ip->size - off;
    80003c42:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c46:	0a0b0963          	beqz	s6,80003cf8 <readi+0xf0>
    80003c4a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c4c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c50:	5cfd                	li	s9,-1
    80003c52:	a82d                	j	80003c8c <readi+0x84>
    80003c54:	020a1d93          	slli	s11,s4,0x20
    80003c58:	020ddd93          	srli	s11,s11,0x20
    80003c5c:	05890613          	addi	a2,s2,88
    80003c60:	86ee                	mv	a3,s11
    80003c62:	963a                	add	a2,a2,a4
    80003c64:	85d6                	mv	a1,s5
    80003c66:	8562                	mv	a0,s8
    80003c68:	fffff097          	auipc	ra,0xfffff
    80003c6c:	a42080e7          	jalr	-1470(ra) # 800026aa <either_copyout>
    80003c70:	05950d63          	beq	a0,s9,80003cca <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c74:	854a                	mv	a0,s2
    80003c76:	fffff097          	auipc	ra,0xfffff
    80003c7a:	60c080e7          	jalr	1548(ra) # 80003282 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c7e:	013a09bb          	addw	s3,s4,s3
    80003c82:	009a04bb          	addw	s1,s4,s1
    80003c86:	9aee                	add	s5,s5,s11
    80003c88:	0569f763          	bgeu	s3,s6,80003cd6 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c8c:	000ba903          	lw	s2,0(s7)
    80003c90:	00a4d59b          	srliw	a1,s1,0xa
    80003c94:	855e                	mv	a0,s7
    80003c96:	00000097          	auipc	ra,0x0
    80003c9a:	8b0080e7          	jalr	-1872(ra) # 80003546 <bmap>
    80003c9e:	0005059b          	sext.w	a1,a0
    80003ca2:	854a                	mv	a0,s2
    80003ca4:	fffff097          	auipc	ra,0xfffff
    80003ca8:	4ae080e7          	jalr	1198(ra) # 80003152 <bread>
    80003cac:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cae:	3ff4f713          	andi	a4,s1,1023
    80003cb2:	40ed07bb          	subw	a5,s10,a4
    80003cb6:	413b06bb          	subw	a3,s6,s3
    80003cba:	8a3e                	mv	s4,a5
    80003cbc:	2781                	sext.w	a5,a5
    80003cbe:	0006861b          	sext.w	a2,a3
    80003cc2:	f8f679e3          	bgeu	a2,a5,80003c54 <readi+0x4c>
    80003cc6:	8a36                	mv	s4,a3
    80003cc8:	b771                	j	80003c54 <readi+0x4c>
      brelse(bp);
    80003cca:	854a                	mv	a0,s2
    80003ccc:	fffff097          	auipc	ra,0xfffff
    80003cd0:	5b6080e7          	jalr	1462(ra) # 80003282 <brelse>
      tot = -1;
    80003cd4:	59fd                	li	s3,-1
  }
  return tot;
    80003cd6:	0009851b          	sext.w	a0,s3
}
    80003cda:	70a6                	ld	ra,104(sp)
    80003cdc:	7406                	ld	s0,96(sp)
    80003cde:	64e6                	ld	s1,88(sp)
    80003ce0:	6946                	ld	s2,80(sp)
    80003ce2:	69a6                	ld	s3,72(sp)
    80003ce4:	6a06                	ld	s4,64(sp)
    80003ce6:	7ae2                	ld	s5,56(sp)
    80003ce8:	7b42                	ld	s6,48(sp)
    80003cea:	7ba2                	ld	s7,40(sp)
    80003cec:	7c02                	ld	s8,32(sp)
    80003cee:	6ce2                	ld	s9,24(sp)
    80003cf0:	6d42                	ld	s10,16(sp)
    80003cf2:	6da2                	ld	s11,8(sp)
    80003cf4:	6165                	addi	sp,sp,112
    80003cf6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cf8:	89da                	mv	s3,s6
    80003cfa:	bff1                	j	80003cd6 <readi+0xce>
    return 0;
    80003cfc:	4501                	li	a0,0
}
    80003cfe:	8082                	ret

0000000080003d00 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d00:	457c                	lw	a5,76(a0)
    80003d02:	10d7e863          	bltu	a5,a3,80003e12 <writei+0x112>
{
    80003d06:	7159                	addi	sp,sp,-112
    80003d08:	f486                	sd	ra,104(sp)
    80003d0a:	f0a2                	sd	s0,96(sp)
    80003d0c:	eca6                	sd	s1,88(sp)
    80003d0e:	e8ca                	sd	s2,80(sp)
    80003d10:	e4ce                	sd	s3,72(sp)
    80003d12:	e0d2                	sd	s4,64(sp)
    80003d14:	fc56                	sd	s5,56(sp)
    80003d16:	f85a                	sd	s6,48(sp)
    80003d18:	f45e                	sd	s7,40(sp)
    80003d1a:	f062                	sd	s8,32(sp)
    80003d1c:	ec66                	sd	s9,24(sp)
    80003d1e:	e86a                	sd	s10,16(sp)
    80003d20:	e46e                	sd	s11,8(sp)
    80003d22:	1880                	addi	s0,sp,112
    80003d24:	8b2a                	mv	s6,a0
    80003d26:	8c2e                	mv	s8,a1
    80003d28:	8ab2                	mv	s5,a2
    80003d2a:	8936                	mv	s2,a3
    80003d2c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d2e:	00e687bb          	addw	a5,a3,a4
    80003d32:	0ed7e263          	bltu	a5,a3,80003e16 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d36:	00043737          	lui	a4,0x43
    80003d3a:	0ef76063          	bltu	a4,a5,80003e1a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d3e:	0c0b8863          	beqz	s7,80003e0e <writei+0x10e>
    80003d42:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d44:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d48:	5cfd                	li	s9,-1
    80003d4a:	a091                	j	80003d8e <writei+0x8e>
    80003d4c:	02099d93          	slli	s11,s3,0x20
    80003d50:	020ddd93          	srli	s11,s11,0x20
    80003d54:	05848513          	addi	a0,s1,88
    80003d58:	86ee                	mv	a3,s11
    80003d5a:	8656                	mv	a2,s5
    80003d5c:	85e2                	mv	a1,s8
    80003d5e:	953a                	add	a0,a0,a4
    80003d60:	fffff097          	auipc	ra,0xfffff
    80003d64:	9a0080e7          	jalr	-1632(ra) # 80002700 <either_copyin>
    80003d68:	07950263          	beq	a0,s9,80003dcc <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d6c:	8526                	mv	a0,s1
    80003d6e:	00000097          	auipc	ra,0x0
    80003d72:	790080e7          	jalr	1936(ra) # 800044fe <log_write>
    brelse(bp);
    80003d76:	8526                	mv	a0,s1
    80003d78:	fffff097          	auipc	ra,0xfffff
    80003d7c:	50a080e7          	jalr	1290(ra) # 80003282 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d80:	01498a3b          	addw	s4,s3,s4
    80003d84:	0129893b          	addw	s2,s3,s2
    80003d88:	9aee                	add	s5,s5,s11
    80003d8a:	057a7663          	bgeu	s4,s7,80003dd6 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d8e:	000b2483          	lw	s1,0(s6)
    80003d92:	00a9559b          	srliw	a1,s2,0xa
    80003d96:	855a                	mv	a0,s6
    80003d98:	fffff097          	auipc	ra,0xfffff
    80003d9c:	7ae080e7          	jalr	1966(ra) # 80003546 <bmap>
    80003da0:	0005059b          	sext.w	a1,a0
    80003da4:	8526                	mv	a0,s1
    80003da6:	fffff097          	auipc	ra,0xfffff
    80003daa:	3ac080e7          	jalr	940(ra) # 80003152 <bread>
    80003dae:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003db0:	3ff97713          	andi	a4,s2,1023
    80003db4:	40ed07bb          	subw	a5,s10,a4
    80003db8:	414b86bb          	subw	a3,s7,s4
    80003dbc:	89be                	mv	s3,a5
    80003dbe:	2781                	sext.w	a5,a5
    80003dc0:	0006861b          	sext.w	a2,a3
    80003dc4:	f8f674e3          	bgeu	a2,a5,80003d4c <writei+0x4c>
    80003dc8:	89b6                	mv	s3,a3
    80003dca:	b749                	j	80003d4c <writei+0x4c>
      brelse(bp);
    80003dcc:	8526                	mv	a0,s1
    80003dce:	fffff097          	auipc	ra,0xfffff
    80003dd2:	4b4080e7          	jalr	1204(ra) # 80003282 <brelse>
  }

  if(off > ip->size)
    80003dd6:	04cb2783          	lw	a5,76(s6)
    80003dda:	0127f463          	bgeu	a5,s2,80003de2 <writei+0xe2>
    ip->size = off;
    80003dde:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003de2:	855a                	mv	a0,s6
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	aa6080e7          	jalr	-1370(ra) # 8000388a <iupdate>

  return tot;
    80003dec:	000a051b          	sext.w	a0,s4
}
    80003df0:	70a6                	ld	ra,104(sp)
    80003df2:	7406                	ld	s0,96(sp)
    80003df4:	64e6                	ld	s1,88(sp)
    80003df6:	6946                	ld	s2,80(sp)
    80003df8:	69a6                	ld	s3,72(sp)
    80003dfa:	6a06                	ld	s4,64(sp)
    80003dfc:	7ae2                	ld	s5,56(sp)
    80003dfe:	7b42                	ld	s6,48(sp)
    80003e00:	7ba2                	ld	s7,40(sp)
    80003e02:	7c02                	ld	s8,32(sp)
    80003e04:	6ce2                	ld	s9,24(sp)
    80003e06:	6d42                	ld	s10,16(sp)
    80003e08:	6da2                	ld	s11,8(sp)
    80003e0a:	6165                	addi	sp,sp,112
    80003e0c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e0e:	8a5e                	mv	s4,s7
    80003e10:	bfc9                	j	80003de2 <writei+0xe2>
    return -1;
    80003e12:	557d                	li	a0,-1
}
    80003e14:	8082                	ret
    return -1;
    80003e16:	557d                	li	a0,-1
    80003e18:	bfe1                	j	80003df0 <writei+0xf0>
    return -1;
    80003e1a:	557d                	li	a0,-1
    80003e1c:	bfd1                	j	80003df0 <writei+0xf0>

0000000080003e1e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e1e:	1141                	addi	sp,sp,-16
    80003e20:	e406                	sd	ra,8(sp)
    80003e22:	e022                	sd	s0,0(sp)
    80003e24:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e26:	4639                	li	a2,14
    80003e28:	ffffd097          	auipc	ra,0xffffd
    80003e2c:	f90080e7          	jalr	-112(ra) # 80000db8 <strncmp>
}
    80003e30:	60a2                	ld	ra,8(sp)
    80003e32:	6402                	ld	s0,0(sp)
    80003e34:	0141                	addi	sp,sp,16
    80003e36:	8082                	ret

0000000080003e38 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e38:	7139                	addi	sp,sp,-64
    80003e3a:	fc06                	sd	ra,56(sp)
    80003e3c:	f822                	sd	s0,48(sp)
    80003e3e:	f426                	sd	s1,40(sp)
    80003e40:	f04a                	sd	s2,32(sp)
    80003e42:	ec4e                	sd	s3,24(sp)
    80003e44:	e852                	sd	s4,16(sp)
    80003e46:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e48:	04451703          	lh	a4,68(a0)
    80003e4c:	4785                	li	a5,1
    80003e4e:	00f71a63          	bne	a4,a5,80003e62 <dirlookup+0x2a>
    80003e52:	892a                	mv	s2,a0
    80003e54:	89ae                	mv	s3,a1
    80003e56:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e58:	457c                	lw	a5,76(a0)
    80003e5a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e5c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e5e:	e79d                	bnez	a5,80003e8c <dirlookup+0x54>
    80003e60:	a8a5                	j	80003ed8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e62:	00004517          	auipc	a0,0x4
    80003e66:	7d650513          	addi	a0,a0,2006 # 80008638 <syscalls+0x1b0>
    80003e6a:	ffffc097          	auipc	ra,0xffffc
    80003e6e:	6d4080e7          	jalr	1748(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003e72:	00004517          	auipc	a0,0x4
    80003e76:	7de50513          	addi	a0,a0,2014 # 80008650 <syscalls+0x1c8>
    80003e7a:	ffffc097          	auipc	ra,0xffffc
    80003e7e:	6c4080e7          	jalr	1732(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e82:	24c1                	addiw	s1,s1,16
    80003e84:	04c92783          	lw	a5,76(s2)
    80003e88:	04f4f763          	bgeu	s1,a5,80003ed6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e8c:	4741                	li	a4,16
    80003e8e:	86a6                	mv	a3,s1
    80003e90:	fc040613          	addi	a2,s0,-64
    80003e94:	4581                	li	a1,0
    80003e96:	854a                	mv	a0,s2
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	d70080e7          	jalr	-656(ra) # 80003c08 <readi>
    80003ea0:	47c1                	li	a5,16
    80003ea2:	fcf518e3          	bne	a0,a5,80003e72 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ea6:	fc045783          	lhu	a5,-64(s0)
    80003eaa:	dfe1                	beqz	a5,80003e82 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003eac:	fc240593          	addi	a1,s0,-62
    80003eb0:	854e                	mv	a0,s3
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	f6c080e7          	jalr	-148(ra) # 80003e1e <namecmp>
    80003eba:	f561                	bnez	a0,80003e82 <dirlookup+0x4a>
      if(poff)
    80003ebc:	000a0463          	beqz	s4,80003ec4 <dirlookup+0x8c>
        *poff = off;
    80003ec0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ec4:	fc045583          	lhu	a1,-64(s0)
    80003ec8:	00092503          	lw	a0,0(s2)
    80003ecc:	fffff097          	auipc	ra,0xfffff
    80003ed0:	754080e7          	jalr	1876(ra) # 80003620 <iget>
    80003ed4:	a011                	j	80003ed8 <dirlookup+0xa0>
  return 0;
    80003ed6:	4501                	li	a0,0
}
    80003ed8:	70e2                	ld	ra,56(sp)
    80003eda:	7442                	ld	s0,48(sp)
    80003edc:	74a2                	ld	s1,40(sp)
    80003ede:	7902                	ld	s2,32(sp)
    80003ee0:	69e2                	ld	s3,24(sp)
    80003ee2:	6a42                	ld	s4,16(sp)
    80003ee4:	6121                	addi	sp,sp,64
    80003ee6:	8082                	ret

0000000080003ee8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ee8:	711d                	addi	sp,sp,-96
    80003eea:	ec86                	sd	ra,88(sp)
    80003eec:	e8a2                	sd	s0,80(sp)
    80003eee:	e4a6                	sd	s1,72(sp)
    80003ef0:	e0ca                	sd	s2,64(sp)
    80003ef2:	fc4e                	sd	s3,56(sp)
    80003ef4:	f852                	sd	s4,48(sp)
    80003ef6:	f456                	sd	s5,40(sp)
    80003ef8:	f05a                	sd	s6,32(sp)
    80003efa:	ec5e                	sd	s7,24(sp)
    80003efc:	e862                	sd	s8,16(sp)
    80003efe:	e466                	sd	s9,8(sp)
    80003f00:	1080                	addi	s0,sp,96
    80003f02:	84aa                	mv	s1,a0
    80003f04:	8b2e                	mv	s6,a1
    80003f06:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f08:	00054703          	lbu	a4,0(a0)
    80003f0c:	02f00793          	li	a5,47
    80003f10:	02f70363          	beq	a4,a5,80003f36 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f14:	ffffe097          	auipc	ra,0xffffe
    80003f18:	ab0080e7          	jalr	-1360(ra) # 800019c4 <myproc>
    80003f1c:	15853503          	ld	a0,344(a0)
    80003f20:	00000097          	auipc	ra,0x0
    80003f24:	9f6080e7          	jalr	-1546(ra) # 80003916 <idup>
    80003f28:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f2a:	02f00913          	li	s2,47
  len = path - s;
    80003f2e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f30:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f32:	4c05                	li	s8,1
    80003f34:	a865                	j	80003fec <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f36:	4585                	li	a1,1
    80003f38:	4505                	li	a0,1
    80003f3a:	fffff097          	auipc	ra,0xfffff
    80003f3e:	6e6080e7          	jalr	1766(ra) # 80003620 <iget>
    80003f42:	89aa                	mv	s3,a0
    80003f44:	b7dd                	j	80003f2a <namex+0x42>
      iunlockput(ip);
    80003f46:	854e                	mv	a0,s3
    80003f48:	00000097          	auipc	ra,0x0
    80003f4c:	c6e080e7          	jalr	-914(ra) # 80003bb6 <iunlockput>
      return 0;
    80003f50:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f52:	854e                	mv	a0,s3
    80003f54:	60e6                	ld	ra,88(sp)
    80003f56:	6446                	ld	s0,80(sp)
    80003f58:	64a6                	ld	s1,72(sp)
    80003f5a:	6906                	ld	s2,64(sp)
    80003f5c:	79e2                	ld	s3,56(sp)
    80003f5e:	7a42                	ld	s4,48(sp)
    80003f60:	7aa2                	ld	s5,40(sp)
    80003f62:	7b02                	ld	s6,32(sp)
    80003f64:	6be2                	ld	s7,24(sp)
    80003f66:	6c42                	ld	s8,16(sp)
    80003f68:	6ca2                	ld	s9,8(sp)
    80003f6a:	6125                	addi	sp,sp,96
    80003f6c:	8082                	ret
      iunlock(ip);
    80003f6e:	854e                	mv	a0,s3
    80003f70:	00000097          	auipc	ra,0x0
    80003f74:	aa6080e7          	jalr	-1370(ra) # 80003a16 <iunlock>
      return ip;
    80003f78:	bfe9                	j	80003f52 <namex+0x6a>
      iunlockput(ip);
    80003f7a:	854e                	mv	a0,s3
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	c3a080e7          	jalr	-966(ra) # 80003bb6 <iunlockput>
      return 0;
    80003f84:	89d2                	mv	s3,s4
    80003f86:	b7f1                	j	80003f52 <namex+0x6a>
  len = path - s;
    80003f88:	40b48633          	sub	a2,s1,a1
    80003f8c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f90:	094cd463          	bge	s9,s4,80004018 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f94:	4639                	li	a2,14
    80003f96:	8556                	mv	a0,s5
    80003f98:	ffffd097          	auipc	ra,0xffffd
    80003f9c:	da8080e7          	jalr	-600(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003fa0:	0004c783          	lbu	a5,0(s1)
    80003fa4:	01279763          	bne	a5,s2,80003fb2 <namex+0xca>
    path++;
    80003fa8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003faa:	0004c783          	lbu	a5,0(s1)
    80003fae:	ff278de3          	beq	a5,s2,80003fa8 <namex+0xc0>
    ilock(ip);
    80003fb2:	854e                	mv	a0,s3
    80003fb4:	00000097          	auipc	ra,0x0
    80003fb8:	9a0080e7          	jalr	-1632(ra) # 80003954 <ilock>
    if(ip->type != T_DIR){
    80003fbc:	04499783          	lh	a5,68(s3)
    80003fc0:	f98793e3          	bne	a5,s8,80003f46 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fc4:	000b0563          	beqz	s6,80003fce <namex+0xe6>
    80003fc8:	0004c783          	lbu	a5,0(s1)
    80003fcc:	d3cd                	beqz	a5,80003f6e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fce:	865e                	mv	a2,s7
    80003fd0:	85d6                	mv	a1,s5
    80003fd2:	854e                	mv	a0,s3
    80003fd4:	00000097          	auipc	ra,0x0
    80003fd8:	e64080e7          	jalr	-412(ra) # 80003e38 <dirlookup>
    80003fdc:	8a2a                	mv	s4,a0
    80003fde:	dd51                	beqz	a0,80003f7a <namex+0x92>
    iunlockput(ip);
    80003fe0:	854e                	mv	a0,s3
    80003fe2:	00000097          	auipc	ra,0x0
    80003fe6:	bd4080e7          	jalr	-1068(ra) # 80003bb6 <iunlockput>
    ip = next;
    80003fea:	89d2                	mv	s3,s4
  while(*path == '/')
    80003fec:	0004c783          	lbu	a5,0(s1)
    80003ff0:	05279763          	bne	a5,s2,8000403e <namex+0x156>
    path++;
    80003ff4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ff6:	0004c783          	lbu	a5,0(s1)
    80003ffa:	ff278de3          	beq	a5,s2,80003ff4 <namex+0x10c>
  if(*path == 0)
    80003ffe:	c79d                	beqz	a5,8000402c <namex+0x144>
    path++;
    80004000:	85a6                	mv	a1,s1
  len = path - s;
    80004002:	8a5e                	mv	s4,s7
    80004004:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004006:	01278963          	beq	a5,s2,80004018 <namex+0x130>
    8000400a:	dfbd                	beqz	a5,80003f88 <namex+0xa0>
    path++;
    8000400c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000400e:	0004c783          	lbu	a5,0(s1)
    80004012:	ff279ce3          	bne	a5,s2,8000400a <namex+0x122>
    80004016:	bf8d                	j	80003f88 <namex+0xa0>
    memmove(name, s, len);
    80004018:	2601                	sext.w	a2,a2
    8000401a:	8556                	mv	a0,s5
    8000401c:	ffffd097          	auipc	ra,0xffffd
    80004020:	d24080e7          	jalr	-732(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004024:	9a56                	add	s4,s4,s5
    80004026:	000a0023          	sb	zero,0(s4)
    8000402a:	bf9d                	j	80003fa0 <namex+0xb8>
  if(nameiparent){
    8000402c:	f20b03e3          	beqz	s6,80003f52 <namex+0x6a>
    iput(ip);
    80004030:	854e                	mv	a0,s3
    80004032:	00000097          	auipc	ra,0x0
    80004036:	adc080e7          	jalr	-1316(ra) # 80003b0e <iput>
    return 0;
    8000403a:	4981                	li	s3,0
    8000403c:	bf19                	j	80003f52 <namex+0x6a>
  if(*path == 0)
    8000403e:	d7fd                	beqz	a5,8000402c <namex+0x144>
  while(*path != '/' && *path != 0)
    80004040:	0004c783          	lbu	a5,0(s1)
    80004044:	85a6                	mv	a1,s1
    80004046:	b7d1                	j	8000400a <namex+0x122>

0000000080004048 <dirlink>:
{
    80004048:	7139                	addi	sp,sp,-64
    8000404a:	fc06                	sd	ra,56(sp)
    8000404c:	f822                	sd	s0,48(sp)
    8000404e:	f426                	sd	s1,40(sp)
    80004050:	f04a                	sd	s2,32(sp)
    80004052:	ec4e                	sd	s3,24(sp)
    80004054:	e852                	sd	s4,16(sp)
    80004056:	0080                	addi	s0,sp,64
    80004058:	892a                	mv	s2,a0
    8000405a:	8a2e                	mv	s4,a1
    8000405c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000405e:	4601                	li	a2,0
    80004060:	00000097          	auipc	ra,0x0
    80004064:	dd8080e7          	jalr	-552(ra) # 80003e38 <dirlookup>
    80004068:	e93d                	bnez	a0,800040de <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000406a:	04c92483          	lw	s1,76(s2)
    8000406e:	c49d                	beqz	s1,8000409c <dirlink+0x54>
    80004070:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004072:	4741                	li	a4,16
    80004074:	86a6                	mv	a3,s1
    80004076:	fc040613          	addi	a2,s0,-64
    8000407a:	4581                	li	a1,0
    8000407c:	854a                	mv	a0,s2
    8000407e:	00000097          	auipc	ra,0x0
    80004082:	b8a080e7          	jalr	-1142(ra) # 80003c08 <readi>
    80004086:	47c1                	li	a5,16
    80004088:	06f51163          	bne	a0,a5,800040ea <dirlink+0xa2>
    if(de.inum == 0)
    8000408c:	fc045783          	lhu	a5,-64(s0)
    80004090:	c791                	beqz	a5,8000409c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004092:	24c1                	addiw	s1,s1,16
    80004094:	04c92783          	lw	a5,76(s2)
    80004098:	fcf4ede3          	bltu	s1,a5,80004072 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000409c:	4639                	li	a2,14
    8000409e:	85d2                	mv	a1,s4
    800040a0:	fc240513          	addi	a0,s0,-62
    800040a4:	ffffd097          	auipc	ra,0xffffd
    800040a8:	d50080e7          	jalr	-688(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800040ac:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040b0:	4741                	li	a4,16
    800040b2:	86a6                	mv	a3,s1
    800040b4:	fc040613          	addi	a2,s0,-64
    800040b8:	4581                	li	a1,0
    800040ba:	854a                	mv	a0,s2
    800040bc:	00000097          	auipc	ra,0x0
    800040c0:	c44080e7          	jalr	-956(ra) # 80003d00 <writei>
    800040c4:	872a                	mv	a4,a0
    800040c6:	47c1                	li	a5,16
  return 0;
    800040c8:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ca:	02f71863          	bne	a4,a5,800040fa <dirlink+0xb2>
}
    800040ce:	70e2                	ld	ra,56(sp)
    800040d0:	7442                	ld	s0,48(sp)
    800040d2:	74a2                	ld	s1,40(sp)
    800040d4:	7902                	ld	s2,32(sp)
    800040d6:	69e2                	ld	s3,24(sp)
    800040d8:	6a42                	ld	s4,16(sp)
    800040da:	6121                	addi	sp,sp,64
    800040dc:	8082                	ret
    iput(ip);
    800040de:	00000097          	auipc	ra,0x0
    800040e2:	a30080e7          	jalr	-1488(ra) # 80003b0e <iput>
    return -1;
    800040e6:	557d                	li	a0,-1
    800040e8:	b7dd                	j	800040ce <dirlink+0x86>
      panic("dirlink read");
    800040ea:	00004517          	auipc	a0,0x4
    800040ee:	57650513          	addi	a0,a0,1398 # 80008660 <syscalls+0x1d8>
    800040f2:	ffffc097          	auipc	ra,0xffffc
    800040f6:	44c080e7          	jalr	1100(ra) # 8000053e <panic>
    panic("dirlink");
    800040fa:	00004517          	auipc	a0,0x4
    800040fe:	67650513          	addi	a0,a0,1654 # 80008770 <syscalls+0x2e8>
    80004102:	ffffc097          	auipc	ra,0xffffc
    80004106:	43c080e7          	jalr	1084(ra) # 8000053e <panic>

000000008000410a <namei>:

struct inode*
namei(char *path)
{
    8000410a:	1101                	addi	sp,sp,-32
    8000410c:	ec06                	sd	ra,24(sp)
    8000410e:	e822                	sd	s0,16(sp)
    80004110:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004112:	fe040613          	addi	a2,s0,-32
    80004116:	4581                	li	a1,0
    80004118:	00000097          	auipc	ra,0x0
    8000411c:	dd0080e7          	jalr	-560(ra) # 80003ee8 <namex>
}
    80004120:	60e2                	ld	ra,24(sp)
    80004122:	6442                	ld	s0,16(sp)
    80004124:	6105                	addi	sp,sp,32
    80004126:	8082                	ret

0000000080004128 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004128:	1141                	addi	sp,sp,-16
    8000412a:	e406                	sd	ra,8(sp)
    8000412c:	e022                	sd	s0,0(sp)
    8000412e:	0800                	addi	s0,sp,16
    80004130:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004132:	4585                	li	a1,1
    80004134:	00000097          	auipc	ra,0x0
    80004138:	db4080e7          	jalr	-588(ra) # 80003ee8 <namex>
}
    8000413c:	60a2                	ld	ra,8(sp)
    8000413e:	6402                	ld	s0,0(sp)
    80004140:	0141                	addi	sp,sp,16
    80004142:	8082                	ret

0000000080004144 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004144:	1101                	addi	sp,sp,-32
    80004146:	ec06                	sd	ra,24(sp)
    80004148:	e822                	sd	s0,16(sp)
    8000414a:	e426                	sd	s1,8(sp)
    8000414c:	e04a                	sd	s2,0(sp)
    8000414e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004150:	0001d917          	auipc	s2,0x1d
    80004154:	32090913          	addi	s2,s2,800 # 80021470 <log>
    80004158:	01892583          	lw	a1,24(s2)
    8000415c:	02892503          	lw	a0,40(s2)
    80004160:	fffff097          	auipc	ra,0xfffff
    80004164:	ff2080e7          	jalr	-14(ra) # 80003152 <bread>
    80004168:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000416a:	02c92683          	lw	a3,44(s2)
    8000416e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004170:	02d05763          	blez	a3,8000419e <write_head+0x5a>
    80004174:	0001d797          	auipc	a5,0x1d
    80004178:	32c78793          	addi	a5,a5,812 # 800214a0 <log+0x30>
    8000417c:	05c50713          	addi	a4,a0,92
    80004180:	36fd                	addiw	a3,a3,-1
    80004182:	1682                	slli	a3,a3,0x20
    80004184:	9281                	srli	a3,a3,0x20
    80004186:	068a                	slli	a3,a3,0x2
    80004188:	0001d617          	auipc	a2,0x1d
    8000418c:	31c60613          	addi	a2,a2,796 # 800214a4 <log+0x34>
    80004190:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004192:	4390                	lw	a2,0(a5)
    80004194:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004196:	0791                	addi	a5,a5,4
    80004198:	0711                	addi	a4,a4,4
    8000419a:	fed79ce3          	bne	a5,a3,80004192 <write_head+0x4e>
  }
  bwrite(buf);
    8000419e:	8526                	mv	a0,s1
    800041a0:	fffff097          	auipc	ra,0xfffff
    800041a4:	0a4080e7          	jalr	164(ra) # 80003244 <bwrite>
  brelse(buf);
    800041a8:	8526                	mv	a0,s1
    800041aa:	fffff097          	auipc	ra,0xfffff
    800041ae:	0d8080e7          	jalr	216(ra) # 80003282 <brelse>
}
    800041b2:	60e2                	ld	ra,24(sp)
    800041b4:	6442                	ld	s0,16(sp)
    800041b6:	64a2                	ld	s1,8(sp)
    800041b8:	6902                	ld	s2,0(sp)
    800041ba:	6105                	addi	sp,sp,32
    800041bc:	8082                	ret

00000000800041be <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041be:	0001d797          	auipc	a5,0x1d
    800041c2:	2de7a783          	lw	a5,734(a5) # 8002149c <log+0x2c>
    800041c6:	0af05d63          	blez	a5,80004280 <install_trans+0xc2>
{
    800041ca:	7139                	addi	sp,sp,-64
    800041cc:	fc06                	sd	ra,56(sp)
    800041ce:	f822                	sd	s0,48(sp)
    800041d0:	f426                	sd	s1,40(sp)
    800041d2:	f04a                	sd	s2,32(sp)
    800041d4:	ec4e                	sd	s3,24(sp)
    800041d6:	e852                	sd	s4,16(sp)
    800041d8:	e456                	sd	s5,8(sp)
    800041da:	e05a                	sd	s6,0(sp)
    800041dc:	0080                	addi	s0,sp,64
    800041de:	8b2a                	mv	s6,a0
    800041e0:	0001da97          	auipc	s5,0x1d
    800041e4:	2c0a8a93          	addi	s5,s5,704 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041e8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041ea:	0001d997          	auipc	s3,0x1d
    800041ee:	28698993          	addi	s3,s3,646 # 80021470 <log>
    800041f2:	a035                	j	8000421e <install_trans+0x60>
      bunpin(dbuf);
    800041f4:	8526                	mv	a0,s1
    800041f6:	fffff097          	auipc	ra,0xfffff
    800041fa:	166080e7          	jalr	358(ra) # 8000335c <bunpin>
    brelse(lbuf);
    800041fe:	854a                	mv	a0,s2
    80004200:	fffff097          	auipc	ra,0xfffff
    80004204:	082080e7          	jalr	130(ra) # 80003282 <brelse>
    brelse(dbuf);
    80004208:	8526                	mv	a0,s1
    8000420a:	fffff097          	auipc	ra,0xfffff
    8000420e:	078080e7          	jalr	120(ra) # 80003282 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004212:	2a05                	addiw	s4,s4,1
    80004214:	0a91                	addi	s5,s5,4
    80004216:	02c9a783          	lw	a5,44(s3)
    8000421a:	04fa5963          	bge	s4,a5,8000426c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000421e:	0189a583          	lw	a1,24(s3)
    80004222:	014585bb          	addw	a1,a1,s4
    80004226:	2585                	addiw	a1,a1,1
    80004228:	0289a503          	lw	a0,40(s3)
    8000422c:	fffff097          	auipc	ra,0xfffff
    80004230:	f26080e7          	jalr	-218(ra) # 80003152 <bread>
    80004234:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004236:	000aa583          	lw	a1,0(s5)
    8000423a:	0289a503          	lw	a0,40(s3)
    8000423e:	fffff097          	auipc	ra,0xfffff
    80004242:	f14080e7          	jalr	-236(ra) # 80003152 <bread>
    80004246:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004248:	40000613          	li	a2,1024
    8000424c:	05890593          	addi	a1,s2,88
    80004250:	05850513          	addi	a0,a0,88
    80004254:	ffffd097          	auipc	ra,0xffffd
    80004258:	aec080e7          	jalr	-1300(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000425c:	8526                	mv	a0,s1
    8000425e:	fffff097          	auipc	ra,0xfffff
    80004262:	fe6080e7          	jalr	-26(ra) # 80003244 <bwrite>
    if(recovering == 0)
    80004266:	f80b1ce3          	bnez	s6,800041fe <install_trans+0x40>
    8000426a:	b769                	j	800041f4 <install_trans+0x36>
}
    8000426c:	70e2                	ld	ra,56(sp)
    8000426e:	7442                	ld	s0,48(sp)
    80004270:	74a2                	ld	s1,40(sp)
    80004272:	7902                	ld	s2,32(sp)
    80004274:	69e2                	ld	s3,24(sp)
    80004276:	6a42                	ld	s4,16(sp)
    80004278:	6aa2                	ld	s5,8(sp)
    8000427a:	6b02                	ld	s6,0(sp)
    8000427c:	6121                	addi	sp,sp,64
    8000427e:	8082                	ret
    80004280:	8082                	ret

0000000080004282 <initlog>:
{
    80004282:	7179                	addi	sp,sp,-48
    80004284:	f406                	sd	ra,40(sp)
    80004286:	f022                	sd	s0,32(sp)
    80004288:	ec26                	sd	s1,24(sp)
    8000428a:	e84a                	sd	s2,16(sp)
    8000428c:	e44e                	sd	s3,8(sp)
    8000428e:	1800                	addi	s0,sp,48
    80004290:	892a                	mv	s2,a0
    80004292:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004294:	0001d497          	auipc	s1,0x1d
    80004298:	1dc48493          	addi	s1,s1,476 # 80021470 <log>
    8000429c:	00004597          	auipc	a1,0x4
    800042a0:	3d458593          	addi	a1,a1,980 # 80008670 <syscalls+0x1e8>
    800042a4:	8526                	mv	a0,s1
    800042a6:	ffffd097          	auipc	ra,0xffffd
    800042aa:	8ae080e7          	jalr	-1874(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800042ae:	0149a583          	lw	a1,20(s3)
    800042b2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042b4:	0109a783          	lw	a5,16(s3)
    800042b8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042ba:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042be:	854a                	mv	a0,s2
    800042c0:	fffff097          	auipc	ra,0xfffff
    800042c4:	e92080e7          	jalr	-366(ra) # 80003152 <bread>
  log.lh.n = lh->n;
    800042c8:	4d3c                	lw	a5,88(a0)
    800042ca:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042cc:	02f05563          	blez	a5,800042f6 <initlog+0x74>
    800042d0:	05c50713          	addi	a4,a0,92
    800042d4:	0001d697          	auipc	a3,0x1d
    800042d8:	1cc68693          	addi	a3,a3,460 # 800214a0 <log+0x30>
    800042dc:	37fd                	addiw	a5,a5,-1
    800042de:	1782                	slli	a5,a5,0x20
    800042e0:	9381                	srli	a5,a5,0x20
    800042e2:	078a                	slli	a5,a5,0x2
    800042e4:	06050613          	addi	a2,a0,96
    800042e8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800042ea:	4310                	lw	a2,0(a4)
    800042ec:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800042ee:	0711                	addi	a4,a4,4
    800042f0:	0691                	addi	a3,a3,4
    800042f2:	fef71ce3          	bne	a4,a5,800042ea <initlog+0x68>
  brelse(buf);
    800042f6:	fffff097          	auipc	ra,0xfffff
    800042fa:	f8c080e7          	jalr	-116(ra) # 80003282 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042fe:	4505                	li	a0,1
    80004300:	00000097          	auipc	ra,0x0
    80004304:	ebe080e7          	jalr	-322(ra) # 800041be <install_trans>
  log.lh.n = 0;
    80004308:	0001d797          	auipc	a5,0x1d
    8000430c:	1807aa23          	sw	zero,404(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    80004310:	00000097          	auipc	ra,0x0
    80004314:	e34080e7          	jalr	-460(ra) # 80004144 <write_head>
}
    80004318:	70a2                	ld	ra,40(sp)
    8000431a:	7402                	ld	s0,32(sp)
    8000431c:	64e2                	ld	s1,24(sp)
    8000431e:	6942                	ld	s2,16(sp)
    80004320:	69a2                	ld	s3,8(sp)
    80004322:	6145                	addi	sp,sp,48
    80004324:	8082                	ret

0000000080004326 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004326:	1101                	addi	sp,sp,-32
    80004328:	ec06                	sd	ra,24(sp)
    8000432a:	e822                	sd	s0,16(sp)
    8000432c:	e426                	sd	s1,8(sp)
    8000432e:	e04a                	sd	s2,0(sp)
    80004330:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004332:	0001d517          	auipc	a0,0x1d
    80004336:	13e50513          	addi	a0,a0,318 # 80021470 <log>
    8000433a:	ffffd097          	auipc	ra,0xffffd
    8000433e:	8aa080e7          	jalr	-1878(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004342:	0001d497          	auipc	s1,0x1d
    80004346:	12e48493          	addi	s1,s1,302 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000434a:	4979                	li	s2,30
    8000434c:	a039                	j	8000435a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000434e:	85a6                	mv	a1,s1
    80004350:	8526                	mv	a0,s1
    80004352:	ffffe097          	auipc	ra,0xffffe
    80004356:	fb4080e7          	jalr	-76(ra) # 80002306 <sleep>
    if(log.committing){
    8000435a:	50dc                	lw	a5,36(s1)
    8000435c:	fbed                	bnez	a5,8000434e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000435e:	509c                	lw	a5,32(s1)
    80004360:	0017871b          	addiw	a4,a5,1
    80004364:	0007069b          	sext.w	a3,a4
    80004368:	0027179b          	slliw	a5,a4,0x2
    8000436c:	9fb9                	addw	a5,a5,a4
    8000436e:	0017979b          	slliw	a5,a5,0x1
    80004372:	54d8                	lw	a4,44(s1)
    80004374:	9fb9                	addw	a5,a5,a4
    80004376:	00f95963          	bge	s2,a5,80004388 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000437a:	85a6                	mv	a1,s1
    8000437c:	8526                	mv	a0,s1
    8000437e:	ffffe097          	auipc	ra,0xffffe
    80004382:	f88080e7          	jalr	-120(ra) # 80002306 <sleep>
    80004386:	bfd1                	j	8000435a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004388:	0001d517          	auipc	a0,0x1d
    8000438c:	0e850513          	addi	a0,a0,232 # 80021470 <log>
    80004390:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004392:	ffffd097          	auipc	ra,0xffffd
    80004396:	906080e7          	jalr	-1786(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000439a:	60e2                	ld	ra,24(sp)
    8000439c:	6442                	ld	s0,16(sp)
    8000439e:	64a2                	ld	s1,8(sp)
    800043a0:	6902                	ld	s2,0(sp)
    800043a2:	6105                	addi	sp,sp,32
    800043a4:	8082                	ret

00000000800043a6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043a6:	7139                	addi	sp,sp,-64
    800043a8:	fc06                	sd	ra,56(sp)
    800043aa:	f822                	sd	s0,48(sp)
    800043ac:	f426                	sd	s1,40(sp)
    800043ae:	f04a                	sd	s2,32(sp)
    800043b0:	ec4e                	sd	s3,24(sp)
    800043b2:	e852                	sd	s4,16(sp)
    800043b4:	e456                	sd	s5,8(sp)
    800043b6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043b8:	0001d497          	auipc	s1,0x1d
    800043bc:	0b848493          	addi	s1,s1,184 # 80021470 <log>
    800043c0:	8526                	mv	a0,s1
    800043c2:	ffffd097          	auipc	ra,0xffffd
    800043c6:	822080e7          	jalr	-2014(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800043ca:	509c                	lw	a5,32(s1)
    800043cc:	37fd                	addiw	a5,a5,-1
    800043ce:	0007891b          	sext.w	s2,a5
    800043d2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043d4:	50dc                	lw	a5,36(s1)
    800043d6:	efb9                	bnez	a5,80004434 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043d8:	06091663          	bnez	s2,80004444 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043dc:	0001d497          	auipc	s1,0x1d
    800043e0:	09448493          	addi	s1,s1,148 # 80021470 <log>
    800043e4:	4785                	li	a5,1
    800043e6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043e8:	8526                	mv	a0,s1
    800043ea:	ffffd097          	auipc	ra,0xffffd
    800043ee:	8ae080e7          	jalr	-1874(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043f2:	54dc                	lw	a5,44(s1)
    800043f4:	06f04763          	bgtz	a5,80004462 <end_op+0xbc>
    acquire(&log.lock);
    800043f8:	0001d497          	auipc	s1,0x1d
    800043fc:	07848493          	addi	s1,s1,120 # 80021470 <log>
    80004400:	8526                	mv	a0,s1
    80004402:	ffffc097          	auipc	ra,0xffffc
    80004406:	7e2080e7          	jalr	2018(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000440a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000440e:	8526                	mv	a0,s1
    80004410:	ffffe097          	auipc	ra,0xffffe
    80004414:	082080e7          	jalr	130(ra) # 80002492 <wakeup>
    release(&log.lock);
    80004418:	8526                	mv	a0,s1
    8000441a:	ffffd097          	auipc	ra,0xffffd
    8000441e:	87e080e7          	jalr	-1922(ra) # 80000c98 <release>
}
    80004422:	70e2                	ld	ra,56(sp)
    80004424:	7442                	ld	s0,48(sp)
    80004426:	74a2                	ld	s1,40(sp)
    80004428:	7902                	ld	s2,32(sp)
    8000442a:	69e2                	ld	s3,24(sp)
    8000442c:	6a42                	ld	s4,16(sp)
    8000442e:	6aa2                	ld	s5,8(sp)
    80004430:	6121                	addi	sp,sp,64
    80004432:	8082                	ret
    panic("log.committing");
    80004434:	00004517          	auipc	a0,0x4
    80004438:	24450513          	addi	a0,a0,580 # 80008678 <syscalls+0x1f0>
    8000443c:	ffffc097          	auipc	ra,0xffffc
    80004440:	102080e7          	jalr	258(ra) # 8000053e <panic>
    wakeup(&log);
    80004444:	0001d497          	auipc	s1,0x1d
    80004448:	02c48493          	addi	s1,s1,44 # 80021470 <log>
    8000444c:	8526                	mv	a0,s1
    8000444e:	ffffe097          	auipc	ra,0xffffe
    80004452:	044080e7          	jalr	68(ra) # 80002492 <wakeup>
  release(&log.lock);
    80004456:	8526                	mv	a0,s1
    80004458:	ffffd097          	auipc	ra,0xffffd
    8000445c:	840080e7          	jalr	-1984(ra) # 80000c98 <release>
  if(do_commit){
    80004460:	b7c9                	j	80004422 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004462:	0001da97          	auipc	s5,0x1d
    80004466:	03ea8a93          	addi	s5,s5,62 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000446a:	0001da17          	auipc	s4,0x1d
    8000446e:	006a0a13          	addi	s4,s4,6 # 80021470 <log>
    80004472:	018a2583          	lw	a1,24(s4)
    80004476:	012585bb          	addw	a1,a1,s2
    8000447a:	2585                	addiw	a1,a1,1
    8000447c:	028a2503          	lw	a0,40(s4)
    80004480:	fffff097          	auipc	ra,0xfffff
    80004484:	cd2080e7          	jalr	-814(ra) # 80003152 <bread>
    80004488:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000448a:	000aa583          	lw	a1,0(s5)
    8000448e:	028a2503          	lw	a0,40(s4)
    80004492:	fffff097          	auipc	ra,0xfffff
    80004496:	cc0080e7          	jalr	-832(ra) # 80003152 <bread>
    8000449a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000449c:	40000613          	li	a2,1024
    800044a0:	05850593          	addi	a1,a0,88
    800044a4:	05848513          	addi	a0,s1,88
    800044a8:	ffffd097          	auipc	ra,0xffffd
    800044ac:	898080e7          	jalr	-1896(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800044b0:	8526                	mv	a0,s1
    800044b2:	fffff097          	auipc	ra,0xfffff
    800044b6:	d92080e7          	jalr	-622(ra) # 80003244 <bwrite>
    brelse(from);
    800044ba:	854e                	mv	a0,s3
    800044bc:	fffff097          	auipc	ra,0xfffff
    800044c0:	dc6080e7          	jalr	-570(ra) # 80003282 <brelse>
    brelse(to);
    800044c4:	8526                	mv	a0,s1
    800044c6:	fffff097          	auipc	ra,0xfffff
    800044ca:	dbc080e7          	jalr	-580(ra) # 80003282 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044ce:	2905                	addiw	s2,s2,1
    800044d0:	0a91                	addi	s5,s5,4
    800044d2:	02ca2783          	lw	a5,44(s4)
    800044d6:	f8f94ee3          	blt	s2,a5,80004472 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044da:	00000097          	auipc	ra,0x0
    800044de:	c6a080e7          	jalr	-918(ra) # 80004144 <write_head>
    install_trans(0); // Now install writes to home locations
    800044e2:	4501                	li	a0,0
    800044e4:	00000097          	auipc	ra,0x0
    800044e8:	cda080e7          	jalr	-806(ra) # 800041be <install_trans>
    log.lh.n = 0;
    800044ec:	0001d797          	auipc	a5,0x1d
    800044f0:	fa07a823          	sw	zero,-80(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044f4:	00000097          	auipc	ra,0x0
    800044f8:	c50080e7          	jalr	-944(ra) # 80004144 <write_head>
    800044fc:	bdf5                	j	800043f8 <end_op+0x52>

00000000800044fe <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044fe:	1101                	addi	sp,sp,-32
    80004500:	ec06                	sd	ra,24(sp)
    80004502:	e822                	sd	s0,16(sp)
    80004504:	e426                	sd	s1,8(sp)
    80004506:	e04a                	sd	s2,0(sp)
    80004508:	1000                	addi	s0,sp,32
    8000450a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000450c:	0001d917          	auipc	s2,0x1d
    80004510:	f6490913          	addi	s2,s2,-156 # 80021470 <log>
    80004514:	854a                	mv	a0,s2
    80004516:	ffffc097          	auipc	ra,0xffffc
    8000451a:	6ce080e7          	jalr	1742(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000451e:	02c92603          	lw	a2,44(s2)
    80004522:	47f5                	li	a5,29
    80004524:	06c7c563          	blt	a5,a2,8000458e <log_write+0x90>
    80004528:	0001d797          	auipc	a5,0x1d
    8000452c:	f647a783          	lw	a5,-156(a5) # 8002148c <log+0x1c>
    80004530:	37fd                	addiw	a5,a5,-1
    80004532:	04f65e63          	bge	a2,a5,8000458e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004536:	0001d797          	auipc	a5,0x1d
    8000453a:	f5a7a783          	lw	a5,-166(a5) # 80021490 <log+0x20>
    8000453e:	06f05063          	blez	a5,8000459e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004542:	4781                	li	a5,0
    80004544:	06c05563          	blez	a2,800045ae <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004548:	44cc                	lw	a1,12(s1)
    8000454a:	0001d717          	auipc	a4,0x1d
    8000454e:	f5670713          	addi	a4,a4,-170 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004552:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004554:	4314                	lw	a3,0(a4)
    80004556:	04b68c63          	beq	a3,a1,800045ae <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000455a:	2785                	addiw	a5,a5,1
    8000455c:	0711                	addi	a4,a4,4
    8000455e:	fef61be3          	bne	a2,a5,80004554 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004562:	0621                	addi	a2,a2,8
    80004564:	060a                	slli	a2,a2,0x2
    80004566:	0001d797          	auipc	a5,0x1d
    8000456a:	f0a78793          	addi	a5,a5,-246 # 80021470 <log>
    8000456e:	963e                	add	a2,a2,a5
    80004570:	44dc                	lw	a5,12(s1)
    80004572:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004574:	8526                	mv	a0,s1
    80004576:	fffff097          	auipc	ra,0xfffff
    8000457a:	daa080e7          	jalr	-598(ra) # 80003320 <bpin>
    log.lh.n++;
    8000457e:	0001d717          	auipc	a4,0x1d
    80004582:	ef270713          	addi	a4,a4,-270 # 80021470 <log>
    80004586:	575c                	lw	a5,44(a4)
    80004588:	2785                	addiw	a5,a5,1
    8000458a:	d75c                	sw	a5,44(a4)
    8000458c:	a835                	j	800045c8 <log_write+0xca>
    panic("too big a transaction");
    8000458e:	00004517          	auipc	a0,0x4
    80004592:	0fa50513          	addi	a0,a0,250 # 80008688 <syscalls+0x200>
    80004596:	ffffc097          	auipc	ra,0xffffc
    8000459a:	fa8080e7          	jalr	-88(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000459e:	00004517          	auipc	a0,0x4
    800045a2:	10250513          	addi	a0,a0,258 # 800086a0 <syscalls+0x218>
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	f98080e7          	jalr	-104(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800045ae:	00878713          	addi	a4,a5,8
    800045b2:	00271693          	slli	a3,a4,0x2
    800045b6:	0001d717          	auipc	a4,0x1d
    800045ba:	eba70713          	addi	a4,a4,-326 # 80021470 <log>
    800045be:	9736                	add	a4,a4,a3
    800045c0:	44d4                	lw	a3,12(s1)
    800045c2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045c4:	faf608e3          	beq	a2,a5,80004574 <log_write+0x76>
  }
  release(&log.lock);
    800045c8:	0001d517          	auipc	a0,0x1d
    800045cc:	ea850513          	addi	a0,a0,-344 # 80021470 <log>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	6c8080e7          	jalr	1736(ra) # 80000c98 <release>
}
    800045d8:	60e2                	ld	ra,24(sp)
    800045da:	6442                	ld	s0,16(sp)
    800045dc:	64a2                	ld	s1,8(sp)
    800045de:	6902                	ld	s2,0(sp)
    800045e0:	6105                	addi	sp,sp,32
    800045e2:	8082                	ret

00000000800045e4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045e4:	1101                	addi	sp,sp,-32
    800045e6:	ec06                	sd	ra,24(sp)
    800045e8:	e822                	sd	s0,16(sp)
    800045ea:	e426                	sd	s1,8(sp)
    800045ec:	e04a                	sd	s2,0(sp)
    800045ee:	1000                	addi	s0,sp,32
    800045f0:	84aa                	mv	s1,a0
    800045f2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045f4:	00004597          	auipc	a1,0x4
    800045f8:	0cc58593          	addi	a1,a1,204 # 800086c0 <syscalls+0x238>
    800045fc:	0521                	addi	a0,a0,8
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	556080e7          	jalr	1366(ra) # 80000b54 <initlock>
  lk->name = name;
    80004606:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000460a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000460e:	0204a423          	sw	zero,40(s1)
}
    80004612:	60e2                	ld	ra,24(sp)
    80004614:	6442                	ld	s0,16(sp)
    80004616:	64a2                	ld	s1,8(sp)
    80004618:	6902                	ld	s2,0(sp)
    8000461a:	6105                	addi	sp,sp,32
    8000461c:	8082                	ret

000000008000461e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000461e:	1101                	addi	sp,sp,-32
    80004620:	ec06                	sd	ra,24(sp)
    80004622:	e822                	sd	s0,16(sp)
    80004624:	e426                	sd	s1,8(sp)
    80004626:	e04a                	sd	s2,0(sp)
    80004628:	1000                	addi	s0,sp,32
    8000462a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000462c:	00850913          	addi	s2,a0,8
    80004630:	854a                	mv	a0,s2
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	5b2080e7          	jalr	1458(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000463a:	409c                	lw	a5,0(s1)
    8000463c:	cb89                	beqz	a5,8000464e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000463e:	85ca                	mv	a1,s2
    80004640:	8526                	mv	a0,s1
    80004642:	ffffe097          	auipc	ra,0xffffe
    80004646:	cc4080e7          	jalr	-828(ra) # 80002306 <sleep>
  while (lk->locked) {
    8000464a:	409c                	lw	a5,0(s1)
    8000464c:	fbed                	bnez	a5,8000463e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000464e:	4785                	li	a5,1
    80004650:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004652:	ffffd097          	auipc	ra,0xffffd
    80004656:	372080e7          	jalr	882(ra) # 800019c4 <myproc>
    8000465a:	591c                	lw	a5,48(a0)
    8000465c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000465e:	854a                	mv	a0,s2
    80004660:	ffffc097          	auipc	ra,0xffffc
    80004664:	638080e7          	jalr	1592(ra) # 80000c98 <release>
}
    80004668:	60e2                	ld	ra,24(sp)
    8000466a:	6442                	ld	s0,16(sp)
    8000466c:	64a2                	ld	s1,8(sp)
    8000466e:	6902                	ld	s2,0(sp)
    80004670:	6105                	addi	sp,sp,32
    80004672:	8082                	ret

0000000080004674 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004674:	1101                	addi	sp,sp,-32
    80004676:	ec06                	sd	ra,24(sp)
    80004678:	e822                	sd	s0,16(sp)
    8000467a:	e426                	sd	s1,8(sp)
    8000467c:	e04a                	sd	s2,0(sp)
    8000467e:	1000                	addi	s0,sp,32
    80004680:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004682:	00850913          	addi	s2,a0,8
    80004686:	854a                	mv	a0,s2
    80004688:	ffffc097          	auipc	ra,0xffffc
    8000468c:	55c080e7          	jalr	1372(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004690:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004694:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004698:	8526                	mv	a0,s1
    8000469a:	ffffe097          	auipc	ra,0xffffe
    8000469e:	df8080e7          	jalr	-520(ra) # 80002492 <wakeup>
  release(&lk->lk);
    800046a2:	854a                	mv	a0,s2
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	5f4080e7          	jalr	1524(ra) # 80000c98 <release>
}
    800046ac:	60e2                	ld	ra,24(sp)
    800046ae:	6442                	ld	s0,16(sp)
    800046b0:	64a2                	ld	s1,8(sp)
    800046b2:	6902                	ld	s2,0(sp)
    800046b4:	6105                	addi	sp,sp,32
    800046b6:	8082                	ret

00000000800046b8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046b8:	7179                	addi	sp,sp,-48
    800046ba:	f406                	sd	ra,40(sp)
    800046bc:	f022                	sd	s0,32(sp)
    800046be:	ec26                	sd	s1,24(sp)
    800046c0:	e84a                	sd	s2,16(sp)
    800046c2:	e44e                	sd	s3,8(sp)
    800046c4:	1800                	addi	s0,sp,48
    800046c6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046c8:	00850913          	addi	s2,a0,8
    800046cc:	854a                	mv	a0,s2
    800046ce:	ffffc097          	auipc	ra,0xffffc
    800046d2:	516080e7          	jalr	1302(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046d6:	409c                	lw	a5,0(s1)
    800046d8:	ef99                	bnez	a5,800046f6 <holdingsleep+0x3e>
    800046da:	4481                	li	s1,0
  release(&lk->lk);
    800046dc:	854a                	mv	a0,s2
    800046de:	ffffc097          	auipc	ra,0xffffc
    800046e2:	5ba080e7          	jalr	1466(ra) # 80000c98 <release>
  return r;
}
    800046e6:	8526                	mv	a0,s1
    800046e8:	70a2                	ld	ra,40(sp)
    800046ea:	7402                	ld	s0,32(sp)
    800046ec:	64e2                	ld	s1,24(sp)
    800046ee:	6942                	ld	s2,16(sp)
    800046f0:	69a2                	ld	s3,8(sp)
    800046f2:	6145                	addi	sp,sp,48
    800046f4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046f6:	0284a983          	lw	s3,40(s1)
    800046fa:	ffffd097          	auipc	ra,0xffffd
    800046fe:	2ca080e7          	jalr	714(ra) # 800019c4 <myproc>
    80004702:	5904                	lw	s1,48(a0)
    80004704:	413484b3          	sub	s1,s1,s3
    80004708:	0014b493          	seqz	s1,s1
    8000470c:	bfc1                	j	800046dc <holdingsleep+0x24>

000000008000470e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000470e:	1141                	addi	sp,sp,-16
    80004710:	e406                	sd	ra,8(sp)
    80004712:	e022                	sd	s0,0(sp)
    80004714:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004716:	00004597          	auipc	a1,0x4
    8000471a:	fba58593          	addi	a1,a1,-70 # 800086d0 <syscalls+0x248>
    8000471e:	0001d517          	auipc	a0,0x1d
    80004722:	e9a50513          	addi	a0,a0,-358 # 800215b8 <ftable>
    80004726:	ffffc097          	auipc	ra,0xffffc
    8000472a:	42e080e7          	jalr	1070(ra) # 80000b54 <initlock>
}
    8000472e:	60a2                	ld	ra,8(sp)
    80004730:	6402                	ld	s0,0(sp)
    80004732:	0141                	addi	sp,sp,16
    80004734:	8082                	ret

0000000080004736 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004736:	1101                	addi	sp,sp,-32
    80004738:	ec06                	sd	ra,24(sp)
    8000473a:	e822                	sd	s0,16(sp)
    8000473c:	e426                	sd	s1,8(sp)
    8000473e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004740:	0001d517          	auipc	a0,0x1d
    80004744:	e7850513          	addi	a0,a0,-392 # 800215b8 <ftable>
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	49c080e7          	jalr	1180(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004750:	0001d497          	auipc	s1,0x1d
    80004754:	e8048493          	addi	s1,s1,-384 # 800215d0 <ftable+0x18>
    80004758:	0001e717          	auipc	a4,0x1e
    8000475c:	e1870713          	addi	a4,a4,-488 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    80004760:	40dc                	lw	a5,4(s1)
    80004762:	cf99                	beqz	a5,80004780 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004764:	02848493          	addi	s1,s1,40
    80004768:	fee49ce3          	bne	s1,a4,80004760 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000476c:	0001d517          	auipc	a0,0x1d
    80004770:	e4c50513          	addi	a0,a0,-436 # 800215b8 <ftable>
    80004774:	ffffc097          	auipc	ra,0xffffc
    80004778:	524080e7          	jalr	1316(ra) # 80000c98 <release>
  return 0;
    8000477c:	4481                	li	s1,0
    8000477e:	a819                	j	80004794 <filealloc+0x5e>
      f->ref = 1;
    80004780:	4785                	li	a5,1
    80004782:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004784:	0001d517          	auipc	a0,0x1d
    80004788:	e3450513          	addi	a0,a0,-460 # 800215b8 <ftable>
    8000478c:	ffffc097          	auipc	ra,0xffffc
    80004790:	50c080e7          	jalr	1292(ra) # 80000c98 <release>
}
    80004794:	8526                	mv	a0,s1
    80004796:	60e2                	ld	ra,24(sp)
    80004798:	6442                	ld	s0,16(sp)
    8000479a:	64a2                	ld	s1,8(sp)
    8000479c:	6105                	addi	sp,sp,32
    8000479e:	8082                	ret

00000000800047a0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047a0:	1101                	addi	sp,sp,-32
    800047a2:	ec06                	sd	ra,24(sp)
    800047a4:	e822                	sd	s0,16(sp)
    800047a6:	e426                	sd	s1,8(sp)
    800047a8:	1000                	addi	s0,sp,32
    800047aa:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047ac:	0001d517          	auipc	a0,0x1d
    800047b0:	e0c50513          	addi	a0,a0,-500 # 800215b8 <ftable>
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	430080e7          	jalr	1072(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800047bc:	40dc                	lw	a5,4(s1)
    800047be:	02f05263          	blez	a5,800047e2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047c2:	2785                	addiw	a5,a5,1
    800047c4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047c6:	0001d517          	auipc	a0,0x1d
    800047ca:	df250513          	addi	a0,a0,-526 # 800215b8 <ftable>
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	4ca080e7          	jalr	1226(ra) # 80000c98 <release>
  return f;
}
    800047d6:	8526                	mv	a0,s1
    800047d8:	60e2                	ld	ra,24(sp)
    800047da:	6442                	ld	s0,16(sp)
    800047dc:	64a2                	ld	s1,8(sp)
    800047de:	6105                	addi	sp,sp,32
    800047e0:	8082                	ret
    panic("filedup");
    800047e2:	00004517          	auipc	a0,0x4
    800047e6:	ef650513          	addi	a0,a0,-266 # 800086d8 <syscalls+0x250>
    800047ea:	ffffc097          	auipc	ra,0xffffc
    800047ee:	d54080e7          	jalr	-684(ra) # 8000053e <panic>

00000000800047f2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047f2:	7139                	addi	sp,sp,-64
    800047f4:	fc06                	sd	ra,56(sp)
    800047f6:	f822                	sd	s0,48(sp)
    800047f8:	f426                	sd	s1,40(sp)
    800047fa:	f04a                	sd	s2,32(sp)
    800047fc:	ec4e                	sd	s3,24(sp)
    800047fe:	e852                	sd	s4,16(sp)
    80004800:	e456                	sd	s5,8(sp)
    80004802:	0080                	addi	s0,sp,64
    80004804:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004806:	0001d517          	auipc	a0,0x1d
    8000480a:	db250513          	addi	a0,a0,-590 # 800215b8 <ftable>
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	3d6080e7          	jalr	982(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004816:	40dc                	lw	a5,4(s1)
    80004818:	06f05163          	blez	a5,8000487a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000481c:	37fd                	addiw	a5,a5,-1
    8000481e:	0007871b          	sext.w	a4,a5
    80004822:	c0dc                	sw	a5,4(s1)
    80004824:	06e04363          	bgtz	a4,8000488a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004828:	0004a903          	lw	s2,0(s1)
    8000482c:	0094ca83          	lbu	s5,9(s1)
    80004830:	0104ba03          	ld	s4,16(s1)
    80004834:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004838:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000483c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004840:	0001d517          	auipc	a0,0x1d
    80004844:	d7850513          	addi	a0,a0,-648 # 800215b8 <ftable>
    80004848:	ffffc097          	auipc	ra,0xffffc
    8000484c:	450080e7          	jalr	1104(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004850:	4785                	li	a5,1
    80004852:	04f90d63          	beq	s2,a5,800048ac <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004856:	3979                	addiw	s2,s2,-2
    80004858:	4785                	li	a5,1
    8000485a:	0527e063          	bltu	a5,s2,8000489a <fileclose+0xa8>
    begin_op();
    8000485e:	00000097          	auipc	ra,0x0
    80004862:	ac8080e7          	jalr	-1336(ra) # 80004326 <begin_op>
    iput(ff.ip);
    80004866:	854e                	mv	a0,s3
    80004868:	fffff097          	auipc	ra,0xfffff
    8000486c:	2a6080e7          	jalr	678(ra) # 80003b0e <iput>
    end_op();
    80004870:	00000097          	auipc	ra,0x0
    80004874:	b36080e7          	jalr	-1226(ra) # 800043a6 <end_op>
    80004878:	a00d                	j	8000489a <fileclose+0xa8>
    panic("fileclose");
    8000487a:	00004517          	auipc	a0,0x4
    8000487e:	e6650513          	addi	a0,a0,-410 # 800086e0 <syscalls+0x258>
    80004882:	ffffc097          	auipc	ra,0xffffc
    80004886:	cbc080e7          	jalr	-836(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000488a:	0001d517          	auipc	a0,0x1d
    8000488e:	d2e50513          	addi	a0,a0,-722 # 800215b8 <ftable>
    80004892:	ffffc097          	auipc	ra,0xffffc
    80004896:	406080e7          	jalr	1030(ra) # 80000c98 <release>
  }
}
    8000489a:	70e2                	ld	ra,56(sp)
    8000489c:	7442                	ld	s0,48(sp)
    8000489e:	74a2                	ld	s1,40(sp)
    800048a0:	7902                	ld	s2,32(sp)
    800048a2:	69e2                	ld	s3,24(sp)
    800048a4:	6a42                	ld	s4,16(sp)
    800048a6:	6aa2                	ld	s5,8(sp)
    800048a8:	6121                	addi	sp,sp,64
    800048aa:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048ac:	85d6                	mv	a1,s5
    800048ae:	8552                	mv	a0,s4
    800048b0:	00000097          	auipc	ra,0x0
    800048b4:	34c080e7          	jalr	844(ra) # 80004bfc <pipeclose>
    800048b8:	b7cd                	j	8000489a <fileclose+0xa8>

00000000800048ba <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048ba:	715d                	addi	sp,sp,-80
    800048bc:	e486                	sd	ra,72(sp)
    800048be:	e0a2                	sd	s0,64(sp)
    800048c0:	fc26                	sd	s1,56(sp)
    800048c2:	f84a                	sd	s2,48(sp)
    800048c4:	f44e                	sd	s3,40(sp)
    800048c6:	0880                	addi	s0,sp,80
    800048c8:	84aa                	mv	s1,a0
    800048ca:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048cc:	ffffd097          	auipc	ra,0xffffd
    800048d0:	0f8080e7          	jalr	248(ra) # 800019c4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048d4:	409c                	lw	a5,0(s1)
    800048d6:	37f9                	addiw	a5,a5,-2
    800048d8:	4705                	li	a4,1
    800048da:	04f76763          	bltu	a4,a5,80004928 <filestat+0x6e>
    800048de:	892a                	mv	s2,a0
    ilock(f->ip);
    800048e0:	6c88                	ld	a0,24(s1)
    800048e2:	fffff097          	auipc	ra,0xfffff
    800048e6:	072080e7          	jalr	114(ra) # 80003954 <ilock>
    stati(f->ip, &st);
    800048ea:	fb840593          	addi	a1,s0,-72
    800048ee:	6c88                	ld	a0,24(s1)
    800048f0:	fffff097          	auipc	ra,0xfffff
    800048f4:	2ee080e7          	jalr	750(ra) # 80003bde <stati>
    iunlock(f->ip);
    800048f8:	6c88                	ld	a0,24(s1)
    800048fa:	fffff097          	auipc	ra,0xfffff
    800048fe:	11c080e7          	jalr	284(ra) # 80003a16 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004902:	46e1                	li	a3,24
    80004904:	fb840613          	addi	a2,s0,-72
    80004908:	85ce                	mv	a1,s3
    8000490a:	05893503          	ld	a0,88(s2)
    8000490e:	ffffd097          	auipc	ra,0xffffd
    80004912:	d6c080e7          	jalr	-660(ra) # 8000167a <copyout>
    80004916:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000491a:	60a6                	ld	ra,72(sp)
    8000491c:	6406                	ld	s0,64(sp)
    8000491e:	74e2                	ld	s1,56(sp)
    80004920:	7942                	ld	s2,48(sp)
    80004922:	79a2                	ld	s3,40(sp)
    80004924:	6161                	addi	sp,sp,80
    80004926:	8082                	ret
  return -1;
    80004928:	557d                	li	a0,-1
    8000492a:	bfc5                	j	8000491a <filestat+0x60>

000000008000492c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000492c:	7179                	addi	sp,sp,-48
    8000492e:	f406                	sd	ra,40(sp)
    80004930:	f022                	sd	s0,32(sp)
    80004932:	ec26                	sd	s1,24(sp)
    80004934:	e84a                	sd	s2,16(sp)
    80004936:	e44e                	sd	s3,8(sp)
    80004938:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000493a:	00854783          	lbu	a5,8(a0)
    8000493e:	c3d5                	beqz	a5,800049e2 <fileread+0xb6>
    80004940:	84aa                	mv	s1,a0
    80004942:	89ae                	mv	s3,a1
    80004944:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004946:	411c                	lw	a5,0(a0)
    80004948:	4705                	li	a4,1
    8000494a:	04e78963          	beq	a5,a4,8000499c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000494e:	470d                	li	a4,3
    80004950:	04e78d63          	beq	a5,a4,800049aa <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004954:	4709                	li	a4,2
    80004956:	06e79e63          	bne	a5,a4,800049d2 <fileread+0xa6>
    ilock(f->ip);
    8000495a:	6d08                	ld	a0,24(a0)
    8000495c:	fffff097          	auipc	ra,0xfffff
    80004960:	ff8080e7          	jalr	-8(ra) # 80003954 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004964:	874a                	mv	a4,s2
    80004966:	5094                	lw	a3,32(s1)
    80004968:	864e                	mv	a2,s3
    8000496a:	4585                	li	a1,1
    8000496c:	6c88                	ld	a0,24(s1)
    8000496e:	fffff097          	auipc	ra,0xfffff
    80004972:	29a080e7          	jalr	666(ra) # 80003c08 <readi>
    80004976:	892a                	mv	s2,a0
    80004978:	00a05563          	blez	a0,80004982 <fileread+0x56>
      f->off += r;
    8000497c:	509c                	lw	a5,32(s1)
    8000497e:	9fa9                	addw	a5,a5,a0
    80004980:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004982:	6c88                	ld	a0,24(s1)
    80004984:	fffff097          	auipc	ra,0xfffff
    80004988:	092080e7          	jalr	146(ra) # 80003a16 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000498c:	854a                	mv	a0,s2
    8000498e:	70a2                	ld	ra,40(sp)
    80004990:	7402                	ld	s0,32(sp)
    80004992:	64e2                	ld	s1,24(sp)
    80004994:	6942                	ld	s2,16(sp)
    80004996:	69a2                	ld	s3,8(sp)
    80004998:	6145                	addi	sp,sp,48
    8000499a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000499c:	6908                	ld	a0,16(a0)
    8000499e:	00000097          	auipc	ra,0x0
    800049a2:	3c8080e7          	jalr	968(ra) # 80004d66 <piperead>
    800049a6:	892a                	mv	s2,a0
    800049a8:	b7d5                	j	8000498c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049aa:	02451783          	lh	a5,36(a0)
    800049ae:	03079693          	slli	a3,a5,0x30
    800049b2:	92c1                	srli	a3,a3,0x30
    800049b4:	4725                	li	a4,9
    800049b6:	02d76863          	bltu	a4,a3,800049e6 <fileread+0xba>
    800049ba:	0792                	slli	a5,a5,0x4
    800049bc:	0001d717          	auipc	a4,0x1d
    800049c0:	b5c70713          	addi	a4,a4,-1188 # 80021518 <devsw>
    800049c4:	97ba                	add	a5,a5,a4
    800049c6:	639c                	ld	a5,0(a5)
    800049c8:	c38d                	beqz	a5,800049ea <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049ca:	4505                	li	a0,1
    800049cc:	9782                	jalr	a5
    800049ce:	892a                	mv	s2,a0
    800049d0:	bf75                	j	8000498c <fileread+0x60>
    panic("fileread");
    800049d2:	00004517          	auipc	a0,0x4
    800049d6:	d1e50513          	addi	a0,a0,-738 # 800086f0 <syscalls+0x268>
    800049da:	ffffc097          	auipc	ra,0xffffc
    800049de:	b64080e7          	jalr	-1180(ra) # 8000053e <panic>
    return -1;
    800049e2:	597d                	li	s2,-1
    800049e4:	b765                	j	8000498c <fileread+0x60>
      return -1;
    800049e6:	597d                	li	s2,-1
    800049e8:	b755                	j	8000498c <fileread+0x60>
    800049ea:	597d                	li	s2,-1
    800049ec:	b745                	j	8000498c <fileread+0x60>

00000000800049ee <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800049ee:	715d                	addi	sp,sp,-80
    800049f0:	e486                	sd	ra,72(sp)
    800049f2:	e0a2                	sd	s0,64(sp)
    800049f4:	fc26                	sd	s1,56(sp)
    800049f6:	f84a                	sd	s2,48(sp)
    800049f8:	f44e                	sd	s3,40(sp)
    800049fa:	f052                	sd	s4,32(sp)
    800049fc:	ec56                	sd	s5,24(sp)
    800049fe:	e85a                	sd	s6,16(sp)
    80004a00:	e45e                	sd	s7,8(sp)
    80004a02:	e062                	sd	s8,0(sp)
    80004a04:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a06:	00954783          	lbu	a5,9(a0)
    80004a0a:	10078663          	beqz	a5,80004b16 <filewrite+0x128>
    80004a0e:	892a                	mv	s2,a0
    80004a10:	8aae                	mv	s5,a1
    80004a12:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a14:	411c                	lw	a5,0(a0)
    80004a16:	4705                	li	a4,1
    80004a18:	02e78263          	beq	a5,a4,80004a3c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a1c:	470d                	li	a4,3
    80004a1e:	02e78663          	beq	a5,a4,80004a4a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a22:	4709                	li	a4,2
    80004a24:	0ee79163          	bne	a5,a4,80004b06 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a28:	0ac05d63          	blez	a2,80004ae2 <filewrite+0xf4>
    int i = 0;
    80004a2c:	4981                	li	s3,0
    80004a2e:	6b05                	lui	s6,0x1
    80004a30:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a34:	6b85                	lui	s7,0x1
    80004a36:	c00b8b9b          	addiw	s7,s7,-1024
    80004a3a:	a861                	j	80004ad2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a3c:	6908                	ld	a0,16(a0)
    80004a3e:	00000097          	auipc	ra,0x0
    80004a42:	22e080e7          	jalr	558(ra) # 80004c6c <pipewrite>
    80004a46:	8a2a                	mv	s4,a0
    80004a48:	a045                	j	80004ae8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a4a:	02451783          	lh	a5,36(a0)
    80004a4e:	03079693          	slli	a3,a5,0x30
    80004a52:	92c1                	srli	a3,a3,0x30
    80004a54:	4725                	li	a4,9
    80004a56:	0cd76263          	bltu	a4,a3,80004b1a <filewrite+0x12c>
    80004a5a:	0792                	slli	a5,a5,0x4
    80004a5c:	0001d717          	auipc	a4,0x1d
    80004a60:	abc70713          	addi	a4,a4,-1348 # 80021518 <devsw>
    80004a64:	97ba                	add	a5,a5,a4
    80004a66:	679c                	ld	a5,8(a5)
    80004a68:	cbdd                	beqz	a5,80004b1e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a6a:	4505                	li	a0,1
    80004a6c:	9782                	jalr	a5
    80004a6e:	8a2a                	mv	s4,a0
    80004a70:	a8a5                	j	80004ae8 <filewrite+0xfa>
    80004a72:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a76:	00000097          	auipc	ra,0x0
    80004a7a:	8b0080e7          	jalr	-1872(ra) # 80004326 <begin_op>
      ilock(f->ip);
    80004a7e:	01893503          	ld	a0,24(s2)
    80004a82:	fffff097          	auipc	ra,0xfffff
    80004a86:	ed2080e7          	jalr	-302(ra) # 80003954 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a8a:	8762                	mv	a4,s8
    80004a8c:	02092683          	lw	a3,32(s2)
    80004a90:	01598633          	add	a2,s3,s5
    80004a94:	4585                	li	a1,1
    80004a96:	01893503          	ld	a0,24(s2)
    80004a9a:	fffff097          	auipc	ra,0xfffff
    80004a9e:	266080e7          	jalr	614(ra) # 80003d00 <writei>
    80004aa2:	84aa                	mv	s1,a0
    80004aa4:	00a05763          	blez	a0,80004ab2 <filewrite+0xc4>
        f->off += r;
    80004aa8:	02092783          	lw	a5,32(s2)
    80004aac:	9fa9                	addw	a5,a5,a0
    80004aae:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ab2:	01893503          	ld	a0,24(s2)
    80004ab6:	fffff097          	auipc	ra,0xfffff
    80004aba:	f60080e7          	jalr	-160(ra) # 80003a16 <iunlock>
      end_op();
    80004abe:	00000097          	auipc	ra,0x0
    80004ac2:	8e8080e7          	jalr	-1816(ra) # 800043a6 <end_op>

      if(r != n1){
    80004ac6:	009c1f63          	bne	s8,s1,80004ae4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004aca:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ace:	0149db63          	bge	s3,s4,80004ae4 <filewrite+0xf6>
      int n1 = n - i;
    80004ad2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ad6:	84be                	mv	s1,a5
    80004ad8:	2781                	sext.w	a5,a5
    80004ada:	f8fb5ce3          	bge	s6,a5,80004a72 <filewrite+0x84>
    80004ade:	84de                	mv	s1,s7
    80004ae0:	bf49                	j	80004a72 <filewrite+0x84>
    int i = 0;
    80004ae2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ae4:	013a1f63          	bne	s4,s3,80004b02 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ae8:	8552                	mv	a0,s4
    80004aea:	60a6                	ld	ra,72(sp)
    80004aec:	6406                	ld	s0,64(sp)
    80004aee:	74e2                	ld	s1,56(sp)
    80004af0:	7942                	ld	s2,48(sp)
    80004af2:	79a2                	ld	s3,40(sp)
    80004af4:	7a02                	ld	s4,32(sp)
    80004af6:	6ae2                	ld	s5,24(sp)
    80004af8:	6b42                	ld	s6,16(sp)
    80004afa:	6ba2                	ld	s7,8(sp)
    80004afc:	6c02                	ld	s8,0(sp)
    80004afe:	6161                	addi	sp,sp,80
    80004b00:	8082                	ret
    ret = (i == n ? n : -1);
    80004b02:	5a7d                	li	s4,-1
    80004b04:	b7d5                	j	80004ae8 <filewrite+0xfa>
    panic("filewrite");
    80004b06:	00004517          	auipc	a0,0x4
    80004b0a:	bfa50513          	addi	a0,a0,-1030 # 80008700 <syscalls+0x278>
    80004b0e:	ffffc097          	auipc	ra,0xffffc
    80004b12:	a30080e7          	jalr	-1488(ra) # 8000053e <panic>
    return -1;
    80004b16:	5a7d                	li	s4,-1
    80004b18:	bfc1                	j	80004ae8 <filewrite+0xfa>
      return -1;
    80004b1a:	5a7d                	li	s4,-1
    80004b1c:	b7f1                	j	80004ae8 <filewrite+0xfa>
    80004b1e:	5a7d                	li	s4,-1
    80004b20:	b7e1                	j	80004ae8 <filewrite+0xfa>

0000000080004b22 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b22:	7179                	addi	sp,sp,-48
    80004b24:	f406                	sd	ra,40(sp)
    80004b26:	f022                	sd	s0,32(sp)
    80004b28:	ec26                	sd	s1,24(sp)
    80004b2a:	e84a                	sd	s2,16(sp)
    80004b2c:	e44e                	sd	s3,8(sp)
    80004b2e:	e052                	sd	s4,0(sp)
    80004b30:	1800                	addi	s0,sp,48
    80004b32:	84aa                	mv	s1,a0
    80004b34:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b36:	0005b023          	sd	zero,0(a1)
    80004b3a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b3e:	00000097          	auipc	ra,0x0
    80004b42:	bf8080e7          	jalr	-1032(ra) # 80004736 <filealloc>
    80004b46:	e088                	sd	a0,0(s1)
    80004b48:	c551                	beqz	a0,80004bd4 <pipealloc+0xb2>
    80004b4a:	00000097          	auipc	ra,0x0
    80004b4e:	bec080e7          	jalr	-1044(ra) # 80004736 <filealloc>
    80004b52:	00aa3023          	sd	a0,0(s4)
    80004b56:	c92d                	beqz	a0,80004bc8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b58:	ffffc097          	auipc	ra,0xffffc
    80004b5c:	f9c080e7          	jalr	-100(ra) # 80000af4 <kalloc>
    80004b60:	892a                	mv	s2,a0
    80004b62:	c125                	beqz	a0,80004bc2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b64:	4985                	li	s3,1
    80004b66:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b6a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b6e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b72:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b76:	00004597          	auipc	a1,0x4
    80004b7a:	b9a58593          	addi	a1,a1,-1126 # 80008710 <syscalls+0x288>
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	fd6080e7          	jalr	-42(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004b86:	609c                	ld	a5,0(s1)
    80004b88:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b8c:	609c                	ld	a5,0(s1)
    80004b8e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b92:	609c                	ld	a5,0(s1)
    80004b94:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b98:	609c                	ld	a5,0(s1)
    80004b9a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b9e:	000a3783          	ld	a5,0(s4)
    80004ba2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ba6:	000a3783          	ld	a5,0(s4)
    80004baa:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bae:	000a3783          	ld	a5,0(s4)
    80004bb2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bb6:	000a3783          	ld	a5,0(s4)
    80004bba:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bbe:	4501                	li	a0,0
    80004bc0:	a025                	j	80004be8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bc2:	6088                	ld	a0,0(s1)
    80004bc4:	e501                	bnez	a0,80004bcc <pipealloc+0xaa>
    80004bc6:	a039                	j	80004bd4 <pipealloc+0xb2>
    80004bc8:	6088                	ld	a0,0(s1)
    80004bca:	c51d                	beqz	a0,80004bf8 <pipealloc+0xd6>
    fileclose(*f0);
    80004bcc:	00000097          	auipc	ra,0x0
    80004bd0:	c26080e7          	jalr	-986(ra) # 800047f2 <fileclose>
  if(*f1)
    80004bd4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bd8:	557d                	li	a0,-1
  if(*f1)
    80004bda:	c799                	beqz	a5,80004be8 <pipealloc+0xc6>
    fileclose(*f1);
    80004bdc:	853e                	mv	a0,a5
    80004bde:	00000097          	auipc	ra,0x0
    80004be2:	c14080e7          	jalr	-1004(ra) # 800047f2 <fileclose>
  return -1;
    80004be6:	557d                	li	a0,-1
}
    80004be8:	70a2                	ld	ra,40(sp)
    80004bea:	7402                	ld	s0,32(sp)
    80004bec:	64e2                	ld	s1,24(sp)
    80004bee:	6942                	ld	s2,16(sp)
    80004bf0:	69a2                	ld	s3,8(sp)
    80004bf2:	6a02                	ld	s4,0(sp)
    80004bf4:	6145                	addi	sp,sp,48
    80004bf6:	8082                	ret
  return -1;
    80004bf8:	557d                	li	a0,-1
    80004bfa:	b7fd                	j	80004be8 <pipealloc+0xc6>

0000000080004bfc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bfc:	1101                	addi	sp,sp,-32
    80004bfe:	ec06                	sd	ra,24(sp)
    80004c00:	e822                	sd	s0,16(sp)
    80004c02:	e426                	sd	s1,8(sp)
    80004c04:	e04a                	sd	s2,0(sp)
    80004c06:	1000                	addi	s0,sp,32
    80004c08:	84aa                	mv	s1,a0
    80004c0a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c0c:	ffffc097          	auipc	ra,0xffffc
    80004c10:	fd8080e7          	jalr	-40(ra) # 80000be4 <acquire>
  if(writable){
    80004c14:	02090d63          	beqz	s2,80004c4e <pipeclose+0x52>
    pi->writeopen = 0;
    80004c18:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c1c:	21848513          	addi	a0,s1,536
    80004c20:	ffffe097          	auipc	ra,0xffffe
    80004c24:	872080e7          	jalr	-1934(ra) # 80002492 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c28:	2204b783          	ld	a5,544(s1)
    80004c2c:	eb95                	bnez	a5,80004c60 <pipeclose+0x64>
    release(&pi->lock);
    80004c2e:	8526                	mv	a0,s1
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	068080e7          	jalr	104(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004c38:	8526                	mv	a0,s1
    80004c3a:	ffffc097          	auipc	ra,0xffffc
    80004c3e:	dbe080e7          	jalr	-578(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004c42:	60e2                	ld	ra,24(sp)
    80004c44:	6442                	ld	s0,16(sp)
    80004c46:	64a2                	ld	s1,8(sp)
    80004c48:	6902                	ld	s2,0(sp)
    80004c4a:	6105                	addi	sp,sp,32
    80004c4c:	8082                	ret
    pi->readopen = 0;
    80004c4e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c52:	21c48513          	addi	a0,s1,540
    80004c56:	ffffe097          	auipc	ra,0xffffe
    80004c5a:	83c080e7          	jalr	-1988(ra) # 80002492 <wakeup>
    80004c5e:	b7e9                	j	80004c28 <pipeclose+0x2c>
    release(&pi->lock);
    80004c60:	8526                	mv	a0,s1
    80004c62:	ffffc097          	auipc	ra,0xffffc
    80004c66:	036080e7          	jalr	54(ra) # 80000c98 <release>
}
    80004c6a:	bfe1                	j	80004c42 <pipeclose+0x46>

0000000080004c6c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c6c:	7159                	addi	sp,sp,-112
    80004c6e:	f486                	sd	ra,104(sp)
    80004c70:	f0a2                	sd	s0,96(sp)
    80004c72:	eca6                	sd	s1,88(sp)
    80004c74:	e8ca                	sd	s2,80(sp)
    80004c76:	e4ce                	sd	s3,72(sp)
    80004c78:	e0d2                	sd	s4,64(sp)
    80004c7a:	fc56                	sd	s5,56(sp)
    80004c7c:	f85a                	sd	s6,48(sp)
    80004c7e:	f45e                	sd	s7,40(sp)
    80004c80:	f062                	sd	s8,32(sp)
    80004c82:	ec66                	sd	s9,24(sp)
    80004c84:	1880                	addi	s0,sp,112
    80004c86:	84aa                	mv	s1,a0
    80004c88:	8aae                	mv	s5,a1
    80004c8a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c8c:	ffffd097          	auipc	ra,0xffffd
    80004c90:	d38080e7          	jalr	-712(ra) # 800019c4 <myproc>
    80004c94:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c96:	8526                	mv	a0,s1
    80004c98:	ffffc097          	auipc	ra,0xffffc
    80004c9c:	f4c080e7          	jalr	-180(ra) # 80000be4 <acquire>
  while(i < n){
    80004ca0:	0d405163          	blez	s4,80004d62 <pipewrite+0xf6>
    80004ca4:	8ba6                	mv	s7,s1
  int i = 0;
    80004ca6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ca8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004caa:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cae:	21c48c13          	addi	s8,s1,540
    80004cb2:	a08d                	j	80004d14 <pipewrite+0xa8>
      release(&pi->lock);
    80004cb4:	8526                	mv	a0,s1
    80004cb6:	ffffc097          	auipc	ra,0xffffc
    80004cba:	fe2080e7          	jalr	-30(ra) # 80000c98 <release>
      return -1;
    80004cbe:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004cc0:	854a                	mv	a0,s2
    80004cc2:	70a6                	ld	ra,104(sp)
    80004cc4:	7406                	ld	s0,96(sp)
    80004cc6:	64e6                	ld	s1,88(sp)
    80004cc8:	6946                	ld	s2,80(sp)
    80004cca:	69a6                	ld	s3,72(sp)
    80004ccc:	6a06                	ld	s4,64(sp)
    80004cce:	7ae2                	ld	s5,56(sp)
    80004cd0:	7b42                	ld	s6,48(sp)
    80004cd2:	7ba2                	ld	s7,40(sp)
    80004cd4:	7c02                	ld	s8,32(sp)
    80004cd6:	6ce2                	ld	s9,24(sp)
    80004cd8:	6165                	addi	sp,sp,112
    80004cda:	8082                	ret
      wakeup(&pi->nread);
    80004cdc:	8566                	mv	a0,s9
    80004cde:	ffffd097          	auipc	ra,0xffffd
    80004ce2:	7b4080e7          	jalr	1972(ra) # 80002492 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ce6:	85de                	mv	a1,s7
    80004ce8:	8562                	mv	a0,s8
    80004cea:	ffffd097          	auipc	ra,0xffffd
    80004cee:	61c080e7          	jalr	1564(ra) # 80002306 <sleep>
    80004cf2:	a839                	j	80004d10 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cf4:	21c4a783          	lw	a5,540(s1)
    80004cf8:	0017871b          	addiw	a4,a5,1
    80004cfc:	20e4ae23          	sw	a4,540(s1)
    80004d00:	1ff7f793          	andi	a5,a5,511
    80004d04:	97a6                	add	a5,a5,s1
    80004d06:	f9f44703          	lbu	a4,-97(s0)
    80004d0a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d0e:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d10:	03495d63          	bge	s2,s4,80004d4a <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004d14:	2204a783          	lw	a5,544(s1)
    80004d18:	dfd1                	beqz	a5,80004cb4 <pipewrite+0x48>
    80004d1a:	0289a783          	lw	a5,40(s3)
    80004d1e:	fbd9                	bnez	a5,80004cb4 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d20:	2184a783          	lw	a5,536(s1)
    80004d24:	21c4a703          	lw	a4,540(s1)
    80004d28:	2007879b          	addiw	a5,a5,512
    80004d2c:	faf708e3          	beq	a4,a5,80004cdc <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d30:	4685                	li	a3,1
    80004d32:	01590633          	add	a2,s2,s5
    80004d36:	f9f40593          	addi	a1,s0,-97
    80004d3a:	0589b503          	ld	a0,88(s3)
    80004d3e:	ffffd097          	auipc	ra,0xffffd
    80004d42:	9c8080e7          	jalr	-1592(ra) # 80001706 <copyin>
    80004d46:	fb6517e3          	bne	a0,s6,80004cf4 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d4a:	21848513          	addi	a0,s1,536
    80004d4e:	ffffd097          	auipc	ra,0xffffd
    80004d52:	744080e7          	jalr	1860(ra) # 80002492 <wakeup>
  release(&pi->lock);
    80004d56:	8526                	mv	a0,s1
    80004d58:	ffffc097          	auipc	ra,0xffffc
    80004d5c:	f40080e7          	jalr	-192(ra) # 80000c98 <release>
  return i;
    80004d60:	b785                	j	80004cc0 <pipewrite+0x54>
  int i = 0;
    80004d62:	4901                	li	s2,0
    80004d64:	b7dd                	j	80004d4a <pipewrite+0xde>

0000000080004d66 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d66:	715d                	addi	sp,sp,-80
    80004d68:	e486                	sd	ra,72(sp)
    80004d6a:	e0a2                	sd	s0,64(sp)
    80004d6c:	fc26                	sd	s1,56(sp)
    80004d6e:	f84a                	sd	s2,48(sp)
    80004d70:	f44e                	sd	s3,40(sp)
    80004d72:	f052                	sd	s4,32(sp)
    80004d74:	ec56                	sd	s5,24(sp)
    80004d76:	e85a                	sd	s6,16(sp)
    80004d78:	0880                	addi	s0,sp,80
    80004d7a:	84aa                	mv	s1,a0
    80004d7c:	892e                	mv	s2,a1
    80004d7e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d80:	ffffd097          	auipc	ra,0xffffd
    80004d84:	c44080e7          	jalr	-956(ra) # 800019c4 <myproc>
    80004d88:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d8a:	8b26                	mv	s6,s1
    80004d8c:	8526                	mv	a0,s1
    80004d8e:	ffffc097          	auipc	ra,0xffffc
    80004d92:	e56080e7          	jalr	-426(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d96:	2184a703          	lw	a4,536(s1)
    80004d9a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d9e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004da2:	02f71463          	bne	a4,a5,80004dca <piperead+0x64>
    80004da6:	2244a783          	lw	a5,548(s1)
    80004daa:	c385                	beqz	a5,80004dca <piperead+0x64>
    if(pr->killed){
    80004dac:	028a2783          	lw	a5,40(s4)
    80004db0:	ebc1                	bnez	a5,80004e40 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004db2:	85da                	mv	a1,s6
    80004db4:	854e                	mv	a0,s3
    80004db6:	ffffd097          	auipc	ra,0xffffd
    80004dba:	550080e7          	jalr	1360(ra) # 80002306 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dbe:	2184a703          	lw	a4,536(s1)
    80004dc2:	21c4a783          	lw	a5,540(s1)
    80004dc6:	fef700e3          	beq	a4,a5,80004da6 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dca:	09505263          	blez	s5,80004e4e <piperead+0xe8>
    80004dce:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dd0:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004dd2:	2184a783          	lw	a5,536(s1)
    80004dd6:	21c4a703          	lw	a4,540(s1)
    80004dda:	02f70d63          	beq	a4,a5,80004e14 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004dde:	0017871b          	addiw	a4,a5,1
    80004de2:	20e4ac23          	sw	a4,536(s1)
    80004de6:	1ff7f793          	andi	a5,a5,511
    80004dea:	97a6                	add	a5,a5,s1
    80004dec:	0187c783          	lbu	a5,24(a5)
    80004df0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004df4:	4685                	li	a3,1
    80004df6:	fbf40613          	addi	a2,s0,-65
    80004dfa:	85ca                	mv	a1,s2
    80004dfc:	058a3503          	ld	a0,88(s4)
    80004e00:	ffffd097          	auipc	ra,0xffffd
    80004e04:	87a080e7          	jalr	-1926(ra) # 8000167a <copyout>
    80004e08:	01650663          	beq	a0,s6,80004e14 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e0c:	2985                	addiw	s3,s3,1
    80004e0e:	0905                	addi	s2,s2,1
    80004e10:	fd3a91e3          	bne	s5,s3,80004dd2 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e14:	21c48513          	addi	a0,s1,540
    80004e18:	ffffd097          	auipc	ra,0xffffd
    80004e1c:	67a080e7          	jalr	1658(ra) # 80002492 <wakeup>
  release(&pi->lock);
    80004e20:	8526                	mv	a0,s1
    80004e22:	ffffc097          	auipc	ra,0xffffc
    80004e26:	e76080e7          	jalr	-394(ra) # 80000c98 <release>
  return i;
}
    80004e2a:	854e                	mv	a0,s3
    80004e2c:	60a6                	ld	ra,72(sp)
    80004e2e:	6406                	ld	s0,64(sp)
    80004e30:	74e2                	ld	s1,56(sp)
    80004e32:	7942                	ld	s2,48(sp)
    80004e34:	79a2                	ld	s3,40(sp)
    80004e36:	7a02                	ld	s4,32(sp)
    80004e38:	6ae2                	ld	s5,24(sp)
    80004e3a:	6b42                	ld	s6,16(sp)
    80004e3c:	6161                	addi	sp,sp,80
    80004e3e:	8082                	ret
      release(&pi->lock);
    80004e40:	8526                	mv	a0,s1
    80004e42:	ffffc097          	auipc	ra,0xffffc
    80004e46:	e56080e7          	jalr	-426(ra) # 80000c98 <release>
      return -1;
    80004e4a:	59fd                	li	s3,-1
    80004e4c:	bff9                	j	80004e2a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e4e:	4981                	li	s3,0
    80004e50:	b7d1                	j	80004e14 <piperead+0xae>

0000000080004e52 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e52:	df010113          	addi	sp,sp,-528
    80004e56:	20113423          	sd	ra,520(sp)
    80004e5a:	20813023          	sd	s0,512(sp)
    80004e5e:	ffa6                	sd	s1,504(sp)
    80004e60:	fbca                	sd	s2,496(sp)
    80004e62:	f7ce                	sd	s3,488(sp)
    80004e64:	f3d2                	sd	s4,480(sp)
    80004e66:	efd6                	sd	s5,472(sp)
    80004e68:	ebda                	sd	s6,464(sp)
    80004e6a:	e7de                	sd	s7,456(sp)
    80004e6c:	e3e2                	sd	s8,448(sp)
    80004e6e:	ff66                	sd	s9,440(sp)
    80004e70:	fb6a                	sd	s10,432(sp)
    80004e72:	f76e                	sd	s11,424(sp)
    80004e74:	0c00                	addi	s0,sp,528
    80004e76:	84aa                	mv	s1,a0
    80004e78:	dea43c23          	sd	a0,-520(s0)
    80004e7c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e80:	ffffd097          	auipc	ra,0xffffd
    80004e84:	b44080e7          	jalr	-1212(ra) # 800019c4 <myproc>
    80004e88:	892a                	mv	s2,a0

  begin_op();
    80004e8a:	fffff097          	auipc	ra,0xfffff
    80004e8e:	49c080e7          	jalr	1180(ra) # 80004326 <begin_op>

  if((ip = namei(path)) == 0){
    80004e92:	8526                	mv	a0,s1
    80004e94:	fffff097          	auipc	ra,0xfffff
    80004e98:	276080e7          	jalr	630(ra) # 8000410a <namei>
    80004e9c:	c92d                	beqz	a0,80004f0e <exec+0xbc>
    80004e9e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ea0:	fffff097          	auipc	ra,0xfffff
    80004ea4:	ab4080e7          	jalr	-1356(ra) # 80003954 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ea8:	04000713          	li	a4,64
    80004eac:	4681                	li	a3,0
    80004eae:	e5040613          	addi	a2,s0,-432
    80004eb2:	4581                	li	a1,0
    80004eb4:	8526                	mv	a0,s1
    80004eb6:	fffff097          	auipc	ra,0xfffff
    80004eba:	d52080e7          	jalr	-686(ra) # 80003c08 <readi>
    80004ebe:	04000793          	li	a5,64
    80004ec2:	00f51a63          	bne	a0,a5,80004ed6 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004ec6:	e5042703          	lw	a4,-432(s0)
    80004eca:	464c47b7          	lui	a5,0x464c4
    80004ece:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ed2:	04f70463          	beq	a4,a5,80004f1a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ed6:	8526                	mv	a0,s1
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	cde080e7          	jalr	-802(ra) # 80003bb6 <iunlockput>
    end_op();
    80004ee0:	fffff097          	auipc	ra,0xfffff
    80004ee4:	4c6080e7          	jalr	1222(ra) # 800043a6 <end_op>
  }
  return -1;
    80004ee8:	557d                	li	a0,-1
}
    80004eea:	20813083          	ld	ra,520(sp)
    80004eee:	20013403          	ld	s0,512(sp)
    80004ef2:	74fe                	ld	s1,504(sp)
    80004ef4:	795e                	ld	s2,496(sp)
    80004ef6:	79be                	ld	s3,488(sp)
    80004ef8:	7a1e                	ld	s4,480(sp)
    80004efa:	6afe                	ld	s5,472(sp)
    80004efc:	6b5e                	ld	s6,464(sp)
    80004efe:	6bbe                	ld	s7,456(sp)
    80004f00:	6c1e                	ld	s8,448(sp)
    80004f02:	7cfa                	ld	s9,440(sp)
    80004f04:	7d5a                	ld	s10,432(sp)
    80004f06:	7dba                	ld	s11,424(sp)
    80004f08:	21010113          	addi	sp,sp,528
    80004f0c:	8082                	ret
    end_op();
    80004f0e:	fffff097          	auipc	ra,0xfffff
    80004f12:	498080e7          	jalr	1176(ra) # 800043a6 <end_op>
    return -1;
    80004f16:	557d                	li	a0,-1
    80004f18:	bfc9                	j	80004eea <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f1a:	854a                	mv	a0,s2
    80004f1c:	ffffd097          	auipc	ra,0xffffd
    80004f20:	b6c080e7          	jalr	-1172(ra) # 80001a88 <proc_pagetable>
    80004f24:	8baa                	mv	s7,a0
    80004f26:	d945                	beqz	a0,80004ed6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f28:	e7042983          	lw	s3,-400(s0)
    80004f2c:	e8845783          	lhu	a5,-376(s0)
    80004f30:	c7ad                	beqz	a5,80004f9a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f32:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f34:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004f36:	6c85                	lui	s9,0x1
    80004f38:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f3c:	def43823          	sd	a5,-528(s0)
    80004f40:	a42d                	j	8000516a <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f42:	00003517          	auipc	a0,0x3
    80004f46:	7d650513          	addi	a0,a0,2006 # 80008718 <syscalls+0x290>
    80004f4a:	ffffb097          	auipc	ra,0xffffb
    80004f4e:	5f4080e7          	jalr	1524(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f52:	8756                	mv	a4,s5
    80004f54:	012d86bb          	addw	a3,s11,s2
    80004f58:	4581                	li	a1,0
    80004f5a:	8526                	mv	a0,s1
    80004f5c:	fffff097          	auipc	ra,0xfffff
    80004f60:	cac080e7          	jalr	-852(ra) # 80003c08 <readi>
    80004f64:	2501                	sext.w	a0,a0
    80004f66:	1aaa9963          	bne	s5,a0,80005118 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f6a:	6785                	lui	a5,0x1
    80004f6c:	0127893b          	addw	s2,a5,s2
    80004f70:	77fd                	lui	a5,0xfffff
    80004f72:	01478a3b          	addw	s4,a5,s4
    80004f76:	1f897163          	bgeu	s2,s8,80005158 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004f7a:	02091593          	slli	a1,s2,0x20
    80004f7e:	9181                	srli	a1,a1,0x20
    80004f80:	95ea                	add	a1,a1,s10
    80004f82:	855e                	mv	a0,s7
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	0f2080e7          	jalr	242(ra) # 80001076 <walkaddr>
    80004f8c:	862a                	mv	a2,a0
    if(pa == 0)
    80004f8e:	d955                	beqz	a0,80004f42 <exec+0xf0>
      n = PGSIZE;
    80004f90:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f92:	fd9a70e3          	bgeu	s4,s9,80004f52 <exec+0x100>
      n = sz - i;
    80004f96:	8ad2                	mv	s5,s4
    80004f98:	bf6d                	j	80004f52 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f9a:	4901                	li	s2,0
  iunlockput(ip);
    80004f9c:	8526                	mv	a0,s1
    80004f9e:	fffff097          	auipc	ra,0xfffff
    80004fa2:	c18080e7          	jalr	-1000(ra) # 80003bb6 <iunlockput>
  end_op();
    80004fa6:	fffff097          	auipc	ra,0xfffff
    80004faa:	400080e7          	jalr	1024(ra) # 800043a6 <end_op>
  p = myproc();
    80004fae:	ffffd097          	auipc	ra,0xffffd
    80004fb2:	a16080e7          	jalr	-1514(ra) # 800019c4 <myproc>
    80004fb6:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fb8:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80004fbc:	6785                	lui	a5,0x1
    80004fbe:	17fd                	addi	a5,a5,-1
    80004fc0:	993e                	add	s2,s2,a5
    80004fc2:	757d                	lui	a0,0xfffff
    80004fc4:	00a977b3          	and	a5,s2,a0
    80004fc8:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fcc:	6609                	lui	a2,0x2
    80004fce:	963e                	add	a2,a2,a5
    80004fd0:	85be                	mv	a1,a5
    80004fd2:	855e                	mv	a0,s7
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	456080e7          	jalr	1110(ra) # 8000142a <uvmalloc>
    80004fdc:	8b2a                	mv	s6,a0
  ip = 0;
    80004fde:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fe0:	12050c63          	beqz	a0,80005118 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fe4:	75f9                	lui	a1,0xffffe
    80004fe6:	95aa                	add	a1,a1,a0
    80004fe8:	855e                	mv	a0,s7
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	65e080e7          	jalr	1630(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ff2:	7c7d                	lui	s8,0xfffff
    80004ff4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ff6:	e0043783          	ld	a5,-512(s0)
    80004ffa:	6388                	ld	a0,0(a5)
    80004ffc:	c535                	beqz	a0,80005068 <exec+0x216>
    80004ffe:	e9040993          	addi	s3,s0,-368
    80005002:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005006:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005008:	ffffc097          	auipc	ra,0xffffc
    8000500c:	e5c080e7          	jalr	-420(ra) # 80000e64 <strlen>
    80005010:	2505                	addiw	a0,a0,1
    80005012:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005016:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000501a:	13896363          	bltu	s2,s8,80005140 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000501e:	e0043d83          	ld	s11,-512(s0)
    80005022:	000dba03          	ld	s4,0(s11)
    80005026:	8552                	mv	a0,s4
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	e3c080e7          	jalr	-452(ra) # 80000e64 <strlen>
    80005030:	0015069b          	addiw	a3,a0,1
    80005034:	8652                	mv	a2,s4
    80005036:	85ca                	mv	a1,s2
    80005038:	855e                	mv	a0,s7
    8000503a:	ffffc097          	auipc	ra,0xffffc
    8000503e:	640080e7          	jalr	1600(ra) # 8000167a <copyout>
    80005042:	10054363          	bltz	a0,80005148 <exec+0x2f6>
    ustack[argc] = sp;
    80005046:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000504a:	0485                	addi	s1,s1,1
    8000504c:	008d8793          	addi	a5,s11,8
    80005050:	e0f43023          	sd	a5,-512(s0)
    80005054:	008db503          	ld	a0,8(s11)
    80005058:	c911                	beqz	a0,8000506c <exec+0x21a>
    if(argc >= MAXARG)
    8000505a:	09a1                	addi	s3,s3,8
    8000505c:	fb3c96e3          	bne	s9,s3,80005008 <exec+0x1b6>
  sz = sz1;
    80005060:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005064:	4481                	li	s1,0
    80005066:	a84d                	j	80005118 <exec+0x2c6>
  sp = sz;
    80005068:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000506a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000506c:	00349793          	slli	a5,s1,0x3
    80005070:	f9040713          	addi	a4,s0,-112
    80005074:	97ba                	add	a5,a5,a4
    80005076:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000507a:	00148693          	addi	a3,s1,1
    8000507e:	068e                	slli	a3,a3,0x3
    80005080:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005084:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005088:	01897663          	bgeu	s2,s8,80005094 <exec+0x242>
  sz = sz1;
    8000508c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005090:	4481                	li	s1,0
    80005092:	a059                	j	80005118 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005094:	e9040613          	addi	a2,s0,-368
    80005098:	85ca                	mv	a1,s2
    8000509a:	855e                	mv	a0,s7
    8000509c:	ffffc097          	auipc	ra,0xffffc
    800050a0:	5de080e7          	jalr	1502(ra) # 8000167a <copyout>
    800050a4:	0a054663          	bltz	a0,80005150 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800050a8:	060ab783          	ld	a5,96(s5)
    800050ac:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050b0:	df843783          	ld	a5,-520(s0)
    800050b4:	0007c703          	lbu	a4,0(a5)
    800050b8:	cf11                	beqz	a4,800050d4 <exec+0x282>
    800050ba:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050bc:	02f00693          	li	a3,47
    800050c0:	a039                	j	800050ce <exec+0x27c>
      last = s+1;
    800050c2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800050c6:	0785                	addi	a5,a5,1
    800050c8:	fff7c703          	lbu	a4,-1(a5)
    800050cc:	c701                	beqz	a4,800050d4 <exec+0x282>
    if(*s == '/')
    800050ce:	fed71ce3          	bne	a4,a3,800050c6 <exec+0x274>
    800050d2:	bfc5                	j	800050c2 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800050d4:	4641                	li	a2,16
    800050d6:	df843583          	ld	a1,-520(s0)
    800050da:	160a8513          	addi	a0,s5,352
    800050de:	ffffc097          	auipc	ra,0xffffc
    800050e2:	d54080e7          	jalr	-684(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800050e6:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    800050ea:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    800050ee:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050f2:	060ab783          	ld	a5,96(s5)
    800050f6:	e6843703          	ld	a4,-408(s0)
    800050fa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050fc:	060ab783          	ld	a5,96(s5)
    80005100:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005104:	85ea                	mv	a1,s10
    80005106:	ffffd097          	auipc	ra,0xffffd
    8000510a:	a1e080e7          	jalr	-1506(ra) # 80001b24 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000510e:	0004851b          	sext.w	a0,s1
    80005112:	bbe1                	j	80004eea <exec+0x98>
    80005114:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005118:	e0843583          	ld	a1,-504(s0)
    8000511c:	855e                	mv	a0,s7
    8000511e:	ffffd097          	auipc	ra,0xffffd
    80005122:	a06080e7          	jalr	-1530(ra) # 80001b24 <proc_freepagetable>
  if(ip){
    80005126:	da0498e3          	bnez	s1,80004ed6 <exec+0x84>
  return -1;
    8000512a:	557d                	li	a0,-1
    8000512c:	bb7d                	j	80004eea <exec+0x98>
    8000512e:	e1243423          	sd	s2,-504(s0)
    80005132:	b7dd                	j	80005118 <exec+0x2c6>
    80005134:	e1243423          	sd	s2,-504(s0)
    80005138:	b7c5                	j	80005118 <exec+0x2c6>
    8000513a:	e1243423          	sd	s2,-504(s0)
    8000513e:	bfe9                	j	80005118 <exec+0x2c6>
  sz = sz1;
    80005140:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005144:	4481                	li	s1,0
    80005146:	bfc9                	j	80005118 <exec+0x2c6>
  sz = sz1;
    80005148:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000514c:	4481                	li	s1,0
    8000514e:	b7e9                	j	80005118 <exec+0x2c6>
  sz = sz1;
    80005150:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005154:	4481                	li	s1,0
    80005156:	b7c9                	j	80005118 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005158:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000515c:	2b05                	addiw	s6,s6,1
    8000515e:	0389899b          	addiw	s3,s3,56
    80005162:	e8845783          	lhu	a5,-376(s0)
    80005166:	e2fb5be3          	bge	s6,a5,80004f9c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000516a:	2981                	sext.w	s3,s3
    8000516c:	03800713          	li	a4,56
    80005170:	86ce                	mv	a3,s3
    80005172:	e1840613          	addi	a2,s0,-488
    80005176:	4581                	li	a1,0
    80005178:	8526                	mv	a0,s1
    8000517a:	fffff097          	auipc	ra,0xfffff
    8000517e:	a8e080e7          	jalr	-1394(ra) # 80003c08 <readi>
    80005182:	03800793          	li	a5,56
    80005186:	f8f517e3          	bne	a0,a5,80005114 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000518a:	e1842783          	lw	a5,-488(s0)
    8000518e:	4705                	li	a4,1
    80005190:	fce796e3          	bne	a5,a4,8000515c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005194:	e4043603          	ld	a2,-448(s0)
    80005198:	e3843783          	ld	a5,-456(s0)
    8000519c:	f8f669e3          	bltu	a2,a5,8000512e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051a0:	e2843783          	ld	a5,-472(s0)
    800051a4:	963e                	add	a2,a2,a5
    800051a6:	f8f667e3          	bltu	a2,a5,80005134 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051aa:	85ca                	mv	a1,s2
    800051ac:	855e                	mv	a0,s7
    800051ae:	ffffc097          	auipc	ra,0xffffc
    800051b2:	27c080e7          	jalr	636(ra) # 8000142a <uvmalloc>
    800051b6:	e0a43423          	sd	a0,-504(s0)
    800051ba:	d141                	beqz	a0,8000513a <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800051bc:	e2843d03          	ld	s10,-472(s0)
    800051c0:	df043783          	ld	a5,-528(s0)
    800051c4:	00fd77b3          	and	a5,s10,a5
    800051c8:	fba1                	bnez	a5,80005118 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051ca:	e2042d83          	lw	s11,-480(s0)
    800051ce:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051d2:	f80c03e3          	beqz	s8,80005158 <exec+0x306>
    800051d6:	8a62                	mv	s4,s8
    800051d8:	4901                	li	s2,0
    800051da:	b345                	j	80004f7a <exec+0x128>

00000000800051dc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051dc:	7179                	addi	sp,sp,-48
    800051de:	f406                	sd	ra,40(sp)
    800051e0:	f022                	sd	s0,32(sp)
    800051e2:	ec26                	sd	s1,24(sp)
    800051e4:	e84a                	sd	s2,16(sp)
    800051e6:	1800                	addi	s0,sp,48
    800051e8:	892e                	mv	s2,a1
    800051ea:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800051ec:	fdc40593          	addi	a1,s0,-36
    800051f0:	ffffe097          	auipc	ra,0xffffe
    800051f4:	ba6080e7          	jalr	-1114(ra) # 80002d96 <argint>
    800051f8:	04054063          	bltz	a0,80005238 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051fc:	fdc42703          	lw	a4,-36(s0)
    80005200:	47bd                	li	a5,15
    80005202:	02e7ed63          	bltu	a5,a4,8000523c <argfd+0x60>
    80005206:	ffffc097          	auipc	ra,0xffffc
    8000520a:	7be080e7          	jalr	1982(ra) # 800019c4 <myproc>
    8000520e:	fdc42703          	lw	a4,-36(s0)
    80005212:	01a70793          	addi	a5,a4,26
    80005216:	078e                	slli	a5,a5,0x3
    80005218:	953e                	add	a0,a0,a5
    8000521a:	651c                	ld	a5,8(a0)
    8000521c:	c395                	beqz	a5,80005240 <argfd+0x64>
    return -1;
  if(pfd)
    8000521e:	00090463          	beqz	s2,80005226 <argfd+0x4a>
    *pfd = fd;
    80005222:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005226:	4501                	li	a0,0
  if(pf)
    80005228:	c091                	beqz	s1,8000522c <argfd+0x50>
    *pf = f;
    8000522a:	e09c                	sd	a5,0(s1)
}
    8000522c:	70a2                	ld	ra,40(sp)
    8000522e:	7402                	ld	s0,32(sp)
    80005230:	64e2                	ld	s1,24(sp)
    80005232:	6942                	ld	s2,16(sp)
    80005234:	6145                	addi	sp,sp,48
    80005236:	8082                	ret
    return -1;
    80005238:	557d                	li	a0,-1
    8000523a:	bfcd                	j	8000522c <argfd+0x50>
    return -1;
    8000523c:	557d                	li	a0,-1
    8000523e:	b7fd                	j	8000522c <argfd+0x50>
    80005240:	557d                	li	a0,-1
    80005242:	b7ed                	j	8000522c <argfd+0x50>

0000000080005244 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005244:	1101                	addi	sp,sp,-32
    80005246:	ec06                	sd	ra,24(sp)
    80005248:	e822                	sd	s0,16(sp)
    8000524a:	e426                	sd	s1,8(sp)
    8000524c:	1000                	addi	s0,sp,32
    8000524e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005250:	ffffc097          	auipc	ra,0xffffc
    80005254:	774080e7          	jalr	1908(ra) # 800019c4 <myproc>
    80005258:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000525a:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffd90d8>
    8000525e:	4501                	li	a0,0
    80005260:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005262:	6398                	ld	a4,0(a5)
    80005264:	cb19                	beqz	a4,8000527a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005266:	2505                	addiw	a0,a0,1
    80005268:	07a1                	addi	a5,a5,8
    8000526a:	fed51ce3          	bne	a0,a3,80005262 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000526e:	557d                	li	a0,-1
}
    80005270:	60e2                	ld	ra,24(sp)
    80005272:	6442                	ld	s0,16(sp)
    80005274:	64a2                	ld	s1,8(sp)
    80005276:	6105                	addi	sp,sp,32
    80005278:	8082                	ret
      p->ofile[fd] = f;
    8000527a:	01a50793          	addi	a5,a0,26
    8000527e:	078e                	slli	a5,a5,0x3
    80005280:	963e                	add	a2,a2,a5
    80005282:	e604                	sd	s1,8(a2)
      return fd;
    80005284:	b7f5                	j	80005270 <fdalloc+0x2c>

0000000080005286 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005286:	715d                	addi	sp,sp,-80
    80005288:	e486                	sd	ra,72(sp)
    8000528a:	e0a2                	sd	s0,64(sp)
    8000528c:	fc26                	sd	s1,56(sp)
    8000528e:	f84a                	sd	s2,48(sp)
    80005290:	f44e                	sd	s3,40(sp)
    80005292:	f052                	sd	s4,32(sp)
    80005294:	ec56                	sd	s5,24(sp)
    80005296:	0880                	addi	s0,sp,80
    80005298:	89ae                	mv	s3,a1
    8000529a:	8ab2                	mv	s5,a2
    8000529c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000529e:	fb040593          	addi	a1,s0,-80
    800052a2:	fffff097          	auipc	ra,0xfffff
    800052a6:	e86080e7          	jalr	-378(ra) # 80004128 <nameiparent>
    800052aa:	892a                	mv	s2,a0
    800052ac:	12050f63          	beqz	a0,800053ea <create+0x164>
    return 0;

  ilock(dp);
    800052b0:	ffffe097          	auipc	ra,0xffffe
    800052b4:	6a4080e7          	jalr	1700(ra) # 80003954 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052b8:	4601                	li	a2,0
    800052ba:	fb040593          	addi	a1,s0,-80
    800052be:	854a                	mv	a0,s2
    800052c0:	fffff097          	auipc	ra,0xfffff
    800052c4:	b78080e7          	jalr	-1160(ra) # 80003e38 <dirlookup>
    800052c8:	84aa                	mv	s1,a0
    800052ca:	c921                	beqz	a0,8000531a <create+0x94>
    iunlockput(dp);
    800052cc:	854a                	mv	a0,s2
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	8e8080e7          	jalr	-1816(ra) # 80003bb6 <iunlockput>
    ilock(ip);
    800052d6:	8526                	mv	a0,s1
    800052d8:	ffffe097          	auipc	ra,0xffffe
    800052dc:	67c080e7          	jalr	1660(ra) # 80003954 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052e0:	2981                	sext.w	s3,s3
    800052e2:	4789                	li	a5,2
    800052e4:	02f99463          	bne	s3,a5,8000530c <create+0x86>
    800052e8:	0444d783          	lhu	a5,68(s1)
    800052ec:	37f9                	addiw	a5,a5,-2
    800052ee:	17c2                	slli	a5,a5,0x30
    800052f0:	93c1                	srli	a5,a5,0x30
    800052f2:	4705                	li	a4,1
    800052f4:	00f76c63          	bltu	a4,a5,8000530c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800052f8:	8526                	mv	a0,s1
    800052fa:	60a6                	ld	ra,72(sp)
    800052fc:	6406                	ld	s0,64(sp)
    800052fe:	74e2                	ld	s1,56(sp)
    80005300:	7942                	ld	s2,48(sp)
    80005302:	79a2                	ld	s3,40(sp)
    80005304:	7a02                	ld	s4,32(sp)
    80005306:	6ae2                	ld	s5,24(sp)
    80005308:	6161                	addi	sp,sp,80
    8000530a:	8082                	ret
    iunlockput(ip);
    8000530c:	8526                	mv	a0,s1
    8000530e:	fffff097          	auipc	ra,0xfffff
    80005312:	8a8080e7          	jalr	-1880(ra) # 80003bb6 <iunlockput>
    return 0;
    80005316:	4481                	li	s1,0
    80005318:	b7c5                	j	800052f8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000531a:	85ce                	mv	a1,s3
    8000531c:	00092503          	lw	a0,0(s2)
    80005320:	ffffe097          	auipc	ra,0xffffe
    80005324:	49c080e7          	jalr	1180(ra) # 800037bc <ialloc>
    80005328:	84aa                	mv	s1,a0
    8000532a:	c529                	beqz	a0,80005374 <create+0xee>
  ilock(ip);
    8000532c:	ffffe097          	auipc	ra,0xffffe
    80005330:	628080e7          	jalr	1576(ra) # 80003954 <ilock>
  ip->major = major;
    80005334:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005338:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000533c:	4785                	li	a5,1
    8000533e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005342:	8526                	mv	a0,s1
    80005344:	ffffe097          	auipc	ra,0xffffe
    80005348:	546080e7          	jalr	1350(ra) # 8000388a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000534c:	2981                	sext.w	s3,s3
    8000534e:	4785                	li	a5,1
    80005350:	02f98a63          	beq	s3,a5,80005384 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005354:	40d0                	lw	a2,4(s1)
    80005356:	fb040593          	addi	a1,s0,-80
    8000535a:	854a                	mv	a0,s2
    8000535c:	fffff097          	auipc	ra,0xfffff
    80005360:	cec080e7          	jalr	-788(ra) # 80004048 <dirlink>
    80005364:	06054b63          	bltz	a0,800053da <create+0x154>
  iunlockput(dp);
    80005368:	854a                	mv	a0,s2
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	84c080e7          	jalr	-1972(ra) # 80003bb6 <iunlockput>
  return ip;
    80005372:	b759                	j	800052f8 <create+0x72>
    panic("create: ialloc");
    80005374:	00003517          	auipc	a0,0x3
    80005378:	3c450513          	addi	a0,a0,964 # 80008738 <syscalls+0x2b0>
    8000537c:	ffffb097          	auipc	ra,0xffffb
    80005380:	1c2080e7          	jalr	450(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005384:	04a95783          	lhu	a5,74(s2)
    80005388:	2785                	addiw	a5,a5,1
    8000538a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000538e:	854a                	mv	a0,s2
    80005390:	ffffe097          	auipc	ra,0xffffe
    80005394:	4fa080e7          	jalr	1274(ra) # 8000388a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005398:	40d0                	lw	a2,4(s1)
    8000539a:	00003597          	auipc	a1,0x3
    8000539e:	3ae58593          	addi	a1,a1,942 # 80008748 <syscalls+0x2c0>
    800053a2:	8526                	mv	a0,s1
    800053a4:	fffff097          	auipc	ra,0xfffff
    800053a8:	ca4080e7          	jalr	-860(ra) # 80004048 <dirlink>
    800053ac:	00054f63          	bltz	a0,800053ca <create+0x144>
    800053b0:	00492603          	lw	a2,4(s2)
    800053b4:	00003597          	auipc	a1,0x3
    800053b8:	39c58593          	addi	a1,a1,924 # 80008750 <syscalls+0x2c8>
    800053bc:	8526                	mv	a0,s1
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	c8a080e7          	jalr	-886(ra) # 80004048 <dirlink>
    800053c6:	f80557e3          	bgez	a0,80005354 <create+0xce>
      panic("create dots");
    800053ca:	00003517          	auipc	a0,0x3
    800053ce:	38e50513          	addi	a0,a0,910 # 80008758 <syscalls+0x2d0>
    800053d2:	ffffb097          	auipc	ra,0xffffb
    800053d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>
    panic("create: dirlink");
    800053da:	00003517          	auipc	a0,0x3
    800053de:	38e50513          	addi	a0,a0,910 # 80008768 <syscalls+0x2e0>
    800053e2:	ffffb097          	auipc	ra,0xffffb
    800053e6:	15c080e7          	jalr	348(ra) # 8000053e <panic>
    return 0;
    800053ea:	84aa                	mv	s1,a0
    800053ec:	b731                	j	800052f8 <create+0x72>

00000000800053ee <sys_dup>:
{
    800053ee:	7179                	addi	sp,sp,-48
    800053f0:	f406                	sd	ra,40(sp)
    800053f2:	f022                	sd	s0,32(sp)
    800053f4:	ec26                	sd	s1,24(sp)
    800053f6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053f8:	fd840613          	addi	a2,s0,-40
    800053fc:	4581                	li	a1,0
    800053fe:	4501                	li	a0,0
    80005400:	00000097          	auipc	ra,0x0
    80005404:	ddc080e7          	jalr	-548(ra) # 800051dc <argfd>
    return -1;
    80005408:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000540a:	02054363          	bltz	a0,80005430 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000540e:	fd843503          	ld	a0,-40(s0)
    80005412:	00000097          	auipc	ra,0x0
    80005416:	e32080e7          	jalr	-462(ra) # 80005244 <fdalloc>
    8000541a:	84aa                	mv	s1,a0
    return -1;
    8000541c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000541e:	00054963          	bltz	a0,80005430 <sys_dup+0x42>
  filedup(f);
    80005422:	fd843503          	ld	a0,-40(s0)
    80005426:	fffff097          	auipc	ra,0xfffff
    8000542a:	37a080e7          	jalr	890(ra) # 800047a0 <filedup>
  return fd;
    8000542e:	87a6                	mv	a5,s1
}
    80005430:	853e                	mv	a0,a5
    80005432:	70a2                	ld	ra,40(sp)
    80005434:	7402                	ld	s0,32(sp)
    80005436:	64e2                	ld	s1,24(sp)
    80005438:	6145                	addi	sp,sp,48
    8000543a:	8082                	ret

000000008000543c <sys_read>:
{
    8000543c:	7179                	addi	sp,sp,-48
    8000543e:	f406                	sd	ra,40(sp)
    80005440:	f022                	sd	s0,32(sp)
    80005442:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005444:	fe840613          	addi	a2,s0,-24
    80005448:	4581                	li	a1,0
    8000544a:	4501                	li	a0,0
    8000544c:	00000097          	auipc	ra,0x0
    80005450:	d90080e7          	jalr	-624(ra) # 800051dc <argfd>
    return -1;
    80005454:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005456:	04054163          	bltz	a0,80005498 <sys_read+0x5c>
    8000545a:	fe440593          	addi	a1,s0,-28
    8000545e:	4509                	li	a0,2
    80005460:	ffffe097          	auipc	ra,0xffffe
    80005464:	936080e7          	jalr	-1738(ra) # 80002d96 <argint>
    return -1;
    80005468:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000546a:	02054763          	bltz	a0,80005498 <sys_read+0x5c>
    8000546e:	fd840593          	addi	a1,s0,-40
    80005472:	4505                	li	a0,1
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	944080e7          	jalr	-1724(ra) # 80002db8 <argaddr>
    return -1;
    8000547c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000547e:	00054d63          	bltz	a0,80005498 <sys_read+0x5c>
  return fileread(f, p, n);
    80005482:	fe442603          	lw	a2,-28(s0)
    80005486:	fd843583          	ld	a1,-40(s0)
    8000548a:	fe843503          	ld	a0,-24(s0)
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	49e080e7          	jalr	1182(ra) # 8000492c <fileread>
    80005496:	87aa                	mv	a5,a0
}
    80005498:	853e                	mv	a0,a5
    8000549a:	70a2                	ld	ra,40(sp)
    8000549c:	7402                	ld	s0,32(sp)
    8000549e:	6145                	addi	sp,sp,48
    800054a0:	8082                	ret

00000000800054a2 <sys_write>:
{
    800054a2:	7179                	addi	sp,sp,-48
    800054a4:	f406                	sd	ra,40(sp)
    800054a6:	f022                	sd	s0,32(sp)
    800054a8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054aa:	fe840613          	addi	a2,s0,-24
    800054ae:	4581                	li	a1,0
    800054b0:	4501                	li	a0,0
    800054b2:	00000097          	auipc	ra,0x0
    800054b6:	d2a080e7          	jalr	-726(ra) # 800051dc <argfd>
    return -1;
    800054ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054bc:	04054163          	bltz	a0,800054fe <sys_write+0x5c>
    800054c0:	fe440593          	addi	a1,s0,-28
    800054c4:	4509                	li	a0,2
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	8d0080e7          	jalr	-1840(ra) # 80002d96 <argint>
    return -1;
    800054ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d0:	02054763          	bltz	a0,800054fe <sys_write+0x5c>
    800054d4:	fd840593          	addi	a1,s0,-40
    800054d8:	4505                	li	a0,1
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	8de080e7          	jalr	-1826(ra) # 80002db8 <argaddr>
    return -1;
    800054e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e4:	00054d63          	bltz	a0,800054fe <sys_write+0x5c>
  return filewrite(f, p, n);
    800054e8:	fe442603          	lw	a2,-28(s0)
    800054ec:	fd843583          	ld	a1,-40(s0)
    800054f0:	fe843503          	ld	a0,-24(s0)
    800054f4:	fffff097          	auipc	ra,0xfffff
    800054f8:	4fa080e7          	jalr	1274(ra) # 800049ee <filewrite>
    800054fc:	87aa                	mv	a5,a0
}
    800054fe:	853e                	mv	a0,a5
    80005500:	70a2                	ld	ra,40(sp)
    80005502:	7402                	ld	s0,32(sp)
    80005504:	6145                	addi	sp,sp,48
    80005506:	8082                	ret

0000000080005508 <sys_close>:
{
    80005508:	1101                	addi	sp,sp,-32
    8000550a:	ec06                	sd	ra,24(sp)
    8000550c:	e822                	sd	s0,16(sp)
    8000550e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005510:	fe040613          	addi	a2,s0,-32
    80005514:	fec40593          	addi	a1,s0,-20
    80005518:	4501                	li	a0,0
    8000551a:	00000097          	auipc	ra,0x0
    8000551e:	cc2080e7          	jalr	-830(ra) # 800051dc <argfd>
    return -1;
    80005522:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005524:	02054463          	bltz	a0,8000554c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005528:	ffffc097          	auipc	ra,0xffffc
    8000552c:	49c080e7          	jalr	1180(ra) # 800019c4 <myproc>
    80005530:	fec42783          	lw	a5,-20(s0)
    80005534:	07e9                	addi	a5,a5,26
    80005536:	078e                	slli	a5,a5,0x3
    80005538:	97aa                	add	a5,a5,a0
    8000553a:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    8000553e:	fe043503          	ld	a0,-32(s0)
    80005542:	fffff097          	auipc	ra,0xfffff
    80005546:	2b0080e7          	jalr	688(ra) # 800047f2 <fileclose>
  return 0;
    8000554a:	4781                	li	a5,0
}
    8000554c:	853e                	mv	a0,a5
    8000554e:	60e2                	ld	ra,24(sp)
    80005550:	6442                	ld	s0,16(sp)
    80005552:	6105                	addi	sp,sp,32
    80005554:	8082                	ret

0000000080005556 <sys_fstat>:
{
    80005556:	1101                	addi	sp,sp,-32
    80005558:	ec06                	sd	ra,24(sp)
    8000555a:	e822                	sd	s0,16(sp)
    8000555c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000555e:	fe840613          	addi	a2,s0,-24
    80005562:	4581                	li	a1,0
    80005564:	4501                	li	a0,0
    80005566:	00000097          	auipc	ra,0x0
    8000556a:	c76080e7          	jalr	-906(ra) # 800051dc <argfd>
    return -1;
    8000556e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005570:	02054563          	bltz	a0,8000559a <sys_fstat+0x44>
    80005574:	fe040593          	addi	a1,s0,-32
    80005578:	4505                	li	a0,1
    8000557a:	ffffe097          	auipc	ra,0xffffe
    8000557e:	83e080e7          	jalr	-1986(ra) # 80002db8 <argaddr>
    return -1;
    80005582:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005584:	00054b63          	bltz	a0,8000559a <sys_fstat+0x44>
  return filestat(f, st);
    80005588:	fe043583          	ld	a1,-32(s0)
    8000558c:	fe843503          	ld	a0,-24(s0)
    80005590:	fffff097          	auipc	ra,0xfffff
    80005594:	32a080e7          	jalr	810(ra) # 800048ba <filestat>
    80005598:	87aa                	mv	a5,a0
}
    8000559a:	853e                	mv	a0,a5
    8000559c:	60e2                	ld	ra,24(sp)
    8000559e:	6442                	ld	s0,16(sp)
    800055a0:	6105                	addi	sp,sp,32
    800055a2:	8082                	ret

00000000800055a4 <sys_link>:
{
    800055a4:	7169                	addi	sp,sp,-304
    800055a6:	f606                	sd	ra,296(sp)
    800055a8:	f222                	sd	s0,288(sp)
    800055aa:	ee26                	sd	s1,280(sp)
    800055ac:	ea4a                	sd	s2,272(sp)
    800055ae:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055b0:	08000613          	li	a2,128
    800055b4:	ed040593          	addi	a1,s0,-304
    800055b8:	4501                	li	a0,0
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	820080e7          	jalr	-2016(ra) # 80002dda <argstr>
    return -1;
    800055c2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055c4:	10054e63          	bltz	a0,800056e0 <sys_link+0x13c>
    800055c8:	08000613          	li	a2,128
    800055cc:	f5040593          	addi	a1,s0,-176
    800055d0:	4505                	li	a0,1
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	808080e7          	jalr	-2040(ra) # 80002dda <argstr>
    return -1;
    800055da:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055dc:	10054263          	bltz	a0,800056e0 <sys_link+0x13c>
  begin_op();
    800055e0:	fffff097          	auipc	ra,0xfffff
    800055e4:	d46080e7          	jalr	-698(ra) # 80004326 <begin_op>
  if((ip = namei(old)) == 0){
    800055e8:	ed040513          	addi	a0,s0,-304
    800055ec:	fffff097          	auipc	ra,0xfffff
    800055f0:	b1e080e7          	jalr	-1250(ra) # 8000410a <namei>
    800055f4:	84aa                	mv	s1,a0
    800055f6:	c551                	beqz	a0,80005682 <sys_link+0xde>
  ilock(ip);
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	35c080e7          	jalr	860(ra) # 80003954 <ilock>
  if(ip->type == T_DIR){
    80005600:	04449703          	lh	a4,68(s1)
    80005604:	4785                	li	a5,1
    80005606:	08f70463          	beq	a4,a5,8000568e <sys_link+0xea>
  ip->nlink++;
    8000560a:	04a4d783          	lhu	a5,74(s1)
    8000560e:	2785                	addiw	a5,a5,1
    80005610:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005614:	8526                	mv	a0,s1
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	274080e7          	jalr	628(ra) # 8000388a <iupdate>
  iunlock(ip);
    8000561e:	8526                	mv	a0,s1
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	3f6080e7          	jalr	1014(ra) # 80003a16 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005628:	fd040593          	addi	a1,s0,-48
    8000562c:	f5040513          	addi	a0,s0,-176
    80005630:	fffff097          	auipc	ra,0xfffff
    80005634:	af8080e7          	jalr	-1288(ra) # 80004128 <nameiparent>
    80005638:	892a                	mv	s2,a0
    8000563a:	c935                	beqz	a0,800056ae <sys_link+0x10a>
  ilock(dp);
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	318080e7          	jalr	792(ra) # 80003954 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005644:	00092703          	lw	a4,0(s2)
    80005648:	409c                	lw	a5,0(s1)
    8000564a:	04f71d63          	bne	a4,a5,800056a4 <sys_link+0x100>
    8000564e:	40d0                	lw	a2,4(s1)
    80005650:	fd040593          	addi	a1,s0,-48
    80005654:	854a                	mv	a0,s2
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	9f2080e7          	jalr	-1550(ra) # 80004048 <dirlink>
    8000565e:	04054363          	bltz	a0,800056a4 <sys_link+0x100>
  iunlockput(dp);
    80005662:	854a                	mv	a0,s2
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	552080e7          	jalr	1362(ra) # 80003bb6 <iunlockput>
  iput(ip);
    8000566c:	8526                	mv	a0,s1
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	4a0080e7          	jalr	1184(ra) # 80003b0e <iput>
  end_op();
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	d30080e7          	jalr	-720(ra) # 800043a6 <end_op>
  return 0;
    8000567e:	4781                	li	a5,0
    80005680:	a085                	j	800056e0 <sys_link+0x13c>
    end_op();
    80005682:	fffff097          	auipc	ra,0xfffff
    80005686:	d24080e7          	jalr	-732(ra) # 800043a6 <end_op>
    return -1;
    8000568a:	57fd                	li	a5,-1
    8000568c:	a891                	j	800056e0 <sys_link+0x13c>
    iunlockput(ip);
    8000568e:	8526                	mv	a0,s1
    80005690:	ffffe097          	auipc	ra,0xffffe
    80005694:	526080e7          	jalr	1318(ra) # 80003bb6 <iunlockput>
    end_op();
    80005698:	fffff097          	auipc	ra,0xfffff
    8000569c:	d0e080e7          	jalr	-754(ra) # 800043a6 <end_op>
    return -1;
    800056a0:	57fd                	li	a5,-1
    800056a2:	a83d                	j	800056e0 <sys_link+0x13c>
    iunlockput(dp);
    800056a4:	854a                	mv	a0,s2
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	510080e7          	jalr	1296(ra) # 80003bb6 <iunlockput>
  ilock(ip);
    800056ae:	8526                	mv	a0,s1
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	2a4080e7          	jalr	676(ra) # 80003954 <ilock>
  ip->nlink--;
    800056b8:	04a4d783          	lhu	a5,74(s1)
    800056bc:	37fd                	addiw	a5,a5,-1
    800056be:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056c2:	8526                	mv	a0,s1
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	1c6080e7          	jalr	454(ra) # 8000388a <iupdate>
  iunlockput(ip);
    800056cc:	8526                	mv	a0,s1
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	4e8080e7          	jalr	1256(ra) # 80003bb6 <iunlockput>
  end_op();
    800056d6:	fffff097          	auipc	ra,0xfffff
    800056da:	cd0080e7          	jalr	-816(ra) # 800043a6 <end_op>
  return -1;
    800056de:	57fd                	li	a5,-1
}
    800056e0:	853e                	mv	a0,a5
    800056e2:	70b2                	ld	ra,296(sp)
    800056e4:	7412                	ld	s0,288(sp)
    800056e6:	64f2                	ld	s1,280(sp)
    800056e8:	6952                	ld	s2,272(sp)
    800056ea:	6155                	addi	sp,sp,304
    800056ec:	8082                	ret

00000000800056ee <sys_unlink>:
{
    800056ee:	7151                	addi	sp,sp,-240
    800056f0:	f586                	sd	ra,232(sp)
    800056f2:	f1a2                	sd	s0,224(sp)
    800056f4:	eda6                	sd	s1,216(sp)
    800056f6:	e9ca                	sd	s2,208(sp)
    800056f8:	e5ce                	sd	s3,200(sp)
    800056fa:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056fc:	08000613          	li	a2,128
    80005700:	f3040593          	addi	a1,s0,-208
    80005704:	4501                	li	a0,0
    80005706:	ffffd097          	auipc	ra,0xffffd
    8000570a:	6d4080e7          	jalr	1748(ra) # 80002dda <argstr>
    8000570e:	18054163          	bltz	a0,80005890 <sys_unlink+0x1a2>
  begin_op();
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	c14080e7          	jalr	-1004(ra) # 80004326 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000571a:	fb040593          	addi	a1,s0,-80
    8000571e:	f3040513          	addi	a0,s0,-208
    80005722:	fffff097          	auipc	ra,0xfffff
    80005726:	a06080e7          	jalr	-1530(ra) # 80004128 <nameiparent>
    8000572a:	84aa                	mv	s1,a0
    8000572c:	c979                	beqz	a0,80005802 <sys_unlink+0x114>
  ilock(dp);
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	226080e7          	jalr	550(ra) # 80003954 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005736:	00003597          	auipc	a1,0x3
    8000573a:	01258593          	addi	a1,a1,18 # 80008748 <syscalls+0x2c0>
    8000573e:	fb040513          	addi	a0,s0,-80
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	6dc080e7          	jalr	1756(ra) # 80003e1e <namecmp>
    8000574a:	14050a63          	beqz	a0,8000589e <sys_unlink+0x1b0>
    8000574e:	00003597          	auipc	a1,0x3
    80005752:	00258593          	addi	a1,a1,2 # 80008750 <syscalls+0x2c8>
    80005756:	fb040513          	addi	a0,s0,-80
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	6c4080e7          	jalr	1732(ra) # 80003e1e <namecmp>
    80005762:	12050e63          	beqz	a0,8000589e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005766:	f2c40613          	addi	a2,s0,-212
    8000576a:	fb040593          	addi	a1,s0,-80
    8000576e:	8526                	mv	a0,s1
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	6c8080e7          	jalr	1736(ra) # 80003e38 <dirlookup>
    80005778:	892a                	mv	s2,a0
    8000577a:	12050263          	beqz	a0,8000589e <sys_unlink+0x1b0>
  ilock(ip);
    8000577e:	ffffe097          	auipc	ra,0xffffe
    80005782:	1d6080e7          	jalr	470(ra) # 80003954 <ilock>
  if(ip->nlink < 1)
    80005786:	04a91783          	lh	a5,74(s2)
    8000578a:	08f05263          	blez	a5,8000580e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000578e:	04491703          	lh	a4,68(s2)
    80005792:	4785                	li	a5,1
    80005794:	08f70563          	beq	a4,a5,8000581e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005798:	4641                	li	a2,16
    8000579a:	4581                	li	a1,0
    8000579c:	fc040513          	addi	a0,s0,-64
    800057a0:	ffffb097          	auipc	ra,0xffffb
    800057a4:	540080e7          	jalr	1344(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057a8:	4741                	li	a4,16
    800057aa:	f2c42683          	lw	a3,-212(s0)
    800057ae:	fc040613          	addi	a2,s0,-64
    800057b2:	4581                	li	a1,0
    800057b4:	8526                	mv	a0,s1
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	54a080e7          	jalr	1354(ra) # 80003d00 <writei>
    800057be:	47c1                	li	a5,16
    800057c0:	0af51563          	bne	a0,a5,8000586a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057c4:	04491703          	lh	a4,68(s2)
    800057c8:	4785                	li	a5,1
    800057ca:	0af70863          	beq	a4,a5,8000587a <sys_unlink+0x18c>
  iunlockput(dp);
    800057ce:	8526                	mv	a0,s1
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	3e6080e7          	jalr	998(ra) # 80003bb6 <iunlockput>
  ip->nlink--;
    800057d8:	04a95783          	lhu	a5,74(s2)
    800057dc:	37fd                	addiw	a5,a5,-1
    800057de:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057e2:	854a                	mv	a0,s2
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	0a6080e7          	jalr	166(ra) # 8000388a <iupdate>
  iunlockput(ip);
    800057ec:	854a                	mv	a0,s2
    800057ee:	ffffe097          	auipc	ra,0xffffe
    800057f2:	3c8080e7          	jalr	968(ra) # 80003bb6 <iunlockput>
  end_op();
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	bb0080e7          	jalr	-1104(ra) # 800043a6 <end_op>
  return 0;
    800057fe:	4501                	li	a0,0
    80005800:	a84d                	j	800058b2 <sys_unlink+0x1c4>
    end_op();
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	ba4080e7          	jalr	-1116(ra) # 800043a6 <end_op>
    return -1;
    8000580a:	557d                	li	a0,-1
    8000580c:	a05d                	j	800058b2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000580e:	00003517          	auipc	a0,0x3
    80005812:	f6a50513          	addi	a0,a0,-150 # 80008778 <syscalls+0x2f0>
    80005816:	ffffb097          	auipc	ra,0xffffb
    8000581a:	d28080e7          	jalr	-728(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000581e:	04c92703          	lw	a4,76(s2)
    80005822:	02000793          	li	a5,32
    80005826:	f6e7f9e3          	bgeu	a5,a4,80005798 <sys_unlink+0xaa>
    8000582a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000582e:	4741                	li	a4,16
    80005830:	86ce                	mv	a3,s3
    80005832:	f1840613          	addi	a2,s0,-232
    80005836:	4581                	li	a1,0
    80005838:	854a                	mv	a0,s2
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	3ce080e7          	jalr	974(ra) # 80003c08 <readi>
    80005842:	47c1                	li	a5,16
    80005844:	00f51b63          	bne	a0,a5,8000585a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005848:	f1845783          	lhu	a5,-232(s0)
    8000584c:	e7a1                	bnez	a5,80005894 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000584e:	29c1                	addiw	s3,s3,16
    80005850:	04c92783          	lw	a5,76(s2)
    80005854:	fcf9ede3          	bltu	s3,a5,8000582e <sys_unlink+0x140>
    80005858:	b781                	j	80005798 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000585a:	00003517          	auipc	a0,0x3
    8000585e:	f3650513          	addi	a0,a0,-202 # 80008790 <syscalls+0x308>
    80005862:	ffffb097          	auipc	ra,0xffffb
    80005866:	cdc080e7          	jalr	-804(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000586a:	00003517          	auipc	a0,0x3
    8000586e:	f3e50513          	addi	a0,a0,-194 # 800087a8 <syscalls+0x320>
    80005872:	ffffb097          	auipc	ra,0xffffb
    80005876:	ccc080e7          	jalr	-820(ra) # 8000053e <panic>
    dp->nlink--;
    8000587a:	04a4d783          	lhu	a5,74(s1)
    8000587e:	37fd                	addiw	a5,a5,-1
    80005880:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005884:	8526                	mv	a0,s1
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	004080e7          	jalr	4(ra) # 8000388a <iupdate>
    8000588e:	b781                	j	800057ce <sys_unlink+0xe0>
    return -1;
    80005890:	557d                	li	a0,-1
    80005892:	a005                	j	800058b2 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005894:	854a                	mv	a0,s2
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	320080e7          	jalr	800(ra) # 80003bb6 <iunlockput>
  iunlockput(dp);
    8000589e:	8526                	mv	a0,s1
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	316080e7          	jalr	790(ra) # 80003bb6 <iunlockput>
  end_op();
    800058a8:	fffff097          	auipc	ra,0xfffff
    800058ac:	afe080e7          	jalr	-1282(ra) # 800043a6 <end_op>
  return -1;
    800058b0:	557d                	li	a0,-1
}
    800058b2:	70ae                	ld	ra,232(sp)
    800058b4:	740e                	ld	s0,224(sp)
    800058b6:	64ee                	ld	s1,216(sp)
    800058b8:	694e                	ld	s2,208(sp)
    800058ba:	69ae                	ld	s3,200(sp)
    800058bc:	616d                	addi	sp,sp,240
    800058be:	8082                	ret

00000000800058c0 <sys_open>:

uint64
sys_open(void)
{
    800058c0:	7131                	addi	sp,sp,-192
    800058c2:	fd06                	sd	ra,184(sp)
    800058c4:	f922                	sd	s0,176(sp)
    800058c6:	f526                	sd	s1,168(sp)
    800058c8:	f14a                	sd	s2,160(sp)
    800058ca:	ed4e                	sd	s3,152(sp)
    800058cc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058ce:	08000613          	li	a2,128
    800058d2:	f5040593          	addi	a1,s0,-176
    800058d6:	4501                	li	a0,0
    800058d8:	ffffd097          	auipc	ra,0xffffd
    800058dc:	502080e7          	jalr	1282(ra) # 80002dda <argstr>
    return -1;
    800058e0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058e2:	0c054163          	bltz	a0,800059a4 <sys_open+0xe4>
    800058e6:	f4c40593          	addi	a1,s0,-180
    800058ea:	4505                	li	a0,1
    800058ec:	ffffd097          	auipc	ra,0xffffd
    800058f0:	4aa080e7          	jalr	1194(ra) # 80002d96 <argint>
    800058f4:	0a054863          	bltz	a0,800059a4 <sys_open+0xe4>

  begin_op();
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	a2e080e7          	jalr	-1490(ra) # 80004326 <begin_op>

  if(omode & O_CREATE){
    80005900:	f4c42783          	lw	a5,-180(s0)
    80005904:	2007f793          	andi	a5,a5,512
    80005908:	cbdd                	beqz	a5,800059be <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000590a:	4681                	li	a3,0
    8000590c:	4601                	li	a2,0
    8000590e:	4589                	li	a1,2
    80005910:	f5040513          	addi	a0,s0,-176
    80005914:	00000097          	auipc	ra,0x0
    80005918:	972080e7          	jalr	-1678(ra) # 80005286 <create>
    8000591c:	892a                	mv	s2,a0
    if(ip == 0){
    8000591e:	c959                	beqz	a0,800059b4 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005920:	04491703          	lh	a4,68(s2)
    80005924:	478d                	li	a5,3
    80005926:	00f71763          	bne	a4,a5,80005934 <sys_open+0x74>
    8000592a:	04695703          	lhu	a4,70(s2)
    8000592e:	47a5                	li	a5,9
    80005930:	0ce7ec63          	bltu	a5,a4,80005a08 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	e02080e7          	jalr	-510(ra) # 80004736 <filealloc>
    8000593c:	89aa                	mv	s3,a0
    8000593e:	10050263          	beqz	a0,80005a42 <sys_open+0x182>
    80005942:	00000097          	auipc	ra,0x0
    80005946:	902080e7          	jalr	-1790(ra) # 80005244 <fdalloc>
    8000594a:	84aa                	mv	s1,a0
    8000594c:	0e054663          	bltz	a0,80005a38 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005950:	04491703          	lh	a4,68(s2)
    80005954:	478d                	li	a5,3
    80005956:	0cf70463          	beq	a4,a5,80005a1e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000595a:	4789                	li	a5,2
    8000595c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005960:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005964:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005968:	f4c42783          	lw	a5,-180(s0)
    8000596c:	0017c713          	xori	a4,a5,1
    80005970:	8b05                	andi	a4,a4,1
    80005972:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005976:	0037f713          	andi	a4,a5,3
    8000597a:	00e03733          	snez	a4,a4
    8000597e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005982:	4007f793          	andi	a5,a5,1024
    80005986:	c791                	beqz	a5,80005992 <sys_open+0xd2>
    80005988:	04491703          	lh	a4,68(s2)
    8000598c:	4789                	li	a5,2
    8000598e:	08f70f63          	beq	a4,a5,80005a2c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005992:	854a                	mv	a0,s2
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	082080e7          	jalr	130(ra) # 80003a16 <iunlock>
  end_op();
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	a0a080e7          	jalr	-1526(ra) # 800043a6 <end_op>

  return fd;
}
    800059a4:	8526                	mv	a0,s1
    800059a6:	70ea                	ld	ra,184(sp)
    800059a8:	744a                	ld	s0,176(sp)
    800059aa:	74aa                	ld	s1,168(sp)
    800059ac:	790a                	ld	s2,160(sp)
    800059ae:	69ea                	ld	s3,152(sp)
    800059b0:	6129                	addi	sp,sp,192
    800059b2:	8082                	ret
      end_op();
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	9f2080e7          	jalr	-1550(ra) # 800043a6 <end_op>
      return -1;
    800059bc:	b7e5                	j	800059a4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059be:	f5040513          	addi	a0,s0,-176
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	748080e7          	jalr	1864(ra) # 8000410a <namei>
    800059ca:	892a                	mv	s2,a0
    800059cc:	c905                	beqz	a0,800059fc <sys_open+0x13c>
    ilock(ip);
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	f86080e7          	jalr	-122(ra) # 80003954 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059d6:	04491703          	lh	a4,68(s2)
    800059da:	4785                	li	a5,1
    800059dc:	f4f712e3          	bne	a4,a5,80005920 <sys_open+0x60>
    800059e0:	f4c42783          	lw	a5,-180(s0)
    800059e4:	dba1                	beqz	a5,80005934 <sys_open+0x74>
      iunlockput(ip);
    800059e6:	854a                	mv	a0,s2
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	1ce080e7          	jalr	462(ra) # 80003bb6 <iunlockput>
      end_op();
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	9b6080e7          	jalr	-1610(ra) # 800043a6 <end_op>
      return -1;
    800059f8:	54fd                	li	s1,-1
    800059fa:	b76d                	j	800059a4 <sys_open+0xe4>
      end_op();
    800059fc:	fffff097          	auipc	ra,0xfffff
    80005a00:	9aa080e7          	jalr	-1622(ra) # 800043a6 <end_op>
      return -1;
    80005a04:	54fd                	li	s1,-1
    80005a06:	bf79                	j	800059a4 <sys_open+0xe4>
    iunlockput(ip);
    80005a08:	854a                	mv	a0,s2
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	1ac080e7          	jalr	428(ra) # 80003bb6 <iunlockput>
    end_op();
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	994080e7          	jalr	-1644(ra) # 800043a6 <end_op>
    return -1;
    80005a1a:	54fd                	li	s1,-1
    80005a1c:	b761                	j	800059a4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a1e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a22:	04691783          	lh	a5,70(s2)
    80005a26:	02f99223          	sh	a5,36(s3)
    80005a2a:	bf2d                	j	80005964 <sys_open+0xa4>
    itrunc(ip);
    80005a2c:	854a                	mv	a0,s2
    80005a2e:	ffffe097          	auipc	ra,0xffffe
    80005a32:	034080e7          	jalr	52(ra) # 80003a62 <itrunc>
    80005a36:	bfb1                	j	80005992 <sys_open+0xd2>
      fileclose(f);
    80005a38:	854e                	mv	a0,s3
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	db8080e7          	jalr	-584(ra) # 800047f2 <fileclose>
    iunlockput(ip);
    80005a42:	854a                	mv	a0,s2
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	172080e7          	jalr	370(ra) # 80003bb6 <iunlockput>
    end_op();
    80005a4c:	fffff097          	auipc	ra,0xfffff
    80005a50:	95a080e7          	jalr	-1702(ra) # 800043a6 <end_op>
    return -1;
    80005a54:	54fd                	li	s1,-1
    80005a56:	b7b9                	j	800059a4 <sys_open+0xe4>

0000000080005a58 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a58:	7175                	addi	sp,sp,-144
    80005a5a:	e506                	sd	ra,136(sp)
    80005a5c:	e122                	sd	s0,128(sp)
    80005a5e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	8c6080e7          	jalr	-1850(ra) # 80004326 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a68:	08000613          	li	a2,128
    80005a6c:	f7040593          	addi	a1,s0,-144
    80005a70:	4501                	li	a0,0
    80005a72:	ffffd097          	auipc	ra,0xffffd
    80005a76:	368080e7          	jalr	872(ra) # 80002dda <argstr>
    80005a7a:	02054963          	bltz	a0,80005aac <sys_mkdir+0x54>
    80005a7e:	4681                	li	a3,0
    80005a80:	4601                	li	a2,0
    80005a82:	4585                	li	a1,1
    80005a84:	f7040513          	addi	a0,s0,-144
    80005a88:	fffff097          	auipc	ra,0xfffff
    80005a8c:	7fe080e7          	jalr	2046(ra) # 80005286 <create>
    80005a90:	cd11                	beqz	a0,80005aac <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a92:	ffffe097          	auipc	ra,0xffffe
    80005a96:	124080e7          	jalr	292(ra) # 80003bb6 <iunlockput>
  end_op();
    80005a9a:	fffff097          	auipc	ra,0xfffff
    80005a9e:	90c080e7          	jalr	-1780(ra) # 800043a6 <end_op>
  return 0;
    80005aa2:	4501                	li	a0,0
}
    80005aa4:	60aa                	ld	ra,136(sp)
    80005aa6:	640a                	ld	s0,128(sp)
    80005aa8:	6149                	addi	sp,sp,144
    80005aaa:	8082                	ret
    end_op();
    80005aac:	fffff097          	auipc	ra,0xfffff
    80005ab0:	8fa080e7          	jalr	-1798(ra) # 800043a6 <end_op>
    return -1;
    80005ab4:	557d                	li	a0,-1
    80005ab6:	b7fd                	j	80005aa4 <sys_mkdir+0x4c>

0000000080005ab8 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ab8:	7135                	addi	sp,sp,-160
    80005aba:	ed06                	sd	ra,152(sp)
    80005abc:	e922                	sd	s0,144(sp)
    80005abe:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	866080e7          	jalr	-1946(ra) # 80004326 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ac8:	08000613          	li	a2,128
    80005acc:	f7040593          	addi	a1,s0,-144
    80005ad0:	4501                	li	a0,0
    80005ad2:	ffffd097          	auipc	ra,0xffffd
    80005ad6:	308080e7          	jalr	776(ra) # 80002dda <argstr>
    80005ada:	04054a63          	bltz	a0,80005b2e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005ade:	f6c40593          	addi	a1,s0,-148
    80005ae2:	4505                	li	a0,1
    80005ae4:	ffffd097          	auipc	ra,0xffffd
    80005ae8:	2b2080e7          	jalr	690(ra) # 80002d96 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005aec:	04054163          	bltz	a0,80005b2e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005af0:	f6840593          	addi	a1,s0,-152
    80005af4:	4509                	li	a0,2
    80005af6:	ffffd097          	auipc	ra,0xffffd
    80005afa:	2a0080e7          	jalr	672(ra) # 80002d96 <argint>
     argint(1, &major) < 0 ||
    80005afe:	02054863          	bltz	a0,80005b2e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b02:	f6841683          	lh	a3,-152(s0)
    80005b06:	f6c41603          	lh	a2,-148(s0)
    80005b0a:	458d                	li	a1,3
    80005b0c:	f7040513          	addi	a0,s0,-144
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	776080e7          	jalr	1910(ra) # 80005286 <create>
     argint(2, &minor) < 0 ||
    80005b18:	c919                	beqz	a0,80005b2e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b1a:	ffffe097          	auipc	ra,0xffffe
    80005b1e:	09c080e7          	jalr	156(ra) # 80003bb6 <iunlockput>
  end_op();
    80005b22:	fffff097          	auipc	ra,0xfffff
    80005b26:	884080e7          	jalr	-1916(ra) # 800043a6 <end_op>
  return 0;
    80005b2a:	4501                	li	a0,0
    80005b2c:	a031                	j	80005b38 <sys_mknod+0x80>
    end_op();
    80005b2e:	fffff097          	auipc	ra,0xfffff
    80005b32:	878080e7          	jalr	-1928(ra) # 800043a6 <end_op>
    return -1;
    80005b36:	557d                	li	a0,-1
}
    80005b38:	60ea                	ld	ra,152(sp)
    80005b3a:	644a                	ld	s0,144(sp)
    80005b3c:	610d                	addi	sp,sp,160
    80005b3e:	8082                	ret

0000000080005b40 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b40:	7135                	addi	sp,sp,-160
    80005b42:	ed06                	sd	ra,152(sp)
    80005b44:	e922                	sd	s0,144(sp)
    80005b46:	e526                	sd	s1,136(sp)
    80005b48:	e14a                	sd	s2,128(sp)
    80005b4a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b4c:	ffffc097          	auipc	ra,0xffffc
    80005b50:	e78080e7          	jalr	-392(ra) # 800019c4 <myproc>
    80005b54:	892a                	mv	s2,a0
  
  begin_op();
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	7d0080e7          	jalr	2000(ra) # 80004326 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b5e:	08000613          	li	a2,128
    80005b62:	f6040593          	addi	a1,s0,-160
    80005b66:	4501                	li	a0,0
    80005b68:	ffffd097          	auipc	ra,0xffffd
    80005b6c:	272080e7          	jalr	626(ra) # 80002dda <argstr>
    80005b70:	04054b63          	bltz	a0,80005bc6 <sys_chdir+0x86>
    80005b74:	f6040513          	addi	a0,s0,-160
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	592080e7          	jalr	1426(ra) # 8000410a <namei>
    80005b80:	84aa                	mv	s1,a0
    80005b82:	c131                	beqz	a0,80005bc6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	dd0080e7          	jalr	-560(ra) # 80003954 <ilock>
  if(ip->type != T_DIR){
    80005b8c:	04449703          	lh	a4,68(s1)
    80005b90:	4785                	li	a5,1
    80005b92:	04f71063          	bne	a4,a5,80005bd2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b96:	8526                	mv	a0,s1
    80005b98:	ffffe097          	auipc	ra,0xffffe
    80005b9c:	e7e080e7          	jalr	-386(ra) # 80003a16 <iunlock>
  iput(p->cwd);
    80005ba0:	15893503          	ld	a0,344(s2)
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	f6a080e7          	jalr	-150(ra) # 80003b0e <iput>
  end_op();
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	7fa080e7          	jalr	2042(ra) # 800043a6 <end_op>
  p->cwd = ip;
    80005bb4:	14993c23          	sd	s1,344(s2)
  return 0;
    80005bb8:	4501                	li	a0,0
}
    80005bba:	60ea                	ld	ra,152(sp)
    80005bbc:	644a                	ld	s0,144(sp)
    80005bbe:	64aa                	ld	s1,136(sp)
    80005bc0:	690a                	ld	s2,128(sp)
    80005bc2:	610d                	addi	sp,sp,160
    80005bc4:	8082                	ret
    end_op();
    80005bc6:	ffffe097          	auipc	ra,0xffffe
    80005bca:	7e0080e7          	jalr	2016(ra) # 800043a6 <end_op>
    return -1;
    80005bce:	557d                	li	a0,-1
    80005bd0:	b7ed                	j	80005bba <sys_chdir+0x7a>
    iunlockput(ip);
    80005bd2:	8526                	mv	a0,s1
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	fe2080e7          	jalr	-30(ra) # 80003bb6 <iunlockput>
    end_op();
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	7ca080e7          	jalr	1994(ra) # 800043a6 <end_op>
    return -1;
    80005be4:	557d                	li	a0,-1
    80005be6:	bfd1                	j	80005bba <sys_chdir+0x7a>

0000000080005be8 <sys_exec>:

uint64
sys_exec(void)
{
    80005be8:	7145                	addi	sp,sp,-464
    80005bea:	e786                	sd	ra,456(sp)
    80005bec:	e3a2                	sd	s0,448(sp)
    80005bee:	ff26                	sd	s1,440(sp)
    80005bf0:	fb4a                	sd	s2,432(sp)
    80005bf2:	f74e                	sd	s3,424(sp)
    80005bf4:	f352                	sd	s4,416(sp)
    80005bf6:	ef56                	sd	s5,408(sp)
    80005bf8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bfa:	08000613          	li	a2,128
    80005bfe:	f4040593          	addi	a1,s0,-192
    80005c02:	4501                	li	a0,0
    80005c04:	ffffd097          	auipc	ra,0xffffd
    80005c08:	1d6080e7          	jalr	470(ra) # 80002dda <argstr>
    return -1;
    80005c0c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c0e:	0c054a63          	bltz	a0,80005ce2 <sys_exec+0xfa>
    80005c12:	e3840593          	addi	a1,s0,-456
    80005c16:	4505                	li	a0,1
    80005c18:	ffffd097          	auipc	ra,0xffffd
    80005c1c:	1a0080e7          	jalr	416(ra) # 80002db8 <argaddr>
    80005c20:	0c054163          	bltz	a0,80005ce2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c24:	10000613          	li	a2,256
    80005c28:	4581                	li	a1,0
    80005c2a:	e4040513          	addi	a0,s0,-448
    80005c2e:	ffffb097          	auipc	ra,0xffffb
    80005c32:	0b2080e7          	jalr	178(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c36:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c3a:	89a6                	mv	s3,s1
    80005c3c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c3e:	02000a13          	li	s4,32
    80005c42:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c46:	00391513          	slli	a0,s2,0x3
    80005c4a:	e3040593          	addi	a1,s0,-464
    80005c4e:	e3843783          	ld	a5,-456(s0)
    80005c52:	953e                	add	a0,a0,a5
    80005c54:	ffffd097          	auipc	ra,0xffffd
    80005c58:	0a8080e7          	jalr	168(ra) # 80002cfc <fetchaddr>
    80005c5c:	02054a63          	bltz	a0,80005c90 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c60:	e3043783          	ld	a5,-464(s0)
    80005c64:	c3b9                	beqz	a5,80005caa <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c66:	ffffb097          	auipc	ra,0xffffb
    80005c6a:	e8e080e7          	jalr	-370(ra) # 80000af4 <kalloc>
    80005c6e:	85aa                	mv	a1,a0
    80005c70:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c74:	cd11                	beqz	a0,80005c90 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c76:	6605                	lui	a2,0x1
    80005c78:	e3043503          	ld	a0,-464(s0)
    80005c7c:	ffffd097          	auipc	ra,0xffffd
    80005c80:	0d2080e7          	jalr	210(ra) # 80002d4e <fetchstr>
    80005c84:	00054663          	bltz	a0,80005c90 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c88:	0905                	addi	s2,s2,1
    80005c8a:	09a1                	addi	s3,s3,8
    80005c8c:	fb491be3          	bne	s2,s4,80005c42 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c90:	10048913          	addi	s2,s1,256
    80005c94:	6088                	ld	a0,0(s1)
    80005c96:	c529                	beqz	a0,80005ce0 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c98:	ffffb097          	auipc	ra,0xffffb
    80005c9c:	d60080e7          	jalr	-672(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ca0:	04a1                	addi	s1,s1,8
    80005ca2:	ff2499e3          	bne	s1,s2,80005c94 <sys_exec+0xac>
  return -1;
    80005ca6:	597d                	li	s2,-1
    80005ca8:	a82d                	j	80005ce2 <sys_exec+0xfa>
      argv[i] = 0;
    80005caa:	0a8e                	slli	s5,s5,0x3
    80005cac:	fc040793          	addi	a5,s0,-64
    80005cb0:	9abe                	add	s5,s5,a5
    80005cb2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cb6:	e4040593          	addi	a1,s0,-448
    80005cba:	f4040513          	addi	a0,s0,-192
    80005cbe:	fffff097          	auipc	ra,0xfffff
    80005cc2:	194080e7          	jalr	404(ra) # 80004e52 <exec>
    80005cc6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cc8:	10048993          	addi	s3,s1,256
    80005ccc:	6088                	ld	a0,0(s1)
    80005cce:	c911                	beqz	a0,80005ce2 <sys_exec+0xfa>
    kfree(argv[i]);
    80005cd0:	ffffb097          	auipc	ra,0xffffb
    80005cd4:	d28080e7          	jalr	-728(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cd8:	04a1                	addi	s1,s1,8
    80005cda:	ff3499e3          	bne	s1,s3,80005ccc <sys_exec+0xe4>
    80005cde:	a011                	j	80005ce2 <sys_exec+0xfa>
  return -1;
    80005ce0:	597d                	li	s2,-1
}
    80005ce2:	854a                	mv	a0,s2
    80005ce4:	60be                	ld	ra,456(sp)
    80005ce6:	641e                	ld	s0,448(sp)
    80005ce8:	74fa                	ld	s1,440(sp)
    80005cea:	795a                	ld	s2,432(sp)
    80005cec:	79ba                	ld	s3,424(sp)
    80005cee:	7a1a                	ld	s4,416(sp)
    80005cf0:	6afa                	ld	s5,408(sp)
    80005cf2:	6179                	addi	sp,sp,464
    80005cf4:	8082                	ret

0000000080005cf6 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005cf6:	7139                	addi	sp,sp,-64
    80005cf8:	fc06                	sd	ra,56(sp)
    80005cfa:	f822                	sd	s0,48(sp)
    80005cfc:	f426                	sd	s1,40(sp)
    80005cfe:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d00:	ffffc097          	auipc	ra,0xffffc
    80005d04:	cc4080e7          	jalr	-828(ra) # 800019c4 <myproc>
    80005d08:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d0a:	fd840593          	addi	a1,s0,-40
    80005d0e:	4501                	li	a0,0
    80005d10:	ffffd097          	auipc	ra,0xffffd
    80005d14:	0a8080e7          	jalr	168(ra) # 80002db8 <argaddr>
    return -1;
    80005d18:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d1a:	0e054063          	bltz	a0,80005dfa <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d1e:	fc840593          	addi	a1,s0,-56
    80005d22:	fd040513          	addi	a0,s0,-48
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	dfc080e7          	jalr	-516(ra) # 80004b22 <pipealloc>
    return -1;
    80005d2e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d30:	0c054563          	bltz	a0,80005dfa <sys_pipe+0x104>
  fd0 = -1;
    80005d34:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d38:	fd043503          	ld	a0,-48(s0)
    80005d3c:	fffff097          	auipc	ra,0xfffff
    80005d40:	508080e7          	jalr	1288(ra) # 80005244 <fdalloc>
    80005d44:	fca42223          	sw	a0,-60(s0)
    80005d48:	08054c63          	bltz	a0,80005de0 <sys_pipe+0xea>
    80005d4c:	fc843503          	ld	a0,-56(s0)
    80005d50:	fffff097          	auipc	ra,0xfffff
    80005d54:	4f4080e7          	jalr	1268(ra) # 80005244 <fdalloc>
    80005d58:	fca42023          	sw	a0,-64(s0)
    80005d5c:	06054863          	bltz	a0,80005dcc <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d60:	4691                	li	a3,4
    80005d62:	fc440613          	addi	a2,s0,-60
    80005d66:	fd843583          	ld	a1,-40(s0)
    80005d6a:	6ca8                	ld	a0,88(s1)
    80005d6c:	ffffc097          	auipc	ra,0xffffc
    80005d70:	90e080e7          	jalr	-1778(ra) # 8000167a <copyout>
    80005d74:	02054063          	bltz	a0,80005d94 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d78:	4691                	li	a3,4
    80005d7a:	fc040613          	addi	a2,s0,-64
    80005d7e:	fd843583          	ld	a1,-40(s0)
    80005d82:	0591                	addi	a1,a1,4
    80005d84:	6ca8                	ld	a0,88(s1)
    80005d86:	ffffc097          	auipc	ra,0xffffc
    80005d8a:	8f4080e7          	jalr	-1804(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d8e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d90:	06055563          	bgez	a0,80005dfa <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d94:	fc442783          	lw	a5,-60(s0)
    80005d98:	07e9                	addi	a5,a5,26
    80005d9a:	078e                	slli	a5,a5,0x3
    80005d9c:	97a6                	add	a5,a5,s1
    80005d9e:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005da2:	fc042503          	lw	a0,-64(s0)
    80005da6:	0569                	addi	a0,a0,26
    80005da8:	050e                	slli	a0,a0,0x3
    80005daa:	9526                	add	a0,a0,s1
    80005dac:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005db0:	fd043503          	ld	a0,-48(s0)
    80005db4:	fffff097          	auipc	ra,0xfffff
    80005db8:	a3e080e7          	jalr	-1474(ra) # 800047f2 <fileclose>
    fileclose(wf);
    80005dbc:	fc843503          	ld	a0,-56(s0)
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	a32080e7          	jalr	-1486(ra) # 800047f2 <fileclose>
    return -1;
    80005dc8:	57fd                	li	a5,-1
    80005dca:	a805                	j	80005dfa <sys_pipe+0x104>
    if(fd0 >= 0)
    80005dcc:	fc442783          	lw	a5,-60(s0)
    80005dd0:	0007c863          	bltz	a5,80005de0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005dd4:	01a78513          	addi	a0,a5,26
    80005dd8:	050e                	slli	a0,a0,0x3
    80005dda:	9526                	add	a0,a0,s1
    80005ddc:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005de0:	fd043503          	ld	a0,-48(s0)
    80005de4:	fffff097          	auipc	ra,0xfffff
    80005de8:	a0e080e7          	jalr	-1522(ra) # 800047f2 <fileclose>
    fileclose(wf);
    80005dec:	fc843503          	ld	a0,-56(s0)
    80005df0:	fffff097          	auipc	ra,0xfffff
    80005df4:	a02080e7          	jalr	-1534(ra) # 800047f2 <fileclose>
    return -1;
    80005df8:	57fd                	li	a5,-1
}
    80005dfa:	853e                	mv	a0,a5
    80005dfc:	70e2                	ld	ra,56(sp)
    80005dfe:	7442                	ld	s0,48(sp)
    80005e00:	74a2                	ld	s1,40(sp)
    80005e02:	6121                	addi	sp,sp,64
    80005e04:	8082                	ret
	...

0000000080005e10 <kernelvec>:
    80005e10:	7111                	addi	sp,sp,-256
    80005e12:	e006                	sd	ra,0(sp)
    80005e14:	e40a                	sd	sp,8(sp)
    80005e16:	e80e                	sd	gp,16(sp)
    80005e18:	ec12                	sd	tp,24(sp)
    80005e1a:	f016                	sd	t0,32(sp)
    80005e1c:	f41a                	sd	t1,40(sp)
    80005e1e:	f81e                	sd	t2,48(sp)
    80005e20:	fc22                	sd	s0,56(sp)
    80005e22:	e0a6                	sd	s1,64(sp)
    80005e24:	e4aa                	sd	a0,72(sp)
    80005e26:	e8ae                	sd	a1,80(sp)
    80005e28:	ecb2                	sd	a2,88(sp)
    80005e2a:	f0b6                	sd	a3,96(sp)
    80005e2c:	f4ba                	sd	a4,104(sp)
    80005e2e:	f8be                	sd	a5,112(sp)
    80005e30:	fcc2                	sd	a6,120(sp)
    80005e32:	e146                	sd	a7,128(sp)
    80005e34:	e54a                	sd	s2,136(sp)
    80005e36:	e94e                	sd	s3,144(sp)
    80005e38:	ed52                	sd	s4,152(sp)
    80005e3a:	f156                	sd	s5,160(sp)
    80005e3c:	f55a                	sd	s6,168(sp)
    80005e3e:	f95e                	sd	s7,176(sp)
    80005e40:	fd62                	sd	s8,184(sp)
    80005e42:	e1e6                	sd	s9,192(sp)
    80005e44:	e5ea                	sd	s10,200(sp)
    80005e46:	e9ee                	sd	s11,208(sp)
    80005e48:	edf2                	sd	t3,216(sp)
    80005e4a:	f1f6                	sd	t4,224(sp)
    80005e4c:	f5fa                	sd	t5,232(sp)
    80005e4e:	f9fe                	sd	t6,240(sp)
    80005e50:	d79fc0ef          	jal	ra,80002bc8 <kerneltrap>
    80005e54:	6082                	ld	ra,0(sp)
    80005e56:	6122                	ld	sp,8(sp)
    80005e58:	61c2                	ld	gp,16(sp)
    80005e5a:	7282                	ld	t0,32(sp)
    80005e5c:	7322                	ld	t1,40(sp)
    80005e5e:	73c2                	ld	t2,48(sp)
    80005e60:	7462                	ld	s0,56(sp)
    80005e62:	6486                	ld	s1,64(sp)
    80005e64:	6526                	ld	a0,72(sp)
    80005e66:	65c6                	ld	a1,80(sp)
    80005e68:	6666                	ld	a2,88(sp)
    80005e6a:	7686                	ld	a3,96(sp)
    80005e6c:	7726                	ld	a4,104(sp)
    80005e6e:	77c6                	ld	a5,112(sp)
    80005e70:	7866                	ld	a6,120(sp)
    80005e72:	688a                	ld	a7,128(sp)
    80005e74:	692a                	ld	s2,136(sp)
    80005e76:	69ca                	ld	s3,144(sp)
    80005e78:	6a6a                	ld	s4,152(sp)
    80005e7a:	7a8a                	ld	s5,160(sp)
    80005e7c:	7b2a                	ld	s6,168(sp)
    80005e7e:	7bca                	ld	s7,176(sp)
    80005e80:	7c6a                	ld	s8,184(sp)
    80005e82:	6c8e                	ld	s9,192(sp)
    80005e84:	6d2e                	ld	s10,200(sp)
    80005e86:	6dce                	ld	s11,208(sp)
    80005e88:	6e6e                	ld	t3,216(sp)
    80005e8a:	7e8e                	ld	t4,224(sp)
    80005e8c:	7f2e                	ld	t5,232(sp)
    80005e8e:	7fce                	ld	t6,240(sp)
    80005e90:	6111                	addi	sp,sp,256
    80005e92:	10200073          	sret
    80005e96:	00000013          	nop
    80005e9a:	00000013          	nop
    80005e9e:	0001                	nop

0000000080005ea0 <timervec>:
    80005ea0:	34051573          	csrrw	a0,mscratch,a0
    80005ea4:	e10c                	sd	a1,0(a0)
    80005ea6:	e510                	sd	a2,8(a0)
    80005ea8:	e914                	sd	a3,16(a0)
    80005eaa:	6d0c                	ld	a1,24(a0)
    80005eac:	7110                	ld	a2,32(a0)
    80005eae:	6194                	ld	a3,0(a1)
    80005eb0:	96b2                	add	a3,a3,a2
    80005eb2:	e194                	sd	a3,0(a1)
    80005eb4:	4589                	li	a1,2
    80005eb6:	14459073          	csrw	sip,a1
    80005eba:	6914                	ld	a3,16(a0)
    80005ebc:	6510                	ld	a2,8(a0)
    80005ebe:	610c                	ld	a1,0(a0)
    80005ec0:	34051573          	csrrw	a0,mscratch,a0
    80005ec4:	30200073          	mret
	...

0000000080005eca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eca:	1141                	addi	sp,sp,-16
    80005ecc:	e422                	sd	s0,8(sp)
    80005ece:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ed0:	0c0007b7          	lui	a5,0xc000
    80005ed4:	4705                	li	a4,1
    80005ed6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ed8:	c3d8                	sw	a4,4(a5)
}
    80005eda:	6422                	ld	s0,8(sp)
    80005edc:	0141                	addi	sp,sp,16
    80005ede:	8082                	ret

0000000080005ee0 <plicinithart>:

void
plicinithart(void)
{
    80005ee0:	1141                	addi	sp,sp,-16
    80005ee2:	e406                	sd	ra,8(sp)
    80005ee4:	e022                	sd	s0,0(sp)
    80005ee6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ee8:	ffffc097          	auipc	ra,0xffffc
    80005eec:	ab0080e7          	jalr	-1360(ra) # 80001998 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ef0:	0085171b          	slliw	a4,a0,0x8
    80005ef4:	0c0027b7          	lui	a5,0xc002
    80005ef8:	97ba                	add	a5,a5,a4
    80005efa:	40200713          	li	a4,1026
    80005efe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f02:	00d5151b          	slliw	a0,a0,0xd
    80005f06:	0c2017b7          	lui	a5,0xc201
    80005f0a:	953e                	add	a0,a0,a5
    80005f0c:	00052023          	sw	zero,0(a0)
}
    80005f10:	60a2                	ld	ra,8(sp)
    80005f12:	6402                	ld	s0,0(sp)
    80005f14:	0141                	addi	sp,sp,16
    80005f16:	8082                	ret

0000000080005f18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f18:	1141                	addi	sp,sp,-16
    80005f1a:	e406                	sd	ra,8(sp)
    80005f1c:	e022                	sd	s0,0(sp)
    80005f1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f20:	ffffc097          	auipc	ra,0xffffc
    80005f24:	a78080e7          	jalr	-1416(ra) # 80001998 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f28:	00d5179b          	slliw	a5,a0,0xd
    80005f2c:	0c201537          	lui	a0,0xc201
    80005f30:	953e                	add	a0,a0,a5
  return irq;
}
    80005f32:	4148                	lw	a0,4(a0)
    80005f34:	60a2                	ld	ra,8(sp)
    80005f36:	6402                	ld	s0,0(sp)
    80005f38:	0141                	addi	sp,sp,16
    80005f3a:	8082                	ret

0000000080005f3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f3c:	1101                	addi	sp,sp,-32
    80005f3e:	ec06                	sd	ra,24(sp)
    80005f40:	e822                	sd	s0,16(sp)
    80005f42:	e426                	sd	s1,8(sp)
    80005f44:	1000                	addi	s0,sp,32
    80005f46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f48:	ffffc097          	auipc	ra,0xffffc
    80005f4c:	a50080e7          	jalr	-1456(ra) # 80001998 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f50:	00d5151b          	slliw	a0,a0,0xd
    80005f54:	0c2017b7          	lui	a5,0xc201
    80005f58:	97aa                	add	a5,a5,a0
    80005f5a:	c3c4                	sw	s1,4(a5)
}
    80005f5c:	60e2                	ld	ra,24(sp)
    80005f5e:	6442                	ld	s0,16(sp)
    80005f60:	64a2                	ld	s1,8(sp)
    80005f62:	6105                	addi	sp,sp,32
    80005f64:	8082                	ret

0000000080005f66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f66:	1141                	addi	sp,sp,-16
    80005f68:	e406                	sd	ra,8(sp)
    80005f6a:	e022                	sd	s0,0(sp)
    80005f6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f6e:	479d                	li	a5,7
    80005f70:	06a7c963          	blt	a5,a0,80005fe2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005f74:	0001d797          	auipc	a5,0x1d
    80005f78:	08c78793          	addi	a5,a5,140 # 80023000 <disk>
    80005f7c:	00a78733          	add	a4,a5,a0
    80005f80:	6789                	lui	a5,0x2
    80005f82:	97ba                	add	a5,a5,a4
    80005f84:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f88:	e7ad                	bnez	a5,80005ff2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f8a:	00451793          	slli	a5,a0,0x4
    80005f8e:	0001f717          	auipc	a4,0x1f
    80005f92:	07270713          	addi	a4,a4,114 # 80025000 <disk+0x2000>
    80005f96:	6314                	ld	a3,0(a4)
    80005f98:	96be                	add	a3,a3,a5
    80005f9a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f9e:	6314                	ld	a3,0(a4)
    80005fa0:	96be                	add	a3,a3,a5
    80005fa2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005fa6:	6314                	ld	a3,0(a4)
    80005fa8:	96be                	add	a3,a3,a5
    80005faa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005fae:	6318                	ld	a4,0(a4)
    80005fb0:	97ba                	add	a5,a5,a4
    80005fb2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005fb6:	0001d797          	auipc	a5,0x1d
    80005fba:	04a78793          	addi	a5,a5,74 # 80023000 <disk>
    80005fbe:	97aa                	add	a5,a5,a0
    80005fc0:	6509                	lui	a0,0x2
    80005fc2:	953e                	add	a0,a0,a5
    80005fc4:	4785                	li	a5,1
    80005fc6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005fca:	0001f517          	auipc	a0,0x1f
    80005fce:	04e50513          	addi	a0,a0,78 # 80025018 <disk+0x2018>
    80005fd2:	ffffc097          	auipc	ra,0xffffc
    80005fd6:	4c0080e7          	jalr	1216(ra) # 80002492 <wakeup>
}
    80005fda:	60a2                	ld	ra,8(sp)
    80005fdc:	6402                	ld	s0,0(sp)
    80005fde:	0141                	addi	sp,sp,16
    80005fe0:	8082                	ret
    panic("free_desc 1");
    80005fe2:	00002517          	auipc	a0,0x2
    80005fe6:	7d650513          	addi	a0,a0,2006 # 800087b8 <syscalls+0x330>
    80005fea:	ffffa097          	auipc	ra,0xffffa
    80005fee:	554080e7          	jalr	1364(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005ff2:	00002517          	auipc	a0,0x2
    80005ff6:	7d650513          	addi	a0,a0,2006 # 800087c8 <syscalls+0x340>
    80005ffa:	ffffa097          	auipc	ra,0xffffa
    80005ffe:	544080e7          	jalr	1348(ra) # 8000053e <panic>

0000000080006002 <virtio_disk_init>:
{
    80006002:	1101                	addi	sp,sp,-32
    80006004:	ec06                	sd	ra,24(sp)
    80006006:	e822                	sd	s0,16(sp)
    80006008:	e426                	sd	s1,8(sp)
    8000600a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000600c:	00002597          	auipc	a1,0x2
    80006010:	7cc58593          	addi	a1,a1,1996 # 800087d8 <syscalls+0x350>
    80006014:	0001f517          	auipc	a0,0x1f
    80006018:	11450513          	addi	a0,a0,276 # 80025128 <disk+0x2128>
    8000601c:	ffffb097          	auipc	ra,0xffffb
    80006020:	b38080e7          	jalr	-1224(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006024:	100017b7          	lui	a5,0x10001
    80006028:	4398                	lw	a4,0(a5)
    8000602a:	2701                	sext.w	a4,a4
    8000602c:	747277b7          	lui	a5,0x74727
    80006030:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006034:	0ef71163          	bne	a4,a5,80006116 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006038:	100017b7          	lui	a5,0x10001
    8000603c:	43dc                	lw	a5,4(a5)
    8000603e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006040:	4705                	li	a4,1
    80006042:	0ce79a63          	bne	a5,a4,80006116 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006046:	100017b7          	lui	a5,0x10001
    8000604a:	479c                	lw	a5,8(a5)
    8000604c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000604e:	4709                	li	a4,2
    80006050:	0ce79363          	bne	a5,a4,80006116 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006054:	100017b7          	lui	a5,0x10001
    80006058:	47d8                	lw	a4,12(a5)
    8000605a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000605c:	554d47b7          	lui	a5,0x554d4
    80006060:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006064:	0af71963          	bne	a4,a5,80006116 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006068:	100017b7          	lui	a5,0x10001
    8000606c:	4705                	li	a4,1
    8000606e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006070:	470d                	li	a4,3
    80006072:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006074:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006076:	c7ffe737          	lui	a4,0xc7ffe
    8000607a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000607e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006080:	2701                	sext.w	a4,a4
    80006082:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006084:	472d                	li	a4,11
    80006086:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006088:	473d                	li	a4,15
    8000608a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000608c:	6705                	lui	a4,0x1
    8000608e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006090:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006094:	5bdc                	lw	a5,52(a5)
    80006096:	2781                	sext.w	a5,a5
  if(max == 0)
    80006098:	c7d9                	beqz	a5,80006126 <virtio_disk_init+0x124>
  if(max < NUM)
    8000609a:	471d                	li	a4,7
    8000609c:	08f77d63          	bgeu	a4,a5,80006136 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060a0:	100014b7          	lui	s1,0x10001
    800060a4:	47a1                	li	a5,8
    800060a6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060a8:	6609                	lui	a2,0x2
    800060aa:	4581                	li	a1,0
    800060ac:	0001d517          	auipc	a0,0x1d
    800060b0:	f5450513          	addi	a0,a0,-172 # 80023000 <disk>
    800060b4:	ffffb097          	auipc	ra,0xffffb
    800060b8:	c2c080e7          	jalr	-980(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800060bc:	0001d717          	auipc	a4,0x1d
    800060c0:	f4470713          	addi	a4,a4,-188 # 80023000 <disk>
    800060c4:	00c75793          	srli	a5,a4,0xc
    800060c8:	2781                	sext.w	a5,a5
    800060ca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800060cc:	0001f797          	auipc	a5,0x1f
    800060d0:	f3478793          	addi	a5,a5,-204 # 80025000 <disk+0x2000>
    800060d4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800060d6:	0001d717          	auipc	a4,0x1d
    800060da:	faa70713          	addi	a4,a4,-86 # 80023080 <disk+0x80>
    800060de:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800060e0:	0001e717          	auipc	a4,0x1e
    800060e4:	f2070713          	addi	a4,a4,-224 # 80024000 <disk+0x1000>
    800060e8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060ea:	4705                	li	a4,1
    800060ec:	00e78c23          	sb	a4,24(a5)
    800060f0:	00e78ca3          	sb	a4,25(a5)
    800060f4:	00e78d23          	sb	a4,26(a5)
    800060f8:	00e78da3          	sb	a4,27(a5)
    800060fc:	00e78e23          	sb	a4,28(a5)
    80006100:	00e78ea3          	sb	a4,29(a5)
    80006104:	00e78f23          	sb	a4,30(a5)
    80006108:	00e78fa3          	sb	a4,31(a5)
}
    8000610c:	60e2                	ld	ra,24(sp)
    8000610e:	6442                	ld	s0,16(sp)
    80006110:	64a2                	ld	s1,8(sp)
    80006112:	6105                	addi	sp,sp,32
    80006114:	8082                	ret
    panic("could not find virtio disk");
    80006116:	00002517          	auipc	a0,0x2
    8000611a:	6d250513          	addi	a0,a0,1746 # 800087e8 <syscalls+0x360>
    8000611e:	ffffa097          	auipc	ra,0xffffa
    80006122:	420080e7          	jalr	1056(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006126:	00002517          	auipc	a0,0x2
    8000612a:	6e250513          	addi	a0,a0,1762 # 80008808 <syscalls+0x380>
    8000612e:	ffffa097          	auipc	ra,0xffffa
    80006132:	410080e7          	jalr	1040(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006136:	00002517          	auipc	a0,0x2
    8000613a:	6f250513          	addi	a0,a0,1778 # 80008828 <syscalls+0x3a0>
    8000613e:	ffffa097          	auipc	ra,0xffffa
    80006142:	400080e7          	jalr	1024(ra) # 8000053e <panic>

0000000080006146 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006146:	7159                	addi	sp,sp,-112
    80006148:	f486                	sd	ra,104(sp)
    8000614a:	f0a2                	sd	s0,96(sp)
    8000614c:	eca6                	sd	s1,88(sp)
    8000614e:	e8ca                	sd	s2,80(sp)
    80006150:	e4ce                	sd	s3,72(sp)
    80006152:	e0d2                	sd	s4,64(sp)
    80006154:	fc56                	sd	s5,56(sp)
    80006156:	f85a                	sd	s6,48(sp)
    80006158:	f45e                	sd	s7,40(sp)
    8000615a:	f062                	sd	s8,32(sp)
    8000615c:	ec66                	sd	s9,24(sp)
    8000615e:	e86a                	sd	s10,16(sp)
    80006160:	1880                	addi	s0,sp,112
    80006162:	892a                	mv	s2,a0
    80006164:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006166:	00c52c83          	lw	s9,12(a0)
    8000616a:	001c9c9b          	slliw	s9,s9,0x1
    8000616e:	1c82                	slli	s9,s9,0x20
    80006170:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006174:	0001f517          	auipc	a0,0x1f
    80006178:	fb450513          	addi	a0,a0,-76 # 80025128 <disk+0x2128>
    8000617c:	ffffb097          	auipc	ra,0xffffb
    80006180:	a68080e7          	jalr	-1432(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006184:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006186:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006188:	0001db97          	auipc	s7,0x1d
    8000618c:	e78b8b93          	addi	s7,s7,-392 # 80023000 <disk>
    80006190:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006192:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006194:	8a4e                	mv	s4,s3
    80006196:	a051                	j	8000621a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006198:	00fb86b3          	add	a3,s7,a5
    8000619c:	96da                	add	a3,a3,s6
    8000619e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800061a2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800061a4:	0207c563          	bltz	a5,800061ce <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061a8:	2485                	addiw	s1,s1,1
    800061aa:	0711                	addi	a4,a4,4
    800061ac:	25548063          	beq	s1,s5,800063ec <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800061b0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800061b2:	0001f697          	auipc	a3,0x1f
    800061b6:	e6668693          	addi	a3,a3,-410 # 80025018 <disk+0x2018>
    800061ba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800061bc:	0006c583          	lbu	a1,0(a3)
    800061c0:	fde1                	bnez	a1,80006198 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800061c2:	2785                	addiw	a5,a5,1
    800061c4:	0685                	addi	a3,a3,1
    800061c6:	ff879be3          	bne	a5,s8,800061bc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800061ca:	57fd                	li	a5,-1
    800061cc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800061ce:	02905a63          	blez	s1,80006202 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061d2:	f9042503          	lw	a0,-112(s0)
    800061d6:	00000097          	auipc	ra,0x0
    800061da:	d90080e7          	jalr	-624(ra) # 80005f66 <free_desc>
      for(int j = 0; j < i; j++)
    800061de:	4785                	li	a5,1
    800061e0:	0297d163          	bge	a5,s1,80006202 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061e4:	f9442503          	lw	a0,-108(s0)
    800061e8:	00000097          	auipc	ra,0x0
    800061ec:	d7e080e7          	jalr	-642(ra) # 80005f66 <free_desc>
      for(int j = 0; j < i; j++)
    800061f0:	4789                	li	a5,2
    800061f2:	0097d863          	bge	a5,s1,80006202 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061f6:	f9842503          	lw	a0,-104(s0)
    800061fa:	00000097          	auipc	ra,0x0
    800061fe:	d6c080e7          	jalr	-660(ra) # 80005f66 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006202:	0001f597          	auipc	a1,0x1f
    80006206:	f2658593          	addi	a1,a1,-218 # 80025128 <disk+0x2128>
    8000620a:	0001f517          	auipc	a0,0x1f
    8000620e:	e0e50513          	addi	a0,a0,-498 # 80025018 <disk+0x2018>
    80006212:	ffffc097          	auipc	ra,0xffffc
    80006216:	0f4080e7          	jalr	244(ra) # 80002306 <sleep>
  for(int i = 0; i < 3; i++){
    8000621a:	f9040713          	addi	a4,s0,-112
    8000621e:	84ce                	mv	s1,s3
    80006220:	bf41                	j	800061b0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006222:	20058713          	addi	a4,a1,512
    80006226:	00471693          	slli	a3,a4,0x4
    8000622a:	0001d717          	auipc	a4,0x1d
    8000622e:	dd670713          	addi	a4,a4,-554 # 80023000 <disk>
    80006232:	9736                	add	a4,a4,a3
    80006234:	4685                	li	a3,1
    80006236:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000623a:	20058713          	addi	a4,a1,512
    8000623e:	00471693          	slli	a3,a4,0x4
    80006242:	0001d717          	auipc	a4,0x1d
    80006246:	dbe70713          	addi	a4,a4,-578 # 80023000 <disk>
    8000624a:	9736                	add	a4,a4,a3
    8000624c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006250:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006254:	7679                	lui	a2,0xffffe
    80006256:	963e                	add	a2,a2,a5
    80006258:	0001f697          	auipc	a3,0x1f
    8000625c:	da868693          	addi	a3,a3,-600 # 80025000 <disk+0x2000>
    80006260:	6298                	ld	a4,0(a3)
    80006262:	9732                	add	a4,a4,a2
    80006264:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006266:	6298                	ld	a4,0(a3)
    80006268:	9732                	add	a4,a4,a2
    8000626a:	4541                	li	a0,16
    8000626c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000626e:	6298                	ld	a4,0(a3)
    80006270:	9732                	add	a4,a4,a2
    80006272:	4505                	li	a0,1
    80006274:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006278:	f9442703          	lw	a4,-108(s0)
    8000627c:	6288                	ld	a0,0(a3)
    8000627e:	962a                	add	a2,a2,a0
    80006280:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006284:	0712                	slli	a4,a4,0x4
    80006286:	6290                	ld	a2,0(a3)
    80006288:	963a                	add	a2,a2,a4
    8000628a:	05890513          	addi	a0,s2,88
    8000628e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006290:	6294                	ld	a3,0(a3)
    80006292:	96ba                	add	a3,a3,a4
    80006294:	40000613          	li	a2,1024
    80006298:	c690                	sw	a2,8(a3)
  if(write)
    8000629a:	140d0063          	beqz	s10,800063da <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000629e:	0001f697          	auipc	a3,0x1f
    800062a2:	d626b683          	ld	a3,-670(a3) # 80025000 <disk+0x2000>
    800062a6:	96ba                	add	a3,a3,a4
    800062a8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062ac:	0001d817          	auipc	a6,0x1d
    800062b0:	d5480813          	addi	a6,a6,-684 # 80023000 <disk>
    800062b4:	0001f517          	auipc	a0,0x1f
    800062b8:	d4c50513          	addi	a0,a0,-692 # 80025000 <disk+0x2000>
    800062bc:	6114                	ld	a3,0(a0)
    800062be:	96ba                	add	a3,a3,a4
    800062c0:	00c6d603          	lhu	a2,12(a3)
    800062c4:	00166613          	ori	a2,a2,1
    800062c8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062cc:	f9842683          	lw	a3,-104(s0)
    800062d0:	6110                	ld	a2,0(a0)
    800062d2:	9732                	add	a4,a4,a2
    800062d4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062d8:	20058613          	addi	a2,a1,512
    800062dc:	0612                	slli	a2,a2,0x4
    800062de:	9642                	add	a2,a2,a6
    800062e0:	577d                	li	a4,-1
    800062e2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062e6:	00469713          	slli	a4,a3,0x4
    800062ea:	6114                	ld	a3,0(a0)
    800062ec:	96ba                	add	a3,a3,a4
    800062ee:	03078793          	addi	a5,a5,48
    800062f2:	97c2                	add	a5,a5,a6
    800062f4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800062f6:	611c                	ld	a5,0(a0)
    800062f8:	97ba                	add	a5,a5,a4
    800062fa:	4685                	li	a3,1
    800062fc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062fe:	611c                	ld	a5,0(a0)
    80006300:	97ba                	add	a5,a5,a4
    80006302:	4809                	li	a6,2
    80006304:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006308:	611c                	ld	a5,0(a0)
    8000630a:	973e                	add	a4,a4,a5
    8000630c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006310:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006314:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006318:	6518                	ld	a4,8(a0)
    8000631a:	00275783          	lhu	a5,2(a4)
    8000631e:	8b9d                	andi	a5,a5,7
    80006320:	0786                	slli	a5,a5,0x1
    80006322:	97ba                	add	a5,a5,a4
    80006324:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006328:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000632c:	6518                	ld	a4,8(a0)
    8000632e:	00275783          	lhu	a5,2(a4)
    80006332:	2785                	addiw	a5,a5,1
    80006334:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006338:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000633c:	100017b7          	lui	a5,0x10001
    80006340:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006344:	00492703          	lw	a4,4(s2)
    80006348:	4785                	li	a5,1
    8000634a:	02f71163          	bne	a4,a5,8000636c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000634e:	0001f997          	auipc	s3,0x1f
    80006352:	dda98993          	addi	s3,s3,-550 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006356:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006358:	85ce                	mv	a1,s3
    8000635a:	854a                	mv	a0,s2
    8000635c:	ffffc097          	auipc	ra,0xffffc
    80006360:	faa080e7          	jalr	-86(ra) # 80002306 <sleep>
  while(b->disk == 1) {
    80006364:	00492783          	lw	a5,4(s2)
    80006368:	fe9788e3          	beq	a5,s1,80006358 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000636c:	f9042903          	lw	s2,-112(s0)
    80006370:	20090793          	addi	a5,s2,512
    80006374:	00479713          	slli	a4,a5,0x4
    80006378:	0001d797          	auipc	a5,0x1d
    8000637c:	c8878793          	addi	a5,a5,-888 # 80023000 <disk>
    80006380:	97ba                	add	a5,a5,a4
    80006382:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006386:	0001f997          	auipc	s3,0x1f
    8000638a:	c7a98993          	addi	s3,s3,-902 # 80025000 <disk+0x2000>
    8000638e:	00491713          	slli	a4,s2,0x4
    80006392:	0009b783          	ld	a5,0(s3)
    80006396:	97ba                	add	a5,a5,a4
    80006398:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000639c:	854a                	mv	a0,s2
    8000639e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063a2:	00000097          	auipc	ra,0x0
    800063a6:	bc4080e7          	jalr	-1084(ra) # 80005f66 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063aa:	8885                	andi	s1,s1,1
    800063ac:	f0ed                	bnez	s1,8000638e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063ae:	0001f517          	auipc	a0,0x1f
    800063b2:	d7a50513          	addi	a0,a0,-646 # 80025128 <disk+0x2128>
    800063b6:	ffffb097          	auipc	ra,0xffffb
    800063ba:	8e2080e7          	jalr	-1822(ra) # 80000c98 <release>
}
    800063be:	70a6                	ld	ra,104(sp)
    800063c0:	7406                	ld	s0,96(sp)
    800063c2:	64e6                	ld	s1,88(sp)
    800063c4:	6946                	ld	s2,80(sp)
    800063c6:	69a6                	ld	s3,72(sp)
    800063c8:	6a06                	ld	s4,64(sp)
    800063ca:	7ae2                	ld	s5,56(sp)
    800063cc:	7b42                	ld	s6,48(sp)
    800063ce:	7ba2                	ld	s7,40(sp)
    800063d0:	7c02                	ld	s8,32(sp)
    800063d2:	6ce2                	ld	s9,24(sp)
    800063d4:	6d42                	ld	s10,16(sp)
    800063d6:	6165                	addi	sp,sp,112
    800063d8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063da:	0001f697          	auipc	a3,0x1f
    800063de:	c266b683          	ld	a3,-986(a3) # 80025000 <disk+0x2000>
    800063e2:	96ba                	add	a3,a3,a4
    800063e4:	4609                	li	a2,2
    800063e6:	00c69623          	sh	a2,12(a3)
    800063ea:	b5c9                	j	800062ac <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063ec:	f9042583          	lw	a1,-112(s0)
    800063f0:	20058793          	addi	a5,a1,512
    800063f4:	0792                	slli	a5,a5,0x4
    800063f6:	0001d517          	auipc	a0,0x1d
    800063fa:	cb250513          	addi	a0,a0,-846 # 800230a8 <disk+0xa8>
    800063fe:	953e                	add	a0,a0,a5
  if(write)
    80006400:	e20d11e3          	bnez	s10,80006222 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006404:	20058713          	addi	a4,a1,512
    80006408:	00471693          	slli	a3,a4,0x4
    8000640c:	0001d717          	auipc	a4,0x1d
    80006410:	bf470713          	addi	a4,a4,-1036 # 80023000 <disk>
    80006414:	9736                	add	a4,a4,a3
    80006416:	0a072423          	sw	zero,168(a4)
    8000641a:	b505                	j	8000623a <virtio_disk_rw+0xf4>

000000008000641c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000641c:	1101                	addi	sp,sp,-32
    8000641e:	ec06                	sd	ra,24(sp)
    80006420:	e822                	sd	s0,16(sp)
    80006422:	e426                	sd	s1,8(sp)
    80006424:	e04a                	sd	s2,0(sp)
    80006426:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006428:	0001f517          	auipc	a0,0x1f
    8000642c:	d0050513          	addi	a0,a0,-768 # 80025128 <disk+0x2128>
    80006430:	ffffa097          	auipc	ra,0xffffa
    80006434:	7b4080e7          	jalr	1972(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006438:	10001737          	lui	a4,0x10001
    8000643c:	533c                	lw	a5,96(a4)
    8000643e:	8b8d                	andi	a5,a5,3
    80006440:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006442:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006446:	0001f797          	auipc	a5,0x1f
    8000644a:	bba78793          	addi	a5,a5,-1094 # 80025000 <disk+0x2000>
    8000644e:	6b94                	ld	a3,16(a5)
    80006450:	0207d703          	lhu	a4,32(a5)
    80006454:	0026d783          	lhu	a5,2(a3)
    80006458:	06f70163          	beq	a4,a5,800064ba <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000645c:	0001d917          	auipc	s2,0x1d
    80006460:	ba490913          	addi	s2,s2,-1116 # 80023000 <disk>
    80006464:	0001f497          	auipc	s1,0x1f
    80006468:	b9c48493          	addi	s1,s1,-1124 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000646c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006470:	6898                	ld	a4,16(s1)
    80006472:	0204d783          	lhu	a5,32(s1)
    80006476:	8b9d                	andi	a5,a5,7
    80006478:	078e                	slli	a5,a5,0x3
    8000647a:	97ba                	add	a5,a5,a4
    8000647c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000647e:	20078713          	addi	a4,a5,512
    80006482:	0712                	slli	a4,a4,0x4
    80006484:	974a                	add	a4,a4,s2
    80006486:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000648a:	e731                	bnez	a4,800064d6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000648c:	20078793          	addi	a5,a5,512
    80006490:	0792                	slli	a5,a5,0x4
    80006492:	97ca                	add	a5,a5,s2
    80006494:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006496:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000649a:	ffffc097          	auipc	ra,0xffffc
    8000649e:	ff8080e7          	jalr	-8(ra) # 80002492 <wakeup>

    disk.used_idx += 1;
    800064a2:	0204d783          	lhu	a5,32(s1)
    800064a6:	2785                	addiw	a5,a5,1
    800064a8:	17c2                	slli	a5,a5,0x30
    800064aa:	93c1                	srli	a5,a5,0x30
    800064ac:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064b0:	6898                	ld	a4,16(s1)
    800064b2:	00275703          	lhu	a4,2(a4)
    800064b6:	faf71be3          	bne	a4,a5,8000646c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800064ba:	0001f517          	auipc	a0,0x1f
    800064be:	c6e50513          	addi	a0,a0,-914 # 80025128 <disk+0x2128>
    800064c2:	ffffa097          	auipc	ra,0xffffa
    800064c6:	7d6080e7          	jalr	2006(ra) # 80000c98 <release>
}
    800064ca:	60e2                	ld	ra,24(sp)
    800064cc:	6442                	ld	s0,16(sp)
    800064ce:	64a2                	ld	s1,8(sp)
    800064d0:	6902                	ld	s2,0(sp)
    800064d2:	6105                	addi	sp,sp,32
    800064d4:	8082                	ret
      panic("virtio_disk_intr status");
    800064d6:	00002517          	auipc	a0,0x2
    800064da:	37250513          	addi	a0,a0,882 # 80008848 <syscalls+0x3c0>
    800064de:	ffffa097          	auipc	ra,0xffffa
    800064e2:	060080e7          	jalr	96(ra) # 8000053e <panic>
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
