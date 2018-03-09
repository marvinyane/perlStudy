#!/usr/bin/perl -w

use Tk;
use strict;

my $startx = 50;
my $starty = 20;

my $sizex = 200;
my $sizey = 150;

my $step = 250;

my $mw = MainWindow->new;
$mw->geometry("1000x1000");
$mw->title("Canvas Example");

#my $canvas = $mw->Canvas(-relief => "sunken", -background => "blue");
my $canvas = $mw->Scrolled('Canvas');

for(my $i = 0; $i < 10; $i++){
	my $tempy = $starty + $i * $step;
	$canvas->createRectangle($startx, $tempy, $startx+$sizex, $tempy+$sizey, -fill => "cyan");
}

#$canvas->createText(100,100, -fill => "red", -disabledfill => "black", -text => "hello world");

$canvas->pack();

$mw->Button(-text => 'Exit', -command => sub {exit})->pack();;

MainLoop;