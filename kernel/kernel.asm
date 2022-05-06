
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b5013103          	ld	sp,-1200(sp) # 80008b50 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	39c78793          	addi	a5,a5,924 # 80006400 <timervec>
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
    80000130:	6a8080e7          	jalr	1704(ra) # 800027d4 <either_copyin>
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
    800001c8:	c48080e7          	jalr	-952(ra) # 80001e0c <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	386080e7          	jalr	902(ra) # 8000255a <sleep>
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
    80000214:	56e080e7          	jalr	1390(ra) # 8000277e <either_copyout>
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
    800002f6:	538080e7          	jalr	1336(ra) # 8000282a <procdump>
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
    8000044a:	72a080e7          	jalr	1834(ra) # 80002b70 <wakeup>
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
    8000047c:	42078793          	addi	a5,a5,1056 # 80021898 <devsw>
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
    80000570:	e1450513          	addi	a0,a0,-492 # 80008380 <digits+0x340>
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
    800008a4:	2d0080e7          	jalr	720(ra) # 80002b70 <wakeup>
    
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
    80000930:	c2e080e7          	jalr	-978(ra) # 8000255a <sleep>
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
    80000b82:	26c080e7          	jalr	620(ra) # 80001dea <mycpu>
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
    80000bb4:	23a080e7          	jalr	570(ra) # 80001dea <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	22e080e7          	jalr	558(ra) # 80001dea <mycpu>
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
    80000bd8:	216080e7          	jalr	534(ra) # 80001dea <mycpu>
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
    80000c18:	1d6080e7          	jalr	470(ra) # 80001dea <mycpu>
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
    80000c44:	1aa080e7          	jalr	426(ra) # 80001dea <mycpu>
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
    80000e9a:	f44080e7          	jalr	-188(ra) # 80001dda <cpuid>
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
    80000eb6:	f28080e7          	jalr	-216(ra) # 80001dda <cpuid>
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
    80000ed8:	f8e080e7          	jalr	-114(ra) # 80002e62 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	564080e7          	jalr	1380(ra) # 80006440 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	400080e7          	jalr	1024(ra) # 800022e4 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	48450513          	addi	a0,a0,1156 # 80008380 <digits+0x340>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	46450513          	addi	a0,a0,1124 # 80008380 <digits+0x340>
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
    80000f48:	d94080e7          	jalr	-620(ra) # 80001cd8 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	eee080e7          	jalr	-274(ra) # 80002e3a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	f0e080e7          	jalr	-242(ra) # 80002e62 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	4ce080e7          	jalr	1230(ra) # 8000642a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	4dc080e7          	jalr	1244(ra) # 80006440 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	6b4080e7          	jalr	1716(ra) # 80003620 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	d44080e7          	jalr	-700(ra) # 80003cb8 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	cee080e7          	jalr	-786(ra) # 80004c6a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	5de080e7          	jalr	1502(ra) # 80006562 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	23c080e7          	jalr	572(ra) # 800021c8 <userinit>
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
    80001244:	a02080e7          	jalr	-1534(ra) # 80001c42 <proc_mapstacks>
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
    80001878:	17800993          	li	s3,376
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
    800018ba:	1141                	addi	sp,sp,-16
    800018bc:	e422                	sd	s0,8(sp)
    800018be:	0800                	addi	s0,sp,16
  lst->head = -1;
    800018c0:	57fd                	li	a5,-1
    800018c2:	c11c                	sw	a5,0(a0)
  lst->tail = -1;
    800018c4:	c15c                	sw	a5,4(a0)
}
    800018c6:	6422                	ld	s0,8(sp)
    800018c8:	0141                	addi	sp,sp,16
    800018ca:	8082                	ret

00000000800018cc <initialize_lists>:

void initialize_lists(void){
    800018cc:	7179                	addi	sp,sp,-48
    800018ce:	f406                	sd	ra,40(sp)
    800018d0:	f022                	sd	s0,32(sp)
    800018d2:	ec26                	sd	s1,24(sp)
    800018d4:	e84a                	sd	s2,16(sp)
    800018d6:	e44e                	sd	s3,8(sp)
    800018d8:	e052                	sd	s4,0(sp)
    800018da:	1800                	addi	s0,sp,48
  struct cpu *c;
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    800018dc:	00010497          	auipc	s1,0x10
    800018e0:	9c448493          	addi	s1,s1,-1596 # 800112a0 <cpus>
    c->runnable_list = (struct _list){-1, -1};
    800018e4:	597d                	li	s2,-1
    initlock(&c->runnable_list.lock, "runnable_list_lock");
    800018e6:	00007a17          	auipc	s4,0x7
    800018ea:	90aa0a13          	addi	s4,s4,-1782 # 800081f0 <digits+0x1b0>
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    800018ee:	00010997          	auipc	s3,0x10
    800018f2:	f3298993          	addi	s3,s3,-206 # 80011820 <pid_lock>
    c->runnable_list = (struct _list){-1, -1};
    800018f6:	0804b423          	sd	zero,136(s1)
    800018fa:	0804b823          	sd	zero,144(s1)
    800018fe:	0804bc23          	sd	zero,152(s1)
    80001902:	0924a023          	sw	s2,128(s1)
    80001906:	0924a223          	sw	s2,132(s1)
    initlock(&c->runnable_list.lock, "runnable_list_lock");
    8000190a:	85d2                	mv	a1,s4
    8000190c:	08848513          	addi	a0,s1,136
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001918:	0b048493          	addi	s1,s1,176
    8000191c:	fd349de3          	bne	s1,s3,800018f6 <initialize_lists+0x2a>
  }
  initlock(&unused_list.lock, "unused_list_lock");
    80001920:	00007597          	auipc	a1,0x7
    80001924:	8e858593          	addi	a1,a1,-1816 # 80008208 <digits+0x1c8>
    80001928:	00007517          	auipc	a0,0x7
    8000192c:	19050513          	addi	a0,a0,400 # 80008ab8 <unused_list+0x8>
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	224080e7          	jalr	548(ra) # 80000b54 <initlock>
  initlock(&sleeping_list.lock, "sleeping_list_lock");
    80001938:	00007597          	auipc	a1,0x7
    8000193c:	8e858593          	addi	a1,a1,-1816 # 80008220 <digits+0x1e0>
    80001940:	00007517          	auipc	a0,0x7
    80001944:	19850513          	addi	a0,a0,408 # 80008ad8 <sleeping_list+0x8>
    80001948:	fffff097          	auipc	ra,0xfffff
    8000194c:	20c080e7          	jalr	524(ra) # 80000b54 <initlock>
  initlock(&zombie_list.lock, "zombie_list_lock");
    80001950:	00007597          	auipc	a1,0x7
    80001954:	8e858593          	addi	a1,a1,-1816 # 80008238 <digits+0x1f8>
    80001958:	00007517          	auipc	a0,0x7
    8000195c:	1a050513          	addi	a0,a0,416 # 80008af8 <zombie_list+0x8>
    80001960:	fffff097          	auipc	ra,0xfffff
    80001964:	1f4080e7          	jalr	500(ra) # 80000b54 <initlock>
}
    80001968:	70a2                	ld	ra,40(sp)
    8000196a:	7402                	ld	s0,32(sp)
    8000196c:	64e2                	ld	s1,24(sp)
    8000196e:	6942                	ld	s2,16(sp)
    80001970:	69a2                	ld	s3,8(sp)
    80001972:	6a02                	ld	s4,0(sp)
    80001974:	6145                	addi	sp,sp,48
    80001976:	8082                	ret

0000000080001978 <initialize_proc>:

void
initialize_proc(struct proc *p){
    80001978:	1141                	addi	sp,sp,-16
    8000197a:	e422                	sd	s0,8(sp)
    8000197c:	0800                	addi	s0,sp,16
  p->next_index = -1;
    8000197e:	57fd                	li	a5,-1
    80001980:	16f52a23          	sw	a5,372(a0)
  p->prev_index = -1;
    80001984:	16f52823          	sw	a5,368(a0)
}
    80001988:	6422                	ld	s0,8(sp)
    8000198a:	0141                	addi	sp,sp,16
    8000198c:	8082                	ret

000000008000198e <isEmpty>:

int
isEmpty(struct _list *lst){
    8000198e:	1141                	addi	sp,sp,-16
    80001990:	e422                	sd	s0,8(sp)
    80001992:	0800                	addi	s0,sp,16
  return lst->head == -1;
    80001994:	4108                	lw	a0,0(a0)
    80001996:	0505                	addi	a0,a0,1
}
    80001998:	00153513          	seqz	a0,a0
    8000199c:	6422                	ld	s0,8(sp)
    8000199e:	0141                	addi	sp,sp,16
    800019a0:	8082                	ret

00000000800019a2 <set_prev_proc>:
  printf("after remove: \n");
  print_list(*lst); // delete
}
*/

void set_prev_proc(struct proc *p, int value){
    800019a2:	1101                	addi	sp,sp,-32
    800019a4:	ec06                	sd	ra,24(sp)
    800019a6:	e822                	sd	s0,16(sp)
    800019a8:	e426                	sd	s1,8(sp)
    800019aa:	e04a                	sd	s2,0(sp)
    800019ac:	1000                	addi	s0,sp,32
    800019ae:	84aa                	mv	s1,a0
    800019b0:	892e                	mv	s2,a1
  acquire(&p->lock);
    800019b2:	fffff097          	auipc	ra,0xfffff
    800019b6:	232080e7          	jalr	562(ra) # 80000be4 <acquire>
  p->prev_index = value; 
    800019ba:	1724a823          	sw	s2,368(s1)
  release(&p->lock);
    800019be:	8526                	mv	a0,s1
    800019c0:	fffff097          	auipc	ra,0xfffff
    800019c4:	2d8080e7          	jalr	728(ra) # 80000c98 <release>
}
    800019c8:	60e2                	ld	ra,24(sp)
    800019ca:	6442                	ld	s0,16(sp)
    800019cc:	64a2                	ld	s1,8(sp)
    800019ce:	6902                	ld	s2,0(sp)
    800019d0:	6105                	addi	sp,sp,32
    800019d2:	8082                	ret

00000000800019d4 <set_next_proc>:

void set_next_proc(struct proc *p, int value){
    800019d4:	1101                	addi	sp,sp,-32
    800019d6:	ec06                	sd	ra,24(sp)
    800019d8:	e822                	sd	s0,16(sp)
    800019da:	e426                	sd	s1,8(sp)
    800019dc:	e04a                	sd	s2,0(sp)
    800019de:	1000                	addi	s0,sp,32
    800019e0:	84aa                	mv	s1,a0
    800019e2:	892e                	mv	s2,a1
  acquire(&p->lock);
    800019e4:	fffff097          	auipc	ra,0xfffff
    800019e8:	200080e7          	jalr	512(ra) # 80000be4 <acquire>
  p->next_index = value; 
    800019ec:	1724aa23          	sw	s2,372(s1)
  release(&p->lock);
    800019f0:	8526                	mv	a0,s1
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	2a6080e7          	jalr	678(ra) # 80000c98 <release>
}
    800019fa:	60e2                	ld	ra,24(sp)
    800019fc:	6442                	ld	s0,16(sp)
    800019fe:	64a2                	ld	s1,8(sp)
    80001a00:	6902                	ld	s2,0(sp)
    80001a02:	6105                	addi	sp,sp,32
    80001a04:	8082                	ret

0000000080001a06 <insert_proc_to_list>:

void 
insert_proc_to_list(struct _list *lst, struct proc *p){
    80001a06:	715d                	addi	sp,sp,-80
    80001a08:	e486                	sd	ra,72(sp)
    80001a0a:	e0a2                	sd	s0,64(sp)
    80001a0c:	fc26                	sd	s1,56(sp)
    80001a0e:	f84a                	sd	s2,48(sp)
    80001a10:	f44e                	sd	s3,40(sp)
    80001a12:	f052                	sd	s4,32(sp)
    80001a14:	0880                	addi	s0,sp,80
    80001a16:	84aa                	mv	s1,a0
    80001a18:	892e                	mv	s2,a1
  printf("before insert: \n");
    80001a1a:	00007517          	auipc	a0,0x7
    80001a1e:	83650513          	addi	a0,a0,-1994 # 80008250 <digits+0x210>
    80001a22:	fffff097          	auipc	ra,0xfffff
    80001a26:	b66080e7          	jalr	-1178(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001a2a:	6090                	ld	a2,0(s1)
    80001a2c:	6494                	ld	a3,8(s1)
    80001a2e:	6898                	ld	a4,16(s1)
    80001a30:	6c9c                	ld	a5,24(s1)
    80001a32:	fac43823          	sd	a2,-80(s0)
    80001a36:	fad43c23          	sd	a3,-72(s0)
    80001a3a:	fce43023          	sd	a4,-64(s0)
    80001a3e:	fcf43423          	sd	a5,-56(s0)
    80001a42:	fb040513          	addi	a0,s0,-80
    80001a46:	00000097          	auipc	ra,0x0
    80001a4a:	df8080e7          	jalr	-520(ra) # 8000183e <print_list>

  acquire(&lst->lock);
    80001a4e:	00848993          	addi	s3,s1,8
    80001a52:	854e                	mv	a0,s3
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	190080e7          	jalr	400(ra) # 80000be4 <acquire>
  if(isEmpty(lst)){
    80001a5c:	4098                	lw	a4,0(s1)
    80001a5e:	57fd                	li	a5,-1
    80001a60:	04f71f63          	bne	a4,a5,80001abe <insert_proc_to_list+0xb8>
    lst->head = p->index;
    80001a64:	16c92783          	lw	a5,364(s2) # 116c <_entry-0x7fffee94>
    80001a68:	c09c                	sw	a5,0(s1)
    lst->tail = p-> index;
    80001a6a:	16c92783          	lw	a5,364(s2)
    80001a6e:	c0dc                	sw	a5,4(s1)
    struct proc *p_tail = &proc[lst->tail];
    set_next_proc(p_tail, p->index);  // update next proc of the curr tail
    p->prev_index = p_tail->index; // update the prev proc of the new proc
    lst->tail = p->index;          // update tail
  }
  release(&lst->lock);
    80001a70:	854e                	mv	a0,s3
    80001a72:	fffff097          	auipc	ra,0xfffff
    80001a76:	226080e7          	jalr	550(ra) # 80000c98 <release>
  printf("after insert: \n");
    80001a7a:	00006517          	auipc	a0,0x6
    80001a7e:	7ee50513          	addi	a0,a0,2030 # 80008268 <digits+0x228>
    80001a82:	fffff097          	auipc	ra,0xfffff
    80001a86:	b06080e7          	jalr	-1274(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001a8a:	6090                	ld	a2,0(s1)
    80001a8c:	6494                	ld	a3,8(s1)
    80001a8e:	6898                	ld	a4,16(s1)
    80001a90:	6c9c                	ld	a5,24(s1)
    80001a92:	fac43823          	sd	a2,-80(s0)
    80001a96:	fad43c23          	sd	a3,-72(s0)
    80001a9a:	fce43023          	sd	a4,-64(s0)
    80001a9e:	fcf43423          	sd	a5,-56(s0)
    80001aa2:	fb040513          	addi	a0,s0,-80
    80001aa6:	00000097          	auipc	ra,0x0
    80001aaa:	d98080e7          	jalr	-616(ra) # 8000183e <print_list>
}
    80001aae:	60a6                	ld	ra,72(sp)
    80001ab0:	6406                	ld	s0,64(sp)
    80001ab2:	74e2                	ld	s1,56(sp)
    80001ab4:	7942                	ld	s2,48(sp)
    80001ab6:	79a2                	ld	s3,40(sp)
    80001ab8:	7a02                	ld	s4,32(sp)
    80001aba:	6161                	addi	sp,sp,80
    80001abc:	8082                	ret
    struct proc *p_tail = &proc[lst->tail];
    80001abe:	0044aa03          	lw	s4,4(s1)
    80001ac2:	17800793          	li	a5,376
    80001ac6:	02fa0a33          	mul	s4,s4,a5
    80001aca:	00010797          	auipc	a5,0x10
    80001ace:	d8678793          	addi	a5,a5,-634 # 80011850 <proc>
    80001ad2:	9a3e                	add	s4,s4,a5
    set_next_proc(p_tail, p->index);  // update next proc of the curr tail
    80001ad4:	16c92583          	lw	a1,364(s2)
    80001ad8:	8552                	mv	a0,s4
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	efa080e7          	jalr	-262(ra) # 800019d4 <set_next_proc>
    p->prev_index = p_tail->index; // update the prev proc of the new proc
    80001ae2:	16ca2783          	lw	a5,364(s4)
    80001ae6:	16f92823          	sw	a5,368(s2)
    lst->tail = p->index;          // update tail
    80001aea:	16c92783          	lw	a5,364(s2)
    80001aee:	c0dc                	sw	a5,4(s1)
    80001af0:	b741                	j	80001a70 <insert_proc_to_list+0x6a>

0000000080001af2 <remove_proc_to_list>:

void 
remove_proc_to_list(struct _list *lst, struct proc *p){
    80001af2:	711d                	addi	sp,sp,-96
    80001af4:	ec86                	sd	ra,88(sp)
    80001af6:	e8a2                	sd	s0,80(sp)
    80001af8:	e4a6                	sd	s1,72(sp)
    80001afa:	e0ca                	sd	s2,64(sp)
    80001afc:	fc4e                	sd	s3,56(sp)
    80001afe:	f852                	sd	s4,48(sp)
    80001b00:	f456                	sd	s5,40(sp)
    80001b02:	1080                	addi	s0,sp,96
    80001b04:	84aa                	mv	s1,a0
    80001b06:	892e                	mv	s2,a1
  printf("before insert: \n");
    80001b08:	00006517          	auipc	a0,0x6
    80001b0c:	74850513          	addi	a0,a0,1864 # 80008250 <digits+0x210>
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	a78080e7          	jalr	-1416(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001b18:	6090                	ld	a2,0(s1)
    80001b1a:	6494                	ld	a3,8(s1)
    80001b1c:	6898                	ld	a4,16(s1)
    80001b1e:	6c9c                	ld	a5,24(s1)
    80001b20:	fac43023          	sd	a2,-96(s0)
    80001b24:	fad43423          	sd	a3,-88(s0)
    80001b28:	fae43823          	sd	a4,-80(s0)
    80001b2c:	faf43c23          	sd	a5,-72(s0)
    80001b30:	fa040513          	addi	a0,s0,-96
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	d0a080e7          	jalr	-758(ra) # 8000183e <print_list>
  acquire(&lst->lock);
    80001b3c:	00848993          	addi	s3,s1,8
    80001b40:	854e                	mv	a0,s3
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	0a2080e7          	jalr	162(ra) # 80000be4 <acquire>
  if(lst->head == p->index && lst->tail == p->index) // p is the only proc in the list
    80001b4a:	16c92783          	lw	a5,364(s2)
    80001b4e:	4098                	lw	a4,0(s1)
    80001b50:	08f70e63          	beq	a4,a5,80001bec <remove_proc_to_list+0xfa>
    initialize_list(lst);
  else if(lst->head == p->index) {  // p is the head of the list
    lst->head = p->next_index;
    set_prev_proc(&proc[lst->head], -1);
  }
  else if(lst->tail == p->index) { // p is the tail of the list
    80001b54:	40d8                	lw	a4,4(s1)
    80001b56:	0cf70463          	beq	a4,a5,80001c1e <remove_proc_to_list+0x12c>
    lst->tail = p->prev_index;
    set_next_proc(&proc[lst->tail], -1);
    }
  else {
    set_next_proc(&proc[p->prev_index], p->next_index);
    80001b5a:	17092503          	lw	a0,368(s2)
    80001b5e:	17800a93          	li	s5,376
    80001b62:	03550533          	mul	a0,a0,s5
    80001b66:	00010a17          	auipc	s4,0x10
    80001b6a:	ceaa0a13          	addi	s4,s4,-790 # 80011850 <proc>
    80001b6e:	17492583          	lw	a1,372(s2)
    80001b72:	9552                	add	a0,a0,s4
    80001b74:	00000097          	auipc	ra,0x0
    80001b78:	e60080e7          	jalr	-416(ra) # 800019d4 <set_next_proc>
    set_prev_proc(&proc[p->next_index], p->prev_index);
    80001b7c:	17492503          	lw	a0,372(s2)
    80001b80:	03550533          	mul	a0,a0,s5
    80001b84:	17092583          	lw	a1,368(s2)
    80001b88:	9552                	add	a0,a0,s4
    80001b8a:	00000097          	auipc	ra,0x0
    80001b8e:	e18080e7          	jalr	-488(ra) # 800019a2 <set_prev_proc>
  }
  release(&lst->lock);
    80001b92:	854e                	mv	a0,s3
    80001b94:	fffff097          	auipc	ra,0xfffff
    80001b98:	104080e7          	jalr	260(ra) # 80000c98 <release>
  p->next_index = -1;
    80001b9c:	57fd                	li	a5,-1
    80001b9e:	16f92a23          	sw	a5,372(s2)
  p->prev_index = -1;
    80001ba2:	16f92823          	sw	a5,368(s2)
  initialize_proc(p);

  printf("after remove: \n");
    80001ba6:	00006517          	auipc	a0,0x6
    80001baa:	6d250513          	addi	a0,a0,1746 # 80008278 <digits+0x238>
    80001bae:	fffff097          	auipc	ra,0xfffff
    80001bb2:	9da080e7          	jalr	-1574(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001bb6:	6090                	ld	a2,0(s1)
    80001bb8:	6494                	ld	a3,8(s1)
    80001bba:	6898                	ld	a4,16(s1)
    80001bbc:	6c9c                	ld	a5,24(s1)
    80001bbe:	fac43023          	sd	a2,-96(s0)
    80001bc2:	fad43423          	sd	a3,-88(s0)
    80001bc6:	fae43823          	sd	a4,-80(s0)
    80001bca:	faf43c23          	sd	a5,-72(s0)
    80001bce:	fa040513          	addi	a0,s0,-96
    80001bd2:	00000097          	auipc	ra,0x0
    80001bd6:	c6c080e7          	jalr	-916(ra) # 8000183e <print_list>
}
    80001bda:	60e6                	ld	ra,88(sp)
    80001bdc:	6446                	ld	s0,80(sp)
    80001bde:	64a6                	ld	s1,72(sp)
    80001be0:	6906                	ld	s2,64(sp)
    80001be2:	79e2                	ld	s3,56(sp)
    80001be4:	7a42                	ld	s4,48(sp)
    80001be6:	7aa2                	ld	s5,40(sp)
    80001be8:	6125                	addi	sp,sp,96
    80001bea:	8082                	ret
  if(lst->head == p->index && lst->tail == p->index) // p is the only proc in the list
    80001bec:	40d8                	lw	a4,4(s1)
    80001bee:	02f70463          	beq	a4,a5,80001c16 <remove_proc_to_list+0x124>
    lst->head = p->next_index;
    80001bf2:	17492503          	lw	a0,372(s2)
    80001bf6:	c088                	sw	a0,0(s1)
    set_prev_proc(&proc[lst->head], -1);
    80001bf8:	17800793          	li	a5,376
    80001bfc:	02f50533          	mul	a0,a0,a5
    80001c00:	55fd                	li	a1,-1
    80001c02:	00010797          	auipc	a5,0x10
    80001c06:	c4e78793          	addi	a5,a5,-946 # 80011850 <proc>
    80001c0a:	953e                	add	a0,a0,a5
    80001c0c:	00000097          	auipc	ra,0x0
    80001c10:	d96080e7          	jalr	-618(ra) # 800019a2 <set_prev_proc>
    80001c14:	bfbd                	j	80001b92 <remove_proc_to_list+0xa0>
  lst->head = -1;
    80001c16:	57fd                	li	a5,-1
    80001c18:	c09c                	sw	a5,0(s1)
  lst->tail = -1;
    80001c1a:	c0dc                	sw	a5,4(s1)
}
    80001c1c:	bf9d                	j	80001b92 <remove_proc_to_list+0xa0>
    lst->tail = p->prev_index;
    80001c1e:	17092503          	lw	a0,368(s2)
    80001c22:	c0c8                	sw	a0,4(s1)
    set_next_proc(&proc[lst->tail], -1);
    80001c24:	17800793          	li	a5,376
    80001c28:	02f50533          	mul	a0,a0,a5
    80001c2c:	55fd                	li	a1,-1
    80001c2e:	00010797          	auipc	a5,0x10
    80001c32:	c2278793          	addi	a5,a5,-990 # 80011850 <proc>
    80001c36:	953e                	add	a0,a0,a5
    80001c38:	00000097          	auipc	ra,0x0
    80001c3c:	d9c080e7          	jalr	-612(ra) # 800019d4 <set_next_proc>
    80001c40:	bf89                	j	80001b92 <remove_proc_to_list+0xa0>

0000000080001c42 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001c42:	7139                	addi	sp,sp,-64
    80001c44:	fc06                	sd	ra,56(sp)
    80001c46:	f822                	sd	s0,48(sp)
    80001c48:	f426                	sd	s1,40(sp)
    80001c4a:	f04a                	sd	s2,32(sp)
    80001c4c:	ec4e                	sd	s3,24(sp)
    80001c4e:	e852                	sd	s4,16(sp)
    80001c50:	e456                	sd	s5,8(sp)
    80001c52:	e05a                	sd	s6,0(sp)
    80001c54:	0080                	addi	s0,sp,64
    80001c56:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c58:	00010497          	auipc	s1,0x10
    80001c5c:	bf848493          	addi	s1,s1,-1032 # 80011850 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001c60:	8b26                	mv	s6,s1
    80001c62:	00006a97          	auipc	s5,0x6
    80001c66:	39ea8a93          	addi	s5,s5,926 # 80008000 <etext>
    80001c6a:	04000937          	lui	s2,0x4000
    80001c6e:	197d                	addi	s2,s2,-1
    80001c70:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c72:	00016a17          	auipc	s4,0x16
    80001c76:	9dea0a13          	addi	s4,s4,-1570 # 80017650 <tickslock>
    char *pa = kalloc();
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	e7a080e7          	jalr	-390(ra) # 80000af4 <kalloc>
    80001c82:	862a                	mv	a2,a0
    if(pa == 0)
    80001c84:	c131                	beqz	a0,80001cc8 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001c86:	416485b3          	sub	a1,s1,s6
    80001c8a:	858d                	srai	a1,a1,0x3
    80001c8c:	000ab783          	ld	a5,0(s5)
    80001c90:	02f585b3          	mul	a1,a1,a5
    80001c94:	2585                	addiw	a1,a1,1
    80001c96:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c9a:	4719                	li	a4,6
    80001c9c:	6685                	lui	a3,0x1
    80001c9e:	40b905b3          	sub	a1,s2,a1
    80001ca2:	854e                	mv	a0,s3
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	4ac080e7          	jalr	1196(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cac:	17848493          	addi	s1,s1,376
    80001cb0:	fd4495e3          	bne	s1,s4,80001c7a <proc_mapstacks+0x38>
  }
}
    80001cb4:	70e2                	ld	ra,56(sp)
    80001cb6:	7442                	ld	s0,48(sp)
    80001cb8:	74a2                	ld	s1,40(sp)
    80001cba:	7902                	ld	s2,32(sp)
    80001cbc:	69e2                	ld	s3,24(sp)
    80001cbe:	6a42                	ld	s4,16(sp)
    80001cc0:	6aa2                	ld	s5,8(sp)
    80001cc2:	6b02                	ld	s6,0(sp)
    80001cc4:	6121                	addi	sp,sp,64
    80001cc6:	8082                	ret
      panic("kalloc");
    80001cc8:	00006517          	auipc	a0,0x6
    80001ccc:	5c050513          	addi	a0,a0,1472 # 80008288 <digits+0x248>
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	86e080e7          	jalr	-1938(ra) # 8000053e <panic>

0000000080001cd8 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001cd8:	711d                	addi	sp,sp,-96
    80001cda:	ec86                	sd	ra,88(sp)
    80001cdc:	e8a2                	sd	s0,80(sp)
    80001cde:	e4a6                	sd	s1,72(sp)
    80001ce0:	e0ca                	sd	s2,64(sp)
    80001ce2:	fc4e                	sd	s3,56(sp)
    80001ce4:	f852                	sd	s4,48(sp)
    80001ce6:	f456                	sd	s5,40(sp)
    80001ce8:	f05a                	sd	s6,32(sp)
    80001cea:	ec5e                	sd	s7,24(sp)
    80001cec:	e862                	sd	s8,16(sp)
    80001cee:	e466                	sd	s9,8(sp)
    80001cf0:	e06a                	sd	s10,0(sp)
    80001cf2:	1080                	addi	s0,sp,96
  struct proc *p;

  initialize_lists();
    80001cf4:	00000097          	auipc	ra,0x0
    80001cf8:	bd8080e7          	jalr	-1064(ra) # 800018cc <initialize_lists>

  initlock(&pid_lock, "nextpid");
    80001cfc:	00006597          	auipc	a1,0x6
    80001d00:	59458593          	addi	a1,a1,1428 # 80008290 <digits+0x250>
    80001d04:	00010517          	auipc	a0,0x10
    80001d08:	b1c50513          	addi	a0,a0,-1252 # 80011820 <pid_lock>
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	e48080e7          	jalr	-440(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001d14:	00006597          	auipc	a1,0x6
    80001d18:	58458593          	addi	a1,a1,1412 # 80008298 <digits+0x258>
    80001d1c:	00010517          	auipc	a0,0x10
    80001d20:	b1c50513          	addi	a0,a0,-1252 # 80011838 <wait_lock>
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	e30080e7          	jalr	-464(ra) # 80000b54 <initlock>

  int i = 0;
    80001d2c:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d2e:	00010497          	auipc	s1,0x10
    80001d32:	b2248493          	addi	s1,s1,-1246 # 80011850 <proc>
      initlock(&p->lock, "proc");
    80001d36:	00006d17          	auipc	s10,0x6
    80001d3a:	572d0d13          	addi	s10,s10,1394 # 800082a8 <digits+0x268>
      p->kstack = KSTACK((int) (p - proc));
    80001d3e:	8ca6                	mv	s9,s1
    80001d40:	00006c17          	auipc	s8,0x6
    80001d44:	2c0c0c13          	addi	s8,s8,704 # 80008000 <etext>
    80001d48:	04000a37          	lui	s4,0x4000
    80001d4c:	1a7d                	addi	s4,s4,-1
    80001d4e:	0a32                	slli	s4,s4,0xc
  p->next_index = -1;
    80001d50:	59fd                	li	s3,-1
      p->index = i;
      initialize_proc(p);
      printf("insert procinit unused %d\n", p->index); //delete
    80001d52:	00006b97          	auipc	s7,0x6
    80001d56:	55eb8b93          	addi	s7,s7,1374 # 800082b0 <digits+0x270>
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001d5a:	00007b17          	auipc	s6,0x7
    80001d5e:	d56b0b13          	addi	s6,s6,-682 # 80008ab0 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d62:	00016a97          	auipc	s5,0x16
    80001d66:	8eea8a93          	addi	s5,s5,-1810 # 80017650 <tickslock>
      initlock(&p->lock, "proc");
    80001d6a:	85ea                	mv	a1,s10
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	de6080e7          	jalr	-538(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001d76:	419487b3          	sub	a5,s1,s9
    80001d7a:	878d                	srai	a5,a5,0x3
    80001d7c:	000c3703          	ld	a4,0(s8)
    80001d80:	02e787b3          	mul	a5,a5,a4
    80001d84:	2785                	addiw	a5,a5,1
    80001d86:	00d7979b          	slliw	a5,a5,0xd
    80001d8a:	40fa07b3          	sub	a5,s4,a5
    80001d8e:	e0bc                	sd	a5,64(s1)
      p->index = i;
    80001d90:	1724a623          	sw	s2,364(s1)
  p->next_index = -1;
    80001d94:	1734aa23          	sw	s3,372(s1)
  p->prev_index = -1;
    80001d98:	1734a823          	sw	s3,368(s1)
      printf("insert procinit unused %d\n", p->index); //delete
    80001d9c:	85ca                	mv	a1,s2
    80001d9e:	855e                	mv	a0,s7
    80001da0:	ffffe097          	auipc	ra,0xffffe
    80001da4:	7e8080e7          	jalr	2024(ra) # 80000588 <printf>
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001da8:	85a6                	mv	a1,s1
    80001daa:	855a                	mv	a0,s6
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	c5a080e7          	jalr	-934(ra) # 80001a06 <insert_proc_to_list>
      i++;
    80001db4:	2905                	addiw	s2,s2,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80001db6:	17848493          	addi	s1,s1,376
    80001dba:	fb5498e3          	bne	s1,s5,80001d6a <procinit+0x92>
  }
}
    80001dbe:	60e6                	ld	ra,88(sp)
    80001dc0:	6446                	ld	s0,80(sp)
    80001dc2:	64a6                	ld	s1,72(sp)
    80001dc4:	6906                	ld	s2,64(sp)
    80001dc6:	79e2                	ld	s3,56(sp)
    80001dc8:	7a42                	ld	s4,48(sp)
    80001dca:	7aa2                	ld	s5,40(sp)
    80001dcc:	7b02                	ld	s6,32(sp)
    80001dce:	6be2                	ld	s7,24(sp)
    80001dd0:	6c42                	ld	s8,16(sp)
    80001dd2:	6ca2                	ld	s9,8(sp)
    80001dd4:	6d02                	ld	s10,0(sp)
    80001dd6:	6125                	addi	sp,sp,96
    80001dd8:	8082                	ret

0000000080001dda <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001dda:	1141                	addi	sp,sp,-16
    80001ddc:	e422                	sd	s0,8(sp)
    80001dde:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001de0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001de2:	2501                	sext.w	a0,a0
    80001de4:	6422                	ld	s0,8(sp)
    80001de6:	0141                	addi	sp,sp,16
    80001de8:	8082                	ret

0000000080001dea <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001dea:	1141                	addi	sp,sp,-16
    80001dec:	e422                	sd	s0,8(sp)
    80001dee:	0800                	addi	s0,sp,16
    80001df0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001df2:	2781                	sext.w	a5,a5
    80001df4:	0b000513          	li	a0,176
    80001df8:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001dfc:	0000f517          	auipc	a0,0xf
    80001e00:	4a450513          	addi	a0,a0,1188 # 800112a0 <cpus>
    80001e04:	953e                	add	a0,a0,a5
    80001e06:	6422                	ld	s0,8(sp)
    80001e08:	0141                	addi	sp,sp,16
    80001e0a:	8082                	ret

0000000080001e0c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001e0c:	1101                	addi	sp,sp,-32
    80001e0e:	ec06                	sd	ra,24(sp)
    80001e10:	e822                	sd	s0,16(sp)
    80001e12:	e426                	sd	s1,8(sp)
    80001e14:	1000                	addi	s0,sp,32
  push_off();
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	d82080e7          	jalr	-638(ra) # 80000b98 <push_off>
    80001e1e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001e20:	2781                	sext.w	a5,a5
    80001e22:	0b000713          	li	a4,176
    80001e26:	02e787b3          	mul	a5,a5,a4
    80001e2a:	0000f717          	auipc	a4,0xf
    80001e2e:	47670713          	addi	a4,a4,1142 # 800112a0 <cpus>
    80001e32:	97ba                	add	a5,a5,a4
    80001e34:	6384                	ld	s1,0(a5)
  pop_off();
    80001e36:	fffff097          	auipc	ra,0xfffff
    80001e3a:	e02080e7          	jalr	-510(ra) # 80000c38 <pop_off>
  return p;
}
    80001e3e:	8526                	mv	a0,s1
    80001e40:	60e2                	ld	ra,24(sp)
    80001e42:	6442                	ld	s0,16(sp)
    80001e44:	64a2                	ld	s1,8(sp)
    80001e46:	6105                	addi	sp,sp,32
    80001e48:	8082                	ret

0000000080001e4a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001e4a:	1141                	addi	sp,sp,-16
    80001e4c:	e406                	sd	ra,8(sp)
    80001e4e:	e022                	sd	s0,0(sp)
    80001e50:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001e52:	00000097          	auipc	ra,0x0
    80001e56:	fba080e7          	jalr	-70(ra) # 80001e0c <myproc>
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	e3e080e7          	jalr	-450(ra) # 80000c98 <release>

  if (first) {
    80001e62:	00007797          	auipc	a5,0x7
    80001e66:	c3e7a783          	lw	a5,-962(a5) # 80008aa0 <first.1762>
    80001e6a:	eb89                	bnez	a5,80001e7c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001e6c:	00001097          	auipc	ra,0x1
    80001e70:	00e080e7          	jalr	14(ra) # 80002e7a <usertrapret>
}
    80001e74:	60a2                	ld	ra,8(sp)
    80001e76:	6402                	ld	s0,0(sp)
    80001e78:	0141                	addi	sp,sp,16
    80001e7a:	8082                	ret
    first = 0;
    80001e7c:	00007797          	auipc	a5,0x7
    80001e80:	c207a223          	sw	zero,-988(a5) # 80008aa0 <first.1762>
    fsinit(ROOTDEV);
    80001e84:	4505                	li	a0,1
    80001e86:	00002097          	auipc	ra,0x2
    80001e8a:	db2080e7          	jalr	-590(ra) # 80003c38 <fsinit>
    80001e8e:	bff9                	j	80001e6c <forkret+0x22>

0000000080001e90 <allocpid>:
allocpid() {
    80001e90:	1101                	addi	sp,sp,-32
    80001e92:	ec06                	sd	ra,24(sp)
    80001e94:	e822                	sd	s0,16(sp)
    80001e96:	e426                	sd	s1,8(sp)
    80001e98:	e04a                	sd	s2,0(sp)
    80001e9a:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001e9c:	00007917          	auipc	s2,0x7
    80001ea0:	c0890913          	addi	s2,s2,-1016 # 80008aa4 <nextpid>
    80001ea4:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, nextpid + 1));
    80001ea8:	0014861b          	addiw	a2,s1,1
    80001eac:	85a6                	mv	a1,s1
    80001eae:	854a                	mv	a0,s2
    80001eb0:	00005097          	auipc	ra,0x5
    80001eb4:	b96080e7          	jalr	-1130(ra) # 80006a46 <cas>
    80001eb8:	2501                	sext.w	a0,a0
    80001eba:	f56d                	bnez	a0,80001ea4 <allocpid+0x14>
}
    80001ebc:	8526                	mv	a0,s1
    80001ebe:	60e2                	ld	ra,24(sp)
    80001ec0:	6442                	ld	s0,16(sp)
    80001ec2:	64a2                	ld	s1,8(sp)
    80001ec4:	6902                	ld	s2,0(sp)
    80001ec6:	6105                	addi	sp,sp,32
    80001ec8:	8082                	ret

0000000080001eca <proc_pagetable>:
{
    80001eca:	1101                	addi	sp,sp,-32
    80001ecc:	ec06                	sd	ra,24(sp)
    80001ece:	e822                	sd	s0,16(sp)
    80001ed0:	e426                	sd	s1,8(sp)
    80001ed2:	e04a                	sd	s2,0(sp)
    80001ed4:	1000                	addi	s0,sp,32
    80001ed6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	462080e7          	jalr	1122(ra) # 8000133a <uvmcreate>
    80001ee0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ee2:	c121                	beqz	a0,80001f22 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ee4:	4729                	li	a4,10
    80001ee6:	00005697          	auipc	a3,0x5
    80001eea:	11a68693          	addi	a3,a3,282 # 80007000 <_trampoline>
    80001eee:	6605                	lui	a2,0x1
    80001ef0:	040005b7          	lui	a1,0x4000
    80001ef4:	15fd                	addi	a1,a1,-1
    80001ef6:	05b2                	slli	a1,a1,0xc
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	1b8080e7          	jalr	440(ra) # 800010b0 <mappages>
    80001f00:	02054863          	bltz	a0,80001f30 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001f04:	4719                	li	a4,6
    80001f06:	05893683          	ld	a3,88(s2)
    80001f0a:	6605                	lui	a2,0x1
    80001f0c:	020005b7          	lui	a1,0x2000
    80001f10:	15fd                	addi	a1,a1,-1
    80001f12:	05b6                	slli	a1,a1,0xd
    80001f14:	8526                	mv	a0,s1
    80001f16:	fffff097          	auipc	ra,0xfffff
    80001f1a:	19a080e7          	jalr	410(ra) # 800010b0 <mappages>
    80001f1e:	02054163          	bltz	a0,80001f40 <proc_pagetable+0x76>
}
    80001f22:	8526                	mv	a0,s1
    80001f24:	60e2                	ld	ra,24(sp)
    80001f26:	6442                	ld	s0,16(sp)
    80001f28:	64a2                	ld	s1,8(sp)
    80001f2a:	6902                	ld	s2,0(sp)
    80001f2c:	6105                	addi	sp,sp,32
    80001f2e:	8082                	ret
    uvmfree(pagetable, 0);
    80001f30:	4581                	li	a1,0
    80001f32:	8526                	mv	a0,s1
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	602080e7          	jalr	1538(ra) # 80001536 <uvmfree>
    return 0;
    80001f3c:	4481                	li	s1,0
    80001f3e:	b7d5                	j	80001f22 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f40:	4681                	li	a3,0
    80001f42:	4605                	li	a2,1
    80001f44:	040005b7          	lui	a1,0x4000
    80001f48:	15fd                	addi	a1,a1,-1
    80001f4a:	05b2                	slli	a1,a1,0xc
    80001f4c:	8526                	mv	a0,s1
    80001f4e:	fffff097          	auipc	ra,0xfffff
    80001f52:	328080e7          	jalr	808(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001f56:	4581                	li	a1,0
    80001f58:	8526                	mv	a0,s1
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	5dc080e7          	jalr	1500(ra) # 80001536 <uvmfree>
    return 0;
    80001f62:	4481                	li	s1,0
    80001f64:	bf7d                	j	80001f22 <proc_pagetable+0x58>

0000000080001f66 <proc_freepagetable>:
{
    80001f66:	1101                	addi	sp,sp,-32
    80001f68:	ec06                	sd	ra,24(sp)
    80001f6a:	e822                	sd	s0,16(sp)
    80001f6c:	e426                	sd	s1,8(sp)
    80001f6e:	e04a                	sd	s2,0(sp)
    80001f70:	1000                	addi	s0,sp,32
    80001f72:	84aa                	mv	s1,a0
    80001f74:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f76:	4681                	li	a3,0
    80001f78:	4605                	li	a2,1
    80001f7a:	040005b7          	lui	a1,0x4000
    80001f7e:	15fd                	addi	a1,a1,-1
    80001f80:	05b2                	slli	a1,a1,0xc
    80001f82:	fffff097          	auipc	ra,0xfffff
    80001f86:	2f4080e7          	jalr	756(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001f8a:	4681                	li	a3,0
    80001f8c:	4605                	li	a2,1
    80001f8e:	020005b7          	lui	a1,0x2000
    80001f92:	15fd                	addi	a1,a1,-1
    80001f94:	05b6                	slli	a1,a1,0xd
    80001f96:	8526                	mv	a0,s1
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	2de080e7          	jalr	734(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001fa0:	85ca                	mv	a1,s2
    80001fa2:	8526                	mv	a0,s1
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	592080e7          	jalr	1426(ra) # 80001536 <uvmfree>
}
    80001fac:	60e2                	ld	ra,24(sp)
    80001fae:	6442                	ld	s0,16(sp)
    80001fb0:	64a2                	ld	s1,8(sp)
    80001fb2:	6902                	ld	s2,0(sp)
    80001fb4:	6105                	addi	sp,sp,32
    80001fb6:	8082                	ret

0000000080001fb8 <freeproc>:
{
    80001fb8:	1101                	addi	sp,sp,-32
    80001fba:	ec06                	sd	ra,24(sp)
    80001fbc:	e822                	sd	s0,16(sp)
    80001fbe:	e426                	sd	s1,8(sp)
    80001fc0:	1000                	addi	s0,sp,32
    80001fc2:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001fc4:	6d28                	ld	a0,88(a0)
    80001fc6:	c509                	beqz	a0,80001fd0 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	a30080e7          	jalr	-1488(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001fd0:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001fd4:	68a8                	ld	a0,80(s1)
    80001fd6:	c511                	beqz	a0,80001fe2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001fd8:	64ac                	ld	a1,72(s1)
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	f8c080e7          	jalr	-116(ra) # 80001f66 <proc_freepagetable>
  p->pagetable = 0;
    80001fe2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001fe6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001fea:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001fee:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ff2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ff6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ffa:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ffe:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80002002:	0004ac23          	sw	zero,24(s1)
  printf("remove free proc zombie %d\n", p->index); //delete
    80002006:	16c4a583          	lw	a1,364(s1)
    8000200a:	00006517          	auipc	a0,0x6
    8000200e:	2c650513          	addi	a0,a0,710 # 800082d0 <digits+0x290>
    80002012:	ffffe097          	auipc	ra,0xffffe
    80002016:	576080e7          	jalr	1398(ra) # 80000588 <printf>
  remove_proc_to_list(&zombie_list, p); // remove the freed process from the ZOMBIE list
    8000201a:	85a6                	mv	a1,s1
    8000201c:	00007517          	auipc	a0,0x7
    80002020:	ad450513          	addi	a0,a0,-1324 # 80008af0 <zombie_list>
    80002024:	00000097          	auipc	ra,0x0
    80002028:	ace080e7          	jalr	-1330(ra) # 80001af2 <remove_proc_to_list>
  printf("insert free proc unused %d\n", p->index); //delete
    8000202c:	16c4a583          	lw	a1,364(s1)
    80002030:	00006517          	auipc	a0,0x6
    80002034:	2c050513          	addi	a0,a0,704 # 800082f0 <digits+0x2b0>
    80002038:	ffffe097          	auipc	ra,0xffffe
    8000203c:	550080e7          	jalr	1360(ra) # 80000588 <printf>
  insert_proc_to_list(&unused_list, p); // admit its entry to the UNUSED entry list.
    80002040:	85a6                	mv	a1,s1
    80002042:	00007517          	auipc	a0,0x7
    80002046:	a6e50513          	addi	a0,a0,-1426 # 80008ab0 <unused_list>
    8000204a:	00000097          	auipc	ra,0x0
    8000204e:	9bc080e7          	jalr	-1604(ra) # 80001a06 <insert_proc_to_list>
}
    80002052:	60e2                	ld	ra,24(sp)
    80002054:	6442                	ld	s0,16(sp)
    80002056:	64a2                	ld	s1,8(sp)
    80002058:	6105                	addi	sp,sp,32
    8000205a:	8082                	ret

000000008000205c <allocproc>:
{
    8000205c:	715d                	addi	sp,sp,-80
    8000205e:	e486                	sd	ra,72(sp)
    80002060:	e0a2                	sd	s0,64(sp)
    80002062:	fc26                	sd	s1,56(sp)
    80002064:	f84a                	sd	s2,48(sp)
    80002066:	f44e                	sd	s3,40(sp)
    80002068:	f052                	sd	s4,32(sp)
    8000206a:	ec56                	sd	s5,24(sp)
    8000206c:	e85a                	sd	s6,16(sp)
    8000206e:	e45e                	sd	s7,8(sp)
    80002070:	0880                	addi	s0,sp,80
  return lst->head == -1;
    80002072:	00007917          	auipc	s2,0x7
    80002076:	a3e92903          	lw	s2,-1474(s2) # 80008ab0 <unused_list>
  while(!isEmpty(&unused_list)){
    8000207a:	57fd                	li	a5,-1
    8000207c:	14f90463          	beq	s2,a5,800021c4 <allocproc+0x168>
    80002080:	17800a93          	li	s5,376
    p = &proc[unused_list.head];
    80002084:	0000fa17          	auipc	s4,0xf
    80002088:	7cca0a13          	addi	s4,s4,1996 # 80011850 <proc>
  return lst->head == -1;
    8000208c:	00007b97          	auipc	s7,0x7
    80002090:	a24b8b93          	addi	s7,s7,-1500 # 80008ab0 <unused_list>
  while(!isEmpty(&unused_list)){
    80002094:	5b7d                	li	s6,-1
    p = &proc[unused_list.head];
    80002096:	035909b3          	mul	s3,s2,s5
    8000209a:	014984b3          	add	s1,s3,s4
    acquire(&p->lock);
    8000209e:	8526                	mv	a0,s1
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	b44080e7          	jalr	-1212(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    800020a8:	4c9c                	lw	a5,24(s1)
    800020aa:	c79d                	beqz	a5,800020d8 <allocproc+0x7c>
      release(&p->lock);
    800020ac:	8526                	mv	a0,s1
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	bea080e7          	jalr	-1046(ra) # 80000c98 <release>
  return lst->head == -1;
    800020b6:	000ba903          	lw	s2,0(s7)
  while(!isEmpty(&unused_list)){
    800020ba:	fd691ee3          	bne	s2,s6,80002096 <allocproc+0x3a>
  return 0;
    800020be:	4481                	li	s1,0
}
    800020c0:	8526                	mv	a0,s1
    800020c2:	60a6                	ld	ra,72(sp)
    800020c4:	6406                	ld	s0,64(sp)
    800020c6:	74e2                	ld	s1,56(sp)
    800020c8:	7942                	ld	s2,48(sp)
    800020ca:	79a2                	ld	s3,40(sp)
    800020cc:	7a02                	ld	s4,32(sp)
    800020ce:	6ae2                	ld	s5,24(sp)
    800020d0:	6b42                	ld	s6,16(sp)
    800020d2:	6ba2                	ld	s7,8(sp)
    800020d4:	6161                	addi	sp,sp,80
    800020d6:	8082                	ret
      printf("remove allocproc unused %d\n", p->index); //delete
    800020d8:	17800a13          	li	s4,376
    800020dc:	034907b3          	mul	a5,s2,s4
    800020e0:	0000fa17          	auipc	s4,0xf
    800020e4:	770a0a13          	addi	s4,s4,1904 # 80011850 <proc>
    800020e8:	9a3e                	add	s4,s4,a5
    800020ea:	16ca2583          	lw	a1,364(s4)
    800020ee:	00006517          	auipc	a0,0x6
    800020f2:	22250513          	addi	a0,a0,546 # 80008310 <digits+0x2d0>
    800020f6:	ffffe097          	auipc	ra,0xffffe
    800020fa:	492080e7          	jalr	1170(ra) # 80000588 <printf>
      remove_proc_to_list(&unused_list, p); // choose the new process entry to initialize from the UNUSED entry list.
    800020fe:	85a6                	mv	a1,s1
    80002100:	00007517          	auipc	a0,0x7
    80002104:	9b050513          	addi	a0,a0,-1616 # 80008ab0 <unused_list>
    80002108:	00000097          	auipc	ra,0x0
    8000210c:	9ea080e7          	jalr	-1558(ra) # 80001af2 <remove_proc_to_list>
  p->pid = allocpid();
    80002110:	00000097          	auipc	ra,0x0
    80002114:	d80080e7          	jalr	-640(ra) # 80001e90 <allocpid>
    80002118:	02aa2823          	sw	a0,48(s4)
  p->state = USED;
    8000211c:	4785                	li	a5,1
    8000211e:	00fa2c23          	sw	a5,24(s4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002122:	fffff097          	auipc	ra,0xfffff
    80002126:	9d2080e7          	jalr	-1582(ra) # 80000af4 <kalloc>
    8000212a:	8aaa                	mv	s5,a0
    8000212c:	04aa3c23          	sd	a0,88(s4)
    80002130:	c135                	beqz	a0,80002194 <allocproc+0x138>
  p->pagetable = proc_pagetable(p);
    80002132:	8526                	mv	a0,s1
    80002134:	00000097          	auipc	ra,0x0
    80002138:	d96080e7          	jalr	-618(ra) # 80001eca <proc_pagetable>
    8000213c:	8a2a                	mv	s4,a0
    8000213e:	17800793          	li	a5,376
    80002142:	02f90733          	mul	a4,s2,a5
    80002146:	0000f797          	auipc	a5,0xf
    8000214a:	70a78793          	addi	a5,a5,1802 # 80011850 <proc>
    8000214e:	97ba                	add	a5,a5,a4
    80002150:	eba8                	sd	a0,80(a5)
  if(p->pagetable == 0){
    80002152:	cd29                	beqz	a0,800021ac <allocproc+0x150>
  memset(&p->context, 0, sizeof(p->context));
    80002154:	06098513          	addi	a0,s3,96
    80002158:	0000f997          	auipc	s3,0xf
    8000215c:	6f898993          	addi	s3,s3,1784 # 80011850 <proc>
    80002160:	07000613          	li	a2,112
    80002164:	4581                	li	a1,0
    80002166:	954e                	add	a0,a0,s3
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	b78080e7          	jalr	-1160(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80002170:	17800793          	li	a5,376
    80002174:	02f90933          	mul	s2,s2,a5
    80002178:	994e                	add	s2,s2,s3
    8000217a:	00000797          	auipc	a5,0x0
    8000217e:	cd078793          	addi	a5,a5,-816 # 80001e4a <forkret>
    80002182:	06f93023          	sd	a5,96(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002186:	04093783          	ld	a5,64(s2)
    8000218a:	6705                	lui	a4,0x1
    8000218c:	97ba                	add	a5,a5,a4
    8000218e:	06f93423          	sd	a5,104(s2)
  return p;
    80002192:	b73d                	j	800020c0 <allocproc+0x64>
    freeproc(p);
    80002194:	8526                	mv	a0,s1
    80002196:	00000097          	auipc	ra,0x0
    8000219a:	e22080e7          	jalr	-478(ra) # 80001fb8 <freeproc>
    release(&p->lock);
    8000219e:	8526                	mv	a0,s1
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	af8080e7          	jalr	-1288(ra) # 80000c98 <release>
    return 0;
    800021a8:	84d6                	mv	s1,s5
    800021aa:	bf19                	j	800020c0 <allocproc+0x64>
    freeproc(p);
    800021ac:	8526                	mv	a0,s1
    800021ae:	00000097          	auipc	ra,0x0
    800021b2:	e0a080e7          	jalr	-502(ra) # 80001fb8 <freeproc>
    release(&p->lock);
    800021b6:	8526                	mv	a0,s1
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	ae0080e7          	jalr	-1312(ra) # 80000c98 <release>
    return 0;
    800021c0:	84d2                	mv	s1,s4
    800021c2:	bdfd                	j	800020c0 <allocproc+0x64>
  return 0;
    800021c4:	4481                	li	s1,0
    800021c6:	bded                	j	800020c0 <allocproc+0x64>

00000000800021c8 <userinit>:
{
    800021c8:	1101                	addi	sp,sp,-32
    800021ca:	ec06                	sd	ra,24(sp)
    800021cc:	e822                	sd	s0,16(sp)
    800021ce:	e426                	sd	s1,8(sp)
    800021d0:	1000                	addi	s0,sp,32
  p = allocproc();
    800021d2:	00000097          	auipc	ra,0x0
    800021d6:	e8a080e7          	jalr	-374(ra) # 8000205c <allocproc>
    800021da:	84aa                	mv	s1,a0
  initproc = p;
    800021dc:	00007797          	auipc	a5,0x7
    800021e0:	e4a7b623          	sd	a0,-436(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800021e4:	03400613          	li	a2,52
    800021e8:	00007597          	auipc	a1,0x7
    800021ec:	92858593          	addi	a1,a1,-1752 # 80008b10 <initcode>
    800021f0:	6928                	ld	a0,80(a0)
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	176080e7          	jalr	374(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    800021fa:	6785                	lui	a5,0x1
    800021fc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    800021fe:	6cb8                	ld	a4,88(s1)
    80002200:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002204:	6cb8                	ld	a4,88(s1)
    80002206:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002208:	4641                	li	a2,16
    8000220a:	00006597          	auipc	a1,0x6
    8000220e:	12658593          	addi	a1,a1,294 # 80008330 <digits+0x2f0>
    80002212:	15848513          	addi	a0,s1,344
    80002216:	fffff097          	auipc	ra,0xfffff
    8000221a:	c1c080e7          	jalr	-996(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    8000221e:	00006517          	auipc	a0,0x6
    80002222:	12250513          	addi	a0,a0,290 # 80008340 <digits+0x300>
    80002226:	00002097          	auipc	ra,0x2
    8000222a:	440080e7          	jalr	1088(ra) # 80004666 <namei>
    8000222e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80002232:	478d                	li	a5,3
    80002234:	cc9c                	sw	a5,24(s1)
  printf("insert userinit runnable %d\n", p->index); //delete
    80002236:	16c4a583          	lw	a1,364(s1)
    8000223a:	00006517          	auipc	a0,0x6
    8000223e:	10e50513          	addi	a0,a0,270 # 80008348 <digits+0x308>
    80002242:	ffffe097          	auipc	ra,0xffffe
    80002246:	346080e7          	jalr	838(ra) # 80000588 <printf>
  insert_proc_to_list(&(cpus[0].runnable_list), p); // admit the init process (the first process in the OS) to the first CPU’s list.
    8000224a:	85a6                	mv	a1,s1
    8000224c:	0000f517          	auipc	a0,0xf
    80002250:	0d450513          	addi	a0,a0,212 # 80011320 <cpus+0x80>
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	7b2080e7          	jalr	1970(ra) # 80001a06 <insert_proc_to_list>
  release(&p->lock);
    8000225c:	8526                	mv	a0,s1
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	a3a080e7          	jalr	-1478(ra) # 80000c98 <release>
}
    80002266:	60e2                	ld	ra,24(sp)
    80002268:	6442                	ld	s0,16(sp)
    8000226a:	64a2                	ld	s1,8(sp)
    8000226c:	6105                	addi	sp,sp,32
    8000226e:	8082                	ret

0000000080002270 <growproc>:
{
    80002270:	1101                	addi	sp,sp,-32
    80002272:	ec06                	sd	ra,24(sp)
    80002274:	e822                	sd	s0,16(sp)
    80002276:	e426                	sd	s1,8(sp)
    80002278:	e04a                	sd	s2,0(sp)
    8000227a:	1000                	addi	s0,sp,32
    8000227c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000227e:	00000097          	auipc	ra,0x0
    80002282:	b8e080e7          	jalr	-1138(ra) # 80001e0c <myproc>
    80002286:	892a                	mv	s2,a0
  sz = p->sz;
    80002288:	652c                	ld	a1,72(a0)
    8000228a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000228e:	00904f63          	bgtz	s1,800022ac <growproc+0x3c>
  } else if(n < 0){
    80002292:	0204cc63          	bltz	s1,800022ca <growproc+0x5a>
  p->sz = sz;
    80002296:	1602                	slli	a2,a2,0x20
    80002298:	9201                	srli	a2,a2,0x20
    8000229a:	04c93423          	sd	a2,72(s2)
  return 0;
    8000229e:	4501                	li	a0,0
}
    800022a0:	60e2                	ld	ra,24(sp)
    800022a2:	6442                	ld	s0,16(sp)
    800022a4:	64a2                	ld	s1,8(sp)
    800022a6:	6902                	ld	s2,0(sp)
    800022a8:	6105                	addi	sp,sp,32
    800022aa:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800022ac:	9e25                	addw	a2,a2,s1
    800022ae:	1602                	slli	a2,a2,0x20
    800022b0:	9201                	srli	a2,a2,0x20
    800022b2:	1582                	slli	a1,a1,0x20
    800022b4:	9181                	srli	a1,a1,0x20
    800022b6:	6928                	ld	a0,80(a0)
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	16a080e7          	jalr	362(ra) # 80001422 <uvmalloc>
    800022c0:	0005061b          	sext.w	a2,a0
    800022c4:	fa69                	bnez	a2,80002296 <growproc+0x26>
      return -1;
    800022c6:	557d                	li	a0,-1
    800022c8:	bfe1                	j	800022a0 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800022ca:	9e25                	addw	a2,a2,s1
    800022cc:	1602                	slli	a2,a2,0x20
    800022ce:	9201                	srli	a2,a2,0x20
    800022d0:	1582                	slli	a1,a1,0x20
    800022d2:	9181                	srli	a1,a1,0x20
    800022d4:	6928                	ld	a0,80(a0)
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	104080e7          	jalr	260(ra) # 800013da <uvmdealloc>
    800022de:	0005061b          	sext.w	a2,a0
    800022e2:	bf55                	j	80002296 <growproc+0x26>

00000000800022e4 <scheduler>:
{
    800022e4:	7159                	addi	sp,sp,-112
    800022e6:	f486                	sd	ra,104(sp)
    800022e8:	f0a2                	sd	s0,96(sp)
    800022ea:	eca6                	sd	s1,88(sp)
    800022ec:	e8ca                	sd	s2,80(sp)
    800022ee:	e4ce                	sd	s3,72(sp)
    800022f0:	e0d2                	sd	s4,64(sp)
    800022f2:	fc56                	sd	s5,56(sp)
    800022f4:	f85a                	sd	s6,48(sp)
    800022f6:	f45e                	sd	s7,40(sp)
    800022f8:	f062                	sd	s8,32(sp)
    800022fa:	ec66                	sd	s9,24(sp)
    800022fc:	e86a                	sd	s10,16(sp)
    800022fe:	e46e                	sd	s11,8(sp)
    80002300:	1880                	addi	s0,sp,112
    80002302:	8712                	mv	a4,tp
  int id = r_tp();
    80002304:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002306:	0000fc97          	auipc	s9,0xf
    8000230a:	f9ac8c93          	addi	s9,s9,-102 # 800112a0 <cpus>
    8000230e:	0b000793          	li	a5,176
    80002312:	02f707b3          	mul	a5,a4,a5
    80002316:	00fc86b3          	add	a3,s9,a5
    8000231a:	0006b023          	sd	zero,0(a3)
    if(!isEmpty(&(c->runnable_list))) { // check whether there is a ready process in the cpu
    8000231e:	08078d13          	addi	s10,a5,128 # 1080 <_entry-0x7fffef80>
    80002322:	9d66                	add	s10,s10,s9
        swtch(&c->context, &p->context);
    80002324:	07a1                	addi	a5,a5,8
    80002326:	9cbe                	add	s9,s9,a5
  return lst->head == -1;
    80002328:	8ab6                	mv	s5,a3
    if(!isEmpty(&(c->runnable_list))) { // check whether there is a ready process in the cpu
    8000232a:	597d                	li	s2,-1
    8000232c:	17800b93          	li	s7,376
      p =  &proc[c->runnable_list.head]; //  pick the first process from the correct CPU’s list.
    80002330:	0000fb17          	auipc	s6,0xf
    80002334:	520b0b13          	addi	s6,s6,1312 # 80011850 <proc>
      if(p->state == RUNNABLE) {  
    80002338:	4c0d                	li	s8,3
        p->state = RUNNING;
    8000233a:	4d91                	li	s11,4
    8000233c:	a031                	j	80002348 <scheduler+0x64>
      release(&p->lock);
    8000233e:	854e                	mv	a0,s3
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	958080e7          	jalr	-1704(ra) # 80000c98 <release>
  return lst->head == -1;
    80002348:	080aa483          	lw	s1,128(s5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000234c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002350:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002354:	10079073          	csrw	sstatus,a5
    if(!isEmpty(&(c->runnable_list))) { // check whether there is a ready process in the cpu
    80002358:	ff248ae3          	beq	s1,s2,8000234c <scheduler+0x68>
      p =  &proc[c->runnable_list.head]; //  pick the first process from the correct CPU’s list.
    8000235c:	03748a33          	mul	s4,s1,s7
    80002360:	016a09b3          	add	s3,s4,s6
      acquire(&p->lock);
    80002364:	854e                	mv	a0,s3
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	87e080e7          	jalr	-1922(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {  
    8000236e:	0189a783          	lw	a5,24(s3)
    80002372:	fd8796e3          	bne	a5,s8,8000233e <scheduler+0x5a>
        printf("remove sched runnable %d\n", p->index); //delete
    80002376:	16c9a583          	lw	a1,364(s3)
    8000237a:	00006517          	auipc	a0,0x6
    8000237e:	fee50513          	addi	a0,a0,-18 # 80008368 <digits+0x328>
    80002382:	ffffe097          	auipc	ra,0xffffe
    80002386:	206080e7          	jalr	518(ra) # 80000588 <printf>
        remove_proc_to_list(&(c->runnable_list), p);
    8000238a:	85ce                	mv	a1,s3
    8000238c:	856a                	mv	a0,s10
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	764080e7          	jalr	1892(ra) # 80001af2 <remove_proc_to_list>
        p->state = RUNNING;
    80002396:	01b9ac23          	sw	s11,24(s3)
        c->proc = p;
    8000239a:	013ab023          	sd	s3,0(s5)
        p->last_cpu = c->cpu_id;
    8000239e:	0a0aa783          	lw	a5,160(s5)
    800023a2:	16f9a423          	sw	a5,360(s3)
        printf("before swtch%d\n", p->index); //delete
    800023a6:	16c9a583          	lw	a1,364(s3)
    800023aa:	00006517          	auipc	a0,0x6
    800023ae:	fde50513          	addi	a0,a0,-34 # 80008388 <digits+0x348>
    800023b2:	ffffe097          	auipc	ra,0xffffe
    800023b6:	1d6080e7          	jalr	470(ra) # 80000588 <printf>
        swtch(&c->context, &p->context);
    800023ba:	060a0593          	addi	a1,s4,96
    800023be:	95da                	add	a1,a1,s6
    800023c0:	8566                	mv	a0,s9
    800023c2:	00001097          	auipc	ra,0x1
    800023c6:	a0e080e7          	jalr	-1522(ra) # 80002dd0 <swtch>
        printf("after swtch%d\n", p->index); //delete
    800023ca:	16c9a583          	lw	a1,364(s3)
    800023ce:	00006517          	auipc	a0,0x6
    800023d2:	fca50513          	addi	a0,a0,-54 # 80008398 <digits+0x358>
    800023d6:	ffffe097          	auipc	ra,0xffffe
    800023da:	1b2080e7          	jalr	434(ra) # 80000588 <printf>
        c->proc = 0;
    800023de:	000ab023          	sd	zero,0(s5)
    800023e2:	bfb1                	j	8000233e <scheduler+0x5a>

00000000800023e4 <sched>:
{
    800023e4:	7179                	addi	sp,sp,-48
    800023e6:	f406                	sd	ra,40(sp)
    800023e8:	f022                	sd	s0,32(sp)
    800023ea:	ec26                	sd	s1,24(sp)
    800023ec:	e84a                	sd	s2,16(sp)
    800023ee:	e44e                	sd	s3,8(sp)
    800023f0:	e052                	sd	s4,0(sp)
    800023f2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800023f4:	00000097          	auipc	ra,0x0
    800023f8:	a18080e7          	jalr	-1512(ra) # 80001e0c <myproc>
    800023fc:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800023fe:	ffffe097          	auipc	ra,0xffffe
    80002402:	76c080e7          	jalr	1900(ra) # 80000b6a <holding>
    80002406:	c145                	beqz	a0,800024a6 <sched+0xc2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002408:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000240a:	2781                	sext.w	a5,a5
    8000240c:	0b000713          	li	a4,176
    80002410:	02e787b3          	mul	a5,a5,a4
    80002414:	0000f717          	auipc	a4,0xf
    80002418:	e8c70713          	addi	a4,a4,-372 # 800112a0 <cpus>
    8000241c:	97ba                	add	a5,a5,a4
    8000241e:	5fb8                	lw	a4,120(a5)
    80002420:	4785                	li	a5,1
    80002422:	08f71a63          	bne	a4,a5,800024b6 <sched+0xd2>
  if(p->state == RUNNING)
    80002426:	4c98                	lw	a4,24(s1)
    80002428:	4791                	li	a5,4
    8000242a:	08f70e63          	beq	a4,a5,800024c6 <sched+0xe2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000242e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002432:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002434:	e3cd                	bnez	a5,800024d6 <sched+0xf2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002436:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002438:	0000f917          	auipc	s2,0xf
    8000243c:	e6890913          	addi	s2,s2,-408 # 800112a0 <cpus>
    80002440:	2781                	sext.w	a5,a5
    80002442:	0b000993          	li	s3,176
    80002446:	033787b3          	mul	a5,a5,s3
    8000244a:	97ca                	add	a5,a5,s2
    8000244c:	07c7aa03          	lw	s4,124(a5)
  printf("before sched swtch status \n"); //delete
    80002450:	00006517          	auipc	a0,0x6
    80002454:	fa050513          	addi	a0,a0,-96 # 800083f0 <digits+0x3b0>
    80002458:	ffffe097          	auipc	ra,0xffffe
    8000245c:	130080e7          	jalr	304(ra) # 80000588 <printf>
    80002460:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    80002462:	2581                	sext.w	a1,a1
    80002464:	033585b3          	mul	a1,a1,s3
    80002468:	05a1                	addi	a1,a1,8
    8000246a:	95ca                	add	a1,a1,s2
    8000246c:	06048513          	addi	a0,s1,96
    80002470:	00001097          	auipc	ra,0x1
    80002474:	960080e7          	jalr	-1696(ra) # 80002dd0 <swtch>
  printf("after sched swtch  status \n"); //delete
    80002478:	00006517          	auipc	a0,0x6
    8000247c:	f9850513          	addi	a0,a0,-104 # 80008410 <digits+0x3d0>
    80002480:	ffffe097          	auipc	ra,0xffffe
    80002484:	108080e7          	jalr	264(ra) # 80000588 <printf>
    80002488:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000248a:	2781                	sext.w	a5,a5
    8000248c:	033787b3          	mul	a5,a5,s3
    80002490:	993e                	add	s2,s2,a5
    80002492:	07492e23          	sw	s4,124(s2)
}
    80002496:	70a2                	ld	ra,40(sp)
    80002498:	7402                	ld	s0,32(sp)
    8000249a:	64e2                	ld	s1,24(sp)
    8000249c:	6942                	ld	s2,16(sp)
    8000249e:	69a2                	ld	s3,8(sp)
    800024a0:	6a02                	ld	s4,0(sp)
    800024a2:	6145                	addi	sp,sp,48
    800024a4:	8082                	ret
    panic("sched p->lock");
    800024a6:	00006517          	auipc	a0,0x6
    800024aa:	f0250513          	addi	a0,a0,-254 # 800083a8 <digits+0x368>
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	090080e7          	jalr	144(ra) # 8000053e <panic>
    panic("sched locks");
    800024b6:	00006517          	auipc	a0,0x6
    800024ba:	f0250513          	addi	a0,a0,-254 # 800083b8 <digits+0x378>
    800024be:	ffffe097          	auipc	ra,0xffffe
    800024c2:	080080e7          	jalr	128(ra) # 8000053e <panic>
    panic("sched running");
    800024c6:	00006517          	auipc	a0,0x6
    800024ca:	f0250513          	addi	a0,a0,-254 # 800083c8 <digits+0x388>
    800024ce:	ffffe097          	auipc	ra,0xffffe
    800024d2:	070080e7          	jalr	112(ra) # 8000053e <panic>
    panic("sched interruptible");
    800024d6:	00006517          	auipc	a0,0x6
    800024da:	f0250513          	addi	a0,a0,-254 # 800083d8 <digits+0x398>
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	060080e7          	jalr	96(ra) # 8000053e <panic>

00000000800024e6 <yield>:
{
    800024e6:	1101                	addi	sp,sp,-32
    800024e8:	ec06                	sd	ra,24(sp)
    800024ea:	e822                	sd	s0,16(sp)
    800024ec:	e426                	sd	s1,8(sp)
    800024ee:	e04a                	sd	s2,0(sp)
    800024f0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800024f2:	00000097          	auipc	ra,0x0
    800024f6:	91a080e7          	jalr	-1766(ra) # 80001e0c <myproc>
    800024fa:	84aa                	mv	s1,a0
    800024fc:	8912                	mv	s2,tp
  acquire(&p->lock);
    800024fe:	ffffe097          	auipc	ra,0xffffe
    80002502:	6e6080e7          	jalr	1766(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002506:	478d                	li	a5,3
    80002508:	cc9c                	sw	a5,24(s1)
  printf("insert yield runnable %d\n", p->index); //delete
    8000250a:	16c4a583          	lw	a1,364(s1)
    8000250e:	00006517          	auipc	a0,0x6
    80002512:	f2250513          	addi	a0,a0,-222 # 80008430 <digits+0x3f0>
    80002516:	ffffe097          	auipc	ra,0xffffe
    8000251a:	072080e7          	jalr	114(ra) # 80000588 <printf>
  insert_proc_to_list(&(c->runnable_list), p); // TODO: check
    8000251e:	2901                	sext.w	s2,s2
    80002520:	0b000513          	li	a0,176
    80002524:	02a90933          	mul	s2,s2,a0
    80002528:	85a6                	mv	a1,s1
    8000252a:	0000f517          	auipc	a0,0xf
    8000252e:	df650513          	addi	a0,a0,-522 # 80011320 <cpus+0x80>
    80002532:	954a                	add	a0,a0,s2
    80002534:	fffff097          	auipc	ra,0xfffff
    80002538:	4d2080e7          	jalr	1234(ra) # 80001a06 <insert_proc_to_list>
  sched();
    8000253c:	00000097          	auipc	ra,0x0
    80002540:	ea8080e7          	jalr	-344(ra) # 800023e4 <sched>
  release(&p->lock);
    80002544:	8526                	mv	a0,s1
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	752080e7          	jalr	1874(ra) # 80000c98 <release>
}
    8000254e:	60e2                	ld	ra,24(sp)
    80002550:	6442                	ld	s0,16(sp)
    80002552:	64a2                	ld	s1,8(sp)
    80002554:	6902                	ld	s2,0(sp)
    80002556:	6105                	addi	sp,sp,32
    80002558:	8082                	ret

000000008000255a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000255a:	7179                	addi	sp,sp,-48
    8000255c:	f406                	sd	ra,40(sp)
    8000255e:	f022                	sd	s0,32(sp)
    80002560:	ec26                	sd	s1,24(sp)
    80002562:	e84a                	sd	s2,16(sp)
    80002564:	e44e                	sd	s3,8(sp)
    80002566:	1800                	addi	s0,sp,48
    80002568:	89aa                	mv	s3,a0
    8000256a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000256c:	00000097          	auipc	ra,0x0
    80002570:	8a0080e7          	jalr	-1888(ra) # 80001e0c <myproc>
    80002574:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	66e080e7          	jalr	1646(ra) # 80000be4 <acquire>
  release(lk);
    8000257e:	854a                	mv	a0,s2
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	718080e7          	jalr	1816(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002588:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000258c:	4789                	li	a5,2
    8000258e:	cc9c                	sw	a5,24(s1)
  printf("insert sleep sleep %d\n", p->index); //delete
    80002590:	16c4a583          	lw	a1,364(s1)
    80002594:	00006517          	auipc	a0,0x6
    80002598:	ebc50513          	addi	a0,a0,-324 # 80008450 <digits+0x410>
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	fec080e7          	jalr	-20(ra) # 80000588 <printf>
  insert_proc_to_list(&sleeping_list, p);
    800025a4:	85a6                	mv	a1,s1
    800025a6:	00006517          	auipc	a0,0x6
    800025aa:	52a50513          	addi	a0,a0,1322 # 80008ad0 <sleeping_list>
    800025ae:	fffff097          	auipc	ra,0xfffff
    800025b2:	458080e7          	jalr	1112(ra) # 80001a06 <insert_proc_to_list>

  sched();
    800025b6:	00000097          	auipc	ra,0x0
    800025ba:	e2e080e7          	jalr	-466(ra) # 800023e4 <sched>

  // Tidy up.
  p->chan = 0;
    800025be:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800025c2:	8526                	mv	a0,s1
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	6d4080e7          	jalr	1748(ra) # 80000c98 <release>
  acquire(lk);
    800025cc:	854a                	mv	a0,s2
    800025ce:	ffffe097          	auipc	ra,0xffffe
    800025d2:	616080e7          	jalr	1558(ra) # 80000be4 <acquire>
}
    800025d6:	70a2                	ld	ra,40(sp)
    800025d8:	7402                	ld	s0,32(sp)
    800025da:	64e2                	ld	s1,24(sp)
    800025dc:	6942                	ld	s2,16(sp)
    800025de:	69a2                	ld	s3,8(sp)
    800025e0:	6145                	addi	sp,sp,48
    800025e2:	8082                	ret

00000000800025e4 <wait>:
{
    800025e4:	715d                	addi	sp,sp,-80
    800025e6:	e486                	sd	ra,72(sp)
    800025e8:	e0a2                	sd	s0,64(sp)
    800025ea:	fc26                	sd	s1,56(sp)
    800025ec:	f84a                	sd	s2,48(sp)
    800025ee:	f44e                	sd	s3,40(sp)
    800025f0:	f052                	sd	s4,32(sp)
    800025f2:	ec56                	sd	s5,24(sp)
    800025f4:	e85a                	sd	s6,16(sp)
    800025f6:	e45e                	sd	s7,8(sp)
    800025f8:	e062                	sd	s8,0(sp)
    800025fa:	0880                	addi	s0,sp,80
    800025fc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025fe:	00000097          	auipc	ra,0x0
    80002602:	80e080e7          	jalr	-2034(ra) # 80001e0c <myproc>
    80002606:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002608:	0000f517          	auipc	a0,0xf
    8000260c:	23050513          	addi	a0,a0,560 # 80011838 <wait_lock>
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	5d4080e7          	jalr	1492(ra) # 80000be4 <acquire>
    havekids = 0;
    80002618:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000261a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000261c:	00015997          	auipc	s3,0x15
    80002620:	03498993          	addi	s3,s3,52 # 80017650 <tickslock>
        havekids = 1;
    80002624:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002626:	0000fc17          	auipc	s8,0xf
    8000262a:	212c0c13          	addi	s8,s8,530 # 80011838 <wait_lock>
    havekids = 0;
    8000262e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002630:	0000f497          	auipc	s1,0xf
    80002634:	22048493          	addi	s1,s1,544 # 80011850 <proc>
    80002638:	a0bd                	j	800026a6 <wait+0xc2>
          pid = np->pid;
    8000263a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000263e:	000b0e63          	beqz	s6,8000265a <wait+0x76>
    80002642:	4691                	li	a3,4
    80002644:	02c48613          	addi	a2,s1,44
    80002648:	85da                	mv	a1,s6
    8000264a:	05093503          	ld	a0,80(s2)
    8000264e:	fffff097          	auipc	ra,0xfffff
    80002652:	024080e7          	jalr	36(ra) # 80001672 <copyout>
    80002656:	02054563          	bltz	a0,80002680 <wait+0x9c>
          freeproc(np);
    8000265a:	8526                	mv	a0,s1
    8000265c:	00000097          	auipc	ra,0x0
    80002660:	95c080e7          	jalr	-1700(ra) # 80001fb8 <freeproc>
          release(&np->lock);
    80002664:	8526                	mv	a0,s1
    80002666:	ffffe097          	auipc	ra,0xffffe
    8000266a:	632080e7          	jalr	1586(ra) # 80000c98 <release>
          release(&wait_lock);
    8000266e:	0000f517          	auipc	a0,0xf
    80002672:	1ca50513          	addi	a0,a0,458 # 80011838 <wait_lock>
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	622080e7          	jalr	1570(ra) # 80000c98 <release>
          return pid;
    8000267e:	a09d                	j	800026e4 <wait+0x100>
            release(&np->lock);
    80002680:	8526                	mv	a0,s1
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	616080e7          	jalr	1558(ra) # 80000c98 <release>
            release(&wait_lock);
    8000268a:	0000f517          	auipc	a0,0xf
    8000268e:	1ae50513          	addi	a0,a0,430 # 80011838 <wait_lock>
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	606080e7          	jalr	1542(ra) # 80000c98 <release>
            return -1;
    8000269a:	59fd                	li	s3,-1
    8000269c:	a0a1                	j	800026e4 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000269e:	17848493          	addi	s1,s1,376
    800026a2:	03348463          	beq	s1,s3,800026ca <wait+0xe6>
      if(np->parent == p){
    800026a6:	7c9c                	ld	a5,56(s1)
    800026a8:	ff279be3          	bne	a5,s2,8000269e <wait+0xba>
        acquire(&np->lock);
    800026ac:	8526                	mv	a0,s1
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	536080e7          	jalr	1334(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800026b6:	4c9c                	lw	a5,24(s1)
    800026b8:	f94781e3          	beq	a5,s4,8000263a <wait+0x56>
        release(&np->lock);
    800026bc:	8526                	mv	a0,s1
    800026be:	ffffe097          	auipc	ra,0xffffe
    800026c2:	5da080e7          	jalr	1498(ra) # 80000c98 <release>
        havekids = 1;
    800026c6:	8756                	mv	a4,s5
    800026c8:	bfd9                	j	8000269e <wait+0xba>
    if(!havekids || p->killed){
    800026ca:	c701                	beqz	a4,800026d2 <wait+0xee>
    800026cc:	02892783          	lw	a5,40(s2)
    800026d0:	c79d                	beqz	a5,800026fe <wait+0x11a>
      release(&wait_lock);
    800026d2:	0000f517          	auipc	a0,0xf
    800026d6:	16650513          	addi	a0,a0,358 # 80011838 <wait_lock>
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	5be080e7          	jalr	1470(ra) # 80000c98 <release>
      return -1;
    800026e2:	59fd                	li	s3,-1
}
    800026e4:	854e                	mv	a0,s3
    800026e6:	60a6                	ld	ra,72(sp)
    800026e8:	6406                	ld	s0,64(sp)
    800026ea:	74e2                	ld	s1,56(sp)
    800026ec:	7942                	ld	s2,48(sp)
    800026ee:	79a2                	ld	s3,40(sp)
    800026f0:	7a02                	ld	s4,32(sp)
    800026f2:	6ae2                	ld	s5,24(sp)
    800026f4:	6b42                	ld	s6,16(sp)
    800026f6:	6ba2                	ld	s7,8(sp)
    800026f8:	6c02                	ld	s8,0(sp)
    800026fa:	6161                	addi	sp,sp,80
    800026fc:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026fe:	85e2                	mv	a1,s8
    80002700:	854a                	mv	a0,s2
    80002702:	00000097          	auipc	ra,0x0
    80002706:	e58080e7          	jalr	-424(ra) # 8000255a <sleep>
    havekids = 0;
    8000270a:	b715                	j	8000262e <wait+0x4a>

000000008000270c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000270c:	7179                	addi	sp,sp,-48
    8000270e:	f406                	sd	ra,40(sp)
    80002710:	f022                	sd	s0,32(sp)
    80002712:	ec26                	sd	s1,24(sp)
    80002714:	e84a                	sd	s2,16(sp)
    80002716:	e44e                	sd	s3,8(sp)
    80002718:	1800                	addi	s0,sp,48
    8000271a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000271c:	0000f497          	auipc	s1,0xf
    80002720:	13448493          	addi	s1,s1,308 # 80011850 <proc>
    80002724:	00015997          	auipc	s3,0x15
    80002728:	f2c98993          	addi	s3,s3,-212 # 80017650 <tickslock>
    acquire(&p->lock);
    8000272c:	8526                	mv	a0,s1
    8000272e:	ffffe097          	auipc	ra,0xffffe
    80002732:	4b6080e7          	jalr	1206(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002736:	589c                	lw	a5,48(s1)
    80002738:	01278d63          	beq	a5,s2,80002752 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000273c:	8526                	mv	a0,s1
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	55a080e7          	jalr	1370(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002746:	17848493          	addi	s1,s1,376
    8000274a:	ff3491e3          	bne	s1,s3,8000272c <kill+0x20>
  }
  return -1;
    8000274e:	557d                	li	a0,-1
    80002750:	a829                	j	8000276a <kill+0x5e>
      p->killed = 1;
    80002752:	4785                	li	a5,1
    80002754:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002756:	4c98                	lw	a4,24(s1)
    80002758:	4789                	li	a5,2
    8000275a:	00f70f63          	beq	a4,a5,80002778 <kill+0x6c>
      release(&p->lock);
    8000275e:	8526                	mv	a0,s1
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	538080e7          	jalr	1336(ra) # 80000c98 <release>
      return 0;
    80002768:	4501                	li	a0,0
}
    8000276a:	70a2                	ld	ra,40(sp)
    8000276c:	7402                	ld	s0,32(sp)
    8000276e:	64e2                	ld	s1,24(sp)
    80002770:	6942                	ld	s2,16(sp)
    80002772:	69a2                	ld	s3,8(sp)
    80002774:	6145                	addi	sp,sp,48
    80002776:	8082                	ret
        p->state = RUNNABLE;
    80002778:	478d                	li	a5,3
    8000277a:	cc9c                	sw	a5,24(s1)
    8000277c:	b7cd                	j	8000275e <kill+0x52>

000000008000277e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000277e:	7179                	addi	sp,sp,-48
    80002780:	f406                	sd	ra,40(sp)
    80002782:	f022                	sd	s0,32(sp)
    80002784:	ec26                	sd	s1,24(sp)
    80002786:	e84a                	sd	s2,16(sp)
    80002788:	e44e                	sd	s3,8(sp)
    8000278a:	e052                	sd	s4,0(sp)
    8000278c:	1800                	addi	s0,sp,48
    8000278e:	84aa                	mv	s1,a0
    80002790:	892e                	mv	s2,a1
    80002792:	89b2                	mv	s3,a2
    80002794:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002796:	fffff097          	auipc	ra,0xfffff
    8000279a:	676080e7          	jalr	1654(ra) # 80001e0c <myproc>
  if(user_dst){
    8000279e:	c08d                	beqz	s1,800027c0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027a0:	86d2                	mv	a3,s4
    800027a2:	864e                	mv	a2,s3
    800027a4:	85ca                	mv	a1,s2
    800027a6:	6928                	ld	a0,80(a0)
    800027a8:	fffff097          	auipc	ra,0xfffff
    800027ac:	eca080e7          	jalr	-310(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027b0:	70a2                	ld	ra,40(sp)
    800027b2:	7402                	ld	s0,32(sp)
    800027b4:	64e2                	ld	s1,24(sp)
    800027b6:	6942                	ld	s2,16(sp)
    800027b8:	69a2                	ld	s3,8(sp)
    800027ba:	6a02                	ld	s4,0(sp)
    800027bc:	6145                	addi	sp,sp,48
    800027be:	8082                	ret
    memmove((char *)dst, src, len);
    800027c0:	000a061b          	sext.w	a2,s4
    800027c4:	85ce                	mv	a1,s3
    800027c6:	854a                	mv	a0,s2
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	578080e7          	jalr	1400(ra) # 80000d40 <memmove>
    return 0;
    800027d0:	8526                	mv	a0,s1
    800027d2:	bff9                	j	800027b0 <either_copyout+0x32>

00000000800027d4 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027d4:	7179                	addi	sp,sp,-48
    800027d6:	f406                	sd	ra,40(sp)
    800027d8:	f022                	sd	s0,32(sp)
    800027da:	ec26                	sd	s1,24(sp)
    800027dc:	e84a                	sd	s2,16(sp)
    800027de:	e44e                	sd	s3,8(sp)
    800027e0:	e052                	sd	s4,0(sp)
    800027e2:	1800                	addi	s0,sp,48
    800027e4:	892a                	mv	s2,a0
    800027e6:	84ae                	mv	s1,a1
    800027e8:	89b2                	mv	s3,a2
    800027ea:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027ec:	fffff097          	auipc	ra,0xfffff
    800027f0:	620080e7          	jalr	1568(ra) # 80001e0c <myproc>
  if(user_src){
    800027f4:	c08d                	beqz	s1,80002816 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800027f6:	86d2                	mv	a3,s4
    800027f8:	864e                	mv	a2,s3
    800027fa:	85ca                	mv	a1,s2
    800027fc:	6928                	ld	a0,80(a0)
    800027fe:	fffff097          	auipc	ra,0xfffff
    80002802:	f00080e7          	jalr	-256(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002806:	70a2                	ld	ra,40(sp)
    80002808:	7402                	ld	s0,32(sp)
    8000280a:	64e2                	ld	s1,24(sp)
    8000280c:	6942                	ld	s2,16(sp)
    8000280e:	69a2                	ld	s3,8(sp)
    80002810:	6a02                	ld	s4,0(sp)
    80002812:	6145                	addi	sp,sp,48
    80002814:	8082                	ret
    memmove(dst, (char*)src, len);
    80002816:	000a061b          	sext.w	a2,s4
    8000281a:	85ce                	mv	a1,s3
    8000281c:	854a                	mv	a0,s2
    8000281e:	ffffe097          	auipc	ra,0xffffe
    80002822:	522080e7          	jalr	1314(ra) # 80000d40 <memmove>
    return 0;
    80002826:	8526                	mv	a0,s1
    80002828:	bff9                	j	80002806 <either_copyin+0x32>

000000008000282a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    8000282a:	715d                	addi	sp,sp,-80
    8000282c:	e486                	sd	ra,72(sp)
    8000282e:	e0a2                	sd	s0,64(sp)
    80002830:	fc26                	sd	s1,56(sp)
    80002832:	f84a                	sd	s2,48(sp)
    80002834:	f44e                	sd	s3,40(sp)
    80002836:	f052                	sd	s4,32(sp)
    80002838:	ec56                	sd	s5,24(sp)
    8000283a:	e85a                	sd	s6,16(sp)
    8000283c:	e45e                	sd	s7,8(sp)
    8000283e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002840:	00006517          	auipc	a0,0x6
    80002844:	b4050513          	addi	a0,a0,-1216 # 80008380 <digits+0x340>
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	d40080e7          	jalr	-704(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002850:	0000f497          	auipc	s1,0xf
    80002854:	15848493          	addi	s1,s1,344 # 800119a8 <proc+0x158>
    80002858:	00015917          	auipc	s2,0x15
    8000285c:	f5090913          	addi	s2,s2,-176 # 800177a8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002860:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    80002862:	00006997          	auipc	s3,0x6
    80002866:	c0698993          	addi	s3,s3,-1018 # 80008468 <digits+0x428>
    printf("%d %s %s", p->pid, state, p->name);
    8000286a:	00006a97          	auipc	s5,0x6
    8000286e:	c06a8a93          	addi	s5,s5,-1018 # 80008470 <digits+0x430>
    printf("\n");
    80002872:	00006a17          	auipc	s4,0x6
    80002876:	b0ea0a13          	addi	s4,s4,-1266 # 80008380 <digits+0x340>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000287a:	00006b97          	auipc	s7,0x6
    8000287e:	cbeb8b93          	addi	s7,s7,-834 # 80008538 <states.1801>
    80002882:	a00d                	j	800028a4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002884:	ed86a583          	lw	a1,-296(a3)
    80002888:	8556                	mv	a0,s5
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	cfe080e7          	jalr	-770(ra) # 80000588 <printf>
    printf("\n");
    80002892:	8552                	mv	a0,s4
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	cf4080e7          	jalr	-780(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000289c:	17848493          	addi	s1,s1,376
    800028a0:	03248163          	beq	s1,s2,800028c2 <procdump+0x98>
    if(p->state == UNUSED)
    800028a4:	86a6                	mv	a3,s1
    800028a6:	ec04a783          	lw	a5,-320(s1)
    800028aa:	dbed                	beqz	a5,8000289c <procdump+0x72>
      state = "???"; 
    800028ac:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ae:	fcfb6be3          	bltu	s6,a5,80002884 <procdump+0x5a>
    800028b2:	1782                	slli	a5,a5,0x20
    800028b4:	9381                	srli	a5,a5,0x20
    800028b6:	078e                	slli	a5,a5,0x3
    800028b8:	97de                	add	a5,a5,s7
    800028ba:	6390                	ld	a2,0(a5)
    800028bc:	f661                	bnez	a2,80002884 <procdump+0x5a>
      state = "???"; 
    800028be:	864e                	mv	a2,s3
    800028c0:	b7d1                	j	80002884 <procdump+0x5a>
  }
}
    800028c2:	60a6                	ld	ra,72(sp)
    800028c4:	6406                	ld	s0,64(sp)
    800028c6:	74e2                	ld	s1,56(sp)
    800028c8:	7942                	ld	s2,48(sp)
    800028ca:	79a2                	ld	s3,40(sp)
    800028cc:	7a02                	ld	s4,32(sp)
    800028ce:	6ae2                	ld	s5,24(sp)
    800028d0:	6b42                	ld	s6,16(sp)
    800028d2:	6ba2                	ld	s7,8(sp)
    800028d4:	6161                	addi	sp,sp,80
    800028d6:	8082                	ret

00000000800028d8 <set_cpu>:

// assign current process to a different CPU. 
int
set_cpu(int cpu_num){
    800028d8:	1101                	addi	sp,sp,-32
    800028da:	ec06                	sd	ra,24(sp)
    800028dc:	e822                	sd	s0,16(sp)
    800028de:	e426                	sd	s1,8(sp)
    800028e0:	e04a                	sd	s2,0(sp)
    800028e2:	1000                	addi	s0,sp,32
    800028e4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800028e6:	fffff097          	auipc	ra,0xfffff
    800028ea:	526080e7          	jalr	1318(ra) # 80001e0c <myproc>
  if(cpu_num >= 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL){
    800028ee:	0004871b          	sext.w	a4,s1
    800028f2:	479d                	li	a5,7
    800028f4:	02e7e963          	bltu	a5,a4,80002926 <set_cpu+0x4e>
    800028f8:	892a                	mv	s2,a0
    acquire(&p->lock);
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	2ea080e7          	jalr	746(ra) # 80000be4 <acquire>
    p->last_cpu = cpu_num;
    80002902:	16992423          	sw	s1,360(s2)
    release(&p->lock);
    80002906:	854a                	mv	a0,s2
    80002908:	ffffe097          	auipc	ra,0xffffe
    8000290c:	390080e7          	jalr	912(ra) # 80000c98 <release>

    yield();
    80002910:	00000097          	auipc	ra,0x0
    80002914:	bd6080e7          	jalr	-1066(ra) # 800024e6 <yield>

    return cpu_num;
    80002918:	8526                	mv	a0,s1
  }
  return -1;
}
    8000291a:	60e2                	ld	ra,24(sp)
    8000291c:	6442                	ld	s0,16(sp)
    8000291e:	64a2                	ld	s1,8(sp)
    80002920:	6902                	ld	s2,0(sp)
    80002922:	6105                	addi	sp,sp,32
    80002924:	8082                	ret
  return -1;
    80002926:	557d                	li	a0,-1
    80002928:	bfcd                	j	8000291a <set_cpu+0x42>

000000008000292a <get_cpu>:

// return the current CPU id.
int
get_cpu(void){
    8000292a:	1141                	addi	sp,sp,-16
    8000292c:	e406                	sd	ra,8(sp)
    8000292e:	e022                	sd	s0,0(sp)
    80002930:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002932:	fffff097          	auipc	ra,0xfffff
    80002936:	4da080e7          	jalr	1242(ra) # 80001e0c <myproc>
  return p->last_cpu;
}
    8000293a:	16852503          	lw	a0,360(a0)
    8000293e:	60a2                	ld	ra,8(sp)
    80002940:	6402                	ld	s0,0(sp)
    80002942:	0141                	addi	sp,sp,16
    80002944:	8082                	ret

0000000080002946 <min_cpu>:

int
min_cpu(void){
    80002946:	1141                	addi	sp,sp,-16
    80002948:	e422                	sd	s0,8(sp)
    8000294a:	0800                	addi	s0,sp,16
  struct cpu *c, *min_cpu;
// should add an if to insure numberOfCpus>0
  min_cpu = cpus;
    8000294c:	0000f617          	auipc	a2,0xf
    80002950:	95460613          	addi	a2,a2,-1708 # 800112a0 <cpus>
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL ; c++){
    80002954:	0000f797          	auipc	a5,0xf
    80002958:	9fc78793          	addi	a5,a5,-1540 # 80011350 <cpus+0xb0>
    8000295c:	0000f597          	auipc	a1,0xf
    80002960:	ec458593          	addi	a1,a1,-316 # 80011820 <pid_lock>
    80002964:	a029                	j	8000296e <min_cpu+0x28>
    80002966:	0b078793          	addi	a5,a5,176
    8000296a:	00b78863          	beq	a5,a1,8000297a <min_cpu+0x34>
    if (c->cpu_process_count < min_cpu->cpu_process_count)
    8000296e:	77d4                	ld	a3,168(a5)
    80002970:	7658                	ld	a4,168(a2)
    80002972:	fee6fae3          	bgeu	a3,a4,80002966 <min_cpu+0x20>
    80002976:	863e                	mv	a2,a5
    80002978:	b7fd                	j	80002966 <min_cpu+0x20>
        min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    8000297a:	0a062503          	lw	a0,160(a2)
    8000297e:	6422                	ld	s0,8(sp)
    80002980:	0141                	addi	sp,sp,16
    80002982:	8082                	ret

0000000080002984 <cpu_process_count>:

int
cpu_process_count(int cpu_num){
    80002984:	1141                	addi	sp,sp,-16
    80002986:	e422                	sd	s0,8(sp)
    80002988:	0800                	addi	s0,sp,16
  if (cpu_num > 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL) 
    8000298a:	fff5071b          	addiw	a4,a0,-1
    8000298e:	4799                	li	a5,6
    80002990:	02e7e063          	bltu	a5,a4,800029b0 <cpu_process_count+0x2c>
    return cpus[cpu_num].cpu_process_count;
    80002994:	0b000793          	li	a5,176
    80002998:	02f50533          	mul	a0,a0,a5
    8000299c:	0000f797          	auipc	a5,0xf
    800029a0:	90478793          	addi	a5,a5,-1788 # 800112a0 <cpus>
    800029a4:	953e                	add	a0,a0,a5
    800029a6:	0a852503          	lw	a0,168(a0)
  return -1;
}
    800029aa:	6422                	ld	s0,8(sp)
    800029ac:	0141                	addi	sp,sp,16
    800029ae:	8082                	ret
  return -1;
    800029b0:	557d                	li	a0,-1
    800029b2:	bfe5                	j	800029aa <cpu_process_count+0x26>

00000000800029b4 <increment_cpu_process_count>:

void 
increment_cpu_process_count(struct cpu *c){
    800029b4:	1101                	addi	sp,sp,-32
    800029b6:	ec06                	sd	ra,24(sp)
    800029b8:	e822                	sd	s0,16(sp)
    800029ba:	e426                	sd	s1,8(sp)
    800029bc:	e04a                	sd	s2,0(sp)
    800029be:	1000                	addi	s0,sp,32
    800029c0:	84aa                	mv	s1,a0
  uint64 curr_count;
  do{
    curr_count = c->cpu_process_count;
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    800029c2:	0a850913          	addi	s2,a0,168
    curr_count = c->cpu_process_count;
    800029c6:	74cc                	ld	a1,168(s1)
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    800029c8:	0015861b          	addiw	a2,a1,1
    800029cc:	2581                	sext.w	a1,a1
    800029ce:	854a                	mv	a0,s2
    800029d0:	00004097          	auipc	ra,0x4
    800029d4:	076080e7          	jalr	118(ra) # 80006a46 <cas>
    800029d8:	2501                	sext.w	a0,a0
    800029da:	f575                	bnez	a0,800029c6 <increment_cpu_process_count+0x12>
}
    800029dc:	60e2                	ld	ra,24(sp)
    800029de:	6442                	ld	s0,16(sp)
    800029e0:	64a2                	ld	s1,8(sp)
    800029e2:	6902                	ld	s2,0(sp)
    800029e4:	6105                	addi	sp,sp,32
    800029e6:	8082                	ret

00000000800029e8 <fork>:
{
    800029e8:	7139                	addi	sp,sp,-64
    800029ea:	fc06                	sd	ra,56(sp)
    800029ec:	f822                	sd	s0,48(sp)
    800029ee:	f426                	sd	s1,40(sp)
    800029f0:	f04a                	sd	s2,32(sp)
    800029f2:	ec4e                	sd	s3,24(sp)
    800029f4:	e852                	sd	s4,16(sp)
    800029f6:	e456                	sd	s5,8(sp)
    800029f8:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800029fa:	fffff097          	auipc	ra,0xfffff
    800029fe:	412080e7          	jalr	1042(ra) # 80001e0c <myproc>
    80002a02:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002a04:	fffff097          	auipc	ra,0xfffff
    80002a08:	658080e7          	jalr	1624(ra) # 8000205c <allocproc>
    80002a0c:	16050063          	beqz	a0,80002b6c <fork+0x184>
    80002a10:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002a12:	0489b603          	ld	a2,72(s3)
    80002a16:	692c                	ld	a1,80(a0)
    80002a18:	0509b503          	ld	a0,80(s3)
    80002a1c:	fffff097          	auipc	ra,0xfffff
    80002a20:	b52080e7          	jalr	-1198(ra) # 8000156e <uvmcopy>
    80002a24:	04054663          	bltz	a0,80002a70 <fork+0x88>
  np->sz = p->sz;
    80002a28:	0489b783          	ld	a5,72(s3)
    80002a2c:	04f93423          	sd	a5,72(s2)
  *(np->trapframe) = *(p->trapframe);
    80002a30:	0589b683          	ld	a3,88(s3)
    80002a34:	87b6                	mv	a5,a3
    80002a36:	05893703          	ld	a4,88(s2)
    80002a3a:	12068693          	addi	a3,a3,288
    80002a3e:	0007b803          	ld	a6,0(a5)
    80002a42:	6788                	ld	a0,8(a5)
    80002a44:	6b8c                	ld	a1,16(a5)
    80002a46:	6f90                	ld	a2,24(a5)
    80002a48:	01073023          	sd	a6,0(a4)
    80002a4c:	e708                	sd	a0,8(a4)
    80002a4e:	eb0c                	sd	a1,16(a4)
    80002a50:	ef10                	sd	a2,24(a4)
    80002a52:	02078793          	addi	a5,a5,32
    80002a56:	02070713          	addi	a4,a4,32
    80002a5a:	fed792e3          	bne	a5,a3,80002a3e <fork+0x56>
  np->trapframe->a0 = 0;
    80002a5e:	05893783          	ld	a5,88(s2)
    80002a62:	0607b823          	sd	zero,112(a5)
    80002a66:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002a6a:	15000a13          	li	s4,336
    80002a6e:	a03d                	j	80002a9c <fork+0xb4>
    freeproc(np);
    80002a70:	854a                	mv	a0,s2
    80002a72:	fffff097          	auipc	ra,0xfffff
    80002a76:	546080e7          	jalr	1350(ra) # 80001fb8 <freeproc>
    release(&np->lock);
    80002a7a:	854a                	mv	a0,s2
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	21c080e7          	jalr	540(ra) # 80000c98 <release>
    return -1;
    80002a84:	5afd                	li	s5,-1
    80002a86:	a8c9                	j	80002b58 <fork+0x170>
      np->ofile[i] = filedup(p->ofile[i]);
    80002a88:	00002097          	auipc	ra,0x2
    80002a8c:	274080e7          	jalr	628(ra) # 80004cfc <filedup>
    80002a90:	009907b3          	add	a5,s2,s1
    80002a94:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002a96:	04a1                	addi	s1,s1,8
    80002a98:	01448763          	beq	s1,s4,80002aa6 <fork+0xbe>
    if(p->ofile[i])
    80002a9c:	009987b3          	add	a5,s3,s1
    80002aa0:	6388                	ld	a0,0(a5)
    80002aa2:	f17d                	bnez	a0,80002a88 <fork+0xa0>
    80002aa4:	bfcd                	j	80002a96 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002aa6:	1509b503          	ld	a0,336(s3)
    80002aaa:	00001097          	auipc	ra,0x1
    80002aae:	3c8080e7          	jalr	968(ra) # 80003e72 <idup>
    80002ab2:	14a93823          	sd	a0,336(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002ab6:	4641                	li	a2,16
    80002ab8:	15898593          	addi	a1,s3,344
    80002abc:	15890513          	addi	a0,s2,344
    80002ac0:	ffffe097          	auipc	ra,0xffffe
    80002ac4:	372080e7          	jalr	882(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002ac8:	03092a83          	lw	s5,48(s2)
  release(&np->lock);
    80002acc:	854a                	mv	a0,s2
    80002ace:	ffffe097          	auipc	ra,0xffffe
    80002ad2:	1ca080e7          	jalr	458(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002ad6:	0000ea17          	auipc	s4,0xe
    80002ada:	7caa0a13          	addi	s4,s4,1994 # 800112a0 <cpus>
    80002ade:	0000f497          	auipc	s1,0xf
    80002ae2:	d5a48493          	addi	s1,s1,-678 # 80011838 <wait_lock>
    80002ae6:	8526                	mv	a0,s1
    80002ae8:	ffffe097          	auipc	ra,0xffffe
    80002aec:	0fc080e7          	jalr	252(ra) # 80000be4 <acquire>
  np->parent = p;
    80002af0:	03393c23          	sd	s3,56(s2)
  release(&wait_lock);
    80002af4:	8526                	mv	a0,s1
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	1a2080e7          	jalr	418(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002afe:	854a                	mv	a0,s2
    80002b00:	ffffe097          	auipc	ra,0xffffe
    80002b04:	0e4080e7          	jalr	228(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002b08:	478d                	li	a5,3
    80002b0a:	00f92c23          	sw	a5,24(s2)
  np->last_cpu = p->last_cpu; // case BLNCFLG=OFF -> cpu = parent's cpu 
    80002b0e:	1689a483          	lw	s1,360(s3)
    80002b12:	16992423          	sw	s1,360(s2)
  struct cpu *c = &cpus[np->last_cpu];
    80002b16:	0b000513          	li	a0,176
    80002b1a:	02a484b3          	mul	s1,s1,a0
  increment_cpu_process_count(c);
    80002b1e:	009a0533          	add	a0,s4,s1
    80002b22:	00000097          	auipc	ra,0x0
    80002b26:	e92080e7          	jalr	-366(ra) # 800029b4 <increment_cpu_process_count>
  printf("insert fork runnable %d\n", np->index); //delete
    80002b2a:	16c92583          	lw	a1,364(s2)
    80002b2e:	00006517          	auipc	a0,0x6
    80002b32:	95250513          	addi	a0,a0,-1710 # 80008480 <digits+0x440>
    80002b36:	ffffe097          	auipc	ra,0xffffe
    80002b3a:	a52080e7          	jalr	-1454(ra) # 80000588 <printf>
  insert_proc_to_list(&(c->runnable_list), np); // admit the new process to the father’s current CPU’s ready list
    80002b3e:	08048513          	addi	a0,s1,128
    80002b42:	85ca                	mv	a1,s2
    80002b44:	9552                	add	a0,a0,s4
    80002b46:	fffff097          	auipc	ra,0xfffff
    80002b4a:	ec0080e7          	jalr	-320(ra) # 80001a06 <insert_proc_to_list>
  release(&np->lock);
    80002b4e:	854a                	mv	a0,s2
    80002b50:	ffffe097          	auipc	ra,0xffffe
    80002b54:	148080e7          	jalr	328(ra) # 80000c98 <release>
}
    80002b58:	8556                	mv	a0,s5
    80002b5a:	70e2                	ld	ra,56(sp)
    80002b5c:	7442                	ld	s0,48(sp)
    80002b5e:	74a2                	ld	s1,40(sp)
    80002b60:	7902                	ld	s2,32(sp)
    80002b62:	69e2                	ld	s3,24(sp)
    80002b64:	6a42                	ld	s4,16(sp)
    80002b66:	6aa2                	ld	s5,8(sp)
    80002b68:	6121                	addi	sp,sp,64
    80002b6a:	8082                	ret
    return -1;
    80002b6c:	5afd                	li	s5,-1
    80002b6e:	b7ed                	j	80002b58 <fork+0x170>

0000000080002b70 <wakeup>:
{
    80002b70:	7159                	addi	sp,sp,-112
    80002b72:	f486                	sd	ra,104(sp)
    80002b74:	f0a2                	sd	s0,96(sp)
    80002b76:	eca6                	sd	s1,88(sp)
    80002b78:	e8ca                	sd	s2,80(sp)
    80002b7a:	e4ce                	sd	s3,72(sp)
    80002b7c:	e0d2                	sd	s4,64(sp)
    80002b7e:	fc56                	sd	s5,56(sp)
    80002b80:	f85a                	sd	s6,48(sp)
    80002b82:	f45e                	sd	s7,40(sp)
    80002b84:	f062                	sd	s8,32(sp)
    80002b86:	ec66                	sd	s9,24(sp)
    80002b88:	e86a                	sd	s10,16(sp)
    80002b8a:	e46e                	sd	s11,8(sp)
    80002b8c:	1880                	addi	s0,sp,112
  int curr = sleeping_list.head;
    80002b8e:	00006917          	auipc	s2,0x6
    80002b92:	f4292903          	lw	s2,-190(s2) # 80008ad0 <sleeping_list>
  while(curr != -1) {
    80002b96:	57fd                	li	a5,-1
    80002b98:	0cf90263          	beq	s2,a5,80002c5c <wakeup+0xec>
    80002b9c:	8baa                	mv	s7,a0
    p = &proc[curr];
    80002b9e:	17800a93          	li	s5,376
    80002ba2:	0000fa17          	auipc	s4,0xf
    80002ba6:	caea0a13          	addi	s4,s4,-850 # 80011850 <proc>
      if(p->state == SLEEPING && p->chan == chan) {
    80002baa:	4b09                	li	s6,2
        p->state = RUNNABLE;
    80002bac:	4d8d                	li	s11,3
    80002bae:	0b000d13          	li	s10,176
        c = &cpus[p->last_cpu];
    80002bb2:	0000ec97          	auipc	s9,0xe
    80002bb6:	6eec8c93          	addi	s9,s9,1774 # 800112a0 <cpus>
    80002bba:	a809                	j	80002bcc <wakeup+0x5c>
      release(&p->lock);
    80002bbc:	8526                	mv	a0,s1
    80002bbe:	ffffe097          	auipc	ra,0xffffe
    80002bc2:	0da080e7          	jalr	218(ra) # 80000c98 <release>
  while(curr != -1) {
    80002bc6:	57fd                	li	a5,-1
    80002bc8:	08f90a63          	beq	s2,a5,80002c5c <wakeup+0xec>
    p = &proc[curr];
    80002bcc:	035904b3          	mul	s1,s2,s5
    80002bd0:	94d2                	add	s1,s1,s4
    curr = p->next_index;
    80002bd2:	1744a903          	lw	s2,372(s1)
    if(p != myproc()){
    80002bd6:	fffff097          	auipc	ra,0xfffff
    80002bda:	236080e7          	jalr	566(ra) # 80001e0c <myproc>
    80002bde:	fea484e3          	beq	s1,a0,80002bc6 <wakeup+0x56>
      acquire(&p->lock);
    80002be2:	8526                	mv	a0,s1
    80002be4:	ffffe097          	auipc	ra,0xffffe
    80002be8:	000080e7          	jalr	ra # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002bec:	4c9c                	lw	a5,24(s1)
    80002bee:	fd6797e3          	bne	a5,s6,80002bbc <wakeup+0x4c>
    80002bf2:	709c                	ld	a5,32(s1)
    80002bf4:	fd7794e3          	bne	a5,s7,80002bbc <wakeup+0x4c>
        printf("remove wakeup sleep %d\n", p->index); //delete
    80002bf8:	16c4a583          	lw	a1,364(s1)
    80002bfc:	00006517          	auipc	a0,0x6
    80002c00:	8a450513          	addi	a0,a0,-1884 # 800084a0 <digits+0x460>
    80002c04:	ffffe097          	auipc	ra,0xffffe
    80002c08:	984080e7          	jalr	-1660(ra) # 80000588 <printf>
        remove_proc_to_list(&sleeping_list, p);
    80002c0c:	85a6                	mv	a1,s1
    80002c0e:	00006517          	auipc	a0,0x6
    80002c12:	ec250513          	addi	a0,a0,-318 # 80008ad0 <sleeping_list>
    80002c16:	fffff097          	auipc	ra,0xfffff
    80002c1a:	edc080e7          	jalr	-292(ra) # 80001af2 <remove_proc_to_list>
        p->state = RUNNABLE;
    80002c1e:	01b4ac23          	sw	s11,24(s1)
        c = &cpus[p->last_cpu];
    80002c22:	1684ac03          	lw	s8,360(s1)
    80002c26:	03ac0c33          	mul	s8,s8,s10
        increment_cpu_process_count(c);
    80002c2a:	018c8533          	add	a0,s9,s8
    80002c2e:	00000097          	auipc	ra,0x0
    80002c32:	d86080e7          	jalr	-634(ra) # 800029b4 <increment_cpu_process_count>
        printf("insert wakeup runnable %d\n", p->index); //delete
    80002c36:	16c4a583          	lw	a1,364(s1)
    80002c3a:	00006517          	auipc	a0,0x6
    80002c3e:	87e50513          	addi	a0,a0,-1922 # 800084b8 <digits+0x478>
    80002c42:	ffffe097          	auipc	ra,0xffffe
    80002c46:	946080e7          	jalr	-1722(ra) # 80000588 <printf>
        insert_proc_to_list(&(c->runnable_list), p);
    80002c4a:	080c0513          	addi	a0,s8,128
    80002c4e:	85a6                	mv	a1,s1
    80002c50:	9566                	add	a0,a0,s9
    80002c52:	fffff097          	auipc	ra,0xfffff
    80002c56:	db4080e7          	jalr	-588(ra) # 80001a06 <insert_proc_to_list>
    80002c5a:	b78d                	j	80002bbc <wakeup+0x4c>
}
    80002c5c:	70a6                	ld	ra,104(sp)
    80002c5e:	7406                	ld	s0,96(sp)
    80002c60:	64e6                	ld	s1,88(sp)
    80002c62:	6946                	ld	s2,80(sp)
    80002c64:	69a6                	ld	s3,72(sp)
    80002c66:	6a06                	ld	s4,64(sp)
    80002c68:	7ae2                	ld	s5,56(sp)
    80002c6a:	7b42                	ld	s6,48(sp)
    80002c6c:	7ba2                	ld	s7,40(sp)
    80002c6e:	7c02                	ld	s8,32(sp)
    80002c70:	6ce2                	ld	s9,24(sp)
    80002c72:	6d42                	ld	s10,16(sp)
    80002c74:	6da2                	ld	s11,8(sp)
    80002c76:	6165                	addi	sp,sp,112
    80002c78:	8082                	ret

0000000080002c7a <reparent>:
{
    80002c7a:	7179                	addi	sp,sp,-48
    80002c7c:	f406                	sd	ra,40(sp)
    80002c7e:	f022                	sd	s0,32(sp)
    80002c80:	ec26                	sd	s1,24(sp)
    80002c82:	e84a                	sd	s2,16(sp)
    80002c84:	e44e                	sd	s3,8(sp)
    80002c86:	e052                	sd	s4,0(sp)
    80002c88:	1800                	addi	s0,sp,48
    80002c8a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002c8c:	0000f497          	auipc	s1,0xf
    80002c90:	bc448493          	addi	s1,s1,-1084 # 80011850 <proc>
      pp->parent = initproc;
    80002c94:	00006a17          	auipc	s4,0x6
    80002c98:	394a0a13          	addi	s4,s4,916 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002c9c:	00015997          	auipc	s3,0x15
    80002ca0:	9b498993          	addi	s3,s3,-1612 # 80017650 <tickslock>
    80002ca4:	a029                	j	80002cae <reparent+0x34>
    80002ca6:	17848493          	addi	s1,s1,376
    80002caa:	01348d63          	beq	s1,s3,80002cc4 <reparent+0x4a>
    if(pp->parent == p){
    80002cae:	7c9c                	ld	a5,56(s1)
    80002cb0:	ff279be3          	bne	a5,s2,80002ca6 <reparent+0x2c>
      pp->parent = initproc;
    80002cb4:	000a3503          	ld	a0,0(s4)
    80002cb8:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002cba:	00000097          	auipc	ra,0x0
    80002cbe:	eb6080e7          	jalr	-330(ra) # 80002b70 <wakeup>
    80002cc2:	b7d5                	j	80002ca6 <reparent+0x2c>
}
    80002cc4:	70a2                	ld	ra,40(sp)
    80002cc6:	7402                	ld	s0,32(sp)
    80002cc8:	64e2                	ld	s1,24(sp)
    80002cca:	6942                	ld	s2,16(sp)
    80002ccc:	69a2                	ld	s3,8(sp)
    80002cce:	6a02                	ld	s4,0(sp)
    80002cd0:	6145                	addi	sp,sp,48
    80002cd2:	8082                	ret

0000000080002cd4 <exit>:
{
    80002cd4:	7179                	addi	sp,sp,-48
    80002cd6:	f406                	sd	ra,40(sp)
    80002cd8:	f022                	sd	s0,32(sp)
    80002cda:	ec26                	sd	s1,24(sp)
    80002cdc:	e84a                	sd	s2,16(sp)
    80002cde:	e44e                	sd	s3,8(sp)
    80002ce0:	e052                	sd	s4,0(sp)
    80002ce2:	1800                	addi	s0,sp,48
    80002ce4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	126080e7          	jalr	294(ra) # 80001e0c <myproc>
    80002cee:	89aa                	mv	s3,a0
  if(p == initproc)
    80002cf0:	00006797          	auipc	a5,0x6
    80002cf4:	3387b783          	ld	a5,824(a5) # 80009028 <initproc>
    80002cf8:	0d050493          	addi	s1,a0,208
    80002cfc:	15050913          	addi	s2,a0,336
    80002d00:	02a79363          	bne	a5,a0,80002d26 <exit+0x52>
    panic("init exiting");
    80002d04:	00005517          	auipc	a0,0x5
    80002d08:	7d450513          	addi	a0,a0,2004 # 800084d8 <digits+0x498>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	832080e7          	jalr	-1998(ra) # 8000053e <panic>
      fileclose(f);
    80002d14:	00002097          	auipc	ra,0x2
    80002d18:	03a080e7          	jalr	58(ra) # 80004d4e <fileclose>
      p->ofile[fd] = 0;
    80002d1c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002d20:	04a1                	addi	s1,s1,8
    80002d22:	01248563          	beq	s1,s2,80002d2c <exit+0x58>
    if(p->ofile[fd]){
    80002d26:	6088                	ld	a0,0(s1)
    80002d28:	f575                	bnez	a0,80002d14 <exit+0x40>
    80002d2a:	bfdd                	j	80002d20 <exit+0x4c>
  begin_op();
    80002d2c:	00002097          	auipc	ra,0x2
    80002d30:	b56080e7          	jalr	-1194(ra) # 80004882 <begin_op>
  iput(p->cwd);
    80002d34:	1509b503          	ld	a0,336(s3)
    80002d38:	00001097          	auipc	ra,0x1
    80002d3c:	332080e7          	jalr	818(ra) # 8000406a <iput>
  end_op();
    80002d40:	00002097          	auipc	ra,0x2
    80002d44:	bc2080e7          	jalr	-1086(ra) # 80004902 <end_op>
  p->cwd = 0;
    80002d48:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002d4c:	0000f497          	auipc	s1,0xf
    80002d50:	aec48493          	addi	s1,s1,-1300 # 80011838 <wait_lock>
    80002d54:	8526                	mv	a0,s1
    80002d56:	ffffe097          	auipc	ra,0xffffe
    80002d5a:	e8e080e7          	jalr	-370(ra) # 80000be4 <acquire>
  reparent(p);
    80002d5e:	854e                	mv	a0,s3
    80002d60:	00000097          	auipc	ra,0x0
    80002d64:	f1a080e7          	jalr	-230(ra) # 80002c7a <reparent>
  wakeup(p->parent);
    80002d68:	0389b503          	ld	a0,56(s3)
    80002d6c:	00000097          	auipc	ra,0x0
    80002d70:	e04080e7          	jalr	-508(ra) # 80002b70 <wakeup>
  acquire(&p->lock);
    80002d74:	854e                	mv	a0,s3
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	e6e080e7          	jalr	-402(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002d7e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002d82:	4795                	li	a5,5
    80002d84:	00f9ac23          	sw	a5,24(s3)
  printf("insert exit zombie %d\n", p->index); //delete
    80002d88:	16c9a583          	lw	a1,364(s3)
    80002d8c:	00005517          	auipc	a0,0x5
    80002d90:	75c50513          	addi	a0,a0,1884 # 800084e8 <digits+0x4a8>
    80002d94:	ffffd097          	auipc	ra,0xffffd
    80002d98:	7f4080e7          	jalr	2036(ra) # 80000588 <printf>
  insert_proc_to_list(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    80002d9c:	85ce                	mv	a1,s3
    80002d9e:	00006517          	auipc	a0,0x6
    80002da2:	d5250513          	addi	a0,a0,-686 # 80008af0 <zombie_list>
    80002da6:	fffff097          	auipc	ra,0xfffff
    80002daa:	c60080e7          	jalr	-928(ra) # 80001a06 <insert_proc_to_list>
  release(&wait_lock);
    80002dae:	8526                	mv	a0,s1
    80002db0:	ffffe097          	auipc	ra,0xffffe
    80002db4:	ee8080e7          	jalr	-280(ra) # 80000c98 <release>
  sched();
    80002db8:	fffff097          	auipc	ra,0xfffff
    80002dbc:	62c080e7          	jalr	1580(ra) # 800023e4 <sched>
  panic("zombie exit");
    80002dc0:	00005517          	auipc	a0,0x5
    80002dc4:	74050513          	addi	a0,a0,1856 # 80008500 <digits+0x4c0>
    80002dc8:	ffffd097          	auipc	ra,0xffffd
    80002dcc:	776080e7          	jalr	1910(ra) # 8000053e <panic>

0000000080002dd0 <swtch>:
    80002dd0:	00153023          	sd	ra,0(a0)
    80002dd4:	00253423          	sd	sp,8(a0)
    80002dd8:	e900                	sd	s0,16(a0)
    80002dda:	ed04                	sd	s1,24(a0)
    80002ddc:	03253023          	sd	s2,32(a0)
    80002de0:	03353423          	sd	s3,40(a0)
    80002de4:	03453823          	sd	s4,48(a0)
    80002de8:	03553c23          	sd	s5,56(a0)
    80002dec:	05653023          	sd	s6,64(a0)
    80002df0:	05753423          	sd	s7,72(a0)
    80002df4:	05853823          	sd	s8,80(a0)
    80002df8:	05953c23          	sd	s9,88(a0)
    80002dfc:	07a53023          	sd	s10,96(a0)
    80002e00:	07b53423          	sd	s11,104(a0)
    80002e04:	0005b083          	ld	ra,0(a1)
    80002e08:	0085b103          	ld	sp,8(a1)
    80002e0c:	6980                	ld	s0,16(a1)
    80002e0e:	6d84                	ld	s1,24(a1)
    80002e10:	0205b903          	ld	s2,32(a1)
    80002e14:	0285b983          	ld	s3,40(a1)
    80002e18:	0305ba03          	ld	s4,48(a1)
    80002e1c:	0385ba83          	ld	s5,56(a1)
    80002e20:	0405bb03          	ld	s6,64(a1)
    80002e24:	0485bb83          	ld	s7,72(a1)
    80002e28:	0505bc03          	ld	s8,80(a1)
    80002e2c:	0585bc83          	ld	s9,88(a1)
    80002e30:	0605bd03          	ld	s10,96(a1)
    80002e34:	0685bd83          	ld	s11,104(a1)
    80002e38:	8082                	ret

0000000080002e3a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002e3a:	1141                	addi	sp,sp,-16
    80002e3c:	e406                	sd	ra,8(sp)
    80002e3e:	e022                	sd	s0,0(sp)
    80002e40:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002e42:	00005597          	auipc	a1,0x5
    80002e46:	72658593          	addi	a1,a1,1830 # 80008568 <states.1801+0x30>
    80002e4a:	00015517          	auipc	a0,0x15
    80002e4e:	80650513          	addi	a0,a0,-2042 # 80017650 <tickslock>
    80002e52:	ffffe097          	auipc	ra,0xffffe
    80002e56:	d02080e7          	jalr	-766(ra) # 80000b54 <initlock>
}
    80002e5a:	60a2                	ld	ra,8(sp)
    80002e5c:	6402                	ld	s0,0(sp)
    80002e5e:	0141                	addi	sp,sp,16
    80002e60:	8082                	ret

0000000080002e62 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002e62:	1141                	addi	sp,sp,-16
    80002e64:	e422                	sd	s0,8(sp)
    80002e66:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e68:	00003797          	auipc	a5,0x3
    80002e6c:	50878793          	addi	a5,a5,1288 # 80006370 <kernelvec>
    80002e70:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002e74:	6422                	ld	s0,8(sp)
    80002e76:	0141                	addi	sp,sp,16
    80002e78:	8082                	ret

0000000080002e7a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002e7a:	1141                	addi	sp,sp,-16
    80002e7c:	e406                	sd	ra,8(sp)
    80002e7e:	e022                	sd	s0,0(sp)
    80002e80:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	f8a080e7          	jalr	-118(ra) # 80001e0c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e8a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002e8e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e90:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002e94:	00004617          	auipc	a2,0x4
    80002e98:	16c60613          	addi	a2,a2,364 # 80007000 <_trampoline>
    80002e9c:	00004697          	auipc	a3,0x4
    80002ea0:	16468693          	addi	a3,a3,356 # 80007000 <_trampoline>
    80002ea4:	8e91                	sub	a3,a3,a2
    80002ea6:	040007b7          	lui	a5,0x4000
    80002eaa:	17fd                	addi	a5,a5,-1
    80002eac:	07b2                	slli	a5,a5,0xc
    80002eae:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002eb0:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002eb4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002eb6:	180026f3          	csrr	a3,satp
    80002eba:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002ebc:	6d38                	ld	a4,88(a0)
    80002ebe:	6134                	ld	a3,64(a0)
    80002ec0:	6585                	lui	a1,0x1
    80002ec2:	96ae                	add	a3,a3,a1
    80002ec4:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ec6:	6d38                	ld	a4,88(a0)
    80002ec8:	00000697          	auipc	a3,0x0
    80002ecc:	13868693          	addi	a3,a3,312 # 80003000 <usertrap>
    80002ed0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002ed2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ed4:	8692                	mv	a3,tp
    80002ed6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ed8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002edc:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ee0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ee4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ee8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002eea:	6f18                	ld	a4,24(a4)
    80002eec:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002ef0:	692c                	ld	a1,80(a0)
    80002ef2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002ef4:	00004717          	auipc	a4,0x4
    80002ef8:	19c70713          	addi	a4,a4,412 # 80007090 <userret>
    80002efc:	8f11                	sub	a4,a4,a2
    80002efe:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002f00:	577d                	li	a4,-1
    80002f02:	177e                	slli	a4,a4,0x3f
    80002f04:	8dd9                	or	a1,a1,a4
    80002f06:	02000537          	lui	a0,0x2000
    80002f0a:	157d                	addi	a0,a0,-1
    80002f0c:	0536                	slli	a0,a0,0xd
    80002f0e:	9782                	jalr	a5
}
    80002f10:	60a2                	ld	ra,8(sp)
    80002f12:	6402                	ld	s0,0(sp)
    80002f14:	0141                	addi	sp,sp,16
    80002f16:	8082                	ret

0000000080002f18 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002f18:	1101                	addi	sp,sp,-32
    80002f1a:	ec06                	sd	ra,24(sp)
    80002f1c:	e822                	sd	s0,16(sp)
    80002f1e:	e426                	sd	s1,8(sp)
    80002f20:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002f22:	00014497          	auipc	s1,0x14
    80002f26:	72e48493          	addi	s1,s1,1838 # 80017650 <tickslock>
    80002f2a:	8526                	mv	a0,s1
    80002f2c:	ffffe097          	auipc	ra,0xffffe
    80002f30:	cb8080e7          	jalr	-840(ra) # 80000be4 <acquire>
  ticks++;
    80002f34:	00006517          	auipc	a0,0x6
    80002f38:	0fc50513          	addi	a0,a0,252 # 80009030 <ticks>
    80002f3c:	411c                	lw	a5,0(a0)
    80002f3e:	2785                	addiw	a5,a5,1
    80002f40:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002f42:	00000097          	auipc	ra,0x0
    80002f46:	c2e080e7          	jalr	-978(ra) # 80002b70 <wakeup>
  release(&tickslock);
    80002f4a:	8526                	mv	a0,s1
    80002f4c:	ffffe097          	auipc	ra,0xffffe
    80002f50:	d4c080e7          	jalr	-692(ra) # 80000c98 <release>
}
    80002f54:	60e2                	ld	ra,24(sp)
    80002f56:	6442                	ld	s0,16(sp)
    80002f58:	64a2                	ld	s1,8(sp)
    80002f5a:	6105                	addi	sp,sp,32
    80002f5c:	8082                	ret

0000000080002f5e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002f5e:	1101                	addi	sp,sp,-32
    80002f60:	ec06                	sd	ra,24(sp)
    80002f62:	e822                	sd	s0,16(sp)
    80002f64:	e426                	sd	s1,8(sp)
    80002f66:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f68:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002f6c:	00074d63          	bltz	a4,80002f86 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002f70:	57fd                	li	a5,-1
    80002f72:	17fe                	slli	a5,a5,0x3f
    80002f74:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002f76:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002f78:	06f70363          	beq	a4,a5,80002fde <devintr+0x80>
  }
}
    80002f7c:	60e2                	ld	ra,24(sp)
    80002f7e:	6442                	ld	s0,16(sp)
    80002f80:	64a2                	ld	s1,8(sp)
    80002f82:	6105                	addi	sp,sp,32
    80002f84:	8082                	ret
     (scause & 0xff) == 9){
    80002f86:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002f8a:	46a5                	li	a3,9
    80002f8c:	fed792e3          	bne	a5,a3,80002f70 <devintr+0x12>
    int irq = plic_claim();
    80002f90:	00003097          	auipc	ra,0x3
    80002f94:	4e8080e7          	jalr	1256(ra) # 80006478 <plic_claim>
    80002f98:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002f9a:	47a9                	li	a5,10
    80002f9c:	02f50763          	beq	a0,a5,80002fca <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002fa0:	4785                	li	a5,1
    80002fa2:	02f50963          	beq	a0,a5,80002fd4 <devintr+0x76>
    return 1;
    80002fa6:	4505                	li	a0,1
    } else if(irq){
    80002fa8:	d8f1                	beqz	s1,80002f7c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002faa:	85a6                	mv	a1,s1
    80002fac:	00005517          	auipc	a0,0x5
    80002fb0:	5c450513          	addi	a0,a0,1476 # 80008570 <states.1801+0x38>
    80002fb4:	ffffd097          	auipc	ra,0xffffd
    80002fb8:	5d4080e7          	jalr	1492(ra) # 80000588 <printf>
      plic_complete(irq);
    80002fbc:	8526                	mv	a0,s1
    80002fbe:	00003097          	auipc	ra,0x3
    80002fc2:	4de080e7          	jalr	1246(ra) # 8000649c <plic_complete>
    return 1;
    80002fc6:	4505                	li	a0,1
    80002fc8:	bf55                	j	80002f7c <devintr+0x1e>
      uartintr();
    80002fca:	ffffe097          	auipc	ra,0xffffe
    80002fce:	9de080e7          	jalr	-1570(ra) # 800009a8 <uartintr>
    80002fd2:	b7ed                	j	80002fbc <devintr+0x5e>
      virtio_disk_intr();
    80002fd4:	00004097          	auipc	ra,0x4
    80002fd8:	9a8080e7          	jalr	-1624(ra) # 8000697c <virtio_disk_intr>
    80002fdc:	b7c5                	j	80002fbc <devintr+0x5e>
    if(cpuid() == 0){
    80002fde:	fffff097          	auipc	ra,0xfffff
    80002fe2:	dfc080e7          	jalr	-516(ra) # 80001dda <cpuid>
    80002fe6:	c901                	beqz	a0,80002ff6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002fe8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002fec:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002fee:	14479073          	csrw	sip,a5
    return 2;
    80002ff2:	4509                	li	a0,2
    80002ff4:	b761                	j	80002f7c <devintr+0x1e>
      clockintr();
    80002ff6:	00000097          	auipc	ra,0x0
    80002ffa:	f22080e7          	jalr	-222(ra) # 80002f18 <clockintr>
    80002ffe:	b7ed                	j	80002fe8 <devintr+0x8a>

0000000080003000 <usertrap>:
{
    80003000:	1101                	addi	sp,sp,-32
    80003002:	ec06                	sd	ra,24(sp)
    80003004:	e822                	sd	s0,16(sp)
    80003006:	e426                	sd	s1,8(sp)
    80003008:	e04a                	sd	s2,0(sp)
    8000300a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000300c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003010:	1007f793          	andi	a5,a5,256
    80003014:	e3ad                	bnez	a5,80003076 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003016:	00003797          	auipc	a5,0x3
    8000301a:	35a78793          	addi	a5,a5,858 # 80006370 <kernelvec>
    8000301e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003022:	fffff097          	auipc	ra,0xfffff
    80003026:	dea080e7          	jalr	-534(ra) # 80001e0c <myproc>
    8000302a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000302c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000302e:	14102773          	csrr	a4,sepc
    80003032:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003034:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003038:	47a1                	li	a5,8
    8000303a:	04f71c63          	bne	a4,a5,80003092 <usertrap+0x92>
    if(p->killed)
    8000303e:	551c                	lw	a5,40(a0)
    80003040:	e3b9                	bnez	a5,80003086 <usertrap+0x86>
    p->trapframe->epc += 4;
    80003042:	6cb8                	ld	a4,88(s1)
    80003044:	6f1c                	ld	a5,24(a4)
    80003046:	0791                	addi	a5,a5,4
    80003048:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000304a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000304e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003052:	10079073          	csrw	sstatus,a5
    syscall();
    80003056:	00000097          	auipc	ra,0x0
    8000305a:	2e0080e7          	jalr	736(ra) # 80003336 <syscall>
  if(p->killed)
    8000305e:	549c                	lw	a5,40(s1)
    80003060:	ebc1                	bnez	a5,800030f0 <usertrap+0xf0>
  usertrapret();
    80003062:	00000097          	auipc	ra,0x0
    80003066:	e18080e7          	jalr	-488(ra) # 80002e7a <usertrapret>
}
    8000306a:	60e2                	ld	ra,24(sp)
    8000306c:	6442                	ld	s0,16(sp)
    8000306e:	64a2                	ld	s1,8(sp)
    80003070:	6902                	ld	s2,0(sp)
    80003072:	6105                	addi	sp,sp,32
    80003074:	8082                	ret
    panic("usertrap: not from user mode");
    80003076:	00005517          	auipc	a0,0x5
    8000307a:	51a50513          	addi	a0,a0,1306 # 80008590 <states.1801+0x58>
    8000307e:	ffffd097          	auipc	ra,0xffffd
    80003082:	4c0080e7          	jalr	1216(ra) # 8000053e <panic>
      exit(-1);
    80003086:	557d                	li	a0,-1
    80003088:	00000097          	auipc	ra,0x0
    8000308c:	c4c080e7          	jalr	-948(ra) # 80002cd4 <exit>
    80003090:	bf4d                	j	80003042 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003092:	00000097          	auipc	ra,0x0
    80003096:	ecc080e7          	jalr	-308(ra) # 80002f5e <devintr>
    8000309a:	892a                	mv	s2,a0
    8000309c:	c501                	beqz	a0,800030a4 <usertrap+0xa4>
  if(p->killed)
    8000309e:	549c                	lw	a5,40(s1)
    800030a0:	c3a1                	beqz	a5,800030e0 <usertrap+0xe0>
    800030a2:	a815                	j	800030d6 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030a4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800030a8:	5890                	lw	a2,48(s1)
    800030aa:	00005517          	auipc	a0,0x5
    800030ae:	50650513          	addi	a0,a0,1286 # 800085b0 <states.1801+0x78>
    800030b2:	ffffd097          	auipc	ra,0xffffd
    800030b6:	4d6080e7          	jalr	1238(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030ba:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800030be:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800030c2:	00005517          	auipc	a0,0x5
    800030c6:	51e50513          	addi	a0,a0,1310 # 800085e0 <states.1801+0xa8>
    800030ca:	ffffd097          	auipc	ra,0xffffd
    800030ce:	4be080e7          	jalr	1214(ra) # 80000588 <printf>
    p->killed = 1;
    800030d2:	4785                	li	a5,1
    800030d4:	d49c                	sw	a5,40(s1)
    exit(-1);
    800030d6:	557d                	li	a0,-1
    800030d8:	00000097          	auipc	ra,0x0
    800030dc:	bfc080e7          	jalr	-1028(ra) # 80002cd4 <exit>
  if(which_dev == 2)
    800030e0:	4789                	li	a5,2
    800030e2:	f8f910e3          	bne	s2,a5,80003062 <usertrap+0x62>
    yield();
    800030e6:	fffff097          	auipc	ra,0xfffff
    800030ea:	400080e7          	jalr	1024(ra) # 800024e6 <yield>
    800030ee:	bf95                	j	80003062 <usertrap+0x62>
  int which_dev = 0;
    800030f0:	4901                	li	s2,0
    800030f2:	b7d5                	j	800030d6 <usertrap+0xd6>

00000000800030f4 <kerneltrap>:
{
    800030f4:	7179                	addi	sp,sp,-48
    800030f6:	f406                	sd	ra,40(sp)
    800030f8:	f022                	sd	s0,32(sp)
    800030fa:	ec26                	sd	s1,24(sp)
    800030fc:	e84a                	sd	s2,16(sp)
    800030fe:	e44e                	sd	s3,8(sp)
    80003100:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003102:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003106:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000310a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000310e:	1004f793          	andi	a5,s1,256
    80003112:	cb85                	beqz	a5,80003142 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003114:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003118:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000311a:	ef85                	bnez	a5,80003152 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000311c:	00000097          	auipc	ra,0x0
    80003120:	e42080e7          	jalr	-446(ra) # 80002f5e <devintr>
    80003124:	cd1d                	beqz	a0,80003162 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003126:	4789                	li	a5,2
    80003128:	06f50a63          	beq	a0,a5,8000319c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000312c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003130:	10049073          	csrw	sstatus,s1
}
    80003134:	70a2                	ld	ra,40(sp)
    80003136:	7402                	ld	s0,32(sp)
    80003138:	64e2                	ld	s1,24(sp)
    8000313a:	6942                	ld	s2,16(sp)
    8000313c:	69a2                	ld	s3,8(sp)
    8000313e:	6145                	addi	sp,sp,48
    80003140:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003142:	00005517          	auipc	a0,0x5
    80003146:	4be50513          	addi	a0,a0,1214 # 80008600 <states.1801+0xc8>
    8000314a:	ffffd097          	auipc	ra,0xffffd
    8000314e:	3f4080e7          	jalr	1012(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003152:	00005517          	auipc	a0,0x5
    80003156:	4d650513          	addi	a0,a0,1238 # 80008628 <states.1801+0xf0>
    8000315a:	ffffd097          	auipc	ra,0xffffd
    8000315e:	3e4080e7          	jalr	996(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003162:	85ce                	mv	a1,s3
    80003164:	00005517          	auipc	a0,0x5
    80003168:	4e450513          	addi	a0,a0,1252 # 80008648 <states.1801+0x110>
    8000316c:	ffffd097          	auipc	ra,0xffffd
    80003170:	41c080e7          	jalr	1052(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003174:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003178:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000317c:	00005517          	auipc	a0,0x5
    80003180:	4dc50513          	addi	a0,a0,1244 # 80008658 <states.1801+0x120>
    80003184:	ffffd097          	auipc	ra,0xffffd
    80003188:	404080e7          	jalr	1028(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000318c:	00005517          	auipc	a0,0x5
    80003190:	4e450513          	addi	a0,a0,1252 # 80008670 <states.1801+0x138>
    80003194:	ffffd097          	auipc	ra,0xffffd
    80003198:	3aa080e7          	jalr	938(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000319c:	fffff097          	auipc	ra,0xfffff
    800031a0:	c70080e7          	jalr	-912(ra) # 80001e0c <myproc>
    800031a4:	d541                	beqz	a0,8000312c <kerneltrap+0x38>
    800031a6:	fffff097          	auipc	ra,0xfffff
    800031aa:	c66080e7          	jalr	-922(ra) # 80001e0c <myproc>
    800031ae:	4d18                	lw	a4,24(a0)
    800031b0:	4791                	li	a5,4
    800031b2:	f6f71de3          	bne	a4,a5,8000312c <kerneltrap+0x38>
    yield();
    800031b6:	fffff097          	auipc	ra,0xfffff
    800031ba:	330080e7          	jalr	816(ra) # 800024e6 <yield>
    800031be:	b7bd                	j	8000312c <kerneltrap+0x38>

00000000800031c0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800031c0:	1101                	addi	sp,sp,-32
    800031c2:	ec06                	sd	ra,24(sp)
    800031c4:	e822                	sd	s0,16(sp)
    800031c6:	e426                	sd	s1,8(sp)
    800031c8:	1000                	addi	s0,sp,32
    800031ca:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800031cc:	fffff097          	auipc	ra,0xfffff
    800031d0:	c40080e7          	jalr	-960(ra) # 80001e0c <myproc>
  switch (n) {
    800031d4:	4795                	li	a5,5
    800031d6:	0497e163          	bltu	a5,s1,80003218 <argraw+0x58>
    800031da:	048a                	slli	s1,s1,0x2
    800031dc:	00005717          	auipc	a4,0x5
    800031e0:	4cc70713          	addi	a4,a4,1228 # 800086a8 <states.1801+0x170>
    800031e4:	94ba                	add	s1,s1,a4
    800031e6:	409c                	lw	a5,0(s1)
    800031e8:	97ba                	add	a5,a5,a4
    800031ea:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800031ec:	6d3c                	ld	a5,88(a0)
    800031ee:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800031f0:	60e2                	ld	ra,24(sp)
    800031f2:	6442                	ld	s0,16(sp)
    800031f4:	64a2                	ld	s1,8(sp)
    800031f6:	6105                	addi	sp,sp,32
    800031f8:	8082                	ret
    return p->trapframe->a1;
    800031fa:	6d3c                	ld	a5,88(a0)
    800031fc:	7fa8                	ld	a0,120(a5)
    800031fe:	bfcd                	j	800031f0 <argraw+0x30>
    return p->trapframe->a2;
    80003200:	6d3c                	ld	a5,88(a0)
    80003202:	63c8                	ld	a0,128(a5)
    80003204:	b7f5                	j	800031f0 <argraw+0x30>
    return p->trapframe->a3;
    80003206:	6d3c                	ld	a5,88(a0)
    80003208:	67c8                	ld	a0,136(a5)
    8000320a:	b7dd                	j	800031f0 <argraw+0x30>
    return p->trapframe->a4;
    8000320c:	6d3c                	ld	a5,88(a0)
    8000320e:	6bc8                	ld	a0,144(a5)
    80003210:	b7c5                	j	800031f0 <argraw+0x30>
    return p->trapframe->a5;
    80003212:	6d3c                	ld	a5,88(a0)
    80003214:	6fc8                	ld	a0,152(a5)
    80003216:	bfe9                	j	800031f0 <argraw+0x30>
  panic("argraw");
    80003218:	00005517          	auipc	a0,0x5
    8000321c:	46850513          	addi	a0,a0,1128 # 80008680 <states.1801+0x148>
    80003220:	ffffd097          	auipc	ra,0xffffd
    80003224:	31e080e7          	jalr	798(ra) # 8000053e <panic>

0000000080003228 <fetchaddr>:
{
    80003228:	1101                	addi	sp,sp,-32
    8000322a:	ec06                	sd	ra,24(sp)
    8000322c:	e822                	sd	s0,16(sp)
    8000322e:	e426                	sd	s1,8(sp)
    80003230:	e04a                	sd	s2,0(sp)
    80003232:	1000                	addi	s0,sp,32
    80003234:	84aa                	mv	s1,a0
    80003236:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003238:	fffff097          	auipc	ra,0xfffff
    8000323c:	bd4080e7          	jalr	-1068(ra) # 80001e0c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003240:	653c                	ld	a5,72(a0)
    80003242:	02f4f863          	bgeu	s1,a5,80003272 <fetchaddr+0x4a>
    80003246:	00848713          	addi	a4,s1,8
    8000324a:	02e7e663          	bltu	a5,a4,80003276 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000324e:	46a1                	li	a3,8
    80003250:	8626                	mv	a2,s1
    80003252:	85ca                	mv	a1,s2
    80003254:	6928                	ld	a0,80(a0)
    80003256:	ffffe097          	auipc	ra,0xffffe
    8000325a:	4a8080e7          	jalr	1192(ra) # 800016fe <copyin>
    8000325e:	00a03533          	snez	a0,a0
    80003262:	40a00533          	neg	a0,a0
}
    80003266:	60e2                	ld	ra,24(sp)
    80003268:	6442                	ld	s0,16(sp)
    8000326a:	64a2                	ld	s1,8(sp)
    8000326c:	6902                	ld	s2,0(sp)
    8000326e:	6105                	addi	sp,sp,32
    80003270:	8082                	ret
    return -1;
    80003272:	557d                	li	a0,-1
    80003274:	bfcd                	j	80003266 <fetchaddr+0x3e>
    80003276:	557d                	li	a0,-1
    80003278:	b7fd                	j	80003266 <fetchaddr+0x3e>

000000008000327a <fetchstr>:
{
    8000327a:	7179                	addi	sp,sp,-48
    8000327c:	f406                	sd	ra,40(sp)
    8000327e:	f022                	sd	s0,32(sp)
    80003280:	ec26                	sd	s1,24(sp)
    80003282:	e84a                	sd	s2,16(sp)
    80003284:	e44e                	sd	s3,8(sp)
    80003286:	1800                	addi	s0,sp,48
    80003288:	892a                	mv	s2,a0
    8000328a:	84ae                	mv	s1,a1
    8000328c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000328e:	fffff097          	auipc	ra,0xfffff
    80003292:	b7e080e7          	jalr	-1154(ra) # 80001e0c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003296:	86ce                	mv	a3,s3
    80003298:	864a                	mv	a2,s2
    8000329a:	85a6                	mv	a1,s1
    8000329c:	6928                	ld	a0,80(a0)
    8000329e:	ffffe097          	auipc	ra,0xffffe
    800032a2:	4ec080e7          	jalr	1260(ra) # 8000178a <copyinstr>
  if(err < 0)
    800032a6:	00054763          	bltz	a0,800032b4 <fetchstr+0x3a>
  return strlen(buf);
    800032aa:	8526                	mv	a0,s1
    800032ac:	ffffe097          	auipc	ra,0xffffe
    800032b0:	bb8080e7          	jalr	-1096(ra) # 80000e64 <strlen>
}
    800032b4:	70a2                	ld	ra,40(sp)
    800032b6:	7402                	ld	s0,32(sp)
    800032b8:	64e2                	ld	s1,24(sp)
    800032ba:	6942                	ld	s2,16(sp)
    800032bc:	69a2                	ld	s3,8(sp)
    800032be:	6145                	addi	sp,sp,48
    800032c0:	8082                	ret

00000000800032c2 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800032c2:	1101                	addi	sp,sp,-32
    800032c4:	ec06                	sd	ra,24(sp)
    800032c6:	e822                	sd	s0,16(sp)
    800032c8:	e426                	sd	s1,8(sp)
    800032ca:	1000                	addi	s0,sp,32
    800032cc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800032ce:	00000097          	auipc	ra,0x0
    800032d2:	ef2080e7          	jalr	-270(ra) # 800031c0 <argraw>
    800032d6:	c088                	sw	a0,0(s1)
  return 0;
}
    800032d8:	4501                	li	a0,0
    800032da:	60e2                	ld	ra,24(sp)
    800032dc:	6442                	ld	s0,16(sp)
    800032de:	64a2                	ld	s1,8(sp)
    800032e0:	6105                	addi	sp,sp,32
    800032e2:	8082                	ret

00000000800032e4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800032e4:	1101                	addi	sp,sp,-32
    800032e6:	ec06                	sd	ra,24(sp)
    800032e8:	e822                	sd	s0,16(sp)
    800032ea:	e426                	sd	s1,8(sp)
    800032ec:	1000                	addi	s0,sp,32
    800032ee:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800032f0:	00000097          	auipc	ra,0x0
    800032f4:	ed0080e7          	jalr	-304(ra) # 800031c0 <argraw>
    800032f8:	e088                	sd	a0,0(s1)
  return 0;
}
    800032fa:	4501                	li	a0,0
    800032fc:	60e2                	ld	ra,24(sp)
    800032fe:	6442                	ld	s0,16(sp)
    80003300:	64a2                	ld	s1,8(sp)
    80003302:	6105                	addi	sp,sp,32
    80003304:	8082                	ret

0000000080003306 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003306:	1101                	addi	sp,sp,-32
    80003308:	ec06                	sd	ra,24(sp)
    8000330a:	e822                	sd	s0,16(sp)
    8000330c:	e426                	sd	s1,8(sp)
    8000330e:	e04a                	sd	s2,0(sp)
    80003310:	1000                	addi	s0,sp,32
    80003312:	84ae                	mv	s1,a1
    80003314:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003316:	00000097          	auipc	ra,0x0
    8000331a:	eaa080e7          	jalr	-342(ra) # 800031c0 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000331e:	864a                	mv	a2,s2
    80003320:	85a6                	mv	a1,s1
    80003322:	00000097          	auipc	ra,0x0
    80003326:	f58080e7          	jalr	-168(ra) # 8000327a <fetchstr>
}
    8000332a:	60e2                	ld	ra,24(sp)
    8000332c:	6442                	ld	s0,16(sp)
    8000332e:	64a2                	ld	s1,8(sp)
    80003330:	6902                	ld	s2,0(sp)
    80003332:	6105                	addi	sp,sp,32
    80003334:	8082                	ret

0000000080003336 <syscall>:
[SYS_cpu_process_count]   sys_cpu_process_count,
};

void
syscall(void)
{
    80003336:	1101                	addi	sp,sp,-32
    80003338:	ec06                	sd	ra,24(sp)
    8000333a:	e822                	sd	s0,16(sp)
    8000333c:	e426                	sd	s1,8(sp)
    8000333e:	e04a                	sd	s2,0(sp)
    80003340:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003342:	fffff097          	auipc	ra,0xfffff
    80003346:	aca080e7          	jalr	-1334(ra) # 80001e0c <myproc>
    8000334a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000334c:	05853903          	ld	s2,88(a0)
    80003350:	0a893783          	ld	a5,168(s2)
    80003354:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003358:	37fd                	addiw	a5,a5,-1
    8000335a:	475d                	li	a4,23
    8000335c:	00f76f63          	bltu	a4,a5,8000337a <syscall+0x44>
    80003360:	00369713          	slli	a4,a3,0x3
    80003364:	00005797          	auipc	a5,0x5
    80003368:	35c78793          	addi	a5,a5,860 # 800086c0 <syscalls>
    8000336c:	97ba                	add	a5,a5,a4
    8000336e:	639c                	ld	a5,0(a5)
    80003370:	c789                	beqz	a5,8000337a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003372:	9782                	jalr	a5
    80003374:	06a93823          	sd	a0,112(s2)
    80003378:	a839                	j	80003396 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000337a:	15848613          	addi	a2,s1,344
    8000337e:	588c                	lw	a1,48(s1)
    80003380:	00005517          	auipc	a0,0x5
    80003384:	30850513          	addi	a0,a0,776 # 80008688 <states.1801+0x150>
    80003388:	ffffd097          	auipc	ra,0xffffd
    8000338c:	200080e7          	jalr	512(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003390:	6cbc                	ld	a5,88(s1)
    80003392:	577d                	li	a4,-1
    80003394:	fbb8                	sd	a4,112(a5)
  }
}
    80003396:	60e2                	ld	ra,24(sp)
    80003398:	6442                	ld	s0,16(sp)
    8000339a:	64a2                	ld	s1,8(sp)
    8000339c:	6902                	ld	s2,0(sp)
    8000339e:	6105                	addi	sp,sp,32
    800033a0:	8082                	ret

00000000800033a2 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800033a2:	1101                	addi	sp,sp,-32
    800033a4:	ec06                	sd	ra,24(sp)
    800033a6:	e822                	sd	s0,16(sp)
    800033a8:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800033aa:	fec40593          	addi	a1,s0,-20
    800033ae:	4501                	li	a0,0
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	f12080e7          	jalr	-238(ra) # 800032c2 <argint>
    return -1;
    800033b8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800033ba:	00054963          	bltz	a0,800033cc <sys_exit+0x2a>
  exit(n);
    800033be:	fec42503          	lw	a0,-20(s0)
    800033c2:	00000097          	auipc	ra,0x0
    800033c6:	912080e7          	jalr	-1774(ra) # 80002cd4 <exit>
  return 0;  // not reached
    800033ca:	4781                	li	a5,0
}
    800033cc:	853e                	mv	a0,a5
    800033ce:	60e2                	ld	ra,24(sp)
    800033d0:	6442                	ld	s0,16(sp)
    800033d2:	6105                	addi	sp,sp,32
    800033d4:	8082                	ret

00000000800033d6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800033d6:	1141                	addi	sp,sp,-16
    800033d8:	e406                	sd	ra,8(sp)
    800033da:	e022                	sd	s0,0(sp)
    800033dc:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800033de:	fffff097          	auipc	ra,0xfffff
    800033e2:	a2e080e7          	jalr	-1490(ra) # 80001e0c <myproc>
}
    800033e6:	5908                	lw	a0,48(a0)
    800033e8:	60a2                	ld	ra,8(sp)
    800033ea:	6402                	ld	s0,0(sp)
    800033ec:	0141                	addi	sp,sp,16
    800033ee:	8082                	ret

00000000800033f0 <sys_fork>:

uint64
sys_fork(void)
{
    800033f0:	1141                	addi	sp,sp,-16
    800033f2:	e406                	sd	ra,8(sp)
    800033f4:	e022                	sd	s0,0(sp)
    800033f6:	0800                	addi	s0,sp,16
  return fork();
    800033f8:	fffff097          	auipc	ra,0xfffff
    800033fc:	5f0080e7          	jalr	1520(ra) # 800029e8 <fork>
}
    80003400:	60a2                	ld	ra,8(sp)
    80003402:	6402                	ld	s0,0(sp)
    80003404:	0141                	addi	sp,sp,16
    80003406:	8082                	ret

0000000080003408 <sys_wait>:

uint64
sys_wait(void)
{
    80003408:	1101                	addi	sp,sp,-32
    8000340a:	ec06                	sd	ra,24(sp)
    8000340c:	e822                	sd	s0,16(sp)
    8000340e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003410:	fe840593          	addi	a1,s0,-24
    80003414:	4501                	li	a0,0
    80003416:	00000097          	auipc	ra,0x0
    8000341a:	ece080e7          	jalr	-306(ra) # 800032e4 <argaddr>
    8000341e:	87aa                	mv	a5,a0
    return -1;
    80003420:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003422:	0007c863          	bltz	a5,80003432 <sys_wait+0x2a>
  return wait(p);
    80003426:	fe843503          	ld	a0,-24(s0)
    8000342a:	fffff097          	auipc	ra,0xfffff
    8000342e:	1ba080e7          	jalr	442(ra) # 800025e4 <wait>
}
    80003432:	60e2                	ld	ra,24(sp)
    80003434:	6442                	ld	s0,16(sp)
    80003436:	6105                	addi	sp,sp,32
    80003438:	8082                	ret

000000008000343a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000343a:	7179                	addi	sp,sp,-48
    8000343c:	f406                	sd	ra,40(sp)
    8000343e:	f022                	sd	s0,32(sp)
    80003440:	ec26                	sd	s1,24(sp)
    80003442:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003444:	fdc40593          	addi	a1,s0,-36
    80003448:	4501                	li	a0,0
    8000344a:	00000097          	auipc	ra,0x0
    8000344e:	e78080e7          	jalr	-392(ra) # 800032c2 <argint>
    80003452:	87aa                	mv	a5,a0
    return -1;
    80003454:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003456:	0207c063          	bltz	a5,80003476 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000345a:	fffff097          	auipc	ra,0xfffff
    8000345e:	9b2080e7          	jalr	-1614(ra) # 80001e0c <myproc>
    80003462:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003464:	fdc42503          	lw	a0,-36(s0)
    80003468:	fffff097          	auipc	ra,0xfffff
    8000346c:	e08080e7          	jalr	-504(ra) # 80002270 <growproc>
    80003470:	00054863          	bltz	a0,80003480 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003474:	8526                	mv	a0,s1
}
    80003476:	70a2                	ld	ra,40(sp)
    80003478:	7402                	ld	s0,32(sp)
    8000347a:	64e2                	ld	s1,24(sp)
    8000347c:	6145                	addi	sp,sp,48
    8000347e:	8082                	ret
    return -1;
    80003480:	557d                	li	a0,-1
    80003482:	bfd5                	j	80003476 <sys_sbrk+0x3c>

0000000080003484 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003484:	7139                	addi	sp,sp,-64
    80003486:	fc06                	sd	ra,56(sp)
    80003488:	f822                	sd	s0,48(sp)
    8000348a:	f426                	sd	s1,40(sp)
    8000348c:	f04a                	sd	s2,32(sp)
    8000348e:	ec4e                	sd	s3,24(sp)
    80003490:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003492:	fcc40593          	addi	a1,s0,-52
    80003496:	4501                	li	a0,0
    80003498:	00000097          	auipc	ra,0x0
    8000349c:	e2a080e7          	jalr	-470(ra) # 800032c2 <argint>
    return -1;
    800034a0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800034a2:	06054563          	bltz	a0,8000350c <sys_sleep+0x88>
  acquire(&tickslock);
    800034a6:	00014517          	auipc	a0,0x14
    800034aa:	1aa50513          	addi	a0,a0,426 # 80017650 <tickslock>
    800034ae:	ffffd097          	auipc	ra,0xffffd
    800034b2:	736080e7          	jalr	1846(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800034b6:	00006917          	auipc	s2,0x6
    800034ba:	b7a92903          	lw	s2,-1158(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800034be:	fcc42783          	lw	a5,-52(s0)
    800034c2:	cf85                	beqz	a5,800034fa <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800034c4:	00014997          	auipc	s3,0x14
    800034c8:	18c98993          	addi	s3,s3,396 # 80017650 <tickslock>
    800034cc:	00006497          	auipc	s1,0x6
    800034d0:	b6448493          	addi	s1,s1,-1180 # 80009030 <ticks>
    if(myproc()->killed){
    800034d4:	fffff097          	auipc	ra,0xfffff
    800034d8:	938080e7          	jalr	-1736(ra) # 80001e0c <myproc>
    800034dc:	551c                	lw	a5,40(a0)
    800034de:	ef9d                	bnez	a5,8000351c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800034e0:	85ce                	mv	a1,s3
    800034e2:	8526                	mv	a0,s1
    800034e4:	fffff097          	auipc	ra,0xfffff
    800034e8:	076080e7          	jalr	118(ra) # 8000255a <sleep>
  while(ticks - ticks0 < n){
    800034ec:	409c                	lw	a5,0(s1)
    800034ee:	412787bb          	subw	a5,a5,s2
    800034f2:	fcc42703          	lw	a4,-52(s0)
    800034f6:	fce7efe3          	bltu	a5,a4,800034d4 <sys_sleep+0x50>
  }
  release(&tickslock);
    800034fa:	00014517          	auipc	a0,0x14
    800034fe:	15650513          	addi	a0,a0,342 # 80017650 <tickslock>
    80003502:	ffffd097          	auipc	ra,0xffffd
    80003506:	796080e7          	jalr	1942(ra) # 80000c98 <release>
  return 0;
    8000350a:	4781                	li	a5,0
}
    8000350c:	853e                	mv	a0,a5
    8000350e:	70e2                	ld	ra,56(sp)
    80003510:	7442                	ld	s0,48(sp)
    80003512:	74a2                	ld	s1,40(sp)
    80003514:	7902                	ld	s2,32(sp)
    80003516:	69e2                	ld	s3,24(sp)
    80003518:	6121                	addi	sp,sp,64
    8000351a:	8082                	ret
      release(&tickslock);
    8000351c:	00014517          	auipc	a0,0x14
    80003520:	13450513          	addi	a0,a0,308 # 80017650 <tickslock>
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	774080e7          	jalr	1908(ra) # 80000c98 <release>
      return -1;
    8000352c:	57fd                	li	a5,-1
    8000352e:	bff9                	j	8000350c <sys_sleep+0x88>

0000000080003530 <sys_kill>:

uint64
sys_kill(void)
{
    80003530:	1101                	addi	sp,sp,-32
    80003532:	ec06                	sd	ra,24(sp)
    80003534:	e822                	sd	s0,16(sp)
    80003536:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003538:	fec40593          	addi	a1,s0,-20
    8000353c:	4501                	li	a0,0
    8000353e:	00000097          	auipc	ra,0x0
    80003542:	d84080e7          	jalr	-636(ra) # 800032c2 <argint>
    80003546:	87aa                	mv	a5,a0
    return -1;
    80003548:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000354a:	0007c863          	bltz	a5,8000355a <sys_kill+0x2a>
  return kill(pid);
    8000354e:	fec42503          	lw	a0,-20(s0)
    80003552:	fffff097          	auipc	ra,0xfffff
    80003556:	1ba080e7          	jalr	442(ra) # 8000270c <kill>
}
    8000355a:	60e2                	ld	ra,24(sp)
    8000355c:	6442                	ld	s0,16(sp)
    8000355e:	6105                	addi	sp,sp,32
    80003560:	8082                	ret

0000000080003562 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003562:	1101                	addi	sp,sp,-32
    80003564:	ec06                	sd	ra,24(sp)
    80003566:	e822                	sd	s0,16(sp)
    80003568:	e426                	sd	s1,8(sp)
    8000356a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000356c:	00014517          	auipc	a0,0x14
    80003570:	0e450513          	addi	a0,a0,228 # 80017650 <tickslock>
    80003574:	ffffd097          	auipc	ra,0xffffd
    80003578:	670080e7          	jalr	1648(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000357c:	00006497          	auipc	s1,0x6
    80003580:	ab44a483          	lw	s1,-1356(s1) # 80009030 <ticks>
  release(&tickslock);
    80003584:	00014517          	auipc	a0,0x14
    80003588:	0cc50513          	addi	a0,a0,204 # 80017650 <tickslock>
    8000358c:	ffffd097          	auipc	ra,0xffffd
    80003590:	70c080e7          	jalr	1804(ra) # 80000c98 <release>
  return xticks;
}
    80003594:	02049513          	slli	a0,s1,0x20
    80003598:	9101                	srli	a0,a0,0x20
    8000359a:	60e2                	ld	ra,24(sp)
    8000359c:	6442                	ld	s0,16(sp)
    8000359e:	64a2                	ld	s1,8(sp)
    800035a0:	6105                	addi	sp,sp,32
    800035a2:	8082                	ret

00000000800035a4 <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    800035a4:	1101                	addi	sp,sp,-32
    800035a6:	ec06                	sd	ra,24(sp)
    800035a8:	e822                	sd	s0,16(sp)
    800035aa:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    800035ac:	fec40593          	addi	a1,s0,-20
    800035b0:	4501                	li	a0,0
    800035b2:	00000097          	auipc	ra,0x0
    800035b6:	d10080e7          	jalr	-752(ra) # 800032c2 <argint>
    800035ba:	87aa                	mv	a5,a0
    return -1;
    800035bc:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    800035be:	0007c863          	bltz	a5,800035ce <sys_set_cpu+0x2a>
  return set_cpu(cpu_id);
    800035c2:	fec42503          	lw	a0,-20(s0)
    800035c6:	fffff097          	auipc	ra,0xfffff
    800035ca:	312080e7          	jalr	786(ra) # 800028d8 <set_cpu>
}
    800035ce:	60e2                	ld	ra,24(sp)
    800035d0:	6442                	ld	s0,16(sp)
    800035d2:	6105                	addi	sp,sp,32
    800035d4:	8082                	ret

00000000800035d6 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    800035d6:	1141                	addi	sp,sp,-16
    800035d8:	e406                	sd	ra,8(sp)
    800035da:	e022                	sd	s0,0(sp)
    800035dc:	0800                	addi	s0,sp,16
  return get_cpu();
    800035de:	fffff097          	auipc	ra,0xfffff
    800035e2:	34c080e7          	jalr	844(ra) # 8000292a <get_cpu>
}
    800035e6:	60a2                	ld	ra,8(sp)
    800035e8:	6402                	ld	s0,0(sp)
    800035ea:	0141                	addi	sp,sp,16
    800035ec:	8082                	ret

00000000800035ee <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void)
{
    800035ee:	1101                	addi	sp,sp,-32
    800035f0:	ec06                	sd	ra,24(sp)
    800035f2:	e822                	sd	s0,16(sp)
    800035f4:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    800035f6:	fec40593          	addi	a1,s0,-20
    800035fa:	4501                	li	a0,0
    800035fc:	00000097          	auipc	ra,0x0
    80003600:	cc6080e7          	jalr	-826(ra) # 800032c2 <argint>
    80003604:	87aa                	mv	a5,a0
    return -1;
    80003606:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    80003608:	0007c863          	bltz	a5,80003618 <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpu_id);
    8000360c:	fec42503          	lw	a0,-20(s0)
    80003610:	fffff097          	auipc	ra,0xfffff
    80003614:	374080e7          	jalr	884(ra) # 80002984 <cpu_process_count>
}
    80003618:	60e2                	ld	ra,24(sp)
    8000361a:	6442                	ld	s0,16(sp)
    8000361c:	6105                	addi	sp,sp,32
    8000361e:	8082                	ret

0000000080003620 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003620:	7179                	addi	sp,sp,-48
    80003622:	f406                	sd	ra,40(sp)
    80003624:	f022                	sd	s0,32(sp)
    80003626:	ec26                	sd	s1,24(sp)
    80003628:	e84a                	sd	s2,16(sp)
    8000362a:	e44e                	sd	s3,8(sp)
    8000362c:	e052                	sd	s4,0(sp)
    8000362e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003630:	00005597          	auipc	a1,0x5
    80003634:	15858593          	addi	a1,a1,344 # 80008788 <syscalls+0xc8>
    80003638:	00014517          	auipc	a0,0x14
    8000363c:	03050513          	addi	a0,a0,48 # 80017668 <bcache>
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	514080e7          	jalr	1300(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003648:	0001c797          	auipc	a5,0x1c
    8000364c:	02078793          	addi	a5,a5,32 # 8001f668 <bcache+0x8000>
    80003650:	0001c717          	auipc	a4,0x1c
    80003654:	28070713          	addi	a4,a4,640 # 8001f8d0 <bcache+0x8268>
    80003658:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000365c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003660:	00014497          	auipc	s1,0x14
    80003664:	02048493          	addi	s1,s1,32 # 80017680 <bcache+0x18>
    b->next = bcache.head.next;
    80003668:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000366a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000366c:	00005a17          	auipc	s4,0x5
    80003670:	124a0a13          	addi	s4,s4,292 # 80008790 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003674:	2b893783          	ld	a5,696(s2)
    80003678:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000367a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000367e:	85d2                	mv	a1,s4
    80003680:	01048513          	addi	a0,s1,16
    80003684:	00001097          	auipc	ra,0x1
    80003688:	4bc080e7          	jalr	1212(ra) # 80004b40 <initsleeplock>
    bcache.head.next->prev = b;
    8000368c:	2b893783          	ld	a5,696(s2)
    80003690:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003692:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003696:	45848493          	addi	s1,s1,1112
    8000369a:	fd349de3          	bne	s1,s3,80003674 <binit+0x54>
  }
}
    8000369e:	70a2                	ld	ra,40(sp)
    800036a0:	7402                	ld	s0,32(sp)
    800036a2:	64e2                	ld	s1,24(sp)
    800036a4:	6942                	ld	s2,16(sp)
    800036a6:	69a2                	ld	s3,8(sp)
    800036a8:	6a02                	ld	s4,0(sp)
    800036aa:	6145                	addi	sp,sp,48
    800036ac:	8082                	ret

00000000800036ae <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800036ae:	7179                	addi	sp,sp,-48
    800036b0:	f406                	sd	ra,40(sp)
    800036b2:	f022                	sd	s0,32(sp)
    800036b4:	ec26                	sd	s1,24(sp)
    800036b6:	e84a                	sd	s2,16(sp)
    800036b8:	e44e                	sd	s3,8(sp)
    800036ba:	1800                	addi	s0,sp,48
    800036bc:	89aa                	mv	s3,a0
    800036be:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800036c0:	00014517          	auipc	a0,0x14
    800036c4:	fa850513          	addi	a0,a0,-88 # 80017668 <bcache>
    800036c8:	ffffd097          	auipc	ra,0xffffd
    800036cc:	51c080e7          	jalr	1308(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800036d0:	0001c497          	auipc	s1,0x1c
    800036d4:	2504b483          	ld	s1,592(s1) # 8001f920 <bcache+0x82b8>
    800036d8:	0001c797          	auipc	a5,0x1c
    800036dc:	1f878793          	addi	a5,a5,504 # 8001f8d0 <bcache+0x8268>
    800036e0:	02f48f63          	beq	s1,a5,8000371e <bread+0x70>
    800036e4:	873e                	mv	a4,a5
    800036e6:	a021                	j	800036ee <bread+0x40>
    800036e8:	68a4                	ld	s1,80(s1)
    800036ea:	02e48a63          	beq	s1,a4,8000371e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800036ee:	449c                	lw	a5,8(s1)
    800036f0:	ff379ce3          	bne	a5,s3,800036e8 <bread+0x3a>
    800036f4:	44dc                	lw	a5,12(s1)
    800036f6:	ff2799e3          	bne	a5,s2,800036e8 <bread+0x3a>
      b->refcnt++;
    800036fa:	40bc                	lw	a5,64(s1)
    800036fc:	2785                	addiw	a5,a5,1
    800036fe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003700:	00014517          	auipc	a0,0x14
    80003704:	f6850513          	addi	a0,a0,-152 # 80017668 <bcache>
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	590080e7          	jalr	1424(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003710:	01048513          	addi	a0,s1,16
    80003714:	00001097          	auipc	ra,0x1
    80003718:	466080e7          	jalr	1126(ra) # 80004b7a <acquiresleep>
      return b;
    8000371c:	a8b9                	j	8000377a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000371e:	0001c497          	auipc	s1,0x1c
    80003722:	1fa4b483          	ld	s1,506(s1) # 8001f918 <bcache+0x82b0>
    80003726:	0001c797          	auipc	a5,0x1c
    8000372a:	1aa78793          	addi	a5,a5,426 # 8001f8d0 <bcache+0x8268>
    8000372e:	00f48863          	beq	s1,a5,8000373e <bread+0x90>
    80003732:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003734:	40bc                	lw	a5,64(s1)
    80003736:	cf81                	beqz	a5,8000374e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003738:	64a4                	ld	s1,72(s1)
    8000373a:	fee49de3          	bne	s1,a4,80003734 <bread+0x86>
  panic("bget: no buffers");
    8000373e:	00005517          	auipc	a0,0x5
    80003742:	05a50513          	addi	a0,a0,90 # 80008798 <syscalls+0xd8>
    80003746:	ffffd097          	auipc	ra,0xffffd
    8000374a:	df8080e7          	jalr	-520(ra) # 8000053e <panic>
      b->dev = dev;
    8000374e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003752:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003756:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000375a:	4785                	li	a5,1
    8000375c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000375e:	00014517          	auipc	a0,0x14
    80003762:	f0a50513          	addi	a0,a0,-246 # 80017668 <bcache>
    80003766:	ffffd097          	auipc	ra,0xffffd
    8000376a:	532080e7          	jalr	1330(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000376e:	01048513          	addi	a0,s1,16
    80003772:	00001097          	auipc	ra,0x1
    80003776:	408080e7          	jalr	1032(ra) # 80004b7a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000377a:	409c                	lw	a5,0(s1)
    8000377c:	cb89                	beqz	a5,8000378e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000377e:	8526                	mv	a0,s1
    80003780:	70a2                	ld	ra,40(sp)
    80003782:	7402                	ld	s0,32(sp)
    80003784:	64e2                	ld	s1,24(sp)
    80003786:	6942                	ld	s2,16(sp)
    80003788:	69a2                	ld	s3,8(sp)
    8000378a:	6145                	addi	sp,sp,48
    8000378c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000378e:	4581                	li	a1,0
    80003790:	8526                	mv	a0,s1
    80003792:	00003097          	auipc	ra,0x3
    80003796:	f14080e7          	jalr	-236(ra) # 800066a6 <virtio_disk_rw>
    b->valid = 1;
    8000379a:	4785                	li	a5,1
    8000379c:	c09c                	sw	a5,0(s1)
  return b;
    8000379e:	b7c5                	j	8000377e <bread+0xd0>

00000000800037a0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800037a0:	1101                	addi	sp,sp,-32
    800037a2:	ec06                	sd	ra,24(sp)
    800037a4:	e822                	sd	s0,16(sp)
    800037a6:	e426                	sd	s1,8(sp)
    800037a8:	1000                	addi	s0,sp,32
    800037aa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037ac:	0541                	addi	a0,a0,16
    800037ae:	00001097          	auipc	ra,0x1
    800037b2:	466080e7          	jalr	1126(ra) # 80004c14 <holdingsleep>
    800037b6:	cd01                	beqz	a0,800037ce <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800037b8:	4585                	li	a1,1
    800037ba:	8526                	mv	a0,s1
    800037bc:	00003097          	auipc	ra,0x3
    800037c0:	eea080e7          	jalr	-278(ra) # 800066a6 <virtio_disk_rw>
}
    800037c4:	60e2                	ld	ra,24(sp)
    800037c6:	6442                	ld	s0,16(sp)
    800037c8:	64a2                	ld	s1,8(sp)
    800037ca:	6105                	addi	sp,sp,32
    800037cc:	8082                	ret
    panic("bwrite");
    800037ce:	00005517          	auipc	a0,0x5
    800037d2:	fe250513          	addi	a0,a0,-30 # 800087b0 <syscalls+0xf0>
    800037d6:	ffffd097          	auipc	ra,0xffffd
    800037da:	d68080e7          	jalr	-664(ra) # 8000053e <panic>

00000000800037de <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800037de:	1101                	addi	sp,sp,-32
    800037e0:	ec06                	sd	ra,24(sp)
    800037e2:	e822                	sd	s0,16(sp)
    800037e4:	e426                	sd	s1,8(sp)
    800037e6:	e04a                	sd	s2,0(sp)
    800037e8:	1000                	addi	s0,sp,32
    800037ea:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037ec:	01050913          	addi	s2,a0,16
    800037f0:	854a                	mv	a0,s2
    800037f2:	00001097          	auipc	ra,0x1
    800037f6:	422080e7          	jalr	1058(ra) # 80004c14 <holdingsleep>
    800037fa:	c92d                	beqz	a0,8000386c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800037fc:	854a                	mv	a0,s2
    800037fe:	00001097          	auipc	ra,0x1
    80003802:	3d2080e7          	jalr	978(ra) # 80004bd0 <releasesleep>

  acquire(&bcache.lock);
    80003806:	00014517          	auipc	a0,0x14
    8000380a:	e6250513          	addi	a0,a0,-414 # 80017668 <bcache>
    8000380e:	ffffd097          	auipc	ra,0xffffd
    80003812:	3d6080e7          	jalr	982(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003816:	40bc                	lw	a5,64(s1)
    80003818:	37fd                	addiw	a5,a5,-1
    8000381a:	0007871b          	sext.w	a4,a5
    8000381e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003820:	eb05                	bnez	a4,80003850 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003822:	68bc                	ld	a5,80(s1)
    80003824:	64b8                	ld	a4,72(s1)
    80003826:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003828:	64bc                	ld	a5,72(s1)
    8000382a:	68b8                	ld	a4,80(s1)
    8000382c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000382e:	0001c797          	auipc	a5,0x1c
    80003832:	e3a78793          	addi	a5,a5,-454 # 8001f668 <bcache+0x8000>
    80003836:	2b87b703          	ld	a4,696(a5)
    8000383a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000383c:	0001c717          	auipc	a4,0x1c
    80003840:	09470713          	addi	a4,a4,148 # 8001f8d0 <bcache+0x8268>
    80003844:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003846:	2b87b703          	ld	a4,696(a5)
    8000384a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000384c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003850:	00014517          	auipc	a0,0x14
    80003854:	e1850513          	addi	a0,a0,-488 # 80017668 <bcache>
    80003858:	ffffd097          	auipc	ra,0xffffd
    8000385c:	440080e7          	jalr	1088(ra) # 80000c98 <release>
}
    80003860:	60e2                	ld	ra,24(sp)
    80003862:	6442                	ld	s0,16(sp)
    80003864:	64a2                	ld	s1,8(sp)
    80003866:	6902                	ld	s2,0(sp)
    80003868:	6105                	addi	sp,sp,32
    8000386a:	8082                	ret
    panic("brelse");
    8000386c:	00005517          	auipc	a0,0x5
    80003870:	f4c50513          	addi	a0,a0,-180 # 800087b8 <syscalls+0xf8>
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	cca080e7          	jalr	-822(ra) # 8000053e <panic>

000000008000387c <bpin>:

void
bpin(struct buf *b) {
    8000387c:	1101                	addi	sp,sp,-32
    8000387e:	ec06                	sd	ra,24(sp)
    80003880:	e822                	sd	s0,16(sp)
    80003882:	e426                	sd	s1,8(sp)
    80003884:	1000                	addi	s0,sp,32
    80003886:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003888:	00014517          	auipc	a0,0x14
    8000388c:	de050513          	addi	a0,a0,-544 # 80017668 <bcache>
    80003890:	ffffd097          	auipc	ra,0xffffd
    80003894:	354080e7          	jalr	852(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003898:	40bc                	lw	a5,64(s1)
    8000389a:	2785                	addiw	a5,a5,1
    8000389c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000389e:	00014517          	auipc	a0,0x14
    800038a2:	dca50513          	addi	a0,a0,-566 # 80017668 <bcache>
    800038a6:	ffffd097          	auipc	ra,0xffffd
    800038aa:	3f2080e7          	jalr	1010(ra) # 80000c98 <release>
}
    800038ae:	60e2                	ld	ra,24(sp)
    800038b0:	6442                	ld	s0,16(sp)
    800038b2:	64a2                	ld	s1,8(sp)
    800038b4:	6105                	addi	sp,sp,32
    800038b6:	8082                	ret

00000000800038b8 <bunpin>:

void
bunpin(struct buf *b) {
    800038b8:	1101                	addi	sp,sp,-32
    800038ba:	ec06                	sd	ra,24(sp)
    800038bc:	e822                	sd	s0,16(sp)
    800038be:	e426                	sd	s1,8(sp)
    800038c0:	1000                	addi	s0,sp,32
    800038c2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038c4:	00014517          	auipc	a0,0x14
    800038c8:	da450513          	addi	a0,a0,-604 # 80017668 <bcache>
    800038cc:	ffffd097          	auipc	ra,0xffffd
    800038d0:	318080e7          	jalr	792(ra) # 80000be4 <acquire>
  b->refcnt--;
    800038d4:	40bc                	lw	a5,64(s1)
    800038d6:	37fd                	addiw	a5,a5,-1
    800038d8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038da:	00014517          	auipc	a0,0x14
    800038de:	d8e50513          	addi	a0,a0,-626 # 80017668 <bcache>
    800038e2:	ffffd097          	auipc	ra,0xffffd
    800038e6:	3b6080e7          	jalr	950(ra) # 80000c98 <release>
}
    800038ea:	60e2                	ld	ra,24(sp)
    800038ec:	6442                	ld	s0,16(sp)
    800038ee:	64a2                	ld	s1,8(sp)
    800038f0:	6105                	addi	sp,sp,32
    800038f2:	8082                	ret

00000000800038f4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800038f4:	1101                	addi	sp,sp,-32
    800038f6:	ec06                	sd	ra,24(sp)
    800038f8:	e822                	sd	s0,16(sp)
    800038fa:	e426                	sd	s1,8(sp)
    800038fc:	e04a                	sd	s2,0(sp)
    800038fe:	1000                	addi	s0,sp,32
    80003900:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003902:	00d5d59b          	srliw	a1,a1,0xd
    80003906:	0001c797          	auipc	a5,0x1c
    8000390a:	43e7a783          	lw	a5,1086(a5) # 8001fd44 <sb+0x1c>
    8000390e:	9dbd                	addw	a1,a1,a5
    80003910:	00000097          	auipc	ra,0x0
    80003914:	d9e080e7          	jalr	-610(ra) # 800036ae <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003918:	0074f713          	andi	a4,s1,7
    8000391c:	4785                	li	a5,1
    8000391e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003922:	14ce                	slli	s1,s1,0x33
    80003924:	90d9                	srli	s1,s1,0x36
    80003926:	00950733          	add	a4,a0,s1
    8000392a:	05874703          	lbu	a4,88(a4)
    8000392e:	00e7f6b3          	and	a3,a5,a4
    80003932:	c69d                	beqz	a3,80003960 <bfree+0x6c>
    80003934:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003936:	94aa                	add	s1,s1,a0
    80003938:	fff7c793          	not	a5,a5
    8000393c:	8ff9                	and	a5,a5,a4
    8000393e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003942:	00001097          	auipc	ra,0x1
    80003946:	118080e7          	jalr	280(ra) # 80004a5a <log_write>
  brelse(bp);
    8000394a:	854a                	mv	a0,s2
    8000394c:	00000097          	auipc	ra,0x0
    80003950:	e92080e7          	jalr	-366(ra) # 800037de <brelse>
}
    80003954:	60e2                	ld	ra,24(sp)
    80003956:	6442                	ld	s0,16(sp)
    80003958:	64a2                	ld	s1,8(sp)
    8000395a:	6902                	ld	s2,0(sp)
    8000395c:	6105                	addi	sp,sp,32
    8000395e:	8082                	ret
    panic("freeing free block");
    80003960:	00005517          	auipc	a0,0x5
    80003964:	e6050513          	addi	a0,a0,-416 # 800087c0 <syscalls+0x100>
    80003968:	ffffd097          	auipc	ra,0xffffd
    8000396c:	bd6080e7          	jalr	-1066(ra) # 8000053e <panic>

0000000080003970 <balloc>:
{
    80003970:	711d                	addi	sp,sp,-96
    80003972:	ec86                	sd	ra,88(sp)
    80003974:	e8a2                	sd	s0,80(sp)
    80003976:	e4a6                	sd	s1,72(sp)
    80003978:	e0ca                	sd	s2,64(sp)
    8000397a:	fc4e                	sd	s3,56(sp)
    8000397c:	f852                	sd	s4,48(sp)
    8000397e:	f456                	sd	s5,40(sp)
    80003980:	f05a                	sd	s6,32(sp)
    80003982:	ec5e                	sd	s7,24(sp)
    80003984:	e862                	sd	s8,16(sp)
    80003986:	e466                	sd	s9,8(sp)
    80003988:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000398a:	0001c797          	auipc	a5,0x1c
    8000398e:	3a27a783          	lw	a5,930(a5) # 8001fd2c <sb+0x4>
    80003992:	cbd1                	beqz	a5,80003a26 <balloc+0xb6>
    80003994:	8baa                	mv	s7,a0
    80003996:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003998:	0001cb17          	auipc	s6,0x1c
    8000399c:	390b0b13          	addi	s6,s6,912 # 8001fd28 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039a0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800039a2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039a4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800039a6:	6c89                	lui	s9,0x2
    800039a8:	a831                	j	800039c4 <balloc+0x54>
    brelse(bp);
    800039aa:	854a                	mv	a0,s2
    800039ac:	00000097          	auipc	ra,0x0
    800039b0:	e32080e7          	jalr	-462(ra) # 800037de <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800039b4:	015c87bb          	addw	a5,s9,s5
    800039b8:	00078a9b          	sext.w	s5,a5
    800039bc:	004b2703          	lw	a4,4(s6)
    800039c0:	06eaf363          	bgeu	s5,a4,80003a26 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800039c4:	41fad79b          	sraiw	a5,s5,0x1f
    800039c8:	0137d79b          	srliw	a5,a5,0x13
    800039cc:	015787bb          	addw	a5,a5,s5
    800039d0:	40d7d79b          	sraiw	a5,a5,0xd
    800039d4:	01cb2583          	lw	a1,28(s6)
    800039d8:	9dbd                	addw	a1,a1,a5
    800039da:	855e                	mv	a0,s7
    800039dc:	00000097          	auipc	ra,0x0
    800039e0:	cd2080e7          	jalr	-814(ra) # 800036ae <bread>
    800039e4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039e6:	004b2503          	lw	a0,4(s6)
    800039ea:	000a849b          	sext.w	s1,s5
    800039ee:	8662                	mv	a2,s8
    800039f0:	faa4fde3          	bgeu	s1,a0,800039aa <balloc+0x3a>
      m = 1 << (bi % 8);
    800039f4:	41f6579b          	sraiw	a5,a2,0x1f
    800039f8:	01d7d69b          	srliw	a3,a5,0x1d
    800039fc:	00c6873b          	addw	a4,a3,a2
    80003a00:	00777793          	andi	a5,a4,7
    80003a04:	9f95                	subw	a5,a5,a3
    80003a06:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a0a:	4037571b          	sraiw	a4,a4,0x3
    80003a0e:	00e906b3          	add	a3,s2,a4
    80003a12:	0586c683          	lbu	a3,88(a3)
    80003a16:	00d7f5b3          	and	a1,a5,a3
    80003a1a:	cd91                	beqz	a1,80003a36 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a1c:	2605                	addiw	a2,a2,1
    80003a1e:	2485                	addiw	s1,s1,1
    80003a20:	fd4618e3          	bne	a2,s4,800039f0 <balloc+0x80>
    80003a24:	b759                	j	800039aa <balloc+0x3a>
  panic("balloc: out of blocks");
    80003a26:	00005517          	auipc	a0,0x5
    80003a2a:	db250513          	addi	a0,a0,-590 # 800087d8 <syscalls+0x118>
    80003a2e:	ffffd097          	auipc	ra,0xffffd
    80003a32:	b10080e7          	jalr	-1264(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003a36:	974a                	add	a4,a4,s2
    80003a38:	8fd5                	or	a5,a5,a3
    80003a3a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003a3e:	854a                	mv	a0,s2
    80003a40:	00001097          	auipc	ra,0x1
    80003a44:	01a080e7          	jalr	26(ra) # 80004a5a <log_write>
        brelse(bp);
    80003a48:	854a                	mv	a0,s2
    80003a4a:	00000097          	auipc	ra,0x0
    80003a4e:	d94080e7          	jalr	-620(ra) # 800037de <brelse>
  bp = bread(dev, bno);
    80003a52:	85a6                	mv	a1,s1
    80003a54:	855e                	mv	a0,s7
    80003a56:	00000097          	auipc	ra,0x0
    80003a5a:	c58080e7          	jalr	-936(ra) # 800036ae <bread>
    80003a5e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003a60:	40000613          	li	a2,1024
    80003a64:	4581                	li	a1,0
    80003a66:	05850513          	addi	a0,a0,88
    80003a6a:	ffffd097          	auipc	ra,0xffffd
    80003a6e:	276080e7          	jalr	630(ra) # 80000ce0 <memset>
  log_write(bp);
    80003a72:	854a                	mv	a0,s2
    80003a74:	00001097          	auipc	ra,0x1
    80003a78:	fe6080e7          	jalr	-26(ra) # 80004a5a <log_write>
  brelse(bp);
    80003a7c:	854a                	mv	a0,s2
    80003a7e:	00000097          	auipc	ra,0x0
    80003a82:	d60080e7          	jalr	-672(ra) # 800037de <brelse>
}
    80003a86:	8526                	mv	a0,s1
    80003a88:	60e6                	ld	ra,88(sp)
    80003a8a:	6446                	ld	s0,80(sp)
    80003a8c:	64a6                	ld	s1,72(sp)
    80003a8e:	6906                	ld	s2,64(sp)
    80003a90:	79e2                	ld	s3,56(sp)
    80003a92:	7a42                	ld	s4,48(sp)
    80003a94:	7aa2                	ld	s5,40(sp)
    80003a96:	7b02                	ld	s6,32(sp)
    80003a98:	6be2                	ld	s7,24(sp)
    80003a9a:	6c42                	ld	s8,16(sp)
    80003a9c:	6ca2                	ld	s9,8(sp)
    80003a9e:	6125                	addi	sp,sp,96
    80003aa0:	8082                	ret

0000000080003aa2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003aa2:	7179                	addi	sp,sp,-48
    80003aa4:	f406                	sd	ra,40(sp)
    80003aa6:	f022                	sd	s0,32(sp)
    80003aa8:	ec26                	sd	s1,24(sp)
    80003aaa:	e84a                	sd	s2,16(sp)
    80003aac:	e44e                	sd	s3,8(sp)
    80003aae:	e052                	sd	s4,0(sp)
    80003ab0:	1800                	addi	s0,sp,48
    80003ab2:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ab4:	47ad                	li	a5,11
    80003ab6:	04b7fe63          	bgeu	a5,a1,80003b12 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003aba:	ff45849b          	addiw	s1,a1,-12
    80003abe:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003ac2:	0ff00793          	li	a5,255
    80003ac6:	0ae7e363          	bltu	a5,a4,80003b6c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003aca:	08052583          	lw	a1,128(a0)
    80003ace:	c5ad                	beqz	a1,80003b38 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003ad0:	00092503          	lw	a0,0(s2)
    80003ad4:	00000097          	auipc	ra,0x0
    80003ad8:	bda080e7          	jalr	-1062(ra) # 800036ae <bread>
    80003adc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003ade:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003ae2:	02049593          	slli	a1,s1,0x20
    80003ae6:	9181                	srli	a1,a1,0x20
    80003ae8:	058a                	slli	a1,a1,0x2
    80003aea:	00b784b3          	add	s1,a5,a1
    80003aee:	0004a983          	lw	s3,0(s1)
    80003af2:	04098d63          	beqz	s3,80003b4c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003af6:	8552                	mv	a0,s4
    80003af8:	00000097          	auipc	ra,0x0
    80003afc:	ce6080e7          	jalr	-794(ra) # 800037de <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b00:	854e                	mv	a0,s3
    80003b02:	70a2                	ld	ra,40(sp)
    80003b04:	7402                	ld	s0,32(sp)
    80003b06:	64e2                	ld	s1,24(sp)
    80003b08:	6942                	ld	s2,16(sp)
    80003b0a:	69a2                	ld	s3,8(sp)
    80003b0c:	6a02                	ld	s4,0(sp)
    80003b0e:	6145                	addi	sp,sp,48
    80003b10:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003b12:	02059493          	slli	s1,a1,0x20
    80003b16:	9081                	srli	s1,s1,0x20
    80003b18:	048a                	slli	s1,s1,0x2
    80003b1a:	94aa                	add	s1,s1,a0
    80003b1c:	0504a983          	lw	s3,80(s1)
    80003b20:	fe0990e3          	bnez	s3,80003b00 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003b24:	4108                	lw	a0,0(a0)
    80003b26:	00000097          	auipc	ra,0x0
    80003b2a:	e4a080e7          	jalr	-438(ra) # 80003970 <balloc>
    80003b2e:	0005099b          	sext.w	s3,a0
    80003b32:	0534a823          	sw	s3,80(s1)
    80003b36:	b7e9                	j	80003b00 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003b38:	4108                	lw	a0,0(a0)
    80003b3a:	00000097          	auipc	ra,0x0
    80003b3e:	e36080e7          	jalr	-458(ra) # 80003970 <balloc>
    80003b42:	0005059b          	sext.w	a1,a0
    80003b46:	08b92023          	sw	a1,128(s2)
    80003b4a:	b759                	j	80003ad0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003b4c:	00092503          	lw	a0,0(s2)
    80003b50:	00000097          	auipc	ra,0x0
    80003b54:	e20080e7          	jalr	-480(ra) # 80003970 <balloc>
    80003b58:	0005099b          	sext.w	s3,a0
    80003b5c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003b60:	8552                	mv	a0,s4
    80003b62:	00001097          	auipc	ra,0x1
    80003b66:	ef8080e7          	jalr	-264(ra) # 80004a5a <log_write>
    80003b6a:	b771                	j	80003af6 <bmap+0x54>
  panic("bmap: out of range");
    80003b6c:	00005517          	auipc	a0,0x5
    80003b70:	c8450513          	addi	a0,a0,-892 # 800087f0 <syscalls+0x130>
    80003b74:	ffffd097          	auipc	ra,0xffffd
    80003b78:	9ca080e7          	jalr	-1590(ra) # 8000053e <panic>

0000000080003b7c <iget>:
{
    80003b7c:	7179                	addi	sp,sp,-48
    80003b7e:	f406                	sd	ra,40(sp)
    80003b80:	f022                	sd	s0,32(sp)
    80003b82:	ec26                	sd	s1,24(sp)
    80003b84:	e84a                	sd	s2,16(sp)
    80003b86:	e44e                	sd	s3,8(sp)
    80003b88:	e052                	sd	s4,0(sp)
    80003b8a:	1800                	addi	s0,sp,48
    80003b8c:	89aa                	mv	s3,a0
    80003b8e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003b90:	0001c517          	auipc	a0,0x1c
    80003b94:	1b850513          	addi	a0,a0,440 # 8001fd48 <itable>
    80003b98:	ffffd097          	auipc	ra,0xffffd
    80003b9c:	04c080e7          	jalr	76(ra) # 80000be4 <acquire>
  empty = 0;
    80003ba0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ba2:	0001c497          	auipc	s1,0x1c
    80003ba6:	1be48493          	addi	s1,s1,446 # 8001fd60 <itable+0x18>
    80003baa:	0001e697          	auipc	a3,0x1e
    80003bae:	c4668693          	addi	a3,a3,-954 # 800217f0 <log>
    80003bb2:	a039                	j	80003bc0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bb4:	02090b63          	beqz	s2,80003bea <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bb8:	08848493          	addi	s1,s1,136
    80003bbc:	02d48a63          	beq	s1,a3,80003bf0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003bc0:	449c                	lw	a5,8(s1)
    80003bc2:	fef059e3          	blez	a5,80003bb4 <iget+0x38>
    80003bc6:	4098                	lw	a4,0(s1)
    80003bc8:	ff3716e3          	bne	a4,s3,80003bb4 <iget+0x38>
    80003bcc:	40d8                	lw	a4,4(s1)
    80003bce:	ff4713e3          	bne	a4,s4,80003bb4 <iget+0x38>
      ip->ref++;
    80003bd2:	2785                	addiw	a5,a5,1
    80003bd4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003bd6:	0001c517          	auipc	a0,0x1c
    80003bda:	17250513          	addi	a0,a0,370 # 8001fd48 <itable>
    80003bde:	ffffd097          	auipc	ra,0xffffd
    80003be2:	0ba080e7          	jalr	186(ra) # 80000c98 <release>
      return ip;
    80003be6:	8926                	mv	s2,s1
    80003be8:	a03d                	j	80003c16 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bea:	f7f9                	bnez	a5,80003bb8 <iget+0x3c>
    80003bec:	8926                	mv	s2,s1
    80003bee:	b7e9                	j	80003bb8 <iget+0x3c>
  if(empty == 0)
    80003bf0:	02090c63          	beqz	s2,80003c28 <iget+0xac>
  ip->dev = dev;
    80003bf4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003bf8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003bfc:	4785                	li	a5,1
    80003bfe:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c02:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c06:	0001c517          	auipc	a0,0x1c
    80003c0a:	14250513          	addi	a0,a0,322 # 8001fd48 <itable>
    80003c0e:	ffffd097          	auipc	ra,0xffffd
    80003c12:	08a080e7          	jalr	138(ra) # 80000c98 <release>
}
    80003c16:	854a                	mv	a0,s2
    80003c18:	70a2                	ld	ra,40(sp)
    80003c1a:	7402                	ld	s0,32(sp)
    80003c1c:	64e2                	ld	s1,24(sp)
    80003c1e:	6942                	ld	s2,16(sp)
    80003c20:	69a2                	ld	s3,8(sp)
    80003c22:	6a02                	ld	s4,0(sp)
    80003c24:	6145                	addi	sp,sp,48
    80003c26:	8082                	ret
    panic("iget: no inodes");
    80003c28:	00005517          	auipc	a0,0x5
    80003c2c:	be050513          	addi	a0,a0,-1056 # 80008808 <syscalls+0x148>
    80003c30:	ffffd097          	auipc	ra,0xffffd
    80003c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080003c38 <fsinit>:
fsinit(int dev) {
    80003c38:	7179                	addi	sp,sp,-48
    80003c3a:	f406                	sd	ra,40(sp)
    80003c3c:	f022                	sd	s0,32(sp)
    80003c3e:	ec26                	sd	s1,24(sp)
    80003c40:	e84a                	sd	s2,16(sp)
    80003c42:	e44e                	sd	s3,8(sp)
    80003c44:	1800                	addi	s0,sp,48
    80003c46:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c48:	4585                	li	a1,1
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	a64080e7          	jalr	-1436(ra) # 800036ae <bread>
    80003c52:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c54:	0001c997          	auipc	s3,0x1c
    80003c58:	0d498993          	addi	s3,s3,212 # 8001fd28 <sb>
    80003c5c:	02000613          	li	a2,32
    80003c60:	05850593          	addi	a1,a0,88
    80003c64:	854e                	mv	a0,s3
    80003c66:	ffffd097          	auipc	ra,0xffffd
    80003c6a:	0da080e7          	jalr	218(ra) # 80000d40 <memmove>
  brelse(bp);
    80003c6e:	8526                	mv	a0,s1
    80003c70:	00000097          	auipc	ra,0x0
    80003c74:	b6e080e7          	jalr	-1170(ra) # 800037de <brelse>
  if(sb.magic != FSMAGIC)
    80003c78:	0009a703          	lw	a4,0(s3)
    80003c7c:	102037b7          	lui	a5,0x10203
    80003c80:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c84:	02f71263          	bne	a4,a5,80003ca8 <fsinit+0x70>
  initlog(dev, &sb);
    80003c88:	0001c597          	auipc	a1,0x1c
    80003c8c:	0a058593          	addi	a1,a1,160 # 8001fd28 <sb>
    80003c90:	854a                	mv	a0,s2
    80003c92:	00001097          	auipc	ra,0x1
    80003c96:	b4c080e7          	jalr	-1204(ra) # 800047de <initlog>
}
    80003c9a:	70a2                	ld	ra,40(sp)
    80003c9c:	7402                	ld	s0,32(sp)
    80003c9e:	64e2                	ld	s1,24(sp)
    80003ca0:	6942                	ld	s2,16(sp)
    80003ca2:	69a2                	ld	s3,8(sp)
    80003ca4:	6145                	addi	sp,sp,48
    80003ca6:	8082                	ret
    panic("invalid file system");
    80003ca8:	00005517          	auipc	a0,0x5
    80003cac:	b7050513          	addi	a0,a0,-1168 # 80008818 <syscalls+0x158>
    80003cb0:	ffffd097          	auipc	ra,0xffffd
    80003cb4:	88e080e7          	jalr	-1906(ra) # 8000053e <panic>

0000000080003cb8 <iinit>:
{
    80003cb8:	7179                	addi	sp,sp,-48
    80003cba:	f406                	sd	ra,40(sp)
    80003cbc:	f022                	sd	s0,32(sp)
    80003cbe:	ec26                	sd	s1,24(sp)
    80003cc0:	e84a                	sd	s2,16(sp)
    80003cc2:	e44e                	sd	s3,8(sp)
    80003cc4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003cc6:	00005597          	auipc	a1,0x5
    80003cca:	b6a58593          	addi	a1,a1,-1174 # 80008830 <syscalls+0x170>
    80003cce:	0001c517          	auipc	a0,0x1c
    80003cd2:	07a50513          	addi	a0,a0,122 # 8001fd48 <itable>
    80003cd6:	ffffd097          	auipc	ra,0xffffd
    80003cda:	e7e080e7          	jalr	-386(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003cde:	0001c497          	auipc	s1,0x1c
    80003ce2:	09248493          	addi	s1,s1,146 # 8001fd70 <itable+0x28>
    80003ce6:	0001e997          	auipc	s3,0x1e
    80003cea:	b1a98993          	addi	s3,s3,-1254 # 80021800 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003cee:	00005917          	auipc	s2,0x5
    80003cf2:	b4a90913          	addi	s2,s2,-1206 # 80008838 <syscalls+0x178>
    80003cf6:	85ca                	mv	a1,s2
    80003cf8:	8526                	mv	a0,s1
    80003cfa:	00001097          	auipc	ra,0x1
    80003cfe:	e46080e7          	jalr	-442(ra) # 80004b40 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d02:	08848493          	addi	s1,s1,136
    80003d06:	ff3498e3          	bne	s1,s3,80003cf6 <iinit+0x3e>
}
    80003d0a:	70a2                	ld	ra,40(sp)
    80003d0c:	7402                	ld	s0,32(sp)
    80003d0e:	64e2                	ld	s1,24(sp)
    80003d10:	6942                	ld	s2,16(sp)
    80003d12:	69a2                	ld	s3,8(sp)
    80003d14:	6145                	addi	sp,sp,48
    80003d16:	8082                	ret

0000000080003d18 <ialloc>:
{
    80003d18:	715d                	addi	sp,sp,-80
    80003d1a:	e486                	sd	ra,72(sp)
    80003d1c:	e0a2                	sd	s0,64(sp)
    80003d1e:	fc26                	sd	s1,56(sp)
    80003d20:	f84a                	sd	s2,48(sp)
    80003d22:	f44e                	sd	s3,40(sp)
    80003d24:	f052                	sd	s4,32(sp)
    80003d26:	ec56                	sd	s5,24(sp)
    80003d28:	e85a                	sd	s6,16(sp)
    80003d2a:	e45e                	sd	s7,8(sp)
    80003d2c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d2e:	0001c717          	auipc	a4,0x1c
    80003d32:	00672703          	lw	a4,6(a4) # 8001fd34 <sb+0xc>
    80003d36:	4785                	li	a5,1
    80003d38:	04e7fa63          	bgeu	a5,a4,80003d8c <ialloc+0x74>
    80003d3c:	8aaa                	mv	s5,a0
    80003d3e:	8bae                	mv	s7,a1
    80003d40:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d42:	0001ca17          	auipc	s4,0x1c
    80003d46:	fe6a0a13          	addi	s4,s4,-26 # 8001fd28 <sb>
    80003d4a:	00048b1b          	sext.w	s6,s1
    80003d4e:	0044d593          	srli	a1,s1,0x4
    80003d52:	018a2783          	lw	a5,24(s4)
    80003d56:	9dbd                	addw	a1,a1,a5
    80003d58:	8556                	mv	a0,s5
    80003d5a:	00000097          	auipc	ra,0x0
    80003d5e:	954080e7          	jalr	-1708(ra) # 800036ae <bread>
    80003d62:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d64:	05850993          	addi	s3,a0,88
    80003d68:	00f4f793          	andi	a5,s1,15
    80003d6c:	079a                	slli	a5,a5,0x6
    80003d6e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d70:	00099783          	lh	a5,0(s3)
    80003d74:	c785                	beqz	a5,80003d9c <ialloc+0x84>
    brelse(bp);
    80003d76:	00000097          	auipc	ra,0x0
    80003d7a:	a68080e7          	jalr	-1432(ra) # 800037de <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d7e:	0485                	addi	s1,s1,1
    80003d80:	00ca2703          	lw	a4,12(s4)
    80003d84:	0004879b          	sext.w	a5,s1
    80003d88:	fce7e1e3          	bltu	a5,a4,80003d4a <ialloc+0x32>
  panic("ialloc: no inodes");
    80003d8c:	00005517          	auipc	a0,0x5
    80003d90:	ab450513          	addi	a0,a0,-1356 # 80008840 <syscalls+0x180>
    80003d94:	ffffc097          	auipc	ra,0xffffc
    80003d98:	7aa080e7          	jalr	1962(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003d9c:	04000613          	li	a2,64
    80003da0:	4581                	li	a1,0
    80003da2:	854e                	mv	a0,s3
    80003da4:	ffffd097          	auipc	ra,0xffffd
    80003da8:	f3c080e7          	jalr	-196(ra) # 80000ce0 <memset>
      dip->type = type;
    80003dac:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003db0:	854a                	mv	a0,s2
    80003db2:	00001097          	auipc	ra,0x1
    80003db6:	ca8080e7          	jalr	-856(ra) # 80004a5a <log_write>
      brelse(bp);
    80003dba:	854a                	mv	a0,s2
    80003dbc:	00000097          	auipc	ra,0x0
    80003dc0:	a22080e7          	jalr	-1502(ra) # 800037de <brelse>
      return iget(dev, inum);
    80003dc4:	85da                	mv	a1,s6
    80003dc6:	8556                	mv	a0,s5
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	db4080e7          	jalr	-588(ra) # 80003b7c <iget>
}
    80003dd0:	60a6                	ld	ra,72(sp)
    80003dd2:	6406                	ld	s0,64(sp)
    80003dd4:	74e2                	ld	s1,56(sp)
    80003dd6:	7942                	ld	s2,48(sp)
    80003dd8:	79a2                	ld	s3,40(sp)
    80003dda:	7a02                	ld	s4,32(sp)
    80003ddc:	6ae2                	ld	s5,24(sp)
    80003dde:	6b42                	ld	s6,16(sp)
    80003de0:	6ba2                	ld	s7,8(sp)
    80003de2:	6161                	addi	sp,sp,80
    80003de4:	8082                	ret

0000000080003de6 <iupdate>:
{
    80003de6:	1101                	addi	sp,sp,-32
    80003de8:	ec06                	sd	ra,24(sp)
    80003dea:	e822                	sd	s0,16(sp)
    80003dec:	e426                	sd	s1,8(sp)
    80003dee:	e04a                	sd	s2,0(sp)
    80003df0:	1000                	addi	s0,sp,32
    80003df2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003df4:	415c                	lw	a5,4(a0)
    80003df6:	0047d79b          	srliw	a5,a5,0x4
    80003dfa:	0001c597          	auipc	a1,0x1c
    80003dfe:	f465a583          	lw	a1,-186(a1) # 8001fd40 <sb+0x18>
    80003e02:	9dbd                	addw	a1,a1,a5
    80003e04:	4108                	lw	a0,0(a0)
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	8a8080e7          	jalr	-1880(ra) # 800036ae <bread>
    80003e0e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e10:	05850793          	addi	a5,a0,88
    80003e14:	40c8                	lw	a0,4(s1)
    80003e16:	893d                	andi	a0,a0,15
    80003e18:	051a                	slli	a0,a0,0x6
    80003e1a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003e1c:	04449703          	lh	a4,68(s1)
    80003e20:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003e24:	04649703          	lh	a4,70(s1)
    80003e28:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003e2c:	04849703          	lh	a4,72(s1)
    80003e30:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003e34:	04a49703          	lh	a4,74(s1)
    80003e38:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003e3c:	44f8                	lw	a4,76(s1)
    80003e3e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e40:	03400613          	li	a2,52
    80003e44:	05048593          	addi	a1,s1,80
    80003e48:	0531                	addi	a0,a0,12
    80003e4a:	ffffd097          	auipc	ra,0xffffd
    80003e4e:	ef6080e7          	jalr	-266(ra) # 80000d40 <memmove>
  log_write(bp);
    80003e52:	854a                	mv	a0,s2
    80003e54:	00001097          	auipc	ra,0x1
    80003e58:	c06080e7          	jalr	-1018(ra) # 80004a5a <log_write>
  brelse(bp);
    80003e5c:	854a                	mv	a0,s2
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	980080e7          	jalr	-1664(ra) # 800037de <brelse>
}
    80003e66:	60e2                	ld	ra,24(sp)
    80003e68:	6442                	ld	s0,16(sp)
    80003e6a:	64a2                	ld	s1,8(sp)
    80003e6c:	6902                	ld	s2,0(sp)
    80003e6e:	6105                	addi	sp,sp,32
    80003e70:	8082                	ret

0000000080003e72 <idup>:
{
    80003e72:	1101                	addi	sp,sp,-32
    80003e74:	ec06                	sd	ra,24(sp)
    80003e76:	e822                	sd	s0,16(sp)
    80003e78:	e426                	sd	s1,8(sp)
    80003e7a:	1000                	addi	s0,sp,32
    80003e7c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e7e:	0001c517          	auipc	a0,0x1c
    80003e82:	eca50513          	addi	a0,a0,-310 # 8001fd48 <itable>
    80003e86:	ffffd097          	auipc	ra,0xffffd
    80003e8a:	d5e080e7          	jalr	-674(ra) # 80000be4 <acquire>
  ip->ref++;
    80003e8e:	449c                	lw	a5,8(s1)
    80003e90:	2785                	addiw	a5,a5,1
    80003e92:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e94:	0001c517          	auipc	a0,0x1c
    80003e98:	eb450513          	addi	a0,a0,-332 # 8001fd48 <itable>
    80003e9c:	ffffd097          	auipc	ra,0xffffd
    80003ea0:	dfc080e7          	jalr	-516(ra) # 80000c98 <release>
}
    80003ea4:	8526                	mv	a0,s1
    80003ea6:	60e2                	ld	ra,24(sp)
    80003ea8:	6442                	ld	s0,16(sp)
    80003eaa:	64a2                	ld	s1,8(sp)
    80003eac:	6105                	addi	sp,sp,32
    80003eae:	8082                	ret

0000000080003eb0 <ilock>:
{
    80003eb0:	1101                	addi	sp,sp,-32
    80003eb2:	ec06                	sd	ra,24(sp)
    80003eb4:	e822                	sd	s0,16(sp)
    80003eb6:	e426                	sd	s1,8(sp)
    80003eb8:	e04a                	sd	s2,0(sp)
    80003eba:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ebc:	c115                	beqz	a0,80003ee0 <ilock+0x30>
    80003ebe:	84aa                	mv	s1,a0
    80003ec0:	451c                	lw	a5,8(a0)
    80003ec2:	00f05f63          	blez	a5,80003ee0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ec6:	0541                	addi	a0,a0,16
    80003ec8:	00001097          	auipc	ra,0x1
    80003ecc:	cb2080e7          	jalr	-846(ra) # 80004b7a <acquiresleep>
  if(ip->valid == 0){
    80003ed0:	40bc                	lw	a5,64(s1)
    80003ed2:	cf99                	beqz	a5,80003ef0 <ilock+0x40>
}
    80003ed4:	60e2                	ld	ra,24(sp)
    80003ed6:	6442                	ld	s0,16(sp)
    80003ed8:	64a2                	ld	s1,8(sp)
    80003eda:	6902                	ld	s2,0(sp)
    80003edc:	6105                	addi	sp,sp,32
    80003ede:	8082                	ret
    panic("ilock");
    80003ee0:	00005517          	auipc	a0,0x5
    80003ee4:	97850513          	addi	a0,a0,-1672 # 80008858 <syscalls+0x198>
    80003ee8:	ffffc097          	auipc	ra,0xffffc
    80003eec:	656080e7          	jalr	1622(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ef0:	40dc                	lw	a5,4(s1)
    80003ef2:	0047d79b          	srliw	a5,a5,0x4
    80003ef6:	0001c597          	auipc	a1,0x1c
    80003efa:	e4a5a583          	lw	a1,-438(a1) # 8001fd40 <sb+0x18>
    80003efe:	9dbd                	addw	a1,a1,a5
    80003f00:	4088                	lw	a0,0(s1)
    80003f02:	fffff097          	auipc	ra,0xfffff
    80003f06:	7ac080e7          	jalr	1964(ra) # 800036ae <bread>
    80003f0a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f0c:	05850593          	addi	a1,a0,88
    80003f10:	40dc                	lw	a5,4(s1)
    80003f12:	8bbd                	andi	a5,a5,15
    80003f14:	079a                	slli	a5,a5,0x6
    80003f16:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f18:	00059783          	lh	a5,0(a1)
    80003f1c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f20:	00259783          	lh	a5,2(a1)
    80003f24:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f28:	00459783          	lh	a5,4(a1)
    80003f2c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f30:	00659783          	lh	a5,6(a1)
    80003f34:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f38:	459c                	lw	a5,8(a1)
    80003f3a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f3c:	03400613          	li	a2,52
    80003f40:	05b1                	addi	a1,a1,12
    80003f42:	05048513          	addi	a0,s1,80
    80003f46:	ffffd097          	auipc	ra,0xffffd
    80003f4a:	dfa080e7          	jalr	-518(ra) # 80000d40 <memmove>
    brelse(bp);
    80003f4e:	854a                	mv	a0,s2
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	88e080e7          	jalr	-1906(ra) # 800037de <brelse>
    ip->valid = 1;
    80003f58:	4785                	li	a5,1
    80003f5a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f5c:	04449783          	lh	a5,68(s1)
    80003f60:	fbb5                	bnez	a5,80003ed4 <ilock+0x24>
      panic("ilock: no type");
    80003f62:	00005517          	auipc	a0,0x5
    80003f66:	8fe50513          	addi	a0,a0,-1794 # 80008860 <syscalls+0x1a0>
    80003f6a:	ffffc097          	auipc	ra,0xffffc
    80003f6e:	5d4080e7          	jalr	1492(ra) # 8000053e <panic>

0000000080003f72 <iunlock>:
{
    80003f72:	1101                	addi	sp,sp,-32
    80003f74:	ec06                	sd	ra,24(sp)
    80003f76:	e822                	sd	s0,16(sp)
    80003f78:	e426                	sd	s1,8(sp)
    80003f7a:	e04a                	sd	s2,0(sp)
    80003f7c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f7e:	c905                	beqz	a0,80003fae <iunlock+0x3c>
    80003f80:	84aa                	mv	s1,a0
    80003f82:	01050913          	addi	s2,a0,16
    80003f86:	854a                	mv	a0,s2
    80003f88:	00001097          	auipc	ra,0x1
    80003f8c:	c8c080e7          	jalr	-884(ra) # 80004c14 <holdingsleep>
    80003f90:	cd19                	beqz	a0,80003fae <iunlock+0x3c>
    80003f92:	449c                	lw	a5,8(s1)
    80003f94:	00f05d63          	blez	a5,80003fae <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f98:	854a                	mv	a0,s2
    80003f9a:	00001097          	auipc	ra,0x1
    80003f9e:	c36080e7          	jalr	-970(ra) # 80004bd0 <releasesleep>
}
    80003fa2:	60e2                	ld	ra,24(sp)
    80003fa4:	6442                	ld	s0,16(sp)
    80003fa6:	64a2                	ld	s1,8(sp)
    80003fa8:	6902                	ld	s2,0(sp)
    80003faa:	6105                	addi	sp,sp,32
    80003fac:	8082                	ret
    panic("iunlock");
    80003fae:	00005517          	auipc	a0,0x5
    80003fb2:	8c250513          	addi	a0,a0,-1854 # 80008870 <syscalls+0x1b0>
    80003fb6:	ffffc097          	auipc	ra,0xffffc
    80003fba:	588080e7          	jalr	1416(ra) # 8000053e <panic>

0000000080003fbe <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003fbe:	7179                	addi	sp,sp,-48
    80003fc0:	f406                	sd	ra,40(sp)
    80003fc2:	f022                	sd	s0,32(sp)
    80003fc4:	ec26                	sd	s1,24(sp)
    80003fc6:	e84a                	sd	s2,16(sp)
    80003fc8:	e44e                	sd	s3,8(sp)
    80003fca:	e052                	sd	s4,0(sp)
    80003fcc:	1800                	addi	s0,sp,48
    80003fce:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003fd0:	05050493          	addi	s1,a0,80
    80003fd4:	08050913          	addi	s2,a0,128
    80003fd8:	a021                	j	80003fe0 <itrunc+0x22>
    80003fda:	0491                	addi	s1,s1,4
    80003fdc:	01248d63          	beq	s1,s2,80003ff6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003fe0:	408c                	lw	a1,0(s1)
    80003fe2:	dde5                	beqz	a1,80003fda <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003fe4:	0009a503          	lw	a0,0(s3)
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	90c080e7          	jalr	-1780(ra) # 800038f4 <bfree>
      ip->addrs[i] = 0;
    80003ff0:	0004a023          	sw	zero,0(s1)
    80003ff4:	b7dd                	j	80003fda <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ff6:	0809a583          	lw	a1,128(s3)
    80003ffa:	e185                	bnez	a1,8000401a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ffc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004000:	854e                	mv	a0,s3
    80004002:	00000097          	auipc	ra,0x0
    80004006:	de4080e7          	jalr	-540(ra) # 80003de6 <iupdate>
}
    8000400a:	70a2                	ld	ra,40(sp)
    8000400c:	7402                	ld	s0,32(sp)
    8000400e:	64e2                	ld	s1,24(sp)
    80004010:	6942                	ld	s2,16(sp)
    80004012:	69a2                	ld	s3,8(sp)
    80004014:	6a02                	ld	s4,0(sp)
    80004016:	6145                	addi	sp,sp,48
    80004018:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000401a:	0009a503          	lw	a0,0(s3)
    8000401e:	fffff097          	auipc	ra,0xfffff
    80004022:	690080e7          	jalr	1680(ra) # 800036ae <bread>
    80004026:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004028:	05850493          	addi	s1,a0,88
    8000402c:	45850913          	addi	s2,a0,1112
    80004030:	a811                	j	80004044 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004032:	0009a503          	lw	a0,0(s3)
    80004036:	00000097          	auipc	ra,0x0
    8000403a:	8be080e7          	jalr	-1858(ra) # 800038f4 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000403e:	0491                	addi	s1,s1,4
    80004040:	01248563          	beq	s1,s2,8000404a <itrunc+0x8c>
      if(a[j])
    80004044:	408c                	lw	a1,0(s1)
    80004046:	dde5                	beqz	a1,8000403e <itrunc+0x80>
    80004048:	b7ed                	j	80004032 <itrunc+0x74>
    brelse(bp);
    8000404a:	8552                	mv	a0,s4
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	792080e7          	jalr	1938(ra) # 800037de <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004054:	0809a583          	lw	a1,128(s3)
    80004058:	0009a503          	lw	a0,0(s3)
    8000405c:	00000097          	auipc	ra,0x0
    80004060:	898080e7          	jalr	-1896(ra) # 800038f4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004064:	0809a023          	sw	zero,128(s3)
    80004068:	bf51                	j	80003ffc <itrunc+0x3e>

000000008000406a <iput>:
{
    8000406a:	1101                	addi	sp,sp,-32
    8000406c:	ec06                	sd	ra,24(sp)
    8000406e:	e822                	sd	s0,16(sp)
    80004070:	e426                	sd	s1,8(sp)
    80004072:	e04a                	sd	s2,0(sp)
    80004074:	1000                	addi	s0,sp,32
    80004076:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004078:	0001c517          	auipc	a0,0x1c
    8000407c:	cd050513          	addi	a0,a0,-816 # 8001fd48 <itable>
    80004080:	ffffd097          	auipc	ra,0xffffd
    80004084:	b64080e7          	jalr	-1180(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004088:	4498                	lw	a4,8(s1)
    8000408a:	4785                	li	a5,1
    8000408c:	02f70363          	beq	a4,a5,800040b2 <iput+0x48>
  ip->ref--;
    80004090:	449c                	lw	a5,8(s1)
    80004092:	37fd                	addiw	a5,a5,-1
    80004094:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004096:	0001c517          	auipc	a0,0x1c
    8000409a:	cb250513          	addi	a0,a0,-846 # 8001fd48 <itable>
    8000409e:	ffffd097          	auipc	ra,0xffffd
    800040a2:	bfa080e7          	jalr	-1030(ra) # 80000c98 <release>
}
    800040a6:	60e2                	ld	ra,24(sp)
    800040a8:	6442                	ld	s0,16(sp)
    800040aa:	64a2                	ld	s1,8(sp)
    800040ac:	6902                	ld	s2,0(sp)
    800040ae:	6105                	addi	sp,sp,32
    800040b0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040b2:	40bc                	lw	a5,64(s1)
    800040b4:	dff1                	beqz	a5,80004090 <iput+0x26>
    800040b6:	04a49783          	lh	a5,74(s1)
    800040ba:	fbf9                	bnez	a5,80004090 <iput+0x26>
    acquiresleep(&ip->lock);
    800040bc:	01048913          	addi	s2,s1,16
    800040c0:	854a                	mv	a0,s2
    800040c2:	00001097          	auipc	ra,0x1
    800040c6:	ab8080e7          	jalr	-1352(ra) # 80004b7a <acquiresleep>
    release(&itable.lock);
    800040ca:	0001c517          	auipc	a0,0x1c
    800040ce:	c7e50513          	addi	a0,a0,-898 # 8001fd48 <itable>
    800040d2:	ffffd097          	auipc	ra,0xffffd
    800040d6:	bc6080e7          	jalr	-1082(ra) # 80000c98 <release>
    itrunc(ip);
    800040da:	8526                	mv	a0,s1
    800040dc:	00000097          	auipc	ra,0x0
    800040e0:	ee2080e7          	jalr	-286(ra) # 80003fbe <itrunc>
    ip->type = 0;
    800040e4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800040e8:	8526                	mv	a0,s1
    800040ea:	00000097          	auipc	ra,0x0
    800040ee:	cfc080e7          	jalr	-772(ra) # 80003de6 <iupdate>
    ip->valid = 0;
    800040f2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800040f6:	854a                	mv	a0,s2
    800040f8:	00001097          	auipc	ra,0x1
    800040fc:	ad8080e7          	jalr	-1320(ra) # 80004bd0 <releasesleep>
    acquire(&itable.lock);
    80004100:	0001c517          	auipc	a0,0x1c
    80004104:	c4850513          	addi	a0,a0,-952 # 8001fd48 <itable>
    80004108:	ffffd097          	auipc	ra,0xffffd
    8000410c:	adc080e7          	jalr	-1316(ra) # 80000be4 <acquire>
    80004110:	b741                	j	80004090 <iput+0x26>

0000000080004112 <iunlockput>:
{
    80004112:	1101                	addi	sp,sp,-32
    80004114:	ec06                	sd	ra,24(sp)
    80004116:	e822                	sd	s0,16(sp)
    80004118:	e426                	sd	s1,8(sp)
    8000411a:	1000                	addi	s0,sp,32
    8000411c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000411e:	00000097          	auipc	ra,0x0
    80004122:	e54080e7          	jalr	-428(ra) # 80003f72 <iunlock>
  iput(ip);
    80004126:	8526                	mv	a0,s1
    80004128:	00000097          	auipc	ra,0x0
    8000412c:	f42080e7          	jalr	-190(ra) # 8000406a <iput>
}
    80004130:	60e2                	ld	ra,24(sp)
    80004132:	6442                	ld	s0,16(sp)
    80004134:	64a2                	ld	s1,8(sp)
    80004136:	6105                	addi	sp,sp,32
    80004138:	8082                	ret

000000008000413a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000413a:	1141                	addi	sp,sp,-16
    8000413c:	e422                	sd	s0,8(sp)
    8000413e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004140:	411c                	lw	a5,0(a0)
    80004142:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004144:	415c                	lw	a5,4(a0)
    80004146:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004148:	04451783          	lh	a5,68(a0)
    8000414c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004150:	04a51783          	lh	a5,74(a0)
    80004154:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004158:	04c56783          	lwu	a5,76(a0)
    8000415c:	e99c                	sd	a5,16(a1)
}
    8000415e:	6422                	ld	s0,8(sp)
    80004160:	0141                	addi	sp,sp,16
    80004162:	8082                	ret

0000000080004164 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004164:	457c                	lw	a5,76(a0)
    80004166:	0ed7e963          	bltu	a5,a3,80004258 <readi+0xf4>
{
    8000416a:	7159                	addi	sp,sp,-112
    8000416c:	f486                	sd	ra,104(sp)
    8000416e:	f0a2                	sd	s0,96(sp)
    80004170:	eca6                	sd	s1,88(sp)
    80004172:	e8ca                	sd	s2,80(sp)
    80004174:	e4ce                	sd	s3,72(sp)
    80004176:	e0d2                	sd	s4,64(sp)
    80004178:	fc56                	sd	s5,56(sp)
    8000417a:	f85a                	sd	s6,48(sp)
    8000417c:	f45e                	sd	s7,40(sp)
    8000417e:	f062                	sd	s8,32(sp)
    80004180:	ec66                	sd	s9,24(sp)
    80004182:	e86a                	sd	s10,16(sp)
    80004184:	e46e                	sd	s11,8(sp)
    80004186:	1880                	addi	s0,sp,112
    80004188:	8baa                	mv	s7,a0
    8000418a:	8c2e                	mv	s8,a1
    8000418c:	8ab2                	mv	s5,a2
    8000418e:	84b6                	mv	s1,a3
    80004190:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004192:	9f35                	addw	a4,a4,a3
    return 0;
    80004194:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004196:	0ad76063          	bltu	a4,a3,80004236 <readi+0xd2>
  if(off + n > ip->size)
    8000419a:	00e7f463          	bgeu	a5,a4,800041a2 <readi+0x3e>
    n = ip->size - off;
    8000419e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041a2:	0a0b0963          	beqz	s6,80004254 <readi+0xf0>
    800041a6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041a8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800041ac:	5cfd                	li	s9,-1
    800041ae:	a82d                	j	800041e8 <readi+0x84>
    800041b0:	020a1d93          	slli	s11,s4,0x20
    800041b4:	020ddd93          	srli	s11,s11,0x20
    800041b8:	05890613          	addi	a2,s2,88
    800041bc:	86ee                	mv	a3,s11
    800041be:	963a                	add	a2,a2,a4
    800041c0:	85d6                	mv	a1,s5
    800041c2:	8562                	mv	a0,s8
    800041c4:	ffffe097          	auipc	ra,0xffffe
    800041c8:	5ba080e7          	jalr	1466(ra) # 8000277e <either_copyout>
    800041cc:	05950d63          	beq	a0,s9,80004226 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800041d0:	854a                	mv	a0,s2
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	60c080e7          	jalr	1548(ra) # 800037de <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041da:	013a09bb          	addw	s3,s4,s3
    800041de:	009a04bb          	addw	s1,s4,s1
    800041e2:	9aee                	add	s5,s5,s11
    800041e4:	0569f763          	bgeu	s3,s6,80004232 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800041e8:	000ba903          	lw	s2,0(s7)
    800041ec:	00a4d59b          	srliw	a1,s1,0xa
    800041f0:	855e                	mv	a0,s7
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	8b0080e7          	jalr	-1872(ra) # 80003aa2 <bmap>
    800041fa:	0005059b          	sext.w	a1,a0
    800041fe:	854a                	mv	a0,s2
    80004200:	fffff097          	auipc	ra,0xfffff
    80004204:	4ae080e7          	jalr	1198(ra) # 800036ae <bread>
    80004208:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000420a:	3ff4f713          	andi	a4,s1,1023
    8000420e:	40ed07bb          	subw	a5,s10,a4
    80004212:	413b06bb          	subw	a3,s6,s3
    80004216:	8a3e                	mv	s4,a5
    80004218:	2781                	sext.w	a5,a5
    8000421a:	0006861b          	sext.w	a2,a3
    8000421e:	f8f679e3          	bgeu	a2,a5,800041b0 <readi+0x4c>
    80004222:	8a36                	mv	s4,a3
    80004224:	b771                	j	800041b0 <readi+0x4c>
      brelse(bp);
    80004226:	854a                	mv	a0,s2
    80004228:	fffff097          	auipc	ra,0xfffff
    8000422c:	5b6080e7          	jalr	1462(ra) # 800037de <brelse>
      tot = -1;
    80004230:	59fd                	li	s3,-1
  }
  return tot;
    80004232:	0009851b          	sext.w	a0,s3
}
    80004236:	70a6                	ld	ra,104(sp)
    80004238:	7406                	ld	s0,96(sp)
    8000423a:	64e6                	ld	s1,88(sp)
    8000423c:	6946                	ld	s2,80(sp)
    8000423e:	69a6                	ld	s3,72(sp)
    80004240:	6a06                	ld	s4,64(sp)
    80004242:	7ae2                	ld	s5,56(sp)
    80004244:	7b42                	ld	s6,48(sp)
    80004246:	7ba2                	ld	s7,40(sp)
    80004248:	7c02                	ld	s8,32(sp)
    8000424a:	6ce2                	ld	s9,24(sp)
    8000424c:	6d42                	ld	s10,16(sp)
    8000424e:	6da2                	ld	s11,8(sp)
    80004250:	6165                	addi	sp,sp,112
    80004252:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004254:	89da                	mv	s3,s6
    80004256:	bff1                	j	80004232 <readi+0xce>
    return 0;
    80004258:	4501                	li	a0,0
}
    8000425a:	8082                	ret

000000008000425c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000425c:	457c                	lw	a5,76(a0)
    8000425e:	10d7e863          	bltu	a5,a3,8000436e <writei+0x112>
{
    80004262:	7159                	addi	sp,sp,-112
    80004264:	f486                	sd	ra,104(sp)
    80004266:	f0a2                	sd	s0,96(sp)
    80004268:	eca6                	sd	s1,88(sp)
    8000426a:	e8ca                	sd	s2,80(sp)
    8000426c:	e4ce                	sd	s3,72(sp)
    8000426e:	e0d2                	sd	s4,64(sp)
    80004270:	fc56                	sd	s5,56(sp)
    80004272:	f85a                	sd	s6,48(sp)
    80004274:	f45e                	sd	s7,40(sp)
    80004276:	f062                	sd	s8,32(sp)
    80004278:	ec66                	sd	s9,24(sp)
    8000427a:	e86a                	sd	s10,16(sp)
    8000427c:	e46e                	sd	s11,8(sp)
    8000427e:	1880                	addi	s0,sp,112
    80004280:	8b2a                	mv	s6,a0
    80004282:	8c2e                	mv	s8,a1
    80004284:	8ab2                	mv	s5,a2
    80004286:	8936                	mv	s2,a3
    80004288:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000428a:	00e687bb          	addw	a5,a3,a4
    8000428e:	0ed7e263          	bltu	a5,a3,80004372 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004292:	00043737          	lui	a4,0x43
    80004296:	0ef76063          	bltu	a4,a5,80004376 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000429a:	0c0b8863          	beqz	s7,8000436a <writei+0x10e>
    8000429e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800042a0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800042a4:	5cfd                	li	s9,-1
    800042a6:	a091                	j	800042ea <writei+0x8e>
    800042a8:	02099d93          	slli	s11,s3,0x20
    800042ac:	020ddd93          	srli	s11,s11,0x20
    800042b0:	05848513          	addi	a0,s1,88
    800042b4:	86ee                	mv	a3,s11
    800042b6:	8656                	mv	a2,s5
    800042b8:	85e2                	mv	a1,s8
    800042ba:	953a                	add	a0,a0,a4
    800042bc:	ffffe097          	auipc	ra,0xffffe
    800042c0:	518080e7          	jalr	1304(ra) # 800027d4 <either_copyin>
    800042c4:	07950263          	beq	a0,s9,80004328 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800042c8:	8526                	mv	a0,s1
    800042ca:	00000097          	auipc	ra,0x0
    800042ce:	790080e7          	jalr	1936(ra) # 80004a5a <log_write>
    brelse(bp);
    800042d2:	8526                	mv	a0,s1
    800042d4:	fffff097          	auipc	ra,0xfffff
    800042d8:	50a080e7          	jalr	1290(ra) # 800037de <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042dc:	01498a3b          	addw	s4,s3,s4
    800042e0:	0129893b          	addw	s2,s3,s2
    800042e4:	9aee                	add	s5,s5,s11
    800042e6:	057a7663          	bgeu	s4,s7,80004332 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800042ea:	000b2483          	lw	s1,0(s6)
    800042ee:	00a9559b          	srliw	a1,s2,0xa
    800042f2:	855a                	mv	a0,s6
    800042f4:	fffff097          	auipc	ra,0xfffff
    800042f8:	7ae080e7          	jalr	1966(ra) # 80003aa2 <bmap>
    800042fc:	0005059b          	sext.w	a1,a0
    80004300:	8526                	mv	a0,s1
    80004302:	fffff097          	auipc	ra,0xfffff
    80004306:	3ac080e7          	jalr	940(ra) # 800036ae <bread>
    8000430a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000430c:	3ff97713          	andi	a4,s2,1023
    80004310:	40ed07bb          	subw	a5,s10,a4
    80004314:	414b86bb          	subw	a3,s7,s4
    80004318:	89be                	mv	s3,a5
    8000431a:	2781                	sext.w	a5,a5
    8000431c:	0006861b          	sext.w	a2,a3
    80004320:	f8f674e3          	bgeu	a2,a5,800042a8 <writei+0x4c>
    80004324:	89b6                	mv	s3,a3
    80004326:	b749                	j	800042a8 <writei+0x4c>
      brelse(bp);
    80004328:	8526                	mv	a0,s1
    8000432a:	fffff097          	auipc	ra,0xfffff
    8000432e:	4b4080e7          	jalr	1204(ra) # 800037de <brelse>
  }

  if(off > ip->size)
    80004332:	04cb2783          	lw	a5,76(s6)
    80004336:	0127f463          	bgeu	a5,s2,8000433e <writei+0xe2>
    ip->size = off;
    8000433a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000433e:	855a                	mv	a0,s6
    80004340:	00000097          	auipc	ra,0x0
    80004344:	aa6080e7          	jalr	-1370(ra) # 80003de6 <iupdate>

  return tot;
    80004348:	000a051b          	sext.w	a0,s4
}
    8000434c:	70a6                	ld	ra,104(sp)
    8000434e:	7406                	ld	s0,96(sp)
    80004350:	64e6                	ld	s1,88(sp)
    80004352:	6946                	ld	s2,80(sp)
    80004354:	69a6                	ld	s3,72(sp)
    80004356:	6a06                	ld	s4,64(sp)
    80004358:	7ae2                	ld	s5,56(sp)
    8000435a:	7b42                	ld	s6,48(sp)
    8000435c:	7ba2                	ld	s7,40(sp)
    8000435e:	7c02                	ld	s8,32(sp)
    80004360:	6ce2                	ld	s9,24(sp)
    80004362:	6d42                	ld	s10,16(sp)
    80004364:	6da2                	ld	s11,8(sp)
    80004366:	6165                	addi	sp,sp,112
    80004368:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000436a:	8a5e                	mv	s4,s7
    8000436c:	bfc9                	j	8000433e <writei+0xe2>
    return -1;
    8000436e:	557d                	li	a0,-1
}
    80004370:	8082                	ret
    return -1;
    80004372:	557d                	li	a0,-1
    80004374:	bfe1                	j	8000434c <writei+0xf0>
    return -1;
    80004376:	557d                	li	a0,-1
    80004378:	bfd1                	j	8000434c <writei+0xf0>

000000008000437a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000437a:	1141                	addi	sp,sp,-16
    8000437c:	e406                	sd	ra,8(sp)
    8000437e:	e022                	sd	s0,0(sp)
    80004380:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004382:	4639                	li	a2,14
    80004384:	ffffd097          	auipc	ra,0xffffd
    80004388:	a34080e7          	jalr	-1484(ra) # 80000db8 <strncmp>
}
    8000438c:	60a2                	ld	ra,8(sp)
    8000438e:	6402                	ld	s0,0(sp)
    80004390:	0141                	addi	sp,sp,16
    80004392:	8082                	ret

0000000080004394 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004394:	7139                	addi	sp,sp,-64
    80004396:	fc06                	sd	ra,56(sp)
    80004398:	f822                	sd	s0,48(sp)
    8000439a:	f426                	sd	s1,40(sp)
    8000439c:	f04a                	sd	s2,32(sp)
    8000439e:	ec4e                	sd	s3,24(sp)
    800043a0:	e852                	sd	s4,16(sp)
    800043a2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800043a4:	04451703          	lh	a4,68(a0)
    800043a8:	4785                	li	a5,1
    800043aa:	00f71a63          	bne	a4,a5,800043be <dirlookup+0x2a>
    800043ae:	892a                	mv	s2,a0
    800043b0:	89ae                	mv	s3,a1
    800043b2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800043b4:	457c                	lw	a5,76(a0)
    800043b6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800043b8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043ba:	e79d                	bnez	a5,800043e8 <dirlookup+0x54>
    800043bc:	a8a5                	j	80004434 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800043be:	00004517          	auipc	a0,0x4
    800043c2:	4ba50513          	addi	a0,a0,1210 # 80008878 <syscalls+0x1b8>
    800043c6:	ffffc097          	auipc	ra,0xffffc
    800043ca:	178080e7          	jalr	376(ra) # 8000053e <panic>
      panic("dirlookup read");
    800043ce:	00004517          	auipc	a0,0x4
    800043d2:	4c250513          	addi	a0,a0,1218 # 80008890 <syscalls+0x1d0>
    800043d6:	ffffc097          	auipc	ra,0xffffc
    800043da:	168080e7          	jalr	360(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043de:	24c1                	addiw	s1,s1,16
    800043e0:	04c92783          	lw	a5,76(s2)
    800043e4:	04f4f763          	bgeu	s1,a5,80004432 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043e8:	4741                	li	a4,16
    800043ea:	86a6                	mv	a3,s1
    800043ec:	fc040613          	addi	a2,s0,-64
    800043f0:	4581                	li	a1,0
    800043f2:	854a                	mv	a0,s2
    800043f4:	00000097          	auipc	ra,0x0
    800043f8:	d70080e7          	jalr	-656(ra) # 80004164 <readi>
    800043fc:	47c1                	li	a5,16
    800043fe:	fcf518e3          	bne	a0,a5,800043ce <dirlookup+0x3a>
    if(de.inum == 0)
    80004402:	fc045783          	lhu	a5,-64(s0)
    80004406:	dfe1                	beqz	a5,800043de <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004408:	fc240593          	addi	a1,s0,-62
    8000440c:	854e                	mv	a0,s3
    8000440e:	00000097          	auipc	ra,0x0
    80004412:	f6c080e7          	jalr	-148(ra) # 8000437a <namecmp>
    80004416:	f561                	bnez	a0,800043de <dirlookup+0x4a>
      if(poff)
    80004418:	000a0463          	beqz	s4,80004420 <dirlookup+0x8c>
        *poff = off;
    8000441c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004420:	fc045583          	lhu	a1,-64(s0)
    80004424:	00092503          	lw	a0,0(s2)
    80004428:	fffff097          	auipc	ra,0xfffff
    8000442c:	754080e7          	jalr	1876(ra) # 80003b7c <iget>
    80004430:	a011                	j	80004434 <dirlookup+0xa0>
  return 0;
    80004432:	4501                	li	a0,0
}
    80004434:	70e2                	ld	ra,56(sp)
    80004436:	7442                	ld	s0,48(sp)
    80004438:	74a2                	ld	s1,40(sp)
    8000443a:	7902                	ld	s2,32(sp)
    8000443c:	69e2                	ld	s3,24(sp)
    8000443e:	6a42                	ld	s4,16(sp)
    80004440:	6121                	addi	sp,sp,64
    80004442:	8082                	ret

0000000080004444 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004444:	711d                	addi	sp,sp,-96
    80004446:	ec86                	sd	ra,88(sp)
    80004448:	e8a2                	sd	s0,80(sp)
    8000444a:	e4a6                	sd	s1,72(sp)
    8000444c:	e0ca                	sd	s2,64(sp)
    8000444e:	fc4e                	sd	s3,56(sp)
    80004450:	f852                	sd	s4,48(sp)
    80004452:	f456                	sd	s5,40(sp)
    80004454:	f05a                	sd	s6,32(sp)
    80004456:	ec5e                	sd	s7,24(sp)
    80004458:	e862                	sd	s8,16(sp)
    8000445a:	e466                	sd	s9,8(sp)
    8000445c:	1080                	addi	s0,sp,96
    8000445e:	84aa                	mv	s1,a0
    80004460:	8b2e                	mv	s6,a1
    80004462:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004464:	00054703          	lbu	a4,0(a0)
    80004468:	02f00793          	li	a5,47
    8000446c:	02f70363          	beq	a4,a5,80004492 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004470:	ffffe097          	auipc	ra,0xffffe
    80004474:	99c080e7          	jalr	-1636(ra) # 80001e0c <myproc>
    80004478:	15053503          	ld	a0,336(a0)
    8000447c:	00000097          	auipc	ra,0x0
    80004480:	9f6080e7          	jalr	-1546(ra) # 80003e72 <idup>
    80004484:	89aa                	mv	s3,a0
  while(*path == '/')
    80004486:	02f00913          	li	s2,47
  len = path - s;
    8000448a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000448c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000448e:	4c05                	li	s8,1
    80004490:	a865                	j	80004548 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004492:	4585                	li	a1,1
    80004494:	4505                	li	a0,1
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	6e6080e7          	jalr	1766(ra) # 80003b7c <iget>
    8000449e:	89aa                	mv	s3,a0
    800044a0:	b7dd                	j	80004486 <namex+0x42>
      iunlockput(ip);
    800044a2:	854e                	mv	a0,s3
    800044a4:	00000097          	auipc	ra,0x0
    800044a8:	c6e080e7          	jalr	-914(ra) # 80004112 <iunlockput>
      return 0;
    800044ac:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800044ae:	854e                	mv	a0,s3
    800044b0:	60e6                	ld	ra,88(sp)
    800044b2:	6446                	ld	s0,80(sp)
    800044b4:	64a6                	ld	s1,72(sp)
    800044b6:	6906                	ld	s2,64(sp)
    800044b8:	79e2                	ld	s3,56(sp)
    800044ba:	7a42                	ld	s4,48(sp)
    800044bc:	7aa2                	ld	s5,40(sp)
    800044be:	7b02                	ld	s6,32(sp)
    800044c0:	6be2                	ld	s7,24(sp)
    800044c2:	6c42                	ld	s8,16(sp)
    800044c4:	6ca2                	ld	s9,8(sp)
    800044c6:	6125                	addi	sp,sp,96
    800044c8:	8082                	ret
      iunlock(ip);
    800044ca:	854e                	mv	a0,s3
    800044cc:	00000097          	auipc	ra,0x0
    800044d0:	aa6080e7          	jalr	-1370(ra) # 80003f72 <iunlock>
      return ip;
    800044d4:	bfe9                	j	800044ae <namex+0x6a>
      iunlockput(ip);
    800044d6:	854e                	mv	a0,s3
    800044d8:	00000097          	auipc	ra,0x0
    800044dc:	c3a080e7          	jalr	-966(ra) # 80004112 <iunlockput>
      return 0;
    800044e0:	89d2                	mv	s3,s4
    800044e2:	b7f1                	j	800044ae <namex+0x6a>
  len = path - s;
    800044e4:	40b48633          	sub	a2,s1,a1
    800044e8:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800044ec:	094cd463          	bge	s9,s4,80004574 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800044f0:	4639                	li	a2,14
    800044f2:	8556                	mv	a0,s5
    800044f4:	ffffd097          	auipc	ra,0xffffd
    800044f8:	84c080e7          	jalr	-1972(ra) # 80000d40 <memmove>
  while(*path == '/')
    800044fc:	0004c783          	lbu	a5,0(s1)
    80004500:	01279763          	bne	a5,s2,8000450e <namex+0xca>
    path++;
    80004504:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004506:	0004c783          	lbu	a5,0(s1)
    8000450a:	ff278de3          	beq	a5,s2,80004504 <namex+0xc0>
    ilock(ip);
    8000450e:	854e                	mv	a0,s3
    80004510:	00000097          	auipc	ra,0x0
    80004514:	9a0080e7          	jalr	-1632(ra) # 80003eb0 <ilock>
    if(ip->type != T_DIR){
    80004518:	04499783          	lh	a5,68(s3)
    8000451c:	f98793e3          	bne	a5,s8,800044a2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004520:	000b0563          	beqz	s6,8000452a <namex+0xe6>
    80004524:	0004c783          	lbu	a5,0(s1)
    80004528:	d3cd                	beqz	a5,800044ca <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000452a:	865e                	mv	a2,s7
    8000452c:	85d6                	mv	a1,s5
    8000452e:	854e                	mv	a0,s3
    80004530:	00000097          	auipc	ra,0x0
    80004534:	e64080e7          	jalr	-412(ra) # 80004394 <dirlookup>
    80004538:	8a2a                	mv	s4,a0
    8000453a:	dd51                	beqz	a0,800044d6 <namex+0x92>
    iunlockput(ip);
    8000453c:	854e                	mv	a0,s3
    8000453e:	00000097          	auipc	ra,0x0
    80004542:	bd4080e7          	jalr	-1068(ra) # 80004112 <iunlockput>
    ip = next;
    80004546:	89d2                	mv	s3,s4
  while(*path == '/')
    80004548:	0004c783          	lbu	a5,0(s1)
    8000454c:	05279763          	bne	a5,s2,8000459a <namex+0x156>
    path++;
    80004550:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004552:	0004c783          	lbu	a5,0(s1)
    80004556:	ff278de3          	beq	a5,s2,80004550 <namex+0x10c>
  if(*path == 0)
    8000455a:	c79d                	beqz	a5,80004588 <namex+0x144>
    path++;
    8000455c:	85a6                	mv	a1,s1
  len = path - s;
    8000455e:	8a5e                	mv	s4,s7
    80004560:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004562:	01278963          	beq	a5,s2,80004574 <namex+0x130>
    80004566:	dfbd                	beqz	a5,800044e4 <namex+0xa0>
    path++;
    80004568:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000456a:	0004c783          	lbu	a5,0(s1)
    8000456e:	ff279ce3          	bne	a5,s2,80004566 <namex+0x122>
    80004572:	bf8d                	j	800044e4 <namex+0xa0>
    memmove(name, s, len);
    80004574:	2601                	sext.w	a2,a2
    80004576:	8556                	mv	a0,s5
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	7c8080e7          	jalr	1992(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004580:	9a56                	add	s4,s4,s5
    80004582:	000a0023          	sb	zero,0(s4)
    80004586:	bf9d                	j	800044fc <namex+0xb8>
  if(nameiparent){
    80004588:	f20b03e3          	beqz	s6,800044ae <namex+0x6a>
    iput(ip);
    8000458c:	854e                	mv	a0,s3
    8000458e:	00000097          	auipc	ra,0x0
    80004592:	adc080e7          	jalr	-1316(ra) # 8000406a <iput>
    return 0;
    80004596:	4981                	li	s3,0
    80004598:	bf19                	j	800044ae <namex+0x6a>
  if(*path == 0)
    8000459a:	d7fd                	beqz	a5,80004588 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000459c:	0004c783          	lbu	a5,0(s1)
    800045a0:	85a6                	mv	a1,s1
    800045a2:	b7d1                	j	80004566 <namex+0x122>

00000000800045a4 <dirlink>:
{
    800045a4:	7139                	addi	sp,sp,-64
    800045a6:	fc06                	sd	ra,56(sp)
    800045a8:	f822                	sd	s0,48(sp)
    800045aa:	f426                	sd	s1,40(sp)
    800045ac:	f04a                	sd	s2,32(sp)
    800045ae:	ec4e                	sd	s3,24(sp)
    800045b0:	e852                	sd	s4,16(sp)
    800045b2:	0080                	addi	s0,sp,64
    800045b4:	892a                	mv	s2,a0
    800045b6:	8a2e                	mv	s4,a1
    800045b8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800045ba:	4601                	li	a2,0
    800045bc:	00000097          	auipc	ra,0x0
    800045c0:	dd8080e7          	jalr	-552(ra) # 80004394 <dirlookup>
    800045c4:	e93d                	bnez	a0,8000463a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045c6:	04c92483          	lw	s1,76(s2)
    800045ca:	c49d                	beqz	s1,800045f8 <dirlink+0x54>
    800045cc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045ce:	4741                	li	a4,16
    800045d0:	86a6                	mv	a3,s1
    800045d2:	fc040613          	addi	a2,s0,-64
    800045d6:	4581                	li	a1,0
    800045d8:	854a                	mv	a0,s2
    800045da:	00000097          	auipc	ra,0x0
    800045de:	b8a080e7          	jalr	-1142(ra) # 80004164 <readi>
    800045e2:	47c1                	li	a5,16
    800045e4:	06f51163          	bne	a0,a5,80004646 <dirlink+0xa2>
    if(de.inum == 0)
    800045e8:	fc045783          	lhu	a5,-64(s0)
    800045ec:	c791                	beqz	a5,800045f8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045ee:	24c1                	addiw	s1,s1,16
    800045f0:	04c92783          	lw	a5,76(s2)
    800045f4:	fcf4ede3          	bltu	s1,a5,800045ce <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800045f8:	4639                	li	a2,14
    800045fa:	85d2                	mv	a1,s4
    800045fc:	fc240513          	addi	a0,s0,-62
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	7f4080e7          	jalr	2036(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004608:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000460c:	4741                	li	a4,16
    8000460e:	86a6                	mv	a3,s1
    80004610:	fc040613          	addi	a2,s0,-64
    80004614:	4581                	li	a1,0
    80004616:	854a                	mv	a0,s2
    80004618:	00000097          	auipc	ra,0x0
    8000461c:	c44080e7          	jalr	-956(ra) # 8000425c <writei>
    80004620:	872a                	mv	a4,a0
    80004622:	47c1                	li	a5,16
  return 0;
    80004624:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004626:	02f71863          	bne	a4,a5,80004656 <dirlink+0xb2>
}
    8000462a:	70e2                	ld	ra,56(sp)
    8000462c:	7442                	ld	s0,48(sp)
    8000462e:	74a2                	ld	s1,40(sp)
    80004630:	7902                	ld	s2,32(sp)
    80004632:	69e2                	ld	s3,24(sp)
    80004634:	6a42                	ld	s4,16(sp)
    80004636:	6121                	addi	sp,sp,64
    80004638:	8082                	ret
    iput(ip);
    8000463a:	00000097          	auipc	ra,0x0
    8000463e:	a30080e7          	jalr	-1488(ra) # 8000406a <iput>
    return -1;
    80004642:	557d                	li	a0,-1
    80004644:	b7dd                	j	8000462a <dirlink+0x86>
      panic("dirlink read");
    80004646:	00004517          	auipc	a0,0x4
    8000464a:	25a50513          	addi	a0,a0,602 # 800088a0 <syscalls+0x1e0>
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	ef0080e7          	jalr	-272(ra) # 8000053e <panic>
    panic("dirlink");
    80004656:	00004517          	auipc	a0,0x4
    8000465a:	35a50513          	addi	a0,a0,858 # 800089b0 <syscalls+0x2f0>
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	ee0080e7          	jalr	-288(ra) # 8000053e <panic>

0000000080004666 <namei>:

struct inode*
namei(char *path)
{
    80004666:	1101                	addi	sp,sp,-32
    80004668:	ec06                	sd	ra,24(sp)
    8000466a:	e822                	sd	s0,16(sp)
    8000466c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000466e:	fe040613          	addi	a2,s0,-32
    80004672:	4581                	li	a1,0
    80004674:	00000097          	auipc	ra,0x0
    80004678:	dd0080e7          	jalr	-560(ra) # 80004444 <namex>
}
    8000467c:	60e2                	ld	ra,24(sp)
    8000467e:	6442                	ld	s0,16(sp)
    80004680:	6105                	addi	sp,sp,32
    80004682:	8082                	ret

0000000080004684 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004684:	1141                	addi	sp,sp,-16
    80004686:	e406                	sd	ra,8(sp)
    80004688:	e022                	sd	s0,0(sp)
    8000468a:	0800                	addi	s0,sp,16
    8000468c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000468e:	4585                	li	a1,1
    80004690:	00000097          	auipc	ra,0x0
    80004694:	db4080e7          	jalr	-588(ra) # 80004444 <namex>
}
    80004698:	60a2                	ld	ra,8(sp)
    8000469a:	6402                	ld	s0,0(sp)
    8000469c:	0141                	addi	sp,sp,16
    8000469e:	8082                	ret

00000000800046a0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800046a0:	1101                	addi	sp,sp,-32
    800046a2:	ec06                	sd	ra,24(sp)
    800046a4:	e822                	sd	s0,16(sp)
    800046a6:	e426                	sd	s1,8(sp)
    800046a8:	e04a                	sd	s2,0(sp)
    800046aa:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800046ac:	0001d917          	auipc	s2,0x1d
    800046b0:	14490913          	addi	s2,s2,324 # 800217f0 <log>
    800046b4:	01892583          	lw	a1,24(s2)
    800046b8:	02892503          	lw	a0,40(s2)
    800046bc:	fffff097          	auipc	ra,0xfffff
    800046c0:	ff2080e7          	jalr	-14(ra) # 800036ae <bread>
    800046c4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800046c6:	02c92683          	lw	a3,44(s2)
    800046ca:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800046cc:	02d05763          	blez	a3,800046fa <write_head+0x5a>
    800046d0:	0001d797          	auipc	a5,0x1d
    800046d4:	15078793          	addi	a5,a5,336 # 80021820 <log+0x30>
    800046d8:	05c50713          	addi	a4,a0,92
    800046dc:	36fd                	addiw	a3,a3,-1
    800046de:	1682                	slli	a3,a3,0x20
    800046e0:	9281                	srli	a3,a3,0x20
    800046e2:	068a                	slli	a3,a3,0x2
    800046e4:	0001d617          	auipc	a2,0x1d
    800046e8:	14060613          	addi	a2,a2,320 # 80021824 <log+0x34>
    800046ec:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800046ee:	4390                	lw	a2,0(a5)
    800046f0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800046f2:	0791                	addi	a5,a5,4
    800046f4:	0711                	addi	a4,a4,4
    800046f6:	fed79ce3          	bne	a5,a3,800046ee <write_head+0x4e>
  }
  bwrite(buf);
    800046fa:	8526                	mv	a0,s1
    800046fc:	fffff097          	auipc	ra,0xfffff
    80004700:	0a4080e7          	jalr	164(ra) # 800037a0 <bwrite>
  brelse(buf);
    80004704:	8526                	mv	a0,s1
    80004706:	fffff097          	auipc	ra,0xfffff
    8000470a:	0d8080e7          	jalr	216(ra) # 800037de <brelse>
}
    8000470e:	60e2                	ld	ra,24(sp)
    80004710:	6442                	ld	s0,16(sp)
    80004712:	64a2                	ld	s1,8(sp)
    80004714:	6902                	ld	s2,0(sp)
    80004716:	6105                	addi	sp,sp,32
    80004718:	8082                	ret

000000008000471a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000471a:	0001d797          	auipc	a5,0x1d
    8000471e:	1027a783          	lw	a5,258(a5) # 8002181c <log+0x2c>
    80004722:	0af05d63          	blez	a5,800047dc <install_trans+0xc2>
{
    80004726:	7139                	addi	sp,sp,-64
    80004728:	fc06                	sd	ra,56(sp)
    8000472a:	f822                	sd	s0,48(sp)
    8000472c:	f426                	sd	s1,40(sp)
    8000472e:	f04a                	sd	s2,32(sp)
    80004730:	ec4e                	sd	s3,24(sp)
    80004732:	e852                	sd	s4,16(sp)
    80004734:	e456                	sd	s5,8(sp)
    80004736:	e05a                	sd	s6,0(sp)
    80004738:	0080                	addi	s0,sp,64
    8000473a:	8b2a                	mv	s6,a0
    8000473c:	0001da97          	auipc	s5,0x1d
    80004740:	0e4a8a93          	addi	s5,s5,228 # 80021820 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004744:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004746:	0001d997          	auipc	s3,0x1d
    8000474a:	0aa98993          	addi	s3,s3,170 # 800217f0 <log>
    8000474e:	a035                	j	8000477a <install_trans+0x60>
      bunpin(dbuf);
    80004750:	8526                	mv	a0,s1
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	166080e7          	jalr	358(ra) # 800038b8 <bunpin>
    brelse(lbuf);
    8000475a:	854a                	mv	a0,s2
    8000475c:	fffff097          	auipc	ra,0xfffff
    80004760:	082080e7          	jalr	130(ra) # 800037de <brelse>
    brelse(dbuf);
    80004764:	8526                	mv	a0,s1
    80004766:	fffff097          	auipc	ra,0xfffff
    8000476a:	078080e7          	jalr	120(ra) # 800037de <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000476e:	2a05                	addiw	s4,s4,1
    80004770:	0a91                	addi	s5,s5,4
    80004772:	02c9a783          	lw	a5,44(s3)
    80004776:	04fa5963          	bge	s4,a5,800047c8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000477a:	0189a583          	lw	a1,24(s3)
    8000477e:	014585bb          	addw	a1,a1,s4
    80004782:	2585                	addiw	a1,a1,1
    80004784:	0289a503          	lw	a0,40(s3)
    80004788:	fffff097          	auipc	ra,0xfffff
    8000478c:	f26080e7          	jalr	-218(ra) # 800036ae <bread>
    80004790:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004792:	000aa583          	lw	a1,0(s5)
    80004796:	0289a503          	lw	a0,40(s3)
    8000479a:	fffff097          	auipc	ra,0xfffff
    8000479e:	f14080e7          	jalr	-236(ra) # 800036ae <bread>
    800047a2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800047a4:	40000613          	li	a2,1024
    800047a8:	05890593          	addi	a1,s2,88
    800047ac:	05850513          	addi	a0,a0,88
    800047b0:	ffffc097          	auipc	ra,0xffffc
    800047b4:	590080e7          	jalr	1424(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800047b8:	8526                	mv	a0,s1
    800047ba:	fffff097          	auipc	ra,0xfffff
    800047be:	fe6080e7          	jalr	-26(ra) # 800037a0 <bwrite>
    if(recovering == 0)
    800047c2:	f80b1ce3          	bnez	s6,8000475a <install_trans+0x40>
    800047c6:	b769                	j	80004750 <install_trans+0x36>
}
    800047c8:	70e2                	ld	ra,56(sp)
    800047ca:	7442                	ld	s0,48(sp)
    800047cc:	74a2                	ld	s1,40(sp)
    800047ce:	7902                	ld	s2,32(sp)
    800047d0:	69e2                	ld	s3,24(sp)
    800047d2:	6a42                	ld	s4,16(sp)
    800047d4:	6aa2                	ld	s5,8(sp)
    800047d6:	6b02                	ld	s6,0(sp)
    800047d8:	6121                	addi	sp,sp,64
    800047da:	8082                	ret
    800047dc:	8082                	ret

00000000800047de <initlog>:
{
    800047de:	7179                	addi	sp,sp,-48
    800047e0:	f406                	sd	ra,40(sp)
    800047e2:	f022                	sd	s0,32(sp)
    800047e4:	ec26                	sd	s1,24(sp)
    800047e6:	e84a                	sd	s2,16(sp)
    800047e8:	e44e                	sd	s3,8(sp)
    800047ea:	1800                	addi	s0,sp,48
    800047ec:	892a                	mv	s2,a0
    800047ee:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800047f0:	0001d497          	auipc	s1,0x1d
    800047f4:	00048493          	mv	s1,s1
    800047f8:	00004597          	auipc	a1,0x4
    800047fc:	0b858593          	addi	a1,a1,184 # 800088b0 <syscalls+0x1f0>
    80004800:	8526                	mv	a0,s1
    80004802:	ffffc097          	auipc	ra,0xffffc
    80004806:	352080e7          	jalr	850(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000480a:	0149a583          	lw	a1,20(s3)
    8000480e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004810:	0109a783          	lw	a5,16(s3)
    80004814:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004816:	0324a423          	sw	s2,40(s1) # 80021818 <log+0x28>
  struct buf *buf = bread(log.dev, log.start);
    8000481a:	854a                	mv	a0,s2
    8000481c:	fffff097          	auipc	ra,0xfffff
    80004820:	e92080e7          	jalr	-366(ra) # 800036ae <bread>
  log.lh.n = lh->n;
    80004824:	4d3c                	lw	a5,88(a0)
    80004826:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004828:	02f05563          	blez	a5,80004852 <initlog+0x74>
    8000482c:	05c50713          	addi	a4,a0,92
    80004830:	0001d697          	auipc	a3,0x1d
    80004834:	ff068693          	addi	a3,a3,-16 # 80021820 <log+0x30>
    80004838:	37fd                	addiw	a5,a5,-1
    8000483a:	1782                	slli	a5,a5,0x20
    8000483c:	9381                	srli	a5,a5,0x20
    8000483e:	078a                	slli	a5,a5,0x2
    80004840:	06050613          	addi	a2,a0,96
    80004844:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004846:	4310                	lw	a2,0(a4)
    80004848:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000484a:	0711                	addi	a4,a4,4
    8000484c:	0691                	addi	a3,a3,4
    8000484e:	fef71ce3          	bne	a4,a5,80004846 <initlog+0x68>
  brelse(buf);
    80004852:	fffff097          	auipc	ra,0xfffff
    80004856:	f8c080e7          	jalr	-116(ra) # 800037de <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000485a:	4505                	li	a0,1
    8000485c:	00000097          	auipc	ra,0x0
    80004860:	ebe080e7          	jalr	-322(ra) # 8000471a <install_trans>
  log.lh.n = 0;
    80004864:	0001d797          	auipc	a5,0x1d
    80004868:	fa07ac23          	sw	zero,-72(a5) # 8002181c <log+0x2c>
  write_head(); // clear the log
    8000486c:	00000097          	auipc	ra,0x0
    80004870:	e34080e7          	jalr	-460(ra) # 800046a0 <write_head>
}
    80004874:	70a2                	ld	ra,40(sp)
    80004876:	7402                	ld	s0,32(sp)
    80004878:	64e2                	ld	s1,24(sp)
    8000487a:	6942                	ld	s2,16(sp)
    8000487c:	69a2                	ld	s3,8(sp)
    8000487e:	6145                	addi	sp,sp,48
    80004880:	8082                	ret

0000000080004882 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004882:	1101                	addi	sp,sp,-32
    80004884:	ec06                	sd	ra,24(sp)
    80004886:	e822                	sd	s0,16(sp)
    80004888:	e426                	sd	s1,8(sp)
    8000488a:	e04a                	sd	s2,0(sp)
    8000488c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000488e:	0001d517          	auipc	a0,0x1d
    80004892:	f6250513          	addi	a0,a0,-158 # 800217f0 <log>
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	34e080e7          	jalr	846(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000489e:	0001d497          	auipc	s1,0x1d
    800048a2:	f5248493          	addi	s1,s1,-174 # 800217f0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048a6:	4979                	li	s2,30
    800048a8:	a039                	j	800048b6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800048aa:	85a6                	mv	a1,s1
    800048ac:	8526                	mv	a0,s1
    800048ae:	ffffe097          	auipc	ra,0xffffe
    800048b2:	cac080e7          	jalr	-852(ra) # 8000255a <sleep>
    if(log.committing){
    800048b6:	50dc                	lw	a5,36(s1)
    800048b8:	fbed                	bnez	a5,800048aa <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048ba:	509c                	lw	a5,32(s1)
    800048bc:	0017871b          	addiw	a4,a5,1
    800048c0:	0007069b          	sext.w	a3,a4
    800048c4:	0027179b          	slliw	a5,a4,0x2
    800048c8:	9fb9                	addw	a5,a5,a4
    800048ca:	0017979b          	slliw	a5,a5,0x1
    800048ce:	54d8                	lw	a4,44(s1)
    800048d0:	9fb9                	addw	a5,a5,a4
    800048d2:	00f95963          	bge	s2,a5,800048e4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800048d6:	85a6                	mv	a1,s1
    800048d8:	8526                	mv	a0,s1
    800048da:	ffffe097          	auipc	ra,0xffffe
    800048de:	c80080e7          	jalr	-896(ra) # 8000255a <sleep>
    800048e2:	bfd1                	j	800048b6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800048e4:	0001d517          	auipc	a0,0x1d
    800048e8:	f0c50513          	addi	a0,a0,-244 # 800217f0 <log>
    800048ec:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800048ee:	ffffc097          	auipc	ra,0xffffc
    800048f2:	3aa080e7          	jalr	938(ra) # 80000c98 <release>
      break;
    }
  }
}
    800048f6:	60e2                	ld	ra,24(sp)
    800048f8:	6442                	ld	s0,16(sp)
    800048fa:	64a2                	ld	s1,8(sp)
    800048fc:	6902                	ld	s2,0(sp)
    800048fe:	6105                	addi	sp,sp,32
    80004900:	8082                	ret

0000000080004902 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004902:	7139                	addi	sp,sp,-64
    80004904:	fc06                	sd	ra,56(sp)
    80004906:	f822                	sd	s0,48(sp)
    80004908:	f426                	sd	s1,40(sp)
    8000490a:	f04a                	sd	s2,32(sp)
    8000490c:	ec4e                	sd	s3,24(sp)
    8000490e:	e852                	sd	s4,16(sp)
    80004910:	e456                	sd	s5,8(sp)
    80004912:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004914:	0001d497          	auipc	s1,0x1d
    80004918:	edc48493          	addi	s1,s1,-292 # 800217f0 <log>
    8000491c:	8526                	mv	a0,s1
    8000491e:	ffffc097          	auipc	ra,0xffffc
    80004922:	2c6080e7          	jalr	710(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004926:	509c                	lw	a5,32(s1)
    80004928:	37fd                	addiw	a5,a5,-1
    8000492a:	0007891b          	sext.w	s2,a5
    8000492e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004930:	50dc                	lw	a5,36(s1)
    80004932:	efb9                	bnez	a5,80004990 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004934:	06091663          	bnez	s2,800049a0 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004938:	0001d497          	auipc	s1,0x1d
    8000493c:	eb848493          	addi	s1,s1,-328 # 800217f0 <log>
    80004940:	4785                	li	a5,1
    80004942:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004944:	8526                	mv	a0,s1
    80004946:	ffffc097          	auipc	ra,0xffffc
    8000494a:	352080e7          	jalr	850(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000494e:	54dc                	lw	a5,44(s1)
    80004950:	06f04763          	bgtz	a5,800049be <end_op+0xbc>
    acquire(&log.lock);
    80004954:	0001d497          	auipc	s1,0x1d
    80004958:	e9c48493          	addi	s1,s1,-356 # 800217f0 <log>
    8000495c:	8526                	mv	a0,s1
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	286080e7          	jalr	646(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004966:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000496a:	8526                	mv	a0,s1
    8000496c:	ffffe097          	auipc	ra,0xffffe
    80004970:	204080e7          	jalr	516(ra) # 80002b70 <wakeup>
    release(&log.lock);
    80004974:	8526                	mv	a0,s1
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	322080e7          	jalr	802(ra) # 80000c98 <release>
}
    8000497e:	70e2                	ld	ra,56(sp)
    80004980:	7442                	ld	s0,48(sp)
    80004982:	74a2                	ld	s1,40(sp)
    80004984:	7902                	ld	s2,32(sp)
    80004986:	69e2                	ld	s3,24(sp)
    80004988:	6a42                	ld	s4,16(sp)
    8000498a:	6aa2                	ld	s5,8(sp)
    8000498c:	6121                	addi	sp,sp,64
    8000498e:	8082                	ret
    panic("log.committing");
    80004990:	00004517          	auipc	a0,0x4
    80004994:	f2850513          	addi	a0,a0,-216 # 800088b8 <syscalls+0x1f8>
    80004998:	ffffc097          	auipc	ra,0xffffc
    8000499c:	ba6080e7          	jalr	-1114(ra) # 8000053e <panic>
    wakeup(&log);
    800049a0:	0001d497          	auipc	s1,0x1d
    800049a4:	e5048493          	addi	s1,s1,-432 # 800217f0 <log>
    800049a8:	8526                	mv	a0,s1
    800049aa:	ffffe097          	auipc	ra,0xffffe
    800049ae:	1c6080e7          	jalr	454(ra) # 80002b70 <wakeup>
  release(&log.lock);
    800049b2:	8526                	mv	a0,s1
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	2e4080e7          	jalr	740(ra) # 80000c98 <release>
  if(do_commit){
    800049bc:	b7c9                	j	8000497e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049be:	0001da97          	auipc	s5,0x1d
    800049c2:	e62a8a93          	addi	s5,s5,-414 # 80021820 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800049c6:	0001da17          	auipc	s4,0x1d
    800049ca:	e2aa0a13          	addi	s4,s4,-470 # 800217f0 <log>
    800049ce:	018a2583          	lw	a1,24(s4)
    800049d2:	012585bb          	addw	a1,a1,s2
    800049d6:	2585                	addiw	a1,a1,1
    800049d8:	028a2503          	lw	a0,40(s4)
    800049dc:	fffff097          	auipc	ra,0xfffff
    800049e0:	cd2080e7          	jalr	-814(ra) # 800036ae <bread>
    800049e4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800049e6:	000aa583          	lw	a1,0(s5)
    800049ea:	028a2503          	lw	a0,40(s4)
    800049ee:	fffff097          	auipc	ra,0xfffff
    800049f2:	cc0080e7          	jalr	-832(ra) # 800036ae <bread>
    800049f6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800049f8:	40000613          	li	a2,1024
    800049fc:	05850593          	addi	a1,a0,88
    80004a00:	05848513          	addi	a0,s1,88
    80004a04:	ffffc097          	auipc	ra,0xffffc
    80004a08:	33c080e7          	jalr	828(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004a0c:	8526                	mv	a0,s1
    80004a0e:	fffff097          	auipc	ra,0xfffff
    80004a12:	d92080e7          	jalr	-622(ra) # 800037a0 <bwrite>
    brelse(from);
    80004a16:	854e                	mv	a0,s3
    80004a18:	fffff097          	auipc	ra,0xfffff
    80004a1c:	dc6080e7          	jalr	-570(ra) # 800037de <brelse>
    brelse(to);
    80004a20:	8526                	mv	a0,s1
    80004a22:	fffff097          	auipc	ra,0xfffff
    80004a26:	dbc080e7          	jalr	-580(ra) # 800037de <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a2a:	2905                	addiw	s2,s2,1
    80004a2c:	0a91                	addi	s5,s5,4
    80004a2e:	02ca2783          	lw	a5,44(s4)
    80004a32:	f8f94ee3          	blt	s2,a5,800049ce <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a36:	00000097          	auipc	ra,0x0
    80004a3a:	c6a080e7          	jalr	-918(ra) # 800046a0 <write_head>
    install_trans(0); // Now install writes to home locations
    80004a3e:	4501                	li	a0,0
    80004a40:	00000097          	auipc	ra,0x0
    80004a44:	cda080e7          	jalr	-806(ra) # 8000471a <install_trans>
    log.lh.n = 0;
    80004a48:	0001d797          	auipc	a5,0x1d
    80004a4c:	dc07aa23          	sw	zero,-556(a5) # 8002181c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004a50:	00000097          	auipc	ra,0x0
    80004a54:	c50080e7          	jalr	-944(ra) # 800046a0 <write_head>
    80004a58:	bdf5                	j	80004954 <end_op+0x52>

0000000080004a5a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004a5a:	1101                	addi	sp,sp,-32
    80004a5c:	ec06                	sd	ra,24(sp)
    80004a5e:	e822                	sd	s0,16(sp)
    80004a60:	e426                	sd	s1,8(sp)
    80004a62:	e04a                	sd	s2,0(sp)
    80004a64:	1000                	addi	s0,sp,32
    80004a66:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004a68:	0001d917          	auipc	s2,0x1d
    80004a6c:	d8890913          	addi	s2,s2,-632 # 800217f0 <log>
    80004a70:	854a                	mv	a0,s2
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	172080e7          	jalr	370(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004a7a:	02c92603          	lw	a2,44(s2)
    80004a7e:	47f5                	li	a5,29
    80004a80:	06c7c563          	blt	a5,a2,80004aea <log_write+0x90>
    80004a84:	0001d797          	auipc	a5,0x1d
    80004a88:	d887a783          	lw	a5,-632(a5) # 8002180c <log+0x1c>
    80004a8c:	37fd                	addiw	a5,a5,-1
    80004a8e:	04f65e63          	bge	a2,a5,80004aea <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004a92:	0001d797          	auipc	a5,0x1d
    80004a96:	d7e7a783          	lw	a5,-642(a5) # 80021810 <log+0x20>
    80004a9a:	06f05063          	blez	a5,80004afa <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004a9e:	4781                	li	a5,0
    80004aa0:	06c05563          	blez	a2,80004b0a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004aa4:	44cc                	lw	a1,12(s1)
    80004aa6:	0001d717          	auipc	a4,0x1d
    80004aaa:	d7a70713          	addi	a4,a4,-646 # 80021820 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004aae:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ab0:	4314                	lw	a3,0(a4)
    80004ab2:	04b68c63          	beq	a3,a1,80004b0a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004ab6:	2785                	addiw	a5,a5,1
    80004ab8:	0711                	addi	a4,a4,4
    80004aba:	fef61be3          	bne	a2,a5,80004ab0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004abe:	0621                	addi	a2,a2,8
    80004ac0:	060a                	slli	a2,a2,0x2
    80004ac2:	0001d797          	auipc	a5,0x1d
    80004ac6:	d2e78793          	addi	a5,a5,-722 # 800217f0 <log>
    80004aca:	963e                	add	a2,a2,a5
    80004acc:	44dc                	lw	a5,12(s1)
    80004ace:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004ad0:	8526                	mv	a0,s1
    80004ad2:	fffff097          	auipc	ra,0xfffff
    80004ad6:	daa080e7          	jalr	-598(ra) # 8000387c <bpin>
    log.lh.n++;
    80004ada:	0001d717          	auipc	a4,0x1d
    80004ade:	d1670713          	addi	a4,a4,-746 # 800217f0 <log>
    80004ae2:	575c                	lw	a5,44(a4)
    80004ae4:	2785                	addiw	a5,a5,1
    80004ae6:	d75c                	sw	a5,44(a4)
    80004ae8:	a835                	j	80004b24 <log_write+0xca>
    panic("too big a transaction");
    80004aea:	00004517          	auipc	a0,0x4
    80004aee:	dde50513          	addi	a0,a0,-546 # 800088c8 <syscalls+0x208>
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	a4c080e7          	jalr	-1460(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004afa:	00004517          	auipc	a0,0x4
    80004afe:	de650513          	addi	a0,a0,-538 # 800088e0 <syscalls+0x220>
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	a3c080e7          	jalr	-1476(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004b0a:	00878713          	addi	a4,a5,8
    80004b0e:	00271693          	slli	a3,a4,0x2
    80004b12:	0001d717          	auipc	a4,0x1d
    80004b16:	cde70713          	addi	a4,a4,-802 # 800217f0 <log>
    80004b1a:	9736                	add	a4,a4,a3
    80004b1c:	44d4                	lw	a3,12(s1)
    80004b1e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004b20:	faf608e3          	beq	a2,a5,80004ad0 <log_write+0x76>
  }
  release(&log.lock);
    80004b24:	0001d517          	auipc	a0,0x1d
    80004b28:	ccc50513          	addi	a0,a0,-820 # 800217f0 <log>
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	16c080e7          	jalr	364(ra) # 80000c98 <release>
}
    80004b34:	60e2                	ld	ra,24(sp)
    80004b36:	6442                	ld	s0,16(sp)
    80004b38:	64a2                	ld	s1,8(sp)
    80004b3a:	6902                	ld	s2,0(sp)
    80004b3c:	6105                	addi	sp,sp,32
    80004b3e:	8082                	ret

0000000080004b40 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004b40:	1101                	addi	sp,sp,-32
    80004b42:	ec06                	sd	ra,24(sp)
    80004b44:	e822                	sd	s0,16(sp)
    80004b46:	e426                	sd	s1,8(sp)
    80004b48:	e04a                	sd	s2,0(sp)
    80004b4a:	1000                	addi	s0,sp,32
    80004b4c:	84aa                	mv	s1,a0
    80004b4e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004b50:	00004597          	auipc	a1,0x4
    80004b54:	db058593          	addi	a1,a1,-592 # 80008900 <syscalls+0x240>
    80004b58:	0521                	addi	a0,a0,8
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	ffa080e7          	jalr	-6(ra) # 80000b54 <initlock>
  lk->name = name;
    80004b62:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004b66:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b6a:	0204a423          	sw	zero,40(s1)
}
    80004b6e:	60e2                	ld	ra,24(sp)
    80004b70:	6442                	ld	s0,16(sp)
    80004b72:	64a2                	ld	s1,8(sp)
    80004b74:	6902                	ld	s2,0(sp)
    80004b76:	6105                	addi	sp,sp,32
    80004b78:	8082                	ret

0000000080004b7a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004b7a:	1101                	addi	sp,sp,-32
    80004b7c:	ec06                	sd	ra,24(sp)
    80004b7e:	e822                	sd	s0,16(sp)
    80004b80:	e426                	sd	s1,8(sp)
    80004b82:	e04a                	sd	s2,0(sp)
    80004b84:	1000                	addi	s0,sp,32
    80004b86:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b88:	00850913          	addi	s2,a0,8
    80004b8c:	854a                	mv	a0,s2
    80004b8e:	ffffc097          	auipc	ra,0xffffc
    80004b92:	056080e7          	jalr	86(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004b96:	409c                	lw	a5,0(s1)
    80004b98:	cb89                	beqz	a5,80004baa <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004b9a:	85ca                	mv	a1,s2
    80004b9c:	8526                	mv	a0,s1
    80004b9e:	ffffe097          	auipc	ra,0xffffe
    80004ba2:	9bc080e7          	jalr	-1604(ra) # 8000255a <sleep>
  while (lk->locked) {
    80004ba6:	409c                	lw	a5,0(s1)
    80004ba8:	fbed                	bnez	a5,80004b9a <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004baa:	4785                	li	a5,1
    80004bac:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004bae:	ffffd097          	auipc	ra,0xffffd
    80004bb2:	25e080e7          	jalr	606(ra) # 80001e0c <myproc>
    80004bb6:	591c                	lw	a5,48(a0)
    80004bb8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004bba:	854a                	mv	a0,s2
    80004bbc:	ffffc097          	auipc	ra,0xffffc
    80004bc0:	0dc080e7          	jalr	220(ra) # 80000c98 <release>
}
    80004bc4:	60e2                	ld	ra,24(sp)
    80004bc6:	6442                	ld	s0,16(sp)
    80004bc8:	64a2                	ld	s1,8(sp)
    80004bca:	6902                	ld	s2,0(sp)
    80004bcc:	6105                	addi	sp,sp,32
    80004bce:	8082                	ret

0000000080004bd0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004bd0:	1101                	addi	sp,sp,-32
    80004bd2:	ec06                	sd	ra,24(sp)
    80004bd4:	e822                	sd	s0,16(sp)
    80004bd6:	e426                	sd	s1,8(sp)
    80004bd8:	e04a                	sd	s2,0(sp)
    80004bda:	1000                	addi	s0,sp,32
    80004bdc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bde:	00850913          	addi	s2,a0,8
    80004be2:	854a                	mv	a0,s2
    80004be4:	ffffc097          	auipc	ra,0xffffc
    80004be8:	000080e7          	jalr	ra # 80000be4 <acquire>
  lk->locked = 0;
    80004bec:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004bf0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004bf4:	8526                	mv	a0,s1
    80004bf6:	ffffe097          	auipc	ra,0xffffe
    80004bfa:	f7a080e7          	jalr	-134(ra) # 80002b70 <wakeup>
  release(&lk->lk);
    80004bfe:	854a                	mv	a0,s2
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	098080e7          	jalr	152(ra) # 80000c98 <release>
}
    80004c08:	60e2                	ld	ra,24(sp)
    80004c0a:	6442                	ld	s0,16(sp)
    80004c0c:	64a2                	ld	s1,8(sp)
    80004c0e:	6902                	ld	s2,0(sp)
    80004c10:	6105                	addi	sp,sp,32
    80004c12:	8082                	ret

0000000080004c14 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004c14:	7179                	addi	sp,sp,-48
    80004c16:	f406                	sd	ra,40(sp)
    80004c18:	f022                	sd	s0,32(sp)
    80004c1a:	ec26                	sd	s1,24(sp)
    80004c1c:	e84a                	sd	s2,16(sp)
    80004c1e:	e44e                	sd	s3,8(sp)
    80004c20:	1800                	addi	s0,sp,48
    80004c22:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004c24:	00850913          	addi	s2,a0,8
    80004c28:	854a                	mv	a0,s2
    80004c2a:	ffffc097          	auipc	ra,0xffffc
    80004c2e:	fba080e7          	jalr	-70(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c32:	409c                	lw	a5,0(s1)
    80004c34:	ef99                	bnez	a5,80004c52 <holdingsleep+0x3e>
    80004c36:	4481                	li	s1,0
  release(&lk->lk);
    80004c38:	854a                	mv	a0,s2
    80004c3a:	ffffc097          	auipc	ra,0xffffc
    80004c3e:	05e080e7          	jalr	94(ra) # 80000c98 <release>
  return r;
}
    80004c42:	8526                	mv	a0,s1
    80004c44:	70a2                	ld	ra,40(sp)
    80004c46:	7402                	ld	s0,32(sp)
    80004c48:	64e2                	ld	s1,24(sp)
    80004c4a:	6942                	ld	s2,16(sp)
    80004c4c:	69a2                	ld	s3,8(sp)
    80004c4e:	6145                	addi	sp,sp,48
    80004c50:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c52:	0284a983          	lw	s3,40(s1)
    80004c56:	ffffd097          	auipc	ra,0xffffd
    80004c5a:	1b6080e7          	jalr	438(ra) # 80001e0c <myproc>
    80004c5e:	5904                	lw	s1,48(a0)
    80004c60:	413484b3          	sub	s1,s1,s3
    80004c64:	0014b493          	seqz	s1,s1
    80004c68:	bfc1                	j	80004c38 <holdingsleep+0x24>

0000000080004c6a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004c6a:	1141                	addi	sp,sp,-16
    80004c6c:	e406                	sd	ra,8(sp)
    80004c6e:	e022                	sd	s0,0(sp)
    80004c70:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004c72:	00004597          	auipc	a1,0x4
    80004c76:	c9e58593          	addi	a1,a1,-866 # 80008910 <syscalls+0x250>
    80004c7a:	0001d517          	auipc	a0,0x1d
    80004c7e:	cbe50513          	addi	a0,a0,-834 # 80021938 <ftable>
    80004c82:	ffffc097          	auipc	ra,0xffffc
    80004c86:	ed2080e7          	jalr	-302(ra) # 80000b54 <initlock>
}
    80004c8a:	60a2                	ld	ra,8(sp)
    80004c8c:	6402                	ld	s0,0(sp)
    80004c8e:	0141                	addi	sp,sp,16
    80004c90:	8082                	ret

0000000080004c92 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004c92:	1101                	addi	sp,sp,-32
    80004c94:	ec06                	sd	ra,24(sp)
    80004c96:	e822                	sd	s0,16(sp)
    80004c98:	e426                	sd	s1,8(sp)
    80004c9a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004c9c:	0001d517          	auipc	a0,0x1d
    80004ca0:	c9c50513          	addi	a0,a0,-868 # 80021938 <ftable>
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	f40080e7          	jalr	-192(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cac:	0001d497          	auipc	s1,0x1d
    80004cb0:	ca448493          	addi	s1,s1,-860 # 80021950 <ftable+0x18>
    80004cb4:	0001e717          	auipc	a4,0x1e
    80004cb8:	c3c70713          	addi	a4,a4,-964 # 800228f0 <ftable+0xfb8>
    if(f->ref == 0){
    80004cbc:	40dc                	lw	a5,4(s1)
    80004cbe:	cf99                	beqz	a5,80004cdc <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cc0:	02848493          	addi	s1,s1,40
    80004cc4:	fee49ce3          	bne	s1,a4,80004cbc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004cc8:	0001d517          	auipc	a0,0x1d
    80004ccc:	c7050513          	addi	a0,a0,-912 # 80021938 <ftable>
    80004cd0:	ffffc097          	auipc	ra,0xffffc
    80004cd4:	fc8080e7          	jalr	-56(ra) # 80000c98 <release>
  return 0;
    80004cd8:	4481                	li	s1,0
    80004cda:	a819                	j	80004cf0 <filealloc+0x5e>
      f->ref = 1;
    80004cdc:	4785                	li	a5,1
    80004cde:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004ce0:	0001d517          	auipc	a0,0x1d
    80004ce4:	c5850513          	addi	a0,a0,-936 # 80021938 <ftable>
    80004ce8:	ffffc097          	auipc	ra,0xffffc
    80004cec:	fb0080e7          	jalr	-80(ra) # 80000c98 <release>
}
    80004cf0:	8526                	mv	a0,s1
    80004cf2:	60e2                	ld	ra,24(sp)
    80004cf4:	6442                	ld	s0,16(sp)
    80004cf6:	64a2                	ld	s1,8(sp)
    80004cf8:	6105                	addi	sp,sp,32
    80004cfa:	8082                	ret

0000000080004cfc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004cfc:	1101                	addi	sp,sp,-32
    80004cfe:	ec06                	sd	ra,24(sp)
    80004d00:	e822                	sd	s0,16(sp)
    80004d02:	e426                	sd	s1,8(sp)
    80004d04:	1000                	addi	s0,sp,32
    80004d06:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004d08:	0001d517          	auipc	a0,0x1d
    80004d0c:	c3050513          	addi	a0,a0,-976 # 80021938 <ftable>
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	ed4080e7          	jalr	-300(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004d18:	40dc                	lw	a5,4(s1)
    80004d1a:	02f05263          	blez	a5,80004d3e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004d1e:	2785                	addiw	a5,a5,1
    80004d20:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004d22:	0001d517          	auipc	a0,0x1d
    80004d26:	c1650513          	addi	a0,a0,-1002 # 80021938 <ftable>
    80004d2a:	ffffc097          	auipc	ra,0xffffc
    80004d2e:	f6e080e7          	jalr	-146(ra) # 80000c98 <release>
  return f;
}
    80004d32:	8526                	mv	a0,s1
    80004d34:	60e2                	ld	ra,24(sp)
    80004d36:	6442                	ld	s0,16(sp)
    80004d38:	64a2                	ld	s1,8(sp)
    80004d3a:	6105                	addi	sp,sp,32
    80004d3c:	8082                	ret
    panic("filedup");
    80004d3e:	00004517          	auipc	a0,0x4
    80004d42:	bda50513          	addi	a0,a0,-1062 # 80008918 <syscalls+0x258>
    80004d46:	ffffb097          	auipc	ra,0xffffb
    80004d4a:	7f8080e7          	jalr	2040(ra) # 8000053e <panic>

0000000080004d4e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004d4e:	7139                	addi	sp,sp,-64
    80004d50:	fc06                	sd	ra,56(sp)
    80004d52:	f822                	sd	s0,48(sp)
    80004d54:	f426                	sd	s1,40(sp)
    80004d56:	f04a                	sd	s2,32(sp)
    80004d58:	ec4e                	sd	s3,24(sp)
    80004d5a:	e852                	sd	s4,16(sp)
    80004d5c:	e456                	sd	s5,8(sp)
    80004d5e:	0080                	addi	s0,sp,64
    80004d60:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d62:	0001d517          	auipc	a0,0x1d
    80004d66:	bd650513          	addi	a0,a0,-1066 # 80021938 <ftable>
    80004d6a:	ffffc097          	auipc	ra,0xffffc
    80004d6e:	e7a080e7          	jalr	-390(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004d72:	40dc                	lw	a5,4(s1)
    80004d74:	06f05163          	blez	a5,80004dd6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004d78:	37fd                	addiw	a5,a5,-1
    80004d7a:	0007871b          	sext.w	a4,a5
    80004d7e:	c0dc                	sw	a5,4(s1)
    80004d80:	06e04363          	bgtz	a4,80004de6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004d84:	0004a903          	lw	s2,0(s1)
    80004d88:	0094ca83          	lbu	s5,9(s1)
    80004d8c:	0104ba03          	ld	s4,16(s1)
    80004d90:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004d94:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004d98:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004d9c:	0001d517          	auipc	a0,0x1d
    80004da0:	b9c50513          	addi	a0,a0,-1124 # 80021938 <ftable>
    80004da4:	ffffc097          	auipc	ra,0xffffc
    80004da8:	ef4080e7          	jalr	-268(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004dac:	4785                	li	a5,1
    80004dae:	04f90d63          	beq	s2,a5,80004e08 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004db2:	3979                	addiw	s2,s2,-2
    80004db4:	4785                	li	a5,1
    80004db6:	0527e063          	bltu	a5,s2,80004df6 <fileclose+0xa8>
    begin_op();
    80004dba:	00000097          	auipc	ra,0x0
    80004dbe:	ac8080e7          	jalr	-1336(ra) # 80004882 <begin_op>
    iput(ff.ip);
    80004dc2:	854e                	mv	a0,s3
    80004dc4:	fffff097          	auipc	ra,0xfffff
    80004dc8:	2a6080e7          	jalr	678(ra) # 8000406a <iput>
    end_op();
    80004dcc:	00000097          	auipc	ra,0x0
    80004dd0:	b36080e7          	jalr	-1226(ra) # 80004902 <end_op>
    80004dd4:	a00d                	j	80004df6 <fileclose+0xa8>
    panic("fileclose");
    80004dd6:	00004517          	auipc	a0,0x4
    80004dda:	b4a50513          	addi	a0,a0,-1206 # 80008920 <syscalls+0x260>
    80004dde:	ffffb097          	auipc	ra,0xffffb
    80004de2:	760080e7          	jalr	1888(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004de6:	0001d517          	auipc	a0,0x1d
    80004dea:	b5250513          	addi	a0,a0,-1198 # 80021938 <ftable>
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	eaa080e7          	jalr	-342(ra) # 80000c98 <release>
  }
}
    80004df6:	70e2                	ld	ra,56(sp)
    80004df8:	7442                	ld	s0,48(sp)
    80004dfa:	74a2                	ld	s1,40(sp)
    80004dfc:	7902                	ld	s2,32(sp)
    80004dfe:	69e2                	ld	s3,24(sp)
    80004e00:	6a42                	ld	s4,16(sp)
    80004e02:	6aa2                	ld	s5,8(sp)
    80004e04:	6121                	addi	sp,sp,64
    80004e06:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004e08:	85d6                	mv	a1,s5
    80004e0a:	8552                	mv	a0,s4
    80004e0c:	00000097          	auipc	ra,0x0
    80004e10:	34c080e7          	jalr	844(ra) # 80005158 <pipeclose>
    80004e14:	b7cd                	j	80004df6 <fileclose+0xa8>

0000000080004e16 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004e16:	715d                	addi	sp,sp,-80
    80004e18:	e486                	sd	ra,72(sp)
    80004e1a:	e0a2                	sd	s0,64(sp)
    80004e1c:	fc26                	sd	s1,56(sp)
    80004e1e:	f84a                	sd	s2,48(sp)
    80004e20:	f44e                	sd	s3,40(sp)
    80004e22:	0880                	addi	s0,sp,80
    80004e24:	84aa                	mv	s1,a0
    80004e26:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004e28:	ffffd097          	auipc	ra,0xffffd
    80004e2c:	fe4080e7          	jalr	-28(ra) # 80001e0c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e30:	409c                	lw	a5,0(s1)
    80004e32:	37f9                	addiw	a5,a5,-2
    80004e34:	4705                	li	a4,1
    80004e36:	04f76763          	bltu	a4,a5,80004e84 <filestat+0x6e>
    80004e3a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004e3c:	6c88                	ld	a0,24(s1)
    80004e3e:	fffff097          	auipc	ra,0xfffff
    80004e42:	072080e7          	jalr	114(ra) # 80003eb0 <ilock>
    stati(f->ip, &st);
    80004e46:	fb840593          	addi	a1,s0,-72
    80004e4a:	6c88                	ld	a0,24(s1)
    80004e4c:	fffff097          	auipc	ra,0xfffff
    80004e50:	2ee080e7          	jalr	750(ra) # 8000413a <stati>
    iunlock(f->ip);
    80004e54:	6c88                	ld	a0,24(s1)
    80004e56:	fffff097          	auipc	ra,0xfffff
    80004e5a:	11c080e7          	jalr	284(ra) # 80003f72 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004e5e:	46e1                	li	a3,24
    80004e60:	fb840613          	addi	a2,s0,-72
    80004e64:	85ce                	mv	a1,s3
    80004e66:	05093503          	ld	a0,80(s2)
    80004e6a:	ffffd097          	auipc	ra,0xffffd
    80004e6e:	808080e7          	jalr	-2040(ra) # 80001672 <copyout>
    80004e72:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004e76:	60a6                	ld	ra,72(sp)
    80004e78:	6406                	ld	s0,64(sp)
    80004e7a:	74e2                	ld	s1,56(sp)
    80004e7c:	7942                	ld	s2,48(sp)
    80004e7e:	79a2                	ld	s3,40(sp)
    80004e80:	6161                	addi	sp,sp,80
    80004e82:	8082                	ret
  return -1;
    80004e84:	557d                	li	a0,-1
    80004e86:	bfc5                	j	80004e76 <filestat+0x60>

0000000080004e88 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004e88:	7179                	addi	sp,sp,-48
    80004e8a:	f406                	sd	ra,40(sp)
    80004e8c:	f022                	sd	s0,32(sp)
    80004e8e:	ec26                	sd	s1,24(sp)
    80004e90:	e84a                	sd	s2,16(sp)
    80004e92:	e44e                	sd	s3,8(sp)
    80004e94:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004e96:	00854783          	lbu	a5,8(a0)
    80004e9a:	c3d5                	beqz	a5,80004f3e <fileread+0xb6>
    80004e9c:	84aa                	mv	s1,a0
    80004e9e:	89ae                	mv	s3,a1
    80004ea0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ea2:	411c                	lw	a5,0(a0)
    80004ea4:	4705                	li	a4,1
    80004ea6:	04e78963          	beq	a5,a4,80004ef8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004eaa:	470d                	li	a4,3
    80004eac:	04e78d63          	beq	a5,a4,80004f06 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004eb0:	4709                	li	a4,2
    80004eb2:	06e79e63          	bne	a5,a4,80004f2e <fileread+0xa6>
    ilock(f->ip);
    80004eb6:	6d08                	ld	a0,24(a0)
    80004eb8:	fffff097          	auipc	ra,0xfffff
    80004ebc:	ff8080e7          	jalr	-8(ra) # 80003eb0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ec0:	874a                	mv	a4,s2
    80004ec2:	5094                	lw	a3,32(s1)
    80004ec4:	864e                	mv	a2,s3
    80004ec6:	4585                	li	a1,1
    80004ec8:	6c88                	ld	a0,24(s1)
    80004eca:	fffff097          	auipc	ra,0xfffff
    80004ece:	29a080e7          	jalr	666(ra) # 80004164 <readi>
    80004ed2:	892a                	mv	s2,a0
    80004ed4:	00a05563          	blez	a0,80004ede <fileread+0x56>
      f->off += r;
    80004ed8:	509c                	lw	a5,32(s1)
    80004eda:	9fa9                	addw	a5,a5,a0
    80004edc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ede:	6c88                	ld	a0,24(s1)
    80004ee0:	fffff097          	auipc	ra,0xfffff
    80004ee4:	092080e7          	jalr	146(ra) # 80003f72 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ee8:	854a                	mv	a0,s2
    80004eea:	70a2                	ld	ra,40(sp)
    80004eec:	7402                	ld	s0,32(sp)
    80004eee:	64e2                	ld	s1,24(sp)
    80004ef0:	6942                	ld	s2,16(sp)
    80004ef2:	69a2                	ld	s3,8(sp)
    80004ef4:	6145                	addi	sp,sp,48
    80004ef6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004ef8:	6908                	ld	a0,16(a0)
    80004efa:	00000097          	auipc	ra,0x0
    80004efe:	3c8080e7          	jalr	968(ra) # 800052c2 <piperead>
    80004f02:	892a                	mv	s2,a0
    80004f04:	b7d5                	j	80004ee8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f06:	02451783          	lh	a5,36(a0)
    80004f0a:	03079693          	slli	a3,a5,0x30
    80004f0e:	92c1                	srli	a3,a3,0x30
    80004f10:	4725                	li	a4,9
    80004f12:	02d76863          	bltu	a4,a3,80004f42 <fileread+0xba>
    80004f16:	0792                	slli	a5,a5,0x4
    80004f18:	0001d717          	auipc	a4,0x1d
    80004f1c:	98070713          	addi	a4,a4,-1664 # 80021898 <devsw>
    80004f20:	97ba                	add	a5,a5,a4
    80004f22:	639c                	ld	a5,0(a5)
    80004f24:	c38d                	beqz	a5,80004f46 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004f26:	4505                	li	a0,1
    80004f28:	9782                	jalr	a5
    80004f2a:	892a                	mv	s2,a0
    80004f2c:	bf75                	j	80004ee8 <fileread+0x60>
    panic("fileread");
    80004f2e:	00004517          	auipc	a0,0x4
    80004f32:	a0250513          	addi	a0,a0,-1534 # 80008930 <syscalls+0x270>
    80004f36:	ffffb097          	auipc	ra,0xffffb
    80004f3a:	608080e7          	jalr	1544(ra) # 8000053e <panic>
    return -1;
    80004f3e:	597d                	li	s2,-1
    80004f40:	b765                	j	80004ee8 <fileread+0x60>
      return -1;
    80004f42:	597d                	li	s2,-1
    80004f44:	b755                	j	80004ee8 <fileread+0x60>
    80004f46:	597d                	li	s2,-1
    80004f48:	b745                	j	80004ee8 <fileread+0x60>

0000000080004f4a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004f4a:	715d                	addi	sp,sp,-80
    80004f4c:	e486                	sd	ra,72(sp)
    80004f4e:	e0a2                	sd	s0,64(sp)
    80004f50:	fc26                	sd	s1,56(sp)
    80004f52:	f84a                	sd	s2,48(sp)
    80004f54:	f44e                	sd	s3,40(sp)
    80004f56:	f052                	sd	s4,32(sp)
    80004f58:	ec56                	sd	s5,24(sp)
    80004f5a:	e85a                	sd	s6,16(sp)
    80004f5c:	e45e                	sd	s7,8(sp)
    80004f5e:	e062                	sd	s8,0(sp)
    80004f60:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004f62:	00954783          	lbu	a5,9(a0)
    80004f66:	10078663          	beqz	a5,80005072 <filewrite+0x128>
    80004f6a:	892a                	mv	s2,a0
    80004f6c:	8aae                	mv	s5,a1
    80004f6e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f70:	411c                	lw	a5,0(a0)
    80004f72:	4705                	li	a4,1
    80004f74:	02e78263          	beq	a5,a4,80004f98 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f78:	470d                	li	a4,3
    80004f7a:	02e78663          	beq	a5,a4,80004fa6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f7e:	4709                	li	a4,2
    80004f80:	0ee79163          	bne	a5,a4,80005062 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f84:	0ac05d63          	blez	a2,8000503e <filewrite+0xf4>
    int i = 0;
    80004f88:	4981                	li	s3,0
    80004f8a:	6b05                	lui	s6,0x1
    80004f8c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004f90:	6b85                	lui	s7,0x1
    80004f92:	c00b8b9b          	addiw	s7,s7,-1024
    80004f96:	a861                	j	8000502e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004f98:	6908                	ld	a0,16(a0)
    80004f9a:	00000097          	auipc	ra,0x0
    80004f9e:	22e080e7          	jalr	558(ra) # 800051c8 <pipewrite>
    80004fa2:	8a2a                	mv	s4,a0
    80004fa4:	a045                	j	80005044 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004fa6:	02451783          	lh	a5,36(a0)
    80004faa:	03079693          	slli	a3,a5,0x30
    80004fae:	92c1                	srli	a3,a3,0x30
    80004fb0:	4725                	li	a4,9
    80004fb2:	0cd76263          	bltu	a4,a3,80005076 <filewrite+0x12c>
    80004fb6:	0792                	slli	a5,a5,0x4
    80004fb8:	0001d717          	auipc	a4,0x1d
    80004fbc:	8e070713          	addi	a4,a4,-1824 # 80021898 <devsw>
    80004fc0:	97ba                	add	a5,a5,a4
    80004fc2:	679c                	ld	a5,8(a5)
    80004fc4:	cbdd                	beqz	a5,8000507a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004fc6:	4505                	li	a0,1
    80004fc8:	9782                	jalr	a5
    80004fca:	8a2a                	mv	s4,a0
    80004fcc:	a8a5                	j	80005044 <filewrite+0xfa>
    80004fce:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004fd2:	00000097          	auipc	ra,0x0
    80004fd6:	8b0080e7          	jalr	-1872(ra) # 80004882 <begin_op>
      ilock(f->ip);
    80004fda:	01893503          	ld	a0,24(s2)
    80004fde:	fffff097          	auipc	ra,0xfffff
    80004fe2:	ed2080e7          	jalr	-302(ra) # 80003eb0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004fe6:	8762                	mv	a4,s8
    80004fe8:	02092683          	lw	a3,32(s2)
    80004fec:	01598633          	add	a2,s3,s5
    80004ff0:	4585                	li	a1,1
    80004ff2:	01893503          	ld	a0,24(s2)
    80004ff6:	fffff097          	auipc	ra,0xfffff
    80004ffa:	266080e7          	jalr	614(ra) # 8000425c <writei>
    80004ffe:	84aa                	mv	s1,a0
    80005000:	00a05763          	blez	a0,8000500e <filewrite+0xc4>
        f->off += r;
    80005004:	02092783          	lw	a5,32(s2)
    80005008:	9fa9                	addw	a5,a5,a0
    8000500a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000500e:	01893503          	ld	a0,24(s2)
    80005012:	fffff097          	auipc	ra,0xfffff
    80005016:	f60080e7          	jalr	-160(ra) # 80003f72 <iunlock>
      end_op();
    8000501a:	00000097          	auipc	ra,0x0
    8000501e:	8e8080e7          	jalr	-1816(ra) # 80004902 <end_op>

      if(r != n1){
    80005022:	009c1f63          	bne	s8,s1,80005040 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005026:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000502a:	0149db63          	bge	s3,s4,80005040 <filewrite+0xf6>
      int n1 = n - i;
    8000502e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005032:	84be                	mv	s1,a5
    80005034:	2781                	sext.w	a5,a5
    80005036:	f8fb5ce3          	bge	s6,a5,80004fce <filewrite+0x84>
    8000503a:	84de                	mv	s1,s7
    8000503c:	bf49                	j	80004fce <filewrite+0x84>
    int i = 0;
    8000503e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005040:	013a1f63          	bne	s4,s3,8000505e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005044:	8552                	mv	a0,s4
    80005046:	60a6                	ld	ra,72(sp)
    80005048:	6406                	ld	s0,64(sp)
    8000504a:	74e2                	ld	s1,56(sp)
    8000504c:	7942                	ld	s2,48(sp)
    8000504e:	79a2                	ld	s3,40(sp)
    80005050:	7a02                	ld	s4,32(sp)
    80005052:	6ae2                	ld	s5,24(sp)
    80005054:	6b42                	ld	s6,16(sp)
    80005056:	6ba2                	ld	s7,8(sp)
    80005058:	6c02                	ld	s8,0(sp)
    8000505a:	6161                	addi	sp,sp,80
    8000505c:	8082                	ret
    ret = (i == n ? n : -1);
    8000505e:	5a7d                	li	s4,-1
    80005060:	b7d5                	j	80005044 <filewrite+0xfa>
    panic("filewrite");
    80005062:	00004517          	auipc	a0,0x4
    80005066:	8de50513          	addi	a0,a0,-1826 # 80008940 <syscalls+0x280>
    8000506a:	ffffb097          	auipc	ra,0xffffb
    8000506e:	4d4080e7          	jalr	1236(ra) # 8000053e <panic>
    return -1;
    80005072:	5a7d                	li	s4,-1
    80005074:	bfc1                	j	80005044 <filewrite+0xfa>
      return -1;
    80005076:	5a7d                	li	s4,-1
    80005078:	b7f1                	j	80005044 <filewrite+0xfa>
    8000507a:	5a7d                	li	s4,-1
    8000507c:	b7e1                	j	80005044 <filewrite+0xfa>

000000008000507e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000507e:	7179                	addi	sp,sp,-48
    80005080:	f406                	sd	ra,40(sp)
    80005082:	f022                	sd	s0,32(sp)
    80005084:	ec26                	sd	s1,24(sp)
    80005086:	e84a                	sd	s2,16(sp)
    80005088:	e44e                	sd	s3,8(sp)
    8000508a:	e052                	sd	s4,0(sp)
    8000508c:	1800                	addi	s0,sp,48
    8000508e:	84aa                	mv	s1,a0
    80005090:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005092:	0005b023          	sd	zero,0(a1)
    80005096:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000509a:	00000097          	auipc	ra,0x0
    8000509e:	bf8080e7          	jalr	-1032(ra) # 80004c92 <filealloc>
    800050a2:	e088                	sd	a0,0(s1)
    800050a4:	c551                	beqz	a0,80005130 <pipealloc+0xb2>
    800050a6:	00000097          	auipc	ra,0x0
    800050aa:	bec080e7          	jalr	-1044(ra) # 80004c92 <filealloc>
    800050ae:	00aa3023          	sd	a0,0(s4)
    800050b2:	c92d                	beqz	a0,80005124 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800050b4:	ffffc097          	auipc	ra,0xffffc
    800050b8:	a40080e7          	jalr	-1472(ra) # 80000af4 <kalloc>
    800050bc:	892a                	mv	s2,a0
    800050be:	c125                	beqz	a0,8000511e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800050c0:	4985                	li	s3,1
    800050c2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800050c6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800050ca:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800050ce:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800050d2:	00004597          	auipc	a1,0x4
    800050d6:	87e58593          	addi	a1,a1,-1922 # 80008950 <syscalls+0x290>
    800050da:	ffffc097          	auipc	ra,0xffffc
    800050de:	a7a080e7          	jalr	-1414(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800050e2:	609c                	ld	a5,0(s1)
    800050e4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800050e8:	609c                	ld	a5,0(s1)
    800050ea:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800050ee:	609c                	ld	a5,0(s1)
    800050f0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800050f4:	609c                	ld	a5,0(s1)
    800050f6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800050fa:	000a3783          	ld	a5,0(s4)
    800050fe:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005102:	000a3783          	ld	a5,0(s4)
    80005106:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000510a:	000a3783          	ld	a5,0(s4)
    8000510e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005112:	000a3783          	ld	a5,0(s4)
    80005116:	0127b823          	sd	s2,16(a5)
  return 0;
    8000511a:	4501                	li	a0,0
    8000511c:	a025                	j	80005144 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000511e:	6088                	ld	a0,0(s1)
    80005120:	e501                	bnez	a0,80005128 <pipealloc+0xaa>
    80005122:	a039                	j	80005130 <pipealloc+0xb2>
    80005124:	6088                	ld	a0,0(s1)
    80005126:	c51d                	beqz	a0,80005154 <pipealloc+0xd6>
    fileclose(*f0);
    80005128:	00000097          	auipc	ra,0x0
    8000512c:	c26080e7          	jalr	-986(ra) # 80004d4e <fileclose>
  if(*f1)
    80005130:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005134:	557d                	li	a0,-1
  if(*f1)
    80005136:	c799                	beqz	a5,80005144 <pipealloc+0xc6>
    fileclose(*f1);
    80005138:	853e                	mv	a0,a5
    8000513a:	00000097          	auipc	ra,0x0
    8000513e:	c14080e7          	jalr	-1004(ra) # 80004d4e <fileclose>
  return -1;
    80005142:	557d                	li	a0,-1
}
    80005144:	70a2                	ld	ra,40(sp)
    80005146:	7402                	ld	s0,32(sp)
    80005148:	64e2                	ld	s1,24(sp)
    8000514a:	6942                	ld	s2,16(sp)
    8000514c:	69a2                	ld	s3,8(sp)
    8000514e:	6a02                	ld	s4,0(sp)
    80005150:	6145                	addi	sp,sp,48
    80005152:	8082                	ret
  return -1;
    80005154:	557d                	li	a0,-1
    80005156:	b7fd                	j	80005144 <pipealloc+0xc6>

0000000080005158 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005158:	1101                	addi	sp,sp,-32
    8000515a:	ec06                	sd	ra,24(sp)
    8000515c:	e822                	sd	s0,16(sp)
    8000515e:	e426                	sd	s1,8(sp)
    80005160:	e04a                	sd	s2,0(sp)
    80005162:	1000                	addi	s0,sp,32
    80005164:	84aa                	mv	s1,a0
    80005166:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005168:	ffffc097          	auipc	ra,0xffffc
    8000516c:	a7c080e7          	jalr	-1412(ra) # 80000be4 <acquire>
  if(writable){
    80005170:	02090d63          	beqz	s2,800051aa <pipeclose+0x52>
    pi->writeopen = 0;
    80005174:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005178:	21848513          	addi	a0,s1,536
    8000517c:	ffffe097          	auipc	ra,0xffffe
    80005180:	9f4080e7          	jalr	-1548(ra) # 80002b70 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005184:	2204b783          	ld	a5,544(s1)
    80005188:	eb95                	bnez	a5,800051bc <pipeclose+0x64>
    release(&pi->lock);
    8000518a:	8526                	mv	a0,s1
    8000518c:	ffffc097          	auipc	ra,0xffffc
    80005190:	b0c080e7          	jalr	-1268(ra) # 80000c98 <release>
    kfree((char*)pi);
    80005194:	8526                	mv	a0,s1
    80005196:	ffffc097          	auipc	ra,0xffffc
    8000519a:	862080e7          	jalr	-1950(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    8000519e:	60e2                	ld	ra,24(sp)
    800051a0:	6442                	ld	s0,16(sp)
    800051a2:	64a2                	ld	s1,8(sp)
    800051a4:	6902                	ld	s2,0(sp)
    800051a6:	6105                	addi	sp,sp,32
    800051a8:	8082                	ret
    pi->readopen = 0;
    800051aa:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800051ae:	21c48513          	addi	a0,s1,540
    800051b2:	ffffe097          	auipc	ra,0xffffe
    800051b6:	9be080e7          	jalr	-1602(ra) # 80002b70 <wakeup>
    800051ba:	b7e9                	j	80005184 <pipeclose+0x2c>
    release(&pi->lock);
    800051bc:	8526                	mv	a0,s1
    800051be:	ffffc097          	auipc	ra,0xffffc
    800051c2:	ada080e7          	jalr	-1318(ra) # 80000c98 <release>
}
    800051c6:	bfe1                	j	8000519e <pipeclose+0x46>

00000000800051c8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800051c8:	7159                	addi	sp,sp,-112
    800051ca:	f486                	sd	ra,104(sp)
    800051cc:	f0a2                	sd	s0,96(sp)
    800051ce:	eca6                	sd	s1,88(sp)
    800051d0:	e8ca                	sd	s2,80(sp)
    800051d2:	e4ce                	sd	s3,72(sp)
    800051d4:	e0d2                	sd	s4,64(sp)
    800051d6:	fc56                	sd	s5,56(sp)
    800051d8:	f85a                	sd	s6,48(sp)
    800051da:	f45e                	sd	s7,40(sp)
    800051dc:	f062                	sd	s8,32(sp)
    800051de:	ec66                	sd	s9,24(sp)
    800051e0:	1880                	addi	s0,sp,112
    800051e2:	84aa                	mv	s1,a0
    800051e4:	8aae                	mv	s5,a1
    800051e6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800051e8:	ffffd097          	auipc	ra,0xffffd
    800051ec:	c24080e7          	jalr	-988(ra) # 80001e0c <myproc>
    800051f0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800051f2:	8526                	mv	a0,s1
    800051f4:	ffffc097          	auipc	ra,0xffffc
    800051f8:	9f0080e7          	jalr	-1552(ra) # 80000be4 <acquire>
  while(i < n){
    800051fc:	0d405163          	blez	s4,800052be <pipewrite+0xf6>
    80005200:	8ba6                	mv	s7,s1
  int i = 0;
    80005202:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005204:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005206:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000520a:	21c48c13          	addi	s8,s1,540
    8000520e:	a08d                	j	80005270 <pipewrite+0xa8>
      release(&pi->lock);
    80005210:	8526                	mv	a0,s1
    80005212:	ffffc097          	auipc	ra,0xffffc
    80005216:	a86080e7          	jalr	-1402(ra) # 80000c98 <release>
      return -1;
    8000521a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000521c:	854a                	mv	a0,s2
    8000521e:	70a6                	ld	ra,104(sp)
    80005220:	7406                	ld	s0,96(sp)
    80005222:	64e6                	ld	s1,88(sp)
    80005224:	6946                	ld	s2,80(sp)
    80005226:	69a6                	ld	s3,72(sp)
    80005228:	6a06                	ld	s4,64(sp)
    8000522a:	7ae2                	ld	s5,56(sp)
    8000522c:	7b42                	ld	s6,48(sp)
    8000522e:	7ba2                	ld	s7,40(sp)
    80005230:	7c02                	ld	s8,32(sp)
    80005232:	6ce2                	ld	s9,24(sp)
    80005234:	6165                	addi	sp,sp,112
    80005236:	8082                	ret
      wakeup(&pi->nread);
    80005238:	8566                	mv	a0,s9
    8000523a:	ffffe097          	auipc	ra,0xffffe
    8000523e:	936080e7          	jalr	-1738(ra) # 80002b70 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005242:	85de                	mv	a1,s7
    80005244:	8562                	mv	a0,s8
    80005246:	ffffd097          	auipc	ra,0xffffd
    8000524a:	314080e7          	jalr	788(ra) # 8000255a <sleep>
    8000524e:	a839                	j	8000526c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005250:	21c4a783          	lw	a5,540(s1)
    80005254:	0017871b          	addiw	a4,a5,1
    80005258:	20e4ae23          	sw	a4,540(s1)
    8000525c:	1ff7f793          	andi	a5,a5,511
    80005260:	97a6                	add	a5,a5,s1
    80005262:	f9f44703          	lbu	a4,-97(s0)
    80005266:	00e78c23          	sb	a4,24(a5)
      i++;
    8000526a:	2905                	addiw	s2,s2,1
  while(i < n){
    8000526c:	03495d63          	bge	s2,s4,800052a6 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005270:	2204a783          	lw	a5,544(s1)
    80005274:	dfd1                	beqz	a5,80005210 <pipewrite+0x48>
    80005276:	0289a783          	lw	a5,40(s3)
    8000527a:	fbd9                	bnez	a5,80005210 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000527c:	2184a783          	lw	a5,536(s1)
    80005280:	21c4a703          	lw	a4,540(s1)
    80005284:	2007879b          	addiw	a5,a5,512
    80005288:	faf708e3          	beq	a4,a5,80005238 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000528c:	4685                	li	a3,1
    8000528e:	01590633          	add	a2,s2,s5
    80005292:	f9f40593          	addi	a1,s0,-97
    80005296:	0509b503          	ld	a0,80(s3)
    8000529a:	ffffc097          	auipc	ra,0xffffc
    8000529e:	464080e7          	jalr	1124(ra) # 800016fe <copyin>
    800052a2:	fb6517e3          	bne	a0,s6,80005250 <pipewrite+0x88>
  wakeup(&pi->nread);
    800052a6:	21848513          	addi	a0,s1,536
    800052aa:	ffffe097          	auipc	ra,0xffffe
    800052ae:	8c6080e7          	jalr	-1850(ra) # 80002b70 <wakeup>
  release(&pi->lock);
    800052b2:	8526                	mv	a0,s1
    800052b4:	ffffc097          	auipc	ra,0xffffc
    800052b8:	9e4080e7          	jalr	-1564(ra) # 80000c98 <release>
  return i;
    800052bc:	b785                	j	8000521c <pipewrite+0x54>
  int i = 0;
    800052be:	4901                	li	s2,0
    800052c0:	b7dd                	j	800052a6 <pipewrite+0xde>

00000000800052c2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800052c2:	715d                	addi	sp,sp,-80
    800052c4:	e486                	sd	ra,72(sp)
    800052c6:	e0a2                	sd	s0,64(sp)
    800052c8:	fc26                	sd	s1,56(sp)
    800052ca:	f84a                	sd	s2,48(sp)
    800052cc:	f44e                	sd	s3,40(sp)
    800052ce:	f052                	sd	s4,32(sp)
    800052d0:	ec56                	sd	s5,24(sp)
    800052d2:	e85a                	sd	s6,16(sp)
    800052d4:	0880                	addi	s0,sp,80
    800052d6:	84aa                	mv	s1,a0
    800052d8:	892e                	mv	s2,a1
    800052da:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800052dc:	ffffd097          	auipc	ra,0xffffd
    800052e0:	b30080e7          	jalr	-1232(ra) # 80001e0c <myproc>
    800052e4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800052e6:	8b26                	mv	s6,s1
    800052e8:	8526                	mv	a0,s1
    800052ea:	ffffc097          	auipc	ra,0xffffc
    800052ee:	8fa080e7          	jalr	-1798(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052f2:	2184a703          	lw	a4,536(s1)
    800052f6:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800052fa:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052fe:	02f71463          	bne	a4,a5,80005326 <piperead+0x64>
    80005302:	2244a783          	lw	a5,548(s1)
    80005306:	c385                	beqz	a5,80005326 <piperead+0x64>
    if(pr->killed){
    80005308:	028a2783          	lw	a5,40(s4)
    8000530c:	ebc1                	bnez	a5,8000539c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000530e:	85da                	mv	a1,s6
    80005310:	854e                	mv	a0,s3
    80005312:	ffffd097          	auipc	ra,0xffffd
    80005316:	248080e7          	jalr	584(ra) # 8000255a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000531a:	2184a703          	lw	a4,536(s1)
    8000531e:	21c4a783          	lw	a5,540(s1)
    80005322:	fef700e3          	beq	a4,a5,80005302 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005326:	09505263          	blez	s5,800053aa <piperead+0xe8>
    8000532a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000532c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000532e:	2184a783          	lw	a5,536(s1)
    80005332:	21c4a703          	lw	a4,540(s1)
    80005336:	02f70d63          	beq	a4,a5,80005370 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000533a:	0017871b          	addiw	a4,a5,1
    8000533e:	20e4ac23          	sw	a4,536(s1)
    80005342:	1ff7f793          	andi	a5,a5,511
    80005346:	97a6                	add	a5,a5,s1
    80005348:	0187c783          	lbu	a5,24(a5)
    8000534c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005350:	4685                	li	a3,1
    80005352:	fbf40613          	addi	a2,s0,-65
    80005356:	85ca                	mv	a1,s2
    80005358:	050a3503          	ld	a0,80(s4)
    8000535c:	ffffc097          	auipc	ra,0xffffc
    80005360:	316080e7          	jalr	790(ra) # 80001672 <copyout>
    80005364:	01650663          	beq	a0,s6,80005370 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005368:	2985                	addiw	s3,s3,1
    8000536a:	0905                	addi	s2,s2,1
    8000536c:	fd3a91e3          	bne	s5,s3,8000532e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005370:	21c48513          	addi	a0,s1,540
    80005374:	ffffd097          	auipc	ra,0xffffd
    80005378:	7fc080e7          	jalr	2044(ra) # 80002b70 <wakeup>
  release(&pi->lock);
    8000537c:	8526                	mv	a0,s1
    8000537e:	ffffc097          	auipc	ra,0xffffc
    80005382:	91a080e7          	jalr	-1766(ra) # 80000c98 <release>
  return i;
}
    80005386:	854e                	mv	a0,s3
    80005388:	60a6                	ld	ra,72(sp)
    8000538a:	6406                	ld	s0,64(sp)
    8000538c:	74e2                	ld	s1,56(sp)
    8000538e:	7942                	ld	s2,48(sp)
    80005390:	79a2                	ld	s3,40(sp)
    80005392:	7a02                	ld	s4,32(sp)
    80005394:	6ae2                	ld	s5,24(sp)
    80005396:	6b42                	ld	s6,16(sp)
    80005398:	6161                	addi	sp,sp,80
    8000539a:	8082                	ret
      release(&pi->lock);
    8000539c:	8526                	mv	a0,s1
    8000539e:	ffffc097          	auipc	ra,0xffffc
    800053a2:	8fa080e7          	jalr	-1798(ra) # 80000c98 <release>
      return -1;
    800053a6:	59fd                	li	s3,-1
    800053a8:	bff9                	j	80005386 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053aa:	4981                	li	s3,0
    800053ac:	b7d1                	j	80005370 <piperead+0xae>

00000000800053ae <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800053ae:	df010113          	addi	sp,sp,-528
    800053b2:	20113423          	sd	ra,520(sp)
    800053b6:	20813023          	sd	s0,512(sp)
    800053ba:	ffa6                	sd	s1,504(sp)
    800053bc:	fbca                	sd	s2,496(sp)
    800053be:	f7ce                	sd	s3,488(sp)
    800053c0:	f3d2                	sd	s4,480(sp)
    800053c2:	efd6                	sd	s5,472(sp)
    800053c4:	ebda                	sd	s6,464(sp)
    800053c6:	e7de                	sd	s7,456(sp)
    800053c8:	e3e2                	sd	s8,448(sp)
    800053ca:	ff66                	sd	s9,440(sp)
    800053cc:	fb6a                	sd	s10,432(sp)
    800053ce:	f76e                	sd	s11,424(sp)
    800053d0:	0c00                	addi	s0,sp,528
    800053d2:	84aa                	mv	s1,a0
    800053d4:	dea43c23          	sd	a0,-520(s0)
    800053d8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800053dc:	ffffd097          	auipc	ra,0xffffd
    800053e0:	a30080e7          	jalr	-1488(ra) # 80001e0c <myproc>
    800053e4:	892a                	mv	s2,a0

  begin_op();
    800053e6:	fffff097          	auipc	ra,0xfffff
    800053ea:	49c080e7          	jalr	1180(ra) # 80004882 <begin_op>

  if((ip = namei(path)) == 0){
    800053ee:	8526                	mv	a0,s1
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	276080e7          	jalr	630(ra) # 80004666 <namei>
    800053f8:	c92d                	beqz	a0,8000546a <exec+0xbc>
    800053fa:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800053fc:	fffff097          	auipc	ra,0xfffff
    80005400:	ab4080e7          	jalr	-1356(ra) # 80003eb0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005404:	04000713          	li	a4,64
    80005408:	4681                	li	a3,0
    8000540a:	e5040613          	addi	a2,s0,-432
    8000540e:	4581                	li	a1,0
    80005410:	8526                	mv	a0,s1
    80005412:	fffff097          	auipc	ra,0xfffff
    80005416:	d52080e7          	jalr	-686(ra) # 80004164 <readi>
    8000541a:	04000793          	li	a5,64
    8000541e:	00f51a63          	bne	a0,a5,80005432 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005422:	e5042703          	lw	a4,-432(s0)
    80005426:	464c47b7          	lui	a5,0x464c4
    8000542a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000542e:	04f70463          	beq	a4,a5,80005476 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005432:	8526                	mv	a0,s1
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	cde080e7          	jalr	-802(ra) # 80004112 <iunlockput>
    end_op();
    8000543c:	fffff097          	auipc	ra,0xfffff
    80005440:	4c6080e7          	jalr	1222(ra) # 80004902 <end_op>
  }
  return -1;
    80005444:	557d                	li	a0,-1
}
    80005446:	20813083          	ld	ra,520(sp)
    8000544a:	20013403          	ld	s0,512(sp)
    8000544e:	74fe                	ld	s1,504(sp)
    80005450:	795e                	ld	s2,496(sp)
    80005452:	79be                	ld	s3,488(sp)
    80005454:	7a1e                	ld	s4,480(sp)
    80005456:	6afe                	ld	s5,472(sp)
    80005458:	6b5e                	ld	s6,464(sp)
    8000545a:	6bbe                	ld	s7,456(sp)
    8000545c:	6c1e                	ld	s8,448(sp)
    8000545e:	7cfa                	ld	s9,440(sp)
    80005460:	7d5a                	ld	s10,432(sp)
    80005462:	7dba                	ld	s11,424(sp)
    80005464:	21010113          	addi	sp,sp,528
    80005468:	8082                	ret
    end_op();
    8000546a:	fffff097          	auipc	ra,0xfffff
    8000546e:	498080e7          	jalr	1176(ra) # 80004902 <end_op>
    return -1;
    80005472:	557d                	li	a0,-1
    80005474:	bfc9                	j	80005446 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005476:	854a                	mv	a0,s2
    80005478:	ffffd097          	auipc	ra,0xffffd
    8000547c:	a52080e7          	jalr	-1454(ra) # 80001eca <proc_pagetable>
    80005480:	8baa                	mv	s7,a0
    80005482:	d945                	beqz	a0,80005432 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005484:	e7042983          	lw	s3,-400(s0)
    80005488:	e8845783          	lhu	a5,-376(s0)
    8000548c:	c7ad                	beqz	a5,800054f6 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000548e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005490:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005492:	6c85                	lui	s9,0x1
    80005494:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005498:	def43823          	sd	a5,-528(s0)
    8000549c:	a42d                	j	800056c6 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000549e:	00003517          	auipc	a0,0x3
    800054a2:	4ba50513          	addi	a0,a0,1210 # 80008958 <syscalls+0x298>
    800054a6:	ffffb097          	auipc	ra,0xffffb
    800054aa:	098080e7          	jalr	152(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800054ae:	8756                	mv	a4,s5
    800054b0:	012d86bb          	addw	a3,s11,s2
    800054b4:	4581                	li	a1,0
    800054b6:	8526                	mv	a0,s1
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	cac080e7          	jalr	-852(ra) # 80004164 <readi>
    800054c0:	2501                	sext.w	a0,a0
    800054c2:	1aaa9963          	bne	s5,a0,80005674 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800054c6:	6785                	lui	a5,0x1
    800054c8:	0127893b          	addw	s2,a5,s2
    800054cc:	77fd                	lui	a5,0xfffff
    800054ce:	01478a3b          	addw	s4,a5,s4
    800054d2:	1f897163          	bgeu	s2,s8,800056b4 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800054d6:	02091593          	slli	a1,s2,0x20
    800054da:	9181                	srli	a1,a1,0x20
    800054dc:	95ea                	add	a1,a1,s10
    800054de:	855e                	mv	a0,s7
    800054e0:	ffffc097          	auipc	ra,0xffffc
    800054e4:	b8e080e7          	jalr	-1138(ra) # 8000106e <walkaddr>
    800054e8:	862a                	mv	a2,a0
    if(pa == 0)
    800054ea:	d955                	beqz	a0,8000549e <exec+0xf0>
      n = PGSIZE;
    800054ec:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800054ee:	fd9a70e3          	bgeu	s4,s9,800054ae <exec+0x100>
      n = sz - i;
    800054f2:	8ad2                	mv	s5,s4
    800054f4:	bf6d                	j	800054ae <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800054f6:	4901                	li	s2,0
  iunlockput(ip);
    800054f8:	8526                	mv	a0,s1
    800054fa:	fffff097          	auipc	ra,0xfffff
    800054fe:	c18080e7          	jalr	-1000(ra) # 80004112 <iunlockput>
  end_op();
    80005502:	fffff097          	auipc	ra,0xfffff
    80005506:	400080e7          	jalr	1024(ra) # 80004902 <end_op>
  p = myproc();
    8000550a:	ffffd097          	auipc	ra,0xffffd
    8000550e:	902080e7          	jalr	-1790(ra) # 80001e0c <myproc>
    80005512:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005514:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005518:	6785                	lui	a5,0x1
    8000551a:	17fd                	addi	a5,a5,-1
    8000551c:	993e                	add	s2,s2,a5
    8000551e:	757d                	lui	a0,0xfffff
    80005520:	00a977b3          	and	a5,s2,a0
    80005524:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005528:	6609                	lui	a2,0x2
    8000552a:	963e                	add	a2,a2,a5
    8000552c:	85be                	mv	a1,a5
    8000552e:	855e                	mv	a0,s7
    80005530:	ffffc097          	auipc	ra,0xffffc
    80005534:	ef2080e7          	jalr	-270(ra) # 80001422 <uvmalloc>
    80005538:	8b2a                	mv	s6,a0
  ip = 0;
    8000553a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000553c:	12050c63          	beqz	a0,80005674 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005540:	75f9                	lui	a1,0xffffe
    80005542:	95aa                	add	a1,a1,a0
    80005544:	855e                	mv	a0,s7
    80005546:	ffffc097          	auipc	ra,0xffffc
    8000554a:	0fa080e7          	jalr	250(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    8000554e:	7c7d                	lui	s8,0xfffff
    80005550:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005552:	e0043783          	ld	a5,-512(s0)
    80005556:	6388                	ld	a0,0(a5)
    80005558:	c535                	beqz	a0,800055c4 <exec+0x216>
    8000555a:	e9040993          	addi	s3,s0,-368
    8000555e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005562:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005564:	ffffc097          	auipc	ra,0xffffc
    80005568:	900080e7          	jalr	-1792(ra) # 80000e64 <strlen>
    8000556c:	2505                	addiw	a0,a0,1
    8000556e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005572:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005576:	13896363          	bltu	s2,s8,8000569c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000557a:	e0043d83          	ld	s11,-512(s0)
    8000557e:	000dba03          	ld	s4,0(s11)
    80005582:	8552                	mv	a0,s4
    80005584:	ffffc097          	auipc	ra,0xffffc
    80005588:	8e0080e7          	jalr	-1824(ra) # 80000e64 <strlen>
    8000558c:	0015069b          	addiw	a3,a0,1
    80005590:	8652                	mv	a2,s4
    80005592:	85ca                	mv	a1,s2
    80005594:	855e                	mv	a0,s7
    80005596:	ffffc097          	auipc	ra,0xffffc
    8000559a:	0dc080e7          	jalr	220(ra) # 80001672 <copyout>
    8000559e:	10054363          	bltz	a0,800056a4 <exec+0x2f6>
    ustack[argc] = sp;
    800055a2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800055a6:	0485                	addi	s1,s1,1
    800055a8:	008d8793          	addi	a5,s11,8
    800055ac:	e0f43023          	sd	a5,-512(s0)
    800055b0:	008db503          	ld	a0,8(s11)
    800055b4:	c911                	beqz	a0,800055c8 <exec+0x21a>
    if(argc >= MAXARG)
    800055b6:	09a1                	addi	s3,s3,8
    800055b8:	fb3c96e3          	bne	s9,s3,80005564 <exec+0x1b6>
  sz = sz1;
    800055bc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055c0:	4481                	li	s1,0
    800055c2:	a84d                	j	80005674 <exec+0x2c6>
  sp = sz;
    800055c4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800055c6:	4481                	li	s1,0
  ustack[argc] = 0;
    800055c8:	00349793          	slli	a5,s1,0x3
    800055cc:	f9040713          	addi	a4,s0,-112
    800055d0:	97ba                	add	a5,a5,a4
    800055d2:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800055d6:	00148693          	addi	a3,s1,1
    800055da:	068e                	slli	a3,a3,0x3
    800055dc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800055e0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800055e4:	01897663          	bgeu	s2,s8,800055f0 <exec+0x242>
  sz = sz1;
    800055e8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055ec:	4481                	li	s1,0
    800055ee:	a059                	j	80005674 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800055f0:	e9040613          	addi	a2,s0,-368
    800055f4:	85ca                	mv	a1,s2
    800055f6:	855e                	mv	a0,s7
    800055f8:	ffffc097          	auipc	ra,0xffffc
    800055fc:	07a080e7          	jalr	122(ra) # 80001672 <copyout>
    80005600:	0a054663          	bltz	a0,800056ac <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005604:	058ab783          	ld	a5,88(s5)
    80005608:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000560c:	df843783          	ld	a5,-520(s0)
    80005610:	0007c703          	lbu	a4,0(a5)
    80005614:	cf11                	beqz	a4,80005630 <exec+0x282>
    80005616:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005618:	02f00693          	li	a3,47
    8000561c:	a039                	j	8000562a <exec+0x27c>
      last = s+1;
    8000561e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005622:	0785                	addi	a5,a5,1
    80005624:	fff7c703          	lbu	a4,-1(a5)
    80005628:	c701                	beqz	a4,80005630 <exec+0x282>
    if(*s == '/')
    8000562a:	fed71ce3          	bne	a4,a3,80005622 <exec+0x274>
    8000562e:	bfc5                	j	8000561e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005630:	4641                	li	a2,16
    80005632:	df843583          	ld	a1,-520(s0)
    80005636:	158a8513          	addi	a0,s5,344
    8000563a:	ffffb097          	auipc	ra,0xffffb
    8000563e:	7f8080e7          	jalr	2040(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005642:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005646:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000564a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000564e:	058ab783          	ld	a5,88(s5)
    80005652:	e6843703          	ld	a4,-408(s0)
    80005656:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005658:	058ab783          	ld	a5,88(s5)
    8000565c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005660:	85ea                	mv	a1,s10
    80005662:	ffffd097          	auipc	ra,0xffffd
    80005666:	904080e7          	jalr	-1788(ra) # 80001f66 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000566a:	0004851b          	sext.w	a0,s1
    8000566e:	bbe1                	j	80005446 <exec+0x98>
    80005670:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005674:	e0843583          	ld	a1,-504(s0)
    80005678:	855e                	mv	a0,s7
    8000567a:	ffffd097          	auipc	ra,0xffffd
    8000567e:	8ec080e7          	jalr	-1812(ra) # 80001f66 <proc_freepagetable>
  if(ip){
    80005682:	da0498e3          	bnez	s1,80005432 <exec+0x84>
  return -1;
    80005686:	557d                	li	a0,-1
    80005688:	bb7d                	j	80005446 <exec+0x98>
    8000568a:	e1243423          	sd	s2,-504(s0)
    8000568e:	b7dd                	j	80005674 <exec+0x2c6>
    80005690:	e1243423          	sd	s2,-504(s0)
    80005694:	b7c5                	j	80005674 <exec+0x2c6>
    80005696:	e1243423          	sd	s2,-504(s0)
    8000569a:	bfe9                	j	80005674 <exec+0x2c6>
  sz = sz1;
    8000569c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056a0:	4481                	li	s1,0
    800056a2:	bfc9                	j	80005674 <exec+0x2c6>
  sz = sz1;
    800056a4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056a8:	4481                	li	s1,0
    800056aa:	b7e9                	j	80005674 <exec+0x2c6>
  sz = sz1;
    800056ac:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056b0:	4481                	li	s1,0
    800056b2:	b7c9                	j	80005674 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800056b4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056b8:	2b05                	addiw	s6,s6,1
    800056ba:	0389899b          	addiw	s3,s3,56
    800056be:	e8845783          	lhu	a5,-376(s0)
    800056c2:	e2fb5be3          	bge	s6,a5,800054f8 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800056c6:	2981                	sext.w	s3,s3
    800056c8:	03800713          	li	a4,56
    800056cc:	86ce                	mv	a3,s3
    800056ce:	e1840613          	addi	a2,s0,-488
    800056d2:	4581                	li	a1,0
    800056d4:	8526                	mv	a0,s1
    800056d6:	fffff097          	auipc	ra,0xfffff
    800056da:	a8e080e7          	jalr	-1394(ra) # 80004164 <readi>
    800056de:	03800793          	li	a5,56
    800056e2:	f8f517e3          	bne	a0,a5,80005670 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800056e6:	e1842783          	lw	a5,-488(s0)
    800056ea:	4705                	li	a4,1
    800056ec:	fce796e3          	bne	a5,a4,800056b8 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800056f0:	e4043603          	ld	a2,-448(s0)
    800056f4:	e3843783          	ld	a5,-456(s0)
    800056f8:	f8f669e3          	bltu	a2,a5,8000568a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800056fc:	e2843783          	ld	a5,-472(s0)
    80005700:	963e                	add	a2,a2,a5
    80005702:	f8f667e3          	bltu	a2,a5,80005690 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005706:	85ca                	mv	a1,s2
    80005708:	855e                	mv	a0,s7
    8000570a:	ffffc097          	auipc	ra,0xffffc
    8000570e:	d18080e7          	jalr	-744(ra) # 80001422 <uvmalloc>
    80005712:	e0a43423          	sd	a0,-504(s0)
    80005716:	d141                	beqz	a0,80005696 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005718:	e2843d03          	ld	s10,-472(s0)
    8000571c:	df043783          	ld	a5,-528(s0)
    80005720:	00fd77b3          	and	a5,s10,a5
    80005724:	fba1                	bnez	a5,80005674 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005726:	e2042d83          	lw	s11,-480(s0)
    8000572a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000572e:	f80c03e3          	beqz	s8,800056b4 <exec+0x306>
    80005732:	8a62                	mv	s4,s8
    80005734:	4901                	li	s2,0
    80005736:	b345                	j	800054d6 <exec+0x128>

0000000080005738 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005738:	7179                	addi	sp,sp,-48
    8000573a:	f406                	sd	ra,40(sp)
    8000573c:	f022                	sd	s0,32(sp)
    8000573e:	ec26                	sd	s1,24(sp)
    80005740:	e84a                	sd	s2,16(sp)
    80005742:	1800                	addi	s0,sp,48
    80005744:	892e                	mv	s2,a1
    80005746:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005748:	fdc40593          	addi	a1,s0,-36
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	b76080e7          	jalr	-1162(ra) # 800032c2 <argint>
    80005754:	04054063          	bltz	a0,80005794 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005758:	fdc42703          	lw	a4,-36(s0)
    8000575c:	47bd                	li	a5,15
    8000575e:	02e7ed63          	bltu	a5,a4,80005798 <argfd+0x60>
    80005762:	ffffc097          	auipc	ra,0xffffc
    80005766:	6aa080e7          	jalr	1706(ra) # 80001e0c <myproc>
    8000576a:	fdc42703          	lw	a4,-36(s0)
    8000576e:	01a70793          	addi	a5,a4,26
    80005772:	078e                	slli	a5,a5,0x3
    80005774:	953e                	add	a0,a0,a5
    80005776:	611c                	ld	a5,0(a0)
    80005778:	c395                	beqz	a5,8000579c <argfd+0x64>
    return -1;
  if(pfd)
    8000577a:	00090463          	beqz	s2,80005782 <argfd+0x4a>
    *pfd = fd;
    8000577e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005782:	4501                	li	a0,0
  if(pf)
    80005784:	c091                	beqz	s1,80005788 <argfd+0x50>
    *pf = f;
    80005786:	e09c                	sd	a5,0(s1)
}
    80005788:	70a2                	ld	ra,40(sp)
    8000578a:	7402                	ld	s0,32(sp)
    8000578c:	64e2                	ld	s1,24(sp)
    8000578e:	6942                	ld	s2,16(sp)
    80005790:	6145                	addi	sp,sp,48
    80005792:	8082                	ret
    return -1;
    80005794:	557d                	li	a0,-1
    80005796:	bfcd                	j	80005788 <argfd+0x50>
    return -1;
    80005798:	557d                	li	a0,-1
    8000579a:	b7fd                	j	80005788 <argfd+0x50>
    8000579c:	557d                	li	a0,-1
    8000579e:	b7ed                	j	80005788 <argfd+0x50>

00000000800057a0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800057a0:	1101                	addi	sp,sp,-32
    800057a2:	ec06                	sd	ra,24(sp)
    800057a4:	e822                	sd	s0,16(sp)
    800057a6:	e426                	sd	s1,8(sp)
    800057a8:	1000                	addi	s0,sp,32
    800057aa:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800057ac:	ffffc097          	auipc	ra,0xffffc
    800057b0:	660080e7          	jalr	1632(ra) # 80001e0c <myproc>
    800057b4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800057b6:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800057ba:	4501                	li	a0,0
    800057bc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800057be:	6398                	ld	a4,0(a5)
    800057c0:	cb19                	beqz	a4,800057d6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800057c2:	2505                	addiw	a0,a0,1
    800057c4:	07a1                	addi	a5,a5,8
    800057c6:	fed51ce3          	bne	a0,a3,800057be <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800057ca:	557d                	li	a0,-1
}
    800057cc:	60e2                	ld	ra,24(sp)
    800057ce:	6442                	ld	s0,16(sp)
    800057d0:	64a2                	ld	s1,8(sp)
    800057d2:	6105                	addi	sp,sp,32
    800057d4:	8082                	ret
      p->ofile[fd] = f;
    800057d6:	01a50793          	addi	a5,a0,26
    800057da:	078e                	slli	a5,a5,0x3
    800057dc:	963e                	add	a2,a2,a5
    800057de:	e204                	sd	s1,0(a2)
      return fd;
    800057e0:	b7f5                	j	800057cc <fdalloc+0x2c>

00000000800057e2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800057e2:	715d                	addi	sp,sp,-80
    800057e4:	e486                	sd	ra,72(sp)
    800057e6:	e0a2                	sd	s0,64(sp)
    800057e8:	fc26                	sd	s1,56(sp)
    800057ea:	f84a                	sd	s2,48(sp)
    800057ec:	f44e                	sd	s3,40(sp)
    800057ee:	f052                	sd	s4,32(sp)
    800057f0:	ec56                	sd	s5,24(sp)
    800057f2:	0880                	addi	s0,sp,80
    800057f4:	89ae                	mv	s3,a1
    800057f6:	8ab2                	mv	s5,a2
    800057f8:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800057fa:	fb040593          	addi	a1,s0,-80
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	e86080e7          	jalr	-378(ra) # 80004684 <nameiparent>
    80005806:	892a                	mv	s2,a0
    80005808:	12050f63          	beqz	a0,80005946 <create+0x164>
    return 0;

  ilock(dp);
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	6a4080e7          	jalr	1700(ra) # 80003eb0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005814:	4601                	li	a2,0
    80005816:	fb040593          	addi	a1,s0,-80
    8000581a:	854a                	mv	a0,s2
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	b78080e7          	jalr	-1160(ra) # 80004394 <dirlookup>
    80005824:	84aa                	mv	s1,a0
    80005826:	c921                	beqz	a0,80005876 <create+0x94>
    iunlockput(dp);
    80005828:	854a                	mv	a0,s2
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	8e8080e7          	jalr	-1816(ra) # 80004112 <iunlockput>
    ilock(ip);
    80005832:	8526                	mv	a0,s1
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	67c080e7          	jalr	1660(ra) # 80003eb0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000583c:	2981                	sext.w	s3,s3
    8000583e:	4789                	li	a5,2
    80005840:	02f99463          	bne	s3,a5,80005868 <create+0x86>
    80005844:	0444d783          	lhu	a5,68(s1)
    80005848:	37f9                	addiw	a5,a5,-2
    8000584a:	17c2                	slli	a5,a5,0x30
    8000584c:	93c1                	srli	a5,a5,0x30
    8000584e:	4705                	li	a4,1
    80005850:	00f76c63          	bltu	a4,a5,80005868 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005854:	8526                	mv	a0,s1
    80005856:	60a6                	ld	ra,72(sp)
    80005858:	6406                	ld	s0,64(sp)
    8000585a:	74e2                	ld	s1,56(sp)
    8000585c:	7942                	ld	s2,48(sp)
    8000585e:	79a2                	ld	s3,40(sp)
    80005860:	7a02                	ld	s4,32(sp)
    80005862:	6ae2                	ld	s5,24(sp)
    80005864:	6161                	addi	sp,sp,80
    80005866:	8082                	ret
    iunlockput(ip);
    80005868:	8526                	mv	a0,s1
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	8a8080e7          	jalr	-1880(ra) # 80004112 <iunlockput>
    return 0;
    80005872:	4481                	li	s1,0
    80005874:	b7c5                	j	80005854 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005876:	85ce                	mv	a1,s3
    80005878:	00092503          	lw	a0,0(s2)
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	49c080e7          	jalr	1180(ra) # 80003d18 <ialloc>
    80005884:	84aa                	mv	s1,a0
    80005886:	c529                	beqz	a0,800058d0 <create+0xee>
  ilock(ip);
    80005888:	ffffe097          	auipc	ra,0xffffe
    8000588c:	628080e7          	jalr	1576(ra) # 80003eb0 <ilock>
  ip->major = major;
    80005890:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005894:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005898:	4785                	li	a5,1
    8000589a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000589e:	8526                	mv	a0,s1
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	546080e7          	jalr	1350(ra) # 80003de6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800058a8:	2981                	sext.w	s3,s3
    800058aa:	4785                	li	a5,1
    800058ac:	02f98a63          	beq	s3,a5,800058e0 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800058b0:	40d0                	lw	a2,4(s1)
    800058b2:	fb040593          	addi	a1,s0,-80
    800058b6:	854a                	mv	a0,s2
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	cec080e7          	jalr	-788(ra) # 800045a4 <dirlink>
    800058c0:	06054b63          	bltz	a0,80005936 <create+0x154>
  iunlockput(dp);
    800058c4:	854a                	mv	a0,s2
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	84c080e7          	jalr	-1972(ra) # 80004112 <iunlockput>
  return ip;
    800058ce:	b759                	j	80005854 <create+0x72>
    panic("create: ialloc");
    800058d0:	00003517          	auipc	a0,0x3
    800058d4:	0a850513          	addi	a0,a0,168 # 80008978 <syscalls+0x2b8>
    800058d8:	ffffb097          	auipc	ra,0xffffb
    800058dc:	c66080e7          	jalr	-922(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800058e0:	04a95783          	lhu	a5,74(s2)
    800058e4:	2785                	addiw	a5,a5,1
    800058e6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800058ea:	854a                	mv	a0,s2
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	4fa080e7          	jalr	1274(ra) # 80003de6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800058f4:	40d0                	lw	a2,4(s1)
    800058f6:	00003597          	auipc	a1,0x3
    800058fa:	09258593          	addi	a1,a1,146 # 80008988 <syscalls+0x2c8>
    800058fe:	8526                	mv	a0,s1
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	ca4080e7          	jalr	-860(ra) # 800045a4 <dirlink>
    80005908:	00054f63          	bltz	a0,80005926 <create+0x144>
    8000590c:	00492603          	lw	a2,4(s2)
    80005910:	00003597          	auipc	a1,0x3
    80005914:	08058593          	addi	a1,a1,128 # 80008990 <syscalls+0x2d0>
    80005918:	8526                	mv	a0,s1
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	c8a080e7          	jalr	-886(ra) # 800045a4 <dirlink>
    80005922:	f80557e3          	bgez	a0,800058b0 <create+0xce>
      panic("create dots");
    80005926:	00003517          	auipc	a0,0x3
    8000592a:	07250513          	addi	a0,a0,114 # 80008998 <syscalls+0x2d8>
    8000592e:	ffffb097          	auipc	ra,0xffffb
    80005932:	c10080e7          	jalr	-1008(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005936:	00003517          	auipc	a0,0x3
    8000593a:	07250513          	addi	a0,a0,114 # 800089a8 <syscalls+0x2e8>
    8000593e:	ffffb097          	auipc	ra,0xffffb
    80005942:	c00080e7          	jalr	-1024(ra) # 8000053e <panic>
    return 0;
    80005946:	84aa                	mv	s1,a0
    80005948:	b731                	j	80005854 <create+0x72>

000000008000594a <sys_dup>:
{
    8000594a:	7179                	addi	sp,sp,-48
    8000594c:	f406                	sd	ra,40(sp)
    8000594e:	f022                	sd	s0,32(sp)
    80005950:	ec26                	sd	s1,24(sp)
    80005952:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005954:	fd840613          	addi	a2,s0,-40
    80005958:	4581                	li	a1,0
    8000595a:	4501                	li	a0,0
    8000595c:	00000097          	auipc	ra,0x0
    80005960:	ddc080e7          	jalr	-548(ra) # 80005738 <argfd>
    return -1;
    80005964:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005966:	02054363          	bltz	a0,8000598c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000596a:	fd843503          	ld	a0,-40(s0)
    8000596e:	00000097          	auipc	ra,0x0
    80005972:	e32080e7          	jalr	-462(ra) # 800057a0 <fdalloc>
    80005976:	84aa                	mv	s1,a0
    return -1;
    80005978:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000597a:	00054963          	bltz	a0,8000598c <sys_dup+0x42>
  filedup(f);
    8000597e:	fd843503          	ld	a0,-40(s0)
    80005982:	fffff097          	auipc	ra,0xfffff
    80005986:	37a080e7          	jalr	890(ra) # 80004cfc <filedup>
  return fd;
    8000598a:	87a6                	mv	a5,s1
}
    8000598c:	853e                	mv	a0,a5
    8000598e:	70a2                	ld	ra,40(sp)
    80005990:	7402                	ld	s0,32(sp)
    80005992:	64e2                	ld	s1,24(sp)
    80005994:	6145                	addi	sp,sp,48
    80005996:	8082                	ret

0000000080005998 <sys_read>:
{
    80005998:	7179                	addi	sp,sp,-48
    8000599a:	f406                	sd	ra,40(sp)
    8000599c:	f022                	sd	s0,32(sp)
    8000599e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059a0:	fe840613          	addi	a2,s0,-24
    800059a4:	4581                	li	a1,0
    800059a6:	4501                	li	a0,0
    800059a8:	00000097          	auipc	ra,0x0
    800059ac:	d90080e7          	jalr	-624(ra) # 80005738 <argfd>
    return -1;
    800059b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059b2:	04054163          	bltz	a0,800059f4 <sys_read+0x5c>
    800059b6:	fe440593          	addi	a1,s0,-28
    800059ba:	4509                	li	a0,2
    800059bc:	ffffe097          	auipc	ra,0xffffe
    800059c0:	906080e7          	jalr	-1786(ra) # 800032c2 <argint>
    return -1;
    800059c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059c6:	02054763          	bltz	a0,800059f4 <sys_read+0x5c>
    800059ca:	fd840593          	addi	a1,s0,-40
    800059ce:	4505                	li	a0,1
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	914080e7          	jalr	-1772(ra) # 800032e4 <argaddr>
    return -1;
    800059d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059da:	00054d63          	bltz	a0,800059f4 <sys_read+0x5c>
  return fileread(f, p, n);
    800059de:	fe442603          	lw	a2,-28(s0)
    800059e2:	fd843583          	ld	a1,-40(s0)
    800059e6:	fe843503          	ld	a0,-24(s0)
    800059ea:	fffff097          	auipc	ra,0xfffff
    800059ee:	49e080e7          	jalr	1182(ra) # 80004e88 <fileread>
    800059f2:	87aa                	mv	a5,a0
}
    800059f4:	853e                	mv	a0,a5
    800059f6:	70a2                	ld	ra,40(sp)
    800059f8:	7402                	ld	s0,32(sp)
    800059fa:	6145                	addi	sp,sp,48
    800059fc:	8082                	ret

00000000800059fe <sys_write>:
{
    800059fe:	7179                	addi	sp,sp,-48
    80005a00:	f406                	sd	ra,40(sp)
    80005a02:	f022                	sd	s0,32(sp)
    80005a04:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a06:	fe840613          	addi	a2,s0,-24
    80005a0a:	4581                	li	a1,0
    80005a0c:	4501                	li	a0,0
    80005a0e:	00000097          	auipc	ra,0x0
    80005a12:	d2a080e7          	jalr	-726(ra) # 80005738 <argfd>
    return -1;
    80005a16:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a18:	04054163          	bltz	a0,80005a5a <sys_write+0x5c>
    80005a1c:	fe440593          	addi	a1,s0,-28
    80005a20:	4509                	li	a0,2
    80005a22:	ffffe097          	auipc	ra,0xffffe
    80005a26:	8a0080e7          	jalr	-1888(ra) # 800032c2 <argint>
    return -1;
    80005a2a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a2c:	02054763          	bltz	a0,80005a5a <sys_write+0x5c>
    80005a30:	fd840593          	addi	a1,s0,-40
    80005a34:	4505                	li	a0,1
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	8ae080e7          	jalr	-1874(ra) # 800032e4 <argaddr>
    return -1;
    80005a3e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a40:	00054d63          	bltz	a0,80005a5a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005a44:	fe442603          	lw	a2,-28(s0)
    80005a48:	fd843583          	ld	a1,-40(s0)
    80005a4c:	fe843503          	ld	a0,-24(s0)
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	4fa080e7          	jalr	1274(ra) # 80004f4a <filewrite>
    80005a58:	87aa                	mv	a5,a0
}
    80005a5a:	853e                	mv	a0,a5
    80005a5c:	70a2                	ld	ra,40(sp)
    80005a5e:	7402                	ld	s0,32(sp)
    80005a60:	6145                	addi	sp,sp,48
    80005a62:	8082                	ret

0000000080005a64 <sys_close>:
{
    80005a64:	1101                	addi	sp,sp,-32
    80005a66:	ec06                	sd	ra,24(sp)
    80005a68:	e822                	sd	s0,16(sp)
    80005a6a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005a6c:	fe040613          	addi	a2,s0,-32
    80005a70:	fec40593          	addi	a1,s0,-20
    80005a74:	4501                	li	a0,0
    80005a76:	00000097          	auipc	ra,0x0
    80005a7a:	cc2080e7          	jalr	-830(ra) # 80005738 <argfd>
    return -1;
    80005a7e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a80:	02054463          	bltz	a0,80005aa8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005a84:	ffffc097          	auipc	ra,0xffffc
    80005a88:	388080e7          	jalr	904(ra) # 80001e0c <myproc>
    80005a8c:	fec42783          	lw	a5,-20(s0)
    80005a90:	07e9                	addi	a5,a5,26
    80005a92:	078e                	slli	a5,a5,0x3
    80005a94:	97aa                	add	a5,a5,a0
    80005a96:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005a9a:	fe043503          	ld	a0,-32(s0)
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	2b0080e7          	jalr	688(ra) # 80004d4e <fileclose>
  return 0;
    80005aa6:	4781                	li	a5,0
}
    80005aa8:	853e                	mv	a0,a5
    80005aaa:	60e2                	ld	ra,24(sp)
    80005aac:	6442                	ld	s0,16(sp)
    80005aae:	6105                	addi	sp,sp,32
    80005ab0:	8082                	ret

0000000080005ab2 <sys_fstat>:
{
    80005ab2:	1101                	addi	sp,sp,-32
    80005ab4:	ec06                	sd	ra,24(sp)
    80005ab6:	e822                	sd	s0,16(sp)
    80005ab8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005aba:	fe840613          	addi	a2,s0,-24
    80005abe:	4581                	li	a1,0
    80005ac0:	4501                	li	a0,0
    80005ac2:	00000097          	auipc	ra,0x0
    80005ac6:	c76080e7          	jalr	-906(ra) # 80005738 <argfd>
    return -1;
    80005aca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005acc:	02054563          	bltz	a0,80005af6 <sys_fstat+0x44>
    80005ad0:	fe040593          	addi	a1,s0,-32
    80005ad4:	4505                	li	a0,1
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	80e080e7          	jalr	-2034(ra) # 800032e4 <argaddr>
    return -1;
    80005ade:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ae0:	00054b63          	bltz	a0,80005af6 <sys_fstat+0x44>
  return filestat(f, st);
    80005ae4:	fe043583          	ld	a1,-32(s0)
    80005ae8:	fe843503          	ld	a0,-24(s0)
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	32a080e7          	jalr	810(ra) # 80004e16 <filestat>
    80005af4:	87aa                	mv	a5,a0
}
    80005af6:	853e                	mv	a0,a5
    80005af8:	60e2                	ld	ra,24(sp)
    80005afa:	6442                	ld	s0,16(sp)
    80005afc:	6105                	addi	sp,sp,32
    80005afe:	8082                	ret

0000000080005b00 <sys_link>:
{
    80005b00:	7169                	addi	sp,sp,-304
    80005b02:	f606                	sd	ra,296(sp)
    80005b04:	f222                	sd	s0,288(sp)
    80005b06:	ee26                	sd	s1,280(sp)
    80005b08:	ea4a                	sd	s2,272(sp)
    80005b0a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b0c:	08000613          	li	a2,128
    80005b10:	ed040593          	addi	a1,s0,-304
    80005b14:	4501                	li	a0,0
    80005b16:	ffffd097          	auipc	ra,0xffffd
    80005b1a:	7f0080e7          	jalr	2032(ra) # 80003306 <argstr>
    return -1;
    80005b1e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b20:	10054e63          	bltz	a0,80005c3c <sys_link+0x13c>
    80005b24:	08000613          	li	a2,128
    80005b28:	f5040593          	addi	a1,s0,-176
    80005b2c:	4505                	li	a0,1
    80005b2e:	ffffd097          	auipc	ra,0xffffd
    80005b32:	7d8080e7          	jalr	2008(ra) # 80003306 <argstr>
    return -1;
    80005b36:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b38:	10054263          	bltz	a0,80005c3c <sys_link+0x13c>
  begin_op();
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	d46080e7          	jalr	-698(ra) # 80004882 <begin_op>
  if((ip = namei(old)) == 0){
    80005b44:	ed040513          	addi	a0,s0,-304
    80005b48:	fffff097          	auipc	ra,0xfffff
    80005b4c:	b1e080e7          	jalr	-1250(ra) # 80004666 <namei>
    80005b50:	84aa                	mv	s1,a0
    80005b52:	c551                	beqz	a0,80005bde <sys_link+0xde>
  ilock(ip);
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	35c080e7          	jalr	860(ra) # 80003eb0 <ilock>
  if(ip->type == T_DIR){
    80005b5c:	04449703          	lh	a4,68(s1)
    80005b60:	4785                	li	a5,1
    80005b62:	08f70463          	beq	a4,a5,80005bea <sys_link+0xea>
  ip->nlink++;
    80005b66:	04a4d783          	lhu	a5,74(s1)
    80005b6a:	2785                	addiw	a5,a5,1
    80005b6c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b70:	8526                	mv	a0,s1
    80005b72:	ffffe097          	auipc	ra,0xffffe
    80005b76:	274080e7          	jalr	628(ra) # 80003de6 <iupdate>
  iunlock(ip);
    80005b7a:	8526                	mv	a0,s1
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	3f6080e7          	jalr	1014(ra) # 80003f72 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b84:	fd040593          	addi	a1,s0,-48
    80005b88:	f5040513          	addi	a0,s0,-176
    80005b8c:	fffff097          	auipc	ra,0xfffff
    80005b90:	af8080e7          	jalr	-1288(ra) # 80004684 <nameiparent>
    80005b94:	892a                	mv	s2,a0
    80005b96:	c935                	beqz	a0,80005c0a <sys_link+0x10a>
  ilock(dp);
    80005b98:	ffffe097          	auipc	ra,0xffffe
    80005b9c:	318080e7          	jalr	792(ra) # 80003eb0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005ba0:	00092703          	lw	a4,0(s2)
    80005ba4:	409c                	lw	a5,0(s1)
    80005ba6:	04f71d63          	bne	a4,a5,80005c00 <sys_link+0x100>
    80005baa:	40d0                	lw	a2,4(s1)
    80005bac:	fd040593          	addi	a1,s0,-48
    80005bb0:	854a                	mv	a0,s2
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	9f2080e7          	jalr	-1550(ra) # 800045a4 <dirlink>
    80005bba:	04054363          	bltz	a0,80005c00 <sys_link+0x100>
  iunlockput(dp);
    80005bbe:	854a                	mv	a0,s2
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	552080e7          	jalr	1362(ra) # 80004112 <iunlockput>
  iput(ip);
    80005bc8:	8526                	mv	a0,s1
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	4a0080e7          	jalr	1184(ra) # 8000406a <iput>
  end_op();
    80005bd2:	fffff097          	auipc	ra,0xfffff
    80005bd6:	d30080e7          	jalr	-720(ra) # 80004902 <end_op>
  return 0;
    80005bda:	4781                	li	a5,0
    80005bdc:	a085                	j	80005c3c <sys_link+0x13c>
    end_op();
    80005bde:	fffff097          	auipc	ra,0xfffff
    80005be2:	d24080e7          	jalr	-732(ra) # 80004902 <end_op>
    return -1;
    80005be6:	57fd                	li	a5,-1
    80005be8:	a891                	j	80005c3c <sys_link+0x13c>
    iunlockput(ip);
    80005bea:	8526                	mv	a0,s1
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	526080e7          	jalr	1318(ra) # 80004112 <iunlockput>
    end_op();
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	d0e080e7          	jalr	-754(ra) # 80004902 <end_op>
    return -1;
    80005bfc:	57fd                	li	a5,-1
    80005bfe:	a83d                	j	80005c3c <sys_link+0x13c>
    iunlockput(dp);
    80005c00:	854a                	mv	a0,s2
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	510080e7          	jalr	1296(ra) # 80004112 <iunlockput>
  ilock(ip);
    80005c0a:	8526                	mv	a0,s1
    80005c0c:	ffffe097          	auipc	ra,0xffffe
    80005c10:	2a4080e7          	jalr	676(ra) # 80003eb0 <ilock>
  ip->nlink--;
    80005c14:	04a4d783          	lhu	a5,74(s1)
    80005c18:	37fd                	addiw	a5,a5,-1
    80005c1a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c1e:	8526                	mv	a0,s1
    80005c20:	ffffe097          	auipc	ra,0xffffe
    80005c24:	1c6080e7          	jalr	454(ra) # 80003de6 <iupdate>
  iunlockput(ip);
    80005c28:	8526                	mv	a0,s1
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	4e8080e7          	jalr	1256(ra) # 80004112 <iunlockput>
  end_op();
    80005c32:	fffff097          	auipc	ra,0xfffff
    80005c36:	cd0080e7          	jalr	-816(ra) # 80004902 <end_op>
  return -1;
    80005c3a:	57fd                	li	a5,-1
}
    80005c3c:	853e                	mv	a0,a5
    80005c3e:	70b2                	ld	ra,296(sp)
    80005c40:	7412                	ld	s0,288(sp)
    80005c42:	64f2                	ld	s1,280(sp)
    80005c44:	6952                	ld	s2,272(sp)
    80005c46:	6155                	addi	sp,sp,304
    80005c48:	8082                	ret

0000000080005c4a <sys_unlink>:
{
    80005c4a:	7151                	addi	sp,sp,-240
    80005c4c:	f586                	sd	ra,232(sp)
    80005c4e:	f1a2                	sd	s0,224(sp)
    80005c50:	eda6                	sd	s1,216(sp)
    80005c52:	e9ca                	sd	s2,208(sp)
    80005c54:	e5ce                	sd	s3,200(sp)
    80005c56:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005c58:	08000613          	li	a2,128
    80005c5c:	f3040593          	addi	a1,s0,-208
    80005c60:	4501                	li	a0,0
    80005c62:	ffffd097          	auipc	ra,0xffffd
    80005c66:	6a4080e7          	jalr	1700(ra) # 80003306 <argstr>
    80005c6a:	18054163          	bltz	a0,80005dec <sys_unlink+0x1a2>
  begin_op();
    80005c6e:	fffff097          	auipc	ra,0xfffff
    80005c72:	c14080e7          	jalr	-1004(ra) # 80004882 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005c76:	fb040593          	addi	a1,s0,-80
    80005c7a:	f3040513          	addi	a0,s0,-208
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	a06080e7          	jalr	-1530(ra) # 80004684 <nameiparent>
    80005c86:	84aa                	mv	s1,a0
    80005c88:	c979                	beqz	a0,80005d5e <sys_unlink+0x114>
  ilock(dp);
    80005c8a:	ffffe097          	auipc	ra,0xffffe
    80005c8e:	226080e7          	jalr	550(ra) # 80003eb0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005c92:	00003597          	auipc	a1,0x3
    80005c96:	cf658593          	addi	a1,a1,-778 # 80008988 <syscalls+0x2c8>
    80005c9a:	fb040513          	addi	a0,s0,-80
    80005c9e:	ffffe097          	auipc	ra,0xffffe
    80005ca2:	6dc080e7          	jalr	1756(ra) # 8000437a <namecmp>
    80005ca6:	14050a63          	beqz	a0,80005dfa <sys_unlink+0x1b0>
    80005caa:	00003597          	auipc	a1,0x3
    80005cae:	ce658593          	addi	a1,a1,-794 # 80008990 <syscalls+0x2d0>
    80005cb2:	fb040513          	addi	a0,s0,-80
    80005cb6:	ffffe097          	auipc	ra,0xffffe
    80005cba:	6c4080e7          	jalr	1732(ra) # 8000437a <namecmp>
    80005cbe:	12050e63          	beqz	a0,80005dfa <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005cc2:	f2c40613          	addi	a2,s0,-212
    80005cc6:	fb040593          	addi	a1,s0,-80
    80005cca:	8526                	mv	a0,s1
    80005ccc:	ffffe097          	auipc	ra,0xffffe
    80005cd0:	6c8080e7          	jalr	1736(ra) # 80004394 <dirlookup>
    80005cd4:	892a                	mv	s2,a0
    80005cd6:	12050263          	beqz	a0,80005dfa <sys_unlink+0x1b0>
  ilock(ip);
    80005cda:	ffffe097          	auipc	ra,0xffffe
    80005cde:	1d6080e7          	jalr	470(ra) # 80003eb0 <ilock>
  if(ip->nlink < 1)
    80005ce2:	04a91783          	lh	a5,74(s2)
    80005ce6:	08f05263          	blez	a5,80005d6a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005cea:	04491703          	lh	a4,68(s2)
    80005cee:	4785                	li	a5,1
    80005cf0:	08f70563          	beq	a4,a5,80005d7a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005cf4:	4641                	li	a2,16
    80005cf6:	4581                	li	a1,0
    80005cf8:	fc040513          	addi	a0,s0,-64
    80005cfc:	ffffb097          	auipc	ra,0xffffb
    80005d00:	fe4080e7          	jalr	-28(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d04:	4741                	li	a4,16
    80005d06:	f2c42683          	lw	a3,-212(s0)
    80005d0a:	fc040613          	addi	a2,s0,-64
    80005d0e:	4581                	li	a1,0
    80005d10:	8526                	mv	a0,s1
    80005d12:	ffffe097          	auipc	ra,0xffffe
    80005d16:	54a080e7          	jalr	1354(ra) # 8000425c <writei>
    80005d1a:	47c1                	li	a5,16
    80005d1c:	0af51563          	bne	a0,a5,80005dc6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005d20:	04491703          	lh	a4,68(s2)
    80005d24:	4785                	li	a5,1
    80005d26:	0af70863          	beq	a4,a5,80005dd6 <sys_unlink+0x18c>
  iunlockput(dp);
    80005d2a:	8526                	mv	a0,s1
    80005d2c:	ffffe097          	auipc	ra,0xffffe
    80005d30:	3e6080e7          	jalr	998(ra) # 80004112 <iunlockput>
  ip->nlink--;
    80005d34:	04a95783          	lhu	a5,74(s2)
    80005d38:	37fd                	addiw	a5,a5,-1
    80005d3a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005d3e:	854a                	mv	a0,s2
    80005d40:	ffffe097          	auipc	ra,0xffffe
    80005d44:	0a6080e7          	jalr	166(ra) # 80003de6 <iupdate>
  iunlockput(ip);
    80005d48:	854a                	mv	a0,s2
    80005d4a:	ffffe097          	auipc	ra,0xffffe
    80005d4e:	3c8080e7          	jalr	968(ra) # 80004112 <iunlockput>
  end_op();
    80005d52:	fffff097          	auipc	ra,0xfffff
    80005d56:	bb0080e7          	jalr	-1104(ra) # 80004902 <end_op>
  return 0;
    80005d5a:	4501                	li	a0,0
    80005d5c:	a84d                	j	80005e0e <sys_unlink+0x1c4>
    end_op();
    80005d5e:	fffff097          	auipc	ra,0xfffff
    80005d62:	ba4080e7          	jalr	-1116(ra) # 80004902 <end_op>
    return -1;
    80005d66:	557d                	li	a0,-1
    80005d68:	a05d                	j	80005e0e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005d6a:	00003517          	auipc	a0,0x3
    80005d6e:	c4e50513          	addi	a0,a0,-946 # 800089b8 <syscalls+0x2f8>
    80005d72:	ffffa097          	auipc	ra,0xffffa
    80005d76:	7cc080e7          	jalr	1996(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d7a:	04c92703          	lw	a4,76(s2)
    80005d7e:	02000793          	li	a5,32
    80005d82:	f6e7f9e3          	bgeu	a5,a4,80005cf4 <sys_unlink+0xaa>
    80005d86:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d8a:	4741                	li	a4,16
    80005d8c:	86ce                	mv	a3,s3
    80005d8e:	f1840613          	addi	a2,s0,-232
    80005d92:	4581                	li	a1,0
    80005d94:	854a                	mv	a0,s2
    80005d96:	ffffe097          	auipc	ra,0xffffe
    80005d9a:	3ce080e7          	jalr	974(ra) # 80004164 <readi>
    80005d9e:	47c1                	li	a5,16
    80005da0:	00f51b63          	bne	a0,a5,80005db6 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005da4:	f1845783          	lhu	a5,-232(s0)
    80005da8:	e7a1                	bnez	a5,80005df0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005daa:	29c1                	addiw	s3,s3,16
    80005dac:	04c92783          	lw	a5,76(s2)
    80005db0:	fcf9ede3          	bltu	s3,a5,80005d8a <sys_unlink+0x140>
    80005db4:	b781                	j	80005cf4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005db6:	00003517          	auipc	a0,0x3
    80005dba:	c1a50513          	addi	a0,a0,-998 # 800089d0 <syscalls+0x310>
    80005dbe:	ffffa097          	auipc	ra,0xffffa
    80005dc2:	780080e7          	jalr	1920(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005dc6:	00003517          	auipc	a0,0x3
    80005dca:	c2250513          	addi	a0,a0,-990 # 800089e8 <syscalls+0x328>
    80005dce:	ffffa097          	auipc	ra,0xffffa
    80005dd2:	770080e7          	jalr	1904(ra) # 8000053e <panic>
    dp->nlink--;
    80005dd6:	04a4d783          	lhu	a5,74(s1)
    80005dda:	37fd                	addiw	a5,a5,-1
    80005ddc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005de0:	8526                	mv	a0,s1
    80005de2:	ffffe097          	auipc	ra,0xffffe
    80005de6:	004080e7          	jalr	4(ra) # 80003de6 <iupdate>
    80005dea:	b781                	j	80005d2a <sys_unlink+0xe0>
    return -1;
    80005dec:	557d                	li	a0,-1
    80005dee:	a005                	j	80005e0e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005df0:	854a                	mv	a0,s2
    80005df2:	ffffe097          	auipc	ra,0xffffe
    80005df6:	320080e7          	jalr	800(ra) # 80004112 <iunlockput>
  iunlockput(dp);
    80005dfa:	8526                	mv	a0,s1
    80005dfc:	ffffe097          	auipc	ra,0xffffe
    80005e00:	316080e7          	jalr	790(ra) # 80004112 <iunlockput>
  end_op();
    80005e04:	fffff097          	auipc	ra,0xfffff
    80005e08:	afe080e7          	jalr	-1282(ra) # 80004902 <end_op>
  return -1;
    80005e0c:	557d                	li	a0,-1
}
    80005e0e:	70ae                	ld	ra,232(sp)
    80005e10:	740e                	ld	s0,224(sp)
    80005e12:	64ee                	ld	s1,216(sp)
    80005e14:	694e                	ld	s2,208(sp)
    80005e16:	69ae                	ld	s3,200(sp)
    80005e18:	616d                	addi	sp,sp,240
    80005e1a:	8082                	ret

0000000080005e1c <sys_open>:

uint64
sys_open(void)
{
    80005e1c:	7131                	addi	sp,sp,-192
    80005e1e:	fd06                	sd	ra,184(sp)
    80005e20:	f922                	sd	s0,176(sp)
    80005e22:	f526                	sd	s1,168(sp)
    80005e24:	f14a                	sd	s2,160(sp)
    80005e26:	ed4e                	sd	s3,152(sp)
    80005e28:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005e2a:	08000613          	li	a2,128
    80005e2e:	f5040593          	addi	a1,s0,-176
    80005e32:	4501                	li	a0,0
    80005e34:	ffffd097          	auipc	ra,0xffffd
    80005e38:	4d2080e7          	jalr	1234(ra) # 80003306 <argstr>
    return -1;
    80005e3c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005e3e:	0c054163          	bltz	a0,80005f00 <sys_open+0xe4>
    80005e42:	f4c40593          	addi	a1,s0,-180
    80005e46:	4505                	li	a0,1
    80005e48:	ffffd097          	auipc	ra,0xffffd
    80005e4c:	47a080e7          	jalr	1146(ra) # 800032c2 <argint>
    80005e50:	0a054863          	bltz	a0,80005f00 <sys_open+0xe4>

  begin_op();
    80005e54:	fffff097          	auipc	ra,0xfffff
    80005e58:	a2e080e7          	jalr	-1490(ra) # 80004882 <begin_op>

  if(omode & O_CREATE){
    80005e5c:	f4c42783          	lw	a5,-180(s0)
    80005e60:	2007f793          	andi	a5,a5,512
    80005e64:	cbdd                	beqz	a5,80005f1a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005e66:	4681                	li	a3,0
    80005e68:	4601                	li	a2,0
    80005e6a:	4589                	li	a1,2
    80005e6c:	f5040513          	addi	a0,s0,-176
    80005e70:	00000097          	auipc	ra,0x0
    80005e74:	972080e7          	jalr	-1678(ra) # 800057e2 <create>
    80005e78:	892a                	mv	s2,a0
    if(ip == 0){
    80005e7a:	c959                	beqz	a0,80005f10 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e7c:	04491703          	lh	a4,68(s2)
    80005e80:	478d                	li	a5,3
    80005e82:	00f71763          	bne	a4,a5,80005e90 <sys_open+0x74>
    80005e86:	04695703          	lhu	a4,70(s2)
    80005e8a:	47a5                	li	a5,9
    80005e8c:	0ce7ec63          	bltu	a5,a4,80005f64 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005e90:	fffff097          	auipc	ra,0xfffff
    80005e94:	e02080e7          	jalr	-510(ra) # 80004c92 <filealloc>
    80005e98:	89aa                	mv	s3,a0
    80005e9a:	10050263          	beqz	a0,80005f9e <sys_open+0x182>
    80005e9e:	00000097          	auipc	ra,0x0
    80005ea2:	902080e7          	jalr	-1790(ra) # 800057a0 <fdalloc>
    80005ea6:	84aa                	mv	s1,a0
    80005ea8:	0e054663          	bltz	a0,80005f94 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005eac:	04491703          	lh	a4,68(s2)
    80005eb0:	478d                	li	a5,3
    80005eb2:	0cf70463          	beq	a4,a5,80005f7a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005eb6:	4789                	li	a5,2
    80005eb8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ebc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ec0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ec4:	f4c42783          	lw	a5,-180(s0)
    80005ec8:	0017c713          	xori	a4,a5,1
    80005ecc:	8b05                	andi	a4,a4,1
    80005ece:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ed2:	0037f713          	andi	a4,a5,3
    80005ed6:	00e03733          	snez	a4,a4
    80005eda:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ede:	4007f793          	andi	a5,a5,1024
    80005ee2:	c791                	beqz	a5,80005eee <sys_open+0xd2>
    80005ee4:	04491703          	lh	a4,68(s2)
    80005ee8:	4789                	li	a5,2
    80005eea:	08f70f63          	beq	a4,a5,80005f88 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005eee:	854a                	mv	a0,s2
    80005ef0:	ffffe097          	auipc	ra,0xffffe
    80005ef4:	082080e7          	jalr	130(ra) # 80003f72 <iunlock>
  end_op();
    80005ef8:	fffff097          	auipc	ra,0xfffff
    80005efc:	a0a080e7          	jalr	-1526(ra) # 80004902 <end_op>

  return fd;
}
    80005f00:	8526                	mv	a0,s1
    80005f02:	70ea                	ld	ra,184(sp)
    80005f04:	744a                	ld	s0,176(sp)
    80005f06:	74aa                	ld	s1,168(sp)
    80005f08:	790a                	ld	s2,160(sp)
    80005f0a:	69ea                	ld	s3,152(sp)
    80005f0c:	6129                	addi	sp,sp,192
    80005f0e:	8082                	ret
      end_op();
    80005f10:	fffff097          	auipc	ra,0xfffff
    80005f14:	9f2080e7          	jalr	-1550(ra) # 80004902 <end_op>
      return -1;
    80005f18:	b7e5                	j	80005f00 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005f1a:	f5040513          	addi	a0,s0,-176
    80005f1e:	ffffe097          	auipc	ra,0xffffe
    80005f22:	748080e7          	jalr	1864(ra) # 80004666 <namei>
    80005f26:	892a                	mv	s2,a0
    80005f28:	c905                	beqz	a0,80005f58 <sys_open+0x13c>
    ilock(ip);
    80005f2a:	ffffe097          	auipc	ra,0xffffe
    80005f2e:	f86080e7          	jalr	-122(ra) # 80003eb0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005f32:	04491703          	lh	a4,68(s2)
    80005f36:	4785                	li	a5,1
    80005f38:	f4f712e3          	bne	a4,a5,80005e7c <sys_open+0x60>
    80005f3c:	f4c42783          	lw	a5,-180(s0)
    80005f40:	dba1                	beqz	a5,80005e90 <sys_open+0x74>
      iunlockput(ip);
    80005f42:	854a                	mv	a0,s2
    80005f44:	ffffe097          	auipc	ra,0xffffe
    80005f48:	1ce080e7          	jalr	462(ra) # 80004112 <iunlockput>
      end_op();
    80005f4c:	fffff097          	auipc	ra,0xfffff
    80005f50:	9b6080e7          	jalr	-1610(ra) # 80004902 <end_op>
      return -1;
    80005f54:	54fd                	li	s1,-1
    80005f56:	b76d                	j	80005f00 <sys_open+0xe4>
      end_op();
    80005f58:	fffff097          	auipc	ra,0xfffff
    80005f5c:	9aa080e7          	jalr	-1622(ra) # 80004902 <end_op>
      return -1;
    80005f60:	54fd                	li	s1,-1
    80005f62:	bf79                	j	80005f00 <sys_open+0xe4>
    iunlockput(ip);
    80005f64:	854a                	mv	a0,s2
    80005f66:	ffffe097          	auipc	ra,0xffffe
    80005f6a:	1ac080e7          	jalr	428(ra) # 80004112 <iunlockput>
    end_op();
    80005f6e:	fffff097          	auipc	ra,0xfffff
    80005f72:	994080e7          	jalr	-1644(ra) # 80004902 <end_op>
    return -1;
    80005f76:	54fd                	li	s1,-1
    80005f78:	b761                	j	80005f00 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005f7a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005f7e:	04691783          	lh	a5,70(s2)
    80005f82:	02f99223          	sh	a5,36(s3)
    80005f86:	bf2d                	j	80005ec0 <sys_open+0xa4>
    itrunc(ip);
    80005f88:	854a                	mv	a0,s2
    80005f8a:	ffffe097          	auipc	ra,0xffffe
    80005f8e:	034080e7          	jalr	52(ra) # 80003fbe <itrunc>
    80005f92:	bfb1                	j	80005eee <sys_open+0xd2>
      fileclose(f);
    80005f94:	854e                	mv	a0,s3
    80005f96:	fffff097          	auipc	ra,0xfffff
    80005f9a:	db8080e7          	jalr	-584(ra) # 80004d4e <fileclose>
    iunlockput(ip);
    80005f9e:	854a                	mv	a0,s2
    80005fa0:	ffffe097          	auipc	ra,0xffffe
    80005fa4:	172080e7          	jalr	370(ra) # 80004112 <iunlockput>
    end_op();
    80005fa8:	fffff097          	auipc	ra,0xfffff
    80005fac:	95a080e7          	jalr	-1702(ra) # 80004902 <end_op>
    return -1;
    80005fb0:	54fd                	li	s1,-1
    80005fb2:	b7b9                	j	80005f00 <sys_open+0xe4>

0000000080005fb4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005fb4:	7175                	addi	sp,sp,-144
    80005fb6:	e506                	sd	ra,136(sp)
    80005fb8:	e122                	sd	s0,128(sp)
    80005fba:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005fbc:	fffff097          	auipc	ra,0xfffff
    80005fc0:	8c6080e7          	jalr	-1850(ra) # 80004882 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005fc4:	08000613          	li	a2,128
    80005fc8:	f7040593          	addi	a1,s0,-144
    80005fcc:	4501                	li	a0,0
    80005fce:	ffffd097          	auipc	ra,0xffffd
    80005fd2:	338080e7          	jalr	824(ra) # 80003306 <argstr>
    80005fd6:	02054963          	bltz	a0,80006008 <sys_mkdir+0x54>
    80005fda:	4681                	li	a3,0
    80005fdc:	4601                	li	a2,0
    80005fde:	4585                	li	a1,1
    80005fe0:	f7040513          	addi	a0,s0,-144
    80005fe4:	fffff097          	auipc	ra,0xfffff
    80005fe8:	7fe080e7          	jalr	2046(ra) # 800057e2 <create>
    80005fec:	cd11                	beqz	a0,80006008 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fee:	ffffe097          	auipc	ra,0xffffe
    80005ff2:	124080e7          	jalr	292(ra) # 80004112 <iunlockput>
  end_op();
    80005ff6:	fffff097          	auipc	ra,0xfffff
    80005ffa:	90c080e7          	jalr	-1780(ra) # 80004902 <end_op>
  return 0;
    80005ffe:	4501                	li	a0,0
}
    80006000:	60aa                	ld	ra,136(sp)
    80006002:	640a                	ld	s0,128(sp)
    80006004:	6149                	addi	sp,sp,144
    80006006:	8082                	ret
    end_op();
    80006008:	fffff097          	auipc	ra,0xfffff
    8000600c:	8fa080e7          	jalr	-1798(ra) # 80004902 <end_op>
    return -1;
    80006010:	557d                	li	a0,-1
    80006012:	b7fd                	j	80006000 <sys_mkdir+0x4c>

0000000080006014 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006014:	7135                	addi	sp,sp,-160
    80006016:	ed06                	sd	ra,152(sp)
    80006018:	e922                	sd	s0,144(sp)
    8000601a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000601c:	fffff097          	auipc	ra,0xfffff
    80006020:	866080e7          	jalr	-1946(ra) # 80004882 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006024:	08000613          	li	a2,128
    80006028:	f7040593          	addi	a1,s0,-144
    8000602c:	4501                	li	a0,0
    8000602e:	ffffd097          	auipc	ra,0xffffd
    80006032:	2d8080e7          	jalr	728(ra) # 80003306 <argstr>
    80006036:	04054a63          	bltz	a0,8000608a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000603a:	f6c40593          	addi	a1,s0,-148
    8000603e:	4505                	li	a0,1
    80006040:	ffffd097          	auipc	ra,0xffffd
    80006044:	282080e7          	jalr	642(ra) # 800032c2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006048:	04054163          	bltz	a0,8000608a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000604c:	f6840593          	addi	a1,s0,-152
    80006050:	4509                	li	a0,2
    80006052:	ffffd097          	auipc	ra,0xffffd
    80006056:	270080e7          	jalr	624(ra) # 800032c2 <argint>
     argint(1, &major) < 0 ||
    8000605a:	02054863          	bltz	a0,8000608a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000605e:	f6841683          	lh	a3,-152(s0)
    80006062:	f6c41603          	lh	a2,-148(s0)
    80006066:	458d                	li	a1,3
    80006068:	f7040513          	addi	a0,s0,-144
    8000606c:	fffff097          	auipc	ra,0xfffff
    80006070:	776080e7          	jalr	1910(ra) # 800057e2 <create>
     argint(2, &minor) < 0 ||
    80006074:	c919                	beqz	a0,8000608a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006076:	ffffe097          	auipc	ra,0xffffe
    8000607a:	09c080e7          	jalr	156(ra) # 80004112 <iunlockput>
  end_op();
    8000607e:	fffff097          	auipc	ra,0xfffff
    80006082:	884080e7          	jalr	-1916(ra) # 80004902 <end_op>
  return 0;
    80006086:	4501                	li	a0,0
    80006088:	a031                	j	80006094 <sys_mknod+0x80>
    end_op();
    8000608a:	fffff097          	auipc	ra,0xfffff
    8000608e:	878080e7          	jalr	-1928(ra) # 80004902 <end_op>
    return -1;
    80006092:	557d                	li	a0,-1
}
    80006094:	60ea                	ld	ra,152(sp)
    80006096:	644a                	ld	s0,144(sp)
    80006098:	610d                	addi	sp,sp,160
    8000609a:	8082                	ret

000000008000609c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000609c:	7135                	addi	sp,sp,-160
    8000609e:	ed06                	sd	ra,152(sp)
    800060a0:	e922                	sd	s0,144(sp)
    800060a2:	e526                	sd	s1,136(sp)
    800060a4:	e14a                	sd	s2,128(sp)
    800060a6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800060a8:	ffffc097          	auipc	ra,0xffffc
    800060ac:	d64080e7          	jalr	-668(ra) # 80001e0c <myproc>
    800060b0:	892a                	mv	s2,a0
  
  begin_op();
    800060b2:	ffffe097          	auipc	ra,0xffffe
    800060b6:	7d0080e7          	jalr	2000(ra) # 80004882 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800060ba:	08000613          	li	a2,128
    800060be:	f6040593          	addi	a1,s0,-160
    800060c2:	4501                	li	a0,0
    800060c4:	ffffd097          	auipc	ra,0xffffd
    800060c8:	242080e7          	jalr	578(ra) # 80003306 <argstr>
    800060cc:	04054b63          	bltz	a0,80006122 <sys_chdir+0x86>
    800060d0:	f6040513          	addi	a0,s0,-160
    800060d4:	ffffe097          	auipc	ra,0xffffe
    800060d8:	592080e7          	jalr	1426(ra) # 80004666 <namei>
    800060dc:	84aa                	mv	s1,a0
    800060de:	c131                	beqz	a0,80006122 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800060e0:	ffffe097          	auipc	ra,0xffffe
    800060e4:	dd0080e7          	jalr	-560(ra) # 80003eb0 <ilock>
  if(ip->type != T_DIR){
    800060e8:	04449703          	lh	a4,68(s1)
    800060ec:	4785                	li	a5,1
    800060ee:	04f71063          	bne	a4,a5,8000612e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800060f2:	8526                	mv	a0,s1
    800060f4:	ffffe097          	auipc	ra,0xffffe
    800060f8:	e7e080e7          	jalr	-386(ra) # 80003f72 <iunlock>
  iput(p->cwd);
    800060fc:	15093503          	ld	a0,336(s2)
    80006100:	ffffe097          	auipc	ra,0xffffe
    80006104:	f6a080e7          	jalr	-150(ra) # 8000406a <iput>
  end_op();
    80006108:	ffffe097          	auipc	ra,0xffffe
    8000610c:	7fa080e7          	jalr	2042(ra) # 80004902 <end_op>
  p->cwd = ip;
    80006110:	14993823          	sd	s1,336(s2)
  return 0;
    80006114:	4501                	li	a0,0
}
    80006116:	60ea                	ld	ra,152(sp)
    80006118:	644a                	ld	s0,144(sp)
    8000611a:	64aa                	ld	s1,136(sp)
    8000611c:	690a                	ld	s2,128(sp)
    8000611e:	610d                	addi	sp,sp,160
    80006120:	8082                	ret
    end_op();
    80006122:	ffffe097          	auipc	ra,0xffffe
    80006126:	7e0080e7          	jalr	2016(ra) # 80004902 <end_op>
    return -1;
    8000612a:	557d                	li	a0,-1
    8000612c:	b7ed                	j	80006116 <sys_chdir+0x7a>
    iunlockput(ip);
    8000612e:	8526                	mv	a0,s1
    80006130:	ffffe097          	auipc	ra,0xffffe
    80006134:	fe2080e7          	jalr	-30(ra) # 80004112 <iunlockput>
    end_op();
    80006138:	ffffe097          	auipc	ra,0xffffe
    8000613c:	7ca080e7          	jalr	1994(ra) # 80004902 <end_op>
    return -1;
    80006140:	557d                	li	a0,-1
    80006142:	bfd1                	j	80006116 <sys_chdir+0x7a>

0000000080006144 <sys_exec>:

uint64
sys_exec(void)
{
    80006144:	7145                	addi	sp,sp,-464
    80006146:	e786                	sd	ra,456(sp)
    80006148:	e3a2                	sd	s0,448(sp)
    8000614a:	ff26                	sd	s1,440(sp)
    8000614c:	fb4a                	sd	s2,432(sp)
    8000614e:	f74e                	sd	s3,424(sp)
    80006150:	f352                	sd	s4,416(sp)
    80006152:	ef56                	sd	s5,408(sp)
    80006154:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006156:	08000613          	li	a2,128
    8000615a:	f4040593          	addi	a1,s0,-192
    8000615e:	4501                	li	a0,0
    80006160:	ffffd097          	auipc	ra,0xffffd
    80006164:	1a6080e7          	jalr	422(ra) # 80003306 <argstr>
    return -1;
    80006168:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000616a:	0c054a63          	bltz	a0,8000623e <sys_exec+0xfa>
    8000616e:	e3840593          	addi	a1,s0,-456
    80006172:	4505                	li	a0,1
    80006174:	ffffd097          	auipc	ra,0xffffd
    80006178:	170080e7          	jalr	368(ra) # 800032e4 <argaddr>
    8000617c:	0c054163          	bltz	a0,8000623e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006180:	10000613          	li	a2,256
    80006184:	4581                	li	a1,0
    80006186:	e4040513          	addi	a0,s0,-448
    8000618a:	ffffb097          	auipc	ra,0xffffb
    8000618e:	b56080e7          	jalr	-1194(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006192:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006196:	89a6                	mv	s3,s1
    80006198:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000619a:	02000a13          	li	s4,32
    8000619e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800061a2:	00391513          	slli	a0,s2,0x3
    800061a6:	e3040593          	addi	a1,s0,-464
    800061aa:	e3843783          	ld	a5,-456(s0)
    800061ae:	953e                	add	a0,a0,a5
    800061b0:	ffffd097          	auipc	ra,0xffffd
    800061b4:	078080e7          	jalr	120(ra) # 80003228 <fetchaddr>
    800061b8:	02054a63          	bltz	a0,800061ec <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800061bc:	e3043783          	ld	a5,-464(s0)
    800061c0:	c3b9                	beqz	a5,80006206 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800061c2:	ffffb097          	auipc	ra,0xffffb
    800061c6:	932080e7          	jalr	-1742(ra) # 80000af4 <kalloc>
    800061ca:	85aa                	mv	a1,a0
    800061cc:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800061d0:	cd11                	beqz	a0,800061ec <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800061d2:	6605                	lui	a2,0x1
    800061d4:	e3043503          	ld	a0,-464(s0)
    800061d8:	ffffd097          	auipc	ra,0xffffd
    800061dc:	0a2080e7          	jalr	162(ra) # 8000327a <fetchstr>
    800061e0:	00054663          	bltz	a0,800061ec <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800061e4:	0905                	addi	s2,s2,1
    800061e6:	09a1                	addi	s3,s3,8
    800061e8:	fb491be3          	bne	s2,s4,8000619e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061ec:	10048913          	addi	s2,s1,256
    800061f0:	6088                	ld	a0,0(s1)
    800061f2:	c529                	beqz	a0,8000623c <sys_exec+0xf8>
    kfree(argv[i]);
    800061f4:	ffffb097          	auipc	ra,0xffffb
    800061f8:	804080e7          	jalr	-2044(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061fc:	04a1                	addi	s1,s1,8
    800061fe:	ff2499e3          	bne	s1,s2,800061f0 <sys_exec+0xac>
  return -1;
    80006202:	597d                	li	s2,-1
    80006204:	a82d                	j	8000623e <sys_exec+0xfa>
      argv[i] = 0;
    80006206:	0a8e                	slli	s5,s5,0x3
    80006208:	fc040793          	addi	a5,s0,-64
    8000620c:	9abe                	add	s5,s5,a5
    8000620e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006212:	e4040593          	addi	a1,s0,-448
    80006216:	f4040513          	addi	a0,s0,-192
    8000621a:	fffff097          	auipc	ra,0xfffff
    8000621e:	194080e7          	jalr	404(ra) # 800053ae <exec>
    80006222:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006224:	10048993          	addi	s3,s1,256
    80006228:	6088                	ld	a0,0(s1)
    8000622a:	c911                	beqz	a0,8000623e <sys_exec+0xfa>
    kfree(argv[i]);
    8000622c:	ffffa097          	auipc	ra,0xffffa
    80006230:	7cc080e7          	jalr	1996(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006234:	04a1                	addi	s1,s1,8
    80006236:	ff3499e3          	bne	s1,s3,80006228 <sys_exec+0xe4>
    8000623a:	a011                	j	8000623e <sys_exec+0xfa>
  return -1;
    8000623c:	597d                	li	s2,-1
}
    8000623e:	854a                	mv	a0,s2
    80006240:	60be                	ld	ra,456(sp)
    80006242:	641e                	ld	s0,448(sp)
    80006244:	74fa                	ld	s1,440(sp)
    80006246:	795a                	ld	s2,432(sp)
    80006248:	79ba                	ld	s3,424(sp)
    8000624a:	7a1a                	ld	s4,416(sp)
    8000624c:	6afa                	ld	s5,408(sp)
    8000624e:	6179                	addi	sp,sp,464
    80006250:	8082                	ret

0000000080006252 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006252:	7139                	addi	sp,sp,-64
    80006254:	fc06                	sd	ra,56(sp)
    80006256:	f822                	sd	s0,48(sp)
    80006258:	f426                	sd	s1,40(sp)
    8000625a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000625c:	ffffc097          	auipc	ra,0xffffc
    80006260:	bb0080e7          	jalr	-1104(ra) # 80001e0c <myproc>
    80006264:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006266:	fd840593          	addi	a1,s0,-40
    8000626a:	4501                	li	a0,0
    8000626c:	ffffd097          	auipc	ra,0xffffd
    80006270:	078080e7          	jalr	120(ra) # 800032e4 <argaddr>
    return -1;
    80006274:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006276:	0e054063          	bltz	a0,80006356 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000627a:	fc840593          	addi	a1,s0,-56
    8000627e:	fd040513          	addi	a0,s0,-48
    80006282:	fffff097          	auipc	ra,0xfffff
    80006286:	dfc080e7          	jalr	-516(ra) # 8000507e <pipealloc>
    return -1;
    8000628a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000628c:	0c054563          	bltz	a0,80006356 <sys_pipe+0x104>
  fd0 = -1;
    80006290:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006294:	fd043503          	ld	a0,-48(s0)
    80006298:	fffff097          	auipc	ra,0xfffff
    8000629c:	508080e7          	jalr	1288(ra) # 800057a0 <fdalloc>
    800062a0:	fca42223          	sw	a0,-60(s0)
    800062a4:	08054c63          	bltz	a0,8000633c <sys_pipe+0xea>
    800062a8:	fc843503          	ld	a0,-56(s0)
    800062ac:	fffff097          	auipc	ra,0xfffff
    800062b0:	4f4080e7          	jalr	1268(ra) # 800057a0 <fdalloc>
    800062b4:	fca42023          	sw	a0,-64(s0)
    800062b8:	06054863          	bltz	a0,80006328 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800062bc:	4691                	li	a3,4
    800062be:	fc440613          	addi	a2,s0,-60
    800062c2:	fd843583          	ld	a1,-40(s0)
    800062c6:	68a8                	ld	a0,80(s1)
    800062c8:	ffffb097          	auipc	ra,0xffffb
    800062cc:	3aa080e7          	jalr	938(ra) # 80001672 <copyout>
    800062d0:	02054063          	bltz	a0,800062f0 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800062d4:	4691                	li	a3,4
    800062d6:	fc040613          	addi	a2,s0,-64
    800062da:	fd843583          	ld	a1,-40(s0)
    800062de:	0591                	addi	a1,a1,4
    800062e0:	68a8                	ld	a0,80(s1)
    800062e2:	ffffb097          	auipc	ra,0xffffb
    800062e6:	390080e7          	jalr	912(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800062ea:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800062ec:	06055563          	bgez	a0,80006356 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800062f0:	fc442783          	lw	a5,-60(s0)
    800062f4:	07e9                	addi	a5,a5,26
    800062f6:	078e                	slli	a5,a5,0x3
    800062f8:	97a6                	add	a5,a5,s1
    800062fa:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800062fe:	fc042503          	lw	a0,-64(s0)
    80006302:	0569                	addi	a0,a0,26
    80006304:	050e                	slli	a0,a0,0x3
    80006306:	9526                	add	a0,a0,s1
    80006308:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000630c:	fd043503          	ld	a0,-48(s0)
    80006310:	fffff097          	auipc	ra,0xfffff
    80006314:	a3e080e7          	jalr	-1474(ra) # 80004d4e <fileclose>
    fileclose(wf);
    80006318:	fc843503          	ld	a0,-56(s0)
    8000631c:	fffff097          	auipc	ra,0xfffff
    80006320:	a32080e7          	jalr	-1486(ra) # 80004d4e <fileclose>
    return -1;
    80006324:	57fd                	li	a5,-1
    80006326:	a805                	j	80006356 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006328:	fc442783          	lw	a5,-60(s0)
    8000632c:	0007c863          	bltz	a5,8000633c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006330:	01a78513          	addi	a0,a5,26
    80006334:	050e                	slli	a0,a0,0x3
    80006336:	9526                	add	a0,a0,s1
    80006338:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000633c:	fd043503          	ld	a0,-48(s0)
    80006340:	fffff097          	auipc	ra,0xfffff
    80006344:	a0e080e7          	jalr	-1522(ra) # 80004d4e <fileclose>
    fileclose(wf);
    80006348:	fc843503          	ld	a0,-56(s0)
    8000634c:	fffff097          	auipc	ra,0xfffff
    80006350:	a02080e7          	jalr	-1534(ra) # 80004d4e <fileclose>
    return -1;
    80006354:	57fd                	li	a5,-1
}
    80006356:	853e                	mv	a0,a5
    80006358:	70e2                	ld	ra,56(sp)
    8000635a:	7442                	ld	s0,48(sp)
    8000635c:	74a2                	ld	s1,40(sp)
    8000635e:	6121                	addi	sp,sp,64
    80006360:	8082                	ret
	...

0000000080006370 <kernelvec>:
    80006370:	7111                	addi	sp,sp,-256
    80006372:	e006                	sd	ra,0(sp)
    80006374:	e40a                	sd	sp,8(sp)
    80006376:	e80e                	sd	gp,16(sp)
    80006378:	ec12                	sd	tp,24(sp)
    8000637a:	f016                	sd	t0,32(sp)
    8000637c:	f41a                	sd	t1,40(sp)
    8000637e:	f81e                	sd	t2,48(sp)
    80006380:	fc22                	sd	s0,56(sp)
    80006382:	e0a6                	sd	s1,64(sp)
    80006384:	e4aa                	sd	a0,72(sp)
    80006386:	e8ae                	sd	a1,80(sp)
    80006388:	ecb2                	sd	a2,88(sp)
    8000638a:	f0b6                	sd	a3,96(sp)
    8000638c:	f4ba                	sd	a4,104(sp)
    8000638e:	f8be                	sd	a5,112(sp)
    80006390:	fcc2                	sd	a6,120(sp)
    80006392:	e146                	sd	a7,128(sp)
    80006394:	e54a                	sd	s2,136(sp)
    80006396:	e94e                	sd	s3,144(sp)
    80006398:	ed52                	sd	s4,152(sp)
    8000639a:	f156                	sd	s5,160(sp)
    8000639c:	f55a                	sd	s6,168(sp)
    8000639e:	f95e                	sd	s7,176(sp)
    800063a0:	fd62                	sd	s8,184(sp)
    800063a2:	e1e6                	sd	s9,192(sp)
    800063a4:	e5ea                	sd	s10,200(sp)
    800063a6:	e9ee                	sd	s11,208(sp)
    800063a8:	edf2                	sd	t3,216(sp)
    800063aa:	f1f6                	sd	t4,224(sp)
    800063ac:	f5fa                	sd	t5,232(sp)
    800063ae:	f9fe                	sd	t6,240(sp)
    800063b0:	d45fc0ef          	jal	ra,800030f4 <kerneltrap>
    800063b4:	6082                	ld	ra,0(sp)
    800063b6:	6122                	ld	sp,8(sp)
    800063b8:	61c2                	ld	gp,16(sp)
    800063ba:	7282                	ld	t0,32(sp)
    800063bc:	7322                	ld	t1,40(sp)
    800063be:	73c2                	ld	t2,48(sp)
    800063c0:	7462                	ld	s0,56(sp)
    800063c2:	6486                	ld	s1,64(sp)
    800063c4:	6526                	ld	a0,72(sp)
    800063c6:	65c6                	ld	a1,80(sp)
    800063c8:	6666                	ld	a2,88(sp)
    800063ca:	7686                	ld	a3,96(sp)
    800063cc:	7726                	ld	a4,104(sp)
    800063ce:	77c6                	ld	a5,112(sp)
    800063d0:	7866                	ld	a6,120(sp)
    800063d2:	688a                	ld	a7,128(sp)
    800063d4:	692a                	ld	s2,136(sp)
    800063d6:	69ca                	ld	s3,144(sp)
    800063d8:	6a6a                	ld	s4,152(sp)
    800063da:	7a8a                	ld	s5,160(sp)
    800063dc:	7b2a                	ld	s6,168(sp)
    800063de:	7bca                	ld	s7,176(sp)
    800063e0:	7c6a                	ld	s8,184(sp)
    800063e2:	6c8e                	ld	s9,192(sp)
    800063e4:	6d2e                	ld	s10,200(sp)
    800063e6:	6dce                	ld	s11,208(sp)
    800063e8:	6e6e                	ld	t3,216(sp)
    800063ea:	7e8e                	ld	t4,224(sp)
    800063ec:	7f2e                	ld	t5,232(sp)
    800063ee:	7fce                	ld	t6,240(sp)
    800063f0:	6111                	addi	sp,sp,256
    800063f2:	10200073          	sret
    800063f6:	00000013          	nop
    800063fa:	00000013          	nop
    800063fe:	0001                	nop

0000000080006400 <timervec>:
    80006400:	34051573          	csrrw	a0,mscratch,a0
    80006404:	e10c                	sd	a1,0(a0)
    80006406:	e510                	sd	a2,8(a0)
    80006408:	e914                	sd	a3,16(a0)
    8000640a:	6d0c                	ld	a1,24(a0)
    8000640c:	7110                	ld	a2,32(a0)
    8000640e:	6194                	ld	a3,0(a1)
    80006410:	96b2                	add	a3,a3,a2
    80006412:	e194                	sd	a3,0(a1)
    80006414:	4589                	li	a1,2
    80006416:	14459073          	csrw	sip,a1
    8000641a:	6914                	ld	a3,16(a0)
    8000641c:	6510                	ld	a2,8(a0)
    8000641e:	610c                	ld	a1,0(a0)
    80006420:	34051573          	csrrw	a0,mscratch,a0
    80006424:	30200073          	mret
	...

000000008000642a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000642a:	1141                	addi	sp,sp,-16
    8000642c:	e422                	sd	s0,8(sp)
    8000642e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006430:	0c0007b7          	lui	a5,0xc000
    80006434:	4705                	li	a4,1
    80006436:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006438:	c3d8                	sw	a4,4(a5)
}
    8000643a:	6422                	ld	s0,8(sp)
    8000643c:	0141                	addi	sp,sp,16
    8000643e:	8082                	ret

0000000080006440 <plicinithart>:

void
plicinithart(void)
{
    80006440:	1141                	addi	sp,sp,-16
    80006442:	e406                	sd	ra,8(sp)
    80006444:	e022                	sd	s0,0(sp)
    80006446:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006448:	ffffc097          	auipc	ra,0xffffc
    8000644c:	992080e7          	jalr	-1646(ra) # 80001dda <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006450:	0085171b          	slliw	a4,a0,0x8
    80006454:	0c0027b7          	lui	a5,0xc002
    80006458:	97ba                	add	a5,a5,a4
    8000645a:	40200713          	li	a4,1026
    8000645e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006462:	00d5151b          	slliw	a0,a0,0xd
    80006466:	0c2017b7          	lui	a5,0xc201
    8000646a:	953e                	add	a0,a0,a5
    8000646c:	00052023          	sw	zero,0(a0)
}
    80006470:	60a2                	ld	ra,8(sp)
    80006472:	6402                	ld	s0,0(sp)
    80006474:	0141                	addi	sp,sp,16
    80006476:	8082                	ret

0000000080006478 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006478:	1141                	addi	sp,sp,-16
    8000647a:	e406                	sd	ra,8(sp)
    8000647c:	e022                	sd	s0,0(sp)
    8000647e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006480:	ffffc097          	auipc	ra,0xffffc
    80006484:	95a080e7          	jalr	-1702(ra) # 80001dda <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006488:	00d5179b          	slliw	a5,a0,0xd
    8000648c:	0c201537          	lui	a0,0xc201
    80006490:	953e                	add	a0,a0,a5
  return irq;
}
    80006492:	4148                	lw	a0,4(a0)
    80006494:	60a2                	ld	ra,8(sp)
    80006496:	6402                	ld	s0,0(sp)
    80006498:	0141                	addi	sp,sp,16
    8000649a:	8082                	ret

000000008000649c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000649c:	1101                	addi	sp,sp,-32
    8000649e:	ec06                	sd	ra,24(sp)
    800064a0:	e822                	sd	s0,16(sp)
    800064a2:	e426                	sd	s1,8(sp)
    800064a4:	1000                	addi	s0,sp,32
    800064a6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800064a8:	ffffc097          	auipc	ra,0xffffc
    800064ac:	932080e7          	jalr	-1742(ra) # 80001dda <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800064b0:	00d5151b          	slliw	a0,a0,0xd
    800064b4:	0c2017b7          	lui	a5,0xc201
    800064b8:	97aa                	add	a5,a5,a0
    800064ba:	c3c4                	sw	s1,4(a5)
}
    800064bc:	60e2                	ld	ra,24(sp)
    800064be:	6442                	ld	s0,16(sp)
    800064c0:	64a2                	ld	s1,8(sp)
    800064c2:	6105                	addi	sp,sp,32
    800064c4:	8082                	ret

00000000800064c6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800064c6:	1141                	addi	sp,sp,-16
    800064c8:	e406                	sd	ra,8(sp)
    800064ca:	e022                	sd	s0,0(sp)
    800064cc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800064ce:	479d                	li	a5,7
    800064d0:	06a7c963          	blt	a5,a0,80006542 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800064d4:	0001d797          	auipc	a5,0x1d
    800064d8:	b2c78793          	addi	a5,a5,-1236 # 80023000 <disk>
    800064dc:	00a78733          	add	a4,a5,a0
    800064e0:	6789                	lui	a5,0x2
    800064e2:	97ba                	add	a5,a5,a4
    800064e4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800064e8:	e7ad                	bnez	a5,80006552 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800064ea:	00451793          	slli	a5,a0,0x4
    800064ee:	0001f717          	auipc	a4,0x1f
    800064f2:	b1270713          	addi	a4,a4,-1262 # 80025000 <disk+0x2000>
    800064f6:	6314                	ld	a3,0(a4)
    800064f8:	96be                	add	a3,a3,a5
    800064fa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800064fe:	6314                	ld	a3,0(a4)
    80006500:	96be                	add	a3,a3,a5
    80006502:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006506:	6314                	ld	a3,0(a4)
    80006508:	96be                	add	a3,a3,a5
    8000650a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000650e:	6318                	ld	a4,0(a4)
    80006510:	97ba                	add	a5,a5,a4
    80006512:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006516:	0001d797          	auipc	a5,0x1d
    8000651a:	aea78793          	addi	a5,a5,-1302 # 80023000 <disk>
    8000651e:	97aa                	add	a5,a5,a0
    80006520:	6509                	lui	a0,0x2
    80006522:	953e                	add	a0,a0,a5
    80006524:	4785                	li	a5,1
    80006526:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000652a:	0001f517          	auipc	a0,0x1f
    8000652e:	aee50513          	addi	a0,a0,-1298 # 80025018 <disk+0x2018>
    80006532:	ffffc097          	auipc	ra,0xffffc
    80006536:	63e080e7          	jalr	1598(ra) # 80002b70 <wakeup>
}
    8000653a:	60a2                	ld	ra,8(sp)
    8000653c:	6402                	ld	s0,0(sp)
    8000653e:	0141                	addi	sp,sp,16
    80006540:	8082                	ret
    panic("free_desc 1");
    80006542:	00002517          	auipc	a0,0x2
    80006546:	4b650513          	addi	a0,a0,1206 # 800089f8 <syscalls+0x338>
    8000654a:	ffffa097          	auipc	ra,0xffffa
    8000654e:	ff4080e7          	jalr	-12(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006552:	00002517          	auipc	a0,0x2
    80006556:	4b650513          	addi	a0,a0,1206 # 80008a08 <syscalls+0x348>
    8000655a:	ffffa097          	auipc	ra,0xffffa
    8000655e:	fe4080e7          	jalr	-28(ra) # 8000053e <panic>

0000000080006562 <virtio_disk_init>:
{
    80006562:	1101                	addi	sp,sp,-32
    80006564:	ec06                	sd	ra,24(sp)
    80006566:	e822                	sd	s0,16(sp)
    80006568:	e426                	sd	s1,8(sp)
    8000656a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000656c:	00002597          	auipc	a1,0x2
    80006570:	4ac58593          	addi	a1,a1,1196 # 80008a18 <syscalls+0x358>
    80006574:	0001f517          	auipc	a0,0x1f
    80006578:	bb450513          	addi	a0,a0,-1100 # 80025128 <disk+0x2128>
    8000657c:	ffffa097          	auipc	ra,0xffffa
    80006580:	5d8080e7          	jalr	1496(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006584:	100017b7          	lui	a5,0x10001
    80006588:	4398                	lw	a4,0(a5)
    8000658a:	2701                	sext.w	a4,a4
    8000658c:	747277b7          	lui	a5,0x74727
    80006590:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006594:	0ef71163          	bne	a4,a5,80006676 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006598:	100017b7          	lui	a5,0x10001
    8000659c:	43dc                	lw	a5,4(a5)
    8000659e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065a0:	4705                	li	a4,1
    800065a2:	0ce79a63          	bne	a5,a4,80006676 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065a6:	100017b7          	lui	a5,0x10001
    800065aa:	479c                	lw	a5,8(a5)
    800065ac:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800065ae:	4709                	li	a4,2
    800065b0:	0ce79363          	bne	a5,a4,80006676 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800065b4:	100017b7          	lui	a5,0x10001
    800065b8:	47d8                	lw	a4,12(a5)
    800065ba:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065bc:	554d47b7          	lui	a5,0x554d4
    800065c0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800065c4:	0af71963          	bne	a4,a5,80006676 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800065c8:	100017b7          	lui	a5,0x10001
    800065cc:	4705                	li	a4,1
    800065ce:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065d0:	470d                	li	a4,3
    800065d2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800065d4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800065d6:	c7ffe737          	lui	a4,0xc7ffe
    800065da:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800065de:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800065e0:	2701                	sext.w	a4,a4
    800065e2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065e4:	472d                	li	a4,11
    800065e6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065e8:	473d                	li	a4,15
    800065ea:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800065ec:	6705                	lui	a4,0x1
    800065ee:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800065f0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800065f4:	5bdc                	lw	a5,52(a5)
    800065f6:	2781                	sext.w	a5,a5
  if(max == 0)
    800065f8:	c7d9                	beqz	a5,80006686 <virtio_disk_init+0x124>
  if(max < NUM)
    800065fa:	471d                	li	a4,7
    800065fc:	08f77d63          	bgeu	a4,a5,80006696 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006600:	100014b7          	lui	s1,0x10001
    80006604:	47a1                	li	a5,8
    80006606:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006608:	6609                	lui	a2,0x2
    8000660a:	4581                	li	a1,0
    8000660c:	0001d517          	auipc	a0,0x1d
    80006610:	9f450513          	addi	a0,a0,-1548 # 80023000 <disk>
    80006614:	ffffa097          	auipc	ra,0xffffa
    80006618:	6cc080e7          	jalr	1740(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000661c:	0001d717          	auipc	a4,0x1d
    80006620:	9e470713          	addi	a4,a4,-1564 # 80023000 <disk>
    80006624:	00c75793          	srli	a5,a4,0xc
    80006628:	2781                	sext.w	a5,a5
    8000662a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000662c:	0001f797          	auipc	a5,0x1f
    80006630:	9d478793          	addi	a5,a5,-1580 # 80025000 <disk+0x2000>
    80006634:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006636:	0001d717          	auipc	a4,0x1d
    8000663a:	a4a70713          	addi	a4,a4,-1462 # 80023080 <disk+0x80>
    8000663e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006640:	0001e717          	auipc	a4,0x1e
    80006644:	9c070713          	addi	a4,a4,-1600 # 80024000 <disk+0x1000>
    80006648:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000664a:	4705                	li	a4,1
    8000664c:	00e78c23          	sb	a4,24(a5)
    80006650:	00e78ca3          	sb	a4,25(a5)
    80006654:	00e78d23          	sb	a4,26(a5)
    80006658:	00e78da3          	sb	a4,27(a5)
    8000665c:	00e78e23          	sb	a4,28(a5)
    80006660:	00e78ea3          	sb	a4,29(a5)
    80006664:	00e78f23          	sb	a4,30(a5)
    80006668:	00e78fa3          	sb	a4,31(a5)
}
    8000666c:	60e2                	ld	ra,24(sp)
    8000666e:	6442                	ld	s0,16(sp)
    80006670:	64a2                	ld	s1,8(sp)
    80006672:	6105                	addi	sp,sp,32
    80006674:	8082                	ret
    panic("could not find virtio disk");
    80006676:	00002517          	auipc	a0,0x2
    8000667a:	3b250513          	addi	a0,a0,946 # 80008a28 <syscalls+0x368>
    8000667e:	ffffa097          	auipc	ra,0xffffa
    80006682:	ec0080e7          	jalr	-320(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006686:	00002517          	auipc	a0,0x2
    8000668a:	3c250513          	addi	a0,a0,962 # 80008a48 <syscalls+0x388>
    8000668e:	ffffa097          	auipc	ra,0xffffa
    80006692:	eb0080e7          	jalr	-336(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006696:	00002517          	auipc	a0,0x2
    8000669a:	3d250513          	addi	a0,a0,978 # 80008a68 <syscalls+0x3a8>
    8000669e:	ffffa097          	auipc	ra,0xffffa
    800066a2:	ea0080e7          	jalr	-352(ra) # 8000053e <panic>

00000000800066a6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800066a6:	7159                	addi	sp,sp,-112
    800066a8:	f486                	sd	ra,104(sp)
    800066aa:	f0a2                	sd	s0,96(sp)
    800066ac:	eca6                	sd	s1,88(sp)
    800066ae:	e8ca                	sd	s2,80(sp)
    800066b0:	e4ce                	sd	s3,72(sp)
    800066b2:	e0d2                	sd	s4,64(sp)
    800066b4:	fc56                	sd	s5,56(sp)
    800066b6:	f85a                	sd	s6,48(sp)
    800066b8:	f45e                	sd	s7,40(sp)
    800066ba:	f062                	sd	s8,32(sp)
    800066bc:	ec66                	sd	s9,24(sp)
    800066be:	e86a                	sd	s10,16(sp)
    800066c0:	1880                	addi	s0,sp,112
    800066c2:	892a                	mv	s2,a0
    800066c4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800066c6:	00c52c83          	lw	s9,12(a0)
    800066ca:	001c9c9b          	slliw	s9,s9,0x1
    800066ce:	1c82                	slli	s9,s9,0x20
    800066d0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800066d4:	0001f517          	auipc	a0,0x1f
    800066d8:	a5450513          	addi	a0,a0,-1452 # 80025128 <disk+0x2128>
    800066dc:	ffffa097          	auipc	ra,0xffffa
    800066e0:	508080e7          	jalr	1288(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800066e4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800066e6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800066e8:	0001db97          	auipc	s7,0x1d
    800066ec:	918b8b93          	addi	s7,s7,-1768 # 80023000 <disk>
    800066f0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800066f2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800066f4:	8a4e                	mv	s4,s3
    800066f6:	a051                	j	8000677a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800066f8:	00fb86b3          	add	a3,s7,a5
    800066fc:	96da                	add	a3,a3,s6
    800066fe:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006702:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006704:	0207c563          	bltz	a5,8000672e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006708:	2485                	addiw	s1,s1,1
    8000670a:	0711                	addi	a4,a4,4
    8000670c:	25548063          	beq	s1,s5,8000694c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006710:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006712:	0001f697          	auipc	a3,0x1f
    80006716:	90668693          	addi	a3,a3,-1786 # 80025018 <disk+0x2018>
    8000671a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000671c:	0006c583          	lbu	a1,0(a3)
    80006720:	fde1                	bnez	a1,800066f8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006722:	2785                	addiw	a5,a5,1
    80006724:	0685                	addi	a3,a3,1
    80006726:	ff879be3          	bne	a5,s8,8000671c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000672a:	57fd                	li	a5,-1
    8000672c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000672e:	02905a63          	blez	s1,80006762 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006732:	f9042503          	lw	a0,-112(s0)
    80006736:	00000097          	auipc	ra,0x0
    8000673a:	d90080e7          	jalr	-624(ra) # 800064c6 <free_desc>
      for(int j = 0; j < i; j++)
    8000673e:	4785                	li	a5,1
    80006740:	0297d163          	bge	a5,s1,80006762 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006744:	f9442503          	lw	a0,-108(s0)
    80006748:	00000097          	auipc	ra,0x0
    8000674c:	d7e080e7          	jalr	-642(ra) # 800064c6 <free_desc>
      for(int j = 0; j < i; j++)
    80006750:	4789                	li	a5,2
    80006752:	0097d863          	bge	a5,s1,80006762 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006756:	f9842503          	lw	a0,-104(s0)
    8000675a:	00000097          	auipc	ra,0x0
    8000675e:	d6c080e7          	jalr	-660(ra) # 800064c6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006762:	0001f597          	auipc	a1,0x1f
    80006766:	9c658593          	addi	a1,a1,-1594 # 80025128 <disk+0x2128>
    8000676a:	0001f517          	auipc	a0,0x1f
    8000676e:	8ae50513          	addi	a0,a0,-1874 # 80025018 <disk+0x2018>
    80006772:	ffffc097          	auipc	ra,0xffffc
    80006776:	de8080e7          	jalr	-536(ra) # 8000255a <sleep>
  for(int i = 0; i < 3; i++){
    8000677a:	f9040713          	addi	a4,s0,-112
    8000677e:	84ce                	mv	s1,s3
    80006780:	bf41                	j	80006710 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006782:	20058713          	addi	a4,a1,512
    80006786:	00471693          	slli	a3,a4,0x4
    8000678a:	0001d717          	auipc	a4,0x1d
    8000678e:	87670713          	addi	a4,a4,-1930 # 80023000 <disk>
    80006792:	9736                	add	a4,a4,a3
    80006794:	4685                	li	a3,1
    80006796:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000679a:	20058713          	addi	a4,a1,512
    8000679e:	00471693          	slli	a3,a4,0x4
    800067a2:	0001d717          	auipc	a4,0x1d
    800067a6:	85e70713          	addi	a4,a4,-1954 # 80023000 <disk>
    800067aa:	9736                	add	a4,a4,a3
    800067ac:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800067b0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800067b4:	7679                	lui	a2,0xffffe
    800067b6:	963e                	add	a2,a2,a5
    800067b8:	0001f697          	auipc	a3,0x1f
    800067bc:	84868693          	addi	a3,a3,-1976 # 80025000 <disk+0x2000>
    800067c0:	6298                	ld	a4,0(a3)
    800067c2:	9732                	add	a4,a4,a2
    800067c4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800067c6:	6298                	ld	a4,0(a3)
    800067c8:	9732                	add	a4,a4,a2
    800067ca:	4541                	li	a0,16
    800067cc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800067ce:	6298                	ld	a4,0(a3)
    800067d0:	9732                	add	a4,a4,a2
    800067d2:	4505                	li	a0,1
    800067d4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800067d8:	f9442703          	lw	a4,-108(s0)
    800067dc:	6288                	ld	a0,0(a3)
    800067de:	962a                	add	a2,a2,a0
    800067e0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800067e4:	0712                	slli	a4,a4,0x4
    800067e6:	6290                	ld	a2,0(a3)
    800067e8:	963a                	add	a2,a2,a4
    800067ea:	05890513          	addi	a0,s2,88
    800067ee:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800067f0:	6294                	ld	a3,0(a3)
    800067f2:	96ba                	add	a3,a3,a4
    800067f4:	40000613          	li	a2,1024
    800067f8:	c690                	sw	a2,8(a3)
  if(write)
    800067fa:	140d0063          	beqz	s10,8000693a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800067fe:	0001f697          	auipc	a3,0x1f
    80006802:	8026b683          	ld	a3,-2046(a3) # 80025000 <disk+0x2000>
    80006806:	96ba                	add	a3,a3,a4
    80006808:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000680c:	0001c817          	auipc	a6,0x1c
    80006810:	7f480813          	addi	a6,a6,2036 # 80023000 <disk>
    80006814:	0001e517          	auipc	a0,0x1e
    80006818:	7ec50513          	addi	a0,a0,2028 # 80025000 <disk+0x2000>
    8000681c:	6114                	ld	a3,0(a0)
    8000681e:	96ba                	add	a3,a3,a4
    80006820:	00c6d603          	lhu	a2,12(a3)
    80006824:	00166613          	ori	a2,a2,1
    80006828:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000682c:	f9842683          	lw	a3,-104(s0)
    80006830:	6110                	ld	a2,0(a0)
    80006832:	9732                	add	a4,a4,a2
    80006834:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006838:	20058613          	addi	a2,a1,512
    8000683c:	0612                	slli	a2,a2,0x4
    8000683e:	9642                	add	a2,a2,a6
    80006840:	577d                	li	a4,-1
    80006842:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006846:	00469713          	slli	a4,a3,0x4
    8000684a:	6114                	ld	a3,0(a0)
    8000684c:	96ba                	add	a3,a3,a4
    8000684e:	03078793          	addi	a5,a5,48
    80006852:	97c2                	add	a5,a5,a6
    80006854:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006856:	611c                	ld	a5,0(a0)
    80006858:	97ba                	add	a5,a5,a4
    8000685a:	4685                	li	a3,1
    8000685c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000685e:	611c                	ld	a5,0(a0)
    80006860:	97ba                	add	a5,a5,a4
    80006862:	4809                	li	a6,2
    80006864:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006868:	611c                	ld	a5,0(a0)
    8000686a:	973e                	add	a4,a4,a5
    8000686c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006870:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006874:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006878:	6518                	ld	a4,8(a0)
    8000687a:	00275783          	lhu	a5,2(a4)
    8000687e:	8b9d                	andi	a5,a5,7
    80006880:	0786                	slli	a5,a5,0x1
    80006882:	97ba                	add	a5,a5,a4
    80006884:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006888:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000688c:	6518                	ld	a4,8(a0)
    8000688e:	00275783          	lhu	a5,2(a4)
    80006892:	2785                	addiw	a5,a5,1
    80006894:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006898:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000689c:	100017b7          	lui	a5,0x10001
    800068a0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800068a4:	00492703          	lw	a4,4(s2)
    800068a8:	4785                	li	a5,1
    800068aa:	02f71163          	bne	a4,a5,800068cc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800068ae:	0001f997          	auipc	s3,0x1f
    800068b2:	87a98993          	addi	s3,s3,-1926 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800068b6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800068b8:	85ce                	mv	a1,s3
    800068ba:	854a                	mv	a0,s2
    800068bc:	ffffc097          	auipc	ra,0xffffc
    800068c0:	c9e080e7          	jalr	-866(ra) # 8000255a <sleep>
  while(b->disk == 1) {
    800068c4:	00492783          	lw	a5,4(s2)
    800068c8:	fe9788e3          	beq	a5,s1,800068b8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800068cc:	f9042903          	lw	s2,-112(s0)
    800068d0:	20090793          	addi	a5,s2,512
    800068d4:	00479713          	slli	a4,a5,0x4
    800068d8:	0001c797          	auipc	a5,0x1c
    800068dc:	72878793          	addi	a5,a5,1832 # 80023000 <disk>
    800068e0:	97ba                	add	a5,a5,a4
    800068e2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800068e6:	0001e997          	auipc	s3,0x1e
    800068ea:	71a98993          	addi	s3,s3,1818 # 80025000 <disk+0x2000>
    800068ee:	00491713          	slli	a4,s2,0x4
    800068f2:	0009b783          	ld	a5,0(s3)
    800068f6:	97ba                	add	a5,a5,a4
    800068f8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800068fc:	854a                	mv	a0,s2
    800068fe:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006902:	00000097          	auipc	ra,0x0
    80006906:	bc4080e7          	jalr	-1084(ra) # 800064c6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000690a:	8885                	andi	s1,s1,1
    8000690c:	f0ed                	bnez	s1,800068ee <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000690e:	0001f517          	auipc	a0,0x1f
    80006912:	81a50513          	addi	a0,a0,-2022 # 80025128 <disk+0x2128>
    80006916:	ffffa097          	auipc	ra,0xffffa
    8000691a:	382080e7          	jalr	898(ra) # 80000c98 <release>
}
    8000691e:	70a6                	ld	ra,104(sp)
    80006920:	7406                	ld	s0,96(sp)
    80006922:	64e6                	ld	s1,88(sp)
    80006924:	6946                	ld	s2,80(sp)
    80006926:	69a6                	ld	s3,72(sp)
    80006928:	6a06                	ld	s4,64(sp)
    8000692a:	7ae2                	ld	s5,56(sp)
    8000692c:	7b42                	ld	s6,48(sp)
    8000692e:	7ba2                	ld	s7,40(sp)
    80006930:	7c02                	ld	s8,32(sp)
    80006932:	6ce2                	ld	s9,24(sp)
    80006934:	6d42                	ld	s10,16(sp)
    80006936:	6165                	addi	sp,sp,112
    80006938:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000693a:	0001e697          	auipc	a3,0x1e
    8000693e:	6c66b683          	ld	a3,1734(a3) # 80025000 <disk+0x2000>
    80006942:	96ba                	add	a3,a3,a4
    80006944:	4609                	li	a2,2
    80006946:	00c69623          	sh	a2,12(a3)
    8000694a:	b5c9                	j	8000680c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000694c:	f9042583          	lw	a1,-112(s0)
    80006950:	20058793          	addi	a5,a1,512
    80006954:	0792                	slli	a5,a5,0x4
    80006956:	0001c517          	auipc	a0,0x1c
    8000695a:	75250513          	addi	a0,a0,1874 # 800230a8 <disk+0xa8>
    8000695e:	953e                	add	a0,a0,a5
  if(write)
    80006960:	e20d11e3          	bnez	s10,80006782 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006964:	20058713          	addi	a4,a1,512
    80006968:	00471693          	slli	a3,a4,0x4
    8000696c:	0001c717          	auipc	a4,0x1c
    80006970:	69470713          	addi	a4,a4,1684 # 80023000 <disk>
    80006974:	9736                	add	a4,a4,a3
    80006976:	0a072423          	sw	zero,168(a4)
    8000697a:	b505                	j	8000679a <virtio_disk_rw+0xf4>

000000008000697c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000697c:	1101                	addi	sp,sp,-32
    8000697e:	ec06                	sd	ra,24(sp)
    80006980:	e822                	sd	s0,16(sp)
    80006982:	e426                	sd	s1,8(sp)
    80006984:	e04a                	sd	s2,0(sp)
    80006986:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006988:	0001e517          	auipc	a0,0x1e
    8000698c:	7a050513          	addi	a0,a0,1952 # 80025128 <disk+0x2128>
    80006990:	ffffa097          	auipc	ra,0xffffa
    80006994:	254080e7          	jalr	596(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006998:	10001737          	lui	a4,0x10001
    8000699c:	533c                	lw	a5,96(a4)
    8000699e:	8b8d                	andi	a5,a5,3
    800069a0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800069a2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800069a6:	0001e797          	auipc	a5,0x1e
    800069aa:	65a78793          	addi	a5,a5,1626 # 80025000 <disk+0x2000>
    800069ae:	6b94                	ld	a3,16(a5)
    800069b0:	0207d703          	lhu	a4,32(a5)
    800069b4:	0026d783          	lhu	a5,2(a3)
    800069b8:	06f70163          	beq	a4,a5,80006a1a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069bc:	0001c917          	auipc	s2,0x1c
    800069c0:	64490913          	addi	s2,s2,1604 # 80023000 <disk>
    800069c4:	0001e497          	auipc	s1,0x1e
    800069c8:	63c48493          	addi	s1,s1,1596 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800069cc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069d0:	6898                	ld	a4,16(s1)
    800069d2:	0204d783          	lhu	a5,32(s1)
    800069d6:	8b9d                	andi	a5,a5,7
    800069d8:	078e                	slli	a5,a5,0x3
    800069da:	97ba                	add	a5,a5,a4
    800069dc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800069de:	20078713          	addi	a4,a5,512
    800069e2:	0712                	slli	a4,a4,0x4
    800069e4:	974a                	add	a4,a4,s2
    800069e6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800069ea:	e731                	bnez	a4,80006a36 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800069ec:	20078793          	addi	a5,a5,512
    800069f0:	0792                	slli	a5,a5,0x4
    800069f2:	97ca                	add	a5,a5,s2
    800069f4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800069f6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800069fa:	ffffc097          	auipc	ra,0xffffc
    800069fe:	176080e7          	jalr	374(ra) # 80002b70 <wakeup>

    disk.used_idx += 1;
    80006a02:	0204d783          	lhu	a5,32(s1)
    80006a06:	2785                	addiw	a5,a5,1
    80006a08:	17c2                	slli	a5,a5,0x30
    80006a0a:	93c1                	srli	a5,a5,0x30
    80006a0c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006a10:	6898                	ld	a4,16(s1)
    80006a12:	00275703          	lhu	a4,2(a4)
    80006a16:	faf71be3          	bne	a4,a5,800069cc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006a1a:	0001e517          	auipc	a0,0x1e
    80006a1e:	70e50513          	addi	a0,a0,1806 # 80025128 <disk+0x2128>
    80006a22:	ffffa097          	auipc	ra,0xffffa
    80006a26:	276080e7          	jalr	630(ra) # 80000c98 <release>
}
    80006a2a:	60e2                	ld	ra,24(sp)
    80006a2c:	6442                	ld	s0,16(sp)
    80006a2e:	64a2                	ld	s1,8(sp)
    80006a30:	6902                	ld	s2,0(sp)
    80006a32:	6105                	addi	sp,sp,32
    80006a34:	8082                	ret
      panic("virtio_disk_intr status");
    80006a36:	00002517          	auipc	a0,0x2
    80006a3a:	05250513          	addi	a0,a0,82 # 80008a88 <syscalls+0x3c8>
    80006a3e:	ffffa097          	auipc	ra,0xffffa
    80006a42:	b00080e7          	jalr	-1280(ra) # 8000053e <panic>

0000000080006a46 <cas>:
    80006a46:	100522af          	lr.w	t0,(a0)
    80006a4a:	00b29563          	bne	t0,a1,80006a54 <fail>
    80006a4e:	18c5252f          	sc.w	a0,a2,(a0)
    80006a52:	8082                	ret

0000000080006a54 <fail>:
    80006a54:	4505                	li	a0,1
    80006a56:	8082                	ret
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
