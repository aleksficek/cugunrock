// ----------------------------------------------------------------
// Gunrock -- Fast and Efficient GPU Graph Library
// ----------------------------------------------------------------
// This source code is distributed under the terms of LICENSE.TXT
// in the root directory of this source distribution.
// ----------------------------------------------------------------

/**
 * @file
 * partitioner.cuh
 *
 * @brief Common interface for all partitioners
 */

#pragma once

#include <string>

#include <gunrock/util/parameters.h>
#include <gunrock/partitioner/random.cuh>

namespace gunrock {
namespace partitioner {

cudaError_t UseParameters(
    util::Parameters &parameters)
{
    cudaError_t retval = cudaSuccess;

    retval = parameters.Use<std::string>(
        "partition-method",
        util::REQUIRED_ARGUMENT | util::SINGLE_VALUE | util::OPTIONAL_PARAMETER,
        "random",
        "partitioning method, can be one of {random, biasrandom, cluster, metis, static}",
        __FILE__, __LINE__);
    if (retval) return retval;

    retval = parameters.Use<float>(
        "partition-factor",
        util::REQUIRED_ARGUMENT | util::SINGLE_VALUE | util::OPTIONAL_PARAMETER,
        0.5,
        "partitioning factor",
        __FILE__, __LINE__);
    if (retval) return retval;

    retval = parameters.Use<int>(
        "partition-seed",
        util::REQUIRED_ARGUMENT | util::SINGLE_VALUE | util::OPTIONAL_PARAMETER,
        0,
        "partitioning seed, default is time(NULL)",
        __FILE__, __LINE__);
    if (retval) return retval;

    return retval;
}

template <typename GraphT>
cudaError_t Partition(
    GraphT     &org_graph,
    GraphT*    &sub_graphs,
    util::Parameters &parameters,
    int         num_subgraphs = 1,
    PartitionFlag flag = PARTITION_NONE,
    util::Location target = util::HOST)
{
    typedef typename GraphT::GpT GpT;

    cudaError_t retval = cudaSuccess;
    std::string partition_method = parameters.Get<std::string>("partition-method");

    retval = org_graph.GpT::Allocate(
        org_graph.nodes, org_graph.edges,
        num_subgraphs, flag & Org_Graph_Mark, target);
    if (retval) return retval;

    if (partition_method == "random")
        retval = random::Partition(
            org_graph, sub_graphs, parameters, num_subgraphs, target);
    else retval = util::GRError("Unknown partitioning method " + partition_method,
        __FILE__, __LINE__);
    if (retval) return retval;

    retval = MakeSubGraph(org_graph, sub_graphs, parameters, num_subgraphs, flag, target);
    if (retval) return retval;
    return retval;
}

} // namespace partitioner
} // namespace gunrock

// Leave this at the end of the file
// Local Variables:
// mode:c++
// c-file-style: "NVIDIA"
// End:
