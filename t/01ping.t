use strict;
use Test;
BEGIN { plan tests => 3 }
use File::Scan::ClamAV;
use POSIX ":sys_wait_h";

do "t/mkconf.pl";

# start clamd
my $pid = fork;
die "Fork failed" unless defined $pid;
if (!$pid) {
    exec "$ENV{CLAMD_PATH}/clamd -c clamav.conf";
    die "clamd failed to start: $!";
}
for (1..10) {
  last if (-e "clamsock");
  if (kill(0 => $pid) == 0) {
    die "clamd appears to have died";
  }
  sleep(1);
}

my $av = new File::Scan::ClamAV(port => "clamsock");
ok($av);
ok($av->ping);

ok(kill(9 => $pid), 1);
1 while (waitpid($pid, &WNOHANG) != -1);
unlink("clamsock");
