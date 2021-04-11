namespace QCHack.Task4 {
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Diagnostics;

    // Task 4 (12 points). f(x) = 1 if the graph edge coloring is triangle-free
    // 
    // Inputs:
    //      1) The number of vertices in the graph "V" (V ≤ 6).
    //      2) An array of E tuples of integers "edges", representing the edges of the graph (0 ≤ E ≤ V(V-1)/2).
    //         Each tuple gives the indices of the start and the end vertices of the edge.
    //         The vertices are indexed 0 through V - 1.
    //         The graph is undirected, so the order of the start and the end vertices in the edge doesn't matter.
    //      3) An array of E qubits "colorsRegister" that encodes the color assignments of the edges.
    //         Each color will be 0 or 1 (stored in 1 qubit).
    //         The colors of edges in this array are given in the same order as the edges in the "edges" array.
    //      4) A qubit "target" in an arbitrary state.
    //
    // Goal: Implement a marking oracle for function f(x) = 1 if
    //       the coloring of the edges of the given graph described by this colors assignment is triangle-free, i.e.,
    //       no triangle of edges connecting 3 vertices has all three edges in the same color.
    //
    // Example: a graph with 3 vertices and 3 edges [(0, 1), (1, 2), (2, 0)] has one triangle.
    // The result of applying the operation to state (|001⟩ + |110⟩ + |111⟩)/√3 ⊗ |0⟩ 
    // will be 1/√3|001⟩ ⊗ |1⟩ + 1/√3|110⟩ ⊗ |1⟩ + 1/√3|111⟩ ⊗ |0⟩.
    // The first two terms describe triangle-free colorings, 
    // and the last term describes a coloring where all edges of the triangle have the same color.
    //
    // In this task you are not allowed to use quantum gates that use more qubits than the number of edges in the graph,
    // unless there are 3 or less edges in the graph. For example, if the graph has 4 edges, you can only use 4-qubit gates or less.
    // You are guaranteed that in tests that have 4 or more edges in the graph the number of triangles in the graph 
    // will be strictly less than the number of edges.
    //
    // Hint: Make use of helper functions and helper operations, and avoid trying to fit the complete
    //       implementation into a single operation - it's not impossible but make your code less readable.
    //       GraphColoring kata has an example of implementing oracles for a similar task.
    //
    // Hint: Remember that you can examine the inputs and the intermediary results of your computations
    //       using Message function for classical values and DumpMachine for quantum states.
    //
    operation Task4_TriangleFreeColoringOracle (
        V : Int, 
        edges : (Int, Int)[], 
        colorsRegister : Qubit[], 
        target : Qubit
    ) : Unit is Adj+Ctl {
        // declare acillae bits
        use ancillae = Qubit[3];
        use adder = Qubit[4];
        use adder_anc = Qubit[3];
        let num_edges = Length(edges);
        // iterate through triplets of edges
        within{
            for i in 0 .. num_edges-1 {
                for j in i+1 .. num_edges-1 {
                    for k in j+1 .. num_edges-1 {
                        // check if they form triangle
                        if isTriangle((i, j, k), edges) {
                            //Message($"{i}, {j}, {k}");
                            within {
                                // check if triangle have same colours
                                CNOT(colorsRegister[i], ancillae[0]);
                                CNOT(colorsRegister[j], ancillae[0]);
                                CNOT(colorsRegister[j], ancillae[1]);
                                CNOT(colorsRegister[k], ancillae[1]); 
                                X(ancillae[0]);
                                X(ancillae[1]);
                                CCNOT(ancillae[0], ancillae[1], ancillae[2]);
                                // track carry over
                                CCNOT(ancillae[2], adder[0], adder_anc[0]);
                                for x in 1 .. Length(adder)-2 {
                                    CCNOT(adder[x], adder_anc[x-1], adder_anc[x]);
                                }
                            } 
                            // track total number of single-colour triangles (up to 15)
                            apply {
                                // implement carry over
                                for x in 0 .. Length(adder)-2 {
                                    CNOT(adder_anc[x], adder[x+1]);
                                }
                                CNOT(ancillae[2], adder[0]);
                            }
                        }
                    }
                }
            }
            //DumpRegister((), adder);
            // flip target if no single colour triangle
            for i in 0 .. Length(adder)-1 {
                X(adder[i]);
            }
            CCNOT(adder[0], adder[1], ancillae[0]);
            CCNOT(adder[2], adder[3], ancillae[1]);
        } apply {
            CCNOT(ancillae[0], ancillae[1], target);
        }
    }

    function isTriangle (
        indices : (Int, Int, Int),
        edges : (Int, Int)[]
        ) : Bool {
        // declare variables
        let (i, j, k) = indices;
        let ((e1, e2), (e3, e4), (e5, e6)) = (edges[i], edges[j], edges[k]);
        if e1 == e3 {
            if e2 == e5 and e4 == e6 {
                return true;
            } elif e2 == e6 and e4 == e5 {
                return true;
            } else {
                return false;
            }
        } elif e1 == e4 {
            if e2 == e5 and e3 == e6 {
                return true;
            } elif e2 == e6 and e3 == e5 {
                return true;
            } else {
                return false;
            }
        } elif e1 == e5 {
            if e2 == e3 and e4 == e6 {
                return true;
            } elif e2 == e4 and e3 == e6 {
                return true;
            } else {
                return false;
            }
        } elif e1 == e6 {
            if e2 == e3 and e4 == e5 {
                return true;
            } elif e2 == e4 and e3 == e5 {
                return true;
            } else {
                return false;
            }
        } else{
            return false;
        }
    }
}

