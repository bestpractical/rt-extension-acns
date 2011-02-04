use inc::Module::Install;
RTx('RT-Extension-ACNS');
all_from 'lib/RT/Extension/ACNS.pm';
readme_from 'lib/RT/Extension/ACNS.pm';

requires 'Parse::ACNS';

WriteAll();
