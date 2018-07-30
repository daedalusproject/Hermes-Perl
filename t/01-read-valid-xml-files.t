#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 18;
use Test::Exception;

BEGIN {
    use_ok('Daedalus::Hermes') || print "Bail out!\n";
}

throws_ok {
    Daedalus::Hermes::parse_hermes_config();
}
qr/There is no file provided, cannot parse any config./,
  "For parsing a file, that file is needed.";

throws_ok {
    Daedalus::Hermes::parse_hermes_config("noexistenfile");
}
qr/'noexistenfile' file does no exist, cannot parse any config./,
  "For parsing a file, that file must exist.";

throws_ok {
    Daedalus::Hermes::parse_hermes_config("t/files/nonxmlfile");
}
qr/ERROR in 't\/files\/nonxmlfile'/,
  "For parsing a file, a valid XML file is needed.";

throws_ok {
    Daedalus::Hermes::parse_hermes_config("t/files/hermesrabbitnonvalid01.xml");
}
qr/not well-formed/, "For parsing a file, a valid XML file is needed.";

throws_ok {
    Daedalus::Hermes::parse_hermes_config("t/files/hermesrabbitnonvalid01.xml");
}
qr/not well-formed/, "For parsing a file, a valid XML file is needed.";

throws_ok {
    Daedalus::Hermes::parse_hermes_config("t/files/hermesrabbitnonvalid02.xml");
}
qr/not well-formed/, "for parsing a file, a valid xml file is needed.";

throws_ok {
    Daedalus::Hermes::parse_hermes_config("t/files/hermesrabbitnonvalid03.xml");
}
qr/Hermes config not found, 'hermes' key is not pressent/,
  "for parsing hermes config, hermes key is needed.";

throws_ok {
    Daedalus::Hermes::parse_hermes_config("t/files/hermesrabbitnonvalid04.xml");
}
qr/Type 'Nonsense' is invalid, configuration is invalid./,
  "Hermes types must exists.";

throws_ok {
    Daedalus::Hermes::parse_hermes_config("t/files/hermesrabbitnonvalid05.xml");
}
qr/The following Hermes RabbitMQ field are required: user, password/,
  "Hermes RabbitMQ needs defined user and password.";

throws_ok {
    Daedalus::Hermes::parse_hermes_config("t/files/hermesrabbitnonvalid06.xml");
}
qr/The following Hermes RabbitMQ field are required: password/,
  "Hermes RabbitMQ needs defined password.";

throws_ok {
    Daedalus::Hermes::parse_hermes_config("t/files/hermesrabbitnonvalid07.xml");
}
qr/The following Hermes RabbitMQ field are required: user/,
  "Hermes RabbitMQ needs defined user and password.";

throws_ok {
    Daedalus::Hermes::parse_hermes_config("t/files/hermesrabbitnonvalid08.xml");
}
qr/All queues have to have 'name' attirbute, invalid config./,
  "name has to be defined in any queue";

throws_ok {
    Daedalus::Hermes::parse_hermes_config("t/files/hermesrabbitnonvalid09.xml");
}
qr/All queues have to have 'channel' attirbute, invalid config./,
  "name has to be defined in any queue";

throws_ok {
    Daedalus::Hermes::parse_hermes_config("t/files/hermesrabbitnonvalid10.xml");
}
qr/All queues have to have 'purpose' attirbute, invalid config./,
  "name has to be defined in any queue";

throws_ok {
    Daedalus::Hermes::parse_hermes_config("t/files/hermesrabbitnonvalid11.xml");
}
qr/Parameter 'nonsense' is not a valid queue parameter, invalid config./,
  "Hermes only accepts valid queue parameter names.";

my $hermes_config =
  Daedalus::Hermes::parse_hermes_config("t/files/hermesrabbit01.xml");

ok(
    $hermes_config->{config}->{queues}->{secondtestqueue}->{queue_options}
      ->{delivery_mode} eq '2',
    'Check hermes config I'
);

ok(
    $hermes_config->{config}->{queues}->{secondtestqueue}->{publish_options}
      ->{global} eq '1',
    'Check hermes config II'
);

diag("Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X");
