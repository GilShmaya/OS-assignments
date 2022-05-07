
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	bc013103          	ld	sp,-1088(sp) # 80008bc0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	4ac78793          	addi	a5,a5,1196 # 80006510 <timervec>
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
    80000130:	780080e7          	jalr	1920(ra) # 800028ac <either_copyin>
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
    800001c8:	d00080e7          	jalr	-768(ra) # 80001ec4 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	45e080e7          	jalr	1118(ra) # 80002632 <sleep>
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
    80000214:	646080e7          	jalr	1606(ra) # 80002856 <either_copyout>
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
    800002f6:	610080e7          	jalr	1552(ra) # 80002902 <procdump>
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
    8000044a:	802080e7          	jalr	-2046(ra) # 80002c48 <wakeup>
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
    80000570:	e5c50513          	addi	a0,a0,-420 # 800083c8 <digits+0x388>
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
    800008a4:	3a8080e7          	jalr	936(ra) # 80002c48 <wakeup>
    
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
    80000930:	d06080e7          	jalr	-762(ra) # 80002632 <sleep>
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
    80000b82:	324080e7          	jalr	804(ra) # 80001ea2 <mycpu>
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
    80000bb4:	2f2080e7          	jalr	754(ra) # 80001ea2 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	2e6080e7          	jalr	742(ra) # 80001ea2 <mycpu>
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
    80000bd8:	2ce080e7          	jalr	718(ra) # 80001ea2 <mycpu>
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
    80000c18:	28e080e7          	jalr	654(ra) # 80001ea2 <mycpu>
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
    80000c44:	262080e7          	jalr	610(ra) # 80001ea2 <mycpu>
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
    80000e9a:	ffc080e7          	jalr	-4(ra) # 80001e92 <cpuid>
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
    80000eb6:	fe0080e7          	jalr	-32(ra) # 80001e92 <cpuid>
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
    80000ed8:	0a4080e7          	jalr	164(ra) # 80002f78 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	674080e7          	jalr	1652(ra) # 80006550 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	4c4080e7          	jalr	1220(ra) # 800023a8 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	4cc50513          	addi	a0,a0,1228 # 800083c8 <digits+0x388>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	4ac50513          	addi	a0,a0,1196 # 800083c8 <digits+0x388>
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
    80000f48:	e4c080e7          	jalr	-436(ra) # 80001d90 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	004080e7          	jalr	4(ra) # 80002f50 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	024080e7          	jalr	36(ra) # 80002f78 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	5de080e7          	jalr	1502(ra) # 8000653a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	5ec080e7          	jalr	1516(ra) # 80006550 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	7ca080e7          	jalr	1994(ra) # 80003736 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	e5a080e7          	jalr	-422(ra) # 80003dce <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	e04080e7          	jalr	-508(ra) # 80004d80 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	6ee080e7          	jalr	1774(ra) # 80006672 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	300080e7          	jalr	768(ra) # 8000228c <userinit>
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
    80001244:	aba080e7          	jalr	-1350(ra) # 80001cfa <proc_mapstacks>
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
    800018f0:	1141                	addi	sp,sp,-16
    800018f2:	e422                	sd	s0,8(sp)
    800018f4:	0800                	addi	s0,sp,16
  struct cpu *c;
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    800018f6:	00010797          	auipc	a5,0x10
    800018fa:	9aa78793          	addi	a5,a5,-1622 # 800112a0 <cpus>
    c->runnable_list = (struct _list){-1, -1};
    800018fe:	577d                	li	a4,-1
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001900:	00010697          	auipc	a3,0x10
    80001904:	f2068693          	addi	a3,a3,-224 # 80011820 <pid_lock>
    c->runnable_list = (struct _list){-1, -1};
    80001908:	0807b423          	sd	zero,136(a5)
    8000190c:	0807b823          	sd	zero,144(a5)
    80001910:	0807bc23          	sd	zero,152(a5)
    80001914:	08e7a023          	sw	a4,128(a5)
    80001918:	08e7a223          	sw	a4,132(a5)
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    8000191c:	0b078793          	addi	a5,a5,176
    80001920:	fed794e3          	bne	a5,a3,80001908 <initialize_lists+0x18>
  }
}
    80001924:	6422                	ld	s0,8(sp)
    80001926:	0141                	addi	sp,sp,16
    80001928:	8082                	ret

000000008000192a <initialize_proc>:

void
initialize_proc(struct proc *p){
    8000192a:	1141                	addi	sp,sp,-16
    8000192c:	e422                	sd	s0,8(sp)
    8000192e:	0800                	addi	s0,sp,16
  p->next_index = -1;
    80001930:	57fd                	li	a5,-1
    80001932:	16f52a23          	sw	a5,372(a0)
  p->prev_index = -1;
    80001936:	16f52823          	sw	a5,368(a0)
}
    8000193a:	6422                	ld	s0,8(sp)
    8000193c:	0141                	addi	sp,sp,16
    8000193e:	8082                	ret

0000000080001940 <isEmpty>:

int
isEmpty(struct _list *lst){
    80001940:	1141                	addi	sp,sp,-16
    80001942:	e422                	sd	s0,8(sp)
    80001944:	0800                	addi	s0,sp,16
  return lst->head == -1;
    80001946:	4108                	lw	a0,0(a0)
    80001948:	0505                	addi	a0,a0,1
}
    8000194a:	00153513          	seqz	a0,a0
    8000194e:	6422                	ld	s0,8(sp)
    80001950:	0141                	addi	sp,sp,16
    80001952:	8082                	ret

0000000080001954 <get_head>:
  printf("after remove: \n");
  print_list(*lst); // delete
}
*/
int 
get_head(struct _list *lst){
    80001954:	1101                	addi	sp,sp,-32
    80001956:	ec06                	sd	ra,24(sp)
    80001958:	e822                	sd	s0,16(sp)
    8000195a:	e426                	sd	s1,8(sp)
    8000195c:	e04a                	sd	s2,0(sp)
    8000195e:	1000                	addi	s0,sp,32
    80001960:	84aa                	mv	s1,a0
  acquire(&lst->head_lock); 
    80001962:	00850913          	addi	s2,a0,8
    80001966:	854a                	mv	a0,s2
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	27c080e7          	jalr	636(ra) # 80000be4 <acquire>
  int output = lst->head;
    80001970:	4084                	lw	s1,0(s1)
  release(&lst->head_lock);
    80001972:	854a                	mv	a0,s2
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	324080e7          	jalr	804(ra) # 80000c98 <release>
  return output;
}
    8000197c:	8526                	mv	a0,s1
    8000197e:	60e2                	ld	ra,24(sp)
    80001980:	6442                	ld	s0,16(sp)
    80001982:	64a2                	ld	s1,8(sp)
    80001984:	6902                	ld	s2,0(sp)
    80001986:	6105                	addi	sp,sp,32
    80001988:	8082                	ret

000000008000198a <set_prev_proc>:

void set_prev_proc(struct proc *p, int value){
    8000198a:	1141                	addi	sp,sp,-16
    8000198c:	e422                	sd	s0,8(sp)
    8000198e:	0800                	addi	s0,sp,16
  p->prev_index = value; 
    80001990:	16b52823          	sw	a1,368(a0)
}
    80001994:	6422                	ld	s0,8(sp)
    80001996:	0141                	addi	sp,sp,16
    80001998:	8082                	ret

000000008000199a <set_next_proc>:

void set_next_proc(struct proc *p, int value){
    8000199a:	1141                	addi	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	addi	s0,sp,16
  p->next_index = value; 
    800019a0:	16b52a23          	sw	a1,372(a0)
}
    800019a4:	6422                	ld	s0,8(sp)
    800019a6:	0141                	addi	sp,sp,16
    800019a8:	8082                	ret

00000000800019aa <insert_proc_to_list>:

void 
insert_proc_to_list(struct _list *lst, struct proc *p){
    800019aa:	711d                	addi	sp,sp,-96
    800019ac:	ec86                	sd	ra,88(sp)
    800019ae:	e8a2                	sd	s0,80(sp)
    800019b0:	e4a6                	sd	s1,72(sp)
    800019b2:	e0ca                	sd	s2,64(sp)
    800019b4:	fc4e                	sd	s3,56(sp)
    800019b6:	f852                	sd	s4,48(sp)
    800019b8:	f456                	sd	s5,40(sp)
    800019ba:	f05a                	sd	s6,32(sp)
    800019bc:	1080                	addi	s0,sp,96
    800019be:	892a                	mv	s2,a0
    800019c0:	8aae                	mv	s5,a1
  printf("before insert: \n");
    800019c2:	00007517          	auipc	a0,0x7
    800019c6:	82e50513          	addi	a0,a0,-2002 # 800081f0 <digits+0x1b0>
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	bbe080e7          	jalr	-1090(ra) # 80000588 <printf>
  print_list(*lst); // delete
    800019d2:	00093603          	ld	a2,0(s2) # 1000 <_entry-0x7ffff000>
    800019d6:	00893683          	ld	a3,8(s2)
    800019da:	01093703          	ld	a4,16(s2)
    800019de:	01893783          	ld	a5,24(s2)
    800019e2:	fac43023          	sd	a2,-96(s0)
    800019e6:	fad43423          	sd	a3,-88(s0)
    800019ea:	fae43823          	sd	a4,-80(s0)
    800019ee:	faf43c23          	sd	a5,-72(s0)
    800019f2:	fa040513          	addi	a0,s0,-96
    800019f6:	00000097          	auipc	ra,0x0
    800019fa:	e48080e7          	jalr	-440(ra) # 8000183e <print_list>

  acquire(&lst->head_lock);
    800019fe:	00890993          	addi	s3,s2,8
    80001a02:	854e                	mv	a0,s3
    80001a04:	fffff097          	auipc	ra,0xfffff
    80001a08:	1e0080e7          	jalr	480(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80001a0c:	00092503          	lw	a0,0(s2)
  if(isEmpty(lst)){
    80001a10:	57fd                	li	a5,-1
    80001a12:	00f51c63          	bne	a0,a5,80001a2a <insert_proc_to_list+0x80>
    lst->head = p->index;
    80001a16:	16caa783          	lw	a5,364(s5)
    80001a1a:	00f92023          	sw	a5,0(s2)
    release(&lst->head_lock);
    80001a1e:	854e                	mv	a0,s3
    80001a20:	fffff097          	auipc	ra,0xfffff
    80001a24:	278080e7          	jalr	632(ra) # 80000c98 <release>
    80001a28:	a849                	j	80001aba <insert_proc_to_list+0x110>
  }
  else{ 
    struct proc *curr = &proc[lst->head];
    80001a2a:	19000793          	li	a5,400
    80001a2e:	02f50533          	mul	a0,a0,a5
    80001a32:	00010797          	auipc	a5,0x10
    80001a36:	e1e78793          	addi	a5,a5,-482 # 80011850 <proc>
    80001a3a:	00f504b3          	add	s1,a0,a5
    acquire(&curr->node_lock);
    80001a3e:	17850513          	addi	a0,a0,376
    80001a42:	953e                	add	a0,a0,a5
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
    release(&lst->head_lock);
    80001a4c:	854e                	mv	a0,s3
    80001a4e:	fffff097          	auipc	ra,0xfffff
    80001a52:	24a080e7          	jalr	586(ra) # 80000c98 <release>
    while(curr->next_index != -1){ // search tail
    80001a56:	1744a783          	lw	a5,372(s1)
    80001a5a:	577d                	li	a4,-1
    80001a5c:	04e78163          	beq	a5,a4,80001a9e <insert_proc_to_list+0xf4>
      acquire(&proc[curr->next_index].node_lock);
    80001a60:	19000a13          	li	s4,400
    80001a64:	00010997          	auipc	s3,0x10
    80001a68:	dec98993          	addi	s3,s3,-532 # 80011850 <proc>
    while(curr->next_index != -1){ // search tail
    80001a6c:	5b7d                	li	s6,-1
      acquire(&proc[curr->next_index].node_lock);
    80001a6e:	034787b3          	mul	a5,a5,s4
    80001a72:	17878513          	addi	a0,a5,376
    80001a76:	954e                	add	a0,a0,s3
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	16c080e7          	jalr	364(ra) # 80000be4 <acquire>
      release(&curr->node_lock);
    80001a80:	17848513          	addi	a0,s1,376
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	214080e7          	jalr	532(ra) # 80000c98 <release>
      curr = &proc[curr->next_index];
    80001a8c:	1744a483          	lw	s1,372(s1)
    80001a90:	034484b3          	mul	s1,s1,s4
    80001a94:	94ce                	add	s1,s1,s3
    while(curr->next_index != -1){ // search tail
    80001a96:	1744a783          	lw	a5,372(s1)
    80001a9a:	fd679ae3          	bne	a5,s6,80001a6e <insert_proc_to_list+0xc4>
    }
    set_next_proc(curr, p->index);  // update next proc of the curr tail
    80001a9e:	16caa783          	lw	a5,364(s5)
  p->next_index = value; 
    80001aa2:	16f4aa23          	sw	a5,372(s1)
    set_prev_proc(p, curr->index); // update the prev proc of the new proc
    80001aa6:	16c4a783          	lw	a5,364(s1)
  p->prev_index = value; 
    80001aaa:	16faa823          	sw	a5,368(s5)
    release(&curr->node_lock);
    80001aae:	17848513          	addi	a0,s1,376
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	1e6080e7          	jalr	486(ra) # 80000c98 <release>
  }
  printf("after insert: \n");
    80001aba:	00006517          	auipc	a0,0x6
    80001abe:	74e50513          	addi	a0,a0,1870 # 80008208 <digits+0x1c8>
    80001ac2:	fffff097          	auipc	ra,0xfffff
    80001ac6:	ac6080e7          	jalr	-1338(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001aca:	00093603          	ld	a2,0(s2)
    80001ace:	00893683          	ld	a3,8(s2)
    80001ad2:	01093703          	ld	a4,16(s2)
    80001ad6:	01893783          	ld	a5,24(s2)
    80001ada:	fac43023          	sd	a2,-96(s0)
    80001ade:	fad43423          	sd	a3,-88(s0)
    80001ae2:	fae43823          	sd	a4,-80(s0)
    80001ae6:	faf43c23          	sd	a5,-72(s0)
    80001aea:	fa040513          	addi	a0,s0,-96
    80001aee:	00000097          	auipc	ra,0x0
    80001af2:	d50080e7          	jalr	-688(ra) # 8000183e <print_list>
}
    80001af6:	60e6                	ld	ra,88(sp)
    80001af8:	6446                	ld	s0,80(sp)
    80001afa:	64a6                	ld	s1,72(sp)
    80001afc:	6906                	ld	s2,64(sp)
    80001afe:	79e2                	ld	s3,56(sp)
    80001b00:	7a42                	ld	s4,48(sp)
    80001b02:	7aa2                	ld	s5,40(sp)
    80001b04:	7b02                	ld	s6,32(sp)
    80001b06:	6125                	addi	sp,sp,96
    80001b08:	8082                	ret

0000000080001b0a <remove_proc_to_list>:

void 
remove_proc_to_list(struct _list *lst, struct proc *p){
    80001b0a:	711d                	addi	sp,sp,-96
    80001b0c:	ec86                	sd	ra,88(sp)
    80001b0e:	e8a2                	sd	s0,80(sp)
    80001b10:	e4a6                	sd	s1,72(sp)
    80001b12:	e0ca                	sd	s2,64(sp)
    80001b14:	fc4e                	sd	s3,56(sp)
    80001b16:	f852                	sd	s4,48(sp)
    80001b18:	f456                	sd	s5,40(sp)
    80001b1a:	f05a                	sd	s6,32(sp)
    80001b1c:	1080                	addi	s0,sp,96
    80001b1e:	892a                	mv	s2,a0
    80001b20:	89ae                	mv	s3,a1
  printf("before remove: \n");
    80001b22:	00006517          	auipc	a0,0x6
    80001b26:	6f650513          	addi	a0,a0,1782 # 80008218 <digits+0x1d8>
    80001b2a:	fffff097          	auipc	ra,0xfffff
    80001b2e:	a5e080e7          	jalr	-1442(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001b32:	00093603          	ld	a2,0(s2)
    80001b36:	00893683          	ld	a3,8(s2)
    80001b3a:	01093703          	ld	a4,16(s2)
    80001b3e:	01893783          	ld	a5,24(s2)
    80001b42:	fac43023          	sd	a2,-96(s0)
    80001b46:	fad43423          	sd	a3,-88(s0)
    80001b4a:	fae43823          	sd	a4,-80(s0)
    80001b4e:	faf43c23          	sd	a5,-72(s0)
    80001b52:	fa040513          	addi	a0,s0,-96
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	ce8080e7          	jalr	-792(ra) # 8000183e <print_list>

  acquire(&lst->head_lock);
    80001b5e:	00890a13          	addi	s4,s2,8
    80001b62:	8552                	mv	a0,s4
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	080080e7          	jalr	128(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80001b6c:	00092503          	lw	a0,0(s2)
  if(isEmpty(lst)){
    80001b70:	57fd                	li	a5,-1
    80001b72:	06f50f63          	beq	a0,a5,80001bf0 <remove_proc_to_list+0xe6>
    panic("Fails in removing the process from the list: the list is empty\n");
  }

  if(lst->head == p->index){ // the required proc is the head
    80001b76:	16c9a783          	lw	a5,364(s3)
    80001b7a:	0aa79063          	bne	a5,a0,80001c1a <remove_proc_to_list+0x110>
    lst->head = p->next_index;
    80001b7e:	1749a783          	lw	a5,372(s3)
    80001b82:	00f92023          	sw	a5,0(s2)
    if(p->next_index != -1)
    80001b86:	577d                	li	a4,-1
    80001b88:	06e79c63          	bne	a5,a4,80001c00 <remove_proc_to_list+0xf6>
      set_prev_proc(&proc[p->next_index], -1);
    release(&lst->head_lock);
    80001b8c:	8552                	mv	a0,s4
    80001b8e:	fffff097          	auipc	ra,0xfffff
    80001b92:	10a080e7          	jalr	266(ra) # 80000c98 <release>
  p->next_index = -1;
    80001b96:	57fd                	li	a5,-1
    80001b98:	16f9aa23          	sw	a5,372(s3)
  p->prev_index = -1;
    80001b9c:	16f9a823          	sw	a5,368(s3)
    release(&curr->node_lock);
    release(&p->node_lock);
  }
  initialize_proc(p);

  printf("after remove: \n");
    80001ba0:	00006517          	auipc	a0,0x6
    80001ba4:	72050513          	addi	a0,a0,1824 # 800082c0 <digits+0x280>
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	9e0080e7          	jalr	-1568(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001bb0:	00093603          	ld	a2,0(s2)
    80001bb4:	00893683          	ld	a3,8(s2)
    80001bb8:	01093703          	ld	a4,16(s2)
    80001bbc:	01893783          	ld	a5,24(s2)
    80001bc0:	fac43023          	sd	a2,-96(s0)
    80001bc4:	fad43423          	sd	a3,-88(s0)
    80001bc8:	fae43823          	sd	a4,-80(s0)
    80001bcc:	faf43c23          	sd	a5,-72(s0)
    80001bd0:	fa040513          	addi	a0,s0,-96
    80001bd4:	00000097          	auipc	ra,0x0
    80001bd8:	c6a080e7          	jalr	-918(ra) # 8000183e <print_list>
}
    80001bdc:	60e6                	ld	ra,88(sp)
    80001bde:	6446                	ld	s0,80(sp)
    80001be0:	64a6                	ld	s1,72(sp)
    80001be2:	6906                	ld	s2,64(sp)
    80001be4:	79e2                	ld	s3,56(sp)
    80001be6:	7a42                	ld	s4,48(sp)
    80001be8:	7aa2                	ld	s5,40(sp)
    80001bea:	7b02                	ld	s6,32(sp)
    80001bec:	6125                	addi	sp,sp,96
    80001bee:	8082                	ret
    panic("Fails in removing the process from the list: the list is empty\n");
    80001bf0:	00006517          	auipc	a0,0x6
    80001bf4:	64050513          	addi	a0,a0,1600 # 80008230 <digits+0x1f0>
    80001bf8:	fffff097          	auipc	ra,0xfffff
    80001bfc:	946080e7          	jalr	-1722(ra) # 8000053e <panic>
  p->prev_index = value; 
    80001c00:	19000713          	li	a4,400
    80001c04:	02e787b3          	mul	a5,a5,a4
    80001c08:	00010717          	auipc	a4,0x10
    80001c0c:	c4870713          	addi	a4,a4,-952 # 80011850 <proc>
    80001c10:	97ba                	add	a5,a5,a4
    80001c12:	577d                	li	a4,-1
    80001c14:	16e7a823          	sw	a4,368(a5)
}
    80001c18:	bf95                	j	80001b8c <remove_proc_to_list+0x82>
    struct proc *curr = &proc[lst->head];
    80001c1a:	19000793          	li	a5,400
    80001c1e:	02f50533          	mul	a0,a0,a5
    80001c22:	00010797          	auipc	a5,0x10
    80001c26:	c2e78793          	addi	a5,a5,-978 # 80011850 <proc>
    80001c2a:	00f504b3          	add	s1,a0,a5
    acquire(&curr->node_lock);
    80001c2e:	17850513          	addi	a0,a0,376
    80001c32:	953e                	add	a0,a0,a5
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	fb0080e7          	jalr	-80(ra) # 80000be4 <acquire>
    release(&lst->head_lock);
    80001c3c:	8552                	mv	a0,s4
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	05a080e7          	jalr	90(ra) # 80000c98 <release>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001c46:	1744a783          	lw	a5,372(s1)
    80001c4a:	16c9a703          	lw	a4,364(s3)
    80001c4e:	5b7d                	li	s6,-1
      acquire(&proc[curr->next_index].node_lock);
    80001c50:	19000a93          	li	s5,400
    80001c54:	00010a17          	auipc	s4,0x10
    80001c58:	bfca0a13          	addi	s4,s4,-1028 # 80011850 <proc>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001c5c:	08f70563          	beq	a4,a5,80001ce6 <remove_proc_to_list+0x1dc>
    80001c60:	09678563          	beq	a5,s6,80001cea <remove_proc_to_list+0x1e0>
      acquire(&proc[curr->next_index].node_lock);
    80001c64:	035787b3          	mul	a5,a5,s5
    80001c68:	17878513          	addi	a0,a5,376
    80001c6c:	9552                	add	a0,a0,s4
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	f76080e7          	jalr	-138(ra) # 80000be4 <acquire>
      release(&curr->node_lock);
    80001c76:	17848513          	addi	a0,s1,376
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	01e080e7          	jalr	30(ra) # 80000c98 <release>
      curr = &proc[curr->next_index];
    80001c82:	1744a483          	lw	s1,372(s1)
    80001c86:	035484b3          	mul	s1,s1,s5
    80001c8a:	94d2                	add	s1,s1,s4
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001c8c:	1744a783          	lw	a5,372(s1)
    80001c90:	16c9a703          	lw	a4,364(s3)
    80001c94:	fce796e3          	bne	a5,a4,80001c60 <remove_proc_to_list+0x156>
    if(curr->next_index == -1){
    80001c98:	57fd                	li	a5,-1
    80001c9a:	04f70863          	beq	a4,a5,80001cea <remove_proc_to_list+0x1e0>
    acquire(&p->node_lock); // curr is p->prev
    80001c9e:	17898a13          	addi	s4,s3,376
    80001ca2:	8552                	mv	a0,s4
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	f40080e7          	jalr	-192(ra) # 80000be4 <acquire>
    set_next_proc(curr, p->next_index);
    80001cac:	1749a783          	lw	a5,372(s3)
  p->next_index = value; 
    80001cb0:	16f4aa23          	sw	a5,372(s1)
    set_prev_proc(&proc[p->next_index], curr->index);
    80001cb4:	16c4a683          	lw	a3,364(s1)
  p->prev_index = value; 
    80001cb8:	19000713          	li	a4,400
    80001cbc:	02e787b3          	mul	a5,a5,a4
    80001cc0:	00010717          	auipc	a4,0x10
    80001cc4:	b9070713          	addi	a4,a4,-1136 # 80011850 <proc>
    80001cc8:	97ba                	add	a5,a5,a4
    80001cca:	16d7a823          	sw	a3,368(a5)
    release(&curr->node_lock);
    80001cce:	17848513          	addi	a0,s1,376
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	fc6080e7          	jalr	-58(ra) # 80000c98 <release>
    release(&p->node_lock);
    80001cda:	8552                	mv	a0,s4
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	fbc080e7          	jalr	-68(ra) # 80000c98 <release>
    80001ce4:	bd4d                	j	80001b96 <remove_proc_to_list+0x8c>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001ce6:	873e                	mv	a4,a5
    80001ce8:	bf45                	j	80001c98 <remove_proc_to_list+0x18e>
      panic("Fails in removing the process from the list: process is not found in the list\n");
    80001cea:	00006517          	auipc	a0,0x6
    80001cee:	58650513          	addi	a0,a0,1414 # 80008270 <digits+0x230>
    80001cf2:	fffff097          	auipc	ra,0xfffff
    80001cf6:	84c080e7          	jalr	-1972(ra) # 8000053e <panic>

0000000080001cfa <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001cfa:	7139                	addi	sp,sp,-64
    80001cfc:	fc06                	sd	ra,56(sp)
    80001cfe:	f822                	sd	s0,48(sp)
    80001d00:	f426                	sd	s1,40(sp)
    80001d02:	f04a                	sd	s2,32(sp)
    80001d04:	ec4e                	sd	s3,24(sp)
    80001d06:	e852                	sd	s4,16(sp)
    80001d08:	e456                	sd	s5,8(sp)
    80001d0a:	e05a                	sd	s6,0(sp)
    80001d0c:	0080                	addi	s0,sp,64
    80001d0e:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d10:	00010497          	auipc	s1,0x10
    80001d14:	b4048493          	addi	s1,s1,-1216 # 80011850 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001d18:	8b26                	mv	s6,s1
    80001d1a:	00006a97          	auipc	s5,0x6
    80001d1e:	2e6a8a93          	addi	s5,s5,742 # 80008000 <etext>
    80001d22:	04000937          	lui	s2,0x4000
    80001d26:	197d                	addi	s2,s2,-1
    80001d28:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d2a:	00016a17          	auipc	s4,0x16
    80001d2e:	f26a0a13          	addi	s4,s4,-218 # 80017c50 <tickslock>
    char *pa = kalloc();
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	dc2080e7          	jalr	-574(ra) # 80000af4 <kalloc>
    80001d3a:	862a                	mv	a2,a0
    if(pa == 0)
    80001d3c:	c131                	beqz	a0,80001d80 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001d3e:	416485b3          	sub	a1,s1,s6
    80001d42:	8591                	srai	a1,a1,0x4
    80001d44:	000ab783          	ld	a5,0(s5)
    80001d48:	02f585b3          	mul	a1,a1,a5
    80001d4c:	2585                	addiw	a1,a1,1
    80001d4e:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001d52:	4719                	li	a4,6
    80001d54:	6685                	lui	a3,0x1
    80001d56:	40b905b3          	sub	a1,s2,a1
    80001d5a:	854e                	mv	a0,s3
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	3f4080e7          	jalr	1012(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d64:	19048493          	addi	s1,s1,400
    80001d68:	fd4495e3          	bne	s1,s4,80001d32 <proc_mapstacks+0x38>
  }
}
    80001d6c:	70e2                	ld	ra,56(sp)
    80001d6e:	7442                	ld	s0,48(sp)
    80001d70:	74a2                	ld	s1,40(sp)
    80001d72:	7902                	ld	s2,32(sp)
    80001d74:	69e2                	ld	s3,24(sp)
    80001d76:	6a42                	ld	s4,16(sp)
    80001d78:	6aa2                	ld	s5,8(sp)
    80001d7a:	6b02                	ld	s6,0(sp)
    80001d7c:	6121                	addi	sp,sp,64
    80001d7e:	8082                	ret
      panic("kalloc");
    80001d80:	00006517          	auipc	a0,0x6
    80001d84:	55050513          	addi	a0,a0,1360 # 800082d0 <digits+0x290>
    80001d88:	ffffe097          	auipc	ra,0xffffe
    80001d8c:	7b6080e7          	jalr	1974(ra) # 8000053e <panic>

0000000080001d90 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001d90:	711d                	addi	sp,sp,-96
    80001d92:	ec86                	sd	ra,88(sp)
    80001d94:	e8a2                	sd	s0,80(sp)
    80001d96:	e4a6                	sd	s1,72(sp)
    80001d98:	e0ca                	sd	s2,64(sp)
    80001d9a:	fc4e                	sd	s3,56(sp)
    80001d9c:	f852                	sd	s4,48(sp)
    80001d9e:	f456                	sd	s5,40(sp)
    80001da0:	f05a                	sd	s6,32(sp)
    80001da2:	ec5e                	sd	s7,24(sp)
    80001da4:	e862                	sd	s8,16(sp)
    80001da6:	e466                	sd	s9,8(sp)
    80001da8:	e06a                	sd	s10,0(sp)
    80001daa:	1080                	addi	s0,sp,96
  struct proc *p;

  initialize_lists();
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	b44080e7          	jalr	-1212(ra) # 800018f0 <initialize_lists>

  initlock(&pid_lock, "nextpid");
    80001db4:	00006597          	auipc	a1,0x6
    80001db8:	52458593          	addi	a1,a1,1316 # 800082d8 <digits+0x298>
    80001dbc:	00010517          	auipc	a0,0x10
    80001dc0:	a6450513          	addi	a0,a0,-1436 # 80011820 <pid_lock>
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	d90080e7          	jalr	-624(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001dcc:	00006597          	auipc	a1,0x6
    80001dd0:	51458593          	addi	a1,a1,1300 # 800082e0 <digits+0x2a0>
    80001dd4:	00010517          	auipc	a0,0x10
    80001dd8:	a6450513          	addi	a0,a0,-1436 # 80011838 <wait_lock>
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	d78080e7          	jalr	-648(ra) # 80000b54 <initlock>

  int i = 0;
    80001de4:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001de6:	00010497          	auipc	s1,0x10
    80001dea:	a6a48493          	addi	s1,s1,-1430 # 80011850 <proc>
      initlock(&p->lock, "proc");
    80001dee:	00006d17          	auipc	s10,0x6
    80001df2:	502d0d13          	addi	s10,s10,1282 # 800082f0 <digits+0x2b0>
      p->kstack = KSTACK((int) (p - proc));
    80001df6:	8ca6                	mv	s9,s1
    80001df8:	00006c17          	auipc	s8,0x6
    80001dfc:	208c0c13          	addi	s8,s8,520 # 80008000 <etext>
    80001e00:	04000a37          	lui	s4,0x4000
    80001e04:	1a7d                	addi	s4,s4,-1
    80001e06:	0a32                	slli	s4,s4,0xc
  p->next_index = -1;
    80001e08:	59fd                	li	s3,-1
      p->index = i;
      initialize_proc(p);
      printf("insert procinit unused %d\n", p->index); //delete
    80001e0a:	00006b97          	auipc	s7,0x6
    80001e0e:	4eeb8b93          	addi	s7,s7,1262 # 800082f8 <digits+0x2b8>
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001e12:	00007b17          	auipc	s6,0x7
    80001e16:	d0eb0b13          	addi	s6,s6,-754 # 80008b20 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e1a:	00016a97          	auipc	s5,0x16
    80001e1e:	e36a8a93          	addi	s5,s5,-458 # 80017c50 <tickslock>
      initlock(&p->lock, "proc");
    80001e22:	85ea                	mv	a1,s10
    80001e24:	8526                	mv	a0,s1
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	d2e080e7          	jalr	-722(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001e2e:	419487b3          	sub	a5,s1,s9
    80001e32:	8791                	srai	a5,a5,0x4
    80001e34:	000c3703          	ld	a4,0(s8)
    80001e38:	02e787b3          	mul	a5,a5,a4
    80001e3c:	2785                	addiw	a5,a5,1
    80001e3e:	00d7979b          	slliw	a5,a5,0xd
    80001e42:	40fa07b3          	sub	a5,s4,a5
    80001e46:	e0bc                	sd	a5,64(s1)
      p->index = i;
    80001e48:	1724a623          	sw	s2,364(s1)
  p->next_index = -1;
    80001e4c:	1734aa23          	sw	s3,372(s1)
  p->prev_index = -1;
    80001e50:	1734a823          	sw	s3,368(s1)
      printf("insert procinit unused %d\n", p->index); //delete
    80001e54:	85ca                	mv	a1,s2
    80001e56:	855e                	mv	a0,s7
    80001e58:	ffffe097          	auipc	ra,0xffffe
    80001e5c:	730080e7          	jalr	1840(ra) # 80000588 <printf>
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001e60:	85a6                	mv	a1,s1
    80001e62:	855a                	mv	a0,s6
    80001e64:	00000097          	auipc	ra,0x0
    80001e68:	b46080e7          	jalr	-1210(ra) # 800019aa <insert_proc_to_list>
      i++;
    80001e6c:	2905                	addiw	s2,s2,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e6e:	19048493          	addi	s1,s1,400
    80001e72:	fb5498e3          	bne	s1,s5,80001e22 <procinit+0x92>
  }
}
    80001e76:	60e6                	ld	ra,88(sp)
    80001e78:	6446                	ld	s0,80(sp)
    80001e7a:	64a6                	ld	s1,72(sp)
    80001e7c:	6906                	ld	s2,64(sp)
    80001e7e:	79e2                	ld	s3,56(sp)
    80001e80:	7a42                	ld	s4,48(sp)
    80001e82:	7aa2                	ld	s5,40(sp)
    80001e84:	7b02                	ld	s6,32(sp)
    80001e86:	6be2                	ld	s7,24(sp)
    80001e88:	6c42                	ld	s8,16(sp)
    80001e8a:	6ca2                	ld	s9,8(sp)
    80001e8c:	6d02                	ld	s10,0(sp)
    80001e8e:	6125                	addi	sp,sp,96
    80001e90:	8082                	ret

0000000080001e92 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001e92:	1141                	addi	sp,sp,-16
    80001e94:	e422                	sd	s0,8(sp)
    80001e96:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e98:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001e9a:	2501                	sext.w	a0,a0
    80001e9c:	6422                	ld	s0,8(sp)
    80001e9e:	0141                	addi	sp,sp,16
    80001ea0:	8082                	ret

0000000080001ea2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001ea2:	1141                	addi	sp,sp,-16
    80001ea4:	e422                	sd	s0,8(sp)
    80001ea6:	0800                	addi	s0,sp,16
    80001ea8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001eaa:	2781                	sext.w	a5,a5
    80001eac:	0b000513          	li	a0,176
    80001eb0:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001eb4:	0000f517          	auipc	a0,0xf
    80001eb8:	3ec50513          	addi	a0,a0,1004 # 800112a0 <cpus>
    80001ebc:	953e                	add	a0,a0,a5
    80001ebe:	6422                	ld	s0,8(sp)
    80001ec0:	0141                	addi	sp,sp,16
    80001ec2:	8082                	ret

0000000080001ec4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001ec4:	1101                	addi	sp,sp,-32
    80001ec6:	ec06                	sd	ra,24(sp)
    80001ec8:	e822                	sd	s0,16(sp)
    80001eca:	e426                	sd	s1,8(sp)
    80001ecc:	1000                	addi	s0,sp,32
  push_off();
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	cca080e7          	jalr	-822(ra) # 80000b98 <push_off>
    80001ed6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ed8:	2781                	sext.w	a5,a5
    80001eda:	0b000713          	li	a4,176
    80001ede:	02e787b3          	mul	a5,a5,a4
    80001ee2:	0000f717          	auipc	a4,0xf
    80001ee6:	3be70713          	addi	a4,a4,958 # 800112a0 <cpus>
    80001eea:	97ba                	add	a5,a5,a4
    80001eec:	6384                	ld	s1,0(a5)
  pop_off();
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	d4a080e7          	jalr	-694(ra) # 80000c38 <pop_off>
  return p;
}
    80001ef6:	8526                	mv	a0,s1
    80001ef8:	60e2                	ld	ra,24(sp)
    80001efa:	6442                	ld	s0,16(sp)
    80001efc:	64a2                	ld	s1,8(sp)
    80001efe:	6105                	addi	sp,sp,32
    80001f00:	8082                	ret

0000000080001f02 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001f02:	1141                	addi	sp,sp,-16
    80001f04:	e406                	sd	ra,8(sp)
    80001f06:	e022                	sd	s0,0(sp)
    80001f08:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001f0a:	00000097          	auipc	ra,0x0
    80001f0e:	fba080e7          	jalr	-70(ra) # 80001ec4 <myproc>
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	d86080e7          	jalr	-634(ra) # 80000c98 <release>

  if (first) {
    80001f1a:	00007797          	auipc	a5,0x7
    80001f1e:	bf67a783          	lw	a5,-1034(a5) # 80008b10 <first.1777>
    80001f22:	eb89                	bnez	a5,80001f34 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001f24:	00001097          	auipc	ra,0x1
    80001f28:	06c080e7          	jalr	108(ra) # 80002f90 <usertrapret>
}
    80001f2c:	60a2                	ld	ra,8(sp)
    80001f2e:	6402                	ld	s0,0(sp)
    80001f30:	0141                	addi	sp,sp,16
    80001f32:	8082                	ret
    first = 0;
    80001f34:	00007797          	auipc	a5,0x7
    80001f38:	bc07ae23          	sw	zero,-1060(a5) # 80008b10 <first.1777>
    fsinit(ROOTDEV);
    80001f3c:	4505                	li	a0,1
    80001f3e:	00002097          	auipc	ra,0x2
    80001f42:	e10080e7          	jalr	-496(ra) # 80003d4e <fsinit>
    80001f46:	bff9                	j	80001f24 <forkret+0x22>

0000000080001f48 <allocpid>:
allocpid() {
    80001f48:	1101                	addi	sp,sp,-32
    80001f4a:	ec06                	sd	ra,24(sp)
    80001f4c:	e822                	sd	s0,16(sp)
    80001f4e:	e426                	sd	s1,8(sp)
    80001f50:	e04a                	sd	s2,0(sp)
    80001f52:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001f54:	00007917          	auipc	s2,0x7
    80001f58:	bc090913          	addi	s2,s2,-1088 # 80008b14 <nextpid>
    80001f5c:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, nextpid + 1));
    80001f60:	0014861b          	addiw	a2,s1,1
    80001f64:	85a6                	mv	a1,s1
    80001f66:	854a                	mv	a0,s2
    80001f68:	00005097          	auipc	ra,0x5
    80001f6c:	bee080e7          	jalr	-1042(ra) # 80006b56 <cas>
    80001f70:	2501                	sext.w	a0,a0
    80001f72:	f56d                	bnez	a0,80001f5c <allocpid+0x14>
}
    80001f74:	8526                	mv	a0,s1
    80001f76:	60e2                	ld	ra,24(sp)
    80001f78:	6442                	ld	s0,16(sp)
    80001f7a:	64a2                	ld	s1,8(sp)
    80001f7c:	6902                	ld	s2,0(sp)
    80001f7e:	6105                	addi	sp,sp,32
    80001f80:	8082                	ret

0000000080001f82 <proc_pagetable>:
{
    80001f82:	1101                	addi	sp,sp,-32
    80001f84:	ec06                	sd	ra,24(sp)
    80001f86:	e822                	sd	s0,16(sp)
    80001f88:	e426                	sd	s1,8(sp)
    80001f8a:	e04a                	sd	s2,0(sp)
    80001f8c:	1000                	addi	s0,sp,32
    80001f8e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	3aa080e7          	jalr	938(ra) # 8000133a <uvmcreate>
    80001f98:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001f9a:	c121                	beqz	a0,80001fda <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001f9c:	4729                	li	a4,10
    80001f9e:	00005697          	auipc	a3,0x5
    80001fa2:	06268693          	addi	a3,a3,98 # 80007000 <_trampoline>
    80001fa6:	6605                	lui	a2,0x1
    80001fa8:	040005b7          	lui	a1,0x4000
    80001fac:	15fd                	addi	a1,a1,-1
    80001fae:	05b2                	slli	a1,a1,0xc
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	100080e7          	jalr	256(ra) # 800010b0 <mappages>
    80001fb8:	02054863          	bltz	a0,80001fe8 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001fbc:	4719                	li	a4,6
    80001fbe:	05893683          	ld	a3,88(s2)
    80001fc2:	6605                	lui	a2,0x1
    80001fc4:	020005b7          	lui	a1,0x2000
    80001fc8:	15fd                	addi	a1,a1,-1
    80001fca:	05b6                	slli	a1,a1,0xd
    80001fcc:	8526                	mv	a0,s1
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	0e2080e7          	jalr	226(ra) # 800010b0 <mappages>
    80001fd6:	02054163          	bltz	a0,80001ff8 <proc_pagetable+0x76>
}
    80001fda:	8526                	mv	a0,s1
    80001fdc:	60e2                	ld	ra,24(sp)
    80001fde:	6442                	ld	s0,16(sp)
    80001fe0:	64a2                	ld	s1,8(sp)
    80001fe2:	6902                	ld	s2,0(sp)
    80001fe4:	6105                	addi	sp,sp,32
    80001fe6:	8082                	ret
    uvmfree(pagetable, 0);
    80001fe8:	4581                	li	a1,0
    80001fea:	8526                	mv	a0,s1
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	54a080e7          	jalr	1354(ra) # 80001536 <uvmfree>
    return 0;
    80001ff4:	4481                	li	s1,0
    80001ff6:	b7d5                	j	80001fda <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ff8:	4681                	li	a3,0
    80001ffa:	4605                	li	a2,1
    80001ffc:	040005b7          	lui	a1,0x4000
    80002000:	15fd                	addi	a1,a1,-1
    80002002:	05b2                	slli	a1,a1,0xc
    80002004:	8526                	mv	a0,s1
    80002006:	fffff097          	auipc	ra,0xfffff
    8000200a:	270080e7          	jalr	624(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    8000200e:	4581                	li	a1,0
    80002010:	8526                	mv	a0,s1
    80002012:	fffff097          	auipc	ra,0xfffff
    80002016:	524080e7          	jalr	1316(ra) # 80001536 <uvmfree>
    return 0;
    8000201a:	4481                	li	s1,0
    8000201c:	bf7d                	j	80001fda <proc_pagetable+0x58>

000000008000201e <proc_freepagetable>:
{
    8000201e:	1101                	addi	sp,sp,-32
    80002020:	ec06                	sd	ra,24(sp)
    80002022:	e822                	sd	s0,16(sp)
    80002024:	e426                	sd	s1,8(sp)
    80002026:	e04a                	sd	s2,0(sp)
    80002028:	1000                	addi	s0,sp,32
    8000202a:	84aa                	mv	s1,a0
    8000202c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    8000202e:	4681                	li	a3,0
    80002030:	4605                	li	a2,1
    80002032:	040005b7          	lui	a1,0x4000
    80002036:	15fd                	addi	a1,a1,-1
    80002038:	05b2                	slli	a1,a1,0xc
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	23c080e7          	jalr	572(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80002042:	4681                	li	a3,0
    80002044:	4605                	li	a2,1
    80002046:	020005b7          	lui	a1,0x2000
    8000204a:	15fd                	addi	a1,a1,-1
    8000204c:	05b6                	slli	a1,a1,0xd
    8000204e:	8526                	mv	a0,s1
    80002050:	fffff097          	auipc	ra,0xfffff
    80002054:	226080e7          	jalr	550(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80002058:	85ca                	mv	a1,s2
    8000205a:	8526                	mv	a0,s1
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	4da080e7          	jalr	1242(ra) # 80001536 <uvmfree>
}
    80002064:	60e2                	ld	ra,24(sp)
    80002066:	6442                	ld	s0,16(sp)
    80002068:	64a2                	ld	s1,8(sp)
    8000206a:	6902                	ld	s2,0(sp)
    8000206c:	6105                	addi	sp,sp,32
    8000206e:	8082                	ret

0000000080002070 <freeproc>:
{
    80002070:	1101                	addi	sp,sp,-32
    80002072:	ec06                	sd	ra,24(sp)
    80002074:	e822                	sd	s0,16(sp)
    80002076:	e426                	sd	s1,8(sp)
    80002078:	1000                	addi	s0,sp,32
    8000207a:	84aa                	mv	s1,a0
  if(p->trapframe)
    8000207c:	6d28                	ld	a0,88(a0)
    8000207e:	c509                	beqz	a0,80002088 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80002080:	fffff097          	auipc	ra,0xfffff
    80002084:	978080e7          	jalr	-1672(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80002088:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    8000208c:	68a8                	ld	a0,80(s1)
    8000208e:	c511                	beqz	a0,8000209a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002090:	64ac                	ld	a1,72(s1)
    80002092:	00000097          	auipc	ra,0x0
    80002096:	f8c080e7          	jalr	-116(ra) # 8000201e <proc_freepagetable>
  p->pagetable = 0;
    8000209a:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    8000209e:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    800020a2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    800020a6:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    800020aa:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    800020ae:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    800020b2:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    800020b6:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    800020ba:	0004ac23          	sw	zero,24(s1)
  printf("remove free proc zombie %d\n", p->index); //delete
    800020be:	16c4a583          	lw	a1,364(s1)
    800020c2:	00006517          	auipc	a0,0x6
    800020c6:	25650513          	addi	a0,a0,598 # 80008318 <digits+0x2d8>
    800020ca:	ffffe097          	auipc	ra,0xffffe
    800020ce:	4be080e7          	jalr	1214(ra) # 80000588 <printf>
  remove_proc_to_list(&zombie_list, p); // remove the freed process from the ZOMBIE list
    800020d2:	85a6                	mv	a1,s1
    800020d4:	00007517          	auipc	a0,0x7
    800020d8:	a6c50513          	addi	a0,a0,-1428 # 80008b40 <zombie_list>
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	a2e080e7          	jalr	-1490(ra) # 80001b0a <remove_proc_to_list>
  printf("insert free proc unused %d\n", p->index); //delete
    800020e4:	16c4a583          	lw	a1,364(s1)
    800020e8:	00006517          	auipc	a0,0x6
    800020ec:	25050513          	addi	a0,a0,592 # 80008338 <digits+0x2f8>
    800020f0:	ffffe097          	auipc	ra,0xffffe
    800020f4:	498080e7          	jalr	1176(ra) # 80000588 <printf>
  insert_proc_to_list(&unused_list, p); // admit its entry to the UNUSED entry list.
    800020f8:	85a6                	mv	a1,s1
    800020fa:	00007517          	auipc	a0,0x7
    800020fe:	a2650513          	addi	a0,a0,-1498 # 80008b20 <unused_list>
    80002102:	00000097          	auipc	ra,0x0
    80002106:	8a8080e7          	jalr	-1880(ra) # 800019aa <insert_proc_to_list>
}
    8000210a:	60e2                	ld	ra,24(sp)
    8000210c:	6442                	ld	s0,16(sp)
    8000210e:	64a2                	ld	s1,8(sp)
    80002110:	6105                	addi	sp,sp,32
    80002112:	8082                	ret

0000000080002114 <allocproc>:
{
    80002114:	715d                	addi	sp,sp,-80
    80002116:	e486                	sd	ra,72(sp)
    80002118:	e0a2                	sd	s0,64(sp)
    8000211a:	fc26                	sd	s1,56(sp)
    8000211c:	f84a                	sd	s2,48(sp)
    8000211e:	f44e                	sd	s3,40(sp)
    80002120:	f052                	sd	s4,32(sp)
    80002122:	ec56                	sd	s5,24(sp)
    80002124:	e85a                	sd	s6,16(sp)
    80002126:	e45e                	sd	s7,8(sp)
    80002128:	0880                	addi	s0,sp,80
  while(!isEmpty(&unused_list)){
    8000212a:	00007717          	auipc	a4,0x7
    8000212e:	9f672703          	lw	a4,-1546(a4) # 80008b20 <unused_list>
    80002132:	57fd                	li	a5,-1
    80002134:	14f70a63          	beq	a4,a5,80002288 <allocproc+0x174>
    p = &proc[get_head(&unused_list)];
    80002138:	00007a17          	auipc	s4,0x7
    8000213c:	9e8a0a13          	addi	s4,s4,-1560 # 80008b20 <unused_list>
    80002140:	19000b13          	li	s6,400
    80002144:	0000fa97          	auipc	s5,0xf
    80002148:	70ca8a93          	addi	s5,s5,1804 # 80011850 <proc>
  while(!isEmpty(&unused_list)){
    8000214c:	5bfd                	li	s7,-1
    p = &proc[get_head(&unused_list)];
    8000214e:	8552                	mv	a0,s4
    80002150:	00000097          	auipc	ra,0x0
    80002154:	804080e7          	jalr	-2044(ra) # 80001954 <get_head>
    80002158:	892a                	mv	s2,a0
    8000215a:	036509b3          	mul	s3,a0,s6
    8000215e:	015984b3          	add	s1,s3,s5
    acquire(&p->lock);
    80002162:	8526                	mv	a0,s1
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	a80080e7          	jalr	-1408(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    8000216c:	4c9c                	lw	a5,24(s1)
    8000216e:	c79d                	beqz	a5,8000219c <allocproc+0x88>
      release(&p->lock);
    80002170:	8526                	mv	a0,s1
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	b26080e7          	jalr	-1242(ra) # 80000c98 <release>
  while(!isEmpty(&unused_list)){
    8000217a:	000a2783          	lw	a5,0(s4)
    8000217e:	fd7798e3          	bne	a5,s7,8000214e <allocproc+0x3a>
  return 0;
    80002182:	4481                	li	s1,0
}
    80002184:	8526                	mv	a0,s1
    80002186:	60a6                	ld	ra,72(sp)
    80002188:	6406                	ld	s0,64(sp)
    8000218a:	74e2                	ld	s1,56(sp)
    8000218c:	7942                	ld	s2,48(sp)
    8000218e:	79a2                	ld	s3,40(sp)
    80002190:	7a02                	ld	s4,32(sp)
    80002192:	6ae2                	ld	s5,24(sp)
    80002194:	6b42                	ld	s6,16(sp)
    80002196:	6ba2                	ld	s7,8(sp)
    80002198:	6161                	addi	sp,sp,80
    8000219a:	8082                	ret
      printf("remove allocproc unused %d\n", p->index); //delete
    8000219c:	19000a13          	li	s4,400
    800021a0:	034907b3          	mul	a5,s2,s4
    800021a4:	0000fa17          	auipc	s4,0xf
    800021a8:	6aca0a13          	addi	s4,s4,1708 # 80011850 <proc>
    800021ac:	9a3e                	add	s4,s4,a5
    800021ae:	16ca2583          	lw	a1,364(s4)
    800021b2:	00006517          	auipc	a0,0x6
    800021b6:	1a650513          	addi	a0,a0,422 # 80008358 <digits+0x318>
    800021ba:	ffffe097          	auipc	ra,0xffffe
    800021be:	3ce080e7          	jalr	974(ra) # 80000588 <printf>
      remove_proc_to_list(&unused_list, p); // choose the new process entry to initialize from the UNUSED entry list.
    800021c2:	85a6                	mv	a1,s1
    800021c4:	00007517          	auipc	a0,0x7
    800021c8:	95c50513          	addi	a0,a0,-1700 # 80008b20 <unused_list>
    800021cc:	00000097          	auipc	ra,0x0
    800021d0:	93e080e7          	jalr	-1730(ra) # 80001b0a <remove_proc_to_list>
  p->pid = allocpid();
    800021d4:	00000097          	auipc	ra,0x0
    800021d8:	d74080e7          	jalr	-652(ra) # 80001f48 <allocpid>
    800021dc:	02aa2823          	sw	a0,48(s4)
  p->state = USED;
    800021e0:	4785                	li	a5,1
    800021e2:	00fa2c23          	sw	a5,24(s4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	90e080e7          	jalr	-1778(ra) # 80000af4 <kalloc>
    800021ee:	8aaa                	mv	s5,a0
    800021f0:	04aa3c23          	sd	a0,88(s4)
    800021f4:	c135                	beqz	a0,80002258 <allocproc+0x144>
  p->pagetable = proc_pagetable(p);
    800021f6:	8526                	mv	a0,s1
    800021f8:	00000097          	auipc	ra,0x0
    800021fc:	d8a080e7          	jalr	-630(ra) # 80001f82 <proc_pagetable>
    80002200:	8a2a                	mv	s4,a0
    80002202:	19000793          	li	a5,400
    80002206:	02f90733          	mul	a4,s2,a5
    8000220a:	0000f797          	auipc	a5,0xf
    8000220e:	64678793          	addi	a5,a5,1606 # 80011850 <proc>
    80002212:	97ba                	add	a5,a5,a4
    80002214:	eba8                	sd	a0,80(a5)
  if(p->pagetable == 0){
    80002216:	cd29                	beqz	a0,80002270 <allocproc+0x15c>
  memset(&p->context, 0, sizeof(p->context));
    80002218:	06098513          	addi	a0,s3,96
    8000221c:	0000f997          	auipc	s3,0xf
    80002220:	63498993          	addi	s3,s3,1588 # 80011850 <proc>
    80002224:	07000613          	li	a2,112
    80002228:	4581                	li	a1,0
    8000222a:	954e                	add	a0,a0,s3
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	ab4080e7          	jalr	-1356(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80002234:	19000793          	li	a5,400
    80002238:	02f90933          	mul	s2,s2,a5
    8000223c:	994e                	add	s2,s2,s3
    8000223e:	00000797          	auipc	a5,0x0
    80002242:	cc478793          	addi	a5,a5,-828 # 80001f02 <forkret>
    80002246:	06f93023          	sd	a5,96(s2)
  p->context.sp = p->kstack + PGSIZE;
    8000224a:	04093783          	ld	a5,64(s2)
    8000224e:	6705                	lui	a4,0x1
    80002250:	97ba                	add	a5,a5,a4
    80002252:	06f93423          	sd	a5,104(s2)
  return p;
    80002256:	b73d                	j	80002184 <allocproc+0x70>
    freeproc(p);
    80002258:	8526                	mv	a0,s1
    8000225a:	00000097          	auipc	ra,0x0
    8000225e:	e16080e7          	jalr	-490(ra) # 80002070 <freeproc>
    release(&p->lock);
    80002262:	8526                	mv	a0,s1
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	a34080e7          	jalr	-1484(ra) # 80000c98 <release>
    return 0;
    8000226c:	84d6                	mv	s1,s5
    8000226e:	bf19                	j	80002184 <allocproc+0x70>
    freeproc(p);
    80002270:	8526                	mv	a0,s1
    80002272:	00000097          	auipc	ra,0x0
    80002276:	dfe080e7          	jalr	-514(ra) # 80002070 <freeproc>
    release(&p->lock);
    8000227a:	8526                	mv	a0,s1
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	a1c080e7          	jalr	-1508(ra) # 80000c98 <release>
    return 0;
    80002284:	84d2                	mv	s1,s4
    80002286:	bdfd                	j	80002184 <allocproc+0x70>
  return 0;
    80002288:	4481                	li	s1,0
    8000228a:	bded                	j	80002184 <allocproc+0x70>

000000008000228c <userinit>:
{
    8000228c:	1101                	addi	sp,sp,-32
    8000228e:	ec06                	sd	ra,24(sp)
    80002290:	e822                	sd	s0,16(sp)
    80002292:	e426                	sd	s1,8(sp)
    80002294:	1000                	addi	s0,sp,32
  p = allocproc();
    80002296:	00000097          	auipc	ra,0x0
    8000229a:	e7e080e7          	jalr	-386(ra) # 80002114 <allocproc>
    8000229e:	84aa                	mv	s1,a0
  initproc = p;
    800022a0:	00007797          	auipc	a5,0x7
    800022a4:	d8a7b423          	sd	a0,-632(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800022a8:	03400613          	li	a2,52
    800022ac:	00007597          	auipc	a1,0x7
    800022b0:	8b458593          	addi	a1,a1,-1868 # 80008b60 <initcode>
    800022b4:	6928                	ld	a0,80(a0)
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	0b2080e7          	jalr	178(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    800022be:	6785                	lui	a5,0x1
    800022c0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    800022c2:	6cb8                	ld	a4,88(s1)
    800022c4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800022c8:	6cb8                	ld	a4,88(s1)
    800022ca:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800022cc:	4641                	li	a2,16
    800022ce:	00006597          	auipc	a1,0x6
    800022d2:	0aa58593          	addi	a1,a1,170 # 80008378 <digits+0x338>
    800022d6:	15848513          	addi	a0,s1,344
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	b58080e7          	jalr	-1192(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800022e2:	00006517          	auipc	a0,0x6
    800022e6:	0a650513          	addi	a0,a0,166 # 80008388 <digits+0x348>
    800022ea:	00002097          	auipc	ra,0x2
    800022ee:	492080e7          	jalr	1170(ra) # 8000477c <namei>
    800022f2:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800022f6:	478d                	li	a5,3
    800022f8:	cc9c                	sw	a5,24(s1)
  printf("insert userinit runnable %d\n", p->index); //delete
    800022fa:	16c4a583          	lw	a1,364(s1)
    800022fe:	00006517          	auipc	a0,0x6
    80002302:	09250513          	addi	a0,a0,146 # 80008390 <digits+0x350>
    80002306:	ffffe097          	auipc	ra,0xffffe
    8000230a:	282080e7          	jalr	642(ra) # 80000588 <printf>
  insert_proc_to_list(&(cpus[0].runnable_list), p); // admit the init process (the first process in the OS) to the first CPU’s list.
    8000230e:	85a6                	mv	a1,s1
    80002310:	0000f517          	auipc	a0,0xf
    80002314:	01050513          	addi	a0,a0,16 # 80011320 <cpus+0x80>
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	692080e7          	jalr	1682(ra) # 800019aa <insert_proc_to_list>
  release(&p->lock);
    80002320:	8526                	mv	a0,s1
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	976080e7          	jalr	-1674(ra) # 80000c98 <release>
}
    8000232a:	60e2                	ld	ra,24(sp)
    8000232c:	6442                	ld	s0,16(sp)
    8000232e:	64a2                	ld	s1,8(sp)
    80002330:	6105                	addi	sp,sp,32
    80002332:	8082                	ret

0000000080002334 <growproc>:
{
    80002334:	1101                	addi	sp,sp,-32
    80002336:	ec06                	sd	ra,24(sp)
    80002338:	e822                	sd	s0,16(sp)
    8000233a:	e426                	sd	s1,8(sp)
    8000233c:	e04a                	sd	s2,0(sp)
    8000233e:	1000                	addi	s0,sp,32
    80002340:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002342:	00000097          	auipc	ra,0x0
    80002346:	b82080e7          	jalr	-1150(ra) # 80001ec4 <myproc>
    8000234a:	892a                	mv	s2,a0
  sz = p->sz;
    8000234c:	652c                	ld	a1,72(a0)
    8000234e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002352:	00904f63          	bgtz	s1,80002370 <growproc+0x3c>
  } else if(n < 0){
    80002356:	0204cc63          	bltz	s1,8000238e <growproc+0x5a>
  p->sz = sz;
    8000235a:	1602                	slli	a2,a2,0x20
    8000235c:	9201                	srli	a2,a2,0x20
    8000235e:	04c93423          	sd	a2,72(s2)
  return 0;
    80002362:	4501                	li	a0,0
}
    80002364:	60e2                	ld	ra,24(sp)
    80002366:	6442                	ld	s0,16(sp)
    80002368:	64a2                	ld	s1,8(sp)
    8000236a:	6902                	ld	s2,0(sp)
    8000236c:	6105                	addi	sp,sp,32
    8000236e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002370:	9e25                	addw	a2,a2,s1
    80002372:	1602                	slli	a2,a2,0x20
    80002374:	9201                	srli	a2,a2,0x20
    80002376:	1582                	slli	a1,a1,0x20
    80002378:	9181                	srli	a1,a1,0x20
    8000237a:	6928                	ld	a0,80(a0)
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	0a6080e7          	jalr	166(ra) # 80001422 <uvmalloc>
    80002384:	0005061b          	sext.w	a2,a0
    80002388:	fa69                	bnez	a2,8000235a <growproc+0x26>
      return -1;
    8000238a:	557d                	li	a0,-1
    8000238c:	bfe1                	j	80002364 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000238e:	9e25                	addw	a2,a2,s1
    80002390:	1602                	slli	a2,a2,0x20
    80002392:	9201                	srli	a2,a2,0x20
    80002394:	1582                	slli	a1,a1,0x20
    80002396:	9181                	srli	a1,a1,0x20
    80002398:	6928                	ld	a0,80(a0)
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	040080e7          	jalr	64(ra) # 800013da <uvmdealloc>
    800023a2:	0005061b          	sext.w	a2,a0
    800023a6:	bf55                	j	8000235a <growproc+0x26>

00000000800023a8 <scheduler>:
{
    800023a8:	711d                	addi	sp,sp,-96
    800023aa:	ec86                	sd	ra,88(sp)
    800023ac:	e8a2                	sd	s0,80(sp)
    800023ae:	e4a6                	sd	s1,72(sp)
    800023b0:	e0ca                	sd	s2,64(sp)
    800023b2:	fc4e                	sd	s3,56(sp)
    800023b4:	f852                	sd	s4,48(sp)
    800023b6:	f456                	sd	s5,40(sp)
    800023b8:	f05a                	sd	s6,32(sp)
    800023ba:	ec5e                	sd	s7,24(sp)
    800023bc:	e862                	sd	s8,16(sp)
    800023be:	e466                	sd	s9,8(sp)
    800023c0:	e06a                	sd	s10,0(sp)
    800023c2:	1080                	addi	s0,sp,96
    800023c4:	8712                	mv	a4,tp
  int id = r_tp();
    800023c6:	2701                	sext.w	a4,a4
  c->proc = 0;
    800023c8:	0000fb97          	auipc	s7,0xf
    800023cc:	ed8b8b93          	addi	s7,s7,-296 # 800112a0 <cpus>
    800023d0:	0b000793          	li	a5,176
    800023d4:	02f707b3          	mul	a5,a4,a5
    800023d8:	00fb86b3          	add	a3,s7,a5
    800023dc:	0006b023          	sd	zero,0(a3)
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    800023e0:	08078b13          	addi	s6,a5,128 # 1080 <_entry-0x7fffef80>
    800023e4:	9b5e                	add	s6,s6,s7
          swtch(&c->context, &p->context);
    800023e6:	07a1                	addi	a5,a5,8
    800023e8:	9bbe                	add	s7,s7,a5
  return lst->head == -1;
    800023ea:	89b6                	mv	s3,a3
      if(p->state == RUNNABLE) {
    800023ec:	0000fa17          	auipc	s4,0xf
    800023f0:	464a0a13          	addi	s4,s4,1124 # 80011850 <proc>
    800023f4:	19000a93          	li	s5,400
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023f8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800023fc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002400:	10079073          	csrw	sstatus,a5
    80002404:	4c0d                	li	s8,3
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80002406:	54fd                	li	s1,-1
    80002408:	0809a783          	lw	a5,128(s3)
    8000240c:	fe9786e3          	beq	a5,s1,800023f8 <scheduler+0x50>
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    80002410:	855a                	mv	a0,s6
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	542080e7          	jalr	1346(ra) # 80001954 <get_head>
      if(p->state == RUNNABLE) {
    8000241a:	035507b3          	mul	a5,a0,s5
    8000241e:	97d2                	add	a5,a5,s4
    80002420:	4f9c                	lw	a5,24(a5)
    80002422:	ff8793e3          	bne	a5,s8,80002408 <scheduler+0x60>
    80002426:	03550d33          	mul	s10,a0,s5
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    8000242a:	014d0cb3          	add	s9,s10,s4
        acquire(&p->lock);
    8000242e:	8566                	mv	a0,s9
    80002430:	ffffe097          	auipc	ra,0xffffe
    80002434:	7b4080e7          	jalr	1972(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {  
    80002438:	018ca783          	lw	a5,24(s9)
    8000243c:	01878863          	beq	a5,s8,8000244c <scheduler+0xa4>
        release(&p->lock);
    80002440:	8566                	mv	a0,s9
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	856080e7          	jalr	-1962(ra) # 80000c98 <release>
    8000244a:	bf75                	j	80002406 <scheduler+0x5e>
          printf("remove sched runnable %d\n", p->index); //delete
    8000244c:	16cca583          	lw	a1,364(s9)
    80002450:	00006517          	auipc	a0,0x6
    80002454:	f6050513          	addi	a0,a0,-160 # 800083b0 <digits+0x370>
    80002458:	ffffe097          	auipc	ra,0xffffe
    8000245c:	130080e7          	jalr	304(ra) # 80000588 <printf>
          remove_proc_to_list(&(c->runnable_list), p);
    80002460:	85e6                	mv	a1,s9
    80002462:	855a                	mv	a0,s6
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	6a6080e7          	jalr	1702(ra) # 80001b0a <remove_proc_to_list>
          p->state = RUNNING;
    8000246c:	4791                	li	a5,4
    8000246e:	00fcac23          	sw	a5,24(s9)
          c->proc = p;
    80002472:	0199b023          	sd	s9,0(s3)
          p->last_cpu = c->cpu_id;
    80002476:	0a09a783          	lw	a5,160(s3)
    8000247a:	16fca423          	sw	a5,360(s9)
          printf("before swtch%d\n", p->index); //delete
    8000247e:	16cca583          	lw	a1,364(s9)
    80002482:	00006517          	auipc	a0,0x6
    80002486:	f4e50513          	addi	a0,a0,-178 # 800083d0 <digits+0x390>
    8000248a:	ffffe097          	auipc	ra,0xffffe
    8000248e:	0fe080e7          	jalr	254(ra) # 80000588 <printf>
          swtch(&c->context, &p->context);
    80002492:	060d0593          	addi	a1,s10,96
    80002496:	95d2                	add	a1,a1,s4
    80002498:	855e                	mv	a0,s7
    8000249a:	00001097          	auipc	ra,0x1
    8000249e:	a4c080e7          	jalr	-1460(ra) # 80002ee6 <swtch>
          printf("after swtch%d\n", p->index); //delete
    800024a2:	16cca583          	lw	a1,364(s9)
    800024a6:	00006517          	auipc	a0,0x6
    800024aa:	f3a50513          	addi	a0,a0,-198 # 800083e0 <digits+0x3a0>
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	0da080e7          	jalr	218(ra) # 80000588 <printf>
          c->proc = 0;
    800024b6:	0009b023          	sd	zero,0(s3)
    800024ba:	b759                	j	80002440 <scheduler+0x98>

00000000800024bc <sched>:
{
    800024bc:	7179                	addi	sp,sp,-48
    800024be:	f406                	sd	ra,40(sp)
    800024c0:	f022                	sd	s0,32(sp)
    800024c2:	ec26                	sd	s1,24(sp)
    800024c4:	e84a                	sd	s2,16(sp)
    800024c6:	e44e                	sd	s3,8(sp)
    800024c8:	e052                	sd	s4,0(sp)
    800024ca:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800024cc:	00000097          	auipc	ra,0x0
    800024d0:	9f8080e7          	jalr	-1544(ra) # 80001ec4 <myproc>
    800024d4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800024d6:	ffffe097          	auipc	ra,0xffffe
    800024da:	694080e7          	jalr	1684(ra) # 80000b6a <holding>
    800024de:	c145                	beqz	a0,8000257e <sched+0xc2>
  asm volatile("mv %0, tp" : "=r" (x) );
    800024e0:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800024e2:	2781                	sext.w	a5,a5
    800024e4:	0b000713          	li	a4,176
    800024e8:	02e787b3          	mul	a5,a5,a4
    800024ec:	0000f717          	auipc	a4,0xf
    800024f0:	db470713          	addi	a4,a4,-588 # 800112a0 <cpus>
    800024f4:	97ba                	add	a5,a5,a4
    800024f6:	5fb8                	lw	a4,120(a5)
    800024f8:	4785                	li	a5,1
    800024fa:	08f71a63          	bne	a4,a5,8000258e <sched+0xd2>
  if(p->state == RUNNING)
    800024fe:	4c98                	lw	a4,24(s1)
    80002500:	4791                	li	a5,4
    80002502:	08f70e63          	beq	a4,a5,8000259e <sched+0xe2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002506:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000250a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000250c:	e3cd                	bnez	a5,800025ae <sched+0xf2>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000250e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002510:	0000f917          	auipc	s2,0xf
    80002514:	d9090913          	addi	s2,s2,-624 # 800112a0 <cpus>
    80002518:	2781                	sext.w	a5,a5
    8000251a:	0b000993          	li	s3,176
    8000251e:	033787b3          	mul	a5,a5,s3
    80002522:	97ca                	add	a5,a5,s2
    80002524:	07c7aa03          	lw	s4,124(a5)
  printf("before sched swtch status \n"); //delete
    80002528:	00006517          	auipc	a0,0x6
    8000252c:	f1050513          	addi	a0,a0,-240 # 80008438 <digits+0x3f8>
    80002530:	ffffe097          	auipc	ra,0xffffe
    80002534:	058080e7          	jalr	88(ra) # 80000588 <printf>
    80002538:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    8000253a:	2581                	sext.w	a1,a1
    8000253c:	033585b3          	mul	a1,a1,s3
    80002540:	05a1                	addi	a1,a1,8
    80002542:	95ca                	add	a1,a1,s2
    80002544:	06048513          	addi	a0,s1,96
    80002548:	00001097          	auipc	ra,0x1
    8000254c:	99e080e7          	jalr	-1634(ra) # 80002ee6 <swtch>
  printf("after sched swtch  status \n"); //delete
    80002550:	00006517          	auipc	a0,0x6
    80002554:	f0850513          	addi	a0,a0,-248 # 80008458 <digits+0x418>
    80002558:	ffffe097          	auipc	ra,0xffffe
    8000255c:	030080e7          	jalr	48(ra) # 80000588 <printf>
    80002560:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002562:	2781                	sext.w	a5,a5
    80002564:	033787b3          	mul	a5,a5,s3
    80002568:	993e                	add	s2,s2,a5
    8000256a:	07492e23          	sw	s4,124(s2)
}
    8000256e:	70a2                	ld	ra,40(sp)
    80002570:	7402                	ld	s0,32(sp)
    80002572:	64e2                	ld	s1,24(sp)
    80002574:	6942                	ld	s2,16(sp)
    80002576:	69a2                	ld	s3,8(sp)
    80002578:	6a02                	ld	s4,0(sp)
    8000257a:	6145                	addi	sp,sp,48
    8000257c:	8082                	ret
    panic("sched p->lock");
    8000257e:	00006517          	auipc	a0,0x6
    80002582:	e7250513          	addi	a0,a0,-398 # 800083f0 <digits+0x3b0>
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	fb8080e7          	jalr	-72(ra) # 8000053e <panic>
    panic("sched locks");
    8000258e:	00006517          	auipc	a0,0x6
    80002592:	e7250513          	addi	a0,a0,-398 # 80008400 <digits+0x3c0>
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	fa8080e7          	jalr	-88(ra) # 8000053e <panic>
    panic("sched running");
    8000259e:	00006517          	auipc	a0,0x6
    800025a2:	e7250513          	addi	a0,a0,-398 # 80008410 <digits+0x3d0>
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	f98080e7          	jalr	-104(ra) # 8000053e <panic>
    panic("sched interruptible");
    800025ae:	00006517          	auipc	a0,0x6
    800025b2:	e7250513          	addi	a0,a0,-398 # 80008420 <digits+0x3e0>
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	f88080e7          	jalr	-120(ra) # 8000053e <panic>

00000000800025be <yield>:
{
    800025be:	1101                	addi	sp,sp,-32
    800025c0:	ec06                	sd	ra,24(sp)
    800025c2:	e822                	sd	s0,16(sp)
    800025c4:	e426                	sd	s1,8(sp)
    800025c6:	e04a                	sd	s2,0(sp)
    800025c8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800025ca:	00000097          	auipc	ra,0x0
    800025ce:	8fa080e7          	jalr	-1798(ra) # 80001ec4 <myproc>
    800025d2:	84aa                	mv	s1,a0
    800025d4:	8912                	mv	s2,tp
  acquire(&p->lock);
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	60e080e7          	jalr	1550(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800025de:	478d                	li	a5,3
    800025e0:	cc9c                	sw	a5,24(s1)
  printf("insert yield runnable %d\n", p->index); //delete
    800025e2:	16c4a583          	lw	a1,364(s1)
    800025e6:	00006517          	auipc	a0,0x6
    800025ea:	e9250513          	addi	a0,a0,-366 # 80008478 <digits+0x438>
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	f9a080e7          	jalr	-102(ra) # 80000588 <printf>
  insert_proc_to_list(&(c->runnable_list), p); // TODO: check
    800025f6:	2901                	sext.w	s2,s2
    800025f8:	0b000513          	li	a0,176
    800025fc:	02a90933          	mul	s2,s2,a0
    80002600:	85a6                	mv	a1,s1
    80002602:	0000f517          	auipc	a0,0xf
    80002606:	d1e50513          	addi	a0,a0,-738 # 80011320 <cpus+0x80>
    8000260a:	954a                	add	a0,a0,s2
    8000260c:	fffff097          	auipc	ra,0xfffff
    80002610:	39e080e7          	jalr	926(ra) # 800019aa <insert_proc_to_list>
  sched();
    80002614:	00000097          	auipc	ra,0x0
    80002618:	ea8080e7          	jalr	-344(ra) # 800024bc <sched>
  release(&p->lock);
    8000261c:	8526                	mv	a0,s1
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	67a080e7          	jalr	1658(ra) # 80000c98 <release>
}
    80002626:	60e2                	ld	ra,24(sp)
    80002628:	6442                	ld	s0,16(sp)
    8000262a:	64a2                	ld	s1,8(sp)
    8000262c:	6902                	ld	s2,0(sp)
    8000262e:	6105                	addi	sp,sp,32
    80002630:	8082                	ret

0000000080002632 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002632:	7179                	addi	sp,sp,-48
    80002634:	f406                	sd	ra,40(sp)
    80002636:	f022                	sd	s0,32(sp)
    80002638:	ec26                	sd	s1,24(sp)
    8000263a:	e84a                	sd	s2,16(sp)
    8000263c:	e44e                	sd	s3,8(sp)
    8000263e:	1800                	addi	s0,sp,48
    80002640:	89aa                	mv	s3,a0
    80002642:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002644:	00000097          	auipc	ra,0x0
    80002648:	880080e7          	jalr	-1920(ra) # 80001ec4 <myproc>
    8000264c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	596080e7          	jalr	1430(ra) # 80000be4 <acquire>
  release(lk);
    80002656:	854a                	mv	a0,s2
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	640080e7          	jalr	1600(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002660:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002664:	4789                	li	a5,2
    80002666:	cc9c                	sw	a5,24(s1)
  printf("insert sleep sleep %d\n", p->index); //delete
    80002668:	16c4a583          	lw	a1,364(s1)
    8000266c:	00006517          	auipc	a0,0x6
    80002670:	e2c50513          	addi	a0,a0,-468 # 80008498 <digits+0x458>
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	f14080e7          	jalr	-236(ra) # 80000588 <printf>
  insert_proc_to_list(&sleeping_list, p);
    8000267c:	85a6                	mv	a1,s1
    8000267e:	00006517          	auipc	a0,0x6
    80002682:	51a50513          	addi	a0,a0,1306 # 80008b98 <sleeping_list>
    80002686:	fffff097          	auipc	ra,0xfffff
    8000268a:	324080e7          	jalr	804(ra) # 800019aa <insert_proc_to_list>

  sched();
    8000268e:	00000097          	auipc	ra,0x0
    80002692:	e2e080e7          	jalr	-466(ra) # 800024bc <sched>

  // Tidy up.
  p->chan = 0;
    80002696:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000269a:	8526                	mv	a0,s1
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	5fc080e7          	jalr	1532(ra) # 80000c98 <release>
  acquire(lk);
    800026a4:	854a                	mv	a0,s2
    800026a6:	ffffe097          	auipc	ra,0xffffe
    800026aa:	53e080e7          	jalr	1342(ra) # 80000be4 <acquire>
}
    800026ae:	70a2                	ld	ra,40(sp)
    800026b0:	7402                	ld	s0,32(sp)
    800026b2:	64e2                	ld	s1,24(sp)
    800026b4:	6942                	ld	s2,16(sp)
    800026b6:	69a2                	ld	s3,8(sp)
    800026b8:	6145                	addi	sp,sp,48
    800026ba:	8082                	ret

00000000800026bc <wait>:
{
    800026bc:	715d                	addi	sp,sp,-80
    800026be:	e486                	sd	ra,72(sp)
    800026c0:	e0a2                	sd	s0,64(sp)
    800026c2:	fc26                	sd	s1,56(sp)
    800026c4:	f84a                	sd	s2,48(sp)
    800026c6:	f44e                	sd	s3,40(sp)
    800026c8:	f052                	sd	s4,32(sp)
    800026ca:	ec56                	sd	s5,24(sp)
    800026cc:	e85a                	sd	s6,16(sp)
    800026ce:	e45e                	sd	s7,8(sp)
    800026d0:	e062                	sd	s8,0(sp)
    800026d2:	0880                	addi	s0,sp,80
    800026d4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800026d6:	fffff097          	auipc	ra,0xfffff
    800026da:	7ee080e7          	jalr	2030(ra) # 80001ec4 <myproc>
    800026de:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800026e0:	0000f517          	auipc	a0,0xf
    800026e4:	15850513          	addi	a0,a0,344 # 80011838 <wait_lock>
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	4fc080e7          	jalr	1276(ra) # 80000be4 <acquire>
    havekids = 0;
    800026f0:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800026f2:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800026f4:	00015997          	auipc	s3,0x15
    800026f8:	55c98993          	addi	s3,s3,1372 # 80017c50 <tickslock>
        havekids = 1;
    800026fc:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026fe:	0000fc17          	auipc	s8,0xf
    80002702:	13ac0c13          	addi	s8,s8,314 # 80011838 <wait_lock>
    havekids = 0;
    80002706:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002708:	0000f497          	auipc	s1,0xf
    8000270c:	14848493          	addi	s1,s1,328 # 80011850 <proc>
    80002710:	a0bd                	j	8000277e <wait+0xc2>
          pid = np->pid;
    80002712:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002716:	000b0e63          	beqz	s6,80002732 <wait+0x76>
    8000271a:	4691                	li	a3,4
    8000271c:	02c48613          	addi	a2,s1,44
    80002720:	85da                	mv	a1,s6
    80002722:	05093503          	ld	a0,80(s2)
    80002726:	fffff097          	auipc	ra,0xfffff
    8000272a:	f4c080e7          	jalr	-180(ra) # 80001672 <copyout>
    8000272e:	02054563          	bltz	a0,80002758 <wait+0x9c>
          freeproc(np);
    80002732:	8526                	mv	a0,s1
    80002734:	00000097          	auipc	ra,0x0
    80002738:	93c080e7          	jalr	-1732(ra) # 80002070 <freeproc>
          release(&np->lock);
    8000273c:	8526                	mv	a0,s1
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	55a080e7          	jalr	1370(ra) # 80000c98 <release>
          release(&wait_lock);
    80002746:	0000f517          	auipc	a0,0xf
    8000274a:	0f250513          	addi	a0,a0,242 # 80011838 <wait_lock>
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	54a080e7          	jalr	1354(ra) # 80000c98 <release>
          return pid;
    80002756:	a09d                	j	800027bc <wait+0x100>
            release(&np->lock);
    80002758:	8526                	mv	a0,s1
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	53e080e7          	jalr	1342(ra) # 80000c98 <release>
            release(&wait_lock);
    80002762:	0000f517          	auipc	a0,0xf
    80002766:	0d650513          	addi	a0,a0,214 # 80011838 <wait_lock>
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	52e080e7          	jalr	1326(ra) # 80000c98 <release>
            return -1;
    80002772:	59fd                	li	s3,-1
    80002774:	a0a1                	j	800027bc <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002776:	19048493          	addi	s1,s1,400
    8000277a:	03348463          	beq	s1,s3,800027a2 <wait+0xe6>
      if(np->parent == p){
    8000277e:	7c9c                	ld	a5,56(s1)
    80002780:	ff279be3          	bne	a5,s2,80002776 <wait+0xba>
        acquire(&np->lock);
    80002784:	8526                	mv	a0,s1
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	45e080e7          	jalr	1118(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000278e:	4c9c                	lw	a5,24(s1)
    80002790:	f94781e3          	beq	a5,s4,80002712 <wait+0x56>
        release(&np->lock);
    80002794:	8526                	mv	a0,s1
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	502080e7          	jalr	1282(ra) # 80000c98 <release>
        havekids = 1;
    8000279e:	8756                	mv	a4,s5
    800027a0:	bfd9                	j	80002776 <wait+0xba>
    if(!havekids || p->killed){
    800027a2:	c701                	beqz	a4,800027aa <wait+0xee>
    800027a4:	02892783          	lw	a5,40(s2)
    800027a8:	c79d                	beqz	a5,800027d6 <wait+0x11a>
      release(&wait_lock);
    800027aa:	0000f517          	auipc	a0,0xf
    800027ae:	08e50513          	addi	a0,a0,142 # 80011838 <wait_lock>
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	4e6080e7          	jalr	1254(ra) # 80000c98 <release>
      return -1;
    800027ba:	59fd                	li	s3,-1
}
    800027bc:	854e                	mv	a0,s3
    800027be:	60a6                	ld	ra,72(sp)
    800027c0:	6406                	ld	s0,64(sp)
    800027c2:	74e2                	ld	s1,56(sp)
    800027c4:	7942                	ld	s2,48(sp)
    800027c6:	79a2                	ld	s3,40(sp)
    800027c8:	7a02                	ld	s4,32(sp)
    800027ca:	6ae2                	ld	s5,24(sp)
    800027cc:	6b42                	ld	s6,16(sp)
    800027ce:	6ba2                	ld	s7,8(sp)
    800027d0:	6c02                	ld	s8,0(sp)
    800027d2:	6161                	addi	sp,sp,80
    800027d4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800027d6:	85e2                	mv	a1,s8
    800027d8:	854a                	mv	a0,s2
    800027da:	00000097          	auipc	ra,0x0
    800027de:	e58080e7          	jalr	-424(ra) # 80002632 <sleep>
    havekids = 0;
    800027e2:	b715                	j	80002706 <wait+0x4a>

00000000800027e4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800027e4:	7179                	addi	sp,sp,-48
    800027e6:	f406                	sd	ra,40(sp)
    800027e8:	f022                	sd	s0,32(sp)
    800027ea:	ec26                	sd	s1,24(sp)
    800027ec:	e84a                	sd	s2,16(sp)
    800027ee:	e44e                	sd	s3,8(sp)
    800027f0:	1800                	addi	s0,sp,48
    800027f2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800027f4:	0000f497          	auipc	s1,0xf
    800027f8:	05c48493          	addi	s1,s1,92 # 80011850 <proc>
    800027fc:	00015997          	auipc	s3,0x15
    80002800:	45498993          	addi	s3,s3,1108 # 80017c50 <tickslock>
    acquire(&p->lock);
    80002804:	8526                	mv	a0,s1
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	3de080e7          	jalr	990(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000280e:	589c                	lw	a5,48(s1)
    80002810:	01278d63          	beq	a5,s2,8000282a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002814:	8526                	mv	a0,s1
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	482080e7          	jalr	1154(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000281e:	19048493          	addi	s1,s1,400
    80002822:	ff3491e3          	bne	s1,s3,80002804 <kill+0x20>
  }
  return -1;
    80002826:	557d                	li	a0,-1
    80002828:	a829                	j	80002842 <kill+0x5e>
      p->killed = 1;
    8000282a:	4785                	li	a5,1
    8000282c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000282e:	4c98                	lw	a4,24(s1)
    80002830:	4789                	li	a5,2
    80002832:	00f70f63          	beq	a4,a5,80002850 <kill+0x6c>
      release(&p->lock);
    80002836:	8526                	mv	a0,s1
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	460080e7          	jalr	1120(ra) # 80000c98 <release>
      return 0;
    80002840:	4501                	li	a0,0
}
    80002842:	70a2                	ld	ra,40(sp)
    80002844:	7402                	ld	s0,32(sp)
    80002846:	64e2                	ld	s1,24(sp)
    80002848:	6942                	ld	s2,16(sp)
    8000284a:	69a2                	ld	s3,8(sp)
    8000284c:	6145                	addi	sp,sp,48
    8000284e:	8082                	ret
        p->state = RUNNABLE;
    80002850:	478d                	li	a5,3
    80002852:	cc9c                	sw	a5,24(s1)
    80002854:	b7cd                	j	80002836 <kill+0x52>

0000000080002856 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002856:	7179                	addi	sp,sp,-48
    80002858:	f406                	sd	ra,40(sp)
    8000285a:	f022                	sd	s0,32(sp)
    8000285c:	ec26                	sd	s1,24(sp)
    8000285e:	e84a                	sd	s2,16(sp)
    80002860:	e44e                	sd	s3,8(sp)
    80002862:	e052                	sd	s4,0(sp)
    80002864:	1800                	addi	s0,sp,48
    80002866:	84aa                	mv	s1,a0
    80002868:	892e                	mv	s2,a1
    8000286a:	89b2                	mv	s3,a2
    8000286c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000286e:	fffff097          	auipc	ra,0xfffff
    80002872:	656080e7          	jalr	1622(ra) # 80001ec4 <myproc>
  if(user_dst){
    80002876:	c08d                	beqz	s1,80002898 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002878:	86d2                	mv	a3,s4
    8000287a:	864e                	mv	a2,s3
    8000287c:	85ca                	mv	a1,s2
    8000287e:	6928                	ld	a0,80(a0)
    80002880:	fffff097          	auipc	ra,0xfffff
    80002884:	df2080e7          	jalr	-526(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002888:	70a2                	ld	ra,40(sp)
    8000288a:	7402                	ld	s0,32(sp)
    8000288c:	64e2                	ld	s1,24(sp)
    8000288e:	6942                	ld	s2,16(sp)
    80002890:	69a2                	ld	s3,8(sp)
    80002892:	6a02                	ld	s4,0(sp)
    80002894:	6145                	addi	sp,sp,48
    80002896:	8082                	ret
    memmove((char *)dst, src, len);
    80002898:	000a061b          	sext.w	a2,s4
    8000289c:	85ce                	mv	a1,s3
    8000289e:	854a                	mv	a0,s2
    800028a0:	ffffe097          	auipc	ra,0xffffe
    800028a4:	4a0080e7          	jalr	1184(ra) # 80000d40 <memmove>
    return 0;
    800028a8:	8526                	mv	a0,s1
    800028aa:	bff9                	j	80002888 <either_copyout+0x32>

00000000800028ac <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800028ac:	7179                	addi	sp,sp,-48
    800028ae:	f406                	sd	ra,40(sp)
    800028b0:	f022                	sd	s0,32(sp)
    800028b2:	ec26                	sd	s1,24(sp)
    800028b4:	e84a                	sd	s2,16(sp)
    800028b6:	e44e                	sd	s3,8(sp)
    800028b8:	e052                	sd	s4,0(sp)
    800028ba:	1800                	addi	s0,sp,48
    800028bc:	892a                	mv	s2,a0
    800028be:	84ae                	mv	s1,a1
    800028c0:	89b2                	mv	s3,a2
    800028c2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800028c4:	fffff097          	auipc	ra,0xfffff
    800028c8:	600080e7          	jalr	1536(ra) # 80001ec4 <myproc>
  if(user_src){
    800028cc:	c08d                	beqz	s1,800028ee <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800028ce:	86d2                	mv	a3,s4
    800028d0:	864e                	mv	a2,s3
    800028d2:	85ca                	mv	a1,s2
    800028d4:	6928                	ld	a0,80(a0)
    800028d6:	fffff097          	auipc	ra,0xfffff
    800028da:	e28080e7          	jalr	-472(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800028de:	70a2                	ld	ra,40(sp)
    800028e0:	7402                	ld	s0,32(sp)
    800028e2:	64e2                	ld	s1,24(sp)
    800028e4:	6942                	ld	s2,16(sp)
    800028e6:	69a2                	ld	s3,8(sp)
    800028e8:	6a02                	ld	s4,0(sp)
    800028ea:	6145                	addi	sp,sp,48
    800028ec:	8082                	ret
    memmove(dst, (char*)src, len);
    800028ee:	000a061b          	sext.w	a2,s4
    800028f2:	85ce                	mv	a1,s3
    800028f4:	854a                	mv	a0,s2
    800028f6:	ffffe097          	auipc	ra,0xffffe
    800028fa:	44a080e7          	jalr	1098(ra) # 80000d40 <memmove>
    return 0;
    800028fe:	8526                	mv	a0,s1
    80002900:	bff9                	j	800028de <either_copyin+0x32>

0000000080002902 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    80002902:	715d                	addi	sp,sp,-80
    80002904:	e486                	sd	ra,72(sp)
    80002906:	e0a2                	sd	s0,64(sp)
    80002908:	fc26                	sd	s1,56(sp)
    8000290a:	f84a                	sd	s2,48(sp)
    8000290c:	f44e                	sd	s3,40(sp)
    8000290e:	f052                	sd	s4,32(sp)
    80002910:	ec56                	sd	s5,24(sp)
    80002912:	e85a                	sd	s6,16(sp)
    80002914:	e45e                	sd	s7,8(sp)
    80002916:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002918:	00006517          	auipc	a0,0x6
    8000291c:	ab050513          	addi	a0,a0,-1360 # 800083c8 <digits+0x388>
    80002920:	ffffe097          	auipc	ra,0xffffe
    80002924:	c68080e7          	jalr	-920(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002928:	0000f497          	auipc	s1,0xf
    8000292c:	08048493          	addi	s1,s1,128 # 800119a8 <proc+0x158>
    80002930:	00015917          	auipc	s2,0x15
    80002934:	47890913          	addi	s2,s2,1144 # 80017da8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002938:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    8000293a:	00006997          	auipc	s3,0x6
    8000293e:	b7698993          	addi	s3,s3,-1162 # 800084b0 <digits+0x470>
    printf("%d %s %s", p->pid, state, p->name);
    80002942:	00006a97          	auipc	s5,0x6
    80002946:	b76a8a93          	addi	s5,s5,-1162 # 800084b8 <digits+0x478>
    printf("\n");
    8000294a:	00006a17          	auipc	s4,0x6
    8000294e:	a7ea0a13          	addi	s4,s4,-1410 # 800083c8 <digits+0x388>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002952:	00006b97          	auipc	s7,0x6
    80002956:	c4eb8b93          	addi	s7,s7,-946 # 800085a0 <states.1816>
    8000295a:	a00d                	j	8000297c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000295c:	ed86a583          	lw	a1,-296(a3)
    80002960:	8556                	mv	a0,s5
    80002962:	ffffe097          	auipc	ra,0xffffe
    80002966:	c26080e7          	jalr	-986(ra) # 80000588 <printf>
    printf("\n");
    8000296a:	8552                	mv	a0,s4
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	c1c080e7          	jalr	-996(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002974:	19048493          	addi	s1,s1,400
    80002978:	03248163          	beq	s1,s2,8000299a <procdump+0x98>
    if(p->state == UNUSED)
    8000297c:	86a6                	mv	a3,s1
    8000297e:	ec04a783          	lw	a5,-320(s1)
    80002982:	dbed                	beqz	a5,80002974 <procdump+0x72>
      state = "???"; 
    80002984:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002986:	fcfb6be3          	bltu	s6,a5,8000295c <procdump+0x5a>
    8000298a:	1782                	slli	a5,a5,0x20
    8000298c:	9381                	srli	a5,a5,0x20
    8000298e:	078e                	slli	a5,a5,0x3
    80002990:	97de                	add	a5,a5,s7
    80002992:	6390                	ld	a2,0(a5)
    80002994:	f661                	bnez	a2,8000295c <procdump+0x5a>
      state = "???"; 
    80002996:	864e                	mv	a2,s3
    80002998:	b7d1                	j	8000295c <procdump+0x5a>
  }
}
    8000299a:	60a6                	ld	ra,72(sp)
    8000299c:	6406                	ld	s0,64(sp)
    8000299e:	74e2                	ld	s1,56(sp)
    800029a0:	7942                	ld	s2,48(sp)
    800029a2:	79a2                	ld	s3,40(sp)
    800029a4:	7a02                	ld	s4,32(sp)
    800029a6:	6ae2                	ld	s5,24(sp)
    800029a8:	6b42                	ld	s6,16(sp)
    800029aa:	6ba2                	ld	s7,8(sp)
    800029ac:	6161                	addi	sp,sp,80
    800029ae:	8082                	ret

00000000800029b0 <set_cpu>:

// assign current process to a different CPU. 
int
set_cpu(int cpu_num){
    800029b0:	1101                	addi	sp,sp,-32
    800029b2:	ec06                	sd	ra,24(sp)
    800029b4:	e822                	sd	s0,16(sp)
    800029b6:	e426                	sd	s1,8(sp)
    800029b8:	e04a                	sd	s2,0(sp)
    800029ba:	1000                	addi	s0,sp,32
    800029bc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029be:	fffff097          	auipc	ra,0xfffff
    800029c2:	506080e7          	jalr	1286(ra) # 80001ec4 <myproc>
  if(cpu_num >= 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL){
    800029c6:	0004871b          	sext.w	a4,s1
    800029ca:	479d                	li	a5,7
    800029cc:	02e7e963          	bltu	a5,a4,800029fe <set_cpu+0x4e>
    800029d0:	892a                	mv	s2,a0
    acquire(&p->lock);
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	212080e7          	jalr	530(ra) # 80000be4 <acquire>
    p->last_cpu = cpu_num;
    800029da:	16992423          	sw	s1,360(s2)
    release(&p->lock);
    800029de:	854a                	mv	a0,s2
    800029e0:	ffffe097          	auipc	ra,0xffffe
    800029e4:	2b8080e7          	jalr	696(ra) # 80000c98 <release>

    yield();
    800029e8:	00000097          	auipc	ra,0x0
    800029ec:	bd6080e7          	jalr	-1066(ra) # 800025be <yield>

    return cpu_num;
    800029f0:	8526                	mv	a0,s1
  }
  return -1;
}
    800029f2:	60e2                	ld	ra,24(sp)
    800029f4:	6442                	ld	s0,16(sp)
    800029f6:	64a2                	ld	s1,8(sp)
    800029f8:	6902                	ld	s2,0(sp)
    800029fa:	6105                	addi	sp,sp,32
    800029fc:	8082                	ret
  return -1;
    800029fe:	557d                	li	a0,-1
    80002a00:	bfcd                	j	800029f2 <set_cpu+0x42>

0000000080002a02 <get_cpu>:

// return the current CPU id.
int
get_cpu(void){
    80002a02:	1141                	addi	sp,sp,-16
    80002a04:	e406                	sd	ra,8(sp)
    80002a06:	e022                	sd	s0,0(sp)
    80002a08:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a0a:	fffff097          	auipc	ra,0xfffff
    80002a0e:	4ba080e7          	jalr	1210(ra) # 80001ec4 <myproc>
  return p->last_cpu;
}
    80002a12:	16852503          	lw	a0,360(a0)
    80002a16:	60a2                	ld	ra,8(sp)
    80002a18:	6402                	ld	s0,0(sp)
    80002a1a:	0141                	addi	sp,sp,16
    80002a1c:	8082                	ret

0000000080002a1e <min_cpu>:

int
min_cpu(void){
    80002a1e:	1141                	addi	sp,sp,-16
    80002a20:	e422                	sd	s0,8(sp)
    80002a22:	0800                	addi	s0,sp,16
  struct cpu *c, *min_cpu;
// should add an if to insure numberOfCpus>0
  min_cpu = cpus;
    80002a24:	0000f617          	auipc	a2,0xf
    80002a28:	87c60613          	addi	a2,a2,-1924 # 800112a0 <cpus>
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL ; c++){
    80002a2c:	0000f797          	auipc	a5,0xf
    80002a30:	92478793          	addi	a5,a5,-1756 # 80011350 <cpus+0xb0>
    80002a34:	0000f597          	auipc	a1,0xf
    80002a38:	dec58593          	addi	a1,a1,-532 # 80011820 <pid_lock>
    80002a3c:	a029                	j	80002a46 <min_cpu+0x28>
    80002a3e:	0b078793          	addi	a5,a5,176
    80002a42:	00b78863          	beq	a5,a1,80002a52 <min_cpu+0x34>
    if (c->cpu_process_count < min_cpu->cpu_process_count)
    80002a46:	77d4                	ld	a3,168(a5)
    80002a48:	7658                	ld	a4,168(a2)
    80002a4a:	fee6fae3          	bgeu	a3,a4,80002a3e <min_cpu+0x20>
    80002a4e:	863e                	mv	a2,a5
    80002a50:	b7fd                	j	80002a3e <min_cpu+0x20>
        min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    80002a52:	0a062503          	lw	a0,160(a2)
    80002a56:	6422                	ld	s0,8(sp)
    80002a58:	0141                	addi	sp,sp,16
    80002a5a:	8082                	ret

0000000080002a5c <cpu_process_count>:

int
cpu_process_count(int cpu_num){
    80002a5c:	1141                	addi	sp,sp,-16
    80002a5e:	e422                	sd	s0,8(sp)
    80002a60:	0800                	addi	s0,sp,16
  if (cpu_num > 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL) 
    80002a62:	fff5071b          	addiw	a4,a0,-1
    80002a66:	4799                	li	a5,6
    80002a68:	02e7e063          	bltu	a5,a4,80002a88 <cpu_process_count+0x2c>
    return cpus[cpu_num].cpu_process_count;
    80002a6c:	0b000793          	li	a5,176
    80002a70:	02f50533          	mul	a0,a0,a5
    80002a74:	0000f797          	auipc	a5,0xf
    80002a78:	82c78793          	addi	a5,a5,-2004 # 800112a0 <cpus>
    80002a7c:	953e                	add	a0,a0,a5
    80002a7e:	0a852503          	lw	a0,168(a0)
  return -1;
}
    80002a82:	6422                	ld	s0,8(sp)
    80002a84:	0141                	addi	sp,sp,16
    80002a86:	8082                	ret
  return -1;
    80002a88:	557d                	li	a0,-1
    80002a8a:	bfe5                	j	80002a82 <cpu_process_count+0x26>

0000000080002a8c <increment_cpu_process_count>:

void 
increment_cpu_process_count(struct cpu *c){
    80002a8c:	1101                	addi	sp,sp,-32
    80002a8e:	ec06                	sd	ra,24(sp)
    80002a90:	e822                	sd	s0,16(sp)
    80002a92:	e426                	sd	s1,8(sp)
    80002a94:	e04a                	sd	s2,0(sp)
    80002a96:	1000                	addi	s0,sp,32
    80002a98:	84aa                	mv	s1,a0
  uint64 curr_count;
  do{
    curr_count = c->cpu_process_count;
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    80002a9a:	0a850913          	addi	s2,a0,168
    curr_count = c->cpu_process_count;
    80002a9e:	74cc                	ld	a1,168(s1)
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    80002aa0:	0015861b          	addiw	a2,a1,1
    80002aa4:	2581                	sext.w	a1,a1
    80002aa6:	854a                	mv	a0,s2
    80002aa8:	00004097          	auipc	ra,0x4
    80002aac:	0ae080e7          	jalr	174(ra) # 80006b56 <cas>
    80002ab0:	2501                	sext.w	a0,a0
    80002ab2:	f575                	bnez	a0,80002a9e <increment_cpu_process_count+0x12>
}
    80002ab4:	60e2                	ld	ra,24(sp)
    80002ab6:	6442                	ld	s0,16(sp)
    80002ab8:	64a2                	ld	s1,8(sp)
    80002aba:	6902                	ld	s2,0(sp)
    80002abc:	6105                	addi	sp,sp,32
    80002abe:	8082                	ret

0000000080002ac0 <fork>:
{
    80002ac0:	7139                	addi	sp,sp,-64
    80002ac2:	fc06                	sd	ra,56(sp)
    80002ac4:	f822                	sd	s0,48(sp)
    80002ac6:	f426                	sd	s1,40(sp)
    80002ac8:	f04a                	sd	s2,32(sp)
    80002aca:	ec4e                	sd	s3,24(sp)
    80002acc:	e852                	sd	s4,16(sp)
    80002ace:	e456                	sd	s5,8(sp)
    80002ad0:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002ad2:	fffff097          	auipc	ra,0xfffff
    80002ad6:	3f2080e7          	jalr	1010(ra) # 80001ec4 <myproc>
    80002ada:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002adc:	fffff097          	auipc	ra,0xfffff
    80002ae0:	638080e7          	jalr	1592(ra) # 80002114 <allocproc>
    80002ae4:	16050063          	beqz	a0,80002c44 <fork+0x184>
    80002ae8:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002aea:	0489b603          	ld	a2,72(s3)
    80002aee:	692c                	ld	a1,80(a0)
    80002af0:	0509b503          	ld	a0,80(s3)
    80002af4:	fffff097          	auipc	ra,0xfffff
    80002af8:	a7a080e7          	jalr	-1414(ra) # 8000156e <uvmcopy>
    80002afc:	04054663          	bltz	a0,80002b48 <fork+0x88>
  np->sz = p->sz;
    80002b00:	0489b783          	ld	a5,72(s3)
    80002b04:	04f93423          	sd	a5,72(s2)
  *(np->trapframe) = *(p->trapframe);
    80002b08:	0589b683          	ld	a3,88(s3)
    80002b0c:	87b6                	mv	a5,a3
    80002b0e:	05893703          	ld	a4,88(s2)
    80002b12:	12068693          	addi	a3,a3,288
    80002b16:	0007b803          	ld	a6,0(a5)
    80002b1a:	6788                	ld	a0,8(a5)
    80002b1c:	6b8c                	ld	a1,16(a5)
    80002b1e:	6f90                	ld	a2,24(a5)
    80002b20:	01073023          	sd	a6,0(a4)
    80002b24:	e708                	sd	a0,8(a4)
    80002b26:	eb0c                	sd	a1,16(a4)
    80002b28:	ef10                	sd	a2,24(a4)
    80002b2a:	02078793          	addi	a5,a5,32
    80002b2e:	02070713          	addi	a4,a4,32
    80002b32:	fed792e3          	bne	a5,a3,80002b16 <fork+0x56>
  np->trapframe->a0 = 0;
    80002b36:	05893783          	ld	a5,88(s2)
    80002b3a:	0607b823          	sd	zero,112(a5)
    80002b3e:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002b42:	15000a13          	li	s4,336
    80002b46:	a03d                	j	80002b74 <fork+0xb4>
    freeproc(np);
    80002b48:	854a                	mv	a0,s2
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	526080e7          	jalr	1318(ra) # 80002070 <freeproc>
    release(&np->lock);
    80002b52:	854a                	mv	a0,s2
    80002b54:	ffffe097          	auipc	ra,0xffffe
    80002b58:	144080e7          	jalr	324(ra) # 80000c98 <release>
    return -1;
    80002b5c:	5afd                	li	s5,-1
    80002b5e:	a8c9                	j	80002c30 <fork+0x170>
      np->ofile[i] = filedup(p->ofile[i]);
    80002b60:	00002097          	auipc	ra,0x2
    80002b64:	2b2080e7          	jalr	690(ra) # 80004e12 <filedup>
    80002b68:	009907b3          	add	a5,s2,s1
    80002b6c:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002b6e:	04a1                	addi	s1,s1,8
    80002b70:	01448763          	beq	s1,s4,80002b7e <fork+0xbe>
    if(p->ofile[i])
    80002b74:	009987b3          	add	a5,s3,s1
    80002b78:	6388                	ld	a0,0(a5)
    80002b7a:	f17d                	bnez	a0,80002b60 <fork+0xa0>
    80002b7c:	bfcd                	j	80002b6e <fork+0xae>
  np->cwd = idup(p->cwd);
    80002b7e:	1509b503          	ld	a0,336(s3)
    80002b82:	00001097          	auipc	ra,0x1
    80002b86:	406080e7          	jalr	1030(ra) # 80003f88 <idup>
    80002b8a:	14a93823          	sd	a0,336(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002b8e:	4641                	li	a2,16
    80002b90:	15898593          	addi	a1,s3,344
    80002b94:	15890513          	addi	a0,s2,344
    80002b98:	ffffe097          	auipc	ra,0xffffe
    80002b9c:	29a080e7          	jalr	666(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002ba0:	03092a83          	lw	s5,48(s2)
  release(&np->lock);
    80002ba4:	854a                	mv	a0,s2
    80002ba6:	ffffe097          	auipc	ra,0xffffe
    80002baa:	0f2080e7          	jalr	242(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002bae:	0000ea17          	auipc	s4,0xe
    80002bb2:	6f2a0a13          	addi	s4,s4,1778 # 800112a0 <cpus>
    80002bb6:	0000f497          	auipc	s1,0xf
    80002bba:	c8248493          	addi	s1,s1,-894 # 80011838 <wait_lock>
    80002bbe:	8526                	mv	a0,s1
    80002bc0:	ffffe097          	auipc	ra,0xffffe
    80002bc4:	024080e7          	jalr	36(ra) # 80000be4 <acquire>
  np->parent = p;
    80002bc8:	03393c23          	sd	s3,56(s2)
  release(&wait_lock);
    80002bcc:	8526                	mv	a0,s1
    80002bce:	ffffe097          	auipc	ra,0xffffe
    80002bd2:	0ca080e7          	jalr	202(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002bd6:	854a                	mv	a0,s2
    80002bd8:	ffffe097          	auipc	ra,0xffffe
    80002bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002be0:	478d                	li	a5,3
    80002be2:	00f92c23          	sw	a5,24(s2)
  np->last_cpu = p->last_cpu; // case BLNCFLG=OFF -> cpu = parent's cpu 
    80002be6:	1689a483          	lw	s1,360(s3)
    80002bea:	16992423          	sw	s1,360(s2)
  struct cpu *c = &cpus[np->last_cpu];
    80002bee:	0b000513          	li	a0,176
    80002bf2:	02a484b3          	mul	s1,s1,a0
  increment_cpu_process_count(c);
    80002bf6:	009a0533          	add	a0,s4,s1
    80002bfa:	00000097          	auipc	ra,0x0
    80002bfe:	e92080e7          	jalr	-366(ra) # 80002a8c <increment_cpu_process_count>
  printf("insert fork runnable %d\n", np->index); //delete
    80002c02:	16c92583          	lw	a1,364(s2)
    80002c06:	00006517          	auipc	a0,0x6
    80002c0a:	8c250513          	addi	a0,a0,-1854 # 800084c8 <digits+0x488>
    80002c0e:	ffffe097          	auipc	ra,0xffffe
    80002c12:	97a080e7          	jalr	-1670(ra) # 80000588 <printf>
  insert_proc_to_list(&(c->runnable_list), np); // admit the new process to the father’s current CPU’s ready list
    80002c16:	08048513          	addi	a0,s1,128
    80002c1a:	85ca                	mv	a1,s2
    80002c1c:	9552                	add	a0,a0,s4
    80002c1e:	fffff097          	auipc	ra,0xfffff
    80002c22:	d8c080e7          	jalr	-628(ra) # 800019aa <insert_proc_to_list>
  release(&np->lock);
    80002c26:	854a                	mv	a0,s2
    80002c28:	ffffe097          	auipc	ra,0xffffe
    80002c2c:	070080e7          	jalr	112(ra) # 80000c98 <release>
}
    80002c30:	8556                	mv	a0,s5
    80002c32:	70e2                	ld	ra,56(sp)
    80002c34:	7442                	ld	s0,48(sp)
    80002c36:	74a2                	ld	s1,40(sp)
    80002c38:	7902                	ld	s2,32(sp)
    80002c3a:	69e2                	ld	s3,24(sp)
    80002c3c:	6a42                	ld	s4,16(sp)
    80002c3e:	6aa2                	ld	s5,8(sp)
    80002c40:	6121                	addi	sp,sp,64
    80002c42:	8082                	ret
    return -1;
    80002c44:	5afd                	li	s5,-1
    80002c46:	b7ed                	j	80002c30 <fork+0x170>

0000000080002c48 <wakeup>:
{
    80002c48:	7159                	addi	sp,sp,-112
    80002c4a:	f486                	sd	ra,104(sp)
    80002c4c:	f0a2                	sd	s0,96(sp)
    80002c4e:	eca6                	sd	s1,88(sp)
    80002c50:	e8ca                	sd	s2,80(sp)
    80002c52:	e4ce                	sd	s3,72(sp)
    80002c54:	e0d2                	sd	s4,64(sp)
    80002c56:	fc56                	sd	s5,56(sp)
    80002c58:	f85a                	sd	s6,48(sp)
    80002c5a:	f45e                	sd	s7,40(sp)
    80002c5c:	f062                	sd	s8,32(sp)
    80002c5e:	ec66                	sd	s9,24(sp)
    80002c60:	e86a                	sd	s10,16(sp)
    80002c62:	e46e                	sd	s11,8(sp)
    80002c64:	1880                	addi	s0,sp,112
    80002c66:	8baa                	mv	s7,a0
  int curr = get_head(&sleeping_list);
    80002c68:	00006517          	auipc	a0,0x6
    80002c6c:	f3050513          	addi	a0,a0,-208 # 80008b98 <sleeping_list>
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	ce4080e7          	jalr	-796(ra) # 80001954 <get_head>
  while(curr != -1) {
    80002c78:	57fd                	li	a5,-1
    80002c7a:	0ef50c63          	beq	a0,a5,80002d72 <wakeup+0x12a>
    80002c7e:	892a                	mv	s2,a0
    p = &proc[curr];
    80002c80:	19000a93          	li	s5,400
    80002c84:	0000fa17          	auipc	s4,0xf
    80002c88:	bcca0a13          	addi	s4,s4,-1076 # 80011850 <proc>
      if(p->state == SLEEPING && p->chan == chan) {
    80002c8c:	4b09                	li	s6,2
        p->state = RUNNABLE;
    80002c8e:	4d8d                	li	s11,3
    80002c90:	0b000d13          	li	s10,176
        c = &cpus[p->last_cpu];
    80002c94:	0000ec97          	auipc	s9,0xe
    80002c98:	60cc8c93          	addi	s9,s9,1548 # 800112a0 <cpus>
    80002c9c:	a809                	j	80002cae <wakeup+0x66>
      release(&p->lock);
    80002c9e:	8526                	mv	a0,s1
    80002ca0:	ffffe097          	auipc	ra,0xffffe
    80002ca4:	ff8080e7          	jalr	-8(ra) # 80000c98 <release>
  while(curr != -1) {
    80002ca8:	57fd                	li	a5,-1
    80002caa:	0cf90463          	beq	s2,a5,80002d72 <wakeup+0x12a>
    p = &proc[curr];
    80002cae:	035904b3          	mul	s1,s2,s5
    80002cb2:	94d2                	add	s1,s1,s4
    curr = p->next_index;
    80002cb4:	1744a903          	lw	s2,372(s1)
    if(p != myproc()){
    80002cb8:	fffff097          	auipc	ra,0xfffff
    80002cbc:	20c080e7          	jalr	524(ra) # 80001ec4 <myproc>
    80002cc0:	fea484e3          	beq	s1,a0,80002ca8 <wakeup+0x60>
      acquire(&p->lock);
    80002cc4:	8526                	mv	a0,s1
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	f1e080e7          	jalr	-226(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002cce:	4c9c                	lw	a5,24(s1)
    80002cd0:	fd6797e3          	bne	a5,s6,80002c9e <wakeup+0x56>
    80002cd4:	709c                	ld	a5,32(s1)
    80002cd6:	fd7794e3          	bne	a5,s7,80002c9e <wakeup+0x56>
        printf("remove wakeup sleep %d\n", p->index); //delete
    80002cda:	16c4a583          	lw	a1,364(s1)
    80002cde:	00006517          	auipc	a0,0x6
    80002ce2:	80a50513          	addi	a0,a0,-2038 # 800084e8 <digits+0x4a8>
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	8a2080e7          	jalr	-1886(ra) # 80000588 <printf>
        remove_proc_to_list(&sleeping_list, p);
    80002cee:	85a6                	mv	a1,s1
    80002cf0:	00006517          	auipc	a0,0x6
    80002cf4:	ea850513          	addi	a0,a0,-344 # 80008b98 <sleeping_list>
    80002cf8:	fffff097          	auipc	ra,0xfffff
    80002cfc:	e12080e7          	jalr	-494(ra) # 80001b0a <remove_proc_to_list>
        p->state = RUNNABLE;
    80002d00:	01b4ac23          	sw	s11,24(s1)
        c = &cpus[p->last_cpu];
    80002d04:	1684ac03          	lw	s8,360(s1)
    80002d08:	03ac0c33          	mul	s8,s8,s10
        increment_cpu_process_count(c);
    80002d0c:	018c8533          	add	a0,s9,s8
    80002d10:	00000097          	auipc	ra,0x0
    80002d14:	d7c080e7          	jalr	-644(ra) # 80002a8c <increment_cpu_process_count>
        printf("insert wakeup runnable %d\n", p->index); //delete
    80002d18:	16c4a583          	lw	a1,364(s1)
    80002d1c:	00005517          	auipc	a0,0x5
    80002d20:	7e450513          	addi	a0,a0,2020 # 80008500 <digits+0x4c0>
    80002d24:	ffffe097          	auipc	ra,0xffffe
    80002d28:	864080e7          	jalr	-1948(ra) # 80000588 <printf>
        insert_proc_to_list(&(c->runnable_list), p);
    80002d2c:	080c0513          	addi	a0,s8,128
    80002d30:	85a6                	mv	a1,s1
    80002d32:	9566                	add	a0,a0,s9
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	c76080e7          	jalr	-906(ra) # 800019aa <insert_proc_to_list>
        printf("after wakeup\n"); //delete
    80002d3c:	00005517          	auipc	a0,0x5
    80002d40:	7e450513          	addi	a0,a0,2020 # 80008520 <digits+0x4e0>
    80002d44:	ffffe097          	auipc	ra,0xffffe
    80002d48:	844080e7          	jalr	-1980(ra) # 80000588 <printf>
    80002d4c:	8792                	mv	a5,tp
  return lst->head == -1;
    80002d4e:	2781                	sext.w	a5,a5
    80002d50:	03a787b3          	mul	a5,a5,s10
    80002d54:	97e6                	add	a5,a5,s9
    80002d56:	0807a583          	lw	a1,128(a5)
    80002d5a:	0585                	addi	a1,a1,1
        printf("isempty? %d\n", isEmpty(&mycpu()->runnable_list)); //delete
    80002d5c:	0015b593          	seqz	a1,a1
    80002d60:	00005517          	auipc	a0,0x5
    80002d64:	7d050513          	addi	a0,a0,2000 # 80008530 <digits+0x4f0>
    80002d68:	ffffe097          	auipc	ra,0xffffe
    80002d6c:	820080e7          	jalr	-2016(ra) # 80000588 <printf>
    80002d70:	b73d                	j	80002c9e <wakeup+0x56>
}
    80002d72:	70a6                	ld	ra,104(sp)
    80002d74:	7406                	ld	s0,96(sp)
    80002d76:	64e6                	ld	s1,88(sp)
    80002d78:	6946                	ld	s2,80(sp)
    80002d7a:	69a6                	ld	s3,72(sp)
    80002d7c:	6a06                	ld	s4,64(sp)
    80002d7e:	7ae2                	ld	s5,56(sp)
    80002d80:	7b42                	ld	s6,48(sp)
    80002d82:	7ba2                	ld	s7,40(sp)
    80002d84:	7c02                	ld	s8,32(sp)
    80002d86:	6ce2                	ld	s9,24(sp)
    80002d88:	6d42                	ld	s10,16(sp)
    80002d8a:	6da2                	ld	s11,8(sp)
    80002d8c:	6165                	addi	sp,sp,112
    80002d8e:	8082                	ret

0000000080002d90 <reparent>:
{
    80002d90:	7179                	addi	sp,sp,-48
    80002d92:	f406                	sd	ra,40(sp)
    80002d94:	f022                	sd	s0,32(sp)
    80002d96:	ec26                	sd	s1,24(sp)
    80002d98:	e84a                	sd	s2,16(sp)
    80002d9a:	e44e                	sd	s3,8(sp)
    80002d9c:	e052                	sd	s4,0(sp)
    80002d9e:	1800                	addi	s0,sp,48
    80002da0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002da2:	0000f497          	auipc	s1,0xf
    80002da6:	aae48493          	addi	s1,s1,-1362 # 80011850 <proc>
      pp->parent = initproc;
    80002daa:	00006a17          	auipc	s4,0x6
    80002dae:	27ea0a13          	addi	s4,s4,638 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002db2:	00015997          	auipc	s3,0x15
    80002db6:	e9e98993          	addi	s3,s3,-354 # 80017c50 <tickslock>
    80002dba:	a029                	j	80002dc4 <reparent+0x34>
    80002dbc:	19048493          	addi	s1,s1,400
    80002dc0:	01348d63          	beq	s1,s3,80002dda <reparent+0x4a>
    if(pp->parent == p){
    80002dc4:	7c9c                	ld	a5,56(s1)
    80002dc6:	ff279be3          	bne	a5,s2,80002dbc <reparent+0x2c>
      pp->parent = initproc;
    80002dca:	000a3503          	ld	a0,0(s4)
    80002dce:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002dd0:	00000097          	auipc	ra,0x0
    80002dd4:	e78080e7          	jalr	-392(ra) # 80002c48 <wakeup>
    80002dd8:	b7d5                	j	80002dbc <reparent+0x2c>
}
    80002dda:	70a2                	ld	ra,40(sp)
    80002ddc:	7402                	ld	s0,32(sp)
    80002dde:	64e2                	ld	s1,24(sp)
    80002de0:	6942                	ld	s2,16(sp)
    80002de2:	69a2                	ld	s3,8(sp)
    80002de4:	6a02                	ld	s4,0(sp)
    80002de6:	6145                	addi	sp,sp,48
    80002de8:	8082                	ret

0000000080002dea <exit>:
{
    80002dea:	7179                	addi	sp,sp,-48
    80002dec:	f406                	sd	ra,40(sp)
    80002dee:	f022                	sd	s0,32(sp)
    80002df0:	ec26                	sd	s1,24(sp)
    80002df2:	e84a                	sd	s2,16(sp)
    80002df4:	e44e                	sd	s3,8(sp)
    80002df6:	e052                	sd	s4,0(sp)
    80002df8:	1800                	addi	s0,sp,48
    80002dfa:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	0c8080e7          	jalr	200(ra) # 80001ec4 <myproc>
    80002e04:	89aa                	mv	s3,a0
  if(p == initproc)
    80002e06:	00006797          	auipc	a5,0x6
    80002e0a:	2227b783          	ld	a5,546(a5) # 80009028 <initproc>
    80002e0e:	0d050493          	addi	s1,a0,208
    80002e12:	15050913          	addi	s2,a0,336
    80002e16:	02a79363          	bne	a5,a0,80002e3c <exit+0x52>
    panic("init exiting");
    80002e1a:	00005517          	auipc	a0,0x5
    80002e1e:	72650513          	addi	a0,a0,1830 # 80008540 <digits+0x500>
    80002e22:	ffffd097          	auipc	ra,0xffffd
    80002e26:	71c080e7          	jalr	1820(ra) # 8000053e <panic>
      fileclose(f);
    80002e2a:	00002097          	auipc	ra,0x2
    80002e2e:	03a080e7          	jalr	58(ra) # 80004e64 <fileclose>
      p->ofile[fd] = 0;
    80002e32:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002e36:	04a1                	addi	s1,s1,8
    80002e38:	01248563          	beq	s1,s2,80002e42 <exit+0x58>
    if(p->ofile[fd]){
    80002e3c:	6088                	ld	a0,0(s1)
    80002e3e:	f575                	bnez	a0,80002e2a <exit+0x40>
    80002e40:	bfdd                	j	80002e36 <exit+0x4c>
  begin_op();
    80002e42:	00002097          	auipc	ra,0x2
    80002e46:	b56080e7          	jalr	-1194(ra) # 80004998 <begin_op>
  iput(p->cwd);
    80002e4a:	1509b503          	ld	a0,336(s3)
    80002e4e:	00001097          	auipc	ra,0x1
    80002e52:	332080e7          	jalr	818(ra) # 80004180 <iput>
  end_op();
    80002e56:	00002097          	auipc	ra,0x2
    80002e5a:	bc2080e7          	jalr	-1086(ra) # 80004a18 <end_op>
  p->cwd = 0;
    80002e5e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002e62:	0000f497          	auipc	s1,0xf
    80002e66:	9d648493          	addi	s1,s1,-1578 # 80011838 <wait_lock>
    80002e6a:	8526                	mv	a0,s1
    80002e6c:	ffffe097          	auipc	ra,0xffffe
    80002e70:	d78080e7          	jalr	-648(ra) # 80000be4 <acquire>
  reparent(p);
    80002e74:	854e                	mv	a0,s3
    80002e76:	00000097          	auipc	ra,0x0
    80002e7a:	f1a080e7          	jalr	-230(ra) # 80002d90 <reparent>
  wakeup(p->parent);
    80002e7e:	0389b503          	ld	a0,56(s3)
    80002e82:	00000097          	auipc	ra,0x0
    80002e86:	dc6080e7          	jalr	-570(ra) # 80002c48 <wakeup>
  acquire(&p->lock);
    80002e8a:	854e                	mv	a0,s3
    80002e8c:	ffffe097          	auipc	ra,0xffffe
    80002e90:	d58080e7          	jalr	-680(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002e94:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002e98:	4795                	li	a5,5
    80002e9a:	00f9ac23          	sw	a5,24(s3)
  printf("insert exit zombie %d\n", p->index); //delete
    80002e9e:	16c9a583          	lw	a1,364(s3)
    80002ea2:	00005517          	auipc	a0,0x5
    80002ea6:	6ae50513          	addi	a0,a0,1710 # 80008550 <digits+0x510>
    80002eaa:	ffffd097          	auipc	ra,0xffffd
    80002eae:	6de080e7          	jalr	1758(ra) # 80000588 <printf>
  insert_proc_to_list(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    80002eb2:	85ce                	mv	a1,s3
    80002eb4:	00006517          	auipc	a0,0x6
    80002eb8:	c8c50513          	addi	a0,a0,-884 # 80008b40 <zombie_list>
    80002ebc:	fffff097          	auipc	ra,0xfffff
    80002ec0:	aee080e7          	jalr	-1298(ra) # 800019aa <insert_proc_to_list>
  release(&wait_lock);
    80002ec4:	8526                	mv	a0,s1
    80002ec6:	ffffe097          	auipc	ra,0xffffe
    80002eca:	dd2080e7          	jalr	-558(ra) # 80000c98 <release>
  sched();
    80002ece:	fffff097          	auipc	ra,0xfffff
    80002ed2:	5ee080e7          	jalr	1518(ra) # 800024bc <sched>
  panic("zombie exit");
    80002ed6:	00005517          	auipc	a0,0x5
    80002eda:	69250513          	addi	a0,a0,1682 # 80008568 <digits+0x528>
    80002ede:	ffffd097          	auipc	ra,0xffffd
    80002ee2:	660080e7          	jalr	1632(ra) # 8000053e <panic>

0000000080002ee6 <swtch>:
    80002ee6:	00153023          	sd	ra,0(a0)
    80002eea:	00253423          	sd	sp,8(a0)
    80002eee:	e900                	sd	s0,16(a0)
    80002ef0:	ed04                	sd	s1,24(a0)
    80002ef2:	03253023          	sd	s2,32(a0)
    80002ef6:	03353423          	sd	s3,40(a0)
    80002efa:	03453823          	sd	s4,48(a0)
    80002efe:	03553c23          	sd	s5,56(a0)
    80002f02:	05653023          	sd	s6,64(a0)
    80002f06:	05753423          	sd	s7,72(a0)
    80002f0a:	05853823          	sd	s8,80(a0)
    80002f0e:	05953c23          	sd	s9,88(a0)
    80002f12:	07a53023          	sd	s10,96(a0)
    80002f16:	07b53423          	sd	s11,104(a0)
    80002f1a:	0005b083          	ld	ra,0(a1)
    80002f1e:	0085b103          	ld	sp,8(a1)
    80002f22:	6980                	ld	s0,16(a1)
    80002f24:	6d84                	ld	s1,24(a1)
    80002f26:	0205b903          	ld	s2,32(a1)
    80002f2a:	0285b983          	ld	s3,40(a1)
    80002f2e:	0305ba03          	ld	s4,48(a1)
    80002f32:	0385ba83          	ld	s5,56(a1)
    80002f36:	0405bb03          	ld	s6,64(a1)
    80002f3a:	0485bb83          	ld	s7,72(a1)
    80002f3e:	0505bc03          	ld	s8,80(a1)
    80002f42:	0585bc83          	ld	s9,88(a1)
    80002f46:	0605bd03          	ld	s10,96(a1)
    80002f4a:	0685bd83          	ld	s11,104(a1)
    80002f4e:	8082                	ret

0000000080002f50 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002f50:	1141                	addi	sp,sp,-16
    80002f52:	e406                	sd	ra,8(sp)
    80002f54:	e022                	sd	s0,0(sp)
    80002f56:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002f58:	00005597          	auipc	a1,0x5
    80002f5c:	67858593          	addi	a1,a1,1656 # 800085d0 <states.1816+0x30>
    80002f60:	00015517          	auipc	a0,0x15
    80002f64:	cf050513          	addi	a0,a0,-784 # 80017c50 <tickslock>
    80002f68:	ffffe097          	auipc	ra,0xffffe
    80002f6c:	bec080e7          	jalr	-1044(ra) # 80000b54 <initlock>
}
    80002f70:	60a2                	ld	ra,8(sp)
    80002f72:	6402                	ld	s0,0(sp)
    80002f74:	0141                	addi	sp,sp,16
    80002f76:	8082                	ret

0000000080002f78 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002f78:	1141                	addi	sp,sp,-16
    80002f7a:	e422                	sd	s0,8(sp)
    80002f7c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f7e:	00003797          	auipc	a5,0x3
    80002f82:	50278793          	addi	a5,a5,1282 # 80006480 <kernelvec>
    80002f86:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002f8a:	6422                	ld	s0,8(sp)
    80002f8c:	0141                	addi	sp,sp,16
    80002f8e:	8082                	ret

0000000080002f90 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002f90:	1141                	addi	sp,sp,-16
    80002f92:	e406                	sd	ra,8(sp)
    80002f94:	e022                	sd	s0,0(sp)
    80002f96:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	f2c080e7          	jalr	-212(ra) # 80001ec4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fa0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002fa4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fa6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002faa:	00004617          	auipc	a2,0x4
    80002fae:	05660613          	addi	a2,a2,86 # 80007000 <_trampoline>
    80002fb2:	00004697          	auipc	a3,0x4
    80002fb6:	04e68693          	addi	a3,a3,78 # 80007000 <_trampoline>
    80002fba:	8e91                	sub	a3,a3,a2
    80002fbc:	040007b7          	lui	a5,0x4000
    80002fc0:	17fd                	addi	a5,a5,-1
    80002fc2:	07b2                	slli	a5,a5,0xc
    80002fc4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fc6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002fca:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002fcc:	180026f3          	csrr	a3,satp
    80002fd0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002fd2:	6d38                	ld	a4,88(a0)
    80002fd4:	6134                	ld	a3,64(a0)
    80002fd6:	6585                	lui	a1,0x1
    80002fd8:	96ae                	add	a3,a3,a1
    80002fda:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002fdc:	6d38                	ld	a4,88(a0)
    80002fde:	00000697          	auipc	a3,0x0
    80002fe2:	13868693          	addi	a3,a3,312 # 80003116 <usertrap>
    80002fe6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002fe8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002fea:	8692                	mv	a3,tp
    80002fec:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fee:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ff2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ff6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ffa:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ffe:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003000:	6f18                	ld	a4,24(a4)
    80003002:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003006:	692c                	ld	a1,80(a0)
    80003008:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000300a:	00004717          	auipc	a4,0x4
    8000300e:	08670713          	addi	a4,a4,134 # 80007090 <userret>
    80003012:	8f11                	sub	a4,a4,a2
    80003014:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003016:	577d                	li	a4,-1
    80003018:	177e                	slli	a4,a4,0x3f
    8000301a:	8dd9                	or	a1,a1,a4
    8000301c:	02000537          	lui	a0,0x2000
    80003020:	157d                	addi	a0,a0,-1
    80003022:	0536                	slli	a0,a0,0xd
    80003024:	9782                	jalr	a5
}
    80003026:	60a2                	ld	ra,8(sp)
    80003028:	6402                	ld	s0,0(sp)
    8000302a:	0141                	addi	sp,sp,16
    8000302c:	8082                	ret

000000008000302e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000302e:	1101                	addi	sp,sp,-32
    80003030:	ec06                	sd	ra,24(sp)
    80003032:	e822                	sd	s0,16(sp)
    80003034:	e426                	sd	s1,8(sp)
    80003036:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003038:	00015497          	auipc	s1,0x15
    8000303c:	c1848493          	addi	s1,s1,-1000 # 80017c50 <tickslock>
    80003040:	8526                	mv	a0,s1
    80003042:	ffffe097          	auipc	ra,0xffffe
    80003046:	ba2080e7          	jalr	-1118(ra) # 80000be4 <acquire>
  ticks++;
    8000304a:	00006517          	auipc	a0,0x6
    8000304e:	fe650513          	addi	a0,a0,-26 # 80009030 <ticks>
    80003052:	411c                	lw	a5,0(a0)
    80003054:	2785                	addiw	a5,a5,1
    80003056:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003058:	00000097          	auipc	ra,0x0
    8000305c:	bf0080e7          	jalr	-1040(ra) # 80002c48 <wakeup>
  release(&tickslock);
    80003060:	8526                	mv	a0,s1
    80003062:	ffffe097          	auipc	ra,0xffffe
    80003066:	c36080e7          	jalr	-970(ra) # 80000c98 <release>
}
    8000306a:	60e2                	ld	ra,24(sp)
    8000306c:	6442                	ld	s0,16(sp)
    8000306e:	64a2                	ld	s1,8(sp)
    80003070:	6105                	addi	sp,sp,32
    80003072:	8082                	ret

0000000080003074 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003074:	1101                	addi	sp,sp,-32
    80003076:	ec06                	sd	ra,24(sp)
    80003078:	e822                	sd	s0,16(sp)
    8000307a:	e426                	sd	s1,8(sp)
    8000307c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000307e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003082:	00074d63          	bltz	a4,8000309c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003086:	57fd                	li	a5,-1
    80003088:	17fe                	slli	a5,a5,0x3f
    8000308a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000308c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000308e:	06f70363          	beq	a4,a5,800030f4 <devintr+0x80>
  }
}
    80003092:	60e2                	ld	ra,24(sp)
    80003094:	6442                	ld	s0,16(sp)
    80003096:	64a2                	ld	s1,8(sp)
    80003098:	6105                	addi	sp,sp,32
    8000309a:	8082                	ret
     (scause & 0xff) == 9){
    8000309c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800030a0:	46a5                	li	a3,9
    800030a2:	fed792e3          	bne	a5,a3,80003086 <devintr+0x12>
    int irq = plic_claim();
    800030a6:	00003097          	auipc	ra,0x3
    800030aa:	4e2080e7          	jalr	1250(ra) # 80006588 <plic_claim>
    800030ae:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800030b0:	47a9                	li	a5,10
    800030b2:	02f50763          	beq	a0,a5,800030e0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800030b6:	4785                	li	a5,1
    800030b8:	02f50963          	beq	a0,a5,800030ea <devintr+0x76>
    return 1;
    800030bc:	4505                	li	a0,1
    } else if(irq){
    800030be:	d8f1                	beqz	s1,80003092 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800030c0:	85a6                	mv	a1,s1
    800030c2:	00005517          	auipc	a0,0x5
    800030c6:	51650513          	addi	a0,a0,1302 # 800085d8 <states.1816+0x38>
    800030ca:	ffffd097          	auipc	ra,0xffffd
    800030ce:	4be080e7          	jalr	1214(ra) # 80000588 <printf>
      plic_complete(irq);
    800030d2:	8526                	mv	a0,s1
    800030d4:	00003097          	auipc	ra,0x3
    800030d8:	4d8080e7          	jalr	1240(ra) # 800065ac <plic_complete>
    return 1;
    800030dc:	4505                	li	a0,1
    800030de:	bf55                	j	80003092 <devintr+0x1e>
      uartintr();
    800030e0:	ffffe097          	auipc	ra,0xffffe
    800030e4:	8c8080e7          	jalr	-1848(ra) # 800009a8 <uartintr>
    800030e8:	b7ed                	j	800030d2 <devintr+0x5e>
      virtio_disk_intr();
    800030ea:	00004097          	auipc	ra,0x4
    800030ee:	9a2080e7          	jalr	-1630(ra) # 80006a8c <virtio_disk_intr>
    800030f2:	b7c5                	j	800030d2 <devintr+0x5e>
    if(cpuid() == 0){
    800030f4:	fffff097          	auipc	ra,0xfffff
    800030f8:	d9e080e7          	jalr	-610(ra) # 80001e92 <cpuid>
    800030fc:	c901                	beqz	a0,8000310c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800030fe:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003102:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003104:	14479073          	csrw	sip,a5
    return 2;
    80003108:	4509                	li	a0,2
    8000310a:	b761                	j	80003092 <devintr+0x1e>
      clockintr();
    8000310c:	00000097          	auipc	ra,0x0
    80003110:	f22080e7          	jalr	-222(ra) # 8000302e <clockintr>
    80003114:	b7ed                	j	800030fe <devintr+0x8a>

0000000080003116 <usertrap>:
{
    80003116:	1101                	addi	sp,sp,-32
    80003118:	ec06                	sd	ra,24(sp)
    8000311a:	e822                	sd	s0,16(sp)
    8000311c:	e426                	sd	s1,8(sp)
    8000311e:	e04a                	sd	s2,0(sp)
    80003120:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003122:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003126:	1007f793          	andi	a5,a5,256
    8000312a:	e3ad                	bnez	a5,8000318c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000312c:	00003797          	auipc	a5,0x3
    80003130:	35478793          	addi	a5,a5,852 # 80006480 <kernelvec>
    80003134:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003138:	fffff097          	auipc	ra,0xfffff
    8000313c:	d8c080e7          	jalr	-628(ra) # 80001ec4 <myproc>
    80003140:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003142:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003144:	14102773          	csrr	a4,sepc
    80003148:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000314a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000314e:	47a1                	li	a5,8
    80003150:	04f71c63          	bne	a4,a5,800031a8 <usertrap+0x92>
    if(p->killed)
    80003154:	551c                	lw	a5,40(a0)
    80003156:	e3b9                	bnez	a5,8000319c <usertrap+0x86>
    p->trapframe->epc += 4;
    80003158:	6cb8                	ld	a4,88(s1)
    8000315a:	6f1c                	ld	a5,24(a4)
    8000315c:	0791                	addi	a5,a5,4
    8000315e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003160:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003164:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003168:	10079073          	csrw	sstatus,a5
    syscall();
    8000316c:	00000097          	auipc	ra,0x0
    80003170:	2e0080e7          	jalr	736(ra) # 8000344c <syscall>
  if(p->killed)
    80003174:	549c                	lw	a5,40(s1)
    80003176:	ebc1                	bnez	a5,80003206 <usertrap+0xf0>
  usertrapret();
    80003178:	00000097          	auipc	ra,0x0
    8000317c:	e18080e7          	jalr	-488(ra) # 80002f90 <usertrapret>
}
    80003180:	60e2                	ld	ra,24(sp)
    80003182:	6442                	ld	s0,16(sp)
    80003184:	64a2                	ld	s1,8(sp)
    80003186:	6902                	ld	s2,0(sp)
    80003188:	6105                	addi	sp,sp,32
    8000318a:	8082                	ret
    panic("usertrap: not from user mode");
    8000318c:	00005517          	auipc	a0,0x5
    80003190:	46c50513          	addi	a0,a0,1132 # 800085f8 <states.1816+0x58>
    80003194:	ffffd097          	auipc	ra,0xffffd
    80003198:	3aa080e7          	jalr	938(ra) # 8000053e <panic>
      exit(-1);
    8000319c:	557d                	li	a0,-1
    8000319e:	00000097          	auipc	ra,0x0
    800031a2:	c4c080e7          	jalr	-948(ra) # 80002dea <exit>
    800031a6:	bf4d                	j	80003158 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800031a8:	00000097          	auipc	ra,0x0
    800031ac:	ecc080e7          	jalr	-308(ra) # 80003074 <devintr>
    800031b0:	892a                	mv	s2,a0
    800031b2:	c501                	beqz	a0,800031ba <usertrap+0xa4>
  if(p->killed)
    800031b4:	549c                	lw	a5,40(s1)
    800031b6:	c3a1                	beqz	a5,800031f6 <usertrap+0xe0>
    800031b8:	a815                	j	800031ec <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031ba:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800031be:	5890                	lw	a2,48(s1)
    800031c0:	00005517          	auipc	a0,0x5
    800031c4:	45850513          	addi	a0,a0,1112 # 80008618 <states.1816+0x78>
    800031c8:	ffffd097          	auipc	ra,0xffffd
    800031cc:	3c0080e7          	jalr	960(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031d0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800031d4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800031d8:	00005517          	auipc	a0,0x5
    800031dc:	47050513          	addi	a0,a0,1136 # 80008648 <states.1816+0xa8>
    800031e0:	ffffd097          	auipc	ra,0xffffd
    800031e4:	3a8080e7          	jalr	936(ra) # 80000588 <printf>
    p->killed = 1;
    800031e8:	4785                	li	a5,1
    800031ea:	d49c                	sw	a5,40(s1)
    exit(-1);
    800031ec:	557d                	li	a0,-1
    800031ee:	00000097          	auipc	ra,0x0
    800031f2:	bfc080e7          	jalr	-1028(ra) # 80002dea <exit>
  if(which_dev == 2)
    800031f6:	4789                	li	a5,2
    800031f8:	f8f910e3          	bne	s2,a5,80003178 <usertrap+0x62>
    yield();
    800031fc:	fffff097          	auipc	ra,0xfffff
    80003200:	3c2080e7          	jalr	962(ra) # 800025be <yield>
    80003204:	bf95                	j	80003178 <usertrap+0x62>
  int which_dev = 0;
    80003206:	4901                	li	s2,0
    80003208:	b7d5                	j	800031ec <usertrap+0xd6>

000000008000320a <kerneltrap>:
{
    8000320a:	7179                	addi	sp,sp,-48
    8000320c:	f406                	sd	ra,40(sp)
    8000320e:	f022                	sd	s0,32(sp)
    80003210:	ec26                	sd	s1,24(sp)
    80003212:	e84a                	sd	s2,16(sp)
    80003214:	e44e                	sd	s3,8(sp)
    80003216:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003218:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000321c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003220:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003224:	1004f793          	andi	a5,s1,256
    80003228:	cb85                	beqz	a5,80003258 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000322a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000322e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003230:	ef85                	bnez	a5,80003268 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003232:	00000097          	auipc	ra,0x0
    80003236:	e42080e7          	jalr	-446(ra) # 80003074 <devintr>
    8000323a:	cd1d                	beqz	a0,80003278 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000323c:	4789                	li	a5,2
    8000323e:	06f50a63          	beq	a0,a5,800032b2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003242:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003246:	10049073          	csrw	sstatus,s1
}
    8000324a:	70a2                	ld	ra,40(sp)
    8000324c:	7402                	ld	s0,32(sp)
    8000324e:	64e2                	ld	s1,24(sp)
    80003250:	6942                	ld	s2,16(sp)
    80003252:	69a2                	ld	s3,8(sp)
    80003254:	6145                	addi	sp,sp,48
    80003256:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003258:	00005517          	auipc	a0,0x5
    8000325c:	41050513          	addi	a0,a0,1040 # 80008668 <states.1816+0xc8>
    80003260:	ffffd097          	auipc	ra,0xffffd
    80003264:	2de080e7          	jalr	734(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003268:	00005517          	auipc	a0,0x5
    8000326c:	42850513          	addi	a0,a0,1064 # 80008690 <states.1816+0xf0>
    80003270:	ffffd097          	auipc	ra,0xffffd
    80003274:	2ce080e7          	jalr	718(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003278:	85ce                	mv	a1,s3
    8000327a:	00005517          	auipc	a0,0x5
    8000327e:	43650513          	addi	a0,a0,1078 # 800086b0 <states.1816+0x110>
    80003282:	ffffd097          	auipc	ra,0xffffd
    80003286:	306080e7          	jalr	774(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000328a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000328e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003292:	00005517          	auipc	a0,0x5
    80003296:	42e50513          	addi	a0,a0,1070 # 800086c0 <states.1816+0x120>
    8000329a:	ffffd097          	auipc	ra,0xffffd
    8000329e:	2ee080e7          	jalr	750(ra) # 80000588 <printf>
    panic("kerneltrap");
    800032a2:	00005517          	auipc	a0,0x5
    800032a6:	43650513          	addi	a0,a0,1078 # 800086d8 <states.1816+0x138>
    800032aa:	ffffd097          	auipc	ra,0xffffd
    800032ae:	294080e7          	jalr	660(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800032b2:	fffff097          	auipc	ra,0xfffff
    800032b6:	c12080e7          	jalr	-1006(ra) # 80001ec4 <myproc>
    800032ba:	d541                	beqz	a0,80003242 <kerneltrap+0x38>
    800032bc:	fffff097          	auipc	ra,0xfffff
    800032c0:	c08080e7          	jalr	-1016(ra) # 80001ec4 <myproc>
    800032c4:	4d18                	lw	a4,24(a0)
    800032c6:	4791                	li	a5,4
    800032c8:	f6f71de3          	bne	a4,a5,80003242 <kerneltrap+0x38>
    yield();
    800032cc:	fffff097          	auipc	ra,0xfffff
    800032d0:	2f2080e7          	jalr	754(ra) # 800025be <yield>
    800032d4:	b7bd                	j	80003242 <kerneltrap+0x38>

00000000800032d6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800032d6:	1101                	addi	sp,sp,-32
    800032d8:	ec06                	sd	ra,24(sp)
    800032da:	e822                	sd	s0,16(sp)
    800032dc:	e426                	sd	s1,8(sp)
    800032de:	1000                	addi	s0,sp,32
    800032e0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800032e2:	fffff097          	auipc	ra,0xfffff
    800032e6:	be2080e7          	jalr	-1054(ra) # 80001ec4 <myproc>
  switch (n) {
    800032ea:	4795                	li	a5,5
    800032ec:	0497e163          	bltu	a5,s1,8000332e <argraw+0x58>
    800032f0:	048a                	slli	s1,s1,0x2
    800032f2:	00005717          	auipc	a4,0x5
    800032f6:	41e70713          	addi	a4,a4,1054 # 80008710 <states.1816+0x170>
    800032fa:	94ba                	add	s1,s1,a4
    800032fc:	409c                	lw	a5,0(s1)
    800032fe:	97ba                	add	a5,a5,a4
    80003300:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003302:	6d3c                	ld	a5,88(a0)
    80003304:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003306:	60e2                	ld	ra,24(sp)
    80003308:	6442                	ld	s0,16(sp)
    8000330a:	64a2                	ld	s1,8(sp)
    8000330c:	6105                	addi	sp,sp,32
    8000330e:	8082                	ret
    return p->trapframe->a1;
    80003310:	6d3c                	ld	a5,88(a0)
    80003312:	7fa8                	ld	a0,120(a5)
    80003314:	bfcd                	j	80003306 <argraw+0x30>
    return p->trapframe->a2;
    80003316:	6d3c                	ld	a5,88(a0)
    80003318:	63c8                	ld	a0,128(a5)
    8000331a:	b7f5                	j	80003306 <argraw+0x30>
    return p->trapframe->a3;
    8000331c:	6d3c                	ld	a5,88(a0)
    8000331e:	67c8                	ld	a0,136(a5)
    80003320:	b7dd                	j	80003306 <argraw+0x30>
    return p->trapframe->a4;
    80003322:	6d3c                	ld	a5,88(a0)
    80003324:	6bc8                	ld	a0,144(a5)
    80003326:	b7c5                	j	80003306 <argraw+0x30>
    return p->trapframe->a5;
    80003328:	6d3c                	ld	a5,88(a0)
    8000332a:	6fc8                	ld	a0,152(a5)
    8000332c:	bfe9                	j	80003306 <argraw+0x30>
  panic("argraw");
    8000332e:	00005517          	auipc	a0,0x5
    80003332:	3ba50513          	addi	a0,a0,954 # 800086e8 <states.1816+0x148>
    80003336:	ffffd097          	auipc	ra,0xffffd
    8000333a:	208080e7          	jalr	520(ra) # 8000053e <panic>

000000008000333e <fetchaddr>:
{
    8000333e:	1101                	addi	sp,sp,-32
    80003340:	ec06                	sd	ra,24(sp)
    80003342:	e822                	sd	s0,16(sp)
    80003344:	e426                	sd	s1,8(sp)
    80003346:	e04a                	sd	s2,0(sp)
    80003348:	1000                	addi	s0,sp,32
    8000334a:	84aa                	mv	s1,a0
    8000334c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000334e:	fffff097          	auipc	ra,0xfffff
    80003352:	b76080e7          	jalr	-1162(ra) # 80001ec4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003356:	653c                	ld	a5,72(a0)
    80003358:	02f4f863          	bgeu	s1,a5,80003388 <fetchaddr+0x4a>
    8000335c:	00848713          	addi	a4,s1,8
    80003360:	02e7e663          	bltu	a5,a4,8000338c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003364:	46a1                	li	a3,8
    80003366:	8626                	mv	a2,s1
    80003368:	85ca                	mv	a1,s2
    8000336a:	6928                	ld	a0,80(a0)
    8000336c:	ffffe097          	auipc	ra,0xffffe
    80003370:	392080e7          	jalr	914(ra) # 800016fe <copyin>
    80003374:	00a03533          	snez	a0,a0
    80003378:	40a00533          	neg	a0,a0
}
    8000337c:	60e2                	ld	ra,24(sp)
    8000337e:	6442                	ld	s0,16(sp)
    80003380:	64a2                	ld	s1,8(sp)
    80003382:	6902                	ld	s2,0(sp)
    80003384:	6105                	addi	sp,sp,32
    80003386:	8082                	ret
    return -1;
    80003388:	557d                	li	a0,-1
    8000338a:	bfcd                	j	8000337c <fetchaddr+0x3e>
    8000338c:	557d                	li	a0,-1
    8000338e:	b7fd                	j	8000337c <fetchaddr+0x3e>

0000000080003390 <fetchstr>:
{
    80003390:	7179                	addi	sp,sp,-48
    80003392:	f406                	sd	ra,40(sp)
    80003394:	f022                	sd	s0,32(sp)
    80003396:	ec26                	sd	s1,24(sp)
    80003398:	e84a                	sd	s2,16(sp)
    8000339a:	e44e                	sd	s3,8(sp)
    8000339c:	1800                	addi	s0,sp,48
    8000339e:	892a                	mv	s2,a0
    800033a0:	84ae                	mv	s1,a1
    800033a2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800033a4:	fffff097          	auipc	ra,0xfffff
    800033a8:	b20080e7          	jalr	-1248(ra) # 80001ec4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800033ac:	86ce                	mv	a3,s3
    800033ae:	864a                	mv	a2,s2
    800033b0:	85a6                	mv	a1,s1
    800033b2:	6928                	ld	a0,80(a0)
    800033b4:	ffffe097          	auipc	ra,0xffffe
    800033b8:	3d6080e7          	jalr	982(ra) # 8000178a <copyinstr>
  if(err < 0)
    800033bc:	00054763          	bltz	a0,800033ca <fetchstr+0x3a>
  return strlen(buf);
    800033c0:	8526                	mv	a0,s1
    800033c2:	ffffe097          	auipc	ra,0xffffe
    800033c6:	aa2080e7          	jalr	-1374(ra) # 80000e64 <strlen>
}
    800033ca:	70a2                	ld	ra,40(sp)
    800033cc:	7402                	ld	s0,32(sp)
    800033ce:	64e2                	ld	s1,24(sp)
    800033d0:	6942                	ld	s2,16(sp)
    800033d2:	69a2                	ld	s3,8(sp)
    800033d4:	6145                	addi	sp,sp,48
    800033d6:	8082                	ret

00000000800033d8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800033d8:	1101                	addi	sp,sp,-32
    800033da:	ec06                	sd	ra,24(sp)
    800033dc:	e822                	sd	s0,16(sp)
    800033de:	e426                	sd	s1,8(sp)
    800033e0:	1000                	addi	s0,sp,32
    800033e2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800033e4:	00000097          	auipc	ra,0x0
    800033e8:	ef2080e7          	jalr	-270(ra) # 800032d6 <argraw>
    800033ec:	c088                	sw	a0,0(s1)
  return 0;
}
    800033ee:	4501                	li	a0,0
    800033f0:	60e2                	ld	ra,24(sp)
    800033f2:	6442                	ld	s0,16(sp)
    800033f4:	64a2                	ld	s1,8(sp)
    800033f6:	6105                	addi	sp,sp,32
    800033f8:	8082                	ret

00000000800033fa <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800033fa:	1101                	addi	sp,sp,-32
    800033fc:	ec06                	sd	ra,24(sp)
    800033fe:	e822                	sd	s0,16(sp)
    80003400:	e426                	sd	s1,8(sp)
    80003402:	1000                	addi	s0,sp,32
    80003404:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	ed0080e7          	jalr	-304(ra) # 800032d6 <argraw>
    8000340e:	e088                	sd	a0,0(s1)
  return 0;
}
    80003410:	4501                	li	a0,0
    80003412:	60e2                	ld	ra,24(sp)
    80003414:	6442                	ld	s0,16(sp)
    80003416:	64a2                	ld	s1,8(sp)
    80003418:	6105                	addi	sp,sp,32
    8000341a:	8082                	ret

000000008000341c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000341c:	1101                	addi	sp,sp,-32
    8000341e:	ec06                	sd	ra,24(sp)
    80003420:	e822                	sd	s0,16(sp)
    80003422:	e426                	sd	s1,8(sp)
    80003424:	e04a                	sd	s2,0(sp)
    80003426:	1000                	addi	s0,sp,32
    80003428:	84ae                	mv	s1,a1
    8000342a:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000342c:	00000097          	auipc	ra,0x0
    80003430:	eaa080e7          	jalr	-342(ra) # 800032d6 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003434:	864a                	mv	a2,s2
    80003436:	85a6                	mv	a1,s1
    80003438:	00000097          	auipc	ra,0x0
    8000343c:	f58080e7          	jalr	-168(ra) # 80003390 <fetchstr>
}
    80003440:	60e2                	ld	ra,24(sp)
    80003442:	6442                	ld	s0,16(sp)
    80003444:	64a2                	ld	s1,8(sp)
    80003446:	6902                	ld	s2,0(sp)
    80003448:	6105                	addi	sp,sp,32
    8000344a:	8082                	ret

000000008000344c <syscall>:
[SYS_cpu_process_count]   sys_cpu_process_count,
};

void
syscall(void)
{
    8000344c:	1101                	addi	sp,sp,-32
    8000344e:	ec06                	sd	ra,24(sp)
    80003450:	e822                	sd	s0,16(sp)
    80003452:	e426                	sd	s1,8(sp)
    80003454:	e04a                	sd	s2,0(sp)
    80003456:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003458:	fffff097          	auipc	ra,0xfffff
    8000345c:	a6c080e7          	jalr	-1428(ra) # 80001ec4 <myproc>
    80003460:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003462:	05853903          	ld	s2,88(a0)
    80003466:	0a893783          	ld	a5,168(s2)
    8000346a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000346e:	37fd                	addiw	a5,a5,-1
    80003470:	475d                	li	a4,23
    80003472:	00f76f63          	bltu	a4,a5,80003490 <syscall+0x44>
    80003476:	00369713          	slli	a4,a3,0x3
    8000347a:	00005797          	auipc	a5,0x5
    8000347e:	2ae78793          	addi	a5,a5,686 # 80008728 <syscalls>
    80003482:	97ba                	add	a5,a5,a4
    80003484:	639c                	ld	a5,0(a5)
    80003486:	c789                	beqz	a5,80003490 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003488:	9782                	jalr	a5
    8000348a:	06a93823          	sd	a0,112(s2)
    8000348e:	a839                	j	800034ac <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003490:	15848613          	addi	a2,s1,344
    80003494:	588c                	lw	a1,48(s1)
    80003496:	00005517          	auipc	a0,0x5
    8000349a:	25a50513          	addi	a0,a0,602 # 800086f0 <states.1816+0x150>
    8000349e:	ffffd097          	auipc	ra,0xffffd
    800034a2:	0ea080e7          	jalr	234(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800034a6:	6cbc                	ld	a5,88(s1)
    800034a8:	577d                	li	a4,-1
    800034aa:	fbb8                	sd	a4,112(a5)
  }
}
    800034ac:	60e2                	ld	ra,24(sp)
    800034ae:	6442                	ld	s0,16(sp)
    800034b0:	64a2                	ld	s1,8(sp)
    800034b2:	6902                	ld	s2,0(sp)
    800034b4:	6105                	addi	sp,sp,32
    800034b6:	8082                	ret

00000000800034b8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800034b8:	1101                	addi	sp,sp,-32
    800034ba:	ec06                	sd	ra,24(sp)
    800034bc:	e822                	sd	s0,16(sp)
    800034be:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800034c0:	fec40593          	addi	a1,s0,-20
    800034c4:	4501                	li	a0,0
    800034c6:	00000097          	auipc	ra,0x0
    800034ca:	f12080e7          	jalr	-238(ra) # 800033d8 <argint>
    return -1;
    800034ce:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800034d0:	00054963          	bltz	a0,800034e2 <sys_exit+0x2a>
  exit(n);
    800034d4:	fec42503          	lw	a0,-20(s0)
    800034d8:	00000097          	auipc	ra,0x0
    800034dc:	912080e7          	jalr	-1774(ra) # 80002dea <exit>
  return 0;  // not reached
    800034e0:	4781                	li	a5,0
}
    800034e2:	853e                	mv	a0,a5
    800034e4:	60e2                	ld	ra,24(sp)
    800034e6:	6442                	ld	s0,16(sp)
    800034e8:	6105                	addi	sp,sp,32
    800034ea:	8082                	ret

00000000800034ec <sys_getpid>:

uint64
sys_getpid(void)
{
    800034ec:	1141                	addi	sp,sp,-16
    800034ee:	e406                	sd	ra,8(sp)
    800034f0:	e022                	sd	s0,0(sp)
    800034f2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800034f4:	fffff097          	auipc	ra,0xfffff
    800034f8:	9d0080e7          	jalr	-1584(ra) # 80001ec4 <myproc>
}
    800034fc:	5908                	lw	a0,48(a0)
    800034fe:	60a2                	ld	ra,8(sp)
    80003500:	6402                	ld	s0,0(sp)
    80003502:	0141                	addi	sp,sp,16
    80003504:	8082                	ret

0000000080003506 <sys_fork>:

uint64
sys_fork(void)
{
    80003506:	1141                	addi	sp,sp,-16
    80003508:	e406                	sd	ra,8(sp)
    8000350a:	e022                	sd	s0,0(sp)
    8000350c:	0800                	addi	s0,sp,16
  return fork();
    8000350e:	fffff097          	auipc	ra,0xfffff
    80003512:	5b2080e7          	jalr	1458(ra) # 80002ac0 <fork>
}
    80003516:	60a2                	ld	ra,8(sp)
    80003518:	6402                	ld	s0,0(sp)
    8000351a:	0141                	addi	sp,sp,16
    8000351c:	8082                	ret

000000008000351e <sys_wait>:

uint64
sys_wait(void)
{
    8000351e:	1101                	addi	sp,sp,-32
    80003520:	ec06                	sd	ra,24(sp)
    80003522:	e822                	sd	s0,16(sp)
    80003524:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003526:	fe840593          	addi	a1,s0,-24
    8000352a:	4501                	li	a0,0
    8000352c:	00000097          	auipc	ra,0x0
    80003530:	ece080e7          	jalr	-306(ra) # 800033fa <argaddr>
    80003534:	87aa                	mv	a5,a0
    return -1;
    80003536:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003538:	0007c863          	bltz	a5,80003548 <sys_wait+0x2a>
  return wait(p);
    8000353c:	fe843503          	ld	a0,-24(s0)
    80003540:	fffff097          	auipc	ra,0xfffff
    80003544:	17c080e7          	jalr	380(ra) # 800026bc <wait>
}
    80003548:	60e2                	ld	ra,24(sp)
    8000354a:	6442                	ld	s0,16(sp)
    8000354c:	6105                	addi	sp,sp,32
    8000354e:	8082                	ret

0000000080003550 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003550:	7179                	addi	sp,sp,-48
    80003552:	f406                	sd	ra,40(sp)
    80003554:	f022                	sd	s0,32(sp)
    80003556:	ec26                	sd	s1,24(sp)
    80003558:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000355a:	fdc40593          	addi	a1,s0,-36
    8000355e:	4501                	li	a0,0
    80003560:	00000097          	auipc	ra,0x0
    80003564:	e78080e7          	jalr	-392(ra) # 800033d8 <argint>
    80003568:	87aa                	mv	a5,a0
    return -1;
    8000356a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000356c:	0207c063          	bltz	a5,8000358c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003570:	fffff097          	auipc	ra,0xfffff
    80003574:	954080e7          	jalr	-1708(ra) # 80001ec4 <myproc>
    80003578:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000357a:	fdc42503          	lw	a0,-36(s0)
    8000357e:	fffff097          	auipc	ra,0xfffff
    80003582:	db6080e7          	jalr	-586(ra) # 80002334 <growproc>
    80003586:	00054863          	bltz	a0,80003596 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000358a:	8526                	mv	a0,s1
}
    8000358c:	70a2                	ld	ra,40(sp)
    8000358e:	7402                	ld	s0,32(sp)
    80003590:	64e2                	ld	s1,24(sp)
    80003592:	6145                	addi	sp,sp,48
    80003594:	8082                	ret
    return -1;
    80003596:	557d                	li	a0,-1
    80003598:	bfd5                	j	8000358c <sys_sbrk+0x3c>

000000008000359a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000359a:	7139                	addi	sp,sp,-64
    8000359c:	fc06                	sd	ra,56(sp)
    8000359e:	f822                	sd	s0,48(sp)
    800035a0:	f426                	sd	s1,40(sp)
    800035a2:	f04a                	sd	s2,32(sp)
    800035a4:	ec4e                	sd	s3,24(sp)
    800035a6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800035a8:	fcc40593          	addi	a1,s0,-52
    800035ac:	4501                	li	a0,0
    800035ae:	00000097          	auipc	ra,0x0
    800035b2:	e2a080e7          	jalr	-470(ra) # 800033d8 <argint>
    return -1;
    800035b6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800035b8:	06054563          	bltz	a0,80003622 <sys_sleep+0x88>
  acquire(&tickslock);
    800035bc:	00014517          	auipc	a0,0x14
    800035c0:	69450513          	addi	a0,a0,1684 # 80017c50 <tickslock>
    800035c4:	ffffd097          	auipc	ra,0xffffd
    800035c8:	620080e7          	jalr	1568(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800035cc:	00006917          	auipc	s2,0x6
    800035d0:	a6492903          	lw	s2,-1436(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800035d4:	fcc42783          	lw	a5,-52(s0)
    800035d8:	cf85                	beqz	a5,80003610 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800035da:	00014997          	auipc	s3,0x14
    800035de:	67698993          	addi	s3,s3,1654 # 80017c50 <tickslock>
    800035e2:	00006497          	auipc	s1,0x6
    800035e6:	a4e48493          	addi	s1,s1,-1458 # 80009030 <ticks>
    if(myproc()->killed){
    800035ea:	fffff097          	auipc	ra,0xfffff
    800035ee:	8da080e7          	jalr	-1830(ra) # 80001ec4 <myproc>
    800035f2:	551c                	lw	a5,40(a0)
    800035f4:	ef9d                	bnez	a5,80003632 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800035f6:	85ce                	mv	a1,s3
    800035f8:	8526                	mv	a0,s1
    800035fa:	fffff097          	auipc	ra,0xfffff
    800035fe:	038080e7          	jalr	56(ra) # 80002632 <sleep>
  while(ticks - ticks0 < n){
    80003602:	409c                	lw	a5,0(s1)
    80003604:	412787bb          	subw	a5,a5,s2
    80003608:	fcc42703          	lw	a4,-52(s0)
    8000360c:	fce7efe3          	bltu	a5,a4,800035ea <sys_sleep+0x50>
  }
  release(&tickslock);
    80003610:	00014517          	auipc	a0,0x14
    80003614:	64050513          	addi	a0,a0,1600 # 80017c50 <tickslock>
    80003618:	ffffd097          	auipc	ra,0xffffd
    8000361c:	680080e7          	jalr	1664(ra) # 80000c98 <release>
  return 0;
    80003620:	4781                	li	a5,0
}
    80003622:	853e                	mv	a0,a5
    80003624:	70e2                	ld	ra,56(sp)
    80003626:	7442                	ld	s0,48(sp)
    80003628:	74a2                	ld	s1,40(sp)
    8000362a:	7902                	ld	s2,32(sp)
    8000362c:	69e2                	ld	s3,24(sp)
    8000362e:	6121                	addi	sp,sp,64
    80003630:	8082                	ret
      release(&tickslock);
    80003632:	00014517          	auipc	a0,0x14
    80003636:	61e50513          	addi	a0,a0,1566 # 80017c50 <tickslock>
    8000363a:	ffffd097          	auipc	ra,0xffffd
    8000363e:	65e080e7          	jalr	1630(ra) # 80000c98 <release>
      return -1;
    80003642:	57fd                	li	a5,-1
    80003644:	bff9                	j	80003622 <sys_sleep+0x88>

0000000080003646 <sys_kill>:

uint64
sys_kill(void)
{
    80003646:	1101                	addi	sp,sp,-32
    80003648:	ec06                	sd	ra,24(sp)
    8000364a:	e822                	sd	s0,16(sp)
    8000364c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000364e:	fec40593          	addi	a1,s0,-20
    80003652:	4501                	li	a0,0
    80003654:	00000097          	auipc	ra,0x0
    80003658:	d84080e7          	jalr	-636(ra) # 800033d8 <argint>
    8000365c:	87aa                	mv	a5,a0
    return -1;
    8000365e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003660:	0007c863          	bltz	a5,80003670 <sys_kill+0x2a>
  return kill(pid);
    80003664:	fec42503          	lw	a0,-20(s0)
    80003668:	fffff097          	auipc	ra,0xfffff
    8000366c:	17c080e7          	jalr	380(ra) # 800027e4 <kill>
}
    80003670:	60e2                	ld	ra,24(sp)
    80003672:	6442                	ld	s0,16(sp)
    80003674:	6105                	addi	sp,sp,32
    80003676:	8082                	ret

0000000080003678 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003678:	1101                	addi	sp,sp,-32
    8000367a:	ec06                	sd	ra,24(sp)
    8000367c:	e822                	sd	s0,16(sp)
    8000367e:	e426                	sd	s1,8(sp)
    80003680:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003682:	00014517          	auipc	a0,0x14
    80003686:	5ce50513          	addi	a0,a0,1486 # 80017c50 <tickslock>
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	55a080e7          	jalr	1370(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003692:	00006497          	auipc	s1,0x6
    80003696:	99e4a483          	lw	s1,-1634(s1) # 80009030 <ticks>
  release(&tickslock);
    8000369a:	00014517          	auipc	a0,0x14
    8000369e:	5b650513          	addi	a0,a0,1462 # 80017c50 <tickslock>
    800036a2:	ffffd097          	auipc	ra,0xffffd
    800036a6:	5f6080e7          	jalr	1526(ra) # 80000c98 <release>
  return xticks;
}
    800036aa:	02049513          	slli	a0,s1,0x20
    800036ae:	9101                	srli	a0,a0,0x20
    800036b0:	60e2                	ld	ra,24(sp)
    800036b2:	6442                	ld	s0,16(sp)
    800036b4:	64a2                	ld	s1,8(sp)
    800036b6:	6105                	addi	sp,sp,32
    800036b8:	8082                	ret

00000000800036ba <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    800036ba:	1101                	addi	sp,sp,-32
    800036bc:	ec06                	sd	ra,24(sp)
    800036be:	e822                	sd	s0,16(sp)
    800036c0:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    800036c2:	fec40593          	addi	a1,s0,-20
    800036c6:	4501                	li	a0,0
    800036c8:	00000097          	auipc	ra,0x0
    800036cc:	d10080e7          	jalr	-752(ra) # 800033d8 <argint>
    800036d0:	87aa                	mv	a5,a0
    return -1;
    800036d2:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    800036d4:	0007c863          	bltz	a5,800036e4 <sys_set_cpu+0x2a>
  return set_cpu(cpu_id);
    800036d8:	fec42503          	lw	a0,-20(s0)
    800036dc:	fffff097          	auipc	ra,0xfffff
    800036e0:	2d4080e7          	jalr	724(ra) # 800029b0 <set_cpu>
}
    800036e4:	60e2                	ld	ra,24(sp)
    800036e6:	6442                	ld	s0,16(sp)
    800036e8:	6105                	addi	sp,sp,32
    800036ea:	8082                	ret

00000000800036ec <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    800036ec:	1141                	addi	sp,sp,-16
    800036ee:	e406                	sd	ra,8(sp)
    800036f0:	e022                	sd	s0,0(sp)
    800036f2:	0800                	addi	s0,sp,16
  return get_cpu();
    800036f4:	fffff097          	auipc	ra,0xfffff
    800036f8:	30e080e7          	jalr	782(ra) # 80002a02 <get_cpu>
}
    800036fc:	60a2                	ld	ra,8(sp)
    800036fe:	6402                	ld	s0,0(sp)
    80003700:	0141                	addi	sp,sp,16
    80003702:	8082                	ret

0000000080003704 <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void)
{
    80003704:	1101                	addi	sp,sp,-32
    80003706:	ec06                	sd	ra,24(sp)
    80003708:	e822                	sd	s0,16(sp)
    8000370a:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    8000370c:	fec40593          	addi	a1,s0,-20
    80003710:	4501                	li	a0,0
    80003712:	00000097          	auipc	ra,0x0
    80003716:	cc6080e7          	jalr	-826(ra) # 800033d8 <argint>
    8000371a:	87aa                	mv	a5,a0
    return -1;
    8000371c:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    8000371e:	0007c863          	bltz	a5,8000372e <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpu_id);
    80003722:	fec42503          	lw	a0,-20(s0)
    80003726:	fffff097          	auipc	ra,0xfffff
    8000372a:	336080e7          	jalr	822(ra) # 80002a5c <cpu_process_count>
}
    8000372e:	60e2                	ld	ra,24(sp)
    80003730:	6442                	ld	s0,16(sp)
    80003732:	6105                	addi	sp,sp,32
    80003734:	8082                	ret

0000000080003736 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003736:	7179                	addi	sp,sp,-48
    80003738:	f406                	sd	ra,40(sp)
    8000373a:	f022                	sd	s0,32(sp)
    8000373c:	ec26                	sd	s1,24(sp)
    8000373e:	e84a                	sd	s2,16(sp)
    80003740:	e44e                	sd	s3,8(sp)
    80003742:	e052                	sd	s4,0(sp)
    80003744:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003746:	00005597          	auipc	a1,0x5
    8000374a:	0aa58593          	addi	a1,a1,170 # 800087f0 <syscalls+0xc8>
    8000374e:	00014517          	auipc	a0,0x14
    80003752:	51a50513          	addi	a0,a0,1306 # 80017c68 <bcache>
    80003756:	ffffd097          	auipc	ra,0xffffd
    8000375a:	3fe080e7          	jalr	1022(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000375e:	0001c797          	auipc	a5,0x1c
    80003762:	50a78793          	addi	a5,a5,1290 # 8001fc68 <bcache+0x8000>
    80003766:	0001c717          	auipc	a4,0x1c
    8000376a:	76a70713          	addi	a4,a4,1898 # 8001fed0 <bcache+0x8268>
    8000376e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003772:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003776:	00014497          	auipc	s1,0x14
    8000377a:	50a48493          	addi	s1,s1,1290 # 80017c80 <bcache+0x18>
    b->next = bcache.head.next;
    8000377e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003780:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003782:	00005a17          	auipc	s4,0x5
    80003786:	076a0a13          	addi	s4,s4,118 # 800087f8 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000378a:	2b893783          	ld	a5,696(s2)
    8000378e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003790:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003794:	85d2                	mv	a1,s4
    80003796:	01048513          	addi	a0,s1,16
    8000379a:	00001097          	auipc	ra,0x1
    8000379e:	4bc080e7          	jalr	1212(ra) # 80004c56 <initsleeplock>
    bcache.head.next->prev = b;
    800037a2:	2b893783          	ld	a5,696(s2)
    800037a6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800037a8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800037ac:	45848493          	addi	s1,s1,1112
    800037b0:	fd349de3          	bne	s1,s3,8000378a <binit+0x54>
  }
}
    800037b4:	70a2                	ld	ra,40(sp)
    800037b6:	7402                	ld	s0,32(sp)
    800037b8:	64e2                	ld	s1,24(sp)
    800037ba:	6942                	ld	s2,16(sp)
    800037bc:	69a2                	ld	s3,8(sp)
    800037be:	6a02                	ld	s4,0(sp)
    800037c0:	6145                	addi	sp,sp,48
    800037c2:	8082                	ret

00000000800037c4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800037c4:	7179                	addi	sp,sp,-48
    800037c6:	f406                	sd	ra,40(sp)
    800037c8:	f022                	sd	s0,32(sp)
    800037ca:	ec26                	sd	s1,24(sp)
    800037cc:	e84a                	sd	s2,16(sp)
    800037ce:	e44e                	sd	s3,8(sp)
    800037d0:	1800                	addi	s0,sp,48
    800037d2:	89aa                	mv	s3,a0
    800037d4:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800037d6:	00014517          	auipc	a0,0x14
    800037da:	49250513          	addi	a0,a0,1170 # 80017c68 <bcache>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	406080e7          	jalr	1030(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800037e6:	0001c497          	auipc	s1,0x1c
    800037ea:	73a4b483          	ld	s1,1850(s1) # 8001ff20 <bcache+0x82b8>
    800037ee:	0001c797          	auipc	a5,0x1c
    800037f2:	6e278793          	addi	a5,a5,1762 # 8001fed0 <bcache+0x8268>
    800037f6:	02f48f63          	beq	s1,a5,80003834 <bread+0x70>
    800037fa:	873e                	mv	a4,a5
    800037fc:	a021                	j	80003804 <bread+0x40>
    800037fe:	68a4                	ld	s1,80(s1)
    80003800:	02e48a63          	beq	s1,a4,80003834 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003804:	449c                	lw	a5,8(s1)
    80003806:	ff379ce3          	bne	a5,s3,800037fe <bread+0x3a>
    8000380a:	44dc                	lw	a5,12(s1)
    8000380c:	ff2799e3          	bne	a5,s2,800037fe <bread+0x3a>
      b->refcnt++;
    80003810:	40bc                	lw	a5,64(s1)
    80003812:	2785                	addiw	a5,a5,1
    80003814:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003816:	00014517          	auipc	a0,0x14
    8000381a:	45250513          	addi	a0,a0,1106 # 80017c68 <bcache>
    8000381e:	ffffd097          	auipc	ra,0xffffd
    80003822:	47a080e7          	jalr	1146(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003826:	01048513          	addi	a0,s1,16
    8000382a:	00001097          	auipc	ra,0x1
    8000382e:	466080e7          	jalr	1126(ra) # 80004c90 <acquiresleep>
      return b;
    80003832:	a8b9                	j	80003890 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003834:	0001c497          	auipc	s1,0x1c
    80003838:	6e44b483          	ld	s1,1764(s1) # 8001ff18 <bcache+0x82b0>
    8000383c:	0001c797          	auipc	a5,0x1c
    80003840:	69478793          	addi	a5,a5,1684 # 8001fed0 <bcache+0x8268>
    80003844:	00f48863          	beq	s1,a5,80003854 <bread+0x90>
    80003848:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000384a:	40bc                	lw	a5,64(s1)
    8000384c:	cf81                	beqz	a5,80003864 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000384e:	64a4                	ld	s1,72(s1)
    80003850:	fee49de3          	bne	s1,a4,8000384a <bread+0x86>
  panic("bget: no buffers");
    80003854:	00005517          	auipc	a0,0x5
    80003858:	fac50513          	addi	a0,a0,-84 # 80008800 <syscalls+0xd8>
    8000385c:	ffffd097          	auipc	ra,0xffffd
    80003860:	ce2080e7          	jalr	-798(ra) # 8000053e <panic>
      b->dev = dev;
    80003864:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003868:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000386c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003870:	4785                	li	a5,1
    80003872:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003874:	00014517          	auipc	a0,0x14
    80003878:	3f450513          	addi	a0,a0,1012 # 80017c68 <bcache>
    8000387c:	ffffd097          	auipc	ra,0xffffd
    80003880:	41c080e7          	jalr	1052(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003884:	01048513          	addi	a0,s1,16
    80003888:	00001097          	auipc	ra,0x1
    8000388c:	408080e7          	jalr	1032(ra) # 80004c90 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003890:	409c                	lw	a5,0(s1)
    80003892:	cb89                	beqz	a5,800038a4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003894:	8526                	mv	a0,s1
    80003896:	70a2                	ld	ra,40(sp)
    80003898:	7402                	ld	s0,32(sp)
    8000389a:	64e2                	ld	s1,24(sp)
    8000389c:	6942                	ld	s2,16(sp)
    8000389e:	69a2                	ld	s3,8(sp)
    800038a0:	6145                	addi	sp,sp,48
    800038a2:	8082                	ret
    virtio_disk_rw(b, 0);
    800038a4:	4581                	li	a1,0
    800038a6:	8526                	mv	a0,s1
    800038a8:	00003097          	auipc	ra,0x3
    800038ac:	f0e080e7          	jalr	-242(ra) # 800067b6 <virtio_disk_rw>
    b->valid = 1;
    800038b0:	4785                	li	a5,1
    800038b2:	c09c                	sw	a5,0(s1)
  return b;
    800038b4:	b7c5                	j	80003894 <bread+0xd0>

00000000800038b6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800038b6:	1101                	addi	sp,sp,-32
    800038b8:	ec06                	sd	ra,24(sp)
    800038ba:	e822                	sd	s0,16(sp)
    800038bc:	e426                	sd	s1,8(sp)
    800038be:	1000                	addi	s0,sp,32
    800038c0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800038c2:	0541                	addi	a0,a0,16
    800038c4:	00001097          	auipc	ra,0x1
    800038c8:	466080e7          	jalr	1126(ra) # 80004d2a <holdingsleep>
    800038cc:	cd01                	beqz	a0,800038e4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800038ce:	4585                	li	a1,1
    800038d0:	8526                	mv	a0,s1
    800038d2:	00003097          	auipc	ra,0x3
    800038d6:	ee4080e7          	jalr	-284(ra) # 800067b6 <virtio_disk_rw>
}
    800038da:	60e2                	ld	ra,24(sp)
    800038dc:	6442                	ld	s0,16(sp)
    800038de:	64a2                	ld	s1,8(sp)
    800038e0:	6105                	addi	sp,sp,32
    800038e2:	8082                	ret
    panic("bwrite");
    800038e4:	00005517          	auipc	a0,0x5
    800038e8:	f3450513          	addi	a0,a0,-204 # 80008818 <syscalls+0xf0>
    800038ec:	ffffd097          	auipc	ra,0xffffd
    800038f0:	c52080e7          	jalr	-942(ra) # 8000053e <panic>

00000000800038f4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800038f4:	1101                	addi	sp,sp,-32
    800038f6:	ec06                	sd	ra,24(sp)
    800038f8:	e822                	sd	s0,16(sp)
    800038fa:	e426                	sd	s1,8(sp)
    800038fc:	e04a                	sd	s2,0(sp)
    800038fe:	1000                	addi	s0,sp,32
    80003900:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003902:	01050913          	addi	s2,a0,16
    80003906:	854a                	mv	a0,s2
    80003908:	00001097          	auipc	ra,0x1
    8000390c:	422080e7          	jalr	1058(ra) # 80004d2a <holdingsleep>
    80003910:	c92d                	beqz	a0,80003982 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003912:	854a                	mv	a0,s2
    80003914:	00001097          	auipc	ra,0x1
    80003918:	3d2080e7          	jalr	978(ra) # 80004ce6 <releasesleep>

  acquire(&bcache.lock);
    8000391c:	00014517          	auipc	a0,0x14
    80003920:	34c50513          	addi	a0,a0,844 # 80017c68 <bcache>
    80003924:	ffffd097          	auipc	ra,0xffffd
    80003928:	2c0080e7          	jalr	704(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000392c:	40bc                	lw	a5,64(s1)
    8000392e:	37fd                	addiw	a5,a5,-1
    80003930:	0007871b          	sext.w	a4,a5
    80003934:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003936:	eb05                	bnez	a4,80003966 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003938:	68bc                	ld	a5,80(s1)
    8000393a:	64b8                	ld	a4,72(s1)
    8000393c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000393e:	64bc                	ld	a5,72(s1)
    80003940:	68b8                	ld	a4,80(s1)
    80003942:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003944:	0001c797          	auipc	a5,0x1c
    80003948:	32478793          	addi	a5,a5,804 # 8001fc68 <bcache+0x8000>
    8000394c:	2b87b703          	ld	a4,696(a5)
    80003950:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003952:	0001c717          	auipc	a4,0x1c
    80003956:	57e70713          	addi	a4,a4,1406 # 8001fed0 <bcache+0x8268>
    8000395a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000395c:	2b87b703          	ld	a4,696(a5)
    80003960:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003962:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003966:	00014517          	auipc	a0,0x14
    8000396a:	30250513          	addi	a0,a0,770 # 80017c68 <bcache>
    8000396e:	ffffd097          	auipc	ra,0xffffd
    80003972:	32a080e7          	jalr	810(ra) # 80000c98 <release>
}
    80003976:	60e2                	ld	ra,24(sp)
    80003978:	6442                	ld	s0,16(sp)
    8000397a:	64a2                	ld	s1,8(sp)
    8000397c:	6902                	ld	s2,0(sp)
    8000397e:	6105                	addi	sp,sp,32
    80003980:	8082                	ret
    panic("brelse");
    80003982:	00005517          	auipc	a0,0x5
    80003986:	e9e50513          	addi	a0,a0,-354 # 80008820 <syscalls+0xf8>
    8000398a:	ffffd097          	auipc	ra,0xffffd
    8000398e:	bb4080e7          	jalr	-1100(ra) # 8000053e <panic>

0000000080003992 <bpin>:

void
bpin(struct buf *b) {
    80003992:	1101                	addi	sp,sp,-32
    80003994:	ec06                	sd	ra,24(sp)
    80003996:	e822                	sd	s0,16(sp)
    80003998:	e426                	sd	s1,8(sp)
    8000399a:	1000                	addi	s0,sp,32
    8000399c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000399e:	00014517          	auipc	a0,0x14
    800039a2:	2ca50513          	addi	a0,a0,714 # 80017c68 <bcache>
    800039a6:	ffffd097          	auipc	ra,0xffffd
    800039aa:	23e080e7          	jalr	574(ra) # 80000be4 <acquire>
  b->refcnt++;
    800039ae:	40bc                	lw	a5,64(s1)
    800039b0:	2785                	addiw	a5,a5,1
    800039b2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800039b4:	00014517          	auipc	a0,0x14
    800039b8:	2b450513          	addi	a0,a0,692 # 80017c68 <bcache>
    800039bc:	ffffd097          	auipc	ra,0xffffd
    800039c0:	2dc080e7          	jalr	732(ra) # 80000c98 <release>
}
    800039c4:	60e2                	ld	ra,24(sp)
    800039c6:	6442                	ld	s0,16(sp)
    800039c8:	64a2                	ld	s1,8(sp)
    800039ca:	6105                	addi	sp,sp,32
    800039cc:	8082                	ret

00000000800039ce <bunpin>:

void
bunpin(struct buf *b) {
    800039ce:	1101                	addi	sp,sp,-32
    800039d0:	ec06                	sd	ra,24(sp)
    800039d2:	e822                	sd	s0,16(sp)
    800039d4:	e426                	sd	s1,8(sp)
    800039d6:	1000                	addi	s0,sp,32
    800039d8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800039da:	00014517          	auipc	a0,0x14
    800039de:	28e50513          	addi	a0,a0,654 # 80017c68 <bcache>
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	202080e7          	jalr	514(ra) # 80000be4 <acquire>
  b->refcnt--;
    800039ea:	40bc                	lw	a5,64(s1)
    800039ec:	37fd                	addiw	a5,a5,-1
    800039ee:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800039f0:	00014517          	auipc	a0,0x14
    800039f4:	27850513          	addi	a0,a0,632 # 80017c68 <bcache>
    800039f8:	ffffd097          	auipc	ra,0xffffd
    800039fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>
}
    80003a00:	60e2                	ld	ra,24(sp)
    80003a02:	6442                	ld	s0,16(sp)
    80003a04:	64a2                	ld	s1,8(sp)
    80003a06:	6105                	addi	sp,sp,32
    80003a08:	8082                	ret

0000000080003a0a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003a0a:	1101                	addi	sp,sp,-32
    80003a0c:	ec06                	sd	ra,24(sp)
    80003a0e:	e822                	sd	s0,16(sp)
    80003a10:	e426                	sd	s1,8(sp)
    80003a12:	e04a                	sd	s2,0(sp)
    80003a14:	1000                	addi	s0,sp,32
    80003a16:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003a18:	00d5d59b          	srliw	a1,a1,0xd
    80003a1c:	0001d797          	auipc	a5,0x1d
    80003a20:	9287a783          	lw	a5,-1752(a5) # 80020344 <sb+0x1c>
    80003a24:	9dbd                	addw	a1,a1,a5
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	d9e080e7          	jalr	-610(ra) # 800037c4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003a2e:	0074f713          	andi	a4,s1,7
    80003a32:	4785                	li	a5,1
    80003a34:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003a38:	14ce                	slli	s1,s1,0x33
    80003a3a:	90d9                	srli	s1,s1,0x36
    80003a3c:	00950733          	add	a4,a0,s1
    80003a40:	05874703          	lbu	a4,88(a4)
    80003a44:	00e7f6b3          	and	a3,a5,a4
    80003a48:	c69d                	beqz	a3,80003a76 <bfree+0x6c>
    80003a4a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003a4c:	94aa                	add	s1,s1,a0
    80003a4e:	fff7c793          	not	a5,a5
    80003a52:	8ff9                	and	a5,a5,a4
    80003a54:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003a58:	00001097          	auipc	ra,0x1
    80003a5c:	118080e7          	jalr	280(ra) # 80004b70 <log_write>
  brelse(bp);
    80003a60:	854a                	mv	a0,s2
    80003a62:	00000097          	auipc	ra,0x0
    80003a66:	e92080e7          	jalr	-366(ra) # 800038f4 <brelse>
}
    80003a6a:	60e2                	ld	ra,24(sp)
    80003a6c:	6442                	ld	s0,16(sp)
    80003a6e:	64a2                	ld	s1,8(sp)
    80003a70:	6902                	ld	s2,0(sp)
    80003a72:	6105                	addi	sp,sp,32
    80003a74:	8082                	ret
    panic("freeing free block");
    80003a76:	00005517          	auipc	a0,0x5
    80003a7a:	db250513          	addi	a0,a0,-590 # 80008828 <syscalls+0x100>
    80003a7e:	ffffd097          	auipc	ra,0xffffd
    80003a82:	ac0080e7          	jalr	-1344(ra) # 8000053e <panic>

0000000080003a86 <balloc>:
{
    80003a86:	711d                	addi	sp,sp,-96
    80003a88:	ec86                	sd	ra,88(sp)
    80003a8a:	e8a2                	sd	s0,80(sp)
    80003a8c:	e4a6                	sd	s1,72(sp)
    80003a8e:	e0ca                	sd	s2,64(sp)
    80003a90:	fc4e                	sd	s3,56(sp)
    80003a92:	f852                	sd	s4,48(sp)
    80003a94:	f456                	sd	s5,40(sp)
    80003a96:	f05a                	sd	s6,32(sp)
    80003a98:	ec5e                	sd	s7,24(sp)
    80003a9a:	e862                	sd	s8,16(sp)
    80003a9c:	e466                	sd	s9,8(sp)
    80003a9e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003aa0:	0001d797          	auipc	a5,0x1d
    80003aa4:	88c7a783          	lw	a5,-1908(a5) # 8002032c <sb+0x4>
    80003aa8:	cbd1                	beqz	a5,80003b3c <balloc+0xb6>
    80003aaa:	8baa                	mv	s7,a0
    80003aac:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003aae:	0001db17          	auipc	s6,0x1d
    80003ab2:	87ab0b13          	addi	s6,s6,-1926 # 80020328 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ab6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003ab8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003aba:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003abc:	6c89                	lui	s9,0x2
    80003abe:	a831                	j	80003ada <balloc+0x54>
    brelse(bp);
    80003ac0:	854a                	mv	a0,s2
    80003ac2:	00000097          	auipc	ra,0x0
    80003ac6:	e32080e7          	jalr	-462(ra) # 800038f4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003aca:	015c87bb          	addw	a5,s9,s5
    80003ace:	00078a9b          	sext.w	s5,a5
    80003ad2:	004b2703          	lw	a4,4(s6)
    80003ad6:	06eaf363          	bgeu	s5,a4,80003b3c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003ada:	41fad79b          	sraiw	a5,s5,0x1f
    80003ade:	0137d79b          	srliw	a5,a5,0x13
    80003ae2:	015787bb          	addw	a5,a5,s5
    80003ae6:	40d7d79b          	sraiw	a5,a5,0xd
    80003aea:	01cb2583          	lw	a1,28(s6)
    80003aee:	9dbd                	addw	a1,a1,a5
    80003af0:	855e                	mv	a0,s7
    80003af2:	00000097          	auipc	ra,0x0
    80003af6:	cd2080e7          	jalr	-814(ra) # 800037c4 <bread>
    80003afa:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003afc:	004b2503          	lw	a0,4(s6)
    80003b00:	000a849b          	sext.w	s1,s5
    80003b04:	8662                	mv	a2,s8
    80003b06:	faa4fde3          	bgeu	s1,a0,80003ac0 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003b0a:	41f6579b          	sraiw	a5,a2,0x1f
    80003b0e:	01d7d69b          	srliw	a3,a5,0x1d
    80003b12:	00c6873b          	addw	a4,a3,a2
    80003b16:	00777793          	andi	a5,a4,7
    80003b1a:	9f95                	subw	a5,a5,a3
    80003b1c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003b20:	4037571b          	sraiw	a4,a4,0x3
    80003b24:	00e906b3          	add	a3,s2,a4
    80003b28:	0586c683          	lbu	a3,88(a3)
    80003b2c:	00d7f5b3          	and	a1,a5,a3
    80003b30:	cd91                	beqz	a1,80003b4c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b32:	2605                	addiw	a2,a2,1
    80003b34:	2485                	addiw	s1,s1,1
    80003b36:	fd4618e3          	bne	a2,s4,80003b06 <balloc+0x80>
    80003b3a:	b759                	j	80003ac0 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003b3c:	00005517          	auipc	a0,0x5
    80003b40:	d0450513          	addi	a0,a0,-764 # 80008840 <syscalls+0x118>
    80003b44:	ffffd097          	auipc	ra,0xffffd
    80003b48:	9fa080e7          	jalr	-1542(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003b4c:	974a                	add	a4,a4,s2
    80003b4e:	8fd5                	or	a5,a5,a3
    80003b50:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003b54:	854a                	mv	a0,s2
    80003b56:	00001097          	auipc	ra,0x1
    80003b5a:	01a080e7          	jalr	26(ra) # 80004b70 <log_write>
        brelse(bp);
    80003b5e:	854a                	mv	a0,s2
    80003b60:	00000097          	auipc	ra,0x0
    80003b64:	d94080e7          	jalr	-620(ra) # 800038f4 <brelse>
  bp = bread(dev, bno);
    80003b68:	85a6                	mv	a1,s1
    80003b6a:	855e                	mv	a0,s7
    80003b6c:	00000097          	auipc	ra,0x0
    80003b70:	c58080e7          	jalr	-936(ra) # 800037c4 <bread>
    80003b74:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003b76:	40000613          	li	a2,1024
    80003b7a:	4581                	li	a1,0
    80003b7c:	05850513          	addi	a0,a0,88
    80003b80:	ffffd097          	auipc	ra,0xffffd
    80003b84:	160080e7          	jalr	352(ra) # 80000ce0 <memset>
  log_write(bp);
    80003b88:	854a                	mv	a0,s2
    80003b8a:	00001097          	auipc	ra,0x1
    80003b8e:	fe6080e7          	jalr	-26(ra) # 80004b70 <log_write>
  brelse(bp);
    80003b92:	854a                	mv	a0,s2
    80003b94:	00000097          	auipc	ra,0x0
    80003b98:	d60080e7          	jalr	-672(ra) # 800038f4 <brelse>
}
    80003b9c:	8526                	mv	a0,s1
    80003b9e:	60e6                	ld	ra,88(sp)
    80003ba0:	6446                	ld	s0,80(sp)
    80003ba2:	64a6                	ld	s1,72(sp)
    80003ba4:	6906                	ld	s2,64(sp)
    80003ba6:	79e2                	ld	s3,56(sp)
    80003ba8:	7a42                	ld	s4,48(sp)
    80003baa:	7aa2                	ld	s5,40(sp)
    80003bac:	7b02                	ld	s6,32(sp)
    80003bae:	6be2                	ld	s7,24(sp)
    80003bb0:	6c42                	ld	s8,16(sp)
    80003bb2:	6ca2                	ld	s9,8(sp)
    80003bb4:	6125                	addi	sp,sp,96
    80003bb6:	8082                	ret

0000000080003bb8 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003bb8:	7179                	addi	sp,sp,-48
    80003bba:	f406                	sd	ra,40(sp)
    80003bbc:	f022                	sd	s0,32(sp)
    80003bbe:	ec26                	sd	s1,24(sp)
    80003bc0:	e84a                	sd	s2,16(sp)
    80003bc2:	e44e                	sd	s3,8(sp)
    80003bc4:	e052                	sd	s4,0(sp)
    80003bc6:	1800                	addi	s0,sp,48
    80003bc8:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003bca:	47ad                	li	a5,11
    80003bcc:	04b7fe63          	bgeu	a5,a1,80003c28 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003bd0:	ff45849b          	addiw	s1,a1,-12
    80003bd4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003bd8:	0ff00793          	li	a5,255
    80003bdc:	0ae7e363          	bltu	a5,a4,80003c82 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003be0:	08052583          	lw	a1,128(a0)
    80003be4:	c5ad                	beqz	a1,80003c4e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003be6:	00092503          	lw	a0,0(s2)
    80003bea:	00000097          	auipc	ra,0x0
    80003bee:	bda080e7          	jalr	-1062(ra) # 800037c4 <bread>
    80003bf2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003bf4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003bf8:	02049593          	slli	a1,s1,0x20
    80003bfc:	9181                	srli	a1,a1,0x20
    80003bfe:	058a                	slli	a1,a1,0x2
    80003c00:	00b784b3          	add	s1,a5,a1
    80003c04:	0004a983          	lw	s3,0(s1)
    80003c08:	04098d63          	beqz	s3,80003c62 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003c0c:	8552                	mv	a0,s4
    80003c0e:	00000097          	auipc	ra,0x0
    80003c12:	ce6080e7          	jalr	-794(ra) # 800038f4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003c16:	854e                	mv	a0,s3
    80003c18:	70a2                	ld	ra,40(sp)
    80003c1a:	7402                	ld	s0,32(sp)
    80003c1c:	64e2                	ld	s1,24(sp)
    80003c1e:	6942                	ld	s2,16(sp)
    80003c20:	69a2                	ld	s3,8(sp)
    80003c22:	6a02                	ld	s4,0(sp)
    80003c24:	6145                	addi	sp,sp,48
    80003c26:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003c28:	02059493          	slli	s1,a1,0x20
    80003c2c:	9081                	srli	s1,s1,0x20
    80003c2e:	048a                	slli	s1,s1,0x2
    80003c30:	94aa                	add	s1,s1,a0
    80003c32:	0504a983          	lw	s3,80(s1)
    80003c36:	fe0990e3          	bnez	s3,80003c16 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003c3a:	4108                	lw	a0,0(a0)
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	e4a080e7          	jalr	-438(ra) # 80003a86 <balloc>
    80003c44:	0005099b          	sext.w	s3,a0
    80003c48:	0534a823          	sw	s3,80(s1)
    80003c4c:	b7e9                	j	80003c16 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003c4e:	4108                	lw	a0,0(a0)
    80003c50:	00000097          	auipc	ra,0x0
    80003c54:	e36080e7          	jalr	-458(ra) # 80003a86 <balloc>
    80003c58:	0005059b          	sext.w	a1,a0
    80003c5c:	08b92023          	sw	a1,128(s2)
    80003c60:	b759                	j	80003be6 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003c62:	00092503          	lw	a0,0(s2)
    80003c66:	00000097          	auipc	ra,0x0
    80003c6a:	e20080e7          	jalr	-480(ra) # 80003a86 <balloc>
    80003c6e:	0005099b          	sext.w	s3,a0
    80003c72:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003c76:	8552                	mv	a0,s4
    80003c78:	00001097          	auipc	ra,0x1
    80003c7c:	ef8080e7          	jalr	-264(ra) # 80004b70 <log_write>
    80003c80:	b771                	j	80003c0c <bmap+0x54>
  panic("bmap: out of range");
    80003c82:	00005517          	auipc	a0,0x5
    80003c86:	bd650513          	addi	a0,a0,-1066 # 80008858 <syscalls+0x130>
    80003c8a:	ffffd097          	auipc	ra,0xffffd
    80003c8e:	8b4080e7          	jalr	-1868(ra) # 8000053e <panic>

0000000080003c92 <iget>:
{
    80003c92:	7179                	addi	sp,sp,-48
    80003c94:	f406                	sd	ra,40(sp)
    80003c96:	f022                	sd	s0,32(sp)
    80003c98:	ec26                	sd	s1,24(sp)
    80003c9a:	e84a                	sd	s2,16(sp)
    80003c9c:	e44e                	sd	s3,8(sp)
    80003c9e:	e052                	sd	s4,0(sp)
    80003ca0:	1800                	addi	s0,sp,48
    80003ca2:	89aa                	mv	s3,a0
    80003ca4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003ca6:	0001c517          	auipc	a0,0x1c
    80003caa:	6a250513          	addi	a0,a0,1698 # 80020348 <itable>
    80003cae:	ffffd097          	auipc	ra,0xffffd
    80003cb2:	f36080e7          	jalr	-202(ra) # 80000be4 <acquire>
  empty = 0;
    80003cb6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003cb8:	0001c497          	auipc	s1,0x1c
    80003cbc:	6a848493          	addi	s1,s1,1704 # 80020360 <itable+0x18>
    80003cc0:	0001e697          	auipc	a3,0x1e
    80003cc4:	13068693          	addi	a3,a3,304 # 80021df0 <log>
    80003cc8:	a039                	j	80003cd6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003cca:	02090b63          	beqz	s2,80003d00 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003cce:	08848493          	addi	s1,s1,136
    80003cd2:	02d48a63          	beq	s1,a3,80003d06 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003cd6:	449c                	lw	a5,8(s1)
    80003cd8:	fef059e3          	blez	a5,80003cca <iget+0x38>
    80003cdc:	4098                	lw	a4,0(s1)
    80003cde:	ff3716e3          	bne	a4,s3,80003cca <iget+0x38>
    80003ce2:	40d8                	lw	a4,4(s1)
    80003ce4:	ff4713e3          	bne	a4,s4,80003cca <iget+0x38>
      ip->ref++;
    80003ce8:	2785                	addiw	a5,a5,1
    80003cea:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003cec:	0001c517          	auipc	a0,0x1c
    80003cf0:	65c50513          	addi	a0,a0,1628 # 80020348 <itable>
    80003cf4:	ffffd097          	auipc	ra,0xffffd
    80003cf8:	fa4080e7          	jalr	-92(ra) # 80000c98 <release>
      return ip;
    80003cfc:	8926                	mv	s2,s1
    80003cfe:	a03d                	j	80003d2c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003d00:	f7f9                	bnez	a5,80003cce <iget+0x3c>
    80003d02:	8926                	mv	s2,s1
    80003d04:	b7e9                	j	80003cce <iget+0x3c>
  if(empty == 0)
    80003d06:	02090c63          	beqz	s2,80003d3e <iget+0xac>
  ip->dev = dev;
    80003d0a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003d0e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003d12:	4785                	li	a5,1
    80003d14:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003d18:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003d1c:	0001c517          	auipc	a0,0x1c
    80003d20:	62c50513          	addi	a0,a0,1580 # 80020348 <itable>
    80003d24:	ffffd097          	auipc	ra,0xffffd
    80003d28:	f74080e7          	jalr	-140(ra) # 80000c98 <release>
}
    80003d2c:	854a                	mv	a0,s2
    80003d2e:	70a2                	ld	ra,40(sp)
    80003d30:	7402                	ld	s0,32(sp)
    80003d32:	64e2                	ld	s1,24(sp)
    80003d34:	6942                	ld	s2,16(sp)
    80003d36:	69a2                	ld	s3,8(sp)
    80003d38:	6a02                	ld	s4,0(sp)
    80003d3a:	6145                	addi	sp,sp,48
    80003d3c:	8082                	ret
    panic("iget: no inodes");
    80003d3e:	00005517          	auipc	a0,0x5
    80003d42:	b3250513          	addi	a0,a0,-1230 # 80008870 <syscalls+0x148>
    80003d46:	ffffc097          	auipc	ra,0xffffc
    80003d4a:	7f8080e7          	jalr	2040(ra) # 8000053e <panic>

0000000080003d4e <fsinit>:
fsinit(int dev) {
    80003d4e:	7179                	addi	sp,sp,-48
    80003d50:	f406                	sd	ra,40(sp)
    80003d52:	f022                	sd	s0,32(sp)
    80003d54:	ec26                	sd	s1,24(sp)
    80003d56:	e84a                	sd	s2,16(sp)
    80003d58:	e44e                	sd	s3,8(sp)
    80003d5a:	1800                	addi	s0,sp,48
    80003d5c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003d5e:	4585                	li	a1,1
    80003d60:	00000097          	auipc	ra,0x0
    80003d64:	a64080e7          	jalr	-1436(ra) # 800037c4 <bread>
    80003d68:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003d6a:	0001c997          	auipc	s3,0x1c
    80003d6e:	5be98993          	addi	s3,s3,1470 # 80020328 <sb>
    80003d72:	02000613          	li	a2,32
    80003d76:	05850593          	addi	a1,a0,88
    80003d7a:	854e                	mv	a0,s3
    80003d7c:	ffffd097          	auipc	ra,0xffffd
    80003d80:	fc4080e7          	jalr	-60(ra) # 80000d40 <memmove>
  brelse(bp);
    80003d84:	8526                	mv	a0,s1
    80003d86:	00000097          	auipc	ra,0x0
    80003d8a:	b6e080e7          	jalr	-1170(ra) # 800038f4 <brelse>
  if(sb.magic != FSMAGIC)
    80003d8e:	0009a703          	lw	a4,0(s3)
    80003d92:	102037b7          	lui	a5,0x10203
    80003d96:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003d9a:	02f71263          	bne	a4,a5,80003dbe <fsinit+0x70>
  initlog(dev, &sb);
    80003d9e:	0001c597          	auipc	a1,0x1c
    80003da2:	58a58593          	addi	a1,a1,1418 # 80020328 <sb>
    80003da6:	854a                	mv	a0,s2
    80003da8:	00001097          	auipc	ra,0x1
    80003dac:	b4c080e7          	jalr	-1204(ra) # 800048f4 <initlog>
}
    80003db0:	70a2                	ld	ra,40(sp)
    80003db2:	7402                	ld	s0,32(sp)
    80003db4:	64e2                	ld	s1,24(sp)
    80003db6:	6942                	ld	s2,16(sp)
    80003db8:	69a2                	ld	s3,8(sp)
    80003dba:	6145                	addi	sp,sp,48
    80003dbc:	8082                	ret
    panic("invalid file system");
    80003dbe:	00005517          	auipc	a0,0x5
    80003dc2:	ac250513          	addi	a0,a0,-1342 # 80008880 <syscalls+0x158>
    80003dc6:	ffffc097          	auipc	ra,0xffffc
    80003dca:	778080e7          	jalr	1912(ra) # 8000053e <panic>

0000000080003dce <iinit>:
{
    80003dce:	7179                	addi	sp,sp,-48
    80003dd0:	f406                	sd	ra,40(sp)
    80003dd2:	f022                	sd	s0,32(sp)
    80003dd4:	ec26                	sd	s1,24(sp)
    80003dd6:	e84a                	sd	s2,16(sp)
    80003dd8:	e44e                	sd	s3,8(sp)
    80003dda:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003ddc:	00005597          	auipc	a1,0x5
    80003de0:	abc58593          	addi	a1,a1,-1348 # 80008898 <syscalls+0x170>
    80003de4:	0001c517          	auipc	a0,0x1c
    80003de8:	56450513          	addi	a0,a0,1380 # 80020348 <itable>
    80003dec:	ffffd097          	auipc	ra,0xffffd
    80003df0:	d68080e7          	jalr	-664(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003df4:	0001c497          	auipc	s1,0x1c
    80003df8:	57c48493          	addi	s1,s1,1404 # 80020370 <itable+0x28>
    80003dfc:	0001e997          	auipc	s3,0x1e
    80003e00:	00498993          	addi	s3,s3,4 # 80021e00 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003e04:	00005917          	auipc	s2,0x5
    80003e08:	a9c90913          	addi	s2,s2,-1380 # 800088a0 <syscalls+0x178>
    80003e0c:	85ca                	mv	a1,s2
    80003e0e:	8526                	mv	a0,s1
    80003e10:	00001097          	auipc	ra,0x1
    80003e14:	e46080e7          	jalr	-442(ra) # 80004c56 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003e18:	08848493          	addi	s1,s1,136
    80003e1c:	ff3498e3          	bne	s1,s3,80003e0c <iinit+0x3e>
}
    80003e20:	70a2                	ld	ra,40(sp)
    80003e22:	7402                	ld	s0,32(sp)
    80003e24:	64e2                	ld	s1,24(sp)
    80003e26:	6942                	ld	s2,16(sp)
    80003e28:	69a2                	ld	s3,8(sp)
    80003e2a:	6145                	addi	sp,sp,48
    80003e2c:	8082                	ret

0000000080003e2e <ialloc>:
{
    80003e2e:	715d                	addi	sp,sp,-80
    80003e30:	e486                	sd	ra,72(sp)
    80003e32:	e0a2                	sd	s0,64(sp)
    80003e34:	fc26                	sd	s1,56(sp)
    80003e36:	f84a                	sd	s2,48(sp)
    80003e38:	f44e                	sd	s3,40(sp)
    80003e3a:	f052                	sd	s4,32(sp)
    80003e3c:	ec56                	sd	s5,24(sp)
    80003e3e:	e85a                	sd	s6,16(sp)
    80003e40:	e45e                	sd	s7,8(sp)
    80003e42:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e44:	0001c717          	auipc	a4,0x1c
    80003e48:	4f072703          	lw	a4,1264(a4) # 80020334 <sb+0xc>
    80003e4c:	4785                	li	a5,1
    80003e4e:	04e7fa63          	bgeu	a5,a4,80003ea2 <ialloc+0x74>
    80003e52:	8aaa                	mv	s5,a0
    80003e54:	8bae                	mv	s7,a1
    80003e56:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003e58:	0001ca17          	auipc	s4,0x1c
    80003e5c:	4d0a0a13          	addi	s4,s4,1232 # 80020328 <sb>
    80003e60:	00048b1b          	sext.w	s6,s1
    80003e64:	0044d593          	srli	a1,s1,0x4
    80003e68:	018a2783          	lw	a5,24(s4)
    80003e6c:	9dbd                	addw	a1,a1,a5
    80003e6e:	8556                	mv	a0,s5
    80003e70:	00000097          	auipc	ra,0x0
    80003e74:	954080e7          	jalr	-1708(ra) # 800037c4 <bread>
    80003e78:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003e7a:	05850993          	addi	s3,a0,88
    80003e7e:	00f4f793          	andi	a5,s1,15
    80003e82:	079a                	slli	a5,a5,0x6
    80003e84:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003e86:	00099783          	lh	a5,0(s3)
    80003e8a:	c785                	beqz	a5,80003eb2 <ialloc+0x84>
    brelse(bp);
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	a68080e7          	jalr	-1432(ra) # 800038f4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e94:	0485                	addi	s1,s1,1
    80003e96:	00ca2703          	lw	a4,12(s4)
    80003e9a:	0004879b          	sext.w	a5,s1
    80003e9e:	fce7e1e3          	bltu	a5,a4,80003e60 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003ea2:	00005517          	auipc	a0,0x5
    80003ea6:	a0650513          	addi	a0,a0,-1530 # 800088a8 <syscalls+0x180>
    80003eaa:	ffffc097          	auipc	ra,0xffffc
    80003eae:	694080e7          	jalr	1684(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003eb2:	04000613          	li	a2,64
    80003eb6:	4581                	li	a1,0
    80003eb8:	854e                	mv	a0,s3
    80003eba:	ffffd097          	auipc	ra,0xffffd
    80003ebe:	e26080e7          	jalr	-474(ra) # 80000ce0 <memset>
      dip->type = type;
    80003ec2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ec6:	854a                	mv	a0,s2
    80003ec8:	00001097          	auipc	ra,0x1
    80003ecc:	ca8080e7          	jalr	-856(ra) # 80004b70 <log_write>
      brelse(bp);
    80003ed0:	854a                	mv	a0,s2
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	a22080e7          	jalr	-1502(ra) # 800038f4 <brelse>
      return iget(dev, inum);
    80003eda:	85da                	mv	a1,s6
    80003edc:	8556                	mv	a0,s5
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	db4080e7          	jalr	-588(ra) # 80003c92 <iget>
}
    80003ee6:	60a6                	ld	ra,72(sp)
    80003ee8:	6406                	ld	s0,64(sp)
    80003eea:	74e2                	ld	s1,56(sp)
    80003eec:	7942                	ld	s2,48(sp)
    80003eee:	79a2                	ld	s3,40(sp)
    80003ef0:	7a02                	ld	s4,32(sp)
    80003ef2:	6ae2                	ld	s5,24(sp)
    80003ef4:	6b42                	ld	s6,16(sp)
    80003ef6:	6ba2                	ld	s7,8(sp)
    80003ef8:	6161                	addi	sp,sp,80
    80003efa:	8082                	ret

0000000080003efc <iupdate>:
{
    80003efc:	1101                	addi	sp,sp,-32
    80003efe:	ec06                	sd	ra,24(sp)
    80003f00:	e822                	sd	s0,16(sp)
    80003f02:	e426                	sd	s1,8(sp)
    80003f04:	e04a                	sd	s2,0(sp)
    80003f06:	1000                	addi	s0,sp,32
    80003f08:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f0a:	415c                	lw	a5,4(a0)
    80003f0c:	0047d79b          	srliw	a5,a5,0x4
    80003f10:	0001c597          	auipc	a1,0x1c
    80003f14:	4305a583          	lw	a1,1072(a1) # 80020340 <sb+0x18>
    80003f18:	9dbd                	addw	a1,a1,a5
    80003f1a:	4108                	lw	a0,0(a0)
    80003f1c:	00000097          	auipc	ra,0x0
    80003f20:	8a8080e7          	jalr	-1880(ra) # 800037c4 <bread>
    80003f24:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f26:	05850793          	addi	a5,a0,88
    80003f2a:	40c8                	lw	a0,4(s1)
    80003f2c:	893d                	andi	a0,a0,15
    80003f2e:	051a                	slli	a0,a0,0x6
    80003f30:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003f32:	04449703          	lh	a4,68(s1)
    80003f36:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003f3a:	04649703          	lh	a4,70(s1)
    80003f3e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003f42:	04849703          	lh	a4,72(s1)
    80003f46:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003f4a:	04a49703          	lh	a4,74(s1)
    80003f4e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003f52:	44f8                	lw	a4,76(s1)
    80003f54:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003f56:	03400613          	li	a2,52
    80003f5a:	05048593          	addi	a1,s1,80
    80003f5e:	0531                	addi	a0,a0,12
    80003f60:	ffffd097          	auipc	ra,0xffffd
    80003f64:	de0080e7          	jalr	-544(ra) # 80000d40 <memmove>
  log_write(bp);
    80003f68:	854a                	mv	a0,s2
    80003f6a:	00001097          	auipc	ra,0x1
    80003f6e:	c06080e7          	jalr	-1018(ra) # 80004b70 <log_write>
  brelse(bp);
    80003f72:	854a                	mv	a0,s2
    80003f74:	00000097          	auipc	ra,0x0
    80003f78:	980080e7          	jalr	-1664(ra) # 800038f4 <brelse>
}
    80003f7c:	60e2                	ld	ra,24(sp)
    80003f7e:	6442                	ld	s0,16(sp)
    80003f80:	64a2                	ld	s1,8(sp)
    80003f82:	6902                	ld	s2,0(sp)
    80003f84:	6105                	addi	sp,sp,32
    80003f86:	8082                	ret

0000000080003f88 <idup>:
{
    80003f88:	1101                	addi	sp,sp,-32
    80003f8a:	ec06                	sd	ra,24(sp)
    80003f8c:	e822                	sd	s0,16(sp)
    80003f8e:	e426                	sd	s1,8(sp)
    80003f90:	1000                	addi	s0,sp,32
    80003f92:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f94:	0001c517          	auipc	a0,0x1c
    80003f98:	3b450513          	addi	a0,a0,948 # 80020348 <itable>
    80003f9c:	ffffd097          	auipc	ra,0xffffd
    80003fa0:	c48080e7          	jalr	-952(ra) # 80000be4 <acquire>
  ip->ref++;
    80003fa4:	449c                	lw	a5,8(s1)
    80003fa6:	2785                	addiw	a5,a5,1
    80003fa8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003faa:	0001c517          	auipc	a0,0x1c
    80003fae:	39e50513          	addi	a0,a0,926 # 80020348 <itable>
    80003fb2:	ffffd097          	auipc	ra,0xffffd
    80003fb6:	ce6080e7          	jalr	-794(ra) # 80000c98 <release>
}
    80003fba:	8526                	mv	a0,s1
    80003fbc:	60e2                	ld	ra,24(sp)
    80003fbe:	6442                	ld	s0,16(sp)
    80003fc0:	64a2                	ld	s1,8(sp)
    80003fc2:	6105                	addi	sp,sp,32
    80003fc4:	8082                	ret

0000000080003fc6 <ilock>:
{
    80003fc6:	1101                	addi	sp,sp,-32
    80003fc8:	ec06                	sd	ra,24(sp)
    80003fca:	e822                	sd	s0,16(sp)
    80003fcc:	e426                	sd	s1,8(sp)
    80003fce:	e04a                	sd	s2,0(sp)
    80003fd0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003fd2:	c115                	beqz	a0,80003ff6 <ilock+0x30>
    80003fd4:	84aa                	mv	s1,a0
    80003fd6:	451c                	lw	a5,8(a0)
    80003fd8:	00f05f63          	blez	a5,80003ff6 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003fdc:	0541                	addi	a0,a0,16
    80003fde:	00001097          	auipc	ra,0x1
    80003fe2:	cb2080e7          	jalr	-846(ra) # 80004c90 <acquiresleep>
  if(ip->valid == 0){
    80003fe6:	40bc                	lw	a5,64(s1)
    80003fe8:	cf99                	beqz	a5,80004006 <ilock+0x40>
}
    80003fea:	60e2                	ld	ra,24(sp)
    80003fec:	6442                	ld	s0,16(sp)
    80003fee:	64a2                	ld	s1,8(sp)
    80003ff0:	6902                	ld	s2,0(sp)
    80003ff2:	6105                	addi	sp,sp,32
    80003ff4:	8082                	ret
    panic("ilock");
    80003ff6:	00005517          	auipc	a0,0x5
    80003ffa:	8ca50513          	addi	a0,a0,-1846 # 800088c0 <syscalls+0x198>
    80003ffe:	ffffc097          	auipc	ra,0xffffc
    80004002:	540080e7          	jalr	1344(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004006:	40dc                	lw	a5,4(s1)
    80004008:	0047d79b          	srliw	a5,a5,0x4
    8000400c:	0001c597          	auipc	a1,0x1c
    80004010:	3345a583          	lw	a1,820(a1) # 80020340 <sb+0x18>
    80004014:	9dbd                	addw	a1,a1,a5
    80004016:	4088                	lw	a0,0(s1)
    80004018:	fffff097          	auipc	ra,0xfffff
    8000401c:	7ac080e7          	jalr	1964(ra) # 800037c4 <bread>
    80004020:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004022:	05850593          	addi	a1,a0,88
    80004026:	40dc                	lw	a5,4(s1)
    80004028:	8bbd                	andi	a5,a5,15
    8000402a:	079a                	slli	a5,a5,0x6
    8000402c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000402e:	00059783          	lh	a5,0(a1)
    80004032:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004036:	00259783          	lh	a5,2(a1)
    8000403a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000403e:	00459783          	lh	a5,4(a1)
    80004042:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004046:	00659783          	lh	a5,6(a1)
    8000404a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000404e:	459c                	lw	a5,8(a1)
    80004050:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004052:	03400613          	li	a2,52
    80004056:	05b1                	addi	a1,a1,12
    80004058:	05048513          	addi	a0,s1,80
    8000405c:	ffffd097          	auipc	ra,0xffffd
    80004060:	ce4080e7          	jalr	-796(ra) # 80000d40 <memmove>
    brelse(bp);
    80004064:	854a                	mv	a0,s2
    80004066:	00000097          	auipc	ra,0x0
    8000406a:	88e080e7          	jalr	-1906(ra) # 800038f4 <brelse>
    ip->valid = 1;
    8000406e:	4785                	li	a5,1
    80004070:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004072:	04449783          	lh	a5,68(s1)
    80004076:	fbb5                	bnez	a5,80003fea <ilock+0x24>
      panic("ilock: no type");
    80004078:	00005517          	auipc	a0,0x5
    8000407c:	85050513          	addi	a0,a0,-1968 # 800088c8 <syscalls+0x1a0>
    80004080:	ffffc097          	auipc	ra,0xffffc
    80004084:	4be080e7          	jalr	1214(ra) # 8000053e <panic>

0000000080004088 <iunlock>:
{
    80004088:	1101                	addi	sp,sp,-32
    8000408a:	ec06                	sd	ra,24(sp)
    8000408c:	e822                	sd	s0,16(sp)
    8000408e:	e426                	sd	s1,8(sp)
    80004090:	e04a                	sd	s2,0(sp)
    80004092:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004094:	c905                	beqz	a0,800040c4 <iunlock+0x3c>
    80004096:	84aa                	mv	s1,a0
    80004098:	01050913          	addi	s2,a0,16
    8000409c:	854a                	mv	a0,s2
    8000409e:	00001097          	auipc	ra,0x1
    800040a2:	c8c080e7          	jalr	-884(ra) # 80004d2a <holdingsleep>
    800040a6:	cd19                	beqz	a0,800040c4 <iunlock+0x3c>
    800040a8:	449c                	lw	a5,8(s1)
    800040aa:	00f05d63          	blez	a5,800040c4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800040ae:	854a                	mv	a0,s2
    800040b0:	00001097          	auipc	ra,0x1
    800040b4:	c36080e7          	jalr	-970(ra) # 80004ce6 <releasesleep>
}
    800040b8:	60e2                	ld	ra,24(sp)
    800040ba:	6442                	ld	s0,16(sp)
    800040bc:	64a2                	ld	s1,8(sp)
    800040be:	6902                	ld	s2,0(sp)
    800040c0:	6105                	addi	sp,sp,32
    800040c2:	8082                	ret
    panic("iunlock");
    800040c4:	00005517          	auipc	a0,0x5
    800040c8:	81450513          	addi	a0,a0,-2028 # 800088d8 <syscalls+0x1b0>
    800040cc:	ffffc097          	auipc	ra,0xffffc
    800040d0:	472080e7          	jalr	1138(ra) # 8000053e <panic>

00000000800040d4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800040d4:	7179                	addi	sp,sp,-48
    800040d6:	f406                	sd	ra,40(sp)
    800040d8:	f022                	sd	s0,32(sp)
    800040da:	ec26                	sd	s1,24(sp)
    800040dc:	e84a                	sd	s2,16(sp)
    800040de:	e44e                	sd	s3,8(sp)
    800040e0:	e052                	sd	s4,0(sp)
    800040e2:	1800                	addi	s0,sp,48
    800040e4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800040e6:	05050493          	addi	s1,a0,80
    800040ea:	08050913          	addi	s2,a0,128
    800040ee:	a021                	j	800040f6 <itrunc+0x22>
    800040f0:	0491                	addi	s1,s1,4
    800040f2:	01248d63          	beq	s1,s2,8000410c <itrunc+0x38>
    if(ip->addrs[i]){
    800040f6:	408c                	lw	a1,0(s1)
    800040f8:	dde5                	beqz	a1,800040f0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800040fa:	0009a503          	lw	a0,0(s3)
    800040fe:	00000097          	auipc	ra,0x0
    80004102:	90c080e7          	jalr	-1780(ra) # 80003a0a <bfree>
      ip->addrs[i] = 0;
    80004106:	0004a023          	sw	zero,0(s1)
    8000410a:	b7dd                	j	800040f0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000410c:	0809a583          	lw	a1,128(s3)
    80004110:	e185                	bnez	a1,80004130 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004112:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004116:	854e                	mv	a0,s3
    80004118:	00000097          	auipc	ra,0x0
    8000411c:	de4080e7          	jalr	-540(ra) # 80003efc <iupdate>
}
    80004120:	70a2                	ld	ra,40(sp)
    80004122:	7402                	ld	s0,32(sp)
    80004124:	64e2                	ld	s1,24(sp)
    80004126:	6942                	ld	s2,16(sp)
    80004128:	69a2                	ld	s3,8(sp)
    8000412a:	6a02                	ld	s4,0(sp)
    8000412c:	6145                	addi	sp,sp,48
    8000412e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004130:	0009a503          	lw	a0,0(s3)
    80004134:	fffff097          	auipc	ra,0xfffff
    80004138:	690080e7          	jalr	1680(ra) # 800037c4 <bread>
    8000413c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000413e:	05850493          	addi	s1,a0,88
    80004142:	45850913          	addi	s2,a0,1112
    80004146:	a811                	j	8000415a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004148:	0009a503          	lw	a0,0(s3)
    8000414c:	00000097          	auipc	ra,0x0
    80004150:	8be080e7          	jalr	-1858(ra) # 80003a0a <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004154:	0491                	addi	s1,s1,4
    80004156:	01248563          	beq	s1,s2,80004160 <itrunc+0x8c>
      if(a[j])
    8000415a:	408c                	lw	a1,0(s1)
    8000415c:	dde5                	beqz	a1,80004154 <itrunc+0x80>
    8000415e:	b7ed                	j	80004148 <itrunc+0x74>
    brelse(bp);
    80004160:	8552                	mv	a0,s4
    80004162:	fffff097          	auipc	ra,0xfffff
    80004166:	792080e7          	jalr	1938(ra) # 800038f4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000416a:	0809a583          	lw	a1,128(s3)
    8000416e:	0009a503          	lw	a0,0(s3)
    80004172:	00000097          	auipc	ra,0x0
    80004176:	898080e7          	jalr	-1896(ra) # 80003a0a <bfree>
    ip->addrs[NDIRECT] = 0;
    8000417a:	0809a023          	sw	zero,128(s3)
    8000417e:	bf51                	j	80004112 <itrunc+0x3e>

0000000080004180 <iput>:
{
    80004180:	1101                	addi	sp,sp,-32
    80004182:	ec06                	sd	ra,24(sp)
    80004184:	e822                	sd	s0,16(sp)
    80004186:	e426                	sd	s1,8(sp)
    80004188:	e04a                	sd	s2,0(sp)
    8000418a:	1000                	addi	s0,sp,32
    8000418c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000418e:	0001c517          	auipc	a0,0x1c
    80004192:	1ba50513          	addi	a0,a0,442 # 80020348 <itable>
    80004196:	ffffd097          	auipc	ra,0xffffd
    8000419a:	a4e080e7          	jalr	-1458(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000419e:	4498                	lw	a4,8(s1)
    800041a0:	4785                	li	a5,1
    800041a2:	02f70363          	beq	a4,a5,800041c8 <iput+0x48>
  ip->ref--;
    800041a6:	449c                	lw	a5,8(s1)
    800041a8:	37fd                	addiw	a5,a5,-1
    800041aa:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800041ac:	0001c517          	auipc	a0,0x1c
    800041b0:	19c50513          	addi	a0,a0,412 # 80020348 <itable>
    800041b4:	ffffd097          	auipc	ra,0xffffd
    800041b8:	ae4080e7          	jalr	-1308(ra) # 80000c98 <release>
}
    800041bc:	60e2                	ld	ra,24(sp)
    800041be:	6442                	ld	s0,16(sp)
    800041c0:	64a2                	ld	s1,8(sp)
    800041c2:	6902                	ld	s2,0(sp)
    800041c4:	6105                	addi	sp,sp,32
    800041c6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800041c8:	40bc                	lw	a5,64(s1)
    800041ca:	dff1                	beqz	a5,800041a6 <iput+0x26>
    800041cc:	04a49783          	lh	a5,74(s1)
    800041d0:	fbf9                	bnez	a5,800041a6 <iput+0x26>
    acquiresleep(&ip->lock);
    800041d2:	01048913          	addi	s2,s1,16
    800041d6:	854a                	mv	a0,s2
    800041d8:	00001097          	auipc	ra,0x1
    800041dc:	ab8080e7          	jalr	-1352(ra) # 80004c90 <acquiresleep>
    release(&itable.lock);
    800041e0:	0001c517          	auipc	a0,0x1c
    800041e4:	16850513          	addi	a0,a0,360 # 80020348 <itable>
    800041e8:	ffffd097          	auipc	ra,0xffffd
    800041ec:	ab0080e7          	jalr	-1360(ra) # 80000c98 <release>
    itrunc(ip);
    800041f0:	8526                	mv	a0,s1
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	ee2080e7          	jalr	-286(ra) # 800040d4 <itrunc>
    ip->type = 0;
    800041fa:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800041fe:	8526                	mv	a0,s1
    80004200:	00000097          	auipc	ra,0x0
    80004204:	cfc080e7          	jalr	-772(ra) # 80003efc <iupdate>
    ip->valid = 0;
    80004208:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000420c:	854a                	mv	a0,s2
    8000420e:	00001097          	auipc	ra,0x1
    80004212:	ad8080e7          	jalr	-1320(ra) # 80004ce6 <releasesleep>
    acquire(&itable.lock);
    80004216:	0001c517          	auipc	a0,0x1c
    8000421a:	13250513          	addi	a0,a0,306 # 80020348 <itable>
    8000421e:	ffffd097          	auipc	ra,0xffffd
    80004222:	9c6080e7          	jalr	-1594(ra) # 80000be4 <acquire>
    80004226:	b741                	j	800041a6 <iput+0x26>

0000000080004228 <iunlockput>:
{
    80004228:	1101                	addi	sp,sp,-32
    8000422a:	ec06                	sd	ra,24(sp)
    8000422c:	e822                	sd	s0,16(sp)
    8000422e:	e426                	sd	s1,8(sp)
    80004230:	1000                	addi	s0,sp,32
    80004232:	84aa                	mv	s1,a0
  iunlock(ip);
    80004234:	00000097          	auipc	ra,0x0
    80004238:	e54080e7          	jalr	-428(ra) # 80004088 <iunlock>
  iput(ip);
    8000423c:	8526                	mv	a0,s1
    8000423e:	00000097          	auipc	ra,0x0
    80004242:	f42080e7          	jalr	-190(ra) # 80004180 <iput>
}
    80004246:	60e2                	ld	ra,24(sp)
    80004248:	6442                	ld	s0,16(sp)
    8000424a:	64a2                	ld	s1,8(sp)
    8000424c:	6105                	addi	sp,sp,32
    8000424e:	8082                	ret

0000000080004250 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004250:	1141                	addi	sp,sp,-16
    80004252:	e422                	sd	s0,8(sp)
    80004254:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004256:	411c                	lw	a5,0(a0)
    80004258:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000425a:	415c                	lw	a5,4(a0)
    8000425c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000425e:	04451783          	lh	a5,68(a0)
    80004262:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004266:	04a51783          	lh	a5,74(a0)
    8000426a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000426e:	04c56783          	lwu	a5,76(a0)
    80004272:	e99c                	sd	a5,16(a1)
}
    80004274:	6422                	ld	s0,8(sp)
    80004276:	0141                	addi	sp,sp,16
    80004278:	8082                	ret

000000008000427a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000427a:	457c                	lw	a5,76(a0)
    8000427c:	0ed7e963          	bltu	a5,a3,8000436e <readi+0xf4>
{
    80004280:	7159                	addi	sp,sp,-112
    80004282:	f486                	sd	ra,104(sp)
    80004284:	f0a2                	sd	s0,96(sp)
    80004286:	eca6                	sd	s1,88(sp)
    80004288:	e8ca                	sd	s2,80(sp)
    8000428a:	e4ce                	sd	s3,72(sp)
    8000428c:	e0d2                	sd	s4,64(sp)
    8000428e:	fc56                	sd	s5,56(sp)
    80004290:	f85a                	sd	s6,48(sp)
    80004292:	f45e                	sd	s7,40(sp)
    80004294:	f062                	sd	s8,32(sp)
    80004296:	ec66                	sd	s9,24(sp)
    80004298:	e86a                	sd	s10,16(sp)
    8000429a:	e46e                	sd	s11,8(sp)
    8000429c:	1880                	addi	s0,sp,112
    8000429e:	8baa                	mv	s7,a0
    800042a0:	8c2e                	mv	s8,a1
    800042a2:	8ab2                	mv	s5,a2
    800042a4:	84b6                	mv	s1,a3
    800042a6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800042a8:	9f35                	addw	a4,a4,a3
    return 0;
    800042aa:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800042ac:	0ad76063          	bltu	a4,a3,8000434c <readi+0xd2>
  if(off + n > ip->size)
    800042b0:	00e7f463          	bgeu	a5,a4,800042b8 <readi+0x3e>
    n = ip->size - off;
    800042b4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042b8:	0a0b0963          	beqz	s6,8000436a <readi+0xf0>
    800042bc:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800042be:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800042c2:	5cfd                	li	s9,-1
    800042c4:	a82d                	j	800042fe <readi+0x84>
    800042c6:	020a1d93          	slli	s11,s4,0x20
    800042ca:	020ddd93          	srli	s11,s11,0x20
    800042ce:	05890613          	addi	a2,s2,88
    800042d2:	86ee                	mv	a3,s11
    800042d4:	963a                	add	a2,a2,a4
    800042d6:	85d6                	mv	a1,s5
    800042d8:	8562                	mv	a0,s8
    800042da:	ffffe097          	auipc	ra,0xffffe
    800042de:	57c080e7          	jalr	1404(ra) # 80002856 <either_copyout>
    800042e2:	05950d63          	beq	a0,s9,8000433c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800042e6:	854a                	mv	a0,s2
    800042e8:	fffff097          	auipc	ra,0xfffff
    800042ec:	60c080e7          	jalr	1548(ra) # 800038f4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042f0:	013a09bb          	addw	s3,s4,s3
    800042f4:	009a04bb          	addw	s1,s4,s1
    800042f8:	9aee                	add	s5,s5,s11
    800042fa:	0569f763          	bgeu	s3,s6,80004348 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800042fe:	000ba903          	lw	s2,0(s7)
    80004302:	00a4d59b          	srliw	a1,s1,0xa
    80004306:	855e                	mv	a0,s7
    80004308:	00000097          	auipc	ra,0x0
    8000430c:	8b0080e7          	jalr	-1872(ra) # 80003bb8 <bmap>
    80004310:	0005059b          	sext.w	a1,a0
    80004314:	854a                	mv	a0,s2
    80004316:	fffff097          	auipc	ra,0xfffff
    8000431a:	4ae080e7          	jalr	1198(ra) # 800037c4 <bread>
    8000431e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004320:	3ff4f713          	andi	a4,s1,1023
    80004324:	40ed07bb          	subw	a5,s10,a4
    80004328:	413b06bb          	subw	a3,s6,s3
    8000432c:	8a3e                	mv	s4,a5
    8000432e:	2781                	sext.w	a5,a5
    80004330:	0006861b          	sext.w	a2,a3
    80004334:	f8f679e3          	bgeu	a2,a5,800042c6 <readi+0x4c>
    80004338:	8a36                	mv	s4,a3
    8000433a:	b771                	j	800042c6 <readi+0x4c>
      brelse(bp);
    8000433c:	854a                	mv	a0,s2
    8000433e:	fffff097          	auipc	ra,0xfffff
    80004342:	5b6080e7          	jalr	1462(ra) # 800038f4 <brelse>
      tot = -1;
    80004346:	59fd                	li	s3,-1
  }
  return tot;
    80004348:	0009851b          	sext.w	a0,s3
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
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000436a:	89da                	mv	s3,s6
    8000436c:	bff1                	j	80004348 <readi+0xce>
    return 0;
    8000436e:	4501                	li	a0,0
}
    80004370:	8082                	ret

0000000080004372 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004372:	457c                	lw	a5,76(a0)
    80004374:	10d7e863          	bltu	a5,a3,80004484 <writei+0x112>
{
    80004378:	7159                	addi	sp,sp,-112
    8000437a:	f486                	sd	ra,104(sp)
    8000437c:	f0a2                	sd	s0,96(sp)
    8000437e:	eca6                	sd	s1,88(sp)
    80004380:	e8ca                	sd	s2,80(sp)
    80004382:	e4ce                	sd	s3,72(sp)
    80004384:	e0d2                	sd	s4,64(sp)
    80004386:	fc56                	sd	s5,56(sp)
    80004388:	f85a                	sd	s6,48(sp)
    8000438a:	f45e                	sd	s7,40(sp)
    8000438c:	f062                	sd	s8,32(sp)
    8000438e:	ec66                	sd	s9,24(sp)
    80004390:	e86a                	sd	s10,16(sp)
    80004392:	e46e                	sd	s11,8(sp)
    80004394:	1880                	addi	s0,sp,112
    80004396:	8b2a                	mv	s6,a0
    80004398:	8c2e                	mv	s8,a1
    8000439a:	8ab2                	mv	s5,a2
    8000439c:	8936                	mv	s2,a3
    8000439e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800043a0:	00e687bb          	addw	a5,a3,a4
    800043a4:	0ed7e263          	bltu	a5,a3,80004488 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800043a8:	00043737          	lui	a4,0x43
    800043ac:	0ef76063          	bltu	a4,a5,8000448c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043b0:	0c0b8863          	beqz	s7,80004480 <writei+0x10e>
    800043b4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800043b6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800043ba:	5cfd                	li	s9,-1
    800043bc:	a091                	j	80004400 <writei+0x8e>
    800043be:	02099d93          	slli	s11,s3,0x20
    800043c2:	020ddd93          	srli	s11,s11,0x20
    800043c6:	05848513          	addi	a0,s1,88
    800043ca:	86ee                	mv	a3,s11
    800043cc:	8656                	mv	a2,s5
    800043ce:	85e2                	mv	a1,s8
    800043d0:	953a                	add	a0,a0,a4
    800043d2:	ffffe097          	auipc	ra,0xffffe
    800043d6:	4da080e7          	jalr	1242(ra) # 800028ac <either_copyin>
    800043da:	07950263          	beq	a0,s9,8000443e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800043de:	8526                	mv	a0,s1
    800043e0:	00000097          	auipc	ra,0x0
    800043e4:	790080e7          	jalr	1936(ra) # 80004b70 <log_write>
    brelse(bp);
    800043e8:	8526                	mv	a0,s1
    800043ea:	fffff097          	auipc	ra,0xfffff
    800043ee:	50a080e7          	jalr	1290(ra) # 800038f4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043f2:	01498a3b          	addw	s4,s3,s4
    800043f6:	0129893b          	addw	s2,s3,s2
    800043fa:	9aee                	add	s5,s5,s11
    800043fc:	057a7663          	bgeu	s4,s7,80004448 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004400:	000b2483          	lw	s1,0(s6)
    80004404:	00a9559b          	srliw	a1,s2,0xa
    80004408:	855a                	mv	a0,s6
    8000440a:	fffff097          	auipc	ra,0xfffff
    8000440e:	7ae080e7          	jalr	1966(ra) # 80003bb8 <bmap>
    80004412:	0005059b          	sext.w	a1,a0
    80004416:	8526                	mv	a0,s1
    80004418:	fffff097          	auipc	ra,0xfffff
    8000441c:	3ac080e7          	jalr	940(ra) # 800037c4 <bread>
    80004420:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004422:	3ff97713          	andi	a4,s2,1023
    80004426:	40ed07bb          	subw	a5,s10,a4
    8000442a:	414b86bb          	subw	a3,s7,s4
    8000442e:	89be                	mv	s3,a5
    80004430:	2781                	sext.w	a5,a5
    80004432:	0006861b          	sext.w	a2,a3
    80004436:	f8f674e3          	bgeu	a2,a5,800043be <writei+0x4c>
    8000443a:	89b6                	mv	s3,a3
    8000443c:	b749                	j	800043be <writei+0x4c>
      brelse(bp);
    8000443e:	8526                	mv	a0,s1
    80004440:	fffff097          	auipc	ra,0xfffff
    80004444:	4b4080e7          	jalr	1204(ra) # 800038f4 <brelse>
  }

  if(off > ip->size)
    80004448:	04cb2783          	lw	a5,76(s6)
    8000444c:	0127f463          	bgeu	a5,s2,80004454 <writei+0xe2>
    ip->size = off;
    80004450:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004454:	855a                	mv	a0,s6
    80004456:	00000097          	auipc	ra,0x0
    8000445a:	aa6080e7          	jalr	-1370(ra) # 80003efc <iupdate>

  return tot;
    8000445e:	000a051b          	sext.w	a0,s4
}
    80004462:	70a6                	ld	ra,104(sp)
    80004464:	7406                	ld	s0,96(sp)
    80004466:	64e6                	ld	s1,88(sp)
    80004468:	6946                	ld	s2,80(sp)
    8000446a:	69a6                	ld	s3,72(sp)
    8000446c:	6a06                	ld	s4,64(sp)
    8000446e:	7ae2                	ld	s5,56(sp)
    80004470:	7b42                	ld	s6,48(sp)
    80004472:	7ba2                	ld	s7,40(sp)
    80004474:	7c02                	ld	s8,32(sp)
    80004476:	6ce2                	ld	s9,24(sp)
    80004478:	6d42                	ld	s10,16(sp)
    8000447a:	6da2                	ld	s11,8(sp)
    8000447c:	6165                	addi	sp,sp,112
    8000447e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004480:	8a5e                	mv	s4,s7
    80004482:	bfc9                	j	80004454 <writei+0xe2>
    return -1;
    80004484:	557d                	li	a0,-1
}
    80004486:	8082                	ret
    return -1;
    80004488:	557d                	li	a0,-1
    8000448a:	bfe1                	j	80004462 <writei+0xf0>
    return -1;
    8000448c:	557d                	li	a0,-1
    8000448e:	bfd1                	j	80004462 <writei+0xf0>

0000000080004490 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004490:	1141                	addi	sp,sp,-16
    80004492:	e406                	sd	ra,8(sp)
    80004494:	e022                	sd	s0,0(sp)
    80004496:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004498:	4639                	li	a2,14
    8000449a:	ffffd097          	auipc	ra,0xffffd
    8000449e:	91e080e7          	jalr	-1762(ra) # 80000db8 <strncmp>
}
    800044a2:	60a2                	ld	ra,8(sp)
    800044a4:	6402                	ld	s0,0(sp)
    800044a6:	0141                	addi	sp,sp,16
    800044a8:	8082                	ret

00000000800044aa <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800044aa:	7139                	addi	sp,sp,-64
    800044ac:	fc06                	sd	ra,56(sp)
    800044ae:	f822                	sd	s0,48(sp)
    800044b0:	f426                	sd	s1,40(sp)
    800044b2:	f04a                	sd	s2,32(sp)
    800044b4:	ec4e                	sd	s3,24(sp)
    800044b6:	e852                	sd	s4,16(sp)
    800044b8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800044ba:	04451703          	lh	a4,68(a0)
    800044be:	4785                	li	a5,1
    800044c0:	00f71a63          	bne	a4,a5,800044d4 <dirlookup+0x2a>
    800044c4:	892a                	mv	s2,a0
    800044c6:	89ae                	mv	s3,a1
    800044c8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800044ca:	457c                	lw	a5,76(a0)
    800044cc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800044ce:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044d0:	e79d                	bnez	a5,800044fe <dirlookup+0x54>
    800044d2:	a8a5                	j	8000454a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800044d4:	00004517          	auipc	a0,0x4
    800044d8:	40c50513          	addi	a0,a0,1036 # 800088e0 <syscalls+0x1b8>
    800044dc:	ffffc097          	auipc	ra,0xffffc
    800044e0:	062080e7          	jalr	98(ra) # 8000053e <panic>
      panic("dirlookup read");
    800044e4:	00004517          	auipc	a0,0x4
    800044e8:	41450513          	addi	a0,a0,1044 # 800088f8 <syscalls+0x1d0>
    800044ec:	ffffc097          	auipc	ra,0xffffc
    800044f0:	052080e7          	jalr	82(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044f4:	24c1                	addiw	s1,s1,16
    800044f6:	04c92783          	lw	a5,76(s2)
    800044fa:	04f4f763          	bgeu	s1,a5,80004548 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044fe:	4741                	li	a4,16
    80004500:	86a6                	mv	a3,s1
    80004502:	fc040613          	addi	a2,s0,-64
    80004506:	4581                	li	a1,0
    80004508:	854a                	mv	a0,s2
    8000450a:	00000097          	auipc	ra,0x0
    8000450e:	d70080e7          	jalr	-656(ra) # 8000427a <readi>
    80004512:	47c1                	li	a5,16
    80004514:	fcf518e3          	bne	a0,a5,800044e4 <dirlookup+0x3a>
    if(de.inum == 0)
    80004518:	fc045783          	lhu	a5,-64(s0)
    8000451c:	dfe1                	beqz	a5,800044f4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000451e:	fc240593          	addi	a1,s0,-62
    80004522:	854e                	mv	a0,s3
    80004524:	00000097          	auipc	ra,0x0
    80004528:	f6c080e7          	jalr	-148(ra) # 80004490 <namecmp>
    8000452c:	f561                	bnez	a0,800044f4 <dirlookup+0x4a>
      if(poff)
    8000452e:	000a0463          	beqz	s4,80004536 <dirlookup+0x8c>
        *poff = off;
    80004532:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004536:	fc045583          	lhu	a1,-64(s0)
    8000453a:	00092503          	lw	a0,0(s2)
    8000453e:	fffff097          	auipc	ra,0xfffff
    80004542:	754080e7          	jalr	1876(ra) # 80003c92 <iget>
    80004546:	a011                	j	8000454a <dirlookup+0xa0>
  return 0;
    80004548:	4501                	li	a0,0
}
    8000454a:	70e2                	ld	ra,56(sp)
    8000454c:	7442                	ld	s0,48(sp)
    8000454e:	74a2                	ld	s1,40(sp)
    80004550:	7902                	ld	s2,32(sp)
    80004552:	69e2                	ld	s3,24(sp)
    80004554:	6a42                	ld	s4,16(sp)
    80004556:	6121                	addi	sp,sp,64
    80004558:	8082                	ret

000000008000455a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000455a:	711d                	addi	sp,sp,-96
    8000455c:	ec86                	sd	ra,88(sp)
    8000455e:	e8a2                	sd	s0,80(sp)
    80004560:	e4a6                	sd	s1,72(sp)
    80004562:	e0ca                	sd	s2,64(sp)
    80004564:	fc4e                	sd	s3,56(sp)
    80004566:	f852                	sd	s4,48(sp)
    80004568:	f456                	sd	s5,40(sp)
    8000456a:	f05a                	sd	s6,32(sp)
    8000456c:	ec5e                	sd	s7,24(sp)
    8000456e:	e862                	sd	s8,16(sp)
    80004570:	e466                	sd	s9,8(sp)
    80004572:	1080                	addi	s0,sp,96
    80004574:	84aa                	mv	s1,a0
    80004576:	8b2e                	mv	s6,a1
    80004578:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000457a:	00054703          	lbu	a4,0(a0)
    8000457e:	02f00793          	li	a5,47
    80004582:	02f70363          	beq	a4,a5,800045a8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004586:	ffffe097          	auipc	ra,0xffffe
    8000458a:	93e080e7          	jalr	-1730(ra) # 80001ec4 <myproc>
    8000458e:	15053503          	ld	a0,336(a0)
    80004592:	00000097          	auipc	ra,0x0
    80004596:	9f6080e7          	jalr	-1546(ra) # 80003f88 <idup>
    8000459a:	89aa                	mv	s3,a0
  while(*path == '/')
    8000459c:	02f00913          	li	s2,47
  len = path - s;
    800045a0:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800045a2:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800045a4:	4c05                	li	s8,1
    800045a6:	a865                	j	8000465e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800045a8:	4585                	li	a1,1
    800045aa:	4505                	li	a0,1
    800045ac:	fffff097          	auipc	ra,0xfffff
    800045b0:	6e6080e7          	jalr	1766(ra) # 80003c92 <iget>
    800045b4:	89aa                	mv	s3,a0
    800045b6:	b7dd                	j	8000459c <namex+0x42>
      iunlockput(ip);
    800045b8:	854e                	mv	a0,s3
    800045ba:	00000097          	auipc	ra,0x0
    800045be:	c6e080e7          	jalr	-914(ra) # 80004228 <iunlockput>
      return 0;
    800045c2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800045c4:	854e                	mv	a0,s3
    800045c6:	60e6                	ld	ra,88(sp)
    800045c8:	6446                	ld	s0,80(sp)
    800045ca:	64a6                	ld	s1,72(sp)
    800045cc:	6906                	ld	s2,64(sp)
    800045ce:	79e2                	ld	s3,56(sp)
    800045d0:	7a42                	ld	s4,48(sp)
    800045d2:	7aa2                	ld	s5,40(sp)
    800045d4:	7b02                	ld	s6,32(sp)
    800045d6:	6be2                	ld	s7,24(sp)
    800045d8:	6c42                	ld	s8,16(sp)
    800045da:	6ca2                	ld	s9,8(sp)
    800045dc:	6125                	addi	sp,sp,96
    800045de:	8082                	ret
      iunlock(ip);
    800045e0:	854e                	mv	a0,s3
    800045e2:	00000097          	auipc	ra,0x0
    800045e6:	aa6080e7          	jalr	-1370(ra) # 80004088 <iunlock>
      return ip;
    800045ea:	bfe9                	j	800045c4 <namex+0x6a>
      iunlockput(ip);
    800045ec:	854e                	mv	a0,s3
    800045ee:	00000097          	auipc	ra,0x0
    800045f2:	c3a080e7          	jalr	-966(ra) # 80004228 <iunlockput>
      return 0;
    800045f6:	89d2                	mv	s3,s4
    800045f8:	b7f1                	j	800045c4 <namex+0x6a>
  len = path - s;
    800045fa:	40b48633          	sub	a2,s1,a1
    800045fe:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004602:	094cd463          	bge	s9,s4,8000468a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004606:	4639                	li	a2,14
    80004608:	8556                	mv	a0,s5
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	736080e7          	jalr	1846(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004612:	0004c783          	lbu	a5,0(s1)
    80004616:	01279763          	bne	a5,s2,80004624 <namex+0xca>
    path++;
    8000461a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000461c:	0004c783          	lbu	a5,0(s1)
    80004620:	ff278de3          	beq	a5,s2,8000461a <namex+0xc0>
    ilock(ip);
    80004624:	854e                	mv	a0,s3
    80004626:	00000097          	auipc	ra,0x0
    8000462a:	9a0080e7          	jalr	-1632(ra) # 80003fc6 <ilock>
    if(ip->type != T_DIR){
    8000462e:	04499783          	lh	a5,68(s3)
    80004632:	f98793e3          	bne	a5,s8,800045b8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004636:	000b0563          	beqz	s6,80004640 <namex+0xe6>
    8000463a:	0004c783          	lbu	a5,0(s1)
    8000463e:	d3cd                	beqz	a5,800045e0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004640:	865e                	mv	a2,s7
    80004642:	85d6                	mv	a1,s5
    80004644:	854e                	mv	a0,s3
    80004646:	00000097          	auipc	ra,0x0
    8000464a:	e64080e7          	jalr	-412(ra) # 800044aa <dirlookup>
    8000464e:	8a2a                	mv	s4,a0
    80004650:	dd51                	beqz	a0,800045ec <namex+0x92>
    iunlockput(ip);
    80004652:	854e                	mv	a0,s3
    80004654:	00000097          	auipc	ra,0x0
    80004658:	bd4080e7          	jalr	-1068(ra) # 80004228 <iunlockput>
    ip = next;
    8000465c:	89d2                	mv	s3,s4
  while(*path == '/')
    8000465e:	0004c783          	lbu	a5,0(s1)
    80004662:	05279763          	bne	a5,s2,800046b0 <namex+0x156>
    path++;
    80004666:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004668:	0004c783          	lbu	a5,0(s1)
    8000466c:	ff278de3          	beq	a5,s2,80004666 <namex+0x10c>
  if(*path == 0)
    80004670:	c79d                	beqz	a5,8000469e <namex+0x144>
    path++;
    80004672:	85a6                	mv	a1,s1
  len = path - s;
    80004674:	8a5e                	mv	s4,s7
    80004676:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004678:	01278963          	beq	a5,s2,8000468a <namex+0x130>
    8000467c:	dfbd                	beqz	a5,800045fa <namex+0xa0>
    path++;
    8000467e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004680:	0004c783          	lbu	a5,0(s1)
    80004684:	ff279ce3          	bne	a5,s2,8000467c <namex+0x122>
    80004688:	bf8d                	j	800045fa <namex+0xa0>
    memmove(name, s, len);
    8000468a:	2601                	sext.w	a2,a2
    8000468c:	8556                	mv	a0,s5
    8000468e:	ffffc097          	auipc	ra,0xffffc
    80004692:	6b2080e7          	jalr	1714(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004696:	9a56                	add	s4,s4,s5
    80004698:	000a0023          	sb	zero,0(s4)
    8000469c:	bf9d                	j	80004612 <namex+0xb8>
  if(nameiparent){
    8000469e:	f20b03e3          	beqz	s6,800045c4 <namex+0x6a>
    iput(ip);
    800046a2:	854e                	mv	a0,s3
    800046a4:	00000097          	auipc	ra,0x0
    800046a8:	adc080e7          	jalr	-1316(ra) # 80004180 <iput>
    return 0;
    800046ac:	4981                	li	s3,0
    800046ae:	bf19                	j	800045c4 <namex+0x6a>
  if(*path == 0)
    800046b0:	d7fd                	beqz	a5,8000469e <namex+0x144>
  while(*path != '/' && *path != 0)
    800046b2:	0004c783          	lbu	a5,0(s1)
    800046b6:	85a6                	mv	a1,s1
    800046b8:	b7d1                	j	8000467c <namex+0x122>

00000000800046ba <dirlink>:
{
    800046ba:	7139                	addi	sp,sp,-64
    800046bc:	fc06                	sd	ra,56(sp)
    800046be:	f822                	sd	s0,48(sp)
    800046c0:	f426                	sd	s1,40(sp)
    800046c2:	f04a                	sd	s2,32(sp)
    800046c4:	ec4e                	sd	s3,24(sp)
    800046c6:	e852                	sd	s4,16(sp)
    800046c8:	0080                	addi	s0,sp,64
    800046ca:	892a                	mv	s2,a0
    800046cc:	8a2e                	mv	s4,a1
    800046ce:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800046d0:	4601                	li	a2,0
    800046d2:	00000097          	auipc	ra,0x0
    800046d6:	dd8080e7          	jalr	-552(ra) # 800044aa <dirlookup>
    800046da:	e93d                	bnez	a0,80004750 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046dc:	04c92483          	lw	s1,76(s2)
    800046e0:	c49d                	beqz	s1,8000470e <dirlink+0x54>
    800046e2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046e4:	4741                	li	a4,16
    800046e6:	86a6                	mv	a3,s1
    800046e8:	fc040613          	addi	a2,s0,-64
    800046ec:	4581                	li	a1,0
    800046ee:	854a                	mv	a0,s2
    800046f0:	00000097          	auipc	ra,0x0
    800046f4:	b8a080e7          	jalr	-1142(ra) # 8000427a <readi>
    800046f8:	47c1                	li	a5,16
    800046fa:	06f51163          	bne	a0,a5,8000475c <dirlink+0xa2>
    if(de.inum == 0)
    800046fe:	fc045783          	lhu	a5,-64(s0)
    80004702:	c791                	beqz	a5,8000470e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004704:	24c1                	addiw	s1,s1,16
    80004706:	04c92783          	lw	a5,76(s2)
    8000470a:	fcf4ede3          	bltu	s1,a5,800046e4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000470e:	4639                	li	a2,14
    80004710:	85d2                	mv	a1,s4
    80004712:	fc240513          	addi	a0,s0,-62
    80004716:	ffffc097          	auipc	ra,0xffffc
    8000471a:	6de080e7          	jalr	1758(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000471e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004722:	4741                	li	a4,16
    80004724:	86a6                	mv	a3,s1
    80004726:	fc040613          	addi	a2,s0,-64
    8000472a:	4581                	li	a1,0
    8000472c:	854a                	mv	a0,s2
    8000472e:	00000097          	auipc	ra,0x0
    80004732:	c44080e7          	jalr	-956(ra) # 80004372 <writei>
    80004736:	872a                	mv	a4,a0
    80004738:	47c1                	li	a5,16
  return 0;
    8000473a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000473c:	02f71863          	bne	a4,a5,8000476c <dirlink+0xb2>
}
    80004740:	70e2                	ld	ra,56(sp)
    80004742:	7442                	ld	s0,48(sp)
    80004744:	74a2                	ld	s1,40(sp)
    80004746:	7902                	ld	s2,32(sp)
    80004748:	69e2                	ld	s3,24(sp)
    8000474a:	6a42                	ld	s4,16(sp)
    8000474c:	6121                	addi	sp,sp,64
    8000474e:	8082                	ret
    iput(ip);
    80004750:	00000097          	auipc	ra,0x0
    80004754:	a30080e7          	jalr	-1488(ra) # 80004180 <iput>
    return -1;
    80004758:	557d                	li	a0,-1
    8000475a:	b7dd                	j	80004740 <dirlink+0x86>
      panic("dirlink read");
    8000475c:	00004517          	auipc	a0,0x4
    80004760:	1ac50513          	addi	a0,a0,428 # 80008908 <syscalls+0x1e0>
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	dda080e7          	jalr	-550(ra) # 8000053e <panic>
    panic("dirlink");
    8000476c:	00004517          	auipc	a0,0x4
    80004770:	2ac50513          	addi	a0,a0,684 # 80008a18 <syscalls+0x2f0>
    80004774:	ffffc097          	auipc	ra,0xffffc
    80004778:	dca080e7          	jalr	-566(ra) # 8000053e <panic>

000000008000477c <namei>:

struct inode*
namei(char *path)
{
    8000477c:	1101                	addi	sp,sp,-32
    8000477e:	ec06                	sd	ra,24(sp)
    80004780:	e822                	sd	s0,16(sp)
    80004782:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004784:	fe040613          	addi	a2,s0,-32
    80004788:	4581                	li	a1,0
    8000478a:	00000097          	auipc	ra,0x0
    8000478e:	dd0080e7          	jalr	-560(ra) # 8000455a <namex>
}
    80004792:	60e2                	ld	ra,24(sp)
    80004794:	6442                	ld	s0,16(sp)
    80004796:	6105                	addi	sp,sp,32
    80004798:	8082                	ret

000000008000479a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000479a:	1141                	addi	sp,sp,-16
    8000479c:	e406                	sd	ra,8(sp)
    8000479e:	e022                	sd	s0,0(sp)
    800047a0:	0800                	addi	s0,sp,16
    800047a2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800047a4:	4585                	li	a1,1
    800047a6:	00000097          	auipc	ra,0x0
    800047aa:	db4080e7          	jalr	-588(ra) # 8000455a <namex>
}
    800047ae:	60a2                	ld	ra,8(sp)
    800047b0:	6402                	ld	s0,0(sp)
    800047b2:	0141                	addi	sp,sp,16
    800047b4:	8082                	ret

00000000800047b6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800047b6:	1101                	addi	sp,sp,-32
    800047b8:	ec06                	sd	ra,24(sp)
    800047ba:	e822                	sd	s0,16(sp)
    800047bc:	e426                	sd	s1,8(sp)
    800047be:	e04a                	sd	s2,0(sp)
    800047c0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800047c2:	0001d917          	auipc	s2,0x1d
    800047c6:	62e90913          	addi	s2,s2,1582 # 80021df0 <log>
    800047ca:	01892583          	lw	a1,24(s2)
    800047ce:	02892503          	lw	a0,40(s2)
    800047d2:	fffff097          	auipc	ra,0xfffff
    800047d6:	ff2080e7          	jalr	-14(ra) # 800037c4 <bread>
    800047da:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800047dc:	02c92683          	lw	a3,44(s2)
    800047e0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800047e2:	02d05763          	blez	a3,80004810 <write_head+0x5a>
    800047e6:	0001d797          	auipc	a5,0x1d
    800047ea:	63a78793          	addi	a5,a5,1594 # 80021e20 <log+0x30>
    800047ee:	05c50713          	addi	a4,a0,92
    800047f2:	36fd                	addiw	a3,a3,-1
    800047f4:	1682                	slli	a3,a3,0x20
    800047f6:	9281                	srli	a3,a3,0x20
    800047f8:	068a                	slli	a3,a3,0x2
    800047fa:	0001d617          	auipc	a2,0x1d
    800047fe:	62a60613          	addi	a2,a2,1578 # 80021e24 <log+0x34>
    80004802:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004804:	4390                	lw	a2,0(a5)
    80004806:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004808:	0791                	addi	a5,a5,4
    8000480a:	0711                	addi	a4,a4,4
    8000480c:	fed79ce3          	bne	a5,a3,80004804 <write_head+0x4e>
  }
  bwrite(buf);
    80004810:	8526                	mv	a0,s1
    80004812:	fffff097          	auipc	ra,0xfffff
    80004816:	0a4080e7          	jalr	164(ra) # 800038b6 <bwrite>
  brelse(buf);
    8000481a:	8526                	mv	a0,s1
    8000481c:	fffff097          	auipc	ra,0xfffff
    80004820:	0d8080e7          	jalr	216(ra) # 800038f4 <brelse>
}
    80004824:	60e2                	ld	ra,24(sp)
    80004826:	6442                	ld	s0,16(sp)
    80004828:	64a2                	ld	s1,8(sp)
    8000482a:	6902                	ld	s2,0(sp)
    8000482c:	6105                	addi	sp,sp,32
    8000482e:	8082                	ret

0000000080004830 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004830:	0001d797          	auipc	a5,0x1d
    80004834:	5ec7a783          	lw	a5,1516(a5) # 80021e1c <log+0x2c>
    80004838:	0af05d63          	blez	a5,800048f2 <install_trans+0xc2>
{
    8000483c:	7139                	addi	sp,sp,-64
    8000483e:	fc06                	sd	ra,56(sp)
    80004840:	f822                	sd	s0,48(sp)
    80004842:	f426                	sd	s1,40(sp)
    80004844:	f04a                	sd	s2,32(sp)
    80004846:	ec4e                	sd	s3,24(sp)
    80004848:	e852                	sd	s4,16(sp)
    8000484a:	e456                	sd	s5,8(sp)
    8000484c:	e05a                	sd	s6,0(sp)
    8000484e:	0080                	addi	s0,sp,64
    80004850:	8b2a                	mv	s6,a0
    80004852:	0001da97          	auipc	s5,0x1d
    80004856:	5cea8a93          	addi	s5,s5,1486 # 80021e20 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000485a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000485c:	0001d997          	auipc	s3,0x1d
    80004860:	59498993          	addi	s3,s3,1428 # 80021df0 <log>
    80004864:	a035                	j	80004890 <install_trans+0x60>
      bunpin(dbuf);
    80004866:	8526                	mv	a0,s1
    80004868:	fffff097          	auipc	ra,0xfffff
    8000486c:	166080e7          	jalr	358(ra) # 800039ce <bunpin>
    brelse(lbuf);
    80004870:	854a                	mv	a0,s2
    80004872:	fffff097          	auipc	ra,0xfffff
    80004876:	082080e7          	jalr	130(ra) # 800038f4 <brelse>
    brelse(dbuf);
    8000487a:	8526                	mv	a0,s1
    8000487c:	fffff097          	auipc	ra,0xfffff
    80004880:	078080e7          	jalr	120(ra) # 800038f4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004884:	2a05                	addiw	s4,s4,1
    80004886:	0a91                	addi	s5,s5,4
    80004888:	02c9a783          	lw	a5,44(s3)
    8000488c:	04fa5963          	bge	s4,a5,800048de <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004890:	0189a583          	lw	a1,24(s3)
    80004894:	014585bb          	addw	a1,a1,s4
    80004898:	2585                	addiw	a1,a1,1
    8000489a:	0289a503          	lw	a0,40(s3)
    8000489e:	fffff097          	auipc	ra,0xfffff
    800048a2:	f26080e7          	jalr	-218(ra) # 800037c4 <bread>
    800048a6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800048a8:	000aa583          	lw	a1,0(s5)
    800048ac:	0289a503          	lw	a0,40(s3)
    800048b0:	fffff097          	auipc	ra,0xfffff
    800048b4:	f14080e7          	jalr	-236(ra) # 800037c4 <bread>
    800048b8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800048ba:	40000613          	li	a2,1024
    800048be:	05890593          	addi	a1,s2,88
    800048c2:	05850513          	addi	a0,a0,88
    800048c6:	ffffc097          	auipc	ra,0xffffc
    800048ca:	47a080e7          	jalr	1146(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800048ce:	8526                	mv	a0,s1
    800048d0:	fffff097          	auipc	ra,0xfffff
    800048d4:	fe6080e7          	jalr	-26(ra) # 800038b6 <bwrite>
    if(recovering == 0)
    800048d8:	f80b1ce3          	bnez	s6,80004870 <install_trans+0x40>
    800048dc:	b769                	j	80004866 <install_trans+0x36>
}
    800048de:	70e2                	ld	ra,56(sp)
    800048e0:	7442                	ld	s0,48(sp)
    800048e2:	74a2                	ld	s1,40(sp)
    800048e4:	7902                	ld	s2,32(sp)
    800048e6:	69e2                	ld	s3,24(sp)
    800048e8:	6a42                	ld	s4,16(sp)
    800048ea:	6aa2                	ld	s5,8(sp)
    800048ec:	6b02                	ld	s6,0(sp)
    800048ee:	6121                	addi	sp,sp,64
    800048f0:	8082                	ret
    800048f2:	8082                	ret

00000000800048f4 <initlog>:
{
    800048f4:	7179                	addi	sp,sp,-48
    800048f6:	f406                	sd	ra,40(sp)
    800048f8:	f022                	sd	s0,32(sp)
    800048fa:	ec26                	sd	s1,24(sp)
    800048fc:	e84a                	sd	s2,16(sp)
    800048fe:	e44e                	sd	s3,8(sp)
    80004900:	1800                	addi	s0,sp,48
    80004902:	892a                	mv	s2,a0
    80004904:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004906:	0001d497          	auipc	s1,0x1d
    8000490a:	4ea48493          	addi	s1,s1,1258 # 80021df0 <log>
    8000490e:	00004597          	auipc	a1,0x4
    80004912:	00a58593          	addi	a1,a1,10 # 80008918 <syscalls+0x1f0>
    80004916:	8526                	mv	a0,s1
    80004918:	ffffc097          	auipc	ra,0xffffc
    8000491c:	23c080e7          	jalr	572(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004920:	0149a583          	lw	a1,20(s3)
    80004924:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004926:	0109a783          	lw	a5,16(s3)
    8000492a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000492c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004930:	854a                	mv	a0,s2
    80004932:	fffff097          	auipc	ra,0xfffff
    80004936:	e92080e7          	jalr	-366(ra) # 800037c4 <bread>
  log.lh.n = lh->n;
    8000493a:	4d3c                	lw	a5,88(a0)
    8000493c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000493e:	02f05563          	blez	a5,80004968 <initlog+0x74>
    80004942:	05c50713          	addi	a4,a0,92
    80004946:	0001d697          	auipc	a3,0x1d
    8000494a:	4da68693          	addi	a3,a3,1242 # 80021e20 <log+0x30>
    8000494e:	37fd                	addiw	a5,a5,-1
    80004950:	1782                	slli	a5,a5,0x20
    80004952:	9381                	srli	a5,a5,0x20
    80004954:	078a                	slli	a5,a5,0x2
    80004956:	06050613          	addi	a2,a0,96
    8000495a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000495c:	4310                	lw	a2,0(a4)
    8000495e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004960:	0711                	addi	a4,a4,4
    80004962:	0691                	addi	a3,a3,4
    80004964:	fef71ce3          	bne	a4,a5,8000495c <initlog+0x68>
  brelse(buf);
    80004968:	fffff097          	auipc	ra,0xfffff
    8000496c:	f8c080e7          	jalr	-116(ra) # 800038f4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004970:	4505                	li	a0,1
    80004972:	00000097          	auipc	ra,0x0
    80004976:	ebe080e7          	jalr	-322(ra) # 80004830 <install_trans>
  log.lh.n = 0;
    8000497a:	0001d797          	auipc	a5,0x1d
    8000497e:	4a07a123          	sw	zero,1186(a5) # 80021e1c <log+0x2c>
  write_head(); // clear the log
    80004982:	00000097          	auipc	ra,0x0
    80004986:	e34080e7          	jalr	-460(ra) # 800047b6 <write_head>
}
    8000498a:	70a2                	ld	ra,40(sp)
    8000498c:	7402                	ld	s0,32(sp)
    8000498e:	64e2                	ld	s1,24(sp)
    80004990:	6942                	ld	s2,16(sp)
    80004992:	69a2                	ld	s3,8(sp)
    80004994:	6145                	addi	sp,sp,48
    80004996:	8082                	ret

0000000080004998 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004998:	1101                	addi	sp,sp,-32
    8000499a:	ec06                	sd	ra,24(sp)
    8000499c:	e822                	sd	s0,16(sp)
    8000499e:	e426                	sd	s1,8(sp)
    800049a0:	e04a                	sd	s2,0(sp)
    800049a2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800049a4:	0001d517          	auipc	a0,0x1d
    800049a8:	44c50513          	addi	a0,a0,1100 # 80021df0 <log>
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	238080e7          	jalr	568(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800049b4:	0001d497          	auipc	s1,0x1d
    800049b8:	43c48493          	addi	s1,s1,1084 # 80021df0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800049bc:	4979                	li	s2,30
    800049be:	a039                	j	800049cc <begin_op+0x34>
      sleep(&log, &log.lock);
    800049c0:	85a6                	mv	a1,s1
    800049c2:	8526                	mv	a0,s1
    800049c4:	ffffe097          	auipc	ra,0xffffe
    800049c8:	c6e080e7          	jalr	-914(ra) # 80002632 <sleep>
    if(log.committing){
    800049cc:	50dc                	lw	a5,36(s1)
    800049ce:	fbed                	bnez	a5,800049c0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800049d0:	509c                	lw	a5,32(s1)
    800049d2:	0017871b          	addiw	a4,a5,1
    800049d6:	0007069b          	sext.w	a3,a4
    800049da:	0027179b          	slliw	a5,a4,0x2
    800049de:	9fb9                	addw	a5,a5,a4
    800049e0:	0017979b          	slliw	a5,a5,0x1
    800049e4:	54d8                	lw	a4,44(s1)
    800049e6:	9fb9                	addw	a5,a5,a4
    800049e8:	00f95963          	bge	s2,a5,800049fa <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800049ec:	85a6                	mv	a1,s1
    800049ee:	8526                	mv	a0,s1
    800049f0:	ffffe097          	auipc	ra,0xffffe
    800049f4:	c42080e7          	jalr	-958(ra) # 80002632 <sleep>
    800049f8:	bfd1                	j	800049cc <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800049fa:	0001d517          	auipc	a0,0x1d
    800049fe:	3f650513          	addi	a0,a0,1014 # 80021df0 <log>
    80004a02:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004a04:	ffffc097          	auipc	ra,0xffffc
    80004a08:	294080e7          	jalr	660(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004a0c:	60e2                	ld	ra,24(sp)
    80004a0e:	6442                	ld	s0,16(sp)
    80004a10:	64a2                	ld	s1,8(sp)
    80004a12:	6902                	ld	s2,0(sp)
    80004a14:	6105                	addi	sp,sp,32
    80004a16:	8082                	ret

0000000080004a18 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004a18:	7139                	addi	sp,sp,-64
    80004a1a:	fc06                	sd	ra,56(sp)
    80004a1c:	f822                	sd	s0,48(sp)
    80004a1e:	f426                	sd	s1,40(sp)
    80004a20:	f04a                	sd	s2,32(sp)
    80004a22:	ec4e                	sd	s3,24(sp)
    80004a24:	e852                	sd	s4,16(sp)
    80004a26:	e456                	sd	s5,8(sp)
    80004a28:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004a2a:	0001d497          	auipc	s1,0x1d
    80004a2e:	3c648493          	addi	s1,s1,966 # 80021df0 <log>
    80004a32:	8526                	mv	a0,s1
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	1b0080e7          	jalr	432(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004a3c:	509c                	lw	a5,32(s1)
    80004a3e:	37fd                	addiw	a5,a5,-1
    80004a40:	0007891b          	sext.w	s2,a5
    80004a44:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004a46:	50dc                	lw	a5,36(s1)
    80004a48:	efb9                	bnez	a5,80004aa6 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004a4a:	06091663          	bnez	s2,80004ab6 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004a4e:	0001d497          	auipc	s1,0x1d
    80004a52:	3a248493          	addi	s1,s1,930 # 80021df0 <log>
    80004a56:	4785                	li	a5,1
    80004a58:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004a5a:	8526                	mv	a0,s1
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	23c080e7          	jalr	572(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004a64:	54dc                	lw	a5,44(s1)
    80004a66:	06f04763          	bgtz	a5,80004ad4 <end_op+0xbc>
    acquire(&log.lock);
    80004a6a:	0001d497          	auipc	s1,0x1d
    80004a6e:	38648493          	addi	s1,s1,902 # 80021df0 <log>
    80004a72:	8526                	mv	a0,s1
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	170080e7          	jalr	368(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004a7c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004a80:	8526                	mv	a0,s1
    80004a82:	ffffe097          	auipc	ra,0xffffe
    80004a86:	1c6080e7          	jalr	454(ra) # 80002c48 <wakeup>
    release(&log.lock);
    80004a8a:	8526                	mv	a0,s1
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	20c080e7          	jalr	524(ra) # 80000c98 <release>
}
    80004a94:	70e2                	ld	ra,56(sp)
    80004a96:	7442                	ld	s0,48(sp)
    80004a98:	74a2                	ld	s1,40(sp)
    80004a9a:	7902                	ld	s2,32(sp)
    80004a9c:	69e2                	ld	s3,24(sp)
    80004a9e:	6a42                	ld	s4,16(sp)
    80004aa0:	6aa2                	ld	s5,8(sp)
    80004aa2:	6121                	addi	sp,sp,64
    80004aa4:	8082                	ret
    panic("log.committing");
    80004aa6:	00004517          	auipc	a0,0x4
    80004aaa:	e7a50513          	addi	a0,a0,-390 # 80008920 <syscalls+0x1f8>
    80004aae:	ffffc097          	auipc	ra,0xffffc
    80004ab2:	a90080e7          	jalr	-1392(ra) # 8000053e <panic>
    wakeup(&log);
    80004ab6:	0001d497          	auipc	s1,0x1d
    80004aba:	33a48493          	addi	s1,s1,826 # 80021df0 <log>
    80004abe:	8526                	mv	a0,s1
    80004ac0:	ffffe097          	auipc	ra,0xffffe
    80004ac4:	188080e7          	jalr	392(ra) # 80002c48 <wakeup>
  release(&log.lock);
    80004ac8:	8526                	mv	a0,s1
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	1ce080e7          	jalr	462(ra) # 80000c98 <release>
  if(do_commit){
    80004ad2:	b7c9                	j	80004a94 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ad4:	0001da97          	auipc	s5,0x1d
    80004ad8:	34ca8a93          	addi	s5,s5,844 # 80021e20 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004adc:	0001da17          	auipc	s4,0x1d
    80004ae0:	314a0a13          	addi	s4,s4,788 # 80021df0 <log>
    80004ae4:	018a2583          	lw	a1,24(s4)
    80004ae8:	012585bb          	addw	a1,a1,s2
    80004aec:	2585                	addiw	a1,a1,1
    80004aee:	028a2503          	lw	a0,40(s4)
    80004af2:	fffff097          	auipc	ra,0xfffff
    80004af6:	cd2080e7          	jalr	-814(ra) # 800037c4 <bread>
    80004afa:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004afc:	000aa583          	lw	a1,0(s5)
    80004b00:	028a2503          	lw	a0,40(s4)
    80004b04:	fffff097          	auipc	ra,0xfffff
    80004b08:	cc0080e7          	jalr	-832(ra) # 800037c4 <bread>
    80004b0c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004b0e:	40000613          	li	a2,1024
    80004b12:	05850593          	addi	a1,a0,88
    80004b16:	05848513          	addi	a0,s1,88
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	226080e7          	jalr	550(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004b22:	8526                	mv	a0,s1
    80004b24:	fffff097          	auipc	ra,0xfffff
    80004b28:	d92080e7          	jalr	-622(ra) # 800038b6 <bwrite>
    brelse(from);
    80004b2c:	854e                	mv	a0,s3
    80004b2e:	fffff097          	auipc	ra,0xfffff
    80004b32:	dc6080e7          	jalr	-570(ra) # 800038f4 <brelse>
    brelse(to);
    80004b36:	8526                	mv	a0,s1
    80004b38:	fffff097          	auipc	ra,0xfffff
    80004b3c:	dbc080e7          	jalr	-580(ra) # 800038f4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b40:	2905                	addiw	s2,s2,1
    80004b42:	0a91                	addi	s5,s5,4
    80004b44:	02ca2783          	lw	a5,44(s4)
    80004b48:	f8f94ee3          	blt	s2,a5,80004ae4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004b4c:	00000097          	auipc	ra,0x0
    80004b50:	c6a080e7          	jalr	-918(ra) # 800047b6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004b54:	4501                	li	a0,0
    80004b56:	00000097          	auipc	ra,0x0
    80004b5a:	cda080e7          	jalr	-806(ra) # 80004830 <install_trans>
    log.lh.n = 0;
    80004b5e:	0001d797          	auipc	a5,0x1d
    80004b62:	2a07af23          	sw	zero,702(a5) # 80021e1c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004b66:	00000097          	auipc	ra,0x0
    80004b6a:	c50080e7          	jalr	-944(ra) # 800047b6 <write_head>
    80004b6e:	bdf5                	j	80004a6a <end_op+0x52>

0000000080004b70 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004b70:	1101                	addi	sp,sp,-32
    80004b72:	ec06                	sd	ra,24(sp)
    80004b74:	e822                	sd	s0,16(sp)
    80004b76:	e426                	sd	s1,8(sp)
    80004b78:	e04a                	sd	s2,0(sp)
    80004b7a:	1000                	addi	s0,sp,32
    80004b7c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004b7e:	0001d917          	auipc	s2,0x1d
    80004b82:	27290913          	addi	s2,s2,626 # 80021df0 <log>
    80004b86:	854a                	mv	a0,s2
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	05c080e7          	jalr	92(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004b90:	02c92603          	lw	a2,44(s2)
    80004b94:	47f5                	li	a5,29
    80004b96:	06c7c563          	blt	a5,a2,80004c00 <log_write+0x90>
    80004b9a:	0001d797          	auipc	a5,0x1d
    80004b9e:	2727a783          	lw	a5,626(a5) # 80021e0c <log+0x1c>
    80004ba2:	37fd                	addiw	a5,a5,-1
    80004ba4:	04f65e63          	bge	a2,a5,80004c00 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004ba8:	0001d797          	auipc	a5,0x1d
    80004bac:	2687a783          	lw	a5,616(a5) # 80021e10 <log+0x20>
    80004bb0:	06f05063          	blez	a5,80004c10 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004bb4:	4781                	li	a5,0
    80004bb6:	06c05563          	blez	a2,80004c20 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004bba:	44cc                	lw	a1,12(s1)
    80004bbc:	0001d717          	auipc	a4,0x1d
    80004bc0:	26470713          	addi	a4,a4,612 # 80021e20 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004bc4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004bc6:	4314                	lw	a3,0(a4)
    80004bc8:	04b68c63          	beq	a3,a1,80004c20 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004bcc:	2785                	addiw	a5,a5,1
    80004bce:	0711                	addi	a4,a4,4
    80004bd0:	fef61be3          	bne	a2,a5,80004bc6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004bd4:	0621                	addi	a2,a2,8
    80004bd6:	060a                	slli	a2,a2,0x2
    80004bd8:	0001d797          	auipc	a5,0x1d
    80004bdc:	21878793          	addi	a5,a5,536 # 80021df0 <log>
    80004be0:	963e                	add	a2,a2,a5
    80004be2:	44dc                	lw	a5,12(s1)
    80004be4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004be6:	8526                	mv	a0,s1
    80004be8:	fffff097          	auipc	ra,0xfffff
    80004bec:	daa080e7          	jalr	-598(ra) # 80003992 <bpin>
    log.lh.n++;
    80004bf0:	0001d717          	auipc	a4,0x1d
    80004bf4:	20070713          	addi	a4,a4,512 # 80021df0 <log>
    80004bf8:	575c                	lw	a5,44(a4)
    80004bfa:	2785                	addiw	a5,a5,1
    80004bfc:	d75c                	sw	a5,44(a4)
    80004bfe:	a835                	j	80004c3a <log_write+0xca>
    panic("too big a transaction");
    80004c00:	00004517          	auipc	a0,0x4
    80004c04:	d3050513          	addi	a0,a0,-720 # 80008930 <syscalls+0x208>
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	936080e7          	jalr	-1738(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004c10:	00004517          	auipc	a0,0x4
    80004c14:	d3850513          	addi	a0,a0,-712 # 80008948 <syscalls+0x220>
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	926080e7          	jalr	-1754(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004c20:	00878713          	addi	a4,a5,8
    80004c24:	00271693          	slli	a3,a4,0x2
    80004c28:	0001d717          	auipc	a4,0x1d
    80004c2c:	1c870713          	addi	a4,a4,456 # 80021df0 <log>
    80004c30:	9736                	add	a4,a4,a3
    80004c32:	44d4                	lw	a3,12(s1)
    80004c34:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004c36:	faf608e3          	beq	a2,a5,80004be6 <log_write+0x76>
  }
  release(&log.lock);
    80004c3a:	0001d517          	auipc	a0,0x1d
    80004c3e:	1b650513          	addi	a0,a0,438 # 80021df0 <log>
    80004c42:	ffffc097          	auipc	ra,0xffffc
    80004c46:	056080e7          	jalr	86(ra) # 80000c98 <release>
}
    80004c4a:	60e2                	ld	ra,24(sp)
    80004c4c:	6442                	ld	s0,16(sp)
    80004c4e:	64a2                	ld	s1,8(sp)
    80004c50:	6902                	ld	s2,0(sp)
    80004c52:	6105                	addi	sp,sp,32
    80004c54:	8082                	ret

0000000080004c56 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004c56:	1101                	addi	sp,sp,-32
    80004c58:	ec06                	sd	ra,24(sp)
    80004c5a:	e822                	sd	s0,16(sp)
    80004c5c:	e426                	sd	s1,8(sp)
    80004c5e:	e04a                	sd	s2,0(sp)
    80004c60:	1000                	addi	s0,sp,32
    80004c62:	84aa                	mv	s1,a0
    80004c64:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004c66:	00004597          	auipc	a1,0x4
    80004c6a:	d0258593          	addi	a1,a1,-766 # 80008968 <syscalls+0x240>
    80004c6e:	0521                	addi	a0,a0,8
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	ee4080e7          	jalr	-284(ra) # 80000b54 <initlock>
  lk->name = name;
    80004c78:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004c7c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c80:	0204a423          	sw	zero,40(s1)
}
    80004c84:	60e2                	ld	ra,24(sp)
    80004c86:	6442                	ld	s0,16(sp)
    80004c88:	64a2                	ld	s1,8(sp)
    80004c8a:	6902                	ld	s2,0(sp)
    80004c8c:	6105                	addi	sp,sp,32
    80004c8e:	8082                	ret

0000000080004c90 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004c90:	1101                	addi	sp,sp,-32
    80004c92:	ec06                	sd	ra,24(sp)
    80004c94:	e822                	sd	s0,16(sp)
    80004c96:	e426                	sd	s1,8(sp)
    80004c98:	e04a                	sd	s2,0(sp)
    80004c9a:	1000                	addi	s0,sp,32
    80004c9c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c9e:	00850913          	addi	s2,a0,8
    80004ca2:	854a                	mv	a0,s2
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	f40080e7          	jalr	-192(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004cac:	409c                	lw	a5,0(s1)
    80004cae:	cb89                	beqz	a5,80004cc0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004cb0:	85ca                	mv	a1,s2
    80004cb2:	8526                	mv	a0,s1
    80004cb4:	ffffe097          	auipc	ra,0xffffe
    80004cb8:	97e080e7          	jalr	-1666(ra) # 80002632 <sleep>
  while (lk->locked) {
    80004cbc:	409c                	lw	a5,0(s1)
    80004cbe:	fbed                	bnez	a5,80004cb0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004cc0:	4785                	li	a5,1
    80004cc2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004cc4:	ffffd097          	auipc	ra,0xffffd
    80004cc8:	200080e7          	jalr	512(ra) # 80001ec4 <myproc>
    80004ccc:	591c                	lw	a5,48(a0)
    80004cce:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004cd0:	854a                	mv	a0,s2
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	fc6080e7          	jalr	-58(ra) # 80000c98 <release>
}
    80004cda:	60e2                	ld	ra,24(sp)
    80004cdc:	6442                	ld	s0,16(sp)
    80004cde:	64a2                	ld	s1,8(sp)
    80004ce0:	6902                	ld	s2,0(sp)
    80004ce2:	6105                	addi	sp,sp,32
    80004ce4:	8082                	ret

0000000080004ce6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004ce6:	1101                	addi	sp,sp,-32
    80004ce8:	ec06                	sd	ra,24(sp)
    80004cea:	e822                	sd	s0,16(sp)
    80004cec:	e426                	sd	s1,8(sp)
    80004cee:	e04a                	sd	s2,0(sp)
    80004cf0:	1000                	addi	s0,sp,32
    80004cf2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004cf4:	00850913          	addi	s2,a0,8
    80004cf8:	854a                	mv	a0,s2
    80004cfa:	ffffc097          	auipc	ra,0xffffc
    80004cfe:	eea080e7          	jalr	-278(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004d02:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d06:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004d0a:	8526                	mv	a0,s1
    80004d0c:	ffffe097          	auipc	ra,0xffffe
    80004d10:	f3c080e7          	jalr	-196(ra) # 80002c48 <wakeup>
  release(&lk->lk);
    80004d14:	854a                	mv	a0,s2
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	f82080e7          	jalr	-126(ra) # 80000c98 <release>
}
    80004d1e:	60e2                	ld	ra,24(sp)
    80004d20:	6442                	ld	s0,16(sp)
    80004d22:	64a2                	ld	s1,8(sp)
    80004d24:	6902                	ld	s2,0(sp)
    80004d26:	6105                	addi	sp,sp,32
    80004d28:	8082                	ret

0000000080004d2a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004d2a:	7179                	addi	sp,sp,-48
    80004d2c:	f406                	sd	ra,40(sp)
    80004d2e:	f022                	sd	s0,32(sp)
    80004d30:	ec26                	sd	s1,24(sp)
    80004d32:	e84a                	sd	s2,16(sp)
    80004d34:	e44e                	sd	s3,8(sp)
    80004d36:	1800                	addi	s0,sp,48
    80004d38:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004d3a:	00850913          	addi	s2,a0,8
    80004d3e:	854a                	mv	a0,s2
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	ea4080e7          	jalr	-348(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d48:	409c                	lw	a5,0(s1)
    80004d4a:	ef99                	bnez	a5,80004d68 <holdingsleep+0x3e>
    80004d4c:	4481                	li	s1,0
  release(&lk->lk);
    80004d4e:	854a                	mv	a0,s2
    80004d50:	ffffc097          	auipc	ra,0xffffc
    80004d54:	f48080e7          	jalr	-184(ra) # 80000c98 <release>
  return r;
}
    80004d58:	8526                	mv	a0,s1
    80004d5a:	70a2                	ld	ra,40(sp)
    80004d5c:	7402                	ld	s0,32(sp)
    80004d5e:	64e2                	ld	s1,24(sp)
    80004d60:	6942                	ld	s2,16(sp)
    80004d62:	69a2                	ld	s3,8(sp)
    80004d64:	6145                	addi	sp,sp,48
    80004d66:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d68:	0284a983          	lw	s3,40(s1)
    80004d6c:	ffffd097          	auipc	ra,0xffffd
    80004d70:	158080e7          	jalr	344(ra) # 80001ec4 <myproc>
    80004d74:	5904                	lw	s1,48(a0)
    80004d76:	413484b3          	sub	s1,s1,s3
    80004d7a:	0014b493          	seqz	s1,s1
    80004d7e:	bfc1                	j	80004d4e <holdingsleep+0x24>

0000000080004d80 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004d80:	1141                	addi	sp,sp,-16
    80004d82:	e406                	sd	ra,8(sp)
    80004d84:	e022                	sd	s0,0(sp)
    80004d86:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004d88:	00004597          	auipc	a1,0x4
    80004d8c:	bf058593          	addi	a1,a1,-1040 # 80008978 <syscalls+0x250>
    80004d90:	0001d517          	auipc	a0,0x1d
    80004d94:	1a850513          	addi	a0,a0,424 # 80021f38 <ftable>
    80004d98:	ffffc097          	auipc	ra,0xffffc
    80004d9c:	dbc080e7          	jalr	-580(ra) # 80000b54 <initlock>
}
    80004da0:	60a2                	ld	ra,8(sp)
    80004da2:	6402                	ld	s0,0(sp)
    80004da4:	0141                	addi	sp,sp,16
    80004da6:	8082                	ret

0000000080004da8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004da8:	1101                	addi	sp,sp,-32
    80004daa:	ec06                	sd	ra,24(sp)
    80004dac:	e822                	sd	s0,16(sp)
    80004dae:	e426                	sd	s1,8(sp)
    80004db0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004db2:	0001d517          	auipc	a0,0x1d
    80004db6:	18650513          	addi	a0,a0,390 # 80021f38 <ftable>
    80004dba:	ffffc097          	auipc	ra,0xffffc
    80004dbe:	e2a080e7          	jalr	-470(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004dc2:	0001d497          	auipc	s1,0x1d
    80004dc6:	18e48493          	addi	s1,s1,398 # 80021f50 <ftable+0x18>
    80004dca:	0001e717          	auipc	a4,0x1e
    80004dce:	12670713          	addi	a4,a4,294 # 80022ef0 <ftable+0xfb8>
    if(f->ref == 0){
    80004dd2:	40dc                	lw	a5,4(s1)
    80004dd4:	cf99                	beqz	a5,80004df2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004dd6:	02848493          	addi	s1,s1,40
    80004dda:	fee49ce3          	bne	s1,a4,80004dd2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004dde:	0001d517          	auipc	a0,0x1d
    80004de2:	15a50513          	addi	a0,a0,346 # 80021f38 <ftable>
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	eb2080e7          	jalr	-334(ra) # 80000c98 <release>
  return 0;
    80004dee:	4481                	li	s1,0
    80004df0:	a819                	j	80004e06 <filealloc+0x5e>
      f->ref = 1;
    80004df2:	4785                	li	a5,1
    80004df4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004df6:	0001d517          	auipc	a0,0x1d
    80004dfa:	14250513          	addi	a0,a0,322 # 80021f38 <ftable>
    80004dfe:	ffffc097          	auipc	ra,0xffffc
    80004e02:	e9a080e7          	jalr	-358(ra) # 80000c98 <release>
}
    80004e06:	8526                	mv	a0,s1
    80004e08:	60e2                	ld	ra,24(sp)
    80004e0a:	6442                	ld	s0,16(sp)
    80004e0c:	64a2                	ld	s1,8(sp)
    80004e0e:	6105                	addi	sp,sp,32
    80004e10:	8082                	ret

0000000080004e12 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004e12:	1101                	addi	sp,sp,-32
    80004e14:	ec06                	sd	ra,24(sp)
    80004e16:	e822                	sd	s0,16(sp)
    80004e18:	e426                	sd	s1,8(sp)
    80004e1a:	1000                	addi	s0,sp,32
    80004e1c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004e1e:	0001d517          	auipc	a0,0x1d
    80004e22:	11a50513          	addi	a0,a0,282 # 80021f38 <ftable>
    80004e26:	ffffc097          	auipc	ra,0xffffc
    80004e2a:	dbe080e7          	jalr	-578(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004e2e:	40dc                	lw	a5,4(s1)
    80004e30:	02f05263          	blez	a5,80004e54 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004e34:	2785                	addiw	a5,a5,1
    80004e36:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004e38:	0001d517          	auipc	a0,0x1d
    80004e3c:	10050513          	addi	a0,a0,256 # 80021f38 <ftable>
    80004e40:	ffffc097          	auipc	ra,0xffffc
    80004e44:	e58080e7          	jalr	-424(ra) # 80000c98 <release>
  return f;
}
    80004e48:	8526                	mv	a0,s1
    80004e4a:	60e2                	ld	ra,24(sp)
    80004e4c:	6442                	ld	s0,16(sp)
    80004e4e:	64a2                	ld	s1,8(sp)
    80004e50:	6105                	addi	sp,sp,32
    80004e52:	8082                	ret
    panic("filedup");
    80004e54:	00004517          	auipc	a0,0x4
    80004e58:	b2c50513          	addi	a0,a0,-1236 # 80008980 <syscalls+0x258>
    80004e5c:	ffffb097          	auipc	ra,0xffffb
    80004e60:	6e2080e7          	jalr	1762(ra) # 8000053e <panic>

0000000080004e64 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004e64:	7139                	addi	sp,sp,-64
    80004e66:	fc06                	sd	ra,56(sp)
    80004e68:	f822                	sd	s0,48(sp)
    80004e6a:	f426                	sd	s1,40(sp)
    80004e6c:	f04a                	sd	s2,32(sp)
    80004e6e:	ec4e                	sd	s3,24(sp)
    80004e70:	e852                	sd	s4,16(sp)
    80004e72:	e456                	sd	s5,8(sp)
    80004e74:	0080                	addi	s0,sp,64
    80004e76:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004e78:	0001d517          	auipc	a0,0x1d
    80004e7c:	0c050513          	addi	a0,a0,192 # 80021f38 <ftable>
    80004e80:	ffffc097          	auipc	ra,0xffffc
    80004e84:	d64080e7          	jalr	-668(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004e88:	40dc                	lw	a5,4(s1)
    80004e8a:	06f05163          	blez	a5,80004eec <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004e8e:	37fd                	addiw	a5,a5,-1
    80004e90:	0007871b          	sext.w	a4,a5
    80004e94:	c0dc                	sw	a5,4(s1)
    80004e96:	06e04363          	bgtz	a4,80004efc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004e9a:	0004a903          	lw	s2,0(s1)
    80004e9e:	0094ca83          	lbu	s5,9(s1)
    80004ea2:	0104ba03          	ld	s4,16(s1)
    80004ea6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004eaa:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004eae:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004eb2:	0001d517          	auipc	a0,0x1d
    80004eb6:	08650513          	addi	a0,a0,134 # 80021f38 <ftable>
    80004eba:	ffffc097          	auipc	ra,0xffffc
    80004ebe:	dde080e7          	jalr	-546(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004ec2:	4785                	li	a5,1
    80004ec4:	04f90d63          	beq	s2,a5,80004f1e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ec8:	3979                	addiw	s2,s2,-2
    80004eca:	4785                	li	a5,1
    80004ecc:	0527e063          	bltu	a5,s2,80004f0c <fileclose+0xa8>
    begin_op();
    80004ed0:	00000097          	auipc	ra,0x0
    80004ed4:	ac8080e7          	jalr	-1336(ra) # 80004998 <begin_op>
    iput(ff.ip);
    80004ed8:	854e                	mv	a0,s3
    80004eda:	fffff097          	auipc	ra,0xfffff
    80004ede:	2a6080e7          	jalr	678(ra) # 80004180 <iput>
    end_op();
    80004ee2:	00000097          	auipc	ra,0x0
    80004ee6:	b36080e7          	jalr	-1226(ra) # 80004a18 <end_op>
    80004eea:	a00d                	j	80004f0c <fileclose+0xa8>
    panic("fileclose");
    80004eec:	00004517          	auipc	a0,0x4
    80004ef0:	a9c50513          	addi	a0,a0,-1380 # 80008988 <syscalls+0x260>
    80004ef4:	ffffb097          	auipc	ra,0xffffb
    80004ef8:	64a080e7          	jalr	1610(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004efc:	0001d517          	auipc	a0,0x1d
    80004f00:	03c50513          	addi	a0,a0,60 # 80021f38 <ftable>
    80004f04:	ffffc097          	auipc	ra,0xffffc
    80004f08:	d94080e7          	jalr	-620(ra) # 80000c98 <release>
  }
}
    80004f0c:	70e2                	ld	ra,56(sp)
    80004f0e:	7442                	ld	s0,48(sp)
    80004f10:	74a2                	ld	s1,40(sp)
    80004f12:	7902                	ld	s2,32(sp)
    80004f14:	69e2                	ld	s3,24(sp)
    80004f16:	6a42                	ld	s4,16(sp)
    80004f18:	6aa2                	ld	s5,8(sp)
    80004f1a:	6121                	addi	sp,sp,64
    80004f1c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004f1e:	85d6                	mv	a1,s5
    80004f20:	8552                	mv	a0,s4
    80004f22:	00000097          	auipc	ra,0x0
    80004f26:	34c080e7          	jalr	844(ra) # 8000526e <pipeclose>
    80004f2a:	b7cd                	j	80004f0c <fileclose+0xa8>

0000000080004f2c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004f2c:	715d                	addi	sp,sp,-80
    80004f2e:	e486                	sd	ra,72(sp)
    80004f30:	e0a2                	sd	s0,64(sp)
    80004f32:	fc26                	sd	s1,56(sp)
    80004f34:	f84a                	sd	s2,48(sp)
    80004f36:	f44e                	sd	s3,40(sp)
    80004f38:	0880                	addi	s0,sp,80
    80004f3a:	84aa                	mv	s1,a0
    80004f3c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004f3e:	ffffd097          	auipc	ra,0xffffd
    80004f42:	f86080e7          	jalr	-122(ra) # 80001ec4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004f46:	409c                	lw	a5,0(s1)
    80004f48:	37f9                	addiw	a5,a5,-2
    80004f4a:	4705                	li	a4,1
    80004f4c:	04f76763          	bltu	a4,a5,80004f9a <filestat+0x6e>
    80004f50:	892a                	mv	s2,a0
    ilock(f->ip);
    80004f52:	6c88                	ld	a0,24(s1)
    80004f54:	fffff097          	auipc	ra,0xfffff
    80004f58:	072080e7          	jalr	114(ra) # 80003fc6 <ilock>
    stati(f->ip, &st);
    80004f5c:	fb840593          	addi	a1,s0,-72
    80004f60:	6c88                	ld	a0,24(s1)
    80004f62:	fffff097          	auipc	ra,0xfffff
    80004f66:	2ee080e7          	jalr	750(ra) # 80004250 <stati>
    iunlock(f->ip);
    80004f6a:	6c88                	ld	a0,24(s1)
    80004f6c:	fffff097          	auipc	ra,0xfffff
    80004f70:	11c080e7          	jalr	284(ra) # 80004088 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004f74:	46e1                	li	a3,24
    80004f76:	fb840613          	addi	a2,s0,-72
    80004f7a:	85ce                	mv	a1,s3
    80004f7c:	05093503          	ld	a0,80(s2)
    80004f80:	ffffc097          	auipc	ra,0xffffc
    80004f84:	6f2080e7          	jalr	1778(ra) # 80001672 <copyout>
    80004f88:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004f8c:	60a6                	ld	ra,72(sp)
    80004f8e:	6406                	ld	s0,64(sp)
    80004f90:	74e2                	ld	s1,56(sp)
    80004f92:	7942                	ld	s2,48(sp)
    80004f94:	79a2                	ld	s3,40(sp)
    80004f96:	6161                	addi	sp,sp,80
    80004f98:	8082                	ret
  return -1;
    80004f9a:	557d                	li	a0,-1
    80004f9c:	bfc5                	j	80004f8c <filestat+0x60>

0000000080004f9e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004f9e:	7179                	addi	sp,sp,-48
    80004fa0:	f406                	sd	ra,40(sp)
    80004fa2:	f022                	sd	s0,32(sp)
    80004fa4:	ec26                	sd	s1,24(sp)
    80004fa6:	e84a                	sd	s2,16(sp)
    80004fa8:	e44e                	sd	s3,8(sp)
    80004faa:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004fac:	00854783          	lbu	a5,8(a0)
    80004fb0:	c3d5                	beqz	a5,80005054 <fileread+0xb6>
    80004fb2:	84aa                	mv	s1,a0
    80004fb4:	89ae                	mv	s3,a1
    80004fb6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004fb8:	411c                	lw	a5,0(a0)
    80004fba:	4705                	li	a4,1
    80004fbc:	04e78963          	beq	a5,a4,8000500e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004fc0:	470d                	li	a4,3
    80004fc2:	04e78d63          	beq	a5,a4,8000501c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fc6:	4709                	li	a4,2
    80004fc8:	06e79e63          	bne	a5,a4,80005044 <fileread+0xa6>
    ilock(f->ip);
    80004fcc:	6d08                	ld	a0,24(a0)
    80004fce:	fffff097          	auipc	ra,0xfffff
    80004fd2:	ff8080e7          	jalr	-8(ra) # 80003fc6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004fd6:	874a                	mv	a4,s2
    80004fd8:	5094                	lw	a3,32(s1)
    80004fda:	864e                	mv	a2,s3
    80004fdc:	4585                	li	a1,1
    80004fde:	6c88                	ld	a0,24(s1)
    80004fe0:	fffff097          	auipc	ra,0xfffff
    80004fe4:	29a080e7          	jalr	666(ra) # 8000427a <readi>
    80004fe8:	892a                	mv	s2,a0
    80004fea:	00a05563          	blez	a0,80004ff4 <fileread+0x56>
      f->off += r;
    80004fee:	509c                	lw	a5,32(s1)
    80004ff0:	9fa9                	addw	a5,a5,a0
    80004ff2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ff4:	6c88                	ld	a0,24(s1)
    80004ff6:	fffff097          	auipc	ra,0xfffff
    80004ffa:	092080e7          	jalr	146(ra) # 80004088 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ffe:	854a                	mv	a0,s2
    80005000:	70a2                	ld	ra,40(sp)
    80005002:	7402                	ld	s0,32(sp)
    80005004:	64e2                	ld	s1,24(sp)
    80005006:	6942                	ld	s2,16(sp)
    80005008:	69a2                	ld	s3,8(sp)
    8000500a:	6145                	addi	sp,sp,48
    8000500c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000500e:	6908                	ld	a0,16(a0)
    80005010:	00000097          	auipc	ra,0x0
    80005014:	3c8080e7          	jalr	968(ra) # 800053d8 <piperead>
    80005018:	892a                	mv	s2,a0
    8000501a:	b7d5                	j	80004ffe <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000501c:	02451783          	lh	a5,36(a0)
    80005020:	03079693          	slli	a3,a5,0x30
    80005024:	92c1                	srli	a3,a3,0x30
    80005026:	4725                	li	a4,9
    80005028:	02d76863          	bltu	a4,a3,80005058 <fileread+0xba>
    8000502c:	0792                	slli	a5,a5,0x4
    8000502e:	0001d717          	auipc	a4,0x1d
    80005032:	e6a70713          	addi	a4,a4,-406 # 80021e98 <devsw>
    80005036:	97ba                	add	a5,a5,a4
    80005038:	639c                	ld	a5,0(a5)
    8000503a:	c38d                	beqz	a5,8000505c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000503c:	4505                	li	a0,1
    8000503e:	9782                	jalr	a5
    80005040:	892a                	mv	s2,a0
    80005042:	bf75                	j	80004ffe <fileread+0x60>
    panic("fileread");
    80005044:	00004517          	auipc	a0,0x4
    80005048:	95450513          	addi	a0,a0,-1708 # 80008998 <syscalls+0x270>
    8000504c:	ffffb097          	auipc	ra,0xffffb
    80005050:	4f2080e7          	jalr	1266(ra) # 8000053e <panic>
    return -1;
    80005054:	597d                	li	s2,-1
    80005056:	b765                	j	80004ffe <fileread+0x60>
      return -1;
    80005058:	597d                	li	s2,-1
    8000505a:	b755                	j	80004ffe <fileread+0x60>
    8000505c:	597d                	li	s2,-1
    8000505e:	b745                	j	80004ffe <fileread+0x60>

0000000080005060 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005060:	715d                	addi	sp,sp,-80
    80005062:	e486                	sd	ra,72(sp)
    80005064:	e0a2                	sd	s0,64(sp)
    80005066:	fc26                	sd	s1,56(sp)
    80005068:	f84a                	sd	s2,48(sp)
    8000506a:	f44e                	sd	s3,40(sp)
    8000506c:	f052                	sd	s4,32(sp)
    8000506e:	ec56                	sd	s5,24(sp)
    80005070:	e85a                	sd	s6,16(sp)
    80005072:	e45e                	sd	s7,8(sp)
    80005074:	e062                	sd	s8,0(sp)
    80005076:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005078:	00954783          	lbu	a5,9(a0)
    8000507c:	10078663          	beqz	a5,80005188 <filewrite+0x128>
    80005080:	892a                	mv	s2,a0
    80005082:	8aae                	mv	s5,a1
    80005084:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005086:	411c                	lw	a5,0(a0)
    80005088:	4705                	li	a4,1
    8000508a:	02e78263          	beq	a5,a4,800050ae <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000508e:	470d                	li	a4,3
    80005090:	02e78663          	beq	a5,a4,800050bc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005094:	4709                	li	a4,2
    80005096:	0ee79163          	bne	a5,a4,80005178 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000509a:	0ac05d63          	blez	a2,80005154 <filewrite+0xf4>
    int i = 0;
    8000509e:	4981                	li	s3,0
    800050a0:	6b05                	lui	s6,0x1
    800050a2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800050a6:	6b85                	lui	s7,0x1
    800050a8:	c00b8b9b          	addiw	s7,s7,-1024
    800050ac:	a861                	j	80005144 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800050ae:	6908                	ld	a0,16(a0)
    800050b0:	00000097          	auipc	ra,0x0
    800050b4:	22e080e7          	jalr	558(ra) # 800052de <pipewrite>
    800050b8:	8a2a                	mv	s4,a0
    800050ba:	a045                	j	8000515a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800050bc:	02451783          	lh	a5,36(a0)
    800050c0:	03079693          	slli	a3,a5,0x30
    800050c4:	92c1                	srli	a3,a3,0x30
    800050c6:	4725                	li	a4,9
    800050c8:	0cd76263          	bltu	a4,a3,8000518c <filewrite+0x12c>
    800050cc:	0792                	slli	a5,a5,0x4
    800050ce:	0001d717          	auipc	a4,0x1d
    800050d2:	dca70713          	addi	a4,a4,-566 # 80021e98 <devsw>
    800050d6:	97ba                	add	a5,a5,a4
    800050d8:	679c                	ld	a5,8(a5)
    800050da:	cbdd                	beqz	a5,80005190 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800050dc:	4505                	li	a0,1
    800050de:	9782                	jalr	a5
    800050e0:	8a2a                	mv	s4,a0
    800050e2:	a8a5                	j	8000515a <filewrite+0xfa>
    800050e4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800050e8:	00000097          	auipc	ra,0x0
    800050ec:	8b0080e7          	jalr	-1872(ra) # 80004998 <begin_op>
      ilock(f->ip);
    800050f0:	01893503          	ld	a0,24(s2)
    800050f4:	fffff097          	auipc	ra,0xfffff
    800050f8:	ed2080e7          	jalr	-302(ra) # 80003fc6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800050fc:	8762                	mv	a4,s8
    800050fe:	02092683          	lw	a3,32(s2)
    80005102:	01598633          	add	a2,s3,s5
    80005106:	4585                	li	a1,1
    80005108:	01893503          	ld	a0,24(s2)
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	266080e7          	jalr	614(ra) # 80004372 <writei>
    80005114:	84aa                	mv	s1,a0
    80005116:	00a05763          	blez	a0,80005124 <filewrite+0xc4>
        f->off += r;
    8000511a:	02092783          	lw	a5,32(s2)
    8000511e:	9fa9                	addw	a5,a5,a0
    80005120:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005124:	01893503          	ld	a0,24(s2)
    80005128:	fffff097          	auipc	ra,0xfffff
    8000512c:	f60080e7          	jalr	-160(ra) # 80004088 <iunlock>
      end_op();
    80005130:	00000097          	auipc	ra,0x0
    80005134:	8e8080e7          	jalr	-1816(ra) # 80004a18 <end_op>

      if(r != n1){
    80005138:	009c1f63          	bne	s8,s1,80005156 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000513c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005140:	0149db63          	bge	s3,s4,80005156 <filewrite+0xf6>
      int n1 = n - i;
    80005144:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005148:	84be                	mv	s1,a5
    8000514a:	2781                	sext.w	a5,a5
    8000514c:	f8fb5ce3          	bge	s6,a5,800050e4 <filewrite+0x84>
    80005150:	84de                	mv	s1,s7
    80005152:	bf49                	j	800050e4 <filewrite+0x84>
    int i = 0;
    80005154:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005156:	013a1f63          	bne	s4,s3,80005174 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000515a:	8552                	mv	a0,s4
    8000515c:	60a6                	ld	ra,72(sp)
    8000515e:	6406                	ld	s0,64(sp)
    80005160:	74e2                	ld	s1,56(sp)
    80005162:	7942                	ld	s2,48(sp)
    80005164:	79a2                	ld	s3,40(sp)
    80005166:	7a02                	ld	s4,32(sp)
    80005168:	6ae2                	ld	s5,24(sp)
    8000516a:	6b42                	ld	s6,16(sp)
    8000516c:	6ba2                	ld	s7,8(sp)
    8000516e:	6c02                	ld	s8,0(sp)
    80005170:	6161                	addi	sp,sp,80
    80005172:	8082                	ret
    ret = (i == n ? n : -1);
    80005174:	5a7d                	li	s4,-1
    80005176:	b7d5                	j	8000515a <filewrite+0xfa>
    panic("filewrite");
    80005178:	00004517          	auipc	a0,0x4
    8000517c:	83050513          	addi	a0,a0,-2000 # 800089a8 <syscalls+0x280>
    80005180:	ffffb097          	auipc	ra,0xffffb
    80005184:	3be080e7          	jalr	958(ra) # 8000053e <panic>
    return -1;
    80005188:	5a7d                	li	s4,-1
    8000518a:	bfc1                	j	8000515a <filewrite+0xfa>
      return -1;
    8000518c:	5a7d                	li	s4,-1
    8000518e:	b7f1                	j	8000515a <filewrite+0xfa>
    80005190:	5a7d                	li	s4,-1
    80005192:	b7e1                	j	8000515a <filewrite+0xfa>

0000000080005194 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005194:	7179                	addi	sp,sp,-48
    80005196:	f406                	sd	ra,40(sp)
    80005198:	f022                	sd	s0,32(sp)
    8000519a:	ec26                	sd	s1,24(sp)
    8000519c:	e84a                	sd	s2,16(sp)
    8000519e:	e44e                	sd	s3,8(sp)
    800051a0:	e052                	sd	s4,0(sp)
    800051a2:	1800                	addi	s0,sp,48
    800051a4:	84aa                	mv	s1,a0
    800051a6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800051a8:	0005b023          	sd	zero,0(a1)
    800051ac:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800051b0:	00000097          	auipc	ra,0x0
    800051b4:	bf8080e7          	jalr	-1032(ra) # 80004da8 <filealloc>
    800051b8:	e088                	sd	a0,0(s1)
    800051ba:	c551                	beqz	a0,80005246 <pipealloc+0xb2>
    800051bc:	00000097          	auipc	ra,0x0
    800051c0:	bec080e7          	jalr	-1044(ra) # 80004da8 <filealloc>
    800051c4:	00aa3023          	sd	a0,0(s4)
    800051c8:	c92d                	beqz	a0,8000523a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800051ca:	ffffc097          	auipc	ra,0xffffc
    800051ce:	92a080e7          	jalr	-1750(ra) # 80000af4 <kalloc>
    800051d2:	892a                	mv	s2,a0
    800051d4:	c125                	beqz	a0,80005234 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800051d6:	4985                	li	s3,1
    800051d8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800051dc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800051e0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800051e4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800051e8:	00003597          	auipc	a1,0x3
    800051ec:	7d058593          	addi	a1,a1,2000 # 800089b8 <syscalls+0x290>
    800051f0:	ffffc097          	auipc	ra,0xffffc
    800051f4:	964080e7          	jalr	-1692(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800051f8:	609c                	ld	a5,0(s1)
    800051fa:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800051fe:	609c                	ld	a5,0(s1)
    80005200:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005204:	609c                	ld	a5,0(s1)
    80005206:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000520a:	609c                	ld	a5,0(s1)
    8000520c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005210:	000a3783          	ld	a5,0(s4)
    80005214:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005218:	000a3783          	ld	a5,0(s4)
    8000521c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005220:	000a3783          	ld	a5,0(s4)
    80005224:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005228:	000a3783          	ld	a5,0(s4)
    8000522c:	0127b823          	sd	s2,16(a5)
  return 0;
    80005230:	4501                	li	a0,0
    80005232:	a025                	j	8000525a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005234:	6088                	ld	a0,0(s1)
    80005236:	e501                	bnez	a0,8000523e <pipealloc+0xaa>
    80005238:	a039                	j	80005246 <pipealloc+0xb2>
    8000523a:	6088                	ld	a0,0(s1)
    8000523c:	c51d                	beqz	a0,8000526a <pipealloc+0xd6>
    fileclose(*f0);
    8000523e:	00000097          	auipc	ra,0x0
    80005242:	c26080e7          	jalr	-986(ra) # 80004e64 <fileclose>
  if(*f1)
    80005246:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000524a:	557d                	li	a0,-1
  if(*f1)
    8000524c:	c799                	beqz	a5,8000525a <pipealloc+0xc6>
    fileclose(*f1);
    8000524e:	853e                	mv	a0,a5
    80005250:	00000097          	auipc	ra,0x0
    80005254:	c14080e7          	jalr	-1004(ra) # 80004e64 <fileclose>
  return -1;
    80005258:	557d                	li	a0,-1
}
    8000525a:	70a2                	ld	ra,40(sp)
    8000525c:	7402                	ld	s0,32(sp)
    8000525e:	64e2                	ld	s1,24(sp)
    80005260:	6942                	ld	s2,16(sp)
    80005262:	69a2                	ld	s3,8(sp)
    80005264:	6a02                	ld	s4,0(sp)
    80005266:	6145                	addi	sp,sp,48
    80005268:	8082                	ret
  return -1;
    8000526a:	557d                	li	a0,-1
    8000526c:	b7fd                	j	8000525a <pipealloc+0xc6>

000000008000526e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000526e:	1101                	addi	sp,sp,-32
    80005270:	ec06                	sd	ra,24(sp)
    80005272:	e822                	sd	s0,16(sp)
    80005274:	e426                	sd	s1,8(sp)
    80005276:	e04a                	sd	s2,0(sp)
    80005278:	1000                	addi	s0,sp,32
    8000527a:	84aa                	mv	s1,a0
    8000527c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000527e:	ffffc097          	auipc	ra,0xffffc
    80005282:	966080e7          	jalr	-1690(ra) # 80000be4 <acquire>
  if(writable){
    80005286:	02090d63          	beqz	s2,800052c0 <pipeclose+0x52>
    pi->writeopen = 0;
    8000528a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000528e:	21848513          	addi	a0,s1,536
    80005292:	ffffe097          	auipc	ra,0xffffe
    80005296:	9b6080e7          	jalr	-1610(ra) # 80002c48 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000529a:	2204b783          	ld	a5,544(s1)
    8000529e:	eb95                	bnez	a5,800052d2 <pipeclose+0x64>
    release(&pi->lock);
    800052a0:	8526                	mv	a0,s1
    800052a2:	ffffc097          	auipc	ra,0xffffc
    800052a6:	9f6080e7          	jalr	-1546(ra) # 80000c98 <release>
    kfree((char*)pi);
    800052aa:	8526                	mv	a0,s1
    800052ac:	ffffb097          	auipc	ra,0xffffb
    800052b0:	74c080e7          	jalr	1868(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800052b4:	60e2                	ld	ra,24(sp)
    800052b6:	6442                	ld	s0,16(sp)
    800052b8:	64a2                	ld	s1,8(sp)
    800052ba:	6902                	ld	s2,0(sp)
    800052bc:	6105                	addi	sp,sp,32
    800052be:	8082                	ret
    pi->readopen = 0;
    800052c0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800052c4:	21c48513          	addi	a0,s1,540
    800052c8:	ffffe097          	auipc	ra,0xffffe
    800052cc:	980080e7          	jalr	-1664(ra) # 80002c48 <wakeup>
    800052d0:	b7e9                	j	8000529a <pipeclose+0x2c>
    release(&pi->lock);
    800052d2:	8526                	mv	a0,s1
    800052d4:	ffffc097          	auipc	ra,0xffffc
    800052d8:	9c4080e7          	jalr	-1596(ra) # 80000c98 <release>
}
    800052dc:	bfe1                	j	800052b4 <pipeclose+0x46>

00000000800052de <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800052de:	7159                	addi	sp,sp,-112
    800052e0:	f486                	sd	ra,104(sp)
    800052e2:	f0a2                	sd	s0,96(sp)
    800052e4:	eca6                	sd	s1,88(sp)
    800052e6:	e8ca                	sd	s2,80(sp)
    800052e8:	e4ce                	sd	s3,72(sp)
    800052ea:	e0d2                	sd	s4,64(sp)
    800052ec:	fc56                	sd	s5,56(sp)
    800052ee:	f85a                	sd	s6,48(sp)
    800052f0:	f45e                	sd	s7,40(sp)
    800052f2:	f062                	sd	s8,32(sp)
    800052f4:	ec66                	sd	s9,24(sp)
    800052f6:	1880                	addi	s0,sp,112
    800052f8:	84aa                	mv	s1,a0
    800052fa:	8aae                	mv	s5,a1
    800052fc:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800052fe:	ffffd097          	auipc	ra,0xffffd
    80005302:	bc6080e7          	jalr	-1082(ra) # 80001ec4 <myproc>
    80005306:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005308:	8526                	mv	a0,s1
    8000530a:	ffffc097          	auipc	ra,0xffffc
    8000530e:	8da080e7          	jalr	-1830(ra) # 80000be4 <acquire>
  while(i < n){
    80005312:	0d405163          	blez	s4,800053d4 <pipewrite+0xf6>
    80005316:	8ba6                	mv	s7,s1
  int i = 0;
    80005318:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000531a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000531c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005320:	21c48c13          	addi	s8,s1,540
    80005324:	a08d                	j	80005386 <pipewrite+0xa8>
      release(&pi->lock);
    80005326:	8526                	mv	a0,s1
    80005328:	ffffc097          	auipc	ra,0xffffc
    8000532c:	970080e7          	jalr	-1680(ra) # 80000c98 <release>
      return -1;
    80005330:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005332:	854a                	mv	a0,s2
    80005334:	70a6                	ld	ra,104(sp)
    80005336:	7406                	ld	s0,96(sp)
    80005338:	64e6                	ld	s1,88(sp)
    8000533a:	6946                	ld	s2,80(sp)
    8000533c:	69a6                	ld	s3,72(sp)
    8000533e:	6a06                	ld	s4,64(sp)
    80005340:	7ae2                	ld	s5,56(sp)
    80005342:	7b42                	ld	s6,48(sp)
    80005344:	7ba2                	ld	s7,40(sp)
    80005346:	7c02                	ld	s8,32(sp)
    80005348:	6ce2                	ld	s9,24(sp)
    8000534a:	6165                	addi	sp,sp,112
    8000534c:	8082                	ret
      wakeup(&pi->nread);
    8000534e:	8566                	mv	a0,s9
    80005350:	ffffe097          	auipc	ra,0xffffe
    80005354:	8f8080e7          	jalr	-1800(ra) # 80002c48 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005358:	85de                	mv	a1,s7
    8000535a:	8562                	mv	a0,s8
    8000535c:	ffffd097          	auipc	ra,0xffffd
    80005360:	2d6080e7          	jalr	726(ra) # 80002632 <sleep>
    80005364:	a839                	j	80005382 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005366:	21c4a783          	lw	a5,540(s1)
    8000536a:	0017871b          	addiw	a4,a5,1
    8000536e:	20e4ae23          	sw	a4,540(s1)
    80005372:	1ff7f793          	andi	a5,a5,511
    80005376:	97a6                	add	a5,a5,s1
    80005378:	f9f44703          	lbu	a4,-97(s0)
    8000537c:	00e78c23          	sb	a4,24(a5)
      i++;
    80005380:	2905                	addiw	s2,s2,1
  while(i < n){
    80005382:	03495d63          	bge	s2,s4,800053bc <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005386:	2204a783          	lw	a5,544(s1)
    8000538a:	dfd1                	beqz	a5,80005326 <pipewrite+0x48>
    8000538c:	0289a783          	lw	a5,40(s3)
    80005390:	fbd9                	bnez	a5,80005326 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005392:	2184a783          	lw	a5,536(s1)
    80005396:	21c4a703          	lw	a4,540(s1)
    8000539a:	2007879b          	addiw	a5,a5,512
    8000539e:	faf708e3          	beq	a4,a5,8000534e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800053a2:	4685                	li	a3,1
    800053a4:	01590633          	add	a2,s2,s5
    800053a8:	f9f40593          	addi	a1,s0,-97
    800053ac:	0509b503          	ld	a0,80(s3)
    800053b0:	ffffc097          	auipc	ra,0xffffc
    800053b4:	34e080e7          	jalr	846(ra) # 800016fe <copyin>
    800053b8:	fb6517e3          	bne	a0,s6,80005366 <pipewrite+0x88>
  wakeup(&pi->nread);
    800053bc:	21848513          	addi	a0,s1,536
    800053c0:	ffffe097          	auipc	ra,0xffffe
    800053c4:	888080e7          	jalr	-1912(ra) # 80002c48 <wakeup>
  release(&pi->lock);
    800053c8:	8526                	mv	a0,s1
    800053ca:	ffffc097          	auipc	ra,0xffffc
    800053ce:	8ce080e7          	jalr	-1842(ra) # 80000c98 <release>
  return i;
    800053d2:	b785                	j	80005332 <pipewrite+0x54>
  int i = 0;
    800053d4:	4901                	li	s2,0
    800053d6:	b7dd                	j	800053bc <pipewrite+0xde>

00000000800053d8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800053d8:	715d                	addi	sp,sp,-80
    800053da:	e486                	sd	ra,72(sp)
    800053dc:	e0a2                	sd	s0,64(sp)
    800053de:	fc26                	sd	s1,56(sp)
    800053e0:	f84a                	sd	s2,48(sp)
    800053e2:	f44e                	sd	s3,40(sp)
    800053e4:	f052                	sd	s4,32(sp)
    800053e6:	ec56                	sd	s5,24(sp)
    800053e8:	e85a                	sd	s6,16(sp)
    800053ea:	0880                	addi	s0,sp,80
    800053ec:	84aa                	mv	s1,a0
    800053ee:	892e                	mv	s2,a1
    800053f0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800053f2:	ffffd097          	auipc	ra,0xffffd
    800053f6:	ad2080e7          	jalr	-1326(ra) # 80001ec4 <myproc>
    800053fa:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800053fc:	8b26                	mv	s6,s1
    800053fe:	8526                	mv	a0,s1
    80005400:	ffffb097          	auipc	ra,0xffffb
    80005404:	7e4080e7          	jalr	2020(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005408:	2184a703          	lw	a4,536(s1)
    8000540c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005410:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005414:	02f71463          	bne	a4,a5,8000543c <piperead+0x64>
    80005418:	2244a783          	lw	a5,548(s1)
    8000541c:	c385                	beqz	a5,8000543c <piperead+0x64>
    if(pr->killed){
    8000541e:	028a2783          	lw	a5,40(s4)
    80005422:	ebc1                	bnez	a5,800054b2 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005424:	85da                	mv	a1,s6
    80005426:	854e                	mv	a0,s3
    80005428:	ffffd097          	auipc	ra,0xffffd
    8000542c:	20a080e7          	jalr	522(ra) # 80002632 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005430:	2184a703          	lw	a4,536(s1)
    80005434:	21c4a783          	lw	a5,540(s1)
    80005438:	fef700e3          	beq	a4,a5,80005418 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000543c:	09505263          	blez	s5,800054c0 <piperead+0xe8>
    80005440:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005442:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005444:	2184a783          	lw	a5,536(s1)
    80005448:	21c4a703          	lw	a4,540(s1)
    8000544c:	02f70d63          	beq	a4,a5,80005486 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005450:	0017871b          	addiw	a4,a5,1
    80005454:	20e4ac23          	sw	a4,536(s1)
    80005458:	1ff7f793          	andi	a5,a5,511
    8000545c:	97a6                	add	a5,a5,s1
    8000545e:	0187c783          	lbu	a5,24(a5)
    80005462:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005466:	4685                	li	a3,1
    80005468:	fbf40613          	addi	a2,s0,-65
    8000546c:	85ca                	mv	a1,s2
    8000546e:	050a3503          	ld	a0,80(s4)
    80005472:	ffffc097          	auipc	ra,0xffffc
    80005476:	200080e7          	jalr	512(ra) # 80001672 <copyout>
    8000547a:	01650663          	beq	a0,s6,80005486 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000547e:	2985                	addiw	s3,s3,1
    80005480:	0905                	addi	s2,s2,1
    80005482:	fd3a91e3          	bne	s5,s3,80005444 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005486:	21c48513          	addi	a0,s1,540
    8000548a:	ffffd097          	auipc	ra,0xffffd
    8000548e:	7be080e7          	jalr	1982(ra) # 80002c48 <wakeup>
  release(&pi->lock);
    80005492:	8526                	mv	a0,s1
    80005494:	ffffc097          	auipc	ra,0xffffc
    80005498:	804080e7          	jalr	-2044(ra) # 80000c98 <release>
  return i;
}
    8000549c:	854e                	mv	a0,s3
    8000549e:	60a6                	ld	ra,72(sp)
    800054a0:	6406                	ld	s0,64(sp)
    800054a2:	74e2                	ld	s1,56(sp)
    800054a4:	7942                	ld	s2,48(sp)
    800054a6:	79a2                	ld	s3,40(sp)
    800054a8:	7a02                	ld	s4,32(sp)
    800054aa:	6ae2                	ld	s5,24(sp)
    800054ac:	6b42                	ld	s6,16(sp)
    800054ae:	6161                	addi	sp,sp,80
    800054b0:	8082                	ret
      release(&pi->lock);
    800054b2:	8526                	mv	a0,s1
    800054b4:	ffffb097          	auipc	ra,0xffffb
    800054b8:	7e4080e7          	jalr	2020(ra) # 80000c98 <release>
      return -1;
    800054bc:	59fd                	li	s3,-1
    800054be:	bff9                	j	8000549c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054c0:	4981                	li	s3,0
    800054c2:	b7d1                	j	80005486 <piperead+0xae>

00000000800054c4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800054c4:	df010113          	addi	sp,sp,-528
    800054c8:	20113423          	sd	ra,520(sp)
    800054cc:	20813023          	sd	s0,512(sp)
    800054d0:	ffa6                	sd	s1,504(sp)
    800054d2:	fbca                	sd	s2,496(sp)
    800054d4:	f7ce                	sd	s3,488(sp)
    800054d6:	f3d2                	sd	s4,480(sp)
    800054d8:	efd6                	sd	s5,472(sp)
    800054da:	ebda                	sd	s6,464(sp)
    800054dc:	e7de                	sd	s7,456(sp)
    800054de:	e3e2                	sd	s8,448(sp)
    800054e0:	ff66                	sd	s9,440(sp)
    800054e2:	fb6a                	sd	s10,432(sp)
    800054e4:	f76e                	sd	s11,424(sp)
    800054e6:	0c00                	addi	s0,sp,528
    800054e8:	84aa                	mv	s1,a0
    800054ea:	dea43c23          	sd	a0,-520(s0)
    800054ee:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800054f2:	ffffd097          	auipc	ra,0xffffd
    800054f6:	9d2080e7          	jalr	-1582(ra) # 80001ec4 <myproc>
    800054fa:	892a                	mv	s2,a0

  begin_op();
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	49c080e7          	jalr	1180(ra) # 80004998 <begin_op>

  if((ip = namei(path)) == 0){
    80005504:	8526                	mv	a0,s1
    80005506:	fffff097          	auipc	ra,0xfffff
    8000550a:	276080e7          	jalr	630(ra) # 8000477c <namei>
    8000550e:	c92d                	beqz	a0,80005580 <exec+0xbc>
    80005510:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	ab4080e7          	jalr	-1356(ra) # 80003fc6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000551a:	04000713          	li	a4,64
    8000551e:	4681                	li	a3,0
    80005520:	e5040613          	addi	a2,s0,-432
    80005524:	4581                	li	a1,0
    80005526:	8526                	mv	a0,s1
    80005528:	fffff097          	auipc	ra,0xfffff
    8000552c:	d52080e7          	jalr	-686(ra) # 8000427a <readi>
    80005530:	04000793          	li	a5,64
    80005534:	00f51a63          	bne	a0,a5,80005548 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005538:	e5042703          	lw	a4,-432(s0)
    8000553c:	464c47b7          	lui	a5,0x464c4
    80005540:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005544:	04f70463          	beq	a4,a5,8000558c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005548:	8526                	mv	a0,s1
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	cde080e7          	jalr	-802(ra) # 80004228 <iunlockput>
    end_op();
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	4c6080e7          	jalr	1222(ra) # 80004a18 <end_op>
  }
  return -1;
    8000555a:	557d                	li	a0,-1
}
    8000555c:	20813083          	ld	ra,520(sp)
    80005560:	20013403          	ld	s0,512(sp)
    80005564:	74fe                	ld	s1,504(sp)
    80005566:	795e                	ld	s2,496(sp)
    80005568:	79be                	ld	s3,488(sp)
    8000556a:	7a1e                	ld	s4,480(sp)
    8000556c:	6afe                	ld	s5,472(sp)
    8000556e:	6b5e                	ld	s6,464(sp)
    80005570:	6bbe                	ld	s7,456(sp)
    80005572:	6c1e                	ld	s8,448(sp)
    80005574:	7cfa                	ld	s9,440(sp)
    80005576:	7d5a                	ld	s10,432(sp)
    80005578:	7dba                	ld	s11,424(sp)
    8000557a:	21010113          	addi	sp,sp,528
    8000557e:	8082                	ret
    end_op();
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	498080e7          	jalr	1176(ra) # 80004a18 <end_op>
    return -1;
    80005588:	557d                	li	a0,-1
    8000558a:	bfc9                	j	8000555c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000558c:	854a                	mv	a0,s2
    8000558e:	ffffd097          	auipc	ra,0xffffd
    80005592:	9f4080e7          	jalr	-1548(ra) # 80001f82 <proc_pagetable>
    80005596:	8baa                	mv	s7,a0
    80005598:	d945                	beqz	a0,80005548 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000559a:	e7042983          	lw	s3,-400(s0)
    8000559e:	e8845783          	lhu	a5,-376(s0)
    800055a2:	c7ad                	beqz	a5,8000560c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800055a4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055a6:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800055a8:	6c85                	lui	s9,0x1
    800055aa:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800055ae:	def43823          	sd	a5,-528(s0)
    800055b2:	a42d                	j	800057dc <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800055b4:	00003517          	auipc	a0,0x3
    800055b8:	40c50513          	addi	a0,a0,1036 # 800089c0 <syscalls+0x298>
    800055bc:	ffffb097          	auipc	ra,0xffffb
    800055c0:	f82080e7          	jalr	-126(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800055c4:	8756                	mv	a4,s5
    800055c6:	012d86bb          	addw	a3,s11,s2
    800055ca:	4581                	li	a1,0
    800055cc:	8526                	mv	a0,s1
    800055ce:	fffff097          	auipc	ra,0xfffff
    800055d2:	cac080e7          	jalr	-852(ra) # 8000427a <readi>
    800055d6:	2501                	sext.w	a0,a0
    800055d8:	1aaa9963          	bne	s5,a0,8000578a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800055dc:	6785                	lui	a5,0x1
    800055de:	0127893b          	addw	s2,a5,s2
    800055e2:	77fd                	lui	a5,0xfffff
    800055e4:	01478a3b          	addw	s4,a5,s4
    800055e8:	1f897163          	bgeu	s2,s8,800057ca <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800055ec:	02091593          	slli	a1,s2,0x20
    800055f0:	9181                	srli	a1,a1,0x20
    800055f2:	95ea                	add	a1,a1,s10
    800055f4:	855e                	mv	a0,s7
    800055f6:	ffffc097          	auipc	ra,0xffffc
    800055fa:	a78080e7          	jalr	-1416(ra) # 8000106e <walkaddr>
    800055fe:	862a                	mv	a2,a0
    if(pa == 0)
    80005600:	d955                	beqz	a0,800055b4 <exec+0xf0>
      n = PGSIZE;
    80005602:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005604:	fd9a70e3          	bgeu	s4,s9,800055c4 <exec+0x100>
      n = sz - i;
    80005608:	8ad2                	mv	s5,s4
    8000560a:	bf6d                	j	800055c4 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000560c:	4901                	li	s2,0
  iunlockput(ip);
    8000560e:	8526                	mv	a0,s1
    80005610:	fffff097          	auipc	ra,0xfffff
    80005614:	c18080e7          	jalr	-1000(ra) # 80004228 <iunlockput>
  end_op();
    80005618:	fffff097          	auipc	ra,0xfffff
    8000561c:	400080e7          	jalr	1024(ra) # 80004a18 <end_op>
  p = myproc();
    80005620:	ffffd097          	auipc	ra,0xffffd
    80005624:	8a4080e7          	jalr	-1884(ra) # 80001ec4 <myproc>
    80005628:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000562a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000562e:	6785                	lui	a5,0x1
    80005630:	17fd                	addi	a5,a5,-1
    80005632:	993e                	add	s2,s2,a5
    80005634:	757d                	lui	a0,0xfffff
    80005636:	00a977b3          	and	a5,s2,a0
    8000563a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000563e:	6609                	lui	a2,0x2
    80005640:	963e                	add	a2,a2,a5
    80005642:	85be                	mv	a1,a5
    80005644:	855e                	mv	a0,s7
    80005646:	ffffc097          	auipc	ra,0xffffc
    8000564a:	ddc080e7          	jalr	-548(ra) # 80001422 <uvmalloc>
    8000564e:	8b2a                	mv	s6,a0
  ip = 0;
    80005650:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005652:	12050c63          	beqz	a0,8000578a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005656:	75f9                	lui	a1,0xffffe
    80005658:	95aa                	add	a1,a1,a0
    8000565a:	855e                	mv	a0,s7
    8000565c:	ffffc097          	auipc	ra,0xffffc
    80005660:	fe4080e7          	jalr	-28(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005664:	7c7d                	lui	s8,0xfffff
    80005666:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005668:	e0043783          	ld	a5,-512(s0)
    8000566c:	6388                	ld	a0,0(a5)
    8000566e:	c535                	beqz	a0,800056da <exec+0x216>
    80005670:	e9040993          	addi	s3,s0,-368
    80005674:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005678:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000567a:	ffffb097          	auipc	ra,0xffffb
    8000567e:	7ea080e7          	jalr	2026(ra) # 80000e64 <strlen>
    80005682:	2505                	addiw	a0,a0,1
    80005684:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005688:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000568c:	13896363          	bltu	s2,s8,800057b2 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005690:	e0043d83          	ld	s11,-512(s0)
    80005694:	000dba03          	ld	s4,0(s11)
    80005698:	8552                	mv	a0,s4
    8000569a:	ffffb097          	auipc	ra,0xffffb
    8000569e:	7ca080e7          	jalr	1994(ra) # 80000e64 <strlen>
    800056a2:	0015069b          	addiw	a3,a0,1
    800056a6:	8652                	mv	a2,s4
    800056a8:	85ca                	mv	a1,s2
    800056aa:	855e                	mv	a0,s7
    800056ac:	ffffc097          	auipc	ra,0xffffc
    800056b0:	fc6080e7          	jalr	-58(ra) # 80001672 <copyout>
    800056b4:	10054363          	bltz	a0,800057ba <exec+0x2f6>
    ustack[argc] = sp;
    800056b8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800056bc:	0485                	addi	s1,s1,1
    800056be:	008d8793          	addi	a5,s11,8
    800056c2:	e0f43023          	sd	a5,-512(s0)
    800056c6:	008db503          	ld	a0,8(s11)
    800056ca:	c911                	beqz	a0,800056de <exec+0x21a>
    if(argc >= MAXARG)
    800056cc:	09a1                	addi	s3,s3,8
    800056ce:	fb3c96e3          	bne	s9,s3,8000567a <exec+0x1b6>
  sz = sz1;
    800056d2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056d6:	4481                	li	s1,0
    800056d8:	a84d                	j	8000578a <exec+0x2c6>
  sp = sz;
    800056da:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800056dc:	4481                	li	s1,0
  ustack[argc] = 0;
    800056de:	00349793          	slli	a5,s1,0x3
    800056e2:	f9040713          	addi	a4,s0,-112
    800056e6:	97ba                	add	a5,a5,a4
    800056e8:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800056ec:	00148693          	addi	a3,s1,1
    800056f0:	068e                	slli	a3,a3,0x3
    800056f2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800056f6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800056fa:	01897663          	bgeu	s2,s8,80005706 <exec+0x242>
  sz = sz1;
    800056fe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005702:	4481                	li	s1,0
    80005704:	a059                	j	8000578a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005706:	e9040613          	addi	a2,s0,-368
    8000570a:	85ca                	mv	a1,s2
    8000570c:	855e                	mv	a0,s7
    8000570e:	ffffc097          	auipc	ra,0xffffc
    80005712:	f64080e7          	jalr	-156(ra) # 80001672 <copyout>
    80005716:	0a054663          	bltz	a0,800057c2 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000571a:	058ab783          	ld	a5,88(s5)
    8000571e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005722:	df843783          	ld	a5,-520(s0)
    80005726:	0007c703          	lbu	a4,0(a5)
    8000572a:	cf11                	beqz	a4,80005746 <exec+0x282>
    8000572c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000572e:	02f00693          	li	a3,47
    80005732:	a039                	j	80005740 <exec+0x27c>
      last = s+1;
    80005734:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005738:	0785                	addi	a5,a5,1
    8000573a:	fff7c703          	lbu	a4,-1(a5)
    8000573e:	c701                	beqz	a4,80005746 <exec+0x282>
    if(*s == '/')
    80005740:	fed71ce3          	bne	a4,a3,80005738 <exec+0x274>
    80005744:	bfc5                	j	80005734 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005746:	4641                	li	a2,16
    80005748:	df843583          	ld	a1,-520(s0)
    8000574c:	158a8513          	addi	a0,s5,344
    80005750:	ffffb097          	auipc	ra,0xffffb
    80005754:	6e2080e7          	jalr	1762(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005758:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000575c:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005760:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005764:	058ab783          	ld	a5,88(s5)
    80005768:	e6843703          	ld	a4,-408(s0)
    8000576c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000576e:	058ab783          	ld	a5,88(s5)
    80005772:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005776:	85ea                	mv	a1,s10
    80005778:	ffffd097          	auipc	ra,0xffffd
    8000577c:	8a6080e7          	jalr	-1882(ra) # 8000201e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005780:	0004851b          	sext.w	a0,s1
    80005784:	bbe1                	j	8000555c <exec+0x98>
    80005786:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000578a:	e0843583          	ld	a1,-504(s0)
    8000578e:	855e                	mv	a0,s7
    80005790:	ffffd097          	auipc	ra,0xffffd
    80005794:	88e080e7          	jalr	-1906(ra) # 8000201e <proc_freepagetable>
  if(ip){
    80005798:	da0498e3          	bnez	s1,80005548 <exec+0x84>
  return -1;
    8000579c:	557d                	li	a0,-1
    8000579e:	bb7d                	j	8000555c <exec+0x98>
    800057a0:	e1243423          	sd	s2,-504(s0)
    800057a4:	b7dd                	j	8000578a <exec+0x2c6>
    800057a6:	e1243423          	sd	s2,-504(s0)
    800057aa:	b7c5                	j	8000578a <exec+0x2c6>
    800057ac:	e1243423          	sd	s2,-504(s0)
    800057b0:	bfe9                	j	8000578a <exec+0x2c6>
  sz = sz1;
    800057b2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800057b6:	4481                	li	s1,0
    800057b8:	bfc9                	j	8000578a <exec+0x2c6>
  sz = sz1;
    800057ba:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800057be:	4481                	li	s1,0
    800057c0:	b7e9                	j	8000578a <exec+0x2c6>
  sz = sz1;
    800057c2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800057c6:	4481                	li	s1,0
    800057c8:	b7c9                	j	8000578a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800057ca:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057ce:	2b05                	addiw	s6,s6,1
    800057d0:	0389899b          	addiw	s3,s3,56
    800057d4:	e8845783          	lhu	a5,-376(s0)
    800057d8:	e2fb5be3          	bge	s6,a5,8000560e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800057dc:	2981                	sext.w	s3,s3
    800057de:	03800713          	li	a4,56
    800057e2:	86ce                	mv	a3,s3
    800057e4:	e1840613          	addi	a2,s0,-488
    800057e8:	4581                	li	a1,0
    800057ea:	8526                	mv	a0,s1
    800057ec:	fffff097          	auipc	ra,0xfffff
    800057f0:	a8e080e7          	jalr	-1394(ra) # 8000427a <readi>
    800057f4:	03800793          	li	a5,56
    800057f8:	f8f517e3          	bne	a0,a5,80005786 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800057fc:	e1842783          	lw	a5,-488(s0)
    80005800:	4705                	li	a4,1
    80005802:	fce796e3          	bne	a5,a4,800057ce <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005806:	e4043603          	ld	a2,-448(s0)
    8000580a:	e3843783          	ld	a5,-456(s0)
    8000580e:	f8f669e3          	bltu	a2,a5,800057a0 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005812:	e2843783          	ld	a5,-472(s0)
    80005816:	963e                	add	a2,a2,a5
    80005818:	f8f667e3          	bltu	a2,a5,800057a6 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000581c:	85ca                	mv	a1,s2
    8000581e:	855e                	mv	a0,s7
    80005820:	ffffc097          	auipc	ra,0xffffc
    80005824:	c02080e7          	jalr	-1022(ra) # 80001422 <uvmalloc>
    80005828:	e0a43423          	sd	a0,-504(s0)
    8000582c:	d141                	beqz	a0,800057ac <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000582e:	e2843d03          	ld	s10,-472(s0)
    80005832:	df043783          	ld	a5,-528(s0)
    80005836:	00fd77b3          	and	a5,s10,a5
    8000583a:	fba1                	bnez	a5,8000578a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000583c:	e2042d83          	lw	s11,-480(s0)
    80005840:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005844:	f80c03e3          	beqz	s8,800057ca <exec+0x306>
    80005848:	8a62                	mv	s4,s8
    8000584a:	4901                	li	s2,0
    8000584c:	b345                	j	800055ec <exec+0x128>

000000008000584e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000584e:	7179                	addi	sp,sp,-48
    80005850:	f406                	sd	ra,40(sp)
    80005852:	f022                	sd	s0,32(sp)
    80005854:	ec26                	sd	s1,24(sp)
    80005856:	e84a                	sd	s2,16(sp)
    80005858:	1800                	addi	s0,sp,48
    8000585a:	892e                	mv	s2,a1
    8000585c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000585e:	fdc40593          	addi	a1,s0,-36
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	b76080e7          	jalr	-1162(ra) # 800033d8 <argint>
    8000586a:	04054063          	bltz	a0,800058aa <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000586e:	fdc42703          	lw	a4,-36(s0)
    80005872:	47bd                	li	a5,15
    80005874:	02e7ed63          	bltu	a5,a4,800058ae <argfd+0x60>
    80005878:	ffffc097          	auipc	ra,0xffffc
    8000587c:	64c080e7          	jalr	1612(ra) # 80001ec4 <myproc>
    80005880:	fdc42703          	lw	a4,-36(s0)
    80005884:	01a70793          	addi	a5,a4,26
    80005888:	078e                	slli	a5,a5,0x3
    8000588a:	953e                	add	a0,a0,a5
    8000588c:	611c                	ld	a5,0(a0)
    8000588e:	c395                	beqz	a5,800058b2 <argfd+0x64>
    return -1;
  if(pfd)
    80005890:	00090463          	beqz	s2,80005898 <argfd+0x4a>
    *pfd = fd;
    80005894:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005898:	4501                	li	a0,0
  if(pf)
    8000589a:	c091                	beqz	s1,8000589e <argfd+0x50>
    *pf = f;
    8000589c:	e09c                	sd	a5,0(s1)
}
    8000589e:	70a2                	ld	ra,40(sp)
    800058a0:	7402                	ld	s0,32(sp)
    800058a2:	64e2                	ld	s1,24(sp)
    800058a4:	6942                	ld	s2,16(sp)
    800058a6:	6145                	addi	sp,sp,48
    800058a8:	8082                	ret
    return -1;
    800058aa:	557d                	li	a0,-1
    800058ac:	bfcd                	j	8000589e <argfd+0x50>
    return -1;
    800058ae:	557d                	li	a0,-1
    800058b0:	b7fd                	j	8000589e <argfd+0x50>
    800058b2:	557d                	li	a0,-1
    800058b4:	b7ed                	j	8000589e <argfd+0x50>

00000000800058b6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800058b6:	1101                	addi	sp,sp,-32
    800058b8:	ec06                	sd	ra,24(sp)
    800058ba:	e822                	sd	s0,16(sp)
    800058bc:	e426                	sd	s1,8(sp)
    800058be:	1000                	addi	s0,sp,32
    800058c0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800058c2:	ffffc097          	auipc	ra,0xffffc
    800058c6:	602080e7          	jalr	1538(ra) # 80001ec4 <myproc>
    800058ca:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800058cc:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800058d0:	4501                	li	a0,0
    800058d2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800058d4:	6398                	ld	a4,0(a5)
    800058d6:	cb19                	beqz	a4,800058ec <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800058d8:	2505                	addiw	a0,a0,1
    800058da:	07a1                	addi	a5,a5,8
    800058dc:	fed51ce3          	bne	a0,a3,800058d4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800058e0:	557d                	li	a0,-1
}
    800058e2:	60e2                	ld	ra,24(sp)
    800058e4:	6442                	ld	s0,16(sp)
    800058e6:	64a2                	ld	s1,8(sp)
    800058e8:	6105                	addi	sp,sp,32
    800058ea:	8082                	ret
      p->ofile[fd] = f;
    800058ec:	01a50793          	addi	a5,a0,26
    800058f0:	078e                	slli	a5,a5,0x3
    800058f2:	963e                	add	a2,a2,a5
    800058f4:	e204                	sd	s1,0(a2)
      return fd;
    800058f6:	b7f5                	j	800058e2 <fdalloc+0x2c>

00000000800058f8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800058f8:	715d                	addi	sp,sp,-80
    800058fa:	e486                	sd	ra,72(sp)
    800058fc:	e0a2                	sd	s0,64(sp)
    800058fe:	fc26                	sd	s1,56(sp)
    80005900:	f84a                	sd	s2,48(sp)
    80005902:	f44e                	sd	s3,40(sp)
    80005904:	f052                	sd	s4,32(sp)
    80005906:	ec56                	sd	s5,24(sp)
    80005908:	0880                	addi	s0,sp,80
    8000590a:	89ae                	mv	s3,a1
    8000590c:	8ab2                	mv	s5,a2
    8000590e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005910:	fb040593          	addi	a1,s0,-80
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	e86080e7          	jalr	-378(ra) # 8000479a <nameiparent>
    8000591c:	892a                	mv	s2,a0
    8000591e:	12050f63          	beqz	a0,80005a5c <create+0x164>
    return 0;

  ilock(dp);
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	6a4080e7          	jalr	1700(ra) # 80003fc6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000592a:	4601                	li	a2,0
    8000592c:	fb040593          	addi	a1,s0,-80
    80005930:	854a                	mv	a0,s2
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	b78080e7          	jalr	-1160(ra) # 800044aa <dirlookup>
    8000593a:	84aa                	mv	s1,a0
    8000593c:	c921                	beqz	a0,8000598c <create+0x94>
    iunlockput(dp);
    8000593e:	854a                	mv	a0,s2
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	8e8080e7          	jalr	-1816(ra) # 80004228 <iunlockput>
    ilock(ip);
    80005948:	8526                	mv	a0,s1
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	67c080e7          	jalr	1660(ra) # 80003fc6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005952:	2981                	sext.w	s3,s3
    80005954:	4789                	li	a5,2
    80005956:	02f99463          	bne	s3,a5,8000597e <create+0x86>
    8000595a:	0444d783          	lhu	a5,68(s1)
    8000595e:	37f9                	addiw	a5,a5,-2
    80005960:	17c2                	slli	a5,a5,0x30
    80005962:	93c1                	srli	a5,a5,0x30
    80005964:	4705                	li	a4,1
    80005966:	00f76c63          	bltu	a4,a5,8000597e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000596a:	8526                	mv	a0,s1
    8000596c:	60a6                	ld	ra,72(sp)
    8000596e:	6406                	ld	s0,64(sp)
    80005970:	74e2                	ld	s1,56(sp)
    80005972:	7942                	ld	s2,48(sp)
    80005974:	79a2                	ld	s3,40(sp)
    80005976:	7a02                	ld	s4,32(sp)
    80005978:	6ae2                	ld	s5,24(sp)
    8000597a:	6161                	addi	sp,sp,80
    8000597c:	8082                	ret
    iunlockput(ip);
    8000597e:	8526                	mv	a0,s1
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	8a8080e7          	jalr	-1880(ra) # 80004228 <iunlockput>
    return 0;
    80005988:	4481                	li	s1,0
    8000598a:	b7c5                	j	8000596a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000598c:	85ce                	mv	a1,s3
    8000598e:	00092503          	lw	a0,0(s2)
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	49c080e7          	jalr	1180(ra) # 80003e2e <ialloc>
    8000599a:	84aa                	mv	s1,a0
    8000599c:	c529                	beqz	a0,800059e6 <create+0xee>
  ilock(ip);
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	628080e7          	jalr	1576(ra) # 80003fc6 <ilock>
  ip->major = major;
    800059a6:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800059aa:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800059ae:	4785                	li	a5,1
    800059b0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059b4:	8526                	mv	a0,s1
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	546080e7          	jalr	1350(ra) # 80003efc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800059be:	2981                	sext.w	s3,s3
    800059c0:	4785                	li	a5,1
    800059c2:	02f98a63          	beq	s3,a5,800059f6 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800059c6:	40d0                	lw	a2,4(s1)
    800059c8:	fb040593          	addi	a1,s0,-80
    800059cc:	854a                	mv	a0,s2
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	cec080e7          	jalr	-788(ra) # 800046ba <dirlink>
    800059d6:	06054b63          	bltz	a0,80005a4c <create+0x154>
  iunlockput(dp);
    800059da:	854a                	mv	a0,s2
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	84c080e7          	jalr	-1972(ra) # 80004228 <iunlockput>
  return ip;
    800059e4:	b759                	j	8000596a <create+0x72>
    panic("create: ialloc");
    800059e6:	00003517          	auipc	a0,0x3
    800059ea:	ffa50513          	addi	a0,a0,-6 # 800089e0 <syscalls+0x2b8>
    800059ee:	ffffb097          	auipc	ra,0xffffb
    800059f2:	b50080e7          	jalr	-1200(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800059f6:	04a95783          	lhu	a5,74(s2)
    800059fa:	2785                	addiw	a5,a5,1
    800059fc:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005a00:	854a                	mv	a0,s2
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	4fa080e7          	jalr	1274(ra) # 80003efc <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005a0a:	40d0                	lw	a2,4(s1)
    80005a0c:	00003597          	auipc	a1,0x3
    80005a10:	fe458593          	addi	a1,a1,-28 # 800089f0 <syscalls+0x2c8>
    80005a14:	8526                	mv	a0,s1
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	ca4080e7          	jalr	-860(ra) # 800046ba <dirlink>
    80005a1e:	00054f63          	bltz	a0,80005a3c <create+0x144>
    80005a22:	00492603          	lw	a2,4(s2)
    80005a26:	00003597          	auipc	a1,0x3
    80005a2a:	fd258593          	addi	a1,a1,-46 # 800089f8 <syscalls+0x2d0>
    80005a2e:	8526                	mv	a0,s1
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	c8a080e7          	jalr	-886(ra) # 800046ba <dirlink>
    80005a38:	f80557e3          	bgez	a0,800059c6 <create+0xce>
      panic("create dots");
    80005a3c:	00003517          	auipc	a0,0x3
    80005a40:	fc450513          	addi	a0,a0,-60 # 80008a00 <syscalls+0x2d8>
    80005a44:	ffffb097          	auipc	ra,0xffffb
    80005a48:	afa080e7          	jalr	-1286(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005a4c:	00003517          	auipc	a0,0x3
    80005a50:	fc450513          	addi	a0,a0,-60 # 80008a10 <syscalls+0x2e8>
    80005a54:	ffffb097          	auipc	ra,0xffffb
    80005a58:	aea080e7          	jalr	-1302(ra) # 8000053e <panic>
    return 0;
    80005a5c:	84aa                	mv	s1,a0
    80005a5e:	b731                	j	8000596a <create+0x72>

0000000080005a60 <sys_dup>:
{
    80005a60:	7179                	addi	sp,sp,-48
    80005a62:	f406                	sd	ra,40(sp)
    80005a64:	f022                	sd	s0,32(sp)
    80005a66:	ec26                	sd	s1,24(sp)
    80005a68:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005a6a:	fd840613          	addi	a2,s0,-40
    80005a6e:	4581                	li	a1,0
    80005a70:	4501                	li	a0,0
    80005a72:	00000097          	auipc	ra,0x0
    80005a76:	ddc080e7          	jalr	-548(ra) # 8000584e <argfd>
    return -1;
    80005a7a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005a7c:	02054363          	bltz	a0,80005aa2 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005a80:	fd843503          	ld	a0,-40(s0)
    80005a84:	00000097          	auipc	ra,0x0
    80005a88:	e32080e7          	jalr	-462(ra) # 800058b6 <fdalloc>
    80005a8c:	84aa                	mv	s1,a0
    return -1;
    80005a8e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005a90:	00054963          	bltz	a0,80005aa2 <sys_dup+0x42>
  filedup(f);
    80005a94:	fd843503          	ld	a0,-40(s0)
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	37a080e7          	jalr	890(ra) # 80004e12 <filedup>
  return fd;
    80005aa0:	87a6                	mv	a5,s1
}
    80005aa2:	853e                	mv	a0,a5
    80005aa4:	70a2                	ld	ra,40(sp)
    80005aa6:	7402                	ld	s0,32(sp)
    80005aa8:	64e2                	ld	s1,24(sp)
    80005aaa:	6145                	addi	sp,sp,48
    80005aac:	8082                	ret

0000000080005aae <sys_read>:
{
    80005aae:	7179                	addi	sp,sp,-48
    80005ab0:	f406                	sd	ra,40(sp)
    80005ab2:	f022                	sd	s0,32(sp)
    80005ab4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ab6:	fe840613          	addi	a2,s0,-24
    80005aba:	4581                	li	a1,0
    80005abc:	4501                	li	a0,0
    80005abe:	00000097          	auipc	ra,0x0
    80005ac2:	d90080e7          	jalr	-624(ra) # 8000584e <argfd>
    return -1;
    80005ac6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ac8:	04054163          	bltz	a0,80005b0a <sys_read+0x5c>
    80005acc:	fe440593          	addi	a1,s0,-28
    80005ad0:	4509                	li	a0,2
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	906080e7          	jalr	-1786(ra) # 800033d8 <argint>
    return -1;
    80005ada:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005adc:	02054763          	bltz	a0,80005b0a <sys_read+0x5c>
    80005ae0:	fd840593          	addi	a1,s0,-40
    80005ae4:	4505                	li	a0,1
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	914080e7          	jalr	-1772(ra) # 800033fa <argaddr>
    return -1;
    80005aee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005af0:	00054d63          	bltz	a0,80005b0a <sys_read+0x5c>
  return fileread(f, p, n);
    80005af4:	fe442603          	lw	a2,-28(s0)
    80005af8:	fd843583          	ld	a1,-40(s0)
    80005afc:	fe843503          	ld	a0,-24(s0)
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	49e080e7          	jalr	1182(ra) # 80004f9e <fileread>
    80005b08:	87aa                	mv	a5,a0
}
    80005b0a:	853e                	mv	a0,a5
    80005b0c:	70a2                	ld	ra,40(sp)
    80005b0e:	7402                	ld	s0,32(sp)
    80005b10:	6145                	addi	sp,sp,48
    80005b12:	8082                	ret

0000000080005b14 <sys_write>:
{
    80005b14:	7179                	addi	sp,sp,-48
    80005b16:	f406                	sd	ra,40(sp)
    80005b18:	f022                	sd	s0,32(sp)
    80005b1a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b1c:	fe840613          	addi	a2,s0,-24
    80005b20:	4581                	li	a1,0
    80005b22:	4501                	li	a0,0
    80005b24:	00000097          	auipc	ra,0x0
    80005b28:	d2a080e7          	jalr	-726(ra) # 8000584e <argfd>
    return -1;
    80005b2c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b2e:	04054163          	bltz	a0,80005b70 <sys_write+0x5c>
    80005b32:	fe440593          	addi	a1,s0,-28
    80005b36:	4509                	li	a0,2
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	8a0080e7          	jalr	-1888(ra) # 800033d8 <argint>
    return -1;
    80005b40:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b42:	02054763          	bltz	a0,80005b70 <sys_write+0x5c>
    80005b46:	fd840593          	addi	a1,s0,-40
    80005b4a:	4505                	li	a0,1
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	8ae080e7          	jalr	-1874(ra) # 800033fa <argaddr>
    return -1;
    80005b54:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b56:	00054d63          	bltz	a0,80005b70 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005b5a:	fe442603          	lw	a2,-28(s0)
    80005b5e:	fd843583          	ld	a1,-40(s0)
    80005b62:	fe843503          	ld	a0,-24(s0)
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	4fa080e7          	jalr	1274(ra) # 80005060 <filewrite>
    80005b6e:	87aa                	mv	a5,a0
}
    80005b70:	853e                	mv	a0,a5
    80005b72:	70a2                	ld	ra,40(sp)
    80005b74:	7402                	ld	s0,32(sp)
    80005b76:	6145                	addi	sp,sp,48
    80005b78:	8082                	ret

0000000080005b7a <sys_close>:
{
    80005b7a:	1101                	addi	sp,sp,-32
    80005b7c:	ec06                	sd	ra,24(sp)
    80005b7e:	e822                	sd	s0,16(sp)
    80005b80:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005b82:	fe040613          	addi	a2,s0,-32
    80005b86:	fec40593          	addi	a1,s0,-20
    80005b8a:	4501                	li	a0,0
    80005b8c:	00000097          	auipc	ra,0x0
    80005b90:	cc2080e7          	jalr	-830(ra) # 8000584e <argfd>
    return -1;
    80005b94:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005b96:	02054463          	bltz	a0,80005bbe <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005b9a:	ffffc097          	auipc	ra,0xffffc
    80005b9e:	32a080e7          	jalr	810(ra) # 80001ec4 <myproc>
    80005ba2:	fec42783          	lw	a5,-20(s0)
    80005ba6:	07e9                	addi	a5,a5,26
    80005ba8:	078e                	slli	a5,a5,0x3
    80005baa:	97aa                	add	a5,a5,a0
    80005bac:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005bb0:	fe043503          	ld	a0,-32(s0)
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	2b0080e7          	jalr	688(ra) # 80004e64 <fileclose>
  return 0;
    80005bbc:	4781                	li	a5,0
}
    80005bbe:	853e                	mv	a0,a5
    80005bc0:	60e2                	ld	ra,24(sp)
    80005bc2:	6442                	ld	s0,16(sp)
    80005bc4:	6105                	addi	sp,sp,32
    80005bc6:	8082                	ret

0000000080005bc8 <sys_fstat>:
{
    80005bc8:	1101                	addi	sp,sp,-32
    80005bca:	ec06                	sd	ra,24(sp)
    80005bcc:	e822                	sd	s0,16(sp)
    80005bce:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005bd0:	fe840613          	addi	a2,s0,-24
    80005bd4:	4581                	li	a1,0
    80005bd6:	4501                	li	a0,0
    80005bd8:	00000097          	auipc	ra,0x0
    80005bdc:	c76080e7          	jalr	-906(ra) # 8000584e <argfd>
    return -1;
    80005be0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005be2:	02054563          	bltz	a0,80005c0c <sys_fstat+0x44>
    80005be6:	fe040593          	addi	a1,s0,-32
    80005bea:	4505                	li	a0,1
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	80e080e7          	jalr	-2034(ra) # 800033fa <argaddr>
    return -1;
    80005bf4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005bf6:	00054b63          	bltz	a0,80005c0c <sys_fstat+0x44>
  return filestat(f, st);
    80005bfa:	fe043583          	ld	a1,-32(s0)
    80005bfe:	fe843503          	ld	a0,-24(s0)
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	32a080e7          	jalr	810(ra) # 80004f2c <filestat>
    80005c0a:	87aa                	mv	a5,a0
}
    80005c0c:	853e                	mv	a0,a5
    80005c0e:	60e2                	ld	ra,24(sp)
    80005c10:	6442                	ld	s0,16(sp)
    80005c12:	6105                	addi	sp,sp,32
    80005c14:	8082                	ret

0000000080005c16 <sys_link>:
{
    80005c16:	7169                	addi	sp,sp,-304
    80005c18:	f606                	sd	ra,296(sp)
    80005c1a:	f222                	sd	s0,288(sp)
    80005c1c:	ee26                	sd	s1,280(sp)
    80005c1e:	ea4a                	sd	s2,272(sp)
    80005c20:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c22:	08000613          	li	a2,128
    80005c26:	ed040593          	addi	a1,s0,-304
    80005c2a:	4501                	li	a0,0
    80005c2c:	ffffd097          	auipc	ra,0xffffd
    80005c30:	7f0080e7          	jalr	2032(ra) # 8000341c <argstr>
    return -1;
    80005c34:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c36:	10054e63          	bltz	a0,80005d52 <sys_link+0x13c>
    80005c3a:	08000613          	li	a2,128
    80005c3e:	f5040593          	addi	a1,s0,-176
    80005c42:	4505                	li	a0,1
    80005c44:	ffffd097          	auipc	ra,0xffffd
    80005c48:	7d8080e7          	jalr	2008(ra) # 8000341c <argstr>
    return -1;
    80005c4c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c4e:	10054263          	bltz	a0,80005d52 <sys_link+0x13c>
  begin_op();
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	d46080e7          	jalr	-698(ra) # 80004998 <begin_op>
  if((ip = namei(old)) == 0){
    80005c5a:	ed040513          	addi	a0,s0,-304
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	b1e080e7          	jalr	-1250(ra) # 8000477c <namei>
    80005c66:	84aa                	mv	s1,a0
    80005c68:	c551                	beqz	a0,80005cf4 <sys_link+0xde>
  ilock(ip);
    80005c6a:	ffffe097          	auipc	ra,0xffffe
    80005c6e:	35c080e7          	jalr	860(ra) # 80003fc6 <ilock>
  if(ip->type == T_DIR){
    80005c72:	04449703          	lh	a4,68(s1)
    80005c76:	4785                	li	a5,1
    80005c78:	08f70463          	beq	a4,a5,80005d00 <sys_link+0xea>
  ip->nlink++;
    80005c7c:	04a4d783          	lhu	a5,74(s1)
    80005c80:	2785                	addiw	a5,a5,1
    80005c82:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c86:	8526                	mv	a0,s1
    80005c88:	ffffe097          	auipc	ra,0xffffe
    80005c8c:	274080e7          	jalr	628(ra) # 80003efc <iupdate>
  iunlock(ip);
    80005c90:	8526                	mv	a0,s1
    80005c92:	ffffe097          	auipc	ra,0xffffe
    80005c96:	3f6080e7          	jalr	1014(ra) # 80004088 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005c9a:	fd040593          	addi	a1,s0,-48
    80005c9e:	f5040513          	addi	a0,s0,-176
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	af8080e7          	jalr	-1288(ra) # 8000479a <nameiparent>
    80005caa:	892a                	mv	s2,a0
    80005cac:	c935                	beqz	a0,80005d20 <sys_link+0x10a>
  ilock(dp);
    80005cae:	ffffe097          	auipc	ra,0xffffe
    80005cb2:	318080e7          	jalr	792(ra) # 80003fc6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005cb6:	00092703          	lw	a4,0(s2)
    80005cba:	409c                	lw	a5,0(s1)
    80005cbc:	04f71d63          	bne	a4,a5,80005d16 <sys_link+0x100>
    80005cc0:	40d0                	lw	a2,4(s1)
    80005cc2:	fd040593          	addi	a1,s0,-48
    80005cc6:	854a                	mv	a0,s2
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	9f2080e7          	jalr	-1550(ra) # 800046ba <dirlink>
    80005cd0:	04054363          	bltz	a0,80005d16 <sys_link+0x100>
  iunlockput(dp);
    80005cd4:	854a                	mv	a0,s2
    80005cd6:	ffffe097          	auipc	ra,0xffffe
    80005cda:	552080e7          	jalr	1362(ra) # 80004228 <iunlockput>
  iput(ip);
    80005cde:	8526                	mv	a0,s1
    80005ce0:	ffffe097          	auipc	ra,0xffffe
    80005ce4:	4a0080e7          	jalr	1184(ra) # 80004180 <iput>
  end_op();
    80005ce8:	fffff097          	auipc	ra,0xfffff
    80005cec:	d30080e7          	jalr	-720(ra) # 80004a18 <end_op>
  return 0;
    80005cf0:	4781                	li	a5,0
    80005cf2:	a085                	j	80005d52 <sys_link+0x13c>
    end_op();
    80005cf4:	fffff097          	auipc	ra,0xfffff
    80005cf8:	d24080e7          	jalr	-732(ra) # 80004a18 <end_op>
    return -1;
    80005cfc:	57fd                	li	a5,-1
    80005cfe:	a891                	j	80005d52 <sys_link+0x13c>
    iunlockput(ip);
    80005d00:	8526                	mv	a0,s1
    80005d02:	ffffe097          	auipc	ra,0xffffe
    80005d06:	526080e7          	jalr	1318(ra) # 80004228 <iunlockput>
    end_op();
    80005d0a:	fffff097          	auipc	ra,0xfffff
    80005d0e:	d0e080e7          	jalr	-754(ra) # 80004a18 <end_op>
    return -1;
    80005d12:	57fd                	li	a5,-1
    80005d14:	a83d                	j	80005d52 <sys_link+0x13c>
    iunlockput(dp);
    80005d16:	854a                	mv	a0,s2
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	510080e7          	jalr	1296(ra) # 80004228 <iunlockput>
  ilock(ip);
    80005d20:	8526                	mv	a0,s1
    80005d22:	ffffe097          	auipc	ra,0xffffe
    80005d26:	2a4080e7          	jalr	676(ra) # 80003fc6 <ilock>
  ip->nlink--;
    80005d2a:	04a4d783          	lhu	a5,74(s1)
    80005d2e:	37fd                	addiw	a5,a5,-1
    80005d30:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d34:	8526                	mv	a0,s1
    80005d36:	ffffe097          	auipc	ra,0xffffe
    80005d3a:	1c6080e7          	jalr	454(ra) # 80003efc <iupdate>
  iunlockput(ip);
    80005d3e:	8526                	mv	a0,s1
    80005d40:	ffffe097          	auipc	ra,0xffffe
    80005d44:	4e8080e7          	jalr	1256(ra) # 80004228 <iunlockput>
  end_op();
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	cd0080e7          	jalr	-816(ra) # 80004a18 <end_op>
  return -1;
    80005d50:	57fd                	li	a5,-1
}
    80005d52:	853e                	mv	a0,a5
    80005d54:	70b2                	ld	ra,296(sp)
    80005d56:	7412                	ld	s0,288(sp)
    80005d58:	64f2                	ld	s1,280(sp)
    80005d5a:	6952                	ld	s2,272(sp)
    80005d5c:	6155                	addi	sp,sp,304
    80005d5e:	8082                	ret

0000000080005d60 <sys_unlink>:
{
    80005d60:	7151                	addi	sp,sp,-240
    80005d62:	f586                	sd	ra,232(sp)
    80005d64:	f1a2                	sd	s0,224(sp)
    80005d66:	eda6                	sd	s1,216(sp)
    80005d68:	e9ca                	sd	s2,208(sp)
    80005d6a:	e5ce                	sd	s3,200(sp)
    80005d6c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005d6e:	08000613          	li	a2,128
    80005d72:	f3040593          	addi	a1,s0,-208
    80005d76:	4501                	li	a0,0
    80005d78:	ffffd097          	auipc	ra,0xffffd
    80005d7c:	6a4080e7          	jalr	1700(ra) # 8000341c <argstr>
    80005d80:	18054163          	bltz	a0,80005f02 <sys_unlink+0x1a2>
  begin_op();
    80005d84:	fffff097          	auipc	ra,0xfffff
    80005d88:	c14080e7          	jalr	-1004(ra) # 80004998 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005d8c:	fb040593          	addi	a1,s0,-80
    80005d90:	f3040513          	addi	a0,s0,-208
    80005d94:	fffff097          	auipc	ra,0xfffff
    80005d98:	a06080e7          	jalr	-1530(ra) # 8000479a <nameiparent>
    80005d9c:	84aa                	mv	s1,a0
    80005d9e:	c979                	beqz	a0,80005e74 <sys_unlink+0x114>
  ilock(dp);
    80005da0:	ffffe097          	auipc	ra,0xffffe
    80005da4:	226080e7          	jalr	550(ra) # 80003fc6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005da8:	00003597          	auipc	a1,0x3
    80005dac:	c4858593          	addi	a1,a1,-952 # 800089f0 <syscalls+0x2c8>
    80005db0:	fb040513          	addi	a0,s0,-80
    80005db4:	ffffe097          	auipc	ra,0xffffe
    80005db8:	6dc080e7          	jalr	1756(ra) # 80004490 <namecmp>
    80005dbc:	14050a63          	beqz	a0,80005f10 <sys_unlink+0x1b0>
    80005dc0:	00003597          	auipc	a1,0x3
    80005dc4:	c3858593          	addi	a1,a1,-968 # 800089f8 <syscalls+0x2d0>
    80005dc8:	fb040513          	addi	a0,s0,-80
    80005dcc:	ffffe097          	auipc	ra,0xffffe
    80005dd0:	6c4080e7          	jalr	1732(ra) # 80004490 <namecmp>
    80005dd4:	12050e63          	beqz	a0,80005f10 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005dd8:	f2c40613          	addi	a2,s0,-212
    80005ddc:	fb040593          	addi	a1,s0,-80
    80005de0:	8526                	mv	a0,s1
    80005de2:	ffffe097          	auipc	ra,0xffffe
    80005de6:	6c8080e7          	jalr	1736(ra) # 800044aa <dirlookup>
    80005dea:	892a                	mv	s2,a0
    80005dec:	12050263          	beqz	a0,80005f10 <sys_unlink+0x1b0>
  ilock(ip);
    80005df0:	ffffe097          	auipc	ra,0xffffe
    80005df4:	1d6080e7          	jalr	470(ra) # 80003fc6 <ilock>
  if(ip->nlink < 1)
    80005df8:	04a91783          	lh	a5,74(s2)
    80005dfc:	08f05263          	blez	a5,80005e80 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005e00:	04491703          	lh	a4,68(s2)
    80005e04:	4785                	li	a5,1
    80005e06:	08f70563          	beq	a4,a5,80005e90 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005e0a:	4641                	li	a2,16
    80005e0c:	4581                	li	a1,0
    80005e0e:	fc040513          	addi	a0,s0,-64
    80005e12:	ffffb097          	auipc	ra,0xffffb
    80005e16:	ece080e7          	jalr	-306(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e1a:	4741                	li	a4,16
    80005e1c:	f2c42683          	lw	a3,-212(s0)
    80005e20:	fc040613          	addi	a2,s0,-64
    80005e24:	4581                	li	a1,0
    80005e26:	8526                	mv	a0,s1
    80005e28:	ffffe097          	auipc	ra,0xffffe
    80005e2c:	54a080e7          	jalr	1354(ra) # 80004372 <writei>
    80005e30:	47c1                	li	a5,16
    80005e32:	0af51563          	bne	a0,a5,80005edc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005e36:	04491703          	lh	a4,68(s2)
    80005e3a:	4785                	li	a5,1
    80005e3c:	0af70863          	beq	a4,a5,80005eec <sys_unlink+0x18c>
  iunlockput(dp);
    80005e40:	8526                	mv	a0,s1
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	3e6080e7          	jalr	998(ra) # 80004228 <iunlockput>
  ip->nlink--;
    80005e4a:	04a95783          	lhu	a5,74(s2)
    80005e4e:	37fd                	addiw	a5,a5,-1
    80005e50:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005e54:	854a                	mv	a0,s2
    80005e56:	ffffe097          	auipc	ra,0xffffe
    80005e5a:	0a6080e7          	jalr	166(ra) # 80003efc <iupdate>
  iunlockput(ip);
    80005e5e:	854a                	mv	a0,s2
    80005e60:	ffffe097          	auipc	ra,0xffffe
    80005e64:	3c8080e7          	jalr	968(ra) # 80004228 <iunlockput>
  end_op();
    80005e68:	fffff097          	auipc	ra,0xfffff
    80005e6c:	bb0080e7          	jalr	-1104(ra) # 80004a18 <end_op>
  return 0;
    80005e70:	4501                	li	a0,0
    80005e72:	a84d                	j	80005f24 <sys_unlink+0x1c4>
    end_op();
    80005e74:	fffff097          	auipc	ra,0xfffff
    80005e78:	ba4080e7          	jalr	-1116(ra) # 80004a18 <end_op>
    return -1;
    80005e7c:	557d                	li	a0,-1
    80005e7e:	a05d                	j	80005f24 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005e80:	00003517          	auipc	a0,0x3
    80005e84:	ba050513          	addi	a0,a0,-1120 # 80008a20 <syscalls+0x2f8>
    80005e88:	ffffa097          	auipc	ra,0xffffa
    80005e8c:	6b6080e7          	jalr	1718(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e90:	04c92703          	lw	a4,76(s2)
    80005e94:	02000793          	li	a5,32
    80005e98:	f6e7f9e3          	bgeu	a5,a4,80005e0a <sys_unlink+0xaa>
    80005e9c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ea0:	4741                	li	a4,16
    80005ea2:	86ce                	mv	a3,s3
    80005ea4:	f1840613          	addi	a2,s0,-232
    80005ea8:	4581                	li	a1,0
    80005eaa:	854a                	mv	a0,s2
    80005eac:	ffffe097          	auipc	ra,0xffffe
    80005eb0:	3ce080e7          	jalr	974(ra) # 8000427a <readi>
    80005eb4:	47c1                	li	a5,16
    80005eb6:	00f51b63          	bne	a0,a5,80005ecc <sys_unlink+0x16c>
    if(de.inum != 0)
    80005eba:	f1845783          	lhu	a5,-232(s0)
    80005ebe:	e7a1                	bnez	a5,80005f06 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ec0:	29c1                	addiw	s3,s3,16
    80005ec2:	04c92783          	lw	a5,76(s2)
    80005ec6:	fcf9ede3          	bltu	s3,a5,80005ea0 <sys_unlink+0x140>
    80005eca:	b781                	j	80005e0a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ecc:	00003517          	auipc	a0,0x3
    80005ed0:	b6c50513          	addi	a0,a0,-1172 # 80008a38 <syscalls+0x310>
    80005ed4:	ffffa097          	auipc	ra,0xffffa
    80005ed8:	66a080e7          	jalr	1642(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005edc:	00003517          	auipc	a0,0x3
    80005ee0:	b7450513          	addi	a0,a0,-1164 # 80008a50 <syscalls+0x328>
    80005ee4:	ffffa097          	auipc	ra,0xffffa
    80005ee8:	65a080e7          	jalr	1626(ra) # 8000053e <panic>
    dp->nlink--;
    80005eec:	04a4d783          	lhu	a5,74(s1)
    80005ef0:	37fd                	addiw	a5,a5,-1
    80005ef2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ef6:	8526                	mv	a0,s1
    80005ef8:	ffffe097          	auipc	ra,0xffffe
    80005efc:	004080e7          	jalr	4(ra) # 80003efc <iupdate>
    80005f00:	b781                	j	80005e40 <sys_unlink+0xe0>
    return -1;
    80005f02:	557d                	li	a0,-1
    80005f04:	a005                	j	80005f24 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005f06:	854a                	mv	a0,s2
    80005f08:	ffffe097          	auipc	ra,0xffffe
    80005f0c:	320080e7          	jalr	800(ra) # 80004228 <iunlockput>
  iunlockput(dp);
    80005f10:	8526                	mv	a0,s1
    80005f12:	ffffe097          	auipc	ra,0xffffe
    80005f16:	316080e7          	jalr	790(ra) # 80004228 <iunlockput>
  end_op();
    80005f1a:	fffff097          	auipc	ra,0xfffff
    80005f1e:	afe080e7          	jalr	-1282(ra) # 80004a18 <end_op>
  return -1;
    80005f22:	557d                	li	a0,-1
}
    80005f24:	70ae                	ld	ra,232(sp)
    80005f26:	740e                	ld	s0,224(sp)
    80005f28:	64ee                	ld	s1,216(sp)
    80005f2a:	694e                	ld	s2,208(sp)
    80005f2c:	69ae                	ld	s3,200(sp)
    80005f2e:	616d                	addi	sp,sp,240
    80005f30:	8082                	ret

0000000080005f32 <sys_open>:

uint64
sys_open(void)
{
    80005f32:	7131                	addi	sp,sp,-192
    80005f34:	fd06                	sd	ra,184(sp)
    80005f36:	f922                	sd	s0,176(sp)
    80005f38:	f526                	sd	s1,168(sp)
    80005f3a:	f14a                	sd	s2,160(sp)
    80005f3c:	ed4e                	sd	s3,152(sp)
    80005f3e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005f40:	08000613          	li	a2,128
    80005f44:	f5040593          	addi	a1,s0,-176
    80005f48:	4501                	li	a0,0
    80005f4a:	ffffd097          	auipc	ra,0xffffd
    80005f4e:	4d2080e7          	jalr	1234(ra) # 8000341c <argstr>
    return -1;
    80005f52:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005f54:	0c054163          	bltz	a0,80006016 <sys_open+0xe4>
    80005f58:	f4c40593          	addi	a1,s0,-180
    80005f5c:	4505                	li	a0,1
    80005f5e:	ffffd097          	auipc	ra,0xffffd
    80005f62:	47a080e7          	jalr	1146(ra) # 800033d8 <argint>
    80005f66:	0a054863          	bltz	a0,80006016 <sys_open+0xe4>

  begin_op();
    80005f6a:	fffff097          	auipc	ra,0xfffff
    80005f6e:	a2e080e7          	jalr	-1490(ra) # 80004998 <begin_op>

  if(omode & O_CREATE){
    80005f72:	f4c42783          	lw	a5,-180(s0)
    80005f76:	2007f793          	andi	a5,a5,512
    80005f7a:	cbdd                	beqz	a5,80006030 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005f7c:	4681                	li	a3,0
    80005f7e:	4601                	li	a2,0
    80005f80:	4589                	li	a1,2
    80005f82:	f5040513          	addi	a0,s0,-176
    80005f86:	00000097          	auipc	ra,0x0
    80005f8a:	972080e7          	jalr	-1678(ra) # 800058f8 <create>
    80005f8e:	892a                	mv	s2,a0
    if(ip == 0){
    80005f90:	c959                	beqz	a0,80006026 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005f92:	04491703          	lh	a4,68(s2)
    80005f96:	478d                	li	a5,3
    80005f98:	00f71763          	bne	a4,a5,80005fa6 <sys_open+0x74>
    80005f9c:	04695703          	lhu	a4,70(s2)
    80005fa0:	47a5                	li	a5,9
    80005fa2:	0ce7ec63          	bltu	a5,a4,8000607a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005fa6:	fffff097          	auipc	ra,0xfffff
    80005faa:	e02080e7          	jalr	-510(ra) # 80004da8 <filealloc>
    80005fae:	89aa                	mv	s3,a0
    80005fb0:	10050263          	beqz	a0,800060b4 <sys_open+0x182>
    80005fb4:	00000097          	auipc	ra,0x0
    80005fb8:	902080e7          	jalr	-1790(ra) # 800058b6 <fdalloc>
    80005fbc:	84aa                	mv	s1,a0
    80005fbe:	0e054663          	bltz	a0,800060aa <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005fc2:	04491703          	lh	a4,68(s2)
    80005fc6:	478d                	li	a5,3
    80005fc8:	0cf70463          	beq	a4,a5,80006090 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005fcc:	4789                	li	a5,2
    80005fce:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005fd2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005fd6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005fda:	f4c42783          	lw	a5,-180(s0)
    80005fde:	0017c713          	xori	a4,a5,1
    80005fe2:	8b05                	andi	a4,a4,1
    80005fe4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005fe8:	0037f713          	andi	a4,a5,3
    80005fec:	00e03733          	snez	a4,a4
    80005ff0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ff4:	4007f793          	andi	a5,a5,1024
    80005ff8:	c791                	beqz	a5,80006004 <sys_open+0xd2>
    80005ffa:	04491703          	lh	a4,68(s2)
    80005ffe:	4789                	li	a5,2
    80006000:	08f70f63          	beq	a4,a5,8000609e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006004:	854a                	mv	a0,s2
    80006006:	ffffe097          	auipc	ra,0xffffe
    8000600a:	082080e7          	jalr	130(ra) # 80004088 <iunlock>
  end_op();
    8000600e:	fffff097          	auipc	ra,0xfffff
    80006012:	a0a080e7          	jalr	-1526(ra) # 80004a18 <end_op>

  return fd;
}
    80006016:	8526                	mv	a0,s1
    80006018:	70ea                	ld	ra,184(sp)
    8000601a:	744a                	ld	s0,176(sp)
    8000601c:	74aa                	ld	s1,168(sp)
    8000601e:	790a                	ld	s2,160(sp)
    80006020:	69ea                	ld	s3,152(sp)
    80006022:	6129                	addi	sp,sp,192
    80006024:	8082                	ret
      end_op();
    80006026:	fffff097          	auipc	ra,0xfffff
    8000602a:	9f2080e7          	jalr	-1550(ra) # 80004a18 <end_op>
      return -1;
    8000602e:	b7e5                	j	80006016 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006030:	f5040513          	addi	a0,s0,-176
    80006034:	ffffe097          	auipc	ra,0xffffe
    80006038:	748080e7          	jalr	1864(ra) # 8000477c <namei>
    8000603c:	892a                	mv	s2,a0
    8000603e:	c905                	beqz	a0,8000606e <sys_open+0x13c>
    ilock(ip);
    80006040:	ffffe097          	auipc	ra,0xffffe
    80006044:	f86080e7          	jalr	-122(ra) # 80003fc6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006048:	04491703          	lh	a4,68(s2)
    8000604c:	4785                	li	a5,1
    8000604e:	f4f712e3          	bne	a4,a5,80005f92 <sys_open+0x60>
    80006052:	f4c42783          	lw	a5,-180(s0)
    80006056:	dba1                	beqz	a5,80005fa6 <sys_open+0x74>
      iunlockput(ip);
    80006058:	854a                	mv	a0,s2
    8000605a:	ffffe097          	auipc	ra,0xffffe
    8000605e:	1ce080e7          	jalr	462(ra) # 80004228 <iunlockput>
      end_op();
    80006062:	fffff097          	auipc	ra,0xfffff
    80006066:	9b6080e7          	jalr	-1610(ra) # 80004a18 <end_op>
      return -1;
    8000606a:	54fd                	li	s1,-1
    8000606c:	b76d                	j	80006016 <sys_open+0xe4>
      end_op();
    8000606e:	fffff097          	auipc	ra,0xfffff
    80006072:	9aa080e7          	jalr	-1622(ra) # 80004a18 <end_op>
      return -1;
    80006076:	54fd                	li	s1,-1
    80006078:	bf79                	j	80006016 <sys_open+0xe4>
    iunlockput(ip);
    8000607a:	854a                	mv	a0,s2
    8000607c:	ffffe097          	auipc	ra,0xffffe
    80006080:	1ac080e7          	jalr	428(ra) # 80004228 <iunlockput>
    end_op();
    80006084:	fffff097          	auipc	ra,0xfffff
    80006088:	994080e7          	jalr	-1644(ra) # 80004a18 <end_op>
    return -1;
    8000608c:	54fd                	li	s1,-1
    8000608e:	b761                	j	80006016 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006090:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006094:	04691783          	lh	a5,70(s2)
    80006098:	02f99223          	sh	a5,36(s3)
    8000609c:	bf2d                	j	80005fd6 <sys_open+0xa4>
    itrunc(ip);
    8000609e:	854a                	mv	a0,s2
    800060a0:	ffffe097          	auipc	ra,0xffffe
    800060a4:	034080e7          	jalr	52(ra) # 800040d4 <itrunc>
    800060a8:	bfb1                	j	80006004 <sys_open+0xd2>
      fileclose(f);
    800060aa:	854e                	mv	a0,s3
    800060ac:	fffff097          	auipc	ra,0xfffff
    800060b0:	db8080e7          	jalr	-584(ra) # 80004e64 <fileclose>
    iunlockput(ip);
    800060b4:	854a                	mv	a0,s2
    800060b6:	ffffe097          	auipc	ra,0xffffe
    800060ba:	172080e7          	jalr	370(ra) # 80004228 <iunlockput>
    end_op();
    800060be:	fffff097          	auipc	ra,0xfffff
    800060c2:	95a080e7          	jalr	-1702(ra) # 80004a18 <end_op>
    return -1;
    800060c6:	54fd                	li	s1,-1
    800060c8:	b7b9                	j	80006016 <sys_open+0xe4>

00000000800060ca <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800060ca:	7175                	addi	sp,sp,-144
    800060cc:	e506                	sd	ra,136(sp)
    800060ce:	e122                	sd	s0,128(sp)
    800060d0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800060d2:	fffff097          	auipc	ra,0xfffff
    800060d6:	8c6080e7          	jalr	-1850(ra) # 80004998 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800060da:	08000613          	li	a2,128
    800060de:	f7040593          	addi	a1,s0,-144
    800060e2:	4501                	li	a0,0
    800060e4:	ffffd097          	auipc	ra,0xffffd
    800060e8:	338080e7          	jalr	824(ra) # 8000341c <argstr>
    800060ec:	02054963          	bltz	a0,8000611e <sys_mkdir+0x54>
    800060f0:	4681                	li	a3,0
    800060f2:	4601                	li	a2,0
    800060f4:	4585                	li	a1,1
    800060f6:	f7040513          	addi	a0,s0,-144
    800060fa:	fffff097          	auipc	ra,0xfffff
    800060fe:	7fe080e7          	jalr	2046(ra) # 800058f8 <create>
    80006102:	cd11                	beqz	a0,8000611e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006104:	ffffe097          	auipc	ra,0xffffe
    80006108:	124080e7          	jalr	292(ra) # 80004228 <iunlockput>
  end_op();
    8000610c:	fffff097          	auipc	ra,0xfffff
    80006110:	90c080e7          	jalr	-1780(ra) # 80004a18 <end_op>
  return 0;
    80006114:	4501                	li	a0,0
}
    80006116:	60aa                	ld	ra,136(sp)
    80006118:	640a                	ld	s0,128(sp)
    8000611a:	6149                	addi	sp,sp,144
    8000611c:	8082                	ret
    end_op();
    8000611e:	fffff097          	auipc	ra,0xfffff
    80006122:	8fa080e7          	jalr	-1798(ra) # 80004a18 <end_op>
    return -1;
    80006126:	557d                	li	a0,-1
    80006128:	b7fd                	j	80006116 <sys_mkdir+0x4c>

000000008000612a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000612a:	7135                	addi	sp,sp,-160
    8000612c:	ed06                	sd	ra,152(sp)
    8000612e:	e922                	sd	s0,144(sp)
    80006130:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006132:	fffff097          	auipc	ra,0xfffff
    80006136:	866080e7          	jalr	-1946(ra) # 80004998 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000613a:	08000613          	li	a2,128
    8000613e:	f7040593          	addi	a1,s0,-144
    80006142:	4501                	li	a0,0
    80006144:	ffffd097          	auipc	ra,0xffffd
    80006148:	2d8080e7          	jalr	728(ra) # 8000341c <argstr>
    8000614c:	04054a63          	bltz	a0,800061a0 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006150:	f6c40593          	addi	a1,s0,-148
    80006154:	4505                	li	a0,1
    80006156:	ffffd097          	auipc	ra,0xffffd
    8000615a:	282080e7          	jalr	642(ra) # 800033d8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000615e:	04054163          	bltz	a0,800061a0 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006162:	f6840593          	addi	a1,s0,-152
    80006166:	4509                	li	a0,2
    80006168:	ffffd097          	auipc	ra,0xffffd
    8000616c:	270080e7          	jalr	624(ra) # 800033d8 <argint>
     argint(1, &major) < 0 ||
    80006170:	02054863          	bltz	a0,800061a0 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006174:	f6841683          	lh	a3,-152(s0)
    80006178:	f6c41603          	lh	a2,-148(s0)
    8000617c:	458d                	li	a1,3
    8000617e:	f7040513          	addi	a0,s0,-144
    80006182:	fffff097          	auipc	ra,0xfffff
    80006186:	776080e7          	jalr	1910(ra) # 800058f8 <create>
     argint(2, &minor) < 0 ||
    8000618a:	c919                	beqz	a0,800061a0 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000618c:	ffffe097          	auipc	ra,0xffffe
    80006190:	09c080e7          	jalr	156(ra) # 80004228 <iunlockput>
  end_op();
    80006194:	fffff097          	auipc	ra,0xfffff
    80006198:	884080e7          	jalr	-1916(ra) # 80004a18 <end_op>
  return 0;
    8000619c:	4501                	li	a0,0
    8000619e:	a031                	j	800061aa <sys_mknod+0x80>
    end_op();
    800061a0:	fffff097          	auipc	ra,0xfffff
    800061a4:	878080e7          	jalr	-1928(ra) # 80004a18 <end_op>
    return -1;
    800061a8:	557d                	li	a0,-1
}
    800061aa:	60ea                	ld	ra,152(sp)
    800061ac:	644a                	ld	s0,144(sp)
    800061ae:	610d                	addi	sp,sp,160
    800061b0:	8082                	ret

00000000800061b2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800061b2:	7135                	addi	sp,sp,-160
    800061b4:	ed06                	sd	ra,152(sp)
    800061b6:	e922                	sd	s0,144(sp)
    800061b8:	e526                	sd	s1,136(sp)
    800061ba:	e14a                	sd	s2,128(sp)
    800061bc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800061be:	ffffc097          	auipc	ra,0xffffc
    800061c2:	d06080e7          	jalr	-762(ra) # 80001ec4 <myproc>
    800061c6:	892a                	mv	s2,a0
  
  begin_op();
    800061c8:	ffffe097          	auipc	ra,0xffffe
    800061cc:	7d0080e7          	jalr	2000(ra) # 80004998 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800061d0:	08000613          	li	a2,128
    800061d4:	f6040593          	addi	a1,s0,-160
    800061d8:	4501                	li	a0,0
    800061da:	ffffd097          	auipc	ra,0xffffd
    800061de:	242080e7          	jalr	578(ra) # 8000341c <argstr>
    800061e2:	04054b63          	bltz	a0,80006238 <sys_chdir+0x86>
    800061e6:	f6040513          	addi	a0,s0,-160
    800061ea:	ffffe097          	auipc	ra,0xffffe
    800061ee:	592080e7          	jalr	1426(ra) # 8000477c <namei>
    800061f2:	84aa                	mv	s1,a0
    800061f4:	c131                	beqz	a0,80006238 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800061f6:	ffffe097          	auipc	ra,0xffffe
    800061fa:	dd0080e7          	jalr	-560(ra) # 80003fc6 <ilock>
  if(ip->type != T_DIR){
    800061fe:	04449703          	lh	a4,68(s1)
    80006202:	4785                	li	a5,1
    80006204:	04f71063          	bne	a4,a5,80006244 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006208:	8526                	mv	a0,s1
    8000620a:	ffffe097          	auipc	ra,0xffffe
    8000620e:	e7e080e7          	jalr	-386(ra) # 80004088 <iunlock>
  iput(p->cwd);
    80006212:	15093503          	ld	a0,336(s2)
    80006216:	ffffe097          	auipc	ra,0xffffe
    8000621a:	f6a080e7          	jalr	-150(ra) # 80004180 <iput>
  end_op();
    8000621e:	ffffe097          	auipc	ra,0xffffe
    80006222:	7fa080e7          	jalr	2042(ra) # 80004a18 <end_op>
  p->cwd = ip;
    80006226:	14993823          	sd	s1,336(s2)
  return 0;
    8000622a:	4501                	li	a0,0
}
    8000622c:	60ea                	ld	ra,152(sp)
    8000622e:	644a                	ld	s0,144(sp)
    80006230:	64aa                	ld	s1,136(sp)
    80006232:	690a                	ld	s2,128(sp)
    80006234:	610d                	addi	sp,sp,160
    80006236:	8082                	ret
    end_op();
    80006238:	ffffe097          	auipc	ra,0xffffe
    8000623c:	7e0080e7          	jalr	2016(ra) # 80004a18 <end_op>
    return -1;
    80006240:	557d                	li	a0,-1
    80006242:	b7ed                	j	8000622c <sys_chdir+0x7a>
    iunlockput(ip);
    80006244:	8526                	mv	a0,s1
    80006246:	ffffe097          	auipc	ra,0xffffe
    8000624a:	fe2080e7          	jalr	-30(ra) # 80004228 <iunlockput>
    end_op();
    8000624e:	ffffe097          	auipc	ra,0xffffe
    80006252:	7ca080e7          	jalr	1994(ra) # 80004a18 <end_op>
    return -1;
    80006256:	557d                	li	a0,-1
    80006258:	bfd1                	j	8000622c <sys_chdir+0x7a>

000000008000625a <sys_exec>:

uint64
sys_exec(void)
{
    8000625a:	7145                	addi	sp,sp,-464
    8000625c:	e786                	sd	ra,456(sp)
    8000625e:	e3a2                	sd	s0,448(sp)
    80006260:	ff26                	sd	s1,440(sp)
    80006262:	fb4a                	sd	s2,432(sp)
    80006264:	f74e                	sd	s3,424(sp)
    80006266:	f352                	sd	s4,416(sp)
    80006268:	ef56                	sd	s5,408(sp)
    8000626a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000626c:	08000613          	li	a2,128
    80006270:	f4040593          	addi	a1,s0,-192
    80006274:	4501                	li	a0,0
    80006276:	ffffd097          	auipc	ra,0xffffd
    8000627a:	1a6080e7          	jalr	422(ra) # 8000341c <argstr>
    return -1;
    8000627e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006280:	0c054a63          	bltz	a0,80006354 <sys_exec+0xfa>
    80006284:	e3840593          	addi	a1,s0,-456
    80006288:	4505                	li	a0,1
    8000628a:	ffffd097          	auipc	ra,0xffffd
    8000628e:	170080e7          	jalr	368(ra) # 800033fa <argaddr>
    80006292:	0c054163          	bltz	a0,80006354 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006296:	10000613          	li	a2,256
    8000629a:	4581                	li	a1,0
    8000629c:	e4040513          	addi	a0,s0,-448
    800062a0:	ffffb097          	auipc	ra,0xffffb
    800062a4:	a40080e7          	jalr	-1472(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800062a8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800062ac:	89a6                	mv	s3,s1
    800062ae:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800062b0:	02000a13          	li	s4,32
    800062b4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800062b8:	00391513          	slli	a0,s2,0x3
    800062bc:	e3040593          	addi	a1,s0,-464
    800062c0:	e3843783          	ld	a5,-456(s0)
    800062c4:	953e                	add	a0,a0,a5
    800062c6:	ffffd097          	auipc	ra,0xffffd
    800062ca:	078080e7          	jalr	120(ra) # 8000333e <fetchaddr>
    800062ce:	02054a63          	bltz	a0,80006302 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800062d2:	e3043783          	ld	a5,-464(s0)
    800062d6:	c3b9                	beqz	a5,8000631c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800062d8:	ffffb097          	auipc	ra,0xffffb
    800062dc:	81c080e7          	jalr	-2020(ra) # 80000af4 <kalloc>
    800062e0:	85aa                	mv	a1,a0
    800062e2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800062e6:	cd11                	beqz	a0,80006302 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800062e8:	6605                	lui	a2,0x1
    800062ea:	e3043503          	ld	a0,-464(s0)
    800062ee:	ffffd097          	auipc	ra,0xffffd
    800062f2:	0a2080e7          	jalr	162(ra) # 80003390 <fetchstr>
    800062f6:	00054663          	bltz	a0,80006302 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800062fa:	0905                	addi	s2,s2,1
    800062fc:	09a1                	addi	s3,s3,8
    800062fe:	fb491be3          	bne	s2,s4,800062b4 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006302:	10048913          	addi	s2,s1,256
    80006306:	6088                	ld	a0,0(s1)
    80006308:	c529                	beqz	a0,80006352 <sys_exec+0xf8>
    kfree(argv[i]);
    8000630a:	ffffa097          	auipc	ra,0xffffa
    8000630e:	6ee080e7          	jalr	1774(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006312:	04a1                	addi	s1,s1,8
    80006314:	ff2499e3          	bne	s1,s2,80006306 <sys_exec+0xac>
  return -1;
    80006318:	597d                	li	s2,-1
    8000631a:	a82d                	j	80006354 <sys_exec+0xfa>
      argv[i] = 0;
    8000631c:	0a8e                	slli	s5,s5,0x3
    8000631e:	fc040793          	addi	a5,s0,-64
    80006322:	9abe                	add	s5,s5,a5
    80006324:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006328:	e4040593          	addi	a1,s0,-448
    8000632c:	f4040513          	addi	a0,s0,-192
    80006330:	fffff097          	auipc	ra,0xfffff
    80006334:	194080e7          	jalr	404(ra) # 800054c4 <exec>
    80006338:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000633a:	10048993          	addi	s3,s1,256
    8000633e:	6088                	ld	a0,0(s1)
    80006340:	c911                	beqz	a0,80006354 <sys_exec+0xfa>
    kfree(argv[i]);
    80006342:	ffffa097          	auipc	ra,0xffffa
    80006346:	6b6080e7          	jalr	1718(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000634a:	04a1                	addi	s1,s1,8
    8000634c:	ff3499e3          	bne	s1,s3,8000633e <sys_exec+0xe4>
    80006350:	a011                	j	80006354 <sys_exec+0xfa>
  return -1;
    80006352:	597d                	li	s2,-1
}
    80006354:	854a                	mv	a0,s2
    80006356:	60be                	ld	ra,456(sp)
    80006358:	641e                	ld	s0,448(sp)
    8000635a:	74fa                	ld	s1,440(sp)
    8000635c:	795a                	ld	s2,432(sp)
    8000635e:	79ba                	ld	s3,424(sp)
    80006360:	7a1a                	ld	s4,416(sp)
    80006362:	6afa                	ld	s5,408(sp)
    80006364:	6179                	addi	sp,sp,464
    80006366:	8082                	ret

0000000080006368 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006368:	7139                	addi	sp,sp,-64
    8000636a:	fc06                	sd	ra,56(sp)
    8000636c:	f822                	sd	s0,48(sp)
    8000636e:	f426                	sd	s1,40(sp)
    80006370:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006372:	ffffc097          	auipc	ra,0xffffc
    80006376:	b52080e7          	jalr	-1198(ra) # 80001ec4 <myproc>
    8000637a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000637c:	fd840593          	addi	a1,s0,-40
    80006380:	4501                	li	a0,0
    80006382:	ffffd097          	auipc	ra,0xffffd
    80006386:	078080e7          	jalr	120(ra) # 800033fa <argaddr>
    return -1;
    8000638a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000638c:	0e054063          	bltz	a0,8000646c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006390:	fc840593          	addi	a1,s0,-56
    80006394:	fd040513          	addi	a0,s0,-48
    80006398:	fffff097          	auipc	ra,0xfffff
    8000639c:	dfc080e7          	jalr	-516(ra) # 80005194 <pipealloc>
    return -1;
    800063a0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800063a2:	0c054563          	bltz	a0,8000646c <sys_pipe+0x104>
  fd0 = -1;
    800063a6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800063aa:	fd043503          	ld	a0,-48(s0)
    800063ae:	fffff097          	auipc	ra,0xfffff
    800063b2:	508080e7          	jalr	1288(ra) # 800058b6 <fdalloc>
    800063b6:	fca42223          	sw	a0,-60(s0)
    800063ba:	08054c63          	bltz	a0,80006452 <sys_pipe+0xea>
    800063be:	fc843503          	ld	a0,-56(s0)
    800063c2:	fffff097          	auipc	ra,0xfffff
    800063c6:	4f4080e7          	jalr	1268(ra) # 800058b6 <fdalloc>
    800063ca:	fca42023          	sw	a0,-64(s0)
    800063ce:	06054863          	bltz	a0,8000643e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800063d2:	4691                	li	a3,4
    800063d4:	fc440613          	addi	a2,s0,-60
    800063d8:	fd843583          	ld	a1,-40(s0)
    800063dc:	68a8                	ld	a0,80(s1)
    800063de:	ffffb097          	auipc	ra,0xffffb
    800063e2:	294080e7          	jalr	660(ra) # 80001672 <copyout>
    800063e6:	02054063          	bltz	a0,80006406 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800063ea:	4691                	li	a3,4
    800063ec:	fc040613          	addi	a2,s0,-64
    800063f0:	fd843583          	ld	a1,-40(s0)
    800063f4:	0591                	addi	a1,a1,4
    800063f6:	68a8                	ld	a0,80(s1)
    800063f8:	ffffb097          	auipc	ra,0xffffb
    800063fc:	27a080e7          	jalr	634(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006400:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006402:	06055563          	bgez	a0,8000646c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006406:	fc442783          	lw	a5,-60(s0)
    8000640a:	07e9                	addi	a5,a5,26
    8000640c:	078e                	slli	a5,a5,0x3
    8000640e:	97a6                	add	a5,a5,s1
    80006410:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006414:	fc042503          	lw	a0,-64(s0)
    80006418:	0569                	addi	a0,a0,26
    8000641a:	050e                	slli	a0,a0,0x3
    8000641c:	9526                	add	a0,a0,s1
    8000641e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006422:	fd043503          	ld	a0,-48(s0)
    80006426:	fffff097          	auipc	ra,0xfffff
    8000642a:	a3e080e7          	jalr	-1474(ra) # 80004e64 <fileclose>
    fileclose(wf);
    8000642e:	fc843503          	ld	a0,-56(s0)
    80006432:	fffff097          	auipc	ra,0xfffff
    80006436:	a32080e7          	jalr	-1486(ra) # 80004e64 <fileclose>
    return -1;
    8000643a:	57fd                	li	a5,-1
    8000643c:	a805                	j	8000646c <sys_pipe+0x104>
    if(fd0 >= 0)
    8000643e:	fc442783          	lw	a5,-60(s0)
    80006442:	0007c863          	bltz	a5,80006452 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006446:	01a78513          	addi	a0,a5,26
    8000644a:	050e                	slli	a0,a0,0x3
    8000644c:	9526                	add	a0,a0,s1
    8000644e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006452:	fd043503          	ld	a0,-48(s0)
    80006456:	fffff097          	auipc	ra,0xfffff
    8000645a:	a0e080e7          	jalr	-1522(ra) # 80004e64 <fileclose>
    fileclose(wf);
    8000645e:	fc843503          	ld	a0,-56(s0)
    80006462:	fffff097          	auipc	ra,0xfffff
    80006466:	a02080e7          	jalr	-1534(ra) # 80004e64 <fileclose>
    return -1;
    8000646a:	57fd                	li	a5,-1
}
    8000646c:	853e                	mv	a0,a5
    8000646e:	70e2                	ld	ra,56(sp)
    80006470:	7442                	ld	s0,48(sp)
    80006472:	74a2                	ld	s1,40(sp)
    80006474:	6121                	addi	sp,sp,64
    80006476:	8082                	ret
	...

0000000080006480 <kernelvec>:
    80006480:	7111                	addi	sp,sp,-256
    80006482:	e006                	sd	ra,0(sp)
    80006484:	e40a                	sd	sp,8(sp)
    80006486:	e80e                	sd	gp,16(sp)
    80006488:	ec12                	sd	tp,24(sp)
    8000648a:	f016                	sd	t0,32(sp)
    8000648c:	f41a                	sd	t1,40(sp)
    8000648e:	f81e                	sd	t2,48(sp)
    80006490:	fc22                	sd	s0,56(sp)
    80006492:	e0a6                	sd	s1,64(sp)
    80006494:	e4aa                	sd	a0,72(sp)
    80006496:	e8ae                	sd	a1,80(sp)
    80006498:	ecb2                	sd	a2,88(sp)
    8000649a:	f0b6                	sd	a3,96(sp)
    8000649c:	f4ba                	sd	a4,104(sp)
    8000649e:	f8be                	sd	a5,112(sp)
    800064a0:	fcc2                	sd	a6,120(sp)
    800064a2:	e146                	sd	a7,128(sp)
    800064a4:	e54a                	sd	s2,136(sp)
    800064a6:	e94e                	sd	s3,144(sp)
    800064a8:	ed52                	sd	s4,152(sp)
    800064aa:	f156                	sd	s5,160(sp)
    800064ac:	f55a                	sd	s6,168(sp)
    800064ae:	f95e                	sd	s7,176(sp)
    800064b0:	fd62                	sd	s8,184(sp)
    800064b2:	e1e6                	sd	s9,192(sp)
    800064b4:	e5ea                	sd	s10,200(sp)
    800064b6:	e9ee                	sd	s11,208(sp)
    800064b8:	edf2                	sd	t3,216(sp)
    800064ba:	f1f6                	sd	t4,224(sp)
    800064bc:	f5fa                	sd	t5,232(sp)
    800064be:	f9fe                	sd	t6,240(sp)
    800064c0:	d4bfc0ef          	jal	ra,8000320a <kerneltrap>
    800064c4:	6082                	ld	ra,0(sp)
    800064c6:	6122                	ld	sp,8(sp)
    800064c8:	61c2                	ld	gp,16(sp)
    800064ca:	7282                	ld	t0,32(sp)
    800064cc:	7322                	ld	t1,40(sp)
    800064ce:	73c2                	ld	t2,48(sp)
    800064d0:	7462                	ld	s0,56(sp)
    800064d2:	6486                	ld	s1,64(sp)
    800064d4:	6526                	ld	a0,72(sp)
    800064d6:	65c6                	ld	a1,80(sp)
    800064d8:	6666                	ld	a2,88(sp)
    800064da:	7686                	ld	a3,96(sp)
    800064dc:	7726                	ld	a4,104(sp)
    800064de:	77c6                	ld	a5,112(sp)
    800064e0:	7866                	ld	a6,120(sp)
    800064e2:	688a                	ld	a7,128(sp)
    800064e4:	692a                	ld	s2,136(sp)
    800064e6:	69ca                	ld	s3,144(sp)
    800064e8:	6a6a                	ld	s4,152(sp)
    800064ea:	7a8a                	ld	s5,160(sp)
    800064ec:	7b2a                	ld	s6,168(sp)
    800064ee:	7bca                	ld	s7,176(sp)
    800064f0:	7c6a                	ld	s8,184(sp)
    800064f2:	6c8e                	ld	s9,192(sp)
    800064f4:	6d2e                	ld	s10,200(sp)
    800064f6:	6dce                	ld	s11,208(sp)
    800064f8:	6e6e                	ld	t3,216(sp)
    800064fa:	7e8e                	ld	t4,224(sp)
    800064fc:	7f2e                	ld	t5,232(sp)
    800064fe:	7fce                	ld	t6,240(sp)
    80006500:	6111                	addi	sp,sp,256
    80006502:	10200073          	sret
    80006506:	00000013          	nop
    8000650a:	00000013          	nop
    8000650e:	0001                	nop

0000000080006510 <timervec>:
    80006510:	34051573          	csrrw	a0,mscratch,a0
    80006514:	e10c                	sd	a1,0(a0)
    80006516:	e510                	sd	a2,8(a0)
    80006518:	e914                	sd	a3,16(a0)
    8000651a:	6d0c                	ld	a1,24(a0)
    8000651c:	7110                	ld	a2,32(a0)
    8000651e:	6194                	ld	a3,0(a1)
    80006520:	96b2                	add	a3,a3,a2
    80006522:	e194                	sd	a3,0(a1)
    80006524:	4589                	li	a1,2
    80006526:	14459073          	csrw	sip,a1
    8000652a:	6914                	ld	a3,16(a0)
    8000652c:	6510                	ld	a2,8(a0)
    8000652e:	610c                	ld	a1,0(a0)
    80006530:	34051573          	csrrw	a0,mscratch,a0
    80006534:	30200073          	mret
	...

000000008000653a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000653a:	1141                	addi	sp,sp,-16
    8000653c:	e422                	sd	s0,8(sp)
    8000653e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006540:	0c0007b7          	lui	a5,0xc000
    80006544:	4705                	li	a4,1
    80006546:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006548:	c3d8                	sw	a4,4(a5)
}
    8000654a:	6422                	ld	s0,8(sp)
    8000654c:	0141                	addi	sp,sp,16
    8000654e:	8082                	ret

0000000080006550 <plicinithart>:

void
plicinithart(void)
{
    80006550:	1141                	addi	sp,sp,-16
    80006552:	e406                	sd	ra,8(sp)
    80006554:	e022                	sd	s0,0(sp)
    80006556:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006558:	ffffc097          	auipc	ra,0xffffc
    8000655c:	93a080e7          	jalr	-1734(ra) # 80001e92 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006560:	0085171b          	slliw	a4,a0,0x8
    80006564:	0c0027b7          	lui	a5,0xc002
    80006568:	97ba                	add	a5,a5,a4
    8000656a:	40200713          	li	a4,1026
    8000656e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006572:	00d5151b          	slliw	a0,a0,0xd
    80006576:	0c2017b7          	lui	a5,0xc201
    8000657a:	953e                	add	a0,a0,a5
    8000657c:	00052023          	sw	zero,0(a0)
}
    80006580:	60a2                	ld	ra,8(sp)
    80006582:	6402                	ld	s0,0(sp)
    80006584:	0141                	addi	sp,sp,16
    80006586:	8082                	ret

0000000080006588 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006588:	1141                	addi	sp,sp,-16
    8000658a:	e406                	sd	ra,8(sp)
    8000658c:	e022                	sd	s0,0(sp)
    8000658e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006590:	ffffc097          	auipc	ra,0xffffc
    80006594:	902080e7          	jalr	-1790(ra) # 80001e92 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006598:	00d5179b          	slliw	a5,a0,0xd
    8000659c:	0c201537          	lui	a0,0xc201
    800065a0:	953e                	add	a0,a0,a5
  return irq;
}
    800065a2:	4148                	lw	a0,4(a0)
    800065a4:	60a2                	ld	ra,8(sp)
    800065a6:	6402                	ld	s0,0(sp)
    800065a8:	0141                	addi	sp,sp,16
    800065aa:	8082                	ret

00000000800065ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800065ac:	1101                	addi	sp,sp,-32
    800065ae:	ec06                	sd	ra,24(sp)
    800065b0:	e822                	sd	s0,16(sp)
    800065b2:	e426                	sd	s1,8(sp)
    800065b4:	1000                	addi	s0,sp,32
    800065b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800065b8:	ffffc097          	auipc	ra,0xffffc
    800065bc:	8da080e7          	jalr	-1830(ra) # 80001e92 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800065c0:	00d5151b          	slliw	a0,a0,0xd
    800065c4:	0c2017b7          	lui	a5,0xc201
    800065c8:	97aa                	add	a5,a5,a0
    800065ca:	c3c4                	sw	s1,4(a5)
}
    800065cc:	60e2                	ld	ra,24(sp)
    800065ce:	6442                	ld	s0,16(sp)
    800065d0:	64a2                	ld	s1,8(sp)
    800065d2:	6105                	addi	sp,sp,32
    800065d4:	8082                	ret

00000000800065d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800065d6:	1141                	addi	sp,sp,-16
    800065d8:	e406                	sd	ra,8(sp)
    800065da:	e022                	sd	s0,0(sp)
    800065dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800065de:	479d                	li	a5,7
    800065e0:	06a7c963          	blt	a5,a0,80006652 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800065e4:	0001d797          	auipc	a5,0x1d
    800065e8:	a1c78793          	addi	a5,a5,-1508 # 80023000 <disk>
    800065ec:	00a78733          	add	a4,a5,a0
    800065f0:	6789                	lui	a5,0x2
    800065f2:	97ba                	add	a5,a5,a4
    800065f4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800065f8:	e7ad                	bnez	a5,80006662 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800065fa:	00451793          	slli	a5,a0,0x4
    800065fe:	0001f717          	auipc	a4,0x1f
    80006602:	a0270713          	addi	a4,a4,-1534 # 80025000 <disk+0x2000>
    80006606:	6314                	ld	a3,0(a4)
    80006608:	96be                	add	a3,a3,a5
    8000660a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000660e:	6314                	ld	a3,0(a4)
    80006610:	96be                	add	a3,a3,a5
    80006612:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006616:	6314                	ld	a3,0(a4)
    80006618:	96be                	add	a3,a3,a5
    8000661a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000661e:	6318                	ld	a4,0(a4)
    80006620:	97ba                	add	a5,a5,a4
    80006622:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006626:	0001d797          	auipc	a5,0x1d
    8000662a:	9da78793          	addi	a5,a5,-1574 # 80023000 <disk>
    8000662e:	97aa                	add	a5,a5,a0
    80006630:	6509                	lui	a0,0x2
    80006632:	953e                	add	a0,a0,a5
    80006634:	4785                	li	a5,1
    80006636:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000663a:	0001f517          	auipc	a0,0x1f
    8000663e:	9de50513          	addi	a0,a0,-1570 # 80025018 <disk+0x2018>
    80006642:	ffffc097          	auipc	ra,0xffffc
    80006646:	606080e7          	jalr	1542(ra) # 80002c48 <wakeup>
}
    8000664a:	60a2                	ld	ra,8(sp)
    8000664c:	6402                	ld	s0,0(sp)
    8000664e:	0141                	addi	sp,sp,16
    80006650:	8082                	ret
    panic("free_desc 1");
    80006652:	00002517          	auipc	a0,0x2
    80006656:	40e50513          	addi	a0,a0,1038 # 80008a60 <syscalls+0x338>
    8000665a:	ffffa097          	auipc	ra,0xffffa
    8000665e:	ee4080e7          	jalr	-284(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006662:	00002517          	auipc	a0,0x2
    80006666:	40e50513          	addi	a0,a0,1038 # 80008a70 <syscalls+0x348>
    8000666a:	ffffa097          	auipc	ra,0xffffa
    8000666e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080006672 <virtio_disk_init>:
{
    80006672:	1101                	addi	sp,sp,-32
    80006674:	ec06                	sd	ra,24(sp)
    80006676:	e822                	sd	s0,16(sp)
    80006678:	e426                	sd	s1,8(sp)
    8000667a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000667c:	00002597          	auipc	a1,0x2
    80006680:	40458593          	addi	a1,a1,1028 # 80008a80 <syscalls+0x358>
    80006684:	0001f517          	auipc	a0,0x1f
    80006688:	aa450513          	addi	a0,a0,-1372 # 80025128 <disk+0x2128>
    8000668c:	ffffa097          	auipc	ra,0xffffa
    80006690:	4c8080e7          	jalr	1224(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006694:	100017b7          	lui	a5,0x10001
    80006698:	4398                	lw	a4,0(a5)
    8000669a:	2701                	sext.w	a4,a4
    8000669c:	747277b7          	lui	a5,0x74727
    800066a0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800066a4:	0ef71163          	bne	a4,a5,80006786 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800066a8:	100017b7          	lui	a5,0x10001
    800066ac:	43dc                	lw	a5,4(a5)
    800066ae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800066b0:	4705                	li	a4,1
    800066b2:	0ce79a63          	bne	a5,a4,80006786 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800066b6:	100017b7          	lui	a5,0x10001
    800066ba:	479c                	lw	a5,8(a5)
    800066bc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800066be:	4709                	li	a4,2
    800066c0:	0ce79363          	bne	a5,a4,80006786 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800066c4:	100017b7          	lui	a5,0x10001
    800066c8:	47d8                	lw	a4,12(a5)
    800066ca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800066cc:	554d47b7          	lui	a5,0x554d4
    800066d0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800066d4:	0af71963          	bne	a4,a5,80006786 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800066d8:	100017b7          	lui	a5,0x10001
    800066dc:	4705                	li	a4,1
    800066de:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800066e0:	470d                	li	a4,3
    800066e2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800066e4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800066e6:	c7ffe737          	lui	a4,0xc7ffe
    800066ea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800066ee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800066f0:	2701                	sext.w	a4,a4
    800066f2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800066f4:	472d                	li	a4,11
    800066f6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800066f8:	473d                	li	a4,15
    800066fa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800066fc:	6705                	lui	a4,0x1
    800066fe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006700:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006704:	5bdc                	lw	a5,52(a5)
    80006706:	2781                	sext.w	a5,a5
  if(max == 0)
    80006708:	c7d9                	beqz	a5,80006796 <virtio_disk_init+0x124>
  if(max < NUM)
    8000670a:	471d                	li	a4,7
    8000670c:	08f77d63          	bgeu	a4,a5,800067a6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006710:	100014b7          	lui	s1,0x10001
    80006714:	47a1                	li	a5,8
    80006716:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006718:	6609                	lui	a2,0x2
    8000671a:	4581                	li	a1,0
    8000671c:	0001d517          	auipc	a0,0x1d
    80006720:	8e450513          	addi	a0,a0,-1820 # 80023000 <disk>
    80006724:	ffffa097          	auipc	ra,0xffffa
    80006728:	5bc080e7          	jalr	1468(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000672c:	0001d717          	auipc	a4,0x1d
    80006730:	8d470713          	addi	a4,a4,-1836 # 80023000 <disk>
    80006734:	00c75793          	srli	a5,a4,0xc
    80006738:	2781                	sext.w	a5,a5
    8000673a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000673c:	0001f797          	auipc	a5,0x1f
    80006740:	8c478793          	addi	a5,a5,-1852 # 80025000 <disk+0x2000>
    80006744:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006746:	0001d717          	auipc	a4,0x1d
    8000674a:	93a70713          	addi	a4,a4,-1734 # 80023080 <disk+0x80>
    8000674e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006750:	0001e717          	auipc	a4,0x1e
    80006754:	8b070713          	addi	a4,a4,-1872 # 80024000 <disk+0x1000>
    80006758:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000675a:	4705                	li	a4,1
    8000675c:	00e78c23          	sb	a4,24(a5)
    80006760:	00e78ca3          	sb	a4,25(a5)
    80006764:	00e78d23          	sb	a4,26(a5)
    80006768:	00e78da3          	sb	a4,27(a5)
    8000676c:	00e78e23          	sb	a4,28(a5)
    80006770:	00e78ea3          	sb	a4,29(a5)
    80006774:	00e78f23          	sb	a4,30(a5)
    80006778:	00e78fa3          	sb	a4,31(a5)
}
    8000677c:	60e2                	ld	ra,24(sp)
    8000677e:	6442                	ld	s0,16(sp)
    80006780:	64a2                	ld	s1,8(sp)
    80006782:	6105                	addi	sp,sp,32
    80006784:	8082                	ret
    panic("could not find virtio disk");
    80006786:	00002517          	auipc	a0,0x2
    8000678a:	30a50513          	addi	a0,a0,778 # 80008a90 <syscalls+0x368>
    8000678e:	ffffa097          	auipc	ra,0xffffa
    80006792:	db0080e7          	jalr	-592(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006796:	00002517          	auipc	a0,0x2
    8000679a:	31a50513          	addi	a0,a0,794 # 80008ab0 <syscalls+0x388>
    8000679e:	ffffa097          	auipc	ra,0xffffa
    800067a2:	da0080e7          	jalr	-608(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800067a6:	00002517          	auipc	a0,0x2
    800067aa:	32a50513          	addi	a0,a0,810 # 80008ad0 <syscalls+0x3a8>
    800067ae:	ffffa097          	auipc	ra,0xffffa
    800067b2:	d90080e7          	jalr	-624(ra) # 8000053e <panic>

00000000800067b6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800067b6:	7159                	addi	sp,sp,-112
    800067b8:	f486                	sd	ra,104(sp)
    800067ba:	f0a2                	sd	s0,96(sp)
    800067bc:	eca6                	sd	s1,88(sp)
    800067be:	e8ca                	sd	s2,80(sp)
    800067c0:	e4ce                	sd	s3,72(sp)
    800067c2:	e0d2                	sd	s4,64(sp)
    800067c4:	fc56                	sd	s5,56(sp)
    800067c6:	f85a                	sd	s6,48(sp)
    800067c8:	f45e                	sd	s7,40(sp)
    800067ca:	f062                	sd	s8,32(sp)
    800067cc:	ec66                	sd	s9,24(sp)
    800067ce:	e86a                	sd	s10,16(sp)
    800067d0:	1880                	addi	s0,sp,112
    800067d2:	892a                	mv	s2,a0
    800067d4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800067d6:	00c52c83          	lw	s9,12(a0)
    800067da:	001c9c9b          	slliw	s9,s9,0x1
    800067de:	1c82                	slli	s9,s9,0x20
    800067e0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800067e4:	0001f517          	auipc	a0,0x1f
    800067e8:	94450513          	addi	a0,a0,-1724 # 80025128 <disk+0x2128>
    800067ec:	ffffa097          	auipc	ra,0xffffa
    800067f0:	3f8080e7          	jalr	1016(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800067f4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800067f6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800067f8:	0001db97          	auipc	s7,0x1d
    800067fc:	808b8b93          	addi	s7,s7,-2040 # 80023000 <disk>
    80006800:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006802:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006804:	8a4e                	mv	s4,s3
    80006806:	a051                	j	8000688a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006808:	00fb86b3          	add	a3,s7,a5
    8000680c:	96da                	add	a3,a3,s6
    8000680e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006812:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006814:	0207c563          	bltz	a5,8000683e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006818:	2485                	addiw	s1,s1,1
    8000681a:	0711                	addi	a4,a4,4
    8000681c:	25548063          	beq	s1,s5,80006a5c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006820:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006822:	0001e697          	auipc	a3,0x1e
    80006826:	7f668693          	addi	a3,a3,2038 # 80025018 <disk+0x2018>
    8000682a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000682c:	0006c583          	lbu	a1,0(a3)
    80006830:	fde1                	bnez	a1,80006808 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006832:	2785                	addiw	a5,a5,1
    80006834:	0685                	addi	a3,a3,1
    80006836:	ff879be3          	bne	a5,s8,8000682c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000683a:	57fd                	li	a5,-1
    8000683c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000683e:	02905a63          	blez	s1,80006872 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006842:	f9042503          	lw	a0,-112(s0)
    80006846:	00000097          	auipc	ra,0x0
    8000684a:	d90080e7          	jalr	-624(ra) # 800065d6 <free_desc>
      for(int j = 0; j < i; j++)
    8000684e:	4785                	li	a5,1
    80006850:	0297d163          	bge	a5,s1,80006872 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006854:	f9442503          	lw	a0,-108(s0)
    80006858:	00000097          	auipc	ra,0x0
    8000685c:	d7e080e7          	jalr	-642(ra) # 800065d6 <free_desc>
      for(int j = 0; j < i; j++)
    80006860:	4789                	li	a5,2
    80006862:	0097d863          	bge	a5,s1,80006872 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006866:	f9842503          	lw	a0,-104(s0)
    8000686a:	00000097          	auipc	ra,0x0
    8000686e:	d6c080e7          	jalr	-660(ra) # 800065d6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006872:	0001f597          	auipc	a1,0x1f
    80006876:	8b658593          	addi	a1,a1,-1866 # 80025128 <disk+0x2128>
    8000687a:	0001e517          	auipc	a0,0x1e
    8000687e:	79e50513          	addi	a0,a0,1950 # 80025018 <disk+0x2018>
    80006882:	ffffc097          	auipc	ra,0xffffc
    80006886:	db0080e7          	jalr	-592(ra) # 80002632 <sleep>
  for(int i = 0; i < 3; i++){
    8000688a:	f9040713          	addi	a4,s0,-112
    8000688e:	84ce                	mv	s1,s3
    80006890:	bf41                	j	80006820 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006892:	20058713          	addi	a4,a1,512
    80006896:	00471693          	slli	a3,a4,0x4
    8000689a:	0001c717          	auipc	a4,0x1c
    8000689e:	76670713          	addi	a4,a4,1894 # 80023000 <disk>
    800068a2:	9736                	add	a4,a4,a3
    800068a4:	4685                	li	a3,1
    800068a6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800068aa:	20058713          	addi	a4,a1,512
    800068ae:	00471693          	slli	a3,a4,0x4
    800068b2:	0001c717          	auipc	a4,0x1c
    800068b6:	74e70713          	addi	a4,a4,1870 # 80023000 <disk>
    800068ba:	9736                	add	a4,a4,a3
    800068bc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800068c0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800068c4:	7679                	lui	a2,0xffffe
    800068c6:	963e                	add	a2,a2,a5
    800068c8:	0001e697          	auipc	a3,0x1e
    800068cc:	73868693          	addi	a3,a3,1848 # 80025000 <disk+0x2000>
    800068d0:	6298                	ld	a4,0(a3)
    800068d2:	9732                	add	a4,a4,a2
    800068d4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800068d6:	6298                	ld	a4,0(a3)
    800068d8:	9732                	add	a4,a4,a2
    800068da:	4541                	li	a0,16
    800068dc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800068de:	6298                	ld	a4,0(a3)
    800068e0:	9732                	add	a4,a4,a2
    800068e2:	4505                	li	a0,1
    800068e4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800068e8:	f9442703          	lw	a4,-108(s0)
    800068ec:	6288                	ld	a0,0(a3)
    800068ee:	962a                	add	a2,a2,a0
    800068f0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800068f4:	0712                	slli	a4,a4,0x4
    800068f6:	6290                	ld	a2,0(a3)
    800068f8:	963a                	add	a2,a2,a4
    800068fa:	05890513          	addi	a0,s2,88
    800068fe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006900:	6294                	ld	a3,0(a3)
    80006902:	96ba                	add	a3,a3,a4
    80006904:	40000613          	li	a2,1024
    80006908:	c690                	sw	a2,8(a3)
  if(write)
    8000690a:	140d0063          	beqz	s10,80006a4a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000690e:	0001e697          	auipc	a3,0x1e
    80006912:	6f26b683          	ld	a3,1778(a3) # 80025000 <disk+0x2000>
    80006916:	96ba                	add	a3,a3,a4
    80006918:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000691c:	0001c817          	auipc	a6,0x1c
    80006920:	6e480813          	addi	a6,a6,1764 # 80023000 <disk>
    80006924:	0001e517          	auipc	a0,0x1e
    80006928:	6dc50513          	addi	a0,a0,1756 # 80025000 <disk+0x2000>
    8000692c:	6114                	ld	a3,0(a0)
    8000692e:	96ba                	add	a3,a3,a4
    80006930:	00c6d603          	lhu	a2,12(a3)
    80006934:	00166613          	ori	a2,a2,1
    80006938:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000693c:	f9842683          	lw	a3,-104(s0)
    80006940:	6110                	ld	a2,0(a0)
    80006942:	9732                	add	a4,a4,a2
    80006944:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006948:	20058613          	addi	a2,a1,512
    8000694c:	0612                	slli	a2,a2,0x4
    8000694e:	9642                	add	a2,a2,a6
    80006950:	577d                	li	a4,-1
    80006952:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006956:	00469713          	slli	a4,a3,0x4
    8000695a:	6114                	ld	a3,0(a0)
    8000695c:	96ba                	add	a3,a3,a4
    8000695e:	03078793          	addi	a5,a5,48
    80006962:	97c2                	add	a5,a5,a6
    80006964:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006966:	611c                	ld	a5,0(a0)
    80006968:	97ba                	add	a5,a5,a4
    8000696a:	4685                	li	a3,1
    8000696c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000696e:	611c                	ld	a5,0(a0)
    80006970:	97ba                	add	a5,a5,a4
    80006972:	4809                	li	a6,2
    80006974:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006978:	611c                	ld	a5,0(a0)
    8000697a:	973e                	add	a4,a4,a5
    8000697c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006980:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006984:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006988:	6518                	ld	a4,8(a0)
    8000698a:	00275783          	lhu	a5,2(a4)
    8000698e:	8b9d                	andi	a5,a5,7
    80006990:	0786                	slli	a5,a5,0x1
    80006992:	97ba                	add	a5,a5,a4
    80006994:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006998:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000699c:	6518                	ld	a4,8(a0)
    8000699e:	00275783          	lhu	a5,2(a4)
    800069a2:	2785                	addiw	a5,a5,1
    800069a4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800069a8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800069ac:	100017b7          	lui	a5,0x10001
    800069b0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800069b4:	00492703          	lw	a4,4(s2)
    800069b8:	4785                	li	a5,1
    800069ba:	02f71163          	bne	a4,a5,800069dc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800069be:	0001e997          	auipc	s3,0x1e
    800069c2:	76a98993          	addi	s3,s3,1898 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800069c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800069c8:	85ce                	mv	a1,s3
    800069ca:	854a                	mv	a0,s2
    800069cc:	ffffc097          	auipc	ra,0xffffc
    800069d0:	c66080e7          	jalr	-922(ra) # 80002632 <sleep>
  while(b->disk == 1) {
    800069d4:	00492783          	lw	a5,4(s2)
    800069d8:	fe9788e3          	beq	a5,s1,800069c8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800069dc:	f9042903          	lw	s2,-112(s0)
    800069e0:	20090793          	addi	a5,s2,512
    800069e4:	00479713          	slli	a4,a5,0x4
    800069e8:	0001c797          	auipc	a5,0x1c
    800069ec:	61878793          	addi	a5,a5,1560 # 80023000 <disk>
    800069f0:	97ba                	add	a5,a5,a4
    800069f2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800069f6:	0001e997          	auipc	s3,0x1e
    800069fa:	60a98993          	addi	s3,s3,1546 # 80025000 <disk+0x2000>
    800069fe:	00491713          	slli	a4,s2,0x4
    80006a02:	0009b783          	ld	a5,0(s3)
    80006a06:	97ba                	add	a5,a5,a4
    80006a08:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006a0c:	854a                	mv	a0,s2
    80006a0e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006a12:	00000097          	auipc	ra,0x0
    80006a16:	bc4080e7          	jalr	-1084(ra) # 800065d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006a1a:	8885                	andi	s1,s1,1
    80006a1c:	f0ed                	bnez	s1,800069fe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006a1e:	0001e517          	auipc	a0,0x1e
    80006a22:	70a50513          	addi	a0,a0,1802 # 80025128 <disk+0x2128>
    80006a26:	ffffa097          	auipc	ra,0xffffa
    80006a2a:	272080e7          	jalr	626(ra) # 80000c98 <release>
}
    80006a2e:	70a6                	ld	ra,104(sp)
    80006a30:	7406                	ld	s0,96(sp)
    80006a32:	64e6                	ld	s1,88(sp)
    80006a34:	6946                	ld	s2,80(sp)
    80006a36:	69a6                	ld	s3,72(sp)
    80006a38:	6a06                	ld	s4,64(sp)
    80006a3a:	7ae2                	ld	s5,56(sp)
    80006a3c:	7b42                	ld	s6,48(sp)
    80006a3e:	7ba2                	ld	s7,40(sp)
    80006a40:	7c02                	ld	s8,32(sp)
    80006a42:	6ce2                	ld	s9,24(sp)
    80006a44:	6d42                	ld	s10,16(sp)
    80006a46:	6165                	addi	sp,sp,112
    80006a48:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006a4a:	0001e697          	auipc	a3,0x1e
    80006a4e:	5b66b683          	ld	a3,1462(a3) # 80025000 <disk+0x2000>
    80006a52:	96ba                	add	a3,a3,a4
    80006a54:	4609                	li	a2,2
    80006a56:	00c69623          	sh	a2,12(a3)
    80006a5a:	b5c9                	j	8000691c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006a5c:	f9042583          	lw	a1,-112(s0)
    80006a60:	20058793          	addi	a5,a1,512
    80006a64:	0792                	slli	a5,a5,0x4
    80006a66:	0001c517          	auipc	a0,0x1c
    80006a6a:	64250513          	addi	a0,a0,1602 # 800230a8 <disk+0xa8>
    80006a6e:	953e                	add	a0,a0,a5
  if(write)
    80006a70:	e20d11e3          	bnez	s10,80006892 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006a74:	20058713          	addi	a4,a1,512
    80006a78:	00471693          	slli	a3,a4,0x4
    80006a7c:	0001c717          	auipc	a4,0x1c
    80006a80:	58470713          	addi	a4,a4,1412 # 80023000 <disk>
    80006a84:	9736                	add	a4,a4,a3
    80006a86:	0a072423          	sw	zero,168(a4)
    80006a8a:	b505                	j	800068aa <virtio_disk_rw+0xf4>

0000000080006a8c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006a8c:	1101                	addi	sp,sp,-32
    80006a8e:	ec06                	sd	ra,24(sp)
    80006a90:	e822                	sd	s0,16(sp)
    80006a92:	e426                	sd	s1,8(sp)
    80006a94:	e04a                	sd	s2,0(sp)
    80006a96:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006a98:	0001e517          	auipc	a0,0x1e
    80006a9c:	69050513          	addi	a0,a0,1680 # 80025128 <disk+0x2128>
    80006aa0:	ffffa097          	auipc	ra,0xffffa
    80006aa4:	144080e7          	jalr	324(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006aa8:	10001737          	lui	a4,0x10001
    80006aac:	533c                	lw	a5,96(a4)
    80006aae:	8b8d                	andi	a5,a5,3
    80006ab0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006ab2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006ab6:	0001e797          	auipc	a5,0x1e
    80006aba:	54a78793          	addi	a5,a5,1354 # 80025000 <disk+0x2000>
    80006abe:	6b94                	ld	a3,16(a5)
    80006ac0:	0207d703          	lhu	a4,32(a5)
    80006ac4:	0026d783          	lhu	a5,2(a3)
    80006ac8:	06f70163          	beq	a4,a5,80006b2a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006acc:	0001c917          	auipc	s2,0x1c
    80006ad0:	53490913          	addi	s2,s2,1332 # 80023000 <disk>
    80006ad4:	0001e497          	auipc	s1,0x1e
    80006ad8:	52c48493          	addi	s1,s1,1324 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006adc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006ae0:	6898                	ld	a4,16(s1)
    80006ae2:	0204d783          	lhu	a5,32(s1)
    80006ae6:	8b9d                	andi	a5,a5,7
    80006ae8:	078e                	slli	a5,a5,0x3
    80006aea:	97ba                	add	a5,a5,a4
    80006aec:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006aee:	20078713          	addi	a4,a5,512
    80006af2:	0712                	slli	a4,a4,0x4
    80006af4:	974a                	add	a4,a4,s2
    80006af6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006afa:	e731                	bnez	a4,80006b46 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006afc:	20078793          	addi	a5,a5,512
    80006b00:	0792                	slli	a5,a5,0x4
    80006b02:	97ca                	add	a5,a5,s2
    80006b04:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006b06:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006b0a:	ffffc097          	auipc	ra,0xffffc
    80006b0e:	13e080e7          	jalr	318(ra) # 80002c48 <wakeup>

    disk.used_idx += 1;
    80006b12:	0204d783          	lhu	a5,32(s1)
    80006b16:	2785                	addiw	a5,a5,1
    80006b18:	17c2                	slli	a5,a5,0x30
    80006b1a:	93c1                	srli	a5,a5,0x30
    80006b1c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006b20:	6898                	ld	a4,16(s1)
    80006b22:	00275703          	lhu	a4,2(a4)
    80006b26:	faf71be3          	bne	a4,a5,80006adc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006b2a:	0001e517          	auipc	a0,0x1e
    80006b2e:	5fe50513          	addi	a0,a0,1534 # 80025128 <disk+0x2128>
    80006b32:	ffffa097          	auipc	ra,0xffffa
    80006b36:	166080e7          	jalr	358(ra) # 80000c98 <release>
}
    80006b3a:	60e2                	ld	ra,24(sp)
    80006b3c:	6442                	ld	s0,16(sp)
    80006b3e:	64a2                	ld	s1,8(sp)
    80006b40:	6902                	ld	s2,0(sp)
    80006b42:	6105                	addi	sp,sp,32
    80006b44:	8082                	ret
      panic("virtio_disk_intr status");
    80006b46:	00002517          	auipc	a0,0x2
    80006b4a:	faa50513          	addi	a0,a0,-86 # 80008af0 <syscalls+0x3c8>
    80006b4e:	ffffa097          	auipc	ra,0xffffa
    80006b52:	9f0080e7          	jalr	-1552(ra) # 8000053e <panic>

0000000080006b56 <cas>:
    80006b56:	100522af          	lr.w	t0,(a0)
    80006b5a:	00b29563          	bne	t0,a1,80006b64 <fail>
    80006b5e:	18c5252f          	sc.w	a0,a2,(a0)
    80006b62:	8082                	ret

0000000080006b64 <fail>:
    80006b64:	4505                	li	a0,1
    80006b66:	8082                	ret
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
