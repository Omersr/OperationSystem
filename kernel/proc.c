#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

//-------- OUR ADDITION --------------------
int p_time = 0;
int toRelease = 0;
int rate = 5;
int program_time =0;
int start_time =0;
int cpu_utilization =0;


int sleeping_processes_mean = 0;
int running_processes_mean = 0;
int runnable_processes_mean = 0;

int running_procs = 0;

// 1 = sh or init, 0 = else
int check_name(char name[])
{
  if (name[0] == 105 && name[1] == 110 && name[2] == 105 && name[3] == 116)
  {
    for (int i = 4; i < 15; i++)
    {
      if (name[i] != 0)
      {
        return 0;
      }
      return 1;
    }
  }

  if (name[0] == 115 && name[1] == 104)
  {
    for (int i = 2; i < 15; i++)
    {
      if (name[i] != 0)
      {
        return 0;
      }
      return 1;
    }
  }
  return 0;
}
void print_stats (void)
{
  printf("program_time:%d  \ncpu_utilization:%d precent \nrunning_processes_mean:%d  \nrunnable_processes_mean:%d  \nsleeping_processes_mean:%d\n\n",program_time,cpu_utilization,running_processes_mean,runnable_processes_mean,sleeping_processes_mean);
}

// updates sleep/runnable/running times
void update_time(struct proc *p)
{
   //if (check_name(p->name) != 0)
   //{
      if (p->state == RUNNABLE)
      {
        p->runnable_time = p->runnable_time + (ticks - p->counter);
      }
      if (p->state == RUNNING)
      {
        p->running_time = p->running_time + (ticks - p->counter);
      }
      if (p->state == SLEEPING)
      {
       // printf("SLEEP UPDATE: ticks:%d counter:%d\n",ticks,p->counter);
        p->sleep_time = p->sleep_time + (ticks - p->counter);
      }
   //}
 }

void update_time_mean(struct proc *p)
{
  printf("UPDATE IN PROGRESS  %d\n", ticks - start_time);
  update_time(p);
  program_time = program_time + p->running_time;
  cpu_utilization = (program_time* 100) / (ticks - start_time);
  running_processes_mean = ((running_processes_mean * running_procs) + p->running_time) / (running_procs + 1);
  runnable_processes_mean = ((runnable_processes_mean * running_procs) + p->runnable_time) / (running_procs + 1);
  sleeping_processes_mean = ((sleeping_processes_mean * running_procs) + p->runnable_time) / (running_procs + 1);
  running_procs = running_procs + 1;
  print_stats();
}



//-------- OUR ADDITION END--------------------

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table at boot time.
void procinit(void)
{
  struct proc *p;
  start_time = ticks;
  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    initlock(&p->lock, "proc");
    p->kstack = KSTACK((int)(p - proc));
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int allocpid()
{
  int pid;

  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc *
allocproc(void)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == UNUSED)
    {
      goto found;
    }
    else
    {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;
  // our addition
  p->pause = 0;
  // CHECK!
  p->last_ticks = 0;
  p->mean_ticks = 0;
  p->last_runnable_time = 0;
  p->sleep_time = 0;
  p->runnable_time = 0;
  p->running_time = 0;
  p->counter = 0;
  // Allocate a trapframe page.
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if (p->pagetable == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;

  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if (p->trapframe)
    kfree((void *)p->trapframe);
  p->trapframe = 0;
  if (p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
}

// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if (pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
               (uint64)trampoline, PTE_R | PTE_X) < 0)
  {
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe just below TRAMPOLINE, for trampoline.S.
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
               (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
  {
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
    0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
    0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
    0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
    0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
    0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
    0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00};

// Set up first user process.
void userinit(void)
{
  struct proc *p;

  p = allocproc();
  initproc = p;

  // allocate one user page and copy init's instructions
  // and data into it.
  uvminit(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;     // user program counter
  p->trapframe->sp = PGSIZE; // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;

  // added
  p->counter = ticks;
  p->last_runnable_time = ticks;

  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.

int growproc(int n)
{
  uint sz;
  struct proc *p = myproc();

  sz = p->sz;
  if (n > 0)
  {
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    {
      return -1;
    }
  }
  else if (n < 0)
  {
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if ((np = allocproc()) == 0)
  {
    return -1;
  }

  // Copy user memory from parent to child.
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
  {
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for (i = 0; i < NOFILE; i++)
    if (p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  // added
  update_time(np);
  np->state = RUNNABLE;
  // added
  np->counter = ticks;
  np->last_runnable_time = ticks;
  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void reparent(struct proc *p)
{
  struct proc *pp;

  for (pp = proc; pp < &proc[NPROC]; pp++)
  {
    if (pp->parent == p)
    {
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void exit(int status)
{
  struct proc *p = myproc();

  if (p == initproc)
    panic("init exiting");

  // Close all open files.
  for (int fd = 0; fd < NOFILE; fd++)
  {
    if (p->ofile[fd])
    {
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);

  acquire(&p->lock);

  p->xstate = status;
  update_time(p);
  p->state = ZOMBIE;
  update_time_mean(p);
  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int wait(uint64 addr)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (np = proc; np < &proc[NPROC]; np++)
    {
      if (np->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
        {
          // Found one.
          pid = np->pid;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                   sizeof(np->xstate)) < 0)
          {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || p->killed)
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.

//----- OUR ADDITION  --------

void unpause(void)
{
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    p->pause = 0;
    release(&p->lock);
  }
}

// print all runnable proccesses last_runnable_time and the one with the lowest
void printall(struct proc *pillow)
{
  printf("LOWEST RUNNING PORCCESS!\nPID: %d   name:%s last_runnable_time:%d \n\n", pillow->pid, pillow->name, pillow->last_runnable_time);
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
  {

    // our addition
    if (p->state == RUNNABLE && p != pillow)
    {
      printf("PID: %d   name:%s last_runnable_time:%d \n", p->pid, p->name, p->last_runnable_time);
    }
  }
}

//----- OUR ADDITION END --------

// ------------------- Schedulers ------------------
void FCFS_scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
  struct proc *pillow = proc;
  int pid2 = -1;
  c->proc = 0;
  for (;;)
  {
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      // our addition
      if (p->state == RUNNABLE && p->pause == 0)
      {
        if (p->last_runnable_time <= pillow->last_runnable_time)
        {
          pillow = p;
        }
      }
      release(&p->lock);
    }
    acquire(&pillow->lock);
    if (pid2 != pillow->pid)
    {
      // printall(pillow);
      pid2 = pillow->pid;
    }

    // Switch to chosen process.  It is the process's job
    // to release its lock and then reacquire it
    // before jumping back to us.

    // added update_time and counter
    update_time(pillow);
    pillow->state = RUNNING;
    pillow->counter = ticks;
    c->proc = pillow;
    swtch(&c->context, &pillow->context);
    // Process is done running for now.
    // It should have changed its p->state before coming back.
    c->proc = 0;
    release(&pillow->lock);
    // our addition
    if (ticks >= p_time && toRelease == 1)
    {
      toRelease = 0;
      printf("RELEASING! ticks:%d   p_time:%d  \n", ticks, p_time);
      unpause();
    }
  }
}

void SJF_scheduler(void)
{
  printf("SJFFFF im here\n");
  struct proc *p;
  struct cpu *c = mycpu();
  c->proc = 0;

  for (;;)
  {
    // Avoid deadlock by ensuring that devices can interrupt.
    // intr_on();
    uint min_ticks = 1000;
    struct proc *min_pointer = proc + 2;
    int initi = 0;
    for (p = proc + 2; p < &proc[NPROC]; p++)
    {
      if (initi == 0 && p->state == RUNNABLE)
      {
        min_ticks = p->mean_ticks;
        min_pointer = p;
        initi = 1;
        printf("init: min_ticks:%d  min_pointer_name:%s \n", min_ticks, min_pointer->name);
      }
      acquire(&p->lock);
      // our addition
      if (p->pid != 0 && p->pid != 1 && check_name(p->name) == 0 && p->state == RUNNABLE && p->pause == 0)
      {
        if (min_ticks <= p->mean_ticks)
        {
          min_ticks = p->mean_ticks;
          min_pointer = p;
        }
      }
      release(&p->lock);
    }
    // Switch to chosen process.  It is the process's job
    // to release its lock and then reacquire it
    // before jumping back to us.
    // printf("im running! %s, pid:%d \n",min_pointer->name, min_pointer->pid);
    acquire(&min_pointer->lock);

    // added update_time and counter
    update_time(min_pointer);
    min_pointer->state = RUNNING;
    min_pointer->counter = ticks;
    c->proc = min_pointer;
    // int firstick = ticks;
    min_pointer->last_ticks = ticks;
    swtch(&c->context, &min_pointer->context);
    // int lastick = ticks;
    min_pointer->mean_ticks = ((10 - rate) * min_pointer->mean_ticks + min_pointer->last_ticks * (rate)) / 10;
    // printf("p->last_tick:%d\n", min_pointer->last_ticks);
    // printf("p->mean_tick:%d\n", min_pointer->mean_ticks);
    // Process is done running for now.
    // It should have changed its p->state before coming back.
    c->proc = 0;
    release(&min_pointer->lock);

    // our addition
    if (ticks >= p_time && toRelease == 1)
    {
      toRelease = 0;
      printf("RELEASING! ticks:%d   p_time:%d  \n", ticks, p_time);
      unpause();
    }
  }
}
// ------------------- Schedulers  end ------------------

void scheduler(void)
{
  int mode = 0;
//---------- OUR ADDITION --------------
#ifdef RR
  //-------------------RR Selected --------------------
  printf("RR is selected\n");
  mode = 1;
  //-------------------RR Selected END--------------------
#endif
  //-------------- SJF SELECTED----------------------
#ifdef SJF
  printf("SJF is selected\n");
  mode = 2;
#endif

#ifdef FCFS
  printf("FCFS is selected\n");
  mode = 3;
#endif
  //---------- OUR ADDITION END --------------
  if (mode == 0) // NO MODE
  {
    struct proc *p;
    struct cpu *c = mycpu();
    c->proc = 0;
    for (;;)
    {
      // Avoid deadlock by ensuring that devices can interrupt.
      intr_on();
      for (p = proc; p < &proc[NPROC]; p++)
      {
        acquire(&p->lock);
        // our addition
        if (p->state == RUNNABLE && p->pause == 0)
        {
          // Switch to chosen process.  It is the process's job
          // to release its lock and then reacquire it
          // before jumping back to us.

          // added update_time and counter
          update_time(p);
          p->state = RUNNING;
          p->counter = ticks;
          c->proc = p;
          swtch(&c->context, &p->context);
          // Process is done running for now.
          // It should have changed its p->state before coming back.
          c->proc = 0;
        }
        release(&p->lock);
      }
      // our addition
      if (ticks >= p_time && toRelease == 1)
      {
        toRelease = 0;
        printf("RELEASING! ticks:%d   p_time:%d  \n", ticks, p_time);
        unpause();
      }
    }
  }
  if (mode == 2)
  {
    SJF_scheduler();
  }
  if (mode == 3)
  {
    FCFS_scheduler();
  }
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void sched(void)
{
  int intena;
  struct proc *p = myproc();

  if (!holding(&p->lock))
    panic("sched p->lock");
  if (mycpu()->noff != 1)
    panic("sched locks");
  if (p->state == RUNNING)
    panic("sched running");
  if (intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  // added update_time and counter
  update_time(p);
  p->state = RUNNABLE;
  // added
  p->last_runnable_time = ticks;
  p->counter = ticks;
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first)
  {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{

  struct proc *p = myproc();
  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
  release(lk);
  // Go to sleep.
  update_time(p);
  p->chan = chan;
  p->state = SLEEPING;
  // printf("CHANGE TO SLEEP, last_ticks:%d   ticks%:%d \n",p->last_ticks,ticks);
  p->counter = ticks;
  p->last_ticks = ticks - p->last_ticks;
  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
      {
        // added update_time and counter
        update_time(p);
        p->state = RUNNABLE;
        // added
        p->last_runnable_time = ticks;
        p->counter = ticks;
      }
      release(&p->lock);
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->pid == pid)
    {
      p->killed = 1;

      if (p->state == SLEEPING)
      {
        // Wake process from sleep().

        // added
        update_time(p);
        p->state = RUNNABLE;
        p->counter = ticks;
        // added
        p->last_runnable_time = ticks;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if (user_dst)
  {
    return copyout(p->pagetable, dst, src, len);
  }
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if (user_src)
  {
    return copyin(p->pagetable, dst, src, len);
  }
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
  static char *states[] = {
      [UNUSED] "unused",
      [SLEEPING] "sleep ",
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}

//---------- OUR ADDITION -------------------------

int pause_system(int seconds)
{
  toRelease = 1;

  int sec = 10; //!!!!!!!!!!!!!!!!!!! CHANGE TO 10e6
  p_time = ticks + seconds * sec;
  // struct proc *p = myproc();
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    int x = check_name(p->name);
    //  printf("x=%d, name:%s\n" ,x,p->name);
    // printf("PID: %d STATE: %d  name: %s\n", p->pid, p->state, p->name);
    if (x == 0)
    {
      p->pause = 1;
      // printf("PID: %d STATE: %d  name: %s pause_flag is on\n", p->pid, p->state,p->name);
    }
    release(&p->lock);
    if (p->pause == 1 && p->state == 4)
    {
      // printf("myproc: %d\n",myproc()->pid);
      yield();
    }
    // printf("PID: %d STATE: %d  pause_flag: %d\n", p->pid, p->state,p->pause);
  }

  return seconds;
}

int kill_system(void)
{
  struct proc *p;
  // int my_pid = myproc()->pid;
  for (p = proc; p < &proc[NPROC]; p++)
  {

    int x = check_name(p->name);
    if (x == 0 && p != myproc())
    {
      kill(p->pid);
    }
  }

  return 0;
}