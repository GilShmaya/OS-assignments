
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	c4013103          	ld	sp,-960(sp) # 80008c40 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	66c78793          	addi	a5,a5,1644 # 800066d0 <timervec>
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
    80000130:	730080e7          	jalr	1840(ra) # 8000285c <either_copyin>
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
    800001c8:	d8a080e7          	jalr	-630(ra) # 80001f4e <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	3b4080e7          	jalr	948(ra) # 80002588 <sleep>
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
    80000214:	5f6080e7          	jalr	1526(ra) # 80002806 <either_copyout>
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
    800002f6:	5c0080e7          	jalr	1472(ra) # 800028b2 <procdump>
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
    8000044a:	7c8080e7          	jalr	1992(ra) # 80002c0e <wakeup>
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
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	a2078793          	addi	a5,a5,-1504 # 80021e98 <devsw>
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
    80000570:	08450513          	addi	a0,a0,132 # 800085f0 <digits+0x5b0>
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
    800008a4:	36e080e7          	jalr	878(ra) # 80002c0e <wakeup>
    
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
    80000930:	c5c080e7          	jalr	-932(ra) # 80002588 <sleep>
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
    80000b82:	3ae080e7          	jalr	942(ra) # 80001f2c <mycpu>
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
    80000bb4:	37c080e7          	jalr	892(ra) # 80001f2c <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	370080e7          	jalr	880(ra) # 80001f2c <mycpu>
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
    80000bd8:	358080e7          	jalr	856(ra) # 80001f2c <mycpu>
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
    80000c18:	318080e7          	jalr	792(ra) # 80001f2c <mycpu>
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
    80000c44:	2ec080e7          	jalr	748(ra) # 80001f2c <mycpu>
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
    80000e9a:	086080e7          	jalr	134(ra) # 80001f1c <cpuid>
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
    80000eb6:	06a080e7          	jalr	106(ra) # 80001f1c <cpuid>
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
    80000ed8:	25e080e7          	jalr	606(ra) # 80003132 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00006097          	auipc	ra,0x6
    80000ee0:	834080e7          	jalr	-1996(ra) # 80006710 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	0c4080e7          	jalr	196(ra) # 80002fa8 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	6f450513          	addi	a0,a0,1780 # 800085f0 <digits+0x5b0>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	6d450513          	addi	a0,a0,1748 # 800085f0 <digits+0x5b0>
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
    80000f48:	ec4080e7          	jalr	-316(ra) # 80001e08 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	1be080e7          	jalr	446(ra) # 8000310a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	1de080e7          	jalr	478(ra) # 80003132 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	79e080e7          	jalr	1950(ra) # 800066fa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	7ac080e7          	jalr	1964(ra) # 80006710 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00003097          	auipc	ra,0x3
    80000f70:	984080e7          	jalr	-1660(ra) # 800038f0 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	014080e7          	jalr	20(ra) # 80003f88 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	fbe080e7          	jalr	-66(ra) # 80004f3a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00006097          	auipc	ra,0x6
    80000f88:	8ae080e7          	jalr	-1874(ra) # 80006832 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	38a080e7          	jalr	906(ra) # 80002316 <userinit>
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
    80001244:	b32080e7          	jalr	-1230(ra) # 80001d72 <proc_mapstacks>
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
struct _list unused_list = {-1};   // contains all UNUSED process entries.
struct _list sleeping_list = {-1}; // contains all SLEEPING processes.
struct _list zombie_list = {-1};   // contains all ZOMBIE processes.

void
print_list(struct _list lst){
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	0080                	addi	s0,sp,64
  int curr = lst.head;
    80001850:	4104                	lw	s1,0(a0)
  printf("\n[ ");
    80001852:	00007517          	auipc	a0,0x7
    80001856:	98650513          	addi	a0,a0,-1658 # 800081d8 <digits+0x198>
    8000185a:	fffff097          	auipc	ra,0xfffff
    8000185e:	d2e080e7          	jalr	-722(ra) # 80000588 <printf>
  while(curr != -1){
    80001862:	57fd                	li	a5,-1
    80001864:	02f48a63          	beq	s1,a5,80001898 <print_list+0x5a>
    printf(" %d,", curr);
    80001868:	00007a97          	auipc	s5,0x7
    8000186c:	978a8a93          	addi	s5,s5,-1672 # 800081e0 <digits+0x1a0>
    curr = proc[curr].next_index;
    80001870:	00010a17          	auipc	s4,0x10
    80001874:	fe0a0a13          	addi	s4,s4,-32 # 80011850 <proc>
    80001878:	19000993          	li	s3,400
  while(curr != -1){
    8000187c:	597d                	li	s2,-1
    printf(" %d,", curr);
    8000187e:	85a6                	mv	a1,s1
    80001880:	8556                	mv	a0,s5
    80001882:	fffff097          	auipc	ra,0xfffff
    80001886:	d06080e7          	jalr	-762(ra) # 80000588 <printf>
    curr = proc[curr].next_index;
    8000188a:	033484b3          	mul	s1,s1,s3
    8000188e:	94d2                	add	s1,s1,s4
    80001890:	1744a483          	lw	s1,372(s1)
  while(curr != -1){
    80001894:	ff2495e3          	bne	s1,s2,8000187e <print_list+0x40>
  }
  printf(" ]\n");
    80001898:	00007517          	auipc	a0,0x7
    8000189c:	95050513          	addi	a0,a0,-1712 # 800081e8 <digits+0x1a8>
    800018a0:	fffff097          	auipc	ra,0xfffff
    800018a4:	ce8080e7          	jalr	-792(ra) # 80000588 <printf>
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6121                	addi	sp,sp,64
    800018b8:	8082                	ret

00000000800018ba <initialize_list>:


void initialize_list(struct _list *lst){
    800018ba:	1101                	addi	sp,sp,-32
    800018bc:	ec06                	sd	ra,24(sp)
    800018be:	e822                	sd	s0,16(sp)
    800018c0:	e426                	sd	s1,8(sp)
    800018c2:	e04a                	sd	s2,0(sp)
    800018c4:	1000                	addi	s0,sp,32
    800018c6:	84aa                	mv	s1,a0
  acquire(&lst->head_lock);
    800018c8:	00850913          	addi	s2,a0,8
    800018cc:	854a                	mv	a0,s2
    800018ce:	fffff097          	auipc	ra,0xfffff
    800018d2:	316080e7          	jalr	790(ra) # 80000be4 <acquire>
  lst->head = -1;
    800018d6:	57fd                	li	a5,-1
    800018d8:	c09c                	sw	a5,0(s1)
  acquire(&lst->head_lock);
    800018da:	854a                	mv	a0,s2
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	308080e7          	jalr	776(ra) # 80000be4 <acquire>
}
    800018e4:	60e2                	ld	ra,24(sp)
    800018e6:	6442                	ld	s0,16(sp)
    800018e8:	64a2                	ld	s1,8(sp)
    800018ea:	6902                	ld	s2,0(sp)
    800018ec:	6105                	addi	sp,sp,32
    800018ee:	8082                	ret

00000000800018f0 <initialize_lists>:

void initialize_lists(void){
    800018f0:	1101                	addi	sp,sp,-32
    800018f2:	ec06                	sd	ra,24(sp)
    800018f4:	e822                	sd	s0,16(sp)
    800018f6:	e426                	sd	s1,8(sp)
    800018f8:	e04a                	sd	s2,0(sp)
    800018fa:	1000                	addi	s0,sp,32
  struct cpu *c;
  int i = 0;
  for(c = cpus; c < &cpus[NCPU] && i < CPUS ; c++){
    c->runnable_list = (struct _list){-1};
    800018fc:	00010497          	auipc	s1,0x10
    80001900:	9a448493          	addi	s1,s1,-1628 # 800112a0 <cpus>
    80001904:	0804b023          	sd	zero,128(s1)
    80001908:	0804b423          	sd	zero,136(s1)
    8000190c:	0804b823          	sd	zero,144(s1)
    80001910:	0804bc23          	sd	zero,152(s1)
    80001914:	597d                	li	s2,-1
    80001916:	0924a023          	sw	s2,128(s1)
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list - head lock");
    8000191a:	00007597          	auipc	a1,0x7
    8000191e:	8d658593          	addi	a1,a1,-1834 # 800081f0 <digits+0x1b0>
    80001922:	00010517          	auipc	a0,0x10
    80001926:	a0650513          	addi	a0,a0,-1530 # 80011328 <cpus+0x88>
    8000192a:	fffff097          	auipc	ra,0xfffff
    8000192e:	22a080e7          	jalr	554(ra) # 80000b54 <initlock>
    c->cpu_id = i;
    80001932:	0a04a023          	sw	zero,160(s1)
    c->runnable_list = (struct _list){-1};
    80001936:	1204b823          	sd	zero,304(s1)
    8000193a:	1204bc23          	sd	zero,312(s1)
    8000193e:	1404b023          	sd	zero,320(s1)
    80001942:	1404b423          	sd	zero,328(s1)
    80001946:	1324a823          	sw	s2,304(s1)
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list - head lock");
    8000194a:	00007597          	auipc	a1,0x7
    8000194e:	8a658593          	addi	a1,a1,-1882 # 800081f0 <digits+0x1b0>
    80001952:	00010517          	auipc	a0,0x10
    80001956:	a8650513          	addi	a0,a0,-1402 # 800113d8 <cpus+0x138>
    8000195a:	fffff097          	auipc	ra,0xfffff
    8000195e:	1fa080e7          	jalr	506(ra) # 80000b54 <initlock>
    c->cpu_id = i;
    80001962:	4785                	li	a5,1
    80001964:	14f4a823          	sw	a5,336(s1)
    c->runnable_list = (struct _list){-1};
    80001968:	1e04b023          	sd	zero,480(s1)
    8000196c:	1e04b423          	sd	zero,488(s1)
    80001970:	1e04b823          	sd	zero,496(s1)
    80001974:	1e04bc23          	sd	zero,504(s1)
    80001978:	1f24a023          	sw	s2,480(s1)
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list - head lock");
    8000197c:	00007597          	auipc	a1,0x7
    80001980:	87458593          	addi	a1,a1,-1932 # 800081f0 <digits+0x1b0>
    80001984:	00010517          	auipc	a0,0x10
    80001988:	b0450513          	addi	a0,a0,-1276 # 80011488 <cpus+0x1e8>
    8000198c:	fffff097          	auipc	ra,0xfffff
    80001990:	1c8080e7          	jalr	456(ra) # 80000b54 <initlock>
    c->cpu_id = i;
    80001994:	4789                	li	a5,2
    80001996:	20f4a023          	sw	a5,512(s1)
    i++;
  }
  initlock(&unused_list.head_lock, "unused_list - head lock");
    8000199a:	00007597          	auipc	a1,0x7
    8000199e:	87658593          	addi	a1,a1,-1930 # 80008210 <digits+0x1d0>
    800019a2:	00007517          	auipc	a0,0x7
    800019a6:	20650513          	addi	a0,a0,518 # 80008ba8 <unused_list+0x8>
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	1aa080e7          	jalr	426(ra) # 80000b54 <initlock>
  initlock(&sleeping_list.head_lock, "sleeping_list - head lock");
    800019b2:	00007597          	auipc	a1,0x7
    800019b6:	87658593          	addi	a1,a1,-1930 # 80008228 <digits+0x1e8>
    800019ba:	00007517          	auipc	a0,0x7
    800019be:	20e50513          	addi	a0,a0,526 # 80008bc8 <sleeping_list+0x8>
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	192080e7          	jalr	402(ra) # 80000b54 <initlock>
  initlock(&zombie_list.head_lock, "zombie_list - head lock");
    800019ca:	00007597          	auipc	a1,0x7
    800019ce:	87e58593          	addi	a1,a1,-1922 # 80008248 <digits+0x208>
    800019d2:	00007517          	auipc	a0,0x7
    800019d6:	21650513          	addi	a0,a0,534 # 80008be8 <zombie_list+0x8>
    800019da:	fffff097          	auipc	ra,0xfffff
    800019de:	17a080e7          	jalr	378(ra) # 80000b54 <initlock>
}
    800019e2:	60e2                	ld	ra,24(sp)
    800019e4:	6442                	ld	s0,16(sp)
    800019e6:	64a2                	ld	s1,8(sp)
    800019e8:	6902                	ld	s2,0(sp)
    800019ea:	6105                	addi	sp,sp,32
    800019ec:	8082                	ret

00000000800019ee <initialize_proc>:

void
initialize_proc(struct proc *p){
    800019ee:	1141                	addi	sp,sp,-16
    800019f0:	e422                	sd	s0,8(sp)
    800019f2:	0800                	addi	s0,sp,16
  p->next_index = -1;
    800019f4:	57fd                	li	a5,-1
    800019f6:	16f52a23          	sw	a5,372(a0)
  p->prev_index = -1;
    800019fa:	16f52823          	sw	a5,368(a0)
}
    800019fe:	6422                	ld	s0,8(sp)
    80001a00:	0141                	addi	sp,sp,16
    80001a02:	8082                	ret

0000000080001a04 <isEmpty>:

int
isEmpty(struct _list *lst){
    80001a04:	1141                	addi	sp,sp,-16
    80001a06:	e422                	sd	s0,8(sp)
    80001a08:	0800                	addi	s0,sp,16
  return lst->head == -1;
    80001a0a:	4108                	lw	a0,0(a0)
    80001a0c:	0505                	addi	a0,a0,1
}
    80001a0e:	00153513          	seqz	a0,a0
    80001a12:	6422                	ld	s0,8(sp)
    80001a14:	0141                	addi	sp,sp,16
    80001a16:	8082                	ret

0000000080001a18 <get_head>:

int 
get_head(struct _list *lst){
    80001a18:	1101                	addi	sp,sp,-32
    80001a1a:	ec06                	sd	ra,24(sp)
    80001a1c:	e822                	sd	s0,16(sp)
    80001a1e:	e426                	sd	s1,8(sp)
    80001a20:	e04a                	sd	s2,0(sp)
    80001a22:	1000                	addi	s0,sp,32
    80001a24:	84aa                	mv	s1,a0
  acquire(&lst->head_lock); 
    80001a26:	00850913          	addi	s2,a0,8
    80001a2a:	854a                	mv	a0,s2
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	1b8080e7          	jalr	440(ra) # 80000be4 <acquire>
  int output = lst->head;
    80001a34:	4084                	lw	s1,0(s1)
  release(&lst->head_lock);
    80001a36:	854a                	mv	a0,s2
    80001a38:	fffff097          	auipc	ra,0xfffff
    80001a3c:	260080e7          	jalr	608(ra) # 80000c98 <release>
  return output;
}
    80001a40:	8526                	mv	a0,s1
    80001a42:	60e2                	ld	ra,24(sp)
    80001a44:	6442                	ld	s0,16(sp)
    80001a46:	64a2                	ld	s1,8(sp)
    80001a48:	6902                	ld	s2,0(sp)
    80001a4a:	6105                	addi	sp,sp,32
    80001a4c:	8082                	ret

0000000080001a4e <set_prev_proc>:

void set_prev_proc(struct proc *p, int value){
    80001a4e:	1141                	addi	sp,sp,-16
    80001a50:	e422                	sd	s0,8(sp)
    80001a52:	0800                	addi	s0,sp,16
  p->prev_index = value; 
    80001a54:	16b52823          	sw	a1,368(a0)
}
    80001a58:	6422                	ld	s0,8(sp)
    80001a5a:	0141                	addi	sp,sp,16
    80001a5c:	8082                	ret

0000000080001a5e <set_next_proc>:

void set_next_proc(struct proc *p, int value){
    80001a5e:	1141                	addi	sp,sp,-16
    80001a60:	e422                	sd	s0,8(sp)
    80001a62:	0800                	addi	s0,sp,16
  p->next_index = value; 
    80001a64:	16b52a23          	sw	a1,372(a0)
}
    80001a68:	6422                	ld	s0,8(sp)
    80001a6a:	0141                	addi	sp,sp,16
    80001a6c:	8082                	ret

0000000080001a6e <insert_proc_to_list>:

int 
insert_proc_to_list(struct _list *lst, struct proc *p){
    80001a6e:	7139                	addi	sp,sp,-64
    80001a70:	fc06                	sd	ra,56(sp)
    80001a72:	f822                	sd	s0,48(sp)
    80001a74:	f426                	sd	s1,40(sp)
    80001a76:	f04a                	sd	s2,32(sp)
    80001a78:	ec4e                	sd	s3,24(sp)
    80001a7a:	e852                	sd	s4,16(sp)
    80001a7c:	e456                	sd	s5,8(sp)
    80001a7e:	0080                	addi	s0,sp,64
    80001a80:	84aa                	mv	s1,a0
    80001a82:	8a2e                	mv	s4,a1
  //printf("before insert: \n");
  //print_list(*lst); // delete
  acquire(&lst->head_lock);
    80001a84:	00850913          	addi	s2,a0,8
    80001a88:	854a                	mv	a0,s2
    80001a8a:	fffff097          	auipc	ra,0xfffff
    80001a8e:	15a080e7          	jalr	346(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80001a92:	4088                	lw	a0,0(s1)
  if(isEmpty(lst)){
    80001a94:	57fd                	li	a5,-1
    80001a96:	00f51b63          	bne	a0,a5,80001aac <insert_proc_to_list+0x3e>
    lst->head = p->index;
    80001a9a:	16ca2783          	lw	a5,364(s4)
    80001a9e:	c09c                	sw	a5,0(s1)
    release(&lst->head_lock);
    80001aa0:	854a                	mv	a0,s2
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	1f6080e7          	jalr	502(ra) # 80000c98 <release>
    80001aaa:	a849                	j	80001b3c <insert_proc_to_list+0xce>
  }
  else{ 
    struct proc *curr = &proc[lst->head];
    80001aac:	19000793          	li	a5,400
    80001ab0:	02f50533          	mul	a0,a0,a5
    80001ab4:	00010797          	auipc	a5,0x10
    80001ab8:	d9c78793          	addi	a5,a5,-612 # 80011850 <proc>
    80001abc:	00f504b3          	add	s1,a0,a5
    acquire(&curr->node_lock);
    80001ac0:	17850513          	addi	a0,a0,376
    80001ac4:	953e                	add	a0,a0,a5
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	11e080e7          	jalr	286(ra) # 80000be4 <acquire>
    release(&lst->head_lock);
    80001ace:	854a                	mv	a0,s2
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	1c8080e7          	jalr	456(ra) # 80000c98 <release>
    while(curr->next_index != -1){ // search tail
    80001ad8:	1744a503          	lw	a0,372(s1)
    80001adc:	57fd                	li	a5,-1
    80001ade:	04f50163          	beq	a0,a5,80001b20 <insert_proc_to_list+0xb2>
      acquire(&proc[curr->next_index].node_lock);
    80001ae2:	19000993          	li	s3,400
    80001ae6:	00010917          	auipc	s2,0x10
    80001aea:	d6a90913          	addi	s2,s2,-662 # 80011850 <proc>
    while(curr->next_index != -1){ // search tail
    80001aee:	5afd                	li	s5,-1
      acquire(&proc[curr->next_index].node_lock);
    80001af0:	03350533          	mul	a0,a0,s3
    80001af4:	17850513          	addi	a0,a0,376
    80001af8:	954a                	add	a0,a0,s2
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	0ea080e7          	jalr	234(ra) # 80000be4 <acquire>
      release(&curr->node_lock);
    80001b02:	17848513          	addi	a0,s1,376
    80001b06:	fffff097          	auipc	ra,0xfffff
    80001b0a:	192080e7          	jalr	402(ra) # 80000c98 <release>
      curr = &proc[curr->next_index];
    80001b0e:	1744a483          	lw	s1,372(s1)
    80001b12:	033484b3          	mul	s1,s1,s3
    80001b16:	94ca                	add	s1,s1,s2
    while(curr->next_index != -1){ // search tail
    80001b18:	1744a503          	lw	a0,372(s1)
    80001b1c:	fd551ae3          	bne	a0,s5,80001af0 <insert_proc_to_list+0x82>
    }
    set_next_proc(curr, p->index);  // update next proc of the curr tail
    80001b20:	16ca2783          	lw	a5,364(s4)
  p->next_index = value; 
    80001b24:	16f4aa23          	sw	a5,372(s1)
    set_prev_proc(p, curr->index); // update the prev proc of the new proc
    80001b28:	16c4a783          	lw	a5,364(s1)
  p->prev_index = value; 
    80001b2c:	16fa2823          	sw	a5,368(s4)
    release(&curr->node_lock);
    80001b30:	17848513          	addi	a0,s1,376
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	164080e7          	jalr	356(ra) # 80000c98 <release>
  }
  //printf("after insert: \n");
  //print_list(*lst); // delete
  return 1; 
}
    80001b3c:	4505                	li	a0,1
    80001b3e:	70e2                	ld	ra,56(sp)
    80001b40:	7442                	ld	s0,48(sp)
    80001b42:	74a2                	ld	s1,40(sp)
    80001b44:	7902                	ld	s2,32(sp)
    80001b46:	69e2                	ld	s3,24(sp)
    80001b48:	6a42                	ld	s4,16(sp)
    80001b4a:	6aa2                	ld	s5,8(sp)
    80001b4c:	6121                	addi	sp,sp,64
    80001b4e:	8082                	ret

0000000080001b50 <remove_head_from_list>:

int 
remove_head_from_list(struct _list *lst){
    80001b50:	1101                	addi	sp,sp,-32
    80001b52:	ec06                	sd	ra,24(sp)
    80001b54:	e822                	sd	s0,16(sp)
    80001b56:	e426                	sd	s1,8(sp)
    80001b58:	1000                	addi	s0,sp,32
    80001b5a:	84aa                	mv	s1,a0
  printf("before remove head: \n");
    80001b5c:	00006517          	auipc	a0,0x6
    80001b60:	70450513          	addi	a0,a0,1796 # 80008260 <digits+0x220>
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	a24080e7          	jalr	-1500(ra) # 80000588 <printf>
  return lst->head == -1;
    80001b6c:	409c                	lw	a5,0(s1)
  //print_list(*lst); // delete

  if(isEmpty(lst)){
    80001b6e:	577d                	li	a4,-1
    80001b70:	04e78963          	beq	a5,a4,80001bc2 <remove_head_from_list+0x72>
    printf("Fails in removing the head from the list: the list is empty\n");
    release(&lst->head_lock);
    return 0;
  }
  struct proc *p_head = &proc[lst->head];
  lst->head = p_head->next_index;
    80001b74:	19000713          	li	a4,400
    80001b78:	02e786b3          	mul	a3,a5,a4
    80001b7c:	00010717          	auipc	a4,0x10
    80001b80:	cd470713          	addi	a4,a4,-812 # 80011850 <proc>
    80001b84:	9736                	add	a4,a4,a3
    80001b86:	17472703          	lw	a4,372(a4)
    80001b8a:	c098                	sw	a4,0(s1)
  if(p_head->next_index != -1){
    80001b8c:	56fd                	li	a3,-1
    80001b8e:	04d71a63          	bne	a4,a3,80001be2 <remove_head_from_list+0x92>
  p->next_index = value; 
    80001b92:	19000713          	li	a4,400
    80001b96:	02e787b3          	mul	a5,a5,a4
    80001b9a:	00010717          	auipc	a4,0x10
    80001b9e:	cb670713          	addi	a4,a4,-842 # 80011850 <proc>
    80001ba2:	97ba                	add	a5,a5,a4
    80001ba4:	577d                	li	a4,-1
    80001ba6:	16e7aa23          	sw	a4,372(a5)
    set_prev_proc(&proc[p_head->next_index], -1);
  }
  set_next_proc(p_head, -1);
  release(&lst->head_lock);
    80001baa:	00848513          	addi	a0,s1,8
    80001bae:	fffff097          	auipc	ra,0xfffff
    80001bb2:	0ea080e7          	jalr	234(ra) # 80000c98 <release>
  //printf("after remove head: \n");
  //print_list(*lst); // delete
  return 1;
    80001bb6:	4505                	li	a0,1
}
    80001bb8:	60e2                	ld	ra,24(sp)
    80001bba:	6442                	ld	s0,16(sp)
    80001bbc:	64a2                	ld	s1,8(sp)
    80001bbe:	6105                	addi	sp,sp,32
    80001bc0:	8082                	ret
    printf("Fails in removing the head from the list: the list is empty\n");
    80001bc2:	00006517          	auipc	a0,0x6
    80001bc6:	6b650513          	addi	a0,a0,1718 # 80008278 <digits+0x238>
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	9be080e7          	jalr	-1602(ra) # 80000588 <printf>
    release(&lst->head_lock);
    80001bd2:	00848513          	addi	a0,s1,8
    80001bd6:	fffff097          	auipc	ra,0xfffff
    80001bda:	0c2080e7          	jalr	194(ra) # 80000c98 <release>
    return 0;
    80001bde:	4501                	li	a0,0
    80001be0:	bfe1                	j	80001bb8 <remove_head_from_list+0x68>
  p->prev_index = value; 
    80001be2:	19000693          	li	a3,400
    80001be6:	02d70733          	mul	a4,a4,a3
    80001bea:	00010697          	auipc	a3,0x10
    80001bee:	c6668693          	addi	a3,a3,-922 # 80011850 <proc>
    80001bf2:	9736                	add	a4,a4,a3
    80001bf4:	56fd                	li	a3,-1
    80001bf6:	16d72823          	sw	a3,368(a4)
}
    80001bfa:	bf61                	j	80001b92 <remove_head_from_list+0x42>

0000000080001bfc <remove_proc_to_list>:

int
remove_proc_to_list(struct _list *lst, struct proc *p){
    80001bfc:	7139                	addi	sp,sp,-64
    80001bfe:	fc06                	sd	ra,56(sp)
    80001c00:	f822                	sd	s0,48(sp)
    80001c02:	f426                	sd	s1,40(sp)
    80001c04:	f04a                	sd	s2,32(sp)
    80001c06:	ec4e                	sd	s3,24(sp)
    80001c08:	e852                	sd	s4,16(sp)
    80001c0a:	e456                	sd	s5,8(sp)
    80001c0c:	e05a                	sd	s6,0(sp)
    80001c0e:	0080                	addi	s0,sp,64
    80001c10:	84aa                	mv	s1,a0
    80001c12:	892e                	mv	s2,a1
  //printf("before remove: \n");
  //print_list(*lst); // delete

  acquire(&lst->head_lock);
    80001c14:	00850b13          	addi	s6,a0,8
    80001c18:	855a                	mv	a0,s6
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	fca080e7          	jalr	-54(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80001c22:	409c                	lw	a5,0(s1)
  if(isEmpty(lst)){
    80001c24:	577d                	li	a4,-1
    80001c26:	0ee78163          	beq	a5,a4,80001d08 <remove_proc_to_list+0x10c>
    printf("Fails in removing the process from the list: the list is empty\n");
    release(&lst->head_lock);
    return 0;
  }

  if(lst->head == p->index){ // the required proc is the head
    80001c2a:	16c92703          	lw	a4,364(s2)
    80001c2e:	0ef70c63          	beq	a4,a5,80001d26 <remove_proc_to_list+0x12a>
   remove_head_from_list(lst);
  }
  else{
    struct proc *curr = &proc[lst->head];
    80001c32:	19000513          	li	a0,400
    80001c36:	02a787b3          	mul	a5,a5,a0
    80001c3a:	00010517          	auipc	a0,0x10
    80001c3e:	c1650513          	addi	a0,a0,-1002 # 80011850 <proc>
    80001c42:	00a784b3          	add	s1,a5,a0
    acquire(&curr->node_lock);
    80001c46:	17878793          	addi	a5,a5,376
    80001c4a:	953e                	add	a0,a0,a5
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	f98080e7          	jalr	-104(ra) # 80000be4 <acquire>
    release(&lst->head_lock);
    80001c54:	855a                	mv	a0,s6
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	042080e7          	jalr	66(ra) # 80000c98 <release>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001c5e:	1744a503          	lw	a0,372(s1)
    80001c62:	16c92783          	lw	a5,364(s2)
    80001c66:	5afd                	li	s5,-1
      acquire(&proc[curr->next_index].node_lock);
    80001c68:	19000a13          	li	s4,400
    80001c6c:	00010997          	auipc	s3,0x10
    80001c70:	be498993          	addi	s3,s3,-1052 # 80011850 <proc>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001c74:	0ca78063          	beq	a5,a0,80001d34 <remove_proc_to_list+0x138>
    80001c78:	0d550063          	beq	a0,s5,80001d38 <remove_proc_to_list+0x13c>
      acquire(&proc[curr->next_index].node_lock);
    80001c7c:	03450533          	mul	a0,a0,s4
    80001c80:	17850513          	addi	a0,a0,376
    80001c84:	954e                	add	a0,a0,s3
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	f5e080e7          	jalr	-162(ra) # 80000be4 <acquire>
      release(&curr->node_lock);
    80001c8e:	17848513          	addi	a0,s1,376
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	006080e7          	jalr	6(ra) # 80000c98 <release>
      curr = &proc[curr->next_index];
    80001c9a:	1744a483          	lw	s1,372(s1)
    80001c9e:	034484b3          	mul	s1,s1,s4
    80001ca2:	94ce                	add	s1,s1,s3
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001ca4:	1744a503          	lw	a0,372(s1)
    80001ca8:	16c92783          	lw	a5,364(s2)
    80001cac:	fcf516e3          	bne	a0,a5,80001c78 <remove_proc_to_list+0x7c>
    }
    if(curr->next_index == -1){
    80001cb0:	577d                	li	a4,-1
    80001cb2:	08e78363          	beq	a5,a4,80001d38 <remove_proc_to_list+0x13c>
      printf("Fails in removing the process from the list: process is not found in the list\n");
      release(&lst->head_lock);
      return 0;
    }
    acquire(&p->node_lock); // curr is p->prev
    80001cb6:	17890993          	addi	s3,s2,376
    80001cba:	854e                	mv	a0,s3
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	f28080e7          	jalr	-216(ra) # 80000be4 <acquire>
    set_next_proc(curr, p->next_index);
    80001cc4:	17492783          	lw	a5,372(s2)
  p->next_index = value; 
    80001cc8:	16f4aa23          	sw	a5,372(s1)
    if(p->next_index != -1)
    80001ccc:	577d                	li	a4,-1
    80001cce:	08e79463          	bne	a5,a4,80001d56 <remove_proc_to_list+0x15a>
  p->next_index = -1;
    80001cd2:	57fd                	li	a5,-1
    80001cd4:	16f92a23          	sw	a5,372(s2)
  p->prev_index = -1;
    80001cd8:	16f92823          	sw	a5,368(s2)
      set_prev_proc(&proc[p->next_index], curr->index);
    initialize_proc(p);
    release(&p->node_lock);
    80001cdc:	854e                	mv	a0,s3
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	fba080e7          	jalr	-70(ra) # 80000c98 <release>
    release(&curr->node_lock);
    80001ce6:	17848513          	addi	a0,s1,376
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	fae080e7          	jalr	-82(ra) # 80000c98 <release>
  }
  //printf("after remove: \n");
  //print_list(*lst); // delete
  return 1;
    80001cf2:	4505                	li	a0,1
}
    80001cf4:	70e2                	ld	ra,56(sp)
    80001cf6:	7442                	ld	s0,48(sp)
    80001cf8:	74a2                	ld	s1,40(sp)
    80001cfa:	7902                	ld	s2,32(sp)
    80001cfc:	69e2                	ld	s3,24(sp)
    80001cfe:	6a42                	ld	s4,16(sp)
    80001d00:	6aa2                	ld	s5,8(sp)
    80001d02:	6b02                	ld	s6,0(sp)
    80001d04:	6121                	addi	sp,sp,64
    80001d06:	8082                	ret
    printf("Fails in removing the process from the list: the list is empty\n");
    80001d08:	00006517          	auipc	a0,0x6
    80001d0c:	5b050513          	addi	a0,a0,1456 # 800082b8 <digits+0x278>
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	878080e7          	jalr	-1928(ra) # 80000588 <printf>
    release(&lst->head_lock);
    80001d18:	855a                	mv	a0,s6
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	f7e080e7          	jalr	-130(ra) # 80000c98 <release>
    return 0;
    80001d22:	4501                	li	a0,0
    80001d24:	bfc1                	j	80001cf4 <remove_proc_to_list+0xf8>
   remove_head_from_list(lst);
    80001d26:	8526                	mv	a0,s1
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	e28080e7          	jalr	-472(ra) # 80001b50 <remove_head_from_list>
  return 1;
    80001d30:	4505                	li	a0,1
    80001d32:	b7c9                	j	80001cf4 <remove_proc_to_list+0xf8>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001d34:	87aa                	mv	a5,a0
    80001d36:	bfad                	j	80001cb0 <remove_proc_to_list+0xb4>
      printf("Fails in removing the process from the list: process is not found in the list\n");
    80001d38:	00006517          	auipc	a0,0x6
    80001d3c:	5c050513          	addi	a0,a0,1472 # 800082f8 <digits+0x2b8>
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	848080e7          	jalr	-1976(ra) # 80000588 <printf>
      release(&lst->head_lock);
    80001d48:	855a                	mv	a0,s6
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	f4e080e7          	jalr	-178(ra) # 80000c98 <release>
      return 0;
    80001d52:	4501                	li	a0,0
    80001d54:	b745                	j	80001cf4 <remove_proc_to_list+0xf8>
      set_prev_proc(&proc[p->next_index], curr->index);
    80001d56:	16c4a683          	lw	a3,364(s1)
  p->prev_index = value; 
    80001d5a:	19000713          	li	a4,400
    80001d5e:	02e787b3          	mul	a5,a5,a4
    80001d62:	00010717          	auipc	a4,0x10
    80001d66:	aee70713          	addi	a4,a4,-1298 # 80011850 <proc>
    80001d6a:	97ba                	add	a5,a5,a4
    80001d6c:	16d7a823          	sw	a3,368(a5)
}
    80001d70:	b78d                	j	80001cd2 <remove_proc_to_list+0xd6>

0000000080001d72 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001d72:	7139                	addi	sp,sp,-64
    80001d74:	fc06                	sd	ra,56(sp)
    80001d76:	f822                	sd	s0,48(sp)
    80001d78:	f426                	sd	s1,40(sp)
    80001d7a:	f04a                	sd	s2,32(sp)
    80001d7c:	ec4e                	sd	s3,24(sp)
    80001d7e:	e852                	sd	s4,16(sp)
    80001d80:	e456                	sd	s5,8(sp)
    80001d82:	e05a                	sd	s6,0(sp)
    80001d84:	0080                	addi	s0,sp,64
    80001d86:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d88:	00010497          	auipc	s1,0x10
    80001d8c:	ac848493          	addi	s1,s1,-1336 # 80011850 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001d90:	8b26                	mv	s6,s1
    80001d92:	00006a97          	auipc	s5,0x6
    80001d96:	26ea8a93          	addi	s5,s5,622 # 80008000 <etext>
    80001d9a:	04000937          	lui	s2,0x4000
    80001d9e:	197d                	addi	s2,s2,-1
    80001da0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001da2:	00016a17          	auipc	s4,0x16
    80001da6:	eaea0a13          	addi	s4,s4,-338 # 80017c50 <tickslock>
    char *pa = kalloc();
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	d4a080e7          	jalr	-694(ra) # 80000af4 <kalloc>
    80001db2:	862a                	mv	a2,a0
    if(pa == 0)
    80001db4:	c131                	beqz	a0,80001df8 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001db6:	416485b3          	sub	a1,s1,s6
    80001dba:	8591                	srai	a1,a1,0x4
    80001dbc:	000ab783          	ld	a5,0(s5)
    80001dc0:	02f585b3          	mul	a1,a1,a5
    80001dc4:	2585                	addiw	a1,a1,1
    80001dc6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001dca:	4719                	li	a4,6
    80001dcc:	6685                	lui	a3,0x1
    80001dce:	40b905b3          	sub	a1,s2,a1
    80001dd2:	854e                	mv	a0,s3
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	37c080e7          	jalr	892(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ddc:	19048493          	addi	s1,s1,400
    80001de0:	fd4495e3          	bne	s1,s4,80001daa <proc_mapstacks+0x38>
  }
}
    80001de4:	70e2                	ld	ra,56(sp)
    80001de6:	7442                	ld	s0,48(sp)
    80001de8:	74a2                	ld	s1,40(sp)
    80001dea:	7902                	ld	s2,32(sp)
    80001dec:	69e2                	ld	s3,24(sp)
    80001dee:	6a42                	ld	s4,16(sp)
    80001df0:	6aa2                	ld	s5,8(sp)
    80001df2:	6b02                	ld	s6,0(sp)
    80001df4:	6121                	addi	sp,sp,64
    80001df6:	8082                	ret
      panic("kalloc");
    80001df8:	00006517          	auipc	a0,0x6
    80001dfc:	55050513          	addi	a0,a0,1360 # 80008348 <digits+0x308>
    80001e00:	ffffe097          	auipc	ra,0xffffe
    80001e04:	73e080e7          	jalr	1854(ra) # 8000053e <panic>

0000000080001e08 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001e08:	711d                	addi	sp,sp,-96
    80001e0a:	ec86                	sd	ra,88(sp)
    80001e0c:	e8a2                	sd	s0,80(sp)
    80001e0e:	e4a6                	sd	s1,72(sp)
    80001e10:	e0ca                	sd	s2,64(sp)
    80001e12:	fc4e                	sd	s3,56(sp)
    80001e14:	f852                	sd	s4,48(sp)
    80001e16:	f456                	sd	s5,40(sp)
    80001e18:	f05a                	sd	s6,32(sp)
    80001e1a:	ec5e                	sd	s7,24(sp)
    80001e1c:	e862                	sd	s8,16(sp)
    80001e1e:	e466                	sd	s9,8(sp)
    80001e20:	e06a                	sd	s10,0(sp)
    80001e22:	1080                	addi	s0,sp,96
  struct proc *p;

  initialize_lists();
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	acc080e7          	jalr	-1332(ra) # 800018f0 <initialize_lists>

  initlock(&pid_lock, "nextpid");
    80001e2c:	00006597          	auipc	a1,0x6
    80001e30:	52458593          	addi	a1,a1,1316 # 80008350 <digits+0x310>
    80001e34:	00010517          	auipc	a0,0x10
    80001e38:	9ec50513          	addi	a0,a0,-1556 # 80011820 <pid_lock>
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	d18080e7          	jalr	-744(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001e44:	00006597          	auipc	a1,0x6
    80001e48:	51458593          	addi	a1,a1,1300 # 80008358 <digits+0x318>
    80001e4c:	00010517          	auipc	a0,0x10
    80001e50:	9ec50513          	addi	a0,a0,-1556 # 80011838 <wait_lock>
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	d00080e7          	jalr	-768(ra) # 80000b54 <initlock>

  int i = 0;
    80001e5c:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e5e:	00010497          	auipc	s1,0x10
    80001e62:	9f248493          	addi	s1,s1,-1550 # 80011850 <proc>
      initlock(&p->lock, "proc");
    80001e66:	00006d17          	auipc	s10,0x6
    80001e6a:	502d0d13          	addi	s10,s10,1282 # 80008368 <digits+0x328>
      initlock(&p->lock, "node_lock");
    80001e6e:	00006c97          	auipc	s9,0x6
    80001e72:	502c8c93          	addi	s9,s9,1282 # 80008370 <digits+0x330>
      p->kstack = KSTACK((int) (p - proc));
    80001e76:	8c26                	mv	s8,s1
    80001e78:	00006b97          	auipc	s7,0x6
    80001e7c:	188b8b93          	addi	s7,s7,392 # 80008000 <etext>
    80001e80:	04000a37          	lui	s4,0x4000
    80001e84:	1a7d                	addi	s4,s4,-1
    80001e86:	0a32                	slli	s4,s4,0xc
  p->next_index = -1;
    80001e88:	59fd                	li	s3,-1
      p->index = i;
      initialize_proc(p);
      printf("insert procinit unused %d\n", p->index); //delete
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001e8a:	00007b17          	auipc	s6,0x7
    80001e8e:	d16b0b13          	addi	s6,s6,-746 # 80008ba0 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e92:	00016a97          	auipc	s5,0x16
    80001e96:	dbea8a93          	addi	s5,s5,-578 # 80017c50 <tickslock>
      initlock(&p->lock, "proc");
    80001e9a:	85ea                	mv	a1,s10
    80001e9c:	8526                	mv	a0,s1
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	cb6080e7          	jalr	-842(ra) # 80000b54 <initlock>
      initlock(&p->lock, "node_lock");
    80001ea6:	85e6                	mv	a1,s9
    80001ea8:	8526                	mv	a0,s1
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	caa080e7          	jalr	-854(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001eb2:	418487b3          	sub	a5,s1,s8
    80001eb6:	8791                	srai	a5,a5,0x4
    80001eb8:	000bb703          	ld	a4,0(s7)
    80001ebc:	02e787b3          	mul	a5,a5,a4
    80001ec0:	2785                	addiw	a5,a5,1
    80001ec2:	00d7979b          	slliw	a5,a5,0xd
    80001ec6:	40fa07b3          	sub	a5,s4,a5
    80001eca:	e0bc                	sd	a5,64(s1)
      p->index = i;
    80001ecc:	1724a623          	sw	s2,364(s1)
  p->next_index = -1;
    80001ed0:	1734aa23          	sw	s3,372(s1)
  p->prev_index = -1;
    80001ed4:	1734a823          	sw	s3,368(s1)
      printf("insert procinit unused %d\n", p->index); //delete
    80001ed8:	85ca                	mv	a1,s2
    80001eda:	00006517          	auipc	a0,0x6
    80001ede:	4a650513          	addi	a0,a0,1190 # 80008380 <digits+0x340>
    80001ee2:	ffffe097          	auipc	ra,0xffffe
    80001ee6:	6a6080e7          	jalr	1702(ra) # 80000588 <printf>
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001eea:	85a6                	mv	a1,s1
    80001eec:	855a                	mv	a0,s6
    80001eee:	00000097          	auipc	ra,0x0
    80001ef2:	b80080e7          	jalr	-1152(ra) # 80001a6e <insert_proc_to_list>
      i++;
    80001ef6:	2905                	addiw	s2,s2,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ef8:	19048493          	addi	s1,s1,400
    80001efc:	f9549fe3          	bne	s1,s5,80001e9a <procinit+0x92>
  }
}
    80001f00:	60e6                	ld	ra,88(sp)
    80001f02:	6446                	ld	s0,80(sp)
    80001f04:	64a6                	ld	s1,72(sp)
    80001f06:	6906                	ld	s2,64(sp)
    80001f08:	79e2                	ld	s3,56(sp)
    80001f0a:	7a42                	ld	s4,48(sp)
    80001f0c:	7aa2                	ld	s5,40(sp)
    80001f0e:	7b02                	ld	s6,32(sp)
    80001f10:	6be2                	ld	s7,24(sp)
    80001f12:	6c42                	ld	s8,16(sp)
    80001f14:	6ca2                	ld	s9,8(sp)
    80001f16:	6d02                	ld	s10,0(sp)
    80001f18:	6125                	addi	sp,sp,96
    80001f1a:	8082                	ret

0000000080001f1c <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001f1c:	1141                	addi	sp,sp,-16
    80001f1e:	e422                	sd	s0,8(sp)
    80001f20:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f22:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001f24:	2501                	sext.w	a0,a0
    80001f26:	6422                	ld	s0,8(sp)
    80001f28:	0141                	addi	sp,sp,16
    80001f2a:	8082                	ret

0000000080001f2c <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001f2c:	1141                	addi	sp,sp,-16
    80001f2e:	e422                	sd	s0,8(sp)
    80001f30:	0800                	addi	s0,sp,16
    80001f32:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001f34:	2781                	sext.w	a5,a5
    80001f36:	0b000513          	li	a0,176
    80001f3a:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001f3e:	0000f517          	auipc	a0,0xf
    80001f42:	36250513          	addi	a0,a0,866 # 800112a0 <cpus>
    80001f46:	953e                	add	a0,a0,a5
    80001f48:	6422                	ld	s0,8(sp)
    80001f4a:	0141                	addi	sp,sp,16
    80001f4c:	8082                	ret

0000000080001f4e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001f4e:	1101                	addi	sp,sp,-32
    80001f50:	ec06                	sd	ra,24(sp)
    80001f52:	e822                	sd	s0,16(sp)
    80001f54:	e426                	sd	s1,8(sp)
    80001f56:	1000                	addi	s0,sp,32
  push_off();
    80001f58:	fffff097          	auipc	ra,0xfffff
    80001f5c:	c40080e7          	jalr	-960(ra) # 80000b98 <push_off>
    80001f60:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001f62:	2781                	sext.w	a5,a5
    80001f64:	0b000713          	li	a4,176
    80001f68:	02e787b3          	mul	a5,a5,a4
    80001f6c:	0000f717          	auipc	a4,0xf
    80001f70:	33470713          	addi	a4,a4,820 # 800112a0 <cpus>
    80001f74:	97ba                	add	a5,a5,a4
    80001f76:	6384                	ld	s1,0(a5)
  pop_off();
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	cc0080e7          	jalr	-832(ra) # 80000c38 <pop_off>
  return p;
}
    80001f80:	8526                	mv	a0,s1
    80001f82:	60e2                	ld	ra,24(sp)
    80001f84:	6442                	ld	s0,16(sp)
    80001f86:	64a2                	ld	s1,8(sp)
    80001f88:	6105                	addi	sp,sp,32
    80001f8a:	8082                	ret

0000000080001f8c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001f8c:	1141                	addi	sp,sp,-16
    80001f8e:	e406                	sd	ra,8(sp)
    80001f90:	e022                	sd	s0,0(sp)
    80001f92:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001f94:	00000097          	auipc	ra,0x0
    80001f98:	fba080e7          	jalr	-70(ra) # 80001f4e <myproc>
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	cfc080e7          	jalr	-772(ra) # 80000c98 <release>

  if (first) {
    80001fa4:	00007797          	auipc	a5,0x7
    80001fa8:	bec7a783          	lw	a5,-1044(a5) # 80008b90 <first.1787>
    80001fac:	eb89                	bnez	a5,80001fbe <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001fae:	00001097          	auipc	ra,0x1
    80001fb2:	19c080e7          	jalr	412(ra) # 8000314a <usertrapret>
}
    80001fb6:	60a2                	ld	ra,8(sp)
    80001fb8:	6402                	ld	s0,0(sp)
    80001fba:	0141                	addi	sp,sp,16
    80001fbc:	8082                	ret
    first = 0;
    80001fbe:	00007797          	auipc	a5,0x7
    80001fc2:	bc07a923          	sw	zero,-1070(a5) # 80008b90 <first.1787>
    fsinit(ROOTDEV);
    80001fc6:	4505                	li	a0,1
    80001fc8:	00002097          	auipc	ra,0x2
    80001fcc:	f40080e7          	jalr	-192(ra) # 80003f08 <fsinit>
    80001fd0:	bff9                	j	80001fae <forkret+0x22>

0000000080001fd2 <allocpid>:
allocpid() {
    80001fd2:	1101                	addi	sp,sp,-32
    80001fd4:	ec06                	sd	ra,24(sp)
    80001fd6:	e822                	sd	s0,16(sp)
    80001fd8:	e426                	sd	s1,8(sp)
    80001fda:	e04a                	sd	s2,0(sp)
    80001fdc:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001fde:	00007917          	auipc	s2,0x7
    80001fe2:	bb690913          	addi	s2,s2,-1098 # 80008b94 <nextpid>
    80001fe6:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, nextpid + 1));
    80001fea:	0014861b          	addiw	a2,s1,1
    80001fee:	85a6                	mv	a1,s1
    80001ff0:	854a                	mv	a0,s2
    80001ff2:	00005097          	auipc	ra,0x5
    80001ff6:	d24080e7          	jalr	-732(ra) # 80006d16 <cas>
    80001ffa:	2501                	sext.w	a0,a0
    80001ffc:	f56d                	bnez	a0,80001fe6 <allocpid+0x14>
}
    80001ffe:	8526                	mv	a0,s1
    80002000:	60e2                	ld	ra,24(sp)
    80002002:	6442                	ld	s0,16(sp)
    80002004:	64a2                	ld	s1,8(sp)
    80002006:	6902                	ld	s2,0(sp)
    80002008:	6105                	addi	sp,sp,32
    8000200a:	8082                	ret

000000008000200c <proc_pagetable>:
{
    8000200c:	1101                	addi	sp,sp,-32
    8000200e:	ec06                	sd	ra,24(sp)
    80002010:	e822                	sd	s0,16(sp)
    80002012:	e426                	sd	s1,8(sp)
    80002014:	e04a                	sd	s2,0(sp)
    80002016:	1000                	addi	s0,sp,32
    80002018:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    8000201a:	fffff097          	auipc	ra,0xfffff
    8000201e:	320080e7          	jalr	800(ra) # 8000133a <uvmcreate>
    80002022:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80002024:	c121                	beqz	a0,80002064 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80002026:	4729                	li	a4,10
    80002028:	00005697          	auipc	a3,0x5
    8000202c:	fd868693          	addi	a3,a3,-40 # 80007000 <_trampoline>
    80002030:	6605                	lui	a2,0x1
    80002032:	040005b7          	lui	a1,0x4000
    80002036:	15fd                	addi	a1,a1,-1
    80002038:	05b2                	slli	a1,a1,0xc
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	076080e7          	jalr	118(ra) # 800010b0 <mappages>
    80002042:	02054863          	bltz	a0,80002072 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80002046:	4719                	li	a4,6
    80002048:	05893683          	ld	a3,88(s2)
    8000204c:	6605                	lui	a2,0x1
    8000204e:	020005b7          	lui	a1,0x2000
    80002052:	15fd                	addi	a1,a1,-1
    80002054:	05b6                	slli	a1,a1,0xd
    80002056:	8526                	mv	a0,s1
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	058080e7          	jalr	88(ra) # 800010b0 <mappages>
    80002060:	02054163          	bltz	a0,80002082 <proc_pagetable+0x76>
}
    80002064:	8526                	mv	a0,s1
    80002066:	60e2                	ld	ra,24(sp)
    80002068:	6442                	ld	s0,16(sp)
    8000206a:	64a2                	ld	s1,8(sp)
    8000206c:	6902                	ld	s2,0(sp)
    8000206e:	6105                	addi	sp,sp,32
    80002070:	8082                	ret
    uvmfree(pagetable, 0);
    80002072:	4581                	li	a1,0
    80002074:	8526                	mv	a0,s1
    80002076:	fffff097          	auipc	ra,0xfffff
    8000207a:	4c0080e7          	jalr	1216(ra) # 80001536 <uvmfree>
    return 0;
    8000207e:	4481                	li	s1,0
    80002080:	b7d5                	j	80002064 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002082:	4681                	li	a3,0
    80002084:	4605                	li	a2,1
    80002086:	040005b7          	lui	a1,0x4000
    8000208a:	15fd                	addi	a1,a1,-1
    8000208c:	05b2                	slli	a1,a1,0xc
    8000208e:	8526                	mv	a0,s1
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	1e6080e7          	jalr	486(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80002098:	4581                	li	a1,0
    8000209a:	8526                	mv	a0,s1
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	49a080e7          	jalr	1178(ra) # 80001536 <uvmfree>
    return 0;
    800020a4:	4481                	li	s1,0
    800020a6:	bf7d                	j	80002064 <proc_pagetable+0x58>

00000000800020a8 <proc_freepagetable>:
{
    800020a8:	1101                	addi	sp,sp,-32
    800020aa:	ec06                	sd	ra,24(sp)
    800020ac:	e822                	sd	s0,16(sp)
    800020ae:	e426                	sd	s1,8(sp)
    800020b0:	e04a                	sd	s2,0(sp)
    800020b2:	1000                	addi	s0,sp,32
    800020b4:	84aa                	mv	s1,a0
    800020b6:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    800020b8:	4681                	li	a3,0
    800020ba:	4605                	li	a2,1
    800020bc:	040005b7          	lui	a1,0x4000
    800020c0:	15fd                	addi	a1,a1,-1
    800020c2:	05b2                	slli	a1,a1,0xc
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	1b2080e7          	jalr	434(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    800020cc:	4681                	li	a3,0
    800020ce:	4605                	li	a2,1
    800020d0:	020005b7          	lui	a1,0x2000
    800020d4:	15fd                	addi	a1,a1,-1
    800020d6:	05b6                	slli	a1,a1,0xd
    800020d8:	8526                	mv	a0,s1
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	19c080e7          	jalr	412(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    800020e2:	85ca                	mv	a1,s2
    800020e4:	8526                	mv	a0,s1
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	450080e7          	jalr	1104(ra) # 80001536 <uvmfree>
}
    800020ee:	60e2                	ld	ra,24(sp)
    800020f0:	6442                	ld	s0,16(sp)
    800020f2:	64a2                	ld	s1,8(sp)
    800020f4:	6902                	ld	s2,0(sp)
    800020f6:	6105                	addi	sp,sp,32
    800020f8:	8082                	ret

00000000800020fa <freeproc>:
{
    800020fa:	1101                	addi	sp,sp,-32
    800020fc:	ec06                	sd	ra,24(sp)
    800020fe:	e822                	sd	s0,16(sp)
    80002100:	e426                	sd	s1,8(sp)
    80002102:	1000                	addi	s0,sp,32
    80002104:	84aa                	mv	s1,a0
  if(p->trapframe)
    80002106:	6d28                	ld	a0,88(a0)
    80002108:	c509                	beqz	a0,80002112 <freeproc+0x18>
    kfree((void*)p->trapframe);
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	8ee080e7          	jalr	-1810(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80002112:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80002116:	68a8                	ld	a0,80(s1)
    80002118:	c511                	beqz	a0,80002124 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    8000211a:	64ac                	ld	a1,72(s1)
    8000211c:	00000097          	auipc	ra,0x0
    80002120:	f8c080e7          	jalr	-116(ra) # 800020a8 <proc_freepagetable>
  p->pagetable = 0;
    80002124:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80002128:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    8000212c:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80002130:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80002134:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80002138:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    8000213c:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002140:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80002144:	0004ac23          	sw	zero,24(s1)
  printf("remove freeproc zombie %d\n", p->index); //delete
    80002148:	16c4a583          	lw	a1,364(s1)
    8000214c:	00006517          	auipc	a0,0x6
    80002150:	25450513          	addi	a0,a0,596 # 800083a0 <digits+0x360>
    80002154:	ffffe097          	auipc	ra,0xffffe
    80002158:	434080e7          	jalr	1076(ra) # 80000588 <printf>
  remove_proc_to_list(&zombie_list, p); // remove the freed process from the ZOMBIE list
    8000215c:	85a6                	mv	a1,s1
    8000215e:	00007517          	auipc	a0,0x7
    80002162:	a8250513          	addi	a0,a0,-1406 # 80008be0 <zombie_list>
    80002166:	00000097          	auipc	ra,0x0
    8000216a:	a96080e7          	jalr	-1386(ra) # 80001bfc <remove_proc_to_list>
  printf("insert freeproc unused %d\n", p->index); //delete
    8000216e:	16c4a583          	lw	a1,364(s1)
    80002172:	00006517          	auipc	a0,0x6
    80002176:	24e50513          	addi	a0,a0,590 # 800083c0 <digits+0x380>
    8000217a:	ffffe097          	auipc	ra,0xffffe
    8000217e:	40e080e7          	jalr	1038(ra) # 80000588 <printf>
  insert_proc_to_list(&unused_list, p); // admit its entry to the UNUSED entry list.
    80002182:	85a6                	mv	a1,s1
    80002184:	00007517          	auipc	a0,0x7
    80002188:	a1c50513          	addi	a0,a0,-1508 # 80008ba0 <unused_list>
    8000218c:	00000097          	auipc	ra,0x0
    80002190:	8e2080e7          	jalr	-1822(ra) # 80001a6e <insert_proc_to_list>
}
    80002194:	60e2                	ld	ra,24(sp)
    80002196:	6442                	ld	s0,16(sp)
    80002198:	64a2                	ld	s1,8(sp)
    8000219a:	6105                	addi	sp,sp,32
    8000219c:	8082                	ret

000000008000219e <allocproc>:
{
    8000219e:	715d                	addi	sp,sp,-80
    800021a0:	e486                	sd	ra,72(sp)
    800021a2:	e0a2                	sd	s0,64(sp)
    800021a4:	fc26                	sd	s1,56(sp)
    800021a6:	f84a                	sd	s2,48(sp)
    800021a8:	f44e                	sd	s3,40(sp)
    800021aa:	f052                	sd	s4,32(sp)
    800021ac:	ec56                	sd	s5,24(sp)
    800021ae:	e85a                	sd	s6,16(sp)
    800021b0:	e45e                	sd	s7,8(sp)
    800021b2:	0880                	addi	s0,sp,80
  while(!isEmpty(&unused_list)){
    800021b4:	00007717          	auipc	a4,0x7
    800021b8:	9ec72703          	lw	a4,-1556(a4) # 80008ba0 <unused_list>
    800021bc:	57fd                	li	a5,-1
    800021be:	14f70a63          	beq	a4,a5,80002312 <allocproc+0x174>
    p = &proc[get_head(&unused_list)];
    800021c2:	00007a17          	auipc	s4,0x7
    800021c6:	9dea0a13          	addi	s4,s4,-1570 # 80008ba0 <unused_list>
    800021ca:	19000b13          	li	s6,400
    800021ce:	0000fa97          	auipc	s5,0xf
    800021d2:	682a8a93          	addi	s5,s5,1666 # 80011850 <proc>
  while(!isEmpty(&unused_list)){
    800021d6:	5bfd                	li	s7,-1
    p = &proc[get_head(&unused_list)];
    800021d8:	8552                	mv	a0,s4
    800021da:	00000097          	auipc	ra,0x0
    800021de:	83e080e7          	jalr	-1986(ra) # 80001a18 <get_head>
    800021e2:	892a                	mv	s2,a0
    800021e4:	036509b3          	mul	s3,a0,s6
    800021e8:	015984b3          	add	s1,s3,s5
    acquire(&p->lock);
    800021ec:	8526                	mv	a0,s1
    800021ee:	fffff097          	auipc	ra,0xfffff
    800021f2:	9f6080e7          	jalr	-1546(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    800021f6:	4c9c                	lw	a5,24(s1)
    800021f8:	c79d                	beqz	a5,80002226 <allocproc+0x88>
      release(&p->lock);
    800021fa:	8526                	mv	a0,s1
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	a9c080e7          	jalr	-1380(ra) # 80000c98 <release>
  while(!isEmpty(&unused_list)){
    80002204:	000a2783          	lw	a5,0(s4)
    80002208:	fd7798e3          	bne	a5,s7,800021d8 <allocproc+0x3a>
  return 0;
    8000220c:	4481                	li	s1,0
}
    8000220e:	8526                	mv	a0,s1
    80002210:	60a6                	ld	ra,72(sp)
    80002212:	6406                	ld	s0,64(sp)
    80002214:	74e2                	ld	s1,56(sp)
    80002216:	7942                	ld	s2,48(sp)
    80002218:	79a2                	ld	s3,40(sp)
    8000221a:	7a02                	ld	s4,32(sp)
    8000221c:	6ae2                	ld	s5,24(sp)
    8000221e:	6b42                	ld	s6,16(sp)
    80002220:	6ba2                	ld	s7,8(sp)
    80002222:	6161                	addi	sp,sp,80
    80002224:	8082                	ret
      printf("remove allocpric unused %d\n", p->index); //delete
    80002226:	19000a13          	li	s4,400
    8000222a:	034907b3          	mul	a5,s2,s4
    8000222e:	0000fa17          	auipc	s4,0xf
    80002232:	622a0a13          	addi	s4,s4,1570 # 80011850 <proc>
    80002236:	9a3e                	add	s4,s4,a5
    80002238:	16ca2583          	lw	a1,364(s4)
    8000223c:	00006517          	auipc	a0,0x6
    80002240:	1a450513          	addi	a0,a0,420 # 800083e0 <digits+0x3a0>
    80002244:	ffffe097          	auipc	ra,0xffffe
    80002248:	344080e7          	jalr	836(ra) # 80000588 <printf>
      remove_proc_to_list(&unused_list, p); // choose the new process entry to initialize from the UNUSED entry list.
    8000224c:	85a6                	mv	a1,s1
    8000224e:	00007517          	auipc	a0,0x7
    80002252:	95250513          	addi	a0,a0,-1710 # 80008ba0 <unused_list>
    80002256:	00000097          	auipc	ra,0x0
    8000225a:	9a6080e7          	jalr	-1626(ra) # 80001bfc <remove_proc_to_list>
  p->pid = allocpid();
    8000225e:	00000097          	auipc	ra,0x0
    80002262:	d74080e7          	jalr	-652(ra) # 80001fd2 <allocpid>
    80002266:	02aa2823          	sw	a0,48(s4)
  p->state = USED;
    8000226a:	4785                	li	a5,1
    8000226c:	00fa2c23          	sw	a5,24(s4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	884080e7          	jalr	-1916(ra) # 80000af4 <kalloc>
    80002278:	8aaa                	mv	s5,a0
    8000227a:	04aa3c23          	sd	a0,88(s4)
    8000227e:	c135                	beqz	a0,800022e2 <allocproc+0x144>
  p->pagetable = proc_pagetable(p);
    80002280:	8526                	mv	a0,s1
    80002282:	00000097          	auipc	ra,0x0
    80002286:	d8a080e7          	jalr	-630(ra) # 8000200c <proc_pagetable>
    8000228a:	8a2a                	mv	s4,a0
    8000228c:	19000793          	li	a5,400
    80002290:	02f90733          	mul	a4,s2,a5
    80002294:	0000f797          	auipc	a5,0xf
    80002298:	5bc78793          	addi	a5,a5,1468 # 80011850 <proc>
    8000229c:	97ba                	add	a5,a5,a4
    8000229e:	eba8                	sd	a0,80(a5)
  if(p->pagetable == 0){
    800022a0:	cd29                	beqz	a0,800022fa <allocproc+0x15c>
  memset(&p->context, 0, sizeof(p->context));
    800022a2:	06098513          	addi	a0,s3,96
    800022a6:	0000f997          	auipc	s3,0xf
    800022aa:	5aa98993          	addi	s3,s3,1450 # 80011850 <proc>
    800022ae:	07000613          	li	a2,112
    800022b2:	4581                	li	a1,0
    800022b4:	954e                	add	a0,a0,s3
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	a2a080e7          	jalr	-1494(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    800022be:	19000793          	li	a5,400
    800022c2:	02f90933          	mul	s2,s2,a5
    800022c6:	994e                	add	s2,s2,s3
    800022c8:	00000797          	auipc	a5,0x0
    800022cc:	cc478793          	addi	a5,a5,-828 # 80001f8c <forkret>
    800022d0:	06f93023          	sd	a5,96(s2)
  p->context.sp = p->kstack + PGSIZE;
    800022d4:	04093783          	ld	a5,64(s2)
    800022d8:	6705                	lui	a4,0x1
    800022da:	97ba                	add	a5,a5,a4
    800022dc:	06f93423          	sd	a5,104(s2)
  return p;
    800022e0:	b73d                	j	8000220e <allocproc+0x70>
    freeproc(p);
    800022e2:	8526                	mv	a0,s1
    800022e4:	00000097          	auipc	ra,0x0
    800022e8:	e16080e7          	jalr	-490(ra) # 800020fa <freeproc>
    release(&p->lock);
    800022ec:	8526                	mv	a0,s1
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	9aa080e7          	jalr	-1622(ra) # 80000c98 <release>
    return 0;
    800022f6:	84d6                	mv	s1,s5
    800022f8:	bf19                	j	8000220e <allocproc+0x70>
    freeproc(p);
    800022fa:	8526                	mv	a0,s1
    800022fc:	00000097          	auipc	ra,0x0
    80002300:	dfe080e7          	jalr	-514(ra) # 800020fa <freeproc>
    release(&p->lock);
    80002304:	8526                	mv	a0,s1
    80002306:	fffff097          	auipc	ra,0xfffff
    8000230a:	992080e7          	jalr	-1646(ra) # 80000c98 <release>
    return 0;
    8000230e:	84d2                	mv	s1,s4
    80002310:	bdfd                	j	8000220e <allocproc+0x70>
  return 0;
    80002312:	4481                	li	s1,0
    80002314:	bded                	j	8000220e <allocproc+0x70>

0000000080002316 <userinit>:
{
    80002316:	1101                	addi	sp,sp,-32
    80002318:	ec06                	sd	ra,24(sp)
    8000231a:	e822                	sd	s0,16(sp)
    8000231c:	e426                	sd	s1,8(sp)
    8000231e:	1000                	addi	s0,sp,32
  p = allocproc();
    80002320:	00000097          	auipc	ra,0x0
    80002324:	e7e080e7          	jalr	-386(ra) # 8000219e <allocproc>
    80002328:	84aa                	mv	s1,a0
  initproc = p;
    8000232a:	00007797          	auipc	a5,0x7
    8000232e:	cea7bf23          	sd	a0,-770(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002332:	03400613          	li	a2,52
    80002336:	00007597          	auipc	a1,0x7
    8000233a:	8ca58593          	addi	a1,a1,-1846 # 80008c00 <initcode>
    8000233e:	6928                	ld	a0,80(a0)
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	028080e7          	jalr	40(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80002348:	6785                	lui	a5,0x1
    8000234a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    8000234c:	6cb8                	ld	a4,88(s1)
    8000234e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002352:	6cb8                	ld	a4,88(s1)
    80002354:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002356:	4641                	li	a2,16
    80002358:	00006597          	auipc	a1,0x6
    8000235c:	0a858593          	addi	a1,a1,168 # 80008400 <digits+0x3c0>
    80002360:	15848513          	addi	a0,s1,344
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	ace080e7          	jalr	-1330(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    8000236c:	00006517          	auipc	a0,0x6
    80002370:	0a450513          	addi	a0,a0,164 # 80008410 <digits+0x3d0>
    80002374:	00002097          	auipc	ra,0x2
    80002378:	5c2080e7          	jalr	1474(ra) # 80004936 <namei>
    8000237c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80002380:	478d                	li	a5,3
    80002382:	cc9c                	sw	a5,24(s1)
  printf("insert userinit runnable %d\n", p->index); //delete
    80002384:	16c4a583          	lw	a1,364(s1)
    80002388:	00006517          	auipc	a0,0x6
    8000238c:	09050513          	addi	a0,a0,144 # 80008418 <digits+0x3d8>
    80002390:	ffffe097          	auipc	ra,0xffffe
    80002394:	1f8080e7          	jalr	504(ra) # 80000588 <printf>
  insert_proc_to_list(&(cpus[0].runnable_list), p); // admit the init process (the first process in the OS) to the first CPU’s list.
    80002398:	85a6                	mv	a1,s1
    8000239a:	0000f517          	auipc	a0,0xf
    8000239e:	f8650513          	addi	a0,a0,-122 # 80011320 <cpus+0x80>
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	6cc080e7          	jalr	1740(ra) # 80001a6e <insert_proc_to_list>
  release(&p->lock);
    800023aa:	8526                	mv	a0,s1
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	8ec080e7          	jalr	-1812(ra) # 80000c98 <release>
}
    800023b4:	60e2                	ld	ra,24(sp)
    800023b6:	6442                	ld	s0,16(sp)
    800023b8:	64a2                	ld	s1,8(sp)
    800023ba:	6105                	addi	sp,sp,32
    800023bc:	8082                	ret

00000000800023be <growproc>:
{
    800023be:	1101                	addi	sp,sp,-32
    800023c0:	ec06                	sd	ra,24(sp)
    800023c2:	e822                	sd	s0,16(sp)
    800023c4:	e426                	sd	s1,8(sp)
    800023c6:	e04a                	sd	s2,0(sp)
    800023c8:	1000                	addi	s0,sp,32
    800023ca:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800023cc:	00000097          	auipc	ra,0x0
    800023d0:	b82080e7          	jalr	-1150(ra) # 80001f4e <myproc>
    800023d4:	892a                	mv	s2,a0
  sz = p->sz;
    800023d6:	652c                	ld	a1,72(a0)
    800023d8:	0005861b          	sext.w	a2,a1
  if(n > 0){
    800023dc:	00904f63          	bgtz	s1,800023fa <growproc+0x3c>
  } else if(n < 0){
    800023e0:	0204cc63          	bltz	s1,80002418 <growproc+0x5a>
  p->sz = sz;
    800023e4:	1602                	slli	a2,a2,0x20
    800023e6:	9201                	srli	a2,a2,0x20
    800023e8:	04c93423          	sd	a2,72(s2)
  return 0;
    800023ec:	4501                	li	a0,0
}
    800023ee:	60e2                	ld	ra,24(sp)
    800023f0:	6442                	ld	s0,16(sp)
    800023f2:	64a2                	ld	s1,8(sp)
    800023f4:	6902                	ld	s2,0(sp)
    800023f6:	6105                	addi	sp,sp,32
    800023f8:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800023fa:	9e25                	addw	a2,a2,s1
    800023fc:	1602                	slli	a2,a2,0x20
    800023fe:	9201                	srli	a2,a2,0x20
    80002400:	1582                	slli	a1,a1,0x20
    80002402:	9181                	srli	a1,a1,0x20
    80002404:	6928                	ld	a0,80(a0)
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	01c080e7          	jalr	28(ra) # 80001422 <uvmalloc>
    8000240e:	0005061b          	sext.w	a2,a0
    80002412:	fa69                	bnez	a2,800023e4 <growproc+0x26>
      return -1;
    80002414:	557d                	li	a0,-1
    80002416:	bfe1                	j	800023ee <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002418:	9e25                	addw	a2,a2,s1
    8000241a:	1602                	slli	a2,a2,0x20
    8000241c:	9201                	srli	a2,a2,0x20
    8000241e:	1582                	slli	a1,a1,0x20
    80002420:	9181                	srli	a1,a1,0x20
    80002422:	6928                	ld	a0,80(a0)
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	fb6080e7          	jalr	-74(ra) # 800013da <uvmdealloc>
    8000242c:	0005061b          	sext.w	a2,a0
    80002430:	bf55                	j	800023e4 <growproc+0x26>

0000000080002432 <sched>:
{
    80002432:	7179                	addi	sp,sp,-48
    80002434:	f406                	sd	ra,40(sp)
    80002436:	f022                	sd	s0,32(sp)
    80002438:	ec26                	sd	s1,24(sp)
    8000243a:	e84a                	sd	s2,16(sp)
    8000243c:	e44e                	sd	s3,8(sp)
    8000243e:	e052                	sd	s4,0(sp)
    80002440:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002442:	00000097          	auipc	ra,0x0
    80002446:	b0c080e7          	jalr	-1268(ra) # 80001f4e <myproc>
    8000244a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000244c:	ffffe097          	auipc	ra,0xffffe
    80002450:	71e080e7          	jalr	1822(ra) # 80000b6a <holding>
    80002454:	c141                	beqz	a0,800024d4 <sched+0xa2>
    80002456:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002458:	2781                	sext.w	a5,a5
    8000245a:	0b000713          	li	a4,176
    8000245e:	02e787b3          	mul	a5,a5,a4
    80002462:	0000f717          	auipc	a4,0xf
    80002466:	e3e70713          	addi	a4,a4,-450 # 800112a0 <cpus>
    8000246a:	97ba                	add	a5,a5,a4
    8000246c:	5fb8                	lw	a4,120(a5)
    8000246e:	4785                	li	a5,1
    80002470:	06f71a63          	bne	a4,a5,800024e4 <sched+0xb2>
  if(p->state == RUNNING)
    80002474:	4c98                	lw	a4,24(s1)
    80002476:	4791                	li	a5,4
    80002478:	06f70e63          	beq	a4,a5,800024f4 <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000247c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002480:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002482:	e3c9                	bnez	a5,80002504 <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002484:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002486:	0000f917          	auipc	s2,0xf
    8000248a:	e1a90913          	addi	s2,s2,-486 # 800112a0 <cpus>
    8000248e:	2781                	sext.w	a5,a5
    80002490:	0b000993          	li	s3,176
    80002494:	033787b3          	mul	a5,a5,s3
    80002498:	97ca                	add	a5,a5,s2
    8000249a:	07c7aa03          	lw	s4,124(a5) # 107c <_entry-0x7fffef84>
    8000249e:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    800024a0:	2581                	sext.w	a1,a1
    800024a2:	033585b3          	mul	a1,a1,s3
    800024a6:	05a1                	addi	a1,a1,8
    800024a8:	95ca                	add	a1,a1,s2
    800024aa:	06048513          	addi	a0,s1,96
    800024ae:	00001097          	auipc	ra,0x1
    800024b2:	bf2080e7          	jalr	-1038(ra) # 800030a0 <swtch>
    800024b6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800024b8:	2781                	sext.w	a5,a5
    800024ba:	033787b3          	mul	a5,a5,s3
    800024be:	993e                	add	s2,s2,a5
    800024c0:	07492e23          	sw	s4,124(s2)
}
    800024c4:	70a2                	ld	ra,40(sp)
    800024c6:	7402                	ld	s0,32(sp)
    800024c8:	64e2                	ld	s1,24(sp)
    800024ca:	6942                	ld	s2,16(sp)
    800024cc:	69a2                	ld	s3,8(sp)
    800024ce:	6a02                	ld	s4,0(sp)
    800024d0:	6145                	addi	sp,sp,48
    800024d2:	8082                	ret
    panic("sched p->lock");
    800024d4:	00006517          	auipc	a0,0x6
    800024d8:	f6450513          	addi	a0,a0,-156 # 80008438 <digits+0x3f8>
    800024dc:	ffffe097          	auipc	ra,0xffffe
    800024e0:	062080e7          	jalr	98(ra) # 8000053e <panic>
    panic("sched locks");
    800024e4:	00006517          	auipc	a0,0x6
    800024e8:	f6450513          	addi	a0,a0,-156 # 80008448 <digits+0x408>
    800024ec:	ffffe097          	auipc	ra,0xffffe
    800024f0:	052080e7          	jalr	82(ra) # 8000053e <panic>
    panic("sched running");
    800024f4:	00006517          	auipc	a0,0x6
    800024f8:	f6450513          	addi	a0,a0,-156 # 80008458 <digits+0x418>
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	042080e7          	jalr	66(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002504:	00006517          	auipc	a0,0x6
    80002508:	f6450513          	addi	a0,a0,-156 # 80008468 <digits+0x428>
    8000250c:	ffffe097          	auipc	ra,0xffffe
    80002510:	032080e7          	jalr	50(ra) # 8000053e <panic>

0000000080002514 <yield>:
{
    80002514:	1101                	addi	sp,sp,-32
    80002516:	ec06                	sd	ra,24(sp)
    80002518:	e822                	sd	s0,16(sp)
    8000251a:	e426                	sd	s1,8(sp)
    8000251c:	e04a                	sd	s2,0(sp)
    8000251e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002520:	00000097          	auipc	ra,0x0
    80002524:	a2e080e7          	jalr	-1490(ra) # 80001f4e <myproc>
    80002528:	84aa                	mv	s1,a0
    8000252a:	8912                	mv	s2,tp
  acquire(&p->lock);
    8000252c:	ffffe097          	auipc	ra,0xffffe
    80002530:	6b8080e7          	jalr	1720(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002534:	478d                	li	a5,3
    80002536:	cc9c                	sw	a5,24(s1)
  printf("insert yield runnable %d\n", p->index); //delete
    80002538:	16c4a583          	lw	a1,364(s1)
    8000253c:	00006517          	auipc	a0,0x6
    80002540:	f4450513          	addi	a0,a0,-188 # 80008480 <digits+0x440>
    80002544:	ffffe097          	auipc	ra,0xffffe
    80002548:	044080e7          	jalr	68(ra) # 80000588 <printf>
  insert_proc_to_list(&(c->runnable_list), p); // TODO: check
    8000254c:	2901                	sext.w	s2,s2
    8000254e:	0b000513          	li	a0,176
    80002552:	02a90933          	mul	s2,s2,a0
    80002556:	85a6                	mv	a1,s1
    80002558:	0000f517          	auipc	a0,0xf
    8000255c:	dc850513          	addi	a0,a0,-568 # 80011320 <cpus+0x80>
    80002560:	954a                	add	a0,a0,s2
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	50c080e7          	jalr	1292(ra) # 80001a6e <insert_proc_to_list>
  sched();
    8000256a:	00000097          	auipc	ra,0x0
    8000256e:	ec8080e7          	jalr	-312(ra) # 80002432 <sched>
  release(&p->lock);
    80002572:	8526                	mv	a0,s1
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	724080e7          	jalr	1828(ra) # 80000c98 <release>
}
    8000257c:	60e2                	ld	ra,24(sp)
    8000257e:	6442                	ld	s0,16(sp)
    80002580:	64a2                	ld	s1,8(sp)
    80002582:	6902                	ld	s2,0(sp)
    80002584:	6105                	addi	sp,sp,32
    80002586:	8082                	ret

0000000080002588 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002588:	7179                	addi	sp,sp,-48
    8000258a:	f406                	sd	ra,40(sp)
    8000258c:	f022                	sd	s0,32(sp)
    8000258e:	ec26                	sd	s1,24(sp)
    80002590:	e84a                	sd	s2,16(sp)
    80002592:	e44e                	sd	s3,8(sp)
    80002594:	1800                	addi	s0,sp,48
    80002596:	89aa                	mv	s3,a0
    80002598:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000259a:	00000097          	auipc	ra,0x0
    8000259e:	9b4080e7          	jalr	-1612(ra) # 80001f4e <myproc>
    800025a2:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	640080e7          	jalr	1600(ra) # 80000be4 <acquire>
  printf("insert sleep sleep %d\n", p->index); //delete
    800025ac:	16c4a583          	lw	a1,364(s1)
    800025b0:	00006517          	auipc	a0,0x6
    800025b4:	ef050513          	addi	a0,a0,-272 # 800084a0 <digits+0x460>
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	fd0080e7          	jalr	-48(ra) # 80000588 <printf>
  insert_proc_to_list(&sleeping_list, p);
    800025c0:	85a6                	mv	a1,s1
    800025c2:	00006517          	auipc	a0,0x6
    800025c6:	5fe50513          	addi	a0,a0,1534 # 80008bc0 <sleeping_list>
    800025ca:	fffff097          	auipc	ra,0xfffff
    800025ce:	4a4080e7          	jalr	1188(ra) # 80001a6e <insert_proc_to_list>
  release(lk);
    800025d2:	854a                	mv	a0,s2
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	6c4080e7          	jalr	1732(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800025dc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800025e0:	4789                	li	a5,2
    800025e2:	cc9c                	sw	a5,24(s1)

  sched();
    800025e4:	00000097          	auipc	ra,0x0
    800025e8:	e4e080e7          	jalr	-434(ra) # 80002432 <sched>

  // Tidy up.
  p->chan = 0;
    800025ec:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800025f0:	8526                	mv	a0,s1
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	6a6080e7          	jalr	1702(ra) # 80000c98 <release>
  acquire(lk);
    800025fa:	854a                	mv	a0,s2
    800025fc:	ffffe097          	auipc	ra,0xffffe
    80002600:	5e8080e7          	jalr	1512(ra) # 80000be4 <acquire>
}
    80002604:	70a2                	ld	ra,40(sp)
    80002606:	7402                	ld	s0,32(sp)
    80002608:	64e2                	ld	s1,24(sp)
    8000260a:	6942                	ld	s2,16(sp)
    8000260c:	69a2                	ld	s3,8(sp)
    8000260e:	6145                	addi	sp,sp,48
    80002610:	8082                	ret

0000000080002612 <wait>:
{
    80002612:	715d                	addi	sp,sp,-80
    80002614:	e486                	sd	ra,72(sp)
    80002616:	e0a2                	sd	s0,64(sp)
    80002618:	fc26                	sd	s1,56(sp)
    8000261a:	f84a                	sd	s2,48(sp)
    8000261c:	f44e                	sd	s3,40(sp)
    8000261e:	f052                	sd	s4,32(sp)
    80002620:	ec56                	sd	s5,24(sp)
    80002622:	e85a                	sd	s6,16(sp)
    80002624:	e45e                	sd	s7,8(sp)
    80002626:	e062                	sd	s8,0(sp)
    80002628:	0880                	addi	s0,sp,80
    8000262a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000262c:	00000097          	auipc	ra,0x0
    80002630:	922080e7          	jalr	-1758(ra) # 80001f4e <myproc>
    80002634:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002636:	0000f517          	auipc	a0,0xf
    8000263a:	20250513          	addi	a0,a0,514 # 80011838 <wait_lock>
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	5a6080e7          	jalr	1446(ra) # 80000be4 <acquire>
    havekids = 0;
    80002646:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002648:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000264a:	00015997          	auipc	s3,0x15
    8000264e:	60698993          	addi	s3,s3,1542 # 80017c50 <tickslock>
        havekids = 1;
    80002652:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002654:	0000fc17          	auipc	s8,0xf
    80002658:	1e4c0c13          	addi	s8,s8,484 # 80011838 <wait_lock>
    havekids = 0;
    8000265c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000265e:	0000f497          	auipc	s1,0xf
    80002662:	1f248493          	addi	s1,s1,498 # 80011850 <proc>
    80002666:	a0bd                	j	800026d4 <wait+0xc2>
          pid = np->pid;
    80002668:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000266c:	000b0e63          	beqz	s6,80002688 <wait+0x76>
    80002670:	4691                	li	a3,4
    80002672:	02c48613          	addi	a2,s1,44
    80002676:	85da                	mv	a1,s6
    80002678:	05093503          	ld	a0,80(s2)
    8000267c:	fffff097          	auipc	ra,0xfffff
    80002680:	ff6080e7          	jalr	-10(ra) # 80001672 <copyout>
    80002684:	02054563          	bltz	a0,800026ae <wait+0x9c>
          freeproc(np);
    80002688:	8526                	mv	a0,s1
    8000268a:	00000097          	auipc	ra,0x0
    8000268e:	a70080e7          	jalr	-1424(ra) # 800020fa <freeproc>
          release(&np->lock);
    80002692:	8526                	mv	a0,s1
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	604080e7          	jalr	1540(ra) # 80000c98 <release>
          release(&wait_lock);
    8000269c:	0000f517          	auipc	a0,0xf
    800026a0:	19c50513          	addi	a0,a0,412 # 80011838 <wait_lock>
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	5f4080e7          	jalr	1524(ra) # 80000c98 <release>
          return pid;
    800026ac:	a09d                	j	80002712 <wait+0x100>
            release(&np->lock);
    800026ae:	8526                	mv	a0,s1
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	5e8080e7          	jalr	1512(ra) # 80000c98 <release>
            release(&wait_lock);
    800026b8:	0000f517          	auipc	a0,0xf
    800026bc:	18050513          	addi	a0,a0,384 # 80011838 <wait_lock>
    800026c0:	ffffe097          	auipc	ra,0xffffe
    800026c4:	5d8080e7          	jalr	1496(ra) # 80000c98 <release>
            return -1;
    800026c8:	59fd                	li	s3,-1
    800026ca:	a0a1                	j	80002712 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800026cc:	19048493          	addi	s1,s1,400
    800026d0:	03348463          	beq	s1,s3,800026f8 <wait+0xe6>
      if(np->parent == p){
    800026d4:	7c9c                	ld	a5,56(s1)
    800026d6:	ff279be3          	bne	a5,s2,800026cc <wait+0xba>
        acquire(&np->lock);
    800026da:	8526                	mv	a0,s1
    800026dc:	ffffe097          	auipc	ra,0xffffe
    800026e0:	508080e7          	jalr	1288(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800026e4:	4c9c                	lw	a5,24(s1)
    800026e6:	f94781e3          	beq	a5,s4,80002668 <wait+0x56>
        release(&np->lock);
    800026ea:	8526                	mv	a0,s1
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	5ac080e7          	jalr	1452(ra) # 80000c98 <release>
        havekids = 1;
    800026f4:	8756                	mv	a4,s5
    800026f6:	bfd9                	j	800026cc <wait+0xba>
    if(!havekids || p->killed){
    800026f8:	c701                	beqz	a4,80002700 <wait+0xee>
    800026fa:	02892783          	lw	a5,40(s2)
    800026fe:	c79d                	beqz	a5,8000272c <wait+0x11a>
      release(&wait_lock);
    80002700:	0000f517          	auipc	a0,0xf
    80002704:	13850513          	addi	a0,a0,312 # 80011838 <wait_lock>
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	590080e7          	jalr	1424(ra) # 80000c98 <release>
      return -1;
    80002710:	59fd                	li	s3,-1
}
    80002712:	854e                	mv	a0,s3
    80002714:	60a6                	ld	ra,72(sp)
    80002716:	6406                	ld	s0,64(sp)
    80002718:	74e2                	ld	s1,56(sp)
    8000271a:	7942                	ld	s2,48(sp)
    8000271c:	79a2                	ld	s3,40(sp)
    8000271e:	7a02                	ld	s4,32(sp)
    80002720:	6ae2                	ld	s5,24(sp)
    80002722:	6b42                	ld	s6,16(sp)
    80002724:	6ba2                	ld	s7,8(sp)
    80002726:	6c02                	ld	s8,0(sp)
    80002728:	6161                	addi	sp,sp,80
    8000272a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000272c:	85e2                	mv	a1,s8
    8000272e:	854a                	mv	a0,s2
    80002730:	00000097          	auipc	ra,0x0
    80002734:	e58080e7          	jalr	-424(ra) # 80002588 <sleep>
    havekids = 0;
    80002738:	b715                	j	8000265c <wait+0x4a>

000000008000273a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000273a:	7179                	addi	sp,sp,-48
    8000273c:	f406                	sd	ra,40(sp)
    8000273e:	f022                	sd	s0,32(sp)
    80002740:	ec26                	sd	s1,24(sp)
    80002742:	e84a                	sd	s2,16(sp)
    80002744:	e44e                	sd	s3,8(sp)
    80002746:	1800                	addi	s0,sp,48
    80002748:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000274a:	0000f497          	auipc	s1,0xf
    8000274e:	10648493          	addi	s1,s1,262 # 80011850 <proc>
    80002752:	00015997          	auipc	s3,0x15
    80002756:	4fe98993          	addi	s3,s3,1278 # 80017c50 <tickslock>
    acquire(&p->lock);
    8000275a:	8526                	mv	a0,s1
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	488080e7          	jalr	1160(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002764:	589c                	lw	a5,48(s1)
    80002766:	01278d63          	beq	a5,s2,80002780 <kill+0x46>
        insert_proc_to_list(&cpus[p->last_cpu].runnable_list, p);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000276a:	8526                	mv	a0,s1
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	52c080e7          	jalr	1324(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002774:	19048493          	addi	s1,s1,400
    80002778:	ff3491e3          	bne	s1,s3,8000275a <kill+0x20>
  }
  return -1;
    8000277c:	557d                	li	a0,-1
    8000277e:	a829                	j	80002798 <kill+0x5e>
      p->killed = 1;
    80002780:	4785                	li	a5,1
    80002782:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002784:	4c98                	lw	a4,24(s1)
    80002786:	4789                	li	a5,2
    80002788:	00f70f63          	beq	a4,a5,800027a6 <kill+0x6c>
      release(&p->lock);
    8000278c:	8526                	mv	a0,s1
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	50a080e7          	jalr	1290(ra) # 80000c98 <release>
      return 0;
    80002796:	4501                	li	a0,0
}
    80002798:	70a2                	ld	ra,40(sp)
    8000279a:	7402                	ld	s0,32(sp)
    8000279c:	64e2                	ld	s1,24(sp)
    8000279e:	6942                	ld	s2,16(sp)
    800027a0:	69a2                	ld	s3,8(sp)
    800027a2:	6145                	addi	sp,sp,48
    800027a4:	8082                	ret
        p->state = RUNNABLE;
    800027a6:	478d                	li	a5,3
    800027a8:	cc9c                	sw	a5,24(s1)
        printf("remove kill sleep %d\n", p->index); //delete
    800027aa:	16c4a583          	lw	a1,364(s1)
    800027ae:	00006517          	auipc	a0,0x6
    800027b2:	d0a50513          	addi	a0,a0,-758 # 800084b8 <digits+0x478>
    800027b6:	ffffe097          	auipc	ra,0xffffe
    800027ba:	dd2080e7          	jalr	-558(ra) # 80000588 <printf>
        remove_proc_to_list(&sleeping_list, p);
    800027be:	85a6                	mv	a1,s1
    800027c0:	00006517          	auipc	a0,0x6
    800027c4:	40050513          	addi	a0,a0,1024 # 80008bc0 <sleeping_list>
    800027c8:	fffff097          	auipc	ra,0xfffff
    800027cc:	434080e7          	jalr	1076(ra) # 80001bfc <remove_proc_to_list>
        printf("insert kill runnable %d\n", p->index); //delete
    800027d0:	16c4a583          	lw	a1,364(s1)
    800027d4:	00006517          	auipc	a0,0x6
    800027d8:	cfc50513          	addi	a0,a0,-772 # 800084d0 <digits+0x490>
    800027dc:	ffffe097          	auipc	ra,0xffffe
    800027e0:	dac080e7          	jalr	-596(ra) # 80000588 <printf>
        insert_proc_to_list(&cpus[p->last_cpu].runnable_list, p);
    800027e4:	1684a783          	lw	a5,360(s1)
    800027e8:	0b000713          	li	a4,176
    800027ec:	02e787b3          	mul	a5,a5,a4
    800027f0:	85a6                	mv	a1,s1
    800027f2:	0000f517          	auipc	a0,0xf
    800027f6:	b2e50513          	addi	a0,a0,-1234 # 80011320 <cpus+0x80>
    800027fa:	953e                	add	a0,a0,a5
    800027fc:	fffff097          	auipc	ra,0xfffff
    80002800:	272080e7          	jalr	626(ra) # 80001a6e <insert_proc_to_list>
    80002804:	b761                	j	8000278c <kill+0x52>

0000000080002806 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002806:	7179                	addi	sp,sp,-48
    80002808:	f406                	sd	ra,40(sp)
    8000280a:	f022                	sd	s0,32(sp)
    8000280c:	ec26                	sd	s1,24(sp)
    8000280e:	e84a                	sd	s2,16(sp)
    80002810:	e44e                	sd	s3,8(sp)
    80002812:	e052                	sd	s4,0(sp)
    80002814:	1800                	addi	s0,sp,48
    80002816:	84aa                	mv	s1,a0
    80002818:	892e                	mv	s2,a1
    8000281a:	89b2                	mv	s3,a2
    8000281c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000281e:	fffff097          	auipc	ra,0xfffff
    80002822:	730080e7          	jalr	1840(ra) # 80001f4e <myproc>
  if(user_dst){
    80002826:	c08d                	beqz	s1,80002848 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002828:	86d2                	mv	a3,s4
    8000282a:	864e                	mv	a2,s3
    8000282c:	85ca                	mv	a1,s2
    8000282e:	6928                	ld	a0,80(a0)
    80002830:	fffff097          	auipc	ra,0xfffff
    80002834:	e42080e7          	jalr	-446(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002838:	70a2                	ld	ra,40(sp)
    8000283a:	7402                	ld	s0,32(sp)
    8000283c:	64e2                	ld	s1,24(sp)
    8000283e:	6942                	ld	s2,16(sp)
    80002840:	69a2                	ld	s3,8(sp)
    80002842:	6a02                	ld	s4,0(sp)
    80002844:	6145                	addi	sp,sp,48
    80002846:	8082                	ret
    memmove((char *)dst, src, len);
    80002848:	000a061b          	sext.w	a2,s4
    8000284c:	85ce                	mv	a1,s3
    8000284e:	854a                	mv	a0,s2
    80002850:	ffffe097          	auipc	ra,0xffffe
    80002854:	4f0080e7          	jalr	1264(ra) # 80000d40 <memmove>
    return 0;
    80002858:	8526                	mv	a0,s1
    8000285a:	bff9                	j	80002838 <either_copyout+0x32>

000000008000285c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000285c:	7179                	addi	sp,sp,-48
    8000285e:	f406                	sd	ra,40(sp)
    80002860:	f022                	sd	s0,32(sp)
    80002862:	ec26                	sd	s1,24(sp)
    80002864:	e84a                	sd	s2,16(sp)
    80002866:	e44e                	sd	s3,8(sp)
    80002868:	e052                	sd	s4,0(sp)
    8000286a:	1800                	addi	s0,sp,48
    8000286c:	892a                	mv	s2,a0
    8000286e:	84ae                	mv	s1,a1
    80002870:	89b2                	mv	s3,a2
    80002872:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002874:	fffff097          	auipc	ra,0xfffff
    80002878:	6da080e7          	jalr	1754(ra) # 80001f4e <myproc>
  if(user_src){
    8000287c:	c08d                	beqz	s1,8000289e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000287e:	86d2                	mv	a3,s4
    80002880:	864e                	mv	a2,s3
    80002882:	85ca                	mv	a1,s2
    80002884:	6928                	ld	a0,80(a0)
    80002886:	fffff097          	auipc	ra,0xfffff
    8000288a:	e78080e7          	jalr	-392(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000288e:	70a2                	ld	ra,40(sp)
    80002890:	7402                	ld	s0,32(sp)
    80002892:	64e2                	ld	s1,24(sp)
    80002894:	6942                	ld	s2,16(sp)
    80002896:	69a2                	ld	s3,8(sp)
    80002898:	6a02                	ld	s4,0(sp)
    8000289a:	6145                	addi	sp,sp,48
    8000289c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000289e:	000a061b          	sext.w	a2,s4
    800028a2:	85ce                	mv	a1,s3
    800028a4:	854a                	mv	a0,s2
    800028a6:	ffffe097          	auipc	ra,0xffffe
    800028aa:	49a080e7          	jalr	1178(ra) # 80000d40 <memmove>
    return 0;
    800028ae:	8526                	mv	a0,s1
    800028b0:	bff9                	j	8000288e <either_copyin+0x32>

00000000800028b2 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    800028b2:	715d                	addi	sp,sp,-80
    800028b4:	e486                	sd	ra,72(sp)
    800028b6:	e0a2                	sd	s0,64(sp)
    800028b8:	fc26                	sd	s1,56(sp)
    800028ba:	f84a                	sd	s2,48(sp)
    800028bc:	f44e                	sd	s3,40(sp)
    800028be:	f052                	sd	s4,32(sp)
    800028c0:	ec56                	sd	s5,24(sp)
    800028c2:	e85a                	sd	s6,16(sp)
    800028c4:	e45e                	sd	s7,8(sp)
    800028c6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800028c8:	00006517          	auipc	a0,0x6
    800028cc:	d2850513          	addi	a0,a0,-728 # 800085f0 <digits+0x5b0>
    800028d0:	ffffe097          	auipc	ra,0xffffe
    800028d4:	cb8080e7          	jalr	-840(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028d8:	0000f497          	auipc	s1,0xf
    800028dc:	0d048493          	addi	s1,s1,208 # 800119a8 <proc+0x158>
    800028e0:	00015917          	auipc	s2,0x15
    800028e4:	4c890913          	addi	s2,s2,1224 # 80017da8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028e8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    800028ea:	00006997          	auipc	s3,0x6
    800028ee:	c0698993          	addi	s3,s3,-1018 # 800084f0 <digits+0x4b0>
    printf("%d %s %s", p->pid, state, p->name);
    800028f2:	00006a97          	auipc	s5,0x6
    800028f6:	c06a8a93          	addi	s5,s5,-1018 # 800084f8 <digits+0x4b8>
    printf("\n");
    800028fa:	00006a17          	auipc	s4,0x6
    800028fe:	cf6a0a13          	addi	s4,s4,-778 # 800085f0 <digits+0x5b0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002902:	00006b97          	auipc	s7,0x6
    80002906:	d1eb8b93          	addi	s7,s7,-738 # 80008620 <states.1826>
    8000290a:	a00d                	j	8000292c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000290c:	ed86a583          	lw	a1,-296(a3)
    80002910:	8556                	mv	a0,s5
    80002912:	ffffe097          	auipc	ra,0xffffe
    80002916:	c76080e7          	jalr	-906(ra) # 80000588 <printf>
    printf("\n");
    8000291a:	8552                	mv	a0,s4
    8000291c:	ffffe097          	auipc	ra,0xffffe
    80002920:	c6c080e7          	jalr	-916(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002924:	19048493          	addi	s1,s1,400
    80002928:	03248163          	beq	s1,s2,8000294a <procdump+0x98>
    if(p->state == UNUSED)
    8000292c:	86a6                	mv	a3,s1
    8000292e:	ec04a783          	lw	a5,-320(s1)
    80002932:	dbed                	beqz	a5,80002924 <procdump+0x72>
      state = "???"; 
    80002934:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002936:	fcfb6be3          	bltu	s6,a5,8000290c <procdump+0x5a>
    8000293a:	1782                	slli	a5,a5,0x20
    8000293c:	9381                	srli	a5,a5,0x20
    8000293e:	078e                	slli	a5,a5,0x3
    80002940:	97de                	add	a5,a5,s7
    80002942:	6390                	ld	a2,0(a5)
    80002944:	f661                	bnez	a2,8000290c <procdump+0x5a>
      state = "???"; 
    80002946:	864e                	mv	a2,s3
    80002948:	b7d1                	j	8000290c <procdump+0x5a>
  }
}
    8000294a:	60a6                	ld	ra,72(sp)
    8000294c:	6406                	ld	s0,64(sp)
    8000294e:	74e2                	ld	s1,56(sp)
    80002950:	7942                	ld	s2,48(sp)
    80002952:	79a2                	ld	s3,40(sp)
    80002954:	7a02                	ld	s4,32(sp)
    80002956:	6ae2                	ld	s5,24(sp)
    80002958:	6b42                	ld	s6,16(sp)
    8000295a:	6ba2                	ld	s7,8(sp)
    8000295c:	6161                	addi	sp,sp,80
    8000295e:	8082                	ret

0000000080002960 <set_cpu>:

// assign current process to a different CPU. 
int
set_cpu(int cpu_num){
    80002960:	1101                	addi	sp,sp,-32
    80002962:	ec06                	sd	ra,24(sp)
    80002964:	e822                	sd	s0,16(sp)
    80002966:	e426                	sd	s1,8(sp)
    80002968:	e04a                	sd	s2,0(sp)
    8000296a:	1000                	addi	s0,sp,32
    8000296c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000296e:	fffff097          	auipc	ra,0xfffff
    80002972:	5e0080e7          	jalr	1504(ra) # 80001f4e <myproc>
  if(cpu_num >= 0 && cpu_num < CPUS){
    80002976:	0004871b          	sext.w	a4,s1
    8000297a:	4789                	li	a5,2
    8000297c:	02e7e963          	bltu	a5,a4,800029ae <set_cpu+0x4e>
    80002980:	892a                	mv	s2,a0
    acquire(&p->lock);
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	262080e7          	jalr	610(ra) # 80000be4 <acquire>
    p->last_cpu = cpu_num;
    8000298a:	16992423          	sw	s1,360(s2)
    release(&p->lock);
    8000298e:	854a                	mv	a0,s2
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	308080e7          	jalr	776(ra) # 80000c98 <release>

    yield();
    80002998:	00000097          	auipc	ra,0x0
    8000299c:	b7c080e7          	jalr	-1156(ra) # 80002514 <yield>

    return cpu_num;
    800029a0:	8526                	mv	a0,s1
  }
  return -1;
}
    800029a2:	60e2                	ld	ra,24(sp)
    800029a4:	6442                	ld	s0,16(sp)
    800029a6:	64a2                	ld	s1,8(sp)
    800029a8:	6902                	ld	s2,0(sp)
    800029aa:	6105                	addi	sp,sp,32
    800029ac:	8082                	ret
  return -1;
    800029ae:	557d                	li	a0,-1
    800029b0:	bfcd                	j	800029a2 <set_cpu+0x42>

00000000800029b2 <get_cpu>:

// return the current CPU id.
int
get_cpu(void){
    800029b2:	1141                	addi	sp,sp,-16
    800029b4:	e406                	sd	ra,8(sp)
    800029b6:	e022                	sd	s0,0(sp)
    800029b8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029ba:	fffff097          	auipc	ra,0xfffff
    800029be:	594080e7          	jalr	1428(ra) # 80001f4e <myproc>
  return p->last_cpu;
}
    800029c2:	16852503          	lw	a0,360(a0)
    800029c6:	60a2                	ld	ra,8(sp)
    800029c8:	6402                	ld	s0,0(sp)
    800029ca:	0141                	addi	sp,sp,16
    800029cc:	8082                	ret

00000000800029ce <min_cpu_process_count>:

int
min_cpu_process_count(void){
    800029ce:	1141                	addi	sp,sp,-16
    800029d0:	e422                	sd	s0,8(sp)
    800029d2:	0800                	addi	s0,sp,16
  struct cpu *c, *min_cpu;
  min_cpu = cpus;
    800029d4:	0000f617          	auipc	a2,0xf
    800029d8:	8cc60613          	addi	a2,a2,-1844 # 800112a0 <cpus>
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL && c->cpu_id<CPUS ; c++){
    800029dc:	0000f797          	auipc	a5,0xf
    800029e0:	97478793          	addi	a5,a5,-1676 # 80011350 <cpus+0xb0>
    800029e4:	4589                	li	a1,2
    800029e6:	0000f517          	auipc	a0,0xf
    800029ea:	e3a50513          	addi	a0,a0,-454 # 80011820 <pid_lock>
    800029ee:	a029                	j	800029f8 <min_cpu_process_count+0x2a>
    800029f0:	0b078793          	addi	a5,a5,176
    800029f4:	00a78c63          	beq	a5,a0,80002a0c <min_cpu_process_count+0x3e>
    800029f8:	0a07a703          	lw	a4,160(a5)
    800029fc:	00e5c863          	blt	a1,a4,80002a0c <min_cpu_process_count+0x3e>
    if (c->cpu_process_count < min_cpu->cpu_process_count)
    80002a00:	77d4                	ld	a3,168(a5)
    80002a02:	7658                	ld	a4,168(a2)
    80002a04:	fee6f6e3          	bgeu	a3,a4,800029f0 <min_cpu_process_count+0x22>
    80002a08:	863e                	mv	a2,a5
    80002a0a:	b7dd                	j	800029f0 <min_cpu_process_count+0x22>
      min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    80002a0c:	0a062503          	lw	a0,160(a2)
    80002a10:	6422                	ld	s0,8(sp)
    80002a12:	0141                	addi	sp,sp,16
    80002a14:	8082                	ret

0000000080002a16 <cpu_process_count>:

int
cpu_process_count(int cpu_num){
    80002a16:	1141                	addi	sp,sp,-16
    80002a18:	e422                	sd	s0,8(sp)
    80002a1a:	0800                	addi	s0,sp,16
  if (cpu_num > 0 && cpu_num < CPUS && &cpus[cpu_num] != NULL) 
    80002a1c:	fff5071b          	addiw	a4,a0,-1
    80002a20:	4785                	li	a5,1
    80002a22:	02e7e063          	bltu	a5,a4,80002a42 <cpu_process_count+0x2c>
    return cpus[cpu_num].cpu_process_count;
    80002a26:	0b000793          	li	a5,176
    80002a2a:	02f50533          	mul	a0,a0,a5
    80002a2e:	0000f797          	auipc	a5,0xf
    80002a32:	87278793          	addi	a5,a5,-1934 # 800112a0 <cpus>
    80002a36:	953e                	add	a0,a0,a5
    80002a38:	0a852503          	lw	a0,168(a0)
  return -1;
}
    80002a3c:	6422                	ld	s0,8(sp)
    80002a3e:	0141                	addi	sp,sp,16
    80002a40:	8082                	ret
  return -1;
    80002a42:	557d                	li	a0,-1
    80002a44:	bfe5                	j	80002a3c <cpu_process_count+0x26>

0000000080002a46 <increment_cpu_process_count>:

void 
increment_cpu_process_count(struct cpu *c){
    80002a46:	1101                	addi	sp,sp,-32
    80002a48:	ec06                	sd	ra,24(sp)
    80002a4a:	e822                	sd	s0,16(sp)
    80002a4c:	e426                	sd	s1,8(sp)
    80002a4e:	e04a                	sd	s2,0(sp)
    80002a50:	1000                	addi	s0,sp,32
    80002a52:	84aa                	mv	s1,a0
  uint64 curr_count;
  do{
    curr_count = c->cpu_process_count;
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    80002a54:	0a850913          	addi	s2,a0,168
    curr_count = c->cpu_process_count;
    80002a58:	74cc                	ld	a1,168(s1)
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    80002a5a:	0015861b          	addiw	a2,a1,1
    80002a5e:	2581                	sext.w	a1,a1
    80002a60:	854a                	mv	a0,s2
    80002a62:	00004097          	auipc	ra,0x4
    80002a66:	2b4080e7          	jalr	692(ra) # 80006d16 <cas>
    80002a6a:	2501                	sext.w	a0,a0
    80002a6c:	f575                	bnez	a0,80002a58 <increment_cpu_process_count+0x12>
}
    80002a6e:	60e2                	ld	ra,24(sp)
    80002a70:	6442                	ld	s0,16(sp)
    80002a72:	64a2                	ld	s1,8(sp)
    80002a74:	6902                	ld	s2,0(sp)
    80002a76:	6105                	addi	sp,sp,32
    80002a78:	8082                	ret

0000000080002a7a <fork>:
{
    80002a7a:	7139                	addi	sp,sp,-64
    80002a7c:	fc06                	sd	ra,56(sp)
    80002a7e:	f822                	sd	s0,48(sp)
    80002a80:	f426                	sd	s1,40(sp)
    80002a82:	f04a                	sd	s2,32(sp)
    80002a84:	ec4e                	sd	s3,24(sp)
    80002a86:	e852                	sd	s4,16(sp)
    80002a88:	e456                	sd	s5,8(sp)
    80002a8a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002a8c:	fffff097          	auipc	ra,0xfffff
    80002a90:	4c2080e7          	jalr	1218(ra) # 80001f4e <myproc>
    80002a94:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002a96:	fffff097          	auipc	ra,0xfffff
    80002a9a:	708080e7          	jalr	1800(ra) # 8000219e <allocproc>
    80002a9e:	16050663          	beqz	a0,80002c0a <fork+0x190>
    80002aa2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002aa4:	04893603          	ld	a2,72(s2)
    80002aa8:	692c                	ld	a1,80(a0)
    80002aaa:	05093503          	ld	a0,80(s2)
    80002aae:	fffff097          	auipc	ra,0xfffff
    80002ab2:	ac0080e7          	jalr	-1344(ra) # 8000156e <uvmcopy>
    80002ab6:	04054663          	bltz	a0,80002b02 <fork+0x88>
  np->sz = p->sz;
    80002aba:	04893783          	ld	a5,72(s2)
    80002abe:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80002ac2:	05893683          	ld	a3,88(s2)
    80002ac6:	87b6                	mv	a5,a3
    80002ac8:	0589b703          	ld	a4,88(s3)
    80002acc:	12068693          	addi	a3,a3,288
    80002ad0:	0007b803          	ld	a6,0(a5)
    80002ad4:	6788                	ld	a0,8(a5)
    80002ad6:	6b8c                	ld	a1,16(a5)
    80002ad8:	6f90                	ld	a2,24(a5)
    80002ada:	01073023          	sd	a6,0(a4)
    80002ade:	e708                	sd	a0,8(a4)
    80002ae0:	eb0c                	sd	a1,16(a4)
    80002ae2:	ef10                	sd	a2,24(a4)
    80002ae4:	02078793          	addi	a5,a5,32
    80002ae8:	02070713          	addi	a4,a4,32
    80002aec:	fed792e3          	bne	a5,a3,80002ad0 <fork+0x56>
  np->trapframe->a0 = 0;
    80002af0:	0589b783          	ld	a5,88(s3)
    80002af4:	0607b823          	sd	zero,112(a5)
    80002af8:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002afc:	15000a13          	li	s4,336
    80002b00:	a03d                	j	80002b2e <fork+0xb4>
    freeproc(np);
    80002b02:	854e                	mv	a0,s3
    80002b04:	fffff097          	auipc	ra,0xfffff
    80002b08:	5f6080e7          	jalr	1526(ra) # 800020fa <freeproc>
    release(&np->lock);
    80002b0c:	854e                	mv	a0,s3
    80002b0e:	ffffe097          	auipc	ra,0xffffe
    80002b12:	18a080e7          	jalr	394(ra) # 80000c98 <release>
    return -1;
    80002b16:	5afd                	li	s5,-1
    80002b18:	a8f9                	j	80002bf6 <fork+0x17c>
      np->ofile[i] = filedup(p->ofile[i]);
    80002b1a:	00002097          	auipc	ra,0x2
    80002b1e:	4b2080e7          	jalr	1202(ra) # 80004fcc <filedup>
    80002b22:	009987b3          	add	a5,s3,s1
    80002b26:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002b28:	04a1                	addi	s1,s1,8
    80002b2a:	01448763          	beq	s1,s4,80002b38 <fork+0xbe>
    if(p->ofile[i])
    80002b2e:	009907b3          	add	a5,s2,s1
    80002b32:	6388                	ld	a0,0(a5)
    80002b34:	f17d                	bnez	a0,80002b1a <fork+0xa0>
    80002b36:	bfcd                	j	80002b28 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002b38:	15093503          	ld	a0,336(s2)
    80002b3c:	00001097          	auipc	ra,0x1
    80002b40:	606080e7          	jalr	1542(ra) # 80004142 <idup>
    80002b44:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002b48:	4641                	li	a2,16
    80002b4a:	15890593          	addi	a1,s2,344
    80002b4e:	15898513          	addi	a0,s3,344
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	2e0080e7          	jalr	736(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002b5a:	0309aa83          	lw	s5,48(s3)
  release(&np->lock);
    80002b5e:	854e                	mv	a0,s3
    80002b60:	ffffe097          	auipc	ra,0xffffe
    80002b64:	138080e7          	jalr	312(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002b68:	0000ea17          	auipc	s4,0xe
    80002b6c:	738a0a13          	addi	s4,s4,1848 # 800112a0 <cpus>
    80002b70:	0000f497          	auipc	s1,0xf
    80002b74:	cc848493          	addi	s1,s1,-824 # 80011838 <wait_lock>
    80002b78:	8526                	mv	a0,s1
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	06a080e7          	jalr	106(ra) # 80000be4 <acquire>
  np->parent = p;
    80002b82:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80002b86:	8526                	mv	a0,s1
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	110080e7          	jalr	272(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002b90:	854e                	mv	a0,s3
    80002b92:	ffffe097          	auipc	ra,0xffffe
    80002b96:	052080e7          	jalr	82(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002b9a:	478d                	li	a5,3
    80002b9c:	00f9ac23          	sw	a5,24(s3)
  np->last_cpu = p->last_cpu; // case BLNCFLG=OFF -> cpu = parent's cpu 
    80002ba0:	16892783          	lw	a5,360(s2)
    80002ba4:	16f9a423          	sw	a5,360(s3)
      np->last_cpu = min_cpu_process_count(); // case BLNCFLG=ON -> cpu = CPU with the lowest counter value
    80002ba8:	00000097          	auipc	ra,0x0
    80002bac:	e26080e7          	jalr	-474(ra) # 800029ce <min_cpu_process_count>
    80002bb0:	16a9a423          	sw	a0,360(s3)
  struct cpu *c = &cpus[np->last_cpu];
    80002bb4:	0b000493          	li	s1,176
    80002bb8:	029504b3          	mul	s1,a0,s1
  increment_cpu_process_count(c);
    80002bbc:	009a0533          	add	a0,s4,s1
    80002bc0:	00000097          	auipc	ra,0x0
    80002bc4:	e86080e7          	jalr	-378(ra) # 80002a46 <increment_cpu_process_count>
  printf("insert fork runnable %d\n", p->index); //delete
    80002bc8:	16c92583          	lw	a1,364(s2)
    80002bcc:	00006517          	auipc	a0,0x6
    80002bd0:	93c50513          	addi	a0,a0,-1732 # 80008508 <digits+0x4c8>
    80002bd4:	ffffe097          	auipc	ra,0xffffe
    80002bd8:	9b4080e7          	jalr	-1612(ra) # 80000588 <printf>
  insert_proc_to_list(&(c->runnable_list), np); // admit the new process to the father’s current CPU’s ready list
    80002bdc:	08048513          	addi	a0,s1,128
    80002be0:	85ce                	mv	a1,s3
    80002be2:	9552                	add	a0,a0,s4
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	e8a080e7          	jalr	-374(ra) # 80001a6e <insert_proc_to_list>
  release(&np->lock);
    80002bec:	854e                	mv	a0,s3
    80002bee:	ffffe097          	auipc	ra,0xffffe
    80002bf2:	0aa080e7          	jalr	170(ra) # 80000c98 <release>
}
    80002bf6:	8556                	mv	a0,s5
    80002bf8:	70e2                	ld	ra,56(sp)
    80002bfa:	7442                	ld	s0,48(sp)
    80002bfc:	74a2                	ld	s1,40(sp)
    80002bfe:	7902                	ld	s2,32(sp)
    80002c00:	69e2                	ld	s3,24(sp)
    80002c02:	6a42                	ld	s4,16(sp)
    80002c04:	6aa2                	ld	s5,8(sp)
    80002c06:	6121                	addi	sp,sp,64
    80002c08:	8082                	ret
    return -1;
    80002c0a:	5afd                	li	s5,-1
    80002c0c:	b7ed                	j	80002bf6 <fork+0x17c>

0000000080002c0e <wakeup>:
{
    80002c0e:	7119                	addi	sp,sp,-128
    80002c10:	fc86                	sd	ra,120(sp)
    80002c12:	f8a2                	sd	s0,112(sp)
    80002c14:	f4a6                	sd	s1,104(sp)
    80002c16:	f0ca                	sd	s2,96(sp)
    80002c18:	ecce                	sd	s3,88(sp)
    80002c1a:	e8d2                	sd	s4,80(sp)
    80002c1c:	e4d6                	sd	s5,72(sp)
    80002c1e:	e0da                	sd	s6,64(sp)
    80002c20:	fc5e                	sd	s7,56(sp)
    80002c22:	f862                	sd	s8,48(sp)
    80002c24:	f466                	sd	s9,40(sp)
    80002c26:	f06a                	sd	s10,32(sp)
    80002c28:	ec6e                	sd	s11,24(sp)
    80002c2a:	0100                	addi	s0,sp,128
    80002c2c:	8baa                	mv	s7,a0
  int curr = get_head(&sleeping_list);
    80002c2e:	00006517          	auipc	a0,0x6
    80002c32:	f9250513          	addi	a0,a0,-110 # 80008bc0 <sleeping_list>
    80002c36:	fffff097          	auipc	ra,0xfffff
    80002c3a:	de2080e7          	jalr	-542(ra) # 80001a18 <get_head>
  while(curr != -1) {
    80002c3e:	57fd                	li	a5,-1
    80002c40:	0cf50b63          	beq	a0,a5,80002d16 <wakeup+0x108>
    80002c44:	892a                	mv	s2,a0
    p = &proc[curr];
    80002c46:	19000a93          	li	s5,400
    80002c4a:	0000fa17          	auipc	s4,0xf
    80002c4e:	c06a0a13          	addi	s4,s4,-1018 # 80011850 <proc>
      if(p->state == SLEEPING && p->chan == chan) {
    80002c52:	4b09                	li	s6,2
        remove_proc_to_list(&sleeping_list, p);
    80002c54:	00006c17          	auipc	s8,0x6
    80002c58:	f6cc0c13          	addi	s8,s8,-148 # 80008bc0 <sleeping_list>
        p->state = RUNNABLE;
    80002c5c:	4d8d                	li	s11,3
    80002c5e:	0b000d13          	li	s10,176
        c = &cpus[p->last_cpu];
    80002c62:	0000ec97          	auipc	s9,0xe
    80002c66:	63ec8c93          	addi	s9,s9,1598 # 800112a0 <cpus>
    80002c6a:	a809                	j	80002c7c <wakeup+0x6e>
      release(&p->lock);
    80002c6c:	8526                	mv	a0,s1
    80002c6e:	ffffe097          	auipc	ra,0xffffe
    80002c72:	02a080e7          	jalr	42(ra) # 80000c98 <release>
  while(curr != -1) {
    80002c76:	57fd                	li	a5,-1
    80002c78:	08f90f63          	beq	s2,a5,80002d16 <wakeup+0x108>
    p = &proc[curr];
    80002c7c:	035904b3          	mul	s1,s2,s5
    80002c80:	94d2                	add	s1,s1,s4
    curr = p->next_index;
    80002c82:	1744a903          	lw	s2,372(s1)
    if(p != myproc()){
    80002c86:	fffff097          	auipc	ra,0xfffff
    80002c8a:	2c8080e7          	jalr	712(ra) # 80001f4e <myproc>
    80002c8e:	fea484e3          	beq	s1,a0,80002c76 <wakeup+0x68>
      acquire(&p->lock);
    80002c92:	8526                	mv	a0,s1
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	f50080e7          	jalr	-176(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002c9c:	4c9c                	lw	a5,24(s1)
    80002c9e:	fd6797e3          	bne	a5,s6,80002c6c <wakeup+0x5e>
    80002ca2:	709c                	ld	a5,32(s1)
    80002ca4:	fd7794e3          	bne	a5,s7,80002c6c <wakeup+0x5e>
        printf("remove wakeup sleep %d\n", p->index); //delete
    80002ca8:	16c4a583          	lw	a1,364(s1)
    80002cac:	00006517          	auipc	a0,0x6
    80002cb0:	87c50513          	addi	a0,a0,-1924 # 80008528 <digits+0x4e8>
    80002cb4:	ffffe097          	auipc	ra,0xffffe
    80002cb8:	8d4080e7          	jalr	-1836(ra) # 80000588 <printf>
        remove_proc_to_list(&sleeping_list, p);
    80002cbc:	85a6                	mv	a1,s1
    80002cbe:	8562                	mv	a0,s8
    80002cc0:	fffff097          	auipc	ra,0xfffff
    80002cc4:	f3c080e7          	jalr	-196(ra) # 80001bfc <remove_proc_to_list>
        p->state = RUNNABLE;
    80002cc8:	01b4ac23          	sw	s11,24(s1)
            p->last_cpu = min_cpu_process_count(); // case BLNCFLG=ON -> cpu = CPU with the lowest counter value
    80002ccc:	00000097          	auipc	ra,0x0
    80002cd0:	d02080e7          	jalr	-766(ra) # 800029ce <min_cpu_process_count>
    80002cd4:	16a4a423          	sw	a0,360(s1)
        c = &cpus[p->last_cpu];
    80002cd8:	03a507b3          	mul	a5,a0,s10
        increment_cpu_process_count(c);
    80002cdc:	f8f43423          	sd	a5,-120(s0)
    80002ce0:	00fc8533          	add	a0,s9,a5
    80002ce4:	00000097          	auipc	ra,0x0
    80002ce8:	d62080e7          	jalr	-670(ra) # 80002a46 <increment_cpu_process_count>
        printf("insert wakeup runnable %d\n", p->index); //delete
    80002cec:	16c4a583          	lw	a1,364(s1)
    80002cf0:	00006517          	auipc	a0,0x6
    80002cf4:	85050513          	addi	a0,a0,-1968 # 80008540 <digits+0x500>
    80002cf8:	ffffe097          	auipc	ra,0xffffe
    80002cfc:	890080e7          	jalr	-1904(ra) # 80000588 <printf>
        insert_proc_to_list(&(c->runnable_list), p);
    80002d00:	f8843783          	ld	a5,-120(s0)
    80002d04:	08078513          	addi	a0,a5,128
    80002d08:	85a6                	mv	a1,s1
    80002d0a:	9566                	add	a0,a0,s9
    80002d0c:	fffff097          	auipc	ra,0xfffff
    80002d10:	d62080e7          	jalr	-670(ra) # 80001a6e <insert_proc_to_list>
    80002d14:	bfa1                	j	80002c6c <wakeup+0x5e>
}
    80002d16:	70e6                	ld	ra,120(sp)
    80002d18:	7446                	ld	s0,112(sp)
    80002d1a:	74a6                	ld	s1,104(sp)
    80002d1c:	7906                	ld	s2,96(sp)
    80002d1e:	69e6                	ld	s3,88(sp)
    80002d20:	6a46                	ld	s4,80(sp)
    80002d22:	6aa6                	ld	s5,72(sp)
    80002d24:	6b06                	ld	s6,64(sp)
    80002d26:	7be2                	ld	s7,56(sp)
    80002d28:	7c42                	ld	s8,48(sp)
    80002d2a:	7ca2                	ld	s9,40(sp)
    80002d2c:	7d02                	ld	s10,32(sp)
    80002d2e:	6de2                	ld	s11,24(sp)
    80002d30:	6109                	addi	sp,sp,128
    80002d32:	8082                	ret

0000000080002d34 <reparent>:
{
    80002d34:	7179                	addi	sp,sp,-48
    80002d36:	f406                	sd	ra,40(sp)
    80002d38:	f022                	sd	s0,32(sp)
    80002d3a:	ec26                	sd	s1,24(sp)
    80002d3c:	e84a                	sd	s2,16(sp)
    80002d3e:	e44e                	sd	s3,8(sp)
    80002d40:	e052                	sd	s4,0(sp)
    80002d42:	1800                	addi	s0,sp,48
    80002d44:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002d46:	0000f497          	auipc	s1,0xf
    80002d4a:	b0a48493          	addi	s1,s1,-1270 # 80011850 <proc>
      pp->parent = initproc;
    80002d4e:	00006a17          	auipc	s4,0x6
    80002d52:	2daa0a13          	addi	s4,s4,730 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002d56:	00015997          	auipc	s3,0x15
    80002d5a:	efa98993          	addi	s3,s3,-262 # 80017c50 <tickslock>
    80002d5e:	a029                	j	80002d68 <reparent+0x34>
    80002d60:	19048493          	addi	s1,s1,400
    80002d64:	01348d63          	beq	s1,s3,80002d7e <reparent+0x4a>
    if(pp->parent == p){
    80002d68:	7c9c                	ld	a5,56(s1)
    80002d6a:	ff279be3          	bne	a5,s2,80002d60 <reparent+0x2c>
      pp->parent = initproc;
    80002d6e:	000a3503          	ld	a0,0(s4)
    80002d72:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002d74:	00000097          	auipc	ra,0x0
    80002d78:	e9a080e7          	jalr	-358(ra) # 80002c0e <wakeup>
    80002d7c:	b7d5                	j	80002d60 <reparent+0x2c>
}
    80002d7e:	70a2                	ld	ra,40(sp)
    80002d80:	7402                	ld	s0,32(sp)
    80002d82:	64e2                	ld	s1,24(sp)
    80002d84:	6942                	ld	s2,16(sp)
    80002d86:	69a2                	ld	s3,8(sp)
    80002d88:	6a02                	ld	s4,0(sp)
    80002d8a:	6145                	addi	sp,sp,48
    80002d8c:	8082                	ret

0000000080002d8e <exit>:
{
    80002d8e:	7179                	addi	sp,sp,-48
    80002d90:	f406                	sd	ra,40(sp)
    80002d92:	f022                	sd	s0,32(sp)
    80002d94:	ec26                	sd	s1,24(sp)
    80002d96:	e84a                	sd	s2,16(sp)
    80002d98:	e44e                	sd	s3,8(sp)
    80002d9a:	e052                	sd	s4,0(sp)
    80002d9c:	1800                	addi	s0,sp,48
    80002d9e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002da0:	fffff097          	auipc	ra,0xfffff
    80002da4:	1ae080e7          	jalr	430(ra) # 80001f4e <myproc>
    80002da8:	89aa                	mv	s3,a0
  if(p == initproc)
    80002daa:	00006797          	auipc	a5,0x6
    80002dae:	27e7b783          	ld	a5,638(a5) # 80009028 <initproc>
    80002db2:	0d050493          	addi	s1,a0,208
    80002db6:	15050913          	addi	s2,a0,336
    80002dba:	02a79363          	bne	a5,a0,80002de0 <exit+0x52>
    panic("init exiting");
    80002dbe:	00005517          	auipc	a0,0x5
    80002dc2:	7a250513          	addi	a0,a0,1954 # 80008560 <digits+0x520>
    80002dc6:	ffffd097          	auipc	ra,0xffffd
    80002dca:	778080e7          	jalr	1912(ra) # 8000053e <panic>
      fileclose(f);
    80002dce:	00002097          	auipc	ra,0x2
    80002dd2:	250080e7          	jalr	592(ra) # 8000501e <fileclose>
      p->ofile[fd] = 0;
    80002dd6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002dda:	04a1                	addi	s1,s1,8
    80002ddc:	01248563          	beq	s1,s2,80002de6 <exit+0x58>
    if(p->ofile[fd]){
    80002de0:	6088                	ld	a0,0(s1)
    80002de2:	f575                	bnez	a0,80002dce <exit+0x40>
    80002de4:	bfdd                	j	80002dda <exit+0x4c>
  begin_op();
    80002de6:	00002097          	auipc	ra,0x2
    80002dea:	d6c080e7          	jalr	-660(ra) # 80004b52 <begin_op>
  iput(p->cwd);
    80002dee:	1509b503          	ld	a0,336(s3)
    80002df2:	00001097          	auipc	ra,0x1
    80002df6:	548080e7          	jalr	1352(ra) # 8000433a <iput>
  end_op();
    80002dfa:	00002097          	auipc	ra,0x2
    80002dfe:	dd8080e7          	jalr	-552(ra) # 80004bd2 <end_op>
  p->cwd = 0;
    80002e02:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002e06:	0000f497          	auipc	s1,0xf
    80002e0a:	a3248493          	addi	s1,s1,-1486 # 80011838 <wait_lock>
    80002e0e:	8526                	mv	a0,s1
    80002e10:	ffffe097          	auipc	ra,0xffffe
    80002e14:	dd4080e7          	jalr	-556(ra) # 80000be4 <acquire>
  reparent(p);
    80002e18:	854e                	mv	a0,s3
    80002e1a:	00000097          	auipc	ra,0x0
    80002e1e:	f1a080e7          	jalr	-230(ra) # 80002d34 <reparent>
  wakeup(p->parent);
    80002e22:	0389b503          	ld	a0,56(s3)
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	de8080e7          	jalr	-536(ra) # 80002c0e <wakeup>
  acquire(&p->lock);
    80002e2e:	854e                	mv	a0,s3
    80002e30:	ffffe097          	auipc	ra,0xffffe
    80002e34:	db4080e7          	jalr	-588(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002e38:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002e3c:	4795                	li	a5,5
    80002e3e:	00f9ac23          	sw	a5,24(s3)
  printf("insert exit zombie %d\n", p->index); //delete
    80002e42:	16c9a583          	lw	a1,364(s3)
    80002e46:	00005517          	auipc	a0,0x5
    80002e4a:	72a50513          	addi	a0,a0,1834 # 80008570 <digits+0x530>
    80002e4e:	ffffd097          	auipc	ra,0xffffd
    80002e52:	73a080e7          	jalr	1850(ra) # 80000588 <printf>
  insert_proc_to_list(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    80002e56:	85ce                	mv	a1,s3
    80002e58:	00006517          	auipc	a0,0x6
    80002e5c:	d8850513          	addi	a0,a0,-632 # 80008be0 <zombie_list>
    80002e60:	fffff097          	auipc	ra,0xfffff
    80002e64:	c0e080e7          	jalr	-1010(ra) # 80001a6e <insert_proc_to_list>
  release(&wait_lock);
    80002e68:	8526                	mv	a0,s1
    80002e6a:	ffffe097          	auipc	ra,0xffffe
    80002e6e:	e2e080e7          	jalr	-466(ra) # 80000c98 <release>
  sched();
    80002e72:	fffff097          	auipc	ra,0xfffff
    80002e76:	5c0080e7          	jalr	1472(ra) # 80002432 <sched>
  panic("zombie exit");
    80002e7a:	00005517          	auipc	a0,0x5
    80002e7e:	70e50513          	addi	a0,a0,1806 # 80008588 <digits+0x548>
    80002e82:	ffffd097          	auipc	ra,0xffffd
    80002e86:	6bc080e7          	jalr	1724(ra) # 8000053e <panic>

0000000080002e8a <steal_process>:

void
steal_process(struct cpu *curr_c){  
    80002e8a:	711d                	addi	sp,sp,-96
    80002e8c:	ec86                	sd	ra,88(sp)
    80002e8e:	e8a2                	sd	s0,80(sp)
    80002e90:	e4a6                	sd	s1,72(sp)
    80002e92:	e0ca                	sd	s2,64(sp)
    80002e94:	fc4e                	sd	s3,56(sp)
    80002e96:	f852                	sd	s4,48(sp)
    80002e98:	f456                	sd	s5,40(sp)
    80002e9a:	f05a                	sd	s6,32(sp)
    80002e9c:	ec5e                	sd	s7,24(sp)
    80002e9e:	e862                	sd	s8,16(sp)
    80002ea0:	e466                	sd	s9,8(sp)
    80002ea2:	e06a                	sd	s10,0(sp)
    80002ea4:	1080                	addi	s0,sp,96
    80002ea6:	89aa                	mv	s3,a0
  struct cpu *c;
  struct proc *p;
  struct _list *lst;
  int stolen_process;
  int succeed = 0;
  for(c = cpus; !succeed && c < &cpus[NCPU] && c != NULL && c->cpu_id < CPUS ; c++){
    80002ea8:	0000e497          	auipc	s1,0xe
    80002eac:	3f848493          	addi	s1,s1,1016 # 800112a0 <cpus>
    80002eb0:	4a09                	li	s4,2
      if(c != curr_c){
        lst = &c->runnable_list;
        acquire(&lst->head_lock);
        if(!isEmpty(lst)){ 
    80002eb2:	5b7d                	li	s6,-1
          stolen_process = lst->head;
          p = &proc[stolen_process];
    80002eb4:	19000c93          	li	s9,400
    80002eb8:	0000fc17          	auipc	s8,0xf
    80002ebc:	998c0c13          	addi	s8,s8,-1640 # 80011850 <proc>
          acquire(&p->lock);
          printf("remove steal runnable %d\n", p->index); //delete
    80002ec0:	00005b97          	auipc	s7,0x5
    80002ec4:	6d8b8b93          	addi	s7,s7,1752 # 80008598 <digits+0x558>
  for(c = cpus; !succeed && c < &cpus[NCPU] && c != NULL && c->cpu_id < CPUS ; c++){
    80002ec8:	0000fa97          	auipc	s5,0xf
    80002ecc:	958a8a93          	addi	s5,s5,-1704 # 80011820 <pid_lock>
    80002ed0:	a811                	j	80002ee4 <steal_process+0x5a>
          succeed = remove_head_from_list(lst);
          release(&p->lock);
        }
        else{
          release(&lst->head_lock);
    80002ed2:	856a                	mv	a0,s10
    80002ed4:	ffffe097          	auipc	ra,0xffffe
    80002ed8:	dc4080e7          	jalr	-572(ra) # 80000c98 <release>
  for(c = cpus; !succeed && c < &cpus[NCPU] && c != NULL && c->cpu_id < CPUS ; c++){
    80002edc:	0b048493          	addi	s1,s1,176
    80002ee0:	0b548663          	beq	s1,s5,80002f8c <steal_process+0x102>
    80002ee4:	0a04a783          	lw	a5,160(s1)
    80002ee8:	0afa4263          	blt	s4,a5,80002f8c <steal_process+0x102>
      if(c != curr_c){
    80002eec:	fe9988e3          	beq	s3,s1,80002edc <steal_process+0x52>
        acquire(&lst->head_lock);
    80002ef0:	08848d13          	addi	s10,s1,136
    80002ef4:	856a                	mv	a0,s10
    80002ef6:	ffffe097          	auipc	ra,0xffffe
    80002efa:	cee080e7          	jalr	-786(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80002efe:	0804a903          	lw	s2,128(s1)
        if(!isEmpty(lst)){ 
    80002f02:	fd6908e3          	beq	s2,s6,80002ed2 <steal_process+0x48>
          p = &proc[stolen_process];
    80002f06:	03990933          	mul	s2,s2,s9
    80002f0a:	9962                	add	s2,s2,s8
          acquire(&p->lock);
    80002f0c:	854a                	mv	a0,s2
    80002f0e:	ffffe097          	auipc	ra,0xffffe
    80002f12:	cd6080e7          	jalr	-810(ra) # 80000be4 <acquire>
          printf("remove steal runnable %d\n", p->index); //delete
    80002f16:	16c92583          	lw	a1,364(s2)
    80002f1a:	855e                	mv	a0,s7
    80002f1c:	ffffd097          	auipc	ra,0xffffd
    80002f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
          succeed = remove_head_from_list(lst);
    80002f24:	08048513          	addi	a0,s1,128
    80002f28:	fffff097          	auipc	ra,0xfffff
    80002f2c:	c28080e7          	jalr	-984(ra) # 80001b50 <remove_head_from_list>
    80002f30:	8d2a                	mv	s10,a0
          release(&p->lock);
    80002f32:	854a                	mv	a0,s2
    80002f34:	ffffe097          	auipc	ra,0xffffe
    80002f38:	d64080e7          	jalr	-668(ra) # 80000c98 <release>
  for(c = cpus; !succeed && c < &cpus[NCPU] && c != NULL && c->cpu_id < CPUS ; c++){
    80002f3c:	0b048493          	addi	s1,s1,176
    80002f40:	fa0d00e3          	beqz	s10,80002ee0 <steal_process+0x56>
        }
      }
  }
  if(succeed){
    acquire(&p->lock);
    80002f44:	854a                	mv	a0,s2
    80002f46:	ffffe097          	auipc	ra,0xffffe
    80002f4a:	c9e080e7          	jalr	-866(ra) # 80000be4 <acquire>
    printf("insert steal runnable %d\n", p->index); //delete
    80002f4e:	16c92583          	lw	a1,364(s2)
    80002f52:	00005517          	auipc	a0,0x5
    80002f56:	66650513          	addi	a0,a0,1638 # 800085b8 <digits+0x578>
    80002f5a:	ffffd097          	auipc	ra,0xffffd
    80002f5e:	62e080e7          	jalr	1582(ra) # 80000588 <printf>
    insert_proc_to_list(&curr_c->runnable_list, p);
    80002f62:	85ca                	mv	a1,s2
    80002f64:	08098513          	addi	a0,s3,128
    80002f68:	fffff097          	auipc	ra,0xfffff
    80002f6c:	b06080e7          	jalr	-1274(ra) # 80001a6e <insert_proc_to_list>
    p->last_cpu = curr_c->cpu_id;
    80002f70:	0a09a783          	lw	a5,160(s3)
    80002f74:	16f92423          	sw	a5,360(s2)
    increment_cpu_process_count(curr_c); 
    80002f78:	854e                	mv	a0,s3
    80002f7a:	00000097          	auipc	ra,0x0
    80002f7e:	acc080e7          	jalr	-1332(ra) # 80002a46 <increment_cpu_process_count>
    release(&p->lock);
    80002f82:	854a                	mv	a0,s2
    80002f84:	ffffe097          	auipc	ra,0xffffe
    80002f88:	d14080e7          	jalr	-748(ra) # 80000c98 <release>
  }
    80002f8c:	60e6                	ld	ra,88(sp)
    80002f8e:	6446                	ld	s0,80(sp)
    80002f90:	64a6                	ld	s1,72(sp)
    80002f92:	6906                	ld	s2,64(sp)
    80002f94:	79e2                	ld	s3,56(sp)
    80002f96:	7a42                	ld	s4,48(sp)
    80002f98:	7aa2                	ld	s5,40(sp)
    80002f9a:	7b02                	ld	s6,32(sp)
    80002f9c:	6be2                	ld	s7,24(sp)
    80002f9e:	6c42                	ld	s8,16(sp)
    80002fa0:	6ca2                	ld	s9,8(sp)
    80002fa2:	6d02                	ld	s10,0(sp)
    80002fa4:	6125                	addi	sp,sp,96
    80002fa6:	8082                	ret

0000000080002fa8 <scheduler>:
{
    80002fa8:	711d                	addi	sp,sp,-96
    80002faa:	ec86                	sd	ra,88(sp)
    80002fac:	e8a2                	sd	s0,80(sp)
    80002fae:	e4a6                	sd	s1,72(sp)
    80002fb0:	e0ca                	sd	s2,64(sp)
    80002fb2:	fc4e                	sd	s3,56(sp)
    80002fb4:	f852                	sd	s4,48(sp)
    80002fb6:	f456                	sd	s5,40(sp)
    80002fb8:	f05a                	sd	s6,32(sp)
    80002fba:	ec5e                	sd	s7,24(sp)
    80002fbc:	e862                	sd	s8,16(sp)
    80002fbe:	e466                	sd	s9,8(sp)
    80002fc0:	e06a                	sd	s10,0(sp)
    80002fc2:	1080                	addi	s0,sp,96
    80002fc4:	8712                	mv	a4,tp
  int id = r_tp();
    80002fc6:	2701                	sext.w	a4,a4
  struct cpu *c = &cpus[id];
    80002fc8:	0b000793          	li	a5,176
    80002fcc:	02f707b3          	mul	a5,a4,a5
    80002fd0:	0000eb97          	auipc	s7,0xe
    80002fd4:	2d0b8b93          	addi	s7,s7,720 # 800112a0 <cpus>
    80002fd8:	00fb8b33          	add	s6,s7,a5
  c->proc = 0;
    80002fdc:	000b3023          	sd	zero,0(s6)
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80002fe0:	08078a93          	addi	s5,a5,128
    80002fe4:	9ade                	add	s5,s5,s7
          swtch(&c->context, &p->context);
    80002fe6:	07a1                	addi	a5,a5,8
    80002fe8:	9bbe                	add	s7,s7,a5
  return lst->head == -1;
    80002fea:	895a                	mv	s2,s6
      if(p->state == RUNNABLE) {
    80002fec:	0000f997          	auipc	s3,0xf
    80002ff0:	86498993          	addi	s3,s3,-1948 # 80011850 <proc>
    80002ff4:	19000a13          	li	s4,400
    80002ff8:	a891                	j	8000304c <scheduler+0xa4>
          printf("remove sched runnable %d\n", p->index); //delete
    80002ffa:	16cc2583          	lw	a1,364(s8)
    80002ffe:	00005517          	auipc	a0,0x5
    80003002:	5da50513          	addi	a0,a0,1498 # 800085d8 <digits+0x598>
    80003006:	ffffd097          	auipc	ra,0xffffd
    8000300a:	582080e7          	jalr	1410(ra) # 80000588 <printf>
          remove_proc_to_list(&(c->runnable_list), p);
    8000300e:	85e2                	mv	a1,s8
    80003010:	8556                	mv	a0,s5
    80003012:	fffff097          	auipc	ra,0xfffff
    80003016:	bea080e7          	jalr	-1046(ra) # 80001bfc <remove_proc_to_list>
          p->state = RUNNING;
    8000301a:	4791                	li	a5,4
    8000301c:	00fc2c23          	sw	a5,24(s8)
          c->proc = p;
    80003020:	01893023          	sd	s8,0(s2)
          p->last_cpu = c->cpu_id;
    80003024:	0a092783          	lw	a5,160(s2)
    80003028:	16fc2423          	sw	a5,360(s8)
          swtch(&c->context, &p->context);
    8000302c:	060d0593          	addi	a1,s10,96
    80003030:	95ce                	add	a1,a1,s3
    80003032:	855e                	mv	a0,s7
    80003034:	00000097          	auipc	ra,0x0
    80003038:	06c080e7          	jalr	108(ra) # 800030a0 <swtch>
          c->proc = 0;
    8000303c:	00093023          	sd	zero,0(s2)
    80003040:	a891                	j	80003094 <scheduler+0xec>
        steal_process(c);
    80003042:	855a                	mv	a0,s6
    80003044:	00000097          	auipc	ra,0x0
    80003048:	e46080e7          	jalr	-442(ra) # 80002e8a <steal_process>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000304c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003050:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003054:	10079073          	csrw	sstatus,a5
      if(p->state == RUNNABLE) {
    80003058:	4c8d                	li	s9,3
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    8000305a:	5c7d                	li	s8,-1
    8000305c:	08092783          	lw	a5,128(s2)
    80003060:	ff8781e3          	beq	a5,s8,80003042 <scheduler+0x9a>
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    80003064:	8556                	mv	a0,s5
    80003066:	fffff097          	auipc	ra,0xfffff
    8000306a:	9b2080e7          	jalr	-1614(ra) # 80001a18 <get_head>
      if(p->state == RUNNABLE) {
    8000306e:	034507b3          	mul	a5,a0,s4
    80003072:	97ce                	add	a5,a5,s3
    80003074:	4f9c                	lw	a5,24(a5)
    80003076:	ff9793e3          	bne	a5,s9,8000305c <scheduler+0xb4>
    8000307a:	03450d33          	mul	s10,a0,s4
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    8000307e:	013d0c33          	add	s8,s10,s3
        acquire(&p->lock);
    80003082:	8562                	mv	a0,s8
    80003084:	ffffe097          	auipc	ra,0xffffe
    80003088:	b60080e7          	jalr	-1184(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {  
    8000308c:	018c2783          	lw	a5,24(s8)
    80003090:	f79785e3          	beq	a5,s9,80002ffa <scheduler+0x52>
        release(&p->lock);
    80003094:	8562                	mv	a0,s8
    80003096:	ffffe097          	auipc	ra,0xffffe
    8000309a:	c02080e7          	jalr	-1022(ra) # 80000c98 <release>
    8000309e:	bf75                	j	8000305a <scheduler+0xb2>

00000000800030a0 <swtch>:
    800030a0:	00153023          	sd	ra,0(a0)
    800030a4:	00253423          	sd	sp,8(a0)
    800030a8:	e900                	sd	s0,16(a0)
    800030aa:	ed04                	sd	s1,24(a0)
    800030ac:	03253023          	sd	s2,32(a0)
    800030b0:	03353423          	sd	s3,40(a0)
    800030b4:	03453823          	sd	s4,48(a0)
    800030b8:	03553c23          	sd	s5,56(a0)
    800030bc:	05653023          	sd	s6,64(a0)
    800030c0:	05753423          	sd	s7,72(a0)
    800030c4:	05853823          	sd	s8,80(a0)
    800030c8:	05953c23          	sd	s9,88(a0)
    800030cc:	07a53023          	sd	s10,96(a0)
    800030d0:	07b53423          	sd	s11,104(a0)
    800030d4:	0005b083          	ld	ra,0(a1)
    800030d8:	0085b103          	ld	sp,8(a1)
    800030dc:	6980                	ld	s0,16(a1)
    800030de:	6d84                	ld	s1,24(a1)
    800030e0:	0205b903          	ld	s2,32(a1)
    800030e4:	0285b983          	ld	s3,40(a1)
    800030e8:	0305ba03          	ld	s4,48(a1)
    800030ec:	0385ba83          	ld	s5,56(a1)
    800030f0:	0405bb03          	ld	s6,64(a1)
    800030f4:	0485bb83          	ld	s7,72(a1)
    800030f8:	0505bc03          	ld	s8,80(a1)
    800030fc:	0585bc83          	ld	s9,88(a1)
    80003100:	0605bd03          	ld	s10,96(a1)
    80003104:	0685bd83          	ld	s11,104(a1)
    80003108:	8082                	ret

000000008000310a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000310a:	1141                	addi	sp,sp,-16
    8000310c:	e406                	sd	ra,8(sp)
    8000310e:	e022                	sd	s0,0(sp)
    80003110:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80003112:	00005597          	auipc	a1,0x5
    80003116:	53e58593          	addi	a1,a1,1342 # 80008650 <states.1826+0x30>
    8000311a:	00015517          	auipc	a0,0x15
    8000311e:	b3650513          	addi	a0,a0,-1226 # 80017c50 <tickslock>
    80003122:	ffffe097          	auipc	ra,0xffffe
    80003126:	a32080e7          	jalr	-1486(ra) # 80000b54 <initlock>
}
    8000312a:	60a2                	ld	ra,8(sp)
    8000312c:	6402                	ld	s0,0(sp)
    8000312e:	0141                	addi	sp,sp,16
    80003130:	8082                	ret

0000000080003132 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80003132:	1141                	addi	sp,sp,-16
    80003134:	e422                	sd	s0,8(sp)
    80003136:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003138:	00003797          	auipc	a5,0x3
    8000313c:	50878793          	addi	a5,a5,1288 # 80006640 <kernelvec>
    80003140:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80003144:	6422                	ld	s0,8(sp)
    80003146:	0141                	addi	sp,sp,16
    80003148:	8082                	ret

000000008000314a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000314a:	1141                	addi	sp,sp,-16
    8000314c:	e406                	sd	ra,8(sp)
    8000314e:	e022                	sd	s0,0(sp)
    80003150:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003152:	fffff097          	auipc	ra,0xfffff
    80003156:	dfc080e7          	jalr	-516(ra) # 80001f4e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000315a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000315e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003160:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003164:	00004617          	auipc	a2,0x4
    80003168:	e9c60613          	addi	a2,a2,-356 # 80007000 <_trampoline>
    8000316c:	00004697          	auipc	a3,0x4
    80003170:	e9468693          	addi	a3,a3,-364 # 80007000 <_trampoline>
    80003174:	8e91                	sub	a3,a3,a2
    80003176:	040007b7          	lui	a5,0x4000
    8000317a:	17fd                	addi	a5,a5,-1
    8000317c:	07b2                	slli	a5,a5,0xc
    8000317e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003180:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003184:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003186:	180026f3          	csrr	a3,satp
    8000318a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000318c:	6d38                	ld	a4,88(a0)
    8000318e:	6134                	ld	a3,64(a0)
    80003190:	6585                	lui	a1,0x1
    80003192:	96ae                	add	a3,a3,a1
    80003194:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003196:	6d38                	ld	a4,88(a0)
    80003198:	00000697          	auipc	a3,0x0
    8000319c:	13868693          	addi	a3,a3,312 # 800032d0 <usertrap>
    800031a0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800031a2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800031a4:	8692                	mv	a3,tp
    800031a6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031a8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800031ac:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800031b0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031b4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800031b8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800031ba:	6f18                	ld	a4,24(a4)
    800031bc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800031c0:	692c                	ld	a1,80(a0)
    800031c2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800031c4:	00004717          	auipc	a4,0x4
    800031c8:	ecc70713          	addi	a4,a4,-308 # 80007090 <userret>
    800031cc:	8f11                	sub	a4,a4,a2
    800031ce:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800031d0:	577d                	li	a4,-1
    800031d2:	177e                	slli	a4,a4,0x3f
    800031d4:	8dd9                	or	a1,a1,a4
    800031d6:	02000537          	lui	a0,0x2000
    800031da:	157d                	addi	a0,a0,-1
    800031dc:	0536                	slli	a0,a0,0xd
    800031de:	9782                	jalr	a5
}
    800031e0:	60a2                	ld	ra,8(sp)
    800031e2:	6402                	ld	s0,0(sp)
    800031e4:	0141                	addi	sp,sp,16
    800031e6:	8082                	ret

00000000800031e8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800031e8:	1101                	addi	sp,sp,-32
    800031ea:	ec06                	sd	ra,24(sp)
    800031ec:	e822                	sd	s0,16(sp)
    800031ee:	e426                	sd	s1,8(sp)
    800031f0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800031f2:	00015497          	auipc	s1,0x15
    800031f6:	a5e48493          	addi	s1,s1,-1442 # 80017c50 <tickslock>
    800031fa:	8526                	mv	a0,s1
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	9e8080e7          	jalr	-1560(ra) # 80000be4 <acquire>
  ticks++;
    80003204:	00006517          	auipc	a0,0x6
    80003208:	e2c50513          	addi	a0,a0,-468 # 80009030 <ticks>
    8000320c:	411c                	lw	a5,0(a0)
    8000320e:	2785                	addiw	a5,a5,1
    80003210:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003212:	00000097          	auipc	ra,0x0
    80003216:	9fc080e7          	jalr	-1540(ra) # 80002c0e <wakeup>
  release(&tickslock);
    8000321a:	8526                	mv	a0,s1
    8000321c:	ffffe097          	auipc	ra,0xffffe
    80003220:	a7c080e7          	jalr	-1412(ra) # 80000c98 <release>
}
    80003224:	60e2                	ld	ra,24(sp)
    80003226:	6442                	ld	s0,16(sp)
    80003228:	64a2                	ld	s1,8(sp)
    8000322a:	6105                	addi	sp,sp,32
    8000322c:	8082                	ret

000000008000322e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000322e:	1101                	addi	sp,sp,-32
    80003230:	ec06                	sd	ra,24(sp)
    80003232:	e822                	sd	s0,16(sp)
    80003234:	e426                	sd	s1,8(sp)
    80003236:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003238:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000323c:	00074d63          	bltz	a4,80003256 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003240:	57fd                	li	a5,-1
    80003242:	17fe                	slli	a5,a5,0x3f
    80003244:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003246:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003248:	06f70363          	beq	a4,a5,800032ae <devintr+0x80>
  }
}
    8000324c:	60e2                	ld	ra,24(sp)
    8000324e:	6442                	ld	s0,16(sp)
    80003250:	64a2                	ld	s1,8(sp)
    80003252:	6105                	addi	sp,sp,32
    80003254:	8082                	ret
     (scause & 0xff) == 9){
    80003256:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000325a:	46a5                	li	a3,9
    8000325c:	fed792e3          	bne	a5,a3,80003240 <devintr+0x12>
    int irq = plic_claim();
    80003260:	00003097          	auipc	ra,0x3
    80003264:	4e8080e7          	jalr	1256(ra) # 80006748 <plic_claim>
    80003268:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000326a:	47a9                	li	a5,10
    8000326c:	02f50763          	beq	a0,a5,8000329a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003270:	4785                	li	a5,1
    80003272:	02f50963          	beq	a0,a5,800032a4 <devintr+0x76>
    return 1;
    80003276:	4505                	li	a0,1
    } else if(irq){
    80003278:	d8f1                	beqz	s1,8000324c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000327a:	85a6                	mv	a1,s1
    8000327c:	00005517          	auipc	a0,0x5
    80003280:	3dc50513          	addi	a0,a0,988 # 80008658 <states.1826+0x38>
    80003284:	ffffd097          	auipc	ra,0xffffd
    80003288:	304080e7          	jalr	772(ra) # 80000588 <printf>
      plic_complete(irq);
    8000328c:	8526                	mv	a0,s1
    8000328e:	00003097          	auipc	ra,0x3
    80003292:	4de080e7          	jalr	1246(ra) # 8000676c <plic_complete>
    return 1;
    80003296:	4505                	li	a0,1
    80003298:	bf55                	j	8000324c <devintr+0x1e>
      uartintr();
    8000329a:	ffffd097          	auipc	ra,0xffffd
    8000329e:	70e080e7          	jalr	1806(ra) # 800009a8 <uartintr>
    800032a2:	b7ed                	j	8000328c <devintr+0x5e>
      virtio_disk_intr();
    800032a4:	00004097          	auipc	ra,0x4
    800032a8:	9a8080e7          	jalr	-1624(ra) # 80006c4c <virtio_disk_intr>
    800032ac:	b7c5                	j	8000328c <devintr+0x5e>
    if(cpuid() == 0){
    800032ae:	fffff097          	auipc	ra,0xfffff
    800032b2:	c6e080e7          	jalr	-914(ra) # 80001f1c <cpuid>
    800032b6:	c901                	beqz	a0,800032c6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800032b8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800032bc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800032be:	14479073          	csrw	sip,a5
    return 2;
    800032c2:	4509                	li	a0,2
    800032c4:	b761                	j	8000324c <devintr+0x1e>
      clockintr();
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	f22080e7          	jalr	-222(ra) # 800031e8 <clockintr>
    800032ce:	b7ed                	j	800032b8 <devintr+0x8a>

00000000800032d0 <usertrap>:
{
    800032d0:	1101                	addi	sp,sp,-32
    800032d2:	ec06                	sd	ra,24(sp)
    800032d4:	e822                	sd	s0,16(sp)
    800032d6:	e426                	sd	s1,8(sp)
    800032d8:	e04a                	sd	s2,0(sp)
    800032da:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032dc:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800032e0:	1007f793          	andi	a5,a5,256
    800032e4:	e3ad                	bnez	a5,80003346 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800032e6:	00003797          	auipc	a5,0x3
    800032ea:	35a78793          	addi	a5,a5,858 # 80006640 <kernelvec>
    800032ee:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800032f2:	fffff097          	auipc	ra,0xfffff
    800032f6:	c5c080e7          	jalr	-932(ra) # 80001f4e <myproc>
    800032fa:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800032fc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032fe:	14102773          	csrr	a4,sepc
    80003302:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003304:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003308:	47a1                	li	a5,8
    8000330a:	04f71c63          	bne	a4,a5,80003362 <usertrap+0x92>
    if(p->killed)
    8000330e:	551c                	lw	a5,40(a0)
    80003310:	e3b9                	bnez	a5,80003356 <usertrap+0x86>
    p->trapframe->epc += 4;
    80003312:	6cb8                	ld	a4,88(s1)
    80003314:	6f1c                	ld	a5,24(a4)
    80003316:	0791                	addi	a5,a5,4
    80003318:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000331a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000331e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003322:	10079073          	csrw	sstatus,a5
    syscall();
    80003326:	00000097          	auipc	ra,0x0
    8000332a:	2e0080e7          	jalr	736(ra) # 80003606 <syscall>
  if(p->killed)
    8000332e:	549c                	lw	a5,40(s1)
    80003330:	ebc1                	bnez	a5,800033c0 <usertrap+0xf0>
  usertrapret();
    80003332:	00000097          	auipc	ra,0x0
    80003336:	e18080e7          	jalr	-488(ra) # 8000314a <usertrapret>
}
    8000333a:	60e2                	ld	ra,24(sp)
    8000333c:	6442                	ld	s0,16(sp)
    8000333e:	64a2                	ld	s1,8(sp)
    80003340:	6902                	ld	s2,0(sp)
    80003342:	6105                	addi	sp,sp,32
    80003344:	8082                	ret
    panic("usertrap: not from user mode");
    80003346:	00005517          	auipc	a0,0x5
    8000334a:	33250513          	addi	a0,a0,818 # 80008678 <states.1826+0x58>
    8000334e:	ffffd097          	auipc	ra,0xffffd
    80003352:	1f0080e7          	jalr	496(ra) # 8000053e <panic>
      exit(-1);
    80003356:	557d                	li	a0,-1
    80003358:	00000097          	auipc	ra,0x0
    8000335c:	a36080e7          	jalr	-1482(ra) # 80002d8e <exit>
    80003360:	bf4d                	j	80003312 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003362:	00000097          	auipc	ra,0x0
    80003366:	ecc080e7          	jalr	-308(ra) # 8000322e <devintr>
    8000336a:	892a                	mv	s2,a0
    8000336c:	c501                	beqz	a0,80003374 <usertrap+0xa4>
  if(p->killed)
    8000336e:	549c                	lw	a5,40(s1)
    80003370:	c3a1                	beqz	a5,800033b0 <usertrap+0xe0>
    80003372:	a815                	j	800033a6 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003374:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003378:	5890                	lw	a2,48(s1)
    8000337a:	00005517          	auipc	a0,0x5
    8000337e:	31e50513          	addi	a0,a0,798 # 80008698 <states.1826+0x78>
    80003382:	ffffd097          	auipc	ra,0xffffd
    80003386:	206080e7          	jalr	518(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000338a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000338e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003392:	00005517          	auipc	a0,0x5
    80003396:	33650513          	addi	a0,a0,822 # 800086c8 <states.1826+0xa8>
    8000339a:	ffffd097          	auipc	ra,0xffffd
    8000339e:	1ee080e7          	jalr	494(ra) # 80000588 <printf>
    p->killed = 1;
    800033a2:	4785                	li	a5,1
    800033a4:	d49c                	sw	a5,40(s1)
    exit(-1);
    800033a6:	557d                	li	a0,-1
    800033a8:	00000097          	auipc	ra,0x0
    800033ac:	9e6080e7          	jalr	-1562(ra) # 80002d8e <exit>
  if(which_dev == 2)
    800033b0:	4789                	li	a5,2
    800033b2:	f8f910e3          	bne	s2,a5,80003332 <usertrap+0x62>
    yield();
    800033b6:	fffff097          	auipc	ra,0xfffff
    800033ba:	15e080e7          	jalr	350(ra) # 80002514 <yield>
    800033be:	bf95                	j	80003332 <usertrap+0x62>
  int which_dev = 0;
    800033c0:	4901                	li	s2,0
    800033c2:	b7d5                	j	800033a6 <usertrap+0xd6>

00000000800033c4 <kerneltrap>:
{
    800033c4:	7179                	addi	sp,sp,-48
    800033c6:	f406                	sd	ra,40(sp)
    800033c8:	f022                	sd	s0,32(sp)
    800033ca:	ec26                	sd	s1,24(sp)
    800033cc:	e84a                	sd	s2,16(sp)
    800033ce:	e44e                	sd	s3,8(sp)
    800033d0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800033d2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800033d6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800033da:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800033de:	1004f793          	andi	a5,s1,256
    800033e2:	cb85                	beqz	a5,80003412 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800033e4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800033e8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800033ea:	ef85                	bnez	a5,80003422 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800033ec:	00000097          	auipc	ra,0x0
    800033f0:	e42080e7          	jalr	-446(ra) # 8000322e <devintr>
    800033f4:	cd1d                	beqz	a0,80003432 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800033f6:	4789                	li	a5,2
    800033f8:	06f50a63          	beq	a0,a5,8000346c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800033fc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003400:	10049073          	csrw	sstatus,s1
}
    80003404:	70a2                	ld	ra,40(sp)
    80003406:	7402                	ld	s0,32(sp)
    80003408:	64e2                	ld	s1,24(sp)
    8000340a:	6942                	ld	s2,16(sp)
    8000340c:	69a2                	ld	s3,8(sp)
    8000340e:	6145                	addi	sp,sp,48
    80003410:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003412:	00005517          	auipc	a0,0x5
    80003416:	2d650513          	addi	a0,a0,726 # 800086e8 <states.1826+0xc8>
    8000341a:	ffffd097          	auipc	ra,0xffffd
    8000341e:	124080e7          	jalr	292(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003422:	00005517          	auipc	a0,0x5
    80003426:	2ee50513          	addi	a0,a0,750 # 80008710 <states.1826+0xf0>
    8000342a:	ffffd097          	auipc	ra,0xffffd
    8000342e:	114080e7          	jalr	276(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003432:	85ce                	mv	a1,s3
    80003434:	00005517          	auipc	a0,0x5
    80003438:	2fc50513          	addi	a0,a0,764 # 80008730 <states.1826+0x110>
    8000343c:	ffffd097          	auipc	ra,0xffffd
    80003440:	14c080e7          	jalr	332(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003444:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003448:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000344c:	00005517          	auipc	a0,0x5
    80003450:	2f450513          	addi	a0,a0,756 # 80008740 <states.1826+0x120>
    80003454:	ffffd097          	auipc	ra,0xffffd
    80003458:	134080e7          	jalr	308(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000345c:	00005517          	auipc	a0,0x5
    80003460:	2fc50513          	addi	a0,a0,764 # 80008758 <states.1826+0x138>
    80003464:	ffffd097          	auipc	ra,0xffffd
    80003468:	0da080e7          	jalr	218(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000346c:	fffff097          	auipc	ra,0xfffff
    80003470:	ae2080e7          	jalr	-1310(ra) # 80001f4e <myproc>
    80003474:	d541                	beqz	a0,800033fc <kerneltrap+0x38>
    80003476:	fffff097          	auipc	ra,0xfffff
    8000347a:	ad8080e7          	jalr	-1320(ra) # 80001f4e <myproc>
    8000347e:	4d18                	lw	a4,24(a0)
    80003480:	4791                	li	a5,4
    80003482:	f6f71de3          	bne	a4,a5,800033fc <kerneltrap+0x38>
    yield();
    80003486:	fffff097          	auipc	ra,0xfffff
    8000348a:	08e080e7          	jalr	142(ra) # 80002514 <yield>
    8000348e:	b7bd                	j	800033fc <kerneltrap+0x38>

0000000080003490 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003490:	1101                	addi	sp,sp,-32
    80003492:	ec06                	sd	ra,24(sp)
    80003494:	e822                	sd	s0,16(sp)
    80003496:	e426                	sd	s1,8(sp)
    80003498:	1000                	addi	s0,sp,32
    8000349a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000349c:	fffff097          	auipc	ra,0xfffff
    800034a0:	ab2080e7          	jalr	-1358(ra) # 80001f4e <myproc>
  switch (n) {
    800034a4:	4795                	li	a5,5
    800034a6:	0497e163          	bltu	a5,s1,800034e8 <argraw+0x58>
    800034aa:	048a                	slli	s1,s1,0x2
    800034ac:	00005717          	auipc	a4,0x5
    800034b0:	2e470713          	addi	a4,a4,740 # 80008790 <states.1826+0x170>
    800034b4:	94ba                	add	s1,s1,a4
    800034b6:	409c                	lw	a5,0(s1)
    800034b8:	97ba                	add	a5,a5,a4
    800034ba:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800034bc:	6d3c                	ld	a5,88(a0)
    800034be:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800034c0:	60e2                	ld	ra,24(sp)
    800034c2:	6442                	ld	s0,16(sp)
    800034c4:	64a2                	ld	s1,8(sp)
    800034c6:	6105                	addi	sp,sp,32
    800034c8:	8082                	ret
    return p->trapframe->a1;
    800034ca:	6d3c                	ld	a5,88(a0)
    800034cc:	7fa8                	ld	a0,120(a5)
    800034ce:	bfcd                	j	800034c0 <argraw+0x30>
    return p->trapframe->a2;
    800034d0:	6d3c                	ld	a5,88(a0)
    800034d2:	63c8                	ld	a0,128(a5)
    800034d4:	b7f5                	j	800034c0 <argraw+0x30>
    return p->trapframe->a3;
    800034d6:	6d3c                	ld	a5,88(a0)
    800034d8:	67c8                	ld	a0,136(a5)
    800034da:	b7dd                	j	800034c0 <argraw+0x30>
    return p->trapframe->a4;
    800034dc:	6d3c                	ld	a5,88(a0)
    800034de:	6bc8                	ld	a0,144(a5)
    800034e0:	b7c5                	j	800034c0 <argraw+0x30>
    return p->trapframe->a5;
    800034e2:	6d3c                	ld	a5,88(a0)
    800034e4:	6fc8                	ld	a0,152(a5)
    800034e6:	bfe9                	j	800034c0 <argraw+0x30>
  panic("argraw");
    800034e8:	00005517          	auipc	a0,0x5
    800034ec:	28050513          	addi	a0,a0,640 # 80008768 <states.1826+0x148>
    800034f0:	ffffd097          	auipc	ra,0xffffd
    800034f4:	04e080e7          	jalr	78(ra) # 8000053e <panic>

00000000800034f8 <fetchaddr>:
{
    800034f8:	1101                	addi	sp,sp,-32
    800034fa:	ec06                	sd	ra,24(sp)
    800034fc:	e822                	sd	s0,16(sp)
    800034fe:	e426                	sd	s1,8(sp)
    80003500:	e04a                	sd	s2,0(sp)
    80003502:	1000                	addi	s0,sp,32
    80003504:	84aa                	mv	s1,a0
    80003506:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003508:	fffff097          	auipc	ra,0xfffff
    8000350c:	a46080e7          	jalr	-1466(ra) # 80001f4e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003510:	653c                	ld	a5,72(a0)
    80003512:	02f4f863          	bgeu	s1,a5,80003542 <fetchaddr+0x4a>
    80003516:	00848713          	addi	a4,s1,8
    8000351a:	02e7e663          	bltu	a5,a4,80003546 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000351e:	46a1                	li	a3,8
    80003520:	8626                	mv	a2,s1
    80003522:	85ca                	mv	a1,s2
    80003524:	6928                	ld	a0,80(a0)
    80003526:	ffffe097          	auipc	ra,0xffffe
    8000352a:	1d8080e7          	jalr	472(ra) # 800016fe <copyin>
    8000352e:	00a03533          	snez	a0,a0
    80003532:	40a00533          	neg	a0,a0
}
    80003536:	60e2                	ld	ra,24(sp)
    80003538:	6442                	ld	s0,16(sp)
    8000353a:	64a2                	ld	s1,8(sp)
    8000353c:	6902                	ld	s2,0(sp)
    8000353e:	6105                	addi	sp,sp,32
    80003540:	8082                	ret
    return -1;
    80003542:	557d                	li	a0,-1
    80003544:	bfcd                	j	80003536 <fetchaddr+0x3e>
    80003546:	557d                	li	a0,-1
    80003548:	b7fd                	j	80003536 <fetchaddr+0x3e>

000000008000354a <fetchstr>:
{
    8000354a:	7179                	addi	sp,sp,-48
    8000354c:	f406                	sd	ra,40(sp)
    8000354e:	f022                	sd	s0,32(sp)
    80003550:	ec26                	sd	s1,24(sp)
    80003552:	e84a                	sd	s2,16(sp)
    80003554:	e44e                	sd	s3,8(sp)
    80003556:	1800                	addi	s0,sp,48
    80003558:	892a                	mv	s2,a0
    8000355a:	84ae                	mv	s1,a1
    8000355c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000355e:	fffff097          	auipc	ra,0xfffff
    80003562:	9f0080e7          	jalr	-1552(ra) # 80001f4e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003566:	86ce                	mv	a3,s3
    80003568:	864a                	mv	a2,s2
    8000356a:	85a6                	mv	a1,s1
    8000356c:	6928                	ld	a0,80(a0)
    8000356e:	ffffe097          	auipc	ra,0xffffe
    80003572:	21c080e7          	jalr	540(ra) # 8000178a <copyinstr>
  if(err < 0)
    80003576:	00054763          	bltz	a0,80003584 <fetchstr+0x3a>
  return strlen(buf);
    8000357a:	8526                	mv	a0,s1
    8000357c:	ffffe097          	auipc	ra,0xffffe
    80003580:	8e8080e7          	jalr	-1816(ra) # 80000e64 <strlen>
}
    80003584:	70a2                	ld	ra,40(sp)
    80003586:	7402                	ld	s0,32(sp)
    80003588:	64e2                	ld	s1,24(sp)
    8000358a:	6942                	ld	s2,16(sp)
    8000358c:	69a2                	ld	s3,8(sp)
    8000358e:	6145                	addi	sp,sp,48
    80003590:	8082                	ret

0000000080003592 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003592:	1101                	addi	sp,sp,-32
    80003594:	ec06                	sd	ra,24(sp)
    80003596:	e822                	sd	s0,16(sp)
    80003598:	e426                	sd	s1,8(sp)
    8000359a:	1000                	addi	s0,sp,32
    8000359c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000359e:	00000097          	auipc	ra,0x0
    800035a2:	ef2080e7          	jalr	-270(ra) # 80003490 <argraw>
    800035a6:	c088                	sw	a0,0(s1)
  return 0;
}
    800035a8:	4501                	li	a0,0
    800035aa:	60e2                	ld	ra,24(sp)
    800035ac:	6442                	ld	s0,16(sp)
    800035ae:	64a2                	ld	s1,8(sp)
    800035b0:	6105                	addi	sp,sp,32
    800035b2:	8082                	ret

00000000800035b4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800035b4:	1101                	addi	sp,sp,-32
    800035b6:	ec06                	sd	ra,24(sp)
    800035b8:	e822                	sd	s0,16(sp)
    800035ba:	e426                	sd	s1,8(sp)
    800035bc:	1000                	addi	s0,sp,32
    800035be:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800035c0:	00000097          	auipc	ra,0x0
    800035c4:	ed0080e7          	jalr	-304(ra) # 80003490 <argraw>
    800035c8:	e088                	sd	a0,0(s1)
  return 0;
}
    800035ca:	4501                	li	a0,0
    800035cc:	60e2                	ld	ra,24(sp)
    800035ce:	6442                	ld	s0,16(sp)
    800035d0:	64a2                	ld	s1,8(sp)
    800035d2:	6105                	addi	sp,sp,32
    800035d4:	8082                	ret

00000000800035d6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800035d6:	1101                	addi	sp,sp,-32
    800035d8:	ec06                	sd	ra,24(sp)
    800035da:	e822                	sd	s0,16(sp)
    800035dc:	e426                	sd	s1,8(sp)
    800035de:	e04a                	sd	s2,0(sp)
    800035e0:	1000                	addi	s0,sp,32
    800035e2:	84ae                	mv	s1,a1
    800035e4:	8932                	mv	s2,a2
  *ip = argraw(n);
    800035e6:	00000097          	auipc	ra,0x0
    800035ea:	eaa080e7          	jalr	-342(ra) # 80003490 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800035ee:	864a                	mv	a2,s2
    800035f0:	85a6                	mv	a1,s1
    800035f2:	00000097          	auipc	ra,0x0
    800035f6:	f58080e7          	jalr	-168(ra) # 8000354a <fetchstr>
}
    800035fa:	60e2                	ld	ra,24(sp)
    800035fc:	6442                	ld	s0,16(sp)
    800035fe:	64a2                	ld	s1,8(sp)
    80003600:	6902                	ld	s2,0(sp)
    80003602:	6105                	addi	sp,sp,32
    80003604:	8082                	ret

0000000080003606 <syscall>:
[SYS_cpu_process_count]   sys_cpu_process_count,
};

void
syscall(void)
{
    80003606:	1101                	addi	sp,sp,-32
    80003608:	ec06                	sd	ra,24(sp)
    8000360a:	e822                	sd	s0,16(sp)
    8000360c:	e426                	sd	s1,8(sp)
    8000360e:	e04a                	sd	s2,0(sp)
    80003610:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003612:	fffff097          	auipc	ra,0xfffff
    80003616:	93c080e7          	jalr	-1732(ra) # 80001f4e <myproc>
    8000361a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000361c:	05853903          	ld	s2,88(a0)
    80003620:	0a893783          	ld	a5,168(s2)
    80003624:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003628:	37fd                	addiw	a5,a5,-1
    8000362a:	475d                	li	a4,23
    8000362c:	00f76f63          	bltu	a4,a5,8000364a <syscall+0x44>
    80003630:	00369713          	slli	a4,a3,0x3
    80003634:	00005797          	auipc	a5,0x5
    80003638:	17478793          	addi	a5,a5,372 # 800087a8 <syscalls>
    8000363c:	97ba                	add	a5,a5,a4
    8000363e:	639c                	ld	a5,0(a5)
    80003640:	c789                	beqz	a5,8000364a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003642:	9782                	jalr	a5
    80003644:	06a93823          	sd	a0,112(s2)
    80003648:	a839                	j	80003666 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000364a:	15848613          	addi	a2,s1,344
    8000364e:	588c                	lw	a1,48(s1)
    80003650:	00005517          	auipc	a0,0x5
    80003654:	12050513          	addi	a0,a0,288 # 80008770 <states.1826+0x150>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	f30080e7          	jalr	-208(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003660:	6cbc                	ld	a5,88(s1)
    80003662:	577d                	li	a4,-1
    80003664:	fbb8                	sd	a4,112(a5)
  }
}
    80003666:	60e2                	ld	ra,24(sp)
    80003668:	6442                	ld	s0,16(sp)
    8000366a:	64a2                	ld	s1,8(sp)
    8000366c:	6902                	ld	s2,0(sp)
    8000366e:	6105                	addi	sp,sp,32
    80003670:	8082                	ret

0000000080003672 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003672:	1101                	addi	sp,sp,-32
    80003674:	ec06                	sd	ra,24(sp)
    80003676:	e822                	sd	s0,16(sp)
    80003678:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000367a:	fec40593          	addi	a1,s0,-20
    8000367e:	4501                	li	a0,0
    80003680:	00000097          	auipc	ra,0x0
    80003684:	f12080e7          	jalr	-238(ra) # 80003592 <argint>
    return -1;
    80003688:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000368a:	00054963          	bltz	a0,8000369c <sys_exit+0x2a>
  exit(n);
    8000368e:	fec42503          	lw	a0,-20(s0)
    80003692:	fffff097          	auipc	ra,0xfffff
    80003696:	6fc080e7          	jalr	1788(ra) # 80002d8e <exit>
  return 0;  // not reached
    8000369a:	4781                	li	a5,0
}
    8000369c:	853e                	mv	a0,a5
    8000369e:	60e2                	ld	ra,24(sp)
    800036a0:	6442                	ld	s0,16(sp)
    800036a2:	6105                	addi	sp,sp,32
    800036a4:	8082                	ret

00000000800036a6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800036a6:	1141                	addi	sp,sp,-16
    800036a8:	e406                	sd	ra,8(sp)
    800036aa:	e022                	sd	s0,0(sp)
    800036ac:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800036ae:	fffff097          	auipc	ra,0xfffff
    800036b2:	8a0080e7          	jalr	-1888(ra) # 80001f4e <myproc>
}
    800036b6:	5908                	lw	a0,48(a0)
    800036b8:	60a2                	ld	ra,8(sp)
    800036ba:	6402                	ld	s0,0(sp)
    800036bc:	0141                	addi	sp,sp,16
    800036be:	8082                	ret

00000000800036c0 <sys_fork>:

uint64
sys_fork(void)
{
    800036c0:	1141                	addi	sp,sp,-16
    800036c2:	e406                	sd	ra,8(sp)
    800036c4:	e022                	sd	s0,0(sp)
    800036c6:	0800                	addi	s0,sp,16
  return fork();
    800036c8:	fffff097          	auipc	ra,0xfffff
    800036cc:	3b2080e7          	jalr	946(ra) # 80002a7a <fork>
}
    800036d0:	60a2                	ld	ra,8(sp)
    800036d2:	6402                	ld	s0,0(sp)
    800036d4:	0141                	addi	sp,sp,16
    800036d6:	8082                	ret

00000000800036d8 <sys_wait>:

uint64
sys_wait(void)
{
    800036d8:	1101                	addi	sp,sp,-32
    800036da:	ec06                	sd	ra,24(sp)
    800036dc:	e822                	sd	s0,16(sp)
    800036de:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800036e0:	fe840593          	addi	a1,s0,-24
    800036e4:	4501                	li	a0,0
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	ece080e7          	jalr	-306(ra) # 800035b4 <argaddr>
    800036ee:	87aa                	mv	a5,a0
    return -1;
    800036f0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800036f2:	0007c863          	bltz	a5,80003702 <sys_wait+0x2a>
  return wait(p);
    800036f6:	fe843503          	ld	a0,-24(s0)
    800036fa:	fffff097          	auipc	ra,0xfffff
    800036fe:	f18080e7          	jalr	-232(ra) # 80002612 <wait>
}
    80003702:	60e2                	ld	ra,24(sp)
    80003704:	6442                	ld	s0,16(sp)
    80003706:	6105                	addi	sp,sp,32
    80003708:	8082                	ret

000000008000370a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000370a:	7179                	addi	sp,sp,-48
    8000370c:	f406                	sd	ra,40(sp)
    8000370e:	f022                	sd	s0,32(sp)
    80003710:	ec26                	sd	s1,24(sp)
    80003712:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003714:	fdc40593          	addi	a1,s0,-36
    80003718:	4501                	li	a0,0
    8000371a:	00000097          	auipc	ra,0x0
    8000371e:	e78080e7          	jalr	-392(ra) # 80003592 <argint>
    80003722:	87aa                	mv	a5,a0
    return -1;
    80003724:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003726:	0207c063          	bltz	a5,80003746 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000372a:	fffff097          	auipc	ra,0xfffff
    8000372e:	824080e7          	jalr	-2012(ra) # 80001f4e <myproc>
    80003732:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003734:	fdc42503          	lw	a0,-36(s0)
    80003738:	fffff097          	auipc	ra,0xfffff
    8000373c:	c86080e7          	jalr	-890(ra) # 800023be <growproc>
    80003740:	00054863          	bltz	a0,80003750 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003744:	8526                	mv	a0,s1
}
    80003746:	70a2                	ld	ra,40(sp)
    80003748:	7402                	ld	s0,32(sp)
    8000374a:	64e2                	ld	s1,24(sp)
    8000374c:	6145                	addi	sp,sp,48
    8000374e:	8082                	ret
    return -1;
    80003750:	557d                	li	a0,-1
    80003752:	bfd5                	j	80003746 <sys_sbrk+0x3c>

0000000080003754 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003754:	7139                	addi	sp,sp,-64
    80003756:	fc06                	sd	ra,56(sp)
    80003758:	f822                	sd	s0,48(sp)
    8000375a:	f426                	sd	s1,40(sp)
    8000375c:	f04a                	sd	s2,32(sp)
    8000375e:	ec4e                	sd	s3,24(sp)
    80003760:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003762:	fcc40593          	addi	a1,s0,-52
    80003766:	4501                	li	a0,0
    80003768:	00000097          	auipc	ra,0x0
    8000376c:	e2a080e7          	jalr	-470(ra) # 80003592 <argint>
    return -1;
    80003770:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003772:	06054563          	bltz	a0,800037dc <sys_sleep+0x88>
  acquire(&tickslock);
    80003776:	00014517          	auipc	a0,0x14
    8000377a:	4da50513          	addi	a0,a0,1242 # 80017c50 <tickslock>
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	466080e7          	jalr	1126(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003786:	00006917          	auipc	s2,0x6
    8000378a:	8aa92903          	lw	s2,-1878(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000378e:	fcc42783          	lw	a5,-52(s0)
    80003792:	cf85                	beqz	a5,800037ca <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003794:	00014997          	auipc	s3,0x14
    80003798:	4bc98993          	addi	s3,s3,1212 # 80017c50 <tickslock>
    8000379c:	00006497          	auipc	s1,0x6
    800037a0:	89448493          	addi	s1,s1,-1900 # 80009030 <ticks>
    if(myproc()->killed){
    800037a4:	ffffe097          	auipc	ra,0xffffe
    800037a8:	7aa080e7          	jalr	1962(ra) # 80001f4e <myproc>
    800037ac:	551c                	lw	a5,40(a0)
    800037ae:	ef9d                	bnez	a5,800037ec <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800037b0:	85ce                	mv	a1,s3
    800037b2:	8526                	mv	a0,s1
    800037b4:	fffff097          	auipc	ra,0xfffff
    800037b8:	dd4080e7          	jalr	-556(ra) # 80002588 <sleep>
  while(ticks - ticks0 < n){
    800037bc:	409c                	lw	a5,0(s1)
    800037be:	412787bb          	subw	a5,a5,s2
    800037c2:	fcc42703          	lw	a4,-52(s0)
    800037c6:	fce7efe3          	bltu	a5,a4,800037a4 <sys_sleep+0x50>
  }
  release(&tickslock);
    800037ca:	00014517          	auipc	a0,0x14
    800037ce:	48650513          	addi	a0,a0,1158 # 80017c50 <tickslock>
    800037d2:	ffffd097          	auipc	ra,0xffffd
    800037d6:	4c6080e7          	jalr	1222(ra) # 80000c98 <release>
  return 0;
    800037da:	4781                	li	a5,0
}
    800037dc:	853e                	mv	a0,a5
    800037de:	70e2                	ld	ra,56(sp)
    800037e0:	7442                	ld	s0,48(sp)
    800037e2:	74a2                	ld	s1,40(sp)
    800037e4:	7902                	ld	s2,32(sp)
    800037e6:	69e2                	ld	s3,24(sp)
    800037e8:	6121                	addi	sp,sp,64
    800037ea:	8082                	ret
      release(&tickslock);
    800037ec:	00014517          	auipc	a0,0x14
    800037f0:	46450513          	addi	a0,a0,1124 # 80017c50 <tickslock>
    800037f4:	ffffd097          	auipc	ra,0xffffd
    800037f8:	4a4080e7          	jalr	1188(ra) # 80000c98 <release>
      return -1;
    800037fc:	57fd                	li	a5,-1
    800037fe:	bff9                	j	800037dc <sys_sleep+0x88>

0000000080003800 <sys_kill>:

uint64
sys_kill(void)
{
    80003800:	1101                	addi	sp,sp,-32
    80003802:	ec06                	sd	ra,24(sp)
    80003804:	e822                	sd	s0,16(sp)
    80003806:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003808:	fec40593          	addi	a1,s0,-20
    8000380c:	4501                	li	a0,0
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	d84080e7          	jalr	-636(ra) # 80003592 <argint>
    80003816:	87aa                	mv	a5,a0
    return -1;
    80003818:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000381a:	0007c863          	bltz	a5,8000382a <sys_kill+0x2a>
  return kill(pid);
    8000381e:	fec42503          	lw	a0,-20(s0)
    80003822:	fffff097          	auipc	ra,0xfffff
    80003826:	f18080e7          	jalr	-232(ra) # 8000273a <kill>
}
    8000382a:	60e2                	ld	ra,24(sp)
    8000382c:	6442                	ld	s0,16(sp)
    8000382e:	6105                	addi	sp,sp,32
    80003830:	8082                	ret

0000000080003832 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003832:	1101                	addi	sp,sp,-32
    80003834:	ec06                	sd	ra,24(sp)
    80003836:	e822                	sd	s0,16(sp)
    80003838:	e426                	sd	s1,8(sp)
    8000383a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000383c:	00014517          	auipc	a0,0x14
    80003840:	41450513          	addi	a0,a0,1044 # 80017c50 <tickslock>
    80003844:	ffffd097          	auipc	ra,0xffffd
    80003848:	3a0080e7          	jalr	928(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000384c:	00005497          	auipc	s1,0x5
    80003850:	7e44a483          	lw	s1,2020(s1) # 80009030 <ticks>
  release(&tickslock);
    80003854:	00014517          	auipc	a0,0x14
    80003858:	3fc50513          	addi	a0,a0,1020 # 80017c50 <tickslock>
    8000385c:	ffffd097          	auipc	ra,0xffffd
    80003860:	43c080e7          	jalr	1084(ra) # 80000c98 <release>
  return xticks;
}
    80003864:	02049513          	slli	a0,s1,0x20
    80003868:	9101                	srli	a0,a0,0x20
    8000386a:	60e2                	ld	ra,24(sp)
    8000386c:	6442                	ld	s0,16(sp)
    8000386e:	64a2                	ld	s1,8(sp)
    80003870:	6105                	addi	sp,sp,32
    80003872:	8082                	ret

0000000080003874 <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    80003874:	1101                	addi	sp,sp,-32
    80003876:	ec06                	sd	ra,24(sp)
    80003878:	e822                	sd	s0,16(sp)
    8000387a:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    8000387c:	fec40593          	addi	a1,s0,-20
    80003880:	4501                	li	a0,0
    80003882:	00000097          	auipc	ra,0x0
    80003886:	d10080e7          	jalr	-752(ra) # 80003592 <argint>
    8000388a:	87aa                	mv	a5,a0
    return -1;
    8000388c:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    8000388e:	0007c863          	bltz	a5,8000389e <sys_set_cpu+0x2a>
  return set_cpu(cpu_id);
    80003892:	fec42503          	lw	a0,-20(s0)
    80003896:	fffff097          	auipc	ra,0xfffff
    8000389a:	0ca080e7          	jalr	202(ra) # 80002960 <set_cpu>
}
    8000389e:	60e2                	ld	ra,24(sp)
    800038a0:	6442                	ld	s0,16(sp)
    800038a2:	6105                	addi	sp,sp,32
    800038a4:	8082                	ret

00000000800038a6 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    800038a6:	1141                	addi	sp,sp,-16
    800038a8:	e406                	sd	ra,8(sp)
    800038aa:	e022                	sd	s0,0(sp)
    800038ac:	0800                	addi	s0,sp,16
  return get_cpu();
    800038ae:	fffff097          	auipc	ra,0xfffff
    800038b2:	104080e7          	jalr	260(ra) # 800029b2 <get_cpu>
}
    800038b6:	60a2                	ld	ra,8(sp)
    800038b8:	6402                	ld	s0,0(sp)
    800038ba:	0141                	addi	sp,sp,16
    800038bc:	8082                	ret

00000000800038be <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void)
{
    800038be:	1101                	addi	sp,sp,-32
    800038c0:	ec06                	sd	ra,24(sp)
    800038c2:	e822                	sd	s0,16(sp)
    800038c4:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    800038c6:	fec40593          	addi	a1,s0,-20
    800038ca:	4501                	li	a0,0
    800038cc:	00000097          	auipc	ra,0x0
    800038d0:	cc6080e7          	jalr	-826(ra) # 80003592 <argint>
    800038d4:	87aa                	mv	a5,a0
    return -1;
    800038d6:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    800038d8:	0007c863          	bltz	a5,800038e8 <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpu_id);
    800038dc:	fec42503          	lw	a0,-20(s0)
    800038e0:	fffff097          	auipc	ra,0xfffff
    800038e4:	136080e7          	jalr	310(ra) # 80002a16 <cpu_process_count>
}
    800038e8:	60e2                	ld	ra,24(sp)
    800038ea:	6442                	ld	s0,16(sp)
    800038ec:	6105                	addi	sp,sp,32
    800038ee:	8082                	ret

00000000800038f0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800038f0:	7179                	addi	sp,sp,-48
    800038f2:	f406                	sd	ra,40(sp)
    800038f4:	f022                	sd	s0,32(sp)
    800038f6:	ec26                	sd	s1,24(sp)
    800038f8:	e84a                	sd	s2,16(sp)
    800038fa:	e44e                	sd	s3,8(sp)
    800038fc:	e052                	sd	s4,0(sp)
    800038fe:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003900:	00005597          	auipc	a1,0x5
    80003904:	f7058593          	addi	a1,a1,-144 # 80008870 <syscalls+0xc8>
    80003908:	00014517          	auipc	a0,0x14
    8000390c:	36050513          	addi	a0,a0,864 # 80017c68 <bcache>
    80003910:	ffffd097          	auipc	ra,0xffffd
    80003914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003918:	0001c797          	auipc	a5,0x1c
    8000391c:	35078793          	addi	a5,a5,848 # 8001fc68 <bcache+0x8000>
    80003920:	0001c717          	auipc	a4,0x1c
    80003924:	5b070713          	addi	a4,a4,1456 # 8001fed0 <bcache+0x8268>
    80003928:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000392c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003930:	00014497          	auipc	s1,0x14
    80003934:	35048493          	addi	s1,s1,848 # 80017c80 <bcache+0x18>
    b->next = bcache.head.next;
    80003938:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000393a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000393c:	00005a17          	auipc	s4,0x5
    80003940:	f3ca0a13          	addi	s4,s4,-196 # 80008878 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003944:	2b893783          	ld	a5,696(s2)
    80003948:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000394a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000394e:	85d2                	mv	a1,s4
    80003950:	01048513          	addi	a0,s1,16
    80003954:	00001097          	auipc	ra,0x1
    80003958:	4bc080e7          	jalr	1212(ra) # 80004e10 <initsleeplock>
    bcache.head.next->prev = b;
    8000395c:	2b893783          	ld	a5,696(s2)
    80003960:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003962:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003966:	45848493          	addi	s1,s1,1112
    8000396a:	fd349de3          	bne	s1,s3,80003944 <binit+0x54>
  }
}
    8000396e:	70a2                	ld	ra,40(sp)
    80003970:	7402                	ld	s0,32(sp)
    80003972:	64e2                	ld	s1,24(sp)
    80003974:	6942                	ld	s2,16(sp)
    80003976:	69a2                	ld	s3,8(sp)
    80003978:	6a02                	ld	s4,0(sp)
    8000397a:	6145                	addi	sp,sp,48
    8000397c:	8082                	ret

000000008000397e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000397e:	7179                	addi	sp,sp,-48
    80003980:	f406                	sd	ra,40(sp)
    80003982:	f022                	sd	s0,32(sp)
    80003984:	ec26                	sd	s1,24(sp)
    80003986:	e84a                	sd	s2,16(sp)
    80003988:	e44e                	sd	s3,8(sp)
    8000398a:	1800                	addi	s0,sp,48
    8000398c:	89aa                	mv	s3,a0
    8000398e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003990:	00014517          	auipc	a0,0x14
    80003994:	2d850513          	addi	a0,a0,728 # 80017c68 <bcache>
    80003998:	ffffd097          	auipc	ra,0xffffd
    8000399c:	24c080e7          	jalr	588(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800039a0:	0001c497          	auipc	s1,0x1c
    800039a4:	5804b483          	ld	s1,1408(s1) # 8001ff20 <bcache+0x82b8>
    800039a8:	0001c797          	auipc	a5,0x1c
    800039ac:	52878793          	addi	a5,a5,1320 # 8001fed0 <bcache+0x8268>
    800039b0:	02f48f63          	beq	s1,a5,800039ee <bread+0x70>
    800039b4:	873e                	mv	a4,a5
    800039b6:	a021                	j	800039be <bread+0x40>
    800039b8:	68a4                	ld	s1,80(s1)
    800039ba:	02e48a63          	beq	s1,a4,800039ee <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800039be:	449c                	lw	a5,8(s1)
    800039c0:	ff379ce3          	bne	a5,s3,800039b8 <bread+0x3a>
    800039c4:	44dc                	lw	a5,12(s1)
    800039c6:	ff2799e3          	bne	a5,s2,800039b8 <bread+0x3a>
      b->refcnt++;
    800039ca:	40bc                	lw	a5,64(s1)
    800039cc:	2785                	addiw	a5,a5,1
    800039ce:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800039d0:	00014517          	auipc	a0,0x14
    800039d4:	29850513          	addi	a0,a0,664 # 80017c68 <bcache>
    800039d8:	ffffd097          	auipc	ra,0xffffd
    800039dc:	2c0080e7          	jalr	704(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800039e0:	01048513          	addi	a0,s1,16
    800039e4:	00001097          	auipc	ra,0x1
    800039e8:	466080e7          	jalr	1126(ra) # 80004e4a <acquiresleep>
      return b;
    800039ec:	a8b9                	j	80003a4a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800039ee:	0001c497          	auipc	s1,0x1c
    800039f2:	52a4b483          	ld	s1,1322(s1) # 8001ff18 <bcache+0x82b0>
    800039f6:	0001c797          	auipc	a5,0x1c
    800039fa:	4da78793          	addi	a5,a5,1242 # 8001fed0 <bcache+0x8268>
    800039fe:	00f48863          	beq	s1,a5,80003a0e <bread+0x90>
    80003a02:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003a04:	40bc                	lw	a5,64(s1)
    80003a06:	cf81                	beqz	a5,80003a1e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003a08:	64a4                	ld	s1,72(s1)
    80003a0a:	fee49de3          	bne	s1,a4,80003a04 <bread+0x86>
  panic("bget: no buffers");
    80003a0e:	00005517          	auipc	a0,0x5
    80003a12:	e7250513          	addi	a0,a0,-398 # 80008880 <syscalls+0xd8>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	b28080e7          	jalr	-1240(ra) # 8000053e <panic>
      b->dev = dev;
    80003a1e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003a22:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003a26:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003a2a:	4785                	li	a5,1
    80003a2c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003a2e:	00014517          	auipc	a0,0x14
    80003a32:	23a50513          	addi	a0,a0,570 # 80017c68 <bcache>
    80003a36:	ffffd097          	auipc	ra,0xffffd
    80003a3a:	262080e7          	jalr	610(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003a3e:	01048513          	addi	a0,s1,16
    80003a42:	00001097          	auipc	ra,0x1
    80003a46:	408080e7          	jalr	1032(ra) # 80004e4a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003a4a:	409c                	lw	a5,0(s1)
    80003a4c:	cb89                	beqz	a5,80003a5e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003a4e:	8526                	mv	a0,s1
    80003a50:	70a2                	ld	ra,40(sp)
    80003a52:	7402                	ld	s0,32(sp)
    80003a54:	64e2                	ld	s1,24(sp)
    80003a56:	6942                	ld	s2,16(sp)
    80003a58:	69a2                	ld	s3,8(sp)
    80003a5a:	6145                	addi	sp,sp,48
    80003a5c:	8082                	ret
    virtio_disk_rw(b, 0);
    80003a5e:	4581                	li	a1,0
    80003a60:	8526                	mv	a0,s1
    80003a62:	00003097          	auipc	ra,0x3
    80003a66:	f14080e7          	jalr	-236(ra) # 80006976 <virtio_disk_rw>
    b->valid = 1;
    80003a6a:	4785                	li	a5,1
    80003a6c:	c09c                	sw	a5,0(s1)
  return b;
    80003a6e:	b7c5                	j	80003a4e <bread+0xd0>

0000000080003a70 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003a70:	1101                	addi	sp,sp,-32
    80003a72:	ec06                	sd	ra,24(sp)
    80003a74:	e822                	sd	s0,16(sp)
    80003a76:	e426                	sd	s1,8(sp)
    80003a78:	1000                	addi	s0,sp,32
    80003a7a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003a7c:	0541                	addi	a0,a0,16
    80003a7e:	00001097          	auipc	ra,0x1
    80003a82:	466080e7          	jalr	1126(ra) # 80004ee4 <holdingsleep>
    80003a86:	cd01                	beqz	a0,80003a9e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003a88:	4585                	li	a1,1
    80003a8a:	8526                	mv	a0,s1
    80003a8c:	00003097          	auipc	ra,0x3
    80003a90:	eea080e7          	jalr	-278(ra) # 80006976 <virtio_disk_rw>
}
    80003a94:	60e2                	ld	ra,24(sp)
    80003a96:	6442                	ld	s0,16(sp)
    80003a98:	64a2                	ld	s1,8(sp)
    80003a9a:	6105                	addi	sp,sp,32
    80003a9c:	8082                	ret
    panic("bwrite");
    80003a9e:	00005517          	auipc	a0,0x5
    80003aa2:	dfa50513          	addi	a0,a0,-518 # 80008898 <syscalls+0xf0>
    80003aa6:	ffffd097          	auipc	ra,0xffffd
    80003aaa:	a98080e7          	jalr	-1384(ra) # 8000053e <panic>

0000000080003aae <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003aae:	1101                	addi	sp,sp,-32
    80003ab0:	ec06                	sd	ra,24(sp)
    80003ab2:	e822                	sd	s0,16(sp)
    80003ab4:	e426                	sd	s1,8(sp)
    80003ab6:	e04a                	sd	s2,0(sp)
    80003ab8:	1000                	addi	s0,sp,32
    80003aba:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003abc:	01050913          	addi	s2,a0,16
    80003ac0:	854a                	mv	a0,s2
    80003ac2:	00001097          	auipc	ra,0x1
    80003ac6:	422080e7          	jalr	1058(ra) # 80004ee4 <holdingsleep>
    80003aca:	c92d                	beqz	a0,80003b3c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003acc:	854a                	mv	a0,s2
    80003ace:	00001097          	auipc	ra,0x1
    80003ad2:	3d2080e7          	jalr	978(ra) # 80004ea0 <releasesleep>

  acquire(&bcache.lock);
    80003ad6:	00014517          	auipc	a0,0x14
    80003ada:	19250513          	addi	a0,a0,402 # 80017c68 <bcache>
    80003ade:	ffffd097          	auipc	ra,0xffffd
    80003ae2:	106080e7          	jalr	262(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003ae6:	40bc                	lw	a5,64(s1)
    80003ae8:	37fd                	addiw	a5,a5,-1
    80003aea:	0007871b          	sext.w	a4,a5
    80003aee:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003af0:	eb05                	bnez	a4,80003b20 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003af2:	68bc                	ld	a5,80(s1)
    80003af4:	64b8                	ld	a4,72(s1)
    80003af6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003af8:	64bc                	ld	a5,72(s1)
    80003afa:	68b8                	ld	a4,80(s1)
    80003afc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003afe:	0001c797          	auipc	a5,0x1c
    80003b02:	16a78793          	addi	a5,a5,362 # 8001fc68 <bcache+0x8000>
    80003b06:	2b87b703          	ld	a4,696(a5)
    80003b0a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003b0c:	0001c717          	auipc	a4,0x1c
    80003b10:	3c470713          	addi	a4,a4,964 # 8001fed0 <bcache+0x8268>
    80003b14:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003b16:	2b87b703          	ld	a4,696(a5)
    80003b1a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003b1c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003b20:	00014517          	auipc	a0,0x14
    80003b24:	14850513          	addi	a0,a0,328 # 80017c68 <bcache>
    80003b28:	ffffd097          	auipc	ra,0xffffd
    80003b2c:	170080e7          	jalr	368(ra) # 80000c98 <release>
}
    80003b30:	60e2                	ld	ra,24(sp)
    80003b32:	6442                	ld	s0,16(sp)
    80003b34:	64a2                	ld	s1,8(sp)
    80003b36:	6902                	ld	s2,0(sp)
    80003b38:	6105                	addi	sp,sp,32
    80003b3a:	8082                	ret
    panic("brelse");
    80003b3c:	00005517          	auipc	a0,0x5
    80003b40:	d6450513          	addi	a0,a0,-668 # 800088a0 <syscalls+0xf8>
    80003b44:	ffffd097          	auipc	ra,0xffffd
    80003b48:	9fa080e7          	jalr	-1542(ra) # 8000053e <panic>

0000000080003b4c <bpin>:

void
bpin(struct buf *b) {
    80003b4c:	1101                	addi	sp,sp,-32
    80003b4e:	ec06                	sd	ra,24(sp)
    80003b50:	e822                	sd	s0,16(sp)
    80003b52:	e426                	sd	s1,8(sp)
    80003b54:	1000                	addi	s0,sp,32
    80003b56:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003b58:	00014517          	auipc	a0,0x14
    80003b5c:	11050513          	addi	a0,a0,272 # 80017c68 <bcache>
    80003b60:	ffffd097          	auipc	ra,0xffffd
    80003b64:	084080e7          	jalr	132(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003b68:	40bc                	lw	a5,64(s1)
    80003b6a:	2785                	addiw	a5,a5,1
    80003b6c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003b6e:	00014517          	auipc	a0,0x14
    80003b72:	0fa50513          	addi	a0,a0,250 # 80017c68 <bcache>
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	122080e7          	jalr	290(ra) # 80000c98 <release>
}
    80003b7e:	60e2                	ld	ra,24(sp)
    80003b80:	6442                	ld	s0,16(sp)
    80003b82:	64a2                	ld	s1,8(sp)
    80003b84:	6105                	addi	sp,sp,32
    80003b86:	8082                	ret

0000000080003b88 <bunpin>:

void
bunpin(struct buf *b) {
    80003b88:	1101                	addi	sp,sp,-32
    80003b8a:	ec06                	sd	ra,24(sp)
    80003b8c:	e822                	sd	s0,16(sp)
    80003b8e:	e426                	sd	s1,8(sp)
    80003b90:	1000                	addi	s0,sp,32
    80003b92:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003b94:	00014517          	auipc	a0,0x14
    80003b98:	0d450513          	addi	a0,a0,212 # 80017c68 <bcache>
    80003b9c:	ffffd097          	auipc	ra,0xffffd
    80003ba0:	048080e7          	jalr	72(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003ba4:	40bc                	lw	a5,64(s1)
    80003ba6:	37fd                	addiw	a5,a5,-1
    80003ba8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003baa:	00014517          	auipc	a0,0x14
    80003bae:	0be50513          	addi	a0,a0,190 # 80017c68 <bcache>
    80003bb2:	ffffd097          	auipc	ra,0xffffd
    80003bb6:	0e6080e7          	jalr	230(ra) # 80000c98 <release>
}
    80003bba:	60e2                	ld	ra,24(sp)
    80003bbc:	6442                	ld	s0,16(sp)
    80003bbe:	64a2                	ld	s1,8(sp)
    80003bc0:	6105                	addi	sp,sp,32
    80003bc2:	8082                	ret

0000000080003bc4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003bc4:	1101                	addi	sp,sp,-32
    80003bc6:	ec06                	sd	ra,24(sp)
    80003bc8:	e822                	sd	s0,16(sp)
    80003bca:	e426                	sd	s1,8(sp)
    80003bcc:	e04a                	sd	s2,0(sp)
    80003bce:	1000                	addi	s0,sp,32
    80003bd0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003bd2:	00d5d59b          	srliw	a1,a1,0xd
    80003bd6:	0001c797          	auipc	a5,0x1c
    80003bda:	76e7a783          	lw	a5,1902(a5) # 80020344 <sb+0x1c>
    80003bde:	9dbd                	addw	a1,a1,a5
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	d9e080e7          	jalr	-610(ra) # 8000397e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003be8:	0074f713          	andi	a4,s1,7
    80003bec:	4785                	li	a5,1
    80003bee:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003bf2:	14ce                	slli	s1,s1,0x33
    80003bf4:	90d9                	srli	s1,s1,0x36
    80003bf6:	00950733          	add	a4,a0,s1
    80003bfa:	05874703          	lbu	a4,88(a4)
    80003bfe:	00e7f6b3          	and	a3,a5,a4
    80003c02:	c69d                	beqz	a3,80003c30 <bfree+0x6c>
    80003c04:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003c06:	94aa                	add	s1,s1,a0
    80003c08:	fff7c793          	not	a5,a5
    80003c0c:	8ff9                	and	a5,a5,a4
    80003c0e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003c12:	00001097          	auipc	ra,0x1
    80003c16:	118080e7          	jalr	280(ra) # 80004d2a <log_write>
  brelse(bp);
    80003c1a:	854a                	mv	a0,s2
    80003c1c:	00000097          	auipc	ra,0x0
    80003c20:	e92080e7          	jalr	-366(ra) # 80003aae <brelse>
}
    80003c24:	60e2                	ld	ra,24(sp)
    80003c26:	6442                	ld	s0,16(sp)
    80003c28:	64a2                	ld	s1,8(sp)
    80003c2a:	6902                	ld	s2,0(sp)
    80003c2c:	6105                	addi	sp,sp,32
    80003c2e:	8082                	ret
    panic("freeing free block");
    80003c30:	00005517          	auipc	a0,0x5
    80003c34:	c7850513          	addi	a0,a0,-904 # 800088a8 <syscalls+0x100>
    80003c38:	ffffd097          	auipc	ra,0xffffd
    80003c3c:	906080e7          	jalr	-1786(ra) # 8000053e <panic>

0000000080003c40 <balloc>:
{
    80003c40:	711d                	addi	sp,sp,-96
    80003c42:	ec86                	sd	ra,88(sp)
    80003c44:	e8a2                	sd	s0,80(sp)
    80003c46:	e4a6                	sd	s1,72(sp)
    80003c48:	e0ca                	sd	s2,64(sp)
    80003c4a:	fc4e                	sd	s3,56(sp)
    80003c4c:	f852                	sd	s4,48(sp)
    80003c4e:	f456                	sd	s5,40(sp)
    80003c50:	f05a                	sd	s6,32(sp)
    80003c52:	ec5e                	sd	s7,24(sp)
    80003c54:	e862                	sd	s8,16(sp)
    80003c56:	e466                	sd	s9,8(sp)
    80003c58:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003c5a:	0001c797          	auipc	a5,0x1c
    80003c5e:	6d27a783          	lw	a5,1746(a5) # 8002032c <sb+0x4>
    80003c62:	cbd1                	beqz	a5,80003cf6 <balloc+0xb6>
    80003c64:	8baa                	mv	s7,a0
    80003c66:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003c68:	0001cb17          	auipc	s6,0x1c
    80003c6c:	6c0b0b13          	addi	s6,s6,1728 # 80020328 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c70:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003c72:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c74:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003c76:	6c89                	lui	s9,0x2
    80003c78:	a831                	j	80003c94 <balloc+0x54>
    brelse(bp);
    80003c7a:	854a                	mv	a0,s2
    80003c7c:	00000097          	auipc	ra,0x0
    80003c80:	e32080e7          	jalr	-462(ra) # 80003aae <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003c84:	015c87bb          	addw	a5,s9,s5
    80003c88:	00078a9b          	sext.w	s5,a5
    80003c8c:	004b2703          	lw	a4,4(s6)
    80003c90:	06eaf363          	bgeu	s5,a4,80003cf6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003c94:	41fad79b          	sraiw	a5,s5,0x1f
    80003c98:	0137d79b          	srliw	a5,a5,0x13
    80003c9c:	015787bb          	addw	a5,a5,s5
    80003ca0:	40d7d79b          	sraiw	a5,a5,0xd
    80003ca4:	01cb2583          	lw	a1,28(s6)
    80003ca8:	9dbd                	addw	a1,a1,a5
    80003caa:	855e                	mv	a0,s7
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	cd2080e7          	jalr	-814(ra) # 8000397e <bread>
    80003cb4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003cb6:	004b2503          	lw	a0,4(s6)
    80003cba:	000a849b          	sext.w	s1,s5
    80003cbe:	8662                	mv	a2,s8
    80003cc0:	faa4fde3          	bgeu	s1,a0,80003c7a <balloc+0x3a>
      m = 1 << (bi % 8);
    80003cc4:	41f6579b          	sraiw	a5,a2,0x1f
    80003cc8:	01d7d69b          	srliw	a3,a5,0x1d
    80003ccc:	00c6873b          	addw	a4,a3,a2
    80003cd0:	00777793          	andi	a5,a4,7
    80003cd4:	9f95                	subw	a5,a5,a3
    80003cd6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003cda:	4037571b          	sraiw	a4,a4,0x3
    80003cde:	00e906b3          	add	a3,s2,a4
    80003ce2:	0586c683          	lbu	a3,88(a3)
    80003ce6:	00d7f5b3          	and	a1,a5,a3
    80003cea:	cd91                	beqz	a1,80003d06 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003cec:	2605                	addiw	a2,a2,1
    80003cee:	2485                	addiw	s1,s1,1
    80003cf0:	fd4618e3          	bne	a2,s4,80003cc0 <balloc+0x80>
    80003cf4:	b759                	j	80003c7a <balloc+0x3a>
  panic("balloc: out of blocks");
    80003cf6:	00005517          	auipc	a0,0x5
    80003cfa:	bca50513          	addi	a0,a0,-1078 # 800088c0 <syscalls+0x118>
    80003cfe:	ffffd097          	auipc	ra,0xffffd
    80003d02:	840080e7          	jalr	-1984(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003d06:	974a                	add	a4,a4,s2
    80003d08:	8fd5                	or	a5,a5,a3
    80003d0a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003d0e:	854a                	mv	a0,s2
    80003d10:	00001097          	auipc	ra,0x1
    80003d14:	01a080e7          	jalr	26(ra) # 80004d2a <log_write>
        brelse(bp);
    80003d18:	854a                	mv	a0,s2
    80003d1a:	00000097          	auipc	ra,0x0
    80003d1e:	d94080e7          	jalr	-620(ra) # 80003aae <brelse>
  bp = bread(dev, bno);
    80003d22:	85a6                	mv	a1,s1
    80003d24:	855e                	mv	a0,s7
    80003d26:	00000097          	auipc	ra,0x0
    80003d2a:	c58080e7          	jalr	-936(ra) # 8000397e <bread>
    80003d2e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003d30:	40000613          	li	a2,1024
    80003d34:	4581                	li	a1,0
    80003d36:	05850513          	addi	a0,a0,88
    80003d3a:	ffffd097          	auipc	ra,0xffffd
    80003d3e:	fa6080e7          	jalr	-90(ra) # 80000ce0 <memset>
  log_write(bp);
    80003d42:	854a                	mv	a0,s2
    80003d44:	00001097          	auipc	ra,0x1
    80003d48:	fe6080e7          	jalr	-26(ra) # 80004d2a <log_write>
  brelse(bp);
    80003d4c:	854a                	mv	a0,s2
    80003d4e:	00000097          	auipc	ra,0x0
    80003d52:	d60080e7          	jalr	-672(ra) # 80003aae <brelse>
}
    80003d56:	8526                	mv	a0,s1
    80003d58:	60e6                	ld	ra,88(sp)
    80003d5a:	6446                	ld	s0,80(sp)
    80003d5c:	64a6                	ld	s1,72(sp)
    80003d5e:	6906                	ld	s2,64(sp)
    80003d60:	79e2                	ld	s3,56(sp)
    80003d62:	7a42                	ld	s4,48(sp)
    80003d64:	7aa2                	ld	s5,40(sp)
    80003d66:	7b02                	ld	s6,32(sp)
    80003d68:	6be2                	ld	s7,24(sp)
    80003d6a:	6c42                	ld	s8,16(sp)
    80003d6c:	6ca2                	ld	s9,8(sp)
    80003d6e:	6125                	addi	sp,sp,96
    80003d70:	8082                	ret

0000000080003d72 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003d72:	7179                	addi	sp,sp,-48
    80003d74:	f406                	sd	ra,40(sp)
    80003d76:	f022                	sd	s0,32(sp)
    80003d78:	ec26                	sd	s1,24(sp)
    80003d7a:	e84a                	sd	s2,16(sp)
    80003d7c:	e44e                	sd	s3,8(sp)
    80003d7e:	e052                	sd	s4,0(sp)
    80003d80:	1800                	addi	s0,sp,48
    80003d82:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003d84:	47ad                	li	a5,11
    80003d86:	04b7fe63          	bgeu	a5,a1,80003de2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003d8a:	ff45849b          	addiw	s1,a1,-12
    80003d8e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003d92:	0ff00793          	li	a5,255
    80003d96:	0ae7e363          	bltu	a5,a4,80003e3c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003d9a:	08052583          	lw	a1,128(a0)
    80003d9e:	c5ad                	beqz	a1,80003e08 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003da0:	00092503          	lw	a0,0(s2)
    80003da4:	00000097          	auipc	ra,0x0
    80003da8:	bda080e7          	jalr	-1062(ra) # 8000397e <bread>
    80003dac:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003dae:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003db2:	02049593          	slli	a1,s1,0x20
    80003db6:	9181                	srli	a1,a1,0x20
    80003db8:	058a                	slli	a1,a1,0x2
    80003dba:	00b784b3          	add	s1,a5,a1
    80003dbe:	0004a983          	lw	s3,0(s1)
    80003dc2:	04098d63          	beqz	s3,80003e1c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003dc6:	8552                	mv	a0,s4
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	ce6080e7          	jalr	-794(ra) # 80003aae <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003dd0:	854e                	mv	a0,s3
    80003dd2:	70a2                	ld	ra,40(sp)
    80003dd4:	7402                	ld	s0,32(sp)
    80003dd6:	64e2                	ld	s1,24(sp)
    80003dd8:	6942                	ld	s2,16(sp)
    80003dda:	69a2                	ld	s3,8(sp)
    80003ddc:	6a02                	ld	s4,0(sp)
    80003dde:	6145                	addi	sp,sp,48
    80003de0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003de2:	02059493          	slli	s1,a1,0x20
    80003de6:	9081                	srli	s1,s1,0x20
    80003de8:	048a                	slli	s1,s1,0x2
    80003dea:	94aa                	add	s1,s1,a0
    80003dec:	0504a983          	lw	s3,80(s1)
    80003df0:	fe0990e3          	bnez	s3,80003dd0 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003df4:	4108                	lw	a0,0(a0)
    80003df6:	00000097          	auipc	ra,0x0
    80003dfa:	e4a080e7          	jalr	-438(ra) # 80003c40 <balloc>
    80003dfe:	0005099b          	sext.w	s3,a0
    80003e02:	0534a823          	sw	s3,80(s1)
    80003e06:	b7e9                	j	80003dd0 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003e08:	4108                	lw	a0,0(a0)
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	e36080e7          	jalr	-458(ra) # 80003c40 <balloc>
    80003e12:	0005059b          	sext.w	a1,a0
    80003e16:	08b92023          	sw	a1,128(s2)
    80003e1a:	b759                	j	80003da0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003e1c:	00092503          	lw	a0,0(s2)
    80003e20:	00000097          	auipc	ra,0x0
    80003e24:	e20080e7          	jalr	-480(ra) # 80003c40 <balloc>
    80003e28:	0005099b          	sext.w	s3,a0
    80003e2c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003e30:	8552                	mv	a0,s4
    80003e32:	00001097          	auipc	ra,0x1
    80003e36:	ef8080e7          	jalr	-264(ra) # 80004d2a <log_write>
    80003e3a:	b771                	j	80003dc6 <bmap+0x54>
  panic("bmap: out of range");
    80003e3c:	00005517          	auipc	a0,0x5
    80003e40:	a9c50513          	addi	a0,a0,-1380 # 800088d8 <syscalls+0x130>
    80003e44:	ffffc097          	auipc	ra,0xffffc
    80003e48:	6fa080e7          	jalr	1786(ra) # 8000053e <panic>

0000000080003e4c <iget>:
{
    80003e4c:	7179                	addi	sp,sp,-48
    80003e4e:	f406                	sd	ra,40(sp)
    80003e50:	f022                	sd	s0,32(sp)
    80003e52:	ec26                	sd	s1,24(sp)
    80003e54:	e84a                	sd	s2,16(sp)
    80003e56:	e44e                	sd	s3,8(sp)
    80003e58:	e052                	sd	s4,0(sp)
    80003e5a:	1800                	addi	s0,sp,48
    80003e5c:	89aa                	mv	s3,a0
    80003e5e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003e60:	0001c517          	auipc	a0,0x1c
    80003e64:	4e850513          	addi	a0,a0,1256 # 80020348 <itable>
    80003e68:	ffffd097          	auipc	ra,0xffffd
    80003e6c:	d7c080e7          	jalr	-644(ra) # 80000be4 <acquire>
  empty = 0;
    80003e70:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003e72:	0001c497          	auipc	s1,0x1c
    80003e76:	4ee48493          	addi	s1,s1,1262 # 80020360 <itable+0x18>
    80003e7a:	0001e697          	auipc	a3,0x1e
    80003e7e:	f7668693          	addi	a3,a3,-138 # 80021df0 <log>
    80003e82:	a039                	j	80003e90 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003e84:	02090b63          	beqz	s2,80003eba <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003e88:	08848493          	addi	s1,s1,136
    80003e8c:	02d48a63          	beq	s1,a3,80003ec0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003e90:	449c                	lw	a5,8(s1)
    80003e92:	fef059e3          	blez	a5,80003e84 <iget+0x38>
    80003e96:	4098                	lw	a4,0(s1)
    80003e98:	ff3716e3          	bne	a4,s3,80003e84 <iget+0x38>
    80003e9c:	40d8                	lw	a4,4(s1)
    80003e9e:	ff4713e3          	bne	a4,s4,80003e84 <iget+0x38>
      ip->ref++;
    80003ea2:	2785                	addiw	a5,a5,1
    80003ea4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003ea6:	0001c517          	auipc	a0,0x1c
    80003eaa:	4a250513          	addi	a0,a0,1186 # 80020348 <itable>
    80003eae:	ffffd097          	auipc	ra,0xffffd
    80003eb2:	dea080e7          	jalr	-534(ra) # 80000c98 <release>
      return ip;
    80003eb6:	8926                	mv	s2,s1
    80003eb8:	a03d                	j	80003ee6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003eba:	f7f9                	bnez	a5,80003e88 <iget+0x3c>
    80003ebc:	8926                	mv	s2,s1
    80003ebe:	b7e9                	j	80003e88 <iget+0x3c>
  if(empty == 0)
    80003ec0:	02090c63          	beqz	s2,80003ef8 <iget+0xac>
  ip->dev = dev;
    80003ec4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003ec8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003ecc:	4785                	li	a5,1
    80003ece:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003ed2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003ed6:	0001c517          	auipc	a0,0x1c
    80003eda:	47250513          	addi	a0,a0,1138 # 80020348 <itable>
    80003ede:	ffffd097          	auipc	ra,0xffffd
    80003ee2:	dba080e7          	jalr	-582(ra) # 80000c98 <release>
}
    80003ee6:	854a                	mv	a0,s2
    80003ee8:	70a2                	ld	ra,40(sp)
    80003eea:	7402                	ld	s0,32(sp)
    80003eec:	64e2                	ld	s1,24(sp)
    80003eee:	6942                	ld	s2,16(sp)
    80003ef0:	69a2                	ld	s3,8(sp)
    80003ef2:	6a02                	ld	s4,0(sp)
    80003ef4:	6145                	addi	sp,sp,48
    80003ef6:	8082                	ret
    panic("iget: no inodes");
    80003ef8:	00005517          	auipc	a0,0x5
    80003efc:	9f850513          	addi	a0,a0,-1544 # 800088f0 <syscalls+0x148>
    80003f00:	ffffc097          	auipc	ra,0xffffc
    80003f04:	63e080e7          	jalr	1598(ra) # 8000053e <panic>

0000000080003f08 <fsinit>:
fsinit(int dev) {
    80003f08:	7179                	addi	sp,sp,-48
    80003f0a:	f406                	sd	ra,40(sp)
    80003f0c:	f022                	sd	s0,32(sp)
    80003f0e:	ec26                	sd	s1,24(sp)
    80003f10:	e84a                	sd	s2,16(sp)
    80003f12:	e44e                	sd	s3,8(sp)
    80003f14:	1800                	addi	s0,sp,48
    80003f16:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003f18:	4585                	li	a1,1
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	a64080e7          	jalr	-1436(ra) # 8000397e <bread>
    80003f22:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003f24:	0001c997          	auipc	s3,0x1c
    80003f28:	40498993          	addi	s3,s3,1028 # 80020328 <sb>
    80003f2c:	02000613          	li	a2,32
    80003f30:	05850593          	addi	a1,a0,88
    80003f34:	854e                	mv	a0,s3
    80003f36:	ffffd097          	auipc	ra,0xffffd
    80003f3a:	e0a080e7          	jalr	-502(ra) # 80000d40 <memmove>
  brelse(bp);
    80003f3e:	8526                	mv	a0,s1
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	b6e080e7          	jalr	-1170(ra) # 80003aae <brelse>
  if(sb.magic != FSMAGIC)
    80003f48:	0009a703          	lw	a4,0(s3)
    80003f4c:	102037b7          	lui	a5,0x10203
    80003f50:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003f54:	02f71263          	bne	a4,a5,80003f78 <fsinit+0x70>
  initlog(dev, &sb);
    80003f58:	0001c597          	auipc	a1,0x1c
    80003f5c:	3d058593          	addi	a1,a1,976 # 80020328 <sb>
    80003f60:	854a                	mv	a0,s2
    80003f62:	00001097          	auipc	ra,0x1
    80003f66:	b4c080e7          	jalr	-1204(ra) # 80004aae <initlog>
}
    80003f6a:	70a2                	ld	ra,40(sp)
    80003f6c:	7402                	ld	s0,32(sp)
    80003f6e:	64e2                	ld	s1,24(sp)
    80003f70:	6942                	ld	s2,16(sp)
    80003f72:	69a2                	ld	s3,8(sp)
    80003f74:	6145                	addi	sp,sp,48
    80003f76:	8082                	ret
    panic("invalid file system");
    80003f78:	00005517          	auipc	a0,0x5
    80003f7c:	98850513          	addi	a0,a0,-1656 # 80008900 <syscalls+0x158>
    80003f80:	ffffc097          	auipc	ra,0xffffc
    80003f84:	5be080e7          	jalr	1470(ra) # 8000053e <panic>

0000000080003f88 <iinit>:
{
    80003f88:	7179                	addi	sp,sp,-48
    80003f8a:	f406                	sd	ra,40(sp)
    80003f8c:	f022                	sd	s0,32(sp)
    80003f8e:	ec26                	sd	s1,24(sp)
    80003f90:	e84a                	sd	s2,16(sp)
    80003f92:	e44e                	sd	s3,8(sp)
    80003f94:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003f96:	00005597          	auipc	a1,0x5
    80003f9a:	98258593          	addi	a1,a1,-1662 # 80008918 <syscalls+0x170>
    80003f9e:	0001c517          	auipc	a0,0x1c
    80003fa2:	3aa50513          	addi	a0,a0,938 # 80020348 <itable>
    80003fa6:	ffffd097          	auipc	ra,0xffffd
    80003faa:	bae080e7          	jalr	-1106(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003fae:	0001c497          	auipc	s1,0x1c
    80003fb2:	3c248493          	addi	s1,s1,962 # 80020370 <itable+0x28>
    80003fb6:	0001e997          	auipc	s3,0x1e
    80003fba:	e4a98993          	addi	s3,s3,-438 # 80021e00 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003fbe:	00005917          	auipc	s2,0x5
    80003fc2:	96290913          	addi	s2,s2,-1694 # 80008920 <syscalls+0x178>
    80003fc6:	85ca                	mv	a1,s2
    80003fc8:	8526                	mv	a0,s1
    80003fca:	00001097          	auipc	ra,0x1
    80003fce:	e46080e7          	jalr	-442(ra) # 80004e10 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003fd2:	08848493          	addi	s1,s1,136
    80003fd6:	ff3498e3          	bne	s1,s3,80003fc6 <iinit+0x3e>
}
    80003fda:	70a2                	ld	ra,40(sp)
    80003fdc:	7402                	ld	s0,32(sp)
    80003fde:	64e2                	ld	s1,24(sp)
    80003fe0:	6942                	ld	s2,16(sp)
    80003fe2:	69a2                	ld	s3,8(sp)
    80003fe4:	6145                	addi	sp,sp,48
    80003fe6:	8082                	ret

0000000080003fe8 <ialloc>:
{
    80003fe8:	715d                	addi	sp,sp,-80
    80003fea:	e486                	sd	ra,72(sp)
    80003fec:	e0a2                	sd	s0,64(sp)
    80003fee:	fc26                	sd	s1,56(sp)
    80003ff0:	f84a                	sd	s2,48(sp)
    80003ff2:	f44e                	sd	s3,40(sp)
    80003ff4:	f052                	sd	s4,32(sp)
    80003ff6:	ec56                	sd	s5,24(sp)
    80003ff8:	e85a                	sd	s6,16(sp)
    80003ffa:	e45e                	sd	s7,8(sp)
    80003ffc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ffe:	0001c717          	auipc	a4,0x1c
    80004002:	33672703          	lw	a4,822(a4) # 80020334 <sb+0xc>
    80004006:	4785                	li	a5,1
    80004008:	04e7fa63          	bgeu	a5,a4,8000405c <ialloc+0x74>
    8000400c:	8aaa                	mv	s5,a0
    8000400e:	8bae                	mv	s7,a1
    80004010:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004012:	0001ca17          	auipc	s4,0x1c
    80004016:	316a0a13          	addi	s4,s4,790 # 80020328 <sb>
    8000401a:	00048b1b          	sext.w	s6,s1
    8000401e:	0044d593          	srli	a1,s1,0x4
    80004022:	018a2783          	lw	a5,24(s4)
    80004026:	9dbd                	addw	a1,a1,a5
    80004028:	8556                	mv	a0,s5
    8000402a:	00000097          	auipc	ra,0x0
    8000402e:	954080e7          	jalr	-1708(ra) # 8000397e <bread>
    80004032:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004034:	05850993          	addi	s3,a0,88
    80004038:	00f4f793          	andi	a5,s1,15
    8000403c:	079a                	slli	a5,a5,0x6
    8000403e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004040:	00099783          	lh	a5,0(s3)
    80004044:	c785                	beqz	a5,8000406c <ialloc+0x84>
    brelse(bp);
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	a68080e7          	jalr	-1432(ra) # 80003aae <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000404e:	0485                	addi	s1,s1,1
    80004050:	00ca2703          	lw	a4,12(s4)
    80004054:	0004879b          	sext.w	a5,s1
    80004058:	fce7e1e3          	bltu	a5,a4,8000401a <ialloc+0x32>
  panic("ialloc: no inodes");
    8000405c:	00005517          	auipc	a0,0x5
    80004060:	8cc50513          	addi	a0,a0,-1844 # 80008928 <syscalls+0x180>
    80004064:	ffffc097          	auipc	ra,0xffffc
    80004068:	4da080e7          	jalr	1242(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    8000406c:	04000613          	li	a2,64
    80004070:	4581                	li	a1,0
    80004072:	854e                	mv	a0,s3
    80004074:	ffffd097          	auipc	ra,0xffffd
    80004078:	c6c080e7          	jalr	-916(ra) # 80000ce0 <memset>
      dip->type = type;
    8000407c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004080:	854a                	mv	a0,s2
    80004082:	00001097          	auipc	ra,0x1
    80004086:	ca8080e7          	jalr	-856(ra) # 80004d2a <log_write>
      brelse(bp);
    8000408a:	854a                	mv	a0,s2
    8000408c:	00000097          	auipc	ra,0x0
    80004090:	a22080e7          	jalr	-1502(ra) # 80003aae <brelse>
      return iget(dev, inum);
    80004094:	85da                	mv	a1,s6
    80004096:	8556                	mv	a0,s5
    80004098:	00000097          	auipc	ra,0x0
    8000409c:	db4080e7          	jalr	-588(ra) # 80003e4c <iget>
}
    800040a0:	60a6                	ld	ra,72(sp)
    800040a2:	6406                	ld	s0,64(sp)
    800040a4:	74e2                	ld	s1,56(sp)
    800040a6:	7942                	ld	s2,48(sp)
    800040a8:	79a2                	ld	s3,40(sp)
    800040aa:	7a02                	ld	s4,32(sp)
    800040ac:	6ae2                	ld	s5,24(sp)
    800040ae:	6b42                	ld	s6,16(sp)
    800040b0:	6ba2                	ld	s7,8(sp)
    800040b2:	6161                	addi	sp,sp,80
    800040b4:	8082                	ret

00000000800040b6 <iupdate>:
{
    800040b6:	1101                	addi	sp,sp,-32
    800040b8:	ec06                	sd	ra,24(sp)
    800040ba:	e822                	sd	s0,16(sp)
    800040bc:	e426                	sd	s1,8(sp)
    800040be:	e04a                	sd	s2,0(sp)
    800040c0:	1000                	addi	s0,sp,32
    800040c2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800040c4:	415c                	lw	a5,4(a0)
    800040c6:	0047d79b          	srliw	a5,a5,0x4
    800040ca:	0001c597          	auipc	a1,0x1c
    800040ce:	2765a583          	lw	a1,630(a1) # 80020340 <sb+0x18>
    800040d2:	9dbd                	addw	a1,a1,a5
    800040d4:	4108                	lw	a0,0(a0)
    800040d6:	00000097          	auipc	ra,0x0
    800040da:	8a8080e7          	jalr	-1880(ra) # 8000397e <bread>
    800040de:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800040e0:	05850793          	addi	a5,a0,88
    800040e4:	40c8                	lw	a0,4(s1)
    800040e6:	893d                	andi	a0,a0,15
    800040e8:	051a                	slli	a0,a0,0x6
    800040ea:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800040ec:	04449703          	lh	a4,68(s1)
    800040f0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800040f4:	04649703          	lh	a4,70(s1)
    800040f8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800040fc:	04849703          	lh	a4,72(s1)
    80004100:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004104:	04a49703          	lh	a4,74(s1)
    80004108:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000410c:	44f8                	lw	a4,76(s1)
    8000410e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004110:	03400613          	li	a2,52
    80004114:	05048593          	addi	a1,s1,80
    80004118:	0531                	addi	a0,a0,12
    8000411a:	ffffd097          	auipc	ra,0xffffd
    8000411e:	c26080e7          	jalr	-986(ra) # 80000d40 <memmove>
  log_write(bp);
    80004122:	854a                	mv	a0,s2
    80004124:	00001097          	auipc	ra,0x1
    80004128:	c06080e7          	jalr	-1018(ra) # 80004d2a <log_write>
  brelse(bp);
    8000412c:	854a                	mv	a0,s2
    8000412e:	00000097          	auipc	ra,0x0
    80004132:	980080e7          	jalr	-1664(ra) # 80003aae <brelse>
}
    80004136:	60e2                	ld	ra,24(sp)
    80004138:	6442                	ld	s0,16(sp)
    8000413a:	64a2                	ld	s1,8(sp)
    8000413c:	6902                	ld	s2,0(sp)
    8000413e:	6105                	addi	sp,sp,32
    80004140:	8082                	ret

0000000080004142 <idup>:
{
    80004142:	1101                	addi	sp,sp,-32
    80004144:	ec06                	sd	ra,24(sp)
    80004146:	e822                	sd	s0,16(sp)
    80004148:	e426                	sd	s1,8(sp)
    8000414a:	1000                	addi	s0,sp,32
    8000414c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000414e:	0001c517          	auipc	a0,0x1c
    80004152:	1fa50513          	addi	a0,a0,506 # 80020348 <itable>
    80004156:	ffffd097          	auipc	ra,0xffffd
    8000415a:	a8e080e7          	jalr	-1394(ra) # 80000be4 <acquire>
  ip->ref++;
    8000415e:	449c                	lw	a5,8(s1)
    80004160:	2785                	addiw	a5,a5,1
    80004162:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004164:	0001c517          	auipc	a0,0x1c
    80004168:	1e450513          	addi	a0,a0,484 # 80020348 <itable>
    8000416c:	ffffd097          	auipc	ra,0xffffd
    80004170:	b2c080e7          	jalr	-1236(ra) # 80000c98 <release>
}
    80004174:	8526                	mv	a0,s1
    80004176:	60e2                	ld	ra,24(sp)
    80004178:	6442                	ld	s0,16(sp)
    8000417a:	64a2                	ld	s1,8(sp)
    8000417c:	6105                	addi	sp,sp,32
    8000417e:	8082                	ret

0000000080004180 <ilock>:
{
    80004180:	1101                	addi	sp,sp,-32
    80004182:	ec06                	sd	ra,24(sp)
    80004184:	e822                	sd	s0,16(sp)
    80004186:	e426                	sd	s1,8(sp)
    80004188:	e04a                	sd	s2,0(sp)
    8000418a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000418c:	c115                	beqz	a0,800041b0 <ilock+0x30>
    8000418e:	84aa                	mv	s1,a0
    80004190:	451c                	lw	a5,8(a0)
    80004192:	00f05f63          	blez	a5,800041b0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80004196:	0541                	addi	a0,a0,16
    80004198:	00001097          	auipc	ra,0x1
    8000419c:	cb2080e7          	jalr	-846(ra) # 80004e4a <acquiresleep>
  if(ip->valid == 0){
    800041a0:	40bc                	lw	a5,64(s1)
    800041a2:	cf99                	beqz	a5,800041c0 <ilock+0x40>
}
    800041a4:	60e2                	ld	ra,24(sp)
    800041a6:	6442                	ld	s0,16(sp)
    800041a8:	64a2                	ld	s1,8(sp)
    800041aa:	6902                	ld	s2,0(sp)
    800041ac:	6105                	addi	sp,sp,32
    800041ae:	8082                	ret
    panic("ilock");
    800041b0:	00004517          	auipc	a0,0x4
    800041b4:	79050513          	addi	a0,a0,1936 # 80008940 <syscalls+0x198>
    800041b8:	ffffc097          	auipc	ra,0xffffc
    800041bc:	386080e7          	jalr	902(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800041c0:	40dc                	lw	a5,4(s1)
    800041c2:	0047d79b          	srliw	a5,a5,0x4
    800041c6:	0001c597          	auipc	a1,0x1c
    800041ca:	17a5a583          	lw	a1,378(a1) # 80020340 <sb+0x18>
    800041ce:	9dbd                	addw	a1,a1,a5
    800041d0:	4088                	lw	a0,0(s1)
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	7ac080e7          	jalr	1964(ra) # 8000397e <bread>
    800041da:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800041dc:	05850593          	addi	a1,a0,88
    800041e0:	40dc                	lw	a5,4(s1)
    800041e2:	8bbd                	andi	a5,a5,15
    800041e4:	079a                	slli	a5,a5,0x6
    800041e6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800041e8:	00059783          	lh	a5,0(a1)
    800041ec:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800041f0:	00259783          	lh	a5,2(a1)
    800041f4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800041f8:	00459783          	lh	a5,4(a1)
    800041fc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004200:	00659783          	lh	a5,6(a1)
    80004204:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004208:	459c                	lw	a5,8(a1)
    8000420a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000420c:	03400613          	li	a2,52
    80004210:	05b1                	addi	a1,a1,12
    80004212:	05048513          	addi	a0,s1,80
    80004216:	ffffd097          	auipc	ra,0xffffd
    8000421a:	b2a080e7          	jalr	-1238(ra) # 80000d40 <memmove>
    brelse(bp);
    8000421e:	854a                	mv	a0,s2
    80004220:	00000097          	auipc	ra,0x0
    80004224:	88e080e7          	jalr	-1906(ra) # 80003aae <brelse>
    ip->valid = 1;
    80004228:	4785                	li	a5,1
    8000422a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000422c:	04449783          	lh	a5,68(s1)
    80004230:	fbb5                	bnez	a5,800041a4 <ilock+0x24>
      panic("ilock: no type");
    80004232:	00004517          	auipc	a0,0x4
    80004236:	71650513          	addi	a0,a0,1814 # 80008948 <syscalls+0x1a0>
    8000423a:	ffffc097          	auipc	ra,0xffffc
    8000423e:	304080e7          	jalr	772(ra) # 8000053e <panic>

0000000080004242 <iunlock>:
{
    80004242:	1101                	addi	sp,sp,-32
    80004244:	ec06                	sd	ra,24(sp)
    80004246:	e822                	sd	s0,16(sp)
    80004248:	e426                	sd	s1,8(sp)
    8000424a:	e04a                	sd	s2,0(sp)
    8000424c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000424e:	c905                	beqz	a0,8000427e <iunlock+0x3c>
    80004250:	84aa                	mv	s1,a0
    80004252:	01050913          	addi	s2,a0,16
    80004256:	854a                	mv	a0,s2
    80004258:	00001097          	auipc	ra,0x1
    8000425c:	c8c080e7          	jalr	-884(ra) # 80004ee4 <holdingsleep>
    80004260:	cd19                	beqz	a0,8000427e <iunlock+0x3c>
    80004262:	449c                	lw	a5,8(s1)
    80004264:	00f05d63          	blez	a5,8000427e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004268:	854a                	mv	a0,s2
    8000426a:	00001097          	auipc	ra,0x1
    8000426e:	c36080e7          	jalr	-970(ra) # 80004ea0 <releasesleep>
}
    80004272:	60e2                	ld	ra,24(sp)
    80004274:	6442                	ld	s0,16(sp)
    80004276:	64a2                	ld	s1,8(sp)
    80004278:	6902                	ld	s2,0(sp)
    8000427a:	6105                	addi	sp,sp,32
    8000427c:	8082                	ret
    panic("iunlock");
    8000427e:	00004517          	auipc	a0,0x4
    80004282:	6da50513          	addi	a0,a0,1754 # 80008958 <syscalls+0x1b0>
    80004286:	ffffc097          	auipc	ra,0xffffc
    8000428a:	2b8080e7          	jalr	696(ra) # 8000053e <panic>

000000008000428e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000428e:	7179                	addi	sp,sp,-48
    80004290:	f406                	sd	ra,40(sp)
    80004292:	f022                	sd	s0,32(sp)
    80004294:	ec26                	sd	s1,24(sp)
    80004296:	e84a                	sd	s2,16(sp)
    80004298:	e44e                	sd	s3,8(sp)
    8000429a:	e052                	sd	s4,0(sp)
    8000429c:	1800                	addi	s0,sp,48
    8000429e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800042a0:	05050493          	addi	s1,a0,80
    800042a4:	08050913          	addi	s2,a0,128
    800042a8:	a021                	j	800042b0 <itrunc+0x22>
    800042aa:	0491                	addi	s1,s1,4
    800042ac:	01248d63          	beq	s1,s2,800042c6 <itrunc+0x38>
    if(ip->addrs[i]){
    800042b0:	408c                	lw	a1,0(s1)
    800042b2:	dde5                	beqz	a1,800042aa <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800042b4:	0009a503          	lw	a0,0(s3)
    800042b8:	00000097          	auipc	ra,0x0
    800042bc:	90c080e7          	jalr	-1780(ra) # 80003bc4 <bfree>
      ip->addrs[i] = 0;
    800042c0:	0004a023          	sw	zero,0(s1)
    800042c4:	b7dd                	j	800042aa <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800042c6:	0809a583          	lw	a1,128(s3)
    800042ca:	e185                	bnez	a1,800042ea <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800042cc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800042d0:	854e                	mv	a0,s3
    800042d2:	00000097          	auipc	ra,0x0
    800042d6:	de4080e7          	jalr	-540(ra) # 800040b6 <iupdate>
}
    800042da:	70a2                	ld	ra,40(sp)
    800042dc:	7402                	ld	s0,32(sp)
    800042de:	64e2                	ld	s1,24(sp)
    800042e0:	6942                	ld	s2,16(sp)
    800042e2:	69a2                	ld	s3,8(sp)
    800042e4:	6a02                	ld	s4,0(sp)
    800042e6:	6145                	addi	sp,sp,48
    800042e8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800042ea:	0009a503          	lw	a0,0(s3)
    800042ee:	fffff097          	auipc	ra,0xfffff
    800042f2:	690080e7          	jalr	1680(ra) # 8000397e <bread>
    800042f6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800042f8:	05850493          	addi	s1,a0,88
    800042fc:	45850913          	addi	s2,a0,1112
    80004300:	a811                	j	80004314 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004302:	0009a503          	lw	a0,0(s3)
    80004306:	00000097          	auipc	ra,0x0
    8000430a:	8be080e7          	jalr	-1858(ra) # 80003bc4 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000430e:	0491                	addi	s1,s1,4
    80004310:	01248563          	beq	s1,s2,8000431a <itrunc+0x8c>
      if(a[j])
    80004314:	408c                	lw	a1,0(s1)
    80004316:	dde5                	beqz	a1,8000430e <itrunc+0x80>
    80004318:	b7ed                	j	80004302 <itrunc+0x74>
    brelse(bp);
    8000431a:	8552                	mv	a0,s4
    8000431c:	fffff097          	auipc	ra,0xfffff
    80004320:	792080e7          	jalr	1938(ra) # 80003aae <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004324:	0809a583          	lw	a1,128(s3)
    80004328:	0009a503          	lw	a0,0(s3)
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	898080e7          	jalr	-1896(ra) # 80003bc4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004334:	0809a023          	sw	zero,128(s3)
    80004338:	bf51                	j	800042cc <itrunc+0x3e>

000000008000433a <iput>:
{
    8000433a:	1101                	addi	sp,sp,-32
    8000433c:	ec06                	sd	ra,24(sp)
    8000433e:	e822                	sd	s0,16(sp)
    80004340:	e426                	sd	s1,8(sp)
    80004342:	e04a                	sd	s2,0(sp)
    80004344:	1000                	addi	s0,sp,32
    80004346:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004348:	0001c517          	auipc	a0,0x1c
    8000434c:	00050513          	mv	a0,a0
    80004350:	ffffd097          	auipc	ra,0xffffd
    80004354:	894080e7          	jalr	-1900(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004358:	4498                	lw	a4,8(s1)
    8000435a:	4785                	li	a5,1
    8000435c:	02f70363          	beq	a4,a5,80004382 <iput+0x48>
  ip->ref--;
    80004360:	449c                	lw	a5,8(s1)
    80004362:	37fd                	addiw	a5,a5,-1
    80004364:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004366:	0001c517          	auipc	a0,0x1c
    8000436a:	fe250513          	addi	a0,a0,-30 # 80020348 <itable>
    8000436e:	ffffd097          	auipc	ra,0xffffd
    80004372:	92a080e7          	jalr	-1750(ra) # 80000c98 <release>
}
    80004376:	60e2                	ld	ra,24(sp)
    80004378:	6442                	ld	s0,16(sp)
    8000437a:	64a2                	ld	s1,8(sp)
    8000437c:	6902                	ld	s2,0(sp)
    8000437e:	6105                	addi	sp,sp,32
    80004380:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004382:	40bc                	lw	a5,64(s1)
    80004384:	dff1                	beqz	a5,80004360 <iput+0x26>
    80004386:	04a49783          	lh	a5,74(s1)
    8000438a:	fbf9                	bnez	a5,80004360 <iput+0x26>
    acquiresleep(&ip->lock);
    8000438c:	01048913          	addi	s2,s1,16
    80004390:	854a                	mv	a0,s2
    80004392:	00001097          	auipc	ra,0x1
    80004396:	ab8080e7          	jalr	-1352(ra) # 80004e4a <acquiresleep>
    release(&itable.lock);
    8000439a:	0001c517          	auipc	a0,0x1c
    8000439e:	fae50513          	addi	a0,a0,-82 # 80020348 <itable>
    800043a2:	ffffd097          	auipc	ra,0xffffd
    800043a6:	8f6080e7          	jalr	-1802(ra) # 80000c98 <release>
    itrunc(ip);
    800043aa:	8526                	mv	a0,s1
    800043ac:	00000097          	auipc	ra,0x0
    800043b0:	ee2080e7          	jalr	-286(ra) # 8000428e <itrunc>
    ip->type = 0;
    800043b4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800043b8:	8526                	mv	a0,s1
    800043ba:	00000097          	auipc	ra,0x0
    800043be:	cfc080e7          	jalr	-772(ra) # 800040b6 <iupdate>
    ip->valid = 0;
    800043c2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800043c6:	854a                	mv	a0,s2
    800043c8:	00001097          	auipc	ra,0x1
    800043cc:	ad8080e7          	jalr	-1320(ra) # 80004ea0 <releasesleep>
    acquire(&itable.lock);
    800043d0:	0001c517          	auipc	a0,0x1c
    800043d4:	f7850513          	addi	a0,a0,-136 # 80020348 <itable>
    800043d8:	ffffd097          	auipc	ra,0xffffd
    800043dc:	80c080e7          	jalr	-2036(ra) # 80000be4 <acquire>
    800043e0:	b741                	j	80004360 <iput+0x26>

00000000800043e2 <iunlockput>:
{
    800043e2:	1101                	addi	sp,sp,-32
    800043e4:	ec06                	sd	ra,24(sp)
    800043e6:	e822                	sd	s0,16(sp)
    800043e8:	e426                	sd	s1,8(sp)
    800043ea:	1000                	addi	s0,sp,32
    800043ec:	84aa                	mv	s1,a0
  iunlock(ip);
    800043ee:	00000097          	auipc	ra,0x0
    800043f2:	e54080e7          	jalr	-428(ra) # 80004242 <iunlock>
  iput(ip);
    800043f6:	8526                	mv	a0,s1
    800043f8:	00000097          	auipc	ra,0x0
    800043fc:	f42080e7          	jalr	-190(ra) # 8000433a <iput>
}
    80004400:	60e2                	ld	ra,24(sp)
    80004402:	6442                	ld	s0,16(sp)
    80004404:	64a2                	ld	s1,8(sp)
    80004406:	6105                	addi	sp,sp,32
    80004408:	8082                	ret

000000008000440a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000440a:	1141                	addi	sp,sp,-16
    8000440c:	e422                	sd	s0,8(sp)
    8000440e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004410:	411c                	lw	a5,0(a0)
    80004412:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004414:	415c                	lw	a5,4(a0)
    80004416:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004418:	04451783          	lh	a5,68(a0)
    8000441c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004420:	04a51783          	lh	a5,74(a0)
    80004424:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004428:	04c56783          	lwu	a5,76(a0)
    8000442c:	e99c                	sd	a5,16(a1)
}
    8000442e:	6422                	ld	s0,8(sp)
    80004430:	0141                	addi	sp,sp,16
    80004432:	8082                	ret

0000000080004434 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004434:	457c                	lw	a5,76(a0)
    80004436:	0ed7e963          	bltu	a5,a3,80004528 <readi+0xf4>
{
    8000443a:	7159                	addi	sp,sp,-112
    8000443c:	f486                	sd	ra,104(sp)
    8000443e:	f0a2                	sd	s0,96(sp)
    80004440:	eca6                	sd	s1,88(sp)
    80004442:	e8ca                	sd	s2,80(sp)
    80004444:	e4ce                	sd	s3,72(sp)
    80004446:	e0d2                	sd	s4,64(sp)
    80004448:	fc56                	sd	s5,56(sp)
    8000444a:	f85a                	sd	s6,48(sp)
    8000444c:	f45e                	sd	s7,40(sp)
    8000444e:	f062                	sd	s8,32(sp)
    80004450:	ec66                	sd	s9,24(sp)
    80004452:	e86a                	sd	s10,16(sp)
    80004454:	e46e                	sd	s11,8(sp)
    80004456:	1880                	addi	s0,sp,112
    80004458:	8baa                	mv	s7,a0
    8000445a:	8c2e                	mv	s8,a1
    8000445c:	8ab2                	mv	s5,a2
    8000445e:	84b6                	mv	s1,a3
    80004460:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004462:	9f35                	addw	a4,a4,a3
    return 0;
    80004464:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004466:	0ad76063          	bltu	a4,a3,80004506 <readi+0xd2>
  if(off + n > ip->size)
    8000446a:	00e7f463          	bgeu	a5,a4,80004472 <readi+0x3e>
    n = ip->size - off;
    8000446e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004472:	0a0b0963          	beqz	s6,80004524 <readi+0xf0>
    80004476:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004478:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000447c:	5cfd                	li	s9,-1
    8000447e:	a82d                	j	800044b8 <readi+0x84>
    80004480:	020a1d93          	slli	s11,s4,0x20
    80004484:	020ddd93          	srli	s11,s11,0x20
    80004488:	05890613          	addi	a2,s2,88
    8000448c:	86ee                	mv	a3,s11
    8000448e:	963a                	add	a2,a2,a4
    80004490:	85d6                	mv	a1,s5
    80004492:	8562                	mv	a0,s8
    80004494:	ffffe097          	auipc	ra,0xffffe
    80004498:	372080e7          	jalr	882(ra) # 80002806 <either_copyout>
    8000449c:	05950d63          	beq	a0,s9,800044f6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800044a0:	854a                	mv	a0,s2
    800044a2:	fffff097          	auipc	ra,0xfffff
    800044a6:	60c080e7          	jalr	1548(ra) # 80003aae <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800044aa:	013a09bb          	addw	s3,s4,s3
    800044ae:	009a04bb          	addw	s1,s4,s1
    800044b2:	9aee                	add	s5,s5,s11
    800044b4:	0569f763          	bgeu	s3,s6,80004502 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800044b8:	000ba903          	lw	s2,0(s7)
    800044bc:	00a4d59b          	srliw	a1,s1,0xa
    800044c0:	855e                	mv	a0,s7
    800044c2:	00000097          	auipc	ra,0x0
    800044c6:	8b0080e7          	jalr	-1872(ra) # 80003d72 <bmap>
    800044ca:	0005059b          	sext.w	a1,a0
    800044ce:	854a                	mv	a0,s2
    800044d0:	fffff097          	auipc	ra,0xfffff
    800044d4:	4ae080e7          	jalr	1198(ra) # 8000397e <bread>
    800044d8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800044da:	3ff4f713          	andi	a4,s1,1023
    800044de:	40ed07bb          	subw	a5,s10,a4
    800044e2:	413b06bb          	subw	a3,s6,s3
    800044e6:	8a3e                	mv	s4,a5
    800044e8:	2781                	sext.w	a5,a5
    800044ea:	0006861b          	sext.w	a2,a3
    800044ee:	f8f679e3          	bgeu	a2,a5,80004480 <readi+0x4c>
    800044f2:	8a36                	mv	s4,a3
    800044f4:	b771                	j	80004480 <readi+0x4c>
      brelse(bp);
    800044f6:	854a                	mv	a0,s2
    800044f8:	fffff097          	auipc	ra,0xfffff
    800044fc:	5b6080e7          	jalr	1462(ra) # 80003aae <brelse>
      tot = -1;
    80004500:	59fd                	li	s3,-1
  }
  return tot;
    80004502:	0009851b          	sext.w	a0,s3
}
    80004506:	70a6                	ld	ra,104(sp)
    80004508:	7406                	ld	s0,96(sp)
    8000450a:	64e6                	ld	s1,88(sp)
    8000450c:	6946                	ld	s2,80(sp)
    8000450e:	69a6                	ld	s3,72(sp)
    80004510:	6a06                	ld	s4,64(sp)
    80004512:	7ae2                	ld	s5,56(sp)
    80004514:	7b42                	ld	s6,48(sp)
    80004516:	7ba2                	ld	s7,40(sp)
    80004518:	7c02                	ld	s8,32(sp)
    8000451a:	6ce2                	ld	s9,24(sp)
    8000451c:	6d42                	ld	s10,16(sp)
    8000451e:	6da2                	ld	s11,8(sp)
    80004520:	6165                	addi	sp,sp,112
    80004522:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004524:	89da                	mv	s3,s6
    80004526:	bff1                	j	80004502 <readi+0xce>
    return 0;
    80004528:	4501                	li	a0,0
}
    8000452a:	8082                	ret

000000008000452c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000452c:	457c                	lw	a5,76(a0)
    8000452e:	10d7e863          	bltu	a5,a3,8000463e <writei+0x112>
{
    80004532:	7159                	addi	sp,sp,-112
    80004534:	f486                	sd	ra,104(sp)
    80004536:	f0a2                	sd	s0,96(sp)
    80004538:	eca6                	sd	s1,88(sp)
    8000453a:	e8ca                	sd	s2,80(sp)
    8000453c:	e4ce                	sd	s3,72(sp)
    8000453e:	e0d2                	sd	s4,64(sp)
    80004540:	fc56                	sd	s5,56(sp)
    80004542:	f85a                	sd	s6,48(sp)
    80004544:	f45e                	sd	s7,40(sp)
    80004546:	f062                	sd	s8,32(sp)
    80004548:	ec66                	sd	s9,24(sp)
    8000454a:	e86a                	sd	s10,16(sp)
    8000454c:	e46e                	sd	s11,8(sp)
    8000454e:	1880                	addi	s0,sp,112
    80004550:	8b2a                	mv	s6,a0
    80004552:	8c2e                	mv	s8,a1
    80004554:	8ab2                	mv	s5,a2
    80004556:	8936                	mv	s2,a3
    80004558:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000455a:	00e687bb          	addw	a5,a3,a4
    8000455e:	0ed7e263          	bltu	a5,a3,80004642 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004562:	00043737          	lui	a4,0x43
    80004566:	0ef76063          	bltu	a4,a5,80004646 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000456a:	0c0b8863          	beqz	s7,8000463a <writei+0x10e>
    8000456e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004570:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004574:	5cfd                	li	s9,-1
    80004576:	a091                	j	800045ba <writei+0x8e>
    80004578:	02099d93          	slli	s11,s3,0x20
    8000457c:	020ddd93          	srli	s11,s11,0x20
    80004580:	05848513          	addi	a0,s1,88
    80004584:	86ee                	mv	a3,s11
    80004586:	8656                	mv	a2,s5
    80004588:	85e2                	mv	a1,s8
    8000458a:	953a                	add	a0,a0,a4
    8000458c:	ffffe097          	auipc	ra,0xffffe
    80004590:	2d0080e7          	jalr	720(ra) # 8000285c <either_copyin>
    80004594:	07950263          	beq	a0,s9,800045f8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004598:	8526                	mv	a0,s1
    8000459a:	00000097          	auipc	ra,0x0
    8000459e:	790080e7          	jalr	1936(ra) # 80004d2a <log_write>
    brelse(bp);
    800045a2:	8526                	mv	a0,s1
    800045a4:	fffff097          	auipc	ra,0xfffff
    800045a8:	50a080e7          	jalr	1290(ra) # 80003aae <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800045ac:	01498a3b          	addw	s4,s3,s4
    800045b0:	0129893b          	addw	s2,s3,s2
    800045b4:	9aee                	add	s5,s5,s11
    800045b6:	057a7663          	bgeu	s4,s7,80004602 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800045ba:	000b2483          	lw	s1,0(s6)
    800045be:	00a9559b          	srliw	a1,s2,0xa
    800045c2:	855a                	mv	a0,s6
    800045c4:	fffff097          	auipc	ra,0xfffff
    800045c8:	7ae080e7          	jalr	1966(ra) # 80003d72 <bmap>
    800045cc:	0005059b          	sext.w	a1,a0
    800045d0:	8526                	mv	a0,s1
    800045d2:	fffff097          	auipc	ra,0xfffff
    800045d6:	3ac080e7          	jalr	940(ra) # 8000397e <bread>
    800045da:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800045dc:	3ff97713          	andi	a4,s2,1023
    800045e0:	40ed07bb          	subw	a5,s10,a4
    800045e4:	414b86bb          	subw	a3,s7,s4
    800045e8:	89be                	mv	s3,a5
    800045ea:	2781                	sext.w	a5,a5
    800045ec:	0006861b          	sext.w	a2,a3
    800045f0:	f8f674e3          	bgeu	a2,a5,80004578 <writei+0x4c>
    800045f4:	89b6                	mv	s3,a3
    800045f6:	b749                	j	80004578 <writei+0x4c>
      brelse(bp);
    800045f8:	8526                	mv	a0,s1
    800045fa:	fffff097          	auipc	ra,0xfffff
    800045fe:	4b4080e7          	jalr	1204(ra) # 80003aae <brelse>
  }

  if(off > ip->size)
    80004602:	04cb2783          	lw	a5,76(s6)
    80004606:	0127f463          	bgeu	a5,s2,8000460e <writei+0xe2>
    ip->size = off;
    8000460a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000460e:	855a                	mv	a0,s6
    80004610:	00000097          	auipc	ra,0x0
    80004614:	aa6080e7          	jalr	-1370(ra) # 800040b6 <iupdate>

  return tot;
    80004618:	000a051b          	sext.w	a0,s4
}
    8000461c:	70a6                	ld	ra,104(sp)
    8000461e:	7406                	ld	s0,96(sp)
    80004620:	64e6                	ld	s1,88(sp)
    80004622:	6946                	ld	s2,80(sp)
    80004624:	69a6                	ld	s3,72(sp)
    80004626:	6a06                	ld	s4,64(sp)
    80004628:	7ae2                	ld	s5,56(sp)
    8000462a:	7b42                	ld	s6,48(sp)
    8000462c:	7ba2                	ld	s7,40(sp)
    8000462e:	7c02                	ld	s8,32(sp)
    80004630:	6ce2                	ld	s9,24(sp)
    80004632:	6d42                	ld	s10,16(sp)
    80004634:	6da2                	ld	s11,8(sp)
    80004636:	6165                	addi	sp,sp,112
    80004638:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000463a:	8a5e                	mv	s4,s7
    8000463c:	bfc9                	j	8000460e <writei+0xe2>
    return -1;
    8000463e:	557d                	li	a0,-1
}
    80004640:	8082                	ret
    return -1;
    80004642:	557d                	li	a0,-1
    80004644:	bfe1                	j	8000461c <writei+0xf0>
    return -1;
    80004646:	557d                	li	a0,-1
    80004648:	bfd1                	j	8000461c <writei+0xf0>

000000008000464a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000464a:	1141                	addi	sp,sp,-16
    8000464c:	e406                	sd	ra,8(sp)
    8000464e:	e022                	sd	s0,0(sp)
    80004650:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004652:	4639                	li	a2,14
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	764080e7          	jalr	1892(ra) # 80000db8 <strncmp>
}
    8000465c:	60a2                	ld	ra,8(sp)
    8000465e:	6402                	ld	s0,0(sp)
    80004660:	0141                	addi	sp,sp,16
    80004662:	8082                	ret

0000000080004664 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004664:	7139                	addi	sp,sp,-64
    80004666:	fc06                	sd	ra,56(sp)
    80004668:	f822                	sd	s0,48(sp)
    8000466a:	f426                	sd	s1,40(sp)
    8000466c:	f04a                	sd	s2,32(sp)
    8000466e:	ec4e                	sd	s3,24(sp)
    80004670:	e852                	sd	s4,16(sp)
    80004672:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004674:	04451703          	lh	a4,68(a0)
    80004678:	4785                	li	a5,1
    8000467a:	00f71a63          	bne	a4,a5,8000468e <dirlookup+0x2a>
    8000467e:	892a                	mv	s2,a0
    80004680:	89ae                	mv	s3,a1
    80004682:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004684:	457c                	lw	a5,76(a0)
    80004686:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004688:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000468a:	e79d                	bnez	a5,800046b8 <dirlookup+0x54>
    8000468c:	a8a5                	j	80004704 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000468e:	00004517          	auipc	a0,0x4
    80004692:	2d250513          	addi	a0,a0,722 # 80008960 <syscalls+0x1b8>
    80004696:	ffffc097          	auipc	ra,0xffffc
    8000469a:	ea8080e7          	jalr	-344(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000469e:	00004517          	auipc	a0,0x4
    800046a2:	2da50513          	addi	a0,a0,730 # 80008978 <syscalls+0x1d0>
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	e98080e7          	jalr	-360(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046ae:	24c1                	addiw	s1,s1,16
    800046b0:	04c92783          	lw	a5,76(s2)
    800046b4:	04f4f763          	bgeu	s1,a5,80004702 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046b8:	4741                	li	a4,16
    800046ba:	86a6                	mv	a3,s1
    800046bc:	fc040613          	addi	a2,s0,-64
    800046c0:	4581                	li	a1,0
    800046c2:	854a                	mv	a0,s2
    800046c4:	00000097          	auipc	ra,0x0
    800046c8:	d70080e7          	jalr	-656(ra) # 80004434 <readi>
    800046cc:	47c1                	li	a5,16
    800046ce:	fcf518e3          	bne	a0,a5,8000469e <dirlookup+0x3a>
    if(de.inum == 0)
    800046d2:	fc045783          	lhu	a5,-64(s0)
    800046d6:	dfe1                	beqz	a5,800046ae <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800046d8:	fc240593          	addi	a1,s0,-62
    800046dc:	854e                	mv	a0,s3
    800046de:	00000097          	auipc	ra,0x0
    800046e2:	f6c080e7          	jalr	-148(ra) # 8000464a <namecmp>
    800046e6:	f561                	bnez	a0,800046ae <dirlookup+0x4a>
      if(poff)
    800046e8:	000a0463          	beqz	s4,800046f0 <dirlookup+0x8c>
        *poff = off;
    800046ec:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800046f0:	fc045583          	lhu	a1,-64(s0)
    800046f4:	00092503          	lw	a0,0(s2)
    800046f8:	fffff097          	auipc	ra,0xfffff
    800046fc:	754080e7          	jalr	1876(ra) # 80003e4c <iget>
    80004700:	a011                	j	80004704 <dirlookup+0xa0>
  return 0;
    80004702:	4501                	li	a0,0
}
    80004704:	70e2                	ld	ra,56(sp)
    80004706:	7442                	ld	s0,48(sp)
    80004708:	74a2                	ld	s1,40(sp)
    8000470a:	7902                	ld	s2,32(sp)
    8000470c:	69e2                	ld	s3,24(sp)
    8000470e:	6a42                	ld	s4,16(sp)
    80004710:	6121                	addi	sp,sp,64
    80004712:	8082                	ret

0000000080004714 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004714:	711d                	addi	sp,sp,-96
    80004716:	ec86                	sd	ra,88(sp)
    80004718:	e8a2                	sd	s0,80(sp)
    8000471a:	e4a6                	sd	s1,72(sp)
    8000471c:	e0ca                	sd	s2,64(sp)
    8000471e:	fc4e                	sd	s3,56(sp)
    80004720:	f852                	sd	s4,48(sp)
    80004722:	f456                	sd	s5,40(sp)
    80004724:	f05a                	sd	s6,32(sp)
    80004726:	ec5e                	sd	s7,24(sp)
    80004728:	e862                	sd	s8,16(sp)
    8000472a:	e466                	sd	s9,8(sp)
    8000472c:	1080                	addi	s0,sp,96
    8000472e:	84aa                	mv	s1,a0
    80004730:	8b2e                	mv	s6,a1
    80004732:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004734:	00054703          	lbu	a4,0(a0)
    80004738:	02f00793          	li	a5,47
    8000473c:	02f70363          	beq	a4,a5,80004762 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004740:	ffffe097          	auipc	ra,0xffffe
    80004744:	80e080e7          	jalr	-2034(ra) # 80001f4e <myproc>
    80004748:	15053503          	ld	a0,336(a0)
    8000474c:	00000097          	auipc	ra,0x0
    80004750:	9f6080e7          	jalr	-1546(ra) # 80004142 <idup>
    80004754:	89aa                	mv	s3,a0
  while(*path == '/')
    80004756:	02f00913          	li	s2,47
  len = path - s;
    8000475a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000475c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000475e:	4c05                	li	s8,1
    80004760:	a865                	j	80004818 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004762:	4585                	li	a1,1
    80004764:	4505                	li	a0,1
    80004766:	fffff097          	auipc	ra,0xfffff
    8000476a:	6e6080e7          	jalr	1766(ra) # 80003e4c <iget>
    8000476e:	89aa                	mv	s3,a0
    80004770:	b7dd                	j	80004756 <namex+0x42>
      iunlockput(ip);
    80004772:	854e                	mv	a0,s3
    80004774:	00000097          	auipc	ra,0x0
    80004778:	c6e080e7          	jalr	-914(ra) # 800043e2 <iunlockput>
      return 0;
    8000477c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000477e:	854e                	mv	a0,s3
    80004780:	60e6                	ld	ra,88(sp)
    80004782:	6446                	ld	s0,80(sp)
    80004784:	64a6                	ld	s1,72(sp)
    80004786:	6906                	ld	s2,64(sp)
    80004788:	79e2                	ld	s3,56(sp)
    8000478a:	7a42                	ld	s4,48(sp)
    8000478c:	7aa2                	ld	s5,40(sp)
    8000478e:	7b02                	ld	s6,32(sp)
    80004790:	6be2                	ld	s7,24(sp)
    80004792:	6c42                	ld	s8,16(sp)
    80004794:	6ca2                	ld	s9,8(sp)
    80004796:	6125                	addi	sp,sp,96
    80004798:	8082                	ret
      iunlock(ip);
    8000479a:	854e                	mv	a0,s3
    8000479c:	00000097          	auipc	ra,0x0
    800047a0:	aa6080e7          	jalr	-1370(ra) # 80004242 <iunlock>
      return ip;
    800047a4:	bfe9                	j	8000477e <namex+0x6a>
      iunlockput(ip);
    800047a6:	854e                	mv	a0,s3
    800047a8:	00000097          	auipc	ra,0x0
    800047ac:	c3a080e7          	jalr	-966(ra) # 800043e2 <iunlockput>
      return 0;
    800047b0:	89d2                	mv	s3,s4
    800047b2:	b7f1                	j	8000477e <namex+0x6a>
  len = path - s;
    800047b4:	40b48633          	sub	a2,s1,a1
    800047b8:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800047bc:	094cd463          	bge	s9,s4,80004844 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800047c0:	4639                	li	a2,14
    800047c2:	8556                	mv	a0,s5
    800047c4:	ffffc097          	auipc	ra,0xffffc
    800047c8:	57c080e7          	jalr	1404(ra) # 80000d40 <memmove>
  while(*path == '/')
    800047cc:	0004c783          	lbu	a5,0(s1)
    800047d0:	01279763          	bne	a5,s2,800047de <namex+0xca>
    path++;
    800047d4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800047d6:	0004c783          	lbu	a5,0(s1)
    800047da:	ff278de3          	beq	a5,s2,800047d4 <namex+0xc0>
    ilock(ip);
    800047de:	854e                	mv	a0,s3
    800047e0:	00000097          	auipc	ra,0x0
    800047e4:	9a0080e7          	jalr	-1632(ra) # 80004180 <ilock>
    if(ip->type != T_DIR){
    800047e8:	04499783          	lh	a5,68(s3)
    800047ec:	f98793e3          	bne	a5,s8,80004772 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800047f0:	000b0563          	beqz	s6,800047fa <namex+0xe6>
    800047f4:	0004c783          	lbu	a5,0(s1)
    800047f8:	d3cd                	beqz	a5,8000479a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800047fa:	865e                	mv	a2,s7
    800047fc:	85d6                	mv	a1,s5
    800047fe:	854e                	mv	a0,s3
    80004800:	00000097          	auipc	ra,0x0
    80004804:	e64080e7          	jalr	-412(ra) # 80004664 <dirlookup>
    80004808:	8a2a                	mv	s4,a0
    8000480a:	dd51                	beqz	a0,800047a6 <namex+0x92>
    iunlockput(ip);
    8000480c:	854e                	mv	a0,s3
    8000480e:	00000097          	auipc	ra,0x0
    80004812:	bd4080e7          	jalr	-1068(ra) # 800043e2 <iunlockput>
    ip = next;
    80004816:	89d2                	mv	s3,s4
  while(*path == '/')
    80004818:	0004c783          	lbu	a5,0(s1)
    8000481c:	05279763          	bne	a5,s2,8000486a <namex+0x156>
    path++;
    80004820:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004822:	0004c783          	lbu	a5,0(s1)
    80004826:	ff278de3          	beq	a5,s2,80004820 <namex+0x10c>
  if(*path == 0)
    8000482a:	c79d                	beqz	a5,80004858 <namex+0x144>
    path++;
    8000482c:	85a6                	mv	a1,s1
  len = path - s;
    8000482e:	8a5e                	mv	s4,s7
    80004830:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004832:	01278963          	beq	a5,s2,80004844 <namex+0x130>
    80004836:	dfbd                	beqz	a5,800047b4 <namex+0xa0>
    path++;
    80004838:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000483a:	0004c783          	lbu	a5,0(s1)
    8000483e:	ff279ce3          	bne	a5,s2,80004836 <namex+0x122>
    80004842:	bf8d                	j	800047b4 <namex+0xa0>
    memmove(name, s, len);
    80004844:	2601                	sext.w	a2,a2
    80004846:	8556                	mv	a0,s5
    80004848:	ffffc097          	auipc	ra,0xffffc
    8000484c:	4f8080e7          	jalr	1272(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004850:	9a56                	add	s4,s4,s5
    80004852:	000a0023          	sb	zero,0(s4)
    80004856:	bf9d                	j	800047cc <namex+0xb8>
  if(nameiparent){
    80004858:	f20b03e3          	beqz	s6,8000477e <namex+0x6a>
    iput(ip);
    8000485c:	854e                	mv	a0,s3
    8000485e:	00000097          	auipc	ra,0x0
    80004862:	adc080e7          	jalr	-1316(ra) # 8000433a <iput>
    return 0;
    80004866:	4981                	li	s3,0
    80004868:	bf19                	j	8000477e <namex+0x6a>
  if(*path == 0)
    8000486a:	d7fd                	beqz	a5,80004858 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000486c:	0004c783          	lbu	a5,0(s1)
    80004870:	85a6                	mv	a1,s1
    80004872:	b7d1                	j	80004836 <namex+0x122>

0000000080004874 <dirlink>:
{
    80004874:	7139                	addi	sp,sp,-64
    80004876:	fc06                	sd	ra,56(sp)
    80004878:	f822                	sd	s0,48(sp)
    8000487a:	f426                	sd	s1,40(sp)
    8000487c:	f04a                	sd	s2,32(sp)
    8000487e:	ec4e                	sd	s3,24(sp)
    80004880:	e852                	sd	s4,16(sp)
    80004882:	0080                	addi	s0,sp,64
    80004884:	892a                	mv	s2,a0
    80004886:	8a2e                	mv	s4,a1
    80004888:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000488a:	4601                	li	a2,0
    8000488c:	00000097          	auipc	ra,0x0
    80004890:	dd8080e7          	jalr	-552(ra) # 80004664 <dirlookup>
    80004894:	e93d                	bnez	a0,8000490a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004896:	04c92483          	lw	s1,76(s2)
    8000489a:	c49d                	beqz	s1,800048c8 <dirlink+0x54>
    8000489c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000489e:	4741                	li	a4,16
    800048a0:	86a6                	mv	a3,s1
    800048a2:	fc040613          	addi	a2,s0,-64
    800048a6:	4581                	li	a1,0
    800048a8:	854a                	mv	a0,s2
    800048aa:	00000097          	auipc	ra,0x0
    800048ae:	b8a080e7          	jalr	-1142(ra) # 80004434 <readi>
    800048b2:	47c1                	li	a5,16
    800048b4:	06f51163          	bne	a0,a5,80004916 <dirlink+0xa2>
    if(de.inum == 0)
    800048b8:	fc045783          	lhu	a5,-64(s0)
    800048bc:	c791                	beqz	a5,800048c8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800048be:	24c1                	addiw	s1,s1,16
    800048c0:	04c92783          	lw	a5,76(s2)
    800048c4:	fcf4ede3          	bltu	s1,a5,8000489e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800048c8:	4639                	li	a2,14
    800048ca:	85d2                	mv	a1,s4
    800048cc:	fc240513          	addi	a0,s0,-62
    800048d0:	ffffc097          	auipc	ra,0xffffc
    800048d4:	524080e7          	jalr	1316(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800048d8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800048dc:	4741                	li	a4,16
    800048de:	86a6                	mv	a3,s1
    800048e0:	fc040613          	addi	a2,s0,-64
    800048e4:	4581                	li	a1,0
    800048e6:	854a                	mv	a0,s2
    800048e8:	00000097          	auipc	ra,0x0
    800048ec:	c44080e7          	jalr	-956(ra) # 8000452c <writei>
    800048f0:	872a                	mv	a4,a0
    800048f2:	47c1                	li	a5,16
  return 0;
    800048f4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800048f6:	02f71863          	bne	a4,a5,80004926 <dirlink+0xb2>
}
    800048fa:	70e2                	ld	ra,56(sp)
    800048fc:	7442                	ld	s0,48(sp)
    800048fe:	74a2                	ld	s1,40(sp)
    80004900:	7902                	ld	s2,32(sp)
    80004902:	69e2                	ld	s3,24(sp)
    80004904:	6a42                	ld	s4,16(sp)
    80004906:	6121                	addi	sp,sp,64
    80004908:	8082                	ret
    iput(ip);
    8000490a:	00000097          	auipc	ra,0x0
    8000490e:	a30080e7          	jalr	-1488(ra) # 8000433a <iput>
    return -1;
    80004912:	557d                	li	a0,-1
    80004914:	b7dd                	j	800048fa <dirlink+0x86>
      panic("dirlink read");
    80004916:	00004517          	auipc	a0,0x4
    8000491a:	07250513          	addi	a0,a0,114 # 80008988 <syscalls+0x1e0>
    8000491e:	ffffc097          	auipc	ra,0xffffc
    80004922:	c20080e7          	jalr	-992(ra) # 8000053e <panic>
    panic("dirlink");
    80004926:	00004517          	auipc	a0,0x4
    8000492a:	17250513          	addi	a0,a0,370 # 80008a98 <syscalls+0x2f0>
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	c10080e7          	jalr	-1008(ra) # 8000053e <panic>

0000000080004936 <namei>:

struct inode*
namei(char *path)
{
    80004936:	1101                	addi	sp,sp,-32
    80004938:	ec06                	sd	ra,24(sp)
    8000493a:	e822                	sd	s0,16(sp)
    8000493c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000493e:	fe040613          	addi	a2,s0,-32
    80004942:	4581                	li	a1,0
    80004944:	00000097          	auipc	ra,0x0
    80004948:	dd0080e7          	jalr	-560(ra) # 80004714 <namex>
}
    8000494c:	60e2                	ld	ra,24(sp)
    8000494e:	6442                	ld	s0,16(sp)
    80004950:	6105                	addi	sp,sp,32
    80004952:	8082                	ret

0000000080004954 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004954:	1141                	addi	sp,sp,-16
    80004956:	e406                	sd	ra,8(sp)
    80004958:	e022                	sd	s0,0(sp)
    8000495a:	0800                	addi	s0,sp,16
    8000495c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000495e:	4585                	li	a1,1
    80004960:	00000097          	auipc	ra,0x0
    80004964:	db4080e7          	jalr	-588(ra) # 80004714 <namex>
}
    80004968:	60a2                	ld	ra,8(sp)
    8000496a:	6402                	ld	s0,0(sp)
    8000496c:	0141                	addi	sp,sp,16
    8000496e:	8082                	ret

0000000080004970 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004970:	1101                	addi	sp,sp,-32
    80004972:	ec06                	sd	ra,24(sp)
    80004974:	e822                	sd	s0,16(sp)
    80004976:	e426                	sd	s1,8(sp)
    80004978:	e04a                	sd	s2,0(sp)
    8000497a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000497c:	0001d917          	auipc	s2,0x1d
    80004980:	47490913          	addi	s2,s2,1140 # 80021df0 <log>
    80004984:	01892583          	lw	a1,24(s2)
    80004988:	02892503          	lw	a0,40(s2)
    8000498c:	fffff097          	auipc	ra,0xfffff
    80004990:	ff2080e7          	jalr	-14(ra) # 8000397e <bread>
    80004994:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004996:	02c92683          	lw	a3,44(s2)
    8000499a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000499c:	02d05763          	blez	a3,800049ca <write_head+0x5a>
    800049a0:	0001d797          	auipc	a5,0x1d
    800049a4:	48078793          	addi	a5,a5,1152 # 80021e20 <log+0x30>
    800049a8:	05c50713          	addi	a4,a0,92
    800049ac:	36fd                	addiw	a3,a3,-1
    800049ae:	1682                	slli	a3,a3,0x20
    800049b0:	9281                	srli	a3,a3,0x20
    800049b2:	068a                	slli	a3,a3,0x2
    800049b4:	0001d617          	auipc	a2,0x1d
    800049b8:	47060613          	addi	a2,a2,1136 # 80021e24 <log+0x34>
    800049bc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800049be:	4390                	lw	a2,0(a5)
    800049c0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800049c2:	0791                	addi	a5,a5,4
    800049c4:	0711                	addi	a4,a4,4
    800049c6:	fed79ce3          	bne	a5,a3,800049be <write_head+0x4e>
  }
  bwrite(buf);
    800049ca:	8526                	mv	a0,s1
    800049cc:	fffff097          	auipc	ra,0xfffff
    800049d0:	0a4080e7          	jalr	164(ra) # 80003a70 <bwrite>
  brelse(buf);
    800049d4:	8526                	mv	a0,s1
    800049d6:	fffff097          	auipc	ra,0xfffff
    800049da:	0d8080e7          	jalr	216(ra) # 80003aae <brelse>
}
    800049de:	60e2                	ld	ra,24(sp)
    800049e0:	6442                	ld	s0,16(sp)
    800049e2:	64a2                	ld	s1,8(sp)
    800049e4:	6902                	ld	s2,0(sp)
    800049e6:	6105                	addi	sp,sp,32
    800049e8:	8082                	ret

00000000800049ea <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800049ea:	0001d797          	auipc	a5,0x1d
    800049ee:	4327a783          	lw	a5,1074(a5) # 80021e1c <log+0x2c>
    800049f2:	0af05d63          	blez	a5,80004aac <install_trans+0xc2>
{
    800049f6:	7139                	addi	sp,sp,-64
    800049f8:	fc06                	sd	ra,56(sp)
    800049fa:	f822                	sd	s0,48(sp)
    800049fc:	f426                	sd	s1,40(sp)
    800049fe:	f04a                	sd	s2,32(sp)
    80004a00:	ec4e                	sd	s3,24(sp)
    80004a02:	e852                	sd	s4,16(sp)
    80004a04:	e456                	sd	s5,8(sp)
    80004a06:	e05a                	sd	s6,0(sp)
    80004a08:	0080                	addi	s0,sp,64
    80004a0a:	8b2a                	mv	s6,a0
    80004a0c:	0001da97          	auipc	s5,0x1d
    80004a10:	414a8a93          	addi	s5,s5,1044 # 80021e20 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a14:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004a16:	0001d997          	auipc	s3,0x1d
    80004a1a:	3da98993          	addi	s3,s3,986 # 80021df0 <log>
    80004a1e:	a035                	j	80004a4a <install_trans+0x60>
      bunpin(dbuf);
    80004a20:	8526                	mv	a0,s1
    80004a22:	fffff097          	auipc	ra,0xfffff
    80004a26:	166080e7          	jalr	358(ra) # 80003b88 <bunpin>
    brelse(lbuf);
    80004a2a:	854a                	mv	a0,s2
    80004a2c:	fffff097          	auipc	ra,0xfffff
    80004a30:	082080e7          	jalr	130(ra) # 80003aae <brelse>
    brelse(dbuf);
    80004a34:	8526                	mv	a0,s1
    80004a36:	fffff097          	auipc	ra,0xfffff
    80004a3a:	078080e7          	jalr	120(ra) # 80003aae <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a3e:	2a05                	addiw	s4,s4,1
    80004a40:	0a91                	addi	s5,s5,4
    80004a42:	02c9a783          	lw	a5,44(s3)
    80004a46:	04fa5963          	bge	s4,a5,80004a98 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004a4a:	0189a583          	lw	a1,24(s3)
    80004a4e:	014585bb          	addw	a1,a1,s4
    80004a52:	2585                	addiw	a1,a1,1
    80004a54:	0289a503          	lw	a0,40(s3)
    80004a58:	fffff097          	auipc	ra,0xfffff
    80004a5c:	f26080e7          	jalr	-218(ra) # 8000397e <bread>
    80004a60:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004a62:	000aa583          	lw	a1,0(s5)
    80004a66:	0289a503          	lw	a0,40(s3)
    80004a6a:	fffff097          	auipc	ra,0xfffff
    80004a6e:	f14080e7          	jalr	-236(ra) # 8000397e <bread>
    80004a72:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004a74:	40000613          	li	a2,1024
    80004a78:	05890593          	addi	a1,s2,88
    80004a7c:	05850513          	addi	a0,a0,88
    80004a80:	ffffc097          	auipc	ra,0xffffc
    80004a84:	2c0080e7          	jalr	704(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004a88:	8526                	mv	a0,s1
    80004a8a:	fffff097          	auipc	ra,0xfffff
    80004a8e:	fe6080e7          	jalr	-26(ra) # 80003a70 <bwrite>
    if(recovering == 0)
    80004a92:	f80b1ce3          	bnez	s6,80004a2a <install_trans+0x40>
    80004a96:	b769                	j	80004a20 <install_trans+0x36>
}
    80004a98:	70e2                	ld	ra,56(sp)
    80004a9a:	7442                	ld	s0,48(sp)
    80004a9c:	74a2                	ld	s1,40(sp)
    80004a9e:	7902                	ld	s2,32(sp)
    80004aa0:	69e2                	ld	s3,24(sp)
    80004aa2:	6a42                	ld	s4,16(sp)
    80004aa4:	6aa2                	ld	s5,8(sp)
    80004aa6:	6b02                	ld	s6,0(sp)
    80004aa8:	6121                	addi	sp,sp,64
    80004aaa:	8082                	ret
    80004aac:	8082                	ret

0000000080004aae <initlog>:
{
    80004aae:	7179                	addi	sp,sp,-48
    80004ab0:	f406                	sd	ra,40(sp)
    80004ab2:	f022                	sd	s0,32(sp)
    80004ab4:	ec26                	sd	s1,24(sp)
    80004ab6:	e84a                	sd	s2,16(sp)
    80004ab8:	e44e                	sd	s3,8(sp)
    80004aba:	1800                	addi	s0,sp,48
    80004abc:	892a                	mv	s2,a0
    80004abe:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004ac0:	0001d497          	auipc	s1,0x1d
    80004ac4:	33048493          	addi	s1,s1,816 # 80021df0 <log>
    80004ac8:	00004597          	auipc	a1,0x4
    80004acc:	ed058593          	addi	a1,a1,-304 # 80008998 <syscalls+0x1f0>
    80004ad0:	8526                	mv	a0,s1
    80004ad2:	ffffc097          	auipc	ra,0xffffc
    80004ad6:	082080e7          	jalr	130(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004ada:	0149a583          	lw	a1,20(s3)
    80004ade:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004ae0:	0109a783          	lw	a5,16(s3)
    80004ae4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004ae6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004aea:	854a                	mv	a0,s2
    80004aec:	fffff097          	auipc	ra,0xfffff
    80004af0:	e92080e7          	jalr	-366(ra) # 8000397e <bread>
  log.lh.n = lh->n;
    80004af4:	4d3c                	lw	a5,88(a0)
    80004af6:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004af8:	02f05563          	blez	a5,80004b22 <initlog+0x74>
    80004afc:	05c50713          	addi	a4,a0,92
    80004b00:	0001d697          	auipc	a3,0x1d
    80004b04:	32068693          	addi	a3,a3,800 # 80021e20 <log+0x30>
    80004b08:	37fd                	addiw	a5,a5,-1
    80004b0a:	1782                	slli	a5,a5,0x20
    80004b0c:	9381                	srli	a5,a5,0x20
    80004b0e:	078a                	slli	a5,a5,0x2
    80004b10:	06050613          	addi	a2,a0,96
    80004b14:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004b16:	4310                	lw	a2,0(a4)
    80004b18:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004b1a:	0711                	addi	a4,a4,4
    80004b1c:	0691                	addi	a3,a3,4
    80004b1e:	fef71ce3          	bne	a4,a5,80004b16 <initlog+0x68>
  brelse(buf);
    80004b22:	fffff097          	auipc	ra,0xfffff
    80004b26:	f8c080e7          	jalr	-116(ra) # 80003aae <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004b2a:	4505                	li	a0,1
    80004b2c:	00000097          	auipc	ra,0x0
    80004b30:	ebe080e7          	jalr	-322(ra) # 800049ea <install_trans>
  log.lh.n = 0;
    80004b34:	0001d797          	auipc	a5,0x1d
    80004b38:	2e07a423          	sw	zero,744(a5) # 80021e1c <log+0x2c>
  write_head(); // clear the log
    80004b3c:	00000097          	auipc	ra,0x0
    80004b40:	e34080e7          	jalr	-460(ra) # 80004970 <write_head>
}
    80004b44:	70a2                	ld	ra,40(sp)
    80004b46:	7402                	ld	s0,32(sp)
    80004b48:	64e2                	ld	s1,24(sp)
    80004b4a:	6942                	ld	s2,16(sp)
    80004b4c:	69a2                	ld	s3,8(sp)
    80004b4e:	6145                	addi	sp,sp,48
    80004b50:	8082                	ret

0000000080004b52 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004b52:	1101                	addi	sp,sp,-32
    80004b54:	ec06                	sd	ra,24(sp)
    80004b56:	e822                	sd	s0,16(sp)
    80004b58:	e426                	sd	s1,8(sp)
    80004b5a:	e04a                	sd	s2,0(sp)
    80004b5c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004b5e:	0001d517          	auipc	a0,0x1d
    80004b62:	29250513          	addi	a0,a0,658 # 80021df0 <log>
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	07e080e7          	jalr	126(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004b6e:	0001d497          	auipc	s1,0x1d
    80004b72:	28248493          	addi	s1,s1,642 # 80021df0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004b76:	4979                	li	s2,30
    80004b78:	a039                	j	80004b86 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004b7a:	85a6                	mv	a1,s1
    80004b7c:	8526                	mv	a0,s1
    80004b7e:	ffffe097          	auipc	ra,0xffffe
    80004b82:	a0a080e7          	jalr	-1526(ra) # 80002588 <sleep>
    if(log.committing){
    80004b86:	50dc                	lw	a5,36(s1)
    80004b88:	fbed                	bnez	a5,80004b7a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004b8a:	509c                	lw	a5,32(s1)
    80004b8c:	0017871b          	addiw	a4,a5,1
    80004b90:	0007069b          	sext.w	a3,a4
    80004b94:	0027179b          	slliw	a5,a4,0x2
    80004b98:	9fb9                	addw	a5,a5,a4
    80004b9a:	0017979b          	slliw	a5,a5,0x1
    80004b9e:	54d8                	lw	a4,44(s1)
    80004ba0:	9fb9                	addw	a5,a5,a4
    80004ba2:	00f95963          	bge	s2,a5,80004bb4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004ba6:	85a6                	mv	a1,s1
    80004ba8:	8526                	mv	a0,s1
    80004baa:	ffffe097          	auipc	ra,0xffffe
    80004bae:	9de080e7          	jalr	-1570(ra) # 80002588 <sleep>
    80004bb2:	bfd1                	j	80004b86 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004bb4:	0001d517          	auipc	a0,0x1d
    80004bb8:	23c50513          	addi	a0,a0,572 # 80021df0 <log>
    80004bbc:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004bbe:	ffffc097          	auipc	ra,0xffffc
    80004bc2:	0da080e7          	jalr	218(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004bc6:	60e2                	ld	ra,24(sp)
    80004bc8:	6442                	ld	s0,16(sp)
    80004bca:	64a2                	ld	s1,8(sp)
    80004bcc:	6902                	ld	s2,0(sp)
    80004bce:	6105                	addi	sp,sp,32
    80004bd0:	8082                	ret

0000000080004bd2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004bd2:	7139                	addi	sp,sp,-64
    80004bd4:	fc06                	sd	ra,56(sp)
    80004bd6:	f822                	sd	s0,48(sp)
    80004bd8:	f426                	sd	s1,40(sp)
    80004bda:	f04a                	sd	s2,32(sp)
    80004bdc:	ec4e                	sd	s3,24(sp)
    80004bde:	e852                	sd	s4,16(sp)
    80004be0:	e456                	sd	s5,8(sp)
    80004be2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004be4:	0001d497          	auipc	s1,0x1d
    80004be8:	20c48493          	addi	s1,s1,524 # 80021df0 <log>
    80004bec:	8526                	mv	a0,s1
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	ff6080e7          	jalr	-10(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004bf6:	509c                	lw	a5,32(s1)
    80004bf8:	37fd                	addiw	a5,a5,-1
    80004bfa:	0007891b          	sext.w	s2,a5
    80004bfe:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004c00:	50dc                	lw	a5,36(s1)
    80004c02:	efb9                	bnez	a5,80004c60 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004c04:	06091663          	bnez	s2,80004c70 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004c08:	0001d497          	auipc	s1,0x1d
    80004c0c:	1e848493          	addi	s1,s1,488 # 80021df0 <log>
    80004c10:	4785                	li	a5,1
    80004c12:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004c14:	8526                	mv	a0,s1
    80004c16:	ffffc097          	auipc	ra,0xffffc
    80004c1a:	082080e7          	jalr	130(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004c1e:	54dc                	lw	a5,44(s1)
    80004c20:	06f04763          	bgtz	a5,80004c8e <end_op+0xbc>
    acquire(&log.lock);
    80004c24:	0001d497          	auipc	s1,0x1d
    80004c28:	1cc48493          	addi	s1,s1,460 # 80021df0 <log>
    80004c2c:	8526                	mv	a0,s1
    80004c2e:	ffffc097          	auipc	ra,0xffffc
    80004c32:	fb6080e7          	jalr	-74(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004c36:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004c3a:	8526                	mv	a0,s1
    80004c3c:	ffffe097          	auipc	ra,0xffffe
    80004c40:	fd2080e7          	jalr	-46(ra) # 80002c0e <wakeup>
    release(&log.lock);
    80004c44:	8526                	mv	a0,s1
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	052080e7          	jalr	82(ra) # 80000c98 <release>
}
    80004c4e:	70e2                	ld	ra,56(sp)
    80004c50:	7442                	ld	s0,48(sp)
    80004c52:	74a2                	ld	s1,40(sp)
    80004c54:	7902                	ld	s2,32(sp)
    80004c56:	69e2                	ld	s3,24(sp)
    80004c58:	6a42                	ld	s4,16(sp)
    80004c5a:	6aa2                	ld	s5,8(sp)
    80004c5c:	6121                	addi	sp,sp,64
    80004c5e:	8082                	ret
    panic("log.committing");
    80004c60:	00004517          	auipc	a0,0x4
    80004c64:	d4050513          	addi	a0,a0,-704 # 800089a0 <syscalls+0x1f8>
    80004c68:	ffffc097          	auipc	ra,0xffffc
    80004c6c:	8d6080e7          	jalr	-1834(ra) # 8000053e <panic>
    wakeup(&log);
    80004c70:	0001d497          	auipc	s1,0x1d
    80004c74:	18048493          	addi	s1,s1,384 # 80021df0 <log>
    80004c78:	8526                	mv	a0,s1
    80004c7a:	ffffe097          	auipc	ra,0xffffe
    80004c7e:	f94080e7          	jalr	-108(ra) # 80002c0e <wakeup>
  release(&log.lock);
    80004c82:	8526                	mv	a0,s1
    80004c84:	ffffc097          	auipc	ra,0xffffc
    80004c88:	014080e7          	jalr	20(ra) # 80000c98 <release>
  if(do_commit){
    80004c8c:	b7c9                	j	80004c4e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c8e:	0001da97          	auipc	s5,0x1d
    80004c92:	192a8a93          	addi	s5,s5,402 # 80021e20 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004c96:	0001da17          	auipc	s4,0x1d
    80004c9a:	15aa0a13          	addi	s4,s4,346 # 80021df0 <log>
    80004c9e:	018a2583          	lw	a1,24(s4)
    80004ca2:	012585bb          	addw	a1,a1,s2
    80004ca6:	2585                	addiw	a1,a1,1
    80004ca8:	028a2503          	lw	a0,40(s4)
    80004cac:	fffff097          	auipc	ra,0xfffff
    80004cb0:	cd2080e7          	jalr	-814(ra) # 8000397e <bread>
    80004cb4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004cb6:	000aa583          	lw	a1,0(s5)
    80004cba:	028a2503          	lw	a0,40(s4)
    80004cbe:	fffff097          	auipc	ra,0xfffff
    80004cc2:	cc0080e7          	jalr	-832(ra) # 8000397e <bread>
    80004cc6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004cc8:	40000613          	li	a2,1024
    80004ccc:	05850593          	addi	a1,a0,88
    80004cd0:	05848513          	addi	a0,s1,88
    80004cd4:	ffffc097          	auipc	ra,0xffffc
    80004cd8:	06c080e7          	jalr	108(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004cdc:	8526                	mv	a0,s1
    80004cde:	fffff097          	auipc	ra,0xfffff
    80004ce2:	d92080e7          	jalr	-622(ra) # 80003a70 <bwrite>
    brelse(from);
    80004ce6:	854e                	mv	a0,s3
    80004ce8:	fffff097          	auipc	ra,0xfffff
    80004cec:	dc6080e7          	jalr	-570(ra) # 80003aae <brelse>
    brelse(to);
    80004cf0:	8526                	mv	a0,s1
    80004cf2:	fffff097          	auipc	ra,0xfffff
    80004cf6:	dbc080e7          	jalr	-580(ra) # 80003aae <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004cfa:	2905                	addiw	s2,s2,1
    80004cfc:	0a91                	addi	s5,s5,4
    80004cfe:	02ca2783          	lw	a5,44(s4)
    80004d02:	f8f94ee3          	blt	s2,a5,80004c9e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004d06:	00000097          	auipc	ra,0x0
    80004d0a:	c6a080e7          	jalr	-918(ra) # 80004970 <write_head>
    install_trans(0); // Now install writes to home locations
    80004d0e:	4501                	li	a0,0
    80004d10:	00000097          	auipc	ra,0x0
    80004d14:	cda080e7          	jalr	-806(ra) # 800049ea <install_trans>
    log.lh.n = 0;
    80004d18:	0001d797          	auipc	a5,0x1d
    80004d1c:	1007a223          	sw	zero,260(a5) # 80021e1c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004d20:	00000097          	auipc	ra,0x0
    80004d24:	c50080e7          	jalr	-944(ra) # 80004970 <write_head>
    80004d28:	bdf5                	j	80004c24 <end_op+0x52>

0000000080004d2a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004d2a:	1101                	addi	sp,sp,-32
    80004d2c:	ec06                	sd	ra,24(sp)
    80004d2e:	e822                	sd	s0,16(sp)
    80004d30:	e426                	sd	s1,8(sp)
    80004d32:	e04a                	sd	s2,0(sp)
    80004d34:	1000                	addi	s0,sp,32
    80004d36:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004d38:	0001d917          	auipc	s2,0x1d
    80004d3c:	0b890913          	addi	s2,s2,184 # 80021df0 <log>
    80004d40:	854a                	mv	a0,s2
    80004d42:	ffffc097          	auipc	ra,0xffffc
    80004d46:	ea2080e7          	jalr	-350(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004d4a:	02c92603          	lw	a2,44(s2)
    80004d4e:	47f5                	li	a5,29
    80004d50:	06c7c563          	blt	a5,a2,80004dba <log_write+0x90>
    80004d54:	0001d797          	auipc	a5,0x1d
    80004d58:	0b87a783          	lw	a5,184(a5) # 80021e0c <log+0x1c>
    80004d5c:	37fd                	addiw	a5,a5,-1
    80004d5e:	04f65e63          	bge	a2,a5,80004dba <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004d62:	0001d797          	auipc	a5,0x1d
    80004d66:	0ae7a783          	lw	a5,174(a5) # 80021e10 <log+0x20>
    80004d6a:	06f05063          	blez	a5,80004dca <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004d6e:	4781                	li	a5,0
    80004d70:	06c05563          	blez	a2,80004dda <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004d74:	44cc                	lw	a1,12(s1)
    80004d76:	0001d717          	auipc	a4,0x1d
    80004d7a:	0aa70713          	addi	a4,a4,170 # 80021e20 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004d7e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004d80:	4314                	lw	a3,0(a4)
    80004d82:	04b68c63          	beq	a3,a1,80004dda <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004d86:	2785                	addiw	a5,a5,1
    80004d88:	0711                	addi	a4,a4,4
    80004d8a:	fef61be3          	bne	a2,a5,80004d80 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004d8e:	0621                	addi	a2,a2,8
    80004d90:	060a                	slli	a2,a2,0x2
    80004d92:	0001d797          	auipc	a5,0x1d
    80004d96:	05e78793          	addi	a5,a5,94 # 80021df0 <log>
    80004d9a:	963e                	add	a2,a2,a5
    80004d9c:	44dc                	lw	a5,12(s1)
    80004d9e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004da0:	8526                	mv	a0,s1
    80004da2:	fffff097          	auipc	ra,0xfffff
    80004da6:	daa080e7          	jalr	-598(ra) # 80003b4c <bpin>
    log.lh.n++;
    80004daa:	0001d717          	auipc	a4,0x1d
    80004dae:	04670713          	addi	a4,a4,70 # 80021df0 <log>
    80004db2:	575c                	lw	a5,44(a4)
    80004db4:	2785                	addiw	a5,a5,1
    80004db6:	d75c                	sw	a5,44(a4)
    80004db8:	a835                	j	80004df4 <log_write+0xca>
    panic("too big a transaction");
    80004dba:	00004517          	auipc	a0,0x4
    80004dbe:	bf650513          	addi	a0,a0,-1034 # 800089b0 <syscalls+0x208>
    80004dc2:	ffffb097          	auipc	ra,0xffffb
    80004dc6:	77c080e7          	jalr	1916(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004dca:	00004517          	auipc	a0,0x4
    80004dce:	bfe50513          	addi	a0,a0,-1026 # 800089c8 <syscalls+0x220>
    80004dd2:	ffffb097          	auipc	ra,0xffffb
    80004dd6:	76c080e7          	jalr	1900(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004dda:	00878713          	addi	a4,a5,8
    80004dde:	00271693          	slli	a3,a4,0x2
    80004de2:	0001d717          	auipc	a4,0x1d
    80004de6:	00e70713          	addi	a4,a4,14 # 80021df0 <log>
    80004dea:	9736                	add	a4,a4,a3
    80004dec:	44d4                	lw	a3,12(s1)
    80004dee:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004df0:	faf608e3          	beq	a2,a5,80004da0 <log_write+0x76>
  }
  release(&log.lock);
    80004df4:	0001d517          	auipc	a0,0x1d
    80004df8:	ffc50513          	addi	a0,a0,-4 # 80021df0 <log>
    80004dfc:	ffffc097          	auipc	ra,0xffffc
    80004e00:	e9c080e7          	jalr	-356(ra) # 80000c98 <release>
}
    80004e04:	60e2                	ld	ra,24(sp)
    80004e06:	6442                	ld	s0,16(sp)
    80004e08:	64a2                	ld	s1,8(sp)
    80004e0a:	6902                	ld	s2,0(sp)
    80004e0c:	6105                	addi	sp,sp,32
    80004e0e:	8082                	ret

0000000080004e10 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004e10:	1101                	addi	sp,sp,-32
    80004e12:	ec06                	sd	ra,24(sp)
    80004e14:	e822                	sd	s0,16(sp)
    80004e16:	e426                	sd	s1,8(sp)
    80004e18:	e04a                	sd	s2,0(sp)
    80004e1a:	1000                	addi	s0,sp,32
    80004e1c:	84aa                	mv	s1,a0
    80004e1e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004e20:	00004597          	auipc	a1,0x4
    80004e24:	bc858593          	addi	a1,a1,-1080 # 800089e8 <syscalls+0x240>
    80004e28:	0521                	addi	a0,a0,8
    80004e2a:	ffffc097          	auipc	ra,0xffffc
    80004e2e:	d2a080e7          	jalr	-726(ra) # 80000b54 <initlock>
  lk->name = name;
    80004e32:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004e36:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004e3a:	0204a423          	sw	zero,40(s1)
}
    80004e3e:	60e2                	ld	ra,24(sp)
    80004e40:	6442                	ld	s0,16(sp)
    80004e42:	64a2                	ld	s1,8(sp)
    80004e44:	6902                	ld	s2,0(sp)
    80004e46:	6105                	addi	sp,sp,32
    80004e48:	8082                	ret

0000000080004e4a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004e4a:	1101                	addi	sp,sp,-32
    80004e4c:	ec06                	sd	ra,24(sp)
    80004e4e:	e822                	sd	s0,16(sp)
    80004e50:	e426                	sd	s1,8(sp)
    80004e52:	e04a                	sd	s2,0(sp)
    80004e54:	1000                	addi	s0,sp,32
    80004e56:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004e58:	00850913          	addi	s2,a0,8
    80004e5c:	854a                	mv	a0,s2
    80004e5e:	ffffc097          	auipc	ra,0xffffc
    80004e62:	d86080e7          	jalr	-634(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004e66:	409c                	lw	a5,0(s1)
    80004e68:	cb89                	beqz	a5,80004e7a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004e6a:	85ca                	mv	a1,s2
    80004e6c:	8526                	mv	a0,s1
    80004e6e:	ffffd097          	auipc	ra,0xffffd
    80004e72:	71a080e7          	jalr	1818(ra) # 80002588 <sleep>
  while (lk->locked) {
    80004e76:	409c                	lw	a5,0(s1)
    80004e78:	fbed                	bnez	a5,80004e6a <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004e7a:	4785                	li	a5,1
    80004e7c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004e7e:	ffffd097          	auipc	ra,0xffffd
    80004e82:	0d0080e7          	jalr	208(ra) # 80001f4e <myproc>
    80004e86:	591c                	lw	a5,48(a0)
    80004e88:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004e8a:	854a                	mv	a0,s2
    80004e8c:	ffffc097          	auipc	ra,0xffffc
    80004e90:	e0c080e7          	jalr	-500(ra) # 80000c98 <release>
}
    80004e94:	60e2                	ld	ra,24(sp)
    80004e96:	6442                	ld	s0,16(sp)
    80004e98:	64a2                	ld	s1,8(sp)
    80004e9a:	6902                	ld	s2,0(sp)
    80004e9c:	6105                	addi	sp,sp,32
    80004e9e:	8082                	ret

0000000080004ea0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004ea0:	1101                	addi	sp,sp,-32
    80004ea2:	ec06                	sd	ra,24(sp)
    80004ea4:	e822                	sd	s0,16(sp)
    80004ea6:	e426                	sd	s1,8(sp)
    80004ea8:	e04a                	sd	s2,0(sp)
    80004eaa:	1000                	addi	s0,sp,32
    80004eac:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004eae:	00850913          	addi	s2,a0,8
    80004eb2:	854a                	mv	a0,s2
    80004eb4:	ffffc097          	auipc	ra,0xffffc
    80004eb8:	d30080e7          	jalr	-720(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004ebc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ec0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004ec4:	8526                	mv	a0,s1
    80004ec6:	ffffe097          	auipc	ra,0xffffe
    80004eca:	d48080e7          	jalr	-696(ra) # 80002c0e <wakeup>
  release(&lk->lk);
    80004ece:	854a                	mv	a0,s2
    80004ed0:	ffffc097          	auipc	ra,0xffffc
    80004ed4:	dc8080e7          	jalr	-568(ra) # 80000c98 <release>
}
    80004ed8:	60e2                	ld	ra,24(sp)
    80004eda:	6442                	ld	s0,16(sp)
    80004edc:	64a2                	ld	s1,8(sp)
    80004ede:	6902                	ld	s2,0(sp)
    80004ee0:	6105                	addi	sp,sp,32
    80004ee2:	8082                	ret

0000000080004ee4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004ee4:	7179                	addi	sp,sp,-48
    80004ee6:	f406                	sd	ra,40(sp)
    80004ee8:	f022                	sd	s0,32(sp)
    80004eea:	ec26                	sd	s1,24(sp)
    80004eec:	e84a                	sd	s2,16(sp)
    80004eee:	e44e                	sd	s3,8(sp)
    80004ef0:	1800                	addi	s0,sp,48
    80004ef2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004ef4:	00850913          	addi	s2,a0,8
    80004ef8:	854a                	mv	a0,s2
    80004efa:	ffffc097          	auipc	ra,0xffffc
    80004efe:	cea080e7          	jalr	-790(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004f02:	409c                	lw	a5,0(s1)
    80004f04:	ef99                	bnez	a5,80004f22 <holdingsleep+0x3e>
    80004f06:	4481                	li	s1,0
  release(&lk->lk);
    80004f08:	854a                	mv	a0,s2
    80004f0a:	ffffc097          	auipc	ra,0xffffc
    80004f0e:	d8e080e7          	jalr	-626(ra) # 80000c98 <release>
  return r;
}
    80004f12:	8526                	mv	a0,s1
    80004f14:	70a2                	ld	ra,40(sp)
    80004f16:	7402                	ld	s0,32(sp)
    80004f18:	64e2                	ld	s1,24(sp)
    80004f1a:	6942                	ld	s2,16(sp)
    80004f1c:	69a2                	ld	s3,8(sp)
    80004f1e:	6145                	addi	sp,sp,48
    80004f20:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004f22:	0284a983          	lw	s3,40(s1)
    80004f26:	ffffd097          	auipc	ra,0xffffd
    80004f2a:	028080e7          	jalr	40(ra) # 80001f4e <myproc>
    80004f2e:	5904                	lw	s1,48(a0)
    80004f30:	413484b3          	sub	s1,s1,s3
    80004f34:	0014b493          	seqz	s1,s1
    80004f38:	bfc1                	j	80004f08 <holdingsleep+0x24>

0000000080004f3a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004f3a:	1141                	addi	sp,sp,-16
    80004f3c:	e406                	sd	ra,8(sp)
    80004f3e:	e022                	sd	s0,0(sp)
    80004f40:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004f42:	00004597          	auipc	a1,0x4
    80004f46:	ab658593          	addi	a1,a1,-1354 # 800089f8 <syscalls+0x250>
    80004f4a:	0001d517          	auipc	a0,0x1d
    80004f4e:	fee50513          	addi	a0,a0,-18 # 80021f38 <ftable>
    80004f52:	ffffc097          	auipc	ra,0xffffc
    80004f56:	c02080e7          	jalr	-1022(ra) # 80000b54 <initlock>
}
    80004f5a:	60a2                	ld	ra,8(sp)
    80004f5c:	6402                	ld	s0,0(sp)
    80004f5e:	0141                	addi	sp,sp,16
    80004f60:	8082                	ret

0000000080004f62 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004f62:	1101                	addi	sp,sp,-32
    80004f64:	ec06                	sd	ra,24(sp)
    80004f66:	e822                	sd	s0,16(sp)
    80004f68:	e426                	sd	s1,8(sp)
    80004f6a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004f6c:	0001d517          	auipc	a0,0x1d
    80004f70:	fcc50513          	addi	a0,a0,-52 # 80021f38 <ftable>
    80004f74:	ffffc097          	auipc	ra,0xffffc
    80004f78:	c70080e7          	jalr	-912(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004f7c:	0001d497          	auipc	s1,0x1d
    80004f80:	fd448493          	addi	s1,s1,-44 # 80021f50 <ftable+0x18>
    80004f84:	0001e717          	auipc	a4,0x1e
    80004f88:	f6c70713          	addi	a4,a4,-148 # 80022ef0 <ftable+0xfb8>
    if(f->ref == 0){
    80004f8c:	40dc                	lw	a5,4(s1)
    80004f8e:	cf99                	beqz	a5,80004fac <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004f90:	02848493          	addi	s1,s1,40
    80004f94:	fee49ce3          	bne	s1,a4,80004f8c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004f98:	0001d517          	auipc	a0,0x1d
    80004f9c:	fa050513          	addi	a0,a0,-96 # 80021f38 <ftable>
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	cf8080e7          	jalr	-776(ra) # 80000c98 <release>
  return 0;
    80004fa8:	4481                	li	s1,0
    80004faa:	a819                	j	80004fc0 <filealloc+0x5e>
      f->ref = 1;
    80004fac:	4785                	li	a5,1
    80004fae:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004fb0:	0001d517          	auipc	a0,0x1d
    80004fb4:	f8850513          	addi	a0,a0,-120 # 80021f38 <ftable>
    80004fb8:	ffffc097          	auipc	ra,0xffffc
    80004fbc:	ce0080e7          	jalr	-800(ra) # 80000c98 <release>
}
    80004fc0:	8526                	mv	a0,s1
    80004fc2:	60e2                	ld	ra,24(sp)
    80004fc4:	6442                	ld	s0,16(sp)
    80004fc6:	64a2                	ld	s1,8(sp)
    80004fc8:	6105                	addi	sp,sp,32
    80004fca:	8082                	ret

0000000080004fcc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004fcc:	1101                	addi	sp,sp,-32
    80004fce:	ec06                	sd	ra,24(sp)
    80004fd0:	e822                	sd	s0,16(sp)
    80004fd2:	e426                	sd	s1,8(sp)
    80004fd4:	1000                	addi	s0,sp,32
    80004fd6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004fd8:	0001d517          	auipc	a0,0x1d
    80004fdc:	f6050513          	addi	a0,a0,-160 # 80021f38 <ftable>
    80004fe0:	ffffc097          	auipc	ra,0xffffc
    80004fe4:	c04080e7          	jalr	-1020(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004fe8:	40dc                	lw	a5,4(s1)
    80004fea:	02f05263          	blez	a5,8000500e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004fee:	2785                	addiw	a5,a5,1
    80004ff0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ff2:	0001d517          	auipc	a0,0x1d
    80004ff6:	f4650513          	addi	a0,a0,-186 # 80021f38 <ftable>
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	c9e080e7          	jalr	-866(ra) # 80000c98 <release>
  return f;
}
    80005002:	8526                	mv	a0,s1
    80005004:	60e2                	ld	ra,24(sp)
    80005006:	6442                	ld	s0,16(sp)
    80005008:	64a2                	ld	s1,8(sp)
    8000500a:	6105                	addi	sp,sp,32
    8000500c:	8082                	ret
    panic("filedup");
    8000500e:	00004517          	auipc	a0,0x4
    80005012:	9f250513          	addi	a0,a0,-1550 # 80008a00 <syscalls+0x258>
    80005016:	ffffb097          	auipc	ra,0xffffb
    8000501a:	528080e7          	jalr	1320(ra) # 8000053e <panic>

000000008000501e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000501e:	7139                	addi	sp,sp,-64
    80005020:	fc06                	sd	ra,56(sp)
    80005022:	f822                	sd	s0,48(sp)
    80005024:	f426                	sd	s1,40(sp)
    80005026:	f04a                	sd	s2,32(sp)
    80005028:	ec4e                	sd	s3,24(sp)
    8000502a:	e852                	sd	s4,16(sp)
    8000502c:	e456                	sd	s5,8(sp)
    8000502e:	0080                	addi	s0,sp,64
    80005030:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005032:	0001d517          	auipc	a0,0x1d
    80005036:	f0650513          	addi	a0,a0,-250 # 80021f38 <ftable>
    8000503a:	ffffc097          	auipc	ra,0xffffc
    8000503e:	baa080e7          	jalr	-1110(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80005042:	40dc                	lw	a5,4(s1)
    80005044:	06f05163          	blez	a5,800050a6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005048:	37fd                	addiw	a5,a5,-1
    8000504a:	0007871b          	sext.w	a4,a5
    8000504e:	c0dc                	sw	a5,4(s1)
    80005050:	06e04363          	bgtz	a4,800050b6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005054:	0004a903          	lw	s2,0(s1)
    80005058:	0094ca83          	lbu	s5,9(s1)
    8000505c:	0104ba03          	ld	s4,16(s1)
    80005060:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005064:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005068:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000506c:	0001d517          	auipc	a0,0x1d
    80005070:	ecc50513          	addi	a0,a0,-308 # 80021f38 <ftable>
    80005074:	ffffc097          	auipc	ra,0xffffc
    80005078:	c24080e7          	jalr	-988(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    8000507c:	4785                	li	a5,1
    8000507e:	04f90d63          	beq	s2,a5,800050d8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005082:	3979                	addiw	s2,s2,-2
    80005084:	4785                	li	a5,1
    80005086:	0527e063          	bltu	a5,s2,800050c6 <fileclose+0xa8>
    begin_op();
    8000508a:	00000097          	auipc	ra,0x0
    8000508e:	ac8080e7          	jalr	-1336(ra) # 80004b52 <begin_op>
    iput(ff.ip);
    80005092:	854e                	mv	a0,s3
    80005094:	fffff097          	auipc	ra,0xfffff
    80005098:	2a6080e7          	jalr	678(ra) # 8000433a <iput>
    end_op();
    8000509c:	00000097          	auipc	ra,0x0
    800050a0:	b36080e7          	jalr	-1226(ra) # 80004bd2 <end_op>
    800050a4:	a00d                	j	800050c6 <fileclose+0xa8>
    panic("fileclose");
    800050a6:	00004517          	auipc	a0,0x4
    800050aa:	96250513          	addi	a0,a0,-1694 # 80008a08 <syscalls+0x260>
    800050ae:	ffffb097          	auipc	ra,0xffffb
    800050b2:	490080e7          	jalr	1168(ra) # 8000053e <panic>
    release(&ftable.lock);
    800050b6:	0001d517          	auipc	a0,0x1d
    800050ba:	e8250513          	addi	a0,a0,-382 # 80021f38 <ftable>
    800050be:	ffffc097          	auipc	ra,0xffffc
    800050c2:	bda080e7          	jalr	-1062(ra) # 80000c98 <release>
  }
}
    800050c6:	70e2                	ld	ra,56(sp)
    800050c8:	7442                	ld	s0,48(sp)
    800050ca:	74a2                	ld	s1,40(sp)
    800050cc:	7902                	ld	s2,32(sp)
    800050ce:	69e2                	ld	s3,24(sp)
    800050d0:	6a42                	ld	s4,16(sp)
    800050d2:	6aa2                	ld	s5,8(sp)
    800050d4:	6121                	addi	sp,sp,64
    800050d6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800050d8:	85d6                	mv	a1,s5
    800050da:	8552                	mv	a0,s4
    800050dc:	00000097          	auipc	ra,0x0
    800050e0:	34c080e7          	jalr	844(ra) # 80005428 <pipeclose>
    800050e4:	b7cd                	j	800050c6 <fileclose+0xa8>

00000000800050e6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800050e6:	715d                	addi	sp,sp,-80
    800050e8:	e486                	sd	ra,72(sp)
    800050ea:	e0a2                	sd	s0,64(sp)
    800050ec:	fc26                	sd	s1,56(sp)
    800050ee:	f84a                	sd	s2,48(sp)
    800050f0:	f44e                	sd	s3,40(sp)
    800050f2:	0880                	addi	s0,sp,80
    800050f4:	84aa                	mv	s1,a0
    800050f6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800050f8:	ffffd097          	auipc	ra,0xffffd
    800050fc:	e56080e7          	jalr	-426(ra) # 80001f4e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005100:	409c                	lw	a5,0(s1)
    80005102:	37f9                	addiw	a5,a5,-2
    80005104:	4705                	li	a4,1
    80005106:	04f76763          	bltu	a4,a5,80005154 <filestat+0x6e>
    8000510a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000510c:	6c88                	ld	a0,24(s1)
    8000510e:	fffff097          	auipc	ra,0xfffff
    80005112:	072080e7          	jalr	114(ra) # 80004180 <ilock>
    stati(f->ip, &st);
    80005116:	fb840593          	addi	a1,s0,-72
    8000511a:	6c88                	ld	a0,24(s1)
    8000511c:	fffff097          	auipc	ra,0xfffff
    80005120:	2ee080e7          	jalr	750(ra) # 8000440a <stati>
    iunlock(f->ip);
    80005124:	6c88                	ld	a0,24(s1)
    80005126:	fffff097          	auipc	ra,0xfffff
    8000512a:	11c080e7          	jalr	284(ra) # 80004242 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000512e:	46e1                	li	a3,24
    80005130:	fb840613          	addi	a2,s0,-72
    80005134:	85ce                	mv	a1,s3
    80005136:	05093503          	ld	a0,80(s2)
    8000513a:	ffffc097          	auipc	ra,0xffffc
    8000513e:	538080e7          	jalr	1336(ra) # 80001672 <copyout>
    80005142:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005146:	60a6                	ld	ra,72(sp)
    80005148:	6406                	ld	s0,64(sp)
    8000514a:	74e2                	ld	s1,56(sp)
    8000514c:	7942                	ld	s2,48(sp)
    8000514e:	79a2                	ld	s3,40(sp)
    80005150:	6161                	addi	sp,sp,80
    80005152:	8082                	ret
  return -1;
    80005154:	557d                	li	a0,-1
    80005156:	bfc5                	j	80005146 <filestat+0x60>

0000000080005158 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005158:	7179                	addi	sp,sp,-48
    8000515a:	f406                	sd	ra,40(sp)
    8000515c:	f022                	sd	s0,32(sp)
    8000515e:	ec26                	sd	s1,24(sp)
    80005160:	e84a                	sd	s2,16(sp)
    80005162:	e44e                	sd	s3,8(sp)
    80005164:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005166:	00854783          	lbu	a5,8(a0)
    8000516a:	c3d5                	beqz	a5,8000520e <fileread+0xb6>
    8000516c:	84aa                	mv	s1,a0
    8000516e:	89ae                	mv	s3,a1
    80005170:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005172:	411c                	lw	a5,0(a0)
    80005174:	4705                	li	a4,1
    80005176:	04e78963          	beq	a5,a4,800051c8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000517a:	470d                	li	a4,3
    8000517c:	04e78d63          	beq	a5,a4,800051d6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005180:	4709                	li	a4,2
    80005182:	06e79e63          	bne	a5,a4,800051fe <fileread+0xa6>
    ilock(f->ip);
    80005186:	6d08                	ld	a0,24(a0)
    80005188:	fffff097          	auipc	ra,0xfffff
    8000518c:	ff8080e7          	jalr	-8(ra) # 80004180 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005190:	874a                	mv	a4,s2
    80005192:	5094                	lw	a3,32(s1)
    80005194:	864e                	mv	a2,s3
    80005196:	4585                	li	a1,1
    80005198:	6c88                	ld	a0,24(s1)
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	29a080e7          	jalr	666(ra) # 80004434 <readi>
    800051a2:	892a                	mv	s2,a0
    800051a4:	00a05563          	blez	a0,800051ae <fileread+0x56>
      f->off += r;
    800051a8:	509c                	lw	a5,32(s1)
    800051aa:	9fa9                	addw	a5,a5,a0
    800051ac:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800051ae:	6c88                	ld	a0,24(s1)
    800051b0:	fffff097          	auipc	ra,0xfffff
    800051b4:	092080e7          	jalr	146(ra) # 80004242 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800051b8:	854a                	mv	a0,s2
    800051ba:	70a2                	ld	ra,40(sp)
    800051bc:	7402                	ld	s0,32(sp)
    800051be:	64e2                	ld	s1,24(sp)
    800051c0:	6942                	ld	s2,16(sp)
    800051c2:	69a2                	ld	s3,8(sp)
    800051c4:	6145                	addi	sp,sp,48
    800051c6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800051c8:	6908                	ld	a0,16(a0)
    800051ca:	00000097          	auipc	ra,0x0
    800051ce:	3c8080e7          	jalr	968(ra) # 80005592 <piperead>
    800051d2:	892a                	mv	s2,a0
    800051d4:	b7d5                	j	800051b8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800051d6:	02451783          	lh	a5,36(a0)
    800051da:	03079693          	slli	a3,a5,0x30
    800051de:	92c1                	srli	a3,a3,0x30
    800051e0:	4725                	li	a4,9
    800051e2:	02d76863          	bltu	a4,a3,80005212 <fileread+0xba>
    800051e6:	0792                	slli	a5,a5,0x4
    800051e8:	0001d717          	auipc	a4,0x1d
    800051ec:	cb070713          	addi	a4,a4,-848 # 80021e98 <devsw>
    800051f0:	97ba                	add	a5,a5,a4
    800051f2:	639c                	ld	a5,0(a5)
    800051f4:	c38d                	beqz	a5,80005216 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800051f6:	4505                	li	a0,1
    800051f8:	9782                	jalr	a5
    800051fa:	892a                	mv	s2,a0
    800051fc:	bf75                	j	800051b8 <fileread+0x60>
    panic("fileread");
    800051fe:	00004517          	auipc	a0,0x4
    80005202:	81a50513          	addi	a0,a0,-2022 # 80008a18 <syscalls+0x270>
    80005206:	ffffb097          	auipc	ra,0xffffb
    8000520a:	338080e7          	jalr	824(ra) # 8000053e <panic>
    return -1;
    8000520e:	597d                	li	s2,-1
    80005210:	b765                	j	800051b8 <fileread+0x60>
      return -1;
    80005212:	597d                	li	s2,-1
    80005214:	b755                	j	800051b8 <fileread+0x60>
    80005216:	597d                	li	s2,-1
    80005218:	b745                	j	800051b8 <fileread+0x60>

000000008000521a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000521a:	715d                	addi	sp,sp,-80
    8000521c:	e486                	sd	ra,72(sp)
    8000521e:	e0a2                	sd	s0,64(sp)
    80005220:	fc26                	sd	s1,56(sp)
    80005222:	f84a                	sd	s2,48(sp)
    80005224:	f44e                	sd	s3,40(sp)
    80005226:	f052                	sd	s4,32(sp)
    80005228:	ec56                	sd	s5,24(sp)
    8000522a:	e85a                	sd	s6,16(sp)
    8000522c:	e45e                	sd	s7,8(sp)
    8000522e:	e062                	sd	s8,0(sp)
    80005230:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005232:	00954783          	lbu	a5,9(a0)
    80005236:	10078663          	beqz	a5,80005342 <filewrite+0x128>
    8000523a:	892a                	mv	s2,a0
    8000523c:	8aae                	mv	s5,a1
    8000523e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005240:	411c                	lw	a5,0(a0)
    80005242:	4705                	li	a4,1
    80005244:	02e78263          	beq	a5,a4,80005268 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005248:	470d                	li	a4,3
    8000524a:	02e78663          	beq	a5,a4,80005276 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000524e:	4709                	li	a4,2
    80005250:	0ee79163          	bne	a5,a4,80005332 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005254:	0ac05d63          	blez	a2,8000530e <filewrite+0xf4>
    int i = 0;
    80005258:	4981                	li	s3,0
    8000525a:	6b05                	lui	s6,0x1
    8000525c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005260:	6b85                	lui	s7,0x1
    80005262:	c00b8b9b          	addiw	s7,s7,-1024
    80005266:	a861                	j	800052fe <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005268:	6908                	ld	a0,16(a0)
    8000526a:	00000097          	auipc	ra,0x0
    8000526e:	22e080e7          	jalr	558(ra) # 80005498 <pipewrite>
    80005272:	8a2a                	mv	s4,a0
    80005274:	a045                	j	80005314 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005276:	02451783          	lh	a5,36(a0)
    8000527a:	03079693          	slli	a3,a5,0x30
    8000527e:	92c1                	srli	a3,a3,0x30
    80005280:	4725                	li	a4,9
    80005282:	0cd76263          	bltu	a4,a3,80005346 <filewrite+0x12c>
    80005286:	0792                	slli	a5,a5,0x4
    80005288:	0001d717          	auipc	a4,0x1d
    8000528c:	c1070713          	addi	a4,a4,-1008 # 80021e98 <devsw>
    80005290:	97ba                	add	a5,a5,a4
    80005292:	679c                	ld	a5,8(a5)
    80005294:	cbdd                	beqz	a5,8000534a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005296:	4505                	li	a0,1
    80005298:	9782                	jalr	a5
    8000529a:	8a2a                	mv	s4,a0
    8000529c:	a8a5                	j	80005314 <filewrite+0xfa>
    8000529e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800052a2:	00000097          	auipc	ra,0x0
    800052a6:	8b0080e7          	jalr	-1872(ra) # 80004b52 <begin_op>
      ilock(f->ip);
    800052aa:	01893503          	ld	a0,24(s2)
    800052ae:	fffff097          	auipc	ra,0xfffff
    800052b2:	ed2080e7          	jalr	-302(ra) # 80004180 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800052b6:	8762                	mv	a4,s8
    800052b8:	02092683          	lw	a3,32(s2)
    800052bc:	01598633          	add	a2,s3,s5
    800052c0:	4585                	li	a1,1
    800052c2:	01893503          	ld	a0,24(s2)
    800052c6:	fffff097          	auipc	ra,0xfffff
    800052ca:	266080e7          	jalr	614(ra) # 8000452c <writei>
    800052ce:	84aa                	mv	s1,a0
    800052d0:	00a05763          	blez	a0,800052de <filewrite+0xc4>
        f->off += r;
    800052d4:	02092783          	lw	a5,32(s2)
    800052d8:	9fa9                	addw	a5,a5,a0
    800052da:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800052de:	01893503          	ld	a0,24(s2)
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	f60080e7          	jalr	-160(ra) # 80004242 <iunlock>
      end_op();
    800052ea:	00000097          	auipc	ra,0x0
    800052ee:	8e8080e7          	jalr	-1816(ra) # 80004bd2 <end_op>

      if(r != n1){
    800052f2:	009c1f63          	bne	s8,s1,80005310 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800052f6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800052fa:	0149db63          	bge	s3,s4,80005310 <filewrite+0xf6>
      int n1 = n - i;
    800052fe:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005302:	84be                	mv	s1,a5
    80005304:	2781                	sext.w	a5,a5
    80005306:	f8fb5ce3          	bge	s6,a5,8000529e <filewrite+0x84>
    8000530a:	84de                	mv	s1,s7
    8000530c:	bf49                	j	8000529e <filewrite+0x84>
    int i = 0;
    8000530e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005310:	013a1f63          	bne	s4,s3,8000532e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005314:	8552                	mv	a0,s4
    80005316:	60a6                	ld	ra,72(sp)
    80005318:	6406                	ld	s0,64(sp)
    8000531a:	74e2                	ld	s1,56(sp)
    8000531c:	7942                	ld	s2,48(sp)
    8000531e:	79a2                	ld	s3,40(sp)
    80005320:	7a02                	ld	s4,32(sp)
    80005322:	6ae2                	ld	s5,24(sp)
    80005324:	6b42                	ld	s6,16(sp)
    80005326:	6ba2                	ld	s7,8(sp)
    80005328:	6c02                	ld	s8,0(sp)
    8000532a:	6161                	addi	sp,sp,80
    8000532c:	8082                	ret
    ret = (i == n ? n : -1);
    8000532e:	5a7d                	li	s4,-1
    80005330:	b7d5                	j	80005314 <filewrite+0xfa>
    panic("filewrite");
    80005332:	00003517          	auipc	a0,0x3
    80005336:	6f650513          	addi	a0,a0,1782 # 80008a28 <syscalls+0x280>
    8000533a:	ffffb097          	auipc	ra,0xffffb
    8000533e:	204080e7          	jalr	516(ra) # 8000053e <panic>
    return -1;
    80005342:	5a7d                	li	s4,-1
    80005344:	bfc1                	j	80005314 <filewrite+0xfa>
      return -1;
    80005346:	5a7d                	li	s4,-1
    80005348:	b7f1                	j	80005314 <filewrite+0xfa>
    8000534a:	5a7d                	li	s4,-1
    8000534c:	b7e1                	j	80005314 <filewrite+0xfa>

000000008000534e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000534e:	7179                	addi	sp,sp,-48
    80005350:	f406                	sd	ra,40(sp)
    80005352:	f022                	sd	s0,32(sp)
    80005354:	ec26                	sd	s1,24(sp)
    80005356:	e84a                	sd	s2,16(sp)
    80005358:	e44e                	sd	s3,8(sp)
    8000535a:	e052                	sd	s4,0(sp)
    8000535c:	1800                	addi	s0,sp,48
    8000535e:	84aa                	mv	s1,a0
    80005360:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005362:	0005b023          	sd	zero,0(a1)
    80005366:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000536a:	00000097          	auipc	ra,0x0
    8000536e:	bf8080e7          	jalr	-1032(ra) # 80004f62 <filealloc>
    80005372:	e088                	sd	a0,0(s1)
    80005374:	c551                	beqz	a0,80005400 <pipealloc+0xb2>
    80005376:	00000097          	auipc	ra,0x0
    8000537a:	bec080e7          	jalr	-1044(ra) # 80004f62 <filealloc>
    8000537e:	00aa3023          	sd	a0,0(s4)
    80005382:	c92d                	beqz	a0,800053f4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005384:	ffffb097          	auipc	ra,0xffffb
    80005388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000538c:	892a                	mv	s2,a0
    8000538e:	c125                	beqz	a0,800053ee <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005390:	4985                	li	s3,1
    80005392:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005396:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000539a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000539e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800053a2:	00003597          	auipc	a1,0x3
    800053a6:	69658593          	addi	a1,a1,1686 # 80008a38 <syscalls+0x290>
    800053aa:	ffffb097          	auipc	ra,0xffffb
    800053ae:	7aa080e7          	jalr	1962(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800053b2:	609c                	ld	a5,0(s1)
    800053b4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800053b8:	609c                	ld	a5,0(s1)
    800053ba:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800053be:	609c                	ld	a5,0(s1)
    800053c0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800053c4:	609c                	ld	a5,0(s1)
    800053c6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800053ca:	000a3783          	ld	a5,0(s4)
    800053ce:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800053d2:	000a3783          	ld	a5,0(s4)
    800053d6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800053da:	000a3783          	ld	a5,0(s4)
    800053de:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800053e2:	000a3783          	ld	a5,0(s4)
    800053e6:	0127b823          	sd	s2,16(a5)
  return 0;
    800053ea:	4501                	li	a0,0
    800053ec:	a025                	j	80005414 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800053ee:	6088                	ld	a0,0(s1)
    800053f0:	e501                	bnez	a0,800053f8 <pipealloc+0xaa>
    800053f2:	a039                	j	80005400 <pipealloc+0xb2>
    800053f4:	6088                	ld	a0,0(s1)
    800053f6:	c51d                	beqz	a0,80005424 <pipealloc+0xd6>
    fileclose(*f0);
    800053f8:	00000097          	auipc	ra,0x0
    800053fc:	c26080e7          	jalr	-986(ra) # 8000501e <fileclose>
  if(*f1)
    80005400:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005404:	557d                	li	a0,-1
  if(*f1)
    80005406:	c799                	beqz	a5,80005414 <pipealloc+0xc6>
    fileclose(*f1);
    80005408:	853e                	mv	a0,a5
    8000540a:	00000097          	auipc	ra,0x0
    8000540e:	c14080e7          	jalr	-1004(ra) # 8000501e <fileclose>
  return -1;
    80005412:	557d                	li	a0,-1
}
    80005414:	70a2                	ld	ra,40(sp)
    80005416:	7402                	ld	s0,32(sp)
    80005418:	64e2                	ld	s1,24(sp)
    8000541a:	6942                	ld	s2,16(sp)
    8000541c:	69a2                	ld	s3,8(sp)
    8000541e:	6a02                	ld	s4,0(sp)
    80005420:	6145                	addi	sp,sp,48
    80005422:	8082                	ret
  return -1;
    80005424:	557d                	li	a0,-1
    80005426:	b7fd                	j	80005414 <pipealloc+0xc6>

0000000080005428 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005428:	1101                	addi	sp,sp,-32
    8000542a:	ec06                	sd	ra,24(sp)
    8000542c:	e822                	sd	s0,16(sp)
    8000542e:	e426                	sd	s1,8(sp)
    80005430:	e04a                	sd	s2,0(sp)
    80005432:	1000                	addi	s0,sp,32
    80005434:	84aa                	mv	s1,a0
    80005436:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005438:	ffffb097          	auipc	ra,0xffffb
    8000543c:	7ac080e7          	jalr	1964(ra) # 80000be4 <acquire>
  if(writable){
    80005440:	02090d63          	beqz	s2,8000547a <pipeclose+0x52>
    pi->writeopen = 0;
    80005444:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005448:	21848513          	addi	a0,s1,536
    8000544c:	ffffd097          	auipc	ra,0xffffd
    80005450:	7c2080e7          	jalr	1986(ra) # 80002c0e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005454:	2204b783          	ld	a5,544(s1)
    80005458:	eb95                	bnez	a5,8000548c <pipeclose+0x64>
    release(&pi->lock);
    8000545a:	8526                	mv	a0,s1
    8000545c:	ffffc097          	auipc	ra,0xffffc
    80005460:	83c080e7          	jalr	-1988(ra) # 80000c98 <release>
    kfree((char*)pi);
    80005464:	8526                	mv	a0,s1
    80005466:	ffffb097          	auipc	ra,0xffffb
    8000546a:	592080e7          	jalr	1426(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    8000546e:	60e2                	ld	ra,24(sp)
    80005470:	6442                	ld	s0,16(sp)
    80005472:	64a2                	ld	s1,8(sp)
    80005474:	6902                	ld	s2,0(sp)
    80005476:	6105                	addi	sp,sp,32
    80005478:	8082                	ret
    pi->readopen = 0;
    8000547a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000547e:	21c48513          	addi	a0,s1,540
    80005482:	ffffd097          	auipc	ra,0xffffd
    80005486:	78c080e7          	jalr	1932(ra) # 80002c0e <wakeup>
    8000548a:	b7e9                	j	80005454 <pipeclose+0x2c>
    release(&pi->lock);
    8000548c:	8526                	mv	a0,s1
    8000548e:	ffffc097          	auipc	ra,0xffffc
    80005492:	80a080e7          	jalr	-2038(ra) # 80000c98 <release>
}
    80005496:	bfe1                	j	8000546e <pipeclose+0x46>

0000000080005498 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005498:	7159                	addi	sp,sp,-112
    8000549a:	f486                	sd	ra,104(sp)
    8000549c:	f0a2                	sd	s0,96(sp)
    8000549e:	eca6                	sd	s1,88(sp)
    800054a0:	e8ca                	sd	s2,80(sp)
    800054a2:	e4ce                	sd	s3,72(sp)
    800054a4:	e0d2                	sd	s4,64(sp)
    800054a6:	fc56                	sd	s5,56(sp)
    800054a8:	f85a                	sd	s6,48(sp)
    800054aa:	f45e                	sd	s7,40(sp)
    800054ac:	f062                	sd	s8,32(sp)
    800054ae:	ec66                	sd	s9,24(sp)
    800054b0:	1880                	addi	s0,sp,112
    800054b2:	84aa                	mv	s1,a0
    800054b4:	8aae                	mv	s5,a1
    800054b6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800054b8:	ffffd097          	auipc	ra,0xffffd
    800054bc:	a96080e7          	jalr	-1386(ra) # 80001f4e <myproc>
    800054c0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800054c2:	8526                	mv	a0,s1
    800054c4:	ffffb097          	auipc	ra,0xffffb
    800054c8:	720080e7          	jalr	1824(ra) # 80000be4 <acquire>
  while(i < n){
    800054cc:	0d405163          	blez	s4,8000558e <pipewrite+0xf6>
    800054d0:	8ba6                	mv	s7,s1
  int i = 0;
    800054d2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800054d4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800054d6:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800054da:	21c48c13          	addi	s8,s1,540
    800054de:	a08d                	j	80005540 <pipewrite+0xa8>
      release(&pi->lock);
    800054e0:	8526                	mv	a0,s1
    800054e2:	ffffb097          	auipc	ra,0xffffb
    800054e6:	7b6080e7          	jalr	1974(ra) # 80000c98 <release>
      return -1;
    800054ea:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800054ec:	854a                	mv	a0,s2
    800054ee:	70a6                	ld	ra,104(sp)
    800054f0:	7406                	ld	s0,96(sp)
    800054f2:	64e6                	ld	s1,88(sp)
    800054f4:	6946                	ld	s2,80(sp)
    800054f6:	69a6                	ld	s3,72(sp)
    800054f8:	6a06                	ld	s4,64(sp)
    800054fa:	7ae2                	ld	s5,56(sp)
    800054fc:	7b42                	ld	s6,48(sp)
    800054fe:	7ba2                	ld	s7,40(sp)
    80005500:	7c02                	ld	s8,32(sp)
    80005502:	6ce2                	ld	s9,24(sp)
    80005504:	6165                	addi	sp,sp,112
    80005506:	8082                	ret
      wakeup(&pi->nread);
    80005508:	8566                	mv	a0,s9
    8000550a:	ffffd097          	auipc	ra,0xffffd
    8000550e:	704080e7          	jalr	1796(ra) # 80002c0e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005512:	85de                	mv	a1,s7
    80005514:	8562                	mv	a0,s8
    80005516:	ffffd097          	auipc	ra,0xffffd
    8000551a:	072080e7          	jalr	114(ra) # 80002588 <sleep>
    8000551e:	a839                	j	8000553c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005520:	21c4a783          	lw	a5,540(s1)
    80005524:	0017871b          	addiw	a4,a5,1
    80005528:	20e4ae23          	sw	a4,540(s1)
    8000552c:	1ff7f793          	andi	a5,a5,511
    80005530:	97a6                	add	a5,a5,s1
    80005532:	f9f44703          	lbu	a4,-97(s0)
    80005536:	00e78c23          	sb	a4,24(a5)
      i++;
    8000553a:	2905                	addiw	s2,s2,1
  while(i < n){
    8000553c:	03495d63          	bge	s2,s4,80005576 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005540:	2204a783          	lw	a5,544(s1)
    80005544:	dfd1                	beqz	a5,800054e0 <pipewrite+0x48>
    80005546:	0289a783          	lw	a5,40(s3)
    8000554a:	fbd9                	bnez	a5,800054e0 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000554c:	2184a783          	lw	a5,536(s1)
    80005550:	21c4a703          	lw	a4,540(s1)
    80005554:	2007879b          	addiw	a5,a5,512
    80005558:	faf708e3          	beq	a4,a5,80005508 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000555c:	4685                	li	a3,1
    8000555e:	01590633          	add	a2,s2,s5
    80005562:	f9f40593          	addi	a1,s0,-97
    80005566:	0509b503          	ld	a0,80(s3)
    8000556a:	ffffc097          	auipc	ra,0xffffc
    8000556e:	194080e7          	jalr	404(ra) # 800016fe <copyin>
    80005572:	fb6517e3          	bne	a0,s6,80005520 <pipewrite+0x88>
  wakeup(&pi->nread);
    80005576:	21848513          	addi	a0,s1,536
    8000557a:	ffffd097          	auipc	ra,0xffffd
    8000557e:	694080e7          	jalr	1684(ra) # 80002c0e <wakeup>
  release(&pi->lock);
    80005582:	8526                	mv	a0,s1
    80005584:	ffffb097          	auipc	ra,0xffffb
    80005588:	714080e7          	jalr	1812(ra) # 80000c98 <release>
  return i;
    8000558c:	b785                	j	800054ec <pipewrite+0x54>
  int i = 0;
    8000558e:	4901                	li	s2,0
    80005590:	b7dd                	j	80005576 <pipewrite+0xde>

0000000080005592 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005592:	715d                	addi	sp,sp,-80
    80005594:	e486                	sd	ra,72(sp)
    80005596:	e0a2                	sd	s0,64(sp)
    80005598:	fc26                	sd	s1,56(sp)
    8000559a:	f84a                	sd	s2,48(sp)
    8000559c:	f44e                	sd	s3,40(sp)
    8000559e:	f052                	sd	s4,32(sp)
    800055a0:	ec56                	sd	s5,24(sp)
    800055a2:	e85a                	sd	s6,16(sp)
    800055a4:	0880                	addi	s0,sp,80
    800055a6:	84aa                	mv	s1,a0
    800055a8:	892e                	mv	s2,a1
    800055aa:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800055ac:	ffffd097          	auipc	ra,0xffffd
    800055b0:	9a2080e7          	jalr	-1630(ra) # 80001f4e <myproc>
    800055b4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800055b6:	8b26                	mv	s6,s1
    800055b8:	8526                	mv	a0,s1
    800055ba:	ffffb097          	auipc	ra,0xffffb
    800055be:	62a080e7          	jalr	1578(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800055c2:	2184a703          	lw	a4,536(s1)
    800055c6:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800055ca:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800055ce:	02f71463          	bne	a4,a5,800055f6 <piperead+0x64>
    800055d2:	2244a783          	lw	a5,548(s1)
    800055d6:	c385                	beqz	a5,800055f6 <piperead+0x64>
    if(pr->killed){
    800055d8:	028a2783          	lw	a5,40(s4)
    800055dc:	ebc1                	bnez	a5,8000566c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800055de:	85da                	mv	a1,s6
    800055e0:	854e                	mv	a0,s3
    800055e2:	ffffd097          	auipc	ra,0xffffd
    800055e6:	fa6080e7          	jalr	-90(ra) # 80002588 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800055ea:	2184a703          	lw	a4,536(s1)
    800055ee:	21c4a783          	lw	a5,540(s1)
    800055f2:	fef700e3          	beq	a4,a5,800055d2 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800055f6:	09505263          	blez	s5,8000567a <piperead+0xe8>
    800055fa:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800055fc:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800055fe:	2184a783          	lw	a5,536(s1)
    80005602:	21c4a703          	lw	a4,540(s1)
    80005606:	02f70d63          	beq	a4,a5,80005640 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000560a:	0017871b          	addiw	a4,a5,1
    8000560e:	20e4ac23          	sw	a4,536(s1)
    80005612:	1ff7f793          	andi	a5,a5,511
    80005616:	97a6                	add	a5,a5,s1
    80005618:	0187c783          	lbu	a5,24(a5)
    8000561c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005620:	4685                	li	a3,1
    80005622:	fbf40613          	addi	a2,s0,-65
    80005626:	85ca                	mv	a1,s2
    80005628:	050a3503          	ld	a0,80(s4)
    8000562c:	ffffc097          	auipc	ra,0xffffc
    80005630:	046080e7          	jalr	70(ra) # 80001672 <copyout>
    80005634:	01650663          	beq	a0,s6,80005640 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005638:	2985                	addiw	s3,s3,1
    8000563a:	0905                	addi	s2,s2,1
    8000563c:	fd3a91e3          	bne	s5,s3,800055fe <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005640:	21c48513          	addi	a0,s1,540
    80005644:	ffffd097          	auipc	ra,0xffffd
    80005648:	5ca080e7          	jalr	1482(ra) # 80002c0e <wakeup>
  release(&pi->lock);
    8000564c:	8526                	mv	a0,s1
    8000564e:	ffffb097          	auipc	ra,0xffffb
    80005652:	64a080e7          	jalr	1610(ra) # 80000c98 <release>
  return i;
}
    80005656:	854e                	mv	a0,s3
    80005658:	60a6                	ld	ra,72(sp)
    8000565a:	6406                	ld	s0,64(sp)
    8000565c:	74e2                	ld	s1,56(sp)
    8000565e:	7942                	ld	s2,48(sp)
    80005660:	79a2                	ld	s3,40(sp)
    80005662:	7a02                	ld	s4,32(sp)
    80005664:	6ae2                	ld	s5,24(sp)
    80005666:	6b42                	ld	s6,16(sp)
    80005668:	6161                	addi	sp,sp,80
    8000566a:	8082                	ret
      release(&pi->lock);
    8000566c:	8526                	mv	a0,s1
    8000566e:	ffffb097          	auipc	ra,0xffffb
    80005672:	62a080e7          	jalr	1578(ra) # 80000c98 <release>
      return -1;
    80005676:	59fd                	li	s3,-1
    80005678:	bff9                	j	80005656 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000567a:	4981                	li	s3,0
    8000567c:	b7d1                	j	80005640 <piperead+0xae>

000000008000567e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000567e:	df010113          	addi	sp,sp,-528
    80005682:	20113423          	sd	ra,520(sp)
    80005686:	20813023          	sd	s0,512(sp)
    8000568a:	ffa6                	sd	s1,504(sp)
    8000568c:	fbca                	sd	s2,496(sp)
    8000568e:	f7ce                	sd	s3,488(sp)
    80005690:	f3d2                	sd	s4,480(sp)
    80005692:	efd6                	sd	s5,472(sp)
    80005694:	ebda                	sd	s6,464(sp)
    80005696:	e7de                	sd	s7,456(sp)
    80005698:	e3e2                	sd	s8,448(sp)
    8000569a:	ff66                	sd	s9,440(sp)
    8000569c:	fb6a                	sd	s10,432(sp)
    8000569e:	f76e                	sd	s11,424(sp)
    800056a0:	0c00                	addi	s0,sp,528
    800056a2:	84aa                	mv	s1,a0
    800056a4:	dea43c23          	sd	a0,-520(s0)
    800056a8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800056ac:	ffffd097          	auipc	ra,0xffffd
    800056b0:	8a2080e7          	jalr	-1886(ra) # 80001f4e <myproc>
    800056b4:	892a                	mv	s2,a0

  begin_op();
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	49c080e7          	jalr	1180(ra) # 80004b52 <begin_op>

  if((ip = namei(path)) == 0){
    800056be:	8526                	mv	a0,s1
    800056c0:	fffff097          	auipc	ra,0xfffff
    800056c4:	276080e7          	jalr	630(ra) # 80004936 <namei>
    800056c8:	c92d                	beqz	a0,8000573a <exec+0xbc>
    800056ca:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	ab4080e7          	jalr	-1356(ra) # 80004180 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800056d4:	04000713          	li	a4,64
    800056d8:	4681                	li	a3,0
    800056da:	e5040613          	addi	a2,s0,-432
    800056de:	4581                	li	a1,0
    800056e0:	8526                	mv	a0,s1
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	d52080e7          	jalr	-686(ra) # 80004434 <readi>
    800056ea:	04000793          	li	a5,64
    800056ee:	00f51a63          	bne	a0,a5,80005702 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800056f2:	e5042703          	lw	a4,-432(s0)
    800056f6:	464c47b7          	lui	a5,0x464c4
    800056fa:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800056fe:	04f70463          	beq	a4,a5,80005746 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005702:	8526                	mv	a0,s1
    80005704:	fffff097          	auipc	ra,0xfffff
    80005708:	cde080e7          	jalr	-802(ra) # 800043e2 <iunlockput>
    end_op();
    8000570c:	fffff097          	auipc	ra,0xfffff
    80005710:	4c6080e7          	jalr	1222(ra) # 80004bd2 <end_op>
  }
  return -1;
    80005714:	557d                	li	a0,-1
}
    80005716:	20813083          	ld	ra,520(sp)
    8000571a:	20013403          	ld	s0,512(sp)
    8000571e:	74fe                	ld	s1,504(sp)
    80005720:	795e                	ld	s2,496(sp)
    80005722:	79be                	ld	s3,488(sp)
    80005724:	7a1e                	ld	s4,480(sp)
    80005726:	6afe                	ld	s5,472(sp)
    80005728:	6b5e                	ld	s6,464(sp)
    8000572a:	6bbe                	ld	s7,456(sp)
    8000572c:	6c1e                	ld	s8,448(sp)
    8000572e:	7cfa                	ld	s9,440(sp)
    80005730:	7d5a                	ld	s10,432(sp)
    80005732:	7dba                	ld	s11,424(sp)
    80005734:	21010113          	addi	sp,sp,528
    80005738:	8082                	ret
    end_op();
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	498080e7          	jalr	1176(ra) # 80004bd2 <end_op>
    return -1;
    80005742:	557d                	li	a0,-1
    80005744:	bfc9                	j	80005716 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005746:	854a                	mv	a0,s2
    80005748:	ffffd097          	auipc	ra,0xffffd
    8000574c:	8c4080e7          	jalr	-1852(ra) # 8000200c <proc_pagetable>
    80005750:	8baa                	mv	s7,a0
    80005752:	d945                	beqz	a0,80005702 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005754:	e7042983          	lw	s3,-400(s0)
    80005758:	e8845783          	lhu	a5,-376(s0)
    8000575c:	c7ad                	beqz	a5,800057c6 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000575e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005760:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005762:	6c85                	lui	s9,0x1
    80005764:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005768:	def43823          	sd	a5,-528(s0)
    8000576c:	a42d                	j	80005996 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000576e:	00003517          	auipc	a0,0x3
    80005772:	2d250513          	addi	a0,a0,722 # 80008a40 <syscalls+0x298>
    80005776:	ffffb097          	auipc	ra,0xffffb
    8000577a:	dc8080e7          	jalr	-568(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000577e:	8756                	mv	a4,s5
    80005780:	012d86bb          	addw	a3,s11,s2
    80005784:	4581                	li	a1,0
    80005786:	8526                	mv	a0,s1
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	cac080e7          	jalr	-852(ra) # 80004434 <readi>
    80005790:	2501                	sext.w	a0,a0
    80005792:	1aaa9963          	bne	s5,a0,80005944 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005796:	6785                	lui	a5,0x1
    80005798:	0127893b          	addw	s2,a5,s2
    8000579c:	77fd                	lui	a5,0xfffff
    8000579e:	01478a3b          	addw	s4,a5,s4
    800057a2:	1f897163          	bgeu	s2,s8,80005984 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800057a6:	02091593          	slli	a1,s2,0x20
    800057aa:	9181                	srli	a1,a1,0x20
    800057ac:	95ea                	add	a1,a1,s10
    800057ae:	855e                	mv	a0,s7
    800057b0:	ffffc097          	auipc	ra,0xffffc
    800057b4:	8be080e7          	jalr	-1858(ra) # 8000106e <walkaddr>
    800057b8:	862a                	mv	a2,a0
    if(pa == 0)
    800057ba:	d955                	beqz	a0,8000576e <exec+0xf0>
      n = PGSIZE;
    800057bc:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800057be:	fd9a70e3          	bgeu	s4,s9,8000577e <exec+0x100>
      n = sz - i;
    800057c2:	8ad2                	mv	s5,s4
    800057c4:	bf6d                	j	8000577e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800057c6:	4901                	li	s2,0
  iunlockput(ip);
    800057c8:	8526                	mv	a0,s1
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	c18080e7          	jalr	-1000(ra) # 800043e2 <iunlockput>
  end_op();
    800057d2:	fffff097          	auipc	ra,0xfffff
    800057d6:	400080e7          	jalr	1024(ra) # 80004bd2 <end_op>
  p = myproc();
    800057da:	ffffc097          	auipc	ra,0xffffc
    800057de:	774080e7          	jalr	1908(ra) # 80001f4e <myproc>
    800057e2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800057e4:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800057e8:	6785                	lui	a5,0x1
    800057ea:	17fd                	addi	a5,a5,-1
    800057ec:	993e                	add	s2,s2,a5
    800057ee:	757d                	lui	a0,0xfffff
    800057f0:	00a977b3          	and	a5,s2,a0
    800057f4:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800057f8:	6609                	lui	a2,0x2
    800057fa:	963e                	add	a2,a2,a5
    800057fc:	85be                	mv	a1,a5
    800057fe:	855e                	mv	a0,s7
    80005800:	ffffc097          	auipc	ra,0xffffc
    80005804:	c22080e7          	jalr	-990(ra) # 80001422 <uvmalloc>
    80005808:	8b2a                	mv	s6,a0
  ip = 0;
    8000580a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000580c:	12050c63          	beqz	a0,80005944 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005810:	75f9                	lui	a1,0xffffe
    80005812:	95aa                	add	a1,a1,a0
    80005814:	855e                	mv	a0,s7
    80005816:	ffffc097          	auipc	ra,0xffffc
    8000581a:	e2a080e7          	jalr	-470(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    8000581e:	7c7d                	lui	s8,0xfffff
    80005820:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005822:	e0043783          	ld	a5,-512(s0)
    80005826:	6388                	ld	a0,0(a5)
    80005828:	c535                	beqz	a0,80005894 <exec+0x216>
    8000582a:	e9040993          	addi	s3,s0,-368
    8000582e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005832:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005834:	ffffb097          	auipc	ra,0xffffb
    80005838:	630080e7          	jalr	1584(ra) # 80000e64 <strlen>
    8000583c:	2505                	addiw	a0,a0,1
    8000583e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005842:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005846:	13896363          	bltu	s2,s8,8000596c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000584a:	e0043d83          	ld	s11,-512(s0)
    8000584e:	000dba03          	ld	s4,0(s11)
    80005852:	8552                	mv	a0,s4
    80005854:	ffffb097          	auipc	ra,0xffffb
    80005858:	610080e7          	jalr	1552(ra) # 80000e64 <strlen>
    8000585c:	0015069b          	addiw	a3,a0,1
    80005860:	8652                	mv	a2,s4
    80005862:	85ca                	mv	a1,s2
    80005864:	855e                	mv	a0,s7
    80005866:	ffffc097          	auipc	ra,0xffffc
    8000586a:	e0c080e7          	jalr	-500(ra) # 80001672 <copyout>
    8000586e:	10054363          	bltz	a0,80005974 <exec+0x2f6>
    ustack[argc] = sp;
    80005872:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005876:	0485                	addi	s1,s1,1
    80005878:	008d8793          	addi	a5,s11,8
    8000587c:	e0f43023          	sd	a5,-512(s0)
    80005880:	008db503          	ld	a0,8(s11)
    80005884:	c911                	beqz	a0,80005898 <exec+0x21a>
    if(argc >= MAXARG)
    80005886:	09a1                	addi	s3,s3,8
    80005888:	fb3c96e3          	bne	s9,s3,80005834 <exec+0x1b6>
  sz = sz1;
    8000588c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005890:	4481                	li	s1,0
    80005892:	a84d                	j	80005944 <exec+0x2c6>
  sp = sz;
    80005894:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005896:	4481                	li	s1,0
  ustack[argc] = 0;
    80005898:	00349793          	slli	a5,s1,0x3
    8000589c:	f9040713          	addi	a4,s0,-112
    800058a0:	97ba                	add	a5,a5,a4
    800058a2:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800058a6:	00148693          	addi	a3,s1,1
    800058aa:	068e                	slli	a3,a3,0x3
    800058ac:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800058b0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800058b4:	01897663          	bgeu	s2,s8,800058c0 <exec+0x242>
  sz = sz1;
    800058b8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800058bc:	4481                	li	s1,0
    800058be:	a059                	j	80005944 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800058c0:	e9040613          	addi	a2,s0,-368
    800058c4:	85ca                	mv	a1,s2
    800058c6:	855e                	mv	a0,s7
    800058c8:	ffffc097          	auipc	ra,0xffffc
    800058cc:	daa080e7          	jalr	-598(ra) # 80001672 <copyout>
    800058d0:	0a054663          	bltz	a0,8000597c <exec+0x2fe>
  p->trapframe->a1 = sp;
    800058d4:	058ab783          	ld	a5,88(s5)
    800058d8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800058dc:	df843783          	ld	a5,-520(s0)
    800058e0:	0007c703          	lbu	a4,0(a5)
    800058e4:	cf11                	beqz	a4,80005900 <exec+0x282>
    800058e6:	0785                	addi	a5,a5,1
    if(*s == '/')
    800058e8:	02f00693          	li	a3,47
    800058ec:	a039                	j	800058fa <exec+0x27c>
      last = s+1;
    800058ee:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800058f2:	0785                	addi	a5,a5,1
    800058f4:	fff7c703          	lbu	a4,-1(a5)
    800058f8:	c701                	beqz	a4,80005900 <exec+0x282>
    if(*s == '/')
    800058fa:	fed71ce3          	bne	a4,a3,800058f2 <exec+0x274>
    800058fe:	bfc5                	j	800058ee <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005900:	4641                	li	a2,16
    80005902:	df843583          	ld	a1,-520(s0)
    80005906:	158a8513          	addi	a0,s5,344
    8000590a:	ffffb097          	auipc	ra,0xffffb
    8000590e:	528080e7          	jalr	1320(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005912:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005916:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000591a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000591e:	058ab783          	ld	a5,88(s5)
    80005922:	e6843703          	ld	a4,-408(s0)
    80005926:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005928:	058ab783          	ld	a5,88(s5)
    8000592c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005930:	85ea                	mv	a1,s10
    80005932:	ffffc097          	auipc	ra,0xffffc
    80005936:	776080e7          	jalr	1910(ra) # 800020a8 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000593a:	0004851b          	sext.w	a0,s1
    8000593e:	bbe1                	j	80005716 <exec+0x98>
    80005940:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005944:	e0843583          	ld	a1,-504(s0)
    80005948:	855e                	mv	a0,s7
    8000594a:	ffffc097          	auipc	ra,0xffffc
    8000594e:	75e080e7          	jalr	1886(ra) # 800020a8 <proc_freepagetable>
  if(ip){
    80005952:	da0498e3          	bnez	s1,80005702 <exec+0x84>
  return -1;
    80005956:	557d                	li	a0,-1
    80005958:	bb7d                	j	80005716 <exec+0x98>
    8000595a:	e1243423          	sd	s2,-504(s0)
    8000595e:	b7dd                	j	80005944 <exec+0x2c6>
    80005960:	e1243423          	sd	s2,-504(s0)
    80005964:	b7c5                	j	80005944 <exec+0x2c6>
    80005966:	e1243423          	sd	s2,-504(s0)
    8000596a:	bfe9                	j	80005944 <exec+0x2c6>
  sz = sz1;
    8000596c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005970:	4481                	li	s1,0
    80005972:	bfc9                	j	80005944 <exec+0x2c6>
  sz = sz1;
    80005974:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005978:	4481                	li	s1,0
    8000597a:	b7e9                	j	80005944 <exec+0x2c6>
  sz = sz1;
    8000597c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005980:	4481                	li	s1,0
    80005982:	b7c9                	j	80005944 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005984:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005988:	2b05                	addiw	s6,s6,1
    8000598a:	0389899b          	addiw	s3,s3,56
    8000598e:	e8845783          	lhu	a5,-376(s0)
    80005992:	e2fb5be3          	bge	s6,a5,800057c8 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005996:	2981                	sext.w	s3,s3
    80005998:	03800713          	li	a4,56
    8000599c:	86ce                	mv	a3,s3
    8000599e:	e1840613          	addi	a2,s0,-488
    800059a2:	4581                	li	a1,0
    800059a4:	8526                	mv	a0,s1
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	a8e080e7          	jalr	-1394(ra) # 80004434 <readi>
    800059ae:	03800793          	li	a5,56
    800059b2:	f8f517e3          	bne	a0,a5,80005940 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800059b6:	e1842783          	lw	a5,-488(s0)
    800059ba:	4705                	li	a4,1
    800059bc:	fce796e3          	bne	a5,a4,80005988 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800059c0:	e4043603          	ld	a2,-448(s0)
    800059c4:	e3843783          	ld	a5,-456(s0)
    800059c8:	f8f669e3          	bltu	a2,a5,8000595a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800059cc:	e2843783          	ld	a5,-472(s0)
    800059d0:	963e                	add	a2,a2,a5
    800059d2:	f8f667e3          	bltu	a2,a5,80005960 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800059d6:	85ca                	mv	a1,s2
    800059d8:	855e                	mv	a0,s7
    800059da:	ffffc097          	auipc	ra,0xffffc
    800059de:	a48080e7          	jalr	-1464(ra) # 80001422 <uvmalloc>
    800059e2:	e0a43423          	sd	a0,-504(s0)
    800059e6:	d141                	beqz	a0,80005966 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800059e8:	e2843d03          	ld	s10,-472(s0)
    800059ec:	df043783          	ld	a5,-528(s0)
    800059f0:	00fd77b3          	and	a5,s10,a5
    800059f4:	fba1                	bnez	a5,80005944 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800059f6:	e2042d83          	lw	s11,-480(s0)
    800059fa:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800059fe:	f80c03e3          	beqz	s8,80005984 <exec+0x306>
    80005a02:	8a62                	mv	s4,s8
    80005a04:	4901                	li	s2,0
    80005a06:	b345                	j	800057a6 <exec+0x128>

0000000080005a08 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005a08:	7179                	addi	sp,sp,-48
    80005a0a:	f406                	sd	ra,40(sp)
    80005a0c:	f022                	sd	s0,32(sp)
    80005a0e:	ec26                	sd	s1,24(sp)
    80005a10:	e84a                	sd	s2,16(sp)
    80005a12:	1800                	addi	s0,sp,48
    80005a14:	892e                	mv	s2,a1
    80005a16:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005a18:	fdc40593          	addi	a1,s0,-36
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	b76080e7          	jalr	-1162(ra) # 80003592 <argint>
    80005a24:	04054063          	bltz	a0,80005a64 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005a28:	fdc42703          	lw	a4,-36(s0)
    80005a2c:	47bd                	li	a5,15
    80005a2e:	02e7ed63          	bltu	a5,a4,80005a68 <argfd+0x60>
    80005a32:	ffffc097          	auipc	ra,0xffffc
    80005a36:	51c080e7          	jalr	1308(ra) # 80001f4e <myproc>
    80005a3a:	fdc42703          	lw	a4,-36(s0)
    80005a3e:	01a70793          	addi	a5,a4,26
    80005a42:	078e                	slli	a5,a5,0x3
    80005a44:	953e                	add	a0,a0,a5
    80005a46:	611c                	ld	a5,0(a0)
    80005a48:	c395                	beqz	a5,80005a6c <argfd+0x64>
    return -1;
  if(pfd)
    80005a4a:	00090463          	beqz	s2,80005a52 <argfd+0x4a>
    *pfd = fd;
    80005a4e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005a52:	4501                	li	a0,0
  if(pf)
    80005a54:	c091                	beqz	s1,80005a58 <argfd+0x50>
    *pf = f;
    80005a56:	e09c                	sd	a5,0(s1)
}
    80005a58:	70a2                	ld	ra,40(sp)
    80005a5a:	7402                	ld	s0,32(sp)
    80005a5c:	64e2                	ld	s1,24(sp)
    80005a5e:	6942                	ld	s2,16(sp)
    80005a60:	6145                	addi	sp,sp,48
    80005a62:	8082                	ret
    return -1;
    80005a64:	557d                	li	a0,-1
    80005a66:	bfcd                	j	80005a58 <argfd+0x50>
    return -1;
    80005a68:	557d                	li	a0,-1
    80005a6a:	b7fd                	j	80005a58 <argfd+0x50>
    80005a6c:	557d                	li	a0,-1
    80005a6e:	b7ed                	j	80005a58 <argfd+0x50>

0000000080005a70 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005a70:	1101                	addi	sp,sp,-32
    80005a72:	ec06                	sd	ra,24(sp)
    80005a74:	e822                	sd	s0,16(sp)
    80005a76:	e426                	sd	s1,8(sp)
    80005a78:	1000                	addi	s0,sp,32
    80005a7a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005a7c:	ffffc097          	auipc	ra,0xffffc
    80005a80:	4d2080e7          	jalr	1234(ra) # 80001f4e <myproc>
    80005a84:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005a86:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005a8a:	4501                	li	a0,0
    80005a8c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005a8e:	6398                	ld	a4,0(a5)
    80005a90:	cb19                	beqz	a4,80005aa6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005a92:	2505                	addiw	a0,a0,1
    80005a94:	07a1                	addi	a5,a5,8
    80005a96:	fed51ce3          	bne	a0,a3,80005a8e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005a9a:	557d                	li	a0,-1
}
    80005a9c:	60e2                	ld	ra,24(sp)
    80005a9e:	6442                	ld	s0,16(sp)
    80005aa0:	64a2                	ld	s1,8(sp)
    80005aa2:	6105                	addi	sp,sp,32
    80005aa4:	8082                	ret
      p->ofile[fd] = f;
    80005aa6:	01a50793          	addi	a5,a0,26
    80005aaa:	078e                	slli	a5,a5,0x3
    80005aac:	963e                	add	a2,a2,a5
    80005aae:	e204                	sd	s1,0(a2)
      return fd;
    80005ab0:	b7f5                	j	80005a9c <fdalloc+0x2c>

0000000080005ab2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005ab2:	715d                	addi	sp,sp,-80
    80005ab4:	e486                	sd	ra,72(sp)
    80005ab6:	e0a2                	sd	s0,64(sp)
    80005ab8:	fc26                	sd	s1,56(sp)
    80005aba:	f84a                	sd	s2,48(sp)
    80005abc:	f44e                	sd	s3,40(sp)
    80005abe:	f052                	sd	s4,32(sp)
    80005ac0:	ec56                	sd	s5,24(sp)
    80005ac2:	0880                	addi	s0,sp,80
    80005ac4:	89ae                	mv	s3,a1
    80005ac6:	8ab2                	mv	s5,a2
    80005ac8:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005aca:	fb040593          	addi	a1,s0,-80
    80005ace:	fffff097          	auipc	ra,0xfffff
    80005ad2:	e86080e7          	jalr	-378(ra) # 80004954 <nameiparent>
    80005ad6:	892a                	mv	s2,a0
    80005ad8:	12050f63          	beqz	a0,80005c16 <create+0x164>
    return 0;

  ilock(dp);
    80005adc:	ffffe097          	auipc	ra,0xffffe
    80005ae0:	6a4080e7          	jalr	1700(ra) # 80004180 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005ae4:	4601                	li	a2,0
    80005ae6:	fb040593          	addi	a1,s0,-80
    80005aea:	854a                	mv	a0,s2
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	b78080e7          	jalr	-1160(ra) # 80004664 <dirlookup>
    80005af4:	84aa                	mv	s1,a0
    80005af6:	c921                	beqz	a0,80005b46 <create+0x94>
    iunlockput(dp);
    80005af8:	854a                	mv	a0,s2
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	8e8080e7          	jalr	-1816(ra) # 800043e2 <iunlockput>
    ilock(ip);
    80005b02:	8526                	mv	a0,s1
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	67c080e7          	jalr	1660(ra) # 80004180 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005b0c:	2981                	sext.w	s3,s3
    80005b0e:	4789                	li	a5,2
    80005b10:	02f99463          	bne	s3,a5,80005b38 <create+0x86>
    80005b14:	0444d783          	lhu	a5,68(s1)
    80005b18:	37f9                	addiw	a5,a5,-2
    80005b1a:	17c2                	slli	a5,a5,0x30
    80005b1c:	93c1                	srli	a5,a5,0x30
    80005b1e:	4705                	li	a4,1
    80005b20:	00f76c63          	bltu	a4,a5,80005b38 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005b24:	8526                	mv	a0,s1
    80005b26:	60a6                	ld	ra,72(sp)
    80005b28:	6406                	ld	s0,64(sp)
    80005b2a:	74e2                	ld	s1,56(sp)
    80005b2c:	7942                	ld	s2,48(sp)
    80005b2e:	79a2                	ld	s3,40(sp)
    80005b30:	7a02                	ld	s4,32(sp)
    80005b32:	6ae2                	ld	s5,24(sp)
    80005b34:	6161                	addi	sp,sp,80
    80005b36:	8082                	ret
    iunlockput(ip);
    80005b38:	8526                	mv	a0,s1
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	8a8080e7          	jalr	-1880(ra) # 800043e2 <iunlockput>
    return 0;
    80005b42:	4481                	li	s1,0
    80005b44:	b7c5                	j	80005b24 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005b46:	85ce                	mv	a1,s3
    80005b48:	00092503          	lw	a0,0(s2)
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	49c080e7          	jalr	1180(ra) # 80003fe8 <ialloc>
    80005b54:	84aa                	mv	s1,a0
    80005b56:	c529                	beqz	a0,80005ba0 <create+0xee>
  ilock(ip);
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	628080e7          	jalr	1576(ra) # 80004180 <ilock>
  ip->major = major;
    80005b60:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005b64:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005b68:	4785                	li	a5,1
    80005b6a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b6e:	8526                	mv	a0,s1
    80005b70:	ffffe097          	auipc	ra,0xffffe
    80005b74:	546080e7          	jalr	1350(ra) # 800040b6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005b78:	2981                	sext.w	s3,s3
    80005b7a:	4785                	li	a5,1
    80005b7c:	02f98a63          	beq	s3,a5,80005bb0 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005b80:	40d0                	lw	a2,4(s1)
    80005b82:	fb040593          	addi	a1,s0,-80
    80005b86:	854a                	mv	a0,s2
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	cec080e7          	jalr	-788(ra) # 80004874 <dirlink>
    80005b90:	06054b63          	bltz	a0,80005c06 <create+0x154>
  iunlockput(dp);
    80005b94:	854a                	mv	a0,s2
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	84c080e7          	jalr	-1972(ra) # 800043e2 <iunlockput>
  return ip;
    80005b9e:	b759                	j	80005b24 <create+0x72>
    panic("create: ialloc");
    80005ba0:	00003517          	auipc	a0,0x3
    80005ba4:	ec050513          	addi	a0,a0,-320 # 80008a60 <syscalls+0x2b8>
    80005ba8:	ffffb097          	auipc	ra,0xffffb
    80005bac:	996080e7          	jalr	-1642(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005bb0:	04a95783          	lhu	a5,74(s2)
    80005bb4:	2785                	addiw	a5,a5,1
    80005bb6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005bba:	854a                	mv	a0,s2
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	4fa080e7          	jalr	1274(ra) # 800040b6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005bc4:	40d0                	lw	a2,4(s1)
    80005bc6:	00003597          	auipc	a1,0x3
    80005bca:	eaa58593          	addi	a1,a1,-342 # 80008a70 <syscalls+0x2c8>
    80005bce:	8526                	mv	a0,s1
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	ca4080e7          	jalr	-860(ra) # 80004874 <dirlink>
    80005bd8:	00054f63          	bltz	a0,80005bf6 <create+0x144>
    80005bdc:	00492603          	lw	a2,4(s2)
    80005be0:	00003597          	auipc	a1,0x3
    80005be4:	e9858593          	addi	a1,a1,-360 # 80008a78 <syscalls+0x2d0>
    80005be8:	8526                	mv	a0,s1
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	c8a080e7          	jalr	-886(ra) # 80004874 <dirlink>
    80005bf2:	f80557e3          	bgez	a0,80005b80 <create+0xce>
      panic("create dots");
    80005bf6:	00003517          	auipc	a0,0x3
    80005bfa:	e8a50513          	addi	a0,a0,-374 # 80008a80 <syscalls+0x2d8>
    80005bfe:	ffffb097          	auipc	ra,0xffffb
    80005c02:	940080e7          	jalr	-1728(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005c06:	00003517          	auipc	a0,0x3
    80005c0a:	e8a50513          	addi	a0,a0,-374 # 80008a90 <syscalls+0x2e8>
    80005c0e:	ffffb097          	auipc	ra,0xffffb
    80005c12:	930080e7          	jalr	-1744(ra) # 8000053e <panic>
    return 0;
    80005c16:	84aa                	mv	s1,a0
    80005c18:	b731                	j	80005b24 <create+0x72>

0000000080005c1a <sys_dup>:
{
    80005c1a:	7179                	addi	sp,sp,-48
    80005c1c:	f406                	sd	ra,40(sp)
    80005c1e:	f022                	sd	s0,32(sp)
    80005c20:	ec26                	sd	s1,24(sp)
    80005c22:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005c24:	fd840613          	addi	a2,s0,-40
    80005c28:	4581                	li	a1,0
    80005c2a:	4501                	li	a0,0
    80005c2c:	00000097          	auipc	ra,0x0
    80005c30:	ddc080e7          	jalr	-548(ra) # 80005a08 <argfd>
    return -1;
    80005c34:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005c36:	02054363          	bltz	a0,80005c5c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005c3a:	fd843503          	ld	a0,-40(s0)
    80005c3e:	00000097          	auipc	ra,0x0
    80005c42:	e32080e7          	jalr	-462(ra) # 80005a70 <fdalloc>
    80005c46:	84aa                	mv	s1,a0
    return -1;
    80005c48:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005c4a:	00054963          	bltz	a0,80005c5c <sys_dup+0x42>
  filedup(f);
    80005c4e:	fd843503          	ld	a0,-40(s0)
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	37a080e7          	jalr	890(ra) # 80004fcc <filedup>
  return fd;
    80005c5a:	87a6                	mv	a5,s1
}
    80005c5c:	853e                	mv	a0,a5
    80005c5e:	70a2                	ld	ra,40(sp)
    80005c60:	7402                	ld	s0,32(sp)
    80005c62:	64e2                	ld	s1,24(sp)
    80005c64:	6145                	addi	sp,sp,48
    80005c66:	8082                	ret

0000000080005c68 <sys_read>:
{
    80005c68:	7179                	addi	sp,sp,-48
    80005c6a:	f406                	sd	ra,40(sp)
    80005c6c:	f022                	sd	s0,32(sp)
    80005c6e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c70:	fe840613          	addi	a2,s0,-24
    80005c74:	4581                	li	a1,0
    80005c76:	4501                	li	a0,0
    80005c78:	00000097          	auipc	ra,0x0
    80005c7c:	d90080e7          	jalr	-624(ra) # 80005a08 <argfd>
    return -1;
    80005c80:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c82:	04054163          	bltz	a0,80005cc4 <sys_read+0x5c>
    80005c86:	fe440593          	addi	a1,s0,-28
    80005c8a:	4509                	li	a0,2
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	906080e7          	jalr	-1786(ra) # 80003592 <argint>
    return -1;
    80005c94:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c96:	02054763          	bltz	a0,80005cc4 <sys_read+0x5c>
    80005c9a:	fd840593          	addi	a1,s0,-40
    80005c9e:	4505                	li	a0,1
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	914080e7          	jalr	-1772(ra) # 800035b4 <argaddr>
    return -1;
    80005ca8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005caa:	00054d63          	bltz	a0,80005cc4 <sys_read+0x5c>
  return fileread(f, p, n);
    80005cae:	fe442603          	lw	a2,-28(s0)
    80005cb2:	fd843583          	ld	a1,-40(s0)
    80005cb6:	fe843503          	ld	a0,-24(s0)
    80005cba:	fffff097          	auipc	ra,0xfffff
    80005cbe:	49e080e7          	jalr	1182(ra) # 80005158 <fileread>
    80005cc2:	87aa                	mv	a5,a0
}
    80005cc4:	853e                	mv	a0,a5
    80005cc6:	70a2                	ld	ra,40(sp)
    80005cc8:	7402                	ld	s0,32(sp)
    80005cca:	6145                	addi	sp,sp,48
    80005ccc:	8082                	ret

0000000080005cce <sys_write>:
{
    80005cce:	7179                	addi	sp,sp,-48
    80005cd0:	f406                	sd	ra,40(sp)
    80005cd2:	f022                	sd	s0,32(sp)
    80005cd4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005cd6:	fe840613          	addi	a2,s0,-24
    80005cda:	4581                	li	a1,0
    80005cdc:	4501                	li	a0,0
    80005cde:	00000097          	auipc	ra,0x0
    80005ce2:	d2a080e7          	jalr	-726(ra) # 80005a08 <argfd>
    return -1;
    80005ce6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ce8:	04054163          	bltz	a0,80005d2a <sys_write+0x5c>
    80005cec:	fe440593          	addi	a1,s0,-28
    80005cf0:	4509                	li	a0,2
    80005cf2:	ffffe097          	auipc	ra,0xffffe
    80005cf6:	8a0080e7          	jalr	-1888(ra) # 80003592 <argint>
    return -1;
    80005cfa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005cfc:	02054763          	bltz	a0,80005d2a <sys_write+0x5c>
    80005d00:	fd840593          	addi	a1,s0,-40
    80005d04:	4505                	li	a0,1
    80005d06:	ffffe097          	auipc	ra,0xffffe
    80005d0a:	8ae080e7          	jalr	-1874(ra) # 800035b4 <argaddr>
    return -1;
    80005d0e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005d10:	00054d63          	bltz	a0,80005d2a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005d14:	fe442603          	lw	a2,-28(s0)
    80005d18:	fd843583          	ld	a1,-40(s0)
    80005d1c:	fe843503          	ld	a0,-24(s0)
    80005d20:	fffff097          	auipc	ra,0xfffff
    80005d24:	4fa080e7          	jalr	1274(ra) # 8000521a <filewrite>
    80005d28:	87aa                	mv	a5,a0
}
    80005d2a:	853e                	mv	a0,a5
    80005d2c:	70a2                	ld	ra,40(sp)
    80005d2e:	7402                	ld	s0,32(sp)
    80005d30:	6145                	addi	sp,sp,48
    80005d32:	8082                	ret

0000000080005d34 <sys_close>:
{
    80005d34:	1101                	addi	sp,sp,-32
    80005d36:	ec06                	sd	ra,24(sp)
    80005d38:	e822                	sd	s0,16(sp)
    80005d3a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005d3c:	fe040613          	addi	a2,s0,-32
    80005d40:	fec40593          	addi	a1,s0,-20
    80005d44:	4501                	li	a0,0
    80005d46:	00000097          	auipc	ra,0x0
    80005d4a:	cc2080e7          	jalr	-830(ra) # 80005a08 <argfd>
    return -1;
    80005d4e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005d50:	02054463          	bltz	a0,80005d78 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005d54:	ffffc097          	auipc	ra,0xffffc
    80005d58:	1fa080e7          	jalr	506(ra) # 80001f4e <myproc>
    80005d5c:	fec42783          	lw	a5,-20(s0)
    80005d60:	07e9                	addi	a5,a5,26
    80005d62:	078e                	slli	a5,a5,0x3
    80005d64:	97aa                	add	a5,a5,a0
    80005d66:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005d6a:	fe043503          	ld	a0,-32(s0)
    80005d6e:	fffff097          	auipc	ra,0xfffff
    80005d72:	2b0080e7          	jalr	688(ra) # 8000501e <fileclose>
  return 0;
    80005d76:	4781                	li	a5,0
}
    80005d78:	853e                	mv	a0,a5
    80005d7a:	60e2                	ld	ra,24(sp)
    80005d7c:	6442                	ld	s0,16(sp)
    80005d7e:	6105                	addi	sp,sp,32
    80005d80:	8082                	ret

0000000080005d82 <sys_fstat>:
{
    80005d82:	1101                	addi	sp,sp,-32
    80005d84:	ec06                	sd	ra,24(sp)
    80005d86:	e822                	sd	s0,16(sp)
    80005d88:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005d8a:	fe840613          	addi	a2,s0,-24
    80005d8e:	4581                	li	a1,0
    80005d90:	4501                	li	a0,0
    80005d92:	00000097          	auipc	ra,0x0
    80005d96:	c76080e7          	jalr	-906(ra) # 80005a08 <argfd>
    return -1;
    80005d9a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005d9c:	02054563          	bltz	a0,80005dc6 <sys_fstat+0x44>
    80005da0:	fe040593          	addi	a1,s0,-32
    80005da4:	4505                	li	a0,1
    80005da6:	ffffe097          	auipc	ra,0xffffe
    80005daa:	80e080e7          	jalr	-2034(ra) # 800035b4 <argaddr>
    return -1;
    80005dae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005db0:	00054b63          	bltz	a0,80005dc6 <sys_fstat+0x44>
  return filestat(f, st);
    80005db4:	fe043583          	ld	a1,-32(s0)
    80005db8:	fe843503          	ld	a0,-24(s0)
    80005dbc:	fffff097          	auipc	ra,0xfffff
    80005dc0:	32a080e7          	jalr	810(ra) # 800050e6 <filestat>
    80005dc4:	87aa                	mv	a5,a0
}
    80005dc6:	853e                	mv	a0,a5
    80005dc8:	60e2                	ld	ra,24(sp)
    80005dca:	6442                	ld	s0,16(sp)
    80005dcc:	6105                	addi	sp,sp,32
    80005dce:	8082                	ret

0000000080005dd0 <sys_link>:
{
    80005dd0:	7169                	addi	sp,sp,-304
    80005dd2:	f606                	sd	ra,296(sp)
    80005dd4:	f222                	sd	s0,288(sp)
    80005dd6:	ee26                	sd	s1,280(sp)
    80005dd8:	ea4a                	sd	s2,272(sp)
    80005dda:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ddc:	08000613          	li	a2,128
    80005de0:	ed040593          	addi	a1,s0,-304
    80005de4:	4501                	li	a0,0
    80005de6:	ffffd097          	auipc	ra,0xffffd
    80005dea:	7f0080e7          	jalr	2032(ra) # 800035d6 <argstr>
    return -1;
    80005dee:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005df0:	10054e63          	bltz	a0,80005f0c <sys_link+0x13c>
    80005df4:	08000613          	li	a2,128
    80005df8:	f5040593          	addi	a1,s0,-176
    80005dfc:	4505                	li	a0,1
    80005dfe:	ffffd097          	auipc	ra,0xffffd
    80005e02:	7d8080e7          	jalr	2008(ra) # 800035d6 <argstr>
    return -1;
    80005e06:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005e08:	10054263          	bltz	a0,80005f0c <sys_link+0x13c>
  begin_op();
    80005e0c:	fffff097          	auipc	ra,0xfffff
    80005e10:	d46080e7          	jalr	-698(ra) # 80004b52 <begin_op>
  if((ip = namei(old)) == 0){
    80005e14:	ed040513          	addi	a0,s0,-304
    80005e18:	fffff097          	auipc	ra,0xfffff
    80005e1c:	b1e080e7          	jalr	-1250(ra) # 80004936 <namei>
    80005e20:	84aa                	mv	s1,a0
    80005e22:	c551                	beqz	a0,80005eae <sys_link+0xde>
  ilock(ip);
    80005e24:	ffffe097          	auipc	ra,0xffffe
    80005e28:	35c080e7          	jalr	860(ra) # 80004180 <ilock>
  if(ip->type == T_DIR){
    80005e2c:	04449703          	lh	a4,68(s1)
    80005e30:	4785                	li	a5,1
    80005e32:	08f70463          	beq	a4,a5,80005eba <sys_link+0xea>
  ip->nlink++;
    80005e36:	04a4d783          	lhu	a5,74(s1)
    80005e3a:	2785                	addiw	a5,a5,1
    80005e3c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005e40:	8526                	mv	a0,s1
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	274080e7          	jalr	628(ra) # 800040b6 <iupdate>
  iunlock(ip);
    80005e4a:	8526                	mv	a0,s1
    80005e4c:	ffffe097          	auipc	ra,0xffffe
    80005e50:	3f6080e7          	jalr	1014(ra) # 80004242 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005e54:	fd040593          	addi	a1,s0,-48
    80005e58:	f5040513          	addi	a0,s0,-176
    80005e5c:	fffff097          	auipc	ra,0xfffff
    80005e60:	af8080e7          	jalr	-1288(ra) # 80004954 <nameiparent>
    80005e64:	892a                	mv	s2,a0
    80005e66:	c935                	beqz	a0,80005eda <sys_link+0x10a>
  ilock(dp);
    80005e68:	ffffe097          	auipc	ra,0xffffe
    80005e6c:	318080e7          	jalr	792(ra) # 80004180 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005e70:	00092703          	lw	a4,0(s2)
    80005e74:	409c                	lw	a5,0(s1)
    80005e76:	04f71d63          	bne	a4,a5,80005ed0 <sys_link+0x100>
    80005e7a:	40d0                	lw	a2,4(s1)
    80005e7c:	fd040593          	addi	a1,s0,-48
    80005e80:	854a                	mv	a0,s2
    80005e82:	fffff097          	auipc	ra,0xfffff
    80005e86:	9f2080e7          	jalr	-1550(ra) # 80004874 <dirlink>
    80005e8a:	04054363          	bltz	a0,80005ed0 <sys_link+0x100>
  iunlockput(dp);
    80005e8e:	854a                	mv	a0,s2
    80005e90:	ffffe097          	auipc	ra,0xffffe
    80005e94:	552080e7          	jalr	1362(ra) # 800043e2 <iunlockput>
  iput(ip);
    80005e98:	8526                	mv	a0,s1
    80005e9a:	ffffe097          	auipc	ra,0xffffe
    80005e9e:	4a0080e7          	jalr	1184(ra) # 8000433a <iput>
  end_op();
    80005ea2:	fffff097          	auipc	ra,0xfffff
    80005ea6:	d30080e7          	jalr	-720(ra) # 80004bd2 <end_op>
  return 0;
    80005eaa:	4781                	li	a5,0
    80005eac:	a085                	j	80005f0c <sys_link+0x13c>
    end_op();
    80005eae:	fffff097          	auipc	ra,0xfffff
    80005eb2:	d24080e7          	jalr	-732(ra) # 80004bd2 <end_op>
    return -1;
    80005eb6:	57fd                	li	a5,-1
    80005eb8:	a891                	j	80005f0c <sys_link+0x13c>
    iunlockput(ip);
    80005eba:	8526                	mv	a0,s1
    80005ebc:	ffffe097          	auipc	ra,0xffffe
    80005ec0:	526080e7          	jalr	1318(ra) # 800043e2 <iunlockput>
    end_op();
    80005ec4:	fffff097          	auipc	ra,0xfffff
    80005ec8:	d0e080e7          	jalr	-754(ra) # 80004bd2 <end_op>
    return -1;
    80005ecc:	57fd                	li	a5,-1
    80005ece:	a83d                	j	80005f0c <sys_link+0x13c>
    iunlockput(dp);
    80005ed0:	854a                	mv	a0,s2
    80005ed2:	ffffe097          	auipc	ra,0xffffe
    80005ed6:	510080e7          	jalr	1296(ra) # 800043e2 <iunlockput>
  ilock(ip);
    80005eda:	8526                	mv	a0,s1
    80005edc:	ffffe097          	auipc	ra,0xffffe
    80005ee0:	2a4080e7          	jalr	676(ra) # 80004180 <ilock>
  ip->nlink--;
    80005ee4:	04a4d783          	lhu	a5,74(s1)
    80005ee8:	37fd                	addiw	a5,a5,-1
    80005eea:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005eee:	8526                	mv	a0,s1
    80005ef0:	ffffe097          	auipc	ra,0xffffe
    80005ef4:	1c6080e7          	jalr	454(ra) # 800040b6 <iupdate>
  iunlockput(ip);
    80005ef8:	8526                	mv	a0,s1
    80005efa:	ffffe097          	auipc	ra,0xffffe
    80005efe:	4e8080e7          	jalr	1256(ra) # 800043e2 <iunlockput>
  end_op();
    80005f02:	fffff097          	auipc	ra,0xfffff
    80005f06:	cd0080e7          	jalr	-816(ra) # 80004bd2 <end_op>
  return -1;
    80005f0a:	57fd                	li	a5,-1
}
    80005f0c:	853e                	mv	a0,a5
    80005f0e:	70b2                	ld	ra,296(sp)
    80005f10:	7412                	ld	s0,288(sp)
    80005f12:	64f2                	ld	s1,280(sp)
    80005f14:	6952                	ld	s2,272(sp)
    80005f16:	6155                	addi	sp,sp,304
    80005f18:	8082                	ret

0000000080005f1a <sys_unlink>:
{
    80005f1a:	7151                	addi	sp,sp,-240
    80005f1c:	f586                	sd	ra,232(sp)
    80005f1e:	f1a2                	sd	s0,224(sp)
    80005f20:	eda6                	sd	s1,216(sp)
    80005f22:	e9ca                	sd	s2,208(sp)
    80005f24:	e5ce                	sd	s3,200(sp)
    80005f26:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005f28:	08000613          	li	a2,128
    80005f2c:	f3040593          	addi	a1,s0,-208
    80005f30:	4501                	li	a0,0
    80005f32:	ffffd097          	auipc	ra,0xffffd
    80005f36:	6a4080e7          	jalr	1700(ra) # 800035d6 <argstr>
    80005f3a:	18054163          	bltz	a0,800060bc <sys_unlink+0x1a2>
  begin_op();
    80005f3e:	fffff097          	auipc	ra,0xfffff
    80005f42:	c14080e7          	jalr	-1004(ra) # 80004b52 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005f46:	fb040593          	addi	a1,s0,-80
    80005f4a:	f3040513          	addi	a0,s0,-208
    80005f4e:	fffff097          	auipc	ra,0xfffff
    80005f52:	a06080e7          	jalr	-1530(ra) # 80004954 <nameiparent>
    80005f56:	84aa                	mv	s1,a0
    80005f58:	c979                	beqz	a0,8000602e <sys_unlink+0x114>
  ilock(dp);
    80005f5a:	ffffe097          	auipc	ra,0xffffe
    80005f5e:	226080e7          	jalr	550(ra) # 80004180 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005f62:	00003597          	auipc	a1,0x3
    80005f66:	b0e58593          	addi	a1,a1,-1266 # 80008a70 <syscalls+0x2c8>
    80005f6a:	fb040513          	addi	a0,s0,-80
    80005f6e:	ffffe097          	auipc	ra,0xffffe
    80005f72:	6dc080e7          	jalr	1756(ra) # 8000464a <namecmp>
    80005f76:	14050a63          	beqz	a0,800060ca <sys_unlink+0x1b0>
    80005f7a:	00003597          	auipc	a1,0x3
    80005f7e:	afe58593          	addi	a1,a1,-1282 # 80008a78 <syscalls+0x2d0>
    80005f82:	fb040513          	addi	a0,s0,-80
    80005f86:	ffffe097          	auipc	ra,0xffffe
    80005f8a:	6c4080e7          	jalr	1732(ra) # 8000464a <namecmp>
    80005f8e:	12050e63          	beqz	a0,800060ca <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005f92:	f2c40613          	addi	a2,s0,-212
    80005f96:	fb040593          	addi	a1,s0,-80
    80005f9a:	8526                	mv	a0,s1
    80005f9c:	ffffe097          	auipc	ra,0xffffe
    80005fa0:	6c8080e7          	jalr	1736(ra) # 80004664 <dirlookup>
    80005fa4:	892a                	mv	s2,a0
    80005fa6:	12050263          	beqz	a0,800060ca <sys_unlink+0x1b0>
  ilock(ip);
    80005faa:	ffffe097          	auipc	ra,0xffffe
    80005fae:	1d6080e7          	jalr	470(ra) # 80004180 <ilock>
  if(ip->nlink < 1)
    80005fb2:	04a91783          	lh	a5,74(s2)
    80005fb6:	08f05263          	blez	a5,8000603a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005fba:	04491703          	lh	a4,68(s2)
    80005fbe:	4785                	li	a5,1
    80005fc0:	08f70563          	beq	a4,a5,8000604a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005fc4:	4641                	li	a2,16
    80005fc6:	4581                	li	a1,0
    80005fc8:	fc040513          	addi	a0,s0,-64
    80005fcc:	ffffb097          	auipc	ra,0xffffb
    80005fd0:	d14080e7          	jalr	-748(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005fd4:	4741                	li	a4,16
    80005fd6:	f2c42683          	lw	a3,-212(s0)
    80005fda:	fc040613          	addi	a2,s0,-64
    80005fde:	4581                	li	a1,0
    80005fe0:	8526                	mv	a0,s1
    80005fe2:	ffffe097          	auipc	ra,0xffffe
    80005fe6:	54a080e7          	jalr	1354(ra) # 8000452c <writei>
    80005fea:	47c1                	li	a5,16
    80005fec:	0af51563          	bne	a0,a5,80006096 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005ff0:	04491703          	lh	a4,68(s2)
    80005ff4:	4785                	li	a5,1
    80005ff6:	0af70863          	beq	a4,a5,800060a6 <sys_unlink+0x18c>
  iunlockput(dp);
    80005ffa:	8526                	mv	a0,s1
    80005ffc:	ffffe097          	auipc	ra,0xffffe
    80006000:	3e6080e7          	jalr	998(ra) # 800043e2 <iunlockput>
  ip->nlink--;
    80006004:	04a95783          	lhu	a5,74(s2)
    80006008:	37fd                	addiw	a5,a5,-1
    8000600a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000600e:	854a                	mv	a0,s2
    80006010:	ffffe097          	auipc	ra,0xffffe
    80006014:	0a6080e7          	jalr	166(ra) # 800040b6 <iupdate>
  iunlockput(ip);
    80006018:	854a                	mv	a0,s2
    8000601a:	ffffe097          	auipc	ra,0xffffe
    8000601e:	3c8080e7          	jalr	968(ra) # 800043e2 <iunlockput>
  end_op();
    80006022:	fffff097          	auipc	ra,0xfffff
    80006026:	bb0080e7          	jalr	-1104(ra) # 80004bd2 <end_op>
  return 0;
    8000602a:	4501                	li	a0,0
    8000602c:	a84d                	j	800060de <sys_unlink+0x1c4>
    end_op();
    8000602e:	fffff097          	auipc	ra,0xfffff
    80006032:	ba4080e7          	jalr	-1116(ra) # 80004bd2 <end_op>
    return -1;
    80006036:	557d                	li	a0,-1
    80006038:	a05d                	j	800060de <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000603a:	00003517          	auipc	a0,0x3
    8000603e:	a6650513          	addi	a0,a0,-1434 # 80008aa0 <syscalls+0x2f8>
    80006042:	ffffa097          	auipc	ra,0xffffa
    80006046:	4fc080e7          	jalr	1276(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000604a:	04c92703          	lw	a4,76(s2)
    8000604e:	02000793          	li	a5,32
    80006052:	f6e7f9e3          	bgeu	a5,a4,80005fc4 <sys_unlink+0xaa>
    80006056:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000605a:	4741                	li	a4,16
    8000605c:	86ce                	mv	a3,s3
    8000605e:	f1840613          	addi	a2,s0,-232
    80006062:	4581                	li	a1,0
    80006064:	854a                	mv	a0,s2
    80006066:	ffffe097          	auipc	ra,0xffffe
    8000606a:	3ce080e7          	jalr	974(ra) # 80004434 <readi>
    8000606e:	47c1                	li	a5,16
    80006070:	00f51b63          	bne	a0,a5,80006086 <sys_unlink+0x16c>
    if(de.inum != 0)
    80006074:	f1845783          	lhu	a5,-232(s0)
    80006078:	e7a1                	bnez	a5,800060c0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000607a:	29c1                	addiw	s3,s3,16
    8000607c:	04c92783          	lw	a5,76(s2)
    80006080:	fcf9ede3          	bltu	s3,a5,8000605a <sys_unlink+0x140>
    80006084:	b781                	j	80005fc4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006086:	00003517          	auipc	a0,0x3
    8000608a:	a3250513          	addi	a0,a0,-1486 # 80008ab8 <syscalls+0x310>
    8000608e:	ffffa097          	auipc	ra,0xffffa
    80006092:	4b0080e7          	jalr	1200(ra) # 8000053e <panic>
    panic("unlink: writei");
    80006096:	00003517          	auipc	a0,0x3
    8000609a:	a3a50513          	addi	a0,a0,-1478 # 80008ad0 <syscalls+0x328>
    8000609e:	ffffa097          	auipc	ra,0xffffa
    800060a2:	4a0080e7          	jalr	1184(ra) # 8000053e <panic>
    dp->nlink--;
    800060a6:	04a4d783          	lhu	a5,74(s1)
    800060aa:	37fd                	addiw	a5,a5,-1
    800060ac:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800060b0:	8526                	mv	a0,s1
    800060b2:	ffffe097          	auipc	ra,0xffffe
    800060b6:	004080e7          	jalr	4(ra) # 800040b6 <iupdate>
    800060ba:	b781                	j	80005ffa <sys_unlink+0xe0>
    return -1;
    800060bc:	557d                	li	a0,-1
    800060be:	a005                	j	800060de <sys_unlink+0x1c4>
    iunlockput(ip);
    800060c0:	854a                	mv	a0,s2
    800060c2:	ffffe097          	auipc	ra,0xffffe
    800060c6:	320080e7          	jalr	800(ra) # 800043e2 <iunlockput>
  iunlockput(dp);
    800060ca:	8526                	mv	a0,s1
    800060cc:	ffffe097          	auipc	ra,0xffffe
    800060d0:	316080e7          	jalr	790(ra) # 800043e2 <iunlockput>
  end_op();
    800060d4:	fffff097          	auipc	ra,0xfffff
    800060d8:	afe080e7          	jalr	-1282(ra) # 80004bd2 <end_op>
  return -1;
    800060dc:	557d                	li	a0,-1
}
    800060de:	70ae                	ld	ra,232(sp)
    800060e0:	740e                	ld	s0,224(sp)
    800060e2:	64ee                	ld	s1,216(sp)
    800060e4:	694e                	ld	s2,208(sp)
    800060e6:	69ae                	ld	s3,200(sp)
    800060e8:	616d                	addi	sp,sp,240
    800060ea:	8082                	ret

00000000800060ec <sys_open>:

uint64
sys_open(void)
{
    800060ec:	7131                	addi	sp,sp,-192
    800060ee:	fd06                	sd	ra,184(sp)
    800060f0:	f922                	sd	s0,176(sp)
    800060f2:	f526                	sd	s1,168(sp)
    800060f4:	f14a                	sd	s2,160(sp)
    800060f6:	ed4e                	sd	s3,152(sp)
    800060f8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800060fa:	08000613          	li	a2,128
    800060fe:	f5040593          	addi	a1,s0,-176
    80006102:	4501                	li	a0,0
    80006104:	ffffd097          	auipc	ra,0xffffd
    80006108:	4d2080e7          	jalr	1234(ra) # 800035d6 <argstr>
    return -1;
    8000610c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000610e:	0c054163          	bltz	a0,800061d0 <sys_open+0xe4>
    80006112:	f4c40593          	addi	a1,s0,-180
    80006116:	4505                	li	a0,1
    80006118:	ffffd097          	auipc	ra,0xffffd
    8000611c:	47a080e7          	jalr	1146(ra) # 80003592 <argint>
    80006120:	0a054863          	bltz	a0,800061d0 <sys_open+0xe4>

  begin_op();
    80006124:	fffff097          	auipc	ra,0xfffff
    80006128:	a2e080e7          	jalr	-1490(ra) # 80004b52 <begin_op>

  if(omode & O_CREATE){
    8000612c:	f4c42783          	lw	a5,-180(s0)
    80006130:	2007f793          	andi	a5,a5,512
    80006134:	cbdd                	beqz	a5,800061ea <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006136:	4681                	li	a3,0
    80006138:	4601                	li	a2,0
    8000613a:	4589                	li	a1,2
    8000613c:	f5040513          	addi	a0,s0,-176
    80006140:	00000097          	auipc	ra,0x0
    80006144:	972080e7          	jalr	-1678(ra) # 80005ab2 <create>
    80006148:	892a                	mv	s2,a0
    if(ip == 0){
    8000614a:	c959                	beqz	a0,800061e0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000614c:	04491703          	lh	a4,68(s2)
    80006150:	478d                	li	a5,3
    80006152:	00f71763          	bne	a4,a5,80006160 <sys_open+0x74>
    80006156:	04695703          	lhu	a4,70(s2)
    8000615a:	47a5                	li	a5,9
    8000615c:	0ce7ec63          	bltu	a5,a4,80006234 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006160:	fffff097          	auipc	ra,0xfffff
    80006164:	e02080e7          	jalr	-510(ra) # 80004f62 <filealloc>
    80006168:	89aa                	mv	s3,a0
    8000616a:	10050263          	beqz	a0,8000626e <sys_open+0x182>
    8000616e:	00000097          	auipc	ra,0x0
    80006172:	902080e7          	jalr	-1790(ra) # 80005a70 <fdalloc>
    80006176:	84aa                	mv	s1,a0
    80006178:	0e054663          	bltz	a0,80006264 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000617c:	04491703          	lh	a4,68(s2)
    80006180:	478d                	li	a5,3
    80006182:	0cf70463          	beq	a4,a5,8000624a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006186:	4789                	li	a5,2
    80006188:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000618c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006190:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006194:	f4c42783          	lw	a5,-180(s0)
    80006198:	0017c713          	xori	a4,a5,1
    8000619c:	8b05                	andi	a4,a4,1
    8000619e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800061a2:	0037f713          	andi	a4,a5,3
    800061a6:	00e03733          	snez	a4,a4
    800061aa:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800061ae:	4007f793          	andi	a5,a5,1024
    800061b2:	c791                	beqz	a5,800061be <sys_open+0xd2>
    800061b4:	04491703          	lh	a4,68(s2)
    800061b8:	4789                	li	a5,2
    800061ba:	08f70f63          	beq	a4,a5,80006258 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800061be:	854a                	mv	a0,s2
    800061c0:	ffffe097          	auipc	ra,0xffffe
    800061c4:	082080e7          	jalr	130(ra) # 80004242 <iunlock>
  end_op();
    800061c8:	fffff097          	auipc	ra,0xfffff
    800061cc:	a0a080e7          	jalr	-1526(ra) # 80004bd2 <end_op>

  return fd;
}
    800061d0:	8526                	mv	a0,s1
    800061d2:	70ea                	ld	ra,184(sp)
    800061d4:	744a                	ld	s0,176(sp)
    800061d6:	74aa                	ld	s1,168(sp)
    800061d8:	790a                	ld	s2,160(sp)
    800061da:	69ea                	ld	s3,152(sp)
    800061dc:	6129                	addi	sp,sp,192
    800061de:	8082                	ret
      end_op();
    800061e0:	fffff097          	auipc	ra,0xfffff
    800061e4:	9f2080e7          	jalr	-1550(ra) # 80004bd2 <end_op>
      return -1;
    800061e8:	b7e5                	j	800061d0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800061ea:	f5040513          	addi	a0,s0,-176
    800061ee:	ffffe097          	auipc	ra,0xffffe
    800061f2:	748080e7          	jalr	1864(ra) # 80004936 <namei>
    800061f6:	892a                	mv	s2,a0
    800061f8:	c905                	beqz	a0,80006228 <sys_open+0x13c>
    ilock(ip);
    800061fa:	ffffe097          	auipc	ra,0xffffe
    800061fe:	f86080e7          	jalr	-122(ra) # 80004180 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006202:	04491703          	lh	a4,68(s2)
    80006206:	4785                	li	a5,1
    80006208:	f4f712e3          	bne	a4,a5,8000614c <sys_open+0x60>
    8000620c:	f4c42783          	lw	a5,-180(s0)
    80006210:	dba1                	beqz	a5,80006160 <sys_open+0x74>
      iunlockput(ip);
    80006212:	854a                	mv	a0,s2
    80006214:	ffffe097          	auipc	ra,0xffffe
    80006218:	1ce080e7          	jalr	462(ra) # 800043e2 <iunlockput>
      end_op();
    8000621c:	fffff097          	auipc	ra,0xfffff
    80006220:	9b6080e7          	jalr	-1610(ra) # 80004bd2 <end_op>
      return -1;
    80006224:	54fd                	li	s1,-1
    80006226:	b76d                	j	800061d0 <sys_open+0xe4>
      end_op();
    80006228:	fffff097          	auipc	ra,0xfffff
    8000622c:	9aa080e7          	jalr	-1622(ra) # 80004bd2 <end_op>
      return -1;
    80006230:	54fd                	li	s1,-1
    80006232:	bf79                	j	800061d0 <sys_open+0xe4>
    iunlockput(ip);
    80006234:	854a                	mv	a0,s2
    80006236:	ffffe097          	auipc	ra,0xffffe
    8000623a:	1ac080e7          	jalr	428(ra) # 800043e2 <iunlockput>
    end_op();
    8000623e:	fffff097          	auipc	ra,0xfffff
    80006242:	994080e7          	jalr	-1644(ra) # 80004bd2 <end_op>
    return -1;
    80006246:	54fd                	li	s1,-1
    80006248:	b761                	j	800061d0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000624a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000624e:	04691783          	lh	a5,70(s2)
    80006252:	02f99223          	sh	a5,36(s3)
    80006256:	bf2d                	j	80006190 <sys_open+0xa4>
    itrunc(ip);
    80006258:	854a                	mv	a0,s2
    8000625a:	ffffe097          	auipc	ra,0xffffe
    8000625e:	034080e7          	jalr	52(ra) # 8000428e <itrunc>
    80006262:	bfb1                	j	800061be <sys_open+0xd2>
      fileclose(f);
    80006264:	854e                	mv	a0,s3
    80006266:	fffff097          	auipc	ra,0xfffff
    8000626a:	db8080e7          	jalr	-584(ra) # 8000501e <fileclose>
    iunlockput(ip);
    8000626e:	854a                	mv	a0,s2
    80006270:	ffffe097          	auipc	ra,0xffffe
    80006274:	172080e7          	jalr	370(ra) # 800043e2 <iunlockput>
    end_op();
    80006278:	fffff097          	auipc	ra,0xfffff
    8000627c:	95a080e7          	jalr	-1702(ra) # 80004bd2 <end_op>
    return -1;
    80006280:	54fd                	li	s1,-1
    80006282:	b7b9                	j	800061d0 <sys_open+0xe4>

0000000080006284 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006284:	7175                	addi	sp,sp,-144
    80006286:	e506                	sd	ra,136(sp)
    80006288:	e122                	sd	s0,128(sp)
    8000628a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000628c:	fffff097          	auipc	ra,0xfffff
    80006290:	8c6080e7          	jalr	-1850(ra) # 80004b52 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006294:	08000613          	li	a2,128
    80006298:	f7040593          	addi	a1,s0,-144
    8000629c:	4501                	li	a0,0
    8000629e:	ffffd097          	auipc	ra,0xffffd
    800062a2:	338080e7          	jalr	824(ra) # 800035d6 <argstr>
    800062a6:	02054963          	bltz	a0,800062d8 <sys_mkdir+0x54>
    800062aa:	4681                	li	a3,0
    800062ac:	4601                	li	a2,0
    800062ae:	4585                	li	a1,1
    800062b0:	f7040513          	addi	a0,s0,-144
    800062b4:	fffff097          	auipc	ra,0xfffff
    800062b8:	7fe080e7          	jalr	2046(ra) # 80005ab2 <create>
    800062bc:	cd11                	beqz	a0,800062d8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800062be:	ffffe097          	auipc	ra,0xffffe
    800062c2:	124080e7          	jalr	292(ra) # 800043e2 <iunlockput>
  end_op();
    800062c6:	fffff097          	auipc	ra,0xfffff
    800062ca:	90c080e7          	jalr	-1780(ra) # 80004bd2 <end_op>
  return 0;
    800062ce:	4501                	li	a0,0
}
    800062d0:	60aa                	ld	ra,136(sp)
    800062d2:	640a                	ld	s0,128(sp)
    800062d4:	6149                	addi	sp,sp,144
    800062d6:	8082                	ret
    end_op();
    800062d8:	fffff097          	auipc	ra,0xfffff
    800062dc:	8fa080e7          	jalr	-1798(ra) # 80004bd2 <end_op>
    return -1;
    800062e0:	557d                	li	a0,-1
    800062e2:	b7fd                	j	800062d0 <sys_mkdir+0x4c>

00000000800062e4 <sys_mknod>:

uint64
sys_mknod(void)
{
    800062e4:	7135                	addi	sp,sp,-160
    800062e6:	ed06                	sd	ra,152(sp)
    800062e8:	e922                	sd	s0,144(sp)
    800062ea:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800062ec:	fffff097          	auipc	ra,0xfffff
    800062f0:	866080e7          	jalr	-1946(ra) # 80004b52 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800062f4:	08000613          	li	a2,128
    800062f8:	f7040593          	addi	a1,s0,-144
    800062fc:	4501                	li	a0,0
    800062fe:	ffffd097          	auipc	ra,0xffffd
    80006302:	2d8080e7          	jalr	728(ra) # 800035d6 <argstr>
    80006306:	04054a63          	bltz	a0,8000635a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000630a:	f6c40593          	addi	a1,s0,-148
    8000630e:	4505                	li	a0,1
    80006310:	ffffd097          	auipc	ra,0xffffd
    80006314:	282080e7          	jalr	642(ra) # 80003592 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006318:	04054163          	bltz	a0,8000635a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000631c:	f6840593          	addi	a1,s0,-152
    80006320:	4509                	li	a0,2
    80006322:	ffffd097          	auipc	ra,0xffffd
    80006326:	270080e7          	jalr	624(ra) # 80003592 <argint>
     argint(1, &major) < 0 ||
    8000632a:	02054863          	bltz	a0,8000635a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000632e:	f6841683          	lh	a3,-152(s0)
    80006332:	f6c41603          	lh	a2,-148(s0)
    80006336:	458d                	li	a1,3
    80006338:	f7040513          	addi	a0,s0,-144
    8000633c:	fffff097          	auipc	ra,0xfffff
    80006340:	776080e7          	jalr	1910(ra) # 80005ab2 <create>
     argint(2, &minor) < 0 ||
    80006344:	c919                	beqz	a0,8000635a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006346:	ffffe097          	auipc	ra,0xffffe
    8000634a:	09c080e7          	jalr	156(ra) # 800043e2 <iunlockput>
  end_op();
    8000634e:	fffff097          	auipc	ra,0xfffff
    80006352:	884080e7          	jalr	-1916(ra) # 80004bd2 <end_op>
  return 0;
    80006356:	4501                	li	a0,0
    80006358:	a031                	j	80006364 <sys_mknod+0x80>
    end_op();
    8000635a:	fffff097          	auipc	ra,0xfffff
    8000635e:	878080e7          	jalr	-1928(ra) # 80004bd2 <end_op>
    return -1;
    80006362:	557d                	li	a0,-1
}
    80006364:	60ea                	ld	ra,152(sp)
    80006366:	644a                	ld	s0,144(sp)
    80006368:	610d                	addi	sp,sp,160
    8000636a:	8082                	ret

000000008000636c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000636c:	7135                	addi	sp,sp,-160
    8000636e:	ed06                	sd	ra,152(sp)
    80006370:	e922                	sd	s0,144(sp)
    80006372:	e526                	sd	s1,136(sp)
    80006374:	e14a                	sd	s2,128(sp)
    80006376:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006378:	ffffc097          	auipc	ra,0xffffc
    8000637c:	bd6080e7          	jalr	-1066(ra) # 80001f4e <myproc>
    80006380:	892a                	mv	s2,a0
  
  begin_op();
    80006382:	ffffe097          	auipc	ra,0xffffe
    80006386:	7d0080e7          	jalr	2000(ra) # 80004b52 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000638a:	08000613          	li	a2,128
    8000638e:	f6040593          	addi	a1,s0,-160
    80006392:	4501                	li	a0,0
    80006394:	ffffd097          	auipc	ra,0xffffd
    80006398:	242080e7          	jalr	578(ra) # 800035d6 <argstr>
    8000639c:	04054b63          	bltz	a0,800063f2 <sys_chdir+0x86>
    800063a0:	f6040513          	addi	a0,s0,-160
    800063a4:	ffffe097          	auipc	ra,0xffffe
    800063a8:	592080e7          	jalr	1426(ra) # 80004936 <namei>
    800063ac:	84aa                	mv	s1,a0
    800063ae:	c131                	beqz	a0,800063f2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800063b0:	ffffe097          	auipc	ra,0xffffe
    800063b4:	dd0080e7          	jalr	-560(ra) # 80004180 <ilock>
  if(ip->type != T_DIR){
    800063b8:	04449703          	lh	a4,68(s1)
    800063bc:	4785                	li	a5,1
    800063be:	04f71063          	bne	a4,a5,800063fe <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800063c2:	8526                	mv	a0,s1
    800063c4:	ffffe097          	auipc	ra,0xffffe
    800063c8:	e7e080e7          	jalr	-386(ra) # 80004242 <iunlock>
  iput(p->cwd);
    800063cc:	15093503          	ld	a0,336(s2)
    800063d0:	ffffe097          	auipc	ra,0xffffe
    800063d4:	f6a080e7          	jalr	-150(ra) # 8000433a <iput>
  end_op();
    800063d8:	ffffe097          	auipc	ra,0xffffe
    800063dc:	7fa080e7          	jalr	2042(ra) # 80004bd2 <end_op>
  p->cwd = ip;
    800063e0:	14993823          	sd	s1,336(s2)
  return 0;
    800063e4:	4501                	li	a0,0
}
    800063e6:	60ea                	ld	ra,152(sp)
    800063e8:	644a                	ld	s0,144(sp)
    800063ea:	64aa                	ld	s1,136(sp)
    800063ec:	690a                	ld	s2,128(sp)
    800063ee:	610d                	addi	sp,sp,160
    800063f0:	8082                	ret
    end_op();
    800063f2:	ffffe097          	auipc	ra,0xffffe
    800063f6:	7e0080e7          	jalr	2016(ra) # 80004bd2 <end_op>
    return -1;
    800063fa:	557d                	li	a0,-1
    800063fc:	b7ed                	j	800063e6 <sys_chdir+0x7a>
    iunlockput(ip);
    800063fe:	8526                	mv	a0,s1
    80006400:	ffffe097          	auipc	ra,0xffffe
    80006404:	fe2080e7          	jalr	-30(ra) # 800043e2 <iunlockput>
    end_op();
    80006408:	ffffe097          	auipc	ra,0xffffe
    8000640c:	7ca080e7          	jalr	1994(ra) # 80004bd2 <end_op>
    return -1;
    80006410:	557d                	li	a0,-1
    80006412:	bfd1                	j	800063e6 <sys_chdir+0x7a>

0000000080006414 <sys_exec>:

uint64
sys_exec(void)
{
    80006414:	7145                	addi	sp,sp,-464
    80006416:	e786                	sd	ra,456(sp)
    80006418:	e3a2                	sd	s0,448(sp)
    8000641a:	ff26                	sd	s1,440(sp)
    8000641c:	fb4a                	sd	s2,432(sp)
    8000641e:	f74e                	sd	s3,424(sp)
    80006420:	f352                	sd	s4,416(sp)
    80006422:	ef56                	sd	s5,408(sp)
    80006424:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006426:	08000613          	li	a2,128
    8000642a:	f4040593          	addi	a1,s0,-192
    8000642e:	4501                	li	a0,0
    80006430:	ffffd097          	auipc	ra,0xffffd
    80006434:	1a6080e7          	jalr	422(ra) # 800035d6 <argstr>
    return -1;
    80006438:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000643a:	0c054a63          	bltz	a0,8000650e <sys_exec+0xfa>
    8000643e:	e3840593          	addi	a1,s0,-456
    80006442:	4505                	li	a0,1
    80006444:	ffffd097          	auipc	ra,0xffffd
    80006448:	170080e7          	jalr	368(ra) # 800035b4 <argaddr>
    8000644c:	0c054163          	bltz	a0,8000650e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006450:	10000613          	li	a2,256
    80006454:	4581                	li	a1,0
    80006456:	e4040513          	addi	a0,s0,-448
    8000645a:	ffffb097          	auipc	ra,0xffffb
    8000645e:	886080e7          	jalr	-1914(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006462:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006466:	89a6                	mv	s3,s1
    80006468:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000646a:	02000a13          	li	s4,32
    8000646e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006472:	00391513          	slli	a0,s2,0x3
    80006476:	e3040593          	addi	a1,s0,-464
    8000647a:	e3843783          	ld	a5,-456(s0)
    8000647e:	953e                	add	a0,a0,a5
    80006480:	ffffd097          	auipc	ra,0xffffd
    80006484:	078080e7          	jalr	120(ra) # 800034f8 <fetchaddr>
    80006488:	02054a63          	bltz	a0,800064bc <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000648c:	e3043783          	ld	a5,-464(s0)
    80006490:	c3b9                	beqz	a5,800064d6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006492:	ffffa097          	auipc	ra,0xffffa
    80006496:	662080e7          	jalr	1634(ra) # 80000af4 <kalloc>
    8000649a:	85aa                	mv	a1,a0
    8000649c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800064a0:	cd11                	beqz	a0,800064bc <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800064a2:	6605                	lui	a2,0x1
    800064a4:	e3043503          	ld	a0,-464(s0)
    800064a8:	ffffd097          	auipc	ra,0xffffd
    800064ac:	0a2080e7          	jalr	162(ra) # 8000354a <fetchstr>
    800064b0:	00054663          	bltz	a0,800064bc <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800064b4:	0905                	addi	s2,s2,1
    800064b6:	09a1                	addi	s3,s3,8
    800064b8:	fb491be3          	bne	s2,s4,8000646e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800064bc:	10048913          	addi	s2,s1,256
    800064c0:	6088                	ld	a0,0(s1)
    800064c2:	c529                	beqz	a0,8000650c <sys_exec+0xf8>
    kfree(argv[i]);
    800064c4:	ffffa097          	auipc	ra,0xffffa
    800064c8:	534080e7          	jalr	1332(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800064cc:	04a1                	addi	s1,s1,8
    800064ce:	ff2499e3          	bne	s1,s2,800064c0 <sys_exec+0xac>
  return -1;
    800064d2:	597d                	li	s2,-1
    800064d4:	a82d                	j	8000650e <sys_exec+0xfa>
      argv[i] = 0;
    800064d6:	0a8e                	slli	s5,s5,0x3
    800064d8:	fc040793          	addi	a5,s0,-64
    800064dc:	9abe                	add	s5,s5,a5
    800064de:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800064e2:	e4040593          	addi	a1,s0,-448
    800064e6:	f4040513          	addi	a0,s0,-192
    800064ea:	fffff097          	auipc	ra,0xfffff
    800064ee:	194080e7          	jalr	404(ra) # 8000567e <exec>
    800064f2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800064f4:	10048993          	addi	s3,s1,256
    800064f8:	6088                	ld	a0,0(s1)
    800064fa:	c911                	beqz	a0,8000650e <sys_exec+0xfa>
    kfree(argv[i]);
    800064fc:	ffffa097          	auipc	ra,0xffffa
    80006500:	4fc080e7          	jalr	1276(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006504:	04a1                	addi	s1,s1,8
    80006506:	ff3499e3          	bne	s1,s3,800064f8 <sys_exec+0xe4>
    8000650a:	a011                	j	8000650e <sys_exec+0xfa>
  return -1;
    8000650c:	597d                	li	s2,-1
}
    8000650e:	854a                	mv	a0,s2
    80006510:	60be                	ld	ra,456(sp)
    80006512:	641e                	ld	s0,448(sp)
    80006514:	74fa                	ld	s1,440(sp)
    80006516:	795a                	ld	s2,432(sp)
    80006518:	79ba                	ld	s3,424(sp)
    8000651a:	7a1a                	ld	s4,416(sp)
    8000651c:	6afa                	ld	s5,408(sp)
    8000651e:	6179                	addi	sp,sp,464
    80006520:	8082                	ret

0000000080006522 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006522:	7139                	addi	sp,sp,-64
    80006524:	fc06                	sd	ra,56(sp)
    80006526:	f822                	sd	s0,48(sp)
    80006528:	f426                	sd	s1,40(sp)
    8000652a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000652c:	ffffc097          	auipc	ra,0xffffc
    80006530:	a22080e7          	jalr	-1502(ra) # 80001f4e <myproc>
    80006534:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006536:	fd840593          	addi	a1,s0,-40
    8000653a:	4501                	li	a0,0
    8000653c:	ffffd097          	auipc	ra,0xffffd
    80006540:	078080e7          	jalr	120(ra) # 800035b4 <argaddr>
    return -1;
    80006544:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006546:	0e054063          	bltz	a0,80006626 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000654a:	fc840593          	addi	a1,s0,-56
    8000654e:	fd040513          	addi	a0,s0,-48
    80006552:	fffff097          	auipc	ra,0xfffff
    80006556:	dfc080e7          	jalr	-516(ra) # 8000534e <pipealloc>
    return -1;
    8000655a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000655c:	0c054563          	bltz	a0,80006626 <sys_pipe+0x104>
  fd0 = -1;
    80006560:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006564:	fd043503          	ld	a0,-48(s0)
    80006568:	fffff097          	auipc	ra,0xfffff
    8000656c:	508080e7          	jalr	1288(ra) # 80005a70 <fdalloc>
    80006570:	fca42223          	sw	a0,-60(s0)
    80006574:	08054c63          	bltz	a0,8000660c <sys_pipe+0xea>
    80006578:	fc843503          	ld	a0,-56(s0)
    8000657c:	fffff097          	auipc	ra,0xfffff
    80006580:	4f4080e7          	jalr	1268(ra) # 80005a70 <fdalloc>
    80006584:	fca42023          	sw	a0,-64(s0)
    80006588:	06054863          	bltz	a0,800065f8 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000658c:	4691                	li	a3,4
    8000658e:	fc440613          	addi	a2,s0,-60
    80006592:	fd843583          	ld	a1,-40(s0)
    80006596:	68a8                	ld	a0,80(s1)
    80006598:	ffffb097          	auipc	ra,0xffffb
    8000659c:	0da080e7          	jalr	218(ra) # 80001672 <copyout>
    800065a0:	02054063          	bltz	a0,800065c0 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800065a4:	4691                	li	a3,4
    800065a6:	fc040613          	addi	a2,s0,-64
    800065aa:	fd843583          	ld	a1,-40(s0)
    800065ae:	0591                	addi	a1,a1,4
    800065b0:	68a8                	ld	a0,80(s1)
    800065b2:	ffffb097          	auipc	ra,0xffffb
    800065b6:	0c0080e7          	jalr	192(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800065ba:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800065bc:	06055563          	bgez	a0,80006626 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800065c0:	fc442783          	lw	a5,-60(s0)
    800065c4:	07e9                	addi	a5,a5,26
    800065c6:	078e                	slli	a5,a5,0x3
    800065c8:	97a6                	add	a5,a5,s1
    800065ca:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800065ce:	fc042503          	lw	a0,-64(s0)
    800065d2:	0569                	addi	a0,a0,26
    800065d4:	050e                	slli	a0,a0,0x3
    800065d6:	9526                	add	a0,a0,s1
    800065d8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800065dc:	fd043503          	ld	a0,-48(s0)
    800065e0:	fffff097          	auipc	ra,0xfffff
    800065e4:	a3e080e7          	jalr	-1474(ra) # 8000501e <fileclose>
    fileclose(wf);
    800065e8:	fc843503          	ld	a0,-56(s0)
    800065ec:	fffff097          	auipc	ra,0xfffff
    800065f0:	a32080e7          	jalr	-1486(ra) # 8000501e <fileclose>
    return -1;
    800065f4:	57fd                	li	a5,-1
    800065f6:	a805                	j	80006626 <sys_pipe+0x104>
    if(fd0 >= 0)
    800065f8:	fc442783          	lw	a5,-60(s0)
    800065fc:	0007c863          	bltz	a5,8000660c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006600:	01a78513          	addi	a0,a5,26
    80006604:	050e                	slli	a0,a0,0x3
    80006606:	9526                	add	a0,a0,s1
    80006608:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000660c:	fd043503          	ld	a0,-48(s0)
    80006610:	fffff097          	auipc	ra,0xfffff
    80006614:	a0e080e7          	jalr	-1522(ra) # 8000501e <fileclose>
    fileclose(wf);
    80006618:	fc843503          	ld	a0,-56(s0)
    8000661c:	fffff097          	auipc	ra,0xfffff
    80006620:	a02080e7          	jalr	-1534(ra) # 8000501e <fileclose>
    return -1;
    80006624:	57fd                	li	a5,-1
}
    80006626:	853e                	mv	a0,a5
    80006628:	70e2                	ld	ra,56(sp)
    8000662a:	7442                	ld	s0,48(sp)
    8000662c:	74a2                	ld	s1,40(sp)
    8000662e:	6121                	addi	sp,sp,64
    80006630:	8082                	ret
	...

0000000080006640 <kernelvec>:
    80006640:	7111                	addi	sp,sp,-256
    80006642:	e006                	sd	ra,0(sp)
    80006644:	e40a                	sd	sp,8(sp)
    80006646:	e80e                	sd	gp,16(sp)
    80006648:	ec12                	sd	tp,24(sp)
    8000664a:	f016                	sd	t0,32(sp)
    8000664c:	f41a                	sd	t1,40(sp)
    8000664e:	f81e                	sd	t2,48(sp)
    80006650:	fc22                	sd	s0,56(sp)
    80006652:	e0a6                	sd	s1,64(sp)
    80006654:	e4aa                	sd	a0,72(sp)
    80006656:	e8ae                	sd	a1,80(sp)
    80006658:	ecb2                	sd	a2,88(sp)
    8000665a:	f0b6                	sd	a3,96(sp)
    8000665c:	f4ba                	sd	a4,104(sp)
    8000665e:	f8be                	sd	a5,112(sp)
    80006660:	fcc2                	sd	a6,120(sp)
    80006662:	e146                	sd	a7,128(sp)
    80006664:	e54a                	sd	s2,136(sp)
    80006666:	e94e                	sd	s3,144(sp)
    80006668:	ed52                	sd	s4,152(sp)
    8000666a:	f156                	sd	s5,160(sp)
    8000666c:	f55a                	sd	s6,168(sp)
    8000666e:	f95e                	sd	s7,176(sp)
    80006670:	fd62                	sd	s8,184(sp)
    80006672:	e1e6                	sd	s9,192(sp)
    80006674:	e5ea                	sd	s10,200(sp)
    80006676:	e9ee                	sd	s11,208(sp)
    80006678:	edf2                	sd	t3,216(sp)
    8000667a:	f1f6                	sd	t4,224(sp)
    8000667c:	f5fa                	sd	t5,232(sp)
    8000667e:	f9fe                	sd	t6,240(sp)
    80006680:	d45fc0ef          	jal	ra,800033c4 <kerneltrap>
    80006684:	6082                	ld	ra,0(sp)
    80006686:	6122                	ld	sp,8(sp)
    80006688:	61c2                	ld	gp,16(sp)
    8000668a:	7282                	ld	t0,32(sp)
    8000668c:	7322                	ld	t1,40(sp)
    8000668e:	73c2                	ld	t2,48(sp)
    80006690:	7462                	ld	s0,56(sp)
    80006692:	6486                	ld	s1,64(sp)
    80006694:	6526                	ld	a0,72(sp)
    80006696:	65c6                	ld	a1,80(sp)
    80006698:	6666                	ld	a2,88(sp)
    8000669a:	7686                	ld	a3,96(sp)
    8000669c:	7726                	ld	a4,104(sp)
    8000669e:	77c6                	ld	a5,112(sp)
    800066a0:	7866                	ld	a6,120(sp)
    800066a2:	688a                	ld	a7,128(sp)
    800066a4:	692a                	ld	s2,136(sp)
    800066a6:	69ca                	ld	s3,144(sp)
    800066a8:	6a6a                	ld	s4,152(sp)
    800066aa:	7a8a                	ld	s5,160(sp)
    800066ac:	7b2a                	ld	s6,168(sp)
    800066ae:	7bca                	ld	s7,176(sp)
    800066b0:	7c6a                	ld	s8,184(sp)
    800066b2:	6c8e                	ld	s9,192(sp)
    800066b4:	6d2e                	ld	s10,200(sp)
    800066b6:	6dce                	ld	s11,208(sp)
    800066b8:	6e6e                	ld	t3,216(sp)
    800066ba:	7e8e                	ld	t4,224(sp)
    800066bc:	7f2e                	ld	t5,232(sp)
    800066be:	7fce                	ld	t6,240(sp)
    800066c0:	6111                	addi	sp,sp,256
    800066c2:	10200073          	sret
    800066c6:	00000013          	nop
    800066ca:	00000013          	nop
    800066ce:	0001                	nop

00000000800066d0 <timervec>:
    800066d0:	34051573          	csrrw	a0,mscratch,a0
    800066d4:	e10c                	sd	a1,0(a0)
    800066d6:	e510                	sd	a2,8(a0)
    800066d8:	e914                	sd	a3,16(a0)
    800066da:	6d0c                	ld	a1,24(a0)
    800066dc:	7110                	ld	a2,32(a0)
    800066de:	6194                	ld	a3,0(a1)
    800066e0:	96b2                	add	a3,a3,a2
    800066e2:	e194                	sd	a3,0(a1)
    800066e4:	4589                	li	a1,2
    800066e6:	14459073          	csrw	sip,a1
    800066ea:	6914                	ld	a3,16(a0)
    800066ec:	6510                	ld	a2,8(a0)
    800066ee:	610c                	ld	a1,0(a0)
    800066f0:	34051573          	csrrw	a0,mscratch,a0
    800066f4:	30200073          	mret
	...

00000000800066fa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800066fa:	1141                	addi	sp,sp,-16
    800066fc:	e422                	sd	s0,8(sp)
    800066fe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006700:	0c0007b7          	lui	a5,0xc000
    80006704:	4705                	li	a4,1
    80006706:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006708:	c3d8                	sw	a4,4(a5)
}
    8000670a:	6422                	ld	s0,8(sp)
    8000670c:	0141                	addi	sp,sp,16
    8000670e:	8082                	ret

0000000080006710 <plicinithart>:

void
plicinithart(void)
{
    80006710:	1141                	addi	sp,sp,-16
    80006712:	e406                	sd	ra,8(sp)
    80006714:	e022                	sd	s0,0(sp)
    80006716:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006718:	ffffc097          	auipc	ra,0xffffc
    8000671c:	804080e7          	jalr	-2044(ra) # 80001f1c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006720:	0085171b          	slliw	a4,a0,0x8
    80006724:	0c0027b7          	lui	a5,0xc002
    80006728:	97ba                	add	a5,a5,a4
    8000672a:	40200713          	li	a4,1026
    8000672e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006732:	00d5151b          	slliw	a0,a0,0xd
    80006736:	0c2017b7          	lui	a5,0xc201
    8000673a:	953e                	add	a0,a0,a5
    8000673c:	00052023          	sw	zero,0(a0)
}
    80006740:	60a2                	ld	ra,8(sp)
    80006742:	6402                	ld	s0,0(sp)
    80006744:	0141                	addi	sp,sp,16
    80006746:	8082                	ret

0000000080006748 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006748:	1141                	addi	sp,sp,-16
    8000674a:	e406                	sd	ra,8(sp)
    8000674c:	e022                	sd	s0,0(sp)
    8000674e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006750:	ffffb097          	auipc	ra,0xffffb
    80006754:	7cc080e7          	jalr	1996(ra) # 80001f1c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006758:	00d5179b          	slliw	a5,a0,0xd
    8000675c:	0c201537          	lui	a0,0xc201
    80006760:	953e                	add	a0,a0,a5
  return irq;
}
    80006762:	4148                	lw	a0,4(a0)
    80006764:	60a2                	ld	ra,8(sp)
    80006766:	6402                	ld	s0,0(sp)
    80006768:	0141                	addi	sp,sp,16
    8000676a:	8082                	ret

000000008000676c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000676c:	1101                	addi	sp,sp,-32
    8000676e:	ec06                	sd	ra,24(sp)
    80006770:	e822                	sd	s0,16(sp)
    80006772:	e426                	sd	s1,8(sp)
    80006774:	1000                	addi	s0,sp,32
    80006776:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006778:	ffffb097          	auipc	ra,0xffffb
    8000677c:	7a4080e7          	jalr	1956(ra) # 80001f1c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006780:	00d5151b          	slliw	a0,a0,0xd
    80006784:	0c2017b7          	lui	a5,0xc201
    80006788:	97aa                	add	a5,a5,a0
    8000678a:	c3c4                	sw	s1,4(a5)
}
    8000678c:	60e2                	ld	ra,24(sp)
    8000678e:	6442                	ld	s0,16(sp)
    80006790:	64a2                	ld	s1,8(sp)
    80006792:	6105                	addi	sp,sp,32
    80006794:	8082                	ret

0000000080006796 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006796:	1141                	addi	sp,sp,-16
    80006798:	e406                	sd	ra,8(sp)
    8000679a:	e022                	sd	s0,0(sp)
    8000679c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000679e:	479d                	li	a5,7
    800067a0:	06a7c963          	blt	a5,a0,80006812 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800067a4:	0001d797          	auipc	a5,0x1d
    800067a8:	85c78793          	addi	a5,a5,-1956 # 80023000 <disk>
    800067ac:	00a78733          	add	a4,a5,a0
    800067b0:	6789                	lui	a5,0x2
    800067b2:	97ba                	add	a5,a5,a4
    800067b4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800067b8:	e7ad                	bnez	a5,80006822 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800067ba:	00451793          	slli	a5,a0,0x4
    800067be:	0001f717          	auipc	a4,0x1f
    800067c2:	84270713          	addi	a4,a4,-1982 # 80025000 <disk+0x2000>
    800067c6:	6314                	ld	a3,0(a4)
    800067c8:	96be                	add	a3,a3,a5
    800067ca:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800067ce:	6314                	ld	a3,0(a4)
    800067d0:	96be                	add	a3,a3,a5
    800067d2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800067d6:	6314                	ld	a3,0(a4)
    800067d8:	96be                	add	a3,a3,a5
    800067da:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800067de:	6318                	ld	a4,0(a4)
    800067e0:	97ba                	add	a5,a5,a4
    800067e2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800067e6:	0001d797          	auipc	a5,0x1d
    800067ea:	81a78793          	addi	a5,a5,-2022 # 80023000 <disk>
    800067ee:	97aa                	add	a5,a5,a0
    800067f0:	6509                	lui	a0,0x2
    800067f2:	953e                	add	a0,a0,a5
    800067f4:	4785                	li	a5,1
    800067f6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800067fa:	0001f517          	auipc	a0,0x1f
    800067fe:	81e50513          	addi	a0,a0,-2018 # 80025018 <disk+0x2018>
    80006802:	ffffc097          	auipc	ra,0xffffc
    80006806:	40c080e7          	jalr	1036(ra) # 80002c0e <wakeup>
}
    8000680a:	60a2                	ld	ra,8(sp)
    8000680c:	6402                	ld	s0,0(sp)
    8000680e:	0141                	addi	sp,sp,16
    80006810:	8082                	ret
    panic("free_desc 1");
    80006812:	00002517          	auipc	a0,0x2
    80006816:	2ce50513          	addi	a0,a0,718 # 80008ae0 <syscalls+0x338>
    8000681a:	ffffa097          	auipc	ra,0xffffa
    8000681e:	d24080e7          	jalr	-732(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006822:	00002517          	auipc	a0,0x2
    80006826:	2ce50513          	addi	a0,a0,718 # 80008af0 <syscalls+0x348>
    8000682a:	ffffa097          	auipc	ra,0xffffa
    8000682e:	d14080e7          	jalr	-748(ra) # 8000053e <panic>

0000000080006832 <virtio_disk_init>:
{
    80006832:	1101                	addi	sp,sp,-32
    80006834:	ec06                	sd	ra,24(sp)
    80006836:	e822                	sd	s0,16(sp)
    80006838:	e426                	sd	s1,8(sp)
    8000683a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000683c:	00002597          	auipc	a1,0x2
    80006840:	2c458593          	addi	a1,a1,708 # 80008b00 <syscalls+0x358>
    80006844:	0001f517          	auipc	a0,0x1f
    80006848:	8e450513          	addi	a0,a0,-1820 # 80025128 <disk+0x2128>
    8000684c:	ffffa097          	auipc	ra,0xffffa
    80006850:	308080e7          	jalr	776(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006854:	100017b7          	lui	a5,0x10001
    80006858:	4398                	lw	a4,0(a5)
    8000685a:	2701                	sext.w	a4,a4
    8000685c:	747277b7          	lui	a5,0x74727
    80006860:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006864:	0ef71163          	bne	a4,a5,80006946 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006868:	100017b7          	lui	a5,0x10001
    8000686c:	43dc                	lw	a5,4(a5)
    8000686e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006870:	4705                	li	a4,1
    80006872:	0ce79a63          	bne	a5,a4,80006946 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006876:	100017b7          	lui	a5,0x10001
    8000687a:	479c                	lw	a5,8(a5)
    8000687c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000687e:	4709                	li	a4,2
    80006880:	0ce79363          	bne	a5,a4,80006946 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006884:	100017b7          	lui	a5,0x10001
    80006888:	47d8                	lw	a4,12(a5)
    8000688a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000688c:	554d47b7          	lui	a5,0x554d4
    80006890:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006894:	0af71963          	bne	a4,a5,80006946 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006898:	100017b7          	lui	a5,0x10001
    8000689c:	4705                	li	a4,1
    8000689e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800068a0:	470d                	li	a4,3
    800068a2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800068a4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800068a6:	c7ffe737          	lui	a4,0xc7ffe
    800068aa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800068ae:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800068b0:	2701                	sext.w	a4,a4
    800068b2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800068b4:	472d                	li	a4,11
    800068b6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800068b8:	473d                	li	a4,15
    800068ba:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800068bc:	6705                	lui	a4,0x1
    800068be:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800068c0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800068c4:	5bdc                	lw	a5,52(a5)
    800068c6:	2781                	sext.w	a5,a5
  if(max == 0)
    800068c8:	c7d9                	beqz	a5,80006956 <virtio_disk_init+0x124>
  if(max < NUM)
    800068ca:	471d                	li	a4,7
    800068cc:	08f77d63          	bgeu	a4,a5,80006966 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800068d0:	100014b7          	lui	s1,0x10001
    800068d4:	47a1                	li	a5,8
    800068d6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800068d8:	6609                	lui	a2,0x2
    800068da:	4581                	li	a1,0
    800068dc:	0001c517          	auipc	a0,0x1c
    800068e0:	72450513          	addi	a0,a0,1828 # 80023000 <disk>
    800068e4:	ffffa097          	auipc	ra,0xffffa
    800068e8:	3fc080e7          	jalr	1020(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800068ec:	0001c717          	auipc	a4,0x1c
    800068f0:	71470713          	addi	a4,a4,1812 # 80023000 <disk>
    800068f4:	00c75793          	srli	a5,a4,0xc
    800068f8:	2781                	sext.w	a5,a5
    800068fa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800068fc:	0001e797          	auipc	a5,0x1e
    80006900:	70478793          	addi	a5,a5,1796 # 80025000 <disk+0x2000>
    80006904:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006906:	0001c717          	auipc	a4,0x1c
    8000690a:	77a70713          	addi	a4,a4,1914 # 80023080 <disk+0x80>
    8000690e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006910:	0001d717          	auipc	a4,0x1d
    80006914:	6f070713          	addi	a4,a4,1776 # 80024000 <disk+0x1000>
    80006918:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000691a:	4705                	li	a4,1
    8000691c:	00e78c23          	sb	a4,24(a5)
    80006920:	00e78ca3          	sb	a4,25(a5)
    80006924:	00e78d23          	sb	a4,26(a5)
    80006928:	00e78da3          	sb	a4,27(a5)
    8000692c:	00e78e23          	sb	a4,28(a5)
    80006930:	00e78ea3          	sb	a4,29(a5)
    80006934:	00e78f23          	sb	a4,30(a5)
    80006938:	00e78fa3          	sb	a4,31(a5)
}
    8000693c:	60e2                	ld	ra,24(sp)
    8000693e:	6442                	ld	s0,16(sp)
    80006940:	64a2                	ld	s1,8(sp)
    80006942:	6105                	addi	sp,sp,32
    80006944:	8082                	ret
    panic("could not find virtio disk");
    80006946:	00002517          	auipc	a0,0x2
    8000694a:	1ca50513          	addi	a0,a0,458 # 80008b10 <syscalls+0x368>
    8000694e:	ffffa097          	auipc	ra,0xffffa
    80006952:	bf0080e7          	jalr	-1040(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006956:	00002517          	auipc	a0,0x2
    8000695a:	1da50513          	addi	a0,a0,474 # 80008b30 <syscalls+0x388>
    8000695e:	ffffa097          	auipc	ra,0xffffa
    80006962:	be0080e7          	jalr	-1056(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006966:	00002517          	auipc	a0,0x2
    8000696a:	1ea50513          	addi	a0,a0,490 # 80008b50 <syscalls+0x3a8>
    8000696e:	ffffa097          	auipc	ra,0xffffa
    80006972:	bd0080e7          	jalr	-1072(ra) # 8000053e <panic>

0000000080006976 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006976:	7159                	addi	sp,sp,-112
    80006978:	f486                	sd	ra,104(sp)
    8000697a:	f0a2                	sd	s0,96(sp)
    8000697c:	eca6                	sd	s1,88(sp)
    8000697e:	e8ca                	sd	s2,80(sp)
    80006980:	e4ce                	sd	s3,72(sp)
    80006982:	e0d2                	sd	s4,64(sp)
    80006984:	fc56                	sd	s5,56(sp)
    80006986:	f85a                	sd	s6,48(sp)
    80006988:	f45e                	sd	s7,40(sp)
    8000698a:	f062                	sd	s8,32(sp)
    8000698c:	ec66                	sd	s9,24(sp)
    8000698e:	e86a                	sd	s10,16(sp)
    80006990:	1880                	addi	s0,sp,112
    80006992:	892a                	mv	s2,a0
    80006994:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006996:	00c52c83          	lw	s9,12(a0)
    8000699a:	001c9c9b          	slliw	s9,s9,0x1
    8000699e:	1c82                	slli	s9,s9,0x20
    800069a0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800069a4:	0001e517          	auipc	a0,0x1e
    800069a8:	78450513          	addi	a0,a0,1924 # 80025128 <disk+0x2128>
    800069ac:	ffffa097          	auipc	ra,0xffffa
    800069b0:	238080e7          	jalr	568(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800069b4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800069b6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800069b8:	0001cb97          	auipc	s7,0x1c
    800069bc:	648b8b93          	addi	s7,s7,1608 # 80023000 <disk>
    800069c0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800069c2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800069c4:	8a4e                	mv	s4,s3
    800069c6:	a051                	j	80006a4a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800069c8:	00fb86b3          	add	a3,s7,a5
    800069cc:	96da                	add	a3,a3,s6
    800069ce:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800069d2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800069d4:	0207c563          	bltz	a5,800069fe <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800069d8:	2485                	addiw	s1,s1,1
    800069da:	0711                	addi	a4,a4,4
    800069dc:	25548063          	beq	s1,s5,80006c1c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800069e0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800069e2:	0001e697          	auipc	a3,0x1e
    800069e6:	63668693          	addi	a3,a3,1590 # 80025018 <disk+0x2018>
    800069ea:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800069ec:	0006c583          	lbu	a1,0(a3)
    800069f0:	fde1                	bnez	a1,800069c8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800069f2:	2785                	addiw	a5,a5,1
    800069f4:	0685                	addi	a3,a3,1
    800069f6:	ff879be3          	bne	a5,s8,800069ec <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800069fa:	57fd                	li	a5,-1
    800069fc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800069fe:	02905a63          	blez	s1,80006a32 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006a02:	f9042503          	lw	a0,-112(s0)
    80006a06:	00000097          	auipc	ra,0x0
    80006a0a:	d90080e7          	jalr	-624(ra) # 80006796 <free_desc>
      for(int j = 0; j < i; j++)
    80006a0e:	4785                	li	a5,1
    80006a10:	0297d163          	bge	a5,s1,80006a32 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006a14:	f9442503          	lw	a0,-108(s0)
    80006a18:	00000097          	auipc	ra,0x0
    80006a1c:	d7e080e7          	jalr	-642(ra) # 80006796 <free_desc>
      for(int j = 0; j < i; j++)
    80006a20:	4789                	li	a5,2
    80006a22:	0097d863          	bge	a5,s1,80006a32 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006a26:	f9842503          	lw	a0,-104(s0)
    80006a2a:	00000097          	auipc	ra,0x0
    80006a2e:	d6c080e7          	jalr	-660(ra) # 80006796 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006a32:	0001e597          	auipc	a1,0x1e
    80006a36:	6f658593          	addi	a1,a1,1782 # 80025128 <disk+0x2128>
    80006a3a:	0001e517          	auipc	a0,0x1e
    80006a3e:	5de50513          	addi	a0,a0,1502 # 80025018 <disk+0x2018>
    80006a42:	ffffc097          	auipc	ra,0xffffc
    80006a46:	b46080e7          	jalr	-1210(ra) # 80002588 <sleep>
  for(int i = 0; i < 3; i++){
    80006a4a:	f9040713          	addi	a4,s0,-112
    80006a4e:	84ce                	mv	s1,s3
    80006a50:	bf41                	j	800069e0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006a52:	20058713          	addi	a4,a1,512
    80006a56:	00471693          	slli	a3,a4,0x4
    80006a5a:	0001c717          	auipc	a4,0x1c
    80006a5e:	5a670713          	addi	a4,a4,1446 # 80023000 <disk>
    80006a62:	9736                	add	a4,a4,a3
    80006a64:	4685                	li	a3,1
    80006a66:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006a6a:	20058713          	addi	a4,a1,512
    80006a6e:	00471693          	slli	a3,a4,0x4
    80006a72:	0001c717          	auipc	a4,0x1c
    80006a76:	58e70713          	addi	a4,a4,1422 # 80023000 <disk>
    80006a7a:	9736                	add	a4,a4,a3
    80006a7c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006a80:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006a84:	7679                	lui	a2,0xffffe
    80006a86:	963e                	add	a2,a2,a5
    80006a88:	0001e697          	auipc	a3,0x1e
    80006a8c:	57868693          	addi	a3,a3,1400 # 80025000 <disk+0x2000>
    80006a90:	6298                	ld	a4,0(a3)
    80006a92:	9732                	add	a4,a4,a2
    80006a94:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006a96:	6298                	ld	a4,0(a3)
    80006a98:	9732                	add	a4,a4,a2
    80006a9a:	4541                	li	a0,16
    80006a9c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006a9e:	6298                	ld	a4,0(a3)
    80006aa0:	9732                	add	a4,a4,a2
    80006aa2:	4505                	li	a0,1
    80006aa4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006aa8:	f9442703          	lw	a4,-108(s0)
    80006aac:	6288                	ld	a0,0(a3)
    80006aae:	962a                	add	a2,a2,a0
    80006ab0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006ab4:	0712                	slli	a4,a4,0x4
    80006ab6:	6290                	ld	a2,0(a3)
    80006ab8:	963a                	add	a2,a2,a4
    80006aba:	05890513          	addi	a0,s2,88
    80006abe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006ac0:	6294                	ld	a3,0(a3)
    80006ac2:	96ba                	add	a3,a3,a4
    80006ac4:	40000613          	li	a2,1024
    80006ac8:	c690                	sw	a2,8(a3)
  if(write)
    80006aca:	140d0063          	beqz	s10,80006c0a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006ace:	0001e697          	auipc	a3,0x1e
    80006ad2:	5326b683          	ld	a3,1330(a3) # 80025000 <disk+0x2000>
    80006ad6:	96ba                	add	a3,a3,a4
    80006ad8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006adc:	0001c817          	auipc	a6,0x1c
    80006ae0:	52480813          	addi	a6,a6,1316 # 80023000 <disk>
    80006ae4:	0001e517          	auipc	a0,0x1e
    80006ae8:	51c50513          	addi	a0,a0,1308 # 80025000 <disk+0x2000>
    80006aec:	6114                	ld	a3,0(a0)
    80006aee:	96ba                	add	a3,a3,a4
    80006af0:	00c6d603          	lhu	a2,12(a3)
    80006af4:	00166613          	ori	a2,a2,1
    80006af8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006afc:	f9842683          	lw	a3,-104(s0)
    80006b00:	6110                	ld	a2,0(a0)
    80006b02:	9732                	add	a4,a4,a2
    80006b04:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006b08:	20058613          	addi	a2,a1,512
    80006b0c:	0612                	slli	a2,a2,0x4
    80006b0e:	9642                	add	a2,a2,a6
    80006b10:	577d                	li	a4,-1
    80006b12:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006b16:	00469713          	slli	a4,a3,0x4
    80006b1a:	6114                	ld	a3,0(a0)
    80006b1c:	96ba                	add	a3,a3,a4
    80006b1e:	03078793          	addi	a5,a5,48
    80006b22:	97c2                	add	a5,a5,a6
    80006b24:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006b26:	611c                	ld	a5,0(a0)
    80006b28:	97ba                	add	a5,a5,a4
    80006b2a:	4685                	li	a3,1
    80006b2c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006b2e:	611c                	ld	a5,0(a0)
    80006b30:	97ba                	add	a5,a5,a4
    80006b32:	4809                	li	a6,2
    80006b34:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006b38:	611c                	ld	a5,0(a0)
    80006b3a:	973e                	add	a4,a4,a5
    80006b3c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006b40:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006b44:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006b48:	6518                	ld	a4,8(a0)
    80006b4a:	00275783          	lhu	a5,2(a4)
    80006b4e:	8b9d                	andi	a5,a5,7
    80006b50:	0786                	slli	a5,a5,0x1
    80006b52:	97ba                	add	a5,a5,a4
    80006b54:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006b58:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006b5c:	6518                	ld	a4,8(a0)
    80006b5e:	00275783          	lhu	a5,2(a4)
    80006b62:	2785                	addiw	a5,a5,1
    80006b64:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006b68:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006b6c:	100017b7          	lui	a5,0x10001
    80006b70:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006b74:	00492703          	lw	a4,4(s2)
    80006b78:	4785                	li	a5,1
    80006b7a:	02f71163          	bne	a4,a5,80006b9c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006b7e:	0001e997          	auipc	s3,0x1e
    80006b82:	5aa98993          	addi	s3,s3,1450 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006b86:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006b88:	85ce                	mv	a1,s3
    80006b8a:	854a                	mv	a0,s2
    80006b8c:	ffffc097          	auipc	ra,0xffffc
    80006b90:	9fc080e7          	jalr	-1540(ra) # 80002588 <sleep>
  while(b->disk == 1) {
    80006b94:	00492783          	lw	a5,4(s2)
    80006b98:	fe9788e3          	beq	a5,s1,80006b88 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006b9c:	f9042903          	lw	s2,-112(s0)
    80006ba0:	20090793          	addi	a5,s2,512
    80006ba4:	00479713          	slli	a4,a5,0x4
    80006ba8:	0001c797          	auipc	a5,0x1c
    80006bac:	45878793          	addi	a5,a5,1112 # 80023000 <disk>
    80006bb0:	97ba                	add	a5,a5,a4
    80006bb2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006bb6:	0001e997          	auipc	s3,0x1e
    80006bba:	44a98993          	addi	s3,s3,1098 # 80025000 <disk+0x2000>
    80006bbe:	00491713          	slli	a4,s2,0x4
    80006bc2:	0009b783          	ld	a5,0(s3)
    80006bc6:	97ba                	add	a5,a5,a4
    80006bc8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006bcc:	854a                	mv	a0,s2
    80006bce:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006bd2:	00000097          	auipc	ra,0x0
    80006bd6:	bc4080e7          	jalr	-1084(ra) # 80006796 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006bda:	8885                	andi	s1,s1,1
    80006bdc:	f0ed                	bnez	s1,80006bbe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006bde:	0001e517          	auipc	a0,0x1e
    80006be2:	54a50513          	addi	a0,a0,1354 # 80025128 <disk+0x2128>
    80006be6:	ffffa097          	auipc	ra,0xffffa
    80006bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
}
    80006bee:	70a6                	ld	ra,104(sp)
    80006bf0:	7406                	ld	s0,96(sp)
    80006bf2:	64e6                	ld	s1,88(sp)
    80006bf4:	6946                	ld	s2,80(sp)
    80006bf6:	69a6                	ld	s3,72(sp)
    80006bf8:	6a06                	ld	s4,64(sp)
    80006bfa:	7ae2                	ld	s5,56(sp)
    80006bfc:	7b42                	ld	s6,48(sp)
    80006bfe:	7ba2                	ld	s7,40(sp)
    80006c00:	7c02                	ld	s8,32(sp)
    80006c02:	6ce2                	ld	s9,24(sp)
    80006c04:	6d42                	ld	s10,16(sp)
    80006c06:	6165                	addi	sp,sp,112
    80006c08:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006c0a:	0001e697          	auipc	a3,0x1e
    80006c0e:	3f66b683          	ld	a3,1014(a3) # 80025000 <disk+0x2000>
    80006c12:	96ba                	add	a3,a3,a4
    80006c14:	4609                	li	a2,2
    80006c16:	00c69623          	sh	a2,12(a3)
    80006c1a:	b5c9                	j	80006adc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006c1c:	f9042583          	lw	a1,-112(s0)
    80006c20:	20058793          	addi	a5,a1,512
    80006c24:	0792                	slli	a5,a5,0x4
    80006c26:	0001c517          	auipc	a0,0x1c
    80006c2a:	48250513          	addi	a0,a0,1154 # 800230a8 <disk+0xa8>
    80006c2e:	953e                	add	a0,a0,a5
  if(write)
    80006c30:	e20d11e3          	bnez	s10,80006a52 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006c34:	20058713          	addi	a4,a1,512
    80006c38:	00471693          	slli	a3,a4,0x4
    80006c3c:	0001c717          	auipc	a4,0x1c
    80006c40:	3c470713          	addi	a4,a4,964 # 80023000 <disk>
    80006c44:	9736                	add	a4,a4,a3
    80006c46:	0a072423          	sw	zero,168(a4)
    80006c4a:	b505                	j	80006a6a <virtio_disk_rw+0xf4>

0000000080006c4c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006c4c:	1101                	addi	sp,sp,-32
    80006c4e:	ec06                	sd	ra,24(sp)
    80006c50:	e822                	sd	s0,16(sp)
    80006c52:	e426                	sd	s1,8(sp)
    80006c54:	e04a                	sd	s2,0(sp)
    80006c56:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006c58:	0001e517          	auipc	a0,0x1e
    80006c5c:	4d050513          	addi	a0,a0,1232 # 80025128 <disk+0x2128>
    80006c60:	ffffa097          	auipc	ra,0xffffa
    80006c64:	f84080e7          	jalr	-124(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006c68:	10001737          	lui	a4,0x10001
    80006c6c:	533c                	lw	a5,96(a4)
    80006c6e:	8b8d                	andi	a5,a5,3
    80006c70:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006c72:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006c76:	0001e797          	auipc	a5,0x1e
    80006c7a:	38a78793          	addi	a5,a5,906 # 80025000 <disk+0x2000>
    80006c7e:	6b94                	ld	a3,16(a5)
    80006c80:	0207d703          	lhu	a4,32(a5)
    80006c84:	0026d783          	lhu	a5,2(a3)
    80006c88:	06f70163          	beq	a4,a5,80006cea <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006c8c:	0001c917          	auipc	s2,0x1c
    80006c90:	37490913          	addi	s2,s2,884 # 80023000 <disk>
    80006c94:	0001e497          	auipc	s1,0x1e
    80006c98:	36c48493          	addi	s1,s1,876 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006c9c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006ca0:	6898                	ld	a4,16(s1)
    80006ca2:	0204d783          	lhu	a5,32(s1)
    80006ca6:	8b9d                	andi	a5,a5,7
    80006ca8:	078e                	slli	a5,a5,0x3
    80006caa:	97ba                	add	a5,a5,a4
    80006cac:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006cae:	20078713          	addi	a4,a5,512
    80006cb2:	0712                	slli	a4,a4,0x4
    80006cb4:	974a                	add	a4,a4,s2
    80006cb6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006cba:	e731                	bnez	a4,80006d06 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006cbc:	20078793          	addi	a5,a5,512
    80006cc0:	0792                	slli	a5,a5,0x4
    80006cc2:	97ca                	add	a5,a5,s2
    80006cc4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006cc6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006cca:	ffffc097          	auipc	ra,0xffffc
    80006cce:	f44080e7          	jalr	-188(ra) # 80002c0e <wakeup>

    disk.used_idx += 1;
    80006cd2:	0204d783          	lhu	a5,32(s1)
    80006cd6:	2785                	addiw	a5,a5,1
    80006cd8:	17c2                	slli	a5,a5,0x30
    80006cda:	93c1                	srli	a5,a5,0x30
    80006cdc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006ce0:	6898                	ld	a4,16(s1)
    80006ce2:	00275703          	lhu	a4,2(a4)
    80006ce6:	faf71be3          	bne	a4,a5,80006c9c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006cea:	0001e517          	auipc	a0,0x1e
    80006cee:	43e50513          	addi	a0,a0,1086 # 80025128 <disk+0x2128>
    80006cf2:	ffffa097          	auipc	ra,0xffffa
    80006cf6:	fa6080e7          	jalr	-90(ra) # 80000c98 <release>
}
    80006cfa:	60e2                	ld	ra,24(sp)
    80006cfc:	6442                	ld	s0,16(sp)
    80006cfe:	64a2                	ld	s1,8(sp)
    80006d00:	6902                	ld	s2,0(sp)
    80006d02:	6105                	addi	sp,sp,32
    80006d04:	8082                	ret
      panic("virtio_disk_intr status");
    80006d06:	00002517          	auipc	a0,0x2
    80006d0a:	e6a50513          	addi	a0,a0,-406 # 80008b70 <syscalls+0x3c8>
    80006d0e:	ffffa097          	auipc	ra,0xffffa
    80006d12:	830080e7          	jalr	-2000(ra) # 8000053e <panic>

0000000080006d16 <cas>:
    80006d16:	100522af          	lr.w	t0,(a0)
    80006d1a:	00b29563          	bne	t0,a1,80006d24 <fail>
    80006d1e:	18c5252f          	sc.w	a0,a2,(a0)
    80006d22:	8082                	ret

0000000080006d24 <fail>:
    80006d24:	4505                	li	a0,1
    80006d26:	8082                	ret
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
