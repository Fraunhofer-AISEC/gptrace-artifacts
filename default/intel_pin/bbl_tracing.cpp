// Copyright 2025 Fraunhofer AISEC
// Fraunhofer-Gesellschaft zur Förderung der angewandten Forschung e.V.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


// This Intel Pin instrumentation stores each encountered address together with
// the number of occurences of that address during the execution of the binary.

#include "pin.H"
#include <iostream>
#include <fstream>
using std::string;

static std::ostream* traceFile = &std::cerr;
static std::ofstream outFile;

static PIN_LOCK lockVector;
static PIN_LOCK lockCounter;

KNOB< string > KnobOutputFile(KNOB_MODE_WRITEONCE, "pintool", "o", "", "specify output file name");

INT32 Usage() {
    std::cerr << "This tool prints out the number of dynamically executed " << std::endl
         << "instructions, basic blocks and threads in the application." << std::endl
         << std::endl;

    std::cerr << KNOB_BASE::StringKnobSummary() << std::endl;

    return -1;
}

struct BBInfo {
    ADDRINT addr;
    UINT64  count;
};

static std::vector<BBInfo*> allBBs;

static VOID PIN_FAST_ANALYSIS_CALL incCounter(UINT64 *c) {
    PIN_GetLock(&lockCounter, 0);
    ++(*c);
    PIN_ReleaseLock(&lockCounter);
}

VOID recordBasicBlock(TRACE trace, VOID *) {
    for (BBL bbl = TRACE_BblHead(trace); BBL_Valid(bbl); bbl = BBL_Next(bbl)) {
        auto *info = new BBInfo{ BBL_Address(bbl), 0 };

        PIN_GetLock(&lockVector, 0);
        allBBs.push_back(info);
        PIN_ReleaseLock(&lockVector);

        BBL_InsertCall(bbl, IPOINT_ANYWHERE,
                       (AFUNPTR)incCounter,
                       IARG_FAST_ANALYSIS_CALL,
                       IARG_PTR, &info->count,
                       IARG_END);
    }
}

VOID fini(INT32, VOID *) {
    for (const auto *i : allBBs)
        *traceFile << std::hex << i->addr << ' ' << std::dec << i->count << '\n';
}

int main(int argc, char *argv[]) {
    // Initialize Pin
    if (PIN_Init(argc, argv)) {
        std::cerr << "PIN_Init failed!" << std::endl;
        return Usage();
    }
    PIN_InitLock(&lockVector);
    PIN_InitLock(&lockCounter);

    string fileName = KnobOutputFile.Value();
    if (!fileName.empty()) {
        outFile.open(fileName.c_str());
        if (!outFile) {
            std::cerr << "Could not open output file " << fileName << std::endl;
            return 1;
        }
        traceFile = &outFile;
    }

    // Register the basic block instruction
    TRACE_AddInstrumentFunction(recordBasicBlock, nullptr);

    // Register fini function
    PIN_AddFiniFunction(fini, nullptr);

    // Start the program
    PIN_StartProgram();
    return 0;
}
