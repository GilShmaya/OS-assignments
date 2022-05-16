
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ca013103          	ld	sp,-864(sp) # 80008ca0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000064:	00007797          	auipc	a5,0x7
    80000068:	80c78793          	addi	a5,a5,-2036 # 80006870 <timervec>
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
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	8b0080e7          	jalr	-1872(ra) # 800029dc <either_copyin>
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
    800001c8:	f0a080e7          	jalr	-246(ra) # 800020ce <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	534080e7          	jalr	1332(ra) # 80002708 <sleep>
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
    80000214:	776080e7          	jalr	1910(ra) # 80002986 <either_copyout>
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
    800002f6:	740080e7          	jalr	1856(ra) # 80002a32 <procdump>
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
    80000446:	00003097          	auipc	ra,0x3
    8000044a:	948080e7          	jalr	-1720(ra) # 80002d8e <wakeup>
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
    80000570:	0ec50513          	addi	a0,a0,236 # 80008658 <digits+0x618>
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
    800008a4:	4ee080e7          	jalr	1262(ra) # 80002d8e <wakeup>
    
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
    80000930:	ddc080e7          	jalr	-548(ra) # 80002708 <sleep>
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
    80000b82:	52e080e7          	jalr	1326(ra) # 800020ac <mycpu>
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
    80000bb4:	4fc080e7          	jalr	1276(ra) # 800020ac <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	4f0080e7          	jalr	1264(ra) # 800020ac <mycpu>
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
    80000bd8:	4d8080e7          	jalr	1240(ra) # 800020ac <mycpu>
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
    80000c18:	498080e7          	jalr	1176(ra) # 800020ac <mycpu>
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
    80000c44:	46c080e7          	jalr	1132(ra) # 800020ac <mycpu>
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
    80000e9a:	206080e7          	jalr	518(ra) # 8000209c <cpuid>
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
    80000eb6:	1ea080e7          	jalr	490(ra) # 8000209c <cpuid>
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
    80000ed8:	406080e7          	jalr	1030(ra) # 800032da <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00006097          	auipc	ra,0x6
    80000ee0:	9d4080e7          	jalr	-1580(ra) # 800068b0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	26c080e7          	jalr	620(ra) # 80003150 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	75c50513          	addi	a0,a0,1884 # 80008658 <digits+0x618>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	73c50513          	addi	a0,a0,1852 # 80008658 <digits+0x618>
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
    80000f48:	044080e7          	jalr	68(ra) # 80001f88 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	366080e7          	jalr	870(ra) # 800032b2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	386080e7          	jalr	902(ra) # 800032da <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00006097          	auipc	ra,0x6
    80000f60:	93e080e7          	jalr	-1730(ra) # 8000689a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00006097          	auipc	ra,0x6
    80000f68:	94c080e7          	jalr	-1716(ra) # 800068b0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00003097          	auipc	ra,0x3
    80000f70:	b2c080e7          	jalr	-1236(ra) # 80003a98 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	1bc080e7          	jalr	444(ra) # 80004130 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	166080e7          	jalr	358(ra) # 800050e2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00006097          	auipc	ra,0x6
    80000f88:	a4e080e7          	jalr	-1458(ra) # 800069d2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	50a080e7          	jalr	1290(ra) # 80002496 <userinit>
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
    80001244:	cb2080e7          	jalr	-846(ra) # 80001ef2 <proc_mapstacks>
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
    800019a6:	26650513          	addi	a0,a0,614 # 80008c08 <unused_list+0x8>
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	1aa080e7          	jalr	426(ra) # 80000b54 <initlock>
  initlock(&sleeping_list.head_lock, "sleeping_list - head lock");
    800019b2:	00007597          	auipc	a1,0x7
    800019b6:	87658593          	addi	a1,a1,-1930 # 80008228 <digits+0x1e8>
    800019ba:	00007517          	auipc	a0,0x7
    800019be:	26e50513          	addi	a0,a0,622 # 80008c28 <sleeping_list+0x8>
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	192080e7          	jalr	402(ra) # 80000b54 <initlock>
  initlock(&zombie_list.head_lock, "zombie_list - head lock");
    800019ca:	00007597          	auipc	a1,0x7
    800019ce:	87e58593          	addi	a1,a1,-1922 # 80008248 <digits+0x208>
    800019d2:	00007517          	auipc	a0,0x7
    800019d6:	27650513          	addi	a0,a0,630 # 80008c48 <zombie_list+0x8>
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
    80001a6e:	711d                	addi	sp,sp,-96
    80001a70:	ec86                	sd	ra,88(sp)
    80001a72:	e8a2                	sd	s0,80(sp)
    80001a74:	e4a6                	sd	s1,72(sp)
    80001a76:	e0ca                	sd	s2,64(sp)
    80001a78:	fc4e                	sd	s3,56(sp)
    80001a7a:	f852                	sd	s4,48(sp)
    80001a7c:	f456                	sd	s5,40(sp)
    80001a7e:	f05a                	sd	s6,32(sp)
    80001a80:	1080                	addi	s0,sp,96
    80001a82:	892a                	mv	s2,a0
    80001a84:	8aae                	mv	s5,a1
  printf("before insert: \n");
    80001a86:	00006517          	auipc	a0,0x6
    80001a8a:	7da50513          	addi	a0,a0,2010 # 80008260 <digits+0x220>
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	afa080e7          	jalr	-1286(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001a96:	00093603          	ld	a2,0(s2) # 1000 <_entry-0x7ffff000>
    80001a9a:	00893683          	ld	a3,8(s2)
    80001a9e:	01093703          	ld	a4,16(s2)
    80001aa2:	01893783          	ld	a5,24(s2)
    80001aa6:	fac43023          	sd	a2,-96(s0)
    80001aaa:	fad43423          	sd	a3,-88(s0)
    80001aae:	fae43823          	sd	a4,-80(s0)
    80001ab2:	faf43c23          	sd	a5,-72(s0)
    80001ab6:	fa040513          	addi	a0,s0,-96
    80001aba:	00000097          	auipc	ra,0x0
    80001abe:	d84080e7          	jalr	-636(ra) # 8000183e <print_list>
  acquire(&lst->head_lock);
    80001ac2:	00890993          	addi	s3,s2,8
    80001ac6:	854e                	mv	a0,s3
    80001ac8:	fffff097          	auipc	ra,0xfffff
    80001acc:	11c080e7          	jalr	284(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80001ad0:	00092503          	lw	a0,0(s2)
  //printf("after aquire insert head: \n"); // delete
  if(isEmpty(lst)){
    80001ad4:	57fd                	li	a5,-1
    80001ad6:	02f51163          	bne	a0,a5,80001af8 <insert_proc_to_list+0x8a>
    lst->head = p->index;
    80001ada:	16caa783          	lw	a5,364(s5)
    80001ade:	00f92023          	sw	a5,0(s2)
  p->next_index = -1;
    80001ae2:	57fd                	li	a5,-1
    80001ae4:	16faaa23          	sw	a5,372(s5)
  p->prev_index = -1;
    80001ae8:	16faa823          	sw	a5,368(s5)
    initialize_proc(p);
    release(&lst->head_lock);
    80001aec:	854e                	mv	a0,s3
    80001aee:	fffff097          	auipc	ra,0xfffff
    80001af2:	1aa080e7          	jalr	426(ra) # 80000c98 <release>
    80001af6:	a849                	j	80001b88 <insert_proc_to_list+0x11a>
    //printf("after release insert head: \n"); // delete
  }
  else{ 
    struct proc *curr = &proc[lst->head];
    80001af8:	19000793          	li	a5,400
    80001afc:	02f50533          	mul	a0,a0,a5
    80001b00:	00010797          	auipc	a5,0x10
    80001b04:	d5078793          	addi	a5,a5,-688 # 80011850 <proc>
    80001b08:	00f504b3          	add	s1,a0,a5
    acquire(&curr->node_lock);
    80001b0c:	17850513          	addi	a0,a0,376
    80001b10:	953e                	add	a0,a0,a5
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	0d2080e7          	jalr	210(ra) # 80000be4 <acquire>
    //printf("after aquire insert node: \n"); // delete
    release(&lst->head_lock);
    80001b1a:	854e                	mv	a0,s3
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	17c080e7          	jalr	380(ra) # 80000c98 <release>
    //printf("after release insert head: \n"); // delete
    while(curr->next_index != -1){ // search tail
    80001b24:	1744a783          	lw	a5,372(s1)
    80001b28:	577d                	li	a4,-1
    80001b2a:	04e78163          	beq	a5,a4,80001b6c <insert_proc_to_list+0xfe>
      acquire(&proc[curr->next_index].node_lock);
    80001b2e:	19000a13          	li	s4,400
    80001b32:	00010997          	auipc	s3,0x10
    80001b36:	d1e98993          	addi	s3,s3,-738 # 80011850 <proc>
    while(curr->next_index != -1){ // search tail
    80001b3a:	5b7d                	li	s6,-1
      acquire(&proc[curr->next_index].node_lock);
    80001b3c:	034787b3          	mul	a5,a5,s4
    80001b40:	17878513          	addi	a0,a5,376
    80001b44:	954e                	add	a0,a0,s3
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	09e080e7          	jalr	158(ra) # 80000be4 <acquire>
      //printf("after aquire insert node: \n"); // delete
      release(&curr->node_lock);
    80001b4e:	17848513          	addi	a0,s1,376
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	146080e7          	jalr	326(ra) # 80000c98 <release>
      //printf("after release insert node: \n"); // delete
      curr = &proc[curr->next_index];
    80001b5a:	1744a483          	lw	s1,372(s1)
    80001b5e:	034484b3          	mul	s1,s1,s4
    80001b62:	94ce                	add	s1,s1,s3
    while(curr->next_index != -1){ // search tail
    80001b64:	1744a783          	lw	a5,372(s1)
    80001b68:	fd679ae3          	bne	a5,s6,80001b3c <insert_proc_to_list+0xce>
    }
    set_next_proc(curr, p->index);  // update next proc of the curr tail
    80001b6c:	16caa783          	lw	a5,364(s5)
  p->next_index = value; 
    80001b70:	16f4aa23          	sw	a5,372(s1)
    set_prev_proc(p, curr->index); // update the prev proc of the new proc
    80001b74:	16c4a783          	lw	a5,364(s1)
  p->prev_index = value; 
    80001b78:	16faa823          	sw	a5,368(s5)
    release(&curr->node_lock);
    80001b7c:	17848513          	addi	a0,s1,376
    80001b80:	fffff097          	auipc	ra,0xfffff
    80001b84:	118080e7          	jalr	280(ra) # 80000c98 <release>
    //printf("after release insert node: \n"); // delete
  }
  printf("after insert: \n");
    80001b88:	00006517          	auipc	a0,0x6
    80001b8c:	6f050513          	addi	a0,a0,1776 # 80008278 <digits+0x238>
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	9f8080e7          	jalr	-1544(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001b98:	00093603          	ld	a2,0(s2)
    80001b9c:	00893683          	ld	a3,8(s2)
    80001ba0:	01093703          	ld	a4,16(s2)
    80001ba4:	01893783          	ld	a5,24(s2)
    80001ba8:	fac43023          	sd	a2,-96(s0)
    80001bac:	fad43423          	sd	a3,-88(s0)
    80001bb0:	fae43823          	sd	a4,-80(s0)
    80001bb4:	faf43c23          	sd	a5,-72(s0)
    80001bb8:	fa040513          	addi	a0,s0,-96
    80001bbc:	00000097          	auipc	ra,0x0
    80001bc0:	c82080e7          	jalr	-894(ra) # 8000183e <print_list>
  return 1; 
}
    80001bc4:	4505                	li	a0,1
    80001bc6:	60e6                	ld	ra,88(sp)
    80001bc8:	6446                	ld	s0,80(sp)
    80001bca:	64a6                	ld	s1,72(sp)
    80001bcc:	6906                	ld	s2,64(sp)
    80001bce:	79e2                	ld	s3,56(sp)
    80001bd0:	7a42                	ld	s4,48(sp)
    80001bd2:	7aa2                	ld	s5,40(sp)
    80001bd4:	7b02                	ld	s6,32(sp)
    80001bd6:	6125                	addi	sp,sp,96
    80001bd8:	8082                	ret

0000000080001bda <remove_head_from_list>:

int 
remove_head_from_list(struct _list *lst){
    80001bda:	711d                	addi	sp,sp,-96
    80001bdc:	ec86                	sd	ra,88(sp)
    80001bde:	e8a2                	sd	s0,80(sp)
    80001be0:	e4a6                	sd	s1,72(sp)
    80001be2:	e0ca                	sd	s2,64(sp)
    80001be4:	fc4e                	sd	s3,56(sp)
    80001be6:	f852                	sd	s4,48(sp)
    80001be8:	f456                	sd	s5,40(sp)
    80001bea:	1080                	addi	s0,sp,96
    80001bec:	84aa                	mv	s1,a0
  printf("before remove head: \n");
    80001bee:	00006517          	auipc	a0,0x6
    80001bf2:	69a50513          	addi	a0,a0,1690 # 80008288 <digits+0x248>
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	992080e7          	jalr	-1646(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001bfe:	6090                	ld	a2,0(s1)
    80001c00:	6494                	ld	a3,8(s1)
    80001c02:	6898                	ld	a4,16(s1)
    80001c04:	6c9c                	ld	a5,24(s1)
    80001c06:	fac43023          	sd	a2,-96(s0)
    80001c0a:	fad43423          	sd	a3,-88(s0)
    80001c0e:	fae43823          	sd	a4,-80(s0)
    80001c12:	faf43c23          	sd	a5,-72(s0)
    80001c16:	fa040513          	addi	a0,s0,-96
    80001c1a:	00000097          	auipc	ra,0x0
    80001c1e:	c24080e7          	jalr	-988(ra) # 8000183e <print_list>
  return lst->head == -1;
    80001c22:	0004a903          	lw	s2,0(s1)

  if(isEmpty(lst)){
    80001c26:	57fd                	li	a5,-1
    80001c28:	0af90063          	beq	s2,a5,80001cc8 <remove_head_from_list+0xee>
    printf("Fails in removing the head from the list: the list is empty\n");
    return 0;
  }
  struct proc *p_head = &proc[lst->head];
  acquire(&p_head->node_lock);
    80001c2c:	19000a13          	li	s4,400
    80001c30:	03490ab3          	mul	s5,s2,s4
    80001c34:	178a8993          	addi	s3,s5,376
    80001c38:	00010a17          	auipc	s4,0x10
    80001c3c:	c18a0a13          	addi	s4,s4,-1000 # 80011850 <proc>
    80001c40:	99d2                	add	s3,s3,s4
    80001c42:	854e                	mv	a0,s3
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	fa0080e7          	jalr	-96(ra) # 80000be4 <acquire>
  lst->head = p_head->next_index;
    80001c4c:	9a56                	add	s4,s4,s5
    80001c4e:	174a2783          	lw	a5,372(s4)
    80001c52:	c09c                	sw	a5,0(s1)
  if(lst->head != -1){
    80001c54:	577d                	li	a4,-1
    80001c56:	08e79363          	bne	a5,a4,80001cdc <remove_head_from_list+0x102>
  p->next_index = -1;
    80001c5a:	19000793          	li	a5,400
    80001c5e:	02f90933          	mul	s2,s2,a5
    80001c62:	00010797          	auipc	a5,0x10
    80001c66:	bee78793          	addi	a5,a5,-1042 # 80011850 <proc>
    80001c6a:	993e                	add	s2,s2,a5
    80001c6c:	57fd                	li	a5,-1
    80001c6e:	16f92a23          	sw	a5,372(s2)
  p->prev_index = -1;
    80001c72:	16f92823          	sw	a5,368(s2)
    set_prev_proc(&proc[p_head->next_index], -1);
  }
  initialize_proc(p_head);
  release(&p_head->node_lock);
    80001c76:	854e                	mv	a0,s3
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	020080e7          	jalr	32(ra) # 80000c98 <release>
  printf("after remove head: \n");
    80001c80:	00006517          	auipc	a0,0x6
    80001c84:	66050513          	addi	a0,a0,1632 # 800082e0 <digits+0x2a0>
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	900080e7          	jalr	-1792(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001c90:	6090                	ld	a2,0(s1)
    80001c92:	6494                	ld	a3,8(s1)
    80001c94:	6898                	ld	a4,16(s1)
    80001c96:	6c9c                	ld	a5,24(s1)
    80001c98:	fac43023          	sd	a2,-96(s0)
    80001c9c:	fad43423          	sd	a3,-88(s0)
    80001ca0:	fae43823          	sd	a4,-80(s0)
    80001ca4:	faf43c23          	sd	a5,-72(s0)
    80001ca8:	fa040513          	addi	a0,s0,-96
    80001cac:	00000097          	auipc	ra,0x0
    80001cb0:	b92080e7          	jalr	-1134(ra) # 8000183e <print_list>
  return 1;
    80001cb4:	4505                	li	a0,1
}
    80001cb6:	60e6                	ld	ra,88(sp)
    80001cb8:	6446                	ld	s0,80(sp)
    80001cba:	64a6                	ld	s1,72(sp)
    80001cbc:	6906                	ld	s2,64(sp)
    80001cbe:	79e2                	ld	s3,56(sp)
    80001cc0:	7a42                	ld	s4,48(sp)
    80001cc2:	7aa2                	ld	s5,40(sp)
    80001cc4:	6125                	addi	sp,sp,96
    80001cc6:	8082                	ret
    printf("Fails in removing the head from the list: the list is empty\n");
    80001cc8:	00006517          	auipc	a0,0x6
    80001ccc:	5d850513          	addi	a0,a0,1496 # 800082a0 <digits+0x260>
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	8b8080e7          	jalr	-1864(ra) # 80000588 <printf>
    return 0;
    80001cd8:	4501                	li	a0,0
    80001cda:	bff1                	j	80001cb6 <remove_head_from_list+0xdc>
  p->prev_index = value; 
    80001cdc:	19000713          	li	a4,400
    80001ce0:	02e787b3          	mul	a5,a5,a4
    80001ce4:	00010717          	auipc	a4,0x10
    80001ce8:	b6c70713          	addi	a4,a4,-1172 # 80011850 <proc>
    80001cec:	97ba                	add	a5,a5,a4
    80001cee:	577d                	li	a4,-1
    80001cf0:	16e7a823          	sw	a4,368(a5)
}
    80001cf4:	b79d                	j	80001c5a <remove_head_from_list+0x80>

0000000080001cf6 <remove_proc_to_list>:

int
remove_proc_to_list(struct _list *lst, struct proc *p){
    80001cf6:	7159                	addi	sp,sp,-112
    80001cf8:	f486                	sd	ra,104(sp)
    80001cfa:	f0a2                	sd	s0,96(sp)
    80001cfc:	eca6                	sd	s1,88(sp)
    80001cfe:	e8ca                	sd	s2,80(sp)
    80001d00:	e4ce                	sd	s3,72(sp)
    80001d02:	e0d2                	sd	s4,64(sp)
    80001d04:	fc56                	sd	s5,56(sp)
    80001d06:	f85a                	sd	s6,48(sp)
    80001d08:	f45e                	sd	s7,40(sp)
    80001d0a:	1880                	addi	s0,sp,112
    80001d0c:	892a                	mv	s2,a0
    80001d0e:	89ae                	mv	s3,a1
  printf("before remove: \n");
    80001d10:	00006517          	auipc	a0,0x6
    80001d14:	5e850513          	addi	a0,a0,1512 # 800082f8 <digits+0x2b8>
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	870080e7          	jalr	-1936(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001d20:	00093603          	ld	a2,0(s2)
    80001d24:	00893683          	ld	a3,8(s2)
    80001d28:	01093703          	ld	a4,16(s2)
    80001d2c:	01893783          	ld	a5,24(s2)
    80001d30:	f8c43823          	sd	a2,-112(s0)
    80001d34:	f8d43c23          	sd	a3,-104(s0)
    80001d38:	fae43023          	sd	a4,-96(s0)
    80001d3c:	faf43423          	sd	a5,-88(s0)
    80001d40:	f9040513          	addi	a0,s0,-112
    80001d44:	00000097          	auipc	ra,0x0
    80001d48:	afa080e7          	jalr	-1286(ra) # 8000183e <print_list>

  acquire(&lst->head_lock);
    80001d4c:	00890b93          	addi	s7,s2,8
    80001d50:	855e                	mv	a0,s7
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	e92080e7          	jalr	-366(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80001d5a:	00092503          	lw	a0,0(s2)
  if(isEmpty(lst)){
    80001d5e:	57fd                	li	a5,-1
    80001d60:	12f50063          	beq	a0,a5,80001e80 <remove_proc_to_list+0x18a>
    printf("Fails in removing the process from the list: the list is empty\n");
    release(&lst->head_lock);
    return 0;
  }

  if(lst->head == p->index){ // the required proc is the head
    80001d64:	16c9a783          	lw	a5,364(s3)
    80001d68:	12a78b63          	beq	a5,a0,80001e9e <remove_proc_to_list+0x1a8>
   remove_head_from_list(lst);
   release(&lst->head_lock);
  }
  else{
    struct proc *curr = &proc[lst->head];
    80001d6c:	19000793          	li	a5,400
    80001d70:	02f50533          	mul	a0,a0,a5
    80001d74:	00010797          	auipc	a5,0x10
    80001d78:	adc78793          	addi	a5,a5,-1316 # 80011850 <proc>
    80001d7c:	00f504b3          	add	s1,a0,a5
    acquire(&curr->node_lock);
    80001d80:	17850513          	addi	a0,a0,376
    80001d84:	953e                	add	a0,a0,a5
    80001d86:	fffff097          	auipc	ra,0xfffff
    80001d8a:	e5e080e7          	jalr	-418(ra) # 80000be4 <acquire>
    release(&lst->head_lock);
    80001d8e:	855e                	mv	a0,s7
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	f08080e7          	jalr	-248(ra) # 80000c98 <release>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001d98:	1744a783          	lw	a5,372(s1)
    80001d9c:	16c9a703          	lw	a4,364(s3)
    80001da0:	5b7d                	li	s6,-1
      acquire(&proc[curr->next_index].node_lock);
    80001da2:	19000a93          	li	s5,400
    80001da6:	00010a17          	auipc	s4,0x10
    80001daa:	aaaa0a13          	addi	s4,s4,-1366 # 80011850 <proc>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001dae:	10f70363          	beq	a4,a5,80001eb4 <remove_proc_to_list+0x1be>
    80001db2:	11678363          	beq	a5,s6,80001eb8 <remove_proc_to_list+0x1c2>
      acquire(&proc[curr->next_index].node_lock);
    80001db6:	035787b3          	mul	a5,a5,s5
    80001dba:	17878513          	addi	a0,a5,376
    80001dbe:	9552                	add	a0,a0,s4
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	e24080e7          	jalr	-476(ra) # 80000be4 <acquire>
      release(&curr->node_lock);
    80001dc8:	17848513          	addi	a0,s1,376
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	ecc080e7          	jalr	-308(ra) # 80000c98 <release>
      curr = &proc[curr->next_index];
    80001dd4:	1744a483          	lw	s1,372(s1)
    80001dd8:	035484b3          	mul	s1,s1,s5
    80001ddc:	94d2                	add	s1,s1,s4
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001dde:	1744a783          	lw	a5,372(s1)
    80001de2:	16c9a703          	lw	a4,364(s3)
    80001de6:	fce796e3          	bne	a5,a4,80001db2 <remove_proc_to_list+0xbc>
    }
    if(curr->next_index == -1){
    80001dea:	57fd                	li	a5,-1
    80001dec:	0cf70663          	beq	a4,a5,80001eb8 <remove_proc_to_list+0x1c2>
      printf("Fails in removing the process from the list: process is not found in the list\n");
      release(&lst->head_lock);
      return 0;
    }
    acquire(&p->node_lock); // curr is p->prev
    80001df0:	17898a13          	addi	s4,s3,376
    80001df4:	8552                	mv	a0,s4
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	dee080e7          	jalr	-530(ra) # 80000be4 <acquire>
    set_next_proc(curr, p->next_index);
    80001dfe:	1749a783          	lw	a5,372(s3)
  p->next_index = value; 
    80001e02:	16f4aa23          	sw	a5,372(s1)
    if(p->next_index != -1)
    80001e06:	577d                	li	a4,-1
    80001e08:	0ce79763          	bne	a5,a4,80001ed6 <remove_proc_to_list+0x1e0>
  p->next_index = -1;
    80001e0c:	57fd                	li	a5,-1
    80001e0e:	16f9aa23          	sw	a5,372(s3)
  p->prev_index = -1;
    80001e12:	16f9a823          	sw	a5,368(s3)
      set_prev_proc(&proc[p->next_index], curr->index);
    initialize_proc(p);
    release(&p->node_lock);
    80001e16:	8552                	mv	a0,s4
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	e80080e7          	jalr	-384(ra) # 80000c98 <release>
    release(&curr->node_lock);
    80001e20:	17848513          	addi	a0,s1,376
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	e74080e7          	jalr	-396(ra) # 80000c98 <release>
  }
  printf("after remove: \n");
    80001e2c:	00006517          	auipc	a0,0x6
    80001e30:	57450513          	addi	a0,a0,1396 # 800083a0 <digits+0x360>
    80001e34:	ffffe097          	auipc	ra,0xffffe
    80001e38:	754080e7          	jalr	1876(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001e3c:	00093603          	ld	a2,0(s2)
    80001e40:	00893683          	ld	a3,8(s2)
    80001e44:	01093703          	ld	a4,16(s2)
    80001e48:	01893783          	ld	a5,24(s2)
    80001e4c:	f8c43823          	sd	a2,-112(s0)
    80001e50:	f8d43c23          	sd	a3,-104(s0)
    80001e54:	fae43023          	sd	a4,-96(s0)
    80001e58:	faf43423          	sd	a5,-88(s0)
    80001e5c:	f9040513          	addi	a0,s0,-112
    80001e60:	00000097          	auipc	ra,0x0
    80001e64:	9de080e7          	jalr	-1570(ra) # 8000183e <print_list>
  return 1;
    80001e68:	4505                	li	a0,1
}
    80001e6a:	70a6                	ld	ra,104(sp)
    80001e6c:	7406                	ld	s0,96(sp)
    80001e6e:	64e6                	ld	s1,88(sp)
    80001e70:	6946                	ld	s2,80(sp)
    80001e72:	69a6                	ld	s3,72(sp)
    80001e74:	6a06                	ld	s4,64(sp)
    80001e76:	7ae2                	ld	s5,56(sp)
    80001e78:	7b42                	ld	s6,48(sp)
    80001e7a:	7ba2                	ld	s7,40(sp)
    80001e7c:	6165                	addi	sp,sp,112
    80001e7e:	8082                	ret
    printf("Fails in removing the process from the list: the list is empty\n");
    80001e80:	00006517          	auipc	a0,0x6
    80001e84:	49050513          	addi	a0,a0,1168 # 80008310 <digits+0x2d0>
    80001e88:	ffffe097          	auipc	ra,0xffffe
    80001e8c:	700080e7          	jalr	1792(ra) # 80000588 <printf>
    release(&lst->head_lock);
    80001e90:	855e                	mv	a0,s7
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	e06080e7          	jalr	-506(ra) # 80000c98 <release>
    return 0;
    80001e9a:	4501                	li	a0,0
    80001e9c:	b7f9                	j	80001e6a <remove_proc_to_list+0x174>
   remove_head_from_list(lst);
    80001e9e:	854a                	mv	a0,s2
    80001ea0:	00000097          	auipc	ra,0x0
    80001ea4:	d3a080e7          	jalr	-710(ra) # 80001bda <remove_head_from_list>
   release(&lst->head_lock);
    80001ea8:	855e                	mv	a0,s7
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	dee080e7          	jalr	-530(ra) # 80000c98 <release>
    80001eb2:	bfad                	j	80001e2c <remove_proc_to_list+0x136>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001eb4:	873e                	mv	a4,a5
    80001eb6:	bf15                	j	80001dea <remove_proc_to_list+0xf4>
      printf("Fails in removing the process from the list: process is not found in the list\n");
    80001eb8:	00006517          	auipc	a0,0x6
    80001ebc:	49850513          	addi	a0,a0,1176 # 80008350 <digits+0x310>
    80001ec0:	ffffe097          	auipc	ra,0xffffe
    80001ec4:	6c8080e7          	jalr	1736(ra) # 80000588 <printf>
      release(&lst->head_lock);
    80001ec8:	855e                	mv	a0,s7
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	dce080e7          	jalr	-562(ra) # 80000c98 <release>
      return 0;
    80001ed2:	4501                	li	a0,0
    80001ed4:	bf59                	j	80001e6a <remove_proc_to_list+0x174>
      set_prev_proc(&proc[p->next_index], curr->index);
    80001ed6:	16c4a683          	lw	a3,364(s1)
  p->prev_index = value; 
    80001eda:	19000713          	li	a4,400
    80001ede:	02e787b3          	mul	a5,a5,a4
    80001ee2:	00010717          	auipc	a4,0x10
    80001ee6:	96e70713          	addi	a4,a4,-1682 # 80011850 <proc>
    80001eea:	97ba                	add	a5,a5,a4
    80001eec:	16d7a823          	sw	a3,368(a5)
}
    80001ef0:	bf31                	j	80001e0c <remove_proc_to_list+0x116>

0000000080001ef2 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001ef2:	7139                	addi	sp,sp,-64
    80001ef4:	fc06                	sd	ra,56(sp)
    80001ef6:	f822                	sd	s0,48(sp)
    80001ef8:	f426                	sd	s1,40(sp)
    80001efa:	f04a                	sd	s2,32(sp)
    80001efc:	ec4e                	sd	s3,24(sp)
    80001efe:	e852                	sd	s4,16(sp)
    80001f00:	e456                	sd	s5,8(sp)
    80001f02:	e05a                	sd	s6,0(sp)
    80001f04:	0080                	addi	s0,sp,64
    80001f06:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f08:	00010497          	auipc	s1,0x10
    80001f0c:	94848493          	addi	s1,s1,-1720 # 80011850 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001f10:	8b26                	mv	s6,s1
    80001f12:	00006a97          	auipc	s5,0x6
    80001f16:	0eea8a93          	addi	s5,s5,238 # 80008000 <etext>
    80001f1a:	04000937          	lui	s2,0x4000
    80001f1e:	197d                	addi	s2,s2,-1
    80001f20:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f22:	00016a17          	auipc	s4,0x16
    80001f26:	d2ea0a13          	addi	s4,s4,-722 # 80017c50 <tickslock>
    char *pa = kalloc();
    80001f2a:	fffff097          	auipc	ra,0xfffff
    80001f2e:	bca080e7          	jalr	-1078(ra) # 80000af4 <kalloc>
    80001f32:	862a                	mv	a2,a0
    if(pa == 0)
    80001f34:	c131                	beqz	a0,80001f78 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001f36:	416485b3          	sub	a1,s1,s6
    80001f3a:	8591                	srai	a1,a1,0x4
    80001f3c:	000ab783          	ld	a5,0(s5)
    80001f40:	02f585b3          	mul	a1,a1,a5
    80001f44:	2585                	addiw	a1,a1,1
    80001f46:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001f4a:	4719                	li	a4,6
    80001f4c:	6685                	lui	a3,0x1
    80001f4e:	40b905b3          	sub	a1,s2,a1
    80001f52:	854e                	mv	a0,s3
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	1fc080e7          	jalr	508(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f5c:	19048493          	addi	s1,s1,400
    80001f60:	fd4495e3          	bne	s1,s4,80001f2a <proc_mapstacks+0x38>
  }
}
    80001f64:	70e2                	ld	ra,56(sp)
    80001f66:	7442                	ld	s0,48(sp)
    80001f68:	74a2                	ld	s1,40(sp)
    80001f6a:	7902                	ld	s2,32(sp)
    80001f6c:	69e2                	ld	s3,24(sp)
    80001f6e:	6a42                	ld	s4,16(sp)
    80001f70:	6aa2                	ld	s5,8(sp)
    80001f72:	6b02                	ld	s6,0(sp)
    80001f74:	6121                	addi	sp,sp,64
    80001f76:	8082                	ret
      panic("kalloc");
    80001f78:	00006517          	auipc	a0,0x6
    80001f7c:	43850513          	addi	a0,a0,1080 # 800083b0 <digits+0x370>
    80001f80:	ffffe097          	auipc	ra,0xffffe
    80001f84:	5be080e7          	jalr	1470(ra) # 8000053e <panic>

0000000080001f88 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001f88:	711d                	addi	sp,sp,-96
    80001f8a:	ec86                	sd	ra,88(sp)
    80001f8c:	e8a2                	sd	s0,80(sp)
    80001f8e:	e4a6                	sd	s1,72(sp)
    80001f90:	e0ca                	sd	s2,64(sp)
    80001f92:	fc4e                	sd	s3,56(sp)
    80001f94:	f852                	sd	s4,48(sp)
    80001f96:	f456                	sd	s5,40(sp)
    80001f98:	f05a                	sd	s6,32(sp)
    80001f9a:	ec5e                	sd	s7,24(sp)
    80001f9c:	e862                	sd	s8,16(sp)
    80001f9e:	e466                	sd	s9,8(sp)
    80001fa0:	e06a                	sd	s10,0(sp)
    80001fa2:	1080                	addi	s0,sp,96
  struct proc *p;

  initialize_lists();
    80001fa4:	00000097          	auipc	ra,0x0
    80001fa8:	94c080e7          	jalr	-1716(ra) # 800018f0 <initialize_lists>

  initlock(&pid_lock, "nextpid");
    80001fac:	00006597          	auipc	a1,0x6
    80001fb0:	40c58593          	addi	a1,a1,1036 # 800083b8 <digits+0x378>
    80001fb4:	00010517          	auipc	a0,0x10
    80001fb8:	86c50513          	addi	a0,a0,-1940 # 80011820 <pid_lock>
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	b98080e7          	jalr	-1128(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001fc4:	00006597          	auipc	a1,0x6
    80001fc8:	3fc58593          	addi	a1,a1,1020 # 800083c0 <digits+0x380>
    80001fcc:	00010517          	auipc	a0,0x10
    80001fd0:	86c50513          	addi	a0,a0,-1940 # 80011838 <wait_lock>
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	b80080e7          	jalr	-1152(ra) # 80000b54 <initlock>

  int i = 0;
    80001fdc:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fde:	00010497          	auipc	s1,0x10
    80001fe2:	87248493          	addi	s1,s1,-1934 # 80011850 <proc>
      initlock(&p->lock, "proc");
    80001fe6:	00006d17          	auipc	s10,0x6
    80001fea:	3ead0d13          	addi	s10,s10,1002 # 800083d0 <digits+0x390>
      initlock(&p->lock, "node_lock");
    80001fee:	00006c97          	auipc	s9,0x6
    80001ff2:	3eac8c93          	addi	s9,s9,1002 # 800083d8 <digits+0x398>
      p->kstack = KSTACK((int) (p - proc));
    80001ff6:	8c26                	mv	s8,s1
    80001ff8:	00006b97          	auipc	s7,0x6
    80001ffc:	008b8b93          	addi	s7,s7,8 # 80008000 <etext>
    80002000:	04000a37          	lui	s4,0x4000
    80002004:	1a7d                	addi	s4,s4,-1
    80002006:	0a32                	slli	s4,s4,0xc
  p->next_index = -1;
    80002008:	59fd                	li	s3,-1
      p->index = i;
      initialize_proc(p);
      printf("insert procinit unused %d\n", p->index); //delete
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    8000200a:	00007b17          	auipc	s6,0x7
    8000200e:	bf6b0b13          	addi	s6,s6,-1034 # 80008c00 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002012:	00016a97          	auipc	s5,0x16
    80002016:	c3ea8a93          	addi	s5,s5,-962 # 80017c50 <tickslock>
      initlock(&p->lock, "proc");
    8000201a:	85ea                	mv	a1,s10
    8000201c:	8526                	mv	a0,s1
    8000201e:	fffff097          	auipc	ra,0xfffff
    80002022:	b36080e7          	jalr	-1226(ra) # 80000b54 <initlock>
      initlock(&p->lock, "node_lock");
    80002026:	85e6                	mv	a1,s9
    80002028:	8526                	mv	a0,s1
    8000202a:	fffff097          	auipc	ra,0xfffff
    8000202e:	b2a080e7          	jalr	-1238(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80002032:	418487b3          	sub	a5,s1,s8
    80002036:	8791                	srai	a5,a5,0x4
    80002038:	000bb703          	ld	a4,0(s7)
    8000203c:	02e787b3          	mul	a5,a5,a4
    80002040:	2785                	addiw	a5,a5,1
    80002042:	00d7979b          	slliw	a5,a5,0xd
    80002046:	40fa07b3          	sub	a5,s4,a5
    8000204a:	e0bc                	sd	a5,64(s1)
      p->index = i;
    8000204c:	1724a623          	sw	s2,364(s1)
  p->next_index = -1;
    80002050:	1734aa23          	sw	s3,372(s1)
  p->prev_index = -1;
    80002054:	1734a823          	sw	s3,368(s1)
      printf("insert procinit unused %d\n", p->index); //delete
    80002058:	85ca                	mv	a1,s2
    8000205a:	00006517          	auipc	a0,0x6
    8000205e:	38e50513          	addi	a0,a0,910 # 800083e8 <digits+0x3a8>
    80002062:	ffffe097          	auipc	ra,0xffffe
    80002066:	526080e7          	jalr	1318(ra) # 80000588 <printf>
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    8000206a:	85a6                	mv	a1,s1
    8000206c:	855a                	mv	a0,s6
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	a00080e7          	jalr	-1536(ra) # 80001a6e <insert_proc_to_list>
      i++;
    80002076:	2905                	addiw	s2,s2,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80002078:	19048493          	addi	s1,s1,400
    8000207c:	f9549fe3          	bne	s1,s5,8000201a <procinit+0x92>
  }
}
    80002080:	60e6                	ld	ra,88(sp)
    80002082:	6446                	ld	s0,80(sp)
    80002084:	64a6                	ld	s1,72(sp)
    80002086:	6906                	ld	s2,64(sp)
    80002088:	79e2                	ld	s3,56(sp)
    8000208a:	7a42                	ld	s4,48(sp)
    8000208c:	7aa2                	ld	s5,40(sp)
    8000208e:	7b02                	ld	s6,32(sp)
    80002090:	6be2                	ld	s7,24(sp)
    80002092:	6c42                	ld	s8,16(sp)
    80002094:	6ca2                	ld	s9,8(sp)
    80002096:	6d02                	ld	s10,0(sp)
    80002098:	6125                	addi	sp,sp,96
    8000209a:	8082                	ret

000000008000209c <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000209c:	1141                	addi	sp,sp,-16
    8000209e:	e422                	sd	s0,8(sp)
    800020a0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800020a2:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800020a4:	2501                	sext.w	a0,a0
    800020a6:	6422                	ld	s0,8(sp)
    800020a8:	0141                	addi	sp,sp,16
    800020aa:	8082                	ret

00000000800020ac <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800020ac:	1141                	addi	sp,sp,-16
    800020ae:	e422                	sd	s0,8(sp)
    800020b0:	0800                	addi	s0,sp,16
    800020b2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800020b4:	2781                	sext.w	a5,a5
    800020b6:	0b000513          	li	a0,176
    800020ba:	02a787b3          	mul	a5,a5,a0
  return c;
}
    800020be:	0000f517          	auipc	a0,0xf
    800020c2:	1e250513          	addi	a0,a0,482 # 800112a0 <cpus>
    800020c6:	953e                	add	a0,a0,a5
    800020c8:	6422                	ld	s0,8(sp)
    800020ca:	0141                	addi	sp,sp,16
    800020cc:	8082                	ret

00000000800020ce <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800020ce:	1101                	addi	sp,sp,-32
    800020d0:	ec06                	sd	ra,24(sp)
    800020d2:	e822                	sd	s0,16(sp)
    800020d4:	e426                	sd	s1,8(sp)
    800020d6:	1000                	addi	s0,sp,32
  push_off();
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	ac0080e7          	jalr	-1344(ra) # 80000b98 <push_off>
    800020e0:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800020e2:	2781                	sext.w	a5,a5
    800020e4:	0b000713          	li	a4,176
    800020e8:	02e787b3          	mul	a5,a5,a4
    800020ec:	0000f717          	auipc	a4,0xf
    800020f0:	1b470713          	addi	a4,a4,436 # 800112a0 <cpus>
    800020f4:	97ba                	add	a5,a5,a4
    800020f6:	6384                	ld	s1,0(a5)
  pop_off();
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	b40080e7          	jalr	-1216(ra) # 80000c38 <pop_off>
  return p;
}
    80002100:	8526                	mv	a0,s1
    80002102:	60e2                	ld	ra,24(sp)
    80002104:	6442                	ld	s0,16(sp)
    80002106:	64a2                	ld	s1,8(sp)
    80002108:	6105                	addi	sp,sp,32
    8000210a:	8082                	ret

000000008000210c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    8000210c:	1141                	addi	sp,sp,-16
    8000210e:	e406                	sd	ra,8(sp)
    80002110:	e022                	sd	s0,0(sp)
    80002112:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80002114:	00000097          	auipc	ra,0x0
    80002118:	fba080e7          	jalr	-70(ra) # 800020ce <myproc>
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	b7c080e7          	jalr	-1156(ra) # 80000c98 <release>

  if (first) {
    80002124:	00007797          	auipc	a5,0x7
    80002128:	acc7a783          	lw	a5,-1332(a5) # 80008bf0 <first.1787>
    8000212c:	eb89                	bnez	a5,8000213e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    8000212e:	00001097          	auipc	ra,0x1
    80002132:	1c4080e7          	jalr	452(ra) # 800032f2 <usertrapret>
}
    80002136:	60a2                	ld	ra,8(sp)
    80002138:	6402                	ld	s0,0(sp)
    8000213a:	0141                	addi	sp,sp,16
    8000213c:	8082                	ret
    first = 0;
    8000213e:	00007797          	auipc	a5,0x7
    80002142:	aa07a923          	sw	zero,-1358(a5) # 80008bf0 <first.1787>
    fsinit(ROOTDEV);
    80002146:	4505                	li	a0,1
    80002148:	00002097          	auipc	ra,0x2
    8000214c:	f68080e7          	jalr	-152(ra) # 800040b0 <fsinit>
    80002150:	bff9                	j	8000212e <forkret+0x22>

0000000080002152 <allocpid>:
allocpid() {
    80002152:	1101                	addi	sp,sp,-32
    80002154:	ec06                	sd	ra,24(sp)
    80002156:	e822                	sd	s0,16(sp)
    80002158:	e426                	sd	s1,8(sp)
    8000215a:	e04a                	sd	s2,0(sp)
    8000215c:	1000                	addi	s0,sp,32
    pid = nextpid;
    8000215e:	00007917          	auipc	s2,0x7
    80002162:	a9690913          	addi	s2,s2,-1386 # 80008bf4 <nextpid>
    80002166:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, nextpid + 1));
    8000216a:	0014861b          	addiw	a2,s1,1
    8000216e:	85a6                	mv	a1,s1
    80002170:	854a                	mv	a0,s2
    80002172:	00005097          	auipc	ra,0x5
    80002176:	d44080e7          	jalr	-700(ra) # 80006eb6 <cas>
    8000217a:	2501                	sext.w	a0,a0
    8000217c:	f56d                	bnez	a0,80002166 <allocpid+0x14>
}
    8000217e:	8526                	mv	a0,s1
    80002180:	60e2                	ld	ra,24(sp)
    80002182:	6442                	ld	s0,16(sp)
    80002184:	64a2                	ld	s1,8(sp)
    80002186:	6902                	ld	s2,0(sp)
    80002188:	6105                	addi	sp,sp,32
    8000218a:	8082                	ret

000000008000218c <proc_pagetable>:
{
    8000218c:	1101                	addi	sp,sp,-32
    8000218e:	ec06                	sd	ra,24(sp)
    80002190:	e822                	sd	s0,16(sp)
    80002192:	e426                	sd	s1,8(sp)
    80002194:	e04a                	sd	s2,0(sp)
    80002196:	1000                	addi	s0,sp,32
    80002198:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	1a0080e7          	jalr	416(ra) # 8000133a <uvmcreate>
    800021a2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800021a4:	c121                	beqz	a0,800021e4 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800021a6:	4729                	li	a4,10
    800021a8:	00005697          	auipc	a3,0x5
    800021ac:	e5868693          	addi	a3,a3,-424 # 80007000 <_trampoline>
    800021b0:	6605                	lui	a2,0x1
    800021b2:	040005b7          	lui	a1,0x4000
    800021b6:	15fd                	addi	a1,a1,-1
    800021b8:	05b2                	slli	a1,a1,0xc
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	ef6080e7          	jalr	-266(ra) # 800010b0 <mappages>
    800021c2:	02054863          	bltz	a0,800021f2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    800021c6:	4719                	li	a4,6
    800021c8:	05893683          	ld	a3,88(s2)
    800021cc:	6605                	lui	a2,0x1
    800021ce:	020005b7          	lui	a1,0x2000
    800021d2:	15fd                	addi	a1,a1,-1
    800021d4:	05b6                	slli	a1,a1,0xd
    800021d6:	8526                	mv	a0,s1
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	ed8080e7          	jalr	-296(ra) # 800010b0 <mappages>
    800021e0:	02054163          	bltz	a0,80002202 <proc_pagetable+0x76>
}
    800021e4:	8526                	mv	a0,s1
    800021e6:	60e2                	ld	ra,24(sp)
    800021e8:	6442                	ld	s0,16(sp)
    800021ea:	64a2                	ld	s1,8(sp)
    800021ec:	6902                	ld	s2,0(sp)
    800021ee:	6105                	addi	sp,sp,32
    800021f0:	8082                	ret
    uvmfree(pagetable, 0);
    800021f2:	4581                	li	a1,0
    800021f4:	8526                	mv	a0,s1
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	340080e7          	jalr	832(ra) # 80001536 <uvmfree>
    return 0;
    800021fe:	4481                	li	s1,0
    80002200:	b7d5                	j	800021e4 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002202:	4681                	li	a3,0
    80002204:	4605                	li	a2,1
    80002206:	040005b7          	lui	a1,0x4000
    8000220a:	15fd                	addi	a1,a1,-1
    8000220c:	05b2                	slli	a1,a1,0xc
    8000220e:	8526                	mv	a0,s1
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	066080e7          	jalr	102(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80002218:	4581                	li	a1,0
    8000221a:	8526                	mv	a0,s1
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	31a080e7          	jalr	794(ra) # 80001536 <uvmfree>
    return 0;
    80002224:	4481                	li	s1,0
    80002226:	bf7d                	j	800021e4 <proc_pagetable+0x58>

0000000080002228 <proc_freepagetable>:
{
    80002228:	1101                	addi	sp,sp,-32
    8000222a:	ec06                	sd	ra,24(sp)
    8000222c:	e822                	sd	s0,16(sp)
    8000222e:	e426                	sd	s1,8(sp)
    80002230:	e04a                	sd	s2,0(sp)
    80002232:	1000                	addi	s0,sp,32
    80002234:	84aa                	mv	s1,a0
    80002236:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002238:	4681                	li	a3,0
    8000223a:	4605                	li	a2,1
    8000223c:	040005b7          	lui	a1,0x4000
    80002240:	15fd                	addi	a1,a1,-1
    80002242:	05b2                	slli	a1,a1,0xc
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	032080e7          	jalr	50(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    8000224c:	4681                	li	a3,0
    8000224e:	4605                	li	a2,1
    80002250:	020005b7          	lui	a1,0x2000
    80002254:	15fd                	addi	a1,a1,-1
    80002256:	05b6                	slli	a1,a1,0xd
    80002258:	8526                	mv	a0,s1
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	01c080e7          	jalr	28(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80002262:	85ca                	mv	a1,s2
    80002264:	8526                	mv	a0,s1
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	2d0080e7          	jalr	720(ra) # 80001536 <uvmfree>
}
    8000226e:	60e2                	ld	ra,24(sp)
    80002270:	6442                	ld	s0,16(sp)
    80002272:	64a2                	ld	s1,8(sp)
    80002274:	6902                	ld	s2,0(sp)
    80002276:	6105                	addi	sp,sp,32
    80002278:	8082                	ret

000000008000227a <freeproc>:
{
    8000227a:	1101                	addi	sp,sp,-32
    8000227c:	ec06                	sd	ra,24(sp)
    8000227e:	e822                	sd	s0,16(sp)
    80002280:	e426                	sd	s1,8(sp)
    80002282:	1000                	addi	s0,sp,32
    80002284:	84aa                	mv	s1,a0
  if(p->trapframe)
    80002286:	6d28                	ld	a0,88(a0)
    80002288:	c509                	beqz	a0,80002292 <freeproc+0x18>
    kfree((void*)p->trapframe);
    8000228a:	ffffe097          	auipc	ra,0xffffe
    8000228e:	76e080e7          	jalr	1902(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80002292:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80002296:	68a8                	ld	a0,80(s1)
    80002298:	c511                	beqz	a0,800022a4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    8000229a:	64ac                	ld	a1,72(s1)
    8000229c:	00000097          	auipc	ra,0x0
    800022a0:	f8c080e7          	jalr	-116(ra) # 80002228 <proc_freepagetable>
  p->pagetable = 0;
    800022a4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    800022a8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    800022ac:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    800022b0:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    800022b4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    800022b8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    800022bc:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    800022c0:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    800022c4:	0004ac23          	sw	zero,24(s1)
  printf("remove freeproc zombie %d\n", p->index); //delete
    800022c8:	16c4a583          	lw	a1,364(s1)
    800022cc:	00006517          	auipc	a0,0x6
    800022d0:	13c50513          	addi	a0,a0,316 # 80008408 <digits+0x3c8>
    800022d4:	ffffe097          	auipc	ra,0xffffe
    800022d8:	2b4080e7          	jalr	692(ra) # 80000588 <printf>
  remove_proc_to_list(&zombie_list, p); // remove the freed process from the ZOMBIE list
    800022dc:	85a6                	mv	a1,s1
    800022de:	00007517          	auipc	a0,0x7
    800022e2:	96250513          	addi	a0,a0,-1694 # 80008c40 <zombie_list>
    800022e6:	00000097          	auipc	ra,0x0
    800022ea:	a10080e7          	jalr	-1520(ra) # 80001cf6 <remove_proc_to_list>
  printf("insert freeproc unused %d\n", p->index); //delete
    800022ee:	16c4a583          	lw	a1,364(s1)
    800022f2:	00006517          	auipc	a0,0x6
    800022f6:	13650513          	addi	a0,a0,310 # 80008428 <digits+0x3e8>
    800022fa:	ffffe097          	auipc	ra,0xffffe
    800022fe:	28e080e7          	jalr	654(ra) # 80000588 <printf>
  insert_proc_to_list(&unused_list, p); // admit its entry to the UNUSED entry list.
    80002302:	85a6                	mv	a1,s1
    80002304:	00007517          	auipc	a0,0x7
    80002308:	8fc50513          	addi	a0,a0,-1796 # 80008c00 <unused_list>
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	762080e7          	jalr	1890(ra) # 80001a6e <insert_proc_to_list>
}
    80002314:	60e2                	ld	ra,24(sp)
    80002316:	6442                	ld	s0,16(sp)
    80002318:	64a2                	ld	s1,8(sp)
    8000231a:	6105                	addi	sp,sp,32
    8000231c:	8082                	ret

000000008000231e <allocproc>:
{
    8000231e:	715d                	addi	sp,sp,-80
    80002320:	e486                	sd	ra,72(sp)
    80002322:	e0a2                	sd	s0,64(sp)
    80002324:	fc26                	sd	s1,56(sp)
    80002326:	f84a                	sd	s2,48(sp)
    80002328:	f44e                	sd	s3,40(sp)
    8000232a:	f052                	sd	s4,32(sp)
    8000232c:	ec56                	sd	s5,24(sp)
    8000232e:	e85a                	sd	s6,16(sp)
    80002330:	e45e                	sd	s7,8(sp)
    80002332:	0880                	addi	s0,sp,80
  while(!isEmpty(&unused_list)){
    80002334:	00007717          	auipc	a4,0x7
    80002338:	8cc72703          	lw	a4,-1844(a4) # 80008c00 <unused_list>
    8000233c:	57fd                	li	a5,-1
    8000233e:	14f70a63          	beq	a4,a5,80002492 <allocproc+0x174>
    p = &proc[get_head(&unused_list)];
    80002342:	00007a17          	auipc	s4,0x7
    80002346:	8bea0a13          	addi	s4,s4,-1858 # 80008c00 <unused_list>
    8000234a:	19000b13          	li	s6,400
    8000234e:	0000fa97          	auipc	s5,0xf
    80002352:	502a8a93          	addi	s5,s5,1282 # 80011850 <proc>
  while(!isEmpty(&unused_list)){
    80002356:	5bfd                	li	s7,-1
    p = &proc[get_head(&unused_list)];
    80002358:	8552                	mv	a0,s4
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	6be080e7          	jalr	1726(ra) # 80001a18 <get_head>
    80002362:	892a                	mv	s2,a0
    80002364:	036509b3          	mul	s3,a0,s6
    80002368:	015984b3          	add	s1,s3,s5
    acquire(&p->lock);
    8000236c:	8526                	mv	a0,s1
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	876080e7          	jalr	-1930(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80002376:	4c9c                	lw	a5,24(s1)
    80002378:	c79d                	beqz	a5,800023a6 <allocproc+0x88>
      release(&p->lock);
    8000237a:	8526                	mv	a0,s1
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	91c080e7          	jalr	-1764(ra) # 80000c98 <release>
  while(!isEmpty(&unused_list)){
    80002384:	000a2783          	lw	a5,0(s4)
    80002388:	fd7798e3          	bne	a5,s7,80002358 <allocproc+0x3a>
  return 0;
    8000238c:	4481                	li	s1,0
}
    8000238e:	8526                	mv	a0,s1
    80002390:	60a6                	ld	ra,72(sp)
    80002392:	6406                	ld	s0,64(sp)
    80002394:	74e2                	ld	s1,56(sp)
    80002396:	7942                	ld	s2,48(sp)
    80002398:	79a2                	ld	s3,40(sp)
    8000239a:	7a02                	ld	s4,32(sp)
    8000239c:	6ae2                	ld	s5,24(sp)
    8000239e:	6b42                	ld	s6,16(sp)
    800023a0:	6ba2                	ld	s7,8(sp)
    800023a2:	6161                	addi	sp,sp,80
    800023a4:	8082                	ret
      printf("remove allocpric unused %d\n", p->index); //delete
    800023a6:	19000a13          	li	s4,400
    800023aa:	034907b3          	mul	a5,s2,s4
    800023ae:	0000fa17          	auipc	s4,0xf
    800023b2:	4a2a0a13          	addi	s4,s4,1186 # 80011850 <proc>
    800023b6:	9a3e                	add	s4,s4,a5
    800023b8:	16ca2583          	lw	a1,364(s4)
    800023bc:	00006517          	auipc	a0,0x6
    800023c0:	08c50513          	addi	a0,a0,140 # 80008448 <digits+0x408>
    800023c4:	ffffe097          	auipc	ra,0xffffe
    800023c8:	1c4080e7          	jalr	452(ra) # 80000588 <printf>
      remove_proc_to_list(&unused_list, p); // choose the new process entry to initialize from the UNUSED entry list.
    800023cc:	85a6                	mv	a1,s1
    800023ce:	00007517          	auipc	a0,0x7
    800023d2:	83250513          	addi	a0,a0,-1998 # 80008c00 <unused_list>
    800023d6:	00000097          	auipc	ra,0x0
    800023da:	920080e7          	jalr	-1760(ra) # 80001cf6 <remove_proc_to_list>
  p->pid = allocpid();
    800023de:	00000097          	auipc	ra,0x0
    800023e2:	d74080e7          	jalr	-652(ra) # 80002152 <allocpid>
    800023e6:	02aa2823          	sw	a0,48(s4)
  p->state = USED;
    800023ea:	4785                	li	a5,1
    800023ec:	00fa2c23          	sw	a5,24(s4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800023f0:	ffffe097          	auipc	ra,0xffffe
    800023f4:	704080e7          	jalr	1796(ra) # 80000af4 <kalloc>
    800023f8:	8aaa                	mv	s5,a0
    800023fa:	04aa3c23          	sd	a0,88(s4)
    800023fe:	c135                	beqz	a0,80002462 <allocproc+0x144>
  p->pagetable = proc_pagetable(p);
    80002400:	8526                	mv	a0,s1
    80002402:	00000097          	auipc	ra,0x0
    80002406:	d8a080e7          	jalr	-630(ra) # 8000218c <proc_pagetable>
    8000240a:	8a2a                	mv	s4,a0
    8000240c:	19000793          	li	a5,400
    80002410:	02f90733          	mul	a4,s2,a5
    80002414:	0000f797          	auipc	a5,0xf
    80002418:	43c78793          	addi	a5,a5,1084 # 80011850 <proc>
    8000241c:	97ba                	add	a5,a5,a4
    8000241e:	eba8                	sd	a0,80(a5)
  if(p->pagetable == 0){
    80002420:	cd29                	beqz	a0,8000247a <allocproc+0x15c>
  memset(&p->context, 0, sizeof(p->context));
    80002422:	06098513          	addi	a0,s3,96
    80002426:	0000f997          	auipc	s3,0xf
    8000242a:	42a98993          	addi	s3,s3,1066 # 80011850 <proc>
    8000242e:	07000613          	li	a2,112
    80002432:	4581                	li	a1,0
    80002434:	954e                	add	a0,a0,s3
    80002436:	fffff097          	auipc	ra,0xfffff
    8000243a:	8aa080e7          	jalr	-1878(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    8000243e:	19000793          	li	a5,400
    80002442:	02f90933          	mul	s2,s2,a5
    80002446:	994e                	add	s2,s2,s3
    80002448:	00000797          	auipc	a5,0x0
    8000244c:	cc478793          	addi	a5,a5,-828 # 8000210c <forkret>
    80002450:	06f93023          	sd	a5,96(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002454:	04093783          	ld	a5,64(s2)
    80002458:	6705                	lui	a4,0x1
    8000245a:	97ba                	add	a5,a5,a4
    8000245c:	06f93423          	sd	a5,104(s2)
  return p;
    80002460:	b73d                	j	8000238e <allocproc+0x70>
    freeproc(p);
    80002462:	8526                	mv	a0,s1
    80002464:	00000097          	auipc	ra,0x0
    80002468:	e16080e7          	jalr	-490(ra) # 8000227a <freeproc>
    release(&p->lock);
    8000246c:	8526                	mv	a0,s1
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	82a080e7          	jalr	-2006(ra) # 80000c98 <release>
    return 0;
    80002476:	84d6                	mv	s1,s5
    80002478:	bf19                	j	8000238e <allocproc+0x70>
    freeproc(p);
    8000247a:	8526                	mv	a0,s1
    8000247c:	00000097          	auipc	ra,0x0
    80002480:	dfe080e7          	jalr	-514(ra) # 8000227a <freeproc>
    release(&p->lock);
    80002484:	8526                	mv	a0,s1
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	812080e7          	jalr	-2030(ra) # 80000c98 <release>
    return 0;
    8000248e:	84d2                	mv	s1,s4
    80002490:	bdfd                	j	8000238e <allocproc+0x70>
  return 0;
    80002492:	4481                	li	s1,0
    80002494:	bded                	j	8000238e <allocproc+0x70>

0000000080002496 <userinit>:
{
    80002496:	1101                	addi	sp,sp,-32
    80002498:	ec06                	sd	ra,24(sp)
    8000249a:	e822                	sd	s0,16(sp)
    8000249c:	e426                	sd	s1,8(sp)
    8000249e:	1000                	addi	s0,sp,32
  p = allocproc();
    800024a0:	00000097          	auipc	ra,0x0
    800024a4:	e7e080e7          	jalr	-386(ra) # 8000231e <allocproc>
    800024a8:	84aa                	mv	s1,a0
  initproc = p;
    800024aa:	00007797          	auipc	a5,0x7
    800024ae:	b6a7bf23          	sd	a0,-1154(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800024b2:	03400613          	li	a2,52
    800024b6:	00006597          	auipc	a1,0x6
    800024ba:	7aa58593          	addi	a1,a1,1962 # 80008c60 <initcode>
    800024be:	6928                	ld	a0,80(a0)
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	ea8080e7          	jalr	-344(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    800024c8:	6785                	lui	a5,0x1
    800024ca:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    800024cc:	6cb8                	ld	a4,88(s1)
    800024ce:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800024d2:	6cb8                	ld	a4,88(s1)
    800024d4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800024d6:	4641                	li	a2,16
    800024d8:	00006597          	auipc	a1,0x6
    800024dc:	f9058593          	addi	a1,a1,-112 # 80008468 <digits+0x428>
    800024e0:	15848513          	addi	a0,s1,344
    800024e4:	fffff097          	auipc	ra,0xfffff
    800024e8:	94e080e7          	jalr	-1714(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800024ec:	00006517          	auipc	a0,0x6
    800024f0:	f8c50513          	addi	a0,a0,-116 # 80008478 <digits+0x438>
    800024f4:	00002097          	auipc	ra,0x2
    800024f8:	5ea080e7          	jalr	1514(ra) # 80004ade <namei>
    800024fc:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80002500:	478d                	li	a5,3
    80002502:	cc9c                	sw	a5,24(s1)
  printf("insert userinit runnable %d\n", p->index); //delete
    80002504:	16c4a583          	lw	a1,364(s1)
    80002508:	00006517          	auipc	a0,0x6
    8000250c:	f7850513          	addi	a0,a0,-136 # 80008480 <digits+0x440>
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	078080e7          	jalr	120(ra) # 80000588 <printf>
  insert_proc_to_list(&(cpus[0].runnable_list), p); // admit the init process (the first process in the OS) to the first CPU’s list.
    80002518:	85a6                	mv	a1,s1
    8000251a:	0000f517          	auipc	a0,0xf
    8000251e:	e0650513          	addi	a0,a0,-506 # 80011320 <cpus+0x80>
    80002522:	fffff097          	auipc	ra,0xfffff
    80002526:	54c080e7          	jalr	1356(ra) # 80001a6e <insert_proc_to_list>
  release(&p->lock);
    8000252a:	8526                	mv	a0,s1
    8000252c:	ffffe097          	auipc	ra,0xffffe
    80002530:	76c080e7          	jalr	1900(ra) # 80000c98 <release>
}
    80002534:	60e2                	ld	ra,24(sp)
    80002536:	6442                	ld	s0,16(sp)
    80002538:	64a2                	ld	s1,8(sp)
    8000253a:	6105                	addi	sp,sp,32
    8000253c:	8082                	ret

000000008000253e <growproc>:
{
    8000253e:	1101                	addi	sp,sp,-32
    80002540:	ec06                	sd	ra,24(sp)
    80002542:	e822                	sd	s0,16(sp)
    80002544:	e426                	sd	s1,8(sp)
    80002546:	e04a                	sd	s2,0(sp)
    80002548:	1000                	addi	s0,sp,32
    8000254a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000254c:	00000097          	auipc	ra,0x0
    80002550:	b82080e7          	jalr	-1150(ra) # 800020ce <myproc>
    80002554:	892a                	mv	s2,a0
  sz = p->sz;
    80002556:	652c                	ld	a1,72(a0)
    80002558:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000255c:	00904f63          	bgtz	s1,8000257a <growproc+0x3c>
  } else if(n < 0){
    80002560:	0204cc63          	bltz	s1,80002598 <growproc+0x5a>
  p->sz = sz;
    80002564:	1602                	slli	a2,a2,0x20
    80002566:	9201                	srli	a2,a2,0x20
    80002568:	04c93423          	sd	a2,72(s2)
  return 0;
    8000256c:	4501                	li	a0,0
}
    8000256e:	60e2                	ld	ra,24(sp)
    80002570:	6442                	ld	s0,16(sp)
    80002572:	64a2                	ld	s1,8(sp)
    80002574:	6902                	ld	s2,0(sp)
    80002576:	6105                	addi	sp,sp,32
    80002578:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000257a:	9e25                	addw	a2,a2,s1
    8000257c:	1602                	slli	a2,a2,0x20
    8000257e:	9201                	srli	a2,a2,0x20
    80002580:	1582                	slli	a1,a1,0x20
    80002582:	9181                	srli	a1,a1,0x20
    80002584:	6928                	ld	a0,80(a0)
    80002586:	fffff097          	auipc	ra,0xfffff
    8000258a:	e9c080e7          	jalr	-356(ra) # 80001422 <uvmalloc>
    8000258e:	0005061b          	sext.w	a2,a0
    80002592:	fa69                	bnez	a2,80002564 <growproc+0x26>
      return -1;
    80002594:	557d                	li	a0,-1
    80002596:	bfe1                	j	8000256e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002598:	9e25                	addw	a2,a2,s1
    8000259a:	1602                	slli	a2,a2,0x20
    8000259c:	9201                	srli	a2,a2,0x20
    8000259e:	1582                	slli	a1,a1,0x20
    800025a0:	9181                	srli	a1,a1,0x20
    800025a2:	6928                	ld	a0,80(a0)
    800025a4:	fffff097          	auipc	ra,0xfffff
    800025a8:	e36080e7          	jalr	-458(ra) # 800013da <uvmdealloc>
    800025ac:	0005061b          	sext.w	a2,a0
    800025b0:	bf55                	j	80002564 <growproc+0x26>

00000000800025b2 <sched>:
{
    800025b2:	7179                	addi	sp,sp,-48
    800025b4:	f406                	sd	ra,40(sp)
    800025b6:	f022                	sd	s0,32(sp)
    800025b8:	ec26                	sd	s1,24(sp)
    800025ba:	e84a                	sd	s2,16(sp)
    800025bc:	e44e                	sd	s3,8(sp)
    800025be:	e052                	sd	s4,0(sp)
    800025c0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800025c2:	00000097          	auipc	ra,0x0
    800025c6:	b0c080e7          	jalr	-1268(ra) # 800020ce <myproc>
    800025ca:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	59e080e7          	jalr	1438(ra) # 80000b6a <holding>
    800025d4:	c141                	beqz	a0,80002654 <sched+0xa2>
    800025d6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800025d8:	2781                	sext.w	a5,a5
    800025da:	0b000713          	li	a4,176
    800025de:	02e787b3          	mul	a5,a5,a4
    800025e2:	0000f717          	auipc	a4,0xf
    800025e6:	cbe70713          	addi	a4,a4,-834 # 800112a0 <cpus>
    800025ea:	97ba                	add	a5,a5,a4
    800025ec:	5fb8                	lw	a4,120(a5)
    800025ee:	4785                	li	a5,1
    800025f0:	06f71a63          	bne	a4,a5,80002664 <sched+0xb2>
  if(p->state == RUNNING)
    800025f4:	4c98                	lw	a4,24(s1)
    800025f6:	4791                	li	a5,4
    800025f8:	06f70e63          	beq	a4,a5,80002674 <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025fc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002600:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002602:	e3c9                	bnez	a5,80002684 <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002604:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002606:	0000f917          	auipc	s2,0xf
    8000260a:	c9a90913          	addi	s2,s2,-870 # 800112a0 <cpus>
    8000260e:	2781                	sext.w	a5,a5
    80002610:	0b000993          	li	s3,176
    80002614:	033787b3          	mul	a5,a5,s3
    80002618:	97ca                	add	a5,a5,s2
    8000261a:	07c7aa03          	lw	s4,124(a5) # 107c <_entry-0x7fffef84>
    8000261e:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    80002620:	2581                	sext.w	a1,a1
    80002622:	033585b3          	mul	a1,a1,s3
    80002626:	05a1                	addi	a1,a1,8
    80002628:	95ca                	add	a1,a1,s2
    8000262a:	06048513          	addi	a0,s1,96
    8000262e:	00001097          	auipc	ra,0x1
    80002632:	c1a080e7          	jalr	-998(ra) # 80003248 <swtch>
    80002636:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002638:	2781                	sext.w	a5,a5
    8000263a:	033787b3          	mul	a5,a5,s3
    8000263e:	993e                	add	s2,s2,a5
    80002640:	07492e23          	sw	s4,124(s2)
}
    80002644:	70a2                	ld	ra,40(sp)
    80002646:	7402                	ld	s0,32(sp)
    80002648:	64e2                	ld	s1,24(sp)
    8000264a:	6942                	ld	s2,16(sp)
    8000264c:	69a2                	ld	s3,8(sp)
    8000264e:	6a02                	ld	s4,0(sp)
    80002650:	6145                	addi	sp,sp,48
    80002652:	8082                	ret
    panic("sched p->lock");
    80002654:	00006517          	auipc	a0,0x6
    80002658:	e4c50513          	addi	a0,a0,-436 # 800084a0 <digits+0x460>
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	ee2080e7          	jalr	-286(ra) # 8000053e <panic>
    panic("sched locks");
    80002664:	00006517          	auipc	a0,0x6
    80002668:	e4c50513          	addi	a0,a0,-436 # 800084b0 <digits+0x470>
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	ed2080e7          	jalr	-302(ra) # 8000053e <panic>
    panic("sched running");
    80002674:	00006517          	auipc	a0,0x6
    80002678:	e4c50513          	addi	a0,a0,-436 # 800084c0 <digits+0x480>
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	ec2080e7          	jalr	-318(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002684:	00006517          	auipc	a0,0x6
    80002688:	e4c50513          	addi	a0,a0,-436 # 800084d0 <digits+0x490>
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	eb2080e7          	jalr	-334(ra) # 8000053e <panic>

0000000080002694 <yield>:
{
    80002694:	1101                	addi	sp,sp,-32
    80002696:	ec06                	sd	ra,24(sp)
    80002698:	e822                	sd	s0,16(sp)
    8000269a:	e426                	sd	s1,8(sp)
    8000269c:	e04a                	sd	s2,0(sp)
    8000269e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800026a0:	00000097          	auipc	ra,0x0
    800026a4:	a2e080e7          	jalr	-1490(ra) # 800020ce <myproc>
    800026a8:	84aa                	mv	s1,a0
    800026aa:	8912                	mv	s2,tp
  acquire(&p->lock);
    800026ac:	ffffe097          	auipc	ra,0xffffe
    800026b0:	538080e7          	jalr	1336(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800026b4:	478d                	li	a5,3
    800026b6:	cc9c                	sw	a5,24(s1)
  printf("insert yield runnable %d\n", p->index); //delete
    800026b8:	16c4a583          	lw	a1,364(s1)
    800026bc:	00006517          	auipc	a0,0x6
    800026c0:	e2c50513          	addi	a0,a0,-468 # 800084e8 <digits+0x4a8>
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	ec4080e7          	jalr	-316(ra) # 80000588 <printf>
  insert_proc_to_list(&(c->runnable_list), p); // TODO: check
    800026cc:	2901                	sext.w	s2,s2
    800026ce:	0b000513          	li	a0,176
    800026d2:	02a90933          	mul	s2,s2,a0
    800026d6:	85a6                	mv	a1,s1
    800026d8:	0000f517          	auipc	a0,0xf
    800026dc:	c4850513          	addi	a0,a0,-952 # 80011320 <cpus+0x80>
    800026e0:	954a                	add	a0,a0,s2
    800026e2:	fffff097          	auipc	ra,0xfffff
    800026e6:	38c080e7          	jalr	908(ra) # 80001a6e <insert_proc_to_list>
  sched();
    800026ea:	00000097          	auipc	ra,0x0
    800026ee:	ec8080e7          	jalr	-312(ra) # 800025b2 <sched>
  release(&p->lock);
    800026f2:	8526                	mv	a0,s1
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	5a4080e7          	jalr	1444(ra) # 80000c98 <release>
}
    800026fc:	60e2                	ld	ra,24(sp)
    800026fe:	6442                	ld	s0,16(sp)
    80002700:	64a2                	ld	s1,8(sp)
    80002702:	6902                	ld	s2,0(sp)
    80002704:	6105                	addi	sp,sp,32
    80002706:	8082                	ret

0000000080002708 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002708:	7179                	addi	sp,sp,-48
    8000270a:	f406                	sd	ra,40(sp)
    8000270c:	f022                	sd	s0,32(sp)
    8000270e:	ec26                	sd	s1,24(sp)
    80002710:	e84a                	sd	s2,16(sp)
    80002712:	e44e                	sd	s3,8(sp)
    80002714:	1800                	addi	s0,sp,48
    80002716:	89aa                	mv	s3,a0
    80002718:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000271a:	00000097          	auipc	ra,0x0
    8000271e:	9b4080e7          	jalr	-1612(ra) # 800020ce <myproc>
    80002722:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	4c0080e7          	jalr	1216(ra) # 80000be4 <acquire>
  printf("insert sleep sleep %d\n", p->index); //delete
    8000272c:	16c4a583          	lw	a1,364(s1)
    80002730:	00006517          	auipc	a0,0x6
    80002734:	dd850513          	addi	a0,a0,-552 # 80008508 <digits+0x4c8>
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	e50080e7          	jalr	-432(ra) # 80000588 <printf>
  insert_proc_to_list(&sleeping_list, p);
    80002740:	85a6                	mv	a1,s1
    80002742:	00006517          	auipc	a0,0x6
    80002746:	4de50513          	addi	a0,a0,1246 # 80008c20 <sleeping_list>
    8000274a:	fffff097          	auipc	ra,0xfffff
    8000274e:	324080e7          	jalr	804(ra) # 80001a6e <insert_proc_to_list>
  release(lk);
    80002752:	854a                	mv	a0,s2
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	544080e7          	jalr	1348(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000275c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002760:	4789                	li	a5,2
    80002762:	cc9c                	sw	a5,24(s1)

  sched();
    80002764:	00000097          	auipc	ra,0x0
    80002768:	e4e080e7          	jalr	-434(ra) # 800025b2 <sched>

  // Tidy up.
  p->chan = 0;
    8000276c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002770:	8526                	mv	a0,s1
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	526080e7          	jalr	1318(ra) # 80000c98 <release>
  acquire(lk);
    8000277a:	854a                	mv	a0,s2
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	468080e7          	jalr	1128(ra) # 80000be4 <acquire>
}
    80002784:	70a2                	ld	ra,40(sp)
    80002786:	7402                	ld	s0,32(sp)
    80002788:	64e2                	ld	s1,24(sp)
    8000278a:	6942                	ld	s2,16(sp)
    8000278c:	69a2                	ld	s3,8(sp)
    8000278e:	6145                	addi	sp,sp,48
    80002790:	8082                	ret

0000000080002792 <wait>:
{
    80002792:	715d                	addi	sp,sp,-80
    80002794:	e486                	sd	ra,72(sp)
    80002796:	e0a2                	sd	s0,64(sp)
    80002798:	fc26                	sd	s1,56(sp)
    8000279a:	f84a                	sd	s2,48(sp)
    8000279c:	f44e                	sd	s3,40(sp)
    8000279e:	f052                	sd	s4,32(sp)
    800027a0:	ec56                	sd	s5,24(sp)
    800027a2:	e85a                	sd	s6,16(sp)
    800027a4:	e45e                	sd	s7,8(sp)
    800027a6:	e062                	sd	s8,0(sp)
    800027a8:	0880                	addi	s0,sp,80
    800027aa:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800027ac:	00000097          	auipc	ra,0x0
    800027b0:	922080e7          	jalr	-1758(ra) # 800020ce <myproc>
    800027b4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800027b6:	0000f517          	auipc	a0,0xf
    800027ba:	08250513          	addi	a0,a0,130 # 80011838 <wait_lock>
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	426080e7          	jalr	1062(ra) # 80000be4 <acquire>
    havekids = 0;
    800027c6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800027c8:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800027ca:	00015997          	auipc	s3,0x15
    800027ce:	48698993          	addi	s3,s3,1158 # 80017c50 <tickslock>
        havekids = 1;
    800027d2:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800027d4:	0000fc17          	auipc	s8,0xf
    800027d8:	064c0c13          	addi	s8,s8,100 # 80011838 <wait_lock>
    havekids = 0;
    800027dc:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800027de:	0000f497          	auipc	s1,0xf
    800027e2:	07248493          	addi	s1,s1,114 # 80011850 <proc>
    800027e6:	a0bd                	j	80002854 <wait+0xc2>
          pid = np->pid;
    800027e8:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027ec:	000b0e63          	beqz	s6,80002808 <wait+0x76>
    800027f0:	4691                	li	a3,4
    800027f2:	02c48613          	addi	a2,s1,44
    800027f6:	85da                	mv	a1,s6
    800027f8:	05093503          	ld	a0,80(s2)
    800027fc:	fffff097          	auipc	ra,0xfffff
    80002800:	e76080e7          	jalr	-394(ra) # 80001672 <copyout>
    80002804:	02054563          	bltz	a0,8000282e <wait+0x9c>
          freeproc(np);
    80002808:	8526                	mv	a0,s1
    8000280a:	00000097          	auipc	ra,0x0
    8000280e:	a70080e7          	jalr	-1424(ra) # 8000227a <freeproc>
          release(&np->lock);
    80002812:	8526                	mv	a0,s1
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	484080e7          	jalr	1156(ra) # 80000c98 <release>
          release(&wait_lock);
    8000281c:	0000f517          	auipc	a0,0xf
    80002820:	01c50513          	addi	a0,a0,28 # 80011838 <wait_lock>
    80002824:	ffffe097          	auipc	ra,0xffffe
    80002828:	474080e7          	jalr	1140(ra) # 80000c98 <release>
          return pid;
    8000282c:	a09d                	j	80002892 <wait+0x100>
            release(&np->lock);
    8000282e:	8526                	mv	a0,s1
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	468080e7          	jalr	1128(ra) # 80000c98 <release>
            release(&wait_lock);
    80002838:	0000f517          	auipc	a0,0xf
    8000283c:	00050513          	mv	a0,a0
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	458080e7          	jalr	1112(ra) # 80000c98 <release>
            return -1;
    80002848:	59fd                	li	s3,-1
    8000284a:	a0a1                	j	80002892 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000284c:	19048493          	addi	s1,s1,400
    80002850:	03348463          	beq	s1,s3,80002878 <wait+0xe6>
      if(np->parent == p){
    80002854:	7c9c                	ld	a5,56(s1)
    80002856:	ff279be3          	bne	a5,s2,8000284c <wait+0xba>
        acquire(&np->lock);
    8000285a:	8526                	mv	a0,s1
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	388080e7          	jalr	904(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002864:	4c9c                	lw	a5,24(s1)
    80002866:	f94781e3          	beq	a5,s4,800027e8 <wait+0x56>
        release(&np->lock);
    8000286a:	8526                	mv	a0,s1
    8000286c:	ffffe097          	auipc	ra,0xffffe
    80002870:	42c080e7          	jalr	1068(ra) # 80000c98 <release>
        havekids = 1;
    80002874:	8756                	mv	a4,s5
    80002876:	bfd9                	j	8000284c <wait+0xba>
    if(!havekids || p->killed){
    80002878:	c701                	beqz	a4,80002880 <wait+0xee>
    8000287a:	02892783          	lw	a5,40(s2)
    8000287e:	c79d                	beqz	a5,800028ac <wait+0x11a>
      release(&wait_lock);
    80002880:	0000f517          	auipc	a0,0xf
    80002884:	fb850513          	addi	a0,a0,-72 # 80011838 <wait_lock>
    80002888:	ffffe097          	auipc	ra,0xffffe
    8000288c:	410080e7          	jalr	1040(ra) # 80000c98 <release>
      return -1;
    80002890:	59fd                	li	s3,-1
}
    80002892:	854e                	mv	a0,s3
    80002894:	60a6                	ld	ra,72(sp)
    80002896:	6406                	ld	s0,64(sp)
    80002898:	74e2                	ld	s1,56(sp)
    8000289a:	7942                	ld	s2,48(sp)
    8000289c:	79a2                	ld	s3,40(sp)
    8000289e:	7a02                	ld	s4,32(sp)
    800028a0:	6ae2                	ld	s5,24(sp)
    800028a2:	6b42                	ld	s6,16(sp)
    800028a4:	6ba2                	ld	s7,8(sp)
    800028a6:	6c02                	ld	s8,0(sp)
    800028a8:	6161                	addi	sp,sp,80
    800028aa:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800028ac:	85e2                	mv	a1,s8
    800028ae:	854a                	mv	a0,s2
    800028b0:	00000097          	auipc	ra,0x0
    800028b4:	e58080e7          	jalr	-424(ra) # 80002708 <sleep>
    havekids = 0;
    800028b8:	b715                	j	800027dc <wait+0x4a>

00000000800028ba <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800028ba:	7179                	addi	sp,sp,-48
    800028bc:	f406                	sd	ra,40(sp)
    800028be:	f022                	sd	s0,32(sp)
    800028c0:	ec26                	sd	s1,24(sp)
    800028c2:	e84a                	sd	s2,16(sp)
    800028c4:	e44e                	sd	s3,8(sp)
    800028c6:	1800                	addi	s0,sp,48
    800028c8:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800028ca:	0000f497          	auipc	s1,0xf
    800028ce:	f8648493          	addi	s1,s1,-122 # 80011850 <proc>
    800028d2:	00015997          	auipc	s3,0x15
    800028d6:	37e98993          	addi	s3,s3,894 # 80017c50 <tickslock>
    acquire(&p->lock);
    800028da:	8526                	mv	a0,s1
    800028dc:	ffffe097          	auipc	ra,0xffffe
    800028e0:	308080e7          	jalr	776(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800028e4:	589c                	lw	a5,48(s1)
    800028e6:	01278d63          	beq	a5,s2,80002900 <kill+0x46>
        insert_proc_to_list(&cpus[p->last_cpu].runnable_list, p);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800028ea:	8526                	mv	a0,s1
    800028ec:	ffffe097          	auipc	ra,0xffffe
    800028f0:	3ac080e7          	jalr	940(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800028f4:	19048493          	addi	s1,s1,400
    800028f8:	ff3491e3          	bne	s1,s3,800028da <kill+0x20>
  }
  return -1;
    800028fc:	557d                	li	a0,-1
    800028fe:	a829                	j	80002918 <kill+0x5e>
      p->killed = 1;
    80002900:	4785                	li	a5,1
    80002902:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002904:	4c98                	lw	a4,24(s1)
    80002906:	4789                	li	a5,2
    80002908:	00f70f63          	beq	a4,a5,80002926 <kill+0x6c>
      release(&p->lock);
    8000290c:	8526                	mv	a0,s1
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	38a080e7          	jalr	906(ra) # 80000c98 <release>
      return 0;
    80002916:	4501                	li	a0,0
}
    80002918:	70a2                	ld	ra,40(sp)
    8000291a:	7402                	ld	s0,32(sp)
    8000291c:	64e2                	ld	s1,24(sp)
    8000291e:	6942                	ld	s2,16(sp)
    80002920:	69a2                	ld	s3,8(sp)
    80002922:	6145                	addi	sp,sp,48
    80002924:	8082                	ret
        p->state = RUNNABLE;
    80002926:	478d                	li	a5,3
    80002928:	cc9c                	sw	a5,24(s1)
        printf("remove kill sleep %d\n", p->index); //delete
    8000292a:	16c4a583          	lw	a1,364(s1)
    8000292e:	00006517          	auipc	a0,0x6
    80002932:	bf250513          	addi	a0,a0,-1038 # 80008520 <digits+0x4e0>
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	c52080e7          	jalr	-942(ra) # 80000588 <printf>
        remove_proc_to_list(&sleeping_list, p);
    8000293e:	85a6                	mv	a1,s1
    80002940:	00006517          	auipc	a0,0x6
    80002944:	2e050513          	addi	a0,a0,736 # 80008c20 <sleeping_list>
    80002948:	fffff097          	auipc	ra,0xfffff
    8000294c:	3ae080e7          	jalr	942(ra) # 80001cf6 <remove_proc_to_list>
        printf("insert kill runnable %d\n", p->index); //delete
    80002950:	16c4a583          	lw	a1,364(s1)
    80002954:	00006517          	auipc	a0,0x6
    80002958:	be450513          	addi	a0,a0,-1052 # 80008538 <digits+0x4f8>
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	c2c080e7          	jalr	-980(ra) # 80000588 <printf>
        insert_proc_to_list(&cpus[p->last_cpu].runnable_list, p);
    80002964:	1684a783          	lw	a5,360(s1)
    80002968:	0b000713          	li	a4,176
    8000296c:	02e787b3          	mul	a5,a5,a4
    80002970:	85a6                	mv	a1,s1
    80002972:	0000f517          	auipc	a0,0xf
    80002976:	9ae50513          	addi	a0,a0,-1618 # 80011320 <cpus+0x80>
    8000297a:	953e                	add	a0,a0,a5
    8000297c:	fffff097          	auipc	ra,0xfffff
    80002980:	0f2080e7          	jalr	242(ra) # 80001a6e <insert_proc_to_list>
    80002984:	b761                	j	8000290c <kill+0x52>

0000000080002986 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002986:	7179                	addi	sp,sp,-48
    80002988:	f406                	sd	ra,40(sp)
    8000298a:	f022                	sd	s0,32(sp)
    8000298c:	ec26                	sd	s1,24(sp)
    8000298e:	e84a                	sd	s2,16(sp)
    80002990:	e44e                	sd	s3,8(sp)
    80002992:	e052                	sd	s4,0(sp)
    80002994:	1800                	addi	s0,sp,48
    80002996:	84aa                	mv	s1,a0
    80002998:	892e                	mv	s2,a1
    8000299a:	89b2                	mv	s3,a2
    8000299c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000299e:	fffff097          	auipc	ra,0xfffff
    800029a2:	730080e7          	jalr	1840(ra) # 800020ce <myproc>
  if(user_dst){
    800029a6:	c08d                	beqz	s1,800029c8 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800029a8:	86d2                	mv	a3,s4
    800029aa:	864e                	mv	a2,s3
    800029ac:	85ca                	mv	a1,s2
    800029ae:	6928                	ld	a0,80(a0)
    800029b0:	fffff097          	auipc	ra,0xfffff
    800029b4:	cc2080e7          	jalr	-830(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029b8:	70a2                	ld	ra,40(sp)
    800029ba:	7402                	ld	s0,32(sp)
    800029bc:	64e2                	ld	s1,24(sp)
    800029be:	6942                	ld	s2,16(sp)
    800029c0:	69a2                	ld	s3,8(sp)
    800029c2:	6a02                	ld	s4,0(sp)
    800029c4:	6145                	addi	sp,sp,48
    800029c6:	8082                	ret
    memmove((char *)dst, src, len);
    800029c8:	000a061b          	sext.w	a2,s4
    800029cc:	85ce                	mv	a1,s3
    800029ce:	854a                	mv	a0,s2
    800029d0:	ffffe097          	auipc	ra,0xffffe
    800029d4:	370080e7          	jalr	880(ra) # 80000d40 <memmove>
    return 0;
    800029d8:	8526                	mv	a0,s1
    800029da:	bff9                	j	800029b8 <either_copyout+0x32>

00000000800029dc <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800029dc:	7179                	addi	sp,sp,-48
    800029de:	f406                	sd	ra,40(sp)
    800029e0:	f022                	sd	s0,32(sp)
    800029e2:	ec26                	sd	s1,24(sp)
    800029e4:	e84a                	sd	s2,16(sp)
    800029e6:	e44e                	sd	s3,8(sp)
    800029e8:	e052                	sd	s4,0(sp)
    800029ea:	1800                	addi	s0,sp,48
    800029ec:	892a                	mv	s2,a0
    800029ee:	84ae                	mv	s1,a1
    800029f0:	89b2                	mv	s3,a2
    800029f2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029f4:	fffff097          	auipc	ra,0xfffff
    800029f8:	6da080e7          	jalr	1754(ra) # 800020ce <myproc>
  if(user_src){
    800029fc:	c08d                	beqz	s1,80002a1e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800029fe:	86d2                	mv	a3,s4
    80002a00:	864e                	mv	a2,s3
    80002a02:	85ca                	mv	a1,s2
    80002a04:	6928                	ld	a0,80(a0)
    80002a06:	fffff097          	auipc	ra,0xfffff
    80002a0a:	cf8080e7          	jalr	-776(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a0e:	70a2                	ld	ra,40(sp)
    80002a10:	7402                	ld	s0,32(sp)
    80002a12:	64e2                	ld	s1,24(sp)
    80002a14:	6942                	ld	s2,16(sp)
    80002a16:	69a2                	ld	s3,8(sp)
    80002a18:	6a02                	ld	s4,0(sp)
    80002a1a:	6145                	addi	sp,sp,48
    80002a1c:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a1e:	000a061b          	sext.w	a2,s4
    80002a22:	85ce                	mv	a1,s3
    80002a24:	854a                	mv	a0,s2
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	31a080e7          	jalr	794(ra) # 80000d40 <memmove>
    return 0;
    80002a2e:	8526                	mv	a0,s1
    80002a30:	bff9                	j	80002a0e <either_copyin+0x32>

0000000080002a32 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    80002a32:	715d                	addi	sp,sp,-80
    80002a34:	e486                	sd	ra,72(sp)
    80002a36:	e0a2                	sd	s0,64(sp)
    80002a38:	fc26                	sd	s1,56(sp)
    80002a3a:	f84a                	sd	s2,48(sp)
    80002a3c:	f44e                	sd	s3,40(sp)
    80002a3e:	f052                	sd	s4,32(sp)
    80002a40:	ec56                	sd	s5,24(sp)
    80002a42:	e85a                	sd	s6,16(sp)
    80002a44:	e45e                	sd	s7,8(sp)
    80002a46:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002a48:	00006517          	auipc	a0,0x6
    80002a4c:	c1050513          	addi	a0,a0,-1008 # 80008658 <digits+0x618>
    80002a50:	ffffe097          	auipc	ra,0xffffe
    80002a54:	b38080e7          	jalr	-1224(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a58:	0000f497          	auipc	s1,0xf
    80002a5c:	f5048493          	addi	s1,s1,-176 # 800119a8 <proc+0x158>
    80002a60:	00015917          	auipc	s2,0x15
    80002a64:	34890913          	addi	s2,s2,840 # 80017da8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a68:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    80002a6a:	00006997          	auipc	s3,0x6
    80002a6e:	aee98993          	addi	s3,s3,-1298 # 80008558 <digits+0x518>
    printf("%d %s %s", p->pid, state, p->name);
    80002a72:	00006a97          	auipc	s5,0x6
    80002a76:	aeea8a93          	addi	s5,s5,-1298 # 80008560 <digits+0x520>
    printf("\n");
    80002a7a:	00006a17          	auipc	s4,0x6
    80002a7e:	bdea0a13          	addi	s4,s4,-1058 # 80008658 <digits+0x618>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a82:	00006b97          	auipc	s7,0x6
    80002a86:	c06b8b93          	addi	s7,s7,-1018 # 80008688 <states.1826>
    80002a8a:	a00d                	j	80002aac <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002a8c:	ed86a583          	lw	a1,-296(a3)
    80002a90:	8556                	mv	a0,s5
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	af6080e7          	jalr	-1290(ra) # 80000588 <printf>
    printf("\n");
    80002a9a:	8552                	mv	a0,s4
    80002a9c:	ffffe097          	auipc	ra,0xffffe
    80002aa0:	aec080e7          	jalr	-1300(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002aa4:	19048493          	addi	s1,s1,400
    80002aa8:	03248163          	beq	s1,s2,80002aca <procdump+0x98>
    if(p->state == UNUSED)
    80002aac:	86a6                	mv	a3,s1
    80002aae:	ec04a783          	lw	a5,-320(s1)
    80002ab2:	dbed                	beqz	a5,80002aa4 <procdump+0x72>
      state = "???"; 
    80002ab4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ab6:	fcfb6be3          	bltu	s6,a5,80002a8c <procdump+0x5a>
    80002aba:	1782                	slli	a5,a5,0x20
    80002abc:	9381                	srli	a5,a5,0x20
    80002abe:	078e                	slli	a5,a5,0x3
    80002ac0:	97de                	add	a5,a5,s7
    80002ac2:	6390                	ld	a2,0(a5)
    80002ac4:	f661                	bnez	a2,80002a8c <procdump+0x5a>
      state = "???"; 
    80002ac6:	864e                	mv	a2,s3
    80002ac8:	b7d1                	j	80002a8c <procdump+0x5a>
  }
}
    80002aca:	60a6                	ld	ra,72(sp)
    80002acc:	6406                	ld	s0,64(sp)
    80002ace:	74e2                	ld	s1,56(sp)
    80002ad0:	7942                	ld	s2,48(sp)
    80002ad2:	79a2                	ld	s3,40(sp)
    80002ad4:	7a02                	ld	s4,32(sp)
    80002ad6:	6ae2                	ld	s5,24(sp)
    80002ad8:	6b42                	ld	s6,16(sp)
    80002ada:	6ba2                	ld	s7,8(sp)
    80002adc:	6161                	addi	sp,sp,80
    80002ade:	8082                	ret

0000000080002ae0 <set_cpu>:

// assign current process to a different CPU. 
int
set_cpu(int cpu_num){
    80002ae0:	1101                	addi	sp,sp,-32
    80002ae2:	ec06                	sd	ra,24(sp)
    80002ae4:	e822                	sd	s0,16(sp)
    80002ae6:	e426                	sd	s1,8(sp)
    80002ae8:	e04a                	sd	s2,0(sp)
    80002aea:	1000                	addi	s0,sp,32
    80002aec:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002aee:	fffff097          	auipc	ra,0xfffff
    80002af2:	5e0080e7          	jalr	1504(ra) # 800020ce <myproc>
  if(cpu_num >= 0 && cpu_num < CPUS){
    80002af6:	0004871b          	sext.w	a4,s1
    80002afa:	4789                	li	a5,2
    80002afc:	02e7e963          	bltu	a5,a4,80002b2e <set_cpu+0x4e>
    80002b00:	892a                	mv	s2,a0
    acquire(&p->lock);
    80002b02:	ffffe097          	auipc	ra,0xffffe
    80002b06:	0e2080e7          	jalr	226(ra) # 80000be4 <acquire>
    p->last_cpu = cpu_num;
    80002b0a:	16992423          	sw	s1,360(s2)
    release(&p->lock);
    80002b0e:	854a                	mv	a0,s2
    80002b10:	ffffe097          	auipc	ra,0xffffe
    80002b14:	188080e7          	jalr	392(ra) # 80000c98 <release>

    yield();
    80002b18:	00000097          	auipc	ra,0x0
    80002b1c:	b7c080e7          	jalr	-1156(ra) # 80002694 <yield>

    return cpu_num;
    80002b20:	8526                	mv	a0,s1
  }
  return -1;
}
    80002b22:	60e2                	ld	ra,24(sp)
    80002b24:	6442                	ld	s0,16(sp)
    80002b26:	64a2                	ld	s1,8(sp)
    80002b28:	6902                	ld	s2,0(sp)
    80002b2a:	6105                	addi	sp,sp,32
    80002b2c:	8082                	ret
  return -1;
    80002b2e:	557d                	li	a0,-1
    80002b30:	bfcd                	j	80002b22 <set_cpu+0x42>

0000000080002b32 <get_cpu>:

// return the current CPU id.
int
get_cpu(void){
    80002b32:	1141                	addi	sp,sp,-16
    80002b34:	e406                	sd	ra,8(sp)
    80002b36:	e022                	sd	s0,0(sp)
    80002b38:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b3a:	fffff097          	auipc	ra,0xfffff
    80002b3e:	594080e7          	jalr	1428(ra) # 800020ce <myproc>
  return p->last_cpu;
}
    80002b42:	16852503          	lw	a0,360(a0)
    80002b46:	60a2                	ld	ra,8(sp)
    80002b48:	6402                	ld	s0,0(sp)
    80002b4a:	0141                	addi	sp,sp,16
    80002b4c:	8082                	ret

0000000080002b4e <min_cpu_process_count>:

int
min_cpu_process_count(void){
    80002b4e:	1141                	addi	sp,sp,-16
    80002b50:	e422                	sd	s0,8(sp)
    80002b52:	0800                	addi	s0,sp,16
  struct cpu *c, *min_cpu;
  min_cpu = cpus;
    80002b54:	0000e617          	auipc	a2,0xe
    80002b58:	74c60613          	addi	a2,a2,1868 # 800112a0 <cpus>
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL && c->cpu_id<CPUS ; c++){
    80002b5c:	0000e797          	auipc	a5,0xe
    80002b60:	7f478793          	addi	a5,a5,2036 # 80011350 <cpus+0xb0>
    80002b64:	4589                	li	a1,2
    80002b66:	0000f517          	auipc	a0,0xf
    80002b6a:	cba50513          	addi	a0,a0,-838 # 80011820 <pid_lock>
    80002b6e:	a029                	j	80002b78 <min_cpu_process_count+0x2a>
    80002b70:	0b078793          	addi	a5,a5,176
    80002b74:	00a78c63          	beq	a5,a0,80002b8c <min_cpu_process_count+0x3e>
    80002b78:	0a07a703          	lw	a4,160(a5)
    80002b7c:	00e5c863          	blt	a1,a4,80002b8c <min_cpu_process_count+0x3e>
    if (c->cpu_process_count < min_cpu->cpu_process_count)
    80002b80:	77d4                	ld	a3,168(a5)
    80002b82:	7658                	ld	a4,168(a2)
    80002b84:	fee6f6e3          	bgeu	a3,a4,80002b70 <min_cpu_process_count+0x22>
    80002b88:	863e                	mv	a2,a5
    80002b8a:	b7dd                	j	80002b70 <min_cpu_process_count+0x22>
      min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    80002b8c:	0a062503          	lw	a0,160(a2)
    80002b90:	6422                	ld	s0,8(sp)
    80002b92:	0141                	addi	sp,sp,16
    80002b94:	8082                	ret

0000000080002b96 <cpu_process_count>:

int
cpu_process_count(int cpu_num){
    80002b96:	1141                	addi	sp,sp,-16
    80002b98:	e422                	sd	s0,8(sp)
    80002b9a:	0800                	addi	s0,sp,16
  if (cpu_num > 0 && cpu_num < CPUS && &cpus[cpu_num] != NULL) 
    80002b9c:	fff5071b          	addiw	a4,a0,-1
    80002ba0:	4785                	li	a5,1
    80002ba2:	02e7e063          	bltu	a5,a4,80002bc2 <cpu_process_count+0x2c>
    return cpus[cpu_num].cpu_process_count;
    80002ba6:	0b000793          	li	a5,176
    80002baa:	02f50533          	mul	a0,a0,a5
    80002bae:	0000e797          	auipc	a5,0xe
    80002bb2:	6f278793          	addi	a5,a5,1778 # 800112a0 <cpus>
    80002bb6:	953e                	add	a0,a0,a5
    80002bb8:	0a852503          	lw	a0,168(a0)
  return -1;
}
    80002bbc:	6422                	ld	s0,8(sp)
    80002bbe:	0141                	addi	sp,sp,16
    80002bc0:	8082                	ret
  return -1;
    80002bc2:	557d                	li	a0,-1
    80002bc4:	bfe5                	j	80002bbc <cpu_process_count+0x26>

0000000080002bc6 <increment_cpu_process_count>:

void 
increment_cpu_process_count(struct cpu *c){
    80002bc6:	1101                	addi	sp,sp,-32
    80002bc8:	ec06                	sd	ra,24(sp)
    80002bca:	e822                	sd	s0,16(sp)
    80002bcc:	e426                	sd	s1,8(sp)
    80002bce:	e04a                	sd	s2,0(sp)
    80002bd0:	1000                	addi	s0,sp,32
    80002bd2:	84aa                	mv	s1,a0
  uint64 curr_count;
  do{
    curr_count = c->cpu_process_count;
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    80002bd4:	0a850913          	addi	s2,a0,168
    curr_count = c->cpu_process_count;
    80002bd8:	74cc                	ld	a1,168(s1)
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    80002bda:	0015861b          	addiw	a2,a1,1
    80002bde:	2581                	sext.w	a1,a1
    80002be0:	854a                	mv	a0,s2
    80002be2:	00004097          	auipc	ra,0x4
    80002be6:	2d4080e7          	jalr	724(ra) # 80006eb6 <cas>
    80002bea:	2501                	sext.w	a0,a0
    80002bec:	f575                	bnez	a0,80002bd8 <increment_cpu_process_count+0x12>
}
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	64a2                	ld	s1,8(sp)
    80002bf4:	6902                	ld	s2,0(sp)
    80002bf6:	6105                	addi	sp,sp,32
    80002bf8:	8082                	ret

0000000080002bfa <fork>:
{
    80002bfa:	7139                	addi	sp,sp,-64
    80002bfc:	fc06                	sd	ra,56(sp)
    80002bfe:	f822                	sd	s0,48(sp)
    80002c00:	f426                	sd	s1,40(sp)
    80002c02:	f04a                	sd	s2,32(sp)
    80002c04:	ec4e                	sd	s3,24(sp)
    80002c06:	e852                	sd	s4,16(sp)
    80002c08:	e456                	sd	s5,8(sp)
    80002c0a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002c0c:	fffff097          	auipc	ra,0xfffff
    80002c10:	4c2080e7          	jalr	1218(ra) # 800020ce <myproc>
    80002c14:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002c16:	fffff097          	auipc	ra,0xfffff
    80002c1a:	708080e7          	jalr	1800(ra) # 8000231e <allocproc>
    80002c1e:	16050663          	beqz	a0,80002d8a <fork+0x190>
    80002c22:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002c24:	04893603          	ld	a2,72(s2)
    80002c28:	692c                	ld	a1,80(a0)
    80002c2a:	05093503          	ld	a0,80(s2)
    80002c2e:	fffff097          	auipc	ra,0xfffff
    80002c32:	940080e7          	jalr	-1728(ra) # 8000156e <uvmcopy>
    80002c36:	04054663          	bltz	a0,80002c82 <fork+0x88>
  np->sz = p->sz;
    80002c3a:	04893783          	ld	a5,72(s2)
    80002c3e:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80002c42:	05893683          	ld	a3,88(s2)
    80002c46:	87b6                	mv	a5,a3
    80002c48:	0589b703          	ld	a4,88(s3)
    80002c4c:	12068693          	addi	a3,a3,288
    80002c50:	0007b803          	ld	a6,0(a5)
    80002c54:	6788                	ld	a0,8(a5)
    80002c56:	6b8c                	ld	a1,16(a5)
    80002c58:	6f90                	ld	a2,24(a5)
    80002c5a:	01073023          	sd	a6,0(a4)
    80002c5e:	e708                	sd	a0,8(a4)
    80002c60:	eb0c                	sd	a1,16(a4)
    80002c62:	ef10                	sd	a2,24(a4)
    80002c64:	02078793          	addi	a5,a5,32
    80002c68:	02070713          	addi	a4,a4,32
    80002c6c:	fed792e3          	bne	a5,a3,80002c50 <fork+0x56>
  np->trapframe->a0 = 0;
    80002c70:	0589b783          	ld	a5,88(s3)
    80002c74:	0607b823          	sd	zero,112(a5)
    80002c78:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002c7c:	15000a13          	li	s4,336
    80002c80:	a03d                	j	80002cae <fork+0xb4>
    freeproc(np);
    80002c82:	854e                	mv	a0,s3
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	5f6080e7          	jalr	1526(ra) # 8000227a <freeproc>
    release(&np->lock);
    80002c8c:	854e                	mv	a0,s3
    80002c8e:	ffffe097          	auipc	ra,0xffffe
    80002c92:	00a080e7          	jalr	10(ra) # 80000c98 <release>
    return -1;
    80002c96:	5afd                	li	s5,-1
    80002c98:	a8f9                	j	80002d76 <fork+0x17c>
      np->ofile[i] = filedup(p->ofile[i]);
    80002c9a:	00002097          	auipc	ra,0x2
    80002c9e:	4da080e7          	jalr	1242(ra) # 80005174 <filedup>
    80002ca2:	009987b3          	add	a5,s3,s1
    80002ca6:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002ca8:	04a1                	addi	s1,s1,8
    80002caa:	01448763          	beq	s1,s4,80002cb8 <fork+0xbe>
    if(p->ofile[i])
    80002cae:	009907b3          	add	a5,s2,s1
    80002cb2:	6388                	ld	a0,0(a5)
    80002cb4:	f17d                	bnez	a0,80002c9a <fork+0xa0>
    80002cb6:	bfcd                	j	80002ca8 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002cb8:	15093503          	ld	a0,336(s2)
    80002cbc:	00001097          	auipc	ra,0x1
    80002cc0:	62e080e7          	jalr	1582(ra) # 800042ea <idup>
    80002cc4:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002cc8:	4641                	li	a2,16
    80002cca:	15890593          	addi	a1,s2,344
    80002cce:	15898513          	addi	a0,s3,344
    80002cd2:	ffffe097          	auipc	ra,0xffffe
    80002cd6:	160080e7          	jalr	352(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002cda:	0309aa83          	lw	s5,48(s3)
  release(&np->lock);
    80002cde:	854e                	mv	a0,s3
    80002ce0:	ffffe097          	auipc	ra,0xffffe
    80002ce4:	fb8080e7          	jalr	-72(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002ce8:	0000ea17          	auipc	s4,0xe
    80002cec:	5b8a0a13          	addi	s4,s4,1464 # 800112a0 <cpus>
    80002cf0:	0000f497          	auipc	s1,0xf
    80002cf4:	b4848493          	addi	s1,s1,-1208 # 80011838 <wait_lock>
    80002cf8:	8526                	mv	a0,s1
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	eea080e7          	jalr	-278(ra) # 80000be4 <acquire>
  np->parent = p;
    80002d02:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80002d06:	8526                	mv	a0,s1
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	f90080e7          	jalr	-112(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002d10:	854e                	mv	a0,s3
    80002d12:	ffffe097          	auipc	ra,0xffffe
    80002d16:	ed2080e7          	jalr	-302(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002d1a:	478d                	li	a5,3
    80002d1c:	00f9ac23          	sw	a5,24(s3)
  np->last_cpu = p->last_cpu; // case BLNCFLG=OFF -> cpu = parent's cpu 
    80002d20:	16892783          	lw	a5,360(s2)
    80002d24:	16f9a423          	sw	a5,360(s3)
      np->last_cpu = min_cpu_process_count(); // case BLNCFLG=ON -> cpu = CPU with the lowest counter value
    80002d28:	00000097          	auipc	ra,0x0
    80002d2c:	e26080e7          	jalr	-474(ra) # 80002b4e <min_cpu_process_count>
    80002d30:	16a9a423          	sw	a0,360(s3)
  struct cpu *c = &cpus[np->last_cpu];
    80002d34:	0b000493          	li	s1,176
    80002d38:	029504b3          	mul	s1,a0,s1
  increment_cpu_process_count(c);
    80002d3c:	009a0533          	add	a0,s4,s1
    80002d40:	00000097          	auipc	ra,0x0
    80002d44:	e86080e7          	jalr	-378(ra) # 80002bc6 <increment_cpu_process_count>
  printf("insert fork runnable %d\n", p->index); //delete
    80002d48:	16c92583          	lw	a1,364(s2)
    80002d4c:	00006517          	auipc	a0,0x6
    80002d50:	82450513          	addi	a0,a0,-2012 # 80008570 <digits+0x530>
    80002d54:	ffffe097          	auipc	ra,0xffffe
    80002d58:	834080e7          	jalr	-1996(ra) # 80000588 <printf>
  insert_proc_to_list(&(c->runnable_list), np); // admit the new process to the father’s current CPU’s ready list
    80002d5c:	08048513          	addi	a0,s1,128
    80002d60:	85ce                	mv	a1,s3
    80002d62:	9552                	add	a0,a0,s4
    80002d64:	fffff097          	auipc	ra,0xfffff
    80002d68:	d0a080e7          	jalr	-758(ra) # 80001a6e <insert_proc_to_list>
  release(&np->lock);
    80002d6c:	854e                	mv	a0,s3
    80002d6e:	ffffe097          	auipc	ra,0xffffe
    80002d72:	f2a080e7          	jalr	-214(ra) # 80000c98 <release>
}
    80002d76:	8556                	mv	a0,s5
    80002d78:	70e2                	ld	ra,56(sp)
    80002d7a:	7442                	ld	s0,48(sp)
    80002d7c:	74a2                	ld	s1,40(sp)
    80002d7e:	7902                	ld	s2,32(sp)
    80002d80:	69e2                	ld	s3,24(sp)
    80002d82:	6a42                	ld	s4,16(sp)
    80002d84:	6aa2                	ld	s5,8(sp)
    80002d86:	6121                	addi	sp,sp,64
    80002d88:	8082                	ret
    return -1;
    80002d8a:	5afd                	li	s5,-1
    80002d8c:	b7ed                	j	80002d76 <fork+0x17c>

0000000080002d8e <wakeup>:
{
    80002d8e:	7119                	addi	sp,sp,-128
    80002d90:	fc86                	sd	ra,120(sp)
    80002d92:	f8a2                	sd	s0,112(sp)
    80002d94:	f4a6                	sd	s1,104(sp)
    80002d96:	f0ca                	sd	s2,96(sp)
    80002d98:	ecce                	sd	s3,88(sp)
    80002d9a:	e8d2                	sd	s4,80(sp)
    80002d9c:	e4d6                	sd	s5,72(sp)
    80002d9e:	e0da                	sd	s6,64(sp)
    80002da0:	fc5e                	sd	s7,56(sp)
    80002da2:	f862                	sd	s8,48(sp)
    80002da4:	f466                	sd	s9,40(sp)
    80002da6:	f06a                	sd	s10,32(sp)
    80002da8:	ec6e                	sd	s11,24(sp)
    80002daa:	0100                	addi	s0,sp,128
    80002dac:	8baa                	mv	s7,a0
  int curr = get_head(&sleeping_list);
    80002dae:	00006517          	auipc	a0,0x6
    80002db2:	e7250513          	addi	a0,a0,-398 # 80008c20 <sleeping_list>
    80002db6:	fffff097          	auipc	ra,0xfffff
    80002dba:	c62080e7          	jalr	-926(ra) # 80001a18 <get_head>
  while(curr != -1) {
    80002dbe:	57fd                	li	a5,-1
    80002dc0:	0cf50b63          	beq	a0,a5,80002e96 <wakeup+0x108>
    80002dc4:	892a                	mv	s2,a0
    p = &proc[curr];
    80002dc6:	19000a93          	li	s5,400
    80002dca:	0000fa17          	auipc	s4,0xf
    80002dce:	a86a0a13          	addi	s4,s4,-1402 # 80011850 <proc>
      if(p->state == SLEEPING && p->chan == chan) {
    80002dd2:	4b09                	li	s6,2
        remove_proc_to_list(&sleeping_list, p);
    80002dd4:	00006c17          	auipc	s8,0x6
    80002dd8:	e4cc0c13          	addi	s8,s8,-436 # 80008c20 <sleeping_list>
        p->state = RUNNABLE;
    80002ddc:	4d8d                	li	s11,3
    80002dde:	0b000d13          	li	s10,176
        c = &cpus[p->last_cpu];
    80002de2:	0000ec97          	auipc	s9,0xe
    80002de6:	4bec8c93          	addi	s9,s9,1214 # 800112a0 <cpus>
    80002dea:	a809                	j	80002dfc <wakeup+0x6e>
      release(&p->lock);
    80002dec:	8526                	mv	a0,s1
    80002dee:	ffffe097          	auipc	ra,0xffffe
    80002df2:	eaa080e7          	jalr	-342(ra) # 80000c98 <release>
  while(curr != -1) {
    80002df6:	57fd                	li	a5,-1
    80002df8:	08f90f63          	beq	s2,a5,80002e96 <wakeup+0x108>
    p = &proc[curr];
    80002dfc:	035904b3          	mul	s1,s2,s5
    80002e00:	94d2                	add	s1,s1,s4
    curr = p->next_index;
    80002e02:	1744a903          	lw	s2,372(s1)
    if(p != myproc()){
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	2c8080e7          	jalr	712(ra) # 800020ce <myproc>
    80002e0e:	fea484e3          	beq	s1,a0,80002df6 <wakeup+0x68>
      acquire(&p->lock);
    80002e12:	8526                	mv	a0,s1
    80002e14:	ffffe097          	auipc	ra,0xffffe
    80002e18:	dd0080e7          	jalr	-560(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002e1c:	4c9c                	lw	a5,24(s1)
    80002e1e:	fd6797e3          	bne	a5,s6,80002dec <wakeup+0x5e>
    80002e22:	709c                	ld	a5,32(s1)
    80002e24:	fd7794e3          	bne	a5,s7,80002dec <wakeup+0x5e>
        printf("remove wakeup sleep %d\n", p->index); //delete
    80002e28:	16c4a583          	lw	a1,364(s1)
    80002e2c:	00005517          	auipc	a0,0x5
    80002e30:	76450513          	addi	a0,a0,1892 # 80008590 <digits+0x550>
    80002e34:	ffffd097          	auipc	ra,0xffffd
    80002e38:	754080e7          	jalr	1876(ra) # 80000588 <printf>
        remove_proc_to_list(&sleeping_list, p);
    80002e3c:	85a6                	mv	a1,s1
    80002e3e:	8562                	mv	a0,s8
    80002e40:	fffff097          	auipc	ra,0xfffff
    80002e44:	eb6080e7          	jalr	-330(ra) # 80001cf6 <remove_proc_to_list>
        p->state = RUNNABLE;
    80002e48:	01b4ac23          	sw	s11,24(s1)
          p->last_cpu = min_cpu_process_count(); // case BLNCFLG=ON -> cpu = CPU with the lowest counter value
    80002e4c:	00000097          	auipc	ra,0x0
    80002e50:	d02080e7          	jalr	-766(ra) # 80002b4e <min_cpu_process_count>
    80002e54:	16a4a423          	sw	a0,360(s1)
        c = &cpus[p->last_cpu];
    80002e58:	03a507b3          	mul	a5,a0,s10
        increment_cpu_process_count(c);
    80002e5c:	f8f43423          	sd	a5,-120(s0)
    80002e60:	00fc8533          	add	a0,s9,a5
    80002e64:	00000097          	auipc	ra,0x0
    80002e68:	d62080e7          	jalr	-670(ra) # 80002bc6 <increment_cpu_process_count>
        printf("insert wakeup runnable %d\n", p->index); //delete
    80002e6c:	16c4a583          	lw	a1,364(s1)
    80002e70:	00005517          	auipc	a0,0x5
    80002e74:	73850513          	addi	a0,a0,1848 # 800085a8 <digits+0x568>
    80002e78:	ffffd097          	auipc	ra,0xffffd
    80002e7c:	710080e7          	jalr	1808(ra) # 80000588 <printf>
        insert_proc_to_list(&(c->runnable_list), p);
    80002e80:	f8843783          	ld	a5,-120(s0)
    80002e84:	08078513          	addi	a0,a5,128
    80002e88:	85a6                	mv	a1,s1
    80002e8a:	9566                	add	a0,a0,s9
    80002e8c:	fffff097          	auipc	ra,0xfffff
    80002e90:	be2080e7          	jalr	-1054(ra) # 80001a6e <insert_proc_to_list>
    80002e94:	bfa1                	j	80002dec <wakeup+0x5e>
}
    80002e96:	70e6                	ld	ra,120(sp)
    80002e98:	7446                	ld	s0,112(sp)
    80002e9a:	74a6                	ld	s1,104(sp)
    80002e9c:	7906                	ld	s2,96(sp)
    80002e9e:	69e6                	ld	s3,88(sp)
    80002ea0:	6a46                	ld	s4,80(sp)
    80002ea2:	6aa6                	ld	s5,72(sp)
    80002ea4:	6b06                	ld	s6,64(sp)
    80002ea6:	7be2                	ld	s7,56(sp)
    80002ea8:	7c42                	ld	s8,48(sp)
    80002eaa:	7ca2                	ld	s9,40(sp)
    80002eac:	7d02                	ld	s10,32(sp)
    80002eae:	6de2                	ld	s11,24(sp)
    80002eb0:	6109                	addi	sp,sp,128
    80002eb2:	8082                	ret

0000000080002eb4 <reparent>:
{
    80002eb4:	7179                	addi	sp,sp,-48
    80002eb6:	f406                	sd	ra,40(sp)
    80002eb8:	f022                	sd	s0,32(sp)
    80002eba:	ec26                	sd	s1,24(sp)
    80002ebc:	e84a                	sd	s2,16(sp)
    80002ebe:	e44e                	sd	s3,8(sp)
    80002ec0:	e052                	sd	s4,0(sp)
    80002ec2:	1800                	addi	s0,sp,48
    80002ec4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002ec6:	0000f497          	auipc	s1,0xf
    80002eca:	98a48493          	addi	s1,s1,-1654 # 80011850 <proc>
      pp->parent = initproc;
    80002ece:	00006a17          	auipc	s4,0x6
    80002ed2:	15aa0a13          	addi	s4,s4,346 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002ed6:	00015997          	auipc	s3,0x15
    80002eda:	d7a98993          	addi	s3,s3,-646 # 80017c50 <tickslock>
    80002ede:	a029                	j	80002ee8 <reparent+0x34>
    80002ee0:	19048493          	addi	s1,s1,400
    80002ee4:	01348d63          	beq	s1,s3,80002efe <reparent+0x4a>
    if(pp->parent == p){
    80002ee8:	7c9c                	ld	a5,56(s1)
    80002eea:	ff279be3          	bne	a5,s2,80002ee0 <reparent+0x2c>
      pp->parent = initproc;
    80002eee:	000a3503          	ld	a0,0(s4)
    80002ef2:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002ef4:	00000097          	auipc	ra,0x0
    80002ef8:	e9a080e7          	jalr	-358(ra) # 80002d8e <wakeup>
    80002efc:	b7d5                	j	80002ee0 <reparent+0x2c>
}
    80002efe:	70a2                	ld	ra,40(sp)
    80002f00:	7402                	ld	s0,32(sp)
    80002f02:	64e2                	ld	s1,24(sp)
    80002f04:	6942                	ld	s2,16(sp)
    80002f06:	69a2                	ld	s3,8(sp)
    80002f08:	6a02                	ld	s4,0(sp)
    80002f0a:	6145                	addi	sp,sp,48
    80002f0c:	8082                	ret

0000000080002f0e <exit>:
{
    80002f0e:	7179                	addi	sp,sp,-48
    80002f10:	f406                	sd	ra,40(sp)
    80002f12:	f022                	sd	s0,32(sp)
    80002f14:	ec26                	sd	s1,24(sp)
    80002f16:	e84a                	sd	s2,16(sp)
    80002f18:	e44e                	sd	s3,8(sp)
    80002f1a:	e052                	sd	s4,0(sp)
    80002f1c:	1800                	addi	s0,sp,48
    80002f1e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002f20:	fffff097          	auipc	ra,0xfffff
    80002f24:	1ae080e7          	jalr	430(ra) # 800020ce <myproc>
    80002f28:	89aa                	mv	s3,a0
  if(p == initproc)
    80002f2a:	00006797          	auipc	a5,0x6
    80002f2e:	0fe7b783          	ld	a5,254(a5) # 80009028 <initproc>
    80002f32:	0d050493          	addi	s1,a0,208
    80002f36:	15050913          	addi	s2,a0,336
    80002f3a:	02a79363          	bne	a5,a0,80002f60 <exit+0x52>
    panic("init exiting");
    80002f3e:	00005517          	auipc	a0,0x5
    80002f42:	68a50513          	addi	a0,a0,1674 # 800085c8 <digits+0x588>
    80002f46:	ffffd097          	auipc	ra,0xffffd
    80002f4a:	5f8080e7          	jalr	1528(ra) # 8000053e <panic>
      fileclose(f);
    80002f4e:	00002097          	auipc	ra,0x2
    80002f52:	278080e7          	jalr	632(ra) # 800051c6 <fileclose>
      p->ofile[fd] = 0;
    80002f56:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002f5a:	04a1                	addi	s1,s1,8
    80002f5c:	01248563          	beq	s1,s2,80002f66 <exit+0x58>
    if(p->ofile[fd]){
    80002f60:	6088                	ld	a0,0(s1)
    80002f62:	f575                	bnez	a0,80002f4e <exit+0x40>
    80002f64:	bfdd                	j	80002f5a <exit+0x4c>
  begin_op();
    80002f66:	00002097          	auipc	ra,0x2
    80002f6a:	d94080e7          	jalr	-620(ra) # 80004cfa <begin_op>
  iput(p->cwd);
    80002f6e:	1509b503          	ld	a0,336(s3)
    80002f72:	00001097          	auipc	ra,0x1
    80002f76:	570080e7          	jalr	1392(ra) # 800044e2 <iput>
  end_op();
    80002f7a:	00002097          	auipc	ra,0x2
    80002f7e:	e00080e7          	jalr	-512(ra) # 80004d7a <end_op>
  p->cwd = 0;
    80002f82:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002f86:	0000f497          	auipc	s1,0xf
    80002f8a:	8b248493          	addi	s1,s1,-1870 # 80011838 <wait_lock>
    80002f8e:	8526                	mv	a0,s1
    80002f90:	ffffe097          	auipc	ra,0xffffe
    80002f94:	c54080e7          	jalr	-940(ra) # 80000be4 <acquire>
  reparent(p);
    80002f98:	854e                	mv	a0,s3
    80002f9a:	00000097          	auipc	ra,0x0
    80002f9e:	f1a080e7          	jalr	-230(ra) # 80002eb4 <reparent>
  wakeup(p->parent);
    80002fa2:	0389b503          	ld	a0,56(s3)
    80002fa6:	00000097          	auipc	ra,0x0
    80002faa:	de8080e7          	jalr	-536(ra) # 80002d8e <wakeup>
  acquire(&p->lock);
    80002fae:	854e                	mv	a0,s3
    80002fb0:	ffffe097          	auipc	ra,0xffffe
    80002fb4:	c34080e7          	jalr	-972(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002fb8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002fbc:	4795                	li	a5,5
    80002fbe:	00f9ac23          	sw	a5,24(s3)
  printf("insert exit zombie %d\n", p->index); //delete
    80002fc2:	16c9a583          	lw	a1,364(s3)
    80002fc6:	00005517          	auipc	a0,0x5
    80002fca:	61250513          	addi	a0,a0,1554 # 800085d8 <digits+0x598>
    80002fce:	ffffd097          	auipc	ra,0xffffd
    80002fd2:	5ba080e7          	jalr	1466(ra) # 80000588 <printf>
  insert_proc_to_list(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    80002fd6:	85ce                	mv	a1,s3
    80002fd8:	00006517          	auipc	a0,0x6
    80002fdc:	c6850513          	addi	a0,a0,-920 # 80008c40 <zombie_list>
    80002fe0:	fffff097          	auipc	ra,0xfffff
    80002fe4:	a8e080e7          	jalr	-1394(ra) # 80001a6e <insert_proc_to_list>
  release(&wait_lock);
    80002fe8:	8526                	mv	a0,s1
    80002fea:	ffffe097          	auipc	ra,0xffffe
    80002fee:	cae080e7          	jalr	-850(ra) # 80000c98 <release>
  sched();
    80002ff2:	fffff097          	auipc	ra,0xfffff
    80002ff6:	5c0080e7          	jalr	1472(ra) # 800025b2 <sched>
  panic("zombie exit");
    80002ffa:	00005517          	auipc	a0,0x5
    80002ffe:	5f650513          	addi	a0,a0,1526 # 800085f0 <digits+0x5b0>
    80003002:	ffffd097          	auipc	ra,0xffffd
    80003006:	53c080e7          	jalr	1340(ra) # 8000053e <panic>

000000008000300a <steal_process>:

void
steal_process(struct cpu *curr_c){  
    8000300a:	7119                	addi	sp,sp,-128
    8000300c:	fc86                	sd	ra,120(sp)
    8000300e:	f8a2                	sd	s0,112(sp)
    80003010:	f4a6                	sd	s1,104(sp)
    80003012:	f0ca                	sd	s2,96(sp)
    80003014:	ecce                	sd	s3,88(sp)
    80003016:	e8d2                	sd	s4,80(sp)
    80003018:	e4d6                	sd	s5,72(sp)
    8000301a:	e0da                	sd	s6,64(sp)
    8000301c:	fc5e                	sd	s7,56(sp)
    8000301e:	f862                	sd	s8,48(sp)
    80003020:	f466                	sd	s9,40(sp)
    80003022:	f06a                	sd	s10,32(sp)
    80003024:	ec6e                	sd	s11,24(sp)
    80003026:	0100                	addi	s0,sp,128
    80003028:	892a                	mv	s2,a0
  struct cpu *c;
  struct proc *p;
  struct _list *lst;
  int stolen_process;
  int succeed = 0;
  for(c = cpus; !succeed && c < &cpus[NCPU] && c != NULL && c->cpu_id < CPUS ; c++){
    8000302a:	0000e497          	auipc	s1,0xe
    8000302e:	27648493          	addi	s1,s1,630 # 800112a0 <cpus>
    80003032:	4a09                	li	s4,2
      if(c->cpu_id != curr_c->cpu_id){
        lst = &c->runnable_list;
        acquire(&lst->head_lock);
        if(!isEmpty(lst)){ 
    80003034:	5c7d                	li	s8,-1
          stolen_process = lst->head;
          p = &proc[stolen_process];
    80003036:	19000d93          	li	s11,400
    8000303a:	0000fd17          	auipc	s10,0xf
    8000303e:	816d0d13          	addi	s10,s10,-2026 # 80011850 <proc>
          acquire(&p->lock);
          if(!isEmpty(lst) && get_head(lst) == stolen_process){ // p is still the head
            printf("remove steal runnable %d\n", p->index); //delete
            remove_head_from_list(lst);
            printf("insert steal runnable %d\n", p->index); //delete
            insert_proc_to_list(&curr_c->runnable_list, p);
    80003042:	08050793          	addi	a5,a0,128
    80003046:	f8f43023          	sd	a5,-128(s0)
  for(c = cpus; !succeed && c < &cpus[NCPU] && c != NULL && c->cpu_id < CPUS ; c++){
    8000304a:	0000eb97          	auipc	s7,0xe
    8000304e:	7d6b8b93          	addi	s7,s7,2006 # 80011820 <pid_lock>
    80003052:	a815                	j	80003086 <steal_process+0x7c>
        acquire(&lst->head_lock);
    80003054:	f8943423          	sd	s1,-120(s0)
    80003058:	08848993          	addi	s3,s1,136
    8000305c:	854e                	mv	a0,s3
    8000305e:	ffffe097          	auipc	ra,0xffffe
    80003062:	b86080e7          	jalr	-1146(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80003066:	0804aa83          	lw	s5,128(s1)
    8000306a:	4b01                	li	s6,0
        if(!isEmpty(lst)){ 
    8000306c:	038a9863          	bne	s5,s8,8000309c <steal_process+0x92>
            increment_cpu_process_count(curr_c); 
            succeed = 1;
          }
          release(&p->lock);
        }
        release(&lst->head_lock);
    80003070:	854e                	mv	a0,s3
    80003072:	ffffe097          	auipc	ra,0xffffe
    80003076:	c26080e7          	jalr	-986(ra) # 80000c98 <release>
  for(c = cpus; !succeed && c < &cpus[NCPU] && c != NULL && c->cpu_id < CPUS ; c++){
    8000307a:	0b048493          	addi	s1,s1,176
    8000307e:	0a0b1a63          	bnez	s6,80003132 <steal_process+0x128>
    80003082:	0b748863          	beq	s1,s7,80003132 <steal_process+0x128>
    80003086:	0a04a783          	lw	a5,160(s1)
    8000308a:	0afa4463          	blt	s4,a5,80003132 <steal_process+0x128>
      if(c->cpu_id != curr_c->cpu_id){
    8000308e:	0a092703          	lw	a4,160(s2)
    80003092:	fcf711e3          	bne	a4,a5,80003054 <steal_process+0x4a>
  for(c = cpus; !succeed && c < &cpus[NCPU] && c != NULL && c->cpu_id < CPUS ; c++){
    80003096:	0b048493          	addi	s1,s1,176
    8000309a:	b7e5                	j	80003082 <steal_process+0x78>
          p = &proc[stolen_process];
    8000309c:	03ba8cb3          	mul	s9,s5,s11
    800030a0:	9cea                	add	s9,s9,s10
          acquire(&p->lock);
    800030a2:	8566                	mv	a0,s9
    800030a4:	ffffe097          	auipc	ra,0xffffe
    800030a8:	b40080e7          	jalr	-1216(ra) # 80000be4 <acquire>
          if(!isEmpty(lst) && get_head(lst) == stolen_process){ // p is still the head
    800030ac:	0804a783          	lw	a5,128(s1)
    800030b0:	01879863          	bne	a5,s8,800030c0 <steal_process+0xb6>
          release(&p->lock);
    800030b4:	8566                	mv	a0,s9
    800030b6:	ffffe097          	auipc	ra,0xffffe
    800030ba:	be2080e7          	jalr	-1054(ra) # 80000c98 <release>
    800030be:	bf4d                	j	80003070 <steal_process+0x66>
    800030c0:	f8843783          	ld	a5,-120(s0)
    800030c4:	08078793          	addi	a5,a5,128
    800030c8:	f8f43423          	sd	a5,-120(s0)
          if(!isEmpty(lst) && get_head(lst) == stolen_process){ // p is still the head
    800030cc:	853e                	mv	a0,a5
    800030ce:	fffff097          	auipc	ra,0xfffff
    800030d2:	94a080e7          	jalr	-1718(ra) # 80001a18 <get_head>
    800030d6:	fd551fe3          	bne	a0,s5,800030b4 <steal_process+0xaa>
            printf("remove steal runnable %d\n", p->index); //delete
    800030da:	16cca583          	lw	a1,364(s9)
    800030de:	00005517          	auipc	a0,0x5
    800030e2:	52250513          	addi	a0,a0,1314 # 80008600 <digits+0x5c0>
    800030e6:	ffffd097          	auipc	ra,0xffffd
    800030ea:	4a2080e7          	jalr	1186(ra) # 80000588 <printf>
            remove_head_from_list(lst);
    800030ee:	f8843503          	ld	a0,-120(s0)
    800030f2:	fffff097          	auipc	ra,0xfffff
    800030f6:	ae8080e7          	jalr	-1304(ra) # 80001bda <remove_head_from_list>
            printf("insert steal runnable %d\n", p->index); //delete
    800030fa:	16cca583          	lw	a1,364(s9)
    800030fe:	00005517          	auipc	a0,0x5
    80003102:	52250513          	addi	a0,a0,1314 # 80008620 <digits+0x5e0>
    80003106:	ffffd097          	auipc	ra,0xffffd
    8000310a:	482080e7          	jalr	1154(ra) # 80000588 <printf>
            insert_proc_to_list(&curr_c->runnable_list, p);
    8000310e:	85e6                	mv	a1,s9
    80003110:	f8043503          	ld	a0,-128(s0)
    80003114:	fffff097          	auipc	ra,0xfffff
    80003118:	95a080e7          	jalr	-1702(ra) # 80001a6e <insert_proc_to_list>
            p->last_cpu = curr_c->cpu_id;
    8000311c:	0a092783          	lw	a5,160(s2)
    80003120:	16fca423          	sw	a5,360(s9)
            increment_cpu_process_count(curr_c); 
    80003124:	854a                	mv	a0,s2
    80003126:	00000097          	auipc	ra,0x0
    8000312a:	aa0080e7          	jalr	-1376(ra) # 80002bc6 <increment_cpu_process_count>
            succeed = 1;
    8000312e:	4b05                	li	s6,1
    80003130:	b751                	j	800030b4 <steal_process+0xaa>
      }
  }
    80003132:	70e6                	ld	ra,120(sp)
    80003134:	7446                	ld	s0,112(sp)
    80003136:	74a6                	ld	s1,104(sp)
    80003138:	7906                	ld	s2,96(sp)
    8000313a:	69e6                	ld	s3,88(sp)
    8000313c:	6a46                	ld	s4,80(sp)
    8000313e:	6aa6                	ld	s5,72(sp)
    80003140:	6b06                	ld	s6,64(sp)
    80003142:	7be2                	ld	s7,56(sp)
    80003144:	7c42                	ld	s8,48(sp)
    80003146:	7ca2                	ld	s9,40(sp)
    80003148:	7d02                	ld	s10,32(sp)
    8000314a:	6de2                	ld	s11,24(sp)
    8000314c:	6109                	addi	sp,sp,128
    8000314e:	8082                	ret

0000000080003150 <scheduler>:
{
    80003150:	711d                	addi	sp,sp,-96
    80003152:	ec86                	sd	ra,88(sp)
    80003154:	e8a2                	sd	s0,80(sp)
    80003156:	e4a6                	sd	s1,72(sp)
    80003158:	e0ca                	sd	s2,64(sp)
    8000315a:	fc4e                	sd	s3,56(sp)
    8000315c:	f852                	sd	s4,48(sp)
    8000315e:	f456                	sd	s5,40(sp)
    80003160:	f05a                	sd	s6,32(sp)
    80003162:	ec5e                	sd	s7,24(sp)
    80003164:	e862                	sd	s8,16(sp)
    80003166:	e466                	sd	s9,8(sp)
    80003168:	e06a                	sd	s10,0(sp)
    8000316a:	1080                	addi	s0,sp,96
    8000316c:	8712                	mv	a4,tp
  int id = r_tp();
    8000316e:	2701                	sext.w	a4,a4
  struct cpu *c = &cpus[id];
    80003170:	0b000793          	li	a5,176
    80003174:	02f707b3          	mul	a5,a4,a5
    80003178:	0000eb97          	auipc	s7,0xe
    8000317c:	128b8b93          	addi	s7,s7,296 # 800112a0 <cpus>
    80003180:	00fb8b33          	add	s6,s7,a5
  c->proc = 0;
    80003184:	000b3023          	sd	zero,0(s6)
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80003188:	08078a93          	addi	s5,a5,128
    8000318c:	9ade                	add	s5,s5,s7
          swtch(&c->context, &p->context);
    8000318e:	07a1                	addi	a5,a5,8
    80003190:	9bbe                	add	s7,s7,a5
  return lst->head == -1;
    80003192:	895a                	mv	s2,s6
      if(p->state == RUNNABLE) {
    80003194:	0000e997          	auipc	s3,0xe
    80003198:	6bc98993          	addi	s3,s3,1724 # 80011850 <proc>
    8000319c:	19000a13          	li	s4,400
    800031a0:	a891                	j	800031f4 <scheduler+0xa4>
          printf("remove sched runnable %d\n", p->index); //delete
    800031a2:	16cc2583          	lw	a1,364(s8)
    800031a6:	00005517          	auipc	a0,0x5
    800031aa:	49a50513          	addi	a0,a0,1178 # 80008640 <digits+0x600>
    800031ae:	ffffd097          	auipc	ra,0xffffd
    800031b2:	3da080e7          	jalr	986(ra) # 80000588 <printf>
          remove_proc_to_list(&(c->runnable_list), p);
    800031b6:	85e2                	mv	a1,s8
    800031b8:	8556                	mv	a0,s5
    800031ba:	fffff097          	auipc	ra,0xfffff
    800031be:	b3c080e7          	jalr	-1220(ra) # 80001cf6 <remove_proc_to_list>
          p->state = RUNNING;
    800031c2:	4791                	li	a5,4
    800031c4:	00fc2c23          	sw	a5,24(s8)
          c->proc = p;
    800031c8:	01893023          	sd	s8,0(s2)
          p->last_cpu = c->cpu_id;
    800031cc:	0a092783          	lw	a5,160(s2)
    800031d0:	16fc2423          	sw	a5,360(s8)
          swtch(&c->context, &p->context);
    800031d4:	060d0593          	addi	a1,s10,96
    800031d8:	95ce                	add	a1,a1,s3
    800031da:	855e                	mv	a0,s7
    800031dc:	00000097          	auipc	ra,0x0
    800031e0:	06c080e7          	jalr	108(ra) # 80003248 <swtch>
          c->proc = 0;
    800031e4:	00093023          	sd	zero,0(s2)
    800031e8:	a891                	j	8000323c <scheduler+0xec>
        steal_process(c);
    800031ea:	855a                	mv	a0,s6
    800031ec:	00000097          	auipc	ra,0x0
    800031f0:	e1e080e7          	jalr	-482(ra) # 8000300a <steal_process>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031f4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800031f8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031fc:	10079073          	csrw	sstatus,a5
      if(p->state == RUNNABLE) {
    80003200:	4c8d                	li	s9,3
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80003202:	5c7d                	li	s8,-1
    80003204:	08092783          	lw	a5,128(s2)
    80003208:	ff8781e3          	beq	a5,s8,800031ea <scheduler+0x9a>
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    8000320c:	8556                	mv	a0,s5
    8000320e:	fffff097          	auipc	ra,0xfffff
    80003212:	80a080e7          	jalr	-2038(ra) # 80001a18 <get_head>
      if(p->state == RUNNABLE) {
    80003216:	034507b3          	mul	a5,a0,s4
    8000321a:	97ce                	add	a5,a5,s3
    8000321c:	4f9c                	lw	a5,24(a5)
    8000321e:	ff9793e3          	bne	a5,s9,80003204 <scheduler+0xb4>
    80003222:	03450d33          	mul	s10,a0,s4
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    80003226:	013d0c33          	add	s8,s10,s3
        acquire(&p->lock);
    8000322a:	8562                	mv	a0,s8
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	9b8080e7          	jalr	-1608(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {  
    80003234:	018c2783          	lw	a5,24(s8)
    80003238:	f79785e3          	beq	a5,s9,800031a2 <scheduler+0x52>
        release(&p->lock);
    8000323c:	8562                	mv	a0,s8
    8000323e:	ffffe097          	auipc	ra,0xffffe
    80003242:	a5a080e7          	jalr	-1446(ra) # 80000c98 <release>
    80003246:	bf75                	j	80003202 <scheduler+0xb2>

0000000080003248 <swtch>:
    80003248:	00153023          	sd	ra,0(a0)
    8000324c:	00253423          	sd	sp,8(a0)
    80003250:	e900                	sd	s0,16(a0)
    80003252:	ed04                	sd	s1,24(a0)
    80003254:	03253023          	sd	s2,32(a0)
    80003258:	03353423          	sd	s3,40(a0)
    8000325c:	03453823          	sd	s4,48(a0)
    80003260:	03553c23          	sd	s5,56(a0)
    80003264:	05653023          	sd	s6,64(a0)
    80003268:	05753423          	sd	s7,72(a0)
    8000326c:	05853823          	sd	s8,80(a0)
    80003270:	05953c23          	sd	s9,88(a0)
    80003274:	07a53023          	sd	s10,96(a0)
    80003278:	07b53423          	sd	s11,104(a0)
    8000327c:	0005b083          	ld	ra,0(a1)
    80003280:	0085b103          	ld	sp,8(a1)
    80003284:	6980                	ld	s0,16(a1)
    80003286:	6d84                	ld	s1,24(a1)
    80003288:	0205b903          	ld	s2,32(a1)
    8000328c:	0285b983          	ld	s3,40(a1)
    80003290:	0305ba03          	ld	s4,48(a1)
    80003294:	0385ba83          	ld	s5,56(a1)
    80003298:	0405bb03          	ld	s6,64(a1)
    8000329c:	0485bb83          	ld	s7,72(a1)
    800032a0:	0505bc03          	ld	s8,80(a1)
    800032a4:	0585bc83          	ld	s9,88(a1)
    800032a8:	0605bd03          	ld	s10,96(a1)
    800032ac:	0685bd83          	ld	s11,104(a1)
    800032b0:	8082                	ret

00000000800032b2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800032b2:	1141                	addi	sp,sp,-16
    800032b4:	e406                	sd	ra,8(sp)
    800032b6:	e022                	sd	s0,0(sp)
    800032b8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800032ba:	00005597          	auipc	a1,0x5
    800032be:	3fe58593          	addi	a1,a1,1022 # 800086b8 <states.1826+0x30>
    800032c2:	00015517          	auipc	a0,0x15
    800032c6:	98e50513          	addi	a0,a0,-1650 # 80017c50 <tickslock>
    800032ca:	ffffe097          	auipc	ra,0xffffe
    800032ce:	88a080e7          	jalr	-1910(ra) # 80000b54 <initlock>
}
    800032d2:	60a2                	ld	ra,8(sp)
    800032d4:	6402                	ld	s0,0(sp)
    800032d6:	0141                	addi	sp,sp,16
    800032d8:	8082                	ret

00000000800032da <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800032da:	1141                	addi	sp,sp,-16
    800032dc:	e422                	sd	s0,8(sp)
    800032de:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800032e0:	00003797          	auipc	a5,0x3
    800032e4:	50078793          	addi	a5,a5,1280 # 800067e0 <kernelvec>
    800032e8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800032ec:	6422                	ld	s0,8(sp)
    800032ee:	0141                	addi	sp,sp,16
    800032f0:	8082                	ret

00000000800032f2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800032f2:	1141                	addi	sp,sp,-16
    800032f4:	e406                	sd	ra,8(sp)
    800032f6:	e022                	sd	s0,0(sp)
    800032f8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800032fa:	fffff097          	auipc	ra,0xfffff
    800032fe:	dd4080e7          	jalr	-556(ra) # 800020ce <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003302:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003306:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003308:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000330c:	00004617          	auipc	a2,0x4
    80003310:	cf460613          	addi	a2,a2,-780 # 80007000 <_trampoline>
    80003314:	00004697          	auipc	a3,0x4
    80003318:	cec68693          	addi	a3,a3,-788 # 80007000 <_trampoline>
    8000331c:	8e91                	sub	a3,a3,a2
    8000331e:	040007b7          	lui	a5,0x4000
    80003322:	17fd                	addi	a5,a5,-1
    80003324:	07b2                	slli	a5,a5,0xc
    80003326:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003328:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000332c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000332e:	180026f3          	csrr	a3,satp
    80003332:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003334:	6d38                	ld	a4,88(a0)
    80003336:	6134                	ld	a3,64(a0)
    80003338:	6585                	lui	a1,0x1
    8000333a:	96ae                	add	a3,a3,a1
    8000333c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000333e:	6d38                	ld	a4,88(a0)
    80003340:	00000697          	auipc	a3,0x0
    80003344:	13868693          	addi	a3,a3,312 # 80003478 <usertrap>
    80003348:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000334a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000334c:	8692                	mv	a3,tp
    8000334e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003350:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003354:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003358:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000335c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80003360:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003362:	6f18                	ld	a4,24(a4)
    80003364:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003368:	692c                	ld	a1,80(a0)
    8000336a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000336c:	00004717          	auipc	a4,0x4
    80003370:	d2470713          	addi	a4,a4,-732 # 80007090 <userret>
    80003374:	8f11                	sub	a4,a4,a2
    80003376:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003378:	577d                	li	a4,-1
    8000337a:	177e                	slli	a4,a4,0x3f
    8000337c:	8dd9                	or	a1,a1,a4
    8000337e:	02000537          	lui	a0,0x2000
    80003382:	157d                	addi	a0,a0,-1
    80003384:	0536                	slli	a0,a0,0xd
    80003386:	9782                	jalr	a5
}
    80003388:	60a2                	ld	ra,8(sp)
    8000338a:	6402                	ld	s0,0(sp)
    8000338c:	0141                	addi	sp,sp,16
    8000338e:	8082                	ret

0000000080003390 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80003390:	1101                	addi	sp,sp,-32
    80003392:	ec06                	sd	ra,24(sp)
    80003394:	e822                	sd	s0,16(sp)
    80003396:	e426                	sd	s1,8(sp)
    80003398:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000339a:	00015497          	auipc	s1,0x15
    8000339e:	8b648493          	addi	s1,s1,-1866 # 80017c50 <tickslock>
    800033a2:	8526                	mv	a0,s1
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	840080e7          	jalr	-1984(ra) # 80000be4 <acquire>
  ticks++;
    800033ac:	00006517          	auipc	a0,0x6
    800033b0:	c8450513          	addi	a0,a0,-892 # 80009030 <ticks>
    800033b4:	411c                	lw	a5,0(a0)
    800033b6:	2785                	addiw	a5,a5,1
    800033b8:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800033ba:	00000097          	auipc	ra,0x0
    800033be:	9d4080e7          	jalr	-1580(ra) # 80002d8e <wakeup>
  release(&tickslock);
    800033c2:	8526                	mv	a0,s1
    800033c4:	ffffe097          	auipc	ra,0xffffe
    800033c8:	8d4080e7          	jalr	-1836(ra) # 80000c98 <release>
}
    800033cc:	60e2                	ld	ra,24(sp)
    800033ce:	6442                	ld	s0,16(sp)
    800033d0:	64a2                	ld	s1,8(sp)
    800033d2:	6105                	addi	sp,sp,32
    800033d4:	8082                	ret

00000000800033d6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800033d6:	1101                	addi	sp,sp,-32
    800033d8:	ec06                	sd	ra,24(sp)
    800033da:	e822                	sd	s0,16(sp)
    800033dc:	e426                	sd	s1,8(sp)
    800033de:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800033e0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800033e4:	00074d63          	bltz	a4,800033fe <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800033e8:	57fd                	li	a5,-1
    800033ea:	17fe                	slli	a5,a5,0x3f
    800033ec:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800033ee:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800033f0:	06f70363          	beq	a4,a5,80003456 <devintr+0x80>
  }
}
    800033f4:	60e2                	ld	ra,24(sp)
    800033f6:	6442                	ld	s0,16(sp)
    800033f8:	64a2                	ld	s1,8(sp)
    800033fa:	6105                	addi	sp,sp,32
    800033fc:	8082                	ret
     (scause & 0xff) == 9){
    800033fe:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003402:	46a5                	li	a3,9
    80003404:	fed792e3          	bne	a5,a3,800033e8 <devintr+0x12>
    int irq = plic_claim();
    80003408:	00003097          	auipc	ra,0x3
    8000340c:	4e0080e7          	jalr	1248(ra) # 800068e8 <plic_claim>
    80003410:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003412:	47a9                	li	a5,10
    80003414:	02f50763          	beq	a0,a5,80003442 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003418:	4785                	li	a5,1
    8000341a:	02f50963          	beq	a0,a5,8000344c <devintr+0x76>
    return 1;
    8000341e:	4505                	li	a0,1
    } else if(irq){
    80003420:	d8f1                	beqz	s1,800033f4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003422:	85a6                	mv	a1,s1
    80003424:	00005517          	auipc	a0,0x5
    80003428:	29c50513          	addi	a0,a0,668 # 800086c0 <states.1826+0x38>
    8000342c:	ffffd097          	auipc	ra,0xffffd
    80003430:	15c080e7          	jalr	348(ra) # 80000588 <printf>
      plic_complete(irq);
    80003434:	8526                	mv	a0,s1
    80003436:	00003097          	auipc	ra,0x3
    8000343a:	4d6080e7          	jalr	1238(ra) # 8000690c <plic_complete>
    return 1;
    8000343e:	4505                	li	a0,1
    80003440:	bf55                	j	800033f4 <devintr+0x1e>
      uartintr();
    80003442:	ffffd097          	auipc	ra,0xffffd
    80003446:	566080e7          	jalr	1382(ra) # 800009a8 <uartintr>
    8000344a:	b7ed                	j	80003434 <devintr+0x5e>
      virtio_disk_intr();
    8000344c:	00004097          	auipc	ra,0x4
    80003450:	9a0080e7          	jalr	-1632(ra) # 80006dec <virtio_disk_intr>
    80003454:	b7c5                	j	80003434 <devintr+0x5e>
    if(cpuid() == 0){
    80003456:	fffff097          	auipc	ra,0xfffff
    8000345a:	c46080e7          	jalr	-954(ra) # 8000209c <cpuid>
    8000345e:	c901                	beqz	a0,8000346e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003460:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003464:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003466:	14479073          	csrw	sip,a5
    return 2;
    8000346a:	4509                	li	a0,2
    8000346c:	b761                	j	800033f4 <devintr+0x1e>
      clockintr();
    8000346e:	00000097          	auipc	ra,0x0
    80003472:	f22080e7          	jalr	-222(ra) # 80003390 <clockintr>
    80003476:	b7ed                	j	80003460 <devintr+0x8a>

0000000080003478 <usertrap>:
{
    80003478:	1101                	addi	sp,sp,-32
    8000347a:	ec06                	sd	ra,24(sp)
    8000347c:	e822                	sd	s0,16(sp)
    8000347e:	e426                	sd	s1,8(sp)
    80003480:	e04a                	sd	s2,0(sp)
    80003482:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003484:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003488:	1007f793          	andi	a5,a5,256
    8000348c:	e3ad                	bnez	a5,800034ee <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000348e:	00003797          	auipc	a5,0x3
    80003492:	35278793          	addi	a5,a5,850 # 800067e0 <kernelvec>
    80003496:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000349a:	fffff097          	auipc	ra,0xfffff
    8000349e:	c34080e7          	jalr	-972(ra) # 800020ce <myproc>
    800034a2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800034a4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800034a6:	14102773          	csrr	a4,sepc
    800034aa:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800034ac:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800034b0:	47a1                	li	a5,8
    800034b2:	04f71c63          	bne	a4,a5,8000350a <usertrap+0x92>
    if(p->killed)
    800034b6:	551c                	lw	a5,40(a0)
    800034b8:	e3b9                	bnez	a5,800034fe <usertrap+0x86>
    p->trapframe->epc += 4;
    800034ba:	6cb8                	ld	a4,88(s1)
    800034bc:	6f1c                	ld	a5,24(a4)
    800034be:	0791                	addi	a5,a5,4
    800034c0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800034c2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800034c6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800034ca:	10079073          	csrw	sstatus,a5
    syscall();
    800034ce:	00000097          	auipc	ra,0x0
    800034d2:	2e0080e7          	jalr	736(ra) # 800037ae <syscall>
  if(p->killed)
    800034d6:	549c                	lw	a5,40(s1)
    800034d8:	ebc1                	bnez	a5,80003568 <usertrap+0xf0>
  usertrapret();
    800034da:	00000097          	auipc	ra,0x0
    800034de:	e18080e7          	jalr	-488(ra) # 800032f2 <usertrapret>
}
    800034e2:	60e2                	ld	ra,24(sp)
    800034e4:	6442                	ld	s0,16(sp)
    800034e6:	64a2                	ld	s1,8(sp)
    800034e8:	6902                	ld	s2,0(sp)
    800034ea:	6105                	addi	sp,sp,32
    800034ec:	8082                	ret
    panic("usertrap: not from user mode");
    800034ee:	00005517          	auipc	a0,0x5
    800034f2:	1f250513          	addi	a0,a0,498 # 800086e0 <states.1826+0x58>
    800034f6:	ffffd097          	auipc	ra,0xffffd
    800034fa:	048080e7          	jalr	72(ra) # 8000053e <panic>
      exit(-1);
    800034fe:	557d                	li	a0,-1
    80003500:	00000097          	auipc	ra,0x0
    80003504:	a0e080e7          	jalr	-1522(ra) # 80002f0e <exit>
    80003508:	bf4d                	j	800034ba <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000350a:	00000097          	auipc	ra,0x0
    8000350e:	ecc080e7          	jalr	-308(ra) # 800033d6 <devintr>
    80003512:	892a                	mv	s2,a0
    80003514:	c501                	beqz	a0,8000351c <usertrap+0xa4>
  if(p->killed)
    80003516:	549c                	lw	a5,40(s1)
    80003518:	c3a1                	beqz	a5,80003558 <usertrap+0xe0>
    8000351a:	a815                	j	8000354e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000351c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003520:	5890                	lw	a2,48(s1)
    80003522:	00005517          	auipc	a0,0x5
    80003526:	1de50513          	addi	a0,a0,478 # 80008700 <states.1826+0x78>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	05e080e7          	jalr	94(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003532:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003536:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000353a:	00005517          	auipc	a0,0x5
    8000353e:	1f650513          	addi	a0,a0,502 # 80008730 <states.1826+0xa8>
    80003542:	ffffd097          	auipc	ra,0xffffd
    80003546:	046080e7          	jalr	70(ra) # 80000588 <printf>
    p->killed = 1;
    8000354a:	4785                	li	a5,1
    8000354c:	d49c                	sw	a5,40(s1)
    exit(-1);
    8000354e:	557d                	li	a0,-1
    80003550:	00000097          	auipc	ra,0x0
    80003554:	9be080e7          	jalr	-1602(ra) # 80002f0e <exit>
  if(which_dev == 2)
    80003558:	4789                	li	a5,2
    8000355a:	f8f910e3          	bne	s2,a5,800034da <usertrap+0x62>
    yield();
    8000355e:	fffff097          	auipc	ra,0xfffff
    80003562:	136080e7          	jalr	310(ra) # 80002694 <yield>
    80003566:	bf95                	j	800034da <usertrap+0x62>
  int which_dev = 0;
    80003568:	4901                	li	s2,0
    8000356a:	b7d5                	j	8000354e <usertrap+0xd6>

000000008000356c <kerneltrap>:
{
    8000356c:	7179                	addi	sp,sp,-48
    8000356e:	f406                	sd	ra,40(sp)
    80003570:	f022                	sd	s0,32(sp)
    80003572:	ec26                	sd	s1,24(sp)
    80003574:	e84a                	sd	s2,16(sp)
    80003576:	e44e                	sd	s3,8(sp)
    80003578:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000357a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000357e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003582:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003586:	1004f793          	andi	a5,s1,256
    8000358a:	cb85                	beqz	a5,800035ba <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000358c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003590:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003592:	ef85                	bnez	a5,800035ca <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003594:	00000097          	auipc	ra,0x0
    80003598:	e42080e7          	jalr	-446(ra) # 800033d6 <devintr>
    8000359c:	cd1d                	beqz	a0,800035da <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000359e:	4789                	li	a5,2
    800035a0:	06f50a63          	beq	a0,a5,80003614 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800035a4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800035a8:	10049073          	csrw	sstatus,s1
}
    800035ac:	70a2                	ld	ra,40(sp)
    800035ae:	7402                	ld	s0,32(sp)
    800035b0:	64e2                	ld	s1,24(sp)
    800035b2:	6942                	ld	s2,16(sp)
    800035b4:	69a2                	ld	s3,8(sp)
    800035b6:	6145                	addi	sp,sp,48
    800035b8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800035ba:	00005517          	auipc	a0,0x5
    800035be:	19650513          	addi	a0,a0,406 # 80008750 <states.1826+0xc8>
    800035c2:	ffffd097          	auipc	ra,0xffffd
    800035c6:	f7c080e7          	jalr	-132(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800035ca:	00005517          	auipc	a0,0x5
    800035ce:	1ae50513          	addi	a0,a0,430 # 80008778 <states.1826+0xf0>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	f6c080e7          	jalr	-148(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800035da:	85ce                	mv	a1,s3
    800035dc:	00005517          	auipc	a0,0x5
    800035e0:	1bc50513          	addi	a0,a0,444 # 80008798 <states.1826+0x110>
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	fa4080e7          	jalr	-92(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800035ec:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800035f0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800035f4:	00005517          	auipc	a0,0x5
    800035f8:	1b450513          	addi	a0,a0,436 # 800087a8 <states.1826+0x120>
    800035fc:	ffffd097          	auipc	ra,0xffffd
    80003600:	f8c080e7          	jalr	-116(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003604:	00005517          	auipc	a0,0x5
    80003608:	1bc50513          	addi	a0,a0,444 # 800087c0 <states.1826+0x138>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	f32080e7          	jalr	-206(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003614:	fffff097          	auipc	ra,0xfffff
    80003618:	aba080e7          	jalr	-1350(ra) # 800020ce <myproc>
    8000361c:	d541                	beqz	a0,800035a4 <kerneltrap+0x38>
    8000361e:	fffff097          	auipc	ra,0xfffff
    80003622:	ab0080e7          	jalr	-1360(ra) # 800020ce <myproc>
    80003626:	4d18                	lw	a4,24(a0)
    80003628:	4791                	li	a5,4
    8000362a:	f6f71de3          	bne	a4,a5,800035a4 <kerneltrap+0x38>
    yield();
    8000362e:	fffff097          	auipc	ra,0xfffff
    80003632:	066080e7          	jalr	102(ra) # 80002694 <yield>
    80003636:	b7bd                	j	800035a4 <kerneltrap+0x38>

0000000080003638 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003638:	1101                	addi	sp,sp,-32
    8000363a:	ec06                	sd	ra,24(sp)
    8000363c:	e822                	sd	s0,16(sp)
    8000363e:	e426                	sd	s1,8(sp)
    80003640:	1000                	addi	s0,sp,32
    80003642:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003644:	fffff097          	auipc	ra,0xfffff
    80003648:	a8a080e7          	jalr	-1398(ra) # 800020ce <myproc>
  switch (n) {
    8000364c:	4795                	li	a5,5
    8000364e:	0497e163          	bltu	a5,s1,80003690 <argraw+0x58>
    80003652:	048a                	slli	s1,s1,0x2
    80003654:	00005717          	auipc	a4,0x5
    80003658:	1a470713          	addi	a4,a4,420 # 800087f8 <states.1826+0x170>
    8000365c:	94ba                	add	s1,s1,a4
    8000365e:	409c                	lw	a5,0(s1)
    80003660:	97ba                	add	a5,a5,a4
    80003662:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003664:	6d3c                	ld	a5,88(a0)
    80003666:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003668:	60e2                	ld	ra,24(sp)
    8000366a:	6442                	ld	s0,16(sp)
    8000366c:	64a2                	ld	s1,8(sp)
    8000366e:	6105                	addi	sp,sp,32
    80003670:	8082                	ret
    return p->trapframe->a1;
    80003672:	6d3c                	ld	a5,88(a0)
    80003674:	7fa8                	ld	a0,120(a5)
    80003676:	bfcd                	j	80003668 <argraw+0x30>
    return p->trapframe->a2;
    80003678:	6d3c                	ld	a5,88(a0)
    8000367a:	63c8                	ld	a0,128(a5)
    8000367c:	b7f5                	j	80003668 <argraw+0x30>
    return p->trapframe->a3;
    8000367e:	6d3c                	ld	a5,88(a0)
    80003680:	67c8                	ld	a0,136(a5)
    80003682:	b7dd                	j	80003668 <argraw+0x30>
    return p->trapframe->a4;
    80003684:	6d3c                	ld	a5,88(a0)
    80003686:	6bc8                	ld	a0,144(a5)
    80003688:	b7c5                	j	80003668 <argraw+0x30>
    return p->trapframe->a5;
    8000368a:	6d3c                	ld	a5,88(a0)
    8000368c:	6fc8                	ld	a0,152(a5)
    8000368e:	bfe9                	j	80003668 <argraw+0x30>
  panic("argraw");
    80003690:	00005517          	auipc	a0,0x5
    80003694:	14050513          	addi	a0,a0,320 # 800087d0 <states.1826+0x148>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	ea6080e7          	jalr	-346(ra) # 8000053e <panic>

00000000800036a0 <fetchaddr>:
{
    800036a0:	1101                	addi	sp,sp,-32
    800036a2:	ec06                	sd	ra,24(sp)
    800036a4:	e822                	sd	s0,16(sp)
    800036a6:	e426                	sd	s1,8(sp)
    800036a8:	e04a                	sd	s2,0(sp)
    800036aa:	1000                	addi	s0,sp,32
    800036ac:	84aa                	mv	s1,a0
    800036ae:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800036b0:	fffff097          	auipc	ra,0xfffff
    800036b4:	a1e080e7          	jalr	-1506(ra) # 800020ce <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800036b8:	653c                	ld	a5,72(a0)
    800036ba:	02f4f863          	bgeu	s1,a5,800036ea <fetchaddr+0x4a>
    800036be:	00848713          	addi	a4,s1,8
    800036c2:	02e7e663          	bltu	a5,a4,800036ee <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800036c6:	46a1                	li	a3,8
    800036c8:	8626                	mv	a2,s1
    800036ca:	85ca                	mv	a1,s2
    800036cc:	6928                	ld	a0,80(a0)
    800036ce:	ffffe097          	auipc	ra,0xffffe
    800036d2:	030080e7          	jalr	48(ra) # 800016fe <copyin>
    800036d6:	00a03533          	snez	a0,a0
    800036da:	40a00533          	neg	a0,a0
}
    800036de:	60e2                	ld	ra,24(sp)
    800036e0:	6442                	ld	s0,16(sp)
    800036e2:	64a2                	ld	s1,8(sp)
    800036e4:	6902                	ld	s2,0(sp)
    800036e6:	6105                	addi	sp,sp,32
    800036e8:	8082                	ret
    return -1;
    800036ea:	557d                	li	a0,-1
    800036ec:	bfcd                	j	800036de <fetchaddr+0x3e>
    800036ee:	557d                	li	a0,-1
    800036f0:	b7fd                	j	800036de <fetchaddr+0x3e>

00000000800036f2 <fetchstr>:
{
    800036f2:	7179                	addi	sp,sp,-48
    800036f4:	f406                	sd	ra,40(sp)
    800036f6:	f022                	sd	s0,32(sp)
    800036f8:	ec26                	sd	s1,24(sp)
    800036fa:	e84a                	sd	s2,16(sp)
    800036fc:	e44e                	sd	s3,8(sp)
    800036fe:	1800                	addi	s0,sp,48
    80003700:	892a                	mv	s2,a0
    80003702:	84ae                	mv	s1,a1
    80003704:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003706:	fffff097          	auipc	ra,0xfffff
    8000370a:	9c8080e7          	jalr	-1592(ra) # 800020ce <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000370e:	86ce                	mv	a3,s3
    80003710:	864a                	mv	a2,s2
    80003712:	85a6                	mv	a1,s1
    80003714:	6928                	ld	a0,80(a0)
    80003716:	ffffe097          	auipc	ra,0xffffe
    8000371a:	074080e7          	jalr	116(ra) # 8000178a <copyinstr>
  if(err < 0)
    8000371e:	00054763          	bltz	a0,8000372c <fetchstr+0x3a>
  return strlen(buf);
    80003722:	8526                	mv	a0,s1
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	740080e7          	jalr	1856(ra) # 80000e64 <strlen>
}
    8000372c:	70a2                	ld	ra,40(sp)
    8000372e:	7402                	ld	s0,32(sp)
    80003730:	64e2                	ld	s1,24(sp)
    80003732:	6942                	ld	s2,16(sp)
    80003734:	69a2                	ld	s3,8(sp)
    80003736:	6145                	addi	sp,sp,48
    80003738:	8082                	ret

000000008000373a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000373a:	1101                	addi	sp,sp,-32
    8000373c:	ec06                	sd	ra,24(sp)
    8000373e:	e822                	sd	s0,16(sp)
    80003740:	e426                	sd	s1,8(sp)
    80003742:	1000                	addi	s0,sp,32
    80003744:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003746:	00000097          	auipc	ra,0x0
    8000374a:	ef2080e7          	jalr	-270(ra) # 80003638 <argraw>
    8000374e:	c088                	sw	a0,0(s1)
  return 0;
}
    80003750:	4501                	li	a0,0
    80003752:	60e2                	ld	ra,24(sp)
    80003754:	6442                	ld	s0,16(sp)
    80003756:	64a2                	ld	s1,8(sp)
    80003758:	6105                	addi	sp,sp,32
    8000375a:	8082                	ret

000000008000375c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000375c:	1101                	addi	sp,sp,-32
    8000375e:	ec06                	sd	ra,24(sp)
    80003760:	e822                	sd	s0,16(sp)
    80003762:	e426                	sd	s1,8(sp)
    80003764:	1000                	addi	s0,sp,32
    80003766:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003768:	00000097          	auipc	ra,0x0
    8000376c:	ed0080e7          	jalr	-304(ra) # 80003638 <argraw>
    80003770:	e088                	sd	a0,0(s1)
  return 0;
}
    80003772:	4501                	li	a0,0
    80003774:	60e2                	ld	ra,24(sp)
    80003776:	6442                	ld	s0,16(sp)
    80003778:	64a2                	ld	s1,8(sp)
    8000377a:	6105                	addi	sp,sp,32
    8000377c:	8082                	ret

000000008000377e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000377e:	1101                	addi	sp,sp,-32
    80003780:	ec06                	sd	ra,24(sp)
    80003782:	e822                	sd	s0,16(sp)
    80003784:	e426                	sd	s1,8(sp)
    80003786:	e04a                	sd	s2,0(sp)
    80003788:	1000                	addi	s0,sp,32
    8000378a:	84ae                	mv	s1,a1
    8000378c:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000378e:	00000097          	auipc	ra,0x0
    80003792:	eaa080e7          	jalr	-342(ra) # 80003638 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003796:	864a                	mv	a2,s2
    80003798:	85a6                	mv	a1,s1
    8000379a:	00000097          	auipc	ra,0x0
    8000379e:	f58080e7          	jalr	-168(ra) # 800036f2 <fetchstr>
}
    800037a2:	60e2                	ld	ra,24(sp)
    800037a4:	6442                	ld	s0,16(sp)
    800037a6:	64a2                	ld	s1,8(sp)
    800037a8:	6902                	ld	s2,0(sp)
    800037aa:	6105                	addi	sp,sp,32
    800037ac:	8082                	ret

00000000800037ae <syscall>:
[SYS_cpu_process_count]   sys_cpu_process_count,
};

void
syscall(void)
{
    800037ae:	1101                	addi	sp,sp,-32
    800037b0:	ec06                	sd	ra,24(sp)
    800037b2:	e822                	sd	s0,16(sp)
    800037b4:	e426                	sd	s1,8(sp)
    800037b6:	e04a                	sd	s2,0(sp)
    800037b8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800037ba:	fffff097          	auipc	ra,0xfffff
    800037be:	914080e7          	jalr	-1772(ra) # 800020ce <myproc>
    800037c2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800037c4:	05853903          	ld	s2,88(a0)
    800037c8:	0a893783          	ld	a5,168(s2)
    800037cc:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800037d0:	37fd                	addiw	a5,a5,-1
    800037d2:	475d                	li	a4,23
    800037d4:	00f76f63          	bltu	a4,a5,800037f2 <syscall+0x44>
    800037d8:	00369713          	slli	a4,a3,0x3
    800037dc:	00005797          	auipc	a5,0x5
    800037e0:	03478793          	addi	a5,a5,52 # 80008810 <syscalls>
    800037e4:	97ba                	add	a5,a5,a4
    800037e6:	639c                	ld	a5,0(a5)
    800037e8:	c789                	beqz	a5,800037f2 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800037ea:	9782                	jalr	a5
    800037ec:	06a93823          	sd	a0,112(s2)
    800037f0:	a839                	j	8000380e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800037f2:	15848613          	addi	a2,s1,344
    800037f6:	588c                	lw	a1,48(s1)
    800037f8:	00005517          	auipc	a0,0x5
    800037fc:	fe050513          	addi	a0,a0,-32 # 800087d8 <states.1826+0x150>
    80003800:	ffffd097          	auipc	ra,0xffffd
    80003804:	d88080e7          	jalr	-632(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003808:	6cbc                	ld	a5,88(s1)
    8000380a:	577d                	li	a4,-1
    8000380c:	fbb8                	sd	a4,112(a5)
  }
}
    8000380e:	60e2                	ld	ra,24(sp)
    80003810:	6442                	ld	s0,16(sp)
    80003812:	64a2                	ld	s1,8(sp)
    80003814:	6902                	ld	s2,0(sp)
    80003816:	6105                	addi	sp,sp,32
    80003818:	8082                	ret

000000008000381a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000381a:	1101                	addi	sp,sp,-32
    8000381c:	ec06                	sd	ra,24(sp)
    8000381e:	e822                	sd	s0,16(sp)
    80003820:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003822:	fec40593          	addi	a1,s0,-20
    80003826:	4501                	li	a0,0
    80003828:	00000097          	auipc	ra,0x0
    8000382c:	f12080e7          	jalr	-238(ra) # 8000373a <argint>
    return -1;
    80003830:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003832:	00054963          	bltz	a0,80003844 <sys_exit+0x2a>
  exit(n);
    80003836:	fec42503          	lw	a0,-20(s0)
    8000383a:	fffff097          	auipc	ra,0xfffff
    8000383e:	6d4080e7          	jalr	1748(ra) # 80002f0e <exit>
  return 0;  // not reached
    80003842:	4781                	li	a5,0
}
    80003844:	853e                	mv	a0,a5
    80003846:	60e2                	ld	ra,24(sp)
    80003848:	6442                	ld	s0,16(sp)
    8000384a:	6105                	addi	sp,sp,32
    8000384c:	8082                	ret

000000008000384e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000384e:	1141                	addi	sp,sp,-16
    80003850:	e406                	sd	ra,8(sp)
    80003852:	e022                	sd	s0,0(sp)
    80003854:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003856:	fffff097          	auipc	ra,0xfffff
    8000385a:	878080e7          	jalr	-1928(ra) # 800020ce <myproc>
}
    8000385e:	5908                	lw	a0,48(a0)
    80003860:	60a2                	ld	ra,8(sp)
    80003862:	6402                	ld	s0,0(sp)
    80003864:	0141                	addi	sp,sp,16
    80003866:	8082                	ret

0000000080003868 <sys_fork>:

uint64
sys_fork(void)
{
    80003868:	1141                	addi	sp,sp,-16
    8000386a:	e406                	sd	ra,8(sp)
    8000386c:	e022                	sd	s0,0(sp)
    8000386e:	0800                	addi	s0,sp,16
  return fork();
    80003870:	fffff097          	auipc	ra,0xfffff
    80003874:	38a080e7          	jalr	906(ra) # 80002bfa <fork>
}
    80003878:	60a2                	ld	ra,8(sp)
    8000387a:	6402                	ld	s0,0(sp)
    8000387c:	0141                	addi	sp,sp,16
    8000387e:	8082                	ret

0000000080003880 <sys_wait>:

uint64
sys_wait(void)
{
    80003880:	1101                	addi	sp,sp,-32
    80003882:	ec06                	sd	ra,24(sp)
    80003884:	e822                	sd	s0,16(sp)
    80003886:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003888:	fe840593          	addi	a1,s0,-24
    8000388c:	4501                	li	a0,0
    8000388e:	00000097          	auipc	ra,0x0
    80003892:	ece080e7          	jalr	-306(ra) # 8000375c <argaddr>
    80003896:	87aa                	mv	a5,a0
    return -1;
    80003898:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000389a:	0007c863          	bltz	a5,800038aa <sys_wait+0x2a>
  return wait(p);
    8000389e:	fe843503          	ld	a0,-24(s0)
    800038a2:	fffff097          	auipc	ra,0xfffff
    800038a6:	ef0080e7          	jalr	-272(ra) # 80002792 <wait>
}
    800038aa:	60e2                	ld	ra,24(sp)
    800038ac:	6442                	ld	s0,16(sp)
    800038ae:	6105                	addi	sp,sp,32
    800038b0:	8082                	ret

00000000800038b2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800038b2:	7179                	addi	sp,sp,-48
    800038b4:	f406                	sd	ra,40(sp)
    800038b6:	f022                	sd	s0,32(sp)
    800038b8:	ec26                	sd	s1,24(sp)
    800038ba:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800038bc:	fdc40593          	addi	a1,s0,-36
    800038c0:	4501                	li	a0,0
    800038c2:	00000097          	auipc	ra,0x0
    800038c6:	e78080e7          	jalr	-392(ra) # 8000373a <argint>
    800038ca:	87aa                	mv	a5,a0
    return -1;
    800038cc:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800038ce:	0207c063          	bltz	a5,800038ee <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800038d2:	ffffe097          	auipc	ra,0xffffe
    800038d6:	7fc080e7          	jalr	2044(ra) # 800020ce <myproc>
    800038da:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800038dc:	fdc42503          	lw	a0,-36(s0)
    800038e0:	fffff097          	auipc	ra,0xfffff
    800038e4:	c5e080e7          	jalr	-930(ra) # 8000253e <growproc>
    800038e8:	00054863          	bltz	a0,800038f8 <sys_sbrk+0x46>
    return -1;
  return addr;
    800038ec:	8526                	mv	a0,s1
}
    800038ee:	70a2                	ld	ra,40(sp)
    800038f0:	7402                	ld	s0,32(sp)
    800038f2:	64e2                	ld	s1,24(sp)
    800038f4:	6145                	addi	sp,sp,48
    800038f6:	8082                	ret
    return -1;
    800038f8:	557d                	li	a0,-1
    800038fa:	bfd5                	j	800038ee <sys_sbrk+0x3c>

00000000800038fc <sys_sleep>:

uint64
sys_sleep(void)
{
    800038fc:	7139                	addi	sp,sp,-64
    800038fe:	fc06                	sd	ra,56(sp)
    80003900:	f822                	sd	s0,48(sp)
    80003902:	f426                	sd	s1,40(sp)
    80003904:	f04a                	sd	s2,32(sp)
    80003906:	ec4e                	sd	s3,24(sp)
    80003908:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000390a:	fcc40593          	addi	a1,s0,-52
    8000390e:	4501                	li	a0,0
    80003910:	00000097          	auipc	ra,0x0
    80003914:	e2a080e7          	jalr	-470(ra) # 8000373a <argint>
    return -1;
    80003918:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000391a:	06054563          	bltz	a0,80003984 <sys_sleep+0x88>
  acquire(&tickslock);
    8000391e:	00014517          	auipc	a0,0x14
    80003922:	33250513          	addi	a0,a0,818 # 80017c50 <tickslock>
    80003926:	ffffd097          	auipc	ra,0xffffd
    8000392a:	2be080e7          	jalr	702(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000392e:	00005917          	auipc	s2,0x5
    80003932:	70292903          	lw	s2,1794(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003936:	fcc42783          	lw	a5,-52(s0)
    8000393a:	cf85                	beqz	a5,80003972 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000393c:	00014997          	auipc	s3,0x14
    80003940:	31498993          	addi	s3,s3,788 # 80017c50 <tickslock>
    80003944:	00005497          	auipc	s1,0x5
    80003948:	6ec48493          	addi	s1,s1,1772 # 80009030 <ticks>
    if(myproc()->killed){
    8000394c:	ffffe097          	auipc	ra,0xffffe
    80003950:	782080e7          	jalr	1922(ra) # 800020ce <myproc>
    80003954:	551c                	lw	a5,40(a0)
    80003956:	ef9d                	bnez	a5,80003994 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003958:	85ce                	mv	a1,s3
    8000395a:	8526                	mv	a0,s1
    8000395c:	fffff097          	auipc	ra,0xfffff
    80003960:	dac080e7          	jalr	-596(ra) # 80002708 <sleep>
  while(ticks - ticks0 < n){
    80003964:	409c                	lw	a5,0(s1)
    80003966:	412787bb          	subw	a5,a5,s2
    8000396a:	fcc42703          	lw	a4,-52(s0)
    8000396e:	fce7efe3          	bltu	a5,a4,8000394c <sys_sleep+0x50>
  }
  release(&tickslock);
    80003972:	00014517          	auipc	a0,0x14
    80003976:	2de50513          	addi	a0,a0,734 # 80017c50 <tickslock>
    8000397a:	ffffd097          	auipc	ra,0xffffd
    8000397e:	31e080e7          	jalr	798(ra) # 80000c98 <release>
  return 0;
    80003982:	4781                	li	a5,0
}
    80003984:	853e                	mv	a0,a5
    80003986:	70e2                	ld	ra,56(sp)
    80003988:	7442                	ld	s0,48(sp)
    8000398a:	74a2                	ld	s1,40(sp)
    8000398c:	7902                	ld	s2,32(sp)
    8000398e:	69e2                	ld	s3,24(sp)
    80003990:	6121                	addi	sp,sp,64
    80003992:	8082                	ret
      release(&tickslock);
    80003994:	00014517          	auipc	a0,0x14
    80003998:	2bc50513          	addi	a0,a0,700 # 80017c50 <tickslock>
    8000399c:	ffffd097          	auipc	ra,0xffffd
    800039a0:	2fc080e7          	jalr	764(ra) # 80000c98 <release>
      return -1;
    800039a4:	57fd                	li	a5,-1
    800039a6:	bff9                	j	80003984 <sys_sleep+0x88>

00000000800039a8 <sys_kill>:

uint64
sys_kill(void)
{
    800039a8:	1101                	addi	sp,sp,-32
    800039aa:	ec06                	sd	ra,24(sp)
    800039ac:	e822                	sd	s0,16(sp)
    800039ae:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800039b0:	fec40593          	addi	a1,s0,-20
    800039b4:	4501                	li	a0,0
    800039b6:	00000097          	auipc	ra,0x0
    800039ba:	d84080e7          	jalr	-636(ra) # 8000373a <argint>
    800039be:	87aa                	mv	a5,a0
    return -1;
    800039c0:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800039c2:	0007c863          	bltz	a5,800039d2 <sys_kill+0x2a>
  return kill(pid);
    800039c6:	fec42503          	lw	a0,-20(s0)
    800039ca:	fffff097          	auipc	ra,0xfffff
    800039ce:	ef0080e7          	jalr	-272(ra) # 800028ba <kill>
}
    800039d2:	60e2                	ld	ra,24(sp)
    800039d4:	6442                	ld	s0,16(sp)
    800039d6:	6105                	addi	sp,sp,32
    800039d8:	8082                	ret

00000000800039da <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800039da:	1101                	addi	sp,sp,-32
    800039dc:	ec06                	sd	ra,24(sp)
    800039de:	e822                	sd	s0,16(sp)
    800039e0:	e426                	sd	s1,8(sp)
    800039e2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800039e4:	00014517          	auipc	a0,0x14
    800039e8:	26c50513          	addi	a0,a0,620 # 80017c50 <tickslock>
    800039ec:	ffffd097          	auipc	ra,0xffffd
    800039f0:	1f8080e7          	jalr	504(ra) # 80000be4 <acquire>
  xticks = ticks;
    800039f4:	00005497          	auipc	s1,0x5
    800039f8:	63c4a483          	lw	s1,1596(s1) # 80009030 <ticks>
  release(&tickslock);
    800039fc:	00014517          	auipc	a0,0x14
    80003a00:	25450513          	addi	a0,a0,596 # 80017c50 <tickslock>
    80003a04:	ffffd097          	auipc	ra,0xffffd
    80003a08:	294080e7          	jalr	660(ra) # 80000c98 <release>
  return xticks;
}
    80003a0c:	02049513          	slli	a0,s1,0x20
    80003a10:	9101                	srli	a0,a0,0x20
    80003a12:	60e2                	ld	ra,24(sp)
    80003a14:	6442                	ld	s0,16(sp)
    80003a16:	64a2                	ld	s1,8(sp)
    80003a18:	6105                	addi	sp,sp,32
    80003a1a:	8082                	ret

0000000080003a1c <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    80003a1c:	1101                	addi	sp,sp,-32
    80003a1e:	ec06                	sd	ra,24(sp)
    80003a20:	e822                	sd	s0,16(sp)
    80003a22:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    80003a24:	fec40593          	addi	a1,s0,-20
    80003a28:	4501                	li	a0,0
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	d10080e7          	jalr	-752(ra) # 8000373a <argint>
    80003a32:	87aa                	mv	a5,a0
    return -1;
    80003a34:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    80003a36:	0007c863          	bltz	a5,80003a46 <sys_set_cpu+0x2a>
  return set_cpu(cpu_id);
    80003a3a:	fec42503          	lw	a0,-20(s0)
    80003a3e:	fffff097          	auipc	ra,0xfffff
    80003a42:	0a2080e7          	jalr	162(ra) # 80002ae0 <set_cpu>
}
    80003a46:	60e2                	ld	ra,24(sp)
    80003a48:	6442                	ld	s0,16(sp)
    80003a4a:	6105                	addi	sp,sp,32
    80003a4c:	8082                	ret

0000000080003a4e <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    80003a4e:	1141                	addi	sp,sp,-16
    80003a50:	e406                	sd	ra,8(sp)
    80003a52:	e022                	sd	s0,0(sp)
    80003a54:	0800                	addi	s0,sp,16
  return get_cpu();
    80003a56:	fffff097          	auipc	ra,0xfffff
    80003a5a:	0dc080e7          	jalr	220(ra) # 80002b32 <get_cpu>
}
    80003a5e:	60a2                	ld	ra,8(sp)
    80003a60:	6402                	ld	s0,0(sp)
    80003a62:	0141                	addi	sp,sp,16
    80003a64:	8082                	ret

0000000080003a66 <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void)
{
    80003a66:	1101                	addi	sp,sp,-32
    80003a68:	ec06                	sd	ra,24(sp)
    80003a6a:	e822                	sd	s0,16(sp)
    80003a6c:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    80003a6e:	fec40593          	addi	a1,s0,-20
    80003a72:	4501                	li	a0,0
    80003a74:	00000097          	auipc	ra,0x0
    80003a78:	cc6080e7          	jalr	-826(ra) # 8000373a <argint>
    80003a7c:	87aa                	mv	a5,a0
    return -1;
    80003a7e:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    80003a80:	0007c863          	bltz	a5,80003a90 <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpu_id);
    80003a84:	fec42503          	lw	a0,-20(s0)
    80003a88:	fffff097          	auipc	ra,0xfffff
    80003a8c:	10e080e7          	jalr	270(ra) # 80002b96 <cpu_process_count>
}
    80003a90:	60e2                	ld	ra,24(sp)
    80003a92:	6442                	ld	s0,16(sp)
    80003a94:	6105                	addi	sp,sp,32
    80003a96:	8082                	ret

0000000080003a98 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003a98:	7179                	addi	sp,sp,-48
    80003a9a:	f406                	sd	ra,40(sp)
    80003a9c:	f022                	sd	s0,32(sp)
    80003a9e:	ec26                	sd	s1,24(sp)
    80003aa0:	e84a                	sd	s2,16(sp)
    80003aa2:	e44e                	sd	s3,8(sp)
    80003aa4:	e052                	sd	s4,0(sp)
    80003aa6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003aa8:	00005597          	auipc	a1,0x5
    80003aac:	e3058593          	addi	a1,a1,-464 # 800088d8 <syscalls+0xc8>
    80003ab0:	00014517          	auipc	a0,0x14
    80003ab4:	1b850513          	addi	a0,a0,440 # 80017c68 <bcache>
    80003ab8:	ffffd097          	auipc	ra,0xffffd
    80003abc:	09c080e7          	jalr	156(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003ac0:	0001c797          	auipc	a5,0x1c
    80003ac4:	1a878793          	addi	a5,a5,424 # 8001fc68 <bcache+0x8000>
    80003ac8:	0001c717          	auipc	a4,0x1c
    80003acc:	40870713          	addi	a4,a4,1032 # 8001fed0 <bcache+0x8268>
    80003ad0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003ad4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003ad8:	00014497          	auipc	s1,0x14
    80003adc:	1a848493          	addi	s1,s1,424 # 80017c80 <bcache+0x18>
    b->next = bcache.head.next;
    80003ae0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003ae2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003ae4:	00005a17          	auipc	s4,0x5
    80003ae8:	dfca0a13          	addi	s4,s4,-516 # 800088e0 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003aec:	2b893783          	ld	a5,696(s2)
    80003af0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003af2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003af6:	85d2                	mv	a1,s4
    80003af8:	01048513          	addi	a0,s1,16
    80003afc:	00001097          	auipc	ra,0x1
    80003b00:	4bc080e7          	jalr	1212(ra) # 80004fb8 <initsleeplock>
    bcache.head.next->prev = b;
    80003b04:	2b893783          	ld	a5,696(s2)
    80003b08:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003b0a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003b0e:	45848493          	addi	s1,s1,1112
    80003b12:	fd349de3          	bne	s1,s3,80003aec <binit+0x54>
  }
}
    80003b16:	70a2                	ld	ra,40(sp)
    80003b18:	7402                	ld	s0,32(sp)
    80003b1a:	64e2                	ld	s1,24(sp)
    80003b1c:	6942                	ld	s2,16(sp)
    80003b1e:	69a2                	ld	s3,8(sp)
    80003b20:	6a02                	ld	s4,0(sp)
    80003b22:	6145                	addi	sp,sp,48
    80003b24:	8082                	ret

0000000080003b26 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003b26:	7179                	addi	sp,sp,-48
    80003b28:	f406                	sd	ra,40(sp)
    80003b2a:	f022                	sd	s0,32(sp)
    80003b2c:	ec26                	sd	s1,24(sp)
    80003b2e:	e84a                	sd	s2,16(sp)
    80003b30:	e44e                	sd	s3,8(sp)
    80003b32:	1800                	addi	s0,sp,48
    80003b34:	89aa                	mv	s3,a0
    80003b36:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003b38:	00014517          	auipc	a0,0x14
    80003b3c:	13050513          	addi	a0,a0,304 # 80017c68 <bcache>
    80003b40:	ffffd097          	auipc	ra,0xffffd
    80003b44:	0a4080e7          	jalr	164(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003b48:	0001c497          	auipc	s1,0x1c
    80003b4c:	3d84b483          	ld	s1,984(s1) # 8001ff20 <bcache+0x82b8>
    80003b50:	0001c797          	auipc	a5,0x1c
    80003b54:	38078793          	addi	a5,a5,896 # 8001fed0 <bcache+0x8268>
    80003b58:	02f48f63          	beq	s1,a5,80003b96 <bread+0x70>
    80003b5c:	873e                	mv	a4,a5
    80003b5e:	a021                	j	80003b66 <bread+0x40>
    80003b60:	68a4                	ld	s1,80(s1)
    80003b62:	02e48a63          	beq	s1,a4,80003b96 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003b66:	449c                	lw	a5,8(s1)
    80003b68:	ff379ce3          	bne	a5,s3,80003b60 <bread+0x3a>
    80003b6c:	44dc                	lw	a5,12(s1)
    80003b6e:	ff2799e3          	bne	a5,s2,80003b60 <bread+0x3a>
      b->refcnt++;
    80003b72:	40bc                	lw	a5,64(s1)
    80003b74:	2785                	addiw	a5,a5,1
    80003b76:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b78:	00014517          	auipc	a0,0x14
    80003b7c:	0f050513          	addi	a0,a0,240 # 80017c68 <bcache>
    80003b80:	ffffd097          	auipc	ra,0xffffd
    80003b84:	118080e7          	jalr	280(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003b88:	01048513          	addi	a0,s1,16
    80003b8c:	00001097          	auipc	ra,0x1
    80003b90:	466080e7          	jalr	1126(ra) # 80004ff2 <acquiresleep>
      return b;
    80003b94:	a8b9                	j	80003bf2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b96:	0001c497          	auipc	s1,0x1c
    80003b9a:	3824b483          	ld	s1,898(s1) # 8001ff18 <bcache+0x82b0>
    80003b9e:	0001c797          	auipc	a5,0x1c
    80003ba2:	33278793          	addi	a5,a5,818 # 8001fed0 <bcache+0x8268>
    80003ba6:	00f48863          	beq	s1,a5,80003bb6 <bread+0x90>
    80003baa:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003bac:	40bc                	lw	a5,64(s1)
    80003bae:	cf81                	beqz	a5,80003bc6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003bb0:	64a4                	ld	s1,72(s1)
    80003bb2:	fee49de3          	bne	s1,a4,80003bac <bread+0x86>
  panic("bget: no buffers");
    80003bb6:	00005517          	auipc	a0,0x5
    80003bba:	d3250513          	addi	a0,a0,-718 # 800088e8 <syscalls+0xd8>
    80003bbe:	ffffd097          	auipc	ra,0xffffd
    80003bc2:	980080e7          	jalr	-1664(ra) # 8000053e <panic>
      b->dev = dev;
    80003bc6:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003bca:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003bce:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003bd2:	4785                	li	a5,1
    80003bd4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003bd6:	00014517          	auipc	a0,0x14
    80003bda:	09250513          	addi	a0,a0,146 # 80017c68 <bcache>
    80003bde:	ffffd097          	auipc	ra,0xffffd
    80003be2:	0ba080e7          	jalr	186(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003be6:	01048513          	addi	a0,s1,16
    80003bea:	00001097          	auipc	ra,0x1
    80003bee:	408080e7          	jalr	1032(ra) # 80004ff2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003bf2:	409c                	lw	a5,0(s1)
    80003bf4:	cb89                	beqz	a5,80003c06 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003bf6:	8526                	mv	a0,s1
    80003bf8:	70a2                	ld	ra,40(sp)
    80003bfa:	7402                	ld	s0,32(sp)
    80003bfc:	64e2                	ld	s1,24(sp)
    80003bfe:	6942                	ld	s2,16(sp)
    80003c00:	69a2                	ld	s3,8(sp)
    80003c02:	6145                	addi	sp,sp,48
    80003c04:	8082                	ret
    virtio_disk_rw(b, 0);
    80003c06:	4581                	li	a1,0
    80003c08:	8526                	mv	a0,s1
    80003c0a:	00003097          	auipc	ra,0x3
    80003c0e:	f0c080e7          	jalr	-244(ra) # 80006b16 <virtio_disk_rw>
    b->valid = 1;
    80003c12:	4785                	li	a5,1
    80003c14:	c09c                	sw	a5,0(s1)
  return b;
    80003c16:	b7c5                	j	80003bf6 <bread+0xd0>

0000000080003c18 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003c18:	1101                	addi	sp,sp,-32
    80003c1a:	ec06                	sd	ra,24(sp)
    80003c1c:	e822                	sd	s0,16(sp)
    80003c1e:	e426                	sd	s1,8(sp)
    80003c20:	1000                	addi	s0,sp,32
    80003c22:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c24:	0541                	addi	a0,a0,16
    80003c26:	00001097          	auipc	ra,0x1
    80003c2a:	466080e7          	jalr	1126(ra) # 8000508c <holdingsleep>
    80003c2e:	cd01                	beqz	a0,80003c46 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003c30:	4585                	li	a1,1
    80003c32:	8526                	mv	a0,s1
    80003c34:	00003097          	auipc	ra,0x3
    80003c38:	ee2080e7          	jalr	-286(ra) # 80006b16 <virtio_disk_rw>
}
    80003c3c:	60e2                	ld	ra,24(sp)
    80003c3e:	6442                	ld	s0,16(sp)
    80003c40:	64a2                	ld	s1,8(sp)
    80003c42:	6105                	addi	sp,sp,32
    80003c44:	8082                	ret
    panic("bwrite");
    80003c46:	00005517          	auipc	a0,0x5
    80003c4a:	cba50513          	addi	a0,a0,-838 # 80008900 <syscalls+0xf0>
    80003c4e:	ffffd097          	auipc	ra,0xffffd
    80003c52:	8f0080e7          	jalr	-1808(ra) # 8000053e <panic>

0000000080003c56 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003c56:	1101                	addi	sp,sp,-32
    80003c58:	ec06                	sd	ra,24(sp)
    80003c5a:	e822                	sd	s0,16(sp)
    80003c5c:	e426                	sd	s1,8(sp)
    80003c5e:	e04a                	sd	s2,0(sp)
    80003c60:	1000                	addi	s0,sp,32
    80003c62:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c64:	01050913          	addi	s2,a0,16
    80003c68:	854a                	mv	a0,s2
    80003c6a:	00001097          	auipc	ra,0x1
    80003c6e:	422080e7          	jalr	1058(ra) # 8000508c <holdingsleep>
    80003c72:	c92d                	beqz	a0,80003ce4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003c74:	854a                	mv	a0,s2
    80003c76:	00001097          	auipc	ra,0x1
    80003c7a:	3d2080e7          	jalr	978(ra) # 80005048 <releasesleep>

  acquire(&bcache.lock);
    80003c7e:	00014517          	auipc	a0,0x14
    80003c82:	fea50513          	addi	a0,a0,-22 # 80017c68 <bcache>
    80003c86:	ffffd097          	auipc	ra,0xffffd
    80003c8a:	f5e080e7          	jalr	-162(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003c8e:	40bc                	lw	a5,64(s1)
    80003c90:	37fd                	addiw	a5,a5,-1
    80003c92:	0007871b          	sext.w	a4,a5
    80003c96:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003c98:	eb05                	bnez	a4,80003cc8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003c9a:	68bc                	ld	a5,80(s1)
    80003c9c:	64b8                	ld	a4,72(s1)
    80003c9e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003ca0:	64bc                	ld	a5,72(s1)
    80003ca2:	68b8                	ld	a4,80(s1)
    80003ca4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003ca6:	0001c797          	auipc	a5,0x1c
    80003caa:	fc278793          	addi	a5,a5,-62 # 8001fc68 <bcache+0x8000>
    80003cae:	2b87b703          	ld	a4,696(a5)
    80003cb2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003cb4:	0001c717          	auipc	a4,0x1c
    80003cb8:	21c70713          	addi	a4,a4,540 # 8001fed0 <bcache+0x8268>
    80003cbc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003cbe:	2b87b703          	ld	a4,696(a5)
    80003cc2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003cc4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003cc8:	00014517          	auipc	a0,0x14
    80003ccc:	fa050513          	addi	a0,a0,-96 # 80017c68 <bcache>
    80003cd0:	ffffd097          	auipc	ra,0xffffd
    80003cd4:	fc8080e7          	jalr	-56(ra) # 80000c98 <release>
}
    80003cd8:	60e2                	ld	ra,24(sp)
    80003cda:	6442                	ld	s0,16(sp)
    80003cdc:	64a2                	ld	s1,8(sp)
    80003cde:	6902                	ld	s2,0(sp)
    80003ce0:	6105                	addi	sp,sp,32
    80003ce2:	8082                	ret
    panic("brelse");
    80003ce4:	00005517          	auipc	a0,0x5
    80003ce8:	c2450513          	addi	a0,a0,-988 # 80008908 <syscalls+0xf8>
    80003cec:	ffffd097          	auipc	ra,0xffffd
    80003cf0:	852080e7          	jalr	-1966(ra) # 8000053e <panic>

0000000080003cf4 <bpin>:

void
bpin(struct buf *b) {
    80003cf4:	1101                	addi	sp,sp,-32
    80003cf6:	ec06                	sd	ra,24(sp)
    80003cf8:	e822                	sd	s0,16(sp)
    80003cfa:	e426                	sd	s1,8(sp)
    80003cfc:	1000                	addi	s0,sp,32
    80003cfe:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003d00:	00014517          	auipc	a0,0x14
    80003d04:	f6850513          	addi	a0,a0,-152 # 80017c68 <bcache>
    80003d08:	ffffd097          	auipc	ra,0xffffd
    80003d0c:	edc080e7          	jalr	-292(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003d10:	40bc                	lw	a5,64(s1)
    80003d12:	2785                	addiw	a5,a5,1
    80003d14:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d16:	00014517          	auipc	a0,0x14
    80003d1a:	f5250513          	addi	a0,a0,-174 # 80017c68 <bcache>
    80003d1e:	ffffd097          	auipc	ra,0xffffd
    80003d22:	f7a080e7          	jalr	-134(ra) # 80000c98 <release>
}
    80003d26:	60e2                	ld	ra,24(sp)
    80003d28:	6442                	ld	s0,16(sp)
    80003d2a:	64a2                	ld	s1,8(sp)
    80003d2c:	6105                	addi	sp,sp,32
    80003d2e:	8082                	ret

0000000080003d30 <bunpin>:

void
bunpin(struct buf *b) {
    80003d30:	1101                	addi	sp,sp,-32
    80003d32:	ec06                	sd	ra,24(sp)
    80003d34:	e822                	sd	s0,16(sp)
    80003d36:	e426                	sd	s1,8(sp)
    80003d38:	1000                	addi	s0,sp,32
    80003d3a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003d3c:	00014517          	auipc	a0,0x14
    80003d40:	f2c50513          	addi	a0,a0,-212 # 80017c68 <bcache>
    80003d44:	ffffd097          	auipc	ra,0xffffd
    80003d48:	ea0080e7          	jalr	-352(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003d4c:	40bc                	lw	a5,64(s1)
    80003d4e:	37fd                	addiw	a5,a5,-1
    80003d50:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d52:	00014517          	auipc	a0,0x14
    80003d56:	f1650513          	addi	a0,a0,-234 # 80017c68 <bcache>
    80003d5a:	ffffd097          	auipc	ra,0xffffd
    80003d5e:	f3e080e7          	jalr	-194(ra) # 80000c98 <release>
}
    80003d62:	60e2                	ld	ra,24(sp)
    80003d64:	6442                	ld	s0,16(sp)
    80003d66:	64a2                	ld	s1,8(sp)
    80003d68:	6105                	addi	sp,sp,32
    80003d6a:	8082                	ret

0000000080003d6c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003d6c:	1101                	addi	sp,sp,-32
    80003d6e:	ec06                	sd	ra,24(sp)
    80003d70:	e822                	sd	s0,16(sp)
    80003d72:	e426                	sd	s1,8(sp)
    80003d74:	e04a                	sd	s2,0(sp)
    80003d76:	1000                	addi	s0,sp,32
    80003d78:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003d7a:	00d5d59b          	srliw	a1,a1,0xd
    80003d7e:	0001c797          	auipc	a5,0x1c
    80003d82:	5c67a783          	lw	a5,1478(a5) # 80020344 <sb+0x1c>
    80003d86:	9dbd                	addw	a1,a1,a5
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	d9e080e7          	jalr	-610(ra) # 80003b26 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003d90:	0074f713          	andi	a4,s1,7
    80003d94:	4785                	li	a5,1
    80003d96:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003d9a:	14ce                	slli	s1,s1,0x33
    80003d9c:	90d9                	srli	s1,s1,0x36
    80003d9e:	00950733          	add	a4,a0,s1
    80003da2:	05874703          	lbu	a4,88(a4)
    80003da6:	00e7f6b3          	and	a3,a5,a4
    80003daa:	c69d                	beqz	a3,80003dd8 <bfree+0x6c>
    80003dac:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003dae:	94aa                	add	s1,s1,a0
    80003db0:	fff7c793          	not	a5,a5
    80003db4:	8ff9                	and	a5,a5,a4
    80003db6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003dba:	00001097          	auipc	ra,0x1
    80003dbe:	118080e7          	jalr	280(ra) # 80004ed2 <log_write>
  brelse(bp);
    80003dc2:	854a                	mv	a0,s2
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	e92080e7          	jalr	-366(ra) # 80003c56 <brelse>
}
    80003dcc:	60e2                	ld	ra,24(sp)
    80003dce:	6442                	ld	s0,16(sp)
    80003dd0:	64a2                	ld	s1,8(sp)
    80003dd2:	6902                	ld	s2,0(sp)
    80003dd4:	6105                	addi	sp,sp,32
    80003dd6:	8082                	ret
    panic("freeing free block");
    80003dd8:	00005517          	auipc	a0,0x5
    80003ddc:	b3850513          	addi	a0,a0,-1224 # 80008910 <syscalls+0x100>
    80003de0:	ffffc097          	auipc	ra,0xffffc
    80003de4:	75e080e7          	jalr	1886(ra) # 8000053e <panic>

0000000080003de8 <balloc>:
{
    80003de8:	711d                	addi	sp,sp,-96
    80003dea:	ec86                	sd	ra,88(sp)
    80003dec:	e8a2                	sd	s0,80(sp)
    80003dee:	e4a6                	sd	s1,72(sp)
    80003df0:	e0ca                	sd	s2,64(sp)
    80003df2:	fc4e                	sd	s3,56(sp)
    80003df4:	f852                	sd	s4,48(sp)
    80003df6:	f456                	sd	s5,40(sp)
    80003df8:	f05a                	sd	s6,32(sp)
    80003dfa:	ec5e                	sd	s7,24(sp)
    80003dfc:	e862                	sd	s8,16(sp)
    80003dfe:	e466                	sd	s9,8(sp)
    80003e00:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003e02:	0001c797          	auipc	a5,0x1c
    80003e06:	52a7a783          	lw	a5,1322(a5) # 8002032c <sb+0x4>
    80003e0a:	cbd1                	beqz	a5,80003e9e <balloc+0xb6>
    80003e0c:	8baa                	mv	s7,a0
    80003e0e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003e10:	0001cb17          	auipc	s6,0x1c
    80003e14:	518b0b13          	addi	s6,s6,1304 # 80020328 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e18:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003e1a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e1c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003e1e:	6c89                	lui	s9,0x2
    80003e20:	a831                	j	80003e3c <balloc+0x54>
    brelse(bp);
    80003e22:	854a                	mv	a0,s2
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	e32080e7          	jalr	-462(ra) # 80003c56 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003e2c:	015c87bb          	addw	a5,s9,s5
    80003e30:	00078a9b          	sext.w	s5,a5
    80003e34:	004b2703          	lw	a4,4(s6)
    80003e38:	06eaf363          	bgeu	s5,a4,80003e9e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003e3c:	41fad79b          	sraiw	a5,s5,0x1f
    80003e40:	0137d79b          	srliw	a5,a5,0x13
    80003e44:	015787bb          	addw	a5,a5,s5
    80003e48:	40d7d79b          	sraiw	a5,a5,0xd
    80003e4c:	01cb2583          	lw	a1,28(s6)
    80003e50:	9dbd                	addw	a1,a1,a5
    80003e52:	855e                	mv	a0,s7
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	cd2080e7          	jalr	-814(ra) # 80003b26 <bread>
    80003e5c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e5e:	004b2503          	lw	a0,4(s6)
    80003e62:	000a849b          	sext.w	s1,s5
    80003e66:	8662                	mv	a2,s8
    80003e68:	faa4fde3          	bgeu	s1,a0,80003e22 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003e6c:	41f6579b          	sraiw	a5,a2,0x1f
    80003e70:	01d7d69b          	srliw	a3,a5,0x1d
    80003e74:	00c6873b          	addw	a4,a3,a2
    80003e78:	00777793          	andi	a5,a4,7
    80003e7c:	9f95                	subw	a5,a5,a3
    80003e7e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003e82:	4037571b          	sraiw	a4,a4,0x3
    80003e86:	00e906b3          	add	a3,s2,a4
    80003e8a:	0586c683          	lbu	a3,88(a3)
    80003e8e:	00d7f5b3          	and	a1,a5,a3
    80003e92:	cd91                	beqz	a1,80003eae <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e94:	2605                	addiw	a2,a2,1
    80003e96:	2485                	addiw	s1,s1,1
    80003e98:	fd4618e3          	bne	a2,s4,80003e68 <balloc+0x80>
    80003e9c:	b759                	j	80003e22 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003e9e:	00005517          	auipc	a0,0x5
    80003ea2:	a8a50513          	addi	a0,a0,-1398 # 80008928 <syscalls+0x118>
    80003ea6:	ffffc097          	auipc	ra,0xffffc
    80003eaa:	698080e7          	jalr	1688(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003eae:	974a                	add	a4,a4,s2
    80003eb0:	8fd5                	or	a5,a5,a3
    80003eb2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003eb6:	854a                	mv	a0,s2
    80003eb8:	00001097          	auipc	ra,0x1
    80003ebc:	01a080e7          	jalr	26(ra) # 80004ed2 <log_write>
        brelse(bp);
    80003ec0:	854a                	mv	a0,s2
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	d94080e7          	jalr	-620(ra) # 80003c56 <brelse>
  bp = bread(dev, bno);
    80003eca:	85a6                	mv	a1,s1
    80003ecc:	855e                	mv	a0,s7
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	c58080e7          	jalr	-936(ra) # 80003b26 <bread>
    80003ed6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003ed8:	40000613          	li	a2,1024
    80003edc:	4581                	li	a1,0
    80003ede:	05850513          	addi	a0,a0,88
    80003ee2:	ffffd097          	auipc	ra,0xffffd
    80003ee6:	dfe080e7          	jalr	-514(ra) # 80000ce0 <memset>
  log_write(bp);
    80003eea:	854a                	mv	a0,s2
    80003eec:	00001097          	auipc	ra,0x1
    80003ef0:	fe6080e7          	jalr	-26(ra) # 80004ed2 <log_write>
  brelse(bp);
    80003ef4:	854a                	mv	a0,s2
    80003ef6:	00000097          	auipc	ra,0x0
    80003efa:	d60080e7          	jalr	-672(ra) # 80003c56 <brelse>
}
    80003efe:	8526                	mv	a0,s1
    80003f00:	60e6                	ld	ra,88(sp)
    80003f02:	6446                	ld	s0,80(sp)
    80003f04:	64a6                	ld	s1,72(sp)
    80003f06:	6906                	ld	s2,64(sp)
    80003f08:	79e2                	ld	s3,56(sp)
    80003f0a:	7a42                	ld	s4,48(sp)
    80003f0c:	7aa2                	ld	s5,40(sp)
    80003f0e:	7b02                	ld	s6,32(sp)
    80003f10:	6be2                	ld	s7,24(sp)
    80003f12:	6c42                	ld	s8,16(sp)
    80003f14:	6ca2                	ld	s9,8(sp)
    80003f16:	6125                	addi	sp,sp,96
    80003f18:	8082                	ret

0000000080003f1a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003f1a:	7179                	addi	sp,sp,-48
    80003f1c:	f406                	sd	ra,40(sp)
    80003f1e:	f022                	sd	s0,32(sp)
    80003f20:	ec26                	sd	s1,24(sp)
    80003f22:	e84a                	sd	s2,16(sp)
    80003f24:	e44e                	sd	s3,8(sp)
    80003f26:	e052                	sd	s4,0(sp)
    80003f28:	1800                	addi	s0,sp,48
    80003f2a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003f2c:	47ad                	li	a5,11
    80003f2e:	04b7fe63          	bgeu	a5,a1,80003f8a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003f32:	ff45849b          	addiw	s1,a1,-12
    80003f36:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003f3a:	0ff00793          	li	a5,255
    80003f3e:	0ae7e363          	bltu	a5,a4,80003fe4 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003f42:	08052583          	lw	a1,128(a0)
    80003f46:	c5ad                	beqz	a1,80003fb0 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003f48:	00092503          	lw	a0,0(s2)
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	bda080e7          	jalr	-1062(ra) # 80003b26 <bread>
    80003f54:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003f56:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003f5a:	02049593          	slli	a1,s1,0x20
    80003f5e:	9181                	srli	a1,a1,0x20
    80003f60:	058a                	slli	a1,a1,0x2
    80003f62:	00b784b3          	add	s1,a5,a1
    80003f66:	0004a983          	lw	s3,0(s1)
    80003f6a:	04098d63          	beqz	s3,80003fc4 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003f6e:	8552                	mv	a0,s4
    80003f70:	00000097          	auipc	ra,0x0
    80003f74:	ce6080e7          	jalr	-794(ra) # 80003c56 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003f78:	854e                	mv	a0,s3
    80003f7a:	70a2                	ld	ra,40(sp)
    80003f7c:	7402                	ld	s0,32(sp)
    80003f7e:	64e2                	ld	s1,24(sp)
    80003f80:	6942                	ld	s2,16(sp)
    80003f82:	69a2                	ld	s3,8(sp)
    80003f84:	6a02                	ld	s4,0(sp)
    80003f86:	6145                	addi	sp,sp,48
    80003f88:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003f8a:	02059493          	slli	s1,a1,0x20
    80003f8e:	9081                	srli	s1,s1,0x20
    80003f90:	048a                	slli	s1,s1,0x2
    80003f92:	94aa                	add	s1,s1,a0
    80003f94:	0504a983          	lw	s3,80(s1)
    80003f98:	fe0990e3          	bnez	s3,80003f78 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003f9c:	4108                	lw	a0,0(a0)
    80003f9e:	00000097          	auipc	ra,0x0
    80003fa2:	e4a080e7          	jalr	-438(ra) # 80003de8 <balloc>
    80003fa6:	0005099b          	sext.w	s3,a0
    80003faa:	0534a823          	sw	s3,80(s1)
    80003fae:	b7e9                	j	80003f78 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003fb0:	4108                	lw	a0,0(a0)
    80003fb2:	00000097          	auipc	ra,0x0
    80003fb6:	e36080e7          	jalr	-458(ra) # 80003de8 <balloc>
    80003fba:	0005059b          	sext.w	a1,a0
    80003fbe:	08b92023          	sw	a1,128(s2)
    80003fc2:	b759                	j	80003f48 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003fc4:	00092503          	lw	a0,0(s2)
    80003fc8:	00000097          	auipc	ra,0x0
    80003fcc:	e20080e7          	jalr	-480(ra) # 80003de8 <balloc>
    80003fd0:	0005099b          	sext.w	s3,a0
    80003fd4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003fd8:	8552                	mv	a0,s4
    80003fda:	00001097          	auipc	ra,0x1
    80003fde:	ef8080e7          	jalr	-264(ra) # 80004ed2 <log_write>
    80003fe2:	b771                	j	80003f6e <bmap+0x54>
  panic("bmap: out of range");
    80003fe4:	00005517          	auipc	a0,0x5
    80003fe8:	95c50513          	addi	a0,a0,-1700 # 80008940 <syscalls+0x130>
    80003fec:	ffffc097          	auipc	ra,0xffffc
    80003ff0:	552080e7          	jalr	1362(ra) # 8000053e <panic>

0000000080003ff4 <iget>:
{
    80003ff4:	7179                	addi	sp,sp,-48
    80003ff6:	f406                	sd	ra,40(sp)
    80003ff8:	f022                	sd	s0,32(sp)
    80003ffa:	ec26                	sd	s1,24(sp)
    80003ffc:	e84a                	sd	s2,16(sp)
    80003ffe:	e44e                	sd	s3,8(sp)
    80004000:	e052                	sd	s4,0(sp)
    80004002:	1800                	addi	s0,sp,48
    80004004:	89aa                	mv	s3,a0
    80004006:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80004008:	0001c517          	auipc	a0,0x1c
    8000400c:	34050513          	addi	a0,a0,832 # 80020348 <itable>
    80004010:	ffffd097          	auipc	ra,0xffffd
    80004014:	bd4080e7          	jalr	-1068(ra) # 80000be4 <acquire>
  empty = 0;
    80004018:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000401a:	0001c497          	auipc	s1,0x1c
    8000401e:	34648493          	addi	s1,s1,838 # 80020360 <itable+0x18>
    80004022:	0001e697          	auipc	a3,0x1e
    80004026:	dce68693          	addi	a3,a3,-562 # 80021df0 <log>
    8000402a:	a039                	j	80004038 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000402c:	02090b63          	beqz	s2,80004062 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004030:	08848493          	addi	s1,s1,136
    80004034:	02d48a63          	beq	s1,a3,80004068 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80004038:	449c                	lw	a5,8(s1)
    8000403a:	fef059e3          	blez	a5,8000402c <iget+0x38>
    8000403e:	4098                	lw	a4,0(s1)
    80004040:	ff3716e3          	bne	a4,s3,8000402c <iget+0x38>
    80004044:	40d8                	lw	a4,4(s1)
    80004046:	ff4713e3          	bne	a4,s4,8000402c <iget+0x38>
      ip->ref++;
    8000404a:	2785                	addiw	a5,a5,1
    8000404c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000404e:	0001c517          	auipc	a0,0x1c
    80004052:	2fa50513          	addi	a0,a0,762 # 80020348 <itable>
    80004056:	ffffd097          	auipc	ra,0xffffd
    8000405a:	c42080e7          	jalr	-958(ra) # 80000c98 <release>
      return ip;
    8000405e:	8926                	mv	s2,s1
    80004060:	a03d                	j	8000408e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004062:	f7f9                	bnez	a5,80004030 <iget+0x3c>
    80004064:	8926                	mv	s2,s1
    80004066:	b7e9                	j	80004030 <iget+0x3c>
  if(empty == 0)
    80004068:	02090c63          	beqz	s2,800040a0 <iget+0xac>
  ip->dev = dev;
    8000406c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004070:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004074:	4785                	li	a5,1
    80004076:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000407a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000407e:	0001c517          	auipc	a0,0x1c
    80004082:	2ca50513          	addi	a0,a0,714 # 80020348 <itable>
    80004086:	ffffd097          	auipc	ra,0xffffd
    8000408a:	c12080e7          	jalr	-1006(ra) # 80000c98 <release>
}
    8000408e:	854a                	mv	a0,s2
    80004090:	70a2                	ld	ra,40(sp)
    80004092:	7402                	ld	s0,32(sp)
    80004094:	64e2                	ld	s1,24(sp)
    80004096:	6942                	ld	s2,16(sp)
    80004098:	69a2                	ld	s3,8(sp)
    8000409a:	6a02                	ld	s4,0(sp)
    8000409c:	6145                	addi	sp,sp,48
    8000409e:	8082                	ret
    panic("iget: no inodes");
    800040a0:	00005517          	auipc	a0,0x5
    800040a4:	8b850513          	addi	a0,a0,-1864 # 80008958 <syscalls+0x148>
    800040a8:	ffffc097          	auipc	ra,0xffffc
    800040ac:	496080e7          	jalr	1174(ra) # 8000053e <panic>

00000000800040b0 <fsinit>:
fsinit(int dev) {
    800040b0:	7179                	addi	sp,sp,-48
    800040b2:	f406                	sd	ra,40(sp)
    800040b4:	f022                	sd	s0,32(sp)
    800040b6:	ec26                	sd	s1,24(sp)
    800040b8:	e84a                	sd	s2,16(sp)
    800040ba:	e44e                	sd	s3,8(sp)
    800040bc:	1800                	addi	s0,sp,48
    800040be:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800040c0:	4585                	li	a1,1
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	a64080e7          	jalr	-1436(ra) # 80003b26 <bread>
    800040ca:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800040cc:	0001c997          	auipc	s3,0x1c
    800040d0:	25c98993          	addi	s3,s3,604 # 80020328 <sb>
    800040d4:	02000613          	li	a2,32
    800040d8:	05850593          	addi	a1,a0,88
    800040dc:	854e                	mv	a0,s3
    800040de:	ffffd097          	auipc	ra,0xffffd
    800040e2:	c62080e7          	jalr	-926(ra) # 80000d40 <memmove>
  brelse(bp);
    800040e6:	8526                	mv	a0,s1
    800040e8:	00000097          	auipc	ra,0x0
    800040ec:	b6e080e7          	jalr	-1170(ra) # 80003c56 <brelse>
  if(sb.magic != FSMAGIC)
    800040f0:	0009a703          	lw	a4,0(s3)
    800040f4:	102037b7          	lui	a5,0x10203
    800040f8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800040fc:	02f71263          	bne	a4,a5,80004120 <fsinit+0x70>
  initlog(dev, &sb);
    80004100:	0001c597          	auipc	a1,0x1c
    80004104:	22858593          	addi	a1,a1,552 # 80020328 <sb>
    80004108:	854a                	mv	a0,s2
    8000410a:	00001097          	auipc	ra,0x1
    8000410e:	b4c080e7          	jalr	-1204(ra) # 80004c56 <initlog>
}
    80004112:	70a2                	ld	ra,40(sp)
    80004114:	7402                	ld	s0,32(sp)
    80004116:	64e2                	ld	s1,24(sp)
    80004118:	6942                	ld	s2,16(sp)
    8000411a:	69a2                	ld	s3,8(sp)
    8000411c:	6145                	addi	sp,sp,48
    8000411e:	8082                	ret
    panic("invalid file system");
    80004120:	00005517          	auipc	a0,0x5
    80004124:	84850513          	addi	a0,a0,-1976 # 80008968 <syscalls+0x158>
    80004128:	ffffc097          	auipc	ra,0xffffc
    8000412c:	416080e7          	jalr	1046(ra) # 8000053e <panic>

0000000080004130 <iinit>:
{
    80004130:	7179                	addi	sp,sp,-48
    80004132:	f406                	sd	ra,40(sp)
    80004134:	f022                	sd	s0,32(sp)
    80004136:	ec26                	sd	s1,24(sp)
    80004138:	e84a                	sd	s2,16(sp)
    8000413a:	e44e                	sd	s3,8(sp)
    8000413c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000413e:	00005597          	auipc	a1,0x5
    80004142:	84258593          	addi	a1,a1,-1982 # 80008980 <syscalls+0x170>
    80004146:	0001c517          	auipc	a0,0x1c
    8000414a:	20250513          	addi	a0,a0,514 # 80020348 <itable>
    8000414e:	ffffd097          	auipc	ra,0xffffd
    80004152:	a06080e7          	jalr	-1530(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80004156:	0001c497          	auipc	s1,0x1c
    8000415a:	21a48493          	addi	s1,s1,538 # 80020370 <itable+0x28>
    8000415e:	0001e997          	auipc	s3,0x1e
    80004162:	ca298993          	addi	s3,s3,-862 # 80021e00 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004166:	00005917          	auipc	s2,0x5
    8000416a:	82290913          	addi	s2,s2,-2014 # 80008988 <syscalls+0x178>
    8000416e:	85ca                	mv	a1,s2
    80004170:	8526                	mv	a0,s1
    80004172:	00001097          	auipc	ra,0x1
    80004176:	e46080e7          	jalr	-442(ra) # 80004fb8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000417a:	08848493          	addi	s1,s1,136
    8000417e:	ff3498e3          	bne	s1,s3,8000416e <iinit+0x3e>
}
    80004182:	70a2                	ld	ra,40(sp)
    80004184:	7402                	ld	s0,32(sp)
    80004186:	64e2                	ld	s1,24(sp)
    80004188:	6942                	ld	s2,16(sp)
    8000418a:	69a2                	ld	s3,8(sp)
    8000418c:	6145                	addi	sp,sp,48
    8000418e:	8082                	ret

0000000080004190 <ialloc>:
{
    80004190:	715d                	addi	sp,sp,-80
    80004192:	e486                	sd	ra,72(sp)
    80004194:	e0a2                	sd	s0,64(sp)
    80004196:	fc26                	sd	s1,56(sp)
    80004198:	f84a                	sd	s2,48(sp)
    8000419a:	f44e                	sd	s3,40(sp)
    8000419c:	f052                	sd	s4,32(sp)
    8000419e:	ec56                	sd	s5,24(sp)
    800041a0:	e85a                	sd	s6,16(sp)
    800041a2:	e45e                	sd	s7,8(sp)
    800041a4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800041a6:	0001c717          	auipc	a4,0x1c
    800041aa:	18e72703          	lw	a4,398(a4) # 80020334 <sb+0xc>
    800041ae:	4785                	li	a5,1
    800041b0:	04e7fa63          	bgeu	a5,a4,80004204 <ialloc+0x74>
    800041b4:	8aaa                	mv	s5,a0
    800041b6:	8bae                	mv	s7,a1
    800041b8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800041ba:	0001ca17          	auipc	s4,0x1c
    800041be:	16ea0a13          	addi	s4,s4,366 # 80020328 <sb>
    800041c2:	00048b1b          	sext.w	s6,s1
    800041c6:	0044d593          	srli	a1,s1,0x4
    800041ca:	018a2783          	lw	a5,24(s4)
    800041ce:	9dbd                	addw	a1,a1,a5
    800041d0:	8556                	mv	a0,s5
    800041d2:	00000097          	auipc	ra,0x0
    800041d6:	954080e7          	jalr	-1708(ra) # 80003b26 <bread>
    800041da:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800041dc:	05850993          	addi	s3,a0,88
    800041e0:	00f4f793          	andi	a5,s1,15
    800041e4:	079a                	slli	a5,a5,0x6
    800041e6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800041e8:	00099783          	lh	a5,0(s3)
    800041ec:	c785                	beqz	a5,80004214 <ialloc+0x84>
    brelse(bp);
    800041ee:	00000097          	auipc	ra,0x0
    800041f2:	a68080e7          	jalr	-1432(ra) # 80003c56 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800041f6:	0485                	addi	s1,s1,1
    800041f8:	00ca2703          	lw	a4,12(s4)
    800041fc:	0004879b          	sext.w	a5,s1
    80004200:	fce7e1e3          	bltu	a5,a4,800041c2 <ialloc+0x32>
  panic("ialloc: no inodes");
    80004204:	00004517          	auipc	a0,0x4
    80004208:	78c50513          	addi	a0,a0,1932 # 80008990 <syscalls+0x180>
    8000420c:	ffffc097          	auipc	ra,0xffffc
    80004210:	332080e7          	jalr	818(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80004214:	04000613          	li	a2,64
    80004218:	4581                	li	a1,0
    8000421a:	854e                	mv	a0,s3
    8000421c:	ffffd097          	auipc	ra,0xffffd
    80004220:	ac4080e7          	jalr	-1340(ra) # 80000ce0 <memset>
      dip->type = type;
    80004224:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004228:	854a                	mv	a0,s2
    8000422a:	00001097          	auipc	ra,0x1
    8000422e:	ca8080e7          	jalr	-856(ra) # 80004ed2 <log_write>
      brelse(bp);
    80004232:	854a                	mv	a0,s2
    80004234:	00000097          	auipc	ra,0x0
    80004238:	a22080e7          	jalr	-1502(ra) # 80003c56 <brelse>
      return iget(dev, inum);
    8000423c:	85da                	mv	a1,s6
    8000423e:	8556                	mv	a0,s5
    80004240:	00000097          	auipc	ra,0x0
    80004244:	db4080e7          	jalr	-588(ra) # 80003ff4 <iget>
}
    80004248:	60a6                	ld	ra,72(sp)
    8000424a:	6406                	ld	s0,64(sp)
    8000424c:	74e2                	ld	s1,56(sp)
    8000424e:	7942                	ld	s2,48(sp)
    80004250:	79a2                	ld	s3,40(sp)
    80004252:	7a02                	ld	s4,32(sp)
    80004254:	6ae2                	ld	s5,24(sp)
    80004256:	6b42                	ld	s6,16(sp)
    80004258:	6ba2                	ld	s7,8(sp)
    8000425a:	6161                	addi	sp,sp,80
    8000425c:	8082                	ret

000000008000425e <iupdate>:
{
    8000425e:	1101                	addi	sp,sp,-32
    80004260:	ec06                	sd	ra,24(sp)
    80004262:	e822                	sd	s0,16(sp)
    80004264:	e426                	sd	s1,8(sp)
    80004266:	e04a                	sd	s2,0(sp)
    80004268:	1000                	addi	s0,sp,32
    8000426a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000426c:	415c                	lw	a5,4(a0)
    8000426e:	0047d79b          	srliw	a5,a5,0x4
    80004272:	0001c597          	auipc	a1,0x1c
    80004276:	0ce5a583          	lw	a1,206(a1) # 80020340 <sb+0x18>
    8000427a:	9dbd                	addw	a1,a1,a5
    8000427c:	4108                	lw	a0,0(a0)
    8000427e:	00000097          	auipc	ra,0x0
    80004282:	8a8080e7          	jalr	-1880(ra) # 80003b26 <bread>
    80004286:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004288:	05850793          	addi	a5,a0,88
    8000428c:	40c8                	lw	a0,4(s1)
    8000428e:	893d                	andi	a0,a0,15
    80004290:	051a                	slli	a0,a0,0x6
    80004292:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004294:	04449703          	lh	a4,68(s1)
    80004298:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000429c:	04649703          	lh	a4,70(s1)
    800042a0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800042a4:	04849703          	lh	a4,72(s1)
    800042a8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800042ac:	04a49703          	lh	a4,74(s1)
    800042b0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800042b4:	44f8                	lw	a4,76(s1)
    800042b6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800042b8:	03400613          	li	a2,52
    800042bc:	05048593          	addi	a1,s1,80
    800042c0:	0531                	addi	a0,a0,12
    800042c2:	ffffd097          	auipc	ra,0xffffd
    800042c6:	a7e080e7          	jalr	-1410(ra) # 80000d40 <memmove>
  log_write(bp);
    800042ca:	854a                	mv	a0,s2
    800042cc:	00001097          	auipc	ra,0x1
    800042d0:	c06080e7          	jalr	-1018(ra) # 80004ed2 <log_write>
  brelse(bp);
    800042d4:	854a                	mv	a0,s2
    800042d6:	00000097          	auipc	ra,0x0
    800042da:	980080e7          	jalr	-1664(ra) # 80003c56 <brelse>
}
    800042de:	60e2                	ld	ra,24(sp)
    800042e0:	6442                	ld	s0,16(sp)
    800042e2:	64a2                	ld	s1,8(sp)
    800042e4:	6902                	ld	s2,0(sp)
    800042e6:	6105                	addi	sp,sp,32
    800042e8:	8082                	ret

00000000800042ea <idup>:
{
    800042ea:	1101                	addi	sp,sp,-32
    800042ec:	ec06                	sd	ra,24(sp)
    800042ee:	e822                	sd	s0,16(sp)
    800042f0:	e426                	sd	s1,8(sp)
    800042f2:	1000                	addi	s0,sp,32
    800042f4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800042f6:	0001c517          	auipc	a0,0x1c
    800042fa:	05250513          	addi	a0,a0,82 # 80020348 <itable>
    800042fe:	ffffd097          	auipc	ra,0xffffd
    80004302:	8e6080e7          	jalr	-1818(ra) # 80000be4 <acquire>
  ip->ref++;
    80004306:	449c                	lw	a5,8(s1)
    80004308:	2785                	addiw	a5,a5,1
    8000430a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000430c:	0001c517          	auipc	a0,0x1c
    80004310:	03c50513          	addi	a0,a0,60 # 80020348 <itable>
    80004314:	ffffd097          	auipc	ra,0xffffd
    80004318:	984080e7          	jalr	-1660(ra) # 80000c98 <release>
}
    8000431c:	8526                	mv	a0,s1
    8000431e:	60e2                	ld	ra,24(sp)
    80004320:	6442                	ld	s0,16(sp)
    80004322:	64a2                	ld	s1,8(sp)
    80004324:	6105                	addi	sp,sp,32
    80004326:	8082                	ret

0000000080004328 <ilock>:
{
    80004328:	1101                	addi	sp,sp,-32
    8000432a:	ec06                	sd	ra,24(sp)
    8000432c:	e822                	sd	s0,16(sp)
    8000432e:	e426                	sd	s1,8(sp)
    80004330:	e04a                	sd	s2,0(sp)
    80004332:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004334:	c115                	beqz	a0,80004358 <ilock+0x30>
    80004336:	84aa                	mv	s1,a0
    80004338:	451c                	lw	a5,8(a0)
    8000433a:	00f05f63          	blez	a5,80004358 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000433e:	0541                	addi	a0,a0,16
    80004340:	00001097          	auipc	ra,0x1
    80004344:	cb2080e7          	jalr	-846(ra) # 80004ff2 <acquiresleep>
  if(ip->valid == 0){
    80004348:	40bc                	lw	a5,64(s1)
    8000434a:	cf99                	beqz	a5,80004368 <ilock+0x40>
}
    8000434c:	60e2                	ld	ra,24(sp)
    8000434e:	6442                	ld	s0,16(sp)
    80004350:	64a2                	ld	s1,8(sp)
    80004352:	6902                	ld	s2,0(sp)
    80004354:	6105                	addi	sp,sp,32
    80004356:	8082                	ret
    panic("ilock");
    80004358:	00004517          	auipc	a0,0x4
    8000435c:	65050513          	addi	a0,a0,1616 # 800089a8 <syscalls+0x198>
    80004360:	ffffc097          	auipc	ra,0xffffc
    80004364:	1de080e7          	jalr	478(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004368:	40dc                	lw	a5,4(s1)
    8000436a:	0047d79b          	srliw	a5,a5,0x4
    8000436e:	0001c597          	auipc	a1,0x1c
    80004372:	fd25a583          	lw	a1,-46(a1) # 80020340 <sb+0x18>
    80004376:	9dbd                	addw	a1,a1,a5
    80004378:	4088                	lw	a0,0(s1)
    8000437a:	fffff097          	auipc	ra,0xfffff
    8000437e:	7ac080e7          	jalr	1964(ra) # 80003b26 <bread>
    80004382:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004384:	05850593          	addi	a1,a0,88
    80004388:	40dc                	lw	a5,4(s1)
    8000438a:	8bbd                	andi	a5,a5,15
    8000438c:	079a                	slli	a5,a5,0x6
    8000438e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004390:	00059783          	lh	a5,0(a1)
    80004394:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004398:	00259783          	lh	a5,2(a1)
    8000439c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800043a0:	00459783          	lh	a5,4(a1)
    800043a4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800043a8:	00659783          	lh	a5,6(a1)
    800043ac:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800043b0:	459c                	lw	a5,8(a1)
    800043b2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800043b4:	03400613          	li	a2,52
    800043b8:	05b1                	addi	a1,a1,12
    800043ba:	05048513          	addi	a0,s1,80
    800043be:	ffffd097          	auipc	ra,0xffffd
    800043c2:	982080e7          	jalr	-1662(ra) # 80000d40 <memmove>
    brelse(bp);
    800043c6:	854a                	mv	a0,s2
    800043c8:	00000097          	auipc	ra,0x0
    800043cc:	88e080e7          	jalr	-1906(ra) # 80003c56 <brelse>
    ip->valid = 1;
    800043d0:	4785                	li	a5,1
    800043d2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800043d4:	04449783          	lh	a5,68(s1)
    800043d8:	fbb5                	bnez	a5,8000434c <ilock+0x24>
      panic("ilock: no type");
    800043da:	00004517          	auipc	a0,0x4
    800043de:	5d650513          	addi	a0,a0,1494 # 800089b0 <syscalls+0x1a0>
    800043e2:	ffffc097          	auipc	ra,0xffffc
    800043e6:	15c080e7          	jalr	348(ra) # 8000053e <panic>

00000000800043ea <iunlock>:
{
    800043ea:	1101                	addi	sp,sp,-32
    800043ec:	ec06                	sd	ra,24(sp)
    800043ee:	e822                	sd	s0,16(sp)
    800043f0:	e426                	sd	s1,8(sp)
    800043f2:	e04a                	sd	s2,0(sp)
    800043f4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800043f6:	c905                	beqz	a0,80004426 <iunlock+0x3c>
    800043f8:	84aa                	mv	s1,a0
    800043fa:	01050913          	addi	s2,a0,16
    800043fe:	854a                	mv	a0,s2
    80004400:	00001097          	auipc	ra,0x1
    80004404:	c8c080e7          	jalr	-884(ra) # 8000508c <holdingsleep>
    80004408:	cd19                	beqz	a0,80004426 <iunlock+0x3c>
    8000440a:	449c                	lw	a5,8(s1)
    8000440c:	00f05d63          	blez	a5,80004426 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004410:	854a                	mv	a0,s2
    80004412:	00001097          	auipc	ra,0x1
    80004416:	c36080e7          	jalr	-970(ra) # 80005048 <releasesleep>
}
    8000441a:	60e2                	ld	ra,24(sp)
    8000441c:	6442                	ld	s0,16(sp)
    8000441e:	64a2                	ld	s1,8(sp)
    80004420:	6902                	ld	s2,0(sp)
    80004422:	6105                	addi	sp,sp,32
    80004424:	8082                	ret
    panic("iunlock");
    80004426:	00004517          	auipc	a0,0x4
    8000442a:	59a50513          	addi	a0,a0,1434 # 800089c0 <syscalls+0x1b0>
    8000442e:	ffffc097          	auipc	ra,0xffffc
    80004432:	110080e7          	jalr	272(ra) # 8000053e <panic>

0000000080004436 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004436:	7179                	addi	sp,sp,-48
    80004438:	f406                	sd	ra,40(sp)
    8000443a:	f022                	sd	s0,32(sp)
    8000443c:	ec26                	sd	s1,24(sp)
    8000443e:	e84a                	sd	s2,16(sp)
    80004440:	e44e                	sd	s3,8(sp)
    80004442:	e052                	sd	s4,0(sp)
    80004444:	1800                	addi	s0,sp,48
    80004446:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004448:	05050493          	addi	s1,a0,80
    8000444c:	08050913          	addi	s2,a0,128
    80004450:	a021                	j	80004458 <itrunc+0x22>
    80004452:	0491                	addi	s1,s1,4
    80004454:	01248d63          	beq	s1,s2,8000446e <itrunc+0x38>
    if(ip->addrs[i]){
    80004458:	408c                	lw	a1,0(s1)
    8000445a:	dde5                	beqz	a1,80004452 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000445c:	0009a503          	lw	a0,0(s3)
    80004460:	00000097          	auipc	ra,0x0
    80004464:	90c080e7          	jalr	-1780(ra) # 80003d6c <bfree>
      ip->addrs[i] = 0;
    80004468:	0004a023          	sw	zero,0(s1)
    8000446c:	b7dd                	j	80004452 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000446e:	0809a583          	lw	a1,128(s3)
    80004472:	e185                	bnez	a1,80004492 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004474:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004478:	854e                	mv	a0,s3
    8000447a:	00000097          	auipc	ra,0x0
    8000447e:	de4080e7          	jalr	-540(ra) # 8000425e <iupdate>
}
    80004482:	70a2                	ld	ra,40(sp)
    80004484:	7402                	ld	s0,32(sp)
    80004486:	64e2                	ld	s1,24(sp)
    80004488:	6942                	ld	s2,16(sp)
    8000448a:	69a2                	ld	s3,8(sp)
    8000448c:	6a02                	ld	s4,0(sp)
    8000448e:	6145                	addi	sp,sp,48
    80004490:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004492:	0009a503          	lw	a0,0(s3)
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	690080e7          	jalr	1680(ra) # 80003b26 <bread>
    8000449e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800044a0:	05850493          	addi	s1,a0,88
    800044a4:	45850913          	addi	s2,a0,1112
    800044a8:	a811                	j	800044bc <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800044aa:	0009a503          	lw	a0,0(s3)
    800044ae:	00000097          	auipc	ra,0x0
    800044b2:	8be080e7          	jalr	-1858(ra) # 80003d6c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800044b6:	0491                	addi	s1,s1,4
    800044b8:	01248563          	beq	s1,s2,800044c2 <itrunc+0x8c>
      if(a[j])
    800044bc:	408c                	lw	a1,0(s1)
    800044be:	dde5                	beqz	a1,800044b6 <itrunc+0x80>
    800044c0:	b7ed                	j	800044aa <itrunc+0x74>
    brelse(bp);
    800044c2:	8552                	mv	a0,s4
    800044c4:	fffff097          	auipc	ra,0xfffff
    800044c8:	792080e7          	jalr	1938(ra) # 80003c56 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800044cc:	0809a583          	lw	a1,128(s3)
    800044d0:	0009a503          	lw	a0,0(s3)
    800044d4:	00000097          	auipc	ra,0x0
    800044d8:	898080e7          	jalr	-1896(ra) # 80003d6c <bfree>
    ip->addrs[NDIRECT] = 0;
    800044dc:	0809a023          	sw	zero,128(s3)
    800044e0:	bf51                	j	80004474 <itrunc+0x3e>

00000000800044e2 <iput>:
{
    800044e2:	1101                	addi	sp,sp,-32
    800044e4:	ec06                	sd	ra,24(sp)
    800044e6:	e822                	sd	s0,16(sp)
    800044e8:	e426                	sd	s1,8(sp)
    800044ea:	e04a                	sd	s2,0(sp)
    800044ec:	1000                	addi	s0,sp,32
    800044ee:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800044f0:	0001c517          	auipc	a0,0x1c
    800044f4:	e5850513          	addi	a0,a0,-424 # 80020348 <itable>
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	6ec080e7          	jalr	1772(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004500:	4498                	lw	a4,8(s1)
    80004502:	4785                	li	a5,1
    80004504:	02f70363          	beq	a4,a5,8000452a <iput+0x48>
  ip->ref--;
    80004508:	449c                	lw	a5,8(s1)
    8000450a:	37fd                	addiw	a5,a5,-1
    8000450c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000450e:	0001c517          	auipc	a0,0x1c
    80004512:	e3a50513          	addi	a0,a0,-454 # 80020348 <itable>
    80004516:	ffffc097          	auipc	ra,0xffffc
    8000451a:	782080e7          	jalr	1922(ra) # 80000c98 <release>
}
    8000451e:	60e2                	ld	ra,24(sp)
    80004520:	6442                	ld	s0,16(sp)
    80004522:	64a2                	ld	s1,8(sp)
    80004524:	6902                	ld	s2,0(sp)
    80004526:	6105                	addi	sp,sp,32
    80004528:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000452a:	40bc                	lw	a5,64(s1)
    8000452c:	dff1                	beqz	a5,80004508 <iput+0x26>
    8000452e:	04a49783          	lh	a5,74(s1)
    80004532:	fbf9                	bnez	a5,80004508 <iput+0x26>
    acquiresleep(&ip->lock);
    80004534:	01048913          	addi	s2,s1,16
    80004538:	854a                	mv	a0,s2
    8000453a:	00001097          	auipc	ra,0x1
    8000453e:	ab8080e7          	jalr	-1352(ra) # 80004ff2 <acquiresleep>
    release(&itable.lock);
    80004542:	0001c517          	auipc	a0,0x1c
    80004546:	e0650513          	addi	a0,a0,-506 # 80020348 <itable>
    8000454a:	ffffc097          	auipc	ra,0xffffc
    8000454e:	74e080e7          	jalr	1870(ra) # 80000c98 <release>
    itrunc(ip);
    80004552:	8526                	mv	a0,s1
    80004554:	00000097          	auipc	ra,0x0
    80004558:	ee2080e7          	jalr	-286(ra) # 80004436 <itrunc>
    ip->type = 0;
    8000455c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004560:	8526                	mv	a0,s1
    80004562:	00000097          	auipc	ra,0x0
    80004566:	cfc080e7          	jalr	-772(ra) # 8000425e <iupdate>
    ip->valid = 0;
    8000456a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000456e:	854a                	mv	a0,s2
    80004570:	00001097          	auipc	ra,0x1
    80004574:	ad8080e7          	jalr	-1320(ra) # 80005048 <releasesleep>
    acquire(&itable.lock);
    80004578:	0001c517          	auipc	a0,0x1c
    8000457c:	dd050513          	addi	a0,a0,-560 # 80020348 <itable>
    80004580:	ffffc097          	auipc	ra,0xffffc
    80004584:	664080e7          	jalr	1636(ra) # 80000be4 <acquire>
    80004588:	b741                	j	80004508 <iput+0x26>

000000008000458a <iunlockput>:
{
    8000458a:	1101                	addi	sp,sp,-32
    8000458c:	ec06                	sd	ra,24(sp)
    8000458e:	e822                	sd	s0,16(sp)
    80004590:	e426                	sd	s1,8(sp)
    80004592:	1000                	addi	s0,sp,32
    80004594:	84aa                	mv	s1,a0
  iunlock(ip);
    80004596:	00000097          	auipc	ra,0x0
    8000459a:	e54080e7          	jalr	-428(ra) # 800043ea <iunlock>
  iput(ip);
    8000459e:	8526                	mv	a0,s1
    800045a0:	00000097          	auipc	ra,0x0
    800045a4:	f42080e7          	jalr	-190(ra) # 800044e2 <iput>
}
    800045a8:	60e2                	ld	ra,24(sp)
    800045aa:	6442                	ld	s0,16(sp)
    800045ac:	64a2                	ld	s1,8(sp)
    800045ae:	6105                	addi	sp,sp,32
    800045b0:	8082                	ret

00000000800045b2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800045b2:	1141                	addi	sp,sp,-16
    800045b4:	e422                	sd	s0,8(sp)
    800045b6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800045b8:	411c                	lw	a5,0(a0)
    800045ba:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800045bc:	415c                	lw	a5,4(a0)
    800045be:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800045c0:	04451783          	lh	a5,68(a0)
    800045c4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800045c8:	04a51783          	lh	a5,74(a0)
    800045cc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800045d0:	04c56783          	lwu	a5,76(a0)
    800045d4:	e99c                	sd	a5,16(a1)
}
    800045d6:	6422                	ld	s0,8(sp)
    800045d8:	0141                	addi	sp,sp,16
    800045da:	8082                	ret

00000000800045dc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800045dc:	457c                	lw	a5,76(a0)
    800045de:	0ed7e963          	bltu	a5,a3,800046d0 <readi+0xf4>
{
    800045e2:	7159                	addi	sp,sp,-112
    800045e4:	f486                	sd	ra,104(sp)
    800045e6:	f0a2                	sd	s0,96(sp)
    800045e8:	eca6                	sd	s1,88(sp)
    800045ea:	e8ca                	sd	s2,80(sp)
    800045ec:	e4ce                	sd	s3,72(sp)
    800045ee:	e0d2                	sd	s4,64(sp)
    800045f0:	fc56                	sd	s5,56(sp)
    800045f2:	f85a                	sd	s6,48(sp)
    800045f4:	f45e                	sd	s7,40(sp)
    800045f6:	f062                	sd	s8,32(sp)
    800045f8:	ec66                	sd	s9,24(sp)
    800045fa:	e86a                	sd	s10,16(sp)
    800045fc:	e46e                	sd	s11,8(sp)
    800045fe:	1880                	addi	s0,sp,112
    80004600:	8baa                	mv	s7,a0
    80004602:	8c2e                	mv	s8,a1
    80004604:	8ab2                	mv	s5,a2
    80004606:	84b6                	mv	s1,a3
    80004608:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000460a:	9f35                	addw	a4,a4,a3
    return 0;
    8000460c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000460e:	0ad76063          	bltu	a4,a3,800046ae <readi+0xd2>
  if(off + n > ip->size)
    80004612:	00e7f463          	bgeu	a5,a4,8000461a <readi+0x3e>
    n = ip->size - off;
    80004616:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000461a:	0a0b0963          	beqz	s6,800046cc <readi+0xf0>
    8000461e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004620:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004624:	5cfd                	li	s9,-1
    80004626:	a82d                	j	80004660 <readi+0x84>
    80004628:	020a1d93          	slli	s11,s4,0x20
    8000462c:	020ddd93          	srli	s11,s11,0x20
    80004630:	05890613          	addi	a2,s2,88
    80004634:	86ee                	mv	a3,s11
    80004636:	963a                	add	a2,a2,a4
    80004638:	85d6                	mv	a1,s5
    8000463a:	8562                	mv	a0,s8
    8000463c:	ffffe097          	auipc	ra,0xffffe
    80004640:	34a080e7          	jalr	842(ra) # 80002986 <either_copyout>
    80004644:	05950d63          	beq	a0,s9,8000469e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004648:	854a                	mv	a0,s2
    8000464a:	fffff097          	auipc	ra,0xfffff
    8000464e:	60c080e7          	jalr	1548(ra) # 80003c56 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004652:	013a09bb          	addw	s3,s4,s3
    80004656:	009a04bb          	addw	s1,s4,s1
    8000465a:	9aee                	add	s5,s5,s11
    8000465c:	0569f763          	bgeu	s3,s6,800046aa <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004660:	000ba903          	lw	s2,0(s7)
    80004664:	00a4d59b          	srliw	a1,s1,0xa
    80004668:	855e                	mv	a0,s7
    8000466a:	00000097          	auipc	ra,0x0
    8000466e:	8b0080e7          	jalr	-1872(ra) # 80003f1a <bmap>
    80004672:	0005059b          	sext.w	a1,a0
    80004676:	854a                	mv	a0,s2
    80004678:	fffff097          	auipc	ra,0xfffff
    8000467c:	4ae080e7          	jalr	1198(ra) # 80003b26 <bread>
    80004680:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004682:	3ff4f713          	andi	a4,s1,1023
    80004686:	40ed07bb          	subw	a5,s10,a4
    8000468a:	413b06bb          	subw	a3,s6,s3
    8000468e:	8a3e                	mv	s4,a5
    80004690:	2781                	sext.w	a5,a5
    80004692:	0006861b          	sext.w	a2,a3
    80004696:	f8f679e3          	bgeu	a2,a5,80004628 <readi+0x4c>
    8000469a:	8a36                	mv	s4,a3
    8000469c:	b771                	j	80004628 <readi+0x4c>
      brelse(bp);
    8000469e:	854a                	mv	a0,s2
    800046a0:	fffff097          	auipc	ra,0xfffff
    800046a4:	5b6080e7          	jalr	1462(ra) # 80003c56 <brelse>
      tot = -1;
    800046a8:	59fd                	li	s3,-1
  }
  return tot;
    800046aa:	0009851b          	sext.w	a0,s3
}
    800046ae:	70a6                	ld	ra,104(sp)
    800046b0:	7406                	ld	s0,96(sp)
    800046b2:	64e6                	ld	s1,88(sp)
    800046b4:	6946                	ld	s2,80(sp)
    800046b6:	69a6                	ld	s3,72(sp)
    800046b8:	6a06                	ld	s4,64(sp)
    800046ba:	7ae2                	ld	s5,56(sp)
    800046bc:	7b42                	ld	s6,48(sp)
    800046be:	7ba2                	ld	s7,40(sp)
    800046c0:	7c02                	ld	s8,32(sp)
    800046c2:	6ce2                	ld	s9,24(sp)
    800046c4:	6d42                	ld	s10,16(sp)
    800046c6:	6da2                	ld	s11,8(sp)
    800046c8:	6165                	addi	sp,sp,112
    800046ca:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800046cc:	89da                	mv	s3,s6
    800046ce:	bff1                	j	800046aa <readi+0xce>
    return 0;
    800046d0:	4501                	li	a0,0
}
    800046d2:	8082                	ret

00000000800046d4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800046d4:	457c                	lw	a5,76(a0)
    800046d6:	10d7e863          	bltu	a5,a3,800047e6 <writei+0x112>
{
    800046da:	7159                	addi	sp,sp,-112
    800046dc:	f486                	sd	ra,104(sp)
    800046de:	f0a2                	sd	s0,96(sp)
    800046e0:	eca6                	sd	s1,88(sp)
    800046e2:	e8ca                	sd	s2,80(sp)
    800046e4:	e4ce                	sd	s3,72(sp)
    800046e6:	e0d2                	sd	s4,64(sp)
    800046e8:	fc56                	sd	s5,56(sp)
    800046ea:	f85a                	sd	s6,48(sp)
    800046ec:	f45e                	sd	s7,40(sp)
    800046ee:	f062                	sd	s8,32(sp)
    800046f0:	ec66                	sd	s9,24(sp)
    800046f2:	e86a                	sd	s10,16(sp)
    800046f4:	e46e                	sd	s11,8(sp)
    800046f6:	1880                	addi	s0,sp,112
    800046f8:	8b2a                	mv	s6,a0
    800046fa:	8c2e                	mv	s8,a1
    800046fc:	8ab2                	mv	s5,a2
    800046fe:	8936                	mv	s2,a3
    80004700:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004702:	00e687bb          	addw	a5,a3,a4
    80004706:	0ed7e263          	bltu	a5,a3,800047ea <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000470a:	00043737          	lui	a4,0x43
    8000470e:	0ef76063          	bltu	a4,a5,800047ee <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004712:	0c0b8863          	beqz	s7,800047e2 <writei+0x10e>
    80004716:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004718:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000471c:	5cfd                	li	s9,-1
    8000471e:	a091                	j	80004762 <writei+0x8e>
    80004720:	02099d93          	slli	s11,s3,0x20
    80004724:	020ddd93          	srli	s11,s11,0x20
    80004728:	05848513          	addi	a0,s1,88
    8000472c:	86ee                	mv	a3,s11
    8000472e:	8656                	mv	a2,s5
    80004730:	85e2                	mv	a1,s8
    80004732:	953a                	add	a0,a0,a4
    80004734:	ffffe097          	auipc	ra,0xffffe
    80004738:	2a8080e7          	jalr	680(ra) # 800029dc <either_copyin>
    8000473c:	07950263          	beq	a0,s9,800047a0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004740:	8526                	mv	a0,s1
    80004742:	00000097          	auipc	ra,0x0
    80004746:	790080e7          	jalr	1936(ra) # 80004ed2 <log_write>
    brelse(bp);
    8000474a:	8526                	mv	a0,s1
    8000474c:	fffff097          	auipc	ra,0xfffff
    80004750:	50a080e7          	jalr	1290(ra) # 80003c56 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004754:	01498a3b          	addw	s4,s3,s4
    80004758:	0129893b          	addw	s2,s3,s2
    8000475c:	9aee                	add	s5,s5,s11
    8000475e:	057a7663          	bgeu	s4,s7,800047aa <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004762:	000b2483          	lw	s1,0(s6)
    80004766:	00a9559b          	srliw	a1,s2,0xa
    8000476a:	855a                	mv	a0,s6
    8000476c:	fffff097          	auipc	ra,0xfffff
    80004770:	7ae080e7          	jalr	1966(ra) # 80003f1a <bmap>
    80004774:	0005059b          	sext.w	a1,a0
    80004778:	8526                	mv	a0,s1
    8000477a:	fffff097          	auipc	ra,0xfffff
    8000477e:	3ac080e7          	jalr	940(ra) # 80003b26 <bread>
    80004782:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004784:	3ff97713          	andi	a4,s2,1023
    80004788:	40ed07bb          	subw	a5,s10,a4
    8000478c:	414b86bb          	subw	a3,s7,s4
    80004790:	89be                	mv	s3,a5
    80004792:	2781                	sext.w	a5,a5
    80004794:	0006861b          	sext.w	a2,a3
    80004798:	f8f674e3          	bgeu	a2,a5,80004720 <writei+0x4c>
    8000479c:	89b6                	mv	s3,a3
    8000479e:	b749                	j	80004720 <writei+0x4c>
      brelse(bp);
    800047a0:	8526                	mv	a0,s1
    800047a2:	fffff097          	auipc	ra,0xfffff
    800047a6:	4b4080e7          	jalr	1204(ra) # 80003c56 <brelse>
  }

  if(off > ip->size)
    800047aa:	04cb2783          	lw	a5,76(s6)
    800047ae:	0127f463          	bgeu	a5,s2,800047b6 <writei+0xe2>
    ip->size = off;
    800047b2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800047b6:	855a                	mv	a0,s6
    800047b8:	00000097          	auipc	ra,0x0
    800047bc:	aa6080e7          	jalr	-1370(ra) # 8000425e <iupdate>

  return tot;
    800047c0:	000a051b          	sext.w	a0,s4
}
    800047c4:	70a6                	ld	ra,104(sp)
    800047c6:	7406                	ld	s0,96(sp)
    800047c8:	64e6                	ld	s1,88(sp)
    800047ca:	6946                	ld	s2,80(sp)
    800047cc:	69a6                	ld	s3,72(sp)
    800047ce:	6a06                	ld	s4,64(sp)
    800047d0:	7ae2                	ld	s5,56(sp)
    800047d2:	7b42                	ld	s6,48(sp)
    800047d4:	7ba2                	ld	s7,40(sp)
    800047d6:	7c02                	ld	s8,32(sp)
    800047d8:	6ce2                	ld	s9,24(sp)
    800047da:	6d42                	ld	s10,16(sp)
    800047dc:	6da2                	ld	s11,8(sp)
    800047de:	6165                	addi	sp,sp,112
    800047e0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800047e2:	8a5e                	mv	s4,s7
    800047e4:	bfc9                	j	800047b6 <writei+0xe2>
    return -1;
    800047e6:	557d                	li	a0,-1
}
    800047e8:	8082                	ret
    return -1;
    800047ea:	557d                	li	a0,-1
    800047ec:	bfe1                	j	800047c4 <writei+0xf0>
    return -1;
    800047ee:	557d                	li	a0,-1
    800047f0:	bfd1                	j	800047c4 <writei+0xf0>

00000000800047f2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800047f2:	1141                	addi	sp,sp,-16
    800047f4:	e406                	sd	ra,8(sp)
    800047f6:	e022                	sd	s0,0(sp)
    800047f8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800047fa:	4639                	li	a2,14
    800047fc:	ffffc097          	auipc	ra,0xffffc
    80004800:	5bc080e7          	jalr	1468(ra) # 80000db8 <strncmp>
}
    80004804:	60a2                	ld	ra,8(sp)
    80004806:	6402                	ld	s0,0(sp)
    80004808:	0141                	addi	sp,sp,16
    8000480a:	8082                	ret

000000008000480c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000480c:	7139                	addi	sp,sp,-64
    8000480e:	fc06                	sd	ra,56(sp)
    80004810:	f822                	sd	s0,48(sp)
    80004812:	f426                	sd	s1,40(sp)
    80004814:	f04a                	sd	s2,32(sp)
    80004816:	ec4e                	sd	s3,24(sp)
    80004818:	e852                	sd	s4,16(sp)
    8000481a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000481c:	04451703          	lh	a4,68(a0)
    80004820:	4785                	li	a5,1
    80004822:	00f71a63          	bne	a4,a5,80004836 <dirlookup+0x2a>
    80004826:	892a                	mv	s2,a0
    80004828:	89ae                	mv	s3,a1
    8000482a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000482c:	457c                	lw	a5,76(a0)
    8000482e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004830:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004832:	e79d                	bnez	a5,80004860 <dirlookup+0x54>
    80004834:	a8a5                	j	800048ac <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004836:	00004517          	auipc	a0,0x4
    8000483a:	19250513          	addi	a0,a0,402 # 800089c8 <syscalls+0x1b8>
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	d00080e7          	jalr	-768(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004846:	00004517          	auipc	a0,0x4
    8000484a:	19a50513          	addi	a0,a0,410 # 800089e0 <syscalls+0x1d0>
    8000484e:	ffffc097          	auipc	ra,0xffffc
    80004852:	cf0080e7          	jalr	-784(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004856:	24c1                	addiw	s1,s1,16
    80004858:	04c92783          	lw	a5,76(s2)
    8000485c:	04f4f763          	bgeu	s1,a5,800048aa <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004860:	4741                	li	a4,16
    80004862:	86a6                	mv	a3,s1
    80004864:	fc040613          	addi	a2,s0,-64
    80004868:	4581                	li	a1,0
    8000486a:	854a                	mv	a0,s2
    8000486c:	00000097          	auipc	ra,0x0
    80004870:	d70080e7          	jalr	-656(ra) # 800045dc <readi>
    80004874:	47c1                	li	a5,16
    80004876:	fcf518e3          	bne	a0,a5,80004846 <dirlookup+0x3a>
    if(de.inum == 0)
    8000487a:	fc045783          	lhu	a5,-64(s0)
    8000487e:	dfe1                	beqz	a5,80004856 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004880:	fc240593          	addi	a1,s0,-62
    80004884:	854e                	mv	a0,s3
    80004886:	00000097          	auipc	ra,0x0
    8000488a:	f6c080e7          	jalr	-148(ra) # 800047f2 <namecmp>
    8000488e:	f561                	bnez	a0,80004856 <dirlookup+0x4a>
      if(poff)
    80004890:	000a0463          	beqz	s4,80004898 <dirlookup+0x8c>
        *poff = off;
    80004894:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004898:	fc045583          	lhu	a1,-64(s0)
    8000489c:	00092503          	lw	a0,0(s2)
    800048a0:	fffff097          	auipc	ra,0xfffff
    800048a4:	754080e7          	jalr	1876(ra) # 80003ff4 <iget>
    800048a8:	a011                	j	800048ac <dirlookup+0xa0>
  return 0;
    800048aa:	4501                	li	a0,0
}
    800048ac:	70e2                	ld	ra,56(sp)
    800048ae:	7442                	ld	s0,48(sp)
    800048b0:	74a2                	ld	s1,40(sp)
    800048b2:	7902                	ld	s2,32(sp)
    800048b4:	69e2                	ld	s3,24(sp)
    800048b6:	6a42                	ld	s4,16(sp)
    800048b8:	6121                	addi	sp,sp,64
    800048ba:	8082                	ret

00000000800048bc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800048bc:	711d                	addi	sp,sp,-96
    800048be:	ec86                	sd	ra,88(sp)
    800048c0:	e8a2                	sd	s0,80(sp)
    800048c2:	e4a6                	sd	s1,72(sp)
    800048c4:	e0ca                	sd	s2,64(sp)
    800048c6:	fc4e                	sd	s3,56(sp)
    800048c8:	f852                	sd	s4,48(sp)
    800048ca:	f456                	sd	s5,40(sp)
    800048cc:	f05a                	sd	s6,32(sp)
    800048ce:	ec5e                	sd	s7,24(sp)
    800048d0:	e862                	sd	s8,16(sp)
    800048d2:	e466                	sd	s9,8(sp)
    800048d4:	1080                	addi	s0,sp,96
    800048d6:	84aa                	mv	s1,a0
    800048d8:	8b2e                	mv	s6,a1
    800048da:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800048dc:	00054703          	lbu	a4,0(a0)
    800048e0:	02f00793          	li	a5,47
    800048e4:	02f70363          	beq	a4,a5,8000490a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800048e8:	ffffd097          	auipc	ra,0xffffd
    800048ec:	7e6080e7          	jalr	2022(ra) # 800020ce <myproc>
    800048f0:	15053503          	ld	a0,336(a0)
    800048f4:	00000097          	auipc	ra,0x0
    800048f8:	9f6080e7          	jalr	-1546(ra) # 800042ea <idup>
    800048fc:	89aa                	mv	s3,a0
  while(*path == '/')
    800048fe:	02f00913          	li	s2,47
  len = path - s;
    80004902:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004904:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004906:	4c05                	li	s8,1
    80004908:	a865                	j	800049c0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000490a:	4585                	li	a1,1
    8000490c:	4505                	li	a0,1
    8000490e:	fffff097          	auipc	ra,0xfffff
    80004912:	6e6080e7          	jalr	1766(ra) # 80003ff4 <iget>
    80004916:	89aa                	mv	s3,a0
    80004918:	b7dd                	j	800048fe <namex+0x42>
      iunlockput(ip);
    8000491a:	854e                	mv	a0,s3
    8000491c:	00000097          	auipc	ra,0x0
    80004920:	c6e080e7          	jalr	-914(ra) # 8000458a <iunlockput>
      return 0;
    80004924:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004926:	854e                	mv	a0,s3
    80004928:	60e6                	ld	ra,88(sp)
    8000492a:	6446                	ld	s0,80(sp)
    8000492c:	64a6                	ld	s1,72(sp)
    8000492e:	6906                	ld	s2,64(sp)
    80004930:	79e2                	ld	s3,56(sp)
    80004932:	7a42                	ld	s4,48(sp)
    80004934:	7aa2                	ld	s5,40(sp)
    80004936:	7b02                	ld	s6,32(sp)
    80004938:	6be2                	ld	s7,24(sp)
    8000493a:	6c42                	ld	s8,16(sp)
    8000493c:	6ca2                	ld	s9,8(sp)
    8000493e:	6125                	addi	sp,sp,96
    80004940:	8082                	ret
      iunlock(ip);
    80004942:	854e                	mv	a0,s3
    80004944:	00000097          	auipc	ra,0x0
    80004948:	aa6080e7          	jalr	-1370(ra) # 800043ea <iunlock>
      return ip;
    8000494c:	bfe9                	j	80004926 <namex+0x6a>
      iunlockput(ip);
    8000494e:	854e                	mv	a0,s3
    80004950:	00000097          	auipc	ra,0x0
    80004954:	c3a080e7          	jalr	-966(ra) # 8000458a <iunlockput>
      return 0;
    80004958:	89d2                	mv	s3,s4
    8000495a:	b7f1                	j	80004926 <namex+0x6a>
  len = path - s;
    8000495c:	40b48633          	sub	a2,s1,a1
    80004960:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004964:	094cd463          	bge	s9,s4,800049ec <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004968:	4639                	li	a2,14
    8000496a:	8556                	mv	a0,s5
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	3d4080e7          	jalr	980(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004974:	0004c783          	lbu	a5,0(s1)
    80004978:	01279763          	bne	a5,s2,80004986 <namex+0xca>
    path++;
    8000497c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000497e:	0004c783          	lbu	a5,0(s1)
    80004982:	ff278de3          	beq	a5,s2,8000497c <namex+0xc0>
    ilock(ip);
    80004986:	854e                	mv	a0,s3
    80004988:	00000097          	auipc	ra,0x0
    8000498c:	9a0080e7          	jalr	-1632(ra) # 80004328 <ilock>
    if(ip->type != T_DIR){
    80004990:	04499783          	lh	a5,68(s3)
    80004994:	f98793e3          	bne	a5,s8,8000491a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004998:	000b0563          	beqz	s6,800049a2 <namex+0xe6>
    8000499c:	0004c783          	lbu	a5,0(s1)
    800049a0:	d3cd                	beqz	a5,80004942 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800049a2:	865e                	mv	a2,s7
    800049a4:	85d6                	mv	a1,s5
    800049a6:	854e                	mv	a0,s3
    800049a8:	00000097          	auipc	ra,0x0
    800049ac:	e64080e7          	jalr	-412(ra) # 8000480c <dirlookup>
    800049b0:	8a2a                	mv	s4,a0
    800049b2:	dd51                	beqz	a0,8000494e <namex+0x92>
    iunlockput(ip);
    800049b4:	854e                	mv	a0,s3
    800049b6:	00000097          	auipc	ra,0x0
    800049ba:	bd4080e7          	jalr	-1068(ra) # 8000458a <iunlockput>
    ip = next;
    800049be:	89d2                	mv	s3,s4
  while(*path == '/')
    800049c0:	0004c783          	lbu	a5,0(s1)
    800049c4:	05279763          	bne	a5,s2,80004a12 <namex+0x156>
    path++;
    800049c8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800049ca:	0004c783          	lbu	a5,0(s1)
    800049ce:	ff278de3          	beq	a5,s2,800049c8 <namex+0x10c>
  if(*path == 0)
    800049d2:	c79d                	beqz	a5,80004a00 <namex+0x144>
    path++;
    800049d4:	85a6                	mv	a1,s1
  len = path - s;
    800049d6:	8a5e                	mv	s4,s7
    800049d8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800049da:	01278963          	beq	a5,s2,800049ec <namex+0x130>
    800049de:	dfbd                	beqz	a5,8000495c <namex+0xa0>
    path++;
    800049e0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800049e2:	0004c783          	lbu	a5,0(s1)
    800049e6:	ff279ce3          	bne	a5,s2,800049de <namex+0x122>
    800049ea:	bf8d                	j	8000495c <namex+0xa0>
    memmove(name, s, len);
    800049ec:	2601                	sext.w	a2,a2
    800049ee:	8556                	mv	a0,s5
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	350080e7          	jalr	848(ra) # 80000d40 <memmove>
    name[len] = 0;
    800049f8:	9a56                	add	s4,s4,s5
    800049fa:	000a0023          	sb	zero,0(s4)
    800049fe:	bf9d                	j	80004974 <namex+0xb8>
  if(nameiparent){
    80004a00:	f20b03e3          	beqz	s6,80004926 <namex+0x6a>
    iput(ip);
    80004a04:	854e                	mv	a0,s3
    80004a06:	00000097          	auipc	ra,0x0
    80004a0a:	adc080e7          	jalr	-1316(ra) # 800044e2 <iput>
    return 0;
    80004a0e:	4981                	li	s3,0
    80004a10:	bf19                	j	80004926 <namex+0x6a>
  if(*path == 0)
    80004a12:	d7fd                	beqz	a5,80004a00 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004a14:	0004c783          	lbu	a5,0(s1)
    80004a18:	85a6                	mv	a1,s1
    80004a1a:	b7d1                	j	800049de <namex+0x122>

0000000080004a1c <dirlink>:
{
    80004a1c:	7139                	addi	sp,sp,-64
    80004a1e:	fc06                	sd	ra,56(sp)
    80004a20:	f822                	sd	s0,48(sp)
    80004a22:	f426                	sd	s1,40(sp)
    80004a24:	f04a                	sd	s2,32(sp)
    80004a26:	ec4e                	sd	s3,24(sp)
    80004a28:	e852                	sd	s4,16(sp)
    80004a2a:	0080                	addi	s0,sp,64
    80004a2c:	892a                	mv	s2,a0
    80004a2e:	8a2e                	mv	s4,a1
    80004a30:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004a32:	4601                	li	a2,0
    80004a34:	00000097          	auipc	ra,0x0
    80004a38:	dd8080e7          	jalr	-552(ra) # 8000480c <dirlookup>
    80004a3c:	e93d                	bnez	a0,80004ab2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a3e:	04c92483          	lw	s1,76(s2)
    80004a42:	c49d                	beqz	s1,80004a70 <dirlink+0x54>
    80004a44:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a46:	4741                	li	a4,16
    80004a48:	86a6                	mv	a3,s1
    80004a4a:	fc040613          	addi	a2,s0,-64
    80004a4e:	4581                	li	a1,0
    80004a50:	854a                	mv	a0,s2
    80004a52:	00000097          	auipc	ra,0x0
    80004a56:	b8a080e7          	jalr	-1142(ra) # 800045dc <readi>
    80004a5a:	47c1                	li	a5,16
    80004a5c:	06f51163          	bne	a0,a5,80004abe <dirlink+0xa2>
    if(de.inum == 0)
    80004a60:	fc045783          	lhu	a5,-64(s0)
    80004a64:	c791                	beqz	a5,80004a70 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a66:	24c1                	addiw	s1,s1,16
    80004a68:	04c92783          	lw	a5,76(s2)
    80004a6c:	fcf4ede3          	bltu	s1,a5,80004a46 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004a70:	4639                	li	a2,14
    80004a72:	85d2                	mv	a1,s4
    80004a74:	fc240513          	addi	a0,s0,-62
    80004a78:	ffffc097          	auipc	ra,0xffffc
    80004a7c:	37c080e7          	jalr	892(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004a80:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a84:	4741                	li	a4,16
    80004a86:	86a6                	mv	a3,s1
    80004a88:	fc040613          	addi	a2,s0,-64
    80004a8c:	4581                	li	a1,0
    80004a8e:	854a                	mv	a0,s2
    80004a90:	00000097          	auipc	ra,0x0
    80004a94:	c44080e7          	jalr	-956(ra) # 800046d4 <writei>
    80004a98:	872a                	mv	a4,a0
    80004a9a:	47c1                	li	a5,16
  return 0;
    80004a9c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a9e:	02f71863          	bne	a4,a5,80004ace <dirlink+0xb2>
}
    80004aa2:	70e2                	ld	ra,56(sp)
    80004aa4:	7442                	ld	s0,48(sp)
    80004aa6:	74a2                	ld	s1,40(sp)
    80004aa8:	7902                	ld	s2,32(sp)
    80004aaa:	69e2                	ld	s3,24(sp)
    80004aac:	6a42                	ld	s4,16(sp)
    80004aae:	6121                	addi	sp,sp,64
    80004ab0:	8082                	ret
    iput(ip);
    80004ab2:	00000097          	auipc	ra,0x0
    80004ab6:	a30080e7          	jalr	-1488(ra) # 800044e2 <iput>
    return -1;
    80004aba:	557d                	li	a0,-1
    80004abc:	b7dd                	j	80004aa2 <dirlink+0x86>
      panic("dirlink read");
    80004abe:	00004517          	auipc	a0,0x4
    80004ac2:	f3250513          	addi	a0,a0,-206 # 800089f0 <syscalls+0x1e0>
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	a78080e7          	jalr	-1416(ra) # 8000053e <panic>
    panic("dirlink");
    80004ace:	00004517          	auipc	a0,0x4
    80004ad2:	03250513          	addi	a0,a0,50 # 80008b00 <syscalls+0x2f0>
    80004ad6:	ffffc097          	auipc	ra,0xffffc
    80004ada:	a68080e7          	jalr	-1432(ra) # 8000053e <panic>

0000000080004ade <namei>:

struct inode*
namei(char *path)
{
    80004ade:	1101                	addi	sp,sp,-32
    80004ae0:	ec06                	sd	ra,24(sp)
    80004ae2:	e822                	sd	s0,16(sp)
    80004ae4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004ae6:	fe040613          	addi	a2,s0,-32
    80004aea:	4581                	li	a1,0
    80004aec:	00000097          	auipc	ra,0x0
    80004af0:	dd0080e7          	jalr	-560(ra) # 800048bc <namex>
}
    80004af4:	60e2                	ld	ra,24(sp)
    80004af6:	6442                	ld	s0,16(sp)
    80004af8:	6105                	addi	sp,sp,32
    80004afa:	8082                	ret

0000000080004afc <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004afc:	1141                	addi	sp,sp,-16
    80004afe:	e406                	sd	ra,8(sp)
    80004b00:	e022                	sd	s0,0(sp)
    80004b02:	0800                	addi	s0,sp,16
    80004b04:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004b06:	4585                	li	a1,1
    80004b08:	00000097          	auipc	ra,0x0
    80004b0c:	db4080e7          	jalr	-588(ra) # 800048bc <namex>
}
    80004b10:	60a2                	ld	ra,8(sp)
    80004b12:	6402                	ld	s0,0(sp)
    80004b14:	0141                	addi	sp,sp,16
    80004b16:	8082                	ret

0000000080004b18 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004b18:	1101                	addi	sp,sp,-32
    80004b1a:	ec06                	sd	ra,24(sp)
    80004b1c:	e822                	sd	s0,16(sp)
    80004b1e:	e426                	sd	s1,8(sp)
    80004b20:	e04a                	sd	s2,0(sp)
    80004b22:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004b24:	0001d917          	auipc	s2,0x1d
    80004b28:	2cc90913          	addi	s2,s2,716 # 80021df0 <log>
    80004b2c:	01892583          	lw	a1,24(s2)
    80004b30:	02892503          	lw	a0,40(s2)
    80004b34:	fffff097          	auipc	ra,0xfffff
    80004b38:	ff2080e7          	jalr	-14(ra) # 80003b26 <bread>
    80004b3c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004b3e:	02c92683          	lw	a3,44(s2)
    80004b42:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004b44:	02d05763          	blez	a3,80004b72 <write_head+0x5a>
    80004b48:	0001d797          	auipc	a5,0x1d
    80004b4c:	2d878793          	addi	a5,a5,728 # 80021e20 <log+0x30>
    80004b50:	05c50713          	addi	a4,a0,92
    80004b54:	36fd                	addiw	a3,a3,-1
    80004b56:	1682                	slli	a3,a3,0x20
    80004b58:	9281                	srli	a3,a3,0x20
    80004b5a:	068a                	slli	a3,a3,0x2
    80004b5c:	0001d617          	auipc	a2,0x1d
    80004b60:	2c860613          	addi	a2,a2,712 # 80021e24 <log+0x34>
    80004b64:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004b66:	4390                	lw	a2,0(a5)
    80004b68:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004b6a:	0791                	addi	a5,a5,4
    80004b6c:	0711                	addi	a4,a4,4
    80004b6e:	fed79ce3          	bne	a5,a3,80004b66 <write_head+0x4e>
  }
  bwrite(buf);
    80004b72:	8526                	mv	a0,s1
    80004b74:	fffff097          	auipc	ra,0xfffff
    80004b78:	0a4080e7          	jalr	164(ra) # 80003c18 <bwrite>
  brelse(buf);
    80004b7c:	8526                	mv	a0,s1
    80004b7e:	fffff097          	auipc	ra,0xfffff
    80004b82:	0d8080e7          	jalr	216(ra) # 80003c56 <brelse>
}
    80004b86:	60e2                	ld	ra,24(sp)
    80004b88:	6442                	ld	s0,16(sp)
    80004b8a:	64a2                	ld	s1,8(sp)
    80004b8c:	6902                	ld	s2,0(sp)
    80004b8e:	6105                	addi	sp,sp,32
    80004b90:	8082                	ret

0000000080004b92 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b92:	0001d797          	auipc	a5,0x1d
    80004b96:	28a7a783          	lw	a5,650(a5) # 80021e1c <log+0x2c>
    80004b9a:	0af05d63          	blez	a5,80004c54 <install_trans+0xc2>
{
    80004b9e:	7139                	addi	sp,sp,-64
    80004ba0:	fc06                	sd	ra,56(sp)
    80004ba2:	f822                	sd	s0,48(sp)
    80004ba4:	f426                	sd	s1,40(sp)
    80004ba6:	f04a                	sd	s2,32(sp)
    80004ba8:	ec4e                	sd	s3,24(sp)
    80004baa:	e852                	sd	s4,16(sp)
    80004bac:	e456                	sd	s5,8(sp)
    80004bae:	e05a                	sd	s6,0(sp)
    80004bb0:	0080                	addi	s0,sp,64
    80004bb2:	8b2a                	mv	s6,a0
    80004bb4:	0001da97          	auipc	s5,0x1d
    80004bb8:	26ca8a93          	addi	s5,s5,620 # 80021e20 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bbc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004bbe:	0001d997          	auipc	s3,0x1d
    80004bc2:	23298993          	addi	s3,s3,562 # 80021df0 <log>
    80004bc6:	a035                	j	80004bf2 <install_trans+0x60>
      bunpin(dbuf);
    80004bc8:	8526                	mv	a0,s1
    80004bca:	fffff097          	auipc	ra,0xfffff
    80004bce:	166080e7          	jalr	358(ra) # 80003d30 <bunpin>
    brelse(lbuf);
    80004bd2:	854a                	mv	a0,s2
    80004bd4:	fffff097          	auipc	ra,0xfffff
    80004bd8:	082080e7          	jalr	130(ra) # 80003c56 <brelse>
    brelse(dbuf);
    80004bdc:	8526                	mv	a0,s1
    80004bde:	fffff097          	auipc	ra,0xfffff
    80004be2:	078080e7          	jalr	120(ra) # 80003c56 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004be6:	2a05                	addiw	s4,s4,1
    80004be8:	0a91                	addi	s5,s5,4
    80004bea:	02c9a783          	lw	a5,44(s3)
    80004bee:	04fa5963          	bge	s4,a5,80004c40 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004bf2:	0189a583          	lw	a1,24(s3)
    80004bf6:	014585bb          	addw	a1,a1,s4
    80004bfa:	2585                	addiw	a1,a1,1
    80004bfc:	0289a503          	lw	a0,40(s3)
    80004c00:	fffff097          	auipc	ra,0xfffff
    80004c04:	f26080e7          	jalr	-218(ra) # 80003b26 <bread>
    80004c08:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004c0a:	000aa583          	lw	a1,0(s5)
    80004c0e:	0289a503          	lw	a0,40(s3)
    80004c12:	fffff097          	auipc	ra,0xfffff
    80004c16:	f14080e7          	jalr	-236(ra) # 80003b26 <bread>
    80004c1a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004c1c:	40000613          	li	a2,1024
    80004c20:	05890593          	addi	a1,s2,88
    80004c24:	05850513          	addi	a0,a0,88
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	118080e7          	jalr	280(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004c30:	8526                	mv	a0,s1
    80004c32:	fffff097          	auipc	ra,0xfffff
    80004c36:	fe6080e7          	jalr	-26(ra) # 80003c18 <bwrite>
    if(recovering == 0)
    80004c3a:	f80b1ce3          	bnez	s6,80004bd2 <install_trans+0x40>
    80004c3e:	b769                	j	80004bc8 <install_trans+0x36>
}
    80004c40:	70e2                	ld	ra,56(sp)
    80004c42:	7442                	ld	s0,48(sp)
    80004c44:	74a2                	ld	s1,40(sp)
    80004c46:	7902                	ld	s2,32(sp)
    80004c48:	69e2                	ld	s3,24(sp)
    80004c4a:	6a42                	ld	s4,16(sp)
    80004c4c:	6aa2                	ld	s5,8(sp)
    80004c4e:	6b02                	ld	s6,0(sp)
    80004c50:	6121                	addi	sp,sp,64
    80004c52:	8082                	ret
    80004c54:	8082                	ret

0000000080004c56 <initlog>:
{
    80004c56:	7179                	addi	sp,sp,-48
    80004c58:	f406                	sd	ra,40(sp)
    80004c5a:	f022                	sd	s0,32(sp)
    80004c5c:	ec26                	sd	s1,24(sp)
    80004c5e:	e84a                	sd	s2,16(sp)
    80004c60:	e44e                	sd	s3,8(sp)
    80004c62:	1800                	addi	s0,sp,48
    80004c64:	892a                	mv	s2,a0
    80004c66:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004c68:	0001d497          	auipc	s1,0x1d
    80004c6c:	18848493          	addi	s1,s1,392 # 80021df0 <log>
    80004c70:	00004597          	auipc	a1,0x4
    80004c74:	d9058593          	addi	a1,a1,-624 # 80008a00 <syscalls+0x1f0>
    80004c78:	8526                	mv	a0,s1
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	eda080e7          	jalr	-294(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004c82:	0149a583          	lw	a1,20(s3)
    80004c86:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004c88:	0109a783          	lw	a5,16(s3)
    80004c8c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004c8e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004c92:	854a                	mv	a0,s2
    80004c94:	fffff097          	auipc	ra,0xfffff
    80004c98:	e92080e7          	jalr	-366(ra) # 80003b26 <bread>
  log.lh.n = lh->n;
    80004c9c:	4d3c                	lw	a5,88(a0)
    80004c9e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004ca0:	02f05563          	blez	a5,80004cca <initlog+0x74>
    80004ca4:	05c50713          	addi	a4,a0,92
    80004ca8:	0001d697          	auipc	a3,0x1d
    80004cac:	17868693          	addi	a3,a3,376 # 80021e20 <log+0x30>
    80004cb0:	37fd                	addiw	a5,a5,-1
    80004cb2:	1782                	slli	a5,a5,0x20
    80004cb4:	9381                	srli	a5,a5,0x20
    80004cb6:	078a                	slli	a5,a5,0x2
    80004cb8:	06050613          	addi	a2,a0,96
    80004cbc:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004cbe:	4310                	lw	a2,0(a4)
    80004cc0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004cc2:	0711                	addi	a4,a4,4
    80004cc4:	0691                	addi	a3,a3,4
    80004cc6:	fef71ce3          	bne	a4,a5,80004cbe <initlog+0x68>
  brelse(buf);
    80004cca:	fffff097          	auipc	ra,0xfffff
    80004cce:	f8c080e7          	jalr	-116(ra) # 80003c56 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004cd2:	4505                	li	a0,1
    80004cd4:	00000097          	auipc	ra,0x0
    80004cd8:	ebe080e7          	jalr	-322(ra) # 80004b92 <install_trans>
  log.lh.n = 0;
    80004cdc:	0001d797          	auipc	a5,0x1d
    80004ce0:	1407a023          	sw	zero,320(a5) # 80021e1c <log+0x2c>
  write_head(); // clear the log
    80004ce4:	00000097          	auipc	ra,0x0
    80004ce8:	e34080e7          	jalr	-460(ra) # 80004b18 <write_head>
}
    80004cec:	70a2                	ld	ra,40(sp)
    80004cee:	7402                	ld	s0,32(sp)
    80004cf0:	64e2                	ld	s1,24(sp)
    80004cf2:	6942                	ld	s2,16(sp)
    80004cf4:	69a2                	ld	s3,8(sp)
    80004cf6:	6145                	addi	sp,sp,48
    80004cf8:	8082                	ret

0000000080004cfa <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004cfa:	1101                	addi	sp,sp,-32
    80004cfc:	ec06                	sd	ra,24(sp)
    80004cfe:	e822                	sd	s0,16(sp)
    80004d00:	e426                	sd	s1,8(sp)
    80004d02:	e04a                	sd	s2,0(sp)
    80004d04:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004d06:	0001d517          	auipc	a0,0x1d
    80004d0a:	0ea50513          	addi	a0,a0,234 # 80021df0 <log>
    80004d0e:	ffffc097          	auipc	ra,0xffffc
    80004d12:	ed6080e7          	jalr	-298(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004d16:	0001d497          	auipc	s1,0x1d
    80004d1a:	0da48493          	addi	s1,s1,218 # 80021df0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d1e:	4979                	li	s2,30
    80004d20:	a039                	j	80004d2e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004d22:	85a6                	mv	a1,s1
    80004d24:	8526                	mv	a0,s1
    80004d26:	ffffe097          	auipc	ra,0xffffe
    80004d2a:	9e2080e7          	jalr	-1566(ra) # 80002708 <sleep>
    if(log.committing){
    80004d2e:	50dc                	lw	a5,36(s1)
    80004d30:	fbed                	bnez	a5,80004d22 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d32:	509c                	lw	a5,32(s1)
    80004d34:	0017871b          	addiw	a4,a5,1
    80004d38:	0007069b          	sext.w	a3,a4
    80004d3c:	0027179b          	slliw	a5,a4,0x2
    80004d40:	9fb9                	addw	a5,a5,a4
    80004d42:	0017979b          	slliw	a5,a5,0x1
    80004d46:	54d8                	lw	a4,44(s1)
    80004d48:	9fb9                	addw	a5,a5,a4
    80004d4a:	00f95963          	bge	s2,a5,80004d5c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004d4e:	85a6                	mv	a1,s1
    80004d50:	8526                	mv	a0,s1
    80004d52:	ffffe097          	auipc	ra,0xffffe
    80004d56:	9b6080e7          	jalr	-1610(ra) # 80002708 <sleep>
    80004d5a:	bfd1                	j	80004d2e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004d5c:	0001d517          	auipc	a0,0x1d
    80004d60:	09450513          	addi	a0,a0,148 # 80021df0 <log>
    80004d64:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004d66:	ffffc097          	auipc	ra,0xffffc
    80004d6a:	f32080e7          	jalr	-206(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004d6e:	60e2                	ld	ra,24(sp)
    80004d70:	6442                	ld	s0,16(sp)
    80004d72:	64a2                	ld	s1,8(sp)
    80004d74:	6902                	ld	s2,0(sp)
    80004d76:	6105                	addi	sp,sp,32
    80004d78:	8082                	ret

0000000080004d7a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004d7a:	7139                	addi	sp,sp,-64
    80004d7c:	fc06                	sd	ra,56(sp)
    80004d7e:	f822                	sd	s0,48(sp)
    80004d80:	f426                	sd	s1,40(sp)
    80004d82:	f04a                	sd	s2,32(sp)
    80004d84:	ec4e                	sd	s3,24(sp)
    80004d86:	e852                	sd	s4,16(sp)
    80004d88:	e456                	sd	s5,8(sp)
    80004d8a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004d8c:	0001d497          	auipc	s1,0x1d
    80004d90:	06448493          	addi	s1,s1,100 # 80021df0 <log>
    80004d94:	8526                	mv	a0,s1
    80004d96:	ffffc097          	auipc	ra,0xffffc
    80004d9a:	e4e080e7          	jalr	-434(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004d9e:	509c                	lw	a5,32(s1)
    80004da0:	37fd                	addiw	a5,a5,-1
    80004da2:	0007891b          	sext.w	s2,a5
    80004da6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004da8:	50dc                	lw	a5,36(s1)
    80004daa:	efb9                	bnez	a5,80004e08 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004dac:	06091663          	bnez	s2,80004e18 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004db0:	0001d497          	auipc	s1,0x1d
    80004db4:	04048493          	addi	s1,s1,64 # 80021df0 <log>
    80004db8:	4785                	li	a5,1
    80004dba:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004dbc:	8526                	mv	a0,s1
    80004dbe:	ffffc097          	auipc	ra,0xffffc
    80004dc2:	eda080e7          	jalr	-294(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004dc6:	54dc                	lw	a5,44(s1)
    80004dc8:	06f04763          	bgtz	a5,80004e36 <end_op+0xbc>
    acquire(&log.lock);
    80004dcc:	0001d497          	auipc	s1,0x1d
    80004dd0:	02448493          	addi	s1,s1,36 # 80021df0 <log>
    80004dd4:	8526                	mv	a0,s1
    80004dd6:	ffffc097          	auipc	ra,0xffffc
    80004dda:	e0e080e7          	jalr	-498(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004dde:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004de2:	8526                	mv	a0,s1
    80004de4:	ffffe097          	auipc	ra,0xffffe
    80004de8:	faa080e7          	jalr	-86(ra) # 80002d8e <wakeup>
    release(&log.lock);
    80004dec:	8526                	mv	a0,s1
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	eaa080e7          	jalr	-342(ra) # 80000c98 <release>
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
    panic("log.committing");
    80004e08:	00004517          	auipc	a0,0x4
    80004e0c:	c0050513          	addi	a0,a0,-1024 # 80008a08 <syscalls+0x1f8>
    80004e10:	ffffb097          	auipc	ra,0xffffb
    80004e14:	72e080e7          	jalr	1838(ra) # 8000053e <panic>
    wakeup(&log);
    80004e18:	0001d497          	auipc	s1,0x1d
    80004e1c:	fd848493          	addi	s1,s1,-40 # 80021df0 <log>
    80004e20:	8526                	mv	a0,s1
    80004e22:	ffffe097          	auipc	ra,0xffffe
    80004e26:	f6c080e7          	jalr	-148(ra) # 80002d8e <wakeup>
  release(&log.lock);
    80004e2a:	8526                	mv	a0,s1
    80004e2c:	ffffc097          	auipc	ra,0xffffc
    80004e30:	e6c080e7          	jalr	-404(ra) # 80000c98 <release>
  if(do_commit){
    80004e34:	b7c9                	j	80004df6 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e36:	0001da97          	auipc	s5,0x1d
    80004e3a:	feaa8a93          	addi	s5,s5,-22 # 80021e20 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004e3e:	0001da17          	auipc	s4,0x1d
    80004e42:	fb2a0a13          	addi	s4,s4,-78 # 80021df0 <log>
    80004e46:	018a2583          	lw	a1,24(s4)
    80004e4a:	012585bb          	addw	a1,a1,s2
    80004e4e:	2585                	addiw	a1,a1,1
    80004e50:	028a2503          	lw	a0,40(s4)
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	cd2080e7          	jalr	-814(ra) # 80003b26 <bread>
    80004e5c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004e5e:	000aa583          	lw	a1,0(s5)
    80004e62:	028a2503          	lw	a0,40(s4)
    80004e66:	fffff097          	auipc	ra,0xfffff
    80004e6a:	cc0080e7          	jalr	-832(ra) # 80003b26 <bread>
    80004e6e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004e70:	40000613          	li	a2,1024
    80004e74:	05850593          	addi	a1,a0,88
    80004e78:	05848513          	addi	a0,s1,88
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	ec4080e7          	jalr	-316(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004e84:	8526                	mv	a0,s1
    80004e86:	fffff097          	auipc	ra,0xfffff
    80004e8a:	d92080e7          	jalr	-622(ra) # 80003c18 <bwrite>
    brelse(from);
    80004e8e:	854e                	mv	a0,s3
    80004e90:	fffff097          	auipc	ra,0xfffff
    80004e94:	dc6080e7          	jalr	-570(ra) # 80003c56 <brelse>
    brelse(to);
    80004e98:	8526                	mv	a0,s1
    80004e9a:	fffff097          	auipc	ra,0xfffff
    80004e9e:	dbc080e7          	jalr	-580(ra) # 80003c56 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ea2:	2905                	addiw	s2,s2,1
    80004ea4:	0a91                	addi	s5,s5,4
    80004ea6:	02ca2783          	lw	a5,44(s4)
    80004eaa:	f8f94ee3          	blt	s2,a5,80004e46 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004eae:	00000097          	auipc	ra,0x0
    80004eb2:	c6a080e7          	jalr	-918(ra) # 80004b18 <write_head>
    install_trans(0); // Now install writes to home locations
    80004eb6:	4501                	li	a0,0
    80004eb8:	00000097          	auipc	ra,0x0
    80004ebc:	cda080e7          	jalr	-806(ra) # 80004b92 <install_trans>
    log.lh.n = 0;
    80004ec0:	0001d797          	auipc	a5,0x1d
    80004ec4:	f407ae23          	sw	zero,-164(a5) # 80021e1c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004ec8:	00000097          	auipc	ra,0x0
    80004ecc:	c50080e7          	jalr	-944(ra) # 80004b18 <write_head>
    80004ed0:	bdf5                	j	80004dcc <end_op+0x52>

0000000080004ed2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004ed2:	1101                	addi	sp,sp,-32
    80004ed4:	ec06                	sd	ra,24(sp)
    80004ed6:	e822                	sd	s0,16(sp)
    80004ed8:	e426                	sd	s1,8(sp)
    80004eda:	e04a                	sd	s2,0(sp)
    80004edc:	1000                	addi	s0,sp,32
    80004ede:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004ee0:	0001d917          	auipc	s2,0x1d
    80004ee4:	f1090913          	addi	s2,s2,-240 # 80021df0 <log>
    80004ee8:	854a                	mv	a0,s2
    80004eea:	ffffc097          	auipc	ra,0xffffc
    80004eee:	cfa080e7          	jalr	-774(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004ef2:	02c92603          	lw	a2,44(s2)
    80004ef6:	47f5                	li	a5,29
    80004ef8:	06c7c563          	blt	a5,a2,80004f62 <log_write+0x90>
    80004efc:	0001d797          	auipc	a5,0x1d
    80004f00:	f107a783          	lw	a5,-240(a5) # 80021e0c <log+0x1c>
    80004f04:	37fd                	addiw	a5,a5,-1
    80004f06:	04f65e63          	bge	a2,a5,80004f62 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004f0a:	0001d797          	auipc	a5,0x1d
    80004f0e:	f067a783          	lw	a5,-250(a5) # 80021e10 <log+0x20>
    80004f12:	06f05063          	blez	a5,80004f72 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004f16:	4781                	li	a5,0
    80004f18:	06c05563          	blez	a2,80004f82 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004f1c:	44cc                	lw	a1,12(s1)
    80004f1e:	0001d717          	auipc	a4,0x1d
    80004f22:	f0270713          	addi	a4,a4,-254 # 80021e20 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004f26:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004f28:	4314                	lw	a3,0(a4)
    80004f2a:	04b68c63          	beq	a3,a1,80004f82 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004f2e:	2785                	addiw	a5,a5,1
    80004f30:	0711                	addi	a4,a4,4
    80004f32:	fef61be3          	bne	a2,a5,80004f28 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004f36:	0621                	addi	a2,a2,8
    80004f38:	060a                	slli	a2,a2,0x2
    80004f3a:	0001d797          	auipc	a5,0x1d
    80004f3e:	eb678793          	addi	a5,a5,-330 # 80021df0 <log>
    80004f42:	963e                	add	a2,a2,a5
    80004f44:	44dc                	lw	a5,12(s1)
    80004f46:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004f48:	8526                	mv	a0,s1
    80004f4a:	fffff097          	auipc	ra,0xfffff
    80004f4e:	daa080e7          	jalr	-598(ra) # 80003cf4 <bpin>
    log.lh.n++;
    80004f52:	0001d717          	auipc	a4,0x1d
    80004f56:	e9e70713          	addi	a4,a4,-354 # 80021df0 <log>
    80004f5a:	575c                	lw	a5,44(a4)
    80004f5c:	2785                	addiw	a5,a5,1
    80004f5e:	d75c                	sw	a5,44(a4)
    80004f60:	a835                	j	80004f9c <log_write+0xca>
    panic("too big a transaction");
    80004f62:	00004517          	auipc	a0,0x4
    80004f66:	ab650513          	addi	a0,a0,-1354 # 80008a18 <syscalls+0x208>
    80004f6a:	ffffb097          	auipc	ra,0xffffb
    80004f6e:	5d4080e7          	jalr	1492(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004f72:	00004517          	auipc	a0,0x4
    80004f76:	abe50513          	addi	a0,a0,-1346 # 80008a30 <syscalls+0x220>
    80004f7a:	ffffb097          	auipc	ra,0xffffb
    80004f7e:	5c4080e7          	jalr	1476(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004f82:	00878713          	addi	a4,a5,8
    80004f86:	00271693          	slli	a3,a4,0x2
    80004f8a:	0001d717          	auipc	a4,0x1d
    80004f8e:	e6670713          	addi	a4,a4,-410 # 80021df0 <log>
    80004f92:	9736                	add	a4,a4,a3
    80004f94:	44d4                	lw	a3,12(s1)
    80004f96:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004f98:	faf608e3          	beq	a2,a5,80004f48 <log_write+0x76>
  }
  release(&log.lock);
    80004f9c:	0001d517          	auipc	a0,0x1d
    80004fa0:	e5450513          	addi	a0,a0,-428 # 80021df0 <log>
    80004fa4:	ffffc097          	auipc	ra,0xffffc
    80004fa8:	cf4080e7          	jalr	-780(ra) # 80000c98 <release>
}
    80004fac:	60e2                	ld	ra,24(sp)
    80004fae:	6442                	ld	s0,16(sp)
    80004fb0:	64a2                	ld	s1,8(sp)
    80004fb2:	6902                	ld	s2,0(sp)
    80004fb4:	6105                	addi	sp,sp,32
    80004fb6:	8082                	ret

0000000080004fb8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004fb8:	1101                	addi	sp,sp,-32
    80004fba:	ec06                	sd	ra,24(sp)
    80004fbc:	e822                	sd	s0,16(sp)
    80004fbe:	e426                	sd	s1,8(sp)
    80004fc0:	e04a                	sd	s2,0(sp)
    80004fc2:	1000                	addi	s0,sp,32
    80004fc4:	84aa                	mv	s1,a0
    80004fc6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004fc8:	00004597          	auipc	a1,0x4
    80004fcc:	a8858593          	addi	a1,a1,-1400 # 80008a50 <syscalls+0x240>
    80004fd0:	0521                	addi	a0,a0,8
    80004fd2:	ffffc097          	auipc	ra,0xffffc
    80004fd6:	b82080e7          	jalr	-1150(ra) # 80000b54 <initlock>
  lk->name = name;
    80004fda:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004fde:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004fe2:	0204a423          	sw	zero,40(s1)
}
    80004fe6:	60e2                	ld	ra,24(sp)
    80004fe8:	6442                	ld	s0,16(sp)
    80004fea:	64a2                	ld	s1,8(sp)
    80004fec:	6902                	ld	s2,0(sp)
    80004fee:	6105                	addi	sp,sp,32
    80004ff0:	8082                	ret

0000000080004ff2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004ff2:	1101                	addi	sp,sp,-32
    80004ff4:	ec06                	sd	ra,24(sp)
    80004ff6:	e822                	sd	s0,16(sp)
    80004ff8:	e426                	sd	s1,8(sp)
    80004ffa:	e04a                	sd	s2,0(sp)
    80004ffc:	1000                	addi	s0,sp,32
    80004ffe:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005000:	00850913          	addi	s2,a0,8
    80005004:	854a                	mv	a0,s2
    80005006:	ffffc097          	auipc	ra,0xffffc
    8000500a:	bde080e7          	jalr	-1058(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000500e:	409c                	lw	a5,0(s1)
    80005010:	cb89                	beqz	a5,80005022 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80005012:	85ca                	mv	a1,s2
    80005014:	8526                	mv	a0,s1
    80005016:	ffffd097          	auipc	ra,0xffffd
    8000501a:	6f2080e7          	jalr	1778(ra) # 80002708 <sleep>
  while (lk->locked) {
    8000501e:	409c                	lw	a5,0(s1)
    80005020:	fbed                	bnez	a5,80005012 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80005022:	4785                	li	a5,1
    80005024:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80005026:	ffffd097          	auipc	ra,0xffffd
    8000502a:	0a8080e7          	jalr	168(ra) # 800020ce <myproc>
    8000502e:	591c                	lw	a5,48(a0)
    80005030:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80005032:	854a                	mv	a0,s2
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	c64080e7          	jalr	-924(ra) # 80000c98 <release>
}
    8000503c:	60e2                	ld	ra,24(sp)
    8000503e:	6442                	ld	s0,16(sp)
    80005040:	64a2                	ld	s1,8(sp)
    80005042:	6902                	ld	s2,0(sp)
    80005044:	6105                	addi	sp,sp,32
    80005046:	8082                	ret

0000000080005048 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80005048:	1101                	addi	sp,sp,-32
    8000504a:	ec06                	sd	ra,24(sp)
    8000504c:	e822                	sd	s0,16(sp)
    8000504e:	e426                	sd	s1,8(sp)
    80005050:	e04a                	sd	s2,0(sp)
    80005052:	1000                	addi	s0,sp,32
    80005054:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005056:	00850913          	addi	s2,a0,8
    8000505a:	854a                	mv	a0,s2
    8000505c:	ffffc097          	auipc	ra,0xffffc
    80005060:	b88080e7          	jalr	-1144(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80005064:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005068:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000506c:	8526                	mv	a0,s1
    8000506e:	ffffe097          	auipc	ra,0xffffe
    80005072:	d20080e7          	jalr	-736(ra) # 80002d8e <wakeup>
  release(&lk->lk);
    80005076:	854a                	mv	a0,s2
    80005078:	ffffc097          	auipc	ra,0xffffc
    8000507c:	c20080e7          	jalr	-992(ra) # 80000c98 <release>
}
    80005080:	60e2                	ld	ra,24(sp)
    80005082:	6442                	ld	s0,16(sp)
    80005084:	64a2                	ld	s1,8(sp)
    80005086:	6902                	ld	s2,0(sp)
    80005088:	6105                	addi	sp,sp,32
    8000508a:	8082                	ret

000000008000508c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000508c:	7179                	addi	sp,sp,-48
    8000508e:	f406                	sd	ra,40(sp)
    80005090:	f022                	sd	s0,32(sp)
    80005092:	ec26                	sd	s1,24(sp)
    80005094:	e84a                	sd	s2,16(sp)
    80005096:	e44e                	sd	s3,8(sp)
    80005098:	1800                	addi	s0,sp,48
    8000509a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000509c:	00850913          	addi	s2,a0,8
    800050a0:	854a                	mv	a0,s2
    800050a2:	ffffc097          	auipc	ra,0xffffc
    800050a6:	b42080e7          	jalr	-1214(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800050aa:	409c                	lw	a5,0(s1)
    800050ac:	ef99                	bnez	a5,800050ca <holdingsleep+0x3e>
    800050ae:	4481                	li	s1,0
  release(&lk->lk);
    800050b0:	854a                	mv	a0,s2
    800050b2:	ffffc097          	auipc	ra,0xffffc
    800050b6:	be6080e7          	jalr	-1050(ra) # 80000c98 <release>
  return r;
}
    800050ba:	8526                	mv	a0,s1
    800050bc:	70a2                	ld	ra,40(sp)
    800050be:	7402                	ld	s0,32(sp)
    800050c0:	64e2                	ld	s1,24(sp)
    800050c2:	6942                	ld	s2,16(sp)
    800050c4:	69a2                	ld	s3,8(sp)
    800050c6:	6145                	addi	sp,sp,48
    800050c8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800050ca:	0284a983          	lw	s3,40(s1)
    800050ce:	ffffd097          	auipc	ra,0xffffd
    800050d2:	000080e7          	jalr	ra # 800020ce <myproc>
    800050d6:	5904                	lw	s1,48(a0)
    800050d8:	413484b3          	sub	s1,s1,s3
    800050dc:	0014b493          	seqz	s1,s1
    800050e0:	bfc1                	j	800050b0 <holdingsleep+0x24>

00000000800050e2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800050e2:	1141                	addi	sp,sp,-16
    800050e4:	e406                	sd	ra,8(sp)
    800050e6:	e022                	sd	s0,0(sp)
    800050e8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800050ea:	00004597          	auipc	a1,0x4
    800050ee:	97658593          	addi	a1,a1,-1674 # 80008a60 <syscalls+0x250>
    800050f2:	0001d517          	auipc	a0,0x1d
    800050f6:	e4650513          	addi	a0,a0,-442 # 80021f38 <ftable>
    800050fa:	ffffc097          	auipc	ra,0xffffc
    800050fe:	a5a080e7          	jalr	-1446(ra) # 80000b54 <initlock>
}
    80005102:	60a2                	ld	ra,8(sp)
    80005104:	6402                	ld	s0,0(sp)
    80005106:	0141                	addi	sp,sp,16
    80005108:	8082                	ret

000000008000510a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000510a:	1101                	addi	sp,sp,-32
    8000510c:	ec06                	sd	ra,24(sp)
    8000510e:	e822                	sd	s0,16(sp)
    80005110:	e426                	sd	s1,8(sp)
    80005112:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005114:	0001d517          	auipc	a0,0x1d
    80005118:	e2450513          	addi	a0,a0,-476 # 80021f38 <ftable>
    8000511c:	ffffc097          	auipc	ra,0xffffc
    80005120:	ac8080e7          	jalr	-1336(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005124:	0001d497          	auipc	s1,0x1d
    80005128:	e2c48493          	addi	s1,s1,-468 # 80021f50 <ftable+0x18>
    8000512c:	0001e717          	auipc	a4,0x1e
    80005130:	dc470713          	addi	a4,a4,-572 # 80022ef0 <ftable+0xfb8>
    if(f->ref == 0){
    80005134:	40dc                	lw	a5,4(s1)
    80005136:	cf99                	beqz	a5,80005154 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005138:	02848493          	addi	s1,s1,40
    8000513c:	fee49ce3          	bne	s1,a4,80005134 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005140:	0001d517          	auipc	a0,0x1d
    80005144:	df850513          	addi	a0,a0,-520 # 80021f38 <ftable>
    80005148:	ffffc097          	auipc	ra,0xffffc
    8000514c:	b50080e7          	jalr	-1200(ra) # 80000c98 <release>
  return 0;
    80005150:	4481                	li	s1,0
    80005152:	a819                	j	80005168 <filealloc+0x5e>
      f->ref = 1;
    80005154:	4785                	li	a5,1
    80005156:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005158:	0001d517          	auipc	a0,0x1d
    8000515c:	de050513          	addi	a0,a0,-544 # 80021f38 <ftable>
    80005160:	ffffc097          	auipc	ra,0xffffc
    80005164:	b38080e7          	jalr	-1224(ra) # 80000c98 <release>
}
    80005168:	8526                	mv	a0,s1
    8000516a:	60e2                	ld	ra,24(sp)
    8000516c:	6442                	ld	s0,16(sp)
    8000516e:	64a2                	ld	s1,8(sp)
    80005170:	6105                	addi	sp,sp,32
    80005172:	8082                	ret

0000000080005174 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005174:	1101                	addi	sp,sp,-32
    80005176:	ec06                	sd	ra,24(sp)
    80005178:	e822                	sd	s0,16(sp)
    8000517a:	e426                	sd	s1,8(sp)
    8000517c:	1000                	addi	s0,sp,32
    8000517e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005180:	0001d517          	auipc	a0,0x1d
    80005184:	db850513          	addi	a0,a0,-584 # 80021f38 <ftable>
    80005188:	ffffc097          	auipc	ra,0xffffc
    8000518c:	a5c080e7          	jalr	-1444(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80005190:	40dc                	lw	a5,4(s1)
    80005192:	02f05263          	blez	a5,800051b6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005196:	2785                	addiw	a5,a5,1
    80005198:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000519a:	0001d517          	auipc	a0,0x1d
    8000519e:	d9e50513          	addi	a0,a0,-610 # 80021f38 <ftable>
    800051a2:	ffffc097          	auipc	ra,0xffffc
    800051a6:	af6080e7          	jalr	-1290(ra) # 80000c98 <release>
  return f;
}
    800051aa:	8526                	mv	a0,s1
    800051ac:	60e2                	ld	ra,24(sp)
    800051ae:	6442                	ld	s0,16(sp)
    800051b0:	64a2                	ld	s1,8(sp)
    800051b2:	6105                	addi	sp,sp,32
    800051b4:	8082                	ret
    panic("filedup");
    800051b6:	00004517          	auipc	a0,0x4
    800051ba:	8b250513          	addi	a0,a0,-1870 # 80008a68 <syscalls+0x258>
    800051be:	ffffb097          	auipc	ra,0xffffb
    800051c2:	380080e7          	jalr	896(ra) # 8000053e <panic>

00000000800051c6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800051c6:	7139                	addi	sp,sp,-64
    800051c8:	fc06                	sd	ra,56(sp)
    800051ca:	f822                	sd	s0,48(sp)
    800051cc:	f426                	sd	s1,40(sp)
    800051ce:	f04a                	sd	s2,32(sp)
    800051d0:	ec4e                	sd	s3,24(sp)
    800051d2:	e852                	sd	s4,16(sp)
    800051d4:	e456                	sd	s5,8(sp)
    800051d6:	0080                	addi	s0,sp,64
    800051d8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800051da:	0001d517          	auipc	a0,0x1d
    800051de:	d5e50513          	addi	a0,a0,-674 # 80021f38 <ftable>
    800051e2:	ffffc097          	auipc	ra,0xffffc
    800051e6:	a02080e7          	jalr	-1534(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800051ea:	40dc                	lw	a5,4(s1)
    800051ec:	06f05163          	blez	a5,8000524e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800051f0:	37fd                	addiw	a5,a5,-1
    800051f2:	0007871b          	sext.w	a4,a5
    800051f6:	c0dc                	sw	a5,4(s1)
    800051f8:	06e04363          	bgtz	a4,8000525e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800051fc:	0004a903          	lw	s2,0(s1)
    80005200:	0094ca83          	lbu	s5,9(s1)
    80005204:	0104ba03          	ld	s4,16(s1)
    80005208:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000520c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005210:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005214:	0001d517          	auipc	a0,0x1d
    80005218:	d2450513          	addi	a0,a0,-732 # 80021f38 <ftable>
    8000521c:	ffffc097          	auipc	ra,0xffffc
    80005220:	a7c080e7          	jalr	-1412(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80005224:	4785                	li	a5,1
    80005226:	04f90d63          	beq	s2,a5,80005280 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000522a:	3979                	addiw	s2,s2,-2
    8000522c:	4785                	li	a5,1
    8000522e:	0527e063          	bltu	a5,s2,8000526e <fileclose+0xa8>
    begin_op();
    80005232:	00000097          	auipc	ra,0x0
    80005236:	ac8080e7          	jalr	-1336(ra) # 80004cfa <begin_op>
    iput(ff.ip);
    8000523a:	854e                	mv	a0,s3
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	2a6080e7          	jalr	678(ra) # 800044e2 <iput>
    end_op();
    80005244:	00000097          	auipc	ra,0x0
    80005248:	b36080e7          	jalr	-1226(ra) # 80004d7a <end_op>
    8000524c:	a00d                	j	8000526e <fileclose+0xa8>
    panic("fileclose");
    8000524e:	00004517          	auipc	a0,0x4
    80005252:	82250513          	addi	a0,a0,-2014 # 80008a70 <syscalls+0x260>
    80005256:	ffffb097          	auipc	ra,0xffffb
    8000525a:	2e8080e7          	jalr	744(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000525e:	0001d517          	auipc	a0,0x1d
    80005262:	cda50513          	addi	a0,a0,-806 # 80021f38 <ftable>
    80005266:	ffffc097          	auipc	ra,0xffffc
    8000526a:	a32080e7          	jalr	-1486(ra) # 80000c98 <release>
  }
}
    8000526e:	70e2                	ld	ra,56(sp)
    80005270:	7442                	ld	s0,48(sp)
    80005272:	74a2                	ld	s1,40(sp)
    80005274:	7902                	ld	s2,32(sp)
    80005276:	69e2                	ld	s3,24(sp)
    80005278:	6a42                	ld	s4,16(sp)
    8000527a:	6aa2                	ld	s5,8(sp)
    8000527c:	6121                	addi	sp,sp,64
    8000527e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005280:	85d6                	mv	a1,s5
    80005282:	8552                	mv	a0,s4
    80005284:	00000097          	auipc	ra,0x0
    80005288:	34c080e7          	jalr	844(ra) # 800055d0 <pipeclose>
    8000528c:	b7cd                	j	8000526e <fileclose+0xa8>

000000008000528e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000528e:	715d                	addi	sp,sp,-80
    80005290:	e486                	sd	ra,72(sp)
    80005292:	e0a2                	sd	s0,64(sp)
    80005294:	fc26                	sd	s1,56(sp)
    80005296:	f84a                	sd	s2,48(sp)
    80005298:	f44e                	sd	s3,40(sp)
    8000529a:	0880                	addi	s0,sp,80
    8000529c:	84aa                	mv	s1,a0
    8000529e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800052a0:	ffffd097          	auipc	ra,0xffffd
    800052a4:	e2e080e7          	jalr	-466(ra) # 800020ce <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800052a8:	409c                	lw	a5,0(s1)
    800052aa:	37f9                	addiw	a5,a5,-2
    800052ac:	4705                	li	a4,1
    800052ae:	04f76763          	bltu	a4,a5,800052fc <filestat+0x6e>
    800052b2:	892a                	mv	s2,a0
    ilock(f->ip);
    800052b4:	6c88                	ld	a0,24(s1)
    800052b6:	fffff097          	auipc	ra,0xfffff
    800052ba:	072080e7          	jalr	114(ra) # 80004328 <ilock>
    stati(f->ip, &st);
    800052be:	fb840593          	addi	a1,s0,-72
    800052c2:	6c88                	ld	a0,24(s1)
    800052c4:	fffff097          	auipc	ra,0xfffff
    800052c8:	2ee080e7          	jalr	750(ra) # 800045b2 <stati>
    iunlock(f->ip);
    800052cc:	6c88                	ld	a0,24(s1)
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	11c080e7          	jalr	284(ra) # 800043ea <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800052d6:	46e1                	li	a3,24
    800052d8:	fb840613          	addi	a2,s0,-72
    800052dc:	85ce                	mv	a1,s3
    800052de:	05093503          	ld	a0,80(s2)
    800052e2:	ffffc097          	auipc	ra,0xffffc
    800052e6:	390080e7          	jalr	912(ra) # 80001672 <copyout>
    800052ea:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800052ee:	60a6                	ld	ra,72(sp)
    800052f0:	6406                	ld	s0,64(sp)
    800052f2:	74e2                	ld	s1,56(sp)
    800052f4:	7942                	ld	s2,48(sp)
    800052f6:	79a2                	ld	s3,40(sp)
    800052f8:	6161                	addi	sp,sp,80
    800052fa:	8082                	ret
  return -1;
    800052fc:	557d                	li	a0,-1
    800052fe:	bfc5                	j	800052ee <filestat+0x60>

0000000080005300 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005300:	7179                	addi	sp,sp,-48
    80005302:	f406                	sd	ra,40(sp)
    80005304:	f022                	sd	s0,32(sp)
    80005306:	ec26                	sd	s1,24(sp)
    80005308:	e84a                	sd	s2,16(sp)
    8000530a:	e44e                	sd	s3,8(sp)
    8000530c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000530e:	00854783          	lbu	a5,8(a0)
    80005312:	c3d5                	beqz	a5,800053b6 <fileread+0xb6>
    80005314:	84aa                	mv	s1,a0
    80005316:	89ae                	mv	s3,a1
    80005318:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000531a:	411c                	lw	a5,0(a0)
    8000531c:	4705                	li	a4,1
    8000531e:	04e78963          	beq	a5,a4,80005370 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005322:	470d                	li	a4,3
    80005324:	04e78d63          	beq	a5,a4,8000537e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005328:	4709                	li	a4,2
    8000532a:	06e79e63          	bne	a5,a4,800053a6 <fileread+0xa6>
    ilock(f->ip);
    8000532e:	6d08                	ld	a0,24(a0)
    80005330:	fffff097          	auipc	ra,0xfffff
    80005334:	ff8080e7          	jalr	-8(ra) # 80004328 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005338:	874a                	mv	a4,s2
    8000533a:	5094                	lw	a3,32(s1)
    8000533c:	864e                	mv	a2,s3
    8000533e:	4585                	li	a1,1
    80005340:	6c88                	ld	a0,24(s1)
    80005342:	fffff097          	auipc	ra,0xfffff
    80005346:	29a080e7          	jalr	666(ra) # 800045dc <readi>
    8000534a:	892a                	mv	s2,a0
    8000534c:	00a05563          	blez	a0,80005356 <fileread+0x56>
      f->off += r;
    80005350:	509c                	lw	a5,32(s1)
    80005352:	9fa9                	addw	a5,a5,a0
    80005354:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005356:	6c88                	ld	a0,24(s1)
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	092080e7          	jalr	146(ra) # 800043ea <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005360:	854a                	mv	a0,s2
    80005362:	70a2                	ld	ra,40(sp)
    80005364:	7402                	ld	s0,32(sp)
    80005366:	64e2                	ld	s1,24(sp)
    80005368:	6942                	ld	s2,16(sp)
    8000536a:	69a2                	ld	s3,8(sp)
    8000536c:	6145                	addi	sp,sp,48
    8000536e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005370:	6908                	ld	a0,16(a0)
    80005372:	00000097          	auipc	ra,0x0
    80005376:	3c8080e7          	jalr	968(ra) # 8000573a <piperead>
    8000537a:	892a                	mv	s2,a0
    8000537c:	b7d5                	j	80005360 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000537e:	02451783          	lh	a5,36(a0)
    80005382:	03079693          	slli	a3,a5,0x30
    80005386:	92c1                	srli	a3,a3,0x30
    80005388:	4725                	li	a4,9
    8000538a:	02d76863          	bltu	a4,a3,800053ba <fileread+0xba>
    8000538e:	0792                	slli	a5,a5,0x4
    80005390:	0001d717          	auipc	a4,0x1d
    80005394:	b0870713          	addi	a4,a4,-1272 # 80021e98 <devsw>
    80005398:	97ba                	add	a5,a5,a4
    8000539a:	639c                	ld	a5,0(a5)
    8000539c:	c38d                	beqz	a5,800053be <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000539e:	4505                	li	a0,1
    800053a0:	9782                	jalr	a5
    800053a2:	892a                	mv	s2,a0
    800053a4:	bf75                	j	80005360 <fileread+0x60>
    panic("fileread");
    800053a6:	00003517          	auipc	a0,0x3
    800053aa:	6da50513          	addi	a0,a0,1754 # 80008a80 <syscalls+0x270>
    800053ae:	ffffb097          	auipc	ra,0xffffb
    800053b2:	190080e7          	jalr	400(ra) # 8000053e <panic>
    return -1;
    800053b6:	597d                	li	s2,-1
    800053b8:	b765                	j	80005360 <fileread+0x60>
      return -1;
    800053ba:	597d                	li	s2,-1
    800053bc:	b755                	j	80005360 <fileread+0x60>
    800053be:	597d                	li	s2,-1
    800053c0:	b745                	j	80005360 <fileread+0x60>

00000000800053c2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800053c2:	715d                	addi	sp,sp,-80
    800053c4:	e486                	sd	ra,72(sp)
    800053c6:	e0a2                	sd	s0,64(sp)
    800053c8:	fc26                	sd	s1,56(sp)
    800053ca:	f84a                	sd	s2,48(sp)
    800053cc:	f44e                	sd	s3,40(sp)
    800053ce:	f052                	sd	s4,32(sp)
    800053d0:	ec56                	sd	s5,24(sp)
    800053d2:	e85a                	sd	s6,16(sp)
    800053d4:	e45e                	sd	s7,8(sp)
    800053d6:	e062                	sd	s8,0(sp)
    800053d8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800053da:	00954783          	lbu	a5,9(a0)
    800053de:	10078663          	beqz	a5,800054ea <filewrite+0x128>
    800053e2:	892a                	mv	s2,a0
    800053e4:	8aae                	mv	s5,a1
    800053e6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800053e8:	411c                	lw	a5,0(a0)
    800053ea:	4705                	li	a4,1
    800053ec:	02e78263          	beq	a5,a4,80005410 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800053f0:	470d                	li	a4,3
    800053f2:	02e78663          	beq	a5,a4,8000541e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800053f6:	4709                	li	a4,2
    800053f8:	0ee79163          	bne	a5,a4,800054da <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800053fc:	0ac05d63          	blez	a2,800054b6 <filewrite+0xf4>
    int i = 0;
    80005400:	4981                	li	s3,0
    80005402:	6b05                	lui	s6,0x1
    80005404:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005408:	6b85                	lui	s7,0x1
    8000540a:	c00b8b9b          	addiw	s7,s7,-1024
    8000540e:	a861                	j	800054a6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005410:	6908                	ld	a0,16(a0)
    80005412:	00000097          	auipc	ra,0x0
    80005416:	22e080e7          	jalr	558(ra) # 80005640 <pipewrite>
    8000541a:	8a2a                	mv	s4,a0
    8000541c:	a045                	j	800054bc <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000541e:	02451783          	lh	a5,36(a0)
    80005422:	03079693          	slli	a3,a5,0x30
    80005426:	92c1                	srli	a3,a3,0x30
    80005428:	4725                	li	a4,9
    8000542a:	0cd76263          	bltu	a4,a3,800054ee <filewrite+0x12c>
    8000542e:	0792                	slli	a5,a5,0x4
    80005430:	0001d717          	auipc	a4,0x1d
    80005434:	a6870713          	addi	a4,a4,-1432 # 80021e98 <devsw>
    80005438:	97ba                	add	a5,a5,a4
    8000543a:	679c                	ld	a5,8(a5)
    8000543c:	cbdd                	beqz	a5,800054f2 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000543e:	4505                	li	a0,1
    80005440:	9782                	jalr	a5
    80005442:	8a2a                	mv	s4,a0
    80005444:	a8a5                	j	800054bc <filewrite+0xfa>
    80005446:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000544a:	00000097          	auipc	ra,0x0
    8000544e:	8b0080e7          	jalr	-1872(ra) # 80004cfa <begin_op>
      ilock(f->ip);
    80005452:	01893503          	ld	a0,24(s2)
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	ed2080e7          	jalr	-302(ra) # 80004328 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000545e:	8762                	mv	a4,s8
    80005460:	02092683          	lw	a3,32(s2)
    80005464:	01598633          	add	a2,s3,s5
    80005468:	4585                	li	a1,1
    8000546a:	01893503          	ld	a0,24(s2)
    8000546e:	fffff097          	auipc	ra,0xfffff
    80005472:	266080e7          	jalr	614(ra) # 800046d4 <writei>
    80005476:	84aa                	mv	s1,a0
    80005478:	00a05763          	blez	a0,80005486 <filewrite+0xc4>
        f->off += r;
    8000547c:	02092783          	lw	a5,32(s2)
    80005480:	9fa9                	addw	a5,a5,a0
    80005482:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005486:	01893503          	ld	a0,24(s2)
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	f60080e7          	jalr	-160(ra) # 800043ea <iunlock>
      end_op();
    80005492:	00000097          	auipc	ra,0x0
    80005496:	8e8080e7          	jalr	-1816(ra) # 80004d7a <end_op>

      if(r != n1){
    8000549a:	009c1f63          	bne	s8,s1,800054b8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000549e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800054a2:	0149db63          	bge	s3,s4,800054b8 <filewrite+0xf6>
      int n1 = n - i;
    800054a6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800054aa:	84be                	mv	s1,a5
    800054ac:	2781                	sext.w	a5,a5
    800054ae:	f8fb5ce3          	bge	s6,a5,80005446 <filewrite+0x84>
    800054b2:	84de                	mv	s1,s7
    800054b4:	bf49                	j	80005446 <filewrite+0x84>
    int i = 0;
    800054b6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800054b8:	013a1f63          	bne	s4,s3,800054d6 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800054bc:	8552                	mv	a0,s4
    800054be:	60a6                	ld	ra,72(sp)
    800054c0:	6406                	ld	s0,64(sp)
    800054c2:	74e2                	ld	s1,56(sp)
    800054c4:	7942                	ld	s2,48(sp)
    800054c6:	79a2                	ld	s3,40(sp)
    800054c8:	7a02                	ld	s4,32(sp)
    800054ca:	6ae2                	ld	s5,24(sp)
    800054cc:	6b42                	ld	s6,16(sp)
    800054ce:	6ba2                	ld	s7,8(sp)
    800054d0:	6c02                	ld	s8,0(sp)
    800054d2:	6161                	addi	sp,sp,80
    800054d4:	8082                	ret
    ret = (i == n ? n : -1);
    800054d6:	5a7d                	li	s4,-1
    800054d8:	b7d5                	j	800054bc <filewrite+0xfa>
    panic("filewrite");
    800054da:	00003517          	auipc	a0,0x3
    800054de:	5b650513          	addi	a0,a0,1462 # 80008a90 <syscalls+0x280>
    800054e2:	ffffb097          	auipc	ra,0xffffb
    800054e6:	05c080e7          	jalr	92(ra) # 8000053e <panic>
    return -1;
    800054ea:	5a7d                	li	s4,-1
    800054ec:	bfc1                	j	800054bc <filewrite+0xfa>
      return -1;
    800054ee:	5a7d                	li	s4,-1
    800054f0:	b7f1                	j	800054bc <filewrite+0xfa>
    800054f2:	5a7d                	li	s4,-1
    800054f4:	b7e1                	j	800054bc <filewrite+0xfa>

00000000800054f6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800054f6:	7179                	addi	sp,sp,-48
    800054f8:	f406                	sd	ra,40(sp)
    800054fa:	f022                	sd	s0,32(sp)
    800054fc:	ec26                	sd	s1,24(sp)
    800054fe:	e84a                	sd	s2,16(sp)
    80005500:	e44e                	sd	s3,8(sp)
    80005502:	e052                	sd	s4,0(sp)
    80005504:	1800                	addi	s0,sp,48
    80005506:	84aa                	mv	s1,a0
    80005508:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000550a:	0005b023          	sd	zero,0(a1)
    8000550e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005512:	00000097          	auipc	ra,0x0
    80005516:	bf8080e7          	jalr	-1032(ra) # 8000510a <filealloc>
    8000551a:	e088                	sd	a0,0(s1)
    8000551c:	c551                	beqz	a0,800055a8 <pipealloc+0xb2>
    8000551e:	00000097          	auipc	ra,0x0
    80005522:	bec080e7          	jalr	-1044(ra) # 8000510a <filealloc>
    80005526:	00aa3023          	sd	a0,0(s4)
    8000552a:	c92d                	beqz	a0,8000559c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000552c:	ffffb097          	auipc	ra,0xffffb
    80005530:	5c8080e7          	jalr	1480(ra) # 80000af4 <kalloc>
    80005534:	892a                	mv	s2,a0
    80005536:	c125                	beqz	a0,80005596 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005538:	4985                	li	s3,1
    8000553a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000553e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005542:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005546:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000554a:	00003597          	auipc	a1,0x3
    8000554e:	55658593          	addi	a1,a1,1366 # 80008aa0 <syscalls+0x290>
    80005552:	ffffb097          	auipc	ra,0xffffb
    80005556:	602080e7          	jalr	1538(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000555a:	609c                	ld	a5,0(s1)
    8000555c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005560:	609c                	ld	a5,0(s1)
    80005562:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005566:	609c                	ld	a5,0(s1)
    80005568:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000556c:	609c                	ld	a5,0(s1)
    8000556e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005572:	000a3783          	ld	a5,0(s4)
    80005576:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000557a:	000a3783          	ld	a5,0(s4)
    8000557e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005582:	000a3783          	ld	a5,0(s4)
    80005586:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000558a:	000a3783          	ld	a5,0(s4)
    8000558e:	0127b823          	sd	s2,16(a5)
  return 0;
    80005592:	4501                	li	a0,0
    80005594:	a025                	j	800055bc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005596:	6088                	ld	a0,0(s1)
    80005598:	e501                	bnez	a0,800055a0 <pipealloc+0xaa>
    8000559a:	a039                	j	800055a8 <pipealloc+0xb2>
    8000559c:	6088                	ld	a0,0(s1)
    8000559e:	c51d                	beqz	a0,800055cc <pipealloc+0xd6>
    fileclose(*f0);
    800055a0:	00000097          	auipc	ra,0x0
    800055a4:	c26080e7          	jalr	-986(ra) # 800051c6 <fileclose>
  if(*f1)
    800055a8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800055ac:	557d                	li	a0,-1
  if(*f1)
    800055ae:	c799                	beqz	a5,800055bc <pipealloc+0xc6>
    fileclose(*f1);
    800055b0:	853e                	mv	a0,a5
    800055b2:	00000097          	auipc	ra,0x0
    800055b6:	c14080e7          	jalr	-1004(ra) # 800051c6 <fileclose>
  return -1;
    800055ba:	557d                	li	a0,-1
}
    800055bc:	70a2                	ld	ra,40(sp)
    800055be:	7402                	ld	s0,32(sp)
    800055c0:	64e2                	ld	s1,24(sp)
    800055c2:	6942                	ld	s2,16(sp)
    800055c4:	69a2                	ld	s3,8(sp)
    800055c6:	6a02                	ld	s4,0(sp)
    800055c8:	6145                	addi	sp,sp,48
    800055ca:	8082                	ret
  return -1;
    800055cc:	557d                	li	a0,-1
    800055ce:	b7fd                	j	800055bc <pipealloc+0xc6>

00000000800055d0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800055d0:	1101                	addi	sp,sp,-32
    800055d2:	ec06                	sd	ra,24(sp)
    800055d4:	e822                	sd	s0,16(sp)
    800055d6:	e426                	sd	s1,8(sp)
    800055d8:	e04a                	sd	s2,0(sp)
    800055da:	1000                	addi	s0,sp,32
    800055dc:	84aa                	mv	s1,a0
    800055de:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800055e0:	ffffb097          	auipc	ra,0xffffb
    800055e4:	604080e7          	jalr	1540(ra) # 80000be4 <acquire>
  if(writable){
    800055e8:	02090d63          	beqz	s2,80005622 <pipeclose+0x52>
    pi->writeopen = 0;
    800055ec:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800055f0:	21848513          	addi	a0,s1,536
    800055f4:	ffffd097          	auipc	ra,0xffffd
    800055f8:	79a080e7          	jalr	1946(ra) # 80002d8e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800055fc:	2204b783          	ld	a5,544(s1)
    80005600:	eb95                	bnez	a5,80005634 <pipeclose+0x64>
    release(&pi->lock);
    80005602:	8526                	mv	a0,s1
    80005604:	ffffb097          	auipc	ra,0xffffb
    80005608:	694080e7          	jalr	1684(ra) # 80000c98 <release>
    kfree((char*)pi);
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffb097          	auipc	ra,0xffffb
    80005612:	3ea080e7          	jalr	1002(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005616:	60e2                	ld	ra,24(sp)
    80005618:	6442                	ld	s0,16(sp)
    8000561a:	64a2                	ld	s1,8(sp)
    8000561c:	6902                	ld	s2,0(sp)
    8000561e:	6105                	addi	sp,sp,32
    80005620:	8082                	ret
    pi->readopen = 0;
    80005622:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005626:	21c48513          	addi	a0,s1,540
    8000562a:	ffffd097          	auipc	ra,0xffffd
    8000562e:	764080e7          	jalr	1892(ra) # 80002d8e <wakeup>
    80005632:	b7e9                	j	800055fc <pipeclose+0x2c>
    release(&pi->lock);
    80005634:	8526                	mv	a0,s1
    80005636:	ffffb097          	auipc	ra,0xffffb
    8000563a:	662080e7          	jalr	1634(ra) # 80000c98 <release>
}
    8000563e:	bfe1                	j	80005616 <pipeclose+0x46>

0000000080005640 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005640:	7159                	addi	sp,sp,-112
    80005642:	f486                	sd	ra,104(sp)
    80005644:	f0a2                	sd	s0,96(sp)
    80005646:	eca6                	sd	s1,88(sp)
    80005648:	e8ca                	sd	s2,80(sp)
    8000564a:	e4ce                	sd	s3,72(sp)
    8000564c:	e0d2                	sd	s4,64(sp)
    8000564e:	fc56                	sd	s5,56(sp)
    80005650:	f85a                	sd	s6,48(sp)
    80005652:	f45e                	sd	s7,40(sp)
    80005654:	f062                	sd	s8,32(sp)
    80005656:	ec66                	sd	s9,24(sp)
    80005658:	1880                	addi	s0,sp,112
    8000565a:	84aa                	mv	s1,a0
    8000565c:	8aae                	mv	s5,a1
    8000565e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005660:	ffffd097          	auipc	ra,0xffffd
    80005664:	a6e080e7          	jalr	-1426(ra) # 800020ce <myproc>
    80005668:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000566a:	8526                	mv	a0,s1
    8000566c:	ffffb097          	auipc	ra,0xffffb
    80005670:	578080e7          	jalr	1400(ra) # 80000be4 <acquire>
  while(i < n){
    80005674:	0d405163          	blez	s4,80005736 <pipewrite+0xf6>
    80005678:	8ba6                	mv	s7,s1
  int i = 0;
    8000567a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000567c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000567e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005682:	21c48c13          	addi	s8,s1,540
    80005686:	a08d                	j	800056e8 <pipewrite+0xa8>
      release(&pi->lock);
    80005688:	8526                	mv	a0,s1
    8000568a:	ffffb097          	auipc	ra,0xffffb
    8000568e:	60e080e7          	jalr	1550(ra) # 80000c98 <release>
      return -1;
    80005692:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005694:	854a                	mv	a0,s2
    80005696:	70a6                	ld	ra,104(sp)
    80005698:	7406                	ld	s0,96(sp)
    8000569a:	64e6                	ld	s1,88(sp)
    8000569c:	6946                	ld	s2,80(sp)
    8000569e:	69a6                	ld	s3,72(sp)
    800056a0:	6a06                	ld	s4,64(sp)
    800056a2:	7ae2                	ld	s5,56(sp)
    800056a4:	7b42                	ld	s6,48(sp)
    800056a6:	7ba2                	ld	s7,40(sp)
    800056a8:	7c02                	ld	s8,32(sp)
    800056aa:	6ce2                	ld	s9,24(sp)
    800056ac:	6165                	addi	sp,sp,112
    800056ae:	8082                	ret
      wakeup(&pi->nread);
    800056b0:	8566                	mv	a0,s9
    800056b2:	ffffd097          	auipc	ra,0xffffd
    800056b6:	6dc080e7          	jalr	1756(ra) # 80002d8e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800056ba:	85de                	mv	a1,s7
    800056bc:	8562                	mv	a0,s8
    800056be:	ffffd097          	auipc	ra,0xffffd
    800056c2:	04a080e7          	jalr	74(ra) # 80002708 <sleep>
    800056c6:	a839                	j	800056e4 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800056c8:	21c4a783          	lw	a5,540(s1)
    800056cc:	0017871b          	addiw	a4,a5,1
    800056d0:	20e4ae23          	sw	a4,540(s1)
    800056d4:	1ff7f793          	andi	a5,a5,511
    800056d8:	97a6                	add	a5,a5,s1
    800056da:	f9f44703          	lbu	a4,-97(s0)
    800056de:	00e78c23          	sb	a4,24(a5)
      i++;
    800056e2:	2905                	addiw	s2,s2,1
  while(i < n){
    800056e4:	03495d63          	bge	s2,s4,8000571e <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800056e8:	2204a783          	lw	a5,544(s1)
    800056ec:	dfd1                	beqz	a5,80005688 <pipewrite+0x48>
    800056ee:	0289a783          	lw	a5,40(s3)
    800056f2:	fbd9                	bnez	a5,80005688 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800056f4:	2184a783          	lw	a5,536(s1)
    800056f8:	21c4a703          	lw	a4,540(s1)
    800056fc:	2007879b          	addiw	a5,a5,512
    80005700:	faf708e3          	beq	a4,a5,800056b0 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005704:	4685                	li	a3,1
    80005706:	01590633          	add	a2,s2,s5
    8000570a:	f9f40593          	addi	a1,s0,-97
    8000570e:	0509b503          	ld	a0,80(s3)
    80005712:	ffffc097          	auipc	ra,0xffffc
    80005716:	fec080e7          	jalr	-20(ra) # 800016fe <copyin>
    8000571a:	fb6517e3          	bne	a0,s6,800056c8 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000571e:	21848513          	addi	a0,s1,536
    80005722:	ffffd097          	auipc	ra,0xffffd
    80005726:	66c080e7          	jalr	1644(ra) # 80002d8e <wakeup>
  release(&pi->lock);
    8000572a:	8526                	mv	a0,s1
    8000572c:	ffffb097          	auipc	ra,0xffffb
    80005730:	56c080e7          	jalr	1388(ra) # 80000c98 <release>
  return i;
    80005734:	b785                	j	80005694 <pipewrite+0x54>
  int i = 0;
    80005736:	4901                	li	s2,0
    80005738:	b7dd                	j	8000571e <pipewrite+0xde>

000000008000573a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000573a:	715d                	addi	sp,sp,-80
    8000573c:	e486                	sd	ra,72(sp)
    8000573e:	e0a2                	sd	s0,64(sp)
    80005740:	fc26                	sd	s1,56(sp)
    80005742:	f84a                	sd	s2,48(sp)
    80005744:	f44e                	sd	s3,40(sp)
    80005746:	f052                	sd	s4,32(sp)
    80005748:	ec56                	sd	s5,24(sp)
    8000574a:	e85a                	sd	s6,16(sp)
    8000574c:	0880                	addi	s0,sp,80
    8000574e:	84aa                	mv	s1,a0
    80005750:	892e                	mv	s2,a1
    80005752:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005754:	ffffd097          	auipc	ra,0xffffd
    80005758:	97a080e7          	jalr	-1670(ra) # 800020ce <myproc>
    8000575c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000575e:	8b26                	mv	s6,s1
    80005760:	8526                	mv	a0,s1
    80005762:	ffffb097          	auipc	ra,0xffffb
    80005766:	482080e7          	jalr	1154(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000576a:	2184a703          	lw	a4,536(s1)
    8000576e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005772:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005776:	02f71463          	bne	a4,a5,8000579e <piperead+0x64>
    8000577a:	2244a783          	lw	a5,548(s1)
    8000577e:	c385                	beqz	a5,8000579e <piperead+0x64>
    if(pr->killed){
    80005780:	028a2783          	lw	a5,40(s4)
    80005784:	ebc1                	bnez	a5,80005814 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005786:	85da                	mv	a1,s6
    80005788:	854e                	mv	a0,s3
    8000578a:	ffffd097          	auipc	ra,0xffffd
    8000578e:	f7e080e7          	jalr	-130(ra) # 80002708 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005792:	2184a703          	lw	a4,536(s1)
    80005796:	21c4a783          	lw	a5,540(s1)
    8000579a:	fef700e3          	beq	a4,a5,8000577a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000579e:	09505263          	blez	s5,80005822 <piperead+0xe8>
    800057a2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800057a4:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800057a6:	2184a783          	lw	a5,536(s1)
    800057aa:	21c4a703          	lw	a4,540(s1)
    800057ae:	02f70d63          	beq	a4,a5,800057e8 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800057b2:	0017871b          	addiw	a4,a5,1
    800057b6:	20e4ac23          	sw	a4,536(s1)
    800057ba:	1ff7f793          	andi	a5,a5,511
    800057be:	97a6                	add	a5,a5,s1
    800057c0:	0187c783          	lbu	a5,24(a5)
    800057c4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800057c8:	4685                	li	a3,1
    800057ca:	fbf40613          	addi	a2,s0,-65
    800057ce:	85ca                	mv	a1,s2
    800057d0:	050a3503          	ld	a0,80(s4)
    800057d4:	ffffc097          	auipc	ra,0xffffc
    800057d8:	e9e080e7          	jalr	-354(ra) # 80001672 <copyout>
    800057dc:	01650663          	beq	a0,s6,800057e8 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057e0:	2985                	addiw	s3,s3,1
    800057e2:	0905                	addi	s2,s2,1
    800057e4:	fd3a91e3          	bne	s5,s3,800057a6 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800057e8:	21c48513          	addi	a0,s1,540
    800057ec:	ffffd097          	auipc	ra,0xffffd
    800057f0:	5a2080e7          	jalr	1442(ra) # 80002d8e <wakeup>
  release(&pi->lock);
    800057f4:	8526                	mv	a0,s1
    800057f6:	ffffb097          	auipc	ra,0xffffb
    800057fa:	4a2080e7          	jalr	1186(ra) # 80000c98 <release>
  return i;
}
    800057fe:	854e                	mv	a0,s3
    80005800:	60a6                	ld	ra,72(sp)
    80005802:	6406                	ld	s0,64(sp)
    80005804:	74e2                	ld	s1,56(sp)
    80005806:	7942                	ld	s2,48(sp)
    80005808:	79a2                	ld	s3,40(sp)
    8000580a:	7a02                	ld	s4,32(sp)
    8000580c:	6ae2                	ld	s5,24(sp)
    8000580e:	6b42                	ld	s6,16(sp)
    80005810:	6161                	addi	sp,sp,80
    80005812:	8082                	ret
      release(&pi->lock);
    80005814:	8526                	mv	a0,s1
    80005816:	ffffb097          	auipc	ra,0xffffb
    8000581a:	482080e7          	jalr	1154(ra) # 80000c98 <release>
      return -1;
    8000581e:	59fd                	li	s3,-1
    80005820:	bff9                	j	800057fe <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005822:	4981                	li	s3,0
    80005824:	b7d1                	j	800057e8 <piperead+0xae>

0000000080005826 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005826:	df010113          	addi	sp,sp,-528
    8000582a:	20113423          	sd	ra,520(sp)
    8000582e:	20813023          	sd	s0,512(sp)
    80005832:	ffa6                	sd	s1,504(sp)
    80005834:	fbca                	sd	s2,496(sp)
    80005836:	f7ce                	sd	s3,488(sp)
    80005838:	f3d2                	sd	s4,480(sp)
    8000583a:	efd6                	sd	s5,472(sp)
    8000583c:	ebda                	sd	s6,464(sp)
    8000583e:	e7de                	sd	s7,456(sp)
    80005840:	e3e2                	sd	s8,448(sp)
    80005842:	ff66                	sd	s9,440(sp)
    80005844:	fb6a                	sd	s10,432(sp)
    80005846:	f76e                	sd	s11,424(sp)
    80005848:	0c00                	addi	s0,sp,528
    8000584a:	84aa                	mv	s1,a0
    8000584c:	dea43c23          	sd	a0,-520(s0)
    80005850:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005854:	ffffd097          	auipc	ra,0xffffd
    80005858:	87a080e7          	jalr	-1926(ra) # 800020ce <myproc>
    8000585c:	892a                	mv	s2,a0

  begin_op();
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	49c080e7          	jalr	1180(ra) # 80004cfa <begin_op>

  if((ip = namei(path)) == 0){
    80005866:	8526                	mv	a0,s1
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	276080e7          	jalr	630(ra) # 80004ade <namei>
    80005870:	c92d                	beqz	a0,800058e2 <exec+0xbc>
    80005872:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	ab4080e7          	jalr	-1356(ra) # 80004328 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000587c:	04000713          	li	a4,64
    80005880:	4681                	li	a3,0
    80005882:	e5040613          	addi	a2,s0,-432
    80005886:	4581                	li	a1,0
    80005888:	8526                	mv	a0,s1
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	d52080e7          	jalr	-686(ra) # 800045dc <readi>
    80005892:	04000793          	li	a5,64
    80005896:	00f51a63          	bne	a0,a5,800058aa <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000589a:	e5042703          	lw	a4,-432(s0)
    8000589e:	464c47b7          	lui	a5,0x464c4
    800058a2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800058a6:	04f70463          	beq	a4,a5,800058ee <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800058aa:	8526                	mv	a0,s1
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	cde080e7          	jalr	-802(ra) # 8000458a <iunlockput>
    end_op();
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	4c6080e7          	jalr	1222(ra) # 80004d7a <end_op>
  }
  return -1;
    800058bc:	557d                	li	a0,-1
}
    800058be:	20813083          	ld	ra,520(sp)
    800058c2:	20013403          	ld	s0,512(sp)
    800058c6:	74fe                	ld	s1,504(sp)
    800058c8:	795e                	ld	s2,496(sp)
    800058ca:	79be                	ld	s3,488(sp)
    800058cc:	7a1e                	ld	s4,480(sp)
    800058ce:	6afe                	ld	s5,472(sp)
    800058d0:	6b5e                	ld	s6,464(sp)
    800058d2:	6bbe                	ld	s7,456(sp)
    800058d4:	6c1e                	ld	s8,448(sp)
    800058d6:	7cfa                	ld	s9,440(sp)
    800058d8:	7d5a                	ld	s10,432(sp)
    800058da:	7dba                	ld	s11,424(sp)
    800058dc:	21010113          	addi	sp,sp,528
    800058e0:	8082                	ret
    end_op();
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	498080e7          	jalr	1176(ra) # 80004d7a <end_op>
    return -1;
    800058ea:	557d                	li	a0,-1
    800058ec:	bfc9                	j	800058be <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800058ee:	854a                	mv	a0,s2
    800058f0:	ffffd097          	auipc	ra,0xffffd
    800058f4:	89c080e7          	jalr	-1892(ra) # 8000218c <proc_pagetable>
    800058f8:	8baa                	mv	s7,a0
    800058fa:	d945                	beqz	a0,800058aa <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800058fc:	e7042983          	lw	s3,-400(s0)
    80005900:	e8845783          	lhu	a5,-376(s0)
    80005904:	c7ad                	beqz	a5,8000596e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005906:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005908:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000590a:	6c85                	lui	s9,0x1
    8000590c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005910:	def43823          	sd	a5,-528(s0)
    80005914:	a42d                	j	80005b3e <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005916:	00003517          	auipc	a0,0x3
    8000591a:	19250513          	addi	a0,a0,402 # 80008aa8 <syscalls+0x298>
    8000591e:	ffffb097          	auipc	ra,0xffffb
    80005922:	c20080e7          	jalr	-992(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005926:	8756                	mv	a4,s5
    80005928:	012d86bb          	addw	a3,s11,s2
    8000592c:	4581                	li	a1,0
    8000592e:	8526                	mv	a0,s1
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	cac080e7          	jalr	-852(ra) # 800045dc <readi>
    80005938:	2501                	sext.w	a0,a0
    8000593a:	1aaa9963          	bne	s5,a0,80005aec <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000593e:	6785                	lui	a5,0x1
    80005940:	0127893b          	addw	s2,a5,s2
    80005944:	77fd                	lui	a5,0xfffff
    80005946:	01478a3b          	addw	s4,a5,s4
    8000594a:	1f897163          	bgeu	s2,s8,80005b2c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000594e:	02091593          	slli	a1,s2,0x20
    80005952:	9181                	srli	a1,a1,0x20
    80005954:	95ea                	add	a1,a1,s10
    80005956:	855e                	mv	a0,s7
    80005958:	ffffb097          	auipc	ra,0xffffb
    8000595c:	716080e7          	jalr	1814(ra) # 8000106e <walkaddr>
    80005960:	862a                	mv	a2,a0
    if(pa == 0)
    80005962:	d955                	beqz	a0,80005916 <exec+0xf0>
      n = PGSIZE;
    80005964:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005966:	fd9a70e3          	bgeu	s4,s9,80005926 <exec+0x100>
      n = sz - i;
    8000596a:	8ad2                	mv	s5,s4
    8000596c:	bf6d                	j	80005926 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000596e:	4901                	li	s2,0
  iunlockput(ip);
    80005970:	8526                	mv	a0,s1
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	c18080e7          	jalr	-1000(ra) # 8000458a <iunlockput>
  end_op();
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	400080e7          	jalr	1024(ra) # 80004d7a <end_op>
  p = myproc();
    80005982:	ffffc097          	auipc	ra,0xffffc
    80005986:	74c080e7          	jalr	1868(ra) # 800020ce <myproc>
    8000598a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000598c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005990:	6785                	lui	a5,0x1
    80005992:	17fd                	addi	a5,a5,-1
    80005994:	993e                	add	s2,s2,a5
    80005996:	757d                	lui	a0,0xfffff
    80005998:	00a977b3          	and	a5,s2,a0
    8000599c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800059a0:	6609                	lui	a2,0x2
    800059a2:	963e                	add	a2,a2,a5
    800059a4:	85be                	mv	a1,a5
    800059a6:	855e                	mv	a0,s7
    800059a8:	ffffc097          	auipc	ra,0xffffc
    800059ac:	a7a080e7          	jalr	-1414(ra) # 80001422 <uvmalloc>
    800059b0:	8b2a                	mv	s6,a0
  ip = 0;
    800059b2:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800059b4:	12050c63          	beqz	a0,80005aec <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800059b8:	75f9                	lui	a1,0xffffe
    800059ba:	95aa                	add	a1,a1,a0
    800059bc:	855e                	mv	a0,s7
    800059be:	ffffc097          	auipc	ra,0xffffc
    800059c2:	c82080e7          	jalr	-894(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800059c6:	7c7d                	lui	s8,0xfffff
    800059c8:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800059ca:	e0043783          	ld	a5,-512(s0)
    800059ce:	6388                	ld	a0,0(a5)
    800059d0:	c535                	beqz	a0,80005a3c <exec+0x216>
    800059d2:	e9040993          	addi	s3,s0,-368
    800059d6:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800059da:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800059dc:	ffffb097          	auipc	ra,0xffffb
    800059e0:	488080e7          	jalr	1160(ra) # 80000e64 <strlen>
    800059e4:	2505                	addiw	a0,a0,1
    800059e6:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800059ea:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800059ee:	13896363          	bltu	s2,s8,80005b14 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800059f2:	e0043d83          	ld	s11,-512(s0)
    800059f6:	000dba03          	ld	s4,0(s11)
    800059fa:	8552                	mv	a0,s4
    800059fc:	ffffb097          	auipc	ra,0xffffb
    80005a00:	468080e7          	jalr	1128(ra) # 80000e64 <strlen>
    80005a04:	0015069b          	addiw	a3,a0,1
    80005a08:	8652                	mv	a2,s4
    80005a0a:	85ca                	mv	a1,s2
    80005a0c:	855e                	mv	a0,s7
    80005a0e:	ffffc097          	auipc	ra,0xffffc
    80005a12:	c64080e7          	jalr	-924(ra) # 80001672 <copyout>
    80005a16:	10054363          	bltz	a0,80005b1c <exec+0x2f6>
    ustack[argc] = sp;
    80005a1a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005a1e:	0485                	addi	s1,s1,1
    80005a20:	008d8793          	addi	a5,s11,8
    80005a24:	e0f43023          	sd	a5,-512(s0)
    80005a28:	008db503          	ld	a0,8(s11)
    80005a2c:	c911                	beqz	a0,80005a40 <exec+0x21a>
    if(argc >= MAXARG)
    80005a2e:	09a1                	addi	s3,s3,8
    80005a30:	fb3c96e3          	bne	s9,s3,800059dc <exec+0x1b6>
  sz = sz1;
    80005a34:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005a38:	4481                	li	s1,0
    80005a3a:	a84d                	j	80005aec <exec+0x2c6>
  sp = sz;
    80005a3c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005a3e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005a40:	00349793          	slli	a5,s1,0x3
    80005a44:	f9040713          	addi	a4,s0,-112
    80005a48:	97ba                	add	a5,a5,a4
    80005a4a:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005a4e:	00148693          	addi	a3,s1,1
    80005a52:	068e                	slli	a3,a3,0x3
    80005a54:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005a58:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005a5c:	01897663          	bgeu	s2,s8,80005a68 <exec+0x242>
  sz = sz1;
    80005a60:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005a64:	4481                	li	s1,0
    80005a66:	a059                	j	80005aec <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005a68:	e9040613          	addi	a2,s0,-368
    80005a6c:	85ca                	mv	a1,s2
    80005a6e:	855e                	mv	a0,s7
    80005a70:	ffffc097          	auipc	ra,0xffffc
    80005a74:	c02080e7          	jalr	-1022(ra) # 80001672 <copyout>
    80005a78:	0a054663          	bltz	a0,80005b24 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005a7c:	058ab783          	ld	a5,88(s5)
    80005a80:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005a84:	df843783          	ld	a5,-520(s0)
    80005a88:	0007c703          	lbu	a4,0(a5)
    80005a8c:	cf11                	beqz	a4,80005aa8 <exec+0x282>
    80005a8e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005a90:	02f00693          	li	a3,47
    80005a94:	a039                	j	80005aa2 <exec+0x27c>
      last = s+1;
    80005a96:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005a9a:	0785                	addi	a5,a5,1
    80005a9c:	fff7c703          	lbu	a4,-1(a5)
    80005aa0:	c701                	beqz	a4,80005aa8 <exec+0x282>
    if(*s == '/')
    80005aa2:	fed71ce3          	bne	a4,a3,80005a9a <exec+0x274>
    80005aa6:	bfc5                	j	80005a96 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005aa8:	4641                	li	a2,16
    80005aaa:	df843583          	ld	a1,-520(s0)
    80005aae:	158a8513          	addi	a0,s5,344
    80005ab2:	ffffb097          	auipc	ra,0xffffb
    80005ab6:	380080e7          	jalr	896(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005aba:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005abe:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005ac2:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005ac6:	058ab783          	ld	a5,88(s5)
    80005aca:	e6843703          	ld	a4,-408(s0)
    80005ace:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005ad0:	058ab783          	ld	a5,88(s5)
    80005ad4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005ad8:	85ea                	mv	a1,s10
    80005ada:	ffffc097          	auipc	ra,0xffffc
    80005ade:	74e080e7          	jalr	1870(ra) # 80002228 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005ae2:	0004851b          	sext.w	a0,s1
    80005ae6:	bbe1                	j	800058be <exec+0x98>
    80005ae8:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005aec:	e0843583          	ld	a1,-504(s0)
    80005af0:	855e                	mv	a0,s7
    80005af2:	ffffc097          	auipc	ra,0xffffc
    80005af6:	736080e7          	jalr	1846(ra) # 80002228 <proc_freepagetable>
  if(ip){
    80005afa:	da0498e3          	bnez	s1,800058aa <exec+0x84>
  return -1;
    80005afe:	557d                	li	a0,-1
    80005b00:	bb7d                	j	800058be <exec+0x98>
    80005b02:	e1243423          	sd	s2,-504(s0)
    80005b06:	b7dd                	j	80005aec <exec+0x2c6>
    80005b08:	e1243423          	sd	s2,-504(s0)
    80005b0c:	b7c5                	j	80005aec <exec+0x2c6>
    80005b0e:	e1243423          	sd	s2,-504(s0)
    80005b12:	bfe9                	j	80005aec <exec+0x2c6>
  sz = sz1;
    80005b14:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005b18:	4481                	li	s1,0
    80005b1a:	bfc9                	j	80005aec <exec+0x2c6>
  sz = sz1;
    80005b1c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005b20:	4481                	li	s1,0
    80005b22:	b7e9                	j	80005aec <exec+0x2c6>
  sz = sz1;
    80005b24:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005b28:	4481                	li	s1,0
    80005b2a:	b7c9                	j	80005aec <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005b2c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005b30:	2b05                	addiw	s6,s6,1
    80005b32:	0389899b          	addiw	s3,s3,56
    80005b36:	e8845783          	lhu	a5,-376(s0)
    80005b3a:	e2fb5be3          	bge	s6,a5,80005970 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005b3e:	2981                	sext.w	s3,s3
    80005b40:	03800713          	li	a4,56
    80005b44:	86ce                	mv	a3,s3
    80005b46:	e1840613          	addi	a2,s0,-488
    80005b4a:	4581                	li	a1,0
    80005b4c:	8526                	mv	a0,s1
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	a8e080e7          	jalr	-1394(ra) # 800045dc <readi>
    80005b56:	03800793          	li	a5,56
    80005b5a:	f8f517e3          	bne	a0,a5,80005ae8 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005b5e:	e1842783          	lw	a5,-488(s0)
    80005b62:	4705                	li	a4,1
    80005b64:	fce796e3          	bne	a5,a4,80005b30 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005b68:	e4043603          	ld	a2,-448(s0)
    80005b6c:	e3843783          	ld	a5,-456(s0)
    80005b70:	f8f669e3          	bltu	a2,a5,80005b02 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005b74:	e2843783          	ld	a5,-472(s0)
    80005b78:	963e                	add	a2,a2,a5
    80005b7a:	f8f667e3          	bltu	a2,a5,80005b08 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005b7e:	85ca                	mv	a1,s2
    80005b80:	855e                	mv	a0,s7
    80005b82:	ffffc097          	auipc	ra,0xffffc
    80005b86:	8a0080e7          	jalr	-1888(ra) # 80001422 <uvmalloc>
    80005b8a:	e0a43423          	sd	a0,-504(s0)
    80005b8e:	d141                	beqz	a0,80005b0e <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005b90:	e2843d03          	ld	s10,-472(s0)
    80005b94:	df043783          	ld	a5,-528(s0)
    80005b98:	00fd77b3          	and	a5,s10,a5
    80005b9c:	fba1                	bnez	a5,80005aec <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005b9e:	e2042d83          	lw	s11,-480(s0)
    80005ba2:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005ba6:	f80c03e3          	beqz	s8,80005b2c <exec+0x306>
    80005baa:	8a62                	mv	s4,s8
    80005bac:	4901                	li	s2,0
    80005bae:	b345                	j	8000594e <exec+0x128>

0000000080005bb0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005bb0:	7179                	addi	sp,sp,-48
    80005bb2:	f406                	sd	ra,40(sp)
    80005bb4:	f022                	sd	s0,32(sp)
    80005bb6:	ec26                	sd	s1,24(sp)
    80005bb8:	e84a                	sd	s2,16(sp)
    80005bba:	1800                	addi	s0,sp,48
    80005bbc:	892e                	mv	s2,a1
    80005bbe:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005bc0:	fdc40593          	addi	a1,s0,-36
    80005bc4:	ffffe097          	auipc	ra,0xffffe
    80005bc8:	b76080e7          	jalr	-1162(ra) # 8000373a <argint>
    80005bcc:	04054063          	bltz	a0,80005c0c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005bd0:	fdc42703          	lw	a4,-36(s0)
    80005bd4:	47bd                	li	a5,15
    80005bd6:	02e7ed63          	bltu	a5,a4,80005c10 <argfd+0x60>
    80005bda:	ffffc097          	auipc	ra,0xffffc
    80005bde:	4f4080e7          	jalr	1268(ra) # 800020ce <myproc>
    80005be2:	fdc42703          	lw	a4,-36(s0)
    80005be6:	01a70793          	addi	a5,a4,26
    80005bea:	078e                	slli	a5,a5,0x3
    80005bec:	953e                	add	a0,a0,a5
    80005bee:	611c                	ld	a5,0(a0)
    80005bf0:	c395                	beqz	a5,80005c14 <argfd+0x64>
    return -1;
  if(pfd)
    80005bf2:	00090463          	beqz	s2,80005bfa <argfd+0x4a>
    *pfd = fd;
    80005bf6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005bfa:	4501                	li	a0,0
  if(pf)
    80005bfc:	c091                	beqz	s1,80005c00 <argfd+0x50>
    *pf = f;
    80005bfe:	e09c                	sd	a5,0(s1)
}
    80005c00:	70a2                	ld	ra,40(sp)
    80005c02:	7402                	ld	s0,32(sp)
    80005c04:	64e2                	ld	s1,24(sp)
    80005c06:	6942                	ld	s2,16(sp)
    80005c08:	6145                	addi	sp,sp,48
    80005c0a:	8082                	ret
    return -1;
    80005c0c:	557d                	li	a0,-1
    80005c0e:	bfcd                	j	80005c00 <argfd+0x50>
    return -1;
    80005c10:	557d                	li	a0,-1
    80005c12:	b7fd                	j	80005c00 <argfd+0x50>
    80005c14:	557d                	li	a0,-1
    80005c16:	b7ed                	j	80005c00 <argfd+0x50>

0000000080005c18 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005c18:	1101                	addi	sp,sp,-32
    80005c1a:	ec06                	sd	ra,24(sp)
    80005c1c:	e822                	sd	s0,16(sp)
    80005c1e:	e426                	sd	s1,8(sp)
    80005c20:	1000                	addi	s0,sp,32
    80005c22:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005c24:	ffffc097          	auipc	ra,0xffffc
    80005c28:	4aa080e7          	jalr	1194(ra) # 800020ce <myproc>
    80005c2c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005c2e:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005c32:	4501                	li	a0,0
    80005c34:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005c36:	6398                	ld	a4,0(a5)
    80005c38:	cb19                	beqz	a4,80005c4e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005c3a:	2505                	addiw	a0,a0,1
    80005c3c:	07a1                	addi	a5,a5,8
    80005c3e:	fed51ce3          	bne	a0,a3,80005c36 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005c42:	557d                	li	a0,-1
}
    80005c44:	60e2                	ld	ra,24(sp)
    80005c46:	6442                	ld	s0,16(sp)
    80005c48:	64a2                	ld	s1,8(sp)
    80005c4a:	6105                	addi	sp,sp,32
    80005c4c:	8082                	ret
      p->ofile[fd] = f;
    80005c4e:	01a50793          	addi	a5,a0,26
    80005c52:	078e                	slli	a5,a5,0x3
    80005c54:	963e                	add	a2,a2,a5
    80005c56:	e204                	sd	s1,0(a2)
      return fd;
    80005c58:	b7f5                	j	80005c44 <fdalloc+0x2c>

0000000080005c5a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005c5a:	715d                	addi	sp,sp,-80
    80005c5c:	e486                	sd	ra,72(sp)
    80005c5e:	e0a2                	sd	s0,64(sp)
    80005c60:	fc26                	sd	s1,56(sp)
    80005c62:	f84a                	sd	s2,48(sp)
    80005c64:	f44e                	sd	s3,40(sp)
    80005c66:	f052                	sd	s4,32(sp)
    80005c68:	ec56                	sd	s5,24(sp)
    80005c6a:	0880                	addi	s0,sp,80
    80005c6c:	89ae                	mv	s3,a1
    80005c6e:	8ab2                	mv	s5,a2
    80005c70:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005c72:	fb040593          	addi	a1,s0,-80
    80005c76:	fffff097          	auipc	ra,0xfffff
    80005c7a:	e86080e7          	jalr	-378(ra) # 80004afc <nameiparent>
    80005c7e:	892a                	mv	s2,a0
    80005c80:	12050f63          	beqz	a0,80005dbe <create+0x164>
    return 0;

  ilock(dp);
    80005c84:	ffffe097          	auipc	ra,0xffffe
    80005c88:	6a4080e7          	jalr	1700(ra) # 80004328 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005c8c:	4601                	li	a2,0
    80005c8e:	fb040593          	addi	a1,s0,-80
    80005c92:	854a                	mv	a0,s2
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	b78080e7          	jalr	-1160(ra) # 8000480c <dirlookup>
    80005c9c:	84aa                	mv	s1,a0
    80005c9e:	c921                	beqz	a0,80005cee <create+0x94>
    iunlockput(dp);
    80005ca0:	854a                	mv	a0,s2
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	8e8080e7          	jalr	-1816(ra) # 8000458a <iunlockput>
    ilock(ip);
    80005caa:	8526                	mv	a0,s1
    80005cac:	ffffe097          	auipc	ra,0xffffe
    80005cb0:	67c080e7          	jalr	1660(ra) # 80004328 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005cb4:	2981                	sext.w	s3,s3
    80005cb6:	4789                	li	a5,2
    80005cb8:	02f99463          	bne	s3,a5,80005ce0 <create+0x86>
    80005cbc:	0444d783          	lhu	a5,68(s1)
    80005cc0:	37f9                	addiw	a5,a5,-2
    80005cc2:	17c2                	slli	a5,a5,0x30
    80005cc4:	93c1                	srli	a5,a5,0x30
    80005cc6:	4705                	li	a4,1
    80005cc8:	00f76c63          	bltu	a4,a5,80005ce0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005ccc:	8526                	mv	a0,s1
    80005cce:	60a6                	ld	ra,72(sp)
    80005cd0:	6406                	ld	s0,64(sp)
    80005cd2:	74e2                	ld	s1,56(sp)
    80005cd4:	7942                	ld	s2,48(sp)
    80005cd6:	79a2                	ld	s3,40(sp)
    80005cd8:	7a02                	ld	s4,32(sp)
    80005cda:	6ae2                	ld	s5,24(sp)
    80005cdc:	6161                	addi	sp,sp,80
    80005cde:	8082                	ret
    iunlockput(ip);
    80005ce0:	8526                	mv	a0,s1
    80005ce2:	fffff097          	auipc	ra,0xfffff
    80005ce6:	8a8080e7          	jalr	-1880(ra) # 8000458a <iunlockput>
    return 0;
    80005cea:	4481                	li	s1,0
    80005cec:	b7c5                	j	80005ccc <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005cee:	85ce                	mv	a1,s3
    80005cf0:	00092503          	lw	a0,0(s2)
    80005cf4:	ffffe097          	auipc	ra,0xffffe
    80005cf8:	49c080e7          	jalr	1180(ra) # 80004190 <ialloc>
    80005cfc:	84aa                	mv	s1,a0
    80005cfe:	c529                	beqz	a0,80005d48 <create+0xee>
  ilock(ip);
    80005d00:	ffffe097          	auipc	ra,0xffffe
    80005d04:	628080e7          	jalr	1576(ra) # 80004328 <ilock>
  ip->major = major;
    80005d08:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005d0c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005d10:	4785                	li	a5,1
    80005d12:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d16:	8526                	mv	a0,s1
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	546080e7          	jalr	1350(ra) # 8000425e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005d20:	2981                	sext.w	s3,s3
    80005d22:	4785                	li	a5,1
    80005d24:	02f98a63          	beq	s3,a5,80005d58 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005d28:	40d0                	lw	a2,4(s1)
    80005d2a:	fb040593          	addi	a1,s0,-80
    80005d2e:	854a                	mv	a0,s2
    80005d30:	fffff097          	auipc	ra,0xfffff
    80005d34:	cec080e7          	jalr	-788(ra) # 80004a1c <dirlink>
    80005d38:	06054b63          	bltz	a0,80005dae <create+0x154>
  iunlockput(dp);
    80005d3c:	854a                	mv	a0,s2
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	84c080e7          	jalr	-1972(ra) # 8000458a <iunlockput>
  return ip;
    80005d46:	b759                	j	80005ccc <create+0x72>
    panic("create: ialloc");
    80005d48:	00003517          	auipc	a0,0x3
    80005d4c:	d8050513          	addi	a0,a0,-640 # 80008ac8 <syscalls+0x2b8>
    80005d50:	ffffa097          	auipc	ra,0xffffa
    80005d54:	7ee080e7          	jalr	2030(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005d58:	04a95783          	lhu	a5,74(s2)
    80005d5c:	2785                	addiw	a5,a5,1
    80005d5e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005d62:	854a                	mv	a0,s2
    80005d64:	ffffe097          	auipc	ra,0xffffe
    80005d68:	4fa080e7          	jalr	1274(ra) # 8000425e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005d6c:	40d0                	lw	a2,4(s1)
    80005d6e:	00003597          	auipc	a1,0x3
    80005d72:	d6a58593          	addi	a1,a1,-662 # 80008ad8 <syscalls+0x2c8>
    80005d76:	8526                	mv	a0,s1
    80005d78:	fffff097          	auipc	ra,0xfffff
    80005d7c:	ca4080e7          	jalr	-860(ra) # 80004a1c <dirlink>
    80005d80:	00054f63          	bltz	a0,80005d9e <create+0x144>
    80005d84:	00492603          	lw	a2,4(s2)
    80005d88:	00003597          	auipc	a1,0x3
    80005d8c:	d5858593          	addi	a1,a1,-680 # 80008ae0 <syscalls+0x2d0>
    80005d90:	8526                	mv	a0,s1
    80005d92:	fffff097          	auipc	ra,0xfffff
    80005d96:	c8a080e7          	jalr	-886(ra) # 80004a1c <dirlink>
    80005d9a:	f80557e3          	bgez	a0,80005d28 <create+0xce>
      panic("create dots");
    80005d9e:	00003517          	auipc	a0,0x3
    80005da2:	d4a50513          	addi	a0,a0,-694 # 80008ae8 <syscalls+0x2d8>
    80005da6:	ffffa097          	auipc	ra,0xffffa
    80005daa:	798080e7          	jalr	1944(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005dae:	00003517          	auipc	a0,0x3
    80005db2:	d4a50513          	addi	a0,a0,-694 # 80008af8 <syscalls+0x2e8>
    80005db6:	ffffa097          	auipc	ra,0xffffa
    80005dba:	788080e7          	jalr	1928(ra) # 8000053e <panic>
    return 0;
    80005dbe:	84aa                	mv	s1,a0
    80005dc0:	b731                	j	80005ccc <create+0x72>

0000000080005dc2 <sys_dup>:
{
    80005dc2:	7179                	addi	sp,sp,-48
    80005dc4:	f406                	sd	ra,40(sp)
    80005dc6:	f022                	sd	s0,32(sp)
    80005dc8:	ec26                	sd	s1,24(sp)
    80005dca:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005dcc:	fd840613          	addi	a2,s0,-40
    80005dd0:	4581                	li	a1,0
    80005dd2:	4501                	li	a0,0
    80005dd4:	00000097          	auipc	ra,0x0
    80005dd8:	ddc080e7          	jalr	-548(ra) # 80005bb0 <argfd>
    return -1;
    80005ddc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005dde:	02054363          	bltz	a0,80005e04 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005de2:	fd843503          	ld	a0,-40(s0)
    80005de6:	00000097          	auipc	ra,0x0
    80005dea:	e32080e7          	jalr	-462(ra) # 80005c18 <fdalloc>
    80005dee:	84aa                	mv	s1,a0
    return -1;
    80005df0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005df2:	00054963          	bltz	a0,80005e04 <sys_dup+0x42>
  filedup(f);
    80005df6:	fd843503          	ld	a0,-40(s0)
    80005dfa:	fffff097          	auipc	ra,0xfffff
    80005dfe:	37a080e7          	jalr	890(ra) # 80005174 <filedup>
  return fd;
    80005e02:	87a6                	mv	a5,s1
}
    80005e04:	853e                	mv	a0,a5
    80005e06:	70a2                	ld	ra,40(sp)
    80005e08:	7402                	ld	s0,32(sp)
    80005e0a:	64e2                	ld	s1,24(sp)
    80005e0c:	6145                	addi	sp,sp,48
    80005e0e:	8082                	ret

0000000080005e10 <sys_read>:
{
    80005e10:	7179                	addi	sp,sp,-48
    80005e12:	f406                	sd	ra,40(sp)
    80005e14:	f022                	sd	s0,32(sp)
    80005e16:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e18:	fe840613          	addi	a2,s0,-24
    80005e1c:	4581                	li	a1,0
    80005e1e:	4501                	li	a0,0
    80005e20:	00000097          	auipc	ra,0x0
    80005e24:	d90080e7          	jalr	-624(ra) # 80005bb0 <argfd>
    return -1;
    80005e28:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e2a:	04054163          	bltz	a0,80005e6c <sys_read+0x5c>
    80005e2e:	fe440593          	addi	a1,s0,-28
    80005e32:	4509                	li	a0,2
    80005e34:	ffffe097          	auipc	ra,0xffffe
    80005e38:	906080e7          	jalr	-1786(ra) # 8000373a <argint>
    return -1;
    80005e3c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e3e:	02054763          	bltz	a0,80005e6c <sys_read+0x5c>
    80005e42:	fd840593          	addi	a1,s0,-40
    80005e46:	4505                	li	a0,1
    80005e48:	ffffe097          	auipc	ra,0xffffe
    80005e4c:	914080e7          	jalr	-1772(ra) # 8000375c <argaddr>
    return -1;
    80005e50:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e52:	00054d63          	bltz	a0,80005e6c <sys_read+0x5c>
  return fileread(f, p, n);
    80005e56:	fe442603          	lw	a2,-28(s0)
    80005e5a:	fd843583          	ld	a1,-40(s0)
    80005e5e:	fe843503          	ld	a0,-24(s0)
    80005e62:	fffff097          	auipc	ra,0xfffff
    80005e66:	49e080e7          	jalr	1182(ra) # 80005300 <fileread>
    80005e6a:	87aa                	mv	a5,a0
}
    80005e6c:	853e                	mv	a0,a5
    80005e6e:	70a2                	ld	ra,40(sp)
    80005e70:	7402                	ld	s0,32(sp)
    80005e72:	6145                	addi	sp,sp,48
    80005e74:	8082                	ret

0000000080005e76 <sys_write>:
{
    80005e76:	7179                	addi	sp,sp,-48
    80005e78:	f406                	sd	ra,40(sp)
    80005e7a:	f022                	sd	s0,32(sp)
    80005e7c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e7e:	fe840613          	addi	a2,s0,-24
    80005e82:	4581                	li	a1,0
    80005e84:	4501                	li	a0,0
    80005e86:	00000097          	auipc	ra,0x0
    80005e8a:	d2a080e7          	jalr	-726(ra) # 80005bb0 <argfd>
    return -1;
    80005e8e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e90:	04054163          	bltz	a0,80005ed2 <sys_write+0x5c>
    80005e94:	fe440593          	addi	a1,s0,-28
    80005e98:	4509                	li	a0,2
    80005e9a:	ffffe097          	auipc	ra,0xffffe
    80005e9e:	8a0080e7          	jalr	-1888(ra) # 8000373a <argint>
    return -1;
    80005ea2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ea4:	02054763          	bltz	a0,80005ed2 <sys_write+0x5c>
    80005ea8:	fd840593          	addi	a1,s0,-40
    80005eac:	4505                	li	a0,1
    80005eae:	ffffe097          	auipc	ra,0xffffe
    80005eb2:	8ae080e7          	jalr	-1874(ra) # 8000375c <argaddr>
    return -1;
    80005eb6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005eb8:	00054d63          	bltz	a0,80005ed2 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005ebc:	fe442603          	lw	a2,-28(s0)
    80005ec0:	fd843583          	ld	a1,-40(s0)
    80005ec4:	fe843503          	ld	a0,-24(s0)
    80005ec8:	fffff097          	auipc	ra,0xfffff
    80005ecc:	4fa080e7          	jalr	1274(ra) # 800053c2 <filewrite>
    80005ed0:	87aa                	mv	a5,a0
}
    80005ed2:	853e                	mv	a0,a5
    80005ed4:	70a2                	ld	ra,40(sp)
    80005ed6:	7402                	ld	s0,32(sp)
    80005ed8:	6145                	addi	sp,sp,48
    80005eda:	8082                	ret

0000000080005edc <sys_close>:
{
    80005edc:	1101                	addi	sp,sp,-32
    80005ede:	ec06                	sd	ra,24(sp)
    80005ee0:	e822                	sd	s0,16(sp)
    80005ee2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005ee4:	fe040613          	addi	a2,s0,-32
    80005ee8:	fec40593          	addi	a1,s0,-20
    80005eec:	4501                	li	a0,0
    80005eee:	00000097          	auipc	ra,0x0
    80005ef2:	cc2080e7          	jalr	-830(ra) # 80005bb0 <argfd>
    return -1;
    80005ef6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005ef8:	02054463          	bltz	a0,80005f20 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005efc:	ffffc097          	auipc	ra,0xffffc
    80005f00:	1d2080e7          	jalr	466(ra) # 800020ce <myproc>
    80005f04:	fec42783          	lw	a5,-20(s0)
    80005f08:	07e9                	addi	a5,a5,26
    80005f0a:	078e                	slli	a5,a5,0x3
    80005f0c:	97aa                	add	a5,a5,a0
    80005f0e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005f12:	fe043503          	ld	a0,-32(s0)
    80005f16:	fffff097          	auipc	ra,0xfffff
    80005f1a:	2b0080e7          	jalr	688(ra) # 800051c6 <fileclose>
  return 0;
    80005f1e:	4781                	li	a5,0
}
    80005f20:	853e                	mv	a0,a5
    80005f22:	60e2                	ld	ra,24(sp)
    80005f24:	6442                	ld	s0,16(sp)
    80005f26:	6105                	addi	sp,sp,32
    80005f28:	8082                	ret

0000000080005f2a <sys_fstat>:
{
    80005f2a:	1101                	addi	sp,sp,-32
    80005f2c:	ec06                	sd	ra,24(sp)
    80005f2e:	e822                	sd	s0,16(sp)
    80005f30:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f32:	fe840613          	addi	a2,s0,-24
    80005f36:	4581                	li	a1,0
    80005f38:	4501                	li	a0,0
    80005f3a:	00000097          	auipc	ra,0x0
    80005f3e:	c76080e7          	jalr	-906(ra) # 80005bb0 <argfd>
    return -1;
    80005f42:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f44:	02054563          	bltz	a0,80005f6e <sys_fstat+0x44>
    80005f48:	fe040593          	addi	a1,s0,-32
    80005f4c:	4505                	li	a0,1
    80005f4e:	ffffe097          	auipc	ra,0xffffe
    80005f52:	80e080e7          	jalr	-2034(ra) # 8000375c <argaddr>
    return -1;
    80005f56:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f58:	00054b63          	bltz	a0,80005f6e <sys_fstat+0x44>
  return filestat(f, st);
    80005f5c:	fe043583          	ld	a1,-32(s0)
    80005f60:	fe843503          	ld	a0,-24(s0)
    80005f64:	fffff097          	auipc	ra,0xfffff
    80005f68:	32a080e7          	jalr	810(ra) # 8000528e <filestat>
    80005f6c:	87aa                	mv	a5,a0
}
    80005f6e:	853e                	mv	a0,a5
    80005f70:	60e2                	ld	ra,24(sp)
    80005f72:	6442                	ld	s0,16(sp)
    80005f74:	6105                	addi	sp,sp,32
    80005f76:	8082                	ret

0000000080005f78 <sys_link>:
{
    80005f78:	7169                	addi	sp,sp,-304
    80005f7a:	f606                	sd	ra,296(sp)
    80005f7c:	f222                	sd	s0,288(sp)
    80005f7e:	ee26                	sd	s1,280(sp)
    80005f80:	ea4a                	sd	s2,272(sp)
    80005f82:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f84:	08000613          	li	a2,128
    80005f88:	ed040593          	addi	a1,s0,-304
    80005f8c:	4501                	li	a0,0
    80005f8e:	ffffd097          	auipc	ra,0xffffd
    80005f92:	7f0080e7          	jalr	2032(ra) # 8000377e <argstr>
    return -1;
    80005f96:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f98:	10054e63          	bltz	a0,800060b4 <sys_link+0x13c>
    80005f9c:	08000613          	li	a2,128
    80005fa0:	f5040593          	addi	a1,s0,-176
    80005fa4:	4505                	li	a0,1
    80005fa6:	ffffd097          	auipc	ra,0xffffd
    80005faa:	7d8080e7          	jalr	2008(ra) # 8000377e <argstr>
    return -1;
    80005fae:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005fb0:	10054263          	bltz	a0,800060b4 <sys_link+0x13c>
  begin_op();
    80005fb4:	fffff097          	auipc	ra,0xfffff
    80005fb8:	d46080e7          	jalr	-698(ra) # 80004cfa <begin_op>
  if((ip = namei(old)) == 0){
    80005fbc:	ed040513          	addi	a0,s0,-304
    80005fc0:	fffff097          	auipc	ra,0xfffff
    80005fc4:	b1e080e7          	jalr	-1250(ra) # 80004ade <namei>
    80005fc8:	84aa                	mv	s1,a0
    80005fca:	c551                	beqz	a0,80006056 <sys_link+0xde>
  ilock(ip);
    80005fcc:	ffffe097          	auipc	ra,0xffffe
    80005fd0:	35c080e7          	jalr	860(ra) # 80004328 <ilock>
  if(ip->type == T_DIR){
    80005fd4:	04449703          	lh	a4,68(s1)
    80005fd8:	4785                	li	a5,1
    80005fda:	08f70463          	beq	a4,a5,80006062 <sys_link+0xea>
  ip->nlink++;
    80005fde:	04a4d783          	lhu	a5,74(s1)
    80005fe2:	2785                	addiw	a5,a5,1
    80005fe4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005fe8:	8526                	mv	a0,s1
    80005fea:	ffffe097          	auipc	ra,0xffffe
    80005fee:	274080e7          	jalr	628(ra) # 8000425e <iupdate>
  iunlock(ip);
    80005ff2:	8526                	mv	a0,s1
    80005ff4:	ffffe097          	auipc	ra,0xffffe
    80005ff8:	3f6080e7          	jalr	1014(ra) # 800043ea <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005ffc:	fd040593          	addi	a1,s0,-48
    80006000:	f5040513          	addi	a0,s0,-176
    80006004:	fffff097          	auipc	ra,0xfffff
    80006008:	af8080e7          	jalr	-1288(ra) # 80004afc <nameiparent>
    8000600c:	892a                	mv	s2,a0
    8000600e:	c935                	beqz	a0,80006082 <sys_link+0x10a>
  ilock(dp);
    80006010:	ffffe097          	auipc	ra,0xffffe
    80006014:	318080e7          	jalr	792(ra) # 80004328 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006018:	00092703          	lw	a4,0(s2)
    8000601c:	409c                	lw	a5,0(s1)
    8000601e:	04f71d63          	bne	a4,a5,80006078 <sys_link+0x100>
    80006022:	40d0                	lw	a2,4(s1)
    80006024:	fd040593          	addi	a1,s0,-48
    80006028:	854a                	mv	a0,s2
    8000602a:	fffff097          	auipc	ra,0xfffff
    8000602e:	9f2080e7          	jalr	-1550(ra) # 80004a1c <dirlink>
    80006032:	04054363          	bltz	a0,80006078 <sys_link+0x100>
  iunlockput(dp);
    80006036:	854a                	mv	a0,s2
    80006038:	ffffe097          	auipc	ra,0xffffe
    8000603c:	552080e7          	jalr	1362(ra) # 8000458a <iunlockput>
  iput(ip);
    80006040:	8526                	mv	a0,s1
    80006042:	ffffe097          	auipc	ra,0xffffe
    80006046:	4a0080e7          	jalr	1184(ra) # 800044e2 <iput>
  end_op();
    8000604a:	fffff097          	auipc	ra,0xfffff
    8000604e:	d30080e7          	jalr	-720(ra) # 80004d7a <end_op>
  return 0;
    80006052:	4781                	li	a5,0
    80006054:	a085                	j	800060b4 <sys_link+0x13c>
    end_op();
    80006056:	fffff097          	auipc	ra,0xfffff
    8000605a:	d24080e7          	jalr	-732(ra) # 80004d7a <end_op>
    return -1;
    8000605e:	57fd                	li	a5,-1
    80006060:	a891                	j	800060b4 <sys_link+0x13c>
    iunlockput(ip);
    80006062:	8526                	mv	a0,s1
    80006064:	ffffe097          	auipc	ra,0xffffe
    80006068:	526080e7          	jalr	1318(ra) # 8000458a <iunlockput>
    end_op();
    8000606c:	fffff097          	auipc	ra,0xfffff
    80006070:	d0e080e7          	jalr	-754(ra) # 80004d7a <end_op>
    return -1;
    80006074:	57fd                	li	a5,-1
    80006076:	a83d                	j	800060b4 <sys_link+0x13c>
    iunlockput(dp);
    80006078:	854a                	mv	a0,s2
    8000607a:	ffffe097          	auipc	ra,0xffffe
    8000607e:	510080e7          	jalr	1296(ra) # 8000458a <iunlockput>
  ilock(ip);
    80006082:	8526                	mv	a0,s1
    80006084:	ffffe097          	auipc	ra,0xffffe
    80006088:	2a4080e7          	jalr	676(ra) # 80004328 <ilock>
  ip->nlink--;
    8000608c:	04a4d783          	lhu	a5,74(s1)
    80006090:	37fd                	addiw	a5,a5,-1
    80006092:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006096:	8526                	mv	a0,s1
    80006098:	ffffe097          	auipc	ra,0xffffe
    8000609c:	1c6080e7          	jalr	454(ra) # 8000425e <iupdate>
  iunlockput(ip);
    800060a0:	8526                	mv	a0,s1
    800060a2:	ffffe097          	auipc	ra,0xffffe
    800060a6:	4e8080e7          	jalr	1256(ra) # 8000458a <iunlockput>
  end_op();
    800060aa:	fffff097          	auipc	ra,0xfffff
    800060ae:	cd0080e7          	jalr	-816(ra) # 80004d7a <end_op>
  return -1;
    800060b2:	57fd                	li	a5,-1
}
    800060b4:	853e                	mv	a0,a5
    800060b6:	70b2                	ld	ra,296(sp)
    800060b8:	7412                	ld	s0,288(sp)
    800060ba:	64f2                	ld	s1,280(sp)
    800060bc:	6952                	ld	s2,272(sp)
    800060be:	6155                	addi	sp,sp,304
    800060c0:	8082                	ret

00000000800060c2 <sys_unlink>:
{
    800060c2:	7151                	addi	sp,sp,-240
    800060c4:	f586                	sd	ra,232(sp)
    800060c6:	f1a2                	sd	s0,224(sp)
    800060c8:	eda6                	sd	s1,216(sp)
    800060ca:	e9ca                	sd	s2,208(sp)
    800060cc:	e5ce                	sd	s3,200(sp)
    800060ce:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800060d0:	08000613          	li	a2,128
    800060d4:	f3040593          	addi	a1,s0,-208
    800060d8:	4501                	li	a0,0
    800060da:	ffffd097          	auipc	ra,0xffffd
    800060de:	6a4080e7          	jalr	1700(ra) # 8000377e <argstr>
    800060e2:	18054163          	bltz	a0,80006264 <sys_unlink+0x1a2>
  begin_op();
    800060e6:	fffff097          	auipc	ra,0xfffff
    800060ea:	c14080e7          	jalr	-1004(ra) # 80004cfa <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800060ee:	fb040593          	addi	a1,s0,-80
    800060f2:	f3040513          	addi	a0,s0,-208
    800060f6:	fffff097          	auipc	ra,0xfffff
    800060fa:	a06080e7          	jalr	-1530(ra) # 80004afc <nameiparent>
    800060fe:	84aa                	mv	s1,a0
    80006100:	c979                	beqz	a0,800061d6 <sys_unlink+0x114>
  ilock(dp);
    80006102:	ffffe097          	auipc	ra,0xffffe
    80006106:	226080e7          	jalr	550(ra) # 80004328 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000610a:	00003597          	auipc	a1,0x3
    8000610e:	9ce58593          	addi	a1,a1,-1586 # 80008ad8 <syscalls+0x2c8>
    80006112:	fb040513          	addi	a0,s0,-80
    80006116:	ffffe097          	auipc	ra,0xffffe
    8000611a:	6dc080e7          	jalr	1756(ra) # 800047f2 <namecmp>
    8000611e:	14050a63          	beqz	a0,80006272 <sys_unlink+0x1b0>
    80006122:	00003597          	auipc	a1,0x3
    80006126:	9be58593          	addi	a1,a1,-1602 # 80008ae0 <syscalls+0x2d0>
    8000612a:	fb040513          	addi	a0,s0,-80
    8000612e:	ffffe097          	auipc	ra,0xffffe
    80006132:	6c4080e7          	jalr	1732(ra) # 800047f2 <namecmp>
    80006136:	12050e63          	beqz	a0,80006272 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000613a:	f2c40613          	addi	a2,s0,-212
    8000613e:	fb040593          	addi	a1,s0,-80
    80006142:	8526                	mv	a0,s1
    80006144:	ffffe097          	auipc	ra,0xffffe
    80006148:	6c8080e7          	jalr	1736(ra) # 8000480c <dirlookup>
    8000614c:	892a                	mv	s2,a0
    8000614e:	12050263          	beqz	a0,80006272 <sys_unlink+0x1b0>
  ilock(ip);
    80006152:	ffffe097          	auipc	ra,0xffffe
    80006156:	1d6080e7          	jalr	470(ra) # 80004328 <ilock>
  if(ip->nlink < 1)
    8000615a:	04a91783          	lh	a5,74(s2)
    8000615e:	08f05263          	blez	a5,800061e2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006162:	04491703          	lh	a4,68(s2)
    80006166:	4785                	li	a5,1
    80006168:	08f70563          	beq	a4,a5,800061f2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000616c:	4641                	li	a2,16
    8000616e:	4581                	li	a1,0
    80006170:	fc040513          	addi	a0,s0,-64
    80006174:	ffffb097          	auipc	ra,0xffffb
    80006178:	b6c080e7          	jalr	-1172(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000617c:	4741                	li	a4,16
    8000617e:	f2c42683          	lw	a3,-212(s0)
    80006182:	fc040613          	addi	a2,s0,-64
    80006186:	4581                	li	a1,0
    80006188:	8526                	mv	a0,s1
    8000618a:	ffffe097          	auipc	ra,0xffffe
    8000618e:	54a080e7          	jalr	1354(ra) # 800046d4 <writei>
    80006192:	47c1                	li	a5,16
    80006194:	0af51563          	bne	a0,a5,8000623e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006198:	04491703          	lh	a4,68(s2)
    8000619c:	4785                	li	a5,1
    8000619e:	0af70863          	beq	a4,a5,8000624e <sys_unlink+0x18c>
  iunlockput(dp);
    800061a2:	8526                	mv	a0,s1
    800061a4:	ffffe097          	auipc	ra,0xffffe
    800061a8:	3e6080e7          	jalr	998(ra) # 8000458a <iunlockput>
  ip->nlink--;
    800061ac:	04a95783          	lhu	a5,74(s2)
    800061b0:	37fd                	addiw	a5,a5,-1
    800061b2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800061b6:	854a                	mv	a0,s2
    800061b8:	ffffe097          	auipc	ra,0xffffe
    800061bc:	0a6080e7          	jalr	166(ra) # 8000425e <iupdate>
  iunlockput(ip);
    800061c0:	854a                	mv	a0,s2
    800061c2:	ffffe097          	auipc	ra,0xffffe
    800061c6:	3c8080e7          	jalr	968(ra) # 8000458a <iunlockput>
  end_op();
    800061ca:	fffff097          	auipc	ra,0xfffff
    800061ce:	bb0080e7          	jalr	-1104(ra) # 80004d7a <end_op>
  return 0;
    800061d2:	4501                	li	a0,0
    800061d4:	a84d                	j	80006286 <sys_unlink+0x1c4>
    end_op();
    800061d6:	fffff097          	auipc	ra,0xfffff
    800061da:	ba4080e7          	jalr	-1116(ra) # 80004d7a <end_op>
    return -1;
    800061de:	557d                	li	a0,-1
    800061e0:	a05d                	j	80006286 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800061e2:	00003517          	auipc	a0,0x3
    800061e6:	92650513          	addi	a0,a0,-1754 # 80008b08 <syscalls+0x2f8>
    800061ea:	ffffa097          	auipc	ra,0xffffa
    800061ee:	354080e7          	jalr	852(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061f2:	04c92703          	lw	a4,76(s2)
    800061f6:	02000793          	li	a5,32
    800061fa:	f6e7f9e3          	bgeu	a5,a4,8000616c <sys_unlink+0xaa>
    800061fe:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006202:	4741                	li	a4,16
    80006204:	86ce                	mv	a3,s3
    80006206:	f1840613          	addi	a2,s0,-232
    8000620a:	4581                	li	a1,0
    8000620c:	854a                	mv	a0,s2
    8000620e:	ffffe097          	auipc	ra,0xffffe
    80006212:	3ce080e7          	jalr	974(ra) # 800045dc <readi>
    80006216:	47c1                	li	a5,16
    80006218:	00f51b63          	bne	a0,a5,8000622e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000621c:	f1845783          	lhu	a5,-232(s0)
    80006220:	e7a1                	bnez	a5,80006268 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006222:	29c1                	addiw	s3,s3,16
    80006224:	04c92783          	lw	a5,76(s2)
    80006228:	fcf9ede3          	bltu	s3,a5,80006202 <sys_unlink+0x140>
    8000622c:	b781                	j	8000616c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000622e:	00003517          	auipc	a0,0x3
    80006232:	8f250513          	addi	a0,a0,-1806 # 80008b20 <syscalls+0x310>
    80006236:	ffffa097          	auipc	ra,0xffffa
    8000623a:	308080e7          	jalr	776(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000623e:	00003517          	auipc	a0,0x3
    80006242:	8fa50513          	addi	a0,a0,-1798 # 80008b38 <syscalls+0x328>
    80006246:	ffffa097          	auipc	ra,0xffffa
    8000624a:	2f8080e7          	jalr	760(ra) # 8000053e <panic>
    dp->nlink--;
    8000624e:	04a4d783          	lhu	a5,74(s1)
    80006252:	37fd                	addiw	a5,a5,-1
    80006254:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006258:	8526                	mv	a0,s1
    8000625a:	ffffe097          	auipc	ra,0xffffe
    8000625e:	004080e7          	jalr	4(ra) # 8000425e <iupdate>
    80006262:	b781                	j	800061a2 <sys_unlink+0xe0>
    return -1;
    80006264:	557d                	li	a0,-1
    80006266:	a005                	j	80006286 <sys_unlink+0x1c4>
    iunlockput(ip);
    80006268:	854a                	mv	a0,s2
    8000626a:	ffffe097          	auipc	ra,0xffffe
    8000626e:	320080e7          	jalr	800(ra) # 8000458a <iunlockput>
  iunlockput(dp);
    80006272:	8526                	mv	a0,s1
    80006274:	ffffe097          	auipc	ra,0xffffe
    80006278:	316080e7          	jalr	790(ra) # 8000458a <iunlockput>
  end_op();
    8000627c:	fffff097          	auipc	ra,0xfffff
    80006280:	afe080e7          	jalr	-1282(ra) # 80004d7a <end_op>
  return -1;
    80006284:	557d                	li	a0,-1
}
    80006286:	70ae                	ld	ra,232(sp)
    80006288:	740e                	ld	s0,224(sp)
    8000628a:	64ee                	ld	s1,216(sp)
    8000628c:	694e                	ld	s2,208(sp)
    8000628e:	69ae                	ld	s3,200(sp)
    80006290:	616d                	addi	sp,sp,240
    80006292:	8082                	ret

0000000080006294 <sys_open>:

uint64
sys_open(void)
{
    80006294:	7131                	addi	sp,sp,-192
    80006296:	fd06                	sd	ra,184(sp)
    80006298:	f922                	sd	s0,176(sp)
    8000629a:	f526                	sd	s1,168(sp)
    8000629c:	f14a                	sd	s2,160(sp)
    8000629e:	ed4e                	sd	s3,152(sp)
    800062a0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800062a2:	08000613          	li	a2,128
    800062a6:	f5040593          	addi	a1,s0,-176
    800062aa:	4501                	li	a0,0
    800062ac:	ffffd097          	auipc	ra,0xffffd
    800062b0:	4d2080e7          	jalr	1234(ra) # 8000377e <argstr>
    return -1;
    800062b4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800062b6:	0c054163          	bltz	a0,80006378 <sys_open+0xe4>
    800062ba:	f4c40593          	addi	a1,s0,-180
    800062be:	4505                	li	a0,1
    800062c0:	ffffd097          	auipc	ra,0xffffd
    800062c4:	47a080e7          	jalr	1146(ra) # 8000373a <argint>
    800062c8:	0a054863          	bltz	a0,80006378 <sys_open+0xe4>

  begin_op();
    800062cc:	fffff097          	auipc	ra,0xfffff
    800062d0:	a2e080e7          	jalr	-1490(ra) # 80004cfa <begin_op>

  if(omode & O_CREATE){
    800062d4:	f4c42783          	lw	a5,-180(s0)
    800062d8:	2007f793          	andi	a5,a5,512
    800062dc:	cbdd                	beqz	a5,80006392 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800062de:	4681                	li	a3,0
    800062e0:	4601                	li	a2,0
    800062e2:	4589                	li	a1,2
    800062e4:	f5040513          	addi	a0,s0,-176
    800062e8:	00000097          	auipc	ra,0x0
    800062ec:	972080e7          	jalr	-1678(ra) # 80005c5a <create>
    800062f0:	892a                	mv	s2,a0
    if(ip == 0){
    800062f2:	c959                	beqz	a0,80006388 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800062f4:	04491703          	lh	a4,68(s2)
    800062f8:	478d                	li	a5,3
    800062fa:	00f71763          	bne	a4,a5,80006308 <sys_open+0x74>
    800062fe:	04695703          	lhu	a4,70(s2)
    80006302:	47a5                	li	a5,9
    80006304:	0ce7ec63          	bltu	a5,a4,800063dc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006308:	fffff097          	auipc	ra,0xfffff
    8000630c:	e02080e7          	jalr	-510(ra) # 8000510a <filealloc>
    80006310:	89aa                	mv	s3,a0
    80006312:	10050263          	beqz	a0,80006416 <sys_open+0x182>
    80006316:	00000097          	auipc	ra,0x0
    8000631a:	902080e7          	jalr	-1790(ra) # 80005c18 <fdalloc>
    8000631e:	84aa                	mv	s1,a0
    80006320:	0e054663          	bltz	a0,8000640c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006324:	04491703          	lh	a4,68(s2)
    80006328:	478d                	li	a5,3
    8000632a:	0cf70463          	beq	a4,a5,800063f2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000632e:	4789                	li	a5,2
    80006330:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006334:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006338:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000633c:	f4c42783          	lw	a5,-180(s0)
    80006340:	0017c713          	xori	a4,a5,1
    80006344:	8b05                	andi	a4,a4,1
    80006346:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000634a:	0037f713          	andi	a4,a5,3
    8000634e:	00e03733          	snez	a4,a4
    80006352:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006356:	4007f793          	andi	a5,a5,1024
    8000635a:	c791                	beqz	a5,80006366 <sys_open+0xd2>
    8000635c:	04491703          	lh	a4,68(s2)
    80006360:	4789                	li	a5,2
    80006362:	08f70f63          	beq	a4,a5,80006400 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006366:	854a                	mv	a0,s2
    80006368:	ffffe097          	auipc	ra,0xffffe
    8000636c:	082080e7          	jalr	130(ra) # 800043ea <iunlock>
  end_op();
    80006370:	fffff097          	auipc	ra,0xfffff
    80006374:	a0a080e7          	jalr	-1526(ra) # 80004d7a <end_op>

  return fd;
}
    80006378:	8526                	mv	a0,s1
    8000637a:	70ea                	ld	ra,184(sp)
    8000637c:	744a                	ld	s0,176(sp)
    8000637e:	74aa                	ld	s1,168(sp)
    80006380:	790a                	ld	s2,160(sp)
    80006382:	69ea                	ld	s3,152(sp)
    80006384:	6129                	addi	sp,sp,192
    80006386:	8082                	ret
      end_op();
    80006388:	fffff097          	auipc	ra,0xfffff
    8000638c:	9f2080e7          	jalr	-1550(ra) # 80004d7a <end_op>
      return -1;
    80006390:	b7e5                	j	80006378 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006392:	f5040513          	addi	a0,s0,-176
    80006396:	ffffe097          	auipc	ra,0xffffe
    8000639a:	748080e7          	jalr	1864(ra) # 80004ade <namei>
    8000639e:	892a                	mv	s2,a0
    800063a0:	c905                	beqz	a0,800063d0 <sys_open+0x13c>
    ilock(ip);
    800063a2:	ffffe097          	auipc	ra,0xffffe
    800063a6:	f86080e7          	jalr	-122(ra) # 80004328 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800063aa:	04491703          	lh	a4,68(s2)
    800063ae:	4785                	li	a5,1
    800063b0:	f4f712e3          	bne	a4,a5,800062f4 <sys_open+0x60>
    800063b4:	f4c42783          	lw	a5,-180(s0)
    800063b8:	dba1                	beqz	a5,80006308 <sys_open+0x74>
      iunlockput(ip);
    800063ba:	854a                	mv	a0,s2
    800063bc:	ffffe097          	auipc	ra,0xffffe
    800063c0:	1ce080e7          	jalr	462(ra) # 8000458a <iunlockput>
      end_op();
    800063c4:	fffff097          	auipc	ra,0xfffff
    800063c8:	9b6080e7          	jalr	-1610(ra) # 80004d7a <end_op>
      return -1;
    800063cc:	54fd                	li	s1,-1
    800063ce:	b76d                	j	80006378 <sys_open+0xe4>
      end_op();
    800063d0:	fffff097          	auipc	ra,0xfffff
    800063d4:	9aa080e7          	jalr	-1622(ra) # 80004d7a <end_op>
      return -1;
    800063d8:	54fd                	li	s1,-1
    800063da:	bf79                	j	80006378 <sys_open+0xe4>
    iunlockput(ip);
    800063dc:	854a                	mv	a0,s2
    800063de:	ffffe097          	auipc	ra,0xffffe
    800063e2:	1ac080e7          	jalr	428(ra) # 8000458a <iunlockput>
    end_op();
    800063e6:	fffff097          	auipc	ra,0xfffff
    800063ea:	994080e7          	jalr	-1644(ra) # 80004d7a <end_op>
    return -1;
    800063ee:	54fd                	li	s1,-1
    800063f0:	b761                	j	80006378 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800063f2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800063f6:	04691783          	lh	a5,70(s2)
    800063fa:	02f99223          	sh	a5,36(s3)
    800063fe:	bf2d                	j	80006338 <sys_open+0xa4>
    itrunc(ip);
    80006400:	854a                	mv	a0,s2
    80006402:	ffffe097          	auipc	ra,0xffffe
    80006406:	034080e7          	jalr	52(ra) # 80004436 <itrunc>
    8000640a:	bfb1                	j	80006366 <sys_open+0xd2>
      fileclose(f);
    8000640c:	854e                	mv	a0,s3
    8000640e:	fffff097          	auipc	ra,0xfffff
    80006412:	db8080e7          	jalr	-584(ra) # 800051c6 <fileclose>
    iunlockput(ip);
    80006416:	854a                	mv	a0,s2
    80006418:	ffffe097          	auipc	ra,0xffffe
    8000641c:	172080e7          	jalr	370(ra) # 8000458a <iunlockput>
    end_op();
    80006420:	fffff097          	auipc	ra,0xfffff
    80006424:	95a080e7          	jalr	-1702(ra) # 80004d7a <end_op>
    return -1;
    80006428:	54fd                	li	s1,-1
    8000642a:	b7b9                	j	80006378 <sys_open+0xe4>

000000008000642c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000642c:	7175                	addi	sp,sp,-144
    8000642e:	e506                	sd	ra,136(sp)
    80006430:	e122                	sd	s0,128(sp)
    80006432:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006434:	fffff097          	auipc	ra,0xfffff
    80006438:	8c6080e7          	jalr	-1850(ra) # 80004cfa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000643c:	08000613          	li	a2,128
    80006440:	f7040593          	addi	a1,s0,-144
    80006444:	4501                	li	a0,0
    80006446:	ffffd097          	auipc	ra,0xffffd
    8000644a:	338080e7          	jalr	824(ra) # 8000377e <argstr>
    8000644e:	02054963          	bltz	a0,80006480 <sys_mkdir+0x54>
    80006452:	4681                	li	a3,0
    80006454:	4601                	li	a2,0
    80006456:	4585                	li	a1,1
    80006458:	f7040513          	addi	a0,s0,-144
    8000645c:	fffff097          	auipc	ra,0xfffff
    80006460:	7fe080e7          	jalr	2046(ra) # 80005c5a <create>
    80006464:	cd11                	beqz	a0,80006480 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006466:	ffffe097          	auipc	ra,0xffffe
    8000646a:	124080e7          	jalr	292(ra) # 8000458a <iunlockput>
  end_op();
    8000646e:	fffff097          	auipc	ra,0xfffff
    80006472:	90c080e7          	jalr	-1780(ra) # 80004d7a <end_op>
  return 0;
    80006476:	4501                	li	a0,0
}
    80006478:	60aa                	ld	ra,136(sp)
    8000647a:	640a                	ld	s0,128(sp)
    8000647c:	6149                	addi	sp,sp,144
    8000647e:	8082                	ret
    end_op();
    80006480:	fffff097          	auipc	ra,0xfffff
    80006484:	8fa080e7          	jalr	-1798(ra) # 80004d7a <end_op>
    return -1;
    80006488:	557d                	li	a0,-1
    8000648a:	b7fd                	j	80006478 <sys_mkdir+0x4c>

000000008000648c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000648c:	7135                	addi	sp,sp,-160
    8000648e:	ed06                	sd	ra,152(sp)
    80006490:	e922                	sd	s0,144(sp)
    80006492:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006494:	fffff097          	auipc	ra,0xfffff
    80006498:	866080e7          	jalr	-1946(ra) # 80004cfa <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000649c:	08000613          	li	a2,128
    800064a0:	f7040593          	addi	a1,s0,-144
    800064a4:	4501                	li	a0,0
    800064a6:	ffffd097          	auipc	ra,0xffffd
    800064aa:	2d8080e7          	jalr	728(ra) # 8000377e <argstr>
    800064ae:	04054a63          	bltz	a0,80006502 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800064b2:	f6c40593          	addi	a1,s0,-148
    800064b6:	4505                	li	a0,1
    800064b8:	ffffd097          	auipc	ra,0xffffd
    800064bc:	282080e7          	jalr	642(ra) # 8000373a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800064c0:	04054163          	bltz	a0,80006502 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800064c4:	f6840593          	addi	a1,s0,-152
    800064c8:	4509                	li	a0,2
    800064ca:	ffffd097          	auipc	ra,0xffffd
    800064ce:	270080e7          	jalr	624(ra) # 8000373a <argint>
     argint(1, &major) < 0 ||
    800064d2:	02054863          	bltz	a0,80006502 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800064d6:	f6841683          	lh	a3,-152(s0)
    800064da:	f6c41603          	lh	a2,-148(s0)
    800064de:	458d                	li	a1,3
    800064e0:	f7040513          	addi	a0,s0,-144
    800064e4:	fffff097          	auipc	ra,0xfffff
    800064e8:	776080e7          	jalr	1910(ra) # 80005c5a <create>
     argint(2, &minor) < 0 ||
    800064ec:	c919                	beqz	a0,80006502 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800064ee:	ffffe097          	auipc	ra,0xffffe
    800064f2:	09c080e7          	jalr	156(ra) # 8000458a <iunlockput>
  end_op();
    800064f6:	fffff097          	auipc	ra,0xfffff
    800064fa:	884080e7          	jalr	-1916(ra) # 80004d7a <end_op>
  return 0;
    800064fe:	4501                	li	a0,0
    80006500:	a031                	j	8000650c <sys_mknod+0x80>
    end_op();
    80006502:	fffff097          	auipc	ra,0xfffff
    80006506:	878080e7          	jalr	-1928(ra) # 80004d7a <end_op>
    return -1;
    8000650a:	557d                	li	a0,-1
}
    8000650c:	60ea                	ld	ra,152(sp)
    8000650e:	644a                	ld	s0,144(sp)
    80006510:	610d                	addi	sp,sp,160
    80006512:	8082                	ret

0000000080006514 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006514:	7135                	addi	sp,sp,-160
    80006516:	ed06                	sd	ra,152(sp)
    80006518:	e922                	sd	s0,144(sp)
    8000651a:	e526                	sd	s1,136(sp)
    8000651c:	e14a                	sd	s2,128(sp)
    8000651e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006520:	ffffc097          	auipc	ra,0xffffc
    80006524:	bae080e7          	jalr	-1106(ra) # 800020ce <myproc>
    80006528:	892a                	mv	s2,a0
  
  begin_op();
    8000652a:	ffffe097          	auipc	ra,0xffffe
    8000652e:	7d0080e7          	jalr	2000(ra) # 80004cfa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006532:	08000613          	li	a2,128
    80006536:	f6040593          	addi	a1,s0,-160
    8000653a:	4501                	li	a0,0
    8000653c:	ffffd097          	auipc	ra,0xffffd
    80006540:	242080e7          	jalr	578(ra) # 8000377e <argstr>
    80006544:	04054b63          	bltz	a0,8000659a <sys_chdir+0x86>
    80006548:	f6040513          	addi	a0,s0,-160
    8000654c:	ffffe097          	auipc	ra,0xffffe
    80006550:	592080e7          	jalr	1426(ra) # 80004ade <namei>
    80006554:	84aa                	mv	s1,a0
    80006556:	c131                	beqz	a0,8000659a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006558:	ffffe097          	auipc	ra,0xffffe
    8000655c:	dd0080e7          	jalr	-560(ra) # 80004328 <ilock>
  if(ip->type != T_DIR){
    80006560:	04449703          	lh	a4,68(s1)
    80006564:	4785                	li	a5,1
    80006566:	04f71063          	bne	a4,a5,800065a6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000656a:	8526                	mv	a0,s1
    8000656c:	ffffe097          	auipc	ra,0xffffe
    80006570:	e7e080e7          	jalr	-386(ra) # 800043ea <iunlock>
  iput(p->cwd);
    80006574:	15093503          	ld	a0,336(s2)
    80006578:	ffffe097          	auipc	ra,0xffffe
    8000657c:	f6a080e7          	jalr	-150(ra) # 800044e2 <iput>
  end_op();
    80006580:	ffffe097          	auipc	ra,0xffffe
    80006584:	7fa080e7          	jalr	2042(ra) # 80004d7a <end_op>
  p->cwd = ip;
    80006588:	14993823          	sd	s1,336(s2)
  return 0;
    8000658c:	4501                	li	a0,0
}
    8000658e:	60ea                	ld	ra,152(sp)
    80006590:	644a                	ld	s0,144(sp)
    80006592:	64aa                	ld	s1,136(sp)
    80006594:	690a                	ld	s2,128(sp)
    80006596:	610d                	addi	sp,sp,160
    80006598:	8082                	ret
    end_op();
    8000659a:	ffffe097          	auipc	ra,0xffffe
    8000659e:	7e0080e7          	jalr	2016(ra) # 80004d7a <end_op>
    return -1;
    800065a2:	557d                	li	a0,-1
    800065a4:	b7ed                	j	8000658e <sys_chdir+0x7a>
    iunlockput(ip);
    800065a6:	8526                	mv	a0,s1
    800065a8:	ffffe097          	auipc	ra,0xffffe
    800065ac:	fe2080e7          	jalr	-30(ra) # 8000458a <iunlockput>
    end_op();
    800065b0:	ffffe097          	auipc	ra,0xffffe
    800065b4:	7ca080e7          	jalr	1994(ra) # 80004d7a <end_op>
    return -1;
    800065b8:	557d                	li	a0,-1
    800065ba:	bfd1                	j	8000658e <sys_chdir+0x7a>

00000000800065bc <sys_exec>:

uint64
sys_exec(void)
{
    800065bc:	7145                	addi	sp,sp,-464
    800065be:	e786                	sd	ra,456(sp)
    800065c0:	e3a2                	sd	s0,448(sp)
    800065c2:	ff26                	sd	s1,440(sp)
    800065c4:	fb4a                	sd	s2,432(sp)
    800065c6:	f74e                	sd	s3,424(sp)
    800065c8:	f352                	sd	s4,416(sp)
    800065ca:	ef56                	sd	s5,408(sp)
    800065cc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800065ce:	08000613          	li	a2,128
    800065d2:	f4040593          	addi	a1,s0,-192
    800065d6:	4501                	li	a0,0
    800065d8:	ffffd097          	auipc	ra,0xffffd
    800065dc:	1a6080e7          	jalr	422(ra) # 8000377e <argstr>
    return -1;
    800065e0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800065e2:	0c054a63          	bltz	a0,800066b6 <sys_exec+0xfa>
    800065e6:	e3840593          	addi	a1,s0,-456
    800065ea:	4505                	li	a0,1
    800065ec:	ffffd097          	auipc	ra,0xffffd
    800065f0:	170080e7          	jalr	368(ra) # 8000375c <argaddr>
    800065f4:	0c054163          	bltz	a0,800066b6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800065f8:	10000613          	li	a2,256
    800065fc:	4581                	li	a1,0
    800065fe:	e4040513          	addi	a0,s0,-448
    80006602:	ffffa097          	auipc	ra,0xffffa
    80006606:	6de080e7          	jalr	1758(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000660a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000660e:	89a6                	mv	s3,s1
    80006610:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006612:	02000a13          	li	s4,32
    80006616:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000661a:	00391513          	slli	a0,s2,0x3
    8000661e:	e3040593          	addi	a1,s0,-464
    80006622:	e3843783          	ld	a5,-456(s0)
    80006626:	953e                	add	a0,a0,a5
    80006628:	ffffd097          	auipc	ra,0xffffd
    8000662c:	078080e7          	jalr	120(ra) # 800036a0 <fetchaddr>
    80006630:	02054a63          	bltz	a0,80006664 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006634:	e3043783          	ld	a5,-464(s0)
    80006638:	c3b9                	beqz	a5,8000667e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000663a:	ffffa097          	auipc	ra,0xffffa
    8000663e:	4ba080e7          	jalr	1210(ra) # 80000af4 <kalloc>
    80006642:	85aa                	mv	a1,a0
    80006644:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006648:	cd11                	beqz	a0,80006664 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000664a:	6605                	lui	a2,0x1
    8000664c:	e3043503          	ld	a0,-464(s0)
    80006650:	ffffd097          	auipc	ra,0xffffd
    80006654:	0a2080e7          	jalr	162(ra) # 800036f2 <fetchstr>
    80006658:	00054663          	bltz	a0,80006664 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000665c:	0905                	addi	s2,s2,1
    8000665e:	09a1                	addi	s3,s3,8
    80006660:	fb491be3          	bne	s2,s4,80006616 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006664:	10048913          	addi	s2,s1,256
    80006668:	6088                	ld	a0,0(s1)
    8000666a:	c529                	beqz	a0,800066b4 <sys_exec+0xf8>
    kfree(argv[i]);
    8000666c:	ffffa097          	auipc	ra,0xffffa
    80006670:	38c080e7          	jalr	908(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006674:	04a1                	addi	s1,s1,8
    80006676:	ff2499e3          	bne	s1,s2,80006668 <sys_exec+0xac>
  return -1;
    8000667a:	597d                	li	s2,-1
    8000667c:	a82d                	j	800066b6 <sys_exec+0xfa>
      argv[i] = 0;
    8000667e:	0a8e                	slli	s5,s5,0x3
    80006680:	fc040793          	addi	a5,s0,-64
    80006684:	9abe                	add	s5,s5,a5
    80006686:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000668a:	e4040593          	addi	a1,s0,-448
    8000668e:	f4040513          	addi	a0,s0,-192
    80006692:	fffff097          	auipc	ra,0xfffff
    80006696:	194080e7          	jalr	404(ra) # 80005826 <exec>
    8000669a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000669c:	10048993          	addi	s3,s1,256
    800066a0:	6088                	ld	a0,0(s1)
    800066a2:	c911                	beqz	a0,800066b6 <sys_exec+0xfa>
    kfree(argv[i]);
    800066a4:	ffffa097          	auipc	ra,0xffffa
    800066a8:	354080e7          	jalr	852(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066ac:	04a1                	addi	s1,s1,8
    800066ae:	ff3499e3          	bne	s1,s3,800066a0 <sys_exec+0xe4>
    800066b2:	a011                	j	800066b6 <sys_exec+0xfa>
  return -1;
    800066b4:	597d                	li	s2,-1
}
    800066b6:	854a                	mv	a0,s2
    800066b8:	60be                	ld	ra,456(sp)
    800066ba:	641e                	ld	s0,448(sp)
    800066bc:	74fa                	ld	s1,440(sp)
    800066be:	795a                	ld	s2,432(sp)
    800066c0:	79ba                	ld	s3,424(sp)
    800066c2:	7a1a                	ld	s4,416(sp)
    800066c4:	6afa                	ld	s5,408(sp)
    800066c6:	6179                	addi	sp,sp,464
    800066c8:	8082                	ret

00000000800066ca <sys_pipe>:

uint64
sys_pipe(void)
{
    800066ca:	7139                	addi	sp,sp,-64
    800066cc:	fc06                	sd	ra,56(sp)
    800066ce:	f822                	sd	s0,48(sp)
    800066d0:	f426                	sd	s1,40(sp)
    800066d2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800066d4:	ffffc097          	auipc	ra,0xffffc
    800066d8:	9fa080e7          	jalr	-1542(ra) # 800020ce <myproc>
    800066dc:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800066de:	fd840593          	addi	a1,s0,-40
    800066e2:	4501                	li	a0,0
    800066e4:	ffffd097          	auipc	ra,0xffffd
    800066e8:	078080e7          	jalr	120(ra) # 8000375c <argaddr>
    return -1;
    800066ec:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800066ee:	0e054063          	bltz	a0,800067ce <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800066f2:	fc840593          	addi	a1,s0,-56
    800066f6:	fd040513          	addi	a0,s0,-48
    800066fa:	fffff097          	auipc	ra,0xfffff
    800066fe:	dfc080e7          	jalr	-516(ra) # 800054f6 <pipealloc>
    return -1;
    80006702:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006704:	0c054563          	bltz	a0,800067ce <sys_pipe+0x104>
  fd0 = -1;
    80006708:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000670c:	fd043503          	ld	a0,-48(s0)
    80006710:	fffff097          	auipc	ra,0xfffff
    80006714:	508080e7          	jalr	1288(ra) # 80005c18 <fdalloc>
    80006718:	fca42223          	sw	a0,-60(s0)
    8000671c:	08054c63          	bltz	a0,800067b4 <sys_pipe+0xea>
    80006720:	fc843503          	ld	a0,-56(s0)
    80006724:	fffff097          	auipc	ra,0xfffff
    80006728:	4f4080e7          	jalr	1268(ra) # 80005c18 <fdalloc>
    8000672c:	fca42023          	sw	a0,-64(s0)
    80006730:	06054863          	bltz	a0,800067a0 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006734:	4691                	li	a3,4
    80006736:	fc440613          	addi	a2,s0,-60
    8000673a:	fd843583          	ld	a1,-40(s0)
    8000673e:	68a8                	ld	a0,80(s1)
    80006740:	ffffb097          	auipc	ra,0xffffb
    80006744:	f32080e7          	jalr	-206(ra) # 80001672 <copyout>
    80006748:	02054063          	bltz	a0,80006768 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000674c:	4691                	li	a3,4
    8000674e:	fc040613          	addi	a2,s0,-64
    80006752:	fd843583          	ld	a1,-40(s0)
    80006756:	0591                	addi	a1,a1,4
    80006758:	68a8                	ld	a0,80(s1)
    8000675a:	ffffb097          	auipc	ra,0xffffb
    8000675e:	f18080e7          	jalr	-232(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006762:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006764:	06055563          	bgez	a0,800067ce <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006768:	fc442783          	lw	a5,-60(s0)
    8000676c:	07e9                	addi	a5,a5,26
    8000676e:	078e                	slli	a5,a5,0x3
    80006770:	97a6                	add	a5,a5,s1
    80006772:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006776:	fc042503          	lw	a0,-64(s0)
    8000677a:	0569                	addi	a0,a0,26
    8000677c:	050e                	slli	a0,a0,0x3
    8000677e:	9526                	add	a0,a0,s1
    80006780:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006784:	fd043503          	ld	a0,-48(s0)
    80006788:	fffff097          	auipc	ra,0xfffff
    8000678c:	a3e080e7          	jalr	-1474(ra) # 800051c6 <fileclose>
    fileclose(wf);
    80006790:	fc843503          	ld	a0,-56(s0)
    80006794:	fffff097          	auipc	ra,0xfffff
    80006798:	a32080e7          	jalr	-1486(ra) # 800051c6 <fileclose>
    return -1;
    8000679c:	57fd                	li	a5,-1
    8000679e:	a805                	j	800067ce <sys_pipe+0x104>
    if(fd0 >= 0)
    800067a0:	fc442783          	lw	a5,-60(s0)
    800067a4:	0007c863          	bltz	a5,800067b4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800067a8:	01a78513          	addi	a0,a5,26
    800067ac:	050e                	slli	a0,a0,0x3
    800067ae:	9526                	add	a0,a0,s1
    800067b0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800067b4:	fd043503          	ld	a0,-48(s0)
    800067b8:	fffff097          	auipc	ra,0xfffff
    800067bc:	a0e080e7          	jalr	-1522(ra) # 800051c6 <fileclose>
    fileclose(wf);
    800067c0:	fc843503          	ld	a0,-56(s0)
    800067c4:	fffff097          	auipc	ra,0xfffff
    800067c8:	a02080e7          	jalr	-1534(ra) # 800051c6 <fileclose>
    return -1;
    800067cc:	57fd                	li	a5,-1
}
    800067ce:	853e                	mv	a0,a5
    800067d0:	70e2                	ld	ra,56(sp)
    800067d2:	7442                	ld	s0,48(sp)
    800067d4:	74a2                	ld	s1,40(sp)
    800067d6:	6121                	addi	sp,sp,64
    800067d8:	8082                	ret
    800067da:	0000                	unimp
    800067dc:	0000                	unimp
	...

00000000800067e0 <kernelvec>:
    800067e0:	7111                	addi	sp,sp,-256
    800067e2:	e006                	sd	ra,0(sp)
    800067e4:	e40a                	sd	sp,8(sp)
    800067e6:	e80e                	sd	gp,16(sp)
    800067e8:	ec12                	sd	tp,24(sp)
    800067ea:	f016                	sd	t0,32(sp)
    800067ec:	f41a                	sd	t1,40(sp)
    800067ee:	f81e                	sd	t2,48(sp)
    800067f0:	fc22                	sd	s0,56(sp)
    800067f2:	e0a6                	sd	s1,64(sp)
    800067f4:	e4aa                	sd	a0,72(sp)
    800067f6:	e8ae                	sd	a1,80(sp)
    800067f8:	ecb2                	sd	a2,88(sp)
    800067fa:	f0b6                	sd	a3,96(sp)
    800067fc:	f4ba                	sd	a4,104(sp)
    800067fe:	f8be                	sd	a5,112(sp)
    80006800:	fcc2                	sd	a6,120(sp)
    80006802:	e146                	sd	a7,128(sp)
    80006804:	e54a                	sd	s2,136(sp)
    80006806:	e94e                	sd	s3,144(sp)
    80006808:	ed52                	sd	s4,152(sp)
    8000680a:	f156                	sd	s5,160(sp)
    8000680c:	f55a                	sd	s6,168(sp)
    8000680e:	f95e                	sd	s7,176(sp)
    80006810:	fd62                	sd	s8,184(sp)
    80006812:	e1e6                	sd	s9,192(sp)
    80006814:	e5ea                	sd	s10,200(sp)
    80006816:	e9ee                	sd	s11,208(sp)
    80006818:	edf2                	sd	t3,216(sp)
    8000681a:	f1f6                	sd	t4,224(sp)
    8000681c:	f5fa                	sd	t5,232(sp)
    8000681e:	f9fe                	sd	t6,240(sp)
    80006820:	d4dfc0ef          	jal	ra,8000356c <kerneltrap>
    80006824:	6082                	ld	ra,0(sp)
    80006826:	6122                	ld	sp,8(sp)
    80006828:	61c2                	ld	gp,16(sp)
    8000682a:	7282                	ld	t0,32(sp)
    8000682c:	7322                	ld	t1,40(sp)
    8000682e:	73c2                	ld	t2,48(sp)
    80006830:	7462                	ld	s0,56(sp)
    80006832:	6486                	ld	s1,64(sp)
    80006834:	6526                	ld	a0,72(sp)
    80006836:	65c6                	ld	a1,80(sp)
    80006838:	6666                	ld	a2,88(sp)
    8000683a:	7686                	ld	a3,96(sp)
    8000683c:	7726                	ld	a4,104(sp)
    8000683e:	77c6                	ld	a5,112(sp)
    80006840:	7866                	ld	a6,120(sp)
    80006842:	688a                	ld	a7,128(sp)
    80006844:	692a                	ld	s2,136(sp)
    80006846:	69ca                	ld	s3,144(sp)
    80006848:	6a6a                	ld	s4,152(sp)
    8000684a:	7a8a                	ld	s5,160(sp)
    8000684c:	7b2a                	ld	s6,168(sp)
    8000684e:	7bca                	ld	s7,176(sp)
    80006850:	7c6a                	ld	s8,184(sp)
    80006852:	6c8e                	ld	s9,192(sp)
    80006854:	6d2e                	ld	s10,200(sp)
    80006856:	6dce                	ld	s11,208(sp)
    80006858:	6e6e                	ld	t3,216(sp)
    8000685a:	7e8e                	ld	t4,224(sp)
    8000685c:	7f2e                	ld	t5,232(sp)
    8000685e:	7fce                	ld	t6,240(sp)
    80006860:	6111                	addi	sp,sp,256
    80006862:	10200073          	sret
    80006866:	00000013          	nop
    8000686a:	00000013          	nop
    8000686e:	0001                	nop

0000000080006870 <timervec>:
    80006870:	34051573          	csrrw	a0,mscratch,a0
    80006874:	e10c                	sd	a1,0(a0)
    80006876:	e510                	sd	a2,8(a0)
    80006878:	e914                	sd	a3,16(a0)
    8000687a:	6d0c                	ld	a1,24(a0)
    8000687c:	7110                	ld	a2,32(a0)
    8000687e:	6194                	ld	a3,0(a1)
    80006880:	96b2                	add	a3,a3,a2
    80006882:	e194                	sd	a3,0(a1)
    80006884:	4589                	li	a1,2
    80006886:	14459073          	csrw	sip,a1
    8000688a:	6914                	ld	a3,16(a0)
    8000688c:	6510                	ld	a2,8(a0)
    8000688e:	610c                	ld	a1,0(a0)
    80006890:	34051573          	csrrw	a0,mscratch,a0
    80006894:	30200073          	mret
	...

000000008000689a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000689a:	1141                	addi	sp,sp,-16
    8000689c:	e422                	sd	s0,8(sp)
    8000689e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800068a0:	0c0007b7          	lui	a5,0xc000
    800068a4:	4705                	li	a4,1
    800068a6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800068a8:	c3d8                	sw	a4,4(a5)
}
    800068aa:	6422                	ld	s0,8(sp)
    800068ac:	0141                	addi	sp,sp,16
    800068ae:	8082                	ret

00000000800068b0 <plicinithart>:

void
plicinithart(void)
{
    800068b0:	1141                	addi	sp,sp,-16
    800068b2:	e406                	sd	ra,8(sp)
    800068b4:	e022                	sd	s0,0(sp)
    800068b6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800068b8:	ffffb097          	auipc	ra,0xffffb
    800068bc:	7e4080e7          	jalr	2020(ra) # 8000209c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800068c0:	0085171b          	slliw	a4,a0,0x8
    800068c4:	0c0027b7          	lui	a5,0xc002
    800068c8:	97ba                	add	a5,a5,a4
    800068ca:	40200713          	li	a4,1026
    800068ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800068d2:	00d5151b          	slliw	a0,a0,0xd
    800068d6:	0c2017b7          	lui	a5,0xc201
    800068da:	953e                	add	a0,a0,a5
    800068dc:	00052023          	sw	zero,0(a0)
}
    800068e0:	60a2                	ld	ra,8(sp)
    800068e2:	6402                	ld	s0,0(sp)
    800068e4:	0141                	addi	sp,sp,16
    800068e6:	8082                	ret

00000000800068e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800068e8:	1141                	addi	sp,sp,-16
    800068ea:	e406                	sd	ra,8(sp)
    800068ec:	e022                	sd	s0,0(sp)
    800068ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800068f0:	ffffb097          	auipc	ra,0xffffb
    800068f4:	7ac080e7          	jalr	1964(ra) # 8000209c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800068f8:	00d5179b          	slliw	a5,a0,0xd
    800068fc:	0c201537          	lui	a0,0xc201
    80006900:	953e                	add	a0,a0,a5
  return irq;
}
    80006902:	4148                	lw	a0,4(a0)
    80006904:	60a2                	ld	ra,8(sp)
    80006906:	6402                	ld	s0,0(sp)
    80006908:	0141                	addi	sp,sp,16
    8000690a:	8082                	ret

000000008000690c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000690c:	1101                	addi	sp,sp,-32
    8000690e:	ec06                	sd	ra,24(sp)
    80006910:	e822                	sd	s0,16(sp)
    80006912:	e426                	sd	s1,8(sp)
    80006914:	1000                	addi	s0,sp,32
    80006916:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006918:	ffffb097          	auipc	ra,0xffffb
    8000691c:	784080e7          	jalr	1924(ra) # 8000209c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006920:	00d5151b          	slliw	a0,a0,0xd
    80006924:	0c2017b7          	lui	a5,0xc201
    80006928:	97aa                	add	a5,a5,a0
    8000692a:	c3c4                	sw	s1,4(a5)
}
    8000692c:	60e2                	ld	ra,24(sp)
    8000692e:	6442                	ld	s0,16(sp)
    80006930:	64a2                	ld	s1,8(sp)
    80006932:	6105                	addi	sp,sp,32
    80006934:	8082                	ret

0000000080006936 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006936:	1141                	addi	sp,sp,-16
    80006938:	e406                	sd	ra,8(sp)
    8000693a:	e022                	sd	s0,0(sp)
    8000693c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000693e:	479d                	li	a5,7
    80006940:	06a7c963          	blt	a5,a0,800069b2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006944:	0001c797          	auipc	a5,0x1c
    80006948:	6bc78793          	addi	a5,a5,1724 # 80023000 <disk>
    8000694c:	00a78733          	add	a4,a5,a0
    80006950:	6789                	lui	a5,0x2
    80006952:	97ba                	add	a5,a5,a4
    80006954:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006958:	e7ad                	bnez	a5,800069c2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000695a:	00451793          	slli	a5,a0,0x4
    8000695e:	0001e717          	auipc	a4,0x1e
    80006962:	6a270713          	addi	a4,a4,1698 # 80025000 <disk+0x2000>
    80006966:	6314                	ld	a3,0(a4)
    80006968:	96be                	add	a3,a3,a5
    8000696a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000696e:	6314                	ld	a3,0(a4)
    80006970:	96be                	add	a3,a3,a5
    80006972:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006976:	6314                	ld	a3,0(a4)
    80006978:	96be                	add	a3,a3,a5
    8000697a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000697e:	6318                	ld	a4,0(a4)
    80006980:	97ba                	add	a5,a5,a4
    80006982:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006986:	0001c797          	auipc	a5,0x1c
    8000698a:	67a78793          	addi	a5,a5,1658 # 80023000 <disk>
    8000698e:	97aa                	add	a5,a5,a0
    80006990:	6509                	lui	a0,0x2
    80006992:	953e                	add	a0,a0,a5
    80006994:	4785                	li	a5,1
    80006996:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000699a:	0001e517          	auipc	a0,0x1e
    8000699e:	67e50513          	addi	a0,a0,1662 # 80025018 <disk+0x2018>
    800069a2:	ffffc097          	auipc	ra,0xffffc
    800069a6:	3ec080e7          	jalr	1004(ra) # 80002d8e <wakeup>
}
    800069aa:	60a2                	ld	ra,8(sp)
    800069ac:	6402                	ld	s0,0(sp)
    800069ae:	0141                	addi	sp,sp,16
    800069b0:	8082                	ret
    panic("free_desc 1");
    800069b2:	00002517          	auipc	a0,0x2
    800069b6:	19650513          	addi	a0,a0,406 # 80008b48 <syscalls+0x338>
    800069ba:	ffffa097          	auipc	ra,0xffffa
    800069be:	b84080e7          	jalr	-1148(ra) # 8000053e <panic>
    panic("free_desc 2");
    800069c2:	00002517          	auipc	a0,0x2
    800069c6:	19650513          	addi	a0,a0,406 # 80008b58 <syscalls+0x348>
    800069ca:	ffffa097          	auipc	ra,0xffffa
    800069ce:	b74080e7          	jalr	-1164(ra) # 8000053e <panic>

00000000800069d2 <virtio_disk_init>:
{
    800069d2:	1101                	addi	sp,sp,-32
    800069d4:	ec06                	sd	ra,24(sp)
    800069d6:	e822                	sd	s0,16(sp)
    800069d8:	e426                	sd	s1,8(sp)
    800069da:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800069dc:	00002597          	auipc	a1,0x2
    800069e0:	18c58593          	addi	a1,a1,396 # 80008b68 <syscalls+0x358>
    800069e4:	0001e517          	auipc	a0,0x1e
    800069e8:	74450513          	addi	a0,a0,1860 # 80025128 <disk+0x2128>
    800069ec:	ffffa097          	auipc	ra,0xffffa
    800069f0:	168080e7          	jalr	360(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800069f4:	100017b7          	lui	a5,0x10001
    800069f8:	4398                	lw	a4,0(a5)
    800069fa:	2701                	sext.w	a4,a4
    800069fc:	747277b7          	lui	a5,0x74727
    80006a00:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006a04:	0ef71163          	bne	a4,a5,80006ae6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006a08:	100017b7          	lui	a5,0x10001
    80006a0c:	43dc                	lw	a5,4(a5)
    80006a0e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006a10:	4705                	li	a4,1
    80006a12:	0ce79a63          	bne	a5,a4,80006ae6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a16:	100017b7          	lui	a5,0x10001
    80006a1a:	479c                	lw	a5,8(a5)
    80006a1c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006a1e:	4709                	li	a4,2
    80006a20:	0ce79363          	bne	a5,a4,80006ae6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006a24:	100017b7          	lui	a5,0x10001
    80006a28:	47d8                	lw	a4,12(a5)
    80006a2a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a2c:	554d47b7          	lui	a5,0x554d4
    80006a30:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006a34:	0af71963          	bne	a4,a5,80006ae6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a38:	100017b7          	lui	a5,0x10001
    80006a3c:	4705                	li	a4,1
    80006a3e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a40:	470d                	li	a4,3
    80006a42:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006a44:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006a46:	c7ffe737          	lui	a4,0xc7ffe
    80006a4a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80006a4e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006a50:	2701                	sext.w	a4,a4
    80006a52:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a54:	472d                	li	a4,11
    80006a56:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a58:	473d                	li	a4,15
    80006a5a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006a5c:	6705                	lui	a4,0x1
    80006a5e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006a60:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006a64:	5bdc                	lw	a5,52(a5)
    80006a66:	2781                	sext.w	a5,a5
  if(max == 0)
    80006a68:	c7d9                	beqz	a5,80006af6 <virtio_disk_init+0x124>
  if(max < NUM)
    80006a6a:	471d                	li	a4,7
    80006a6c:	08f77d63          	bgeu	a4,a5,80006b06 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006a70:	100014b7          	lui	s1,0x10001
    80006a74:	47a1                	li	a5,8
    80006a76:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006a78:	6609                	lui	a2,0x2
    80006a7a:	4581                	li	a1,0
    80006a7c:	0001c517          	auipc	a0,0x1c
    80006a80:	58450513          	addi	a0,a0,1412 # 80023000 <disk>
    80006a84:	ffffa097          	auipc	ra,0xffffa
    80006a88:	25c080e7          	jalr	604(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006a8c:	0001c717          	auipc	a4,0x1c
    80006a90:	57470713          	addi	a4,a4,1396 # 80023000 <disk>
    80006a94:	00c75793          	srli	a5,a4,0xc
    80006a98:	2781                	sext.w	a5,a5
    80006a9a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006a9c:	0001e797          	auipc	a5,0x1e
    80006aa0:	56478793          	addi	a5,a5,1380 # 80025000 <disk+0x2000>
    80006aa4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006aa6:	0001c717          	auipc	a4,0x1c
    80006aaa:	5da70713          	addi	a4,a4,1498 # 80023080 <disk+0x80>
    80006aae:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006ab0:	0001d717          	auipc	a4,0x1d
    80006ab4:	55070713          	addi	a4,a4,1360 # 80024000 <disk+0x1000>
    80006ab8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006aba:	4705                	li	a4,1
    80006abc:	00e78c23          	sb	a4,24(a5)
    80006ac0:	00e78ca3          	sb	a4,25(a5)
    80006ac4:	00e78d23          	sb	a4,26(a5)
    80006ac8:	00e78da3          	sb	a4,27(a5)
    80006acc:	00e78e23          	sb	a4,28(a5)
    80006ad0:	00e78ea3          	sb	a4,29(a5)
    80006ad4:	00e78f23          	sb	a4,30(a5)
    80006ad8:	00e78fa3          	sb	a4,31(a5)
}
    80006adc:	60e2                	ld	ra,24(sp)
    80006ade:	6442                	ld	s0,16(sp)
    80006ae0:	64a2                	ld	s1,8(sp)
    80006ae2:	6105                	addi	sp,sp,32
    80006ae4:	8082                	ret
    panic("could not find virtio disk");
    80006ae6:	00002517          	auipc	a0,0x2
    80006aea:	09250513          	addi	a0,a0,146 # 80008b78 <syscalls+0x368>
    80006aee:	ffffa097          	auipc	ra,0xffffa
    80006af2:	a50080e7          	jalr	-1456(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006af6:	00002517          	auipc	a0,0x2
    80006afa:	0a250513          	addi	a0,a0,162 # 80008b98 <syscalls+0x388>
    80006afe:	ffffa097          	auipc	ra,0xffffa
    80006b02:	a40080e7          	jalr	-1472(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006b06:	00002517          	auipc	a0,0x2
    80006b0a:	0b250513          	addi	a0,a0,178 # 80008bb8 <syscalls+0x3a8>
    80006b0e:	ffffa097          	auipc	ra,0xffffa
    80006b12:	a30080e7          	jalr	-1488(ra) # 8000053e <panic>

0000000080006b16 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006b16:	7159                	addi	sp,sp,-112
    80006b18:	f486                	sd	ra,104(sp)
    80006b1a:	f0a2                	sd	s0,96(sp)
    80006b1c:	eca6                	sd	s1,88(sp)
    80006b1e:	e8ca                	sd	s2,80(sp)
    80006b20:	e4ce                	sd	s3,72(sp)
    80006b22:	e0d2                	sd	s4,64(sp)
    80006b24:	fc56                	sd	s5,56(sp)
    80006b26:	f85a                	sd	s6,48(sp)
    80006b28:	f45e                	sd	s7,40(sp)
    80006b2a:	f062                	sd	s8,32(sp)
    80006b2c:	ec66                	sd	s9,24(sp)
    80006b2e:	e86a                	sd	s10,16(sp)
    80006b30:	1880                	addi	s0,sp,112
    80006b32:	892a                	mv	s2,a0
    80006b34:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006b36:	00c52c83          	lw	s9,12(a0)
    80006b3a:	001c9c9b          	slliw	s9,s9,0x1
    80006b3e:	1c82                	slli	s9,s9,0x20
    80006b40:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006b44:	0001e517          	auipc	a0,0x1e
    80006b48:	5e450513          	addi	a0,a0,1508 # 80025128 <disk+0x2128>
    80006b4c:	ffffa097          	auipc	ra,0xffffa
    80006b50:	098080e7          	jalr	152(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006b54:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006b56:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006b58:	0001cb97          	auipc	s7,0x1c
    80006b5c:	4a8b8b93          	addi	s7,s7,1192 # 80023000 <disk>
    80006b60:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006b62:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006b64:	8a4e                	mv	s4,s3
    80006b66:	a051                	j	80006bea <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006b68:	00fb86b3          	add	a3,s7,a5
    80006b6c:	96da                	add	a3,a3,s6
    80006b6e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006b72:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006b74:	0207c563          	bltz	a5,80006b9e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006b78:	2485                	addiw	s1,s1,1
    80006b7a:	0711                	addi	a4,a4,4
    80006b7c:	25548063          	beq	s1,s5,80006dbc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006b80:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006b82:	0001e697          	auipc	a3,0x1e
    80006b86:	49668693          	addi	a3,a3,1174 # 80025018 <disk+0x2018>
    80006b8a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006b8c:	0006c583          	lbu	a1,0(a3)
    80006b90:	fde1                	bnez	a1,80006b68 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006b92:	2785                	addiw	a5,a5,1
    80006b94:	0685                	addi	a3,a3,1
    80006b96:	ff879be3          	bne	a5,s8,80006b8c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006b9a:	57fd                	li	a5,-1
    80006b9c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006b9e:	02905a63          	blez	s1,80006bd2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006ba2:	f9042503          	lw	a0,-112(s0)
    80006ba6:	00000097          	auipc	ra,0x0
    80006baa:	d90080e7          	jalr	-624(ra) # 80006936 <free_desc>
      for(int j = 0; j < i; j++)
    80006bae:	4785                	li	a5,1
    80006bb0:	0297d163          	bge	a5,s1,80006bd2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006bb4:	f9442503          	lw	a0,-108(s0)
    80006bb8:	00000097          	auipc	ra,0x0
    80006bbc:	d7e080e7          	jalr	-642(ra) # 80006936 <free_desc>
      for(int j = 0; j < i; j++)
    80006bc0:	4789                	li	a5,2
    80006bc2:	0097d863          	bge	a5,s1,80006bd2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006bc6:	f9842503          	lw	a0,-104(s0)
    80006bca:	00000097          	auipc	ra,0x0
    80006bce:	d6c080e7          	jalr	-660(ra) # 80006936 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006bd2:	0001e597          	auipc	a1,0x1e
    80006bd6:	55658593          	addi	a1,a1,1366 # 80025128 <disk+0x2128>
    80006bda:	0001e517          	auipc	a0,0x1e
    80006bde:	43e50513          	addi	a0,a0,1086 # 80025018 <disk+0x2018>
    80006be2:	ffffc097          	auipc	ra,0xffffc
    80006be6:	b26080e7          	jalr	-1242(ra) # 80002708 <sleep>
  for(int i = 0; i < 3; i++){
    80006bea:	f9040713          	addi	a4,s0,-112
    80006bee:	84ce                	mv	s1,s3
    80006bf0:	bf41                	j	80006b80 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006bf2:	20058713          	addi	a4,a1,512
    80006bf6:	00471693          	slli	a3,a4,0x4
    80006bfa:	0001c717          	auipc	a4,0x1c
    80006bfe:	40670713          	addi	a4,a4,1030 # 80023000 <disk>
    80006c02:	9736                	add	a4,a4,a3
    80006c04:	4685                	li	a3,1
    80006c06:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006c0a:	20058713          	addi	a4,a1,512
    80006c0e:	00471693          	slli	a3,a4,0x4
    80006c12:	0001c717          	auipc	a4,0x1c
    80006c16:	3ee70713          	addi	a4,a4,1006 # 80023000 <disk>
    80006c1a:	9736                	add	a4,a4,a3
    80006c1c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006c20:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006c24:	7679                	lui	a2,0xffffe
    80006c26:	963e                	add	a2,a2,a5
    80006c28:	0001e697          	auipc	a3,0x1e
    80006c2c:	3d868693          	addi	a3,a3,984 # 80025000 <disk+0x2000>
    80006c30:	6298                	ld	a4,0(a3)
    80006c32:	9732                	add	a4,a4,a2
    80006c34:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006c36:	6298                	ld	a4,0(a3)
    80006c38:	9732                	add	a4,a4,a2
    80006c3a:	4541                	li	a0,16
    80006c3c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006c3e:	6298                	ld	a4,0(a3)
    80006c40:	9732                	add	a4,a4,a2
    80006c42:	4505                	li	a0,1
    80006c44:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006c48:	f9442703          	lw	a4,-108(s0)
    80006c4c:	6288                	ld	a0,0(a3)
    80006c4e:	962a                	add	a2,a2,a0
    80006c50:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006c54:	0712                	slli	a4,a4,0x4
    80006c56:	6290                	ld	a2,0(a3)
    80006c58:	963a                	add	a2,a2,a4
    80006c5a:	05890513          	addi	a0,s2,88
    80006c5e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006c60:	6294                	ld	a3,0(a3)
    80006c62:	96ba                	add	a3,a3,a4
    80006c64:	40000613          	li	a2,1024
    80006c68:	c690                	sw	a2,8(a3)
  if(write)
    80006c6a:	140d0063          	beqz	s10,80006daa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006c6e:	0001e697          	auipc	a3,0x1e
    80006c72:	3926b683          	ld	a3,914(a3) # 80025000 <disk+0x2000>
    80006c76:	96ba                	add	a3,a3,a4
    80006c78:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006c7c:	0001c817          	auipc	a6,0x1c
    80006c80:	38480813          	addi	a6,a6,900 # 80023000 <disk>
    80006c84:	0001e517          	auipc	a0,0x1e
    80006c88:	37c50513          	addi	a0,a0,892 # 80025000 <disk+0x2000>
    80006c8c:	6114                	ld	a3,0(a0)
    80006c8e:	96ba                	add	a3,a3,a4
    80006c90:	00c6d603          	lhu	a2,12(a3)
    80006c94:	00166613          	ori	a2,a2,1
    80006c98:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006c9c:	f9842683          	lw	a3,-104(s0)
    80006ca0:	6110                	ld	a2,0(a0)
    80006ca2:	9732                	add	a4,a4,a2
    80006ca4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006ca8:	20058613          	addi	a2,a1,512
    80006cac:	0612                	slli	a2,a2,0x4
    80006cae:	9642                	add	a2,a2,a6
    80006cb0:	577d                	li	a4,-1
    80006cb2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006cb6:	00469713          	slli	a4,a3,0x4
    80006cba:	6114                	ld	a3,0(a0)
    80006cbc:	96ba                	add	a3,a3,a4
    80006cbe:	03078793          	addi	a5,a5,48
    80006cc2:	97c2                	add	a5,a5,a6
    80006cc4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006cc6:	611c                	ld	a5,0(a0)
    80006cc8:	97ba                	add	a5,a5,a4
    80006cca:	4685                	li	a3,1
    80006ccc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006cce:	611c                	ld	a5,0(a0)
    80006cd0:	97ba                	add	a5,a5,a4
    80006cd2:	4809                	li	a6,2
    80006cd4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006cd8:	611c                	ld	a5,0(a0)
    80006cda:	973e                	add	a4,a4,a5
    80006cdc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006ce0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006ce4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006ce8:	6518                	ld	a4,8(a0)
    80006cea:	00275783          	lhu	a5,2(a4)
    80006cee:	8b9d                	andi	a5,a5,7
    80006cf0:	0786                	slli	a5,a5,0x1
    80006cf2:	97ba                	add	a5,a5,a4
    80006cf4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006cf8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006cfc:	6518                	ld	a4,8(a0)
    80006cfe:	00275783          	lhu	a5,2(a4)
    80006d02:	2785                	addiw	a5,a5,1
    80006d04:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006d08:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006d0c:	100017b7          	lui	a5,0x10001
    80006d10:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006d14:	00492703          	lw	a4,4(s2)
    80006d18:	4785                	li	a5,1
    80006d1a:	02f71163          	bne	a4,a5,80006d3c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006d1e:	0001e997          	auipc	s3,0x1e
    80006d22:	40a98993          	addi	s3,s3,1034 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006d26:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006d28:	85ce                	mv	a1,s3
    80006d2a:	854a                	mv	a0,s2
    80006d2c:	ffffc097          	auipc	ra,0xffffc
    80006d30:	9dc080e7          	jalr	-1572(ra) # 80002708 <sleep>
  while(b->disk == 1) {
    80006d34:	00492783          	lw	a5,4(s2)
    80006d38:	fe9788e3          	beq	a5,s1,80006d28 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006d3c:	f9042903          	lw	s2,-112(s0)
    80006d40:	20090793          	addi	a5,s2,512
    80006d44:	00479713          	slli	a4,a5,0x4
    80006d48:	0001c797          	auipc	a5,0x1c
    80006d4c:	2b878793          	addi	a5,a5,696 # 80023000 <disk>
    80006d50:	97ba                	add	a5,a5,a4
    80006d52:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006d56:	0001e997          	auipc	s3,0x1e
    80006d5a:	2aa98993          	addi	s3,s3,682 # 80025000 <disk+0x2000>
    80006d5e:	00491713          	slli	a4,s2,0x4
    80006d62:	0009b783          	ld	a5,0(s3)
    80006d66:	97ba                	add	a5,a5,a4
    80006d68:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006d6c:	854a                	mv	a0,s2
    80006d6e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006d72:	00000097          	auipc	ra,0x0
    80006d76:	bc4080e7          	jalr	-1084(ra) # 80006936 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006d7a:	8885                	andi	s1,s1,1
    80006d7c:	f0ed                	bnez	s1,80006d5e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006d7e:	0001e517          	auipc	a0,0x1e
    80006d82:	3aa50513          	addi	a0,a0,938 # 80025128 <disk+0x2128>
    80006d86:	ffffa097          	auipc	ra,0xffffa
    80006d8a:	f12080e7          	jalr	-238(ra) # 80000c98 <release>
}
    80006d8e:	70a6                	ld	ra,104(sp)
    80006d90:	7406                	ld	s0,96(sp)
    80006d92:	64e6                	ld	s1,88(sp)
    80006d94:	6946                	ld	s2,80(sp)
    80006d96:	69a6                	ld	s3,72(sp)
    80006d98:	6a06                	ld	s4,64(sp)
    80006d9a:	7ae2                	ld	s5,56(sp)
    80006d9c:	7b42                	ld	s6,48(sp)
    80006d9e:	7ba2                	ld	s7,40(sp)
    80006da0:	7c02                	ld	s8,32(sp)
    80006da2:	6ce2                	ld	s9,24(sp)
    80006da4:	6d42                	ld	s10,16(sp)
    80006da6:	6165                	addi	sp,sp,112
    80006da8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006daa:	0001e697          	auipc	a3,0x1e
    80006dae:	2566b683          	ld	a3,598(a3) # 80025000 <disk+0x2000>
    80006db2:	96ba                	add	a3,a3,a4
    80006db4:	4609                	li	a2,2
    80006db6:	00c69623          	sh	a2,12(a3)
    80006dba:	b5c9                	j	80006c7c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006dbc:	f9042583          	lw	a1,-112(s0)
    80006dc0:	20058793          	addi	a5,a1,512
    80006dc4:	0792                	slli	a5,a5,0x4
    80006dc6:	0001c517          	auipc	a0,0x1c
    80006dca:	2e250513          	addi	a0,a0,738 # 800230a8 <disk+0xa8>
    80006dce:	953e                	add	a0,a0,a5
  if(write)
    80006dd0:	e20d11e3          	bnez	s10,80006bf2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006dd4:	20058713          	addi	a4,a1,512
    80006dd8:	00471693          	slli	a3,a4,0x4
    80006ddc:	0001c717          	auipc	a4,0x1c
    80006de0:	22470713          	addi	a4,a4,548 # 80023000 <disk>
    80006de4:	9736                	add	a4,a4,a3
    80006de6:	0a072423          	sw	zero,168(a4)
    80006dea:	b505                	j	80006c0a <virtio_disk_rw+0xf4>

0000000080006dec <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006dec:	1101                	addi	sp,sp,-32
    80006dee:	ec06                	sd	ra,24(sp)
    80006df0:	e822                	sd	s0,16(sp)
    80006df2:	e426                	sd	s1,8(sp)
    80006df4:	e04a                	sd	s2,0(sp)
    80006df6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006df8:	0001e517          	auipc	a0,0x1e
    80006dfc:	33050513          	addi	a0,a0,816 # 80025128 <disk+0x2128>
    80006e00:	ffffa097          	auipc	ra,0xffffa
    80006e04:	de4080e7          	jalr	-540(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006e08:	10001737          	lui	a4,0x10001
    80006e0c:	533c                	lw	a5,96(a4)
    80006e0e:	8b8d                	andi	a5,a5,3
    80006e10:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006e12:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006e16:	0001e797          	auipc	a5,0x1e
    80006e1a:	1ea78793          	addi	a5,a5,490 # 80025000 <disk+0x2000>
    80006e1e:	6b94                	ld	a3,16(a5)
    80006e20:	0207d703          	lhu	a4,32(a5)
    80006e24:	0026d783          	lhu	a5,2(a3)
    80006e28:	06f70163          	beq	a4,a5,80006e8a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006e2c:	0001c917          	auipc	s2,0x1c
    80006e30:	1d490913          	addi	s2,s2,468 # 80023000 <disk>
    80006e34:	0001e497          	auipc	s1,0x1e
    80006e38:	1cc48493          	addi	s1,s1,460 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006e3c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006e40:	6898                	ld	a4,16(s1)
    80006e42:	0204d783          	lhu	a5,32(s1)
    80006e46:	8b9d                	andi	a5,a5,7
    80006e48:	078e                	slli	a5,a5,0x3
    80006e4a:	97ba                	add	a5,a5,a4
    80006e4c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006e4e:	20078713          	addi	a4,a5,512
    80006e52:	0712                	slli	a4,a4,0x4
    80006e54:	974a                	add	a4,a4,s2
    80006e56:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006e5a:	e731                	bnez	a4,80006ea6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006e5c:	20078793          	addi	a5,a5,512
    80006e60:	0792                	slli	a5,a5,0x4
    80006e62:	97ca                	add	a5,a5,s2
    80006e64:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006e66:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006e6a:	ffffc097          	auipc	ra,0xffffc
    80006e6e:	f24080e7          	jalr	-220(ra) # 80002d8e <wakeup>

    disk.used_idx += 1;
    80006e72:	0204d783          	lhu	a5,32(s1)
    80006e76:	2785                	addiw	a5,a5,1
    80006e78:	17c2                	slli	a5,a5,0x30
    80006e7a:	93c1                	srli	a5,a5,0x30
    80006e7c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006e80:	6898                	ld	a4,16(s1)
    80006e82:	00275703          	lhu	a4,2(a4)
    80006e86:	faf71be3          	bne	a4,a5,80006e3c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006e8a:	0001e517          	auipc	a0,0x1e
    80006e8e:	29e50513          	addi	a0,a0,670 # 80025128 <disk+0x2128>
    80006e92:	ffffa097          	auipc	ra,0xffffa
    80006e96:	e06080e7          	jalr	-506(ra) # 80000c98 <release>
}
    80006e9a:	60e2                	ld	ra,24(sp)
    80006e9c:	6442                	ld	s0,16(sp)
    80006e9e:	64a2                	ld	s1,8(sp)
    80006ea0:	6902                	ld	s2,0(sp)
    80006ea2:	6105                	addi	sp,sp,32
    80006ea4:	8082                	ret
      panic("virtio_disk_intr status");
    80006ea6:	00002517          	auipc	a0,0x2
    80006eaa:	d3250513          	addi	a0,a0,-718 # 80008bd8 <syscalls+0x3c8>
    80006eae:	ffff9097          	auipc	ra,0xffff9
    80006eb2:	690080e7          	jalr	1680(ra) # 8000053e <panic>

0000000080006eb6 <cas>:
    80006eb6:	100522af          	lr.w	t0,(a0)
    80006eba:	00b29563          	bne	t0,a1,80006ec4 <fail>
    80006ebe:	18c5252f          	sc.w	a0,a2,(a0)
    80006ec2:	8082                	ret

0000000080006ec4 <fail>:
    80006ec4:	4505                	li	a0,1
    80006ec6:	8082                	ret
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
