///|
pub enum OperationMode {
  Nominal
  Safe
  Contingency
  Simulation
} derive(Debug, Eq)

///|
pub fn all_operation_modes() -> Array[OperationMode] {
  [Nominal, Safe, Contingency, Simulation]
}

///|
pub struct OperationStep {
  index : Int
  name : String
  mode : OperationMode
  duration_s : Double
  resource_cost : Double
  completed : Bool
} derive(Debug, Eq)

///|
pub struct OperationPlan {
  name : String
  steps : Array[OperationStep]
  total_duration_s : Double
  total_resource_cost : Double
} derive(Debug, Eq)

///|
pub fn OperationStep::new(
  index : Int,
  name : String,
  mode : OperationMode,
  duration_s : Double,
  resource_cost : Double,
) -> OperationStep {
  {
    index,
    name,
    mode,
    duration_s: duration_s.max(0.0),
    resource_cost: resource_cost.max(0.0),
    completed: false,
  }
}

///|
pub fn OperationPlan::new(name : String) -> OperationPlan {
  { name, steps: [], total_duration_s: 0.0, total_resource_cost: 0.0 }
}

///|
pub fn OperationPlan::append(
  plan : OperationPlan,
  step : OperationStep,
) -> OperationPlan {
  let steps = plan.steps.copy()
  steps.push(step)
  {
    ..plan,
    steps,
    total_duration_s: plan.total_duration_s + step.duration_s,
    total_resource_cost: plan.total_resource_cost + step.resource_cost,
  }
}

///|
pub fn OperationPlan::complete_step(
  plan : OperationPlan,
  index : Int,
) -> OperationPlan {
  let steps = plan.steps.copy()
  for i in 0..<steps.length() {
    if steps[i].index == index {
      steps[i] = { ..steps[i], completed: true }
    }
  }
  { ..plan, steps, }
}

///|
pub fn OperationPlan::completion_fraction(plan : OperationPlan) -> Double {
  if plan.steps.length() == 0 {
    0.0
  } else {
    Double::from_int(plan.steps.filter(step => step.completed).length()) /
    Double::from_int(plan.steps.length())
  }
}

///|
pub fn OperationPlan::remaining_steps(
  plan : OperationPlan,
) -> Array[OperationStep] {
  plan.steps.filter(step => !step.completed)
}

///|
pub fn OperationPlan::is_ready(plan : OperationPlan) -> Bool {
  (plan.steps.length() > 0 && plan.steps[0].completed) ||
  plan.steps.length() == 0
}

///|
pub fn OperationPlan::resource_remaining(
  plan : OperationPlan,
  resource_limit : Double,
) -> Double {
  resource_limit - plan.total_resource_cost
}

///|
pub fn nominal_step(
  index : Int,
  name : String,
  duration_s : Double,
  resource_cost : Double,
) -> OperationStep {
  OperationStep::new(index, name, Nominal, duration_s, resource_cost)
}

///|
pub fn contingency_step(
  index : Int,
  name : String,
  duration_s : Double,
  resource_cost : Double,
) -> OperationStep {
  OperationStep::new(index, name, Contingency, duration_s, resource_cost)
}

///|
pub fn simulate_plan(
  plan : OperationPlan,
  available_resource : Double,
) -> OperationPlan {
  let mut result = plan
  for step in result.steps {
    if result.resource_remaining(available_resource) >= step.resource_cost {
      result = result.complete_step(step.index)
    }
  }
  result
}
