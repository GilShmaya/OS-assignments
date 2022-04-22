
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	89013103          	ld	sp,-1904(sp) # 80008890 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	e6c78793          	addi	a5,a5,-404 # 80005ed0 <timervec>
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
    80000130:	608080e7          	jalr	1544(ra) # 80002734 <either_copyin>
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
    800001c8:	80a080e7          	jalr	-2038(ra) # 800019ce <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	14a080e7          	jalr	330(ra) # 8000231e <sleep>
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
    80000214:	4ce080e7          	jalr	1230(ra) # 800026de <either_copyout>
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
    800002f6:	498080e7          	jalr	1176(ra) # 8000278a <procdump>
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
    8000044a:	064080e7          	jalr	100(ra) # 800024aa <wakeup>
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
    800008a4:	c0a080e7          	jalr	-1014(ra) # 800024aa <wakeup>
    
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
    80000930:	9f2080e7          	jalr	-1550(ra) # 8000231e <sleep>
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
    80000b82:	e34080e7          	jalr	-460(ra) # 800019b2 <mycpu>
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
    80000bb4:	e02080e7          	jalr	-510(ra) # 800019b2 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	df6080e7          	jalr	-522(ra) # 800019b2 <mycpu>
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
    80000bd8:	dde080e7          	jalr	-546(ra) # 800019b2 <mycpu>
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
    80000c18:	d9e080e7          	jalr	-610(ra) # 800019b2 <mycpu>
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
    80000c44:	d72080e7          	jalr	-654(ra) # 800019b2 <mycpu>
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
    80000e9a:	b0c080e7          	jalr	-1268(ra) # 800019a2 <cpuid>
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
    80000eb6:	af0080e7          	jalr	-1296(ra) # 800019a2 <cpuid>
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
    80000ed8:	a96080e7          	jalr	-1386(ra) # 8000296a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	034080e7          	jalr	52(ra) # 80005f10 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	2fe080e7          	jalr	766(ra) # 800021e2 <scheduler>
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
    80000f50:	9a6080e7          	jalr	-1626(ra) # 800018f2 <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	9ee080e7          	jalr	-1554(ra) # 80002942 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	a0e080e7          	jalr	-1522(ra) # 8000296a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	f96080e7          	jalr	-106(ra) # 80005efa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	fa4080e7          	jalr	-92(ra) # 80005f10 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	184080e7          	jalr	388(ra) # 800030f8 <binit>
    iinit();         // inode table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	814080e7          	jalr	-2028(ra) # 80003790 <iinit>
    fileinit();      // file table
    80000f84:	00003097          	auipc	ra,0x3
    80000f88:	7be080e7          	jalr	1982(ra) # 80004742 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	0a6080e7          	jalr	166(ra) # 80006032 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	d1a080e7          	jalr	-742(ra) # 80001cae <userinit>
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
    8000124c:	614080e7          	jalr	1556(ra) # 8000185c <proc_mapstacks>
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
    8000184c:	00007797          	auipc	a5,0x7
    80001850:	7ec7a783          	lw	a5,2028(a5) # 80009038 <ticks>
    80001854:	dd5c                	sw	a5,60(a0)
  #endif
}  
    80001856:	6422                	ld	s0,8(sp)
    80001858:	0141                	addi	sp,sp,16
    8000185a:	8082                	ret

000000008000185c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000185c:	7139                	addi	sp,sp,-64
    8000185e:	fc06                	sd	ra,56(sp)
    80001860:	f822                	sd	s0,48(sp)
    80001862:	f426                	sd	s1,40(sp)
    80001864:	f04a                	sd	s2,32(sp)
    80001866:	ec4e                	sd	s3,24(sp)
    80001868:	e852                	sd	s4,16(sp)
    8000186a:	e456                	sd	s5,8(sp)
    8000186c:	e05a                	sd	s6,0(sp)
    8000186e:	0080                	addi	s0,sp,64
    80001870:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001872:	00010497          	auipc	s1,0x10
    80001876:	e5e48493          	addi	s1,s1,-418 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	8b26                	mv	s6,s1
    8000187c:	00006a97          	auipc	s5,0x6
    80001880:	784a8a93          	addi	s5,s5,1924 # 80008000 <etext>
    80001884:	04000937          	lui	s2,0x4000
    80001888:	197d                	addi	s2,s2,-1
    8000188a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188c:	00016a17          	auipc	s4,0x16
    80001890:	a44a0a13          	addi	s4,s4,-1468 # 800172d0 <tickslock>
    char *pa = kalloc();
    80001894:	fffff097          	auipc	ra,0xfffff
    80001898:	260080e7          	jalr	608(ra) # 80000af4 <kalloc>
    8000189c:	862a                	mv	a2,a0
    if(pa == 0)
    8000189e:	c131                	beqz	a0,800018e2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018a0:	416485b3          	sub	a1,s1,s6
    800018a4:	8591                	srai	a1,a1,0x4
    800018a6:	000ab783          	ld	a5,0(s5)
    800018aa:	02f585b3          	mul	a1,a1,a5
    800018ae:	2585                	addiw	a1,a1,1
    800018b0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018b4:	4719                	li	a4,6
    800018b6:	6685                	lui	a3,0x1
    800018b8:	40b905b3          	sub	a1,s2,a1
    800018bc:	854e                	mv	a0,s3
    800018be:	00000097          	auipc	ra,0x0
    800018c2:	89a080e7          	jalr	-1894(ra) # 80001158 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c6:	17048493          	addi	s1,s1,368
    800018ca:	fd4495e3          	bne	s1,s4,80001894 <proc_mapstacks+0x38>
  }
}
    800018ce:	70e2                	ld	ra,56(sp)
    800018d0:	7442                	ld	s0,48(sp)
    800018d2:	74a2                	ld	s1,40(sp)
    800018d4:	7902                	ld	s2,32(sp)
    800018d6:	69e2                	ld	s3,24(sp)
    800018d8:	6a42                	ld	s4,16(sp)
    800018da:	6aa2                	ld	s5,8(sp)
    800018dc:	6b02                	ld	s6,0(sp)
    800018de:	6121                	addi	sp,sp,64
    800018e0:	8082                	ret
      panic("kalloc");
    800018e2:	00007517          	auipc	a0,0x7
    800018e6:	8f650513          	addi	a0,a0,-1802 # 800081d8 <digits+0x198>
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	c54080e7          	jalr	-940(ra) # 8000053e <panic>

00000000800018f2 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018f2:	7139                	addi	sp,sp,-64
    800018f4:	fc06                	sd	ra,56(sp)
    800018f6:	f822                	sd	s0,48(sp)
    800018f8:	f426                	sd	s1,40(sp)
    800018fa:	f04a                	sd	s2,32(sp)
    800018fc:	ec4e                	sd	s3,24(sp)
    800018fe:	e852                	sd	s4,16(sp)
    80001900:	e456                	sd	s5,8(sp)
    80001902:	e05a                	sd	s6,0(sp)
    80001904:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001906:	00007597          	auipc	a1,0x7
    8000190a:	8da58593          	addi	a1,a1,-1830 # 800081e0 <digits+0x1a0>
    8000190e:	00010517          	auipc	a0,0x10
    80001912:	99250513          	addi	a0,a0,-1646 # 800112a0 <pid_lock>
    80001916:	fffff097          	auipc	ra,0xfffff
    8000191a:	23e080e7          	jalr	574(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000191e:	00007597          	auipc	a1,0x7
    80001922:	8ca58593          	addi	a1,a1,-1846 # 800081e8 <digits+0x1a8>
    80001926:	00010517          	auipc	a0,0x10
    8000192a:	99250513          	addi	a0,a0,-1646 # 800112b8 <wait_lock>
    8000192e:	fffff097          	auipc	ra,0xfffff
    80001932:	226080e7          	jalr	550(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001936:	00010497          	auipc	s1,0x10
    8000193a:	d9a48493          	addi	s1,s1,-614 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    8000193e:	00007b17          	auipc	s6,0x7
    80001942:	8bab0b13          	addi	s6,s6,-1862 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001946:	8aa6                	mv	s5,s1
    80001948:	00006a17          	auipc	s4,0x6
    8000194c:	6b8a0a13          	addi	s4,s4,1720 # 80008000 <etext>
    80001950:	04000937          	lui	s2,0x4000
    80001954:	197d                	addi	s2,s2,-1
    80001956:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001958:	00016997          	auipc	s3,0x16
    8000195c:	97898993          	addi	s3,s3,-1672 # 800172d0 <tickslock>
      initlock(&p->lock, "proc");
    80001960:	85da                	mv	a1,s6
    80001962:	8526                	mv	a0,s1
    80001964:	fffff097          	auipc	ra,0xfffff
    80001968:	1f0080e7          	jalr	496(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000196c:	415487b3          	sub	a5,s1,s5
    80001970:	8791                	srai	a5,a5,0x4
    80001972:	000a3703          	ld	a4,0(s4)
    80001976:	02e787b3          	mul	a5,a5,a4
    8000197a:	2785                	addiw	a5,a5,1
    8000197c:	00d7979b          	slliw	a5,a5,0xd
    80001980:	40f907b3          	sub	a5,s2,a5
    80001984:	e4bc                	sd	a5,72(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001986:	17048493          	addi	s1,s1,368
    8000198a:	fd349be3          	bne	s1,s3,80001960 <procinit+0x6e>
  }
}
    8000198e:	70e2                	ld	ra,56(sp)
    80001990:	7442                	ld	s0,48(sp)
    80001992:	74a2                	ld	s1,40(sp)
    80001994:	7902                	ld	s2,32(sp)
    80001996:	69e2                	ld	s3,24(sp)
    80001998:	6a42                	ld	s4,16(sp)
    8000199a:	6aa2                	ld	s5,8(sp)
    8000199c:	6b02                	ld	s6,0(sp)
    8000199e:	6121                	addi	sp,sp,64
    800019a0:	8082                	ret

00000000800019a2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019a2:	1141                	addi	sp,sp,-16
    800019a4:	e422                	sd	s0,8(sp)
    800019a6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019aa:	2501                	sext.w	a0,a0
    800019ac:	6422                	ld	s0,8(sp)
    800019ae:	0141                	addi	sp,sp,16
    800019b0:	8082                	ret

00000000800019b2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019b2:	1141                	addi	sp,sp,-16
    800019b4:	e422                	sd	s0,8(sp)
    800019b6:	0800                	addi	s0,sp,16
    800019b8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019ba:	2781                	sext.w	a5,a5
    800019bc:	079e                	slli	a5,a5,0x7
  return c;
}
    800019be:	00010517          	auipc	a0,0x10
    800019c2:	91250513          	addi	a0,a0,-1774 # 800112d0 <cpus>
    800019c6:	953e                	add	a0,a0,a5
    800019c8:	6422                	ld	s0,8(sp)
    800019ca:	0141                	addi	sp,sp,16
    800019cc:	8082                	ret

00000000800019ce <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019ce:	1101                	addi	sp,sp,-32
    800019d0:	ec06                	sd	ra,24(sp)
    800019d2:	e822                	sd	s0,16(sp)
    800019d4:	e426                	sd	s1,8(sp)
    800019d6:	1000                	addi	s0,sp,32
  push_off();
    800019d8:	fffff097          	auipc	ra,0xfffff
    800019dc:	1c0080e7          	jalr	448(ra) # 80000b98 <push_off>
    800019e0:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019e2:	2781                	sext.w	a5,a5
    800019e4:	079e                	slli	a5,a5,0x7
    800019e6:	00010717          	auipc	a4,0x10
    800019ea:	8ba70713          	addi	a4,a4,-1862 # 800112a0 <pid_lock>
    800019ee:	97ba                	add	a5,a5,a4
    800019f0:	7b84                	ld	s1,48(a5)
  pop_off();
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	246080e7          	jalr	582(ra) # 80000c38 <pop_off>
  return p;
}
    800019fa:	8526                	mv	a0,s1
    800019fc:	60e2                	ld	ra,24(sp)
    800019fe:	6442                	ld	s0,16(sp)
    80001a00:	64a2                	ld	s1,8(sp)
    80001a02:	6105                	addi	sp,sp,32
    80001a04:	8082                	ret

0000000080001a06 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a06:	1141                	addi	sp,sp,-16
    80001a08:	e406                	sd	ra,8(sp)
    80001a0a:	e022                	sd	s0,0(sp)
    80001a0c:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a0e:	00000097          	auipc	ra,0x0
    80001a12:	fc0080e7          	jalr	-64(ra) # 800019ce <myproc>
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	282080e7          	jalr	642(ra) # 80000c98 <release>

  if (first) {
    80001a1e:	00007797          	auipc	a5,0x7
    80001a22:	e227a783          	lw	a5,-478(a5) # 80008840 <first.1729>
    80001a26:	eb89                	bnez	a5,80001a38 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a28:	00001097          	auipc	ra,0x1
    80001a2c:	f5a080e7          	jalr	-166(ra) # 80002982 <usertrapret>
}
    80001a30:	60a2                	ld	ra,8(sp)
    80001a32:	6402                	ld	s0,0(sp)
    80001a34:	0141                	addi	sp,sp,16
    80001a36:	8082                	ret
    first = 0;
    80001a38:	00007797          	auipc	a5,0x7
    80001a3c:	e007a423          	sw	zero,-504(a5) # 80008840 <first.1729>
    fsinit(ROOTDEV);
    80001a40:	4505                	li	a0,1
    80001a42:	00002097          	auipc	ra,0x2
    80001a46:	cce080e7          	jalr	-818(ra) # 80003710 <fsinit>
    80001a4a:	bff9                	j	80001a28 <forkret+0x22>

0000000080001a4c <allocpid>:
allocpid() {
    80001a4c:	1101                	addi	sp,sp,-32
    80001a4e:	ec06                	sd	ra,24(sp)
    80001a50:	e822                	sd	s0,16(sp)
    80001a52:	e426                	sd	s1,8(sp)
    80001a54:	e04a                	sd	s2,0(sp)
    80001a56:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a58:	00010917          	auipc	s2,0x10
    80001a5c:	84890913          	addi	s2,s2,-1976 # 800112a0 <pid_lock>
    80001a60:	854a                	mv	a0,s2
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	182080e7          	jalr	386(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a6a:	00007797          	auipc	a5,0x7
    80001a6e:	dda78793          	addi	a5,a5,-550 # 80008844 <nextpid>
    80001a72:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a74:	0014871b          	addiw	a4,s1,1
    80001a78:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a7a:	854a                	mv	a0,s2
    80001a7c:	fffff097          	auipc	ra,0xfffff
    80001a80:	21c080e7          	jalr	540(ra) # 80000c98 <release>
}
    80001a84:	8526                	mv	a0,s1
    80001a86:	60e2                	ld	ra,24(sp)
    80001a88:	6442                	ld	s0,16(sp)
    80001a8a:	64a2                	ld	s1,8(sp)
    80001a8c:	6902                	ld	s2,0(sp)
    80001a8e:	6105                	addi	sp,sp,32
    80001a90:	8082                	ret

0000000080001a92 <proc_pagetable>:
{
    80001a92:	1101                	addi	sp,sp,-32
    80001a94:	ec06                	sd	ra,24(sp)
    80001a96:	e822                	sd	s0,16(sp)
    80001a98:	e426                	sd	s1,8(sp)
    80001a9a:	e04a                	sd	s2,0(sp)
    80001a9c:	1000                	addi	s0,sp,32
    80001a9e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aa0:	00000097          	auipc	ra,0x0
    80001aa4:	8a2080e7          	jalr	-1886(ra) # 80001342 <uvmcreate>
    80001aa8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aaa:	c121                	beqz	a0,80001aea <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aac:	4729                	li	a4,10
    80001aae:	00005697          	auipc	a3,0x5
    80001ab2:	55268693          	addi	a3,a3,1362 # 80007000 <_trampoline>
    80001ab6:	6605                	lui	a2,0x1
    80001ab8:	040005b7          	lui	a1,0x4000
    80001abc:	15fd                	addi	a1,a1,-1
    80001abe:	05b2                	slli	a1,a1,0xc
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f8080e7          	jalr	1528(ra) # 800010b8 <mappages>
    80001ac8:	02054863          	bltz	a0,80001af8 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001acc:	4719                	li	a4,6
    80001ace:	06093683          	ld	a3,96(s2)
    80001ad2:	6605                	lui	a2,0x1
    80001ad4:	020005b7          	lui	a1,0x2000
    80001ad8:	15fd                	addi	a1,a1,-1
    80001ada:	05b6                	slli	a1,a1,0xd
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	5da080e7          	jalr	1498(ra) # 800010b8 <mappages>
    80001ae6:	02054163          	bltz	a0,80001b08 <proc_pagetable+0x76>
}
    80001aea:	8526                	mv	a0,s1
    80001aec:	60e2                	ld	ra,24(sp)
    80001aee:	6442                	ld	s0,16(sp)
    80001af0:	64a2                	ld	s1,8(sp)
    80001af2:	6902                	ld	s2,0(sp)
    80001af4:	6105                	addi	sp,sp,32
    80001af6:	8082                	ret
    uvmfree(pagetable, 0);
    80001af8:	4581                	li	a1,0
    80001afa:	8526                	mv	a0,s1
    80001afc:	00000097          	auipc	ra,0x0
    80001b00:	a42080e7          	jalr	-1470(ra) # 8000153e <uvmfree>
    return 0;
    80001b04:	4481                	li	s1,0
    80001b06:	b7d5                	j	80001aea <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b08:	4681                	li	a3,0
    80001b0a:	4605                	li	a2,1
    80001b0c:	040005b7          	lui	a1,0x4000
    80001b10:	15fd                	addi	a1,a1,-1
    80001b12:	05b2                	slli	a1,a1,0xc
    80001b14:	8526                	mv	a0,s1
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	768080e7          	jalr	1896(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001b1e:	4581                	li	a1,0
    80001b20:	8526                	mv	a0,s1
    80001b22:	00000097          	auipc	ra,0x0
    80001b26:	a1c080e7          	jalr	-1508(ra) # 8000153e <uvmfree>
    return 0;
    80001b2a:	4481                	li	s1,0
    80001b2c:	bf7d                	j	80001aea <proc_pagetable+0x58>

0000000080001b2e <proc_freepagetable>:
{
    80001b2e:	1101                	addi	sp,sp,-32
    80001b30:	ec06                	sd	ra,24(sp)
    80001b32:	e822                	sd	s0,16(sp)
    80001b34:	e426                	sd	s1,8(sp)
    80001b36:	e04a                	sd	s2,0(sp)
    80001b38:	1000                	addi	s0,sp,32
    80001b3a:	84aa                	mv	s1,a0
    80001b3c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b3e:	4681                	li	a3,0
    80001b40:	4605                	li	a2,1
    80001b42:	040005b7          	lui	a1,0x4000
    80001b46:	15fd                	addi	a1,a1,-1
    80001b48:	05b2                	slli	a1,a1,0xc
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	734080e7          	jalr	1844(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b52:	4681                	li	a3,0
    80001b54:	4605                	li	a2,1
    80001b56:	020005b7          	lui	a1,0x2000
    80001b5a:	15fd                	addi	a1,a1,-1
    80001b5c:	05b6                	slli	a1,a1,0xd
    80001b5e:	8526                	mv	a0,s1
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	71e080e7          	jalr	1822(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b68:	85ca                	mv	a1,s2
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	00000097          	auipc	ra,0x0
    80001b70:	9d2080e7          	jalr	-1582(ra) # 8000153e <uvmfree>
}
    80001b74:	60e2                	ld	ra,24(sp)
    80001b76:	6442                	ld	s0,16(sp)
    80001b78:	64a2                	ld	s1,8(sp)
    80001b7a:	6902                	ld	s2,0(sp)
    80001b7c:	6105                	addi	sp,sp,32
    80001b7e:	8082                	ret

0000000080001b80 <freeproc>:
{
    80001b80:	1101                	addi	sp,sp,-32
    80001b82:	ec06                	sd	ra,24(sp)
    80001b84:	e822                	sd	s0,16(sp)
    80001b86:	e426                	sd	s1,8(sp)
    80001b88:	1000                	addi	s0,sp,32
    80001b8a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b8c:	7128                	ld	a0,96(a0)
    80001b8e:	c509                	beqz	a0,80001b98 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	e68080e7          	jalr	-408(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b98:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001b9c:	6ca8                	ld	a0,88(s1)
    80001b9e:	c511                	beqz	a0,80001baa <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ba0:	68ac                	ld	a1,80(s1)
    80001ba2:	00000097          	auipc	ra,0x0
    80001ba6:	f8c080e7          	jalr	-116(ra) # 80001b2e <proc_freepagetable>
  p->pagetable = 0;
    80001baa:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001bae:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001bb2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bb6:	0404b023          	sd	zero,64(s1)
  p->name[0] = 0;
    80001bba:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001bbe:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bc2:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bc6:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bca:	0004ac23          	sw	zero,24(s1)
}
    80001bce:	60e2                	ld	ra,24(sp)
    80001bd0:	6442                	ld	s0,16(sp)
    80001bd2:	64a2                	ld	s1,8(sp)
    80001bd4:	6105                	addi	sp,sp,32
    80001bd6:	8082                	ret

0000000080001bd8 <allocproc>:
{
    80001bd8:	1101                	addi	sp,sp,-32
    80001bda:	ec06                	sd	ra,24(sp)
    80001bdc:	e822                	sd	s0,16(sp)
    80001bde:	e426                	sd	s1,8(sp)
    80001be0:	e04a                	sd	s2,0(sp)
    80001be2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be4:	00010497          	auipc	s1,0x10
    80001be8:	aec48493          	addi	s1,s1,-1300 # 800116d0 <proc>
    80001bec:	00015917          	auipc	s2,0x15
    80001bf0:	6e490913          	addi	s2,s2,1764 # 800172d0 <tickslock>
    acquire(&p->lock);
    80001bf4:	8526                	mv	a0,s1
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	fee080e7          	jalr	-18(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001bfe:	4c9c                	lw	a5,24(s1)
    80001c00:	cf81                	beqz	a5,80001c18 <allocproc+0x40>
      release(&p->lock);
    80001c02:	8526                	mv	a0,s1
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	094080e7          	jalr	148(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0c:	17048493          	addi	s1,s1,368
    80001c10:	ff2492e3          	bne	s1,s2,80001bf4 <allocproc+0x1c>
  return 0;
    80001c14:	4481                	li	s1,0
    80001c16:	a8a9                	j	80001c70 <allocproc+0x98>
  p->pid = allocpid();
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e34080e7          	jalr	-460(ra) # 80001a4c <allocpid>
    80001c20:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c22:	4785                	li	a5,1
    80001c24:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001c26:	0204aa23          	sw	zero,52(s1)
  p->last_ticks = 0;
    80001c2a:	0204ac23          	sw	zero,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	ec6080e7          	jalr	-314(ra) # 80000af4 <kalloc>
    80001c36:	892a                	mv	s2,a0
    80001c38:	f0a8                	sd	a0,96(s1)
    80001c3a:	c131                	beqz	a0,80001c7e <allocproc+0xa6>
  p->pagetable = proc_pagetable(p);
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	00000097          	auipc	ra,0x0
    80001c42:	e54080e7          	jalr	-428(ra) # 80001a92 <proc_pagetable>
    80001c46:	892a                	mv	s2,a0
    80001c48:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001c4a:	c531                	beqz	a0,80001c96 <allocproc+0xbe>
  memset(&p->context, 0, sizeof(p->context));
    80001c4c:	07000613          	li	a2,112
    80001c50:	4581                	li	a1,0
    80001c52:	06848513          	addi	a0,s1,104
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	08a080e7          	jalr	138(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c5e:	00000797          	auipc	a5,0x0
    80001c62:	da878793          	addi	a5,a5,-600 # 80001a06 <forkret>
    80001c66:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c68:	64bc                	ld	a5,72(s1)
    80001c6a:	6705                	lui	a4,0x1
    80001c6c:	97ba                	add	a5,a5,a4
    80001c6e:	f8bc                	sd	a5,112(s1)
}
    80001c70:	8526                	mv	a0,s1
    80001c72:	60e2                	ld	ra,24(sp)
    80001c74:	6442                	ld	s0,16(sp)
    80001c76:	64a2                	ld	s1,8(sp)
    80001c78:	6902                	ld	s2,0(sp)
    80001c7a:	6105                	addi	sp,sp,32
    80001c7c:	8082                	ret
    freeproc(p);
    80001c7e:	8526                	mv	a0,s1
    80001c80:	00000097          	auipc	ra,0x0
    80001c84:	f00080e7          	jalr	-256(ra) # 80001b80 <freeproc>
    release(&p->lock);
    80001c88:	8526                	mv	a0,s1
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	00e080e7          	jalr	14(ra) # 80000c98 <release>
    return 0;
    80001c92:	84ca                	mv	s1,s2
    80001c94:	bff1                	j	80001c70 <allocproc+0x98>
    freeproc(p);
    80001c96:	8526                	mv	a0,s1
    80001c98:	00000097          	auipc	ra,0x0
    80001c9c:	ee8080e7          	jalr	-280(ra) # 80001b80 <freeproc>
    release(&p->lock);
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	ff6080e7          	jalr	-10(ra) # 80000c98 <release>
    return 0;
    80001caa:	84ca                	mv	s1,s2
    80001cac:	b7d1                	j	80001c70 <allocproc+0x98>

0000000080001cae <userinit>:
{
    80001cae:	1101                	addi	sp,sp,-32
    80001cb0:	ec06                	sd	ra,24(sp)
    80001cb2:	e822                	sd	s0,16(sp)
    80001cb4:	e426                	sd	s1,8(sp)
    80001cb6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb8:	00000097          	auipc	ra,0x0
    80001cbc:	f20080e7          	jalr	-224(ra) # 80001bd8 <allocproc>
    80001cc0:	84aa                	mv	s1,a0
  initproc = p;
    80001cc2:	00007797          	auipc	a5,0x7
    80001cc6:	36a7b723          	sd	a0,878(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cca:	03400613          	li	a2,52
    80001cce:	00007597          	auipc	a1,0x7
    80001cd2:	b8258593          	addi	a1,a1,-1150 # 80008850 <initcode>
    80001cd6:	6d28                	ld	a0,88(a0)
    80001cd8:	fffff097          	auipc	ra,0xfffff
    80001cdc:	698080e7          	jalr	1688(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001ce0:	6785                	lui	a5,0x1
    80001ce2:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ce4:	70b8                	ld	a4,96(s1)
    80001ce6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cea:	70b8                	ld	a4,96(s1)
    80001cec:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cee:	4641                	li	a2,16
    80001cf0:	00006597          	auipc	a1,0x6
    80001cf4:	51058593          	addi	a1,a1,1296 # 80008200 <digits+0x1c0>
    80001cf8:	16048513          	addi	a0,s1,352
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	136080e7          	jalr	310(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d04:	00006517          	auipc	a0,0x6
    80001d08:	50c50513          	addi	a0,a0,1292 # 80008210 <digits+0x1d0>
    80001d0c:	00002097          	auipc	ra,0x2
    80001d10:	432080e7          	jalr	1074(ra) # 8000413e <namei>
    80001d14:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001d18:	478d                	li	a5,3
    80001d1a:	cc9c                	sw	a5,24(s1)
    p->last_runnable_time = ticks;
    80001d1c:	00007797          	auipc	a5,0x7
    80001d20:	31c7a783          	lw	a5,796(a5) # 80009038 <ticks>
    80001d24:	dcdc                	sw	a5,60(s1)
  release(&p->lock);
    80001d26:	8526                	mv	a0,s1
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	f70080e7          	jalr	-144(ra) # 80000c98 <release>
}
    80001d30:	60e2                	ld	ra,24(sp)
    80001d32:	6442                	ld	s0,16(sp)
    80001d34:	64a2                	ld	s1,8(sp)
    80001d36:	6105                	addi	sp,sp,32
    80001d38:	8082                	ret

0000000080001d3a <growproc>:
{
    80001d3a:	1101                	addi	sp,sp,-32
    80001d3c:	ec06                	sd	ra,24(sp)
    80001d3e:	e822                	sd	s0,16(sp)
    80001d40:	e426                	sd	s1,8(sp)
    80001d42:	e04a                	sd	s2,0(sp)
    80001d44:	1000                	addi	s0,sp,32
    80001d46:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d48:	00000097          	auipc	ra,0x0
    80001d4c:	c86080e7          	jalr	-890(ra) # 800019ce <myproc>
    80001d50:	892a                	mv	s2,a0
  sz = p->sz;
    80001d52:	692c                	ld	a1,80(a0)
    80001d54:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d58:	00904f63          	bgtz	s1,80001d76 <growproc+0x3c>
  } else if(n < 0){
    80001d5c:	0204cc63          	bltz	s1,80001d94 <growproc+0x5a>
  p->sz = sz;
    80001d60:	1602                	slli	a2,a2,0x20
    80001d62:	9201                	srli	a2,a2,0x20
    80001d64:	04c93823          	sd	a2,80(s2)
  return 0;
    80001d68:	4501                	li	a0,0
}
    80001d6a:	60e2                	ld	ra,24(sp)
    80001d6c:	6442                	ld	s0,16(sp)
    80001d6e:	64a2                	ld	s1,8(sp)
    80001d70:	6902                	ld	s2,0(sp)
    80001d72:	6105                	addi	sp,sp,32
    80001d74:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d76:	9e25                	addw	a2,a2,s1
    80001d78:	1602                	slli	a2,a2,0x20
    80001d7a:	9201                	srli	a2,a2,0x20
    80001d7c:	1582                	slli	a1,a1,0x20
    80001d7e:	9181                	srli	a1,a1,0x20
    80001d80:	6d28                	ld	a0,88(a0)
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	6a8080e7          	jalr	1704(ra) # 8000142a <uvmalloc>
    80001d8a:	0005061b          	sext.w	a2,a0
    80001d8e:	fa69                	bnez	a2,80001d60 <growproc+0x26>
      return -1;
    80001d90:	557d                	li	a0,-1
    80001d92:	bfe1                	j	80001d6a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d94:	9e25                	addw	a2,a2,s1
    80001d96:	1602                	slli	a2,a2,0x20
    80001d98:	9201                	srli	a2,a2,0x20
    80001d9a:	1582                	slli	a1,a1,0x20
    80001d9c:	9181                	srli	a1,a1,0x20
    80001d9e:	6d28                	ld	a0,88(a0)
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	642080e7          	jalr	1602(ra) # 800013e2 <uvmdealloc>
    80001da8:	0005061b          	sext.w	a2,a0
    80001dac:	bf55                	j	80001d60 <growproc+0x26>

0000000080001dae <fork>:
{
    80001dae:	7179                	addi	sp,sp,-48
    80001db0:	f406                	sd	ra,40(sp)
    80001db2:	f022                	sd	s0,32(sp)
    80001db4:	ec26                	sd	s1,24(sp)
    80001db6:	e84a                	sd	s2,16(sp)
    80001db8:	e44e                	sd	s3,8(sp)
    80001dba:	e052                	sd	s4,0(sp)
    80001dbc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dbe:	00000097          	auipc	ra,0x0
    80001dc2:	c10080e7          	jalr	-1008(ra) # 800019ce <myproc>
    80001dc6:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dc8:	00000097          	auipc	ra,0x0
    80001dcc:	e10080e7          	jalr	-496(ra) # 80001bd8 <allocproc>
    80001dd0:	12050163          	beqz	a0,80001ef2 <fork+0x144>
    80001dd4:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dd6:	05093603          	ld	a2,80(s2)
    80001dda:	6d2c                	ld	a1,88(a0)
    80001ddc:	05893503          	ld	a0,88(s2)
    80001de0:	fffff097          	auipc	ra,0xfffff
    80001de4:	796080e7          	jalr	1942(ra) # 80001576 <uvmcopy>
    80001de8:	04054663          	bltz	a0,80001e34 <fork+0x86>
  np->sz = p->sz;
    80001dec:	05093783          	ld	a5,80(s2)
    80001df0:	04f9b823          	sd	a5,80(s3)
  *(np->trapframe) = *(p->trapframe);
    80001df4:	06093683          	ld	a3,96(s2)
    80001df8:	87b6                	mv	a5,a3
    80001dfa:	0609b703          	ld	a4,96(s3)
    80001dfe:	12068693          	addi	a3,a3,288
    80001e02:	0007b803          	ld	a6,0(a5)
    80001e06:	6788                	ld	a0,8(a5)
    80001e08:	6b8c                	ld	a1,16(a5)
    80001e0a:	6f90                	ld	a2,24(a5)
    80001e0c:	01073023          	sd	a6,0(a4)
    80001e10:	e708                	sd	a0,8(a4)
    80001e12:	eb0c                	sd	a1,16(a4)
    80001e14:	ef10                	sd	a2,24(a4)
    80001e16:	02078793          	addi	a5,a5,32
    80001e1a:	02070713          	addi	a4,a4,32
    80001e1e:	fed792e3          	bne	a5,a3,80001e02 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e22:	0609b783          	ld	a5,96(s3)
    80001e26:	0607b823          	sd	zero,112(a5)
    80001e2a:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    80001e2e:	15800a13          	li	s4,344
    80001e32:	a03d                	j	80001e60 <fork+0xb2>
    freeproc(np);
    80001e34:	854e                	mv	a0,s3
    80001e36:	00000097          	auipc	ra,0x0
    80001e3a:	d4a080e7          	jalr	-694(ra) # 80001b80 <freeproc>
    release(&np->lock);
    80001e3e:	854e                	mv	a0,s3
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	e58080e7          	jalr	-424(ra) # 80000c98 <release>
    return -1;
    80001e48:	5a7d                	li	s4,-1
    80001e4a:	a859                	j	80001ee0 <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e4c:	00003097          	auipc	ra,0x3
    80001e50:	988080e7          	jalr	-1656(ra) # 800047d4 <filedup>
    80001e54:	009987b3          	add	a5,s3,s1
    80001e58:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e5a:	04a1                	addi	s1,s1,8
    80001e5c:	01448763          	beq	s1,s4,80001e6a <fork+0xbc>
    if(p->ofile[i])
    80001e60:	009907b3          	add	a5,s2,s1
    80001e64:	6388                	ld	a0,0(a5)
    80001e66:	f17d                	bnez	a0,80001e4c <fork+0x9e>
    80001e68:	bfcd                	j	80001e5a <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e6a:	15893503          	ld	a0,344(s2)
    80001e6e:	00002097          	auipc	ra,0x2
    80001e72:	adc080e7          	jalr	-1316(ra) # 8000394a <idup>
    80001e76:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e7a:	4641                	li	a2,16
    80001e7c:	16090593          	addi	a1,s2,352
    80001e80:	16098513          	addi	a0,s3,352
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	fae080e7          	jalr	-82(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e8c:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e90:	854e                	mv	a0,s3
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	e06080e7          	jalr	-506(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e9a:	0000f497          	auipc	s1,0xf
    80001e9e:	41e48493          	addi	s1,s1,1054 # 800112b8 <wait_lock>
    80001ea2:	8526                	mv	a0,s1
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	d40080e7          	jalr	-704(ra) # 80000be4 <acquire>
  np->parent = p;
    80001eac:	0529b023          	sd	s2,64(s3)
  release(&wait_lock);
    80001eb0:	8526                	mv	a0,s1
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	de6080e7          	jalr	-538(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001eba:	854e                	mv	a0,s3
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	d28080e7          	jalr	-728(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ec4:	478d                	li	a5,3
    80001ec6:	00f9ac23          	sw	a5,24(s3)
    p->last_runnable_time = ticks;
    80001eca:	00007797          	auipc	a5,0x7
    80001ece:	16e7a783          	lw	a5,366(a5) # 80009038 <ticks>
    80001ed2:	02f92e23          	sw	a5,60(s2)
  release(&np->lock);
    80001ed6:	854e                	mv	a0,s3
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	dc0080e7          	jalr	-576(ra) # 80000c98 <release>
}
    80001ee0:	8552                	mv	a0,s4
    80001ee2:	70a2                	ld	ra,40(sp)
    80001ee4:	7402                	ld	s0,32(sp)
    80001ee6:	64e2                	ld	s1,24(sp)
    80001ee8:	6942                	ld	s2,16(sp)
    80001eea:	69a2                	ld	s3,8(sp)
    80001eec:	6a02                	ld	s4,0(sp)
    80001eee:	6145                	addi	sp,sp,48
    80001ef0:	8082                	ret
    return -1;
    80001ef2:	5a7d                	li	s4,-1
    80001ef4:	b7f5                	j	80001ee0 <fork+0x132>

0000000080001ef6 <scheduler_default>:
{
    80001ef6:	715d                	addi	sp,sp,-80
    80001ef8:	e486                	sd	ra,72(sp)
    80001efa:	e0a2                	sd	s0,64(sp)
    80001efc:	fc26                	sd	s1,56(sp)
    80001efe:	f84a                	sd	s2,48(sp)
    80001f00:	f44e                	sd	s3,40(sp)
    80001f02:	f052                	sd	s4,32(sp)
    80001f04:	ec56                	sd	s5,24(sp)
    80001f06:	e85a                	sd	s6,16(sp)
    80001f08:	e45e                	sd	s7,8(sp)
    80001f0a:	e062                	sd	s8,0(sp)
    80001f0c:	0880                	addi	s0,sp,80
    80001f0e:	8792                	mv	a5,tp
  int id = r_tp();
    80001f10:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f12:	00779c13          	slli	s8,a5,0x7
    80001f16:	0000f717          	auipc	a4,0xf
    80001f1a:	38a70713          	addi	a4,a4,906 # 800112a0 <pid_lock>
    80001f1e:	9762                	add	a4,a4,s8
    80001f20:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001f24:	0000f717          	auipc	a4,0xf
    80001f28:	3b470713          	addi	a4,a4,948 # 800112d8 <cpus+0x8>
    80001f2c:	9c3a                	add	s8,s8,a4
      if(ticks >= pause_ticks){ // check if pause signal was called
    80001f2e:	00007a17          	auipc	s4,0x7
    80001f32:	10aa0a13          	addi	s4,s4,266 # 80009038 <ticks>
    80001f36:	00007997          	auipc	s3,0x7
    80001f3a:	0f298993          	addi	s3,s3,242 # 80009028 <pause_ticks>
        if(p->state == RUNNABLE) {
    80001f3e:	4a8d                	li	s5,3
          c->proc = p;
    80001f40:	079e                	slli	a5,a5,0x7
    80001f42:	0000fb17          	auipc	s6,0xf
    80001f46:	35eb0b13          	addi	s6,s6,862 # 800112a0 <pid_lock>
    80001f4a:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f4c:	00015917          	auipc	s2,0x15
    80001f50:	38490913          	addi	s2,s2,900 # 800172d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f54:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f58:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f5c:	10079073          	csrw	sstatus,a5
    80001f60:	0000f497          	auipc	s1,0xf
    80001f64:	77048493          	addi	s1,s1,1904 # 800116d0 <proc>
          p->state = RUNNING;
    80001f68:	4b91                	li	s7,4
    80001f6a:	a03d                	j	80001f98 <scheduler_default+0xa2>
    80001f6c:	0174ac23          	sw	s7,24(s1)
          c->proc = p;
    80001f70:	029b3823          	sd	s1,48(s6)
          swtch(&c->context, &p->context);
    80001f74:	06848593          	addi	a1,s1,104
    80001f78:	8562                	mv	a0,s8
    80001f7a:	00001097          	auipc	ra,0x1
    80001f7e:	95e080e7          	jalr	-1698(ra) # 800028d8 <swtch>
          c->proc = 0;
    80001f82:	020b3823          	sd	zero,48(s6)
        release(&p->lock);
    80001f86:	8526                	mv	a0,s1
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	d10080e7          	jalr	-752(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f90:	17048493          	addi	s1,s1,368
    80001f94:	fd2480e3          	beq	s1,s2,80001f54 <scheduler_default+0x5e>
      if(ticks >= pause_ticks){ // check if pause signal was called
    80001f98:	000a2703          	lw	a4,0(s4)
    80001f9c:	0009a783          	lw	a5,0(s3)
    80001fa0:	fef768e3          	bltu	a4,a5,80001f90 <scheduler_default+0x9a>
        acquire(&p->lock);
    80001fa4:	8526                	mv	a0,s1
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	c3e080e7          	jalr	-962(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {
    80001fae:	4c9c                	lw	a5,24(s1)
    80001fb0:	fd579be3          	bne	a5,s5,80001f86 <scheduler_default+0x90>
    80001fb4:	bf65                	j	80001f6c <scheduler_default+0x76>

0000000080001fb6 <swap_process_ptr>:
{
    80001fb6:	1141                	addi	sp,sp,-16
    80001fb8:	e422                	sd	s0,8(sp)
    80001fba:	0800                	addi	s0,sp,16
  struct proc *temp = *p1;
    80001fbc:	611c                	ld	a5,0(a0)
  *p1 = *p2;
    80001fbe:	6198                	ld	a4,0(a1)
    80001fc0:	e118                	sd	a4,0(a0)
  *p2 = temp; 
    80001fc2:	e19c                	sd	a5,0(a1)
}     
    80001fc4:	6422                	ld	s0,8(sp)
    80001fc6:	0141                	addi	sp,sp,16
    80001fc8:	8082                	ret

0000000080001fca <make_acquired_process_running>:
make_acquired_process_running(struct cpu *c, struct proc *p){
    80001fca:	1101                	addi	sp,sp,-32
    80001fcc:	ec06                	sd	ra,24(sp)
    80001fce:	e822                	sd	s0,16(sp)
    80001fd0:	e426                	sd	s1,8(sp)
    80001fd2:	1000                	addi	s0,sp,32
    80001fd4:	84aa                	mv	s1,a0
  p->state = RUNNING;
    80001fd6:	4791                	li	a5,4
    80001fd8:	cd9c                	sw	a5,24(a1)
  c->proc = p;
    80001fda:	e10c                	sd	a1,0(a0)
  swtch(&c->context, &p->context);
    80001fdc:	06858593          	addi	a1,a1,104
    80001fe0:	0521                	addi	a0,a0,8
    80001fe2:	00001097          	auipc	ra,0x1
    80001fe6:	8f6080e7          	jalr	-1802(ra) # 800028d8 <swtch>
  c->proc = 0;
    80001fea:	0004b023          	sd	zero,0(s1)
}
    80001fee:	60e2                	ld	ra,24(sp)
    80001ff0:	6442                	ld	s0,16(sp)
    80001ff2:	64a2                	ld	s1,8(sp)
    80001ff4:	6105                	addi	sp,sp,32
    80001ff6:	8082                	ret

0000000080001ff8 <scheduler_sjf>:
void scheduler_sjf(void){
    80001ff8:	711d                	addi	sp,sp,-96
    80001ffa:	ec86                	sd	ra,88(sp)
    80001ffc:	e8a2                	sd	s0,80(sp)
    80001ffe:	e4a6                	sd	s1,72(sp)
    80002000:	e0ca                	sd	s2,64(sp)
    80002002:	fc4e                	sd	s3,56(sp)
    80002004:	f852                	sd	s4,48(sp)
    80002006:	f456                	sd	s5,40(sp)
    80002008:	f05a                	sd	s6,32(sp)
    8000200a:	ec5e                	sd	s7,24(sp)
    8000200c:	e862                	sd	s8,16(sp)
    8000200e:	e466                	sd	s9,8(sp)
    80002010:	e06a                	sd	s10,0(sp)
    80002012:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    80002014:	8792                	mv	a5,tp
  int id = r_tp();
    80002016:	2781                	sext.w	a5,a5
  struct cpu *c = &cpus[id];
    80002018:	079e                	slli	a5,a5,0x7
    8000201a:	0000f717          	auipc	a4,0xf
    8000201e:	2b670713          	addi	a4,a4,694 # 800112d0 <cpus>
    80002022:	00f70d33          	add	s10,a4,a5
  c->proc = 0;
    80002026:	0000f717          	auipc	a4,0xf
    8000202a:	27a70713          	addi	a4,a4,634 # 800112a0 <pid_lock>
    8000202e:	97ba                	add	a5,a5,a4
    80002030:	0207b823          	sd	zero,48(a5)
      if(ticks >= pause_ticks){ // check if pause signal was called
    80002034:	00007917          	auipc	s2,0x7
    80002038:	00490913          	addi	s2,s2,4 # 80009038 <ticks>
    8000203c:	00007a17          	auipc	s4,0x7
    80002040:	feca0a13          	addi	s4,s4,-20 # 80009028 <pause_ticks>
        if(curr->state == RUNNABLE) {
    80002044:	4a8d                	li	s5,3
          curr->mean_ticks = ((SECONDS_TO_TICKS - RATE) * curr->mean_ticks + curr->last_ticks * (RATE)) / SECONDS_TO_TICKS;
    80002046:	4ba9                	li	s7,10
    for(curr = proc; curr < &proc[NPROC]; curr++) {
    80002048:	00015997          	auipc	s3,0x15
    8000204c:	28898993          	addi	s3,s3,648 # 800172d0 <tickslock>
    p = NULL;
    80002050:	4c01                	li	s8,0
    80002052:	a8b1                	j	800020ae <scheduler_sjf+0xb6>
    80002054:	8b26                	mv	s6,s1
        release(&curr->lock);
    80002056:	8526                	mv	a0,s1
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	c40080e7          	jalr	-960(ra) # 80000c98 <release>
    for(curr = proc; curr < &proc[NPROC]; curr++) {
    80002060:	17048493          	addi	s1,s1,368
    80002064:	05348363          	beq	s1,s3,800020aa <scheduler_sjf+0xb2>
      if(ticks >= pause_ticks){ // check if pause signal was called
    80002068:	00092703          	lw	a4,0(s2)
    8000206c:	000a2783          	lw	a5,0(s4)
    80002070:	fef768e3          	bltu	a4,a5,80002060 <scheduler_sjf+0x68>
        acquire(&curr->lock);
    80002074:	8526                	mv	a0,s1
    80002076:	fffff097          	auipc	ra,0xfffff
    8000207a:	b6e080e7          	jalr	-1170(ra) # 80000be4 <acquire>
        if(curr->state == RUNNABLE) {
    8000207e:	4c9c                	lw	a5,24(s1)
    80002080:	fd579be3          	bne	a5,s5,80002056 <scheduler_sjf+0x5e>
          curr->mean_ticks = ((SECONDS_TO_TICKS - RATE) * curr->mean_ticks + curr->last_ticks * (RATE)) / SECONDS_TO_TICKS;
    80002084:	58d8                	lw	a4,52(s1)
    80002086:	0027179b          	slliw	a5,a4,0x2
    8000208a:	9fb9                	addw	a5,a5,a4
    8000208c:	0017979b          	slliw	a5,a5,0x1
    80002090:	0377d7bb          	divuw	a5,a5,s7
    80002094:	0007871b          	sext.w	a4,a5
    80002098:	d8dc                	sw	a5,52(s1)
          if(p == NULL || p->mean_ticks >= curr->mean_ticks) {
    8000209a:	fa0b0de3          	beqz	s6,80002054 <scheduler_sjf+0x5c>
    8000209e:	034b2783          	lw	a5,52(s6)
    800020a2:	fae7eae3          	bltu	a5,a4,80002056 <scheduler_sjf+0x5e>
    800020a6:	8b26                	mv	s6,s1
    800020a8:	b77d                	j	80002056 <scheduler_sjf+0x5e>
    if(p != NULL){
    800020aa:	000b1e63          	bnez	s6,800020c6 <scheduler_sjf+0xce>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020ae:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020b2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020b6:	10079073          	csrw	sstatus,a5
    for(curr = proc; curr < &proc[NPROC]; curr++) {
    800020ba:	0000f497          	auipc	s1,0xf
    800020be:	61648493          	addi	s1,s1,1558 # 800116d0 <proc>
    p = NULL;
    800020c2:	8b62                	mv	s6,s8
    800020c4:	b755                	j	80002068 <scheduler_sjf+0x70>
      acquire(&p->lock);
    800020c6:	84da                	mv	s1,s6
    800020c8:	855a                	mv	a0,s6
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	b1a080e7          	jalr	-1254(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE){
    800020d2:	018b2783          	lw	a5,24(s6)
    800020d6:	03579063          	bne	a5,s5,800020f6 <scheduler_sjf+0xfe>
        uint start = ticks;
    800020da:	00092c83          	lw	s9,0(s2)
        make_acquired_process_running(c, p);
    800020de:	85da                	mv	a1,s6
    800020e0:	856a                	mv	a0,s10
    800020e2:	00000097          	auipc	ra,0x0
    800020e6:	ee8080e7          	jalr	-280(ra) # 80001fca <make_acquired_process_running>
        p->last_ticks = ticks - start;
    800020ea:	00092783          	lw	a5,0(s2)
    800020ee:	419787bb          	subw	a5,a5,s9
    800020f2:	02fb2c23          	sw	a5,56(s6)
      release(&p->lock);
    800020f6:	8526                	mv	a0,s1
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	ba0080e7          	jalr	-1120(ra) # 80000c98 <release>
    80002100:	b77d                	j	800020ae <scheduler_sjf+0xb6>

0000000080002102 <scheduler_fcfs>:
scheduler_fcfs(void) {
    80002102:	715d                	addi	sp,sp,-80
    80002104:	e486                	sd	ra,72(sp)
    80002106:	e0a2                	sd	s0,64(sp)
    80002108:	fc26                	sd	s1,56(sp)
    8000210a:	f84a                	sd	s2,48(sp)
    8000210c:	f44e                	sd	s3,40(sp)
    8000210e:	f052                	sd	s4,32(sp)
    80002110:	ec56                	sd	s5,24(sp)
    80002112:	e85a                	sd	s6,16(sp)
    80002114:	e45e                	sd	s7,8(sp)
    80002116:	e062                	sd	s8,0(sp)
    80002118:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    8000211a:	8792                	mv	a5,tp
  int id = r_tp();
    8000211c:	2781                	sext.w	a5,a5
  struct cpu *c = &cpus[id];
    8000211e:	079e                	slli	a5,a5,0x7
    80002120:	0000f717          	auipc	a4,0xf
    80002124:	1b070713          	addi	a4,a4,432 # 800112d0 <cpus>
    80002128:	00f70c33          	add	s8,a4,a5
  c->proc = 0;
    8000212c:	0000f717          	auipc	a4,0xf
    80002130:	17470713          	addi	a4,a4,372 # 800112a0 <pid_lock>
    80002134:	97ba                	add	a5,a5,a4
    80002136:	0207b823          	sd	zero,48(a5)
      if(ticks >= pause_ticks){ // check if pause signal was called
    8000213a:	00007a17          	auipc	s4,0x7
    8000213e:	efea0a13          	addi	s4,s4,-258 # 80009038 <ticks>
    80002142:	00007997          	auipc	s3,0x7
    80002146:	ee698993          	addi	s3,s3,-282 # 80009028 <pause_ticks>
        if(curr->state == RUNNABLE) {
    8000214a:	4a8d                	li	s5,3
    for(curr = proc; curr < &proc[NPROC]; curr++) {
    8000214c:	00015917          	auipc	s2,0x15
    80002150:	18490913          	addi	s2,s2,388 # 800172d0 <tickslock>
    p = NULL;
    80002154:	4b81                	li	s7,0
    80002156:	a0a1                	j	8000219e <scheduler_fcfs+0x9c>
    80002158:	8b26                	mv	s6,s1
        release(&curr->lock);
    8000215a:	8526                	mv	a0,s1
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	b3c080e7          	jalr	-1220(ra) # 80000c98 <release>
    for(curr = proc; curr < &proc[NPROC]; curr++) {
    80002164:	17048493          	addi	s1,s1,368
    80002168:	03248963          	beq	s1,s2,8000219a <scheduler_fcfs+0x98>
      if(ticks >= pause_ticks){ // check if pause signal was called
    8000216c:	000a2703          	lw	a4,0(s4)
    80002170:	0009a783          	lw	a5,0(s3)
    80002174:	fef768e3          	bltu	a4,a5,80002164 <scheduler_fcfs+0x62>
        acquire(&curr->lock);
    80002178:	8526                	mv	a0,s1
    8000217a:	fffff097          	auipc	ra,0xfffff
    8000217e:	a6a080e7          	jalr	-1430(ra) # 80000be4 <acquire>
        if(curr->state == RUNNABLE) {
    80002182:	4c9c                	lw	a5,24(s1)
    80002184:	fd579be3          	bne	a5,s5,8000215a <scheduler_fcfs+0x58>
          if(p == NULL || p->last_runnable_time > curr->last_runnable_time) {
    80002188:	fc0b08e3          	beqz	s6,80002158 <scheduler_fcfs+0x56>
    8000218c:	03cb2703          	lw	a4,60(s6)
    80002190:	5cdc                	lw	a5,60(s1)
    80002192:	fce7f4e3          	bgeu	a5,a4,8000215a <scheduler_fcfs+0x58>
    80002196:	8b26                	mv	s6,s1
    80002198:	b7c9                	j	8000215a <scheduler_fcfs+0x58>
    if(p != NULL){
    8000219a:	000b1e63          	bnez	s6,800021b6 <scheduler_fcfs+0xb4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000219e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021a2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021a6:	10079073          	csrw	sstatus,a5
    for(curr = proc; curr < &proc[NPROC]; curr++) {
    800021aa:	0000f497          	auipc	s1,0xf
    800021ae:	52648493          	addi	s1,s1,1318 # 800116d0 <proc>
    p = NULL;
    800021b2:	8b5e                	mv	s6,s7
    800021b4:	bf65                	j	8000216c <scheduler_fcfs+0x6a>
      acquire(&p->lock);
    800021b6:	84da                	mv	s1,s6
    800021b8:	855a                	mv	a0,s6
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	a2a080e7          	jalr	-1494(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE){
    800021c2:	018b2783          	lw	a5,24(s6)
    800021c6:	01579863          	bne	a5,s5,800021d6 <scheduler_fcfs+0xd4>
        make_acquired_process_running(c, p);
    800021ca:	85da                	mv	a1,s6
    800021cc:	8562                	mv	a0,s8
    800021ce:	00000097          	auipc	ra,0x0
    800021d2:	dfc080e7          	jalr	-516(ra) # 80001fca <make_acquired_process_running>
      release(&p->lock);
    800021d6:	8526                	mv	a0,s1
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	ac0080e7          	jalr	-1344(ra) # 80000c98 <release>
    800021e0:	bf7d                	j	8000219e <scheduler_fcfs+0x9c>

00000000800021e2 <scheduler>:
{
    800021e2:	1141                	addi	sp,sp,-16
    800021e4:	e406                	sd	ra,8(sp)
    800021e6:	e022                	sd	s0,0(sp)
    800021e8:	0800                	addi	s0,sp,16
    printf("FCFS scheduler mode\n");
    800021ea:	00006517          	auipc	a0,0x6
    800021ee:	02e50513          	addi	a0,a0,46 # 80008218 <digits+0x1d8>
    800021f2:	ffffe097          	auipc	ra,0xffffe
    800021f6:	396080e7          	jalr	918(ra) # 80000588 <printf>
    scheduler_fcfs();
    800021fa:	00000097          	auipc	ra,0x0
    800021fe:	f08080e7          	jalr	-248(ra) # 80002102 <scheduler_fcfs>

0000000080002202 <sched>:
{
    80002202:	7179                	addi	sp,sp,-48
    80002204:	f406                	sd	ra,40(sp)
    80002206:	f022                	sd	s0,32(sp)
    80002208:	ec26                	sd	s1,24(sp)
    8000220a:	e84a                	sd	s2,16(sp)
    8000220c:	e44e                	sd	s3,8(sp)
    8000220e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	7be080e7          	jalr	1982(ra) # 800019ce <myproc>
    80002218:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	950080e7          	jalr	-1712(ra) # 80000b6a <holding>
    80002222:	c93d                	beqz	a0,80002298 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002224:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002226:	2781                	sext.w	a5,a5
    80002228:	079e                	slli	a5,a5,0x7
    8000222a:	0000f717          	auipc	a4,0xf
    8000222e:	07670713          	addi	a4,a4,118 # 800112a0 <pid_lock>
    80002232:	97ba                	add	a5,a5,a4
    80002234:	0a87a703          	lw	a4,168(a5)
    80002238:	4785                	li	a5,1
    8000223a:	06f71763          	bne	a4,a5,800022a8 <sched+0xa6>
  if(p->state == RUNNING)
    8000223e:	4c98                	lw	a4,24(s1)
    80002240:	4791                	li	a5,4
    80002242:	06f70b63          	beq	a4,a5,800022b8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002246:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000224a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000224c:	efb5                	bnez	a5,800022c8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000224e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002250:	0000f917          	auipc	s2,0xf
    80002254:	05090913          	addi	s2,s2,80 # 800112a0 <pid_lock>
    80002258:	2781                	sext.w	a5,a5
    8000225a:	079e                	slli	a5,a5,0x7
    8000225c:	97ca                	add	a5,a5,s2
    8000225e:	0ac7a983          	lw	s3,172(a5)
    80002262:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002264:	2781                	sext.w	a5,a5
    80002266:	079e                	slli	a5,a5,0x7
    80002268:	0000f597          	auipc	a1,0xf
    8000226c:	07058593          	addi	a1,a1,112 # 800112d8 <cpus+0x8>
    80002270:	95be                	add	a1,a1,a5
    80002272:	06848513          	addi	a0,s1,104
    80002276:	00000097          	auipc	ra,0x0
    8000227a:	662080e7          	jalr	1634(ra) # 800028d8 <swtch>
    8000227e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002280:	2781                	sext.w	a5,a5
    80002282:	079e                	slli	a5,a5,0x7
    80002284:	97ca                	add	a5,a5,s2
    80002286:	0b37a623          	sw	s3,172(a5)
}
    8000228a:	70a2                	ld	ra,40(sp)
    8000228c:	7402                	ld	s0,32(sp)
    8000228e:	64e2                	ld	s1,24(sp)
    80002290:	6942                	ld	s2,16(sp)
    80002292:	69a2                	ld	s3,8(sp)
    80002294:	6145                	addi	sp,sp,48
    80002296:	8082                	ret
    panic("sched p->lock");
    80002298:	00006517          	auipc	a0,0x6
    8000229c:	f9850513          	addi	a0,a0,-104 # 80008230 <digits+0x1f0>
    800022a0:	ffffe097          	auipc	ra,0xffffe
    800022a4:	29e080e7          	jalr	670(ra) # 8000053e <panic>
    panic("sched locks");
    800022a8:	00006517          	auipc	a0,0x6
    800022ac:	f9850513          	addi	a0,a0,-104 # 80008240 <digits+0x200>
    800022b0:	ffffe097          	auipc	ra,0xffffe
    800022b4:	28e080e7          	jalr	654(ra) # 8000053e <panic>
    panic("sched running");
    800022b8:	00006517          	auipc	a0,0x6
    800022bc:	f9850513          	addi	a0,a0,-104 # 80008250 <digits+0x210>
    800022c0:	ffffe097          	auipc	ra,0xffffe
    800022c4:	27e080e7          	jalr	638(ra) # 8000053e <panic>
    panic("sched interruptible");
    800022c8:	00006517          	auipc	a0,0x6
    800022cc:	f9850513          	addi	a0,a0,-104 # 80008260 <digits+0x220>
    800022d0:	ffffe097          	auipc	ra,0xffffe
    800022d4:	26e080e7          	jalr	622(ra) # 8000053e <panic>

00000000800022d8 <yield>:
{
    800022d8:	1101                	addi	sp,sp,-32
    800022da:	ec06                	sd	ra,24(sp)
    800022dc:	e822                	sd	s0,16(sp)
    800022de:	e426                	sd	s1,8(sp)
    800022e0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	6ec080e7          	jalr	1772(ra) # 800019ce <myproc>
    800022ea:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	8f8080e7          	jalr	-1800(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800022f4:	478d                	li	a5,3
    800022f6:	cc9c                	sw	a5,24(s1)
    p->last_runnable_time = ticks;
    800022f8:	00007797          	auipc	a5,0x7
    800022fc:	d407a783          	lw	a5,-704(a5) # 80009038 <ticks>
    80002300:	dcdc                	sw	a5,60(s1)
  sched();
    80002302:	00000097          	auipc	ra,0x0
    80002306:	f00080e7          	jalr	-256(ra) # 80002202 <sched>
  release(&p->lock);
    8000230a:	8526                	mv	a0,s1
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	98c080e7          	jalr	-1652(ra) # 80000c98 <release>
}
    80002314:	60e2                	ld	ra,24(sp)
    80002316:	6442                	ld	s0,16(sp)
    80002318:	64a2                	ld	s1,8(sp)
    8000231a:	6105                	addi	sp,sp,32
    8000231c:	8082                	ret

000000008000231e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000231e:	7179                	addi	sp,sp,-48
    80002320:	f406                	sd	ra,40(sp)
    80002322:	f022                	sd	s0,32(sp)
    80002324:	ec26                	sd	s1,24(sp)
    80002326:	e84a                	sd	s2,16(sp)
    80002328:	e44e                	sd	s3,8(sp)
    8000232a:	1800                	addi	s0,sp,48
    8000232c:	89aa                	mv	s3,a0
    8000232e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	69e080e7          	jalr	1694(ra) # 800019ce <myproc>
    80002338:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	8aa080e7          	jalr	-1878(ra) # 80000be4 <acquire>
  release(lk);
    80002342:	854a                	mv	a0,s2
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	954080e7          	jalr	-1708(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000234c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002350:	4789                	li	a5,2
    80002352:	cc9c                	sw	a5,24(s1)

  sched();
    80002354:	00000097          	auipc	ra,0x0
    80002358:	eae080e7          	jalr	-338(ra) # 80002202 <sched>

  // Tidy up.
  p->chan = 0;
    8000235c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002360:	8526                	mv	a0,s1
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	936080e7          	jalr	-1738(ra) # 80000c98 <release>
  acquire(lk);
    8000236a:	854a                	mv	a0,s2
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	878080e7          	jalr	-1928(ra) # 80000be4 <acquire>
}
    80002374:	70a2                	ld	ra,40(sp)
    80002376:	7402                	ld	s0,32(sp)
    80002378:	64e2                	ld	s1,24(sp)
    8000237a:	6942                	ld	s2,16(sp)
    8000237c:	69a2                	ld	s3,8(sp)
    8000237e:	6145                	addi	sp,sp,48
    80002380:	8082                	ret

0000000080002382 <wait>:
{
    80002382:	715d                	addi	sp,sp,-80
    80002384:	e486                	sd	ra,72(sp)
    80002386:	e0a2                	sd	s0,64(sp)
    80002388:	fc26                	sd	s1,56(sp)
    8000238a:	f84a                	sd	s2,48(sp)
    8000238c:	f44e                	sd	s3,40(sp)
    8000238e:	f052                	sd	s4,32(sp)
    80002390:	ec56                	sd	s5,24(sp)
    80002392:	e85a                	sd	s6,16(sp)
    80002394:	e45e                	sd	s7,8(sp)
    80002396:	e062                	sd	s8,0(sp)
    80002398:	0880                	addi	s0,sp,80
    8000239a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	632080e7          	jalr	1586(ra) # 800019ce <myproc>
    800023a4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023a6:	0000f517          	auipc	a0,0xf
    800023aa:	f1250513          	addi	a0,a0,-238 # 800112b8 <wait_lock>
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	836080e7          	jalr	-1994(ra) # 80000be4 <acquire>
    havekids = 0;
    800023b6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800023b8:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800023ba:	00015997          	auipc	s3,0x15
    800023be:	f1698993          	addi	s3,s3,-234 # 800172d0 <tickslock>
        havekids = 1;
    800023c2:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023c4:	0000fc17          	auipc	s8,0xf
    800023c8:	ef4c0c13          	addi	s8,s8,-268 # 800112b8 <wait_lock>
    havekids = 0;
    800023cc:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023ce:	0000f497          	auipc	s1,0xf
    800023d2:	30248493          	addi	s1,s1,770 # 800116d0 <proc>
    800023d6:	a0bd                	j	80002444 <wait+0xc2>
          pid = np->pid;
    800023d8:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023dc:	000b0e63          	beqz	s6,800023f8 <wait+0x76>
    800023e0:	4691                	li	a3,4
    800023e2:	02c48613          	addi	a2,s1,44
    800023e6:	85da                	mv	a1,s6
    800023e8:	05893503          	ld	a0,88(s2)
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	28e080e7          	jalr	654(ra) # 8000167a <copyout>
    800023f4:	02054563          	bltz	a0,8000241e <wait+0x9c>
          freeproc(np);
    800023f8:	8526                	mv	a0,s1
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	786080e7          	jalr	1926(ra) # 80001b80 <freeproc>
          release(&np->lock);
    80002402:	8526                	mv	a0,s1
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	894080e7          	jalr	-1900(ra) # 80000c98 <release>
          release(&wait_lock);
    8000240c:	0000f517          	auipc	a0,0xf
    80002410:	eac50513          	addi	a0,a0,-340 # 800112b8 <wait_lock>
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	884080e7          	jalr	-1916(ra) # 80000c98 <release>
          return pid;
    8000241c:	a09d                	j	80002482 <wait+0x100>
            release(&np->lock);
    8000241e:	8526                	mv	a0,s1
    80002420:	fffff097          	auipc	ra,0xfffff
    80002424:	878080e7          	jalr	-1928(ra) # 80000c98 <release>
            release(&wait_lock);
    80002428:	0000f517          	auipc	a0,0xf
    8000242c:	e9050513          	addi	a0,a0,-368 # 800112b8 <wait_lock>
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	868080e7          	jalr	-1944(ra) # 80000c98 <release>
            return -1;
    80002438:	59fd                	li	s3,-1
    8000243a:	a0a1                	j	80002482 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000243c:	17048493          	addi	s1,s1,368
    80002440:	03348463          	beq	s1,s3,80002468 <wait+0xe6>
      if(np->parent == p){
    80002444:	60bc                	ld	a5,64(s1)
    80002446:	ff279be3          	bne	a5,s2,8000243c <wait+0xba>
        acquire(&np->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	ffffe097          	auipc	ra,0xffffe
    80002450:	798080e7          	jalr	1944(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002454:	4c9c                	lw	a5,24(s1)
    80002456:	f94781e3          	beq	a5,s4,800023d8 <wait+0x56>
        release(&np->lock);
    8000245a:	8526                	mv	a0,s1
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	83c080e7          	jalr	-1988(ra) # 80000c98 <release>
        havekids = 1;
    80002464:	8756                	mv	a4,s5
    80002466:	bfd9                	j	8000243c <wait+0xba>
    if(!havekids || p->killed){
    80002468:	c701                	beqz	a4,80002470 <wait+0xee>
    8000246a:	02892783          	lw	a5,40(s2)
    8000246e:	c79d                	beqz	a5,8000249c <wait+0x11a>
      release(&wait_lock);
    80002470:	0000f517          	auipc	a0,0xf
    80002474:	e4850513          	addi	a0,a0,-440 # 800112b8 <wait_lock>
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	820080e7          	jalr	-2016(ra) # 80000c98 <release>
      return -1;
    80002480:	59fd                	li	s3,-1
}
    80002482:	854e                	mv	a0,s3
    80002484:	60a6                	ld	ra,72(sp)
    80002486:	6406                	ld	s0,64(sp)
    80002488:	74e2                	ld	s1,56(sp)
    8000248a:	7942                	ld	s2,48(sp)
    8000248c:	79a2                	ld	s3,40(sp)
    8000248e:	7a02                	ld	s4,32(sp)
    80002490:	6ae2                	ld	s5,24(sp)
    80002492:	6b42                	ld	s6,16(sp)
    80002494:	6ba2                	ld	s7,8(sp)
    80002496:	6c02                	ld	s8,0(sp)
    80002498:	6161                	addi	sp,sp,80
    8000249a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000249c:	85e2                	mv	a1,s8
    8000249e:	854a                	mv	a0,s2
    800024a0:	00000097          	auipc	ra,0x0
    800024a4:	e7e080e7          	jalr	-386(ra) # 8000231e <sleep>
    havekids = 0;
    800024a8:	b715                	j	800023cc <wait+0x4a>

00000000800024aa <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800024aa:	7139                	addi	sp,sp,-64
    800024ac:	fc06                	sd	ra,56(sp)
    800024ae:	f822                	sd	s0,48(sp)
    800024b0:	f426                	sd	s1,40(sp)
    800024b2:	f04a                	sd	s2,32(sp)
    800024b4:	ec4e                	sd	s3,24(sp)
    800024b6:	e852                	sd	s4,16(sp)
    800024b8:	e456                	sd	s5,8(sp)
    800024ba:	e05a                	sd	s6,0(sp)
    800024bc:	0080                	addi	s0,sp,64
    800024be:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800024c0:	0000f497          	auipc	s1,0xf
    800024c4:	21048493          	addi	s1,s1,528 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800024c8:	4989                	li	s3,2
        p->state = RUNNABLE;
    800024ca:	4b0d                	li	s6,3
    p->last_runnable_time = ticks;
    800024cc:	00007a97          	auipc	s5,0x7
    800024d0:	b6ca8a93          	addi	s5,s5,-1172 # 80009038 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024d4:	00015917          	auipc	s2,0x15
    800024d8:	dfc90913          	addi	s2,s2,-516 # 800172d0 <tickslock>
    800024dc:	a811                	j	800024f0 <wakeup+0x46>
        update_last_runnable_time(p);
      }
      release(&p->lock);
    800024de:	8526                	mv	a0,s1
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	7b8080e7          	jalr	1976(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024e8:	17048493          	addi	s1,s1,368
    800024ec:	03248963          	beq	s1,s2,8000251e <wakeup+0x74>
    if(p != myproc()){
    800024f0:	fffff097          	auipc	ra,0xfffff
    800024f4:	4de080e7          	jalr	1246(ra) # 800019ce <myproc>
    800024f8:	fea488e3          	beq	s1,a0,800024e8 <wakeup+0x3e>
      acquire(&p->lock);
    800024fc:	8526                	mv	a0,s1
    800024fe:	ffffe097          	auipc	ra,0xffffe
    80002502:	6e6080e7          	jalr	1766(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002506:	4c9c                	lw	a5,24(s1)
    80002508:	fd379be3          	bne	a5,s3,800024de <wakeup+0x34>
    8000250c:	709c                	ld	a5,32(s1)
    8000250e:	fd4798e3          	bne	a5,s4,800024de <wakeup+0x34>
        p->state = RUNNABLE;
    80002512:	0164ac23          	sw	s6,24(s1)
    p->last_runnable_time = ticks;
    80002516:	000aa783          	lw	a5,0(s5)
    8000251a:	dcdc                	sw	a5,60(s1)
}  
    8000251c:	b7c9                	j	800024de <wakeup+0x34>
    }
  }
}
    8000251e:	70e2                	ld	ra,56(sp)
    80002520:	7442                	ld	s0,48(sp)
    80002522:	74a2                	ld	s1,40(sp)
    80002524:	7902                	ld	s2,32(sp)
    80002526:	69e2                	ld	s3,24(sp)
    80002528:	6a42                	ld	s4,16(sp)
    8000252a:	6aa2                	ld	s5,8(sp)
    8000252c:	6b02                	ld	s6,0(sp)
    8000252e:	6121                	addi	sp,sp,64
    80002530:	8082                	ret

0000000080002532 <reparent>:
{
    80002532:	7179                	addi	sp,sp,-48
    80002534:	f406                	sd	ra,40(sp)
    80002536:	f022                	sd	s0,32(sp)
    80002538:	ec26                	sd	s1,24(sp)
    8000253a:	e84a                	sd	s2,16(sp)
    8000253c:	e44e                	sd	s3,8(sp)
    8000253e:	e052                	sd	s4,0(sp)
    80002540:	1800                	addi	s0,sp,48
    80002542:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002544:	0000f497          	auipc	s1,0xf
    80002548:	18c48493          	addi	s1,s1,396 # 800116d0 <proc>
      pp->parent = initproc;
    8000254c:	00007a17          	auipc	s4,0x7
    80002550:	ae4a0a13          	addi	s4,s4,-1308 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002554:	00015997          	auipc	s3,0x15
    80002558:	d7c98993          	addi	s3,s3,-644 # 800172d0 <tickslock>
    8000255c:	a029                	j	80002566 <reparent+0x34>
    8000255e:	17048493          	addi	s1,s1,368
    80002562:	01348d63          	beq	s1,s3,8000257c <reparent+0x4a>
    if(pp->parent == p){
    80002566:	60bc                	ld	a5,64(s1)
    80002568:	ff279be3          	bne	a5,s2,8000255e <reparent+0x2c>
      pp->parent = initproc;
    8000256c:	000a3503          	ld	a0,0(s4)
    80002570:	e0a8                	sd	a0,64(s1)
      wakeup(initproc);
    80002572:	00000097          	auipc	ra,0x0
    80002576:	f38080e7          	jalr	-200(ra) # 800024aa <wakeup>
    8000257a:	b7d5                	j	8000255e <reparent+0x2c>
}
    8000257c:	70a2                	ld	ra,40(sp)
    8000257e:	7402                	ld	s0,32(sp)
    80002580:	64e2                	ld	s1,24(sp)
    80002582:	6942                	ld	s2,16(sp)
    80002584:	69a2                	ld	s3,8(sp)
    80002586:	6a02                	ld	s4,0(sp)
    80002588:	6145                	addi	sp,sp,48
    8000258a:	8082                	ret

000000008000258c <exit>:
{
    8000258c:	7179                	addi	sp,sp,-48
    8000258e:	f406                	sd	ra,40(sp)
    80002590:	f022                	sd	s0,32(sp)
    80002592:	ec26                	sd	s1,24(sp)
    80002594:	e84a                	sd	s2,16(sp)
    80002596:	e44e                	sd	s3,8(sp)
    80002598:	e052                	sd	s4,0(sp)
    8000259a:	1800                	addi	s0,sp,48
    8000259c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000259e:	fffff097          	auipc	ra,0xfffff
    800025a2:	430080e7          	jalr	1072(ra) # 800019ce <myproc>
    800025a6:	89aa                	mv	s3,a0
  if(p == initproc)
    800025a8:	00007797          	auipc	a5,0x7
    800025ac:	a887b783          	ld	a5,-1400(a5) # 80009030 <initproc>
    800025b0:	0d850493          	addi	s1,a0,216
    800025b4:	15850913          	addi	s2,a0,344
    800025b8:	02a79363          	bne	a5,a0,800025de <exit+0x52>
    panic("init exiting");
    800025bc:	00006517          	auipc	a0,0x6
    800025c0:	cbc50513          	addi	a0,a0,-836 # 80008278 <digits+0x238>
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	f7a080e7          	jalr	-134(ra) # 8000053e <panic>
      fileclose(f);
    800025cc:	00002097          	auipc	ra,0x2
    800025d0:	25a080e7          	jalr	602(ra) # 80004826 <fileclose>
      p->ofile[fd] = 0;
    800025d4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800025d8:	04a1                	addi	s1,s1,8
    800025da:	01248563          	beq	s1,s2,800025e4 <exit+0x58>
    if(p->ofile[fd]){
    800025de:	6088                	ld	a0,0(s1)
    800025e0:	f575                	bnez	a0,800025cc <exit+0x40>
    800025e2:	bfdd                	j	800025d8 <exit+0x4c>
  begin_op();
    800025e4:	00002097          	auipc	ra,0x2
    800025e8:	d76080e7          	jalr	-650(ra) # 8000435a <begin_op>
  iput(p->cwd);
    800025ec:	1589b503          	ld	a0,344(s3)
    800025f0:	00001097          	auipc	ra,0x1
    800025f4:	552080e7          	jalr	1362(ra) # 80003b42 <iput>
  end_op();
    800025f8:	00002097          	auipc	ra,0x2
    800025fc:	de2080e7          	jalr	-542(ra) # 800043da <end_op>
  p->cwd = 0;
    80002600:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    80002604:	0000f497          	auipc	s1,0xf
    80002608:	cb448493          	addi	s1,s1,-844 # 800112b8 <wait_lock>
    8000260c:	8526                	mv	a0,s1
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	5d6080e7          	jalr	1494(ra) # 80000be4 <acquire>
  reparent(p);
    80002616:	854e                	mv	a0,s3
    80002618:	00000097          	auipc	ra,0x0
    8000261c:	f1a080e7          	jalr	-230(ra) # 80002532 <reparent>
  wakeup(p->parent);
    80002620:	0409b503          	ld	a0,64(s3)
    80002624:	00000097          	auipc	ra,0x0
    80002628:	e86080e7          	jalr	-378(ra) # 800024aa <wakeup>
  acquire(&p->lock);
    8000262c:	854e                	mv	a0,s3
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	5b6080e7          	jalr	1462(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002636:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000263a:	4795                	li	a5,5
    8000263c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002640:	8526                	mv	a0,s1
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	656080e7          	jalr	1622(ra) # 80000c98 <release>
  sched();
    8000264a:	00000097          	auipc	ra,0x0
    8000264e:	bb8080e7          	jalr	-1096(ra) # 80002202 <sched>
  panic("zombie exit");
    80002652:	00006517          	auipc	a0,0x6
    80002656:	c3650513          	addi	a0,a0,-970 # 80008288 <digits+0x248>
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	ee4080e7          	jalr	-284(ra) # 8000053e <panic>

0000000080002662 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002662:	7179                	addi	sp,sp,-48
    80002664:	f406                	sd	ra,40(sp)
    80002666:	f022                	sd	s0,32(sp)
    80002668:	ec26                	sd	s1,24(sp)
    8000266a:	e84a                	sd	s2,16(sp)
    8000266c:	e44e                	sd	s3,8(sp)
    8000266e:	1800                	addi	s0,sp,48
    80002670:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002672:	0000f497          	auipc	s1,0xf
    80002676:	05e48493          	addi	s1,s1,94 # 800116d0 <proc>
    8000267a:	00015997          	auipc	s3,0x15
    8000267e:	c5698993          	addi	s3,s3,-938 # 800172d0 <tickslock>
    acquire(&p->lock);
    80002682:	8526                	mv	a0,s1
    80002684:	ffffe097          	auipc	ra,0xffffe
    80002688:	560080e7          	jalr	1376(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000268c:	589c                	lw	a5,48(s1)
    8000268e:	01278d63          	beq	a5,s2,800026a8 <kill+0x46>
        update_last_runnable_time(p);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002692:	8526                	mv	a0,s1
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	604080e7          	jalr	1540(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000269c:	17048493          	addi	s1,s1,368
    800026a0:	ff3491e3          	bne	s1,s3,80002682 <kill+0x20>
  }
  return -1;
    800026a4:	557d                	li	a0,-1
    800026a6:	a829                	j	800026c0 <kill+0x5e>
      p->killed = 1;
    800026a8:	4785                	li	a5,1
    800026aa:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800026ac:	4c98                	lw	a4,24(s1)
    800026ae:	4789                	li	a5,2
    800026b0:	00f70f63          	beq	a4,a5,800026ce <kill+0x6c>
      release(&p->lock);
    800026b4:	8526                	mv	a0,s1
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	5e2080e7          	jalr	1506(ra) # 80000c98 <release>
      return 0;
    800026be:	4501                	li	a0,0
}
    800026c0:	70a2                	ld	ra,40(sp)
    800026c2:	7402                	ld	s0,32(sp)
    800026c4:	64e2                	ld	s1,24(sp)
    800026c6:	6942                	ld	s2,16(sp)
    800026c8:	69a2                	ld	s3,8(sp)
    800026ca:	6145                	addi	sp,sp,48
    800026cc:	8082                	ret
        p->state = RUNNABLE;
    800026ce:	478d                	li	a5,3
    800026d0:	cc9c                	sw	a5,24(s1)
    p->last_runnable_time = ticks;
    800026d2:	00007797          	auipc	a5,0x7
    800026d6:	9667a783          	lw	a5,-1690(a5) # 80009038 <ticks>
    800026da:	dcdc                	sw	a5,60(s1)
}  
    800026dc:	bfe1                	j	800026b4 <kill+0x52>

00000000800026de <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026de:	7179                	addi	sp,sp,-48
    800026e0:	f406                	sd	ra,40(sp)
    800026e2:	f022                	sd	s0,32(sp)
    800026e4:	ec26                	sd	s1,24(sp)
    800026e6:	e84a                	sd	s2,16(sp)
    800026e8:	e44e                	sd	s3,8(sp)
    800026ea:	e052                	sd	s4,0(sp)
    800026ec:	1800                	addi	s0,sp,48
    800026ee:	84aa                	mv	s1,a0
    800026f0:	892e                	mv	s2,a1
    800026f2:	89b2                	mv	s3,a2
    800026f4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026f6:	fffff097          	auipc	ra,0xfffff
    800026fa:	2d8080e7          	jalr	728(ra) # 800019ce <myproc>
  if(user_dst){
    800026fe:	c08d                	beqz	s1,80002720 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002700:	86d2                	mv	a3,s4
    80002702:	864e                	mv	a2,s3
    80002704:	85ca                	mv	a1,s2
    80002706:	6d28                	ld	a0,88(a0)
    80002708:	fffff097          	auipc	ra,0xfffff
    8000270c:	f72080e7          	jalr	-142(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002710:	70a2                	ld	ra,40(sp)
    80002712:	7402                	ld	s0,32(sp)
    80002714:	64e2                	ld	s1,24(sp)
    80002716:	6942                	ld	s2,16(sp)
    80002718:	69a2                	ld	s3,8(sp)
    8000271a:	6a02                	ld	s4,0(sp)
    8000271c:	6145                	addi	sp,sp,48
    8000271e:	8082                	ret
    memmove((char *)dst, src, len);
    80002720:	000a061b          	sext.w	a2,s4
    80002724:	85ce                	mv	a1,s3
    80002726:	854a                	mv	a0,s2
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	618080e7          	jalr	1560(ra) # 80000d40 <memmove>
    return 0;
    80002730:	8526                	mv	a0,s1
    80002732:	bff9                	j	80002710 <either_copyout+0x32>

0000000080002734 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002734:	7179                	addi	sp,sp,-48
    80002736:	f406                	sd	ra,40(sp)
    80002738:	f022                	sd	s0,32(sp)
    8000273a:	ec26                	sd	s1,24(sp)
    8000273c:	e84a                	sd	s2,16(sp)
    8000273e:	e44e                	sd	s3,8(sp)
    80002740:	e052                	sd	s4,0(sp)
    80002742:	1800                	addi	s0,sp,48
    80002744:	892a                	mv	s2,a0
    80002746:	84ae                	mv	s1,a1
    80002748:	89b2                	mv	s3,a2
    8000274a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000274c:	fffff097          	auipc	ra,0xfffff
    80002750:	282080e7          	jalr	642(ra) # 800019ce <myproc>
  if(user_src){
    80002754:	c08d                	beqz	s1,80002776 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002756:	86d2                	mv	a3,s4
    80002758:	864e                	mv	a2,s3
    8000275a:	85ca                	mv	a1,s2
    8000275c:	6d28                	ld	a0,88(a0)
    8000275e:	fffff097          	auipc	ra,0xfffff
    80002762:	fa8080e7          	jalr	-88(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002766:	70a2                	ld	ra,40(sp)
    80002768:	7402                	ld	s0,32(sp)
    8000276a:	64e2                	ld	s1,24(sp)
    8000276c:	6942                	ld	s2,16(sp)
    8000276e:	69a2                	ld	s3,8(sp)
    80002770:	6a02                	ld	s4,0(sp)
    80002772:	6145                	addi	sp,sp,48
    80002774:	8082                	ret
    memmove(dst, (char*)src, len);
    80002776:	000a061b          	sext.w	a2,s4
    8000277a:	85ce                	mv	a1,s3
    8000277c:	854a                	mv	a0,s2
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	5c2080e7          	jalr	1474(ra) # 80000d40 <memmove>
    return 0;
    80002786:	8526                	mv	a0,s1
    80002788:	bff9                	j	80002766 <either_copyin+0x32>

000000008000278a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000278a:	715d                	addi	sp,sp,-80
    8000278c:	e486                	sd	ra,72(sp)
    8000278e:	e0a2                	sd	s0,64(sp)
    80002790:	fc26                	sd	s1,56(sp)
    80002792:	f84a                	sd	s2,48(sp)
    80002794:	f44e                	sd	s3,40(sp)
    80002796:	f052                	sd	s4,32(sp)
    80002798:	ec56                	sd	s5,24(sp)
    8000279a:	e85a                	sd	s6,16(sp)
    8000279c:	e45e                	sd	s7,8(sp)
    8000279e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800027a0:	00006517          	auipc	a0,0x6
    800027a4:	92850513          	addi	a0,a0,-1752 # 800080c8 <digits+0x88>
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	de0080e7          	jalr	-544(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027b0:	0000f497          	auipc	s1,0xf
    800027b4:	08048493          	addi	s1,s1,128 # 80011830 <proc+0x160>
    800027b8:	00015917          	auipc	s2,0x15
    800027bc:	c7890913          	addi	s2,s2,-904 # 80017430 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027c0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800027c2:	00006997          	auipc	s3,0x6
    800027c6:	ad698993          	addi	s3,s3,-1322 # 80008298 <digits+0x258>
    printf("%d %s %s", p->pid, state, p->name);
    800027ca:	00006a97          	auipc	s5,0x6
    800027ce:	ad6a8a93          	addi	s5,s5,-1322 # 800082a0 <digits+0x260>
    printf("\n");
    800027d2:	00006a17          	auipc	s4,0x6
    800027d6:	8f6a0a13          	addi	s4,s4,-1802 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027da:	00006b97          	auipc	s7,0x6
    800027de:	afeb8b93          	addi	s7,s7,-1282 # 800082d8 <states.1766>
    800027e2:	a00d                	j	80002804 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027e4:	ed06a583          	lw	a1,-304(a3)
    800027e8:	8556                	mv	a0,s5
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	d9e080e7          	jalr	-610(ra) # 80000588 <printf>
    printf("\n");
    800027f2:	8552                	mv	a0,s4
    800027f4:	ffffe097          	auipc	ra,0xffffe
    800027f8:	d94080e7          	jalr	-620(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027fc:	17048493          	addi	s1,s1,368
    80002800:	03248163          	beq	s1,s2,80002822 <procdump+0x98>
    if(p->state == UNUSED)
    80002804:	86a6                	mv	a3,s1
    80002806:	eb84a783          	lw	a5,-328(s1)
    8000280a:	dbed                	beqz	a5,800027fc <procdump+0x72>
      state = "???";
    8000280c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000280e:	fcfb6be3          	bltu	s6,a5,800027e4 <procdump+0x5a>
    80002812:	1782                	slli	a5,a5,0x20
    80002814:	9381                	srli	a5,a5,0x20
    80002816:	078e                	slli	a5,a5,0x3
    80002818:	97de                	add	a5,a5,s7
    8000281a:	6390                	ld	a2,0(a5)
    8000281c:	f661                	bnez	a2,800027e4 <procdump+0x5a>
      state = "???";
    8000281e:	864e                	mv	a2,s3
    80002820:	b7d1                	j	800027e4 <procdump+0x5a>
  }
}
    80002822:	60a6                	ld	ra,72(sp)
    80002824:	6406                	ld	s0,64(sp)
    80002826:	74e2                	ld	s1,56(sp)
    80002828:	7942                	ld	s2,48(sp)
    8000282a:	79a2                	ld	s3,40(sp)
    8000282c:	7a02                	ld	s4,32(sp)
    8000282e:	6ae2                	ld	s5,24(sp)
    80002830:	6b42                	ld	s6,16(sp)
    80002832:	6ba2                	ld	s7,8(sp)
    80002834:	6161                	addi	sp,sp,80
    80002836:	8082                	ret

0000000080002838 <pause_system>:

// pause all user processes for the number of seconds specified by thesecond's integer parameter.
int pause_system(int seconds){
    80002838:	1141                	addi	sp,sp,-16
    8000283a:	e406                	sd	ra,8(sp)
    8000283c:	e022                	sd	s0,0(sp)
    8000283e:	0800                	addi	s0,sp,16
  pause_ticks = ticks + seconds * SECONDS_TO_TICKS;
    80002840:	0025179b          	slliw	a5,a0,0x2
    80002844:	9fa9                	addw	a5,a5,a0
    80002846:	0017979b          	slliw	a5,a5,0x1
    8000284a:	00006517          	auipc	a0,0x6
    8000284e:	7ee52503          	lw	a0,2030(a0) # 80009038 <ticks>
    80002852:	9fa9                	addw	a5,a5,a0
    80002854:	00006717          	auipc	a4,0x6
    80002858:	7cf72a23          	sw	a5,2004(a4) # 80009028 <pause_ticks>
  yield();
    8000285c:	00000097          	auipc	ra,0x0
    80002860:	a7c080e7          	jalr	-1412(ra) # 800022d8 <yield>

  return 0;
}
    80002864:	4501                	li	a0,0
    80002866:	60a2                	ld	ra,8(sp)
    80002868:	6402                	ld	s0,0(sp)
    8000286a:	0141                	addi	sp,sp,16
    8000286c:	8082                	ret

000000008000286e <kill_system>:

// terminate all user processes
int 
kill_system(void) {
    8000286e:	7179                	addi	sp,sp,-48
    80002870:	f406                	sd	ra,40(sp)
    80002872:	f022                	sd	s0,32(sp)
    80002874:	ec26                	sd	s1,24(sp)
    80002876:	e84a                	sd	s2,16(sp)
    80002878:	e44e                	sd	s3,8(sp)
    8000287a:	e052                	sd	s4,0(sp)
    8000287c:	1800                	addi	s0,sp,48
  struct proc *p;
  int pid;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000287e:	0000f497          	auipc	s1,0xf
    80002882:	e5248493          	addi	s1,s1,-430 # 800116d0 <proc>
      acquire(&p->lock);
      pid = p->pid;
      release(&p->lock);
      if(pid != INIT_PROC_ID && pid != SHELL_PROC_ID)
    80002886:	4a05                	li	s4,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80002888:	00015997          	auipc	s3,0x15
    8000288c:	a4898993          	addi	s3,s3,-1464 # 800172d0 <tickslock>
    80002890:	a029                	j	8000289a <kill_system+0x2c>
    80002892:	17048493          	addi	s1,s1,368
    80002896:	03348863          	beq	s1,s3,800028c6 <kill_system+0x58>
      acquire(&p->lock);
    8000289a:	8526                	mv	a0,s1
    8000289c:	ffffe097          	auipc	ra,0xffffe
    800028a0:	348080e7          	jalr	840(ra) # 80000be4 <acquire>
      pid = p->pid;
    800028a4:	0304a903          	lw	s2,48(s1)
      release(&p->lock);
    800028a8:	8526                	mv	a0,s1
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	3ee080e7          	jalr	1006(ra) # 80000c98 <release>
      if(pid != INIT_PROC_ID && pid != SHELL_PROC_ID)
    800028b2:	fff9079b          	addiw	a5,s2,-1
    800028b6:	fcfa7ee3          	bgeu	s4,a5,80002892 <kill_system+0x24>
        kill(pid);
    800028ba:	854a                	mv	a0,s2
    800028bc:	00000097          	auipc	ra,0x0
    800028c0:	da6080e7          	jalr	-602(ra) # 80002662 <kill>
    800028c4:	b7f9                	j	80002892 <kill_system+0x24>
  }
  return 0;
}
    800028c6:	4501                	li	a0,0
    800028c8:	70a2                	ld	ra,40(sp)
    800028ca:	7402                	ld	s0,32(sp)
    800028cc:	64e2                	ld	s1,24(sp)
    800028ce:	6942                	ld	s2,16(sp)
    800028d0:	69a2                	ld	s3,8(sp)
    800028d2:	6a02                	ld	s4,0(sp)
    800028d4:	6145                	addi	sp,sp,48
    800028d6:	8082                	ret

00000000800028d8 <swtch>:
    800028d8:	00153023          	sd	ra,0(a0)
    800028dc:	00253423          	sd	sp,8(a0)
    800028e0:	e900                	sd	s0,16(a0)
    800028e2:	ed04                	sd	s1,24(a0)
    800028e4:	03253023          	sd	s2,32(a0)
    800028e8:	03353423          	sd	s3,40(a0)
    800028ec:	03453823          	sd	s4,48(a0)
    800028f0:	03553c23          	sd	s5,56(a0)
    800028f4:	05653023          	sd	s6,64(a0)
    800028f8:	05753423          	sd	s7,72(a0)
    800028fc:	05853823          	sd	s8,80(a0)
    80002900:	05953c23          	sd	s9,88(a0)
    80002904:	07a53023          	sd	s10,96(a0)
    80002908:	07b53423          	sd	s11,104(a0)
    8000290c:	0005b083          	ld	ra,0(a1)
    80002910:	0085b103          	ld	sp,8(a1)
    80002914:	6980                	ld	s0,16(a1)
    80002916:	6d84                	ld	s1,24(a1)
    80002918:	0205b903          	ld	s2,32(a1)
    8000291c:	0285b983          	ld	s3,40(a1)
    80002920:	0305ba03          	ld	s4,48(a1)
    80002924:	0385ba83          	ld	s5,56(a1)
    80002928:	0405bb03          	ld	s6,64(a1)
    8000292c:	0485bb83          	ld	s7,72(a1)
    80002930:	0505bc03          	ld	s8,80(a1)
    80002934:	0585bc83          	ld	s9,88(a1)
    80002938:	0605bd03          	ld	s10,96(a1)
    8000293c:	0685bd83          	ld	s11,104(a1)
    80002940:	8082                	ret

0000000080002942 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002942:	1141                	addi	sp,sp,-16
    80002944:	e406                	sd	ra,8(sp)
    80002946:	e022                	sd	s0,0(sp)
    80002948:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000294a:	00006597          	auipc	a1,0x6
    8000294e:	9be58593          	addi	a1,a1,-1602 # 80008308 <states.1766+0x30>
    80002952:	00015517          	auipc	a0,0x15
    80002956:	97e50513          	addi	a0,a0,-1666 # 800172d0 <tickslock>
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	1fa080e7          	jalr	506(ra) # 80000b54 <initlock>
}
    80002962:	60a2                	ld	ra,8(sp)
    80002964:	6402                	ld	s0,0(sp)
    80002966:	0141                	addi	sp,sp,16
    80002968:	8082                	ret

000000008000296a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000296a:	1141                	addi	sp,sp,-16
    8000296c:	e422                	sd	s0,8(sp)
    8000296e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002970:	00003797          	auipc	a5,0x3
    80002974:	4d078793          	addi	a5,a5,1232 # 80005e40 <kernelvec>
    80002978:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000297c:	6422                	ld	s0,8(sp)
    8000297e:	0141                	addi	sp,sp,16
    80002980:	8082                	ret

0000000080002982 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002982:	1141                	addi	sp,sp,-16
    80002984:	e406                	sd	ra,8(sp)
    80002986:	e022                	sd	s0,0(sp)
    80002988:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000298a:	fffff097          	auipc	ra,0xfffff
    8000298e:	044080e7          	jalr	68(ra) # 800019ce <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002992:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002996:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002998:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000299c:	00004617          	auipc	a2,0x4
    800029a0:	66460613          	addi	a2,a2,1636 # 80007000 <_trampoline>
    800029a4:	00004697          	auipc	a3,0x4
    800029a8:	65c68693          	addi	a3,a3,1628 # 80007000 <_trampoline>
    800029ac:	8e91                	sub	a3,a3,a2
    800029ae:	040007b7          	lui	a5,0x4000
    800029b2:	17fd                	addi	a5,a5,-1
    800029b4:	07b2                	slli	a5,a5,0xc
    800029b6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029b8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029bc:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029be:	180026f3          	csrr	a3,satp
    800029c2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029c4:	7138                	ld	a4,96(a0)
    800029c6:	6534                	ld	a3,72(a0)
    800029c8:	6585                	lui	a1,0x1
    800029ca:	96ae                	add	a3,a3,a1
    800029cc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029ce:	7138                	ld	a4,96(a0)
    800029d0:	00000697          	auipc	a3,0x0
    800029d4:	13868693          	addi	a3,a3,312 # 80002b08 <usertrap>
    800029d8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029da:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029dc:	8692                	mv	a3,tp
    800029de:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029e4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029e8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ec:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029f0:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029f2:	6f18                	ld	a4,24(a4)
    800029f4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029f8:	6d2c                	ld	a1,88(a0)
    800029fa:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029fc:	00004717          	auipc	a4,0x4
    80002a00:	69470713          	addi	a4,a4,1684 # 80007090 <userret>
    80002a04:	8f11                	sub	a4,a4,a2
    80002a06:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a08:	577d                	li	a4,-1
    80002a0a:	177e                	slli	a4,a4,0x3f
    80002a0c:	8dd9                	or	a1,a1,a4
    80002a0e:	02000537          	lui	a0,0x2000
    80002a12:	157d                	addi	a0,a0,-1
    80002a14:	0536                	slli	a0,a0,0xd
    80002a16:	9782                	jalr	a5
}
    80002a18:	60a2                	ld	ra,8(sp)
    80002a1a:	6402                	ld	s0,0(sp)
    80002a1c:	0141                	addi	sp,sp,16
    80002a1e:	8082                	ret

0000000080002a20 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a20:	1101                	addi	sp,sp,-32
    80002a22:	ec06                	sd	ra,24(sp)
    80002a24:	e822                	sd	s0,16(sp)
    80002a26:	e426                	sd	s1,8(sp)
    80002a28:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a2a:	00015497          	auipc	s1,0x15
    80002a2e:	8a648493          	addi	s1,s1,-1882 # 800172d0 <tickslock>
    80002a32:	8526                	mv	a0,s1
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	1b0080e7          	jalr	432(ra) # 80000be4 <acquire>
  ticks++;
    80002a3c:	00006517          	auipc	a0,0x6
    80002a40:	5fc50513          	addi	a0,a0,1532 # 80009038 <ticks>
    80002a44:	411c                	lw	a5,0(a0)
    80002a46:	2785                	addiw	a5,a5,1
    80002a48:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a4a:	00000097          	auipc	ra,0x0
    80002a4e:	a60080e7          	jalr	-1440(ra) # 800024aa <wakeup>
  release(&tickslock);
    80002a52:	8526                	mv	a0,s1
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	244080e7          	jalr	580(ra) # 80000c98 <release>
}
    80002a5c:	60e2                	ld	ra,24(sp)
    80002a5e:	6442                	ld	s0,16(sp)
    80002a60:	64a2                	ld	s1,8(sp)
    80002a62:	6105                	addi	sp,sp,32
    80002a64:	8082                	ret

0000000080002a66 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a66:	1101                	addi	sp,sp,-32
    80002a68:	ec06                	sd	ra,24(sp)
    80002a6a:	e822                	sd	s0,16(sp)
    80002a6c:	e426                	sd	s1,8(sp)
    80002a6e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a70:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a74:	00074d63          	bltz	a4,80002a8e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a78:	57fd                	li	a5,-1
    80002a7a:	17fe                	slli	a5,a5,0x3f
    80002a7c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a7e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a80:	06f70363          	beq	a4,a5,80002ae6 <devintr+0x80>
  }
}
    80002a84:	60e2                	ld	ra,24(sp)
    80002a86:	6442                	ld	s0,16(sp)
    80002a88:	64a2                	ld	s1,8(sp)
    80002a8a:	6105                	addi	sp,sp,32
    80002a8c:	8082                	ret
     (scause & 0xff) == 9){
    80002a8e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a92:	46a5                	li	a3,9
    80002a94:	fed792e3          	bne	a5,a3,80002a78 <devintr+0x12>
    int irq = plic_claim();
    80002a98:	00003097          	auipc	ra,0x3
    80002a9c:	4b0080e7          	jalr	1200(ra) # 80005f48 <plic_claim>
    80002aa0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002aa2:	47a9                	li	a5,10
    80002aa4:	02f50763          	beq	a0,a5,80002ad2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002aa8:	4785                	li	a5,1
    80002aaa:	02f50963          	beq	a0,a5,80002adc <devintr+0x76>
    return 1;
    80002aae:	4505                	li	a0,1
    } else if(irq){
    80002ab0:	d8f1                	beqz	s1,80002a84 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ab2:	85a6                	mv	a1,s1
    80002ab4:	00006517          	auipc	a0,0x6
    80002ab8:	85c50513          	addi	a0,a0,-1956 # 80008310 <states.1766+0x38>
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	acc080e7          	jalr	-1332(ra) # 80000588 <printf>
      plic_complete(irq);
    80002ac4:	8526                	mv	a0,s1
    80002ac6:	00003097          	auipc	ra,0x3
    80002aca:	4a6080e7          	jalr	1190(ra) # 80005f6c <plic_complete>
    return 1;
    80002ace:	4505                	li	a0,1
    80002ad0:	bf55                	j	80002a84 <devintr+0x1e>
      uartintr();
    80002ad2:	ffffe097          	auipc	ra,0xffffe
    80002ad6:	ed6080e7          	jalr	-298(ra) # 800009a8 <uartintr>
    80002ada:	b7ed                	j	80002ac4 <devintr+0x5e>
      virtio_disk_intr();
    80002adc:	00004097          	auipc	ra,0x4
    80002ae0:	970080e7          	jalr	-1680(ra) # 8000644c <virtio_disk_intr>
    80002ae4:	b7c5                	j	80002ac4 <devintr+0x5e>
    if(cpuid() == 0){
    80002ae6:	fffff097          	auipc	ra,0xfffff
    80002aea:	ebc080e7          	jalr	-324(ra) # 800019a2 <cpuid>
    80002aee:	c901                	beqz	a0,80002afe <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002af0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002af4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002af6:	14479073          	csrw	sip,a5
    return 2;
    80002afa:	4509                	li	a0,2
    80002afc:	b761                	j	80002a84 <devintr+0x1e>
      clockintr();
    80002afe:	00000097          	auipc	ra,0x0
    80002b02:	f22080e7          	jalr	-222(ra) # 80002a20 <clockintr>
    80002b06:	b7ed                	j	80002af0 <devintr+0x8a>

0000000080002b08 <usertrap>:
{
    80002b08:	1101                	addi	sp,sp,-32
    80002b0a:	ec06                	sd	ra,24(sp)
    80002b0c:	e822                	sd	s0,16(sp)
    80002b0e:	e426                	sd	s1,8(sp)
    80002b10:	e04a                	sd	s2,0(sp)
    80002b12:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b14:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b18:	1007f793          	andi	a5,a5,256
    80002b1c:	e3ad                	bnez	a5,80002b7e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b1e:	00003797          	auipc	a5,0x3
    80002b22:	32278793          	addi	a5,a5,802 # 80005e40 <kernelvec>
    80002b26:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b2a:	fffff097          	auipc	ra,0xfffff
    80002b2e:	ea4080e7          	jalr	-348(ra) # 800019ce <myproc>
    80002b32:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b34:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b36:	14102773          	csrr	a4,sepc
    80002b3a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b3c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b40:	47a1                	li	a5,8
    80002b42:	04f71c63          	bne	a4,a5,80002b9a <usertrap+0x92>
    if(p->killed)
    80002b46:	551c                	lw	a5,40(a0)
    80002b48:	e3b9                	bnez	a5,80002b8e <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b4a:	70b8                	ld	a4,96(s1)
    80002b4c:	6f1c                	ld	a5,24(a4)
    80002b4e:	0791                	addi	a5,a5,4
    80002b50:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b56:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b5a:	10079073          	csrw	sstatus,a5
    syscall();
    80002b5e:	00000097          	auipc	ra,0x0
    80002b62:	2e0080e7          	jalr	736(ra) # 80002e3e <syscall>
  if(p->killed)
    80002b66:	549c                	lw	a5,40(s1)
    80002b68:	ebc1                	bnez	a5,80002bf8 <usertrap+0xf0>
  usertrapret();
    80002b6a:	00000097          	auipc	ra,0x0
    80002b6e:	e18080e7          	jalr	-488(ra) # 80002982 <usertrapret>
}
    80002b72:	60e2                	ld	ra,24(sp)
    80002b74:	6442                	ld	s0,16(sp)
    80002b76:	64a2                	ld	s1,8(sp)
    80002b78:	6902                	ld	s2,0(sp)
    80002b7a:	6105                	addi	sp,sp,32
    80002b7c:	8082                	ret
    panic("usertrap: not from user mode");
    80002b7e:	00005517          	auipc	a0,0x5
    80002b82:	7b250513          	addi	a0,a0,1970 # 80008330 <states.1766+0x58>
    80002b86:	ffffe097          	auipc	ra,0xffffe
    80002b8a:	9b8080e7          	jalr	-1608(ra) # 8000053e <panic>
      exit(-1);
    80002b8e:	557d                	li	a0,-1
    80002b90:	00000097          	auipc	ra,0x0
    80002b94:	9fc080e7          	jalr	-1540(ra) # 8000258c <exit>
    80002b98:	bf4d                	j	80002b4a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b9a:	00000097          	auipc	ra,0x0
    80002b9e:	ecc080e7          	jalr	-308(ra) # 80002a66 <devintr>
    80002ba2:	892a                	mv	s2,a0
    80002ba4:	c501                	beqz	a0,80002bac <usertrap+0xa4>
  if(p->killed)
    80002ba6:	549c                	lw	a5,40(s1)
    80002ba8:	c3a1                	beqz	a5,80002be8 <usertrap+0xe0>
    80002baa:	a815                	j	80002bde <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bac:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bb0:	5890                	lw	a2,48(s1)
    80002bb2:	00005517          	auipc	a0,0x5
    80002bb6:	79e50513          	addi	a0,a0,1950 # 80008350 <states.1766+0x78>
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	9ce080e7          	jalr	-1586(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bc2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bc6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bca:	00005517          	auipc	a0,0x5
    80002bce:	7b650513          	addi	a0,a0,1974 # 80008380 <states.1766+0xa8>
    80002bd2:	ffffe097          	auipc	ra,0xffffe
    80002bd6:	9b6080e7          	jalr	-1610(ra) # 80000588 <printf>
    p->killed = 1;
    80002bda:	4785                	li	a5,1
    80002bdc:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002bde:	557d                	li	a0,-1
    80002be0:	00000097          	auipc	ra,0x0
    80002be4:	9ac080e7          	jalr	-1620(ra) # 8000258c <exit>
  if(which_dev == 2)
    80002be8:	4789                	li	a5,2
    80002bea:	f8f910e3          	bne	s2,a5,80002b6a <usertrap+0x62>
    yield();
    80002bee:	fffff097          	auipc	ra,0xfffff
    80002bf2:	6ea080e7          	jalr	1770(ra) # 800022d8 <yield>
    80002bf6:	bf95                	j	80002b6a <usertrap+0x62>
  int which_dev = 0;
    80002bf8:	4901                	li	s2,0
    80002bfa:	b7d5                	j	80002bde <usertrap+0xd6>

0000000080002bfc <kerneltrap>:
{
    80002bfc:	7179                	addi	sp,sp,-48
    80002bfe:	f406                	sd	ra,40(sp)
    80002c00:	f022                	sd	s0,32(sp)
    80002c02:	ec26                	sd	s1,24(sp)
    80002c04:	e84a                	sd	s2,16(sp)
    80002c06:	e44e                	sd	s3,8(sp)
    80002c08:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c0a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c0e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c12:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c16:	1004f793          	andi	a5,s1,256
    80002c1a:	cb85                	beqz	a5,80002c4a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c1c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c20:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c22:	ef85                	bnez	a5,80002c5a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c24:	00000097          	auipc	ra,0x0
    80002c28:	e42080e7          	jalr	-446(ra) # 80002a66 <devintr>
    80002c2c:	cd1d                	beqz	a0,80002c6a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c2e:	4789                	li	a5,2
    80002c30:	06f50a63          	beq	a0,a5,80002ca4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c34:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c38:	10049073          	csrw	sstatus,s1
}
    80002c3c:	70a2                	ld	ra,40(sp)
    80002c3e:	7402                	ld	s0,32(sp)
    80002c40:	64e2                	ld	s1,24(sp)
    80002c42:	6942                	ld	s2,16(sp)
    80002c44:	69a2                	ld	s3,8(sp)
    80002c46:	6145                	addi	sp,sp,48
    80002c48:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c4a:	00005517          	auipc	a0,0x5
    80002c4e:	75650513          	addi	a0,a0,1878 # 800083a0 <states.1766+0xc8>
    80002c52:	ffffe097          	auipc	ra,0xffffe
    80002c56:	8ec080e7          	jalr	-1812(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002c5a:	00005517          	auipc	a0,0x5
    80002c5e:	76e50513          	addi	a0,a0,1902 # 800083c8 <states.1766+0xf0>
    80002c62:	ffffe097          	auipc	ra,0xffffe
    80002c66:	8dc080e7          	jalr	-1828(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002c6a:	85ce                	mv	a1,s3
    80002c6c:	00005517          	auipc	a0,0x5
    80002c70:	77c50513          	addi	a0,a0,1916 # 800083e8 <states.1766+0x110>
    80002c74:	ffffe097          	auipc	ra,0xffffe
    80002c78:	914080e7          	jalr	-1772(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c7c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c80:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c84:	00005517          	auipc	a0,0x5
    80002c88:	77450513          	addi	a0,a0,1908 # 800083f8 <states.1766+0x120>
    80002c8c:	ffffe097          	auipc	ra,0xffffe
    80002c90:	8fc080e7          	jalr	-1796(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002c94:	00005517          	auipc	a0,0x5
    80002c98:	77c50513          	addi	a0,a0,1916 # 80008410 <states.1766+0x138>
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	8a2080e7          	jalr	-1886(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ca4:	fffff097          	auipc	ra,0xfffff
    80002ca8:	d2a080e7          	jalr	-726(ra) # 800019ce <myproc>
    80002cac:	d541                	beqz	a0,80002c34 <kerneltrap+0x38>
    80002cae:	fffff097          	auipc	ra,0xfffff
    80002cb2:	d20080e7          	jalr	-736(ra) # 800019ce <myproc>
    80002cb6:	4d18                	lw	a4,24(a0)
    80002cb8:	4791                	li	a5,4
    80002cba:	f6f71de3          	bne	a4,a5,80002c34 <kerneltrap+0x38>
    yield();
    80002cbe:	fffff097          	auipc	ra,0xfffff
    80002cc2:	61a080e7          	jalr	1562(ra) # 800022d8 <yield>
    80002cc6:	b7bd                	j	80002c34 <kerneltrap+0x38>

0000000080002cc8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cc8:	1101                	addi	sp,sp,-32
    80002cca:	ec06                	sd	ra,24(sp)
    80002ccc:	e822                	sd	s0,16(sp)
    80002cce:	e426                	sd	s1,8(sp)
    80002cd0:	1000                	addi	s0,sp,32
    80002cd2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cd4:	fffff097          	auipc	ra,0xfffff
    80002cd8:	cfa080e7          	jalr	-774(ra) # 800019ce <myproc>
  switch (n) {
    80002cdc:	4795                	li	a5,5
    80002cde:	0497e163          	bltu	a5,s1,80002d20 <argraw+0x58>
    80002ce2:	048a                	slli	s1,s1,0x2
    80002ce4:	00005717          	auipc	a4,0x5
    80002ce8:	76470713          	addi	a4,a4,1892 # 80008448 <states.1766+0x170>
    80002cec:	94ba                	add	s1,s1,a4
    80002cee:	409c                	lw	a5,0(s1)
    80002cf0:	97ba                	add	a5,a5,a4
    80002cf2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cf4:	713c                	ld	a5,96(a0)
    80002cf6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cf8:	60e2                	ld	ra,24(sp)
    80002cfa:	6442                	ld	s0,16(sp)
    80002cfc:	64a2                	ld	s1,8(sp)
    80002cfe:	6105                	addi	sp,sp,32
    80002d00:	8082                	ret
    return p->trapframe->a1;
    80002d02:	713c                	ld	a5,96(a0)
    80002d04:	7fa8                	ld	a0,120(a5)
    80002d06:	bfcd                	j	80002cf8 <argraw+0x30>
    return p->trapframe->a2;
    80002d08:	713c                	ld	a5,96(a0)
    80002d0a:	63c8                	ld	a0,128(a5)
    80002d0c:	b7f5                	j	80002cf8 <argraw+0x30>
    return p->trapframe->a3;
    80002d0e:	713c                	ld	a5,96(a0)
    80002d10:	67c8                	ld	a0,136(a5)
    80002d12:	b7dd                	j	80002cf8 <argraw+0x30>
    return p->trapframe->a4;
    80002d14:	713c                	ld	a5,96(a0)
    80002d16:	6bc8                	ld	a0,144(a5)
    80002d18:	b7c5                	j	80002cf8 <argraw+0x30>
    return p->trapframe->a5;
    80002d1a:	713c                	ld	a5,96(a0)
    80002d1c:	6fc8                	ld	a0,152(a5)
    80002d1e:	bfe9                	j	80002cf8 <argraw+0x30>
  panic("argraw");
    80002d20:	00005517          	auipc	a0,0x5
    80002d24:	70050513          	addi	a0,a0,1792 # 80008420 <states.1766+0x148>
    80002d28:	ffffe097          	auipc	ra,0xffffe
    80002d2c:	816080e7          	jalr	-2026(ra) # 8000053e <panic>

0000000080002d30 <fetchaddr>:
{
    80002d30:	1101                	addi	sp,sp,-32
    80002d32:	ec06                	sd	ra,24(sp)
    80002d34:	e822                	sd	s0,16(sp)
    80002d36:	e426                	sd	s1,8(sp)
    80002d38:	e04a                	sd	s2,0(sp)
    80002d3a:	1000                	addi	s0,sp,32
    80002d3c:	84aa                	mv	s1,a0
    80002d3e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	c8e080e7          	jalr	-882(ra) # 800019ce <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d48:	693c                	ld	a5,80(a0)
    80002d4a:	02f4f863          	bgeu	s1,a5,80002d7a <fetchaddr+0x4a>
    80002d4e:	00848713          	addi	a4,s1,8
    80002d52:	02e7e663          	bltu	a5,a4,80002d7e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d56:	46a1                	li	a3,8
    80002d58:	8626                	mv	a2,s1
    80002d5a:	85ca                	mv	a1,s2
    80002d5c:	6d28                	ld	a0,88(a0)
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	9a8080e7          	jalr	-1624(ra) # 80001706 <copyin>
    80002d66:	00a03533          	snez	a0,a0
    80002d6a:	40a00533          	neg	a0,a0
}
    80002d6e:	60e2                	ld	ra,24(sp)
    80002d70:	6442                	ld	s0,16(sp)
    80002d72:	64a2                	ld	s1,8(sp)
    80002d74:	6902                	ld	s2,0(sp)
    80002d76:	6105                	addi	sp,sp,32
    80002d78:	8082                	ret
    return -1;
    80002d7a:	557d                	li	a0,-1
    80002d7c:	bfcd                	j	80002d6e <fetchaddr+0x3e>
    80002d7e:	557d                	li	a0,-1
    80002d80:	b7fd                	j	80002d6e <fetchaddr+0x3e>

0000000080002d82 <fetchstr>:
{
    80002d82:	7179                	addi	sp,sp,-48
    80002d84:	f406                	sd	ra,40(sp)
    80002d86:	f022                	sd	s0,32(sp)
    80002d88:	ec26                	sd	s1,24(sp)
    80002d8a:	e84a                	sd	s2,16(sp)
    80002d8c:	e44e                	sd	s3,8(sp)
    80002d8e:	1800                	addi	s0,sp,48
    80002d90:	892a                	mv	s2,a0
    80002d92:	84ae                	mv	s1,a1
    80002d94:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d96:	fffff097          	auipc	ra,0xfffff
    80002d9a:	c38080e7          	jalr	-968(ra) # 800019ce <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d9e:	86ce                	mv	a3,s3
    80002da0:	864a                	mv	a2,s2
    80002da2:	85a6                	mv	a1,s1
    80002da4:	6d28                	ld	a0,88(a0)
    80002da6:	fffff097          	auipc	ra,0xfffff
    80002daa:	9ec080e7          	jalr	-1556(ra) # 80001792 <copyinstr>
  if(err < 0)
    80002dae:	00054763          	bltz	a0,80002dbc <fetchstr+0x3a>
  return strlen(buf);
    80002db2:	8526                	mv	a0,s1
    80002db4:	ffffe097          	auipc	ra,0xffffe
    80002db8:	0b0080e7          	jalr	176(ra) # 80000e64 <strlen>
}
    80002dbc:	70a2                	ld	ra,40(sp)
    80002dbe:	7402                	ld	s0,32(sp)
    80002dc0:	64e2                	ld	s1,24(sp)
    80002dc2:	6942                	ld	s2,16(sp)
    80002dc4:	69a2                	ld	s3,8(sp)
    80002dc6:	6145                	addi	sp,sp,48
    80002dc8:	8082                	ret

0000000080002dca <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002dca:	1101                	addi	sp,sp,-32
    80002dcc:	ec06                	sd	ra,24(sp)
    80002dce:	e822                	sd	s0,16(sp)
    80002dd0:	e426                	sd	s1,8(sp)
    80002dd2:	1000                	addi	s0,sp,32
    80002dd4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dd6:	00000097          	auipc	ra,0x0
    80002dda:	ef2080e7          	jalr	-270(ra) # 80002cc8 <argraw>
    80002dde:	c088                	sw	a0,0(s1)
  return 0;
}
    80002de0:	4501                	li	a0,0
    80002de2:	60e2                	ld	ra,24(sp)
    80002de4:	6442                	ld	s0,16(sp)
    80002de6:	64a2                	ld	s1,8(sp)
    80002de8:	6105                	addi	sp,sp,32
    80002dea:	8082                	ret

0000000080002dec <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002dec:	1101                	addi	sp,sp,-32
    80002dee:	ec06                	sd	ra,24(sp)
    80002df0:	e822                	sd	s0,16(sp)
    80002df2:	e426                	sd	s1,8(sp)
    80002df4:	1000                	addi	s0,sp,32
    80002df6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002df8:	00000097          	auipc	ra,0x0
    80002dfc:	ed0080e7          	jalr	-304(ra) # 80002cc8 <argraw>
    80002e00:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e02:	4501                	li	a0,0
    80002e04:	60e2                	ld	ra,24(sp)
    80002e06:	6442                	ld	s0,16(sp)
    80002e08:	64a2                	ld	s1,8(sp)
    80002e0a:	6105                	addi	sp,sp,32
    80002e0c:	8082                	ret

0000000080002e0e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e0e:	1101                	addi	sp,sp,-32
    80002e10:	ec06                	sd	ra,24(sp)
    80002e12:	e822                	sd	s0,16(sp)
    80002e14:	e426                	sd	s1,8(sp)
    80002e16:	e04a                	sd	s2,0(sp)
    80002e18:	1000                	addi	s0,sp,32
    80002e1a:	84ae                	mv	s1,a1
    80002e1c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e1e:	00000097          	auipc	ra,0x0
    80002e22:	eaa080e7          	jalr	-342(ra) # 80002cc8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e26:	864a                	mv	a2,s2
    80002e28:	85a6                	mv	a1,s1
    80002e2a:	00000097          	auipc	ra,0x0
    80002e2e:	f58080e7          	jalr	-168(ra) # 80002d82 <fetchstr>
}
    80002e32:	60e2                	ld	ra,24(sp)
    80002e34:	6442                	ld	s0,16(sp)
    80002e36:	64a2                	ld	s1,8(sp)
    80002e38:	6902                	ld	s2,0(sp)
    80002e3a:	6105                	addi	sp,sp,32
    80002e3c:	8082                	ret

0000000080002e3e <syscall>:
[SYS_kill_system] sys_kill_system,
};

void
syscall(void)
{
    80002e3e:	1101                	addi	sp,sp,-32
    80002e40:	ec06                	sd	ra,24(sp)
    80002e42:	e822                	sd	s0,16(sp)
    80002e44:	e426                	sd	s1,8(sp)
    80002e46:	e04a                	sd	s2,0(sp)
    80002e48:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e4a:	fffff097          	auipc	ra,0xfffff
    80002e4e:	b84080e7          	jalr	-1148(ra) # 800019ce <myproc>
    80002e52:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e54:	06053903          	ld	s2,96(a0)
    80002e58:	0a893783          	ld	a5,168(s2)
    80002e5c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e60:	37fd                	addiw	a5,a5,-1
    80002e62:	4759                	li	a4,22
    80002e64:	00f76f63          	bltu	a4,a5,80002e82 <syscall+0x44>
    80002e68:	00369713          	slli	a4,a3,0x3
    80002e6c:	00005797          	auipc	a5,0x5
    80002e70:	5f478793          	addi	a5,a5,1524 # 80008460 <syscalls>
    80002e74:	97ba                	add	a5,a5,a4
    80002e76:	639c                	ld	a5,0(a5)
    80002e78:	c789                	beqz	a5,80002e82 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e7a:	9782                	jalr	a5
    80002e7c:	06a93823          	sd	a0,112(s2)
    80002e80:	a839                	j	80002e9e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e82:	16048613          	addi	a2,s1,352
    80002e86:	588c                	lw	a1,48(s1)
    80002e88:	00005517          	auipc	a0,0x5
    80002e8c:	5a050513          	addi	a0,a0,1440 # 80008428 <states.1766+0x150>
    80002e90:	ffffd097          	auipc	ra,0xffffd
    80002e94:	6f8080e7          	jalr	1784(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e98:	70bc                	ld	a5,96(s1)
    80002e9a:	577d                	li	a4,-1
    80002e9c:	fbb8                	sd	a4,112(a5)
  }
}
    80002e9e:	60e2                	ld	ra,24(sp)
    80002ea0:	6442                	ld	s0,16(sp)
    80002ea2:	64a2                	ld	s1,8(sp)
    80002ea4:	6902                	ld	s2,0(sp)
    80002ea6:	6105                	addi	sp,sp,32
    80002ea8:	8082                	ret

0000000080002eaa <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002eaa:	1101                	addi	sp,sp,-32
    80002eac:	ec06                	sd	ra,24(sp)
    80002eae:	e822                	sd	s0,16(sp)
    80002eb0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002eb2:	fec40593          	addi	a1,s0,-20
    80002eb6:	4501                	li	a0,0
    80002eb8:	00000097          	auipc	ra,0x0
    80002ebc:	f12080e7          	jalr	-238(ra) # 80002dca <argint>
    return -1;
    80002ec0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ec2:	00054963          	bltz	a0,80002ed4 <sys_exit+0x2a>
  exit(n);
    80002ec6:	fec42503          	lw	a0,-20(s0)
    80002eca:	fffff097          	auipc	ra,0xfffff
    80002ece:	6c2080e7          	jalr	1730(ra) # 8000258c <exit>
  return 0;  // not reached
    80002ed2:	4781                	li	a5,0
}
    80002ed4:	853e                	mv	a0,a5
    80002ed6:	60e2                	ld	ra,24(sp)
    80002ed8:	6442                	ld	s0,16(sp)
    80002eda:	6105                	addi	sp,sp,32
    80002edc:	8082                	ret

0000000080002ede <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ede:	1141                	addi	sp,sp,-16
    80002ee0:	e406                	sd	ra,8(sp)
    80002ee2:	e022                	sd	s0,0(sp)
    80002ee4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ee6:	fffff097          	auipc	ra,0xfffff
    80002eea:	ae8080e7          	jalr	-1304(ra) # 800019ce <myproc>
}
    80002eee:	5908                	lw	a0,48(a0)
    80002ef0:	60a2                	ld	ra,8(sp)
    80002ef2:	6402                	ld	s0,0(sp)
    80002ef4:	0141                	addi	sp,sp,16
    80002ef6:	8082                	ret

0000000080002ef8 <sys_fork>:

uint64
sys_fork(void)
{
    80002ef8:	1141                	addi	sp,sp,-16
    80002efa:	e406                	sd	ra,8(sp)
    80002efc:	e022                	sd	s0,0(sp)
    80002efe:	0800                	addi	s0,sp,16
  return fork();
    80002f00:	fffff097          	auipc	ra,0xfffff
    80002f04:	eae080e7          	jalr	-338(ra) # 80001dae <fork>
}
    80002f08:	60a2                	ld	ra,8(sp)
    80002f0a:	6402                	ld	s0,0(sp)
    80002f0c:	0141                	addi	sp,sp,16
    80002f0e:	8082                	ret

0000000080002f10 <sys_wait>:

uint64
sys_wait(void)
{
    80002f10:	1101                	addi	sp,sp,-32
    80002f12:	ec06                	sd	ra,24(sp)
    80002f14:	e822                	sd	s0,16(sp)
    80002f16:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f18:	fe840593          	addi	a1,s0,-24
    80002f1c:	4501                	li	a0,0
    80002f1e:	00000097          	auipc	ra,0x0
    80002f22:	ece080e7          	jalr	-306(ra) # 80002dec <argaddr>
    80002f26:	87aa                	mv	a5,a0
    return -1;
    80002f28:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f2a:	0007c863          	bltz	a5,80002f3a <sys_wait+0x2a>
  return wait(p);
    80002f2e:	fe843503          	ld	a0,-24(s0)
    80002f32:	fffff097          	auipc	ra,0xfffff
    80002f36:	450080e7          	jalr	1104(ra) # 80002382 <wait>
}
    80002f3a:	60e2                	ld	ra,24(sp)
    80002f3c:	6442                	ld	s0,16(sp)
    80002f3e:	6105                	addi	sp,sp,32
    80002f40:	8082                	ret

0000000080002f42 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f42:	7179                	addi	sp,sp,-48
    80002f44:	f406                	sd	ra,40(sp)
    80002f46:	f022                	sd	s0,32(sp)
    80002f48:	ec26                	sd	s1,24(sp)
    80002f4a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f4c:	fdc40593          	addi	a1,s0,-36
    80002f50:	4501                	li	a0,0
    80002f52:	00000097          	auipc	ra,0x0
    80002f56:	e78080e7          	jalr	-392(ra) # 80002dca <argint>
    80002f5a:	87aa                	mv	a5,a0
    return -1;
    80002f5c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f5e:	0207c063          	bltz	a5,80002f7e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f62:	fffff097          	auipc	ra,0xfffff
    80002f66:	a6c080e7          	jalr	-1428(ra) # 800019ce <myproc>
    80002f6a:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002f6c:	fdc42503          	lw	a0,-36(s0)
    80002f70:	fffff097          	auipc	ra,0xfffff
    80002f74:	dca080e7          	jalr	-566(ra) # 80001d3a <growproc>
    80002f78:	00054863          	bltz	a0,80002f88 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f7c:	8526                	mv	a0,s1
}
    80002f7e:	70a2                	ld	ra,40(sp)
    80002f80:	7402                	ld	s0,32(sp)
    80002f82:	64e2                	ld	s1,24(sp)
    80002f84:	6145                	addi	sp,sp,48
    80002f86:	8082                	ret
    return -1;
    80002f88:	557d                	li	a0,-1
    80002f8a:	bfd5                	j	80002f7e <sys_sbrk+0x3c>

0000000080002f8c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f8c:	7139                	addi	sp,sp,-64
    80002f8e:	fc06                	sd	ra,56(sp)
    80002f90:	f822                	sd	s0,48(sp)
    80002f92:	f426                	sd	s1,40(sp)
    80002f94:	f04a                	sd	s2,32(sp)
    80002f96:	ec4e                	sd	s3,24(sp)
    80002f98:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f9a:	fcc40593          	addi	a1,s0,-52
    80002f9e:	4501                	li	a0,0
    80002fa0:	00000097          	auipc	ra,0x0
    80002fa4:	e2a080e7          	jalr	-470(ra) # 80002dca <argint>
    return -1;
    80002fa8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002faa:	06054563          	bltz	a0,80003014 <sys_sleep+0x88>
  acquire(&tickslock);
    80002fae:	00014517          	auipc	a0,0x14
    80002fb2:	32250513          	addi	a0,a0,802 # 800172d0 <tickslock>
    80002fb6:	ffffe097          	auipc	ra,0xffffe
    80002fba:	c2e080e7          	jalr	-978(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002fbe:	00006917          	auipc	s2,0x6
    80002fc2:	07a92903          	lw	s2,122(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80002fc6:	fcc42783          	lw	a5,-52(s0)
    80002fca:	cf85                	beqz	a5,80003002 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fcc:	00014997          	auipc	s3,0x14
    80002fd0:	30498993          	addi	s3,s3,772 # 800172d0 <tickslock>
    80002fd4:	00006497          	auipc	s1,0x6
    80002fd8:	06448493          	addi	s1,s1,100 # 80009038 <ticks>
    if(myproc()->killed){
    80002fdc:	fffff097          	auipc	ra,0xfffff
    80002fe0:	9f2080e7          	jalr	-1550(ra) # 800019ce <myproc>
    80002fe4:	551c                	lw	a5,40(a0)
    80002fe6:	ef9d                	bnez	a5,80003024 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002fe8:	85ce                	mv	a1,s3
    80002fea:	8526                	mv	a0,s1
    80002fec:	fffff097          	auipc	ra,0xfffff
    80002ff0:	332080e7          	jalr	818(ra) # 8000231e <sleep>
  while(ticks - ticks0 < n){
    80002ff4:	409c                	lw	a5,0(s1)
    80002ff6:	412787bb          	subw	a5,a5,s2
    80002ffa:	fcc42703          	lw	a4,-52(s0)
    80002ffe:	fce7efe3          	bltu	a5,a4,80002fdc <sys_sleep+0x50>
  }
  release(&tickslock);
    80003002:	00014517          	auipc	a0,0x14
    80003006:	2ce50513          	addi	a0,a0,718 # 800172d0 <tickslock>
    8000300a:	ffffe097          	auipc	ra,0xffffe
    8000300e:	c8e080e7          	jalr	-882(ra) # 80000c98 <release>
  return 0;
    80003012:	4781                	li	a5,0
}
    80003014:	853e                	mv	a0,a5
    80003016:	70e2                	ld	ra,56(sp)
    80003018:	7442                	ld	s0,48(sp)
    8000301a:	74a2                	ld	s1,40(sp)
    8000301c:	7902                	ld	s2,32(sp)
    8000301e:	69e2                	ld	s3,24(sp)
    80003020:	6121                	addi	sp,sp,64
    80003022:	8082                	ret
      release(&tickslock);
    80003024:	00014517          	auipc	a0,0x14
    80003028:	2ac50513          	addi	a0,a0,684 # 800172d0 <tickslock>
    8000302c:	ffffe097          	auipc	ra,0xffffe
    80003030:	c6c080e7          	jalr	-916(ra) # 80000c98 <release>
      return -1;
    80003034:	57fd                	li	a5,-1
    80003036:	bff9                	j	80003014 <sys_sleep+0x88>

0000000080003038 <sys_kill>:

uint64
sys_kill(void)
{
    80003038:	1101                	addi	sp,sp,-32
    8000303a:	ec06                	sd	ra,24(sp)
    8000303c:	e822                	sd	s0,16(sp)
    8000303e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003040:	fec40593          	addi	a1,s0,-20
    80003044:	4501                	li	a0,0
    80003046:	00000097          	auipc	ra,0x0
    8000304a:	d84080e7          	jalr	-636(ra) # 80002dca <argint>
    8000304e:	87aa                	mv	a5,a0
    return -1;
    80003050:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003052:	0007c863          	bltz	a5,80003062 <sys_kill+0x2a>
  return kill(pid);
    80003056:	fec42503          	lw	a0,-20(s0)
    8000305a:	fffff097          	auipc	ra,0xfffff
    8000305e:	608080e7          	jalr	1544(ra) # 80002662 <kill>
}
    80003062:	60e2                	ld	ra,24(sp)
    80003064:	6442                	ld	s0,16(sp)
    80003066:	6105                	addi	sp,sp,32
    80003068:	8082                	ret

000000008000306a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000306a:	1101                	addi	sp,sp,-32
    8000306c:	ec06                	sd	ra,24(sp)
    8000306e:	e822                	sd	s0,16(sp)
    80003070:	e426                	sd	s1,8(sp)
    80003072:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003074:	00014517          	auipc	a0,0x14
    80003078:	25c50513          	addi	a0,a0,604 # 800172d0 <tickslock>
    8000307c:	ffffe097          	auipc	ra,0xffffe
    80003080:	b68080e7          	jalr	-1176(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003084:	00006497          	auipc	s1,0x6
    80003088:	fb44a483          	lw	s1,-76(s1) # 80009038 <ticks>
  release(&tickslock);
    8000308c:	00014517          	auipc	a0,0x14
    80003090:	24450513          	addi	a0,a0,580 # 800172d0 <tickslock>
    80003094:	ffffe097          	auipc	ra,0xffffe
    80003098:	c04080e7          	jalr	-1020(ra) # 80000c98 <release>
  return xticks;
}
    8000309c:	02049513          	slli	a0,s1,0x20
    800030a0:	9101                	srli	a0,a0,0x20
    800030a2:	60e2                	ld	ra,24(sp)
    800030a4:	6442                	ld	s0,16(sp)
    800030a6:	64a2                	ld	s1,8(sp)
    800030a8:	6105                	addi	sp,sp,32
    800030aa:	8082                	ret

00000000800030ac <sys_pause_system>:

uint64
sys_pause_system(void)
{
    800030ac:	1101                	addi	sp,sp,-32
    800030ae:	ec06                	sd	ra,24(sp)
    800030b0:	e822                	sd	s0,16(sp)
    800030b2:	1000                	addi	s0,sp,32
  int seconds;
  if(argint(0, &seconds) >= 0)
    800030b4:	fec40593          	addi	a1,s0,-20
    800030b8:	4501                	li	a0,0
    800030ba:	00000097          	auipc	ra,0x0
    800030be:	d10080e7          	jalr	-752(ra) # 80002dca <argint>
    800030c2:	87aa                	mv	a5,a0
  {
    return pause_system(seconds);
  }
  return -1;
    800030c4:	557d                	li	a0,-1
  if(argint(0, &seconds) >= 0)
    800030c6:	0007d663          	bgez	a5,800030d2 <sys_pause_system+0x26>
}
    800030ca:	60e2                	ld	ra,24(sp)
    800030cc:	6442                	ld	s0,16(sp)
    800030ce:	6105                	addi	sp,sp,32
    800030d0:	8082                	ret
    return pause_system(seconds);
    800030d2:	fec42503          	lw	a0,-20(s0)
    800030d6:	fffff097          	auipc	ra,0xfffff
    800030da:	762080e7          	jalr	1890(ra) # 80002838 <pause_system>
    800030de:	b7f5                	j	800030ca <sys_pause_system+0x1e>

00000000800030e0 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    800030e0:	1141                	addi	sp,sp,-16
    800030e2:	e406                	sd	ra,8(sp)
    800030e4:	e022                	sd	s0,0(sp)
    800030e6:	0800                	addi	s0,sp,16
  return kill_system();
    800030e8:	fffff097          	auipc	ra,0xfffff
    800030ec:	786080e7          	jalr	1926(ra) # 8000286e <kill_system>
    800030f0:	60a2                	ld	ra,8(sp)
    800030f2:	6402                	ld	s0,0(sp)
    800030f4:	0141                	addi	sp,sp,16
    800030f6:	8082                	ret

00000000800030f8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030f8:	7179                	addi	sp,sp,-48
    800030fa:	f406                	sd	ra,40(sp)
    800030fc:	f022                	sd	s0,32(sp)
    800030fe:	ec26                	sd	s1,24(sp)
    80003100:	e84a                	sd	s2,16(sp)
    80003102:	e44e                	sd	s3,8(sp)
    80003104:	e052                	sd	s4,0(sp)
    80003106:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003108:	00005597          	auipc	a1,0x5
    8000310c:	41858593          	addi	a1,a1,1048 # 80008520 <syscalls+0xc0>
    80003110:	00014517          	auipc	a0,0x14
    80003114:	1d850513          	addi	a0,a0,472 # 800172e8 <bcache>
    80003118:	ffffe097          	auipc	ra,0xffffe
    8000311c:	a3c080e7          	jalr	-1476(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003120:	0001c797          	auipc	a5,0x1c
    80003124:	1c878793          	addi	a5,a5,456 # 8001f2e8 <bcache+0x8000>
    80003128:	0001c717          	auipc	a4,0x1c
    8000312c:	42870713          	addi	a4,a4,1064 # 8001f550 <bcache+0x8268>
    80003130:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003134:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003138:	00014497          	auipc	s1,0x14
    8000313c:	1c848493          	addi	s1,s1,456 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    80003140:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003142:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003144:	00005a17          	auipc	s4,0x5
    80003148:	3e4a0a13          	addi	s4,s4,996 # 80008528 <syscalls+0xc8>
    b->next = bcache.head.next;
    8000314c:	2b893783          	ld	a5,696(s2)
    80003150:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003152:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003156:	85d2                	mv	a1,s4
    80003158:	01048513          	addi	a0,s1,16
    8000315c:	00001097          	auipc	ra,0x1
    80003160:	4bc080e7          	jalr	1212(ra) # 80004618 <initsleeplock>
    bcache.head.next->prev = b;
    80003164:	2b893783          	ld	a5,696(s2)
    80003168:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000316a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000316e:	45848493          	addi	s1,s1,1112
    80003172:	fd349de3          	bne	s1,s3,8000314c <binit+0x54>
  }
}
    80003176:	70a2                	ld	ra,40(sp)
    80003178:	7402                	ld	s0,32(sp)
    8000317a:	64e2                	ld	s1,24(sp)
    8000317c:	6942                	ld	s2,16(sp)
    8000317e:	69a2                	ld	s3,8(sp)
    80003180:	6a02                	ld	s4,0(sp)
    80003182:	6145                	addi	sp,sp,48
    80003184:	8082                	ret

0000000080003186 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003186:	7179                	addi	sp,sp,-48
    80003188:	f406                	sd	ra,40(sp)
    8000318a:	f022                	sd	s0,32(sp)
    8000318c:	ec26                	sd	s1,24(sp)
    8000318e:	e84a                	sd	s2,16(sp)
    80003190:	e44e                	sd	s3,8(sp)
    80003192:	1800                	addi	s0,sp,48
    80003194:	89aa                	mv	s3,a0
    80003196:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003198:	00014517          	auipc	a0,0x14
    8000319c:	15050513          	addi	a0,a0,336 # 800172e8 <bcache>
    800031a0:	ffffe097          	auipc	ra,0xffffe
    800031a4:	a44080e7          	jalr	-1468(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031a8:	0001c497          	auipc	s1,0x1c
    800031ac:	3f84b483          	ld	s1,1016(s1) # 8001f5a0 <bcache+0x82b8>
    800031b0:	0001c797          	auipc	a5,0x1c
    800031b4:	3a078793          	addi	a5,a5,928 # 8001f550 <bcache+0x8268>
    800031b8:	02f48f63          	beq	s1,a5,800031f6 <bread+0x70>
    800031bc:	873e                	mv	a4,a5
    800031be:	a021                	j	800031c6 <bread+0x40>
    800031c0:	68a4                	ld	s1,80(s1)
    800031c2:	02e48a63          	beq	s1,a4,800031f6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031c6:	449c                	lw	a5,8(s1)
    800031c8:	ff379ce3          	bne	a5,s3,800031c0 <bread+0x3a>
    800031cc:	44dc                	lw	a5,12(s1)
    800031ce:	ff2799e3          	bne	a5,s2,800031c0 <bread+0x3a>
      b->refcnt++;
    800031d2:	40bc                	lw	a5,64(s1)
    800031d4:	2785                	addiw	a5,a5,1
    800031d6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031d8:	00014517          	auipc	a0,0x14
    800031dc:	11050513          	addi	a0,a0,272 # 800172e8 <bcache>
    800031e0:	ffffe097          	auipc	ra,0xffffe
    800031e4:	ab8080e7          	jalr	-1352(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800031e8:	01048513          	addi	a0,s1,16
    800031ec:	00001097          	auipc	ra,0x1
    800031f0:	466080e7          	jalr	1126(ra) # 80004652 <acquiresleep>
      return b;
    800031f4:	a8b9                	j	80003252 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031f6:	0001c497          	auipc	s1,0x1c
    800031fa:	3a24b483          	ld	s1,930(s1) # 8001f598 <bcache+0x82b0>
    800031fe:	0001c797          	auipc	a5,0x1c
    80003202:	35278793          	addi	a5,a5,850 # 8001f550 <bcache+0x8268>
    80003206:	00f48863          	beq	s1,a5,80003216 <bread+0x90>
    8000320a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000320c:	40bc                	lw	a5,64(s1)
    8000320e:	cf81                	beqz	a5,80003226 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003210:	64a4                	ld	s1,72(s1)
    80003212:	fee49de3          	bne	s1,a4,8000320c <bread+0x86>
  panic("bget: no buffers");
    80003216:	00005517          	auipc	a0,0x5
    8000321a:	31a50513          	addi	a0,a0,794 # 80008530 <syscalls+0xd0>
    8000321e:	ffffd097          	auipc	ra,0xffffd
    80003222:	320080e7          	jalr	800(ra) # 8000053e <panic>
      b->dev = dev;
    80003226:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000322a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000322e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003232:	4785                	li	a5,1
    80003234:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003236:	00014517          	auipc	a0,0x14
    8000323a:	0b250513          	addi	a0,a0,178 # 800172e8 <bcache>
    8000323e:	ffffe097          	auipc	ra,0xffffe
    80003242:	a5a080e7          	jalr	-1446(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003246:	01048513          	addi	a0,s1,16
    8000324a:	00001097          	auipc	ra,0x1
    8000324e:	408080e7          	jalr	1032(ra) # 80004652 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003252:	409c                	lw	a5,0(s1)
    80003254:	cb89                	beqz	a5,80003266 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003256:	8526                	mv	a0,s1
    80003258:	70a2                	ld	ra,40(sp)
    8000325a:	7402                	ld	s0,32(sp)
    8000325c:	64e2                	ld	s1,24(sp)
    8000325e:	6942                	ld	s2,16(sp)
    80003260:	69a2                	ld	s3,8(sp)
    80003262:	6145                	addi	sp,sp,48
    80003264:	8082                	ret
    virtio_disk_rw(b, 0);
    80003266:	4581                	li	a1,0
    80003268:	8526                	mv	a0,s1
    8000326a:	00003097          	auipc	ra,0x3
    8000326e:	f0c080e7          	jalr	-244(ra) # 80006176 <virtio_disk_rw>
    b->valid = 1;
    80003272:	4785                	li	a5,1
    80003274:	c09c                	sw	a5,0(s1)
  return b;
    80003276:	b7c5                	j	80003256 <bread+0xd0>

0000000080003278 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003278:	1101                	addi	sp,sp,-32
    8000327a:	ec06                	sd	ra,24(sp)
    8000327c:	e822                	sd	s0,16(sp)
    8000327e:	e426                	sd	s1,8(sp)
    80003280:	1000                	addi	s0,sp,32
    80003282:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003284:	0541                	addi	a0,a0,16
    80003286:	00001097          	auipc	ra,0x1
    8000328a:	466080e7          	jalr	1126(ra) # 800046ec <holdingsleep>
    8000328e:	cd01                	beqz	a0,800032a6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003290:	4585                	li	a1,1
    80003292:	8526                	mv	a0,s1
    80003294:	00003097          	auipc	ra,0x3
    80003298:	ee2080e7          	jalr	-286(ra) # 80006176 <virtio_disk_rw>
}
    8000329c:	60e2                	ld	ra,24(sp)
    8000329e:	6442                	ld	s0,16(sp)
    800032a0:	64a2                	ld	s1,8(sp)
    800032a2:	6105                	addi	sp,sp,32
    800032a4:	8082                	ret
    panic("bwrite");
    800032a6:	00005517          	auipc	a0,0x5
    800032aa:	2a250513          	addi	a0,a0,674 # 80008548 <syscalls+0xe8>
    800032ae:	ffffd097          	auipc	ra,0xffffd
    800032b2:	290080e7          	jalr	656(ra) # 8000053e <panic>

00000000800032b6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032b6:	1101                	addi	sp,sp,-32
    800032b8:	ec06                	sd	ra,24(sp)
    800032ba:	e822                	sd	s0,16(sp)
    800032bc:	e426                	sd	s1,8(sp)
    800032be:	e04a                	sd	s2,0(sp)
    800032c0:	1000                	addi	s0,sp,32
    800032c2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032c4:	01050913          	addi	s2,a0,16
    800032c8:	854a                	mv	a0,s2
    800032ca:	00001097          	auipc	ra,0x1
    800032ce:	422080e7          	jalr	1058(ra) # 800046ec <holdingsleep>
    800032d2:	c92d                	beqz	a0,80003344 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032d4:	854a                	mv	a0,s2
    800032d6:	00001097          	auipc	ra,0x1
    800032da:	3d2080e7          	jalr	978(ra) # 800046a8 <releasesleep>

  acquire(&bcache.lock);
    800032de:	00014517          	auipc	a0,0x14
    800032e2:	00a50513          	addi	a0,a0,10 # 800172e8 <bcache>
    800032e6:	ffffe097          	auipc	ra,0xffffe
    800032ea:	8fe080e7          	jalr	-1794(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032ee:	40bc                	lw	a5,64(s1)
    800032f0:	37fd                	addiw	a5,a5,-1
    800032f2:	0007871b          	sext.w	a4,a5
    800032f6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032f8:	eb05                	bnez	a4,80003328 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032fa:	68bc                	ld	a5,80(s1)
    800032fc:	64b8                	ld	a4,72(s1)
    800032fe:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003300:	64bc                	ld	a5,72(s1)
    80003302:	68b8                	ld	a4,80(s1)
    80003304:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003306:	0001c797          	auipc	a5,0x1c
    8000330a:	fe278793          	addi	a5,a5,-30 # 8001f2e8 <bcache+0x8000>
    8000330e:	2b87b703          	ld	a4,696(a5)
    80003312:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003314:	0001c717          	auipc	a4,0x1c
    80003318:	23c70713          	addi	a4,a4,572 # 8001f550 <bcache+0x8268>
    8000331c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000331e:	2b87b703          	ld	a4,696(a5)
    80003322:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003324:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003328:	00014517          	auipc	a0,0x14
    8000332c:	fc050513          	addi	a0,a0,-64 # 800172e8 <bcache>
    80003330:	ffffe097          	auipc	ra,0xffffe
    80003334:	968080e7          	jalr	-1688(ra) # 80000c98 <release>
}
    80003338:	60e2                	ld	ra,24(sp)
    8000333a:	6442                	ld	s0,16(sp)
    8000333c:	64a2                	ld	s1,8(sp)
    8000333e:	6902                	ld	s2,0(sp)
    80003340:	6105                	addi	sp,sp,32
    80003342:	8082                	ret
    panic("brelse");
    80003344:	00005517          	auipc	a0,0x5
    80003348:	20c50513          	addi	a0,a0,524 # 80008550 <syscalls+0xf0>
    8000334c:	ffffd097          	auipc	ra,0xffffd
    80003350:	1f2080e7          	jalr	498(ra) # 8000053e <panic>

0000000080003354 <bpin>:

void
bpin(struct buf *b) {
    80003354:	1101                	addi	sp,sp,-32
    80003356:	ec06                	sd	ra,24(sp)
    80003358:	e822                	sd	s0,16(sp)
    8000335a:	e426                	sd	s1,8(sp)
    8000335c:	1000                	addi	s0,sp,32
    8000335e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003360:	00014517          	auipc	a0,0x14
    80003364:	f8850513          	addi	a0,a0,-120 # 800172e8 <bcache>
    80003368:	ffffe097          	auipc	ra,0xffffe
    8000336c:	87c080e7          	jalr	-1924(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003370:	40bc                	lw	a5,64(s1)
    80003372:	2785                	addiw	a5,a5,1
    80003374:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003376:	00014517          	auipc	a0,0x14
    8000337a:	f7250513          	addi	a0,a0,-142 # 800172e8 <bcache>
    8000337e:	ffffe097          	auipc	ra,0xffffe
    80003382:	91a080e7          	jalr	-1766(ra) # 80000c98 <release>
}
    80003386:	60e2                	ld	ra,24(sp)
    80003388:	6442                	ld	s0,16(sp)
    8000338a:	64a2                	ld	s1,8(sp)
    8000338c:	6105                	addi	sp,sp,32
    8000338e:	8082                	ret

0000000080003390 <bunpin>:

void
bunpin(struct buf *b) {
    80003390:	1101                	addi	sp,sp,-32
    80003392:	ec06                	sd	ra,24(sp)
    80003394:	e822                	sd	s0,16(sp)
    80003396:	e426                	sd	s1,8(sp)
    80003398:	1000                	addi	s0,sp,32
    8000339a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000339c:	00014517          	auipc	a0,0x14
    800033a0:	f4c50513          	addi	a0,a0,-180 # 800172e8 <bcache>
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	840080e7          	jalr	-1984(ra) # 80000be4 <acquire>
  b->refcnt--;
    800033ac:	40bc                	lw	a5,64(s1)
    800033ae:	37fd                	addiw	a5,a5,-1
    800033b0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033b2:	00014517          	auipc	a0,0x14
    800033b6:	f3650513          	addi	a0,a0,-202 # 800172e8 <bcache>
    800033ba:	ffffe097          	auipc	ra,0xffffe
    800033be:	8de080e7          	jalr	-1826(ra) # 80000c98 <release>
}
    800033c2:	60e2                	ld	ra,24(sp)
    800033c4:	6442                	ld	s0,16(sp)
    800033c6:	64a2                	ld	s1,8(sp)
    800033c8:	6105                	addi	sp,sp,32
    800033ca:	8082                	ret

00000000800033cc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033cc:	1101                	addi	sp,sp,-32
    800033ce:	ec06                	sd	ra,24(sp)
    800033d0:	e822                	sd	s0,16(sp)
    800033d2:	e426                	sd	s1,8(sp)
    800033d4:	e04a                	sd	s2,0(sp)
    800033d6:	1000                	addi	s0,sp,32
    800033d8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033da:	00d5d59b          	srliw	a1,a1,0xd
    800033de:	0001c797          	auipc	a5,0x1c
    800033e2:	5e67a783          	lw	a5,1510(a5) # 8001f9c4 <sb+0x1c>
    800033e6:	9dbd                	addw	a1,a1,a5
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	d9e080e7          	jalr	-610(ra) # 80003186 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033f0:	0074f713          	andi	a4,s1,7
    800033f4:	4785                	li	a5,1
    800033f6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033fa:	14ce                	slli	s1,s1,0x33
    800033fc:	90d9                	srli	s1,s1,0x36
    800033fe:	00950733          	add	a4,a0,s1
    80003402:	05874703          	lbu	a4,88(a4)
    80003406:	00e7f6b3          	and	a3,a5,a4
    8000340a:	c69d                	beqz	a3,80003438 <bfree+0x6c>
    8000340c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000340e:	94aa                	add	s1,s1,a0
    80003410:	fff7c793          	not	a5,a5
    80003414:	8ff9                	and	a5,a5,a4
    80003416:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000341a:	00001097          	auipc	ra,0x1
    8000341e:	118080e7          	jalr	280(ra) # 80004532 <log_write>
  brelse(bp);
    80003422:	854a                	mv	a0,s2
    80003424:	00000097          	auipc	ra,0x0
    80003428:	e92080e7          	jalr	-366(ra) # 800032b6 <brelse>
}
    8000342c:	60e2                	ld	ra,24(sp)
    8000342e:	6442                	ld	s0,16(sp)
    80003430:	64a2                	ld	s1,8(sp)
    80003432:	6902                	ld	s2,0(sp)
    80003434:	6105                	addi	sp,sp,32
    80003436:	8082                	ret
    panic("freeing free block");
    80003438:	00005517          	auipc	a0,0x5
    8000343c:	12050513          	addi	a0,a0,288 # 80008558 <syscalls+0xf8>
    80003440:	ffffd097          	auipc	ra,0xffffd
    80003444:	0fe080e7          	jalr	254(ra) # 8000053e <panic>

0000000080003448 <balloc>:
{
    80003448:	711d                	addi	sp,sp,-96
    8000344a:	ec86                	sd	ra,88(sp)
    8000344c:	e8a2                	sd	s0,80(sp)
    8000344e:	e4a6                	sd	s1,72(sp)
    80003450:	e0ca                	sd	s2,64(sp)
    80003452:	fc4e                	sd	s3,56(sp)
    80003454:	f852                	sd	s4,48(sp)
    80003456:	f456                	sd	s5,40(sp)
    80003458:	f05a                	sd	s6,32(sp)
    8000345a:	ec5e                	sd	s7,24(sp)
    8000345c:	e862                	sd	s8,16(sp)
    8000345e:	e466                	sd	s9,8(sp)
    80003460:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003462:	0001c797          	auipc	a5,0x1c
    80003466:	54a7a783          	lw	a5,1354(a5) # 8001f9ac <sb+0x4>
    8000346a:	cbd1                	beqz	a5,800034fe <balloc+0xb6>
    8000346c:	8baa                	mv	s7,a0
    8000346e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003470:	0001cb17          	auipc	s6,0x1c
    80003474:	538b0b13          	addi	s6,s6,1336 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003478:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000347a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000347c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000347e:	6c89                	lui	s9,0x2
    80003480:	a831                	j	8000349c <balloc+0x54>
    brelse(bp);
    80003482:	854a                	mv	a0,s2
    80003484:	00000097          	auipc	ra,0x0
    80003488:	e32080e7          	jalr	-462(ra) # 800032b6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000348c:	015c87bb          	addw	a5,s9,s5
    80003490:	00078a9b          	sext.w	s5,a5
    80003494:	004b2703          	lw	a4,4(s6)
    80003498:	06eaf363          	bgeu	s5,a4,800034fe <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000349c:	41fad79b          	sraiw	a5,s5,0x1f
    800034a0:	0137d79b          	srliw	a5,a5,0x13
    800034a4:	015787bb          	addw	a5,a5,s5
    800034a8:	40d7d79b          	sraiw	a5,a5,0xd
    800034ac:	01cb2583          	lw	a1,28(s6)
    800034b0:	9dbd                	addw	a1,a1,a5
    800034b2:	855e                	mv	a0,s7
    800034b4:	00000097          	auipc	ra,0x0
    800034b8:	cd2080e7          	jalr	-814(ra) # 80003186 <bread>
    800034bc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034be:	004b2503          	lw	a0,4(s6)
    800034c2:	000a849b          	sext.w	s1,s5
    800034c6:	8662                	mv	a2,s8
    800034c8:	faa4fde3          	bgeu	s1,a0,80003482 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034cc:	41f6579b          	sraiw	a5,a2,0x1f
    800034d0:	01d7d69b          	srliw	a3,a5,0x1d
    800034d4:	00c6873b          	addw	a4,a3,a2
    800034d8:	00777793          	andi	a5,a4,7
    800034dc:	9f95                	subw	a5,a5,a3
    800034de:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034e2:	4037571b          	sraiw	a4,a4,0x3
    800034e6:	00e906b3          	add	a3,s2,a4
    800034ea:	0586c683          	lbu	a3,88(a3)
    800034ee:	00d7f5b3          	and	a1,a5,a3
    800034f2:	cd91                	beqz	a1,8000350e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034f4:	2605                	addiw	a2,a2,1
    800034f6:	2485                	addiw	s1,s1,1
    800034f8:	fd4618e3          	bne	a2,s4,800034c8 <balloc+0x80>
    800034fc:	b759                	j	80003482 <balloc+0x3a>
  panic("balloc: out of blocks");
    800034fe:	00005517          	auipc	a0,0x5
    80003502:	07250513          	addi	a0,a0,114 # 80008570 <syscalls+0x110>
    80003506:	ffffd097          	auipc	ra,0xffffd
    8000350a:	038080e7          	jalr	56(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000350e:	974a                	add	a4,a4,s2
    80003510:	8fd5                	or	a5,a5,a3
    80003512:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003516:	854a                	mv	a0,s2
    80003518:	00001097          	auipc	ra,0x1
    8000351c:	01a080e7          	jalr	26(ra) # 80004532 <log_write>
        brelse(bp);
    80003520:	854a                	mv	a0,s2
    80003522:	00000097          	auipc	ra,0x0
    80003526:	d94080e7          	jalr	-620(ra) # 800032b6 <brelse>
  bp = bread(dev, bno);
    8000352a:	85a6                	mv	a1,s1
    8000352c:	855e                	mv	a0,s7
    8000352e:	00000097          	auipc	ra,0x0
    80003532:	c58080e7          	jalr	-936(ra) # 80003186 <bread>
    80003536:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003538:	40000613          	li	a2,1024
    8000353c:	4581                	li	a1,0
    8000353e:	05850513          	addi	a0,a0,88
    80003542:	ffffd097          	auipc	ra,0xffffd
    80003546:	79e080e7          	jalr	1950(ra) # 80000ce0 <memset>
  log_write(bp);
    8000354a:	854a                	mv	a0,s2
    8000354c:	00001097          	auipc	ra,0x1
    80003550:	fe6080e7          	jalr	-26(ra) # 80004532 <log_write>
  brelse(bp);
    80003554:	854a                	mv	a0,s2
    80003556:	00000097          	auipc	ra,0x0
    8000355a:	d60080e7          	jalr	-672(ra) # 800032b6 <brelse>
}
    8000355e:	8526                	mv	a0,s1
    80003560:	60e6                	ld	ra,88(sp)
    80003562:	6446                	ld	s0,80(sp)
    80003564:	64a6                	ld	s1,72(sp)
    80003566:	6906                	ld	s2,64(sp)
    80003568:	79e2                	ld	s3,56(sp)
    8000356a:	7a42                	ld	s4,48(sp)
    8000356c:	7aa2                	ld	s5,40(sp)
    8000356e:	7b02                	ld	s6,32(sp)
    80003570:	6be2                	ld	s7,24(sp)
    80003572:	6c42                	ld	s8,16(sp)
    80003574:	6ca2                	ld	s9,8(sp)
    80003576:	6125                	addi	sp,sp,96
    80003578:	8082                	ret

000000008000357a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000357a:	7179                	addi	sp,sp,-48
    8000357c:	f406                	sd	ra,40(sp)
    8000357e:	f022                	sd	s0,32(sp)
    80003580:	ec26                	sd	s1,24(sp)
    80003582:	e84a                	sd	s2,16(sp)
    80003584:	e44e                	sd	s3,8(sp)
    80003586:	e052                	sd	s4,0(sp)
    80003588:	1800                	addi	s0,sp,48
    8000358a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000358c:	47ad                	li	a5,11
    8000358e:	04b7fe63          	bgeu	a5,a1,800035ea <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003592:	ff45849b          	addiw	s1,a1,-12
    80003596:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000359a:	0ff00793          	li	a5,255
    8000359e:	0ae7e363          	bltu	a5,a4,80003644 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035a2:	08052583          	lw	a1,128(a0)
    800035a6:	c5ad                	beqz	a1,80003610 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035a8:	00092503          	lw	a0,0(s2)
    800035ac:	00000097          	auipc	ra,0x0
    800035b0:	bda080e7          	jalr	-1062(ra) # 80003186 <bread>
    800035b4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035b6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035ba:	02049593          	slli	a1,s1,0x20
    800035be:	9181                	srli	a1,a1,0x20
    800035c0:	058a                	slli	a1,a1,0x2
    800035c2:	00b784b3          	add	s1,a5,a1
    800035c6:	0004a983          	lw	s3,0(s1)
    800035ca:	04098d63          	beqz	s3,80003624 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035ce:	8552                	mv	a0,s4
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	ce6080e7          	jalr	-794(ra) # 800032b6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035d8:	854e                	mv	a0,s3
    800035da:	70a2                	ld	ra,40(sp)
    800035dc:	7402                	ld	s0,32(sp)
    800035de:	64e2                	ld	s1,24(sp)
    800035e0:	6942                	ld	s2,16(sp)
    800035e2:	69a2                	ld	s3,8(sp)
    800035e4:	6a02                	ld	s4,0(sp)
    800035e6:	6145                	addi	sp,sp,48
    800035e8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035ea:	02059493          	slli	s1,a1,0x20
    800035ee:	9081                	srli	s1,s1,0x20
    800035f0:	048a                	slli	s1,s1,0x2
    800035f2:	94aa                	add	s1,s1,a0
    800035f4:	0504a983          	lw	s3,80(s1)
    800035f8:	fe0990e3          	bnez	s3,800035d8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035fc:	4108                	lw	a0,0(a0)
    800035fe:	00000097          	auipc	ra,0x0
    80003602:	e4a080e7          	jalr	-438(ra) # 80003448 <balloc>
    80003606:	0005099b          	sext.w	s3,a0
    8000360a:	0534a823          	sw	s3,80(s1)
    8000360e:	b7e9                	j	800035d8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003610:	4108                	lw	a0,0(a0)
    80003612:	00000097          	auipc	ra,0x0
    80003616:	e36080e7          	jalr	-458(ra) # 80003448 <balloc>
    8000361a:	0005059b          	sext.w	a1,a0
    8000361e:	08b92023          	sw	a1,128(s2)
    80003622:	b759                	j	800035a8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003624:	00092503          	lw	a0,0(s2)
    80003628:	00000097          	auipc	ra,0x0
    8000362c:	e20080e7          	jalr	-480(ra) # 80003448 <balloc>
    80003630:	0005099b          	sext.w	s3,a0
    80003634:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003638:	8552                	mv	a0,s4
    8000363a:	00001097          	auipc	ra,0x1
    8000363e:	ef8080e7          	jalr	-264(ra) # 80004532 <log_write>
    80003642:	b771                	j	800035ce <bmap+0x54>
  panic("bmap: out of range");
    80003644:	00005517          	auipc	a0,0x5
    80003648:	f4450513          	addi	a0,a0,-188 # 80008588 <syscalls+0x128>
    8000364c:	ffffd097          	auipc	ra,0xffffd
    80003650:	ef2080e7          	jalr	-270(ra) # 8000053e <panic>

0000000080003654 <iget>:
{
    80003654:	7179                	addi	sp,sp,-48
    80003656:	f406                	sd	ra,40(sp)
    80003658:	f022                	sd	s0,32(sp)
    8000365a:	ec26                	sd	s1,24(sp)
    8000365c:	e84a                	sd	s2,16(sp)
    8000365e:	e44e                	sd	s3,8(sp)
    80003660:	e052                	sd	s4,0(sp)
    80003662:	1800                	addi	s0,sp,48
    80003664:	89aa                	mv	s3,a0
    80003666:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003668:	0001c517          	auipc	a0,0x1c
    8000366c:	36050513          	addi	a0,a0,864 # 8001f9c8 <itable>
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	574080e7          	jalr	1396(ra) # 80000be4 <acquire>
  empty = 0;
    80003678:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000367a:	0001c497          	auipc	s1,0x1c
    8000367e:	36648493          	addi	s1,s1,870 # 8001f9e0 <itable+0x18>
    80003682:	0001e697          	auipc	a3,0x1e
    80003686:	dee68693          	addi	a3,a3,-530 # 80021470 <log>
    8000368a:	a039                	j	80003698 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000368c:	02090b63          	beqz	s2,800036c2 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003690:	08848493          	addi	s1,s1,136
    80003694:	02d48a63          	beq	s1,a3,800036c8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003698:	449c                	lw	a5,8(s1)
    8000369a:	fef059e3          	blez	a5,8000368c <iget+0x38>
    8000369e:	4098                	lw	a4,0(s1)
    800036a0:	ff3716e3          	bne	a4,s3,8000368c <iget+0x38>
    800036a4:	40d8                	lw	a4,4(s1)
    800036a6:	ff4713e3          	bne	a4,s4,8000368c <iget+0x38>
      ip->ref++;
    800036aa:	2785                	addiw	a5,a5,1
    800036ac:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036ae:	0001c517          	auipc	a0,0x1c
    800036b2:	31a50513          	addi	a0,a0,794 # 8001f9c8 <itable>
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	5e2080e7          	jalr	1506(ra) # 80000c98 <release>
      return ip;
    800036be:	8926                	mv	s2,s1
    800036c0:	a03d                	j	800036ee <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036c2:	f7f9                	bnez	a5,80003690 <iget+0x3c>
    800036c4:	8926                	mv	s2,s1
    800036c6:	b7e9                	j	80003690 <iget+0x3c>
  if(empty == 0)
    800036c8:	02090c63          	beqz	s2,80003700 <iget+0xac>
  ip->dev = dev;
    800036cc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036d0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036d4:	4785                	li	a5,1
    800036d6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036da:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800036de:	0001c517          	auipc	a0,0x1c
    800036e2:	2ea50513          	addi	a0,a0,746 # 8001f9c8 <itable>
    800036e6:	ffffd097          	auipc	ra,0xffffd
    800036ea:	5b2080e7          	jalr	1458(ra) # 80000c98 <release>
}
    800036ee:	854a                	mv	a0,s2
    800036f0:	70a2                	ld	ra,40(sp)
    800036f2:	7402                	ld	s0,32(sp)
    800036f4:	64e2                	ld	s1,24(sp)
    800036f6:	6942                	ld	s2,16(sp)
    800036f8:	69a2                	ld	s3,8(sp)
    800036fa:	6a02                	ld	s4,0(sp)
    800036fc:	6145                	addi	sp,sp,48
    800036fe:	8082                	ret
    panic("iget: no inodes");
    80003700:	00005517          	auipc	a0,0x5
    80003704:	ea050513          	addi	a0,a0,-352 # 800085a0 <syscalls+0x140>
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	e36080e7          	jalr	-458(ra) # 8000053e <panic>

0000000080003710 <fsinit>:
fsinit(int dev) {
    80003710:	7179                	addi	sp,sp,-48
    80003712:	f406                	sd	ra,40(sp)
    80003714:	f022                	sd	s0,32(sp)
    80003716:	ec26                	sd	s1,24(sp)
    80003718:	e84a                	sd	s2,16(sp)
    8000371a:	e44e                	sd	s3,8(sp)
    8000371c:	1800                	addi	s0,sp,48
    8000371e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003720:	4585                	li	a1,1
    80003722:	00000097          	auipc	ra,0x0
    80003726:	a64080e7          	jalr	-1436(ra) # 80003186 <bread>
    8000372a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000372c:	0001c997          	auipc	s3,0x1c
    80003730:	27c98993          	addi	s3,s3,636 # 8001f9a8 <sb>
    80003734:	02000613          	li	a2,32
    80003738:	05850593          	addi	a1,a0,88
    8000373c:	854e                	mv	a0,s3
    8000373e:	ffffd097          	auipc	ra,0xffffd
    80003742:	602080e7          	jalr	1538(ra) # 80000d40 <memmove>
  brelse(bp);
    80003746:	8526                	mv	a0,s1
    80003748:	00000097          	auipc	ra,0x0
    8000374c:	b6e080e7          	jalr	-1170(ra) # 800032b6 <brelse>
  if(sb.magic != FSMAGIC)
    80003750:	0009a703          	lw	a4,0(s3)
    80003754:	102037b7          	lui	a5,0x10203
    80003758:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000375c:	02f71263          	bne	a4,a5,80003780 <fsinit+0x70>
  initlog(dev, &sb);
    80003760:	0001c597          	auipc	a1,0x1c
    80003764:	24858593          	addi	a1,a1,584 # 8001f9a8 <sb>
    80003768:	854a                	mv	a0,s2
    8000376a:	00001097          	auipc	ra,0x1
    8000376e:	b4c080e7          	jalr	-1204(ra) # 800042b6 <initlog>
}
    80003772:	70a2                	ld	ra,40(sp)
    80003774:	7402                	ld	s0,32(sp)
    80003776:	64e2                	ld	s1,24(sp)
    80003778:	6942                	ld	s2,16(sp)
    8000377a:	69a2                	ld	s3,8(sp)
    8000377c:	6145                	addi	sp,sp,48
    8000377e:	8082                	ret
    panic("invalid file system");
    80003780:	00005517          	auipc	a0,0x5
    80003784:	e3050513          	addi	a0,a0,-464 # 800085b0 <syscalls+0x150>
    80003788:	ffffd097          	auipc	ra,0xffffd
    8000378c:	db6080e7          	jalr	-586(ra) # 8000053e <panic>

0000000080003790 <iinit>:
{
    80003790:	7179                	addi	sp,sp,-48
    80003792:	f406                	sd	ra,40(sp)
    80003794:	f022                	sd	s0,32(sp)
    80003796:	ec26                	sd	s1,24(sp)
    80003798:	e84a                	sd	s2,16(sp)
    8000379a:	e44e                	sd	s3,8(sp)
    8000379c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000379e:	00005597          	auipc	a1,0x5
    800037a2:	e2a58593          	addi	a1,a1,-470 # 800085c8 <syscalls+0x168>
    800037a6:	0001c517          	auipc	a0,0x1c
    800037aa:	22250513          	addi	a0,a0,546 # 8001f9c8 <itable>
    800037ae:	ffffd097          	auipc	ra,0xffffd
    800037b2:	3a6080e7          	jalr	934(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037b6:	0001c497          	auipc	s1,0x1c
    800037ba:	23a48493          	addi	s1,s1,570 # 8001f9f0 <itable+0x28>
    800037be:	0001e997          	auipc	s3,0x1e
    800037c2:	cc298993          	addi	s3,s3,-830 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800037c6:	00005917          	auipc	s2,0x5
    800037ca:	e0a90913          	addi	s2,s2,-502 # 800085d0 <syscalls+0x170>
    800037ce:	85ca                	mv	a1,s2
    800037d0:	8526                	mv	a0,s1
    800037d2:	00001097          	auipc	ra,0x1
    800037d6:	e46080e7          	jalr	-442(ra) # 80004618 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037da:	08848493          	addi	s1,s1,136
    800037de:	ff3498e3          	bne	s1,s3,800037ce <iinit+0x3e>
}
    800037e2:	70a2                	ld	ra,40(sp)
    800037e4:	7402                	ld	s0,32(sp)
    800037e6:	64e2                	ld	s1,24(sp)
    800037e8:	6942                	ld	s2,16(sp)
    800037ea:	69a2                	ld	s3,8(sp)
    800037ec:	6145                	addi	sp,sp,48
    800037ee:	8082                	ret

00000000800037f0 <ialloc>:
{
    800037f0:	715d                	addi	sp,sp,-80
    800037f2:	e486                	sd	ra,72(sp)
    800037f4:	e0a2                	sd	s0,64(sp)
    800037f6:	fc26                	sd	s1,56(sp)
    800037f8:	f84a                	sd	s2,48(sp)
    800037fa:	f44e                	sd	s3,40(sp)
    800037fc:	f052                	sd	s4,32(sp)
    800037fe:	ec56                	sd	s5,24(sp)
    80003800:	e85a                	sd	s6,16(sp)
    80003802:	e45e                	sd	s7,8(sp)
    80003804:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003806:	0001c717          	auipc	a4,0x1c
    8000380a:	1ae72703          	lw	a4,430(a4) # 8001f9b4 <sb+0xc>
    8000380e:	4785                	li	a5,1
    80003810:	04e7fa63          	bgeu	a5,a4,80003864 <ialloc+0x74>
    80003814:	8aaa                	mv	s5,a0
    80003816:	8bae                	mv	s7,a1
    80003818:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000381a:	0001ca17          	auipc	s4,0x1c
    8000381e:	18ea0a13          	addi	s4,s4,398 # 8001f9a8 <sb>
    80003822:	00048b1b          	sext.w	s6,s1
    80003826:	0044d593          	srli	a1,s1,0x4
    8000382a:	018a2783          	lw	a5,24(s4)
    8000382e:	9dbd                	addw	a1,a1,a5
    80003830:	8556                	mv	a0,s5
    80003832:	00000097          	auipc	ra,0x0
    80003836:	954080e7          	jalr	-1708(ra) # 80003186 <bread>
    8000383a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000383c:	05850993          	addi	s3,a0,88
    80003840:	00f4f793          	andi	a5,s1,15
    80003844:	079a                	slli	a5,a5,0x6
    80003846:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003848:	00099783          	lh	a5,0(s3)
    8000384c:	c785                	beqz	a5,80003874 <ialloc+0x84>
    brelse(bp);
    8000384e:	00000097          	auipc	ra,0x0
    80003852:	a68080e7          	jalr	-1432(ra) # 800032b6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003856:	0485                	addi	s1,s1,1
    80003858:	00ca2703          	lw	a4,12(s4)
    8000385c:	0004879b          	sext.w	a5,s1
    80003860:	fce7e1e3          	bltu	a5,a4,80003822 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003864:	00005517          	auipc	a0,0x5
    80003868:	d7450513          	addi	a0,a0,-652 # 800085d8 <syscalls+0x178>
    8000386c:	ffffd097          	auipc	ra,0xffffd
    80003870:	cd2080e7          	jalr	-814(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003874:	04000613          	li	a2,64
    80003878:	4581                	li	a1,0
    8000387a:	854e                	mv	a0,s3
    8000387c:	ffffd097          	auipc	ra,0xffffd
    80003880:	464080e7          	jalr	1124(ra) # 80000ce0 <memset>
      dip->type = type;
    80003884:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003888:	854a                	mv	a0,s2
    8000388a:	00001097          	auipc	ra,0x1
    8000388e:	ca8080e7          	jalr	-856(ra) # 80004532 <log_write>
      brelse(bp);
    80003892:	854a                	mv	a0,s2
    80003894:	00000097          	auipc	ra,0x0
    80003898:	a22080e7          	jalr	-1502(ra) # 800032b6 <brelse>
      return iget(dev, inum);
    8000389c:	85da                	mv	a1,s6
    8000389e:	8556                	mv	a0,s5
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	db4080e7          	jalr	-588(ra) # 80003654 <iget>
}
    800038a8:	60a6                	ld	ra,72(sp)
    800038aa:	6406                	ld	s0,64(sp)
    800038ac:	74e2                	ld	s1,56(sp)
    800038ae:	7942                	ld	s2,48(sp)
    800038b0:	79a2                	ld	s3,40(sp)
    800038b2:	7a02                	ld	s4,32(sp)
    800038b4:	6ae2                	ld	s5,24(sp)
    800038b6:	6b42                	ld	s6,16(sp)
    800038b8:	6ba2                	ld	s7,8(sp)
    800038ba:	6161                	addi	sp,sp,80
    800038bc:	8082                	ret

00000000800038be <iupdate>:
{
    800038be:	1101                	addi	sp,sp,-32
    800038c0:	ec06                	sd	ra,24(sp)
    800038c2:	e822                	sd	s0,16(sp)
    800038c4:	e426                	sd	s1,8(sp)
    800038c6:	e04a                	sd	s2,0(sp)
    800038c8:	1000                	addi	s0,sp,32
    800038ca:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038cc:	415c                	lw	a5,4(a0)
    800038ce:	0047d79b          	srliw	a5,a5,0x4
    800038d2:	0001c597          	auipc	a1,0x1c
    800038d6:	0ee5a583          	lw	a1,238(a1) # 8001f9c0 <sb+0x18>
    800038da:	9dbd                	addw	a1,a1,a5
    800038dc:	4108                	lw	a0,0(a0)
    800038de:	00000097          	auipc	ra,0x0
    800038e2:	8a8080e7          	jalr	-1880(ra) # 80003186 <bread>
    800038e6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038e8:	05850793          	addi	a5,a0,88
    800038ec:	40c8                	lw	a0,4(s1)
    800038ee:	893d                	andi	a0,a0,15
    800038f0:	051a                	slli	a0,a0,0x6
    800038f2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038f4:	04449703          	lh	a4,68(s1)
    800038f8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038fc:	04649703          	lh	a4,70(s1)
    80003900:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003904:	04849703          	lh	a4,72(s1)
    80003908:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000390c:	04a49703          	lh	a4,74(s1)
    80003910:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003914:	44f8                	lw	a4,76(s1)
    80003916:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003918:	03400613          	li	a2,52
    8000391c:	05048593          	addi	a1,s1,80
    80003920:	0531                	addi	a0,a0,12
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	41e080e7          	jalr	1054(ra) # 80000d40 <memmove>
  log_write(bp);
    8000392a:	854a                	mv	a0,s2
    8000392c:	00001097          	auipc	ra,0x1
    80003930:	c06080e7          	jalr	-1018(ra) # 80004532 <log_write>
  brelse(bp);
    80003934:	854a                	mv	a0,s2
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	980080e7          	jalr	-1664(ra) # 800032b6 <brelse>
}
    8000393e:	60e2                	ld	ra,24(sp)
    80003940:	6442                	ld	s0,16(sp)
    80003942:	64a2                	ld	s1,8(sp)
    80003944:	6902                	ld	s2,0(sp)
    80003946:	6105                	addi	sp,sp,32
    80003948:	8082                	ret

000000008000394a <idup>:
{
    8000394a:	1101                	addi	sp,sp,-32
    8000394c:	ec06                	sd	ra,24(sp)
    8000394e:	e822                	sd	s0,16(sp)
    80003950:	e426                	sd	s1,8(sp)
    80003952:	1000                	addi	s0,sp,32
    80003954:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003956:	0001c517          	auipc	a0,0x1c
    8000395a:	07250513          	addi	a0,a0,114 # 8001f9c8 <itable>
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	286080e7          	jalr	646(ra) # 80000be4 <acquire>
  ip->ref++;
    80003966:	449c                	lw	a5,8(s1)
    80003968:	2785                	addiw	a5,a5,1
    8000396a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000396c:	0001c517          	auipc	a0,0x1c
    80003970:	05c50513          	addi	a0,a0,92 # 8001f9c8 <itable>
    80003974:	ffffd097          	auipc	ra,0xffffd
    80003978:	324080e7          	jalr	804(ra) # 80000c98 <release>
}
    8000397c:	8526                	mv	a0,s1
    8000397e:	60e2                	ld	ra,24(sp)
    80003980:	6442                	ld	s0,16(sp)
    80003982:	64a2                	ld	s1,8(sp)
    80003984:	6105                	addi	sp,sp,32
    80003986:	8082                	ret

0000000080003988 <ilock>:
{
    80003988:	1101                	addi	sp,sp,-32
    8000398a:	ec06                	sd	ra,24(sp)
    8000398c:	e822                	sd	s0,16(sp)
    8000398e:	e426                	sd	s1,8(sp)
    80003990:	e04a                	sd	s2,0(sp)
    80003992:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003994:	c115                	beqz	a0,800039b8 <ilock+0x30>
    80003996:	84aa                	mv	s1,a0
    80003998:	451c                	lw	a5,8(a0)
    8000399a:	00f05f63          	blez	a5,800039b8 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000399e:	0541                	addi	a0,a0,16
    800039a0:	00001097          	auipc	ra,0x1
    800039a4:	cb2080e7          	jalr	-846(ra) # 80004652 <acquiresleep>
  if(ip->valid == 0){
    800039a8:	40bc                	lw	a5,64(s1)
    800039aa:	cf99                	beqz	a5,800039c8 <ilock+0x40>
}
    800039ac:	60e2                	ld	ra,24(sp)
    800039ae:	6442                	ld	s0,16(sp)
    800039b0:	64a2                	ld	s1,8(sp)
    800039b2:	6902                	ld	s2,0(sp)
    800039b4:	6105                	addi	sp,sp,32
    800039b6:	8082                	ret
    panic("ilock");
    800039b8:	00005517          	auipc	a0,0x5
    800039bc:	c3850513          	addi	a0,a0,-968 # 800085f0 <syscalls+0x190>
    800039c0:	ffffd097          	auipc	ra,0xffffd
    800039c4:	b7e080e7          	jalr	-1154(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039c8:	40dc                	lw	a5,4(s1)
    800039ca:	0047d79b          	srliw	a5,a5,0x4
    800039ce:	0001c597          	auipc	a1,0x1c
    800039d2:	ff25a583          	lw	a1,-14(a1) # 8001f9c0 <sb+0x18>
    800039d6:	9dbd                	addw	a1,a1,a5
    800039d8:	4088                	lw	a0,0(s1)
    800039da:	fffff097          	auipc	ra,0xfffff
    800039de:	7ac080e7          	jalr	1964(ra) # 80003186 <bread>
    800039e2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039e4:	05850593          	addi	a1,a0,88
    800039e8:	40dc                	lw	a5,4(s1)
    800039ea:	8bbd                	andi	a5,a5,15
    800039ec:	079a                	slli	a5,a5,0x6
    800039ee:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039f0:	00059783          	lh	a5,0(a1)
    800039f4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039f8:	00259783          	lh	a5,2(a1)
    800039fc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a00:	00459783          	lh	a5,4(a1)
    80003a04:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a08:	00659783          	lh	a5,6(a1)
    80003a0c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a10:	459c                	lw	a5,8(a1)
    80003a12:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a14:	03400613          	li	a2,52
    80003a18:	05b1                	addi	a1,a1,12
    80003a1a:	05048513          	addi	a0,s1,80
    80003a1e:	ffffd097          	auipc	ra,0xffffd
    80003a22:	322080e7          	jalr	802(ra) # 80000d40 <memmove>
    brelse(bp);
    80003a26:	854a                	mv	a0,s2
    80003a28:	00000097          	auipc	ra,0x0
    80003a2c:	88e080e7          	jalr	-1906(ra) # 800032b6 <brelse>
    ip->valid = 1;
    80003a30:	4785                	li	a5,1
    80003a32:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a34:	04449783          	lh	a5,68(s1)
    80003a38:	fbb5                	bnez	a5,800039ac <ilock+0x24>
      panic("ilock: no type");
    80003a3a:	00005517          	auipc	a0,0x5
    80003a3e:	bbe50513          	addi	a0,a0,-1090 # 800085f8 <syscalls+0x198>
    80003a42:	ffffd097          	auipc	ra,0xffffd
    80003a46:	afc080e7          	jalr	-1284(ra) # 8000053e <panic>

0000000080003a4a <iunlock>:
{
    80003a4a:	1101                	addi	sp,sp,-32
    80003a4c:	ec06                	sd	ra,24(sp)
    80003a4e:	e822                	sd	s0,16(sp)
    80003a50:	e426                	sd	s1,8(sp)
    80003a52:	e04a                	sd	s2,0(sp)
    80003a54:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a56:	c905                	beqz	a0,80003a86 <iunlock+0x3c>
    80003a58:	84aa                	mv	s1,a0
    80003a5a:	01050913          	addi	s2,a0,16
    80003a5e:	854a                	mv	a0,s2
    80003a60:	00001097          	auipc	ra,0x1
    80003a64:	c8c080e7          	jalr	-884(ra) # 800046ec <holdingsleep>
    80003a68:	cd19                	beqz	a0,80003a86 <iunlock+0x3c>
    80003a6a:	449c                	lw	a5,8(s1)
    80003a6c:	00f05d63          	blez	a5,80003a86 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a70:	854a                	mv	a0,s2
    80003a72:	00001097          	auipc	ra,0x1
    80003a76:	c36080e7          	jalr	-970(ra) # 800046a8 <releasesleep>
}
    80003a7a:	60e2                	ld	ra,24(sp)
    80003a7c:	6442                	ld	s0,16(sp)
    80003a7e:	64a2                	ld	s1,8(sp)
    80003a80:	6902                	ld	s2,0(sp)
    80003a82:	6105                	addi	sp,sp,32
    80003a84:	8082                	ret
    panic("iunlock");
    80003a86:	00005517          	auipc	a0,0x5
    80003a8a:	b8250513          	addi	a0,a0,-1150 # 80008608 <syscalls+0x1a8>
    80003a8e:	ffffd097          	auipc	ra,0xffffd
    80003a92:	ab0080e7          	jalr	-1360(ra) # 8000053e <panic>

0000000080003a96 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a96:	7179                	addi	sp,sp,-48
    80003a98:	f406                	sd	ra,40(sp)
    80003a9a:	f022                	sd	s0,32(sp)
    80003a9c:	ec26                	sd	s1,24(sp)
    80003a9e:	e84a                	sd	s2,16(sp)
    80003aa0:	e44e                	sd	s3,8(sp)
    80003aa2:	e052                	sd	s4,0(sp)
    80003aa4:	1800                	addi	s0,sp,48
    80003aa6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003aa8:	05050493          	addi	s1,a0,80
    80003aac:	08050913          	addi	s2,a0,128
    80003ab0:	a021                	j	80003ab8 <itrunc+0x22>
    80003ab2:	0491                	addi	s1,s1,4
    80003ab4:	01248d63          	beq	s1,s2,80003ace <itrunc+0x38>
    if(ip->addrs[i]){
    80003ab8:	408c                	lw	a1,0(s1)
    80003aba:	dde5                	beqz	a1,80003ab2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003abc:	0009a503          	lw	a0,0(s3)
    80003ac0:	00000097          	auipc	ra,0x0
    80003ac4:	90c080e7          	jalr	-1780(ra) # 800033cc <bfree>
      ip->addrs[i] = 0;
    80003ac8:	0004a023          	sw	zero,0(s1)
    80003acc:	b7dd                	j	80003ab2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ace:	0809a583          	lw	a1,128(s3)
    80003ad2:	e185                	bnez	a1,80003af2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ad4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ad8:	854e                	mv	a0,s3
    80003ada:	00000097          	auipc	ra,0x0
    80003ade:	de4080e7          	jalr	-540(ra) # 800038be <iupdate>
}
    80003ae2:	70a2                	ld	ra,40(sp)
    80003ae4:	7402                	ld	s0,32(sp)
    80003ae6:	64e2                	ld	s1,24(sp)
    80003ae8:	6942                	ld	s2,16(sp)
    80003aea:	69a2                	ld	s3,8(sp)
    80003aec:	6a02                	ld	s4,0(sp)
    80003aee:	6145                	addi	sp,sp,48
    80003af0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003af2:	0009a503          	lw	a0,0(s3)
    80003af6:	fffff097          	auipc	ra,0xfffff
    80003afa:	690080e7          	jalr	1680(ra) # 80003186 <bread>
    80003afe:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b00:	05850493          	addi	s1,a0,88
    80003b04:	45850913          	addi	s2,a0,1112
    80003b08:	a811                	j	80003b1c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003b0a:	0009a503          	lw	a0,0(s3)
    80003b0e:	00000097          	auipc	ra,0x0
    80003b12:	8be080e7          	jalr	-1858(ra) # 800033cc <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b16:	0491                	addi	s1,s1,4
    80003b18:	01248563          	beq	s1,s2,80003b22 <itrunc+0x8c>
      if(a[j])
    80003b1c:	408c                	lw	a1,0(s1)
    80003b1e:	dde5                	beqz	a1,80003b16 <itrunc+0x80>
    80003b20:	b7ed                	j	80003b0a <itrunc+0x74>
    brelse(bp);
    80003b22:	8552                	mv	a0,s4
    80003b24:	fffff097          	auipc	ra,0xfffff
    80003b28:	792080e7          	jalr	1938(ra) # 800032b6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b2c:	0809a583          	lw	a1,128(s3)
    80003b30:	0009a503          	lw	a0,0(s3)
    80003b34:	00000097          	auipc	ra,0x0
    80003b38:	898080e7          	jalr	-1896(ra) # 800033cc <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b3c:	0809a023          	sw	zero,128(s3)
    80003b40:	bf51                	j	80003ad4 <itrunc+0x3e>

0000000080003b42 <iput>:
{
    80003b42:	1101                	addi	sp,sp,-32
    80003b44:	ec06                	sd	ra,24(sp)
    80003b46:	e822                	sd	s0,16(sp)
    80003b48:	e426                	sd	s1,8(sp)
    80003b4a:	e04a                	sd	s2,0(sp)
    80003b4c:	1000                	addi	s0,sp,32
    80003b4e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b50:	0001c517          	auipc	a0,0x1c
    80003b54:	e7850513          	addi	a0,a0,-392 # 8001f9c8 <itable>
    80003b58:	ffffd097          	auipc	ra,0xffffd
    80003b5c:	08c080e7          	jalr	140(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b60:	4498                	lw	a4,8(s1)
    80003b62:	4785                	li	a5,1
    80003b64:	02f70363          	beq	a4,a5,80003b8a <iput+0x48>
  ip->ref--;
    80003b68:	449c                	lw	a5,8(s1)
    80003b6a:	37fd                	addiw	a5,a5,-1
    80003b6c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b6e:	0001c517          	auipc	a0,0x1c
    80003b72:	e5a50513          	addi	a0,a0,-422 # 8001f9c8 <itable>
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	122080e7          	jalr	290(ra) # 80000c98 <release>
}
    80003b7e:	60e2                	ld	ra,24(sp)
    80003b80:	6442                	ld	s0,16(sp)
    80003b82:	64a2                	ld	s1,8(sp)
    80003b84:	6902                	ld	s2,0(sp)
    80003b86:	6105                	addi	sp,sp,32
    80003b88:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b8a:	40bc                	lw	a5,64(s1)
    80003b8c:	dff1                	beqz	a5,80003b68 <iput+0x26>
    80003b8e:	04a49783          	lh	a5,74(s1)
    80003b92:	fbf9                	bnez	a5,80003b68 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b94:	01048913          	addi	s2,s1,16
    80003b98:	854a                	mv	a0,s2
    80003b9a:	00001097          	auipc	ra,0x1
    80003b9e:	ab8080e7          	jalr	-1352(ra) # 80004652 <acquiresleep>
    release(&itable.lock);
    80003ba2:	0001c517          	auipc	a0,0x1c
    80003ba6:	e2650513          	addi	a0,a0,-474 # 8001f9c8 <itable>
    80003baa:	ffffd097          	auipc	ra,0xffffd
    80003bae:	0ee080e7          	jalr	238(ra) # 80000c98 <release>
    itrunc(ip);
    80003bb2:	8526                	mv	a0,s1
    80003bb4:	00000097          	auipc	ra,0x0
    80003bb8:	ee2080e7          	jalr	-286(ra) # 80003a96 <itrunc>
    ip->type = 0;
    80003bbc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bc0:	8526                	mv	a0,s1
    80003bc2:	00000097          	auipc	ra,0x0
    80003bc6:	cfc080e7          	jalr	-772(ra) # 800038be <iupdate>
    ip->valid = 0;
    80003bca:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bce:	854a                	mv	a0,s2
    80003bd0:	00001097          	auipc	ra,0x1
    80003bd4:	ad8080e7          	jalr	-1320(ra) # 800046a8 <releasesleep>
    acquire(&itable.lock);
    80003bd8:	0001c517          	auipc	a0,0x1c
    80003bdc:	df050513          	addi	a0,a0,-528 # 8001f9c8 <itable>
    80003be0:	ffffd097          	auipc	ra,0xffffd
    80003be4:	004080e7          	jalr	4(ra) # 80000be4 <acquire>
    80003be8:	b741                	j	80003b68 <iput+0x26>

0000000080003bea <iunlockput>:
{
    80003bea:	1101                	addi	sp,sp,-32
    80003bec:	ec06                	sd	ra,24(sp)
    80003bee:	e822                	sd	s0,16(sp)
    80003bf0:	e426                	sd	s1,8(sp)
    80003bf2:	1000                	addi	s0,sp,32
    80003bf4:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	e54080e7          	jalr	-428(ra) # 80003a4a <iunlock>
  iput(ip);
    80003bfe:	8526                	mv	a0,s1
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	f42080e7          	jalr	-190(ra) # 80003b42 <iput>
}
    80003c08:	60e2                	ld	ra,24(sp)
    80003c0a:	6442                	ld	s0,16(sp)
    80003c0c:	64a2                	ld	s1,8(sp)
    80003c0e:	6105                	addi	sp,sp,32
    80003c10:	8082                	ret

0000000080003c12 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c12:	1141                	addi	sp,sp,-16
    80003c14:	e422                	sd	s0,8(sp)
    80003c16:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c18:	411c                	lw	a5,0(a0)
    80003c1a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c1c:	415c                	lw	a5,4(a0)
    80003c1e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c20:	04451783          	lh	a5,68(a0)
    80003c24:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c28:	04a51783          	lh	a5,74(a0)
    80003c2c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c30:	04c56783          	lwu	a5,76(a0)
    80003c34:	e99c                	sd	a5,16(a1)
}
    80003c36:	6422                	ld	s0,8(sp)
    80003c38:	0141                	addi	sp,sp,16
    80003c3a:	8082                	ret

0000000080003c3c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c3c:	457c                	lw	a5,76(a0)
    80003c3e:	0ed7e963          	bltu	a5,a3,80003d30 <readi+0xf4>
{
    80003c42:	7159                	addi	sp,sp,-112
    80003c44:	f486                	sd	ra,104(sp)
    80003c46:	f0a2                	sd	s0,96(sp)
    80003c48:	eca6                	sd	s1,88(sp)
    80003c4a:	e8ca                	sd	s2,80(sp)
    80003c4c:	e4ce                	sd	s3,72(sp)
    80003c4e:	e0d2                	sd	s4,64(sp)
    80003c50:	fc56                	sd	s5,56(sp)
    80003c52:	f85a                	sd	s6,48(sp)
    80003c54:	f45e                	sd	s7,40(sp)
    80003c56:	f062                	sd	s8,32(sp)
    80003c58:	ec66                	sd	s9,24(sp)
    80003c5a:	e86a                	sd	s10,16(sp)
    80003c5c:	e46e                	sd	s11,8(sp)
    80003c5e:	1880                	addi	s0,sp,112
    80003c60:	8baa                	mv	s7,a0
    80003c62:	8c2e                	mv	s8,a1
    80003c64:	8ab2                	mv	s5,a2
    80003c66:	84b6                	mv	s1,a3
    80003c68:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c6a:	9f35                	addw	a4,a4,a3
    return 0;
    80003c6c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c6e:	0ad76063          	bltu	a4,a3,80003d0e <readi+0xd2>
  if(off + n > ip->size)
    80003c72:	00e7f463          	bgeu	a5,a4,80003c7a <readi+0x3e>
    n = ip->size - off;
    80003c76:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c7a:	0a0b0963          	beqz	s6,80003d2c <readi+0xf0>
    80003c7e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c80:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c84:	5cfd                	li	s9,-1
    80003c86:	a82d                	j	80003cc0 <readi+0x84>
    80003c88:	020a1d93          	slli	s11,s4,0x20
    80003c8c:	020ddd93          	srli	s11,s11,0x20
    80003c90:	05890613          	addi	a2,s2,88
    80003c94:	86ee                	mv	a3,s11
    80003c96:	963a                	add	a2,a2,a4
    80003c98:	85d6                	mv	a1,s5
    80003c9a:	8562                	mv	a0,s8
    80003c9c:	fffff097          	auipc	ra,0xfffff
    80003ca0:	a42080e7          	jalr	-1470(ra) # 800026de <either_copyout>
    80003ca4:	05950d63          	beq	a0,s9,80003cfe <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ca8:	854a                	mv	a0,s2
    80003caa:	fffff097          	auipc	ra,0xfffff
    80003cae:	60c080e7          	jalr	1548(ra) # 800032b6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cb2:	013a09bb          	addw	s3,s4,s3
    80003cb6:	009a04bb          	addw	s1,s4,s1
    80003cba:	9aee                	add	s5,s5,s11
    80003cbc:	0569f763          	bgeu	s3,s6,80003d0a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cc0:	000ba903          	lw	s2,0(s7)
    80003cc4:	00a4d59b          	srliw	a1,s1,0xa
    80003cc8:	855e                	mv	a0,s7
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	8b0080e7          	jalr	-1872(ra) # 8000357a <bmap>
    80003cd2:	0005059b          	sext.w	a1,a0
    80003cd6:	854a                	mv	a0,s2
    80003cd8:	fffff097          	auipc	ra,0xfffff
    80003cdc:	4ae080e7          	jalr	1198(ra) # 80003186 <bread>
    80003ce0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ce2:	3ff4f713          	andi	a4,s1,1023
    80003ce6:	40ed07bb          	subw	a5,s10,a4
    80003cea:	413b06bb          	subw	a3,s6,s3
    80003cee:	8a3e                	mv	s4,a5
    80003cf0:	2781                	sext.w	a5,a5
    80003cf2:	0006861b          	sext.w	a2,a3
    80003cf6:	f8f679e3          	bgeu	a2,a5,80003c88 <readi+0x4c>
    80003cfa:	8a36                	mv	s4,a3
    80003cfc:	b771                	j	80003c88 <readi+0x4c>
      brelse(bp);
    80003cfe:	854a                	mv	a0,s2
    80003d00:	fffff097          	auipc	ra,0xfffff
    80003d04:	5b6080e7          	jalr	1462(ra) # 800032b6 <brelse>
      tot = -1;
    80003d08:	59fd                	li	s3,-1
  }
  return tot;
    80003d0a:	0009851b          	sext.w	a0,s3
}
    80003d0e:	70a6                	ld	ra,104(sp)
    80003d10:	7406                	ld	s0,96(sp)
    80003d12:	64e6                	ld	s1,88(sp)
    80003d14:	6946                	ld	s2,80(sp)
    80003d16:	69a6                	ld	s3,72(sp)
    80003d18:	6a06                	ld	s4,64(sp)
    80003d1a:	7ae2                	ld	s5,56(sp)
    80003d1c:	7b42                	ld	s6,48(sp)
    80003d1e:	7ba2                	ld	s7,40(sp)
    80003d20:	7c02                	ld	s8,32(sp)
    80003d22:	6ce2                	ld	s9,24(sp)
    80003d24:	6d42                	ld	s10,16(sp)
    80003d26:	6da2                	ld	s11,8(sp)
    80003d28:	6165                	addi	sp,sp,112
    80003d2a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d2c:	89da                	mv	s3,s6
    80003d2e:	bff1                	j	80003d0a <readi+0xce>
    return 0;
    80003d30:	4501                	li	a0,0
}
    80003d32:	8082                	ret

0000000080003d34 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d34:	457c                	lw	a5,76(a0)
    80003d36:	10d7e863          	bltu	a5,a3,80003e46 <writei+0x112>
{
    80003d3a:	7159                	addi	sp,sp,-112
    80003d3c:	f486                	sd	ra,104(sp)
    80003d3e:	f0a2                	sd	s0,96(sp)
    80003d40:	eca6                	sd	s1,88(sp)
    80003d42:	e8ca                	sd	s2,80(sp)
    80003d44:	e4ce                	sd	s3,72(sp)
    80003d46:	e0d2                	sd	s4,64(sp)
    80003d48:	fc56                	sd	s5,56(sp)
    80003d4a:	f85a                	sd	s6,48(sp)
    80003d4c:	f45e                	sd	s7,40(sp)
    80003d4e:	f062                	sd	s8,32(sp)
    80003d50:	ec66                	sd	s9,24(sp)
    80003d52:	e86a                	sd	s10,16(sp)
    80003d54:	e46e                	sd	s11,8(sp)
    80003d56:	1880                	addi	s0,sp,112
    80003d58:	8b2a                	mv	s6,a0
    80003d5a:	8c2e                	mv	s8,a1
    80003d5c:	8ab2                	mv	s5,a2
    80003d5e:	8936                	mv	s2,a3
    80003d60:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d62:	00e687bb          	addw	a5,a3,a4
    80003d66:	0ed7e263          	bltu	a5,a3,80003e4a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d6a:	00043737          	lui	a4,0x43
    80003d6e:	0ef76063          	bltu	a4,a5,80003e4e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d72:	0c0b8863          	beqz	s7,80003e42 <writei+0x10e>
    80003d76:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d78:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d7c:	5cfd                	li	s9,-1
    80003d7e:	a091                	j	80003dc2 <writei+0x8e>
    80003d80:	02099d93          	slli	s11,s3,0x20
    80003d84:	020ddd93          	srli	s11,s11,0x20
    80003d88:	05848513          	addi	a0,s1,88
    80003d8c:	86ee                	mv	a3,s11
    80003d8e:	8656                	mv	a2,s5
    80003d90:	85e2                	mv	a1,s8
    80003d92:	953a                	add	a0,a0,a4
    80003d94:	fffff097          	auipc	ra,0xfffff
    80003d98:	9a0080e7          	jalr	-1632(ra) # 80002734 <either_copyin>
    80003d9c:	07950263          	beq	a0,s9,80003e00 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003da0:	8526                	mv	a0,s1
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	790080e7          	jalr	1936(ra) # 80004532 <log_write>
    brelse(bp);
    80003daa:	8526                	mv	a0,s1
    80003dac:	fffff097          	auipc	ra,0xfffff
    80003db0:	50a080e7          	jalr	1290(ra) # 800032b6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003db4:	01498a3b          	addw	s4,s3,s4
    80003db8:	0129893b          	addw	s2,s3,s2
    80003dbc:	9aee                	add	s5,s5,s11
    80003dbe:	057a7663          	bgeu	s4,s7,80003e0a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003dc2:	000b2483          	lw	s1,0(s6)
    80003dc6:	00a9559b          	srliw	a1,s2,0xa
    80003dca:	855a                	mv	a0,s6
    80003dcc:	fffff097          	auipc	ra,0xfffff
    80003dd0:	7ae080e7          	jalr	1966(ra) # 8000357a <bmap>
    80003dd4:	0005059b          	sext.w	a1,a0
    80003dd8:	8526                	mv	a0,s1
    80003dda:	fffff097          	auipc	ra,0xfffff
    80003dde:	3ac080e7          	jalr	940(ra) # 80003186 <bread>
    80003de2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003de4:	3ff97713          	andi	a4,s2,1023
    80003de8:	40ed07bb          	subw	a5,s10,a4
    80003dec:	414b86bb          	subw	a3,s7,s4
    80003df0:	89be                	mv	s3,a5
    80003df2:	2781                	sext.w	a5,a5
    80003df4:	0006861b          	sext.w	a2,a3
    80003df8:	f8f674e3          	bgeu	a2,a5,80003d80 <writei+0x4c>
    80003dfc:	89b6                	mv	s3,a3
    80003dfe:	b749                	j	80003d80 <writei+0x4c>
      brelse(bp);
    80003e00:	8526                	mv	a0,s1
    80003e02:	fffff097          	auipc	ra,0xfffff
    80003e06:	4b4080e7          	jalr	1204(ra) # 800032b6 <brelse>
  }

  if(off > ip->size)
    80003e0a:	04cb2783          	lw	a5,76(s6)
    80003e0e:	0127f463          	bgeu	a5,s2,80003e16 <writei+0xe2>
    ip->size = off;
    80003e12:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e16:	855a                	mv	a0,s6
    80003e18:	00000097          	auipc	ra,0x0
    80003e1c:	aa6080e7          	jalr	-1370(ra) # 800038be <iupdate>

  return tot;
    80003e20:	000a051b          	sext.w	a0,s4
}
    80003e24:	70a6                	ld	ra,104(sp)
    80003e26:	7406                	ld	s0,96(sp)
    80003e28:	64e6                	ld	s1,88(sp)
    80003e2a:	6946                	ld	s2,80(sp)
    80003e2c:	69a6                	ld	s3,72(sp)
    80003e2e:	6a06                	ld	s4,64(sp)
    80003e30:	7ae2                	ld	s5,56(sp)
    80003e32:	7b42                	ld	s6,48(sp)
    80003e34:	7ba2                	ld	s7,40(sp)
    80003e36:	7c02                	ld	s8,32(sp)
    80003e38:	6ce2                	ld	s9,24(sp)
    80003e3a:	6d42                	ld	s10,16(sp)
    80003e3c:	6da2                	ld	s11,8(sp)
    80003e3e:	6165                	addi	sp,sp,112
    80003e40:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e42:	8a5e                	mv	s4,s7
    80003e44:	bfc9                	j	80003e16 <writei+0xe2>
    return -1;
    80003e46:	557d                	li	a0,-1
}
    80003e48:	8082                	ret
    return -1;
    80003e4a:	557d                	li	a0,-1
    80003e4c:	bfe1                	j	80003e24 <writei+0xf0>
    return -1;
    80003e4e:	557d                	li	a0,-1
    80003e50:	bfd1                	j	80003e24 <writei+0xf0>

0000000080003e52 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e52:	1141                	addi	sp,sp,-16
    80003e54:	e406                	sd	ra,8(sp)
    80003e56:	e022                	sd	s0,0(sp)
    80003e58:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e5a:	4639                	li	a2,14
    80003e5c:	ffffd097          	auipc	ra,0xffffd
    80003e60:	f5c080e7          	jalr	-164(ra) # 80000db8 <strncmp>
}
    80003e64:	60a2                	ld	ra,8(sp)
    80003e66:	6402                	ld	s0,0(sp)
    80003e68:	0141                	addi	sp,sp,16
    80003e6a:	8082                	ret

0000000080003e6c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e6c:	7139                	addi	sp,sp,-64
    80003e6e:	fc06                	sd	ra,56(sp)
    80003e70:	f822                	sd	s0,48(sp)
    80003e72:	f426                	sd	s1,40(sp)
    80003e74:	f04a                	sd	s2,32(sp)
    80003e76:	ec4e                	sd	s3,24(sp)
    80003e78:	e852                	sd	s4,16(sp)
    80003e7a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e7c:	04451703          	lh	a4,68(a0)
    80003e80:	4785                	li	a5,1
    80003e82:	00f71a63          	bne	a4,a5,80003e96 <dirlookup+0x2a>
    80003e86:	892a                	mv	s2,a0
    80003e88:	89ae                	mv	s3,a1
    80003e8a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e8c:	457c                	lw	a5,76(a0)
    80003e8e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e90:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e92:	e79d                	bnez	a5,80003ec0 <dirlookup+0x54>
    80003e94:	a8a5                	j	80003f0c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e96:	00004517          	auipc	a0,0x4
    80003e9a:	77a50513          	addi	a0,a0,1914 # 80008610 <syscalls+0x1b0>
    80003e9e:	ffffc097          	auipc	ra,0xffffc
    80003ea2:	6a0080e7          	jalr	1696(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003ea6:	00004517          	auipc	a0,0x4
    80003eaa:	78250513          	addi	a0,a0,1922 # 80008628 <syscalls+0x1c8>
    80003eae:	ffffc097          	auipc	ra,0xffffc
    80003eb2:	690080e7          	jalr	1680(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb6:	24c1                	addiw	s1,s1,16
    80003eb8:	04c92783          	lw	a5,76(s2)
    80003ebc:	04f4f763          	bgeu	s1,a5,80003f0a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ec0:	4741                	li	a4,16
    80003ec2:	86a6                	mv	a3,s1
    80003ec4:	fc040613          	addi	a2,s0,-64
    80003ec8:	4581                	li	a1,0
    80003eca:	854a                	mv	a0,s2
    80003ecc:	00000097          	auipc	ra,0x0
    80003ed0:	d70080e7          	jalr	-656(ra) # 80003c3c <readi>
    80003ed4:	47c1                	li	a5,16
    80003ed6:	fcf518e3          	bne	a0,a5,80003ea6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003eda:	fc045783          	lhu	a5,-64(s0)
    80003ede:	dfe1                	beqz	a5,80003eb6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ee0:	fc240593          	addi	a1,s0,-62
    80003ee4:	854e                	mv	a0,s3
    80003ee6:	00000097          	auipc	ra,0x0
    80003eea:	f6c080e7          	jalr	-148(ra) # 80003e52 <namecmp>
    80003eee:	f561                	bnez	a0,80003eb6 <dirlookup+0x4a>
      if(poff)
    80003ef0:	000a0463          	beqz	s4,80003ef8 <dirlookup+0x8c>
        *poff = off;
    80003ef4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ef8:	fc045583          	lhu	a1,-64(s0)
    80003efc:	00092503          	lw	a0,0(s2)
    80003f00:	fffff097          	auipc	ra,0xfffff
    80003f04:	754080e7          	jalr	1876(ra) # 80003654 <iget>
    80003f08:	a011                	j	80003f0c <dirlookup+0xa0>
  return 0;
    80003f0a:	4501                	li	a0,0
}
    80003f0c:	70e2                	ld	ra,56(sp)
    80003f0e:	7442                	ld	s0,48(sp)
    80003f10:	74a2                	ld	s1,40(sp)
    80003f12:	7902                	ld	s2,32(sp)
    80003f14:	69e2                	ld	s3,24(sp)
    80003f16:	6a42                	ld	s4,16(sp)
    80003f18:	6121                	addi	sp,sp,64
    80003f1a:	8082                	ret

0000000080003f1c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f1c:	711d                	addi	sp,sp,-96
    80003f1e:	ec86                	sd	ra,88(sp)
    80003f20:	e8a2                	sd	s0,80(sp)
    80003f22:	e4a6                	sd	s1,72(sp)
    80003f24:	e0ca                	sd	s2,64(sp)
    80003f26:	fc4e                	sd	s3,56(sp)
    80003f28:	f852                	sd	s4,48(sp)
    80003f2a:	f456                	sd	s5,40(sp)
    80003f2c:	f05a                	sd	s6,32(sp)
    80003f2e:	ec5e                	sd	s7,24(sp)
    80003f30:	e862                	sd	s8,16(sp)
    80003f32:	e466                	sd	s9,8(sp)
    80003f34:	1080                	addi	s0,sp,96
    80003f36:	84aa                	mv	s1,a0
    80003f38:	8b2e                	mv	s6,a1
    80003f3a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f3c:	00054703          	lbu	a4,0(a0)
    80003f40:	02f00793          	li	a5,47
    80003f44:	02f70363          	beq	a4,a5,80003f6a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f48:	ffffe097          	auipc	ra,0xffffe
    80003f4c:	a86080e7          	jalr	-1402(ra) # 800019ce <myproc>
    80003f50:	15853503          	ld	a0,344(a0)
    80003f54:	00000097          	auipc	ra,0x0
    80003f58:	9f6080e7          	jalr	-1546(ra) # 8000394a <idup>
    80003f5c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f5e:	02f00913          	li	s2,47
  len = path - s;
    80003f62:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f64:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f66:	4c05                	li	s8,1
    80003f68:	a865                	j	80004020 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f6a:	4585                	li	a1,1
    80003f6c:	4505                	li	a0,1
    80003f6e:	fffff097          	auipc	ra,0xfffff
    80003f72:	6e6080e7          	jalr	1766(ra) # 80003654 <iget>
    80003f76:	89aa                	mv	s3,a0
    80003f78:	b7dd                	j	80003f5e <namex+0x42>
      iunlockput(ip);
    80003f7a:	854e                	mv	a0,s3
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	c6e080e7          	jalr	-914(ra) # 80003bea <iunlockput>
      return 0;
    80003f84:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f86:	854e                	mv	a0,s3
    80003f88:	60e6                	ld	ra,88(sp)
    80003f8a:	6446                	ld	s0,80(sp)
    80003f8c:	64a6                	ld	s1,72(sp)
    80003f8e:	6906                	ld	s2,64(sp)
    80003f90:	79e2                	ld	s3,56(sp)
    80003f92:	7a42                	ld	s4,48(sp)
    80003f94:	7aa2                	ld	s5,40(sp)
    80003f96:	7b02                	ld	s6,32(sp)
    80003f98:	6be2                	ld	s7,24(sp)
    80003f9a:	6c42                	ld	s8,16(sp)
    80003f9c:	6ca2                	ld	s9,8(sp)
    80003f9e:	6125                	addi	sp,sp,96
    80003fa0:	8082                	ret
      iunlock(ip);
    80003fa2:	854e                	mv	a0,s3
    80003fa4:	00000097          	auipc	ra,0x0
    80003fa8:	aa6080e7          	jalr	-1370(ra) # 80003a4a <iunlock>
      return ip;
    80003fac:	bfe9                	j	80003f86 <namex+0x6a>
      iunlockput(ip);
    80003fae:	854e                	mv	a0,s3
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	c3a080e7          	jalr	-966(ra) # 80003bea <iunlockput>
      return 0;
    80003fb8:	89d2                	mv	s3,s4
    80003fba:	b7f1                	j	80003f86 <namex+0x6a>
  len = path - s;
    80003fbc:	40b48633          	sub	a2,s1,a1
    80003fc0:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003fc4:	094cd463          	bge	s9,s4,8000404c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fc8:	4639                	li	a2,14
    80003fca:	8556                	mv	a0,s5
    80003fcc:	ffffd097          	auipc	ra,0xffffd
    80003fd0:	d74080e7          	jalr	-652(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003fd4:	0004c783          	lbu	a5,0(s1)
    80003fd8:	01279763          	bne	a5,s2,80003fe6 <namex+0xca>
    path++;
    80003fdc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fde:	0004c783          	lbu	a5,0(s1)
    80003fe2:	ff278de3          	beq	a5,s2,80003fdc <namex+0xc0>
    ilock(ip);
    80003fe6:	854e                	mv	a0,s3
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	9a0080e7          	jalr	-1632(ra) # 80003988 <ilock>
    if(ip->type != T_DIR){
    80003ff0:	04499783          	lh	a5,68(s3)
    80003ff4:	f98793e3          	bne	a5,s8,80003f7a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ff8:	000b0563          	beqz	s6,80004002 <namex+0xe6>
    80003ffc:	0004c783          	lbu	a5,0(s1)
    80004000:	d3cd                	beqz	a5,80003fa2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004002:	865e                	mv	a2,s7
    80004004:	85d6                	mv	a1,s5
    80004006:	854e                	mv	a0,s3
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	e64080e7          	jalr	-412(ra) # 80003e6c <dirlookup>
    80004010:	8a2a                	mv	s4,a0
    80004012:	dd51                	beqz	a0,80003fae <namex+0x92>
    iunlockput(ip);
    80004014:	854e                	mv	a0,s3
    80004016:	00000097          	auipc	ra,0x0
    8000401a:	bd4080e7          	jalr	-1068(ra) # 80003bea <iunlockput>
    ip = next;
    8000401e:	89d2                	mv	s3,s4
  while(*path == '/')
    80004020:	0004c783          	lbu	a5,0(s1)
    80004024:	05279763          	bne	a5,s2,80004072 <namex+0x156>
    path++;
    80004028:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000402a:	0004c783          	lbu	a5,0(s1)
    8000402e:	ff278de3          	beq	a5,s2,80004028 <namex+0x10c>
  if(*path == 0)
    80004032:	c79d                	beqz	a5,80004060 <namex+0x144>
    path++;
    80004034:	85a6                	mv	a1,s1
  len = path - s;
    80004036:	8a5e                	mv	s4,s7
    80004038:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000403a:	01278963          	beq	a5,s2,8000404c <namex+0x130>
    8000403e:	dfbd                	beqz	a5,80003fbc <namex+0xa0>
    path++;
    80004040:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004042:	0004c783          	lbu	a5,0(s1)
    80004046:	ff279ce3          	bne	a5,s2,8000403e <namex+0x122>
    8000404a:	bf8d                	j	80003fbc <namex+0xa0>
    memmove(name, s, len);
    8000404c:	2601                	sext.w	a2,a2
    8000404e:	8556                	mv	a0,s5
    80004050:	ffffd097          	auipc	ra,0xffffd
    80004054:	cf0080e7          	jalr	-784(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004058:	9a56                	add	s4,s4,s5
    8000405a:	000a0023          	sb	zero,0(s4)
    8000405e:	bf9d                	j	80003fd4 <namex+0xb8>
  if(nameiparent){
    80004060:	f20b03e3          	beqz	s6,80003f86 <namex+0x6a>
    iput(ip);
    80004064:	854e                	mv	a0,s3
    80004066:	00000097          	auipc	ra,0x0
    8000406a:	adc080e7          	jalr	-1316(ra) # 80003b42 <iput>
    return 0;
    8000406e:	4981                	li	s3,0
    80004070:	bf19                	j	80003f86 <namex+0x6a>
  if(*path == 0)
    80004072:	d7fd                	beqz	a5,80004060 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004074:	0004c783          	lbu	a5,0(s1)
    80004078:	85a6                	mv	a1,s1
    8000407a:	b7d1                	j	8000403e <namex+0x122>

000000008000407c <dirlink>:
{
    8000407c:	7139                	addi	sp,sp,-64
    8000407e:	fc06                	sd	ra,56(sp)
    80004080:	f822                	sd	s0,48(sp)
    80004082:	f426                	sd	s1,40(sp)
    80004084:	f04a                	sd	s2,32(sp)
    80004086:	ec4e                	sd	s3,24(sp)
    80004088:	e852                	sd	s4,16(sp)
    8000408a:	0080                	addi	s0,sp,64
    8000408c:	892a                	mv	s2,a0
    8000408e:	8a2e                	mv	s4,a1
    80004090:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004092:	4601                	li	a2,0
    80004094:	00000097          	auipc	ra,0x0
    80004098:	dd8080e7          	jalr	-552(ra) # 80003e6c <dirlookup>
    8000409c:	e93d                	bnez	a0,80004112 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000409e:	04c92483          	lw	s1,76(s2)
    800040a2:	c49d                	beqz	s1,800040d0 <dirlink+0x54>
    800040a4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040a6:	4741                	li	a4,16
    800040a8:	86a6                	mv	a3,s1
    800040aa:	fc040613          	addi	a2,s0,-64
    800040ae:	4581                	li	a1,0
    800040b0:	854a                	mv	a0,s2
    800040b2:	00000097          	auipc	ra,0x0
    800040b6:	b8a080e7          	jalr	-1142(ra) # 80003c3c <readi>
    800040ba:	47c1                	li	a5,16
    800040bc:	06f51163          	bne	a0,a5,8000411e <dirlink+0xa2>
    if(de.inum == 0)
    800040c0:	fc045783          	lhu	a5,-64(s0)
    800040c4:	c791                	beqz	a5,800040d0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040c6:	24c1                	addiw	s1,s1,16
    800040c8:	04c92783          	lw	a5,76(s2)
    800040cc:	fcf4ede3          	bltu	s1,a5,800040a6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040d0:	4639                	li	a2,14
    800040d2:	85d2                	mv	a1,s4
    800040d4:	fc240513          	addi	a0,s0,-62
    800040d8:	ffffd097          	auipc	ra,0xffffd
    800040dc:	d1c080e7          	jalr	-740(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800040e0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040e4:	4741                	li	a4,16
    800040e6:	86a6                	mv	a3,s1
    800040e8:	fc040613          	addi	a2,s0,-64
    800040ec:	4581                	li	a1,0
    800040ee:	854a                	mv	a0,s2
    800040f0:	00000097          	auipc	ra,0x0
    800040f4:	c44080e7          	jalr	-956(ra) # 80003d34 <writei>
    800040f8:	872a                	mv	a4,a0
    800040fa:	47c1                	li	a5,16
  return 0;
    800040fc:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040fe:	02f71863          	bne	a4,a5,8000412e <dirlink+0xb2>
}
    80004102:	70e2                	ld	ra,56(sp)
    80004104:	7442                	ld	s0,48(sp)
    80004106:	74a2                	ld	s1,40(sp)
    80004108:	7902                	ld	s2,32(sp)
    8000410a:	69e2                	ld	s3,24(sp)
    8000410c:	6a42                	ld	s4,16(sp)
    8000410e:	6121                	addi	sp,sp,64
    80004110:	8082                	ret
    iput(ip);
    80004112:	00000097          	auipc	ra,0x0
    80004116:	a30080e7          	jalr	-1488(ra) # 80003b42 <iput>
    return -1;
    8000411a:	557d                	li	a0,-1
    8000411c:	b7dd                	j	80004102 <dirlink+0x86>
      panic("dirlink read");
    8000411e:	00004517          	auipc	a0,0x4
    80004122:	51a50513          	addi	a0,a0,1306 # 80008638 <syscalls+0x1d8>
    80004126:	ffffc097          	auipc	ra,0xffffc
    8000412a:	418080e7          	jalr	1048(ra) # 8000053e <panic>
    panic("dirlink");
    8000412e:	00004517          	auipc	a0,0x4
    80004132:	61a50513          	addi	a0,a0,1562 # 80008748 <syscalls+0x2e8>
    80004136:	ffffc097          	auipc	ra,0xffffc
    8000413a:	408080e7          	jalr	1032(ra) # 8000053e <panic>

000000008000413e <namei>:

struct inode*
namei(char *path)
{
    8000413e:	1101                	addi	sp,sp,-32
    80004140:	ec06                	sd	ra,24(sp)
    80004142:	e822                	sd	s0,16(sp)
    80004144:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004146:	fe040613          	addi	a2,s0,-32
    8000414a:	4581                	li	a1,0
    8000414c:	00000097          	auipc	ra,0x0
    80004150:	dd0080e7          	jalr	-560(ra) # 80003f1c <namex>
}
    80004154:	60e2                	ld	ra,24(sp)
    80004156:	6442                	ld	s0,16(sp)
    80004158:	6105                	addi	sp,sp,32
    8000415a:	8082                	ret

000000008000415c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000415c:	1141                	addi	sp,sp,-16
    8000415e:	e406                	sd	ra,8(sp)
    80004160:	e022                	sd	s0,0(sp)
    80004162:	0800                	addi	s0,sp,16
    80004164:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004166:	4585                	li	a1,1
    80004168:	00000097          	auipc	ra,0x0
    8000416c:	db4080e7          	jalr	-588(ra) # 80003f1c <namex>
}
    80004170:	60a2                	ld	ra,8(sp)
    80004172:	6402                	ld	s0,0(sp)
    80004174:	0141                	addi	sp,sp,16
    80004176:	8082                	ret

0000000080004178 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004178:	1101                	addi	sp,sp,-32
    8000417a:	ec06                	sd	ra,24(sp)
    8000417c:	e822                	sd	s0,16(sp)
    8000417e:	e426                	sd	s1,8(sp)
    80004180:	e04a                	sd	s2,0(sp)
    80004182:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004184:	0001d917          	auipc	s2,0x1d
    80004188:	2ec90913          	addi	s2,s2,748 # 80021470 <log>
    8000418c:	01892583          	lw	a1,24(s2)
    80004190:	02892503          	lw	a0,40(s2)
    80004194:	fffff097          	auipc	ra,0xfffff
    80004198:	ff2080e7          	jalr	-14(ra) # 80003186 <bread>
    8000419c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000419e:	02c92683          	lw	a3,44(s2)
    800041a2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041a4:	02d05763          	blez	a3,800041d2 <write_head+0x5a>
    800041a8:	0001d797          	auipc	a5,0x1d
    800041ac:	2f878793          	addi	a5,a5,760 # 800214a0 <log+0x30>
    800041b0:	05c50713          	addi	a4,a0,92
    800041b4:	36fd                	addiw	a3,a3,-1
    800041b6:	1682                	slli	a3,a3,0x20
    800041b8:	9281                	srli	a3,a3,0x20
    800041ba:	068a                	slli	a3,a3,0x2
    800041bc:	0001d617          	auipc	a2,0x1d
    800041c0:	2e860613          	addi	a2,a2,744 # 800214a4 <log+0x34>
    800041c4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041c6:	4390                	lw	a2,0(a5)
    800041c8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041ca:	0791                	addi	a5,a5,4
    800041cc:	0711                	addi	a4,a4,4
    800041ce:	fed79ce3          	bne	a5,a3,800041c6 <write_head+0x4e>
  }
  bwrite(buf);
    800041d2:	8526                	mv	a0,s1
    800041d4:	fffff097          	auipc	ra,0xfffff
    800041d8:	0a4080e7          	jalr	164(ra) # 80003278 <bwrite>
  brelse(buf);
    800041dc:	8526                	mv	a0,s1
    800041de:	fffff097          	auipc	ra,0xfffff
    800041e2:	0d8080e7          	jalr	216(ra) # 800032b6 <brelse>
}
    800041e6:	60e2                	ld	ra,24(sp)
    800041e8:	6442                	ld	s0,16(sp)
    800041ea:	64a2                	ld	s1,8(sp)
    800041ec:	6902                	ld	s2,0(sp)
    800041ee:	6105                	addi	sp,sp,32
    800041f0:	8082                	ret

00000000800041f2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041f2:	0001d797          	auipc	a5,0x1d
    800041f6:	2aa7a783          	lw	a5,682(a5) # 8002149c <log+0x2c>
    800041fa:	0af05d63          	blez	a5,800042b4 <install_trans+0xc2>
{
    800041fe:	7139                	addi	sp,sp,-64
    80004200:	fc06                	sd	ra,56(sp)
    80004202:	f822                	sd	s0,48(sp)
    80004204:	f426                	sd	s1,40(sp)
    80004206:	f04a                	sd	s2,32(sp)
    80004208:	ec4e                	sd	s3,24(sp)
    8000420a:	e852                	sd	s4,16(sp)
    8000420c:	e456                	sd	s5,8(sp)
    8000420e:	e05a                	sd	s6,0(sp)
    80004210:	0080                	addi	s0,sp,64
    80004212:	8b2a                	mv	s6,a0
    80004214:	0001da97          	auipc	s5,0x1d
    80004218:	28ca8a93          	addi	s5,s5,652 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000421c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000421e:	0001d997          	auipc	s3,0x1d
    80004222:	25298993          	addi	s3,s3,594 # 80021470 <log>
    80004226:	a035                	j	80004252 <install_trans+0x60>
      bunpin(dbuf);
    80004228:	8526                	mv	a0,s1
    8000422a:	fffff097          	auipc	ra,0xfffff
    8000422e:	166080e7          	jalr	358(ra) # 80003390 <bunpin>
    brelse(lbuf);
    80004232:	854a                	mv	a0,s2
    80004234:	fffff097          	auipc	ra,0xfffff
    80004238:	082080e7          	jalr	130(ra) # 800032b6 <brelse>
    brelse(dbuf);
    8000423c:	8526                	mv	a0,s1
    8000423e:	fffff097          	auipc	ra,0xfffff
    80004242:	078080e7          	jalr	120(ra) # 800032b6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004246:	2a05                	addiw	s4,s4,1
    80004248:	0a91                	addi	s5,s5,4
    8000424a:	02c9a783          	lw	a5,44(s3)
    8000424e:	04fa5963          	bge	s4,a5,800042a0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004252:	0189a583          	lw	a1,24(s3)
    80004256:	014585bb          	addw	a1,a1,s4
    8000425a:	2585                	addiw	a1,a1,1
    8000425c:	0289a503          	lw	a0,40(s3)
    80004260:	fffff097          	auipc	ra,0xfffff
    80004264:	f26080e7          	jalr	-218(ra) # 80003186 <bread>
    80004268:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000426a:	000aa583          	lw	a1,0(s5)
    8000426e:	0289a503          	lw	a0,40(s3)
    80004272:	fffff097          	auipc	ra,0xfffff
    80004276:	f14080e7          	jalr	-236(ra) # 80003186 <bread>
    8000427a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000427c:	40000613          	li	a2,1024
    80004280:	05890593          	addi	a1,s2,88
    80004284:	05850513          	addi	a0,a0,88
    80004288:	ffffd097          	auipc	ra,0xffffd
    8000428c:	ab8080e7          	jalr	-1352(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004290:	8526                	mv	a0,s1
    80004292:	fffff097          	auipc	ra,0xfffff
    80004296:	fe6080e7          	jalr	-26(ra) # 80003278 <bwrite>
    if(recovering == 0)
    8000429a:	f80b1ce3          	bnez	s6,80004232 <install_trans+0x40>
    8000429e:	b769                	j	80004228 <install_trans+0x36>
}
    800042a0:	70e2                	ld	ra,56(sp)
    800042a2:	7442                	ld	s0,48(sp)
    800042a4:	74a2                	ld	s1,40(sp)
    800042a6:	7902                	ld	s2,32(sp)
    800042a8:	69e2                	ld	s3,24(sp)
    800042aa:	6a42                	ld	s4,16(sp)
    800042ac:	6aa2                	ld	s5,8(sp)
    800042ae:	6b02                	ld	s6,0(sp)
    800042b0:	6121                	addi	sp,sp,64
    800042b2:	8082                	ret
    800042b4:	8082                	ret

00000000800042b6 <initlog>:
{
    800042b6:	7179                	addi	sp,sp,-48
    800042b8:	f406                	sd	ra,40(sp)
    800042ba:	f022                	sd	s0,32(sp)
    800042bc:	ec26                	sd	s1,24(sp)
    800042be:	e84a                	sd	s2,16(sp)
    800042c0:	e44e                	sd	s3,8(sp)
    800042c2:	1800                	addi	s0,sp,48
    800042c4:	892a                	mv	s2,a0
    800042c6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042c8:	0001d497          	auipc	s1,0x1d
    800042cc:	1a848493          	addi	s1,s1,424 # 80021470 <log>
    800042d0:	00004597          	auipc	a1,0x4
    800042d4:	37858593          	addi	a1,a1,888 # 80008648 <syscalls+0x1e8>
    800042d8:	8526                	mv	a0,s1
    800042da:	ffffd097          	auipc	ra,0xffffd
    800042de:	87a080e7          	jalr	-1926(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800042e2:	0149a583          	lw	a1,20(s3)
    800042e6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042e8:	0109a783          	lw	a5,16(s3)
    800042ec:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042ee:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042f2:	854a                	mv	a0,s2
    800042f4:	fffff097          	auipc	ra,0xfffff
    800042f8:	e92080e7          	jalr	-366(ra) # 80003186 <bread>
  log.lh.n = lh->n;
    800042fc:	4d3c                	lw	a5,88(a0)
    800042fe:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004300:	02f05563          	blez	a5,8000432a <initlog+0x74>
    80004304:	05c50713          	addi	a4,a0,92
    80004308:	0001d697          	auipc	a3,0x1d
    8000430c:	19868693          	addi	a3,a3,408 # 800214a0 <log+0x30>
    80004310:	37fd                	addiw	a5,a5,-1
    80004312:	1782                	slli	a5,a5,0x20
    80004314:	9381                	srli	a5,a5,0x20
    80004316:	078a                	slli	a5,a5,0x2
    80004318:	06050613          	addi	a2,a0,96
    8000431c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000431e:	4310                	lw	a2,0(a4)
    80004320:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004322:	0711                	addi	a4,a4,4
    80004324:	0691                	addi	a3,a3,4
    80004326:	fef71ce3          	bne	a4,a5,8000431e <initlog+0x68>
  brelse(buf);
    8000432a:	fffff097          	auipc	ra,0xfffff
    8000432e:	f8c080e7          	jalr	-116(ra) # 800032b6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004332:	4505                	li	a0,1
    80004334:	00000097          	auipc	ra,0x0
    80004338:	ebe080e7          	jalr	-322(ra) # 800041f2 <install_trans>
  log.lh.n = 0;
    8000433c:	0001d797          	auipc	a5,0x1d
    80004340:	1607a023          	sw	zero,352(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    80004344:	00000097          	auipc	ra,0x0
    80004348:	e34080e7          	jalr	-460(ra) # 80004178 <write_head>
}
    8000434c:	70a2                	ld	ra,40(sp)
    8000434e:	7402                	ld	s0,32(sp)
    80004350:	64e2                	ld	s1,24(sp)
    80004352:	6942                	ld	s2,16(sp)
    80004354:	69a2                	ld	s3,8(sp)
    80004356:	6145                	addi	sp,sp,48
    80004358:	8082                	ret

000000008000435a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000435a:	1101                	addi	sp,sp,-32
    8000435c:	ec06                	sd	ra,24(sp)
    8000435e:	e822                	sd	s0,16(sp)
    80004360:	e426                	sd	s1,8(sp)
    80004362:	e04a                	sd	s2,0(sp)
    80004364:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004366:	0001d517          	auipc	a0,0x1d
    8000436a:	10a50513          	addi	a0,a0,266 # 80021470 <log>
    8000436e:	ffffd097          	auipc	ra,0xffffd
    80004372:	876080e7          	jalr	-1930(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004376:	0001d497          	auipc	s1,0x1d
    8000437a:	0fa48493          	addi	s1,s1,250 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000437e:	4979                	li	s2,30
    80004380:	a039                	j	8000438e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004382:	85a6                	mv	a1,s1
    80004384:	8526                	mv	a0,s1
    80004386:	ffffe097          	auipc	ra,0xffffe
    8000438a:	f98080e7          	jalr	-104(ra) # 8000231e <sleep>
    if(log.committing){
    8000438e:	50dc                	lw	a5,36(s1)
    80004390:	fbed                	bnez	a5,80004382 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004392:	509c                	lw	a5,32(s1)
    80004394:	0017871b          	addiw	a4,a5,1
    80004398:	0007069b          	sext.w	a3,a4
    8000439c:	0027179b          	slliw	a5,a4,0x2
    800043a0:	9fb9                	addw	a5,a5,a4
    800043a2:	0017979b          	slliw	a5,a5,0x1
    800043a6:	54d8                	lw	a4,44(s1)
    800043a8:	9fb9                	addw	a5,a5,a4
    800043aa:	00f95963          	bge	s2,a5,800043bc <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043ae:	85a6                	mv	a1,s1
    800043b0:	8526                	mv	a0,s1
    800043b2:	ffffe097          	auipc	ra,0xffffe
    800043b6:	f6c080e7          	jalr	-148(ra) # 8000231e <sleep>
    800043ba:	bfd1                	j	8000438e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043bc:	0001d517          	auipc	a0,0x1d
    800043c0:	0b450513          	addi	a0,a0,180 # 80021470 <log>
    800043c4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043c6:	ffffd097          	auipc	ra,0xffffd
    800043ca:	8d2080e7          	jalr	-1838(ra) # 80000c98 <release>
      break;
    }
  }
}
    800043ce:	60e2                	ld	ra,24(sp)
    800043d0:	6442                	ld	s0,16(sp)
    800043d2:	64a2                	ld	s1,8(sp)
    800043d4:	6902                	ld	s2,0(sp)
    800043d6:	6105                	addi	sp,sp,32
    800043d8:	8082                	ret

00000000800043da <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043da:	7139                	addi	sp,sp,-64
    800043dc:	fc06                	sd	ra,56(sp)
    800043de:	f822                	sd	s0,48(sp)
    800043e0:	f426                	sd	s1,40(sp)
    800043e2:	f04a                	sd	s2,32(sp)
    800043e4:	ec4e                	sd	s3,24(sp)
    800043e6:	e852                	sd	s4,16(sp)
    800043e8:	e456                	sd	s5,8(sp)
    800043ea:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043ec:	0001d497          	auipc	s1,0x1d
    800043f0:	08448493          	addi	s1,s1,132 # 80021470 <log>
    800043f4:	8526                	mv	a0,s1
    800043f6:	ffffc097          	auipc	ra,0xffffc
    800043fa:	7ee080e7          	jalr	2030(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800043fe:	509c                	lw	a5,32(s1)
    80004400:	37fd                	addiw	a5,a5,-1
    80004402:	0007891b          	sext.w	s2,a5
    80004406:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004408:	50dc                	lw	a5,36(s1)
    8000440a:	efb9                	bnez	a5,80004468 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000440c:	06091663          	bnez	s2,80004478 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004410:	0001d497          	auipc	s1,0x1d
    80004414:	06048493          	addi	s1,s1,96 # 80021470 <log>
    80004418:	4785                	li	a5,1
    8000441a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000441c:	8526                	mv	a0,s1
    8000441e:	ffffd097          	auipc	ra,0xffffd
    80004422:	87a080e7          	jalr	-1926(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004426:	54dc                	lw	a5,44(s1)
    80004428:	06f04763          	bgtz	a5,80004496 <end_op+0xbc>
    acquire(&log.lock);
    8000442c:	0001d497          	auipc	s1,0x1d
    80004430:	04448493          	addi	s1,s1,68 # 80021470 <log>
    80004434:	8526                	mv	a0,s1
    80004436:	ffffc097          	auipc	ra,0xffffc
    8000443a:	7ae080e7          	jalr	1966(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000443e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004442:	8526                	mv	a0,s1
    80004444:	ffffe097          	auipc	ra,0xffffe
    80004448:	066080e7          	jalr	102(ra) # 800024aa <wakeup>
    release(&log.lock);
    8000444c:	8526                	mv	a0,s1
    8000444e:	ffffd097          	auipc	ra,0xffffd
    80004452:	84a080e7          	jalr	-1974(ra) # 80000c98 <release>
}
    80004456:	70e2                	ld	ra,56(sp)
    80004458:	7442                	ld	s0,48(sp)
    8000445a:	74a2                	ld	s1,40(sp)
    8000445c:	7902                	ld	s2,32(sp)
    8000445e:	69e2                	ld	s3,24(sp)
    80004460:	6a42                	ld	s4,16(sp)
    80004462:	6aa2                	ld	s5,8(sp)
    80004464:	6121                	addi	sp,sp,64
    80004466:	8082                	ret
    panic("log.committing");
    80004468:	00004517          	auipc	a0,0x4
    8000446c:	1e850513          	addi	a0,a0,488 # 80008650 <syscalls+0x1f0>
    80004470:	ffffc097          	auipc	ra,0xffffc
    80004474:	0ce080e7          	jalr	206(ra) # 8000053e <panic>
    wakeup(&log);
    80004478:	0001d497          	auipc	s1,0x1d
    8000447c:	ff848493          	addi	s1,s1,-8 # 80021470 <log>
    80004480:	8526                	mv	a0,s1
    80004482:	ffffe097          	auipc	ra,0xffffe
    80004486:	028080e7          	jalr	40(ra) # 800024aa <wakeup>
  release(&log.lock);
    8000448a:	8526                	mv	a0,s1
    8000448c:	ffffd097          	auipc	ra,0xffffd
    80004490:	80c080e7          	jalr	-2036(ra) # 80000c98 <release>
  if(do_commit){
    80004494:	b7c9                	j	80004456 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004496:	0001da97          	auipc	s5,0x1d
    8000449a:	00aa8a93          	addi	s5,s5,10 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000449e:	0001da17          	auipc	s4,0x1d
    800044a2:	fd2a0a13          	addi	s4,s4,-46 # 80021470 <log>
    800044a6:	018a2583          	lw	a1,24(s4)
    800044aa:	012585bb          	addw	a1,a1,s2
    800044ae:	2585                	addiw	a1,a1,1
    800044b0:	028a2503          	lw	a0,40(s4)
    800044b4:	fffff097          	auipc	ra,0xfffff
    800044b8:	cd2080e7          	jalr	-814(ra) # 80003186 <bread>
    800044bc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044be:	000aa583          	lw	a1,0(s5)
    800044c2:	028a2503          	lw	a0,40(s4)
    800044c6:	fffff097          	auipc	ra,0xfffff
    800044ca:	cc0080e7          	jalr	-832(ra) # 80003186 <bread>
    800044ce:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044d0:	40000613          	li	a2,1024
    800044d4:	05850593          	addi	a1,a0,88
    800044d8:	05848513          	addi	a0,s1,88
    800044dc:	ffffd097          	auipc	ra,0xffffd
    800044e0:	864080e7          	jalr	-1948(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800044e4:	8526                	mv	a0,s1
    800044e6:	fffff097          	auipc	ra,0xfffff
    800044ea:	d92080e7          	jalr	-622(ra) # 80003278 <bwrite>
    brelse(from);
    800044ee:	854e                	mv	a0,s3
    800044f0:	fffff097          	auipc	ra,0xfffff
    800044f4:	dc6080e7          	jalr	-570(ra) # 800032b6 <brelse>
    brelse(to);
    800044f8:	8526                	mv	a0,s1
    800044fa:	fffff097          	auipc	ra,0xfffff
    800044fe:	dbc080e7          	jalr	-580(ra) # 800032b6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004502:	2905                	addiw	s2,s2,1
    80004504:	0a91                	addi	s5,s5,4
    80004506:	02ca2783          	lw	a5,44(s4)
    8000450a:	f8f94ee3          	blt	s2,a5,800044a6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000450e:	00000097          	auipc	ra,0x0
    80004512:	c6a080e7          	jalr	-918(ra) # 80004178 <write_head>
    install_trans(0); // Now install writes to home locations
    80004516:	4501                	li	a0,0
    80004518:	00000097          	auipc	ra,0x0
    8000451c:	cda080e7          	jalr	-806(ra) # 800041f2 <install_trans>
    log.lh.n = 0;
    80004520:	0001d797          	auipc	a5,0x1d
    80004524:	f607ae23          	sw	zero,-132(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004528:	00000097          	auipc	ra,0x0
    8000452c:	c50080e7          	jalr	-944(ra) # 80004178 <write_head>
    80004530:	bdf5                	j	8000442c <end_op+0x52>

0000000080004532 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004532:	1101                	addi	sp,sp,-32
    80004534:	ec06                	sd	ra,24(sp)
    80004536:	e822                	sd	s0,16(sp)
    80004538:	e426                	sd	s1,8(sp)
    8000453a:	e04a                	sd	s2,0(sp)
    8000453c:	1000                	addi	s0,sp,32
    8000453e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004540:	0001d917          	auipc	s2,0x1d
    80004544:	f3090913          	addi	s2,s2,-208 # 80021470 <log>
    80004548:	854a                	mv	a0,s2
    8000454a:	ffffc097          	auipc	ra,0xffffc
    8000454e:	69a080e7          	jalr	1690(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004552:	02c92603          	lw	a2,44(s2)
    80004556:	47f5                	li	a5,29
    80004558:	06c7c563          	blt	a5,a2,800045c2 <log_write+0x90>
    8000455c:	0001d797          	auipc	a5,0x1d
    80004560:	f307a783          	lw	a5,-208(a5) # 8002148c <log+0x1c>
    80004564:	37fd                	addiw	a5,a5,-1
    80004566:	04f65e63          	bge	a2,a5,800045c2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000456a:	0001d797          	auipc	a5,0x1d
    8000456e:	f267a783          	lw	a5,-218(a5) # 80021490 <log+0x20>
    80004572:	06f05063          	blez	a5,800045d2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004576:	4781                	li	a5,0
    80004578:	06c05563          	blez	a2,800045e2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000457c:	44cc                	lw	a1,12(s1)
    8000457e:	0001d717          	auipc	a4,0x1d
    80004582:	f2270713          	addi	a4,a4,-222 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004586:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004588:	4314                	lw	a3,0(a4)
    8000458a:	04b68c63          	beq	a3,a1,800045e2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000458e:	2785                	addiw	a5,a5,1
    80004590:	0711                	addi	a4,a4,4
    80004592:	fef61be3          	bne	a2,a5,80004588 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004596:	0621                	addi	a2,a2,8
    80004598:	060a                	slli	a2,a2,0x2
    8000459a:	0001d797          	auipc	a5,0x1d
    8000459e:	ed678793          	addi	a5,a5,-298 # 80021470 <log>
    800045a2:	963e                	add	a2,a2,a5
    800045a4:	44dc                	lw	a5,12(s1)
    800045a6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045a8:	8526                	mv	a0,s1
    800045aa:	fffff097          	auipc	ra,0xfffff
    800045ae:	daa080e7          	jalr	-598(ra) # 80003354 <bpin>
    log.lh.n++;
    800045b2:	0001d717          	auipc	a4,0x1d
    800045b6:	ebe70713          	addi	a4,a4,-322 # 80021470 <log>
    800045ba:	575c                	lw	a5,44(a4)
    800045bc:	2785                	addiw	a5,a5,1
    800045be:	d75c                	sw	a5,44(a4)
    800045c0:	a835                	j	800045fc <log_write+0xca>
    panic("too big a transaction");
    800045c2:	00004517          	auipc	a0,0x4
    800045c6:	09e50513          	addi	a0,a0,158 # 80008660 <syscalls+0x200>
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	f74080e7          	jalr	-140(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800045d2:	00004517          	auipc	a0,0x4
    800045d6:	0a650513          	addi	a0,a0,166 # 80008678 <syscalls+0x218>
    800045da:	ffffc097          	auipc	ra,0xffffc
    800045de:	f64080e7          	jalr	-156(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800045e2:	00878713          	addi	a4,a5,8
    800045e6:	00271693          	slli	a3,a4,0x2
    800045ea:	0001d717          	auipc	a4,0x1d
    800045ee:	e8670713          	addi	a4,a4,-378 # 80021470 <log>
    800045f2:	9736                	add	a4,a4,a3
    800045f4:	44d4                	lw	a3,12(s1)
    800045f6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045f8:	faf608e3          	beq	a2,a5,800045a8 <log_write+0x76>
  }
  release(&log.lock);
    800045fc:	0001d517          	auipc	a0,0x1d
    80004600:	e7450513          	addi	a0,a0,-396 # 80021470 <log>
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	694080e7          	jalr	1684(ra) # 80000c98 <release>
}
    8000460c:	60e2                	ld	ra,24(sp)
    8000460e:	6442                	ld	s0,16(sp)
    80004610:	64a2                	ld	s1,8(sp)
    80004612:	6902                	ld	s2,0(sp)
    80004614:	6105                	addi	sp,sp,32
    80004616:	8082                	ret

0000000080004618 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004618:	1101                	addi	sp,sp,-32
    8000461a:	ec06                	sd	ra,24(sp)
    8000461c:	e822                	sd	s0,16(sp)
    8000461e:	e426                	sd	s1,8(sp)
    80004620:	e04a                	sd	s2,0(sp)
    80004622:	1000                	addi	s0,sp,32
    80004624:	84aa                	mv	s1,a0
    80004626:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004628:	00004597          	auipc	a1,0x4
    8000462c:	07058593          	addi	a1,a1,112 # 80008698 <syscalls+0x238>
    80004630:	0521                	addi	a0,a0,8
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	522080e7          	jalr	1314(ra) # 80000b54 <initlock>
  lk->name = name;
    8000463a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000463e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004642:	0204a423          	sw	zero,40(s1)
}
    80004646:	60e2                	ld	ra,24(sp)
    80004648:	6442                	ld	s0,16(sp)
    8000464a:	64a2                	ld	s1,8(sp)
    8000464c:	6902                	ld	s2,0(sp)
    8000464e:	6105                	addi	sp,sp,32
    80004650:	8082                	ret

0000000080004652 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004652:	1101                	addi	sp,sp,-32
    80004654:	ec06                	sd	ra,24(sp)
    80004656:	e822                	sd	s0,16(sp)
    80004658:	e426                	sd	s1,8(sp)
    8000465a:	e04a                	sd	s2,0(sp)
    8000465c:	1000                	addi	s0,sp,32
    8000465e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004660:	00850913          	addi	s2,a0,8
    80004664:	854a                	mv	a0,s2
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	57e080e7          	jalr	1406(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000466e:	409c                	lw	a5,0(s1)
    80004670:	cb89                	beqz	a5,80004682 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004672:	85ca                	mv	a1,s2
    80004674:	8526                	mv	a0,s1
    80004676:	ffffe097          	auipc	ra,0xffffe
    8000467a:	ca8080e7          	jalr	-856(ra) # 8000231e <sleep>
  while (lk->locked) {
    8000467e:	409c                	lw	a5,0(s1)
    80004680:	fbed                	bnez	a5,80004672 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004682:	4785                	li	a5,1
    80004684:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004686:	ffffd097          	auipc	ra,0xffffd
    8000468a:	348080e7          	jalr	840(ra) # 800019ce <myproc>
    8000468e:	591c                	lw	a5,48(a0)
    80004690:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004692:	854a                	mv	a0,s2
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	604080e7          	jalr	1540(ra) # 80000c98 <release>
}
    8000469c:	60e2                	ld	ra,24(sp)
    8000469e:	6442                	ld	s0,16(sp)
    800046a0:	64a2                	ld	s1,8(sp)
    800046a2:	6902                	ld	s2,0(sp)
    800046a4:	6105                	addi	sp,sp,32
    800046a6:	8082                	ret

00000000800046a8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046a8:	1101                	addi	sp,sp,-32
    800046aa:	ec06                	sd	ra,24(sp)
    800046ac:	e822                	sd	s0,16(sp)
    800046ae:	e426                	sd	s1,8(sp)
    800046b0:	e04a                	sd	s2,0(sp)
    800046b2:	1000                	addi	s0,sp,32
    800046b4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046b6:	00850913          	addi	s2,a0,8
    800046ba:	854a                	mv	a0,s2
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	528080e7          	jalr	1320(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800046c4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046c8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046cc:	8526                	mv	a0,s1
    800046ce:	ffffe097          	auipc	ra,0xffffe
    800046d2:	ddc080e7          	jalr	-548(ra) # 800024aa <wakeup>
  release(&lk->lk);
    800046d6:	854a                	mv	a0,s2
    800046d8:	ffffc097          	auipc	ra,0xffffc
    800046dc:	5c0080e7          	jalr	1472(ra) # 80000c98 <release>
}
    800046e0:	60e2                	ld	ra,24(sp)
    800046e2:	6442                	ld	s0,16(sp)
    800046e4:	64a2                	ld	s1,8(sp)
    800046e6:	6902                	ld	s2,0(sp)
    800046e8:	6105                	addi	sp,sp,32
    800046ea:	8082                	ret

00000000800046ec <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046ec:	7179                	addi	sp,sp,-48
    800046ee:	f406                	sd	ra,40(sp)
    800046f0:	f022                	sd	s0,32(sp)
    800046f2:	ec26                	sd	s1,24(sp)
    800046f4:	e84a                	sd	s2,16(sp)
    800046f6:	e44e                	sd	s3,8(sp)
    800046f8:	1800                	addi	s0,sp,48
    800046fa:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046fc:	00850913          	addi	s2,a0,8
    80004700:	854a                	mv	a0,s2
    80004702:	ffffc097          	auipc	ra,0xffffc
    80004706:	4e2080e7          	jalr	1250(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000470a:	409c                	lw	a5,0(s1)
    8000470c:	ef99                	bnez	a5,8000472a <holdingsleep+0x3e>
    8000470e:	4481                	li	s1,0
  release(&lk->lk);
    80004710:	854a                	mv	a0,s2
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	586080e7          	jalr	1414(ra) # 80000c98 <release>
  return r;
}
    8000471a:	8526                	mv	a0,s1
    8000471c:	70a2                	ld	ra,40(sp)
    8000471e:	7402                	ld	s0,32(sp)
    80004720:	64e2                	ld	s1,24(sp)
    80004722:	6942                	ld	s2,16(sp)
    80004724:	69a2                	ld	s3,8(sp)
    80004726:	6145                	addi	sp,sp,48
    80004728:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000472a:	0284a983          	lw	s3,40(s1)
    8000472e:	ffffd097          	auipc	ra,0xffffd
    80004732:	2a0080e7          	jalr	672(ra) # 800019ce <myproc>
    80004736:	5904                	lw	s1,48(a0)
    80004738:	413484b3          	sub	s1,s1,s3
    8000473c:	0014b493          	seqz	s1,s1
    80004740:	bfc1                	j	80004710 <holdingsleep+0x24>

0000000080004742 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004742:	1141                	addi	sp,sp,-16
    80004744:	e406                	sd	ra,8(sp)
    80004746:	e022                	sd	s0,0(sp)
    80004748:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000474a:	00004597          	auipc	a1,0x4
    8000474e:	f5e58593          	addi	a1,a1,-162 # 800086a8 <syscalls+0x248>
    80004752:	0001d517          	auipc	a0,0x1d
    80004756:	e6650513          	addi	a0,a0,-410 # 800215b8 <ftable>
    8000475a:	ffffc097          	auipc	ra,0xffffc
    8000475e:	3fa080e7          	jalr	1018(ra) # 80000b54 <initlock>
}
    80004762:	60a2                	ld	ra,8(sp)
    80004764:	6402                	ld	s0,0(sp)
    80004766:	0141                	addi	sp,sp,16
    80004768:	8082                	ret

000000008000476a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000476a:	1101                	addi	sp,sp,-32
    8000476c:	ec06                	sd	ra,24(sp)
    8000476e:	e822                	sd	s0,16(sp)
    80004770:	e426                	sd	s1,8(sp)
    80004772:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004774:	0001d517          	auipc	a0,0x1d
    80004778:	e4450513          	addi	a0,a0,-444 # 800215b8 <ftable>
    8000477c:	ffffc097          	auipc	ra,0xffffc
    80004780:	468080e7          	jalr	1128(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004784:	0001d497          	auipc	s1,0x1d
    80004788:	e4c48493          	addi	s1,s1,-436 # 800215d0 <ftable+0x18>
    8000478c:	0001e717          	auipc	a4,0x1e
    80004790:	de470713          	addi	a4,a4,-540 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    80004794:	40dc                	lw	a5,4(s1)
    80004796:	cf99                	beqz	a5,800047b4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004798:	02848493          	addi	s1,s1,40
    8000479c:	fee49ce3          	bne	s1,a4,80004794 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047a0:	0001d517          	auipc	a0,0x1d
    800047a4:	e1850513          	addi	a0,a0,-488 # 800215b8 <ftable>
    800047a8:	ffffc097          	auipc	ra,0xffffc
    800047ac:	4f0080e7          	jalr	1264(ra) # 80000c98 <release>
  return 0;
    800047b0:	4481                	li	s1,0
    800047b2:	a819                	j	800047c8 <filealloc+0x5e>
      f->ref = 1;
    800047b4:	4785                	li	a5,1
    800047b6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047b8:	0001d517          	auipc	a0,0x1d
    800047bc:	e0050513          	addi	a0,a0,-512 # 800215b8 <ftable>
    800047c0:	ffffc097          	auipc	ra,0xffffc
    800047c4:	4d8080e7          	jalr	1240(ra) # 80000c98 <release>
}
    800047c8:	8526                	mv	a0,s1
    800047ca:	60e2                	ld	ra,24(sp)
    800047cc:	6442                	ld	s0,16(sp)
    800047ce:	64a2                	ld	s1,8(sp)
    800047d0:	6105                	addi	sp,sp,32
    800047d2:	8082                	ret

00000000800047d4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047d4:	1101                	addi	sp,sp,-32
    800047d6:	ec06                	sd	ra,24(sp)
    800047d8:	e822                	sd	s0,16(sp)
    800047da:	e426                	sd	s1,8(sp)
    800047dc:	1000                	addi	s0,sp,32
    800047de:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047e0:	0001d517          	auipc	a0,0x1d
    800047e4:	dd850513          	addi	a0,a0,-552 # 800215b8 <ftable>
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	3fc080e7          	jalr	1020(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800047f0:	40dc                	lw	a5,4(s1)
    800047f2:	02f05263          	blez	a5,80004816 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047f6:	2785                	addiw	a5,a5,1
    800047f8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047fa:	0001d517          	auipc	a0,0x1d
    800047fe:	dbe50513          	addi	a0,a0,-578 # 800215b8 <ftable>
    80004802:	ffffc097          	auipc	ra,0xffffc
    80004806:	496080e7          	jalr	1174(ra) # 80000c98 <release>
  return f;
}
    8000480a:	8526                	mv	a0,s1
    8000480c:	60e2                	ld	ra,24(sp)
    8000480e:	6442                	ld	s0,16(sp)
    80004810:	64a2                	ld	s1,8(sp)
    80004812:	6105                	addi	sp,sp,32
    80004814:	8082                	ret
    panic("filedup");
    80004816:	00004517          	auipc	a0,0x4
    8000481a:	e9a50513          	addi	a0,a0,-358 # 800086b0 <syscalls+0x250>
    8000481e:	ffffc097          	auipc	ra,0xffffc
    80004822:	d20080e7          	jalr	-736(ra) # 8000053e <panic>

0000000080004826 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004826:	7139                	addi	sp,sp,-64
    80004828:	fc06                	sd	ra,56(sp)
    8000482a:	f822                	sd	s0,48(sp)
    8000482c:	f426                	sd	s1,40(sp)
    8000482e:	f04a                	sd	s2,32(sp)
    80004830:	ec4e                	sd	s3,24(sp)
    80004832:	e852                	sd	s4,16(sp)
    80004834:	e456                	sd	s5,8(sp)
    80004836:	0080                	addi	s0,sp,64
    80004838:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000483a:	0001d517          	auipc	a0,0x1d
    8000483e:	d7e50513          	addi	a0,a0,-642 # 800215b8 <ftable>
    80004842:	ffffc097          	auipc	ra,0xffffc
    80004846:	3a2080e7          	jalr	930(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000484a:	40dc                	lw	a5,4(s1)
    8000484c:	06f05163          	blez	a5,800048ae <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004850:	37fd                	addiw	a5,a5,-1
    80004852:	0007871b          	sext.w	a4,a5
    80004856:	c0dc                	sw	a5,4(s1)
    80004858:	06e04363          	bgtz	a4,800048be <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000485c:	0004a903          	lw	s2,0(s1)
    80004860:	0094ca83          	lbu	s5,9(s1)
    80004864:	0104ba03          	ld	s4,16(s1)
    80004868:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000486c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004870:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004874:	0001d517          	auipc	a0,0x1d
    80004878:	d4450513          	addi	a0,a0,-700 # 800215b8 <ftable>
    8000487c:	ffffc097          	auipc	ra,0xffffc
    80004880:	41c080e7          	jalr	1052(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004884:	4785                	li	a5,1
    80004886:	04f90d63          	beq	s2,a5,800048e0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000488a:	3979                	addiw	s2,s2,-2
    8000488c:	4785                	li	a5,1
    8000488e:	0527e063          	bltu	a5,s2,800048ce <fileclose+0xa8>
    begin_op();
    80004892:	00000097          	auipc	ra,0x0
    80004896:	ac8080e7          	jalr	-1336(ra) # 8000435a <begin_op>
    iput(ff.ip);
    8000489a:	854e                	mv	a0,s3
    8000489c:	fffff097          	auipc	ra,0xfffff
    800048a0:	2a6080e7          	jalr	678(ra) # 80003b42 <iput>
    end_op();
    800048a4:	00000097          	auipc	ra,0x0
    800048a8:	b36080e7          	jalr	-1226(ra) # 800043da <end_op>
    800048ac:	a00d                	j	800048ce <fileclose+0xa8>
    panic("fileclose");
    800048ae:	00004517          	auipc	a0,0x4
    800048b2:	e0a50513          	addi	a0,a0,-502 # 800086b8 <syscalls+0x258>
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	c88080e7          	jalr	-888(ra) # 8000053e <panic>
    release(&ftable.lock);
    800048be:	0001d517          	auipc	a0,0x1d
    800048c2:	cfa50513          	addi	a0,a0,-774 # 800215b8 <ftable>
    800048c6:	ffffc097          	auipc	ra,0xffffc
    800048ca:	3d2080e7          	jalr	978(ra) # 80000c98 <release>
  }
}
    800048ce:	70e2                	ld	ra,56(sp)
    800048d0:	7442                	ld	s0,48(sp)
    800048d2:	74a2                	ld	s1,40(sp)
    800048d4:	7902                	ld	s2,32(sp)
    800048d6:	69e2                	ld	s3,24(sp)
    800048d8:	6a42                	ld	s4,16(sp)
    800048da:	6aa2                	ld	s5,8(sp)
    800048dc:	6121                	addi	sp,sp,64
    800048de:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048e0:	85d6                	mv	a1,s5
    800048e2:	8552                	mv	a0,s4
    800048e4:	00000097          	auipc	ra,0x0
    800048e8:	34c080e7          	jalr	844(ra) # 80004c30 <pipeclose>
    800048ec:	b7cd                	j	800048ce <fileclose+0xa8>

00000000800048ee <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048ee:	715d                	addi	sp,sp,-80
    800048f0:	e486                	sd	ra,72(sp)
    800048f2:	e0a2                	sd	s0,64(sp)
    800048f4:	fc26                	sd	s1,56(sp)
    800048f6:	f84a                	sd	s2,48(sp)
    800048f8:	f44e                	sd	s3,40(sp)
    800048fa:	0880                	addi	s0,sp,80
    800048fc:	84aa                	mv	s1,a0
    800048fe:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004900:	ffffd097          	auipc	ra,0xffffd
    80004904:	0ce080e7          	jalr	206(ra) # 800019ce <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004908:	409c                	lw	a5,0(s1)
    8000490a:	37f9                	addiw	a5,a5,-2
    8000490c:	4705                	li	a4,1
    8000490e:	04f76763          	bltu	a4,a5,8000495c <filestat+0x6e>
    80004912:	892a                	mv	s2,a0
    ilock(f->ip);
    80004914:	6c88                	ld	a0,24(s1)
    80004916:	fffff097          	auipc	ra,0xfffff
    8000491a:	072080e7          	jalr	114(ra) # 80003988 <ilock>
    stati(f->ip, &st);
    8000491e:	fb840593          	addi	a1,s0,-72
    80004922:	6c88                	ld	a0,24(s1)
    80004924:	fffff097          	auipc	ra,0xfffff
    80004928:	2ee080e7          	jalr	750(ra) # 80003c12 <stati>
    iunlock(f->ip);
    8000492c:	6c88                	ld	a0,24(s1)
    8000492e:	fffff097          	auipc	ra,0xfffff
    80004932:	11c080e7          	jalr	284(ra) # 80003a4a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004936:	46e1                	li	a3,24
    80004938:	fb840613          	addi	a2,s0,-72
    8000493c:	85ce                	mv	a1,s3
    8000493e:	05893503          	ld	a0,88(s2)
    80004942:	ffffd097          	auipc	ra,0xffffd
    80004946:	d38080e7          	jalr	-712(ra) # 8000167a <copyout>
    8000494a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000494e:	60a6                	ld	ra,72(sp)
    80004950:	6406                	ld	s0,64(sp)
    80004952:	74e2                	ld	s1,56(sp)
    80004954:	7942                	ld	s2,48(sp)
    80004956:	79a2                	ld	s3,40(sp)
    80004958:	6161                	addi	sp,sp,80
    8000495a:	8082                	ret
  return -1;
    8000495c:	557d                	li	a0,-1
    8000495e:	bfc5                	j	8000494e <filestat+0x60>

0000000080004960 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004960:	7179                	addi	sp,sp,-48
    80004962:	f406                	sd	ra,40(sp)
    80004964:	f022                	sd	s0,32(sp)
    80004966:	ec26                	sd	s1,24(sp)
    80004968:	e84a                	sd	s2,16(sp)
    8000496a:	e44e                	sd	s3,8(sp)
    8000496c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000496e:	00854783          	lbu	a5,8(a0)
    80004972:	c3d5                	beqz	a5,80004a16 <fileread+0xb6>
    80004974:	84aa                	mv	s1,a0
    80004976:	89ae                	mv	s3,a1
    80004978:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000497a:	411c                	lw	a5,0(a0)
    8000497c:	4705                	li	a4,1
    8000497e:	04e78963          	beq	a5,a4,800049d0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004982:	470d                	li	a4,3
    80004984:	04e78d63          	beq	a5,a4,800049de <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004988:	4709                	li	a4,2
    8000498a:	06e79e63          	bne	a5,a4,80004a06 <fileread+0xa6>
    ilock(f->ip);
    8000498e:	6d08                	ld	a0,24(a0)
    80004990:	fffff097          	auipc	ra,0xfffff
    80004994:	ff8080e7          	jalr	-8(ra) # 80003988 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004998:	874a                	mv	a4,s2
    8000499a:	5094                	lw	a3,32(s1)
    8000499c:	864e                	mv	a2,s3
    8000499e:	4585                	li	a1,1
    800049a0:	6c88                	ld	a0,24(s1)
    800049a2:	fffff097          	auipc	ra,0xfffff
    800049a6:	29a080e7          	jalr	666(ra) # 80003c3c <readi>
    800049aa:	892a                	mv	s2,a0
    800049ac:	00a05563          	blez	a0,800049b6 <fileread+0x56>
      f->off += r;
    800049b0:	509c                	lw	a5,32(s1)
    800049b2:	9fa9                	addw	a5,a5,a0
    800049b4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049b6:	6c88                	ld	a0,24(s1)
    800049b8:	fffff097          	auipc	ra,0xfffff
    800049bc:	092080e7          	jalr	146(ra) # 80003a4a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049c0:	854a                	mv	a0,s2
    800049c2:	70a2                	ld	ra,40(sp)
    800049c4:	7402                	ld	s0,32(sp)
    800049c6:	64e2                	ld	s1,24(sp)
    800049c8:	6942                	ld	s2,16(sp)
    800049ca:	69a2                	ld	s3,8(sp)
    800049cc:	6145                	addi	sp,sp,48
    800049ce:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049d0:	6908                	ld	a0,16(a0)
    800049d2:	00000097          	auipc	ra,0x0
    800049d6:	3c8080e7          	jalr	968(ra) # 80004d9a <piperead>
    800049da:	892a                	mv	s2,a0
    800049dc:	b7d5                	j	800049c0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049de:	02451783          	lh	a5,36(a0)
    800049e2:	03079693          	slli	a3,a5,0x30
    800049e6:	92c1                	srli	a3,a3,0x30
    800049e8:	4725                	li	a4,9
    800049ea:	02d76863          	bltu	a4,a3,80004a1a <fileread+0xba>
    800049ee:	0792                	slli	a5,a5,0x4
    800049f0:	0001d717          	auipc	a4,0x1d
    800049f4:	b2870713          	addi	a4,a4,-1240 # 80021518 <devsw>
    800049f8:	97ba                	add	a5,a5,a4
    800049fa:	639c                	ld	a5,0(a5)
    800049fc:	c38d                	beqz	a5,80004a1e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049fe:	4505                	li	a0,1
    80004a00:	9782                	jalr	a5
    80004a02:	892a                	mv	s2,a0
    80004a04:	bf75                	j	800049c0 <fileread+0x60>
    panic("fileread");
    80004a06:	00004517          	auipc	a0,0x4
    80004a0a:	cc250513          	addi	a0,a0,-830 # 800086c8 <syscalls+0x268>
    80004a0e:	ffffc097          	auipc	ra,0xffffc
    80004a12:	b30080e7          	jalr	-1232(ra) # 8000053e <panic>
    return -1;
    80004a16:	597d                	li	s2,-1
    80004a18:	b765                	j	800049c0 <fileread+0x60>
      return -1;
    80004a1a:	597d                	li	s2,-1
    80004a1c:	b755                	j	800049c0 <fileread+0x60>
    80004a1e:	597d                	li	s2,-1
    80004a20:	b745                	j	800049c0 <fileread+0x60>

0000000080004a22 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a22:	715d                	addi	sp,sp,-80
    80004a24:	e486                	sd	ra,72(sp)
    80004a26:	e0a2                	sd	s0,64(sp)
    80004a28:	fc26                	sd	s1,56(sp)
    80004a2a:	f84a                	sd	s2,48(sp)
    80004a2c:	f44e                	sd	s3,40(sp)
    80004a2e:	f052                	sd	s4,32(sp)
    80004a30:	ec56                	sd	s5,24(sp)
    80004a32:	e85a                	sd	s6,16(sp)
    80004a34:	e45e                	sd	s7,8(sp)
    80004a36:	e062                	sd	s8,0(sp)
    80004a38:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a3a:	00954783          	lbu	a5,9(a0)
    80004a3e:	10078663          	beqz	a5,80004b4a <filewrite+0x128>
    80004a42:	892a                	mv	s2,a0
    80004a44:	8aae                	mv	s5,a1
    80004a46:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a48:	411c                	lw	a5,0(a0)
    80004a4a:	4705                	li	a4,1
    80004a4c:	02e78263          	beq	a5,a4,80004a70 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a50:	470d                	li	a4,3
    80004a52:	02e78663          	beq	a5,a4,80004a7e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a56:	4709                	li	a4,2
    80004a58:	0ee79163          	bne	a5,a4,80004b3a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a5c:	0ac05d63          	blez	a2,80004b16 <filewrite+0xf4>
    int i = 0;
    80004a60:	4981                	li	s3,0
    80004a62:	6b05                	lui	s6,0x1
    80004a64:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a68:	6b85                	lui	s7,0x1
    80004a6a:	c00b8b9b          	addiw	s7,s7,-1024
    80004a6e:	a861                	j	80004b06 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a70:	6908                	ld	a0,16(a0)
    80004a72:	00000097          	auipc	ra,0x0
    80004a76:	22e080e7          	jalr	558(ra) # 80004ca0 <pipewrite>
    80004a7a:	8a2a                	mv	s4,a0
    80004a7c:	a045                	j	80004b1c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a7e:	02451783          	lh	a5,36(a0)
    80004a82:	03079693          	slli	a3,a5,0x30
    80004a86:	92c1                	srli	a3,a3,0x30
    80004a88:	4725                	li	a4,9
    80004a8a:	0cd76263          	bltu	a4,a3,80004b4e <filewrite+0x12c>
    80004a8e:	0792                	slli	a5,a5,0x4
    80004a90:	0001d717          	auipc	a4,0x1d
    80004a94:	a8870713          	addi	a4,a4,-1400 # 80021518 <devsw>
    80004a98:	97ba                	add	a5,a5,a4
    80004a9a:	679c                	ld	a5,8(a5)
    80004a9c:	cbdd                	beqz	a5,80004b52 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a9e:	4505                	li	a0,1
    80004aa0:	9782                	jalr	a5
    80004aa2:	8a2a                	mv	s4,a0
    80004aa4:	a8a5                	j	80004b1c <filewrite+0xfa>
    80004aa6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004aaa:	00000097          	auipc	ra,0x0
    80004aae:	8b0080e7          	jalr	-1872(ra) # 8000435a <begin_op>
      ilock(f->ip);
    80004ab2:	01893503          	ld	a0,24(s2)
    80004ab6:	fffff097          	auipc	ra,0xfffff
    80004aba:	ed2080e7          	jalr	-302(ra) # 80003988 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004abe:	8762                	mv	a4,s8
    80004ac0:	02092683          	lw	a3,32(s2)
    80004ac4:	01598633          	add	a2,s3,s5
    80004ac8:	4585                	li	a1,1
    80004aca:	01893503          	ld	a0,24(s2)
    80004ace:	fffff097          	auipc	ra,0xfffff
    80004ad2:	266080e7          	jalr	614(ra) # 80003d34 <writei>
    80004ad6:	84aa                	mv	s1,a0
    80004ad8:	00a05763          	blez	a0,80004ae6 <filewrite+0xc4>
        f->off += r;
    80004adc:	02092783          	lw	a5,32(s2)
    80004ae0:	9fa9                	addw	a5,a5,a0
    80004ae2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ae6:	01893503          	ld	a0,24(s2)
    80004aea:	fffff097          	auipc	ra,0xfffff
    80004aee:	f60080e7          	jalr	-160(ra) # 80003a4a <iunlock>
      end_op();
    80004af2:	00000097          	auipc	ra,0x0
    80004af6:	8e8080e7          	jalr	-1816(ra) # 800043da <end_op>

      if(r != n1){
    80004afa:	009c1f63          	bne	s8,s1,80004b18 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004afe:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b02:	0149db63          	bge	s3,s4,80004b18 <filewrite+0xf6>
      int n1 = n - i;
    80004b06:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b0a:	84be                	mv	s1,a5
    80004b0c:	2781                	sext.w	a5,a5
    80004b0e:	f8fb5ce3          	bge	s6,a5,80004aa6 <filewrite+0x84>
    80004b12:	84de                	mv	s1,s7
    80004b14:	bf49                	j	80004aa6 <filewrite+0x84>
    int i = 0;
    80004b16:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b18:	013a1f63          	bne	s4,s3,80004b36 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b1c:	8552                	mv	a0,s4
    80004b1e:	60a6                	ld	ra,72(sp)
    80004b20:	6406                	ld	s0,64(sp)
    80004b22:	74e2                	ld	s1,56(sp)
    80004b24:	7942                	ld	s2,48(sp)
    80004b26:	79a2                	ld	s3,40(sp)
    80004b28:	7a02                	ld	s4,32(sp)
    80004b2a:	6ae2                	ld	s5,24(sp)
    80004b2c:	6b42                	ld	s6,16(sp)
    80004b2e:	6ba2                	ld	s7,8(sp)
    80004b30:	6c02                	ld	s8,0(sp)
    80004b32:	6161                	addi	sp,sp,80
    80004b34:	8082                	ret
    ret = (i == n ? n : -1);
    80004b36:	5a7d                	li	s4,-1
    80004b38:	b7d5                	j	80004b1c <filewrite+0xfa>
    panic("filewrite");
    80004b3a:	00004517          	auipc	a0,0x4
    80004b3e:	b9e50513          	addi	a0,a0,-1122 # 800086d8 <syscalls+0x278>
    80004b42:	ffffc097          	auipc	ra,0xffffc
    80004b46:	9fc080e7          	jalr	-1540(ra) # 8000053e <panic>
    return -1;
    80004b4a:	5a7d                	li	s4,-1
    80004b4c:	bfc1                	j	80004b1c <filewrite+0xfa>
      return -1;
    80004b4e:	5a7d                	li	s4,-1
    80004b50:	b7f1                	j	80004b1c <filewrite+0xfa>
    80004b52:	5a7d                	li	s4,-1
    80004b54:	b7e1                	j	80004b1c <filewrite+0xfa>

0000000080004b56 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b56:	7179                	addi	sp,sp,-48
    80004b58:	f406                	sd	ra,40(sp)
    80004b5a:	f022                	sd	s0,32(sp)
    80004b5c:	ec26                	sd	s1,24(sp)
    80004b5e:	e84a                	sd	s2,16(sp)
    80004b60:	e44e                	sd	s3,8(sp)
    80004b62:	e052                	sd	s4,0(sp)
    80004b64:	1800                	addi	s0,sp,48
    80004b66:	84aa                	mv	s1,a0
    80004b68:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b6a:	0005b023          	sd	zero,0(a1)
    80004b6e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b72:	00000097          	auipc	ra,0x0
    80004b76:	bf8080e7          	jalr	-1032(ra) # 8000476a <filealloc>
    80004b7a:	e088                	sd	a0,0(s1)
    80004b7c:	c551                	beqz	a0,80004c08 <pipealloc+0xb2>
    80004b7e:	00000097          	auipc	ra,0x0
    80004b82:	bec080e7          	jalr	-1044(ra) # 8000476a <filealloc>
    80004b86:	00aa3023          	sd	a0,0(s4)
    80004b8a:	c92d                	beqz	a0,80004bfc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b8c:	ffffc097          	auipc	ra,0xffffc
    80004b90:	f68080e7          	jalr	-152(ra) # 80000af4 <kalloc>
    80004b94:	892a                	mv	s2,a0
    80004b96:	c125                	beqz	a0,80004bf6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b98:	4985                	li	s3,1
    80004b9a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b9e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ba2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ba6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004baa:	00004597          	auipc	a1,0x4
    80004bae:	b3e58593          	addi	a1,a1,-1218 # 800086e8 <syscalls+0x288>
    80004bb2:	ffffc097          	auipc	ra,0xffffc
    80004bb6:	fa2080e7          	jalr	-94(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004bba:	609c                	ld	a5,0(s1)
    80004bbc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bc0:	609c                	ld	a5,0(s1)
    80004bc2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bc6:	609c                	ld	a5,0(s1)
    80004bc8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bcc:	609c                	ld	a5,0(s1)
    80004bce:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bd2:	000a3783          	ld	a5,0(s4)
    80004bd6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bda:	000a3783          	ld	a5,0(s4)
    80004bde:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004be2:	000a3783          	ld	a5,0(s4)
    80004be6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bea:	000a3783          	ld	a5,0(s4)
    80004bee:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bf2:	4501                	li	a0,0
    80004bf4:	a025                	j	80004c1c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bf6:	6088                	ld	a0,0(s1)
    80004bf8:	e501                	bnez	a0,80004c00 <pipealloc+0xaa>
    80004bfa:	a039                	j	80004c08 <pipealloc+0xb2>
    80004bfc:	6088                	ld	a0,0(s1)
    80004bfe:	c51d                	beqz	a0,80004c2c <pipealloc+0xd6>
    fileclose(*f0);
    80004c00:	00000097          	auipc	ra,0x0
    80004c04:	c26080e7          	jalr	-986(ra) # 80004826 <fileclose>
  if(*f1)
    80004c08:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c0c:	557d                	li	a0,-1
  if(*f1)
    80004c0e:	c799                	beqz	a5,80004c1c <pipealloc+0xc6>
    fileclose(*f1);
    80004c10:	853e                	mv	a0,a5
    80004c12:	00000097          	auipc	ra,0x0
    80004c16:	c14080e7          	jalr	-1004(ra) # 80004826 <fileclose>
  return -1;
    80004c1a:	557d                	li	a0,-1
}
    80004c1c:	70a2                	ld	ra,40(sp)
    80004c1e:	7402                	ld	s0,32(sp)
    80004c20:	64e2                	ld	s1,24(sp)
    80004c22:	6942                	ld	s2,16(sp)
    80004c24:	69a2                	ld	s3,8(sp)
    80004c26:	6a02                	ld	s4,0(sp)
    80004c28:	6145                	addi	sp,sp,48
    80004c2a:	8082                	ret
  return -1;
    80004c2c:	557d                	li	a0,-1
    80004c2e:	b7fd                	j	80004c1c <pipealloc+0xc6>

0000000080004c30 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c30:	1101                	addi	sp,sp,-32
    80004c32:	ec06                	sd	ra,24(sp)
    80004c34:	e822                	sd	s0,16(sp)
    80004c36:	e426                	sd	s1,8(sp)
    80004c38:	e04a                	sd	s2,0(sp)
    80004c3a:	1000                	addi	s0,sp,32
    80004c3c:	84aa                	mv	s1,a0
    80004c3e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	fa4080e7          	jalr	-92(ra) # 80000be4 <acquire>
  if(writable){
    80004c48:	02090d63          	beqz	s2,80004c82 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c4c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c50:	21848513          	addi	a0,s1,536
    80004c54:	ffffe097          	auipc	ra,0xffffe
    80004c58:	856080e7          	jalr	-1962(ra) # 800024aa <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c5c:	2204b783          	ld	a5,544(s1)
    80004c60:	eb95                	bnez	a5,80004c94 <pipeclose+0x64>
    release(&pi->lock);
    80004c62:	8526                	mv	a0,s1
    80004c64:	ffffc097          	auipc	ra,0xffffc
    80004c68:	034080e7          	jalr	52(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004c6c:	8526                	mv	a0,s1
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	d8a080e7          	jalr	-630(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004c76:	60e2                	ld	ra,24(sp)
    80004c78:	6442                	ld	s0,16(sp)
    80004c7a:	64a2                	ld	s1,8(sp)
    80004c7c:	6902                	ld	s2,0(sp)
    80004c7e:	6105                	addi	sp,sp,32
    80004c80:	8082                	ret
    pi->readopen = 0;
    80004c82:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c86:	21c48513          	addi	a0,s1,540
    80004c8a:	ffffe097          	auipc	ra,0xffffe
    80004c8e:	820080e7          	jalr	-2016(ra) # 800024aa <wakeup>
    80004c92:	b7e9                	j	80004c5c <pipeclose+0x2c>
    release(&pi->lock);
    80004c94:	8526                	mv	a0,s1
    80004c96:	ffffc097          	auipc	ra,0xffffc
    80004c9a:	002080e7          	jalr	2(ra) # 80000c98 <release>
}
    80004c9e:	bfe1                	j	80004c76 <pipeclose+0x46>

0000000080004ca0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ca0:	7159                	addi	sp,sp,-112
    80004ca2:	f486                	sd	ra,104(sp)
    80004ca4:	f0a2                	sd	s0,96(sp)
    80004ca6:	eca6                	sd	s1,88(sp)
    80004ca8:	e8ca                	sd	s2,80(sp)
    80004caa:	e4ce                	sd	s3,72(sp)
    80004cac:	e0d2                	sd	s4,64(sp)
    80004cae:	fc56                	sd	s5,56(sp)
    80004cb0:	f85a                	sd	s6,48(sp)
    80004cb2:	f45e                	sd	s7,40(sp)
    80004cb4:	f062                	sd	s8,32(sp)
    80004cb6:	ec66                	sd	s9,24(sp)
    80004cb8:	1880                	addi	s0,sp,112
    80004cba:	84aa                	mv	s1,a0
    80004cbc:	8aae                	mv	s5,a1
    80004cbe:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004cc0:	ffffd097          	auipc	ra,0xffffd
    80004cc4:	d0e080e7          	jalr	-754(ra) # 800019ce <myproc>
    80004cc8:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004cca:	8526                	mv	a0,s1
    80004ccc:	ffffc097          	auipc	ra,0xffffc
    80004cd0:	f18080e7          	jalr	-232(ra) # 80000be4 <acquire>
  while(i < n){
    80004cd4:	0d405163          	blez	s4,80004d96 <pipewrite+0xf6>
    80004cd8:	8ba6                	mv	s7,s1
  int i = 0;
    80004cda:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cdc:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004cde:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ce2:	21c48c13          	addi	s8,s1,540
    80004ce6:	a08d                	j	80004d48 <pipewrite+0xa8>
      release(&pi->lock);
    80004ce8:	8526                	mv	a0,s1
    80004cea:	ffffc097          	auipc	ra,0xffffc
    80004cee:	fae080e7          	jalr	-82(ra) # 80000c98 <release>
      return -1;
    80004cf2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004cf4:	854a                	mv	a0,s2
    80004cf6:	70a6                	ld	ra,104(sp)
    80004cf8:	7406                	ld	s0,96(sp)
    80004cfa:	64e6                	ld	s1,88(sp)
    80004cfc:	6946                	ld	s2,80(sp)
    80004cfe:	69a6                	ld	s3,72(sp)
    80004d00:	6a06                	ld	s4,64(sp)
    80004d02:	7ae2                	ld	s5,56(sp)
    80004d04:	7b42                	ld	s6,48(sp)
    80004d06:	7ba2                	ld	s7,40(sp)
    80004d08:	7c02                	ld	s8,32(sp)
    80004d0a:	6ce2                	ld	s9,24(sp)
    80004d0c:	6165                	addi	sp,sp,112
    80004d0e:	8082                	ret
      wakeup(&pi->nread);
    80004d10:	8566                	mv	a0,s9
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	798080e7          	jalr	1944(ra) # 800024aa <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d1a:	85de                	mv	a1,s7
    80004d1c:	8562                	mv	a0,s8
    80004d1e:	ffffd097          	auipc	ra,0xffffd
    80004d22:	600080e7          	jalr	1536(ra) # 8000231e <sleep>
    80004d26:	a839                	j	80004d44 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d28:	21c4a783          	lw	a5,540(s1)
    80004d2c:	0017871b          	addiw	a4,a5,1
    80004d30:	20e4ae23          	sw	a4,540(s1)
    80004d34:	1ff7f793          	andi	a5,a5,511
    80004d38:	97a6                	add	a5,a5,s1
    80004d3a:	f9f44703          	lbu	a4,-97(s0)
    80004d3e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d42:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d44:	03495d63          	bge	s2,s4,80004d7e <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004d48:	2204a783          	lw	a5,544(s1)
    80004d4c:	dfd1                	beqz	a5,80004ce8 <pipewrite+0x48>
    80004d4e:	0289a783          	lw	a5,40(s3)
    80004d52:	fbd9                	bnez	a5,80004ce8 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d54:	2184a783          	lw	a5,536(s1)
    80004d58:	21c4a703          	lw	a4,540(s1)
    80004d5c:	2007879b          	addiw	a5,a5,512
    80004d60:	faf708e3          	beq	a4,a5,80004d10 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d64:	4685                	li	a3,1
    80004d66:	01590633          	add	a2,s2,s5
    80004d6a:	f9f40593          	addi	a1,s0,-97
    80004d6e:	0589b503          	ld	a0,88(s3)
    80004d72:	ffffd097          	auipc	ra,0xffffd
    80004d76:	994080e7          	jalr	-1644(ra) # 80001706 <copyin>
    80004d7a:	fb6517e3          	bne	a0,s6,80004d28 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d7e:	21848513          	addi	a0,s1,536
    80004d82:	ffffd097          	auipc	ra,0xffffd
    80004d86:	728080e7          	jalr	1832(ra) # 800024aa <wakeup>
  release(&pi->lock);
    80004d8a:	8526                	mv	a0,s1
    80004d8c:	ffffc097          	auipc	ra,0xffffc
    80004d90:	f0c080e7          	jalr	-244(ra) # 80000c98 <release>
  return i;
    80004d94:	b785                	j	80004cf4 <pipewrite+0x54>
  int i = 0;
    80004d96:	4901                	li	s2,0
    80004d98:	b7dd                	j	80004d7e <pipewrite+0xde>

0000000080004d9a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d9a:	715d                	addi	sp,sp,-80
    80004d9c:	e486                	sd	ra,72(sp)
    80004d9e:	e0a2                	sd	s0,64(sp)
    80004da0:	fc26                	sd	s1,56(sp)
    80004da2:	f84a                	sd	s2,48(sp)
    80004da4:	f44e                	sd	s3,40(sp)
    80004da6:	f052                	sd	s4,32(sp)
    80004da8:	ec56                	sd	s5,24(sp)
    80004daa:	e85a                	sd	s6,16(sp)
    80004dac:	0880                	addi	s0,sp,80
    80004dae:	84aa                	mv	s1,a0
    80004db0:	892e                	mv	s2,a1
    80004db2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004db4:	ffffd097          	auipc	ra,0xffffd
    80004db8:	c1a080e7          	jalr	-998(ra) # 800019ce <myproc>
    80004dbc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004dbe:	8b26                	mv	s6,s1
    80004dc0:	8526                	mv	a0,s1
    80004dc2:	ffffc097          	auipc	ra,0xffffc
    80004dc6:	e22080e7          	jalr	-478(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dca:	2184a703          	lw	a4,536(s1)
    80004dce:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dd2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dd6:	02f71463          	bne	a4,a5,80004dfe <piperead+0x64>
    80004dda:	2244a783          	lw	a5,548(s1)
    80004dde:	c385                	beqz	a5,80004dfe <piperead+0x64>
    if(pr->killed){
    80004de0:	028a2783          	lw	a5,40(s4)
    80004de4:	ebc1                	bnez	a5,80004e74 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004de6:	85da                	mv	a1,s6
    80004de8:	854e                	mv	a0,s3
    80004dea:	ffffd097          	auipc	ra,0xffffd
    80004dee:	534080e7          	jalr	1332(ra) # 8000231e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004df2:	2184a703          	lw	a4,536(s1)
    80004df6:	21c4a783          	lw	a5,540(s1)
    80004dfa:	fef700e3          	beq	a4,a5,80004dda <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dfe:	09505263          	blez	s5,80004e82 <piperead+0xe8>
    80004e02:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e04:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004e06:	2184a783          	lw	a5,536(s1)
    80004e0a:	21c4a703          	lw	a4,540(s1)
    80004e0e:	02f70d63          	beq	a4,a5,80004e48 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e12:	0017871b          	addiw	a4,a5,1
    80004e16:	20e4ac23          	sw	a4,536(s1)
    80004e1a:	1ff7f793          	andi	a5,a5,511
    80004e1e:	97a6                	add	a5,a5,s1
    80004e20:	0187c783          	lbu	a5,24(a5)
    80004e24:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e28:	4685                	li	a3,1
    80004e2a:	fbf40613          	addi	a2,s0,-65
    80004e2e:	85ca                	mv	a1,s2
    80004e30:	058a3503          	ld	a0,88(s4)
    80004e34:	ffffd097          	auipc	ra,0xffffd
    80004e38:	846080e7          	jalr	-1978(ra) # 8000167a <copyout>
    80004e3c:	01650663          	beq	a0,s6,80004e48 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e40:	2985                	addiw	s3,s3,1
    80004e42:	0905                	addi	s2,s2,1
    80004e44:	fd3a91e3          	bne	s5,s3,80004e06 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e48:	21c48513          	addi	a0,s1,540
    80004e4c:	ffffd097          	auipc	ra,0xffffd
    80004e50:	65e080e7          	jalr	1630(ra) # 800024aa <wakeup>
  release(&pi->lock);
    80004e54:	8526                	mv	a0,s1
    80004e56:	ffffc097          	auipc	ra,0xffffc
    80004e5a:	e42080e7          	jalr	-446(ra) # 80000c98 <release>
  return i;
}
    80004e5e:	854e                	mv	a0,s3
    80004e60:	60a6                	ld	ra,72(sp)
    80004e62:	6406                	ld	s0,64(sp)
    80004e64:	74e2                	ld	s1,56(sp)
    80004e66:	7942                	ld	s2,48(sp)
    80004e68:	79a2                	ld	s3,40(sp)
    80004e6a:	7a02                	ld	s4,32(sp)
    80004e6c:	6ae2                	ld	s5,24(sp)
    80004e6e:	6b42                	ld	s6,16(sp)
    80004e70:	6161                	addi	sp,sp,80
    80004e72:	8082                	ret
      release(&pi->lock);
    80004e74:	8526                	mv	a0,s1
    80004e76:	ffffc097          	auipc	ra,0xffffc
    80004e7a:	e22080e7          	jalr	-478(ra) # 80000c98 <release>
      return -1;
    80004e7e:	59fd                	li	s3,-1
    80004e80:	bff9                	j	80004e5e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e82:	4981                	li	s3,0
    80004e84:	b7d1                	j	80004e48 <piperead+0xae>

0000000080004e86 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e86:	df010113          	addi	sp,sp,-528
    80004e8a:	20113423          	sd	ra,520(sp)
    80004e8e:	20813023          	sd	s0,512(sp)
    80004e92:	ffa6                	sd	s1,504(sp)
    80004e94:	fbca                	sd	s2,496(sp)
    80004e96:	f7ce                	sd	s3,488(sp)
    80004e98:	f3d2                	sd	s4,480(sp)
    80004e9a:	efd6                	sd	s5,472(sp)
    80004e9c:	ebda                	sd	s6,464(sp)
    80004e9e:	e7de                	sd	s7,456(sp)
    80004ea0:	e3e2                	sd	s8,448(sp)
    80004ea2:	ff66                	sd	s9,440(sp)
    80004ea4:	fb6a                	sd	s10,432(sp)
    80004ea6:	f76e                	sd	s11,424(sp)
    80004ea8:	0c00                	addi	s0,sp,528
    80004eaa:	84aa                	mv	s1,a0
    80004eac:	dea43c23          	sd	a0,-520(s0)
    80004eb0:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004eb4:	ffffd097          	auipc	ra,0xffffd
    80004eb8:	b1a080e7          	jalr	-1254(ra) # 800019ce <myproc>
    80004ebc:	892a                	mv	s2,a0

  begin_op();
    80004ebe:	fffff097          	auipc	ra,0xfffff
    80004ec2:	49c080e7          	jalr	1180(ra) # 8000435a <begin_op>

  if((ip = namei(path)) == 0){
    80004ec6:	8526                	mv	a0,s1
    80004ec8:	fffff097          	auipc	ra,0xfffff
    80004ecc:	276080e7          	jalr	630(ra) # 8000413e <namei>
    80004ed0:	c92d                	beqz	a0,80004f42 <exec+0xbc>
    80004ed2:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ed4:	fffff097          	auipc	ra,0xfffff
    80004ed8:	ab4080e7          	jalr	-1356(ra) # 80003988 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004edc:	04000713          	li	a4,64
    80004ee0:	4681                	li	a3,0
    80004ee2:	e5040613          	addi	a2,s0,-432
    80004ee6:	4581                	li	a1,0
    80004ee8:	8526                	mv	a0,s1
    80004eea:	fffff097          	auipc	ra,0xfffff
    80004eee:	d52080e7          	jalr	-686(ra) # 80003c3c <readi>
    80004ef2:	04000793          	li	a5,64
    80004ef6:	00f51a63          	bne	a0,a5,80004f0a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004efa:	e5042703          	lw	a4,-432(s0)
    80004efe:	464c47b7          	lui	a5,0x464c4
    80004f02:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f06:	04f70463          	beq	a4,a5,80004f4e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f0a:	8526                	mv	a0,s1
    80004f0c:	fffff097          	auipc	ra,0xfffff
    80004f10:	cde080e7          	jalr	-802(ra) # 80003bea <iunlockput>
    end_op();
    80004f14:	fffff097          	auipc	ra,0xfffff
    80004f18:	4c6080e7          	jalr	1222(ra) # 800043da <end_op>
  }
  return -1;
    80004f1c:	557d                	li	a0,-1
}
    80004f1e:	20813083          	ld	ra,520(sp)
    80004f22:	20013403          	ld	s0,512(sp)
    80004f26:	74fe                	ld	s1,504(sp)
    80004f28:	795e                	ld	s2,496(sp)
    80004f2a:	79be                	ld	s3,488(sp)
    80004f2c:	7a1e                	ld	s4,480(sp)
    80004f2e:	6afe                	ld	s5,472(sp)
    80004f30:	6b5e                	ld	s6,464(sp)
    80004f32:	6bbe                	ld	s7,456(sp)
    80004f34:	6c1e                	ld	s8,448(sp)
    80004f36:	7cfa                	ld	s9,440(sp)
    80004f38:	7d5a                	ld	s10,432(sp)
    80004f3a:	7dba                	ld	s11,424(sp)
    80004f3c:	21010113          	addi	sp,sp,528
    80004f40:	8082                	ret
    end_op();
    80004f42:	fffff097          	auipc	ra,0xfffff
    80004f46:	498080e7          	jalr	1176(ra) # 800043da <end_op>
    return -1;
    80004f4a:	557d                	li	a0,-1
    80004f4c:	bfc9                	j	80004f1e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f4e:	854a                	mv	a0,s2
    80004f50:	ffffd097          	auipc	ra,0xffffd
    80004f54:	b42080e7          	jalr	-1214(ra) # 80001a92 <proc_pagetable>
    80004f58:	8baa                	mv	s7,a0
    80004f5a:	d945                	beqz	a0,80004f0a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f5c:	e7042983          	lw	s3,-400(s0)
    80004f60:	e8845783          	lhu	a5,-376(s0)
    80004f64:	c7ad                	beqz	a5,80004fce <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f66:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f68:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004f6a:	6c85                	lui	s9,0x1
    80004f6c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f70:	def43823          	sd	a5,-528(s0)
    80004f74:	a42d                	j	8000519e <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f76:	00003517          	auipc	a0,0x3
    80004f7a:	77a50513          	addi	a0,a0,1914 # 800086f0 <syscalls+0x290>
    80004f7e:	ffffb097          	auipc	ra,0xffffb
    80004f82:	5c0080e7          	jalr	1472(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f86:	8756                	mv	a4,s5
    80004f88:	012d86bb          	addw	a3,s11,s2
    80004f8c:	4581                	li	a1,0
    80004f8e:	8526                	mv	a0,s1
    80004f90:	fffff097          	auipc	ra,0xfffff
    80004f94:	cac080e7          	jalr	-852(ra) # 80003c3c <readi>
    80004f98:	2501                	sext.w	a0,a0
    80004f9a:	1aaa9963          	bne	s5,a0,8000514c <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f9e:	6785                	lui	a5,0x1
    80004fa0:	0127893b          	addw	s2,a5,s2
    80004fa4:	77fd                	lui	a5,0xfffff
    80004fa6:	01478a3b          	addw	s4,a5,s4
    80004faa:	1f897163          	bgeu	s2,s8,8000518c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004fae:	02091593          	slli	a1,s2,0x20
    80004fb2:	9181                	srli	a1,a1,0x20
    80004fb4:	95ea                	add	a1,a1,s10
    80004fb6:	855e                	mv	a0,s7
    80004fb8:	ffffc097          	auipc	ra,0xffffc
    80004fbc:	0be080e7          	jalr	190(ra) # 80001076 <walkaddr>
    80004fc0:	862a                	mv	a2,a0
    if(pa == 0)
    80004fc2:	d955                	beqz	a0,80004f76 <exec+0xf0>
      n = PGSIZE;
    80004fc4:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004fc6:	fd9a70e3          	bgeu	s4,s9,80004f86 <exec+0x100>
      n = sz - i;
    80004fca:	8ad2                	mv	s5,s4
    80004fcc:	bf6d                	j	80004f86 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fce:	4901                	li	s2,0
  iunlockput(ip);
    80004fd0:	8526                	mv	a0,s1
    80004fd2:	fffff097          	auipc	ra,0xfffff
    80004fd6:	c18080e7          	jalr	-1000(ra) # 80003bea <iunlockput>
  end_op();
    80004fda:	fffff097          	auipc	ra,0xfffff
    80004fde:	400080e7          	jalr	1024(ra) # 800043da <end_op>
  p = myproc();
    80004fe2:	ffffd097          	auipc	ra,0xffffd
    80004fe6:	9ec080e7          	jalr	-1556(ra) # 800019ce <myproc>
    80004fea:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fec:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80004ff0:	6785                	lui	a5,0x1
    80004ff2:	17fd                	addi	a5,a5,-1
    80004ff4:	993e                	add	s2,s2,a5
    80004ff6:	757d                	lui	a0,0xfffff
    80004ff8:	00a977b3          	and	a5,s2,a0
    80004ffc:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005000:	6609                	lui	a2,0x2
    80005002:	963e                	add	a2,a2,a5
    80005004:	85be                	mv	a1,a5
    80005006:	855e                	mv	a0,s7
    80005008:	ffffc097          	auipc	ra,0xffffc
    8000500c:	422080e7          	jalr	1058(ra) # 8000142a <uvmalloc>
    80005010:	8b2a                	mv	s6,a0
  ip = 0;
    80005012:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005014:	12050c63          	beqz	a0,8000514c <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005018:	75f9                	lui	a1,0xffffe
    8000501a:	95aa                	add	a1,a1,a0
    8000501c:	855e                	mv	a0,s7
    8000501e:	ffffc097          	auipc	ra,0xffffc
    80005022:	62a080e7          	jalr	1578(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80005026:	7c7d                	lui	s8,0xfffff
    80005028:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000502a:	e0043783          	ld	a5,-512(s0)
    8000502e:	6388                	ld	a0,0(a5)
    80005030:	c535                	beqz	a0,8000509c <exec+0x216>
    80005032:	e9040993          	addi	s3,s0,-368
    80005036:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000503a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000503c:	ffffc097          	auipc	ra,0xffffc
    80005040:	e28080e7          	jalr	-472(ra) # 80000e64 <strlen>
    80005044:	2505                	addiw	a0,a0,1
    80005046:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000504a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000504e:	13896363          	bltu	s2,s8,80005174 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005052:	e0043d83          	ld	s11,-512(s0)
    80005056:	000dba03          	ld	s4,0(s11)
    8000505a:	8552                	mv	a0,s4
    8000505c:	ffffc097          	auipc	ra,0xffffc
    80005060:	e08080e7          	jalr	-504(ra) # 80000e64 <strlen>
    80005064:	0015069b          	addiw	a3,a0,1
    80005068:	8652                	mv	a2,s4
    8000506a:	85ca                	mv	a1,s2
    8000506c:	855e                	mv	a0,s7
    8000506e:	ffffc097          	auipc	ra,0xffffc
    80005072:	60c080e7          	jalr	1548(ra) # 8000167a <copyout>
    80005076:	10054363          	bltz	a0,8000517c <exec+0x2f6>
    ustack[argc] = sp;
    8000507a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000507e:	0485                	addi	s1,s1,1
    80005080:	008d8793          	addi	a5,s11,8
    80005084:	e0f43023          	sd	a5,-512(s0)
    80005088:	008db503          	ld	a0,8(s11)
    8000508c:	c911                	beqz	a0,800050a0 <exec+0x21a>
    if(argc >= MAXARG)
    8000508e:	09a1                	addi	s3,s3,8
    80005090:	fb3c96e3          	bne	s9,s3,8000503c <exec+0x1b6>
  sz = sz1;
    80005094:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005098:	4481                	li	s1,0
    8000509a:	a84d                	j	8000514c <exec+0x2c6>
  sp = sz;
    8000509c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000509e:	4481                	li	s1,0
  ustack[argc] = 0;
    800050a0:	00349793          	slli	a5,s1,0x3
    800050a4:	f9040713          	addi	a4,s0,-112
    800050a8:	97ba                	add	a5,a5,a4
    800050aa:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800050ae:	00148693          	addi	a3,s1,1
    800050b2:	068e                	slli	a3,a3,0x3
    800050b4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050b8:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050bc:	01897663          	bgeu	s2,s8,800050c8 <exec+0x242>
  sz = sz1;
    800050c0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050c4:	4481                	li	s1,0
    800050c6:	a059                	j	8000514c <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050c8:	e9040613          	addi	a2,s0,-368
    800050cc:	85ca                	mv	a1,s2
    800050ce:	855e                	mv	a0,s7
    800050d0:	ffffc097          	auipc	ra,0xffffc
    800050d4:	5aa080e7          	jalr	1450(ra) # 8000167a <copyout>
    800050d8:	0a054663          	bltz	a0,80005184 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800050dc:	060ab783          	ld	a5,96(s5)
    800050e0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050e4:	df843783          	ld	a5,-520(s0)
    800050e8:	0007c703          	lbu	a4,0(a5)
    800050ec:	cf11                	beqz	a4,80005108 <exec+0x282>
    800050ee:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050f0:	02f00693          	li	a3,47
    800050f4:	a039                	j	80005102 <exec+0x27c>
      last = s+1;
    800050f6:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800050fa:	0785                	addi	a5,a5,1
    800050fc:	fff7c703          	lbu	a4,-1(a5)
    80005100:	c701                	beqz	a4,80005108 <exec+0x282>
    if(*s == '/')
    80005102:	fed71ce3          	bne	a4,a3,800050fa <exec+0x274>
    80005106:	bfc5                	j	800050f6 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005108:	4641                	li	a2,16
    8000510a:	df843583          	ld	a1,-520(s0)
    8000510e:	160a8513          	addi	a0,s5,352
    80005112:	ffffc097          	auipc	ra,0xffffc
    80005116:	d20080e7          	jalr	-736(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000511a:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    8000511e:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    80005122:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005126:	060ab783          	ld	a5,96(s5)
    8000512a:	e6843703          	ld	a4,-408(s0)
    8000512e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005130:	060ab783          	ld	a5,96(s5)
    80005134:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005138:	85ea                	mv	a1,s10
    8000513a:	ffffd097          	auipc	ra,0xffffd
    8000513e:	9f4080e7          	jalr	-1548(ra) # 80001b2e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005142:	0004851b          	sext.w	a0,s1
    80005146:	bbe1                	j	80004f1e <exec+0x98>
    80005148:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000514c:	e0843583          	ld	a1,-504(s0)
    80005150:	855e                	mv	a0,s7
    80005152:	ffffd097          	auipc	ra,0xffffd
    80005156:	9dc080e7          	jalr	-1572(ra) # 80001b2e <proc_freepagetable>
  if(ip){
    8000515a:	da0498e3          	bnez	s1,80004f0a <exec+0x84>
  return -1;
    8000515e:	557d                	li	a0,-1
    80005160:	bb7d                	j	80004f1e <exec+0x98>
    80005162:	e1243423          	sd	s2,-504(s0)
    80005166:	b7dd                	j	8000514c <exec+0x2c6>
    80005168:	e1243423          	sd	s2,-504(s0)
    8000516c:	b7c5                	j	8000514c <exec+0x2c6>
    8000516e:	e1243423          	sd	s2,-504(s0)
    80005172:	bfe9                	j	8000514c <exec+0x2c6>
  sz = sz1;
    80005174:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005178:	4481                	li	s1,0
    8000517a:	bfc9                	j	8000514c <exec+0x2c6>
  sz = sz1;
    8000517c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005180:	4481                	li	s1,0
    80005182:	b7e9                	j	8000514c <exec+0x2c6>
  sz = sz1;
    80005184:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005188:	4481                	li	s1,0
    8000518a:	b7c9                	j	8000514c <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000518c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005190:	2b05                	addiw	s6,s6,1
    80005192:	0389899b          	addiw	s3,s3,56
    80005196:	e8845783          	lhu	a5,-376(s0)
    8000519a:	e2fb5be3          	bge	s6,a5,80004fd0 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000519e:	2981                	sext.w	s3,s3
    800051a0:	03800713          	li	a4,56
    800051a4:	86ce                	mv	a3,s3
    800051a6:	e1840613          	addi	a2,s0,-488
    800051aa:	4581                	li	a1,0
    800051ac:	8526                	mv	a0,s1
    800051ae:	fffff097          	auipc	ra,0xfffff
    800051b2:	a8e080e7          	jalr	-1394(ra) # 80003c3c <readi>
    800051b6:	03800793          	li	a5,56
    800051ba:	f8f517e3          	bne	a0,a5,80005148 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800051be:	e1842783          	lw	a5,-488(s0)
    800051c2:	4705                	li	a4,1
    800051c4:	fce796e3          	bne	a5,a4,80005190 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800051c8:	e4043603          	ld	a2,-448(s0)
    800051cc:	e3843783          	ld	a5,-456(s0)
    800051d0:	f8f669e3          	bltu	a2,a5,80005162 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051d4:	e2843783          	ld	a5,-472(s0)
    800051d8:	963e                	add	a2,a2,a5
    800051da:	f8f667e3          	bltu	a2,a5,80005168 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051de:	85ca                	mv	a1,s2
    800051e0:	855e                	mv	a0,s7
    800051e2:	ffffc097          	auipc	ra,0xffffc
    800051e6:	248080e7          	jalr	584(ra) # 8000142a <uvmalloc>
    800051ea:	e0a43423          	sd	a0,-504(s0)
    800051ee:	d141                	beqz	a0,8000516e <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800051f0:	e2843d03          	ld	s10,-472(s0)
    800051f4:	df043783          	ld	a5,-528(s0)
    800051f8:	00fd77b3          	and	a5,s10,a5
    800051fc:	fba1                	bnez	a5,8000514c <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051fe:	e2042d83          	lw	s11,-480(s0)
    80005202:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005206:	f80c03e3          	beqz	s8,8000518c <exec+0x306>
    8000520a:	8a62                	mv	s4,s8
    8000520c:	4901                	li	s2,0
    8000520e:	b345                	j	80004fae <exec+0x128>

0000000080005210 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005210:	7179                	addi	sp,sp,-48
    80005212:	f406                	sd	ra,40(sp)
    80005214:	f022                	sd	s0,32(sp)
    80005216:	ec26                	sd	s1,24(sp)
    80005218:	e84a                	sd	s2,16(sp)
    8000521a:	1800                	addi	s0,sp,48
    8000521c:	892e                	mv	s2,a1
    8000521e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005220:	fdc40593          	addi	a1,s0,-36
    80005224:	ffffe097          	auipc	ra,0xffffe
    80005228:	ba6080e7          	jalr	-1114(ra) # 80002dca <argint>
    8000522c:	04054063          	bltz	a0,8000526c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005230:	fdc42703          	lw	a4,-36(s0)
    80005234:	47bd                	li	a5,15
    80005236:	02e7ed63          	bltu	a5,a4,80005270 <argfd+0x60>
    8000523a:	ffffc097          	auipc	ra,0xffffc
    8000523e:	794080e7          	jalr	1940(ra) # 800019ce <myproc>
    80005242:	fdc42703          	lw	a4,-36(s0)
    80005246:	01a70793          	addi	a5,a4,26
    8000524a:	078e                	slli	a5,a5,0x3
    8000524c:	953e                	add	a0,a0,a5
    8000524e:	651c                	ld	a5,8(a0)
    80005250:	c395                	beqz	a5,80005274 <argfd+0x64>
    return -1;
  if(pfd)
    80005252:	00090463          	beqz	s2,8000525a <argfd+0x4a>
    *pfd = fd;
    80005256:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000525a:	4501                	li	a0,0
  if(pf)
    8000525c:	c091                	beqz	s1,80005260 <argfd+0x50>
    *pf = f;
    8000525e:	e09c                	sd	a5,0(s1)
}
    80005260:	70a2                	ld	ra,40(sp)
    80005262:	7402                	ld	s0,32(sp)
    80005264:	64e2                	ld	s1,24(sp)
    80005266:	6942                	ld	s2,16(sp)
    80005268:	6145                	addi	sp,sp,48
    8000526a:	8082                	ret
    return -1;
    8000526c:	557d                	li	a0,-1
    8000526e:	bfcd                	j	80005260 <argfd+0x50>
    return -1;
    80005270:	557d                	li	a0,-1
    80005272:	b7fd                	j	80005260 <argfd+0x50>
    80005274:	557d                	li	a0,-1
    80005276:	b7ed                	j	80005260 <argfd+0x50>

0000000080005278 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005278:	1101                	addi	sp,sp,-32
    8000527a:	ec06                	sd	ra,24(sp)
    8000527c:	e822                	sd	s0,16(sp)
    8000527e:	e426                	sd	s1,8(sp)
    80005280:	1000                	addi	s0,sp,32
    80005282:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005284:	ffffc097          	auipc	ra,0xffffc
    80005288:	74a080e7          	jalr	1866(ra) # 800019ce <myproc>
    8000528c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000528e:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffd90d8>
    80005292:	4501                	li	a0,0
    80005294:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005296:	6398                	ld	a4,0(a5)
    80005298:	cb19                	beqz	a4,800052ae <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000529a:	2505                	addiw	a0,a0,1
    8000529c:	07a1                	addi	a5,a5,8
    8000529e:	fed51ce3          	bne	a0,a3,80005296 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052a2:	557d                	li	a0,-1
}
    800052a4:	60e2                	ld	ra,24(sp)
    800052a6:	6442                	ld	s0,16(sp)
    800052a8:	64a2                	ld	s1,8(sp)
    800052aa:	6105                	addi	sp,sp,32
    800052ac:	8082                	ret
      p->ofile[fd] = f;
    800052ae:	01a50793          	addi	a5,a0,26
    800052b2:	078e                	slli	a5,a5,0x3
    800052b4:	963e                	add	a2,a2,a5
    800052b6:	e604                	sd	s1,8(a2)
      return fd;
    800052b8:	b7f5                	j	800052a4 <fdalloc+0x2c>

00000000800052ba <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052ba:	715d                	addi	sp,sp,-80
    800052bc:	e486                	sd	ra,72(sp)
    800052be:	e0a2                	sd	s0,64(sp)
    800052c0:	fc26                	sd	s1,56(sp)
    800052c2:	f84a                	sd	s2,48(sp)
    800052c4:	f44e                	sd	s3,40(sp)
    800052c6:	f052                	sd	s4,32(sp)
    800052c8:	ec56                	sd	s5,24(sp)
    800052ca:	0880                	addi	s0,sp,80
    800052cc:	89ae                	mv	s3,a1
    800052ce:	8ab2                	mv	s5,a2
    800052d0:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052d2:	fb040593          	addi	a1,s0,-80
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	e86080e7          	jalr	-378(ra) # 8000415c <nameiparent>
    800052de:	892a                	mv	s2,a0
    800052e0:	12050f63          	beqz	a0,8000541e <create+0x164>
    return 0;

  ilock(dp);
    800052e4:	ffffe097          	auipc	ra,0xffffe
    800052e8:	6a4080e7          	jalr	1700(ra) # 80003988 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052ec:	4601                	li	a2,0
    800052ee:	fb040593          	addi	a1,s0,-80
    800052f2:	854a                	mv	a0,s2
    800052f4:	fffff097          	auipc	ra,0xfffff
    800052f8:	b78080e7          	jalr	-1160(ra) # 80003e6c <dirlookup>
    800052fc:	84aa                	mv	s1,a0
    800052fe:	c921                	beqz	a0,8000534e <create+0x94>
    iunlockput(dp);
    80005300:	854a                	mv	a0,s2
    80005302:	fffff097          	auipc	ra,0xfffff
    80005306:	8e8080e7          	jalr	-1816(ra) # 80003bea <iunlockput>
    ilock(ip);
    8000530a:	8526                	mv	a0,s1
    8000530c:	ffffe097          	auipc	ra,0xffffe
    80005310:	67c080e7          	jalr	1660(ra) # 80003988 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005314:	2981                	sext.w	s3,s3
    80005316:	4789                	li	a5,2
    80005318:	02f99463          	bne	s3,a5,80005340 <create+0x86>
    8000531c:	0444d783          	lhu	a5,68(s1)
    80005320:	37f9                	addiw	a5,a5,-2
    80005322:	17c2                	slli	a5,a5,0x30
    80005324:	93c1                	srli	a5,a5,0x30
    80005326:	4705                	li	a4,1
    80005328:	00f76c63          	bltu	a4,a5,80005340 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000532c:	8526                	mv	a0,s1
    8000532e:	60a6                	ld	ra,72(sp)
    80005330:	6406                	ld	s0,64(sp)
    80005332:	74e2                	ld	s1,56(sp)
    80005334:	7942                	ld	s2,48(sp)
    80005336:	79a2                	ld	s3,40(sp)
    80005338:	7a02                	ld	s4,32(sp)
    8000533a:	6ae2                	ld	s5,24(sp)
    8000533c:	6161                	addi	sp,sp,80
    8000533e:	8082                	ret
    iunlockput(ip);
    80005340:	8526                	mv	a0,s1
    80005342:	fffff097          	auipc	ra,0xfffff
    80005346:	8a8080e7          	jalr	-1880(ra) # 80003bea <iunlockput>
    return 0;
    8000534a:	4481                	li	s1,0
    8000534c:	b7c5                	j	8000532c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000534e:	85ce                	mv	a1,s3
    80005350:	00092503          	lw	a0,0(s2)
    80005354:	ffffe097          	auipc	ra,0xffffe
    80005358:	49c080e7          	jalr	1180(ra) # 800037f0 <ialloc>
    8000535c:	84aa                	mv	s1,a0
    8000535e:	c529                	beqz	a0,800053a8 <create+0xee>
  ilock(ip);
    80005360:	ffffe097          	auipc	ra,0xffffe
    80005364:	628080e7          	jalr	1576(ra) # 80003988 <ilock>
  ip->major = major;
    80005368:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000536c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005370:	4785                	li	a5,1
    80005372:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005376:	8526                	mv	a0,s1
    80005378:	ffffe097          	auipc	ra,0xffffe
    8000537c:	546080e7          	jalr	1350(ra) # 800038be <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005380:	2981                	sext.w	s3,s3
    80005382:	4785                	li	a5,1
    80005384:	02f98a63          	beq	s3,a5,800053b8 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005388:	40d0                	lw	a2,4(s1)
    8000538a:	fb040593          	addi	a1,s0,-80
    8000538e:	854a                	mv	a0,s2
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	cec080e7          	jalr	-788(ra) # 8000407c <dirlink>
    80005398:	06054b63          	bltz	a0,8000540e <create+0x154>
  iunlockput(dp);
    8000539c:	854a                	mv	a0,s2
    8000539e:	fffff097          	auipc	ra,0xfffff
    800053a2:	84c080e7          	jalr	-1972(ra) # 80003bea <iunlockput>
  return ip;
    800053a6:	b759                	j	8000532c <create+0x72>
    panic("create: ialloc");
    800053a8:	00003517          	auipc	a0,0x3
    800053ac:	36850513          	addi	a0,a0,872 # 80008710 <syscalls+0x2b0>
    800053b0:	ffffb097          	auipc	ra,0xffffb
    800053b4:	18e080e7          	jalr	398(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800053b8:	04a95783          	lhu	a5,74(s2)
    800053bc:	2785                	addiw	a5,a5,1
    800053be:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053c2:	854a                	mv	a0,s2
    800053c4:	ffffe097          	auipc	ra,0xffffe
    800053c8:	4fa080e7          	jalr	1274(ra) # 800038be <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053cc:	40d0                	lw	a2,4(s1)
    800053ce:	00003597          	auipc	a1,0x3
    800053d2:	35258593          	addi	a1,a1,850 # 80008720 <syscalls+0x2c0>
    800053d6:	8526                	mv	a0,s1
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	ca4080e7          	jalr	-860(ra) # 8000407c <dirlink>
    800053e0:	00054f63          	bltz	a0,800053fe <create+0x144>
    800053e4:	00492603          	lw	a2,4(s2)
    800053e8:	00003597          	auipc	a1,0x3
    800053ec:	34058593          	addi	a1,a1,832 # 80008728 <syscalls+0x2c8>
    800053f0:	8526                	mv	a0,s1
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	c8a080e7          	jalr	-886(ra) # 8000407c <dirlink>
    800053fa:	f80557e3          	bgez	a0,80005388 <create+0xce>
      panic("create dots");
    800053fe:	00003517          	auipc	a0,0x3
    80005402:	33250513          	addi	a0,a0,818 # 80008730 <syscalls+0x2d0>
    80005406:	ffffb097          	auipc	ra,0xffffb
    8000540a:	138080e7          	jalr	312(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000540e:	00003517          	auipc	a0,0x3
    80005412:	33250513          	addi	a0,a0,818 # 80008740 <syscalls+0x2e0>
    80005416:	ffffb097          	auipc	ra,0xffffb
    8000541a:	128080e7          	jalr	296(ra) # 8000053e <panic>
    return 0;
    8000541e:	84aa                	mv	s1,a0
    80005420:	b731                	j	8000532c <create+0x72>

0000000080005422 <sys_dup>:
{
    80005422:	7179                	addi	sp,sp,-48
    80005424:	f406                	sd	ra,40(sp)
    80005426:	f022                	sd	s0,32(sp)
    80005428:	ec26                	sd	s1,24(sp)
    8000542a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000542c:	fd840613          	addi	a2,s0,-40
    80005430:	4581                	li	a1,0
    80005432:	4501                	li	a0,0
    80005434:	00000097          	auipc	ra,0x0
    80005438:	ddc080e7          	jalr	-548(ra) # 80005210 <argfd>
    return -1;
    8000543c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000543e:	02054363          	bltz	a0,80005464 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005442:	fd843503          	ld	a0,-40(s0)
    80005446:	00000097          	auipc	ra,0x0
    8000544a:	e32080e7          	jalr	-462(ra) # 80005278 <fdalloc>
    8000544e:	84aa                	mv	s1,a0
    return -1;
    80005450:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005452:	00054963          	bltz	a0,80005464 <sys_dup+0x42>
  filedup(f);
    80005456:	fd843503          	ld	a0,-40(s0)
    8000545a:	fffff097          	auipc	ra,0xfffff
    8000545e:	37a080e7          	jalr	890(ra) # 800047d4 <filedup>
  return fd;
    80005462:	87a6                	mv	a5,s1
}
    80005464:	853e                	mv	a0,a5
    80005466:	70a2                	ld	ra,40(sp)
    80005468:	7402                	ld	s0,32(sp)
    8000546a:	64e2                	ld	s1,24(sp)
    8000546c:	6145                	addi	sp,sp,48
    8000546e:	8082                	ret

0000000080005470 <sys_read>:
{
    80005470:	7179                	addi	sp,sp,-48
    80005472:	f406                	sd	ra,40(sp)
    80005474:	f022                	sd	s0,32(sp)
    80005476:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005478:	fe840613          	addi	a2,s0,-24
    8000547c:	4581                	li	a1,0
    8000547e:	4501                	li	a0,0
    80005480:	00000097          	auipc	ra,0x0
    80005484:	d90080e7          	jalr	-624(ra) # 80005210 <argfd>
    return -1;
    80005488:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000548a:	04054163          	bltz	a0,800054cc <sys_read+0x5c>
    8000548e:	fe440593          	addi	a1,s0,-28
    80005492:	4509                	li	a0,2
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	936080e7          	jalr	-1738(ra) # 80002dca <argint>
    return -1;
    8000549c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000549e:	02054763          	bltz	a0,800054cc <sys_read+0x5c>
    800054a2:	fd840593          	addi	a1,s0,-40
    800054a6:	4505                	li	a0,1
    800054a8:	ffffe097          	auipc	ra,0xffffe
    800054ac:	944080e7          	jalr	-1724(ra) # 80002dec <argaddr>
    return -1;
    800054b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b2:	00054d63          	bltz	a0,800054cc <sys_read+0x5c>
  return fileread(f, p, n);
    800054b6:	fe442603          	lw	a2,-28(s0)
    800054ba:	fd843583          	ld	a1,-40(s0)
    800054be:	fe843503          	ld	a0,-24(s0)
    800054c2:	fffff097          	auipc	ra,0xfffff
    800054c6:	49e080e7          	jalr	1182(ra) # 80004960 <fileread>
    800054ca:	87aa                	mv	a5,a0
}
    800054cc:	853e                	mv	a0,a5
    800054ce:	70a2                	ld	ra,40(sp)
    800054d0:	7402                	ld	s0,32(sp)
    800054d2:	6145                	addi	sp,sp,48
    800054d4:	8082                	ret

00000000800054d6 <sys_write>:
{
    800054d6:	7179                	addi	sp,sp,-48
    800054d8:	f406                	sd	ra,40(sp)
    800054da:	f022                	sd	s0,32(sp)
    800054dc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054de:	fe840613          	addi	a2,s0,-24
    800054e2:	4581                	li	a1,0
    800054e4:	4501                	li	a0,0
    800054e6:	00000097          	auipc	ra,0x0
    800054ea:	d2a080e7          	jalr	-726(ra) # 80005210 <argfd>
    return -1;
    800054ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054f0:	04054163          	bltz	a0,80005532 <sys_write+0x5c>
    800054f4:	fe440593          	addi	a1,s0,-28
    800054f8:	4509                	li	a0,2
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	8d0080e7          	jalr	-1840(ra) # 80002dca <argint>
    return -1;
    80005502:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005504:	02054763          	bltz	a0,80005532 <sys_write+0x5c>
    80005508:	fd840593          	addi	a1,s0,-40
    8000550c:	4505                	li	a0,1
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	8de080e7          	jalr	-1826(ra) # 80002dec <argaddr>
    return -1;
    80005516:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005518:	00054d63          	bltz	a0,80005532 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000551c:	fe442603          	lw	a2,-28(s0)
    80005520:	fd843583          	ld	a1,-40(s0)
    80005524:	fe843503          	ld	a0,-24(s0)
    80005528:	fffff097          	auipc	ra,0xfffff
    8000552c:	4fa080e7          	jalr	1274(ra) # 80004a22 <filewrite>
    80005530:	87aa                	mv	a5,a0
}
    80005532:	853e                	mv	a0,a5
    80005534:	70a2                	ld	ra,40(sp)
    80005536:	7402                	ld	s0,32(sp)
    80005538:	6145                	addi	sp,sp,48
    8000553a:	8082                	ret

000000008000553c <sys_close>:
{
    8000553c:	1101                	addi	sp,sp,-32
    8000553e:	ec06                	sd	ra,24(sp)
    80005540:	e822                	sd	s0,16(sp)
    80005542:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005544:	fe040613          	addi	a2,s0,-32
    80005548:	fec40593          	addi	a1,s0,-20
    8000554c:	4501                	li	a0,0
    8000554e:	00000097          	auipc	ra,0x0
    80005552:	cc2080e7          	jalr	-830(ra) # 80005210 <argfd>
    return -1;
    80005556:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005558:	02054463          	bltz	a0,80005580 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000555c:	ffffc097          	auipc	ra,0xffffc
    80005560:	472080e7          	jalr	1138(ra) # 800019ce <myproc>
    80005564:	fec42783          	lw	a5,-20(s0)
    80005568:	07e9                	addi	a5,a5,26
    8000556a:	078e                	slli	a5,a5,0x3
    8000556c:	97aa                	add	a5,a5,a0
    8000556e:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005572:	fe043503          	ld	a0,-32(s0)
    80005576:	fffff097          	auipc	ra,0xfffff
    8000557a:	2b0080e7          	jalr	688(ra) # 80004826 <fileclose>
  return 0;
    8000557e:	4781                	li	a5,0
}
    80005580:	853e                	mv	a0,a5
    80005582:	60e2                	ld	ra,24(sp)
    80005584:	6442                	ld	s0,16(sp)
    80005586:	6105                	addi	sp,sp,32
    80005588:	8082                	ret

000000008000558a <sys_fstat>:
{
    8000558a:	1101                	addi	sp,sp,-32
    8000558c:	ec06                	sd	ra,24(sp)
    8000558e:	e822                	sd	s0,16(sp)
    80005590:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005592:	fe840613          	addi	a2,s0,-24
    80005596:	4581                	li	a1,0
    80005598:	4501                	li	a0,0
    8000559a:	00000097          	auipc	ra,0x0
    8000559e:	c76080e7          	jalr	-906(ra) # 80005210 <argfd>
    return -1;
    800055a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055a4:	02054563          	bltz	a0,800055ce <sys_fstat+0x44>
    800055a8:	fe040593          	addi	a1,s0,-32
    800055ac:	4505                	li	a0,1
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	83e080e7          	jalr	-1986(ra) # 80002dec <argaddr>
    return -1;
    800055b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055b8:	00054b63          	bltz	a0,800055ce <sys_fstat+0x44>
  return filestat(f, st);
    800055bc:	fe043583          	ld	a1,-32(s0)
    800055c0:	fe843503          	ld	a0,-24(s0)
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	32a080e7          	jalr	810(ra) # 800048ee <filestat>
    800055cc:	87aa                	mv	a5,a0
}
    800055ce:	853e                	mv	a0,a5
    800055d0:	60e2                	ld	ra,24(sp)
    800055d2:	6442                	ld	s0,16(sp)
    800055d4:	6105                	addi	sp,sp,32
    800055d6:	8082                	ret

00000000800055d8 <sys_link>:
{
    800055d8:	7169                	addi	sp,sp,-304
    800055da:	f606                	sd	ra,296(sp)
    800055dc:	f222                	sd	s0,288(sp)
    800055de:	ee26                	sd	s1,280(sp)
    800055e0:	ea4a                	sd	s2,272(sp)
    800055e2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055e4:	08000613          	li	a2,128
    800055e8:	ed040593          	addi	a1,s0,-304
    800055ec:	4501                	li	a0,0
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	820080e7          	jalr	-2016(ra) # 80002e0e <argstr>
    return -1;
    800055f6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055f8:	10054e63          	bltz	a0,80005714 <sys_link+0x13c>
    800055fc:	08000613          	li	a2,128
    80005600:	f5040593          	addi	a1,s0,-176
    80005604:	4505                	li	a0,1
    80005606:	ffffe097          	auipc	ra,0xffffe
    8000560a:	808080e7          	jalr	-2040(ra) # 80002e0e <argstr>
    return -1;
    8000560e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005610:	10054263          	bltz	a0,80005714 <sys_link+0x13c>
  begin_op();
    80005614:	fffff097          	auipc	ra,0xfffff
    80005618:	d46080e7          	jalr	-698(ra) # 8000435a <begin_op>
  if((ip = namei(old)) == 0){
    8000561c:	ed040513          	addi	a0,s0,-304
    80005620:	fffff097          	auipc	ra,0xfffff
    80005624:	b1e080e7          	jalr	-1250(ra) # 8000413e <namei>
    80005628:	84aa                	mv	s1,a0
    8000562a:	c551                	beqz	a0,800056b6 <sys_link+0xde>
  ilock(ip);
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	35c080e7          	jalr	860(ra) # 80003988 <ilock>
  if(ip->type == T_DIR){
    80005634:	04449703          	lh	a4,68(s1)
    80005638:	4785                	li	a5,1
    8000563a:	08f70463          	beq	a4,a5,800056c2 <sys_link+0xea>
  ip->nlink++;
    8000563e:	04a4d783          	lhu	a5,74(s1)
    80005642:	2785                	addiw	a5,a5,1
    80005644:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005648:	8526                	mv	a0,s1
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	274080e7          	jalr	628(ra) # 800038be <iupdate>
  iunlock(ip);
    80005652:	8526                	mv	a0,s1
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	3f6080e7          	jalr	1014(ra) # 80003a4a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000565c:	fd040593          	addi	a1,s0,-48
    80005660:	f5040513          	addi	a0,s0,-176
    80005664:	fffff097          	auipc	ra,0xfffff
    80005668:	af8080e7          	jalr	-1288(ra) # 8000415c <nameiparent>
    8000566c:	892a                	mv	s2,a0
    8000566e:	c935                	beqz	a0,800056e2 <sys_link+0x10a>
  ilock(dp);
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	318080e7          	jalr	792(ra) # 80003988 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005678:	00092703          	lw	a4,0(s2)
    8000567c:	409c                	lw	a5,0(s1)
    8000567e:	04f71d63          	bne	a4,a5,800056d8 <sys_link+0x100>
    80005682:	40d0                	lw	a2,4(s1)
    80005684:	fd040593          	addi	a1,s0,-48
    80005688:	854a                	mv	a0,s2
    8000568a:	fffff097          	auipc	ra,0xfffff
    8000568e:	9f2080e7          	jalr	-1550(ra) # 8000407c <dirlink>
    80005692:	04054363          	bltz	a0,800056d8 <sys_link+0x100>
  iunlockput(dp);
    80005696:	854a                	mv	a0,s2
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	552080e7          	jalr	1362(ra) # 80003bea <iunlockput>
  iput(ip);
    800056a0:	8526                	mv	a0,s1
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	4a0080e7          	jalr	1184(ra) # 80003b42 <iput>
  end_op();
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	d30080e7          	jalr	-720(ra) # 800043da <end_op>
  return 0;
    800056b2:	4781                	li	a5,0
    800056b4:	a085                	j	80005714 <sys_link+0x13c>
    end_op();
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	d24080e7          	jalr	-732(ra) # 800043da <end_op>
    return -1;
    800056be:	57fd                	li	a5,-1
    800056c0:	a891                	j	80005714 <sys_link+0x13c>
    iunlockput(ip);
    800056c2:	8526                	mv	a0,s1
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	526080e7          	jalr	1318(ra) # 80003bea <iunlockput>
    end_op();
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	d0e080e7          	jalr	-754(ra) # 800043da <end_op>
    return -1;
    800056d4:	57fd                	li	a5,-1
    800056d6:	a83d                	j	80005714 <sys_link+0x13c>
    iunlockput(dp);
    800056d8:	854a                	mv	a0,s2
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	510080e7          	jalr	1296(ra) # 80003bea <iunlockput>
  ilock(ip);
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	2a4080e7          	jalr	676(ra) # 80003988 <ilock>
  ip->nlink--;
    800056ec:	04a4d783          	lhu	a5,74(s1)
    800056f0:	37fd                	addiw	a5,a5,-1
    800056f2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056f6:	8526                	mv	a0,s1
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	1c6080e7          	jalr	454(ra) # 800038be <iupdate>
  iunlockput(ip);
    80005700:	8526                	mv	a0,s1
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	4e8080e7          	jalr	1256(ra) # 80003bea <iunlockput>
  end_op();
    8000570a:	fffff097          	auipc	ra,0xfffff
    8000570e:	cd0080e7          	jalr	-816(ra) # 800043da <end_op>
  return -1;
    80005712:	57fd                	li	a5,-1
}
    80005714:	853e                	mv	a0,a5
    80005716:	70b2                	ld	ra,296(sp)
    80005718:	7412                	ld	s0,288(sp)
    8000571a:	64f2                	ld	s1,280(sp)
    8000571c:	6952                	ld	s2,272(sp)
    8000571e:	6155                	addi	sp,sp,304
    80005720:	8082                	ret

0000000080005722 <sys_unlink>:
{
    80005722:	7151                	addi	sp,sp,-240
    80005724:	f586                	sd	ra,232(sp)
    80005726:	f1a2                	sd	s0,224(sp)
    80005728:	eda6                	sd	s1,216(sp)
    8000572a:	e9ca                	sd	s2,208(sp)
    8000572c:	e5ce                	sd	s3,200(sp)
    8000572e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005730:	08000613          	li	a2,128
    80005734:	f3040593          	addi	a1,s0,-208
    80005738:	4501                	li	a0,0
    8000573a:	ffffd097          	auipc	ra,0xffffd
    8000573e:	6d4080e7          	jalr	1748(ra) # 80002e0e <argstr>
    80005742:	18054163          	bltz	a0,800058c4 <sys_unlink+0x1a2>
  begin_op();
    80005746:	fffff097          	auipc	ra,0xfffff
    8000574a:	c14080e7          	jalr	-1004(ra) # 8000435a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000574e:	fb040593          	addi	a1,s0,-80
    80005752:	f3040513          	addi	a0,s0,-208
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	a06080e7          	jalr	-1530(ra) # 8000415c <nameiparent>
    8000575e:	84aa                	mv	s1,a0
    80005760:	c979                	beqz	a0,80005836 <sys_unlink+0x114>
  ilock(dp);
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	226080e7          	jalr	550(ra) # 80003988 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000576a:	00003597          	auipc	a1,0x3
    8000576e:	fb658593          	addi	a1,a1,-74 # 80008720 <syscalls+0x2c0>
    80005772:	fb040513          	addi	a0,s0,-80
    80005776:	ffffe097          	auipc	ra,0xffffe
    8000577a:	6dc080e7          	jalr	1756(ra) # 80003e52 <namecmp>
    8000577e:	14050a63          	beqz	a0,800058d2 <sys_unlink+0x1b0>
    80005782:	00003597          	auipc	a1,0x3
    80005786:	fa658593          	addi	a1,a1,-90 # 80008728 <syscalls+0x2c8>
    8000578a:	fb040513          	addi	a0,s0,-80
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	6c4080e7          	jalr	1732(ra) # 80003e52 <namecmp>
    80005796:	12050e63          	beqz	a0,800058d2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000579a:	f2c40613          	addi	a2,s0,-212
    8000579e:	fb040593          	addi	a1,s0,-80
    800057a2:	8526                	mv	a0,s1
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	6c8080e7          	jalr	1736(ra) # 80003e6c <dirlookup>
    800057ac:	892a                	mv	s2,a0
    800057ae:	12050263          	beqz	a0,800058d2 <sys_unlink+0x1b0>
  ilock(ip);
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	1d6080e7          	jalr	470(ra) # 80003988 <ilock>
  if(ip->nlink < 1)
    800057ba:	04a91783          	lh	a5,74(s2)
    800057be:	08f05263          	blez	a5,80005842 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057c2:	04491703          	lh	a4,68(s2)
    800057c6:	4785                	li	a5,1
    800057c8:	08f70563          	beq	a4,a5,80005852 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057cc:	4641                	li	a2,16
    800057ce:	4581                	li	a1,0
    800057d0:	fc040513          	addi	a0,s0,-64
    800057d4:	ffffb097          	auipc	ra,0xffffb
    800057d8:	50c080e7          	jalr	1292(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057dc:	4741                	li	a4,16
    800057de:	f2c42683          	lw	a3,-212(s0)
    800057e2:	fc040613          	addi	a2,s0,-64
    800057e6:	4581                	li	a1,0
    800057e8:	8526                	mv	a0,s1
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	54a080e7          	jalr	1354(ra) # 80003d34 <writei>
    800057f2:	47c1                	li	a5,16
    800057f4:	0af51563          	bne	a0,a5,8000589e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057f8:	04491703          	lh	a4,68(s2)
    800057fc:	4785                	li	a5,1
    800057fe:	0af70863          	beq	a4,a5,800058ae <sys_unlink+0x18c>
  iunlockput(dp);
    80005802:	8526                	mv	a0,s1
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	3e6080e7          	jalr	998(ra) # 80003bea <iunlockput>
  ip->nlink--;
    8000580c:	04a95783          	lhu	a5,74(s2)
    80005810:	37fd                	addiw	a5,a5,-1
    80005812:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005816:	854a                	mv	a0,s2
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	0a6080e7          	jalr	166(ra) # 800038be <iupdate>
  iunlockput(ip);
    80005820:	854a                	mv	a0,s2
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	3c8080e7          	jalr	968(ra) # 80003bea <iunlockput>
  end_op();
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	bb0080e7          	jalr	-1104(ra) # 800043da <end_op>
  return 0;
    80005832:	4501                	li	a0,0
    80005834:	a84d                	j	800058e6 <sys_unlink+0x1c4>
    end_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	ba4080e7          	jalr	-1116(ra) # 800043da <end_op>
    return -1;
    8000583e:	557d                	li	a0,-1
    80005840:	a05d                	j	800058e6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005842:	00003517          	auipc	a0,0x3
    80005846:	f0e50513          	addi	a0,a0,-242 # 80008750 <syscalls+0x2f0>
    8000584a:	ffffb097          	auipc	ra,0xffffb
    8000584e:	cf4080e7          	jalr	-780(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005852:	04c92703          	lw	a4,76(s2)
    80005856:	02000793          	li	a5,32
    8000585a:	f6e7f9e3          	bgeu	a5,a4,800057cc <sys_unlink+0xaa>
    8000585e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005862:	4741                	li	a4,16
    80005864:	86ce                	mv	a3,s3
    80005866:	f1840613          	addi	a2,s0,-232
    8000586a:	4581                	li	a1,0
    8000586c:	854a                	mv	a0,s2
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	3ce080e7          	jalr	974(ra) # 80003c3c <readi>
    80005876:	47c1                	li	a5,16
    80005878:	00f51b63          	bne	a0,a5,8000588e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000587c:	f1845783          	lhu	a5,-232(s0)
    80005880:	e7a1                	bnez	a5,800058c8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005882:	29c1                	addiw	s3,s3,16
    80005884:	04c92783          	lw	a5,76(s2)
    80005888:	fcf9ede3          	bltu	s3,a5,80005862 <sys_unlink+0x140>
    8000588c:	b781                	j	800057cc <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000588e:	00003517          	auipc	a0,0x3
    80005892:	eda50513          	addi	a0,a0,-294 # 80008768 <syscalls+0x308>
    80005896:	ffffb097          	auipc	ra,0xffffb
    8000589a:	ca8080e7          	jalr	-856(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000589e:	00003517          	auipc	a0,0x3
    800058a2:	ee250513          	addi	a0,a0,-286 # 80008780 <syscalls+0x320>
    800058a6:	ffffb097          	auipc	ra,0xffffb
    800058aa:	c98080e7          	jalr	-872(ra) # 8000053e <panic>
    dp->nlink--;
    800058ae:	04a4d783          	lhu	a5,74(s1)
    800058b2:	37fd                	addiw	a5,a5,-1
    800058b4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058b8:	8526                	mv	a0,s1
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	004080e7          	jalr	4(ra) # 800038be <iupdate>
    800058c2:	b781                	j	80005802 <sys_unlink+0xe0>
    return -1;
    800058c4:	557d                	li	a0,-1
    800058c6:	a005                	j	800058e6 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058c8:	854a                	mv	a0,s2
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	320080e7          	jalr	800(ra) # 80003bea <iunlockput>
  iunlockput(dp);
    800058d2:	8526                	mv	a0,s1
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	316080e7          	jalr	790(ra) # 80003bea <iunlockput>
  end_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	afe080e7          	jalr	-1282(ra) # 800043da <end_op>
  return -1;
    800058e4:	557d                	li	a0,-1
}
    800058e6:	70ae                	ld	ra,232(sp)
    800058e8:	740e                	ld	s0,224(sp)
    800058ea:	64ee                	ld	s1,216(sp)
    800058ec:	694e                	ld	s2,208(sp)
    800058ee:	69ae                	ld	s3,200(sp)
    800058f0:	616d                	addi	sp,sp,240
    800058f2:	8082                	ret

00000000800058f4 <sys_open>:

uint64
sys_open(void)
{
    800058f4:	7131                	addi	sp,sp,-192
    800058f6:	fd06                	sd	ra,184(sp)
    800058f8:	f922                	sd	s0,176(sp)
    800058fa:	f526                	sd	s1,168(sp)
    800058fc:	f14a                	sd	s2,160(sp)
    800058fe:	ed4e                	sd	s3,152(sp)
    80005900:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005902:	08000613          	li	a2,128
    80005906:	f5040593          	addi	a1,s0,-176
    8000590a:	4501                	li	a0,0
    8000590c:	ffffd097          	auipc	ra,0xffffd
    80005910:	502080e7          	jalr	1282(ra) # 80002e0e <argstr>
    return -1;
    80005914:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005916:	0c054163          	bltz	a0,800059d8 <sys_open+0xe4>
    8000591a:	f4c40593          	addi	a1,s0,-180
    8000591e:	4505                	li	a0,1
    80005920:	ffffd097          	auipc	ra,0xffffd
    80005924:	4aa080e7          	jalr	1194(ra) # 80002dca <argint>
    80005928:	0a054863          	bltz	a0,800059d8 <sys_open+0xe4>

  begin_op();
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	a2e080e7          	jalr	-1490(ra) # 8000435a <begin_op>

  if(omode & O_CREATE){
    80005934:	f4c42783          	lw	a5,-180(s0)
    80005938:	2007f793          	andi	a5,a5,512
    8000593c:	cbdd                	beqz	a5,800059f2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000593e:	4681                	li	a3,0
    80005940:	4601                	li	a2,0
    80005942:	4589                	li	a1,2
    80005944:	f5040513          	addi	a0,s0,-176
    80005948:	00000097          	auipc	ra,0x0
    8000594c:	972080e7          	jalr	-1678(ra) # 800052ba <create>
    80005950:	892a                	mv	s2,a0
    if(ip == 0){
    80005952:	c959                	beqz	a0,800059e8 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005954:	04491703          	lh	a4,68(s2)
    80005958:	478d                	li	a5,3
    8000595a:	00f71763          	bne	a4,a5,80005968 <sys_open+0x74>
    8000595e:	04695703          	lhu	a4,70(s2)
    80005962:	47a5                	li	a5,9
    80005964:	0ce7ec63          	bltu	a5,a4,80005a3c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005968:	fffff097          	auipc	ra,0xfffff
    8000596c:	e02080e7          	jalr	-510(ra) # 8000476a <filealloc>
    80005970:	89aa                	mv	s3,a0
    80005972:	10050263          	beqz	a0,80005a76 <sys_open+0x182>
    80005976:	00000097          	auipc	ra,0x0
    8000597a:	902080e7          	jalr	-1790(ra) # 80005278 <fdalloc>
    8000597e:	84aa                	mv	s1,a0
    80005980:	0e054663          	bltz	a0,80005a6c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005984:	04491703          	lh	a4,68(s2)
    80005988:	478d                	li	a5,3
    8000598a:	0cf70463          	beq	a4,a5,80005a52 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000598e:	4789                	li	a5,2
    80005990:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005994:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005998:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000599c:	f4c42783          	lw	a5,-180(s0)
    800059a0:	0017c713          	xori	a4,a5,1
    800059a4:	8b05                	andi	a4,a4,1
    800059a6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059aa:	0037f713          	andi	a4,a5,3
    800059ae:	00e03733          	snez	a4,a4
    800059b2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059b6:	4007f793          	andi	a5,a5,1024
    800059ba:	c791                	beqz	a5,800059c6 <sys_open+0xd2>
    800059bc:	04491703          	lh	a4,68(s2)
    800059c0:	4789                	li	a5,2
    800059c2:	08f70f63          	beq	a4,a5,80005a60 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059c6:	854a                	mv	a0,s2
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	082080e7          	jalr	130(ra) # 80003a4a <iunlock>
  end_op();
    800059d0:	fffff097          	auipc	ra,0xfffff
    800059d4:	a0a080e7          	jalr	-1526(ra) # 800043da <end_op>

  return fd;
}
    800059d8:	8526                	mv	a0,s1
    800059da:	70ea                	ld	ra,184(sp)
    800059dc:	744a                	ld	s0,176(sp)
    800059de:	74aa                	ld	s1,168(sp)
    800059e0:	790a                	ld	s2,160(sp)
    800059e2:	69ea                	ld	s3,152(sp)
    800059e4:	6129                	addi	sp,sp,192
    800059e6:	8082                	ret
      end_op();
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	9f2080e7          	jalr	-1550(ra) # 800043da <end_op>
      return -1;
    800059f0:	b7e5                	j	800059d8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059f2:	f5040513          	addi	a0,s0,-176
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	748080e7          	jalr	1864(ra) # 8000413e <namei>
    800059fe:	892a                	mv	s2,a0
    80005a00:	c905                	beqz	a0,80005a30 <sys_open+0x13c>
    ilock(ip);
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	f86080e7          	jalr	-122(ra) # 80003988 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a0a:	04491703          	lh	a4,68(s2)
    80005a0e:	4785                	li	a5,1
    80005a10:	f4f712e3          	bne	a4,a5,80005954 <sys_open+0x60>
    80005a14:	f4c42783          	lw	a5,-180(s0)
    80005a18:	dba1                	beqz	a5,80005968 <sys_open+0x74>
      iunlockput(ip);
    80005a1a:	854a                	mv	a0,s2
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	1ce080e7          	jalr	462(ra) # 80003bea <iunlockput>
      end_op();
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	9b6080e7          	jalr	-1610(ra) # 800043da <end_op>
      return -1;
    80005a2c:	54fd                	li	s1,-1
    80005a2e:	b76d                	j	800059d8 <sys_open+0xe4>
      end_op();
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	9aa080e7          	jalr	-1622(ra) # 800043da <end_op>
      return -1;
    80005a38:	54fd                	li	s1,-1
    80005a3a:	bf79                	j	800059d8 <sys_open+0xe4>
    iunlockput(ip);
    80005a3c:	854a                	mv	a0,s2
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	1ac080e7          	jalr	428(ra) # 80003bea <iunlockput>
    end_op();
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	994080e7          	jalr	-1644(ra) # 800043da <end_op>
    return -1;
    80005a4e:	54fd                	li	s1,-1
    80005a50:	b761                	j	800059d8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a52:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a56:	04691783          	lh	a5,70(s2)
    80005a5a:	02f99223          	sh	a5,36(s3)
    80005a5e:	bf2d                	j	80005998 <sys_open+0xa4>
    itrunc(ip);
    80005a60:	854a                	mv	a0,s2
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	034080e7          	jalr	52(ra) # 80003a96 <itrunc>
    80005a6a:	bfb1                	j	800059c6 <sys_open+0xd2>
      fileclose(f);
    80005a6c:	854e                	mv	a0,s3
    80005a6e:	fffff097          	auipc	ra,0xfffff
    80005a72:	db8080e7          	jalr	-584(ra) # 80004826 <fileclose>
    iunlockput(ip);
    80005a76:	854a                	mv	a0,s2
    80005a78:	ffffe097          	auipc	ra,0xffffe
    80005a7c:	172080e7          	jalr	370(ra) # 80003bea <iunlockput>
    end_op();
    80005a80:	fffff097          	auipc	ra,0xfffff
    80005a84:	95a080e7          	jalr	-1702(ra) # 800043da <end_op>
    return -1;
    80005a88:	54fd                	li	s1,-1
    80005a8a:	b7b9                	j	800059d8 <sys_open+0xe4>

0000000080005a8c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a8c:	7175                	addi	sp,sp,-144
    80005a8e:	e506                	sd	ra,136(sp)
    80005a90:	e122                	sd	s0,128(sp)
    80005a92:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a94:	fffff097          	auipc	ra,0xfffff
    80005a98:	8c6080e7          	jalr	-1850(ra) # 8000435a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a9c:	08000613          	li	a2,128
    80005aa0:	f7040593          	addi	a1,s0,-144
    80005aa4:	4501                	li	a0,0
    80005aa6:	ffffd097          	auipc	ra,0xffffd
    80005aaa:	368080e7          	jalr	872(ra) # 80002e0e <argstr>
    80005aae:	02054963          	bltz	a0,80005ae0 <sys_mkdir+0x54>
    80005ab2:	4681                	li	a3,0
    80005ab4:	4601                	li	a2,0
    80005ab6:	4585                	li	a1,1
    80005ab8:	f7040513          	addi	a0,s0,-144
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	7fe080e7          	jalr	2046(ra) # 800052ba <create>
    80005ac4:	cd11                	beqz	a0,80005ae0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ac6:	ffffe097          	auipc	ra,0xffffe
    80005aca:	124080e7          	jalr	292(ra) # 80003bea <iunlockput>
  end_op();
    80005ace:	fffff097          	auipc	ra,0xfffff
    80005ad2:	90c080e7          	jalr	-1780(ra) # 800043da <end_op>
  return 0;
    80005ad6:	4501                	li	a0,0
}
    80005ad8:	60aa                	ld	ra,136(sp)
    80005ada:	640a                	ld	s0,128(sp)
    80005adc:	6149                	addi	sp,sp,144
    80005ade:	8082                	ret
    end_op();
    80005ae0:	fffff097          	auipc	ra,0xfffff
    80005ae4:	8fa080e7          	jalr	-1798(ra) # 800043da <end_op>
    return -1;
    80005ae8:	557d                	li	a0,-1
    80005aea:	b7fd                	j	80005ad8 <sys_mkdir+0x4c>

0000000080005aec <sys_mknod>:

uint64
sys_mknod(void)
{
    80005aec:	7135                	addi	sp,sp,-160
    80005aee:	ed06                	sd	ra,152(sp)
    80005af0:	e922                	sd	s0,144(sp)
    80005af2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	866080e7          	jalr	-1946(ra) # 8000435a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005afc:	08000613          	li	a2,128
    80005b00:	f7040593          	addi	a1,s0,-144
    80005b04:	4501                	li	a0,0
    80005b06:	ffffd097          	auipc	ra,0xffffd
    80005b0a:	308080e7          	jalr	776(ra) # 80002e0e <argstr>
    80005b0e:	04054a63          	bltz	a0,80005b62 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b12:	f6c40593          	addi	a1,s0,-148
    80005b16:	4505                	li	a0,1
    80005b18:	ffffd097          	auipc	ra,0xffffd
    80005b1c:	2b2080e7          	jalr	690(ra) # 80002dca <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b20:	04054163          	bltz	a0,80005b62 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b24:	f6840593          	addi	a1,s0,-152
    80005b28:	4509                	li	a0,2
    80005b2a:	ffffd097          	auipc	ra,0xffffd
    80005b2e:	2a0080e7          	jalr	672(ra) # 80002dca <argint>
     argint(1, &major) < 0 ||
    80005b32:	02054863          	bltz	a0,80005b62 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b36:	f6841683          	lh	a3,-152(s0)
    80005b3a:	f6c41603          	lh	a2,-148(s0)
    80005b3e:	458d                	li	a1,3
    80005b40:	f7040513          	addi	a0,s0,-144
    80005b44:	fffff097          	auipc	ra,0xfffff
    80005b48:	776080e7          	jalr	1910(ra) # 800052ba <create>
     argint(2, &minor) < 0 ||
    80005b4c:	c919                	beqz	a0,80005b62 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b4e:	ffffe097          	auipc	ra,0xffffe
    80005b52:	09c080e7          	jalr	156(ra) # 80003bea <iunlockput>
  end_op();
    80005b56:	fffff097          	auipc	ra,0xfffff
    80005b5a:	884080e7          	jalr	-1916(ra) # 800043da <end_op>
  return 0;
    80005b5e:	4501                	li	a0,0
    80005b60:	a031                	j	80005b6c <sys_mknod+0x80>
    end_op();
    80005b62:	fffff097          	auipc	ra,0xfffff
    80005b66:	878080e7          	jalr	-1928(ra) # 800043da <end_op>
    return -1;
    80005b6a:	557d                	li	a0,-1
}
    80005b6c:	60ea                	ld	ra,152(sp)
    80005b6e:	644a                	ld	s0,144(sp)
    80005b70:	610d                	addi	sp,sp,160
    80005b72:	8082                	ret

0000000080005b74 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b74:	7135                	addi	sp,sp,-160
    80005b76:	ed06                	sd	ra,152(sp)
    80005b78:	e922                	sd	s0,144(sp)
    80005b7a:	e526                	sd	s1,136(sp)
    80005b7c:	e14a                	sd	s2,128(sp)
    80005b7e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b80:	ffffc097          	auipc	ra,0xffffc
    80005b84:	e4e080e7          	jalr	-434(ra) # 800019ce <myproc>
    80005b88:	892a                	mv	s2,a0
  
  begin_op();
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	7d0080e7          	jalr	2000(ra) # 8000435a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b92:	08000613          	li	a2,128
    80005b96:	f6040593          	addi	a1,s0,-160
    80005b9a:	4501                	li	a0,0
    80005b9c:	ffffd097          	auipc	ra,0xffffd
    80005ba0:	272080e7          	jalr	626(ra) # 80002e0e <argstr>
    80005ba4:	04054b63          	bltz	a0,80005bfa <sys_chdir+0x86>
    80005ba8:	f6040513          	addi	a0,s0,-160
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	592080e7          	jalr	1426(ra) # 8000413e <namei>
    80005bb4:	84aa                	mv	s1,a0
    80005bb6:	c131                	beqz	a0,80005bfa <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	dd0080e7          	jalr	-560(ra) # 80003988 <ilock>
  if(ip->type != T_DIR){
    80005bc0:	04449703          	lh	a4,68(s1)
    80005bc4:	4785                	li	a5,1
    80005bc6:	04f71063          	bne	a4,a5,80005c06 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bca:	8526                	mv	a0,s1
    80005bcc:	ffffe097          	auipc	ra,0xffffe
    80005bd0:	e7e080e7          	jalr	-386(ra) # 80003a4a <iunlock>
  iput(p->cwd);
    80005bd4:	15893503          	ld	a0,344(s2)
    80005bd8:	ffffe097          	auipc	ra,0xffffe
    80005bdc:	f6a080e7          	jalr	-150(ra) # 80003b42 <iput>
  end_op();
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	7fa080e7          	jalr	2042(ra) # 800043da <end_op>
  p->cwd = ip;
    80005be8:	14993c23          	sd	s1,344(s2)
  return 0;
    80005bec:	4501                	li	a0,0
}
    80005bee:	60ea                	ld	ra,152(sp)
    80005bf0:	644a                	ld	s0,144(sp)
    80005bf2:	64aa                	ld	s1,136(sp)
    80005bf4:	690a                	ld	s2,128(sp)
    80005bf6:	610d                	addi	sp,sp,160
    80005bf8:	8082                	ret
    end_op();
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	7e0080e7          	jalr	2016(ra) # 800043da <end_op>
    return -1;
    80005c02:	557d                	li	a0,-1
    80005c04:	b7ed                	j	80005bee <sys_chdir+0x7a>
    iunlockput(ip);
    80005c06:	8526                	mv	a0,s1
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	fe2080e7          	jalr	-30(ra) # 80003bea <iunlockput>
    end_op();
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	7ca080e7          	jalr	1994(ra) # 800043da <end_op>
    return -1;
    80005c18:	557d                	li	a0,-1
    80005c1a:	bfd1                	j	80005bee <sys_chdir+0x7a>

0000000080005c1c <sys_exec>:

uint64
sys_exec(void)
{
    80005c1c:	7145                	addi	sp,sp,-464
    80005c1e:	e786                	sd	ra,456(sp)
    80005c20:	e3a2                	sd	s0,448(sp)
    80005c22:	ff26                	sd	s1,440(sp)
    80005c24:	fb4a                	sd	s2,432(sp)
    80005c26:	f74e                	sd	s3,424(sp)
    80005c28:	f352                	sd	s4,416(sp)
    80005c2a:	ef56                	sd	s5,408(sp)
    80005c2c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c2e:	08000613          	li	a2,128
    80005c32:	f4040593          	addi	a1,s0,-192
    80005c36:	4501                	li	a0,0
    80005c38:	ffffd097          	auipc	ra,0xffffd
    80005c3c:	1d6080e7          	jalr	470(ra) # 80002e0e <argstr>
    return -1;
    80005c40:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c42:	0c054a63          	bltz	a0,80005d16 <sys_exec+0xfa>
    80005c46:	e3840593          	addi	a1,s0,-456
    80005c4a:	4505                	li	a0,1
    80005c4c:	ffffd097          	auipc	ra,0xffffd
    80005c50:	1a0080e7          	jalr	416(ra) # 80002dec <argaddr>
    80005c54:	0c054163          	bltz	a0,80005d16 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c58:	10000613          	li	a2,256
    80005c5c:	4581                	li	a1,0
    80005c5e:	e4040513          	addi	a0,s0,-448
    80005c62:	ffffb097          	auipc	ra,0xffffb
    80005c66:	07e080e7          	jalr	126(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c6a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c6e:	89a6                	mv	s3,s1
    80005c70:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c72:	02000a13          	li	s4,32
    80005c76:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c7a:	00391513          	slli	a0,s2,0x3
    80005c7e:	e3040593          	addi	a1,s0,-464
    80005c82:	e3843783          	ld	a5,-456(s0)
    80005c86:	953e                	add	a0,a0,a5
    80005c88:	ffffd097          	auipc	ra,0xffffd
    80005c8c:	0a8080e7          	jalr	168(ra) # 80002d30 <fetchaddr>
    80005c90:	02054a63          	bltz	a0,80005cc4 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c94:	e3043783          	ld	a5,-464(s0)
    80005c98:	c3b9                	beqz	a5,80005cde <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c9a:	ffffb097          	auipc	ra,0xffffb
    80005c9e:	e5a080e7          	jalr	-422(ra) # 80000af4 <kalloc>
    80005ca2:	85aa                	mv	a1,a0
    80005ca4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ca8:	cd11                	beqz	a0,80005cc4 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005caa:	6605                	lui	a2,0x1
    80005cac:	e3043503          	ld	a0,-464(s0)
    80005cb0:	ffffd097          	auipc	ra,0xffffd
    80005cb4:	0d2080e7          	jalr	210(ra) # 80002d82 <fetchstr>
    80005cb8:	00054663          	bltz	a0,80005cc4 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005cbc:	0905                	addi	s2,s2,1
    80005cbe:	09a1                	addi	s3,s3,8
    80005cc0:	fb491be3          	bne	s2,s4,80005c76 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cc4:	10048913          	addi	s2,s1,256
    80005cc8:	6088                	ld	a0,0(s1)
    80005cca:	c529                	beqz	a0,80005d14 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ccc:	ffffb097          	auipc	ra,0xffffb
    80005cd0:	d2c080e7          	jalr	-724(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cd4:	04a1                	addi	s1,s1,8
    80005cd6:	ff2499e3          	bne	s1,s2,80005cc8 <sys_exec+0xac>
  return -1;
    80005cda:	597d                	li	s2,-1
    80005cdc:	a82d                	j	80005d16 <sys_exec+0xfa>
      argv[i] = 0;
    80005cde:	0a8e                	slli	s5,s5,0x3
    80005ce0:	fc040793          	addi	a5,s0,-64
    80005ce4:	9abe                	add	s5,s5,a5
    80005ce6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cea:	e4040593          	addi	a1,s0,-448
    80005cee:	f4040513          	addi	a0,s0,-192
    80005cf2:	fffff097          	auipc	ra,0xfffff
    80005cf6:	194080e7          	jalr	404(ra) # 80004e86 <exec>
    80005cfa:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cfc:	10048993          	addi	s3,s1,256
    80005d00:	6088                	ld	a0,0(s1)
    80005d02:	c911                	beqz	a0,80005d16 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d04:	ffffb097          	auipc	ra,0xffffb
    80005d08:	cf4080e7          	jalr	-780(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d0c:	04a1                	addi	s1,s1,8
    80005d0e:	ff3499e3          	bne	s1,s3,80005d00 <sys_exec+0xe4>
    80005d12:	a011                	j	80005d16 <sys_exec+0xfa>
  return -1;
    80005d14:	597d                	li	s2,-1
}
    80005d16:	854a                	mv	a0,s2
    80005d18:	60be                	ld	ra,456(sp)
    80005d1a:	641e                	ld	s0,448(sp)
    80005d1c:	74fa                	ld	s1,440(sp)
    80005d1e:	795a                	ld	s2,432(sp)
    80005d20:	79ba                	ld	s3,424(sp)
    80005d22:	7a1a                	ld	s4,416(sp)
    80005d24:	6afa                	ld	s5,408(sp)
    80005d26:	6179                	addi	sp,sp,464
    80005d28:	8082                	ret

0000000080005d2a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d2a:	7139                	addi	sp,sp,-64
    80005d2c:	fc06                	sd	ra,56(sp)
    80005d2e:	f822                	sd	s0,48(sp)
    80005d30:	f426                	sd	s1,40(sp)
    80005d32:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d34:	ffffc097          	auipc	ra,0xffffc
    80005d38:	c9a080e7          	jalr	-870(ra) # 800019ce <myproc>
    80005d3c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d3e:	fd840593          	addi	a1,s0,-40
    80005d42:	4501                	li	a0,0
    80005d44:	ffffd097          	auipc	ra,0xffffd
    80005d48:	0a8080e7          	jalr	168(ra) # 80002dec <argaddr>
    return -1;
    80005d4c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d4e:	0e054063          	bltz	a0,80005e2e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d52:	fc840593          	addi	a1,s0,-56
    80005d56:	fd040513          	addi	a0,s0,-48
    80005d5a:	fffff097          	auipc	ra,0xfffff
    80005d5e:	dfc080e7          	jalr	-516(ra) # 80004b56 <pipealloc>
    return -1;
    80005d62:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d64:	0c054563          	bltz	a0,80005e2e <sys_pipe+0x104>
  fd0 = -1;
    80005d68:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d6c:	fd043503          	ld	a0,-48(s0)
    80005d70:	fffff097          	auipc	ra,0xfffff
    80005d74:	508080e7          	jalr	1288(ra) # 80005278 <fdalloc>
    80005d78:	fca42223          	sw	a0,-60(s0)
    80005d7c:	08054c63          	bltz	a0,80005e14 <sys_pipe+0xea>
    80005d80:	fc843503          	ld	a0,-56(s0)
    80005d84:	fffff097          	auipc	ra,0xfffff
    80005d88:	4f4080e7          	jalr	1268(ra) # 80005278 <fdalloc>
    80005d8c:	fca42023          	sw	a0,-64(s0)
    80005d90:	06054863          	bltz	a0,80005e00 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d94:	4691                	li	a3,4
    80005d96:	fc440613          	addi	a2,s0,-60
    80005d9a:	fd843583          	ld	a1,-40(s0)
    80005d9e:	6ca8                	ld	a0,88(s1)
    80005da0:	ffffc097          	auipc	ra,0xffffc
    80005da4:	8da080e7          	jalr	-1830(ra) # 8000167a <copyout>
    80005da8:	02054063          	bltz	a0,80005dc8 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005dac:	4691                	li	a3,4
    80005dae:	fc040613          	addi	a2,s0,-64
    80005db2:	fd843583          	ld	a1,-40(s0)
    80005db6:	0591                	addi	a1,a1,4
    80005db8:	6ca8                	ld	a0,88(s1)
    80005dba:	ffffc097          	auipc	ra,0xffffc
    80005dbe:	8c0080e7          	jalr	-1856(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005dc2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dc4:	06055563          	bgez	a0,80005e2e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005dc8:	fc442783          	lw	a5,-60(s0)
    80005dcc:	07e9                	addi	a5,a5,26
    80005dce:	078e                	slli	a5,a5,0x3
    80005dd0:	97a6                	add	a5,a5,s1
    80005dd2:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005dd6:	fc042503          	lw	a0,-64(s0)
    80005dda:	0569                	addi	a0,a0,26
    80005ddc:	050e                	slli	a0,a0,0x3
    80005dde:	9526                	add	a0,a0,s1
    80005de0:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005de4:	fd043503          	ld	a0,-48(s0)
    80005de8:	fffff097          	auipc	ra,0xfffff
    80005dec:	a3e080e7          	jalr	-1474(ra) # 80004826 <fileclose>
    fileclose(wf);
    80005df0:	fc843503          	ld	a0,-56(s0)
    80005df4:	fffff097          	auipc	ra,0xfffff
    80005df8:	a32080e7          	jalr	-1486(ra) # 80004826 <fileclose>
    return -1;
    80005dfc:	57fd                	li	a5,-1
    80005dfe:	a805                	j	80005e2e <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e00:	fc442783          	lw	a5,-60(s0)
    80005e04:	0007c863          	bltz	a5,80005e14 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e08:	01a78513          	addi	a0,a5,26
    80005e0c:	050e                	slli	a0,a0,0x3
    80005e0e:	9526                	add	a0,a0,s1
    80005e10:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005e14:	fd043503          	ld	a0,-48(s0)
    80005e18:	fffff097          	auipc	ra,0xfffff
    80005e1c:	a0e080e7          	jalr	-1522(ra) # 80004826 <fileclose>
    fileclose(wf);
    80005e20:	fc843503          	ld	a0,-56(s0)
    80005e24:	fffff097          	auipc	ra,0xfffff
    80005e28:	a02080e7          	jalr	-1534(ra) # 80004826 <fileclose>
    return -1;
    80005e2c:	57fd                	li	a5,-1
}
    80005e2e:	853e                	mv	a0,a5
    80005e30:	70e2                	ld	ra,56(sp)
    80005e32:	7442                	ld	s0,48(sp)
    80005e34:	74a2                	ld	s1,40(sp)
    80005e36:	6121                	addi	sp,sp,64
    80005e38:	8082                	ret
    80005e3a:	0000                	unimp
    80005e3c:	0000                	unimp
	...

0000000080005e40 <kernelvec>:
    80005e40:	7111                	addi	sp,sp,-256
    80005e42:	e006                	sd	ra,0(sp)
    80005e44:	e40a                	sd	sp,8(sp)
    80005e46:	e80e                	sd	gp,16(sp)
    80005e48:	ec12                	sd	tp,24(sp)
    80005e4a:	f016                	sd	t0,32(sp)
    80005e4c:	f41a                	sd	t1,40(sp)
    80005e4e:	f81e                	sd	t2,48(sp)
    80005e50:	fc22                	sd	s0,56(sp)
    80005e52:	e0a6                	sd	s1,64(sp)
    80005e54:	e4aa                	sd	a0,72(sp)
    80005e56:	e8ae                	sd	a1,80(sp)
    80005e58:	ecb2                	sd	a2,88(sp)
    80005e5a:	f0b6                	sd	a3,96(sp)
    80005e5c:	f4ba                	sd	a4,104(sp)
    80005e5e:	f8be                	sd	a5,112(sp)
    80005e60:	fcc2                	sd	a6,120(sp)
    80005e62:	e146                	sd	a7,128(sp)
    80005e64:	e54a                	sd	s2,136(sp)
    80005e66:	e94e                	sd	s3,144(sp)
    80005e68:	ed52                	sd	s4,152(sp)
    80005e6a:	f156                	sd	s5,160(sp)
    80005e6c:	f55a                	sd	s6,168(sp)
    80005e6e:	f95e                	sd	s7,176(sp)
    80005e70:	fd62                	sd	s8,184(sp)
    80005e72:	e1e6                	sd	s9,192(sp)
    80005e74:	e5ea                	sd	s10,200(sp)
    80005e76:	e9ee                	sd	s11,208(sp)
    80005e78:	edf2                	sd	t3,216(sp)
    80005e7a:	f1f6                	sd	t4,224(sp)
    80005e7c:	f5fa                	sd	t5,232(sp)
    80005e7e:	f9fe                	sd	t6,240(sp)
    80005e80:	d7dfc0ef          	jal	ra,80002bfc <kerneltrap>
    80005e84:	6082                	ld	ra,0(sp)
    80005e86:	6122                	ld	sp,8(sp)
    80005e88:	61c2                	ld	gp,16(sp)
    80005e8a:	7282                	ld	t0,32(sp)
    80005e8c:	7322                	ld	t1,40(sp)
    80005e8e:	73c2                	ld	t2,48(sp)
    80005e90:	7462                	ld	s0,56(sp)
    80005e92:	6486                	ld	s1,64(sp)
    80005e94:	6526                	ld	a0,72(sp)
    80005e96:	65c6                	ld	a1,80(sp)
    80005e98:	6666                	ld	a2,88(sp)
    80005e9a:	7686                	ld	a3,96(sp)
    80005e9c:	7726                	ld	a4,104(sp)
    80005e9e:	77c6                	ld	a5,112(sp)
    80005ea0:	7866                	ld	a6,120(sp)
    80005ea2:	688a                	ld	a7,128(sp)
    80005ea4:	692a                	ld	s2,136(sp)
    80005ea6:	69ca                	ld	s3,144(sp)
    80005ea8:	6a6a                	ld	s4,152(sp)
    80005eaa:	7a8a                	ld	s5,160(sp)
    80005eac:	7b2a                	ld	s6,168(sp)
    80005eae:	7bca                	ld	s7,176(sp)
    80005eb0:	7c6a                	ld	s8,184(sp)
    80005eb2:	6c8e                	ld	s9,192(sp)
    80005eb4:	6d2e                	ld	s10,200(sp)
    80005eb6:	6dce                	ld	s11,208(sp)
    80005eb8:	6e6e                	ld	t3,216(sp)
    80005eba:	7e8e                	ld	t4,224(sp)
    80005ebc:	7f2e                	ld	t5,232(sp)
    80005ebe:	7fce                	ld	t6,240(sp)
    80005ec0:	6111                	addi	sp,sp,256
    80005ec2:	10200073          	sret
    80005ec6:	00000013          	nop
    80005eca:	00000013          	nop
    80005ece:	0001                	nop

0000000080005ed0 <timervec>:
    80005ed0:	34051573          	csrrw	a0,mscratch,a0
    80005ed4:	e10c                	sd	a1,0(a0)
    80005ed6:	e510                	sd	a2,8(a0)
    80005ed8:	e914                	sd	a3,16(a0)
    80005eda:	6d0c                	ld	a1,24(a0)
    80005edc:	7110                	ld	a2,32(a0)
    80005ede:	6194                	ld	a3,0(a1)
    80005ee0:	96b2                	add	a3,a3,a2
    80005ee2:	e194                	sd	a3,0(a1)
    80005ee4:	4589                	li	a1,2
    80005ee6:	14459073          	csrw	sip,a1
    80005eea:	6914                	ld	a3,16(a0)
    80005eec:	6510                	ld	a2,8(a0)
    80005eee:	610c                	ld	a1,0(a0)
    80005ef0:	34051573          	csrrw	a0,mscratch,a0
    80005ef4:	30200073          	mret
	...

0000000080005efa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005efa:	1141                	addi	sp,sp,-16
    80005efc:	e422                	sd	s0,8(sp)
    80005efe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f00:	0c0007b7          	lui	a5,0xc000
    80005f04:	4705                	li	a4,1
    80005f06:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f08:	c3d8                	sw	a4,4(a5)
}
    80005f0a:	6422                	ld	s0,8(sp)
    80005f0c:	0141                	addi	sp,sp,16
    80005f0e:	8082                	ret

0000000080005f10 <plicinithart>:

void
plicinithart(void)
{
    80005f10:	1141                	addi	sp,sp,-16
    80005f12:	e406                	sd	ra,8(sp)
    80005f14:	e022                	sd	s0,0(sp)
    80005f16:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f18:	ffffc097          	auipc	ra,0xffffc
    80005f1c:	a8a080e7          	jalr	-1398(ra) # 800019a2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f20:	0085171b          	slliw	a4,a0,0x8
    80005f24:	0c0027b7          	lui	a5,0xc002
    80005f28:	97ba                	add	a5,a5,a4
    80005f2a:	40200713          	li	a4,1026
    80005f2e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f32:	00d5151b          	slliw	a0,a0,0xd
    80005f36:	0c2017b7          	lui	a5,0xc201
    80005f3a:	953e                	add	a0,a0,a5
    80005f3c:	00052023          	sw	zero,0(a0)
}
    80005f40:	60a2                	ld	ra,8(sp)
    80005f42:	6402                	ld	s0,0(sp)
    80005f44:	0141                	addi	sp,sp,16
    80005f46:	8082                	ret

0000000080005f48 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f48:	1141                	addi	sp,sp,-16
    80005f4a:	e406                	sd	ra,8(sp)
    80005f4c:	e022                	sd	s0,0(sp)
    80005f4e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f50:	ffffc097          	auipc	ra,0xffffc
    80005f54:	a52080e7          	jalr	-1454(ra) # 800019a2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f58:	00d5179b          	slliw	a5,a0,0xd
    80005f5c:	0c201537          	lui	a0,0xc201
    80005f60:	953e                	add	a0,a0,a5
  return irq;
}
    80005f62:	4148                	lw	a0,4(a0)
    80005f64:	60a2                	ld	ra,8(sp)
    80005f66:	6402                	ld	s0,0(sp)
    80005f68:	0141                	addi	sp,sp,16
    80005f6a:	8082                	ret

0000000080005f6c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f6c:	1101                	addi	sp,sp,-32
    80005f6e:	ec06                	sd	ra,24(sp)
    80005f70:	e822                	sd	s0,16(sp)
    80005f72:	e426                	sd	s1,8(sp)
    80005f74:	1000                	addi	s0,sp,32
    80005f76:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f78:	ffffc097          	auipc	ra,0xffffc
    80005f7c:	a2a080e7          	jalr	-1494(ra) # 800019a2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f80:	00d5151b          	slliw	a0,a0,0xd
    80005f84:	0c2017b7          	lui	a5,0xc201
    80005f88:	97aa                	add	a5,a5,a0
    80005f8a:	c3c4                	sw	s1,4(a5)
}
    80005f8c:	60e2                	ld	ra,24(sp)
    80005f8e:	6442                	ld	s0,16(sp)
    80005f90:	64a2                	ld	s1,8(sp)
    80005f92:	6105                	addi	sp,sp,32
    80005f94:	8082                	ret

0000000080005f96 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f96:	1141                	addi	sp,sp,-16
    80005f98:	e406                	sd	ra,8(sp)
    80005f9a:	e022                	sd	s0,0(sp)
    80005f9c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f9e:	479d                	li	a5,7
    80005fa0:	06a7c963          	blt	a5,a0,80006012 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005fa4:	0001d797          	auipc	a5,0x1d
    80005fa8:	05c78793          	addi	a5,a5,92 # 80023000 <disk>
    80005fac:	00a78733          	add	a4,a5,a0
    80005fb0:	6789                	lui	a5,0x2
    80005fb2:	97ba                	add	a5,a5,a4
    80005fb4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005fb8:	e7ad                	bnez	a5,80006022 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005fba:	00451793          	slli	a5,a0,0x4
    80005fbe:	0001f717          	auipc	a4,0x1f
    80005fc2:	04270713          	addi	a4,a4,66 # 80025000 <disk+0x2000>
    80005fc6:	6314                	ld	a3,0(a4)
    80005fc8:	96be                	add	a3,a3,a5
    80005fca:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005fce:	6314                	ld	a3,0(a4)
    80005fd0:	96be                	add	a3,a3,a5
    80005fd2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005fd6:	6314                	ld	a3,0(a4)
    80005fd8:	96be                	add	a3,a3,a5
    80005fda:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005fde:	6318                	ld	a4,0(a4)
    80005fe0:	97ba                	add	a5,a5,a4
    80005fe2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005fe6:	0001d797          	auipc	a5,0x1d
    80005fea:	01a78793          	addi	a5,a5,26 # 80023000 <disk>
    80005fee:	97aa                	add	a5,a5,a0
    80005ff0:	6509                	lui	a0,0x2
    80005ff2:	953e                	add	a0,a0,a5
    80005ff4:	4785                	li	a5,1
    80005ff6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005ffa:	0001f517          	auipc	a0,0x1f
    80005ffe:	01e50513          	addi	a0,a0,30 # 80025018 <disk+0x2018>
    80006002:	ffffc097          	auipc	ra,0xffffc
    80006006:	4a8080e7          	jalr	1192(ra) # 800024aa <wakeup>
}
    8000600a:	60a2                	ld	ra,8(sp)
    8000600c:	6402                	ld	s0,0(sp)
    8000600e:	0141                	addi	sp,sp,16
    80006010:	8082                	ret
    panic("free_desc 1");
    80006012:	00002517          	auipc	a0,0x2
    80006016:	77e50513          	addi	a0,a0,1918 # 80008790 <syscalls+0x330>
    8000601a:	ffffa097          	auipc	ra,0xffffa
    8000601e:	524080e7          	jalr	1316(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006022:	00002517          	auipc	a0,0x2
    80006026:	77e50513          	addi	a0,a0,1918 # 800087a0 <syscalls+0x340>
    8000602a:	ffffa097          	auipc	ra,0xffffa
    8000602e:	514080e7          	jalr	1300(ra) # 8000053e <panic>

0000000080006032 <virtio_disk_init>:
{
    80006032:	1101                	addi	sp,sp,-32
    80006034:	ec06                	sd	ra,24(sp)
    80006036:	e822                	sd	s0,16(sp)
    80006038:	e426                	sd	s1,8(sp)
    8000603a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000603c:	00002597          	auipc	a1,0x2
    80006040:	77458593          	addi	a1,a1,1908 # 800087b0 <syscalls+0x350>
    80006044:	0001f517          	auipc	a0,0x1f
    80006048:	0e450513          	addi	a0,a0,228 # 80025128 <disk+0x2128>
    8000604c:	ffffb097          	auipc	ra,0xffffb
    80006050:	b08080e7          	jalr	-1272(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006054:	100017b7          	lui	a5,0x10001
    80006058:	4398                	lw	a4,0(a5)
    8000605a:	2701                	sext.w	a4,a4
    8000605c:	747277b7          	lui	a5,0x74727
    80006060:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006064:	0ef71163          	bne	a4,a5,80006146 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006068:	100017b7          	lui	a5,0x10001
    8000606c:	43dc                	lw	a5,4(a5)
    8000606e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006070:	4705                	li	a4,1
    80006072:	0ce79a63          	bne	a5,a4,80006146 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006076:	100017b7          	lui	a5,0x10001
    8000607a:	479c                	lw	a5,8(a5)
    8000607c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000607e:	4709                	li	a4,2
    80006080:	0ce79363          	bne	a5,a4,80006146 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006084:	100017b7          	lui	a5,0x10001
    80006088:	47d8                	lw	a4,12(a5)
    8000608a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000608c:	554d47b7          	lui	a5,0x554d4
    80006090:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006094:	0af71963          	bne	a4,a5,80006146 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006098:	100017b7          	lui	a5,0x10001
    8000609c:	4705                	li	a4,1
    8000609e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060a0:	470d                	li	a4,3
    800060a2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060a4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060a6:	c7ffe737          	lui	a4,0xc7ffe
    800060aa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800060ae:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060b0:	2701                	sext.w	a4,a4
    800060b2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060b4:	472d                	li	a4,11
    800060b6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060b8:	473d                	li	a4,15
    800060ba:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060bc:	6705                	lui	a4,0x1
    800060be:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060c0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060c4:	5bdc                	lw	a5,52(a5)
    800060c6:	2781                	sext.w	a5,a5
  if(max == 0)
    800060c8:	c7d9                	beqz	a5,80006156 <virtio_disk_init+0x124>
  if(max < NUM)
    800060ca:	471d                	li	a4,7
    800060cc:	08f77d63          	bgeu	a4,a5,80006166 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060d0:	100014b7          	lui	s1,0x10001
    800060d4:	47a1                	li	a5,8
    800060d6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060d8:	6609                	lui	a2,0x2
    800060da:	4581                	li	a1,0
    800060dc:	0001d517          	auipc	a0,0x1d
    800060e0:	f2450513          	addi	a0,a0,-220 # 80023000 <disk>
    800060e4:	ffffb097          	auipc	ra,0xffffb
    800060e8:	bfc080e7          	jalr	-1028(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800060ec:	0001d717          	auipc	a4,0x1d
    800060f0:	f1470713          	addi	a4,a4,-236 # 80023000 <disk>
    800060f4:	00c75793          	srli	a5,a4,0xc
    800060f8:	2781                	sext.w	a5,a5
    800060fa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800060fc:	0001f797          	auipc	a5,0x1f
    80006100:	f0478793          	addi	a5,a5,-252 # 80025000 <disk+0x2000>
    80006104:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006106:	0001d717          	auipc	a4,0x1d
    8000610a:	f7a70713          	addi	a4,a4,-134 # 80023080 <disk+0x80>
    8000610e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006110:	0001e717          	auipc	a4,0x1e
    80006114:	ef070713          	addi	a4,a4,-272 # 80024000 <disk+0x1000>
    80006118:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000611a:	4705                	li	a4,1
    8000611c:	00e78c23          	sb	a4,24(a5)
    80006120:	00e78ca3          	sb	a4,25(a5)
    80006124:	00e78d23          	sb	a4,26(a5)
    80006128:	00e78da3          	sb	a4,27(a5)
    8000612c:	00e78e23          	sb	a4,28(a5)
    80006130:	00e78ea3          	sb	a4,29(a5)
    80006134:	00e78f23          	sb	a4,30(a5)
    80006138:	00e78fa3          	sb	a4,31(a5)
}
    8000613c:	60e2                	ld	ra,24(sp)
    8000613e:	6442                	ld	s0,16(sp)
    80006140:	64a2                	ld	s1,8(sp)
    80006142:	6105                	addi	sp,sp,32
    80006144:	8082                	ret
    panic("could not find virtio disk");
    80006146:	00002517          	auipc	a0,0x2
    8000614a:	67a50513          	addi	a0,a0,1658 # 800087c0 <syscalls+0x360>
    8000614e:	ffffa097          	auipc	ra,0xffffa
    80006152:	3f0080e7          	jalr	1008(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006156:	00002517          	auipc	a0,0x2
    8000615a:	68a50513          	addi	a0,a0,1674 # 800087e0 <syscalls+0x380>
    8000615e:	ffffa097          	auipc	ra,0xffffa
    80006162:	3e0080e7          	jalr	992(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006166:	00002517          	auipc	a0,0x2
    8000616a:	69a50513          	addi	a0,a0,1690 # 80008800 <syscalls+0x3a0>
    8000616e:	ffffa097          	auipc	ra,0xffffa
    80006172:	3d0080e7          	jalr	976(ra) # 8000053e <panic>

0000000080006176 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006176:	7159                	addi	sp,sp,-112
    80006178:	f486                	sd	ra,104(sp)
    8000617a:	f0a2                	sd	s0,96(sp)
    8000617c:	eca6                	sd	s1,88(sp)
    8000617e:	e8ca                	sd	s2,80(sp)
    80006180:	e4ce                	sd	s3,72(sp)
    80006182:	e0d2                	sd	s4,64(sp)
    80006184:	fc56                	sd	s5,56(sp)
    80006186:	f85a                	sd	s6,48(sp)
    80006188:	f45e                	sd	s7,40(sp)
    8000618a:	f062                	sd	s8,32(sp)
    8000618c:	ec66                	sd	s9,24(sp)
    8000618e:	e86a                	sd	s10,16(sp)
    80006190:	1880                	addi	s0,sp,112
    80006192:	892a                	mv	s2,a0
    80006194:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006196:	00c52c83          	lw	s9,12(a0)
    8000619a:	001c9c9b          	slliw	s9,s9,0x1
    8000619e:	1c82                	slli	s9,s9,0x20
    800061a0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061a4:	0001f517          	auipc	a0,0x1f
    800061a8:	f8450513          	addi	a0,a0,-124 # 80025128 <disk+0x2128>
    800061ac:	ffffb097          	auipc	ra,0xffffb
    800061b0:	a38080e7          	jalr	-1480(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800061b4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061b6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800061b8:	0001db97          	auipc	s7,0x1d
    800061bc:	e48b8b93          	addi	s7,s7,-440 # 80023000 <disk>
    800061c0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800061c2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800061c4:	8a4e                	mv	s4,s3
    800061c6:	a051                	j	8000624a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800061c8:	00fb86b3          	add	a3,s7,a5
    800061cc:	96da                	add	a3,a3,s6
    800061ce:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800061d2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800061d4:	0207c563          	bltz	a5,800061fe <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061d8:	2485                	addiw	s1,s1,1
    800061da:	0711                	addi	a4,a4,4
    800061dc:	25548063          	beq	s1,s5,8000641c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800061e0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800061e2:	0001f697          	auipc	a3,0x1f
    800061e6:	e3668693          	addi	a3,a3,-458 # 80025018 <disk+0x2018>
    800061ea:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800061ec:	0006c583          	lbu	a1,0(a3)
    800061f0:	fde1                	bnez	a1,800061c8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800061f2:	2785                	addiw	a5,a5,1
    800061f4:	0685                	addi	a3,a3,1
    800061f6:	ff879be3          	bne	a5,s8,800061ec <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800061fa:	57fd                	li	a5,-1
    800061fc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800061fe:	02905a63          	blez	s1,80006232 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006202:	f9042503          	lw	a0,-112(s0)
    80006206:	00000097          	auipc	ra,0x0
    8000620a:	d90080e7          	jalr	-624(ra) # 80005f96 <free_desc>
      for(int j = 0; j < i; j++)
    8000620e:	4785                	li	a5,1
    80006210:	0297d163          	bge	a5,s1,80006232 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006214:	f9442503          	lw	a0,-108(s0)
    80006218:	00000097          	auipc	ra,0x0
    8000621c:	d7e080e7          	jalr	-642(ra) # 80005f96 <free_desc>
      for(int j = 0; j < i; j++)
    80006220:	4789                	li	a5,2
    80006222:	0097d863          	bge	a5,s1,80006232 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006226:	f9842503          	lw	a0,-104(s0)
    8000622a:	00000097          	auipc	ra,0x0
    8000622e:	d6c080e7          	jalr	-660(ra) # 80005f96 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006232:	0001f597          	auipc	a1,0x1f
    80006236:	ef658593          	addi	a1,a1,-266 # 80025128 <disk+0x2128>
    8000623a:	0001f517          	auipc	a0,0x1f
    8000623e:	dde50513          	addi	a0,a0,-546 # 80025018 <disk+0x2018>
    80006242:	ffffc097          	auipc	ra,0xffffc
    80006246:	0dc080e7          	jalr	220(ra) # 8000231e <sleep>
  for(int i = 0; i < 3; i++){
    8000624a:	f9040713          	addi	a4,s0,-112
    8000624e:	84ce                	mv	s1,s3
    80006250:	bf41                	j	800061e0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006252:	20058713          	addi	a4,a1,512
    80006256:	00471693          	slli	a3,a4,0x4
    8000625a:	0001d717          	auipc	a4,0x1d
    8000625e:	da670713          	addi	a4,a4,-602 # 80023000 <disk>
    80006262:	9736                	add	a4,a4,a3
    80006264:	4685                	li	a3,1
    80006266:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000626a:	20058713          	addi	a4,a1,512
    8000626e:	00471693          	slli	a3,a4,0x4
    80006272:	0001d717          	auipc	a4,0x1d
    80006276:	d8e70713          	addi	a4,a4,-626 # 80023000 <disk>
    8000627a:	9736                	add	a4,a4,a3
    8000627c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006280:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006284:	7679                	lui	a2,0xffffe
    80006286:	963e                	add	a2,a2,a5
    80006288:	0001f697          	auipc	a3,0x1f
    8000628c:	d7868693          	addi	a3,a3,-648 # 80025000 <disk+0x2000>
    80006290:	6298                	ld	a4,0(a3)
    80006292:	9732                	add	a4,a4,a2
    80006294:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006296:	6298                	ld	a4,0(a3)
    80006298:	9732                	add	a4,a4,a2
    8000629a:	4541                	li	a0,16
    8000629c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000629e:	6298                	ld	a4,0(a3)
    800062a0:	9732                	add	a4,a4,a2
    800062a2:	4505                	li	a0,1
    800062a4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800062a8:	f9442703          	lw	a4,-108(s0)
    800062ac:	6288                	ld	a0,0(a3)
    800062ae:	962a                	add	a2,a2,a0
    800062b0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062b4:	0712                	slli	a4,a4,0x4
    800062b6:	6290                	ld	a2,0(a3)
    800062b8:	963a                	add	a2,a2,a4
    800062ba:	05890513          	addi	a0,s2,88
    800062be:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800062c0:	6294                	ld	a3,0(a3)
    800062c2:	96ba                	add	a3,a3,a4
    800062c4:	40000613          	li	a2,1024
    800062c8:	c690                	sw	a2,8(a3)
  if(write)
    800062ca:	140d0063          	beqz	s10,8000640a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062ce:	0001f697          	auipc	a3,0x1f
    800062d2:	d326b683          	ld	a3,-718(a3) # 80025000 <disk+0x2000>
    800062d6:	96ba                	add	a3,a3,a4
    800062d8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062dc:	0001d817          	auipc	a6,0x1d
    800062e0:	d2480813          	addi	a6,a6,-732 # 80023000 <disk>
    800062e4:	0001f517          	auipc	a0,0x1f
    800062e8:	d1c50513          	addi	a0,a0,-740 # 80025000 <disk+0x2000>
    800062ec:	6114                	ld	a3,0(a0)
    800062ee:	96ba                	add	a3,a3,a4
    800062f0:	00c6d603          	lhu	a2,12(a3)
    800062f4:	00166613          	ori	a2,a2,1
    800062f8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062fc:	f9842683          	lw	a3,-104(s0)
    80006300:	6110                	ld	a2,0(a0)
    80006302:	9732                	add	a4,a4,a2
    80006304:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006308:	20058613          	addi	a2,a1,512
    8000630c:	0612                	slli	a2,a2,0x4
    8000630e:	9642                	add	a2,a2,a6
    80006310:	577d                	li	a4,-1
    80006312:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006316:	00469713          	slli	a4,a3,0x4
    8000631a:	6114                	ld	a3,0(a0)
    8000631c:	96ba                	add	a3,a3,a4
    8000631e:	03078793          	addi	a5,a5,48
    80006322:	97c2                	add	a5,a5,a6
    80006324:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006326:	611c                	ld	a5,0(a0)
    80006328:	97ba                	add	a5,a5,a4
    8000632a:	4685                	li	a3,1
    8000632c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000632e:	611c                	ld	a5,0(a0)
    80006330:	97ba                	add	a5,a5,a4
    80006332:	4809                	li	a6,2
    80006334:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006338:	611c                	ld	a5,0(a0)
    8000633a:	973e                	add	a4,a4,a5
    8000633c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006340:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006344:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006348:	6518                	ld	a4,8(a0)
    8000634a:	00275783          	lhu	a5,2(a4)
    8000634e:	8b9d                	andi	a5,a5,7
    80006350:	0786                	slli	a5,a5,0x1
    80006352:	97ba                	add	a5,a5,a4
    80006354:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006358:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000635c:	6518                	ld	a4,8(a0)
    8000635e:	00275783          	lhu	a5,2(a4)
    80006362:	2785                	addiw	a5,a5,1
    80006364:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006368:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000636c:	100017b7          	lui	a5,0x10001
    80006370:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006374:	00492703          	lw	a4,4(s2)
    80006378:	4785                	li	a5,1
    8000637a:	02f71163          	bne	a4,a5,8000639c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000637e:	0001f997          	auipc	s3,0x1f
    80006382:	daa98993          	addi	s3,s3,-598 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006386:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006388:	85ce                	mv	a1,s3
    8000638a:	854a                	mv	a0,s2
    8000638c:	ffffc097          	auipc	ra,0xffffc
    80006390:	f92080e7          	jalr	-110(ra) # 8000231e <sleep>
  while(b->disk == 1) {
    80006394:	00492783          	lw	a5,4(s2)
    80006398:	fe9788e3          	beq	a5,s1,80006388 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000639c:	f9042903          	lw	s2,-112(s0)
    800063a0:	20090793          	addi	a5,s2,512
    800063a4:	00479713          	slli	a4,a5,0x4
    800063a8:	0001d797          	auipc	a5,0x1d
    800063ac:	c5878793          	addi	a5,a5,-936 # 80023000 <disk>
    800063b0:	97ba                	add	a5,a5,a4
    800063b2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800063b6:	0001f997          	auipc	s3,0x1f
    800063ba:	c4a98993          	addi	s3,s3,-950 # 80025000 <disk+0x2000>
    800063be:	00491713          	slli	a4,s2,0x4
    800063c2:	0009b783          	ld	a5,0(s3)
    800063c6:	97ba                	add	a5,a5,a4
    800063c8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063cc:	854a                	mv	a0,s2
    800063ce:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063d2:	00000097          	auipc	ra,0x0
    800063d6:	bc4080e7          	jalr	-1084(ra) # 80005f96 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063da:	8885                	andi	s1,s1,1
    800063dc:	f0ed                	bnez	s1,800063be <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063de:	0001f517          	auipc	a0,0x1f
    800063e2:	d4a50513          	addi	a0,a0,-694 # 80025128 <disk+0x2128>
    800063e6:	ffffb097          	auipc	ra,0xffffb
    800063ea:	8b2080e7          	jalr	-1870(ra) # 80000c98 <release>
}
    800063ee:	70a6                	ld	ra,104(sp)
    800063f0:	7406                	ld	s0,96(sp)
    800063f2:	64e6                	ld	s1,88(sp)
    800063f4:	6946                	ld	s2,80(sp)
    800063f6:	69a6                	ld	s3,72(sp)
    800063f8:	6a06                	ld	s4,64(sp)
    800063fa:	7ae2                	ld	s5,56(sp)
    800063fc:	7b42                	ld	s6,48(sp)
    800063fe:	7ba2                	ld	s7,40(sp)
    80006400:	7c02                	ld	s8,32(sp)
    80006402:	6ce2                	ld	s9,24(sp)
    80006404:	6d42                	ld	s10,16(sp)
    80006406:	6165                	addi	sp,sp,112
    80006408:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000640a:	0001f697          	auipc	a3,0x1f
    8000640e:	bf66b683          	ld	a3,-1034(a3) # 80025000 <disk+0x2000>
    80006412:	96ba                	add	a3,a3,a4
    80006414:	4609                	li	a2,2
    80006416:	00c69623          	sh	a2,12(a3)
    8000641a:	b5c9                	j	800062dc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000641c:	f9042583          	lw	a1,-112(s0)
    80006420:	20058793          	addi	a5,a1,512
    80006424:	0792                	slli	a5,a5,0x4
    80006426:	0001d517          	auipc	a0,0x1d
    8000642a:	c8250513          	addi	a0,a0,-894 # 800230a8 <disk+0xa8>
    8000642e:	953e                	add	a0,a0,a5
  if(write)
    80006430:	e20d11e3          	bnez	s10,80006252 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006434:	20058713          	addi	a4,a1,512
    80006438:	00471693          	slli	a3,a4,0x4
    8000643c:	0001d717          	auipc	a4,0x1d
    80006440:	bc470713          	addi	a4,a4,-1084 # 80023000 <disk>
    80006444:	9736                	add	a4,a4,a3
    80006446:	0a072423          	sw	zero,168(a4)
    8000644a:	b505                	j	8000626a <virtio_disk_rw+0xf4>

000000008000644c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000644c:	1101                	addi	sp,sp,-32
    8000644e:	ec06                	sd	ra,24(sp)
    80006450:	e822                	sd	s0,16(sp)
    80006452:	e426                	sd	s1,8(sp)
    80006454:	e04a                	sd	s2,0(sp)
    80006456:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006458:	0001f517          	auipc	a0,0x1f
    8000645c:	cd050513          	addi	a0,a0,-816 # 80025128 <disk+0x2128>
    80006460:	ffffa097          	auipc	ra,0xffffa
    80006464:	784080e7          	jalr	1924(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006468:	10001737          	lui	a4,0x10001
    8000646c:	533c                	lw	a5,96(a4)
    8000646e:	8b8d                	andi	a5,a5,3
    80006470:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006472:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006476:	0001f797          	auipc	a5,0x1f
    8000647a:	b8a78793          	addi	a5,a5,-1142 # 80025000 <disk+0x2000>
    8000647e:	6b94                	ld	a3,16(a5)
    80006480:	0207d703          	lhu	a4,32(a5)
    80006484:	0026d783          	lhu	a5,2(a3)
    80006488:	06f70163          	beq	a4,a5,800064ea <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000648c:	0001d917          	auipc	s2,0x1d
    80006490:	b7490913          	addi	s2,s2,-1164 # 80023000 <disk>
    80006494:	0001f497          	auipc	s1,0x1f
    80006498:	b6c48493          	addi	s1,s1,-1172 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000649c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064a0:	6898                	ld	a4,16(s1)
    800064a2:	0204d783          	lhu	a5,32(s1)
    800064a6:	8b9d                	andi	a5,a5,7
    800064a8:	078e                	slli	a5,a5,0x3
    800064aa:	97ba                	add	a5,a5,a4
    800064ac:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064ae:	20078713          	addi	a4,a5,512
    800064b2:	0712                	slli	a4,a4,0x4
    800064b4:	974a                	add	a4,a4,s2
    800064b6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800064ba:	e731                	bnez	a4,80006506 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064bc:	20078793          	addi	a5,a5,512
    800064c0:	0792                	slli	a5,a5,0x4
    800064c2:	97ca                	add	a5,a5,s2
    800064c4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800064c6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064ca:	ffffc097          	auipc	ra,0xffffc
    800064ce:	fe0080e7          	jalr	-32(ra) # 800024aa <wakeup>

    disk.used_idx += 1;
    800064d2:	0204d783          	lhu	a5,32(s1)
    800064d6:	2785                	addiw	a5,a5,1
    800064d8:	17c2                	slli	a5,a5,0x30
    800064da:	93c1                	srli	a5,a5,0x30
    800064dc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064e0:	6898                	ld	a4,16(s1)
    800064e2:	00275703          	lhu	a4,2(a4)
    800064e6:	faf71be3          	bne	a4,a5,8000649c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800064ea:	0001f517          	auipc	a0,0x1f
    800064ee:	c3e50513          	addi	a0,a0,-962 # 80025128 <disk+0x2128>
    800064f2:	ffffa097          	auipc	ra,0xffffa
    800064f6:	7a6080e7          	jalr	1958(ra) # 80000c98 <release>
}
    800064fa:	60e2                	ld	ra,24(sp)
    800064fc:	6442                	ld	s0,16(sp)
    800064fe:	64a2                	ld	s1,8(sp)
    80006500:	6902                	ld	s2,0(sp)
    80006502:	6105                	addi	sp,sp,32
    80006504:	8082                	ret
      panic("virtio_disk_intr status");
    80006506:	00002517          	auipc	a0,0x2
    8000650a:	31a50513          	addi	a0,a0,794 # 80008820 <syscalls+0x3c0>
    8000650e:	ffffa097          	auipc	ra,0xffffa
    80006512:	030080e7          	jalr	48(ra) # 8000053e <panic>
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
