//
//  OCPrinterUtility.h
//  Objective-CUPS
//
//  Created by Eldon on 3/3/14.
//  Copyright (c) 2014 Loyola University New Orleans. All rights reserved.
//

#import "OCPrinterUtility.h"
#import "OCError.h"
#import <cups/ppd.h>

const char *writeOptionsToPPD(cups_option_t *options, int num_options, const char *file, NSError *__autoreleasing *error)
{

    const char *customval, /* Custom option value */
        *returnPPD;

    ppd_file_t *ppdfile; /* PPD file */

    cups_file_t *inppd, /* PPD file */
        *outppd; /* Temporary file */

    ppd_choice_t *choice; /* Marked choice */

    char tempfile[1024], /* Temporary filename */
        line[1024], /* Line from PPD file */
        keyword[1024], /* Keyword from Default line */
        *keyptr; /* Pointer into keyword... */

    BOOL ppdchanged;

    ppdchanged = NO; // this is read after push/pop so shows as never read with xcode
    if (ppdchanged) {
    };
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

    // silence the depericiaton warnings untill Apple starts to use
    // the standard lpoptions files rather than needing them hard coded
    // into the PPD file.

    if ((ppdfile = ppdOpenFile(file)) == NULL) {
        [OCError errorWithCode:kPrinterErrorCantOpenPPD error:error];
        return NULL;
    } else {
        ppdMarkDefaults(ppdfile);
        cupsMarkOptions(ppdfile, num_options, options);

        if ((outppd = cupsTempFile2(tempfile, sizeof(tempfile))) == NULL) {
            [OCError errorWithCode:kPrinterErrorCantWriteFile error:error];
            cupsFileClose(outppd);
            unlink(tempfile);
            return NULL;
        }

        if ((inppd = cupsFileOpen(file, "r")) == NULL) {
            cupsFileClose(outppd);
            unlink(tempfile);
            [OCError errorWithCode:kPrinterErrorCantOpenPPD error:error];
            return NULL;
        }

        ppdchanged = YES;

        while (cupsFileGets(inppd, line, sizeof(line))) {
            if (strncmp(line, "*Default", 8))
                cupsFilePrintf(outppd, "%s\n", line);
            else {
                strlcpy(keyword, line + 8, sizeof(keyword));

                for (keyptr = keyword; *keyptr; keyptr++)
                    if (*keyptr == ':' || isspace(*keyptr & 255))
                        break;

                *keyptr++ = '\0';
                while (isspace(*keyptr & 255))
                    keyptr++;

                if (!strcmp(keyword, "PageRegion") || !strcmp(keyword, "PageSize") || !strcmp(keyword, "PaperDimension") || !strcmp(keyword, "ImageableArea")) {
                    if ((choice = ppdFindMarkedChoice(ppdfile, "PageSize")) == NULL)
                        choice = ppdFindMarkedChoice(ppdfile, "PageRegion");
                } else
                    choice = ppdFindMarkedChoice(ppdfile, keyword);

                if (choice && strcmp(choice->choice, keyptr)) {
                    if (strcmp(choice->choice, "Custom")) {
                        cupsFilePrintf(outppd, "*Default%s: %s\n", keyword, choice->choice);
                        ppdchanged = YES;
                    } else if ((customval = cupsGetOption(keyword, num_options,
                                                          options)) != NULL) {
                        cupsFilePrintf(outppd, "*Default%s: %s\n", keyword, customval);
                        ppdchanged = YES;
                    } else
                        cupsFilePrintf(outppd, "%s\n", line);
                } else
                    cupsFilePrintf(outppd, "%s\n", line);
            }
        }
        cupsFileClose(inppd);
        cupsFileClose(outppd);
        ppdClose(ppdfile);
    }
#pragma clang diagnostic pop
    returnPPD = ppdchanged ? [[NSString stringWithUTF8String:tempfile] UTF8String] : file;
    if (!ppdchanged) {
        unlink(tempfile);
    }
    return returnPPD;
}
