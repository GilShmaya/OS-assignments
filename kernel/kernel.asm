
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
    80000068:	e0c78793          	addi	a5,a5,-500 # 80005e70 <timervec>
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
    80000130:	5a6080e7          	jalr	1446(ra) # 800026d2 <either_copyin>
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
    800001d8:	104080e7          	jalr	260(ra) # 800022d8 <sleep>
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
    80000214:	46c080e7          	jalr	1132(ra) # 8000267c <either_copyout>
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
    800002f6:	436080e7          	jalr	1078(ra) # 80002728 <procdump>
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
    8000044a:	01e080e7          	jalr	30(ra) # 80002464 <wakeup>
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
    800008a4:	bc4080e7          	jalr	-1084(ra) # 80002464 <wakeup>
    
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
    80000930:	9ac080e7          	jalr	-1620(ra) # 800022d8 <sleep>
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
    80000ed8:	a34080e7          	jalr	-1484(ra) # 80002908 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	fd4080e7          	jalr	-44(ra) # 80005eb0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	1fe080e7          	jalr	510(ra) # 800020e2 <scheduler>
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
    80000f58:	98c080e7          	jalr	-1652(ra) # 800028e0 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	9ac080e7          	jalr	-1620(ra) # 80002908 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	f36080e7          	jalr	-202(ra) # 80005e9a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	f44080e7          	jalr	-188(ra) # 80005eb0 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	122080e7          	jalr	290(ra) # 80003096 <binit>
    iinit();         // inode table
    80000f7c:	00002097          	auipc	ra,0x2
    80000f80:	7b2080e7          	jalr	1970(ra) # 8000372e <iinit>
    fileinit();      // file table
    80000f84:	00003097          	auipc	ra,0x3
    80000f88:	75c080e7          	jalr	1884(ra) # 800046e0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	046080e7          	jalr	70(ra) # 80005fd2 <virtio_disk_init>
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
    80001a18:	e2c7a783          	lw	a5,-468(a5) # 80008840 <first.1729>
    80001a1c:	eb89                	bnez	a5,80001a2e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a1e:	00001097          	auipc	ra,0x1
    80001a22:	f02080e7          	jalr	-254(ra) # 80002920 <usertrapret>
}
    80001a26:	60a2                	ld	ra,8(sp)
    80001a28:	6402                	ld	s0,0(sp)
    80001a2a:	0141                	addi	sp,sp,16
    80001a2c:	8082                	ret
    first = 0;
    80001a2e:	00007797          	auipc	a5,0x7
    80001a32:	e007a923          	sw	zero,-494(a5) # 80008840 <first.1729>
    fsinit(ROOTDEV);
    80001a36:	4505                	li	a0,1
    80001a38:	00002097          	auipc	ra,0x2
    80001a3c:	c76080e7          	jalr	-906(ra) # 800036ae <fsinit>
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
    80001a64:	de478793          	addi	a5,a5,-540 # 80008844 <nextpid>
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
    80001cc8:	b8c58593          	addi	a1,a1,-1140 # 80008850 <initcode>
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
    80001d06:	3da080e7          	jalr	986(ra) # 800040dc <namei>
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
    80001e3c:	93a080e7          	jalr	-1734(ra) # 80004772 <filedup>
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
    80001e5e:	a8e080e7          	jalr	-1394(ra) # 800038e8 <idup>
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
    80001f5e:	91c080e7          	jalr	-1764(ra) # 80002876 <swtch>
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
    80001fb2:	1000                	addi	s0,sp,32
    80001fb4:	84aa                	mv	s1,a0
  p->state = RUNNING;
    80001fb6:	4791                	li	a5,4
    80001fb8:	cd9c                	sw	a5,24(a1)
  c->proc = p;
    80001fba:	e10c                	sd	a1,0(a0)
  swtch(&c->context, &p->context);
    80001fbc:	06858593          	addi	a1,a1,104
    80001fc0:	0521                	addi	a0,a0,8
    80001fc2:	00001097          	auipc	ra,0x1
    80001fc6:	8b4080e7          	jalr	-1868(ra) # 80002876 <swtch>
  c->proc = 0;
    80001fca:	0004b023          	sd	zero,0(s1)
}
    80001fce:	60e2                	ld	ra,24(sp)
    80001fd0:	6442                	ld	s0,16(sp)
    80001fd2:	64a2                	ld	s1,8(sp)
    80001fd4:	6105                	addi	sp,sp,32
    80001fd6:	8082                	ret

0000000080001fd8 <scheduler_sjf>:
void scheduler_sjf(void){
    80001fd8:	711d                	addi	sp,sp,-96
    80001fda:	ec86                	sd	ra,88(sp)
    80001fdc:	e8a2                	sd	s0,80(sp)
    80001fde:	e4a6                	sd	s1,72(sp)
    80001fe0:	e0ca                	sd	s2,64(sp)
    80001fe2:	fc4e                	sd	s3,56(sp)
    80001fe4:	f852                	sd	s4,48(sp)
    80001fe6:	f456                	sd	s5,40(sp)
    80001fe8:	f05a                	sd	s6,32(sp)
    80001fea:	ec5e                	sd	s7,24(sp)
    80001fec:	e862                	sd	s8,16(sp)
    80001fee:	e466                	sd	s9,8(sp)
    80001ff0:	e06a                	sd	s10,0(sp)
    80001ff2:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ff4:	8792                	mv	a5,tp
  int id = r_tp();
    80001ff6:	2781                	sext.w	a5,a5
  struct cpu *c = &cpus[id];
    80001ff8:	079e                	slli	a5,a5,0x7
    80001ffa:	0000f717          	auipc	a4,0xf
    80001ffe:	2d670713          	addi	a4,a4,726 # 800112d0 <cpus>
    80002002:	00f70d33          	add	s10,a4,a5
  c->proc = 0;
    80002006:	0000f717          	auipc	a4,0xf
    8000200a:	29a70713          	addi	a4,a4,666 # 800112a0 <pid_lock>
    8000200e:	97ba                	add	a5,a5,a4
    80002010:	0207b823          	sd	zero,48(a5)
      if(ticks >= pause_ticks){ // check if pause signal was called
    80002014:	00007917          	auipc	s2,0x7
    80002018:	02490913          	addi	s2,s2,36 # 80009038 <ticks>
    8000201c:	00007a17          	auipc	s4,0x7
    80002020:	00ca0a13          	addi	s4,s4,12 # 80009028 <pause_ticks>
        if(curr->state == RUNNABLE) {
    80002024:	4a8d                	li	s5,3
          curr->mean_ticks = ((SECONDS_TO_TICKS - RATE) * curr->mean_ticks + curr->last_ticks * (RATE)) / SECONDS_TO_TICKS;
    80002026:	4ba9                	li	s7,10
    for(curr = proc; curr < &proc[NPROC]; curr++) {
    80002028:	00015997          	auipc	s3,0x15
    8000202c:	2a898993          	addi	s3,s3,680 # 800172d0 <tickslock>
    p = NULL;
    80002030:	4c01                	li	s8,0
    80002032:	a8b1                	j	8000208e <scheduler_sjf+0xb6>
    80002034:	8b26                	mv	s6,s1
        release(&curr->lock);
    80002036:	8526                	mv	a0,s1
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	c60080e7          	jalr	-928(ra) # 80000c98 <release>
    for(curr = proc; curr < &proc[NPROC]; curr++) {
    80002040:	17048493          	addi	s1,s1,368
    80002044:	05348363          	beq	s1,s3,8000208a <scheduler_sjf+0xb2>
      if(ticks >= pause_ticks){ // check if pause signal was called
    80002048:	00092703          	lw	a4,0(s2)
    8000204c:	000a2783          	lw	a5,0(s4)
    80002050:	fef768e3          	bltu	a4,a5,80002040 <scheduler_sjf+0x68>
        acquire(&curr->lock);
    80002054:	8526                	mv	a0,s1
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	b8e080e7          	jalr	-1138(ra) # 80000be4 <acquire>
        if(curr->state == RUNNABLE) {
    8000205e:	4c9c                	lw	a5,24(s1)
    80002060:	fd579be3          	bne	a5,s5,80002036 <scheduler_sjf+0x5e>
          curr->mean_ticks = ((SECONDS_TO_TICKS - RATE) * curr->mean_ticks + curr->last_ticks * (RATE)) / SECONDS_TO_TICKS;
    80002064:	58d8                	lw	a4,52(s1)
    80002066:	0027179b          	slliw	a5,a4,0x2
    8000206a:	9fb9                	addw	a5,a5,a4
    8000206c:	0017979b          	slliw	a5,a5,0x1
    80002070:	0377d7bb          	divuw	a5,a5,s7
    80002074:	0007871b          	sext.w	a4,a5
    80002078:	d8dc                	sw	a5,52(s1)
          if(p == NULL || p->mean_ticks >= curr->mean_ticks) {
    8000207a:	fa0b0de3          	beqz	s6,80002034 <scheduler_sjf+0x5c>
    8000207e:	034b2783          	lw	a5,52(s6)
    80002082:	fae7eae3          	bltu	a5,a4,80002036 <scheduler_sjf+0x5e>
    80002086:	8b26                	mv	s6,s1
    80002088:	b77d                	j	80002036 <scheduler_sjf+0x5e>
    if(p != NULL){
    8000208a:	000b1e63          	bnez	s6,800020a6 <scheduler_sjf+0xce>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000208e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002092:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002096:	10079073          	csrw	sstatus,a5
    for(curr = proc; curr < &proc[NPROC]; curr++) {
    8000209a:	0000f497          	auipc	s1,0xf
    8000209e:	63648493          	addi	s1,s1,1590 # 800116d0 <proc>
    p = NULL;
    800020a2:	8b62                	mv	s6,s8
    800020a4:	b755                	j	80002048 <scheduler_sjf+0x70>
      acquire(&p->lock);
    800020a6:	84da                	mv	s1,s6
    800020a8:	855a                	mv	a0,s6
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	b3a080e7          	jalr	-1222(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE){
    800020b2:	018b2783          	lw	a5,24(s6)
    800020b6:	03579063          	bne	a5,s5,800020d6 <scheduler_sjf+0xfe>
        uint start = ticks;
    800020ba:	00092c83          	lw	s9,0(s2)
        make_acquired_process_running(c, p);
    800020be:	85da                	mv	a1,s6
    800020c0:	856a                	mv	a0,s10
    800020c2:	00000097          	auipc	ra,0x0
    800020c6:	ee8080e7          	jalr	-280(ra) # 80001faa <make_acquired_process_running>
        p->last_ticks = ticks - start;
    800020ca:	00092783          	lw	a5,0(s2)
    800020ce:	419787bb          	subw	a5,a5,s9
    800020d2:	02fb2c23          	sw	a5,56(s6)
      release(&p->lock);
    800020d6:	8526                	mv	a0,s1
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	bc0080e7          	jalr	-1088(ra) # 80000c98 <release>
    800020e0:	b77d                	j	8000208e <scheduler_sjf+0xb6>

00000000800020e2 <scheduler>:
{
    800020e2:	1141                	addi	sp,sp,-16
    800020e4:	e406                	sd	ra,8(sp)
    800020e6:	e022                	sd	s0,0(sp)
    800020e8:	0800                	addi	s0,sp,16
    printf("SJF scheduler mode\n");
    800020ea:	00006517          	auipc	a0,0x6
    800020ee:	12e50513          	addi	a0,a0,302 # 80008218 <digits+0x1d8>
    800020f2:	ffffe097          	auipc	ra,0xffffe
    800020f6:	496080e7          	jalr	1174(ra) # 80000588 <printf>
    scheduler_sjf();
    800020fa:	00000097          	auipc	ra,0x0
    800020fe:	ede080e7          	jalr	-290(ra) # 80001fd8 <scheduler_sjf>

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
    80002120:	0000fb97          	auipc	s7,0xf
    80002124:	1b0b8b93          	addi	s7,s7,432 # 800112d0 <cpus>
    80002128:	9bbe                	add	s7,s7,a5
  c->proc = 0;
    8000212a:	0000f717          	auipc	a4,0xf
    8000212e:	17670713          	addi	a4,a4,374 # 800112a0 <pid_lock>
    80002132:	97ba                	add	a5,a5,a4
    80002134:	0207b823          	sd	zero,48(a5)
    for(curr = proc; curr < &proc[NPROC]; p++) {
    80002138:	0000fc17          	auipc	s8,0xf
    8000213c:	598c0c13          	addi	s8,s8,1432 # 800116d0 <proc>
      if(ticks >= pause_ticks){ // check if pause signal was called
    80002140:	00007a97          	auipc	s5,0x7
    80002144:	ef8a8a93          	addi	s5,s5,-264 # 80009038 <ticks>
    80002148:	00007a17          	auipc	s4,0x7
    8000214c:	ee0a0a13          	addi	s4,s4,-288 # 80009028 <pause_ticks>
        if(curr->state == RUNNABLE) {
    80002150:	4b0d                	li	s6,3
    for(curr = proc; curr < &proc[NPROC]; p++) {
    80002152:	00015997          	auipc	s3,0x15
    80002156:	17e98993          	addi	s3,s3,382 # 800172d0 <tickslock>
    8000215a:	a8a9                	j	800021b4 <scheduler_fcfs+0xb2>
          if(p == NULL){
    8000215c:	c891                	beqz	s1,80002170 <scheduler_fcfs+0x6e>
          } else if(p->last_runnable_time > curr->last_runnable_time) {
    8000215e:	5cd8                	lw	a4,60(s1)
    80002160:	03c92783          	lw	a5,60(s2)
    80002164:	02e7fa63          	bgeu	a5,a4,80002198 <scheduler_fcfs+0x96>
    80002168:	87a6                	mv	a5,s1
    8000216a:	84ca                	mv	s1,s2
    8000216c:	893e                	mv	s2,a5
    8000216e:	a02d                	j	80002198 <scheduler_fcfs+0x96>
    80002170:	84ca                	mv	s1,s2
    for(curr = proc; curr < &proc[NPROC]; p++) {
    80002172:	17048493          	addi	s1,s1,368
    80002176:	03397963          	bgeu	s2,s3,800021a8 <scheduler_fcfs+0xa6>
      if(ticks >= pause_ticks){ // check if pause signal was called
    8000217a:	000aa703          	lw	a4,0(s5)
    8000217e:	000a2783          	lw	a5,0(s4)
    80002182:	fef768e3          	bltu	a4,a5,80002172 <scheduler_fcfs+0x70>
        acquire(&curr->lock);
    80002186:	854a                	mv	a0,s2
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	a5c080e7          	jalr	-1444(ra) # 80000be4 <acquire>
        if(curr->state == RUNNABLE) {
    80002190:	01892783          	lw	a5,24(s2)
    80002194:	fd6784e3          	beq	a5,s6,8000215c <scheduler_fcfs+0x5a>
        if(p != curr)
    80002198:	fd248de3          	beq	s1,s2,80002172 <scheduler_fcfs+0x70>
          release(&curr->lock);
    8000219c:	854a                	mv	a0,s2
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	afa080e7          	jalr	-1286(ra) # 80000c98 <release>
    800021a6:	b7f1                	j	80002172 <scheduler_fcfs+0x70>
      make_acquired_process_running(c, p);
    800021a8:	85a6                	mv	a1,s1
    800021aa:	855e                	mv	a0,s7
    800021ac:	00000097          	auipc	ra,0x0
    800021b0:	dfe080e7          	jalr	-514(ra) # 80001faa <make_acquired_process_running>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021b4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021b8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021bc:	10079073          	csrw	sstatus,a5
    for(curr = proc; curr < &proc[NPROC]; p++) {
    800021c0:	8962                	mv	s2,s8
    p = NULL;
    800021c2:	4481                	li	s1,0
    800021c4:	bf5d                	j	8000217a <scheduler_fcfs+0x78>

00000000800021c6 <sched>:
{
    800021c6:	7179                	addi	sp,sp,-48
    800021c8:	f406                	sd	ra,40(sp)
    800021ca:	f022                	sd	s0,32(sp)
    800021cc:	ec26                	sd	s1,24(sp)
    800021ce:	e84a                	sd	s2,16(sp)
    800021d0:	e44e                	sd	s3,8(sp)
    800021d2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	7f0080e7          	jalr	2032(ra) # 800019c4 <myproc>
    800021dc:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	98c080e7          	jalr	-1652(ra) # 80000b6a <holding>
    800021e6:	c93d                	beqz	a0,8000225c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021e8:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800021ea:	2781                	sext.w	a5,a5
    800021ec:	079e                	slli	a5,a5,0x7
    800021ee:	0000f717          	auipc	a4,0xf
    800021f2:	0b270713          	addi	a4,a4,178 # 800112a0 <pid_lock>
    800021f6:	97ba                	add	a5,a5,a4
    800021f8:	0a87a703          	lw	a4,168(a5)
    800021fc:	4785                	li	a5,1
    800021fe:	06f71763          	bne	a4,a5,8000226c <sched+0xa6>
  if(p->state == RUNNING)
    80002202:	4c98                	lw	a4,24(s1)
    80002204:	4791                	li	a5,4
    80002206:	06f70b63          	beq	a4,a5,8000227c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000220a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000220e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002210:	efb5                	bnez	a5,8000228c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002212:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002214:	0000f917          	auipc	s2,0xf
    80002218:	08c90913          	addi	s2,s2,140 # 800112a0 <pid_lock>
    8000221c:	2781                	sext.w	a5,a5
    8000221e:	079e                	slli	a5,a5,0x7
    80002220:	97ca                	add	a5,a5,s2
    80002222:	0ac7a983          	lw	s3,172(a5)
    80002226:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002228:	2781                	sext.w	a5,a5
    8000222a:	079e                	slli	a5,a5,0x7
    8000222c:	0000f597          	auipc	a1,0xf
    80002230:	0ac58593          	addi	a1,a1,172 # 800112d8 <cpus+0x8>
    80002234:	95be                	add	a1,a1,a5
    80002236:	06848513          	addi	a0,s1,104
    8000223a:	00000097          	auipc	ra,0x0
    8000223e:	63c080e7          	jalr	1596(ra) # 80002876 <swtch>
    80002242:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002244:	2781                	sext.w	a5,a5
    80002246:	079e                	slli	a5,a5,0x7
    80002248:	97ca                	add	a5,a5,s2
    8000224a:	0b37a623          	sw	s3,172(a5)
}
    8000224e:	70a2                	ld	ra,40(sp)
    80002250:	7402                	ld	s0,32(sp)
    80002252:	64e2                	ld	s1,24(sp)
    80002254:	6942                	ld	s2,16(sp)
    80002256:	69a2                	ld	s3,8(sp)
    80002258:	6145                	addi	sp,sp,48
    8000225a:	8082                	ret
    panic("sched p->lock");
    8000225c:	00006517          	auipc	a0,0x6
    80002260:	fd450513          	addi	a0,a0,-44 # 80008230 <digits+0x1f0>
    80002264:	ffffe097          	auipc	ra,0xffffe
    80002268:	2da080e7          	jalr	730(ra) # 8000053e <panic>
    panic("sched locks");
    8000226c:	00006517          	auipc	a0,0x6
    80002270:	fd450513          	addi	a0,a0,-44 # 80008240 <digits+0x200>
    80002274:	ffffe097          	auipc	ra,0xffffe
    80002278:	2ca080e7          	jalr	714(ra) # 8000053e <panic>
    panic("sched running");
    8000227c:	00006517          	auipc	a0,0x6
    80002280:	fd450513          	addi	a0,a0,-44 # 80008250 <digits+0x210>
    80002284:	ffffe097          	auipc	ra,0xffffe
    80002288:	2ba080e7          	jalr	698(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000228c:	00006517          	auipc	a0,0x6
    80002290:	fd450513          	addi	a0,a0,-44 # 80008260 <digits+0x220>
    80002294:	ffffe097          	auipc	ra,0xffffe
    80002298:	2aa080e7          	jalr	682(ra) # 8000053e <panic>

000000008000229c <yield>:
{
    8000229c:	1101                	addi	sp,sp,-32
    8000229e:	ec06                	sd	ra,24(sp)
    800022a0:	e822                	sd	s0,16(sp)
    800022a2:	e426                	sd	s1,8(sp)
    800022a4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	71e080e7          	jalr	1822(ra) # 800019c4 <myproc>
    800022ae:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	934080e7          	jalr	-1740(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800022b8:	478d                	li	a5,3
    800022ba:	cc9c                	sw	a5,24(s1)
  sched();
    800022bc:	00000097          	auipc	ra,0x0
    800022c0:	f0a080e7          	jalr	-246(ra) # 800021c6 <sched>
  release(&p->lock);
    800022c4:	8526                	mv	a0,s1
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	9d2080e7          	jalr	-1582(ra) # 80000c98 <release>
}
    800022ce:	60e2                	ld	ra,24(sp)
    800022d0:	6442                	ld	s0,16(sp)
    800022d2:	64a2                	ld	s1,8(sp)
    800022d4:	6105                	addi	sp,sp,32
    800022d6:	8082                	ret

00000000800022d8 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800022d8:	7179                	addi	sp,sp,-48
    800022da:	f406                	sd	ra,40(sp)
    800022dc:	f022                	sd	s0,32(sp)
    800022de:	ec26                	sd	s1,24(sp)
    800022e0:	e84a                	sd	s2,16(sp)
    800022e2:	e44e                	sd	s3,8(sp)
    800022e4:	1800                	addi	s0,sp,48
    800022e6:	89aa                	mv	s3,a0
    800022e8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	6da080e7          	jalr	1754(ra) # 800019c4 <myproc>
    800022f2:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	8f0080e7          	jalr	-1808(ra) # 80000be4 <acquire>
  release(lk);
    800022fc:	854a                	mv	a0,s2
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	99a080e7          	jalr	-1638(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002306:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000230a:	4789                	li	a5,2
    8000230c:	cc9c                	sw	a5,24(s1)

  sched();
    8000230e:	00000097          	auipc	ra,0x0
    80002312:	eb8080e7          	jalr	-328(ra) # 800021c6 <sched>

  // Tidy up.
  p->chan = 0;
    80002316:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000231a:	8526                	mv	a0,s1
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	97c080e7          	jalr	-1668(ra) # 80000c98 <release>
  acquire(lk);
    80002324:	854a                	mv	a0,s2
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	8be080e7          	jalr	-1858(ra) # 80000be4 <acquire>
}
    8000232e:	70a2                	ld	ra,40(sp)
    80002330:	7402                	ld	s0,32(sp)
    80002332:	64e2                	ld	s1,24(sp)
    80002334:	6942                	ld	s2,16(sp)
    80002336:	69a2                	ld	s3,8(sp)
    80002338:	6145                	addi	sp,sp,48
    8000233a:	8082                	ret

000000008000233c <wait>:
{
    8000233c:	715d                	addi	sp,sp,-80
    8000233e:	e486                	sd	ra,72(sp)
    80002340:	e0a2                	sd	s0,64(sp)
    80002342:	fc26                	sd	s1,56(sp)
    80002344:	f84a                	sd	s2,48(sp)
    80002346:	f44e                	sd	s3,40(sp)
    80002348:	f052                	sd	s4,32(sp)
    8000234a:	ec56                	sd	s5,24(sp)
    8000234c:	e85a                	sd	s6,16(sp)
    8000234e:	e45e                	sd	s7,8(sp)
    80002350:	e062                	sd	s8,0(sp)
    80002352:	0880                	addi	s0,sp,80
    80002354:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	66e080e7          	jalr	1646(ra) # 800019c4 <myproc>
    8000235e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002360:	0000f517          	auipc	a0,0xf
    80002364:	f5850513          	addi	a0,a0,-168 # 800112b8 <wait_lock>
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	87c080e7          	jalr	-1924(ra) # 80000be4 <acquire>
    havekids = 0;
    80002370:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002372:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002374:	00015997          	auipc	s3,0x15
    80002378:	f5c98993          	addi	s3,s3,-164 # 800172d0 <tickslock>
        havekids = 1;
    8000237c:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000237e:	0000fc17          	auipc	s8,0xf
    80002382:	f3ac0c13          	addi	s8,s8,-198 # 800112b8 <wait_lock>
    havekids = 0;
    80002386:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002388:	0000f497          	auipc	s1,0xf
    8000238c:	34848493          	addi	s1,s1,840 # 800116d0 <proc>
    80002390:	a0bd                	j	800023fe <wait+0xc2>
          pid = np->pid;
    80002392:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002396:	000b0e63          	beqz	s6,800023b2 <wait+0x76>
    8000239a:	4691                	li	a3,4
    8000239c:	02c48613          	addi	a2,s1,44
    800023a0:	85da                	mv	a1,s6
    800023a2:	05893503          	ld	a0,88(s2)
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	2d4080e7          	jalr	724(ra) # 8000167a <copyout>
    800023ae:	02054563          	bltz	a0,800023d8 <wait+0x9c>
          freeproc(np);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	7c2080e7          	jalr	1986(ra) # 80001b76 <freeproc>
          release(&np->lock);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	8da080e7          	jalr	-1830(ra) # 80000c98 <release>
          release(&wait_lock);
    800023c6:	0000f517          	auipc	a0,0xf
    800023ca:	ef250513          	addi	a0,a0,-270 # 800112b8 <wait_lock>
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	8ca080e7          	jalr	-1846(ra) # 80000c98 <release>
          return pid;
    800023d6:	a09d                	j	8000243c <wait+0x100>
            release(&np->lock);
    800023d8:	8526                	mv	a0,s1
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	8be080e7          	jalr	-1858(ra) # 80000c98 <release>
            release(&wait_lock);
    800023e2:	0000f517          	auipc	a0,0xf
    800023e6:	ed650513          	addi	a0,a0,-298 # 800112b8 <wait_lock>
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	8ae080e7          	jalr	-1874(ra) # 80000c98 <release>
            return -1;
    800023f2:	59fd                	li	s3,-1
    800023f4:	a0a1                	j	8000243c <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800023f6:	17048493          	addi	s1,s1,368
    800023fa:	03348463          	beq	s1,s3,80002422 <wait+0xe6>
      if(np->parent == p){
    800023fe:	60bc                	ld	a5,64(s1)
    80002400:	ff279be3          	bne	a5,s2,800023f6 <wait+0xba>
        acquire(&np->lock);
    80002404:	8526                	mv	a0,s1
    80002406:	ffffe097          	auipc	ra,0xffffe
    8000240a:	7de080e7          	jalr	2014(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000240e:	4c9c                	lw	a5,24(s1)
    80002410:	f94781e3          	beq	a5,s4,80002392 <wait+0x56>
        release(&np->lock);
    80002414:	8526                	mv	a0,s1
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	882080e7          	jalr	-1918(ra) # 80000c98 <release>
        havekids = 1;
    8000241e:	8756                	mv	a4,s5
    80002420:	bfd9                	j	800023f6 <wait+0xba>
    if(!havekids || p->killed){
    80002422:	c701                	beqz	a4,8000242a <wait+0xee>
    80002424:	02892783          	lw	a5,40(s2)
    80002428:	c79d                	beqz	a5,80002456 <wait+0x11a>
      release(&wait_lock);
    8000242a:	0000f517          	auipc	a0,0xf
    8000242e:	e8e50513          	addi	a0,a0,-370 # 800112b8 <wait_lock>
    80002432:	fffff097          	auipc	ra,0xfffff
    80002436:	866080e7          	jalr	-1946(ra) # 80000c98 <release>
      return -1;
    8000243a:	59fd                	li	s3,-1
}
    8000243c:	854e                	mv	a0,s3
    8000243e:	60a6                	ld	ra,72(sp)
    80002440:	6406                	ld	s0,64(sp)
    80002442:	74e2                	ld	s1,56(sp)
    80002444:	7942                	ld	s2,48(sp)
    80002446:	79a2                	ld	s3,40(sp)
    80002448:	7a02                	ld	s4,32(sp)
    8000244a:	6ae2                	ld	s5,24(sp)
    8000244c:	6b42                	ld	s6,16(sp)
    8000244e:	6ba2                	ld	s7,8(sp)
    80002450:	6c02                	ld	s8,0(sp)
    80002452:	6161                	addi	sp,sp,80
    80002454:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002456:	85e2                	mv	a1,s8
    80002458:	854a                	mv	a0,s2
    8000245a:	00000097          	auipc	ra,0x0
    8000245e:	e7e080e7          	jalr	-386(ra) # 800022d8 <sleep>
    havekids = 0;
    80002462:	b715                	j	80002386 <wait+0x4a>

0000000080002464 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002464:	7139                	addi	sp,sp,-64
    80002466:	fc06                	sd	ra,56(sp)
    80002468:	f822                	sd	s0,48(sp)
    8000246a:	f426                	sd	s1,40(sp)
    8000246c:	f04a                	sd	s2,32(sp)
    8000246e:	ec4e                	sd	s3,24(sp)
    80002470:	e852                	sd	s4,16(sp)
    80002472:	e456                	sd	s5,8(sp)
    80002474:	0080                	addi	s0,sp,64
    80002476:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002478:	0000f497          	auipc	s1,0xf
    8000247c:	25848493          	addi	s1,s1,600 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002480:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002482:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002484:	00015917          	auipc	s2,0x15
    80002488:	e4c90913          	addi	s2,s2,-436 # 800172d0 <tickslock>
    8000248c:	a821                	j	800024a4 <wakeup+0x40>
        p->state = RUNNABLE;
    8000248e:	0154ac23          	sw	s5,24(s1)
        update_last_runnable_time(p);
      }
      release(&p->lock);
    80002492:	8526                	mv	a0,s1
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	804080e7          	jalr	-2044(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000249c:	17048493          	addi	s1,s1,368
    800024a0:	03248463          	beq	s1,s2,800024c8 <wakeup+0x64>
    if(p != myproc()){
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	520080e7          	jalr	1312(ra) # 800019c4 <myproc>
    800024ac:	fea488e3          	beq	s1,a0,8000249c <wakeup+0x38>
      acquire(&p->lock);
    800024b0:	8526                	mv	a0,s1
    800024b2:	ffffe097          	auipc	ra,0xffffe
    800024b6:	732080e7          	jalr	1842(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800024ba:	4c9c                	lw	a5,24(s1)
    800024bc:	fd379be3          	bne	a5,s3,80002492 <wakeup+0x2e>
    800024c0:	709c                	ld	a5,32(s1)
    800024c2:	fd4798e3          	bne	a5,s4,80002492 <wakeup+0x2e>
    800024c6:	b7e1                	j	8000248e <wakeup+0x2a>
    }
  }
}
    800024c8:	70e2                	ld	ra,56(sp)
    800024ca:	7442                	ld	s0,48(sp)
    800024cc:	74a2                	ld	s1,40(sp)
    800024ce:	7902                	ld	s2,32(sp)
    800024d0:	69e2                	ld	s3,24(sp)
    800024d2:	6a42                	ld	s4,16(sp)
    800024d4:	6aa2                	ld	s5,8(sp)
    800024d6:	6121                	addi	sp,sp,64
    800024d8:	8082                	ret

00000000800024da <reparent>:
{
    800024da:	7179                	addi	sp,sp,-48
    800024dc:	f406                	sd	ra,40(sp)
    800024de:	f022                	sd	s0,32(sp)
    800024e0:	ec26                	sd	s1,24(sp)
    800024e2:	e84a                	sd	s2,16(sp)
    800024e4:	e44e                	sd	s3,8(sp)
    800024e6:	e052                	sd	s4,0(sp)
    800024e8:	1800                	addi	s0,sp,48
    800024ea:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800024ec:	0000f497          	auipc	s1,0xf
    800024f0:	1e448493          	addi	s1,s1,484 # 800116d0 <proc>
      pp->parent = initproc;
    800024f4:	00007a17          	auipc	s4,0x7
    800024f8:	b3ca0a13          	addi	s4,s4,-1220 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800024fc:	00015997          	auipc	s3,0x15
    80002500:	dd498993          	addi	s3,s3,-556 # 800172d0 <tickslock>
    80002504:	a029                	j	8000250e <reparent+0x34>
    80002506:	17048493          	addi	s1,s1,368
    8000250a:	01348d63          	beq	s1,s3,80002524 <reparent+0x4a>
    if(pp->parent == p){
    8000250e:	60bc                	ld	a5,64(s1)
    80002510:	ff279be3          	bne	a5,s2,80002506 <reparent+0x2c>
      pp->parent = initproc;
    80002514:	000a3503          	ld	a0,0(s4)
    80002518:	e0a8                	sd	a0,64(s1)
      wakeup(initproc);
    8000251a:	00000097          	auipc	ra,0x0
    8000251e:	f4a080e7          	jalr	-182(ra) # 80002464 <wakeup>
    80002522:	b7d5                	j	80002506 <reparent+0x2c>
}
    80002524:	70a2                	ld	ra,40(sp)
    80002526:	7402                	ld	s0,32(sp)
    80002528:	64e2                	ld	s1,24(sp)
    8000252a:	6942                	ld	s2,16(sp)
    8000252c:	69a2                	ld	s3,8(sp)
    8000252e:	6a02                	ld	s4,0(sp)
    80002530:	6145                	addi	sp,sp,48
    80002532:	8082                	ret

0000000080002534 <exit>:
{
    80002534:	7179                	addi	sp,sp,-48
    80002536:	f406                	sd	ra,40(sp)
    80002538:	f022                	sd	s0,32(sp)
    8000253a:	ec26                	sd	s1,24(sp)
    8000253c:	e84a                	sd	s2,16(sp)
    8000253e:	e44e                	sd	s3,8(sp)
    80002540:	e052                	sd	s4,0(sp)
    80002542:	1800                	addi	s0,sp,48
    80002544:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002546:	fffff097          	auipc	ra,0xfffff
    8000254a:	47e080e7          	jalr	1150(ra) # 800019c4 <myproc>
    8000254e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002550:	00007797          	auipc	a5,0x7
    80002554:	ae07b783          	ld	a5,-1312(a5) # 80009030 <initproc>
    80002558:	0d850493          	addi	s1,a0,216
    8000255c:	15850913          	addi	s2,a0,344
    80002560:	02a79363          	bne	a5,a0,80002586 <exit+0x52>
    panic("init exiting");
    80002564:	00006517          	auipc	a0,0x6
    80002568:	d1450513          	addi	a0,a0,-748 # 80008278 <digits+0x238>
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	fd2080e7          	jalr	-46(ra) # 8000053e <panic>
      fileclose(f);
    80002574:	00002097          	auipc	ra,0x2
    80002578:	250080e7          	jalr	592(ra) # 800047c4 <fileclose>
      p->ofile[fd] = 0;
    8000257c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002580:	04a1                	addi	s1,s1,8
    80002582:	01248563          	beq	s1,s2,8000258c <exit+0x58>
    if(p->ofile[fd]){
    80002586:	6088                	ld	a0,0(s1)
    80002588:	f575                	bnez	a0,80002574 <exit+0x40>
    8000258a:	bfdd                	j	80002580 <exit+0x4c>
  begin_op();
    8000258c:	00002097          	auipc	ra,0x2
    80002590:	d6c080e7          	jalr	-660(ra) # 800042f8 <begin_op>
  iput(p->cwd);
    80002594:	1589b503          	ld	a0,344(s3)
    80002598:	00001097          	auipc	ra,0x1
    8000259c:	548080e7          	jalr	1352(ra) # 80003ae0 <iput>
  end_op();
    800025a0:	00002097          	auipc	ra,0x2
    800025a4:	dd8080e7          	jalr	-552(ra) # 80004378 <end_op>
  p->cwd = 0;
    800025a8:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    800025ac:	0000f497          	auipc	s1,0xf
    800025b0:	d0c48493          	addi	s1,s1,-756 # 800112b8 <wait_lock>
    800025b4:	8526                	mv	a0,s1
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	62e080e7          	jalr	1582(ra) # 80000be4 <acquire>
  reparent(p);
    800025be:	854e                	mv	a0,s3
    800025c0:	00000097          	auipc	ra,0x0
    800025c4:	f1a080e7          	jalr	-230(ra) # 800024da <reparent>
  wakeup(p->parent);
    800025c8:	0409b503          	ld	a0,64(s3)
    800025cc:	00000097          	auipc	ra,0x0
    800025d0:	e98080e7          	jalr	-360(ra) # 80002464 <wakeup>
  acquire(&p->lock);
    800025d4:	854e                	mv	a0,s3
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	60e080e7          	jalr	1550(ra) # 80000be4 <acquire>
  p->xstate = status;
    800025de:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800025e2:	4795                	li	a5,5
    800025e4:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800025e8:	8526                	mv	a0,s1
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	6ae080e7          	jalr	1710(ra) # 80000c98 <release>
  sched();
    800025f2:	00000097          	auipc	ra,0x0
    800025f6:	bd4080e7          	jalr	-1068(ra) # 800021c6 <sched>
  panic("zombie exit");
    800025fa:	00006517          	auipc	a0,0x6
    800025fe:	c8e50513          	addi	a0,a0,-882 # 80008288 <digits+0x248>
    80002602:	ffffe097          	auipc	ra,0xffffe
    80002606:	f3c080e7          	jalr	-196(ra) # 8000053e <panic>

000000008000260a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000260a:	7179                	addi	sp,sp,-48
    8000260c:	f406                	sd	ra,40(sp)
    8000260e:	f022                	sd	s0,32(sp)
    80002610:	ec26                	sd	s1,24(sp)
    80002612:	e84a                	sd	s2,16(sp)
    80002614:	e44e                	sd	s3,8(sp)
    80002616:	1800                	addi	s0,sp,48
    80002618:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000261a:	0000f497          	auipc	s1,0xf
    8000261e:	0b648493          	addi	s1,s1,182 # 800116d0 <proc>
    80002622:	00015997          	auipc	s3,0x15
    80002626:	cae98993          	addi	s3,s3,-850 # 800172d0 <tickslock>
    acquire(&p->lock);
    8000262a:	8526                	mv	a0,s1
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	5b8080e7          	jalr	1464(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002634:	589c                	lw	a5,48(s1)
    80002636:	01278d63          	beq	a5,s2,80002650 <kill+0x46>
        update_last_runnable_time(p);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000263a:	8526                	mv	a0,s1
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	65c080e7          	jalr	1628(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002644:	17048493          	addi	s1,s1,368
    80002648:	ff3491e3          	bne	s1,s3,8000262a <kill+0x20>
  }
  return -1;
    8000264c:	557d                	li	a0,-1
    8000264e:	a829                	j	80002668 <kill+0x5e>
      p->killed = 1;
    80002650:	4785                	li	a5,1
    80002652:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002654:	4c98                	lw	a4,24(s1)
    80002656:	4789                	li	a5,2
    80002658:	00f70f63          	beq	a4,a5,80002676 <kill+0x6c>
      release(&p->lock);
    8000265c:	8526                	mv	a0,s1
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	63a080e7          	jalr	1594(ra) # 80000c98 <release>
      return 0;
    80002666:	4501                	li	a0,0
}
    80002668:	70a2                	ld	ra,40(sp)
    8000266a:	7402                	ld	s0,32(sp)
    8000266c:	64e2                	ld	s1,24(sp)
    8000266e:	6942                	ld	s2,16(sp)
    80002670:	69a2                	ld	s3,8(sp)
    80002672:	6145                	addi	sp,sp,48
    80002674:	8082                	ret
        p->state = RUNNABLE;
    80002676:	478d                	li	a5,3
    80002678:	cc9c                	sw	a5,24(s1)
        update_last_runnable_time(p);
    8000267a:	b7cd                	j	8000265c <kill+0x52>

000000008000267c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000267c:	7179                	addi	sp,sp,-48
    8000267e:	f406                	sd	ra,40(sp)
    80002680:	f022                	sd	s0,32(sp)
    80002682:	ec26                	sd	s1,24(sp)
    80002684:	e84a                	sd	s2,16(sp)
    80002686:	e44e                	sd	s3,8(sp)
    80002688:	e052                	sd	s4,0(sp)
    8000268a:	1800                	addi	s0,sp,48
    8000268c:	84aa                	mv	s1,a0
    8000268e:	892e                	mv	s2,a1
    80002690:	89b2                	mv	s3,a2
    80002692:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002694:	fffff097          	auipc	ra,0xfffff
    80002698:	330080e7          	jalr	816(ra) # 800019c4 <myproc>
  if(user_dst){
    8000269c:	c08d                	beqz	s1,800026be <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000269e:	86d2                	mv	a3,s4
    800026a0:	864e                	mv	a2,s3
    800026a2:	85ca                	mv	a1,s2
    800026a4:	6d28                	ld	a0,88(a0)
    800026a6:	fffff097          	auipc	ra,0xfffff
    800026aa:	fd4080e7          	jalr	-44(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026ae:	70a2                	ld	ra,40(sp)
    800026b0:	7402                	ld	s0,32(sp)
    800026b2:	64e2                	ld	s1,24(sp)
    800026b4:	6942                	ld	s2,16(sp)
    800026b6:	69a2                	ld	s3,8(sp)
    800026b8:	6a02                	ld	s4,0(sp)
    800026ba:	6145                	addi	sp,sp,48
    800026bc:	8082                	ret
    memmove((char *)dst, src, len);
    800026be:	000a061b          	sext.w	a2,s4
    800026c2:	85ce                	mv	a1,s3
    800026c4:	854a                	mv	a0,s2
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	67a080e7          	jalr	1658(ra) # 80000d40 <memmove>
    return 0;
    800026ce:	8526                	mv	a0,s1
    800026d0:	bff9                	j	800026ae <either_copyout+0x32>

00000000800026d2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026d2:	7179                	addi	sp,sp,-48
    800026d4:	f406                	sd	ra,40(sp)
    800026d6:	f022                	sd	s0,32(sp)
    800026d8:	ec26                	sd	s1,24(sp)
    800026da:	e84a                	sd	s2,16(sp)
    800026dc:	e44e                	sd	s3,8(sp)
    800026de:	e052                	sd	s4,0(sp)
    800026e0:	1800                	addi	s0,sp,48
    800026e2:	892a                	mv	s2,a0
    800026e4:	84ae                	mv	s1,a1
    800026e6:	89b2                	mv	s3,a2
    800026e8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026ea:	fffff097          	auipc	ra,0xfffff
    800026ee:	2da080e7          	jalr	730(ra) # 800019c4 <myproc>
  if(user_src){
    800026f2:	c08d                	beqz	s1,80002714 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026f4:	86d2                	mv	a3,s4
    800026f6:	864e                	mv	a2,s3
    800026f8:	85ca                	mv	a1,s2
    800026fa:	6d28                	ld	a0,88(a0)
    800026fc:	fffff097          	auipc	ra,0xfffff
    80002700:	00a080e7          	jalr	10(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002704:	70a2                	ld	ra,40(sp)
    80002706:	7402                	ld	s0,32(sp)
    80002708:	64e2                	ld	s1,24(sp)
    8000270a:	6942                	ld	s2,16(sp)
    8000270c:	69a2                	ld	s3,8(sp)
    8000270e:	6a02                	ld	s4,0(sp)
    80002710:	6145                	addi	sp,sp,48
    80002712:	8082                	ret
    memmove(dst, (char*)src, len);
    80002714:	000a061b          	sext.w	a2,s4
    80002718:	85ce                	mv	a1,s3
    8000271a:	854a                	mv	a0,s2
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	624080e7          	jalr	1572(ra) # 80000d40 <memmove>
    return 0;
    80002724:	8526                	mv	a0,s1
    80002726:	bff9                	j	80002704 <either_copyin+0x32>

0000000080002728 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002728:	715d                	addi	sp,sp,-80
    8000272a:	e486                	sd	ra,72(sp)
    8000272c:	e0a2                	sd	s0,64(sp)
    8000272e:	fc26                	sd	s1,56(sp)
    80002730:	f84a                	sd	s2,48(sp)
    80002732:	f44e                	sd	s3,40(sp)
    80002734:	f052                	sd	s4,32(sp)
    80002736:	ec56                	sd	s5,24(sp)
    80002738:	e85a                	sd	s6,16(sp)
    8000273a:	e45e                	sd	s7,8(sp)
    8000273c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000273e:	00006517          	auipc	a0,0x6
    80002742:	98a50513          	addi	a0,a0,-1654 # 800080c8 <digits+0x88>
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	e42080e7          	jalr	-446(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000274e:	0000f497          	auipc	s1,0xf
    80002752:	0e248493          	addi	s1,s1,226 # 80011830 <proc+0x160>
    80002756:	00015917          	auipc	s2,0x15
    8000275a:	cda90913          	addi	s2,s2,-806 # 80017430 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000275e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002760:	00006997          	auipc	s3,0x6
    80002764:	b3898993          	addi	s3,s3,-1224 # 80008298 <digits+0x258>
    printf("%d %s %s", p->pid, state, p->name);
    80002768:	00006a97          	auipc	s5,0x6
    8000276c:	b38a8a93          	addi	s5,s5,-1224 # 800082a0 <digits+0x260>
    printf("\n");
    80002770:	00006a17          	auipc	s4,0x6
    80002774:	958a0a13          	addi	s4,s4,-1704 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002778:	00006b97          	auipc	s7,0x6
    8000277c:	b60b8b93          	addi	s7,s7,-1184 # 800082d8 <states.1766>
    80002780:	a00d                	j	800027a2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002782:	ed06a583          	lw	a1,-304(a3)
    80002786:	8556                	mv	a0,s5
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	e00080e7          	jalr	-512(ra) # 80000588 <printf>
    printf("\n");
    80002790:	8552                	mv	a0,s4
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	df6080e7          	jalr	-522(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000279a:	17048493          	addi	s1,s1,368
    8000279e:	03248163          	beq	s1,s2,800027c0 <procdump+0x98>
    if(p->state == UNUSED)
    800027a2:	86a6                	mv	a3,s1
    800027a4:	eb84a783          	lw	a5,-328(s1)
    800027a8:	dbed                	beqz	a5,8000279a <procdump+0x72>
      state = "???";
    800027aa:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027ac:	fcfb6be3          	bltu	s6,a5,80002782 <procdump+0x5a>
    800027b0:	1782                	slli	a5,a5,0x20
    800027b2:	9381                	srli	a5,a5,0x20
    800027b4:	078e                	slli	a5,a5,0x3
    800027b6:	97de                	add	a5,a5,s7
    800027b8:	6390                	ld	a2,0(a5)
    800027ba:	f661                	bnez	a2,80002782 <procdump+0x5a>
      state = "???";
    800027bc:	864e                	mv	a2,s3
    800027be:	b7d1                	j	80002782 <procdump+0x5a>
  }
}
    800027c0:	60a6                	ld	ra,72(sp)
    800027c2:	6406                	ld	s0,64(sp)
    800027c4:	74e2                	ld	s1,56(sp)
    800027c6:	7942                	ld	s2,48(sp)
    800027c8:	79a2                	ld	s3,40(sp)
    800027ca:	7a02                	ld	s4,32(sp)
    800027cc:	6ae2                	ld	s5,24(sp)
    800027ce:	6b42                	ld	s6,16(sp)
    800027d0:	6ba2                	ld	s7,8(sp)
    800027d2:	6161                	addi	sp,sp,80
    800027d4:	8082                	ret

00000000800027d6 <pause_system>:

// pause all user processes for the number of seconds specified by thesecond's integer parameter.
int pause_system(int seconds){
    800027d6:	1141                	addi	sp,sp,-16
    800027d8:	e406                	sd	ra,8(sp)
    800027da:	e022                	sd	s0,0(sp)
    800027dc:	0800                	addi	s0,sp,16
  pause_ticks = ticks + seconds * SECONDS_TO_TICKS;
    800027de:	0025179b          	slliw	a5,a0,0x2
    800027e2:	9fa9                	addw	a5,a5,a0
    800027e4:	0017979b          	slliw	a5,a5,0x1
    800027e8:	00007517          	auipc	a0,0x7
    800027ec:	85052503          	lw	a0,-1968(a0) # 80009038 <ticks>
    800027f0:	9fa9                	addw	a5,a5,a0
    800027f2:	00007717          	auipc	a4,0x7
    800027f6:	82f72b23          	sw	a5,-1994(a4) # 80009028 <pause_ticks>
  yield();
    800027fa:	00000097          	auipc	ra,0x0
    800027fe:	aa2080e7          	jalr	-1374(ra) # 8000229c <yield>

  return 0;
}
    80002802:	4501                	li	a0,0
    80002804:	60a2                	ld	ra,8(sp)
    80002806:	6402                	ld	s0,0(sp)
    80002808:	0141                	addi	sp,sp,16
    8000280a:	8082                	ret

000000008000280c <kill_system>:

// terminate all user processes
int 
kill_system(void) {
    8000280c:	7179                	addi	sp,sp,-48
    8000280e:	f406                	sd	ra,40(sp)
    80002810:	f022                	sd	s0,32(sp)
    80002812:	ec26                	sd	s1,24(sp)
    80002814:	e84a                	sd	s2,16(sp)
    80002816:	e44e                	sd	s3,8(sp)
    80002818:	e052                	sd	s4,0(sp)
    8000281a:	1800                	addi	s0,sp,48
  struct proc *p;
  int pid;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000281c:	0000f497          	auipc	s1,0xf
    80002820:	eb448493          	addi	s1,s1,-332 # 800116d0 <proc>
      acquire(&p->lock);
      pid = p->pid;
      release(&p->lock);
      if(pid != INIT_PROC_ID && pid != SHELL_PROC_ID)
    80002824:	4a05                	li	s4,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80002826:	00015997          	auipc	s3,0x15
    8000282a:	aaa98993          	addi	s3,s3,-1366 # 800172d0 <tickslock>
    8000282e:	a029                	j	80002838 <kill_system+0x2c>
    80002830:	17048493          	addi	s1,s1,368
    80002834:	03348863          	beq	s1,s3,80002864 <kill_system+0x58>
      acquire(&p->lock);
    80002838:	8526                	mv	a0,s1
    8000283a:	ffffe097          	auipc	ra,0xffffe
    8000283e:	3aa080e7          	jalr	938(ra) # 80000be4 <acquire>
      pid = p->pid;
    80002842:	0304a903          	lw	s2,48(s1)
      release(&p->lock);
    80002846:	8526                	mv	a0,s1
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	450080e7          	jalr	1104(ra) # 80000c98 <release>
      if(pid != INIT_PROC_ID && pid != SHELL_PROC_ID)
    80002850:	fff9079b          	addiw	a5,s2,-1
    80002854:	fcfa7ee3          	bgeu	s4,a5,80002830 <kill_system+0x24>
        kill(pid);
    80002858:	854a                	mv	a0,s2
    8000285a:	00000097          	auipc	ra,0x0
    8000285e:	db0080e7          	jalr	-592(ra) # 8000260a <kill>
    80002862:	b7f9                	j	80002830 <kill_system+0x24>
  }
  return 0;
}
    80002864:	4501                	li	a0,0
    80002866:	70a2                	ld	ra,40(sp)
    80002868:	7402                	ld	s0,32(sp)
    8000286a:	64e2                	ld	s1,24(sp)
    8000286c:	6942                	ld	s2,16(sp)
    8000286e:	69a2                	ld	s3,8(sp)
    80002870:	6a02                	ld	s4,0(sp)
    80002872:	6145                	addi	sp,sp,48
    80002874:	8082                	ret

0000000080002876 <swtch>:
    80002876:	00153023          	sd	ra,0(a0)
    8000287a:	00253423          	sd	sp,8(a0)
    8000287e:	e900                	sd	s0,16(a0)
    80002880:	ed04                	sd	s1,24(a0)
    80002882:	03253023          	sd	s2,32(a0)
    80002886:	03353423          	sd	s3,40(a0)
    8000288a:	03453823          	sd	s4,48(a0)
    8000288e:	03553c23          	sd	s5,56(a0)
    80002892:	05653023          	sd	s6,64(a0)
    80002896:	05753423          	sd	s7,72(a0)
    8000289a:	05853823          	sd	s8,80(a0)
    8000289e:	05953c23          	sd	s9,88(a0)
    800028a2:	07a53023          	sd	s10,96(a0)
    800028a6:	07b53423          	sd	s11,104(a0)
    800028aa:	0005b083          	ld	ra,0(a1)
    800028ae:	0085b103          	ld	sp,8(a1)
    800028b2:	6980                	ld	s0,16(a1)
    800028b4:	6d84                	ld	s1,24(a1)
    800028b6:	0205b903          	ld	s2,32(a1)
    800028ba:	0285b983          	ld	s3,40(a1)
    800028be:	0305ba03          	ld	s4,48(a1)
    800028c2:	0385ba83          	ld	s5,56(a1)
    800028c6:	0405bb03          	ld	s6,64(a1)
    800028ca:	0485bb83          	ld	s7,72(a1)
    800028ce:	0505bc03          	ld	s8,80(a1)
    800028d2:	0585bc83          	ld	s9,88(a1)
    800028d6:	0605bd03          	ld	s10,96(a1)
    800028da:	0685bd83          	ld	s11,104(a1)
    800028de:	8082                	ret

00000000800028e0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800028e0:	1141                	addi	sp,sp,-16
    800028e2:	e406                	sd	ra,8(sp)
    800028e4:	e022                	sd	s0,0(sp)
    800028e6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800028e8:	00006597          	auipc	a1,0x6
    800028ec:	a2058593          	addi	a1,a1,-1504 # 80008308 <states.1766+0x30>
    800028f0:	00015517          	auipc	a0,0x15
    800028f4:	9e050513          	addi	a0,a0,-1568 # 800172d0 <tickslock>
    800028f8:	ffffe097          	auipc	ra,0xffffe
    800028fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
}
    80002900:	60a2                	ld	ra,8(sp)
    80002902:	6402                	ld	s0,0(sp)
    80002904:	0141                	addi	sp,sp,16
    80002906:	8082                	ret

0000000080002908 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002908:	1141                	addi	sp,sp,-16
    8000290a:	e422                	sd	s0,8(sp)
    8000290c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000290e:	00003797          	auipc	a5,0x3
    80002912:	4d278793          	addi	a5,a5,1234 # 80005de0 <kernelvec>
    80002916:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000291a:	6422                	ld	s0,8(sp)
    8000291c:	0141                	addi	sp,sp,16
    8000291e:	8082                	ret

0000000080002920 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002920:	1141                	addi	sp,sp,-16
    80002922:	e406                	sd	ra,8(sp)
    80002924:	e022                	sd	s0,0(sp)
    80002926:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002928:	fffff097          	auipc	ra,0xfffff
    8000292c:	09c080e7          	jalr	156(ra) # 800019c4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002930:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002934:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002936:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000293a:	00004617          	auipc	a2,0x4
    8000293e:	6c660613          	addi	a2,a2,1734 # 80007000 <_trampoline>
    80002942:	00004697          	auipc	a3,0x4
    80002946:	6be68693          	addi	a3,a3,1726 # 80007000 <_trampoline>
    8000294a:	8e91                	sub	a3,a3,a2
    8000294c:	040007b7          	lui	a5,0x4000
    80002950:	17fd                	addi	a5,a5,-1
    80002952:	07b2                	slli	a5,a5,0xc
    80002954:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002956:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000295a:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000295c:	180026f3          	csrr	a3,satp
    80002960:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002962:	7138                	ld	a4,96(a0)
    80002964:	6534                	ld	a3,72(a0)
    80002966:	6585                	lui	a1,0x1
    80002968:	96ae                	add	a3,a3,a1
    8000296a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000296c:	7138                	ld	a4,96(a0)
    8000296e:	00000697          	auipc	a3,0x0
    80002972:	13868693          	addi	a3,a3,312 # 80002aa6 <usertrap>
    80002976:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002978:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000297a:	8692                	mv	a3,tp
    8000297c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000297e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002982:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002986:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000298a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000298e:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002990:	6f18                	ld	a4,24(a4)
    80002992:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002996:	6d2c                	ld	a1,88(a0)
    80002998:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000299a:	00004717          	auipc	a4,0x4
    8000299e:	6f670713          	addi	a4,a4,1782 # 80007090 <userret>
    800029a2:	8f11                	sub	a4,a4,a2
    800029a4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029a6:	577d                	li	a4,-1
    800029a8:	177e                	slli	a4,a4,0x3f
    800029aa:	8dd9                	or	a1,a1,a4
    800029ac:	02000537          	lui	a0,0x2000
    800029b0:	157d                	addi	a0,a0,-1
    800029b2:	0536                	slli	a0,a0,0xd
    800029b4:	9782                	jalr	a5
}
    800029b6:	60a2                	ld	ra,8(sp)
    800029b8:	6402                	ld	s0,0(sp)
    800029ba:	0141                	addi	sp,sp,16
    800029bc:	8082                	ret

00000000800029be <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029be:	1101                	addi	sp,sp,-32
    800029c0:	ec06                	sd	ra,24(sp)
    800029c2:	e822                	sd	s0,16(sp)
    800029c4:	e426                	sd	s1,8(sp)
    800029c6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029c8:	00015497          	auipc	s1,0x15
    800029cc:	90848493          	addi	s1,s1,-1784 # 800172d0 <tickslock>
    800029d0:	8526                	mv	a0,s1
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	212080e7          	jalr	530(ra) # 80000be4 <acquire>
  ticks++;
    800029da:	00006517          	auipc	a0,0x6
    800029de:	65e50513          	addi	a0,a0,1630 # 80009038 <ticks>
    800029e2:	411c                	lw	a5,0(a0)
    800029e4:	2785                	addiw	a5,a5,1
    800029e6:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800029e8:	00000097          	auipc	ra,0x0
    800029ec:	a7c080e7          	jalr	-1412(ra) # 80002464 <wakeup>
  release(&tickslock);
    800029f0:	8526                	mv	a0,s1
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	2a6080e7          	jalr	678(ra) # 80000c98 <release>
}
    800029fa:	60e2                	ld	ra,24(sp)
    800029fc:	6442                	ld	s0,16(sp)
    800029fe:	64a2                	ld	s1,8(sp)
    80002a00:	6105                	addi	sp,sp,32
    80002a02:	8082                	ret

0000000080002a04 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a04:	1101                	addi	sp,sp,-32
    80002a06:	ec06                	sd	ra,24(sp)
    80002a08:	e822                	sd	s0,16(sp)
    80002a0a:	e426                	sd	s1,8(sp)
    80002a0c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a0e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a12:	00074d63          	bltz	a4,80002a2c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a16:	57fd                	li	a5,-1
    80002a18:	17fe                	slli	a5,a5,0x3f
    80002a1a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a1c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a1e:	06f70363          	beq	a4,a5,80002a84 <devintr+0x80>
  }
}
    80002a22:	60e2                	ld	ra,24(sp)
    80002a24:	6442                	ld	s0,16(sp)
    80002a26:	64a2                	ld	s1,8(sp)
    80002a28:	6105                	addi	sp,sp,32
    80002a2a:	8082                	ret
     (scause & 0xff) == 9){
    80002a2c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a30:	46a5                	li	a3,9
    80002a32:	fed792e3          	bne	a5,a3,80002a16 <devintr+0x12>
    int irq = plic_claim();
    80002a36:	00003097          	auipc	ra,0x3
    80002a3a:	4b2080e7          	jalr	1202(ra) # 80005ee8 <plic_claim>
    80002a3e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a40:	47a9                	li	a5,10
    80002a42:	02f50763          	beq	a0,a5,80002a70 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a46:	4785                	li	a5,1
    80002a48:	02f50963          	beq	a0,a5,80002a7a <devintr+0x76>
    return 1;
    80002a4c:	4505                	li	a0,1
    } else if(irq){
    80002a4e:	d8f1                	beqz	s1,80002a22 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a50:	85a6                	mv	a1,s1
    80002a52:	00006517          	auipc	a0,0x6
    80002a56:	8be50513          	addi	a0,a0,-1858 # 80008310 <states.1766+0x38>
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	b2e080e7          	jalr	-1234(ra) # 80000588 <printf>
      plic_complete(irq);
    80002a62:	8526                	mv	a0,s1
    80002a64:	00003097          	auipc	ra,0x3
    80002a68:	4a8080e7          	jalr	1192(ra) # 80005f0c <plic_complete>
    return 1;
    80002a6c:	4505                	li	a0,1
    80002a6e:	bf55                	j	80002a22 <devintr+0x1e>
      uartintr();
    80002a70:	ffffe097          	auipc	ra,0xffffe
    80002a74:	f38080e7          	jalr	-200(ra) # 800009a8 <uartintr>
    80002a78:	b7ed                	j	80002a62 <devintr+0x5e>
      virtio_disk_intr();
    80002a7a:	00004097          	auipc	ra,0x4
    80002a7e:	972080e7          	jalr	-1678(ra) # 800063ec <virtio_disk_intr>
    80002a82:	b7c5                	j	80002a62 <devintr+0x5e>
    if(cpuid() == 0){
    80002a84:	fffff097          	auipc	ra,0xfffff
    80002a88:	f14080e7          	jalr	-236(ra) # 80001998 <cpuid>
    80002a8c:	c901                	beqz	a0,80002a9c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a8e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a92:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a94:	14479073          	csrw	sip,a5
    return 2;
    80002a98:	4509                	li	a0,2
    80002a9a:	b761                	j	80002a22 <devintr+0x1e>
      clockintr();
    80002a9c:	00000097          	auipc	ra,0x0
    80002aa0:	f22080e7          	jalr	-222(ra) # 800029be <clockintr>
    80002aa4:	b7ed                	j	80002a8e <devintr+0x8a>

0000000080002aa6 <usertrap>:
{
    80002aa6:	1101                	addi	sp,sp,-32
    80002aa8:	ec06                	sd	ra,24(sp)
    80002aaa:	e822                	sd	s0,16(sp)
    80002aac:	e426                	sd	s1,8(sp)
    80002aae:	e04a                	sd	s2,0(sp)
    80002ab0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ab6:	1007f793          	andi	a5,a5,256
    80002aba:	e3ad                	bnez	a5,80002b1c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002abc:	00003797          	auipc	a5,0x3
    80002ac0:	32478793          	addi	a5,a5,804 # 80005de0 <kernelvec>
    80002ac4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ac8:	fffff097          	auipc	ra,0xfffff
    80002acc:	efc080e7          	jalr	-260(ra) # 800019c4 <myproc>
    80002ad0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ad2:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ad4:	14102773          	csrr	a4,sepc
    80002ad8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ada:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ade:	47a1                	li	a5,8
    80002ae0:	04f71c63          	bne	a4,a5,80002b38 <usertrap+0x92>
    if(p->killed)
    80002ae4:	551c                	lw	a5,40(a0)
    80002ae6:	e3b9                	bnez	a5,80002b2c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002ae8:	70b8                	ld	a4,96(s1)
    80002aea:	6f1c                	ld	a5,24(a4)
    80002aec:	0791                	addi	a5,a5,4
    80002aee:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002af0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002af4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002af8:	10079073          	csrw	sstatus,a5
    syscall();
    80002afc:	00000097          	auipc	ra,0x0
    80002b00:	2e0080e7          	jalr	736(ra) # 80002ddc <syscall>
  if(p->killed)
    80002b04:	549c                	lw	a5,40(s1)
    80002b06:	ebc1                	bnez	a5,80002b96 <usertrap+0xf0>
  usertrapret();
    80002b08:	00000097          	auipc	ra,0x0
    80002b0c:	e18080e7          	jalr	-488(ra) # 80002920 <usertrapret>
}
    80002b10:	60e2                	ld	ra,24(sp)
    80002b12:	6442                	ld	s0,16(sp)
    80002b14:	64a2                	ld	s1,8(sp)
    80002b16:	6902                	ld	s2,0(sp)
    80002b18:	6105                	addi	sp,sp,32
    80002b1a:	8082                	ret
    panic("usertrap: not from user mode");
    80002b1c:	00006517          	auipc	a0,0x6
    80002b20:	81450513          	addi	a0,a0,-2028 # 80008330 <states.1766+0x58>
    80002b24:	ffffe097          	auipc	ra,0xffffe
    80002b28:	a1a080e7          	jalr	-1510(ra) # 8000053e <panic>
      exit(-1);
    80002b2c:	557d                	li	a0,-1
    80002b2e:	00000097          	auipc	ra,0x0
    80002b32:	a06080e7          	jalr	-1530(ra) # 80002534 <exit>
    80002b36:	bf4d                	j	80002ae8 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b38:	00000097          	auipc	ra,0x0
    80002b3c:	ecc080e7          	jalr	-308(ra) # 80002a04 <devintr>
    80002b40:	892a                	mv	s2,a0
    80002b42:	c501                	beqz	a0,80002b4a <usertrap+0xa4>
  if(p->killed)
    80002b44:	549c                	lw	a5,40(s1)
    80002b46:	c3a1                	beqz	a5,80002b86 <usertrap+0xe0>
    80002b48:	a815                	j	80002b7c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b4a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b4e:	5890                	lw	a2,48(s1)
    80002b50:	00006517          	auipc	a0,0x6
    80002b54:	80050513          	addi	a0,a0,-2048 # 80008350 <states.1766+0x78>
    80002b58:	ffffe097          	auipc	ra,0xffffe
    80002b5c:	a30080e7          	jalr	-1488(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b60:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b64:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b68:	00006517          	auipc	a0,0x6
    80002b6c:	81850513          	addi	a0,a0,-2024 # 80008380 <states.1766+0xa8>
    80002b70:	ffffe097          	auipc	ra,0xffffe
    80002b74:	a18080e7          	jalr	-1512(ra) # 80000588 <printf>
    p->killed = 1;
    80002b78:	4785                	li	a5,1
    80002b7a:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002b7c:	557d                	li	a0,-1
    80002b7e:	00000097          	auipc	ra,0x0
    80002b82:	9b6080e7          	jalr	-1610(ra) # 80002534 <exit>
  if(which_dev == 2)
    80002b86:	4789                	li	a5,2
    80002b88:	f8f910e3          	bne	s2,a5,80002b08 <usertrap+0x62>
    yield();
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	710080e7          	jalr	1808(ra) # 8000229c <yield>
    80002b94:	bf95                	j	80002b08 <usertrap+0x62>
  int which_dev = 0;
    80002b96:	4901                	li	s2,0
    80002b98:	b7d5                	j	80002b7c <usertrap+0xd6>

0000000080002b9a <kerneltrap>:
{
    80002b9a:	7179                	addi	sp,sp,-48
    80002b9c:	f406                	sd	ra,40(sp)
    80002b9e:	f022                	sd	s0,32(sp)
    80002ba0:	ec26                	sd	s1,24(sp)
    80002ba2:	e84a                	sd	s2,16(sp)
    80002ba4:	e44e                	sd	s3,8(sp)
    80002ba6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ba8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bac:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bb0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bb4:	1004f793          	andi	a5,s1,256
    80002bb8:	cb85                	beqz	a5,80002be8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bba:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bbe:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002bc0:	ef85                	bnez	a5,80002bf8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002bc2:	00000097          	auipc	ra,0x0
    80002bc6:	e42080e7          	jalr	-446(ra) # 80002a04 <devintr>
    80002bca:	cd1d                	beqz	a0,80002c08 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bcc:	4789                	li	a5,2
    80002bce:	06f50a63          	beq	a0,a5,80002c42 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bd2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bd6:	10049073          	csrw	sstatus,s1
}
    80002bda:	70a2                	ld	ra,40(sp)
    80002bdc:	7402                	ld	s0,32(sp)
    80002bde:	64e2                	ld	s1,24(sp)
    80002be0:	6942                	ld	s2,16(sp)
    80002be2:	69a2                	ld	s3,8(sp)
    80002be4:	6145                	addi	sp,sp,48
    80002be6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002be8:	00005517          	auipc	a0,0x5
    80002bec:	7b850513          	addi	a0,a0,1976 # 800083a0 <states.1766+0xc8>
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	94e080e7          	jalr	-1714(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002bf8:	00005517          	auipc	a0,0x5
    80002bfc:	7d050513          	addi	a0,a0,2000 # 800083c8 <states.1766+0xf0>
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	93e080e7          	jalr	-1730(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002c08:	85ce                	mv	a1,s3
    80002c0a:	00005517          	auipc	a0,0x5
    80002c0e:	7de50513          	addi	a0,a0,2014 # 800083e8 <states.1766+0x110>
    80002c12:	ffffe097          	auipc	ra,0xffffe
    80002c16:	976080e7          	jalr	-1674(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c1a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c1e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c22:	00005517          	auipc	a0,0x5
    80002c26:	7d650513          	addi	a0,a0,2006 # 800083f8 <states.1766+0x120>
    80002c2a:	ffffe097          	auipc	ra,0xffffe
    80002c2e:	95e080e7          	jalr	-1698(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002c32:	00005517          	auipc	a0,0x5
    80002c36:	7de50513          	addi	a0,a0,2014 # 80008410 <states.1766+0x138>
    80002c3a:	ffffe097          	auipc	ra,0xffffe
    80002c3e:	904080e7          	jalr	-1788(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c42:	fffff097          	auipc	ra,0xfffff
    80002c46:	d82080e7          	jalr	-638(ra) # 800019c4 <myproc>
    80002c4a:	d541                	beqz	a0,80002bd2 <kerneltrap+0x38>
    80002c4c:	fffff097          	auipc	ra,0xfffff
    80002c50:	d78080e7          	jalr	-648(ra) # 800019c4 <myproc>
    80002c54:	4d18                	lw	a4,24(a0)
    80002c56:	4791                	li	a5,4
    80002c58:	f6f71de3          	bne	a4,a5,80002bd2 <kerneltrap+0x38>
    yield();
    80002c5c:	fffff097          	auipc	ra,0xfffff
    80002c60:	640080e7          	jalr	1600(ra) # 8000229c <yield>
    80002c64:	b7bd                	j	80002bd2 <kerneltrap+0x38>

0000000080002c66 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c66:	1101                	addi	sp,sp,-32
    80002c68:	ec06                	sd	ra,24(sp)
    80002c6a:	e822                	sd	s0,16(sp)
    80002c6c:	e426                	sd	s1,8(sp)
    80002c6e:	1000                	addi	s0,sp,32
    80002c70:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c72:	fffff097          	auipc	ra,0xfffff
    80002c76:	d52080e7          	jalr	-686(ra) # 800019c4 <myproc>
  switch (n) {
    80002c7a:	4795                	li	a5,5
    80002c7c:	0497e163          	bltu	a5,s1,80002cbe <argraw+0x58>
    80002c80:	048a                	slli	s1,s1,0x2
    80002c82:	00005717          	auipc	a4,0x5
    80002c86:	7c670713          	addi	a4,a4,1990 # 80008448 <states.1766+0x170>
    80002c8a:	94ba                	add	s1,s1,a4
    80002c8c:	409c                	lw	a5,0(s1)
    80002c8e:	97ba                	add	a5,a5,a4
    80002c90:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c92:	713c                	ld	a5,96(a0)
    80002c94:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c96:	60e2                	ld	ra,24(sp)
    80002c98:	6442                	ld	s0,16(sp)
    80002c9a:	64a2                	ld	s1,8(sp)
    80002c9c:	6105                	addi	sp,sp,32
    80002c9e:	8082                	ret
    return p->trapframe->a1;
    80002ca0:	713c                	ld	a5,96(a0)
    80002ca2:	7fa8                	ld	a0,120(a5)
    80002ca4:	bfcd                	j	80002c96 <argraw+0x30>
    return p->trapframe->a2;
    80002ca6:	713c                	ld	a5,96(a0)
    80002ca8:	63c8                	ld	a0,128(a5)
    80002caa:	b7f5                	j	80002c96 <argraw+0x30>
    return p->trapframe->a3;
    80002cac:	713c                	ld	a5,96(a0)
    80002cae:	67c8                	ld	a0,136(a5)
    80002cb0:	b7dd                	j	80002c96 <argraw+0x30>
    return p->trapframe->a4;
    80002cb2:	713c                	ld	a5,96(a0)
    80002cb4:	6bc8                	ld	a0,144(a5)
    80002cb6:	b7c5                	j	80002c96 <argraw+0x30>
    return p->trapframe->a5;
    80002cb8:	713c                	ld	a5,96(a0)
    80002cba:	6fc8                	ld	a0,152(a5)
    80002cbc:	bfe9                	j	80002c96 <argraw+0x30>
  panic("argraw");
    80002cbe:	00005517          	auipc	a0,0x5
    80002cc2:	76250513          	addi	a0,a0,1890 # 80008420 <states.1766+0x148>
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	878080e7          	jalr	-1928(ra) # 8000053e <panic>

0000000080002cce <fetchaddr>:
{
    80002cce:	1101                	addi	sp,sp,-32
    80002cd0:	ec06                	sd	ra,24(sp)
    80002cd2:	e822                	sd	s0,16(sp)
    80002cd4:	e426                	sd	s1,8(sp)
    80002cd6:	e04a                	sd	s2,0(sp)
    80002cd8:	1000                	addi	s0,sp,32
    80002cda:	84aa                	mv	s1,a0
    80002cdc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	ce6080e7          	jalr	-794(ra) # 800019c4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ce6:	693c                	ld	a5,80(a0)
    80002ce8:	02f4f863          	bgeu	s1,a5,80002d18 <fetchaddr+0x4a>
    80002cec:	00848713          	addi	a4,s1,8
    80002cf0:	02e7e663          	bltu	a5,a4,80002d1c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cf4:	46a1                	li	a3,8
    80002cf6:	8626                	mv	a2,s1
    80002cf8:	85ca                	mv	a1,s2
    80002cfa:	6d28                	ld	a0,88(a0)
    80002cfc:	fffff097          	auipc	ra,0xfffff
    80002d00:	a0a080e7          	jalr	-1526(ra) # 80001706 <copyin>
    80002d04:	00a03533          	snez	a0,a0
    80002d08:	40a00533          	neg	a0,a0
}
    80002d0c:	60e2                	ld	ra,24(sp)
    80002d0e:	6442                	ld	s0,16(sp)
    80002d10:	64a2                	ld	s1,8(sp)
    80002d12:	6902                	ld	s2,0(sp)
    80002d14:	6105                	addi	sp,sp,32
    80002d16:	8082                	ret
    return -1;
    80002d18:	557d                	li	a0,-1
    80002d1a:	bfcd                	j	80002d0c <fetchaddr+0x3e>
    80002d1c:	557d                	li	a0,-1
    80002d1e:	b7fd                	j	80002d0c <fetchaddr+0x3e>

0000000080002d20 <fetchstr>:
{
    80002d20:	7179                	addi	sp,sp,-48
    80002d22:	f406                	sd	ra,40(sp)
    80002d24:	f022                	sd	s0,32(sp)
    80002d26:	ec26                	sd	s1,24(sp)
    80002d28:	e84a                	sd	s2,16(sp)
    80002d2a:	e44e                	sd	s3,8(sp)
    80002d2c:	1800                	addi	s0,sp,48
    80002d2e:	892a                	mv	s2,a0
    80002d30:	84ae                	mv	s1,a1
    80002d32:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	c90080e7          	jalr	-880(ra) # 800019c4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d3c:	86ce                	mv	a3,s3
    80002d3e:	864a                	mv	a2,s2
    80002d40:	85a6                	mv	a1,s1
    80002d42:	6d28                	ld	a0,88(a0)
    80002d44:	fffff097          	auipc	ra,0xfffff
    80002d48:	a4e080e7          	jalr	-1458(ra) # 80001792 <copyinstr>
  if(err < 0)
    80002d4c:	00054763          	bltz	a0,80002d5a <fetchstr+0x3a>
  return strlen(buf);
    80002d50:	8526                	mv	a0,s1
    80002d52:	ffffe097          	auipc	ra,0xffffe
    80002d56:	112080e7          	jalr	274(ra) # 80000e64 <strlen>
}
    80002d5a:	70a2                	ld	ra,40(sp)
    80002d5c:	7402                	ld	s0,32(sp)
    80002d5e:	64e2                	ld	s1,24(sp)
    80002d60:	6942                	ld	s2,16(sp)
    80002d62:	69a2                	ld	s3,8(sp)
    80002d64:	6145                	addi	sp,sp,48
    80002d66:	8082                	ret

0000000080002d68 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d68:	1101                	addi	sp,sp,-32
    80002d6a:	ec06                	sd	ra,24(sp)
    80002d6c:	e822                	sd	s0,16(sp)
    80002d6e:	e426                	sd	s1,8(sp)
    80002d70:	1000                	addi	s0,sp,32
    80002d72:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d74:	00000097          	auipc	ra,0x0
    80002d78:	ef2080e7          	jalr	-270(ra) # 80002c66 <argraw>
    80002d7c:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d7e:	4501                	li	a0,0
    80002d80:	60e2                	ld	ra,24(sp)
    80002d82:	6442                	ld	s0,16(sp)
    80002d84:	64a2                	ld	s1,8(sp)
    80002d86:	6105                	addi	sp,sp,32
    80002d88:	8082                	ret

0000000080002d8a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d8a:	1101                	addi	sp,sp,-32
    80002d8c:	ec06                	sd	ra,24(sp)
    80002d8e:	e822                	sd	s0,16(sp)
    80002d90:	e426                	sd	s1,8(sp)
    80002d92:	1000                	addi	s0,sp,32
    80002d94:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d96:	00000097          	auipc	ra,0x0
    80002d9a:	ed0080e7          	jalr	-304(ra) # 80002c66 <argraw>
    80002d9e:	e088                	sd	a0,0(s1)
  return 0;
}
    80002da0:	4501                	li	a0,0
    80002da2:	60e2                	ld	ra,24(sp)
    80002da4:	6442                	ld	s0,16(sp)
    80002da6:	64a2                	ld	s1,8(sp)
    80002da8:	6105                	addi	sp,sp,32
    80002daa:	8082                	ret

0000000080002dac <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002dac:	1101                	addi	sp,sp,-32
    80002dae:	ec06                	sd	ra,24(sp)
    80002db0:	e822                	sd	s0,16(sp)
    80002db2:	e426                	sd	s1,8(sp)
    80002db4:	e04a                	sd	s2,0(sp)
    80002db6:	1000                	addi	s0,sp,32
    80002db8:	84ae                	mv	s1,a1
    80002dba:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002dbc:	00000097          	auipc	ra,0x0
    80002dc0:	eaa080e7          	jalr	-342(ra) # 80002c66 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002dc4:	864a                	mv	a2,s2
    80002dc6:	85a6                	mv	a1,s1
    80002dc8:	00000097          	auipc	ra,0x0
    80002dcc:	f58080e7          	jalr	-168(ra) # 80002d20 <fetchstr>
}
    80002dd0:	60e2                	ld	ra,24(sp)
    80002dd2:	6442                	ld	s0,16(sp)
    80002dd4:	64a2                	ld	s1,8(sp)
    80002dd6:	6902                	ld	s2,0(sp)
    80002dd8:	6105                	addi	sp,sp,32
    80002dda:	8082                	ret

0000000080002ddc <syscall>:
[SYS_kill_system] sys_kill_system,
};

void
syscall(void)
{
    80002ddc:	1101                	addi	sp,sp,-32
    80002dde:	ec06                	sd	ra,24(sp)
    80002de0:	e822                	sd	s0,16(sp)
    80002de2:	e426                	sd	s1,8(sp)
    80002de4:	e04a                	sd	s2,0(sp)
    80002de6:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	bdc080e7          	jalr	-1060(ra) # 800019c4 <myproc>
    80002df0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002df2:	06053903          	ld	s2,96(a0)
    80002df6:	0a893783          	ld	a5,168(s2)
    80002dfa:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002dfe:	37fd                	addiw	a5,a5,-1
    80002e00:	4759                	li	a4,22
    80002e02:	00f76f63          	bltu	a4,a5,80002e20 <syscall+0x44>
    80002e06:	00369713          	slli	a4,a3,0x3
    80002e0a:	00005797          	auipc	a5,0x5
    80002e0e:	65678793          	addi	a5,a5,1622 # 80008460 <syscalls>
    80002e12:	97ba                	add	a5,a5,a4
    80002e14:	639c                	ld	a5,0(a5)
    80002e16:	c789                	beqz	a5,80002e20 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e18:	9782                	jalr	a5
    80002e1a:	06a93823          	sd	a0,112(s2)
    80002e1e:	a839                	j	80002e3c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e20:	16048613          	addi	a2,s1,352
    80002e24:	588c                	lw	a1,48(s1)
    80002e26:	00005517          	auipc	a0,0x5
    80002e2a:	60250513          	addi	a0,a0,1538 # 80008428 <states.1766+0x150>
    80002e2e:	ffffd097          	auipc	ra,0xffffd
    80002e32:	75a080e7          	jalr	1882(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e36:	70bc                	ld	a5,96(s1)
    80002e38:	577d                	li	a4,-1
    80002e3a:	fbb8                	sd	a4,112(a5)
  }
}
    80002e3c:	60e2                	ld	ra,24(sp)
    80002e3e:	6442                	ld	s0,16(sp)
    80002e40:	64a2                	ld	s1,8(sp)
    80002e42:	6902                	ld	s2,0(sp)
    80002e44:	6105                	addi	sp,sp,32
    80002e46:	8082                	ret

0000000080002e48 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e48:	1101                	addi	sp,sp,-32
    80002e4a:	ec06                	sd	ra,24(sp)
    80002e4c:	e822                	sd	s0,16(sp)
    80002e4e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e50:	fec40593          	addi	a1,s0,-20
    80002e54:	4501                	li	a0,0
    80002e56:	00000097          	auipc	ra,0x0
    80002e5a:	f12080e7          	jalr	-238(ra) # 80002d68 <argint>
    return -1;
    80002e5e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e60:	00054963          	bltz	a0,80002e72 <sys_exit+0x2a>
  exit(n);
    80002e64:	fec42503          	lw	a0,-20(s0)
    80002e68:	fffff097          	auipc	ra,0xfffff
    80002e6c:	6cc080e7          	jalr	1740(ra) # 80002534 <exit>
  return 0;  // not reached
    80002e70:	4781                	li	a5,0
}
    80002e72:	853e                	mv	a0,a5
    80002e74:	60e2                	ld	ra,24(sp)
    80002e76:	6442                	ld	s0,16(sp)
    80002e78:	6105                	addi	sp,sp,32
    80002e7a:	8082                	ret

0000000080002e7c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e7c:	1141                	addi	sp,sp,-16
    80002e7e:	e406                	sd	ra,8(sp)
    80002e80:	e022                	sd	s0,0(sp)
    80002e82:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e84:	fffff097          	auipc	ra,0xfffff
    80002e88:	b40080e7          	jalr	-1216(ra) # 800019c4 <myproc>
}
    80002e8c:	5908                	lw	a0,48(a0)
    80002e8e:	60a2                	ld	ra,8(sp)
    80002e90:	6402                	ld	s0,0(sp)
    80002e92:	0141                	addi	sp,sp,16
    80002e94:	8082                	ret

0000000080002e96 <sys_fork>:

uint64
sys_fork(void)
{
    80002e96:	1141                	addi	sp,sp,-16
    80002e98:	e406                	sd	ra,8(sp)
    80002e9a:	e022                	sd	s0,0(sp)
    80002e9c:	0800                	addi	s0,sp,16
  return fork();
    80002e9e:	fffff097          	auipc	ra,0xfffff
    80002ea2:	efc080e7          	jalr	-260(ra) # 80001d9a <fork>
}
    80002ea6:	60a2                	ld	ra,8(sp)
    80002ea8:	6402                	ld	s0,0(sp)
    80002eaa:	0141                	addi	sp,sp,16
    80002eac:	8082                	ret

0000000080002eae <sys_wait>:

uint64
sys_wait(void)
{
    80002eae:	1101                	addi	sp,sp,-32
    80002eb0:	ec06                	sd	ra,24(sp)
    80002eb2:	e822                	sd	s0,16(sp)
    80002eb4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002eb6:	fe840593          	addi	a1,s0,-24
    80002eba:	4501                	li	a0,0
    80002ebc:	00000097          	auipc	ra,0x0
    80002ec0:	ece080e7          	jalr	-306(ra) # 80002d8a <argaddr>
    80002ec4:	87aa                	mv	a5,a0
    return -1;
    80002ec6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ec8:	0007c863          	bltz	a5,80002ed8 <sys_wait+0x2a>
  return wait(p);
    80002ecc:	fe843503          	ld	a0,-24(s0)
    80002ed0:	fffff097          	auipc	ra,0xfffff
    80002ed4:	46c080e7          	jalr	1132(ra) # 8000233c <wait>
}
    80002ed8:	60e2                	ld	ra,24(sp)
    80002eda:	6442                	ld	s0,16(sp)
    80002edc:	6105                	addi	sp,sp,32
    80002ede:	8082                	ret

0000000080002ee0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ee0:	7179                	addi	sp,sp,-48
    80002ee2:	f406                	sd	ra,40(sp)
    80002ee4:	f022                	sd	s0,32(sp)
    80002ee6:	ec26                	sd	s1,24(sp)
    80002ee8:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002eea:	fdc40593          	addi	a1,s0,-36
    80002eee:	4501                	li	a0,0
    80002ef0:	00000097          	auipc	ra,0x0
    80002ef4:	e78080e7          	jalr	-392(ra) # 80002d68 <argint>
    80002ef8:	87aa                	mv	a5,a0
    return -1;
    80002efa:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002efc:	0207c063          	bltz	a5,80002f1c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f00:	fffff097          	auipc	ra,0xfffff
    80002f04:	ac4080e7          	jalr	-1340(ra) # 800019c4 <myproc>
    80002f08:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002f0a:	fdc42503          	lw	a0,-36(s0)
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	e18080e7          	jalr	-488(ra) # 80001d26 <growproc>
    80002f16:	00054863          	bltz	a0,80002f26 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f1a:	8526                	mv	a0,s1
}
    80002f1c:	70a2                	ld	ra,40(sp)
    80002f1e:	7402                	ld	s0,32(sp)
    80002f20:	64e2                	ld	s1,24(sp)
    80002f22:	6145                	addi	sp,sp,48
    80002f24:	8082                	ret
    return -1;
    80002f26:	557d                	li	a0,-1
    80002f28:	bfd5                	j	80002f1c <sys_sbrk+0x3c>

0000000080002f2a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f2a:	7139                	addi	sp,sp,-64
    80002f2c:	fc06                	sd	ra,56(sp)
    80002f2e:	f822                	sd	s0,48(sp)
    80002f30:	f426                	sd	s1,40(sp)
    80002f32:	f04a                	sd	s2,32(sp)
    80002f34:	ec4e                	sd	s3,24(sp)
    80002f36:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f38:	fcc40593          	addi	a1,s0,-52
    80002f3c:	4501                	li	a0,0
    80002f3e:	00000097          	auipc	ra,0x0
    80002f42:	e2a080e7          	jalr	-470(ra) # 80002d68 <argint>
    return -1;
    80002f46:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f48:	06054563          	bltz	a0,80002fb2 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f4c:	00014517          	auipc	a0,0x14
    80002f50:	38450513          	addi	a0,a0,900 # 800172d0 <tickslock>
    80002f54:	ffffe097          	auipc	ra,0xffffe
    80002f58:	c90080e7          	jalr	-880(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002f5c:	00006917          	auipc	s2,0x6
    80002f60:	0dc92903          	lw	s2,220(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80002f64:	fcc42783          	lw	a5,-52(s0)
    80002f68:	cf85                	beqz	a5,80002fa0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f6a:	00014997          	auipc	s3,0x14
    80002f6e:	36698993          	addi	s3,s3,870 # 800172d0 <tickslock>
    80002f72:	00006497          	auipc	s1,0x6
    80002f76:	0c648493          	addi	s1,s1,198 # 80009038 <ticks>
    if(myproc()->killed){
    80002f7a:	fffff097          	auipc	ra,0xfffff
    80002f7e:	a4a080e7          	jalr	-1462(ra) # 800019c4 <myproc>
    80002f82:	551c                	lw	a5,40(a0)
    80002f84:	ef9d                	bnez	a5,80002fc2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f86:	85ce                	mv	a1,s3
    80002f88:	8526                	mv	a0,s1
    80002f8a:	fffff097          	auipc	ra,0xfffff
    80002f8e:	34e080e7          	jalr	846(ra) # 800022d8 <sleep>
  while(ticks - ticks0 < n){
    80002f92:	409c                	lw	a5,0(s1)
    80002f94:	412787bb          	subw	a5,a5,s2
    80002f98:	fcc42703          	lw	a4,-52(s0)
    80002f9c:	fce7efe3          	bltu	a5,a4,80002f7a <sys_sleep+0x50>
  }
  release(&tickslock);
    80002fa0:	00014517          	auipc	a0,0x14
    80002fa4:	33050513          	addi	a0,a0,816 # 800172d0 <tickslock>
    80002fa8:	ffffe097          	auipc	ra,0xffffe
    80002fac:	cf0080e7          	jalr	-784(ra) # 80000c98 <release>
  return 0;
    80002fb0:	4781                	li	a5,0
}
    80002fb2:	853e                	mv	a0,a5
    80002fb4:	70e2                	ld	ra,56(sp)
    80002fb6:	7442                	ld	s0,48(sp)
    80002fb8:	74a2                	ld	s1,40(sp)
    80002fba:	7902                	ld	s2,32(sp)
    80002fbc:	69e2                	ld	s3,24(sp)
    80002fbe:	6121                	addi	sp,sp,64
    80002fc0:	8082                	ret
      release(&tickslock);
    80002fc2:	00014517          	auipc	a0,0x14
    80002fc6:	30e50513          	addi	a0,a0,782 # 800172d0 <tickslock>
    80002fca:	ffffe097          	auipc	ra,0xffffe
    80002fce:	cce080e7          	jalr	-818(ra) # 80000c98 <release>
      return -1;
    80002fd2:	57fd                	li	a5,-1
    80002fd4:	bff9                	j	80002fb2 <sys_sleep+0x88>

0000000080002fd6 <sys_kill>:

uint64
sys_kill(void)
{
    80002fd6:	1101                	addi	sp,sp,-32
    80002fd8:	ec06                	sd	ra,24(sp)
    80002fda:	e822                	sd	s0,16(sp)
    80002fdc:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002fde:	fec40593          	addi	a1,s0,-20
    80002fe2:	4501                	li	a0,0
    80002fe4:	00000097          	auipc	ra,0x0
    80002fe8:	d84080e7          	jalr	-636(ra) # 80002d68 <argint>
    80002fec:	87aa                	mv	a5,a0
    return -1;
    80002fee:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ff0:	0007c863          	bltz	a5,80003000 <sys_kill+0x2a>
  return kill(pid);
    80002ff4:	fec42503          	lw	a0,-20(s0)
    80002ff8:	fffff097          	auipc	ra,0xfffff
    80002ffc:	612080e7          	jalr	1554(ra) # 8000260a <kill>
}
    80003000:	60e2                	ld	ra,24(sp)
    80003002:	6442                	ld	s0,16(sp)
    80003004:	6105                	addi	sp,sp,32
    80003006:	8082                	ret

0000000080003008 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003008:	1101                	addi	sp,sp,-32
    8000300a:	ec06                	sd	ra,24(sp)
    8000300c:	e822                	sd	s0,16(sp)
    8000300e:	e426                	sd	s1,8(sp)
    80003010:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003012:	00014517          	auipc	a0,0x14
    80003016:	2be50513          	addi	a0,a0,702 # 800172d0 <tickslock>
    8000301a:	ffffe097          	auipc	ra,0xffffe
    8000301e:	bca080e7          	jalr	-1078(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003022:	00006497          	auipc	s1,0x6
    80003026:	0164a483          	lw	s1,22(s1) # 80009038 <ticks>
  release(&tickslock);
    8000302a:	00014517          	auipc	a0,0x14
    8000302e:	2a650513          	addi	a0,a0,678 # 800172d0 <tickslock>
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	c66080e7          	jalr	-922(ra) # 80000c98 <release>
  return xticks;
}
    8000303a:	02049513          	slli	a0,s1,0x20
    8000303e:	9101                	srli	a0,a0,0x20
    80003040:	60e2                	ld	ra,24(sp)
    80003042:	6442                	ld	s0,16(sp)
    80003044:	64a2                	ld	s1,8(sp)
    80003046:	6105                	addi	sp,sp,32
    80003048:	8082                	ret

000000008000304a <sys_pause_system>:

uint64
sys_pause_system(void)
{
    8000304a:	1101                	addi	sp,sp,-32
    8000304c:	ec06                	sd	ra,24(sp)
    8000304e:	e822                	sd	s0,16(sp)
    80003050:	1000                	addi	s0,sp,32
  int seconds;
  if(argint(0, &seconds) >= 0)
    80003052:	fec40593          	addi	a1,s0,-20
    80003056:	4501                	li	a0,0
    80003058:	00000097          	auipc	ra,0x0
    8000305c:	d10080e7          	jalr	-752(ra) # 80002d68 <argint>
    80003060:	87aa                	mv	a5,a0
  {
    return pause_system(seconds);
  }
  return -1;
    80003062:	557d                	li	a0,-1
  if(argint(0, &seconds) >= 0)
    80003064:	0007d663          	bgez	a5,80003070 <sys_pause_system+0x26>
}
    80003068:	60e2                	ld	ra,24(sp)
    8000306a:	6442                	ld	s0,16(sp)
    8000306c:	6105                	addi	sp,sp,32
    8000306e:	8082                	ret
    return pause_system(seconds);
    80003070:	fec42503          	lw	a0,-20(s0)
    80003074:	fffff097          	auipc	ra,0xfffff
    80003078:	762080e7          	jalr	1890(ra) # 800027d6 <pause_system>
    8000307c:	b7f5                	j	80003068 <sys_pause_system+0x1e>

000000008000307e <sys_kill_system>:

uint64
sys_kill_system(void)
{
    8000307e:	1141                	addi	sp,sp,-16
    80003080:	e406                	sd	ra,8(sp)
    80003082:	e022                	sd	s0,0(sp)
    80003084:	0800                	addi	s0,sp,16
  return kill_system();
    80003086:	fffff097          	auipc	ra,0xfffff
    8000308a:	786080e7          	jalr	1926(ra) # 8000280c <kill_system>
    8000308e:	60a2                	ld	ra,8(sp)
    80003090:	6402                	ld	s0,0(sp)
    80003092:	0141                	addi	sp,sp,16
    80003094:	8082                	ret

0000000080003096 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003096:	7179                	addi	sp,sp,-48
    80003098:	f406                	sd	ra,40(sp)
    8000309a:	f022                	sd	s0,32(sp)
    8000309c:	ec26                	sd	s1,24(sp)
    8000309e:	e84a                	sd	s2,16(sp)
    800030a0:	e44e                	sd	s3,8(sp)
    800030a2:	e052                	sd	s4,0(sp)
    800030a4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030a6:	00005597          	auipc	a1,0x5
    800030aa:	47a58593          	addi	a1,a1,1146 # 80008520 <syscalls+0xc0>
    800030ae:	00014517          	auipc	a0,0x14
    800030b2:	23a50513          	addi	a0,a0,570 # 800172e8 <bcache>
    800030b6:	ffffe097          	auipc	ra,0xffffe
    800030ba:	a9e080e7          	jalr	-1378(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030be:	0001c797          	auipc	a5,0x1c
    800030c2:	22a78793          	addi	a5,a5,554 # 8001f2e8 <bcache+0x8000>
    800030c6:	0001c717          	auipc	a4,0x1c
    800030ca:	48a70713          	addi	a4,a4,1162 # 8001f550 <bcache+0x8268>
    800030ce:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030d2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030d6:	00014497          	auipc	s1,0x14
    800030da:	22a48493          	addi	s1,s1,554 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    800030de:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030e0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030e2:	00005a17          	auipc	s4,0x5
    800030e6:	446a0a13          	addi	s4,s4,1094 # 80008528 <syscalls+0xc8>
    b->next = bcache.head.next;
    800030ea:	2b893783          	ld	a5,696(s2)
    800030ee:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030f0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030f4:	85d2                	mv	a1,s4
    800030f6:	01048513          	addi	a0,s1,16
    800030fa:	00001097          	auipc	ra,0x1
    800030fe:	4bc080e7          	jalr	1212(ra) # 800045b6 <initsleeplock>
    bcache.head.next->prev = b;
    80003102:	2b893783          	ld	a5,696(s2)
    80003106:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003108:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000310c:	45848493          	addi	s1,s1,1112
    80003110:	fd349de3          	bne	s1,s3,800030ea <binit+0x54>
  }
}
    80003114:	70a2                	ld	ra,40(sp)
    80003116:	7402                	ld	s0,32(sp)
    80003118:	64e2                	ld	s1,24(sp)
    8000311a:	6942                	ld	s2,16(sp)
    8000311c:	69a2                	ld	s3,8(sp)
    8000311e:	6a02                	ld	s4,0(sp)
    80003120:	6145                	addi	sp,sp,48
    80003122:	8082                	ret

0000000080003124 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003124:	7179                	addi	sp,sp,-48
    80003126:	f406                	sd	ra,40(sp)
    80003128:	f022                	sd	s0,32(sp)
    8000312a:	ec26                	sd	s1,24(sp)
    8000312c:	e84a                	sd	s2,16(sp)
    8000312e:	e44e                	sd	s3,8(sp)
    80003130:	1800                	addi	s0,sp,48
    80003132:	89aa                	mv	s3,a0
    80003134:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003136:	00014517          	auipc	a0,0x14
    8000313a:	1b250513          	addi	a0,a0,434 # 800172e8 <bcache>
    8000313e:	ffffe097          	auipc	ra,0xffffe
    80003142:	aa6080e7          	jalr	-1370(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003146:	0001c497          	auipc	s1,0x1c
    8000314a:	45a4b483          	ld	s1,1114(s1) # 8001f5a0 <bcache+0x82b8>
    8000314e:	0001c797          	auipc	a5,0x1c
    80003152:	40278793          	addi	a5,a5,1026 # 8001f550 <bcache+0x8268>
    80003156:	02f48f63          	beq	s1,a5,80003194 <bread+0x70>
    8000315a:	873e                	mv	a4,a5
    8000315c:	a021                	j	80003164 <bread+0x40>
    8000315e:	68a4                	ld	s1,80(s1)
    80003160:	02e48a63          	beq	s1,a4,80003194 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003164:	449c                	lw	a5,8(s1)
    80003166:	ff379ce3          	bne	a5,s3,8000315e <bread+0x3a>
    8000316a:	44dc                	lw	a5,12(s1)
    8000316c:	ff2799e3          	bne	a5,s2,8000315e <bread+0x3a>
      b->refcnt++;
    80003170:	40bc                	lw	a5,64(s1)
    80003172:	2785                	addiw	a5,a5,1
    80003174:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003176:	00014517          	auipc	a0,0x14
    8000317a:	17250513          	addi	a0,a0,370 # 800172e8 <bcache>
    8000317e:	ffffe097          	auipc	ra,0xffffe
    80003182:	b1a080e7          	jalr	-1254(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003186:	01048513          	addi	a0,s1,16
    8000318a:	00001097          	auipc	ra,0x1
    8000318e:	466080e7          	jalr	1126(ra) # 800045f0 <acquiresleep>
      return b;
    80003192:	a8b9                	j	800031f0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003194:	0001c497          	auipc	s1,0x1c
    80003198:	4044b483          	ld	s1,1028(s1) # 8001f598 <bcache+0x82b0>
    8000319c:	0001c797          	auipc	a5,0x1c
    800031a0:	3b478793          	addi	a5,a5,948 # 8001f550 <bcache+0x8268>
    800031a4:	00f48863          	beq	s1,a5,800031b4 <bread+0x90>
    800031a8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031aa:	40bc                	lw	a5,64(s1)
    800031ac:	cf81                	beqz	a5,800031c4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031ae:	64a4                	ld	s1,72(s1)
    800031b0:	fee49de3          	bne	s1,a4,800031aa <bread+0x86>
  panic("bget: no buffers");
    800031b4:	00005517          	auipc	a0,0x5
    800031b8:	37c50513          	addi	a0,a0,892 # 80008530 <syscalls+0xd0>
    800031bc:	ffffd097          	auipc	ra,0xffffd
    800031c0:	382080e7          	jalr	898(ra) # 8000053e <panic>
      b->dev = dev;
    800031c4:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800031c8:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800031cc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031d0:	4785                	li	a5,1
    800031d2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031d4:	00014517          	auipc	a0,0x14
    800031d8:	11450513          	addi	a0,a0,276 # 800172e8 <bcache>
    800031dc:	ffffe097          	auipc	ra,0xffffe
    800031e0:	abc080e7          	jalr	-1348(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800031e4:	01048513          	addi	a0,s1,16
    800031e8:	00001097          	auipc	ra,0x1
    800031ec:	408080e7          	jalr	1032(ra) # 800045f0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031f0:	409c                	lw	a5,0(s1)
    800031f2:	cb89                	beqz	a5,80003204 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031f4:	8526                	mv	a0,s1
    800031f6:	70a2                	ld	ra,40(sp)
    800031f8:	7402                	ld	s0,32(sp)
    800031fa:	64e2                	ld	s1,24(sp)
    800031fc:	6942                	ld	s2,16(sp)
    800031fe:	69a2                	ld	s3,8(sp)
    80003200:	6145                	addi	sp,sp,48
    80003202:	8082                	ret
    virtio_disk_rw(b, 0);
    80003204:	4581                	li	a1,0
    80003206:	8526                	mv	a0,s1
    80003208:	00003097          	auipc	ra,0x3
    8000320c:	f0e080e7          	jalr	-242(ra) # 80006116 <virtio_disk_rw>
    b->valid = 1;
    80003210:	4785                	li	a5,1
    80003212:	c09c                	sw	a5,0(s1)
  return b;
    80003214:	b7c5                	j	800031f4 <bread+0xd0>

0000000080003216 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003216:	1101                	addi	sp,sp,-32
    80003218:	ec06                	sd	ra,24(sp)
    8000321a:	e822                	sd	s0,16(sp)
    8000321c:	e426                	sd	s1,8(sp)
    8000321e:	1000                	addi	s0,sp,32
    80003220:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003222:	0541                	addi	a0,a0,16
    80003224:	00001097          	auipc	ra,0x1
    80003228:	466080e7          	jalr	1126(ra) # 8000468a <holdingsleep>
    8000322c:	cd01                	beqz	a0,80003244 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000322e:	4585                	li	a1,1
    80003230:	8526                	mv	a0,s1
    80003232:	00003097          	auipc	ra,0x3
    80003236:	ee4080e7          	jalr	-284(ra) # 80006116 <virtio_disk_rw>
}
    8000323a:	60e2                	ld	ra,24(sp)
    8000323c:	6442                	ld	s0,16(sp)
    8000323e:	64a2                	ld	s1,8(sp)
    80003240:	6105                	addi	sp,sp,32
    80003242:	8082                	ret
    panic("bwrite");
    80003244:	00005517          	auipc	a0,0x5
    80003248:	30450513          	addi	a0,a0,772 # 80008548 <syscalls+0xe8>
    8000324c:	ffffd097          	auipc	ra,0xffffd
    80003250:	2f2080e7          	jalr	754(ra) # 8000053e <panic>

0000000080003254 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003254:	1101                	addi	sp,sp,-32
    80003256:	ec06                	sd	ra,24(sp)
    80003258:	e822                	sd	s0,16(sp)
    8000325a:	e426                	sd	s1,8(sp)
    8000325c:	e04a                	sd	s2,0(sp)
    8000325e:	1000                	addi	s0,sp,32
    80003260:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003262:	01050913          	addi	s2,a0,16
    80003266:	854a                	mv	a0,s2
    80003268:	00001097          	auipc	ra,0x1
    8000326c:	422080e7          	jalr	1058(ra) # 8000468a <holdingsleep>
    80003270:	c92d                	beqz	a0,800032e2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003272:	854a                	mv	a0,s2
    80003274:	00001097          	auipc	ra,0x1
    80003278:	3d2080e7          	jalr	978(ra) # 80004646 <releasesleep>

  acquire(&bcache.lock);
    8000327c:	00014517          	auipc	a0,0x14
    80003280:	06c50513          	addi	a0,a0,108 # 800172e8 <bcache>
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	960080e7          	jalr	-1696(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000328c:	40bc                	lw	a5,64(s1)
    8000328e:	37fd                	addiw	a5,a5,-1
    80003290:	0007871b          	sext.w	a4,a5
    80003294:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003296:	eb05                	bnez	a4,800032c6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003298:	68bc                	ld	a5,80(s1)
    8000329a:	64b8                	ld	a4,72(s1)
    8000329c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000329e:	64bc                	ld	a5,72(s1)
    800032a0:	68b8                	ld	a4,80(s1)
    800032a2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032a4:	0001c797          	auipc	a5,0x1c
    800032a8:	04478793          	addi	a5,a5,68 # 8001f2e8 <bcache+0x8000>
    800032ac:	2b87b703          	ld	a4,696(a5)
    800032b0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032b2:	0001c717          	auipc	a4,0x1c
    800032b6:	29e70713          	addi	a4,a4,670 # 8001f550 <bcache+0x8268>
    800032ba:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032bc:	2b87b703          	ld	a4,696(a5)
    800032c0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032c2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032c6:	00014517          	auipc	a0,0x14
    800032ca:	02250513          	addi	a0,a0,34 # 800172e8 <bcache>
    800032ce:	ffffe097          	auipc	ra,0xffffe
    800032d2:	9ca080e7          	jalr	-1590(ra) # 80000c98 <release>
}
    800032d6:	60e2                	ld	ra,24(sp)
    800032d8:	6442                	ld	s0,16(sp)
    800032da:	64a2                	ld	s1,8(sp)
    800032dc:	6902                	ld	s2,0(sp)
    800032de:	6105                	addi	sp,sp,32
    800032e0:	8082                	ret
    panic("brelse");
    800032e2:	00005517          	auipc	a0,0x5
    800032e6:	26e50513          	addi	a0,a0,622 # 80008550 <syscalls+0xf0>
    800032ea:	ffffd097          	auipc	ra,0xffffd
    800032ee:	254080e7          	jalr	596(ra) # 8000053e <panic>

00000000800032f2 <bpin>:

void
bpin(struct buf *b) {
    800032f2:	1101                	addi	sp,sp,-32
    800032f4:	ec06                	sd	ra,24(sp)
    800032f6:	e822                	sd	s0,16(sp)
    800032f8:	e426                	sd	s1,8(sp)
    800032fa:	1000                	addi	s0,sp,32
    800032fc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032fe:	00014517          	auipc	a0,0x14
    80003302:	fea50513          	addi	a0,a0,-22 # 800172e8 <bcache>
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	8de080e7          	jalr	-1826(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000330e:	40bc                	lw	a5,64(s1)
    80003310:	2785                	addiw	a5,a5,1
    80003312:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003314:	00014517          	auipc	a0,0x14
    80003318:	fd450513          	addi	a0,a0,-44 # 800172e8 <bcache>
    8000331c:	ffffe097          	auipc	ra,0xffffe
    80003320:	97c080e7          	jalr	-1668(ra) # 80000c98 <release>
}
    80003324:	60e2                	ld	ra,24(sp)
    80003326:	6442                	ld	s0,16(sp)
    80003328:	64a2                	ld	s1,8(sp)
    8000332a:	6105                	addi	sp,sp,32
    8000332c:	8082                	ret

000000008000332e <bunpin>:

void
bunpin(struct buf *b) {
    8000332e:	1101                	addi	sp,sp,-32
    80003330:	ec06                	sd	ra,24(sp)
    80003332:	e822                	sd	s0,16(sp)
    80003334:	e426                	sd	s1,8(sp)
    80003336:	1000                	addi	s0,sp,32
    80003338:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000333a:	00014517          	auipc	a0,0x14
    8000333e:	fae50513          	addi	a0,a0,-82 # 800172e8 <bcache>
    80003342:	ffffe097          	auipc	ra,0xffffe
    80003346:	8a2080e7          	jalr	-1886(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000334a:	40bc                	lw	a5,64(s1)
    8000334c:	37fd                	addiw	a5,a5,-1
    8000334e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003350:	00014517          	auipc	a0,0x14
    80003354:	f9850513          	addi	a0,a0,-104 # 800172e8 <bcache>
    80003358:	ffffe097          	auipc	ra,0xffffe
    8000335c:	940080e7          	jalr	-1728(ra) # 80000c98 <release>
}
    80003360:	60e2                	ld	ra,24(sp)
    80003362:	6442                	ld	s0,16(sp)
    80003364:	64a2                	ld	s1,8(sp)
    80003366:	6105                	addi	sp,sp,32
    80003368:	8082                	ret

000000008000336a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000336a:	1101                	addi	sp,sp,-32
    8000336c:	ec06                	sd	ra,24(sp)
    8000336e:	e822                	sd	s0,16(sp)
    80003370:	e426                	sd	s1,8(sp)
    80003372:	e04a                	sd	s2,0(sp)
    80003374:	1000                	addi	s0,sp,32
    80003376:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003378:	00d5d59b          	srliw	a1,a1,0xd
    8000337c:	0001c797          	auipc	a5,0x1c
    80003380:	6487a783          	lw	a5,1608(a5) # 8001f9c4 <sb+0x1c>
    80003384:	9dbd                	addw	a1,a1,a5
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	d9e080e7          	jalr	-610(ra) # 80003124 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000338e:	0074f713          	andi	a4,s1,7
    80003392:	4785                	li	a5,1
    80003394:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003398:	14ce                	slli	s1,s1,0x33
    8000339a:	90d9                	srli	s1,s1,0x36
    8000339c:	00950733          	add	a4,a0,s1
    800033a0:	05874703          	lbu	a4,88(a4)
    800033a4:	00e7f6b3          	and	a3,a5,a4
    800033a8:	c69d                	beqz	a3,800033d6 <bfree+0x6c>
    800033aa:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033ac:	94aa                	add	s1,s1,a0
    800033ae:	fff7c793          	not	a5,a5
    800033b2:	8ff9                	and	a5,a5,a4
    800033b4:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033b8:	00001097          	auipc	ra,0x1
    800033bc:	118080e7          	jalr	280(ra) # 800044d0 <log_write>
  brelse(bp);
    800033c0:	854a                	mv	a0,s2
    800033c2:	00000097          	auipc	ra,0x0
    800033c6:	e92080e7          	jalr	-366(ra) # 80003254 <brelse>
}
    800033ca:	60e2                	ld	ra,24(sp)
    800033cc:	6442                	ld	s0,16(sp)
    800033ce:	64a2                	ld	s1,8(sp)
    800033d0:	6902                	ld	s2,0(sp)
    800033d2:	6105                	addi	sp,sp,32
    800033d4:	8082                	ret
    panic("freeing free block");
    800033d6:	00005517          	auipc	a0,0x5
    800033da:	18250513          	addi	a0,a0,386 # 80008558 <syscalls+0xf8>
    800033de:	ffffd097          	auipc	ra,0xffffd
    800033e2:	160080e7          	jalr	352(ra) # 8000053e <panic>

00000000800033e6 <balloc>:
{
    800033e6:	711d                	addi	sp,sp,-96
    800033e8:	ec86                	sd	ra,88(sp)
    800033ea:	e8a2                	sd	s0,80(sp)
    800033ec:	e4a6                	sd	s1,72(sp)
    800033ee:	e0ca                	sd	s2,64(sp)
    800033f0:	fc4e                	sd	s3,56(sp)
    800033f2:	f852                	sd	s4,48(sp)
    800033f4:	f456                	sd	s5,40(sp)
    800033f6:	f05a                	sd	s6,32(sp)
    800033f8:	ec5e                	sd	s7,24(sp)
    800033fa:	e862                	sd	s8,16(sp)
    800033fc:	e466                	sd	s9,8(sp)
    800033fe:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003400:	0001c797          	auipc	a5,0x1c
    80003404:	5ac7a783          	lw	a5,1452(a5) # 8001f9ac <sb+0x4>
    80003408:	cbd1                	beqz	a5,8000349c <balloc+0xb6>
    8000340a:	8baa                	mv	s7,a0
    8000340c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000340e:	0001cb17          	auipc	s6,0x1c
    80003412:	59ab0b13          	addi	s6,s6,1434 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003416:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003418:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000341a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000341c:	6c89                	lui	s9,0x2
    8000341e:	a831                	j	8000343a <balloc+0x54>
    brelse(bp);
    80003420:	854a                	mv	a0,s2
    80003422:	00000097          	auipc	ra,0x0
    80003426:	e32080e7          	jalr	-462(ra) # 80003254 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000342a:	015c87bb          	addw	a5,s9,s5
    8000342e:	00078a9b          	sext.w	s5,a5
    80003432:	004b2703          	lw	a4,4(s6)
    80003436:	06eaf363          	bgeu	s5,a4,8000349c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000343a:	41fad79b          	sraiw	a5,s5,0x1f
    8000343e:	0137d79b          	srliw	a5,a5,0x13
    80003442:	015787bb          	addw	a5,a5,s5
    80003446:	40d7d79b          	sraiw	a5,a5,0xd
    8000344a:	01cb2583          	lw	a1,28(s6)
    8000344e:	9dbd                	addw	a1,a1,a5
    80003450:	855e                	mv	a0,s7
    80003452:	00000097          	auipc	ra,0x0
    80003456:	cd2080e7          	jalr	-814(ra) # 80003124 <bread>
    8000345a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000345c:	004b2503          	lw	a0,4(s6)
    80003460:	000a849b          	sext.w	s1,s5
    80003464:	8662                	mv	a2,s8
    80003466:	faa4fde3          	bgeu	s1,a0,80003420 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000346a:	41f6579b          	sraiw	a5,a2,0x1f
    8000346e:	01d7d69b          	srliw	a3,a5,0x1d
    80003472:	00c6873b          	addw	a4,a3,a2
    80003476:	00777793          	andi	a5,a4,7
    8000347a:	9f95                	subw	a5,a5,a3
    8000347c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003480:	4037571b          	sraiw	a4,a4,0x3
    80003484:	00e906b3          	add	a3,s2,a4
    80003488:	0586c683          	lbu	a3,88(a3)
    8000348c:	00d7f5b3          	and	a1,a5,a3
    80003490:	cd91                	beqz	a1,800034ac <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003492:	2605                	addiw	a2,a2,1
    80003494:	2485                	addiw	s1,s1,1
    80003496:	fd4618e3          	bne	a2,s4,80003466 <balloc+0x80>
    8000349a:	b759                	j	80003420 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000349c:	00005517          	auipc	a0,0x5
    800034a0:	0d450513          	addi	a0,a0,212 # 80008570 <syscalls+0x110>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	09a080e7          	jalr	154(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034ac:	974a                	add	a4,a4,s2
    800034ae:	8fd5                	or	a5,a5,a3
    800034b0:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034b4:	854a                	mv	a0,s2
    800034b6:	00001097          	auipc	ra,0x1
    800034ba:	01a080e7          	jalr	26(ra) # 800044d0 <log_write>
        brelse(bp);
    800034be:	854a                	mv	a0,s2
    800034c0:	00000097          	auipc	ra,0x0
    800034c4:	d94080e7          	jalr	-620(ra) # 80003254 <brelse>
  bp = bread(dev, bno);
    800034c8:	85a6                	mv	a1,s1
    800034ca:	855e                	mv	a0,s7
    800034cc:	00000097          	auipc	ra,0x0
    800034d0:	c58080e7          	jalr	-936(ra) # 80003124 <bread>
    800034d4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034d6:	40000613          	li	a2,1024
    800034da:	4581                	li	a1,0
    800034dc:	05850513          	addi	a0,a0,88
    800034e0:	ffffe097          	auipc	ra,0xffffe
    800034e4:	800080e7          	jalr	-2048(ra) # 80000ce0 <memset>
  log_write(bp);
    800034e8:	854a                	mv	a0,s2
    800034ea:	00001097          	auipc	ra,0x1
    800034ee:	fe6080e7          	jalr	-26(ra) # 800044d0 <log_write>
  brelse(bp);
    800034f2:	854a                	mv	a0,s2
    800034f4:	00000097          	auipc	ra,0x0
    800034f8:	d60080e7          	jalr	-672(ra) # 80003254 <brelse>
}
    800034fc:	8526                	mv	a0,s1
    800034fe:	60e6                	ld	ra,88(sp)
    80003500:	6446                	ld	s0,80(sp)
    80003502:	64a6                	ld	s1,72(sp)
    80003504:	6906                	ld	s2,64(sp)
    80003506:	79e2                	ld	s3,56(sp)
    80003508:	7a42                	ld	s4,48(sp)
    8000350a:	7aa2                	ld	s5,40(sp)
    8000350c:	7b02                	ld	s6,32(sp)
    8000350e:	6be2                	ld	s7,24(sp)
    80003510:	6c42                	ld	s8,16(sp)
    80003512:	6ca2                	ld	s9,8(sp)
    80003514:	6125                	addi	sp,sp,96
    80003516:	8082                	ret

0000000080003518 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003518:	7179                	addi	sp,sp,-48
    8000351a:	f406                	sd	ra,40(sp)
    8000351c:	f022                	sd	s0,32(sp)
    8000351e:	ec26                	sd	s1,24(sp)
    80003520:	e84a                	sd	s2,16(sp)
    80003522:	e44e                	sd	s3,8(sp)
    80003524:	e052                	sd	s4,0(sp)
    80003526:	1800                	addi	s0,sp,48
    80003528:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000352a:	47ad                	li	a5,11
    8000352c:	04b7fe63          	bgeu	a5,a1,80003588 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003530:	ff45849b          	addiw	s1,a1,-12
    80003534:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003538:	0ff00793          	li	a5,255
    8000353c:	0ae7e363          	bltu	a5,a4,800035e2 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003540:	08052583          	lw	a1,128(a0)
    80003544:	c5ad                	beqz	a1,800035ae <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003546:	00092503          	lw	a0,0(s2)
    8000354a:	00000097          	auipc	ra,0x0
    8000354e:	bda080e7          	jalr	-1062(ra) # 80003124 <bread>
    80003552:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003554:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003558:	02049593          	slli	a1,s1,0x20
    8000355c:	9181                	srli	a1,a1,0x20
    8000355e:	058a                	slli	a1,a1,0x2
    80003560:	00b784b3          	add	s1,a5,a1
    80003564:	0004a983          	lw	s3,0(s1)
    80003568:	04098d63          	beqz	s3,800035c2 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000356c:	8552                	mv	a0,s4
    8000356e:	00000097          	auipc	ra,0x0
    80003572:	ce6080e7          	jalr	-794(ra) # 80003254 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003576:	854e                	mv	a0,s3
    80003578:	70a2                	ld	ra,40(sp)
    8000357a:	7402                	ld	s0,32(sp)
    8000357c:	64e2                	ld	s1,24(sp)
    8000357e:	6942                	ld	s2,16(sp)
    80003580:	69a2                	ld	s3,8(sp)
    80003582:	6a02                	ld	s4,0(sp)
    80003584:	6145                	addi	sp,sp,48
    80003586:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003588:	02059493          	slli	s1,a1,0x20
    8000358c:	9081                	srli	s1,s1,0x20
    8000358e:	048a                	slli	s1,s1,0x2
    80003590:	94aa                	add	s1,s1,a0
    80003592:	0504a983          	lw	s3,80(s1)
    80003596:	fe0990e3          	bnez	s3,80003576 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000359a:	4108                	lw	a0,0(a0)
    8000359c:	00000097          	auipc	ra,0x0
    800035a0:	e4a080e7          	jalr	-438(ra) # 800033e6 <balloc>
    800035a4:	0005099b          	sext.w	s3,a0
    800035a8:	0534a823          	sw	s3,80(s1)
    800035ac:	b7e9                	j	80003576 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035ae:	4108                	lw	a0,0(a0)
    800035b0:	00000097          	auipc	ra,0x0
    800035b4:	e36080e7          	jalr	-458(ra) # 800033e6 <balloc>
    800035b8:	0005059b          	sext.w	a1,a0
    800035bc:	08b92023          	sw	a1,128(s2)
    800035c0:	b759                	j	80003546 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800035c2:	00092503          	lw	a0,0(s2)
    800035c6:	00000097          	auipc	ra,0x0
    800035ca:	e20080e7          	jalr	-480(ra) # 800033e6 <balloc>
    800035ce:	0005099b          	sext.w	s3,a0
    800035d2:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800035d6:	8552                	mv	a0,s4
    800035d8:	00001097          	auipc	ra,0x1
    800035dc:	ef8080e7          	jalr	-264(ra) # 800044d0 <log_write>
    800035e0:	b771                	j	8000356c <bmap+0x54>
  panic("bmap: out of range");
    800035e2:	00005517          	auipc	a0,0x5
    800035e6:	fa650513          	addi	a0,a0,-90 # 80008588 <syscalls+0x128>
    800035ea:	ffffd097          	auipc	ra,0xffffd
    800035ee:	f54080e7          	jalr	-172(ra) # 8000053e <panic>

00000000800035f2 <iget>:
{
    800035f2:	7179                	addi	sp,sp,-48
    800035f4:	f406                	sd	ra,40(sp)
    800035f6:	f022                	sd	s0,32(sp)
    800035f8:	ec26                	sd	s1,24(sp)
    800035fa:	e84a                	sd	s2,16(sp)
    800035fc:	e44e                	sd	s3,8(sp)
    800035fe:	e052                	sd	s4,0(sp)
    80003600:	1800                	addi	s0,sp,48
    80003602:	89aa                	mv	s3,a0
    80003604:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003606:	0001c517          	auipc	a0,0x1c
    8000360a:	3c250513          	addi	a0,a0,962 # 8001f9c8 <itable>
    8000360e:	ffffd097          	auipc	ra,0xffffd
    80003612:	5d6080e7          	jalr	1494(ra) # 80000be4 <acquire>
  empty = 0;
    80003616:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003618:	0001c497          	auipc	s1,0x1c
    8000361c:	3c848493          	addi	s1,s1,968 # 8001f9e0 <itable+0x18>
    80003620:	0001e697          	auipc	a3,0x1e
    80003624:	e5068693          	addi	a3,a3,-432 # 80021470 <log>
    80003628:	a039                	j	80003636 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000362a:	02090b63          	beqz	s2,80003660 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000362e:	08848493          	addi	s1,s1,136
    80003632:	02d48a63          	beq	s1,a3,80003666 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003636:	449c                	lw	a5,8(s1)
    80003638:	fef059e3          	blez	a5,8000362a <iget+0x38>
    8000363c:	4098                	lw	a4,0(s1)
    8000363e:	ff3716e3          	bne	a4,s3,8000362a <iget+0x38>
    80003642:	40d8                	lw	a4,4(s1)
    80003644:	ff4713e3          	bne	a4,s4,8000362a <iget+0x38>
      ip->ref++;
    80003648:	2785                	addiw	a5,a5,1
    8000364a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000364c:	0001c517          	auipc	a0,0x1c
    80003650:	37c50513          	addi	a0,a0,892 # 8001f9c8 <itable>
    80003654:	ffffd097          	auipc	ra,0xffffd
    80003658:	644080e7          	jalr	1604(ra) # 80000c98 <release>
      return ip;
    8000365c:	8926                	mv	s2,s1
    8000365e:	a03d                	j	8000368c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003660:	f7f9                	bnez	a5,8000362e <iget+0x3c>
    80003662:	8926                	mv	s2,s1
    80003664:	b7e9                	j	8000362e <iget+0x3c>
  if(empty == 0)
    80003666:	02090c63          	beqz	s2,8000369e <iget+0xac>
  ip->dev = dev;
    8000366a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000366e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003672:	4785                	li	a5,1
    80003674:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003678:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000367c:	0001c517          	auipc	a0,0x1c
    80003680:	34c50513          	addi	a0,a0,844 # 8001f9c8 <itable>
    80003684:	ffffd097          	auipc	ra,0xffffd
    80003688:	614080e7          	jalr	1556(ra) # 80000c98 <release>
}
    8000368c:	854a                	mv	a0,s2
    8000368e:	70a2                	ld	ra,40(sp)
    80003690:	7402                	ld	s0,32(sp)
    80003692:	64e2                	ld	s1,24(sp)
    80003694:	6942                	ld	s2,16(sp)
    80003696:	69a2                	ld	s3,8(sp)
    80003698:	6a02                	ld	s4,0(sp)
    8000369a:	6145                	addi	sp,sp,48
    8000369c:	8082                	ret
    panic("iget: no inodes");
    8000369e:	00005517          	auipc	a0,0x5
    800036a2:	f0250513          	addi	a0,a0,-254 # 800085a0 <syscalls+0x140>
    800036a6:	ffffd097          	auipc	ra,0xffffd
    800036aa:	e98080e7          	jalr	-360(ra) # 8000053e <panic>

00000000800036ae <fsinit>:
fsinit(int dev) {
    800036ae:	7179                	addi	sp,sp,-48
    800036b0:	f406                	sd	ra,40(sp)
    800036b2:	f022                	sd	s0,32(sp)
    800036b4:	ec26                	sd	s1,24(sp)
    800036b6:	e84a                	sd	s2,16(sp)
    800036b8:	e44e                	sd	s3,8(sp)
    800036ba:	1800                	addi	s0,sp,48
    800036bc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036be:	4585                	li	a1,1
    800036c0:	00000097          	auipc	ra,0x0
    800036c4:	a64080e7          	jalr	-1436(ra) # 80003124 <bread>
    800036c8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036ca:	0001c997          	auipc	s3,0x1c
    800036ce:	2de98993          	addi	s3,s3,734 # 8001f9a8 <sb>
    800036d2:	02000613          	li	a2,32
    800036d6:	05850593          	addi	a1,a0,88
    800036da:	854e                	mv	a0,s3
    800036dc:	ffffd097          	auipc	ra,0xffffd
    800036e0:	664080e7          	jalr	1636(ra) # 80000d40 <memmove>
  brelse(bp);
    800036e4:	8526                	mv	a0,s1
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	b6e080e7          	jalr	-1170(ra) # 80003254 <brelse>
  if(sb.magic != FSMAGIC)
    800036ee:	0009a703          	lw	a4,0(s3)
    800036f2:	102037b7          	lui	a5,0x10203
    800036f6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036fa:	02f71263          	bne	a4,a5,8000371e <fsinit+0x70>
  initlog(dev, &sb);
    800036fe:	0001c597          	auipc	a1,0x1c
    80003702:	2aa58593          	addi	a1,a1,682 # 8001f9a8 <sb>
    80003706:	854a                	mv	a0,s2
    80003708:	00001097          	auipc	ra,0x1
    8000370c:	b4c080e7          	jalr	-1204(ra) # 80004254 <initlog>
}
    80003710:	70a2                	ld	ra,40(sp)
    80003712:	7402                	ld	s0,32(sp)
    80003714:	64e2                	ld	s1,24(sp)
    80003716:	6942                	ld	s2,16(sp)
    80003718:	69a2                	ld	s3,8(sp)
    8000371a:	6145                	addi	sp,sp,48
    8000371c:	8082                	ret
    panic("invalid file system");
    8000371e:	00005517          	auipc	a0,0x5
    80003722:	e9250513          	addi	a0,a0,-366 # 800085b0 <syscalls+0x150>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	e18080e7          	jalr	-488(ra) # 8000053e <panic>

000000008000372e <iinit>:
{
    8000372e:	7179                	addi	sp,sp,-48
    80003730:	f406                	sd	ra,40(sp)
    80003732:	f022                	sd	s0,32(sp)
    80003734:	ec26                	sd	s1,24(sp)
    80003736:	e84a                	sd	s2,16(sp)
    80003738:	e44e                	sd	s3,8(sp)
    8000373a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000373c:	00005597          	auipc	a1,0x5
    80003740:	e8c58593          	addi	a1,a1,-372 # 800085c8 <syscalls+0x168>
    80003744:	0001c517          	auipc	a0,0x1c
    80003748:	28450513          	addi	a0,a0,644 # 8001f9c8 <itable>
    8000374c:	ffffd097          	auipc	ra,0xffffd
    80003750:	408080e7          	jalr	1032(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003754:	0001c497          	auipc	s1,0x1c
    80003758:	29c48493          	addi	s1,s1,668 # 8001f9f0 <itable+0x28>
    8000375c:	0001e997          	auipc	s3,0x1e
    80003760:	d2498993          	addi	s3,s3,-732 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003764:	00005917          	auipc	s2,0x5
    80003768:	e6c90913          	addi	s2,s2,-404 # 800085d0 <syscalls+0x170>
    8000376c:	85ca                	mv	a1,s2
    8000376e:	8526                	mv	a0,s1
    80003770:	00001097          	auipc	ra,0x1
    80003774:	e46080e7          	jalr	-442(ra) # 800045b6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003778:	08848493          	addi	s1,s1,136
    8000377c:	ff3498e3          	bne	s1,s3,8000376c <iinit+0x3e>
}
    80003780:	70a2                	ld	ra,40(sp)
    80003782:	7402                	ld	s0,32(sp)
    80003784:	64e2                	ld	s1,24(sp)
    80003786:	6942                	ld	s2,16(sp)
    80003788:	69a2                	ld	s3,8(sp)
    8000378a:	6145                	addi	sp,sp,48
    8000378c:	8082                	ret

000000008000378e <ialloc>:
{
    8000378e:	715d                	addi	sp,sp,-80
    80003790:	e486                	sd	ra,72(sp)
    80003792:	e0a2                	sd	s0,64(sp)
    80003794:	fc26                	sd	s1,56(sp)
    80003796:	f84a                	sd	s2,48(sp)
    80003798:	f44e                	sd	s3,40(sp)
    8000379a:	f052                	sd	s4,32(sp)
    8000379c:	ec56                	sd	s5,24(sp)
    8000379e:	e85a                	sd	s6,16(sp)
    800037a0:	e45e                	sd	s7,8(sp)
    800037a2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037a4:	0001c717          	auipc	a4,0x1c
    800037a8:	21072703          	lw	a4,528(a4) # 8001f9b4 <sb+0xc>
    800037ac:	4785                	li	a5,1
    800037ae:	04e7fa63          	bgeu	a5,a4,80003802 <ialloc+0x74>
    800037b2:	8aaa                	mv	s5,a0
    800037b4:	8bae                	mv	s7,a1
    800037b6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037b8:	0001ca17          	auipc	s4,0x1c
    800037bc:	1f0a0a13          	addi	s4,s4,496 # 8001f9a8 <sb>
    800037c0:	00048b1b          	sext.w	s6,s1
    800037c4:	0044d593          	srli	a1,s1,0x4
    800037c8:	018a2783          	lw	a5,24(s4)
    800037cc:	9dbd                	addw	a1,a1,a5
    800037ce:	8556                	mv	a0,s5
    800037d0:	00000097          	auipc	ra,0x0
    800037d4:	954080e7          	jalr	-1708(ra) # 80003124 <bread>
    800037d8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037da:	05850993          	addi	s3,a0,88
    800037de:	00f4f793          	andi	a5,s1,15
    800037e2:	079a                	slli	a5,a5,0x6
    800037e4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037e6:	00099783          	lh	a5,0(s3)
    800037ea:	c785                	beqz	a5,80003812 <ialloc+0x84>
    brelse(bp);
    800037ec:	00000097          	auipc	ra,0x0
    800037f0:	a68080e7          	jalr	-1432(ra) # 80003254 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037f4:	0485                	addi	s1,s1,1
    800037f6:	00ca2703          	lw	a4,12(s4)
    800037fa:	0004879b          	sext.w	a5,s1
    800037fe:	fce7e1e3          	bltu	a5,a4,800037c0 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003802:	00005517          	auipc	a0,0x5
    80003806:	dd650513          	addi	a0,a0,-554 # 800085d8 <syscalls+0x178>
    8000380a:	ffffd097          	auipc	ra,0xffffd
    8000380e:	d34080e7          	jalr	-716(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003812:	04000613          	li	a2,64
    80003816:	4581                	li	a1,0
    80003818:	854e                	mv	a0,s3
    8000381a:	ffffd097          	auipc	ra,0xffffd
    8000381e:	4c6080e7          	jalr	1222(ra) # 80000ce0 <memset>
      dip->type = type;
    80003822:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003826:	854a                	mv	a0,s2
    80003828:	00001097          	auipc	ra,0x1
    8000382c:	ca8080e7          	jalr	-856(ra) # 800044d0 <log_write>
      brelse(bp);
    80003830:	854a                	mv	a0,s2
    80003832:	00000097          	auipc	ra,0x0
    80003836:	a22080e7          	jalr	-1502(ra) # 80003254 <brelse>
      return iget(dev, inum);
    8000383a:	85da                	mv	a1,s6
    8000383c:	8556                	mv	a0,s5
    8000383e:	00000097          	auipc	ra,0x0
    80003842:	db4080e7          	jalr	-588(ra) # 800035f2 <iget>
}
    80003846:	60a6                	ld	ra,72(sp)
    80003848:	6406                	ld	s0,64(sp)
    8000384a:	74e2                	ld	s1,56(sp)
    8000384c:	7942                	ld	s2,48(sp)
    8000384e:	79a2                	ld	s3,40(sp)
    80003850:	7a02                	ld	s4,32(sp)
    80003852:	6ae2                	ld	s5,24(sp)
    80003854:	6b42                	ld	s6,16(sp)
    80003856:	6ba2                	ld	s7,8(sp)
    80003858:	6161                	addi	sp,sp,80
    8000385a:	8082                	ret

000000008000385c <iupdate>:
{
    8000385c:	1101                	addi	sp,sp,-32
    8000385e:	ec06                	sd	ra,24(sp)
    80003860:	e822                	sd	s0,16(sp)
    80003862:	e426                	sd	s1,8(sp)
    80003864:	e04a                	sd	s2,0(sp)
    80003866:	1000                	addi	s0,sp,32
    80003868:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000386a:	415c                	lw	a5,4(a0)
    8000386c:	0047d79b          	srliw	a5,a5,0x4
    80003870:	0001c597          	auipc	a1,0x1c
    80003874:	1505a583          	lw	a1,336(a1) # 8001f9c0 <sb+0x18>
    80003878:	9dbd                	addw	a1,a1,a5
    8000387a:	4108                	lw	a0,0(a0)
    8000387c:	00000097          	auipc	ra,0x0
    80003880:	8a8080e7          	jalr	-1880(ra) # 80003124 <bread>
    80003884:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003886:	05850793          	addi	a5,a0,88
    8000388a:	40c8                	lw	a0,4(s1)
    8000388c:	893d                	andi	a0,a0,15
    8000388e:	051a                	slli	a0,a0,0x6
    80003890:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003892:	04449703          	lh	a4,68(s1)
    80003896:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000389a:	04649703          	lh	a4,70(s1)
    8000389e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038a2:	04849703          	lh	a4,72(s1)
    800038a6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038aa:	04a49703          	lh	a4,74(s1)
    800038ae:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038b2:	44f8                	lw	a4,76(s1)
    800038b4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038b6:	03400613          	li	a2,52
    800038ba:	05048593          	addi	a1,s1,80
    800038be:	0531                	addi	a0,a0,12
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	480080e7          	jalr	1152(ra) # 80000d40 <memmove>
  log_write(bp);
    800038c8:	854a                	mv	a0,s2
    800038ca:	00001097          	auipc	ra,0x1
    800038ce:	c06080e7          	jalr	-1018(ra) # 800044d0 <log_write>
  brelse(bp);
    800038d2:	854a                	mv	a0,s2
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	980080e7          	jalr	-1664(ra) # 80003254 <brelse>
}
    800038dc:	60e2                	ld	ra,24(sp)
    800038de:	6442                	ld	s0,16(sp)
    800038e0:	64a2                	ld	s1,8(sp)
    800038e2:	6902                	ld	s2,0(sp)
    800038e4:	6105                	addi	sp,sp,32
    800038e6:	8082                	ret

00000000800038e8 <idup>:
{
    800038e8:	1101                	addi	sp,sp,-32
    800038ea:	ec06                	sd	ra,24(sp)
    800038ec:	e822                	sd	s0,16(sp)
    800038ee:	e426                	sd	s1,8(sp)
    800038f0:	1000                	addi	s0,sp,32
    800038f2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038f4:	0001c517          	auipc	a0,0x1c
    800038f8:	0d450513          	addi	a0,a0,212 # 8001f9c8 <itable>
    800038fc:	ffffd097          	auipc	ra,0xffffd
    80003900:	2e8080e7          	jalr	744(ra) # 80000be4 <acquire>
  ip->ref++;
    80003904:	449c                	lw	a5,8(s1)
    80003906:	2785                	addiw	a5,a5,1
    80003908:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000390a:	0001c517          	auipc	a0,0x1c
    8000390e:	0be50513          	addi	a0,a0,190 # 8001f9c8 <itable>
    80003912:	ffffd097          	auipc	ra,0xffffd
    80003916:	386080e7          	jalr	902(ra) # 80000c98 <release>
}
    8000391a:	8526                	mv	a0,s1
    8000391c:	60e2                	ld	ra,24(sp)
    8000391e:	6442                	ld	s0,16(sp)
    80003920:	64a2                	ld	s1,8(sp)
    80003922:	6105                	addi	sp,sp,32
    80003924:	8082                	ret

0000000080003926 <ilock>:
{
    80003926:	1101                	addi	sp,sp,-32
    80003928:	ec06                	sd	ra,24(sp)
    8000392a:	e822                	sd	s0,16(sp)
    8000392c:	e426                	sd	s1,8(sp)
    8000392e:	e04a                	sd	s2,0(sp)
    80003930:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003932:	c115                	beqz	a0,80003956 <ilock+0x30>
    80003934:	84aa                	mv	s1,a0
    80003936:	451c                	lw	a5,8(a0)
    80003938:	00f05f63          	blez	a5,80003956 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000393c:	0541                	addi	a0,a0,16
    8000393e:	00001097          	auipc	ra,0x1
    80003942:	cb2080e7          	jalr	-846(ra) # 800045f0 <acquiresleep>
  if(ip->valid == 0){
    80003946:	40bc                	lw	a5,64(s1)
    80003948:	cf99                	beqz	a5,80003966 <ilock+0x40>
}
    8000394a:	60e2                	ld	ra,24(sp)
    8000394c:	6442                	ld	s0,16(sp)
    8000394e:	64a2                	ld	s1,8(sp)
    80003950:	6902                	ld	s2,0(sp)
    80003952:	6105                	addi	sp,sp,32
    80003954:	8082                	ret
    panic("ilock");
    80003956:	00005517          	auipc	a0,0x5
    8000395a:	c9a50513          	addi	a0,a0,-870 # 800085f0 <syscalls+0x190>
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	be0080e7          	jalr	-1056(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003966:	40dc                	lw	a5,4(s1)
    80003968:	0047d79b          	srliw	a5,a5,0x4
    8000396c:	0001c597          	auipc	a1,0x1c
    80003970:	0545a583          	lw	a1,84(a1) # 8001f9c0 <sb+0x18>
    80003974:	9dbd                	addw	a1,a1,a5
    80003976:	4088                	lw	a0,0(s1)
    80003978:	fffff097          	auipc	ra,0xfffff
    8000397c:	7ac080e7          	jalr	1964(ra) # 80003124 <bread>
    80003980:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003982:	05850593          	addi	a1,a0,88
    80003986:	40dc                	lw	a5,4(s1)
    80003988:	8bbd                	andi	a5,a5,15
    8000398a:	079a                	slli	a5,a5,0x6
    8000398c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000398e:	00059783          	lh	a5,0(a1)
    80003992:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003996:	00259783          	lh	a5,2(a1)
    8000399a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000399e:	00459783          	lh	a5,4(a1)
    800039a2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039a6:	00659783          	lh	a5,6(a1)
    800039aa:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039ae:	459c                	lw	a5,8(a1)
    800039b0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039b2:	03400613          	li	a2,52
    800039b6:	05b1                	addi	a1,a1,12
    800039b8:	05048513          	addi	a0,s1,80
    800039bc:	ffffd097          	auipc	ra,0xffffd
    800039c0:	384080e7          	jalr	900(ra) # 80000d40 <memmove>
    brelse(bp);
    800039c4:	854a                	mv	a0,s2
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	88e080e7          	jalr	-1906(ra) # 80003254 <brelse>
    ip->valid = 1;
    800039ce:	4785                	li	a5,1
    800039d0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039d2:	04449783          	lh	a5,68(s1)
    800039d6:	fbb5                	bnez	a5,8000394a <ilock+0x24>
      panic("ilock: no type");
    800039d8:	00005517          	auipc	a0,0x5
    800039dc:	c2050513          	addi	a0,a0,-992 # 800085f8 <syscalls+0x198>
    800039e0:	ffffd097          	auipc	ra,0xffffd
    800039e4:	b5e080e7          	jalr	-1186(ra) # 8000053e <panic>

00000000800039e8 <iunlock>:
{
    800039e8:	1101                	addi	sp,sp,-32
    800039ea:	ec06                	sd	ra,24(sp)
    800039ec:	e822                	sd	s0,16(sp)
    800039ee:	e426                	sd	s1,8(sp)
    800039f0:	e04a                	sd	s2,0(sp)
    800039f2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039f4:	c905                	beqz	a0,80003a24 <iunlock+0x3c>
    800039f6:	84aa                	mv	s1,a0
    800039f8:	01050913          	addi	s2,a0,16
    800039fc:	854a                	mv	a0,s2
    800039fe:	00001097          	auipc	ra,0x1
    80003a02:	c8c080e7          	jalr	-884(ra) # 8000468a <holdingsleep>
    80003a06:	cd19                	beqz	a0,80003a24 <iunlock+0x3c>
    80003a08:	449c                	lw	a5,8(s1)
    80003a0a:	00f05d63          	blez	a5,80003a24 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a0e:	854a                	mv	a0,s2
    80003a10:	00001097          	auipc	ra,0x1
    80003a14:	c36080e7          	jalr	-970(ra) # 80004646 <releasesleep>
}
    80003a18:	60e2                	ld	ra,24(sp)
    80003a1a:	6442                	ld	s0,16(sp)
    80003a1c:	64a2                	ld	s1,8(sp)
    80003a1e:	6902                	ld	s2,0(sp)
    80003a20:	6105                	addi	sp,sp,32
    80003a22:	8082                	ret
    panic("iunlock");
    80003a24:	00005517          	auipc	a0,0x5
    80003a28:	be450513          	addi	a0,a0,-1052 # 80008608 <syscalls+0x1a8>
    80003a2c:	ffffd097          	auipc	ra,0xffffd
    80003a30:	b12080e7          	jalr	-1262(ra) # 8000053e <panic>

0000000080003a34 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a34:	7179                	addi	sp,sp,-48
    80003a36:	f406                	sd	ra,40(sp)
    80003a38:	f022                	sd	s0,32(sp)
    80003a3a:	ec26                	sd	s1,24(sp)
    80003a3c:	e84a                	sd	s2,16(sp)
    80003a3e:	e44e                	sd	s3,8(sp)
    80003a40:	e052                	sd	s4,0(sp)
    80003a42:	1800                	addi	s0,sp,48
    80003a44:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a46:	05050493          	addi	s1,a0,80
    80003a4a:	08050913          	addi	s2,a0,128
    80003a4e:	a021                	j	80003a56 <itrunc+0x22>
    80003a50:	0491                	addi	s1,s1,4
    80003a52:	01248d63          	beq	s1,s2,80003a6c <itrunc+0x38>
    if(ip->addrs[i]){
    80003a56:	408c                	lw	a1,0(s1)
    80003a58:	dde5                	beqz	a1,80003a50 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a5a:	0009a503          	lw	a0,0(s3)
    80003a5e:	00000097          	auipc	ra,0x0
    80003a62:	90c080e7          	jalr	-1780(ra) # 8000336a <bfree>
      ip->addrs[i] = 0;
    80003a66:	0004a023          	sw	zero,0(s1)
    80003a6a:	b7dd                	j	80003a50 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a6c:	0809a583          	lw	a1,128(s3)
    80003a70:	e185                	bnez	a1,80003a90 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a72:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a76:	854e                	mv	a0,s3
    80003a78:	00000097          	auipc	ra,0x0
    80003a7c:	de4080e7          	jalr	-540(ra) # 8000385c <iupdate>
}
    80003a80:	70a2                	ld	ra,40(sp)
    80003a82:	7402                	ld	s0,32(sp)
    80003a84:	64e2                	ld	s1,24(sp)
    80003a86:	6942                	ld	s2,16(sp)
    80003a88:	69a2                	ld	s3,8(sp)
    80003a8a:	6a02                	ld	s4,0(sp)
    80003a8c:	6145                	addi	sp,sp,48
    80003a8e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a90:	0009a503          	lw	a0,0(s3)
    80003a94:	fffff097          	auipc	ra,0xfffff
    80003a98:	690080e7          	jalr	1680(ra) # 80003124 <bread>
    80003a9c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a9e:	05850493          	addi	s1,a0,88
    80003aa2:	45850913          	addi	s2,a0,1112
    80003aa6:	a811                	j	80003aba <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003aa8:	0009a503          	lw	a0,0(s3)
    80003aac:	00000097          	auipc	ra,0x0
    80003ab0:	8be080e7          	jalr	-1858(ra) # 8000336a <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003ab4:	0491                	addi	s1,s1,4
    80003ab6:	01248563          	beq	s1,s2,80003ac0 <itrunc+0x8c>
      if(a[j])
    80003aba:	408c                	lw	a1,0(s1)
    80003abc:	dde5                	beqz	a1,80003ab4 <itrunc+0x80>
    80003abe:	b7ed                	j	80003aa8 <itrunc+0x74>
    brelse(bp);
    80003ac0:	8552                	mv	a0,s4
    80003ac2:	fffff097          	auipc	ra,0xfffff
    80003ac6:	792080e7          	jalr	1938(ra) # 80003254 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003aca:	0809a583          	lw	a1,128(s3)
    80003ace:	0009a503          	lw	a0,0(s3)
    80003ad2:	00000097          	auipc	ra,0x0
    80003ad6:	898080e7          	jalr	-1896(ra) # 8000336a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ada:	0809a023          	sw	zero,128(s3)
    80003ade:	bf51                	j	80003a72 <itrunc+0x3e>

0000000080003ae0 <iput>:
{
    80003ae0:	1101                	addi	sp,sp,-32
    80003ae2:	ec06                	sd	ra,24(sp)
    80003ae4:	e822                	sd	s0,16(sp)
    80003ae6:	e426                	sd	s1,8(sp)
    80003ae8:	e04a                	sd	s2,0(sp)
    80003aea:	1000                	addi	s0,sp,32
    80003aec:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003aee:	0001c517          	auipc	a0,0x1c
    80003af2:	eda50513          	addi	a0,a0,-294 # 8001f9c8 <itable>
    80003af6:	ffffd097          	auipc	ra,0xffffd
    80003afa:	0ee080e7          	jalr	238(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003afe:	4498                	lw	a4,8(s1)
    80003b00:	4785                	li	a5,1
    80003b02:	02f70363          	beq	a4,a5,80003b28 <iput+0x48>
  ip->ref--;
    80003b06:	449c                	lw	a5,8(s1)
    80003b08:	37fd                	addiw	a5,a5,-1
    80003b0a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b0c:	0001c517          	auipc	a0,0x1c
    80003b10:	ebc50513          	addi	a0,a0,-324 # 8001f9c8 <itable>
    80003b14:	ffffd097          	auipc	ra,0xffffd
    80003b18:	184080e7          	jalr	388(ra) # 80000c98 <release>
}
    80003b1c:	60e2                	ld	ra,24(sp)
    80003b1e:	6442                	ld	s0,16(sp)
    80003b20:	64a2                	ld	s1,8(sp)
    80003b22:	6902                	ld	s2,0(sp)
    80003b24:	6105                	addi	sp,sp,32
    80003b26:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b28:	40bc                	lw	a5,64(s1)
    80003b2a:	dff1                	beqz	a5,80003b06 <iput+0x26>
    80003b2c:	04a49783          	lh	a5,74(s1)
    80003b30:	fbf9                	bnez	a5,80003b06 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b32:	01048913          	addi	s2,s1,16
    80003b36:	854a                	mv	a0,s2
    80003b38:	00001097          	auipc	ra,0x1
    80003b3c:	ab8080e7          	jalr	-1352(ra) # 800045f0 <acquiresleep>
    release(&itable.lock);
    80003b40:	0001c517          	auipc	a0,0x1c
    80003b44:	e8850513          	addi	a0,a0,-376 # 8001f9c8 <itable>
    80003b48:	ffffd097          	auipc	ra,0xffffd
    80003b4c:	150080e7          	jalr	336(ra) # 80000c98 <release>
    itrunc(ip);
    80003b50:	8526                	mv	a0,s1
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	ee2080e7          	jalr	-286(ra) # 80003a34 <itrunc>
    ip->type = 0;
    80003b5a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b5e:	8526                	mv	a0,s1
    80003b60:	00000097          	auipc	ra,0x0
    80003b64:	cfc080e7          	jalr	-772(ra) # 8000385c <iupdate>
    ip->valid = 0;
    80003b68:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b6c:	854a                	mv	a0,s2
    80003b6e:	00001097          	auipc	ra,0x1
    80003b72:	ad8080e7          	jalr	-1320(ra) # 80004646 <releasesleep>
    acquire(&itable.lock);
    80003b76:	0001c517          	auipc	a0,0x1c
    80003b7a:	e5250513          	addi	a0,a0,-430 # 8001f9c8 <itable>
    80003b7e:	ffffd097          	auipc	ra,0xffffd
    80003b82:	066080e7          	jalr	102(ra) # 80000be4 <acquire>
    80003b86:	b741                	j	80003b06 <iput+0x26>

0000000080003b88 <iunlockput>:
{
    80003b88:	1101                	addi	sp,sp,-32
    80003b8a:	ec06                	sd	ra,24(sp)
    80003b8c:	e822                	sd	s0,16(sp)
    80003b8e:	e426                	sd	s1,8(sp)
    80003b90:	1000                	addi	s0,sp,32
    80003b92:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b94:	00000097          	auipc	ra,0x0
    80003b98:	e54080e7          	jalr	-428(ra) # 800039e8 <iunlock>
  iput(ip);
    80003b9c:	8526                	mv	a0,s1
    80003b9e:	00000097          	auipc	ra,0x0
    80003ba2:	f42080e7          	jalr	-190(ra) # 80003ae0 <iput>
}
    80003ba6:	60e2                	ld	ra,24(sp)
    80003ba8:	6442                	ld	s0,16(sp)
    80003baa:	64a2                	ld	s1,8(sp)
    80003bac:	6105                	addi	sp,sp,32
    80003bae:	8082                	ret

0000000080003bb0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bb0:	1141                	addi	sp,sp,-16
    80003bb2:	e422                	sd	s0,8(sp)
    80003bb4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bb6:	411c                	lw	a5,0(a0)
    80003bb8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bba:	415c                	lw	a5,4(a0)
    80003bbc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bbe:	04451783          	lh	a5,68(a0)
    80003bc2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bc6:	04a51783          	lh	a5,74(a0)
    80003bca:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003bce:	04c56783          	lwu	a5,76(a0)
    80003bd2:	e99c                	sd	a5,16(a1)
}
    80003bd4:	6422                	ld	s0,8(sp)
    80003bd6:	0141                	addi	sp,sp,16
    80003bd8:	8082                	ret

0000000080003bda <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bda:	457c                	lw	a5,76(a0)
    80003bdc:	0ed7e963          	bltu	a5,a3,80003cce <readi+0xf4>
{
    80003be0:	7159                	addi	sp,sp,-112
    80003be2:	f486                	sd	ra,104(sp)
    80003be4:	f0a2                	sd	s0,96(sp)
    80003be6:	eca6                	sd	s1,88(sp)
    80003be8:	e8ca                	sd	s2,80(sp)
    80003bea:	e4ce                	sd	s3,72(sp)
    80003bec:	e0d2                	sd	s4,64(sp)
    80003bee:	fc56                	sd	s5,56(sp)
    80003bf0:	f85a                	sd	s6,48(sp)
    80003bf2:	f45e                	sd	s7,40(sp)
    80003bf4:	f062                	sd	s8,32(sp)
    80003bf6:	ec66                	sd	s9,24(sp)
    80003bf8:	e86a                	sd	s10,16(sp)
    80003bfa:	e46e                	sd	s11,8(sp)
    80003bfc:	1880                	addi	s0,sp,112
    80003bfe:	8baa                	mv	s7,a0
    80003c00:	8c2e                	mv	s8,a1
    80003c02:	8ab2                	mv	s5,a2
    80003c04:	84b6                	mv	s1,a3
    80003c06:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c08:	9f35                	addw	a4,a4,a3
    return 0;
    80003c0a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c0c:	0ad76063          	bltu	a4,a3,80003cac <readi+0xd2>
  if(off + n > ip->size)
    80003c10:	00e7f463          	bgeu	a5,a4,80003c18 <readi+0x3e>
    n = ip->size - off;
    80003c14:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c18:	0a0b0963          	beqz	s6,80003cca <readi+0xf0>
    80003c1c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c1e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c22:	5cfd                	li	s9,-1
    80003c24:	a82d                	j	80003c5e <readi+0x84>
    80003c26:	020a1d93          	slli	s11,s4,0x20
    80003c2a:	020ddd93          	srli	s11,s11,0x20
    80003c2e:	05890613          	addi	a2,s2,88
    80003c32:	86ee                	mv	a3,s11
    80003c34:	963a                	add	a2,a2,a4
    80003c36:	85d6                	mv	a1,s5
    80003c38:	8562                	mv	a0,s8
    80003c3a:	fffff097          	auipc	ra,0xfffff
    80003c3e:	a42080e7          	jalr	-1470(ra) # 8000267c <either_copyout>
    80003c42:	05950d63          	beq	a0,s9,80003c9c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c46:	854a                	mv	a0,s2
    80003c48:	fffff097          	auipc	ra,0xfffff
    80003c4c:	60c080e7          	jalr	1548(ra) # 80003254 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c50:	013a09bb          	addw	s3,s4,s3
    80003c54:	009a04bb          	addw	s1,s4,s1
    80003c58:	9aee                	add	s5,s5,s11
    80003c5a:	0569f763          	bgeu	s3,s6,80003ca8 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c5e:	000ba903          	lw	s2,0(s7)
    80003c62:	00a4d59b          	srliw	a1,s1,0xa
    80003c66:	855e                	mv	a0,s7
    80003c68:	00000097          	auipc	ra,0x0
    80003c6c:	8b0080e7          	jalr	-1872(ra) # 80003518 <bmap>
    80003c70:	0005059b          	sext.w	a1,a0
    80003c74:	854a                	mv	a0,s2
    80003c76:	fffff097          	auipc	ra,0xfffff
    80003c7a:	4ae080e7          	jalr	1198(ra) # 80003124 <bread>
    80003c7e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c80:	3ff4f713          	andi	a4,s1,1023
    80003c84:	40ed07bb          	subw	a5,s10,a4
    80003c88:	413b06bb          	subw	a3,s6,s3
    80003c8c:	8a3e                	mv	s4,a5
    80003c8e:	2781                	sext.w	a5,a5
    80003c90:	0006861b          	sext.w	a2,a3
    80003c94:	f8f679e3          	bgeu	a2,a5,80003c26 <readi+0x4c>
    80003c98:	8a36                	mv	s4,a3
    80003c9a:	b771                	j	80003c26 <readi+0x4c>
      brelse(bp);
    80003c9c:	854a                	mv	a0,s2
    80003c9e:	fffff097          	auipc	ra,0xfffff
    80003ca2:	5b6080e7          	jalr	1462(ra) # 80003254 <brelse>
      tot = -1;
    80003ca6:	59fd                	li	s3,-1
  }
  return tot;
    80003ca8:	0009851b          	sext.w	a0,s3
}
    80003cac:	70a6                	ld	ra,104(sp)
    80003cae:	7406                	ld	s0,96(sp)
    80003cb0:	64e6                	ld	s1,88(sp)
    80003cb2:	6946                	ld	s2,80(sp)
    80003cb4:	69a6                	ld	s3,72(sp)
    80003cb6:	6a06                	ld	s4,64(sp)
    80003cb8:	7ae2                	ld	s5,56(sp)
    80003cba:	7b42                	ld	s6,48(sp)
    80003cbc:	7ba2                	ld	s7,40(sp)
    80003cbe:	7c02                	ld	s8,32(sp)
    80003cc0:	6ce2                	ld	s9,24(sp)
    80003cc2:	6d42                	ld	s10,16(sp)
    80003cc4:	6da2                	ld	s11,8(sp)
    80003cc6:	6165                	addi	sp,sp,112
    80003cc8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cca:	89da                	mv	s3,s6
    80003ccc:	bff1                	j	80003ca8 <readi+0xce>
    return 0;
    80003cce:	4501                	li	a0,0
}
    80003cd0:	8082                	ret

0000000080003cd2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cd2:	457c                	lw	a5,76(a0)
    80003cd4:	10d7e863          	bltu	a5,a3,80003de4 <writei+0x112>
{
    80003cd8:	7159                	addi	sp,sp,-112
    80003cda:	f486                	sd	ra,104(sp)
    80003cdc:	f0a2                	sd	s0,96(sp)
    80003cde:	eca6                	sd	s1,88(sp)
    80003ce0:	e8ca                	sd	s2,80(sp)
    80003ce2:	e4ce                	sd	s3,72(sp)
    80003ce4:	e0d2                	sd	s4,64(sp)
    80003ce6:	fc56                	sd	s5,56(sp)
    80003ce8:	f85a                	sd	s6,48(sp)
    80003cea:	f45e                	sd	s7,40(sp)
    80003cec:	f062                	sd	s8,32(sp)
    80003cee:	ec66                	sd	s9,24(sp)
    80003cf0:	e86a                	sd	s10,16(sp)
    80003cf2:	e46e                	sd	s11,8(sp)
    80003cf4:	1880                	addi	s0,sp,112
    80003cf6:	8b2a                	mv	s6,a0
    80003cf8:	8c2e                	mv	s8,a1
    80003cfa:	8ab2                	mv	s5,a2
    80003cfc:	8936                	mv	s2,a3
    80003cfe:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d00:	00e687bb          	addw	a5,a3,a4
    80003d04:	0ed7e263          	bltu	a5,a3,80003de8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d08:	00043737          	lui	a4,0x43
    80003d0c:	0ef76063          	bltu	a4,a5,80003dec <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d10:	0c0b8863          	beqz	s7,80003de0 <writei+0x10e>
    80003d14:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d16:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d1a:	5cfd                	li	s9,-1
    80003d1c:	a091                	j	80003d60 <writei+0x8e>
    80003d1e:	02099d93          	slli	s11,s3,0x20
    80003d22:	020ddd93          	srli	s11,s11,0x20
    80003d26:	05848513          	addi	a0,s1,88
    80003d2a:	86ee                	mv	a3,s11
    80003d2c:	8656                	mv	a2,s5
    80003d2e:	85e2                	mv	a1,s8
    80003d30:	953a                	add	a0,a0,a4
    80003d32:	fffff097          	auipc	ra,0xfffff
    80003d36:	9a0080e7          	jalr	-1632(ra) # 800026d2 <either_copyin>
    80003d3a:	07950263          	beq	a0,s9,80003d9e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d3e:	8526                	mv	a0,s1
    80003d40:	00000097          	auipc	ra,0x0
    80003d44:	790080e7          	jalr	1936(ra) # 800044d0 <log_write>
    brelse(bp);
    80003d48:	8526                	mv	a0,s1
    80003d4a:	fffff097          	auipc	ra,0xfffff
    80003d4e:	50a080e7          	jalr	1290(ra) # 80003254 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d52:	01498a3b          	addw	s4,s3,s4
    80003d56:	0129893b          	addw	s2,s3,s2
    80003d5a:	9aee                	add	s5,s5,s11
    80003d5c:	057a7663          	bgeu	s4,s7,80003da8 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d60:	000b2483          	lw	s1,0(s6)
    80003d64:	00a9559b          	srliw	a1,s2,0xa
    80003d68:	855a                	mv	a0,s6
    80003d6a:	fffff097          	auipc	ra,0xfffff
    80003d6e:	7ae080e7          	jalr	1966(ra) # 80003518 <bmap>
    80003d72:	0005059b          	sext.w	a1,a0
    80003d76:	8526                	mv	a0,s1
    80003d78:	fffff097          	auipc	ra,0xfffff
    80003d7c:	3ac080e7          	jalr	940(ra) # 80003124 <bread>
    80003d80:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d82:	3ff97713          	andi	a4,s2,1023
    80003d86:	40ed07bb          	subw	a5,s10,a4
    80003d8a:	414b86bb          	subw	a3,s7,s4
    80003d8e:	89be                	mv	s3,a5
    80003d90:	2781                	sext.w	a5,a5
    80003d92:	0006861b          	sext.w	a2,a3
    80003d96:	f8f674e3          	bgeu	a2,a5,80003d1e <writei+0x4c>
    80003d9a:	89b6                	mv	s3,a3
    80003d9c:	b749                	j	80003d1e <writei+0x4c>
      brelse(bp);
    80003d9e:	8526                	mv	a0,s1
    80003da0:	fffff097          	auipc	ra,0xfffff
    80003da4:	4b4080e7          	jalr	1204(ra) # 80003254 <brelse>
  }

  if(off > ip->size)
    80003da8:	04cb2783          	lw	a5,76(s6)
    80003dac:	0127f463          	bgeu	a5,s2,80003db4 <writei+0xe2>
    ip->size = off;
    80003db0:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003db4:	855a                	mv	a0,s6
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	aa6080e7          	jalr	-1370(ra) # 8000385c <iupdate>

  return tot;
    80003dbe:	000a051b          	sext.w	a0,s4
}
    80003dc2:	70a6                	ld	ra,104(sp)
    80003dc4:	7406                	ld	s0,96(sp)
    80003dc6:	64e6                	ld	s1,88(sp)
    80003dc8:	6946                	ld	s2,80(sp)
    80003dca:	69a6                	ld	s3,72(sp)
    80003dcc:	6a06                	ld	s4,64(sp)
    80003dce:	7ae2                	ld	s5,56(sp)
    80003dd0:	7b42                	ld	s6,48(sp)
    80003dd2:	7ba2                	ld	s7,40(sp)
    80003dd4:	7c02                	ld	s8,32(sp)
    80003dd6:	6ce2                	ld	s9,24(sp)
    80003dd8:	6d42                	ld	s10,16(sp)
    80003dda:	6da2                	ld	s11,8(sp)
    80003ddc:	6165                	addi	sp,sp,112
    80003dde:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003de0:	8a5e                	mv	s4,s7
    80003de2:	bfc9                	j	80003db4 <writei+0xe2>
    return -1;
    80003de4:	557d                	li	a0,-1
}
    80003de6:	8082                	ret
    return -1;
    80003de8:	557d                	li	a0,-1
    80003dea:	bfe1                	j	80003dc2 <writei+0xf0>
    return -1;
    80003dec:	557d                	li	a0,-1
    80003dee:	bfd1                	j	80003dc2 <writei+0xf0>

0000000080003df0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003df0:	1141                	addi	sp,sp,-16
    80003df2:	e406                	sd	ra,8(sp)
    80003df4:	e022                	sd	s0,0(sp)
    80003df6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003df8:	4639                	li	a2,14
    80003dfa:	ffffd097          	auipc	ra,0xffffd
    80003dfe:	fbe080e7          	jalr	-66(ra) # 80000db8 <strncmp>
}
    80003e02:	60a2                	ld	ra,8(sp)
    80003e04:	6402                	ld	s0,0(sp)
    80003e06:	0141                	addi	sp,sp,16
    80003e08:	8082                	ret

0000000080003e0a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e0a:	7139                	addi	sp,sp,-64
    80003e0c:	fc06                	sd	ra,56(sp)
    80003e0e:	f822                	sd	s0,48(sp)
    80003e10:	f426                	sd	s1,40(sp)
    80003e12:	f04a                	sd	s2,32(sp)
    80003e14:	ec4e                	sd	s3,24(sp)
    80003e16:	e852                	sd	s4,16(sp)
    80003e18:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e1a:	04451703          	lh	a4,68(a0)
    80003e1e:	4785                	li	a5,1
    80003e20:	00f71a63          	bne	a4,a5,80003e34 <dirlookup+0x2a>
    80003e24:	892a                	mv	s2,a0
    80003e26:	89ae                	mv	s3,a1
    80003e28:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e2a:	457c                	lw	a5,76(a0)
    80003e2c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e2e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e30:	e79d                	bnez	a5,80003e5e <dirlookup+0x54>
    80003e32:	a8a5                	j	80003eaa <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e34:	00004517          	auipc	a0,0x4
    80003e38:	7dc50513          	addi	a0,a0,2012 # 80008610 <syscalls+0x1b0>
    80003e3c:	ffffc097          	auipc	ra,0xffffc
    80003e40:	702080e7          	jalr	1794(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003e44:	00004517          	auipc	a0,0x4
    80003e48:	7e450513          	addi	a0,a0,2020 # 80008628 <syscalls+0x1c8>
    80003e4c:	ffffc097          	auipc	ra,0xffffc
    80003e50:	6f2080e7          	jalr	1778(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e54:	24c1                	addiw	s1,s1,16
    80003e56:	04c92783          	lw	a5,76(s2)
    80003e5a:	04f4f763          	bgeu	s1,a5,80003ea8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e5e:	4741                	li	a4,16
    80003e60:	86a6                	mv	a3,s1
    80003e62:	fc040613          	addi	a2,s0,-64
    80003e66:	4581                	li	a1,0
    80003e68:	854a                	mv	a0,s2
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	d70080e7          	jalr	-656(ra) # 80003bda <readi>
    80003e72:	47c1                	li	a5,16
    80003e74:	fcf518e3          	bne	a0,a5,80003e44 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e78:	fc045783          	lhu	a5,-64(s0)
    80003e7c:	dfe1                	beqz	a5,80003e54 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e7e:	fc240593          	addi	a1,s0,-62
    80003e82:	854e                	mv	a0,s3
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	f6c080e7          	jalr	-148(ra) # 80003df0 <namecmp>
    80003e8c:	f561                	bnez	a0,80003e54 <dirlookup+0x4a>
      if(poff)
    80003e8e:	000a0463          	beqz	s4,80003e96 <dirlookup+0x8c>
        *poff = off;
    80003e92:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e96:	fc045583          	lhu	a1,-64(s0)
    80003e9a:	00092503          	lw	a0,0(s2)
    80003e9e:	fffff097          	auipc	ra,0xfffff
    80003ea2:	754080e7          	jalr	1876(ra) # 800035f2 <iget>
    80003ea6:	a011                	j	80003eaa <dirlookup+0xa0>
  return 0;
    80003ea8:	4501                	li	a0,0
}
    80003eaa:	70e2                	ld	ra,56(sp)
    80003eac:	7442                	ld	s0,48(sp)
    80003eae:	74a2                	ld	s1,40(sp)
    80003eb0:	7902                	ld	s2,32(sp)
    80003eb2:	69e2                	ld	s3,24(sp)
    80003eb4:	6a42                	ld	s4,16(sp)
    80003eb6:	6121                	addi	sp,sp,64
    80003eb8:	8082                	ret

0000000080003eba <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003eba:	711d                	addi	sp,sp,-96
    80003ebc:	ec86                	sd	ra,88(sp)
    80003ebe:	e8a2                	sd	s0,80(sp)
    80003ec0:	e4a6                	sd	s1,72(sp)
    80003ec2:	e0ca                	sd	s2,64(sp)
    80003ec4:	fc4e                	sd	s3,56(sp)
    80003ec6:	f852                	sd	s4,48(sp)
    80003ec8:	f456                	sd	s5,40(sp)
    80003eca:	f05a                	sd	s6,32(sp)
    80003ecc:	ec5e                	sd	s7,24(sp)
    80003ece:	e862                	sd	s8,16(sp)
    80003ed0:	e466                	sd	s9,8(sp)
    80003ed2:	1080                	addi	s0,sp,96
    80003ed4:	84aa                	mv	s1,a0
    80003ed6:	8b2e                	mv	s6,a1
    80003ed8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003eda:	00054703          	lbu	a4,0(a0)
    80003ede:	02f00793          	li	a5,47
    80003ee2:	02f70363          	beq	a4,a5,80003f08 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ee6:	ffffe097          	auipc	ra,0xffffe
    80003eea:	ade080e7          	jalr	-1314(ra) # 800019c4 <myproc>
    80003eee:	15853503          	ld	a0,344(a0)
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	9f6080e7          	jalr	-1546(ra) # 800038e8 <idup>
    80003efa:	89aa                	mv	s3,a0
  while(*path == '/')
    80003efc:	02f00913          	li	s2,47
  len = path - s;
    80003f00:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f02:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f04:	4c05                	li	s8,1
    80003f06:	a865                	j	80003fbe <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f08:	4585                	li	a1,1
    80003f0a:	4505                	li	a0,1
    80003f0c:	fffff097          	auipc	ra,0xfffff
    80003f10:	6e6080e7          	jalr	1766(ra) # 800035f2 <iget>
    80003f14:	89aa                	mv	s3,a0
    80003f16:	b7dd                	j	80003efc <namex+0x42>
      iunlockput(ip);
    80003f18:	854e                	mv	a0,s3
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	c6e080e7          	jalr	-914(ra) # 80003b88 <iunlockput>
      return 0;
    80003f22:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f24:	854e                	mv	a0,s3
    80003f26:	60e6                	ld	ra,88(sp)
    80003f28:	6446                	ld	s0,80(sp)
    80003f2a:	64a6                	ld	s1,72(sp)
    80003f2c:	6906                	ld	s2,64(sp)
    80003f2e:	79e2                	ld	s3,56(sp)
    80003f30:	7a42                	ld	s4,48(sp)
    80003f32:	7aa2                	ld	s5,40(sp)
    80003f34:	7b02                	ld	s6,32(sp)
    80003f36:	6be2                	ld	s7,24(sp)
    80003f38:	6c42                	ld	s8,16(sp)
    80003f3a:	6ca2                	ld	s9,8(sp)
    80003f3c:	6125                	addi	sp,sp,96
    80003f3e:	8082                	ret
      iunlock(ip);
    80003f40:	854e                	mv	a0,s3
    80003f42:	00000097          	auipc	ra,0x0
    80003f46:	aa6080e7          	jalr	-1370(ra) # 800039e8 <iunlock>
      return ip;
    80003f4a:	bfe9                	j	80003f24 <namex+0x6a>
      iunlockput(ip);
    80003f4c:	854e                	mv	a0,s3
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	c3a080e7          	jalr	-966(ra) # 80003b88 <iunlockput>
      return 0;
    80003f56:	89d2                	mv	s3,s4
    80003f58:	b7f1                	j	80003f24 <namex+0x6a>
  len = path - s;
    80003f5a:	40b48633          	sub	a2,s1,a1
    80003f5e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f62:	094cd463          	bge	s9,s4,80003fea <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f66:	4639                	li	a2,14
    80003f68:	8556                	mv	a0,s5
    80003f6a:	ffffd097          	auipc	ra,0xffffd
    80003f6e:	dd6080e7          	jalr	-554(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003f72:	0004c783          	lbu	a5,0(s1)
    80003f76:	01279763          	bne	a5,s2,80003f84 <namex+0xca>
    path++;
    80003f7a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f7c:	0004c783          	lbu	a5,0(s1)
    80003f80:	ff278de3          	beq	a5,s2,80003f7a <namex+0xc0>
    ilock(ip);
    80003f84:	854e                	mv	a0,s3
    80003f86:	00000097          	auipc	ra,0x0
    80003f8a:	9a0080e7          	jalr	-1632(ra) # 80003926 <ilock>
    if(ip->type != T_DIR){
    80003f8e:	04499783          	lh	a5,68(s3)
    80003f92:	f98793e3          	bne	a5,s8,80003f18 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f96:	000b0563          	beqz	s6,80003fa0 <namex+0xe6>
    80003f9a:	0004c783          	lbu	a5,0(s1)
    80003f9e:	d3cd                	beqz	a5,80003f40 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fa0:	865e                	mv	a2,s7
    80003fa2:	85d6                	mv	a1,s5
    80003fa4:	854e                	mv	a0,s3
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	e64080e7          	jalr	-412(ra) # 80003e0a <dirlookup>
    80003fae:	8a2a                	mv	s4,a0
    80003fb0:	dd51                	beqz	a0,80003f4c <namex+0x92>
    iunlockput(ip);
    80003fb2:	854e                	mv	a0,s3
    80003fb4:	00000097          	auipc	ra,0x0
    80003fb8:	bd4080e7          	jalr	-1068(ra) # 80003b88 <iunlockput>
    ip = next;
    80003fbc:	89d2                	mv	s3,s4
  while(*path == '/')
    80003fbe:	0004c783          	lbu	a5,0(s1)
    80003fc2:	05279763          	bne	a5,s2,80004010 <namex+0x156>
    path++;
    80003fc6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fc8:	0004c783          	lbu	a5,0(s1)
    80003fcc:	ff278de3          	beq	a5,s2,80003fc6 <namex+0x10c>
  if(*path == 0)
    80003fd0:	c79d                	beqz	a5,80003ffe <namex+0x144>
    path++;
    80003fd2:	85a6                	mv	a1,s1
  len = path - s;
    80003fd4:	8a5e                	mv	s4,s7
    80003fd6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003fd8:	01278963          	beq	a5,s2,80003fea <namex+0x130>
    80003fdc:	dfbd                	beqz	a5,80003f5a <namex+0xa0>
    path++;
    80003fde:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003fe0:	0004c783          	lbu	a5,0(s1)
    80003fe4:	ff279ce3          	bne	a5,s2,80003fdc <namex+0x122>
    80003fe8:	bf8d                	j	80003f5a <namex+0xa0>
    memmove(name, s, len);
    80003fea:	2601                	sext.w	a2,a2
    80003fec:	8556                	mv	a0,s5
    80003fee:	ffffd097          	auipc	ra,0xffffd
    80003ff2:	d52080e7          	jalr	-686(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003ff6:	9a56                	add	s4,s4,s5
    80003ff8:	000a0023          	sb	zero,0(s4)
    80003ffc:	bf9d                	j	80003f72 <namex+0xb8>
  if(nameiparent){
    80003ffe:	f20b03e3          	beqz	s6,80003f24 <namex+0x6a>
    iput(ip);
    80004002:	854e                	mv	a0,s3
    80004004:	00000097          	auipc	ra,0x0
    80004008:	adc080e7          	jalr	-1316(ra) # 80003ae0 <iput>
    return 0;
    8000400c:	4981                	li	s3,0
    8000400e:	bf19                	j	80003f24 <namex+0x6a>
  if(*path == 0)
    80004010:	d7fd                	beqz	a5,80003ffe <namex+0x144>
  while(*path != '/' && *path != 0)
    80004012:	0004c783          	lbu	a5,0(s1)
    80004016:	85a6                	mv	a1,s1
    80004018:	b7d1                	j	80003fdc <namex+0x122>

000000008000401a <dirlink>:
{
    8000401a:	7139                	addi	sp,sp,-64
    8000401c:	fc06                	sd	ra,56(sp)
    8000401e:	f822                	sd	s0,48(sp)
    80004020:	f426                	sd	s1,40(sp)
    80004022:	f04a                	sd	s2,32(sp)
    80004024:	ec4e                	sd	s3,24(sp)
    80004026:	e852                	sd	s4,16(sp)
    80004028:	0080                	addi	s0,sp,64
    8000402a:	892a                	mv	s2,a0
    8000402c:	8a2e                	mv	s4,a1
    8000402e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004030:	4601                	li	a2,0
    80004032:	00000097          	auipc	ra,0x0
    80004036:	dd8080e7          	jalr	-552(ra) # 80003e0a <dirlookup>
    8000403a:	e93d                	bnez	a0,800040b0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000403c:	04c92483          	lw	s1,76(s2)
    80004040:	c49d                	beqz	s1,8000406e <dirlink+0x54>
    80004042:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004044:	4741                	li	a4,16
    80004046:	86a6                	mv	a3,s1
    80004048:	fc040613          	addi	a2,s0,-64
    8000404c:	4581                	li	a1,0
    8000404e:	854a                	mv	a0,s2
    80004050:	00000097          	auipc	ra,0x0
    80004054:	b8a080e7          	jalr	-1142(ra) # 80003bda <readi>
    80004058:	47c1                	li	a5,16
    8000405a:	06f51163          	bne	a0,a5,800040bc <dirlink+0xa2>
    if(de.inum == 0)
    8000405e:	fc045783          	lhu	a5,-64(s0)
    80004062:	c791                	beqz	a5,8000406e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004064:	24c1                	addiw	s1,s1,16
    80004066:	04c92783          	lw	a5,76(s2)
    8000406a:	fcf4ede3          	bltu	s1,a5,80004044 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000406e:	4639                	li	a2,14
    80004070:	85d2                	mv	a1,s4
    80004072:	fc240513          	addi	a0,s0,-62
    80004076:	ffffd097          	auipc	ra,0xffffd
    8000407a:	d7e080e7          	jalr	-642(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000407e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004082:	4741                	li	a4,16
    80004084:	86a6                	mv	a3,s1
    80004086:	fc040613          	addi	a2,s0,-64
    8000408a:	4581                	li	a1,0
    8000408c:	854a                	mv	a0,s2
    8000408e:	00000097          	auipc	ra,0x0
    80004092:	c44080e7          	jalr	-956(ra) # 80003cd2 <writei>
    80004096:	872a                	mv	a4,a0
    80004098:	47c1                	li	a5,16
  return 0;
    8000409a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000409c:	02f71863          	bne	a4,a5,800040cc <dirlink+0xb2>
}
    800040a0:	70e2                	ld	ra,56(sp)
    800040a2:	7442                	ld	s0,48(sp)
    800040a4:	74a2                	ld	s1,40(sp)
    800040a6:	7902                	ld	s2,32(sp)
    800040a8:	69e2                	ld	s3,24(sp)
    800040aa:	6a42                	ld	s4,16(sp)
    800040ac:	6121                	addi	sp,sp,64
    800040ae:	8082                	ret
    iput(ip);
    800040b0:	00000097          	auipc	ra,0x0
    800040b4:	a30080e7          	jalr	-1488(ra) # 80003ae0 <iput>
    return -1;
    800040b8:	557d                	li	a0,-1
    800040ba:	b7dd                	j	800040a0 <dirlink+0x86>
      panic("dirlink read");
    800040bc:	00004517          	auipc	a0,0x4
    800040c0:	57c50513          	addi	a0,a0,1404 # 80008638 <syscalls+0x1d8>
    800040c4:	ffffc097          	auipc	ra,0xffffc
    800040c8:	47a080e7          	jalr	1146(ra) # 8000053e <panic>
    panic("dirlink");
    800040cc:	00004517          	auipc	a0,0x4
    800040d0:	67c50513          	addi	a0,a0,1660 # 80008748 <syscalls+0x2e8>
    800040d4:	ffffc097          	auipc	ra,0xffffc
    800040d8:	46a080e7          	jalr	1130(ra) # 8000053e <panic>

00000000800040dc <namei>:

struct inode*
namei(char *path)
{
    800040dc:	1101                	addi	sp,sp,-32
    800040de:	ec06                	sd	ra,24(sp)
    800040e0:	e822                	sd	s0,16(sp)
    800040e2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040e4:	fe040613          	addi	a2,s0,-32
    800040e8:	4581                	li	a1,0
    800040ea:	00000097          	auipc	ra,0x0
    800040ee:	dd0080e7          	jalr	-560(ra) # 80003eba <namex>
}
    800040f2:	60e2                	ld	ra,24(sp)
    800040f4:	6442                	ld	s0,16(sp)
    800040f6:	6105                	addi	sp,sp,32
    800040f8:	8082                	ret

00000000800040fa <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040fa:	1141                	addi	sp,sp,-16
    800040fc:	e406                	sd	ra,8(sp)
    800040fe:	e022                	sd	s0,0(sp)
    80004100:	0800                	addi	s0,sp,16
    80004102:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004104:	4585                	li	a1,1
    80004106:	00000097          	auipc	ra,0x0
    8000410a:	db4080e7          	jalr	-588(ra) # 80003eba <namex>
}
    8000410e:	60a2                	ld	ra,8(sp)
    80004110:	6402                	ld	s0,0(sp)
    80004112:	0141                	addi	sp,sp,16
    80004114:	8082                	ret

0000000080004116 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004116:	1101                	addi	sp,sp,-32
    80004118:	ec06                	sd	ra,24(sp)
    8000411a:	e822                	sd	s0,16(sp)
    8000411c:	e426                	sd	s1,8(sp)
    8000411e:	e04a                	sd	s2,0(sp)
    80004120:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004122:	0001d917          	auipc	s2,0x1d
    80004126:	34e90913          	addi	s2,s2,846 # 80021470 <log>
    8000412a:	01892583          	lw	a1,24(s2)
    8000412e:	02892503          	lw	a0,40(s2)
    80004132:	fffff097          	auipc	ra,0xfffff
    80004136:	ff2080e7          	jalr	-14(ra) # 80003124 <bread>
    8000413a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000413c:	02c92683          	lw	a3,44(s2)
    80004140:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004142:	02d05763          	blez	a3,80004170 <write_head+0x5a>
    80004146:	0001d797          	auipc	a5,0x1d
    8000414a:	35a78793          	addi	a5,a5,858 # 800214a0 <log+0x30>
    8000414e:	05c50713          	addi	a4,a0,92
    80004152:	36fd                	addiw	a3,a3,-1
    80004154:	1682                	slli	a3,a3,0x20
    80004156:	9281                	srli	a3,a3,0x20
    80004158:	068a                	slli	a3,a3,0x2
    8000415a:	0001d617          	auipc	a2,0x1d
    8000415e:	34a60613          	addi	a2,a2,842 # 800214a4 <log+0x34>
    80004162:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004164:	4390                	lw	a2,0(a5)
    80004166:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004168:	0791                	addi	a5,a5,4
    8000416a:	0711                	addi	a4,a4,4
    8000416c:	fed79ce3          	bne	a5,a3,80004164 <write_head+0x4e>
  }
  bwrite(buf);
    80004170:	8526                	mv	a0,s1
    80004172:	fffff097          	auipc	ra,0xfffff
    80004176:	0a4080e7          	jalr	164(ra) # 80003216 <bwrite>
  brelse(buf);
    8000417a:	8526                	mv	a0,s1
    8000417c:	fffff097          	auipc	ra,0xfffff
    80004180:	0d8080e7          	jalr	216(ra) # 80003254 <brelse>
}
    80004184:	60e2                	ld	ra,24(sp)
    80004186:	6442                	ld	s0,16(sp)
    80004188:	64a2                	ld	s1,8(sp)
    8000418a:	6902                	ld	s2,0(sp)
    8000418c:	6105                	addi	sp,sp,32
    8000418e:	8082                	ret

0000000080004190 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004190:	0001d797          	auipc	a5,0x1d
    80004194:	30c7a783          	lw	a5,780(a5) # 8002149c <log+0x2c>
    80004198:	0af05d63          	blez	a5,80004252 <install_trans+0xc2>
{
    8000419c:	7139                	addi	sp,sp,-64
    8000419e:	fc06                	sd	ra,56(sp)
    800041a0:	f822                	sd	s0,48(sp)
    800041a2:	f426                	sd	s1,40(sp)
    800041a4:	f04a                	sd	s2,32(sp)
    800041a6:	ec4e                	sd	s3,24(sp)
    800041a8:	e852                	sd	s4,16(sp)
    800041aa:	e456                	sd	s5,8(sp)
    800041ac:	e05a                	sd	s6,0(sp)
    800041ae:	0080                	addi	s0,sp,64
    800041b0:	8b2a                	mv	s6,a0
    800041b2:	0001da97          	auipc	s5,0x1d
    800041b6:	2eea8a93          	addi	s5,s5,750 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ba:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041bc:	0001d997          	auipc	s3,0x1d
    800041c0:	2b498993          	addi	s3,s3,692 # 80021470 <log>
    800041c4:	a035                	j	800041f0 <install_trans+0x60>
      bunpin(dbuf);
    800041c6:	8526                	mv	a0,s1
    800041c8:	fffff097          	auipc	ra,0xfffff
    800041cc:	166080e7          	jalr	358(ra) # 8000332e <bunpin>
    brelse(lbuf);
    800041d0:	854a                	mv	a0,s2
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	082080e7          	jalr	130(ra) # 80003254 <brelse>
    brelse(dbuf);
    800041da:	8526                	mv	a0,s1
    800041dc:	fffff097          	auipc	ra,0xfffff
    800041e0:	078080e7          	jalr	120(ra) # 80003254 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041e4:	2a05                	addiw	s4,s4,1
    800041e6:	0a91                	addi	s5,s5,4
    800041e8:	02c9a783          	lw	a5,44(s3)
    800041ec:	04fa5963          	bge	s4,a5,8000423e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041f0:	0189a583          	lw	a1,24(s3)
    800041f4:	014585bb          	addw	a1,a1,s4
    800041f8:	2585                	addiw	a1,a1,1
    800041fa:	0289a503          	lw	a0,40(s3)
    800041fe:	fffff097          	auipc	ra,0xfffff
    80004202:	f26080e7          	jalr	-218(ra) # 80003124 <bread>
    80004206:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004208:	000aa583          	lw	a1,0(s5)
    8000420c:	0289a503          	lw	a0,40(s3)
    80004210:	fffff097          	auipc	ra,0xfffff
    80004214:	f14080e7          	jalr	-236(ra) # 80003124 <bread>
    80004218:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000421a:	40000613          	li	a2,1024
    8000421e:	05890593          	addi	a1,s2,88
    80004222:	05850513          	addi	a0,a0,88
    80004226:	ffffd097          	auipc	ra,0xffffd
    8000422a:	b1a080e7          	jalr	-1254(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000422e:	8526                	mv	a0,s1
    80004230:	fffff097          	auipc	ra,0xfffff
    80004234:	fe6080e7          	jalr	-26(ra) # 80003216 <bwrite>
    if(recovering == 0)
    80004238:	f80b1ce3          	bnez	s6,800041d0 <install_trans+0x40>
    8000423c:	b769                	j	800041c6 <install_trans+0x36>
}
    8000423e:	70e2                	ld	ra,56(sp)
    80004240:	7442                	ld	s0,48(sp)
    80004242:	74a2                	ld	s1,40(sp)
    80004244:	7902                	ld	s2,32(sp)
    80004246:	69e2                	ld	s3,24(sp)
    80004248:	6a42                	ld	s4,16(sp)
    8000424a:	6aa2                	ld	s5,8(sp)
    8000424c:	6b02                	ld	s6,0(sp)
    8000424e:	6121                	addi	sp,sp,64
    80004250:	8082                	ret
    80004252:	8082                	ret

0000000080004254 <initlog>:
{
    80004254:	7179                	addi	sp,sp,-48
    80004256:	f406                	sd	ra,40(sp)
    80004258:	f022                	sd	s0,32(sp)
    8000425a:	ec26                	sd	s1,24(sp)
    8000425c:	e84a                	sd	s2,16(sp)
    8000425e:	e44e                	sd	s3,8(sp)
    80004260:	1800                	addi	s0,sp,48
    80004262:	892a                	mv	s2,a0
    80004264:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004266:	0001d497          	auipc	s1,0x1d
    8000426a:	20a48493          	addi	s1,s1,522 # 80021470 <log>
    8000426e:	00004597          	auipc	a1,0x4
    80004272:	3da58593          	addi	a1,a1,986 # 80008648 <syscalls+0x1e8>
    80004276:	8526                	mv	a0,s1
    80004278:	ffffd097          	auipc	ra,0xffffd
    8000427c:	8dc080e7          	jalr	-1828(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004280:	0149a583          	lw	a1,20(s3)
    80004284:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004286:	0109a783          	lw	a5,16(s3)
    8000428a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000428c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004290:	854a                	mv	a0,s2
    80004292:	fffff097          	auipc	ra,0xfffff
    80004296:	e92080e7          	jalr	-366(ra) # 80003124 <bread>
  log.lh.n = lh->n;
    8000429a:	4d3c                	lw	a5,88(a0)
    8000429c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000429e:	02f05563          	blez	a5,800042c8 <initlog+0x74>
    800042a2:	05c50713          	addi	a4,a0,92
    800042a6:	0001d697          	auipc	a3,0x1d
    800042aa:	1fa68693          	addi	a3,a3,506 # 800214a0 <log+0x30>
    800042ae:	37fd                	addiw	a5,a5,-1
    800042b0:	1782                	slli	a5,a5,0x20
    800042b2:	9381                	srli	a5,a5,0x20
    800042b4:	078a                	slli	a5,a5,0x2
    800042b6:	06050613          	addi	a2,a0,96
    800042ba:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800042bc:	4310                	lw	a2,0(a4)
    800042be:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800042c0:	0711                	addi	a4,a4,4
    800042c2:	0691                	addi	a3,a3,4
    800042c4:	fef71ce3          	bne	a4,a5,800042bc <initlog+0x68>
  brelse(buf);
    800042c8:	fffff097          	auipc	ra,0xfffff
    800042cc:	f8c080e7          	jalr	-116(ra) # 80003254 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042d0:	4505                	li	a0,1
    800042d2:	00000097          	auipc	ra,0x0
    800042d6:	ebe080e7          	jalr	-322(ra) # 80004190 <install_trans>
  log.lh.n = 0;
    800042da:	0001d797          	auipc	a5,0x1d
    800042de:	1c07a123          	sw	zero,450(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    800042e2:	00000097          	auipc	ra,0x0
    800042e6:	e34080e7          	jalr	-460(ra) # 80004116 <write_head>
}
    800042ea:	70a2                	ld	ra,40(sp)
    800042ec:	7402                	ld	s0,32(sp)
    800042ee:	64e2                	ld	s1,24(sp)
    800042f0:	6942                	ld	s2,16(sp)
    800042f2:	69a2                	ld	s3,8(sp)
    800042f4:	6145                	addi	sp,sp,48
    800042f6:	8082                	ret

00000000800042f8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042f8:	1101                	addi	sp,sp,-32
    800042fa:	ec06                	sd	ra,24(sp)
    800042fc:	e822                	sd	s0,16(sp)
    800042fe:	e426                	sd	s1,8(sp)
    80004300:	e04a                	sd	s2,0(sp)
    80004302:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004304:	0001d517          	auipc	a0,0x1d
    80004308:	16c50513          	addi	a0,a0,364 # 80021470 <log>
    8000430c:	ffffd097          	auipc	ra,0xffffd
    80004310:	8d8080e7          	jalr	-1832(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004314:	0001d497          	auipc	s1,0x1d
    80004318:	15c48493          	addi	s1,s1,348 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000431c:	4979                	li	s2,30
    8000431e:	a039                	j	8000432c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004320:	85a6                	mv	a1,s1
    80004322:	8526                	mv	a0,s1
    80004324:	ffffe097          	auipc	ra,0xffffe
    80004328:	fb4080e7          	jalr	-76(ra) # 800022d8 <sleep>
    if(log.committing){
    8000432c:	50dc                	lw	a5,36(s1)
    8000432e:	fbed                	bnez	a5,80004320 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004330:	509c                	lw	a5,32(s1)
    80004332:	0017871b          	addiw	a4,a5,1
    80004336:	0007069b          	sext.w	a3,a4
    8000433a:	0027179b          	slliw	a5,a4,0x2
    8000433e:	9fb9                	addw	a5,a5,a4
    80004340:	0017979b          	slliw	a5,a5,0x1
    80004344:	54d8                	lw	a4,44(s1)
    80004346:	9fb9                	addw	a5,a5,a4
    80004348:	00f95963          	bge	s2,a5,8000435a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000434c:	85a6                	mv	a1,s1
    8000434e:	8526                	mv	a0,s1
    80004350:	ffffe097          	auipc	ra,0xffffe
    80004354:	f88080e7          	jalr	-120(ra) # 800022d8 <sleep>
    80004358:	bfd1                	j	8000432c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000435a:	0001d517          	auipc	a0,0x1d
    8000435e:	11650513          	addi	a0,a0,278 # 80021470 <log>
    80004362:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004364:	ffffd097          	auipc	ra,0xffffd
    80004368:	934080e7          	jalr	-1740(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000436c:	60e2                	ld	ra,24(sp)
    8000436e:	6442                	ld	s0,16(sp)
    80004370:	64a2                	ld	s1,8(sp)
    80004372:	6902                	ld	s2,0(sp)
    80004374:	6105                	addi	sp,sp,32
    80004376:	8082                	ret

0000000080004378 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004378:	7139                	addi	sp,sp,-64
    8000437a:	fc06                	sd	ra,56(sp)
    8000437c:	f822                	sd	s0,48(sp)
    8000437e:	f426                	sd	s1,40(sp)
    80004380:	f04a                	sd	s2,32(sp)
    80004382:	ec4e                	sd	s3,24(sp)
    80004384:	e852                	sd	s4,16(sp)
    80004386:	e456                	sd	s5,8(sp)
    80004388:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000438a:	0001d497          	auipc	s1,0x1d
    8000438e:	0e648493          	addi	s1,s1,230 # 80021470 <log>
    80004392:	8526                	mv	a0,s1
    80004394:	ffffd097          	auipc	ra,0xffffd
    80004398:	850080e7          	jalr	-1968(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000439c:	509c                	lw	a5,32(s1)
    8000439e:	37fd                	addiw	a5,a5,-1
    800043a0:	0007891b          	sext.w	s2,a5
    800043a4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043a6:	50dc                	lw	a5,36(s1)
    800043a8:	efb9                	bnez	a5,80004406 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043aa:	06091663          	bnez	s2,80004416 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043ae:	0001d497          	auipc	s1,0x1d
    800043b2:	0c248493          	addi	s1,s1,194 # 80021470 <log>
    800043b6:	4785                	li	a5,1
    800043b8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043ba:	8526                	mv	a0,s1
    800043bc:	ffffd097          	auipc	ra,0xffffd
    800043c0:	8dc080e7          	jalr	-1828(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043c4:	54dc                	lw	a5,44(s1)
    800043c6:	06f04763          	bgtz	a5,80004434 <end_op+0xbc>
    acquire(&log.lock);
    800043ca:	0001d497          	auipc	s1,0x1d
    800043ce:	0a648493          	addi	s1,s1,166 # 80021470 <log>
    800043d2:	8526                	mv	a0,s1
    800043d4:	ffffd097          	auipc	ra,0xffffd
    800043d8:	810080e7          	jalr	-2032(ra) # 80000be4 <acquire>
    log.committing = 0;
    800043dc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043e0:	8526                	mv	a0,s1
    800043e2:	ffffe097          	auipc	ra,0xffffe
    800043e6:	082080e7          	jalr	130(ra) # 80002464 <wakeup>
    release(&log.lock);
    800043ea:	8526                	mv	a0,s1
    800043ec:	ffffd097          	auipc	ra,0xffffd
    800043f0:	8ac080e7          	jalr	-1876(ra) # 80000c98 <release>
}
    800043f4:	70e2                	ld	ra,56(sp)
    800043f6:	7442                	ld	s0,48(sp)
    800043f8:	74a2                	ld	s1,40(sp)
    800043fa:	7902                	ld	s2,32(sp)
    800043fc:	69e2                	ld	s3,24(sp)
    800043fe:	6a42                	ld	s4,16(sp)
    80004400:	6aa2                	ld	s5,8(sp)
    80004402:	6121                	addi	sp,sp,64
    80004404:	8082                	ret
    panic("log.committing");
    80004406:	00004517          	auipc	a0,0x4
    8000440a:	24a50513          	addi	a0,a0,586 # 80008650 <syscalls+0x1f0>
    8000440e:	ffffc097          	auipc	ra,0xffffc
    80004412:	130080e7          	jalr	304(ra) # 8000053e <panic>
    wakeup(&log);
    80004416:	0001d497          	auipc	s1,0x1d
    8000441a:	05a48493          	addi	s1,s1,90 # 80021470 <log>
    8000441e:	8526                	mv	a0,s1
    80004420:	ffffe097          	auipc	ra,0xffffe
    80004424:	044080e7          	jalr	68(ra) # 80002464 <wakeup>
  release(&log.lock);
    80004428:	8526                	mv	a0,s1
    8000442a:	ffffd097          	auipc	ra,0xffffd
    8000442e:	86e080e7          	jalr	-1938(ra) # 80000c98 <release>
  if(do_commit){
    80004432:	b7c9                	j	800043f4 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004434:	0001da97          	auipc	s5,0x1d
    80004438:	06ca8a93          	addi	s5,s5,108 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000443c:	0001da17          	auipc	s4,0x1d
    80004440:	034a0a13          	addi	s4,s4,52 # 80021470 <log>
    80004444:	018a2583          	lw	a1,24(s4)
    80004448:	012585bb          	addw	a1,a1,s2
    8000444c:	2585                	addiw	a1,a1,1
    8000444e:	028a2503          	lw	a0,40(s4)
    80004452:	fffff097          	auipc	ra,0xfffff
    80004456:	cd2080e7          	jalr	-814(ra) # 80003124 <bread>
    8000445a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000445c:	000aa583          	lw	a1,0(s5)
    80004460:	028a2503          	lw	a0,40(s4)
    80004464:	fffff097          	auipc	ra,0xfffff
    80004468:	cc0080e7          	jalr	-832(ra) # 80003124 <bread>
    8000446c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000446e:	40000613          	li	a2,1024
    80004472:	05850593          	addi	a1,a0,88
    80004476:	05848513          	addi	a0,s1,88
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	8c6080e7          	jalr	-1850(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004482:	8526                	mv	a0,s1
    80004484:	fffff097          	auipc	ra,0xfffff
    80004488:	d92080e7          	jalr	-622(ra) # 80003216 <bwrite>
    brelse(from);
    8000448c:	854e                	mv	a0,s3
    8000448e:	fffff097          	auipc	ra,0xfffff
    80004492:	dc6080e7          	jalr	-570(ra) # 80003254 <brelse>
    brelse(to);
    80004496:	8526                	mv	a0,s1
    80004498:	fffff097          	auipc	ra,0xfffff
    8000449c:	dbc080e7          	jalr	-580(ra) # 80003254 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044a0:	2905                	addiw	s2,s2,1
    800044a2:	0a91                	addi	s5,s5,4
    800044a4:	02ca2783          	lw	a5,44(s4)
    800044a8:	f8f94ee3          	blt	s2,a5,80004444 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044ac:	00000097          	auipc	ra,0x0
    800044b0:	c6a080e7          	jalr	-918(ra) # 80004116 <write_head>
    install_trans(0); // Now install writes to home locations
    800044b4:	4501                	li	a0,0
    800044b6:	00000097          	auipc	ra,0x0
    800044ba:	cda080e7          	jalr	-806(ra) # 80004190 <install_trans>
    log.lh.n = 0;
    800044be:	0001d797          	auipc	a5,0x1d
    800044c2:	fc07af23          	sw	zero,-34(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044c6:	00000097          	auipc	ra,0x0
    800044ca:	c50080e7          	jalr	-944(ra) # 80004116 <write_head>
    800044ce:	bdf5                	j	800043ca <end_op+0x52>

00000000800044d0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044d0:	1101                	addi	sp,sp,-32
    800044d2:	ec06                	sd	ra,24(sp)
    800044d4:	e822                	sd	s0,16(sp)
    800044d6:	e426                	sd	s1,8(sp)
    800044d8:	e04a                	sd	s2,0(sp)
    800044da:	1000                	addi	s0,sp,32
    800044dc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800044de:	0001d917          	auipc	s2,0x1d
    800044e2:	f9290913          	addi	s2,s2,-110 # 80021470 <log>
    800044e6:	854a                	mv	a0,s2
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	6fc080e7          	jalr	1788(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044f0:	02c92603          	lw	a2,44(s2)
    800044f4:	47f5                	li	a5,29
    800044f6:	06c7c563          	blt	a5,a2,80004560 <log_write+0x90>
    800044fa:	0001d797          	auipc	a5,0x1d
    800044fe:	f927a783          	lw	a5,-110(a5) # 8002148c <log+0x1c>
    80004502:	37fd                	addiw	a5,a5,-1
    80004504:	04f65e63          	bge	a2,a5,80004560 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004508:	0001d797          	auipc	a5,0x1d
    8000450c:	f887a783          	lw	a5,-120(a5) # 80021490 <log+0x20>
    80004510:	06f05063          	blez	a5,80004570 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004514:	4781                	li	a5,0
    80004516:	06c05563          	blez	a2,80004580 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000451a:	44cc                	lw	a1,12(s1)
    8000451c:	0001d717          	auipc	a4,0x1d
    80004520:	f8470713          	addi	a4,a4,-124 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004524:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004526:	4314                	lw	a3,0(a4)
    80004528:	04b68c63          	beq	a3,a1,80004580 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000452c:	2785                	addiw	a5,a5,1
    8000452e:	0711                	addi	a4,a4,4
    80004530:	fef61be3          	bne	a2,a5,80004526 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004534:	0621                	addi	a2,a2,8
    80004536:	060a                	slli	a2,a2,0x2
    80004538:	0001d797          	auipc	a5,0x1d
    8000453c:	f3878793          	addi	a5,a5,-200 # 80021470 <log>
    80004540:	963e                	add	a2,a2,a5
    80004542:	44dc                	lw	a5,12(s1)
    80004544:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004546:	8526                	mv	a0,s1
    80004548:	fffff097          	auipc	ra,0xfffff
    8000454c:	daa080e7          	jalr	-598(ra) # 800032f2 <bpin>
    log.lh.n++;
    80004550:	0001d717          	auipc	a4,0x1d
    80004554:	f2070713          	addi	a4,a4,-224 # 80021470 <log>
    80004558:	575c                	lw	a5,44(a4)
    8000455a:	2785                	addiw	a5,a5,1
    8000455c:	d75c                	sw	a5,44(a4)
    8000455e:	a835                	j	8000459a <log_write+0xca>
    panic("too big a transaction");
    80004560:	00004517          	auipc	a0,0x4
    80004564:	10050513          	addi	a0,a0,256 # 80008660 <syscalls+0x200>
    80004568:	ffffc097          	auipc	ra,0xffffc
    8000456c:	fd6080e7          	jalr	-42(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004570:	00004517          	auipc	a0,0x4
    80004574:	10850513          	addi	a0,a0,264 # 80008678 <syscalls+0x218>
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	fc6080e7          	jalr	-58(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004580:	00878713          	addi	a4,a5,8
    80004584:	00271693          	slli	a3,a4,0x2
    80004588:	0001d717          	auipc	a4,0x1d
    8000458c:	ee870713          	addi	a4,a4,-280 # 80021470 <log>
    80004590:	9736                	add	a4,a4,a3
    80004592:	44d4                	lw	a3,12(s1)
    80004594:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004596:	faf608e3          	beq	a2,a5,80004546 <log_write+0x76>
  }
  release(&log.lock);
    8000459a:	0001d517          	auipc	a0,0x1d
    8000459e:	ed650513          	addi	a0,a0,-298 # 80021470 <log>
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	6f6080e7          	jalr	1782(ra) # 80000c98 <release>
}
    800045aa:	60e2                	ld	ra,24(sp)
    800045ac:	6442                	ld	s0,16(sp)
    800045ae:	64a2                	ld	s1,8(sp)
    800045b0:	6902                	ld	s2,0(sp)
    800045b2:	6105                	addi	sp,sp,32
    800045b4:	8082                	ret

00000000800045b6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045b6:	1101                	addi	sp,sp,-32
    800045b8:	ec06                	sd	ra,24(sp)
    800045ba:	e822                	sd	s0,16(sp)
    800045bc:	e426                	sd	s1,8(sp)
    800045be:	e04a                	sd	s2,0(sp)
    800045c0:	1000                	addi	s0,sp,32
    800045c2:	84aa                	mv	s1,a0
    800045c4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045c6:	00004597          	auipc	a1,0x4
    800045ca:	0d258593          	addi	a1,a1,210 # 80008698 <syscalls+0x238>
    800045ce:	0521                	addi	a0,a0,8
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	584080e7          	jalr	1412(ra) # 80000b54 <initlock>
  lk->name = name;
    800045d8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045dc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045e0:	0204a423          	sw	zero,40(s1)
}
    800045e4:	60e2                	ld	ra,24(sp)
    800045e6:	6442                	ld	s0,16(sp)
    800045e8:	64a2                	ld	s1,8(sp)
    800045ea:	6902                	ld	s2,0(sp)
    800045ec:	6105                	addi	sp,sp,32
    800045ee:	8082                	ret

00000000800045f0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045f0:	1101                	addi	sp,sp,-32
    800045f2:	ec06                	sd	ra,24(sp)
    800045f4:	e822                	sd	s0,16(sp)
    800045f6:	e426                	sd	s1,8(sp)
    800045f8:	e04a                	sd	s2,0(sp)
    800045fa:	1000                	addi	s0,sp,32
    800045fc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045fe:	00850913          	addi	s2,a0,8
    80004602:	854a                	mv	a0,s2
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	5e0080e7          	jalr	1504(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000460c:	409c                	lw	a5,0(s1)
    8000460e:	cb89                	beqz	a5,80004620 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004610:	85ca                	mv	a1,s2
    80004612:	8526                	mv	a0,s1
    80004614:	ffffe097          	auipc	ra,0xffffe
    80004618:	cc4080e7          	jalr	-828(ra) # 800022d8 <sleep>
  while (lk->locked) {
    8000461c:	409c                	lw	a5,0(s1)
    8000461e:	fbed                	bnez	a5,80004610 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004620:	4785                	li	a5,1
    80004622:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004624:	ffffd097          	auipc	ra,0xffffd
    80004628:	3a0080e7          	jalr	928(ra) # 800019c4 <myproc>
    8000462c:	591c                	lw	a5,48(a0)
    8000462e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004630:	854a                	mv	a0,s2
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	666080e7          	jalr	1638(ra) # 80000c98 <release>
}
    8000463a:	60e2                	ld	ra,24(sp)
    8000463c:	6442                	ld	s0,16(sp)
    8000463e:	64a2                	ld	s1,8(sp)
    80004640:	6902                	ld	s2,0(sp)
    80004642:	6105                	addi	sp,sp,32
    80004644:	8082                	ret

0000000080004646 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004646:	1101                	addi	sp,sp,-32
    80004648:	ec06                	sd	ra,24(sp)
    8000464a:	e822                	sd	s0,16(sp)
    8000464c:	e426                	sd	s1,8(sp)
    8000464e:	e04a                	sd	s2,0(sp)
    80004650:	1000                	addi	s0,sp,32
    80004652:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004654:	00850913          	addi	s2,a0,8
    80004658:	854a                	mv	a0,s2
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	58a080e7          	jalr	1418(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004662:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004666:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000466a:	8526                	mv	a0,s1
    8000466c:	ffffe097          	auipc	ra,0xffffe
    80004670:	df8080e7          	jalr	-520(ra) # 80002464 <wakeup>
  release(&lk->lk);
    80004674:	854a                	mv	a0,s2
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	622080e7          	jalr	1570(ra) # 80000c98 <release>
}
    8000467e:	60e2                	ld	ra,24(sp)
    80004680:	6442                	ld	s0,16(sp)
    80004682:	64a2                	ld	s1,8(sp)
    80004684:	6902                	ld	s2,0(sp)
    80004686:	6105                	addi	sp,sp,32
    80004688:	8082                	ret

000000008000468a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000468a:	7179                	addi	sp,sp,-48
    8000468c:	f406                	sd	ra,40(sp)
    8000468e:	f022                	sd	s0,32(sp)
    80004690:	ec26                	sd	s1,24(sp)
    80004692:	e84a                	sd	s2,16(sp)
    80004694:	e44e                	sd	s3,8(sp)
    80004696:	1800                	addi	s0,sp,48
    80004698:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000469a:	00850913          	addi	s2,a0,8
    8000469e:	854a                	mv	a0,s2
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	544080e7          	jalr	1348(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046a8:	409c                	lw	a5,0(s1)
    800046aa:	ef99                	bnez	a5,800046c8 <holdingsleep+0x3e>
    800046ac:	4481                	li	s1,0
  release(&lk->lk);
    800046ae:	854a                	mv	a0,s2
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	5e8080e7          	jalr	1512(ra) # 80000c98 <release>
  return r;
}
    800046b8:	8526                	mv	a0,s1
    800046ba:	70a2                	ld	ra,40(sp)
    800046bc:	7402                	ld	s0,32(sp)
    800046be:	64e2                	ld	s1,24(sp)
    800046c0:	6942                	ld	s2,16(sp)
    800046c2:	69a2                	ld	s3,8(sp)
    800046c4:	6145                	addi	sp,sp,48
    800046c6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046c8:	0284a983          	lw	s3,40(s1)
    800046cc:	ffffd097          	auipc	ra,0xffffd
    800046d0:	2f8080e7          	jalr	760(ra) # 800019c4 <myproc>
    800046d4:	5904                	lw	s1,48(a0)
    800046d6:	413484b3          	sub	s1,s1,s3
    800046da:	0014b493          	seqz	s1,s1
    800046de:	bfc1                	j	800046ae <holdingsleep+0x24>

00000000800046e0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046e0:	1141                	addi	sp,sp,-16
    800046e2:	e406                	sd	ra,8(sp)
    800046e4:	e022                	sd	s0,0(sp)
    800046e6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046e8:	00004597          	auipc	a1,0x4
    800046ec:	fc058593          	addi	a1,a1,-64 # 800086a8 <syscalls+0x248>
    800046f0:	0001d517          	auipc	a0,0x1d
    800046f4:	ec850513          	addi	a0,a0,-312 # 800215b8 <ftable>
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	45c080e7          	jalr	1116(ra) # 80000b54 <initlock>
}
    80004700:	60a2                	ld	ra,8(sp)
    80004702:	6402                	ld	s0,0(sp)
    80004704:	0141                	addi	sp,sp,16
    80004706:	8082                	ret

0000000080004708 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004708:	1101                	addi	sp,sp,-32
    8000470a:	ec06                	sd	ra,24(sp)
    8000470c:	e822                	sd	s0,16(sp)
    8000470e:	e426                	sd	s1,8(sp)
    80004710:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004712:	0001d517          	auipc	a0,0x1d
    80004716:	ea650513          	addi	a0,a0,-346 # 800215b8 <ftable>
    8000471a:	ffffc097          	auipc	ra,0xffffc
    8000471e:	4ca080e7          	jalr	1226(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004722:	0001d497          	auipc	s1,0x1d
    80004726:	eae48493          	addi	s1,s1,-338 # 800215d0 <ftable+0x18>
    8000472a:	0001e717          	auipc	a4,0x1e
    8000472e:	e4670713          	addi	a4,a4,-442 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    80004732:	40dc                	lw	a5,4(s1)
    80004734:	cf99                	beqz	a5,80004752 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004736:	02848493          	addi	s1,s1,40
    8000473a:	fee49ce3          	bne	s1,a4,80004732 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000473e:	0001d517          	auipc	a0,0x1d
    80004742:	e7a50513          	addi	a0,a0,-390 # 800215b8 <ftable>
    80004746:	ffffc097          	auipc	ra,0xffffc
    8000474a:	552080e7          	jalr	1362(ra) # 80000c98 <release>
  return 0;
    8000474e:	4481                	li	s1,0
    80004750:	a819                	j	80004766 <filealloc+0x5e>
      f->ref = 1;
    80004752:	4785                	li	a5,1
    80004754:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004756:	0001d517          	auipc	a0,0x1d
    8000475a:	e6250513          	addi	a0,a0,-414 # 800215b8 <ftable>
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	53a080e7          	jalr	1338(ra) # 80000c98 <release>
}
    80004766:	8526                	mv	a0,s1
    80004768:	60e2                	ld	ra,24(sp)
    8000476a:	6442                	ld	s0,16(sp)
    8000476c:	64a2                	ld	s1,8(sp)
    8000476e:	6105                	addi	sp,sp,32
    80004770:	8082                	ret

0000000080004772 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004772:	1101                	addi	sp,sp,-32
    80004774:	ec06                	sd	ra,24(sp)
    80004776:	e822                	sd	s0,16(sp)
    80004778:	e426                	sd	s1,8(sp)
    8000477a:	1000                	addi	s0,sp,32
    8000477c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000477e:	0001d517          	auipc	a0,0x1d
    80004782:	e3a50513          	addi	a0,a0,-454 # 800215b8 <ftable>
    80004786:	ffffc097          	auipc	ra,0xffffc
    8000478a:	45e080e7          	jalr	1118(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000478e:	40dc                	lw	a5,4(s1)
    80004790:	02f05263          	blez	a5,800047b4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004794:	2785                	addiw	a5,a5,1
    80004796:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004798:	0001d517          	auipc	a0,0x1d
    8000479c:	e2050513          	addi	a0,a0,-480 # 800215b8 <ftable>
    800047a0:	ffffc097          	auipc	ra,0xffffc
    800047a4:	4f8080e7          	jalr	1272(ra) # 80000c98 <release>
  return f;
}
    800047a8:	8526                	mv	a0,s1
    800047aa:	60e2                	ld	ra,24(sp)
    800047ac:	6442                	ld	s0,16(sp)
    800047ae:	64a2                	ld	s1,8(sp)
    800047b0:	6105                	addi	sp,sp,32
    800047b2:	8082                	ret
    panic("filedup");
    800047b4:	00004517          	auipc	a0,0x4
    800047b8:	efc50513          	addi	a0,a0,-260 # 800086b0 <syscalls+0x250>
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	d82080e7          	jalr	-638(ra) # 8000053e <panic>

00000000800047c4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047c4:	7139                	addi	sp,sp,-64
    800047c6:	fc06                	sd	ra,56(sp)
    800047c8:	f822                	sd	s0,48(sp)
    800047ca:	f426                	sd	s1,40(sp)
    800047cc:	f04a                	sd	s2,32(sp)
    800047ce:	ec4e                	sd	s3,24(sp)
    800047d0:	e852                	sd	s4,16(sp)
    800047d2:	e456                	sd	s5,8(sp)
    800047d4:	0080                	addi	s0,sp,64
    800047d6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047d8:	0001d517          	auipc	a0,0x1d
    800047dc:	de050513          	addi	a0,a0,-544 # 800215b8 <ftable>
    800047e0:	ffffc097          	auipc	ra,0xffffc
    800047e4:	404080e7          	jalr	1028(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800047e8:	40dc                	lw	a5,4(s1)
    800047ea:	06f05163          	blez	a5,8000484c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047ee:	37fd                	addiw	a5,a5,-1
    800047f0:	0007871b          	sext.w	a4,a5
    800047f4:	c0dc                	sw	a5,4(s1)
    800047f6:	06e04363          	bgtz	a4,8000485c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047fa:	0004a903          	lw	s2,0(s1)
    800047fe:	0094ca83          	lbu	s5,9(s1)
    80004802:	0104ba03          	ld	s4,16(s1)
    80004806:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000480a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000480e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004812:	0001d517          	auipc	a0,0x1d
    80004816:	da650513          	addi	a0,a0,-602 # 800215b8 <ftable>
    8000481a:	ffffc097          	auipc	ra,0xffffc
    8000481e:	47e080e7          	jalr	1150(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004822:	4785                	li	a5,1
    80004824:	04f90d63          	beq	s2,a5,8000487e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004828:	3979                	addiw	s2,s2,-2
    8000482a:	4785                	li	a5,1
    8000482c:	0527e063          	bltu	a5,s2,8000486c <fileclose+0xa8>
    begin_op();
    80004830:	00000097          	auipc	ra,0x0
    80004834:	ac8080e7          	jalr	-1336(ra) # 800042f8 <begin_op>
    iput(ff.ip);
    80004838:	854e                	mv	a0,s3
    8000483a:	fffff097          	auipc	ra,0xfffff
    8000483e:	2a6080e7          	jalr	678(ra) # 80003ae0 <iput>
    end_op();
    80004842:	00000097          	auipc	ra,0x0
    80004846:	b36080e7          	jalr	-1226(ra) # 80004378 <end_op>
    8000484a:	a00d                	j	8000486c <fileclose+0xa8>
    panic("fileclose");
    8000484c:	00004517          	auipc	a0,0x4
    80004850:	e6c50513          	addi	a0,a0,-404 # 800086b8 <syscalls+0x258>
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	cea080e7          	jalr	-790(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000485c:	0001d517          	auipc	a0,0x1d
    80004860:	d5c50513          	addi	a0,a0,-676 # 800215b8 <ftable>
    80004864:	ffffc097          	auipc	ra,0xffffc
    80004868:	434080e7          	jalr	1076(ra) # 80000c98 <release>
  }
}
    8000486c:	70e2                	ld	ra,56(sp)
    8000486e:	7442                	ld	s0,48(sp)
    80004870:	74a2                	ld	s1,40(sp)
    80004872:	7902                	ld	s2,32(sp)
    80004874:	69e2                	ld	s3,24(sp)
    80004876:	6a42                	ld	s4,16(sp)
    80004878:	6aa2                	ld	s5,8(sp)
    8000487a:	6121                	addi	sp,sp,64
    8000487c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000487e:	85d6                	mv	a1,s5
    80004880:	8552                	mv	a0,s4
    80004882:	00000097          	auipc	ra,0x0
    80004886:	34c080e7          	jalr	844(ra) # 80004bce <pipeclose>
    8000488a:	b7cd                	j	8000486c <fileclose+0xa8>

000000008000488c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000488c:	715d                	addi	sp,sp,-80
    8000488e:	e486                	sd	ra,72(sp)
    80004890:	e0a2                	sd	s0,64(sp)
    80004892:	fc26                	sd	s1,56(sp)
    80004894:	f84a                	sd	s2,48(sp)
    80004896:	f44e                	sd	s3,40(sp)
    80004898:	0880                	addi	s0,sp,80
    8000489a:	84aa                	mv	s1,a0
    8000489c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000489e:	ffffd097          	auipc	ra,0xffffd
    800048a2:	126080e7          	jalr	294(ra) # 800019c4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048a6:	409c                	lw	a5,0(s1)
    800048a8:	37f9                	addiw	a5,a5,-2
    800048aa:	4705                	li	a4,1
    800048ac:	04f76763          	bltu	a4,a5,800048fa <filestat+0x6e>
    800048b0:	892a                	mv	s2,a0
    ilock(f->ip);
    800048b2:	6c88                	ld	a0,24(s1)
    800048b4:	fffff097          	auipc	ra,0xfffff
    800048b8:	072080e7          	jalr	114(ra) # 80003926 <ilock>
    stati(f->ip, &st);
    800048bc:	fb840593          	addi	a1,s0,-72
    800048c0:	6c88                	ld	a0,24(s1)
    800048c2:	fffff097          	auipc	ra,0xfffff
    800048c6:	2ee080e7          	jalr	750(ra) # 80003bb0 <stati>
    iunlock(f->ip);
    800048ca:	6c88                	ld	a0,24(s1)
    800048cc:	fffff097          	auipc	ra,0xfffff
    800048d0:	11c080e7          	jalr	284(ra) # 800039e8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048d4:	46e1                	li	a3,24
    800048d6:	fb840613          	addi	a2,s0,-72
    800048da:	85ce                	mv	a1,s3
    800048dc:	05893503          	ld	a0,88(s2)
    800048e0:	ffffd097          	auipc	ra,0xffffd
    800048e4:	d9a080e7          	jalr	-614(ra) # 8000167a <copyout>
    800048e8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048ec:	60a6                	ld	ra,72(sp)
    800048ee:	6406                	ld	s0,64(sp)
    800048f0:	74e2                	ld	s1,56(sp)
    800048f2:	7942                	ld	s2,48(sp)
    800048f4:	79a2                	ld	s3,40(sp)
    800048f6:	6161                	addi	sp,sp,80
    800048f8:	8082                	ret
  return -1;
    800048fa:	557d                	li	a0,-1
    800048fc:	bfc5                	j	800048ec <filestat+0x60>

00000000800048fe <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048fe:	7179                	addi	sp,sp,-48
    80004900:	f406                	sd	ra,40(sp)
    80004902:	f022                	sd	s0,32(sp)
    80004904:	ec26                	sd	s1,24(sp)
    80004906:	e84a                	sd	s2,16(sp)
    80004908:	e44e                	sd	s3,8(sp)
    8000490a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000490c:	00854783          	lbu	a5,8(a0)
    80004910:	c3d5                	beqz	a5,800049b4 <fileread+0xb6>
    80004912:	84aa                	mv	s1,a0
    80004914:	89ae                	mv	s3,a1
    80004916:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004918:	411c                	lw	a5,0(a0)
    8000491a:	4705                	li	a4,1
    8000491c:	04e78963          	beq	a5,a4,8000496e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004920:	470d                	li	a4,3
    80004922:	04e78d63          	beq	a5,a4,8000497c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004926:	4709                	li	a4,2
    80004928:	06e79e63          	bne	a5,a4,800049a4 <fileread+0xa6>
    ilock(f->ip);
    8000492c:	6d08                	ld	a0,24(a0)
    8000492e:	fffff097          	auipc	ra,0xfffff
    80004932:	ff8080e7          	jalr	-8(ra) # 80003926 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004936:	874a                	mv	a4,s2
    80004938:	5094                	lw	a3,32(s1)
    8000493a:	864e                	mv	a2,s3
    8000493c:	4585                	li	a1,1
    8000493e:	6c88                	ld	a0,24(s1)
    80004940:	fffff097          	auipc	ra,0xfffff
    80004944:	29a080e7          	jalr	666(ra) # 80003bda <readi>
    80004948:	892a                	mv	s2,a0
    8000494a:	00a05563          	blez	a0,80004954 <fileread+0x56>
      f->off += r;
    8000494e:	509c                	lw	a5,32(s1)
    80004950:	9fa9                	addw	a5,a5,a0
    80004952:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004954:	6c88                	ld	a0,24(s1)
    80004956:	fffff097          	auipc	ra,0xfffff
    8000495a:	092080e7          	jalr	146(ra) # 800039e8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000495e:	854a                	mv	a0,s2
    80004960:	70a2                	ld	ra,40(sp)
    80004962:	7402                	ld	s0,32(sp)
    80004964:	64e2                	ld	s1,24(sp)
    80004966:	6942                	ld	s2,16(sp)
    80004968:	69a2                	ld	s3,8(sp)
    8000496a:	6145                	addi	sp,sp,48
    8000496c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000496e:	6908                	ld	a0,16(a0)
    80004970:	00000097          	auipc	ra,0x0
    80004974:	3c8080e7          	jalr	968(ra) # 80004d38 <piperead>
    80004978:	892a                	mv	s2,a0
    8000497a:	b7d5                	j	8000495e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000497c:	02451783          	lh	a5,36(a0)
    80004980:	03079693          	slli	a3,a5,0x30
    80004984:	92c1                	srli	a3,a3,0x30
    80004986:	4725                	li	a4,9
    80004988:	02d76863          	bltu	a4,a3,800049b8 <fileread+0xba>
    8000498c:	0792                	slli	a5,a5,0x4
    8000498e:	0001d717          	auipc	a4,0x1d
    80004992:	b8a70713          	addi	a4,a4,-1142 # 80021518 <devsw>
    80004996:	97ba                	add	a5,a5,a4
    80004998:	639c                	ld	a5,0(a5)
    8000499a:	c38d                	beqz	a5,800049bc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000499c:	4505                	li	a0,1
    8000499e:	9782                	jalr	a5
    800049a0:	892a                	mv	s2,a0
    800049a2:	bf75                	j	8000495e <fileread+0x60>
    panic("fileread");
    800049a4:	00004517          	auipc	a0,0x4
    800049a8:	d2450513          	addi	a0,a0,-732 # 800086c8 <syscalls+0x268>
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	b92080e7          	jalr	-1134(ra) # 8000053e <panic>
    return -1;
    800049b4:	597d                	li	s2,-1
    800049b6:	b765                	j	8000495e <fileread+0x60>
      return -1;
    800049b8:	597d                	li	s2,-1
    800049ba:	b755                	j	8000495e <fileread+0x60>
    800049bc:	597d                	li	s2,-1
    800049be:	b745                	j	8000495e <fileread+0x60>

00000000800049c0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800049c0:	715d                	addi	sp,sp,-80
    800049c2:	e486                	sd	ra,72(sp)
    800049c4:	e0a2                	sd	s0,64(sp)
    800049c6:	fc26                	sd	s1,56(sp)
    800049c8:	f84a                	sd	s2,48(sp)
    800049ca:	f44e                	sd	s3,40(sp)
    800049cc:	f052                	sd	s4,32(sp)
    800049ce:	ec56                	sd	s5,24(sp)
    800049d0:	e85a                	sd	s6,16(sp)
    800049d2:	e45e                	sd	s7,8(sp)
    800049d4:	e062                	sd	s8,0(sp)
    800049d6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049d8:	00954783          	lbu	a5,9(a0)
    800049dc:	10078663          	beqz	a5,80004ae8 <filewrite+0x128>
    800049e0:	892a                	mv	s2,a0
    800049e2:	8aae                	mv	s5,a1
    800049e4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049e6:	411c                	lw	a5,0(a0)
    800049e8:	4705                	li	a4,1
    800049ea:	02e78263          	beq	a5,a4,80004a0e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049ee:	470d                	li	a4,3
    800049f0:	02e78663          	beq	a5,a4,80004a1c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049f4:	4709                	li	a4,2
    800049f6:	0ee79163          	bne	a5,a4,80004ad8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049fa:	0ac05d63          	blez	a2,80004ab4 <filewrite+0xf4>
    int i = 0;
    800049fe:	4981                	li	s3,0
    80004a00:	6b05                	lui	s6,0x1
    80004a02:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a06:	6b85                	lui	s7,0x1
    80004a08:	c00b8b9b          	addiw	s7,s7,-1024
    80004a0c:	a861                	j	80004aa4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a0e:	6908                	ld	a0,16(a0)
    80004a10:	00000097          	auipc	ra,0x0
    80004a14:	22e080e7          	jalr	558(ra) # 80004c3e <pipewrite>
    80004a18:	8a2a                	mv	s4,a0
    80004a1a:	a045                	j	80004aba <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a1c:	02451783          	lh	a5,36(a0)
    80004a20:	03079693          	slli	a3,a5,0x30
    80004a24:	92c1                	srli	a3,a3,0x30
    80004a26:	4725                	li	a4,9
    80004a28:	0cd76263          	bltu	a4,a3,80004aec <filewrite+0x12c>
    80004a2c:	0792                	slli	a5,a5,0x4
    80004a2e:	0001d717          	auipc	a4,0x1d
    80004a32:	aea70713          	addi	a4,a4,-1302 # 80021518 <devsw>
    80004a36:	97ba                	add	a5,a5,a4
    80004a38:	679c                	ld	a5,8(a5)
    80004a3a:	cbdd                	beqz	a5,80004af0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a3c:	4505                	li	a0,1
    80004a3e:	9782                	jalr	a5
    80004a40:	8a2a                	mv	s4,a0
    80004a42:	a8a5                	j	80004aba <filewrite+0xfa>
    80004a44:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a48:	00000097          	auipc	ra,0x0
    80004a4c:	8b0080e7          	jalr	-1872(ra) # 800042f8 <begin_op>
      ilock(f->ip);
    80004a50:	01893503          	ld	a0,24(s2)
    80004a54:	fffff097          	auipc	ra,0xfffff
    80004a58:	ed2080e7          	jalr	-302(ra) # 80003926 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a5c:	8762                	mv	a4,s8
    80004a5e:	02092683          	lw	a3,32(s2)
    80004a62:	01598633          	add	a2,s3,s5
    80004a66:	4585                	li	a1,1
    80004a68:	01893503          	ld	a0,24(s2)
    80004a6c:	fffff097          	auipc	ra,0xfffff
    80004a70:	266080e7          	jalr	614(ra) # 80003cd2 <writei>
    80004a74:	84aa                	mv	s1,a0
    80004a76:	00a05763          	blez	a0,80004a84 <filewrite+0xc4>
        f->off += r;
    80004a7a:	02092783          	lw	a5,32(s2)
    80004a7e:	9fa9                	addw	a5,a5,a0
    80004a80:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a84:	01893503          	ld	a0,24(s2)
    80004a88:	fffff097          	auipc	ra,0xfffff
    80004a8c:	f60080e7          	jalr	-160(ra) # 800039e8 <iunlock>
      end_op();
    80004a90:	00000097          	auipc	ra,0x0
    80004a94:	8e8080e7          	jalr	-1816(ra) # 80004378 <end_op>

      if(r != n1){
    80004a98:	009c1f63          	bne	s8,s1,80004ab6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a9c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004aa0:	0149db63          	bge	s3,s4,80004ab6 <filewrite+0xf6>
      int n1 = n - i;
    80004aa4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004aa8:	84be                	mv	s1,a5
    80004aaa:	2781                	sext.w	a5,a5
    80004aac:	f8fb5ce3          	bge	s6,a5,80004a44 <filewrite+0x84>
    80004ab0:	84de                	mv	s1,s7
    80004ab2:	bf49                	j	80004a44 <filewrite+0x84>
    int i = 0;
    80004ab4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ab6:	013a1f63          	bne	s4,s3,80004ad4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004aba:	8552                	mv	a0,s4
    80004abc:	60a6                	ld	ra,72(sp)
    80004abe:	6406                	ld	s0,64(sp)
    80004ac0:	74e2                	ld	s1,56(sp)
    80004ac2:	7942                	ld	s2,48(sp)
    80004ac4:	79a2                	ld	s3,40(sp)
    80004ac6:	7a02                	ld	s4,32(sp)
    80004ac8:	6ae2                	ld	s5,24(sp)
    80004aca:	6b42                	ld	s6,16(sp)
    80004acc:	6ba2                	ld	s7,8(sp)
    80004ace:	6c02                	ld	s8,0(sp)
    80004ad0:	6161                	addi	sp,sp,80
    80004ad2:	8082                	ret
    ret = (i == n ? n : -1);
    80004ad4:	5a7d                	li	s4,-1
    80004ad6:	b7d5                	j	80004aba <filewrite+0xfa>
    panic("filewrite");
    80004ad8:	00004517          	auipc	a0,0x4
    80004adc:	c0050513          	addi	a0,a0,-1024 # 800086d8 <syscalls+0x278>
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	a5e080e7          	jalr	-1442(ra) # 8000053e <panic>
    return -1;
    80004ae8:	5a7d                	li	s4,-1
    80004aea:	bfc1                	j	80004aba <filewrite+0xfa>
      return -1;
    80004aec:	5a7d                	li	s4,-1
    80004aee:	b7f1                	j	80004aba <filewrite+0xfa>
    80004af0:	5a7d                	li	s4,-1
    80004af2:	b7e1                	j	80004aba <filewrite+0xfa>

0000000080004af4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004af4:	7179                	addi	sp,sp,-48
    80004af6:	f406                	sd	ra,40(sp)
    80004af8:	f022                	sd	s0,32(sp)
    80004afa:	ec26                	sd	s1,24(sp)
    80004afc:	e84a                	sd	s2,16(sp)
    80004afe:	e44e                	sd	s3,8(sp)
    80004b00:	e052                	sd	s4,0(sp)
    80004b02:	1800                	addi	s0,sp,48
    80004b04:	84aa                	mv	s1,a0
    80004b06:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b08:	0005b023          	sd	zero,0(a1)
    80004b0c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b10:	00000097          	auipc	ra,0x0
    80004b14:	bf8080e7          	jalr	-1032(ra) # 80004708 <filealloc>
    80004b18:	e088                	sd	a0,0(s1)
    80004b1a:	c551                	beqz	a0,80004ba6 <pipealloc+0xb2>
    80004b1c:	00000097          	auipc	ra,0x0
    80004b20:	bec080e7          	jalr	-1044(ra) # 80004708 <filealloc>
    80004b24:	00aa3023          	sd	a0,0(s4)
    80004b28:	c92d                	beqz	a0,80004b9a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b2a:	ffffc097          	auipc	ra,0xffffc
    80004b2e:	fca080e7          	jalr	-54(ra) # 80000af4 <kalloc>
    80004b32:	892a                	mv	s2,a0
    80004b34:	c125                	beqz	a0,80004b94 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b36:	4985                	li	s3,1
    80004b38:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b3c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b40:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b44:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b48:	00004597          	auipc	a1,0x4
    80004b4c:	ba058593          	addi	a1,a1,-1120 # 800086e8 <syscalls+0x288>
    80004b50:	ffffc097          	auipc	ra,0xffffc
    80004b54:	004080e7          	jalr	4(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004b58:	609c                	ld	a5,0(s1)
    80004b5a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b5e:	609c                	ld	a5,0(s1)
    80004b60:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b64:	609c                	ld	a5,0(s1)
    80004b66:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b6a:	609c                	ld	a5,0(s1)
    80004b6c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b70:	000a3783          	ld	a5,0(s4)
    80004b74:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b78:	000a3783          	ld	a5,0(s4)
    80004b7c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b80:	000a3783          	ld	a5,0(s4)
    80004b84:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b88:	000a3783          	ld	a5,0(s4)
    80004b8c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b90:	4501                	li	a0,0
    80004b92:	a025                	j	80004bba <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b94:	6088                	ld	a0,0(s1)
    80004b96:	e501                	bnez	a0,80004b9e <pipealloc+0xaa>
    80004b98:	a039                	j	80004ba6 <pipealloc+0xb2>
    80004b9a:	6088                	ld	a0,0(s1)
    80004b9c:	c51d                	beqz	a0,80004bca <pipealloc+0xd6>
    fileclose(*f0);
    80004b9e:	00000097          	auipc	ra,0x0
    80004ba2:	c26080e7          	jalr	-986(ra) # 800047c4 <fileclose>
  if(*f1)
    80004ba6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004baa:	557d                	li	a0,-1
  if(*f1)
    80004bac:	c799                	beqz	a5,80004bba <pipealloc+0xc6>
    fileclose(*f1);
    80004bae:	853e                	mv	a0,a5
    80004bb0:	00000097          	auipc	ra,0x0
    80004bb4:	c14080e7          	jalr	-1004(ra) # 800047c4 <fileclose>
  return -1;
    80004bb8:	557d                	li	a0,-1
}
    80004bba:	70a2                	ld	ra,40(sp)
    80004bbc:	7402                	ld	s0,32(sp)
    80004bbe:	64e2                	ld	s1,24(sp)
    80004bc0:	6942                	ld	s2,16(sp)
    80004bc2:	69a2                	ld	s3,8(sp)
    80004bc4:	6a02                	ld	s4,0(sp)
    80004bc6:	6145                	addi	sp,sp,48
    80004bc8:	8082                	ret
  return -1;
    80004bca:	557d                	li	a0,-1
    80004bcc:	b7fd                	j	80004bba <pipealloc+0xc6>

0000000080004bce <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bce:	1101                	addi	sp,sp,-32
    80004bd0:	ec06                	sd	ra,24(sp)
    80004bd2:	e822                	sd	s0,16(sp)
    80004bd4:	e426                	sd	s1,8(sp)
    80004bd6:	e04a                	sd	s2,0(sp)
    80004bd8:	1000                	addi	s0,sp,32
    80004bda:	84aa                	mv	s1,a0
    80004bdc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	006080e7          	jalr	6(ra) # 80000be4 <acquire>
  if(writable){
    80004be6:	02090d63          	beqz	s2,80004c20 <pipeclose+0x52>
    pi->writeopen = 0;
    80004bea:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bee:	21848513          	addi	a0,s1,536
    80004bf2:	ffffe097          	auipc	ra,0xffffe
    80004bf6:	872080e7          	jalr	-1934(ra) # 80002464 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bfa:	2204b783          	ld	a5,544(s1)
    80004bfe:	eb95                	bnez	a5,80004c32 <pipeclose+0x64>
    release(&pi->lock);
    80004c00:	8526                	mv	a0,s1
    80004c02:	ffffc097          	auipc	ra,0xffffc
    80004c06:	096080e7          	jalr	150(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004c0a:	8526                	mv	a0,s1
    80004c0c:	ffffc097          	auipc	ra,0xffffc
    80004c10:	dec080e7          	jalr	-532(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004c14:	60e2                	ld	ra,24(sp)
    80004c16:	6442                	ld	s0,16(sp)
    80004c18:	64a2                	ld	s1,8(sp)
    80004c1a:	6902                	ld	s2,0(sp)
    80004c1c:	6105                	addi	sp,sp,32
    80004c1e:	8082                	ret
    pi->readopen = 0;
    80004c20:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c24:	21c48513          	addi	a0,s1,540
    80004c28:	ffffe097          	auipc	ra,0xffffe
    80004c2c:	83c080e7          	jalr	-1988(ra) # 80002464 <wakeup>
    80004c30:	b7e9                	j	80004bfa <pipeclose+0x2c>
    release(&pi->lock);
    80004c32:	8526                	mv	a0,s1
    80004c34:	ffffc097          	auipc	ra,0xffffc
    80004c38:	064080e7          	jalr	100(ra) # 80000c98 <release>
}
    80004c3c:	bfe1                	j	80004c14 <pipeclose+0x46>

0000000080004c3e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c3e:	7159                	addi	sp,sp,-112
    80004c40:	f486                	sd	ra,104(sp)
    80004c42:	f0a2                	sd	s0,96(sp)
    80004c44:	eca6                	sd	s1,88(sp)
    80004c46:	e8ca                	sd	s2,80(sp)
    80004c48:	e4ce                	sd	s3,72(sp)
    80004c4a:	e0d2                	sd	s4,64(sp)
    80004c4c:	fc56                	sd	s5,56(sp)
    80004c4e:	f85a                	sd	s6,48(sp)
    80004c50:	f45e                	sd	s7,40(sp)
    80004c52:	f062                	sd	s8,32(sp)
    80004c54:	ec66                	sd	s9,24(sp)
    80004c56:	1880                	addi	s0,sp,112
    80004c58:	84aa                	mv	s1,a0
    80004c5a:	8aae                	mv	s5,a1
    80004c5c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c5e:	ffffd097          	auipc	ra,0xffffd
    80004c62:	d66080e7          	jalr	-666(ra) # 800019c4 <myproc>
    80004c66:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c68:	8526                	mv	a0,s1
    80004c6a:	ffffc097          	auipc	ra,0xffffc
    80004c6e:	f7a080e7          	jalr	-134(ra) # 80000be4 <acquire>
  while(i < n){
    80004c72:	0d405163          	blez	s4,80004d34 <pipewrite+0xf6>
    80004c76:	8ba6                	mv	s7,s1
  int i = 0;
    80004c78:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c7a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c7c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c80:	21c48c13          	addi	s8,s1,540
    80004c84:	a08d                	j	80004ce6 <pipewrite+0xa8>
      release(&pi->lock);
    80004c86:	8526                	mv	a0,s1
    80004c88:	ffffc097          	auipc	ra,0xffffc
    80004c8c:	010080e7          	jalr	16(ra) # 80000c98 <release>
      return -1;
    80004c90:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c92:	854a                	mv	a0,s2
    80004c94:	70a6                	ld	ra,104(sp)
    80004c96:	7406                	ld	s0,96(sp)
    80004c98:	64e6                	ld	s1,88(sp)
    80004c9a:	6946                	ld	s2,80(sp)
    80004c9c:	69a6                	ld	s3,72(sp)
    80004c9e:	6a06                	ld	s4,64(sp)
    80004ca0:	7ae2                	ld	s5,56(sp)
    80004ca2:	7b42                	ld	s6,48(sp)
    80004ca4:	7ba2                	ld	s7,40(sp)
    80004ca6:	7c02                	ld	s8,32(sp)
    80004ca8:	6ce2                	ld	s9,24(sp)
    80004caa:	6165                	addi	sp,sp,112
    80004cac:	8082                	ret
      wakeup(&pi->nread);
    80004cae:	8566                	mv	a0,s9
    80004cb0:	ffffd097          	auipc	ra,0xffffd
    80004cb4:	7b4080e7          	jalr	1972(ra) # 80002464 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cb8:	85de                	mv	a1,s7
    80004cba:	8562                	mv	a0,s8
    80004cbc:	ffffd097          	auipc	ra,0xffffd
    80004cc0:	61c080e7          	jalr	1564(ra) # 800022d8 <sleep>
    80004cc4:	a839                	j	80004ce2 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cc6:	21c4a783          	lw	a5,540(s1)
    80004cca:	0017871b          	addiw	a4,a5,1
    80004cce:	20e4ae23          	sw	a4,540(s1)
    80004cd2:	1ff7f793          	andi	a5,a5,511
    80004cd6:	97a6                	add	a5,a5,s1
    80004cd8:	f9f44703          	lbu	a4,-97(s0)
    80004cdc:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ce0:	2905                	addiw	s2,s2,1
  while(i < n){
    80004ce2:	03495d63          	bge	s2,s4,80004d1c <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004ce6:	2204a783          	lw	a5,544(s1)
    80004cea:	dfd1                	beqz	a5,80004c86 <pipewrite+0x48>
    80004cec:	0289a783          	lw	a5,40(s3)
    80004cf0:	fbd9                	bnez	a5,80004c86 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004cf2:	2184a783          	lw	a5,536(s1)
    80004cf6:	21c4a703          	lw	a4,540(s1)
    80004cfa:	2007879b          	addiw	a5,a5,512
    80004cfe:	faf708e3          	beq	a4,a5,80004cae <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d02:	4685                	li	a3,1
    80004d04:	01590633          	add	a2,s2,s5
    80004d08:	f9f40593          	addi	a1,s0,-97
    80004d0c:	0589b503          	ld	a0,88(s3)
    80004d10:	ffffd097          	auipc	ra,0xffffd
    80004d14:	9f6080e7          	jalr	-1546(ra) # 80001706 <copyin>
    80004d18:	fb6517e3          	bne	a0,s6,80004cc6 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d1c:	21848513          	addi	a0,s1,536
    80004d20:	ffffd097          	auipc	ra,0xffffd
    80004d24:	744080e7          	jalr	1860(ra) # 80002464 <wakeup>
  release(&pi->lock);
    80004d28:	8526                	mv	a0,s1
    80004d2a:	ffffc097          	auipc	ra,0xffffc
    80004d2e:	f6e080e7          	jalr	-146(ra) # 80000c98 <release>
  return i;
    80004d32:	b785                	j	80004c92 <pipewrite+0x54>
  int i = 0;
    80004d34:	4901                	li	s2,0
    80004d36:	b7dd                	j	80004d1c <pipewrite+0xde>

0000000080004d38 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d38:	715d                	addi	sp,sp,-80
    80004d3a:	e486                	sd	ra,72(sp)
    80004d3c:	e0a2                	sd	s0,64(sp)
    80004d3e:	fc26                	sd	s1,56(sp)
    80004d40:	f84a                	sd	s2,48(sp)
    80004d42:	f44e                	sd	s3,40(sp)
    80004d44:	f052                	sd	s4,32(sp)
    80004d46:	ec56                	sd	s5,24(sp)
    80004d48:	e85a                	sd	s6,16(sp)
    80004d4a:	0880                	addi	s0,sp,80
    80004d4c:	84aa                	mv	s1,a0
    80004d4e:	892e                	mv	s2,a1
    80004d50:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d52:	ffffd097          	auipc	ra,0xffffd
    80004d56:	c72080e7          	jalr	-910(ra) # 800019c4 <myproc>
    80004d5a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d5c:	8b26                	mv	s6,s1
    80004d5e:	8526                	mv	a0,s1
    80004d60:	ffffc097          	auipc	ra,0xffffc
    80004d64:	e84080e7          	jalr	-380(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d68:	2184a703          	lw	a4,536(s1)
    80004d6c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d70:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d74:	02f71463          	bne	a4,a5,80004d9c <piperead+0x64>
    80004d78:	2244a783          	lw	a5,548(s1)
    80004d7c:	c385                	beqz	a5,80004d9c <piperead+0x64>
    if(pr->killed){
    80004d7e:	028a2783          	lw	a5,40(s4)
    80004d82:	ebc1                	bnez	a5,80004e12 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d84:	85da                	mv	a1,s6
    80004d86:	854e                	mv	a0,s3
    80004d88:	ffffd097          	auipc	ra,0xffffd
    80004d8c:	550080e7          	jalr	1360(ra) # 800022d8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d90:	2184a703          	lw	a4,536(s1)
    80004d94:	21c4a783          	lw	a5,540(s1)
    80004d98:	fef700e3          	beq	a4,a5,80004d78 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d9c:	09505263          	blez	s5,80004e20 <piperead+0xe8>
    80004da0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004da2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004da4:	2184a783          	lw	a5,536(s1)
    80004da8:	21c4a703          	lw	a4,540(s1)
    80004dac:	02f70d63          	beq	a4,a5,80004de6 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004db0:	0017871b          	addiw	a4,a5,1
    80004db4:	20e4ac23          	sw	a4,536(s1)
    80004db8:	1ff7f793          	andi	a5,a5,511
    80004dbc:	97a6                	add	a5,a5,s1
    80004dbe:	0187c783          	lbu	a5,24(a5)
    80004dc2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dc6:	4685                	li	a3,1
    80004dc8:	fbf40613          	addi	a2,s0,-65
    80004dcc:	85ca                	mv	a1,s2
    80004dce:	058a3503          	ld	a0,88(s4)
    80004dd2:	ffffd097          	auipc	ra,0xffffd
    80004dd6:	8a8080e7          	jalr	-1880(ra) # 8000167a <copyout>
    80004dda:	01650663          	beq	a0,s6,80004de6 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dde:	2985                	addiw	s3,s3,1
    80004de0:	0905                	addi	s2,s2,1
    80004de2:	fd3a91e3          	bne	s5,s3,80004da4 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004de6:	21c48513          	addi	a0,s1,540
    80004dea:	ffffd097          	auipc	ra,0xffffd
    80004dee:	67a080e7          	jalr	1658(ra) # 80002464 <wakeup>
  release(&pi->lock);
    80004df2:	8526                	mv	a0,s1
    80004df4:	ffffc097          	auipc	ra,0xffffc
    80004df8:	ea4080e7          	jalr	-348(ra) # 80000c98 <release>
  return i;
}
    80004dfc:	854e                	mv	a0,s3
    80004dfe:	60a6                	ld	ra,72(sp)
    80004e00:	6406                	ld	s0,64(sp)
    80004e02:	74e2                	ld	s1,56(sp)
    80004e04:	7942                	ld	s2,48(sp)
    80004e06:	79a2                	ld	s3,40(sp)
    80004e08:	7a02                	ld	s4,32(sp)
    80004e0a:	6ae2                	ld	s5,24(sp)
    80004e0c:	6b42                	ld	s6,16(sp)
    80004e0e:	6161                	addi	sp,sp,80
    80004e10:	8082                	ret
      release(&pi->lock);
    80004e12:	8526                	mv	a0,s1
    80004e14:	ffffc097          	auipc	ra,0xffffc
    80004e18:	e84080e7          	jalr	-380(ra) # 80000c98 <release>
      return -1;
    80004e1c:	59fd                	li	s3,-1
    80004e1e:	bff9                	j	80004dfc <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e20:	4981                	li	s3,0
    80004e22:	b7d1                	j	80004de6 <piperead+0xae>

0000000080004e24 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e24:	df010113          	addi	sp,sp,-528
    80004e28:	20113423          	sd	ra,520(sp)
    80004e2c:	20813023          	sd	s0,512(sp)
    80004e30:	ffa6                	sd	s1,504(sp)
    80004e32:	fbca                	sd	s2,496(sp)
    80004e34:	f7ce                	sd	s3,488(sp)
    80004e36:	f3d2                	sd	s4,480(sp)
    80004e38:	efd6                	sd	s5,472(sp)
    80004e3a:	ebda                	sd	s6,464(sp)
    80004e3c:	e7de                	sd	s7,456(sp)
    80004e3e:	e3e2                	sd	s8,448(sp)
    80004e40:	ff66                	sd	s9,440(sp)
    80004e42:	fb6a                	sd	s10,432(sp)
    80004e44:	f76e                	sd	s11,424(sp)
    80004e46:	0c00                	addi	s0,sp,528
    80004e48:	84aa                	mv	s1,a0
    80004e4a:	dea43c23          	sd	a0,-520(s0)
    80004e4e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e52:	ffffd097          	auipc	ra,0xffffd
    80004e56:	b72080e7          	jalr	-1166(ra) # 800019c4 <myproc>
    80004e5a:	892a                	mv	s2,a0

  begin_op();
    80004e5c:	fffff097          	auipc	ra,0xfffff
    80004e60:	49c080e7          	jalr	1180(ra) # 800042f8 <begin_op>

  if((ip = namei(path)) == 0){
    80004e64:	8526                	mv	a0,s1
    80004e66:	fffff097          	auipc	ra,0xfffff
    80004e6a:	276080e7          	jalr	630(ra) # 800040dc <namei>
    80004e6e:	c92d                	beqz	a0,80004ee0 <exec+0xbc>
    80004e70:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e72:	fffff097          	auipc	ra,0xfffff
    80004e76:	ab4080e7          	jalr	-1356(ra) # 80003926 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e7a:	04000713          	li	a4,64
    80004e7e:	4681                	li	a3,0
    80004e80:	e5040613          	addi	a2,s0,-432
    80004e84:	4581                	li	a1,0
    80004e86:	8526                	mv	a0,s1
    80004e88:	fffff097          	auipc	ra,0xfffff
    80004e8c:	d52080e7          	jalr	-686(ra) # 80003bda <readi>
    80004e90:	04000793          	li	a5,64
    80004e94:	00f51a63          	bne	a0,a5,80004ea8 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e98:	e5042703          	lw	a4,-432(s0)
    80004e9c:	464c47b7          	lui	a5,0x464c4
    80004ea0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ea4:	04f70463          	beq	a4,a5,80004eec <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ea8:	8526                	mv	a0,s1
    80004eaa:	fffff097          	auipc	ra,0xfffff
    80004eae:	cde080e7          	jalr	-802(ra) # 80003b88 <iunlockput>
    end_op();
    80004eb2:	fffff097          	auipc	ra,0xfffff
    80004eb6:	4c6080e7          	jalr	1222(ra) # 80004378 <end_op>
  }
  return -1;
    80004eba:	557d                	li	a0,-1
}
    80004ebc:	20813083          	ld	ra,520(sp)
    80004ec0:	20013403          	ld	s0,512(sp)
    80004ec4:	74fe                	ld	s1,504(sp)
    80004ec6:	795e                	ld	s2,496(sp)
    80004ec8:	79be                	ld	s3,488(sp)
    80004eca:	7a1e                	ld	s4,480(sp)
    80004ecc:	6afe                	ld	s5,472(sp)
    80004ece:	6b5e                	ld	s6,464(sp)
    80004ed0:	6bbe                	ld	s7,456(sp)
    80004ed2:	6c1e                	ld	s8,448(sp)
    80004ed4:	7cfa                	ld	s9,440(sp)
    80004ed6:	7d5a                	ld	s10,432(sp)
    80004ed8:	7dba                	ld	s11,424(sp)
    80004eda:	21010113          	addi	sp,sp,528
    80004ede:	8082                	ret
    end_op();
    80004ee0:	fffff097          	auipc	ra,0xfffff
    80004ee4:	498080e7          	jalr	1176(ra) # 80004378 <end_op>
    return -1;
    80004ee8:	557d                	li	a0,-1
    80004eea:	bfc9                	j	80004ebc <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004eec:	854a                	mv	a0,s2
    80004eee:	ffffd097          	auipc	ra,0xffffd
    80004ef2:	b9a080e7          	jalr	-1126(ra) # 80001a88 <proc_pagetable>
    80004ef6:	8baa                	mv	s7,a0
    80004ef8:	d945                	beqz	a0,80004ea8 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004efa:	e7042983          	lw	s3,-400(s0)
    80004efe:	e8845783          	lhu	a5,-376(s0)
    80004f02:	c7ad                	beqz	a5,80004f6c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f04:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f06:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004f08:	6c85                	lui	s9,0x1
    80004f0a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f0e:	def43823          	sd	a5,-528(s0)
    80004f12:	a42d                	j	8000513c <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f14:	00003517          	auipc	a0,0x3
    80004f18:	7dc50513          	addi	a0,a0,2012 # 800086f0 <syscalls+0x290>
    80004f1c:	ffffb097          	auipc	ra,0xffffb
    80004f20:	622080e7          	jalr	1570(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f24:	8756                	mv	a4,s5
    80004f26:	012d86bb          	addw	a3,s11,s2
    80004f2a:	4581                	li	a1,0
    80004f2c:	8526                	mv	a0,s1
    80004f2e:	fffff097          	auipc	ra,0xfffff
    80004f32:	cac080e7          	jalr	-852(ra) # 80003bda <readi>
    80004f36:	2501                	sext.w	a0,a0
    80004f38:	1aaa9963          	bne	s5,a0,800050ea <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f3c:	6785                	lui	a5,0x1
    80004f3e:	0127893b          	addw	s2,a5,s2
    80004f42:	77fd                	lui	a5,0xfffff
    80004f44:	01478a3b          	addw	s4,a5,s4
    80004f48:	1f897163          	bgeu	s2,s8,8000512a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004f4c:	02091593          	slli	a1,s2,0x20
    80004f50:	9181                	srli	a1,a1,0x20
    80004f52:	95ea                	add	a1,a1,s10
    80004f54:	855e                	mv	a0,s7
    80004f56:	ffffc097          	auipc	ra,0xffffc
    80004f5a:	120080e7          	jalr	288(ra) # 80001076 <walkaddr>
    80004f5e:	862a                	mv	a2,a0
    if(pa == 0)
    80004f60:	d955                	beqz	a0,80004f14 <exec+0xf0>
      n = PGSIZE;
    80004f62:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f64:	fd9a70e3          	bgeu	s4,s9,80004f24 <exec+0x100>
      n = sz - i;
    80004f68:	8ad2                	mv	s5,s4
    80004f6a:	bf6d                	j	80004f24 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f6c:	4901                	li	s2,0
  iunlockput(ip);
    80004f6e:	8526                	mv	a0,s1
    80004f70:	fffff097          	auipc	ra,0xfffff
    80004f74:	c18080e7          	jalr	-1000(ra) # 80003b88 <iunlockput>
  end_op();
    80004f78:	fffff097          	auipc	ra,0xfffff
    80004f7c:	400080e7          	jalr	1024(ra) # 80004378 <end_op>
  p = myproc();
    80004f80:	ffffd097          	auipc	ra,0xffffd
    80004f84:	a44080e7          	jalr	-1468(ra) # 800019c4 <myproc>
    80004f88:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f8a:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80004f8e:	6785                	lui	a5,0x1
    80004f90:	17fd                	addi	a5,a5,-1
    80004f92:	993e                	add	s2,s2,a5
    80004f94:	757d                	lui	a0,0xfffff
    80004f96:	00a977b3          	and	a5,s2,a0
    80004f9a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f9e:	6609                	lui	a2,0x2
    80004fa0:	963e                	add	a2,a2,a5
    80004fa2:	85be                	mv	a1,a5
    80004fa4:	855e                	mv	a0,s7
    80004fa6:	ffffc097          	auipc	ra,0xffffc
    80004faa:	484080e7          	jalr	1156(ra) # 8000142a <uvmalloc>
    80004fae:	8b2a                	mv	s6,a0
  ip = 0;
    80004fb0:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fb2:	12050c63          	beqz	a0,800050ea <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fb6:	75f9                	lui	a1,0xffffe
    80004fb8:	95aa                	add	a1,a1,a0
    80004fba:	855e                	mv	a0,s7
    80004fbc:	ffffc097          	auipc	ra,0xffffc
    80004fc0:	68c080e7          	jalr	1676(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80004fc4:	7c7d                	lui	s8,0xfffff
    80004fc6:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fc8:	e0043783          	ld	a5,-512(s0)
    80004fcc:	6388                	ld	a0,0(a5)
    80004fce:	c535                	beqz	a0,8000503a <exec+0x216>
    80004fd0:	e9040993          	addi	s3,s0,-368
    80004fd4:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004fd8:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004fda:	ffffc097          	auipc	ra,0xffffc
    80004fde:	e8a080e7          	jalr	-374(ra) # 80000e64 <strlen>
    80004fe2:	2505                	addiw	a0,a0,1
    80004fe4:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fe8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fec:	13896363          	bltu	s2,s8,80005112 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ff0:	e0043d83          	ld	s11,-512(s0)
    80004ff4:	000dba03          	ld	s4,0(s11)
    80004ff8:	8552                	mv	a0,s4
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	e6a080e7          	jalr	-406(ra) # 80000e64 <strlen>
    80005002:	0015069b          	addiw	a3,a0,1
    80005006:	8652                	mv	a2,s4
    80005008:	85ca                	mv	a1,s2
    8000500a:	855e                	mv	a0,s7
    8000500c:	ffffc097          	auipc	ra,0xffffc
    80005010:	66e080e7          	jalr	1646(ra) # 8000167a <copyout>
    80005014:	10054363          	bltz	a0,8000511a <exec+0x2f6>
    ustack[argc] = sp;
    80005018:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000501c:	0485                	addi	s1,s1,1
    8000501e:	008d8793          	addi	a5,s11,8
    80005022:	e0f43023          	sd	a5,-512(s0)
    80005026:	008db503          	ld	a0,8(s11)
    8000502a:	c911                	beqz	a0,8000503e <exec+0x21a>
    if(argc >= MAXARG)
    8000502c:	09a1                	addi	s3,s3,8
    8000502e:	fb3c96e3          	bne	s9,s3,80004fda <exec+0x1b6>
  sz = sz1;
    80005032:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005036:	4481                	li	s1,0
    80005038:	a84d                	j	800050ea <exec+0x2c6>
  sp = sz;
    8000503a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000503c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000503e:	00349793          	slli	a5,s1,0x3
    80005042:	f9040713          	addi	a4,s0,-112
    80005046:	97ba                	add	a5,a5,a4
    80005048:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000504c:	00148693          	addi	a3,s1,1
    80005050:	068e                	slli	a3,a3,0x3
    80005052:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005056:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000505a:	01897663          	bgeu	s2,s8,80005066 <exec+0x242>
  sz = sz1;
    8000505e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005062:	4481                	li	s1,0
    80005064:	a059                	j	800050ea <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005066:	e9040613          	addi	a2,s0,-368
    8000506a:	85ca                	mv	a1,s2
    8000506c:	855e                	mv	a0,s7
    8000506e:	ffffc097          	auipc	ra,0xffffc
    80005072:	60c080e7          	jalr	1548(ra) # 8000167a <copyout>
    80005076:	0a054663          	bltz	a0,80005122 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000507a:	060ab783          	ld	a5,96(s5)
    8000507e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005082:	df843783          	ld	a5,-520(s0)
    80005086:	0007c703          	lbu	a4,0(a5)
    8000508a:	cf11                	beqz	a4,800050a6 <exec+0x282>
    8000508c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000508e:	02f00693          	li	a3,47
    80005092:	a039                	j	800050a0 <exec+0x27c>
      last = s+1;
    80005094:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005098:	0785                	addi	a5,a5,1
    8000509a:	fff7c703          	lbu	a4,-1(a5)
    8000509e:	c701                	beqz	a4,800050a6 <exec+0x282>
    if(*s == '/')
    800050a0:	fed71ce3          	bne	a4,a3,80005098 <exec+0x274>
    800050a4:	bfc5                	j	80005094 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800050a6:	4641                	li	a2,16
    800050a8:	df843583          	ld	a1,-520(s0)
    800050ac:	160a8513          	addi	a0,s5,352
    800050b0:	ffffc097          	auipc	ra,0xffffc
    800050b4:	d82080e7          	jalr	-638(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800050b8:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    800050bc:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    800050c0:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050c4:	060ab783          	ld	a5,96(s5)
    800050c8:	e6843703          	ld	a4,-408(s0)
    800050cc:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050ce:	060ab783          	ld	a5,96(s5)
    800050d2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050d6:	85ea                	mv	a1,s10
    800050d8:	ffffd097          	auipc	ra,0xffffd
    800050dc:	a4c080e7          	jalr	-1460(ra) # 80001b24 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050e0:	0004851b          	sext.w	a0,s1
    800050e4:	bbe1                	j	80004ebc <exec+0x98>
    800050e6:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800050ea:	e0843583          	ld	a1,-504(s0)
    800050ee:	855e                	mv	a0,s7
    800050f0:	ffffd097          	auipc	ra,0xffffd
    800050f4:	a34080e7          	jalr	-1484(ra) # 80001b24 <proc_freepagetable>
  if(ip){
    800050f8:	da0498e3          	bnez	s1,80004ea8 <exec+0x84>
  return -1;
    800050fc:	557d                	li	a0,-1
    800050fe:	bb7d                	j	80004ebc <exec+0x98>
    80005100:	e1243423          	sd	s2,-504(s0)
    80005104:	b7dd                	j	800050ea <exec+0x2c6>
    80005106:	e1243423          	sd	s2,-504(s0)
    8000510a:	b7c5                	j	800050ea <exec+0x2c6>
    8000510c:	e1243423          	sd	s2,-504(s0)
    80005110:	bfe9                	j	800050ea <exec+0x2c6>
  sz = sz1;
    80005112:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005116:	4481                	li	s1,0
    80005118:	bfc9                	j	800050ea <exec+0x2c6>
  sz = sz1;
    8000511a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000511e:	4481                	li	s1,0
    80005120:	b7e9                	j	800050ea <exec+0x2c6>
  sz = sz1;
    80005122:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005126:	4481                	li	s1,0
    80005128:	b7c9                	j	800050ea <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000512a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000512e:	2b05                	addiw	s6,s6,1
    80005130:	0389899b          	addiw	s3,s3,56
    80005134:	e8845783          	lhu	a5,-376(s0)
    80005138:	e2fb5be3          	bge	s6,a5,80004f6e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000513c:	2981                	sext.w	s3,s3
    8000513e:	03800713          	li	a4,56
    80005142:	86ce                	mv	a3,s3
    80005144:	e1840613          	addi	a2,s0,-488
    80005148:	4581                	li	a1,0
    8000514a:	8526                	mv	a0,s1
    8000514c:	fffff097          	auipc	ra,0xfffff
    80005150:	a8e080e7          	jalr	-1394(ra) # 80003bda <readi>
    80005154:	03800793          	li	a5,56
    80005158:	f8f517e3          	bne	a0,a5,800050e6 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000515c:	e1842783          	lw	a5,-488(s0)
    80005160:	4705                	li	a4,1
    80005162:	fce796e3          	bne	a5,a4,8000512e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005166:	e4043603          	ld	a2,-448(s0)
    8000516a:	e3843783          	ld	a5,-456(s0)
    8000516e:	f8f669e3          	bltu	a2,a5,80005100 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005172:	e2843783          	ld	a5,-472(s0)
    80005176:	963e                	add	a2,a2,a5
    80005178:	f8f667e3          	bltu	a2,a5,80005106 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000517c:	85ca                	mv	a1,s2
    8000517e:	855e                	mv	a0,s7
    80005180:	ffffc097          	auipc	ra,0xffffc
    80005184:	2aa080e7          	jalr	682(ra) # 8000142a <uvmalloc>
    80005188:	e0a43423          	sd	a0,-504(s0)
    8000518c:	d141                	beqz	a0,8000510c <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000518e:	e2843d03          	ld	s10,-472(s0)
    80005192:	df043783          	ld	a5,-528(s0)
    80005196:	00fd77b3          	and	a5,s10,a5
    8000519a:	fba1                	bnez	a5,800050ea <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000519c:	e2042d83          	lw	s11,-480(s0)
    800051a0:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051a4:	f80c03e3          	beqz	s8,8000512a <exec+0x306>
    800051a8:	8a62                	mv	s4,s8
    800051aa:	4901                	li	s2,0
    800051ac:	b345                	j	80004f4c <exec+0x128>

00000000800051ae <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051ae:	7179                	addi	sp,sp,-48
    800051b0:	f406                	sd	ra,40(sp)
    800051b2:	f022                	sd	s0,32(sp)
    800051b4:	ec26                	sd	s1,24(sp)
    800051b6:	e84a                	sd	s2,16(sp)
    800051b8:	1800                	addi	s0,sp,48
    800051ba:	892e                	mv	s2,a1
    800051bc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800051be:	fdc40593          	addi	a1,s0,-36
    800051c2:	ffffe097          	auipc	ra,0xffffe
    800051c6:	ba6080e7          	jalr	-1114(ra) # 80002d68 <argint>
    800051ca:	04054063          	bltz	a0,8000520a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051ce:	fdc42703          	lw	a4,-36(s0)
    800051d2:	47bd                	li	a5,15
    800051d4:	02e7ed63          	bltu	a5,a4,8000520e <argfd+0x60>
    800051d8:	ffffc097          	auipc	ra,0xffffc
    800051dc:	7ec080e7          	jalr	2028(ra) # 800019c4 <myproc>
    800051e0:	fdc42703          	lw	a4,-36(s0)
    800051e4:	01a70793          	addi	a5,a4,26
    800051e8:	078e                	slli	a5,a5,0x3
    800051ea:	953e                	add	a0,a0,a5
    800051ec:	651c                	ld	a5,8(a0)
    800051ee:	c395                	beqz	a5,80005212 <argfd+0x64>
    return -1;
  if(pfd)
    800051f0:	00090463          	beqz	s2,800051f8 <argfd+0x4a>
    *pfd = fd;
    800051f4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051f8:	4501                	li	a0,0
  if(pf)
    800051fa:	c091                	beqz	s1,800051fe <argfd+0x50>
    *pf = f;
    800051fc:	e09c                	sd	a5,0(s1)
}
    800051fe:	70a2                	ld	ra,40(sp)
    80005200:	7402                	ld	s0,32(sp)
    80005202:	64e2                	ld	s1,24(sp)
    80005204:	6942                	ld	s2,16(sp)
    80005206:	6145                	addi	sp,sp,48
    80005208:	8082                	ret
    return -1;
    8000520a:	557d                	li	a0,-1
    8000520c:	bfcd                	j	800051fe <argfd+0x50>
    return -1;
    8000520e:	557d                	li	a0,-1
    80005210:	b7fd                	j	800051fe <argfd+0x50>
    80005212:	557d                	li	a0,-1
    80005214:	b7ed                	j	800051fe <argfd+0x50>

0000000080005216 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005216:	1101                	addi	sp,sp,-32
    80005218:	ec06                	sd	ra,24(sp)
    8000521a:	e822                	sd	s0,16(sp)
    8000521c:	e426                	sd	s1,8(sp)
    8000521e:	1000                	addi	s0,sp,32
    80005220:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005222:	ffffc097          	auipc	ra,0xffffc
    80005226:	7a2080e7          	jalr	1954(ra) # 800019c4 <myproc>
    8000522a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000522c:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffd90d8>
    80005230:	4501                	li	a0,0
    80005232:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005234:	6398                	ld	a4,0(a5)
    80005236:	cb19                	beqz	a4,8000524c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005238:	2505                	addiw	a0,a0,1
    8000523a:	07a1                	addi	a5,a5,8
    8000523c:	fed51ce3          	bne	a0,a3,80005234 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005240:	557d                	li	a0,-1
}
    80005242:	60e2                	ld	ra,24(sp)
    80005244:	6442                	ld	s0,16(sp)
    80005246:	64a2                	ld	s1,8(sp)
    80005248:	6105                	addi	sp,sp,32
    8000524a:	8082                	ret
      p->ofile[fd] = f;
    8000524c:	01a50793          	addi	a5,a0,26
    80005250:	078e                	slli	a5,a5,0x3
    80005252:	963e                	add	a2,a2,a5
    80005254:	e604                	sd	s1,8(a2)
      return fd;
    80005256:	b7f5                	j	80005242 <fdalloc+0x2c>

0000000080005258 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005258:	715d                	addi	sp,sp,-80
    8000525a:	e486                	sd	ra,72(sp)
    8000525c:	e0a2                	sd	s0,64(sp)
    8000525e:	fc26                	sd	s1,56(sp)
    80005260:	f84a                	sd	s2,48(sp)
    80005262:	f44e                	sd	s3,40(sp)
    80005264:	f052                	sd	s4,32(sp)
    80005266:	ec56                	sd	s5,24(sp)
    80005268:	0880                	addi	s0,sp,80
    8000526a:	89ae                	mv	s3,a1
    8000526c:	8ab2                	mv	s5,a2
    8000526e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005270:	fb040593          	addi	a1,s0,-80
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	e86080e7          	jalr	-378(ra) # 800040fa <nameiparent>
    8000527c:	892a                	mv	s2,a0
    8000527e:	12050f63          	beqz	a0,800053bc <create+0x164>
    return 0;

  ilock(dp);
    80005282:	ffffe097          	auipc	ra,0xffffe
    80005286:	6a4080e7          	jalr	1700(ra) # 80003926 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000528a:	4601                	li	a2,0
    8000528c:	fb040593          	addi	a1,s0,-80
    80005290:	854a                	mv	a0,s2
    80005292:	fffff097          	auipc	ra,0xfffff
    80005296:	b78080e7          	jalr	-1160(ra) # 80003e0a <dirlookup>
    8000529a:	84aa                	mv	s1,a0
    8000529c:	c921                	beqz	a0,800052ec <create+0x94>
    iunlockput(dp);
    8000529e:	854a                	mv	a0,s2
    800052a0:	fffff097          	auipc	ra,0xfffff
    800052a4:	8e8080e7          	jalr	-1816(ra) # 80003b88 <iunlockput>
    ilock(ip);
    800052a8:	8526                	mv	a0,s1
    800052aa:	ffffe097          	auipc	ra,0xffffe
    800052ae:	67c080e7          	jalr	1660(ra) # 80003926 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052b2:	2981                	sext.w	s3,s3
    800052b4:	4789                	li	a5,2
    800052b6:	02f99463          	bne	s3,a5,800052de <create+0x86>
    800052ba:	0444d783          	lhu	a5,68(s1)
    800052be:	37f9                	addiw	a5,a5,-2
    800052c0:	17c2                	slli	a5,a5,0x30
    800052c2:	93c1                	srli	a5,a5,0x30
    800052c4:	4705                	li	a4,1
    800052c6:	00f76c63          	bltu	a4,a5,800052de <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800052ca:	8526                	mv	a0,s1
    800052cc:	60a6                	ld	ra,72(sp)
    800052ce:	6406                	ld	s0,64(sp)
    800052d0:	74e2                	ld	s1,56(sp)
    800052d2:	7942                	ld	s2,48(sp)
    800052d4:	79a2                	ld	s3,40(sp)
    800052d6:	7a02                	ld	s4,32(sp)
    800052d8:	6ae2                	ld	s5,24(sp)
    800052da:	6161                	addi	sp,sp,80
    800052dc:	8082                	ret
    iunlockput(ip);
    800052de:	8526                	mv	a0,s1
    800052e0:	fffff097          	auipc	ra,0xfffff
    800052e4:	8a8080e7          	jalr	-1880(ra) # 80003b88 <iunlockput>
    return 0;
    800052e8:	4481                	li	s1,0
    800052ea:	b7c5                	j	800052ca <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052ec:	85ce                	mv	a1,s3
    800052ee:	00092503          	lw	a0,0(s2)
    800052f2:	ffffe097          	auipc	ra,0xffffe
    800052f6:	49c080e7          	jalr	1180(ra) # 8000378e <ialloc>
    800052fa:	84aa                	mv	s1,a0
    800052fc:	c529                	beqz	a0,80005346 <create+0xee>
  ilock(ip);
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	628080e7          	jalr	1576(ra) # 80003926 <ilock>
  ip->major = major;
    80005306:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000530a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000530e:	4785                	li	a5,1
    80005310:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005314:	8526                	mv	a0,s1
    80005316:	ffffe097          	auipc	ra,0xffffe
    8000531a:	546080e7          	jalr	1350(ra) # 8000385c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000531e:	2981                	sext.w	s3,s3
    80005320:	4785                	li	a5,1
    80005322:	02f98a63          	beq	s3,a5,80005356 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005326:	40d0                	lw	a2,4(s1)
    80005328:	fb040593          	addi	a1,s0,-80
    8000532c:	854a                	mv	a0,s2
    8000532e:	fffff097          	auipc	ra,0xfffff
    80005332:	cec080e7          	jalr	-788(ra) # 8000401a <dirlink>
    80005336:	06054b63          	bltz	a0,800053ac <create+0x154>
  iunlockput(dp);
    8000533a:	854a                	mv	a0,s2
    8000533c:	fffff097          	auipc	ra,0xfffff
    80005340:	84c080e7          	jalr	-1972(ra) # 80003b88 <iunlockput>
  return ip;
    80005344:	b759                	j	800052ca <create+0x72>
    panic("create: ialloc");
    80005346:	00003517          	auipc	a0,0x3
    8000534a:	3ca50513          	addi	a0,a0,970 # 80008710 <syscalls+0x2b0>
    8000534e:	ffffb097          	auipc	ra,0xffffb
    80005352:	1f0080e7          	jalr	496(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005356:	04a95783          	lhu	a5,74(s2)
    8000535a:	2785                	addiw	a5,a5,1
    8000535c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005360:	854a                	mv	a0,s2
    80005362:	ffffe097          	auipc	ra,0xffffe
    80005366:	4fa080e7          	jalr	1274(ra) # 8000385c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000536a:	40d0                	lw	a2,4(s1)
    8000536c:	00003597          	auipc	a1,0x3
    80005370:	3b458593          	addi	a1,a1,948 # 80008720 <syscalls+0x2c0>
    80005374:	8526                	mv	a0,s1
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	ca4080e7          	jalr	-860(ra) # 8000401a <dirlink>
    8000537e:	00054f63          	bltz	a0,8000539c <create+0x144>
    80005382:	00492603          	lw	a2,4(s2)
    80005386:	00003597          	auipc	a1,0x3
    8000538a:	3a258593          	addi	a1,a1,930 # 80008728 <syscalls+0x2c8>
    8000538e:	8526                	mv	a0,s1
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	c8a080e7          	jalr	-886(ra) # 8000401a <dirlink>
    80005398:	f80557e3          	bgez	a0,80005326 <create+0xce>
      panic("create dots");
    8000539c:	00003517          	auipc	a0,0x3
    800053a0:	39450513          	addi	a0,a0,916 # 80008730 <syscalls+0x2d0>
    800053a4:	ffffb097          	auipc	ra,0xffffb
    800053a8:	19a080e7          	jalr	410(ra) # 8000053e <panic>
    panic("create: dirlink");
    800053ac:	00003517          	auipc	a0,0x3
    800053b0:	39450513          	addi	a0,a0,916 # 80008740 <syscalls+0x2e0>
    800053b4:	ffffb097          	auipc	ra,0xffffb
    800053b8:	18a080e7          	jalr	394(ra) # 8000053e <panic>
    return 0;
    800053bc:	84aa                	mv	s1,a0
    800053be:	b731                	j	800052ca <create+0x72>

00000000800053c0 <sys_dup>:
{
    800053c0:	7179                	addi	sp,sp,-48
    800053c2:	f406                	sd	ra,40(sp)
    800053c4:	f022                	sd	s0,32(sp)
    800053c6:	ec26                	sd	s1,24(sp)
    800053c8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053ca:	fd840613          	addi	a2,s0,-40
    800053ce:	4581                	li	a1,0
    800053d0:	4501                	li	a0,0
    800053d2:	00000097          	auipc	ra,0x0
    800053d6:	ddc080e7          	jalr	-548(ra) # 800051ae <argfd>
    return -1;
    800053da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053dc:	02054363          	bltz	a0,80005402 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053e0:	fd843503          	ld	a0,-40(s0)
    800053e4:	00000097          	auipc	ra,0x0
    800053e8:	e32080e7          	jalr	-462(ra) # 80005216 <fdalloc>
    800053ec:	84aa                	mv	s1,a0
    return -1;
    800053ee:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053f0:	00054963          	bltz	a0,80005402 <sys_dup+0x42>
  filedup(f);
    800053f4:	fd843503          	ld	a0,-40(s0)
    800053f8:	fffff097          	auipc	ra,0xfffff
    800053fc:	37a080e7          	jalr	890(ra) # 80004772 <filedup>
  return fd;
    80005400:	87a6                	mv	a5,s1
}
    80005402:	853e                	mv	a0,a5
    80005404:	70a2                	ld	ra,40(sp)
    80005406:	7402                	ld	s0,32(sp)
    80005408:	64e2                	ld	s1,24(sp)
    8000540a:	6145                	addi	sp,sp,48
    8000540c:	8082                	ret

000000008000540e <sys_read>:
{
    8000540e:	7179                	addi	sp,sp,-48
    80005410:	f406                	sd	ra,40(sp)
    80005412:	f022                	sd	s0,32(sp)
    80005414:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005416:	fe840613          	addi	a2,s0,-24
    8000541a:	4581                	li	a1,0
    8000541c:	4501                	li	a0,0
    8000541e:	00000097          	auipc	ra,0x0
    80005422:	d90080e7          	jalr	-624(ra) # 800051ae <argfd>
    return -1;
    80005426:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005428:	04054163          	bltz	a0,8000546a <sys_read+0x5c>
    8000542c:	fe440593          	addi	a1,s0,-28
    80005430:	4509                	li	a0,2
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	936080e7          	jalr	-1738(ra) # 80002d68 <argint>
    return -1;
    8000543a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000543c:	02054763          	bltz	a0,8000546a <sys_read+0x5c>
    80005440:	fd840593          	addi	a1,s0,-40
    80005444:	4505                	li	a0,1
    80005446:	ffffe097          	auipc	ra,0xffffe
    8000544a:	944080e7          	jalr	-1724(ra) # 80002d8a <argaddr>
    return -1;
    8000544e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005450:	00054d63          	bltz	a0,8000546a <sys_read+0x5c>
  return fileread(f, p, n);
    80005454:	fe442603          	lw	a2,-28(s0)
    80005458:	fd843583          	ld	a1,-40(s0)
    8000545c:	fe843503          	ld	a0,-24(s0)
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	49e080e7          	jalr	1182(ra) # 800048fe <fileread>
    80005468:	87aa                	mv	a5,a0
}
    8000546a:	853e                	mv	a0,a5
    8000546c:	70a2                	ld	ra,40(sp)
    8000546e:	7402                	ld	s0,32(sp)
    80005470:	6145                	addi	sp,sp,48
    80005472:	8082                	ret

0000000080005474 <sys_write>:
{
    80005474:	7179                	addi	sp,sp,-48
    80005476:	f406                	sd	ra,40(sp)
    80005478:	f022                	sd	s0,32(sp)
    8000547a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000547c:	fe840613          	addi	a2,s0,-24
    80005480:	4581                	li	a1,0
    80005482:	4501                	li	a0,0
    80005484:	00000097          	auipc	ra,0x0
    80005488:	d2a080e7          	jalr	-726(ra) # 800051ae <argfd>
    return -1;
    8000548c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000548e:	04054163          	bltz	a0,800054d0 <sys_write+0x5c>
    80005492:	fe440593          	addi	a1,s0,-28
    80005496:	4509                	li	a0,2
    80005498:	ffffe097          	auipc	ra,0xffffe
    8000549c:	8d0080e7          	jalr	-1840(ra) # 80002d68 <argint>
    return -1;
    800054a0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054a2:	02054763          	bltz	a0,800054d0 <sys_write+0x5c>
    800054a6:	fd840593          	addi	a1,s0,-40
    800054aa:	4505                	li	a0,1
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	8de080e7          	jalr	-1826(ra) # 80002d8a <argaddr>
    return -1;
    800054b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b6:	00054d63          	bltz	a0,800054d0 <sys_write+0x5c>
  return filewrite(f, p, n);
    800054ba:	fe442603          	lw	a2,-28(s0)
    800054be:	fd843583          	ld	a1,-40(s0)
    800054c2:	fe843503          	ld	a0,-24(s0)
    800054c6:	fffff097          	auipc	ra,0xfffff
    800054ca:	4fa080e7          	jalr	1274(ra) # 800049c0 <filewrite>
    800054ce:	87aa                	mv	a5,a0
}
    800054d0:	853e                	mv	a0,a5
    800054d2:	70a2                	ld	ra,40(sp)
    800054d4:	7402                	ld	s0,32(sp)
    800054d6:	6145                	addi	sp,sp,48
    800054d8:	8082                	ret

00000000800054da <sys_close>:
{
    800054da:	1101                	addi	sp,sp,-32
    800054dc:	ec06                	sd	ra,24(sp)
    800054de:	e822                	sd	s0,16(sp)
    800054e0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054e2:	fe040613          	addi	a2,s0,-32
    800054e6:	fec40593          	addi	a1,s0,-20
    800054ea:	4501                	li	a0,0
    800054ec:	00000097          	auipc	ra,0x0
    800054f0:	cc2080e7          	jalr	-830(ra) # 800051ae <argfd>
    return -1;
    800054f4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054f6:	02054463          	bltz	a0,8000551e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054fa:	ffffc097          	auipc	ra,0xffffc
    800054fe:	4ca080e7          	jalr	1226(ra) # 800019c4 <myproc>
    80005502:	fec42783          	lw	a5,-20(s0)
    80005506:	07e9                	addi	a5,a5,26
    80005508:	078e                	slli	a5,a5,0x3
    8000550a:	97aa                	add	a5,a5,a0
    8000550c:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005510:	fe043503          	ld	a0,-32(s0)
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	2b0080e7          	jalr	688(ra) # 800047c4 <fileclose>
  return 0;
    8000551c:	4781                	li	a5,0
}
    8000551e:	853e                	mv	a0,a5
    80005520:	60e2                	ld	ra,24(sp)
    80005522:	6442                	ld	s0,16(sp)
    80005524:	6105                	addi	sp,sp,32
    80005526:	8082                	ret

0000000080005528 <sys_fstat>:
{
    80005528:	1101                	addi	sp,sp,-32
    8000552a:	ec06                	sd	ra,24(sp)
    8000552c:	e822                	sd	s0,16(sp)
    8000552e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005530:	fe840613          	addi	a2,s0,-24
    80005534:	4581                	li	a1,0
    80005536:	4501                	li	a0,0
    80005538:	00000097          	auipc	ra,0x0
    8000553c:	c76080e7          	jalr	-906(ra) # 800051ae <argfd>
    return -1;
    80005540:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005542:	02054563          	bltz	a0,8000556c <sys_fstat+0x44>
    80005546:	fe040593          	addi	a1,s0,-32
    8000554a:	4505                	li	a0,1
    8000554c:	ffffe097          	auipc	ra,0xffffe
    80005550:	83e080e7          	jalr	-1986(ra) # 80002d8a <argaddr>
    return -1;
    80005554:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005556:	00054b63          	bltz	a0,8000556c <sys_fstat+0x44>
  return filestat(f, st);
    8000555a:	fe043583          	ld	a1,-32(s0)
    8000555e:	fe843503          	ld	a0,-24(s0)
    80005562:	fffff097          	auipc	ra,0xfffff
    80005566:	32a080e7          	jalr	810(ra) # 8000488c <filestat>
    8000556a:	87aa                	mv	a5,a0
}
    8000556c:	853e                	mv	a0,a5
    8000556e:	60e2                	ld	ra,24(sp)
    80005570:	6442                	ld	s0,16(sp)
    80005572:	6105                	addi	sp,sp,32
    80005574:	8082                	ret

0000000080005576 <sys_link>:
{
    80005576:	7169                	addi	sp,sp,-304
    80005578:	f606                	sd	ra,296(sp)
    8000557a:	f222                	sd	s0,288(sp)
    8000557c:	ee26                	sd	s1,280(sp)
    8000557e:	ea4a                	sd	s2,272(sp)
    80005580:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005582:	08000613          	li	a2,128
    80005586:	ed040593          	addi	a1,s0,-304
    8000558a:	4501                	li	a0,0
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	820080e7          	jalr	-2016(ra) # 80002dac <argstr>
    return -1;
    80005594:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005596:	10054e63          	bltz	a0,800056b2 <sys_link+0x13c>
    8000559a:	08000613          	li	a2,128
    8000559e:	f5040593          	addi	a1,s0,-176
    800055a2:	4505                	li	a0,1
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	808080e7          	jalr	-2040(ra) # 80002dac <argstr>
    return -1;
    800055ac:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ae:	10054263          	bltz	a0,800056b2 <sys_link+0x13c>
  begin_op();
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	d46080e7          	jalr	-698(ra) # 800042f8 <begin_op>
  if((ip = namei(old)) == 0){
    800055ba:	ed040513          	addi	a0,s0,-304
    800055be:	fffff097          	auipc	ra,0xfffff
    800055c2:	b1e080e7          	jalr	-1250(ra) # 800040dc <namei>
    800055c6:	84aa                	mv	s1,a0
    800055c8:	c551                	beqz	a0,80005654 <sys_link+0xde>
  ilock(ip);
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	35c080e7          	jalr	860(ra) # 80003926 <ilock>
  if(ip->type == T_DIR){
    800055d2:	04449703          	lh	a4,68(s1)
    800055d6:	4785                	li	a5,1
    800055d8:	08f70463          	beq	a4,a5,80005660 <sys_link+0xea>
  ip->nlink++;
    800055dc:	04a4d783          	lhu	a5,74(s1)
    800055e0:	2785                	addiw	a5,a5,1
    800055e2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055e6:	8526                	mv	a0,s1
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	274080e7          	jalr	628(ra) # 8000385c <iupdate>
  iunlock(ip);
    800055f0:	8526                	mv	a0,s1
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	3f6080e7          	jalr	1014(ra) # 800039e8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055fa:	fd040593          	addi	a1,s0,-48
    800055fe:	f5040513          	addi	a0,s0,-176
    80005602:	fffff097          	auipc	ra,0xfffff
    80005606:	af8080e7          	jalr	-1288(ra) # 800040fa <nameiparent>
    8000560a:	892a                	mv	s2,a0
    8000560c:	c935                	beqz	a0,80005680 <sys_link+0x10a>
  ilock(dp);
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	318080e7          	jalr	792(ra) # 80003926 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005616:	00092703          	lw	a4,0(s2)
    8000561a:	409c                	lw	a5,0(s1)
    8000561c:	04f71d63          	bne	a4,a5,80005676 <sys_link+0x100>
    80005620:	40d0                	lw	a2,4(s1)
    80005622:	fd040593          	addi	a1,s0,-48
    80005626:	854a                	mv	a0,s2
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	9f2080e7          	jalr	-1550(ra) # 8000401a <dirlink>
    80005630:	04054363          	bltz	a0,80005676 <sys_link+0x100>
  iunlockput(dp);
    80005634:	854a                	mv	a0,s2
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	552080e7          	jalr	1362(ra) # 80003b88 <iunlockput>
  iput(ip);
    8000563e:	8526                	mv	a0,s1
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	4a0080e7          	jalr	1184(ra) # 80003ae0 <iput>
  end_op();
    80005648:	fffff097          	auipc	ra,0xfffff
    8000564c:	d30080e7          	jalr	-720(ra) # 80004378 <end_op>
  return 0;
    80005650:	4781                	li	a5,0
    80005652:	a085                	j	800056b2 <sys_link+0x13c>
    end_op();
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	d24080e7          	jalr	-732(ra) # 80004378 <end_op>
    return -1;
    8000565c:	57fd                	li	a5,-1
    8000565e:	a891                	j	800056b2 <sys_link+0x13c>
    iunlockput(ip);
    80005660:	8526                	mv	a0,s1
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	526080e7          	jalr	1318(ra) # 80003b88 <iunlockput>
    end_op();
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	d0e080e7          	jalr	-754(ra) # 80004378 <end_op>
    return -1;
    80005672:	57fd                	li	a5,-1
    80005674:	a83d                	j	800056b2 <sys_link+0x13c>
    iunlockput(dp);
    80005676:	854a                	mv	a0,s2
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	510080e7          	jalr	1296(ra) # 80003b88 <iunlockput>
  ilock(ip);
    80005680:	8526                	mv	a0,s1
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	2a4080e7          	jalr	676(ra) # 80003926 <ilock>
  ip->nlink--;
    8000568a:	04a4d783          	lhu	a5,74(s1)
    8000568e:	37fd                	addiw	a5,a5,-1
    80005690:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005694:	8526                	mv	a0,s1
    80005696:	ffffe097          	auipc	ra,0xffffe
    8000569a:	1c6080e7          	jalr	454(ra) # 8000385c <iupdate>
  iunlockput(ip);
    8000569e:	8526                	mv	a0,s1
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	4e8080e7          	jalr	1256(ra) # 80003b88 <iunlockput>
  end_op();
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	cd0080e7          	jalr	-816(ra) # 80004378 <end_op>
  return -1;
    800056b0:	57fd                	li	a5,-1
}
    800056b2:	853e                	mv	a0,a5
    800056b4:	70b2                	ld	ra,296(sp)
    800056b6:	7412                	ld	s0,288(sp)
    800056b8:	64f2                	ld	s1,280(sp)
    800056ba:	6952                	ld	s2,272(sp)
    800056bc:	6155                	addi	sp,sp,304
    800056be:	8082                	ret

00000000800056c0 <sys_unlink>:
{
    800056c0:	7151                	addi	sp,sp,-240
    800056c2:	f586                	sd	ra,232(sp)
    800056c4:	f1a2                	sd	s0,224(sp)
    800056c6:	eda6                	sd	s1,216(sp)
    800056c8:	e9ca                	sd	s2,208(sp)
    800056ca:	e5ce                	sd	s3,200(sp)
    800056cc:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056ce:	08000613          	li	a2,128
    800056d2:	f3040593          	addi	a1,s0,-208
    800056d6:	4501                	li	a0,0
    800056d8:	ffffd097          	auipc	ra,0xffffd
    800056dc:	6d4080e7          	jalr	1748(ra) # 80002dac <argstr>
    800056e0:	18054163          	bltz	a0,80005862 <sys_unlink+0x1a2>
  begin_op();
    800056e4:	fffff097          	auipc	ra,0xfffff
    800056e8:	c14080e7          	jalr	-1004(ra) # 800042f8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056ec:	fb040593          	addi	a1,s0,-80
    800056f0:	f3040513          	addi	a0,s0,-208
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	a06080e7          	jalr	-1530(ra) # 800040fa <nameiparent>
    800056fc:	84aa                	mv	s1,a0
    800056fe:	c979                	beqz	a0,800057d4 <sys_unlink+0x114>
  ilock(dp);
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	226080e7          	jalr	550(ra) # 80003926 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005708:	00003597          	auipc	a1,0x3
    8000570c:	01858593          	addi	a1,a1,24 # 80008720 <syscalls+0x2c0>
    80005710:	fb040513          	addi	a0,s0,-80
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	6dc080e7          	jalr	1756(ra) # 80003df0 <namecmp>
    8000571c:	14050a63          	beqz	a0,80005870 <sys_unlink+0x1b0>
    80005720:	00003597          	auipc	a1,0x3
    80005724:	00858593          	addi	a1,a1,8 # 80008728 <syscalls+0x2c8>
    80005728:	fb040513          	addi	a0,s0,-80
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	6c4080e7          	jalr	1732(ra) # 80003df0 <namecmp>
    80005734:	12050e63          	beqz	a0,80005870 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005738:	f2c40613          	addi	a2,s0,-212
    8000573c:	fb040593          	addi	a1,s0,-80
    80005740:	8526                	mv	a0,s1
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	6c8080e7          	jalr	1736(ra) # 80003e0a <dirlookup>
    8000574a:	892a                	mv	s2,a0
    8000574c:	12050263          	beqz	a0,80005870 <sys_unlink+0x1b0>
  ilock(ip);
    80005750:	ffffe097          	auipc	ra,0xffffe
    80005754:	1d6080e7          	jalr	470(ra) # 80003926 <ilock>
  if(ip->nlink < 1)
    80005758:	04a91783          	lh	a5,74(s2)
    8000575c:	08f05263          	blez	a5,800057e0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005760:	04491703          	lh	a4,68(s2)
    80005764:	4785                	li	a5,1
    80005766:	08f70563          	beq	a4,a5,800057f0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000576a:	4641                	li	a2,16
    8000576c:	4581                	li	a1,0
    8000576e:	fc040513          	addi	a0,s0,-64
    80005772:	ffffb097          	auipc	ra,0xffffb
    80005776:	56e080e7          	jalr	1390(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000577a:	4741                	li	a4,16
    8000577c:	f2c42683          	lw	a3,-212(s0)
    80005780:	fc040613          	addi	a2,s0,-64
    80005784:	4581                	li	a1,0
    80005786:	8526                	mv	a0,s1
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	54a080e7          	jalr	1354(ra) # 80003cd2 <writei>
    80005790:	47c1                	li	a5,16
    80005792:	0af51563          	bne	a0,a5,8000583c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005796:	04491703          	lh	a4,68(s2)
    8000579a:	4785                	li	a5,1
    8000579c:	0af70863          	beq	a4,a5,8000584c <sys_unlink+0x18c>
  iunlockput(dp);
    800057a0:	8526                	mv	a0,s1
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	3e6080e7          	jalr	998(ra) # 80003b88 <iunlockput>
  ip->nlink--;
    800057aa:	04a95783          	lhu	a5,74(s2)
    800057ae:	37fd                	addiw	a5,a5,-1
    800057b0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057b4:	854a                	mv	a0,s2
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	0a6080e7          	jalr	166(ra) # 8000385c <iupdate>
  iunlockput(ip);
    800057be:	854a                	mv	a0,s2
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	3c8080e7          	jalr	968(ra) # 80003b88 <iunlockput>
  end_op();
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	bb0080e7          	jalr	-1104(ra) # 80004378 <end_op>
  return 0;
    800057d0:	4501                	li	a0,0
    800057d2:	a84d                	j	80005884 <sys_unlink+0x1c4>
    end_op();
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	ba4080e7          	jalr	-1116(ra) # 80004378 <end_op>
    return -1;
    800057dc:	557d                	li	a0,-1
    800057de:	a05d                	j	80005884 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057e0:	00003517          	auipc	a0,0x3
    800057e4:	f7050513          	addi	a0,a0,-144 # 80008750 <syscalls+0x2f0>
    800057e8:	ffffb097          	auipc	ra,0xffffb
    800057ec:	d56080e7          	jalr	-682(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057f0:	04c92703          	lw	a4,76(s2)
    800057f4:	02000793          	li	a5,32
    800057f8:	f6e7f9e3          	bgeu	a5,a4,8000576a <sys_unlink+0xaa>
    800057fc:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005800:	4741                	li	a4,16
    80005802:	86ce                	mv	a3,s3
    80005804:	f1840613          	addi	a2,s0,-232
    80005808:	4581                	li	a1,0
    8000580a:	854a                	mv	a0,s2
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	3ce080e7          	jalr	974(ra) # 80003bda <readi>
    80005814:	47c1                	li	a5,16
    80005816:	00f51b63          	bne	a0,a5,8000582c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000581a:	f1845783          	lhu	a5,-232(s0)
    8000581e:	e7a1                	bnez	a5,80005866 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005820:	29c1                	addiw	s3,s3,16
    80005822:	04c92783          	lw	a5,76(s2)
    80005826:	fcf9ede3          	bltu	s3,a5,80005800 <sys_unlink+0x140>
    8000582a:	b781                	j	8000576a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000582c:	00003517          	auipc	a0,0x3
    80005830:	f3c50513          	addi	a0,a0,-196 # 80008768 <syscalls+0x308>
    80005834:	ffffb097          	auipc	ra,0xffffb
    80005838:	d0a080e7          	jalr	-758(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000583c:	00003517          	auipc	a0,0x3
    80005840:	f4450513          	addi	a0,a0,-188 # 80008780 <syscalls+0x320>
    80005844:	ffffb097          	auipc	ra,0xffffb
    80005848:	cfa080e7          	jalr	-774(ra) # 8000053e <panic>
    dp->nlink--;
    8000584c:	04a4d783          	lhu	a5,74(s1)
    80005850:	37fd                	addiw	a5,a5,-1
    80005852:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005856:	8526                	mv	a0,s1
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	004080e7          	jalr	4(ra) # 8000385c <iupdate>
    80005860:	b781                	j	800057a0 <sys_unlink+0xe0>
    return -1;
    80005862:	557d                	li	a0,-1
    80005864:	a005                	j	80005884 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005866:	854a                	mv	a0,s2
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	320080e7          	jalr	800(ra) # 80003b88 <iunlockput>
  iunlockput(dp);
    80005870:	8526                	mv	a0,s1
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	316080e7          	jalr	790(ra) # 80003b88 <iunlockput>
  end_op();
    8000587a:	fffff097          	auipc	ra,0xfffff
    8000587e:	afe080e7          	jalr	-1282(ra) # 80004378 <end_op>
  return -1;
    80005882:	557d                	li	a0,-1
}
    80005884:	70ae                	ld	ra,232(sp)
    80005886:	740e                	ld	s0,224(sp)
    80005888:	64ee                	ld	s1,216(sp)
    8000588a:	694e                	ld	s2,208(sp)
    8000588c:	69ae                	ld	s3,200(sp)
    8000588e:	616d                	addi	sp,sp,240
    80005890:	8082                	ret

0000000080005892 <sys_open>:

uint64
sys_open(void)
{
    80005892:	7131                	addi	sp,sp,-192
    80005894:	fd06                	sd	ra,184(sp)
    80005896:	f922                	sd	s0,176(sp)
    80005898:	f526                	sd	s1,168(sp)
    8000589a:	f14a                	sd	s2,160(sp)
    8000589c:	ed4e                	sd	s3,152(sp)
    8000589e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058a0:	08000613          	li	a2,128
    800058a4:	f5040593          	addi	a1,s0,-176
    800058a8:	4501                	li	a0,0
    800058aa:	ffffd097          	auipc	ra,0xffffd
    800058ae:	502080e7          	jalr	1282(ra) # 80002dac <argstr>
    return -1;
    800058b2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058b4:	0c054163          	bltz	a0,80005976 <sys_open+0xe4>
    800058b8:	f4c40593          	addi	a1,s0,-180
    800058bc:	4505                	li	a0,1
    800058be:	ffffd097          	auipc	ra,0xffffd
    800058c2:	4aa080e7          	jalr	1194(ra) # 80002d68 <argint>
    800058c6:	0a054863          	bltz	a0,80005976 <sys_open+0xe4>

  begin_op();
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	a2e080e7          	jalr	-1490(ra) # 800042f8 <begin_op>

  if(omode & O_CREATE){
    800058d2:	f4c42783          	lw	a5,-180(s0)
    800058d6:	2007f793          	andi	a5,a5,512
    800058da:	cbdd                	beqz	a5,80005990 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058dc:	4681                	li	a3,0
    800058de:	4601                	li	a2,0
    800058e0:	4589                	li	a1,2
    800058e2:	f5040513          	addi	a0,s0,-176
    800058e6:	00000097          	auipc	ra,0x0
    800058ea:	972080e7          	jalr	-1678(ra) # 80005258 <create>
    800058ee:	892a                	mv	s2,a0
    if(ip == 0){
    800058f0:	c959                	beqz	a0,80005986 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058f2:	04491703          	lh	a4,68(s2)
    800058f6:	478d                	li	a5,3
    800058f8:	00f71763          	bne	a4,a5,80005906 <sys_open+0x74>
    800058fc:	04695703          	lhu	a4,70(s2)
    80005900:	47a5                	li	a5,9
    80005902:	0ce7ec63          	bltu	a5,a4,800059da <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	e02080e7          	jalr	-510(ra) # 80004708 <filealloc>
    8000590e:	89aa                	mv	s3,a0
    80005910:	10050263          	beqz	a0,80005a14 <sys_open+0x182>
    80005914:	00000097          	auipc	ra,0x0
    80005918:	902080e7          	jalr	-1790(ra) # 80005216 <fdalloc>
    8000591c:	84aa                	mv	s1,a0
    8000591e:	0e054663          	bltz	a0,80005a0a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005922:	04491703          	lh	a4,68(s2)
    80005926:	478d                	li	a5,3
    80005928:	0cf70463          	beq	a4,a5,800059f0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000592c:	4789                	li	a5,2
    8000592e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005932:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005936:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000593a:	f4c42783          	lw	a5,-180(s0)
    8000593e:	0017c713          	xori	a4,a5,1
    80005942:	8b05                	andi	a4,a4,1
    80005944:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005948:	0037f713          	andi	a4,a5,3
    8000594c:	00e03733          	snez	a4,a4
    80005950:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005954:	4007f793          	andi	a5,a5,1024
    80005958:	c791                	beqz	a5,80005964 <sys_open+0xd2>
    8000595a:	04491703          	lh	a4,68(s2)
    8000595e:	4789                	li	a5,2
    80005960:	08f70f63          	beq	a4,a5,800059fe <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005964:	854a                	mv	a0,s2
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	082080e7          	jalr	130(ra) # 800039e8 <iunlock>
  end_op();
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	a0a080e7          	jalr	-1526(ra) # 80004378 <end_op>

  return fd;
}
    80005976:	8526                	mv	a0,s1
    80005978:	70ea                	ld	ra,184(sp)
    8000597a:	744a                	ld	s0,176(sp)
    8000597c:	74aa                	ld	s1,168(sp)
    8000597e:	790a                	ld	s2,160(sp)
    80005980:	69ea                	ld	s3,152(sp)
    80005982:	6129                	addi	sp,sp,192
    80005984:	8082                	ret
      end_op();
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	9f2080e7          	jalr	-1550(ra) # 80004378 <end_op>
      return -1;
    8000598e:	b7e5                	j	80005976 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005990:	f5040513          	addi	a0,s0,-176
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	748080e7          	jalr	1864(ra) # 800040dc <namei>
    8000599c:	892a                	mv	s2,a0
    8000599e:	c905                	beqz	a0,800059ce <sys_open+0x13c>
    ilock(ip);
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	f86080e7          	jalr	-122(ra) # 80003926 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059a8:	04491703          	lh	a4,68(s2)
    800059ac:	4785                	li	a5,1
    800059ae:	f4f712e3          	bne	a4,a5,800058f2 <sys_open+0x60>
    800059b2:	f4c42783          	lw	a5,-180(s0)
    800059b6:	dba1                	beqz	a5,80005906 <sys_open+0x74>
      iunlockput(ip);
    800059b8:	854a                	mv	a0,s2
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	1ce080e7          	jalr	462(ra) # 80003b88 <iunlockput>
      end_op();
    800059c2:	fffff097          	auipc	ra,0xfffff
    800059c6:	9b6080e7          	jalr	-1610(ra) # 80004378 <end_op>
      return -1;
    800059ca:	54fd                	li	s1,-1
    800059cc:	b76d                	j	80005976 <sys_open+0xe4>
      end_op();
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	9aa080e7          	jalr	-1622(ra) # 80004378 <end_op>
      return -1;
    800059d6:	54fd                	li	s1,-1
    800059d8:	bf79                	j	80005976 <sys_open+0xe4>
    iunlockput(ip);
    800059da:	854a                	mv	a0,s2
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	1ac080e7          	jalr	428(ra) # 80003b88 <iunlockput>
    end_op();
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	994080e7          	jalr	-1644(ra) # 80004378 <end_op>
    return -1;
    800059ec:	54fd                	li	s1,-1
    800059ee:	b761                	j	80005976 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059f0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059f4:	04691783          	lh	a5,70(s2)
    800059f8:	02f99223          	sh	a5,36(s3)
    800059fc:	bf2d                	j	80005936 <sys_open+0xa4>
    itrunc(ip);
    800059fe:	854a                	mv	a0,s2
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	034080e7          	jalr	52(ra) # 80003a34 <itrunc>
    80005a08:	bfb1                	j	80005964 <sys_open+0xd2>
      fileclose(f);
    80005a0a:	854e                	mv	a0,s3
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	db8080e7          	jalr	-584(ra) # 800047c4 <fileclose>
    iunlockput(ip);
    80005a14:	854a                	mv	a0,s2
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	172080e7          	jalr	370(ra) # 80003b88 <iunlockput>
    end_op();
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	95a080e7          	jalr	-1702(ra) # 80004378 <end_op>
    return -1;
    80005a26:	54fd                	li	s1,-1
    80005a28:	b7b9                	j	80005976 <sys_open+0xe4>

0000000080005a2a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a2a:	7175                	addi	sp,sp,-144
    80005a2c:	e506                	sd	ra,136(sp)
    80005a2e:	e122                	sd	s0,128(sp)
    80005a30:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	8c6080e7          	jalr	-1850(ra) # 800042f8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a3a:	08000613          	li	a2,128
    80005a3e:	f7040593          	addi	a1,s0,-144
    80005a42:	4501                	li	a0,0
    80005a44:	ffffd097          	auipc	ra,0xffffd
    80005a48:	368080e7          	jalr	872(ra) # 80002dac <argstr>
    80005a4c:	02054963          	bltz	a0,80005a7e <sys_mkdir+0x54>
    80005a50:	4681                	li	a3,0
    80005a52:	4601                	li	a2,0
    80005a54:	4585                	li	a1,1
    80005a56:	f7040513          	addi	a0,s0,-144
    80005a5a:	fffff097          	auipc	ra,0xfffff
    80005a5e:	7fe080e7          	jalr	2046(ra) # 80005258 <create>
    80005a62:	cd11                	beqz	a0,80005a7e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	124080e7          	jalr	292(ra) # 80003b88 <iunlockput>
  end_op();
    80005a6c:	fffff097          	auipc	ra,0xfffff
    80005a70:	90c080e7          	jalr	-1780(ra) # 80004378 <end_op>
  return 0;
    80005a74:	4501                	li	a0,0
}
    80005a76:	60aa                	ld	ra,136(sp)
    80005a78:	640a                	ld	s0,128(sp)
    80005a7a:	6149                	addi	sp,sp,144
    80005a7c:	8082                	ret
    end_op();
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	8fa080e7          	jalr	-1798(ra) # 80004378 <end_op>
    return -1;
    80005a86:	557d                	li	a0,-1
    80005a88:	b7fd                	j	80005a76 <sys_mkdir+0x4c>

0000000080005a8a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a8a:	7135                	addi	sp,sp,-160
    80005a8c:	ed06                	sd	ra,152(sp)
    80005a8e:	e922                	sd	s0,144(sp)
    80005a90:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a92:	fffff097          	auipc	ra,0xfffff
    80005a96:	866080e7          	jalr	-1946(ra) # 800042f8 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a9a:	08000613          	li	a2,128
    80005a9e:	f7040593          	addi	a1,s0,-144
    80005aa2:	4501                	li	a0,0
    80005aa4:	ffffd097          	auipc	ra,0xffffd
    80005aa8:	308080e7          	jalr	776(ra) # 80002dac <argstr>
    80005aac:	04054a63          	bltz	a0,80005b00 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005ab0:	f6c40593          	addi	a1,s0,-148
    80005ab4:	4505                	li	a0,1
    80005ab6:	ffffd097          	auipc	ra,0xffffd
    80005aba:	2b2080e7          	jalr	690(ra) # 80002d68 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005abe:	04054163          	bltz	a0,80005b00 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ac2:	f6840593          	addi	a1,s0,-152
    80005ac6:	4509                	li	a0,2
    80005ac8:	ffffd097          	auipc	ra,0xffffd
    80005acc:	2a0080e7          	jalr	672(ra) # 80002d68 <argint>
     argint(1, &major) < 0 ||
    80005ad0:	02054863          	bltz	a0,80005b00 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ad4:	f6841683          	lh	a3,-152(s0)
    80005ad8:	f6c41603          	lh	a2,-148(s0)
    80005adc:	458d                	li	a1,3
    80005ade:	f7040513          	addi	a0,s0,-144
    80005ae2:	fffff097          	auipc	ra,0xfffff
    80005ae6:	776080e7          	jalr	1910(ra) # 80005258 <create>
     argint(2, &minor) < 0 ||
    80005aea:	c919                	beqz	a0,80005b00 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aec:	ffffe097          	auipc	ra,0xffffe
    80005af0:	09c080e7          	jalr	156(ra) # 80003b88 <iunlockput>
  end_op();
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	884080e7          	jalr	-1916(ra) # 80004378 <end_op>
  return 0;
    80005afc:	4501                	li	a0,0
    80005afe:	a031                	j	80005b0a <sys_mknod+0x80>
    end_op();
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	878080e7          	jalr	-1928(ra) # 80004378 <end_op>
    return -1;
    80005b08:	557d                	li	a0,-1
}
    80005b0a:	60ea                	ld	ra,152(sp)
    80005b0c:	644a                	ld	s0,144(sp)
    80005b0e:	610d                	addi	sp,sp,160
    80005b10:	8082                	ret

0000000080005b12 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b12:	7135                	addi	sp,sp,-160
    80005b14:	ed06                	sd	ra,152(sp)
    80005b16:	e922                	sd	s0,144(sp)
    80005b18:	e526                	sd	s1,136(sp)
    80005b1a:	e14a                	sd	s2,128(sp)
    80005b1c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b1e:	ffffc097          	auipc	ra,0xffffc
    80005b22:	ea6080e7          	jalr	-346(ra) # 800019c4 <myproc>
    80005b26:	892a                	mv	s2,a0
  
  begin_op();
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	7d0080e7          	jalr	2000(ra) # 800042f8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b30:	08000613          	li	a2,128
    80005b34:	f6040593          	addi	a1,s0,-160
    80005b38:	4501                	li	a0,0
    80005b3a:	ffffd097          	auipc	ra,0xffffd
    80005b3e:	272080e7          	jalr	626(ra) # 80002dac <argstr>
    80005b42:	04054b63          	bltz	a0,80005b98 <sys_chdir+0x86>
    80005b46:	f6040513          	addi	a0,s0,-160
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	592080e7          	jalr	1426(ra) # 800040dc <namei>
    80005b52:	84aa                	mv	s1,a0
    80005b54:	c131                	beqz	a0,80005b98 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	dd0080e7          	jalr	-560(ra) # 80003926 <ilock>
  if(ip->type != T_DIR){
    80005b5e:	04449703          	lh	a4,68(s1)
    80005b62:	4785                	li	a5,1
    80005b64:	04f71063          	bne	a4,a5,80005ba4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b68:	8526                	mv	a0,s1
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	e7e080e7          	jalr	-386(ra) # 800039e8 <iunlock>
  iput(p->cwd);
    80005b72:	15893503          	ld	a0,344(s2)
    80005b76:	ffffe097          	auipc	ra,0xffffe
    80005b7a:	f6a080e7          	jalr	-150(ra) # 80003ae0 <iput>
  end_op();
    80005b7e:	ffffe097          	auipc	ra,0xffffe
    80005b82:	7fa080e7          	jalr	2042(ra) # 80004378 <end_op>
  p->cwd = ip;
    80005b86:	14993c23          	sd	s1,344(s2)
  return 0;
    80005b8a:	4501                	li	a0,0
}
    80005b8c:	60ea                	ld	ra,152(sp)
    80005b8e:	644a                	ld	s0,144(sp)
    80005b90:	64aa                	ld	s1,136(sp)
    80005b92:	690a                	ld	s2,128(sp)
    80005b94:	610d                	addi	sp,sp,160
    80005b96:	8082                	ret
    end_op();
    80005b98:	ffffe097          	auipc	ra,0xffffe
    80005b9c:	7e0080e7          	jalr	2016(ra) # 80004378 <end_op>
    return -1;
    80005ba0:	557d                	li	a0,-1
    80005ba2:	b7ed                	j	80005b8c <sys_chdir+0x7a>
    iunlockput(ip);
    80005ba4:	8526                	mv	a0,s1
    80005ba6:	ffffe097          	auipc	ra,0xffffe
    80005baa:	fe2080e7          	jalr	-30(ra) # 80003b88 <iunlockput>
    end_op();
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	7ca080e7          	jalr	1994(ra) # 80004378 <end_op>
    return -1;
    80005bb6:	557d                	li	a0,-1
    80005bb8:	bfd1                	j	80005b8c <sys_chdir+0x7a>

0000000080005bba <sys_exec>:

uint64
sys_exec(void)
{
    80005bba:	7145                	addi	sp,sp,-464
    80005bbc:	e786                	sd	ra,456(sp)
    80005bbe:	e3a2                	sd	s0,448(sp)
    80005bc0:	ff26                	sd	s1,440(sp)
    80005bc2:	fb4a                	sd	s2,432(sp)
    80005bc4:	f74e                	sd	s3,424(sp)
    80005bc6:	f352                	sd	s4,416(sp)
    80005bc8:	ef56                	sd	s5,408(sp)
    80005bca:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bcc:	08000613          	li	a2,128
    80005bd0:	f4040593          	addi	a1,s0,-192
    80005bd4:	4501                	li	a0,0
    80005bd6:	ffffd097          	auipc	ra,0xffffd
    80005bda:	1d6080e7          	jalr	470(ra) # 80002dac <argstr>
    return -1;
    80005bde:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005be0:	0c054a63          	bltz	a0,80005cb4 <sys_exec+0xfa>
    80005be4:	e3840593          	addi	a1,s0,-456
    80005be8:	4505                	li	a0,1
    80005bea:	ffffd097          	auipc	ra,0xffffd
    80005bee:	1a0080e7          	jalr	416(ra) # 80002d8a <argaddr>
    80005bf2:	0c054163          	bltz	a0,80005cb4 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bf6:	10000613          	li	a2,256
    80005bfa:	4581                	li	a1,0
    80005bfc:	e4040513          	addi	a0,s0,-448
    80005c00:	ffffb097          	auipc	ra,0xffffb
    80005c04:	0e0080e7          	jalr	224(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c08:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c0c:	89a6                	mv	s3,s1
    80005c0e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c10:	02000a13          	li	s4,32
    80005c14:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c18:	00391513          	slli	a0,s2,0x3
    80005c1c:	e3040593          	addi	a1,s0,-464
    80005c20:	e3843783          	ld	a5,-456(s0)
    80005c24:	953e                	add	a0,a0,a5
    80005c26:	ffffd097          	auipc	ra,0xffffd
    80005c2a:	0a8080e7          	jalr	168(ra) # 80002cce <fetchaddr>
    80005c2e:	02054a63          	bltz	a0,80005c62 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c32:	e3043783          	ld	a5,-464(s0)
    80005c36:	c3b9                	beqz	a5,80005c7c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c38:	ffffb097          	auipc	ra,0xffffb
    80005c3c:	ebc080e7          	jalr	-324(ra) # 80000af4 <kalloc>
    80005c40:	85aa                	mv	a1,a0
    80005c42:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c46:	cd11                	beqz	a0,80005c62 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c48:	6605                	lui	a2,0x1
    80005c4a:	e3043503          	ld	a0,-464(s0)
    80005c4e:	ffffd097          	auipc	ra,0xffffd
    80005c52:	0d2080e7          	jalr	210(ra) # 80002d20 <fetchstr>
    80005c56:	00054663          	bltz	a0,80005c62 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c5a:	0905                	addi	s2,s2,1
    80005c5c:	09a1                	addi	s3,s3,8
    80005c5e:	fb491be3          	bne	s2,s4,80005c14 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c62:	10048913          	addi	s2,s1,256
    80005c66:	6088                	ld	a0,0(s1)
    80005c68:	c529                	beqz	a0,80005cb2 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c6a:	ffffb097          	auipc	ra,0xffffb
    80005c6e:	d8e080e7          	jalr	-626(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c72:	04a1                	addi	s1,s1,8
    80005c74:	ff2499e3          	bne	s1,s2,80005c66 <sys_exec+0xac>
  return -1;
    80005c78:	597d                	li	s2,-1
    80005c7a:	a82d                	j	80005cb4 <sys_exec+0xfa>
      argv[i] = 0;
    80005c7c:	0a8e                	slli	s5,s5,0x3
    80005c7e:	fc040793          	addi	a5,s0,-64
    80005c82:	9abe                	add	s5,s5,a5
    80005c84:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c88:	e4040593          	addi	a1,s0,-448
    80005c8c:	f4040513          	addi	a0,s0,-192
    80005c90:	fffff097          	auipc	ra,0xfffff
    80005c94:	194080e7          	jalr	404(ra) # 80004e24 <exec>
    80005c98:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c9a:	10048993          	addi	s3,s1,256
    80005c9e:	6088                	ld	a0,0(s1)
    80005ca0:	c911                	beqz	a0,80005cb4 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ca2:	ffffb097          	auipc	ra,0xffffb
    80005ca6:	d56080e7          	jalr	-682(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005caa:	04a1                	addi	s1,s1,8
    80005cac:	ff3499e3          	bne	s1,s3,80005c9e <sys_exec+0xe4>
    80005cb0:	a011                	j	80005cb4 <sys_exec+0xfa>
  return -1;
    80005cb2:	597d                	li	s2,-1
}
    80005cb4:	854a                	mv	a0,s2
    80005cb6:	60be                	ld	ra,456(sp)
    80005cb8:	641e                	ld	s0,448(sp)
    80005cba:	74fa                	ld	s1,440(sp)
    80005cbc:	795a                	ld	s2,432(sp)
    80005cbe:	79ba                	ld	s3,424(sp)
    80005cc0:	7a1a                	ld	s4,416(sp)
    80005cc2:	6afa                	ld	s5,408(sp)
    80005cc4:	6179                	addi	sp,sp,464
    80005cc6:	8082                	ret

0000000080005cc8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005cc8:	7139                	addi	sp,sp,-64
    80005cca:	fc06                	sd	ra,56(sp)
    80005ccc:	f822                	sd	s0,48(sp)
    80005cce:	f426                	sd	s1,40(sp)
    80005cd0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005cd2:	ffffc097          	auipc	ra,0xffffc
    80005cd6:	cf2080e7          	jalr	-782(ra) # 800019c4 <myproc>
    80005cda:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005cdc:	fd840593          	addi	a1,s0,-40
    80005ce0:	4501                	li	a0,0
    80005ce2:	ffffd097          	auipc	ra,0xffffd
    80005ce6:	0a8080e7          	jalr	168(ra) # 80002d8a <argaddr>
    return -1;
    80005cea:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005cec:	0e054063          	bltz	a0,80005dcc <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005cf0:	fc840593          	addi	a1,s0,-56
    80005cf4:	fd040513          	addi	a0,s0,-48
    80005cf8:	fffff097          	auipc	ra,0xfffff
    80005cfc:	dfc080e7          	jalr	-516(ra) # 80004af4 <pipealloc>
    return -1;
    80005d00:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d02:	0c054563          	bltz	a0,80005dcc <sys_pipe+0x104>
  fd0 = -1;
    80005d06:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d0a:	fd043503          	ld	a0,-48(s0)
    80005d0e:	fffff097          	auipc	ra,0xfffff
    80005d12:	508080e7          	jalr	1288(ra) # 80005216 <fdalloc>
    80005d16:	fca42223          	sw	a0,-60(s0)
    80005d1a:	08054c63          	bltz	a0,80005db2 <sys_pipe+0xea>
    80005d1e:	fc843503          	ld	a0,-56(s0)
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	4f4080e7          	jalr	1268(ra) # 80005216 <fdalloc>
    80005d2a:	fca42023          	sw	a0,-64(s0)
    80005d2e:	06054863          	bltz	a0,80005d9e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d32:	4691                	li	a3,4
    80005d34:	fc440613          	addi	a2,s0,-60
    80005d38:	fd843583          	ld	a1,-40(s0)
    80005d3c:	6ca8                	ld	a0,88(s1)
    80005d3e:	ffffc097          	auipc	ra,0xffffc
    80005d42:	93c080e7          	jalr	-1732(ra) # 8000167a <copyout>
    80005d46:	02054063          	bltz	a0,80005d66 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d4a:	4691                	li	a3,4
    80005d4c:	fc040613          	addi	a2,s0,-64
    80005d50:	fd843583          	ld	a1,-40(s0)
    80005d54:	0591                	addi	a1,a1,4
    80005d56:	6ca8                	ld	a0,88(s1)
    80005d58:	ffffc097          	auipc	ra,0xffffc
    80005d5c:	922080e7          	jalr	-1758(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d60:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d62:	06055563          	bgez	a0,80005dcc <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d66:	fc442783          	lw	a5,-60(s0)
    80005d6a:	07e9                	addi	a5,a5,26
    80005d6c:	078e                	slli	a5,a5,0x3
    80005d6e:	97a6                	add	a5,a5,s1
    80005d70:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005d74:	fc042503          	lw	a0,-64(s0)
    80005d78:	0569                	addi	a0,a0,26
    80005d7a:	050e                	slli	a0,a0,0x3
    80005d7c:	9526                	add	a0,a0,s1
    80005d7e:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005d82:	fd043503          	ld	a0,-48(s0)
    80005d86:	fffff097          	auipc	ra,0xfffff
    80005d8a:	a3e080e7          	jalr	-1474(ra) # 800047c4 <fileclose>
    fileclose(wf);
    80005d8e:	fc843503          	ld	a0,-56(s0)
    80005d92:	fffff097          	auipc	ra,0xfffff
    80005d96:	a32080e7          	jalr	-1486(ra) # 800047c4 <fileclose>
    return -1;
    80005d9a:	57fd                	li	a5,-1
    80005d9c:	a805                	j	80005dcc <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d9e:	fc442783          	lw	a5,-60(s0)
    80005da2:	0007c863          	bltz	a5,80005db2 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005da6:	01a78513          	addi	a0,a5,26
    80005daa:	050e                	slli	a0,a0,0x3
    80005dac:	9526                	add	a0,a0,s1
    80005dae:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005db2:	fd043503          	ld	a0,-48(s0)
    80005db6:	fffff097          	auipc	ra,0xfffff
    80005dba:	a0e080e7          	jalr	-1522(ra) # 800047c4 <fileclose>
    fileclose(wf);
    80005dbe:	fc843503          	ld	a0,-56(s0)
    80005dc2:	fffff097          	auipc	ra,0xfffff
    80005dc6:	a02080e7          	jalr	-1534(ra) # 800047c4 <fileclose>
    return -1;
    80005dca:	57fd                	li	a5,-1
}
    80005dcc:	853e                	mv	a0,a5
    80005dce:	70e2                	ld	ra,56(sp)
    80005dd0:	7442                	ld	s0,48(sp)
    80005dd2:	74a2                	ld	s1,40(sp)
    80005dd4:	6121                	addi	sp,sp,64
    80005dd6:	8082                	ret
	...

0000000080005de0 <kernelvec>:
    80005de0:	7111                	addi	sp,sp,-256
    80005de2:	e006                	sd	ra,0(sp)
    80005de4:	e40a                	sd	sp,8(sp)
    80005de6:	e80e                	sd	gp,16(sp)
    80005de8:	ec12                	sd	tp,24(sp)
    80005dea:	f016                	sd	t0,32(sp)
    80005dec:	f41a                	sd	t1,40(sp)
    80005dee:	f81e                	sd	t2,48(sp)
    80005df0:	fc22                	sd	s0,56(sp)
    80005df2:	e0a6                	sd	s1,64(sp)
    80005df4:	e4aa                	sd	a0,72(sp)
    80005df6:	e8ae                	sd	a1,80(sp)
    80005df8:	ecb2                	sd	a2,88(sp)
    80005dfa:	f0b6                	sd	a3,96(sp)
    80005dfc:	f4ba                	sd	a4,104(sp)
    80005dfe:	f8be                	sd	a5,112(sp)
    80005e00:	fcc2                	sd	a6,120(sp)
    80005e02:	e146                	sd	a7,128(sp)
    80005e04:	e54a                	sd	s2,136(sp)
    80005e06:	e94e                	sd	s3,144(sp)
    80005e08:	ed52                	sd	s4,152(sp)
    80005e0a:	f156                	sd	s5,160(sp)
    80005e0c:	f55a                	sd	s6,168(sp)
    80005e0e:	f95e                	sd	s7,176(sp)
    80005e10:	fd62                	sd	s8,184(sp)
    80005e12:	e1e6                	sd	s9,192(sp)
    80005e14:	e5ea                	sd	s10,200(sp)
    80005e16:	e9ee                	sd	s11,208(sp)
    80005e18:	edf2                	sd	t3,216(sp)
    80005e1a:	f1f6                	sd	t4,224(sp)
    80005e1c:	f5fa                	sd	t5,232(sp)
    80005e1e:	f9fe                	sd	t6,240(sp)
    80005e20:	d7bfc0ef          	jal	ra,80002b9a <kerneltrap>
    80005e24:	6082                	ld	ra,0(sp)
    80005e26:	6122                	ld	sp,8(sp)
    80005e28:	61c2                	ld	gp,16(sp)
    80005e2a:	7282                	ld	t0,32(sp)
    80005e2c:	7322                	ld	t1,40(sp)
    80005e2e:	73c2                	ld	t2,48(sp)
    80005e30:	7462                	ld	s0,56(sp)
    80005e32:	6486                	ld	s1,64(sp)
    80005e34:	6526                	ld	a0,72(sp)
    80005e36:	65c6                	ld	a1,80(sp)
    80005e38:	6666                	ld	a2,88(sp)
    80005e3a:	7686                	ld	a3,96(sp)
    80005e3c:	7726                	ld	a4,104(sp)
    80005e3e:	77c6                	ld	a5,112(sp)
    80005e40:	7866                	ld	a6,120(sp)
    80005e42:	688a                	ld	a7,128(sp)
    80005e44:	692a                	ld	s2,136(sp)
    80005e46:	69ca                	ld	s3,144(sp)
    80005e48:	6a6a                	ld	s4,152(sp)
    80005e4a:	7a8a                	ld	s5,160(sp)
    80005e4c:	7b2a                	ld	s6,168(sp)
    80005e4e:	7bca                	ld	s7,176(sp)
    80005e50:	7c6a                	ld	s8,184(sp)
    80005e52:	6c8e                	ld	s9,192(sp)
    80005e54:	6d2e                	ld	s10,200(sp)
    80005e56:	6dce                	ld	s11,208(sp)
    80005e58:	6e6e                	ld	t3,216(sp)
    80005e5a:	7e8e                	ld	t4,224(sp)
    80005e5c:	7f2e                	ld	t5,232(sp)
    80005e5e:	7fce                	ld	t6,240(sp)
    80005e60:	6111                	addi	sp,sp,256
    80005e62:	10200073          	sret
    80005e66:	00000013          	nop
    80005e6a:	00000013          	nop
    80005e6e:	0001                	nop

0000000080005e70 <timervec>:
    80005e70:	34051573          	csrrw	a0,mscratch,a0
    80005e74:	e10c                	sd	a1,0(a0)
    80005e76:	e510                	sd	a2,8(a0)
    80005e78:	e914                	sd	a3,16(a0)
    80005e7a:	6d0c                	ld	a1,24(a0)
    80005e7c:	7110                	ld	a2,32(a0)
    80005e7e:	6194                	ld	a3,0(a1)
    80005e80:	96b2                	add	a3,a3,a2
    80005e82:	e194                	sd	a3,0(a1)
    80005e84:	4589                	li	a1,2
    80005e86:	14459073          	csrw	sip,a1
    80005e8a:	6914                	ld	a3,16(a0)
    80005e8c:	6510                	ld	a2,8(a0)
    80005e8e:	610c                	ld	a1,0(a0)
    80005e90:	34051573          	csrrw	a0,mscratch,a0
    80005e94:	30200073          	mret
	...

0000000080005e9a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e9a:	1141                	addi	sp,sp,-16
    80005e9c:	e422                	sd	s0,8(sp)
    80005e9e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ea0:	0c0007b7          	lui	a5,0xc000
    80005ea4:	4705                	li	a4,1
    80005ea6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ea8:	c3d8                	sw	a4,4(a5)
}
    80005eaa:	6422                	ld	s0,8(sp)
    80005eac:	0141                	addi	sp,sp,16
    80005eae:	8082                	ret

0000000080005eb0 <plicinithart>:

void
plicinithart(void)
{
    80005eb0:	1141                	addi	sp,sp,-16
    80005eb2:	e406                	sd	ra,8(sp)
    80005eb4:	e022                	sd	s0,0(sp)
    80005eb6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005eb8:	ffffc097          	auipc	ra,0xffffc
    80005ebc:	ae0080e7          	jalr	-1312(ra) # 80001998 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ec0:	0085171b          	slliw	a4,a0,0x8
    80005ec4:	0c0027b7          	lui	a5,0xc002
    80005ec8:	97ba                	add	a5,a5,a4
    80005eca:	40200713          	li	a4,1026
    80005ece:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ed2:	00d5151b          	slliw	a0,a0,0xd
    80005ed6:	0c2017b7          	lui	a5,0xc201
    80005eda:	953e                	add	a0,a0,a5
    80005edc:	00052023          	sw	zero,0(a0)
}
    80005ee0:	60a2                	ld	ra,8(sp)
    80005ee2:	6402                	ld	s0,0(sp)
    80005ee4:	0141                	addi	sp,sp,16
    80005ee6:	8082                	ret

0000000080005ee8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ee8:	1141                	addi	sp,sp,-16
    80005eea:	e406                	sd	ra,8(sp)
    80005eec:	e022                	sd	s0,0(sp)
    80005eee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ef0:	ffffc097          	auipc	ra,0xffffc
    80005ef4:	aa8080e7          	jalr	-1368(ra) # 80001998 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ef8:	00d5179b          	slliw	a5,a0,0xd
    80005efc:	0c201537          	lui	a0,0xc201
    80005f00:	953e                	add	a0,a0,a5
  return irq;
}
    80005f02:	4148                	lw	a0,4(a0)
    80005f04:	60a2                	ld	ra,8(sp)
    80005f06:	6402                	ld	s0,0(sp)
    80005f08:	0141                	addi	sp,sp,16
    80005f0a:	8082                	ret

0000000080005f0c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f0c:	1101                	addi	sp,sp,-32
    80005f0e:	ec06                	sd	ra,24(sp)
    80005f10:	e822                	sd	s0,16(sp)
    80005f12:	e426                	sd	s1,8(sp)
    80005f14:	1000                	addi	s0,sp,32
    80005f16:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f18:	ffffc097          	auipc	ra,0xffffc
    80005f1c:	a80080e7          	jalr	-1408(ra) # 80001998 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f20:	00d5151b          	slliw	a0,a0,0xd
    80005f24:	0c2017b7          	lui	a5,0xc201
    80005f28:	97aa                	add	a5,a5,a0
    80005f2a:	c3c4                	sw	s1,4(a5)
}
    80005f2c:	60e2                	ld	ra,24(sp)
    80005f2e:	6442                	ld	s0,16(sp)
    80005f30:	64a2                	ld	s1,8(sp)
    80005f32:	6105                	addi	sp,sp,32
    80005f34:	8082                	ret

0000000080005f36 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f36:	1141                	addi	sp,sp,-16
    80005f38:	e406                	sd	ra,8(sp)
    80005f3a:	e022                	sd	s0,0(sp)
    80005f3c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f3e:	479d                	li	a5,7
    80005f40:	06a7c963          	blt	a5,a0,80005fb2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005f44:	0001d797          	auipc	a5,0x1d
    80005f48:	0bc78793          	addi	a5,a5,188 # 80023000 <disk>
    80005f4c:	00a78733          	add	a4,a5,a0
    80005f50:	6789                	lui	a5,0x2
    80005f52:	97ba                	add	a5,a5,a4
    80005f54:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f58:	e7ad                	bnez	a5,80005fc2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f5a:	00451793          	slli	a5,a0,0x4
    80005f5e:	0001f717          	auipc	a4,0x1f
    80005f62:	0a270713          	addi	a4,a4,162 # 80025000 <disk+0x2000>
    80005f66:	6314                	ld	a3,0(a4)
    80005f68:	96be                	add	a3,a3,a5
    80005f6a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f6e:	6314                	ld	a3,0(a4)
    80005f70:	96be                	add	a3,a3,a5
    80005f72:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f76:	6314                	ld	a3,0(a4)
    80005f78:	96be                	add	a3,a3,a5
    80005f7a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f7e:	6318                	ld	a4,0(a4)
    80005f80:	97ba                	add	a5,a5,a4
    80005f82:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f86:	0001d797          	auipc	a5,0x1d
    80005f8a:	07a78793          	addi	a5,a5,122 # 80023000 <disk>
    80005f8e:	97aa                	add	a5,a5,a0
    80005f90:	6509                	lui	a0,0x2
    80005f92:	953e                	add	a0,a0,a5
    80005f94:	4785                	li	a5,1
    80005f96:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f9a:	0001f517          	auipc	a0,0x1f
    80005f9e:	07e50513          	addi	a0,a0,126 # 80025018 <disk+0x2018>
    80005fa2:	ffffc097          	auipc	ra,0xffffc
    80005fa6:	4c2080e7          	jalr	1218(ra) # 80002464 <wakeup>
}
    80005faa:	60a2                	ld	ra,8(sp)
    80005fac:	6402                	ld	s0,0(sp)
    80005fae:	0141                	addi	sp,sp,16
    80005fb0:	8082                	ret
    panic("free_desc 1");
    80005fb2:	00002517          	auipc	a0,0x2
    80005fb6:	7de50513          	addi	a0,a0,2014 # 80008790 <syscalls+0x330>
    80005fba:	ffffa097          	auipc	ra,0xffffa
    80005fbe:	584080e7          	jalr	1412(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005fc2:	00002517          	auipc	a0,0x2
    80005fc6:	7de50513          	addi	a0,a0,2014 # 800087a0 <syscalls+0x340>
    80005fca:	ffffa097          	auipc	ra,0xffffa
    80005fce:	574080e7          	jalr	1396(ra) # 8000053e <panic>

0000000080005fd2 <virtio_disk_init>:
{
    80005fd2:	1101                	addi	sp,sp,-32
    80005fd4:	ec06                	sd	ra,24(sp)
    80005fd6:	e822                	sd	s0,16(sp)
    80005fd8:	e426                	sd	s1,8(sp)
    80005fda:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fdc:	00002597          	auipc	a1,0x2
    80005fe0:	7d458593          	addi	a1,a1,2004 # 800087b0 <syscalls+0x350>
    80005fe4:	0001f517          	auipc	a0,0x1f
    80005fe8:	14450513          	addi	a0,a0,324 # 80025128 <disk+0x2128>
    80005fec:	ffffb097          	auipc	ra,0xffffb
    80005ff0:	b68080e7          	jalr	-1176(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ff4:	100017b7          	lui	a5,0x10001
    80005ff8:	4398                	lw	a4,0(a5)
    80005ffa:	2701                	sext.w	a4,a4
    80005ffc:	747277b7          	lui	a5,0x74727
    80006000:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006004:	0ef71163          	bne	a4,a5,800060e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006008:	100017b7          	lui	a5,0x10001
    8000600c:	43dc                	lw	a5,4(a5)
    8000600e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006010:	4705                	li	a4,1
    80006012:	0ce79a63          	bne	a5,a4,800060e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006016:	100017b7          	lui	a5,0x10001
    8000601a:	479c                	lw	a5,8(a5)
    8000601c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000601e:	4709                	li	a4,2
    80006020:	0ce79363          	bne	a5,a4,800060e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006024:	100017b7          	lui	a5,0x10001
    80006028:	47d8                	lw	a4,12(a5)
    8000602a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000602c:	554d47b7          	lui	a5,0x554d4
    80006030:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006034:	0af71963          	bne	a4,a5,800060e6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006038:	100017b7          	lui	a5,0x10001
    8000603c:	4705                	li	a4,1
    8000603e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006040:	470d                	li	a4,3
    80006042:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006044:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006046:	c7ffe737          	lui	a4,0xc7ffe
    8000604a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000604e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006050:	2701                	sext.w	a4,a4
    80006052:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006054:	472d                	li	a4,11
    80006056:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006058:	473d                	li	a4,15
    8000605a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000605c:	6705                	lui	a4,0x1
    8000605e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006060:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006064:	5bdc                	lw	a5,52(a5)
    80006066:	2781                	sext.w	a5,a5
  if(max == 0)
    80006068:	c7d9                	beqz	a5,800060f6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000606a:	471d                	li	a4,7
    8000606c:	08f77d63          	bgeu	a4,a5,80006106 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006070:	100014b7          	lui	s1,0x10001
    80006074:	47a1                	li	a5,8
    80006076:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006078:	6609                	lui	a2,0x2
    8000607a:	4581                	li	a1,0
    8000607c:	0001d517          	auipc	a0,0x1d
    80006080:	f8450513          	addi	a0,a0,-124 # 80023000 <disk>
    80006084:	ffffb097          	auipc	ra,0xffffb
    80006088:	c5c080e7          	jalr	-932(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000608c:	0001d717          	auipc	a4,0x1d
    80006090:	f7470713          	addi	a4,a4,-140 # 80023000 <disk>
    80006094:	00c75793          	srli	a5,a4,0xc
    80006098:	2781                	sext.w	a5,a5
    8000609a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000609c:	0001f797          	auipc	a5,0x1f
    800060a0:	f6478793          	addi	a5,a5,-156 # 80025000 <disk+0x2000>
    800060a4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800060a6:	0001d717          	auipc	a4,0x1d
    800060aa:	fda70713          	addi	a4,a4,-38 # 80023080 <disk+0x80>
    800060ae:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800060b0:	0001e717          	auipc	a4,0x1e
    800060b4:	f5070713          	addi	a4,a4,-176 # 80024000 <disk+0x1000>
    800060b8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060ba:	4705                	li	a4,1
    800060bc:	00e78c23          	sb	a4,24(a5)
    800060c0:	00e78ca3          	sb	a4,25(a5)
    800060c4:	00e78d23          	sb	a4,26(a5)
    800060c8:	00e78da3          	sb	a4,27(a5)
    800060cc:	00e78e23          	sb	a4,28(a5)
    800060d0:	00e78ea3          	sb	a4,29(a5)
    800060d4:	00e78f23          	sb	a4,30(a5)
    800060d8:	00e78fa3          	sb	a4,31(a5)
}
    800060dc:	60e2                	ld	ra,24(sp)
    800060de:	6442                	ld	s0,16(sp)
    800060e0:	64a2                	ld	s1,8(sp)
    800060e2:	6105                	addi	sp,sp,32
    800060e4:	8082                	ret
    panic("could not find virtio disk");
    800060e6:	00002517          	auipc	a0,0x2
    800060ea:	6da50513          	addi	a0,a0,1754 # 800087c0 <syscalls+0x360>
    800060ee:	ffffa097          	auipc	ra,0xffffa
    800060f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800060f6:	00002517          	auipc	a0,0x2
    800060fa:	6ea50513          	addi	a0,a0,1770 # 800087e0 <syscalls+0x380>
    800060fe:	ffffa097          	auipc	ra,0xffffa
    80006102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006106:	00002517          	auipc	a0,0x2
    8000610a:	6fa50513          	addi	a0,a0,1786 # 80008800 <syscalls+0x3a0>
    8000610e:	ffffa097          	auipc	ra,0xffffa
    80006112:	430080e7          	jalr	1072(ra) # 8000053e <panic>

0000000080006116 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006116:	7159                	addi	sp,sp,-112
    80006118:	f486                	sd	ra,104(sp)
    8000611a:	f0a2                	sd	s0,96(sp)
    8000611c:	eca6                	sd	s1,88(sp)
    8000611e:	e8ca                	sd	s2,80(sp)
    80006120:	e4ce                	sd	s3,72(sp)
    80006122:	e0d2                	sd	s4,64(sp)
    80006124:	fc56                	sd	s5,56(sp)
    80006126:	f85a                	sd	s6,48(sp)
    80006128:	f45e                	sd	s7,40(sp)
    8000612a:	f062                	sd	s8,32(sp)
    8000612c:	ec66                	sd	s9,24(sp)
    8000612e:	e86a                	sd	s10,16(sp)
    80006130:	1880                	addi	s0,sp,112
    80006132:	892a                	mv	s2,a0
    80006134:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006136:	00c52c83          	lw	s9,12(a0)
    8000613a:	001c9c9b          	slliw	s9,s9,0x1
    8000613e:	1c82                	slli	s9,s9,0x20
    80006140:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006144:	0001f517          	auipc	a0,0x1f
    80006148:	fe450513          	addi	a0,a0,-28 # 80025128 <disk+0x2128>
    8000614c:	ffffb097          	auipc	ra,0xffffb
    80006150:	a98080e7          	jalr	-1384(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006154:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006156:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006158:	0001db97          	auipc	s7,0x1d
    8000615c:	ea8b8b93          	addi	s7,s7,-344 # 80023000 <disk>
    80006160:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006162:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006164:	8a4e                	mv	s4,s3
    80006166:	a051                	j	800061ea <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006168:	00fb86b3          	add	a3,s7,a5
    8000616c:	96da                	add	a3,a3,s6
    8000616e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006172:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006174:	0207c563          	bltz	a5,8000619e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006178:	2485                	addiw	s1,s1,1
    8000617a:	0711                	addi	a4,a4,4
    8000617c:	25548063          	beq	s1,s5,800063bc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006180:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006182:	0001f697          	auipc	a3,0x1f
    80006186:	e9668693          	addi	a3,a3,-362 # 80025018 <disk+0x2018>
    8000618a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000618c:	0006c583          	lbu	a1,0(a3)
    80006190:	fde1                	bnez	a1,80006168 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006192:	2785                	addiw	a5,a5,1
    80006194:	0685                	addi	a3,a3,1
    80006196:	ff879be3          	bne	a5,s8,8000618c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000619a:	57fd                	li	a5,-1
    8000619c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000619e:	02905a63          	blez	s1,800061d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061a2:	f9042503          	lw	a0,-112(s0)
    800061a6:	00000097          	auipc	ra,0x0
    800061aa:	d90080e7          	jalr	-624(ra) # 80005f36 <free_desc>
      for(int j = 0; j < i; j++)
    800061ae:	4785                	li	a5,1
    800061b0:	0297d163          	bge	a5,s1,800061d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061b4:	f9442503          	lw	a0,-108(s0)
    800061b8:	00000097          	auipc	ra,0x0
    800061bc:	d7e080e7          	jalr	-642(ra) # 80005f36 <free_desc>
      for(int j = 0; j < i; j++)
    800061c0:	4789                	li	a5,2
    800061c2:	0097d863          	bge	a5,s1,800061d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061c6:	f9842503          	lw	a0,-104(s0)
    800061ca:	00000097          	auipc	ra,0x0
    800061ce:	d6c080e7          	jalr	-660(ra) # 80005f36 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061d2:	0001f597          	auipc	a1,0x1f
    800061d6:	f5658593          	addi	a1,a1,-170 # 80025128 <disk+0x2128>
    800061da:	0001f517          	auipc	a0,0x1f
    800061de:	e3e50513          	addi	a0,a0,-450 # 80025018 <disk+0x2018>
    800061e2:	ffffc097          	auipc	ra,0xffffc
    800061e6:	0f6080e7          	jalr	246(ra) # 800022d8 <sleep>
  for(int i = 0; i < 3; i++){
    800061ea:	f9040713          	addi	a4,s0,-112
    800061ee:	84ce                	mv	s1,s3
    800061f0:	bf41                	j	80006180 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800061f2:	20058713          	addi	a4,a1,512
    800061f6:	00471693          	slli	a3,a4,0x4
    800061fa:	0001d717          	auipc	a4,0x1d
    800061fe:	e0670713          	addi	a4,a4,-506 # 80023000 <disk>
    80006202:	9736                	add	a4,a4,a3
    80006204:	4685                	li	a3,1
    80006206:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000620a:	20058713          	addi	a4,a1,512
    8000620e:	00471693          	slli	a3,a4,0x4
    80006212:	0001d717          	auipc	a4,0x1d
    80006216:	dee70713          	addi	a4,a4,-530 # 80023000 <disk>
    8000621a:	9736                	add	a4,a4,a3
    8000621c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006220:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006224:	7679                	lui	a2,0xffffe
    80006226:	963e                	add	a2,a2,a5
    80006228:	0001f697          	auipc	a3,0x1f
    8000622c:	dd868693          	addi	a3,a3,-552 # 80025000 <disk+0x2000>
    80006230:	6298                	ld	a4,0(a3)
    80006232:	9732                	add	a4,a4,a2
    80006234:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006236:	6298                	ld	a4,0(a3)
    80006238:	9732                	add	a4,a4,a2
    8000623a:	4541                	li	a0,16
    8000623c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000623e:	6298                	ld	a4,0(a3)
    80006240:	9732                	add	a4,a4,a2
    80006242:	4505                	li	a0,1
    80006244:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006248:	f9442703          	lw	a4,-108(s0)
    8000624c:	6288                	ld	a0,0(a3)
    8000624e:	962a                	add	a2,a2,a0
    80006250:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006254:	0712                	slli	a4,a4,0x4
    80006256:	6290                	ld	a2,0(a3)
    80006258:	963a                	add	a2,a2,a4
    8000625a:	05890513          	addi	a0,s2,88
    8000625e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006260:	6294                	ld	a3,0(a3)
    80006262:	96ba                	add	a3,a3,a4
    80006264:	40000613          	li	a2,1024
    80006268:	c690                	sw	a2,8(a3)
  if(write)
    8000626a:	140d0063          	beqz	s10,800063aa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000626e:	0001f697          	auipc	a3,0x1f
    80006272:	d926b683          	ld	a3,-622(a3) # 80025000 <disk+0x2000>
    80006276:	96ba                	add	a3,a3,a4
    80006278:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000627c:	0001d817          	auipc	a6,0x1d
    80006280:	d8480813          	addi	a6,a6,-636 # 80023000 <disk>
    80006284:	0001f517          	auipc	a0,0x1f
    80006288:	d7c50513          	addi	a0,a0,-644 # 80025000 <disk+0x2000>
    8000628c:	6114                	ld	a3,0(a0)
    8000628e:	96ba                	add	a3,a3,a4
    80006290:	00c6d603          	lhu	a2,12(a3)
    80006294:	00166613          	ori	a2,a2,1
    80006298:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000629c:	f9842683          	lw	a3,-104(s0)
    800062a0:	6110                	ld	a2,0(a0)
    800062a2:	9732                	add	a4,a4,a2
    800062a4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062a8:	20058613          	addi	a2,a1,512
    800062ac:	0612                	slli	a2,a2,0x4
    800062ae:	9642                	add	a2,a2,a6
    800062b0:	577d                	li	a4,-1
    800062b2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062b6:	00469713          	slli	a4,a3,0x4
    800062ba:	6114                	ld	a3,0(a0)
    800062bc:	96ba                	add	a3,a3,a4
    800062be:	03078793          	addi	a5,a5,48
    800062c2:	97c2                	add	a5,a5,a6
    800062c4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800062c6:	611c                	ld	a5,0(a0)
    800062c8:	97ba                	add	a5,a5,a4
    800062ca:	4685                	li	a3,1
    800062cc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062ce:	611c                	ld	a5,0(a0)
    800062d0:	97ba                	add	a5,a5,a4
    800062d2:	4809                	li	a6,2
    800062d4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800062d8:	611c                	ld	a5,0(a0)
    800062da:	973e                	add	a4,a4,a5
    800062dc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062e0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800062e4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062e8:	6518                	ld	a4,8(a0)
    800062ea:	00275783          	lhu	a5,2(a4)
    800062ee:	8b9d                	andi	a5,a5,7
    800062f0:	0786                	slli	a5,a5,0x1
    800062f2:	97ba                	add	a5,a5,a4
    800062f4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800062f8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062fc:	6518                	ld	a4,8(a0)
    800062fe:	00275783          	lhu	a5,2(a4)
    80006302:	2785                	addiw	a5,a5,1
    80006304:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006308:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000630c:	100017b7          	lui	a5,0x10001
    80006310:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006314:	00492703          	lw	a4,4(s2)
    80006318:	4785                	li	a5,1
    8000631a:	02f71163          	bne	a4,a5,8000633c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000631e:	0001f997          	auipc	s3,0x1f
    80006322:	e0a98993          	addi	s3,s3,-502 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006326:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006328:	85ce                	mv	a1,s3
    8000632a:	854a                	mv	a0,s2
    8000632c:	ffffc097          	auipc	ra,0xffffc
    80006330:	fac080e7          	jalr	-84(ra) # 800022d8 <sleep>
  while(b->disk == 1) {
    80006334:	00492783          	lw	a5,4(s2)
    80006338:	fe9788e3          	beq	a5,s1,80006328 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000633c:	f9042903          	lw	s2,-112(s0)
    80006340:	20090793          	addi	a5,s2,512
    80006344:	00479713          	slli	a4,a5,0x4
    80006348:	0001d797          	auipc	a5,0x1d
    8000634c:	cb878793          	addi	a5,a5,-840 # 80023000 <disk>
    80006350:	97ba                	add	a5,a5,a4
    80006352:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006356:	0001f997          	auipc	s3,0x1f
    8000635a:	caa98993          	addi	s3,s3,-854 # 80025000 <disk+0x2000>
    8000635e:	00491713          	slli	a4,s2,0x4
    80006362:	0009b783          	ld	a5,0(s3)
    80006366:	97ba                	add	a5,a5,a4
    80006368:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000636c:	854a                	mv	a0,s2
    8000636e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006372:	00000097          	auipc	ra,0x0
    80006376:	bc4080e7          	jalr	-1084(ra) # 80005f36 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000637a:	8885                	andi	s1,s1,1
    8000637c:	f0ed                	bnez	s1,8000635e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000637e:	0001f517          	auipc	a0,0x1f
    80006382:	daa50513          	addi	a0,a0,-598 # 80025128 <disk+0x2128>
    80006386:	ffffb097          	auipc	ra,0xffffb
    8000638a:	912080e7          	jalr	-1774(ra) # 80000c98 <release>
}
    8000638e:	70a6                	ld	ra,104(sp)
    80006390:	7406                	ld	s0,96(sp)
    80006392:	64e6                	ld	s1,88(sp)
    80006394:	6946                	ld	s2,80(sp)
    80006396:	69a6                	ld	s3,72(sp)
    80006398:	6a06                	ld	s4,64(sp)
    8000639a:	7ae2                	ld	s5,56(sp)
    8000639c:	7b42                	ld	s6,48(sp)
    8000639e:	7ba2                	ld	s7,40(sp)
    800063a0:	7c02                	ld	s8,32(sp)
    800063a2:	6ce2                	ld	s9,24(sp)
    800063a4:	6d42                	ld	s10,16(sp)
    800063a6:	6165                	addi	sp,sp,112
    800063a8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063aa:	0001f697          	auipc	a3,0x1f
    800063ae:	c566b683          	ld	a3,-938(a3) # 80025000 <disk+0x2000>
    800063b2:	96ba                	add	a3,a3,a4
    800063b4:	4609                	li	a2,2
    800063b6:	00c69623          	sh	a2,12(a3)
    800063ba:	b5c9                	j	8000627c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063bc:	f9042583          	lw	a1,-112(s0)
    800063c0:	20058793          	addi	a5,a1,512
    800063c4:	0792                	slli	a5,a5,0x4
    800063c6:	0001d517          	auipc	a0,0x1d
    800063ca:	ce250513          	addi	a0,a0,-798 # 800230a8 <disk+0xa8>
    800063ce:	953e                	add	a0,a0,a5
  if(write)
    800063d0:	e20d11e3          	bnez	s10,800061f2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800063d4:	20058713          	addi	a4,a1,512
    800063d8:	00471693          	slli	a3,a4,0x4
    800063dc:	0001d717          	auipc	a4,0x1d
    800063e0:	c2470713          	addi	a4,a4,-988 # 80023000 <disk>
    800063e4:	9736                	add	a4,a4,a3
    800063e6:	0a072423          	sw	zero,168(a4)
    800063ea:	b505                	j	8000620a <virtio_disk_rw+0xf4>

00000000800063ec <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063ec:	1101                	addi	sp,sp,-32
    800063ee:	ec06                	sd	ra,24(sp)
    800063f0:	e822                	sd	s0,16(sp)
    800063f2:	e426                	sd	s1,8(sp)
    800063f4:	e04a                	sd	s2,0(sp)
    800063f6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063f8:	0001f517          	auipc	a0,0x1f
    800063fc:	d3050513          	addi	a0,a0,-720 # 80025128 <disk+0x2128>
    80006400:	ffffa097          	auipc	ra,0xffffa
    80006404:	7e4080e7          	jalr	2020(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006408:	10001737          	lui	a4,0x10001
    8000640c:	533c                	lw	a5,96(a4)
    8000640e:	8b8d                	andi	a5,a5,3
    80006410:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006412:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006416:	0001f797          	auipc	a5,0x1f
    8000641a:	bea78793          	addi	a5,a5,-1046 # 80025000 <disk+0x2000>
    8000641e:	6b94                	ld	a3,16(a5)
    80006420:	0207d703          	lhu	a4,32(a5)
    80006424:	0026d783          	lhu	a5,2(a3)
    80006428:	06f70163          	beq	a4,a5,8000648a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000642c:	0001d917          	auipc	s2,0x1d
    80006430:	bd490913          	addi	s2,s2,-1068 # 80023000 <disk>
    80006434:	0001f497          	auipc	s1,0x1f
    80006438:	bcc48493          	addi	s1,s1,-1076 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000643c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006440:	6898                	ld	a4,16(s1)
    80006442:	0204d783          	lhu	a5,32(s1)
    80006446:	8b9d                	andi	a5,a5,7
    80006448:	078e                	slli	a5,a5,0x3
    8000644a:	97ba                	add	a5,a5,a4
    8000644c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000644e:	20078713          	addi	a4,a5,512
    80006452:	0712                	slli	a4,a4,0x4
    80006454:	974a                	add	a4,a4,s2
    80006456:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000645a:	e731                	bnez	a4,800064a6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000645c:	20078793          	addi	a5,a5,512
    80006460:	0792                	slli	a5,a5,0x4
    80006462:	97ca                	add	a5,a5,s2
    80006464:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006466:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000646a:	ffffc097          	auipc	ra,0xffffc
    8000646e:	ffa080e7          	jalr	-6(ra) # 80002464 <wakeup>

    disk.used_idx += 1;
    80006472:	0204d783          	lhu	a5,32(s1)
    80006476:	2785                	addiw	a5,a5,1
    80006478:	17c2                	slli	a5,a5,0x30
    8000647a:	93c1                	srli	a5,a5,0x30
    8000647c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006480:	6898                	ld	a4,16(s1)
    80006482:	00275703          	lhu	a4,2(a4)
    80006486:	faf71be3          	bne	a4,a5,8000643c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000648a:	0001f517          	auipc	a0,0x1f
    8000648e:	c9e50513          	addi	a0,a0,-866 # 80025128 <disk+0x2128>
    80006492:	ffffb097          	auipc	ra,0xffffb
    80006496:	806080e7          	jalr	-2042(ra) # 80000c98 <release>
}
    8000649a:	60e2                	ld	ra,24(sp)
    8000649c:	6442                	ld	s0,16(sp)
    8000649e:	64a2                	ld	s1,8(sp)
    800064a0:	6902                	ld	s2,0(sp)
    800064a2:	6105                	addi	sp,sp,32
    800064a4:	8082                	ret
      panic("virtio_disk_intr status");
    800064a6:	00002517          	auipc	a0,0x2
    800064aa:	37a50513          	addi	a0,a0,890 # 80008820 <syscalls+0x3c0>
    800064ae:	ffffa097          	auipc	ra,0xffffa
    800064b2:	090080e7          	jalr	144(ra) # 8000053e <panic>
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
