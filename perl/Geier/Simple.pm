package Geier::Simple;
## 
## Copyright (C) 2006  Stefan Siegl <stesie@brokenpipe.de>, Germany
## 
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
## 

use strict;
use warnings;

#use Geier;
use XML::Simple;
#use Data::Dumper;

=pod

=head1 NAME

Geier::Simple - Easy API to Elster/Coala interface

=head1 SYNOPSIS

  use XML::Simple;
  my $xs = new XML::Simple(KeepRoot => 1, ForceArray => 1);
  my $subtree = $xs->XMLin(
    "    <Nutzdatenblock>" .
    "      <NutzdatenHeader version=\"9\">" .
    "        [...]" .
    "      </NutzdatenHeader>" .
    "    </Nutzdatenblock>");

  use Geier::Simple;
  my $gs = new Geier::Simple("ElsterAnmeldung", "UStVA", \$subtree);

  my $export = $gs->text();

  use Geier;
  my $coala = new Geier();
  print $coala->send($data);

=head1 DESCRIPTION

This Perl Module supplies an easy API to create Elster/Coala XML-trees,
which can be send to the German inland revenue office afterwards.

GEIER is the first free library to send gathered tax declarations data to
the German inland revenue office.

GEIER as well as this module is part of the Taxbird project.

=head1 USAGE

This module should be used in a class-based approach, but class-less
should be possible as well.  Please mind that B<Geier::Simple> is
thought to be a base class (which cares for the NutzdatenHeader-part
only) for more specialized classes for all the different types of tax
declarations.  Have a look at B<Geier::Simple::UStVA> for an example
(value added tax declarations in this case).  

=head1 FUNCTIONS

=head2 sub new(method, datatype, subtree) - Create a new Class instance

This function creates a new instance of the Geier::Simple class.  You
need to pass three arguments.  The first argument B<method> is the
Coala-method of this declaration (for example B<ElsterAnmeldung>)
which is passed as B<Verfahren> in the TransferHeader.  The B<datatype>
argument specifies the sub-method, i.e. which type of tax (for example
B<UStVA>) and is passed as B<DatenArt> in the resulting XML document.
Last but not least you need to provide a XML::Simple subtree template
for the B<Nutzdaten>-part of the document.

 EXAMPLE:
        my $xs = new XML::Simple(KeepRoot => 1, ForceArray => 1);
        my $subtree = $xs->XMLin(
          "    <Nutzdatenblock>" .
          "      <NutzdatenHeader version=\"9\">" .
          "        [...]" .
          "      </NutzdatenHeader>" .
          "    </Nutzdatenblock>");

        use Geier::Simple;
        my $gs = new Geier::Simple("ElsterAnmeldung", "UStVA", 
                                   \$subtree);

=cut

sub new($$$$) {
    my $that = shift;
    my $class = ref($that) || $that;

    my $verfahren = shift;
    my $datenart = shift;
    my $subtree = shift;

    my $xs = new XML::Simple(KeepRoot => 1, ForceArray => 1);
    my $tree = $xs->XMLin(
	"<?xml version=\"1.0\" encoding=\"UTF-8\"?>" .
	"<Elster xmlns=\"http://www.elster.de/2002/XMLSchema\" " .
	"xmlns:elster=\"http://www.elster.de/2002/XMLSchema\">" .
	"  <TransferHeader version=\"7\">" .
	"    <Verfahren>$verfahren</Verfahren>" .
	"    <DatenArt>$datenart</DatenArt>" .
	"    <Vorgang>send-NoSig</Vorgang>" .
	#"    <Testmerker>700000004</Testmerker>" .
	#"    <HerstellerID>74931</HerstellerID>" .
	#"    <DatenLieferant>Stefan Siegl</DatenLieferant>" .
	"    <Datei>" .
	"      <Verschluesselung>PKCS#7v1.5</Verschluesselung>" .
	"      <Kompression>GZIP</Kompression>" .
	"      <DatenGroesse>1</DatenGroesse>" .
	"      <TransportSchluessel/>" .
	"    </Datei>" .
	"    <VersionClient>0.1</VersionClient>" .
	"  </TransferHeader>" .
	"  <DatenTeil>" .
	"    <Nutzdatenblock>" .
	"    </Nutzdatenblock>" .
	"  </DatenTeil>" .
	"</Elster>"
    );

    # for the moment we don't need a Geier context ...
    # Geier::init(0);
    my $self = { 
	#coala => new Geier(),
	#flavour => $flavour,
	xmltree => $tree,
	xs => $xs,
    };

    # merge subtree ...
    $tree->{Elster}->[0]->{DatenTeil} = [ $$subtree ];
        
    bless $self, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
    # context_free($self->{context});
}

=pod

=head2 sub set_datenlieferant(address) - set DatenLieferant contents

This function sets the B<DatenLieferant> specified in the
TransferHeader. 

 EXAMPLE:
        $xs->set_datenlieferant("Steuer Sklave");

=cut

sub set_datenlieferant($$) {
    my $self = shift;
    my $name = shift;
    $self->{xmltree}->{Elster}->[0]
	->{TransferHeader}->[0]->{DatenLieferant} = [ $name ];
}

=pod

=head2 sub set_testmarker(marker) - (re-)set a testmarker

This function sets the content of the B<TestMerker> field specified in
the TransferHeader.  For a real tax declaration set B<000000000>, in
case of test data set the corresponding value of the transfer method,
like B<700000004>.

 EXAMPLE:
        $xs->set_testmarker("700000004");

=cut

sub set_testmarker($$) {
    my $self = shift;
    my $value = shift;
    $self->{xmltree}->{Elster}->[0]
	->{TransferHeader}->[0]->{Testmerker} = [ $value ];
}

=pod

=head2 sub set_vendorid(vendorid) - set your vendor-id

This function sets the content of the B<HerstellerID> field specified
in the TransferHeader.  For a real tax declaration set your own vendor
id.  For test cases set B<74931>.

 EXAMPLE:
        $xs->set_vendorid("74931");

=cut

sub set_vendorid($$) {
    my $self = shift;
    my $value = shift;
    $self->{xmltree}->{Elster}->[0]
	->{TransferHeader}->[0]->{HerstellerID} = [ $value ];
}

sub export($$$) {
    my $self = shift;
    my $tag = shift;
    my $pool = shift;

    die "Geier::Simple: $tag not defined in Elster XML pool"
	unless(defined($pool->{$tag}));

    return $self->{xs}->XMLout({ $tag => $pool->{$tag} });
}

sub export_start($$$) {
    my $self = shift;
    my $tag = shift;
    my $tree = shift;

    my $out = "<$tag";
    foreach(keys %$tree) {
	next if length ref $tree->{$_};
	$out .= " $_=\"" . $tree->{$_} . "\"";
    }
    $out .= ">\n";

    return $out;
}

sub export_transferheader($) {
    my $self = shift;
    my $out = "<TransferHeader version=\"7\">\n";
	
    #- export TransferHeader cruft ...
    for(qw/Verfahren DatenArt Vorgang Testmerker HerstellerID DatenLieferant/){
	$out .= $self->export($_, $self->{xmltree}->{Elster}->[0]
			      ->{TransferHeader}->[0]);
    }

    $out .= "<Datei>";
    for(qw/Verschluesselung Kompression DatenGroesse TransportSchluessel/) {
	$out .= $self->export($_, $self->{xmltree}->{Elster}->[0]
			      ->{TransferHeader}->[0]->{Datei}->[0]);
    }
    $out .= "</Datei>";

    $out .= $self->export("VersionClient", $self->{xmltree}->{Elster}->[0]
			  ->{TransferHeader}->[0]);
    
    $out .= "</TransferHeader>\n";
    return $out;
}

sub export_steuerfall($$) {
    my $self = shift;
    my $steuerfall = shift;

    my $out = $self->export_start("Steuerfall", $steuerfall);
    
    die "nur ein fall erlaubt" if(scalar(keys(%$steuerfall)) != 1);
    my $art = (keys(%$steuerfall))[0];

    $out .= $self->export_start($art, $steuerfall->{$art}->[0]);

    for(qw/Jahr Zeitraum Steuernummer/) {
	$out .= $self->export($_, {$_, $steuerfall->{$art}->[0]->{$_}->[0]})
    }

    foreach(sort keys %{$steuerfall->{$art}->[0]}) {
	next unless $_ =~ m/^Kz/;
	$out .= $self->export($_, {$_, $steuerfall->{$art}->[0]->{$_}->[0]})
    }
    
    $out .= "</$art>\n";
    $out .= "</Steuerfall>\n";
    return $out;
}

sub export_nutzdatenblock($) {
    my $self = shift;
    my $out = "<Nutzdatenblock>\n";

    #-- NutzdatenHeader
    $out .= $self->export_start("NutzdatenHeader", $self->{xmltree}->{Elster}
			      ->[0]->{DatenTeil}->[0]->{Nutzdatenblock}->[0]
			      ->{NutzdatenHeader}->[0]);

    for(qw/NutzdatenTicket Empfaenger Hersteller DatenLieferant/) {
	$out .= $self->export($_, $self->{xmltree}->{Elster}->[0]
			      ->{DatenTeil}->[0]->{Nutzdatenblock}->[0]
			      ->{NutzdatenHeader}->[0]);
    }

    $out .= "</NutzdatenHeader>\n";

    #-- Nutzdaten
    $out .= $self->export_start("Nutzdaten", $self->{xmltree}->{Elster}
			      ->[0]->{DatenTeil}->[0]->{Nutzdatenblock}->[0]
			      ->{Nutzdaten}->[0]);

    $out .= $self->export_start("Anmeldungssteuern", $self->{xmltree}->{Elster}
				->[0]->{DatenTeil}->[0]->{Nutzdatenblock}->[0]
				->{Nutzdaten}->[0]->{Anmeldungssteuern}->[0]);

    #-- DatenLieferant ...
    $out .= $self->export_start("DatenLieferant", $self->{xmltree}->{Elster}
				->[0]->{DatenTeil}->[0]->{Nutzdatenblock}->[0]
				->{Nutzdaten}->[0]->{Anmeldungssteuern}->[0]
				->{DatenLieferant}->[0]);

    for(qw/Name Strasse PLZ Ort Telefon/) {
	$out .= $self->export($_, {$_, $self->{xmltree}->{Elster}->[0]
			      ->{DatenTeil}->[0]->{Nutzdatenblock}->[0]
			      ->{Nutzdaten}->[0]->{Anmeldungssteuern}->[0]
			      ->{DatenLieferant}->[0]->{$_}->[0]});
    }

    $out .= "</DatenLieferant>\n";

    #-- Erstellungsdatum
    $out .= $self->export("Erstellungsdatum", 
			  { "Erstellungsdatum", $self->{xmltree}->{Elster}->[0]
				->{DatenTeil}->[0]->{Nutzdatenblock}->[0]
				->{Nutzdaten}->[0]->{Anmeldungssteuern}->[0]
				->{Erstellungsdatum}->[0]});

    #-- Steuerfall
    $out .= $self->export_steuerfall($self->{xmltree}->{Elster}->[0]
				     ->{DatenTeil}->[0]->{Nutzdatenblock}->[0]
				     ->{Nutzdaten}->[0]->{Anmeldungssteuern}
				     ->[0]->{Steuerfall}->[0]);

    $out .= "</Anmeldungssteuern>\n";
    $out .= "</Nutzdaten>\n";

    #-- finish ...
    $out .= "</Nutzdatenblock>\n";
    return $out;
}

sub export_datenteil($) {
    my $self = shift;

    my $out = "  <DatenTeil>\n";

    if(defined($self->{xmltree}->{Elster}->[0]
	       ->{DatenTeil}->[0]->{Nutzdatenblock})) {
	$out .= $self->export_nutzdatenblock();
    }
    else {
	die "not reached.";
    }

    $out .= "  </DatenTeil>";
    return $out;
}

=pod

=head2 sub xmltree() - return the XML::Simple XML-tree

This function returns a reference to the internal XML::Simple tree.
Please mind the you cannot export the XML-tree using B<XMLout> using
this reference as the tree wouldn't be written in the order as
required by Germany's fiscal authorities.  Use B<text()> function in
this case.

 EXAMPLE:
        my $xml_simple_ref = $xs->xmltree();

=cut

sub xmltree($) {
    my $self = shift;
    return $self->{xmltree};
}

=pod

=head2 sub text() - return the XML-tree as a string

This function writes the XML-tree out and returns it as a string.  Use
this function in order to export the gathered data and validate, send,
etc. it using the B<Geier> module.

 EXAMPLE:
        my $xml = $xs->text();

=cut

sub text($) {
    my $self = shift;

    # we can't just call XMLout, since the order of the exported data
    # does matter, therefore let's do it ourselves ...
    #
    # return $self->{xs}->XMLout($self->{xmltree});

    my $out =
	"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n" .
	"<Elster xmlns=\"http://www.elster.de/2002/XMLSchema\" " .
	"xmlns:elster=\"http://www.elster.de/2002/XMLSchema\">\n";

    $out .= $self->export_transferheader();
    $out .= $self->export_datenteil();

    $out .= "</Elster>";
	
    return $out;
}




##############################################################################
###   E x p o r t e r   A r e a                                            ###
##############################################################################
require Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
        set_datenlieferant
        set_testmarker
        set_vendorid
        xmltee
        text
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = "0.01";



=pod

=head1 AUTHOR

Stefan Siegl <stesie@brokenpipe.de>

=head1 COPYRIGHT

The Geier module is subject of the GNU General Public License version 2
or any later on your option.

Copyright (C) 2006 by Stefan Siegl <stesie@brokenpipe.de>.


B<libgeier> is subject of the GNU General Publice License version 2 or
any later (on your option) as well. Copyright by the corresponding authors.

=head1 BUGS

If you happen to find a bug, in either this module or the libgeier in
general, please either mail me directly to B<stesie@brokenpipe.de> or to
the Taxbird mailing list, see the webpages at http://www.taxbird.de/ for
details.

=cut