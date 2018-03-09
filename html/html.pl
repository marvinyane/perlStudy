#!/bin/perl -w

#########################################################################
#                                                                       #
#  This example can be used as a framework to create others HTML+       #
#  converters                                                           #
#  It maps various specific elements to common html ones, takes care of #
#  empty elements that would not be displayed in an old browser, and    #
#  finally allows simple inclusion of outside files in the document     #
#                                                                       #
#########################################################################


use strict;
use XML::Twig;


my $t= new XML::Twig
         ( TwigRoots =>
             { example     => \&example,    # include a file 
                                            # convert to an html tag
               method      => \&method,     # convert to tt and create
                                            # link to doc
               tag         => sub { make(@_, 'tt') },
               code        => sub { make(@_, 'tt') },
               package     => sub { make(@_, 'bold') },
               option      => sub { make(@_, 'bold') },
               br          => \&empty,      # we need those for the html
               hr          => \&empty,      # to work in old browsers
             },
            TwigPrintOutsideRoots => 1,     # just print the rest
          );

if( $ARGV[0]) { $t->parsefile( $ARGV[0]); } # process the twig
else          { $t->parse( \*STDIN);      }

exit;

sub empty                                   
  { my( $t, $empty)= @_;                    
    print "<" . $empty->gi . ">";           # just print the tag html style
  }

sub make                                          
  { my( $t, $elt, $new_gi)= @_;
    $elt->set_gi( $new_gi);                 # change the tag gi
    $elt->print;                            # don't forget to print it
  }

sub method
  { my( $t, $method)= @_;
    $method->set_gi( 'tt');
    my $a= $method->insert( 'a');
    my $class= $method->att( 'class');
    my $item= lc $method->text;
    $method->del_att( 'class');
    $a->set_att( href => "$class\_$item");
  }

sub example                                 # generate a link and include the file
  { my( $t, $example)= @_;

    my $file= $example->text;               # first get the included file

    $example->set_gi( 'p');                 # replace the example by a paragraph
    my $a= $example->insert( 'a');          # insert an link in the paragraph
    $a->set_att( href => $file);            # set the href attribute

    $example->print;                        # print the paragraph

    open( EXAMPLE, "<$file")                # open the file
      or die "cannot open file $file: $!"; 
    local undef $/;                         # slurp all of it
    my $text= <EXAMPLE>;
    close EXAMPLE;

    $text=~ s/&/&amp;/g;                    # replace special characters (& first)
    $text=~ s/</&lt;/g ;                    
    $text=~ s/"/&quot;/g;

    print "<pre>$text</pre>";               # print the example


    
  }

