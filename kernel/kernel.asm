
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ab013103          	ld	sp,-1360(sp) # 80008ab0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	21c78793          	addi	a5,a5,540 # 80006280 <timervec>
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
    80000130:	528080e7          	jalr	1320(ra) # 80002654 <either_copyin>
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
    800001c8:	ac8080e7          	jalr	-1336(ra) # 80001c8c <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	206080e7          	jalr	518(ra) # 800023da <sleep>
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
    80000214:	3ee080e7          	jalr	1006(ra) # 800025fe <either_copyout>
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
    800002f6:	3b8080e7          	jalr	952(ra) # 800026aa <procdump>
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
    8000044a:	5aa080e7          	jalr	1450(ra) # 800029f0 <wakeup>
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
    80000570:	db450513          	addi	a0,a0,-588 # 80008320 <digits+0x2e0>
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
    800008a4:	150080e7          	jalr	336(ra) # 800029f0 <wakeup>
    
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
    80000930:	aae080e7          	jalr	-1362(ra) # 800023da <sleep>
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
    80000b82:	0ec080e7          	jalr	236(ra) # 80001c6a <mycpu>
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
    80000bb4:	0ba080e7          	jalr	186(ra) # 80001c6a <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	0ae080e7          	jalr	174(ra) # 80001c6a <mycpu>
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
    80000bd8:	096080e7          	jalr	150(ra) # 80001c6a <mycpu>
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
    80000c18:	056080e7          	jalr	86(ra) # 80001c6a <mycpu>
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
    80000c44:	02a080e7          	jalr	42(ra) # 80001c6a <mycpu>
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
    80000e9a:	dc4080e7          	jalr	-572(ra) # 80001c5a <cpuid>
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
    80000eb6:	da8080e7          	jalr	-600(ra) # 80001c5a <cpuid>
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
    80000ed8:	e0e080e7          	jalr	-498(ra) # 80002ce2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	3e4080e7          	jalr	996(ra) # 800062c0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	280080e7          	jalr	640(ra) # 80002164 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	42450513          	addi	a0,a0,1060 # 80008320 <digits+0x2e0>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	40450513          	addi	a0,a0,1028 # 80008320 <digits+0x2e0>
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
    80000f48:	c14080e7          	jalr	-1004(ra) # 80001b58 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	d6e080e7          	jalr	-658(ra) # 80002cba <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	d8e080e7          	jalr	-626(ra) # 80002ce2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	34e080e7          	jalr	846(ra) # 800062aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	35c080e7          	jalr	860(ra) # 800062c0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	534080e7          	jalr	1332(ra) # 800034a0 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	bc4080e7          	jalr	-1084(ra) # 80003b38 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	b6e080e7          	jalr	-1170(ra) # 80004aea <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	45e080e7          	jalr	1118(ra) # 800063e2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	0bc080e7          	jalr	188(ra) # 80002048 <userinit>
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
    80001244:	882080e7          	jalr	-1918(ra) # 80001ac2 <proc_mapstacks>
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

00000000800018c0 <initialize_list>:


void initialize_list(struct _list *lst){
    800018c0:	1141                	addi	sp,sp,-16
    800018c2:	e422                	sd	s0,8(sp)
    800018c4:	0800                	addi	s0,sp,16
  /*
  int curr_tail = lst->tail;
  if(cas(&lst->tail, curr_tail, -1)){ // if lst is empty
    lst->head = p-> index; */
  lst->head = -1;
    800018c6:	57fd                	li	a5,-1
    800018c8:	c11c                	sw	a5,0(a0)
  lst->tail = -1;
    800018ca:	c15c                	sw	a5,4(a0)
}
    800018cc:	6422                	ld	s0,8(sp)
    800018ce:	0141                	addi	sp,sp,16
    800018d0:	8082                	ret

00000000800018d2 <initialize_runnable_lists>:

void initialize_runnable_lists(void){
    800018d2:	1141                	addi	sp,sp,-16
    800018d4:	e422                	sd	s0,8(sp)
    800018d6:	0800                	addi	s0,sp,16
  struct cpu *c;
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    800018d8:	00010797          	auipc	a5,0x10
    800018dc:	9c878793          	addi	a5,a5,-1592 # 800112a0 <cpus>
    c->runnable_list = (struct _list){-1, -1};
    800018e0:	577d                	li	a4,-1
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    800018e2:	00010697          	auipc	a3,0x10
    800018e6:	e7e68693          	addi	a3,a3,-386 # 80011760 <pid_lock>
    c->runnable_list = (struct _list){-1, -1};
    800018ea:	08e7a023          	sw	a4,128(a5)
    800018ee:	08e7a223          	sw	a4,132(a5)
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    800018f2:	09878793          	addi	a5,a5,152
    800018f6:	fed79ae3          	bne	a5,a3,800018ea <initialize_runnable_lists+0x18>
  }
}
    800018fa:	6422                	ld	s0,8(sp)
    800018fc:	0141                	addi	sp,sp,16
    800018fe:	8082                	ret

0000000080001900 <initialize_proc>:

void
initialize_proc(struct proc *p){
    80001900:	1141                	addi	sp,sp,-16
    80001902:	e422                	sd	s0,8(sp)
    80001904:	0800                	addi	s0,sp,16
  p->next_index = -1;
    80001906:	57fd                	li	a5,-1
    80001908:	16f52a23          	sw	a5,372(a0)
  p->prev_index = -1;
    8000190c:	16f52823          	sw	a5,368(a0)
}
    80001910:	6422                	ld	s0,8(sp)
    80001912:	0141                	addi	sp,sp,16
    80001914:	8082                	ret

0000000080001916 <isEmpty>:

int
isEmpty(struct _list *lst){
    80001916:	1141                	addi	sp,sp,-16
    80001918:	e422                	sd	s0,8(sp)
    8000191a:	0800                	addi	s0,sp,16
  return lst->head == -1;
    8000191c:	4108                	lw	a0,0(a0)
    8000191e:	0505                	addi	a0,a0,1
}
    80001920:	00153513          	seqz	a0,a0
    80001924:	6422                	ld	s0,8(sp)
    80001926:	0141                	addi	sp,sp,16
    80001928:	8082                	ret

000000008000192a <insert_proc_to_list>:
  print_list(*lst); // delete
}
*/

void 
insert_proc_to_list(struct _list *lst, struct proc *p){
    8000192a:	1101                	addi	sp,sp,-32
    8000192c:	ec06                	sd	ra,24(sp)
    8000192e:	e822                	sd	s0,16(sp)
    80001930:	e426                	sd	s1,8(sp)
    80001932:	e04a                	sd	s2,0(sp)
    80001934:	1000                	addi	s0,sp,32
    80001936:	84aa                	mv	s1,a0
    80001938:	892e                	mv	s2,a1
  printf("before insert: \n");
    8000193a:	00007517          	auipc	a0,0x7
    8000193e:	8b650513          	addi	a0,a0,-1866 # 800081f0 <digits+0x1b0>
    80001942:	fffff097          	auipc	ra,0xfffff
    80001946:	c46080e7          	jalr	-954(ra) # 80000588 <printf>
  print_list(*lst); // delete
    8000194a:	0004e503          	lwu	a0,0(s1)
    8000194e:	0044e783          	lwu	a5,4(s1)
    80001952:	1782                	slli	a5,a5,0x20
    80001954:	8d5d                	or	a0,a0,a5
    80001956:	00000097          	auipc	ra,0x0
    8000195a:	ee8080e7          	jalr	-280(ra) # 8000183e <print_list>

  if(isEmpty(lst)){
    8000195e:	4098                	lw	a4,0(s1)
    80001960:	57fd                	li	a5,-1
    80001962:	04f71063          	bne	a4,a5,800019a2 <insert_proc_to_list+0x78>
    lst->head = p->index;
    80001966:	16c92783          	lw	a5,364(s2) # 116c <_entry-0x7fffee94>
    8000196a:	c09c                	sw	a5,0(s1)
    lst->tail = p-> index;
    8000196c:	16c92783          	lw	a5,364(s2)
    80001970:	c0dc                	sw	a5,4(s1)
    struct proc *p_tail = &proc[lst->tail];
    p_tail->next_index = p->index; // update next proc of the curr tail
    p->prev_index = p_tail->index; // update the prev proc of the new proc
    lst->tail = p->index;          // update tail
  }
  printf("after insert: \n");
    80001972:	00007517          	auipc	a0,0x7
    80001976:	89650513          	addi	a0,a0,-1898 # 80008208 <digits+0x1c8>
    8000197a:	fffff097          	auipc	ra,0xfffff
    8000197e:	c0e080e7          	jalr	-1010(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001982:	0004e503          	lwu	a0,0(s1)
    80001986:	0044e783          	lwu	a5,4(s1)
    8000198a:	1782                	slli	a5,a5,0x20
    8000198c:	8d5d                	or	a0,a0,a5
    8000198e:	00000097          	auipc	ra,0x0
    80001992:	eb0080e7          	jalr	-336(ra) # 8000183e <print_list>
}
    80001996:	60e2                	ld	ra,24(sp)
    80001998:	6442                	ld	s0,16(sp)
    8000199a:	64a2                	ld	s1,8(sp)
    8000199c:	6902                	ld	s2,0(sp)
    8000199e:	6105                	addi	sp,sp,32
    800019a0:	8082                	ret
    struct proc *p_tail = &proc[lst->tail];
    800019a2:	40dc                	lw	a5,4(s1)
    p_tail->next_index = p->index; // update next proc of the curr tail
    800019a4:	16c92683          	lw	a3,364(s2)
    800019a8:	17800713          	li	a4,376
    800019ac:	02e78733          	mul	a4,a5,a4
    800019b0:	00010797          	auipc	a5,0x10
    800019b4:	de078793          	addi	a5,a5,-544 # 80011790 <proc>
    800019b8:	97ba                	add	a5,a5,a4
    800019ba:	16d7aa23          	sw	a3,372(a5)
    p->prev_index = p_tail->index; // update the prev proc of the new proc
    800019be:	16c7a783          	lw	a5,364(a5)
    800019c2:	16f92823          	sw	a5,368(s2)
    lst->tail = p->index;          // update tail
    800019c6:	c0d4                	sw	a3,4(s1)
    800019c8:	b76d                	j	80001972 <insert_proc_to_list+0x48>

00000000800019ca <remove_proc_to_list>:

void 
remove_proc_to_list(struct _list *lst, struct proc *p){
    800019ca:	1101                	addi	sp,sp,-32
    800019cc:	ec06                	sd	ra,24(sp)
    800019ce:	e822                	sd	s0,16(sp)
    800019d0:	e426                	sd	s1,8(sp)
    800019d2:	e04a                	sd	s2,0(sp)
    800019d4:	1000                	addi	s0,sp,32
    800019d6:	84aa                	mv	s1,a0
    800019d8:	892e                	mv	s2,a1
  printf("before insert: \n");
    800019da:	00007517          	auipc	a0,0x7
    800019de:	81650513          	addi	a0,a0,-2026 # 800081f0 <digits+0x1b0>
    800019e2:	fffff097          	auipc	ra,0xfffff
    800019e6:	ba6080e7          	jalr	-1114(ra) # 80000588 <printf>
  print_list(*lst); // delete
    800019ea:	0004e503          	lwu	a0,0(s1)
    800019ee:	0044e783          	lwu	a5,4(s1)
    800019f2:	1782                	slli	a5,a5,0x20
    800019f4:	8d5d                	or	a0,a0,a5
    800019f6:	00000097          	auipc	ra,0x0
    800019fa:	e48080e7          	jalr	-440(ra) # 8000183e <print_list>
  if(lst->head == p->index && lst->tail == p->index) // p is the only proc in the list
    800019fe:	16c92783          	lw	a5,364(s2)
    80001a02:	4098                	lw	a4,0(s1)
    80001a04:	06f70863          	beq	a4,a5,80001a74 <remove_proc_to_list+0xaa>
    initialize_list(lst);
  else if(lst->head == p->index) {  // p is the head of the list
    lst->head = p->next_index;
    proc[lst->head].prev_index = -1;
  }
  else if(lst->tail == p->index) { // p is the tail of the list
    80001a08:	40d8                	lw	a4,4(s1)
    80001a0a:	08f70c63          	beq	a4,a5,80001aa2 <remove_proc_to_list+0xd8>
    lst->tail = p->prev_index;
    proc[lst->tail].next_index = -1;
     }
  else {
    proc[p->prev_index].next_index = p->next_index;
    80001a0e:	17092783          	lw	a5,368(s2)
    80001a12:	17492683          	lw	a3,372(s2)
    80001a16:	00010717          	auipc	a4,0x10
    80001a1a:	d7a70713          	addi	a4,a4,-646 # 80011790 <proc>
    80001a1e:	17800613          	li	a2,376
    80001a22:	02c787b3          	mul	a5,a5,a2
    80001a26:	97ba                	add	a5,a5,a4
    80001a28:	16d7aa23          	sw	a3,372(a5)
    proc[p->next_index].prev_index = p->prev_index;
    80001a2c:	17092783          	lw	a5,368(s2)
    80001a30:	02c686b3          	mul	a3,a3,a2
    80001a34:	9736                	add	a4,a4,a3
    80001a36:	16f72823          	sw	a5,368(a4)
  p->next_index = -1;
    80001a3a:	57fd                	li	a5,-1
    80001a3c:	16f92a23          	sw	a5,372(s2)
  p->prev_index = -1;
    80001a40:	16f92823          	sw	a5,368(s2)
  }
  initialize_proc(p);

  printf("after remove: \n");
    80001a44:	00006517          	auipc	a0,0x6
    80001a48:	7d450513          	addi	a0,a0,2004 # 80008218 <digits+0x1d8>
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	b3c080e7          	jalr	-1220(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001a54:	0004e503          	lwu	a0,0(s1)
    80001a58:	0044e783          	lwu	a5,4(s1)
    80001a5c:	1782                	slli	a5,a5,0x20
    80001a5e:	8d5d                	or	a0,a0,a5
    80001a60:	00000097          	auipc	ra,0x0
    80001a64:	dde080e7          	jalr	-546(ra) # 8000183e <print_list>
}
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret
  if(lst->head == p->index && lst->tail == p->index) // p is the only proc in the list
    80001a74:	40d8                	lw	a4,4(s1)
    80001a76:	02f70263          	beq	a4,a5,80001a9a <remove_proc_to_list+0xd0>
    lst->head = p->next_index;
    80001a7a:	17492783          	lw	a5,372(s2)
    80001a7e:	c09c                	sw	a5,0(s1)
    proc[lst->head].prev_index = -1;
    80001a80:	17800713          	li	a4,376
    80001a84:	02e787b3          	mul	a5,a5,a4
    80001a88:	00010717          	auipc	a4,0x10
    80001a8c:	d0870713          	addi	a4,a4,-760 # 80011790 <proc>
    80001a90:	97ba                	add	a5,a5,a4
    80001a92:	577d                	li	a4,-1
    80001a94:	16e7a823          	sw	a4,368(a5)
    80001a98:	b74d                	j	80001a3a <remove_proc_to_list+0x70>
  lst->head = -1;
    80001a9a:	57fd                	li	a5,-1
    80001a9c:	c09c                	sw	a5,0(s1)
  lst->tail = -1;
    80001a9e:	c0dc                	sw	a5,4(s1)
}
    80001aa0:	bf69                	j	80001a3a <remove_proc_to_list+0x70>
    lst->tail = p->prev_index;
    80001aa2:	17092783          	lw	a5,368(s2)
    80001aa6:	c0dc                	sw	a5,4(s1)
    proc[lst->tail].next_index = -1;
    80001aa8:	17800713          	li	a4,376
    80001aac:	02e787b3          	mul	a5,a5,a4
    80001ab0:	00010717          	auipc	a4,0x10
    80001ab4:	ce070713          	addi	a4,a4,-800 # 80011790 <proc>
    80001ab8:	97ba                	add	a5,a5,a4
    80001aba:	577d                	li	a4,-1
    80001abc:	16e7aa23          	sw	a4,372(a5)
    80001ac0:	bfad                	j	80001a3a <remove_proc_to_list+0x70>

0000000080001ac2 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001ac2:	7139                	addi	sp,sp,-64
    80001ac4:	fc06                	sd	ra,56(sp)
    80001ac6:	f822                	sd	s0,48(sp)
    80001ac8:	f426                	sd	s1,40(sp)
    80001aca:	f04a                	sd	s2,32(sp)
    80001acc:	ec4e                	sd	s3,24(sp)
    80001ace:	e852                	sd	s4,16(sp)
    80001ad0:	e456                	sd	s5,8(sp)
    80001ad2:	e05a                	sd	s6,0(sp)
    80001ad4:	0080                	addi	s0,sp,64
    80001ad6:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ad8:	00010497          	auipc	s1,0x10
    80001adc:	cb848493          	addi	s1,s1,-840 # 80011790 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001ae0:	8b26                	mv	s6,s1
    80001ae2:	00006a97          	auipc	s5,0x6
    80001ae6:	51ea8a93          	addi	s5,s5,1310 # 80008000 <etext>
    80001aea:	04000937          	lui	s2,0x4000
    80001aee:	197d                	addi	s2,s2,-1
    80001af0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001af2:	00016a17          	auipc	s4,0x16
    80001af6:	a9ea0a13          	addi	s4,s4,-1378 # 80017590 <tickslock>
    char *pa = kalloc();
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	ffa080e7          	jalr	-6(ra) # 80000af4 <kalloc>
    80001b02:	862a                	mv	a2,a0
    if(pa == 0)
    80001b04:	c131                	beqz	a0,80001b48 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001b06:	416485b3          	sub	a1,s1,s6
    80001b0a:	858d                	srai	a1,a1,0x3
    80001b0c:	000ab783          	ld	a5,0(s5)
    80001b10:	02f585b3          	mul	a1,a1,a5
    80001b14:	2585                	addiw	a1,a1,1
    80001b16:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b1a:	4719                	li	a4,6
    80001b1c:	6685                	lui	a3,0x1
    80001b1e:	40b905b3          	sub	a1,s2,a1
    80001b22:	854e                	mv	a0,s3
    80001b24:	fffff097          	auipc	ra,0xfffff
    80001b28:	62c080e7          	jalr	1580(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b2c:	17848493          	addi	s1,s1,376
    80001b30:	fd4495e3          	bne	s1,s4,80001afa <proc_mapstacks+0x38>
  }
}
    80001b34:	70e2                	ld	ra,56(sp)
    80001b36:	7442                	ld	s0,48(sp)
    80001b38:	74a2                	ld	s1,40(sp)
    80001b3a:	7902                	ld	s2,32(sp)
    80001b3c:	69e2                	ld	s3,24(sp)
    80001b3e:	6a42                	ld	s4,16(sp)
    80001b40:	6aa2                	ld	s5,8(sp)
    80001b42:	6b02                	ld	s6,0(sp)
    80001b44:	6121                	addi	sp,sp,64
    80001b46:	8082                	ret
      panic("kalloc");
    80001b48:	00006517          	auipc	a0,0x6
    80001b4c:	6e050513          	addi	a0,a0,1760 # 80008228 <digits+0x1e8>
    80001b50:	fffff097          	auipc	ra,0xfffff
    80001b54:	9ee080e7          	jalr	-1554(ra) # 8000053e <panic>

0000000080001b58 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001b58:	711d                	addi	sp,sp,-96
    80001b5a:	ec86                	sd	ra,88(sp)
    80001b5c:	e8a2                	sd	s0,80(sp)
    80001b5e:	e4a6                	sd	s1,72(sp)
    80001b60:	e0ca                	sd	s2,64(sp)
    80001b62:	fc4e                	sd	s3,56(sp)
    80001b64:	f852                	sd	s4,48(sp)
    80001b66:	f456                	sd	s5,40(sp)
    80001b68:	f05a                	sd	s6,32(sp)
    80001b6a:	ec5e                	sd	s7,24(sp)
    80001b6c:	e862                	sd	s8,16(sp)
    80001b6e:	e466                	sd	s9,8(sp)
    80001b70:	e06a                	sd	s10,0(sp)
    80001b72:	1080                	addi	s0,sp,96
  struct proc *p;

  initialize_runnable_lists();
    80001b74:	00000097          	auipc	ra,0x0
    80001b78:	d5e080e7          	jalr	-674(ra) # 800018d2 <initialize_runnable_lists>

  initlock(&pid_lock, "nextpid");
    80001b7c:	00006597          	auipc	a1,0x6
    80001b80:	6b458593          	addi	a1,a1,1716 # 80008230 <digits+0x1f0>
    80001b84:	00010517          	auipc	a0,0x10
    80001b88:	bdc50513          	addi	a0,a0,-1060 # 80011760 <pid_lock>
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	fc8080e7          	jalr	-56(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b94:	00006597          	auipc	a1,0x6
    80001b98:	6a458593          	addi	a1,a1,1700 # 80008238 <digits+0x1f8>
    80001b9c:	00010517          	auipc	a0,0x10
    80001ba0:	bdc50513          	addi	a0,a0,-1060 # 80011778 <wait_lock>
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	fb0080e7          	jalr	-80(ra) # 80000b54 <initlock>

  int i = 0;
    80001bac:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bae:	00010497          	auipc	s1,0x10
    80001bb2:	be248493          	addi	s1,s1,-1054 # 80011790 <proc>
      initlock(&p->lock, "proc");
    80001bb6:	00006d17          	auipc	s10,0x6
    80001bba:	692d0d13          	addi	s10,s10,1682 # 80008248 <digits+0x208>
      p->kstack = KSTACK((int) (p - proc));
    80001bbe:	8ca6                	mv	s9,s1
    80001bc0:	00006c17          	auipc	s8,0x6
    80001bc4:	440c0c13          	addi	s8,s8,1088 # 80008000 <etext>
    80001bc8:	04000a37          	lui	s4,0x4000
    80001bcc:	1a7d                	addi	s4,s4,-1
    80001bce:	0a32                	slli	s4,s4,0xc
  p->next_index = -1;
    80001bd0:	59fd                	li	s3,-1
      p->index = i;
      initialize_proc(p);
      printf("insert procinit unused %d\n", p->index); //delete
    80001bd2:	00006b97          	auipc	s7,0x6
    80001bd6:	67eb8b93          	addi	s7,s7,1662 # 80008250 <digits+0x210>
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001bda:	00007b17          	auipc	s6,0x7
    80001bde:	e7eb0b13          	addi	s6,s6,-386 # 80008a58 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be2:	00016a97          	auipc	s5,0x16
    80001be6:	9aea8a93          	addi	s5,s5,-1618 # 80017590 <tickslock>
      initlock(&p->lock, "proc");
    80001bea:	85ea                	mv	a1,s10
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	f66080e7          	jalr	-154(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001bf6:	419487b3          	sub	a5,s1,s9
    80001bfa:	878d                	srai	a5,a5,0x3
    80001bfc:	000c3703          	ld	a4,0(s8)
    80001c00:	02e787b3          	mul	a5,a5,a4
    80001c04:	2785                	addiw	a5,a5,1
    80001c06:	00d7979b          	slliw	a5,a5,0xd
    80001c0a:	40fa07b3          	sub	a5,s4,a5
    80001c0e:	e0bc                	sd	a5,64(s1)
      p->index = i;
    80001c10:	1724a623          	sw	s2,364(s1)
  p->next_index = -1;
    80001c14:	1734aa23          	sw	s3,372(s1)
  p->prev_index = -1;
    80001c18:	1734a823          	sw	s3,368(s1)
      printf("insert procinit unused %d\n", p->index); //delete
    80001c1c:	85ca                	mv	a1,s2
    80001c1e:	855e                	mv	a0,s7
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	968080e7          	jalr	-1688(ra) # 80000588 <printf>
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001c28:	85a6                	mv	a1,s1
    80001c2a:	855a                	mv	a0,s6
    80001c2c:	00000097          	auipc	ra,0x0
    80001c30:	cfe080e7          	jalr	-770(ra) # 8000192a <insert_proc_to_list>
      i++;
    80001c34:	2905                	addiw	s2,s2,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c36:	17848493          	addi	s1,s1,376
    80001c3a:	fb5498e3          	bne	s1,s5,80001bea <procinit+0x92>
  }
}
    80001c3e:	60e6                	ld	ra,88(sp)
    80001c40:	6446                	ld	s0,80(sp)
    80001c42:	64a6                	ld	s1,72(sp)
    80001c44:	6906                	ld	s2,64(sp)
    80001c46:	79e2                	ld	s3,56(sp)
    80001c48:	7a42                	ld	s4,48(sp)
    80001c4a:	7aa2                	ld	s5,40(sp)
    80001c4c:	7b02                	ld	s6,32(sp)
    80001c4e:	6be2                	ld	s7,24(sp)
    80001c50:	6c42                	ld	s8,16(sp)
    80001c52:	6ca2                	ld	s9,8(sp)
    80001c54:	6d02                	ld	s10,0(sp)
    80001c56:	6125                	addi	sp,sp,96
    80001c58:	8082                	ret

0000000080001c5a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001c5a:	1141                	addi	sp,sp,-16
    80001c5c:	e422                	sd	s0,8(sp)
    80001c5e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c60:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001c62:	2501                	sext.w	a0,a0
    80001c64:	6422                	ld	s0,8(sp)
    80001c66:	0141                	addi	sp,sp,16
    80001c68:	8082                	ret

0000000080001c6a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001c6a:	1141                	addi	sp,sp,-16
    80001c6c:	e422                	sd	s0,8(sp)
    80001c6e:	0800                	addi	s0,sp,16
    80001c70:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001c72:	2781                	sext.w	a5,a5
    80001c74:	09800513          	li	a0,152
    80001c78:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001c7c:	0000f517          	auipc	a0,0xf
    80001c80:	62450513          	addi	a0,a0,1572 # 800112a0 <cpus>
    80001c84:	953e                	add	a0,a0,a5
    80001c86:	6422                	ld	s0,8(sp)
    80001c88:	0141                	addi	sp,sp,16
    80001c8a:	8082                	ret

0000000080001c8c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001c8c:	1101                	addi	sp,sp,-32
    80001c8e:	ec06                	sd	ra,24(sp)
    80001c90:	e822                	sd	s0,16(sp)
    80001c92:	e426                	sd	s1,8(sp)
    80001c94:	1000                	addi	s0,sp,32
  push_off();
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	f02080e7          	jalr	-254(ra) # 80000b98 <push_off>
    80001c9e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ca0:	2781                	sext.w	a5,a5
    80001ca2:	09800713          	li	a4,152
    80001ca6:	02e787b3          	mul	a5,a5,a4
    80001caa:	0000f717          	auipc	a4,0xf
    80001cae:	5f670713          	addi	a4,a4,1526 # 800112a0 <cpus>
    80001cb2:	97ba                	add	a5,a5,a4
    80001cb4:	6384                	ld	s1,0(a5)
  pop_off();
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	f82080e7          	jalr	-126(ra) # 80000c38 <pop_off>
  return p;
}
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	60e2                	ld	ra,24(sp)
    80001cc2:	6442                	ld	s0,16(sp)
    80001cc4:	64a2                	ld	s1,8(sp)
    80001cc6:	6105                	addi	sp,sp,32
    80001cc8:	8082                	ret

0000000080001cca <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001cca:	1141                	addi	sp,sp,-16
    80001ccc:	e406                	sd	ra,8(sp)
    80001cce:	e022                	sd	s0,0(sp)
    80001cd0:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001cd2:	00000097          	auipc	ra,0x0
    80001cd6:	fba080e7          	jalr	-70(ra) # 80001c8c <myproc>
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	fbe080e7          	jalr	-66(ra) # 80000c98 <release>

  if (first) {
    80001ce2:	00007797          	auipc	a5,0x7
    80001ce6:	d5e7a783          	lw	a5,-674(a5) # 80008a40 <first.1753>
    80001cea:	eb89                	bnez	a5,80001cfc <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001cec:	00001097          	auipc	ra,0x1
    80001cf0:	00e080e7          	jalr	14(ra) # 80002cfa <usertrapret>
}
    80001cf4:	60a2                	ld	ra,8(sp)
    80001cf6:	6402                	ld	s0,0(sp)
    80001cf8:	0141                	addi	sp,sp,16
    80001cfa:	8082                	ret
    first = 0;
    80001cfc:	00007797          	auipc	a5,0x7
    80001d00:	d407a223          	sw	zero,-700(a5) # 80008a40 <first.1753>
    fsinit(ROOTDEV);
    80001d04:	4505                	li	a0,1
    80001d06:	00002097          	auipc	ra,0x2
    80001d0a:	db2080e7          	jalr	-590(ra) # 80003ab8 <fsinit>
    80001d0e:	bff9                	j	80001cec <forkret+0x22>

0000000080001d10 <allocpid>:
allocpid() {
    80001d10:	1101                	addi	sp,sp,-32
    80001d12:	ec06                	sd	ra,24(sp)
    80001d14:	e822                	sd	s0,16(sp)
    80001d16:	e426                	sd	s1,8(sp)
    80001d18:	e04a                	sd	s2,0(sp)
    80001d1a:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001d1c:	00007917          	auipc	s2,0x7
    80001d20:	d4490913          	addi	s2,s2,-700 # 80008a60 <nextpid>
    80001d24:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, nextpid + 1));
    80001d28:	0014861b          	addiw	a2,s1,1
    80001d2c:	85a6                	mv	a1,s1
    80001d2e:	854a                	mv	a0,s2
    80001d30:	00005097          	auipc	ra,0x5
    80001d34:	b96080e7          	jalr	-1130(ra) # 800068c6 <cas>
    80001d38:	2501                	sext.w	a0,a0
    80001d3a:	f56d                	bnez	a0,80001d24 <allocpid+0x14>
}
    80001d3c:	8526                	mv	a0,s1
    80001d3e:	60e2                	ld	ra,24(sp)
    80001d40:	6442                	ld	s0,16(sp)
    80001d42:	64a2                	ld	s1,8(sp)
    80001d44:	6902                	ld	s2,0(sp)
    80001d46:	6105                	addi	sp,sp,32
    80001d48:	8082                	ret

0000000080001d4a <proc_pagetable>:
{
    80001d4a:	1101                	addi	sp,sp,-32
    80001d4c:	ec06                	sd	ra,24(sp)
    80001d4e:	e822                	sd	s0,16(sp)
    80001d50:	e426                	sd	s1,8(sp)
    80001d52:	e04a                	sd	s2,0(sp)
    80001d54:	1000                	addi	s0,sp,32
    80001d56:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	5e2080e7          	jalr	1506(ra) # 8000133a <uvmcreate>
    80001d60:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001d62:	c121                	beqz	a0,80001da2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d64:	4729                	li	a4,10
    80001d66:	00005697          	auipc	a3,0x5
    80001d6a:	29a68693          	addi	a3,a3,666 # 80007000 <_trampoline>
    80001d6e:	6605                	lui	a2,0x1
    80001d70:	040005b7          	lui	a1,0x4000
    80001d74:	15fd                	addi	a1,a1,-1
    80001d76:	05b2                	slli	a1,a1,0xc
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	338080e7          	jalr	824(ra) # 800010b0 <mappages>
    80001d80:	02054863          	bltz	a0,80001db0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d84:	4719                	li	a4,6
    80001d86:	05893683          	ld	a3,88(s2)
    80001d8a:	6605                	lui	a2,0x1
    80001d8c:	020005b7          	lui	a1,0x2000
    80001d90:	15fd                	addi	a1,a1,-1
    80001d92:	05b6                	slli	a1,a1,0xd
    80001d94:	8526                	mv	a0,s1
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	31a080e7          	jalr	794(ra) # 800010b0 <mappages>
    80001d9e:	02054163          	bltz	a0,80001dc0 <proc_pagetable+0x76>
}
    80001da2:	8526                	mv	a0,s1
    80001da4:	60e2                	ld	ra,24(sp)
    80001da6:	6442                	ld	s0,16(sp)
    80001da8:	64a2                	ld	s1,8(sp)
    80001daa:	6902                	ld	s2,0(sp)
    80001dac:	6105                	addi	sp,sp,32
    80001dae:	8082                	ret
    uvmfree(pagetable, 0);
    80001db0:	4581                	li	a1,0
    80001db2:	8526                	mv	a0,s1
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	782080e7          	jalr	1922(ra) # 80001536 <uvmfree>
    return 0;
    80001dbc:	4481                	li	s1,0
    80001dbe:	b7d5                	j	80001da2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dc0:	4681                	li	a3,0
    80001dc2:	4605                	li	a2,1
    80001dc4:	040005b7          	lui	a1,0x4000
    80001dc8:	15fd                	addi	a1,a1,-1
    80001dca:	05b2                	slli	a1,a1,0xc
    80001dcc:	8526                	mv	a0,s1
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	4a8080e7          	jalr	1192(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001dd6:	4581                	li	a1,0
    80001dd8:	8526                	mv	a0,s1
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	75c080e7          	jalr	1884(ra) # 80001536 <uvmfree>
    return 0;
    80001de2:	4481                	li	s1,0
    80001de4:	bf7d                	j	80001da2 <proc_pagetable+0x58>

0000000080001de6 <proc_freepagetable>:
{
    80001de6:	1101                	addi	sp,sp,-32
    80001de8:	ec06                	sd	ra,24(sp)
    80001dea:	e822                	sd	s0,16(sp)
    80001dec:	e426                	sd	s1,8(sp)
    80001dee:	e04a                	sd	s2,0(sp)
    80001df0:	1000                	addi	s0,sp,32
    80001df2:	84aa                	mv	s1,a0
    80001df4:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001df6:	4681                	li	a3,0
    80001df8:	4605                	li	a2,1
    80001dfa:	040005b7          	lui	a1,0x4000
    80001dfe:	15fd                	addi	a1,a1,-1
    80001e00:	05b2                	slli	a1,a1,0xc
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	474080e7          	jalr	1140(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e0a:	4681                	li	a3,0
    80001e0c:	4605                	li	a2,1
    80001e0e:	020005b7          	lui	a1,0x2000
    80001e12:	15fd                	addi	a1,a1,-1
    80001e14:	05b6                	slli	a1,a1,0xd
    80001e16:	8526                	mv	a0,s1
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	45e080e7          	jalr	1118(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001e20:	85ca                	mv	a1,s2
    80001e22:	8526                	mv	a0,s1
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	712080e7          	jalr	1810(ra) # 80001536 <uvmfree>
}
    80001e2c:	60e2                	ld	ra,24(sp)
    80001e2e:	6442                	ld	s0,16(sp)
    80001e30:	64a2                	ld	s1,8(sp)
    80001e32:	6902                	ld	s2,0(sp)
    80001e34:	6105                	addi	sp,sp,32
    80001e36:	8082                	ret

0000000080001e38 <freeproc>:
{
    80001e38:	1101                	addi	sp,sp,-32
    80001e3a:	ec06                	sd	ra,24(sp)
    80001e3c:	e822                	sd	s0,16(sp)
    80001e3e:	e426                	sd	s1,8(sp)
    80001e40:	1000                	addi	s0,sp,32
    80001e42:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001e44:	6d28                	ld	a0,88(a0)
    80001e46:	c509                	beqz	a0,80001e50 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	bb0080e7          	jalr	-1104(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001e50:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001e54:	68a8                	ld	a0,80(s1)
    80001e56:	c511                	beqz	a0,80001e62 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e58:	64ac                	ld	a1,72(s1)
    80001e5a:	00000097          	auipc	ra,0x0
    80001e5e:	f8c080e7          	jalr	-116(ra) # 80001de6 <proc_freepagetable>
  p->pagetable = 0;
    80001e62:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001e66:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001e6a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001e6e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001e72:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001e76:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001e7a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001e7e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001e82:	0004ac23          	sw	zero,24(s1)
  printf("remove free proc zombie %d\n", p->index); //delete
    80001e86:	16c4a583          	lw	a1,364(s1)
    80001e8a:	00006517          	auipc	a0,0x6
    80001e8e:	3e650513          	addi	a0,a0,998 # 80008270 <digits+0x230>
    80001e92:	ffffe097          	auipc	ra,0xffffe
    80001e96:	6f6080e7          	jalr	1782(ra) # 80000588 <printf>
  remove_proc_to_list(&zombie_list, p); // remove the freed process from the ZOMBIE list
    80001e9a:	85a6                	mv	a1,s1
    80001e9c:	00007517          	auipc	a0,0x7
    80001ea0:	bac50513          	addi	a0,a0,-1108 # 80008a48 <zombie_list>
    80001ea4:	00000097          	auipc	ra,0x0
    80001ea8:	b26080e7          	jalr	-1242(ra) # 800019ca <remove_proc_to_list>
  printf("insert free proc unused %d\n", p->index); //delete
    80001eac:	16c4a583          	lw	a1,364(s1)
    80001eb0:	00006517          	auipc	a0,0x6
    80001eb4:	3e050513          	addi	a0,a0,992 # 80008290 <digits+0x250>
    80001eb8:	ffffe097          	auipc	ra,0xffffe
    80001ebc:	6d0080e7          	jalr	1744(ra) # 80000588 <printf>
  insert_proc_to_list(&unused_list, p); // admit its entry to the UNUSED entry list.
    80001ec0:	85a6                	mv	a1,s1
    80001ec2:	00007517          	auipc	a0,0x7
    80001ec6:	b9650513          	addi	a0,a0,-1130 # 80008a58 <unused_list>
    80001eca:	00000097          	auipc	ra,0x0
    80001ece:	a60080e7          	jalr	-1440(ra) # 8000192a <insert_proc_to_list>
}
    80001ed2:	60e2                	ld	ra,24(sp)
    80001ed4:	6442                	ld	s0,16(sp)
    80001ed6:	64a2                	ld	s1,8(sp)
    80001ed8:	6105                	addi	sp,sp,32
    80001eda:	8082                	ret

0000000080001edc <allocproc>:
{
    80001edc:	715d                	addi	sp,sp,-80
    80001ede:	e486                	sd	ra,72(sp)
    80001ee0:	e0a2                	sd	s0,64(sp)
    80001ee2:	fc26                	sd	s1,56(sp)
    80001ee4:	f84a                	sd	s2,48(sp)
    80001ee6:	f44e                	sd	s3,40(sp)
    80001ee8:	f052                	sd	s4,32(sp)
    80001eea:	ec56                	sd	s5,24(sp)
    80001eec:	e85a                	sd	s6,16(sp)
    80001eee:	e45e                	sd	s7,8(sp)
    80001ef0:	0880                	addi	s0,sp,80
  return lst->head == -1;
    80001ef2:	00007917          	auipc	s2,0x7
    80001ef6:	b6692903          	lw	s2,-1178(s2) # 80008a58 <unused_list>
  while(!isEmpty(&unused_list)){
    80001efa:	57fd                	li	a5,-1
    80001efc:	14f90463          	beq	s2,a5,80002044 <allocproc+0x168>
    80001f00:	17800a93          	li	s5,376
    p = &proc[unused_list.head];
    80001f04:	00010a17          	auipc	s4,0x10
    80001f08:	88ca0a13          	addi	s4,s4,-1908 # 80011790 <proc>
  return lst->head == -1;
    80001f0c:	00007b97          	auipc	s7,0x7
    80001f10:	b4cb8b93          	addi	s7,s7,-1204 # 80008a58 <unused_list>
  while(!isEmpty(&unused_list)){
    80001f14:	5b7d                	li	s6,-1
    p = &proc[unused_list.head];
    80001f16:	035909b3          	mul	s3,s2,s5
    80001f1a:	014984b3          	add	s1,s3,s4
    acquire(&p->lock);
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	cc4080e7          	jalr	-828(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001f28:	4c9c                	lw	a5,24(s1)
    80001f2a:	c79d                	beqz	a5,80001f58 <allocproc+0x7c>
      release(&p->lock);
    80001f2c:	8526                	mv	a0,s1
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	d6a080e7          	jalr	-662(ra) # 80000c98 <release>
  return lst->head == -1;
    80001f36:	000ba903          	lw	s2,0(s7)
  while(!isEmpty(&unused_list)){
    80001f3a:	fd691ee3          	bne	s2,s6,80001f16 <allocproc+0x3a>
  return 0;
    80001f3e:	4481                	li	s1,0
}
    80001f40:	8526                	mv	a0,s1
    80001f42:	60a6                	ld	ra,72(sp)
    80001f44:	6406                	ld	s0,64(sp)
    80001f46:	74e2                	ld	s1,56(sp)
    80001f48:	7942                	ld	s2,48(sp)
    80001f4a:	79a2                	ld	s3,40(sp)
    80001f4c:	7a02                	ld	s4,32(sp)
    80001f4e:	6ae2                	ld	s5,24(sp)
    80001f50:	6b42                	ld	s6,16(sp)
    80001f52:	6ba2                	ld	s7,8(sp)
    80001f54:	6161                	addi	sp,sp,80
    80001f56:	8082                	ret
      printf("remove allocproc unused %d\n", p->index); //delete
    80001f58:	17800a13          	li	s4,376
    80001f5c:	034907b3          	mul	a5,s2,s4
    80001f60:	00010a17          	auipc	s4,0x10
    80001f64:	830a0a13          	addi	s4,s4,-2000 # 80011790 <proc>
    80001f68:	9a3e                	add	s4,s4,a5
    80001f6a:	16ca2583          	lw	a1,364(s4)
    80001f6e:	00006517          	auipc	a0,0x6
    80001f72:	34250513          	addi	a0,a0,834 # 800082b0 <digits+0x270>
    80001f76:	ffffe097          	auipc	ra,0xffffe
    80001f7a:	612080e7          	jalr	1554(ra) # 80000588 <printf>
      remove_proc_to_list(&unused_list, p); // choose the new process entry to initialize from the UNUSED entry list.
    80001f7e:	85a6                	mv	a1,s1
    80001f80:	00007517          	auipc	a0,0x7
    80001f84:	ad850513          	addi	a0,a0,-1320 # 80008a58 <unused_list>
    80001f88:	00000097          	auipc	ra,0x0
    80001f8c:	a42080e7          	jalr	-1470(ra) # 800019ca <remove_proc_to_list>
  p->pid = allocpid();
    80001f90:	00000097          	auipc	ra,0x0
    80001f94:	d80080e7          	jalr	-640(ra) # 80001d10 <allocpid>
    80001f98:	02aa2823          	sw	a0,48(s4)
  p->state = USED;
    80001f9c:	4785                	li	a5,1
    80001f9e:	00fa2c23          	sw	a5,24(s4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	b52080e7          	jalr	-1198(ra) # 80000af4 <kalloc>
    80001faa:	8aaa                	mv	s5,a0
    80001fac:	04aa3c23          	sd	a0,88(s4)
    80001fb0:	c135                	beqz	a0,80002014 <allocproc+0x138>
  p->pagetable = proc_pagetable(p);
    80001fb2:	8526                	mv	a0,s1
    80001fb4:	00000097          	auipc	ra,0x0
    80001fb8:	d96080e7          	jalr	-618(ra) # 80001d4a <proc_pagetable>
    80001fbc:	8a2a                	mv	s4,a0
    80001fbe:	17800793          	li	a5,376
    80001fc2:	02f90733          	mul	a4,s2,a5
    80001fc6:	0000f797          	auipc	a5,0xf
    80001fca:	7ca78793          	addi	a5,a5,1994 # 80011790 <proc>
    80001fce:	97ba                	add	a5,a5,a4
    80001fd0:	eba8                	sd	a0,80(a5)
  if(p->pagetable == 0){
    80001fd2:	cd29                	beqz	a0,8000202c <allocproc+0x150>
  memset(&p->context, 0, sizeof(p->context));
    80001fd4:	06098513          	addi	a0,s3,96 # 1060 <_entry-0x7fffefa0>
    80001fd8:	0000f997          	auipc	s3,0xf
    80001fdc:	7b898993          	addi	s3,s3,1976 # 80011790 <proc>
    80001fe0:	07000613          	li	a2,112
    80001fe4:	4581                	li	a1,0
    80001fe6:	954e                	add	a0,a0,s3
    80001fe8:	fffff097          	auipc	ra,0xfffff
    80001fec:	cf8080e7          	jalr	-776(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001ff0:	17800793          	li	a5,376
    80001ff4:	02f90933          	mul	s2,s2,a5
    80001ff8:	994e                	add	s2,s2,s3
    80001ffa:	00000797          	auipc	a5,0x0
    80001ffe:	cd078793          	addi	a5,a5,-816 # 80001cca <forkret>
    80002002:	06f93023          	sd	a5,96(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002006:	04093783          	ld	a5,64(s2)
    8000200a:	6705                	lui	a4,0x1
    8000200c:	97ba                	add	a5,a5,a4
    8000200e:	06f93423          	sd	a5,104(s2)
  return p;
    80002012:	b73d                	j	80001f40 <allocproc+0x64>
    freeproc(p);
    80002014:	8526                	mv	a0,s1
    80002016:	00000097          	auipc	ra,0x0
    8000201a:	e22080e7          	jalr	-478(ra) # 80001e38 <freeproc>
    release(&p->lock);
    8000201e:	8526                	mv	a0,s1
    80002020:	fffff097          	auipc	ra,0xfffff
    80002024:	c78080e7          	jalr	-904(ra) # 80000c98 <release>
    return 0;
    80002028:	84d6                	mv	s1,s5
    8000202a:	bf19                	j	80001f40 <allocproc+0x64>
    freeproc(p);
    8000202c:	8526                	mv	a0,s1
    8000202e:	00000097          	auipc	ra,0x0
    80002032:	e0a080e7          	jalr	-502(ra) # 80001e38 <freeproc>
    release(&p->lock);
    80002036:	8526                	mv	a0,s1
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	c60080e7          	jalr	-928(ra) # 80000c98 <release>
    return 0;
    80002040:	84d2                	mv	s1,s4
    80002042:	bdfd                	j	80001f40 <allocproc+0x64>
  return 0;
    80002044:	4481                	li	s1,0
    80002046:	bded                	j	80001f40 <allocproc+0x64>

0000000080002048 <userinit>:
{
    80002048:	1101                	addi	sp,sp,-32
    8000204a:	ec06                	sd	ra,24(sp)
    8000204c:	e822                	sd	s0,16(sp)
    8000204e:	e426                	sd	s1,8(sp)
    80002050:	1000                	addi	s0,sp,32
  p = allocproc();
    80002052:	00000097          	auipc	ra,0x0
    80002056:	e8a080e7          	jalr	-374(ra) # 80001edc <allocproc>
    8000205a:	84aa                	mv	s1,a0
  initproc = p;
    8000205c:	00007797          	auipc	a5,0x7
    80002060:	fca7b623          	sd	a0,-52(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002064:	03400613          	li	a2,52
    80002068:	00007597          	auipc	a1,0x7
    8000206c:	a0858593          	addi	a1,a1,-1528 # 80008a70 <initcode>
    80002070:	6928                	ld	a0,80(a0)
    80002072:	fffff097          	auipc	ra,0xfffff
    80002076:	2f6080e7          	jalr	758(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    8000207a:	6785                	lui	a5,0x1
    8000207c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    8000207e:	6cb8                	ld	a4,88(s1)
    80002080:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002084:	6cb8                	ld	a4,88(s1)
    80002086:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002088:	4641                	li	a2,16
    8000208a:	00006597          	auipc	a1,0x6
    8000208e:	24658593          	addi	a1,a1,582 # 800082d0 <digits+0x290>
    80002092:	15848513          	addi	a0,s1,344
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	d9c080e7          	jalr	-612(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    8000209e:	00006517          	auipc	a0,0x6
    800020a2:	24250513          	addi	a0,a0,578 # 800082e0 <digits+0x2a0>
    800020a6:	00002097          	auipc	ra,0x2
    800020aa:	440080e7          	jalr	1088(ra) # 800044e6 <namei>
    800020ae:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800020b2:	478d                	li	a5,3
    800020b4:	cc9c                	sw	a5,24(s1)
  printf("insert userinit runnable %d\n", p->index); //delete
    800020b6:	16c4a583          	lw	a1,364(s1)
    800020ba:	00006517          	auipc	a0,0x6
    800020be:	22e50513          	addi	a0,a0,558 # 800082e8 <digits+0x2a8>
    800020c2:	ffffe097          	auipc	ra,0xffffe
    800020c6:	4c6080e7          	jalr	1222(ra) # 80000588 <printf>
  insert_proc_to_list(&(cpus[0].runnable_list), p); // admit the init process (the first process in the OS) to the first CPU’s list.
    800020ca:	85a6                	mv	a1,s1
    800020cc:	0000f517          	auipc	a0,0xf
    800020d0:	25450513          	addi	a0,a0,596 # 80011320 <cpus+0x80>
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	856080e7          	jalr	-1962(ra) # 8000192a <insert_proc_to_list>
  release(&p->lock);
    800020dc:	8526                	mv	a0,s1
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	bba080e7          	jalr	-1094(ra) # 80000c98 <release>
}
    800020e6:	60e2                	ld	ra,24(sp)
    800020e8:	6442                	ld	s0,16(sp)
    800020ea:	64a2                	ld	s1,8(sp)
    800020ec:	6105                	addi	sp,sp,32
    800020ee:	8082                	ret

00000000800020f0 <growproc>:
{
    800020f0:	1101                	addi	sp,sp,-32
    800020f2:	ec06                	sd	ra,24(sp)
    800020f4:	e822                	sd	s0,16(sp)
    800020f6:	e426                	sd	s1,8(sp)
    800020f8:	e04a                	sd	s2,0(sp)
    800020fa:	1000                	addi	s0,sp,32
    800020fc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800020fe:	00000097          	auipc	ra,0x0
    80002102:	b8e080e7          	jalr	-1138(ra) # 80001c8c <myproc>
    80002106:	892a                	mv	s2,a0
  sz = p->sz;
    80002108:	652c                	ld	a1,72(a0)
    8000210a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000210e:	00904f63          	bgtz	s1,8000212c <growproc+0x3c>
  } else if(n < 0){
    80002112:	0204cc63          	bltz	s1,8000214a <growproc+0x5a>
  p->sz = sz;
    80002116:	1602                	slli	a2,a2,0x20
    80002118:	9201                	srli	a2,a2,0x20
    8000211a:	04c93423          	sd	a2,72(s2)
  return 0;
    8000211e:	4501                	li	a0,0
}
    80002120:	60e2                	ld	ra,24(sp)
    80002122:	6442                	ld	s0,16(sp)
    80002124:	64a2                	ld	s1,8(sp)
    80002126:	6902                	ld	s2,0(sp)
    80002128:	6105                	addi	sp,sp,32
    8000212a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000212c:	9e25                	addw	a2,a2,s1
    8000212e:	1602                	slli	a2,a2,0x20
    80002130:	9201                	srli	a2,a2,0x20
    80002132:	1582                	slli	a1,a1,0x20
    80002134:	9181                	srli	a1,a1,0x20
    80002136:	6928                	ld	a0,80(a0)
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	2ea080e7          	jalr	746(ra) # 80001422 <uvmalloc>
    80002140:	0005061b          	sext.w	a2,a0
    80002144:	fa69                	bnez	a2,80002116 <growproc+0x26>
      return -1;
    80002146:	557d                	li	a0,-1
    80002148:	bfe1                	j	80002120 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000214a:	9e25                	addw	a2,a2,s1
    8000214c:	1602                	slli	a2,a2,0x20
    8000214e:	9201                	srli	a2,a2,0x20
    80002150:	1582                	slli	a1,a1,0x20
    80002152:	9181                	srli	a1,a1,0x20
    80002154:	6928                	ld	a0,80(a0)
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	284080e7          	jalr	644(ra) # 800013da <uvmdealloc>
    8000215e:	0005061b          	sext.w	a2,a0
    80002162:	bf55                	j	80002116 <growproc+0x26>

0000000080002164 <scheduler>:
{
    80002164:	7159                	addi	sp,sp,-112
    80002166:	f486                	sd	ra,104(sp)
    80002168:	f0a2                	sd	s0,96(sp)
    8000216a:	eca6                	sd	s1,88(sp)
    8000216c:	e8ca                	sd	s2,80(sp)
    8000216e:	e4ce                	sd	s3,72(sp)
    80002170:	e0d2                	sd	s4,64(sp)
    80002172:	fc56                	sd	s5,56(sp)
    80002174:	f85a                	sd	s6,48(sp)
    80002176:	f45e                	sd	s7,40(sp)
    80002178:	f062                	sd	s8,32(sp)
    8000217a:	ec66                	sd	s9,24(sp)
    8000217c:	e86a                	sd	s10,16(sp)
    8000217e:	e46e                	sd	s11,8(sp)
    80002180:	1880                	addi	s0,sp,112
    80002182:	8712                	mv	a4,tp
  int id = r_tp();
    80002184:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002186:	0000fc97          	auipc	s9,0xf
    8000218a:	11ac8c93          	addi	s9,s9,282 # 800112a0 <cpus>
    8000218e:	09800793          	li	a5,152
    80002192:	02f707b3          	mul	a5,a4,a5
    80002196:	00fc86b3          	add	a3,s9,a5
    8000219a:	0006b023          	sd	zero,0(a3)
    if(!isEmpty(&(c->runnable_list))) { // check whether there is a ready process in the cpu
    8000219e:	08078d13          	addi	s10,a5,128 # 1080 <_entry-0x7fffef80>
    800021a2:	9d66                	add	s10,s10,s9
        swtch(&c->context, &p->context);
    800021a4:	07a1                	addi	a5,a5,8
    800021a6:	9cbe                	add	s9,s9,a5
  return lst->head == -1;
    800021a8:	8ab6                	mv	s5,a3
    if(!isEmpty(&(c->runnable_list))) { // check whether there is a ready process in the cpu
    800021aa:	597d                	li	s2,-1
    800021ac:	17800b93          	li	s7,376
      p =  &proc[c->runnable_list.head]; //  pick the first process from the correct CPU’s list.
    800021b0:	0000fb17          	auipc	s6,0xf
    800021b4:	5e0b0b13          	addi	s6,s6,1504 # 80011790 <proc>
      if(p->state == RUNNABLE) {  
    800021b8:	4c0d                	li	s8,3
        p->state = RUNNING;
    800021ba:	4d91                	li	s11,4
    800021bc:	a031                	j	800021c8 <scheduler+0x64>
      release(&p->lock);
    800021be:	854e                	mv	a0,s3
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	ad8080e7          	jalr	-1320(ra) # 80000c98 <release>
  return lst->head == -1;
    800021c8:	080aa483          	lw	s1,128(s5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021cc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021d0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021d4:	10079073          	csrw	sstatus,a5
    if(!isEmpty(&(c->runnable_list))) { // check whether there is a ready process in the cpu
    800021d8:	ff248ae3          	beq	s1,s2,800021cc <scheduler+0x68>
      p =  &proc[c->runnable_list.head]; //  pick the first process from the correct CPU’s list.
    800021dc:	03748a33          	mul	s4,s1,s7
    800021e0:	016a09b3          	add	s3,s4,s6
      acquire(&p->lock);
    800021e4:	854e                	mv	a0,s3
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	9fe080e7          	jalr	-1538(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {  
    800021ee:	0189a783          	lw	a5,24(s3)
    800021f2:	fd8796e3          	bne	a5,s8,800021be <scheduler+0x5a>
        printf("remove sched runnable %d\n", p->index); //delete
    800021f6:	16c9a583          	lw	a1,364(s3)
    800021fa:	00006517          	auipc	a0,0x6
    800021fe:	10e50513          	addi	a0,a0,270 # 80008308 <digits+0x2c8>
    80002202:	ffffe097          	auipc	ra,0xffffe
    80002206:	386080e7          	jalr	902(ra) # 80000588 <printf>
        remove_proc_to_list(&(c->runnable_list), p);
    8000220a:	85ce                	mv	a1,s3
    8000220c:	856a                	mv	a0,s10
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	7bc080e7          	jalr	1980(ra) # 800019ca <remove_proc_to_list>
        p->state = RUNNING;
    80002216:	01b9ac23          	sw	s11,24(s3)
        c->proc = p;
    8000221a:	013ab023          	sd	s3,0(s5)
        p->last_cpu = c->cpu_id;
    8000221e:	088aa783          	lw	a5,136(s5)
    80002222:	16f9a423          	sw	a5,360(s3)
        printf("before swtch%d\n", p->index); //delete
    80002226:	16c9a583          	lw	a1,364(s3)
    8000222a:	00006517          	auipc	a0,0x6
    8000222e:	0fe50513          	addi	a0,a0,254 # 80008328 <digits+0x2e8>
    80002232:	ffffe097          	auipc	ra,0xffffe
    80002236:	356080e7          	jalr	854(ra) # 80000588 <printf>
        swtch(&c->context, &p->context);
    8000223a:	060a0593          	addi	a1,s4,96
    8000223e:	95da                	add	a1,a1,s6
    80002240:	8566                	mv	a0,s9
    80002242:	00001097          	auipc	ra,0x1
    80002246:	a0e080e7          	jalr	-1522(ra) # 80002c50 <swtch>
        printf("after swtch%d\n", p->index); //delete
    8000224a:	16c9a583          	lw	a1,364(s3)
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	0ea50513          	addi	a0,a0,234 # 80008338 <digits+0x2f8>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	332080e7          	jalr	818(ra) # 80000588 <printf>
        c->proc = 0;
    8000225e:	000ab023          	sd	zero,0(s5)
    80002262:	bfb1                	j	800021be <scheduler+0x5a>

0000000080002264 <sched>:
{
    80002264:	7179                	addi	sp,sp,-48
    80002266:	f406                	sd	ra,40(sp)
    80002268:	f022                	sd	s0,32(sp)
    8000226a:	ec26                	sd	s1,24(sp)
    8000226c:	e84a                	sd	s2,16(sp)
    8000226e:	e44e                	sd	s3,8(sp)
    80002270:	e052                	sd	s4,0(sp)
    80002272:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002274:	00000097          	auipc	ra,0x0
    80002278:	a18080e7          	jalr	-1512(ra) # 80001c8c <myproc>
    8000227c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	8ec080e7          	jalr	-1812(ra) # 80000b6a <holding>
    80002286:	c145                	beqz	a0,80002326 <sched+0xc2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002288:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000228a:	2781                	sext.w	a5,a5
    8000228c:	09800713          	li	a4,152
    80002290:	02e787b3          	mul	a5,a5,a4
    80002294:	0000f717          	auipc	a4,0xf
    80002298:	00c70713          	addi	a4,a4,12 # 800112a0 <cpus>
    8000229c:	97ba                	add	a5,a5,a4
    8000229e:	5fb8                	lw	a4,120(a5)
    800022a0:	4785                	li	a5,1
    800022a2:	08f71a63          	bne	a4,a5,80002336 <sched+0xd2>
  if(p->state == RUNNING)
    800022a6:	4c98                	lw	a4,24(s1)
    800022a8:	4791                	li	a5,4
    800022aa:	08f70e63          	beq	a4,a5,80002346 <sched+0xe2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022ae:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022b2:	8b89                	andi	a5,a5,2
  if(intr_get())
    800022b4:	e3cd                	bnez	a5,80002356 <sched+0xf2>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022b6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022b8:	0000f917          	auipc	s2,0xf
    800022bc:	fe890913          	addi	s2,s2,-24 # 800112a0 <cpus>
    800022c0:	2781                	sext.w	a5,a5
    800022c2:	09800993          	li	s3,152
    800022c6:	033787b3          	mul	a5,a5,s3
    800022ca:	97ca                	add	a5,a5,s2
    800022cc:	07c7aa03          	lw	s4,124(a5)
  printf("before sched swtch status \n"); //delete
    800022d0:	00006517          	auipc	a0,0x6
    800022d4:	0c050513          	addi	a0,a0,192 # 80008390 <digits+0x350>
    800022d8:	ffffe097          	auipc	ra,0xffffe
    800022dc:	2b0080e7          	jalr	688(ra) # 80000588 <printf>
    800022e0:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    800022e2:	2581                	sext.w	a1,a1
    800022e4:	033585b3          	mul	a1,a1,s3
    800022e8:	05a1                	addi	a1,a1,8
    800022ea:	95ca                	add	a1,a1,s2
    800022ec:	06048513          	addi	a0,s1,96
    800022f0:	00001097          	auipc	ra,0x1
    800022f4:	960080e7          	jalr	-1696(ra) # 80002c50 <swtch>
  printf("after sched swtch  status \n"); //delete
    800022f8:	00006517          	auipc	a0,0x6
    800022fc:	0b850513          	addi	a0,a0,184 # 800083b0 <digits+0x370>
    80002300:	ffffe097          	auipc	ra,0xffffe
    80002304:	288080e7          	jalr	648(ra) # 80000588 <printf>
    80002308:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000230a:	2781                	sext.w	a5,a5
    8000230c:	033787b3          	mul	a5,a5,s3
    80002310:	993e                	add	s2,s2,a5
    80002312:	07492e23          	sw	s4,124(s2)
}
    80002316:	70a2                	ld	ra,40(sp)
    80002318:	7402                	ld	s0,32(sp)
    8000231a:	64e2                	ld	s1,24(sp)
    8000231c:	6942                	ld	s2,16(sp)
    8000231e:	69a2                	ld	s3,8(sp)
    80002320:	6a02                	ld	s4,0(sp)
    80002322:	6145                	addi	sp,sp,48
    80002324:	8082                	ret
    panic("sched p->lock");
    80002326:	00006517          	auipc	a0,0x6
    8000232a:	02250513          	addi	a0,a0,34 # 80008348 <digits+0x308>
    8000232e:	ffffe097          	auipc	ra,0xffffe
    80002332:	210080e7          	jalr	528(ra) # 8000053e <panic>
    panic("sched locks");
    80002336:	00006517          	auipc	a0,0x6
    8000233a:	02250513          	addi	a0,a0,34 # 80008358 <digits+0x318>
    8000233e:	ffffe097          	auipc	ra,0xffffe
    80002342:	200080e7          	jalr	512(ra) # 8000053e <panic>
    panic("sched running");
    80002346:	00006517          	auipc	a0,0x6
    8000234a:	02250513          	addi	a0,a0,34 # 80008368 <digits+0x328>
    8000234e:	ffffe097          	auipc	ra,0xffffe
    80002352:	1f0080e7          	jalr	496(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002356:	00006517          	auipc	a0,0x6
    8000235a:	02250513          	addi	a0,a0,34 # 80008378 <digits+0x338>
    8000235e:	ffffe097          	auipc	ra,0xffffe
    80002362:	1e0080e7          	jalr	480(ra) # 8000053e <panic>

0000000080002366 <yield>:
{
    80002366:	1101                	addi	sp,sp,-32
    80002368:	ec06                	sd	ra,24(sp)
    8000236a:	e822                	sd	s0,16(sp)
    8000236c:	e426                	sd	s1,8(sp)
    8000236e:	e04a                	sd	s2,0(sp)
    80002370:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002372:	00000097          	auipc	ra,0x0
    80002376:	91a080e7          	jalr	-1766(ra) # 80001c8c <myproc>
    8000237a:	84aa                	mv	s1,a0
    8000237c:	8912                	mv	s2,tp
  acquire(&p->lock);
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	866080e7          	jalr	-1946(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002386:	478d                	li	a5,3
    80002388:	cc9c                	sw	a5,24(s1)
  printf("insert yield runnable %d\n", p->index); //delete
    8000238a:	16c4a583          	lw	a1,364(s1)
    8000238e:	00006517          	auipc	a0,0x6
    80002392:	04250513          	addi	a0,a0,66 # 800083d0 <digits+0x390>
    80002396:	ffffe097          	auipc	ra,0xffffe
    8000239a:	1f2080e7          	jalr	498(ra) # 80000588 <printf>
  insert_proc_to_list(&(c->runnable_list), p); // TODO: check
    8000239e:	2901                	sext.w	s2,s2
    800023a0:	09800513          	li	a0,152
    800023a4:	02a90933          	mul	s2,s2,a0
    800023a8:	85a6                	mv	a1,s1
    800023aa:	0000f517          	auipc	a0,0xf
    800023ae:	f7650513          	addi	a0,a0,-138 # 80011320 <cpus+0x80>
    800023b2:	954a                	add	a0,a0,s2
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	576080e7          	jalr	1398(ra) # 8000192a <insert_proc_to_list>
  sched();
    800023bc:	00000097          	auipc	ra,0x0
    800023c0:	ea8080e7          	jalr	-344(ra) # 80002264 <sched>
  release(&p->lock);
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	8d2080e7          	jalr	-1838(ra) # 80000c98 <release>
}
    800023ce:	60e2                	ld	ra,24(sp)
    800023d0:	6442                	ld	s0,16(sp)
    800023d2:	64a2                	ld	s1,8(sp)
    800023d4:	6902                	ld	s2,0(sp)
    800023d6:	6105                	addi	sp,sp,32
    800023d8:	8082                	ret

00000000800023da <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800023da:	7179                	addi	sp,sp,-48
    800023dc:	f406                	sd	ra,40(sp)
    800023de:	f022                	sd	s0,32(sp)
    800023e0:	ec26                	sd	s1,24(sp)
    800023e2:	e84a                	sd	s2,16(sp)
    800023e4:	e44e                	sd	s3,8(sp)
    800023e6:	1800                	addi	s0,sp,48
    800023e8:	89aa                	mv	s3,a0
    800023ea:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800023ec:	00000097          	auipc	ra,0x0
    800023f0:	8a0080e7          	jalr	-1888(ra) # 80001c8c <myproc>
    800023f4:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800023f6:	ffffe097          	auipc	ra,0xffffe
    800023fa:	7ee080e7          	jalr	2030(ra) # 80000be4 <acquire>
  release(lk);
    800023fe:	854a                	mv	a0,s2
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	898080e7          	jalr	-1896(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002408:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000240c:	4789                	li	a5,2
    8000240e:	cc9c                	sw	a5,24(s1)
  printf("insert sleep sleep %d\n", p->index); //delete
    80002410:	16c4a583          	lw	a1,364(s1)
    80002414:	00006517          	auipc	a0,0x6
    80002418:	fdc50513          	addi	a0,a0,-36 # 800083f0 <digits+0x3b0>
    8000241c:	ffffe097          	auipc	ra,0xffffe
    80002420:	16c080e7          	jalr	364(ra) # 80000588 <printf>
  insert_proc_to_list(&sleeping_list, p);
    80002424:	85a6                	mv	a1,s1
    80002426:	00006517          	auipc	a0,0x6
    8000242a:	62a50513          	addi	a0,a0,1578 # 80008a50 <sleeping_list>
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	4fc080e7          	jalr	1276(ra) # 8000192a <insert_proc_to_list>

  sched();
    80002436:	00000097          	auipc	ra,0x0
    8000243a:	e2e080e7          	jalr	-466(ra) # 80002264 <sched>

  // Tidy up.
  p->chan = 0;
    8000243e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002442:	8526                	mv	a0,s1
    80002444:	fffff097          	auipc	ra,0xfffff
    80002448:	854080e7          	jalr	-1964(ra) # 80000c98 <release>
  acquire(lk);
    8000244c:	854a                	mv	a0,s2
    8000244e:	ffffe097          	auipc	ra,0xffffe
    80002452:	796080e7          	jalr	1942(ra) # 80000be4 <acquire>
}
    80002456:	70a2                	ld	ra,40(sp)
    80002458:	7402                	ld	s0,32(sp)
    8000245a:	64e2                	ld	s1,24(sp)
    8000245c:	6942                	ld	s2,16(sp)
    8000245e:	69a2                	ld	s3,8(sp)
    80002460:	6145                	addi	sp,sp,48
    80002462:	8082                	ret

0000000080002464 <wait>:
{
    80002464:	715d                	addi	sp,sp,-80
    80002466:	e486                	sd	ra,72(sp)
    80002468:	e0a2                	sd	s0,64(sp)
    8000246a:	fc26                	sd	s1,56(sp)
    8000246c:	f84a                	sd	s2,48(sp)
    8000246e:	f44e                	sd	s3,40(sp)
    80002470:	f052                	sd	s4,32(sp)
    80002472:	ec56                	sd	s5,24(sp)
    80002474:	e85a                	sd	s6,16(sp)
    80002476:	e45e                	sd	s7,8(sp)
    80002478:	e062                	sd	s8,0(sp)
    8000247a:	0880                	addi	s0,sp,80
    8000247c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000247e:	00000097          	auipc	ra,0x0
    80002482:	80e080e7          	jalr	-2034(ra) # 80001c8c <myproc>
    80002486:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002488:	0000f517          	auipc	a0,0xf
    8000248c:	2f050513          	addi	a0,a0,752 # 80011778 <wait_lock>
    80002490:	ffffe097          	auipc	ra,0xffffe
    80002494:	754080e7          	jalr	1876(ra) # 80000be4 <acquire>
    havekids = 0;
    80002498:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000249a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000249c:	00015997          	auipc	s3,0x15
    800024a0:	0f498993          	addi	s3,s3,244 # 80017590 <tickslock>
        havekids = 1;
    800024a4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024a6:	0000fc17          	auipc	s8,0xf
    800024aa:	2d2c0c13          	addi	s8,s8,722 # 80011778 <wait_lock>
    havekids = 0;
    800024ae:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800024b0:	0000f497          	auipc	s1,0xf
    800024b4:	2e048493          	addi	s1,s1,736 # 80011790 <proc>
    800024b8:	a0bd                	j	80002526 <wait+0xc2>
          pid = np->pid;
    800024ba:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024be:	000b0e63          	beqz	s6,800024da <wait+0x76>
    800024c2:	4691                	li	a3,4
    800024c4:	02c48613          	addi	a2,s1,44
    800024c8:	85da                	mv	a1,s6
    800024ca:	05093503          	ld	a0,80(s2)
    800024ce:	fffff097          	auipc	ra,0xfffff
    800024d2:	1a4080e7          	jalr	420(ra) # 80001672 <copyout>
    800024d6:	02054563          	bltz	a0,80002500 <wait+0x9c>
          freeproc(np);
    800024da:	8526                	mv	a0,s1
    800024dc:	00000097          	auipc	ra,0x0
    800024e0:	95c080e7          	jalr	-1700(ra) # 80001e38 <freeproc>
          release(&np->lock);
    800024e4:	8526                	mv	a0,s1
    800024e6:	ffffe097          	auipc	ra,0xffffe
    800024ea:	7b2080e7          	jalr	1970(ra) # 80000c98 <release>
          release(&wait_lock);
    800024ee:	0000f517          	auipc	a0,0xf
    800024f2:	28a50513          	addi	a0,a0,650 # 80011778 <wait_lock>
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	7a2080e7          	jalr	1954(ra) # 80000c98 <release>
          return pid;
    800024fe:	a09d                	j	80002564 <wait+0x100>
            release(&np->lock);
    80002500:	8526                	mv	a0,s1
    80002502:	ffffe097          	auipc	ra,0xffffe
    80002506:	796080e7          	jalr	1942(ra) # 80000c98 <release>
            release(&wait_lock);
    8000250a:	0000f517          	auipc	a0,0xf
    8000250e:	26e50513          	addi	a0,a0,622 # 80011778 <wait_lock>
    80002512:	ffffe097          	auipc	ra,0xffffe
    80002516:	786080e7          	jalr	1926(ra) # 80000c98 <release>
            return -1;
    8000251a:	59fd                	li	s3,-1
    8000251c:	a0a1                	j	80002564 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000251e:	17848493          	addi	s1,s1,376
    80002522:	03348463          	beq	s1,s3,8000254a <wait+0xe6>
      if(np->parent == p){
    80002526:	7c9c                	ld	a5,56(s1)
    80002528:	ff279be3          	bne	a5,s2,8000251e <wait+0xba>
        acquire(&np->lock);
    8000252c:	8526                	mv	a0,s1
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	6b6080e7          	jalr	1718(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002536:	4c9c                	lw	a5,24(s1)
    80002538:	f94781e3          	beq	a5,s4,800024ba <wait+0x56>
        release(&np->lock);
    8000253c:	8526                	mv	a0,s1
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	75a080e7          	jalr	1882(ra) # 80000c98 <release>
        havekids = 1;
    80002546:	8756                	mv	a4,s5
    80002548:	bfd9                	j	8000251e <wait+0xba>
    if(!havekids || p->killed){
    8000254a:	c701                	beqz	a4,80002552 <wait+0xee>
    8000254c:	02892783          	lw	a5,40(s2)
    80002550:	c79d                	beqz	a5,8000257e <wait+0x11a>
      release(&wait_lock);
    80002552:	0000f517          	auipc	a0,0xf
    80002556:	22650513          	addi	a0,a0,550 # 80011778 <wait_lock>
    8000255a:	ffffe097          	auipc	ra,0xffffe
    8000255e:	73e080e7          	jalr	1854(ra) # 80000c98 <release>
      return -1;
    80002562:	59fd                	li	s3,-1
}
    80002564:	854e                	mv	a0,s3
    80002566:	60a6                	ld	ra,72(sp)
    80002568:	6406                	ld	s0,64(sp)
    8000256a:	74e2                	ld	s1,56(sp)
    8000256c:	7942                	ld	s2,48(sp)
    8000256e:	79a2                	ld	s3,40(sp)
    80002570:	7a02                	ld	s4,32(sp)
    80002572:	6ae2                	ld	s5,24(sp)
    80002574:	6b42                	ld	s6,16(sp)
    80002576:	6ba2                	ld	s7,8(sp)
    80002578:	6c02                	ld	s8,0(sp)
    8000257a:	6161                	addi	sp,sp,80
    8000257c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000257e:	85e2                	mv	a1,s8
    80002580:	854a                	mv	a0,s2
    80002582:	00000097          	auipc	ra,0x0
    80002586:	e58080e7          	jalr	-424(ra) # 800023da <sleep>
    havekids = 0;
    8000258a:	b715                	j	800024ae <wait+0x4a>

000000008000258c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000258c:	7179                	addi	sp,sp,-48
    8000258e:	f406                	sd	ra,40(sp)
    80002590:	f022                	sd	s0,32(sp)
    80002592:	ec26                	sd	s1,24(sp)
    80002594:	e84a                	sd	s2,16(sp)
    80002596:	e44e                	sd	s3,8(sp)
    80002598:	1800                	addi	s0,sp,48
    8000259a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000259c:	0000f497          	auipc	s1,0xf
    800025a0:	1f448493          	addi	s1,s1,500 # 80011790 <proc>
    800025a4:	00015997          	auipc	s3,0x15
    800025a8:	fec98993          	addi	s3,s3,-20 # 80017590 <tickslock>
    acquire(&p->lock);
    800025ac:	8526                	mv	a0,s1
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	636080e7          	jalr	1590(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800025b6:	589c                	lw	a5,48(s1)
    800025b8:	01278d63          	beq	a5,s2,800025d2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025bc:	8526                	mv	a0,s1
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	6da080e7          	jalr	1754(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c6:	17848493          	addi	s1,s1,376
    800025ca:	ff3491e3          	bne	s1,s3,800025ac <kill+0x20>
  }
  return -1;
    800025ce:	557d                	li	a0,-1
    800025d0:	a829                	j	800025ea <kill+0x5e>
      p->killed = 1;
    800025d2:	4785                	li	a5,1
    800025d4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025d6:	4c98                	lw	a4,24(s1)
    800025d8:	4789                	li	a5,2
    800025da:	00f70f63          	beq	a4,a5,800025f8 <kill+0x6c>
      release(&p->lock);
    800025de:	8526                	mv	a0,s1
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	6b8080e7          	jalr	1720(ra) # 80000c98 <release>
      return 0;
    800025e8:	4501                	li	a0,0
}
    800025ea:	70a2                	ld	ra,40(sp)
    800025ec:	7402                	ld	s0,32(sp)
    800025ee:	64e2                	ld	s1,24(sp)
    800025f0:	6942                	ld	s2,16(sp)
    800025f2:	69a2                	ld	s3,8(sp)
    800025f4:	6145                	addi	sp,sp,48
    800025f6:	8082                	ret
        p->state = RUNNABLE;
    800025f8:	478d                	li	a5,3
    800025fa:	cc9c                	sw	a5,24(s1)
    800025fc:	b7cd                	j	800025de <kill+0x52>

00000000800025fe <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025fe:	7179                	addi	sp,sp,-48
    80002600:	f406                	sd	ra,40(sp)
    80002602:	f022                	sd	s0,32(sp)
    80002604:	ec26                	sd	s1,24(sp)
    80002606:	e84a                	sd	s2,16(sp)
    80002608:	e44e                	sd	s3,8(sp)
    8000260a:	e052                	sd	s4,0(sp)
    8000260c:	1800                	addi	s0,sp,48
    8000260e:	84aa                	mv	s1,a0
    80002610:	892e                	mv	s2,a1
    80002612:	89b2                	mv	s3,a2
    80002614:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002616:	fffff097          	auipc	ra,0xfffff
    8000261a:	676080e7          	jalr	1654(ra) # 80001c8c <myproc>
  if(user_dst){
    8000261e:	c08d                	beqz	s1,80002640 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002620:	86d2                	mv	a3,s4
    80002622:	864e                	mv	a2,s3
    80002624:	85ca                	mv	a1,s2
    80002626:	6928                	ld	a0,80(a0)
    80002628:	fffff097          	auipc	ra,0xfffff
    8000262c:	04a080e7          	jalr	74(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002630:	70a2                	ld	ra,40(sp)
    80002632:	7402                	ld	s0,32(sp)
    80002634:	64e2                	ld	s1,24(sp)
    80002636:	6942                	ld	s2,16(sp)
    80002638:	69a2                	ld	s3,8(sp)
    8000263a:	6a02                	ld	s4,0(sp)
    8000263c:	6145                	addi	sp,sp,48
    8000263e:	8082                	ret
    memmove((char *)dst, src, len);
    80002640:	000a061b          	sext.w	a2,s4
    80002644:	85ce                	mv	a1,s3
    80002646:	854a                	mv	a0,s2
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	6f8080e7          	jalr	1784(ra) # 80000d40 <memmove>
    return 0;
    80002650:	8526                	mv	a0,s1
    80002652:	bff9                	j	80002630 <either_copyout+0x32>

0000000080002654 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002654:	7179                	addi	sp,sp,-48
    80002656:	f406                	sd	ra,40(sp)
    80002658:	f022                	sd	s0,32(sp)
    8000265a:	ec26                	sd	s1,24(sp)
    8000265c:	e84a                	sd	s2,16(sp)
    8000265e:	e44e                	sd	s3,8(sp)
    80002660:	e052                	sd	s4,0(sp)
    80002662:	1800                	addi	s0,sp,48
    80002664:	892a                	mv	s2,a0
    80002666:	84ae                	mv	s1,a1
    80002668:	89b2                	mv	s3,a2
    8000266a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000266c:	fffff097          	auipc	ra,0xfffff
    80002670:	620080e7          	jalr	1568(ra) # 80001c8c <myproc>
  if(user_src){
    80002674:	c08d                	beqz	s1,80002696 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002676:	86d2                	mv	a3,s4
    80002678:	864e                	mv	a2,s3
    8000267a:	85ca                	mv	a1,s2
    8000267c:	6928                	ld	a0,80(a0)
    8000267e:	fffff097          	auipc	ra,0xfffff
    80002682:	080080e7          	jalr	128(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002686:	70a2                	ld	ra,40(sp)
    80002688:	7402                	ld	s0,32(sp)
    8000268a:	64e2                	ld	s1,24(sp)
    8000268c:	6942                	ld	s2,16(sp)
    8000268e:	69a2                	ld	s3,8(sp)
    80002690:	6a02                	ld	s4,0(sp)
    80002692:	6145                	addi	sp,sp,48
    80002694:	8082                	ret
    memmove(dst, (char*)src, len);
    80002696:	000a061b          	sext.w	a2,s4
    8000269a:	85ce                	mv	a1,s3
    8000269c:	854a                	mv	a0,s2
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	6a2080e7          	jalr	1698(ra) # 80000d40 <memmove>
    return 0;
    800026a6:	8526                	mv	a0,s1
    800026a8:	bff9                	j	80002686 <either_copyin+0x32>

00000000800026aa <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    800026aa:	715d                	addi	sp,sp,-80
    800026ac:	e486                	sd	ra,72(sp)
    800026ae:	e0a2                	sd	s0,64(sp)
    800026b0:	fc26                	sd	s1,56(sp)
    800026b2:	f84a                	sd	s2,48(sp)
    800026b4:	f44e                	sd	s3,40(sp)
    800026b6:	f052                	sd	s4,32(sp)
    800026b8:	ec56                	sd	s5,24(sp)
    800026ba:	e85a                	sd	s6,16(sp)
    800026bc:	e45e                	sd	s7,8(sp)
    800026be:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026c0:	00006517          	auipc	a0,0x6
    800026c4:	c6050513          	addi	a0,a0,-928 # 80008320 <digits+0x2e0>
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	ec0080e7          	jalr	-320(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026d0:	0000f497          	auipc	s1,0xf
    800026d4:	21848493          	addi	s1,s1,536 # 800118e8 <proc+0x158>
    800026d8:	00015917          	auipc	s2,0x15
    800026dc:	01090913          	addi	s2,s2,16 # 800176e8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026e0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    800026e2:	00006997          	auipc	s3,0x6
    800026e6:	d2698993          	addi	s3,s3,-730 # 80008408 <digits+0x3c8>
    printf("%d %s %s", p->pid, state, p->name);
    800026ea:	00006a97          	auipc	s5,0x6
    800026ee:	d26a8a93          	addi	s5,s5,-730 # 80008410 <digits+0x3d0>
    printf("\n");
    800026f2:	00006a17          	auipc	s4,0x6
    800026f6:	c2ea0a13          	addi	s4,s4,-978 # 80008320 <digits+0x2e0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026fa:	00006b97          	auipc	s7,0x6
    800026fe:	ddeb8b93          	addi	s7,s7,-546 # 800084d8 <states.1792>
    80002702:	a00d                	j	80002724 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002704:	ed86a583          	lw	a1,-296(a3)
    80002708:	8556                	mv	a0,s5
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	e7e080e7          	jalr	-386(ra) # 80000588 <printf>
    printf("\n");
    80002712:	8552                	mv	a0,s4
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	e74080e7          	jalr	-396(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000271c:	17848493          	addi	s1,s1,376
    80002720:	03248163          	beq	s1,s2,80002742 <procdump+0x98>
    if(p->state == UNUSED)
    80002724:	86a6                	mv	a3,s1
    80002726:	ec04a783          	lw	a5,-320(s1)
    8000272a:	dbed                	beqz	a5,8000271c <procdump+0x72>
      state = "???"; 
    8000272c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000272e:	fcfb6be3          	bltu	s6,a5,80002704 <procdump+0x5a>
    80002732:	1782                	slli	a5,a5,0x20
    80002734:	9381                	srli	a5,a5,0x20
    80002736:	078e                	slli	a5,a5,0x3
    80002738:	97de                	add	a5,a5,s7
    8000273a:	6390                	ld	a2,0(a5)
    8000273c:	f661                	bnez	a2,80002704 <procdump+0x5a>
      state = "???"; 
    8000273e:	864e                	mv	a2,s3
    80002740:	b7d1                	j	80002704 <procdump+0x5a>
  }
}
    80002742:	60a6                	ld	ra,72(sp)
    80002744:	6406                	ld	s0,64(sp)
    80002746:	74e2                	ld	s1,56(sp)
    80002748:	7942                	ld	s2,48(sp)
    8000274a:	79a2                	ld	s3,40(sp)
    8000274c:	7a02                	ld	s4,32(sp)
    8000274e:	6ae2                	ld	s5,24(sp)
    80002750:	6b42                	ld	s6,16(sp)
    80002752:	6ba2                	ld	s7,8(sp)
    80002754:	6161                	addi	sp,sp,80
    80002756:	8082                	ret

0000000080002758 <set_cpu>:

// assign current process to a different CPU. 
int
set_cpu(int cpu_num){
    80002758:	1101                	addi	sp,sp,-32
    8000275a:	ec06                	sd	ra,24(sp)
    8000275c:	e822                	sd	s0,16(sp)
    8000275e:	e426                	sd	s1,8(sp)
    80002760:	e04a                	sd	s2,0(sp)
    80002762:	1000                	addi	s0,sp,32
    80002764:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002766:	fffff097          	auipc	ra,0xfffff
    8000276a:	526080e7          	jalr	1318(ra) # 80001c8c <myproc>
  if(cpu_num >= 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL){
    8000276e:	0004871b          	sext.w	a4,s1
    80002772:	479d                	li	a5,7
    80002774:	02e7e963          	bltu	a5,a4,800027a6 <set_cpu+0x4e>
    80002778:	892a                	mv	s2,a0
    acquire(&p->lock);
    8000277a:	ffffe097          	auipc	ra,0xffffe
    8000277e:	46a080e7          	jalr	1130(ra) # 80000be4 <acquire>
    p->last_cpu = cpu_num;
    80002782:	16992423          	sw	s1,360(s2)
    release(&p->lock);
    80002786:	854a                	mv	a0,s2
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	510080e7          	jalr	1296(ra) # 80000c98 <release>

    yield();
    80002790:	00000097          	auipc	ra,0x0
    80002794:	bd6080e7          	jalr	-1066(ra) # 80002366 <yield>

    return cpu_num;
    80002798:	8526                	mv	a0,s1
  }
  return -1;
}
    8000279a:	60e2                	ld	ra,24(sp)
    8000279c:	6442                	ld	s0,16(sp)
    8000279e:	64a2                	ld	s1,8(sp)
    800027a0:	6902                	ld	s2,0(sp)
    800027a2:	6105                	addi	sp,sp,32
    800027a4:	8082                	ret
  return -1;
    800027a6:	557d                	li	a0,-1
    800027a8:	bfcd                	j	8000279a <set_cpu+0x42>

00000000800027aa <get_cpu>:

// return the current CPU id.
int
get_cpu(void){
    800027aa:	1141                	addi	sp,sp,-16
    800027ac:	e406                	sd	ra,8(sp)
    800027ae:	e022                	sd	s0,0(sp)
    800027b0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027b2:	fffff097          	auipc	ra,0xfffff
    800027b6:	4da080e7          	jalr	1242(ra) # 80001c8c <myproc>
  return p->last_cpu;
}
    800027ba:	16852503          	lw	a0,360(a0)
    800027be:	60a2                	ld	ra,8(sp)
    800027c0:	6402                	ld	s0,0(sp)
    800027c2:	0141                	addi	sp,sp,16
    800027c4:	8082                	ret

00000000800027c6 <min_cpu>:

int
min_cpu(void){
    800027c6:	1141                	addi	sp,sp,-16
    800027c8:	e422                	sd	s0,8(sp)
    800027ca:	0800                	addi	s0,sp,16
  struct cpu *c, *min_cpu;
// should add an if to insure numberOfCpus>0
  min_cpu = cpus;
    800027cc:	0000f617          	auipc	a2,0xf
    800027d0:	ad460613          	addi	a2,a2,-1324 # 800112a0 <cpus>
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL ; c++){
    800027d4:	0000f797          	auipc	a5,0xf
    800027d8:	b6478793          	addi	a5,a5,-1180 # 80011338 <cpus+0x98>
    800027dc:	0000f597          	auipc	a1,0xf
    800027e0:	f8458593          	addi	a1,a1,-124 # 80011760 <pid_lock>
    800027e4:	a029                	j	800027ee <min_cpu+0x28>
    800027e6:	09878793          	addi	a5,a5,152
    800027ea:	00b78863          	beq	a5,a1,800027fa <min_cpu+0x34>
    if (c->cpu_process_count < min_cpu->cpu_process_count)
    800027ee:	6bd4                	ld	a3,144(a5)
    800027f0:	6a58                	ld	a4,144(a2)
    800027f2:	fee6fae3          	bgeu	a3,a4,800027e6 <min_cpu+0x20>
    800027f6:	863e                	mv	a2,a5
    800027f8:	b7fd                	j	800027e6 <min_cpu+0x20>
        min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    800027fa:	08862503          	lw	a0,136(a2)
    800027fe:	6422                	ld	s0,8(sp)
    80002800:	0141                	addi	sp,sp,16
    80002802:	8082                	ret

0000000080002804 <cpu_process_count>:

int
cpu_process_count(int cpu_num){
    80002804:	1141                	addi	sp,sp,-16
    80002806:	e422                	sd	s0,8(sp)
    80002808:	0800                	addi	s0,sp,16
  if (cpu_num > 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL) 
    8000280a:	fff5071b          	addiw	a4,a0,-1
    8000280e:	4799                	li	a5,6
    80002810:	02e7e063          	bltu	a5,a4,80002830 <cpu_process_count+0x2c>
    return cpus[cpu_num].cpu_process_count;
    80002814:	09800793          	li	a5,152
    80002818:	02f50533          	mul	a0,a0,a5
    8000281c:	0000f797          	auipc	a5,0xf
    80002820:	a8478793          	addi	a5,a5,-1404 # 800112a0 <cpus>
    80002824:	953e                	add	a0,a0,a5
    80002826:	09052503          	lw	a0,144(a0)
  return -1;
}
    8000282a:	6422                	ld	s0,8(sp)
    8000282c:	0141                	addi	sp,sp,16
    8000282e:	8082                	ret
  return -1;
    80002830:	557d                	li	a0,-1
    80002832:	bfe5                	j	8000282a <cpu_process_count+0x26>

0000000080002834 <increment_cpu_process_count>:

void 
increment_cpu_process_count(struct cpu *c){
    80002834:	1101                	addi	sp,sp,-32
    80002836:	ec06                	sd	ra,24(sp)
    80002838:	e822                	sd	s0,16(sp)
    8000283a:	e426                	sd	s1,8(sp)
    8000283c:	e04a                	sd	s2,0(sp)
    8000283e:	1000                	addi	s0,sp,32
    80002840:	84aa                	mv	s1,a0
  uint64 curr_count;
  do{
    curr_count = c->cpu_process_count;
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    80002842:	09050913          	addi	s2,a0,144
    curr_count = c->cpu_process_count;
    80002846:	68cc                	ld	a1,144(s1)
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    80002848:	0015861b          	addiw	a2,a1,1
    8000284c:	2581                	sext.w	a1,a1
    8000284e:	854a                	mv	a0,s2
    80002850:	00004097          	auipc	ra,0x4
    80002854:	076080e7          	jalr	118(ra) # 800068c6 <cas>
    80002858:	2501                	sext.w	a0,a0
    8000285a:	f575                	bnez	a0,80002846 <increment_cpu_process_count+0x12>
}
    8000285c:	60e2                	ld	ra,24(sp)
    8000285e:	6442                	ld	s0,16(sp)
    80002860:	64a2                	ld	s1,8(sp)
    80002862:	6902                	ld	s2,0(sp)
    80002864:	6105                	addi	sp,sp,32
    80002866:	8082                	ret

0000000080002868 <fork>:
{
    80002868:	7139                	addi	sp,sp,-64
    8000286a:	fc06                	sd	ra,56(sp)
    8000286c:	f822                	sd	s0,48(sp)
    8000286e:	f426                	sd	s1,40(sp)
    80002870:	f04a                	sd	s2,32(sp)
    80002872:	ec4e                	sd	s3,24(sp)
    80002874:	e852                	sd	s4,16(sp)
    80002876:	e456                	sd	s5,8(sp)
    80002878:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    8000287a:	fffff097          	auipc	ra,0xfffff
    8000287e:	412080e7          	jalr	1042(ra) # 80001c8c <myproc>
    80002882:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002884:	fffff097          	auipc	ra,0xfffff
    80002888:	658080e7          	jalr	1624(ra) # 80001edc <allocproc>
    8000288c:	16050063          	beqz	a0,800029ec <fork+0x184>
    80002890:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002892:	0489b603          	ld	a2,72(s3)
    80002896:	692c                	ld	a1,80(a0)
    80002898:	0509b503          	ld	a0,80(s3)
    8000289c:	fffff097          	auipc	ra,0xfffff
    800028a0:	cd2080e7          	jalr	-814(ra) # 8000156e <uvmcopy>
    800028a4:	04054663          	bltz	a0,800028f0 <fork+0x88>
  np->sz = p->sz;
    800028a8:	0489b783          	ld	a5,72(s3)
    800028ac:	04f93423          	sd	a5,72(s2)
  *(np->trapframe) = *(p->trapframe);
    800028b0:	0589b683          	ld	a3,88(s3)
    800028b4:	87b6                	mv	a5,a3
    800028b6:	05893703          	ld	a4,88(s2)
    800028ba:	12068693          	addi	a3,a3,288
    800028be:	0007b803          	ld	a6,0(a5)
    800028c2:	6788                	ld	a0,8(a5)
    800028c4:	6b8c                	ld	a1,16(a5)
    800028c6:	6f90                	ld	a2,24(a5)
    800028c8:	01073023          	sd	a6,0(a4)
    800028cc:	e708                	sd	a0,8(a4)
    800028ce:	eb0c                	sd	a1,16(a4)
    800028d0:	ef10                	sd	a2,24(a4)
    800028d2:	02078793          	addi	a5,a5,32
    800028d6:	02070713          	addi	a4,a4,32
    800028da:	fed792e3          	bne	a5,a3,800028be <fork+0x56>
  np->trapframe->a0 = 0;
    800028de:	05893783          	ld	a5,88(s2)
    800028e2:	0607b823          	sd	zero,112(a5)
    800028e6:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    800028ea:	15000a13          	li	s4,336
    800028ee:	a03d                	j	8000291c <fork+0xb4>
    freeproc(np);
    800028f0:	854a                	mv	a0,s2
    800028f2:	fffff097          	auipc	ra,0xfffff
    800028f6:	546080e7          	jalr	1350(ra) # 80001e38 <freeproc>
    release(&np->lock);
    800028fa:	854a                	mv	a0,s2
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	39c080e7          	jalr	924(ra) # 80000c98 <release>
    return -1;
    80002904:	5afd                	li	s5,-1
    80002906:	a8c9                	j	800029d8 <fork+0x170>
      np->ofile[i] = filedup(p->ofile[i]);
    80002908:	00002097          	auipc	ra,0x2
    8000290c:	274080e7          	jalr	628(ra) # 80004b7c <filedup>
    80002910:	009907b3          	add	a5,s2,s1
    80002914:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002916:	04a1                	addi	s1,s1,8
    80002918:	01448763          	beq	s1,s4,80002926 <fork+0xbe>
    if(p->ofile[i])
    8000291c:	009987b3          	add	a5,s3,s1
    80002920:	6388                	ld	a0,0(a5)
    80002922:	f17d                	bnez	a0,80002908 <fork+0xa0>
    80002924:	bfcd                	j	80002916 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002926:	1509b503          	ld	a0,336(s3)
    8000292a:	00001097          	auipc	ra,0x1
    8000292e:	3c8080e7          	jalr	968(ra) # 80003cf2 <idup>
    80002932:	14a93823          	sd	a0,336(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002936:	4641                	li	a2,16
    80002938:	15898593          	addi	a1,s3,344
    8000293c:	15890513          	addi	a0,s2,344
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	4f2080e7          	jalr	1266(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002948:	03092a83          	lw	s5,48(s2)
  release(&np->lock);
    8000294c:	854a                	mv	a0,s2
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	34a080e7          	jalr	842(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002956:	0000fa17          	auipc	s4,0xf
    8000295a:	94aa0a13          	addi	s4,s4,-1718 # 800112a0 <cpus>
    8000295e:	0000f497          	auipc	s1,0xf
    80002962:	e1a48493          	addi	s1,s1,-486 # 80011778 <wait_lock>
    80002966:	8526                	mv	a0,s1
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	27c080e7          	jalr	636(ra) # 80000be4 <acquire>
  np->parent = p;
    80002970:	03393c23          	sd	s3,56(s2)
  release(&wait_lock);
    80002974:	8526                	mv	a0,s1
    80002976:	ffffe097          	auipc	ra,0xffffe
    8000297a:	322080e7          	jalr	802(ra) # 80000c98 <release>
  acquire(&np->lock);
    8000297e:	854a                	mv	a0,s2
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	264080e7          	jalr	612(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002988:	478d                	li	a5,3
    8000298a:	00f92c23          	sw	a5,24(s2)
  np->last_cpu = p->last_cpu; // case BLNCFLG=OFF -> cpu = parent's cpu 
    8000298e:	1689a483          	lw	s1,360(s3)
    80002992:	16992423          	sw	s1,360(s2)
  struct cpu *c = &cpus[np->last_cpu];
    80002996:	09800513          	li	a0,152
    8000299a:	02a484b3          	mul	s1,s1,a0
  increment_cpu_process_count(c);
    8000299e:	009a0533          	add	a0,s4,s1
    800029a2:	00000097          	auipc	ra,0x0
    800029a6:	e92080e7          	jalr	-366(ra) # 80002834 <increment_cpu_process_count>
  printf("insert fork runnable %d\n", np->index); //delete
    800029aa:	16c92583          	lw	a1,364(s2)
    800029ae:	00006517          	auipc	a0,0x6
    800029b2:	a7250513          	addi	a0,a0,-1422 # 80008420 <digits+0x3e0>
    800029b6:	ffffe097          	auipc	ra,0xffffe
    800029ba:	bd2080e7          	jalr	-1070(ra) # 80000588 <printf>
  insert_proc_to_list(&(c->runnable_list), np); // admit the new process to the father’s current CPU’s ready list
    800029be:	08048513          	addi	a0,s1,128
    800029c2:	85ca                	mv	a1,s2
    800029c4:	9552                	add	a0,a0,s4
    800029c6:	fffff097          	auipc	ra,0xfffff
    800029ca:	f64080e7          	jalr	-156(ra) # 8000192a <insert_proc_to_list>
  release(&np->lock);
    800029ce:	854a                	mv	a0,s2
    800029d0:	ffffe097          	auipc	ra,0xffffe
    800029d4:	2c8080e7          	jalr	712(ra) # 80000c98 <release>
}
    800029d8:	8556                	mv	a0,s5
    800029da:	70e2                	ld	ra,56(sp)
    800029dc:	7442                	ld	s0,48(sp)
    800029de:	74a2                	ld	s1,40(sp)
    800029e0:	7902                	ld	s2,32(sp)
    800029e2:	69e2                	ld	s3,24(sp)
    800029e4:	6a42                	ld	s4,16(sp)
    800029e6:	6aa2                	ld	s5,8(sp)
    800029e8:	6121                	addi	sp,sp,64
    800029ea:	8082                	ret
    return -1;
    800029ec:	5afd                	li	s5,-1
    800029ee:	b7ed                	j	800029d8 <fork+0x170>

00000000800029f0 <wakeup>:
{
    800029f0:	7159                	addi	sp,sp,-112
    800029f2:	f486                	sd	ra,104(sp)
    800029f4:	f0a2                	sd	s0,96(sp)
    800029f6:	eca6                	sd	s1,88(sp)
    800029f8:	e8ca                	sd	s2,80(sp)
    800029fa:	e4ce                	sd	s3,72(sp)
    800029fc:	e0d2                	sd	s4,64(sp)
    800029fe:	fc56                	sd	s5,56(sp)
    80002a00:	f85a                	sd	s6,48(sp)
    80002a02:	f45e                	sd	s7,40(sp)
    80002a04:	f062                	sd	s8,32(sp)
    80002a06:	ec66                	sd	s9,24(sp)
    80002a08:	e86a                	sd	s10,16(sp)
    80002a0a:	e46e                	sd	s11,8(sp)
    80002a0c:	1880                	addi	s0,sp,112
  int curr = sleeping_list.head;
    80002a0e:	00006917          	auipc	s2,0x6
    80002a12:	04292903          	lw	s2,66(s2) # 80008a50 <sleeping_list>
  while(curr != -1) {
    80002a16:	57fd                	li	a5,-1
    80002a18:	0cf90263          	beq	s2,a5,80002adc <wakeup+0xec>
    80002a1c:	8baa                	mv	s7,a0
    p = &proc[curr];
    80002a1e:	17800a93          	li	s5,376
    80002a22:	0000fa17          	auipc	s4,0xf
    80002a26:	d6ea0a13          	addi	s4,s4,-658 # 80011790 <proc>
      if(p->state == SLEEPING && p->chan == chan) {
    80002a2a:	4b09                	li	s6,2
        p->state = RUNNABLE;
    80002a2c:	4d8d                	li	s11,3
    80002a2e:	09800d13          	li	s10,152
        c = &cpus[p->last_cpu];
    80002a32:	0000fc97          	auipc	s9,0xf
    80002a36:	86ec8c93          	addi	s9,s9,-1938 # 800112a0 <cpus>
    80002a3a:	a809                	j	80002a4c <wakeup+0x5c>
      release(&p->lock);
    80002a3c:	8526                	mv	a0,s1
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	25a080e7          	jalr	602(ra) # 80000c98 <release>
  while(curr != -1) {
    80002a46:	57fd                	li	a5,-1
    80002a48:	08f90a63          	beq	s2,a5,80002adc <wakeup+0xec>
    p = &proc[curr];
    80002a4c:	035904b3          	mul	s1,s2,s5
    80002a50:	94d2                	add	s1,s1,s4
    curr = p->next_index;
    80002a52:	1744a903          	lw	s2,372(s1)
    if(p != myproc()){
    80002a56:	fffff097          	auipc	ra,0xfffff
    80002a5a:	236080e7          	jalr	566(ra) # 80001c8c <myproc>
    80002a5e:	fea484e3          	beq	s1,a0,80002a46 <wakeup+0x56>
      acquire(&p->lock);
    80002a62:	8526                	mv	a0,s1
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	180080e7          	jalr	384(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002a6c:	4c9c                	lw	a5,24(s1)
    80002a6e:	fd6797e3          	bne	a5,s6,80002a3c <wakeup+0x4c>
    80002a72:	709c                	ld	a5,32(s1)
    80002a74:	fd7794e3          	bne	a5,s7,80002a3c <wakeup+0x4c>
        printf("remove wakeup sleep %d\n", p->index); //delete
    80002a78:	16c4a583          	lw	a1,364(s1)
    80002a7c:	00006517          	auipc	a0,0x6
    80002a80:	9c450513          	addi	a0,a0,-1596 # 80008440 <digits+0x400>
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	b04080e7          	jalr	-1276(ra) # 80000588 <printf>
        remove_proc_to_list(&sleeping_list, p);
    80002a8c:	85a6                	mv	a1,s1
    80002a8e:	00006517          	auipc	a0,0x6
    80002a92:	fc250513          	addi	a0,a0,-62 # 80008a50 <sleeping_list>
    80002a96:	fffff097          	auipc	ra,0xfffff
    80002a9a:	f34080e7          	jalr	-204(ra) # 800019ca <remove_proc_to_list>
        p->state = RUNNABLE;
    80002a9e:	01b4ac23          	sw	s11,24(s1)
        c = &cpus[p->last_cpu];
    80002aa2:	1684ac03          	lw	s8,360(s1)
    80002aa6:	03ac0c33          	mul	s8,s8,s10
        increment_cpu_process_count(c);
    80002aaa:	018c8533          	add	a0,s9,s8
    80002aae:	00000097          	auipc	ra,0x0
    80002ab2:	d86080e7          	jalr	-634(ra) # 80002834 <increment_cpu_process_count>
        printf("insert wakeup runnable %d\n", p->index); //delete
    80002ab6:	16c4a583          	lw	a1,364(s1)
    80002aba:	00006517          	auipc	a0,0x6
    80002abe:	99e50513          	addi	a0,a0,-1634 # 80008458 <digits+0x418>
    80002ac2:	ffffe097          	auipc	ra,0xffffe
    80002ac6:	ac6080e7          	jalr	-1338(ra) # 80000588 <printf>
        insert_proc_to_list(&(c->runnable_list), p);
    80002aca:	080c0513          	addi	a0,s8,128
    80002ace:	85a6                	mv	a1,s1
    80002ad0:	9566                	add	a0,a0,s9
    80002ad2:	fffff097          	auipc	ra,0xfffff
    80002ad6:	e58080e7          	jalr	-424(ra) # 8000192a <insert_proc_to_list>
    80002ada:	b78d                	j	80002a3c <wakeup+0x4c>
}
    80002adc:	70a6                	ld	ra,104(sp)
    80002ade:	7406                	ld	s0,96(sp)
    80002ae0:	64e6                	ld	s1,88(sp)
    80002ae2:	6946                	ld	s2,80(sp)
    80002ae4:	69a6                	ld	s3,72(sp)
    80002ae6:	6a06                	ld	s4,64(sp)
    80002ae8:	7ae2                	ld	s5,56(sp)
    80002aea:	7b42                	ld	s6,48(sp)
    80002aec:	7ba2                	ld	s7,40(sp)
    80002aee:	7c02                	ld	s8,32(sp)
    80002af0:	6ce2                	ld	s9,24(sp)
    80002af2:	6d42                	ld	s10,16(sp)
    80002af4:	6da2                	ld	s11,8(sp)
    80002af6:	6165                	addi	sp,sp,112
    80002af8:	8082                	ret

0000000080002afa <reparent>:
{
    80002afa:	7179                	addi	sp,sp,-48
    80002afc:	f406                	sd	ra,40(sp)
    80002afe:	f022                	sd	s0,32(sp)
    80002b00:	ec26                	sd	s1,24(sp)
    80002b02:	e84a                	sd	s2,16(sp)
    80002b04:	e44e                	sd	s3,8(sp)
    80002b06:	e052                	sd	s4,0(sp)
    80002b08:	1800                	addi	s0,sp,48
    80002b0a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002b0c:	0000f497          	auipc	s1,0xf
    80002b10:	c8448493          	addi	s1,s1,-892 # 80011790 <proc>
      pp->parent = initproc;
    80002b14:	00006a17          	auipc	s4,0x6
    80002b18:	514a0a13          	addi	s4,s4,1300 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002b1c:	00015997          	auipc	s3,0x15
    80002b20:	a7498993          	addi	s3,s3,-1420 # 80017590 <tickslock>
    80002b24:	a029                	j	80002b2e <reparent+0x34>
    80002b26:	17848493          	addi	s1,s1,376
    80002b2a:	01348d63          	beq	s1,s3,80002b44 <reparent+0x4a>
    if(pp->parent == p){
    80002b2e:	7c9c                	ld	a5,56(s1)
    80002b30:	ff279be3          	bne	a5,s2,80002b26 <reparent+0x2c>
      pp->parent = initproc;
    80002b34:	000a3503          	ld	a0,0(s4)
    80002b38:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002b3a:	00000097          	auipc	ra,0x0
    80002b3e:	eb6080e7          	jalr	-330(ra) # 800029f0 <wakeup>
    80002b42:	b7d5                	j	80002b26 <reparent+0x2c>
}
    80002b44:	70a2                	ld	ra,40(sp)
    80002b46:	7402                	ld	s0,32(sp)
    80002b48:	64e2                	ld	s1,24(sp)
    80002b4a:	6942                	ld	s2,16(sp)
    80002b4c:	69a2                	ld	s3,8(sp)
    80002b4e:	6a02                	ld	s4,0(sp)
    80002b50:	6145                	addi	sp,sp,48
    80002b52:	8082                	ret

0000000080002b54 <exit>:
{
    80002b54:	7179                	addi	sp,sp,-48
    80002b56:	f406                	sd	ra,40(sp)
    80002b58:	f022                	sd	s0,32(sp)
    80002b5a:	ec26                	sd	s1,24(sp)
    80002b5c:	e84a                	sd	s2,16(sp)
    80002b5e:	e44e                	sd	s3,8(sp)
    80002b60:	e052                	sd	s4,0(sp)
    80002b62:	1800                	addi	s0,sp,48
    80002b64:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	126080e7          	jalr	294(ra) # 80001c8c <myproc>
    80002b6e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002b70:	00006797          	auipc	a5,0x6
    80002b74:	4b87b783          	ld	a5,1208(a5) # 80009028 <initproc>
    80002b78:	0d050493          	addi	s1,a0,208
    80002b7c:	15050913          	addi	s2,a0,336
    80002b80:	02a79363          	bne	a5,a0,80002ba6 <exit+0x52>
    panic("init exiting");
    80002b84:	00006517          	auipc	a0,0x6
    80002b88:	8f450513          	addi	a0,a0,-1804 # 80008478 <digits+0x438>
    80002b8c:	ffffe097          	auipc	ra,0xffffe
    80002b90:	9b2080e7          	jalr	-1614(ra) # 8000053e <panic>
      fileclose(f);
    80002b94:	00002097          	auipc	ra,0x2
    80002b98:	03a080e7          	jalr	58(ra) # 80004bce <fileclose>
      p->ofile[fd] = 0;
    80002b9c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002ba0:	04a1                	addi	s1,s1,8
    80002ba2:	01248563          	beq	s1,s2,80002bac <exit+0x58>
    if(p->ofile[fd]){
    80002ba6:	6088                	ld	a0,0(s1)
    80002ba8:	f575                	bnez	a0,80002b94 <exit+0x40>
    80002baa:	bfdd                	j	80002ba0 <exit+0x4c>
  begin_op();
    80002bac:	00002097          	auipc	ra,0x2
    80002bb0:	b56080e7          	jalr	-1194(ra) # 80004702 <begin_op>
  iput(p->cwd);
    80002bb4:	1509b503          	ld	a0,336(s3)
    80002bb8:	00001097          	auipc	ra,0x1
    80002bbc:	332080e7          	jalr	818(ra) # 80003eea <iput>
  end_op();
    80002bc0:	00002097          	auipc	ra,0x2
    80002bc4:	bc2080e7          	jalr	-1086(ra) # 80004782 <end_op>
  p->cwd = 0;
    80002bc8:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002bcc:	0000f497          	auipc	s1,0xf
    80002bd0:	bac48493          	addi	s1,s1,-1108 # 80011778 <wait_lock>
    80002bd4:	8526                	mv	a0,s1
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	00e080e7          	jalr	14(ra) # 80000be4 <acquire>
  reparent(p);
    80002bde:	854e                	mv	a0,s3
    80002be0:	00000097          	auipc	ra,0x0
    80002be4:	f1a080e7          	jalr	-230(ra) # 80002afa <reparent>
  wakeup(p->parent);
    80002be8:	0389b503          	ld	a0,56(s3)
    80002bec:	00000097          	auipc	ra,0x0
    80002bf0:	e04080e7          	jalr	-508(ra) # 800029f0 <wakeup>
  acquire(&p->lock);
    80002bf4:	854e                	mv	a0,s3
    80002bf6:	ffffe097          	auipc	ra,0xffffe
    80002bfa:	fee080e7          	jalr	-18(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002bfe:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002c02:	4795                	li	a5,5
    80002c04:	00f9ac23          	sw	a5,24(s3)
  printf("insert exit zombie %d\n", p->index); //delete
    80002c08:	16c9a583          	lw	a1,364(s3)
    80002c0c:	00006517          	auipc	a0,0x6
    80002c10:	87c50513          	addi	a0,a0,-1924 # 80008488 <digits+0x448>
    80002c14:	ffffe097          	auipc	ra,0xffffe
    80002c18:	974080e7          	jalr	-1676(ra) # 80000588 <printf>
  insert_proc_to_list(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    80002c1c:	85ce                	mv	a1,s3
    80002c1e:	00006517          	auipc	a0,0x6
    80002c22:	e2a50513          	addi	a0,a0,-470 # 80008a48 <zombie_list>
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	d04080e7          	jalr	-764(ra) # 8000192a <insert_proc_to_list>
  release(&wait_lock);
    80002c2e:	8526                	mv	a0,s1
    80002c30:	ffffe097          	auipc	ra,0xffffe
    80002c34:	068080e7          	jalr	104(ra) # 80000c98 <release>
  sched();
    80002c38:	fffff097          	auipc	ra,0xfffff
    80002c3c:	62c080e7          	jalr	1580(ra) # 80002264 <sched>
  panic("zombie exit");
    80002c40:	00006517          	auipc	a0,0x6
    80002c44:	86050513          	addi	a0,a0,-1952 # 800084a0 <digits+0x460>
    80002c48:	ffffe097          	auipc	ra,0xffffe
    80002c4c:	8f6080e7          	jalr	-1802(ra) # 8000053e <panic>

0000000080002c50 <swtch>:
    80002c50:	00153023          	sd	ra,0(a0)
    80002c54:	00253423          	sd	sp,8(a0)
    80002c58:	e900                	sd	s0,16(a0)
    80002c5a:	ed04                	sd	s1,24(a0)
    80002c5c:	03253023          	sd	s2,32(a0)
    80002c60:	03353423          	sd	s3,40(a0)
    80002c64:	03453823          	sd	s4,48(a0)
    80002c68:	03553c23          	sd	s5,56(a0)
    80002c6c:	05653023          	sd	s6,64(a0)
    80002c70:	05753423          	sd	s7,72(a0)
    80002c74:	05853823          	sd	s8,80(a0)
    80002c78:	05953c23          	sd	s9,88(a0)
    80002c7c:	07a53023          	sd	s10,96(a0)
    80002c80:	07b53423          	sd	s11,104(a0)
    80002c84:	0005b083          	ld	ra,0(a1)
    80002c88:	0085b103          	ld	sp,8(a1)
    80002c8c:	6980                	ld	s0,16(a1)
    80002c8e:	6d84                	ld	s1,24(a1)
    80002c90:	0205b903          	ld	s2,32(a1)
    80002c94:	0285b983          	ld	s3,40(a1)
    80002c98:	0305ba03          	ld	s4,48(a1)
    80002c9c:	0385ba83          	ld	s5,56(a1)
    80002ca0:	0405bb03          	ld	s6,64(a1)
    80002ca4:	0485bb83          	ld	s7,72(a1)
    80002ca8:	0505bc03          	ld	s8,80(a1)
    80002cac:	0585bc83          	ld	s9,88(a1)
    80002cb0:	0605bd03          	ld	s10,96(a1)
    80002cb4:	0685bd83          	ld	s11,104(a1)
    80002cb8:	8082                	ret

0000000080002cba <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002cba:	1141                	addi	sp,sp,-16
    80002cbc:	e406                	sd	ra,8(sp)
    80002cbe:	e022                	sd	s0,0(sp)
    80002cc0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002cc2:	00006597          	auipc	a1,0x6
    80002cc6:	84658593          	addi	a1,a1,-1978 # 80008508 <states.1792+0x30>
    80002cca:	00015517          	auipc	a0,0x15
    80002cce:	8c650513          	addi	a0,a0,-1850 # 80017590 <tickslock>
    80002cd2:	ffffe097          	auipc	ra,0xffffe
    80002cd6:	e82080e7          	jalr	-382(ra) # 80000b54 <initlock>
}
    80002cda:	60a2                	ld	ra,8(sp)
    80002cdc:	6402                	ld	s0,0(sp)
    80002cde:	0141                	addi	sp,sp,16
    80002ce0:	8082                	ret

0000000080002ce2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002ce2:	1141                	addi	sp,sp,-16
    80002ce4:	e422                	sd	s0,8(sp)
    80002ce6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ce8:	00003797          	auipc	a5,0x3
    80002cec:	50878793          	addi	a5,a5,1288 # 800061f0 <kernelvec>
    80002cf0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002cf4:	6422                	ld	s0,8(sp)
    80002cf6:	0141                	addi	sp,sp,16
    80002cf8:	8082                	ret

0000000080002cfa <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002cfa:	1141                	addi	sp,sp,-16
    80002cfc:	e406                	sd	ra,8(sp)
    80002cfe:	e022                	sd	s0,0(sp)
    80002d00:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d02:	fffff097          	auipc	ra,0xfffff
    80002d06:	f8a080e7          	jalr	-118(ra) # 80001c8c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d0a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d0e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d10:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002d14:	00004617          	auipc	a2,0x4
    80002d18:	2ec60613          	addi	a2,a2,748 # 80007000 <_trampoline>
    80002d1c:	00004697          	auipc	a3,0x4
    80002d20:	2e468693          	addi	a3,a3,740 # 80007000 <_trampoline>
    80002d24:	8e91                	sub	a3,a3,a2
    80002d26:	040007b7          	lui	a5,0x4000
    80002d2a:	17fd                	addi	a5,a5,-1
    80002d2c:	07b2                	slli	a5,a5,0xc
    80002d2e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d30:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d34:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d36:	180026f3          	csrr	a3,satp
    80002d3a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d3c:	6d38                	ld	a4,88(a0)
    80002d3e:	6134                	ld	a3,64(a0)
    80002d40:	6585                	lui	a1,0x1
    80002d42:	96ae                	add	a3,a3,a1
    80002d44:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d46:	6d38                	ld	a4,88(a0)
    80002d48:	00000697          	auipc	a3,0x0
    80002d4c:	13868693          	addi	a3,a3,312 # 80002e80 <usertrap>
    80002d50:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d52:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d54:	8692                	mv	a3,tp
    80002d56:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d58:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d5c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d60:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d64:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d68:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d6a:	6f18                	ld	a4,24(a4)
    80002d6c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d70:	692c                	ld	a1,80(a0)
    80002d72:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002d74:	00004717          	auipc	a4,0x4
    80002d78:	31c70713          	addi	a4,a4,796 # 80007090 <userret>
    80002d7c:	8f11                	sub	a4,a4,a2
    80002d7e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002d80:	577d                	li	a4,-1
    80002d82:	177e                	slli	a4,a4,0x3f
    80002d84:	8dd9                	or	a1,a1,a4
    80002d86:	02000537          	lui	a0,0x2000
    80002d8a:	157d                	addi	a0,a0,-1
    80002d8c:	0536                	slli	a0,a0,0xd
    80002d8e:	9782                	jalr	a5
}
    80002d90:	60a2                	ld	ra,8(sp)
    80002d92:	6402                	ld	s0,0(sp)
    80002d94:	0141                	addi	sp,sp,16
    80002d96:	8082                	ret

0000000080002d98 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d98:	1101                	addi	sp,sp,-32
    80002d9a:	ec06                	sd	ra,24(sp)
    80002d9c:	e822                	sd	s0,16(sp)
    80002d9e:	e426                	sd	s1,8(sp)
    80002da0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002da2:	00014497          	auipc	s1,0x14
    80002da6:	7ee48493          	addi	s1,s1,2030 # 80017590 <tickslock>
    80002daa:	8526                	mv	a0,s1
    80002dac:	ffffe097          	auipc	ra,0xffffe
    80002db0:	e38080e7          	jalr	-456(ra) # 80000be4 <acquire>
  ticks++;
    80002db4:	00006517          	auipc	a0,0x6
    80002db8:	27c50513          	addi	a0,a0,636 # 80009030 <ticks>
    80002dbc:	411c                	lw	a5,0(a0)
    80002dbe:	2785                	addiw	a5,a5,1
    80002dc0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002dc2:	00000097          	auipc	ra,0x0
    80002dc6:	c2e080e7          	jalr	-978(ra) # 800029f0 <wakeup>
  release(&tickslock);
    80002dca:	8526                	mv	a0,s1
    80002dcc:	ffffe097          	auipc	ra,0xffffe
    80002dd0:	ecc080e7          	jalr	-308(ra) # 80000c98 <release>
}
    80002dd4:	60e2                	ld	ra,24(sp)
    80002dd6:	6442                	ld	s0,16(sp)
    80002dd8:	64a2                	ld	s1,8(sp)
    80002dda:	6105                	addi	sp,sp,32
    80002ddc:	8082                	ret

0000000080002dde <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002dde:	1101                	addi	sp,sp,-32
    80002de0:	ec06                	sd	ra,24(sp)
    80002de2:	e822                	sd	s0,16(sp)
    80002de4:	e426                	sd	s1,8(sp)
    80002de6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002de8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002dec:	00074d63          	bltz	a4,80002e06 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002df0:	57fd                	li	a5,-1
    80002df2:	17fe                	slli	a5,a5,0x3f
    80002df4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002df6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002df8:	06f70363          	beq	a4,a5,80002e5e <devintr+0x80>
  }
}
    80002dfc:	60e2                	ld	ra,24(sp)
    80002dfe:	6442                	ld	s0,16(sp)
    80002e00:	64a2                	ld	s1,8(sp)
    80002e02:	6105                	addi	sp,sp,32
    80002e04:	8082                	ret
     (scause & 0xff) == 9){
    80002e06:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002e0a:	46a5                	li	a3,9
    80002e0c:	fed792e3          	bne	a5,a3,80002df0 <devintr+0x12>
    int irq = plic_claim();
    80002e10:	00003097          	auipc	ra,0x3
    80002e14:	4e8080e7          	jalr	1256(ra) # 800062f8 <plic_claim>
    80002e18:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002e1a:	47a9                	li	a5,10
    80002e1c:	02f50763          	beq	a0,a5,80002e4a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002e20:	4785                	li	a5,1
    80002e22:	02f50963          	beq	a0,a5,80002e54 <devintr+0x76>
    return 1;
    80002e26:	4505                	li	a0,1
    } else if(irq){
    80002e28:	d8f1                	beqz	s1,80002dfc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e2a:	85a6                	mv	a1,s1
    80002e2c:	00005517          	auipc	a0,0x5
    80002e30:	6e450513          	addi	a0,a0,1764 # 80008510 <states.1792+0x38>
    80002e34:	ffffd097          	auipc	ra,0xffffd
    80002e38:	754080e7          	jalr	1876(ra) # 80000588 <printf>
      plic_complete(irq);
    80002e3c:	8526                	mv	a0,s1
    80002e3e:	00003097          	auipc	ra,0x3
    80002e42:	4de080e7          	jalr	1246(ra) # 8000631c <plic_complete>
    return 1;
    80002e46:	4505                	li	a0,1
    80002e48:	bf55                	j	80002dfc <devintr+0x1e>
      uartintr();
    80002e4a:	ffffe097          	auipc	ra,0xffffe
    80002e4e:	b5e080e7          	jalr	-1186(ra) # 800009a8 <uartintr>
    80002e52:	b7ed                	j	80002e3c <devintr+0x5e>
      virtio_disk_intr();
    80002e54:	00004097          	auipc	ra,0x4
    80002e58:	9a8080e7          	jalr	-1624(ra) # 800067fc <virtio_disk_intr>
    80002e5c:	b7c5                	j	80002e3c <devintr+0x5e>
    if(cpuid() == 0){
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	dfc080e7          	jalr	-516(ra) # 80001c5a <cpuid>
    80002e66:	c901                	beqz	a0,80002e76 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e68:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e6c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e6e:	14479073          	csrw	sip,a5
    return 2;
    80002e72:	4509                	li	a0,2
    80002e74:	b761                	j	80002dfc <devintr+0x1e>
      clockintr();
    80002e76:	00000097          	auipc	ra,0x0
    80002e7a:	f22080e7          	jalr	-222(ra) # 80002d98 <clockintr>
    80002e7e:	b7ed                	j	80002e68 <devintr+0x8a>

0000000080002e80 <usertrap>:
{
    80002e80:	1101                	addi	sp,sp,-32
    80002e82:	ec06                	sd	ra,24(sp)
    80002e84:	e822                	sd	s0,16(sp)
    80002e86:	e426                	sd	s1,8(sp)
    80002e88:	e04a                	sd	s2,0(sp)
    80002e8a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e8c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e90:	1007f793          	andi	a5,a5,256
    80002e94:	e3ad                	bnez	a5,80002ef6 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e96:	00003797          	auipc	a5,0x3
    80002e9a:	35a78793          	addi	a5,a5,858 # 800061f0 <kernelvec>
    80002e9e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ea2:	fffff097          	auipc	ra,0xfffff
    80002ea6:	dea080e7          	jalr	-534(ra) # 80001c8c <myproc>
    80002eaa:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002eac:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eae:	14102773          	csrr	a4,sepc
    80002eb2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eb4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002eb8:	47a1                	li	a5,8
    80002eba:	04f71c63          	bne	a4,a5,80002f12 <usertrap+0x92>
    if(p->killed)
    80002ebe:	551c                	lw	a5,40(a0)
    80002ec0:	e3b9                	bnez	a5,80002f06 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002ec2:	6cb8                	ld	a4,88(s1)
    80002ec4:	6f1c                	ld	a5,24(a4)
    80002ec6:	0791                	addi	a5,a5,4
    80002ec8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ece:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ed2:	10079073          	csrw	sstatus,a5
    syscall();
    80002ed6:	00000097          	auipc	ra,0x0
    80002eda:	2e0080e7          	jalr	736(ra) # 800031b6 <syscall>
  if(p->killed)
    80002ede:	549c                	lw	a5,40(s1)
    80002ee0:	ebc1                	bnez	a5,80002f70 <usertrap+0xf0>
  usertrapret();
    80002ee2:	00000097          	auipc	ra,0x0
    80002ee6:	e18080e7          	jalr	-488(ra) # 80002cfa <usertrapret>
}
    80002eea:	60e2                	ld	ra,24(sp)
    80002eec:	6442                	ld	s0,16(sp)
    80002eee:	64a2                	ld	s1,8(sp)
    80002ef0:	6902                	ld	s2,0(sp)
    80002ef2:	6105                	addi	sp,sp,32
    80002ef4:	8082                	ret
    panic("usertrap: not from user mode");
    80002ef6:	00005517          	auipc	a0,0x5
    80002efa:	63a50513          	addi	a0,a0,1594 # 80008530 <states.1792+0x58>
    80002efe:	ffffd097          	auipc	ra,0xffffd
    80002f02:	640080e7          	jalr	1600(ra) # 8000053e <panic>
      exit(-1);
    80002f06:	557d                	li	a0,-1
    80002f08:	00000097          	auipc	ra,0x0
    80002f0c:	c4c080e7          	jalr	-948(ra) # 80002b54 <exit>
    80002f10:	bf4d                	j	80002ec2 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002f12:	00000097          	auipc	ra,0x0
    80002f16:	ecc080e7          	jalr	-308(ra) # 80002dde <devintr>
    80002f1a:	892a                	mv	s2,a0
    80002f1c:	c501                	beqz	a0,80002f24 <usertrap+0xa4>
  if(p->killed)
    80002f1e:	549c                	lw	a5,40(s1)
    80002f20:	c3a1                	beqz	a5,80002f60 <usertrap+0xe0>
    80002f22:	a815                	j	80002f56 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f24:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f28:	5890                	lw	a2,48(s1)
    80002f2a:	00005517          	auipc	a0,0x5
    80002f2e:	62650513          	addi	a0,a0,1574 # 80008550 <states.1792+0x78>
    80002f32:	ffffd097          	auipc	ra,0xffffd
    80002f36:	656080e7          	jalr	1622(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f3a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f3e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f42:	00005517          	auipc	a0,0x5
    80002f46:	63e50513          	addi	a0,a0,1598 # 80008580 <states.1792+0xa8>
    80002f4a:	ffffd097          	auipc	ra,0xffffd
    80002f4e:	63e080e7          	jalr	1598(ra) # 80000588 <printf>
    p->killed = 1;
    80002f52:	4785                	li	a5,1
    80002f54:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002f56:	557d                	li	a0,-1
    80002f58:	00000097          	auipc	ra,0x0
    80002f5c:	bfc080e7          	jalr	-1028(ra) # 80002b54 <exit>
  if(which_dev == 2)
    80002f60:	4789                	li	a5,2
    80002f62:	f8f910e3          	bne	s2,a5,80002ee2 <usertrap+0x62>
    yield();
    80002f66:	fffff097          	auipc	ra,0xfffff
    80002f6a:	400080e7          	jalr	1024(ra) # 80002366 <yield>
    80002f6e:	bf95                	j	80002ee2 <usertrap+0x62>
  int which_dev = 0;
    80002f70:	4901                	li	s2,0
    80002f72:	b7d5                	j	80002f56 <usertrap+0xd6>

0000000080002f74 <kerneltrap>:
{
    80002f74:	7179                	addi	sp,sp,-48
    80002f76:	f406                	sd	ra,40(sp)
    80002f78:	f022                	sd	s0,32(sp)
    80002f7a:	ec26                	sd	s1,24(sp)
    80002f7c:	e84a                	sd	s2,16(sp)
    80002f7e:	e44e                	sd	s3,8(sp)
    80002f80:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f82:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f86:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f8a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f8e:	1004f793          	andi	a5,s1,256
    80002f92:	cb85                	beqz	a5,80002fc2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f94:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f98:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f9a:	ef85                	bnez	a5,80002fd2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f9c:	00000097          	auipc	ra,0x0
    80002fa0:	e42080e7          	jalr	-446(ra) # 80002dde <devintr>
    80002fa4:	cd1d                	beqz	a0,80002fe2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002fa6:	4789                	li	a5,2
    80002fa8:	06f50a63          	beq	a0,a5,8000301c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002fac:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fb0:	10049073          	csrw	sstatus,s1
}
    80002fb4:	70a2                	ld	ra,40(sp)
    80002fb6:	7402                	ld	s0,32(sp)
    80002fb8:	64e2                	ld	s1,24(sp)
    80002fba:	6942                	ld	s2,16(sp)
    80002fbc:	69a2                	ld	s3,8(sp)
    80002fbe:	6145                	addi	sp,sp,48
    80002fc0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002fc2:	00005517          	auipc	a0,0x5
    80002fc6:	5de50513          	addi	a0,a0,1502 # 800085a0 <states.1792+0xc8>
    80002fca:	ffffd097          	auipc	ra,0xffffd
    80002fce:	574080e7          	jalr	1396(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002fd2:	00005517          	auipc	a0,0x5
    80002fd6:	5f650513          	addi	a0,a0,1526 # 800085c8 <states.1792+0xf0>
    80002fda:	ffffd097          	auipc	ra,0xffffd
    80002fde:	564080e7          	jalr	1380(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002fe2:	85ce                	mv	a1,s3
    80002fe4:	00005517          	auipc	a0,0x5
    80002fe8:	60450513          	addi	a0,a0,1540 # 800085e8 <states.1792+0x110>
    80002fec:	ffffd097          	auipc	ra,0xffffd
    80002ff0:	59c080e7          	jalr	1436(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ff4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ff8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ffc:	00005517          	auipc	a0,0x5
    80003000:	5fc50513          	addi	a0,a0,1532 # 800085f8 <states.1792+0x120>
    80003004:	ffffd097          	auipc	ra,0xffffd
    80003008:	584080e7          	jalr	1412(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000300c:	00005517          	auipc	a0,0x5
    80003010:	60450513          	addi	a0,a0,1540 # 80008610 <states.1792+0x138>
    80003014:	ffffd097          	auipc	ra,0xffffd
    80003018:	52a080e7          	jalr	1322(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000301c:	fffff097          	auipc	ra,0xfffff
    80003020:	c70080e7          	jalr	-912(ra) # 80001c8c <myproc>
    80003024:	d541                	beqz	a0,80002fac <kerneltrap+0x38>
    80003026:	fffff097          	auipc	ra,0xfffff
    8000302a:	c66080e7          	jalr	-922(ra) # 80001c8c <myproc>
    8000302e:	4d18                	lw	a4,24(a0)
    80003030:	4791                	li	a5,4
    80003032:	f6f71de3          	bne	a4,a5,80002fac <kerneltrap+0x38>
    yield();
    80003036:	fffff097          	auipc	ra,0xfffff
    8000303a:	330080e7          	jalr	816(ra) # 80002366 <yield>
    8000303e:	b7bd                	j	80002fac <kerneltrap+0x38>

0000000080003040 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003040:	1101                	addi	sp,sp,-32
    80003042:	ec06                	sd	ra,24(sp)
    80003044:	e822                	sd	s0,16(sp)
    80003046:	e426                	sd	s1,8(sp)
    80003048:	1000                	addi	s0,sp,32
    8000304a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000304c:	fffff097          	auipc	ra,0xfffff
    80003050:	c40080e7          	jalr	-960(ra) # 80001c8c <myproc>
  switch (n) {
    80003054:	4795                	li	a5,5
    80003056:	0497e163          	bltu	a5,s1,80003098 <argraw+0x58>
    8000305a:	048a                	slli	s1,s1,0x2
    8000305c:	00005717          	auipc	a4,0x5
    80003060:	5ec70713          	addi	a4,a4,1516 # 80008648 <states.1792+0x170>
    80003064:	94ba                	add	s1,s1,a4
    80003066:	409c                	lw	a5,0(s1)
    80003068:	97ba                	add	a5,a5,a4
    8000306a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000306c:	6d3c                	ld	a5,88(a0)
    8000306e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003070:	60e2                	ld	ra,24(sp)
    80003072:	6442                	ld	s0,16(sp)
    80003074:	64a2                	ld	s1,8(sp)
    80003076:	6105                	addi	sp,sp,32
    80003078:	8082                	ret
    return p->trapframe->a1;
    8000307a:	6d3c                	ld	a5,88(a0)
    8000307c:	7fa8                	ld	a0,120(a5)
    8000307e:	bfcd                	j	80003070 <argraw+0x30>
    return p->trapframe->a2;
    80003080:	6d3c                	ld	a5,88(a0)
    80003082:	63c8                	ld	a0,128(a5)
    80003084:	b7f5                	j	80003070 <argraw+0x30>
    return p->trapframe->a3;
    80003086:	6d3c                	ld	a5,88(a0)
    80003088:	67c8                	ld	a0,136(a5)
    8000308a:	b7dd                	j	80003070 <argraw+0x30>
    return p->trapframe->a4;
    8000308c:	6d3c                	ld	a5,88(a0)
    8000308e:	6bc8                	ld	a0,144(a5)
    80003090:	b7c5                	j	80003070 <argraw+0x30>
    return p->trapframe->a5;
    80003092:	6d3c                	ld	a5,88(a0)
    80003094:	6fc8                	ld	a0,152(a5)
    80003096:	bfe9                	j	80003070 <argraw+0x30>
  panic("argraw");
    80003098:	00005517          	auipc	a0,0x5
    8000309c:	58850513          	addi	a0,a0,1416 # 80008620 <states.1792+0x148>
    800030a0:	ffffd097          	auipc	ra,0xffffd
    800030a4:	49e080e7          	jalr	1182(ra) # 8000053e <panic>

00000000800030a8 <fetchaddr>:
{
    800030a8:	1101                	addi	sp,sp,-32
    800030aa:	ec06                	sd	ra,24(sp)
    800030ac:	e822                	sd	s0,16(sp)
    800030ae:	e426                	sd	s1,8(sp)
    800030b0:	e04a                	sd	s2,0(sp)
    800030b2:	1000                	addi	s0,sp,32
    800030b4:	84aa                	mv	s1,a0
    800030b6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800030b8:	fffff097          	auipc	ra,0xfffff
    800030bc:	bd4080e7          	jalr	-1068(ra) # 80001c8c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800030c0:	653c                	ld	a5,72(a0)
    800030c2:	02f4f863          	bgeu	s1,a5,800030f2 <fetchaddr+0x4a>
    800030c6:	00848713          	addi	a4,s1,8
    800030ca:	02e7e663          	bltu	a5,a4,800030f6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800030ce:	46a1                	li	a3,8
    800030d0:	8626                	mv	a2,s1
    800030d2:	85ca                	mv	a1,s2
    800030d4:	6928                	ld	a0,80(a0)
    800030d6:	ffffe097          	auipc	ra,0xffffe
    800030da:	628080e7          	jalr	1576(ra) # 800016fe <copyin>
    800030de:	00a03533          	snez	a0,a0
    800030e2:	40a00533          	neg	a0,a0
}
    800030e6:	60e2                	ld	ra,24(sp)
    800030e8:	6442                	ld	s0,16(sp)
    800030ea:	64a2                	ld	s1,8(sp)
    800030ec:	6902                	ld	s2,0(sp)
    800030ee:	6105                	addi	sp,sp,32
    800030f0:	8082                	ret
    return -1;
    800030f2:	557d                	li	a0,-1
    800030f4:	bfcd                	j	800030e6 <fetchaddr+0x3e>
    800030f6:	557d                	li	a0,-1
    800030f8:	b7fd                	j	800030e6 <fetchaddr+0x3e>

00000000800030fa <fetchstr>:
{
    800030fa:	7179                	addi	sp,sp,-48
    800030fc:	f406                	sd	ra,40(sp)
    800030fe:	f022                	sd	s0,32(sp)
    80003100:	ec26                	sd	s1,24(sp)
    80003102:	e84a                	sd	s2,16(sp)
    80003104:	e44e                	sd	s3,8(sp)
    80003106:	1800                	addi	s0,sp,48
    80003108:	892a                	mv	s2,a0
    8000310a:	84ae                	mv	s1,a1
    8000310c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000310e:	fffff097          	auipc	ra,0xfffff
    80003112:	b7e080e7          	jalr	-1154(ra) # 80001c8c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003116:	86ce                	mv	a3,s3
    80003118:	864a                	mv	a2,s2
    8000311a:	85a6                	mv	a1,s1
    8000311c:	6928                	ld	a0,80(a0)
    8000311e:	ffffe097          	auipc	ra,0xffffe
    80003122:	66c080e7          	jalr	1644(ra) # 8000178a <copyinstr>
  if(err < 0)
    80003126:	00054763          	bltz	a0,80003134 <fetchstr+0x3a>
  return strlen(buf);
    8000312a:	8526                	mv	a0,s1
    8000312c:	ffffe097          	auipc	ra,0xffffe
    80003130:	d38080e7          	jalr	-712(ra) # 80000e64 <strlen>
}
    80003134:	70a2                	ld	ra,40(sp)
    80003136:	7402                	ld	s0,32(sp)
    80003138:	64e2                	ld	s1,24(sp)
    8000313a:	6942                	ld	s2,16(sp)
    8000313c:	69a2                	ld	s3,8(sp)
    8000313e:	6145                	addi	sp,sp,48
    80003140:	8082                	ret

0000000080003142 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003142:	1101                	addi	sp,sp,-32
    80003144:	ec06                	sd	ra,24(sp)
    80003146:	e822                	sd	s0,16(sp)
    80003148:	e426                	sd	s1,8(sp)
    8000314a:	1000                	addi	s0,sp,32
    8000314c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000314e:	00000097          	auipc	ra,0x0
    80003152:	ef2080e7          	jalr	-270(ra) # 80003040 <argraw>
    80003156:	c088                	sw	a0,0(s1)
  return 0;
}
    80003158:	4501                	li	a0,0
    8000315a:	60e2                	ld	ra,24(sp)
    8000315c:	6442                	ld	s0,16(sp)
    8000315e:	64a2                	ld	s1,8(sp)
    80003160:	6105                	addi	sp,sp,32
    80003162:	8082                	ret

0000000080003164 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003164:	1101                	addi	sp,sp,-32
    80003166:	ec06                	sd	ra,24(sp)
    80003168:	e822                	sd	s0,16(sp)
    8000316a:	e426                	sd	s1,8(sp)
    8000316c:	1000                	addi	s0,sp,32
    8000316e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003170:	00000097          	auipc	ra,0x0
    80003174:	ed0080e7          	jalr	-304(ra) # 80003040 <argraw>
    80003178:	e088                	sd	a0,0(s1)
  return 0;
}
    8000317a:	4501                	li	a0,0
    8000317c:	60e2                	ld	ra,24(sp)
    8000317e:	6442                	ld	s0,16(sp)
    80003180:	64a2                	ld	s1,8(sp)
    80003182:	6105                	addi	sp,sp,32
    80003184:	8082                	ret

0000000080003186 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003186:	1101                	addi	sp,sp,-32
    80003188:	ec06                	sd	ra,24(sp)
    8000318a:	e822                	sd	s0,16(sp)
    8000318c:	e426                	sd	s1,8(sp)
    8000318e:	e04a                	sd	s2,0(sp)
    80003190:	1000                	addi	s0,sp,32
    80003192:	84ae                	mv	s1,a1
    80003194:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003196:	00000097          	auipc	ra,0x0
    8000319a:	eaa080e7          	jalr	-342(ra) # 80003040 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000319e:	864a                	mv	a2,s2
    800031a0:	85a6                	mv	a1,s1
    800031a2:	00000097          	auipc	ra,0x0
    800031a6:	f58080e7          	jalr	-168(ra) # 800030fa <fetchstr>
}
    800031aa:	60e2                	ld	ra,24(sp)
    800031ac:	6442                	ld	s0,16(sp)
    800031ae:	64a2                	ld	s1,8(sp)
    800031b0:	6902                	ld	s2,0(sp)
    800031b2:	6105                	addi	sp,sp,32
    800031b4:	8082                	ret

00000000800031b6 <syscall>:
[SYS_cpu_process_count]   sys_cpu_process_count,
};

void
syscall(void)
{
    800031b6:	1101                	addi	sp,sp,-32
    800031b8:	ec06                	sd	ra,24(sp)
    800031ba:	e822                	sd	s0,16(sp)
    800031bc:	e426                	sd	s1,8(sp)
    800031be:	e04a                	sd	s2,0(sp)
    800031c0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800031c2:	fffff097          	auipc	ra,0xfffff
    800031c6:	aca080e7          	jalr	-1334(ra) # 80001c8c <myproc>
    800031ca:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800031cc:	05853903          	ld	s2,88(a0)
    800031d0:	0a893783          	ld	a5,168(s2)
    800031d4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800031d8:	37fd                	addiw	a5,a5,-1
    800031da:	475d                	li	a4,23
    800031dc:	00f76f63          	bltu	a4,a5,800031fa <syscall+0x44>
    800031e0:	00369713          	slli	a4,a3,0x3
    800031e4:	00005797          	auipc	a5,0x5
    800031e8:	47c78793          	addi	a5,a5,1148 # 80008660 <syscalls>
    800031ec:	97ba                	add	a5,a5,a4
    800031ee:	639c                	ld	a5,0(a5)
    800031f0:	c789                	beqz	a5,800031fa <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800031f2:	9782                	jalr	a5
    800031f4:	06a93823          	sd	a0,112(s2)
    800031f8:	a839                	j	80003216 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800031fa:	15848613          	addi	a2,s1,344
    800031fe:	588c                	lw	a1,48(s1)
    80003200:	00005517          	auipc	a0,0x5
    80003204:	42850513          	addi	a0,a0,1064 # 80008628 <states.1792+0x150>
    80003208:	ffffd097          	auipc	ra,0xffffd
    8000320c:	380080e7          	jalr	896(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003210:	6cbc                	ld	a5,88(s1)
    80003212:	577d                	li	a4,-1
    80003214:	fbb8                	sd	a4,112(a5)
  }
}
    80003216:	60e2                	ld	ra,24(sp)
    80003218:	6442                	ld	s0,16(sp)
    8000321a:	64a2                	ld	s1,8(sp)
    8000321c:	6902                	ld	s2,0(sp)
    8000321e:	6105                	addi	sp,sp,32
    80003220:	8082                	ret

0000000080003222 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003222:	1101                	addi	sp,sp,-32
    80003224:	ec06                	sd	ra,24(sp)
    80003226:	e822                	sd	s0,16(sp)
    80003228:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000322a:	fec40593          	addi	a1,s0,-20
    8000322e:	4501                	li	a0,0
    80003230:	00000097          	auipc	ra,0x0
    80003234:	f12080e7          	jalr	-238(ra) # 80003142 <argint>
    return -1;
    80003238:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000323a:	00054963          	bltz	a0,8000324c <sys_exit+0x2a>
  exit(n);
    8000323e:	fec42503          	lw	a0,-20(s0)
    80003242:	00000097          	auipc	ra,0x0
    80003246:	912080e7          	jalr	-1774(ra) # 80002b54 <exit>
  return 0;  // not reached
    8000324a:	4781                	li	a5,0
}
    8000324c:	853e                	mv	a0,a5
    8000324e:	60e2                	ld	ra,24(sp)
    80003250:	6442                	ld	s0,16(sp)
    80003252:	6105                	addi	sp,sp,32
    80003254:	8082                	ret

0000000080003256 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003256:	1141                	addi	sp,sp,-16
    80003258:	e406                	sd	ra,8(sp)
    8000325a:	e022                	sd	s0,0(sp)
    8000325c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000325e:	fffff097          	auipc	ra,0xfffff
    80003262:	a2e080e7          	jalr	-1490(ra) # 80001c8c <myproc>
}
    80003266:	5908                	lw	a0,48(a0)
    80003268:	60a2                	ld	ra,8(sp)
    8000326a:	6402                	ld	s0,0(sp)
    8000326c:	0141                	addi	sp,sp,16
    8000326e:	8082                	ret

0000000080003270 <sys_fork>:

uint64
sys_fork(void)
{
    80003270:	1141                	addi	sp,sp,-16
    80003272:	e406                	sd	ra,8(sp)
    80003274:	e022                	sd	s0,0(sp)
    80003276:	0800                	addi	s0,sp,16
  return fork();
    80003278:	fffff097          	auipc	ra,0xfffff
    8000327c:	5f0080e7          	jalr	1520(ra) # 80002868 <fork>
}
    80003280:	60a2                	ld	ra,8(sp)
    80003282:	6402                	ld	s0,0(sp)
    80003284:	0141                	addi	sp,sp,16
    80003286:	8082                	ret

0000000080003288 <sys_wait>:

uint64
sys_wait(void)
{
    80003288:	1101                	addi	sp,sp,-32
    8000328a:	ec06                	sd	ra,24(sp)
    8000328c:	e822                	sd	s0,16(sp)
    8000328e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003290:	fe840593          	addi	a1,s0,-24
    80003294:	4501                	li	a0,0
    80003296:	00000097          	auipc	ra,0x0
    8000329a:	ece080e7          	jalr	-306(ra) # 80003164 <argaddr>
    8000329e:	87aa                	mv	a5,a0
    return -1;
    800032a0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800032a2:	0007c863          	bltz	a5,800032b2 <sys_wait+0x2a>
  return wait(p);
    800032a6:	fe843503          	ld	a0,-24(s0)
    800032aa:	fffff097          	auipc	ra,0xfffff
    800032ae:	1ba080e7          	jalr	442(ra) # 80002464 <wait>
}
    800032b2:	60e2                	ld	ra,24(sp)
    800032b4:	6442                	ld	s0,16(sp)
    800032b6:	6105                	addi	sp,sp,32
    800032b8:	8082                	ret

00000000800032ba <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800032ba:	7179                	addi	sp,sp,-48
    800032bc:	f406                	sd	ra,40(sp)
    800032be:	f022                	sd	s0,32(sp)
    800032c0:	ec26                	sd	s1,24(sp)
    800032c2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800032c4:	fdc40593          	addi	a1,s0,-36
    800032c8:	4501                	li	a0,0
    800032ca:	00000097          	auipc	ra,0x0
    800032ce:	e78080e7          	jalr	-392(ra) # 80003142 <argint>
    800032d2:	87aa                	mv	a5,a0
    return -1;
    800032d4:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800032d6:	0207c063          	bltz	a5,800032f6 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800032da:	fffff097          	auipc	ra,0xfffff
    800032de:	9b2080e7          	jalr	-1614(ra) # 80001c8c <myproc>
    800032e2:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800032e4:	fdc42503          	lw	a0,-36(s0)
    800032e8:	fffff097          	auipc	ra,0xfffff
    800032ec:	e08080e7          	jalr	-504(ra) # 800020f0 <growproc>
    800032f0:	00054863          	bltz	a0,80003300 <sys_sbrk+0x46>
    return -1;
  return addr;
    800032f4:	8526                	mv	a0,s1
}
    800032f6:	70a2                	ld	ra,40(sp)
    800032f8:	7402                	ld	s0,32(sp)
    800032fa:	64e2                	ld	s1,24(sp)
    800032fc:	6145                	addi	sp,sp,48
    800032fe:	8082                	ret
    return -1;
    80003300:	557d                	li	a0,-1
    80003302:	bfd5                	j	800032f6 <sys_sbrk+0x3c>

0000000080003304 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003304:	7139                	addi	sp,sp,-64
    80003306:	fc06                	sd	ra,56(sp)
    80003308:	f822                	sd	s0,48(sp)
    8000330a:	f426                	sd	s1,40(sp)
    8000330c:	f04a                	sd	s2,32(sp)
    8000330e:	ec4e                	sd	s3,24(sp)
    80003310:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003312:	fcc40593          	addi	a1,s0,-52
    80003316:	4501                	li	a0,0
    80003318:	00000097          	auipc	ra,0x0
    8000331c:	e2a080e7          	jalr	-470(ra) # 80003142 <argint>
    return -1;
    80003320:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003322:	06054563          	bltz	a0,8000338c <sys_sleep+0x88>
  acquire(&tickslock);
    80003326:	00014517          	auipc	a0,0x14
    8000332a:	26a50513          	addi	a0,a0,618 # 80017590 <tickslock>
    8000332e:	ffffe097          	auipc	ra,0xffffe
    80003332:	8b6080e7          	jalr	-1866(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003336:	00006917          	auipc	s2,0x6
    8000333a:	cfa92903          	lw	s2,-774(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000333e:	fcc42783          	lw	a5,-52(s0)
    80003342:	cf85                	beqz	a5,8000337a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003344:	00014997          	auipc	s3,0x14
    80003348:	24c98993          	addi	s3,s3,588 # 80017590 <tickslock>
    8000334c:	00006497          	auipc	s1,0x6
    80003350:	ce448493          	addi	s1,s1,-796 # 80009030 <ticks>
    if(myproc()->killed){
    80003354:	fffff097          	auipc	ra,0xfffff
    80003358:	938080e7          	jalr	-1736(ra) # 80001c8c <myproc>
    8000335c:	551c                	lw	a5,40(a0)
    8000335e:	ef9d                	bnez	a5,8000339c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003360:	85ce                	mv	a1,s3
    80003362:	8526                	mv	a0,s1
    80003364:	fffff097          	auipc	ra,0xfffff
    80003368:	076080e7          	jalr	118(ra) # 800023da <sleep>
  while(ticks - ticks0 < n){
    8000336c:	409c                	lw	a5,0(s1)
    8000336e:	412787bb          	subw	a5,a5,s2
    80003372:	fcc42703          	lw	a4,-52(s0)
    80003376:	fce7efe3          	bltu	a5,a4,80003354 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000337a:	00014517          	auipc	a0,0x14
    8000337e:	21650513          	addi	a0,a0,534 # 80017590 <tickslock>
    80003382:	ffffe097          	auipc	ra,0xffffe
    80003386:	916080e7          	jalr	-1770(ra) # 80000c98 <release>
  return 0;
    8000338a:	4781                	li	a5,0
}
    8000338c:	853e                	mv	a0,a5
    8000338e:	70e2                	ld	ra,56(sp)
    80003390:	7442                	ld	s0,48(sp)
    80003392:	74a2                	ld	s1,40(sp)
    80003394:	7902                	ld	s2,32(sp)
    80003396:	69e2                	ld	s3,24(sp)
    80003398:	6121                	addi	sp,sp,64
    8000339a:	8082                	ret
      release(&tickslock);
    8000339c:	00014517          	auipc	a0,0x14
    800033a0:	1f450513          	addi	a0,a0,500 # 80017590 <tickslock>
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	8f4080e7          	jalr	-1804(ra) # 80000c98 <release>
      return -1;
    800033ac:	57fd                	li	a5,-1
    800033ae:	bff9                	j	8000338c <sys_sleep+0x88>

00000000800033b0 <sys_kill>:

uint64
sys_kill(void)
{
    800033b0:	1101                	addi	sp,sp,-32
    800033b2:	ec06                	sd	ra,24(sp)
    800033b4:	e822                	sd	s0,16(sp)
    800033b6:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800033b8:	fec40593          	addi	a1,s0,-20
    800033bc:	4501                	li	a0,0
    800033be:	00000097          	auipc	ra,0x0
    800033c2:	d84080e7          	jalr	-636(ra) # 80003142 <argint>
    800033c6:	87aa                	mv	a5,a0
    return -1;
    800033c8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800033ca:	0007c863          	bltz	a5,800033da <sys_kill+0x2a>
  return kill(pid);
    800033ce:	fec42503          	lw	a0,-20(s0)
    800033d2:	fffff097          	auipc	ra,0xfffff
    800033d6:	1ba080e7          	jalr	442(ra) # 8000258c <kill>
}
    800033da:	60e2                	ld	ra,24(sp)
    800033dc:	6442                	ld	s0,16(sp)
    800033de:	6105                	addi	sp,sp,32
    800033e0:	8082                	ret

00000000800033e2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033e2:	1101                	addi	sp,sp,-32
    800033e4:	ec06                	sd	ra,24(sp)
    800033e6:	e822                	sd	s0,16(sp)
    800033e8:	e426                	sd	s1,8(sp)
    800033ea:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800033ec:	00014517          	auipc	a0,0x14
    800033f0:	1a450513          	addi	a0,a0,420 # 80017590 <tickslock>
    800033f4:	ffffd097          	auipc	ra,0xffffd
    800033f8:	7f0080e7          	jalr	2032(ra) # 80000be4 <acquire>
  xticks = ticks;
    800033fc:	00006497          	auipc	s1,0x6
    80003400:	c344a483          	lw	s1,-972(s1) # 80009030 <ticks>
  release(&tickslock);
    80003404:	00014517          	auipc	a0,0x14
    80003408:	18c50513          	addi	a0,a0,396 # 80017590 <tickslock>
    8000340c:	ffffe097          	auipc	ra,0xffffe
    80003410:	88c080e7          	jalr	-1908(ra) # 80000c98 <release>
  return xticks;
}
    80003414:	02049513          	slli	a0,s1,0x20
    80003418:	9101                	srli	a0,a0,0x20
    8000341a:	60e2                	ld	ra,24(sp)
    8000341c:	6442                	ld	s0,16(sp)
    8000341e:	64a2                	ld	s1,8(sp)
    80003420:	6105                	addi	sp,sp,32
    80003422:	8082                	ret

0000000080003424 <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    80003424:	1101                	addi	sp,sp,-32
    80003426:	ec06                	sd	ra,24(sp)
    80003428:	e822                	sd	s0,16(sp)
    8000342a:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    8000342c:	fec40593          	addi	a1,s0,-20
    80003430:	4501                	li	a0,0
    80003432:	00000097          	auipc	ra,0x0
    80003436:	d10080e7          	jalr	-752(ra) # 80003142 <argint>
    8000343a:	87aa                	mv	a5,a0
    return -1;
    8000343c:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    8000343e:	0007c863          	bltz	a5,8000344e <sys_set_cpu+0x2a>
  return set_cpu(cpu_id);
    80003442:	fec42503          	lw	a0,-20(s0)
    80003446:	fffff097          	auipc	ra,0xfffff
    8000344a:	312080e7          	jalr	786(ra) # 80002758 <set_cpu>
}
    8000344e:	60e2                	ld	ra,24(sp)
    80003450:	6442                	ld	s0,16(sp)
    80003452:	6105                	addi	sp,sp,32
    80003454:	8082                	ret

0000000080003456 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    80003456:	1141                	addi	sp,sp,-16
    80003458:	e406                	sd	ra,8(sp)
    8000345a:	e022                	sd	s0,0(sp)
    8000345c:	0800                	addi	s0,sp,16
  return get_cpu();
    8000345e:	fffff097          	auipc	ra,0xfffff
    80003462:	34c080e7          	jalr	844(ra) # 800027aa <get_cpu>
}
    80003466:	60a2                	ld	ra,8(sp)
    80003468:	6402                	ld	s0,0(sp)
    8000346a:	0141                	addi	sp,sp,16
    8000346c:	8082                	ret

000000008000346e <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void)
{
    8000346e:	1101                	addi	sp,sp,-32
    80003470:	ec06                	sd	ra,24(sp)
    80003472:	e822                	sd	s0,16(sp)
    80003474:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    80003476:	fec40593          	addi	a1,s0,-20
    8000347a:	4501                	li	a0,0
    8000347c:	00000097          	auipc	ra,0x0
    80003480:	cc6080e7          	jalr	-826(ra) # 80003142 <argint>
    80003484:	87aa                	mv	a5,a0
    return -1;
    80003486:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    80003488:	0007c863          	bltz	a5,80003498 <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpu_id);
    8000348c:	fec42503          	lw	a0,-20(s0)
    80003490:	fffff097          	auipc	ra,0xfffff
    80003494:	374080e7          	jalr	884(ra) # 80002804 <cpu_process_count>
}
    80003498:	60e2                	ld	ra,24(sp)
    8000349a:	6442                	ld	s0,16(sp)
    8000349c:	6105                	addi	sp,sp,32
    8000349e:	8082                	ret

00000000800034a0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800034a0:	7179                	addi	sp,sp,-48
    800034a2:	f406                	sd	ra,40(sp)
    800034a4:	f022                	sd	s0,32(sp)
    800034a6:	ec26                	sd	s1,24(sp)
    800034a8:	e84a                	sd	s2,16(sp)
    800034aa:	e44e                	sd	s3,8(sp)
    800034ac:	e052                	sd	s4,0(sp)
    800034ae:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800034b0:	00005597          	auipc	a1,0x5
    800034b4:	27858593          	addi	a1,a1,632 # 80008728 <syscalls+0xc8>
    800034b8:	00014517          	auipc	a0,0x14
    800034bc:	0f050513          	addi	a0,a0,240 # 800175a8 <bcache>
    800034c0:	ffffd097          	auipc	ra,0xffffd
    800034c4:	694080e7          	jalr	1684(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034c8:	0001c797          	auipc	a5,0x1c
    800034cc:	0e078793          	addi	a5,a5,224 # 8001f5a8 <bcache+0x8000>
    800034d0:	0001c717          	auipc	a4,0x1c
    800034d4:	34070713          	addi	a4,a4,832 # 8001f810 <bcache+0x8268>
    800034d8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034dc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034e0:	00014497          	auipc	s1,0x14
    800034e4:	0e048493          	addi	s1,s1,224 # 800175c0 <bcache+0x18>
    b->next = bcache.head.next;
    800034e8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034ea:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034ec:	00005a17          	auipc	s4,0x5
    800034f0:	244a0a13          	addi	s4,s4,580 # 80008730 <syscalls+0xd0>
    b->next = bcache.head.next;
    800034f4:	2b893783          	ld	a5,696(s2)
    800034f8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034fa:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034fe:	85d2                	mv	a1,s4
    80003500:	01048513          	addi	a0,s1,16
    80003504:	00001097          	auipc	ra,0x1
    80003508:	4bc080e7          	jalr	1212(ra) # 800049c0 <initsleeplock>
    bcache.head.next->prev = b;
    8000350c:	2b893783          	ld	a5,696(s2)
    80003510:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003512:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003516:	45848493          	addi	s1,s1,1112
    8000351a:	fd349de3          	bne	s1,s3,800034f4 <binit+0x54>
  }
}
    8000351e:	70a2                	ld	ra,40(sp)
    80003520:	7402                	ld	s0,32(sp)
    80003522:	64e2                	ld	s1,24(sp)
    80003524:	6942                	ld	s2,16(sp)
    80003526:	69a2                	ld	s3,8(sp)
    80003528:	6a02                	ld	s4,0(sp)
    8000352a:	6145                	addi	sp,sp,48
    8000352c:	8082                	ret

000000008000352e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000352e:	7179                	addi	sp,sp,-48
    80003530:	f406                	sd	ra,40(sp)
    80003532:	f022                	sd	s0,32(sp)
    80003534:	ec26                	sd	s1,24(sp)
    80003536:	e84a                	sd	s2,16(sp)
    80003538:	e44e                	sd	s3,8(sp)
    8000353a:	1800                	addi	s0,sp,48
    8000353c:	89aa                	mv	s3,a0
    8000353e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003540:	00014517          	auipc	a0,0x14
    80003544:	06850513          	addi	a0,a0,104 # 800175a8 <bcache>
    80003548:	ffffd097          	auipc	ra,0xffffd
    8000354c:	69c080e7          	jalr	1692(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003550:	0001c497          	auipc	s1,0x1c
    80003554:	3104b483          	ld	s1,784(s1) # 8001f860 <bcache+0x82b8>
    80003558:	0001c797          	auipc	a5,0x1c
    8000355c:	2b878793          	addi	a5,a5,696 # 8001f810 <bcache+0x8268>
    80003560:	02f48f63          	beq	s1,a5,8000359e <bread+0x70>
    80003564:	873e                	mv	a4,a5
    80003566:	a021                	j	8000356e <bread+0x40>
    80003568:	68a4                	ld	s1,80(s1)
    8000356a:	02e48a63          	beq	s1,a4,8000359e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000356e:	449c                	lw	a5,8(s1)
    80003570:	ff379ce3          	bne	a5,s3,80003568 <bread+0x3a>
    80003574:	44dc                	lw	a5,12(s1)
    80003576:	ff2799e3          	bne	a5,s2,80003568 <bread+0x3a>
      b->refcnt++;
    8000357a:	40bc                	lw	a5,64(s1)
    8000357c:	2785                	addiw	a5,a5,1
    8000357e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003580:	00014517          	auipc	a0,0x14
    80003584:	02850513          	addi	a0,a0,40 # 800175a8 <bcache>
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	710080e7          	jalr	1808(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003590:	01048513          	addi	a0,s1,16
    80003594:	00001097          	auipc	ra,0x1
    80003598:	466080e7          	jalr	1126(ra) # 800049fa <acquiresleep>
      return b;
    8000359c:	a8b9                	j	800035fa <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000359e:	0001c497          	auipc	s1,0x1c
    800035a2:	2ba4b483          	ld	s1,698(s1) # 8001f858 <bcache+0x82b0>
    800035a6:	0001c797          	auipc	a5,0x1c
    800035aa:	26a78793          	addi	a5,a5,618 # 8001f810 <bcache+0x8268>
    800035ae:	00f48863          	beq	s1,a5,800035be <bread+0x90>
    800035b2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800035b4:	40bc                	lw	a5,64(s1)
    800035b6:	cf81                	beqz	a5,800035ce <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035b8:	64a4                	ld	s1,72(s1)
    800035ba:	fee49de3          	bne	s1,a4,800035b4 <bread+0x86>
  panic("bget: no buffers");
    800035be:	00005517          	auipc	a0,0x5
    800035c2:	17a50513          	addi	a0,a0,378 # 80008738 <syscalls+0xd8>
    800035c6:	ffffd097          	auipc	ra,0xffffd
    800035ca:	f78080e7          	jalr	-136(ra) # 8000053e <panic>
      b->dev = dev;
    800035ce:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800035d2:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800035d6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035da:	4785                	li	a5,1
    800035dc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035de:	00014517          	auipc	a0,0x14
    800035e2:	fca50513          	addi	a0,a0,-54 # 800175a8 <bcache>
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	6b2080e7          	jalr	1714(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800035ee:	01048513          	addi	a0,s1,16
    800035f2:	00001097          	auipc	ra,0x1
    800035f6:	408080e7          	jalr	1032(ra) # 800049fa <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035fa:	409c                	lw	a5,0(s1)
    800035fc:	cb89                	beqz	a5,8000360e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035fe:	8526                	mv	a0,s1
    80003600:	70a2                	ld	ra,40(sp)
    80003602:	7402                	ld	s0,32(sp)
    80003604:	64e2                	ld	s1,24(sp)
    80003606:	6942                	ld	s2,16(sp)
    80003608:	69a2                	ld	s3,8(sp)
    8000360a:	6145                	addi	sp,sp,48
    8000360c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000360e:	4581                	li	a1,0
    80003610:	8526                	mv	a0,s1
    80003612:	00003097          	auipc	ra,0x3
    80003616:	f14080e7          	jalr	-236(ra) # 80006526 <virtio_disk_rw>
    b->valid = 1;
    8000361a:	4785                	li	a5,1
    8000361c:	c09c                	sw	a5,0(s1)
  return b;
    8000361e:	b7c5                	j	800035fe <bread+0xd0>

0000000080003620 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003620:	1101                	addi	sp,sp,-32
    80003622:	ec06                	sd	ra,24(sp)
    80003624:	e822                	sd	s0,16(sp)
    80003626:	e426                	sd	s1,8(sp)
    80003628:	1000                	addi	s0,sp,32
    8000362a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000362c:	0541                	addi	a0,a0,16
    8000362e:	00001097          	auipc	ra,0x1
    80003632:	466080e7          	jalr	1126(ra) # 80004a94 <holdingsleep>
    80003636:	cd01                	beqz	a0,8000364e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003638:	4585                	li	a1,1
    8000363a:	8526                	mv	a0,s1
    8000363c:	00003097          	auipc	ra,0x3
    80003640:	eea080e7          	jalr	-278(ra) # 80006526 <virtio_disk_rw>
}
    80003644:	60e2                	ld	ra,24(sp)
    80003646:	6442                	ld	s0,16(sp)
    80003648:	64a2                	ld	s1,8(sp)
    8000364a:	6105                	addi	sp,sp,32
    8000364c:	8082                	ret
    panic("bwrite");
    8000364e:	00005517          	auipc	a0,0x5
    80003652:	10250513          	addi	a0,a0,258 # 80008750 <syscalls+0xf0>
    80003656:	ffffd097          	auipc	ra,0xffffd
    8000365a:	ee8080e7          	jalr	-280(ra) # 8000053e <panic>

000000008000365e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000365e:	1101                	addi	sp,sp,-32
    80003660:	ec06                	sd	ra,24(sp)
    80003662:	e822                	sd	s0,16(sp)
    80003664:	e426                	sd	s1,8(sp)
    80003666:	e04a                	sd	s2,0(sp)
    80003668:	1000                	addi	s0,sp,32
    8000366a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000366c:	01050913          	addi	s2,a0,16
    80003670:	854a                	mv	a0,s2
    80003672:	00001097          	auipc	ra,0x1
    80003676:	422080e7          	jalr	1058(ra) # 80004a94 <holdingsleep>
    8000367a:	c92d                	beqz	a0,800036ec <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000367c:	854a                	mv	a0,s2
    8000367e:	00001097          	auipc	ra,0x1
    80003682:	3d2080e7          	jalr	978(ra) # 80004a50 <releasesleep>

  acquire(&bcache.lock);
    80003686:	00014517          	auipc	a0,0x14
    8000368a:	f2250513          	addi	a0,a0,-222 # 800175a8 <bcache>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	556080e7          	jalr	1366(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003696:	40bc                	lw	a5,64(s1)
    80003698:	37fd                	addiw	a5,a5,-1
    8000369a:	0007871b          	sext.w	a4,a5
    8000369e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800036a0:	eb05                	bnez	a4,800036d0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800036a2:	68bc                	ld	a5,80(s1)
    800036a4:	64b8                	ld	a4,72(s1)
    800036a6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800036a8:	64bc                	ld	a5,72(s1)
    800036aa:	68b8                	ld	a4,80(s1)
    800036ac:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800036ae:	0001c797          	auipc	a5,0x1c
    800036b2:	efa78793          	addi	a5,a5,-262 # 8001f5a8 <bcache+0x8000>
    800036b6:	2b87b703          	ld	a4,696(a5)
    800036ba:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800036bc:	0001c717          	auipc	a4,0x1c
    800036c0:	15470713          	addi	a4,a4,340 # 8001f810 <bcache+0x8268>
    800036c4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036c6:	2b87b703          	ld	a4,696(a5)
    800036ca:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036cc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036d0:	00014517          	auipc	a0,0x14
    800036d4:	ed850513          	addi	a0,a0,-296 # 800175a8 <bcache>
    800036d8:	ffffd097          	auipc	ra,0xffffd
    800036dc:	5c0080e7          	jalr	1472(ra) # 80000c98 <release>
}
    800036e0:	60e2                	ld	ra,24(sp)
    800036e2:	6442                	ld	s0,16(sp)
    800036e4:	64a2                	ld	s1,8(sp)
    800036e6:	6902                	ld	s2,0(sp)
    800036e8:	6105                	addi	sp,sp,32
    800036ea:	8082                	ret
    panic("brelse");
    800036ec:	00005517          	auipc	a0,0x5
    800036f0:	06c50513          	addi	a0,a0,108 # 80008758 <syscalls+0xf8>
    800036f4:	ffffd097          	auipc	ra,0xffffd
    800036f8:	e4a080e7          	jalr	-438(ra) # 8000053e <panic>

00000000800036fc <bpin>:

void
bpin(struct buf *b) {
    800036fc:	1101                	addi	sp,sp,-32
    800036fe:	ec06                	sd	ra,24(sp)
    80003700:	e822                	sd	s0,16(sp)
    80003702:	e426                	sd	s1,8(sp)
    80003704:	1000                	addi	s0,sp,32
    80003706:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003708:	00014517          	auipc	a0,0x14
    8000370c:	ea050513          	addi	a0,a0,-352 # 800175a8 <bcache>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	4d4080e7          	jalr	1236(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003718:	40bc                	lw	a5,64(s1)
    8000371a:	2785                	addiw	a5,a5,1
    8000371c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000371e:	00014517          	auipc	a0,0x14
    80003722:	e8a50513          	addi	a0,a0,-374 # 800175a8 <bcache>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	572080e7          	jalr	1394(ra) # 80000c98 <release>
}
    8000372e:	60e2                	ld	ra,24(sp)
    80003730:	6442                	ld	s0,16(sp)
    80003732:	64a2                	ld	s1,8(sp)
    80003734:	6105                	addi	sp,sp,32
    80003736:	8082                	ret

0000000080003738 <bunpin>:

void
bunpin(struct buf *b) {
    80003738:	1101                	addi	sp,sp,-32
    8000373a:	ec06                	sd	ra,24(sp)
    8000373c:	e822                	sd	s0,16(sp)
    8000373e:	e426                	sd	s1,8(sp)
    80003740:	1000                	addi	s0,sp,32
    80003742:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003744:	00014517          	auipc	a0,0x14
    80003748:	e6450513          	addi	a0,a0,-412 # 800175a8 <bcache>
    8000374c:	ffffd097          	auipc	ra,0xffffd
    80003750:	498080e7          	jalr	1176(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003754:	40bc                	lw	a5,64(s1)
    80003756:	37fd                	addiw	a5,a5,-1
    80003758:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000375a:	00014517          	auipc	a0,0x14
    8000375e:	e4e50513          	addi	a0,a0,-434 # 800175a8 <bcache>
    80003762:	ffffd097          	auipc	ra,0xffffd
    80003766:	536080e7          	jalr	1334(ra) # 80000c98 <release>
}
    8000376a:	60e2                	ld	ra,24(sp)
    8000376c:	6442                	ld	s0,16(sp)
    8000376e:	64a2                	ld	s1,8(sp)
    80003770:	6105                	addi	sp,sp,32
    80003772:	8082                	ret

0000000080003774 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003774:	1101                	addi	sp,sp,-32
    80003776:	ec06                	sd	ra,24(sp)
    80003778:	e822                	sd	s0,16(sp)
    8000377a:	e426                	sd	s1,8(sp)
    8000377c:	e04a                	sd	s2,0(sp)
    8000377e:	1000                	addi	s0,sp,32
    80003780:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003782:	00d5d59b          	srliw	a1,a1,0xd
    80003786:	0001c797          	auipc	a5,0x1c
    8000378a:	4fe7a783          	lw	a5,1278(a5) # 8001fc84 <sb+0x1c>
    8000378e:	9dbd                	addw	a1,a1,a5
    80003790:	00000097          	auipc	ra,0x0
    80003794:	d9e080e7          	jalr	-610(ra) # 8000352e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003798:	0074f713          	andi	a4,s1,7
    8000379c:	4785                	li	a5,1
    8000379e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800037a2:	14ce                	slli	s1,s1,0x33
    800037a4:	90d9                	srli	s1,s1,0x36
    800037a6:	00950733          	add	a4,a0,s1
    800037aa:	05874703          	lbu	a4,88(a4)
    800037ae:	00e7f6b3          	and	a3,a5,a4
    800037b2:	c69d                	beqz	a3,800037e0 <bfree+0x6c>
    800037b4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800037b6:	94aa                	add	s1,s1,a0
    800037b8:	fff7c793          	not	a5,a5
    800037bc:	8ff9                	and	a5,a5,a4
    800037be:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800037c2:	00001097          	auipc	ra,0x1
    800037c6:	118080e7          	jalr	280(ra) # 800048da <log_write>
  brelse(bp);
    800037ca:	854a                	mv	a0,s2
    800037cc:	00000097          	auipc	ra,0x0
    800037d0:	e92080e7          	jalr	-366(ra) # 8000365e <brelse>
}
    800037d4:	60e2                	ld	ra,24(sp)
    800037d6:	6442                	ld	s0,16(sp)
    800037d8:	64a2                	ld	s1,8(sp)
    800037da:	6902                	ld	s2,0(sp)
    800037dc:	6105                	addi	sp,sp,32
    800037de:	8082                	ret
    panic("freeing free block");
    800037e0:	00005517          	auipc	a0,0x5
    800037e4:	f8050513          	addi	a0,a0,-128 # 80008760 <syscalls+0x100>
    800037e8:	ffffd097          	auipc	ra,0xffffd
    800037ec:	d56080e7          	jalr	-682(ra) # 8000053e <panic>

00000000800037f0 <balloc>:
{
    800037f0:	711d                	addi	sp,sp,-96
    800037f2:	ec86                	sd	ra,88(sp)
    800037f4:	e8a2                	sd	s0,80(sp)
    800037f6:	e4a6                	sd	s1,72(sp)
    800037f8:	e0ca                	sd	s2,64(sp)
    800037fa:	fc4e                	sd	s3,56(sp)
    800037fc:	f852                	sd	s4,48(sp)
    800037fe:	f456                	sd	s5,40(sp)
    80003800:	f05a                	sd	s6,32(sp)
    80003802:	ec5e                	sd	s7,24(sp)
    80003804:	e862                	sd	s8,16(sp)
    80003806:	e466                	sd	s9,8(sp)
    80003808:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000380a:	0001c797          	auipc	a5,0x1c
    8000380e:	4627a783          	lw	a5,1122(a5) # 8001fc6c <sb+0x4>
    80003812:	cbd1                	beqz	a5,800038a6 <balloc+0xb6>
    80003814:	8baa                	mv	s7,a0
    80003816:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003818:	0001cb17          	auipc	s6,0x1c
    8000381c:	450b0b13          	addi	s6,s6,1104 # 8001fc68 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003820:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003822:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003824:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003826:	6c89                	lui	s9,0x2
    80003828:	a831                	j	80003844 <balloc+0x54>
    brelse(bp);
    8000382a:	854a                	mv	a0,s2
    8000382c:	00000097          	auipc	ra,0x0
    80003830:	e32080e7          	jalr	-462(ra) # 8000365e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003834:	015c87bb          	addw	a5,s9,s5
    80003838:	00078a9b          	sext.w	s5,a5
    8000383c:	004b2703          	lw	a4,4(s6)
    80003840:	06eaf363          	bgeu	s5,a4,800038a6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003844:	41fad79b          	sraiw	a5,s5,0x1f
    80003848:	0137d79b          	srliw	a5,a5,0x13
    8000384c:	015787bb          	addw	a5,a5,s5
    80003850:	40d7d79b          	sraiw	a5,a5,0xd
    80003854:	01cb2583          	lw	a1,28(s6)
    80003858:	9dbd                	addw	a1,a1,a5
    8000385a:	855e                	mv	a0,s7
    8000385c:	00000097          	auipc	ra,0x0
    80003860:	cd2080e7          	jalr	-814(ra) # 8000352e <bread>
    80003864:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003866:	004b2503          	lw	a0,4(s6)
    8000386a:	000a849b          	sext.w	s1,s5
    8000386e:	8662                	mv	a2,s8
    80003870:	faa4fde3          	bgeu	s1,a0,8000382a <balloc+0x3a>
      m = 1 << (bi % 8);
    80003874:	41f6579b          	sraiw	a5,a2,0x1f
    80003878:	01d7d69b          	srliw	a3,a5,0x1d
    8000387c:	00c6873b          	addw	a4,a3,a2
    80003880:	00777793          	andi	a5,a4,7
    80003884:	9f95                	subw	a5,a5,a3
    80003886:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000388a:	4037571b          	sraiw	a4,a4,0x3
    8000388e:	00e906b3          	add	a3,s2,a4
    80003892:	0586c683          	lbu	a3,88(a3)
    80003896:	00d7f5b3          	and	a1,a5,a3
    8000389a:	cd91                	beqz	a1,800038b6 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000389c:	2605                	addiw	a2,a2,1
    8000389e:	2485                	addiw	s1,s1,1
    800038a0:	fd4618e3          	bne	a2,s4,80003870 <balloc+0x80>
    800038a4:	b759                	j	8000382a <balloc+0x3a>
  panic("balloc: out of blocks");
    800038a6:	00005517          	auipc	a0,0x5
    800038aa:	ed250513          	addi	a0,a0,-302 # 80008778 <syscalls+0x118>
    800038ae:	ffffd097          	auipc	ra,0xffffd
    800038b2:	c90080e7          	jalr	-880(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800038b6:	974a                	add	a4,a4,s2
    800038b8:	8fd5                	or	a5,a5,a3
    800038ba:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800038be:	854a                	mv	a0,s2
    800038c0:	00001097          	auipc	ra,0x1
    800038c4:	01a080e7          	jalr	26(ra) # 800048da <log_write>
        brelse(bp);
    800038c8:	854a                	mv	a0,s2
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	d94080e7          	jalr	-620(ra) # 8000365e <brelse>
  bp = bread(dev, bno);
    800038d2:	85a6                	mv	a1,s1
    800038d4:	855e                	mv	a0,s7
    800038d6:	00000097          	auipc	ra,0x0
    800038da:	c58080e7          	jalr	-936(ra) # 8000352e <bread>
    800038de:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038e0:	40000613          	li	a2,1024
    800038e4:	4581                	li	a1,0
    800038e6:	05850513          	addi	a0,a0,88
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	3f6080e7          	jalr	1014(ra) # 80000ce0 <memset>
  log_write(bp);
    800038f2:	854a                	mv	a0,s2
    800038f4:	00001097          	auipc	ra,0x1
    800038f8:	fe6080e7          	jalr	-26(ra) # 800048da <log_write>
  brelse(bp);
    800038fc:	854a                	mv	a0,s2
    800038fe:	00000097          	auipc	ra,0x0
    80003902:	d60080e7          	jalr	-672(ra) # 8000365e <brelse>
}
    80003906:	8526                	mv	a0,s1
    80003908:	60e6                	ld	ra,88(sp)
    8000390a:	6446                	ld	s0,80(sp)
    8000390c:	64a6                	ld	s1,72(sp)
    8000390e:	6906                	ld	s2,64(sp)
    80003910:	79e2                	ld	s3,56(sp)
    80003912:	7a42                	ld	s4,48(sp)
    80003914:	7aa2                	ld	s5,40(sp)
    80003916:	7b02                	ld	s6,32(sp)
    80003918:	6be2                	ld	s7,24(sp)
    8000391a:	6c42                	ld	s8,16(sp)
    8000391c:	6ca2                	ld	s9,8(sp)
    8000391e:	6125                	addi	sp,sp,96
    80003920:	8082                	ret

0000000080003922 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003922:	7179                	addi	sp,sp,-48
    80003924:	f406                	sd	ra,40(sp)
    80003926:	f022                	sd	s0,32(sp)
    80003928:	ec26                	sd	s1,24(sp)
    8000392a:	e84a                	sd	s2,16(sp)
    8000392c:	e44e                	sd	s3,8(sp)
    8000392e:	e052                	sd	s4,0(sp)
    80003930:	1800                	addi	s0,sp,48
    80003932:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003934:	47ad                	li	a5,11
    80003936:	04b7fe63          	bgeu	a5,a1,80003992 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000393a:	ff45849b          	addiw	s1,a1,-12
    8000393e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003942:	0ff00793          	li	a5,255
    80003946:	0ae7e363          	bltu	a5,a4,800039ec <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000394a:	08052583          	lw	a1,128(a0)
    8000394e:	c5ad                	beqz	a1,800039b8 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003950:	00092503          	lw	a0,0(s2)
    80003954:	00000097          	auipc	ra,0x0
    80003958:	bda080e7          	jalr	-1062(ra) # 8000352e <bread>
    8000395c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000395e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003962:	02049593          	slli	a1,s1,0x20
    80003966:	9181                	srli	a1,a1,0x20
    80003968:	058a                	slli	a1,a1,0x2
    8000396a:	00b784b3          	add	s1,a5,a1
    8000396e:	0004a983          	lw	s3,0(s1)
    80003972:	04098d63          	beqz	s3,800039cc <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003976:	8552                	mv	a0,s4
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	ce6080e7          	jalr	-794(ra) # 8000365e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003980:	854e                	mv	a0,s3
    80003982:	70a2                	ld	ra,40(sp)
    80003984:	7402                	ld	s0,32(sp)
    80003986:	64e2                	ld	s1,24(sp)
    80003988:	6942                	ld	s2,16(sp)
    8000398a:	69a2                	ld	s3,8(sp)
    8000398c:	6a02                	ld	s4,0(sp)
    8000398e:	6145                	addi	sp,sp,48
    80003990:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003992:	02059493          	slli	s1,a1,0x20
    80003996:	9081                	srli	s1,s1,0x20
    80003998:	048a                	slli	s1,s1,0x2
    8000399a:	94aa                	add	s1,s1,a0
    8000399c:	0504a983          	lw	s3,80(s1)
    800039a0:	fe0990e3          	bnez	s3,80003980 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800039a4:	4108                	lw	a0,0(a0)
    800039a6:	00000097          	auipc	ra,0x0
    800039aa:	e4a080e7          	jalr	-438(ra) # 800037f0 <balloc>
    800039ae:	0005099b          	sext.w	s3,a0
    800039b2:	0534a823          	sw	s3,80(s1)
    800039b6:	b7e9                	j	80003980 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800039b8:	4108                	lw	a0,0(a0)
    800039ba:	00000097          	auipc	ra,0x0
    800039be:	e36080e7          	jalr	-458(ra) # 800037f0 <balloc>
    800039c2:	0005059b          	sext.w	a1,a0
    800039c6:	08b92023          	sw	a1,128(s2)
    800039ca:	b759                	j	80003950 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800039cc:	00092503          	lw	a0,0(s2)
    800039d0:	00000097          	auipc	ra,0x0
    800039d4:	e20080e7          	jalr	-480(ra) # 800037f0 <balloc>
    800039d8:	0005099b          	sext.w	s3,a0
    800039dc:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800039e0:	8552                	mv	a0,s4
    800039e2:	00001097          	auipc	ra,0x1
    800039e6:	ef8080e7          	jalr	-264(ra) # 800048da <log_write>
    800039ea:	b771                	j	80003976 <bmap+0x54>
  panic("bmap: out of range");
    800039ec:	00005517          	auipc	a0,0x5
    800039f0:	da450513          	addi	a0,a0,-604 # 80008790 <syscalls+0x130>
    800039f4:	ffffd097          	auipc	ra,0xffffd
    800039f8:	b4a080e7          	jalr	-1206(ra) # 8000053e <panic>

00000000800039fc <iget>:
{
    800039fc:	7179                	addi	sp,sp,-48
    800039fe:	f406                	sd	ra,40(sp)
    80003a00:	f022                	sd	s0,32(sp)
    80003a02:	ec26                	sd	s1,24(sp)
    80003a04:	e84a                	sd	s2,16(sp)
    80003a06:	e44e                	sd	s3,8(sp)
    80003a08:	e052                	sd	s4,0(sp)
    80003a0a:	1800                	addi	s0,sp,48
    80003a0c:	89aa                	mv	s3,a0
    80003a0e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a10:	0001c517          	auipc	a0,0x1c
    80003a14:	27850513          	addi	a0,a0,632 # 8001fc88 <itable>
    80003a18:	ffffd097          	auipc	ra,0xffffd
    80003a1c:	1cc080e7          	jalr	460(ra) # 80000be4 <acquire>
  empty = 0;
    80003a20:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a22:	0001c497          	auipc	s1,0x1c
    80003a26:	27e48493          	addi	s1,s1,638 # 8001fca0 <itable+0x18>
    80003a2a:	0001e697          	auipc	a3,0x1e
    80003a2e:	d0668693          	addi	a3,a3,-762 # 80021730 <log>
    80003a32:	a039                	j	80003a40 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a34:	02090b63          	beqz	s2,80003a6a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a38:	08848493          	addi	s1,s1,136
    80003a3c:	02d48a63          	beq	s1,a3,80003a70 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a40:	449c                	lw	a5,8(s1)
    80003a42:	fef059e3          	blez	a5,80003a34 <iget+0x38>
    80003a46:	4098                	lw	a4,0(s1)
    80003a48:	ff3716e3          	bne	a4,s3,80003a34 <iget+0x38>
    80003a4c:	40d8                	lw	a4,4(s1)
    80003a4e:	ff4713e3          	bne	a4,s4,80003a34 <iget+0x38>
      ip->ref++;
    80003a52:	2785                	addiw	a5,a5,1
    80003a54:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a56:	0001c517          	auipc	a0,0x1c
    80003a5a:	23250513          	addi	a0,a0,562 # 8001fc88 <itable>
    80003a5e:	ffffd097          	auipc	ra,0xffffd
    80003a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
      return ip;
    80003a66:	8926                	mv	s2,s1
    80003a68:	a03d                	j	80003a96 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a6a:	f7f9                	bnez	a5,80003a38 <iget+0x3c>
    80003a6c:	8926                	mv	s2,s1
    80003a6e:	b7e9                	j	80003a38 <iget+0x3c>
  if(empty == 0)
    80003a70:	02090c63          	beqz	s2,80003aa8 <iget+0xac>
  ip->dev = dev;
    80003a74:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a78:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a7c:	4785                	li	a5,1
    80003a7e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a82:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a86:	0001c517          	auipc	a0,0x1c
    80003a8a:	20250513          	addi	a0,a0,514 # 8001fc88 <itable>
    80003a8e:	ffffd097          	auipc	ra,0xffffd
    80003a92:	20a080e7          	jalr	522(ra) # 80000c98 <release>
}
    80003a96:	854a                	mv	a0,s2
    80003a98:	70a2                	ld	ra,40(sp)
    80003a9a:	7402                	ld	s0,32(sp)
    80003a9c:	64e2                	ld	s1,24(sp)
    80003a9e:	6942                	ld	s2,16(sp)
    80003aa0:	69a2                	ld	s3,8(sp)
    80003aa2:	6a02                	ld	s4,0(sp)
    80003aa4:	6145                	addi	sp,sp,48
    80003aa6:	8082                	ret
    panic("iget: no inodes");
    80003aa8:	00005517          	auipc	a0,0x5
    80003aac:	d0050513          	addi	a0,a0,-768 # 800087a8 <syscalls+0x148>
    80003ab0:	ffffd097          	auipc	ra,0xffffd
    80003ab4:	a8e080e7          	jalr	-1394(ra) # 8000053e <panic>

0000000080003ab8 <fsinit>:
fsinit(int dev) {
    80003ab8:	7179                	addi	sp,sp,-48
    80003aba:	f406                	sd	ra,40(sp)
    80003abc:	f022                	sd	s0,32(sp)
    80003abe:	ec26                	sd	s1,24(sp)
    80003ac0:	e84a                	sd	s2,16(sp)
    80003ac2:	e44e                	sd	s3,8(sp)
    80003ac4:	1800                	addi	s0,sp,48
    80003ac6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003ac8:	4585                	li	a1,1
    80003aca:	00000097          	auipc	ra,0x0
    80003ace:	a64080e7          	jalr	-1436(ra) # 8000352e <bread>
    80003ad2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ad4:	0001c997          	auipc	s3,0x1c
    80003ad8:	19498993          	addi	s3,s3,404 # 8001fc68 <sb>
    80003adc:	02000613          	li	a2,32
    80003ae0:	05850593          	addi	a1,a0,88
    80003ae4:	854e                	mv	a0,s3
    80003ae6:	ffffd097          	auipc	ra,0xffffd
    80003aea:	25a080e7          	jalr	602(ra) # 80000d40 <memmove>
  brelse(bp);
    80003aee:	8526                	mv	a0,s1
    80003af0:	00000097          	auipc	ra,0x0
    80003af4:	b6e080e7          	jalr	-1170(ra) # 8000365e <brelse>
  if(sb.magic != FSMAGIC)
    80003af8:	0009a703          	lw	a4,0(s3)
    80003afc:	102037b7          	lui	a5,0x10203
    80003b00:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b04:	02f71263          	bne	a4,a5,80003b28 <fsinit+0x70>
  initlog(dev, &sb);
    80003b08:	0001c597          	auipc	a1,0x1c
    80003b0c:	16058593          	addi	a1,a1,352 # 8001fc68 <sb>
    80003b10:	854a                	mv	a0,s2
    80003b12:	00001097          	auipc	ra,0x1
    80003b16:	b4c080e7          	jalr	-1204(ra) # 8000465e <initlog>
}
    80003b1a:	70a2                	ld	ra,40(sp)
    80003b1c:	7402                	ld	s0,32(sp)
    80003b1e:	64e2                	ld	s1,24(sp)
    80003b20:	6942                	ld	s2,16(sp)
    80003b22:	69a2                	ld	s3,8(sp)
    80003b24:	6145                	addi	sp,sp,48
    80003b26:	8082                	ret
    panic("invalid file system");
    80003b28:	00005517          	auipc	a0,0x5
    80003b2c:	c9050513          	addi	a0,a0,-880 # 800087b8 <syscalls+0x158>
    80003b30:	ffffd097          	auipc	ra,0xffffd
    80003b34:	a0e080e7          	jalr	-1522(ra) # 8000053e <panic>

0000000080003b38 <iinit>:
{
    80003b38:	7179                	addi	sp,sp,-48
    80003b3a:	f406                	sd	ra,40(sp)
    80003b3c:	f022                	sd	s0,32(sp)
    80003b3e:	ec26                	sd	s1,24(sp)
    80003b40:	e84a                	sd	s2,16(sp)
    80003b42:	e44e                	sd	s3,8(sp)
    80003b44:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b46:	00005597          	auipc	a1,0x5
    80003b4a:	c8a58593          	addi	a1,a1,-886 # 800087d0 <syscalls+0x170>
    80003b4e:	0001c517          	auipc	a0,0x1c
    80003b52:	13a50513          	addi	a0,a0,314 # 8001fc88 <itable>
    80003b56:	ffffd097          	auipc	ra,0xffffd
    80003b5a:	ffe080e7          	jalr	-2(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b5e:	0001c497          	auipc	s1,0x1c
    80003b62:	15248493          	addi	s1,s1,338 # 8001fcb0 <itable+0x28>
    80003b66:	0001e997          	auipc	s3,0x1e
    80003b6a:	bda98993          	addi	s3,s3,-1062 # 80021740 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b6e:	00005917          	auipc	s2,0x5
    80003b72:	c6a90913          	addi	s2,s2,-918 # 800087d8 <syscalls+0x178>
    80003b76:	85ca                	mv	a1,s2
    80003b78:	8526                	mv	a0,s1
    80003b7a:	00001097          	auipc	ra,0x1
    80003b7e:	e46080e7          	jalr	-442(ra) # 800049c0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b82:	08848493          	addi	s1,s1,136
    80003b86:	ff3498e3          	bne	s1,s3,80003b76 <iinit+0x3e>
}
    80003b8a:	70a2                	ld	ra,40(sp)
    80003b8c:	7402                	ld	s0,32(sp)
    80003b8e:	64e2                	ld	s1,24(sp)
    80003b90:	6942                	ld	s2,16(sp)
    80003b92:	69a2                	ld	s3,8(sp)
    80003b94:	6145                	addi	sp,sp,48
    80003b96:	8082                	ret

0000000080003b98 <ialloc>:
{
    80003b98:	715d                	addi	sp,sp,-80
    80003b9a:	e486                	sd	ra,72(sp)
    80003b9c:	e0a2                	sd	s0,64(sp)
    80003b9e:	fc26                	sd	s1,56(sp)
    80003ba0:	f84a                	sd	s2,48(sp)
    80003ba2:	f44e                	sd	s3,40(sp)
    80003ba4:	f052                	sd	s4,32(sp)
    80003ba6:	ec56                	sd	s5,24(sp)
    80003ba8:	e85a                	sd	s6,16(sp)
    80003baa:	e45e                	sd	s7,8(sp)
    80003bac:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bae:	0001c717          	auipc	a4,0x1c
    80003bb2:	0c672703          	lw	a4,198(a4) # 8001fc74 <sb+0xc>
    80003bb6:	4785                	li	a5,1
    80003bb8:	04e7fa63          	bgeu	a5,a4,80003c0c <ialloc+0x74>
    80003bbc:	8aaa                	mv	s5,a0
    80003bbe:	8bae                	mv	s7,a1
    80003bc0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003bc2:	0001ca17          	auipc	s4,0x1c
    80003bc6:	0a6a0a13          	addi	s4,s4,166 # 8001fc68 <sb>
    80003bca:	00048b1b          	sext.w	s6,s1
    80003bce:	0044d593          	srli	a1,s1,0x4
    80003bd2:	018a2783          	lw	a5,24(s4)
    80003bd6:	9dbd                	addw	a1,a1,a5
    80003bd8:	8556                	mv	a0,s5
    80003bda:	00000097          	auipc	ra,0x0
    80003bde:	954080e7          	jalr	-1708(ra) # 8000352e <bread>
    80003be2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003be4:	05850993          	addi	s3,a0,88
    80003be8:	00f4f793          	andi	a5,s1,15
    80003bec:	079a                	slli	a5,a5,0x6
    80003bee:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003bf0:	00099783          	lh	a5,0(s3)
    80003bf4:	c785                	beqz	a5,80003c1c <ialloc+0x84>
    brelse(bp);
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	a68080e7          	jalr	-1432(ra) # 8000365e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bfe:	0485                	addi	s1,s1,1
    80003c00:	00ca2703          	lw	a4,12(s4)
    80003c04:	0004879b          	sext.w	a5,s1
    80003c08:	fce7e1e3          	bltu	a5,a4,80003bca <ialloc+0x32>
  panic("ialloc: no inodes");
    80003c0c:	00005517          	auipc	a0,0x5
    80003c10:	bd450513          	addi	a0,a0,-1068 # 800087e0 <syscalls+0x180>
    80003c14:	ffffd097          	auipc	ra,0xffffd
    80003c18:	92a080e7          	jalr	-1750(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003c1c:	04000613          	li	a2,64
    80003c20:	4581                	li	a1,0
    80003c22:	854e                	mv	a0,s3
    80003c24:	ffffd097          	auipc	ra,0xffffd
    80003c28:	0bc080e7          	jalr	188(ra) # 80000ce0 <memset>
      dip->type = type;
    80003c2c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c30:	854a                	mv	a0,s2
    80003c32:	00001097          	auipc	ra,0x1
    80003c36:	ca8080e7          	jalr	-856(ra) # 800048da <log_write>
      brelse(bp);
    80003c3a:	854a                	mv	a0,s2
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	a22080e7          	jalr	-1502(ra) # 8000365e <brelse>
      return iget(dev, inum);
    80003c44:	85da                	mv	a1,s6
    80003c46:	8556                	mv	a0,s5
    80003c48:	00000097          	auipc	ra,0x0
    80003c4c:	db4080e7          	jalr	-588(ra) # 800039fc <iget>
}
    80003c50:	60a6                	ld	ra,72(sp)
    80003c52:	6406                	ld	s0,64(sp)
    80003c54:	74e2                	ld	s1,56(sp)
    80003c56:	7942                	ld	s2,48(sp)
    80003c58:	79a2                	ld	s3,40(sp)
    80003c5a:	7a02                	ld	s4,32(sp)
    80003c5c:	6ae2                	ld	s5,24(sp)
    80003c5e:	6b42                	ld	s6,16(sp)
    80003c60:	6ba2                	ld	s7,8(sp)
    80003c62:	6161                	addi	sp,sp,80
    80003c64:	8082                	ret

0000000080003c66 <iupdate>:
{
    80003c66:	1101                	addi	sp,sp,-32
    80003c68:	ec06                	sd	ra,24(sp)
    80003c6a:	e822                	sd	s0,16(sp)
    80003c6c:	e426                	sd	s1,8(sp)
    80003c6e:	e04a                	sd	s2,0(sp)
    80003c70:	1000                	addi	s0,sp,32
    80003c72:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c74:	415c                	lw	a5,4(a0)
    80003c76:	0047d79b          	srliw	a5,a5,0x4
    80003c7a:	0001c597          	auipc	a1,0x1c
    80003c7e:	0065a583          	lw	a1,6(a1) # 8001fc80 <sb+0x18>
    80003c82:	9dbd                	addw	a1,a1,a5
    80003c84:	4108                	lw	a0,0(a0)
    80003c86:	00000097          	auipc	ra,0x0
    80003c8a:	8a8080e7          	jalr	-1880(ra) # 8000352e <bread>
    80003c8e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c90:	05850793          	addi	a5,a0,88
    80003c94:	40c8                	lw	a0,4(s1)
    80003c96:	893d                	andi	a0,a0,15
    80003c98:	051a                	slli	a0,a0,0x6
    80003c9a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c9c:	04449703          	lh	a4,68(s1)
    80003ca0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003ca4:	04649703          	lh	a4,70(s1)
    80003ca8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003cac:	04849703          	lh	a4,72(s1)
    80003cb0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003cb4:	04a49703          	lh	a4,74(s1)
    80003cb8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003cbc:	44f8                	lw	a4,76(s1)
    80003cbe:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003cc0:	03400613          	li	a2,52
    80003cc4:	05048593          	addi	a1,s1,80
    80003cc8:	0531                	addi	a0,a0,12
    80003cca:	ffffd097          	auipc	ra,0xffffd
    80003cce:	076080e7          	jalr	118(ra) # 80000d40 <memmove>
  log_write(bp);
    80003cd2:	854a                	mv	a0,s2
    80003cd4:	00001097          	auipc	ra,0x1
    80003cd8:	c06080e7          	jalr	-1018(ra) # 800048da <log_write>
  brelse(bp);
    80003cdc:	854a                	mv	a0,s2
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	980080e7          	jalr	-1664(ra) # 8000365e <brelse>
}
    80003ce6:	60e2                	ld	ra,24(sp)
    80003ce8:	6442                	ld	s0,16(sp)
    80003cea:	64a2                	ld	s1,8(sp)
    80003cec:	6902                	ld	s2,0(sp)
    80003cee:	6105                	addi	sp,sp,32
    80003cf0:	8082                	ret

0000000080003cf2 <idup>:
{
    80003cf2:	1101                	addi	sp,sp,-32
    80003cf4:	ec06                	sd	ra,24(sp)
    80003cf6:	e822                	sd	s0,16(sp)
    80003cf8:	e426                	sd	s1,8(sp)
    80003cfa:	1000                	addi	s0,sp,32
    80003cfc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cfe:	0001c517          	auipc	a0,0x1c
    80003d02:	f8a50513          	addi	a0,a0,-118 # 8001fc88 <itable>
    80003d06:	ffffd097          	auipc	ra,0xffffd
    80003d0a:	ede080e7          	jalr	-290(ra) # 80000be4 <acquire>
  ip->ref++;
    80003d0e:	449c                	lw	a5,8(s1)
    80003d10:	2785                	addiw	a5,a5,1
    80003d12:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d14:	0001c517          	auipc	a0,0x1c
    80003d18:	f7450513          	addi	a0,a0,-140 # 8001fc88 <itable>
    80003d1c:	ffffd097          	auipc	ra,0xffffd
    80003d20:	f7c080e7          	jalr	-132(ra) # 80000c98 <release>
}
    80003d24:	8526                	mv	a0,s1
    80003d26:	60e2                	ld	ra,24(sp)
    80003d28:	6442                	ld	s0,16(sp)
    80003d2a:	64a2                	ld	s1,8(sp)
    80003d2c:	6105                	addi	sp,sp,32
    80003d2e:	8082                	ret

0000000080003d30 <ilock>:
{
    80003d30:	1101                	addi	sp,sp,-32
    80003d32:	ec06                	sd	ra,24(sp)
    80003d34:	e822                	sd	s0,16(sp)
    80003d36:	e426                	sd	s1,8(sp)
    80003d38:	e04a                	sd	s2,0(sp)
    80003d3a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d3c:	c115                	beqz	a0,80003d60 <ilock+0x30>
    80003d3e:	84aa                	mv	s1,a0
    80003d40:	451c                	lw	a5,8(a0)
    80003d42:	00f05f63          	blez	a5,80003d60 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d46:	0541                	addi	a0,a0,16
    80003d48:	00001097          	auipc	ra,0x1
    80003d4c:	cb2080e7          	jalr	-846(ra) # 800049fa <acquiresleep>
  if(ip->valid == 0){
    80003d50:	40bc                	lw	a5,64(s1)
    80003d52:	cf99                	beqz	a5,80003d70 <ilock+0x40>
}
    80003d54:	60e2                	ld	ra,24(sp)
    80003d56:	6442                	ld	s0,16(sp)
    80003d58:	64a2                	ld	s1,8(sp)
    80003d5a:	6902                	ld	s2,0(sp)
    80003d5c:	6105                	addi	sp,sp,32
    80003d5e:	8082                	ret
    panic("ilock");
    80003d60:	00005517          	auipc	a0,0x5
    80003d64:	a9850513          	addi	a0,a0,-1384 # 800087f8 <syscalls+0x198>
    80003d68:	ffffc097          	auipc	ra,0xffffc
    80003d6c:	7d6080e7          	jalr	2006(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d70:	40dc                	lw	a5,4(s1)
    80003d72:	0047d79b          	srliw	a5,a5,0x4
    80003d76:	0001c597          	auipc	a1,0x1c
    80003d7a:	f0a5a583          	lw	a1,-246(a1) # 8001fc80 <sb+0x18>
    80003d7e:	9dbd                	addw	a1,a1,a5
    80003d80:	4088                	lw	a0,0(s1)
    80003d82:	fffff097          	auipc	ra,0xfffff
    80003d86:	7ac080e7          	jalr	1964(ra) # 8000352e <bread>
    80003d8a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d8c:	05850593          	addi	a1,a0,88
    80003d90:	40dc                	lw	a5,4(s1)
    80003d92:	8bbd                	andi	a5,a5,15
    80003d94:	079a                	slli	a5,a5,0x6
    80003d96:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d98:	00059783          	lh	a5,0(a1)
    80003d9c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003da0:	00259783          	lh	a5,2(a1)
    80003da4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003da8:	00459783          	lh	a5,4(a1)
    80003dac:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003db0:	00659783          	lh	a5,6(a1)
    80003db4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003db8:	459c                	lw	a5,8(a1)
    80003dba:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003dbc:	03400613          	li	a2,52
    80003dc0:	05b1                	addi	a1,a1,12
    80003dc2:	05048513          	addi	a0,s1,80
    80003dc6:	ffffd097          	auipc	ra,0xffffd
    80003dca:	f7a080e7          	jalr	-134(ra) # 80000d40 <memmove>
    brelse(bp);
    80003dce:	854a                	mv	a0,s2
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	88e080e7          	jalr	-1906(ra) # 8000365e <brelse>
    ip->valid = 1;
    80003dd8:	4785                	li	a5,1
    80003dda:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ddc:	04449783          	lh	a5,68(s1)
    80003de0:	fbb5                	bnez	a5,80003d54 <ilock+0x24>
      panic("ilock: no type");
    80003de2:	00005517          	auipc	a0,0x5
    80003de6:	a1e50513          	addi	a0,a0,-1506 # 80008800 <syscalls+0x1a0>
    80003dea:	ffffc097          	auipc	ra,0xffffc
    80003dee:	754080e7          	jalr	1876(ra) # 8000053e <panic>

0000000080003df2 <iunlock>:
{
    80003df2:	1101                	addi	sp,sp,-32
    80003df4:	ec06                	sd	ra,24(sp)
    80003df6:	e822                	sd	s0,16(sp)
    80003df8:	e426                	sd	s1,8(sp)
    80003dfa:	e04a                	sd	s2,0(sp)
    80003dfc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003dfe:	c905                	beqz	a0,80003e2e <iunlock+0x3c>
    80003e00:	84aa                	mv	s1,a0
    80003e02:	01050913          	addi	s2,a0,16
    80003e06:	854a                	mv	a0,s2
    80003e08:	00001097          	auipc	ra,0x1
    80003e0c:	c8c080e7          	jalr	-884(ra) # 80004a94 <holdingsleep>
    80003e10:	cd19                	beqz	a0,80003e2e <iunlock+0x3c>
    80003e12:	449c                	lw	a5,8(s1)
    80003e14:	00f05d63          	blez	a5,80003e2e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e18:	854a                	mv	a0,s2
    80003e1a:	00001097          	auipc	ra,0x1
    80003e1e:	c36080e7          	jalr	-970(ra) # 80004a50 <releasesleep>
}
    80003e22:	60e2                	ld	ra,24(sp)
    80003e24:	6442                	ld	s0,16(sp)
    80003e26:	64a2                	ld	s1,8(sp)
    80003e28:	6902                	ld	s2,0(sp)
    80003e2a:	6105                	addi	sp,sp,32
    80003e2c:	8082                	ret
    panic("iunlock");
    80003e2e:	00005517          	auipc	a0,0x5
    80003e32:	9e250513          	addi	a0,a0,-1566 # 80008810 <syscalls+0x1b0>
    80003e36:	ffffc097          	auipc	ra,0xffffc
    80003e3a:	708080e7          	jalr	1800(ra) # 8000053e <panic>

0000000080003e3e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e3e:	7179                	addi	sp,sp,-48
    80003e40:	f406                	sd	ra,40(sp)
    80003e42:	f022                	sd	s0,32(sp)
    80003e44:	ec26                	sd	s1,24(sp)
    80003e46:	e84a                	sd	s2,16(sp)
    80003e48:	e44e                	sd	s3,8(sp)
    80003e4a:	e052                	sd	s4,0(sp)
    80003e4c:	1800                	addi	s0,sp,48
    80003e4e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e50:	05050493          	addi	s1,a0,80
    80003e54:	08050913          	addi	s2,a0,128
    80003e58:	a021                	j	80003e60 <itrunc+0x22>
    80003e5a:	0491                	addi	s1,s1,4
    80003e5c:	01248d63          	beq	s1,s2,80003e76 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e60:	408c                	lw	a1,0(s1)
    80003e62:	dde5                	beqz	a1,80003e5a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e64:	0009a503          	lw	a0,0(s3)
    80003e68:	00000097          	auipc	ra,0x0
    80003e6c:	90c080e7          	jalr	-1780(ra) # 80003774 <bfree>
      ip->addrs[i] = 0;
    80003e70:	0004a023          	sw	zero,0(s1)
    80003e74:	b7dd                	j	80003e5a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e76:	0809a583          	lw	a1,128(s3)
    80003e7a:	e185                	bnez	a1,80003e9a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e7c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e80:	854e                	mv	a0,s3
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	de4080e7          	jalr	-540(ra) # 80003c66 <iupdate>
}
    80003e8a:	70a2                	ld	ra,40(sp)
    80003e8c:	7402                	ld	s0,32(sp)
    80003e8e:	64e2                	ld	s1,24(sp)
    80003e90:	6942                	ld	s2,16(sp)
    80003e92:	69a2                	ld	s3,8(sp)
    80003e94:	6a02                	ld	s4,0(sp)
    80003e96:	6145                	addi	sp,sp,48
    80003e98:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e9a:	0009a503          	lw	a0,0(s3)
    80003e9e:	fffff097          	auipc	ra,0xfffff
    80003ea2:	690080e7          	jalr	1680(ra) # 8000352e <bread>
    80003ea6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ea8:	05850493          	addi	s1,a0,88
    80003eac:	45850913          	addi	s2,a0,1112
    80003eb0:	a811                	j	80003ec4 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003eb2:	0009a503          	lw	a0,0(s3)
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	8be080e7          	jalr	-1858(ra) # 80003774 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003ebe:	0491                	addi	s1,s1,4
    80003ec0:	01248563          	beq	s1,s2,80003eca <itrunc+0x8c>
      if(a[j])
    80003ec4:	408c                	lw	a1,0(s1)
    80003ec6:	dde5                	beqz	a1,80003ebe <itrunc+0x80>
    80003ec8:	b7ed                	j	80003eb2 <itrunc+0x74>
    brelse(bp);
    80003eca:	8552                	mv	a0,s4
    80003ecc:	fffff097          	auipc	ra,0xfffff
    80003ed0:	792080e7          	jalr	1938(ra) # 8000365e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ed4:	0809a583          	lw	a1,128(s3)
    80003ed8:	0009a503          	lw	a0,0(s3)
    80003edc:	00000097          	auipc	ra,0x0
    80003ee0:	898080e7          	jalr	-1896(ra) # 80003774 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ee4:	0809a023          	sw	zero,128(s3)
    80003ee8:	bf51                	j	80003e7c <itrunc+0x3e>

0000000080003eea <iput>:
{
    80003eea:	1101                	addi	sp,sp,-32
    80003eec:	ec06                	sd	ra,24(sp)
    80003eee:	e822                	sd	s0,16(sp)
    80003ef0:	e426                	sd	s1,8(sp)
    80003ef2:	e04a                	sd	s2,0(sp)
    80003ef4:	1000                	addi	s0,sp,32
    80003ef6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ef8:	0001c517          	auipc	a0,0x1c
    80003efc:	d9050513          	addi	a0,a0,-624 # 8001fc88 <itable>
    80003f00:	ffffd097          	auipc	ra,0xffffd
    80003f04:	ce4080e7          	jalr	-796(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f08:	4498                	lw	a4,8(s1)
    80003f0a:	4785                	li	a5,1
    80003f0c:	02f70363          	beq	a4,a5,80003f32 <iput+0x48>
  ip->ref--;
    80003f10:	449c                	lw	a5,8(s1)
    80003f12:	37fd                	addiw	a5,a5,-1
    80003f14:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f16:	0001c517          	auipc	a0,0x1c
    80003f1a:	d7250513          	addi	a0,a0,-654 # 8001fc88 <itable>
    80003f1e:	ffffd097          	auipc	ra,0xffffd
    80003f22:	d7a080e7          	jalr	-646(ra) # 80000c98 <release>
}
    80003f26:	60e2                	ld	ra,24(sp)
    80003f28:	6442                	ld	s0,16(sp)
    80003f2a:	64a2                	ld	s1,8(sp)
    80003f2c:	6902                	ld	s2,0(sp)
    80003f2e:	6105                	addi	sp,sp,32
    80003f30:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f32:	40bc                	lw	a5,64(s1)
    80003f34:	dff1                	beqz	a5,80003f10 <iput+0x26>
    80003f36:	04a49783          	lh	a5,74(s1)
    80003f3a:	fbf9                	bnez	a5,80003f10 <iput+0x26>
    acquiresleep(&ip->lock);
    80003f3c:	01048913          	addi	s2,s1,16
    80003f40:	854a                	mv	a0,s2
    80003f42:	00001097          	auipc	ra,0x1
    80003f46:	ab8080e7          	jalr	-1352(ra) # 800049fa <acquiresleep>
    release(&itable.lock);
    80003f4a:	0001c517          	auipc	a0,0x1c
    80003f4e:	d3e50513          	addi	a0,a0,-706 # 8001fc88 <itable>
    80003f52:	ffffd097          	auipc	ra,0xffffd
    80003f56:	d46080e7          	jalr	-698(ra) # 80000c98 <release>
    itrunc(ip);
    80003f5a:	8526                	mv	a0,s1
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	ee2080e7          	jalr	-286(ra) # 80003e3e <itrunc>
    ip->type = 0;
    80003f64:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f68:	8526                	mv	a0,s1
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	cfc080e7          	jalr	-772(ra) # 80003c66 <iupdate>
    ip->valid = 0;
    80003f72:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f76:	854a                	mv	a0,s2
    80003f78:	00001097          	auipc	ra,0x1
    80003f7c:	ad8080e7          	jalr	-1320(ra) # 80004a50 <releasesleep>
    acquire(&itable.lock);
    80003f80:	0001c517          	auipc	a0,0x1c
    80003f84:	d0850513          	addi	a0,a0,-760 # 8001fc88 <itable>
    80003f88:	ffffd097          	auipc	ra,0xffffd
    80003f8c:	c5c080e7          	jalr	-932(ra) # 80000be4 <acquire>
    80003f90:	b741                	j	80003f10 <iput+0x26>

0000000080003f92 <iunlockput>:
{
    80003f92:	1101                	addi	sp,sp,-32
    80003f94:	ec06                	sd	ra,24(sp)
    80003f96:	e822                	sd	s0,16(sp)
    80003f98:	e426                	sd	s1,8(sp)
    80003f9a:	1000                	addi	s0,sp,32
    80003f9c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f9e:	00000097          	auipc	ra,0x0
    80003fa2:	e54080e7          	jalr	-428(ra) # 80003df2 <iunlock>
  iput(ip);
    80003fa6:	8526                	mv	a0,s1
    80003fa8:	00000097          	auipc	ra,0x0
    80003fac:	f42080e7          	jalr	-190(ra) # 80003eea <iput>
}
    80003fb0:	60e2                	ld	ra,24(sp)
    80003fb2:	6442                	ld	s0,16(sp)
    80003fb4:	64a2                	ld	s1,8(sp)
    80003fb6:	6105                	addi	sp,sp,32
    80003fb8:	8082                	ret

0000000080003fba <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003fba:	1141                	addi	sp,sp,-16
    80003fbc:	e422                	sd	s0,8(sp)
    80003fbe:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003fc0:	411c                	lw	a5,0(a0)
    80003fc2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003fc4:	415c                	lw	a5,4(a0)
    80003fc6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fc8:	04451783          	lh	a5,68(a0)
    80003fcc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003fd0:	04a51783          	lh	a5,74(a0)
    80003fd4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fd8:	04c56783          	lwu	a5,76(a0)
    80003fdc:	e99c                	sd	a5,16(a1)
}
    80003fde:	6422                	ld	s0,8(sp)
    80003fe0:	0141                	addi	sp,sp,16
    80003fe2:	8082                	ret

0000000080003fe4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fe4:	457c                	lw	a5,76(a0)
    80003fe6:	0ed7e963          	bltu	a5,a3,800040d8 <readi+0xf4>
{
    80003fea:	7159                	addi	sp,sp,-112
    80003fec:	f486                	sd	ra,104(sp)
    80003fee:	f0a2                	sd	s0,96(sp)
    80003ff0:	eca6                	sd	s1,88(sp)
    80003ff2:	e8ca                	sd	s2,80(sp)
    80003ff4:	e4ce                	sd	s3,72(sp)
    80003ff6:	e0d2                	sd	s4,64(sp)
    80003ff8:	fc56                	sd	s5,56(sp)
    80003ffa:	f85a                	sd	s6,48(sp)
    80003ffc:	f45e                	sd	s7,40(sp)
    80003ffe:	f062                	sd	s8,32(sp)
    80004000:	ec66                	sd	s9,24(sp)
    80004002:	e86a                	sd	s10,16(sp)
    80004004:	e46e                	sd	s11,8(sp)
    80004006:	1880                	addi	s0,sp,112
    80004008:	8baa                	mv	s7,a0
    8000400a:	8c2e                	mv	s8,a1
    8000400c:	8ab2                	mv	s5,a2
    8000400e:	84b6                	mv	s1,a3
    80004010:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004012:	9f35                	addw	a4,a4,a3
    return 0;
    80004014:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004016:	0ad76063          	bltu	a4,a3,800040b6 <readi+0xd2>
  if(off + n > ip->size)
    8000401a:	00e7f463          	bgeu	a5,a4,80004022 <readi+0x3e>
    n = ip->size - off;
    8000401e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004022:	0a0b0963          	beqz	s6,800040d4 <readi+0xf0>
    80004026:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004028:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000402c:	5cfd                	li	s9,-1
    8000402e:	a82d                	j	80004068 <readi+0x84>
    80004030:	020a1d93          	slli	s11,s4,0x20
    80004034:	020ddd93          	srli	s11,s11,0x20
    80004038:	05890613          	addi	a2,s2,88
    8000403c:	86ee                	mv	a3,s11
    8000403e:	963a                	add	a2,a2,a4
    80004040:	85d6                	mv	a1,s5
    80004042:	8562                	mv	a0,s8
    80004044:	ffffe097          	auipc	ra,0xffffe
    80004048:	5ba080e7          	jalr	1466(ra) # 800025fe <either_copyout>
    8000404c:	05950d63          	beq	a0,s9,800040a6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004050:	854a                	mv	a0,s2
    80004052:	fffff097          	auipc	ra,0xfffff
    80004056:	60c080e7          	jalr	1548(ra) # 8000365e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000405a:	013a09bb          	addw	s3,s4,s3
    8000405e:	009a04bb          	addw	s1,s4,s1
    80004062:	9aee                	add	s5,s5,s11
    80004064:	0569f763          	bgeu	s3,s6,800040b2 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004068:	000ba903          	lw	s2,0(s7)
    8000406c:	00a4d59b          	srliw	a1,s1,0xa
    80004070:	855e                	mv	a0,s7
    80004072:	00000097          	auipc	ra,0x0
    80004076:	8b0080e7          	jalr	-1872(ra) # 80003922 <bmap>
    8000407a:	0005059b          	sext.w	a1,a0
    8000407e:	854a                	mv	a0,s2
    80004080:	fffff097          	auipc	ra,0xfffff
    80004084:	4ae080e7          	jalr	1198(ra) # 8000352e <bread>
    80004088:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000408a:	3ff4f713          	andi	a4,s1,1023
    8000408e:	40ed07bb          	subw	a5,s10,a4
    80004092:	413b06bb          	subw	a3,s6,s3
    80004096:	8a3e                	mv	s4,a5
    80004098:	2781                	sext.w	a5,a5
    8000409a:	0006861b          	sext.w	a2,a3
    8000409e:	f8f679e3          	bgeu	a2,a5,80004030 <readi+0x4c>
    800040a2:	8a36                	mv	s4,a3
    800040a4:	b771                	j	80004030 <readi+0x4c>
      brelse(bp);
    800040a6:	854a                	mv	a0,s2
    800040a8:	fffff097          	auipc	ra,0xfffff
    800040ac:	5b6080e7          	jalr	1462(ra) # 8000365e <brelse>
      tot = -1;
    800040b0:	59fd                	li	s3,-1
  }
  return tot;
    800040b2:	0009851b          	sext.w	a0,s3
}
    800040b6:	70a6                	ld	ra,104(sp)
    800040b8:	7406                	ld	s0,96(sp)
    800040ba:	64e6                	ld	s1,88(sp)
    800040bc:	6946                	ld	s2,80(sp)
    800040be:	69a6                	ld	s3,72(sp)
    800040c0:	6a06                	ld	s4,64(sp)
    800040c2:	7ae2                	ld	s5,56(sp)
    800040c4:	7b42                	ld	s6,48(sp)
    800040c6:	7ba2                	ld	s7,40(sp)
    800040c8:	7c02                	ld	s8,32(sp)
    800040ca:	6ce2                	ld	s9,24(sp)
    800040cc:	6d42                	ld	s10,16(sp)
    800040ce:	6da2                	ld	s11,8(sp)
    800040d0:	6165                	addi	sp,sp,112
    800040d2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040d4:	89da                	mv	s3,s6
    800040d6:	bff1                	j	800040b2 <readi+0xce>
    return 0;
    800040d8:	4501                	li	a0,0
}
    800040da:	8082                	ret

00000000800040dc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040dc:	457c                	lw	a5,76(a0)
    800040de:	10d7e863          	bltu	a5,a3,800041ee <writei+0x112>
{
    800040e2:	7159                	addi	sp,sp,-112
    800040e4:	f486                	sd	ra,104(sp)
    800040e6:	f0a2                	sd	s0,96(sp)
    800040e8:	eca6                	sd	s1,88(sp)
    800040ea:	e8ca                	sd	s2,80(sp)
    800040ec:	e4ce                	sd	s3,72(sp)
    800040ee:	e0d2                	sd	s4,64(sp)
    800040f0:	fc56                	sd	s5,56(sp)
    800040f2:	f85a                	sd	s6,48(sp)
    800040f4:	f45e                	sd	s7,40(sp)
    800040f6:	f062                	sd	s8,32(sp)
    800040f8:	ec66                	sd	s9,24(sp)
    800040fa:	e86a                	sd	s10,16(sp)
    800040fc:	e46e                	sd	s11,8(sp)
    800040fe:	1880                	addi	s0,sp,112
    80004100:	8b2a                	mv	s6,a0
    80004102:	8c2e                	mv	s8,a1
    80004104:	8ab2                	mv	s5,a2
    80004106:	8936                	mv	s2,a3
    80004108:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000410a:	00e687bb          	addw	a5,a3,a4
    8000410e:	0ed7e263          	bltu	a5,a3,800041f2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004112:	00043737          	lui	a4,0x43
    80004116:	0ef76063          	bltu	a4,a5,800041f6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000411a:	0c0b8863          	beqz	s7,800041ea <writei+0x10e>
    8000411e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004120:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004124:	5cfd                	li	s9,-1
    80004126:	a091                	j	8000416a <writei+0x8e>
    80004128:	02099d93          	slli	s11,s3,0x20
    8000412c:	020ddd93          	srli	s11,s11,0x20
    80004130:	05848513          	addi	a0,s1,88
    80004134:	86ee                	mv	a3,s11
    80004136:	8656                	mv	a2,s5
    80004138:	85e2                	mv	a1,s8
    8000413a:	953a                	add	a0,a0,a4
    8000413c:	ffffe097          	auipc	ra,0xffffe
    80004140:	518080e7          	jalr	1304(ra) # 80002654 <either_copyin>
    80004144:	07950263          	beq	a0,s9,800041a8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004148:	8526                	mv	a0,s1
    8000414a:	00000097          	auipc	ra,0x0
    8000414e:	790080e7          	jalr	1936(ra) # 800048da <log_write>
    brelse(bp);
    80004152:	8526                	mv	a0,s1
    80004154:	fffff097          	auipc	ra,0xfffff
    80004158:	50a080e7          	jalr	1290(ra) # 8000365e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000415c:	01498a3b          	addw	s4,s3,s4
    80004160:	0129893b          	addw	s2,s3,s2
    80004164:	9aee                	add	s5,s5,s11
    80004166:	057a7663          	bgeu	s4,s7,800041b2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000416a:	000b2483          	lw	s1,0(s6)
    8000416e:	00a9559b          	srliw	a1,s2,0xa
    80004172:	855a                	mv	a0,s6
    80004174:	fffff097          	auipc	ra,0xfffff
    80004178:	7ae080e7          	jalr	1966(ra) # 80003922 <bmap>
    8000417c:	0005059b          	sext.w	a1,a0
    80004180:	8526                	mv	a0,s1
    80004182:	fffff097          	auipc	ra,0xfffff
    80004186:	3ac080e7          	jalr	940(ra) # 8000352e <bread>
    8000418a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000418c:	3ff97713          	andi	a4,s2,1023
    80004190:	40ed07bb          	subw	a5,s10,a4
    80004194:	414b86bb          	subw	a3,s7,s4
    80004198:	89be                	mv	s3,a5
    8000419a:	2781                	sext.w	a5,a5
    8000419c:	0006861b          	sext.w	a2,a3
    800041a0:	f8f674e3          	bgeu	a2,a5,80004128 <writei+0x4c>
    800041a4:	89b6                	mv	s3,a3
    800041a6:	b749                	j	80004128 <writei+0x4c>
      brelse(bp);
    800041a8:	8526                	mv	a0,s1
    800041aa:	fffff097          	auipc	ra,0xfffff
    800041ae:	4b4080e7          	jalr	1204(ra) # 8000365e <brelse>
  }

  if(off > ip->size)
    800041b2:	04cb2783          	lw	a5,76(s6)
    800041b6:	0127f463          	bgeu	a5,s2,800041be <writei+0xe2>
    ip->size = off;
    800041ba:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800041be:	855a                	mv	a0,s6
    800041c0:	00000097          	auipc	ra,0x0
    800041c4:	aa6080e7          	jalr	-1370(ra) # 80003c66 <iupdate>

  return tot;
    800041c8:	000a051b          	sext.w	a0,s4
}
    800041cc:	70a6                	ld	ra,104(sp)
    800041ce:	7406                	ld	s0,96(sp)
    800041d0:	64e6                	ld	s1,88(sp)
    800041d2:	6946                	ld	s2,80(sp)
    800041d4:	69a6                	ld	s3,72(sp)
    800041d6:	6a06                	ld	s4,64(sp)
    800041d8:	7ae2                	ld	s5,56(sp)
    800041da:	7b42                	ld	s6,48(sp)
    800041dc:	7ba2                	ld	s7,40(sp)
    800041de:	7c02                	ld	s8,32(sp)
    800041e0:	6ce2                	ld	s9,24(sp)
    800041e2:	6d42                	ld	s10,16(sp)
    800041e4:	6da2                	ld	s11,8(sp)
    800041e6:	6165                	addi	sp,sp,112
    800041e8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041ea:	8a5e                	mv	s4,s7
    800041ec:	bfc9                	j	800041be <writei+0xe2>
    return -1;
    800041ee:	557d                	li	a0,-1
}
    800041f0:	8082                	ret
    return -1;
    800041f2:	557d                	li	a0,-1
    800041f4:	bfe1                	j	800041cc <writei+0xf0>
    return -1;
    800041f6:	557d                	li	a0,-1
    800041f8:	bfd1                	j	800041cc <writei+0xf0>

00000000800041fa <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041fa:	1141                	addi	sp,sp,-16
    800041fc:	e406                	sd	ra,8(sp)
    800041fe:	e022                	sd	s0,0(sp)
    80004200:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004202:	4639                	li	a2,14
    80004204:	ffffd097          	auipc	ra,0xffffd
    80004208:	bb4080e7          	jalr	-1100(ra) # 80000db8 <strncmp>
}
    8000420c:	60a2                	ld	ra,8(sp)
    8000420e:	6402                	ld	s0,0(sp)
    80004210:	0141                	addi	sp,sp,16
    80004212:	8082                	ret

0000000080004214 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004214:	7139                	addi	sp,sp,-64
    80004216:	fc06                	sd	ra,56(sp)
    80004218:	f822                	sd	s0,48(sp)
    8000421a:	f426                	sd	s1,40(sp)
    8000421c:	f04a                	sd	s2,32(sp)
    8000421e:	ec4e                	sd	s3,24(sp)
    80004220:	e852                	sd	s4,16(sp)
    80004222:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004224:	04451703          	lh	a4,68(a0)
    80004228:	4785                	li	a5,1
    8000422a:	00f71a63          	bne	a4,a5,8000423e <dirlookup+0x2a>
    8000422e:	892a                	mv	s2,a0
    80004230:	89ae                	mv	s3,a1
    80004232:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004234:	457c                	lw	a5,76(a0)
    80004236:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004238:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000423a:	e79d                	bnez	a5,80004268 <dirlookup+0x54>
    8000423c:	a8a5                	j	800042b4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000423e:	00004517          	auipc	a0,0x4
    80004242:	5da50513          	addi	a0,a0,1498 # 80008818 <syscalls+0x1b8>
    80004246:	ffffc097          	auipc	ra,0xffffc
    8000424a:	2f8080e7          	jalr	760(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000424e:	00004517          	auipc	a0,0x4
    80004252:	5e250513          	addi	a0,a0,1506 # 80008830 <syscalls+0x1d0>
    80004256:	ffffc097          	auipc	ra,0xffffc
    8000425a:	2e8080e7          	jalr	744(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000425e:	24c1                	addiw	s1,s1,16
    80004260:	04c92783          	lw	a5,76(s2)
    80004264:	04f4f763          	bgeu	s1,a5,800042b2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004268:	4741                	li	a4,16
    8000426a:	86a6                	mv	a3,s1
    8000426c:	fc040613          	addi	a2,s0,-64
    80004270:	4581                	li	a1,0
    80004272:	854a                	mv	a0,s2
    80004274:	00000097          	auipc	ra,0x0
    80004278:	d70080e7          	jalr	-656(ra) # 80003fe4 <readi>
    8000427c:	47c1                	li	a5,16
    8000427e:	fcf518e3          	bne	a0,a5,8000424e <dirlookup+0x3a>
    if(de.inum == 0)
    80004282:	fc045783          	lhu	a5,-64(s0)
    80004286:	dfe1                	beqz	a5,8000425e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004288:	fc240593          	addi	a1,s0,-62
    8000428c:	854e                	mv	a0,s3
    8000428e:	00000097          	auipc	ra,0x0
    80004292:	f6c080e7          	jalr	-148(ra) # 800041fa <namecmp>
    80004296:	f561                	bnez	a0,8000425e <dirlookup+0x4a>
      if(poff)
    80004298:	000a0463          	beqz	s4,800042a0 <dirlookup+0x8c>
        *poff = off;
    8000429c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800042a0:	fc045583          	lhu	a1,-64(s0)
    800042a4:	00092503          	lw	a0,0(s2)
    800042a8:	fffff097          	auipc	ra,0xfffff
    800042ac:	754080e7          	jalr	1876(ra) # 800039fc <iget>
    800042b0:	a011                	j	800042b4 <dirlookup+0xa0>
  return 0;
    800042b2:	4501                	li	a0,0
}
    800042b4:	70e2                	ld	ra,56(sp)
    800042b6:	7442                	ld	s0,48(sp)
    800042b8:	74a2                	ld	s1,40(sp)
    800042ba:	7902                	ld	s2,32(sp)
    800042bc:	69e2                	ld	s3,24(sp)
    800042be:	6a42                	ld	s4,16(sp)
    800042c0:	6121                	addi	sp,sp,64
    800042c2:	8082                	ret

00000000800042c4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042c4:	711d                	addi	sp,sp,-96
    800042c6:	ec86                	sd	ra,88(sp)
    800042c8:	e8a2                	sd	s0,80(sp)
    800042ca:	e4a6                	sd	s1,72(sp)
    800042cc:	e0ca                	sd	s2,64(sp)
    800042ce:	fc4e                	sd	s3,56(sp)
    800042d0:	f852                	sd	s4,48(sp)
    800042d2:	f456                	sd	s5,40(sp)
    800042d4:	f05a                	sd	s6,32(sp)
    800042d6:	ec5e                	sd	s7,24(sp)
    800042d8:	e862                	sd	s8,16(sp)
    800042da:	e466                	sd	s9,8(sp)
    800042dc:	1080                	addi	s0,sp,96
    800042de:	84aa                	mv	s1,a0
    800042e0:	8b2e                	mv	s6,a1
    800042e2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042e4:	00054703          	lbu	a4,0(a0)
    800042e8:	02f00793          	li	a5,47
    800042ec:	02f70363          	beq	a4,a5,80004312 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042f0:	ffffe097          	auipc	ra,0xffffe
    800042f4:	99c080e7          	jalr	-1636(ra) # 80001c8c <myproc>
    800042f8:	15053503          	ld	a0,336(a0)
    800042fc:	00000097          	auipc	ra,0x0
    80004300:	9f6080e7          	jalr	-1546(ra) # 80003cf2 <idup>
    80004304:	89aa                	mv	s3,a0
  while(*path == '/')
    80004306:	02f00913          	li	s2,47
  len = path - s;
    8000430a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000430c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000430e:	4c05                	li	s8,1
    80004310:	a865                	j	800043c8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004312:	4585                	li	a1,1
    80004314:	4505                	li	a0,1
    80004316:	fffff097          	auipc	ra,0xfffff
    8000431a:	6e6080e7          	jalr	1766(ra) # 800039fc <iget>
    8000431e:	89aa                	mv	s3,a0
    80004320:	b7dd                	j	80004306 <namex+0x42>
      iunlockput(ip);
    80004322:	854e                	mv	a0,s3
    80004324:	00000097          	auipc	ra,0x0
    80004328:	c6e080e7          	jalr	-914(ra) # 80003f92 <iunlockput>
      return 0;
    8000432c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000432e:	854e                	mv	a0,s3
    80004330:	60e6                	ld	ra,88(sp)
    80004332:	6446                	ld	s0,80(sp)
    80004334:	64a6                	ld	s1,72(sp)
    80004336:	6906                	ld	s2,64(sp)
    80004338:	79e2                	ld	s3,56(sp)
    8000433a:	7a42                	ld	s4,48(sp)
    8000433c:	7aa2                	ld	s5,40(sp)
    8000433e:	7b02                	ld	s6,32(sp)
    80004340:	6be2                	ld	s7,24(sp)
    80004342:	6c42                	ld	s8,16(sp)
    80004344:	6ca2                	ld	s9,8(sp)
    80004346:	6125                	addi	sp,sp,96
    80004348:	8082                	ret
      iunlock(ip);
    8000434a:	854e                	mv	a0,s3
    8000434c:	00000097          	auipc	ra,0x0
    80004350:	aa6080e7          	jalr	-1370(ra) # 80003df2 <iunlock>
      return ip;
    80004354:	bfe9                	j	8000432e <namex+0x6a>
      iunlockput(ip);
    80004356:	854e                	mv	a0,s3
    80004358:	00000097          	auipc	ra,0x0
    8000435c:	c3a080e7          	jalr	-966(ra) # 80003f92 <iunlockput>
      return 0;
    80004360:	89d2                	mv	s3,s4
    80004362:	b7f1                	j	8000432e <namex+0x6a>
  len = path - s;
    80004364:	40b48633          	sub	a2,s1,a1
    80004368:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000436c:	094cd463          	bge	s9,s4,800043f4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004370:	4639                	li	a2,14
    80004372:	8556                	mv	a0,s5
    80004374:	ffffd097          	auipc	ra,0xffffd
    80004378:	9cc080e7          	jalr	-1588(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000437c:	0004c783          	lbu	a5,0(s1)
    80004380:	01279763          	bne	a5,s2,8000438e <namex+0xca>
    path++;
    80004384:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004386:	0004c783          	lbu	a5,0(s1)
    8000438a:	ff278de3          	beq	a5,s2,80004384 <namex+0xc0>
    ilock(ip);
    8000438e:	854e                	mv	a0,s3
    80004390:	00000097          	auipc	ra,0x0
    80004394:	9a0080e7          	jalr	-1632(ra) # 80003d30 <ilock>
    if(ip->type != T_DIR){
    80004398:	04499783          	lh	a5,68(s3)
    8000439c:	f98793e3          	bne	a5,s8,80004322 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800043a0:	000b0563          	beqz	s6,800043aa <namex+0xe6>
    800043a4:	0004c783          	lbu	a5,0(s1)
    800043a8:	d3cd                	beqz	a5,8000434a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800043aa:	865e                	mv	a2,s7
    800043ac:	85d6                	mv	a1,s5
    800043ae:	854e                	mv	a0,s3
    800043b0:	00000097          	auipc	ra,0x0
    800043b4:	e64080e7          	jalr	-412(ra) # 80004214 <dirlookup>
    800043b8:	8a2a                	mv	s4,a0
    800043ba:	dd51                	beqz	a0,80004356 <namex+0x92>
    iunlockput(ip);
    800043bc:	854e                	mv	a0,s3
    800043be:	00000097          	auipc	ra,0x0
    800043c2:	bd4080e7          	jalr	-1068(ra) # 80003f92 <iunlockput>
    ip = next;
    800043c6:	89d2                	mv	s3,s4
  while(*path == '/')
    800043c8:	0004c783          	lbu	a5,0(s1)
    800043cc:	05279763          	bne	a5,s2,8000441a <namex+0x156>
    path++;
    800043d0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043d2:	0004c783          	lbu	a5,0(s1)
    800043d6:	ff278de3          	beq	a5,s2,800043d0 <namex+0x10c>
  if(*path == 0)
    800043da:	c79d                	beqz	a5,80004408 <namex+0x144>
    path++;
    800043dc:	85a6                	mv	a1,s1
  len = path - s;
    800043de:	8a5e                	mv	s4,s7
    800043e0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800043e2:	01278963          	beq	a5,s2,800043f4 <namex+0x130>
    800043e6:	dfbd                	beqz	a5,80004364 <namex+0xa0>
    path++;
    800043e8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800043ea:	0004c783          	lbu	a5,0(s1)
    800043ee:	ff279ce3          	bne	a5,s2,800043e6 <namex+0x122>
    800043f2:	bf8d                	j	80004364 <namex+0xa0>
    memmove(name, s, len);
    800043f4:	2601                	sext.w	a2,a2
    800043f6:	8556                	mv	a0,s5
    800043f8:	ffffd097          	auipc	ra,0xffffd
    800043fc:	948080e7          	jalr	-1720(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004400:	9a56                	add	s4,s4,s5
    80004402:	000a0023          	sb	zero,0(s4)
    80004406:	bf9d                	j	8000437c <namex+0xb8>
  if(nameiparent){
    80004408:	f20b03e3          	beqz	s6,8000432e <namex+0x6a>
    iput(ip);
    8000440c:	854e                	mv	a0,s3
    8000440e:	00000097          	auipc	ra,0x0
    80004412:	adc080e7          	jalr	-1316(ra) # 80003eea <iput>
    return 0;
    80004416:	4981                	li	s3,0
    80004418:	bf19                	j	8000432e <namex+0x6a>
  if(*path == 0)
    8000441a:	d7fd                	beqz	a5,80004408 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000441c:	0004c783          	lbu	a5,0(s1)
    80004420:	85a6                	mv	a1,s1
    80004422:	b7d1                	j	800043e6 <namex+0x122>

0000000080004424 <dirlink>:
{
    80004424:	7139                	addi	sp,sp,-64
    80004426:	fc06                	sd	ra,56(sp)
    80004428:	f822                	sd	s0,48(sp)
    8000442a:	f426                	sd	s1,40(sp)
    8000442c:	f04a                	sd	s2,32(sp)
    8000442e:	ec4e                	sd	s3,24(sp)
    80004430:	e852                	sd	s4,16(sp)
    80004432:	0080                	addi	s0,sp,64
    80004434:	892a                	mv	s2,a0
    80004436:	8a2e                	mv	s4,a1
    80004438:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000443a:	4601                	li	a2,0
    8000443c:	00000097          	auipc	ra,0x0
    80004440:	dd8080e7          	jalr	-552(ra) # 80004214 <dirlookup>
    80004444:	e93d                	bnez	a0,800044ba <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004446:	04c92483          	lw	s1,76(s2)
    8000444a:	c49d                	beqz	s1,80004478 <dirlink+0x54>
    8000444c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000444e:	4741                	li	a4,16
    80004450:	86a6                	mv	a3,s1
    80004452:	fc040613          	addi	a2,s0,-64
    80004456:	4581                	li	a1,0
    80004458:	854a                	mv	a0,s2
    8000445a:	00000097          	auipc	ra,0x0
    8000445e:	b8a080e7          	jalr	-1142(ra) # 80003fe4 <readi>
    80004462:	47c1                	li	a5,16
    80004464:	06f51163          	bne	a0,a5,800044c6 <dirlink+0xa2>
    if(de.inum == 0)
    80004468:	fc045783          	lhu	a5,-64(s0)
    8000446c:	c791                	beqz	a5,80004478 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000446e:	24c1                	addiw	s1,s1,16
    80004470:	04c92783          	lw	a5,76(s2)
    80004474:	fcf4ede3          	bltu	s1,a5,8000444e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004478:	4639                	li	a2,14
    8000447a:	85d2                	mv	a1,s4
    8000447c:	fc240513          	addi	a0,s0,-62
    80004480:	ffffd097          	auipc	ra,0xffffd
    80004484:	974080e7          	jalr	-1676(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004488:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000448c:	4741                	li	a4,16
    8000448e:	86a6                	mv	a3,s1
    80004490:	fc040613          	addi	a2,s0,-64
    80004494:	4581                	li	a1,0
    80004496:	854a                	mv	a0,s2
    80004498:	00000097          	auipc	ra,0x0
    8000449c:	c44080e7          	jalr	-956(ra) # 800040dc <writei>
    800044a0:	872a                	mv	a4,a0
    800044a2:	47c1                	li	a5,16
  return 0;
    800044a4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044a6:	02f71863          	bne	a4,a5,800044d6 <dirlink+0xb2>
}
    800044aa:	70e2                	ld	ra,56(sp)
    800044ac:	7442                	ld	s0,48(sp)
    800044ae:	74a2                	ld	s1,40(sp)
    800044b0:	7902                	ld	s2,32(sp)
    800044b2:	69e2                	ld	s3,24(sp)
    800044b4:	6a42                	ld	s4,16(sp)
    800044b6:	6121                	addi	sp,sp,64
    800044b8:	8082                	ret
    iput(ip);
    800044ba:	00000097          	auipc	ra,0x0
    800044be:	a30080e7          	jalr	-1488(ra) # 80003eea <iput>
    return -1;
    800044c2:	557d                	li	a0,-1
    800044c4:	b7dd                	j	800044aa <dirlink+0x86>
      panic("dirlink read");
    800044c6:	00004517          	auipc	a0,0x4
    800044ca:	37a50513          	addi	a0,a0,890 # 80008840 <syscalls+0x1e0>
    800044ce:	ffffc097          	auipc	ra,0xffffc
    800044d2:	070080e7          	jalr	112(ra) # 8000053e <panic>
    panic("dirlink");
    800044d6:	00004517          	auipc	a0,0x4
    800044da:	47a50513          	addi	a0,a0,1146 # 80008950 <syscalls+0x2f0>
    800044de:	ffffc097          	auipc	ra,0xffffc
    800044e2:	060080e7          	jalr	96(ra) # 8000053e <panic>

00000000800044e6 <namei>:

struct inode*
namei(char *path)
{
    800044e6:	1101                	addi	sp,sp,-32
    800044e8:	ec06                	sd	ra,24(sp)
    800044ea:	e822                	sd	s0,16(sp)
    800044ec:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044ee:	fe040613          	addi	a2,s0,-32
    800044f2:	4581                	li	a1,0
    800044f4:	00000097          	auipc	ra,0x0
    800044f8:	dd0080e7          	jalr	-560(ra) # 800042c4 <namex>
}
    800044fc:	60e2                	ld	ra,24(sp)
    800044fe:	6442                	ld	s0,16(sp)
    80004500:	6105                	addi	sp,sp,32
    80004502:	8082                	ret

0000000080004504 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004504:	1141                	addi	sp,sp,-16
    80004506:	e406                	sd	ra,8(sp)
    80004508:	e022                	sd	s0,0(sp)
    8000450a:	0800                	addi	s0,sp,16
    8000450c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000450e:	4585                	li	a1,1
    80004510:	00000097          	auipc	ra,0x0
    80004514:	db4080e7          	jalr	-588(ra) # 800042c4 <namex>
}
    80004518:	60a2                	ld	ra,8(sp)
    8000451a:	6402                	ld	s0,0(sp)
    8000451c:	0141                	addi	sp,sp,16
    8000451e:	8082                	ret

0000000080004520 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004520:	1101                	addi	sp,sp,-32
    80004522:	ec06                	sd	ra,24(sp)
    80004524:	e822                	sd	s0,16(sp)
    80004526:	e426                	sd	s1,8(sp)
    80004528:	e04a                	sd	s2,0(sp)
    8000452a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000452c:	0001d917          	auipc	s2,0x1d
    80004530:	20490913          	addi	s2,s2,516 # 80021730 <log>
    80004534:	01892583          	lw	a1,24(s2)
    80004538:	02892503          	lw	a0,40(s2)
    8000453c:	fffff097          	auipc	ra,0xfffff
    80004540:	ff2080e7          	jalr	-14(ra) # 8000352e <bread>
    80004544:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004546:	02c92683          	lw	a3,44(s2)
    8000454a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000454c:	02d05763          	blez	a3,8000457a <write_head+0x5a>
    80004550:	0001d797          	auipc	a5,0x1d
    80004554:	21078793          	addi	a5,a5,528 # 80021760 <log+0x30>
    80004558:	05c50713          	addi	a4,a0,92
    8000455c:	36fd                	addiw	a3,a3,-1
    8000455e:	1682                	slli	a3,a3,0x20
    80004560:	9281                	srli	a3,a3,0x20
    80004562:	068a                	slli	a3,a3,0x2
    80004564:	0001d617          	auipc	a2,0x1d
    80004568:	20060613          	addi	a2,a2,512 # 80021764 <log+0x34>
    8000456c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000456e:	4390                	lw	a2,0(a5)
    80004570:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004572:	0791                	addi	a5,a5,4
    80004574:	0711                	addi	a4,a4,4
    80004576:	fed79ce3          	bne	a5,a3,8000456e <write_head+0x4e>
  }
  bwrite(buf);
    8000457a:	8526                	mv	a0,s1
    8000457c:	fffff097          	auipc	ra,0xfffff
    80004580:	0a4080e7          	jalr	164(ra) # 80003620 <bwrite>
  brelse(buf);
    80004584:	8526                	mv	a0,s1
    80004586:	fffff097          	auipc	ra,0xfffff
    8000458a:	0d8080e7          	jalr	216(ra) # 8000365e <brelse>
}
    8000458e:	60e2                	ld	ra,24(sp)
    80004590:	6442                	ld	s0,16(sp)
    80004592:	64a2                	ld	s1,8(sp)
    80004594:	6902                	ld	s2,0(sp)
    80004596:	6105                	addi	sp,sp,32
    80004598:	8082                	ret

000000008000459a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000459a:	0001d797          	auipc	a5,0x1d
    8000459e:	1c27a783          	lw	a5,450(a5) # 8002175c <log+0x2c>
    800045a2:	0af05d63          	blez	a5,8000465c <install_trans+0xc2>
{
    800045a6:	7139                	addi	sp,sp,-64
    800045a8:	fc06                	sd	ra,56(sp)
    800045aa:	f822                	sd	s0,48(sp)
    800045ac:	f426                	sd	s1,40(sp)
    800045ae:	f04a                	sd	s2,32(sp)
    800045b0:	ec4e                	sd	s3,24(sp)
    800045b2:	e852                	sd	s4,16(sp)
    800045b4:	e456                	sd	s5,8(sp)
    800045b6:	e05a                	sd	s6,0(sp)
    800045b8:	0080                	addi	s0,sp,64
    800045ba:	8b2a                	mv	s6,a0
    800045bc:	0001da97          	auipc	s5,0x1d
    800045c0:	1a4a8a93          	addi	s5,s5,420 # 80021760 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045c4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045c6:	0001d997          	auipc	s3,0x1d
    800045ca:	16a98993          	addi	s3,s3,362 # 80021730 <log>
    800045ce:	a035                	j	800045fa <install_trans+0x60>
      bunpin(dbuf);
    800045d0:	8526                	mv	a0,s1
    800045d2:	fffff097          	auipc	ra,0xfffff
    800045d6:	166080e7          	jalr	358(ra) # 80003738 <bunpin>
    brelse(lbuf);
    800045da:	854a                	mv	a0,s2
    800045dc:	fffff097          	auipc	ra,0xfffff
    800045e0:	082080e7          	jalr	130(ra) # 8000365e <brelse>
    brelse(dbuf);
    800045e4:	8526                	mv	a0,s1
    800045e6:	fffff097          	auipc	ra,0xfffff
    800045ea:	078080e7          	jalr	120(ra) # 8000365e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ee:	2a05                	addiw	s4,s4,1
    800045f0:	0a91                	addi	s5,s5,4
    800045f2:	02c9a783          	lw	a5,44(s3)
    800045f6:	04fa5963          	bge	s4,a5,80004648 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045fa:	0189a583          	lw	a1,24(s3)
    800045fe:	014585bb          	addw	a1,a1,s4
    80004602:	2585                	addiw	a1,a1,1
    80004604:	0289a503          	lw	a0,40(s3)
    80004608:	fffff097          	auipc	ra,0xfffff
    8000460c:	f26080e7          	jalr	-218(ra) # 8000352e <bread>
    80004610:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004612:	000aa583          	lw	a1,0(s5)
    80004616:	0289a503          	lw	a0,40(s3)
    8000461a:	fffff097          	auipc	ra,0xfffff
    8000461e:	f14080e7          	jalr	-236(ra) # 8000352e <bread>
    80004622:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004624:	40000613          	li	a2,1024
    80004628:	05890593          	addi	a1,s2,88
    8000462c:	05850513          	addi	a0,a0,88
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	710080e7          	jalr	1808(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004638:	8526                	mv	a0,s1
    8000463a:	fffff097          	auipc	ra,0xfffff
    8000463e:	fe6080e7          	jalr	-26(ra) # 80003620 <bwrite>
    if(recovering == 0)
    80004642:	f80b1ce3          	bnez	s6,800045da <install_trans+0x40>
    80004646:	b769                	j	800045d0 <install_trans+0x36>
}
    80004648:	70e2                	ld	ra,56(sp)
    8000464a:	7442                	ld	s0,48(sp)
    8000464c:	74a2                	ld	s1,40(sp)
    8000464e:	7902                	ld	s2,32(sp)
    80004650:	69e2                	ld	s3,24(sp)
    80004652:	6a42                	ld	s4,16(sp)
    80004654:	6aa2                	ld	s5,8(sp)
    80004656:	6b02                	ld	s6,0(sp)
    80004658:	6121                	addi	sp,sp,64
    8000465a:	8082                	ret
    8000465c:	8082                	ret

000000008000465e <initlog>:
{
    8000465e:	7179                	addi	sp,sp,-48
    80004660:	f406                	sd	ra,40(sp)
    80004662:	f022                	sd	s0,32(sp)
    80004664:	ec26                	sd	s1,24(sp)
    80004666:	e84a                	sd	s2,16(sp)
    80004668:	e44e                	sd	s3,8(sp)
    8000466a:	1800                	addi	s0,sp,48
    8000466c:	892a                	mv	s2,a0
    8000466e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004670:	0001d497          	auipc	s1,0x1d
    80004674:	0c048493          	addi	s1,s1,192 # 80021730 <log>
    80004678:	00004597          	auipc	a1,0x4
    8000467c:	1d858593          	addi	a1,a1,472 # 80008850 <syscalls+0x1f0>
    80004680:	8526                	mv	a0,s1
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	4d2080e7          	jalr	1234(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000468a:	0149a583          	lw	a1,20(s3)
    8000468e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004690:	0109a783          	lw	a5,16(s3)
    80004694:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004696:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000469a:	854a                	mv	a0,s2
    8000469c:	fffff097          	auipc	ra,0xfffff
    800046a0:	e92080e7          	jalr	-366(ra) # 8000352e <bread>
  log.lh.n = lh->n;
    800046a4:	4d3c                	lw	a5,88(a0)
    800046a6:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800046a8:	02f05563          	blez	a5,800046d2 <initlog+0x74>
    800046ac:	05c50713          	addi	a4,a0,92
    800046b0:	0001d697          	auipc	a3,0x1d
    800046b4:	0b068693          	addi	a3,a3,176 # 80021760 <log+0x30>
    800046b8:	37fd                	addiw	a5,a5,-1
    800046ba:	1782                	slli	a5,a5,0x20
    800046bc:	9381                	srli	a5,a5,0x20
    800046be:	078a                	slli	a5,a5,0x2
    800046c0:	06050613          	addi	a2,a0,96
    800046c4:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800046c6:	4310                	lw	a2,0(a4)
    800046c8:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800046ca:	0711                	addi	a4,a4,4
    800046cc:	0691                	addi	a3,a3,4
    800046ce:	fef71ce3          	bne	a4,a5,800046c6 <initlog+0x68>
  brelse(buf);
    800046d2:	fffff097          	auipc	ra,0xfffff
    800046d6:	f8c080e7          	jalr	-116(ra) # 8000365e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046da:	4505                	li	a0,1
    800046dc:	00000097          	auipc	ra,0x0
    800046e0:	ebe080e7          	jalr	-322(ra) # 8000459a <install_trans>
  log.lh.n = 0;
    800046e4:	0001d797          	auipc	a5,0x1d
    800046e8:	0607ac23          	sw	zero,120(a5) # 8002175c <log+0x2c>
  write_head(); // clear the log
    800046ec:	00000097          	auipc	ra,0x0
    800046f0:	e34080e7          	jalr	-460(ra) # 80004520 <write_head>
}
    800046f4:	70a2                	ld	ra,40(sp)
    800046f6:	7402                	ld	s0,32(sp)
    800046f8:	64e2                	ld	s1,24(sp)
    800046fa:	6942                	ld	s2,16(sp)
    800046fc:	69a2                	ld	s3,8(sp)
    800046fe:	6145                	addi	sp,sp,48
    80004700:	8082                	ret

0000000080004702 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004702:	1101                	addi	sp,sp,-32
    80004704:	ec06                	sd	ra,24(sp)
    80004706:	e822                	sd	s0,16(sp)
    80004708:	e426                	sd	s1,8(sp)
    8000470a:	e04a                	sd	s2,0(sp)
    8000470c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000470e:	0001d517          	auipc	a0,0x1d
    80004712:	02250513          	addi	a0,a0,34 # 80021730 <log>
    80004716:	ffffc097          	auipc	ra,0xffffc
    8000471a:	4ce080e7          	jalr	1230(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000471e:	0001d497          	auipc	s1,0x1d
    80004722:	01248493          	addi	s1,s1,18 # 80021730 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004726:	4979                	li	s2,30
    80004728:	a039                	j	80004736 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000472a:	85a6                	mv	a1,s1
    8000472c:	8526                	mv	a0,s1
    8000472e:	ffffe097          	auipc	ra,0xffffe
    80004732:	cac080e7          	jalr	-852(ra) # 800023da <sleep>
    if(log.committing){
    80004736:	50dc                	lw	a5,36(s1)
    80004738:	fbed                	bnez	a5,8000472a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000473a:	509c                	lw	a5,32(s1)
    8000473c:	0017871b          	addiw	a4,a5,1
    80004740:	0007069b          	sext.w	a3,a4
    80004744:	0027179b          	slliw	a5,a4,0x2
    80004748:	9fb9                	addw	a5,a5,a4
    8000474a:	0017979b          	slliw	a5,a5,0x1
    8000474e:	54d8                	lw	a4,44(s1)
    80004750:	9fb9                	addw	a5,a5,a4
    80004752:	00f95963          	bge	s2,a5,80004764 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004756:	85a6                	mv	a1,s1
    80004758:	8526                	mv	a0,s1
    8000475a:	ffffe097          	auipc	ra,0xffffe
    8000475e:	c80080e7          	jalr	-896(ra) # 800023da <sleep>
    80004762:	bfd1                	j	80004736 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004764:	0001d517          	auipc	a0,0x1d
    80004768:	fcc50513          	addi	a0,a0,-52 # 80021730 <log>
    8000476c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	52a080e7          	jalr	1322(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004776:	60e2                	ld	ra,24(sp)
    80004778:	6442                	ld	s0,16(sp)
    8000477a:	64a2                	ld	s1,8(sp)
    8000477c:	6902                	ld	s2,0(sp)
    8000477e:	6105                	addi	sp,sp,32
    80004780:	8082                	ret

0000000080004782 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004782:	7139                	addi	sp,sp,-64
    80004784:	fc06                	sd	ra,56(sp)
    80004786:	f822                	sd	s0,48(sp)
    80004788:	f426                	sd	s1,40(sp)
    8000478a:	f04a                	sd	s2,32(sp)
    8000478c:	ec4e                	sd	s3,24(sp)
    8000478e:	e852                	sd	s4,16(sp)
    80004790:	e456                	sd	s5,8(sp)
    80004792:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004794:	0001d497          	auipc	s1,0x1d
    80004798:	f9c48493          	addi	s1,s1,-100 # 80021730 <log>
    8000479c:	8526                	mv	a0,s1
    8000479e:	ffffc097          	auipc	ra,0xffffc
    800047a2:	446080e7          	jalr	1094(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800047a6:	509c                	lw	a5,32(s1)
    800047a8:	37fd                	addiw	a5,a5,-1
    800047aa:	0007891b          	sext.w	s2,a5
    800047ae:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800047b0:	50dc                	lw	a5,36(s1)
    800047b2:	efb9                	bnez	a5,80004810 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800047b4:	06091663          	bnez	s2,80004820 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800047b8:	0001d497          	auipc	s1,0x1d
    800047bc:	f7848493          	addi	s1,s1,-136 # 80021730 <log>
    800047c0:	4785                	li	a5,1
    800047c2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047c4:	8526                	mv	a0,s1
    800047c6:	ffffc097          	auipc	ra,0xffffc
    800047ca:	4d2080e7          	jalr	1234(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047ce:	54dc                	lw	a5,44(s1)
    800047d0:	06f04763          	bgtz	a5,8000483e <end_op+0xbc>
    acquire(&log.lock);
    800047d4:	0001d497          	auipc	s1,0x1d
    800047d8:	f5c48493          	addi	s1,s1,-164 # 80021730 <log>
    800047dc:	8526                	mv	a0,s1
    800047de:	ffffc097          	auipc	ra,0xffffc
    800047e2:	406080e7          	jalr	1030(ra) # 80000be4 <acquire>
    log.committing = 0;
    800047e6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047ea:	8526                	mv	a0,s1
    800047ec:	ffffe097          	auipc	ra,0xffffe
    800047f0:	204080e7          	jalr	516(ra) # 800029f0 <wakeup>
    release(&log.lock);
    800047f4:	8526                	mv	a0,s1
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	4a2080e7          	jalr	1186(ra) # 80000c98 <release>
}
    800047fe:	70e2                	ld	ra,56(sp)
    80004800:	7442                	ld	s0,48(sp)
    80004802:	74a2                	ld	s1,40(sp)
    80004804:	7902                	ld	s2,32(sp)
    80004806:	69e2                	ld	s3,24(sp)
    80004808:	6a42                	ld	s4,16(sp)
    8000480a:	6aa2                	ld	s5,8(sp)
    8000480c:	6121                	addi	sp,sp,64
    8000480e:	8082                	ret
    panic("log.committing");
    80004810:	00004517          	auipc	a0,0x4
    80004814:	04850513          	addi	a0,a0,72 # 80008858 <syscalls+0x1f8>
    80004818:	ffffc097          	auipc	ra,0xffffc
    8000481c:	d26080e7          	jalr	-730(ra) # 8000053e <panic>
    wakeup(&log);
    80004820:	0001d497          	auipc	s1,0x1d
    80004824:	f1048493          	addi	s1,s1,-240 # 80021730 <log>
    80004828:	8526                	mv	a0,s1
    8000482a:	ffffe097          	auipc	ra,0xffffe
    8000482e:	1c6080e7          	jalr	454(ra) # 800029f0 <wakeup>
  release(&log.lock);
    80004832:	8526                	mv	a0,s1
    80004834:	ffffc097          	auipc	ra,0xffffc
    80004838:	464080e7          	jalr	1124(ra) # 80000c98 <release>
  if(do_commit){
    8000483c:	b7c9                	j	800047fe <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000483e:	0001da97          	auipc	s5,0x1d
    80004842:	f22a8a93          	addi	s5,s5,-222 # 80021760 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004846:	0001da17          	auipc	s4,0x1d
    8000484a:	eeaa0a13          	addi	s4,s4,-278 # 80021730 <log>
    8000484e:	018a2583          	lw	a1,24(s4)
    80004852:	012585bb          	addw	a1,a1,s2
    80004856:	2585                	addiw	a1,a1,1
    80004858:	028a2503          	lw	a0,40(s4)
    8000485c:	fffff097          	auipc	ra,0xfffff
    80004860:	cd2080e7          	jalr	-814(ra) # 8000352e <bread>
    80004864:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004866:	000aa583          	lw	a1,0(s5)
    8000486a:	028a2503          	lw	a0,40(s4)
    8000486e:	fffff097          	auipc	ra,0xfffff
    80004872:	cc0080e7          	jalr	-832(ra) # 8000352e <bread>
    80004876:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004878:	40000613          	li	a2,1024
    8000487c:	05850593          	addi	a1,a0,88
    80004880:	05848513          	addi	a0,s1,88
    80004884:	ffffc097          	auipc	ra,0xffffc
    80004888:	4bc080e7          	jalr	1212(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000488c:	8526                	mv	a0,s1
    8000488e:	fffff097          	auipc	ra,0xfffff
    80004892:	d92080e7          	jalr	-622(ra) # 80003620 <bwrite>
    brelse(from);
    80004896:	854e                	mv	a0,s3
    80004898:	fffff097          	auipc	ra,0xfffff
    8000489c:	dc6080e7          	jalr	-570(ra) # 8000365e <brelse>
    brelse(to);
    800048a0:	8526                	mv	a0,s1
    800048a2:	fffff097          	auipc	ra,0xfffff
    800048a6:	dbc080e7          	jalr	-580(ra) # 8000365e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048aa:	2905                	addiw	s2,s2,1
    800048ac:	0a91                	addi	s5,s5,4
    800048ae:	02ca2783          	lw	a5,44(s4)
    800048b2:	f8f94ee3          	blt	s2,a5,8000484e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800048b6:	00000097          	auipc	ra,0x0
    800048ba:	c6a080e7          	jalr	-918(ra) # 80004520 <write_head>
    install_trans(0); // Now install writes to home locations
    800048be:	4501                	li	a0,0
    800048c0:	00000097          	auipc	ra,0x0
    800048c4:	cda080e7          	jalr	-806(ra) # 8000459a <install_trans>
    log.lh.n = 0;
    800048c8:	0001d797          	auipc	a5,0x1d
    800048cc:	e807aa23          	sw	zero,-364(a5) # 8002175c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048d0:	00000097          	auipc	ra,0x0
    800048d4:	c50080e7          	jalr	-944(ra) # 80004520 <write_head>
    800048d8:	bdf5                	j	800047d4 <end_op+0x52>

00000000800048da <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048da:	1101                	addi	sp,sp,-32
    800048dc:	ec06                	sd	ra,24(sp)
    800048de:	e822                	sd	s0,16(sp)
    800048e0:	e426                	sd	s1,8(sp)
    800048e2:	e04a                	sd	s2,0(sp)
    800048e4:	1000                	addi	s0,sp,32
    800048e6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048e8:	0001d917          	auipc	s2,0x1d
    800048ec:	e4890913          	addi	s2,s2,-440 # 80021730 <log>
    800048f0:	854a                	mv	a0,s2
    800048f2:	ffffc097          	auipc	ra,0xffffc
    800048f6:	2f2080e7          	jalr	754(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048fa:	02c92603          	lw	a2,44(s2)
    800048fe:	47f5                	li	a5,29
    80004900:	06c7c563          	blt	a5,a2,8000496a <log_write+0x90>
    80004904:	0001d797          	auipc	a5,0x1d
    80004908:	e487a783          	lw	a5,-440(a5) # 8002174c <log+0x1c>
    8000490c:	37fd                	addiw	a5,a5,-1
    8000490e:	04f65e63          	bge	a2,a5,8000496a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004912:	0001d797          	auipc	a5,0x1d
    80004916:	e3e7a783          	lw	a5,-450(a5) # 80021750 <log+0x20>
    8000491a:	06f05063          	blez	a5,8000497a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000491e:	4781                	li	a5,0
    80004920:	06c05563          	blez	a2,8000498a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004924:	44cc                	lw	a1,12(s1)
    80004926:	0001d717          	auipc	a4,0x1d
    8000492a:	e3a70713          	addi	a4,a4,-454 # 80021760 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000492e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004930:	4314                	lw	a3,0(a4)
    80004932:	04b68c63          	beq	a3,a1,8000498a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004936:	2785                	addiw	a5,a5,1
    80004938:	0711                	addi	a4,a4,4
    8000493a:	fef61be3          	bne	a2,a5,80004930 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000493e:	0621                	addi	a2,a2,8
    80004940:	060a                	slli	a2,a2,0x2
    80004942:	0001d797          	auipc	a5,0x1d
    80004946:	dee78793          	addi	a5,a5,-530 # 80021730 <log>
    8000494a:	963e                	add	a2,a2,a5
    8000494c:	44dc                	lw	a5,12(s1)
    8000494e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004950:	8526                	mv	a0,s1
    80004952:	fffff097          	auipc	ra,0xfffff
    80004956:	daa080e7          	jalr	-598(ra) # 800036fc <bpin>
    log.lh.n++;
    8000495a:	0001d717          	auipc	a4,0x1d
    8000495e:	dd670713          	addi	a4,a4,-554 # 80021730 <log>
    80004962:	575c                	lw	a5,44(a4)
    80004964:	2785                	addiw	a5,a5,1
    80004966:	d75c                	sw	a5,44(a4)
    80004968:	a835                	j	800049a4 <log_write+0xca>
    panic("too big a transaction");
    8000496a:	00004517          	auipc	a0,0x4
    8000496e:	efe50513          	addi	a0,a0,-258 # 80008868 <syscalls+0x208>
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	bcc080e7          	jalr	-1076(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000497a:	00004517          	auipc	a0,0x4
    8000497e:	f0650513          	addi	a0,a0,-250 # 80008880 <syscalls+0x220>
    80004982:	ffffc097          	auipc	ra,0xffffc
    80004986:	bbc080e7          	jalr	-1092(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000498a:	00878713          	addi	a4,a5,8
    8000498e:	00271693          	slli	a3,a4,0x2
    80004992:	0001d717          	auipc	a4,0x1d
    80004996:	d9e70713          	addi	a4,a4,-610 # 80021730 <log>
    8000499a:	9736                	add	a4,a4,a3
    8000499c:	44d4                	lw	a3,12(s1)
    8000499e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800049a0:	faf608e3          	beq	a2,a5,80004950 <log_write+0x76>
  }
  release(&log.lock);
    800049a4:	0001d517          	auipc	a0,0x1d
    800049a8:	d8c50513          	addi	a0,a0,-628 # 80021730 <log>
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	2ec080e7          	jalr	748(ra) # 80000c98 <release>
}
    800049b4:	60e2                	ld	ra,24(sp)
    800049b6:	6442                	ld	s0,16(sp)
    800049b8:	64a2                	ld	s1,8(sp)
    800049ba:	6902                	ld	s2,0(sp)
    800049bc:	6105                	addi	sp,sp,32
    800049be:	8082                	ret

00000000800049c0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800049c0:	1101                	addi	sp,sp,-32
    800049c2:	ec06                	sd	ra,24(sp)
    800049c4:	e822                	sd	s0,16(sp)
    800049c6:	e426                	sd	s1,8(sp)
    800049c8:	e04a                	sd	s2,0(sp)
    800049ca:	1000                	addi	s0,sp,32
    800049cc:	84aa                	mv	s1,a0
    800049ce:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049d0:	00004597          	auipc	a1,0x4
    800049d4:	ed058593          	addi	a1,a1,-304 # 800088a0 <syscalls+0x240>
    800049d8:	0521                	addi	a0,a0,8
    800049da:	ffffc097          	auipc	ra,0xffffc
    800049de:	17a080e7          	jalr	378(ra) # 80000b54 <initlock>
  lk->name = name;
    800049e2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049e6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049ea:	0204a423          	sw	zero,40(s1)
}
    800049ee:	60e2                	ld	ra,24(sp)
    800049f0:	6442                	ld	s0,16(sp)
    800049f2:	64a2                	ld	s1,8(sp)
    800049f4:	6902                	ld	s2,0(sp)
    800049f6:	6105                	addi	sp,sp,32
    800049f8:	8082                	ret

00000000800049fa <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049fa:	1101                	addi	sp,sp,-32
    800049fc:	ec06                	sd	ra,24(sp)
    800049fe:	e822                	sd	s0,16(sp)
    80004a00:	e426                	sd	s1,8(sp)
    80004a02:	e04a                	sd	s2,0(sp)
    80004a04:	1000                	addi	s0,sp,32
    80004a06:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a08:	00850913          	addi	s2,a0,8
    80004a0c:	854a                	mv	a0,s2
    80004a0e:	ffffc097          	auipc	ra,0xffffc
    80004a12:	1d6080e7          	jalr	470(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004a16:	409c                	lw	a5,0(s1)
    80004a18:	cb89                	beqz	a5,80004a2a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a1a:	85ca                	mv	a1,s2
    80004a1c:	8526                	mv	a0,s1
    80004a1e:	ffffe097          	auipc	ra,0xffffe
    80004a22:	9bc080e7          	jalr	-1604(ra) # 800023da <sleep>
  while (lk->locked) {
    80004a26:	409c                	lw	a5,0(s1)
    80004a28:	fbed                	bnez	a5,80004a1a <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a2a:	4785                	li	a5,1
    80004a2c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a2e:	ffffd097          	auipc	ra,0xffffd
    80004a32:	25e080e7          	jalr	606(ra) # 80001c8c <myproc>
    80004a36:	591c                	lw	a5,48(a0)
    80004a38:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a3a:	854a                	mv	a0,s2
    80004a3c:	ffffc097          	auipc	ra,0xffffc
    80004a40:	25c080e7          	jalr	604(ra) # 80000c98 <release>
}
    80004a44:	60e2                	ld	ra,24(sp)
    80004a46:	6442                	ld	s0,16(sp)
    80004a48:	64a2                	ld	s1,8(sp)
    80004a4a:	6902                	ld	s2,0(sp)
    80004a4c:	6105                	addi	sp,sp,32
    80004a4e:	8082                	ret

0000000080004a50 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a50:	1101                	addi	sp,sp,-32
    80004a52:	ec06                	sd	ra,24(sp)
    80004a54:	e822                	sd	s0,16(sp)
    80004a56:	e426                	sd	s1,8(sp)
    80004a58:	e04a                	sd	s2,0(sp)
    80004a5a:	1000                	addi	s0,sp,32
    80004a5c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a5e:	00850913          	addi	s2,a0,8
    80004a62:	854a                	mv	a0,s2
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	180080e7          	jalr	384(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004a6c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a70:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a74:	8526                	mv	a0,s1
    80004a76:	ffffe097          	auipc	ra,0xffffe
    80004a7a:	f7a080e7          	jalr	-134(ra) # 800029f0 <wakeup>
  release(&lk->lk);
    80004a7e:	854a                	mv	a0,s2
    80004a80:	ffffc097          	auipc	ra,0xffffc
    80004a84:	218080e7          	jalr	536(ra) # 80000c98 <release>
}
    80004a88:	60e2                	ld	ra,24(sp)
    80004a8a:	6442                	ld	s0,16(sp)
    80004a8c:	64a2                	ld	s1,8(sp)
    80004a8e:	6902                	ld	s2,0(sp)
    80004a90:	6105                	addi	sp,sp,32
    80004a92:	8082                	ret

0000000080004a94 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a94:	7179                	addi	sp,sp,-48
    80004a96:	f406                	sd	ra,40(sp)
    80004a98:	f022                	sd	s0,32(sp)
    80004a9a:	ec26                	sd	s1,24(sp)
    80004a9c:	e84a                	sd	s2,16(sp)
    80004a9e:	e44e                	sd	s3,8(sp)
    80004aa0:	1800                	addi	s0,sp,48
    80004aa2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004aa4:	00850913          	addi	s2,a0,8
    80004aa8:	854a                	mv	a0,s2
    80004aaa:	ffffc097          	auipc	ra,0xffffc
    80004aae:	13a080e7          	jalr	314(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ab2:	409c                	lw	a5,0(s1)
    80004ab4:	ef99                	bnez	a5,80004ad2 <holdingsleep+0x3e>
    80004ab6:	4481                	li	s1,0
  release(&lk->lk);
    80004ab8:	854a                	mv	a0,s2
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	1de080e7          	jalr	478(ra) # 80000c98 <release>
  return r;
}
    80004ac2:	8526                	mv	a0,s1
    80004ac4:	70a2                	ld	ra,40(sp)
    80004ac6:	7402                	ld	s0,32(sp)
    80004ac8:	64e2                	ld	s1,24(sp)
    80004aca:	6942                	ld	s2,16(sp)
    80004acc:	69a2                	ld	s3,8(sp)
    80004ace:	6145                	addi	sp,sp,48
    80004ad0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ad2:	0284a983          	lw	s3,40(s1)
    80004ad6:	ffffd097          	auipc	ra,0xffffd
    80004ada:	1b6080e7          	jalr	438(ra) # 80001c8c <myproc>
    80004ade:	5904                	lw	s1,48(a0)
    80004ae0:	413484b3          	sub	s1,s1,s3
    80004ae4:	0014b493          	seqz	s1,s1
    80004ae8:	bfc1                	j	80004ab8 <holdingsleep+0x24>

0000000080004aea <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004aea:	1141                	addi	sp,sp,-16
    80004aec:	e406                	sd	ra,8(sp)
    80004aee:	e022                	sd	s0,0(sp)
    80004af0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004af2:	00004597          	auipc	a1,0x4
    80004af6:	dbe58593          	addi	a1,a1,-578 # 800088b0 <syscalls+0x250>
    80004afa:	0001d517          	auipc	a0,0x1d
    80004afe:	d7e50513          	addi	a0,a0,-642 # 80021878 <ftable>
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	052080e7          	jalr	82(ra) # 80000b54 <initlock>
}
    80004b0a:	60a2                	ld	ra,8(sp)
    80004b0c:	6402                	ld	s0,0(sp)
    80004b0e:	0141                	addi	sp,sp,16
    80004b10:	8082                	ret

0000000080004b12 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b12:	1101                	addi	sp,sp,-32
    80004b14:	ec06                	sd	ra,24(sp)
    80004b16:	e822                	sd	s0,16(sp)
    80004b18:	e426                	sd	s1,8(sp)
    80004b1a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b1c:	0001d517          	auipc	a0,0x1d
    80004b20:	d5c50513          	addi	a0,a0,-676 # 80021878 <ftable>
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	0c0080e7          	jalr	192(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b2c:	0001d497          	auipc	s1,0x1d
    80004b30:	d6448493          	addi	s1,s1,-668 # 80021890 <ftable+0x18>
    80004b34:	0001e717          	auipc	a4,0x1e
    80004b38:	cfc70713          	addi	a4,a4,-772 # 80022830 <ftable+0xfb8>
    if(f->ref == 0){
    80004b3c:	40dc                	lw	a5,4(s1)
    80004b3e:	cf99                	beqz	a5,80004b5c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b40:	02848493          	addi	s1,s1,40
    80004b44:	fee49ce3          	bne	s1,a4,80004b3c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b48:	0001d517          	auipc	a0,0x1d
    80004b4c:	d3050513          	addi	a0,a0,-720 # 80021878 <ftable>
    80004b50:	ffffc097          	auipc	ra,0xffffc
    80004b54:	148080e7          	jalr	328(ra) # 80000c98 <release>
  return 0;
    80004b58:	4481                	li	s1,0
    80004b5a:	a819                	j	80004b70 <filealloc+0x5e>
      f->ref = 1;
    80004b5c:	4785                	li	a5,1
    80004b5e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b60:	0001d517          	auipc	a0,0x1d
    80004b64:	d1850513          	addi	a0,a0,-744 # 80021878 <ftable>
    80004b68:	ffffc097          	auipc	ra,0xffffc
    80004b6c:	130080e7          	jalr	304(ra) # 80000c98 <release>
}
    80004b70:	8526                	mv	a0,s1
    80004b72:	60e2                	ld	ra,24(sp)
    80004b74:	6442                	ld	s0,16(sp)
    80004b76:	64a2                	ld	s1,8(sp)
    80004b78:	6105                	addi	sp,sp,32
    80004b7a:	8082                	ret

0000000080004b7c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b7c:	1101                	addi	sp,sp,-32
    80004b7e:	ec06                	sd	ra,24(sp)
    80004b80:	e822                	sd	s0,16(sp)
    80004b82:	e426                	sd	s1,8(sp)
    80004b84:	1000                	addi	s0,sp,32
    80004b86:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b88:	0001d517          	auipc	a0,0x1d
    80004b8c:	cf050513          	addi	a0,a0,-784 # 80021878 <ftable>
    80004b90:	ffffc097          	auipc	ra,0xffffc
    80004b94:	054080e7          	jalr	84(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b98:	40dc                	lw	a5,4(s1)
    80004b9a:	02f05263          	blez	a5,80004bbe <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b9e:	2785                	addiw	a5,a5,1
    80004ba0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ba2:	0001d517          	auipc	a0,0x1d
    80004ba6:	cd650513          	addi	a0,a0,-810 # 80021878 <ftable>
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	0ee080e7          	jalr	238(ra) # 80000c98 <release>
  return f;
}
    80004bb2:	8526                	mv	a0,s1
    80004bb4:	60e2                	ld	ra,24(sp)
    80004bb6:	6442                	ld	s0,16(sp)
    80004bb8:	64a2                	ld	s1,8(sp)
    80004bba:	6105                	addi	sp,sp,32
    80004bbc:	8082                	ret
    panic("filedup");
    80004bbe:	00004517          	auipc	a0,0x4
    80004bc2:	cfa50513          	addi	a0,a0,-774 # 800088b8 <syscalls+0x258>
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	978080e7          	jalr	-1672(ra) # 8000053e <panic>

0000000080004bce <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004bce:	7139                	addi	sp,sp,-64
    80004bd0:	fc06                	sd	ra,56(sp)
    80004bd2:	f822                	sd	s0,48(sp)
    80004bd4:	f426                	sd	s1,40(sp)
    80004bd6:	f04a                	sd	s2,32(sp)
    80004bd8:	ec4e                	sd	s3,24(sp)
    80004bda:	e852                	sd	s4,16(sp)
    80004bdc:	e456                	sd	s5,8(sp)
    80004bde:	0080                	addi	s0,sp,64
    80004be0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004be2:	0001d517          	auipc	a0,0x1d
    80004be6:	c9650513          	addi	a0,a0,-874 # 80021878 <ftable>
    80004bea:	ffffc097          	auipc	ra,0xffffc
    80004bee:	ffa080e7          	jalr	-6(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004bf2:	40dc                	lw	a5,4(s1)
    80004bf4:	06f05163          	blez	a5,80004c56 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004bf8:	37fd                	addiw	a5,a5,-1
    80004bfa:	0007871b          	sext.w	a4,a5
    80004bfe:	c0dc                	sw	a5,4(s1)
    80004c00:	06e04363          	bgtz	a4,80004c66 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c04:	0004a903          	lw	s2,0(s1)
    80004c08:	0094ca83          	lbu	s5,9(s1)
    80004c0c:	0104ba03          	ld	s4,16(s1)
    80004c10:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c14:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c18:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c1c:	0001d517          	auipc	a0,0x1d
    80004c20:	c5c50513          	addi	a0,a0,-932 # 80021878 <ftable>
    80004c24:	ffffc097          	auipc	ra,0xffffc
    80004c28:	074080e7          	jalr	116(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004c2c:	4785                	li	a5,1
    80004c2e:	04f90d63          	beq	s2,a5,80004c88 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c32:	3979                	addiw	s2,s2,-2
    80004c34:	4785                	li	a5,1
    80004c36:	0527e063          	bltu	a5,s2,80004c76 <fileclose+0xa8>
    begin_op();
    80004c3a:	00000097          	auipc	ra,0x0
    80004c3e:	ac8080e7          	jalr	-1336(ra) # 80004702 <begin_op>
    iput(ff.ip);
    80004c42:	854e                	mv	a0,s3
    80004c44:	fffff097          	auipc	ra,0xfffff
    80004c48:	2a6080e7          	jalr	678(ra) # 80003eea <iput>
    end_op();
    80004c4c:	00000097          	auipc	ra,0x0
    80004c50:	b36080e7          	jalr	-1226(ra) # 80004782 <end_op>
    80004c54:	a00d                	j	80004c76 <fileclose+0xa8>
    panic("fileclose");
    80004c56:	00004517          	auipc	a0,0x4
    80004c5a:	c6a50513          	addi	a0,a0,-918 # 800088c0 <syscalls+0x260>
    80004c5e:	ffffc097          	auipc	ra,0xffffc
    80004c62:	8e0080e7          	jalr	-1824(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004c66:	0001d517          	auipc	a0,0x1d
    80004c6a:	c1250513          	addi	a0,a0,-1006 # 80021878 <ftable>
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	02a080e7          	jalr	42(ra) # 80000c98 <release>
  }
}
    80004c76:	70e2                	ld	ra,56(sp)
    80004c78:	7442                	ld	s0,48(sp)
    80004c7a:	74a2                	ld	s1,40(sp)
    80004c7c:	7902                	ld	s2,32(sp)
    80004c7e:	69e2                	ld	s3,24(sp)
    80004c80:	6a42                	ld	s4,16(sp)
    80004c82:	6aa2                	ld	s5,8(sp)
    80004c84:	6121                	addi	sp,sp,64
    80004c86:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c88:	85d6                	mv	a1,s5
    80004c8a:	8552                	mv	a0,s4
    80004c8c:	00000097          	auipc	ra,0x0
    80004c90:	34c080e7          	jalr	844(ra) # 80004fd8 <pipeclose>
    80004c94:	b7cd                	j	80004c76 <fileclose+0xa8>

0000000080004c96 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c96:	715d                	addi	sp,sp,-80
    80004c98:	e486                	sd	ra,72(sp)
    80004c9a:	e0a2                	sd	s0,64(sp)
    80004c9c:	fc26                	sd	s1,56(sp)
    80004c9e:	f84a                	sd	s2,48(sp)
    80004ca0:	f44e                	sd	s3,40(sp)
    80004ca2:	0880                	addi	s0,sp,80
    80004ca4:	84aa                	mv	s1,a0
    80004ca6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ca8:	ffffd097          	auipc	ra,0xffffd
    80004cac:	fe4080e7          	jalr	-28(ra) # 80001c8c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004cb0:	409c                	lw	a5,0(s1)
    80004cb2:	37f9                	addiw	a5,a5,-2
    80004cb4:	4705                	li	a4,1
    80004cb6:	04f76763          	bltu	a4,a5,80004d04 <filestat+0x6e>
    80004cba:	892a                	mv	s2,a0
    ilock(f->ip);
    80004cbc:	6c88                	ld	a0,24(s1)
    80004cbe:	fffff097          	auipc	ra,0xfffff
    80004cc2:	072080e7          	jalr	114(ra) # 80003d30 <ilock>
    stati(f->ip, &st);
    80004cc6:	fb840593          	addi	a1,s0,-72
    80004cca:	6c88                	ld	a0,24(s1)
    80004ccc:	fffff097          	auipc	ra,0xfffff
    80004cd0:	2ee080e7          	jalr	750(ra) # 80003fba <stati>
    iunlock(f->ip);
    80004cd4:	6c88                	ld	a0,24(s1)
    80004cd6:	fffff097          	auipc	ra,0xfffff
    80004cda:	11c080e7          	jalr	284(ra) # 80003df2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cde:	46e1                	li	a3,24
    80004ce0:	fb840613          	addi	a2,s0,-72
    80004ce4:	85ce                	mv	a1,s3
    80004ce6:	05093503          	ld	a0,80(s2)
    80004cea:	ffffd097          	auipc	ra,0xffffd
    80004cee:	988080e7          	jalr	-1656(ra) # 80001672 <copyout>
    80004cf2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004cf6:	60a6                	ld	ra,72(sp)
    80004cf8:	6406                	ld	s0,64(sp)
    80004cfa:	74e2                	ld	s1,56(sp)
    80004cfc:	7942                	ld	s2,48(sp)
    80004cfe:	79a2                	ld	s3,40(sp)
    80004d00:	6161                	addi	sp,sp,80
    80004d02:	8082                	ret
  return -1;
    80004d04:	557d                	li	a0,-1
    80004d06:	bfc5                	j	80004cf6 <filestat+0x60>

0000000080004d08 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d08:	7179                	addi	sp,sp,-48
    80004d0a:	f406                	sd	ra,40(sp)
    80004d0c:	f022                	sd	s0,32(sp)
    80004d0e:	ec26                	sd	s1,24(sp)
    80004d10:	e84a                	sd	s2,16(sp)
    80004d12:	e44e                	sd	s3,8(sp)
    80004d14:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d16:	00854783          	lbu	a5,8(a0)
    80004d1a:	c3d5                	beqz	a5,80004dbe <fileread+0xb6>
    80004d1c:	84aa                	mv	s1,a0
    80004d1e:	89ae                	mv	s3,a1
    80004d20:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d22:	411c                	lw	a5,0(a0)
    80004d24:	4705                	li	a4,1
    80004d26:	04e78963          	beq	a5,a4,80004d78 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d2a:	470d                	li	a4,3
    80004d2c:	04e78d63          	beq	a5,a4,80004d86 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d30:	4709                	li	a4,2
    80004d32:	06e79e63          	bne	a5,a4,80004dae <fileread+0xa6>
    ilock(f->ip);
    80004d36:	6d08                	ld	a0,24(a0)
    80004d38:	fffff097          	auipc	ra,0xfffff
    80004d3c:	ff8080e7          	jalr	-8(ra) # 80003d30 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d40:	874a                	mv	a4,s2
    80004d42:	5094                	lw	a3,32(s1)
    80004d44:	864e                	mv	a2,s3
    80004d46:	4585                	li	a1,1
    80004d48:	6c88                	ld	a0,24(s1)
    80004d4a:	fffff097          	auipc	ra,0xfffff
    80004d4e:	29a080e7          	jalr	666(ra) # 80003fe4 <readi>
    80004d52:	892a                	mv	s2,a0
    80004d54:	00a05563          	blez	a0,80004d5e <fileread+0x56>
      f->off += r;
    80004d58:	509c                	lw	a5,32(s1)
    80004d5a:	9fa9                	addw	a5,a5,a0
    80004d5c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d5e:	6c88                	ld	a0,24(s1)
    80004d60:	fffff097          	auipc	ra,0xfffff
    80004d64:	092080e7          	jalr	146(ra) # 80003df2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d68:	854a                	mv	a0,s2
    80004d6a:	70a2                	ld	ra,40(sp)
    80004d6c:	7402                	ld	s0,32(sp)
    80004d6e:	64e2                	ld	s1,24(sp)
    80004d70:	6942                	ld	s2,16(sp)
    80004d72:	69a2                	ld	s3,8(sp)
    80004d74:	6145                	addi	sp,sp,48
    80004d76:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d78:	6908                	ld	a0,16(a0)
    80004d7a:	00000097          	auipc	ra,0x0
    80004d7e:	3c8080e7          	jalr	968(ra) # 80005142 <piperead>
    80004d82:	892a                	mv	s2,a0
    80004d84:	b7d5                	j	80004d68 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d86:	02451783          	lh	a5,36(a0)
    80004d8a:	03079693          	slli	a3,a5,0x30
    80004d8e:	92c1                	srli	a3,a3,0x30
    80004d90:	4725                	li	a4,9
    80004d92:	02d76863          	bltu	a4,a3,80004dc2 <fileread+0xba>
    80004d96:	0792                	slli	a5,a5,0x4
    80004d98:	0001d717          	auipc	a4,0x1d
    80004d9c:	a4070713          	addi	a4,a4,-1472 # 800217d8 <devsw>
    80004da0:	97ba                	add	a5,a5,a4
    80004da2:	639c                	ld	a5,0(a5)
    80004da4:	c38d                	beqz	a5,80004dc6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004da6:	4505                	li	a0,1
    80004da8:	9782                	jalr	a5
    80004daa:	892a                	mv	s2,a0
    80004dac:	bf75                	j	80004d68 <fileread+0x60>
    panic("fileread");
    80004dae:	00004517          	auipc	a0,0x4
    80004db2:	b2250513          	addi	a0,a0,-1246 # 800088d0 <syscalls+0x270>
    80004db6:	ffffb097          	auipc	ra,0xffffb
    80004dba:	788080e7          	jalr	1928(ra) # 8000053e <panic>
    return -1;
    80004dbe:	597d                	li	s2,-1
    80004dc0:	b765                	j	80004d68 <fileread+0x60>
      return -1;
    80004dc2:	597d                	li	s2,-1
    80004dc4:	b755                	j	80004d68 <fileread+0x60>
    80004dc6:	597d                	li	s2,-1
    80004dc8:	b745                	j	80004d68 <fileread+0x60>

0000000080004dca <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004dca:	715d                	addi	sp,sp,-80
    80004dcc:	e486                	sd	ra,72(sp)
    80004dce:	e0a2                	sd	s0,64(sp)
    80004dd0:	fc26                	sd	s1,56(sp)
    80004dd2:	f84a                	sd	s2,48(sp)
    80004dd4:	f44e                	sd	s3,40(sp)
    80004dd6:	f052                	sd	s4,32(sp)
    80004dd8:	ec56                	sd	s5,24(sp)
    80004dda:	e85a                	sd	s6,16(sp)
    80004ddc:	e45e                	sd	s7,8(sp)
    80004dde:	e062                	sd	s8,0(sp)
    80004de0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004de2:	00954783          	lbu	a5,9(a0)
    80004de6:	10078663          	beqz	a5,80004ef2 <filewrite+0x128>
    80004dea:	892a                	mv	s2,a0
    80004dec:	8aae                	mv	s5,a1
    80004dee:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004df0:	411c                	lw	a5,0(a0)
    80004df2:	4705                	li	a4,1
    80004df4:	02e78263          	beq	a5,a4,80004e18 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004df8:	470d                	li	a4,3
    80004dfa:	02e78663          	beq	a5,a4,80004e26 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dfe:	4709                	li	a4,2
    80004e00:	0ee79163          	bne	a5,a4,80004ee2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e04:	0ac05d63          	blez	a2,80004ebe <filewrite+0xf4>
    int i = 0;
    80004e08:	4981                	li	s3,0
    80004e0a:	6b05                	lui	s6,0x1
    80004e0c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004e10:	6b85                	lui	s7,0x1
    80004e12:	c00b8b9b          	addiw	s7,s7,-1024
    80004e16:	a861                	j	80004eae <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004e18:	6908                	ld	a0,16(a0)
    80004e1a:	00000097          	auipc	ra,0x0
    80004e1e:	22e080e7          	jalr	558(ra) # 80005048 <pipewrite>
    80004e22:	8a2a                	mv	s4,a0
    80004e24:	a045                	j	80004ec4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e26:	02451783          	lh	a5,36(a0)
    80004e2a:	03079693          	slli	a3,a5,0x30
    80004e2e:	92c1                	srli	a3,a3,0x30
    80004e30:	4725                	li	a4,9
    80004e32:	0cd76263          	bltu	a4,a3,80004ef6 <filewrite+0x12c>
    80004e36:	0792                	slli	a5,a5,0x4
    80004e38:	0001d717          	auipc	a4,0x1d
    80004e3c:	9a070713          	addi	a4,a4,-1632 # 800217d8 <devsw>
    80004e40:	97ba                	add	a5,a5,a4
    80004e42:	679c                	ld	a5,8(a5)
    80004e44:	cbdd                	beqz	a5,80004efa <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e46:	4505                	li	a0,1
    80004e48:	9782                	jalr	a5
    80004e4a:	8a2a                	mv	s4,a0
    80004e4c:	a8a5                	j	80004ec4 <filewrite+0xfa>
    80004e4e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e52:	00000097          	auipc	ra,0x0
    80004e56:	8b0080e7          	jalr	-1872(ra) # 80004702 <begin_op>
      ilock(f->ip);
    80004e5a:	01893503          	ld	a0,24(s2)
    80004e5e:	fffff097          	auipc	ra,0xfffff
    80004e62:	ed2080e7          	jalr	-302(ra) # 80003d30 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e66:	8762                	mv	a4,s8
    80004e68:	02092683          	lw	a3,32(s2)
    80004e6c:	01598633          	add	a2,s3,s5
    80004e70:	4585                	li	a1,1
    80004e72:	01893503          	ld	a0,24(s2)
    80004e76:	fffff097          	auipc	ra,0xfffff
    80004e7a:	266080e7          	jalr	614(ra) # 800040dc <writei>
    80004e7e:	84aa                	mv	s1,a0
    80004e80:	00a05763          	blez	a0,80004e8e <filewrite+0xc4>
        f->off += r;
    80004e84:	02092783          	lw	a5,32(s2)
    80004e88:	9fa9                	addw	a5,a5,a0
    80004e8a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e8e:	01893503          	ld	a0,24(s2)
    80004e92:	fffff097          	auipc	ra,0xfffff
    80004e96:	f60080e7          	jalr	-160(ra) # 80003df2 <iunlock>
      end_op();
    80004e9a:	00000097          	auipc	ra,0x0
    80004e9e:	8e8080e7          	jalr	-1816(ra) # 80004782 <end_op>

      if(r != n1){
    80004ea2:	009c1f63          	bne	s8,s1,80004ec0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ea6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004eaa:	0149db63          	bge	s3,s4,80004ec0 <filewrite+0xf6>
      int n1 = n - i;
    80004eae:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004eb2:	84be                	mv	s1,a5
    80004eb4:	2781                	sext.w	a5,a5
    80004eb6:	f8fb5ce3          	bge	s6,a5,80004e4e <filewrite+0x84>
    80004eba:	84de                	mv	s1,s7
    80004ebc:	bf49                	j	80004e4e <filewrite+0x84>
    int i = 0;
    80004ebe:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ec0:	013a1f63          	bne	s4,s3,80004ede <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ec4:	8552                	mv	a0,s4
    80004ec6:	60a6                	ld	ra,72(sp)
    80004ec8:	6406                	ld	s0,64(sp)
    80004eca:	74e2                	ld	s1,56(sp)
    80004ecc:	7942                	ld	s2,48(sp)
    80004ece:	79a2                	ld	s3,40(sp)
    80004ed0:	7a02                	ld	s4,32(sp)
    80004ed2:	6ae2                	ld	s5,24(sp)
    80004ed4:	6b42                	ld	s6,16(sp)
    80004ed6:	6ba2                	ld	s7,8(sp)
    80004ed8:	6c02                	ld	s8,0(sp)
    80004eda:	6161                	addi	sp,sp,80
    80004edc:	8082                	ret
    ret = (i == n ? n : -1);
    80004ede:	5a7d                	li	s4,-1
    80004ee0:	b7d5                	j	80004ec4 <filewrite+0xfa>
    panic("filewrite");
    80004ee2:	00004517          	auipc	a0,0x4
    80004ee6:	9fe50513          	addi	a0,a0,-1538 # 800088e0 <syscalls+0x280>
    80004eea:	ffffb097          	auipc	ra,0xffffb
    80004eee:	654080e7          	jalr	1620(ra) # 8000053e <panic>
    return -1;
    80004ef2:	5a7d                	li	s4,-1
    80004ef4:	bfc1                	j	80004ec4 <filewrite+0xfa>
      return -1;
    80004ef6:	5a7d                	li	s4,-1
    80004ef8:	b7f1                	j	80004ec4 <filewrite+0xfa>
    80004efa:	5a7d                	li	s4,-1
    80004efc:	b7e1                	j	80004ec4 <filewrite+0xfa>

0000000080004efe <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004efe:	7179                	addi	sp,sp,-48
    80004f00:	f406                	sd	ra,40(sp)
    80004f02:	f022                	sd	s0,32(sp)
    80004f04:	ec26                	sd	s1,24(sp)
    80004f06:	e84a                	sd	s2,16(sp)
    80004f08:	e44e                	sd	s3,8(sp)
    80004f0a:	e052                	sd	s4,0(sp)
    80004f0c:	1800                	addi	s0,sp,48
    80004f0e:	84aa                	mv	s1,a0
    80004f10:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f12:	0005b023          	sd	zero,0(a1)
    80004f16:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f1a:	00000097          	auipc	ra,0x0
    80004f1e:	bf8080e7          	jalr	-1032(ra) # 80004b12 <filealloc>
    80004f22:	e088                	sd	a0,0(s1)
    80004f24:	c551                	beqz	a0,80004fb0 <pipealloc+0xb2>
    80004f26:	00000097          	auipc	ra,0x0
    80004f2a:	bec080e7          	jalr	-1044(ra) # 80004b12 <filealloc>
    80004f2e:	00aa3023          	sd	a0,0(s4)
    80004f32:	c92d                	beqz	a0,80004fa4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f34:	ffffc097          	auipc	ra,0xffffc
    80004f38:	bc0080e7          	jalr	-1088(ra) # 80000af4 <kalloc>
    80004f3c:	892a                	mv	s2,a0
    80004f3e:	c125                	beqz	a0,80004f9e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f40:	4985                	li	s3,1
    80004f42:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f46:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f4a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f4e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f52:	00004597          	auipc	a1,0x4
    80004f56:	99e58593          	addi	a1,a1,-1634 # 800088f0 <syscalls+0x290>
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	bfa080e7          	jalr	-1030(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004f62:	609c                	ld	a5,0(s1)
    80004f64:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f68:	609c                	ld	a5,0(s1)
    80004f6a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f6e:	609c                	ld	a5,0(s1)
    80004f70:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f74:	609c                	ld	a5,0(s1)
    80004f76:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f7a:	000a3783          	ld	a5,0(s4)
    80004f7e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f82:	000a3783          	ld	a5,0(s4)
    80004f86:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f8a:	000a3783          	ld	a5,0(s4)
    80004f8e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f92:	000a3783          	ld	a5,0(s4)
    80004f96:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f9a:	4501                	li	a0,0
    80004f9c:	a025                	j	80004fc4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f9e:	6088                	ld	a0,0(s1)
    80004fa0:	e501                	bnez	a0,80004fa8 <pipealloc+0xaa>
    80004fa2:	a039                	j	80004fb0 <pipealloc+0xb2>
    80004fa4:	6088                	ld	a0,0(s1)
    80004fa6:	c51d                	beqz	a0,80004fd4 <pipealloc+0xd6>
    fileclose(*f0);
    80004fa8:	00000097          	auipc	ra,0x0
    80004fac:	c26080e7          	jalr	-986(ra) # 80004bce <fileclose>
  if(*f1)
    80004fb0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004fb4:	557d                	li	a0,-1
  if(*f1)
    80004fb6:	c799                	beqz	a5,80004fc4 <pipealloc+0xc6>
    fileclose(*f1);
    80004fb8:	853e                	mv	a0,a5
    80004fba:	00000097          	auipc	ra,0x0
    80004fbe:	c14080e7          	jalr	-1004(ra) # 80004bce <fileclose>
  return -1;
    80004fc2:	557d                	li	a0,-1
}
    80004fc4:	70a2                	ld	ra,40(sp)
    80004fc6:	7402                	ld	s0,32(sp)
    80004fc8:	64e2                	ld	s1,24(sp)
    80004fca:	6942                	ld	s2,16(sp)
    80004fcc:	69a2                	ld	s3,8(sp)
    80004fce:	6a02                	ld	s4,0(sp)
    80004fd0:	6145                	addi	sp,sp,48
    80004fd2:	8082                	ret
  return -1;
    80004fd4:	557d                	li	a0,-1
    80004fd6:	b7fd                	j	80004fc4 <pipealloc+0xc6>

0000000080004fd8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fd8:	1101                	addi	sp,sp,-32
    80004fda:	ec06                	sd	ra,24(sp)
    80004fdc:	e822                	sd	s0,16(sp)
    80004fde:	e426                	sd	s1,8(sp)
    80004fe0:	e04a                	sd	s2,0(sp)
    80004fe2:	1000                	addi	s0,sp,32
    80004fe4:	84aa                	mv	s1,a0
    80004fe6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004fe8:	ffffc097          	auipc	ra,0xffffc
    80004fec:	bfc080e7          	jalr	-1028(ra) # 80000be4 <acquire>
  if(writable){
    80004ff0:	02090d63          	beqz	s2,8000502a <pipeclose+0x52>
    pi->writeopen = 0;
    80004ff4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ff8:	21848513          	addi	a0,s1,536
    80004ffc:	ffffe097          	auipc	ra,0xffffe
    80005000:	9f4080e7          	jalr	-1548(ra) # 800029f0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005004:	2204b783          	ld	a5,544(s1)
    80005008:	eb95                	bnez	a5,8000503c <pipeclose+0x64>
    release(&pi->lock);
    8000500a:	8526                	mv	a0,s1
    8000500c:	ffffc097          	auipc	ra,0xffffc
    80005010:	c8c080e7          	jalr	-884(ra) # 80000c98 <release>
    kfree((char*)pi);
    80005014:	8526                	mv	a0,s1
    80005016:	ffffc097          	auipc	ra,0xffffc
    8000501a:	9e2080e7          	jalr	-1566(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    8000501e:	60e2                	ld	ra,24(sp)
    80005020:	6442                	ld	s0,16(sp)
    80005022:	64a2                	ld	s1,8(sp)
    80005024:	6902                	ld	s2,0(sp)
    80005026:	6105                	addi	sp,sp,32
    80005028:	8082                	ret
    pi->readopen = 0;
    8000502a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000502e:	21c48513          	addi	a0,s1,540
    80005032:	ffffe097          	auipc	ra,0xffffe
    80005036:	9be080e7          	jalr	-1602(ra) # 800029f0 <wakeup>
    8000503a:	b7e9                	j	80005004 <pipeclose+0x2c>
    release(&pi->lock);
    8000503c:	8526                	mv	a0,s1
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	c5a080e7          	jalr	-934(ra) # 80000c98 <release>
}
    80005046:	bfe1                	j	8000501e <pipeclose+0x46>

0000000080005048 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005048:	7159                	addi	sp,sp,-112
    8000504a:	f486                	sd	ra,104(sp)
    8000504c:	f0a2                	sd	s0,96(sp)
    8000504e:	eca6                	sd	s1,88(sp)
    80005050:	e8ca                	sd	s2,80(sp)
    80005052:	e4ce                	sd	s3,72(sp)
    80005054:	e0d2                	sd	s4,64(sp)
    80005056:	fc56                	sd	s5,56(sp)
    80005058:	f85a                	sd	s6,48(sp)
    8000505a:	f45e                	sd	s7,40(sp)
    8000505c:	f062                	sd	s8,32(sp)
    8000505e:	ec66                	sd	s9,24(sp)
    80005060:	1880                	addi	s0,sp,112
    80005062:	84aa                	mv	s1,a0
    80005064:	8aae                	mv	s5,a1
    80005066:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005068:	ffffd097          	auipc	ra,0xffffd
    8000506c:	c24080e7          	jalr	-988(ra) # 80001c8c <myproc>
    80005070:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005072:	8526                	mv	a0,s1
    80005074:	ffffc097          	auipc	ra,0xffffc
    80005078:	b70080e7          	jalr	-1168(ra) # 80000be4 <acquire>
  while(i < n){
    8000507c:	0d405163          	blez	s4,8000513e <pipewrite+0xf6>
    80005080:	8ba6                	mv	s7,s1
  int i = 0;
    80005082:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005084:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005086:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000508a:	21c48c13          	addi	s8,s1,540
    8000508e:	a08d                	j	800050f0 <pipewrite+0xa8>
      release(&pi->lock);
    80005090:	8526                	mv	a0,s1
    80005092:	ffffc097          	auipc	ra,0xffffc
    80005096:	c06080e7          	jalr	-1018(ra) # 80000c98 <release>
      return -1;
    8000509a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000509c:	854a                	mv	a0,s2
    8000509e:	70a6                	ld	ra,104(sp)
    800050a0:	7406                	ld	s0,96(sp)
    800050a2:	64e6                	ld	s1,88(sp)
    800050a4:	6946                	ld	s2,80(sp)
    800050a6:	69a6                	ld	s3,72(sp)
    800050a8:	6a06                	ld	s4,64(sp)
    800050aa:	7ae2                	ld	s5,56(sp)
    800050ac:	7b42                	ld	s6,48(sp)
    800050ae:	7ba2                	ld	s7,40(sp)
    800050b0:	7c02                	ld	s8,32(sp)
    800050b2:	6ce2                	ld	s9,24(sp)
    800050b4:	6165                	addi	sp,sp,112
    800050b6:	8082                	ret
      wakeup(&pi->nread);
    800050b8:	8566                	mv	a0,s9
    800050ba:	ffffe097          	auipc	ra,0xffffe
    800050be:	936080e7          	jalr	-1738(ra) # 800029f0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800050c2:	85de                	mv	a1,s7
    800050c4:	8562                	mv	a0,s8
    800050c6:	ffffd097          	auipc	ra,0xffffd
    800050ca:	314080e7          	jalr	788(ra) # 800023da <sleep>
    800050ce:	a839                	j	800050ec <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050d0:	21c4a783          	lw	a5,540(s1)
    800050d4:	0017871b          	addiw	a4,a5,1
    800050d8:	20e4ae23          	sw	a4,540(s1)
    800050dc:	1ff7f793          	andi	a5,a5,511
    800050e0:	97a6                	add	a5,a5,s1
    800050e2:	f9f44703          	lbu	a4,-97(s0)
    800050e6:	00e78c23          	sb	a4,24(a5)
      i++;
    800050ea:	2905                	addiw	s2,s2,1
  while(i < n){
    800050ec:	03495d63          	bge	s2,s4,80005126 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800050f0:	2204a783          	lw	a5,544(s1)
    800050f4:	dfd1                	beqz	a5,80005090 <pipewrite+0x48>
    800050f6:	0289a783          	lw	a5,40(s3)
    800050fa:	fbd9                	bnez	a5,80005090 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050fc:	2184a783          	lw	a5,536(s1)
    80005100:	21c4a703          	lw	a4,540(s1)
    80005104:	2007879b          	addiw	a5,a5,512
    80005108:	faf708e3          	beq	a4,a5,800050b8 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000510c:	4685                	li	a3,1
    8000510e:	01590633          	add	a2,s2,s5
    80005112:	f9f40593          	addi	a1,s0,-97
    80005116:	0509b503          	ld	a0,80(s3)
    8000511a:	ffffc097          	auipc	ra,0xffffc
    8000511e:	5e4080e7          	jalr	1508(ra) # 800016fe <copyin>
    80005122:	fb6517e3          	bne	a0,s6,800050d0 <pipewrite+0x88>
  wakeup(&pi->nread);
    80005126:	21848513          	addi	a0,s1,536
    8000512a:	ffffe097          	auipc	ra,0xffffe
    8000512e:	8c6080e7          	jalr	-1850(ra) # 800029f0 <wakeup>
  release(&pi->lock);
    80005132:	8526                	mv	a0,s1
    80005134:	ffffc097          	auipc	ra,0xffffc
    80005138:	b64080e7          	jalr	-1180(ra) # 80000c98 <release>
  return i;
    8000513c:	b785                	j	8000509c <pipewrite+0x54>
  int i = 0;
    8000513e:	4901                	li	s2,0
    80005140:	b7dd                	j	80005126 <pipewrite+0xde>

0000000080005142 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005142:	715d                	addi	sp,sp,-80
    80005144:	e486                	sd	ra,72(sp)
    80005146:	e0a2                	sd	s0,64(sp)
    80005148:	fc26                	sd	s1,56(sp)
    8000514a:	f84a                	sd	s2,48(sp)
    8000514c:	f44e                	sd	s3,40(sp)
    8000514e:	f052                	sd	s4,32(sp)
    80005150:	ec56                	sd	s5,24(sp)
    80005152:	e85a                	sd	s6,16(sp)
    80005154:	0880                	addi	s0,sp,80
    80005156:	84aa                	mv	s1,a0
    80005158:	892e                	mv	s2,a1
    8000515a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000515c:	ffffd097          	auipc	ra,0xffffd
    80005160:	b30080e7          	jalr	-1232(ra) # 80001c8c <myproc>
    80005164:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005166:	8b26                	mv	s6,s1
    80005168:	8526                	mv	a0,s1
    8000516a:	ffffc097          	auipc	ra,0xffffc
    8000516e:	a7a080e7          	jalr	-1414(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005172:	2184a703          	lw	a4,536(s1)
    80005176:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000517a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000517e:	02f71463          	bne	a4,a5,800051a6 <piperead+0x64>
    80005182:	2244a783          	lw	a5,548(s1)
    80005186:	c385                	beqz	a5,800051a6 <piperead+0x64>
    if(pr->killed){
    80005188:	028a2783          	lw	a5,40(s4)
    8000518c:	ebc1                	bnez	a5,8000521c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000518e:	85da                	mv	a1,s6
    80005190:	854e                	mv	a0,s3
    80005192:	ffffd097          	auipc	ra,0xffffd
    80005196:	248080e7          	jalr	584(ra) # 800023da <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000519a:	2184a703          	lw	a4,536(s1)
    8000519e:	21c4a783          	lw	a5,540(s1)
    800051a2:	fef700e3          	beq	a4,a5,80005182 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051a6:	09505263          	blez	s5,8000522a <piperead+0xe8>
    800051aa:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051ac:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800051ae:	2184a783          	lw	a5,536(s1)
    800051b2:	21c4a703          	lw	a4,540(s1)
    800051b6:	02f70d63          	beq	a4,a5,800051f0 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800051ba:	0017871b          	addiw	a4,a5,1
    800051be:	20e4ac23          	sw	a4,536(s1)
    800051c2:	1ff7f793          	andi	a5,a5,511
    800051c6:	97a6                	add	a5,a5,s1
    800051c8:	0187c783          	lbu	a5,24(a5)
    800051cc:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051d0:	4685                	li	a3,1
    800051d2:	fbf40613          	addi	a2,s0,-65
    800051d6:	85ca                	mv	a1,s2
    800051d8:	050a3503          	ld	a0,80(s4)
    800051dc:	ffffc097          	auipc	ra,0xffffc
    800051e0:	496080e7          	jalr	1174(ra) # 80001672 <copyout>
    800051e4:	01650663          	beq	a0,s6,800051f0 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051e8:	2985                	addiw	s3,s3,1
    800051ea:	0905                	addi	s2,s2,1
    800051ec:	fd3a91e3          	bne	s5,s3,800051ae <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051f0:	21c48513          	addi	a0,s1,540
    800051f4:	ffffd097          	auipc	ra,0xffffd
    800051f8:	7fc080e7          	jalr	2044(ra) # 800029f0 <wakeup>
  release(&pi->lock);
    800051fc:	8526                	mv	a0,s1
    800051fe:	ffffc097          	auipc	ra,0xffffc
    80005202:	a9a080e7          	jalr	-1382(ra) # 80000c98 <release>
  return i;
}
    80005206:	854e                	mv	a0,s3
    80005208:	60a6                	ld	ra,72(sp)
    8000520a:	6406                	ld	s0,64(sp)
    8000520c:	74e2                	ld	s1,56(sp)
    8000520e:	7942                	ld	s2,48(sp)
    80005210:	79a2                	ld	s3,40(sp)
    80005212:	7a02                	ld	s4,32(sp)
    80005214:	6ae2                	ld	s5,24(sp)
    80005216:	6b42                	ld	s6,16(sp)
    80005218:	6161                	addi	sp,sp,80
    8000521a:	8082                	ret
      release(&pi->lock);
    8000521c:	8526                	mv	a0,s1
    8000521e:	ffffc097          	auipc	ra,0xffffc
    80005222:	a7a080e7          	jalr	-1414(ra) # 80000c98 <release>
      return -1;
    80005226:	59fd                	li	s3,-1
    80005228:	bff9                	j	80005206 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000522a:	4981                	li	s3,0
    8000522c:	b7d1                	j	800051f0 <piperead+0xae>

000000008000522e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000522e:	df010113          	addi	sp,sp,-528
    80005232:	20113423          	sd	ra,520(sp)
    80005236:	20813023          	sd	s0,512(sp)
    8000523a:	ffa6                	sd	s1,504(sp)
    8000523c:	fbca                	sd	s2,496(sp)
    8000523e:	f7ce                	sd	s3,488(sp)
    80005240:	f3d2                	sd	s4,480(sp)
    80005242:	efd6                	sd	s5,472(sp)
    80005244:	ebda                	sd	s6,464(sp)
    80005246:	e7de                	sd	s7,456(sp)
    80005248:	e3e2                	sd	s8,448(sp)
    8000524a:	ff66                	sd	s9,440(sp)
    8000524c:	fb6a                	sd	s10,432(sp)
    8000524e:	f76e                	sd	s11,424(sp)
    80005250:	0c00                	addi	s0,sp,528
    80005252:	84aa                	mv	s1,a0
    80005254:	dea43c23          	sd	a0,-520(s0)
    80005258:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000525c:	ffffd097          	auipc	ra,0xffffd
    80005260:	a30080e7          	jalr	-1488(ra) # 80001c8c <myproc>
    80005264:	892a                	mv	s2,a0

  begin_op();
    80005266:	fffff097          	auipc	ra,0xfffff
    8000526a:	49c080e7          	jalr	1180(ra) # 80004702 <begin_op>

  if((ip = namei(path)) == 0){
    8000526e:	8526                	mv	a0,s1
    80005270:	fffff097          	auipc	ra,0xfffff
    80005274:	276080e7          	jalr	630(ra) # 800044e6 <namei>
    80005278:	c92d                	beqz	a0,800052ea <exec+0xbc>
    8000527a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000527c:	fffff097          	auipc	ra,0xfffff
    80005280:	ab4080e7          	jalr	-1356(ra) # 80003d30 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005284:	04000713          	li	a4,64
    80005288:	4681                	li	a3,0
    8000528a:	e5040613          	addi	a2,s0,-432
    8000528e:	4581                	li	a1,0
    80005290:	8526                	mv	a0,s1
    80005292:	fffff097          	auipc	ra,0xfffff
    80005296:	d52080e7          	jalr	-686(ra) # 80003fe4 <readi>
    8000529a:	04000793          	li	a5,64
    8000529e:	00f51a63          	bne	a0,a5,800052b2 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800052a2:	e5042703          	lw	a4,-432(s0)
    800052a6:	464c47b7          	lui	a5,0x464c4
    800052aa:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800052ae:	04f70463          	beq	a4,a5,800052f6 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800052b2:	8526                	mv	a0,s1
    800052b4:	fffff097          	auipc	ra,0xfffff
    800052b8:	cde080e7          	jalr	-802(ra) # 80003f92 <iunlockput>
    end_op();
    800052bc:	fffff097          	auipc	ra,0xfffff
    800052c0:	4c6080e7          	jalr	1222(ra) # 80004782 <end_op>
  }
  return -1;
    800052c4:	557d                	li	a0,-1
}
    800052c6:	20813083          	ld	ra,520(sp)
    800052ca:	20013403          	ld	s0,512(sp)
    800052ce:	74fe                	ld	s1,504(sp)
    800052d0:	795e                	ld	s2,496(sp)
    800052d2:	79be                	ld	s3,488(sp)
    800052d4:	7a1e                	ld	s4,480(sp)
    800052d6:	6afe                	ld	s5,472(sp)
    800052d8:	6b5e                	ld	s6,464(sp)
    800052da:	6bbe                	ld	s7,456(sp)
    800052dc:	6c1e                	ld	s8,448(sp)
    800052de:	7cfa                	ld	s9,440(sp)
    800052e0:	7d5a                	ld	s10,432(sp)
    800052e2:	7dba                	ld	s11,424(sp)
    800052e4:	21010113          	addi	sp,sp,528
    800052e8:	8082                	ret
    end_op();
    800052ea:	fffff097          	auipc	ra,0xfffff
    800052ee:	498080e7          	jalr	1176(ra) # 80004782 <end_op>
    return -1;
    800052f2:	557d                	li	a0,-1
    800052f4:	bfc9                	j	800052c6 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800052f6:	854a                	mv	a0,s2
    800052f8:	ffffd097          	auipc	ra,0xffffd
    800052fc:	a52080e7          	jalr	-1454(ra) # 80001d4a <proc_pagetable>
    80005300:	8baa                	mv	s7,a0
    80005302:	d945                	beqz	a0,800052b2 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005304:	e7042983          	lw	s3,-400(s0)
    80005308:	e8845783          	lhu	a5,-376(s0)
    8000530c:	c7ad                	beqz	a5,80005376 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000530e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005310:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005312:	6c85                	lui	s9,0x1
    80005314:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005318:	def43823          	sd	a5,-528(s0)
    8000531c:	a42d                	j	80005546 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000531e:	00003517          	auipc	a0,0x3
    80005322:	5da50513          	addi	a0,a0,1498 # 800088f8 <syscalls+0x298>
    80005326:	ffffb097          	auipc	ra,0xffffb
    8000532a:	218080e7          	jalr	536(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000532e:	8756                	mv	a4,s5
    80005330:	012d86bb          	addw	a3,s11,s2
    80005334:	4581                	li	a1,0
    80005336:	8526                	mv	a0,s1
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	cac080e7          	jalr	-852(ra) # 80003fe4 <readi>
    80005340:	2501                	sext.w	a0,a0
    80005342:	1aaa9963          	bne	s5,a0,800054f4 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005346:	6785                	lui	a5,0x1
    80005348:	0127893b          	addw	s2,a5,s2
    8000534c:	77fd                	lui	a5,0xfffff
    8000534e:	01478a3b          	addw	s4,a5,s4
    80005352:	1f897163          	bgeu	s2,s8,80005534 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005356:	02091593          	slli	a1,s2,0x20
    8000535a:	9181                	srli	a1,a1,0x20
    8000535c:	95ea                	add	a1,a1,s10
    8000535e:	855e                	mv	a0,s7
    80005360:	ffffc097          	auipc	ra,0xffffc
    80005364:	d0e080e7          	jalr	-754(ra) # 8000106e <walkaddr>
    80005368:	862a                	mv	a2,a0
    if(pa == 0)
    8000536a:	d955                	beqz	a0,8000531e <exec+0xf0>
      n = PGSIZE;
    8000536c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000536e:	fd9a70e3          	bgeu	s4,s9,8000532e <exec+0x100>
      n = sz - i;
    80005372:	8ad2                	mv	s5,s4
    80005374:	bf6d                	j	8000532e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005376:	4901                	li	s2,0
  iunlockput(ip);
    80005378:	8526                	mv	a0,s1
    8000537a:	fffff097          	auipc	ra,0xfffff
    8000537e:	c18080e7          	jalr	-1000(ra) # 80003f92 <iunlockput>
  end_op();
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	400080e7          	jalr	1024(ra) # 80004782 <end_op>
  p = myproc();
    8000538a:	ffffd097          	auipc	ra,0xffffd
    8000538e:	902080e7          	jalr	-1790(ra) # 80001c8c <myproc>
    80005392:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005394:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005398:	6785                	lui	a5,0x1
    8000539a:	17fd                	addi	a5,a5,-1
    8000539c:	993e                	add	s2,s2,a5
    8000539e:	757d                	lui	a0,0xfffff
    800053a0:	00a977b3          	and	a5,s2,a0
    800053a4:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800053a8:	6609                	lui	a2,0x2
    800053aa:	963e                	add	a2,a2,a5
    800053ac:	85be                	mv	a1,a5
    800053ae:	855e                	mv	a0,s7
    800053b0:	ffffc097          	auipc	ra,0xffffc
    800053b4:	072080e7          	jalr	114(ra) # 80001422 <uvmalloc>
    800053b8:	8b2a                	mv	s6,a0
  ip = 0;
    800053ba:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800053bc:	12050c63          	beqz	a0,800054f4 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800053c0:	75f9                	lui	a1,0xffffe
    800053c2:	95aa                	add	a1,a1,a0
    800053c4:	855e                	mv	a0,s7
    800053c6:	ffffc097          	auipc	ra,0xffffc
    800053ca:	27a080e7          	jalr	634(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800053ce:	7c7d                	lui	s8,0xfffff
    800053d0:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800053d2:	e0043783          	ld	a5,-512(s0)
    800053d6:	6388                	ld	a0,0(a5)
    800053d8:	c535                	beqz	a0,80005444 <exec+0x216>
    800053da:	e9040993          	addi	s3,s0,-368
    800053de:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800053e2:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800053e4:	ffffc097          	auipc	ra,0xffffc
    800053e8:	a80080e7          	jalr	-1408(ra) # 80000e64 <strlen>
    800053ec:	2505                	addiw	a0,a0,1
    800053ee:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053f2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800053f6:	13896363          	bltu	s2,s8,8000551c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800053fa:	e0043d83          	ld	s11,-512(s0)
    800053fe:	000dba03          	ld	s4,0(s11)
    80005402:	8552                	mv	a0,s4
    80005404:	ffffc097          	auipc	ra,0xffffc
    80005408:	a60080e7          	jalr	-1440(ra) # 80000e64 <strlen>
    8000540c:	0015069b          	addiw	a3,a0,1
    80005410:	8652                	mv	a2,s4
    80005412:	85ca                	mv	a1,s2
    80005414:	855e                	mv	a0,s7
    80005416:	ffffc097          	auipc	ra,0xffffc
    8000541a:	25c080e7          	jalr	604(ra) # 80001672 <copyout>
    8000541e:	10054363          	bltz	a0,80005524 <exec+0x2f6>
    ustack[argc] = sp;
    80005422:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005426:	0485                	addi	s1,s1,1
    80005428:	008d8793          	addi	a5,s11,8
    8000542c:	e0f43023          	sd	a5,-512(s0)
    80005430:	008db503          	ld	a0,8(s11)
    80005434:	c911                	beqz	a0,80005448 <exec+0x21a>
    if(argc >= MAXARG)
    80005436:	09a1                	addi	s3,s3,8
    80005438:	fb3c96e3          	bne	s9,s3,800053e4 <exec+0x1b6>
  sz = sz1;
    8000543c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005440:	4481                	li	s1,0
    80005442:	a84d                	j	800054f4 <exec+0x2c6>
  sp = sz;
    80005444:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005446:	4481                	li	s1,0
  ustack[argc] = 0;
    80005448:	00349793          	slli	a5,s1,0x3
    8000544c:	f9040713          	addi	a4,s0,-112
    80005450:	97ba                	add	a5,a5,a4
    80005452:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005456:	00148693          	addi	a3,s1,1
    8000545a:	068e                	slli	a3,a3,0x3
    8000545c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005460:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005464:	01897663          	bgeu	s2,s8,80005470 <exec+0x242>
  sz = sz1;
    80005468:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000546c:	4481                	li	s1,0
    8000546e:	a059                	j	800054f4 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005470:	e9040613          	addi	a2,s0,-368
    80005474:	85ca                	mv	a1,s2
    80005476:	855e                	mv	a0,s7
    80005478:	ffffc097          	auipc	ra,0xffffc
    8000547c:	1fa080e7          	jalr	506(ra) # 80001672 <copyout>
    80005480:	0a054663          	bltz	a0,8000552c <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005484:	058ab783          	ld	a5,88(s5)
    80005488:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000548c:	df843783          	ld	a5,-520(s0)
    80005490:	0007c703          	lbu	a4,0(a5)
    80005494:	cf11                	beqz	a4,800054b0 <exec+0x282>
    80005496:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005498:	02f00693          	li	a3,47
    8000549c:	a039                	j	800054aa <exec+0x27c>
      last = s+1;
    8000549e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800054a2:	0785                	addi	a5,a5,1
    800054a4:	fff7c703          	lbu	a4,-1(a5)
    800054a8:	c701                	beqz	a4,800054b0 <exec+0x282>
    if(*s == '/')
    800054aa:	fed71ce3          	bne	a4,a3,800054a2 <exec+0x274>
    800054ae:	bfc5                	j	8000549e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800054b0:	4641                	li	a2,16
    800054b2:	df843583          	ld	a1,-520(s0)
    800054b6:	158a8513          	addi	a0,s5,344
    800054ba:	ffffc097          	auipc	ra,0xffffc
    800054be:	978080e7          	jalr	-1672(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800054c2:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800054c6:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800054ca:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054ce:	058ab783          	ld	a5,88(s5)
    800054d2:	e6843703          	ld	a4,-408(s0)
    800054d6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054d8:	058ab783          	ld	a5,88(s5)
    800054dc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054e0:	85ea                	mv	a1,s10
    800054e2:	ffffd097          	auipc	ra,0xffffd
    800054e6:	904080e7          	jalr	-1788(ra) # 80001de6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054ea:	0004851b          	sext.w	a0,s1
    800054ee:	bbe1                	j	800052c6 <exec+0x98>
    800054f0:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800054f4:	e0843583          	ld	a1,-504(s0)
    800054f8:	855e                	mv	a0,s7
    800054fa:	ffffd097          	auipc	ra,0xffffd
    800054fe:	8ec080e7          	jalr	-1812(ra) # 80001de6 <proc_freepagetable>
  if(ip){
    80005502:	da0498e3          	bnez	s1,800052b2 <exec+0x84>
  return -1;
    80005506:	557d                	li	a0,-1
    80005508:	bb7d                	j	800052c6 <exec+0x98>
    8000550a:	e1243423          	sd	s2,-504(s0)
    8000550e:	b7dd                	j	800054f4 <exec+0x2c6>
    80005510:	e1243423          	sd	s2,-504(s0)
    80005514:	b7c5                	j	800054f4 <exec+0x2c6>
    80005516:	e1243423          	sd	s2,-504(s0)
    8000551a:	bfe9                	j	800054f4 <exec+0x2c6>
  sz = sz1;
    8000551c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005520:	4481                	li	s1,0
    80005522:	bfc9                	j	800054f4 <exec+0x2c6>
  sz = sz1;
    80005524:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005528:	4481                	li	s1,0
    8000552a:	b7e9                	j	800054f4 <exec+0x2c6>
  sz = sz1;
    8000552c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005530:	4481                	li	s1,0
    80005532:	b7c9                	j	800054f4 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005534:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005538:	2b05                	addiw	s6,s6,1
    8000553a:	0389899b          	addiw	s3,s3,56
    8000553e:	e8845783          	lhu	a5,-376(s0)
    80005542:	e2fb5be3          	bge	s6,a5,80005378 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005546:	2981                	sext.w	s3,s3
    80005548:	03800713          	li	a4,56
    8000554c:	86ce                	mv	a3,s3
    8000554e:	e1840613          	addi	a2,s0,-488
    80005552:	4581                	li	a1,0
    80005554:	8526                	mv	a0,s1
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	a8e080e7          	jalr	-1394(ra) # 80003fe4 <readi>
    8000555e:	03800793          	li	a5,56
    80005562:	f8f517e3          	bne	a0,a5,800054f0 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005566:	e1842783          	lw	a5,-488(s0)
    8000556a:	4705                	li	a4,1
    8000556c:	fce796e3          	bne	a5,a4,80005538 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005570:	e4043603          	ld	a2,-448(s0)
    80005574:	e3843783          	ld	a5,-456(s0)
    80005578:	f8f669e3          	bltu	a2,a5,8000550a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000557c:	e2843783          	ld	a5,-472(s0)
    80005580:	963e                	add	a2,a2,a5
    80005582:	f8f667e3          	bltu	a2,a5,80005510 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005586:	85ca                	mv	a1,s2
    80005588:	855e                	mv	a0,s7
    8000558a:	ffffc097          	auipc	ra,0xffffc
    8000558e:	e98080e7          	jalr	-360(ra) # 80001422 <uvmalloc>
    80005592:	e0a43423          	sd	a0,-504(s0)
    80005596:	d141                	beqz	a0,80005516 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005598:	e2843d03          	ld	s10,-472(s0)
    8000559c:	df043783          	ld	a5,-528(s0)
    800055a0:	00fd77b3          	and	a5,s10,a5
    800055a4:	fba1                	bnez	a5,800054f4 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800055a6:	e2042d83          	lw	s11,-480(s0)
    800055aa:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800055ae:	f80c03e3          	beqz	s8,80005534 <exec+0x306>
    800055b2:	8a62                	mv	s4,s8
    800055b4:	4901                	li	s2,0
    800055b6:	b345                	j	80005356 <exec+0x128>

00000000800055b8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800055b8:	7179                	addi	sp,sp,-48
    800055ba:	f406                	sd	ra,40(sp)
    800055bc:	f022                	sd	s0,32(sp)
    800055be:	ec26                	sd	s1,24(sp)
    800055c0:	e84a                	sd	s2,16(sp)
    800055c2:	1800                	addi	s0,sp,48
    800055c4:	892e                	mv	s2,a1
    800055c6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800055c8:	fdc40593          	addi	a1,s0,-36
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	b76080e7          	jalr	-1162(ra) # 80003142 <argint>
    800055d4:	04054063          	bltz	a0,80005614 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055d8:	fdc42703          	lw	a4,-36(s0)
    800055dc:	47bd                	li	a5,15
    800055de:	02e7ed63          	bltu	a5,a4,80005618 <argfd+0x60>
    800055e2:	ffffc097          	auipc	ra,0xffffc
    800055e6:	6aa080e7          	jalr	1706(ra) # 80001c8c <myproc>
    800055ea:	fdc42703          	lw	a4,-36(s0)
    800055ee:	01a70793          	addi	a5,a4,26
    800055f2:	078e                	slli	a5,a5,0x3
    800055f4:	953e                	add	a0,a0,a5
    800055f6:	611c                	ld	a5,0(a0)
    800055f8:	c395                	beqz	a5,8000561c <argfd+0x64>
    return -1;
  if(pfd)
    800055fa:	00090463          	beqz	s2,80005602 <argfd+0x4a>
    *pfd = fd;
    800055fe:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005602:	4501                	li	a0,0
  if(pf)
    80005604:	c091                	beqz	s1,80005608 <argfd+0x50>
    *pf = f;
    80005606:	e09c                	sd	a5,0(s1)
}
    80005608:	70a2                	ld	ra,40(sp)
    8000560a:	7402                	ld	s0,32(sp)
    8000560c:	64e2                	ld	s1,24(sp)
    8000560e:	6942                	ld	s2,16(sp)
    80005610:	6145                	addi	sp,sp,48
    80005612:	8082                	ret
    return -1;
    80005614:	557d                	li	a0,-1
    80005616:	bfcd                	j	80005608 <argfd+0x50>
    return -1;
    80005618:	557d                	li	a0,-1
    8000561a:	b7fd                	j	80005608 <argfd+0x50>
    8000561c:	557d                	li	a0,-1
    8000561e:	b7ed                	j	80005608 <argfd+0x50>

0000000080005620 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005620:	1101                	addi	sp,sp,-32
    80005622:	ec06                	sd	ra,24(sp)
    80005624:	e822                	sd	s0,16(sp)
    80005626:	e426                	sd	s1,8(sp)
    80005628:	1000                	addi	s0,sp,32
    8000562a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000562c:	ffffc097          	auipc	ra,0xffffc
    80005630:	660080e7          	jalr	1632(ra) # 80001c8c <myproc>
    80005634:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005636:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000563a:	4501                	li	a0,0
    8000563c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000563e:	6398                	ld	a4,0(a5)
    80005640:	cb19                	beqz	a4,80005656 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005642:	2505                	addiw	a0,a0,1
    80005644:	07a1                	addi	a5,a5,8
    80005646:	fed51ce3          	bne	a0,a3,8000563e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000564a:	557d                	li	a0,-1
}
    8000564c:	60e2                	ld	ra,24(sp)
    8000564e:	6442                	ld	s0,16(sp)
    80005650:	64a2                	ld	s1,8(sp)
    80005652:	6105                	addi	sp,sp,32
    80005654:	8082                	ret
      p->ofile[fd] = f;
    80005656:	01a50793          	addi	a5,a0,26
    8000565a:	078e                	slli	a5,a5,0x3
    8000565c:	963e                	add	a2,a2,a5
    8000565e:	e204                	sd	s1,0(a2)
      return fd;
    80005660:	b7f5                	j	8000564c <fdalloc+0x2c>

0000000080005662 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005662:	715d                	addi	sp,sp,-80
    80005664:	e486                	sd	ra,72(sp)
    80005666:	e0a2                	sd	s0,64(sp)
    80005668:	fc26                	sd	s1,56(sp)
    8000566a:	f84a                	sd	s2,48(sp)
    8000566c:	f44e                	sd	s3,40(sp)
    8000566e:	f052                	sd	s4,32(sp)
    80005670:	ec56                	sd	s5,24(sp)
    80005672:	0880                	addi	s0,sp,80
    80005674:	89ae                	mv	s3,a1
    80005676:	8ab2                	mv	s5,a2
    80005678:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000567a:	fb040593          	addi	a1,s0,-80
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	e86080e7          	jalr	-378(ra) # 80004504 <nameiparent>
    80005686:	892a                	mv	s2,a0
    80005688:	12050f63          	beqz	a0,800057c6 <create+0x164>
    return 0;

  ilock(dp);
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	6a4080e7          	jalr	1700(ra) # 80003d30 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005694:	4601                	li	a2,0
    80005696:	fb040593          	addi	a1,s0,-80
    8000569a:	854a                	mv	a0,s2
    8000569c:	fffff097          	auipc	ra,0xfffff
    800056a0:	b78080e7          	jalr	-1160(ra) # 80004214 <dirlookup>
    800056a4:	84aa                	mv	s1,a0
    800056a6:	c921                	beqz	a0,800056f6 <create+0x94>
    iunlockput(dp);
    800056a8:	854a                	mv	a0,s2
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	8e8080e7          	jalr	-1816(ra) # 80003f92 <iunlockput>
    ilock(ip);
    800056b2:	8526                	mv	a0,s1
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	67c080e7          	jalr	1660(ra) # 80003d30 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800056bc:	2981                	sext.w	s3,s3
    800056be:	4789                	li	a5,2
    800056c0:	02f99463          	bne	s3,a5,800056e8 <create+0x86>
    800056c4:	0444d783          	lhu	a5,68(s1)
    800056c8:	37f9                	addiw	a5,a5,-2
    800056ca:	17c2                	slli	a5,a5,0x30
    800056cc:	93c1                	srli	a5,a5,0x30
    800056ce:	4705                	li	a4,1
    800056d0:	00f76c63          	bltu	a4,a5,800056e8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800056d4:	8526                	mv	a0,s1
    800056d6:	60a6                	ld	ra,72(sp)
    800056d8:	6406                	ld	s0,64(sp)
    800056da:	74e2                	ld	s1,56(sp)
    800056dc:	7942                	ld	s2,48(sp)
    800056de:	79a2                	ld	s3,40(sp)
    800056e0:	7a02                	ld	s4,32(sp)
    800056e2:	6ae2                	ld	s5,24(sp)
    800056e4:	6161                	addi	sp,sp,80
    800056e6:	8082                	ret
    iunlockput(ip);
    800056e8:	8526                	mv	a0,s1
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	8a8080e7          	jalr	-1880(ra) # 80003f92 <iunlockput>
    return 0;
    800056f2:	4481                	li	s1,0
    800056f4:	b7c5                	j	800056d4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800056f6:	85ce                	mv	a1,s3
    800056f8:	00092503          	lw	a0,0(s2)
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	49c080e7          	jalr	1180(ra) # 80003b98 <ialloc>
    80005704:	84aa                	mv	s1,a0
    80005706:	c529                	beqz	a0,80005750 <create+0xee>
  ilock(ip);
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	628080e7          	jalr	1576(ra) # 80003d30 <ilock>
  ip->major = major;
    80005710:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005714:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005718:	4785                	li	a5,1
    8000571a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000571e:	8526                	mv	a0,s1
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	546080e7          	jalr	1350(ra) # 80003c66 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005728:	2981                	sext.w	s3,s3
    8000572a:	4785                	li	a5,1
    8000572c:	02f98a63          	beq	s3,a5,80005760 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005730:	40d0                	lw	a2,4(s1)
    80005732:	fb040593          	addi	a1,s0,-80
    80005736:	854a                	mv	a0,s2
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	cec080e7          	jalr	-788(ra) # 80004424 <dirlink>
    80005740:	06054b63          	bltz	a0,800057b6 <create+0x154>
  iunlockput(dp);
    80005744:	854a                	mv	a0,s2
    80005746:	fffff097          	auipc	ra,0xfffff
    8000574a:	84c080e7          	jalr	-1972(ra) # 80003f92 <iunlockput>
  return ip;
    8000574e:	b759                	j	800056d4 <create+0x72>
    panic("create: ialloc");
    80005750:	00003517          	auipc	a0,0x3
    80005754:	1c850513          	addi	a0,a0,456 # 80008918 <syscalls+0x2b8>
    80005758:	ffffb097          	auipc	ra,0xffffb
    8000575c:	de6080e7          	jalr	-538(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005760:	04a95783          	lhu	a5,74(s2)
    80005764:	2785                	addiw	a5,a5,1
    80005766:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000576a:	854a                	mv	a0,s2
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	4fa080e7          	jalr	1274(ra) # 80003c66 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005774:	40d0                	lw	a2,4(s1)
    80005776:	00003597          	auipc	a1,0x3
    8000577a:	1b258593          	addi	a1,a1,434 # 80008928 <syscalls+0x2c8>
    8000577e:	8526                	mv	a0,s1
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	ca4080e7          	jalr	-860(ra) # 80004424 <dirlink>
    80005788:	00054f63          	bltz	a0,800057a6 <create+0x144>
    8000578c:	00492603          	lw	a2,4(s2)
    80005790:	00003597          	auipc	a1,0x3
    80005794:	1a058593          	addi	a1,a1,416 # 80008930 <syscalls+0x2d0>
    80005798:	8526                	mv	a0,s1
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	c8a080e7          	jalr	-886(ra) # 80004424 <dirlink>
    800057a2:	f80557e3          	bgez	a0,80005730 <create+0xce>
      panic("create dots");
    800057a6:	00003517          	auipc	a0,0x3
    800057aa:	19250513          	addi	a0,a0,402 # 80008938 <syscalls+0x2d8>
    800057ae:	ffffb097          	auipc	ra,0xffffb
    800057b2:	d90080e7          	jalr	-624(ra) # 8000053e <panic>
    panic("create: dirlink");
    800057b6:	00003517          	auipc	a0,0x3
    800057ba:	19250513          	addi	a0,a0,402 # 80008948 <syscalls+0x2e8>
    800057be:	ffffb097          	auipc	ra,0xffffb
    800057c2:	d80080e7          	jalr	-640(ra) # 8000053e <panic>
    return 0;
    800057c6:	84aa                	mv	s1,a0
    800057c8:	b731                	j	800056d4 <create+0x72>

00000000800057ca <sys_dup>:
{
    800057ca:	7179                	addi	sp,sp,-48
    800057cc:	f406                	sd	ra,40(sp)
    800057ce:	f022                	sd	s0,32(sp)
    800057d0:	ec26                	sd	s1,24(sp)
    800057d2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057d4:	fd840613          	addi	a2,s0,-40
    800057d8:	4581                	li	a1,0
    800057da:	4501                	li	a0,0
    800057dc:	00000097          	auipc	ra,0x0
    800057e0:	ddc080e7          	jalr	-548(ra) # 800055b8 <argfd>
    return -1;
    800057e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800057e6:	02054363          	bltz	a0,8000580c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800057ea:	fd843503          	ld	a0,-40(s0)
    800057ee:	00000097          	auipc	ra,0x0
    800057f2:	e32080e7          	jalr	-462(ra) # 80005620 <fdalloc>
    800057f6:	84aa                	mv	s1,a0
    return -1;
    800057f8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800057fa:	00054963          	bltz	a0,8000580c <sys_dup+0x42>
  filedup(f);
    800057fe:	fd843503          	ld	a0,-40(s0)
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	37a080e7          	jalr	890(ra) # 80004b7c <filedup>
  return fd;
    8000580a:	87a6                	mv	a5,s1
}
    8000580c:	853e                	mv	a0,a5
    8000580e:	70a2                	ld	ra,40(sp)
    80005810:	7402                	ld	s0,32(sp)
    80005812:	64e2                	ld	s1,24(sp)
    80005814:	6145                	addi	sp,sp,48
    80005816:	8082                	ret

0000000080005818 <sys_read>:
{
    80005818:	7179                	addi	sp,sp,-48
    8000581a:	f406                	sd	ra,40(sp)
    8000581c:	f022                	sd	s0,32(sp)
    8000581e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005820:	fe840613          	addi	a2,s0,-24
    80005824:	4581                	li	a1,0
    80005826:	4501                	li	a0,0
    80005828:	00000097          	auipc	ra,0x0
    8000582c:	d90080e7          	jalr	-624(ra) # 800055b8 <argfd>
    return -1;
    80005830:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005832:	04054163          	bltz	a0,80005874 <sys_read+0x5c>
    80005836:	fe440593          	addi	a1,s0,-28
    8000583a:	4509                	li	a0,2
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	906080e7          	jalr	-1786(ra) # 80003142 <argint>
    return -1;
    80005844:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005846:	02054763          	bltz	a0,80005874 <sys_read+0x5c>
    8000584a:	fd840593          	addi	a1,s0,-40
    8000584e:	4505                	li	a0,1
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	914080e7          	jalr	-1772(ra) # 80003164 <argaddr>
    return -1;
    80005858:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000585a:	00054d63          	bltz	a0,80005874 <sys_read+0x5c>
  return fileread(f, p, n);
    8000585e:	fe442603          	lw	a2,-28(s0)
    80005862:	fd843583          	ld	a1,-40(s0)
    80005866:	fe843503          	ld	a0,-24(s0)
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	49e080e7          	jalr	1182(ra) # 80004d08 <fileread>
    80005872:	87aa                	mv	a5,a0
}
    80005874:	853e                	mv	a0,a5
    80005876:	70a2                	ld	ra,40(sp)
    80005878:	7402                	ld	s0,32(sp)
    8000587a:	6145                	addi	sp,sp,48
    8000587c:	8082                	ret

000000008000587e <sys_write>:
{
    8000587e:	7179                	addi	sp,sp,-48
    80005880:	f406                	sd	ra,40(sp)
    80005882:	f022                	sd	s0,32(sp)
    80005884:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005886:	fe840613          	addi	a2,s0,-24
    8000588a:	4581                	li	a1,0
    8000588c:	4501                	li	a0,0
    8000588e:	00000097          	auipc	ra,0x0
    80005892:	d2a080e7          	jalr	-726(ra) # 800055b8 <argfd>
    return -1;
    80005896:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005898:	04054163          	bltz	a0,800058da <sys_write+0x5c>
    8000589c:	fe440593          	addi	a1,s0,-28
    800058a0:	4509                	li	a0,2
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	8a0080e7          	jalr	-1888(ra) # 80003142 <argint>
    return -1;
    800058aa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058ac:	02054763          	bltz	a0,800058da <sys_write+0x5c>
    800058b0:	fd840593          	addi	a1,s0,-40
    800058b4:	4505                	li	a0,1
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	8ae080e7          	jalr	-1874(ra) # 80003164 <argaddr>
    return -1;
    800058be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058c0:	00054d63          	bltz	a0,800058da <sys_write+0x5c>
  return filewrite(f, p, n);
    800058c4:	fe442603          	lw	a2,-28(s0)
    800058c8:	fd843583          	ld	a1,-40(s0)
    800058cc:	fe843503          	ld	a0,-24(s0)
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	4fa080e7          	jalr	1274(ra) # 80004dca <filewrite>
    800058d8:	87aa                	mv	a5,a0
}
    800058da:	853e                	mv	a0,a5
    800058dc:	70a2                	ld	ra,40(sp)
    800058de:	7402                	ld	s0,32(sp)
    800058e0:	6145                	addi	sp,sp,48
    800058e2:	8082                	ret

00000000800058e4 <sys_close>:
{
    800058e4:	1101                	addi	sp,sp,-32
    800058e6:	ec06                	sd	ra,24(sp)
    800058e8:	e822                	sd	s0,16(sp)
    800058ea:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800058ec:	fe040613          	addi	a2,s0,-32
    800058f0:	fec40593          	addi	a1,s0,-20
    800058f4:	4501                	li	a0,0
    800058f6:	00000097          	auipc	ra,0x0
    800058fa:	cc2080e7          	jalr	-830(ra) # 800055b8 <argfd>
    return -1;
    800058fe:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005900:	02054463          	bltz	a0,80005928 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005904:	ffffc097          	auipc	ra,0xffffc
    80005908:	388080e7          	jalr	904(ra) # 80001c8c <myproc>
    8000590c:	fec42783          	lw	a5,-20(s0)
    80005910:	07e9                	addi	a5,a5,26
    80005912:	078e                	slli	a5,a5,0x3
    80005914:	97aa                	add	a5,a5,a0
    80005916:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000591a:	fe043503          	ld	a0,-32(s0)
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	2b0080e7          	jalr	688(ra) # 80004bce <fileclose>
  return 0;
    80005926:	4781                	li	a5,0
}
    80005928:	853e                	mv	a0,a5
    8000592a:	60e2                	ld	ra,24(sp)
    8000592c:	6442                	ld	s0,16(sp)
    8000592e:	6105                	addi	sp,sp,32
    80005930:	8082                	ret

0000000080005932 <sys_fstat>:
{
    80005932:	1101                	addi	sp,sp,-32
    80005934:	ec06                	sd	ra,24(sp)
    80005936:	e822                	sd	s0,16(sp)
    80005938:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000593a:	fe840613          	addi	a2,s0,-24
    8000593e:	4581                	li	a1,0
    80005940:	4501                	li	a0,0
    80005942:	00000097          	auipc	ra,0x0
    80005946:	c76080e7          	jalr	-906(ra) # 800055b8 <argfd>
    return -1;
    8000594a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000594c:	02054563          	bltz	a0,80005976 <sys_fstat+0x44>
    80005950:	fe040593          	addi	a1,s0,-32
    80005954:	4505                	li	a0,1
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	80e080e7          	jalr	-2034(ra) # 80003164 <argaddr>
    return -1;
    8000595e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005960:	00054b63          	bltz	a0,80005976 <sys_fstat+0x44>
  return filestat(f, st);
    80005964:	fe043583          	ld	a1,-32(s0)
    80005968:	fe843503          	ld	a0,-24(s0)
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	32a080e7          	jalr	810(ra) # 80004c96 <filestat>
    80005974:	87aa                	mv	a5,a0
}
    80005976:	853e                	mv	a0,a5
    80005978:	60e2                	ld	ra,24(sp)
    8000597a:	6442                	ld	s0,16(sp)
    8000597c:	6105                	addi	sp,sp,32
    8000597e:	8082                	ret

0000000080005980 <sys_link>:
{
    80005980:	7169                	addi	sp,sp,-304
    80005982:	f606                	sd	ra,296(sp)
    80005984:	f222                	sd	s0,288(sp)
    80005986:	ee26                	sd	s1,280(sp)
    80005988:	ea4a                	sd	s2,272(sp)
    8000598a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000598c:	08000613          	li	a2,128
    80005990:	ed040593          	addi	a1,s0,-304
    80005994:	4501                	li	a0,0
    80005996:	ffffd097          	auipc	ra,0xffffd
    8000599a:	7f0080e7          	jalr	2032(ra) # 80003186 <argstr>
    return -1;
    8000599e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059a0:	10054e63          	bltz	a0,80005abc <sys_link+0x13c>
    800059a4:	08000613          	li	a2,128
    800059a8:	f5040593          	addi	a1,s0,-176
    800059ac:	4505                	li	a0,1
    800059ae:	ffffd097          	auipc	ra,0xffffd
    800059b2:	7d8080e7          	jalr	2008(ra) # 80003186 <argstr>
    return -1;
    800059b6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059b8:	10054263          	bltz	a0,80005abc <sys_link+0x13c>
  begin_op();
    800059bc:	fffff097          	auipc	ra,0xfffff
    800059c0:	d46080e7          	jalr	-698(ra) # 80004702 <begin_op>
  if((ip = namei(old)) == 0){
    800059c4:	ed040513          	addi	a0,s0,-304
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	b1e080e7          	jalr	-1250(ra) # 800044e6 <namei>
    800059d0:	84aa                	mv	s1,a0
    800059d2:	c551                	beqz	a0,80005a5e <sys_link+0xde>
  ilock(ip);
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	35c080e7          	jalr	860(ra) # 80003d30 <ilock>
  if(ip->type == T_DIR){
    800059dc:	04449703          	lh	a4,68(s1)
    800059e0:	4785                	li	a5,1
    800059e2:	08f70463          	beq	a4,a5,80005a6a <sys_link+0xea>
  ip->nlink++;
    800059e6:	04a4d783          	lhu	a5,74(s1)
    800059ea:	2785                	addiw	a5,a5,1
    800059ec:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059f0:	8526                	mv	a0,s1
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	274080e7          	jalr	628(ra) # 80003c66 <iupdate>
  iunlock(ip);
    800059fa:	8526                	mv	a0,s1
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	3f6080e7          	jalr	1014(ra) # 80003df2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a04:	fd040593          	addi	a1,s0,-48
    80005a08:	f5040513          	addi	a0,s0,-176
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	af8080e7          	jalr	-1288(ra) # 80004504 <nameiparent>
    80005a14:	892a                	mv	s2,a0
    80005a16:	c935                	beqz	a0,80005a8a <sys_link+0x10a>
  ilock(dp);
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	318080e7          	jalr	792(ra) # 80003d30 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a20:	00092703          	lw	a4,0(s2)
    80005a24:	409c                	lw	a5,0(s1)
    80005a26:	04f71d63          	bne	a4,a5,80005a80 <sys_link+0x100>
    80005a2a:	40d0                	lw	a2,4(s1)
    80005a2c:	fd040593          	addi	a1,s0,-48
    80005a30:	854a                	mv	a0,s2
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	9f2080e7          	jalr	-1550(ra) # 80004424 <dirlink>
    80005a3a:	04054363          	bltz	a0,80005a80 <sys_link+0x100>
  iunlockput(dp);
    80005a3e:	854a                	mv	a0,s2
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	552080e7          	jalr	1362(ra) # 80003f92 <iunlockput>
  iput(ip);
    80005a48:	8526                	mv	a0,s1
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	4a0080e7          	jalr	1184(ra) # 80003eea <iput>
  end_op();
    80005a52:	fffff097          	auipc	ra,0xfffff
    80005a56:	d30080e7          	jalr	-720(ra) # 80004782 <end_op>
  return 0;
    80005a5a:	4781                	li	a5,0
    80005a5c:	a085                	j	80005abc <sys_link+0x13c>
    end_op();
    80005a5e:	fffff097          	auipc	ra,0xfffff
    80005a62:	d24080e7          	jalr	-732(ra) # 80004782 <end_op>
    return -1;
    80005a66:	57fd                	li	a5,-1
    80005a68:	a891                	j	80005abc <sys_link+0x13c>
    iunlockput(ip);
    80005a6a:	8526                	mv	a0,s1
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	526080e7          	jalr	1318(ra) # 80003f92 <iunlockput>
    end_op();
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	d0e080e7          	jalr	-754(ra) # 80004782 <end_op>
    return -1;
    80005a7c:	57fd                	li	a5,-1
    80005a7e:	a83d                	j	80005abc <sys_link+0x13c>
    iunlockput(dp);
    80005a80:	854a                	mv	a0,s2
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	510080e7          	jalr	1296(ra) # 80003f92 <iunlockput>
  ilock(ip);
    80005a8a:	8526                	mv	a0,s1
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	2a4080e7          	jalr	676(ra) # 80003d30 <ilock>
  ip->nlink--;
    80005a94:	04a4d783          	lhu	a5,74(s1)
    80005a98:	37fd                	addiw	a5,a5,-1
    80005a9a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a9e:	8526                	mv	a0,s1
    80005aa0:	ffffe097          	auipc	ra,0xffffe
    80005aa4:	1c6080e7          	jalr	454(ra) # 80003c66 <iupdate>
  iunlockput(ip);
    80005aa8:	8526                	mv	a0,s1
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	4e8080e7          	jalr	1256(ra) # 80003f92 <iunlockput>
  end_op();
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	cd0080e7          	jalr	-816(ra) # 80004782 <end_op>
  return -1;
    80005aba:	57fd                	li	a5,-1
}
    80005abc:	853e                	mv	a0,a5
    80005abe:	70b2                	ld	ra,296(sp)
    80005ac0:	7412                	ld	s0,288(sp)
    80005ac2:	64f2                	ld	s1,280(sp)
    80005ac4:	6952                	ld	s2,272(sp)
    80005ac6:	6155                	addi	sp,sp,304
    80005ac8:	8082                	ret

0000000080005aca <sys_unlink>:
{
    80005aca:	7151                	addi	sp,sp,-240
    80005acc:	f586                	sd	ra,232(sp)
    80005ace:	f1a2                	sd	s0,224(sp)
    80005ad0:	eda6                	sd	s1,216(sp)
    80005ad2:	e9ca                	sd	s2,208(sp)
    80005ad4:	e5ce                	sd	s3,200(sp)
    80005ad6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005ad8:	08000613          	li	a2,128
    80005adc:	f3040593          	addi	a1,s0,-208
    80005ae0:	4501                	li	a0,0
    80005ae2:	ffffd097          	auipc	ra,0xffffd
    80005ae6:	6a4080e7          	jalr	1700(ra) # 80003186 <argstr>
    80005aea:	18054163          	bltz	a0,80005c6c <sys_unlink+0x1a2>
  begin_op();
    80005aee:	fffff097          	auipc	ra,0xfffff
    80005af2:	c14080e7          	jalr	-1004(ra) # 80004702 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005af6:	fb040593          	addi	a1,s0,-80
    80005afa:	f3040513          	addi	a0,s0,-208
    80005afe:	fffff097          	auipc	ra,0xfffff
    80005b02:	a06080e7          	jalr	-1530(ra) # 80004504 <nameiparent>
    80005b06:	84aa                	mv	s1,a0
    80005b08:	c979                	beqz	a0,80005bde <sys_unlink+0x114>
  ilock(dp);
    80005b0a:	ffffe097          	auipc	ra,0xffffe
    80005b0e:	226080e7          	jalr	550(ra) # 80003d30 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b12:	00003597          	auipc	a1,0x3
    80005b16:	e1658593          	addi	a1,a1,-490 # 80008928 <syscalls+0x2c8>
    80005b1a:	fb040513          	addi	a0,s0,-80
    80005b1e:	ffffe097          	auipc	ra,0xffffe
    80005b22:	6dc080e7          	jalr	1756(ra) # 800041fa <namecmp>
    80005b26:	14050a63          	beqz	a0,80005c7a <sys_unlink+0x1b0>
    80005b2a:	00003597          	auipc	a1,0x3
    80005b2e:	e0658593          	addi	a1,a1,-506 # 80008930 <syscalls+0x2d0>
    80005b32:	fb040513          	addi	a0,s0,-80
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	6c4080e7          	jalr	1732(ra) # 800041fa <namecmp>
    80005b3e:	12050e63          	beqz	a0,80005c7a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b42:	f2c40613          	addi	a2,s0,-212
    80005b46:	fb040593          	addi	a1,s0,-80
    80005b4a:	8526                	mv	a0,s1
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	6c8080e7          	jalr	1736(ra) # 80004214 <dirlookup>
    80005b54:	892a                	mv	s2,a0
    80005b56:	12050263          	beqz	a0,80005c7a <sys_unlink+0x1b0>
  ilock(ip);
    80005b5a:	ffffe097          	auipc	ra,0xffffe
    80005b5e:	1d6080e7          	jalr	470(ra) # 80003d30 <ilock>
  if(ip->nlink < 1)
    80005b62:	04a91783          	lh	a5,74(s2)
    80005b66:	08f05263          	blez	a5,80005bea <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b6a:	04491703          	lh	a4,68(s2)
    80005b6e:	4785                	li	a5,1
    80005b70:	08f70563          	beq	a4,a5,80005bfa <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b74:	4641                	li	a2,16
    80005b76:	4581                	li	a1,0
    80005b78:	fc040513          	addi	a0,s0,-64
    80005b7c:	ffffb097          	auipc	ra,0xffffb
    80005b80:	164080e7          	jalr	356(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b84:	4741                	li	a4,16
    80005b86:	f2c42683          	lw	a3,-212(s0)
    80005b8a:	fc040613          	addi	a2,s0,-64
    80005b8e:	4581                	li	a1,0
    80005b90:	8526                	mv	a0,s1
    80005b92:	ffffe097          	auipc	ra,0xffffe
    80005b96:	54a080e7          	jalr	1354(ra) # 800040dc <writei>
    80005b9a:	47c1                	li	a5,16
    80005b9c:	0af51563          	bne	a0,a5,80005c46 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005ba0:	04491703          	lh	a4,68(s2)
    80005ba4:	4785                	li	a5,1
    80005ba6:	0af70863          	beq	a4,a5,80005c56 <sys_unlink+0x18c>
  iunlockput(dp);
    80005baa:	8526                	mv	a0,s1
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	3e6080e7          	jalr	998(ra) # 80003f92 <iunlockput>
  ip->nlink--;
    80005bb4:	04a95783          	lhu	a5,74(s2)
    80005bb8:	37fd                	addiw	a5,a5,-1
    80005bba:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005bbe:	854a                	mv	a0,s2
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	0a6080e7          	jalr	166(ra) # 80003c66 <iupdate>
  iunlockput(ip);
    80005bc8:	854a                	mv	a0,s2
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	3c8080e7          	jalr	968(ra) # 80003f92 <iunlockput>
  end_op();
    80005bd2:	fffff097          	auipc	ra,0xfffff
    80005bd6:	bb0080e7          	jalr	-1104(ra) # 80004782 <end_op>
  return 0;
    80005bda:	4501                	li	a0,0
    80005bdc:	a84d                	j	80005c8e <sys_unlink+0x1c4>
    end_op();
    80005bde:	fffff097          	auipc	ra,0xfffff
    80005be2:	ba4080e7          	jalr	-1116(ra) # 80004782 <end_op>
    return -1;
    80005be6:	557d                	li	a0,-1
    80005be8:	a05d                	j	80005c8e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005bea:	00003517          	auipc	a0,0x3
    80005bee:	d6e50513          	addi	a0,a0,-658 # 80008958 <syscalls+0x2f8>
    80005bf2:	ffffb097          	auipc	ra,0xffffb
    80005bf6:	94c080e7          	jalr	-1716(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bfa:	04c92703          	lw	a4,76(s2)
    80005bfe:	02000793          	li	a5,32
    80005c02:	f6e7f9e3          	bgeu	a5,a4,80005b74 <sys_unlink+0xaa>
    80005c06:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c0a:	4741                	li	a4,16
    80005c0c:	86ce                	mv	a3,s3
    80005c0e:	f1840613          	addi	a2,s0,-232
    80005c12:	4581                	li	a1,0
    80005c14:	854a                	mv	a0,s2
    80005c16:	ffffe097          	auipc	ra,0xffffe
    80005c1a:	3ce080e7          	jalr	974(ra) # 80003fe4 <readi>
    80005c1e:	47c1                	li	a5,16
    80005c20:	00f51b63          	bne	a0,a5,80005c36 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c24:	f1845783          	lhu	a5,-232(s0)
    80005c28:	e7a1                	bnez	a5,80005c70 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c2a:	29c1                	addiw	s3,s3,16
    80005c2c:	04c92783          	lw	a5,76(s2)
    80005c30:	fcf9ede3          	bltu	s3,a5,80005c0a <sys_unlink+0x140>
    80005c34:	b781                	j	80005b74 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c36:	00003517          	auipc	a0,0x3
    80005c3a:	d3a50513          	addi	a0,a0,-710 # 80008970 <syscalls+0x310>
    80005c3e:	ffffb097          	auipc	ra,0xffffb
    80005c42:	900080e7          	jalr	-1792(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005c46:	00003517          	auipc	a0,0x3
    80005c4a:	d4250513          	addi	a0,a0,-702 # 80008988 <syscalls+0x328>
    80005c4e:	ffffb097          	auipc	ra,0xffffb
    80005c52:	8f0080e7          	jalr	-1808(ra) # 8000053e <panic>
    dp->nlink--;
    80005c56:	04a4d783          	lhu	a5,74(s1)
    80005c5a:	37fd                	addiw	a5,a5,-1
    80005c5c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c60:	8526                	mv	a0,s1
    80005c62:	ffffe097          	auipc	ra,0xffffe
    80005c66:	004080e7          	jalr	4(ra) # 80003c66 <iupdate>
    80005c6a:	b781                	j	80005baa <sys_unlink+0xe0>
    return -1;
    80005c6c:	557d                	li	a0,-1
    80005c6e:	a005                	j	80005c8e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c70:	854a                	mv	a0,s2
    80005c72:	ffffe097          	auipc	ra,0xffffe
    80005c76:	320080e7          	jalr	800(ra) # 80003f92 <iunlockput>
  iunlockput(dp);
    80005c7a:	8526                	mv	a0,s1
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	316080e7          	jalr	790(ra) # 80003f92 <iunlockput>
  end_op();
    80005c84:	fffff097          	auipc	ra,0xfffff
    80005c88:	afe080e7          	jalr	-1282(ra) # 80004782 <end_op>
  return -1;
    80005c8c:	557d                	li	a0,-1
}
    80005c8e:	70ae                	ld	ra,232(sp)
    80005c90:	740e                	ld	s0,224(sp)
    80005c92:	64ee                	ld	s1,216(sp)
    80005c94:	694e                	ld	s2,208(sp)
    80005c96:	69ae                	ld	s3,200(sp)
    80005c98:	616d                	addi	sp,sp,240
    80005c9a:	8082                	ret

0000000080005c9c <sys_open>:

uint64
sys_open(void)
{
    80005c9c:	7131                	addi	sp,sp,-192
    80005c9e:	fd06                	sd	ra,184(sp)
    80005ca0:	f922                	sd	s0,176(sp)
    80005ca2:	f526                	sd	s1,168(sp)
    80005ca4:	f14a                	sd	s2,160(sp)
    80005ca6:	ed4e                	sd	s3,152(sp)
    80005ca8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005caa:	08000613          	li	a2,128
    80005cae:	f5040593          	addi	a1,s0,-176
    80005cb2:	4501                	li	a0,0
    80005cb4:	ffffd097          	auipc	ra,0xffffd
    80005cb8:	4d2080e7          	jalr	1234(ra) # 80003186 <argstr>
    return -1;
    80005cbc:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005cbe:	0c054163          	bltz	a0,80005d80 <sys_open+0xe4>
    80005cc2:	f4c40593          	addi	a1,s0,-180
    80005cc6:	4505                	li	a0,1
    80005cc8:	ffffd097          	auipc	ra,0xffffd
    80005ccc:	47a080e7          	jalr	1146(ra) # 80003142 <argint>
    80005cd0:	0a054863          	bltz	a0,80005d80 <sys_open+0xe4>

  begin_op();
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	a2e080e7          	jalr	-1490(ra) # 80004702 <begin_op>

  if(omode & O_CREATE){
    80005cdc:	f4c42783          	lw	a5,-180(s0)
    80005ce0:	2007f793          	andi	a5,a5,512
    80005ce4:	cbdd                	beqz	a5,80005d9a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ce6:	4681                	li	a3,0
    80005ce8:	4601                	li	a2,0
    80005cea:	4589                	li	a1,2
    80005cec:	f5040513          	addi	a0,s0,-176
    80005cf0:	00000097          	auipc	ra,0x0
    80005cf4:	972080e7          	jalr	-1678(ra) # 80005662 <create>
    80005cf8:	892a                	mv	s2,a0
    if(ip == 0){
    80005cfa:	c959                	beqz	a0,80005d90 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005cfc:	04491703          	lh	a4,68(s2)
    80005d00:	478d                	li	a5,3
    80005d02:	00f71763          	bne	a4,a5,80005d10 <sys_open+0x74>
    80005d06:	04695703          	lhu	a4,70(s2)
    80005d0a:	47a5                	li	a5,9
    80005d0c:	0ce7ec63          	bltu	a5,a4,80005de4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d10:	fffff097          	auipc	ra,0xfffff
    80005d14:	e02080e7          	jalr	-510(ra) # 80004b12 <filealloc>
    80005d18:	89aa                	mv	s3,a0
    80005d1a:	10050263          	beqz	a0,80005e1e <sys_open+0x182>
    80005d1e:	00000097          	auipc	ra,0x0
    80005d22:	902080e7          	jalr	-1790(ra) # 80005620 <fdalloc>
    80005d26:	84aa                	mv	s1,a0
    80005d28:	0e054663          	bltz	a0,80005e14 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d2c:	04491703          	lh	a4,68(s2)
    80005d30:	478d                	li	a5,3
    80005d32:	0cf70463          	beq	a4,a5,80005dfa <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d36:	4789                	li	a5,2
    80005d38:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d3c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d40:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d44:	f4c42783          	lw	a5,-180(s0)
    80005d48:	0017c713          	xori	a4,a5,1
    80005d4c:	8b05                	andi	a4,a4,1
    80005d4e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d52:	0037f713          	andi	a4,a5,3
    80005d56:	00e03733          	snez	a4,a4
    80005d5a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d5e:	4007f793          	andi	a5,a5,1024
    80005d62:	c791                	beqz	a5,80005d6e <sys_open+0xd2>
    80005d64:	04491703          	lh	a4,68(s2)
    80005d68:	4789                	li	a5,2
    80005d6a:	08f70f63          	beq	a4,a5,80005e08 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d6e:	854a                	mv	a0,s2
    80005d70:	ffffe097          	auipc	ra,0xffffe
    80005d74:	082080e7          	jalr	130(ra) # 80003df2 <iunlock>
  end_op();
    80005d78:	fffff097          	auipc	ra,0xfffff
    80005d7c:	a0a080e7          	jalr	-1526(ra) # 80004782 <end_op>

  return fd;
}
    80005d80:	8526                	mv	a0,s1
    80005d82:	70ea                	ld	ra,184(sp)
    80005d84:	744a                	ld	s0,176(sp)
    80005d86:	74aa                	ld	s1,168(sp)
    80005d88:	790a                	ld	s2,160(sp)
    80005d8a:	69ea                	ld	s3,152(sp)
    80005d8c:	6129                	addi	sp,sp,192
    80005d8e:	8082                	ret
      end_op();
    80005d90:	fffff097          	auipc	ra,0xfffff
    80005d94:	9f2080e7          	jalr	-1550(ra) # 80004782 <end_op>
      return -1;
    80005d98:	b7e5                	j	80005d80 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d9a:	f5040513          	addi	a0,s0,-176
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	748080e7          	jalr	1864(ra) # 800044e6 <namei>
    80005da6:	892a                	mv	s2,a0
    80005da8:	c905                	beqz	a0,80005dd8 <sys_open+0x13c>
    ilock(ip);
    80005daa:	ffffe097          	auipc	ra,0xffffe
    80005dae:	f86080e7          	jalr	-122(ra) # 80003d30 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005db2:	04491703          	lh	a4,68(s2)
    80005db6:	4785                	li	a5,1
    80005db8:	f4f712e3          	bne	a4,a5,80005cfc <sys_open+0x60>
    80005dbc:	f4c42783          	lw	a5,-180(s0)
    80005dc0:	dba1                	beqz	a5,80005d10 <sys_open+0x74>
      iunlockput(ip);
    80005dc2:	854a                	mv	a0,s2
    80005dc4:	ffffe097          	auipc	ra,0xffffe
    80005dc8:	1ce080e7          	jalr	462(ra) # 80003f92 <iunlockput>
      end_op();
    80005dcc:	fffff097          	auipc	ra,0xfffff
    80005dd0:	9b6080e7          	jalr	-1610(ra) # 80004782 <end_op>
      return -1;
    80005dd4:	54fd                	li	s1,-1
    80005dd6:	b76d                	j	80005d80 <sys_open+0xe4>
      end_op();
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	9aa080e7          	jalr	-1622(ra) # 80004782 <end_op>
      return -1;
    80005de0:	54fd                	li	s1,-1
    80005de2:	bf79                	j	80005d80 <sys_open+0xe4>
    iunlockput(ip);
    80005de4:	854a                	mv	a0,s2
    80005de6:	ffffe097          	auipc	ra,0xffffe
    80005dea:	1ac080e7          	jalr	428(ra) # 80003f92 <iunlockput>
    end_op();
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	994080e7          	jalr	-1644(ra) # 80004782 <end_op>
    return -1;
    80005df6:	54fd                	li	s1,-1
    80005df8:	b761                	j	80005d80 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005dfa:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005dfe:	04691783          	lh	a5,70(s2)
    80005e02:	02f99223          	sh	a5,36(s3)
    80005e06:	bf2d                	j	80005d40 <sys_open+0xa4>
    itrunc(ip);
    80005e08:	854a                	mv	a0,s2
    80005e0a:	ffffe097          	auipc	ra,0xffffe
    80005e0e:	034080e7          	jalr	52(ra) # 80003e3e <itrunc>
    80005e12:	bfb1                	j	80005d6e <sys_open+0xd2>
      fileclose(f);
    80005e14:	854e                	mv	a0,s3
    80005e16:	fffff097          	auipc	ra,0xfffff
    80005e1a:	db8080e7          	jalr	-584(ra) # 80004bce <fileclose>
    iunlockput(ip);
    80005e1e:	854a                	mv	a0,s2
    80005e20:	ffffe097          	auipc	ra,0xffffe
    80005e24:	172080e7          	jalr	370(ra) # 80003f92 <iunlockput>
    end_op();
    80005e28:	fffff097          	auipc	ra,0xfffff
    80005e2c:	95a080e7          	jalr	-1702(ra) # 80004782 <end_op>
    return -1;
    80005e30:	54fd                	li	s1,-1
    80005e32:	b7b9                	j	80005d80 <sys_open+0xe4>

0000000080005e34 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e34:	7175                	addi	sp,sp,-144
    80005e36:	e506                	sd	ra,136(sp)
    80005e38:	e122                	sd	s0,128(sp)
    80005e3a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e3c:	fffff097          	auipc	ra,0xfffff
    80005e40:	8c6080e7          	jalr	-1850(ra) # 80004702 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e44:	08000613          	li	a2,128
    80005e48:	f7040593          	addi	a1,s0,-144
    80005e4c:	4501                	li	a0,0
    80005e4e:	ffffd097          	auipc	ra,0xffffd
    80005e52:	338080e7          	jalr	824(ra) # 80003186 <argstr>
    80005e56:	02054963          	bltz	a0,80005e88 <sys_mkdir+0x54>
    80005e5a:	4681                	li	a3,0
    80005e5c:	4601                	li	a2,0
    80005e5e:	4585                	li	a1,1
    80005e60:	f7040513          	addi	a0,s0,-144
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	7fe080e7          	jalr	2046(ra) # 80005662 <create>
    80005e6c:	cd11                	beqz	a0,80005e88 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e6e:	ffffe097          	auipc	ra,0xffffe
    80005e72:	124080e7          	jalr	292(ra) # 80003f92 <iunlockput>
  end_op();
    80005e76:	fffff097          	auipc	ra,0xfffff
    80005e7a:	90c080e7          	jalr	-1780(ra) # 80004782 <end_op>
  return 0;
    80005e7e:	4501                	li	a0,0
}
    80005e80:	60aa                	ld	ra,136(sp)
    80005e82:	640a                	ld	s0,128(sp)
    80005e84:	6149                	addi	sp,sp,144
    80005e86:	8082                	ret
    end_op();
    80005e88:	fffff097          	auipc	ra,0xfffff
    80005e8c:	8fa080e7          	jalr	-1798(ra) # 80004782 <end_op>
    return -1;
    80005e90:	557d                	li	a0,-1
    80005e92:	b7fd                	j	80005e80 <sys_mkdir+0x4c>

0000000080005e94 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e94:	7135                	addi	sp,sp,-160
    80005e96:	ed06                	sd	ra,152(sp)
    80005e98:	e922                	sd	s0,144(sp)
    80005e9a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e9c:	fffff097          	auipc	ra,0xfffff
    80005ea0:	866080e7          	jalr	-1946(ra) # 80004702 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ea4:	08000613          	li	a2,128
    80005ea8:	f7040593          	addi	a1,s0,-144
    80005eac:	4501                	li	a0,0
    80005eae:	ffffd097          	auipc	ra,0xffffd
    80005eb2:	2d8080e7          	jalr	728(ra) # 80003186 <argstr>
    80005eb6:	04054a63          	bltz	a0,80005f0a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005eba:	f6c40593          	addi	a1,s0,-148
    80005ebe:	4505                	li	a0,1
    80005ec0:	ffffd097          	auipc	ra,0xffffd
    80005ec4:	282080e7          	jalr	642(ra) # 80003142 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ec8:	04054163          	bltz	a0,80005f0a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ecc:	f6840593          	addi	a1,s0,-152
    80005ed0:	4509                	li	a0,2
    80005ed2:	ffffd097          	auipc	ra,0xffffd
    80005ed6:	270080e7          	jalr	624(ra) # 80003142 <argint>
     argint(1, &major) < 0 ||
    80005eda:	02054863          	bltz	a0,80005f0a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ede:	f6841683          	lh	a3,-152(s0)
    80005ee2:	f6c41603          	lh	a2,-148(s0)
    80005ee6:	458d                	li	a1,3
    80005ee8:	f7040513          	addi	a0,s0,-144
    80005eec:	fffff097          	auipc	ra,0xfffff
    80005ef0:	776080e7          	jalr	1910(ra) # 80005662 <create>
     argint(2, &minor) < 0 ||
    80005ef4:	c919                	beqz	a0,80005f0a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ef6:	ffffe097          	auipc	ra,0xffffe
    80005efa:	09c080e7          	jalr	156(ra) # 80003f92 <iunlockput>
  end_op();
    80005efe:	fffff097          	auipc	ra,0xfffff
    80005f02:	884080e7          	jalr	-1916(ra) # 80004782 <end_op>
  return 0;
    80005f06:	4501                	li	a0,0
    80005f08:	a031                	j	80005f14 <sys_mknod+0x80>
    end_op();
    80005f0a:	fffff097          	auipc	ra,0xfffff
    80005f0e:	878080e7          	jalr	-1928(ra) # 80004782 <end_op>
    return -1;
    80005f12:	557d                	li	a0,-1
}
    80005f14:	60ea                	ld	ra,152(sp)
    80005f16:	644a                	ld	s0,144(sp)
    80005f18:	610d                	addi	sp,sp,160
    80005f1a:	8082                	ret

0000000080005f1c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f1c:	7135                	addi	sp,sp,-160
    80005f1e:	ed06                	sd	ra,152(sp)
    80005f20:	e922                	sd	s0,144(sp)
    80005f22:	e526                	sd	s1,136(sp)
    80005f24:	e14a                	sd	s2,128(sp)
    80005f26:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f28:	ffffc097          	auipc	ra,0xffffc
    80005f2c:	d64080e7          	jalr	-668(ra) # 80001c8c <myproc>
    80005f30:	892a                	mv	s2,a0
  
  begin_op();
    80005f32:	ffffe097          	auipc	ra,0xffffe
    80005f36:	7d0080e7          	jalr	2000(ra) # 80004702 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f3a:	08000613          	li	a2,128
    80005f3e:	f6040593          	addi	a1,s0,-160
    80005f42:	4501                	li	a0,0
    80005f44:	ffffd097          	auipc	ra,0xffffd
    80005f48:	242080e7          	jalr	578(ra) # 80003186 <argstr>
    80005f4c:	04054b63          	bltz	a0,80005fa2 <sys_chdir+0x86>
    80005f50:	f6040513          	addi	a0,s0,-160
    80005f54:	ffffe097          	auipc	ra,0xffffe
    80005f58:	592080e7          	jalr	1426(ra) # 800044e6 <namei>
    80005f5c:	84aa                	mv	s1,a0
    80005f5e:	c131                	beqz	a0,80005fa2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f60:	ffffe097          	auipc	ra,0xffffe
    80005f64:	dd0080e7          	jalr	-560(ra) # 80003d30 <ilock>
  if(ip->type != T_DIR){
    80005f68:	04449703          	lh	a4,68(s1)
    80005f6c:	4785                	li	a5,1
    80005f6e:	04f71063          	bne	a4,a5,80005fae <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f72:	8526                	mv	a0,s1
    80005f74:	ffffe097          	auipc	ra,0xffffe
    80005f78:	e7e080e7          	jalr	-386(ra) # 80003df2 <iunlock>
  iput(p->cwd);
    80005f7c:	15093503          	ld	a0,336(s2)
    80005f80:	ffffe097          	auipc	ra,0xffffe
    80005f84:	f6a080e7          	jalr	-150(ra) # 80003eea <iput>
  end_op();
    80005f88:	ffffe097          	auipc	ra,0xffffe
    80005f8c:	7fa080e7          	jalr	2042(ra) # 80004782 <end_op>
  p->cwd = ip;
    80005f90:	14993823          	sd	s1,336(s2)
  return 0;
    80005f94:	4501                	li	a0,0
}
    80005f96:	60ea                	ld	ra,152(sp)
    80005f98:	644a                	ld	s0,144(sp)
    80005f9a:	64aa                	ld	s1,136(sp)
    80005f9c:	690a                	ld	s2,128(sp)
    80005f9e:	610d                	addi	sp,sp,160
    80005fa0:	8082                	ret
    end_op();
    80005fa2:	ffffe097          	auipc	ra,0xffffe
    80005fa6:	7e0080e7          	jalr	2016(ra) # 80004782 <end_op>
    return -1;
    80005faa:	557d                	li	a0,-1
    80005fac:	b7ed                	j	80005f96 <sys_chdir+0x7a>
    iunlockput(ip);
    80005fae:	8526                	mv	a0,s1
    80005fb0:	ffffe097          	auipc	ra,0xffffe
    80005fb4:	fe2080e7          	jalr	-30(ra) # 80003f92 <iunlockput>
    end_op();
    80005fb8:	ffffe097          	auipc	ra,0xffffe
    80005fbc:	7ca080e7          	jalr	1994(ra) # 80004782 <end_op>
    return -1;
    80005fc0:	557d                	li	a0,-1
    80005fc2:	bfd1                	j	80005f96 <sys_chdir+0x7a>

0000000080005fc4 <sys_exec>:

uint64
sys_exec(void)
{
    80005fc4:	7145                	addi	sp,sp,-464
    80005fc6:	e786                	sd	ra,456(sp)
    80005fc8:	e3a2                	sd	s0,448(sp)
    80005fca:	ff26                	sd	s1,440(sp)
    80005fcc:	fb4a                	sd	s2,432(sp)
    80005fce:	f74e                	sd	s3,424(sp)
    80005fd0:	f352                	sd	s4,416(sp)
    80005fd2:	ef56                	sd	s5,408(sp)
    80005fd4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fd6:	08000613          	li	a2,128
    80005fda:	f4040593          	addi	a1,s0,-192
    80005fde:	4501                	li	a0,0
    80005fe0:	ffffd097          	auipc	ra,0xffffd
    80005fe4:	1a6080e7          	jalr	422(ra) # 80003186 <argstr>
    return -1;
    80005fe8:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fea:	0c054a63          	bltz	a0,800060be <sys_exec+0xfa>
    80005fee:	e3840593          	addi	a1,s0,-456
    80005ff2:	4505                	li	a0,1
    80005ff4:	ffffd097          	auipc	ra,0xffffd
    80005ff8:	170080e7          	jalr	368(ra) # 80003164 <argaddr>
    80005ffc:	0c054163          	bltz	a0,800060be <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006000:	10000613          	li	a2,256
    80006004:	4581                	li	a1,0
    80006006:	e4040513          	addi	a0,s0,-448
    8000600a:	ffffb097          	auipc	ra,0xffffb
    8000600e:	cd6080e7          	jalr	-810(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006012:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006016:	89a6                	mv	s3,s1
    80006018:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000601a:	02000a13          	li	s4,32
    8000601e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006022:	00391513          	slli	a0,s2,0x3
    80006026:	e3040593          	addi	a1,s0,-464
    8000602a:	e3843783          	ld	a5,-456(s0)
    8000602e:	953e                	add	a0,a0,a5
    80006030:	ffffd097          	auipc	ra,0xffffd
    80006034:	078080e7          	jalr	120(ra) # 800030a8 <fetchaddr>
    80006038:	02054a63          	bltz	a0,8000606c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000603c:	e3043783          	ld	a5,-464(s0)
    80006040:	c3b9                	beqz	a5,80006086 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006042:	ffffb097          	auipc	ra,0xffffb
    80006046:	ab2080e7          	jalr	-1358(ra) # 80000af4 <kalloc>
    8000604a:	85aa                	mv	a1,a0
    8000604c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006050:	cd11                	beqz	a0,8000606c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006052:	6605                	lui	a2,0x1
    80006054:	e3043503          	ld	a0,-464(s0)
    80006058:	ffffd097          	auipc	ra,0xffffd
    8000605c:	0a2080e7          	jalr	162(ra) # 800030fa <fetchstr>
    80006060:	00054663          	bltz	a0,8000606c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006064:	0905                	addi	s2,s2,1
    80006066:	09a1                	addi	s3,s3,8
    80006068:	fb491be3          	bne	s2,s4,8000601e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000606c:	10048913          	addi	s2,s1,256
    80006070:	6088                	ld	a0,0(s1)
    80006072:	c529                	beqz	a0,800060bc <sys_exec+0xf8>
    kfree(argv[i]);
    80006074:	ffffb097          	auipc	ra,0xffffb
    80006078:	984080e7          	jalr	-1660(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000607c:	04a1                	addi	s1,s1,8
    8000607e:	ff2499e3          	bne	s1,s2,80006070 <sys_exec+0xac>
  return -1;
    80006082:	597d                	li	s2,-1
    80006084:	a82d                	j	800060be <sys_exec+0xfa>
      argv[i] = 0;
    80006086:	0a8e                	slli	s5,s5,0x3
    80006088:	fc040793          	addi	a5,s0,-64
    8000608c:	9abe                	add	s5,s5,a5
    8000608e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006092:	e4040593          	addi	a1,s0,-448
    80006096:	f4040513          	addi	a0,s0,-192
    8000609a:	fffff097          	auipc	ra,0xfffff
    8000609e:	194080e7          	jalr	404(ra) # 8000522e <exec>
    800060a2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060a4:	10048993          	addi	s3,s1,256
    800060a8:	6088                	ld	a0,0(s1)
    800060aa:	c911                	beqz	a0,800060be <sys_exec+0xfa>
    kfree(argv[i]);
    800060ac:	ffffb097          	auipc	ra,0xffffb
    800060b0:	94c080e7          	jalr	-1716(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060b4:	04a1                	addi	s1,s1,8
    800060b6:	ff3499e3          	bne	s1,s3,800060a8 <sys_exec+0xe4>
    800060ba:	a011                	j	800060be <sys_exec+0xfa>
  return -1;
    800060bc:	597d                	li	s2,-1
}
    800060be:	854a                	mv	a0,s2
    800060c0:	60be                	ld	ra,456(sp)
    800060c2:	641e                	ld	s0,448(sp)
    800060c4:	74fa                	ld	s1,440(sp)
    800060c6:	795a                	ld	s2,432(sp)
    800060c8:	79ba                	ld	s3,424(sp)
    800060ca:	7a1a                	ld	s4,416(sp)
    800060cc:	6afa                	ld	s5,408(sp)
    800060ce:	6179                	addi	sp,sp,464
    800060d0:	8082                	ret

00000000800060d2 <sys_pipe>:

uint64
sys_pipe(void)
{
    800060d2:	7139                	addi	sp,sp,-64
    800060d4:	fc06                	sd	ra,56(sp)
    800060d6:	f822                	sd	s0,48(sp)
    800060d8:	f426                	sd	s1,40(sp)
    800060da:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060dc:	ffffc097          	auipc	ra,0xffffc
    800060e0:	bb0080e7          	jalr	-1104(ra) # 80001c8c <myproc>
    800060e4:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800060e6:	fd840593          	addi	a1,s0,-40
    800060ea:	4501                	li	a0,0
    800060ec:	ffffd097          	auipc	ra,0xffffd
    800060f0:	078080e7          	jalr	120(ra) # 80003164 <argaddr>
    return -1;
    800060f4:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800060f6:	0e054063          	bltz	a0,800061d6 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800060fa:	fc840593          	addi	a1,s0,-56
    800060fe:	fd040513          	addi	a0,s0,-48
    80006102:	fffff097          	auipc	ra,0xfffff
    80006106:	dfc080e7          	jalr	-516(ra) # 80004efe <pipealloc>
    return -1;
    8000610a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000610c:	0c054563          	bltz	a0,800061d6 <sys_pipe+0x104>
  fd0 = -1;
    80006110:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006114:	fd043503          	ld	a0,-48(s0)
    80006118:	fffff097          	auipc	ra,0xfffff
    8000611c:	508080e7          	jalr	1288(ra) # 80005620 <fdalloc>
    80006120:	fca42223          	sw	a0,-60(s0)
    80006124:	08054c63          	bltz	a0,800061bc <sys_pipe+0xea>
    80006128:	fc843503          	ld	a0,-56(s0)
    8000612c:	fffff097          	auipc	ra,0xfffff
    80006130:	4f4080e7          	jalr	1268(ra) # 80005620 <fdalloc>
    80006134:	fca42023          	sw	a0,-64(s0)
    80006138:	06054863          	bltz	a0,800061a8 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000613c:	4691                	li	a3,4
    8000613e:	fc440613          	addi	a2,s0,-60
    80006142:	fd843583          	ld	a1,-40(s0)
    80006146:	68a8                	ld	a0,80(s1)
    80006148:	ffffb097          	auipc	ra,0xffffb
    8000614c:	52a080e7          	jalr	1322(ra) # 80001672 <copyout>
    80006150:	02054063          	bltz	a0,80006170 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006154:	4691                	li	a3,4
    80006156:	fc040613          	addi	a2,s0,-64
    8000615a:	fd843583          	ld	a1,-40(s0)
    8000615e:	0591                	addi	a1,a1,4
    80006160:	68a8                	ld	a0,80(s1)
    80006162:	ffffb097          	auipc	ra,0xffffb
    80006166:	510080e7          	jalr	1296(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000616a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000616c:	06055563          	bgez	a0,800061d6 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006170:	fc442783          	lw	a5,-60(s0)
    80006174:	07e9                	addi	a5,a5,26
    80006176:	078e                	slli	a5,a5,0x3
    80006178:	97a6                	add	a5,a5,s1
    8000617a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000617e:	fc042503          	lw	a0,-64(s0)
    80006182:	0569                	addi	a0,a0,26
    80006184:	050e                	slli	a0,a0,0x3
    80006186:	9526                	add	a0,a0,s1
    80006188:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000618c:	fd043503          	ld	a0,-48(s0)
    80006190:	fffff097          	auipc	ra,0xfffff
    80006194:	a3e080e7          	jalr	-1474(ra) # 80004bce <fileclose>
    fileclose(wf);
    80006198:	fc843503          	ld	a0,-56(s0)
    8000619c:	fffff097          	auipc	ra,0xfffff
    800061a0:	a32080e7          	jalr	-1486(ra) # 80004bce <fileclose>
    return -1;
    800061a4:	57fd                	li	a5,-1
    800061a6:	a805                	j	800061d6 <sys_pipe+0x104>
    if(fd0 >= 0)
    800061a8:	fc442783          	lw	a5,-60(s0)
    800061ac:	0007c863          	bltz	a5,800061bc <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800061b0:	01a78513          	addi	a0,a5,26
    800061b4:	050e                	slli	a0,a0,0x3
    800061b6:	9526                	add	a0,a0,s1
    800061b8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800061bc:	fd043503          	ld	a0,-48(s0)
    800061c0:	fffff097          	auipc	ra,0xfffff
    800061c4:	a0e080e7          	jalr	-1522(ra) # 80004bce <fileclose>
    fileclose(wf);
    800061c8:	fc843503          	ld	a0,-56(s0)
    800061cc:	fffff097          	auipc	ra,0xfffff
    800061d0:	a02080e7          	jalr	-1534(ra) # 80004bce <fileclose>
    return -1;
    800061d4:	57fd                	li	a5,-1
}
    800061d6:	853e                	mv	a0,a5
    800061d8:	70e2                	ld	ra,56(sp)
    800061da:	7442                	ld	s0,48(sp)
    800061dc:	74a2                	ld	s1,40(sp)
    800061de:	6121                	addi	sp,sp,64
    800061e0:	8082                	ret
	...

00000000800061f0 <kernelvec>:
    800061f0:	7111                	addi	sp,sp,-256
    800061f2:	e006                	sd	ra,0(sp)
    800061f4:	e40a                	sd	sp,8(sp)
    800061f6:	e80e                	sd	gp,16(sp)
    800061f8:	ec12                	sd	tp,24(sp)
    800061fa:	f016                	sd	t0,32(sp)
    800061fc:	f41a                	sd	t1,40(sp)
    800061fe:	f81e                	sd	t2,48(sp)
    80006200:	fc22                	sd	s0,56(sp)
    80006202:	e0a6                	sd	s1,64(sp)
    80006204:	e4aa                	sd	a0,72(sp)
    80006206:	e8ae                	sd	a1,80(sp)
    80006208:	ecb2                	sd	a2,88(sp)
    8000620a:	f0b6                	sd	a3,96(sp)
    8000620c:	f4ba                	sd	a4,104(sp)
    8000620e:	f8be                	sd	a5,112(sp)
    80006210:	fcc2                	sd	a6,120(sp)
    80006212:	e146                	sd	a7,128(sp)
    80006214:	e54a                	sd	s2,136(sp)
    80006216:	e94e                	sd	s3,144(sp)
    80006218:	ed52                	sd	s4,152(sp)
    8000621a:	f156                	sd	s5,160(sp)
    8000621c:	f55a                	sd	s6,168(sp)
    8000621e:	f95e                	sd	s7,176(sp)
    80006220:	fd62                	sd	s8,184(sp)
    80006222:	e1e6                	sd	s9,192(sp)
    80006224:	e5ea                	sd	s10,200(sp)
    80006226:	e9ee                	sd	s11,208(sp)
    80006228:	edf2                	sd	t3,216(sp)
    8000622a:	f1f6                	sd	t4,224(sp)
    8000622c:	f5fa                	sd	t5,232(sp)
    8000622e:	f9fe                	sd	t6,240(sp)
    80006230:	d45fc0ef          	jal	ra,80002f74 <kerneltrap>
    80006234:	6082                	ld	ra,0(sp)
    80006236:	6122                	ld	sp,8(sp)
    80006238:	61c2                	ld	gp,16(sp)
    8000623a:	7282                	ld	t0,32(sp)
    8000623c:	7322                	ld	t1,40(sp)
    8000623e:	73c2                	ld	t2,48(sp)
    80006240:	7462                	ld	s0,56(sp)
    80006242:	6486                	ld	s1,64(sp)
    80006244:	6526                	ld	a0,72(sp)
    80006246:	65c6                	ld	a1,80(sp)
    80006248:	6666                	ld	a2,88(sp)
    8000624a:	7686                	ld	a3,96(sp)
    8000624c:	7726                	ld	a4,104(sp)
    8000624e:	77c6                	ld	a5,112(sp)
    80006250:	7866                	ld	a6,120(sp)
    80006252:	688a                	ld	a7,128(sp)
    80006254:	692a                	ld	s2,136(sp)
    80006256:	69ca                	ld	s3,144(sp)
    80006258:	6a6a                	ld	s4,152(sp)
    8000625a:	7a8a                	ld	s5,160(sp)
    8000625c:	7b2a                	ld	s6,168(sp)
    8000625e:	7bca                	ld	s7,176(sp)
    80006260:	7c6a                	ld	s8,184(sp)
    80006262:	6c8e                	ld	s9,192(sp)
    80006264:	6d2e                	ld	s10,200(sp)
    80006266:	6dce                	ld	s11,208(sp)
    80006268:	6e6e                	ld	t3,216(sp)
    8000626a:	7e8e                	ld	t4,224(sp)
    8000626c:	7f2e                	ld	t5,232(sp)
    8000626e:	7fce                	ld	t6,240(sp)
    80006270:	6111                	addi	sp,sp,256
    80006272:	10200073          	sret
    80006276:	00000013          	nop
    8000627a:	00000013          	nop
    8000627e:	0001                	nop

0000000080006280 <timervec>:
    80006280:	34051573          	csrrw	a0,mscratch,a0
    80006284:	e10c                	sd	a1,0(a0)
    80006286:	e510                	sd	a2,8(a0)
    80006288:	e914                	sd	a3,16(a0)
    8000628a:	6d0c                	ld	a1,24(a0)
    8000628c:	7110                	ld	a2,32(a0)
    8000628e:	6194                	ld	a3,0(a1)
    80006290:	96b2                	add	a3,a3,a2
    80006292:	e194                	sd	a3,0(a1)
    80006294:	4589                	li	a1,2
    80006296:	14459073          	csrw	sip,a1
    8000629a:	6914                	ld	a3,16(a0)
    8000629c:	6510                	ld	a2,8(a0)
    8000629e:	610c                	ld	a1,0(a0)
    800062a0:	34051573          	csrrw	a0,mscratch,a0
    800062a4:	30200073          	mret
	...

00000000800062aa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800062aa:	1141                	addi	sp,sp,-16
    800062ac:	e422                	sd	s0,8(sp)
    800062ae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800062b0:	0c0007b7          	lui	a5,0xc000
    800062b4:	4705                	li	a4,1
    800062b6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800062b8:	c3d8                	sw	a4,4(a5)
}
    800062ba:	6422                	ld	s0,8(sp)
    800062bc:	0141                	addi	sp,sp,16
    800062be:	8082                	ret

00000000800062c0 <plicinithart>:

void
plicinithart(void)
{
    800062c0:	1141                	addi	sp,sp,-16
    800062c2:	e406                	sd	ra,8(sp)
    800062c4:	e022                	sd	s0,0(sp)
    800062c6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062c8:	ffffc097          	auipc	ra,0xffffc
    800062cc:	992080e7          	jalr	-1646(ra) # 80001c5a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062d0:	0085171b          	slliw	a4,a0,0x8
    800062d4:	0c0027b7          	lui	a5,0xc002
    800062d8:	97ba                	add	a5,a5,a4
    800062da:	40200713          	li	a4,1026
    800062de:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062e2:	00d5151b          	slliw	a0,a0,0xd
    800062e6:	0c2017b7          	lui	a5,0xc201
    800062ea:	953e                	add	a0,a0,a5
    800062ec:	00052023          	sw	zero,0(a0)
}
    800062f0:	60a2                	ld	ra,8(sp)
    800062f2:	6402                	ld	s0,0(sp)
    800062f4:	0141                	addi	sp,sp,16
    800062f6:	8082                	ret

00000000800062f8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062f8:	1141                	addi	sp,sp,-16
    800062fa:	e406                	sd	ra,8(sp)
    800062fc:	e022                	sd	s0,0(sp)
    800062fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006300:	ffffc097          	auipc	ra,0xffffc
    80006304:	95a080e7          	jalr	-1702(ra) # 80001c5a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006308:	00d5179b          	slliw	a5,a0,0xd
    8000630c:	0c201537          	lui	a0,0xc201
    80006310:	953e                	add	a0,a0,a5
  return irq;
}
    80006312:	4148                	lw	a0,4(a0)
    80006314:	60a2                	ld	ra,8(sp)
    80006316:	6402                	ld	s0,0(sp)
    80006318:	0141                	addi	sp,sp,16
    8000631a:	8082                	ret

000000008000631c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000631c:	1101                	addi	sp,sp,-32
    8000631e:	ec06                	sd	ra,24(sp)
    80006320:	e822                	sd	s0,16(sp)
    80006322:	e426                	sd	s1,8(sp)
    80006324:	1000                	addi	s0,sp,32
    80006326:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006328:	ffffc097          	auipc	ra,0xffffc
    8000632c:	932080e7          	jalr	-1742(ra) # 80001c5a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006330:	00d5151b          	slliw	a0,a0,0xd
    80006334:	0c2017b7          	lui	a5,0xc201
    80006338:	97aa                	add	a5,a5,a0
    8000633a:	c3c4                	sw	s1,4(a5)
}
    8000633c:	60e2                	ld	ra,24(sp)
    8000633e:	6442                	ld	s0,16(sp)
    80006340:	64a2                	ld	s1,8(sp)
    80006342:	6105                	addi	sp,sp,32
    80006344:	8082                	ret

0000000080006346 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006346:	1141                	addi	sp,sp,-16
    80006348:	e406                	sd	ra,8(sp)
    8000634a:	e022                	sd	s0,0(sp)
    8000634c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000634e:	479d                	li	a5,7
    80006350:	06a7c963          	blt	a5,a0,800063c2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006354:	0001d797          	auipc	a5,0x1d
    80006358:	cac78793          	addi	a5,a5,-852 # 80023000 <disk>
    8000635c:	00a78733          	add	a4,a5,a0
    80006360:	6789                	lui	a5,0x2
    80006362:	97ba                	add	a5,a5,a4
    80006364:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006368:	e7ad                	bnez	a5,800063d2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000636a:	00451793          	slli	a5,a0,0x4
    8000636e:	0001f717          	auipc	a4,0x1f
    80006372:	c9270713          	addi	a4,a4,-878 # 80025000 <disk+0x2000>
    80006376:	6314                	ld	a3,0(a4)
    80006378:	96be                	add	a3,a3,a5
    8000637a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000637e:	6314                	ld	a3,0(a4)
    80006380:	96be                	add	a3,a3,a5
    80006382:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006386:	6314                	ld	a3,0(a4)
    80006388:	96be                	add	a3,a3,a5
    8000638a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000638e:	6318                	ld	a4,0(a4)
    80006390:	97ba                	add	a5,a5,a4
    80006392:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006396:	0001d797          	auipc	a5,0x1d
    8000639a:	c6a78793          	addi	a5,a5,-918 # 80023000 <disk>
    8000639e:	97aa                	add	a5,a5,a0
    800063a0:	6509                	lui	a0,0x2
    800063a2:	953e                	add	a0,a0,a5
    800063a4:	4785                	li	a5,1
    800063a6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800063aa:	0001f517          	auipc	a0,0x1f
    800063ae:	c6e50513          	addi	a0,a0,-914 # 80025018 <disk+0x2018>
    800063b2:	ffffc097          	auipc	ra,0xffffc
    800063b6:	63e080e7          	jalr	1598(ra) # 800029f0 <wakeup>
}
    800063ba:	60a2                	ld	ra,8(sp)
    800063bc:	6402                	ld	s0,0(sp)
    800063be:	0141                	addi	sp,sp,16
    800063c0:	8082                	ret
    panic("free_desc 1");
    800063c2:	00002517          	auipc	a0,0x2
    800063c6:	5d650513          	addi	a0,a0,1494 # 80008998 <syscalls+0x338>
    800063ca:	ffffa097          	auipc	ra,0xffffa
    800063ce:	174080e7          	jalr	372(ra) # 8000053e <panic>
    panic("free_desc 2");
    800063d2:	00002517          	auipc	a0,0x2
    800063d6:	5d650513          	addi	a0,a0,1494 # 800089a8 <syscalls+0x348>
    800063da:	ffffa097          	auipc	ra,0xffffa
    800063de:	164080e7          	jalr	356(ra) # 8000053e <panic>

00000000800063e2 <virtio_disk_init>:
{
    800063e2:	1101                	addi	sp,sp,-32
    800063e4:	ec06                	sd	ra,24(sp)
    800063e6:	e822                	sd	s0,16(sp)
    800063e8:	e426                	sd	s1,8(sp)
    800063ea:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063ec:	00002597          	auipc	a1,0x2
    800063f0:	5cc58593          	addi	a1,a1,1484 # 800089b8 <syscalls+0x358>
    800063f4:	0001f517          	auipc	a0,0x1f
    800063f8:	d3450513          	addi	a0,a0,-716 # 80025128 <disk+0x2128>
    800063fc:	ffffa097          	auipc	ra,0xffffa
    80006400:	758080e7          	jalr	1880(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006404:	100017b7          	lui	a5,0x10001
    80006408:	4398                	lw	a4,0(a5)
    8000640a:	2701                	sext.w	a4,a4
    8000640c:	747277b7          	lui	a5,0x74727
    80006410:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006414:	0ef71163          	bne	a4,a5,800064f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006418:	100017b7          	lui	a5,0x10001
    8000641c:	43dc                	lw	a5,4(a5)
    8000641e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006420:	4705                	li	a4,1
    80006422:	0ce79a63          	bne	a5,a4,800064f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006426:	100017b7          	lui	a5,0x10001
    8000642a:	479c                	lw	a5,8(a5)
    8000642c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000642e:	4709                	li	a4,2
    80006430:	0ce79363          	bne	a5,a4,800064f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006434:	100017b7          	lui	a5,0x10001
    80006438:	47d8                	lw	a4,12(a5)
    8000643a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000643c:	554d47b7          	lui	a5,0x554d4
    80006440:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006444:	0af71963          	bne	a4,a5,800064f6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006448:	100017b7          	lui	a5,0x10001
    8000644c:	4705                	li	a4,1
    8000644e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006450:	470d                	li	a4,3
    80006452:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006454:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006456:	c7ffe737          	lui	a4,0xc7ffe
    8000645a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000645e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006460:	2701                	sext.w	a4,a4
    80006462:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006464:	472d                	li	a4,11
    80006466:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006468:	473d                	li	a4,15
    8000646a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000646c:	6705                	lui	a4,0x1
    8000646e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006470:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006474:	5bdc                	lw	a5,52(a5)
    80006476:	2781                	sext.w	a5,a5
  if(max == 0)
    80006478:	c7d9                	beqz	a5,80006506 <virtio_disk_init+0x124>
  if(max < NUM)
    8000647a:	471d                	li	a4,7
    8000647c:	08f77d63          	bgeu	a4,a5,80006516 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006480:	100014b7          	lui	s1,0x10001
    80006484:	47a1                	li	a5,8
    80006486:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006488:	6609                	lui	a2,0x2
    8000648a:	4581                	li	a1,0
    8000648c:	0001d517          	auipc	a0,0x1d
    80006490:	b7450513          	addi	a0,a0,-1164 # 80023000 <disk>
    80006494:	ffffb097          	auipc	ra,0xffffb
    80006498:	84c080e7          	jalr	-1972(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000649c:	0001d717          	auipc	a4,0x1d
    800064a0:	b6470713          	addi	a4,a4,-1180 # 80023000 <disk>
    800064a4:	00c75793          	srli	a5,a4,0xc
    800064a8:	2781                	sext.w	a5,a5
    800064aa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800064ac:	0001f797          	auipc	a5,0x1f
    800064b0:	b5478793          	addi	a5,a5,-1196 # 80025000 <disk+0x2000>
    800064b4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800064b6:	0001d717          	auipc	a4,0x1d
    800064ba:	bca70713          	addi	a4,a4,-1078 # 80023080 <disk+0x80>
    800064be:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800064c0:	0001e717          	auipc	a4,0x1e
    800064c4:	b4070713          	addi	a4,a4,-1216 # 80024000 <disk+0x1000>
    800064c8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800064ca:	4705                	li	a4,1
    800064cc:	00e78c23          	sb	a4,24(a5)
    800064d0:	00e78ca3          	sb	a4,25(a5)
    800064d4:	00e78d23          	sb	a4,26(a5)
    800064d8:	00e78da3          	sb	a4,27(a5)
    800064dc:	00e78e23          	sb	a4,28(a5)
    800064e0:	00e78ea3          	sb	a4,29(a5)
    800064e4:	00e78f23          	sb	a4,30(a5)
    800064e8:	00e78fa3          	sb	a4,31(a5)
}
    800064ec:	60e2                	ld	ra,24(sp)
    800064ee:	6442                	ld	s0,16(sp)
    800064f0:	64a2                	ld	s1,8(sp)
    800064f2:	6105                	addi	sp,sp,32
    800064f4:	8082                	ret
    panic("could not find virtio disk");
    800064f6:	00002517          	auipc	a0,0x2
    800064fa:	4d250513          	addi	a0,a0,1234 # 800089c8 <syscalls+0x368>
    800064fe:	ffffa097          	auipc	ra,0xffffa
    80006502:	040080e7          	jalr	64(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006506:	00002517          	auipc	a0,0x2
    8000650a:	4e250513          	addi	a0,a0,1250 # 800089e8 <syscalls+0x388>
    8000650e:	ffffa097          	auipc	ra,0xffffa
    80006512:	030080e7          	jalr	48(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006516:	00002517          	auipc	a0,0x2
    8000651a:	4f250513          	addi	a0,a0,1266 # 80008a08 <syscalls+0x3a8>
    8000651e:	ffffa097          	auipc	ra,0xffffa
    80006522:	020080e7          	jalr	32(ra) # 8000053e <panic>

0000000080006526 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006526:	7159                	addi	sp,sp,-112
    80006528:	f486                	sd	ra,104(sp)
    8000652a:	f0a2                	sd	s0,96(sp)
    8000652c:	eca6                	sd	s1,88(sp)
    8000652e:	e8ca                	sd	s2,80(sp)
    80006530:	e4ce                	sd	s3,72(sp)
    80006532:	e0d2                	sd	s4,64(sp)
    80006534:	fc56                	sd	s5,56(sp)
    80006536:	f85a                	sd	s6,48(sp)
    80006538:	f45e                	sd	s7,40(sp)
    8000653a:	f062                	sd	s8,32(sp)
    8000653c:	ec66                	sd	s9,24(sp)
    8000653e:	e86a                	sd	s10,16(sp)
    80006540:	1880                	addi	s0,sp,112
    80006542:	892a                	mv	s2,a0
    80006544:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006546:	00c52c83          	lw	s9,12(a0)
    8000654a:	001c9c9b          	slliw	s9,s9,0x1
    8000654e:	1c82                	slli	s9,s9,0x20
    80006550:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006554:	0001f517          	auipc	a0,0x1f
    80006558:	bd450513          	addi	a0,a0,-1068 # 80025128 <disk+0x2128>
    8000655c:	ffffa097          	auipc	ra,0xffffa
    80006560:	688080e7          	jalr	1672(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006564:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006566:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006568:	0001db97          	auipc	s7,0x1d
    8000656c:	a98b8b93          	addi	s7,s7,-1384 # 80023000 <disk>
    80006570:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006572:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006574:	8a4e                	mv	s4,s3
    80006576:	a051                	j	800065fa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006578:	00fb86b3          	add	a3,s7,a5
    8000657c:	96da                	add	a3,a3,s6
    8000657e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006582:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006584:	0207c563          	bltz	a5,800065ae <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006588:	2485                	addiw	s1,s1,1
    8000658a:	0711                	addi	a4,a4,4
    8000658c:	25548063          	beq	s1,s5,800067cc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006590:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006592:	0001f697          	auipc	a3,0x1f
    80006596:	a8668693          	addi	a3,a3,-1402 # 80025018 <disk+0x2018>
    8000659a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000659c:	0006c583          	lbu	a1,0(a3)
    800065a0:	fde1                	bnez	a1,80006578 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800065a2:	2785                	addiw	a5,a5,1
    800065a4:	0685                	addi	a3,a3,1
    800065a6:	ff879be3          	bne	a5,s8,8000659c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800065aa:	57fd                	li	a5,-1
    800065ac:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800065ae:	02905a63          	blez	s1,800065e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065b2:	f9042503          	lw	a0,-112(s0)
    800065b6:	00000097          	auipc	ra,0x0
    800065ba:	d90080e7          	jalr	-624(ra) # 80006346 <free_desc>
      for(int j = 0; j < i; j++)
    800065be:	4785                	li	a5,1
    800065c0:	0297d163          	bge	a5,s1,800065e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065c4:	f9442503          	lw	a0,-108(s0)
    800065c8:	00000097          	auipc	ra,0x0
    800065cc:	d7e080e7          	jalr	-642(ra) # 80006346 <free_desc>
      for(int j = 0; j < i; j++)
    800065d0:	4789                	li	a5,2
    800065d2:	0097d863          	bge	a5,s1,800065e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065d6:	f9842503          	lw	a0,-104(s0)
    800065da:	00000097          	auipc	ra,0x0
    800065de:	d6c080e7          	jalr	-660(ra) # 80006346 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065e2:	0001f597          	auipc	a1,0x1f
    800065e6:	b4658593          	addi	a1,a1,-1210 # 80025128 <disk+0x2128>
    800065ea:	0001f517          	auipc	a0,0x1f
    800065ee:	a2e50513          	addi	a0,a0,-1490 # 80025018 <disk+0x2018>
    800065f2:	ffffc097          	auipc	ra,0xffffc
    800065f6:	de8080e7          	jalr	-536(ra) # 800023da <sleep>
  for(int i = 0; i < 3; i++){
    800065fa:	f9040713          	addi	a4,s0,-112
    800065fe:	84ce                	mv	s1,s3
    80006600:	bf41                	j	80006590 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006602:	20058713          	addi	a4,a1,512
    80006606:	00471693          	slli	a3,a4,0x4
    8000660a:	0001d717          	auipc	a4,0x1d
    8000660e:	9f670713          	addi	a4,a4,-1546 # 80023000 <disk>
    80006612:	9736                	add	a4,a4,a3
    80006614:	4685                	li	a3,1
    80006616:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000661a:	20058713          	addi	a4,a1,512
    8000661e:	00471693          	slli	a3,a4,0x4
    80006622:	0001d717          	auipc	a4,0x1d
    80006626:	9de70713          	addi	a4,a4,-1570 # 80023000 <disk>
    8000662a:	9736                	add	a4,a4,a3
    8000662c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006630:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006634:	7679                	lui	a2,0xffffe
    80006636:	963e                	add	a2,a2,a5
    80006638:	0001f697          	auipc	a3,0x1f
    8000663c:	9c868693          	addi	a3,a3,-1592 # 80025000 <disk+0x2000>
    80006640:	6298                	ld	a4,0(a3)
    80006642:	9732                	add	a4,a4,a2
    80006644:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006646:	6298                	ld	a4,0(a3)
    80006648:	9732                	add	a4,a4,a2
    8000664a:	4541                	li	a0,16
    8000664c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000664e:	6298                	ld	a4,0(a3)
    80006650:	9732                	add	a4,a4,a2
    80006652:	4505                	li	a0,1
    80006654:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006658:	f9442703          	lw	a4,-108(s0)
    8000665c:	6288                	ld	a0,0(a3)
    8000665e:	962a                	add	a2,a2,a0
    80006660:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006664:	0712                	slli	a4,a4,0x4
    80006666:	6290                	ld	a2,0(a3)
    80006668:	963a                	add	a2,a2,a4
    8000666a:	05890513          	addi	a0,s2,88
    8000666e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006670:	6294                	ld	a3,0(a3)
    80006672:	96ba                	add	a3,a3,a4
    80006674:	40000613          	li	a2,1024
    80006678:	c690                	sw	a2,8(a3)
  if(write)
    8000667a:	140d0063          	beqz	s10,800067ba <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000667e:	0001f697          	auipc	a3,0x1f
    80006682:	9826b683          	ld	a3,-1662(a3) # 80025000 <disk+0x2000>
    80006686:	96ba                	add	a3,a3,a4
    80006688:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000668c:	0001d817          	auipc	a6,0x1d
    80006690:	97480813          	addi	a6,a6,-1676 # 80023000 <disk>
    80006694:	0001f517          	auipc	a0,0x1f
    80006698:	96c50513          	addi	a0,a0,-1684 # 80025000 <disk+0x2000>
    8000669c:	6114                	ld	a3,0(a0)
    8000669e:	96ba                	add	a3,a3,a4
    800066a0:	00c6d603          	lhu	a2,12(a3)
    800066a4:	00166613          	ori	a2,a2,1
    800066a8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800066ac:	f9842683          	lw	a3,-104(s0)
    800066b0:	6110                	ld	a2,0(a0)
    800066b2:	9732                	add	a4,a4,a2
    800066b4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800066b8:	20058613          	addi	a2,a1,512
    800066bc:	0612                	slli	a2,a2,0x4
    800066be:	9642                	add	a2,a2,a6
    800066c0:	577d                	li	a4,-1
    800066c2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800066c6:	00469713          	slli	a4,a3,0x4
    800066ca:	6114                	ld	a3,0(a0)
    800066cc:	96ba                	add	a3,a3,a4
    800066ce:	03078793          	addi	a5,a5,48
    800066d2:	97c2                	add	a5,a5,a6
    800066d4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800066d6:	611c                	ld	a5,0(a0)
    800066d8:	97ba                	add	a5,a5,a4
    800066da:	4685                	li	a3,1
    800066dc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066de:	611c                	ld	a5,0(a0)
    800066e0:	97ba                	add	a5,a5,a4
    800066e2:	4809                	li	a6,2
    800066e4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800066e8:	611c                	ld	a5,0(a0)
    800066ea:	973e                	add	a4,a4,a5
    800066ec:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800066f0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800066f4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800066f8:	6518                	ld	a4,8(a0)
    800066fa:	00275783          	lhu	a5,2(a4)
    800066fe:	8b9d                	andi	a5,a5,7
    80006700:	0786                	slli	a5,a5,0x1
    80006702:	97ba                	add	a5,a5,a4
    80006704:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006708:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000670c:	6518                	ld	a4,8(a0)
    8000670e:	00275783          	lhu	a5,2(a4)
    80006712:	2785                	addiw	a5,a5,1
    80006714:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006718:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000671c:	100017b7          	lui	a5,0x10001
    80006720:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006724:	00492703          	lw	a4,4(s2)
    80006728:	4785                	li	a5,1
    8000672a:	02f71163          	bne	a4,a5,8000674c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000672e:	0001f997          	auipc	s3,0x1f
    80006732:	9fa98993          	addi	s3,s3,-1542 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006736:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006738:	85ce                	mv	a1,s3
    8000673a:	854a                	mv	a0,s2
    8000673c:	ffffc097          	auipc	ra,0xffffc
    80006740:	c9e080e7          	jalr	-866(ra) # 800023da <sleep>
  while(b->disk == 1) {
    80006744:	00492783          	lw	a5,4(s2)
    80006748:	fe9788e3          	beq	a5,s1,80006738 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000674c:	f9042903          	lw	s2,-112(s0)
    80006750:	20090793          	addi	a5,s2,512
    80006754:	00479713          	slli	a4,a5,0x4
    80006758:	0001d797          	auipc	a5,0x1d
    8000675c:	8a878793          	addi	a5,a5,-1880 # 80023000 <disk>
    80006760:	97ba                	add	a5,a5,a4
    80006762:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006766:	0001f997          	auipc	s3,0x1f
    8000676a:	89a98993          	addi	s3,s3,-1894 # 80025000 <disk+0x2000>
    8000676e:	00491713          	slli	a4,s2,0x4
    80006772:	0009b783          	ld	a5,0(s3)
    80006776:	97ba                	add	a5,a5,a4
    80006778:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000677c:	854a                	mv	a0,s2
    8000677e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006782:	00000097          	auipc	ra,0x0
    80006786:	bc4080e7          	jalr	-1084(ra) # 80006346 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000678a:	8885                	andi	s1,s1,1
    8000678c:	f0ed                	bnez	s1,8000676e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000678e:	0001f517          	auipc	a0,0x1f
    80006792:	99a50513          	addi	a0,a0,-1638 # 80025128 <disk+0x2128>
    80006796:	ffffa097          	auipc	ra,0xffffa
    8000679a:	502080e7          	jalr	1282(ra) # 80000c98 <release>
}
    8000679e:	70a6                	ld	ra,104(sp)
    800067a0:	7406                	ld	s0,96(sp)
    800067a2:	64e6                	ld	s1,88(sp)
    800067a4:	6946                	ld	s2,80(sp)
    800067a6:	69a6                	ld	s3,72(sp)
    800067a8:	6a06                	ld	s4,64(sp)
    800067aa:	7ae2                	ld	s5,56(sp)
    800067ac:	7b42                	ld	s6,48(sp)
    800067ae:	7ba2                	ld	s7,40(sp)
    800067b0:	7c02                	ld	s8,32(sp)
    800067b2:	6ce2                	ld	s9,24(sp)
    800067b4:	6d42                	ld	s10,16(sp)
    800067b6:	6165                	addi	sp,sp,112
    800067b8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800067ba:	0001f697          	auipc	a3,0x1f
    800067be:	8466b683          	ld	a3,-1978(a3) # 80025000 <disk+0x2000>
    800067c2:	96ba                	add	a3,a3,a4
    800067c4:	4609                	li	a2,2
    800067c6:	00c69623          	sh	a2,12(a3)
    800067ca:	b5c9                	j	8000668c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800067cc:	f9042583          	lw	a1,-112(s0)
    800067d0:	20058793          	addi	a5,a1,512
    800067d4:	0792                	slli	a5,a5,0x4
    800067d6:	0001d517          	auipc	a0,0x1d
    800067da:	8d250513          	addi	a0,a0,-1838 # 800230a8 <disk+0xa8>
    800067de:	953e                	add	a0,a0,a5
  if(write)
    800067e0:	e20d11e3          	bnez	s10,80006602 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800067e4:	20058713          	addi	a4,a1,512
    800067e8:	00471693          	slli	a3,a4,0x4
    800067ec:	0001d717          	auipc	a4,0x1d
    800067f0:	81470713          	addi	a4,a4,-2028 # 80023000 <disk>
    800067f4:	9736                	add	a4,a4,a3
    800067f6:	0a072423          	sw	zero,168(a4)
    800067fa:	b505                	j	8000661a <virtio_disk_rw+0xf4>

00000000800067fc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067fc:	1101                	addi	sp,sp,-32
    800067fe:	ec06                	sd	ra,24(sp)
    80006800:	e822                	sd	s0,16(sp)
    80006802:	e426                	sd	s1,8(sp)
    80006804:	e04a                	sd	s2,0(sp)
    80006806:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006808:	0001f517          	auipc	a0,0x1f
    8000680c:	92050513          	addi	a0,a0,-1760 # 80025128 <disk+0x2128>
    80006810:	ffffa097          	auipc	ra,0xffffa
    80006814:	3d4080e7          	jalr	980(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006818:	10001737          	lui	a4,0x10001
    8000681c:	533c                	lw	a5,96(a4)
    8000681e:	8b8d                	andi	a5,a5,3
    80006820:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006822:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006826:	0001e797          	auipc	a5,0x1e
    8000682a:	7da78793          	addi	a5,a5,2010 # 80025000 <disk+0x2000>
    8000682e:	6b94                	ld	a3,16(a5)
    80006830:	0207d703          	lhu	a4,32(a5)
    80006834:	0026d783          	lhu	a5,2(a3)
    80006838:	06f70163          	beq	a4,a5,8000689a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000683c:	0001c917          	auipc	s2,0x1c
    80006840:	7c490913          	addi	s2,s2,1988 # 80023000 <disk>
    80006844:	0001e497          	auipc	s1,0x1e
    80006848:	7bc48493          	addi	s1,s1,1980 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000684c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006850:	6898                	ld	a4,16(s1)
    80006852:	0204d783          	lhu	a5,32(s1)
    80006856:	8b9d                	andi	a5,a5,7
    80006858:	078e                	slli	a5,a5,0x3
    8000685a:	97ba                	add	a5,a5,a4
    8000685c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000685e:	20078713          	addi	a4,a5,512
    80006862:	0712                	slli	a4,a4,0x4
    80006864:	974a                	add	a4,a4,s2
    80006866:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000686a:	e731                	bnez	a4,800068b6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000686c:	20078793          	addi	a5,a5,512
    80006870:	0792                	slli	a5,a5,0x4
    80006872:	97ca                	add	a5,a5,s2
    80006874:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006876:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000687a:	ffffc097          	auipc	ra,0xffffc
    8000687e:	176080e7          	jalr	374(ra) # 800029f0 <wakeup>

    disk.used_idx += 1;
    80006882:	0204d783          	lhu	a5,32(s1)
    80006886:	2785                	addiw	a5,a5,1
    80006888:	17c2                	slli	a5,a5,0x30
    8000688a:	93c1                	srli	a5,a5,0x30
    8000688c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006890:	6898                	ld	a4,16(s1)
    80006892:	00275703          	lhu	a4,2(a4)
    80006896:	faf71be3          	bne	a4,a5,8000684c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000689a:	0001f517          	auipc	a0,0x1f
    8000689e:	88e50513          	addi	a0,a0,-1906 # 80025128 <disk+0x2128>
    800068a2:	ffffa097          	auipc	ra,0xffffa
    800068a6:	3f6080e7          	jalr	1014(ra) # 80000c98 <release>
}
    800068aa:	60e2                	ld	ra,24(sp)
    800068ac:	6442                	ld	s0,16(sp)
    800068ae:	64a2                	ld	s1,8(sp)
    800068b0:	6902                	ld	s2,0(sp)
    800068b2:	6105                	addi	sp,sp,32
    800068b4:	8082                	ret
      panic("virtio_disk_intr status");
    800068b6:	00002517          	auipc	a0,0x2
    800068ba:	17250513          	addi	a0,a0,370 # 80008a28 <syscalls+0x3c8>
    800068be:	ffffa097          	auipc	ra,0xffffa
    800068c2:	c80080e7          	jalr	-896(ra) # 8000053e <panic>

00000000800068c6 <cas>:
    800068c6:	100522af          	lr.w	t0,(a0)
    800068ca:	00b29563          	bne	t0,a1,800068d4 <fail>
    800068ce:	18c5252f          	sc.w	a0,a2,(a0)
    800068d2:	8082                	ret

00000000800068d4 <fail>:
    800068d4:	4505                	li	a0,1
    800068d6:	8082                	ret
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
