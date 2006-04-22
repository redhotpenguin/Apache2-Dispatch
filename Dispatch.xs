#include "modules/perl/mod_perl.h"

static mod_perl_perl_dir_config *newPerlConfig(pool *p)
{
    mod_perl_perl_dir_config *cld =
	(mod_perl_perl_dir_config *)
	    palloc(p, sizeof (mod_perl_perl_dir_config));
    cld->obj = Nullsv;
    cld->pclass = "main";
    register_cleanup(p, cld, perl_perl_cmd_cleanup, null_cleanup);
    return cld;
}

static void *create_dir_config_sv (pool *p, char *dirname)
{
    return newPerlConfig(p);
}

static void *create_srv_config_sv (pool *p, server_rec *s)
{
    return newPerlConfig(p);
}

static void stash_mod_pointer (char *class, void *ptr)
{
    SV *sv = newSV(0);
    sv_setref_pv(sv, NULL, (void*)ptr);
    hv_store(perl_get_hv("Apache::XS_ModuleConfig",TRUE), 
	     class, strlen(class), sv, FALSE);
}

static mod_perl_cmd_info cmd_info_DispatchPrefix = { 
"main::DispatchPrefix", "", 
};
static mod_perl_cmd_info cmd_info_DispatchExtras = { 
"main::DispatchExtras", "", 
};
static mod_perl_cmd_info cmd_info_DispatchStat = { 
"main::DispatchStat", "", 
};
static mod_perl_cmd_info cmd_info_DispatchAUTOLOAD = { 
"main::DispatchAUTOLOAD", "", 
};
static mod_perl_cmd_info cmd_info_DispatchDebug = { 
"main::DispatchDebug", "", 
};
static mod_perl_cmd_info cmd_info_DispatchISA = { 
"main::DispatchISA", "", 
};
static mod_perl_cmd_info cmd_info_DispatchLocation = { 
"main::DispatchLocation", "", 
};
static mod_perl_cmd_info cmd_info_DispatchRequire = { 
"main::DispatchRequire", "", 
};
static mod_perl_cmd_info cmd_info_DispatchFilter = { 
"main::DispatchFilter", "", 
};
static mod_perl_cmd_info cmd_info_DispatchUpperCase = { 
"main::DispatchUpperCase", "", 
};


static command_rec mod_cmds[] = {
    
    { "DispatchPrefix", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_DispatchPrefix,
      OR_ALL, TAKE1, "a class to be used as the base class" },

    { "DispatchExtras", perl_cmd_perl_ITERATE,
      (void*)&cmd_info_DispatchExtras,
      OR_ALL, ITERATE, "choose any of: Pre, Post, or Error" },

    { "DispatchStat", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_DispatchStat,
      OR_ALL, TAKE1, "choose one of On, Off, or ISA" },

    { "DispatchAUTOLOAD", perl_cmd_perl_FLAG,
      (void*)&cmd_info_DispatchAUTOLOAD,
      OR_ALL, FLAG, "choose one of On or Off" },

    { "DispatchDebug", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_DispatchDebug,
      OR_ALL, TAKE1, "numeric verbosity level" },

    { "DispatchISA", perl_cmd_perl_ITERATE,
      (void*)&cmd_info_DispatchISA,
      OR_ALL, ITERATE, "a list of parent modules" },

    { "DispatchLocation", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_DispatchLocation,
      OR_ALL, TAKE1, "a location to replace the current <Location>" },

    { "DispatchRequire", perl_cmd_perl_FLAG,
      (void*)&cmd_info_DispatchRequire,
      OR_ALL, FLAG, "choose one of On or Off" },

    { "DispatchFilter", perl_cmd_perl_FLAG,
      (void*)&cmd_info_DispatchFilter,
      OR_ALL, FLAG, "choose one of On or Off" },

    { "DispatchUpperCase", perl_cmd_perl_FLAG,
      (void*)&cmd_info_DispatchUpperCase,
      OR_ALL, FLAG, "choose one of On or Off" },

    { NULL }
};

module MODULE_VAR_EXPORT XS_main = {
    STANDARD_MODULE_STUFF,
    NULL,               /* module initializer */
    create_dir_config_sv,  /* per-directory config creator */
    NULL,   /* dir config merger */
    create_srv_config_sv,       /* server config creator */
    NULL,        /* server config merger */
    mod_cmds,               /* command table */
    NULL,           /* [7] list of handlers */
    NULL,  /* [2] filename-to-URI translation */
    NULL,      /* [5] check/validate user_id */
    NULL,       /* [6] check user_id is valid *here* */
    NULL,     /* [4] check access by host address */
    NULL,       /* [7] MIME type checker/setter */
    NULL,        /* [8] fixups */
    NULL,             /* [10] logger */
    NULL,      /* [3] header parser */
    NULL,         /* process initializer */
    NULL,         /* process exit/cleanup */
    NULL,   /* [1] post read_request handling */
};

#define this_module "main.pm"

static void remove_module_cleanup(void *data)
{
    if (find_linked_module("main")) {
        /* need to remove the module so module index is reset */
        remove_module(&XS_main);
    }
    if (data) {
        /* make sure BOOT section is re-run on restarts */
        (void)hv_delete(GvHV(incgv), this_module,
                        strlen(this_module), G_DISCARD);
         if (dowarn) {
             /* avoid subroutine redefined warnings */
             perl_clear_symtab(gv_stashpv("main", FALSE));
         }
    }
}

MODULE = main		PACKAGE = main

PROTOTYPES: DISABLE

BOOT:
    XS_main.name = "main";
    add_module(&XS_main);
    stash_mod_pointer("main", &XS_main);
    register_cleanup(perl_get_startup_pool(), (void *)1,
                     remove_module_cleanup, null_cleanup);

void
END()

    CODE:
    remove_module_cleanup(NULL);
