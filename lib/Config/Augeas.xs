//    Copyright (c) 2008-2010 Dominique Dumont.
//    Copyright (c) 2011-2012 Raphaël Pinson.
// 
//    This library is free software; you can redistribute it and/or
//    modify it under the terms of the GNU Lesser Public License as
//    published by the Free Software Foundation; either version 2.1 of
//    the License, or (at your option) any later version.
// 
//    Config-Model is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//    Lesser Public License for more details.
// 
//    You should have received a copy of the GNU Lesser Public License
//    along with Config-Model; if not, write to the Free Software
//    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
//    02110-1301 USA

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newCONSTSUB
#include "ppport.h"

#include <string.h>
#include <stdio.h>
#include <augeas.h>

/* Defines from Augeas' internal.h */
#ifndef AUGEAS_META_TREE
#define AUGEAS_META_TREE "/augeas"
#endif
#ifndef AUGEAS_SPAN_OPTION
#define AUGEAS_SPAN_OPTION AUGEAS_META_TREE "/span"
#endif
#ifndef AUGEAS_ENABLE
#define AUG_ENABLE "enable"
#endif
#ifndef AUGEAS_DISABLE
#define AUG_DISABLE "disable"
#endif

typedef augeas   Config_Augeas ;
typedef PerlIO*  OutputStream;

MODULE = Config::Augeas PACKAGE = Config::Augeas PREFIX = aug_

 # See http://blogs.sun.com/akolb/entry/pitfals_of_the_perl_xs
 # 
 # Define any constants that need to be exported.  By doing it this way
 # we can avoid the overhead of using the DynaLoader package, and in
 # addition constants defined using this mechanism are eligible for
 # inlining by the perl interpreter at compile time.

BOOT:
  {
    HV *stash;
    stash	       = gv_stashpv("Config::Augeas", TRUE);
    newCONSTSUB(stash, "AUG_NONE",         newSViv(AUG_NONE));
    newCONSTSUB(stash, "AUG_SAVE_BACKUP",  newSViv(AUG_SAVE_BACKUP));
    newCONSTSUB(stash, "AUG_SAVE_NEWFILE", newSViv(AUG_SAVE_NEWFILE));
    newCONSTSUB(stash, "AUG_TYPE_CHECK",   newSViv(AUG_TYPE_CHECK));
    newCONSTSUB(stash, "AUG_NO_STDINC",    newSViv(AUG_NO_STDINC));
    newCONSTSUB(stash, "AUG_SAVE_NOOP",    newSViv(AUG_SAVE_NOOP));
    newCONSTSUB(stash, "AUG_NO_LOAD",      newSViv(AUG_NO_LOAD));
    newCONSTSUB(stash, "AUG_NO_MODL_AUTOLOAD", newSViv(AUG_NO_MODL_AUTOLOAD));
    newCONSTSUB(stash, "AUG_ENABLE_SPAN", newSViv(AUG_ENABLE_SPAN));


    /* Error reporting */
    newCONSTSUB(stash, "AUG_NOERROR",   newSViv(AUG_NOERROR));
    newCONSTSUB(stash, "AUG_ENOMEM",    newSViv(AUG_ENOMEM));
    newCONSTSUB(stash, "AUG_EINTERNAL", newSViv(AUG_EINTERNAL));
    newCONSTSUB(stash, "AUG_EPATHX",    newSViv(AUG_EPATHX));
    newCONSTSUB(stash, "AUG_ENOMATCH",  newSViv(AUG_ENOMATCH));
    newCONSTSUB(stash, "AUG_EMMATCH",   newSViv(AUG_EMMATCH));
    newCONSTSUB(stash, "AUG_ESYNTAX",   newSViv(AUG_ESYNTAX));
    newCONSTSUB(stash, "AUG_ENOLENS",   newSViv(AUG_ENOLENS));
    newCONSTSUB(stash, "AUG_EMXFM",     newSViv(AUG_EMXFM));
    newCONSTSUB(stash, "AUG_ENOSPAN", newSViv(AUG_ENOSPAN));

  }

Config_Augeas*
aug_init(root = NULL ,loadpath = NULL ,flags = 0)
      char* root 
      char* loadpath
      unsigned int flags


MODULE = Config::Augeas PACKAGE = Config::AugeasPtr PREFIX = aug_

void
aug_DESTROY(aug)
      Config_Augeas* aug
    CODE:
      //printf("destroying aug object\n");
      aug_close(aug);

int
aug_defvar(aug, name, expr)
      Config_Augeas* aug
      const char* name
      const char* expr

 # returns an array ( return value, created ) 
void
aug_defnode(aug, name, expr, value)
      Config_Augeas* aug
      const char* name
      const char* expr
      const char* value
    PREINIT:
      int created ;
      int ret ;
    PPCODE:
      created = 1 ;
      ret = aug_defnode(aug, name, expr, value, &created ) ;
      if (ret >= 0 ) {
        XPUSHs(sv_2mortal(newSVnv(ret)));
        XPUSHs(sv_2mortal(newSVnv(created)));
      }

const char*
aug_get(aug, path)
      Config_Augeas* aug
      char* path
    PREINIT:
      int ret ;
    CODE:
      RETVAL = NULL ;
      ret = aug_get(aug, path, &RETVAL);
    OUTPUT:
      RETVAL

int
aug_set(aug, path, c_value)
      Config_Augeas* aug
      const char* path
      char* c_value

int
aug_text_store(aug, lens, node, path)
      Config_Augeas* aug
      const char* lens
      const char* node
      const char* path

int
aug_text_retrieve(aug, lens, node_in, path, node_out)
      Config_Augeas* aug
      const char* lens
      const char* node_in
      const char* path
      const char* node_out

int 
aug_insert(aug, path, label, before)
      Config_Augeas* aug
      const char* path
      const char* label
      int before

int 
aug_rm(aug, path);
      Config_Augeas *aug
      const char *path

int 
aug_mv(aug, src, dst);
      Config_Augeas *aug
      const char *src
      const char *dst

int
aug_rename(aug, src, dst);
      Config_Augeas *aug
      const char *src
      const char *dst

SV*
aug_span(aug, path);
      Config_Augeas* aug
      char* path
    PREINIT:
      int ret ;
      char *filename = NULL;
      const char *option = NULL;
      uint label_start, label_end, value_start, value_end, span_start, span_end;
      HV *span_hash;
    CODE:
      // Check that span is enabled
      if (aug_get(aug, AUGEAS_SPAN_OPTION, &option) != 1) {
	 croak ("Error: option %s not found\n", AUGEAS_SPAN_OPTION);
      }
      if (strcmp(AUG_DISABLE, option) == 0) {
	 croak ("Error: Span is not enabled.\n");
      }
      ret = aug_span(aug, path, &filename, &label_start, &label_end, &value_start, &value_end, &span_start, &span_end);
      span_hash = newHV();
      if (filename) {
         (void)hv_store(span_hash, "filename", 8, newSVpv(filename, strlen(filename)), 0);
         free(filename) ;
      }
      (void)hv_store(span_hash, "label_start", 11, newSViv(label_start), 0);
      (void)hv_store(span_hash, "label_end", 9, newSViv(label_end), 0);
      (void)hv_store(span_hash, "value_start", 11, newSViv(value_start), 0);
      (void)hv_store(span_hash, "value_end", 9, newSViv(value_end), 0);
      (void)hv_store(span_hash, "span_start", 10, newSViv(span_start), 0);
      (void)hv_store(span_hash, "span_end", 8, newSViv(span_end), 0);
      RETVAL = newRV_noinc((SV *)span_hash);
    OUTPUT:
      RETVAL
      

void
aug_match(aug, pattern);
      Config_Augeas *aug
      const char *pattern
    PREINIT:
        char** matches;
        char** err_matches;
        const char*  err_string ;
        int i ;
        int ret ;
	int cnt;
	char die_msg[1024] ;
	char tmp_msg[128];
    PPCODE:
    
        cnt = aug_match(aug, pattern, &matches);

        if (cnt == -1) {
	   sprintf(die_msg, "aug_match error with pattern '%s':\n",pattern);
    	   cnt = aug_match(aug,"/augeas//error/descendant-or-self::*",&err_matches);
	   for (i=0; i < cnt; i++) {
               ret = aug_get(aug, err_matches[i], &err_string) ;
	       sprintf(tmp_msg,"%s = %s\n", err_matches[i], err_string );
	       if (strlen(die_msg) + strlen(tmp_msg) < 1024 )
	       	       strcat(die_msg,tmp_msg);
	   }
	   croak ("%s",die_msg);
        }

        // printf("match: Pattern %s matches %d times\n", pattern, cnt);
    
        for (i=0; i < cnt; i++) {
            XPUSHs(sv_2mortal(newSVpv(matches[i], 0)));
            free((void*) matches[i]);
        }
        free(matches);

int
aug_count_match(aug, pattern);
      Config_Augeas *aug
      const char *pattern
    CODE:
        RETVAL = aug_match(aug, pattern,NULL);
    OUTPUT:
        RETVAL


int 
aug_save( aug );
      Config_Augeas *aug

int 
aug_load( aug );
      Config_Augeas *aug


 # See example 9 in perlxstut man page
int
aug_print(aug, stream, path);
        Config_Augeas *aug
	OutputStream stream
	const char* path
    PREINIT:
        FILE *fp ;
    CODE:
        fp = PerlIO_findFILE(stream);
        if (fp != (FILE*) 0) {
             RETVAL = aug_print(aug, fp, path);
         } else {
             RETVAL = -1;
         }
    OUTPUT:
        RETVAL

int
aug_srun(aug, stream, text);
        Config_Augeas *aug
	OutputStream stream
	const char* text
    PREINIT:
        FILE *fp ;
    CODE:
        fp = PerlIO_findFILE(stream);
        if (fp != (FILE*) 0) {
             RETVAL = aug_srun(aug, fp, text);
         } else {
             RETVAL = -1;
         }
    OUTPUT:
        RETVAL

 # Error reporting

int 
aug_error( aug );
      Config_Augeas *aug

const char*
aug_error_message(aug)
      Config_Augeas* aug

const char*
aug_error_minor_message(aug)
      Config_Augeas* aug

const char*
aug_error_details(aug)
      Config_Augeas* aug
