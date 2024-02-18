#!/usr/bin/perl
#************************************************************************
#
# References  :
#
#          $Revision: 
#          $Date:     
#          $Author:   
#          $Mail:     
#
#***********************************************************************
#
# Name        :  
# Platforms   :  unix, windows      
# Contents    :                  
# Description :  
#                

package F136::RpgPageAdmin;

use locale;
use POSIX qw(strftime setlocale LC_CTYPE);

use vars qw(@ISA $VERSION $PACKAGE);
use English;
use strict;
use warnings;
use utils;
use types;
use page_default;
use src_data;
use sql_make;

use F136::adm_exp_corr;
use F136::adm_imp_corr;
use F136::adm_rowver;

BEGIN 
{
    $VERSION = 0.01;
    @ISA     = qw(RpgPageDefault);
    $PACKAGE = __PACKAGE__;
}

sub DESTROY
{
    my ($self) = @_;
    
    foreach my $parent ( @ISA )
    {
        # вызываем деструкторы базовых классов
        next if $self->{$parent}{DESTROY}++;
        my $destructor = $parent->can("DESTROY");
        $self->$destructor() if $destructor;
    }
}

use constant DICTIONARIES =>
{
    GET_ACC     =>
    {
        src     => 'SQL_GET_CURR_ACC',
        params  => []
    },    
    GET_CLS        =>
    {
        src    => 'SQL_GET_CURR_CLIENT_CLS',
        params  => []
    },
    GET_CODES      =>
    {
        src     => 'SQL_GET_CURR_CODES',
        params  => []
    },
    GET_DEPARTS      =>
    {
        src     => 'SQL_GET_CURR_DEPART',
        params  => []
    },
    GET_ROWVER      =>
    {
        src     => 'SQL_GET_ROWVER',
        params  => []
    },
    GET_SETT      =>
    {
        src     => 'SQL_GET_F136_SETTINGS',
        params  => []
    },
    GET_VERSPR      =>
    {
        src     => 'SQL_GET_ROWVER_OF_SPRAVOCHNIKS',
        params  => []
    },
    GET_THE_ROWVER    =>
    {
        src     => 'SQL_GET_THE_ROWVER',
        params  => [{field => 'rowver'}]
    }        
};

use constant FIELDS_OF_DICTIONARIES => 
{
    rowver =>
    {
        type => 'int' 
    }
};

use constant CHILDRENS =>
{
    IMPORT => 
    {
        CORR_SUM  => sub {new F136::RpgAdmImportCorr(@_);},                
        CORR_ACC  => sub {new F136::RpgAdmImportCorr(@_);},
        CORR_CLN  => sub {new F136::RpgAdmImportCorr(@_);},
        ONLY_CORR_SUM  => sub {new F136::RpgAdmImportCorr(@_);},                
        ONLY_CORR_ACC  => sub {new F136::RpgAdmImportCorr(@_);},
        ONLY_CORR_CLN  => sub {new F136::RpgAdmImportCorr(@_);},
        CORR_COD  => sub {new F136::RpgAdmImportCorr(@_);},
        CORR_BAL  => sub {new F136::RpgAdmImportCorr(@_);},
        SUMM_BAL  => sub {new F136::RpgAdmImportCorr(@_);}
    },
    EXPORT => 
    {
        CORR_COD => sub {new F136::RpgAdmExportCorr(@_);},
        CORR_CLN => sub {new F136::RpgAdmExportCorr(@_);},
        CORR_ACC => sub {new F136::RpgAdmExportCorr(@_);},
        CORR_SUM => sub {new F136::RpgAdmExportCorr(@_);},
        CORR_BAL => sub {new F136::RpgAdmExportCorr(@_);},
        SHOW_COD => sub {new F136::RpgAdmExportCorr(@_);},
        SHOW_BAL => sub {new F136::RpgAdmExportCorr(@_);},
        SHOW_SUM => sub {new F136::RpgAdmExportCorr(@_);},
        SHOW_CUR => sub {new F136::RpgAdmExportCorr(@_);},
                
        ONLY_CORR_CLN => sub {new F136::RpgAdmExportCorr(@_);},
        ONLY_CORR_ACC => sub {new F136::RpgAdmExportCorr(@_);},
        ONLY_CORR_SUM => sub {new F136::RpgAdmExportCorr(@_);},
        
        SETT_USE_ACC         => sub {new F136::RpgAdmExportCorr(@_);},
        SETT_KLIKO           => sub {new F136::RpgAdmExportCorr(@_);},
        SETT_HTML            => sub {new F136::RpgAdmExportCorr(@_);},
        SETT_RESERVE         => sub {new F136::RpgAdmExportCorr(@_);},
        SETT_FORMULAS        => sub {new F136::RpgAdmExportCorr(@_);},
        SETT_PERMISSIONS_ACC => sub {new F136::RpgAdmExportCorr(@_);},

# DEV00000000    CHECK_47426_BY_32802 => sub {new F136::RpgAdmExportCorr(@_);},
        CHECK_47426N_EQUAL_47426 => sub {new F136::RpgAdmExportCorr(@_);}
    },
    UPDATE =>
    {
        SETTINGS             => sub {new F136::RpgAdmImportCorr(@_);},
        SETT_PERMISSIONS_ACC => sub {new F136::RpgAdmImportCorr(@_);}
    },
    EDIT =>
    {
        ROWVER => sub {new F136::RpgAdmRowVersion(@_);}
    },
    CREATE =>
    {
        ROWVER => sub {new F136::RpgAdmRowVersion(@_);}
    },
    DELETE =>
    {
        ROWVER => sub {new F136::RpgAdmRowVersion(@_);}
    }
};

#*******************************************************************************
#
sub new
#
#*******************************************************************************
{
    my ($class) = shift;
    
    unless (ref($class))
    {
        # сюда попадаем только если объект создаётся на прямую, т.е. класса ещё не существует
        # в блоке делается переопределение объекта (передача управления дочерним классам)
        my %args = (@_);
        my $exe  = $args{PARAM}{CGI}->param('exe');
        my $page = $args{PARAM}{CGI}->param('page');
        #my $to   = (defined($args{PARAM}{CGI}->param('lstOutTo')) ? $args{PARAM}{CGI}->param('lstOutTo') : 'HTML');
        
        if (    defined($exe) 
            and defined($page)
            and defined(CHILDRENS->{(uc($exe))}{uc($page)}))
        {
            return CHILDRENS->{(uc($exe))}{uc($page)}(@_);
        }       
        
        # не было найденно подходящего дочернего класса
        # придется делать самим        
    }
    
    # был вызов либо дочерним классом, т.е. класс такой существует
    # или дочернего нет
    my ($self)  = (ref($class) ? $class : bless({@_}, $class));
           
    foreach my $parent (@ISA)
    {        
        # вызываем конструкторы базовых классов
        next if ($self->{$parent}{NEW}++); # запрет на повторный вызов
        my $new = $parent->can("new");
        $self->$new(@_) if $new;
    }
    
    # запрет на повторную инициализацию    
    return _init($self, @_) unless ($self->{$PACKAGE}{INIT}++);      
    return $self;       
}

#*******************************************************************************
#
sub _init
#
#*******************************************************************************
{
    my ($self) = shift;    
    my ($set)  = $self->{PARAM};       # общие параметры, значение self->{PARAM}, установленно в базовом классе    
    
    $set->{SETT}->reload(LOAD_TO      => 'F136_SETTING',
                         SQL_GET_SETT => $set->{SETT}->get($set->{SESSION}->report(), 'SQL_GET_F136_SETTINGS'),
                         DB           => $set->{DB});  

    $set->{CGI}->param(-name => 'sprver', -value => $set->{SETT}->get('F136_SETTING', 'ROWVER_SPRAVOCHNIKS'));

    $self->{TARGET} = undef;
    $self->{EXE}    = undef;
            
    my $exe  = $set->{CGI}->param('exe');
    my $page = $set->{CGI}->param('page');
    
    if (    defined($exe) 
        and defined($page)
        and defined(CHILDRENS->{(uc($exe))}{uc($page)}))
    {
        $self->{TARGET} = $page;
        $self->{EXE}    = $exe;
    }       
    
    return $self;
}

#*******************************************************************************
#
sub do
#
#*******************************************************************************
{
    my $self  = shift;    
    my $set   = $self->{PARAM};       # общие параметры, значение self->{PARAM}, установленно в базовом классе
    my $vars  = $self->{$PACKAGE};    # содержит ссылку на хеш текущего пакета
    my $data  = new RpgSrcData;
    my $maker = new RpgSQLMake;

    $set->{LOG}->out(RpgLog::LOG_I, "start prepare data for console of administration 'Report by form 0409136'");

    # загружаем словари
    foreach my $dic (keys(%{DICTIONARIES()}))
    {
        my $query = $maker->procedure
                                  (
                                        DESC    => {
                                                      src    => $set->{SETT}->get($set->{SESSION}->report(), DICTIONARIES->{$dic}{src}),
                                                      params => DICTIONARIES->{$dic}{params}
                                                   },
                                        CGI     => $set->{CGI},
                                        REQUEST => FIELDS_OF_DICTIONARIES
                                  );    

        $set->{LOG}->out(RpgLog::LOG_D, "try execute '%s' (dictionary), sql: '%s'", $dic, $query);

        unless ($data->add(FROM  => $set->{DB}, 
                           TO    => $dic,
                           SRC   => $query,
                           PARAM => undef))
        {
            $set->{LOG}->out(RpgLog::LOG_E, "Error, coldn't load dictionary, becose: %s", $data->errstr());
            $self->SUPER::do(); # вызываем метод базового класса, который должен вывести соответствующую страницу
            goto _WAS_ERROR;
        }                           
    }    
    
    my %types = (date => {}, time => {});

    $types{date}{name} = $set->{SETT}->get($set->{SESSION}->report(), 'FORMAT_OF_DATE');
    $types{time}{name} = $set->{SETT}->get($set->{SESSION}->report(), 'FORMAT_OF_TIME');

    # описание формата представления даты
    $types{date}{format} = RpgTypeDate::FORMATS()->{$types{date}{name}}{format};
    $types{time}{format} = RpgTypeDate::FORMATS()->{$types{time}{name}}{format};
    
    my $rowver  = $data->get_obj_data('GET_THE_ROWVER');
    my $checkin = ((grep {defined($_) && $_ == 0} map{$_->{is_fix}} @{$data->get_data('GET_ROWVER')}) ? FALSE : TRUE);
    
    # печать заголовка ответа
    print $set->{CGI}->header(-TYPE    => 'text/html', 
                              -CHARSET => 'windows-1251',
                              -cookie  => (defined($set->{CGI}->param('the_request_wait')) ? $set->{CGI}->cookie(-name => $set->{CGI}->param('the_request_wait'), -value => 1, -expires => '+1h') : undef));
        
    # печать тела (шаблона)
    $self->{TT}->process('f136_admin.html',
        { 
            # версия к которой привязан текущий набор данных
            version      => 
            {
                rowver => $set->{SESSION}->rowver(),
                is_fix => $set->{SESSION}->is_fix(),
                access => $set->{SESSION}->access(),
                ldate  => $rowver->ldate(),
                rdate  => $rowver->rdate()
            },
            curver     => $set->{SESSION}->rowver(),
            checkin    => $checkin,
            bin_oper   => sub {($_[0] & $_[2]);},                                                             
            errors     => $self->errstr,
            alerts     => $self->alerts,
            dformat    => $types{date}{format},
            tformat    => $types{time}{format},
            date2str   => sub {RpgTypeDate::Format(shift, 'ISO8601', $types{(shift)}{name});},
            # словари
            dictionaries => {map{$_ => $data->get_data($_)} keys(%{DICTIONARIES()})}                                             
        });                

    if (defined($self->{TT}->error()))
    {
        # если при выводе шаблона были ошибки, то пишим их в лог
        $set->{LOG}->out(RpgLog::LOG_E, "Error, TT2 returns %s", $self->{TT}->error());
        goto _WAS_ERROR;
    }
        
    $set->{LOG}->out(RpgLog::LOG_I, "end prepare data for console of administration 'Report by form 0409136'");
    return TRUE;

_WAS_ERROR:        
    $set->{LOG}->out(RpgLog::LOG_I, "error prepare data for console of administration 'Report by form 0409136'");
    return FALSE;
}

1;
