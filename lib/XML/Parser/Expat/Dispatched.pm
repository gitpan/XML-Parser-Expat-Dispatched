package XML::Parser::Expat::Dispatched;
use strict;
# ABSTRACT: Automagically dispatches subs to XML::Parser::Expat handlers
use true;
use parent 'XML::Parser::Expat';
use Carp;
our $VERSION = 0.901;

=head1 SYNOPSIS

    package MyParser;
    use parent XML::Parser::Expat::Dispatched;
    
    sub Start_tagname{
      my $self = shift;
      say $_[0], $self->original_tagname;
    }
    
    sub End_tagname{
      my $self=shift;
      say "$_[0] ended";
    }
    
    sub Char_handler{
      my ($self, $string) = @_;
      say $string;
    }
     
     sub transform_gi{
      lc $_[1];
     }


     package main;
     my $p = MyParser->new;
     $p->parse('<Tagname>tag</Tagname>');
     # prints
     # Tagname<Tagname>
     # tag
     # Tagname ended

=cut



sub new {
  no strict 'refs';
  # perlcritic doesn't like this, but who likes living by the book
  my($package) = shift;
  my %dispatch;
  while (my ($symbol_table_key, $val) = each %{ *{ "$package\::" } }) {
    local *ENTRY = $val;
    if (defined $val 
	and defined *ENTRY{ CODE }
	and $symbol_table_key =~ /^(?:(?'what'Start|End)_?(?'who'.*)
				  |(?'who'.*?)_?(?'what'handler))$/x){
      carp "the sub $symbol_table_key overrides the handler for $dispatch{$+{what}}{$+{who}}[1]"
	if exists $dispatch{$+{what}}{$+{who}};
      $dispatch{$+{what}}{$+{who}}= [*ENTRY{ CODE }, $symbol_table_key];
    }
  }
  my $s = bless(XML::Parser::Expat->new(@_),$package);
  $s->setHandlers($s->__gen_dispatch(\%dispatch));
  return $s;
}

sub __gen_dispatch{
  my ($s,$dispatch) = @_;
  my %ret;
  foreach my $se (qw|Start End|) {
    if ($dispatch->{$se}) {
      if (not $s->can('transform_gi')) {
	# the alternative would be to have a generic transform_gi sub, i don't want that, because it's much slower.
	$ret{$se} = sub {
	  if ($dispatch->{$se}{$_[1]}) {
	    $dispatch->{$se}{$_[1]}[0](@_);
	  }elsif(defined $dispatch->{$se}{''}){
	    $dispatch->{$se}{''}[0](@_);
	  }
	}
      } else {
	foreach (keys %{$dispatch->{$se}}) {
	  my $new_key=$s->transform_gi($_,1);
	  if ($_ ne $new_key){
	    carp "$dispatch->{$se}{$new_key}[1] and $dispatch->{$se}{$_}[1] translate to the same handler"
	      if exists $dispatch->{$se}{$new_key};
	    $dispatch->{$se}{$new_key} = $dispatch->{$se}{$_};
	    delete $dispatch->{$se}{$_};
	  }
	}
	$ret{$se} = sub {
	  if ($dispatch->{$se}{$s->transform_gi($_[1],0)}) {
	    $dispatch->{$se}{$s->transform_gi($_[1],0)}[0](@_);
	  }elsif(defined $dispatch->{$se}{''}){
	    $dispatch->{$se}{''}[0](@_);
	  }
	}
      }
    }
  }
  $ret{$_} = $dispatch->{handler}{$_}[0] foreach keys %{$dispatch->{handler}};
  return %ret;
}


__END__

=head1 DESCRIPTION

This package provides a C<new> method that produces some dispatch methods for  L<XML::Parser::Expat/set_handlers> .

Since your package will inherit L<XML::Parser::Expat|XML::Parser::Expat> be prepared to call it's C<release>-method if you write your own C<DESTROY>-method.

I wrote this module because i needed a quite low-level XML-Parsing library that had an C<original_string> method. So if you need some higher level library, I'd really suggest to look at the L</SEE ALSO> section.

=head1 HANDLERS

Available handlers:

The underscore in the subroutine names is optional for all the handler methods.
The arguments your subroutine gets called with, are the same as those for the handlers from L<XML::Parser::Expat|XML::Parser::Expat>.

=head2 Start_I<tagname>

Will be called when a start-tag is encountered that matches I<tagname>.
If I<tagname> is not given (when your sub is called C<Start> or C<Start_>), it works like a default-handler for start tags.

=head2 End_I<tagname>

Will be called when a end-tag is encountered that matches I<tagname>.
If I<tagname> is not given (when your sub is called C<End> or C<End_>), it works like a default-handler for end tags.

=head2 I<Handler>_handler

Installs this subroutine as a handler for L<XML::Parser::Expat|XML::Parser::Expat>.
You can see the Handler names on L<XML::Parser::Expat/set_handlers>. Notice that if you try to define a handler for Start or End,
they will be interpreted as C<Start> or C<End> handlers for C<handler>-tags, use subs called C<Start> or C<End> instead.


=head2 transform_gi (Parser, Suffix/Tagname, isSuffix)

This subroutine is special: you can use it to generalize the check
between the subroutine suffix for the C<Start*> and C<End*> subroutine names
and the tagnames. The arguments are:

=for :list
* I<Parser>: the parser object
* I<Suffix/Tagname>: the suffix of your subroutine-name or the tagname
* I<isSuffix>: A C<1/0> value wether a subroutine name's suffix or an tagname was supplied (1 for suffix)


Some Examples:

    sub transform_gi{lc $_[1]}           # case insensitive
    sub transform_gi{return !$_[2] && $_[1]=~/:([^:]+)$/ ?
                            $1: $_[1]}   # try discarding the namespace

Note that the allowed characters for perl's subroutine names
and XML-Identifiers aren't the same, so you might want to use the default handlers or C<transform_gi> in some cases (namespaces, tagnames with an dash).

=head1 DIAGNOSTICS

  the sub %s1 overrides the handler for %s2

You most probably have two subroutines that
have the same name exept one with an underscore and one without.
The warning issued tells you wich of the subroutines will be used as a handler.
Since the underlying mechanism is based on the C<each> iterator, this behavior
can vary from time to time running, so you might want to change your sub names.

  %s1 and %s2 translate to the same handler

There is an sub called C<%s1> that translates to the same handler as a sub C<%s2> after applying C<transform_gi>. The sub C<%s1> will be used.

=head2 INTERNALS

The following things might break this module so be aware of them:

=for :list

* Your parser will be a L<XML::Parser::Expat|XML::Parser::Expat> so consider checking the methods of this class if you write methods other than handler methods
.
*Overwriting C<__gen_dispatch> without calling it in your C<__gen_dispatch> since this is the only method this module has.

*Useing C<AUTOLOAD> without updateing the symbol table before C<new> is called.

*Calling C<set_handlers> on your parser. This module calls C<set_handlers> and if you do, you overwrite the handlers it has installed (why do you use this module anyway).

=head1 SEE ALSO

Obviously L<XML::Parser::Expat|XML::Parser::Expat> as it is a simple extension of that class.


You also should chekout these modules for parsing XML:

=for :list
* L<XML::Twig>
* L<XML::LibXML>
* L<XML::TokeParser>
* Many other modules in the XML::Parser Namespace

=cut
